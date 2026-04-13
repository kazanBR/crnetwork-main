-- Cache of notifications that have action buttons: notificationsWithActions[id] = notificationData
local notificationsWithActions = {}

-- ─── Internal Functions ──────────────────────────────────────────────────────

-- Fetch all stored notifications from the server, normalize legacy fields,
-- and register any that have action buttons into the local cache.
local function getNotifications()
  local notifications = AwaitCallback("getNotifications")

  for i = 1, #notifications do
    local notif = notifications[i]

    -- Legacy: if content is nil, promote title into content
    if notif.content == nil then
      notif.content = notif.title
      notif.title   = nil
    end

    -- Decode custom_data and register action buttons if present
    if notif.custom_data then
      local customData = json.decode(notif.custom_data)
      if customData.buttons then
        notif.actions = customData.buttons
        notificationsWithActions[notif.id] = notif
      end
      notif.custom_data = nil
    end
  end

  return notifications
end

-- Delete a notification by ID.
-- Client-side notifications (prefixed "client-notification-") and non-numeric IDs
-- are removed locally without a server call.
local function deleteNotification(id)
  if not id then return true end

  -- Clear from local action cache if present
  if notificationsWithActions[id] then
    notificationsWithActions[id] = nil
  end

  -- Client-only notifications don't need a DB delete
  if type(id) == "string" and id:find("client%-notification%-") then
    return true
  end

  -- Non-numeric IDs are also treated as client-only
  if type(id) ~= "number" then
    return true
  end

  return AwaitCallback("deleteNotification", id)
end

-- Clear all notifications for a given app.
local function clearNotifications(app)
  local success = AwaitCallback("clearNotifications", app)
  if not success then return false end

  -- Also clear matching entries from the local action cache
  for id, notif in pairs(notificationsWithActions) do
    if notif.app == app then
      notificationsWithActions[id] = nil
    end
  end

  return success
end

-- Handle a button press on a notification.
-- Triggers the button's event (server or client), removes the notification if flagged.
local function handleNotificationButton(notifId, buttonIndex)
  local notif = notificationsWithActions[notifId]
  if not notif or not notif.actions then
    debugprint("No buttons found for notification", notifId, notificationsWithActions)
    return false
  end

  local button = notif.actions[buttonIndex]
  if not button then
    debugprint("Button not found for notification", notifId, buttonIndex)
    return false
  end

  -- Fire the button's event on the appropriate side
  if button.event then
    if button.server then
      TriggerServerEvent(button.event, button.data)
    else
      TriggerEvent(button.event, button.data)
    end
  end

  -- Optionally remove the notification after the button press
  if button.remove then
    SendReactMessage("removeNotification", notifId)
    notificationsWithActions[notifId] = nil
    if type(notifId) == "number" then
      AwaitCallback("deleteNotification", notifId)
    end
  end

  return true
end

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback("Notifications", function(data, cb)
  local action = data.action
  debugprint("Notifications:" .. (action or ""))

  if action == "getNotifications" then
    return cb(getNotifications())

  elseif action == "deleteNotification" then
    if data.id ~= nil then
      return cb(deleteNotification(data.id))
    end

  elseif action == "clearNotifications" then
    return cb(clearNotifications(data.app))

  elseif action == "button" then
    -- buttonId is 0-indexed from the UI; convert to 1-indexed for Lua
    local buttonIndex = (data.buttonId or 0) + 1
    return cb(handleNotificationButton(data.id, buttonIndex))
  end
end)

-- ─── Net Events ──────────────────────────────────────────────────────────────

-- Receive a new notification from the server and push it to the React UI
RegisterNetEvent("phone:sendNotification")
AddEventHandler("phone:sendNotification", function(notif)
  -- Only show notifications if the player has a working phone
  if not HasPhoneItem(currentPhone) or phoneDisabled then
    debugprint("no phone, not showing notification")
    return
  end

  -- Assign a random client-side ID if none was provided
  if not notif.id then
    notif.id = "client-notification-" .. math.random()
  end

  -- Legacy: promote title into content if content is absent
  if notif.content == nil then
    notif.content = notif.title
    notif.title   = nil
  end

  -- Register action buttons if present in customData
  if notif.customData and notif.customData.buttons and notif.id then
    notif.actions = notif.customData.buttons
    notificationsWithActions[notif.id] = notif
  end
  notif.customData = nil

  SendReactMessage("newNotification", notif)

  -- Bring the NUI to the foreground when a notification arrives while phone is closed
  if not phoneOpen and Config.NotificationsUpdateZIndex and SetNuiZindex then
    SetNuiZindex(99)
  end
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────

-- Send a client-side notification (no DB persistence)
exports("SendNotification", function(notif)
  notif.id = "client-notification-" .. math.random()
  TriggerEvent("phone:sendNotification", notif)
end)

exports("DeleteNotification", deleteNotification)