local DisableControl    = DisableControlAction
local IsNuiFocused      = IsNuiFocused
local DisableFiring     = DisablePlayerFiring

-- Global state
phoneData     = nil
currentPhone  = nil
settings      = nil
phoneOpen     = false

SavedLocations  = {}
PhoneOnScreen   = false

-- Internal flags
local fetchingPhone    = nil   -- AKL4_1: phone already loaded once
local isFetchingPhone  = nil   -- AKL5_1: fetch in progress
local configReceived   = nil   -- AKL6_1: UI has received config

-- ─────────────────────────────────────────────
--  Early global definitions
--  These must be available before other client
--  files load (cellTowers, crypto, recordNearby)
--  and before they are used later in this file.
-- ─────────────────────────────────────────────

-- SendReactMessage: sends a message to the NUI layer
function SendReactMessage(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- GetConfigFile: loads a JSON file from config/ folder
function GetConfigFile(filename)
    return LoadResourceFile(GetCurrentResourceName(), "config/" .. filename)
end

-- GetNearbyPlayers: returns cached nearby player list
-- (full implementation is later in this file; this stub
-- ensures the global exists for files that load early)
local nearbyPlayers    = {}
local lastNearbyPos    = vector3(0.0, 0.0, 0.0)
local lastNearbyRefresh = 0

function GetNearbyPlayers()
    local now   = GetGameTimer()
    local myPos = GetEntityCoords(PlayerPedId())
    local timePassed = now - lastNearbyRefresh > 5000
    local movedFar   = #(myPos - lastNearbyPos) > 25.0
    if timePassed or movedFar then
        lastNearbyRefresh = now
        lastNearbyPos     = myPos
        local myId = PlayerId()
        local result = {}
        for _, pid in ipairs(GetActivePlayers()) do
            if pid ~= myId then
                local ped    = GetPlayerPed(pid)
                local coords = GetEntityCoords(ped)
                local dist   = #(myPos - coords)
                if dist <= 50.0 then
                    result[#result + 1] = {
                        player = pid,
                        source = GetPlayerServerId(pid),
                        ped    = ped,
                        coords = coords,
                    }
                end
            end
        end
        nearbyPlayers = result
    end
    return nearbyPlayers
end

-- OnDeath: stub defined early, full impl replaces later
function OnDeath()
    if ToggleOpen then ToggleOpen(false) end
end

-- ─────────────────────────────────────────────
--  WaitForConfig
--  Blocks until the UI signals configReceived.
-- ─────────────────────────────────────────────
local function WaitForConfig()
    if configReceived then return end
    debugprint("waiting for config to be received")
    while not configReceived do
        Wait(0)
    end
    debugprint("config received")
end

-- ─────────────────────────────────────────────
--  GetServerIdentifier
--  Extracts a clean server ID from the base URL.
-- ─────────────────────────────────────────────
local function GetServerIdentifier()
    local url = GetBaseUrl()
    local result = url

    if string.find(url, "%.users%.cfx%.re") then
        local len      = #url
        local reversed = string.reverse(url)
        local dashPos  = string.find(reversed, "-")
        if not dashPos then
            dashPos = len + 1
        end
        local start  = len - dashPos + 2
        local suffix = ".users.cfx.re"
        local finish = len - #suffix
        result = string.sub(url, start, finish)
    end

    return result
end

-- ─────────────────────────────────────────────
--  FetchPhone
--  Loads the player's phone number and data
--  from the server for the first time.
-- ─────────────────────────────────────────────
local function FetchPhone()
    debugprint("FetchPhone triggered")

    if isFetchingPhone then
        debugprint("already fetching phone")
        return
    end

    if not configReceived then
        debugprint("config has not been received by the UI yet")
        return
    end

    isFetchingPhone = true

    -- Wait for the framework to finish loading
    while not FrameworkLoaded do
        debugprint("waiting for framework to load")
        Wait(500)
    end

    debugprint("triggering phone:playerLoaded")

    -- Retrieve (or reuse) the player's phone number
    local phoneNumber
    if fetchingPhone and currentPhone then
        phoneNumber = SavedLocations  -- reuse cached number
    else
        phoneNumber   = AwaitCallback("playerLoaded")
        SavedLocations = phoneNumber  -- store for reuse
        fetchingPhone  = true
    end

    debugprint("got number", phoneNumber)

    -- If no number yet, check if the player has the phone item
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

    -- Still no number — abort
    if not phoneNumber then
        isFetchingPhone = false
        if currentPhone then
            debugprint("no number. using SetPhone")
            SetPhone()
        end
        debugprint("no number, returning")
        return
    end

    -- Load default settings
    local defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))

    -- Version info
    local latestVersion = AwaitCallback("getLatestVersion")
    local resourceName  = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, "version", 0)
    if not latestVersion then
        latestVersion = currentVersion
    end

    defaultSettings.locale        = Config.DefaultLocale
    defaultSettings.version       = currentVersion
    defaultSettings.latestVersion = latestVersion

    -- Fetch full phone data from server
    local isSetup = false
    debugprint("fetching phone data")
    local phone = AwaitCallback("getPhone", phoneNumber)
    debugprint("got phone data", json.encode(phone))

    if phone then
        -- Use phone's own settings if available
        if phone.settings then
            defaultSettings = phone.settings
        end

        -- Display name
        if phone.name then
            defaultSettings.name = phone.name
        else
            local charName = AwaitCallback("getCharacterName")
            defaultSettings.name = L("BACKEND.MISC.X_PHONE", {
                name     = charName.firstname,
                lastname = charName.lastname,
            })
        end

        defaultSettings.version       = currentVersion
        defaultSettings.latestVersion = latestVersion

        -- Saved map locations
        SavedLocations = AwaitCallback("maps:getSavedLocations")

        isSetup    = phone.is_setup or false
        currentPhone = phoneNumber

        -- Build phoneData table
        local battery = 100
        if Config.Battery and Config.Battery.Enabled then
            battery = phone.battery or 100
        end

        phoneData = {
            isSetup          = isSetup,
            phoneNumber      = phoneNumber,
            settings         = defaultSettings,
            battery          = battery,
            serverIdentifier = GetServerIdentifier(),
        }

        WaitForConfig()

        debugprint("triggering phone:setPhoneData")
        SendReactMessage("setPhoneData", phoneData)
        TriggerEvent("lb-phone:numberChanged", phoneNumber)
        Wait(250)
    end

    -- Fetch crypto coins if available
    if FetchCryptoCoins then
        FetchCryptoCoins()
    end

    settings        = defaultSettings
    isFetchingPhone = false
