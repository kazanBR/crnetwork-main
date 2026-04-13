-- Actions that require CanInteract() check before proceeding
local interactRestrictedActions = { "sendMessage", "createGroup", "renameGroup" }

-- NUI callback: dispatch all Messages UI actions to appropriate server callbacks
RegisterNUICallback("Messages", function(data, cb)
    if not currentPhone then
        return
    end

    local action = data.action
    debugprint("Messages:", action or "")

    -- Block interaction-restricted actions when player cannot interact
    if table.contains(interactRestrictedActions, action) then
        if not CanInteract() then
            return cb(false)
        end
    end

    -- Encode attachments as JSON if present and non-empty, otherwise nil
    if data.attachments and #data.attachments == 0 then
        data.attachments = nil
    elseif data.attachments then
        data.attachments = json.encode(data.attachments)
    end

    if action == "sendMessage" then
        -- Fire-and-forget server event for external listeners, then callback for UI
        TriggerServerEvent("phone:messages:messageSent", data.number, data.content, data.attachments)
        TriggerCallback("messages:sendMessage", cb, data.number, data.content, data.attachments, data.id)

    elseif action == "createGroup" then
        -- Extract plain phone numbers from member objects
        local numbers = {}
        for i, member in ipairs(data.members) do
            numbers[i] = member.number
        end
        TriggerCallback("messages:createGroup", cb, numbers, data.content, data.attachments)

    elseif action == "renameGroup" then
        TriggerCallback("messages:renameGroup", cb, data.id, data.name)

    elseif action == "getRecentMessages" then
        local rows = AwaitCallback("messages:getRecentMessages")

        -- Build a deduplicated channel list from the flat join result.
        -- Each row represents one member of one channel; group channels appear
        -- once per member so we collect members incrementally.
        local channels = {}

        -- Helper: return the index of a channel in `channels` by id, or false
        local function findChannelIndex(channelId)
            for i, ch in ipairs(channels) do
                if ch.id == channelId then
                    return i
                end
            end
            return false
        end

        -- First pass: build channel entries and collect group members
        for _, row in ipairs(rows) do
            local idx = findChannelIndex(row.channel_id)
            if not idx then
                if row.is_group then
                    -- New group channel: create entry with first member
                    channels[#channels + 1] = {
                        id          = row.channel_id,
                        lastMessage = row.last_message,
                        timestamp   = row.last_message_timestamp,
                        name        = row.name,
                        isGroup     = true,
                        members     = { { isOwner = row.is_owner, number = row.phone_number } },
                    }
                elseif row.phone_number ~= currentPhone then
                    -- New DM channel (skip self-rows)
                    channels[#channels + 1] = {
                        id          = row.channel_id,
                        lastMessage = row.last_message,
                        timestamp   = row.last_message_timestamp,
                        number      = row.phone_number,
                        isGroup     = false,
                    }
                end
            else
                -- Existing group channel: append this member
                if row.is_group then
                    local members = channels[idx].members
                    members[#members + 1] = { isOwner = row.is_owner, number = row.phone_number }
                end
            end
        end

        -- Second pass: apply per-player deleted/unread flags from own member rows
        for _, row in ipairs(rows) do
            local idx = findChannelIndex(row.channel_id)
            if idx and row.phone_number == currentPhone then
                channels[idx].deleted = row.deleted
                channels[idx].unread  = row.unread > 0
            end
        end

        cb(channels)

    elseif action == "getMessages" then
        TriggerCallback("messages:getMessages", function(messages)
            -- Decode attachments on each message before sending to UI
            for _, msg in ipairs(messages) do
                msg.attachments = json.decode(msg.attachments or "[]")
            end
            cb(messages)
        end, data.id, data.lastId)

    elseif action == "deleteMessage" then
        if Config.DeleteMessages then
            TriggerCallback("messages:deleteMessage", cb, data.id, data.channel)
        end

    elseif action == "addMember" then
        TriggerCallback("messages:addMember", cb, data.id, data.number)

    elseif action == "removeMember" then
        TriggerCallback("messages:removeMember", cb, data.id, data.number)

    elseif action == "leaveGroup" then
        TriggerCallback("messages:leaveGroup", cb, data.id)

    elseif action == "markRead" then
        TriggerCallback("messages:markRead", cb, data.id)

    elseif action == "deleteConversations" then
        TriggerCallback("messages:deleteConversations", cb, data.channels)
    end
end)

-- Net event: new message received — forward to React UI
RegisterNetEvent("phone:messages:newMessage", function(channelId, messageId, sender, content, attachmentsJson)
    local attachments = (attachmentsJson and json.decode(attachmentsJson)) or {}
    SendReactMessage("messages:newMessage", {
        channelId   = channelId,
        messageId   = messageId,
        sender      = sender,
        content     = content,
        attachments = attachments,
    })
end)

-- Net event: message deleted — forward to React UI
RegisterNetEvent("phone:messages:messageDeleted", function(channelId, messageId, isLastMessage)
    SendReactMessage("messages:messageDeleted", {
        channelId     = channelId,
        messageId     = messageId,
        isLastMessage = isLastMessage,
    })
end)

-- Net event: group renamed — forward to React UI
RegisterNetEvent("phone:messages:renameGroup", function(channelId, name)
    SendReactMessage("messages:renameGroup", { channelId = channelId, name = name })
end)

-- Net event: member added to group — forward to React UI
RegisterNetEvent("phone:messages:memberAdded", function(channelId, number)
    SendReactMessage("messages:addMember", { channelId = channelId, number = number })
end)

-- Net event: member removed from group — forward to React UI
RegisterNetEvent("phone:messages:memberRemoved", function(channelId, number)
    SendReactMessage("messages:removeMember", { channelId = channelId, number = number })
end)

-- Net event: group ownership transferred — forward to React UI
RegisterNetEvent("phone:messages:ownerChanged", function(channelId, number)
    SendReactMessage("messages:changeOwner", { channelId = channelId, number = number })
end)

-- Net event: new channel created — forward to React UI
RegisterNetEvent("phone:messages:newChannel", function(channelData)
    SendReactMessage("messages:newChannel", channelData)
end)