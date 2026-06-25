-- =====================================================
--  lb-phone · client/apps/social/tinder.lua
--  Deobfuscated by Eazy Fxap
-- =====================================================

local interactionActions = {
    "createAccount",
    "saveProfile",
    "sendMessage"
}

local function GetMatches(onlyRecent, page)
    local rows = AwaitCallback("spark:getMatches", onlyRecent, page)
    local matches = {}

    for i = 1, #rows do
        local row = rows[i]
        local match = {
            name = row.name,
            number = row.phone_number,
            photos = json.decode(row.photos),
            dob = row.dob,
            bio = row.bio,
            isMale = row.is_male,
            timestamp = row.latest_message_timestamp,
            unread = row.unread == true
        }

        if row.latest_message then
            match.lastMessage = row.latest_message
            match.lastSender = row.latest_sender
        end

        matches[i] = match
    end

    return matches
end

RegisterNUICallback("Tinder", function(data, callback)
    if not currentPhone then
        return
    end

    local action = data.action

    debugprint("Spark:" .. (action or ""))

    if table.contains(interactionActions, action) and not CanInteract() then
        return callback(false)
    end

    if action == "createAccount" then
        return TriggerCallback("spark:createAccount", callback, data.data)
    elseif action == "deleteAccount" then
        return TriggerCallback("spark:deleteAccount", callback)
    elseif action == "saveProfile" then
        return TriggerCallback("spark:updateAccount", callback, data.data)
    elseif action == "isLoggedIn" then
        return callback(AwaitCallback("spark:isLoggedIn", data.phoneNumber) or false)
    elseif action == "getFeed" then
        local rows = AwaitCallback("spark:getFeed", data.page)
        local feed = {}

        for i = 1, #rows do
            local row = rows[i]

            feed[i] = {
                name = row.name,
                dob = row.dob,
                bio = row.bio,
                photos = json.decode(row.photos),
                number = row.phone_number
            }
        end

        callback(feed)
    elseif action == "swipe" then
        TriggerCallback("spark:swipe", callback, data.number, data.like)
    elseif action == "getNewMatchesCount" then
        TriggerCallback("spark:getNewMatchesCount", callback)
    elseif action == "getMatches" then
        return callback(GetMatches(false, data.page))
    elseif action == "getRecentMessages" then
        return callback(GetMatches(true, data.page))
    elseif action == "sendMessage" then
        local message = data.data

        if type(message.attachments) ~= "table" or #message.attachments == 0 then
            message.attachments = nil
        end

        TriggerCallback("spark:sendMessage", callback, message.recipient, message.content, message.attachments)
    elseif action == "getMessages" then
        local messages = AwaitCallback("spark:getMessages", data.number, data.lastId)

        for i = 1, #messages do
            if messages[i].attachments then
                messages[i].attachments = json.decode(messages[i].attachments)
            else
                messages[i].attachments = {}
            end
        end

        callback(messages)
    elseif action == "markAsRead" then
        TriggerCallback("spark:markAsRead", callback, data.number)
    end
end)

RegisterNetEvent("phone:spark:newMessage", function(message)
    message.attachments = message.attachments or {}
    SendNUIAction("tinder:newMessage", message)
end)
