RegisterNUICallback("AppStore", function(data, cb)
    -- Ensure a phone is currently open/active
    if not currentPhone then
        return
    end

    local action = data.action
    debugprint("AppStore:" .. (action or ""))

    -- Route action to the appropriate handler
    if action == "buyApp" then
        TriggerCallback("appstore:buyApp", cb, data.price)
    end
end)