end

-- Expose globally
FetchPhone = FetchPhone

-- ─────────────────────────────────────────────
--  RefreshPhone (also assigned to FetchPhone
--  at the end of the original — kept as-is)
-- ─────────────────────────────────────────────
local function RefreshPhone(skipFetch)
    debugprint("RefreshPhone triggered")

    -- Wait if a fetch is already running
    if isFetchingPhone then
        debugprint("phone is being fetched, waiting before refreshing")
        while isFetchingPhone do
            Wait(0)
        end
    end

    -- Handle dynamic WebRTC credentials
    if Config.DynamicWebRTC and Config.DynamicWebRTC.Enabled then
        local iceServers = AwaitCallback("getWebRTCCredentials")

        -- Remove STUN-only entries if configured
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

    -- Mark config as not yet received so UI re-sends it
    configReceived = false

    -- Decode main config
    local cfg = json.decode(GetConfigFile("config.json"))

    -- Valet settings
    local valetEnabled = Config.Valet and Config.Valet.Enabled or false
    local valet = {
        enabled      = valetEnabled,
        price        = Config.Valet.Price or 0,
        vehicleTypes = Config.Valet.VehicleTypes or { "car" },
    }
    cfg.valet = valet

    -- Copy top-level config values into cfg
    cfg.locations                  = Config.Locations
    cfg.AllowExternal              = Config.AllowExternal
    cfg.ExternalBlacklistedDomains = Config.ExternalBlacklistedDomains
    cfg.ExternalWhitelistedDomains = Config.ExternalWhitelistedDomains
    cfg.EmailDomain                = Config.EmailDomain
    cfg.RealTime                   = Config.RealTime
    cfg.CurrencyFormat             = Config.CurrencyFormat
    cfg.DeleteMessages             = Config.DeleteMessages
    cfg.Battery                    = Config.Battery
    cfg.rtc                        = Config.RTCConfig
    cfg.PromoteBirdy               = Config.PromoteBirdy
    cfg.DynamicIsland              = Config.DynamicIsland
    cfg.SetupScreen                = Config.SetupScreen
    cfg.MaxTransferAmount          = Config.MaxTransferAmount
    cfg.EnableMessagePay           = Config.EnableMessagePay
    cfg.EnableGIFs                 = Config.EnableGIFs
    cfg.GIFsFilter                 = Config.GIFsFilter or "low"
    cfg.EnableVoiceMessages        = Config.EnableVoiceMessages
    cfg.DefaultLocale              = Config.DefaultLocale
    cfg.DateLocale                 = Config.DateLocale
    cfg.Debug                      = Config.Debug
    cfg.TikTokTTS                  = Config.TrendyTTS or {{ "English (US) - Female", "en_us_001" }}
    cfg.recordNearbyVoices         = Config.Voice and Config.Voice.RecordNearby
    cfg.frameColor                 = Config.FrameColor
    cfg.allowFrameColorChange      = Config.AllowFrameColorChange
    cfg.unlockPhoneKey             = Config.KeyBinds and Config.KeyBinds.UnlockPhone and Config.KeyBinds.UnlockPhone.Bind or nil
    cfg.DeleteMail                 = Config.DeleteMail
    cfg.ChangePassword             = Config.ChangePassword
    cfg.DeleteAccount              = Config.DeleteAccount
    cfg.CustomCamera               = (Config.Camera and Config.Camera.Walkable) or false
    cfg.UsernameFilter             = (Config.UsernameFilter and Config.UsernameFilter.Regex) or "[a-zA-Z0-9]+"

    -- Crypto limits
    if Config.Crypto and Config.Crypto.Limits then
        cfg.CryptoLimit = Config.Crypto.Limits
    else
        cfg.CryptoLimit = { Buy = 1000000, Sell = 1000000 }
    end

    cfg.Browser    = Config.Browser
    cfg.CustomMaps = Config.CustomMaps

    -- Sound settings
    cfg.sound = {
        system           = Config.Sound.System,
        ringtones        = Config.Sound.Ringtones,
        notifications    = Config.Sound.Notifications,
        appNotifications = Config.Sound.AppNotifications,
    }

    cfg.AppDownloadTime = Config.AppDownloadTime

    -- Phone number length
    local numLength    = Config.PhoneNumber.Length or 7
    local prefixes     = Config.PhoneNumber.Prefixes
    local prefixLength = (#prefixes > 0) and #prefixes[1] or 0
    cfg.PhoneNumberLength = numLength + prefixLength
    cfg.Format            = Config.PhoneNumber.Format

    -- Image options
    cfg.imageOptions = {
        mime    = (Config.Image and Config.Image.Mime)    or "image/png",
        quality = (Config.Image and Config.Image.Quality) or 1.0,
    }

    -- Video options
    cfg.videoOptions = {
        bitrate  = (Config.Video and Config.Video.Bitrate)     or 250,
        size     = (Config.Video and Config.Video.MaxSize)     or 10,
        duration = (Config.Video and Config.Video.MaxDuration) or 60,
        fps      = (Config.Video and Config.Video.FrameRate)   or 24,
    }

    -- Companies — deep clone and flag custom icon handlers
    cfg.Companies = table.deep_clone(Config.Companies)
    if cfg.Companies and cfg.Companies.Services then
        for i = 1, #cfg.Companies.Services do
            if cfg.Companies.Services[i].onCustomIconClick then
                cfg.Companies.Services[i].onCustomIconClick = true
            end
        end
    end

    -- Custom apps
    if Config.CustomApps then
        for appId, appData in pairs(Config.CustomApps) do
            cfg.apps[appId] = FormatCustomAppDataForUI(appData)
        end
    end

    -- Set access flags on all apps
    for appId, appData in pairs(cfg.apps) do
        appData.access = HasAccessToApp(appId)
    end

    -- Default settings
    local defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))
    cfg.defaultSettings = defaultSettings

    -- Helper: remove an app from the default settings layout
    local function removeFromDefaultLayout(appId)
        local rows = cfg.defaultSettings.apps
        for rowIdx = 1, #rows do
            local row = rows[rowIdx]
            for colIdx = 1, #row do
                if row[colIdx] == appId then
                    table.remove(row, colIdx)
                    break
                end
            end
        end
    end

    -- Standalone framework: remove framework-dependent apps
    if Config.Framework == "standalone" and not Config.CustomFramework then
        cfg.apps.Wallet   = nil
        cfg.apps.Home     = nil
        cfg.apps.Garage   = nil
        cfg.apps.Services = nil
        removeFromDefaultLayout("Wallet")
        removeFromDefaultLayout("Home")
        removeFromDefaultLayout("Garage")
        removeFromDefaultLayout("Services")
    end

    -- No house script: remove home app
    if not Config.HouseScript then
        cfg.apps.Home = nil
        debugprint("No Config.HouseScript, removed home app")
        removeFromDefaultLayout("Home")
    end

    -- Crypto disabled: remove crypto app
    if not (Config.Crypto and Config.Crypto.Enabled) then
        cfg.apps.Crypto = nil
        debugprint("Config.Crypto not enabled, removed crypto app")
        removeFromDefaultLayout("Crypto")
    end

    -- Apply hidden-app flags
    for appId, isHidden in pairs(GetHiddenApps()) do
        if cfg.apps[appId] then
            cfg.apps[appId].hidden = isHidden
        end
    end

    -- Send config to UI
    SendReactMessage("setConfig", cfg)
    WaitForConfig()

    -- If phone data exists, resend it; otherwise fetch fresh
    if phoneData then
        debugprint("phoneData is defined")
        SendReactMessage("setPhoneData", phoneData)
        return
    end

    if skipFetch then return end

    FetchPhone()
