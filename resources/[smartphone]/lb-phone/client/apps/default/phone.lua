InExportCall = false

-- State variables
local isVideoCall          = false
local isInCall             = false
local activeCallId         = nil
local customNumbers        = {}    -- number string -> customNumberData
local dynamicCustomNumbers = {}    -- id -> dynamicNumberData
local dynamicNumberCount   = 0
local activeCustomCall     = nil   -- current custom call data
local customCallStartTime  = 0
local customCallAnswered   = false

-- =====================================================
--  Custom Call Logic
-- =====================================================

-- Ends an active custom call, logs it to server, and resets state
local function EndCustomCall()
    debugprint("EndCustomCall triggered")

    if activeCustomCall then
        local duration = math.floor((GetGameTimer() - customCallStartTime) / 1000 + 0.5)
        debugprint("Custom call to", activeCustomCall.number, "ended after", duration, "seconds answered:", customCallAnswered)
        TriggerServerEvent("phone:logCall", activeCustomCall.number, duration)
    end

    isInCall          = false
    activeCustomCall  = nil
    activeCallId      = nil
    customCallStartTime = 0
    customCallAnswered  = false

    SetPhoneAction("default")
    SendReactMessage("call:endCall")

    if not phoneOpen then
        PlayCloseAnim()
    end
end

-- Finds and initiates a custom call for the given number. Returns true if handled.
local function TryCustomCall(number)
    local customData = customNumbers[number]

    if not customData then
        -- Check dynamic validators
        for id, dynData in pairs(dynamicCustomNumbers) do
            local ok, isValid = pcall(dynData.isValid, number)
            if ok and isValid then
                customData = dynData.customNumber
                break
            elseif not ok then
                local errStr = Citizen.InvokeNative(3607903178, nil, 0, Citizen.ResultAsString()) or ""
                print(string.format(
                    "^1SCRIPT ERROR: Dynamic number validator (id %i, by resource '%s') failed: %s^7\n%s",
                    id, dynData.resource, isValid or "", errStr
                ))
            end
        end
    end

    if not customData then
        return false
    end

    local callUniqueId = "CUSTOM_NUMBER_" .. math.random(9999999)
    isInCall           = true
    activeCallId       = callUniqueId
    activeCustomCall   = customData
    customCallStartTime = GetGameTimer()
    customCallAnswered  = false

    Citizen.CreateThreadNow(function()
        customData.onCall({
            id     = callUniqueId,
            number = number,

            accept = function()
                -- Only mark answered if this call is still active
                if not customCallAnswered and activeCallId == callUniqueId then
                    customCallAnswered = true
                    SetPhoneAction("call")
                    SendReactMessage("call:connected")
                end
            end,

            deny = function()
                if activeCallId == callUniqueId then
                    EndCustomCall()
                end
            end,

            setName = function(name)
                if activeCallId == callUniqueId then
                    SendReactMessage("call:setContactData", { name = name })
                end
            end,

            hasEnded = function()
                return activeCallId ~= callUniqueId
            end,
        })
    end)

    return true
end

-- Dispatches a call action (end/mute/speaker/keypad) to the active custom call handler
local function DispatchCustomCallAction(action)
    if not activeCustomCall then return end

    if action == "end" then
        if activeCustomCall.onEnd then
            Citizen.CreateThreadNow(activeCustomCall.onEnd)
        end
        EndCustomCall()
        return
    end

    if action:find("keypad_") then
        if not activeCustomCall.onKeypad then return end
        local key = action:sub(8)
        if not key then return end
        Citizen.CreateThreadNow(function()
            activeCustomCall.onKeypad(key)
        end)
        return
    end

    if activeCustomCall.onAction then
        activeCustomCall.onAction(action)
    end
end

-- =====================================================
--  NUI Callback: Phone
-- =====================================================

