-- Returns the channel id or nil.
local function FindDMChannel(numberA, numberB)
    return MySQL.scalar.await([[
        SELECT c.id FROM phone_message_channels c
        WHERE c.is_group = 0
            AND EXISTS (SELECT TRUE FROM phone_message_members m WHERE m.channel_id = c.id AND m.phone_number = ?)
            AND EXISTS (SELECT TRUE FROM phone_message_members m WHERE m.channel_id = c.id AND m.phone_number = ?)
    ]], { numberA, numberB })
end

-- Internal: validate inputs, create channel if needed, persist message,
-- notify recipients, and fire events.
-- Parameters: sender, recipient, content, attachments, callback, channelId
-- Returns: { channelId, messageId } or nil
local function SendMessage(sender, recipient, content, attachments, callback, channelId)
    -- Need at least a recipient or a channelId to know where to send
    if not (channelId or recipient) or not sender then
        return
    end

    -- Require content or non-empty attachments
    if not content then
        if not attachments or #attachments == 0 then
            debugprint("No message or attachments provided")
            return
        end
    end

    -- Normalise empty content string to nil
    if content and #content == 0 then
        content = nil
        if not attachments or #attachments == 0 then
            debugprint("No attachments provided")
            return
        end
    end

    -- Block if either party has the other blocked
    local blocked = MySQL.scalar.await([[
        SELECT 1 FROM phone_phone_blocked_numbers
        WHERE (phone_number = ? AND blocked_number = ?)
            OR (phone_number = ? AND blocked_number = ?)
    ]], { sender, recipient, recipient, sender })

    if blocked then
        debugprint("Message blocked between " .. sender .. " and " .. recipient)
        return
    end

    -- Resolve or create the channel
    if not channelId then
        channelId = FindDMChannel(sender, recipient)
    end

    local senderSrc    = GetSourceFromNumber(sender)
    local recipientSrc = GetSourceFromNumber(recipient)

    if not channelId then
        -- Create a new DM channel and add both members
        channelId = MySQL.insert.await("INSERT INTO phone_message_channels (is_group) VALUES (0)")
        MySQL.update.await(
            "INSERT IGNORE INTO phone_message_members (channel_id, phone_number) VALUES (?, ?), (?, ?)",
            { channelId, sender, channelId, recipient }
        )

        local now = os.time() * 1000

        if senderSrc then
            TriggerClientEvent("phone:messages:newChannel", senderSrc, {
                id          = channelId,
                lastMessage = content,
                timestamp   = now,
                number      = recipient,
                isGroup     = false,
                unread      = false,
            })
        end

        if recipientSrc then
            TriggerClientEvent("phone:messages:newChannel", recipientSrc, {
                id          = channelId,
                lastMessage = content,
                timestamp   = now,
                number      = sender,
                isGroup     = false,
                unread      = true,
            })
        end
    end

    -- Log the outgoing message
    if senderSrc and recipient then
        Log("Messages", senderSrc, "info",
            L("BACKEND.LOGS.MESSAGE_TITLE"),
            L("BACKEND.LOGS.NEW_MESSAGE", {
                sender    = FormatNumber(sender),
                recipient = FormatNumber(recipient),
                message   = content or "Attachment",
            })
        )
    end

    -- Encode attachments table to JSON string if needed
    if type(attachments) == "table" then
        attachments = json.encode(attachments)
    end

    -- Persist the message
    local messageId = MySQL.insert.await(
        "INSERT INTO phone_message_messages (channel_id, sender, content, attachments) VALUES (@channelId, @sender, @content, @attachments)",
        {
            ["@channelId"]   = channelId,
            ["@sender"]      = sender,
            ["@content"]     = content,
            ["@attachments"] = attachments,
        }
    )

    if not messageId then
        if callback then callback(false) end
        return
    end

    -- Update channel preview, unread counts, and restore soft-deleted visibility
    MySQL.update(
        "UPDATE phone_message_channels SET last_message = ? WHERE id = ?",
        { string.sub(content or "Attachment", 1, 50), channelId }
    )
    MySQL.update(
        "UPDATE phone_message_members SET unread = unread + 1 WHERE channel_id = ? AND phone_number != ?",
        { channelId, sender }
    )
    MySQL.update(
        "UPDATE phone_message_members SET deleted = 0 WHERE channel_id = ?",
        { channelId }
    )

    -- Notify all other channel members
    local members = MySQL.query.await(
        "SELECT phone_number FROM phone_message_members WHERE channel_id = ? AND phone_number != ?",
        { channelId, sender }
    )

    for _, member in ipairs(members) do
        local number    = member.phone_number
        local memberSrc = GetSourceFromNumber(number)

        if memberSrc then
            TriggerClientEvent("phone:messages:newMessage", memberSrc,
                channelId, messageId, sender, content, attachments)
        end

        -- Skip notification for automated call-no-answer system messages
        if content ~= "<!CALL-NO-ANSWER!>" then
            local contact = GetContact(sender, number)
            local displayName = (contact and contact.name) or sender
            local thumbnail = nil
            if attachments then
                local decoded = json.decode(attachments)
                thumbnail = decoded and decoded[1]
            end

            SendNotification(number, {
                app        = "Messages",
                title      = displayName,
                content    = content,
                thumbnail  = thumbnail,
                avatar     = contact and contact.avatar,
                showAvatar = true,
            })
        end
    end

    if callback then callback(channelId) end

    TriggerEvent("lb-phone:messages:messageSent", {
        channelId   = channelId,
        messageId   = messageId,
        sender      = sender,
        recipient   = recipient,
        message     = content,
        attachments = attachments,
    })

    return { channelId = channelId, messageId = messageId }
