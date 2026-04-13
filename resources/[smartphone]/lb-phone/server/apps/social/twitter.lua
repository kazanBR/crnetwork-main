-- Notification event keys
local NOTIFICATION_TYPES = {
  like    = "BACKEND.TWITTER.LIKE",
  retweet = "BACKEND.TWITTER.RETWEET",
  reply   = "BACKEND.TWITTER.REPLY",
  follow  = "BACKEND.TWITTER.FOLLOW",
  tweet   = "BACKEND.TWITTER.TWEET",
}

-- Interaction table definitions (like / retweet)
local INTERACTION_TABLES = {
  like    = { table = "phone_twitter_likes",    column1 = "username", column2 = "tweet_id" },
  retweet = { table = "phone_twitter_retweets", column1 = "username", column2 = "tweet_id" },
}

-- ─────────────────────────────────────────────────────────────
-- Helper: get logged-in Twitter username for a player source
-- ─────────────────────────────────────────────────────────────
local function getLoggedInUser(source)
  local phoneNumber = GetEquippedPhoneNumber(source)
  if not phoneNumber then
    return false
  end
  return GetLoggedInAccount(phoneNumber, "Twitter")
end

-- ─────────────────────────────────────────────────────────────
-- Helper: register a callback that automatically injects the
-- caller's logged-in Twitter account as an extra argument
-- ─────────────────────────────────────────────────────────────
-- In LB Phone, BaseCallback(name, fn, requireLogin, opts):
--   fn is called as fn(source, phoneNumber, ...clientArgs) and its return value is sent to client.
--   This differs from RegisterLegacyCallback which passes an explicit cb function.
local function registerAuthedCallback(name, handler, requireLogin, opts)
  BaseCallback("birdy:" .. name, function(source, phoneNumber, ...)
    local username = GetLoggedInAccount(phoneNumber, "Twitter")
    if not username then
      return requireLogin
    end
    return handler(source, phoneNumber, username, ...)
  end, requireLogin, opts)
end

-- ─────────────────────────────────────────────────────────────
-- Helper: notify all logged-in sessions of a username except
-- the sender's own phone number
-- ─────────────────────────────────────────────────────────────
local function broadcastToFollowers(username, notification, senderPhone)
  local rows = MySQL.query.await(
    "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'Twitter' AND `active` = 1",
    { username }
  )
  notification.app = "Twitter"
  for _, row in ipairs(rows) do
    if row.phone_number ~= senderPhone then
      SendNotification(row.phone_number, notification)
    end
  end
end

-- ─────────────────────────────────────────────────────────────
-- Helper: fetch profile data for a username, optionally with
-- relationship data relative to a viewer phone number
-- ─────────────────────────────────────────────────────────────
local function getProfile(username, viewerPhone)
  username = username:lower()

  local account = MySQL.single.await(
    "SELECT `display_name`, `bio`, `profile_image`, `profile_header`, `verified`, `follower_count`, `following_count`, `date_joined`, private FROM `phone_twitter_accounts` WHERE `username`=?",
    { username }
  )
  if not account then
    return false
  end

  local isFollowing         = false
  local isFollowingYou      = false
  local notificationsEnabled = false
  local requested           = false
  local pinnedTweet         = nil

  local viewer = viewerPhone and GetLoggedInAccount(viewerPhone, "Twitter") or nil

  if viewer then
    -- Check if viewer follows this user
    isFollowing = nil ~= MySQL.scalar.await(
      "SELECT `followed` FROM `phone_twitter_follows` WHERE `follower` = ? AND `followed` = ?",
      { viewer, username }
    )
    -- Check if this user follows the viewer
    isFollowingYou = nil ~= MySQL.scalar.await(
      "SELECT `followed` FROM `phone_twitter_follows` WHERE `follower` = ? AND `followed` = ?",
      { username, viewer }
    )
    -- Check notification preference
    notificationsEnabled = true == MySQL.scalar.await(
      "SELECT `notifications` FROM `phone_twitter_follows` WHERE `follower` = ? AND `followed` = ?",
      { viewer, username }
    )
    -- Check pending follow request
    requested = nil ~= MySQL.scalar.await(
      "SELECT TRUE FROM phone_twitter_follow_requests WHERE requester = ? AND requestee = ?",
      { viewer, username }
    )
    -- Fetch pinned tweet
    local pinnedId = MySQL.scalar.await(
      "SELECT pinned_tweet FROM phone_twitter_accounts WHERE username = ?",
      { username }
    )
    if pinnedId then
      pinnedTweet = GetTweet(pinnedId, viewer)
    end
  end

  return {
    name                = account.display_name,
    username            = username,
    followers           = account.follower_count,
    following           = account.following_count,
    date_joined         = account.date_joined,
    bio                 = account.bio,
    verified            = account.verified,
    private             = account.private,
    profile_picture     = account.profile_image,
    header              = account.profile_header,
    isFollowing         = isFollowing,
    isFollowingYou      = isFollowingYou,
    notificationsEnabled = notificationsEnabled,
    pinnedTweet         = pinnedTweet,
    requested           = requested,
  }
end

-- ─────────────────────────────────────────────────────────────
-- Helper: create a notification record and push it to the
-- recipient's logged-in devices
-- ─────────────────────────────────────────────────────────────
local function createNotification(recipientUsername, fromUsername, notifType, tweetId)
  -- Don't notify yourself
  if recipientUsername == fromUsername then return end

  local eventKey = NOTIFICATION_TYPES[notifType]
  if not eventKey then return end

  -- For actionable types, deduplicate (like / retweet / follow)
  if notifType == "like" or notifType == "retweet" or notifType == "follow" then
    local query = "SELECT TRUE FROM phone_twitter_notifications WHERE username=@username AND `from`=@from AND `type`=@type"
    if notifType ~= "follow" then
      query = query .. " AND tweet_id=@tweet_id"
    end
    local existing = MySQL.Sync.fetchScalar(query, {
      ["@username"] = recipientUsername,
      ["@from"]     = fromUsername,
      ["@type"]     = notifType,
      ["@tweet_id"] = tweetId,
    })
    if existing then return end
  end

  -- Fetch sender info; skip if private and this is a reply
  local sender = MySQL.Sync.fetchAll(
    "SELECT display_name, private FROM phone_twitter_accounts WHERE username=@username",
    { ["@username"] = fromUsername }
  )[1]

  if not sender then return end
  if sender.private and notifType == "reply" then return end

  -- Build localised notification title
  local title = L(eventKey, { displayName = sender.display_name, username = fromUsername })

  -- Insert notification row
  MySQL.Async.execute(
    "INSERT INTO phone_twitter_notifications (id, username, `from`, `type`, tweet_id) VALUES (@id, @username, @from, @type, @tweetId)",
    {
      ["@id"]       = GenerateId("phone_twitter_notifications", "id"),
      ["@username"] = recipientUsername,
      ["@from"]     = fromUsername,
      ["@type"]     = notifType,
      ["@tweetId"]  = tweetId,
    }
  )

  -- Fetch tweet content for the push notification thumbnail
  local tweetContent    = nil
  local tweetThumbnail  = nil
  if notifType ~= "follow" then
    local tweetRow = MySQL.Sync.fetchAll(
      "SELECT content, attachments FROM phone_twitter_tweets WHERE id=@tweetId",
      { ["@tweetId"] = tweetId }
    )
    if tweetRow and tweetRow[1] then
      tweetContent = tweetRow[1].content
      if tweetRow[1].attachments then
        local decoded = json.decode(tweetRow[1].attachments)
        tweetThumbnail = decoded and decoded[1] or nil
      end
    end
  end

  NotifyLoggedInAccounts("Twitter", recipientUsername, {
    title     = title,
    content   = tweetContent,
    thumbnail = tweetThumbnail,
  })
