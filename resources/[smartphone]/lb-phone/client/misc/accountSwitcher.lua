-- Supported apps for account switching
local supportedApps = {}
supportedApps.Twitter = true
supportedApps.Instagram = true
supportedApps.TikTok = true
supportedApps.Mail = true
supportedApps.DarkChat = true

-- Handle NUI callbacks from the phone UI
RegisterNUICallback("AccountSwitcher", function(data, cb)
  debugprint("AccountSwitcher:" .. (data.action or ""))

  -- Validate phone is active and app is supported
  if not currentPhone or not supportedApps[data.app] then
    debugprint("AccountSwitcher: Invalid app / no currentPhone", data.app)
    return cb(false)
  end

  if data.action == "switch" then
    -- Request account switch on the server
    TriggerCallback("accountSwitcher:switchAccount", cb, data.app, data.account)

  elseif data.action == "getAccounts" then
    -- Fetch logged-in accounts for this app, then return just usernames
    TriggerCallback("accountSwitcher:getAccounts", function(accounts)
      if not accounts then
        return cb(false)
      end

      local usernames = {}
      for i = 1, #accounts do
        usernames[i] = accounts[i].username
      end
      cb(usernames)
    end, data.app)
  end
end)

-- Fired by server when another device logs out of an app account
RegisterNetEvent("phone:logoutFromApp")
AddEventHandler("phone:logoutFromApp", function(data)
  debugprint("logoutFromApp:", data)

  -- Ignore if the event is for our own phone number
  if data.number and data.number == currentPhone then
    return debugprint("Ignoring logoutFromApp event since number matches")
  end

  -- Notify the React UI to log out of the account
  debugprint(data.app .. ":logout", data.username)
  SendReactMessage(data.app .. ":logout", data.username)
end)