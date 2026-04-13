-- ─── Phone ↔ player lookup tables ────────────────────────────────────────────
local numberToSource = {}  
local sourceToNumber = {}  
local settingsCache  = {}  
local dirtySettings  = {}  

-- ─── GenerateString ──────────────────────────────────────────────────────────
-- Returns a random alphanumeric string of the given length (default 15).
function GenerateString(length)
    length = length or 15
    local result = ""

    for _ = 1, length do
        if math.random(1, 2) == 1 then
            -- Random letter a-z, optionally uppercased
            local char = string.char(math.random(97, 122))
            if math.random(1, 2) == 1 then
                char = char:upper()
            end
            result = result .. char
        else
            result = result .. math.random(1, 9)
        end
    end

    return result
end

-- ─── GenerateId ───────────────────────────────────────────────────────────────
-- Returns a unique ID for a given table/column that doesn't already exist in the DB.
function GenerateId(tableName, column)
    local uniqueId
    local exists = true

    while exists do
        local candidate = GenerateString(5)
        uniqueId = candidate

        local query  = ("SELECT `%s` FROM `%s` WHERE `%s` = @id"):format(column, tableName, column)
        local result = MySQL.Sync.fetchScalar(query, { ["@id"] = candidate })
        exists = (result ~= nil)

        if exists then Wait(50) end
    end

    return uniqueId
end

