-- MySQL returns 1/0 for booleans; normalise to true/false
local function toBool(v) return v == true or v == 1 end

-- Parses a raw post object from the server into a structured { user, tweet } table
local function parsePost(rawPost)
  if not rawPost then
    return {}
  end

  -- Parse attachments: may arrive as a JSON string or already as a table
  local attachments = rawPost.attachments
  if type(attachments) == "string" then
    attachments = json.decode(attachments)
  end

  -- Validate that attachments is an array-type table; discard if malformed
  if attachments then
    if type(attachments) == "table" and table.type(attachments) == "array" then
      -- attachments is valid, keep as-is
    else
      attachments = nil
      debugprint("Malformed attachments for birdy post", rawPost.id)
    end
  end

  local user = {
    profile_picture = rawPost.profile_image,
    name            = rawPost.display_name,
    username        = rawPost.username,
    verified        = toBool(rawPost.verified),
    private         = toBool(rawPost.private),
  }

  local tweet = {
    id                  = rawPost.id,
    content             = rawPost.content,
    date_created        = rawPost.timestamp,
    replies             = rawPost.reply_count,
    likes               = rawPost.like_count,
    retweets            = rawPost.retweet_count,
    attachments         = attachments,
    replyToId           = rawPost.reply_to,
    liked               = toBool(rawPost.liked),
    retweeted           = toBool(rawPost.retweeted),
    replyToAuthor       = rawPost.replyToAuthor,
    retweetedByName     = rawPost.retweeted_by_display_name,
    retweetedByUsername = rawPost.retweeted_by_username,
  }

  return { user = user, tweet = tweet }
end

-- Fetches and returns a parsed list of posts, optionally injecting a promoted post
local function getPosts(filter, page)
  local rawPosts = AwaitCallback("birdy:getPosts", filter, page)

  -- Parse every post
  local posts = {}
  for i = 1, #rawPosts do
    posts[i] = parsePost(rawPosts[i])
  end

  -- Determine insertion index for promoted post (capped at list length - 1)
  local insertIndex = math.random(3, 6)
  if insertIndex >= #posts then
    insertIndex = #posts - 1
  end

  -- Inject a promoted post if the feature is enabled and there are enough posts
  if Config.PromoteBirdy and Config.PromoteBirdy.Enabled then
    if #rawPosts > 1 then
      local promotedRaw = AwaitCallback("birdy:getRandomPromoted")
      if promotedRaw then
        local promotedPost = parsePost(promotedRaw)
        promotedPost.tweet.promoted = true
        table.insert(posts, insertIndex, promotedPost)
      end
    end
  end

  return posts
end

-- Actions that require the player to be able to interact (not cuffed, etc.)
local interactActions = { "login", "toggleFollow", "toggleLike", "toggleRetweet", "sendMessage" }

