-- Each entry has: { name, source, device } where device is "phone" or "tablet".
local function getNearbyDevices()
  local devices       = {}
  local nearbyPlayers = GetNearbyPlayers()
  local myCoords      = GetEntityCoords(PlayerPedId())

  debugprint("Nearby players:", nearbyPlayers)

  for i = 1, #nearbyPlayers do
    local player      = nearbyPlayers[i]
    local playerState = Player(player.source).state
    local playerCoords = GetEntityCoords(player.ped)
    local distance    = #(myCoords - playerCoords)

    if distance > 7.5 then
      debugprint("Player is too far away", player.source)
    else
      debugprint("Player data", player.source, player)

      if playerState.lbTabletOpen then
        -- Player has their tablet open
        debugprint("Player has tablet open", player.source)
        devices[#devices + 1] = {
          name   = playerState.lbTabletName or "??",
          source = player.source,
          device = "tablet",
        }
      elseif playerState.phoneOpen then
        -- Player has their phone open
        debugprint("Player has phone open", player.source)
        devices[#devices + 1] = {
          name   = playerState.phoneName or "??",
          source = player.source,
          device = "phone",
        }
      else
        debugprint("Player has no device open", player.source)
      end
    end
  end

  debugprint("Nearby devices:", devices)
  return devices
end

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

-- Handle all AirShare actions dispatched from the phone UI
RegisterNUICallback("AirShare", function(data, cb)
  if not currentPhone then return end

  local action = data.action
  debugprint("AirShare:" .. (action or ""))

  if action == "getNearby" then
    -- Return a list of nearby players with an open device
    cb(getNearbyDevices())

  elseif action == "share" then
    -- Forward the share request to the server
    TriggerCallback("airShare:share", cb, data.source, data.device, data.data)

  elseif action == "accept" then
    -- Notify the server the player accepted the incoming share
    TriggerServerEvent("phone:airShare:interacted", data.source, data.device, true)
    cb("ok")

  elseif action == "deny" then
    -- Notify the server the player denied the incoming share
    TriggerServerEvent("phone:airShare:interacted", data.source, data.device, false)
    cb("ok")
  end
end)

-- ─── Net Events ──────────────────────────────────────────────────────────────

-- Fired by the server when this player receives an incoming AirShare
RegisterNetEvent("phone:airShare:received")
AddEventHandler("phone:airShare:received", function(shareData)
  debugprint("phone:airShare:received", shareData)
  SendReactMessage("airShare:received", shareData)
end)

-- Fired by the server when the sender's share was accepted or denied by the recipient
RegisterNetEvent("phone:airShare:interacted")
AddEventHandler("phone:airShare:interacted", function(senderSource, accepted)
  SendReactMessage("airShare:interacted", {
    source   = senderSource,
    accepted = accepted,
  })
end)