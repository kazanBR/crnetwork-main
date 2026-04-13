-- Global state flags
cameraOpen   = false
local isSelfieMode  = false  -- true when front-facing camera is active
local isRecording   = false  -- true while video recording is in progress
local hudHidden     = false  -- true when HUD is hidden during camera use
local recordingPeer = nil    -- peer ID for the current video recording session
local currentUpload = nil    -- cached upload-method object

-- Media-type slug lookup table
local mediaTypeSlugs = {}
mediaTypeSlugs.selfies     = "selfie"
mediaTypeSlugs.screenshots = "screenshot"
mediaTypeSlugs.imports     = "import"

-- ─────────────────────────────────────────────────────────────
-- GetBaseUrl
-- Returns (and caches) the base upload URL from the server.
-- ─────────────────────────────────────────────────────────────
local function activateCellCamera()  -- forward-declared below as GetBaseUrl
end

function activateCellCamera()
  if not currentUpload then
    currentUpload = AwaitCallback("camera:getBaseUrl")
  end
  return currentUpload
end
GetBaseUrl = activateCellCamera

-- ─────────────────────────────────────────────────────────────
-- startNativeCameraLoop  (original: second AKL6_1 definition)
-- Activates the GTA native cell-cam, runs the idle-cam loop,
-- then tears down or re-opens the phone when done.
-- ─────────────────────────────────────────────────────────────
local startNativeCameraLoop  -- forward declaration used inside itself

startNativeCameraLoop = function()
  -- Hide phone animation and mount it as a camera prop
  TogglePhoneAnimation(false, "camera")
  CreateMobilePhone(0)
  CellCamActivate(true, true)
  CellCamActivateSelfieMode(isSelfieMode)

  -- After 500 ms, delete any nearby phone-prop objects (model 413312110)
  SetTimeout(500, function()
    local objects   = GetGamePool("CObject")
    local playerPos = GetEntityCoords(PlayerPedId())

    for _, obj in ipairs(objects) do
      local dist = #(playerPos - GetEntityCoords(obj))
      if dist < 4.0 then
        if GetEntityModel(obj) == 413312110 then
          -- Mark as mission entity so we can safely delete it
          SetEntityAsMissionEntity(obj, true, true)
          DeleteObject(obj)
        end
      end
    end
  end)

  -- Keep the idle-cam invalidated while the camera is open
  while phoneOpen and cameraOpen and not IsWalkingCamEnabled() do
    Wait(250)
    InvalidateIdleCam()
    InvalidateVehicleIdleCam()
  end

  -- Restore phone animation on exit
  if cameraOpen then
    TogglePhoneAnimation(true, "camera")
  elseif phoneOpen then
    TogglePhoneAnimation(true)
  end

  DestroyMobilePhone()

  -- If camera is still open and not in walkable mode, wait for the
  -- phone to close and then restart the native camera loop.
  if cameraOpen and not IsWalkingCamEnabled() then
    while not phoneOpen do
      Wait(500)
    end
    startNativeCameraLoop()
  end
end
GetBaseUrl = activateCellCamera  -- keep public alias pointing to the cache helper

-- ─────────────────────────────────────────────────────────────
-- normalizeFilter  (original: AKL7_1)
-- Normalises a gallery-filter table before sending it to the server.
-- ─────────────────────────────────────────────────────────────
local function normalizeFilter(filter)
  -- "recents" and "favourites" are virtual albums – clear the album field
  if filter.album == "recents" then
    filter.album = nil
  elseif filter.album == "favourites" then
    filter.album     = nil
    filter.favourites = true
  end

  -- "videos" maps to explicit show-flags
  if filter.type == "videos" then
    filter = { showPhotos = false, showVideos = true }
  end

  -- Translate named types to their server slugs
  if filter.type then
    filter.album = nil
    local slug = mediaTypeSlugs[filter.type]
    if slug then
      filter.type = slug
    else
      filter.type       = nil
      filter.duplicates = true
    end
  end

  -- Default to showing both photos and videos when nothing is specified
  if not filter.showPhotos and not filter.showVideos then
    filter.showPhotos = true
    filter.showVideos = true
  end

  return filter
end

