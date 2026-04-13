-- Tracks active sound IDs: persistent sounds (ringtone/alarm) and per-source sounds
local activeSoundIds = {}   -- [sourceId] = soundId  (nearby players' sounds)
local currentLoopSoundId = nil  -- active ringtone or alarm sound ID
local previewSoundId = nil  -- currently previewing sound in settings UI
local previewSoundKey = nil -- key to detect if a newer preview started

-- ─── Helpers: resolve ringtone / notification names ──────────────────────────

-- Returns (soundName, soundSet, audioBank) for a given ringtone key.
-- Falls back to the first configured ringtone; "vibrate" returns vibrate params.
local function getRingtoneParams(key)
    if key == "vibrate" then
        return "vibrate", "ringtone"
    end

    -- Use the requested ringtone if it exists, otherwise fall back to first entry
    local ringtone
    if key then
        ringtone = Config.Sound.Ringtones[key]
    end
    if not ringtone then
        local firstKey = next(Config.Sound.Ringtones)
        ringtone = Config.Sound.Ringtones[firstKey]
    end

    if ringtone then
        return ringtone.name, ringtone.soundSet, ringtone.audioBank
    end
    return "1", "ringtone", nil
end

-- Returns (soundName, soundSet, audioBank) for a given notification key.
local function getNotificationParams(key)
    if key == "vibrate" then
        return "vibrate", "notification"
    end

    local notification
    if key then
        notification = Config.Sound.Notifications[key]
    end
    if not notification then
        local firstKey = next(Config.Sound.Notifications)
        notification = Config.Sound.Notifications[firstKey]
    end

    if notification then
        return notification.name, notification.soundSet, notification.audioBank
    end
    return "1", "notification", nil
end

-- ─── Audio bank loading ───────────────────────────────────────────────────────

-- Requests a script audio bank, waiting up to 1 second before giving up.
-- Returns true on success; on timeout falls back to NUI sound system.
local function loadAudioBank(audioBank)
    local deadline = GetGameTimer() + 1000
    debugprint("Waiting for audio bank to load")

    while true do
        local bankName = audioBank or "dlc_lbscripts/sounds"
        if RequestScriptAudioBank(bankName, false) then
            break
        end

        Wait(0)

        if GetGameTimer() > deadline then
            infoprint("warning", "Failed to load audio bank, setting Config.Sound.System to 'nui'. This usually happens when you have too many sounds on your server.")
            Config.Sound.System = "nui"
            SendReactMessage("updateConfigValue", { config = { sound = { system = "nui" } } })
            return false
        end
    end

    debugprint("Audio bank loaded")
    return true
end

-- ─── Volume helpers ───────────────────────────────────────────────────────────

-- Resolves and clamps the final playback volume from config + player settings.
local function resolveVolume(rawVolume)
    local vol = rawVolume

    -- Override with static volume if configured
    if type(Config.Sound.Volume.Static) == "number" then
        vol = Config.Sound.Volume.Static
    end

    -- Apply multiplier if set
    if Config.Sound.Volume.Multiplier then
        vol = vol * Config.Sound.Volume.Multiplier
    end

    local minVol = Config.Sound.Volume.Min or 0.0
    local maxVol = Config.Sound.Volume.Max or 1.0
    vol = math.clamp(vol, minVol, maxVol)
    vol = math.clamp(vol, 0.0, 1.0)

    -- Normalise (divide by 1 is a no-op but matches original intent)
    vol = (vol or 1) / 1
    return vol
end

-- ─── Core native sound playback ───────────────────────────────────────────────

-- Plays a sound from a given entity with the resolved volume.
-- Spawns a thread to mute/unmute based on MaxDistance if configured.
-- Returns the soundId (caller owns release for ringtone/alarm).
local function playNativeSound(entity, soundType, volume, soundName, soundSet, audioBank)
    if Config.Sound.System == "nui" then return end

    local finalVolume = resolveVolume(volume)
    if finalVolume == 0 then return end

    if not loadAudioBank(audioBank) then return end

    local soundId = GetSoundId()
    debugprint("Playing sound:", soundName, soundSet, "with volume:", finalVolume)

    PlaySoundFromEntity(soundId, soundName, entity, soundSet, false, 0)
    SetVariableOnSound(soundId, "Volume", finalVolume)
    ReleaseScriptAudioBank()

    -- Release immediately for one-shot sounds
    if soundType ~= "ringtone" and soundType ~= "alarm" then
        ReleaseSoundId(soundId)
    end

    -- Distance-based muting thread (only for other players' sounds)
    local localPed = PlayerPedId()
    if entity ~= localPed and Config.Sound.MaxDistance then
        Citizen.CreateThreadNow(function()
            local muted = false
            while true do
                if HasSoundFinished(soundId) then break end

                local myCoords     = GetEntityCoords(localPed)
                local sourceCoords = GetEntityCoords(entity)
                local dist         = #(myCoords - sourceCoords)

                if dist > Config.Sound.MaxDistance then
                    if not muted then
                        SetVariableOnSound(soundId, "Volume", 0.0)
                        debugprint("Sound volume set to 0 due to being too far away")
                        muted = true
                    end
                elseif muted then
                    SetVariableOnSound(soundId, "Volume", finalVolume)
                    debugprint("Sound volume restored")
                    muted = false
                end

                Wait(100)
            end
        end)
    end

    return soundId
end

-- ─── Public: PlayPhoneSound ───────────────────────────────────────────────────

-- Plays a phone sound locally and, if sync is enabled, relays to nearby players.
function PlayPhoneSound(soundType, soundName)
    -- Resolve player volume setting
    local volume = ((settings and settings.sound and settings.sound.volume) or 0.5) / 1

    local resolvedName, resolvedSet, resolvedBank = nil, nil, nil

    debugprint("PlayPhoneSound", soundType)

    if not ValidateChecks("playNativePhoneSound", soundType, soundName) then
        debugprint("PlayPhoneSound: playNativePhoneSound check cancelled the sound")
        return
    end

    -- Stop any existing loop sound before starting a new ringtone/alarm
    if (soundType == "ringtone" or soundType == "alarm") and currentLoopSoundId then
        StopSound(currentLoopSoundId)
        ReleaseSoundId(currentLoopSoundId)
        currentLoopSoundId = nil
    end

    -- Resolve sound parameters based on type
    if soundType == "cameraShutter" then
        resolvedName = "camera-shutter"
        resolvedSet  = "other"

    elseif soundType == "ringtone" then
        local key = soundName
        if not key then
            key = settings and settings.sound and settings.sound.ringtone
        end
        -- Silent mode: force vibrate
        if settings and settings.sound and settings.sound.silent then
            key = "vibrate"
            volume = 1.0
        end
        resolvedName, resolvedSet, resolvedBank = getRingtoneParams(key)

    elseif soundType == "alarm" then
        resolvedName = "alarm"
        resolvedSet  = "other"
        -- Silent mode: vibrate instead
        if settings and settings.sound and settings.sound.silent then
            resolvedName, resolvedSet, resolvedBank = getRingtoneParams("vibrate")
            volume = 1.0
        end

    elseif soundType == "notification" then
        local key = soundName
        if not key then
            key = settings and settings.sound and settings.sound.notification
        end
        resolvedName, resolvedSet, resolvedBank = getNotificationParams(key)

    else
        debugprint("PlayPhoneSound: invalid sound type", soundType)
        return
    end

    local soundId = playNativeSound(PlayerPedId(), soundType, volume, resolvedName, resolvedSet, resolvedBank)
    if not soundId then return end

    -- Cache loop sounds so they can be stopped later
    if soundType == "ringtone" or soundType == "alarm" then
        currentLoopSoundId = soundId
        -- Muffle when phone UI is closed
        if not phoneOpen then
            SetVariableOnSound(soundId, "Muffle", 0.05)
        end
    end

    -- Sync to nearby players if enabled
    if not Config.Sound.Sync then return end

    local nearbyPlayers = GetNearbyPlayers()
    local sources = {}
    for i = 1, #nearbyPlayers do
        sources[i] = nearbyPlayers[i].source
    end

    TriggerServerEvent("phone:sound:playSound", sources, soundType, resolvedName, resolvedSet, resolvedBank)
end

-- ─── Public: StopPhoneSound ───────────────────────────────────────────────────

-- Stops the active ringtone or alarm.
function StopPhoneSound()
    if not currentLoopSoundId then return end
    StopSound(currentLoopSoundId)
    ReleaseSoundId(currentLoopSoundId)
    currentLoopSoundId = nil
end

-- ─── Per-source sound cleanup ─────────────────────────────────────────────────

-- Stops and releases a cached sound for a given server source ID.
local function releaseSourceSound(sourceId)
    local soundId = activeSoundIds[sourceId]
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        activeSoundIds[sourceId] = nil
    end
end

-- ─── Net events ───────────────────────────────────────────────────────────────

-- Receive a relayed sound from the server (another player's phone)
RegisterNetEvent("phone:sound:playSound")
AddEventHandler("phone:sound:playSound", function(originServerId, soundType, volume, soundName, soundSet, audioBank)
    local originPed   = GetPlayerPed(GetPlayerFromServerId(originServerId))
    local localPed    = PlayerPedId()

    -- Don't double-play our own sounds
    if originPed == localPed then return end

    local soundId = playNativeSound(originPed, soundType, volume, soundName, soundSet, audioBank)
    if soundId then
        activeSoundIds[originServerId] = soundId
    end
end)

-- Server telling us to stop
RegisterNetEvent("phone:sound:stopSound")
AddEventHandler("phone:sound:stopSound", function()
    StopPhoneSound()
end)

-- ─── NUI callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback("playSound", function(data, cb)
    cb("ok")
    -- If restarting an alarm/ringtone, stop the server relay first so nearby
    -- players don't hear the old sound overlapping with the new one.
    -- (Local stop is handled inside PlayPhoneSound, but server relay needs
    -- an explicit stop event.)
    if (data.soundType == "alarm" or data.soundType == "ringtone") and currentLoopSoundId then
        TriggerServerEvent("phone:sound:stopSound")
    end
    PlayPhoneSound(data.soundType, data.soundName)
end)

RegisterNUICallback("stopSound", function(data, cb)
    cb("ok")
    TriggerServerEvent("phone:sound:stopSound")
end)

RegisterNUICallback("previewSound", function(data, cb)
    cb("ok")

    -- Require native system
    if not loadAudioBank() then return end

    local soundName, soundSet, audioBank = nil, nil, nil
    local soundType = data.soundType

    if soundType == "ringtone" then
        soundName, soundSet, audioBank = getRingtoneParams(data.sound)
    elseif soundType == "texttone" then
        soundName, soundSet, audioBank = getNotificationParams(data.sound)
    else
        return
    end

    -- Reuse existing soundId or allocate a new one
    if previewSoundId then
        StopSound(previewSoundId)
    else
        previewSoundId = GetSoundId()
    end

    -- Track this preview attempt so we can detect if another one started
    local currentKey = soundName .. soundSet
    previewSoundKey = currentKey

    PlaySoundFrontend(previewSoundId, soundName, soundSet, false)

    -- Resolve volume
    local vol = (settings and settings.sound and settings.sound.volume) or 1
    if type(Config.Sound.Volume.Static) == "number" then
        vol = Config.Sound.Volume.Static
    end
    if Config.Sound.Volume.Multiplier then
        vol = vol * Config.Sound.Volume.Multiplier
    end
    local minVol = Config.Sound.Volume.Min or 0.0
    local maxVol = Config.Sound.Volume.Max or 1.0
    vol = math.clamp(vol, minVol, maxVol)
    vol = math.clamp(vol, 0.0, 1.0)
    vol = (vol or 1) / 1

    SetVariableOnSound(previewSoundId, "Volume", vol)

    -- Auto-stop after 5 seconds if no newer preview started
    Wait(5000)
    if previewSoundKey ~= currentKey then return end
    if not previewSoundId then return end

    StopSound(previewSoundId)
    ReleaseSoundId(previewSoundId)
    ReleaseScriptAudioBank()
    previewSoundId  = nil
    previewSoundKey = nil
end)

RegisterNUICallback("stopPreviewingSound", function(data, cb)
    cb("ok")
    if previewSoundId then
        StopSound(previewSoundId)
        ReleaseSoundId(previewSoundId)
        ReleaseScriptAudioBank()
        previewSoundId  = nil
        previewSoundKey = nil
    end
end)

-- ─── State bag handlers ───────────────────────────────────────────────────────

-- Another player's ringtone/alarm broadcast via state bag
AddStateBagChangeHandler("lbPhoneAudio", nil, function(bagName, _, audioData)
    local playerServerId, playerPed = GetPlayerDataFromStateBag(bagName)
    if not playerServerId then return end

    -- Only process other players' state bags, not our own
    local myServerId = GetPlayerServerId(PlayerId())
    if playerServerId == myServerId then return end

    -- Stop any previous sound for this player
    releaseSourceSound(playerServerId)

    if not audioData or not playerPed then return end

    -- audioData = { soundType, volume, soundName, soundSet, audioBank }
    local soundId = playNativeSound(playerPed, table.unpack(audioData))
    if not soundId then return end

    -- Muffle if the sender's phone UI is closed
    if not Player(playerServerId).state.phoneOpen then
        SetVariableOnSound(soundId, "Muffle", 0.05)
    end

    activeSoundIds[playerServerId] = soundId
end)

-- Adjust muffle when phone is opened/closed
AddStateBagChangeHandler("phoneOpen", nil, function(bagName, _, isOpen)
    -- Extract the player net ID from the bag name ("player:NNN")
    local netId = tonumber(bagName:match("player:(%d+)"))
    if not netId then return end

    local myServerId = GetPlayerServerId(PlayerId())

    -- Determine which sound to adjust: our own loop sound, or a cached peer sound
    local soundId
    if netId == myServerId then
        soundId = currentLoopSoundId
    else
        soundId = activeSoundIds[netId]
    end

    if not soundId then return end

    local muffleValue = isOpen and 1.0 or 0.05
    SetVariableOnSound(soundId, "Muffle", muffleValue)
end)

-- ─── Player drop / resource stop cleanup ─────────────────────────────────────

RegisterNetEvent("onPlayerDropped")
AddEventHandler("onPlayerDropped", function(playerId)
    releaseSourceSound(playerId)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, soundId in pairs(activeSoundIds) do
        ReleaseSoundId(soundId)
    end
    ReleaseScriptAudioBank()
end)

-- ─── Startup: preload audio bank ─────────────────────────────────────────────

CreateThread(function()
    if Config.Sound.System == "nui" then return end

    -- Wait for framework to be ready
    while not FrameworkLoaded do
        Wait(0)
    end

    -- If bank load fails, the system will have already switched to NUI
    if not loadAudioBank() then
        Config.Sound.System = "nui"
    end

    ReleaseScriptAudioBank()
end)