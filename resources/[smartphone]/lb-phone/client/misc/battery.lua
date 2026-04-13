-- Local battery state
local currentBattery = 100
local isCharging     = false

-- ─── Core Logic ──────────────────────────────────────────────────────────────

-- Set the local battery level, trigger death if it hits 0, and sync to server
local function setBattery(level)
  if not Config.Battery.Enabled then return end

  assert(type(level) == "number", "setBattery: battery must be a number")
  assert(level >= 0 and level <= 100, "setBattery: battery must be between 0 and 100")

  currentBattery = level

  if level == 0 then
    OnDeath()
    TriggerEvent("lb-phone:phoneDied")
  end

  TriggerServerEvent("phone:battery:setBattery", level)
end

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

-- Called by the phone UI to report the current battery level
RegisterNUICallback("setBattery", function(data, cb)
  setBattery(data)
  cb("ok")
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────

-- Set battery level and push the update to the React UI
exports("SetBattery", function(level)
  setBattery(level)
  SendReactMessage("battery:setBattery", level)
end)

-- Return the current battery level
exports("GetBattery", function()
  return currentBattery
end)

-- Toggle the charging state; notifies the React UI if the value actually changed
local function toggleCharging(toggle)
  assert(type(toggle) == "boolean", "ToggleCharging: toggle must be a boolean")

  if isCharging == toggle then
    debugprint("ToggleCharging: charging is already set to", toggle)
    return
  end

  isCharging = toggle
  SendReactMessage("battery:toggleCharging", toggle)
end
ToggleCharging = toggleCharging
exports("ToggleCharging", toggleCharging)

-- Return whether the phone is currently charging
exports("IsCharging", function()
  return isCharging
end)

-- Return true if the battery feature is enabled and the battery is at 0
local function isPhoneDead()
  if not Config.Battery.Enabled then return false end
  return currentBattery == 0
end
IsPhoneDead = isPhoneDead
exports("IsPhoneDead", isPhoneDead)