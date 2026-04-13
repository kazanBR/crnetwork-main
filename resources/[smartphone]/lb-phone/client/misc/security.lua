-- Cached state
local cachedPin = nil       -- currently verified PIN (cleared on reset)
local cachedFaceId = nil    -- cached face identifier for fast re-auth
local cachedIdentifier = nil -- cached player identifier

-- Resets all cached security state and optionally notifies the UI
function ResetSecurity(silent)
    debugprint("ResetSecurity triggered")
    cachedPin = nil
    cachedFaceId = nil
    cachedIdentifier = nil
    if not silent then
        SendReactMessage("resetSecurity")
    end
end

-- Returns the player's unique identifier, fetching and caching it if needed
function GetIdentifier()
    if not cachedIdentifier then
        cachedIdentifier = AwaitCallback("security:getIdentifier")
        debugprint("getIdentifier:", cachedIdentifier)
    end
    return cachedIdentifier or "unknown"
end

-- Validates that a PIN value is a 4-digit numeric string
local function isValidPin(pin)
    if type(pin) ~= "string" then
        return false
    end
    if #pin ~= 4 then
        debugprint("invalid data.pin: invalid length", pin)
        return false
    end
    if not tonumber(pin) then
        debugprint("invalid data.pin: failed to convert to number", pin)
        return false
    end
    return true
end

-- NUI callback handler for all security actions
RegisterNUICallback("Security", function(data, cb)
    local action = data.action
    debugprint("Security:" .. (action or ""), data)

    if action == "setPin" then
        -- Reject if new PIN matches old cached PIN
        if data.pin == cachedPin then
            debugprint("Failed to set pin: new pin is the same as the old pin")
            return cb(false)
        end
        if not isValidPin(data.pin) then
            debugprint("Failed to set pin: invalid pin")
            return cb(false)
        end
        -- Server expects: (phoneNumber, newPin, oldPin)
        local success = AwaitCallback("security:setPin", currentPhone, data.pin, cachedPin)
        if success then
            debugprint("Successfully set pin to", data.pin)
            cachedPin = data.pin
        else
            debugprint("Failed to set pin")
        end
        cb(success)

    elseif action == "removePin" then
        -- Server expects: (phoneNumber, currentPin)
        local success = AwaitCallback("security:removePin", currentPhone, cachedPin)
        if success then
            ResetSecurity()
        end
        cb(success)

    elseif action == "verifyPin" then
        -- If we have a cached PIN, compare locally without a server round-trip
        if cachedPin then
            debugprint("Has cached pin", cachedPin, data.pin)
            return cb(cachedPin == data.pin)
        end
        if not isValidPin(data.pin) then
            debugprint("Failed to verify pin: invalid pin")
            return cb(false)
        end
        -- Server expects: (phoneNumber, inputPin)
        local success = AwaitCallback("security:verifyPin", currentPhone, data.pin)
        debugprint("security:verifyPin returned:", success)
        if success then
            debugprint("Correct pin, caching it", data.pin)
            cachedPin = data.pin
        end
        cb(success)
    end

    if action == "setFaceId" then
        -- Require a matching cached PIN before enabling Face ID
        if cachedPin and cachedPin == data.pin then
            debugprint("Correct pin, triggering enableFaceUnlock")
            -- Server expects: (phoneNumber, pin)
            TriggerCallback("security:enableFaceUnlock", cb, currentPhone, data.pin)
        else
            debugprint("Failed to enable Face Unlock: incorrect pin")
            debugprint(cachedPin, data.pin)
            cb(false)
        end

    elseif action == "removeFaceId" then
        -- Require a matching cached PIN before disabling Face ID
        if cachedPin and cachedPin == data.pin then
            debugprint("Correct pin, triggering disableFaceUnlock")
            -- Server expects: (phoneNumber, pin)
            TriggerCallback("security:disableFaceUnlock", cb, currentPhone, data.pin)
        else
            debugprint("Failed to disable Face Unlock: incorrect pin")
            cb(false)
        end

    elseif action == "verifyFace" then
        if IsFaceObstructed() then
            debugprint("Face is obstructed")
            return cb(false)
        end
        -- Ensure identifier is loaded
        if not cachedIdentifier then
            GetIdentifier()
        end
        -- Use cached face result if available
        if cachedFaceId then
            debugprint("Has cached face, returning:", cachedFaceId == cachedIdentifier)
            return cb(cachedFaceId == cachedIdentifier)
        end
        -- Server expects: (phoneNumber)
        local success = AwaitCallback("security:verifyFace", currentPhone)
        debugprint("security:verifyFace returned:", success)
        if success then
            cachedFaceId = cachedIdentifier
        end
        cb(success)
    end

    if action == "factoryReset" then
        TriggerServerEvent("phone:factoryReset")
    end
end)

-- Server-triggered full factory reset: clears state and re-fetches phone data
RegisterNetEvent("phone:factoryReset")
AddEventHandler("phone:factoryReset", function()
    -- OnDeath closes the phone and clears phone state; guard against nil
    -- in case the global wasn't exported yet (e.g. load-order edge case)
    if OnDeath then
        OnDeath()
    elseif ToggleOpen then
        ToggleOpen(false)
    end
    ResetSecurity()
    FetchPhone()
end)

-- Server-triggered security reset for a specific phone number
RegisterNetEvent("phone:security:reset")
AddEventHandler("phone:security:reset", function(phoneNumber)
    if phoneNumber == currentPhone then
        ResetSecurity()
        Wait(500)
        FetchPhone()
    end
end)