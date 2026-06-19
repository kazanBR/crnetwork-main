-- =====================================================
--  lb-phone · client/client.lua
--  Deobfuscated by Eazy Fxap
-- =====================================================

phoneData = nil
currentPhone = nil
settings = nil
phoneOpen = false
SavedLocations = {}
PhoneOnScreen = false

local cachedPhoneNumber = nil
local hasLoadedPhone = nil
local fetchingPhone = false
local configReceived = nil
local togglingPhone = false
local focusToggleBusy = false

local function NormalizeLocaleCode(locale)
    if type(locale) ~= "string" or locale == "" then
        return "en"
    end

    local normalized = locale:lower():gsub("_", "-"):gsub("%.json$", "")

    if normalized == "cn" or normalized == "zh" then
        return "zh-cn"
    end

    return normalized
end

local function waitForConfig()
    if configReceived then
        return
    end

    debugprint("waiting for config to be received")

    while not configReceived do
        Wait(0)
    end

    debugprint("config received")
end

local function loadJsonConfig(fileName)
    local fileContent = GetConfigFile(fileName)

    if not fileContent then
        return nil
    end

    return json.decode(fileContent)
end

local function GetLocaleConfig(locale)
    locale = NormalizeLocaleCode(locale or Config.DefaultLocale or "en")

    local localeData = loadJsonConfig("locales/" .. locale .. ".json")
    if localeData then
        return localeData, locale
    end

    if locale ~= "en" then
        localeData = loadJsonConfig("locales/en.json")

        if localeData then
            return localeData, "en"
        end
    end

    return nil, locale
end

local function SendPhoneDataToUI()
    if not phoneData then
        return
    end

    local phoneNumber = phoneData.phoneNumber

    SendNUIAction("setPhoneData", phoneData)

    SetTimeout(300, function()
        if phoneData and phoneData.phoneNumber == phoneNumber then
            SendNUIAction("setPhoneData", phoneData)
        end
    end)
end

function FetchPhone()
    debugprint("FetchPhone triggered")

    if fetchingPhone then
        debugprint("already fetching phone")
        return
    end

    if not configReceived then
        debugprint("config has not been received by the UI yet")
        return
    end

    fetchingPhone = true

    while not FrameworkLoaded do
        debugprint("waiting for framework to load")
        Wait(500)
    end

    debugprint("triggering phone:playerLoaded")

    local phoneNumber

    if hasLoadedPhone and currentPhone then
        phoneNumber = cachedPhoneNumber
    else
        phoneNumber = AwaitCallback("playerLoaded")
        cachedPhoneNumber = phoneNumber
        hasLoadedPhone = true
    end

    debugprint("got number", phoneNumber)

    if not phoneNumber then
        debugprint("no number, checking if player has item")

        if HasPhoneItem() then
            debugprint("player has item; triggering phone:generatePhoneNumber")
            phoneNumber = AwaitCallback("generatePhoneNumber")
            debugprint("got number", phoneNumber)
        else
            debugprint("player does not have item")
        end
    end

    if not phoneNumber then
        fetchingPhone = false

        if currentPhone then
            debugprint("no number. using SetPhone")
            SetPhone()
        end

        debugprint("no number, returning")
        return
    end

    local defaultSettings = loadJsonConfig("defaultSettings.json")
    local latestVersion = AwaitCallback("getLatestVersion")
    local resourceVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)

    latestVersion = latestVersion or resourceVersion

    local _, resolvedDefaultLocale = GetLocaleConfig(Config.DefaultLocale)
    defaultSettings.locale = resolvedDefaultLocale
    defaultSettings.version = resourceVersion
    defaultSettings.latestVersion = latestVersion

    debugprint("fetching phone data")

    local loadedPhoneData = AwaitCallback("getPhone", phoneNumber)

    debugprint("got phone data", json.encode(loadedPhoneData))

    if loadedPhoneData then
        local savedLocale = defaultSettings.locale
        local localeWasNormalized = false

        if loadedPhoneData.settings then
            defaultSettings = loadedPhoneData.settings
            savedLocale = defaultSettings.locale
        end

        local _, resolvedLocale = GetLocaleConfig(defaultSettings.locale or Config.DefaultLocale)
        defaultSettings.locale = resolvedLocale
        localeWasNormalized = savedLocale ~= nil and savedLocale ~= defaultSettings.locale

        if loadedPhoneData.name then
            defaultSettings.name = loadedPhoneData.name
        else
            local characterName = AwaitCallback("getCharacterName")

            defaultSettings.name = L("BACKEND.MISC.X_PHONE", {
                name = characterName.firstname,
                lastname = characterName.lastname
            })
        end

        defaultSettings.version = resourceVersion
        defaultSettings.latestVersion = latestVersion
        SavedLocations = AwaitCallback("maps:getSavedLocations")
        currentPhone = phoneNumber

        phoneData = {
            isSetup = loadedPhoneData.is_setup or false,
            phoneNumber = phoneNumber,
            settings = defaultSettings,
            battery = (Config.Battery.Enabled and loadedPhoneData.battery) or 100,
            serverIdentifier = GetCurrentServerEndpoint()
        }

        waitForConfig()

        debugprint("triggering phone:setPhoneData")
        SendPhoneDataToUI()
        TriggerEvent("lb-phone:numberChanged", phoneNumber)

        if localeWasNormalized then
            debugprint("normalizing legacy locale", savedLocale, "->", defaultSettings.locale)
            AwaitCallback("setSettings", defaultSettings)
        end

        Wait(250)
    end

    if FetchCryptoCoins then
        FetchCryptoCoins()
    end

    settings = defaultSettings
    fetchingPhone = false
