-- Active live streams: keyed by username -> live data
local activeLives = {}


-- Active calls during lives: keyed by source -> call data
local activeCalls = {}

-- Helper: get the logged-in Instagram account for a player source
local function GetInstagramAccount(playerSource)
    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then
        return false
    end
    return GetLoggedInAccount(phoneNumber, "Instagram")
end

-- Helper: register a callback that requires a logged-in account
-- Wraps the callback so that the account is resolved before calling handler(source, cb, account, ...)
local function RegisterInstagramCallback(eventName, handler, options)
    BaseCallback("instagram:" .. eventName, function(source, cb, ...)
        local account = GetLoggedInAccount(cb, "Instagram")  -- NOTE: original passes cb as phoneNumber arg
        if not account then
            return handler(source, cb, nil, ...)
        end
        return handler(source, cb, account, ...)
    end, options)
end

-- =====================================================
-- LIVE STREAMS
-- =====================================================

RegisterLegacyCallback("instagram:getLives", function(playerSource, cb)
    local account = GetInstagramAccount(playerSource)
    if not account then
        return cb({})
    end

    local visibleLives = {}
    for username, liveData in pairs(activeLives) do
        if liveData.private then
            local isFollowing = MySQL.Sync.fetchScalar(
                "SELECT TRUE FROM phone_instagram_follows WHERE follower=@follower AND followed=@followed",
                { ["@follower"] = account, ["@followed"] = username }
            )
            if isFollowing then
                visibleLives[username] = liveData
            end
        else
            visibleLives[username] = liveData
        end
    end
    cb(visibleLives)
end)