end

-- ─────────────────────────────────────────────────────────────
-- Callback: getNotifications
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getNotifications", function(source, cb, page)
  local username = getLoggedInUser(source)
  if not username then
    return cb({ notifications = {}, requests = 0 })
  end

  local offset = (page or 0) * 15

  local notifications = MySQL.Sync.fetchAll([[
    SELECT
        n.`from`, n.`type`, n.tweet_id,
        t.username, t.content, t.attachments, t.reply_to, t.like_count,
        t.reply_count, t.retweet_count, t.`timestamp`,
        (SELECT TRUE FROM phone_twitter_likes l WHERE l.tweet_id=t.id AND l.username=@username) AS liked,
        (SELECT TRUE FROM phone_twitter_retweets r WHERE r.tweet_id=t.id AND r.username=@username) AS retweeted,
        a.display_name AS `name`, a.profile_image AS profile_picture, a.verified,
        (CASE WHEN t.reply_to IS NULL THEN NULL ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1) END) AS replyToAuthor
    FROM phone_twitter_notifications n
    LEFT JOIN phone_twitter_tweets t ON n.tweet_id = t.id
    JOIN phone_twitter_accounts a ON a.username = n.from
    WHERE n.username=@username
    ORDER BY n.`timestamp` DESC
    LIMIT @page, @perPage
  ]], {
    ["@username"] = username,
    ["@page"]     = offset,
    ["@perPage"]  = 15,
  })

  -- On subsequent pages we don't need to re-fetch the request count
  if page and page > 0 then
    return cb({ notifications = notifications })
  end

  local requestCount = MySQL.Sync.fetchScalar(
    "SELECT COUNT(1) FROM phone_twitter_follow_requests WHERE requestee=@username",
    { ["@username"] = username }
  )

  cb({ notifications = notifications, requests = requestCount })
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: createAccount
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:createAccount", function(source, cb, displayName, username, password)
  local phoneNumber = GetEquippedPhoneNumber(source)
  if not phoneNumber then
    return cb(false)
  end

  username = username:lower()

  if not IsUsernameValid(username) then
    return cb({ success = false, error = "USERNAME_NOT_ALLOWED" })
  end

  local taken = MySQL.Sync.fetchScalar(
    "SELECT TRUE FROM phone_twitter_accounts WHERE username=@username",
    { ["@username"] = username }
  )
  if taken then
    return cb({ success = false, error = "USERNAME_TAKEN" })
  end

  MySQL.Sync.execute(
    "INSERT INTO phone_twitter_accounts (display_name, username, `password`, phone_number) VALUES (@displayName, @username, @password, @phonenumber)",
    {
      ["@displayName"]  = displayName,
      ["@username"]     = username,
      ["@password"]     = GetPasswordHash(password),
      ["@phonenumber"]  = phoneNumber,
    }
  )

  AddLoggedInAccount(phoneNumber, "Twitter", username)
  cb({ success = true })

  -- Auto-follow configured Birdy accounts
  if Config.AutoFollow and Config.AutoFollow.Enabled then
    if Config.AutoFollow.Birdy and Config.AutoFollow.Birdy.Enabled then
      for _, accountToFollow in ipairs(Config.AutoFollow.Birdy.Accounts) do
        MySQL.update.await(
          "INSERT INTO phone_twitter_follows (followed, follower, notifications) VALUES (?, ?, 1)",
          { accountToFollow, username }
        )
      end
    end
  end
end, { preventSpam = true, rateLimit = 4 })

-- ─────────────────────────────────────────────────────────────
-- Callback: changePassword  (via registerAuthedCallback wrapper)
-- ─────────────────────────────────────────────────────────────
registerAuthedCallback("changePassword", function(source, phoneNumber, username, oldPassword, newPassword)
  if not Config.ChangePassword or not Config.ChangePassword.Birdy then
    infoprint("warning", ("%s tried to change password on Birdy, but it's not enabled in the config."):format(source))
    return false
  end

  -- Reject identical passwords or passwords that are too short
  if oldPassword == newPassword or #newPassword < 3 then
    debugprint("same password / too short")
    return false
  end

  local storedHash = MySQL.scalar.await(
    "SELECT password FROM phone_twitter_accounts WHERE username = ?",
    { username }
  )
  if not storedHash or not VerifyPasswordHash(oldPassword, storedHash) then
    return false
  end

  local updated = MySQL.update.await(
    "UPDATE phone_twitter_accounts SET password = ? WHERE username = ?",
    { GetPasswordHash(newPassword), username }
  )
  if not (updated > 0) then
    return false
  end

  local phoneNumber = GetEquippedPhoneNumber(source)

  -- Notify all other sessions that they have been signed out
  broadcastToFollowers(username, {
    title   = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
    content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
  }, phoneNumber)

  -- Revoke all other sessions
  MySQL.update.await(
    "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Twitter' AND phone_number != ?",
    { username, phoneNumber }
  )
  ClearActiveAccountsCache("Twitter", username, phoneNumber)

  Log("Birdy", source, "info",
    L("BACKEND.LOGS.CHANGED_PASSWORD.TITLE"),
    L("BACKEND.LOGS.CHANGED_PASSWORD.DESCRIPTION", { number = phoneNumber, username = username, app = "Birdy" })
  )

  TriggerClientEvent("phone:logoutFromApp", -1, {
    username = username,
    app      = "twitter",
    reason   = "password",
    number   = phoneNumber,
  })

  return true
end, false)

