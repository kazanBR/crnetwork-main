-- Cache of logged-in player accounts: { [playerId] = accountData }
local loggedInAccounts = {}

-- Helper: wraps a callback with phone number authentication verification.
-- Ensures the calling player's phone number matches the expected number before invoking the real handler.
local function AuthenticatedCallback(callbackName, handler, defaultReturn)
    BaseCallback("spark:" .. callbackName, function(playerId, phoneNumber, ...)
        local account = loggedInAccounts[playerId]

        if account and account.phoneNumber == phoneNumber then
            return handler(playerId, phoneNumber, account, ...)
        end

        return defaultReturn
    end, defaultReturn)
end

-- =====================================================
-- spark:createAccount
-- Creates a new Spark account for the given phone number.
-- Returns false if the account already exists, true on success.
-- =====================================================
BaseCallback("spark:createAccount", function(playerId, phoneNumber, accountData)
    -- Check if account already exists
    local exists = MySQL.scalar.await(
        "SELECT TRUE FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if exists then
        return false
    end

    -- Insert new account
    local query = [[
        INSERT INTO phone_tinder_accounts
            (`name`, phone_number, photos, bio, dob, is_male, interested_men, interested_women)
        VALUES
            (@name, @phoneNumber, @photos, @bio, @dob, @isMale, @showMen, @showWomen)
    ]]

    local rows = MySQL.update.await(query, {
        name        = accountData.name,
        phoneNumber = phoneNumber,
        photos      = json.encode(accountData.photos),
        bio         = accountData.bio,
        dob         = accountData.dob,
        isMale      = accountData.isMale,
        showMen     = accountData.showMen,
        showWomen   = accountData.showWomen,
    })

    return rows > 0
end, false)

-- =====================================================
-- spark:deleteAccount
-- Deletes a player's Spark account and all associated data.
-- Respects the Config.DeleteAccount.Spark toggle.
-- =====================================================
BaseCallback("spark:deleteAccount", function(playerId, phoneNumber)
    if not Config.DeleteAccount.Spark then
        infoprint("warning", string.format(
            "%s tried to delete their spark account, but it's not enabled in the config.",
            playerId
        ))
        return false
    end

    -- Remove the account row
    local deleted = MySQL.update.await(
        "DELETE FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if not (deleted > 0) then
        return false
    end

    -- Remove swipes
    MySQL.update(
        "DELETE FROM phone_tinder_swipes WHERE swiper = ? OR swipee = ?",
        { phoneNumber, phoneNumber }
    )

    -- Remove matches
    MySQL.update(
        "DELETE FROM phone_tinder_matches WHERE phone_number_1 = ? OR phone_number_2 = ?",
        { phoneNumber, phoneNumber }
    )

    -- Remove messages
    MySQL.update(
        "DELETE FROM phone_tinder_messages WHERE sender = ? OR recipient = ?",
        { phoneNumber, phoneNumber }
    )

    return true
end)

-- =====================================================
-- spark:updateAccount (authenticated)
-- Updates the player's Spark profile fields.
-- Merges incoming updates onto existing account data.
-- =====================================================
AuthenticatedCallback("updateAccount", function(playerId, phoneNumber, account, updates)
    -- Merge updates into the local cached account
    for key in pairs(account) do
        if updates[key] ~= nil then
            account[key] = updates[key]
        end
    end

    local query = [[
        UPDATE phone_tinder_accounts
        SET
            `name`=@name,
            photos=@photos,
            bio=@bio,
            is_male=@isMale,
            interested_men=@showMen,
            interested_women=@showWomen,
            `active`=@active
        WHERE phone_number=@phoneNumber
    ]]

    local rows = MySQL.update.await(query, {
        name        = updates.name,
        photos      = json.encode(updates.photos),
        bio         = updates.bio,
        isMale      = updates.isMale,
        showMen     = updates.showMen,
        showWomen   = updates.showWomen,
        active      = updates.active,
        phoneNumber = phoneNumber,
    })

    return rows > 0
end, false)

-- =====================================================
-- spark:isLoggedIn
-- Returns cached account data if logged in, otherwise
-- fetches from the database and caches it.
-- =====================================================
BaseCallback("spark:isLoggedIn", function(playerId, phoneNumber)
    local cached = loggedInAccounts[playerId]

    if cached and cached.phoneNumber == phoneNumber then
        return cached
    end

    -- Fetch from DB
    local row = MySQL.single.await(
        "SELECT `name`, photos, bio, dob, is_male, interested_men, interested_women, `active` FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if not row then
        return nil
    end

    -- Update last seen timestamp
    MySQL.update.await(
        "UPDATE phone_tinder_accounts SET last_seen = NOW() WHERE phone_number = ?",
        { phoneNumber }
    )

    -- Build and cache account object
    loggedInAccounts[playerId] = {
        phoneNumber = phoneNumber,
        name        = row.name,
        photos      = json.decode(row.photos),
        bio         = row.bio,
        dob         = row.dob,
        isMale      = row.is_male,
        showMen     = row.interested_men,
        showWomen   = row.interested_women,
        active      = row.active,
    }

    return loggedInAccounts[playerId]
end, false)

-- =====================================================
-- spark:getFeed
-- Returns a paginated list of potential matches for the player.
-- Page 0 = first 10, page 1 = next 10, etc.
-- =====================================================
BaseCallback("spark:getFeed", function(playerId, phoneNumber, page)
    local query = [[
        SELECT
            a.`name`, a.phone_number, a.photos, a.bio, a.dob
        FROM
            phone_tinder_accounts a

        JOIN
            phone_tinder_accounts b ON b.phone_number = @phoneNumber

        WHERE
            a.phone_number != @phoneNumber
            AND a.`active` = 1
            AND (a.is_male = b.interested_men OR a.is_male=(NOT b.interested_women))
            AND (a.interested_men=b.is_male OR a.interested_women=(NOT b.is_male))
            AND NOT EXISTS (SELECT TRUE FROM phone_tinder_swipes WHERE swiper = @phoneNumber AND swipee = a.phone_number)

        ORDER BY a.phone_number
        LIMIT @page, @perPage
    ]]

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        page        = (page or 0) * 10,
        perPage     = 10,
    })
end, {})

-- =====================================================
-- spark:swipe (authenticated)
-- Records a swipe. If both players liked each other, creates
-- a match and sends the swiped player a notification.
-- =====================================================
AuthenticatedCallback("swipe", function(playerId, phoneNumber, account, swipeeNumber, liked)
    -- Record the swipe (upsert in case they change their mind)
    local result = MySQL.query.await(
        "INSERT INTO phone_tinder_swipes (swiper, swipee, liked) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE liked = ?",
        { phoneNumber, swipeeNumber, liked, liked }
    )

    if result == 0 or not liked then
        return false
    end

    -- Check if the other person already liked us back
    local theyLikedUs = MySQL.scalar.await(
        "SELECT liked FROM phone_tinder_swipes WHERE swiper = ? AND swipee = ?",
        { swipeeNumber, phoneNumber }
    )

    if theyLikedUs ~= true then
        return false
    end

    -- It's a match! Insert the match record
    MySQL.update.await(
        "INSERT INTO phone_tinder_matches (phone_number_1, phone_number_2) VALUES (?, ?)",
        { phoneNumber, swipeeNumber }
    )

    -- Notify the matched player
    SendNotification(swipeeNumber, {
        app       = "Tinder",
        title     = L("BACKEND.TINDER.NEW_MATCH"),
        content   = L("BACKEND.TINDER.MATCHED_WITH", { name = account.name }),
        thumbnail = account.photos[1],
    })

    return true
end)

-- =====================================================
-- spark:getNewMatchesCount
-- Returns the number of new (unread/no-message) matches.
-- =====================================================
BaseCallback("spark:getNewMatchesCount", function(playerId, phoneNumber)
    local query = [[
        SELECT COUNT(*) FROM phone_tinder_matches
        WHERE
            (phone_number_1 = @phoneNumber OR phone_number_2 = @phoneNumber)
            AND latest_message IS NULL
    ]]

    local count = MySQL.scalar.await(query, { phoneNumber = phoneNumber })
    return count or 0
end)

-- =====================================================
-- spark:getMatches
-- Returns paginated matches. Pass hasMessages=true for
-- conversations, false for new (un-messaged) matches.
-- =====================================================
BaseCallback("spark:getMatches", function(playerId, phoneNumber, hasMessages, page)
    local messageFilter = hasMessages and "IS NOT NULL" or "IS NULL"

    local query = ([[
        SELECT
            `account`.`name`,
            `account`.phone_number,
            `account`.photos,
            `account`.dob,
            `account`.bio,
            `account`.is_male,

            `match`.latest_sender,
            `match`.latest_message,
            `match`.latest_message_timestamp,

            CASE
                WHEN `match`.phone_number_1 = @phoneNumber THEN `match`.phone_number_1_has_unread
                ELSE `match`.phone_number_2_has_unread
            END as unread
        FROM
            phone_tinder_accounts `account`

        JOIN phone_tinder_matches `match`
        ON
            (`match`.phone_number_1 = @phoneNumber AND `match`.phone_number_2 = `account`.phone_number)
            OR (`match`.phone_number_2 = @phoneNumber AND `match`.phone_number_1 = `account`.phone_number)

        WHERE latest_message {MESSAGES}

        ORDER BY `match`.latest_message_timestamp DESC
        LIMIT @page, @perPage
    ]]):gsub("{MESSAGES}", messageFilter)

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        page        = (page or 0) * 25,
        perPage     = 25,
    })
