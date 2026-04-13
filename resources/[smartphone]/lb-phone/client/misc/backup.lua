-- Triggers a server callback, then reloads the phone UI if successful.
local function applyBackup(phoneNumber, cb)
  -- Cannot apply a backup from the currently active phone number
  if phoneNumber == currentPhone then
    debugprint("can't apply backup since it's the currently equipped number")
    return cb(false)
  end

  local success = AwaitCallback("backup:applyBackup", phoneNumber)
  debugprint("phone:backup:applyBackup", phoneNumber, ":", success)
  cb(success)

  if not success then return end

  -- Reload the phone after a short delay to reflect the restored data
  Wait(5000)
  OnDeath()
  Wait(500)
  FetchPhone()
  Wait(500)
  ToggleOpen(true)
end

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback("Backup", function(data, cb)
  local action = data.action
  debugprint("Backup:" .. (action or ""))

  if action == "create" then
    TriggerCallback("backup:createBackup", cb)

  elseif action == "delete" then
    TriggerCallback("backup:deleteBackup", cb, data.number)

  elseif action == "apply" then
    applyBackup(data.number, cb)

  elseif action == "get" then
    TriggerCallback("backup:getBackups", cb)
  end
end)