---Adds a transaction to the wallet app and sends a notification
---@param phoneNumber string
---@param amount number
---@param company string
---@param logo? string
function AddTransaction(phoneNumber, amount, company, logo)
    if not phoneNumber or not amount or not company then
        return
    end

    if #company > 50 then
        company = company:sub(1, 47) .. "..."
    end

    MySQL.insert.await("INSERT INTO phone_wallet_transactions (phone_number, amount, company, logo) VALUES (@phoneNumber, @amount, @company, @logo)", {
        ["@phoneNumber"] = phoneNumber,
        ["@amount"] = amount,
        ["@company"] = company,
        ["@logo"] = logo
    })

    local source = GetSourceFromNumber(phoneNumber)
    local content = (amount < 0 and "-" or "") .. Config.CurrencyFormat:format(SeperateNumber(math.abs(amount)))

    SendNotification(phoneNumber, {
        app = "Wallet",
        title = company,
        content = content,
        thumbnail = logo
    })

    TriggerEvent("lb-phone:onAddTransaction", amount > 0 and "received" or "paid", phoneNumber, amount, company, logo)

    Log("Wallet", source or nil, amount > 0 and "success" or "error", L("BACKEND.LOGS." .. (amount > 0 and "RECEIVED" or "PAID") .. "_TITLE", { amount = math.abs(amount) }), L("BACKEND.LOGS.TRANSACTION", {
        number = FormatNumber(phoneNumber),
        amount = amount,
        company = company
    }), logo)

    if not source then
        return
    end

    TriggerClientEvent("phone:wallet:addTransaction", source, {
        amount = amount,
        company = company,
        logo = logo,
        timestamp = os.time()
    })
end

exports("AddTransaction", AddTransaction)

---@param phoneNumber string
---@param page? number
---@param perPage? number
local function GetTransactions(phoneNumber, page, perPage)
    page = math.max(page or 0, 0)
    perPage = math.max(perPage or 5, 1)

    return MySQL.query.await([[
        SELECT amount, company, logo, `timestamp`
        FROM phone_wallet_transactions
        WHERE phone_number = ?

        ORDER BY `timestamp` DESC

        LIMIT ?, ?
    ]], { phoneNumber, (page or 0) * perPage, perPage })
end

BaseCallback("wallet:getBalance", function(source, phoneNumber)
    return GetBalance(source)
end)

---@param page number
---@param recent? true
BaseCallback("wallet:getTransactions", function(source, phoneNumber, page, recent)
    return GetTransactions(phoneNumber, page, recent and 5 or 25)
end)

BaseCallback("wallet:doesNumberExist", function(source, phoneNumber, number)
    local sourceFromNumber = GetSourceFromNumber(number)

    if sourceFromNumber then
        return true
    end

    if Config.TransferOffline then
        return MySQL.scalar.await("SELECT 1 FROM phone_phones WHERE phone_number = ?", { number }) == 1
    end
end, false)