end

RefreshPhone = RefreshPhone

-- ─────────────────────────────────────────────
--  Net event: job updated → refresh app access
-- ─────────────────────────────────────────────
RegisterNetEvent("lb-phone:jobUpdated")
AddEventHandler("lb-phone:jobUpdated", function(jobInfo)
    if not Config.WhitelistApps and not Config.BlacklistApps then return end

    debugprint("Job updated, refreshing whitelisted & blacklisted apps")

    local accessMap = {}

    for appId in pairs(Config.WhitelistApps or {}) do
        accessMap[appId] = HasAccessToApp(appId, jobInfo.job, jobInfo.grade)
    end

    for appId in pairs(Config.BlacklistApps or {}) do
        accessMap[appId] = HasAccessToApp(appId, jobInfo.job, jobInfo.grade)
    end

    for appId in pairs(Config.CustomApps or {}) do
        accessMap[appId] = HasAccessToApp(appId, jobInfo.job, jobInfo.grade)
    end

    SendReactMessage("app:setHasAccess", accessMap)
end)

-- ─────────────────────────────────────────────
--  NUI callback: UI signals config received
-- ─────────────────────────────────────────────
RegisterNUICallback("configReceived", function(_, cb)
    debugprint("UI has received the config (configReceived triggered)")
    configReceived = true
    cb("ok")
end)

