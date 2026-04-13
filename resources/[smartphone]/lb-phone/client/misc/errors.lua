-- Handle UI errors reported from the React phone interface
RegisterNUICallback("logError", function(data, cb)
  -- Only forward errors when running in production (not dev mode)
  local uiPage = GetResourceMetadata(GetCurrentResourceName(), "ui_page", 0)
  if uiPage == "ui/dist/index.html" then
    local errorMsg        = data.error          or "No error message"
    local stack           = data.stack          or "No stack"
    local componentStack  = data.componentStack or "No component stack"

    TriggerServerEvent("phone:logError", errorMsg, stack, componentStack)
  end

  -- Capture whether the phone was open before resetting it
  local wasPhoneOpen = phoneOpen
  OnDeath()

  if wasPhoneOpen then
    debugprint("Opening phone due to error")
    ToggleOpen(true)
  end

  -- Show a crash notification after a short delay
  Wait(5000)
  TriggerEvent("phone:sendNotification", {
    app     = "Settings",
    title   = "System Crash",
    content = "Your phone crashed. Press F8 for more info.",
  })

  cb("ok")
end)