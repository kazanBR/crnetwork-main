-- Build a set of disabled apps from config for O(1) lookup
local disabledApps = {}
if Config.DisabledNotifications then
  for _, appName in ipairs(Config.DisabledNotifications) do
    disabledApps[appName] = true
  end
end

-- ─── SendNotification ────────────────────────────────────────────────────────

-- Send a notification to a specific phone number or player source.
-- target:  player source (number), phone number (string), or nil for source-only
-- data:    notification table { app, title, content, thumbnail, avatar, showAvatar, customData }
-- cb:      optional callback receiving the inserted notification ID
local function sendNotification(target, data, cb)
  -- Reject if the app has notifications disabled
  if disabledApps[data.app] then
    if cb then cb(false) end
    debugprint("SendNotification: Notification are disabled for app", data.app)
    return
  end

  -- Shallow-clone to avoid mutating the caller's table
  data = table.clone(data)

  -- Validate: must be a table with an app field, or target must be a string phone number
  local isValidTable = type(data) == "table" and (data.app or type(target) == "string")
  if not isValidTable then
    if cb then cb(false) end
    return debugprint("SendNotification: Invalid data or no app", data)
  end

  -- Truncate long content
  if data.content and #data.content > 500 then
    if cb then cb(false) end
    data.content = data.content:sub(1, 500)
  end

  -- Resolve target to a phone number (string) and/or player source
  local phoneNumber = nil
  if type(target) == "number" then
    data.source = target
  elseif type(target) == "string" then
    phoneNumber = target
  end

  -- If we have an app but no explicit source, try to find the source from the phone number
  if data.app and not data.source and type(target) == "string" then
    local resolvedSource = GetSourceFromNumber(target)
    if resolvedSource then
      data.source = resolvedSource
    end
  end

  -- If there's no app or no phone number, deliver only to source (no DB insert)
  if not data.app or not phoneNumber then
    if cb then cb(true) end
    if data.source then
      TriggerClientEvent("phone:sendNotification", data.source, data)
      debugprint("SendNotification: Sending notification to source: " .. data.source)
    end
    debugprint("SendNotification: No app or no phone number provided (target is not a string)", phoneNumber, data)
    return
  end

  -- Enforce max notification limit by deleting oldest excess entries
  if Config.MaxNotifications then
    local oldestId = MySQL.scalar.await(
      "SELECT id FROM phone_notifications WHERE phone_number = ? ORDER BY id DESC LIMIT ?, 1",
      { phoneNumber, Config.MaxNotifications - 1 }
    )
    if oldestId then
      debugprint("SendNotification: " .. phoneNumber .. " has reached max notifications, deleting old notifications. id:", oldestId)
      MySQL.update.await(
        "DELETE FROM phone_notifications WHERE phone_number = ? AND id <= ?",
        { phoneNumber, oldestId }
      )
    end
  end

  -- Encode customData as JSON if provided
  local encodedCustomData = data.customData and json.encode(data.customData) or nil

  -- Persist the notification
  local insertedId = MySQL.insert.await(
    "INSERT IGNORE INTO phone_notifications (phone_number, app, title, content, thumbnail, avatar, show_avatar, custom_data) VALUES (@phoneNumber, @app, @title, @content, @thumbnail, @avatar, @showAvatar, @data)",
    {
      ["@phoneNumber"] = phoneNumber,
      ["@app"]         = data.app,
      ["@title"]       = data.title,
      ["@content"]     = data.content,
      ["@thumbnail"]   = data.thumbnail,
      ["@avatar"]      = data.avatar,
      ["@showAvatar"]  = data.showAvatar,
      ["@data"]        = encodedCustomData,
    }
  )

  data.id = insertedId

  -- Push to the player's client if they're online
  if data.source then
    TriggerClientEvent("phone:sendNotification", data.source, data)
    debugprint("SendNotification: Sending notification to source: " .. data.source)
  else
    debugprint("SendNotification: couldn't find source, not triggering event")
  end

  if cb then cb(insertedId) end
  return insertedId
end
SendNotification = sendNotification
exports("SendNotification", sendNotification)

-- ─── NotifyEveryone ──────────────────────────────────────────────────────────