-- ─────────────────────────────────────────────────────────────
-- getUploadMethod  (original: AKL8_1)
-- Resolves and returns the upload-method config for a given
-- upload type (selfie / screenshot / import).
-- Returns a string error message on failure.
-- ─────────────────────────────────────────────────────────────
local function getUploadMethod(uploadType)
  local method = nil

  if CustomGetUploadMethod then
    -- Server script provides a custom resolver
    method = CustomGetUploadMethod(uploadType)
  else
    if not UploadMethods then
      infoprint("error", "Upload methods not found")
      return "No upload methods found. The server devs have broken the upload.lua file. Tell the server devs to reinstall lb-phone."
    end

    -- Look up by config key, then by uploadType-specific sub-method or Default
    local configKey = Config.UploadMethod[uploadType]
    local methodGroup = UploadMethods[configKey]

    if not methodGroup then
      infoprint("error", "Upload methods not found for ", uploadType)
      return "No upload methods found for '" .. tostring(configKey) .. "'. Tell the server devs to reinstall lb-phone."
    end

    -- Pick the most specific sub-method: uploadType > Default
    method = methodGroup[uploadType] or methodGroup.Default

    if not method then
      infoprint("error", "Upload method not found for ", uploadType)
      return "No upload method found for '" .. uploadType .. "' using '" .. tostring(configKey) .. "'. Tell the server devs to reinstall lb-phone."
    end
  end

  -- Cache the resolved config key on the method object
  if not method.method then
    method.method = Config.UploadMethod[uploadType]
  end

  -- Attach player identity if the method requires it
  if method.sendPlayer and not method.player then
    method.player = {
      identifier = GetIdentifier(),
      name       = GetPlayerName(PlayerId()),
    }
  end

  -- Replace BASE_URL placeholder in the URL
  if method.url and method.url:find("BASE_URL") then
    method.url = method.url:gsub("BASE_URL", GetBaseUrl())
  end

  -- Replace API_KEY placeholder in the URL and headers
  local needsApiKey = method.url and method.url:find("API_KEY")
  if not needsApiKey and method.headers then
    for _, v in pairs(method.headers) do
      if v:find("API_KEY") then
        needsApiKey = true
        break
      end
    end
  end

  if needsApiKey then
    local apiKey = AwaitCallback("camera:getUploadApiKey", uploadType)
    method.url = method.url:gsub("API_KEY", apiKey)
    if method.headers then
      for k, v in pairs(method.headers) do
        method.headers[k] = v:gsub("API_KEY", apiKey)
      end
    end
  end

  -- Replace PRESIGNED_URL placeholder
  if method.url and method.url:find("PRESIGNED_URL") then
    local presigned = AwaitCallback("camera:getPresignedUrl", uploadType)
    if not presigned then
      infoprint("error", "Failed to get presigned url for " .. uploadType)
      return "Failed to get presigned url for '" .. uploadType .. "'. The devs have most likely not set a valid token in lb-phone/server/apiKeys.lua. Tell the server devs to check the console for errors."
    end
    method.presignedUrl = method.url:gsub("PRESIGNED_URL", presigned)
  end

  return method
end

-- ─────────────────────────────────────────────────────────────
-- getCameraButtons  (original: AKL9_1)
-- Builds and returns the list of instructional button labels
-- to display while the camera is active.
-- ─────────────────────────────────────────────────────────────
local function getCameraButtons()
  local buttons  = {}
  local binds    = Config.KeyBinds

  -- Helper: append a single-key button entry
  local function addButton(labelKey, bindKey, params)
    local bind = binds[bindKey]
    if bind and bind.Command and bind.bindData then
      params     = params or {}
      params.key = bind.bindData.instructional
      buttons[#buttons + 1] = L(labelKey, params)
    end
  end

  -- Helper: append a dual-key button entry (e.g. Left / Right)
  local function addDualButton(labelKey, leftKey, rightKey)
    local left  = binds[leftKey]
    local right = binds[rightKey]
    if  left  and left.Command  and left.bindData
    and right and right.Command and right.bindData then
      buttons[#buttons + 1] = L(labelKey, {
        key  = left.bindData.instructional,
        key2 = right.bindData.instructional,
      })
    end
  end

  addButton("BACKEND.CAMERA.TAKE_PHOTO",     "TakePhoto")
  addButton("BACKEND.CAMERA.FLIP_CAMERA",    "FlipCamera")
  addButton("BACKEND.CAMERA.TOGGLE_FLASH",   "ToggleFlash")
  addDualButton("BACKEND.CAMERA.CHANGE_MODE", "LeftMode",  "RightMode")
  addDualButton("BACKEND.CAMERA.ROLL",        "RollLeft",  "RollRight")

  -- Freeze button only shown when the freeze feature is enabled
  if Config.Camera and Config.Camera.Freeze and Config.Camera.Freeze.Enabled then
    addButton("BACKEND.CAMERA.FREEZE", "FreezeCamera")
  end

  addButton("BACKEND.CAMERA.TOGGLE_CURSOR", "Focus")

  return buttons
