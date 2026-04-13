-- Track which apps are hidden: hiddenApps[appName] = true/false
local hiddenApps = {}

-- Show or hide the home indicator bar at the bottom of the phone
exports("ToggleHomeIndicator", function(visible)
  SendReactMessage("toggleShowHomeIndicator", visible)
end)

-- Toggle landscape orientation mode
exports("ToggleLandscape", function(enabled)
  SendReactMessage("toggleLandscape", enabled)
end)

-- Open a specific app, optionally passing metadata to it
exports("OpenApp", function(appName, metadata)
  SendReactMessage("setApp", { name = appName, metadata = metadata })
end)

-- Close an app. Options: { app = "AppName", closeCompletely = true/false }
exports("CloseApp", function(options)
  options = options or {}

  local appName = options.app or "nil"
  debugprint("CloseApp: " .. appName .. ", closeCompletely: " .. tostring(options.closeCompletely))

  SendReactMessage("closeApp", {
    app             = options.app,
    closeCompletely = options.closeCompletely == true,
  })
end)


-- Return the full hidden-apps table
function GetHiddenApps()
  return hiddenApps
end

-- Mark an app as hidden or visible, and notify the React UI
exports("SetAppHidden", function(appName, hidden)
  hiddenApps[appName] = hidden == true
  SendReactMessage("app:setHidden", { app = appName, hidden = hidden == true })
end)

-- Mark an app as installed or uninstalled in the React UI
exports("SetAppInstalled", function(appName, installed)
  SendReactMessage("app:setInstalled", { app = appName, installed = installed == true })
end)