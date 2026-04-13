-- Returns the player's identifier and phone number via legacy callback
RegisterLegacyCallback("security:getIdentifier", function(source, cb)
    local identifier, phoneNumber = GetIdentifier(source)
    cb(identifier, phoneNumber)
end)

-- Sets a PIN for a phone number; validates type/length and checks old PIN
BaseCallback("security:setPin", function(source, cb, phoneNumber, newPin, oldPin)
    if type(newPin) ~= "string" or #newPin ~= 4 then
        debugprint("Failed to set pin: invalid type or length")
        return false
    end

    local rowsChanged = MySQL.update.await(
        "UPDATE phone_phones SET pin = ? WHERE phone_number = ? AND (pin = ? OR pin IS NULL)",
        { newPin, phoneNumber, oldPin or "" }
    )
    local success = rowsChanged > 0
    debugprint("phone:security:setPin", GetPlayerName(source), success, phoneNumber, newPin, oldPin)
    return success
end, false)

-- Removes (clears) the PIN for a phone number after verifying the current PIN
BaseCallback("security:removePin", function(source, cb, phoneNumber, currentPin)
    if type(currentPin) ~= "string" or #currentPin ~= 4 then
        debugprint("Failed to remove pin: invalid type or length")
        return false
    end

    local rowsChanged = MySQL.update.await(
        "UPDATE phone_phones SET pin = NULL, face_id = NULL WHERE phone_number = ? AND (pin = ? OR pin IS NULL)",
        { phoneNumber, currentPin }
    )
    return rowsChanged > 0
end, false)

-- Verifies a PIN against the stored value; nil PIN in DB is treated as "no lock"
BaseCallback("security:verifyPin", function(source, cb, phoneNumber, inputPin)
    if type(inputPin) ~= "string" or #inputPin ~= 4 then
        debugprint("Failed to verify pin: invalid type or length")
        return false
    end

    local storedPin = MySQL.scalar.await(
        "SELECT pin FROM phone_phones WHERE phone_number = ?",
        { phoneNumber }
    )
    -- A nil stored PIN means no PIN is set; treat as verified
    local success = (storedPin == nil or storedPin == inputPin)
    debugprint("phone:security:verifyPin", GetPlayerName(source), success, storedPin, inputPin)
    return success
end, false)

-- Enables Face ID for a phone number after PIN verification
BaseCallback("security:enableFaceUnlock", function(source, cb, phoneNumber, pin)
    if type(pin) ~= "string" or #pin ~= 4 then
        debugprint("Failed to enable face unlock: invalid type or length")
        return false
    end

    local identifier = GetIdentifier(source)
    local rowsChanged = MySQL.update.await(
        "UPDATE phone_phones SET face_id = ? WHERE phone_number = ? AND pin = ?",
        { identifier, phoneNumber, pin }
    )
    return rowsChanged > 0
end, false)

-- Disables Face ID for a phone number after PIN verification
BaseCallback("security:disableFaceUnlock", function(source, cb, phoneNumber, pin)
    if type(pin) ~= "string" or #pin ~= 4 then
        debugprint("Failed to disable face unlock: invalid type or length")
        return false
    end

    return MySQL.update.await(
        "UPDATE phone_phones SET face_id = NULL WHERE phone_number = ? AND (pin = ? OR pin IS NULL)",
        { phoneNumber, pin }
    )
end, false)

-- Verifies Face ID by comparing stored face_id with the player's identifier
BaseCallback("security:verifyFace", function(source, cb, phoneNumber)
    local identifier = GetIdentifier(source)
    local storedFaceId = MySQL.scalar.await(
        "SELECT face_id FROM phone_phones WHERE phone_number = ?",
        { phoneNumber }
    )
    debugprint("phone:security:verifyFace", GetPlayerName(source), storedFaceId, identifier)
    return storedFaceId == identifier
end, false)

-- Clears PIN and Face ID for a phone number; notifies the client if online
function ResetSecurity(phoneNumber)
    assert(type(phoneNumber) == "string",
        "Invalid argument #1 to ResetSecurity, expected string, got " .. type(phoneNumber))

    MySQL.update.await(
        "UPDATE phone_phones SET pin = NULL, face_id = NULL WHERE phone_number = ?",
        { phoneNumber }
    )

    local playerSource = GetSourceFromNumber(phoneNumber)
    if playerSource then
        TriggerClientEvent("phone:security:reset", playerSource, phoneNumber)
    end
end
ResetSecurity = ResetSecurity

-- Export: retrieves the stored PIN for a given phone number
exports("GetPin", function(phoneNumber)
    assert(type(phoneNumber) == "string",
        "Invalid argument #1 to GetPin, expected string, got " .. type(phoneNumber))
    return MySQL.scalar.await(
        "SELECT pin FROM phone_phones WHERE phone_number = ?",
        { phoneNumber }
    )
end)

-- Export: exposes ResetSecurity to other resources
exports("ResetSecurity", ResetSecurity)