RegisterNUICallback("Phone", function(data, cb)
    if not currentPhone then return end

    local action = data.action
    debugprint("Phone:" .. (action or ""))

    if action == "getContacts" then
        TriggerCallback("getContacts", function(contacts)
            if Config.Companies.Enabled then
                for companyId, companyData in pairs(Config.Companies.Contacts) do
                    contacts[#contacts + 1] = {
                        firstname = companyData.name,
                        avatar    = companyData.photo,
                        company   = companyId,
                    }
                end
            end
            cb(contacts)
        end)

    elseif action == "toggleFavourite" then
        TriggerCallback("toggleFavourite", cb, data.number, data.favourite)

    elseif action == "toggleBlock" then
        TriggerCallback("toggleBlock", cb, data.number, data.blocked)

    elseif action == "removeContact" then
        TriggerCallback("removeContact", cb, data.number)

    elseif action == "updateContact" then
        TriggerCallback("updateContact", cb, data.data)

    elseif action == "saveContact" then
        TriggerCallback("saveContact", cb, data.data)

    elseif action == "getRecent" then
        TriggerCallback("getRecentCalls", cb, data.missed == true, data.lastId)

    elseif action == "getBlockedNumbers" then
        TriggerCallback("getBlockedNumbers", function(rows)
            local numbers = {}
            for i, row in pairs(rows) do
                numbers[i] = row.number
            end
            cb(numbers)
        end)

    elseif action == "toggleMute" then
        if not activeCallId then
            return cb(false)
        end

        if activeCustomCall then
            DispatchCustomCallAction(data.toggle and "mute" or "unmute")
            return cb(data.toggle)
        end

        if data.toggle then
            RemoveFromCall(activeCallId)
        else
            AddToCall(activeCallId)
        end
        TriggerServerEvent("phone:phone:toggleMute", data.toggle)
        cb(data.toggle)

    elseif action == "toggleSpeaker" then
        if not activeCallId then
            return cb(false)
        end

        if activeCustomCall then
            DispatchCustomCallAction(data.toggle and "enable_speaker" or "disable_speaker")
            return cb(data.toggle)
        end

        TriggerServerEvent("phone:phone:toggleSpeaker", data.toggle)
        ToggleSpeaker(data.toggle)
        cb(data.toggle)

    elseif action == "sendVoicemail" then
        TriggerCallback("sendVoicemail", cb, data.data)

    elseif action == "getVoiceMails" then
        TriggerCallback("getRecentVoicemails", cb, data.page)

    elseif action == "deleteVoiceMail" then
        TriggerCallback("deleteVoiceMail", cb, data.id)

    elseif action == "keypad" then
        cb("ok")
        if activeCustomCall then
            DispatchCustomCallAction("keypad_" .. data.key)
        end

    elseif action == "call" then
        -- Validate company call
        if data.company then
            if not Config.Companies.Enabled or data.videoCall then
                return cb(false)
            end

            local isValidCompany = Config.Companies.Contacts[data.company] ~= nil
            if not isValidCompany then
                for _, service in ipairs(Config.Companies.Services) do
                    if service.job == data.company then
                        isValidCompany = true
                        break
                    end
                end
            end
            if not isValidCompany then
                return cb(false)
            end
        end

        isVideoCall = data.videoCall
        local result = AwaitCallback("call", data)

        if result == "unknown_number" then
            local handled = TryCustomCall(data.number)
            if handled then
                return cb("CUSTOM_NUMBER")
            end
            SendReactMessage("call:userUnavailable")
            return cb(false)
        end

        return cb(result)

    elseif action == "answerCall" then
        if IsInCall() then
            debugprint("answerCall: Already in call")
            return
        end

        if IsLive() then
            debugprint("answerCall: Ending live")
            TriggerCallback("instagram:endLive")
        elseif IsWatchingLive() then
            debugprint("answerCall: Leaving live")
            SendReactMessage("instagram:liveEnded", IsWatchingLive())
        end

        debugprint("Answering call", data.callId)
        TriggerServerEvent("phone:sound:stopSound")
        TriggerCallback("answerCall", cb, data.callId)
        cb("ok")

    elseif action == "endCall" then
        EndCall()
        cb("ok")

    elseif action == "flipCamera" then
        ToggleSelfieCam(not IsSelfieCam())

    elseif action == "requestVideoCall" then
        TriggerCallback("requestVideoCall", cb, data.callId, data.peerId)

    elseif action == "answerVideoRequest" then
        TriggerCallback("answerVideoRequest", cb, data.callId, data.accept)
        if data.accept then
            isVideoCall = true
            EnableWalkableCam()
        end

    elseif action == "stopVideoCall" then
        TriggerCallback("stopVideoCall", cb, data.callId)

    elseif action == "stopRingtone" then
        StopPhoneSound()
    end
end)

-- =====================================================
--  EndCall (client-side)
-- =====================================================

function EndCall()
    TriggerServerEvent("phone:sound:stopSound")
    TriggerServerEvent("phone:endCall")
    if activeCustomCall then
        DispatchCustomCallAction("end")
    end