-- ─────────────────────────────────────────────
--  NUI callback: UI requests phone data
-- ─────────────────────────────────────────────
RegisterNUICallback("getPhoneData", function(data, cb)
    debugprint("getPhoneData triggered")

    while not FrameworkLoaded do
        Wait(500)
    end

    Wait(1000)
    RefreshPhone()

    if not cb then
        debugprint("cb is not defined in getPhoneData", data)
        return
    end

    cb(true)
end)

-- ─────────────────────────────────────────────
--  KeepInput thread: disable game controls
--  while the phone is open (KeepInput mode).
-- ─────────────────────────────────────────────
local function KeepInputThread()
    local playerId = PlayerId()

    -- Block movement / combat controls while phone is open
    local blockedControls = {
        199, 200, 24, 25, 69, 70, 91, 92,
        106, 114, 140, 141, 142, 257, 263,
        264, 330, 331,
    }

    -- Extra controls blocked when NUI has focus
    local nuiFocusControls = {
        1, 2, 245, 14, 15, 16, 17, 37, 50,
        99, 115, 180, 181, 198, 241, 242,
        261, 262, 85,
    }

    while phoneOpen do
        Wait(0)

        for _, control in ipairs(blockedControls) do
            DisableControl(0, control, true)
        end
        DisableFiring(playerId, true)

        if IsNuiFocused() then
            for _, control in ipairs(nuiFocusControls) do
                DisableControl(0, control, true)
            end
        end
    end

    -- Keep blocking the scroll wheel until released
    while IsDisabledControlPressed(0, 200) do
        DisableControl(0, 200, true)
        Wait(0)
    end

    -- Handle walkable camera state on close
    if cameraOpen and IsWalkingCamEnabled() then
        local wasSelfie = IsSelfieCam()
        DisableWalkableCam()

        -- Wait until phone reopens
        while not phoneOpen do
            Wait(500)
        end

        if cameraOpen then
            SetPhoneAction("camera")
            EnableWalkableCam(wasSelfie)
        end
    end
