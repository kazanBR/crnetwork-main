-- ── Helper: get logged-in TikTok username for a source player ──
local function getLoggedInAs(src)
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then return false end
    return GetLoggedInAccount(phoneNumber, "TikTok")
end

-- ── Helper: fetch full account data by username ──
local function getAccountData(username, loggedIn)
    local fields = "`name`, bio, avatar, username, verified, follower_count, following_count, like_count, twitter, instagram, show_likes"
    local result

    if loggedIn then
        local sql = string.format([[
            SELECT %s,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = @loggedIn) AS isFollowingYou,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @loggedIn AND followed = @username) AS isFollowing
            FROM phone_tiktok_accounts WHERE username = @username
        ]], fields)
        local rows = MySQL.Sync.fetchAll(sql, { ["@username"] = username, ["@loggedIn"] = loggedIn })
        result = rows and rows[1]
    else
        local sql = string.format("SELECT %s FROM phone_tiktok_accounts WHERE username = @username", fields)
        local rows = MySQL.Sync.fetchAll(sql, { ["@username"] = username })
        result = rows and rows[1]
    end

    if result then
        result.isFollowing = result.isFollowing == 1
        result.isFollowingYou = result.isFollowingYou == 1
    end

    return result
end

-- ── Notification type → localization key map ──
local notificationTypes = {
    like         = "BACKEND.TIKTOK.LIKE",
    save         = "BACKEND.TIKTOK.SAVE",
    comment      = "BACKEND.TIKTOK.COMMENT",
    follow       = "BACKEND.TIKTOK.FOLLOW",
    like_comment = "BACKEND.TIKTOK.LIKED_COMMENT",
    reply        = "BACKEND.TIKTOK.REPLIED_COMMENT",
    message      = "BACKEND.TIKTOK.DM",
}

