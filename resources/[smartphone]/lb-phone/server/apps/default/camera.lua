-- Cached base URL (lazy-loaded from convar)
local cachedBaseUrl = nil

-- ─────────────────────────────────────────────────────────────
-- camera:getBaseUrl
-- Returns (and caches) the base URL from the "web_baseUrl" convar.
-- ─────────────────────────────────────────────────────────────
RegisterCallback("camera:getBaseUrl", function()
  if not cachedBaseUrl then
    cachedBaseUrl = GetConvar("web_baseUrl", "")
  end
  return cachedBaseUrl
end)

-- ─────────────────────────────────────────────────────────────
-- camera:getPresignedUrl
-- Fetches a presigned upload URL for the given upload type.
-- For Fivemanage: performs an HTTP request to their API.
-- For others: delegates to the custom GetPresignedUrl function.
-- ─────────────────────────────────────────────────────────────
RegisterCallback("camera:getPresignedUrl", function(source, uploadType)
  local uploadMethod = Config.UploadMethod[uploadType]

  if uploadMethod ~= "Fivemanage" then
    -- Use the server-defined custom function if available
    if GetPresignedUrl then
      return GetPresignedUrl(source, uploadType)
    else
      infoprint("warning", "GetPresignedUrl has not been set up. Set it up in lb-phone/server/custom/functions/functions.lua, or change your upload method to Fivemanage.")
    end
    return
  end

  -- Fivemanage: request a presigned URL via HTTP
  local p = promise.new()

  PerformHttpRequest(
    "https://api.fivemanage.com/api/v3/file/presigned-url",
    function(statusCode, body, headers, err)
      if statusCode ~= 200 then
        infoprint("error", "Failed to get presigned URL from Fivemanage")
        print("Status:", statusCode)
        print("Body:", body)
        print("Headers:", json.encode(headers or {}, { indent = true }))
        if err then
          print("Error:", err)
        end
        -- Resolve with nil to signal failure
        p:resolve(nil)
        return
      end

      local decoded = json.decode(body)
      local presignedUrl = decoded and decoded.data and decoded.data.presignedUrl
      p:resolve(presignedUrl)
    end,
    "GET",
    "",
    { Authorization = API_KEYS[uploadType] }
  )

  return Citizen.Await(p)
end)

-- ─────────────────────────────────────────────────────────────
-- phone:setListeningPeerId  (net event)
-- Tracks which peer ID this player is currently listening to
-- for nearby voice recording, and broadcasts start/stop events.
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("phone:setListeningPeerId", function(peerId)
  if not Config.Voice.RecordNearby then return end

  local playerId    = source
  local playerState = Player(playerId).state

  -- If already listening to someone, broadcast that we stopped
  local previousPeer = playerState.listeningPeerId
  if previousPeer then
    TriggerClientEvent("phone:stoppedListening", -1, previousPeer)
  end

  -- Update state and notify all clients
  playerState.listeningPeerId = peerId
  debugprint(playerId, "set listeningPeerId to", peerId)

  if peerId then
    TriggerClientEvent("phone:startedListening", -1, playerId, peerId)
  end
end)

-- ─────────────────────────────────────────────────────────────
-- playerDropped  (event)
-- Cleans up the listening-peer state when a player disconnects.
-- ─────────────────────────────────────────────────────────────
AddEventHandler("playerDropped", function()
  local playerId    = source
  local listeningTo = Player(playerId).state.listeningPeerId

  if listeningTo then
    debugprint(playerId, "dropped, listeningPeerId", listeningTo)
    TriggerClientEvent("phone:stoppedListening", -1, listeningTo)
  end
end)

