local coordsTrackingActive = false
local playerPed            = PlayerPedId()
local lastKnownCoords      = vector3(0, 0, 0)

-- Helper: adds a named location at the given coords (or current player position)
local function addLocation(name, locationOverride)
    if not name then
        return false
    end

    -- Use the provided coords if available, otherwise fall back to the player's current position
    local coords
    if locationOverride then
        coords = vector2(locationOverride[2], locationOverride[1])
    end
    if not coords then
        coords = GetEntityCoords(PlayerPedId())
    end

    local newId = AwaitCallback("maps:addLocation", name, coords.x, coords.y)
    if not newId then
        return false
    end

    -- Build the location entry and append to the local SavedLocations table
    local entry = {
        id       = newId,
        name     = name,
        position = { coords.y, coords.x },
    }
    SavedLocations[#SavedLocations + 1] = entry
    return entry
end

-- Coordinate tracking loop: sends rounded coords to the React UI while the phone is open
local function startCoordUpdates()
    playerPed         = PlayerPedId()
    lastKnownCoords   = GetEntityCoords(playerPed)

    -- Send initial position
    SendReactMessage("maps:updateCoords", {
        x = math.floor(lastKnownCoords.x + 0.5),
        y = math.floor(lastKnownCoords.y + 0.5),
    })

    -- Poll every 250 ms while tracking is enabled
    while coordsTrackingActive do
        local currentCoords = GetEntityCoords(playerPed)

        if phoneOpen then
            -- Only push an update if the player has moved more than 1 unit
            if #(lastKnownCoords - currentCoords) > 1.0 then
                lastKnownCoords = currentCoords
                SendReactMessage("maps:updateCoords", {
                    x = math.floor(currentCoords.x + 0.5),
                    y = math.floor(currentCoords.y + 0.5),
                })
            end
        end

        Wait(250)
    end
end

-- NUI callback router for the Maps app
RegisterNUICallback("Maps", function(data, cb)
    local action = data.action
    debugprint("Maps:" .. (action or ""))

    if action == "getCurrentLocation" then
        -- Return the player's current x/y to the UI
        local coords = GetEntityCoords(PlayerPedId())
        cb({ x = coords.x, y = coords.y })

    elseif action == "toggleUpdateCoords" then
        cb("ok")
        -- Only restart the loop if the toggle state actually changed
        if coordsTrackingActive == data.toggle then
            return
        end
        coordsTrackingActive = (data.toggle == true)
        startCoordUpdates()

    elseif action == "setWaypoint" then
        cb("ok")
        local x = tonumber(data.data.x)
        local y = tonumber(data.data.y)
        if not x or not y then
            return
        end
        SetNewWaypoint(x / 1, y / 1)

    elseif action == "getLocations" then
        cb(SavedLocations)

    elseif action == "addLocation" then
        cb(addLocation(data.name, data.location))

    elseif action == "renameLocation" then
        local newName = data.name
        local success = newName  -- falsy if name is nil/empty

        if newName then
            success = AwaitCallback("maps:renameLocation", data.id, newName)
        end

        if not success then
            return cb(false)
        end

        -- Update the name in the local cache
        for i = 1, #SavedLocations do
            if SavedLocations[i].id == data.id then
                SavedLocations[i].name = newName
                break
            end
        end
        cb(true)

    elseif action == "removeLocation" then
        local success = AwaitCallback("maps:removeLocation", data.id)
        if not success then
            return cb(false)
        end

        -- Remove the entry from the local cache
        for i = 1, #SavedLocations do
            if SavedLocations[i].id == data.id then
                table.remove(SavedLocations, i)
                break
            end
        end
        cb(true)
    end
end)