-- Send a notification to all players who have been seen within the last 7 days.
-- mode: "all" (DB insert + client event) or "online" (client event only)
local function notifyEveryone(mode, data)
  assert(mode == "all" or mode == "online", "Invalid notify")
  assert(type(data.app) == "string",   "Invalid app")
  assert(type(data.title) == "string", "Invalid title")

  if disabledApps[data.app] then
    debugprint("NotifyEveryone: Notification are disabled for app", data.app)
    return
  end

  if mode == "all" then
    MySQL.insert([[
            INSERT INTO phone_notifications
                (phone_number, app, title, content, thumbnail, avatar, show_avatar)
            SELECT
                phone_number, @app, @title, @content, @thumbnail, @avatar, @showAvatar
            FROM
                phone_phones
            WHERE
                last_seen > DATE_SUB(NOW(), INTERVAL 7 DAY)
        ]], {
      ["@app"]        = data.app,
      ["@title"]      = data.title,
      ["@content"]    = data.content,
      ["@thumbnail"]  = data.thumbnail,
      ["@avatar"]     = data.avatar,
      ["@showAvatar"] = data.showAvatar,
    })
  end

  TriggerClientEvent("phone:sendNotification", -1, data)
end
NotifyEveryone = notifyEveryone
exports("NotifyEveryone", notifyEveryone)

-- ─── NotifyPhonesWithQuery ───────────────────────────────────────────────────

-- Insert notifications for phones matching a custom SQL query and push to online players.
-- queryTable:  table/view name to SELECT phone_number FROM
-- data:        notification data table
-- queryPrefix: optional SQL prefix (e.g. "DISTINCT ")
-- params:      optional extra query parameters (merged with notification fields)
function NotifyPhonesWithQuery(queryTable, data, queryPrefix, params)
  if disabledApps[data.app] then
    debugprint("NotifyPhonesWithQuery: Notification are disabled for app", data.app)
    return
  end

  params       = params or {}
  queryPrefix  = queryPrefix or ""

  -- Merge notification fields into params
  params["@app"]        = data.app
  params["@title"]      = data.title
  params["@content"]    = data.content
  params["@thumbnail"]  = data.thumbnail
  params["@avatar"]     = data.avatar
  params["@showAvatar"] = data.showAvatar

  local query = ([[
        INSERT INTO phone_notifications
            (phone_number, app, title, content, thumbnail, avatar, show_avatar)
        SELECT
            %sphone_number, @app, @title, @content, @thumbnail, @avatar, @showAvatar
        FROM
            %s
        RETURNING
            id, phone_number
    ]]):format(queryPrefix, queryTable)

  MySQL.query(query, params, function(rows)
    for i = 1, #rows do
      local phoneNumber = rows[i].phone_number
      local playerSource = GetSourceFromNumber(phoneNumber)
      if playerSource then
        data.id = rows[i].id
        TriggerClientEvent("phone:sendNotification", playerSource, data)
      end
    end
  end)
end

-- ─── NotifyPhones ────────────────────────────────────────────────────────────

