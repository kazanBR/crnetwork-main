-- ── Helper: decode JSON fields on a video row and normalise booleans ──
local function normaliseVideoRow(video)
    -- Decode metadata JSON if present
    if video.metadata then
        video.metadata = json.decode(video.metadata)
    end

    -- Decode and resolve music JSON if present
    if video.music then
        video.music = json.decode(video.music)

        local songEntry = Music.Songs[video.music.path]
        if songEntry then
            -- Attach album cover to song entry if available
            local albumEntry = Music.Albums[songEntry.album]
            if albumEntry then
                songEntry.Cover = albumEntry.Cover
            end

            -- Flatten into a clean music table
            video.music = {
                title  = songEntry.Title,
                artist = songEntry.Artist,
                cover  = songEntry.Cover,
                volume = video.music.volume,
                path   = video.music.path,
            }
        end
    end

    -- Normalise integer booleans returned by MySQL (1 → true, else → false)
    video.liked  = video.liked  == 1
    video.saved  = video.saved  == 1
    video.viewed = video.viewed == 1

    return video
end

-- ── NUI callback: route all TikTok actions from the React frontend ──
RegisterNUICallback("TikTok", function(data, cb)
    if not currentPhone then return end

    local action = data.action
    debugprint("Trendy:" .. (action or ""))

    -- Account actions
    if action == "login" then
        TriggerCallback("tiktok:login", cb, data.data.username, data.data.password)

    elseif action == "signup" then
        TriggerCallback("tiktok:signup", cb, data.data.username, data.data.password, data.data.name)

    elseif action == "changePassword" then
        TriggerCallback("tiktok:changePassword", cb, data.oldPassword, data.newPassword)

    elseif action == "deleteAccount" then
        TriggerCallback("tiktok:deleteAccount", cb, data.password)

    elseif action == "logout" then
        TriggerCallback("tiktok:logout", cb)

    elseif action == "isLoggedIn" then
        TriggerCallback("tiktok:isLoggedIn", cb)

    -- Profile actions
    elseif action == "getProfile" then
        TriggerCallback("tiktok:getProfile", cb, data.username)

    elseif action == "updateProfile" then
        TriggerCallback("tiktok:updateProfile", cb, data.data)

    -- Social / follow actions
    elseif action == "searchAccounts" then
        TriggerCallback("tiktok:searchAccounts", cb, data.query, data.page)

    elseif action == "toggleFollow" then
        TriggerCallback("tiktok:toggleFollow", cb, data.data.username, data.data.follow)

    elseif action == "getFollowing" then
        TriggerCallback("tiktok:getFollowing", cb, data.username, data.page)

    elseif action == "getFollowers" then
        TriggerCallback("tiktok:getFollowers", cb, data.username, data.page)

    -- Video actions
    elseif action == "uploadVideo" then
        local videoData = data.data

        -- Validate required fields before sending to server
        if not videoData.src or not videoData.caption then
            return cb({ success = false, error = "invalid_caption" })
        end

        -- Validate music object has required fields
        if videoData.music then
            if not videoData.music.path or not videoData.music.volume then
                return cb({ success = false, error = "invalid_music" })
            end
            videoData.music = json.encode(videoData.music)
        end

        -- Encode metadata table (nil out if empty)
        if videoData.metadata then
            if type(videoData.metadata) == "table" then
                local isEmpty = true
                for _ in pairs(videoData.metadata) do
                    isEmpty = false
                    break
                end
                videoData.metadata = isEmpty and nil or json.encode(videoData.metadata)
            end
        else
            videoData.metadata = nil
        end

        TriggerCallback("tiktok:uploadVideo", cb, videoData)

    elseif action == "deleteVideo" then
        TriggerCallback("tiktok:deleteVideo", cb, data.id)

    elseif action == "togglePinnedVideo" then
        TriggerCallback("tiktok:togglePinnedVideo", cb, data.id, data.toggle)

    elseif action == "getVideos" then
        local page = data.page or 0
        -- Normalise each video row in the result before forwarding to NUI
        TriggerCallback("tiktok:getVideos", function(rows)
            for i = 1, #rows do
                rows[i] = normaliseVideoRow(rows[i])
            end
            cb(rows)
        end, data.data, page)

    elseif action == "getVideo" then
        -- Normalise the single video row in the result before forwarding to NUI
        TriggerCallback("tiktok:getVideo", function(result)
            if result.video then
                result.video = normaliseVideoRow(result.video)
            end
            cb(result)
        end, data.id)

    elseif action == "setViewed" then
        TriggerServerEvent("phone:tiktok:setViewed", data.id)
        cb("ok")

    elseif action == "toggleLike" then
        TriggerCallback("tiktok:toggleVideoAction", cb, "like", data.id, data.toggle)

    elseif action == "toggleSave" then
        TriggerCallback("tiktok:toggleVideoAction", cb, "save", data.id, data.toggle)

    -- Comment actions
    elseif action == "postComment" then
        TriggerCallback("tiktok:postComment", cb, data.data.id, data.data.replyTo, data.data.comment)

    elseif action == "getComments" then
        TriggerCallback("tiktok:getComments", cb, data.data.id, data.data.replyTo, data.data.creator, data.page)

    elseif action == "deleteComment" then
        TriggerCallback("tiktok:deleteComment", cb, data.id, data.videoId)

    elseif action == "setPinnedComment" then
        TriggerCallback("tiktok:setPinnedComment", cb, data.commentId, data.videoId)

    elseif action == "toggleLikeComment" then
        TriggerCallback("tiktok:toggleLikeComment", cb, data.id, data.toggle)

    -- Messaging actions
    elseif action == "getRecentMessages" then
        TriggerCallback("tiktok:getRecentMessages", cb)

    elseif action == "getMessages" then
        TriggerCallback("tiktok:getMessages", cb, data.id, data.page)

    elseif action == "sendMessage" then
        -- Block sending if the player cannot currently interact (e.g. in a cutscene)
        if not CanInteract() then
            return cb(false)
        end
        TriggerCallback("tiktok:sendMessage", cb, data.data)

    elseif action == "getChannelId" then
        TriggerCallback("tiktok:getChannelId", cb, data.username)

    -- Notification actions
    elseif action == "getNotifications" then
        TriggerCallback("tiktok:getNotifications", cb, data.page)

    elseif action == "getUnreadMessages" then
        TriggerCallback("tiktok:getUnreadMessages", cb)

    elseif action == "clearUnreadMessages" then
        TriggerServerEvent("phone:tiktok:clearUnreadMessages", data.id)
    end
end)