-- ─────────────────────────────────────────────────────────────
-- Internal: permanently delete an account by username
-- ─────────────────────────────────────────────────────────────
local function deleteAccountByUsername(username)
  assert(type(username) == "string",
    "Expected string for argument 1 (username), got " .. type(username))

  local deleted = MySQL.update.await(
    "DELETE FROM phone_twitter_accounts WHERE username = ?",
    { username }
  )
  if not (deleted > 0) then
    return false
  end

  -- Notify any logged-in sessions before wiping them
  broadcastToFollowers(username, {
    title   = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
    content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"),
  }, nil)

  MySQL.update.await(
    "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Twitter'",
    { username }
  )
  ClearActiveAccountsCache("Twitter", username)

  TriggerClientEvent("phone:logoutFromApp", -1, {
    username = username,
    app      = "twitter",
    reason   = "deleted",
  })

  return true
end

exports("DeleteBirdyAccount", deleteAccountByUsername)

-- ─────────────────────────────────────────────────────────────
-- Callback: deleteAccount
-- ─────────────────────────────────────────────────────────────
registerAuthedCallback("deleteAccount", function(source, phoneNumber, username, password)
  if not Config.DeleteAccount or not Config.DeleteAccount.Birdy then
    infoprint("warning", ("%s tried to delete their account on Birdy, but it's not enabled in the config."):format(source))
    return false
  end

  local storedHash = MySQL.scalar.await(
    "SELECT password FROM phone_twitter_accounts WHERE username = ?",
    { username }
  )
  if not storedHash or not VerifyPasswordHash(password, storedHash) then
    return false
  end

  local success = deleteAccountByUsername(username)
  if success then
    local phoneNumber = GetEquippedPhoneNumber(source)
    Log("Birdy", source, "info",
      L("BACKEND.LOGS.DELETED_ACCOUNT.TITLE"),
      L("BACKEND.LOGS.DELETED_ACCOUNT.DESCRIPTION", { number = phoneNumber, username = username, app = "Birdy" })
    )
  end
  return success
end, false)

-- ─────────────────────────────────────────────────────────────
-- Callback: login
-- ─────────────────────────────────────────────────────────────
BaseCallback("birdy:login", function(source, cb, username, password)
  username = username:lower()

  local storedHash = MySQL.scalar.await(
    "SELECT `password` FROM phone_twitter_accounts WHERE username = ?",
    { username }
  )
  if not storedHash then
    return { success = false, error = "INVALID_ACCOUNT" }
  end

  if not VerifyPasswordHash(password, storedHash) then
    return { success = false, error = "INVALID_PASSWORD" }
  end

  local phoneNumber = GetEquippedPhoneNumber(source)
  AddLoggedInAccount(phoneNumber, "Twitter", username)

  local profile = getProfile(username, phoneNumber)
  if not profile then
    return { success = false, error = "INVALID_ACCOUNT" }
  end

  return { success = true, data = profile }
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: isLoggedIn
-- ─────────────────────────────────────────────────────────────
registerAuthedCallback("isLoggedIn", function(source, phoneNumber, username)
  return getProfile(username, phoneNumber)
end, false)

-- ─────────────────────────────────────────────────────────────
-- Callback: getProfile
-- ─────────────────────────────────────────────────────────────
registerAuthedCallback("getProfile", function(source, phoneNumber, loggedInUsername, targetUsername)
  return getProfile(targetUsername, phoneNumber)
end, false, { preventSpam = true, rateLimit = 15 })

-- ─────────────────────────────────────────────────────────────
-- Callback: pinPost
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:pinPost", function(source, cb, tweetId)
  local username = getLoggedInUser(source)
  if not username then
    return cb(false)
  end

  -- If pinning a tweet, verify the caller owns it
  if tweetId then
    local owns = MySQL.scalar.await(
      "SELECT TRUE FROM phone_twitter_tweets WHERE id = ? AND username = ?",
      { tweetId, username }
    )
    if not owns then
      infoprint("warning", ("%s (%s) tried to pin a post on birdy that they didn't make."):format(username, source))
      return cb(false)
    end
  end

  MySQL.Async.execute(
    "UPDATE phone_twitter_accounts SET pinned_tweet=@tweetId WHERE username=@username",
    { ["@tweetId"] = tweetId or nil, ["@username"] = username },
    function() cb(true) end
  )
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: signOut
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:signOut", function(source, cb)
  local phoneNumber = GetEquippedPhoneNumber(source)
  if not phoneNumber then return cb(false) end

  local username = GetLoggedInAccount(phoneNumber, "Twitter")
  if not username then return cb(false) end

  RemoveLoggedInAccount(phoneNumber, "Twitter", username)
  cb(true)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: updateProfile
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:updateProfile", function(source, cb, data)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end

  MySQL.Async.execute(
    "UPDATE phone_twitter_accounts SET display_name=@displayName, bio=@bio, profile_image=@profilePicture, profile_header=@header, private=@private WHERE username=@username",
    {
      ["@username"]       = username,
      ["@displayName"]    = data.name,
      ["@bio"]            = data.bio,
      ["@profilePicture"] = data.profile_picture,
      ["@header"]         = data.header,
      ["@private"]        = data.private,
    },
    function() cb(true) end
  )
end)

-- ─────────────────────────────────────────────────────────────
-- Internal: log a new post to the server log
-- ─────────────────────────────────────────────────────────────
local function logNewPost(postId, username, content, attachments, source)
  local attachmentCount = attachments and #attachments or 0

  local logBody = "**Username**: " .. username .. "\n**Content**: " .. (content or "")

  if attachments then
    logBody = logBody .. "\n**Attachments**:"
    for i = 1, attachmentCount do
      logBody = logBody .. ("\n[Attachment %s](%s)"):format(i, attachments[i])
    end
  end

  logBody = logBody .. "\n**ID**: " .. postId

  Log("Birdy", source, "info", "New post", logBody)
end

-- ─────────────────────────────────────────────────────────────
-- Internal: send a Discord webhook for a new post
-- ─────────────────────────────────────────────────────────────
local function sendPostWebhook(username, content, attachments, replyTo)
  if not Config.Post or not Config.Post.Birdy then return end
  if replyTo then return end  -- don't webhook replies
  if not BIRDY_WEBHOOK then return end
  if BIRDY_WEBHOOK:sub(-14) ~= "/api/webhooks/" then return end

  local avatarUrl = MySQL.scalar.await(
    "SELECT profile_image FROM phone_twitter_accounts WHERE username = ?",
    { username }
  )

  -- Build embed description (content or first attachment)
  local description
  if content and #content > 0 then
    description = content
  end

  -- Build attachment image field
  local imageField = nil
  if attachments and #attachments > 0 then
    imageField = { url = attachments[1] }
  end

  local webhookUsername = (Config.Post.Accounts and Config.Post.Accounts.Birdy and Config.Post.Accounts.Birdy.Username) or "Birdy"
  local webhookAvatar   = (Config.Post.Accounts and Config.Post.Accounts.Birdy and Config.Post.Accounts.Birdy.Avatar)
                          or "https://loaf-scripts.com/fivem/lb-phone/icons/Birdy.png"

  PerformHttpRequest(BIRDY_WEBHOOK, function() end, "POST", json.encode({
    username   = webhookUsername,
    avatar_url = webhookAvatar,
    embeds = {
      {
        title       = L("APPS.TWITTER.NEW_POST"),
        description = description,
        color       = 1942002,
        timestamp   = GetTimestampISO(),
        author = {
          name     = "@" .. username,
          icon_url = avatarUrl or "https://cdn.discordapp.com/embed/avatars/5.png",
        },
        image  = imageField,
        footer = {
          text     = "LB Phone",
          icon_url = "https://docs.lbscripts.com/images/icons/icon.png",
        },
      }
    },
  }), { ["Content-Type"] = "application/json" })
