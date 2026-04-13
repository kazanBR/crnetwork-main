-- Stores the currently open mail (used for action validation)
local currentMail = nil

-- Internal: decode JSON fields on a mail object returned from server.
-- Returns the mail on success, false if nil was passed.
local function DecodeMail(mail)
    if not mail then
        return false
    end

    if not mail.attachments then
        mail.attachments = {}
    else
        mail.attachments = json.decode(mail.attachments)
    end

    if not mail.actions then
        mail.actions = {}
    else
        mail.actions = json.decode(mail.actions)
    end

    return mail
end

-- NUI callback: dispatch all Mail UI actions to the appropriate server callback
RegisterNUICallback("Mail", function(data, cb)
    local action = data.action
    debugprint("Mail:", action or "")

    if action == "isLoggedIn" then
        TriggerCallback("mail:isLoggedIn", cb)

    elseif action == "createMail" then
        TriggerCallback("mail:createAccount", cb, data.data.email, data.data.password)

    elseif action == "changePassword" then
        TriggerCallback("mail:changePassword", cb, data.oldPassword, data.newPassword)

    elseif action == "deleteAccount" then
        TriggerCallback("mail:deleteAccount", cb, data.password)

    elseif action == "login" then
        TriggerCallback("mail:login", cb, data.data.email, data.data.password)

    elseif action == "logout" then
        TriggerCallback("mail:logout", cb)

    elseif action == "getMails" then
        TriggerCallback("mail:getMails", cb, { lastId = data.lastId })

    elseif action == "getMail" then
        -- Decode the mail, cache it for action validation, then send to UI
        TriggerCallback("mail:getMail", function(mail)
            local decoded = DecodeMail(mail)
            currentMail = decoded
            cb(decoded)
        end, data.id)

    elseif action == "search" then
        TriggerCallback("mail:getMails", cb, { search = data.query, lastId = data.lastId })

    elseif action == "sendMail" then
        TriggerCallback("mail:sendMail", cb, data.data)

    elseif action == "deleteMail" then
        TriggerCallback("mail:deleteMail", cb, data.id)

    elseif action == "action" then
        -- Validate that the action belongs to the currently open mail
        if not currentMail or currentMail.id ~= data.id then
            return debugprint("wrong mail id for action")
        end

        local actionIndex = (data.actionId or 0) + 1
        local actionEntry = currentMail.actions[actionIndex]
        local actionData  = actionEntry and actionEntry.data

        if not actionData then
            return debugprint("no action found", actionIndex)
        end

        -- QB-mail compat: unwrap nested data and fire as a local event
        if actionData.data and actionData.data.qbMail then
            TriggerEvent(actionData.event, actionData.data.data)
            return cb("ok")
        end

        -- Fire as server or client event depending on the action definition
        if actionData.isServer then
            TriggerServerEvent(actionData.event, data.id, actionData.data)
        else
            TriggerEvent(actionData.event, data.id, actionData.data)
        end

        cb("ok")
    end
end)

-- Net event: new mail received — forward to the React UI
RegisterNetEvent("phone:mail:newMail", function(mail)
    SendReactMessage("mail:newMail", mail)
end)

-- Net event: mail deleted — forward to the React UI
RegisterNetEvent("phone:mail:mailDeleted", function(mailId)
    SendReactMessage("mail:deleteMail", mailId)
end)