end

-- ─────────────────────────────────────────────
--  toggleLock: internal mutex flag
-- ─────────────────────────────────────────────
local toggleLock = false

-- ─────────────────────────────────────────────
--  ToggleOpen
--  Opens or closes the phone UI.
-- ─────────────────────────────────────────────
local function ToggleOpen(open, keepFocus)
    if toggleLock then return end

    -- If not a boolean, invert current state
    if type(open) ~= "boolean" then
        open = not phoneOpen
    end

    open = open == true

    debugprint("ToggleOpen triggered", tostring(open), tostring(keepFocus))

    -- Guard: phone disabled
    if phoneDisabled and open then
        debugprint("phone is disabled, returning")
        return
    end

    -- Guard: state unchanged
    if phoneOpen == open then
        debugprint("phoneOpen & open are both the same value, returning")
        return
    end

    -- Guard: framework not ready
    if not FrameworkLoaded and open then
        infoprint("warning", "Framework not loaded")
        return
    end

    if open then
        -- Guard: player is dead
        if IsPedDeadOrDying(PlayerPedId(), true) then
            debugprint("player ped is dead/dying, returning")
            return
        end

        -- Guard: custom CanOpenPhone check
        if CanOpenPhone and not CanOpenPhone() then
            debugprint("CanOpenPhone returned false, returning")
            return
        end

        -- Guard: ValidateChecks
        if not ValidateChecks("openPhone") then
            debugprint("ValidateChecks returned false for openPhone, returning")
            return
        end

        -- Guard: another NUI has focus
        if IsNuiFocused() and Config.DisableOpenNUI then
            infoprint("info", "Not opening the phone as another script has NUI focus. You can disable this behavior by setting Config.DisableOpenNUI to false.")
            return
        end

        -- Guard: lb-tablet is open
        if GetResourceState("lb-tablet") == "started" and not Config.DisableTabletOpenPhone then
            local ok, tabletOpen = pcall(function()
                return exports["lb-tablet"]:IsOpen()
            end)
            if ok and tabletOpen then
                infoprint("info", "Not opening the phone as the tablet is open. You can disable this behavior by adding Config.DisableTabletOpenPhone = true to the config.")
                return
            end
        end
    end

    -- Wait for any in-progress fetch to finish
    if isFetchingPhone then
        toggleLock = true
        while isFetchingPhone do
            Wait(0)
        end
        toggleLock = false
    end

    -- Ensure the player has a phone number
    if open then
        if not currentPhone then
            debugprint("no phone, fetching")
            FetchPhone()
            if not currentPhone then
                debugprint("still no phone after fetching, returning")
                return
            end
        end
    end

    -- Ensure the player actually has the phone item
    if open then
        if not HasPhoneItem(currentPhone) then
            debugprint("HasPhoneItem returned false. Phone number:", tostring(currentPhone))
            TriggerServerEvent("phone:togglePhone")
            SendReactMessage("closePhone")
            return
        end
    end

    -- Close selfie cam when closing phone
    if not open and IsWalkingCamEnabled() and IsSelfieCam() then
        ToggleSelfieCam(false)
    end

    -- End live stream when closing phone
    if not open and Config.EndLiveClose then
        local wasWatching = IsWatchingLive()
        EndLive()
        if wasWatching then
            SendReactMessage("instagram:liveEnded", wasWatching)
        end
    end

    phoneOpen = open
    toggleLock = true

    if open then
        debugprint("should open phone. sending openPhone event to ui")
        SendReactMessage("openPhone")

        if not keepFocus then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(Config.KeepInput)
        end

        if Config.KeepInput then
            CreateThread(KeepInputThread)
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
        SendReactMessage("closePhone")
    end

    TriggerServerEvent("phone:togglePhone", open)
    TriggerEvent("lb-phone:phoneToggled", open)
    toggleLock = false
