RegisterNUICallback("Notes", function(data, cb)
    -- Ensure a phone is currently active
    if not currentPhone then
        return
    end

    local action = data.action
    debugprint("Notes:" .. (action or ""))

    -- Some actions wrap their payload in a nested `data` field
    local payload = data.data and data.data or data

    if action == "create" then
        TriggerCallback("notes:createNote", cb, payload.title, payload.content)

    elseif action == "save" then
        TriggerCallback("notes:saveNote", cb, payload.id, payload.title, payload.content)

    elseif action == "fetch" then
        TriggerCallback("notes:getNotes", cb)

    elseif action == "remove" then
        TriggerCallback("notes:removeNote", cb, payload.id)
    end
end)