end)

-- =====================================================
-- spark:sendMessage (authenticated)
-- Sends a message to a matched user. Checks for blacklisted
-- words, updates match preview, and notifies the recipient.
-- =====================================================
AuthenticatedCallback("sendMessage", function(playerId, phoneNumber, account, recipientNumber, content, attachments)
    -- Blacklist check
    if ContainsBlacklistedWord(playerId, "Spark", content) then
        return false
    end

    -- Insert message row
    local insertId = MySQL.insert.await(
        "INSERT INTO phone_tinder_messages (sender, recipient, content, attachments) VALUES (?, ?, ?, ?)",
        { phoneNumber, recipientNumber, content, json.encode(attachments) }
    )

    if not insertId then
        return false
    end

    -- Update the match's latest message preview
    MySQL.update([[
        UPDATE phone_tinder_matches
        SET
            latest_message = @content,
            latest_sender = @sender,
            latest_message_timestamp = CURRENT_TIMESTAMP,
            phone_number_1_has_unread = CASE WHEN phone_number_1 = @recipient THEN 1 ELSE 0 END,
            phone_number_2_has_unread = CASE WHEN phone_number_2 = @recipient THEN 1 ELSE 0 END
        WHERE
            (phone_number_1 = @sender AND phone_number_2 = @recipient)
            OR (phone_number_2 = @sender AND phone_number_1 = @recipient)
    ]], {
        content   = content,
        sender    = phoneNumber,
        recipient = recipientNumber,
    })

    -- Trigger real-time event if recipient is online
    local recipientSource = GetSourceFromNumber(recipientNumber)
    if recipientSource then
        TriggerClientEvent("phone:spark:newMessage", recipientSource, {
            sender      = phoneNumber,
            recipient   = recipientNumber,
            content     = content,
            attachments = attachments,
            timestamp   = os.time() * 1000,
        })
    end

    -- Send push notification
    SendNotification(recipientNumber, {
        app        = "Tinder",
        title      = account.name,
        content    = content,
        thumbnail  = attachments and attachments[1] or nil,
        avatar     = account.photos[1],
        showAvatar = true,
    })

    return insertId
end)

