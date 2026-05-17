local function waitForPhone()
    while GetResourceState('lb-phone') ~= 'started' do
        Wait(1000)
    end
end

local function addApp()
    waitForPhone()

    local app = Config.App or {}
    local added, errorMessage = exports['lb-phone']:AddCustomApp({
        identifier = identifier,
        name = app.name or 'Spotfy',
        description = app.description or 'Musicas e playlists',
        developer = app.developer or 'zVegas',
        defaultApp = app.defaultApp ~= false,
        size = app.size or 48200,
        ui = GetCurrentResourceName() .. '/web/index.html',
        icon = 'https://cfx-nui-' .. GetCurrentResourceName() .. '/web/assets/icon.png',
        fixBlur = true
    })

    if not added then
        print(('[phone-spotfly] Falha ao registrar app no lb-phone: %s'):format(errorMessage or 'erro desconhecido'))
    end
end

CreateThread(addApp)

local soundId = nil
local currentTrack = nil
local currentOutput = 'phone'
local currentVolume = 0.8
local isPlaying = false
local suppressEndEvent = false
local currentVehicleNet = nil
local destroySound

local blockedVehicleClasses = {
    [8] = true, -- motorcycles
    [13] = true -- bicycles
}

local function getSoundId()
    if not soundId then
        soundId = ('spotfly_%s'):format(GetPlayerServerId(PlayerId()))
    end

    return soundId
end

local function getVehicleTarget()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return nil, 'not_in_vehicle'
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil, 'invalid_vehicle'
    end

    local class = GetVehicleClass(vehicle)
    if blockedVehicleClasses[class] then
        return nil, 'blocked_vehicle'
    end

    return vehicle
end

local function getConnectedVehicle()
    if not currentVehicleNet then
        return nil, 'no_vehicle_connected'
    end

    local vehicle = NetworkGetEntityFromNetworkId(currentVehicleNet)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil, 'vehicle_gone'
    end

    return vehicle
end

local function releaseVehicleOutput()
    if currentVehicleNet then
        vSERVER.releaseVehicleOutput(currentVehicleNet)
        currentVehicleNet = nil
    end
end

local function pauseBecauseVehicleUnavailable(reason)
    destroySound()
    releaseVehicleOutput()
    currentOutput = 'phone'
    isPlaying = false

    SendNUIMessage({
        action = 'spotflyOutputChanged',
        output = currentOutput,
        paused = true,
        reason = reason or 'vehicle_unavailable'
    })
end

destroySound = function()
    local id = getSoundId()

    if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
        suppressEndEvent = true
        exports.xsound:Destroy(id)
        suppressEndEvent = false
    end
end

local function playCurrent(timestamp)
    if not currentTrack or not currentTrack.url or GetResourceState('xsound') ~= 'started' then
        return false
    end

    local id = getSoundId()
    local volume = currentVolume
    local options = {
        onPlayEnd = function()
            if suppressEndEvent then
                return
            end

            isPlaying = false
            SendNUIMessage({ action = 'spotflyPlaybackEnded' })
        end
    }

    if exports.xsound:soundExists(id) then
        suppressEndEvent = true
        exports.xsound:Destroy(id)
        suppressEndEvent = false
    end

    if currentOutput == 'vehicle' then
        local vehicle = getConnectedVehicle()
        if not vehicle then
            pauseBecauseVehicleUnavailable('vehicle_gone')
            return false
        else
            exports.xsound:PlayUrlPos(id, currentTrack.url, volume, GetEntityCoords(vehicle), false, options)
            exports.xsound:Distance(id, 20.0)
        end
    else
        exports.xsound:PlayUrl(id, currentTrack.url, volume, false, options)
    end

    if timestamp and timestamp > 0 then
        SetTimeout(350, function()
            if exports.xsound:soundExists(id) then
                exports.xsound:setTimeStamp(id, timestamp)
            end
        end)
    end

    isPlaying = true
    return true
end

local function getTimestamp()
    local id = getSoundId()

    if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
        local timestamp = exports.xsound:getTimeStamp(id)
        return timestamp and timestamp > 0 and timestamp or 0
    end

    return 0
end

CreateThread(function()
    while true do
        Wait(750)

        if currentOutput == 'vehicle' and currentTrack and GetResourceState('xsound') == 'started' then
            local vehicle = getConnectedVehicle()

            if not vehicle then
                pauseBecauseVehicleUnavailable('vehicle_gone')
            elseif exports.xsound:soundExists(getSoundId()) then
                exports.xsound:Position(getSoundId(), GetEntityCoords(vehicle))
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'lb-phone' then
        addApp()
    end
end)

RegisterNUICallback('getData', function(data, cb)
    cb(vSERVER.getData())
end)

RegisterNUICallback('searchYouTube', function(data, cb)
    cb(vSERVER.searchYouTube(data))
end)

RegisterNUICallback('saveState', function(data, cb)
    cb(vSERVER.saveState(data))
end)

RegisterNUICallback('toggleLike', function(data, cb)
    cb(vSERVER.toggleLike(data))
end)

RegisterNUICallback('createPlaylist', function(data, cb)
    cb(vSERVER.createPlaylist(data))
end)

