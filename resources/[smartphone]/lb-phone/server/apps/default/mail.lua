-- Export: get the logged-in email address for a player
exports("GetEmailAddress", function(phoneNumber)
    return GetLoggedInAccount(phoneNumber, "Mail", true)
end)

-- Helper: wrap a callback with a Mail login guard.
-- Calls handler(src, player, account, ...) only if the player is logged in to Mail.
-- Falls back to defaultReturn if not logged in.
local function RegisterMailCallback(eventName, handler, defaultReturn)
    BaseCallback("mail:" .. eventName, function(src, player, ...)
        local account = GetLoggedInAccount(player, "Mail")
        if not account then
            return defaultReturn
        end
        return handler(src, player, account, ...)
    end, defaultReturn)
end

-- Internal: create a mail account with the given address and password.
-- Returns: success (bool), reason (string or nil)
local CreateMailAccount
CreateMailAccount = function(address, password, callback)
    if not address or not password or #address < 3 or #password < 3 then
        if callback then
            callback({ success = false, reason = "Invalid email / password" })
        end
        return false, "Invalid email / password"
    end

    local hashedPassword = GetPasswordHash(password)

    -- Check if address is already taken
    local exists = MySQL.scalar.await("SELECT 1 FROM phone_mail_accounts WHERE address=?", { address })
    if exists then
        if callback then
            callback({ success = false, error = "Address already exists" })
        end
        return false, "Address already exists"
    end

    -- Insert new account
    local affected = MySQL.update.await(
        "INSERT INTO phone_mail_accounts (address, `password`) VALUES (?, ?)",
        { address, hashedPassword }
    )
    if affected ~= 1 then
        if callback then
            callback({ success = false, error = "Server error" })
        end
        return false, "Server error"
    end

    if callback then
        callback({ success = true })
    end
    return true
end

exports("CreateMailAccount", CreateMailAccount)

-- Callback: create account from client (appends configured email domain)
BaseCallback("mail:createAccount", function(src, player, localAddress, password)
    if #localAddress < 3 or #password < 3 then
        return { success = false, error = "Invalid email / password" }
    end

    local address = localAddress .. "@" .. Config.EmailDomain
    local ok, err = CreateMailAccount(address, password)

    if ok then
        AddLoggedInAccount(player, "Mail", address)
    end

    return { success = ok, error = err }
end)

-- Callback: change Mail account password
RegisterMailCallback("changePassword", function(src, player, account, oldPassword, newPassword)
    -- Check feature enabled in config
    if not Config.ChangePassword.Mail then
        infoprint("warning", ("%s tried to change password on Mail, but it's not enabled in the config."):format(src))
        return false
    end

    -- New password must differ and be long enough
    if oldPassword == newPassword or #newPassword < 3 then
        debugprint("same password / too short")
        return false
    end

    -- Verify old password against stored hash
    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_mail_accounts WHERE address = ?",
        { account }
    )
    if not storedHash or not VerifyPasswordHash(oldPassword, storedHash) then
        return false
    end

    -- Update to new hashed password
    local affected = MySQL.update.await(
        "UPDATE phone_mail_accounts SET password = ? WHERE address = ?",
        { GetPasswordHash(newPassword), account }
    )
    if affected <= 0 then
        return false
    end

    -- Notify all other active sessions about the forced logout
    NotifyLoggedInAccounts("Mail", account, {
        title   = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
        content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    }, { player })

    -- Remove all other login sessions for this account
    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Mail' AND phone_number != ?",
        { account, player }
    )

    ClearActiveAccountsCache("Mail", account, player)

    Log("Mail", src, "info",
        L("BACKEND.LOGS.CHANGED_PASSWORD.TITLE"),
        L("BACKEND.LOGS.CHANGED_PASSWORD.DESCRIPTION", {
            number   = player,
            username = account,
            app      = "Mail",
        })
    )

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = account,
        app      = "mail",
        reason   = "password",
        number   = player,
    })

    return true
end, false)

