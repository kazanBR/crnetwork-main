-- Battery levels cache: keyed by phone_number -> battery level (0-100)
local batteryLevels = {}

-- =====================================================
-- SET BATTERY (net event from client)
-- =====================================================

RegisterNetEvent("phone:battery:setBattery")
AddEventHandler("phone:battery:setBattery", function(batteryLevel)
    local playerSource = source

    if not Config.Battery.Enabled then
        return debugprint("setBattery: battery system disabled")
    end

    if type(batteryLevel) ~= "number" or batteryLevel < 0 or batteryLevel > 100 then
        return debugprint("setBattery: invalid battery")
    end

    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then return end

    batteryLevels[phoneNumber] = batteryLevel
end)

-- =====================================================
-- IS PHONE DEAD
-- =====================================================

local function IsPhoneDeadFn(phoneNumber)
    if not Config.Battery.Enabled then
        return false
    end
    return batteryLevels[phoneNumber] == 0
end

IsPhoneDead = IsPhoneDeadFn
exports("IsPhoneDead", IsPhoneDead)

-- =====================================================
-- SAVE BATTERY (persist to DB for one player)
-- =====================================================

local function SaveBatteryFn(playerSource)
    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if not phoneNumber then return end
    if not batteryLevels[phoneNumber] then return end

    debugprint(("saving battery level (%s) for %s"):format(batteryLevels[phoneNumber], phoneNumber))

    MySQL.update(
        "UPDATE phone_phones SET battery = ? WHERE phone_number = ?",
        { batteryLevels[phoneNumber], phoneNumber },
        function()
            batteryLevels[phoneNumber] = nil
        end
    )
end

SaveBattery = SaveBatteryFn
exports("SaveBattery", SaveBattery)

-- =====================================================
-- SAVE ALL BATTERIES
-- =====================================================

local function SaveAllBatteries()
    debugprint("saving all battery levels")
    for _, playerStr in ipairs(GetPlayers()) do
        local playerSource = tonumber(playerStr)
        if playerSource then
            SaveBattery(playerSource)
        end
    end
end

exports("SaveAllBatteries", SaveAllBatteries)

-- =====================================================
-- EVENT HANDLERS
-- =====================================================

-- Save battery on player disconnect
AddEventHandler("playerDropped", function()
    SaveBattery(source)
end)

-- Save all batteries 60 seconds before scheduled txAdmin restart
AddEventHandler("txAdmin:events:scheduledRestart", function(eventData)
    if eventData.secondsRemaining == 60 then
        SaveAllBatteries()
    end
end)

-- Save all batteries on server shutdown
AddEventHandler("txAdmin:events:serverShuttingDown", SaveAllBatteries)

-- Save all batteries when this resource stops
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SaveAllBatteries()
    end
end)