RegisterNUICallback('deletePlaylist', function(data, cb)
    cb(vSERVER.deletePlaylist(data))
end)

RegisterNUICallback('addToPlaylist', function(data, cb)
    cb(vSERVER.addToPlaylist(data))
end)

RegisterNUICallback('removeFromPlaylist', function(data, cb)
    cb(vSERVER.removeFromPlaylist(data))
end)

RegisterNUICallback('addTrack', function(data, cb)
    cb(vSERVER.addTrack(data))
end)

RegisterNUICallback('addRecent', function(data, cb)
    cb(vSERVER.addRecent(data))
end)

RegisterNUICallback('spotflyPlayer', function(data, cb)
    data = data or {}
    local action = data.action
    local id = getSoundId()

    if action == 'play' then
        currentTrack = data.track
        currentVolume = math.max(0.0, math.min(1.0, (tonumber(data.volume) or 80) / 100))
        cb({ ok = playCurrent(tonumber(data.timestamp) or 0), output = currentOutput })
        return
    end

    if action == 'pause' then
        if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
            exports.xsound:Pause(id)
        end

        isPlaying = false
        cb({ ok = true, output = currentOutput })
        return
    end

    if action == 'resume' then
        if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
            exports.xsound:Resume(id)
            isPlaying = true
        elseif currentTrack then
            playCurrent(getTimestamp())
        end

        cb({ ok = true, output = currentOutput })
        return
    end

    if action == 'stop' then
        destroySound()
        releaseVehicleOutput()
        currentTrack = nil
        currentOutput = 'phone'
        isPlaying = false
        cb({ ok = true, output = currentOutput })
        return
    end

    if action == 'volume' then
        currentVolume = math.max(0.0, math.min(1.0, (tonumber(data.volume) or 80) / 100))

        if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
            if currentOutput == 'vehicle' then
                exports.xsound:setVolumeMax(id, currentVolume)
            else
                exports.xsound:setVolume(id, currentVolume)
            end
        end

        cb({ ok = true, output = currentOutput })
        return
    end

    if action == 'seek' then
        local timestamp = tonumber(data.timestamp) or 0

        if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
            exports.xsound:setTimeStamp(id, timestamp)
        end

        cb({ ok = true, output = currentOutput })
        return
    end

    cb({ ok = false, output = currentOutput })
end)

RegisterNUICallback('spotflyStatus', function(data, cb)
    local id = getSoundId()
    local timestamp = 0
    local duration = 0

    if GetResourceState('xsound') == 'started' and exports.xsound:soundExists(id) then
        timestamp = exports.xsound:getTimeStamp(id) or 0
        duration = exports.xsound:getMaxDuration(id) or 0
    end

    cb({
        output = currentOutput,
        playing = isPlaying,
        timestamp = timestamp > 0 and timestamp or 0,
        duration = duration > 0 and duration or 0
    })
end)

RegisterNUICallback('spotflyTargets', function(data, cb)
    local vehicle, reason = getVehicleTarget()

    cb({
        output = currentOutput,
        playing = isPlaying,
        vehicle = vehicle ~= nil,
        reason = reason or false
    })
end)

RegisterNUICallback('spotflySetOutput', function(data, cb)
    local output = data and data.output or 'phone'
    local targetVehicleNet = nil

    if output == 'vehicle' then
        local vehicle, reason = getVehicleTarget()
        if not vehicle then
            cb({ ok = false, output = currentOutput, reason = reason })
            return
        end

        targetVehicleNet = NetworkGetNetworkIdFromEntity(vehicle)
        if not targetVehicleNet or targetVehicleNet == 0 then
            cb({ ok = false, output = currentOutput, reason = 'invalid_vehicle_net' })
            return
        end
    else
        output = 'phone'
    end

    if currentOutput ~= output or (output == 'vehicle' and currentVehicleNet ~= targetVehicleNet) then
        local timestamp = getTimestamp()
        local wasPlaying = isPlaying

        if currentOutput == 'vehicle' and currentVehicleNet and currentVehicleNet ~= targetVehicleNet then
            releaseVehicleOutput()
        end

        currentOutput = output

        if output == 'vehicle' then
            currentVehicleNet = targetVehicleNet
            vSERVER.claimVehicleOutput(currentVehicleNet)
        else
            releaseVehicleOutput()
        end

        if currentTrack then
            playCurrent(timestamp)
            if not wasPlaying and GetResourceState('xsound') == 'started' and exports.xsound:soundExists(getSoundId()) then
                exports.xsound:Pause(getSoundId())
                isPlaying = false
            end
        end
    end

    cb({ ok = true, output = currentOutput })
end)

RegisterNetEvent('spotfy:vehicleOutputTaken', function(vehicleNet)
    if currentOutput ~= 'vehicle' or tonumber(vehicleNet) ~= tonumber(currentVehicleNet) then
        return
    end

    destroySound()
    currentOutput = 'phone'
    currentVehicleNet = nil
    isPlaying = false

    SendNUIMessage({
        action = 'spotflyOutputChanged',
        output = currentOutput,
        paused = true,
        reason = 'vehicle_taken'
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    destroySound()
    releaseVehicleOutput()
end)