end

SendMessage = SendMessage

-- Export: send a payment notification message between two numbers
exports("SentMoney", function(sender, recipient, amount)
    assert(type(sender)    == "string", "Expected string for argument 1, got " .. type(sender))
    assert(type(recipient) == "string", "Expected string for argument 2, got " .. type(recipient))
    assert(type(amount)    == "number", "Expected number for argument 3, got " .. type(amount))
    SendMessage(sender, recipient, "<!SENT-PAYMENT-" .. math.floor(amount + 0.5) .. "!>")
end)

-- Export: send a location pin between two numbers
exports("SendCoords", function(sender, recipient, coords)
    assert(type(sender)    == "string",  "Expected string for argument 1, got "  .. type(sender))
    assert(type(recipient) == "string",  "Expected string for argument 2, got "  .. type(recipient))
    assert(type(coords)    == "vector2", "Expected vector2 for argument 3, got " .. type(coords))
    SendMessage(sender, recipient, "<!SENT-LOCATION-X=" .. coords.x .. "Y=" .. coords.y .. "!>")
end)

-- Export: public API for sending a message programmatically
exports("SendMessage", function(sender, recipient, content, attachments, callback, channelId)
    assert(type(sender)    == "string",   "Expected string for argument 1, got "            .. type(sender))
    assert(type(recipient) == "string",   "Expected string or nil for argument 2, got "     .. type(recipient))
    assert(type(content)   == "string",   "Expected string or nil for argument 3, got "     .. type(content))
    assert(type(attachments) == "table",  "Expected table, string or nil for argument 4, got " .. type(attachments))
    assert(type(callback)  == "function", "Expected function or nil for argument 5, got "   .. type(callback))
    return SendMessage(sender, recipient, content, attachments, callback, channelId)
end)

-- Callback: send a message from a player (blacklist-checked)
BaseCallback("messages:sendMessage", function(src, phoneNumber, recipient, content, attachments, channelId)
    if ContainsBlacklistedWord(src, "Messages", content) then
        return false
    end
    return SendMessage(phoneNumber, recipient, content, attachments, nil, channelId)
end)

-- Callback: create a new group channel with initial members and first message
BaseCallback("messages:createGroup", function(src, phoneNumber, memberNumbers, content, attachments)
    local channelId = MySQL.insert.await("INSERT INTO phone_message_channels (is_group) VALUES (1)")
    if not channelId then
        return false
    end

    -- Add the creator as owner
    local members = { { number = phoneNumber, isOwner = true } }
    MySQL.update.await(
        "INSERT INTO phone_message_members (channel_id, phone_number, is_owner) VALUES (?, ?, 1)",
        { channelId, phoneNumber }
    )

    -- Add each invited member
    for i, number in ipairs(memberNumbers) do
        MySQL.update.await(
            "INSERT INTO phone_message_members (channel_id, phone_number, is_owner) VALUES (?, ?, 0)",
            { channelId, number }
        )
        members[i + 1] = { number = number, isOwner = false }
    end

    local channelData = {
        id          = channelId,
        lastMessage = content,
        timestamp   = os.time() * 1000,
        name        = nil,
        isGroup     = true,
        members     = members,
        unread      = false,
    }

    -- Notify invited members who are online
    for _, number in ipairs(memberNumbers) do
        local memberSrc = GetSourceFromNumber(number)
        if memberSrc then
            TriggerClientEvent("phone:messages:newChannel", memberSrc, channelData)
        end
    end

    -- Notify the creator
    TriggerClientEvent("phone:messages:newChannel", src, channelData)

    -- Send the first message into the group
    return SendMessage(phoneNumber, nil, content, attachments, nil, channelId)
end)

