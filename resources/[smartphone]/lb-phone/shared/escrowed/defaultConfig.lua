local Config = {}

-- General debug mode
Config.Debug = false

-- =====================================================
--  Logging
-- =====================================================
Config.Logs = {
    Enabled  = true,
    Service  = "discord",
    Avatar   = false,
    Dataset  = "default",
    Actions  = {
        Calls        = true,
        Messages     = true,
        InstaPic     = true,
        Birdy        = true,
        YellowPages  = true,
        Marketplace  = true,
        Mail         = true,
        Wallet       = true,
        DarkChat     = true,
        Services     = true,
        Crypto       = true,
        Trendy       = true,
        Uploads      = true,
    },
}

-- =====================================================
--  Database
-- =====================================================
Config.DatabaseChecker = {
    Enabled = true,
    AutoFix = true,
}

-- =====================================================
--  Framework
-- =====================================================
Config.Framework          = "auto"   -- "auto", "qb", "esx", etc.
Config.CustomFramework    = false
Config.QBMailEvent        = true
Config.QBOldJobMethod     = false

-- =====================================================
--  Phone Item
-- =====================================================
Config.Item = {
    Require   = true,
    Name      = "phone",
    Unique    = false,
    Inventory = "auto",
}

-- =====================================================
--  Phone Prop / Model
-- =====================================================
Config.ServerSideSpawn = false
Config.PropSpawn       = "state"
Config.PhoneModel      = 108397254
Config.PhoneRotation   = vector3(0.0, 0.0, 180.0)
Config.PhoneOffset     = vector3(0.0, -0.005, 0.0)

-- =====================================================
--  UI / Display
-- =====================================================
Config.DisableOpenNUI           = true
Config.DynamicIsland            = true
Config.SetupScreen              = true
Config.AutoDisableSparkAccounts = true
Config.AutoDeleteNotifications  = true
Config.MaxNotifications         = 50
Config.DisabledNotifications    = {}
Config.WhitelistApps            = {}
Config.BlacklistApps            = {}

-- Apps where users can change their password
Config.ChangePassword = {
    Trendy   = true,
    InstaPic = true,
    Birdy    = true,
    DarkChat = true,
    Mail     = true,
}

-- Apps where users can delete their account
Config.DeleteAccount = {
    Trendy   = false,
    InstaPic = false,
    Birdy    = false,
    DarkChat = false,
    Mail     = false,
    Spark    = false,
}

-- =====================================================
--  Companies / Emergency Services
-- =====================================================
Config.Companies = {
    Enabled              = true,
    MessageOffline       = true,
    DefaultCallsDisabled = false,
    AllowAnonymous       = false,
    SeeEmployees         = "everyone",
    DeleteConversations  = true,
    AllowNoService       = false,

    Services = {
        {
            job      = "police",
            name     = "Police",
            icon     = "https://cdn-icons-png.flaticon.com/512/7211/7211100.png",
            canCall  = true,
            canMessage = true,
            bossRanks = { "boss" },
            location = {
                name   = "Mission Row",
                coords = { x = 428.9, y = -984.5 },
            },
        },
        {
            job      = "ambulance",
            name     = "Ambulance",
            icon     = "https://cdn-icons-png.flaticon.com/128/1032/1032989.png",
            canCall  = true,
            canMessage = true,
            bossRanks = { "boss", "doctor" },
            location = {
                name   = "Pillbox",
                coords = { x = 304.2, y = -587.0 },
            },
        },
    },

    Contacts = {},

    Management = {
        Enabled  = true,
        Duty     = true,
        Deposit  = true,
        Withdraw = true,
        Hire     = true,
        Fire     = true,
        Promote  = true,
    },
}

-- =====================================================
--  Custom Apps
-- =====================================================
Config.CustomApps = {}

-- =====================================================
--  Valet
-- =====================================================
Config.Valet = {
    Enabled        = true,
    VehicleTypes   = { "car", "vehicle" },
    Price          = 100,
    Model          = 1142162924,
    Drive          = true,
    DisableDamages = false,
    FixTakeOut     = false,
}

