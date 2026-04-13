-- Active calls table: callId -> callData
local activeCalls = {}

-- Players who have disabled company calls: source -> true
local disabledCompanyCalls = {}

-- Generates a unique random call ID
local function GenerateCallId()
    local id = math.random(999999999)
    while activeCalls[id] do
        id = math.random(999999999)
    end
    return id
end

-- =====================================================
--  Contact Helpers
-- =====================================================

function GetContact(callerNumber, contactNumber, ownerNumber, callback)
    local params = { callerNumber, contactNumber, ownerNumber }
    local query = [[
        SELECT
            CONCAT(firstname, ' ', lastname) AS `name`, profile_image AS avatar, firstname, lastname, email, address, contact_phone_number AS `number`, favourite,
            (IF((SELECT TRUE FROM phone_phone_blocked_numbers b WHERE b.phone_number=? AND b.blocked_number=`number`), TRUE, FALSE)) AS blocked
        FROM
            phone_phone_contacts
        WHERE
            contact_phone_number=? AND phone_number=?
    ]]
    if callback then
        return MySQL.single(query, params, callback)
    else
        return MySQL.single.await(query, params)
    end
end

function CreateContact(phoneNumber, contact)
    if not contact then
        debugprint("CreateContact: contact is required", phoneNumber, contact)
        return false
    end
    if not contact.number then
        debugprint("CreateContact: contact.number is required", phoneNumber, contact)
        return false
    end

    local affected = MySQL.Sync.execute([[
        INSERT INTO phone_phone_contacts (contact_phone_number, firstname, lastname, profile_image, email, address, phone_number)
        VALUES (@contactNumber, @firstname, @lastname, @avatar, @email, @address, @phoneNumber)
        ON DUPLICATE KEY UPDATE firstname=@firstname, lastname=@lastname, profile_image=@avatar, email=@email, address=@address
    ]], {
        ["@contactNumber"] = contact.number,
        ["@firstname"]     = contact.firstname or contact.number,
        ["@lastname"]      = contact.lastname or "",
        ["@avatar"]        = contact.avatar,
        ["@email"]         = contact.email,
        ["@address"]       = contact.address,
        ["@phoneNumber"]   = phoneNumber,
    })

    return affected > 0
end

-- =====================================================
--  Contact Callbacks
-- =====================================================

BaseCallback("saveContact", function(source, phoneNumber, contact)
    return CreateContact(phoneNumber, contact)
end, false)

BaseCallback("getContacts", function(source, phoneNumber)
    return MySQL.query.await([[
        SELECT
            contact_phone_number AS number,
            firstname,
            lastname,
            profile_image AS avatar,
            favourite,
            IF(b.blocked_number IS NOT NULL, TRUE, FALSE) AS blocked
        FROM
            phone_phone_contacts c
        LEFT JOIN
            phone_phone_blocked_numbers b
            ON c.phone_number = b.phone_number AND c.contact_phone_number = b.blocked_number
        WHERE
            c.phone_number = ?
    ]], { phoneNumber })
end, {})

BaseCallback("toggleBlock", function(source, phoneNumber, targetNumber, shouldBlock)
    local query = shouldBlock
        and "INSERT INTO phone_phone_blocked_numbers (phone_number, blocked_number) VALUES (@phoneNumber, @number) ON DUPLICATE KEY UPDATE phone_number=@phoneNumber"
        or  "DELETE FROM phone_phone_blocked_numbers WHERE phone_number=@phoneNumber AND blocked_number=@number"
    MySQL.update.await(query, { ["@phoneNumber"] = phoneNumber, ["@number"] = targetNumber })
    return shouldBlock
end, false)

BaseCallback("toggleFavourite", function(source, phoneNumber, targetNumber, isFavourite)
    MySQL.update.await(
        "UPDATE phone_phone_contacts SET favourite=@favourite WHERE contact_phone_number=@number AND phone_number=@phoneNumber",
        { ["@phoneNumber"] = phoneNumber, ["@number"] = targetNumber, ["@favourite"] = isFavourite == true }
    )
    return true
end, false)

BaseCallback("removeContact", function(source, phoneNumber, targetNumber)
    MySQL.update.await(
        "DELETE FROM phone_phone_contacts WHERE contact_phone_number=? AND phone_number=?",
        { targetNumber, phoneNumber }
    )
    return true
end, false)