end

ToggleOpen = ToggleOpen

-- ─────────────────────────────────────────────
--  NUI callback: toggle NUI input focus
-- ─────────────────────────────────────────────
RegisterNUICallback("toggleInput", function(focused, cb)
    cb("ok")

    if not Config.KeepInput then return end

    -- Check push-to-talk state
    local pttPressed
    if Config.DisableFocusTalking then
        pttPressed = IsDisabledControlPressed(0, 249)
    else
        pttPressed = IsDisabledControlJustReleased(0, 249)
    end

    if pttPressed then
        if focused then
            debugprint("PTT is pressed, ignoring toggle focus")
            return
        end

        debugprint("PTT is pressed, waiting before toggling focus")
        while true do
            local stillPressed
            if Config.DisableFocusTalking then
                stillPressed = IsDisabledControlPressed(0, 249)
            else
                stillPressed = IsDisabledControlJustReleased(0, 249)
            end
            if not stillPressed then break end
            Wait(100)
        end
    end

    if focused then
        Wait(200)
    end

    SetNuiFocusKeepInput(not focused)
end)

-- ─────────────────────────────────────────────
--  PTT-during-focus flag
-- ─────────────────────────────────────────────
local pttWhileFocused = false

-- ─────────────────────────────────────────────
--  Event handler: keybind pressed
-- ─────────────────────────────────────────────
AddEventHandler("lb-phone:keyPressed", function(action)
    if IsPauseMenuActive() then return end

    if action == "Open" then
        debugprint("Pressed open keybind")
        ToggleOpen(not phoneOpen)

    elseif action == "Focus" then
        -- Only handle focus toggle if phone is open and not blocked by PTT
        if not phoneOpen then return end
        if pttWhileFocused then return end

        -- Check PTT
        local pttPressed
        if Config.DisableFocusTalking then
            pttPressed = IsDisabledControlPressed(0, 249)
        else
            pttPressed = IsDisabledControlJustReleased(0, 249)
        end

        if pttPressed then
            debugprint("PTT is pressed, waiting before toggling focus")
            pttWhileFocused = true
            while true do
                local stillPressed = IsDisabledControlPressed(0, 249)
                if not stillPressed then
                    stillPressed = IsDisabledControlJustReleased(0, 249)
                end
                if not stillPressed then break end
                Wait(0)
            end
            pttWhileFocused = false
        end

        local hasFocus = IsNuiFocused()
        SetNuiFocus(not hasFocus, not hasFocus)
        if not hasFocus then
            SetNuiFocusKeepInput(Config.KeepInput)
        else
            SetNuiFocusKeepInput(false)
        end

    elseif action == "StopSounds" then
        SendReactMessage("stopSounds")
    end

    -- Call answer / decline
    if action == "AnswerCall" or action == "DeclineCall" then
        if CanOpenPhone then
            if not CanOpenPhone() then
                debugprint("CanOpenPhone returned false, not answering/declining call")
                return
            end
        else
            if not ValidateChecks("openPhone") then
                debugprint("ValidateChecks returned false for openPhone, not answering/declining call")
                return
            end
        end

        if action == "AnswerCall" then
            SendReactMessage("usedCommand", "answer")
        else
            SendReactMessage("usedCommand", "decline")
        end
    end

    -- Camera controls
    if action == "TakePhoto" then
        SendReactMessage("camera:usedCommand", "toggleTaking")
    elseif action == "ToggleFlash" then
        SendReactMessage("camera:usedCommand", "toggleFlash")
    elseif action == "LeftMode" then
        SendReactMessage("camera:usedCommand", "leftMode")
    elseif action == "RightMode" then
        SendReactMessage("camera:usedCommand", "rightMode")
    elseif action == "FlipCamera" then
        SendReactMessage("camera:usedCommand", "toggleFlip")
    end
end)

