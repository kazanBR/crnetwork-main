-- Auto-join channels on MySQL ready
if Config.AutoJoinDarkChat and #Config.AutoJoinDarkChat > 0 then
    MySQL.ready(function()
        -- Wait until database checker has finished
        while not DatabaseCheckerFinished do
            Wait(500)
        end

        -- Build batch insert params for each auto-join channel
        local params = {}
        for i = 1, #Config.AutoJoinDarkChat do
            params[#params + 1] = { Config.AutoJoinDarkChat[i] }
        end

        MySQL.rawExecute("INSERT IGNORE INTO phone_darkchat_channels (`name`) VALUES (?)", params)
    end)
end

-- Callback: get the logged-in DarkChat username for a phone number
BaseCallback("darkchat:getUsername", function(source, phoneNumber)
    local username = GetLoggedInAccount(phoneNumber, "DarkChat")

    if not username then
        -- Try to find an account with no password (guest/linked account)
        username = MySQL.scalar.await(
            "SELECT username FROM phone_darkchat_accounts WHERE phone_number = ? AND `password` IS NULL",
            { phoneNumber }
        )

        if username then
            AddLoggedInAccount(phoneNumber, "DarkChat", username)
        else
            return false
        end
    end

    -- Check whether this account has a password set
    local hasPassword = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_accounts WHERE username = ? AND `password` IS NOT NULL",
        { username }
    )

    if not hasPassword then
        return { username = username, password = false }
    end

    return { username = username, password = true }
end, nil, { defaultReturn = { success = false, reason = "unknown" }, preventSpam = true })


-- Callback: set a password for an account that doesn't have one yet
BaseCallback("darkchat:setPassword", function(source, phoneNumber, password)
    if #password < 3 then
        debugprint("DarkChat: password < 3 characters")
        return false
    end

    local username = GetLoggedInAccount(phoneNumber, "DarkChat")

    if username then
        -- Only allow setting password if one isn't already set
        local alreadyHasPassword = MySQL.scalar.await(
            "SELECT TRUE FROM phone_darkchat_accounts WHERE username = ? AND `password` IS NOT NULL",
            { username }
        )

        if alreadyHasPassword then
            return false
        end
    else
        return false
    end

    local hash = GetPasswordHash(password)
    MySQL.update.await("UPDATE phone_darkchat_accounts SET `password` = ? WHERE username = ?", { hash, username })
    return true
end, nil, { defaultReturn = false, preventSpam = true })