-- =====================================================
-- spark:getMessages
-- Returns up to 25 messages in a conversation.
-- If lastId is provided, fetches older messages (pagination).
-- Also marks messages as read unless lastId is provided.
-- =====================================================
BaseCallback("spark:getMessages", function(playerId, phoneNumber, otherNumber, lastId)
    -- Mark as read when loading fresh (not paginating)
    if not lastId then
        MySQL.update([[
            UPDATE phone_tinder_matches
            SET
                phone_number_1_has_unread = CASE WHEN phone_number_1 = @phoneNumber THEN 0 ELSE phone_number_1_has_unread END,
                phone_number_2_has_unread = CASE WHEN phone_number_2 = @phoneNumber THEN 0 ELSE phone_number_2_has_unread END
            WHERE
                (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
                OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
        ]], {
            phoneNumber = phoneNumber,
            number      = otherNumber,
        })
    end

    -- Build query with optional cursor pagination
    local paginationClause = lastId and "AND id < @lastId" or ""
    local query = ([[
        SELECT id, sender, recipient, content, attachments, timestamp
        FROM phone_tinder_messages
        WHERE
            (
                (sender = @phoneNumber AND recipient = @number)
                OR (recipient = @phoneNumber AND sender = @number)
            ) {PAGINATION}
        ORDER BY id DESC
        LIMIT 25
    ]]):gsub("{PAGINATION}", paginationClause)

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        number      = otherNumber,
        lastId      = lastId,
    })
end)

-- =====================================================
-- spark:markAsRead
-- Clears the unread flag for the current player in a match.
-- =====================================================
BaseCallback("spark:markAsRead", function(playerId, phoneNumber, otherNumber)
    MySQL.update([[
        UPDATE phone_tinder_matches
        SET
            phone_number_1_has_unread = CASE WHEN phone_number_1 = @phoneNumber THEN 0 ELSE phone_number_1_has_unread END,
            phone_number_2_has_unread = CASE WHEN phone_number_2 = @phoneNumber THEN 0 ELSE phone_number_2_has_unread END
        WHERE
            (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
            OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
    ]], {
        phoneNumber = phoneNumber,
        number      = otherNumber,
    })
end)

-- =====================================================
-- Auto-disable inactive Spark accounts
-- Runs every hour. Disables accounts not seen within
-- Config.AutoDisableSparkAccounts days (default: 7).
-- =====================================================
CreateThread(function()
    if not Config.AutoDisableSparkAccounts then
        return
    end

    local checkIntervalMs = 3600000 -- 1 hour
    local inactiveDays    = 7

    -- Allow config to override the inactivity threshold
    if type(Config.AutoDisableSparkAccounts) == "number" then
        inactiveDays = math.max(Config.AutoDisableSparkAccounts, 1)
    end

    -- Wait for DB to be ready before starting the loop
    while not DatabaseCheckerFinished do
        Wait(500)
    end

    while true do
        MySQL.update(
            "UPDATE phone_tinder_accounts SET active = 0 WHERE active = 1 AND last_seen < NOW() - INTERVAL ? DAY",
            { inactiveDays },
            function(rowsAffected)
                debugprint("Disabled " .. rowsAffected .. " inactive Spark accounts.")
            end
        )

        Wait(checkIntervalMs)
    end
end)

-- =====================================================
-- playerDropped
-- Clears cached account data when a player disconnects.
-- =====================================================
AddEventHandler("playerDropped", function()
    local playerId = source
    loggedInAccounts[playerId] = nil
end)