-- ─────────────────────────────────────────────
--  Register keybinds / commands from config
-- ─────────────────────────────────────────────
for actionName, bindCfg in pairs(Config.KeyBinds) do
    if bindCfg.Command then
        bindCfg.Command = string.lower(bindCfg.Command)

        if bindCfg.Bind then
            -- Register as a key bind
            local bindOptions = {
                name             = bindCfg.Command,
                description      = bindCfg.Description or "no description",
                defaultKey       = bindCfg.Bind,
                defaultMapper    = bindCfg.Mapper,
                secondaryKey     = bindCfg.SecondaryBind,
                secondaryMapper  = bindCfg.SecondaryMapper,
                onPress = function()
                    TriggerEvent("lb-phone:keyPressed", actionName)
                end,
                onRelease = function(duration)
                    TriggerEvent("lb-tablet:keyReleased", actionName, duration)
                end,
            }
            bindCfg.bindData = AddKeyBind(bindOptions)
        else
            -- Register as a chat command
            RegisterCommand(bindCfg.Command, function()
                TriggerEvent("lb-phone:keyPressed", actionName)
                Wait(0)
                TriggerEvent("lb-phone:keyReleased", actionName, 0)
            end, false)
        end
    end
end

-- ─────────────────────────────────────────────
--  NUI callback: player finished setup wizard
-- ─────────────────────────────────────────────
RegisterNUICallback("finishedSetup", function(data, cb)
    if phoneData then phoneData.isSetup = true end

    SendReactMessage("setName", data.name)
    TriggerServerEvent("phone:setName", data.name)
    TriggerServerEvent("phone:togglePhone", phoneOpen)
    TriggerServerEvent("phone:finishedSetup", data)

    if Config.AutoBackup then
        TriggerCallback("backup:createBackup")
    end

    cb("ok")
end)

-- ─────────────────────────────────────────────
--  NUI callback: check admin status
-- ─────────────────────────────────────────────
RegisterNUICallback("isAdmin", function(_, cb)
    TriggerCallback("isAdmin", cb)
end)

-- ─────────────────────────────────────────────
--  NUI callback: rename this phone
-- ─────────────────────────────────────────────
RegisterNUICallback("setPhoneName", function(name, cb)
    if phoneData and phoneData.isSetup then
        if settings then settings.name = name end
        TriggerServerEvent("phone:setName", name)
    end
    cb("ok")
end)

-- ─────────────────────────────────────────────
--  NUI callback: save updated settings
-- ─────────────────────────────────────────────
RegisterNUICallback("setSettings", function(newSettings, cb)
    debugprint("setSettings triggered")
    cb("ok")

    if not phoneData then
        print("setSettings triggered, but phoneData is nil")
        return
    end

    settings          = newSettings
    phoneData.settings = settings

    AwaitCallback("setSettings", settings)
    SetCallVolume(settings and settings.sound and settings.sound.callVolume)
    TriggerEvent("lb-phone:settingsUpdated", newSettings)

    SendReactMessage("customApp:sendMessage", {
        identifier = "any",
        message = {
            type     = "settingsUpdated",
            settings = settings,
            action   = "settingsUpdated",
            data     = newSettings,
        },
    })
end)

-- ─────────────────────────────────────────────
--  NUI callback: reposition hardware cursor
-- ─────────────────────────────────────────────
RegisterNUICallback("setCursorLocation", function(data, cb)
    local screenW, screenH = GetActiveScreenResolution()
    SetCursorLocation(data.x / screenW, data.y / screenH)
    cb("ok")
end)

-- ─────────────────────────────────────────────
--  NUI callback: release NUI focus (close)
-- ─────────────────────────────────────────────
RegisterNUICallback("exitFocus", function(_, cb)
    debugprint("exitFocus triggered")
    SetNuiFocus(false, false)
    ToggleOpen(false)
    cb("ok")
end)

-- ─────────────────────────────────────────────
--  NUI callback: return available locales
-- ─────────────────────────────────────────────
RegisterNUICallback("getLocales", function(_, cb)
    cb(Config.Locales or { en = "English" })
end)