RegisterLegacyCallback("instagram:getLiveViewers", function(playerSource, cb, liveId)
    local liveData = activeLives[liveId]
    if not liveData then
        return cb({})
    end

    local viewers = {}
    for _, viewerSource in ipairs(liveData.viewers) do
        local phoneNumber = GetEquippedPhoneNumber(viewerSource)
        if phoneNumber then
            local rows = MySQL.Sync.fetchAll([[
                SELECT
                    a.profile_image AS avatar, a.verified, a.display_name AS `name`, a.username
                FROM phone_logged_in_accounts l
                INNER JOIN phone_instagram_accounts a ON l.username = a.username
                WHERE l.phone_number = ? AND l.active = 1 AND l.app = 'Instagram'
            ]], { phoneNumber })

            if rows and rows[1] then
                viewers[#viewers + 1] = rows[1]
            end
        end
    end
    cb(viewers)
end)

RegisterLegacyCallback("instagram:canGoLive", function(playerSource, cb)
    local account = GetInstagramAccount(playerSource)
    if not account then
        return cb(false)
    end

    local canGo, reason = CanGoLive(playerSource, account)
    if canGo then
        local validated = ValidateChecks("startInstaPicLive", playerSource, account)
        if not validated then
            canGo = false
        end
    end

    if not canGo then
        local phoneNumber = GetEquippedPhoneNumber(playerSource)
        if phoneNumber then
            SendNotification(phoneNumber, {
                app = "Instagram",
                title = reason or L("BACKEND.INSTAGRAM.NOT_ALLOWED_LIVE")
            })
        end
    end

    cb(canGo)
end)

RegisterLegacyCallback("instagram:canCreateStory", function(playerSource, cb)
    local account = GetInstagramAccount(playerSource)
    if not account then
        return cb(false)
    end

    local canCreate, reason = CanCreateStory(playerSource, account)
    if canCreate then
        local validated = ValidateChecks("postInstaPicStory", playerSource, account)
        if not validated then
            canCreate = false
        end
    end

    if not canCreate then
        local phoneNumber = GetEquippedPhoneNumber(playerSource)
        if phoneNumber then
            SendNotification(phoneNumber, {
                app = "Instagram",
                title = reason or L("BACKEND.INSTAGRAM.NOT_ALLOWED_STORY")
            })
        end
    end

    cb(canCreate)
end)

RegisterNetEvent("phone:instagram:startLive")
AddEventHandler("phone:instagram:startLive", function(liveId)
    local playerSource = source
    local account = GetInstagramAccount(playerSource)
    if not account then return end
    if activeLives[account] then return end

    local canGo = CanGoLive(playerSource, account)
    if not canGo then return end
    if not ValidateChecks("startInstaPicLive", playerSource, account) then return end

    local profileData = MySQL.single.await(
        "SELECT profile_image, verified, display_name, private FROM phone_instagram_accounts WHERE username = ?",
        { account }
    )
    if not profileData then return end

    activeLives[account] = {
        id = liveId,
        avatar = profileData.profile_image,
        verified = profileData.verified,
        name = profileData.display_name,
        private = profileData.private,
        host = playerSource,
        viewers = {},
        nearby = {},
        invites = {},
        participants = {},
    }

    Player(playerSource).state.instapicIsLive = account
    TriggerClientEvent("phone:instagram:updateLives", -1, activeLives)

    Log("InstaPic", playerSource, "success",
        L("BACKEND.LOGS.LIVE_TITLE"),
        L("BACKEND.LOGS.STARTED_LIVE", { username = account })
    )
    TrackSimpleEvent("go_live")

    local notification = {
        title = L("APPS.INSTAGRAM.TITLE"),
        content = L("BACKEND.INSTAGRAM.STARTED_LIVE", { username = account })
    }

    local liveNotifSetting = Config.InstaPicLiveNotifications
    if liveNotifSetting then
        local notifScope = (liveNotifSetting == "all") and "all" or "online"
        NotifyEveryone(notifScope, {
            app = "Instagram",
            title = notification.title,
            content = notification.content
        })
    else
        local followers = MySQL.query.await(
            "SELECT follower FROM phone_instagram_follows WHERE followed = ?",
            { account }
        )
        for _, row in ipairs(followers) do
            NotifyLoggedInAccounts("Instagram", row.follower, notification)
        end
    end
end)

-- Internal: end a live that has participants (co-hosts)
local function EndLiveWithParticipants(liveData)
    if not liveData.participants then return end

    local allViewers = table.clone(liveData.viewers)
    allViewers[#allViewers + 1] = liveData.host

    for _, participant in ipairs(liveData.participants) do
        local participantUsername = participant and participant.username
        if participantUsername then
            local participantLive = activeLives[participantUsername]
            if participantLive then
                TriggerClientEvent("phone:phone:removeVoiceTarget", participantLive.host, allViewers)
                Player(participantLive.host).state.instapicIsLive = nil
                activeLives[participantUsername] = nil
                TriggerClientEvent("phone:instagram:endLive", -1, participantUsername)
            end
        end
    end

    for _, nearbySource in ipairs(liveData.nearby) do
        if nearbySource then
            TriggerClientEvent("phone:phone:removeVoiceTarget", nearbySource, allViewers)
            TriggerClientEvent("phone:instagram:leftProximity", -1, nearbySource, liveData.host)
        end
    end

    TriggerClientEvent("phone:phone:removeVoiceTarget", liveData.host, liveData.viewers)
end

-- Internal: remove a participant from a live stream
local function RemoveParticipant(hostUsername, participantUsername)
    local liveData = activeLives[hostUsername]
    if not liveData or not liveData.participants then return end

    local participantSource = nil
    local found = false

    for i, participant in ipairs(liveData.participants) do
        if participant.username == participantUsername then
            participantSource = participant.source
            table.remove(liveData.participants, i)
            found = true
            break
        end
    end

    if not found then return end

    -- Build audience list: viewers + host
    local audience = table.clone(liveData.viewers)
    audience[#audience + 1] = liveData.host

    -- Notify all audience that participant left
    for _, viewerSource in ipairs(audience) do
        TriggerClientEvent("phone:instagram:leftLive", viewerSource, hostUsername, participantUsername, participantSource)
    end

    -- Remove participant from viewer voice targets for other participants
    local viewersCopy = table.clone(liveData.viewers)
    for _, participant in ipairs(liveData.participants) do
        for j, viewerSource in ipairs(viewersCopy) do
            if viewerSource == participant.source then
                table.remove(viewersCopy, j)
                break
            end
        end
    end

    TriggerClientEvent("phone:phone:removeVoiceTarget", participantSource, viewersCopy)
end

RegisterLegacyCallback("instagram:endLive", function(playerSource, cb)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(true) end

    local liveData = activeLives[account]
    if not liveData then return cb(true) end

    if liveData.participant then
        RemoveParticipant(liveData.participant, account)
    else
        EndLiveWithParticipants(liveData)
    end

    activeLives[account] = nil
    Player(playerSource).state.instapicIsLive = nil

    TriggerClientEvent("phone:instagram:updateLives", -1, activeLives)
    TriggerClientEvent("phone:instagram:endLive", -1, account, liveData.participant)

    Log("InstaPic", playerSource, "error",
        L("BACKEND.LOGS.LIVE_TITLE"),
        L("BACKEND.LOGS.ENDED_LIVE", { username = account })
    )

    cb(true)
end)

AddEventHandler("playerDropped", function()
    local droppedSource = source

    for username, liveData in pairs(activeLives) do
        -- Check if dropped player was a viewer
        for i, viewerSource in pairs(liveData.viewers) do
            if viewerSource == droppedSource then
                -- End any active call from this viewer
                if activeCalls[droppedSource] then
                    TriggerClientEvent("phone:endCall", liveData.host, activeCalls[droppedSource])
                    activeCalls[droppedSource] = nil
                end

                table.remove(liveData.viewers, i)
                TriggerClientEvent("phone:instagram:updateViewers", -1, username, #liveData.viewers)
            end
        end

        -- Check if dropped player was the host
        if liveData.host == droppedSource then
            if liveData.participant then
                RemoveParticipant(liveData.participant, username)
            else
                EndLiveWithParticipants(liveData)
            end

            activeLives[username] = nil
            TriggerClientEvent("phone:instagram:updateLives", -1, activeLives)
            TriggerClientEvent("phone:instagram:endLive", -1, username, liveData.participant)

            return
        end
    end
end)

RegisterNetEvent("phone:instagram:addCall")
AddEventHandler("phone:instagram:addCall", function(callData)
    local playerSource = source
    local isViewer = false

    for _, liveData in pairs(activeLives) do
        for _, viewerSource in pairs(liveData.viewers) do
            if viewerSource == playerSource then
                isViewer = true
                break
            end
        end
    end

    if not activeCalls[playerSource] and isViewer then
        activeCalls[playerSource] = callData
    end
end)

RegisterLegacyCallback("instagram:viewLive", function(playerSource, cb, liveId)
    local liveData = activeLives[liveId]
    if not liveData then
        return cb(false)
    end

    -- Check if already viewing
    local alreadyViewing = false
    for _, viewerSource in ipairs(liveData.viewers) do
        if viewerSource == playerSource then
            alreadyViewing = true
            break
        end
    end

    if not alreadyViewing then
        local participants = liveData.participants

        -- Add viewer
        liveData.viewers[#liveData.viewers + 1] = playerSource

        -- Add voice target for host
        TriggerClientEvent("phone:phone:addVoiceTarget", liveData.host, { sources = playerSource })

        -- Update viewer count for all
        TriggerClientEvent("phone:instagram:updateViewers", -1, liveId, #liveData.viewers)

        -- Add voice targets for all participants
        for _, participant in ipairs(participants) do
            TriggerClientEvent("phone:phone:addVoiceTarget", participant.source, { sources = playerSource })
        end

        -- After short delay, set up proximity voice for nearby players
        SetTimeout(500, function()
            local nearby = (liveData and liveData.nearby) or {}
            for _, nearbySource in ipairs(nearby) do
                TriggerClientEvent("phone:phone:addVoiceTarget", nearbySource, { sources = playerSource })
                TriggerClientEvent("phone:instagram:enteredProximity", playerSource, nearbySource, liveData.host)
            end
        end)
    end

    cb(liveData)
end)

RegisterLegacyCallback("instagram:stopViewing", function(playerSource, cb, liveId)
    local liveData = activeLives[liveId]
    if not liveData then
        return cb()
    end

    local wasViewer = false

    for i, viewerSource in pairs(liveData.viewers) do
        if viewerSource == playerSource then
            wasViewer = true

            -- End any active call
            if activeCalls[playerSource] then
                TriggerClientEvent("phone:instagram:endCall", liveData.host, activeCalls[playerSource])
                activeCalls[playerSource] = nil
            end

            table.remove(liveData.viewers, i)
            break
        end
    end

    -- Remove voice from nearby players
    for _, nearbySource in ipairs(liveData.nearby) do
        if nearbySource then
            TriggerClientEvent("phone:phone:removeVoiceTarget", nearbySource, playerSource)
            TriggerClientEvent("phone:instagram:leftProximity", playerSource, nearbySource, liveData.host)
        end
    end

    if wasViewer then
        TriggerClientEvent("phone:phone:removeVoiceTarget", liveData.host, playerSource)
        TriggerClientEvent("phone:instagram:updateViewers", -1, liveId, #liveData.viewers)

        for _, participant in ipairs(liveData.participants) do
            TriggerClientEvent("phone:phone:removeVoiceTarget", participant.source, playerSource)
        end
    end

    cb()
end)

RegisterNetEvent("phone:instagram:inviteLive")
AddEventHandler("phone:instagram:inviteLive", function(inviteeUsername)
    local playerSource = source
    local account = GetInstagramAccount(playerSource)
    if not account then return end

    local liveData = activeLives[account]
    if not liveData or not liveData.participants then return end

    -- Can't invite if target already has a live
    if activeLives[inviteeUsername] then return end

    -- Max 3 participants
    if #liveData.participants >= 3 then return end

    -- Check if already a participant
    for _, participant in ipairs(liveData.participants) do
        if participant and participant.username == inviteeUsername then
            return
        end
    end

    -- Record invite
    if not liveData.invites[inviteeUsername] then
        liveData.invites[inviteeUsername] = true
    end

    -- Notify the invitee's active accounts
    local activeAccounts = GetActiveAccounts("Instagram")
    for phoneNumber, username in pairs(activeAccounts) do
        if inviteeUsername == username then
            local inviteeSource = GetSourceFromNumber(phoneNumber)
            if inviteeSource then
                TriggerClientEvent("phone:instagram:invitedLive", inviteeSource, account)
            end
        end
    end
end)

RegisterNetEvent("phone:instagram:removeLive")
AddEventHandler("phone:instagram:removeLive", function(participantUsername)
    local playerSource = source
    local account = GetInstagramAccount(playerSource)
    if not account then return end

    local liveData = activeLives[account]
    if not liveData then return end

    local participantSource = nil
    local found = false

    for _, participant in ipairs(liveData.participants) do
        if participant.username == participantUsername then
            found = true
            participantSource = participant.source
            break
        end
    end

    if found and participantSource then
        RemoveParticipant(account, participantUsername)

        activeLives[participantUsername] = nil
        Player(participantSource).state.instapicIsLive = nil

        TriggerClientEvent("phone:instagram:updateLives", -1, activeLives)
        TriggerClientEvent("phone:instagram:endLive", -1, participantUsername, account)
        TriggerClientEvent("phone:instagram:removedLive", participantSource)
    end

    TriggerClientEvent("phone:instagram:updateLives", -1, activeLives)
end)

RegisterLegacyCallback("instagram:joinLive", function(playerSource, cb, hostUsername, liveId)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    if not ValidateChecks("joinInstaPicLive", playerSource, account, hostUsername) then return end

    local liveData = activeLives[hostUsername]
    if not liveData or not liveData.participants then
        return cb(false)
    end

    -- Already has a live
    if activeLives[account] then
        return cb(false)
    end

    -- Remove pending invite
    if liveData.invites[account] then
        liveData.invites[account] = nil
    end

    -- Max 3 participants
    if #liveData.participants >= 3 then
        return cb(false)
    end

    -- Already a participant
    for _, participant in ipairs(liveData.participants) do
        if participant and participant.username == account then
            return cb(false)
        end
    end

    local profileData = MySQL.single.await(
        "SELECT profile_image, verified, display_name FROM phone_instagram_accounts WHERE username=@username",
        { ["@username"] = account }
    )
    if not profileData then return cb(false) end

    -- Add to host's participants list
    liveData.participants[#liveData.participants + 1] = {
        username = account,
        name = profileData.display_name,
        avatar = profileData.profile_image,
        verified = profileData.verified,
        id = liveId,
        source = playerSource,
    }

    -- Create a participant live entry
    activeLives[account] = {
        id = liveId,
        avatar = profileData.profile_image,
        verified = profileData.verified,
        name = profileData.display_name,
        host = playerSource,
        nearby = {},
        viewers = {},
        participant = hostUsername,
    }

    Player(playerSource).state.instapicIsLive = account
    TriggerClientEvent("phone:instagram:updateLives", -1, activeLives)

    -- Notify followers of host
    local followers = MySQL.query.await(
        "SELECT follower FROM phone_instagram_follows WHERE followed = @username",
        { ["@username"] = account }
    )
    for _, row in ipairs(followers) do
        NotifyLoggedInAccounts("Instagram", row.follower, {
            app = "Instagram",
            title = L("APPS.INSTAGRAM.TITLE"),
            content = L("BACKEND.INSTAGRAM.JOINED_LIVE", { invitee = account, inviter = hostUsername })
        })
    end

    -- Set up voice for new participant: viewers + host
    local hostViewers = table.clone(activeLives[hostUsername].viewers)
    hostViewers[#hostViewers + 1] = activeLives[hostUsername].host

    TriggerClientEvent("phone:phone:addVoiceTarget", playerSource, { sources = hostViewers })

    for _, viewerSource in ipairs(hostViewers) do
        TriggerClientEvent("phone:instagram:joinedLive", viewerSource, {
            username = account,
            name = profileData.display_name,
            avatar = profileData.profile_image,
            verified = profileData.verified,
            id = liveId,
            host = hostUsername,
            source = playerSource,
        })
    end

    cb(true)
end)

RegisterNetEvent("phone:instagram:sendLiveMessage")
AddEventHandler("phone:instagram:sendLiveMessage", function(messageData)
    local liveId = messageData and messageData.live
    if activeLives[liveId] then
        TriggerClientEvent("phone:instagram:addLiveMessage", -1, messageData)
    end
end)

RegisterNetEvent("phone:instagram:enteredLiveProximity")
AddEventHandler("phone:instagram:enteredLiveProximity", function(liveUsername)
    local playerSource = source

    -- Resolve participant -> host mapping
    local participantLive = activeLives[liveUsername]
    local resolvedHostUsername = liveUsername
    local participantLiveData = {}
    if participantLive and participantLive.participant then
        participantLiveData = activeLives[liveUsername]
        resolvedHostUsername = participantLive.participant
    end

    local liveData = activeLives[resolvedHostUsername]
    if not liveData then return end

    -- Already in nearby
    if table.contains(liveData.nearby, playerSource) then return end

    -- Already a participant
    for _, participant in ipairs(liveData.participants) do
        if participant.source == playerSource then return end
    end

    liveData.nearby[#liveData.nearby + 1] = playerSource

    local shouldHear = table.clone(liveData.viewers)
    if participantLive and participantLive.participant then
        shouldHear[#shouldHear + 1] = liveData.host
    end

    debugprint("shouldHear (joined)", json.encode(shouldHear, { indent = true }))

    TriggerClientEvent("phone:phone:addVoiceTarget", playerSource, { sources = shouldHear })

    local hostSource = (participantLiveData and participantLiveData.host) or liveData.host
    TriggerClientEvent("phone:instagram:enteredProximity", -1, playerSource, hostSource)
end)

RegisterNetEvent("phone:instagram:leftLiveProximity")
AddEventHandler("phone:instagram:leftLiveProximity", function(liveUsername, includeHost)
    local playerSource = source

    -- Resolve participant -> host mapping
    local participantLive = activeLives[liveUsername]
    local resolvedHostUsername = liveUsername
    local participantLiveData = {}
    if participantLive and participantLive.participant then
        participantLiveData = activeLives[liveUsername]
        resolvedHostUsername = participantLive.participant
    end

    local liveData = activeLives[resolvedHostUsername]
    if not liveData then return end

    -- Remove from nearby list
    for i, nearbySource in ipairs(liveData.nearby) do
        if nearbySource == playerSource then
            activeLives[resolvedHostUsername].nearby[i] = nil
            break
        end
    end

    local shouldHear = table.clone(liveData.viewers)
    if participantLive and participantLive.participant or includeHost then
        shouldHear[#shouldHear + 1] = liveData.host
    end

    debugprint("shouldHear (left)", json.encode(shouldHear, { indent = true }))

    TriggerClientEvent("phone:phone:removeVoiceTarget", playerSource, shouldHear)

    local hostSource = (participantLiveData and participantLiveData.host) or liveData.host
    TriggerClientEvent("phone:instagram:leftProximity", -1, playerSource, hostSource)
end)

-- =====================================================
-- STORIES
-- =====================================================

RegisterLegacyCallback("instagram:addToStory", function(playerSource, cb, imageUrl, metadata)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    local storyId = GenerateId("phone_instagram_stories", "id")

    local encodedMetadata = nil
    if metadata then
        encodedMetadata = json.encode(metadata) or nil
    end

    MySQL.Async.execute(
        "INSERT INTO phone_instagram_stories (id, username, image, metadata) VALUES (@id, @username, @image, @metadata)",
        {
            ["@id"] = storyId,
            ["@username"] = account,
            ["@image"] = imageUrl,
            ["@metadata"] = encodedMetadata,
        },
        function(rowsAffected)
            cb(rowsAffected > 0)
        end
    )

    MySQL.Async.fetchAll(
        "SELECT profile_image, verified FROM phone_instagram_accounts WHERE username=@username",
        { ["@username"] = account },
        function(rows)
            TriggerClientEvent("phone:instagram:addStory", -1, {
                username = account,
                avatar = rows[1].profile_image,
                verified = rows[1].verified,
                seen = false,
            })
            Log("InstaPic", playerSource, "info",
                L("BACKEND.LOGS.ADDED_STORY", { username = account }),
                imageUrl
            )
        end
    )
end)

RegisterLegacyCallback("instagram:removeFromStory", function(playerSource, cb, storyId)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    MySQL.Async.execute(
        "DELETE FROM phone_instagram_stories WHERE id=@id AND username=@username",
        { ["@id"] = storyId, ["@username"] = account },
        function(rowsAffected)
            cb(rowsAffected > 0)
        end
    )
end)

RegisterLegacyCallback("instagram:getStories", function(playerSource, cb)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    MySQL.Async.fetchAll([[
        SELECT
            s.username, a.verified, a.profile_image AS avatar,

            (SELECT
                (SELECT COUNT(*) FROM phone_instagram_stories s2
                    WHERE s2.username = s.username AND NOT EXISTS (
                    SELECT TRUE FROM phone_instagram_stories_views v
                    WHERE v.viewer = @loggedInAs AND v.story_id = s2.id
                )
            ) = 0) AS seen

        FROM phone_instagram_stories s

        INNER JOIN phone_instagram_accounts a
        ON a.username = s.username

        WHERE a.private=FALSE OR EXISTS (
            SELECT TRUE FROM phone_instagram_follows f
            WHERE f.followed = s.username AND f.follower = @loggedInAs
        )

        GROUP BY s.username, a.verified, a.profile_image

        ORDER BY MAX(s.`timestamp`) DESC
    ]], { ["@loggedInAs"] = account }, cb)
end)

-- Internal getStory callback (used via RegisterInstagramCallback wrapper)
local function HandleGetStory(playerSource, cb, account, viewerUsername, ownerUsername)
    local stories = MySQL.query.await([[
        SELECT
            s.id,
            s.image,
            s.metadata,
            s.`timestamp`,
            (IF((
                SELECT TRUE FROM phone_instagram_stories_views v
                WHERE v.viewer = ? AND v.story_id = s.id
            ), TRUE, FALSE)) AS seen

        FROM phone_instagram_stories s

        WHERE s.username = ?

        ORDER BY s.timestamp ASC
    ]], { viewerUsername, ownerUsername })

    if not stories or #stories == 0 then
        return {}
    end

    for _, story in ipairs(stories) do
        if story.metadata then
            story.metadata = json.decode(story.metadata)
        end

        -- Auto-mark story as viewed when fetched (fixes ring glitch when navigating to post from story)
        if viewerUsername ~= ownerUsername and not story.seen then
            MySQL.update.await(
                "INSERT IGNORE INTO phone_instagram_stories_views (story_id, viewer) VALUES (?, ?)",
                { story.id, viewerUsername }
            )
            story.seen = true
        end

        -- Owner sees view stats
        if viewerUsername == ownerUsername then
            story.views = MySQL.scalar.await(
                "SELECT COUNT(1) FROM phone_instagram_stories_views WHERE story_id = ? AND viewer != ?",
                { story.id, viewerUsername }
            )
            story.viewers = MySQL.query.await([[
                SELECT
                    a.profile_image AS avatar,
                    a.verified

                FROM
                    phone_instagram_stories_views v

                INNER JOIN phone_instagram_accounts a
                ON a.username = v.viewer

                WHERE
                    v.story_id = ? AND v.viewer != ?

                ORDER BY v.`timestamp` DESC

                LIMIT 3
            ]], { story.id, viewerUsername })
        end
    end

    return stories
end

RegisterCallback("instagram:getStory", function(playerSource, ownerUsername)
    -- The client sends ownerUsername (whose story to view)
    -- The viewer is the logged-in player - resolve from their source
    local viewerAccount = GetInstagramAccount(playerSource)
    local viewerUsername = viewerAccount or ""
    local account = GetLoggedInAccount(viewerUsername, "Instagram")
    return HandleGetStory(playerSource, nil, account, viewerUsername, ownerUsername)
end)

RegisterLegacyCallback("instagram:getViewers", function(playerSource, cb, storyId, page)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    local isOwner = MySQL.Sync.fetchScalar(
        "SELECT TRUE FROM phone_instagram_stories WHERE id = @id AND username = @loggedInAs",
        { ["@id"] = storyId, ["@loggedInAs"] = account }
    )
    if not isOwner then return cb({}) end

    local pageNum = (page or 0) * 15

    MySQL.Async.fetchAll([[
        SELECT a.profile_image AS avatar, a.verified, a.display_name AS `name`, a.username
        FROM phone_instagram_stories_views v

        INNER JOIN phone_instagram_accounts a
        ON a.username = v.viewer

        WHERE v.story_id = @id AND v.viewer != @loggedInAs

        ORDER BY v.`timestamp` DESC

        LIMIT @page, @perPage
    ]], {
        ["@id"] = storyId,
        ["@loggedInAs"] = account,
        ["@page"] = pageNum,
        ["@perPage"] = 15,
    }, cb)
end)

RegisterLegacyCallback("instagram:viewedStory", function(playerSource, cb, storyId)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    MySQL.Async.execute(
        "INSERT IGNORE INTO phone_instagram_stories_views (story_id, viewer) VALUES (@id, @loggedInAs)",
        { ["@id"] = storyId, ["@loggedInAs"] = account },
        function(rowsAffected)
            cb(rowsAffected > 0)
        end
    )
end)

-- Background thread: cleanup expired stories every hour
CreateThread(function()
    while type(DatabaseCheckerFinished) == "function" and not DatabaseCheckerFinished() do
        Wait(500)
    end

    while true do
        MySQL.Async.execute(
            "DELETE FROM phone_instagram_stories WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL 24 HOUR)",
            {}
        )
        Wait(3600000)
    end
end)

-- =====================================================
-- NOTIFICATIONS
-- =====================================================

-- Notification type -> locale key mapping
local notificationLocaleKeys = {
    like_photo    = "BACKEND.INSTAGRAM.LIKED_PHOTO",
    like_comment  = "BACKEND.INSTAGRAM.LIKED_COMMENT",
    comment       = "BACKEND.INSTAGRAM.COMMENTED",
    follow        = "BACKEND.INSTAGRAM.NEW_FOLLOWER",
}

-- Internal: send an Instagram notification to a user
local function SendInstagramNotification(toUsername, fromUsername, notifType, postId)
    if toUsername == fromUsername then return end

    local localeKey = notificationLocaleKeys[notifType]
    if not localeKey then return end

    local content = L(localeKey, { username = fromUsername })

    -- Check for duplicate notifications (follow/like types)
    if notifType == "follow" or notifType == "like_photo" or notifType == "like_comment" then
        local query = "SELECT TRUE FROM phone_instagram_notifications WHERE username=@username AND `from`=@from AND `type`=@type"
        if notifType ~= "follow" then
            query = query .. " AND post_id=@post_id"
        end
        local exists = MySQL.Sync.fetchScalar(query, {
            ["@username"] = toUsername,
            ["@from"] = fromUsername,
            ["@type"] = notifType,
            ["@post_id"] = postId,
        })
        if exists then return end
    end

    -- Insert notification record
    MySQL.Async.execute(
        "INSERT INTO phone_instagram_notifications (id, username, `from`, `type`, post_id) VALUES (@id, @username, @from, @type, @postId)",
        {
            ["@id"] = GenerateId("phone_instagram_notifications", "id"),
            ["@username"] = toUsername,
            ["@from"] = fromUsername,
            ["@type"] = notifType,
            ["@postId"] = postId,
        }
    )

    -- Fetch post thumbnail for photo/comment notifications
    local thumbnail = nil
    if notifType == "like_photo" or notifType == "comment" then
        thumbnail = MySQL.Async.fetchScalar(
            "SELECT TRIM(BOTH '\"' FROM JSON_EXTRACT(media, '$[0]')) FROM phone_instagram_posts WHERE id=@id",
            { ["@id"] = postId }
        )
    end

    NotifyLoggedInAccounts("Instagram", toUsername, {
        app = "Instagram",
        title = L("APPS.INSTAGRAM.TITLE"),
        content = content,
        thumbnail = thumbnail,
    })
end

-- =====================================================
-- NOTIFICATIONS CALLBACKS
-- =====================================================

RegisterLegacyCallback("instagram:getNotifications", function(playerSource, cb, page)
    local account = GetInstagramAccount(playerSource)
    if not account then
        return cb({
            notifications = {},
            requests = { recent = {}, total = 0 }
        })
    end

    local pageNum = (page or 0) * 15

    local notifications = MySQL.Sync.fetchAll([[
        SELECT
            (
                SELECT CASE WHEN f.followed IS NULL THEN FALSE ELSE TRUE END
                    FROM phone_instagram_follows f
                    WHERE f.follower=@username AND f.followed=n.`from`
            ) AS isFollowing,
            n.`from` AS username,
            n.`type`,
            n.`timestamp`,
            TRIM(BOTH '"' FROM JSON_EXTRACT(p.media, '$[0]')) AS photo,
            p.id AS postId,
            c.`comment`,
            c.id AS commentId,
            a.profile_image AS avatar,
            a.verified

        FROM phone_instagram_notifications n

        LEFT JOIN phone_instagram_comments c
            ON n.post_id = c.id

        LEFT JOIN phone_instagram_posts p
            ON p.id = (CASE
                WHEN n.`type`="like_photo"
                THEN n.post_id

                WHEN n.`type`="comment"
                THEN c.post_id

                WHEN n.`type`="like_comment"
                THEN c.post_id

                ELSE NULL
                END
            )

        LEFT JOIN phone_instagram_accounts a
            ON a.username=n.`from`

        WHERE n.username=@username

        ORDER BY n.`timestamp` DESC

        LIMIT @page, @perPage
    ]], {
        ["@username"] = account,
        ["@page"] = pageNum,
        ["@perPage"] = 15,
    })

    if (page or 0) > 0 then
        return cb({ notifications = notifications })
    end

    local recentRequests = MySQL.Sync.fetchAll([[
        SELECT a.username, a.profile_image AS avatar

        FROM phone_instagram_follow_requests r

        INNER JOIN phone_instagram_accounts a
            ON a.username = r.requester

        WHERE r.requestee=@username

        ORDER BY r.`timestamp` DESC

        LIMIT 2
    ]], { ["@username"] = account })

    local totalRequests = MySQL.Sync.fetchScalar(
        "SELECT COUNT(1) FROM phone_instagram_follow_requests WHERE requestee=@username",
        { ["@username"] = account }
    )

    cb({
        notifications = notifications,
        requests = { recent = recentRequests, total = totalRequests }
    })
end)

RegisterLegacyCallback("instagram:getFollowRequests", function(playerSource, cb, page)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    local pageNum = (page or 0) * 15

    MySQL.Async.fetchAll([[
        SELECT a.username, a.display_name AS `name`, a.profile_image AS avatar, a.verified
        FROM phone_instagram_follow_requests r

        INNER JOIN phone_instagram_accounts a
            ON a.username = r.requester

        WHERE r.requestee=@loggedInAs

        ORDER BY r.`timestamp` DESC

        LIMIT @page, @perPage
    ]], {
        ["@loggedInAs"] = account,
        ["@page"] = pageNum,
        ["@perPage"] = 15,
    }, cb)
end)

RegisterLegacyCallback("instagram:handleFollowRequest", function(playerSource, cb, requesterUsername, accept)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    local params = { ["@loggedInAs"] = account, ["@username"] = requesterUsername }

    local deleted = MySQL.Sync.execute(
        "DELETE FROM phone_instagram_follow_requests WHERE requestee=@loggedInAs AND requester=@username",
        params
    )
    if deleted == 0 then return cb(false) end

    if not accept then return cb(true) end

    MySQL.Sync.execute(
        "INSERT IGNORE INTO phone_instagram_follows (follower, followed) VALUES (@username, @loggedInAs)",
        params
    )

    TriggerClientEvent("phone:instagram:updateProfileData", -1, account, "followers", true)
    TriggerClientEvent("phone:instagram:updateProfileData", -1, requesterUsername, "following", true)

    local displayName = MySQL.Sync.fetchScalar(
        "SELECT display_name FROM phone_instagram_accounts WHERE username=@loggedInAs",
        params
    )

    NotifyLoggedInAccounts("Instagram", requesterUsername, {
        app = "Instagram",
        title = L("BACKEND.INSTAGRAM.FOLLOW_REQUEST_ACCEPTED_TITLE"),
        content = L("BACKEND.INSTAGRAM.FOLLOW_REQUEST_ACCEPTED_DESCRIPTION", {
            displayName = displayName,
            username = account,
        })
    })

    cb(true)
end)

-- =====================================================
-- SEARCH
-- =====================================================

RegisterLegacyCallback("instagram:search", function(playerSource, cb, query, page)
    local pageNum = (page or 0) * 25

    MySQL.Async.fetchAll([[
        SELECT
            username,
            display_name AS name,
            profile_image AS avatar,
            verified,
            private

        FROM
            phone_instagram_accounts

        WHERE
            username LIKE CONCAT(@search, "%")
            OR
            display_name LIKE CONCAT("%", @search, "%")

        ORDER BY username ASC

        LIMIT @page, @perPage
    ]], {
        ["@search"] = query,
        ["@page"] = pageNum,
        ["@perPage"] = 25,
    }, cb)
end)

-- =====================================================
-- ACCOUNT MANAGEMENT
-- =====================================================

RegisterLegacyCallback("instagram:createAccount", function(playerSource, cb, displayName, username, password)
    username = username:lower()

    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then
        return cb({ success = false, error = "UNKNOWN" })
    end

    if not IsUsernameValid(username) then
        return cb({ success = false, error = "USERNAME_NOT_ALLOWED" })
    end

    debugprint("INSTAGRAM", ("%s wants to create an account"):format(phoneNumber))

    local existingUser = MySQL.Sync.fetchScalar(
        "SELECT username FROM phone_instagram_accounts WHERE username=@username",
        { ["@username"] = username }
    )
    if existingUser then
        debugprint("INSTAGRAM", ("%s tried to create an account with an existing username"):format(phoneNumber))
        return cb({ success = false, error = "USERNAME_TAKEN" })
    end

    MySQL.Sync.execute(
        "INSERT INTO phone_instagram_accounts (display_name, username, password, phone_number) VALUES (@displayName, @username, @password, @phonenumber)",
        {
            ["@displayName"] = displayName,
            ["@username"] = username,
            ["@password"] = GetPasswordHash(password),
            ["@phonenumber"] = phoneNumber,
        }
    )

    debugprint("INSTAGRAM", ("%s created an account"):format(phoneNumber))
    AddLoggedInAccount(phoneNumber, "Instagram", username)
    cb({ success = true })

    -- Auto-follow accounts if configured
    if Config.AutoFollow and Config.AutoFollow.Enabled then
        local instaPicAutoFollow = Config.AutoFollow.InstaPic
        if instaPicAutoFollow and instaPicAutoFollow.Enabled then
            for _, autoFollowUsername in ipairs(instaPicAutoFollow.Accounts) do
                MySQL.update.await(
                    "INSERT INTO phone_instagram_follows (followed, follower) VALUES (?, ?)",
                    { autoFollowUsername, username }
                )
            end
        end
    end
end, { preventSpam = true, rateLimit = 4 })

BaseCallback("instagram:changePassword", function(playerSource, cb, account, currentPassword, newPassword)
    if not Config.ChangePassword or not Config.ChangePassword.InstaPic then
        infoprint("warning", ("%s tried to change password on InstaPic, but it's not enabled in the config."):format(playerSource))
        return false
    end

    if currentPassword == newPassword or #newPassword < 3 then
        debugprint("same password / too short")
        return false
    end

    if activeLives[account] then
        debugprint("Can't change password when live")
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_instagram_accounts WHERE username = ?",
        { account }
    )
    if not storedHash or not VerifyPasswordHash(currentPassword, storedHash) then
        return false
    end

    local updated = MySQL.update.await(
        "UPDATE phone_instagram_accounts SET password = ? WHERE username = ?",
        { GetPasswordHash(newPassword), account }
    )
    if not (updated > 0) then return false end

    local phoneNumber = cb  -- phoneNumber is passed as second argument (cb) in BaseCallback

    NotifyLoggedInAccounts("Instagram", account, {
        title = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
        content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    })

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram' AND phone_number != ?",
        { account, phoneNumber }
    )

    ClearActiveAccountsCache("Instagram", account, phoneNumber)

    Log("InstaPic", playerSource, "info",
        L("BACKEND.LOGS.CHANGED_PASSWORD.TITLE"),
        L("BACKEND.LOGS.CHANGED_PASSWORD.DESCRIPTION", { number = phoneNumber, username = account, app = "InstaPic" })
    )

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = account,
        app = "instagram",
        reason = "password",
        number = phoneNumber,
    })

    return true
end, false)

-- Internal: delete an Instagram account by username
local function DeleteInstaPicAccount(username)
    assert(type(username) == "string", "Expected string for argument 1 (username), got " .. type(username))

    local deleted = MySQL.update.await(
        "DELETE FROM phone_instagram_accounts WHERE username = ?",
        { username }
    )
    if not (deleted > 0) then return false end

    NotifyLoggedInAccounts("Instagram", username, {
        title = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
        content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"),
    })

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram'",
        { username }
    )

    ClearActiveAccountsCache("Instagram", username)

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = username,
        app = "instagram",
        reason = "deleted",
    })
end

BaseCallback("instagram:deleteAccount", function(playerSource, cb, account, password)
    if not Config.DeleteAccount or not Config.DeleteAccount.InstaPic then
        infoprint("warning", ("%s tried to delete their account on InstaPic, but it's not enabled in the config."):format(playerSource))
        return false
    end

    if activeLives[account] then
        debugprint("Can't delete account when live")
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_instagram_accounts WHERE username = ?",
        { account }
    )
    if not storedHash or not VerifyPasswordHash(password, storedHash) then
        return false
    end

    local phoneNumber = cb  -- passed as second arg in BaseCallback

    local success = DeleteInstaPicAccount(account)
    if success then
        Log("InstaPic", playerSource, "info",
            L("BACKEND.LOGS.DELETED_ACCOUNT.TITLE"),
            L("BACKEND.LOGS.DELETED_ACCOUNT.DESCRIPTION", { number = phoneNumber, username = account, app = "InstaPic" })
        )
    end

    return success
end, false)

exports("DeleteInstaPicAccount", DeleteInstaPicAccount)

-- =====================================================
-- AUTH
-- =====================================================

RegisterLegacyCallback("instagram:logIn", function(playerSource, cb, username, password)
    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then
        return cb({ success = false, error = "UNKNOWN" })
    end

    debugprint("INSTAGRAM", ("%s wants to log in on account %s"):format(phoneNumber, username))
    debugprint("INSTAGRAM", ("%s is not logged in, checking if account exists"):format(phoneNumber))

    username = username:lower()

    MySQL.Async.fetchScalar(
        "SELECT password FROM phone_instagram_accounts WHERE username=@username",
        { ["@username"] = username },
        function(storedHash)
            if not storedHash then
                debugprint("INSTAGRAM", ("%s tried to log in on non-existing account %s"):format(phoneNumber, username))
                return cb({ success = false, error = "UNKNOWN_ACCOUNT" })
            end

            if not VerifyPasswordHash(password, storedHash) then
                debugprint("INSTAGRAM", ("%s tried to log in on account %s with wrong password"):format(phoneNumber, username))
                return cb({ success = false, error = "INCORRECT_PASSWORD" })
            end

            debugprint("INSTAGRAM", ("%s logged in on account %s"):format(phoneNumber, username))
            AddLoggedInAccount(phoneNumber, "Instagram", username)

            MySQL.Async.fetchAll([[
                SELECT
                    display_name AS name, username, profile_image AS avatar, verified
                FROM phone_instagram_accounts

                WHERE username = @username
            ]], { ["@username"] = username }, function(rows)
                debugprint("INSTAGRAM", ("%s got account data"):format(phoneNumber))
                cb({
                    success = true,
                    account = rows and rows[1] or nil,
                })
            end)
        end
    )
end)

RegisterLegacyCallback("instagram:isLoggedIn", function(playerSource, cb)
    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then return cb(false) end

    local account = GetLoggedInAccount(phoneNumber, "Instagram")
    if not account then return cb(false) end

    local profileData = MySQL.single.await([[
        SELECT display_name AS `name`, username, profile_image AS avatar, verified
        FROM phone_instagram_accounts
        WHERE username = ?
    ]], { account })

    cb(profileData or false)
end)

RegisterLegacyCallback("instagram:signOut", function(playerSource, cb)
    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then return cb(false) end

    local account = GetLoggedInAccount(phoneNumber, "Instagram")
    if not account then return cb(false) end

    RemoveLoggedInAccount(phoneNumber, "Instagram", account)
    cb(true)
end)

-- =====================================================
-- PROFILES
-- =====================================================

RegisterLegacyCallback("instagram:getProfile", function(playerSource, cb, targetUsername)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    MySQL.Async.fetchAll([[
        SELECT display_name AS name, username, profile_image AS avatar, bio, verified, private, follower_count as followers, following_count as following, post_count as posts,
            (
                IF((SELECT TRUE FROM phone_instagram_follows f WHERE f.followed=@username AND f.follower=@loggedInAs), TRUE, FALSE)
            ) AS isFollowing,
            (
                IF((SELECT TRUE FROM phone_instagram_follow_requests fr WHERE fr.requester=@loggedInAs AND fr.requestee=@username), TRUE, FALSE)
            ) AS requested,

            (SELECT COUNT(*) > 0 FROM phone_instagram_stories s
                WHERE s.username=@username
                AND s.timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
            ) AS hasStory,
            (SELECT COUNT(*) FROM phone_instagram_stories s
                WHERE s.username=@username
                AND s.timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
            ) = (
                SELECT COUNT(*) FROM phone_instagram_stories_views v
                WHERE v.viewer=@loggedInAs
                AND v.story_id IN (
                    SELECT id FROM phone_instagram_stories
                    WHERE username=@username
                    AND timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
                )
            ) AS seenStory

        FROM phone_instagram_accounts a

        WHERE a.username=@username
    ]], {
        ["@username"] = targetUsername,
        ["@loggedInAs"] = account,
    }, function(rows)
        local profile = rows and rows[1]
        if profile then
            profile.isLive = activeLives[targetUsername] ~= nil
        end
        cb(profile or false)
    end)
end)

-- =====================================================
-- POSTS
-- =====================================================

RegisterLegacyCallback("instagram:createPost", function(playerSource, cb, mediaUrls, caption, location)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    if ContainsBlacklistedWord(playerSource, "InstaPic", caption) then return cb(false) end

    if not ValidateChecks("postInstaPic", playerSource, account, mediaUrls, caption, location) then
        debugprint("instagram:createPost - postInstaPic check failed")
        return cb(false)
    end

    local postId = GenerateId("phone_instagram_posts", "id")
    local encodedMedia = json.encode(mediaUrls)

    MySQL.Sync.execute(
        "INSERT INTO phone_instagram_posts (id, username, media, caption, location) VALUES (@id, @username, @media, @caption, @location)",
        {
            ["@id"] = postId,
            ["@username"] = account,
            ["@media"] = encodedMedia,
            ["@caption"] = caption,
            ["@location"] = location,
        }
    )

    cb(true)

    local postData = {
        username = account,
        media = encodedMedia,
        caption = caption,
        location = location,
        id = postId,
        source = playerSource,
    }

    TriggerClientEvent("phone:instagram:newPost", -1, postData)
    TriggerEvent("lb-phone:instapic:newPost", postData)

    -- Build log message
    local logText = "**Caption**: " .. (caption or "") .. "\n\n**Photos**:\n"
    for i, url in ipairs(mediaUrls) do
        logText = logText .. ("[Photo %s](%s)\n"):format(i, url)
    end
    logText = logText .. "**ID:** " .. postId

    Log("InstaPic", playerSource, "info", "New post", logText)
    TrackSocialMediaPost("instapic", mediaUrls)

    -- Discord webhook
    if Config.Post and Config.Post.InstaPic and INSTAPIC_WEBHOOK then
        if INSTAPIC_WEBHOOK:sub(-14) ~= "/api/webhooks/" then return end

        local avatarUrl = MySQL.scalar.await(
            "SELECT profile_image FROM phone_instagram_accounts WHERE username=?",
            { account }
        )

        local webhookUsername = (Config.Post.Accounts and Config.Post.Accounts.InstaPic and Config.Post.Accounts.InstaPic.Username) or "InstaPic"
        local webhookAvatar = (Config.Post.Accounts and Config.Post.Accounts.InstaPic and Config.Post.Accounts.InstaPic.Avatar)
            or "https://loaf-scripts.com/fivem/lb-phone/icons/InstaPic.png"

        local descriptionText = (caption and #caption > 0) and caption or nil

        PerformHttpRequest(INSTAPIC_WEBHOOK, function() end, "POST", json.encode({
            username = webhookUsername,
            avatar_url = webhookAvatar,
            embeds = {{
                title = L("APPS.INSTAGRAM.NEW_POST"),
                description = descriptionText,
                color = 9059001,
                timestamp = GetTimestampISO(),
                author = {
                    name = "@" .. account,
                    icon_url = avatarUrl or "https://cdn.discordapp.com/embed/avatars/5.png",
                },
                image = { url = mediaUrls[1] },
                footer = {
                    text = "LB Phone",
                    icon_url = "https://docs.lbscripts.com/images/icons/icon.png",
                },
            }}
        }), { ["Content-Type"] = "application/json" })
    end
end, { preventSpam = true, rateLimit = 6 })

RegisterLegacyCallback("instagram:deletePost", function(playerSource, cb, postId)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    local canDelete = IsAdmin(playerSource)
    if not canDelete then
        canDelete = MySQL.Sync.fetchScalar(
            "SELECT TRUE FROM phone_instagram_posts WHERE id=@id AND username=@username",
            { ["@id"] = postId, ["@username"] = account }
        )
    end
    if not canDelete then return cb(false) end

    local params = { ["@id"] = postId }
    MySQL.Sync.execute("DELETE FROM phone_instagram_likes WHERE id=@id", params)
    MySQL.Sync.execute("DELETE FROM phone_instagram_notifications WHERE post_id=@id", params)
    MySQL.Sync.execute("DELETE FROM phone_instagram_comments WHERE post_id=@id", params)
    local deleted = MySQL.Sync.execute("DELETE FROM phone_instagram_posts WHERE id=@id", params)

    if deleted > 0 then
        Log("InstaPic", playerSource, "error", "Deleted post", "**ID**: " .. postId)
    end

    cb(deleted > 0)
end)

RegisterLegacyCallback("instagram:getPost", function(playerSource, cb, postId)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    MySQL.Async.fetchAll([[
        SELECT
            p.id, p.media, p.caption, p.username, p.timestamp, p.like_count, p.comment_count, p.location,

            a.verified, a.profile_image AS avatar,

            (IF((
                SELECT TRUE FROM phone_instagram_likes l
                WHERE l.id=p.id AND l.username=@loggedInAs AND l.is_comment=FALSE
            ), TRUE, FALSE)) AS liked

        FROM phone_instagram_posts p

        INNER JOIN phone_instagram_accounts a
            ON p.username = a.username

        WHERE p.id=@id
    ]], {
        ["@id"] = postId,
        ["@loggedInAs"] = account,
    }, function(rows)
        cb((rows and rows[1]) or false)
    end)
end)

RegisterLegacyCallback("instagram:getPosts", function(playerSource, cb, filters, page)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    filters = filters or {}
    local pageNum = (page or 0) * 15

    local whereClause = ""
    local orderBy = "p.timestamp DESC"

    if filters.following then
        whereClause = [[
            JOIN phone_instagram_follows f

            WHERE f.follower=@loggedInAs
                AND f.followed=p.username
        ]]
    elseif filters.profile then
        whereClause = "WHERE p.username=@username"
    else
        whereClause = [[
            WHERE a.private=FALSE
        ]]
    end

    local query = ([[
        SELECT
            p.id, p.media, p.caption, p.username, p.timestamp, p.like_count, p.comment_count, p.location,

            a.verified, a.profile_image AS avatar,

            (IF((
                SELECT TRUE FROM phone_instagram_likes l
                WHERE l.id=p.id AND l.username=@loggedInAs AND l.is_comment=FALSE
            ), TRUE, FALSE)) AS liked

        FROM phone_instagram_posts p

        INNER JOIN phone_instagram_accounts a
            ON p.username = a.username

        %s

        ORDER BY %s

        LIMIT @page, @perPage
    ]]):format(whereClause, orderBy)

    MySQL.Async.fetchAll(query, {
        ["@page"] = pageNum,
        ["@perPage"] = 15,
        ["@loggedInAs"] = account,
        ["@username"] = filters.username,
    }, cb)
end)

-- =====================================================
-- COMMENTS
-- =====================================================

RegisterLegacyCallback("instagram:getComments", function(playerSource, cb, postId, page)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    local pageNum = (page or 0) * 20

    MySQL.Async.fetchAll([[
        SELECT
            c.id, c.comment, c.`timestamp`, c.like_count,
            a.username, a.profile_image, a.verified,

            (IF((
                SELECT TRUE FROM phone_instagram_likes l
                WHERE l.id=c.id AND l.username=@loggedInAs AND l.is_comment=TRUE
            ), TRUE, FALSE)) AS liked,

            (IF((
                SELECT TRUE FROM phone_instagram_follows f
                WHERE f.follower=@loggedInAs AND f.followed=a.username
            ), TRUE, FALSE)) AS following

        FROM phone_instagram_comments c

        INNER JOIN phone_instagram_accounts a
            ON c.username = a.username

        WHERE c.post_id=@postId

        ORDER BY following DESC, c.like_count DESC, c.`timestamp` DESC

        LIMIT @page, @perPage
    ]], {
        ["@page"] = pageNum,
        ["@perPage"] = 20,
        ["@postId"] = postId,
        ["@loggedInAs"] = account,
    }, cb)
end)

RegisterLegacyCallback("instagram:postComment", function(playerSource, cb, postId, commentText)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    if ContainsBlacklistedWord(playerSource, "InstaPic", commentText) then return cb(false) end

    local commentId = GenerateId("phone_instagram_comments", "id")

    MySQL.Async.execute(
        "INSERT INTO phone_instagram_comments (id, post_id, username, comment) VALUES (@id, @postId, @username, @comment)",
        {
            ["@id"] = commentId,
            ["@postId"] = postId,
            ["@username"] = account,
            ["@comment"] = commentText,
        },
        function()
            -- Notify post author
            MySQL.Async.fetchScalar(
                "SELECT username FROM phone_instagram_posts WHERE id=@id",
                { ["@id"] = postId },
                function(postAuthor)
                    SendInstagramNotification(postAuthor, account, "comment", commentId)
                end
            )

            TriggerClientEvent("phone:instagram:updatePostData", -1, postId, "comment_count", true)
            cb(commentId)
        end
    )
end, { preventSpam = true, rateLimit = 10 })

-- =====================================================
-- PROFILE UPDATES
-- =====================================================

RegisterLegacyCallback("instagram:updateProfile", function(playerSource, cb, updates)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    local name    = updates.name
    local bio     = updates.bio
    local avatar  = updates.avatar
    local private = updates.private

    local setClauses = ""
    if name    then setClauses = setClauses .. "display_name=@displayName," end
    if bio     then setClauses = setClauses .. "bio=@bio," end
    if avatar  then setClauses = setClauses .. "profile_image=@avatar," end
    if type(private) == "boolean" then setClauses = setClauses .. "private=@private," end

    -- Remove trailing comma
    setClauses = setClauses:sub(1, -2)

    MySQL.Async.execute(
        "UPDATE phone_instagram_accounts SET " .. setClauses .. " WHERE username=@username",
        {
            ["@displayName"] = name,
            ["@bio"] = bio,
            ["@avatar"] = avatar,
            ["@username"] = account,
            ["@private"] = private,
        },
        function()
            cb(true)
        end
    )
end)

-- =====================================================
-- FOLLOW SYSTEM
-- =====================================================

RegisterLegacyCallback("instagram:toggleFollow", function(playerSource, cb, targetUsername, follow)
    local account = GetInstagramAccount(playerSource)
    if not account or targetUsername == account then
        return cb(not follow)
    end

    local params = {
        ["@username"] = targetUsername,
        ["@loggedInAs"] = account,
    }

    local function OnFollowChanged(rowsAffected)
        if rowsAffected == 0 then
            return cb(follow)
        end

        TriggerClientEvent("phone:instagram:updateProfileData", -1, targetUsername, "followers", follow)
        TriggerClientEvent("phone:instagram:updateProfileData", -1, account, "following", follow)
        cb(follow)

        if follow then
            SendInstagramNotification(targetUsername, account, "follow")
        end
    end

    local isPrivate = MySQL.Sync.fetchScalar(
        "SELECT private FROM phone_instagram_accounts WHERE username=@username",
        params
    )

    if isPrivate then
        if follow then
            -- Send follow request
            MySQL.Async.execute(
                "INSERT IGNORE INTO phone_instagram_follow_requests (requester, requestee) VALUES (@loggedInAs, @username)",
                params,
                function()
                    cb(follow)
                end
            )

            local displayName = MySQL.Sync.fetchScalar(
                "SELECT display_name FROM phone_instagram_accounts WHERE username=@loggedInAs",
                params
            )

            NotifyLoggedInAccounts("Instagram", targetUsername, {
                title = L("BACKEND.INSTAGRAM.NEW_FOLLOW_REQUEST_TITLE"),
                content = L("BACKEND.INSTAGRAM.NEW_FOLLOW_REQUEST_DESCRIPTION", {
                    displayName = displayName,
                    username = account,
                })
            })
        else
            MySQL.Async.execute(
                "DELETE FROM phone_instagram_follow_requests WHERE requester=@loggedInAs AND requestee=@username",
                params
            )
        end
        return
    end

    local query = follow
        and "INSERT IGNORE INTO phone_instagram_follows (followed, follower) VALUES (@username, @loggedInAs)"
        or  "DELETE FROM phone_instagram_follows WHERE followed=@username AND follower=@loggedInAs"

    MySQL.Async.execute(query, params, OnFollowChanged)
end, { preventSpam = true })

-- =====================================================
-- LIKES
-- =====================================================

RegisterLegacyCallback("instagram:toggleLike", function(playerSource, cb, postId, liked, isComment)
    if not postId then return cb(false) end

    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    local function OnLikeChanged(rowsAffected)
        if rowsAffected == 0 then
            return cb(liked)
        end

        cb(liked)

        if isComment then
            TriggerClientEvent("phone:instagram:updateCommentLikes", -1, postId, liked)
        else
            TriggerClientEvent("phone:instagram:updatePostData", -1, postId, "like_count", liked)
        end

        if liked then
            local table = isComment and "phone_instagram_comments" or "phone_instagram_posts"
            MySQL.Async.fetchScalar(
                "SELECT username FROM " .. table .. " WHERE id=@postId",
                { ["@postId"] = postId },
                function(postAuthor)
                    if postAuthor then
                        local notifType = "like_" .. (isComment and "comment" or "photo")
                        SendInstagramNotification(postAuthor, account, notifType, postId)
                    end
                end
            )
        end
    end

    local query = liked
        and "INSERT IGNORE INTO phone_instagram_likes (id, username, is_comment) VALUES (@postId, @loggedInAs, @isComment)"
        or  "DELETE FROM phone_instagram_likes WHERE id=@postId AND username=@loggedInAs AND is_comment=@isComment"

    MySQL.Async.execute(query, {
        ["@postId"] = postId,
        ["@loggedInAs"] = account,
        ["@isComment"] = isComment,
    }, OnLikeChanged)
end, { preventSpam = true })

-- =====================================================
-- FOLLOWERS / FOLLOWING / LIKES DATA
-- =====================================================

RegisterLegacyCallback("instagram:getData", function(playerSource, cb, dataType, queryParams)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    local tableName, joinColumn, whereClause, orderColumn = "", "", "", ""

    if dataType == "likes" then
        tableName    = "phone_instagram_likes"
        joinColumn   = "username"
        whereClause  = "id=@postId AND is_comment=@isComment"
        orderColumn  = "a.username"
    elseif dataType == "followers" then
        tableName    = "phone_instagram_follows"
        joinColumn   = "follower"
        whereClause  = "q.followed=@username"
        orderColumn  = "q.follower"
    elseif dataType == "following" then
        tableName    = "phone_instagram_follows"
        joinColumn   = "followed"
        whereClause  = "q.follower=@username"
        orderColumn  = "q.followed"
    end

    local query = ([[
        SELECT
            a.username, a.display_name AS name, a.profile_image AS avatar, a.verified,

            (IF((
                SELECT TRUE FROM phone_instagram_follows f
                WHERE f.followed=a.username AND f.follower=@loggedInAs
            ), TRUE, FALSE)) AS isFollowing

        FROM phone_instagram_accounts a

        INNER JOIN %s q ON q.%s=a.username

        WHERE %s

        ORDER BY %s DESC

        LIMIT @page, @perPage
    ]]):format(tableName, joinColumn, whereClause, orderColumn)

    local pageNum = (queryParams.page or 0) * 20

    MySQL.Async.fetchAll(query, {
        ["@username"]   = queryParams.username,
        ["@postId"]     = queryParams.postId,
        ["@isComment"]  = queryParams.isComment == true,
        ["@loggedInAs"] = account,
        ["@page"]       = pageNum,
        ["@perPage"]    = 20,
    }, cb)
end)

-- =====================================================
-- DIRECT MESSAGES
-- =====================================================

RegisterLegacyCallback("instagram:getRecentMessages", function(playerSource, cb, page)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    local pageNum = (page or 0) * 15

    MySQL.Async.fetchAll([[
        SELECT
            m.content, m.attachments, m.sender, f_m.username, m.`timestamp`,

            a.display_name AS `name`, a.profile_image AS avatar, a.verified

        FROM phone_instagram_messages m

        JOIN ((
            SELECT (
                CASE WHEN recipient!=@loggedInAs THEN recipient ELSE sender END
            ) AS username, MAX(`timestamp`) AS `timestamp`

            FROM phone_instagram_messages

            WHERE sender=@loggedInAs OR recipient=@loggedInAs

            GROUP BY username
        ) f_m)
        ON m.`timestamp`=f_m.`timestamp`

        INNER JOIN phone_instagram_accounts a
            ON a.username=f_m.username

        WHERE m.sender=@loggedInAs OR m.recipient=@loggedInAs

        GROUP BY f_m.username

        ORDER BY m.`timestamp` DESC

        LIMIT @page, @perPage
    ]], {
        ["@loggedInAs"] = account,
        ["@page"] = pageNum,
        ["@perPage"] = 15,
    }, cb)
end)

RegisterLegacyCallback("instagram:getMessages", function(playerSource, cb, recipientUsername, page)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb({}) end

    local pageNum = (page or 0) * 25

    MySQL.Async.fetchAll([[
        SELECT
            sender, recipient, content, attachments, `timestamp`

        FROM phone_instagram_messages

        WHERE (sender=@loggedInAs AND recipient=@username) OR (sender=@username AND recipient=@loggedInAs)

        ORDER BY `timestamp` DESC

        LIMIT @page, @perPage
    ]], {
        ["@loggedInAs"] = account,
        ["@username"] = recipientUsername,
        ["@page"] = pageNum,
        ["@perPage"] = 25,
    }, cb)
end)

RegisterLegacyCallback("instagram:sendMessage", function(playerSource, cb, recipientUsername, messageData)
    local account = GetInstagramAccount(playerSource)
    if not account then return cb(false) end

    if ContainsBlacklistedWord(playerSource, "InstaPic", messageData.content) then return cb(false) end

    local encodedAttachments = nil
    if messageData.attachments then
        encodedAttachments = json.encode(messageData.attachments) or nil
    end

    local messageId = GenerateId("phone_instagram_messages", "id")

    local rowsAffected = MySQL.update.await(
        "INSERT INTO phone_instagram_messages (id, sender, recipient, content, attachments) VALUES (?, ?, ?, ?, ?)",
        { messageId, account, recipientUsername, messageData.content, encodedAttachments }
    )

    if rowsAffected == 0 then return cb(false) end

    cb(true)

    -- Notify recipient's active sessions
    local activePhones = MySQL.query.await(
        "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram' AND `active` = 1",
        { recipientUsername }
    )
    if not activePhones or #activePhones == 0 then return end

    local senderProfile = MySQL.single.await(
        "SELECT display_name, username, profile_image FROM phone_instagram_accounts WHERE username = ?",
        { account }
    )
    if not senderProfile then return end

    local isStoryReply = string.find(messageData.content, "<!REPLIED_STORY-DATA=", nil, true)
    local notifContent = isStoryReply and L("APPS.INSTAGRAM.REPLIED_TO_YOUR_STORY") or messageData.content

    for _, row in ipairs(activePhones) do
        local recipientSource = GetSourceFromNumber(row.phone_number)
        if recipientSource then
            TriggerClientEvent("phone:instagram:newMessage", recipientSource, {
                sender = account,
                recipient = recipientUsername,
                content = messageData.content,
                attachments = messageData.attachments,
                timestamp = os.time() * 1000,
            })
        end

        SendNotification(row.phone_number, {
            app = "Instagram",
            title = senderProfile.display_name,
            content = notifContent,
            thumbnail = messageData.attachments and messageData.attachments[1],
            avatar = senderProfile.profile_image,
            showAvatar = true,
        })
    end
end, { preventSpam = true, rateLimit = 15 })