end

-- =====================================================
--  Net Event: Incoming Call
-- =====================================================

RegisterNetEvent("phone:phone:setCall", function(callData)
    if not HasPhoneItem(currentPhone) then
        debugprint("no phone, not showing call")
        return
    end
    if phoneDisabled then
        debugprint("phone is disabled, not showing call")
        return
    end
    if IsPhoneDead() then
        debugprint("phone is dead, not showing call")
        return
    end

    if activeCustomCall or isInCall then
        debugprint("in a (custom?) call", tostring(activeCustomCall), tostring(isInCall))
        return
    end

    if IsPedDeadOrDying(PlayerPedId(), false) then
        debugprint("player is dead, not showing call")
        return
    end

    if CanOpenPhone and not CanOpenPhone() then
        debugprint("can't open phone, not showing call")
        return
    end

    isVideoCall = callData.videoCall

    -- Resolve custom ringtone (if any)
    local customRingtone = nil
    if not callData.hideCallerId and settings and settings.sound and settings.sound.ringtones then
        if callData.number then
            customRingtone = settings.sound.ringtones[callData.number]
        end
    end

    PlayPhoneSound("ringtone", customRingtone)
    SendReactMessage("incomingCall", callData)
end)

-- =====================================================
--  Net Event: Export Call Enabled
-- =====================================================

RegisterNetEvent("phone:phone:enableExportCall", function()
    InExportCall = true
end)

-- =====================================================
--  Net Event: Call Connected
-- =====================================================

RegisterNetEvent("phone:phone:connectCall", function(callId, isExportCall)
    debugprint("phone:phone:connectCall", callId, isExportCall)

    isInCall     = true
    activeCallId = callId
    AddToCall(callId)

    if isExportCall then return end

    StopPhoneSound()
    SetPhoneAction("call")
    SendReactMessage("call:connected")

    if isVideoCall then
        EnableWalkableCam()
    end
end)

-- =====================================================
--  Net Event: Call Ended
-- =====================================================

RegisterNetEvent("phone:phone:endCall", function()
    debugprint("phone:phone:endCall")

    local wasInCall = isInCall
    isInCall    = false
    isVideoCall = false

    SetPhoneAction("default")
    DisableWalkableCam()

    if not phoneOpen and wasInCall then
        debugprint("close anim")
        PlayCloseAnim()
    end

    StopPhoneSound()
    RemoveFromCall(activeCallId)
    activeCallId = nil
    InExportCall = false

    TriggerServerEvent("phone:sound:stopSound")
    SendReactMessage("call:endCall")
end)

-- =====================================================
--  Net Events: Call Status
-- =====================================================

RegisterNetEvent("phone:phone:userUnavailable", function()
    debugprint("phone:phone:userUnavailable")
    SendReactMessage("call:userUnavailable")
end)

RegisterNetEvent("phone:phone:userBusy", function()
    debugprint("phone:phone:userBusy")
    SendReactMessage("call:userBusy")
end)

-- =====================================================
--  IsInCall export (client)
-- =====================================================

function IsInCall()
    return isInCall
end
exports("IsInCall", IsInCall)

-- =====================================================
--  Export: AddContact (client)
-- =====================================================

exports("AddContact", function(contact)
    assert(type(contact) == "table",          "contact must be a table")
    assert(type(contact.number) == "string",  "contact.number must be a string")
    assert(type(contact.firstname) == "string", "contact.firstname must be a string")

    local success = AwaitCallback("saveContact", contact)
    if success then
        SendReactMessage("phone:contactAdded", contact)
    end
    return success
end)

-- =====================================================
--  Video Call Net Events
-- =====================================================

RegisterNetEvent("phone:phone:videoRequested", function(peerId)
    debugprint("phone:phone:videoRequested", peerId)
    SendReactMessage("call:videoRequested", peerId)
end)

RegisterNetEvent("phone:phone:videoRequestAnswered", function(accepted)
    debugprint("phone:phone:videoRequestAnswered", accepted)
    SendReactMessage("call:videoRequestAnswered", accepted)
    if accepted then
        isVideoCall = true
        EnableWalkableCam()
    end
end)

RegisterNetEvent("phone:phone:stopVideoCall", function()
    debugprint("phone:phone:stopVideoCall")
    SendReactMessage("call:stopVideoCall")
    isVideoCall = false
    DisableWalkableCam()
end)

-- =====================================================
--  Net Event: Contact Added (server push)
-- =====================================================

