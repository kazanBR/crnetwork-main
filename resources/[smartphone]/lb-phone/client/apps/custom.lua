-- Pending callback registry: { [id] = handlerFn }
local pendingCallbacks = {}

-- Valid button colours for popup/context menu validation
local validColors = { blue = true, red = true, green = true, yellow = true }

-- Component type → result field(s) mapping
local componentReturnFields = {
    gallery         = { "image" },
    gif             = { "gif" },
    emoji           = { "emoji" },
    camera          = { "url" },
    colorpicker     = { "color" },
    contactselector = { "contact" },
}

-- =====================================================
-- generateCallbackId (internal)
-- Returns a unique random ID not already in use.
-- =====================================================
local function generateCallbackId()
    local id = math.random(999999999)
    while pendingCallbacks[id] do
        id = math.random(999999999)
    end
    return id
end

-- =====================================================
-- NUI Callback: "CustomApp"
-- Dispatches lifecycle events for custom phone apps.
-- =====================================================
RegisterNUICallback("CustomApp", function(data, cb)
    local appName = data.app
    local action  = data.action

    cb("ok")

    if not action or not appName then
        debugprint("invalid data")
        return
    end

    local appConfig = Config.CustomApps[appName]

    if action == "open" then
        if appConfig and appConfig.onServerUse then
            TriggerServerEvent("lb-phone:customApp", appName)
        end

        if not (appConfig and appConfig.ui) then
            if not (appConfig and appConfig.keepOpen) then
                debugprint("Closing phone due to custom app without ui")
                ToggleOpen(false)
            end
        end

        if appConfig and appConfig.onUse then
            Citizen.CreateThreadNow(function()
                appConfig.onUse()
            end)
        end

        if appConfig and appConfig.onOpen then
            Citizen.CreateThreadNow(function()
                appConfig.onOpen()
            end)
        end

    elseif action == "close" then
        if appConfig and appConfig.onClose then
            appConfig.onClose()
        end

    elseif action == "install" then
        if appConfig and appConfig.onInstall then
            appConfig.onInstall()
        end

    elseif action == "uninstall" then
        if appConfig and appConfig.onDelete then
            appConfig.onDelete()
        end
    end
end)

-- =====================================================
-- NUI Callback: "PopUp"
-- Fires the registered handler for a popup button tap.
-- =====================================================
RegisterNUICallback("PopUp", function(callbackId, cb)
    local handler = pendingCallbacks[callbackId]
    if not handler then return end

    cb("ok")
    handler()
    pendingCallbacks[callbackId] = nil
end)

-- =====================================================
-- NUI Callback: "PopUpInputChanged"
-- Fires the registered handler when a popup input changes.
-- =====================================================
RegisterNUICallback("PopUpInputChanged", function(data, cb)
    local callbackId = data.id
    local value      = data.value

    local handler = pendingCallbacks[callbackId]
    if not handler then return end

    cb("ok")
    handler(value)
end)