-- ─────────────────────────────────────────────────────────────
-- camera:getUploadApiKey
-- Returns the API key for the given upload type.
-- Drops the player if they try to abuse the Fivemanage endpoint
-- (which handles its own auth and doesn't need an exposed key).
-- ─────────────────────────────────────────────────────────────
RegisterCallback("camera:getUploadApiKey", function(source, uploadType)
  -- Only return a key when the type is known and a key exists
  if not uploadType or not API_KEYS[uploadType] then
    return
  end

  -- Fivemanage manages its own auth – exposing the key client-side is an exploit
  if Config.UploadMethod[uploadType] == "Fivemanage" then
    DropPlayer(source, "Tried to abuse the upload system")
    return
  end

  return API_KEYS[uploadType]
end)

-- ─────────────────────────────────────────────────────────────
-- forEachAlbumMember  (internal helper)
-- Queries all members of an album and calls callback(phoneNumber, clientSource)
-- for each one. When includeOwner is false the owner row is omitted.
-- ─────────────────────────────────────────────────────────────
local function forEachAlbumMember(albumId, callback, includeOwner)
  local members = MySQL.query.await(
    "SELECT phone_number FROM phone_photo_album_members WHERE album_id = ?",
    { albumId }
  )
  if not members then return end

  -- Optionally append the album owner so they also receive the event
  if not includeOwner then
    local ownerNumber = MySQL.scalar.await(
      "SELECT phone_number FROM phone_photo_albums WHERE id = ?",
      { albumId }
    )
    members[#members + 1] = { phone_number = ownerNumber }
  end

  for _, row in ipairs(members) do
    local phoneNumber  = row.phone_number
    local clientSource = GetSourceFromNumber(phoneNumber)
    callback(phoneNumber, clientSource)
  end
end

-- ─────────────────────────────────────────────────────────────
-- getAlbumData  (internal helper)
-- Returns a single album row enriched with photo/video counts.
-- ─────────────────────────────────────────────────────────────
local function getAlbumData(albumId)
  local album = MySQL.single.await([[
    SELECT
        pa.id,
        pa.title,
        pa.shared,
        (
            SELECT pp_cover.link
            FROM   phone_photos pp_cover
            JOIN   phone_photo_album_photos ap_cover ON ap_cover.photo_id = pp_cover.id
            WHERE  ap_cover.album_id = pa.id
            ORDER BY ap_cover.photo_id DESC
            LIMIT 1
        ) AS cover,
        SUM(CASE WHEN pp.is_video = 1 THEN 1 ELSE 0 END) AS videoCount,
        SUM(CASE WHEN pp.is_video = 0 THEN 1 ELSE 0 END) AS photoCount
    FROM  phone_photo_albums pa
    LEFT JOIN phone_photo_album_photos ap ON ap.album_id = pa.id
    LEFT JOIN phone_photos             pp ON pp.id = ap.photo_id
    WHERE pa.id = ?
    GROUP BY pa.id, pa.title, pa.shared, pa.phone_number
  ]], { albumId })

  if not album then return end

  album.photoCount = tonumber(album.photoCount or 0)
  album.videoCount = tonumber(album.videoCount or 0)
  album.count      = album.photoCount + album.videoCount
  return album
end

-- ─────────────────────────────────────────────────────────────
-- doesPhoneNumberHaveAccessToAlbum  (internal helper)
-- Returns the album row when the given phone number has read
-- access, or false (with a debug log) when they do not.
-- ─────────────────────────────────────────────────────────────
local function doesPhoneNumberHaveAccessToAlbum(phoneNumber, albumId)
  local album = MySQL.single.await(
    "SELECT phone_number, shared FROM phone_photo_albums WHERE id = ?",
    { albumId }
  )

  if not album then
    debugprint("DoesPhoneNumberHaveAccessToAlbum: Album not found", phoneNumber, albumId)
    return false
  end

  if not album.shared then
    -- Private album: only the owner has access
    if album.phone_number ~= phoneNumber then
      debugprint("DoesPhoneNumberHaveAccessToAlbum: Private album, not the owner", phoneNumber, albumId)
      return false
    end
  else
    -- Shared album: non-owners must be in the members table
    if album.phone_number ~= phoneNumber then
      local isMember = MySQL.scalar.await(
        "SELECT 1 FROM phone_photo_album_members WHERE album_id = ? AND phone_number = ?",
        { albumId, phoneNumber }
      )
      if not isMember then
        debugprint("DoesPhoneNumberHaveAccessToAlbum: Album is shared, but not a member", phoneNumber, albumId)
        return false
      end
    end
  end

  return album
end

-- ─────────────────────────────────────────────────────────────
-- broadcastAlbumUpdate  (internal helper)
-- Notifies all online members of an album that its data changed.
-- ─────────────────────────────────────────────────────────────
local function broadcastAlbumUpdate(albumId)
  local albumData = getAlbumData(albumId)
  if not albumData then return end

  forEachAlbumMember(albumId, function(_, clientSource)
    if clientSource then
      TriggerClientEvent("phone:photos:updateAlbum", clientSource, albumData)
    end
  end)
end

-- Valid metadata types for saved media
local validMediaTypes = {
  selfie     = true,
  import     = true,
  screenshot = true,
}

-- ─────────────────────────────────────────────────────────────
-- camera:saveToGallery
-- Inserts a new photo/video row and optionally logs the upload.
-- Returns the new row ID on success, false when the link is blocked.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:saveToGallery", function(source, phoneNumber, link, size, isVideo, mediaType, shouldLog)
  -- Security: reject disallowed CDN links
  if not IsMediaLinkAllowed(link) then
    infoprint("error",
      ("%s %s tried to save an image with a link that is not allowed:"):format(source, phoneNumber),
      link)
    return false
  end

  -- Sanitise metadata type
  if mediaType and not validMediaTypes[mediaType] then
    debugprint("Invalid metadata", mediaType)
    mediaType = nil
  end

  -- Insert into DB
  local rowId = MySQL.insert.await(
    "INSERT INTO phone_photos (phone_number, link, is_video, size, metadata) VALUES (?, ?, ?, ?, ?)",
    { phoneNumber, link, (isVideo == true), size or 0, mediaType }
  )

  -- Optional activity log
  if shouldLog then
    local mediaTypeLabel = isVideo and L("BACKEND.LOGS.VIDEO") or L("BACKEND.LOGS.PHOTO")
    Log("Uploads", source, "info",
      L("BACKEND.LOGS.UPLOADED_MEDIA"),
      L("BACKEND.LOGS.UPLOADED_MEDIA_DESCRIPTION", { type = mediaTypeLabel, id = rowId, link = link }),
      link)
    TrackSimpleEvent(isVideo and "take_video" or "take_photo")
  end

  return rowId
end)

-- ─────────────────────────────────────────────────────────────
-- camera:deleteFromGallery
-- Deletes one or more photos by ID and fires a deletion event
-- for each removed link so other systems can clean up.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:deleteFromGallery", function(source, phoneNumber, ids)
  -- Fetch links before deletion so we can broadcast them
  local rows = MySQL.query.await(
    "SELECT link FROM phone_photos WHERE phone_number = ? AND id IN (?)",
    { phoneNumber, ids }
  )

  for _, row in ipairs(rows) do
    TriggerEvent("lb-phone:deletedFromGallery", source, phoneNumber, row.link)
  end

  MySQL.update(
    "DELETE FROM phone_photos WHERE phone_number = ? AND id IN (?)",
    { phoneNumber, ids }
  )
  return true
end)