-- Callback: delete Mail account after verifying password
RegisterMailCallback("deleteAccount", function(src, player, account, password)
    -- Check feature enabled in config
    if not Config.DeleteAccount.Mail then
        infoprint("warning", ("%s tried to delete their account on Mail, but it's not enabled in the config."):format(src))
        return false
    end

    -- Verify password before allowing deletion
    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_mail_accounts WHERE address = ?",
        { account }
    )
    if not storedHash or not VerifyPasswordHash(password, storedHash) then
        return false
    end

    local affected = MySQL.update.await(
        "DELETE FROM phone_mail_accounts WHERE address = ?",
        { account }
    )
    if affected <= 0 then
        return false
    end

    -- Notify active sessions of deletion
    NotifyLoggedInAccounts("Mail", account, {
        title   = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
        content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"),
    })

    -- Clean up login records and cache
    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Mail'",
        { account }
    )
    ClearActiveAccountsCache("Mail", account)

    Log("Mail", src, "info",
        L("BACKEND.LOGS.DELETED_ACCOUNT.TITLE"),
        L("BACKEND.LOGS.DELETED_ACCOUNT.DESCRIPTION", {
            number   = player,
            username = account,
            app      = "Mail",
        })
    )

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = account,
        app      = "mail",
        reason   = "deleted",
    })

    return true
end, false)

-- Callback: login to Mail with address and password
BaseCallback("mail:login", function(src, player, address, password)
    local storedHash = MySQL.scalar.await(
        "SELECT `password` FROM phone_mail_accounts WHERE address=?",
        { address }
    )
    if not storedHash then
        return { success = false, error = "Invalid address" }
    end

    if not VerifyPasswordHash(password, storedHash) then
        return { success = false, error = "Invalid password" }
    end

    AddLoggedInAccount(player, "Mail", address)
    return { success = true }
end, { success = false, error = "No phone equipped" })

-- Callback: logout from Mail
RegisterMailCallback("logout", function(src, player, account)
    RemoveLoggedInAccount(player, "Mail", account)
    return { success = true }
end, { success = false, error = "Not logged in" })

-- Internal: push a new mail event/notification to relevant clients
local function DispatchMailToClients(mailData)
    if mailData.to == "all" then
        TriggerClientEvent("phone:mail:newMail", -1, mailData)
        return
    end

    -- Trigger event on each player who has this account logged in
    local loggedInNumbers = GetLoggedInNumbers("Mail", mailData.to)
    for _, number in ipairs(loggedInNumbers) do
        local playerSrc = GetSourceFromNumber(number)
        if playerSrc then
            TriggerClientEvent("phone:mail:newMail", playerSrc, mailData)
        end
    end

    -- Send push notification; use first attachment as thumbnail if available
    NotifyPhones(loggedInNumbers, {
        app       = "Mail",
        title     = mailData.sender,
        content   = mailData.subject,
        thumbnail = mailData.attachments and mailData.attachments[1],
    })
end