-- Callback: rename a group channel
BaseCallback("messages:renameGroup", function(src, phoneNumber, channelId, newName)
    local affected = MySQL.update.await(
        "UPDATE phone_message_channels SET `name` = ? WHERE id = ? AND is_group = 1",
        { newName, channelId }
    )
    local ok = affected > 0
    if ok then
        TriggerClientEvent("phone:messages:renameGroup", -1, channelId, newName)
    end
    return ok
end)

-- Callback: fetch the recent conversation list for a player.
-- Returns raw join rows; the client reshapes them into channel objects.
BaseCallback("messages:getRecentMessages", function(src, phoneNumber)
    return MySQL.query.await([[
        SELECT
            channel.id AS channel_id,
            channel.is_group,
            channel.`name`,
            channel.last_message,
            channel.last_message_timestamp,
            channel_member.phone_number,
            channel_member.is_owner,
            channel_member.unread,
            channel_member.deleted
        FROM phone_message_members target_member
        INNER JOIN phone_message_channels channel
            ON channel.id = target_member.channel_id
        INNER JOIN phone_message_members channel_member
            ON channel_member.channel_id = channel.id
        WHERE target_member.phone_number = ?
        ORDER BY channel.last_message_timestamp DESC
    ]], { phoneNumber })
end)

-- Callback: fetch paginated messages for a channel
BaseCallback("messages:getMessages", function(src, phoneNumber, channelId, lastId)
    local query = [[
        SELECT id, sender, content, attachments, `timestamp`
        FROM phone_message_messages
        WHERE
            channel_id = @channelId
            AND EXISTS (SELECT TRUE FROM phone_message_members m WHERE m.channel_id = @channelId AND m.phone_number = @phoneNumber)
            {PAGINATION}
        ORDER BY id DESC
        LIMIT 25
    ]]

    query = query:gsub("{PAGINATION}", lastId and "AND id < @lastId" or "")

    return MySQL.query.await(query, {
        channelId   = channelId,
        phoneNumber = phoneNumber,
        lastId      = lastId,
    })
end)

-- Callback: delete a specific message (sender-only, config-gated)
BaseCallback("messages:deleteMessage", function(src, phoneNumber, messageId, channelId)
    if not Config.DeleteMessages then
        return false
    end

    -- Check if this is the channel's last message (affects preview update)
    local maxId      = MySQL.scalar.await("SELECT MAX(id) FROM phone_message_messages WHERE channel_id = ?", { channelId })
    local isLastMsg  = maxId == messageId

    local affected = MySQL.update.await(
        "DELETE FROM phone_message_messages WHERE id = ? AND sender = ? AND channel_id = ?",
        { messageId, phoneNumber, channelId }
    )
    local deleted = affected > 0

    -- Update channel preview if the deleted message was the last one
    if deleted and isLastMsg then
        MySQL.update.await(
            "UPDATE phone_message_channels SET last_message = ? WHERE id = ?",
            { L("APPS.MESSAGES.MESSAGE_DELETED"), channelId }
        )
    end

    if deleted then
        TriggerClientEvent("phone:messages:messageDeleted", -1, channelId, messageId, isLastMsg)
    end

    return deleted
end)

