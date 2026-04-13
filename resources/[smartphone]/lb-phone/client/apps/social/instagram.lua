-- Actions that require CanInteract() check before processing
local INTERACT_ACTIONS = {
    "sendLiveMessage",
    "logIn",
    "toggleFollow",
    "toggleLike",
    "postComment",
    "sendMessage",
}

-- Track the username of the live stream being watched
local watchingUsername = nil

-- Track server IDs of all sources (host + participants) in the current live view
watchingSources = {}

-- Internal: get the current audio volume from settings, defaulting to 0.5
local function GetAudioVolume()
    local volume = settings and settings.sound and settings.sound.volume
    return (volume or 0.5) / 1
end

-- Internal: get our own server ID
local function GetOwnServerId()
    return GetPlayerServerId(PlayerId())
end

-- Internal: stop listening to all current watching sources and reset state
local function StopWatchingAudio()
    MumbleClearVoiceTargetPlayers(1)
    for _, serverId in ipairs(watchingSources) do
        MumbleSetVolumeOverrideByServerId(serverId, -1.0)
        debugprint("stopped listening to", serverId)
    end
    watchingUsername = nil
    watchingSources  = {}
end

-- Internal: decode attachments field in a list of message rows
local function DecodeMessageAttachments(rows)
    for _, row in ipairs(rows) do
        if row.attachments then
            row.attachments = json.decode(row.attachments)
        end
    end
    return rows
end