end

-- ─────────────────────────────────────────────────────────────
-- RegisterNUICallback: "Camera"  (original: AKL12_1 for Camera)
-- Central NUI handler – routes every camera action from the UI.
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("Camera", function(data, cb)
  if not currentPhone then return end

  if not data then
    return debugprint("Camera data is nil")
  end

  local action = data.action
  debugprint("Camera:" .. (action or ""))

  -- ── open ─────────────────────────────────────────────────
  if action == "open" then
    cb("ok")
    cameraOpen = true
    DisplayCameraButtons(getCameraButtons())

    if Config.Camera and Config.Camera.Walkable then
      debugprint("Using walkable cam")
      EnableWalkableCam()
    else
      debugprint("Using native GTA cam")
      startNativeCameraLoop()
    end

  -- ── saveToGallery ────────────────────────────────────────
  elseif action == "saveToGallery" then
    -- Coerce isVideo to a strict boolean
    local isVideo = data.isVideo and true or false
    TriggerCallback("camera:saveToGallery", cb, data.link, data.size, isVideo, data.type, data.shouldLog)

  -- ── deleteFromGallery ────────────────────────────────────
  elseif action == "deleteFromGallery" then
    -- Ensure ids is always a table
    if type(data.ids) ~= "table" then
      data.ids = { data.ids }
    end
    TriggerCallback("camera:deleteFromGallery", cb, data.ids)

  -- ── getLastImage ─────────────────────────────────────────
  elseif action == "getLastImage" then
    TriggerCallback("camera:getLastImage", cb)

  -- ── getImages ────────────────────────────────────────────
  elseif action == "getImages" then
    local filter = normalizeFilter(data.filter or {})
    local page   = data.page or 0
    local raw    = AwaitCallback("camera:getImages", filter, page)

    -- Map raw DB rows to the shape the UI expects
    local images = {}
    for i, row in ipairs(raw) do
      images[i] = {
        id        = row.id,
        src       = row.link,
        isVideo   = row.is_video,
        type      = row.metadata,
        favourite = row.is_favourite,
        timestamp = row.timestamp,
        size      = row.size or 0,
      }
    end
    cb(images)

  -- ── getAlbums ────────────────────────────────────────────
  elseif action == "getAlbums" then
    TriggerCallback("camera:getHomePageData", cb)

  -- ── createAlbum ──────────────────────────────────────────
  elseif action == "createAlbum" then
    TriggerCallback("camera:createAlbum", cb, data.title)

  -- ── renameAlbum ──────────────────────────────────────────
  elseif action == "renameAlbum" then
    TriggerCallback("camera:renameAlbum", cb, data.id, data.title)

  -- ── addToAlbum ───────────────────────────────────────────
  elseif action == "addToAlbum" then
    TriggerCallback("camera:addToAlbum", cb, data.album, data.ids)

  -- ── removeFromAlbum ──────────────────────────────────────
  elseif action == "removeFromAlbum" then
    TriggerCallback("camera:removeFromAlbum", cb, data.album, data.ids)

  -- ── deleteAlbum ──────────────────────────────────────────
  elseif action == "deleteAlbum" then
    TriggerCallback("camera:deleteAlbum", cb, data.id)

  -- ── removeMemberFromAlbum ────────────────────────────────
  elseif action == "removeMemberFromAlbum" then
    TriggerCallback("camera:removeMemberFromAlbum", cb, data.number, data.album)

  -- ── leaveSharedAlbum ─────────────────────────────────────
  elseif action == "leaveSharedAlbum" then
    TriggerCallback("camera:leaveSharedAlbum", cb, data.id)

  -- ── getAlbumMembers ──────────────────────────────────────
  elseif action == "getAlbumMembers" then
    TriggerCallback("camera:getAlbumMembers", cb, data.id)

  -- ── toggleFavourites ─────────────────────────────────────
  elseif action == "toggleFavourites" then
    TriggerCallback("camera:toggleFavourites", cb, data.favourite, data.ids)

  -- ── toggleVideo ──────────────────────────────────────────
  elseif action == "toggleVideo" then
    -- No-op if state hasn't changed
    if isRecording == data.toggled then
      return cb("ok")
    end
    isRecording  = data.toggled
    cameraOpen   = true
    cb("ok")

    SendReactMessage("camera:toggleMicrophone", IsTalking())

    -- Choose walkable or native camera mode
    if isRecording and Config.Camera and Config.Camera.Walkable then
      EnableWalkableCam(isSelfieMode)
    else
      DisableWalkableCam()
      startNativeCameraLoop()
    end

  -- ── toggleHud ────────────────────────────────────────────
  elseif action == "toggleHud" then
    hudHidden = not data.toggled
    TriggerEvent("lb-phone:toggleHud", hudHidden)
    ToggleHudComponents(not data.toggled)
    Wait(100)
    cb(true)

  -- ── getUploadApi ─────────────────────────────────────────
  elseif action == "getUploadApi" then
    cb(getUploadMethod(data.uploadType) or false)

  -- ── toggleLandscape ──────────────────────────────────────
  elseif action == "toggleLandscape" then
    -- Coerce toggled to a strict boolean (or nil to clear)
    local landscape = data.toggled and true or nil
    LocalPlayer.state:set("phoneLandscape", landscape, true)

    if data.toggled then
      AttachPhone({ landscape = true })
    else
      AttachPhone()
    end
    cb("ok")

  -- ── flipCamera ───────────────────────────────────────────
  elseif action == "flipCamera" then
    local wantSelfie = (data.value == true)
    -- No-op if mode hasn't changed
    if isSelfieMode == wantSelfie then
      return cb("ok")
    end
    isSelfieMode = wantSelfie

    if IsWalkingCamEnabled() then
      ToggleSelfieCam(isSelfieMode)
    else
      CellCamActivateSelfieMode(isSelfieMode)
    end
    cb("ok")

  -- ── setQuickZoom ─────────────────────────────────────────
  elseif action == "setQuickZoom" then
    if IsWalkingCamEnabled() then
      SetCameraZoom(data.value)
    end
    cb(true)

  -- ── setRecordingPeerId ───────────────────────────────────
  elseif action == "setRecordingPeerId" then
    TriggerServerEvent("phone:camera:setPeer", data.peerId)
    recordingPeer = data.peerId
    cb("ok")

  -- ── endedRecording ───────────────────────────────────────
  elseif action == "endedRecording" then
    if recordingPeer then
      TriggerServerEvent("phone:camera:endedRecording", recordingPeer)
      recordingPeer = nil
      cb("ok")
    end

  -- ── close ────────────────────────────────────────────────
  elseif action == "close" then
    cameraOpen   = false
    isRecording  = false
    isSelfieMode = false
    StopDisplayingCameraButtons()
    DisableWalkableCam()

    -- Clear landscape state if it was active
    if LocalPlayer.state.phoneLandscape then
      LocalPlayer.state:set("phoneLandscape", nil, true)
    end
    cb("ok")
  end
end)

-- ─────────────────────────────────────────────────────────────
-- exports.SaveToGallery
-- Public export: saves a media URL to the player's gallery.
-- ─────────────────────────────────────────────────────────────
exports("SaveToGallery", function(link)
  assert(type(link) == "string", "Expected string for link, got " .. type(link))
  SendReactMessage("saveMedia", link)
end)

-- ─────────────────────────────────────────────────────────────
-- Network events: shared-album notifications pushed from server
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("phone:photos:addMemberToAlbum", function(albumId, phoneNumber)
  SendReactMessage("photos:addMemberToAlbum", { albumId = albumId, phoneNumber = phoneNumber })
end)

RegisterNetEvent("phone:photos:removeMemberFromAlbum", function(albumId, phoneNumber)
  SendReactMessage("photos:removeMemberFromAlbum", { albumId = albumId, phoneNumber = phoneNumber })
end)

RegisterNetEvent("phone:photos:addSharedAlbum", function(albumData)
  SendReactMessage("photos:addSharedAlbum", albumData)
end)

RegisterNetEvent("phone:photos:updateAlbum", function(albumData)
  debugprint("phone:photos:updateAlbum", albumData)
  SendReactMessage("photos:updateAlbum", albumData)
end)