-- Callback: login with username + password
BaseCallback("darkchat:login", function(source, phoneNumber, username, password)
    local storedHash = MySQL.scalar.await(
        "SELECT `password` FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )

    if not storedHash then
        return { success = false, reason = "invalid_username" }
    end

    if not VerifyPasswordHash(password, storedHash) then
        return { success = false, reason = "incorrect_password" }
    end

    AddLoggedInAccount(phoneNumber, "DarkChat", username)
    return { success = true }
end, nil, { defaultReturn = { success = false, reason = "unknown" }, preventSpam = true })


-- Callback: register a new DarkChat account
BaseCallback("darkchat:register", function(source, phoneNumber, username, password)
    username = username:lower()

    if not IsUsernameValid(username) then
        return { success = false, reason = "USERNAME_NOT_ALLOWED" }
    end

    local taken = MySQL.scalar.await(
        "SELECT 1 FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )

    if taken then
        return { success = false, reason = "username_taken" }
    end

    local hash = GetPasswordHash(password)
    local affected = MySQL.update.await(
        "INSERT INTO phone_darkchat_accounts (phone_number, username, `password`) VALUES (?, ?, ?)",
        { phoneNumber, username, hash }
    )

    if not (affected > 0) then
        return { success = false, reason = "unknown" }
    end

    AddLoggedInAccount(phoneNumber, "DarkChat", username)

    -- Auto-join configured channels for the new user
    if Config.AutoJoinDarkChat and #Config.AutoJoinDarkChat > 0 then
        local memberParams = {}
        for i = 1, #Config.AutoJoinDarkChat do
            memberParams[#memberParams + 1] = { Config.AutoJoinDarkChat[i], username }
        end
        MySQL.prepare.await(
            "INSERT INTO phone_darkchat_members (channel_name, username) VALUES (?, ?)",
            memberParams
        )
    end

    return { success = true }
end, nil, { defaultReturn = { success = false, reason = "unknown" }, preventSpam = true })


-- Helper: register an authenticated DarkChat callback (requires logged-in account)
local function RegisterAuthCallback(action, handler, defaultReturn)
    local eventName = "darkchat:" .. action

    BaseCallback(eventName, function(source, phoneNumber, ...)
        local username = GetLoggedInAccount(phoneNumber, "DarkChat")
        if not username then
            return defaultReturn
        end
        return handler(source, phoneNumber, username, ...)
    end, nil, { defaultReturn = defaultReturn, preventSpam = true })
end


-- Callback: change password (requires old password verification)
RegisterAuthCallback("changePassword", function(source, phoneNumber, username, oldPassword, newPassword)
    if not Config.ChangePassword.DarkChat then
        infoprint("warning", ("%s tried to change password on DarkChat, but it's not enabled in the config."):format(source))
        return false
    end

    if oldPassword == newPassword or #newPassword < 3 then
        debugprint("same password / too short")
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT `password` FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )

    if not storedHash or not VerifyPasswordHash(oldPassword, storedHash) then
        return false
    end

    local newHash = GetPasswordHash(newPassword)
    local affected = MySQL.update.await(
        "UPDATE phone_darkchat_accounts SET `password` = ? WHERE username = ?",
        { newHash, username }
    )

    if not (affected > 0) then
        return false
    end

    -- Notify all other sessions that they've been logged out due to password change
    NotifyLoggedInAccounts("DarkChat", username, {
        title   = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
        content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    }, { phoneNumber })

    -- Remove all other logged-in sessions for this account
    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'DarkChat' AND phone_number != ?",
        { username, phoneNumber }
    )

    ClearActiveAccountsCache("DarkChat", username, phoneNumber)

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = username,
        app      = "darkchat",
        reason   = "password",
        number   = phoneNumber,
    })

    return true
end)


-- Callback: delete account (requires password confirmation)
RegisterAuthCallback("deleteAccount", function(source, phoneNumber, username, password)
    if not Config.DeleteAccount.DarkChat then
        infoprint("warning", ("%s tried to delete their account on DarkChat, but it's not enabled in the config."):format(source))
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT `password` FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )

    if not storedHash or not VerifyPasswordHash(password, storedHash) then
        return false
    end

    -- Notify other sessions of deletion
    NotifyLoggedInAccounts("DarkChat", username, {
        title   = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
        content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"),
    })

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'DarkChat'",
        { username }
    )

    ClearActiveAccountsCache("DarkChat", username)

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = username,
        app      = "darkchat",
        reason   = "deleted",
    })

    return true
end)


-- Callback: logout
RegisterAuthCallback("logout", function(source, phoneNumber, username)
    RemoveLoggedInAccount(phoneNumber, "DarkChat", username)
    return true
end)


-- Internal: validate and create a channel (returns success, errorReason)
local function CreateChannel(channelName, password)
    assert(type(channelName) == "string", "channel must be a string")

    -- Validate channel name: non-empty, max 50 chars, no whitespace
    if not channelName
        or #channelName < 1
        or #channelName > 50
        or channelName:find("%s")
    then
        debugprint("darkchat: invalid channel name")
        return false, "invalid_name"
    end

    local exists = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_channels WHERE `name` = ?",
        { channelName }
    )

    if exists then
        debugprint("darkchat:createChannel: channel already exists", channelName)
        return false, "channel_exists"
    end

    -- Hash password if provided
    local passwordHash = nil
    if password then
        passwordHash = GetPasswordHash(password)
    end

    local affected = MySQL.update.await(
        "INSERT INTO phone_darkchat_channels (`name`, `password`) VALUES (@name, @password)",
        { ["@name"] = channelName, ["@password"] = passwordHash }
    )

    if not (affected > 0) then
        debugprint("darkchat:createChannel: failed to create channel", channelName)
        return false, "unknown_error"
    end

    return true
