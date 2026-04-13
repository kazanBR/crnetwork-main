-- NUI callback handler: routes all DarkChat UI actions to the appropriate server callbacks
RegisterNUICallback("DarkChat", function(data, cb)
    if not currentPhone then return end

    local action = data.action
    debugprint("DarkChat:" .. (action or ""))

    if action == "getUsername" then
        TriggerCallback("darkchat:getUsername", cb)

    elseif action == "setPassword" then
        TriggerCallback("darkchat:setPassword", cb, data.password)

    elseif action == "login" then
        TriggerCallback("darkchat:login", cb, data.username, data.password)

    elseif action == "logout" then
        TriggerCallback("darkchat:logout", cb)

    elseif action == "changePassword" then
        TriggerCallback("darkchat:changePassword", cb, data.oldPassword, data.newPassword)

    elseif action == "deleteAccount" then
        TriggerCallback("darkchat:deleteAccount", cb, data.password)

    elseif action == "register" then
        TriggerCallback("darkchat:register", cb, data.username, data.password)

    elseif action == "getChannels" then
        TriggerCallback("darkchat:getChannels", cb)

    elseif action == "createChannel" then
        TriggerCallback("darkchat:createChannel", cb, data.channel, data.password)

    elseif action == "joinChannel" then
        TriggerCallback("darkchat:joinChannel", cb, data.channel, data.password)

    elseif action == "getMessages" then
        TriggerCallback("darkchat:getMessages", cb, data.channel, data.lastId)

    elseif action == "sendMessage" then
        -- Check interaction cooldown before allowing send
        if not CanInteract() then
            return cb(false)
        end
        TriggerCallback("darkchat:sendMessage", cb, data.channel, data.content)

    elseif action == "leaveChannel" then
        TriggerCallback("darkchat:leaveChannel", cb, data.channel)
    end
end)


-- Net event: new message received in a channel
RegisterNetEvent("phone:darkChat:newMessage")
AddEventHandler("phone:darkChat:newMessage", function(channelName, sender, content)
    SendReactMessage("darkChat:newMessage", {
        channel = channelName,
        sender  = sender,
        content = content,
    })
end)


-- Net event: a user joined or left a channel
RegisterNetEvent("phone:darkChat:updateChannel")
AddEventHandler("phone:darkChat:updateChannel", function(channelName, username, action)
    SendReactMessage("darkChat:updateChannel", {
        action   = action,
        channel  = channelName,
        username = username,
    })
end)


-- Net event: this client was added to a new channel
RegisterNetEvent("phone:darkChat:joinChannel")
AddEventHandler("phone:darkChat:joinChannel", function(channelData)
    SendReactMessage("darkChat:addChannel", channelData)
end)


-- Net event: this client was removed from a channel
RegisterNetEvent("phone:darkChat:leaveChannel")
AddEventHandler("phone:darkChat:leaveChannel", function(channelName)
    SendReactMessage("darkChat:leaveChannel", channelName)
end)