-- =====================================================
--  House Script Integration
-- =====================================================
Config.HouseScript = "auto"

-- =====================================================
--  Voice
-- =====================================================
Config.Voice = {
    CallEffects            = false,
    SpatialAudio           = true,
    SpatialAudioSubmixes   = 4,
    System                 = "auto",
    HearNearby             = true,
    RecordNearby           = true,
    WaitUntilNotTalking    = false,
}

-- =====================================================
--  Sound
-- =====================================================
Config.Sound = {
    Sync      = true,
    Networked = false,

    Volume = {
        Multiplier = 1.0,
        Static     = false,
        Min        = 0.0,
        Max        = 1.0,
    },

    Ringtones = {
        default       = { name = "23", soundSet = "ringtone" },
        ["ringtone 1"] = { name = "1",  soundSet = "ringtone" },
        ["ringtone 2"] = { name = "7",  soundSet = "ringtone" },
        ["ringtone 3"] = { name = "10", soundSet = "ringtone" },
        ["ringtone 4"] = { name = "13", soundSet = "ringtone" },
        ["ringtone 5"] = { name = "15", soundSet = "ringtone" },
        ["ringtone 6"] = { name = "17", soundSet = "ringtone" },
        ["ringtone 7"] = { name = "19", soundSet = "ringtone" },
        ["ringtone 8"] = { name = "21", soundSet = "ringtone" },
        ["ringtone 9"] = { name = "24", soundSet = "ringtone" },
    },

    Notifications = {
        default            = { name = "1", soundSet = "notification" },
        ["notification 1"] = { name = "2", soundSet = "notification" },
        ["notification 2"] = { name = "3", soundSet = "notification" },
        ["notification 3"] = { name = "4", soundSet = "notification" },
        ["notification 4"] = { name = "5", soundSet = "notification" },
        ["notification 5"] = { name = "6", soundSet = "notification" },
        ["notification 6"] = { name = "7", soundSet = "notification" },
        ["notification 7"] = { name = "8", soundSet = "notification" },
    },
}

-- =====================================================
--  Cell Towers / Signal
-- =====================================================
Config.CellTowers = {
    Enabled    = true,
    Debug      = false,
    MinService = 0,

    -- Signal strength ranges (index = bars)
    Range = {
        [1] = 1500.0,
        [2] = 750.0,
        [3] = 500.0,
        [4] = 250.0,
    },
}

-- =====================================================
--  Locations (map markers / Yellow Pages)
-- =====================================================
Config.Locations = {
    {
        position    = vector2(428.9, -984.5),
        name        = "LSPD",
        description = "Los Santos Police Department",
        icon        = "https://cdn-icons-png.flaticon.com/512/7211/7211100.png",
    },
    {
        position    = vector2(304.2, -587.0),
        name        = "Pillbox",
        description = "Pillbox Medical Hospital",
        icon        = "https://cdn-icons-png.flaticon.com/128/1032/1032989.png",
    },
}

-- =====================================================
--  Locales
-- =====================================================
Config.Locales = {
    { locale = "en",    name = "English" },
    { locale = "de",    name = "Deutsch" },
    { locale = "fr",    name = "Français" },
    { locale = "es",    name = "Español" },
    { locale = "nl",    name = "Nederlands" },
    { locale = "dk",    name = "Dansk" },
    { locale = "no",    name = "Norsk" },
    { locale = "th",    name = "ไทย" },
    { locale = "ar",    name = "عربة" },
    { locale = "ru",    name = "Русский" },
    { locale = "cs",    name = "Czech" },
    { locale = "sv",    name = "Svenska" },
    { locale = "pl",    name = "Polski" },
    { locale = "hu",    name = "Magyar" },
    { locale = "tr",    name = "Türkçe" },
    { locale = "pt-br", name = "Português (Brasil)" },
    { locale = "pt-pt", name = "Português" },
    { locale = "it",    name = "Italiano" },
    { locale = "ua",    name = "Українська" },
    { locale = "ba",    name = "Bosanski" },
    { locale = "zh-cn", name = "简体中文 (Chinese Simplified)" },
    { locale = "ro",    name = "Romana" },
    { locale = "ja",    name = "日本語" },
}