-- ── Net event: server tells clients to update follower count for a user ──
RegisterNetEvent("phone:tiktok:updateFollowers", function(username, method)
    SendReactMessage("tiktok:updateFollowers", { username = username, method = method })
end)

-- ── Net event: server tells clients to update following count for a user ──
RegisterNetEvent("phone:tiktok:updateFollowing", function(username, method)
    SendReactMessage("tiktok:updateFollowing", { username = username, method = method })
end)

-- ── Net event: server tells clients to update like/save/comment counts on a video ──
RegisterNetEvent("phone:tiktok:updateVideoStats", function(statType, videoId, method, count)
    local payload = { id = videoId, method = method, count = count }

    if statType == "like" then
        SendReactMessage("tiktok:updateLikes", payload)
    elseif statType == "save" then
        SendReactMessage("tiktok:updateSaves", payload)
    elseif statType == "comment" then
        SendReactMessage("tiktok:updateComments", payload)
    end
end)

-- ── Net event: server tells clients to update reply/like counts on a comment ──
RegisterNetEvent("phone:tiktok:updateCommentStats", function(statType, commentId, method)
    local payload = { id = commentId, method = method }

    if statType == "reply" then
        SendReactMessage("tiktok:updateReplies", payload)
    elseif statType == "like" then
        SendReactMessage("tiktok:updateCommentLikes", payload)
    end
end)

-- ── Net event: a new DM has arrived for this client ──
RegisterNetEvent("phone:tiktok:receivedMessage", function(messageData)
    SendReactMessage("tiktok:receivedMessage", messageData)
end)

-- ── Net event: a new video was posted; forward to local event bus ──
RegisterNetEvent("phone:tiktok:newVideo", function(postData)
    TriggerEvent("lb-phone:trendy:newPost", postData)
end)