end


-- Callback: createChannel
RegisterAuthCallback("createChannel", function(source, phoneNumber, username, channelName, password)
    if not ValidateChecks("createDarkChatChannel", source, username, channelName) then
        debugprint("darkchat:createChannel: createDarkChatChannel check returned false")
        return false
    end

    local ok, reason = CreateChannel(channelName, password)
    if not ok then
        return reason
    end

    Log("DarkChat", source, "info",
        L("BACKEND.LOGS.DARKCHAT_CREATED_TITLE"),
        L("BACKEND.LOGS.DARKCHAT_CREATED_DESCRIPTION", { creator = username, channel = channelName })
    )

    local affected = MySQL.update.await(
        "INSERT INTO phone_darkchat_members (channel_name, username) VALUES (?, ?)",
        { channelName, username }
    )

    if not (affected > 0) then
        debugprint("darkchat:createChannel: failed to insert into members")
        return "unknown_error"
    end

    return { name = channelName, members = 1 }
end)


-- Callback: joinChannel
RegisterAuthCallback("joinChannel", function(source, phoneNumber, username, channelName, password)
    -- Check user isn't already a member
    local alreadyMember = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_members WHERE channel_name = ? AND username = ?",
        { channelName, username }
    )

    if alreadyMember then
        debugprint("darkchat: already in channel")
        return "already_in_channel"
    end

    -- Fetch channel details
    local channel = MySQL.single.await(
        "SELECT `name`, `password` FROM phone_darkchat_channels WHERE `name` = ?",
        { channelName }
    )

    if not channel then
        return "invalid_channel"
    end

    if not ValidateChecks("joinDarkChatChannel", source, username, channelName) then
        debugprint("darkchat:joinChannel: joinDarkChatChannel check returned false")
        return "check_failed"
    end

    -- Verify password if channel is protected
    if channel.password then
        if not password then
            debugprint("darkchat:joinChannel: password required")
            return "password_required"
        end

        if not VerifyPasswordHash(password, channel.password) then
            debugprint("darkchat:joinChannel: incorrect password")
            return "incorrect_password"
        end
    end

    MySQL.update.await(
        "INSERT INTO phone_darkchat_members (channel_name, username) VALUES (?, ?)",
        { channelName, username }
    )

    local memberCount = MySQL.scalar.await(
        "SELECT COUNT(username) FROM phone_darkchat_members WHERE channel_name = ?",
        { channelName }
    )

    local lastMessage = MySQL.single.await([[
        SELECT sender, content, `timestamp`
        FROM phone_darkchat_messages
        WHERE `channel` = ?
        ORDER BY `id` DESC
        LIMIT 1
    ]], { channelName })

    local result = {
        name    = channelName,
        members = memberCount or 1,
    }

    if lastMessage then
        result.sender      = lastMessage.sender
        result.lastMessage = lastMessage.content
        result.timestamp   = lastMessage.timestamp
    end

    TriggerClientEvent("phone:darkChat:updateChannel", -1, channelName, username, "joined")
    return result
end)


-- Callback: leaveChannel
RegisterAuthCallback("leaveChannel", function(source, phoneNumber, username, channelName)
    local affected = MySQL.update.await(
        "DELETE FROM phone_darkchat_members WHERE channel_name = ? AND username = ?",
        { channelName, username }
    )

    if not affected then
        return false
    end

    TriggerClientEvent("phone:darkChat:updateChannel", -1, channelName, username, "left")
    return true
end)


