if not Config.Voice.HearNearby then return end

-- Map of liveStreamId → true for live streams the local player is currently near
local nearbyLives = {}

-- List of player sources currently in proximity for active phone calls
local nearbyCallSources = {}

-- Map of serverId → { stateBagKey = truthy } tracking remote players' relevant state
local trackedPlayerState = {}

-- ─── enterLiveProximity ────────────────────────────────────────────────────────
-- Marks the local player as near a live stream and notifies the server.
local function enterLiveProximity(liveId)
    if not nearbyLives[liveId] then return end
    nearbyLives[liveId] = true
    debugprint("entered live", liveId)
    TriggerServerEvent("phone:instagram:enteredLiveProximity", liveId)
end

-- ─── leaveLiveProximity ────────────────────────────────────────────────────────
-- Marks the local player as no longer near a live stream and notifies the server.
local function leaveLiveProximity(liveId)
    if not nearbyLives[liveId] then return end
    nearbyLives[liveId] = nil
    debugprint("left live 1", liveId)
    TriggerServerEvent("phone:instagram:leftLiveProximity", liveId)
end

-- ─── phone:instagram:endLive ───────────────────────────────────────────────────
-- Server tells us a live stream has ended.
-- If endedByHost is falsy, simply clean up tracking; otherwise notify the server
-- that proximity has been left (with a flag indicating the stream ended).
RegisterNetEvent("phone:instagram:endLive")
AddEventHandler("phone:instagram:endLive", function(liveId, endedByHost)
    if not endedByHost then
        nearbyLives[liveId] = nil
        return debugprint("left live 2", liveId)
    end

    if nearbyLives[liveId] then
        nearbyLives[liveId] = nil
        TriggerServerEvent("phone:instagram:leftLiveProximity", endedByHost, true)
    end
end)

-- ─── leaveCallProximity ────────────────────────────────────────────────────────
-- Removes a player source from the nearby call list and notifies the server.
-- Resets spatial audio for that source if SpatialAudio is enabled.
local function leaveCallProximity(playerSource)
    if not playerSource then return end

    local found, idx = table.contains(nearbyCallSources, playerSource)
    if not found then return end

    debugprint("left proximity of", playerSource)
    TriggerServerEvent("phone:phone:leftCallProximity", playerSource)

    if Config.Voice.SpatialAudio then
        ResetSpatialAudioSubmixForSource(playerSource)
    end

    table.remove(nearbyCallSources, idx)
    return true
end

-- ─── enterCallProximity ────────────────────────────────────────────────────────
-- Adds a player source to the nearby call list and notifies the server.
-- Sets up spatial audio for that source if SpatialAudio is enabled.
-- Returns early (no-op) if the source is already tracked OR if playerSource is nil.
local function enterCallProximity(playerSource)
    if not playerSource then return end

    -- Already tracked — nothing to do
    if table.contains(nearbyCallSources, playerSource) then return end

    debugprint("entered proximity of", playerSource)
    TriggerServerEvent("phone:phone:enteredCallProximity", playerSource)

    if Config.Voice.SpatialAudio then
        SetSpatialAudioSubmixForSource(playerSource)
    end

    nearbyCallSources[#nearbyCallSources + 1] = playerSource
    return true
end

-- ─── Proximity scan interval ───────────────────────────────────────────────────
-- Runs every 250ms while active. Checks every nearby player and:
--   • If they are live on Instagram and within 10 units → enterLiveProximity
--   • If they are on a speakerphone call (answered) and within 10 units → enterCallProximity
--   • If they are on any call and within 10 units → leaveCallProximity (ensure correct state)
--   • Outside 10 units: leave live / leave call accordingly
-- Also sweeps nearbyCallSources for players who are no longer on a call.
local proximityInterval = Interval.new(Interval, function()
    local nearbyPlayers = GetNearbyPlayers()
    local myCoords      = GetEntityCoords(PlayerPedId())

    for _, playerData in ipairs(nearbyPlayers) do
        local state       = Player(playerData.source).state
        local onCallWith  = state.onCallWith
        local isSpeaker   = onCallWith and state.speakerphone
        local callAnswered = isSpeaker and state.callAnswered
        local isLive      = state.instapicIsLive

        local dist = #(myCoords - GetEntityCoords(playerData.ped))

        if dist <= 10 then
            if isLive then
                enterLiveProximity(isLive)
            elseif callAnswered then
                enterCallProximity(playerData.source)
            elseif onCallWith then
                leaveCallProximity(playerData.source)
            end
        else
            if isLive then
                leaveLiveProximity(isLive)
            elseif onCallWith then
                leaveCallProximity(playerData.source)
            end
        end
    end

    -- Clean up any tracked sources whose call has since ended
    for _, trackedSource in ipairs(nearbyCallSources) do
        if not Player(trackedSource).state.onCallWith then
            leaveCallProximity(trackedSource)
        end
    end
end, 250, false)

proximityInterval.onStart = function()
    debugprint("Hear nearby interval started")
end

proximityInterval.onStop = function()
    debugprint("Hear nearby interval stopped")

    -- Notify the server that we've left proximity of every tracked call source
    for _, trackedSource in ipairs(nearbyCallSources) do
        debugprint("left proximity of", trackedSource)
        TriggerServerEvent("phone:phone:leftCallProximity", trackedSource)
        if Config.Voice.SpatialAudio then
            ResetSpatialAudioSubmixForSource(trackedSource)
        end
    end
    table.wipe(nearbyCallSources)

    -- Also leave proximity of any live streams we were tracking
    for liveId in pairs(nearbyLives) do
        leaveLiveProximity(liveId)
    end
end

-- ─── State bag watchers ────────────────────────────────────────────────────────
-- Watch these four state bag keys on all players. When any of them becomes truthy
-- on a remote player, add that player to trackedPlayerState and start the interval.
-- When all tracked entries are cleared, stop the interval.
local WATCHED_STATE_KEYS = { "onCallWith", "speakerphone", "callAnswered", "instapicIsLive" }

for _, stateKey in ipairs(WATCHED_STATE_KEYS) do
    AddStateBagChangeHandler(stateKey, nil, function(bagName, key, value)
        local serverId = GetPlayerDataFromStateBag(bagName)

        -- Only track other players, not ourselves
        if not serverId then return end
        if serverId == GetPlayerServerId(PlayerId()) then return end

        -- Yield one frame so the state bag value is fully committed
        Wait(0)

        if value then
            if not trackedPlayerState[serverId] then
                trackedPlayerState[serverId] = {}
            end
            trackedPlayerState[serverId][key] = not not value
            proximityInterval:toggle(true)
        else
            if trackedPlayerState[serverId] then
                trackedPlayerState[serverId][key] = nil
                -- Remove the player entry entirely if no tracked keys remain
                if next(trackedPlayerState[serverId]) == nil then
                    trackedPlayerState[serverId] = nil
                end
            end
        end

        -- Stop the interval when no remote players have any relevant state active
        if not next(trackedPlayerState) then
            proximityInterval:toggle(false)
        end
    end)
end

-- ─── onPlayerDropped ───────────────────────────────────────────────────────────
-- Clean up tracked state for a player who disconnected.
RegisterNetEvent("onPlayerDropped")
AddEventHandler("onPlayerDropped", function(droppedServerId)
    trackedPlayerState[droppedServerId] = nil
    if not next(trackedPlayerState) then
        proximityInterval:toggle(false)
    end
end)