-- Main NUI callback handler for all Birdy (Twitter) actions
RegisterNUICallback("Twitter", function(data, cb)
  -- Ignore if no phone is active
  if not currentPhone then return end

  local action = data.action
  debugprint("Birdy:" .. (action or ""))

  -- Gate certain actions behind CanInteract()
  if table.contains(interactActions, action) then
    if not CanInteract() then
      return cb(false)
    end
  end

  if action == "createAccount" then
    local d = data.data
    TriggerCallback("birdy:createAccount", cb, d.name, d.username, d.password)

  elseif action == "changePassword" then
    TriggerCallback("birdy:changePassword", cb, data.oldPassword, data.newPassword)

  elseif action == "deleteAccount" then
    TriggerCallback("birdy:deleteAccount", cb, data.password)

  elseif action == "login" then
    local d = data.data
    TriggerCallback("birdy:login", cb, d.username, d.password)

  elseif action == "isLoggedIn" then
    TriggerCallback("birdy:isLoggedIn", cb)

  elseif action == "sendTweet" then
    local d = data.data
    TriggerCallback("birdy:sendPost", cb, d.content, d.attachments, d.replyTo, d.hashtags)

  elseif action == "updateProfile" then
    TriggerCallback("birdy:updateProfile", cb, data.data)

  elseif action == "searchAccounts" then
    TriggerCallback("birdy:searchAccounts", function(results)
      local accounts = {}
      for i = 1, #results do
        local raw = results[i]
        accounts[i] = {
          username        = raw.username,
          name            = raw.display_name,
          profile_picture = raw.profile_image,
          verified        = toBool(raw.verified),
          private         = toBool(raw.private),
        }
      end
      cb(accounts)
    end, data.query, data.page)

  elseif action == "searchTweets" then
    TriggerCallback("birdy:searchTweets", function(results)
      local tweets = {}
      for i = 1, #results do
        tweets[i] = parsePost(results[i])
      end
      cb(tweets)
    end, data.query, data.page)

  elseif action == "getProfile" then
    TriggerCallback("birdy:getProfile", function(profile)
      if not profile then
        debugprint("Birdy: failed to get profile", data.data.username)
        return cb()
      end
      -- Parse pinned tweet if present
      if profile.pinnedTweet then
        profile.pinnedTweet = parsePost(profile.pinnedTweet)
      end
      cb(profile)
    end, data.data.username)

  elseif action == "getFollowers" then
    TriggerCallback("birdy:getData", cb, "followers", data.data.username, data.data.page)

  elseif action == "getFollowing" then
    TriggerCallback("birdy:getData", cb, "following", data.data.username, data.data.page)

  elseif action == "getLikes" then
    TriggerCallback("birdy:getData", cb, "likes", tostring(data.data.tweet_id), data.data.page)

  elseif action == "getRetweeters" then
    TriggerCallback("birdy:getData", cb, "retweeters", tostring(data.data.tweet_id), data.data.page)

  elseif action == "getTweets" then
    -- Normalise filter key and treat empty tables as nil
    local filter = data.filter or data.filters
    if filter and next(filter) == nil then
      filter = nil
    end
    cb(getPosts(filter, data.page))

  elseif action == "getTweet" then
    TriggerCallback("birdy:getPost", function(rawPost)
      cb(parsePost(rawPost))
    end, data.tweetId)

  elseif action == "getAuthor" then
    TriggerCallback("birdy:getAuthor", cb, data.tweetId)

  elseif action == "toggleFollow" then
    TriggerCallback("birdy:toggleFollow", cb, data.data.username, data.data.following)

  elseif action == "toggleNotifications" then
    TriggerCallback("birdy:toggleNotifications", cb, data.data.username, data.data.toggle)

  elseif action == "toggleLike" then
    TriggerCallback("birdy:toggleInteraction", cb, "like", tostring(data.tweet_id), data.liked)

  elseif action == "toggleRetweet" then
    TriggerCallback("birdy:toggleInteraction", cb, "retweet", tostring(data.tweet_id), data.retweeted)

  elseif action == "deleteTweet" then
    TriggerCallback("birdy:deletePost", cb, data.tweet_id)

  elseif action == "promoteTweet" then
    TriggerCallback("birdy:promotePost", cb, data.tweet_id)

  elseif action == "sendMessage" then
    local d = data.data
    TriggerCallback("birdy:sendMessage", cb, d.recipient, d.content, d.attachments)

  elseif action == "getMessages" then
    local d = data.data
    TriggerCallback("birdy:getMessages", function(messages)
      -- Decode attachment JSON strings in-place
      for i = 1, #messages do
        local msg = messages[i]
        if msg.attachments then
          msg.attachments = json.decode(msg.attachments)
        end
      end
      cb(messages)
    end, d.username, d.page)

  elseif action == "getRecentMessages" then
    TriggerCallback("birdy:getRecentMessages", cb, data.page)

  elseif action == "signOut" then
    TriggerCallback("birdy:signOut", cb)

  elseif action == "getNotifications" then
    TriggerCallback("birdy:getNotifications", function(result)
      -- Decode attachment JSON strings in notification list
      for _, notification in pairs(result.notifications) do
        if notification.attachments then
          notification.attachments = json.decode(notification.attachments)
        end
      end
      cb(result)
    end, data.page)

  elseif action == "getRecentHashtags" then
    TriggerCallback("birdy:getRecentHashtags", cb)

  elseif action == "pinTweet" then
    -- Pass tweet_id only when toggling on; nil unpin
    local tweetId = data.toggle and data.tweet_id or nil
    TriggerCallback("birdy:pinPost", cb, tweetId)

  elseif action == "getFollowRequests" then
    TriggerCallback("birdy:getFollowRequests", cb, data.page or 0)

  elseif action == "handleFollowRequest" then
    TriggerCallback("birdy:handleFollowRequest", cb, data.username, data.accept)
  end
end)

-- Server → client: update tweet engagement counts in the UI
RegisterNetEvent("phone:twitter:updateTweetData")
AddEventHandler("phone:twitter:updateTweetData", function(tweetId, updateData, increment)
  debugprint("updateTweetData", tweetId, updateData, increment)
  SendReactMessage("twitter:updateTweetData", {
    tweetId   = tweetId,
    data      = updateData,
    increment = increment,
  })
end)

-- Server → client: update profile data in the UI
RegisterNetEvent("phone:twitter:updateProfileData")
AddEventHandler("phone:twitter:updateProfileData", function(username, updateData, increment)
  debugprint("updateProfileData", username, updateData, increment)
  SendReactMessage("twitter:updateProfileData", {
    username  = username,
    data      = updateData,
    increment = increment,
  })
end)

-- Server → client: new direct message received
RegisterNetEvent("phone:twitter:newMessage")
AddEventHandler("phone:twitter:newMessage", function(messageData)
  SendReactMessage("twitter:newMessage", messageData)
end)

-- Server → client: new tweet posted (also fires a local event for other resources)
RegisterNetEvent("phone:twitter:newtweet")
AddEventHandler("phone:twitter:newtweet", function(rawPost)
  TriggerEvent("lb-phone:birdy:newPost", rawPost)
  SendReactMessage("twitter:newTweet", parsePost(rawPost))
end)

-- Public export: programmatically send a tweet from another resource
local function SendTweet(data)
  assert(type(data) == "table",
    "Expected table for data, got " .. type(data))
  assert(type(data.content) == "string",
    "Expected string for data.content, got " .. type(data.content))
  assert(type(data.attachments) == "table" or data.attachments == nil,
    "Expected table / nil for data.attachments, got " .. type(data.attachments))
  assert(type(data.replyTo) == "string" or data.replyTo == nil,
    "Expected string / nil for data.replyTo, got " .. type(data.replyTo))
  assert(type(data.hashtags) == "table" or data.hashtags == nil,
    "Expected table / nil for data.hashtags, got " .. type(data.hashtags))

  if not CanInteract() then return end

  return AwaitCallback("birdy:sendPost", data.content, data.attachments, data.replyTo, data.hashtags)
end

exports("SendTweet", SendTweet)
exports("PostBirdy", SendTweet)  -- alias