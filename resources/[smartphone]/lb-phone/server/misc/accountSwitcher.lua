local activeAccounts = {}

-- Supported apps and their internal names
local supportedApps = {}
supportedApps.Twitter   = true
supportedApps.Instagram = true
supportedApps.Mail      = true
supportedApps.TikTok    = true
supportedApps.DarkChat  = true

-- Map of lowercase app identifiers to canonical names
local appNameMap = {}
appNameMap.instapic  = "Instagram"
appNameMap.birdy     = "Twitter"
appNameMap.trendy    = "TikTok"
appNameMap.darkchat  = "DarkChat"
appNameMap.mail      = "Mail"

-- Initialize empty cache tables for each supported app
for appName, _ in pairs(supportedApps) do
  activeAccounts[appName] = {}
end

-- ─── Callbacks ───────────────────────────────────────────────────────────────

-- Switch the active account for a phone number on a given app
BaseCallback("accountSwitcher:switchAccount", function(source, cb, app, username)
  if not supportedApps[app] then
    return false
  end

  -- Verify the player actually has this account logged in before allowing the switch
  local exists = MySQL.scalar.await(
    "SELECT TRUE FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ? AND username = ?",
    { cb, app, username }
  )

  if not exists then
    print(("Possible abuse? %s (%i) tried to switch to an account they aren't logged into.")
      :format(GetPlayerName(source), source))
    return false
  end

  -- Set this account as active, deactivate all others for this phone+app
  local rowsAffected = MySQL.update.await(
    "UPDATE phone_logged_in_accounts SET `active` = (username = ?) WHERE phone_number = ? AND app = ?",
    { username, cb, app }
  )

  local success = rowsAffected > 0
  if success then
    activeAccounts[app][cb] = username
    TriggerEvent("phone:loggedInToAccount", app, cb, username)
  end

  return success
end)

-- Return all logged-in accounts for a phone number on a given app
BaseCallback("accountSwitcher:getAccounts", function(source, cb, app)
  if not supportedApps[app] then
    return {}
  end

  return MySQL.query.await(
    "SELECT username FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ?",
    { cb, app }
  )
end)

-- ─── Exported Helper Functions ───────────────────────────────────────────────

-- Add (or re-activate) a logged-in account for a phone number on an app.
-- Sets all other accounts for that phone+app as inactive.
local function addLoggedInAccount(phoneNumber, app, username)
  assert(supportedApps[app], "Invalid app: " .. app)
  assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
  assert(type(username) == "string", "Invalid username. Expected string.")

  -- Deactivate any other accounts on this phone+app
  MySQL.update.await(
    "UPDATE phone_logged_in_accounts SET `active` = 0 WHERE phone_number = ? AND app = ? AND username != ?",
    { phoneNumber, app, username }
  )

  -- Upsert this account as active
  local rowsAffected = MySQL.update.await(
    "INSERT INTO phone_logged_in_accounts (phone_number, app, username, active) VALUES (?, ?, ?, 1) ON DUPLICATE KEY UPDATE active = 1",
    { phoneNumber, app, username }
  )

  local success = rowsAffected > 0
  if success then
    activeAccounts[app][phoneNumber] = username
    TriggerEvent("phone:loggedInToAccount", app, phoneNumber, username)
  end

  return success
end
AddLoggedInAccount = addLoggedInAccount

-- Remove a logged-in account for a phone number on an app.
local function removeLoggedInAccount(phoneNumber, app, username)
  assert(supportedApps[app], "Invalid app: " .. app)
  assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
  assert(type(username) == "string", "Invalid username. Expected string.")

  local rowsAffected = MySQL.update.await(
    "DELETE FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ? AND username = ?",
    { phoneNumber, app, username }
  )

  local success = rowsAffected > 0
  if success then
    -- Clear cache if the removed account was the active one
    if activeAccounts[app][phoneNumber] == username then
      activeAccounts[app][phoneNumber] = nil
    end
    TriggerEvent("phone:loggedOutFromAccount", app, username, phoneNumber)
  end

  return success
