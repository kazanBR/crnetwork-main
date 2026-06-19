-- =====================================================
--  lb-phone · server/apps/social/tinder.lua
--  Deobfuscated by Eazy Fxap
-- =====================================================

local loggedInAccounts = {}

local function SparkCallback(name, handler, defaultReturn)
    BaseCallback("spark:" .. name, function(source, phoneNumber, ...)
        local account = loggedInAccounts[source]

        if not account or account.phoneNumber ~= phoneNumber then
            return defaultReturn
        end

        return handler(source, phoneNumber, account, ...)
    end, defaultReturn)
end

BaseCallback("spark:createAccount", function(source, phoneNumber, data)
    local exists = MySQL.scalar.await(
        "SELECT TRUE FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if exists then
        return false
    end

    local affectedRows = MySQL.update.await([[
        INSERT INTO phone_tinder_accounts
            (`name`, phone_number, photos, bio, dob, is_male, interested_men, interested_women)
        VALUES
            (@name, @phoneNumber, @photos, @bio, @dob, @isMale, @showMen, @showWomen)
    ]], {
        name = data.name,
        phoneNumber = phoneNumber,
        photos = json.encode(data.photos),
        bio = data.bio,
        dob = data.dob,
        isMale = data.isMale,
        showMen = data.showMen,
        showWomen = data.showWomen
    })

    return affectedRows > 0
end, false)

BaseCallback("spark:deleteAccount", function(source, phoneNumber)
    if not Config.DeleteAccount.Spark then
        infoprint(
            "warning",
            ("%s tried to delete their spark account, but it's not enabled in the config."):format(source)
        )

        return false
    end

    local deleted = MySQL.update.await(
        "DELETE FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    ) > 0

    if not deleted then
        return false
    end

    MySQL.update("DELETE FROM phone_tinder_swipes WHERE swiper = ? OR swipee = ?", { phoneNumber, phoneNumber })
    MySQL.update("DELETE FROM phone_tinder_matches WHERE phone_number_1 = ? OR phone_number_2 = ?", { phoneNumber, phoneNumber })
    MySQL.update("DELETE FROM phone_tinder_messages WHERE sender = ? OR recipient = ?", { phoneNumber, phoneNumber })

    loggedInAccounts[source] = nil

    return true
end)

SparkCallback("updateAccount", function(source, phoneNumber, account, data)
    for key in pairs(account) do
        if data[key] ~= nil then
            account[key] = data[key]
        end
    end

    local affectedRows = MySQL.update.await([[
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
    ]], {
        name = account.name,
        photos = json.encode(account.photos),
        bio = account.bio,
        isMale = account.isMale,
        showMen = account.showMen,
        showWomen = account.showWomen,
        active = account.active,
        phoneNumber = phoneNumber
    })

    return affectedRows > 0
end, false)

BaseCallback("spark:isLoggedIn", function(source, phoneNumber)
    local cachedAccount = loggedInAccounts[source]

    if cachedAccount and cachedAccount.phoneNumber == phoneNumber then
        return cachedAccount
    end

    local account = MySQL.single.await(
        "SELECT `name`, photos, bio, dob, is_male, interested_men, interested_women, `active` FROM phone_tinder_accounts WHERE phone_number = ?",
        { phoneNumber }
    )

    if not account then
        return
    end

    MySQL.update.await(
        "UPDATE phone_tinder_accounts SET last_seen = NOW() WHERE phone_number = ?",
        { phoneNumber }
    )

    loggedInAccounts[source] = {
        phoneNumber = phoneNumber,
        name = account.name,
        photos = json.decode(account.photos),
        bio = account.bio,
        dob = account.dob,
        isMale = account.is_male,
        showMen = account.interested_men,
        showWomen = account.interested_women,
        active = account.active
    }

    return loggedInAccounts[source]
end, false)

BaseCallback("spark:getFeed", function(source, phoneNumber, page)
    return MySQL.query.await([[
        SELECT
            a.`name`, a.phone_number, a.photos, a.bio, a.dob
        FROM
            phone_tinder_accounts a

        JOIN
            phone_tinder_accounts b
        ON
            b.phone_number = @phoneNumber

        WHERE
            a.phone_number != @phoneNumber
            AND a.`active` = 1
            AND (a.is_male = b.interested_men OR a.is_male=(NOT b.interested_women))
            AND (a.interested_men=b.is_male OR a.interested_women=(NOT b.is_male))
            AND NOT EXISTS (SELECT TRUE FROM phone_tinder_swipes WHERE swiper = @phoneNumber AND swipee = a.phone_number)

        ORDER BY a.phone_number

        LIMIT @page, @perPage
    ]], {
        phoneNumber = phoneNumber,
        page = (page or 0) * 10,
        perPage = 10
    })
end, {})

SparkCallback("swipe", function(source, phoneNumber, account, targetNumber, liked)
    local affectedRows = MySQL.update.await(
        "INSERT INTO phone_tinder_swipes (swiper, swipee, liked) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE liked = ?",
        { phoneNumber, targetNumber, liked, liked }
    )

    if affectedRows == 0 or not liked then
        return false
    end

    local likedBack = MySQL.scalar.await(
        "SELECT liked FROM phone_tinder_swipes WHERE swiper = ? AND swipee = ?",
        { targetNumber, phoneNumber }
    )

    if likedBack ~= true and likedBack ~= 1 then
        return false
    end

    local matchExists = MySQL.scalar.await([[
        SELECT TRUE
        FROM phone_tinder_matches
        WHERE
            (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
            OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
    ]], {
        phoneNumber = phoneNumber,
        number = targetNumber
    })

    if not matchExists then
        MySQL.update.await(
            "INSERT INTO phone_tinder_matches (phone_number_1, phone_number_2) VALUES (?, ?)",
            { phoneNumber, targetNumber }
        )

        SendNotification(targetNumber, {
            app = "Tinder",
            title = L("BACKEND.TINDER.NEW_MATCH"),
            content = L("BACKEND.TINDER.MATCHED_WITH", {
                name = account.name
            }),
            thumbnail = account.photos[1]
        })
    end

    return true
end)

BaseCallback("spark:getNewMatchesCount", function(source, phoneNumber)
    return MySQL.scalar.await([[
        SELECT COUNT(*) FROM phone_tinder_matches

        WHERE
            (
                (phone_number_1 = @phoneNumber)
                OR (phone_number_2 = @phoneNumber)
            )
            AND latest_message IS NULL
    ]], {
        phoneNumber = phoneNumber
    }) or 0
end)

BaseCallback("spark:getMatches", function(source, phoneNumber, hasMessages, page)
    local query = [[
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

        JOIN
            phone_tinder_matches `match`
        ON
            (
                `match`.phone_number_1 = @phoneNumber
                AND `match`.phone_number_2 = `account`.phone_number
            )
            OR
            (
                `match`.phone_number_2 = @phoneNumber
                AND `match`.phone_number_1 = `account`.phone_number
            )

        WHERE latest_message {MESSAGES}

        ORDER BY `match`.latest_message_timestamp DESC

        LIMIT @page, @perPage
    ]]

    query = query:gsub("{MESSAGES}", hasMessages and "IS NOT NULL" or "IS NULL")

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        page = (page or 0) * 25,
        perPage = 25
    })
end)

SparkCallback("sendMessage", function(source, phoneNumber, account, recipient, content, attachments)
    if ContainsBlacklistedWord(source, "Spark", content) then
        return false
    end

    local messageId = MySQL.insert.await(
        "INSERT INTO phone_tinder_messages (sender, recipient, content, attachments) VALUES (?, ?, ?, ?)",
        {
            phoneNumber,
            recipient,
            content,
            attachments and json.encode(attachments) or nil
        }
    )

    if not messageId then
        return false
    end

    MySQL.update([[
            UPDATE
                phone_tinder_matches
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
        content = content,
        sender = phoneNumber,
        recipient = recipient
    })

    local recipientSource = GetSourceFromNumber(recipient)

    if recipientSource then
        TriggerClientEvent("phone:spark:newMessage", recipientSource, {
            sender = phoneNumber,
            recipient = recipient,
            content = content,
            attachments = attachments,
            timestamp = os.time() * 1000
        })
    end

    SendNotification(recipient, {
        app = "Tinder",
        title = account.name,
        content = content,
        thumbnail = attachments and attachments[1] or nil,
        avatar = account.photos[1],
        showAvatar = true
    })

    return messageId
end)

BaseCallback("spark:getMessages", function(source, phoneNumber, number, lastId)
    if not lastId then
        MySQL.update([[
            UPDATE
                phone_tinder_matches
            SET
                phone_number_1_has_unread = CASE WHEN phone_number_1 = @phoneNumber THEN 0 ELSE phone_number_1_has_unread END,
                phone_number_2_has_unread = CASE WHEN phone_number_2 = @phoneNumber THEN 0 ELSE phone_number_2_has_unread END
            WHERE
                (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
                OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
        ]], {
            phoneNumber = phoneNumber,
            number = number
        })
    end

    local query = [[
        SELECT
            id,
            sender,
            recipient,
            content,
            attachments,
            timestamp

        FROM
            phone_tinder_messages

        WHERE
            (
                (sender = @phoneNumber AND recipient = @number)
                OR (recipient = @phoneNumber AND sender = @number)
            ) {PAGINATION}

        ORDER BY id DESC

        LIMIT 25
    ]]

    query = query:gsub("{PAGINATION}", lastId and "AND id < @lastId" or "")

    return MySQL.query.await(query, {
        phoneNumber = phoneNumber,
        number = number,
        lastId = lastId
    })
end)

BaseCallback("spark:markAsRead", function(source, phoneNumber, number)
    MySQL.update([[
        UPDATE
            phone_tinder_matches
        SET
            phone_number_1_has_unread = CASE WHEN phone_number_1 = @phoneNumber THEN 0 ELSE phone_number_1_has_unread END,
            phone_number_2_has_unread = CASE WHEN phone_number_2 = @phoneNumber THEN 0 ELSE phone_number_2_has_unread END
        WHERE
            (phone_number_1 = @phoneNumber AND phone_number_2 = @number)
            OR (phone_number_2 = @phoneNumber AND phone_number_1 = @number)
    ]], {
        phoneNumber = phoneNumber,
        number = number
    })
end)

CreateThread(function()
    if not Config.AutoDisableSparkAccounts then
        return
    end

    local interval = 3600000
    local days = 7

    if type(Config.AutoDisableSparkAccounts) == "number" then
        days = math.max(Config.AutoDisableSparkAccounts, 1)
    end

    while not DatabaseCheckerFinished do
        Wait(500)
    end

    while true do
        MySQL.update(
            "UPDATE phone_tinder_accounts SET active = 0 WHERE active = 1 AND last_seen < NOW() - INTERVAL ? DAY",
            { days },
            function(disabled)
                debugprint("Disabled " .. disabled .. " inactive Spark accounts.")
            end
        )

        Wait(interval)
    end
end)

AddEventHandler("playerDropped", function()
    loggedInAccounts[source] = nil
end)