-- NUI callback handler: routes all Instagram UI actions to the appropriate server callbacks
RegisterNUICallback("Instagram", function(data, cb)
    if not currentPhone then return end

    local action = data.action
    debugprint("InstaPic:" .. (action or ""))

    -- Guard interaction-rate-limited actions
    if table.contains(INTERACT_ACTIONS, action) then
        if not CanInteract() then
            return cb(false)
        end
    end

    -- Live streaming
    if action == "getLives" then
        TriggerCallback("instagram:getLives", cb)

    elseif action == "getLiveViewers" then
        TriggerCallback("instagram:getLiveViewers", cb, data.username)

    elseif action == "goLive" then
        if not AwaitCallback("instagram:canGoLive") then
            debugprint("not allowed to go live")
            return cb(false)
        end
        debugprint("allowed to go live; setting live stream on ui")
        cb(true)

    elseif action == "setLive" then
        debugprint("sending server event to start livestream")
        TriggerServerEvent("phone:instagram:startLive", data.id)
        IsLiveStreaming = true
        EnableWalkableCam()

    elseif action == "endLive" then
        EndLive()
        cb(true)

    elseif action == "viewLive" then
        local liveData = AwaitCallback("instagram:viewLive", data.username)
        if not liveData then
            return cb(false)
        end

        local volume = GetAudioVolume()
        watchingUsername = data.username

        -- Add host and all participants to the voice target list
        watchingSources[#watchingSources + 1] = liveData.host
        for _, participant in ipairs(liveData.participants) do
            watchingSources[#watchingSources + 1] = participant.source
        end

        debugprint("InstaPic: adding voice targets. Volume:", volume)
        MumbleClearVoiceTargetPlayers(1)

        for _, serverId in ipairs(watchingSources) do
            MumbleAddVoiceTargetPlayerByServerId(1, serverId)
            MumbleSetVolumeOverrideByServerId(serverId, volume)
            debugprint("started listening to", serverId)
        end

        cb(#liveData.viewers)

    elseif action == "stopViewing" then
        AwaitCallback("instagram:stopViewing", data.username)
        StopWatchingAudio()

    elseif action == "sendLiveMessage" then
        TriggerServerEvent("phone:instagram:sendLiveMessage", data.data)

    elseif action == "addCall" then
        TriggerServerEvent("phone:instagram:addCall", data.id)

    elseif action == "inviteLive" then
        TriggerServerEvent("phone:instagram:inviteLive", data.username)

    elseif action == "removeLive" then
        TriggerServerEvent("phone:instagram:removeLive", data.username)

    elseif action == "joinLive" then
        local result = AwaitCallback("instagram:joinLive", data.username, data.streamId)
        cb(result)
        if not result then return end
        IsLiveStreaming = true
        EnableWalkableCam()

    -- Stories
    elseif action == "addToStory" then
        if not AwaitCallback("instagram:canCreateStory") then
            debugprint("not allowed to go create story")
            return cb(false)
        end
        debugprint("allowed to create story")
        TriggerCallback("instagram:addToStory", cb, data.media, data.metadata)

    elseif action == "removeFromStory" then
        TriggerCallback("instagram:removeFromStory", cb, data.id)

    elseif action == "getStories" then
        TriggerCallback("instagram:getStories", cb)

    elseif action == "getStory" then
        TriggerCallback("instagram:getStory", cb, data.username)

    elseif action == "getViewers" then
        TriggerCallback("instagram:getViewers", cb, data.id, data.page)

    elseif action == "viewedStory" then
        TriggerCallback("instagram:viewedStory", cb, data.id)

    -- Camera
    elseif action == "flipCamera" then
        ToggleSelfieCam(not IsSelfieCam())

    -- Accounts
    elseif action == "createAccount" then
        TriggerCallback("instagram:createAccount", cb, data.name, data.username, data.password)

    elseif action == "changePassword" then
        TriggerCallback("instagram:changePassword", cb, data.oldPassword, data.newPassword)

    elseif action == "deleteAccount" then
        TriggerCallback("instagram:deleteAccount", cb, data.password)

    elseif action == "logIn" then
        TriggerCallback("instagram:logIn", cb, data.username, data.password)

    elseif action == "signOut" then
        TriggerCallback("instagram:signOut", cb)

    elseif action == "isLoggedIn" then
        TriggerCallback("instagram:isLoggedIn", cb)

    -- Profiles & posts
    elseif action == "getProfile" then
        TriggerCallback("instagram:getProfile", cb, data.username)

    elseif action == "newPost" then
        TriggerCallback("instagram:createPost", cb, data.data.images, data.data.caption, data.data.location)

    elseif action == "deletePost" then
        TriggerCallback("instagram:deletePost", cb, data.id)

    elseif action == "getPosts" then
        TriggerCallback("instagram:getPosts", cb, data.filters, data.page)

    elseif action == "getPost" then
        TriggerCallback("instagram:getPost", cb, data.id)

    elseif action == "updateProfile" then
        TriggerCallback("instagram:updateProfile", cb, data.data)

    -- Social
    elseif action == "getFollowers" then
        TriggerCallback("instagram:getData", cb, "followers", data.data)

    elseif action == "getFollowing" then
        TriggerCallback("instagram:getData", cb, "following", data.data)

    elseif action == "getLikes" then
        TriggerCallback("instagram:getData", cb, "likes", data.data)

    elseif action == "toggleFollow" then
        TriggerCallback("instagram:toggleFollow", cb, data.data.username, data.data.following)

    elseif action == "toggleLike" then
        TriggerCallback("instagram:toggleLike", cb, data.data.postId, data.data.toggle, data.data.isComment)

    -- Comments
    elseif action == "getComments" then
        local rows = AwaitCallback("instagram:getComments", data.postId, data.page or 0)
        local comments = {}
        for i, row in ipairs(rows) do
            comments[i] = {
                user = {
                    username = row.username,
                    avatar   = row.profile_image,
                    verified = row.verified,
                },
                comment = {
                    content   = row.comment,
                    timestamp = row.timestamp,
                    likes     = row.like_count,
                    liked     = row.liked,
                    id        = row.id,
                },
            }
        end
        cb(comments)

    elseif action == "postComment" then
        TriggerCallback("instagram:postComment", cb, data.data.postId, data.data.comment)

    -- Notifications & follow requests
    elseif action == "getNotifications" then
        TriggerCallback("instagram:getNotifications", cb, data.page or 0)

    elseif action == "getFollowRequests" then
        TriggerCallback("instagram:getFollowRequests", cb, data.page or 0)

    elseif action == "handleFollowRequest" then
        TriggerCallback("instagram:handleFollowRequest", cb, data.username, data.accept)

    -- Direct messages
    elseif action == "getRecentMessages" then
        cb(DecodeMessageAttachments(AwaitCallback("instagram:getRecentMessages", data.page)))

    elseif action == "getMessages" then
        cb(DecodeMessageAttachments(AwaitCallback("instagram:getMessages", data.username, data.page)))

    elseif action == "sendMessage" then
        TriggerCallback("instagram:sendMessage", cb, data.username, data.message)

    -- Search
    elseif action == "search" then
        TriggerCallback("instagram:search", cb, data.query, data.page)
    end
end)


-- Net event: new live chat message received
RegisterNetEvent("phone:instagram:addLiveMessage")
AddEventHandler("phone:instagram:addLiveMessage", function(messageData)
    SendReactMessage("instagram:addMessage", messageData)
end)


-- Net event: live stream list updated (someone went live / ended)
RegisterNetEvent("phone:instagram:updateLives")
AddEventHandler("phone:instagram:updateLives", function(livesData)
    SendReactMessage("instagram:updateLives", livesData)
end)


-- Net event: a live stream the player was watching has ended
RegisterNetEvent("phone:instagram:endLive")
AddEventHandler("phone:instagram:endLive", function(hostUsername)
    -- If we were watching this stream, clean up audio
    if hostUsername == watchingUsername then
        StopWatchingAudio()
    end
    SendReactMessage("instagram:liveEnded", hostUsername)
end)


-- Net event: a new participant joined the live stream we're watching
RegisterNetEvent("phone:instagram:joinedLive")
AddEventHandler("phone:instagram:joinedLive", function(participantData)
    SendReactMessage("instagram:joinedLive", participantData)

    -- Don't add ourselves as a voice target
    if participantData.source == GetOwnServerId() then return end

    watchingSources[#watchingSources + 1] = participantData.source

    local volume = GetAudioVolume()
    MumbleAddVoiceTargetPlayerByServerId(1, participantData.source)
    MumbleSetVolumeOverrideByServerId(participantData.source, volume)
    debugprint("InstaPic joinedLive: started listening to", participantData.source, "volume:", volume)
end)


-- Event: settings updated — refresh volume for all watched sources
AddEventHandler("lb-phone:settingsUpdated", function()
    -- Only applies when actively watching a live stream
    if not watchingUsername or #watchingSources == 0 then return end

    local volume  = GetAudioVolume()
    local ownId   = GetOwnServerId()

    for _, serverId in ipairs(watchingSources) do
        if serverId ~= ownId then
            MumbleSetVolumeOverrideByServerId(serverId, volume)
            debugprint("InstaPic settingsUpdated: set volume to", volume, "for", serverId)
        end
    end
end)


-- Net event: a participant left the live stream
RegisterNetEvent("phone:instagram:leftLive")
AddEventHandler("phone:instagram:leftLive", function(hostUsername, participantUsername, participantServerId)
    SendReactMessage("instagram:leftLive", { host = hostUsername, participant = participantUsername })

    -- Don't process if it's ourselves leaving
    if participantServerId == GetOwnServerId() then return end

    for i, serverId in ipairs(watchingSources) do
        if serverId == participantServerId then
            MumbleSetVolumeOverrideByServerId(participantServerId, -1.0)
            MumbleRemoveVoiceTargetPlayerByServerId(1, participantServerId)
            debugprint("InstaPic leftLive: stopped listening to", participantServerId)
            table.remove(watchingSources, i)
            break
        end
    end
end)


-- Net event: live call ended
RegisterNetEvent("phone:instagram:endCall")
AddEventHandler("phone:instagram:endCall", function(callData)
    SendReactMessage("instagram:endCall", callData)
end)


-- Net event: viewer count updated for a live stream
RegisterNetEvent("phone:instagram:updateViewers")
AddEventHandler("phone:instagram:updateViewers", function(username, viewers)
    SendReactMessage("instagram:updateViewers", { username = username, viewers = viewers })
end)


-- Net event: a profile's follower/post/like counts changed
RegisterNetEvent("phone:instagram:updateProfileData")
AddEventHandler("phone:instagram:updateProfileData", function(username, updateData, increment)
    debugprint("updateProfileData", username, updateData, increment)
    SendReactMessage("instagram:updateProfileData", { username = username, data = updateData, increment = increment })
end)


-- Net event: a post's like/comment counts changed
RegisterNetEvent("phone:instagram:updatePostData")
AddEventHandler("phone:instagram:updatePostData", function(postId, updateData, increment)
    debugprint("updatePostData", postId, updateData, increment)
    SendReactMessage("instagram:updatePostData", { postId = postId, data = updateData, increment = increment })
end)


-- Net event: a comment's like count changed
RegisterNetEvent("phone:instagram:updateCommentLikes")
AddEventHandler("phone:instagram:updateCommentLikes", function(commentId, increment)
    debugprint("updateCommentLikes", commentId, increment)
    SendReactMessage("instagram:updateCommentLikes", { commentId = commentId, increment = increment })
end)


-- Net event: new DM received
RegisterNetEvent("phone:instagram:newMessage")
AddEventHandler("phone:instagram:newMessage", function(messageData)
    SendReactMessage("instagram:newMessage", messageData)
end)


-- Net event: player was invited to join a live stream
RegisterNetEvent("phone:instagram:invitedLive")
AddEventHandler("phone:instagram:invitedLive", function(inviteData)
    SendReactMessage("instagram:invitedLive", inviteData)
end)


-- Net event: player was removed from a live stream they were participating in
RegisterNetEvent("phone:instagram:removedLive")
AddEventHandler("phone:instagram:removedLive", function()
    EndLive()
end)


-- Net event: a new post was created — forward to local event bus
RegisterNetEvent("phone:instagram:newPost")
AddEventHandler("phone:instagram:newPost", function(postData)
    TriggerEvent("lb-phone:instapic:newPost", postData)
end)


-- Global: end the current live stream (as host or participant)
function EndLive()
    if not IsLiveStreaming then return end
    IsLiveStreaming = false
    DisableWalkableCam()
    AwaitCallback("instagram:endLive")
end

-- Global: returns whether this client is currently streaming live
function IsLive()
    return IsLiveStreaming
end

-- Global: returns the username of the live stream being watched, or nil
function IsWatchingLive()
    return watchingUsername
end

-- Expose IsLive as a resource export
exports("IsLive", IsLive)