Config.DefaultLocale = "en"
Config.DateLocale    = "en-US"
Config.DateFormat    = "auto"

-- =====================================================
--  Appearance
-- =====================================================
Config.FrameColor            = "#39334d"
Config.AllowFrameColorChange = true

-- =====================================================
--  Phone Number
-- =====================================================
Config.PhoneNumber = {
    Format   = "({3}) {3}-{4}",
    Length   = 7,
    Prefixes = { "205", "907", "480", "520", "602" },
}

-- =====================================================
--  Battery
-- =====================================================
Config.Battery = {
    Enabled  = false,

    -- Seconds between charge ticks (random range)
    ChargeInterval            = { 5,  10 },
    -- Seconds between discharge ticks (random range)
    DischargeInterval         = { 50, 60 },
    -- Seconds between discharge ticks when inactive
    DischargeWhenInactiveInterval = { 80, 120 },
    DischargeWhenInactive     = true,
}

-- =====================================================
--  Wallet / Transfers
-- =====================================================
Config.CurrencyFormat     = "$%s"
Config.MaxTransferAmount  = 1000000
Config.TransferOffline    = true
Config.TransferLimits     = {
    Daily  = false,
    Weekly = false,
}

-- =====================================================
--  Messaging
-- =====================================================
Config.EnableMessagePay    = true
Config.EnableVoiceMessages = true
Config.EnableGIFs          = true
Config.GIFsFilter          = "low"   -- "low", "medium", "high"
Config.DeleteMessages      = true
Config.GroupMessageMemberLimit = false

-- =====================================================
--  General Settings
-- =====================================================
Config.CityName            = "Los Santos"
Config.RealTime            = true
Config.CustomTime          = false
Config.EmailDomain         = "lbscripts.com"
Config.AutoCreateEmail     = false
Config.DeleteMail          = true
Config.ConvertMailToMarkdown = false
Config.SyncFlash           = true
Config.EndLiveClose        = false

-- =====================================================
--  External Media / Uploads
-- =====================================================
-- Allow external URLs in each app (false = block external links)
Config.AllowExternal = {
    Gallery     = false,
    Birdy       = false,
    InstaPic    = false,
    Spark       = false,
    Trendy      = false,
    Pages       = false,
    MarketPlace = false,
    Mail        = false,
    Messages    = false,
    Other       = false,
}

Config.ExternalBlacklistedDomains = {
    "imgur.com",
    "discord.com",
    "discordapp.com",
}

Config.ExternalWhitelistedDomains = {}

Config.UploadWhitelistedDomains = {
    "fivemanage.com",
    "fmfile.com",
    "cfx.re",
}

-- =====================================================
--  Word / Name Filters
-- =====================================================
Config.NameFilter = ".+"

Config.WordBlacklist = {
    Enabled = false,
    Apps = {
        Birdy       = true,
        InstaPic    = true,
        Trendy      = true,
        Spark       = true,
        Messages    = true,
        Pages       = true,
        MarketPlace = true,
        DarkChat    = true,
        Mail        = true,
        Other       = true,
    },
    Words = {},
}

-- =====================================================
--  Auto-Follow
-- =====================================================
Config.AutoFollow = {
    Enabled = false,

    Birdy = {
        Enabled  = true,
        Accounts = {},
    },
    InstaPic = {
        Enabled  = true,
        Accounts = {},
    },
    Trendy = {
        Enabled  = true,
        Accounts = {},
    },
}

-- =====================================================
--  Database Backup
-- =====================================================
Config.AutoBackup = true