end

function RefreshPhone(skipFetch)
    debugprint("RefreshPhone triggered")

    if fetchingPhone then
        debugprint("phone is being fetched, waiting before refreshing")

        while fetchingPhone do
            Wait(0)
        end
    end

    if Config.DynamicWebRTC and Config.DynamicWebRTC.Enabled then
        local iceServers = AwaitCallback("getWebRTCCredentials")

        if Config.DynamicWebRTC.RemoveStun and iceServers then
            for i = #iceServers, 1, -1 do
                if not iceServers[i].credential then
                    table.remove(iceServers, i)
                end
            end
        end

        if iceServers then
            Config.RTCConfig = Config.RTCConfig or {}
            Config.RTCConfig.iceServers = iceServers
        end
    end

    configReceived = false

    local currentConfig = loadJsonConfig("config.json")
    local _, resolvedDefaultLocale = GetLocaleConfig(Config.DefaultLocale)

    currentConfig.valet = {
        enabled = Config.Valet.Enabled and true or false,
        price = Config.Valet.Price or 0,
        vehicleTypes = Config.Valet.VehicleTypes or { "car" }
    }

    currentConfig.locations = Config.Locations
    currentConfig.AllowExternal = Config.AllowExternal
    currentConfig.ExternalBlacklistedDomains = Config.ExternalBlacklistedDomains
    currentConfig.ExternalWhitelistedDomains = Config.ExternalWhitelistedDomains
    currentConfig.EmailDomain = Config.EmailDomain
    currentConfig.RealTime = Config.RealTime
    currentConfig.CurrencyFormat = Config.CurrencyFormat
    currentConfig.DeleteMessages = Config.DeleteMessages
    currentConfig.Battery = Config.Battery
    currentConfig.rtc = Config.RTCConfig
    currentConfig.PromoteBirdy = Config.PromoteBirdy
    currentConfig.Verified = Config.Verified
    currentConfig.LiveTray = Config.LiveTray
    currentConfig.SetupScreen = Config.SetupScreen
    currentConfig.MaxTransferAmount = Config.MaxTransferAmount
    currentConfig.EnableMessagePay = Config.EnableMessagePay
    currentConfig.EnableGIFs = Config.EnableGIFs
    currentConfig.GIFsFilter = Config.GIFsFilter or "low"
    currentConfig.EnableVoiceMessages = Config.EnableVoiceMessages
    currentConfig.DefaultLocale = resolvedDefaultLocale
    currentConfig.DateLocale = Config.DateLocale
    currentConfig.Debug = Config.Debug
    currentConfig.TikTokTTS = Config.TrendyTTS or {
        { "English (US) - Female", "en_us_001" }
    }
    currentConfig.recordNearbyVoices = Config.Voice.RecordNearby
    currentConfig.frameColor = Config.FrameColor
    currentConfig.allowFrameColorChange = Config.AllowFrameColorChange
    currentConfig.unlockPhoneKey = Config.KeyBinds.UnlockPhone and Config.KeyBinds.UnlockPhone.Bind or nil
    currentConfig.DeleteMail = Config.DeleteMail
    currentConfig.ChangePassword = Config.ChangePassword
    currentConfig.DeleteAccount = Config.DeleteAccount
    currentConfig.CustomCamera = (Config.Camera and Config.Camera.Walkable) or false
    currentConfig.UsernameFilter = (Config.UsernameFilter and Config.UsernameFilter.Regex) or "[a-zA-Z0-9]+"
    currentConfig.CryptoLimit = (Config.Crypto and Config.Crypto.Limits) or {
        Buy = 1000000,
        Sell = 1000000
    }
    currentConfig.Browser = Config.Browser
    currentConfig.CustomMaps = Config.CustomMaps
    currentConfig.sound = {
        system = Config.Sound.System,
        ringtones = Config.Sound.Ringtones,
        notifications = Config.Sound.Notifications,
        appNotifications = Config.Sound.AppNotifications
    }
    currentConfig.AppDownloadTime = Config.AppDownloadTime
    currentConfig.Pages = Config.Pages
    currentConfig.Marketplace = Config.Marketplace
    currentConfig.PhoneNumberLength = (Config.PhoneNumber.Length or 7) + (#Config.PhoneNumber.Prefixes > 0 and #Config.PhoneNumber.Prefixes[1] or 0)
    currentConfig.Format = Config.PhoneNumber.Format
    currentConfig.imageOptions = {
        mime = (Config.Image and Config.Image.Mime) or "image/png",
        quality = (Config.Image and Config.Image.Quality) or 1.0
    }
    currentConfig.videoOptions = {
        bitrate = (Config.Video and Config.Video.Bitrate) or 250,
        audioBitrate = (Config.Video and Config.Video.AudioBitrate) or 128,
        variableBitrate = (Config.Video and Config.Video.VariableBitrate) or false,
        size = (Config.Video and Config.Video.MaxSize) or 10,
        duration = (Config.Video and Config.Video.MaxDuration) or 60,
        fps = (Config.Video and Config.Video.FrameRate) or 24
    }
    currentConfig.Companies = table.deep_clone(Config.Companies)

    if currentConfig.Companies and currentConfig.Companies.Services then
        for i = 1, #currentConfig.Companies.Services do
            if currentConfig.Companies.Services[i].onCustomIconClick then
                currentConfig.Companies.Services[i].onCustomIconClick = true
            end
        end
    end

    if Config.CustomApps then
        for identifier, app in pairs(Config.CustomApps) do
            currentConfig.apps[identifier] = FormatCustomAppDataForUI(app)
        end
    end

    for appIdentifier, app in pairs(currentConfig.apps) do
        app.access = HasAccessToApp(appIdentifier)
    end

    currentConfig.defaultSettings = loadJsonConfig("defaultSettings.json")
    currentConfig.defaultSettings.locale = resolvedDefaultLocale

    local function removeDefaultApp(appName)
        local appRows = currentConfig.defaultSettings.apps

        for row = 1, #appRows do
            for index = 1, #appRows[row] do
                if appRows[row][index] == appName then
                    table.remove(appRows[row], index)
                    break
                end
            end
        end
    end

    if Config.Framework == "standalone" and not Config.CustomFramework then
        currentConfig.apps.Wallet = nil
        currentConfig.apps.Home = nil
        currentConfig.apps.Garage = nil
        currentConfig.apps.Services = nil

        removeDefaultApp("Wallet")
        removeDefaultApp("Home")
        removeDefaultApp("Garage")
        removeDefaultApp("Services")
    end

    if not Config.HouseScript then
        currentConfig.apps.Home = nil
        debugprint("No Config.HouseScript, removed home app")
        removeDefaultApp("Home")
    end

    if not (Config.Crypto and Config.Crypto.Enabled) then
        currentConfig.apps.Crypto = nil
        debugprint("Config.Crypto not enabled, removed crypto app")
        removeDefaultApp("Crypto")
    end

    for appIdentifier, hidden in pairs(GetHiddenApps()) do
        if currentConfig.apps[appIdentifier] then
            currentConfig.apps[appIdentifier].hidden = hidden
        end
    end

    SendNUIAction("setConfig", currentConfig)
    waitForConfig()

    if phoneData then
        debugprint("phoneData is defined")
        SendPhoneDataToUI()
        return
    end

    if not skipFetch then
        FetchPhone()
    end
end

RegisterNetEvent("lb-phone:jobUpdated", function(jobData)
    if not Config.WhitelistApps and not Config.BlacklistApps then
        return
    end

    debugprint("Job updated, refreshing whitelisted & blacklisted apps")

    local appAccess = {}

    for appIdentifier in pairs(Config.WhitelistApps or {}) do
        appAccess[appIdentifier] = HasAccessToApp(appIdentifier, jobData.job, jobData.grade)
    end

    for appIdentifier in pairs(Config.BlacklistApps or {}) do
        appAccess[appIdentifier] = HasAccessToApp(appIdentifier, jobData.job, jobData.grade)
    end

    for appIdentifier in pairs(Config.CustomApps or {}) do
        appAccess[appIdentifier] = HasAccessToApp(appIdentifier, jobData.job, jobData.grade)
    end

    SendNUIAction("app:setHasAccess", appAccess)
end)

RegisterNUICallback("configReceived", function(data, callback)
    debugprint("UI has received the config (configReceived triggered)")
    configReceived = true
    callback("ok")
end)

RegisterNUICallback("getPhoneData", function(data, callback)
    debugprint("getPhoneData triggered")

    while not FrameworkLoaded do
        Wait(500)
    end

    Wait(1000)
    RefreshPhone()

    if not callback then
        return debugprint("cb is not defined in getPhoneData", data)
    end

    callback(true)
end)

local function keepInputThread()
    local playerId = PlayerId()
    local controls = {
        199, 200, 24, 25, 69, 70, 91, 92, 106, 114, 140, 141, 142, 257, 263, 264, 330, 331
    }
    local focusedControls = {
        1, 2, 245, 14, 15, 16, 17, 37, 50, 99, 115, 180, 181, 198, 241, 242, 261, 262, 85
    }

    while phoneOpen do
        Wait(0)

        for i = 1, #controls do
            DisableControlAction(0, controls[i], true)
        end

        DisablePlayerFiring(playerId, true)

        if IsNuiFocused() then
            for i = 1, #focusedControls do
                DisableControlAction(0, focusedControls[i], true)
            end
        end
    end

    while IsDisabledControlPressed(0, 200) do
        DisableControlAction(0, 200, true)
        Wait(0)
    end

    if cameraOpen and IsWalkingCamEnabled() then
        local wasSelfie = IsSelfieCam()

        DisableWalkableCam()

        while not phoneOpen do
            Wait(500)
        end

        if cameraOpen then
            SetPhoneAction("camera")
            EnableWalkableCam(wasSelfie)
        end
    end
end

local function isPushToTalkHeld()
    return (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249)
end

function ToggleOpen(open, noFocus)
    if togglingPhone then
        return
    end

    if type(open) ~= "boolean" then
        open = not phoneOpen
    end

    open = open == true

    debugprint("ToggleOpen triggered", tostring(open), tostring(noFocus))

    if phoneDisabled and open then
        debugprint("phone is disabled, returning")
        return
    end

    if phoneOpen == open then
        debugprint("phoneOpen & open are both the same value, returning")
        return
    end

    if open and not FrameworkLoaded then
        infoprint("warning", "Framework not loaded")
        return
    end

    if open and IsPedDeadOrDying(PlayerPedId(), true) then
        debugprint("player ped is dead/dying, returning")
        return
    end

    if open and CanOpenPhone and not CanOpenPhone() then
        debugprint("CanOpenPhone returned false, returning")
        return
    end

    if open and not ValidateChecks("openPhone") then
        debugprint("ValidateChecks returned false for openPhone, returning")
        return
    end

    if open and IsNuiFocused() and Config.DisableOpenNUI then
        infoprint("info", "Not opening the phone as another script has NUI focus. You can disable this behavior by setting Config.DisableOpenNUI to false.")
        return
    end

    if open and GetResourceState("lb-tablet") == "started" and not Config.DisableTabletOpenPhone then
        local ok, tabletOpen = pcall(function()
            return exports["lb-tablet"]:IsOpen()
        end)

        if ok and tabletOpen then
            infoprint("info", "Not opening the phone as the tablet is open. You can disable this behavior by adding Config.DisableTabletOpenPhone = true to the config.")
            return
        end
    end

    if fetchingPhone then
        togglingPhone = true

        while fetchingPhone do
            Wait(0)
        end

        togglingPhone = false
    end

    if open and not currentPhone then
        debugprint("no phone, fetching")
        FetchPhone()

        if not currentPhone then
            debugprint("still no phone after fetching, returning")
            return
        end
    end

    if open and not HasPhoneItem(currentPhone) then
        debugprint("HasPhoneItem returned false. Phone number:", tostring(currentPhone))
        TriggerServerEvent("phone:togglePhone")
        SendNUIAction("closePhone")
        return
    end

    if not open and IsWalkingCamEnabled() and IsSelfieCam() then
        ToggleSelfieCam(false)
    end

    if not open and Config.EndLiveClose then
        local liveId = IsWatchingLive()

        EndLive()

        if liveId then
            SendNUIAction("instagram:liveEnded", liveId)
        end
    end

    phoneOpen = open
    togglingPhone = true

    if open then
        debugprint("should open phone. sending openPhone event to ui")
        SendNUIAction("openPhone")

        if not noFocus then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(Config.KeepInput)
        end

        if Config.KeepInput then
            CreateThread(keepInputThread)
        end

        if ControllerThread then
            CreateThread(ControllerThread)
        end

        debugprint("setting animation action")

        if IsWalkingCamEnabled() then
            SetPhoneAction("camera")
        elseif IsInCall() then
            SetPhoneAction("call")
        else
            SetPhoneAction("default")
        end
    else
        debugprint("sending closePhone event to ui")
        PlayCloseAnim()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIAction("closePhone")
    end

    TriggerServerEvent("phone:togglePhone", open)
    TriggerEvent("lb-phone:phoneToggled", open)

    togglingPhone = false
end

RegisterNUICallback("toggleInput", function(data, callback)
    callback("ok")

    if not Config.KeepInput then
        return
    end

    if isPushToTalkHeld() then
        if data then
            debugprint("PTT is pressed, ignoring toggle focus")
            return
        end

        debugprint("PTT is pressed, waiting before toggling focus")

        while isPushToTalkHeld() do
            Wait(100)
        end
    end

    if data then
        Wait(200)
    end

    SetNuiFocusKeepInput(not data)
end)

AddEventHandler("lb-phone:keyPressed", function(key)
    if IsPauseMenuActive() then
        return
    end

    if key == "Open" then
        debugprint("Pressed open keybind")
        ToggleOpen(not phoneOpen)
    elseif key == "Focus" then
        if not phoneOpen or focusToggleBusy then
            return
        end

        if isPushToTalkHeld() then
            debugprint("PTT is pressed, waiting before toggling focus")
            focusToggleBusy = true

            while IsDisabledControlPressed(0, 249) or IsDisabledControlJustReleased(0, 249) do
                Wait(0)
            end

            focusToggleBusy = false
        end

        local focused = IsNuiFocused()

        SetNuiFocus(not focused, not focused)

        if not focused then
            SetNuiFocusKeepInput(Config.KeepInput)
        else
            SetNuiFocusKeepInput(false)
        end
    elseif key == "StopSounds" then
        SendNUIAction("stopSounds")
    end

    if key == "AnswerCall" or key == "DeclineCall" then
        if CanOpenPhone then
            if not CanOpenPhone() then
                debugprint("CanOpenPhone returned false, not answering/declining call")
                return
            end
        elseif not ValidateChecks("openPhone") then
            debugprint("ValidateChecks returned false for openPhone, not answering/declining call")
            return
        end

        if key == "AnswerCall" then
            SendNUIAction("usedCommand", "answer")
        elseif key == "DeclineCall" then
            SendNUIAction("usedCommand", "decline")
        end
    end

    if key == "TakePhoto" then
        SendNUIAction("camera:usedCommand", "toggleTaking")
    elseif key == "ToggleFlash" then
        SendNUIAction("camera:usedCommand", "toggleFlash")
    elseif key == "LeftMode" then
        SendNUIAction("camera:usedCommand", "leftMode")
    elseif key == "RightMode" then
        SendNUIAction("camera:usedCommand", "rightMode")
    elseif key == "FlipCamera" then
        SendNUIAction("camera:usedCommand", "toggleFlip")
    end
end)

for key, keyBind in pairs(Config.KeyBinds) do
    if keyBind.Command then
        keyBind.Command = keyBind.Command:lower()

        if keyBind.Bind then
            keyBind.bindData = AddKeyBind({
                name = keyBind.Command,
                description = keyBind.Description or "no description",
                defaultKey = keyBind.Bind,
                defaultMapper = keyBind.Mapper,
                secondaryKey = keyBind.SecondaryBind,
                secondaryMapper = keyBind.SecondaryMapper,
                onPress = function()
                    TriggerEvent("lb-phone:keyPressed", key)
                end,
                onRelease = function(data)
                    TriggerEvent("lb-phone:keyReleased", key, data)
                end
            })
        else
            RegisterCommand(keyBind.Command, function()
                TriggerEvent("lb-phone:keyPressed", key)
                Wait(0)
                TriggerEvent("lb-phone:keyReleased", key, 0)
            end, false)
        end
    end
end

RegisterNUICallback("finishedSetup", function(data, callback)
    if phoneData then
        phoneData.isSetup = true
    end

    SendNUIAction("setName", data.name)
    TriggerServerEvent("phone:setName", data.name)
    TriggerServerEvent("phone:togglePhone", phoneOpen)
    TriggerServerEvent("phone:finishedSetup", data)

    if Config.AutoBackup then
        TriggerCallback("backup:createBackup")
    end

    callback("ok")
end)

RegisterNUICallback("isAdmin", function(data, callback)
    TriggerCallback("isAdmin", callback)
end)

RegisterNUICallback("setPhoneName", function(data, callback)
    if phoneData and phoneData.isSetup then
        if settings then
            settings.name = data
        end

        TriggerServerEvent("phone:setName", data)
    end

    callback("ok")
end)

RegisterNUICallback("setSettings", function(data, callback)
    debugprint("setSettings triggered")
    callback("ok")

    if not phoneData then
        print("setSettings triggered, but phoneData is nil")
        return
    end

    if data and data.locale then
        local _, resolvedLocale = GetLocaleConfig(data.locale)
        data.locale = resolvedLocale
    end

    settings = data
    phoneData.settings = settings

    AwaitCallback("setSettings", settings)
    SetCallVolume(settings and settings.sound and settings.sound.callVolume)
    TriggerEvent("lb-phone:settingsUpdated", data)
    SendNUIAction("customApp:sendMessage", {
        identifier = "any",
        message = {
            type = "settingsUpdated",
            settings = settings,
            action = "settingsUpdated",
            data = data
        }
    })
end)

RegisterNUICallback("setCursorLocation", function(data, callback)
    local width, height = GetActiveScreenResolution()

    SetCursorLocation(data.x / width, data.y / height)
    callback("ok")
end)

RegisterNUICallback("exitFocus", function(data, callback)
    debugprint("exitFocus triggered")
    SetNuiFocus(false, false)
    ToggleOpen(false)
    callback("ok")
end)

RegisterNUICallback("getLocales", function(data, callback)
    local locales = {}

    for key, value in pairs(Config.Locales or { en = "English" }) do
        local locale = key
        local label = value

        if type(value) == "table" then
            locale = value.locale
            label = value.name
        end

        if locale and GetLocaleConfig(locale) then
            locales[#locales + 1] = {
                locale = NormalizeLocaleCode(locale),
                name = type(label) == "string" and label or locale
            }
        end
    end

    table.sort(locales, function(a, b)
        return a.name < b.name
    end)

    callback(locales)
end)

RegisterNUICallback("setOnScreen", function(data, callback)
    data = data == true

    if data ~= PhoneOnScreen then
        TriggerEvent("lb-phone:setOnScreen", data)
        PhoneOnScreen = data
    end

    callback("ok")
end)

RegisterNUICallback("restartPhone", function(data, callback)
    callback("ok")
    ToggleOpen(false)
    Wait(1000)
    ToggleOpen(true)
end)

exports("IsPhoneOnScreen", function()
    return PhoneOnScreen
end)

CreateThread(function()
    local previousTime = {}

    debugprint("Waiting for currentPhone to be set before updating time & service")

    while not currentPhone do
        Wait(500)
    end

    SendNUIAction("updateService", GetServiceBars())
    debugprint("currentPhone is set, updating time & service")

    while not Config.RealTime do
        local time = Config.CustomTime and Config.CustomTime() or {
            hour = GetClockHours(),
            minute = GetClockMinutes()
        }

        if time.hour ~= previousTime.hour or time.minute ~= previousTime.minute then
            previousTime.hour = time.hour
            previousTime.minute = time.minute
            SendNUIAction("updateTime", time)
        end

        Wait(1000)
    end
end)

function GetConfigFile(fileName)
    if type(fileName) == "string" then
        local locale = fileName:match("^locales/(.+)%.json$")

        if locale then
            fileName = "locales/" .. NormalizeLocaleCode(locale) .. ".json"
        end
    end

    return LoadResourceFile(GetCurrentResourceName(), "config/" .. fileName)
end

RegisterNUICallback("getConfigFile", function(data, callback)
    if type(data) ~= "string" then
        callback(nil)
        return
    end

    if data:sub(1, 8) == "locales/" then
        local locale = data:match("^locales/(.+)$")
        local localeData = GetLocaleConfig(locale)

        callback(localeData)
        return
    end

    callback(loadJsonConfig(data .. ".json"))
end)

local nearbyPlayers = {}
local lastNearbyCoords = vector3(0.0, 0.0, 0.0)
local lastNearbyUpdate = 0

local function updateNearbyPlayers()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local activePlayers = GetActivePlayers()
    local players = {}

    for i = 1, #activePlayers do
        local player = activePlayers[i]

        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local coords = GetEntityCoords(ped)
            local distance = #(playerCoords - coords)

            if distance <= 50.0 then
                players[#players + 1] = {
                    player = player,
                    source = GetPlayerServerId(player),
                    ped = ped,
                    coords = coords
                }
            end
        end
    end

    nearbyPlayers = players
end

function GetNearbyPlayers()
    local shouldUpdate = GetGameTimer() - lastNearbyUpdate > 5000

    if not shouldUpdate then
        shouldUpdate = #(GetEntityCoords(PlayerPedId()) - lastNearbyCoords) > 25.0
    end

    if shouldUpdate then
        lastNearbyUpdate = GetGameTimer()
        lastNearbyCoords = GetEntityCoords(PlayerPedId())
        updateNearbyPlayers()
    end

    return nearbyPlayers
end

function LogOut()
    debugprint("LogOut triggered")

    while fetchingPhone do
        debugprint("LogOut triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end

    ResetSecurity()
    OnDeath()

    phoneData = nil
    currentPhone = nil
    settings = nil

    TriggerEvent("lb-phone:numberChanged", nil)
    TriggerCallback("setLastPhone")
end

function SetPhone(phoneNumber, refetch)
    debugprint("SetPhone triggered", phoneNumber, refetch)

    while fetchingPhone do
        debugprint("SetPhone triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end

    OnDeath()
    AwaitCallback("setLastPhone", phoneNumber)
    ResetSecurity(true)
    ToggleCharging(false)

    phoneData = nil
    currentPhone = nil
    settings = nil

    TriggerEvent("lb-phone:numberChanged", nil)

    if phoneNumber or refetch then
        FetchPhone()
    end

    if phoneNumber == nil and not refetch then
        local firstNumber = GetFirstNumber()

        if firstNumber then
            SetPhone(firstNumber)
        end
    end
end

function OnDeath()
    debugprint("OnDeath triggered")

    local liveId = IsWatchingLive()

    EndLive()

    if liveId then
        SendNUIAction("instagram:liveEnded", liveId)
    end

    if flashlightEnabled then
        flashlightEnabled = false
        TriggerServerEvent("phone:toggleFlashlight", false)
    end

    EndCall()
    ToggleOpen(false)
end

RegisterNetEvent("phone:toggleOpen", ToggleOpen)
exports("ToggleOpen", ToggleOpen)

exports("IsOpen", function()
    return phoneOpen
end)

exports("IsDisabled", function()
    return phoneDisabled
end)

exports("ToggleDisabled", function(disabled)
    phoneDisabled = disabled == true

    debugprint("ToggleDisabled triggered", phoneDisabled)

    if phoneDisabled and phoneOpen then
        ToggleOpen(false)
    end
end)

exports("GetSettings", function()
    return settings
end)

exports("GetAirplaneMode", function()
    return settings and settings.airplaneMode
end)

exports("GetStreamerMode", function()
    return settings and settings.streamerMode
end)

exports("GetEquippedPhoneNumber", function()
    return currentPhone
end)
