local pendingAlbumShares = {}

-- Valid share types for the AirShare export
local validShareTypes = {}
validShareTypes.image      = true
validShareTypes.contact    = true
validShareTypes.location   = true
validShareTypes.note       = true
validShareTypes.voicememo  = true

-- ─── Callbacks ───────────────────────────────────────────────────────────────

-- Handle an incoming share request from a phone to another device (phone or tablet)
BaseCallback("airShare:share", function(source, cb, targetSource, targetDevice, shareData)
  -- Build sender info from player state, falling back to phone number
  local senderName = Player(source).state.phoneName or cb
  shareData.sender = {
    name   = senderName,
    source = source,
    device = "phone",
  }

  if targetDevice == "tablet" then
    -- Only deliver if lb-tablet resource is running and the target has their tablet open
    if GetResourceState("lb-tablet") ~= "started" then
      return false
    end

    if not Player(targetSource).state.lbTabletOpen then
      return false
    end

    TriggerClientEvent("tablet:airShare:received", targetSource, shareData)

  elseif targetDevice == "phone" then
    -- Only deliver if the target's phone is currently open
    if not Player(targetSource).state.phoneOpen then
      debugprint("sendToSource's phone is not open")
      return false
    end

    TriggerClientEvent("phone:airShare:received", targetSource, shareData)
  end

  -- If sharing an album, track the pending request so the receiver can accept/deny
  if shareData.type == "album" then
    if not pendingAlbumShares[targetSource] then
      pendingAlbumShares[targetSource] = {}
    end
    pendingAlbumShares[targetSource][source] = shareData.album.id
  end

  return true
end, false)

-- ─── Net Events ──────────────────────────────────────────────────────────────

-- Fired when a player interacts with (accepts or denies) an incoming AirShare
RegisterNetEvent("phone:airShare:interacted")
AddEventHandler("phone:airShare:interacted", function(senderSource, senderDevice, accepted)
  local receiverSource = source

  -- Validate input types before proceeding
  if type(senderSource) ~= "number" or type(senderDevice) ~= "string" then
    debugprint("AirShare:interacted: Invalid senderSource or senderDevice", senderSource, senderDevice)
    return
  end

  -- Forward the interaction result back to the original sender's device
  if senderDevice == "tablet" then
    TriggerClientEvent("tablet:airShare:interacted", senderSource, receiverSource, accepted)
  elseif senderDevice == "phone" then
    TriggerClientEvent("phone:airShare:interacted", senderSource, receiverSource, accepted)
  end

  -- Handle pending album share resolution
  local receiverPending = pendingAlbumShares[receiverSource]
  if not receiverPending then return end

  local albumId = receiverPending[senderSource]
  if not albumId then return end

  -- Remove this pending entry and clean up the receiver's table if now empty
  receiverPending[senderSource] = nil
  if not next(receiverPending) then
    pendingAlbumShares[receiverSource] = nil
  end

  if not accepted then
    debugprint("AirShare: denied album share", albumId)
    return
  end

  debugprint("AirShare: accepted album share", albumId)
  HandleAcceptAirShareAlbum(receiverSource, senderSource, albumId)
end)

-- ─── Export ──────────────────────────────────────────────────────────────────

-- Send an AirShare item from one player to another programmatically (server-side API)
exports("AirShare", function(senderSource, targetSource, shareType, data)
  assert(type(senderSource) == "number", "Invalid sender")
  assert(type(targetSource) == "number", "Invalid target")
  assert(validShareTypes[shareType],     "Invalid shareType")
  assert(type(data) == "table",          "Invalid data")

  -- Sender must have a phone equipped
  local phoneNumber = GetEquippedPhoneNumber(senderSource)
  if not phoneNumber then
    return false
  end

  -- Build the share payload
  local senderName = phoneNumber
  local playerState = Player(senderSource)
  if playerState then
    senderName = playerState.state.phoneName or phoneNumber
  end

  local payload = {
    type   = shareType,
    sender = {
      name   = senderName,
      source = senderSource,
      device = "phone",
    },
  }

  -- Validate and attach type-specific data
  if shareType == "image" then
    payload.attachment = data
    assert(data.src, "Invalid image data (missing src)")
    -- Default timestamp to now (milliseconds) if not provided
    if not payload.attachment.timestamp then
      payload.attachment.timestamp = os.time() * 1000
    end

  elseif shareType == "contact" then
    payload.contact = data
    assert(type(data.number) == "string",    "Invalid/missing contact data (contact.number)")
    assert(type(data.firstname) == "string", "Invalid/missing contact data (contact.firstname)")

  elseif shareType == "location" then
    assert(data.location,               "Invalid location data (missing location)")
    assert(type(data.name) == "string", "Invalid/missing location data (location.name)")
    payload.location = data.location
    payload.name     = data.name

  elseif shareType == "note" then
    payload.note = data
    assert(type(data.title) == "string",   "Invalid/missing note data (note.title)")
    assert(type(data.content) == "string", "Invalid/missing note data (note.content)")

  elseif shareType == "voicememo" then
    payload.voicememo = data
    assert(type(data.title) == "string",    "Invalid/missing voicememo data (voicememo.title)")
    assert(type(data.src) == "string",      "Invalid/missing voicememo data (voicememo.src)")
    assert(type(data.duration) == "number", "Invalid/missing voicememo data (voicememo.duration)")
  end

  TriggerClientEvent("phone:airShare:received", targetSource, payload)
end)

-- ─── Event Handlers ──────────────────────────────────────────────────────────

-- Clean up any pending album shares when a player disconnects
AddEventHandler("playerDropped", function()
  pendingAlbumShares[source] = nil
end)