-- ─── GeneratePhoneNumber ──────────────────────────────────────────────────────
-- Generates a unique phone number using Config.PhoneNumber settings.
function GeneratePhoneNumber()
    local prefixes = Config.PhoneNumber.Prefixes
    local numLen   = Config.PhoneNumber.Length
    local number
    local unique = false

    while not unique do
        -- Build random digit string
        local digits = ""
        for _ = 1, numLen do
            digits = digits .. math.random(0, 9)
        end

        -- Prepend a random prefix if any are configured
        if #prefixes == 0 then
            number = digits
        else
            local prefix = prefixes[math.random(1, #prefixes)]
            number = prefix .. digits
        end

        -- Check uniqueness
        local existing = MySQL.Sync.fetchScalar(
            "SELECT phone_number FROM phone_phones WHERE phone_number = @number",
            { ["@number"] = number }
        )
        unique = (existing == nil)
        if not unique then Wait(0) end
    end

    return number
end

-- ─── Settings helpers ─────────────────────────────────────────────────────────

function GetSettings(phoneNumber)
    return settingsCache[phoneNumber]
end
exports("GetSettings", GetSettings)

-- Sets (or clears) settings for a phone number.
-- If newSettings is nil, writes the cached value to the DB (if CacheSettings is enabled).
function SetSettings(phoneNumber, newSettings)
    if not newSettings then
        -- Flush cached settings to DB if marked dirty
        if dirtySettings[phoneNumber] then
            dirtySettings[phoneNumber] = nil
            if Config.CacheSettings ~= false then
                debugprint("Updating settings in database for", phoneNumber)
                MySQL.update(
                    "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
                    { json.encode(settingsCache[phoneNumber]), phoneNumber }
                )
            end
        end
    end
    settingsCache[phoneNumber] = newSettings
end

-- Writes all dirty settings to the DB.
function SaveAllSettings()
    if Config.CacheSettings == false then return end
    infoprint("info", "Saving all settings")

    for phoneNumber, settingsData in pairs(settingsCache) do
        if dirtySettings[phoneNumber] then
            MySQL.update(
                "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
                { json.encode(settingsData), phoneNumber }
            )
        else
            debugprint("Not saving settings for", phoneNumber, "because no changes were made")
        end
    end
end

-- ─── playerLoaded callback ────────────────────────────────────────────────────
-- Resolves which phone number belongs to the connecting player.
RegisterLegacyCallback("playerLoaded", function(source, cb)
    local identifier = GetIdentifier(source)
    if not identifier then
        debugprint("playerLoaded: no identifier for source", source)
        return cb()
    end

    debugprint(GetPlayerName(source), source, identifier, "triggered phone:playerLoaded")

    -- ── Non-unique item mode (one phone per identifier) ──────────────────────
    if not Config.Item.Unique then
        local phoneNumber = MySQL.scalar.await(
            "SELECT phone_number FROM phone_phones WHERE id = ?",
            { identifier }
        )
        if phoneNumber then
            if HasPhoneItem(source, phoneNumber) then
                numberToSource[phoneNumber] = source
                sourceToNumber[source]      = phoneNumber
                TriggerEvent("lb-phone:numberChanged", source, phoneNumber)
                MySQL.update(
                    "UPDATE phone_phones SET last_seen = CURRENT_TIMESTAMP WHERE phone_number = ?",
                    { phoneNumber }
                )
            end
        end
        return cb(phoneNumber)
    end

    -- ── Unique item mode: look up the last phone the player used ─────────────
    local lastPhone = MySQL.scalar.await(
        "SELECT phone_number FROM phone_last_phone WHERE id = ?",
        { identifier }
    )
    debugprint("result from phone_last_phone: ", lastPhone)

    if lastPhone then
        debugprint("checking if", source, "has phone with metadata for last phone number equipped")

        if HasPhoneItem(source, lastPhone) then
            debugprint(source .. "has phone with metadata")
            numberToSource[lastPhone] = source
            sourceToNumber[source]    = lastPhone
            TriggerEvent("lb-phone:numberChanged", source, lastPhone)
            MySQL.update(
                "UPDATE phone_phones SET last_seen = CURRENT_TIMESTAMP WHERE phone_number = ?",
                { lastPhone }
            )
            return cb(lastPhone)
        end

        debugprint(source .. " doesn't have phone with metadata for last phone number equipped")
        return cb()
    end

    -- No last-phone record: check if the player has a blank phone item
    debugprint("checking if", source, "has an empty phone")
    if not HasPhoneItem(source) then
        debugprint(source .. " does not have an empty phone")
        return cb()
    end

    -- Player has a blank phone; check for a pre-unique-phone record
    debugprint(source .. " does have an empty phone, checking if they have an existing phone from pre-unique phone")
    local existingNumber = MySQL.scalar.await(
        "SELECT phone_number FROM phone_phones WHERE id = ? AND assigned = FALSE",
        { identifier }
    )

    if existingNumber then
        local assigned = SetPhoneNumber(source, existingNumber)
        if assigned then
            debugprint(source .. " does have an existing phone from pre-unique phone")
            MySQL.update(
                "UPDATE phone_phones SET assigned = TRUE, last_seen = CURRENT_TIMESTAMP WHERE phone_number = ?",
                { existingNumber }
            )
            MySQL.update(
                "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?)",
                { identifier, existingNumber }
            )
            numberToSource[existingNumber] = source
            sourceToNumber[source]         = existingNumber
            TriggerEvent("lb-phone:numberChanged", source, existingNumber)
            return cb(existingNumber)
        end
    end

    debugprint(source .. " does not have an existing phone from pre-unique phone, or failed to set number to item metadata")
    return cb()
end)

-- ─── setLastPhone callback ────────────────────────────────────────────────────
-- Called when a player equips or un-equips a phone.
RegisterLegacyCallback("setLastPhone", function(source, cb, newNumber)
    local identifier  = GetIdentifier(source)
    local oldNumber   = GetEquippedPhoneNumber(source)

    debugprint(DebugPlayerName(source), identifier, "triggered phone:setLastPhone. old number:", oldNumber, "new number:", newNumber)
    SaveBattery(source)

    -- Un-equip (newNumber is nil) ─────────────────────────────────────────────
    if not newNumber then
        if identifier then
            MySQL.update("DELETE FROM phone_last_phone WHERE id = ?", { identifier })
        end
        if oldNumber then
            numberToSource[oldNumber]      = nil
            sourceToNumber[source]         = nil
            TriggerEvent("lb-phone:numberChanged", source)
            local state        = Player(source).state
            state.phoneOpen    = false
            state.phoneName    = nil
            state.phoneNumber  = nil
            if GetSettings(oldNumber) then
                SetSettings(oldNumber, nil)
            end
        end
        return cb()
    end

    -- Equip (newNumber provided) ──────────────────────────────────────────────
    if not identifier then
        debugprint("setLastPhone: no identifier for source", source)
        return cb()
    end

    -- Prevent stealing a number already active on another source
    if numberToSource[newNumber] and numberToSource[newNumber] ~= source then
        return cb()
    end

    -- Verify the number exists in the DB
    local exists = MySQL.scalar.await(
        "SELECT 1 FROM phone_phones WHERE phone_number = ?",
        { newNumber }
    )
    if not exists then
        local playerLabel = GetPlayerName(source) .. " | " .. source
        infoprint("warning", playerLabel
            .. " tried to use a phone with a number that doesn't exist. "
            .. "This usually happens when you delete the phone from phone_phones, "
            .. "without deleting the phone item from the player's inventory. Phone number: "
            .. newNumber)
        return cb()
    end

    -- Upsert last-phone record
    MySQL.update.await(
        "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
        { identifier, newNumber, newNumber }
    )

    -- Clear old number mappings and settings
    if oldNumber then
        numberToSource[oldNumber] = nil
        sourceToNumber[source]    = nil
        if GetSettings(oldNumber) then
            SetSettings(oldNumber, nil)
        end
    end

    -- Register new number
    numberToSource[newNumber] = source
    sourceToNumber[source]    = newNumber
    TriggerEvent("lb-phone:numberChanged", source, newNumber)
    cb()
end)

-- ─── generatePhoneNumber callback ────────────────────────────────────────────
RegisterLegacyCallback("generatePhoneNumber", function(source, cb)
    local identifier = GetIdentifier(source)
    debugprint(GetPlayerName(source), source, identifier, "wants to generate a phone number")

    local phoneId = identifier  -- used as the DB row ID

    if Config.Item.Unique then
        debugprint("unique phones enabled, checking if "
            .. GetPlayerName(source)
            .. " has a phone item without a number assigned")

        if not HasPhoneItem(source) then
            debugprint(GetPlayerName(source) .. " does not have a phone item without a number assigned")
            return cb()
        end

        phoneId = GenerateId("phone_phones", "id")
    else
        -- Non-unique: check if they already have a number
        local existingNumber = MySQL.scalar.await(
            "SELECT phone_number FROM phone_phones WHERE id = ?",
            { identifier }
        )
        if existingNumber then
            infoprint("warning",
                GetPlayerName(source)
                .. " wants to generate a phone number, but they already have one. "
                .. "Please set Config.Debug to true, and send the full log in customer-support if this happens again.")
            numberToSource[existingNumber] = source
            sourceToNumber[source]         = existingNumber
            TriggerEvent("lb-phone:numberChanged", source, existingNumber)
            return cb(existingNumber)
        end
    end

    local newNumber = GeneratePhoneNumber()

    MySQL.update.await(
        "INSERT INTO phone_phones (id, owner_id, phone_number) VALUES (?, ?, ?)",
        { phoneId, identifier, newNumber }
    )
    TriggerEvent("lb-phone:phoneNumberGenerated", source, newNumber)

    if Config.Item.Unique then
        SetPhoneNumber(source, newNumber)
        MySQL.update.await(
            "UPDATE phone_phones SET assigned = TRUE WHERE phone_number = ?",
            { newNumber }
        )
        MySQL.update.await(
            "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
            { GetIdentifier(source), newNumber, newNumber }
        )
    end

    numberToSource[newNumber] = source
    sourceToNumber[source]    = newNumber
    TriggerEvent("lb-phone:numberChanged", source, newNumber)
    cb(newNumber)
end)

-- ─── getPhone callback ────────────────────────────────────────────────────────
-- Returns full phone row data for a given phone number.
RegisterLegacyCallback("getPhone", function(source, cb, phoneNumber)
    debugprint(GetPlayerName(source), "triggered phone:getPhone. checking if they have an item")

    if not HasPhoneItem(source, phoneNumber) then
        debugprint(GetPlayerName(source), "does not have an item")
        return cb()
    end

    debugprint(GetPlayerName(source), "has an item, getting phone data")

    local row = MySQL.single.await(
        "SELECT owner_id, is_setup, settings, `name`, battery FROM phone_phones WHERE phone_number = ?",
        { phoneNumber }
    )
    if not row then
        debugprint(GetPlayerName(source), "does not have any phone data")
        return cb()
    end

    -- Resolve settings: prefer in-memory cache, then decode from DB
    if row.settings then
        local cached = GetSettings(phoneNumber)
        if not cached then
            cached = json.decode(row.settings)
            SetSettings(phoneNumber, cached)
        end
        row.settings = cached
    end

    -- Update player state bag
    Player(source).state.phoneName   = row.name
    Player(source).state.phoneNumber = phoneNumber

    -- Ensure source↔number mappings are registered so GetEquippedPhoneNumber(source)
    -- works correctly for subsequent callbacks (e.g. setSettings from settings/events.js).
    -- playerLoaded may have skipped this if HasPhoneItem returned false at login time.
    if not sourceToNumber[source] then
        numberToSource[phoneNumber] = source
        sourceToNumber[source]      = phoneNumber
        debugprint(GetPlayerName(source), "registered source↔number mapping from getPhone:", phoneNumber)
    end

    debugprint(GetPlayerName(source), "has phone data")

    -- Ensure owner_id is set
    if not row.owner_id then
        local ownerId = GetIdentifier(source)
        debugprint(GetPlayerName(source)
            .. "'s phone does not have an owner, setting owner to "
            .. ownerId)
        MySQL.update(
            "UPDATE phone_phones SET owner_id = ? WHERE phone_number = ?",
            { ownerId, phoneNumber }
        )
    end

    return cb(row)
end)

-- ─── GetEquippedPhoneNumber ───────────────────────────────────────────────────
-- Returns the phone number currently equipped by the given source.
-- Falls back to the player state bag if the in-memory lookup is missing,
-- which can happen if the mapping was cleared (e.g. after factory reset)
-- but the player re-opened the phone via FetchPhone → getPhone.
function GetEquippedPhoneNumber(source)
    local number = sourceToNumber[source]
    if not number then
        -- Try state bag fallback set in getPhone callback
        local ok, val = pcall(function()
            return Player(source).state.phoneNumber
        end)
        if ok and val then
            -- Re-register the mapping so subsequent lookups are fast
            number = val
            sourceToNumber[source]  = number
            numberToSource[number]  = source
            debugprint("GetEquippedPhoneNumber: restored mapping from state bag for source", source, "→", number)
        end
    end
    return number
end

-- ─── GetSourceFromNumber ──────────────────────────────────────────────────────
function GetSourceFromNumber(phoneNumber)
    if not phoneNumber then return false end
    return numberToSource[phoneNumber] or false
end
exports("GetSourceFromNumber", GetSourceFromNumber)

-- ─── isAdmin callback ─────────────────────────────────────────────────────────
RegisterLegacyCallback("isAdmin", function(source, cb)
    cb(IsAdmin(source))
end)

-- ─── getCharacterName callback ────────────────────────────────────────────────
RegisterLegacyCallback("getCharacterName", function(source, cb)
    local first, last = GetCharacterName(source)
    cb({ firstname = first, lastname = last })
end)

-- ─── Version check ────────────────────────────────────────────────────────────
local latestVersion = nil

PerformHttpRequest("https://loaf-scripts.com/versions/phone/version.json", function(status, body, headers, err)
    if status ~= 200 then
        debugprint("Failed to get latest script version")
        debugprint("Status:", status)
        debugprint("Body:", body)
        debugprint("Headers:", headers)
        debugprint("Error:", err)
        return
    end
    latestVersion = json.decode(body).latest
end, "GET")

RegisterCallback("getLatestVersion", function()
    return latestVersion
end)

-- ─── phone:finishedSetup ──────────────────────────────────────────────────────
RegisterNetEvent("phone:finishedSetup")
AddEventHandler("phone:finishedSetup", function(setupData)
    local src         = source
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then return end

    SetSettings(phoneNumber, setupData)
    MySQL.update(
        "UPDATE phone_phones SET is_setup = true, settings = ? WHERE phone_number = ?",
        { json.encode(setupData), phoneNumber }
    )

    if Config.AutoCreateEmail then
        GenerateEmailAccount(src, phoneNumber)
    end
end)

-- ─── phone:setName ────────────────────────────────────────────────────────────
RegisterNetEvent("phone:setName")
AddEventHandler("phone:setName", function(newName)
    local src         = source
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then
        debugprint("phone:setName: no phone number for source", src)
        return
    end

    -- Validate name against filter regex if configured
    if Config.NameFilter then
        if not newName:match(Config.NameFilter) then
            infoprint("warning",
                "Player " .. GetPlayerName(src)
                .. " tried to set an invalid phone name: "
                .. newName)
            local first, last = GetCharacterName(src)
            newName = L("BACKEND.MISC.X_PHONE", { name = first, lastname = last })
        end
    end

    MySQL.Async.execute(
        "UPDATE phone_phones SET `name`=@name WHERE phone_number=@phoneNumber",
        { ["@phoneNumber"] = phoneNumber, ["@name"] = newName }
    )

    if Config.Item.Unique and SetItemName then
        SetItemName(src, phoneNumber, newName)
    end

    local currentSettings = GetSettings(phoneNumber)
    if currentSettings then currentSettings.name = newName end

    Player(src).state.phoneName = newName
end)

-- ─── setSettings callback ─────────────────────────────────────────────────────
-- BaseCallback already resolves phoneNumber server-side via GetEquippedPhoneNumber.
-- The client sends (phoneNumber, newSettings) as args, so we receive an extra
-- phoneNumber arg before newSettings -- skip it and use the server-resolved one.
BaseCallback("setSettings", function(source, phoneNumber, _clientPhoneNumber, newSettings)
    -- Guard: if only one extra arg was passed (no client phoneNumber prefix), shift args
    if newSettings == nil and type(_clientPhoneNumber) == "table" then
        newSettings = _clientPhoneNumber
    end

    if not newSettings then
        debugprint(source, "setSettings: received nil settings for phone number", phoneNumber)
        return
    end

    debugprint(source, "saving settings for phone number", phoneNumber)
    dirtySettings[phoneNumber] = true
    SetSettings(phoneNumber, newSettings)

    -- If caching is disabled, write through immediately
    if Config.CacheSettings == false then
        MySQL.update(
            "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
            { json.encode(newSettings), phoneNumber }
        )
    end
end)

-- ─── phone:togglePhone ───────────────────────────────────────────────────────
RegisterNetEvent("phone:togglePhone")
AddEventHandler("phone:togglePhone", function(isOpen)
    local src         = source
    local state       = Player(src).state
    state.phoneOpen   = isOpen

    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then
        debugprint("phone:togglePhone: no phone number for source", src)
        return
    end
    state.phoneNumber = phoneNumber
end)

-- ─── phone:toggleFlashlight ───────────────────────────────────────────────────
RegisterNetEvent("phone:toggleFlashlight")
AddEventHandler("phone:toggleFlashlight", function(enabled)
    Player(source).state.flashlight = enabled
end)

-- ─── playerDropped ────────────────────────────────────────────────────────────
AddEventHandler("playerDropped", function()
    local src         = source
    local phoneNumber = GetEquippedPhoneNumber(src)
    if not phoneNumber then return end

    Wait(1000)
    SetSettings(phoneNumber, nil)
    numberToSource[phoneNumber] = nil
    sourceToNumber[src]         = nil
    TriggerEvent("lb-phone:numberChanged", src)
end)

-- ─── onResourceStop ───────────────────────────────────────────────────────────
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SaveAllSettings()
end)

-- ─── txAdmin: server shutting down ────────────────────────────────────────────
AddEventHandler("txAdmin:events:serverShuttingDown", function()
    SaveAllSettings()
end)

-- ─── FactoryReset ─────────────────────────────────────────────────────────────
-- Wipes ALL of a phone's data from the DB and notifies the client.
local function FactoryReset(phoneNumber)
    debugprint("FactoryReset triggered for", phoneNumber)

    -- ── Delete all phone-number-linked data ───────────────────────────────────
    -- These tables have a phone_number column referencing this phone
    local tablesWithPhoneNumber = {
        "phone_logged_in_accounts",
        "phone_photo_albums",       -- cascade deletes album members & album photos
        "phone_photos",
        "phone_notes",
        "phone_notifications",
        "phone_twitter_accounts",   -- cascade deletes tweets, likes, follows, messages etc.
        "phone_phone_contacts",
        "phone_phone_blocked_numbers",
        "phone_instagram_accounts", -- cascade deletes posts, likes, follows, stories etc.
        "phone_clock_alarms",
        "phone_tinder_accounts",    -- cascade deletes swipes, matches, messages
        "phone_tinder_swipes",
        "phone_tinder_matches",
        "phone_tinder_messages",
        "phone_message_members",    -- removes player from all group chats
        "phone_darkchat_accounts",  -- cascade deletes darkchat data
        "phone_wallet_transactions",
        "phone_yellow_pages_posts",
        "phone_backups",
        "phone_marketplace_posts",
        "phone_music_playlists",
        "phone_music_saved_playlists",
        "phone_services_channels",
        "phone_maps_locations",
        "phone_tiktok_accounts",    -- cascade deletes tiktok data
        "phone_voice_memos_recordings",
    }

    for _, tableName in ipairs(tablesWithPhoneNumber) do
        local ok, err = pcall(function()
            MySQL.update.await(
                ("DELETE FROM `%s` WHERE phone_number = ?"):format(tableName),
                { phoneNumber }
            )
        end)
        if not ok then
            debugprint("FactoryReset: failed to delete from", tableName, ":", err)
        end
    end

    -- ── Reset phone_phones row ────────────────────────────────────────────────
    local rowsChanged = MySQL.update.await(
        "UPDATE phone_phones SET is_setup = false, settings = NULL, pin = NULL, face_id = NULL, `name` = NULL WHERE phone_number = ?",
        { phoneNumber }
    ) > 0

    -- ── Notify client and clear server-side state ─────────────────────────────
    local playerSource = numberToSource[phoneNumber]
    if rowsChanged and playerSource then
        TriggerEvent("lb-phone:factoryReset", playerSource, phoneNumber)
        TriggerClientEvent("phone:factoryReset", playerSource)
        SetSettings(phoneNumber, nil)
        dirtySettings[phoneNumber]    = nil
        settingsCache[phoneNumber]    = nil
        numberToSource[phoneNumber]   = nil
        sourceToNumber[playerSource]  = nil
        TriggerEvent("lb-phone:numberChanged", playerSource)
    end

    debugprint("FactoryReset complete for", phoneNumber)
end

RegisterNetEvent("phone:factoryReset")
AddEventHandler("phone:factoryReset", function()
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then return end
    FactoryReset(phoneNumber)
end)

exports("FactoryReset", FactoryReset)