RegisterNetEvent("phone:phone:contactAdded", function(contactData)
    debugprint("phone:phone:contactAdded", contactData)
    SendReactMessage("phone:contactAdded", contactData)
end)

-- =====================================================
--  Export: CreateCall (client)
-- =====================================================

function CreateCall(options)
    assert(type(options) == "table", "options must be a table")
    assert(options.number or options.company, "options must contain either a number or company")

    if not currentPhone then
        return debugprint("no phone")
    end

    -- Apply hide-caller-id from settings if not explicitly set
    if options.hideNumber == nil then
        if settings and settings.phone and settings.phone.showCallerId == false then
            options.hideNumber = true
        end
    end

    if options.company then
        if not Config.Companies.Enabled then
            return debugprint("company calls are disabled in config")
        end

        -- Resolve company label
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

        debugprint("CreateCall: company", options)
        SendReactMessage("call", {
            company      = options.company,
            companylabel = companyLabel,
            hideCallerId = options.hideNumber == true,
        })
    else
        debugprint("CreateCall: number", options)
        SendReactMessage("call", {
            number       = options.number,
            videoCall    = options.videoCall == true,
            hideCallerId = options.hideNumber == true,
        })
    end
end
exports("CreateCall", CreateCall)

-- =====================================================
--  Export: CreateCustomNumber
-- =====================================================

exports("CreateCustomNumber", function(number, data)
    local invokingResource = GetInvokingResource()

    assert(type(number) == "string",      "number must be a string")
    assert(type(data) == "table",         "data must be a table")
    assert(type(data.onCall) == "function", "data.onCall must be a function")

    if customNumbers[number] then
        return false, "Number already exists"
    end

    customNumbers[number] = {
        resource  = invokingResource,
        number    = number,
        onCall    = data.onCall,
        onEnd     = data.onEnd,
        onAction  = data.onAction,
        onKeypad  = data.onKeypad,
    }
    return true
end)

-- =====================================================
--  Export: RemoveCustomNumber
-- =====================================================

exports("RemoveCustomNumber", function(number)
    local invokingResource = GetInvokingResource()

    assert(type(number) == "string", "number must be a string")

    if not customNumbers[number] then
        return false, "Number does not exist"
    end
    if customNumbers[number].resource ~= invokingResource then
        return false, "Number was not created by " .. invokingResource
    end

    customNumbers[number] = nil
    return true
end)

-- =====================================================
--  Export: EndCustomCall
-- =====================================================

exports("EndCustomCall", function()
    if activeCustomCall then
        EndCustomCall()
        return true
    end
    return false
end)

-- =====================================================
--  Export: CreateDynamicCustomNumber
-- =====================================================

exports("CreateDynamicCustomNumber", function(validator, data)
    local invokingResource = GetInvokingResource()

    assert(type(validator) == "function",   "validator must be a function")
    assert(type(data) == "table",           "data must be a table")
    assert(type(data.onCall) == "function", "data.onCall must be a function")

    dynamicNumberCount = dynamicNumberCount + 1
    local id = dynamicNumberCount

    dynamicCustomNumbers[id] = {
        isValid      = validator,
        customNumber = data,
        resource     = invokingResource,
    }

    return id
end)

-- =====================================================
--  Export: RemoveDynamicCustomNumber
-- =====================================================

exports("RemoveDynamicCustomNumber", function(id)
    local invokingResource = GetInvokingResource()

    assert(type(id) == "number", "id must be a number")

    if not dynamicCustomNumbers[id] then
        return false, "Dynamic number does not exist"
    end
    if dynamicCustomNumbers[id].resource ~= invokingResource then
        return false, "Dynamic number was not created by " .. invokingResource
    end

    dynamicCustomNumbers[id] = nil
    return true
end)

-- =====================================================
--  Cleanup on resource stop
-- =====================================================

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then return end

    -- Remove static custom numbers registered by this resource
    for number, data in pairs(customNumbers) do
        if data.resource == resourceName then
            debugprint("Removed custom number", number, "due to resource stopping")
            if activeCustomCall == data then
                DispatchCustomCallAction("end")
            end
            customNumbers[number] = nil
        end
    end

    -- Remove dynamic custom numbers registered by this resource
    for id, data in pairs(dynamicCustomNumbers) do
        if data.resource == resourceName then
            debugprint("Removed dynamic custom number id", id, "due to resource stopping")
            dynamicCustomNumbers[id] = nil
        end
    end
end)