-- Batch-insert notifications for a list of phone numbers and push to online players.
function NotifyPhones(phoneNumbers, data)
  data = table.clone(data)

  if disabledApps[data.app] then
    debugprint("NotifyPhones: Notification are disabled for app", data.app)
    return
  end

  if #phoneNumbers == 0 then
    debugprint("NotifyPhones: No phone numbers provided")
    return
  end

  -- Build dynamic column list and values array from the notification data
  local values  = { data.app, data.title }
  local columns = { "phone_number", "app", "title" }

  if data.content    then values[#values + 1] = data.content;             columns[#columns + 1] = "content"     end
  if data.thumbnail  then values[#values + 1] = data.thumbnail;           columns[#columns + 1] = "thumbnail"   end
  if data.avatar     then values[#values + 1] = data.avatar;              columns[#columns + 1] = "avatar"      end
  if data.showAvatar then values[#values + 1] = 1;                        columns[#columns + 1] = "show_avatar" end
  if data.customData then values[#values + 1] = json.encode(data.customData); columns[#columns + 1] = "custom_data" end

  -- Build the INSERT query with placeholders
  local placeholders = string.rep("?, ", #values + 1):sub(1, -3) -- +1 for phone_number, trim trailing ", "
  local query = ("INSERT INTO phone_notifications (%s) VALUES (%s)")
    :gsub("{PARAMS}", table.concat(columns, ", "))
    :gsub("{VALUES}", placeholders)
  query = ("INSERT INTO phone_notifications (%s) VALUES (%s)"):format(
    table.concat(columns, ", "),
    placeholders
  )

  -- Build per-row parameter arrays: each row is { phoneNumber, ...values }
  local rows = {}
  for i, phoneNumber in ipairs(phoneNumbers) do
    rows[i] = { phoneNumber, table.unpack(values) }
  end

  MySQL.prepare(query, rows, function(insertedIds)
    for i, phoneNumber in ipairs(phoneNumbers) do
      -- insertedIds may be a table of IDs or a single ID depending on driver
      local insertedId = type(insertedIds) == "table" and insertedIds[i] or insertedIds
      if phoneNumber and insertedId then
        local playerSource = GetSourceFromNumber(phoneNumber)
        if playerSource then
          data.id = insertedId
          TriggerClientEvent("phone:sendNotification", playerSource, data)
        end
      end
    end
  end)
end

-- ─── NotifyLoggedInAccounts ──────────────────────────────────────────────────

-- Notify all phones currently logged into a social app account.
-- app:          canonical app name (e.g. "Twitter")
-- username:     the account username
-- data:         notification data (app field will be overwritten)
-- excludeNums:  optional list of phone numbers to skip
function NotifyLoggedInAccounts(app, username, data, excludeNums)
  if disabledApps[app] then
    debugprint("NotifyLoggedInAccounts: Notification are disabled for app", app)
    return
  end

  local phoneNumbers = GetLoggedInNumbers(app, username)

  -- Remove any excluded numbers (iterate backwards to allow safe removal)
  if excludeNums then
    for i = #phoneNumbers, 1, -1 do
      if table.contains(excludeNums, phoneNumbers[i]) then
        debugprint("NotifyLoggedInAccounts: Ignoring number", phoneNumbers[i])
        table.remove(phoneNumbers, i)
      end
    end
  end

  if #phoneNumbers == 0 then
    debugprint("NotifyLoggedInAccounts: No logged in numbers for", username, "on", app)
    return
  end

  local notifData = table.clone(data)
  notifData.app   = app
  NotifyPhones(phoneNumbers, notifData)
end

-- ─── EmergencyNotification ───────────────────────────────────────────────────

-- Send an emergency-style notification to a player source.
local function emergencyNotification(playerSource, data)
  assert(type(playerSource) == "number", "Invalid source")
  assert(type(data) == "table",          "Invalid data")

  return sendNotification(playerSource, {
    title   = data.title   or "Emergency Alert",
    content = data.content or "This is a test emergency alert.",
    icon    = "./assets/img/icons/" .. (data.icon or "warning") .. ".png",
  })
end
EmergencyNotification = emergencyNotification
exports("SendAmberAlert",        emergencyNotification)
exports("EmergencyNotification", emergencyNotification)

-- ─── Callbacks ───────────────────────────────────────────────────────────────

-- Return all notifications for a phone number
BaseCallback("getNotifications", function(_source, phoneNumber)
  return MySQL.query.await(
    "SELECT id, app, title, content, thumbnail, avatar, show_avatar AS showAvatar, custom_data, `timestamp` FROM phone_notifications WHERE phone_number=?",
    { phoneNumber }
  )
end, {})

-- Delete a specific notification by ID
BaseCallback("deleteNotification", function(_source, phoneNumber, notifId)
  local rowsAffected = MySQL.update.await(
    "DELETE FROM phone_notifications WHERE id=? AND phone_number=?",
    { notifId, phoneNumber }
  )
  return rowsAffected > 0
end)

-- Clear all notifications for a phone number on a given app
BaseCallback("clearNotifications", function(_source, phoneNumber, app)
  MySQL.update.await(
    "DELETE FROM phone_notifications WHERE phone_number=? AND app=?",
    { phoneNumber, app }
  )
  return true
end)