---@param data { amount: number, phoneNumber: string }
BaseCallback("wallet:sendPayment", function(source, phoneNumber, data)
    -- Fallback: resolve phone number from DB if BaseCallback didn't get it
    if not phoneNumber then
        phoneNumber = MySQL.scalar.await("SELECT phone_number FROM phone_phones WHERE owner_id = ?", { GetIdentifier(source) })
    end

    if not phoneNumber then
        debugprint("wallet:sendPayment: could not resolve phone number for source", source)
        return { success = false, reason = "UNKNOWN_ERROR" }
    end

    amount = tonumber(data.amount)

    if not amount or amount <= 0 then
        return { success = false, reason = "INVALID_AMOUNT" }
    end

    if GetBalance(source) < amount then
        return { success = false, reason = "INSUFFICIENT_FUNDS" }
    end

    if type(Config.TransferLimits.Daily) == "number" and Config.TransferLimits.Daily > 0 then
        local spentToday = MySQL.scalar.await("SELECT -SUM(amount) FROM phone_wallet_transactions WHERE phone_number = ? AND amount < 0 AND `timestamp` > DATE_SUB(NOW(), INTERVAL 1 DAY)", { phoneNumber }) or 0

        if spentToday + amount > Config.TransferLimits.Daily then
            return { success = false, reason = "EXCEED_DAILY" }
        end
    elseif Config.TransferLimits?.Daily then
        infoprint("error", "TransferLimits.Daily must be a number and greater than 0, or false.")
    end

    if type(Config.TransferLimits.Weekly) == "number" and Config.TransferLimits.Weekly > 0 then
        local spentWeek = MySQL.scalar.await("SELECT -SUM(amount) FROM phone_wallet_transactions WHERE phone_number = ? AND amount < 0 AND `timestamp` > DATE_SUB(NOW(), INTERVAL 7 DAY)", { phoneNumber }) or 0

        if spentWeek + amount > Config.TransferLimits.Weekly then
            return { success = false, reason = "EXCEED_WEEKLY" }
        end
    elseif Config.TransferLimits?.Weekly then
        infoprint("error", "TransferLimits.Weekly must be a number and greater than 0, or false.")
    end

    local sendToSource = GetSourceFromNumber(data.phoneNumber)
    local added = false

    if sendToSource then
        if sendToSource ~= source then
            added = AddMoney(sendToSource, amount)
        else
            debugprint("Can't send money to yourself (source).", source, sendToSource)
        end
    elseif Config.TransferOffline then
        local identifier = GetIdentifier(source)
        local sendToIdentifier = MySQL.scalar.await("SELECT owner_id FROM phone_phones WHERE phone_number = ?", { data.phoneNumber })

        if sendToIdentifier and sendToIdentifier ~= identifier then
            added = AddMoneyOffline and AddMoneyOffline(sendToIdentifier, amount)
        elseif sendToIdentifier == identifier then
            debugprint("Can't send money to yourself (identifier).", identifier, sendToIdentifier)
        end
    end

    if not added then
        debugprint("wallet:sendPayment FAILED_ADD - sendToSource:", sendToSource, "source:", source, "amount:", amount, "recipient:", data.phoneNumber)
        return { success = false, reason = "FAILED_ADD" }
    end

    RemoveMoney(source, amount)

    -- Send payment notification message directly via SQL (bypassing broken export asserts)
    local content = "<!SENT-PAYMENT-" .. amount .. "!>"
    local channelId = MySQL.scalar.await([[
        SELECT c.id FROM phone_message_channels c
        WHERE c.is_group = 0
            AND EXISTS (SELECT TRUE FROM phone_message_members m WHERE m.channel_id = c.id AND m.phone_number = ?)
            AND EXISTS (SELECT TRUE FROM phone_message_members m WHERE m.channel_id = c.id AND m.phone_number = ?)
    ]], { phoneNumber, data.phoneNumber })

    if not channelId then
        channelId = MySQL.insert.await("INSERT INTO phone_message_channels (is_group) VALUES (0)")
        MySQL.update.await(
            "INSERT IGNORE INTO phone_message_members (channel_id, phone_number) VALUES (?, ?), (?, ?)",
            { channelId, phoneNumber, channelId, data.phoneNumber }
        )
    end

    local messageId = MySQL.insert.await(
        "INSERT INTO phone_message_messages (channel_id, sender, content) VALUES (?, ?, ?)",
        { channelId, phoneNumber, content }
    )

    -- Update channel last_message preview and unread count for recipient
    MySQL.update(
        "UPDATE phone_message_channels SET last_message = ? WHERE id = ?",
        { string.sub(content, 1, 50), channelId }
    )
    MySQL.update(
        "UPDATE phone_message_members SET unread = unread + 1 WHERE channel_id = ? AND phone_number != ?",
        { channelId, phoneNumber }
    )

    -- Notify recipient's UI (correct individual-arg signature)
    local recipientSrc = GetSourceFromNumber(data.phoneNumber)
    if recipientSrc then
        TriggerClientEvent("phone:messages:newMessage", recipientSrc,
            channelId, messageId, phoneNumber, content, nil)
    end

    -- NOTE: We do NOT notify the sender here — the React UI already optimistically
    -- renders the sent payment message when sendPayment returns success.

    -- Log transactions (skip contact lookup if phoneNumber is nil to avoid SQL errors)
    if phoneNumber then
        AddTransaction(phoneNumber, -amount, data.phoneNumber)
    end

    if data.phoneNumber then
        AddTransaction(data.phoneNumber, amount, phoneNumber or "Unknown")
    end

    return { success = true }
end, nil, {
    defaultReturn = { success = false, reason = "UNKNOWN_ERROR" },
    preventSpam = true,
})
