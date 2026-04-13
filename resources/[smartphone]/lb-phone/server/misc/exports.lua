-- Supported social apps for verified/password exports
local socialApps = {}
socialApps.twitter   = true
socialApps.instagram = true
socialApps.tiktok    = true

-- Map of alternate app identifiers to canonical names
local appAliases = {}
appAliases.birdy    = "twitter"
appAliases.instapic = "instagram"
appAliases.trendy   = "tiktok"

-- Display names for social apps (used in notifications)
local socialAppNames = {}
socialAppNames.twitter   = "Twitter"
socialAppNames.instagram = "Instagram"
socialAppNames.tiktok    = "TikTok"

-- Canonical app names for account-switcher-compatible apps
local accountSwitcherApps = {}
accountSwitcherApps.twitter   = "Twitter"
accountSwitcherApps.instagram = "Instagram"
accountSwitcherApps.mail      = "Mail"
accountSwitcherApps.tiktok    = "TikTok"
accountSwitcherApps.darkchat  = "DarkChat"

-- The DB column used to identify a user in each app's accounts table
local appUsernameField = {}
appUsernameField.twitter   = "username"
appUsernameField.instagram = "username"
appUsernameField.tiktok    = "username"
appUsernameField.mail      = "address"
appUsernameField.darkchat  = "username"

-- ─── Helpers ─────────────────────────────────────────────────────────────────

-- Resolve an app identifier (including aliases) to its canonical lowercase name.
-- Returns the resolved name, or the input unchanged if no alias found.
local function resolveApp(app)
  assert(type(app) == "string", "Invalid app")
  local lower = app:lower()
  -- If not a direct match, check aliases
  if not socialApps[lower] then
    local alias = appAliases[lower]
    lower = tostring(alias)
  end
  return lower
end

-- ─── Exports ─────────────────────────────────────────────────────────────────

-- Toggle the verified badge on a social media account.
-- Notifies all actively logged-in players if verifying.
local function toggleVerified(app, username, verified)
  app = resolveApp(app)
  assert(socialApps[app],          "Invalid app")
  assert(type(username) == "string", "Invalid username")

  TriggerEvent("lb-phone:toggleVerified", app, username, verified)

  local rowsAffected = MySQL.Sync.execute(
    ("UPDATE phone_%s_accounts SET verified=@verified WHERE username=@username"):format(app),
    { ["@username"] = username, ["@verified"] = verified }
  )

  local success = rowsAffected > 0

  -- If verifying and the app supports notifications, notify all active sessions
  if success and verified and socialAppNames[app] then
    local rows = MySQL.query.await(
      "SELECT phone_number FROM phone_logged_in_accounts WHERE app = ? AND username = ? AND `active` = 1",
      { app, username }
    )

    for i = 1, #rows do
      SendNotification(rows[i].phone_number, {
        app   = socialAppNames[app],
        title = L("BACKEND.MISC.VERIFIED"),
      })
    end
  end

  return success
end
ToggleVerified = toggleVerified
exports("ToggleVerified", toggleVerified)

-- Check whether a social media account has the verified badge
exports("IsVerified", function(app, username)
  app = resolveApp(app)
  assert(socialApps[app],           "Invalid app")
  assert(type(username) == "string", "Invalid username")

  local result = MySQL.Sync.fetchScalar(
    ("SELECT verified FROM phone_%s_accounts WHERE username=@username"):format(app),
    { ["@username"] = username }
  )

  return result or false
end)

-- Change the password for a social/account-switcher app account.
-- Pass silent=true to skip logout notifications (e.g. when called internally).
local function changePassword(app, username, newPassword, silent)
  assert(type(app) == "string",         "Invalid app")
  local lowerApp = app:lower()

  -- Resolve to canonical app name via appUsernameField or aliases
  local resolvedApp = appUsernameField[lowerApp] and lowerApp
    or (appAliases[lowerApp] and appAliases[lowerApp])
    or lowerApp
  local usernameField = appUsernameField[resolvedApp]
  assert(usernameField,                     "Invalid app")
  assert(type(username) == "string",        "Invalid username")
  assert(type(newPassword) == "string",     "Invalid password")

  local rowsAffected = MySQL.update.await(
    ("UPDATE phone_%s_accounts SET password = ? WHERE %s = ?"):format(resolvedApp, usernameField),
    { GetPasswordHash(newPassword), username }
  )

  if rowsAffected <= 0 then return false end

  -- Unless silent, log out all active sessions and notify them
  if not silent then
    local canonicalName = accountSwitcherApps[resolvedApp]
    NotifyLoggedInAccounts(canonicalName, username, {
      title   = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
      content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    })
    ClearActiveAccountsCache(canonicalName, username)
    TriggerClientEvent("phone:logoutFromApp", -1, {
      username = username,
      app      = resolvedApp,
      reason   = "password",
    })
    MySQL.update(
      "DELETE FROM phone_logged_in_accounts WHERE app = ? AND username = ?",
      { resolvedApp, username }
    )
  end

  return true
end
ChangePassword = changePassword
exports("ChangePassword", changePassword)

-- Resolve a player source, identifier, or item ID to an equipped phone number
exports("GetEquippedPhoneNumber", function(input)
  -- If given a player source directly, look up their phone
  if type(input) == "number" then
    return GetEquippedPhoneNumber(input)
  end

  -- Try to resolve a player source from a string identifier
  local playerSource = GetSourceFromIdentifier and GetSourceFromIdentifier(input)
  if playerSource then
    return GetEquippedPhoneNumber(playerSource)
  end

  -- Fall back to a DB lookup by item ID
  local table = Config.Item.Unique and "phone_last_phone" or "phone_phones"
  return MySQL.scalar.await(
    ("SELECT phone_number FROM %s WHERE id = ?"):format(table),
    { input }
  )
end)