-- Callback: add a member to a group (respects optional member limit)
BaseCallback("messages:addMember", function(src, phoneNumber, channelId, newMemberNumber)
    -- Enforce group member limit if configured
    if type(Config.GroupMessageMemberLimit) == "number" then
        local count = MySQL.scalar.await(
            "SELECT COUNT(1) FROM phone_message_members WHERE channel_id = ?",
            { channelId }
        ) or 0

        if count >= Config.GroupMessageMemberLimit then
            SendNotification(phoneNumber, {
                app        = "Messages",
                title      = L("APPS.MESSAGES.GROUP_MEMBER_LIMIT_NOTIFICATION.TITLE"),
                content    = L("APPS.MESSAGES.GROUP_MEMBER_LIMIT_NOTIFICATION.CONTENT", { limit = Config.GroupMessageMemberLimit }),
                showAvatar = false,
            })
            return false
        end
    end

    local affected = MySQL.update.await(
        "INSERT IGNORE INTO phone_message_members (channel_id, phone_number) VALUES (?, ?)",
        { channelId, newMemberNumber }
    )
    if affected <= 0 then
        return false
    end

    TriggerClientEvent("phone:messages:memberAdded", -1, channelId, newMemberNumber)

    -- If the new member is online, push the full channel data so their UI updates
    local newMemberSrc = GetSourceFromNumber(newMemberNumber)
    if not newMemberSrc then
        return true
    end

    local members   = MySQL.Sync.fetchAll(
        "SELECT phone_number AS `number`, is_owner AS isOwner FROM phone_message_members WHERE channel_id = ?",
        { channelId }
    )
    local channelInfo = MySQL.single.await(
        "SELECT `name`, last_message, last_message_timestamp FROM phone_message_channels WHERE id = ?",
        { channelId }
    )

    if #members > 0 and channelInfo then
        TriggerClientEvent("phone:messages:newChannel", newMemberSrc, {
            id          = channelId,
            lastMessage = channelInfo.last_message,
            timestamp   = channelInfo.last_message_timestamp,
            name        = channelInfo.name,
            isGroup     = true,
            members     = members,
            unread      = false,
        })
    end

    return true
end)

-- Callback: remove a specific member from a group (owner-only action)
BaseCallback("messages:removeMember", function(src, phoneNumber, channelId, targetNumber)
    -- Verify the requesting player is actually the owner
    local isOwner = MySQL.scalar.await(
        "SELECT is_owner FROM phone_message_members WHERE channel_id = ? AND phone_number = ?",
        { channelId, phoneNumber }
    )
    if not isOwner then
        return false
    end

    local affected = MySQL.update.await(
        "DELETE FROM phone_message_members WHERE channel_id = ? AND phone_number = ?",
        { channelId, targetNumber }
    )
    local removed = affected > 0

    if removed then
        TriggerClientEvent("phone:messages:memberRemoved", -1, channelId, targetNumber)
    end

    return removed
end)

-- Callback: leave a group; transfers ownership if the leaver was owner,
-- and deletes the channel entirely if it becomes empty
BaseCallback("messages:leaveGroup", function(src, phoneNumber, channelId)
    local isOwner = MySQL.scalar.await(
        "SELECT is_owner FROM phone_message_members WHERE channel_id = ? AND phone_number = ?",
        { channelId, phoneNumber }
    )

    -- Transfer ownership to another member before leaving
    if isOwner then
        MySQL.update.await([[
            UPDATE phone_message_members m
            SET is_owner = TRUE
            WHERE m.channel_id = ?
            AND m.phone_number != ?
            LIMIT 1
        ]], { channelId, phoneNumber })

        local newOwner = MySQL.scalar.await(
            "SELECT phone_number FROM phone_message_members WHERE channel_id = ? AND is_owner = TRUE",
            { channelId }
        )
        TriggerClientEvent("phone:messages:ownerChanged", -1, channelId, newOwner)
    end

    local affected = MySQL.update.await(
        "DELETE FROM phone_message_members WHERE channel_id = ? AND phone_number = ?",
        { channelId, phoneNumber }
    )
    local left = affected > 0

    local remaining = MySQL.scalar.await(
        "SELECT COUNT(1) FROM phone_message_members WHERE channel_id = ?",
        { channelId }
    )
    local isEmpty = remaining == 0

    if left then
        TriggerClientEvent("phone:messages:memberRemoved", -1, channelId, phoneNumber)
    end

    -- Clean up the channel row if no members remain
    if isEmpty then
        MySQL.update.await("DELETE FROM phone_message_channels WHERE id = ?", { channelId })
        debugprint("Deleted group " .. channelId, "due to it being empty")
    end

    return left
end)

-- Callback: mark all messages in a channel as read for the player
BaseCallback("messages:markRead", function(src, phoneNumber, channelId)
    MySQL.update.await(
        "UPDATE phone_message_members SET unread = 0 WHERE channel_id = ? AND phone_number = ?",
        { channelId, phoneNumber }
    )
    return true
end)

-- Callback: soft-delete a list of conversations for the player
BaseCallback("messages:deleteConversations", function(src, phoneNumber, channelIds)
    if type(channelIds) ~= "table" then
        debugprint("expected table, got " .. type(channelIds))
        return false
    end

    MySQL.update.await(
        "UPDATE phone_message_members SET deleted = 1 WHERE channel_id IN (?) AND phone_number = ?",
        { channelIds, phoneNumber }
    )
    return true
end)