-- Callback: getChannels (returns all channels the user is a member of)
RegisterAuthCallback("getChannels", function(source, phoneNumber, username)
    return MySQL.query.await([[
        SELECT
            c.name,
            (SELECT COUNT(username) FROM phone_darkchat_members WHERE channel_name = c.name) AS members,
            m.sender,
            m.content AS lastMessage,
            m.timestamp

        FROM phone_darkchat_channels c

        LEFT JOIN phone_darkchat_messages m ON m.channel = c.name
            AND m.id = (SELECT MAX(id) FROM phone_darkchat_messages WHERE channel = c.name)

        WHERE EXISTS (SELECT 1 FROM phone_darkchat_members WHERE channel_name = c.name AND username = ?)
    ]], { username })
end, {})


-- Callback: getMessages (paginated, 15 messages per page)
RegisterAuthCallback("getMessages", function(source, phoneNumber, username, channelName, lastId)
    local query = [[
        SELECT
            id,
            sender,
            content,
            `timestamp`

        FROM phone_darkchat_messages

        WHERE `channel` = @channel
            {PAGINATION}

        ORDER BY `id` DESC

        LIMIT 15
    ]]

    query = query:gsub("{PAGINATION}", lastId and "AND id < @lastId" or "")

    return MySQL.query.await(query, { channel = channelName, lastId = lastId })
end)


-- Internal: insert a message and broadcast to channel members
local function SendMessageInternal(username, channelName, content)
    local id = MySQL.insert.await(
        "INSERT INTO phone_darkchat_messages (sender, `channel`, content) VALUES (?, ?, ?)",
        { username, channelName, content }
    )

    if not id then
        return false
    end

    -- Push notification to active members (excluding sender)
    NotifyPhonesWithQuery([[
        phone_darkchat_members m
        JOIN phone_logged_in_accounts l
            ON l.app = 'DarkChat'
            AND l.`active` = 1
            AND l.username = m.username
        WHERE
            m.channel_name = @channel
            AND m.username != @username
    ]], {
        app     = "DarkChat",
        title   = channelName,
        content = username .. ": " .. content,
    }, "l.", { ["@channel"] = channelName, ["@username"] = username })

    TriggerEvent("lb-phone:darkchat:newMessage", channelName, username, content)
    TriggerClientEvent("phone:darkChat:newMessage", -1, channelName, username, content)
    return true
end


-- Callback: sendMessage
RegisterAuthCallback("sendMessage", function(source, phoneNumber, username, channelName, content)
    if ContainsBlacklistedWord(source, "DarkChat", content) then
        return false
    end

    if not ValidateChecks("sendDarkchatMessage", source, username, channelName, content) then
        debugprint("darkchat:sendMessage: sendDarkchatMessage check returned false")
        return false
    end

    if not SendMessageInternal(username, channelName, content) then
        return false
    end

    Log("DarkChat", source, "info",
        L("BACKEND.LOGS.DARKCHAT_MESSAGE_TITLE"),
        L("BACKEND.LOGS.DARKCHAT_MESSAGE_DESCRIPTION", { sender = username, channel = channelName, message = content })
    )

    return true
end)


-- Export: SendDarkChatMessage
exports("SendDarkChatMessage", function(username, channelName, message, callback)
    assert(type(username) == "string",    "username must be a string")
    assert(type(channelName) == "string", "channel must be a string")
    assert(type(message) == "string",     "message must be a string")

    local result = SendMessageInternal(username, channelName, message)

    if callback then
        callback(result)
    end

    return result
end)


-- Export: SendDarkChatLocation (encodes coords as a special message)
exports("SendDarkChatLocation", function(username, channelName, coords, callback)
    assert(type(username) == "string",    "Expected string for argument 1, got " .. type(username))
    assert(type(channelName) == "string", "Expected string for argument 2, got " .. type(channelName))
    assert(type(coords) == "vector2",     "Expected vector2 for argument 3, got " .. type(coords))

    local locationMsg = "<!SENT-LOCATION-X=" .. coords.x .. "Y=" .. coords.y .. "!>"
    local result = SendMessageInternal(username, channelName, locationMsg)

    if callback then
        callback(result)
    end

    return result
end)