-- ─────────────────────────────────────────────
--  NUI callback: phone visibility changed
-- ─────────────────────────────────────────────
RegisterNUICallback("setOnScreen", function(value, cb)
    local onScreen = value == true
    if onScreen ~= PhoneOnScreen then
        TriggerEvent("lb-phone:setOnScreen", onScreen)
        PhoneOnScreen = onScreen
    end
    cb("ok")
end)

exports("IsPhoneOnScreen", function()
    return PhoneOnScreen
end)


-- ─────────────────────────────────────────────
--  Time & service update thread
-- ─────────────────────────────────────────────
CreateThread(function()
    local lastTime = {}

    debugprint("Waiting for currentPhone to be set before updating time & service")
    while not currentPhone do
        Wait(500)
    end

    SendReactMessage("updateService", GetServiceBars())
    debugprint("currentPhone is set, updating time & service")

    while true do
        -- If RealTime is enabled the UI handles the clock itself
        if Config.RealTime then break end

        local time
        if Config.CustomTime then
            time = Config.CustomTime()
        end

        if not time then
            time = { hour = GetClockHours(), minute = GetClockMinutes() }
        end

        -- Only push update when the time actually changed
        if time.hour ~= lastTime.hour or time.minute ~= lastTime.minute then
            lastTime.hour   = time.hour
            lastTime.minute = time.minute
            SendReactMessage("updateTime", time)
        end

        Wait(1000)
    end
end)


-- ─────────────────────────────────────────────
--  NUI callback: fetch a JSON config file
-- ─────────────────────────────────────────────
RegisterNUICallback("getConfigFile", function(name, cb)
    local raw     = GetConfigFile(name .. ".json")
    local decoded = json.decode(raw)
    cb(decoded)
end)


-- ─────────────────────────────────────────────
--  LogOut
--  Clears all phone state (character logout).
-- ─────────────────────────────────────────────
local function LogOut()
    debugprint("LogOut triggered")

    while isFetchingPhone do
        debugprint("LogOut triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end

    ResetSecurity()
    if OnDeath then OnDeath() end

    phoneData    = nil
    currentPhone = nil
    settings     = nil

    TriggerEvent("lb-phone:numberChanged", nil)
    TriggerCallback("setLastPhone")
end
LogOut = LogOut

-- ─────────────────────────────────────────────
--  SetPhone
--  Switches the active phone number.
-- ─────────────────────────────────────────────
local function SetPhone(number, flag)
    debugprint("SetPhone triggered", number, flag)

    while isFetchingPhone do
        debugprint("SetPhone triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end

    if OnDeath then OnDeath() end
    AwaitCallback("setLastPhone", number)
    ResetSecurity(true)
    ToggleCharging(false)

    phoneData    = nil
    currentPhone = nil
    settings     = nil

    TriggerEvent("lb-phone:numberChanged", nil)

    if number or flag then
        FetchPhone()
    end

    -- If clearing and no explicit number, auto-select the first number
    if number == nil and not flag then
        local first = GetFirstNumber()
        if first then
            SetPhone(first)
        end
    end
end
SetPhone = SetPhone

-- ─────────────────────────────────────────────
--  OnDeath
--  Cleans up active states when the player dies.
-- ─────────────────────────────────────────────
local function OnDeath()
    debugprint("OnDeath triggered")

    local wasWatching = IsWatchingLive()
    EndLive()
    if wasWatching then
        SendReactMessage("instagram:liveEnded", wasWatching)
    end

    if flashlightEnabled then
        flashlightEnabled = false
        TriggerServerEvent("phone:toggleFlashlight", false)
    end

    EndCall()
    ToggleOpen(false)
end
OnDeath = OnDeath

-- ─────────────────────────────────────────────
--  Net / export wiring
-- ─────────────────────────────────────────────
RegisterNetEvent("phone:toggleOpen", ToggleOpen)

exports("ToggleOpen", ToggleOpen)

exports("IsOpen", function()
    return phoneOpen
end)

exports("IsDisabled", function()
    return phoneDisabled
end)

exports("ToggleDisabled", function(state)
    phoneDisabled = state == true
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