-- Internal: validate, persist, and dispatch a mail message.
-- Returns: success (bool), insertId (number)
local SendMail
SendMail = function(mailData)
    -- Validate recipient: must be "all" or an existing address
    if mailData.to then
        if mailData.to ~= "all" then
            local recipientExists = MySQL.scalar.await(
                "SELECT 1 FROM phone_mail_accounts WHERE address = ?",
                { mailData.to }
            )
            if not recipientExists then
                return false, "Invalid address"
            end
        end
    else
        return false, "Invalid address"
    end

    -- Optionally convert HTML message body to Markdown
    if Config.ConvertMailToMarkdown and ConvertHTMLToMarkdown then
        mailData.message = ConvertHTMLToMarkdown(mailData.message)
    end

    -- Default to empty arrays so JSON encoding is clean
    if not mailData.attachments then mailData.attachments = {} end
    if not mailData.actions     then mailData.actions     = {} end

    local attachmentsJson = (#mailData.attachments > 0) and json.encode(mailData.attachments) or nil
    local actionsJson     = (#mailData.actions     > 0) and json.encode(mailData.actions)     or nil

    local insertId = MySQL.insert.await(
        "INSERT INTO phone_mail_messages (recipient, sender, subject, content, attachments, actions) VALUES (@recipient, @sender, @subject, @content, @attachments, @actions)",
        {
            ["@recipient"]   = mailData.to,
            ["@sender"]      = mailData.sender  or "system",
            ["@subject"]     = mailData.subject or "System mail",
            ["@content"]     = mailData.message or "",
            ["@attachments"] = attachmentsJson,
            ["@actions"]     = actionsJson,
        }
    )

    -- Build the canonical mail object for dispatch and events
    local dispatchedMail = {
        id          = insertId,
        to          = mailData.to,
        sender      = mailData.sender  or "System",
        subject     = mailData.subject or "System mail",
        message     = mailData.message or "",
        attachments = mailData.attachments,
        actions     = mailData.actions,
        read        = false,
        timestamp   = os.time() * 1000,
    }

    TriggerEvent("lb-phone:mail:mailSent", dispatchedMail)
    DispatchMailToClients(dispatchedMail)

    return true, insertId
end

exports("SendMail", SendMail)

-- Export: hard-delete a mail message by ID (affects all recipients)
exports("DeleteMail", function(mailId)
    local affected = MySQL.Sync.execute(
        "DELETE FROM phone_mail_messages WHERE id=@id",
        { ["@id"] = mailId }
    )
    local deleted = affected > 0
    if deleted then
        TriggerClientEvent("phone:mail:mailDeleted", -1, mailId)
    end
    return deleted
end)

-- Callback: player sends a mail (blocks broadcast, enforces blacklist)
RegisterMailCallback("sendMail", function(src, player, account, mailData)
    -- Prevent players from broadcasting to "all"
    if mailData.to == "all" then
        return false
    end

    local to          = mailData.to
    local subject     = mailData.subject
    local message     = mailData.message
    local attachments = mailData.attachments

    -- All fields required; attachments must be a table
    if not (to and subject and message and type(attachments) == "table") then
        return false
    end

    -- Block blacklisted words in subject or body
    if ContainsBlacklistedWord(src, "Mail", subject) or
       ContainsBlacklistedWord(src, "Mail", message) then
        return false
    end

    local ok, insertId = SendMail({
        to          = to,
        sender      = account,
        subject     = subject,
        message     = message,
        attachments = attachments,
    })
    if not ok then
        return false
    end

    Log("Mail", src, "info",
        L("BACKEND.LOGS.MAIL_TITLE"),
        L("BACKEND.LOGS.NEW_MAIL", { sender = account, recipient = to })
    )

    return insertId
end, false)

-- Callback: fetch paginated/searchable mail list for the logged-in account
RegisterMailCallback("getMails", function(src, player, account, options)
    local lastId = options and options.lastId or nil
    local search = nil

    -- Build LIKE pattern only when the search string is non-empty
    if options and options.search and #options.search > 0 then
        search = "%" .. options.search .. "%"
    end

    local params = { account, account }

    -- Base query; optional clauses injected via gsub
    local query = [[
        SELECT
            m.id,
            m.recipient AS `to`,
            m.sender,
            m.`subject`,
            LEFT(m.content, 70) AS message,
            m.`read`,
            m.`timestamp`
        FROM phone_mail_messages m
        WHERE (
            recipient=?
            OR recipient="all"
            OR sender=?
        ) {EXCLUDE_DELETED} {SEARCH} {PAGINATION}
        ORDER BY `id` DESC
        LIMIT 10
    ]]

    -- Soft-delete exclusion clause
    if Config.DeleteMail then
        query = query:gsub("{EXCLUDE_DELETED}", [[
            AND NOT EXISTS (
                SELECT 1 FROM phone_mail_deleted d
                WHERE d.message_id = m.id AND d.address = ?
            )
        ]])
        params[#params + 1] = account
    else
        query = query:gsub("{EXCLUDE_DELETED}", "")
    end

    -- Full-text search across recipient, sender, subject, and content
    if search then
        query = query:gsub("{SEARCH}", [[
            AND (
                m.recipient LIKE ? OR m.sender LIKE ?
                OR m.subject LIKE ? OR m.content LIKE ?
            )
        ]])
        params[#params + 1] = search
        params[#params + 1] = search
        params[#params + 1] = search
        params[#params + 1] = search
    else
        query = query:gsub("{SEARCH}", "")
    end

    -- Keyset pagination: only return IDs before lastId
    if lastId then
        query = query:gsub("{PAGINATION}", "AND m.id < ?")
        params[#params + 1] = lastId
    else
        query = query:gsub("{PAGINATION}", "")
    end

    return MySQL.query.await(query, params)
end, {})

-- Callback: fetch a single mail by ID and mark it as read
RegisterMailCallback("getMail", function(src, player, account, mailId)
    local mail = MySQL.single.await([[
        SELECT
            id, recipient AS `to`, sender, subject,
            content as message, attachments, `read`, `timestamp`, actions
        FROM phone_mail_messages
        WHERE (
            recipient=@address OR recipient="all" OR sender=@address
        ) AND id=@id
    ]], { ["@address"] = account, ["@id"] = mailId })

    if not mail then
        return false
    end

    -- Mark as read; skip if the player is the sender
    if not mail.read then
        MySQL.update(
            "UPDATE phone_mail_messages SET `read`=1 WHERE id=? AND sender != ?",
            { mailId, account }
        )
    end

    return mail
end)

-- Callback: soft-delete a mail for the current account only
RegisterMailCallback("deleteMail", function(src, player, account, mailId)
    if not Config.DeleteMail then
        return
    end

    MySQL.update.await(
        "INSERT IGNORE INTO phone_mail_deleted (message_id, address) VALUES (?, ?)",
        { mailId, account }
    )
    return true
end)

-- Auto-create a Mail account when a player first connects with a phone.
-- Sends a welcome mail containing the generated credentials.
function GenerateEmailAccount(src, phoneNumber)
    if not Config.AutoCreateEmail or not phoneNumber then
        return
    end

    -- Derive a base username from the character's name (alphanumeric only)
    local firstName, lastName = GetCharacterName(src)
    firstName = firstName:gsub("[^%w]", "")
    lastName  = lastName:gsub("[^%w]",  "")

    if #firstName == 0 then firstName = GenerateString(5) end
    if #lastName  == 0 then lastName  = GenerateString(5) end

    local baseLocal   = firstName .. "." .. lastName
    local emailDomain = Config.EmailDomain

    -- Append a numeric suffix if the base name is already in use
    local count = MySQL.scalar.await(
        "SELECT COUNT(1) FROM phone_mail_accounts WHERE address LIKE ?",
        { baseLocal .. "%" }
    ) or 0

    if count > 0 then
        baseLocal = baseLocal .. (count + 1)
    end

    local address = (baseLocal .. "@" .. emailDomain):lower()

    -- Retry with random 4-digit suffix if still taken (up to 50 attempts)
    local taken    = MySQL.scalar.await("SELECT 1 FROM phone_mail_accounts WHERE address=?", { address })
    local attempts = 0
    while taken and attempts < 50 do
        address  = (firstName .. "." .. lastName .. math.random(1000, 9999) .. "@" .. emailDomain):lower()
        taken    = MySQL.scalar.await("SELECT 1 FROM phone_mail_accounts WHERE address=?", { address })
        attempts = attempts + 1
        Wait(0)
    end

    if taken then
        debugprint("Failed to generate address for", src)
        return
    end

    -- Register the account with a random temporary password
    local generatedPassword = GenerateString(5)
    local ok = CreateMailAccount(address, generatedPassword)
    if not ok then
        return
    end

    AddLoggedInAccount(phoneNumber, "Mail", address)

    -- Send welcome mail with the auto-generated credentials
    SendMail({
        to      = address,
        sender  = L("BACKEND.MAIL.AUTOMATIC_PASSWORD.SENDER"),
        subject = L("BACKEND.MAIL.AUTOMATIC_PASSWORD.SUBJECT"),
        message = L("BACKEND.MAIL.AUTOMATIC_PASSWORD.MESSAGE", {
            address  = address,
            password = generatedPassword,
        }),
    })
end