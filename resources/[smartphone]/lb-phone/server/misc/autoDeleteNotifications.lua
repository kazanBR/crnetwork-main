if not Config.AutoDeleteNotifications then
    return
end
if type(Config.AutoDeleteNotifications) ~= "number" then
    Config.AutoDeleteNotifications = 168
end

-- Wait until the database checker has finished initializing
while not DatabaseCheckerFinished do
    Wait(500)
end

-- Run the cleanup loop every hour
while true do
    debugprint("Deleting all old notifications..")

    local startTime = os.nanotime()

    MySQL.update(
        "DELETE FROM phone_notifications WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL ? HOUR)",
        { Config.AutoDeleteNotifications },
        function(rowsDeleted)
            local elapsed = (os.nanotime() - startTime) / 1000000.0
            local suffix = rowsDeleted == 1 and "" or "s"
            debugprint("Deleted " .. rowsDeleted .. " notification" .. suffix .. " in " .. elapsed .. " ms")
        end
    )

    Wait(3600000) -- Wait 1 hour before next cleanup
end