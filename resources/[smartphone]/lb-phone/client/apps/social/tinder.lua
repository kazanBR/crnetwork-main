-- Actions that require CanInteract() check before proceeding
local interactRequiredActions = { "createAccount", "saveProfile", "sendMessage" }

-- =====================================================
-- getMatchList (internal helper)
-- Fetches matches from the server and normalises the
-- raw DB rows into clean client-facing objects.
-- hasMessages: true = conversations, false = new matches
-- =====================================================
local function getMatchList(hasMessages, page)
    local rows = AwaitCallback("spark:getMatches", hasMessages, page)
    local matches = {}

    for i = 1, #rows do
        local row = rows[i]
        local match = {
            name      = row.name,
            number    = row.phone_number,
            photos    = json.decode(row.photos),
            dob       = row.dob,
            bio       = row.bio,
            isMale    = row.is_male,
            timestamp = row.latest_message_timestamp,
            unread    = row.unread == true,
        }

        if row.latest_message then
            match.lastMessage = row.latest_message
            match.lastSender  = row.latest_sender
        end

        matches[i] = match
    end

    return matches
end

-- =====================================================
-- NUI Callback: "Tinder"
-- Central dispatcher for all Spark NUI actions.
-- =====================================================
RegisterNUICallback("Tinder", function(data, cb)
    if not currentPhone then return end

    local action = data.action
    debugprint("Spark:" .. (action or ""))

    -- Certain actions require the player to be able to interact
    if table.contains(interactRequiredActions, action) then
        if not CanInteract() then
            return cb(false)
        end
    end

    -- ------------------------------------------------
    if action == "createAccount" then
        TriggerCallback("spark:createAccount", cb, data.data)

    -- ------------------------------------------------
    elseif action == "deleteAccount" then
        TriggerCallback("spark:deleteAccount", cb)

    -- ------------------------------------------------
    elseif action == "saveProfile" then
        TriggerCallback("spark:updateAccount", cb, data.data)

    -- ------------------------------------------------
    elseif action == "isLoggedIn" then
        local account = AwaitCallback("spark:isLoggedIn", data.phoneNumber)
        cb(account or false)

    -- ------------------------------------------------
    elseif action == "getFeed" then
        local rows = AwaitCallback("spark:getFeed", data.page)
        local feed  = {}

        for i = 1, #rows do
            local row = rows[i]
            feed[i] = {
                name   = row.name,
                dob    = row.dob,
                bio    = row.bio,
                photos = json.decode(row.photos),
                number = row.phone_number,
            }
        end

        cb(feed)

    -- ------------------------------------------------
    elseif action == "swipe" then
        TriggerCallback("spark:swipe", cb, data.number, data.like)

    -- ------------------------------------------------
    elseif action == "getNewMatchesCount" then
        TriggerCallback("spark:getNewMatchesCount", cb)

    -- ------------------------------------------------
    elseif action == "getMatches" then
        -- New (un-messaged) matches
        cb(getMatchList(false, data.page))

    -- ------------------------------------------------
    elseif action == "getRecentMessages" then
        -- Matches that already have a conversation
        cb(getMatchList(true, data.page))

    -- ------------------------------------------------
    elseif action == "sendMessage" then
        local msgData = data.data

        -- Clear attachments if the table is empty so the server receives nil
        if type(msgData.attachments) == "table" and #msgData.attachments == 0 then
            msgData.attachments = nil
        end

        TriggerCallback("spark:sendMessage", cb, msgData.recipient, msgData.content, msgData.attachments)

    -- ------------------------------------------------
    elseif action == "getMessages" then
        local messages = AwaitCallback("spark:getMessages", data.number, data.lastId)

        -- Decode attachment JSON for each message
        for i = 1, #messages do
            local msg = messages[i]
            if msg.attachments then
                msg.attachments = json.decode(msg.attachments)
            else
                msg.attachments = {}
            end
        end

        cb(messages)

    -- ------------------------------------------------
    elseif action == "markAsRead" then
        TriggerCallback("spark:markAsRead", cb, data.number)
    end
end)

-- =====================================================
-- phone:spark:newMessage
-- Fired by the server when the player receives a new
-- message while online. Forwards it to the React NUI.
-- =====================================================
RegisterNetEvent("phone:spark:newMessage")
AddEventHandler("phone:spark:newMessage", function(messageData)
    -- Ensure attachments is always a table, even when empty
    if not messageData.attachments then
        messageData.attachments = {}
    end

    SendReactMessage("tinder:newMessage", messageData)
end)