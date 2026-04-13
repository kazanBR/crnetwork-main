-- Early exit if sound sync is disabled
if not Config.Sound.Sync then
    return
end

-- Valid sound types that clients are permitted to trigger
local validSoundTypes = {
    cameraShutter = true,
    notification  = true,
    ringtone      = true,
    alarm         = true,
}

-- Build a whitelist of allowed sound name keys: "name_soundSet_audioBank"
local validSounds = {
    ["vibrate_ringtone_"]         = true,
    ["alarm_other_"]              = true,
    ["camera-shutter_other_"]     = true,
}

for _, ringtone in pairs(Config.Sound.Ringtones) do
    local key = ringtone.name .. "_" .. ringtone.soundSet .. "_" .. (ringtone.audioBank or "")
    validSounds[key] = true
end

for _, notification in pairs(Config.Sound.Notifications) do
    local key = notification.name .. "_" .. notification.soundSet .. "_" .. (notification.audioBank or "")
    validSounds[key] = true
end

-- Relay a phone sound to a list of nearby players, with optional distance culling
RegisterNetEvent("phone:sound:playSound")
AddEventHandler("phone:sound:playSound", function(targetSources, soundType, soundName, soundSet, audioBank)
    local src = source
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then return end

    -- Validate sound type
    if not validSoundTypes[soundType] then
        infoprint("warning", DebugPlayerName(src) .. " tried to play an invalid sound type: " .. tostring(soundType))
        return
    end

    -- Build and validate the sound key
    local soundKey = soundName .. "_" .. (soundSet or "") .. "_" .. (audioBank or "")
    if not validSounds[soundKey] then
        infoprint("warning", DebugPlayerName(src) .. " tried to play an invalid sound: " .. soundKey)
        return
    end

    -- Fetch this player's volume setting
    local playerSettings = GetSettings(phoneNumber)
    local volume = (playerSettings and playerSettings.sound and playerSettings.sound.volume) or 1.0

    -- Ringtones and alarms are broadcast via state bag instead of direct event
    if soundType == "ringtone" or soundType == "alarm" then
        Player(src).state.lbPhoneAudio = { soundType, volume, soundName, soundSet, audioBank }
        return
    end

    if not targetSources then return end

    -- Get sender's position for distance check
    local senderCoords = GetEntityCoords(GetPlayerPed(src))

    for i = 1, #targetSources do
        local targetSrc = targetSources[i]

        if Config.Sound.DistanceCheck and senderCoords then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetSrc))
            local dist = #(senderCoords - targetCoords)
            if dist > 100.0 then
                debugprint("Skipping sound for source:", targetSrc, "due to distance check.")
            else
                TriggerClientEvent("phone:sound:playSound", targetSrc, src, soundType, volume, soundName, soundSet, audioBank)
            end
        else
            TriggerClientEvent("phone:sound:playSound", targetSrc, src, soundType, volume, soundName, soundSet, audioBank)
        end
    end
end)

-- Tell the triggering player to stop their phone sound
RegisterNetEvent("phone:sound:stopSound")
AddEventHandler("phone:sound:stopSound", function()
    local src = source
    Player(src).state.lbPhoneAudio = nil
    TriggerClientEvent("phone:sound:stopSound", src)
end)