end
RemoveLoggedInAccount = removeLoggedInAccount

-- Get the currently active account username for a phone number on an app.
-- Returns false if not logged in. Pass skipCache=true to bypass the in-memory cache.
local function getLoggedInAccount(phoneNumber, app, skipCache)
  assert(supportedApps[app], "Invalid app: " .. app)
  assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")

  -- Return cached value if available
  if activeAccounts[app][phoneNumber] then
    return activeAccounts[app][phoneNumber]
  end

  -- Fall back to DB lookup
  local username = MySQL.scalar.await(
    "SELECT username FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ? AND active = 1",
    { phoneNumber, app }
  )

  -- Populate cache if we got a result and caching is not suppressed
  if username and not skipCache then
    debugprint("AccountSwitcher: Setting cache for " .. phoneNumber .. ", logged in as " .. username .. " on " .. app)
    activeAccounts[app][phoneNumber] = username
  end

  return username or false
end
GetLoggedInAccount = getLoggedInAccount

-- Return all phone numbers that are logged into a given account on a given app.
-- Pass activeOnly=false to include inactive sessions (defaults to active only).
local function getLoggedInNumbers(app, username, activeOnly)
  assert(supportedApps[app], "Invalid app: " .. app)
  assert(type(username) == "string", "Invalid username. Expected string.")

  if activeOnly == nil then
    activeOnly = true
  end

  local query = "SELECT phone_number FROM phone_logged_in_accounts WHERE app = ? AND username = ?"
  if activeOnly then
    query = query .. " AND active = 1"
  end

  local rows = MySQL.query.await(query, { app, username })
  if not rows then
    return {}
  end

  local numbers = {}
  for i = 1, #rows do
    numbers[#numbers + 1] = rows[i].phone_number
  end

  return numbers
end
GetLoggedInNumbers = getLoggedInNumbers

-- Return the full active-account cache for an app (phoneNumber → username).
local function getActiveAccounts(app)
  return activeAccounts[app] or {}
end
GetActiveAccounts = getActiveAccounts

-- Remove cache entries where a username is active on a different phone number.
-- Used to invalidate stale sessions after an account switches devices.
local function clearActiveAccountsCache(app, username, exceptPhoneNumber)
  assert(supportedApps[app], "Invalid app: " .. app)
  assert(type(username) == "string", "Invalid username. Expected string.")

  for phoneNumber, activeUsername in pairs(activeAccounts[app]) do
    if activeUsername == username and phoneNumber ~= exceptPhoneNumber then
      activeAccounts[app][phoneNumber] = nil
    end
  end
end
ClearActiveAccountsCache = clearActiveAccountsCache

-- ─── Exports ─────────────────────────────────────────────────────────────────

-- Export: look up the active social media username for a phone+app combo.
-- Accepts the lowercase app identifier (e.g. "birdy", "instapic").
exports("GetSocialMediaUsername", function(phoneNumber, appIdentifier)
  assert(type(appIdentifier) == "string", "Invalid app")
  local lowerApp = appIdentifier:lower()

  assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
  assert(type(appIdentifier) == "string", "Invalid app. Expected string.")

  local canonicalApp = appNameMap[lowerApp]
  assert(canonicalApp, "Invalid app: " .. appIdentifier)

  -- skipCache=true so export always reads from DB for freshness
  return getLoggedInAccount(phoneNumber, canonicalApp, true)
end)

-- ─── Event Handlers ──────────────────────────────────────────────────────────

-- Clean up active-account cache when a player disconnects
AddEventHandler("playerDropped", function()
  local phoneNumber = GetEquippedPhoneNumber(source)
  if not phoneNumber then return end

  for appName, appCache in pairs(activeAccounts) do
    if appCache[phoneNumber] then
      appCache[phoneNumber] = nil
      debugprint("AccountSwitcher: Player dropped, logging out " .. phoneNumber .. " from " .. appName)
    end
  end
end)