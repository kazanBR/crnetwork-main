local nearbyListeners = {}

-- NUI callback: send voice config (RecordNearby flag + RTC config) to the UI
RegisterNUICallback("voice:getConfig", function(_, cb)
    cb({
        recordNearbyVoices = Config.Voice.RecordNearby,
        rtc               = Config.RTCConfig,
    })
end)

-- Feature is disabled in config — nothing more to do
if not Config.Voice.RecordNearby then
    return
end

-- ── Volume update interval (50 ms) ──────────────────────────────────────────
-- For each tracked listener, recalculate distance-based volume and push it to
-- the UI if it has changed.
local volumeInterval = Interval.new(Interval, function()
    local myCoords = GetEntityCoords(PlayerPedId())

    for i = 1, #nearbyListeners do
        local listener    = nearbyListeners[i]
        local dist        = #(myCoords - GetEntityCoords(listener.ped))
        local newVolume   = GetVoiceVolume(dist)

        if newVolume ~= listener.volume then
            listener.volume = newVolume
            SendReactMessage("voice:setVolume", {
                channel = listener.channel,
                volume  = newVolume,
            })
        end
    end
end, 50, false)

-- ── Nearby-player scan interval (1000 ms) ────────────────────────────────────
-- Rebuilds the listener list every second. If a nearby player is already
-- tracked, their cached volume is preserved; otherwise they join a new channel.
Interval.new(Interval, function()
    local newListeners  = {}
    local nearbyPlayers = GetNearbyPlayers()
    local myCoords      = GetEntityCoords(PlayerPedId())

    for i = 1, #nearbyPlayers do
        local playerData  = nearbyPlayers[i]
        local playerState = Player(playerData.source).state
        local peerId      = playerState and playerState.listeningPeerId

        -- Skip players who are not on a listening peer channel
        if peerId then
            local dist = #(myCoords - GetEntityCoords(playerData.ped))

            -- Only track players within 25 metres
            if dist <= 25.0 then
                local newIndex = #newListeners + 1
                newListeners[newIndex] = {
                    source  = playerData.source,
                    ped     = playerData.ped,
                    channel = peerId,
                }

                -- Check if this player was already in the previous listener list
                local alreadyTracked = false
                for j = 1, #nearbyListeners do
                    local existing = nearbyListeners[j]
                    if existing.source == playerData.source then
                        -- Preserve the previously calculated volume
                        newListeners[newIndex].volume = existing.volume
                        alreadyTracked = true
                        break
                    end
                end

                -- New listener — calculate initial volume and tell the UI to join
                if not alreadyTracked then
                    local volume = GetVoiceVolume(dist)
                    newListeners[newIndex].volume = volume
                    SendReactMessage("voice:joinChannel", {
                        channel = peerId,
                        volume  = volume,
                    })
                end
            end
        end
    end

    nearbyListeners = newListeners

    -- Enable/disable the volume-update interval based on whether anyone is nearby
    volumeInterval.toggle(volumeInterval, #nearbyListeners > 0)
end, 1000)

-- ── Net event: another player started listening ──────────────────────────────
-- Fired by the server when a player begins recording nearby voices.
RegisterNetEvent("phone:startedListening")
AddEventHandler("phone:startedListening", function(sourceServerId, channel)
    local playerLocal = GetPlayerFromServerId(sourceServerId)

    -- Ignore invalid players, ourselves, and players not resolvable locally
    if not playerLocal or playerLocal == PlayerId() or playerLocal == -1 then
        return
    end

    local myPed        = PlayerPedId()
    local theirPed     = GetPlayerPed(playerLocal)
    local myCoords     = GetEntityCoords(myPed)
    local theirCoords  = GetEntityCoords(theirPed)
    local dist         = #(myCoords - theirCoords)

    -- Ignore if the ped doesn't exist, is our own ped, or is too far away
    if not DoesEntityExist(theirPed) or theirPed == myPed or dist > 25.0 then
        return
    end

    -- Ignore if this source is already in the listener list
    for i = 1, #nearbyListeners do
        if nearbyListeners[i].source == sourceServerId then
            return
        end
    end

    -- Add to listeners and tell the UI to join the channel
    local volume = GetVoiceVolume(dist)
    nearbyListeners[#nearbyListeners + 1] = {
        source  = sourceServerId,
        ped     = theirPed,
        channel = channel,
        volume  = volume,
    }

    SendReactMessage("voice:joinChannel", {
        channel = channel,
        volume  = volume,
    })
end)

-- ── Net event: a player stopped listening ───────────────────────────────────
RegisterNetEvent("phone:stoppedListening")
AddEventHandler("phone:stoppedListening", function(sourceServerId)
    SendReactMessage("voice:leaveChannel", sourceServerId)
end)

-- ── NUI callback: UI sets its own listening peer ID ─────────────────────────
RegisterNUICallback("setListeningPeerId", function(data, cb)
    TriggerServerEvent("phone:setListeningPeerId", data)
    cb("ok")
end)