BaseCallback("updateContact", function(source, phoneNumber, contact)
    MySQL.update.await(
        "UPDATE phone_phone_contacts SET firstname=@firstname, lastname=@lastname, profile_image=@avatar, email=@email, address=@address, contact_phone_number=@newNumber WHERE contact_phone_number=@number AND phone_number=@phoneNumber",
        {
            ["@phoneNumber"] = phoneNumber,
            ["@number"]      = contact.oldNumber,
            ["@newNumber"]   = contact.number,
            ["@firstname"]   = contact.firstname,
            ["@lastname"]    = contact.lastname or "",
            ["@avatar"]      = contact.avatar,
            ["@email"]       = contact.email,
            ["@address"]     = contact.address,
        }
    )
    return true
end, false)

-- =====================================================
--  Call History
-- =====================================================

BaseCallback("getRecentCalls", function(source, phoneNumber, missedOnly, beforeId)
    missedOnly = missedOnly == true
    local params = { phoneNumber, phoneNumber, phoneNumber, phoneNumber, phoneNumber }

    local query = [[
        SELECT
            c.id,
            c.duration,
            c.answered,
            c.caller = ? AS called,
            IF(c.callee = ?, c.caller, c.callee) AS `number`,
            IF(c.callee = ?, c.hide_caller_id, FALSE) AS hideCallerId,
            (EXISTS (SELECT 1 FROM phone_phone_blocked_numbers b WHERE b.phone_number=? AND b.blocked_number=`number`)) AS blocked,
            c.`timestamp`
        FROM
            phone_phone_calls c
        WHERE
            (c.callee = ? {MISSED_CALLS_CONDITION}) {PAGINATION}
        ORDER BY
            c.id DESC
        LIMIT 25
    ]]

    if missedOnly then
        query = query:gsub("{MISSED_CALLS_CONDITION}", "AND c.answered = 0")
    else
        query = query:gsub("{MISSED_CALLS_CONDITION}", "OR c.caller = ?")
        params[#params + 1] = phoneNumber
    end

    if beforeId then
        query = query:gsub("{PAGINATION}", "AND c.id < ?")
        params[#params + 1] = beforeId
    else
        query = query:gsub("{PAGINATION}", "")
    end

    local rows = MySQL.query.await(query, params)

    for _, row in ipairs(rows) do
        row.hideCallerId = row.hideCallerId == true
        row.blocked      = row.blocked == true
        row.called       = row.called == true
        if row.hideCallerId then
            row.number = L("BACKEND.CALLS.NO_CALLER_ID")
        end
    end

    return rows
end, {})

BaseCallback("getBlockedNumbers", function(source, phoneNumber)
    return MySQL.query.await(
        "SELECT blocked_number AS `number` FROM phone_phone_blocked_numbers WHERE phone_number=?",
        { phoneNumber }
    )
end, {})

-- =====================================================
--  Call Logging
-- =====================================================

local function LogCall(callerNumber, calleeNumber, duration, answered, hideCallerId, ender)
    MySQL.insert(
        "INSERT INTO phone_phone_calls (caller, callee, duration, answered, hide_caller_id) VALUES (@caller, @callee, @duration, @answered, @hideCallerId)",
        {
            ["@caller"]       = callerNumber,
            ["@callee"]       = calleeNumber,
            ["@duration"]     = duration,
            ["@answered"]     = answered,
            ["@hideCallerId"] = hideCallerId,
        }
    )

    if answered or ender == calleeNumber then return end

    local hasPhone = MySQL.scalar.await("SELECT TRUE FROM phone_phones WHERE phone_number = ?", { calleeNumber })
    if not hasPhone then return end

    if hideCallerId then
        SendNotification(calleeNumber, {
            app        = "Phone",
            title      = L("BACKEND.CALLS.NO_CALLER_ID"),
            content    = L("BACKEND.CALLS.MISSED_CALL"),
            showAvatar = false,
        })
        return
    end

    GetContact(callerNumber, calleeNumber, function(contact)
        local displayName = (contact and contact.name) or callerNumber
        SendNotification(calleeNumber, {
            app        = "Phone",
            title      = displayName,
            content    = L("BACKEND.CALLS.MISSED_CALL"),
            avatar     = contact and contact.avatar,
            showAvatar = true,
        })
    end)

    SendMessage(callerNumber, calleeNumber, "<!CALL-NO-ANSWER!>")
end

RegisterNetEvent("phone:logCall", function(calleeNumber, duration, answered)
    local src = source
    local callerNumber = GetEquippedPhoneNumber(src)
    if not (callerNumber and calleeNumber) or not answered then return end
    LogCall(callerNumber, calleeNumber, answered, false, false, callerNumber)
end)

-- =====================================================
--  Active Call Management
-- =====================================================

function IsInCall(src)
    for callId, call in pairs(activeCalls) do
        local callerSrc = call.caller and call.caller.source
        local calleeSrc = call.callee and call.callee.source
        if callerSrc == src or calleeSrc == src then
            return true, callId, call
        end
    end
    return false
end
exports("IsInCall", IsInCall)

function GetCall(callId)
    return activeCalls[callId]
end
exports("GetCall", GetCall)

RegisterNetEvent("phone:phone:disableCompanyCalls", function(disabled)
    local src = source
    disabledCompanyCalls[src] = disabled or nil
end)

-- =====================================================
--  Initiate a Call
-- =====================================================

BaseCallback("call", function(source, callerNumber, callData)
    debugprint("phone:phone:call", source, callerNumber, callData)

    if IsInCall(source) then
        debugprint(source, "is in call, returning")
        return false
    end

    local callId = GenerateCallId()
    local call = {
        started      = os.time(),
        answered     = false,
        videoCall    = callData.videoCall == true,
        hideCallerId = callData.hideCallerId == true,
        callId       = callId,
        caller       = { source = source, number = callerNumber, nearby = {} },
    }

    -- ---- Company call ----
    if callData.company then
        local companiesEnabled = Config.Companies and Config.Companies.Enabled
        if not companiesEnabled or callData.videoCall then
            debugprint("company calls are disabled in config or trying to call with video")
            TriggerClientEvent("phone:phone:userBusy", source)
            return false
        end

        local isValidCompany = Config.Companies.Contacts[callData.company] ~= nil
        if not isValidCompany then
            for _, service in ipairs(Config.Companies.Services) do
                if service.job == callData.company then
                    isValidCompany = true
                    break
                end
            end
        end
        if not isValidCompany then
            debugprint("invalid company (does not exist in Config.Companies.Contacts or Config.Companies.Services)")
            return false
        end

        if not Config.Companies.AllowAnonymous then
            call.hideCallerId = false
        end
        call.videoCall = false
        call.company   = callData.company
        call.callee    = { nearby = {} }

        local employees = GetEmployees(callData.company)
        debugprint("GetEmployees result:", employees)
        for _, empSrc in ipairs(employees) do
            if not IsInCall(empSrc) and empSrc ~= source and not disabledCompanyCalls[empSrc] then
                TriggerClientEvent("phone:phone:setCall", empSrc, {
                    callId       = callId,
                    number       = callerNumber,
                    company      = callData.company,
                    companylabel = callData.companylabel,
                    hideCallerId = call.hideCallerId,
                })
            else
                debugprint("employee", empSrc, "is in call or have disabled company calls")
            end
        end

    -- ---- Normal call ----
    else
        local isBlocked = MySQL.Sync.fetchScalar([[
            SELECT TRUE FROM phone_phone_blocked_numbers WHERE
                (phone_number = @number1 AND blocked_number = @number2)
                OR (phone_number = @number2 AND blocked_number = @number1)
        ]], { ["@number1"] = callerNumber, ["@number2"] = callData.number })

        if isBlocked then
            debugprint(source, "tried to call", callData.number, "but they are blocked")
            TriggerClientEvent("phone:phone:userBusy", source)
            return false
        end

        if callData.number == callerNumber then
            debugprint(source, "tried to call themselves")
            TriggerClientEvent("phone:phone:userBusy", source)
            return false
        end

        local calleeSrc      = GetSourceFromNumber(callData.number)
        local calleeInCall   = calleeSrc and IsInCall(calleeSrc)
        local calleeUnavailable = calleeSrc and not calleeInCall
            and (IsPhoneDead(callData.number) or HasAirplaneMode(callData.number))

        if not calleeSrc or calleeUnavailable then
            LogCall(callerNumber, callData.number, 0, false, callData.hideCallerId)

            if calleeInCall then
                debugprint(source, "tried to call", callData.number, "but they are in call")
                TriggerClientEvent("phone:phone:userBusy", source)
            else
                local hasPhone = MySQL.scalar.await("SELECT TRUE FROM phone_phones WHERE phone_number = ?", { callData.number })
                if hasPhone ~= nil then
                    debugprint(source, "tried to call", callData.number, "but they are not online, or their phone is dead")
                    TriggerClientEvent("phone:phone:userUnavailable", source)
                else
                    debugprint(source, "tried to call", callData.number, "but that number doesn't exist")
                    return "unknown_number"
                end
            end
            return false
        end

        call.callee = { source = calleeSrc, number = callData.number, nearby = {} }

        debugprint(source, "is calling", callData.number, "with callId", callId)
        TriggerClientEvent("phone:phone:setCall", calleeSrc, {
            callId       = callId,
            number       = callerNumber,
            videoCall    = callData.videoCall,
            webRTC       = callData.webRTC,
            hideCallerId = callData.hideCallerId,
        })
    end

    activeCalls[callId] = call
    TriggerEvent("lb-phone:newCall", call)
    return callId
end)

-- =====================================================
--  Answer Call
-- =====================================================

RegisterCallback("answerCall", function(source, callId)
    debugprint("answerCall", source, callId)

    local call = activeCalls[callId]
    if not call then
        debugprint("answerCall: invalid call id")
        return false
    end

    if call.company then
        if call.callee.source then
            debugprint("answerCall: someone else has already answered this company call")
            return false
        end

        local employees = GetEmployees(call.company)
        for _, empSrc in ipairs(employees) do
            if not IsInCall(empSrc) and empSrc ~= source and not disabledCompanyCalls[empSrc] then
                TriggerClientEvent("phone:phone:endCall", empSrc, callId)
            end
        end

        call.callee.source = source
    else
        if call.callee.source ~= source then
            debugprint("answerCall: invalid callee source")
            return false
        end
    end

    local calleeSrc = call.callee.source
    if not calleeSrc then
        debugprint("answerCall: no callee source")
        return false
    end

    local callerSrc = call.caller.source

    if callerSrc then
        local callerState = Player(callerSrc).state
        callerState.speakerphone = false
        callerState.mutedCall    = false
        callerState.onCallWith   = calleeSrc
        callerState.callAnswered = true
    end

    local calleeState = Player(calleeSrc).state
    calleeState.speakerphone = false
    calleeState.mutedCall    = false
    calleeState.onCallWith   = callerSrc or call.caller.number
    calleeState.callAnswered = true

    call.answered = true

    TriggerClientEvent("phone:phone:connectCall", source, callId)
    if callerSrc then
        TriggerClientEvent("phone:phone:connectCall", callerSrc, callId, call.exportCall == true)
    end

    if Config.Voice.CallEffects and callerSrc then
        TriggerClientEvent("phone:phone:setCallEffect", source,    callerSrc, true)
        TriggerClientEvent("phone:phone:setCallEffect", callerSrc, source,    true)
    end

    TriggerEvent("lb-phone:callAnswered", call)
    debugprint("answerCall: answered call", callId)
    return true
end)

-- =====================================================
--  Video Call
-- =====================================================

local function GetOtherPartySource(call, src)
    if call.caller.source == src then
        return call.callee.source
    end
    return call.caller.source
end

BaseCallback("requestVideoCall", function(source, phoneNumber, callId, peerId)
    local call = callId and activeCalls[callId]
    if not call then
        debugprint("requestVideoCall: invalid call id", callId, json.encode(activeCalls, { indent = true }))
        return false
    end

    debugprint("requestVideoCall", source, callId, peerId)

    if call.videoCall or not call.answered then
        return false
    end

    call.videoRequested = true
    local otherSrc = GetOtherPartySource(call, source)
    if otherSrc then
        TriggerClientEvent("phone:phone:videoRequested", otherSrc, peerId)
    end
end)

BaseCallback("answerVideoRequest", function(source, phoneNumber, callId, accepted)
    local call = callId and activeCalls[callId]
    if not call then
        debugprint("answerVideoRequest: invalid call id")
        return false
    end

    debugprint("answerVideoRequest", source, callId, accepted)

    if not (call.videoCall or (call.answered and call.videoRequested)) then
        return false
    end

    call.videoRequested = false
    call.videoCall      = accepted == true

    local otherSrc = GetOtherPartySource(call, source)
    if otherSrc then
        TriggerClientEvent("phone:phone:videoRequestAnswered", otherSrc, accepted)
    end

    return true
end)

BaseCallback("stopVideoCall", function(source, phoneNumber, callId)
    local call = callId and activeCalls[callId]
    if not call then
        debugprint("stopVideoCall: invalid call id")
        return false
    end

    if not (call.videoCall and call.answered) then
        return false
    end

    call.videoCall = false
    TriggerClientEvent("phone:phone:stopVideoCall", source)

    local otherSrc = GetOtherPartySource(call, source)
    if otherSrc then
        TriggerClientEvent("phone:phone:stopVideoCall", otherSrc)
    end

    return true
end)

-- =====================================================
--  End Call
-- =====================================================

local function EndCall(src, callback)
    local inCall, callId = IsInCall(src)
    debugprint("^5EndCall^7:", src, inCall, callId)

    if not (inCall and callId) or not activeCalls[callId] then
        if callback then callback(false) end
        debugprint("^5EndCall^7: not in call/invalid callId")
        return false
    end

    local call      = activeCalls[callId]
    local callerSrc = call.caller.source
    local calleeSrc = call.callee.source

    if calleeSrc then
        debugprint("^5EndCall^7: ending call for callee", callId, calleeSrc)
        TriggerClientEvent("phone:phone:endCall", calleeSrc)

        if Config.Voice.CallEffects and callerSrc then
            TriggerClientEvent("phone:phone:setCallEffect", calleeSrc, callerSrc, false)
            TriggerClientEvent("phone:phone:setCallEffect", callerSrc, calleeSrc, false)
        end
    elseif call.company then
        local employees = GetEmployees(call.company)
        for _, empSrc in ipairs(employees) do
            if not IsInCall(empSrc) and not disabledCompanyCalls[empSrc] then
                TriggerClientEvent("phone:phone:endCall", empSrc, callId)
            end
        end
    end

    if callerSrc then
        debugprint("^5EndCall^7: ending call for caller", callId, callerSrc)
        TriggerClientEvent("phone:phone:endCall", callerSrc)
    end

    local function clearState(playerSrc)
        if playerSrc and Player(playerSrc) then
            local state = Player(playerSrc).state
            state.onCallWith   = nil
            state.speakerphone = false
            state.mutedCall    = false
            state.callAnswered = false
        end
    end
    clearState(callerSrc)
    clearState(calleeSrc)

    TriggerEvent("lb-phone:callEnded", call, src)

    Log("Calls", call.caller.source, "info",
        L("BACKEND.LOGS.CALL_ENDED"),
        L("BACKEND.LOGS.CALL_DESCRIPTION", {
            duration = os.time() - call.started,
            caller   = FormatNumber(call.caller.number),
            callee   = call.callee.number and FormatNumber(call.callee.number) or call.company,
            answered = call.answered,
        })
    )

    if not call.company then
        LogCall(
            call.caller.number,
            call.callee.number,
            os.time() - call.started,
            call.answered,
            call.hideCallerId,
            GetEquippedPhoneNumber(src)
        )
    end

    activeCalls[callId] = nil

    if callback then callback(true) end
    return true
end

exports("EndCall", EndCall)

RegisterNetEvent("phone:endCall", function()
    EndCall(source)
end)

-- =====================================================
--  Voicemail
-- =====================================================

BaseCallback("getRecentVoicemails", function(source, phoneNumber, page)
    local offset = (page or 0) * 25
    return MySQL.query.await([[
        SELECT id, IF(hide_caller_id, null, caller) AS `number`, url, duration, hide_caller_id AS hideCallerId, `timestamp`
        FROM phone_phone_voicemail
        WHERE callee = ?
        ORDER BY `timestamp` DESC
        LIMIT ?, ?
    ]], { phoneNumber, offset, 25 })
end, {})

BaseCallback("deleteVoiceMail", function(source, phoneNumber, voicemailId)
    local affected = MySQL.update.await(
        "DELETE FROM phone_phone_voicemail WHERE id = ? AND callee = ?",
        { voicemailId, phoneNumber }
    )
    return affected > 0
end)

BaseCallback("sendVoicemail", function(source, phoneNumber, data)
    MySQL.insert.await(
        "INSERT INTO phone_phone_voicemail (caller, callee, url, duration, hide_caller_id) VALUES (@caller, @callee, @url, @duration, @hideCallerId)",
        {
            ["@caller"]       = phoneNumber,
            ["@callee"]       = data.number,
            ["@url"]          = data.src,
            ["@duration"]     = data.duration,
            ["@hideCallerId"] = data.hideCallerId == true,
        }
    )
    SendNotification(data.number, {
        app   = "Phone",
        title = L("BACKEND.CALLS.NEW_VOICEMAIL"),
    })
    return true
end)

-- =====================================================
--  Airplane Mode
-- =====================================================

function HasAirplaneMode(phoneNumber)
    debugprint("checking if", phoneNumber, "has airplane mode enabled")
    local phoneSettings = GetSettings(phoneNumber)
    if not phoneSettings then
        debugprint("no settings found for", phoneNumber)
        return
    end
    return phoneSettings.airplaneMode
end
exports("HasAirplaneMode", HasAirplaneMode)

-- =====================================================
--  Export: CreateCall
-- =====================================================

exports("CreateCall", function(callerInfo, calleeNumber, options)
    options = options or {}

    local callerSrc
    if type(callerInfo) == "table" and callerInfo.source then
        callerSrc = callerInfo.source
    end

    local callerNumber
    if type(callerInfo) ~= "string" or not callerInfo then
        callerNumber = callerInfo.phoneNumber
    else
        callerNumber = callerInfo
    end

    if callerSrc then
        if not GetPlayerName(callerSrc) then
            return debugprint("CreateCall: callerSrc is not a valid player")
        end
        if options.requirePhone then
            if IsPhoneDead(callerNumber) or not HasPhoneItem(callerSrc, callerNumber) then
                return debugprint("CreateCall: caller does not have a phone")
            end
        end
        if IsInCall(callerSrc) then
            return debugprint("CreateCall: caller is already in a call")
        end
    end

    if not options.company and not calleeNumber then
        return debugprint("CreateCall: no callee or company provided")
    end

    local callId = GenerateCallId()
    local call = {
        started      = os.time(),
        answered     = false,
        videoCall    = false,
        hideCallerId = options.hideNumber == true,
        callId       = callId,
        caller       = { source = callerSrc, number = callerNumber, nearby = {} },
        exportCall   = true,
    }

    if options.company then
        if not (Config.Companies and Config.Companies.Enabled) then
            return debugprint("company calls are disabled in config")
        end

        local isValid, companyLabel = false, options.company
        local contactEntry = Config.Companies.Contacts[options.company]
        if contactEntry then
            companyLabel = contactEntry.name
            isValid = true
        else
            for _, service in ipairs(Config.Companies.Services) do
                if service.job == options.company then
                    isValid = true
                    companyLabel = service.name
                    break
                end
            end
        end
        if not isValid then
            return debugprint("invalid company")
        end

        call.company = options.company
        call.callee  = { nearby = {} }

        local employees = GetEmployees(options.company)
        for _, empSrc in ipairs(employees) do
            if not IsInCall(empSrc) and empSrc ~= callerSrc and not disabledCompanyCalls[empSrc] then
                TriggerClientEvent("phone:phone:setCall", empSrc, {
                    callId       = callId,
                    number       = callerNumber,
                    company      = options.company,
                    companylabel = companyLabel,
                })
            end
        end

    elseif calleeNumber then
        local calleeSrc = GetSourceFromNumber(calleeNumber)
        if not calleeSrc then
            return debugprint("CreateCall: calleeSrc is not a valid player")
        end
        if IsInCall(calleeSrc) then
            return debugprint("CreateCall: caller or callee is in call")
        end

        call.callee = { source = calleeSrc, number = calleeNumber, nearby = {} }

        TriggerClientEvent("phone:phone:setCall", calleeSrc, {
            callId       = callId,
            number       = callerNumber,
            hideCallerId = options.hideNumber == true,
        })
    end

    activeCalls[callId] = call
    TriggerEvent("lb-phone:newCall", call)

    if callerSrc then
        TriggerClientEvent("phone:phone:enableExportCall", callerSrc)
    end

    return callId
end)

-- =====================================================
--  Export: AddContact
-- =====================================================

exports("AddContact", function(phoneNumber, contactData)
    assert(type(phoneNumber) == "string", "phoneNumber must be a string")
    assert(type(contactData) == "table",  "data must be a table")

    local success = CreateContact(phoneNumber, contactData)
    debugprint("AddContact: success", success)

    local src = GetSourceFromNumber(phoneNumber)
    if src and success then
        TriggerClientEvent("phone:phone:contactAdded", src, contactData)
    end
end)

-- =====================================================
--  Cleanup on player drop
-- =====================================================

AddEventHandler("playerDropped", function()
    local src = source
    disabledCompanyCalls[src] = nil
    EndCall(src)
end)