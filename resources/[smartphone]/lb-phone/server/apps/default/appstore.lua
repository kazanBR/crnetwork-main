RegisterLegacyCallback("appstore:buyApp", function(source, cb, price)
    -- Verify the player has a phone equipped
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then
        return cb(false)
    end

    -- Attempt to charge the player and return the result
    local success, result, extra = RemoveMoney(source, price)
    cb(success, result, extra)
end)