-- Export: AddUserToDarkChatChannel
exports("AddUserToDarkChatChannel", function(username, channelName)
    assert(type(username) == "string",    "username must be a string")
    assert(type(channelName) == "string", "channel must be a string")

    -- Already a member?
    local alreadyMember = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_members WHERE channel_name = ? AND username = ?",
        { channelName, username }
    )

    if alreadyMember then
        debugprint("AddUserToDarkChatChannel: already in channel")
        return true
    end

    -- Channel must exist
    local channelExists = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_channels WHERE `name` = ?",
        { channelName }
    )

    if not channelExists then
        debugprint("AddUserToDarkChatChannel: channel does not exist", channelName)
        return false
    end

    local affected = MySQL.update.await(
        "INSERT INTO phone_darkchat_members (channel_name, username) VALUES (?, ?)",
        { channelName, username }
    )

    if not (affected > 0) then
        debugprint("AddUserToDarkChatChannel: failed to insert into members")
        return false
    end

    local memberCount = MySQL.scalar.await(
        "SELECT COUNT(username) FROM phone_darkchat_members WHERE channel_name = ?",
        { channelName }
    )

    local lastMessage = MySQL.single.await([[
        SELECT sender, content, `timestamp`
        FROM phone_darkchat_messages
        WHERE `channel` = ?
        ORDER BY `id` DESC
        LIMIT 1
    ]], { channelName })

    local channelData = {
        name    = channelName,
        members = memberCount or 1,
    }

    if lastMessage then
        channelData.sender      = lastMessage.sender
        channelData.lastMessage = lastMessage.content
        channelData.timestamp   = lastMessage.timestamp
    end

    TriggerClientEvent("phone:darkChat:updateChannel", -1, channelName, username, "joined")

    -- Trigger join event on all active client sessions for this user
    local loggedInNumbers = GetLoggedInNumbers("DarkChat", username)
    for _, number in ipairs(loggedInNumbers) do
        local playerSource = GetSourceFromNumber(number)
        if playerSource then
            TriggerClientEvent("phone:darkChat:joinChannel", playerSource, channelData)
        end
    end

    return true
end)


-- Export: RemoveUserFromDarkChatChannel
exports("RemoveUserFromDarkChatChannel", function(username, channelName)
    assert(type(username) == "string",    "username must be a string")
    assert(type(channelName) == "string", "channel must be a string")

    local affected = MySQL.update.await(
        "DELETE FROM phone_darkchat_members WHERE channel_name = ? AND username = ?",
        { channelName, username }
    )

    if not affected then
        return false
    end

    TriggerClientEvent("phone:darkChat:updateChannel", -1, channelName, username, "left")

    -- Trigger leave event on all active client sessions for this user
    local loggedInNumbers = GetLoggedInNumbers("DarkChat", username)
    for _, number in ipairs(loggedInNumbers) do
        local playerSource = GetSourceFromNumber(number)
        if playerSource then
            TriggerClientEvent("phone:darkChat:leaveChannel", playerSource, channelName)
        end
    end

    debugprint("Removed " .. username .. " from DarkChat channel " .. channelName)
    return true
end)


-- Export: CreateDarkChatChannel (exposes internal CreateChannel)
exports("CreateDarkChatChannel", CreateChannel)


-- Export: DeleteDarkChatChannel
exports("DeleteDarkChatChannel", function(channelName)
    assert(type(channelName) == "string", "channel must be a string")

    local affected = MySQL.update.await(
        "DELETE FROM phone_darkchat_channels WHERE `name` = ?",
        { channelName }
    )

    if not (affected > 0) then
        return false
    end

    -- Force all clients to leave the deleted channel
    TriggerClientEvent("phone:darkChat:leaveChannel", -1, channelName)
end)