-- =====================================================
--  Bot / System Posting Accounts
-- =====================================================
Config.Post = {
    Birdy    = true,
    InstaPic = true,

    -- Accounts used when posting as built-in bots
    Accounts = {
        Birdy = {
            Username = "Birdy",
            Avatar   = "https://loaf-scripts.com/fivem/lb-phone/icons/Birdy.png",
        },
        InstaPic = {
            Username = "InstaPic",
            Avatar   = "https://loaf-scripts.com/fivem/lb-phone/icons/InstaPic.png",
        },
    },
}

-- =====================================================
--  Birdy (Twitter-like app)
-- =====================================================
Config.BirdyTrending = {
    Enabled = true,
    Reset   = 168,   -- Reset trending topics every N hours
}

Config.BirdyNotifications     = false
Config.InstaPicLiveNotifications = false

Config.PromoteBirdy = {
    Enabled = true,
    Cost    = 2500,
    Views   = 100,
}

-- =====================================================
--  Username Filter (regex + Lua pattern)
-- =====================================================
Config.UsernameFilter = {
    Regex      = "[a-zA-Z0-9]+",
    LuaPattern = "^[%w]+$",
}

-- =====================================================
--  Trendy TTS Voices
-- =====================================================
Config.TrendyTTS = {
    { "English (US) - Female",                "en_us_001" },
    { "English (US) - Male 1",                "en_us_006" },
    { "English (US) - Male 2",                "en_us_007" },
    { "English (US) - Male 3",                "en_us_009" },
    { "English (US) - Male 4",                "en_us_010" },
    { "English (UK) - Male 1",                "en_uk_001" },
    { "English (UK) - Male 2",                "en_uk_003" },
    { "English (AU) - Female",                "en_au_001" },
    { "English (AU) - Male",                  "en_au_002" },
    { "French - Male 1",                      "fr_001" },
    { "French - Male 2",                      "fr_002" },
    { "German - Female",                      "de_001" },
    { "German - Male",                        "de_002" },
    { "Spanish - Male",                       "es_002" },
    { "Spanish (MX) - Male",                  "es_mx_002" },
    { "Portuguese (BR) - Female 2",           "br_003" },
    { "Portuguese (BR) - Female 3",           "br_004" },
    { "Portuguese (BR) - Male",               "br_005" },
    { "Indonesian - Female",                  "id_001" },
    { "Japanese - Female 1",                  "jp_001" },
    { "Japanese - Female 2",                  "jp_003" },
    { "Japanese - Female 3",                  "jp_005" },
    { "Japanese - Male",                      "jp_006" },
    { "Korean - Male 1",                      "kr_002" },
    { "Korean - Male 2",                      "kr_004" },
    { "Korean - Female",                      "kr_003" },
    { "Ghostface (Scream)",                   "en_us_ghostface" },
    { "Chewbacca (Star Wars)",                "en_us_chewbacca" },
    { "C3PO (Star Wars)",                     "en_us_c3po" },
    { "Stitch (Lilo & Stitch)",               "en_us_stitch" },
    { "Stormtrooper (Star Wars)",             "en_us_stormtrooper" },
    { "Rocket (Guardians of the Galaxy)",     "en_us_rocket" },
    { "Singing - Alto",                       "en_female_f08_salut_damour" },
    { "Singing - Tenor",                      "en_male_m03_lobby" },
    { "Singing - Sunshine Soon",              "en_male_m03_sunshine_soon" },
    { "Singing - Warmy Breeze",               "en_female_f08_warmy_breeze" },
    { "Singing - Glorious",                   "en_female_ht_f08_glorious" },
    { "Singing - It Goes Up",                 "en_male_sing_funny_it_goes_up" },
    { "Singing - Chipmunk",                   "en_male_m2_xhxs_m03_silly" },
    { "Singing - Dramatic",                   "en_female_ht_f08_wonderful_world" },
}