-- =====================================================
-- setupPopUp (internal)
-- Validates popup data and registers button/input
-- callbacks. isExport=true when called from a Lua
-- export (button.cb is a real function); otherwise
-- isExport is the NUI cb function.
-- =====================================================
local function setupPopUp(popupData, isExport)
    assert(popupData.buttons and #popupData.buttons > 0, "You need at least one button")

    for _, button in pairs(popupData.buttons) do
        assert(button.title, "You need a title for each button")

        local color = button.color or "blue"
        assert(validColors[color], "Invalid color")

        if isExport == true then
            if button.cb then
                local id         = generateCallbackId()
                local originalCb = button.cb

                pendingCallbacks[id] = function()
                    originalCb(button.callbackId)
                end

                button.cb = id
            end
        else
            if button.callbackId then
                local id    = generateCallbackId()
                local nuiCb = button.callbackId

                pendingCallbacks[id] = function()
                    isExport(nuiCb)
                end

                button.cb = id
            end
        end
    end

    local inputCfg = popupData.input
    if inputCfg and inputCfg.onChange then
        local id = generateCallbackId()

        if isExport == true then
            pendingCallbacks[id] = inputCfg.onChange
        else
            pendingCallbacks[id] = function(value)
                SendReactMessage("customApp:sendMessage", {
                    identifier = "any",
                    message    = { type = "popUpInputChanged", value = value },
                })
            end
        end

        inputCfg.onChange = id
    end

    SendReactMessage("onComponentUse", { type = "popup", data = popupData })
end

RegisterNUICallback("SetPopUp", setupPopUp)

exports("SetPopUp", function(popupData)
    setupPopUp(popupData, true)
end)

-- =====================================================
-- NUI Callback: "ContextMenu"
-- Fires the handler for a context menu selection.
-- =====================================================
RegisterNUICallback("ContextMenu", function(callbackId, cb)
    local handler = pendingCallbacks[callbackId]
    if not handler then return end

    handler()
    pendingCallbacks[callbackId] = nil
    cb("ok")
end)

-- =====================================================
-- setupContextMenu (internal)
-- Validates context menu data and registers callbacks.
-- =====================================================
local function setupContextMenu(menuData, isExport)
    assert(menuData.buttons and #menuData.buttons > 0, "You need at least one button")

    for _, button in pairs(menuData.buttons) do
        assert(button.title, "You need a title for each button")

        local color = button.color or "blue"
        assert(validColors[color], "Invalid colour")

        if isExport == true then
            assert(button.cb, "You need a callback for each button")
        else
            assert(button.callbackId, "You need a callback for each button")
        end

        local id = generateCallbackId()

        pendingCallbacks[id] = function()
            if isExport == true then
                button.cb()
            else
                isExport(button.callbackId)
            end
        end

        button.cb = id
    end

    SendReactMessage("onComponentUse", { type = "contextmenu", data = menuData })
end

RegisterNUICallback("SetContextMenu", setupContextMenu)

exports("SetContextMenu", function(menuData)
    setupContextMenu(menuData, true)
end)

-- =====================================================
-- SetCameraComponent (export)
-- Opens the in-phone camera. If no callback is given,
-- awaits and returns the captured image URL.
-- =====================================================
local function SetCameraComponent(cameraData, onCapture)
    if type(cameraData) ~= "table" then
        cameraData = {}
    end

    local wasPhoneOpen = phoneOpen
    local id           = generateCallbackId()
    cameraData.id      = id

    if not wasPhoneOpen then
        debugprint("Opening phone due to camera component")
        ToggleOpen(true)
    end

    local p = not onCapture and promise.new() or nil

    pendingCallbacks[id] = function(result)
        if onCapture then
            onCapture(result.url)
        else
            p:resolve(result.url)
        end

        if not wasPhoneOpen then
            debugprint("Closing phone due to camera component")
            ToggleOpen(false)
        end
    end

    SendReactMessage("onComponentUse", { type = "camera", data = cameraData })

    if not onCapture then
        return Citizen.Await(p)
    end
end

exports("SetCameraComponent", SetCameraComponent)

-- =====================================================
-- SetContactModal (NUI callback + export)
-- Opens a contact-info modal for the given number.
-- =====================================================
local function SetContactModal(phoneNumber)
    assert(phoneNumber, "You need to provide a phone number")
    SendReactMessage("onComponentUse", { type = "contactmodal", data = phoneNumber })
end

RegisterNUICallback("SetContactModal", function(data, cb)
    SetContactModal(data)
    cb("ok")
end)

exports("SetContactModal", SetContactModal)

-- =====================================================
-- NUI Callback: "UsedComponent"
-- Fired when the NUI finishes with a UI component.
-- Calls the registered handler and clears it.
-- =====================================================
RegisterNUICallback("UsedComponent", function(data, cb)
    local id = data and data.id
    if not id then return end

    local handler = pendingCallbacks[id]
    if not handler then return end

    handler(data)
    pendingCallbacks[id] = nil
    cb("ok")
end)

-- =====================================================
-- ShowComponent (NUI callback + export)
-- Displays a UI component (gallery, gif, emoji, camera,
-- colorpicker, contactselector). The result callback
-- receives the selected value(s) as arguments.
-- =====================================================
local function ShowComponent(componentData, onResult)
    local componentType = componentData.component

    assert(componentType, "You need to specify a component")
    assert(componentReturnFields[componentType], "Invalid component")

    local id = generateCallbackId()

    pendingCallbacks[id] = function(result)
        local values = {}
        for _, field in pairs(componentReturnFields[componentType]) do
            values[#values + 1] = result[field]
        end
        onResult(table.unpack(values))
    end

    componentData.id = id
    SendReactMessage("onComponentUse", { type = componentType, data = componentData })
end

RegisterNUICallback("ShowComponent", ShowComponent)
exports("ShowComponent", ShowComponent)

-- =====================================================
-- NUI Callback: "CreateCall"
-- Initiates a phone call from within the NUI.
-- =====================================================
RegisterNUICallback("CreateCall", function(data, cb)
    CreateCall(data)
    cb("ok")
end)

-- =====================================================
-- NUI Callback: "GetSettings"
-- Returns current phone settings to the NUI.
-- =====================================================
RegisterNUICallback("GetSettings", function(_, cb)
    cb(settings)
end)

-- =====================================================
-- NUI Callback: "GetLocale"
-- Returns a localised string for the given path/format.
-- =====================================================
RegisterNUICallback("GetLocale", function(data, cb)
    -- data.path may arrive as lowercase from the UI (e.g. "setup.hello")
    -- L() handles uppercase fallback internally, so this is fine
    local path = data.path or ""
    cb(L(path, data.format))
end)

-- =====================================================
-- NUI Callback: "SendNotification"
-- Sends a phone notification from a custom app.
-- Button callbacks are stripped (unsupported from NUI).
-- =====================================================
RegisterNUICallback("SendNotification", function(data, cb)
    if data and data.customData and data.customData.buttons then
        data.customData.buttons = nil
        debugprint("You cannot create notifications with buttons from the NUI.")
    end

    TriggerEvent("phone:sendNotification", data)
    cb(true)
end)