-- ─────────────────────────────────────────────────────────────
-- camera:toggleFavourites
-- Marks or unmarks a list of photos as favourites.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:toggleFavourites", function(source, phoneNumber, isFavourite, ids)
  MySQL.update.await(
    "UPDATE phone_photos SET is_favourite = ? WHERE phone_number = ? AND id IN (?)",
    { (isFavourite == true), phoneNumber, ids }
  )
  return true
end)

-- ─────────────────────────────────────────────────────────────
-- camera:getImages
-- Returns a paginated list of photos/videos matching the filter.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:getImages", function(source, phoneNumber, filter, page)
  -- Nothing to show if both flags are off
  if not filter.showVideos and not filter.showPhotos then
    return {}
  end

  local params  = { phoneNumber }
  local clauses = { "phone_number = ?" }
  local baseSQL = "SELECT id, link, is_video, size, metadata, is_favourite, `timestamp` FROM phone_photos {WHERE}"

  -- Filter by video/photo type when they differ
  if filter.showPhotos ~= filter.showVideos then
    clauses[#clauses + 1] = "(is_video = ? OR is_video != ?)"
    params[#params + 1]   = (filter.showVideos == true)
    params[#params + 1]   = (filter.showPhotos == true)
  end

  if filter.favourites == true then
    clauses[#clauses + 1] = "is_favourite = 1"
  end

  if filter.type then
    clauses[#clauses + 1] = "metadata = ?"
    params[#params + 1]   = filter.type
  end

  if filter.album then
    -- Verify access then scope to album contents
    if not doesPhoneNumberHaveAccessToAlbum(phoneNumber, filter.album) then
      debugprint("getImages: No access to album", phoneNumber, filter.album)
      return {}
    end
    -- Replace the phone_number clause with an album membership clause
    table.remove(clauses, 1)
    table.remove(params,  1)
    clauses[#clauses + 1] = "id IN (SELECT ap.photo_id FROM phone_photo_album_photos ap WHERE ap.album_id = ?)"
    params[#params + 1]   = filter.album
  end

  if filter.duplicates then
    clauses[#clauses + 1] = [[
      link IN (
        SELECT link FROM phone_photos
        WHERE phone_number = ?
        GROUP BY link HAVING COUNT(1) > 1
      )
    ]]
    params[#params + 1] = phoneNumber
  end

  -- Build WHERE clause and pagination
  local perPage   = math.clamp(filter.perPage or 32, 1, 32)
  local whereStr  = #clauses > 0 and ("WHERE " .. table.concat(clauses, " AND ")) or ""
  local finalSQL  = (baseSQL .. " ORDER BY `timestamp` DESC LIMIT ?, ?"):gsub("{WHERE}", whereStr)

  params[#params + 1] = (page or 0) * perPage  -- offset
  params[#params + 1] = perPage                 -- limit

  return MySQL.query.await(finalSQL, params)
end)

-- ─────────────────────────────────────────────────────────────
-- camera:getLastImage
-- Returns the URL of the most recently saved photo for a number.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:getLastImage", function(source, phoneNumber)
  return MySQL.scalar.await(
    "SELECT link FROM phone_photos WHERE phone_number = ? ORDER BY id DESC LIMIT 1",
    { phoneNumber }
  )
end)

-- ─────────────────────────────────────────────────────────────
-- camera:createAlbum
-- Creates a new personal album and returns its new row ID.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:createAlbum", function(source, phoneNumber, title)
  return MySQL.insert.await(
    "INSERT INTO phone_photo_albums (phone_number, title) VALUES (?, ?)",
    { phoneNumber, title }
  )
end)

-- ─────────────────────────────────────────────────────────────
-- camera:renameAlbum
-- Renames an album the player owns. Notifies online members
-- of shared albums so they see the new name immediately.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:renameAlbum", function(source, phoneNumber, albumId, newTitle)
  local affected = MySQL.update.await(
    "UPDATE phone_photo_albums SET title = ? WHERE phone_number = ? AND id = ?",
    { newTitle, phoneNumber, albumId }
  )

  local updated = affected > 0
  if updated then
    -- Broadcast to members of shared albums
    local isShared = MySQL.scalar.await(
      "SELECT shared FROM phone_photo_albums WHERE id = ?",
      { albumId }
    )
    if isShared then
      forEachAlbumMember(albumId, function(_, clientSource)
        if clientSource then
          TriggerClientEvent("phone:photos:renameAlbum", clientSource, albumId, newTitle)
        end
      end, true)
    end
  end

  return updated
end)

-- ─────────────────────────────────────────────────────────────
-- camera:addToAlbum
-- Adds a list of photos to an album the player has access to.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:addToAlbum", function(source, phoneNumber, albumId, photoIds)
  if not doesPhoneNumberHaveAccessToAlbum(phoneNumber, albumId) then
    debugprint("No access to album", phoneNumber, albumId)
    return false
  end

  MySQL.update.await(
    "INSERT IGNORE INTO phone_photo_album_photos (album_id, photo_id) SELECT ?, id FROM phone_photos WHERE phone_number = ? AND id IN (?)",
    { albumId, phoneNumber, photoIds }
  )
  debugprint("Added photos to album", phoneNumber, albumId, photoIds)

  -- Notify members of shared albums that content changed
  local album = doesPhoneNumberHaveAccessToAlbum(phoneNumber, albumId)
  if album and album.shared then
    broadcastAlbumUpdate(albumId)
  end

  return true
end)

-- ─────────────────────────────────────────────────────────────
-- camera:removeFromAlbum
-- Removes a list of photos from an album and notifies members.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:removeFromAlbum", function(source, phoneNumber, albumId, photoIds)
  if not doesPhoneNumberHaveAccessToAlbum(phoneNumber, albumId) then
    debugprint("No access to album", phoneNumber, albumId)
    return false
  end

  MySQL.update.await(
    "DELETE FROM phone_photo_album_photos WHERE album_id = ? AND photo_id IN (?)",
    { albumId, photoIds }
  )
  broadcastAlbumUpdate(albumId)
  return true
end)

-- ─────────────────────────────────────────────────────────────
-- camera:deleteAlbum
-- Deletes a personal album. For shared albums, notifies all
-- members that they have been removed before the row is gone.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:deleteAlbum", function(source, phoneNumber, albumId)
  local album = MySQL.single.await(
    "SELECT shared FROM phone_photo_albums WHERE phone_number = ? AND id = ?",
    { phoneNumber, albumId }
  )

  if not album then
    debugprint("deleteAlbum: Album not found", phoneNumber, albumId)
    return false
  end

  -- Notify all members of shared albums that the album is gone
  if album.shared then
    forEachAlbumMember(albumId, function(memberNumber, clientSource)
      if clientSource then
        TriggerClientEvent("phone:photos:removeMemberFromAlbum", clientSource, albumId, memberNumber)
      end
    end, true)
  end

  MySQL.update(
    "DELETE FROM phone_photo_albums WHERE phone_number = ? AND id = ?",
    { phoneNumber, albumId }
  )
  return true
end)

-- Keys used to order the mediaTypes counts in the home page response
local mediaTypeKeys = {
  "videos", "photos",
  "favouritesVideos", "favouritesPhotos",
  "selfiesVideos",    "selfiesPhotos",
  "screenshotsVideos","screenshotsPhotos",
  "importsVideos",    "importsPhotos",
  "duplicatesPhotos", "duplicatesVideos",
}

-- ─────────────────────────────────────────────────────────────
-- camera:getHomePageData
-- Returns the full gallery home-page payload: aggregated counts
-- for the built-in categories plus all of the player's albums.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:getHomePageData", function(source, phoneNumber)
  -- ── Aggregate media-type counts ──────────────────────────
  local counts = MySQL.single.await([[
    SELECT
        SUM(is_video = 1)                              AS videos,
        SUM(is_video = 0)                              AS photos,
        SUM(is_video = 1 AND is_favourite = 1)         AS favouritesVideos,
        SUM(is_video = 0 AND is_favourite = 1)         AS favouritesPhotos,
        SUM(metadata = 'selfie'     AND is_video = 1)  AS selfiesVideos,
        SUM(metadata = 'selfie'     AND is_video = 0)  AS selfiesPhotos,
        SUM(metadata = 'screenshot' AND is_video = 1)  AS screenshotsVideos,
        SUM(metadata = 'screenshot' AND is_video = 0)  AS screenshotsPhotos,
        SUM(metadata = 'import'     AND is_video = 1)  AS importsVideos,
        SUM(metadata = 'import'     AND is_video = 0)  AS importsPhotos
    FROM phone_photos
    WHERE phone_number = ?
  ]], { phoneNumber })

  -- Duplicate counts = total minus unique links
  local uniquePhotos = MySQL.scalar.await([[
    SELECT COUNT(DISTINCT link) FROM phone_photos
    WHERE phone_number = ? AND is_video = 0
  ]], { phoneNumber })
  counts.duplicatesPhotos = tonumber(counts.photos or 0) - uniquePhotos

  local uniqueVideos = MySQL.scalar.await([[
    SELECT COUNT(DISTINCT link) FROM phone_photos
    WHERE phone_number = ? AND is_video = 1
  ]], { phoneNumber })
  counts.duplicatesVideos = tonumber(counts.videos or 0) - uniqueVideos

  -- Normalise all count values to numbers
  for _, key in ipairs(mediaTypeKeys) do
    counts[key] = tonumber(counts[key] or 0)
  end

  -- Add 1 to duplicate counts so the "duplicates" virtual album shows correctly
  if counts.duplicatesPhotos > 0 then counts.duplicatesPhotos = counts.duplicatesPhotos + 1 end
  if counts.duplicatesVideos > 0 then counts.duplicatesVideos = counts.duplicatesVideos + 1 end

  -- ── Build built-in virtual albums (Recents, Favourites) ─
  local albums = {
    {
      id         = "recents",
      title      = L("APPS.PHOTOS.RECENTS"),
      videoCount = counts.videos,
      photoCount = counts.photos,
      cover      = MySQL.scalar.await(
        "SELECT link FROM phone_photos WHERE phone_number = ? ORDER BY id DESC LIMIT 1",
        { phoneNumber }
      ),
      removable  = false,
    },
    {
      id         = "favourites",
      title      = L("APPS.PHOTOS.FAVOURITES"),
      videoCount = counts.favouritesVideos,
      photoCount = counts.favouritesPhotos,
      cover      = MySQL.scalar.await(
        "SELECT link FROM phone_photos WHERE phone_number = ? AND is_favourite = 1 ORDER BY id DESC LIMIT 1",
        { phoneNumber }
      ),
      removable  = false,
    },
  }

  -- ── Fetch user-created albums (owned + shared) ───────────
  local userAlbums = MySQL.query.await([[
    SELECT
        pa.id,
        pa.title,
        pa.shared,
        pa.phone_number,
        (
            SELECT pp_cover.link
            FROM   phone_photos pp_cover
            JOIN   phone_photo_album_photos ap_cover ON ap_cover.photo_id = pp_cover.id
            WHERE  ap_cover.album_id = pa.id
            ORDER BY ap_cover.photo_id DESC
            LIMIT 1
        ) AS cover,
        SUM(CASE WHEN pp.is_video = 1 THEN 1 ELSE 0 END) AS videoCount,
        SUM(CASE WHEN pp.is_video = 0 THEN 1 ELSE 0 END) AS photoCount
    FROM  phone_photo_albums pa
    LEFT JOIN phone_photo_album_photos ap     ON ap.album_id = pa.id
    LEFT JOIN phone_photos             pp     ON pp.id = ap.photo_id
    WHERE pa.phone_number = ?
       OR EXISTS (
           SELECT 1 FROM phone_photo_album_members member
           WHERE member.album_id = pa.id AND member.phone_number = ?
       )
    GROUP BY pa.id, pa.title, pa.shared, pa.phone_number
    ORDER BY pa.id ASC
  ]], { phoneNumber, phoneNumber })

  for _, album in ipairs(userAlbums) do
    album.removable   = true
    album.isOwner     = (album.phone_number == phoneNumber)
    album.phone_number = nil  -- don't expose raw numbers to the client

    -- Normalise counts
    album.photoCount = tonumber(album.photoCount or 0)
    album.videoCount = tonumber(album.videoCount or 0)
    album.count      = album.photoCount + album.videoCount

    albums[#albums + 1] = album
  end

  return { albums = albums, mediaTypes = counts }
end,
-- Default empty response while loading
{ albums = {}, mediaTypes = {} })

-- ─────────────────────────────────────────────────────────────
-- camera:getAlbumMembers
-- Returns the phone numbers of everyone in an album, including
-- the owner, for the membership management UI.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:getAlbumMembers", function(source, phoneNumber, albumId)
  if not doesPhoneNumberHaveAccessToAlbum(phoneNumber, albumId) then
    debugprint("getAlbumMembers: No access to album", phoneNumber, albumId)
    return false
  end

  -- Fetch member rows
  local memberRows = MySQL.query.await(
    "SELECT phone_number FROM phone_photo_album_members WHERE album_id = ?",
    { albumId }
  )

  local members = {}
  for i, row in ipairs(memberRows) do
    members[i] = row.phone_number
  end

  -- Append the owner so the UI shows the full list
  local ownerNumber = MySQL.scalar.await(
    "SELECT phone_number FROM phone_photo_albums WHERE id = ?",
    { albumId }
  )
  members[#members + 1] = ownerNumber

  return members
end)

-- ─────────────────────────────────────────────────────────────
-- removeMemberFromAlbum  (internal helper)
-- Deletes a member row, un-shares the album when empty,
-- and notifies the removed player's client.
-- ─────────────────────────────────────────────────────────────
local function removeMemberFromAlbum(memberNumber, albumId)
  local affected = MySQL.update.await(
    "DELETE FROM phone_photo_album_members WHERE album_id = ? AND phone_number = ?",
    { albumId, memberNumber }
  )

  if affected == 0 then
    debugprint("removeMemberFromAlbum: failed to remove member from album", memberNumber, albumId)
    return false
  end

  -- Notify remaining online members
  forEachAlbumMember(albumId, function(_, clientSource)
    if clientSource then
      TriggerClientEvent("phone:photos:removeMemberFromAlbum", clientSource, albumId, memberNumber)
    end
  end)

  -- If no members remain, mark the album as private
  local remainingCount = MySQL.scalar.await(
    "SELECT COUNT(1) FROM phone_photo_album_members WHERE album_id = ?",
    { albumId }
  )
  if remainingCount == 0 then
    MySQL.update.await(
      "UPDATE phone_photo_albums SET shared = 0 WHERE id = ?",
      { albumId }
    )
  end

  -- Notify the removed player's client directly if they are online
  local removedSource = GetSourceFromNumber(memberNumber)
  if removedSource then
    TriggerClientEvent("phone:photos:removeMemberFromAlbum", removedSource, albumId, memberNumber)
  end

  return true
end

-- ─────────────────────────────────────────────────────────────
-- camera:removeMemberFromAlbum
-- Only the album owner may remove a member.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:removeMemberFromAlbum", function(source, phoneNumber, memberNumber, albumId)
  -- Verify ownership
  local isOwner = MySQL.scalar.await(
    "SELECT 1 FROM phone_photo_albums WHERE id = ? AND phone_number = ?",
    { albumId, phoneNumber }
  )
  if not isOwner then
    debugprint("removeMemberFromAlbum: not the owner of the album", phoneNumber, albumId)
    return
  end

  return removeMemberFromAlbum(memberNumber, albumId)
end)

-- ─────────────────────────────────────────────────────────────
-- camera:leaveSharedAlbum
-- Lets the current player remove themselves from a shared album.
-- ─────────────────────────────────────────────────────────────
BaseCallback("camera:leaveSharedAlbum", function(source, phoneNumber, albumId)
  removeMemberFromAlbum(phoneNumber, albumId)
  return true
end)

-- ─────────────────────────────────────────────────────────────
-- HandleAcceptAirShareAlbum
-- Called when a player accepts an AirShare album invitation.
-- Validates ownership, checks membership, then inserts the
-- new member row and notifies all relevant clients.
-- ─────────────────────────────────────────────────────────────
function HandleAcceptAirShareAlbum(recipientSource, senderSource, albumId)
  local senderNumber    = GetEquippedPhoneNumber(senderSource)
  local recipientNumber = GetEquippedPhoneNumber(recipientSource)

  if not senderNumber or not recipientNumber then
    debugprint("HandleAcceptAirShareAlbum: senderPhoneNumber/recipientPhoneNumber not found", senderNumber, recipientNumber)
    return
  end

  -- Guard: recipient is already a member
  local alreadyMember = MySQL.scalar.await(
    "SELECT 1 FROM phone_photo_album_members WHERE album_id = ? AND phone_number = ?",
    { albumId, recipientNumber }
  )
  if alreadyMember then
    debugprint("HandleAcceptAirShareAlbum: recipient is already a member of the album", senderNumber, recipientNumber, albumId)
    return
  end

  -- Guard: sender must own the album
  local isOwner = MySQL.scalar.await(
    "SELECT 1 FROM phone_photo_albums WHERE id = ? AND phone_number = ?",
    { albumId, senderNumber }
  )
  if not isOwner then
    debugprint("HandleAcceptAirShareAlbum: sender is not the owner of the album", senderNumber, recipientNumber, albumId)
    return
  end

  -- Mark album as shared
  MySQL.update.await(
    "UPDATE phone_photo_albums SET shared = 1 WHERE id = ?",
    { albumId }
  )

  -- Fetch full album data to send to the new member
  local albumData = getAlbumData(albumId)
  if not albumData then
    debugprint("HandleAcceptAirShareAlbum: albumData not found", senderNumber, recipientNumber, albumId)
    return
  end

  -- Notify all existing members (except the recipient who is being added)
  forEachAlbumMember(albumId, function(_, clientSource)
    if clientSource and clientSource ~= recipientSource then
      TriggerClientEvent("phone:photos:addMemberToAlbum", clientSource, albumId, recipientNumber)
    end
  end)

  -- Insert the new member row
  MySQL.insert(
    "INSERT INTO phone_photo_album_members (album_id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
    { albumId, recipientNumber, recipientNumber }
  )

  -- Send the full album data to the new member's client
  TriggerClientEvent("phone:photos:addSharedAlbum", recipientSource, albumData)
end