-- =====================================================
--  Dynamic WebRTC
-- =====================================================
Config.DynamicWebRTC = {
    Enabled     = false,
    Service     = "cloudflare",
    RemoveStun  = false,
}

-- =====================================================
--  Crypto
-- =====================================================
Config.Crypto = {
    Enabled        = true,
    Refund         = false,
    UpdateInterval = 5,   -- Minutes between price updates

    Coins = {
        lbc = {
            name         = "LB Coin",
            icon         = "./assets/img/icons/crypto/coins/lbc.webp",
            initialValue = 50.0,

            -- Weighted random price changes each tick
            changes = {
                { weight = 500, change = {  0.0,  2.0  } },  -- slight rise (most common)
                { weight = 490, change = { -2.0, -0.0  } },  -- slight drop
                { weight = 5,   change = {  5.0,  15.0 } },  -- big spike
                { weight = 5,   change = { -15.0, -5.0 } },  -- big crash
            },

            permissions = {
                buy      = true,
                sell     = true,
                transfer = true,
            },
        },
    },

    QBit   = true,
    Limits = {
        Buy  = 1000000,
        Sell = 1000000,
    },
}

-- =====================================================
--  Key Binds
-- =====================================================
Config.KeyBinds = {
    Open = {
        Command     = "phone",
        Bind        = "F1",
        Description = "Open your phone",
    },
    Focus = {
        Command     = "togglePhoneFocus",
        Bind        = "LMENU",
        Description = "Toggle cursor on your phone",
    },
    StopSounds = {
        Command     = "stopSounds",
        Bind        = false,
        Description = "Stop all phone sounds",
    },
    FlipCamera = {
        Command     = "flipCam",
        Bind        = "UP",
        Description = "Flip phone camera",
    },
    TakePhoto = {
        Command     = "takePhoto",
        Bind        = "RETURN",
        Description = "Take a photo / video",
    },
    ToggleFlash = {
        Command     = "toggleCameraFlash",
        Bind        = "E",
        Description = "Toggle flash",
    },
    LeftMode = {
        Command     = "leftMode",
        Bind        = "LEFT",
        Description = "Change mode",
    },
    RightMode = {
        Command     = "rightMode",
        Bind        = "RIGHT",
        Description = "Change mode",
    },
    RollLeft = {
        Command     = "cameraRollLeft",
        Bind        = "Z",
        Description = "Roll camera to the left",
    },
    RollRight = {
        Command     = "cameraRollRight",
        Bind        = "C",
        Description = "Roll camera to the right",
    },
    FreezeCamera = {
        Command     = "cameraFreeze",
        Bind        = "X",
        Description = "Freeze camera",
    },
    AnswerCall = {
        Command     = "answerCall",
        Bind        = "RETURN",
        Description = "Answer incoming call",
    },
    DeclineCall = {
        Command     = "declineCall",
        Bind        = "BACK",
        Description = "Decline incoming call",
    },
    UnlockPhone = {
        Bind        = "SPACE",
        Description = "Open your phone",
    },
}

Config.KeepInput         = true
Config.DisableFocusTalking = false

-- =====================================================
--  Camera
-- =====================================================
Config.Camera = {
    ShowTip      = true,
    Walkable     = true,
    Roll         = true,
    AllowRunning = true,
    MaxFOV       = 70.0,
    DefaultFOV   = 60.0,
    MinFOV       = 10.0,
    MaxLookUp    = 80.0,
    MaxLookDown  = -80.0,

    Vehicle = {
        Zoom         = true,
        MaxFOV       = 80.0,
        DefaultFOV   = 60.0,
        MinFOV       = 10.0,
        MaxLookUp    = 50.0,
        MaxLookDown  = -30.0,
        MaxLeftRight = 120.0,
        MinLeftRight = -120.0,
    },

    Selfie = {
        Offset     = vector3(0.05, 0.55, 0.6),
        Rotation   = vector3(10.0, 0.0, -180.0),
        MaxFov     = 90.0,
        DefaultFov = 60.0,
        MinFov     = 50.0,
    },

    Freeze = {
        Enabled     = false,
        MaxDistance = 10.0,
        MaxTime     = 60,
    },
}