end

-- ─────────────────────────────────────────────────────────────
-- Internal: core post creation logic (used by sendPost & export)
-- Returns: success (bool), postId (string|nil)
-- ─────────────────────────────────────────────────────────────
local function createPost(username, content, attachments, replyTo, hashtags, playerSource)
  content = content or ""

  -- Validate arguments
  assert(type(username) == "string",
    "PostBirdy: Expected string for argument 1 (username), got " .. type(username))
  assert(type(content) == "string",
    "PostBirdy: Expected string/nil for argument 2 (content), got " .. type(content))

  local postId = GenerateId("phone_twitter_tweets", "id")
  local params = { postId, username, content }
  local columns = "INSERT INTO phone_twitter_tweets (id, username, content"

  -- Handle attachments
  if attachments ~= nil then
    if type(attachments) == "table" and table.type(attachments) == "array" then
      if #attachments > 0 then
        columns = columns .. ", attachments"
        params[#params + 1] = json.encode(attachments)
      end
    else
      error("PostBirdy: Expected table/nil for argument 3 (attachments), got " .. type(attachments))
    end
  else
    -- No attachments: require non-blank content
    if #content:gsub(" ", "") == 0 then
      debugprint("PostBirdy: No content & no attachments")
      return false
    end
  end

  -- Handle replyTo
  if replyTo ~= nil then
    if type(replyTo) == "string" then
      columns = columns .. ", reply_to"
      params[#params + 1] = replyTo
    else
      error("PostBirdy: Expected string/nil for argument 4 (replyTo), got " .. type(replyTo))
    end
  end

  -- Build and execute INSERT
  local placeholders = ("?, "):rep(#params):sub(1, -3)
  local sql = columns .. ") VALUES (" .. placeholders .. ")"
  local rowsAffected = MySQL.update.await(sql, params)
  if rowsAffected == 0 then
    return false
  end

  -- Fetch author display info
  local author = MySQL.single.await(
    "SELECT display_name, profile_image, verified, private FROM phone_twitter_accounts WHERE username = ?",
    { username }
  )
  if not author then
    author = { display_name = username }
  end

  -- If a reply, increment parent reply count and notify parent author
  if replyTo then
    MySQL.update("UPDATE phone_twitter_tweets SET reply_count = reply_count + 1 WHERE id = ?", { replyTo })
    TriggerClientEvent("phone:twitter:updateTweetData", -1, replyTo, "replies", true)

    MySQL.scalar("SELECT username FROM phone_twitter_tweets WHERE id = ?", { replyTo }, function(parentAuthor)
      if parentAuthor then
        createNotification(parentAuthor, username, "reply", postId)
      end
    end)
  end

  -- Notify all followers with tweet notifications enabled
  MySQL.query("SELECT follower FROM phone_twitter_follows WHERE followed = ? AND notifications=1", { username },
    function(followers)
      for _, row in ipairs(followers) do
        createNotification(row.follower, username, "tweet", postId)
      end
    end
  )

  TrackSocialMediaPost("birdy", attachments)

  -- Log the post
  if playerSource then
    logNewPost(postId, username, content, attachments, playerSource)
  end

  -- Only broadcast public posts
  if not author.private then
    sendPostWebhook(username, content, attachments, replyTo)

    -- Notify online / all players
    if Config.BirdyNotifications then
      local notifScope = Config.BirdyNotifications == "all" and "all" or "online"
      NotifyEveryone(notifScope, {
        app       = "Twitter",
        title     = L("BACKEND.TWITTER.TWEET", { username = username }),
        content   = content,
        thumbnail = attachments and attachments[1] or nil,
      })
    end

    -- Update trending hashtags
    if Config.BirdyTrending and Config.BirdyTrending.Enabled then
      if type(hashtags) == "table" and table.type(hashtags) == "array" and #hashtags > 0 then
        local hashtagPlaceholders = ("(?, 1), "):rep(#hashtags):sub(1, -3)
        MySQL.update(
          "INSERT INTO phone_twitter_hashtags (hashtag, amount) VALUES " .. hashtagPlaceholders ..
          " ON DUPLICATE KEY UPDATE amount = amount + 1",
          hashtags
        )
      end
    end

    -- Build broadcast post object
    local replyToAuthor = nil
    if replyTo then
      replyToAuthor = MySQL.scalar.await(
        "SELECT username FROM phone_twitter_tweets WHERE id = ?",
        { replyTo }
      )
    end

    local broadcastPost = {
      id                  = postId,
      username            = username,
      content             = content,
      attachments         = attachments,
      like_count          = 0,
      reply_count         = 0,
      retweet_count       = 0,
      reply_to            = replyTo,
      timestamp           = os.time() * 1000,
      liked               = false,
      retweeted           = false,
      display_name        = author.display_name,
      profile_image       = author.profile_image,
      verified            = author.verified,
      source              = playerSource,
      replyToAuthor       = replyToAuthor,
    }

    TriggerClientEvent("phone:twitter:newtweet", -1, broadcastPost)
    TriggerEvent("lb-phone:birdy:newPost", broadcastPost)
  end

  return true, postId
end

exports("PostBirdy", createPost)

-- ─────────────────────────────────────────────────────────────
-- Callback: sendPost (player-facing, with antispam)
-- ─────────────────────────────────────────────────────────────
-- Client sends: content, attachments, replyTo, hashtags
registerAuthedCallback("sendPost", function(source, phoneNumber, username, content, attachments, replyTo, hashtags)
  if ContainsBlacklistedWord(source, "Birdy", content) then
    return false
  end

  if not ValidateChecks("postBirdy", source, phoneNumber, content, attachments) then
    debugprint("birdy:sendPost - postBirdy check failed")
    return false
  end

  local success = createPost(username, content, attachments, replyTo, hashtags, source)
  return success
end, nil, { preventSpam = true, rateLimit = 15 })

-- ─────────────────────────────────────────────────────────────
-- Callback: getRecentHashtags
-- ─────────────────────────────────────────────────────────────
RegisterCallback("birdy:getRecentHashtags", function(source)
  if not (Config.BirdyTrending and Config.BirdyTrending.Enabled) then
    return {}
  end
  return MySQL.query.await("SELECT hashtag, amount AS uses FROM phone_twitter_hashtags ORDER BY amount DESC LIMIT 5")
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: deletePost
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:deletePost", function(source, cb, tweetId)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end

  -- Get the parent tweet id (for reply count update)
  local parentId = MySQL.Sync.fetchScalar(
    "SELECT reply_to FROM phone_twitter_tweets WHERE id=@id",
    { ["@id"] = tweetId }
  )

  -- Admins can delete any post; regular users only their own
  local canDelete = IsAdmin(source)
  if not canDelete then
    canDelete = MySQL.Sync.fetchScalar(
      "SELECT TRUE FROM phone_twitter_tweets WHERE id=@id AND username=@username",
      { ["@id"] = tweetId, ["@username"] = username }
    )
  end

  if not canDelete then return cb(false) end

  local params = { ["@id"] = tweetId }
  MySQL.Sync.execute("DELETE FROM phone_twitter_likes WHERE tweet_id=@id", params)
  MySQL.Sync.execute("DELETE FROM phone_twitter_retweets WHERE tweet_id=@id", params)
  MySQL.Sync.execute("DELETE FROM phone_twitter_notifications WHERE tweet_id=@id", params)

  local rows = MySQL.Sync.execute("DELETE FROM phone_twitter_tweets WHERE id=@id", params)
  local success = rows > 0
  cb(success)

  if not success then return end

  -- Update parent reply count if this was a reply
  if parentId then
    local newCount = MySQL.Sync.fetchScalar(
      "SELECT COUNT(id) FROM phone_twitter_tweets WHERE reply_to=@replyTo",
      { ["@replyTo"] = parentId }
    )
    MySQL.Sync.execute(
      "UPDATE phone_twitter_tweets SET reply_count=@count WHERE id=@replyTo",
      { ["@replyTo"] = parentId, ["@count"] = newCount }
    )
    TriggerClientEvent("phone:twitter:updateTweetData", -1, parentId, "replies", false)
  end

  Log("Birdy", source, "info", "Post deleted", "**ID**: " .. tweetId)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: getRandomPromoted
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getRandomPromoted", function(source, cb)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end

  local tweetId = MySQL.Sync.fetchScalar(
    "SELECT tweet_id FROM phone_twitter_promoted WHERE promotions > 0 ORDER BY RAND() LIMIT 1"
  )
  if not tweetId then return cb(false) end

  -- Decrement promotion counter
  MySQL.Async.execute(
    "UPDATE phone_twitter_promoted SET promotions = promotions - 1, views = views + 1 WHERE tweet_id = @tweetId",
    { ["@tweetId"] = tweetId }
  )

  cb(GetTweet(tweetId))
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: promotePost
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:promotePost", function(source, cb, tweetId)
  local enabled = Config.PromoteBirdy and Config.PromoteBirdy.Enabled
  if not enabled or not RemoveMoney then
    return cb(false)
  end

  local paid = RemoveMoney(source, Config.PromoteBirdy.Cost)
  if not paid then return cb(false) end

  MySQL.Async.execute([[
    INSERT INTO phone_twitter_promoted (tweet_id, promotions, views) VALUES (@tweetId, @promotions, 0)
        ON DUPLICATE KEY UPDATE promotions = promotions + @promotions
  ]], {
    ["@tweetId"]    = tweetId,
    ["@promotions"] = Config.PromoteBirdy.Views,
  })

  cb(true)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: searchAccounts
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:searchAccounts", function(source, cb, query, page)
  local offset = (page or 0) * 25
  MySQL.Async.fetchAll([[
    SELECT display_name, username, profile_image, verified, private
    FROM phone_twitter_accounts
    WHERE username LIKE CONCAT(@search, "%") OR display_name LIKE CONCAT("%", @search, "%")
    ORDER BY username ASC
    LIMIT @page, @perPage
  ]], {
    ["@search"]  = query,
    ["@page"]    = offset,
    ["@perPage"] = 25,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: searchTweets
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:searchTweets", function(source, cb, query, page)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end

  local offset = (page or 0) * 10
  MySQL.Async.fetchAll([[
    SELECT DISTINCT t.id, t.username, t.content, t.attachments,
        t.like_count, t.reply_count, t.retweet_count, t.reply_to, t.`timestamp`,
        (CASE WHEN t.reply_to IS NULL THEN NULL ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1) END) AS replyToAuthor,
        a.display_name, a.username, a.profile_image, a.verified,
        (SELECT TRUE FROM phone_twitter_likes l WHERE l.tweet_id=t.id AND l.username=@loggedInAs) AS liked,
        (SELECT TRUE FROM phone_twitter_retweets r WHERE r.tweet_id=t.id AND r.username=@loggedInAs) AS retweeted
    FROM phone_twitter_tweets t
        LEFT JOIN phone_twitter_accounts a ON a.username=t.username
    WHERE t.content LIKE CONCAT("%", @search, "%")
    ORDER BY t.`timestamp` DESC
    LIMIT @page, @perPage
  ]], {
    ["@search"]     = query,
    ["@loggedInAs"] = username,
    ["@page"]       = offset,
    ["@perPage"]    = 10,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: getData (followers / following / likes / retweeters)
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getData", function(source, cb, dataType, whereValue, page)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end

  -- Normalise whereValue: tweet_id may arrive as number from NUI
  if dataType == "likes" or dataType == "retweeters" then
    whereValue = tostring(whereValue)
  end

  -- Map dataType to the correct table and columns
  local tableName = "phone_twitter_likes"
  local whereCol  = "tweet_id"
  local joinCol   = "username"

  if dataType == "following" or dataType == "followers" then
    tableName = "phone_twitter_follows"
    if dataType == "following" then
      whereCol, joinCol = "follower", "followed"
    else
      whereCol, joinCol = "followed", "follower"
    end
  elseif dataType == "retweeters" then
    tableName = "phone_twitter_retweets"
  end

  local offset = (page or 0) * 20
  MySQL.Async.fetchAll(([[
    SELECT
        a.display_name AS `name`, a.username, a.profile_image AS profile_picture, a.bio, a.verified,
        (SELECT CASE WHEN f.followed IS NULL THEN FALSE ELSE TRUE END FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND a.username=f.followed) AS isFollowing,
        (SELECT CASE WHEN f.follower IS NULL THEN FALSE ELSE TRUE END FROM phone_twitter_follows f WHERE f.follower=a.username AND f.followed=@loggedInAs) AS isFollowingYou
    FROM %s w
    JOIN phone_twitter_accounts a ON a.username=w.%s
    WHERE w.%s=@whereValue
    ORDER BY a.username DESC
    LIMIT @page, @perPage
  ]]):format(tableName, joinCol, whereCol), {
    ["@loggedInAs"] = username,
    ["@whereValue"] = whereValue,
    ["@page"]       = offset,
    ["@perPage"]    = 20,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Internal: GetTweet (used by other callbacks and exported)
-- ─────────────────────────────────────────────────────────────
local function getTweet(tweetId, viewerUsername)
  if not tweetId then return nil end

  local rows = MySQL.Sync.fetchAll([[
    SELECT DISTINCT t.id, t.username, t.content, t.attachments,
        t.like_count, t.reply_count, t.retweet_count, t.reply_to, t.`timestamp`,
        (CASE WHEN t.reply_to IS NULL THEN NULL ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1) END) AS replyToAuthor,
        a.display_name, a.username, a.profile_image, a.verified,
        (SELECT TRUE FROM phone_twitter_likes l WHERE l.tweet_id=t.id AND l.username=@loggedInAs) AS liked,
        (SELECT TRUE FROM phone_twitter_retweets r WHERE r.tweet_id=t.id AND r.username=@loggedInAs) AS retweeted
    FROM phone_twitter_tweets t
    INNER JOIN phone_twitter_accounts a ON a.username=t.username
    WHERE t.id=@tweetId AND (a.private=0 OR a.username=@loggedInAs OR (
        SELECT TRUE FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND f.followed=a.username
    ))
  ]], {
    ["@tweetId"]    = tweetId,
    ["@loggedInAs"] = viewerUsername,
  })

  return rows and rows[1] or nil
end

GetTweet = getTweet

-- Legacy export (deprecated – use GetBirdyPost)
exports("GetTweet", function(tweetId, cb)
  assert(type(tweetId) == "string",
    "Expected string for argument 1, got " .. type(tweetId))
  infoprint("warning", "GetTweet is deprecated, use GetBirdyPost instead")

  MySQL.Async.fetchAll([[
    SELECT DISTINCT t.id, t.username, t.content, t.attachments,
        t.like_count, t.reply_count, t.retweet_count, t.reply_to, t.`timestamp`,
        a.display_name, a.username, a.profile_image, a.verified
    FROM (phone_twitter_tweets t, phone_twitter_accounts a)
    WHERE t.id=@tweetId AND t.username=a.username
  ]], { ["@tweetId"] = tweetId }, cb)
end)

-- Modern export
exports("GetBirdyPost", function(tweetId)
  local row = MySQL.single.await([[
    SELECT
        t.id, t.username, t.content, t.attachments,
        t.like_count AS likes, t.reply_count AS replies, t.retweet_count AS reposts,
        t.reply_to AS replyTo, t.`timestamp`,
        a.display_name AS displayName, a.profile_image AS avatar, a.verified
    FROM phone_twitter_tweets t
        LEFT JOIN phone_twitter_accounts a ON a.username = t.username
    WHERE t.id = ?
  ]], { tweetId })

  if row then
    -- Decode attachments JSON string
    if row.attachments then
      row.attachments = json.decode(row.attachments) or nil
    end
  end

  return row
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: getPost
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getPost", function(source, cb, tweetId)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end
  cb(getTweet(tweetId, username))
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: getPosts (main feed with filter support)
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getPosts", function(source, cb, filter, page)
  local username = getLoggedInUser(source)
  if not username then return cb({}) end

  -- Build WHERE / JOIN clauses based on filter type
  local whereClause   = ""
  local joinClause    = ""
  local orderBy       = "`timestamp` DESC"
  local includeRTs    = false
  local rtWhereExtra  = ""
  local rtJoinExtra   = ""

  if not filter then
    whereClause  = "t.reply_to IS NULL"
    includeRTs   = true
  else
    local ftype = filter.type
    if ftype == "following" then
      whereClause  = "t.reply_to IS NULL AND f.follower=@loggedInAs AND f.followed=t.username"
      joinClause   = "JOIN phone_twitter_follows f"
      rtJoinExtra  = "JOIN phone_twitter_follows f ON f.follower=@loggedInAs AND r.username=f.followed"
      includeRTs   = true
    elseif ftype == "replyTo" then
      whereClause = "t.reply_to=@replyTo"
      orderBy     = "t.like_count DESC, t.timestamp DESC"
    elseif ftype == "user" then
      whereClause  = "t.username=@username AND t.reply_to IS NULL"
      rtWhereExtra = " AND r.username=@username"
      includeRTs   = true
    elseif ftype == "media" then
      whereClause = "t.username=@username AND t.attachments IS NOT NULL"
    elseif ftype == "replies" then
      whereClause = "t.username=@username AND t.reply_to IS NOT NULL"
    elseif ftype == "liked" then
      whereClause = "l.username=@username AND t.id=l.tweet_id"
      joinClause  = "JOIN phone_twitter_likes l"
      orderBy     = "l.timestamp DESC"
    end
  end

  -- Base query (original posts)
  local sql = ([[
    SELECT
        (CASE WHEN t.reply_to IS NULL THEN NULL ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1) END) AS replyToAuthor,
        t.id, t.username, t.content, t.attachments,
        t.like_count, t.reply_count, t.retweet_count, t.reply_to, t.`timestamp`,
        a.display_name, a.profile_image, a.verified, a.private,
        (SELECT TRUE FROM phone_twitter_likes l2 WHERE l2.tweet_id=t.id AND l2.username=@loggedInAs) AS liked,
        (SELECT TRUE FROM phone_twitter_retweets r2 WHERE r2.tweet_id=t.id AND r2.username=@loggedInAs) AS retweeted,
        NULL AS tweet_timestamp, NULL AS retweeted_by_display_name, NULL AS retweeted_by_username
    FROM phone_twitter_tweets t
    INNER JOIN phone_twitter_accounts a ON a.username=t.username
    %s
    WHERE (a.private=0 OR a.username=@loggedInAs OR (
        SELECT TRUE FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND f.followed=a.username
    )) AND %s
  ]]):format(joinClause, whereClause)

  -- Append retweet UNION if needed
  if includeRTs then
    sql = sql .. ([[
      UNION ALL
      SELECT
          (CASE WHEN t.reply_to IS NULL THEN NULL ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1) END) AS replyToAuthor,
          t.id, t.username, t.content, t.attachments,
          t.like_count, t.reply_count, t.retweet_count, t.reply_to, r.timestamp,
          a.display_name, a.profile_image, a.verified, a.private,
          (SELECT TRUE FROM phone_twitter_likes l2 WHERE l2.tweet_id=t.id AND l2.username=@loggedInAs) AS liked,
          (SELECT TRUE FROM phone_twitter_retweets r2 WHERE r2.tweet_id=t.id AND r2.username=@loggedInAs) AS retweeted,
          t.`timestamp` AS tweet_timestamp,
          (SELECT display_name FROM phone_twitter_accounts a2 WHERE r.username=a2.username) AS retweeted_by_display_name,
          r.username AS retweeted_by_username
      FROM phone_twitter_tweets t
      INNER JOIN phone_twitter_accounts a ON a.username=t.username
      JOIN phone_twitter_retweets r ON r.tweet_id=t.id
      %s
      WHERE (a.private=0 OR a.username=@loggedInAs OR (
          SELECT TRUE FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND f.followed=a.username
      )) %s
    ]]):format(rtJoinExtra, rtWhereExtra)
  end

  sql = sql .. ("ORDER BY %s\nLIMIT @page, @perPage"):format(orderBy)

  local offset = (page or 0) * 10
  MySQL.Async.fetchAll(sql, {
    ["@page"]       = offset,
    ["@perPage"]    = 10,
    ["@username"]   = filter and filter.username or nil,
    ["@replyTo"]    = filter and filter.tweet_id or nil,
    ["@loggedInAs"] = username,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: toggleInteraction (like / retweet)
-- ─────────────────────────────────────────────────────────────
-- Note: no preventSpam — like/unlike are valid rapid back-to-back actions
RegisterLegacyCallback("birdy:toggleInteraction", function(source, cb, interactionType, tweetId, newState)
  if interactionType ~= "like" and interactionType ~= "retweet" then return end

  -- Normalise tweetId to string (NUI may send it as a number)
  tweetId = tostring(tweetId)

  local username = getLoggedInUser(source)
  if not username then return cb(not newState) end

  local config   = INTERACTION_TABLES[interactionType]
  local countCol = interactionType == "like" and "like_count" or "retweet_count"
  local countField = interactionType == "like" and "likes" or "retweets"

  if newState then
    -- Liking/retweeting: INSERT IGNORE (safe if already exists)
    MySQL.Async.execute(
      ("INSERT IGNORE INTO %s (%s, %s) VALUES (@loggedInAs, @tweetId)"):format(config.table, config.column1, config.column2),
      { ["@loggedInAs"] = username, ["@tweetId"] = tweetId },
      function(rowsAffected)
        if rowsAffected == 0 then
          -- Row already existed — state is already correct, confirm it
          return cb(true)
        end

        -- New like/retweet: increment count
        MySQL.Async.execute(
          ("UPDATE phone_twitter_tweets SET %s = %s + 1 WHERE id=@tweetId"):format(countCol, countCol),
          { ["@tweetId"] = tweetId }
        )

        cb(true)
        TriggerClientEvent("phone:twitter:updateTweetData", -1, tweetId, countField, true)

        -- Notify the post author
        MySQL.scalar("SELECT username FROM phone_twitter_tweets WHERE id=@tweetId",
          { ["@tweetId"] = tweetId },
          function(authorUsername)
            if authorUsername and authorUsername ~= username then
              createNotification(authorUsername, username, interactionType, tweetId)
            end
          end
        )
      end
    )
  else
    -- Unliking/un-retweeting: DELETE
    MySQL.Async.execute(
      ("DELETE FROM %s WHERE %s=@loggedInAs AND %s=@tweetId"):format(config.table, config.column1, config.column2),
      { ["@loggedInAs"] = username, ["@tweetId"] = tweetId },
      function(rowsAffected)
        if rowsAffected == 0 then
          -- Row didn't exist — state is already correct, confirm it
          return cb(false)
        end

        -- Decrement count, floor at 0
        MySQL.Async.execute(
          ("UPDATE phone_twitter_tweets SET %s = GREATEST(0, %s - 1) WHERE id=@tweetId"):format(countCol, countCol),
          { ["@tweetId"] = tweetId }
        )

        cb(false)
        TriggerClientEvent("phone:twitter:updateTweetData", -1, tweetId, countField, false)
      end
    )
  end
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: toggleNotifications
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:toggleNotifications", function(source, cb, targetUsername, enabled)
  local username = getLoggedInUser(source)
  if not username then return cb(not enabled) end

  MySQL.Async.execute(
    "UPDATE phone_twitter_follows SET notifications=@enabled WHERE follower=@loggedInAs AND followed=@username",
    { ["@enabled"] = enabled, ["@loggedInAs"] = username, ["@username"] = targetUsername },
    function(rows)
      cb(rows > 0 and enabled or not enabled)
    end
  )
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: toggleFollow
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:toggleFollow", function(source, cb, targetUsername, wantsFollow)
  local username = getLoggedInUser(source)
  if not username or targetUsername == username then
    return cb(not wantsFollow)
  end

  local params = { ["@loggedInAs"] = username, ["@username"] = targetUsername }

  local isPrivate = MySQL.Sync.fetchScalar(
    "SELECT private FROM phone_twitter_accounts WHERE username=@username",
    params
  )

  -- Private account: handle follow requests instead of direct follows
  if isPrivate then
    if wantsFollow then
      MySQL.Async.execute(
        "INSERT IGNORE INTO phone_twitter_follow_requests (requester, requestee) VALUES (@loggedInAs, @username)",
        params,
        function(rows)
          cb(wantsFollow)
          if rows == 0 then return end  -- already requested
          NotifyLoggedInAccounts("Twitter", targetUsername, {
            title = L("BACKEND.TWITTER.NEW_FOLLOW_REQUEST", { username = username }),
          })
        end
      )
    else
      MySQL.Async.execute(
        "DELETE FROM phone_twitter_follow_requests WHERE requester=@loggedInAs AND requestee=@username",
        params
      )
    end
    return
  end

  -- Public account: directly insert or delete follow record
  local sql = wantsFollow
    and "INSERT IGNORE INTO phone_twitter_follows (followed, follower, notifications) VALUES (@username, @loggedInAs, 1)"
    or  "DELETE FROM phone_twitter_follows WHERE followed=@username AND follower=@loggedInAs"

  MySQL.Async.execute(sql, params, function(rows)
    if rows == 0 then return cb(not wantsFollow) end

    -- Update follower/following counts in the UI
    TriggerClientEvent("phone:twitter:updateProfileData", -1, targetUsername, "followers", wantsFollow == true)
    TriggerClientEvent("phone:twitter:updateProfileData", -1, username, "following", wantsFollow == true)

    if wantsFollow then
      createNotification(targetUsername, username, "follow", nil)
    end

    cb(wantsFollow)
  end)
end, { preventSpam = true, rateLimit = 30 })

-- ─────────────────────────────────────────────────────────────
-- Callback: getFollowRequests
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getFollowRequests", function(source, cb, page)
  local username = getLoggedInUser(source)
  if not username then return cb({}) end

  local offset = (page or 0) * 15
  MySQL.Async.fetchAll([[
    SELECT a.username, a.display_name AS `name`, a.profile_image AS profile_picture, a.verified,
        (SELECT CASE WHEN f.follower IS NULL THEN FALSE ELSE TRUE END FROM phone_twitter_follows f WHERE f.follower=a.username AND f.followed=@loggedInAs) AS isFollowingYou
    FROM phone_twitter_follow_requests r
    INNER JOIN phone_twitter_accounts a ON a.username=r.requester
    WHERE r.requestee=@loggedInAs
    ORDER BY r.`timestamp` DESC
    LIMIT @page, @perPage
  ]], {
    ["@loggedInAs"] = username,
    ["@page"]       = offset,
    ["@perPage"]    = 15,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: handleFollowRequest (accept or decline)
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:handleFollowRequest", function(source, cb, requesterUsername, accept)
  local username = getLoggedInUser(source)
  if not username then return cb(false) end

  local params = { ["@loggedInAs"] = username, ["@username"] = requesterUsername }

  -- Remove the request regardless of accept/decline
  local deleted = MySQL.Sync.execute(
    "DELETE FROM phone_twitter_follow_requests WHERE requestee=@loggedInAs AND requester=@username",
    params
  )
  if deleted == 0 then return cb(false) end
  if not accept then return cb(true) end

  -- Accept: create the follow relationship
  MySQL.Sync.execute(
    "INSERT IGNORE INTO phone_twitter_follows (follower, followed, notifications) VALUES (@username, @loggedInAs, 1)",
    params
  )

  TriggerClientEvent("phone:twitter:updateProfileData", -1, username, "followers", true)
  TriggerClientEvent("phone:twitter:updateProfileData", -1, requesterUsername, "following", true)

  createNotification(username, requesterUsername, "follow", nil)

  NotifyLoggedInAccounts("Twitter", requesterUsername, {
    title = L("BACKEND.TWITTER.FOLLOW_REQUEST_ACCEPTED_DESCRIPTION", { username = username }),
  })

  cb(true)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: sendMessage
-- ─────────────────────────────────────────────────────────────
-- Client sends: recipient, content, attachments
registerAuthedCallback("sendMessage", function(source, phoneNumber, senderUsername, recipientUsername, content, attachments)
  if ContainsBlacklistedWord(source, "Birdy", content) then
    return false
  end

  local encodedAttachments = nil
  if attachments then
    encodedAttachments = json.encode(attachments)
  end

  local rows = MySQL.update.await([[
    INSERT INTO phone_twitter_messages (id, sender, recipient, content, attachments)
    VALUES (@id, @sender, @recipient, @content, @attachments)
  ]], {
    ["@id"]          = GenerateId("phone_twitter_messages", "id"),
    ["@sender"]      = senderUsername,
    ["@recipient"]   = recipientUsername,
    ["@content"]     = content,
    ["@attachments"] = encodedAttachments,
  })
  if rows == 0 then return false end

  -- Push to all online sessions of the recipient
  local recipientPhones = GetLoggedInNumbers("Twitter", recipientUsername)
  for _, number in ipairs(recipientPhones) do
    local playerSource = GetSourceFromNumber(number)
    if playerSource then
      TriggerClientEvent("phone:twitter:newMessage", playerSource, {
        sender      = senderUsername,
        recipient   = recipientUsername,
        content     = content,
        attachments = attachments,
        timestamp   = os.time() * 1000,
      })
    end
  end

  -- Push notification with sender's profile info
  local senderProfile = getProfile(senderUsername)
  if not senderProfile then return true end

  NotifyLoggedInAccounts("Twitter", recipientUsername, {
    app         = "Twitter",
    title       = senderProfile.name,
    content     = content,
    thumbnail   = attachments and attachments[1] or nil,
    avatar      = senderProfile.profile_picture,
    showAvatar  = true,
  })

  return true
end, nil, { preventSpam = true, rateLimit = 15 })

-- ─────────────────────────────────────────────────────────────
-- Callback: getMessages
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getMessages", function(source, cb, otherUsername, page)
  local username = getLoggedInUser(source)
  if not username then return cb({}) end

  local offset = (page or 0) * 25
  MySQL.Async.fetchAll([[
    SELECT sender, recipient, content, attachments, `timestamp`
    FROM phone_twitter_messages
    WHERE (sender=@loggedInAs AND recipient=@username) OR (sender=@username AND recipient=@loggedInAs)
    ORDER BY `timestamp` DESC
    LIMIT @page, @perPage
  ]], {
    ["@loggedInAs"] = username,
    ["@username"]   = otherUsername,
    ["@page"]       = offset,
    ["@perPage"]    = 25,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Callback: getRecentMessages
-- ─────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getRecentMessages", function(source, cb, page)
  local username = getLoggedInUser(source)
  if not username then return cb({}) end

  local offset = (page or 0) * 15
  MySQL.Async.fetchAll([[
    SELECT
        m.content, m.attachments, m.sender, f_m.username, m.`timestamp`,
        a.display_name AS `name`, a.profile_image AS profile_picture, a.verified
    FROM phone_twitter_messages m
    JOIN ((
        SELECT (CASE WHEN recipient!=@loggedInAs THEN recipient ELSE sender END) AS username, MAX(`timestamp`) AS `timestamp`
        FROM phone_twitter_messages
        WHERE sender=@loggedInAs OR recipient=@loggedInAs
        GROUP BY username
    ) f_m) ON m.`timestamp`=f_m.`timestamp`
    INNER JOIN phone_twitter_accounts a ON a.username=f_m.username
    WHERE m.sender=@loggedInAs OR m.recipient=@loggedInAs
    GROUP BY f_m.username
    ORDER BY m.`timestamp` DESC
    LIMIT @page, @perPage
  ]], {
    ["@loggedInAs"] = username,
    ["@page"]       = offset,
    ["@perPage"]    = 15,
  }, cb)
end)

-- ─────────────────────────────────────────────────────────────
-- Background thread: periodically prune old trending hashtags
-- ─────────────────────────────────────────────────────────────
CreateThread(function()
  if not (Config.BirdyTrending and Config.BirdyTrending.Enabled) then return end

  -- Wait for the database checker to finish initialising
  while not DatabaseCheckerFinished do
    Wait(500)
  end

  local resetHours = tostring(Config.BirdyTrending.Reset or 24)

  while true do
    MySQL.Async.execute(
      ("DELETE FROM phone_twitter_hashtags WHERE last_used < DATE_SUB(NOW(), INTERVAL %s HOUR)"):format(resetHours),
      {}
    )
    Wait(3600000)  -- run once per hour
  end
end)