-- ── Helper: send a TikTok in-app notification ──
local function sendTikTokNotification(recipient, sender, notifType, videoId, commentId, messageData)
    local locKey = notificationTypes[notifType]
    if not locKey or recipient == sender then return end

    local senderAccount = getAccountData(sender)
    if not senderAccount then return end

    -- Deduplicate non-DM notifications
    if notifType ~= "message" then
        local query = "SELECT 1 FROM phone_tiktok_notifications WHERE username = ? AND `from` = ? AND `type` = ?"
        local params = { recipient, sender, notifType }

        if videoId then
            query = query .. " AND video_id = ?"
            params[#params + 1] = videoId
        end
        if commentId then
            query = query .. " AND comment_id = ?"
            params[#params + 1] = commentId
        end

        local exists = MySQL.scalar.await(query, params) == 1
        if exists then return end

        MySQL.insert(
            "INSERT INTO phone_tiktok_notifications (username, `from`, `type`, video_id, comment_id) VALUES (?, ?, ?, ?, ?)",
            { recipient, sender, notifType, videoId, commentId }
        )
    end

    -- Resolve video thumbnail
    local thumbnail = nil
    if videoId then
        thumbnail = MySQL.Sync.fetchScalar("SELECT src FROM phone_tiktok_videos WHERE id = @id", { ["@id"] = videoId })
    end

    local notification = {
        app       = "TikTok",
        title     = L(locKey, { displayName = senderAccount.name }),
        thumbnail = thumbnail,
    }

    if notifType == "message" then
        notification.avatar    = senderAccount.avatar
        notification.content   = messageData.content
        notification.showAvatar = true
    end

    NotifyLoggedInAccounts("TikTok", recipient, notification)
end

-- ── Helper: register an authenticated callback (requires TikTok login) ──
local function registerAuthCallback(event, handler, opts)
    BaseCallback("tiktok:" .. event, function(src, cb, ...)
        local loggedInAs = GetLoggedInAccount(GetEquippedPhoneNumber(src) or "", "TikTok")
        if not loggedInAs then return cb(opts) end -- opts used as default return when not logged in
        handler(src, cb, loggedInAs, ...)
    end, opts)
end

-- ── Background thread: wait for DB then periodically clean old notifications ──
CreateThread(function()
    while not DatabaseCheckerFinished do
        Wait(500)
    end
    while true do
        MySQL.Async.execute("DELETE FROM phone_tiktok_notifications WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL 7 DAY)", {})
        Wait(3600000)
    end
end)

-- ────────────────────────────────────────────────────
--  NOTIFICATIONS
-- ────────────────────────────────────────────────────

RegisterLegacyCallback("tiktok:getNotifications", function(src, cb, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local offset = ((page or 0)) * 15

    MySQL.Async.fetchAll([[
        SELECT
            n.`type`, n.`timestamp`, n.video_id AS videoId,
            a.`name`, a.avatar, a.username, a.verified,
            CASE WHEN n.video_id IS NOT NULL THEN v.src ELSE NULL END AS videoSrc,
            n.comment_id,
            CASE WHEN n.comment_id IS NOT NULL THEN c.comment ELSE NULL END AS commentText,
            CASE
                WHEN n.`type` = 'follow' THEN
                    CASE WHEN f.follower IS NOT NULL THEN TRUE ELSE FALSE END
                ELSE NULL
            END AS isFollowing,
            CASE WHEN n.`type` = 'reply' THEN c_original.comment ELSE NULL END AS originalText
        FROM phone_tiktok_notifications n
        LEFT JOIN phone_tiktok_accounts a ON n.from = a.username
        LEFT JOIN phone_tiktok_videos v ON n.video_id = v.id
        LEFT JOIN phone_tiktok_comments c ON n.comment_id = c.id
        LEFT JOIN phone_tiktok_comments c_original ON c.reply_to = c_original.id
        LEFT JOIN phone_tiktok_follows f ON n.username = f.follower AND n.from = f.followed
        WHERE n.username = @username
        ORDER BY n.`timestamp` DESC
        LIMIT @page, @perPage
    ]], {
        ["@username"] = loggedInAs,
        ["@page"]     = offset,
        ["@perPage"]  = 15,
    }, function(rows)
        cb({ success = true, data = rows })
    end)
end)

-- ────────────────────────────────────────────────────
--  ACCOUNT – Login / Signup / Logout / Delete / Password
-- ────────────────────────────────────────────────────

RegisterLegacyCallback("tiktok:login", function(src, cb, username, password)
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then
        return cb({ success = false, error = "no_number" })
    end

    username = username:lower()

    MySQL.Async.fetchScalar(
        "SELECT password FROM phone_tiktok_accounts WHERE username = @username",
        { ["@username"] = username },
        function(storedHash)
            if not storedHash then
                return cb({ success = false, error = "invalid_username" })
            end
            if not VerifyPasswordHash(password, storedHash) then
                return cb({ success = false, error = "incorrect_password" })
            end
            local account = getAccountData(username)
            if not account then
                return cb({ success = false, error = "invalid_username" })
            end
            AddLoggedInAccount(phoneNumber, "TikTok", username)
            cb({ success = true, data = account })
        end
    )
end)

RegisterLegacyCallback("tiktok:signup", function(src, cb, username, password, displayName)
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then
        return cb({ success = false, error = "UNKNOWN" })
    end

    username = username:lower()

    if not IsUsernameValid(username) then
        return cb({ success = false, error = "USERNAME_NOT_ALLOWED" })
    end

    local taken = MySQL.Sync.fetchScalar(
        "SELECT TRUE FROM phone_tiktok_accounts WHERE username = @username",
        { ["@username"] = username }
    )
    if taken then
        return cb({ success = false, error = "USERNAME_TAKEN" })
    end

    MySQL.Sync.execute(
        "INSERT INTO phone_tiktok_accounts (`name`, username, password, phone_number) VALUES (@displayName, @username, @password, @phoneNumber)",
        {
            ["@displayName"]  = displayName,
            ["@username"]     = username,
            ["@password"]     = GetPasswordHash(password),
            ["@phoneNumber"]  = phoneNumber,
        }
    )

    AddLoggedInAccount(phoneNumber, "TikTok", username)
    cb({ success = true })

    -- Auto-follow trendy accounts if configured
    if Config.AutoFollow.Enabled and Config.AutoFollow.Trendy.Enabled then
        for _, trendyAccount in ipairs(Config.AutoFollow.Trendy.Accounts) do
            MySQL.update.await(
                "INSERT INTO phone_tiktok_follows (followed, follower) VALUES (?, ?)",
                { trendyAccount, username }
            )
        end
    end
end, { preventSpam = true, rateLimit = 4 })

-- ── Change Password ──
registerAuthCallback("changePassword", function(src, cb, loggedInAs, phoneNumber, username, oldPassword, newPassword)
    if not Config.ChangePassword.Trendy then
        infoprint("warning", string.format("%s tried to change password on Trendy, but it's not enabled in the config.", src))
        return false
    end

    if oldPassword == newPassword or #newPassword < 3 then
        debugprint("same password / too short")
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_tiktok_accounts WHERE username = ?",
        { username }
    )
    if not storedHash or not VerifyPasswordHash(oldPassword, storedHash) then
        return false
    end

    local updated = MySQL.update.await(
        "UPDATE phone_tiktok_accounts SET password = ? WHERE username = ?",
        { GetPasswordHash(newPassword), username }
    )
    if not (updated > 0) then return false end

    NotifyLoggedInAccounts("TikTok", username, {
        title   = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
        content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    }, { phoneNumber })

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'TikTok' AND phone_number != ?",
        { username, phoneNumber }
    )
    ClearActiveAccountsCache("TikTok", username, phoneNumber)
    Log("Trendy", src, "info", L("BACKEND.LOGS.CHANGED_PASSWORD.TITLE"), L("BACKEND.LOGS.CHANGED_PASSWORD.DESCRIPTION", { number = phoneNumber, username = username, app = "Trendy" }))
    TriggerClientEvent("phone:logoutFromApp", -1, { username = username, app = "tiktok", reason = "password", number = phoneNumber })
    return true
end, false)

-- ── Delete Account (internal helper) ──
local function deleteTrendyAccount(username)
    assert(type(username) == "string", "Expected string for argument 1 (username), got " .. type(username))

    local deleted = MySQL.update.await(
        "DELETE FROM phone_tiktok_accounts WHERE username = ?",
        { username }
    )
    if not (deleted > 0) then return false end

    NotifyLoggedInAccounts("TikTok", username, {
        title   = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
        content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"),
    })
    MySQL.update.await("DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'TikTok'", { username })
    ClearActiveAccountsCache("TikTok", username)
    TriggerClientEvent("phone:logoutFromApp", -1, { username = username, app = "tiktok", reason = "deleted" })
end

exports("DeleteTrendyAccount", deleteTrendyAccount)

-- ── Delete Account (callback) ──
registerAuthCallback("deleteAccount", function(src, cb, loggedInAs, phoneNumber, username, password)
    if not Config.DeleteAccount.Trendy then
        infoprint("warning", string.format("%s tried to delete their account on Trendy, but it's not enabled in the config.", src))
        return false
    end

    local storedHash = MySQL.scalar.await("SELECT password FROM phone_tiktok_accounts WHERE username = ?", { username })
    if not storedHash or not VerifyPasswordHash(password, storedHash) then
        return false
    end

    local success = deleteTrendyAccount(username)
    if success then
        Log("Trendy", src, "info", L("BACKEND.LOGS.DELETED_ACCOUNT.TITLE"), L("BACKEND.LOGS.DELETED_ACCOUNT.DESCRIPTION", { number = phoneNumber, username = username, app = "Trendy" }))
    end
    return success
end, false)

-- ── Logout ──
RegisterLegacyCallback("tiktok:logout", function(src, cb)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then return cb(false) end

    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then return cb(false) end

    RemoveLoggedInAccount(phoneNumber, "TikTok", loggedInAs)
    cb(true)
end)

-- ── Is Logged In ──
RegisterLegacyCallback("tiktok:isLoggedIn", function(src, cb)
    local loggedInAs = getLoggedInAs(src)
    if loggedInAs then
        cb(getAccountData(loggedInAs))
    else
        cb(false)
    end
end)

-- ────────────────────────────────────────────────────
--  PROFILE
-- ────────────────────────────────────────────────────

RegisterLegacyCallback("tiktok:getProfile", function(src, cb, username)
    local loggedInAs = getLoggedInAs(src)
    cb(getAccountData(username, loggedInAs))
end)

RegisterLegacyCallback("tiktok:updateProfile", function(src, cb, data)
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then
        return cb({ success = false, error = "no_number" })
    end

    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local displayName = data.name
    local bio         = data.bio
    local avatar      = data.avatar
    local twitter     = data.twitter
    local instagram   = data.instagram
    local showLikes   = data.show_likes

    if #displayName > 30 then
        return cb({ success = false, error = "display_name_too_long" })
    end
    if bio and #bio > 150 then
        return cb({ success = false, error = "bio_too_long" })
    end

    if twitter then
        local valid = MySQL.Sync.fetchScalar(
            "SELECT TRUE FROM phone_logged_in_accounts WHERE phone_number = @phoneNumber and app = @app and username = @username",
            { ["@phoneNumber"] = phoneNumber, ["@app"] = "Twitter", ["@username"] = twitter }
        )
        if not valid then return cb({ success = false, error = "invalid_twitter" }) end
    end

    if instagram then
        local valid = MySQL.Sync.fetchScalar(
            "SELECT TRUE FROM phone_logged_in_accounts WHERE phone_number = @phoneNumber and app = @app and username = @username",
            { ["@phoneNumber"] = phoneNumber, ["@app"] = "Instagram", ["@username"] = instagram }
        )
        if not valid then return cb({ success = false, error = "invalid_instagram" }) end
    end

    MySQL.Async.execute(
        "UPDATE phone_tiktok_accounts SET `name` = @displayName, bio = @bio, avatar = @avatar, twitter = @twitter, instagram = @instagram, `show_likes` = @showLikes WHERE username = @username",
        {
            ["@displayName"] = displayName,
            ["@bio"]         = bio,
            ["@avatar"]      = avatar,
            ["@twitter"]     = twitter,
            ["@instagram"]   = instagram,
            ["@showLikes"]   = showLikes == true,
            ["@username"]    = loggedInAs,
        },
        function()
            cb({ success = true })
        end
    )
end)

-- ────────────────────────────────────────────────────
--  SOCIAL – Search / Follow / Followers / Following
-- ────────────────────────────────────────────────────

RegisterLegacyCallback("tiktok:searchAccounts", function(src, cb, query, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then return cb(false) end

    local offset = ((page or 0)) * 10

    MySQL.Async.fetchAll([[
        SELECT `name`, username, avatar, verified, follower_count, video_count,
            (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = a.username) AS isFollowing
        FROM phone_tiktok_accounts a
        WHERE username LIKE @query OR `name` LIKE @query
        ORDER BY username
        LIMIT @page, @perPage
    ]], {
        ["@query"]    = "%" .. query .. "%",
        ["@username"] = loggedInAs,
        ["@page"]     = offset,
        ["@perPage"]  = 10,
    }, cb)
end)

RegisterLegacyCallback("tiktok:toggleFollow", function(src, cb, targetUsername, follow)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end
    if targetUsername == loggedInAs then
        return cb({ success = false, error = "cannot_follow_self" })
    end

    local targetAccount = getAccountData(targetUsername)
    if not targetAccount then
        return cb({ success = false, error = "invalid_username" })
    end

    cb({ success = true })

    local sql = follow == true
        and "INSERT IGNORE INTO phone_tiktok_follows (follower, followed) VALUES (@follower, @followed)"
        or  "DELETE FROM phone_tiktok_follows WHERE follower = @follower AND followed = @followed"

    MySQL.Async.execute(sql, { ["@follower"] = loggedInAs, ["@followed"] = targetUsername }, function(rowsChanged)
        if rowsChanged == 0 then return end

        local action = follow == true and "add" or "remove"
        TriggerClientEvent("phone:tiktok:updateFollowers", -1, targetUsername, action)
        TriggerClientEvent("phone:tiktok:updateFollowing", -1, loggedInAs, action)

        if follow == true then
            sendTikTokNotification(targetUsername, loggedInAs, "follow")
        end
    end)
end, { preventSpam = true })

RegisterLegacyCallback("tiktok:getFollowing", function(src, cb, username, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then return cb({}) end

    local offset = ((page or 0)) * 15

    MySQL.Async.fetchAll([[
        SELECT
            a.username, a.`name`, a.avatar, a.verified,
            (SELECT TRUE FROM phone_tiktok_follows WHERE follower = a.username AND followed = @loggedIn) AS isFollowingYou,
            (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @loggedIn AND followed = a.username) AS isFollowing
        FROM phone_tiktok_follows f
        INNER JOIN phone_tiktok_accounts a ON a.username = f.followed
        WHERE f.follower = @username
        ORDER BY a.username
        LIMIT @page, @perPage
    ]], {
        ["@username"] = username,
        ["@loggedIn"] = loggedInAs,
        ["@page"]     = offset,
        ["@perPage"]  = 15,
    }, cb)
end)

RegisterLegacyCallback("tiktok:getFollowers", function(src, cb, username, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then return cb({}) end

    local offset = ((page or 0)) * 15

    MySQL.Async.fetchAll([[
        SELECT
            a.username, a.`name`, a.avatar, a.verified,
            (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = @loggedIn) AS isFollowingYou,
            (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @loggedIn AND followed = @username) AS isFollowing
        FROM phone_tiktok_follows f
        INNER JOIN phone_tiktok_accounts a ON a.username = f.follower
        WHERE f.followed = @username
        ORDER BY a.username
        LIMIT @page, @perPage
    ]], {
        ["@username"] = username,
        ["@loggedIn"] = loggedInAs,
        ["@page"]     = offset,
        ["@perPage"]  = 15,
    }, cb)
end)

-- ────────────────────────────────────────────────────
--  VIDEOS – Shared base query
-- ────────────────────────────────────────────────────

local VIDEO_BASE_QUERY = [[
    SELECT
        v.id, v.src, v.caption, v.`timestamp`,
        p.video_id IS NOT NULL AS pinned,
        v.likes, v.comments, v.views, v.saves,
        (SELECT TRUE FROM phone_tiktok_likes WHERE username = @loggedIn AND video_id = v.id) AS liked,
        (SELECT TRUE FROM phone_tiktok_saves WHERE username = @loggedIn AND video_id = v.id) AS saved,
        w.video_id IS NOT NULL AS viewed,
        v.metadata, v.music,
        a.username, a.`name`, a.avatar, a.verified,
        (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = a.username) AS following
    FROM phone_tiktok_videos v
    INNER JOIN phone_tiktok_accounts a ON a.username = v.username
    LEFT JOIN phone_tiktok_views w ON v.id = w.video_id AND w.username = @loggedIn
    LEFT JOIN phone_tiktok_pinned_videos p ON p.video_id = v.id AND p.username = @loggedIn
]]

-- ── Upload Video ──
RegisterLegacyCallback("tiktok:uploadVideo", function(src, cb, videoData)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    if ContainsBlacklistedWord(src, "Trendy", videoData.caption) then
        return cb(false)
    end

    -- Validate src field
    if not videoData.src or type(videoData.src) ~= "string" or #videoData.src == 0 then
        return cb({ success = false, error = "invalid_src" })
    end

    -- Validate caption field
    if not videoData.caption or type(videoData.caption) ~= "string" or #videoData.caption == 0 then
        return cb({ success = false, error = "invalid_caption" })
    end

    if not ValidateChecks("postTrendy", src, loggedInAs, videoData.src, videoData.caption) then
        debugprint("tiktok:uploadVideo - postTrendy check failed")
        return cb(false)
    end

    local videoId = GenerateId("phone_tiktok_videos", "id")

    MySQL.Async.execute(
        "INSERT INTO phone_tiktok_videos (id, username, src, caption, metadata, music) VALUES (@id, @username, @src, @caption, @metadata, @music)",
        {
            ["@id"]       = videoId,
            ["@username"] = loggedInAs,
            ["@src"]      = videoData.src,
            ["@caption"]  = videoData.caption,
            ["@metadata"] = videoData.metadata,
            ["@music"]    = videoData.music,
        },
        function()
            cb({ success = true, id = videoId })

            local postData = {
                username = loggedInAs,
                caption  = videoData.caption,
                videoUrl = videoData.src,
                id       = videoId,
                source   = src,
            }

            TriggerClientEvent("phone:tiktok:newVideo", -1, postData)
            TriggerEvent("lb-phone:trendy:newPost", postData)
            TrackSocialMediaPost("trendy", { videoData.src })
            Log("Trendy", src, "success",
                L("BACKEND.LOGS.TRENDY_UPLOAD_TITLE"),
                L("BACKEND.LOGS.TRENDY_UPLOAD_DESCRIPTION", { username = loggedInAs, caption = videoData.caption, id = videoId })
            )
        end
    )
end, { preventSpam = true, rateLimit = 6 })

-- ── Delete Video ──
RegisterLegacyCallback("tiktok:deleteVideo", function(src, cb, videoId)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local sql = "DELETE FROM phone_tiktok_videos WHERE id = @id"
    if not IsAdmin(src) then
        sql = sql .. " AND username = @username"
    end

    MySQL.Async.execute(sql, { ["@id"] = videoId, ["@username"] = loggedInAs }, function(rowsChanged)
        cb({ success = rowsChanged > 0 })
        if rowsChanged > 0 then
            Log("Trendy", src, "error",
                L("BACKEND.LOGS.TRENDY_DELETE_TITLE"),
                L("BACKEND.LOGS.TRENDY_DELETE_DESCRIPTION", { username = loggedInAs, id = videoId })
            )
        end
    end)
end)

-- ── Toggle Pinned Video ──
RegisterLegacyCallback("tiktok:togglePinnedVideo", function(src, cb, videoId, pin)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    if pin then
        local count = MySQL.Sync.fetchScalar(
            "SELECT COUNT(*) FROM phone_tiktok_pinned_videos WHERE username = @username",
            { ["@username"] = loggedInAs }
        )
        if count >= 3 then
            return cb({ success = false, error = "max_pinned" })
        end
    end

    local sql = pin
        and "INSERT INTO phone_tiktok_pinned_videos (username, video_id) VALUES (@username, @videoId)"
        or  "DELETE FROM phone_tiktok_pinned_videos WHERE username = @username AND video_id = @videoId"

    MySQL.Async.execute(sql, { ["@videoId"] = videoId, ["@username"] = loggedInAs }, function(rowsChanged)
        cb({ success = rowsChanged > 0 })
    end)
end)

-- ── Get Single Video ──
RegisterLegacyCallback("tiktok:getVideo", function(src, cb, videoId)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local sql = VIDEO_BASE_QUERY .. " WHERE v.id = @id"

    MySQL.Async.fetchAll(sql, {
        ["@id"]       = videoId,
        ["@loggedIn"] = loggedInAs,
        ["@username"] = loggedInAs,
    }, function(rows)
        if #rows == 0 then
            return cb({ success = false, error = "invalid_id" })
        end
        cb({ success = true, video = rows[1] })
    end)
end)

-- ── Get Videos (feed / profile / liked / saved) ──
RegisterLegacyCallback("tiktok:getVideos", function(src, cb, filters, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then return cb({}) end

    local sql = nil
    local perPage = 15

    if filters.full then
        perPage = 5
        local videoType = filters.type

        if videoType == "recent" then
            if filters.id then
                local direction = filters.backwards and ">" or "<"
                if filters.username then
                    sql = VIDEO_BASE_QUERY .. string.format([[
                        WHERE v.username = @username AND v.`timestamp` %s (SELECT `timestamp` FROM phone_tiktok_videos WHERE id = @id)
                        ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                        LIMIT @page, @perPage
                    ]], direction)
                else
                    sql = VIDEO_BASE_QUERY .. string.format([[
                        WHERE v.username != @loggedIn AND v.`timestamp` %s (SELECT `timestamp` FROM phone_tiktok_videos WHERE id = @id)
                        ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                        LIMIT @page, @perPage
                    ]], direction)
                end
            else
                sql = VIDEO_BASE_QUERY .. [[
                    WHERE v.username != @loggedIn
                    ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                    LIMIT @page, @perPage
                ]]
            end
        elseif videoType == "following" then
            sql = VIDEO_BASE_QUERY .. [[
                INNER JOIN phone_tiktok_follows f ON f.followed = v.username
                WHERE f.follower = @loggedIn
                ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                LIMIT @page, @perPage
            ]]
        end
    else
        local videoType = filters.type

        if videoType == "recent" and filters.username then
            if page == 0 then
                sql = [[
                    SELECT v.id, v.src, v.views, p.video_id IS NOT NULL AS pinned
                    FROM phone_tiktok_videos v
                    LEFT JOIN phone_tiktok_pinned_videos p ON p.video_id = v.id AND p.username = @username
                    WHERE v.username = @username
                    ORDER BY (p.video_id IS NOT NULL) DESC, v.`timestamp` DESC
                    LIMIT @page, @perPage
                ]]
            else
                sql = [[
                    SELECT id, src, views
                    FROM phone_tiktok_videos
                    WHERE username = @username
                    ORDER BY `timestamp` DESC
                    LIMIT @page, @perPage
                ]]
            end
        elseif videoType == "liked" then
            sql = [[
                SELECT v.id, v.src, v.views
                FROM phone_tiktok_videos v
                INNER JOIN phone_tiktok_likes l ON l.video_id = v.id
                WHERE l.username = @username
                ORDER BY v.`timestamp` DESC
                LIMIT @page, @perPage
            ]]
        elseif videoType == "saved" then
            if loggedInAs ~= filters.username then
                debugprint("wrong account", loggedInAs, #loggedInAs, filters.username, #(filters.username or ""))
                return cb({})
            end
            sql = [[
                SELECT v.id, v.src, v.views
                FROM phone_tiktok_videos v
                INNER JOIN phone_tiktok_saves s ON s.video_id = v.id
                WHERE s.username = @username
                ORDER BY v.`timestamp` DESC
                LIMIT @page, @perPage
            ]]
        end
    end

    if not sql then return cb({}) end

    local offset = ((page or 0)) * perPage

    MySQL.Async.fetchAll(sql, {
        ["@username"] = filters.username,
        ["@loggedIn"] = loggedInAs,
        ["@id"]       = filters.id,
        ["@page"]     = offset,
        ["@perPage"]  = perPage,
    }, cb)
end)

-- ── Set Viewed ──
RegisterNetEvent("phone:tiktok:setViewed", function(videoId)
    local loggedInAs = getLoggedInAs(source)
    if not loggedInAs then return end

    MySQL.Async.execute(
        "INSERT IGNORE INTO phone_tiktok_views (username, video_id) VALUES (@username, @videoId)",
        { ["@username"] = loggedInAs, ["@videoId"] = videoId }
    )
end)

-- ── Toggle Like / Save ──
RegisterLegacyCallback("tiktok:toggleVideoAction", function(src, cb, action, videoId, toggle)
    if action ~= "like" and action ~= "save" then
        return cb({ success = false, error = "invalid_action" })
    end

    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local videoOwner = MySQL.Sync.fetchScalar(
        "SELECT username FROM phone_tiktok_videos WHERE id = @id",
        { ["@id"] = videoId }
    )
    if not videoOwner then
        return cb({ success = false, error = "invalid_id" })
    end

    cb({ success = true })

    local table = action == "like" and "likes" or "saves"
    local sql = toggle == true
        and string.format("INSERT IGNORE INTO phone_tiktok_%s (username, video_id) VALUES (@username, @videoId)", table)
        or  string.format("DELETE FROM phone_tiktok_%s WHERE username = @username AND video_id = @videoId", table)

    MySQL.Async.execute(sql, { ["@username"] = loggedInAs, ["@videoId"] = videoId }, function(rowsChanged)
        if rowsChanged == 0 then return end

        local changeAction = toggle == true and "add" or "remove"
        TriggerClientEvent("phone:tiktok:updateVideoStats", -1, action, videoId, changeAction)

        if toggle then
            sendTikTokNotification(videoOwner, loggedInAs, action, videoId)
        end
    end)
end, { preventSpam = true, rateLimit = 30 })

-- ────────────────────────────────────────────────────
--  COMMENTS
-- ────────────────────────────────────────────────────

RegisterLegacyCallback("tiktok:postComment", function(src, cb, videoId, replyTo, commentText)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    if not commentText or #commentText == 0 or #commentText > 500 then
        return cb({ success = false, error = "invalid_comment" })
    end

    if ContainsBlacklistedWord(src, "Trendy", commentText) then
        return cb(false)
    end

    local videoOwner = MySQL.Sync.fetchScalar(
        "SELECT username FROM phone_tiktok_videos WHERE id = @id",
        { ["@id"] = videoId }
    )
    if not videoOwner then
        return cb({ success = false, error = "invalid_id" })
    end

    -- Validate reply target if provided
    if replyTo then
        local replyTarget = MySQL.Sync.fetchScalar(
            "SELECT username FROM phone_tiktok_comments WHERE id = @id",
            { ["@id"] = replyTo }
        )
        if not replyTarget then
            return cb({ success = false, error = "invalid_reply_to" })
        end
    end

    local commentId = GenerateId("phone_tiktok_comments", "id")

    MySQL.Async.execute(
        "INSERT INTO phone_tiktok_comments (id, reply_to, video_id, username, comment) VALUES (@id, @replyTo, @videoId, @loggedIn, @comment)",
        {
            ["@id"]      = commentId,
            ["@replyTo"] = replyTo,
            ["@videoId"] = videoId,
            ["@loggedIn"]= loggedInAs,
            ["@comment"] = commentText,
        },
        function(rowsInserted)
            if rowsInserted == 0 then
                return cb({ success = false, error = "failed_insert" })
            end

            TriggerClientEvent("phone:tiktok:updateVideoStats", -1, "comment", videoId, "add")

            if replyTo then
                MySQL.Async.execute(
                    "UPDATE phone_tiktok_comments SET replies = replies + 1 WHERE id = @id",
                    { ["@id"] = replyTo }
                )
                TriggerClientEvent("phone:tiktok:updateCommentStats", -1, "reply", replyTo, "add")
                sendTikTokNotification(videoOwner, loggedInAs, "reply", videoId, commentId)
            end

            cb({ success = true, id = commentId })
            sendTikTokNotification(videoOwner, loggedInAs, "comment", videoId, commentId)
        end
    )
end, { preventSpam = true, rateLimit = 10 })

RegisterLegacyCallback("tiktok:deleteComment", function(src, cb, commentId, videoId)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local ownerFilter = IsAdmin(src) and "" or " AND username = @username"
    local replyCount = 0

    local replyTo = MySQL.Sync.fetchScalar(
        "SELECT reply_to FROM phone_tiktok_comments WHERE id = @id" .. ownerFilter,
        { ["@id"] = commentId, ["@username"] = loggedInAs }
    )

    if replyTo then
        MySQL.Async.execute("UPDATE phone_tiktok_comments SET replies = replies - 1 WHERE id = @id", { ["@id"] = replyTo })
        TriggerClientEvent("phone:tiktok:updateCommentStats", -1, "reply", replyTo, "remove")
    else
        replyCount = MySQL.Sync.fetchScalar(
            "SELECT COUNT(*) FROM phone_tiktok_comments WHERE reply_to = @id",
            { ["@id"] = commentId }
        ) or 0
    end

    MySQL.Async.execute(
        "DELETE FROM phone_tiktok_comments WHERE id = @id" .. ownerFilter,
        { ["@id"] = commentId, ["@username"] = loggedInAs },
        function(rowsChanged)
            if rowsChanged > 0 then
                cb({ success = true })
                TriggerClientEvent("phone:tiktok:updateVideoStats", -1, "comment", videoId, "remove", replyCount + 1)
            else
                cb({ success = false, error = "failed_delete" })
            end
        end
    )
end)

RegisterLegacyCallback("tiktok:setPinnedComment", function(src, cb, commentId, videoId)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local ownsVideo = MySQL.Sync.fetchScalar(
        "SELECT TRUE FROM phone_tiktok_videos WHERE id = @id AND username = @username",
        { ["@id"] = videoId, ["@username"] = loggedInAs }
    )
    if not ownsVideo then
        return cb({ success = false, error = "invalid_id" })
    end

    -- commentId == nil clears the pinned comment
    if commentId ~= nil then
        local ownsComment = MySQL.Sync.fetchScalar(
            "SELECT TRUE FROM phone_tiktok_comments WHERE id = @id AND username = @username",
            { ["@id"] = commentId, ["@username"] = loggedInAs }
        )
        if not ownsComment then
            return cb({ success = false, error = "invalid_comment" })
        end
    end

    MySQL.Async.execute(
        "UPDATE phone_tiktok_videos SET pinned_comment = @commentId WHERE id = @id",
        { ["@commentId"] = commentId, ["@id"] = videoId },
        function(rowsChanged)
            if rowsChanged > 0 then
                cb({ success = true })
            else
                cb({ success = false, error = "failed_update" })
            end
        end
    )
end)

RegisterLegacyCallback("tiktok:getComments", function(src, cb, videoId, replyTo, creatorUsername, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local sql = [[
        SELECT
            a.username, a.`name`, a.avatar, a.verified,
            c.id, c.comment, c.likes, c.replies AS reply_count, c.`timestamp`,
            (SELECT TRUE FROM phone_tiktok_comments_likes WHERE username = @loggedIn AND comment_id = c.id) AS liked,
            (SELECT TRUE FROM phone_tiktok_comments_likes WHERE username = @creator AND comment_id = c.id) AS creator_liked
        FROM phone_tiktok_comments c
        INNER JOIN phone_tiktok_accounts a ON a.username = c.username
        WHERE c.video_id = @videoId
    ]]

    sql = sql .. (replyTo and " AND c.reply_to = @replyTo" or " AND c.reply_to IS NULL")
    sql = sql .. " ORDER BY c.`timestamp` DESC LIMIT @page, @perPage"

    local offset = ((page or 0)) * 15

    MySQL.Async.fetchAll(sql, {
        ["@loggedIn"] = loggedInAs,
        ["@creator"]  = creatorUsername,
        ["@videoId"]  = videoId,
        ["@replyTo"]  = replyTo,
        ["@page"]     = offset,
        ["@perPage"]  = 15,
    }, function(rows)
        cb({ success = true, comments = rows })
    end)
end)

RegisterLegacyCallback("tiktok:toggleLikeComment", function(src, cb, commentId, like)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    if not commentId or like == nil then
        return cb({ success = false, error = "invalid_data" })
    end

    local commentRows = MySQL.Sync.fetchAll(
        "SELECT username, video_id FROM phone_tiktok_comments WHERE id = @id",
        { ["@id"] = commentId }
    )
    local comment = commentRows and commentRows[1]
    if not comment then
        return cb({ success = false, error = "invalid_id" })
    end

    local sql = like == true
        and "INSERT IGNORE INTO phone_tiktok_comments_likes (username, comment_id) VALUES (@username, @commentId)"
        or  "DELETE FROM phone_tiktok_comments_likes WHERE username = @username AND comment_id = @commentId"

    MySQL.Async.execute(sql, { ["@username"] = loggedInAs, ["@commentId"] = commentId }, function(rowsChanged)
        cb({ success = true })

        if rowsChanged == 0 then
            return debugprint("Failed to toggle like comment, no rows changed")
        end

        local changeAction = like == true and "add" or "remove"
        TriggerClientEvent("phone:tiktok:updateCommentStats", -1, "like", commentId, changeAction)

        if like then
            sendTikTokNotification(comment.username, loggedInAs, "like_comment", comment.video_id, commentId)
        end
    end)
end, { preventSpam = true })

-- ────────────────────────────────────────────────────
--  MESSAGING
-- ────────────────────────────────────────────────────

RegisterLegacyCallback("tiktok:getRecentMessages", function(src, cb)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    MySQL.Async.fetchAll([[
        SELECT
            id, last_message, `timestamp`,
            a.username, a.`name`, a.avatar, a.verified, a.follower_count, a.following_count,
            (SELECT COALESCE(amount, 0) FROM phone_tiktok_unread_messages WHERE channel_id = id AND username = @loggedIn) AS unread_messages
        FROM phone_tiktok_channels
        INNER JOIN phone_tiktok_accounts a ON a.username = IF(member_1 = @loggedIn, member_2, member_1)
        WHERE member_1 = @loggedIn OR member_2 = @loggedIn
        ORDER BY `timestamp` DESC
    ]], { ["@loggedIn"] = loggedInAs }, function(rows)
        cb({ success = true, channels = rows })
    end)
end)

RegisterLegacyCallback("tiktok:getMessages", function(src, cb, channelId, page)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local isMember = MySQL.Sync.fetchScalar(
        "SELECT TRUE FROM phone_tiktok_channels WHERE id = @id AND (member_1 = @loggedIn OR member_2 = @loggedIn)",
        { ["@id"] = channelId, ["@loggedIn"] = loggedInAs }
    )
    if not isMember then
        return cb({ success = false, error = "invalid_id" })
    end

    local offset = ((page or 0)) * 25

    MySQL.Async.fetchAll(
        "SELECT id, sender, content, `timestamp` FROM phone_tiktok_messages WHERE channel_id = @channelId ORDER BY `timestamp` DESC LIMIT @page, @perPage",
        { ["@channelId"] = channelId, ["@page"] = offset, ["@perPage"] = 25 },
        function(rows)
            cb({ success = true, messages = rows })
        end
    )
end)

RegisterLegacyCallback("tiktok:getUnreadMessages", function(src, cb)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    MySQL.Async.fetchScalar(
        "SELECT COUNT(*) FROM phone_tiktok_unread_messages WHERE username = @username AND amount > 0",
        { ["@username"] = loggedInAs },
        function(count)
            cb({ success = true, unread = count })
        end
    )
end)

RegisterNetEvent("phone:tiktok:clearUnreadMessages", function(channelId)
    local loggedInAs = getLoggedInAs(source)
    if not loggedInAs then return end

    MySQL.Async.execute(
        "UPDATE phone_tiktok_unread_messages SET amount = 0 WHERE username = @username AND channel_id = @channelId",
        { ["@username"] = loggedInAs, ["@channelId"] = channelId }
    )
end)

RegisterLegacyCallback("tiktok:sendMessage", function(src, cb, msgData)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    if ContainsBlacklistedWord(src, "Trendy", msgData.content) then
        return cb(false)
    end

    local channelId  = msgData.id
    local content    = msgData.content
    local toUsername = msgData.username

    -- Resolve or create channel
    if not channelId then
        if not toUsername then
            return cb({ success = false, error = "invalid_id" })
        end

        channelId = MySQL.Sync.fetchScalar(
            "SELECT id FROM phone_tiktok_channels WHERE (member_1 = @loggedIn AND member_2 = @username) OR (member_1 = @username AND member_2 = @loggedIn)",
            { ["@loggedIn"] = loggedInAs, ["@username"] = toUsername }
        )

        if not channelId then
            channelId = GenerateId("phone_tiktok_channels", "id")
            local inserted = MySQL.Sync.execute(
                "INSERT IGNORE INTO phone_tiktok_channels (id, last_message, member_1, member_2) VALUES (@id, @message, @member_1, @member_2)",
                { ["@id"] = channelId, ["@message"] = content, ["@member_1"] = loggedInAs, ["@member_2"] = toUsername }
            )
            if not (inserted > 0) then
                return cb({ success = false, error = "failed_create_channel" })
            end
        end
    end

    local messageId = GenerateId("phone_tiktok_messages", "id")

    MySQL.Async.execute(
        "INSERT INTO phone_tiktok_messages (id, channel_id, sender, content) VALUES (@messageId, @channelId, @sender, @content)",
        {
            ["@messageId"] = messageId,
            ["@channelId"] = channelId,
            ["@sender"]    = loggedInAs,
            ["@content"]   = content,
        },
        function(rowsInserted)
            cb({ success = rowsInserted > 0, id = messageId, channelId = channelId, error = "failed_insert" })

            if rowsInserted > 0 then
                MySQL.Async.execute([[
                    INSERT INTO phone_tiktok_unread_messages (username, channel_id, amount)
                    VALUES (@username, @channelId, 1)
                    ON DUPLICATE KEY UPDATE amount = amount + 1
                ]], { ["@username"] = toUsername, ["@channelId"] = channelId })

                -- Deliver to recipient if online
                local activeAccounts = GetActiveAccounts("TikTok")
                for phoneNum, accUsername in pairs(activeAccounts) do
                    if accUsername == toUsername then
                        local recipientSrc = GetSourceFromNumber(phoneNum)
                        if recipientSrc then
                            TriggerClientEvent("phone:tiktok:receivedMessage", recipientSrc, {
                                id        = messageId,
                                channelId = channelId,
                                sender    = loggedInAs,
                                content   = content,
                            })
                        end
                    end
                end

                sendTikTokNotification(toUsername, loggedInAs, "message", nil, nil, { content = content })
            end
        end
    )
end, { preventSpam = true })

RegisterLegacyCallback("tiktok:getChannelId", function(src, cb, targetUsername)
    local loggedInAs = getLoggedInAs(src)
    if not loggedInAs then
        return cb({ success = false, error = "not_logged_in" })
    end

    local channelId = MySQL.Sync.fetchScalar(
        "SELECT id FROM phone_tiktok_channels WHERE (member_1 = @loggedIn AND member_2 = @username) OR (member_1 = @username AND member_2 = @loggedIn)",
        { ["@loggedIn"] = loggedInAs, ["@username"] = targetUsername }
    )

    if not channelId then
        return cb({ success = false, error = "no_channel" })
    end

    cb({ success = true, id = channelId })
end)