-- =====================================================
--  Upload Methods
-- =====================================================
Config.UploadMethod = {
    Video = "Fivemanage",
    Image = "Fivemanage",
    Audio = "Fivemanage",
}

Config.Video = {
    Bitrate     = 400,
    FrameRate   = 24,
    MaxSize     = 25,   -- MB
    MaxDuration = 60,   -- Seconds
}

Config.Image = {
    Mime    = "image/webp",
    Quality = 0.95,
}

-- =====================================================
--  Internal: error reporter (loops every 5s)
-- =====================================================
local function reportConfigError(message)
    Citizen.CreateThreadNow(function()
        while true do
            print("^1[ERROR]^7: " .. message)
            Wait(5000)
        end
    end)
end

-- =====================================================
--  Merge defaults into global Config if it already
--  exists (e.g. from a user-provided config file),
--  warning about any missing keys.
-- =====================================================
if not Config then
    reportConfigError("You've broken the config. Re-install the script, and it will work.")
    Config = Config  -- fallback to local default table
end

for key, defaultValue in pairs(Config) do
    if Config[key] == nil then
        print("^3[WARNING]^7: Missing config key: ^2" .. key .. "^7, using default value.")
        Config[key] = defaultValue
    end
end

-- Validate that all phone number prefixes have equal length
if #Config.PhoneNumber.Prefixes > 0 then
    local expectedLength = #Config.PhoneNumber.Prefixes[1]
    for i = 1, #Config.PhoneNumber.Prefixes do
        local prefix = Config.PhoneNumber.Prefixes[i]
        if #prefix ~= expectedLength then
            print("^1[ERROR]^7: The phone number prefix ^5" .. prefix .. "^7 is not the same length as the other prefixes.")
        end
    end
end

-- Warn if both Item.Name and Item.Names are set simultaneously
if Config.Item.Name then
    if Config.Item.Names then
        reportConfigError("You have both ^2Item.Name^7 and ^2Item.Names^7 in your config. Please remove one of them.")
    end
end

-- Warn if Item.Unique is true but Item.Require is false
if Config.Item.Unique then
    if not Config.Item.Require then
        reportConfigError("You have ^2Item.Unique^7 set to true, but ^2Item.Require^7 is set to false. Please set ^2Item.Require^7 to true, or set Item.Unique to false.")
    end
end

-- =====================================================
--  Validate UploadMethod values on resource start
-- =====================================================
CreateThread(function()
    -- Ensure the global UploadMethods registry exists
    if not UploadMethods then
        print("^3[WARNING]^7: UploadMethods is not defined")
        UploadMethods = {}
    end

    -- If UploadMethod block is missing, apply defaults
    if not Config.UploadMethod then
        reportConfigError("Config.UploadMethod is not set")
        Config.UploadMethod = {
            Video = "Fivemanage",
            Image = "Fivemanage",
            Audio = "Fivemanage",
        }
        return
    end

    -- Validate Video upload method
    if not Config.UploadMethod.Video then
        reportConfigError("Config.UploadMethod.Video is not set")
    elseif not UploadMethods[Config.UploadMethod.Video] then
        reportConfigError("Config.UploadMethod.Video is not set to a valid upload method")
    end

    -- Validate Image upload method
    if not Config.UploadMethod.Image then
        reportConfigError("Config.UploadMethod.Image is not set")
    elseif not UploadMethods[Config.UploadMethod.Image] then
        reportConfigError("Config.UploadMethod.Image is not set to a valid upload method")
    end

    -- Validate Audio upload method
    if not Config.UploadMethod.Audio then
        reportConfigError("Config.UploadMethod.Audio is not set")
    elseif not UploadMethods[Config.UploadMethod.Audio] then
        reportConfigError("Config.UploadMethod.Audio is not set to a valid upload method")
    end
end)