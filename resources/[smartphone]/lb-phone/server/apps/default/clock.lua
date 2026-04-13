-- Fetch all alarms for a given phone number
BaseCallback("clock:getAlarms", function(source, phoneNumber)
    return MySQL.query.await(
        "SELECT id, hours, minutes, label, enabled FROM phone_clock_alarms WHERE phone_number = ?",
        { phoneNumber }
    )
end, {})

-- Insert a new alarm for a given phone number
BaseCallback("clock:createAlarm", function(source, phoneNumber, label, hours, minutes)
    return MySQL.insert.await(
        "INSERT INTO phone_clock_alarms (phone_number, hours, minutes, label) VALUES (@phoneNumber, @hours, @minutes, @label)",
        {
            ["@phoneNumber"] = phoneNumber,
            ["@hours"]       = hours,
            ["@minutes"]     = minutes,
            ["@label"]       = label,
        }
    )
end)

-- Delete an alarm, returns true if a row was affected
BaseCallback("clock:deleteAlarm", function(source, phoneNumber, alarmId)
    return MySQL.update.await(
        "DELETE FROM phone_clock_alarms WHERE id = ? AND phone_number = ?",
        { alarmId, phoneNumber }
    ) > 0
end)

-- Toggle an alarm's enabled state, returns the new state
BaseCallback("clock:toggleAlarm", function(source, phoneNumber, alarmId, enabled)
    MySQL.update.await(
        "UPDATE phone_clock_alarms SET enabled = ? WHERE id = ? AND phone_number = ?",
        { enabled == true, alarmId, phoneNumber }
    )
    return enabled
end)

-- Update an alarm's label/time, returns true if a row was affected
BaseCallback("clock:updateAlarm", function(source, phoneNumber, alarmId, label, hours, minutes)
    return MySQL.update.await(
        "UPDATE phone_clock_alarms SET label = ?, hours = ?, minutes = ? WHERE id = ? AND phone_number = ?",
        { label, hours, minutes, alarmId, phoneNumber }
    ) > 0
end)