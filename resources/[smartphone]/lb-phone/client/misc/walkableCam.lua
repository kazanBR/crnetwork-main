-- ── Config: on-foot FOV limits ───────────────────────────────────────────────
local cam         = Config.Camera
local maxFOV      = (cam and cam.MaxFOV)      or 70.0
local defaultFOV  = (cam and cam.DefaultFOV)  or 60.0
local minFOV      = (cam and cam.MinFOV)      or 10.0
local maxLookUp   = (cam and cam.MaxLookUp)   or 80.0
local maxLookDown = (cam and cam.MaxLookDown) or -80.0
local allowRunning = (cam and cam.AllowRunning) == true

-- ── Config: vehicle FOV / pan limits ────────────────────────────────────────
local vehicleZoom        = (cam and cam.Vehicle and cam.Vehicle.Zoom) == true
local vehicleMaxFOV      = (cam and cam.Vehicle and cam.Vehicle.MaxFOV)      or 80.0
local vehicleDefaultFOV  = (cam and cam.Vehicle and cam.Vehicle.DefaultFOV)  or 60.0
local vehicleMinFOV      = (cam and cam.Vehicle and cam.Vehicle.MinFOV)      or 10.0
local vehicleMaxLookUp   = (cam and cam.Vehicle and cam.Vehicle.MaxLookUp)   or 50.0
local vehicleMaxLookDown = (cam and cam.Vehicle and cam.Vehicle.MaxLookDown) or -30.0
local vehicleMaxLeftRight = (cam and cam.Vehicle and cam.Vehicle.MaxLeftRight) or  120.0
local vehicleMinLeftRight = (cam and cam.Vehicle and cam.Vehicle.MinLeftRight) or -120.0

-- ── Config: selfie FOV ───────────────────────────────────────────────────────
local selfieMaxFOV     = (cam and cam.Selfie and cam.Selfie.MaxFOV)     or 80.0
local selfieDefaultFOV = (cam and cam.Selfie and cam.Selfie.DefaultFOV) or 60.0
local selfieMinFOV     = (cam and cam.Selfie and cam.Selfie.MinFOV)     or 50.0

-- ── Config: freeze ───────────────────────────────────────────────────────────
local freezeEnabled  = (cam and cam.Freeze and cam.Freeze.Enabled) == true
local freezeMaxDist  = (cam and cam.Freeze and cam.Freeze.MaxDistance) or 10.0
local freezeMaxTime  = ((cam and cam.Freeze and cam.Freeze.MaxTime) or 60) * 1000

-- ── Config: selfie offset / rotation ────────────────────────────────────────
local selfieOffset   = (cam and cam.Selfie and cam.Selfie.Offset)   or vector3(0.1, 0.55, 0.6)
local selfieRotation = (cam and cam.Selfie and cam.Selfie.Rotation) or vector3(10.0, 0.0, -180.0)

-- ── Config: roll ─────────────────────────────────────────────────────────────
local rollEnabled = (cam and cam.Roll) == true

-- ── Runtime state ────────────────────────────────────────────────────────────
local rearCamOffset        = vector3(0.0, 0.5, 0.6) -- default rear-cam ped offset
local camPitch             = 0.0      -- current vertical look angle
local camRoll              = 0.0      -- current roll angle (degrees)
local currentFOV           = 60.0     -- current camera FOV (interpolated toward target)
local savedCamViewMode     = 0        -- follow-ped view mode saved on open, restored on close
local vehicleHeadingOffset = 0.0     -- horizontal pan offset when in vehicle
local radioDisabled        = false    -- true while we have muted the vehicle radio
local camFrozen            = false    -- true while the freeze-cam feature is active
local freezeExpireTime     = 0        -- game timer value at which the freeze expires
local localPed             = PlayerPedId()
local isSelfieCam          = false    -- true when the selfie (front-facing) cam is active
local isSprinting          = false    -- true when the player is pressing a sprint control
local mouseSensitivity     = 0.0      -- per-frame sensitivity scalar
local sensitivityBase      = GetProfileSetting(754) + 10  -- mouse sensitivity from profile
local lastZoomLevel        = 1.0      -- last integer zoom level sent to the UI
local scriptCam            = nil      -- handle to the active scripted camera (nil = inactive)

-- Camera mode flags (bit-field values)
local CAM_MODE = { REAR = 0, SELFIE = 1, IN_VEHICLE = 2 }
local currentCamMode = CAM_MODE.REAR

-- ── getFOVLimits() ───────────────────────────────────────────────────────────
-- Returns maxFOV, minFOV, defaultFOV for the current camera context
-- (selfie → selfie limits; in-vehicle with zoom → vehicle limits; else on-foot).
local function getFOVLimits()
    local inVehicle = IsPedInAnyVehicle(localPed, true)

    local fovMax
    if isSelfieCam and selfieMaxFOV then
        fovMax = selfieMaxFOV
    elseif inVehicle and vehicleMaxFOV then
        fovMax = vehicleMaxFOV
    else
        fovMax = maxFOV
    end

    local fovMin
    if isSelfieCam and selfieMinFOV then
        fovMin = selfieMinFOV
    elseif inVehicle and vehicleZoom and vehicleMinFOV then
        fovMin = vehicleMinFOV
    elseif inVehicle and vehicleMaxFOV then
        fovMin = vehicleMaxFOV  -- no zoom in vehicle: min == max
    else
        fovMin = minFOV
    end

    local fovDefault
    if isSelfieCam and selfieDefaultFOV then
        fovDefault = selfieDefaultFOV
    elseif inVehicle and vehicleDefaultFOV then
        fovDefault = vehicleDefaultFOV
    else
        fovDefault = defaultFOV
    end

    return fovMax, fovMin, fovDefault
end

-- ── ConvertFovToZoom(fov) ────────────────────────────────────────────────────
-- Maps an FOV value to a zoom multiplier (>=1 means zoomed out, <1 zoomed in).
function ConvertFovToZoom(fov)
    local fovMax, fovMin, fovDefault = getFOVLimits()
    local clamped = math.clamp(fov, fovMin, fovMax)

    if clamped == fovDefault then
        return 1.0
    elseif fovDefault > clamped then
        -- Zoomed in past default
        if clamped <= 0 then return 1.0 end
        return fovDefault / clamped
    else
        -- Zoomed out past default
        local t = (clamped - fovDefault) / (fovMax - fovDefault)
        return 1.0 - t * 0.5
    end
end

-- ── ConvertZoomToFov(zoom) ───────────────────────────────────────────────────
-- Inverse of ConvertFovToZoom: maps a zoom multiplier back to an FOV value.
local function ConvertZoomToFov(zoom)
    local fovMax, fovMin, fovDefault = getFOVLimits()

    -- Determine valid zoom range
    local zoomMin = 1.0
    if fovDefault < fovMax then zoomMin = 0.5 end

    local zoomMax = 1.0
    if fovMin < fovDefault and fovMin > 0 then
        zoomMax = fovDefault / fovMin
    end

    local clamped = math.clamp(zoom, zoomMin, zoomMax)

    if clamped == 1.0 then
        return fovDefault
    elseif clamped > 1.0 then
        return fovDefault / clamped
    else
        -- Interpolate between default and max FOV
        local t = 2.0 * (1.0 - clamped)
        return fovDefault + t * (fovMax - fovDefault)
    end
end

-- ── updateZoomLevels() ───────────────────────────────────────────────────────
-- Builds and sends the list of discrete zoom level stops to the UI.
local function updateZoomLevels()
    local fovMax, fovMin, _ = getFOVLimits()
    local zoomMax = ConvertFovToZoom(fovMax)
    local zoomMin = ConvertFovToZoom(fovMin)

    local levels = { 1.0 }

    -- Add a sub-1x level if the minimum zoom is less than 1
    if zoomMax < 1.0 then
        table.insert(levels, 1, zoomMax)
    end

    -- Add 2x and 5x/3x stops based on how far the max zoom reaches
    if zoomMin > 2.0 then
        table.insert(levels, 2, 2)
    end
    if zoomMin > 5.0 then
        table.insert(levels, 5)
    elseif zoomMin > 3.0 then
        table.insert(levels, 3)
    end

    SendReactMessage("camera:setZoomLevels", levels)
end

-- ── SetCameraZoom(zoom) ──────────────────────────────────────────────────────
-- Converts a zoom multiplier to FOV and stores it as the target FOV.
function SetCameraZoom(zoom)
    currentFOV = ConvertZoomToFov(zoom)
end

-- ── updateCameraMode() ───────────────────────────────────────────────────────
-- Detects camera mode changes (selfie / in-vehicle) and applies initial state.
local function updateCameraMode()
    local inVehicle = IsPedInAnyVehicle(localPed, true)

    -- Determine new mode flags
    local newMode = isSelfieCam and CAM_MODE.SELFIE or CAM_MODE.REAR
    if inVehicle then
        newMode = newMode | CAM_MODE.IN_VEHICLE
    end

    if currentCamMode ~= newMode then
        local fovMax, fovMin, fovDefault = getFOVLimits()
        currentCamMode = newMode
        currentFOV     = fovDefault

        debugprint("Camera mode changed to: " .. currentCamMode)
        updateZoomLevels()
        SetCamFov(scriptCam, currentFOV)
    end

    -- Determine if any sprint/strafe control is pressed (used for running check)
    local sprinting = IsDisabledControlPressed(0, 33)
                   or IsDisabledControlPressed(0, 34)
    if not sprinting then
        -- Control 35 only counts as sprinting when on foot
        sprinting = IsDisabledControlPressed(0, 35) and not inVehicle
    end
    isSprinting = sprinting

    -- Lock follow-ped cam and suppress default look/move controls
    SetFollowPedCamViewMode(0)
    SetGameplayCamRelativeHeading(0.0)

    local disabledControls = {1, 14, 15, 16, 17, 99, 100, 115, 116, 261, 262}
    for _, ctrl in ipairs(disabledControls) do
        DisableControlAction(0, ctrl, true)
    end

    SetPedResetFlag(localPed, 47, true)

    -- ── Freeze-cam check ─────────────────────────────────────────────────────
    if camFrozen and not inVehicle then
        local pedCoords = GetEntityCoords(localPed)
        local camCoords = GetCamCoord(scriptCam)
        local dist      = #(pedCoords - camCoords)

        -- Unfreeze if player walked too far away OR the timer expired
        if dist > freezeMaxDist or GetGameTimer() > freezeExpireTime then
            camFrozen = false
            TogglePhoneAnimation(true, "camera")
        end
        return
    end

    -- Disable running if not allowed
    if not allowRunning then
        DisableControlAction(0, 21, true)
    end

    -- ── Attach camera to ped / vehicle ───────────────────────────────────────
    if isSelfieCam and not inVehicle then
        -- Selfie: attach to head bone facing forward
        AttachCamToPedBone_2(
            scriptCam, localPed, 0,
            selfieRotation.x + camPitch, selfieRotation.y, selfieRotation.z,
            selfieOffset.x, selfieOffset.y, selfieOffset.z,
            true
        )

    elseif not isSelfieCam and not inVehicle then
        -- Rear on-foot: position behind the ped's head, respecting ground level
        local targetPos  = GetOffsetFromEntityInWorldCoords(localPed, rearCamOffset.x, rearCamOffset.y, rearCamOffset.z)
        local headPos    = GetPedBoneCoords(localPed, 31086, 0.0, 0.0, 0.0)

        -- Use head Z if it differs significantly from the offset Z (e.g. crouching)
        local camZ = targetPos.z
        if math.abs(headPos.z - targetPos.z) > 0.2 and headPos.z then
            camZ = headPos.z
        end

        DetachCam(scriptCam)
        SetCamCoord(scriptCam, targetPos.x, targetPos.y, camZ)
        SetCamRot(scriptCam, camPitch, 0.0, GetEntityHeading(localPed), 2)

    elseif isSelfieCam and inVehicle then
        -- Selfie in vehicle: attach behind head, rotated 180°
        AttachCamToPedBone_2(
            scriptCam, localPed, 0,
            80.0 + camPitch, 0.0, -180.0,
            0.0, 0.2, 0.5,
            true
        )

    elseif not isSelfieCam and inVehicle then
        -- Rear in vehicle: attach to steering-wheel bone, hide ped and phone prop
        local phoneObj = GetPhoneObject()
        if phoneObj then
            SetEntityLocallyInvisible(phoneObj)
        end
        SetEntityLocallyInvisible(localPed)

        local boneIndex = GetPedBoneIndex(localPed, 11816)
        AttachCamToPedBone_2(
            scriptCam, localPed, boneIndex,
            camPitch, 0.0, vehicleHeadingOffset,
            0.0, 0.0, 0.55,
            true
        )
    end

    -- ── Vehicle radio control ─────────────────────────────────────────────────
    if inVehicle then
        if not radioDisabled then
            radioDisabled = true
            SetUserRadioControlEnabled(false)
        end
    else
        if radioDisabled then
            radioDisabled = false
            SetUserRadioControlEnabled(true)
        end
        vehicleHeadingOffset = 0.0
    end

    -- Sprint control: allow look-around while sprinting; otherwise lock strafe
    if isSprinting then
        SetPedResetFlag(localPed, 69, true)
    elseif not isSelfieCam and not inVehicle then
        DisableControlAction(0, 30, true)
    end

    -- ── FOV smooth interpolation ──────────────────────────────────────────────
    local activeFOV = GetCamFov(scriptCam)

    -- Recalculate FOV limits for the current mode (mirrors getFOVLimits logic)
    local fovMax = (isSelfieCam and selfieMaxFOV)
               or (inVehicle    and vehicleMaxFOV)
               or maxFOV
    local fovMin = (isSelfieCam and selfieMinFOV)
               or (inVehicle and vehicleZoom and vehicleMinFOV)
               or (inVehicle and vehicleMaxFOV)
               or minFOV

    currentFOV = math.clamp(currentFOV, fovMin, fovMax)

    -- Send integer zoom level to UI when it changes
    local zoomLevel = math.round(ConvertFovToZoom(activeFOV), 1)
    if zoomLevel ~= lastZoomLevel then
        debugprint("Zoom changed to: " .. zoomLevel, ConvertFovToZoom(activeFOV), activeFOV)
        lastZoomLevel = zoomLevel
        SendReactMessage("camera:setZoom", zoomLevel)
    end

    -- Smoothly lerp the actual cam FOV toward the target (1/25 per frame)
    if math.abs(activeFOV - currentFOV) > 0.05 then
        SetCamFov(scriptCam, activeFOV + (currentFOV - activeFOV) / 25)
    end

    -- Stop updating if NUI has focus (e.g. UI modal open)
    if IsNuiFocused() then return end

    -- ── Mouse sensitivity scalar ──────────────────────────────────────────────
    mouseSensitivity = sensitivityBase * (currentFOV / maxFOV) / 5

    -- ── Horizontal look / vehicle steering ───────────────────────────────────
    local lookX = GetDisabledControlNormal(0, 1)  -- mouse X axis

    if inVehicle then
        -- Pan the camera heading inside the vehicle clamp range
        vehicleHeadingOffset = math.clamp(
            vehicleHeadingOffset - lookX * mouseSensitivity,
            vehicleMinLeftRight,
            vehicleMaxLeftRight
        )
    elseif lookX ~= 0.0 then
        -- On foot: rotate the ped entity to turn the camera
        SetEntityHeading(localPed, GetEntityHeading(localPed) - lookX * mouseSensitivity)
    end

    -- ── Zoom scroll (mouse wheel) ─────────────────────────────────────────────
    if IsDisabledControlPressed(0, 180) then
        currentFOV = currentFOV + 5   -- scroll up → zoom out
    elseif IsDisabledControlPressed(0, 181) then
        currentFOV = currentFOV - 5   -- scroll down → zoom in
    end

    -- ── Vertical look (mouse Y axis) ─────────────────────────────────────────
    local lookY = GetDisabledControlNormal(0, 2)  -- mouse Y axis
    if lookY ~= 0.0 then
        local deltaPitch = lookY * mouseSensitivity
        if inVehicle then
            camPitch = math.clamp(camPitch - deltaPitch, vehicleMaxLookDown, vehicleMaxLookUp)
        else
            camPitch = math.clamp(camPitch - deltaPitch, maxLookDown, maxLookUp)
        end
    end
end

-- ── applyHeadingFromMouse() ──────────────────────────────────────────────────
-- Rotates the local ped based on horizontal mouse input (used during cam freeze).
local function applyHeadingFromMouse()
    local lookX = GetDisabledControlNormal(0, 1)
    if lookX ~= 0.0 then
        SetEntityHeading(localPed, GetEntityHeading(localPed) - lookX * mouseSensitivity)
    end
end

-- ── EnableWalkableCam(selfie) ────────────────────────────────────────────────
-- Creates the scripted camera and starts the per-frame update threads.
function EnableWalkableCam(selfie)
    if scriptCam then return end  -- already active

    -- Set selfie mode and reset state
    isSelfieCam = (selfie == true)
    isSprinting = false
    camPitch    = 0.0
    camRoll     = 0.0
    vehicleHeadingOffset = 0.0
    camFrozen   = false

    -- Snap to selfie or default FOV
    currentFOV = (isSelfieCam and selfieDefaultFOV and selfieDefaultFOV) or defaultFOV

    localPed          = PlayerPedId()
    savedCamViewMode  = GetFollowPedCamViewMode()
    sensitivityBase   = GetProfileSetting(754) + 10
    lastZoomLevel     = 1.0

    -- Create the scripted camera
    scriptCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    SetPhoneAction("camera")

    -- Thread 1: handle freeze-cam heading while NUI is not focused
    CreateThread(function()
        while scriptCam do
            Wait(0)
            if isSprinting or camFrozen then
                if not IsNuiFocused() then
                    applyHeadingFromMouse()
                end
            end
        end
    end)

    -- Thread 2: main per-frame camera update; cleans up when cam is destroyed
    CreateThread(function()
        while scriptCam do
            Wait(0)
            updateCameraMode()
        end

        -- Restore radio if it was muted
        if radioDisabled then
            radioDisabled = false
            SetUserRadioControlEnabled(true)
        end
    end)

    SetCamFov(scriptCam, currentFOV)
    RenderScriptCams(true, false, 0, true, true)
    SetCamActive(scriptCam, true)
    SendReactMessage("camera:setZoom", 1.0)
    updateZoomLevels()
    RefreshAnimationsInterval()
end

-- ── DisableWalkableCam() ─────────────────────────────────────────────────────
-- Tears down the scripted camera and restores normal gameplay state.
function DisableWalkableCam()
    if not scriptCam then return end

    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(scriptCam, false)
    SetFollowPedCamViewMode(savedCamViewMode)

    -- Restore phone action (call or default)
    local action = IsInCall() and "call" or "default"
    SetPhoneAction(action)

    scriptCam = nil

    if camFrozen then
        TogglePhoneAnimation(true, "camera")
    end

    RefreshAnimationsInterval()
end

-- ── ToggleSelfieCam(enable) ──────────────────────────────────────────────────
-- Switches between rear and selfie camera modes; resets angles on change.
function ToggleSelfieCam(enable)
    local wasSelfieCam = isSelfieCam
    isSelfieCam = (enable == true)

    if wasSelfieCam ~= isSelfieCam then
        camRoll  = 0.0
        camPitch = 0.0
    end
end

-- ── ToggleCameraFrozen() ─────────────────────────────────────────────────────
-- Toggles the freeze-cam feature (only valid when in selfie mode with freeze enabled).
function ToggleCameraFrozen()
    -- Only freeze when: freeze is configured, cam is active, and selfie mode is on
    if not (freezeEnabled and scriptCam and not isSelfieCam) then
        return
    end

    local nowFrozen = not camFrozen
    if nowFrozen then
        -- Start freeze: hide the phone animation and set expiry timer
        TogglePhoneAnimation(false, "camera")
        freezeExpireTime = GetGameTimer() + freezeMaxTime
    end
    camFrozen = nowFrozen
end

-- ── IsWalkingCamEnabled() ────────────────────────────────────────────────────
function IsWalkingCamEnabled()
    return scriptCam ~= nil
end

-- ── IsSelfieCam() ────────────────────────────────────────────────────────────
function IsSelfieCam()
    return isSelfieCam
end

-- ── Key-press event handler ───────────────────────────────────────────────────
AddEventHandler("lb-phone:keyPressed", function(key)
    if not scriptCam then return end

    if key == "FreezeCamera" then
        -- Only allow freeze when configured and in selfie (non-selfie) mode on foot
        if freezeEnabled and not isSelfieCam then
            ToggleCameraFrozen()
        end

    elseif key == "RollLeft" or key == "RollRight" then
        if not rollEnabled then return end

        local delta = (key == "RollLeft") and -0.5 or 0.5
        local bindData = Config.KeyBinds[key].bindData

        -- Continuously apply roll while the key is held
        while bindData.pressed do
            Wait(0)
            camRoll = camRoll + delta
        end
    end
end)

-- ── Exports ───────────────────────────────────────────────────────────────────
exports("EnableWalkableCam",   EnableWalkableCam)
exports("DisableWalkableCam",  DisableWalkableCam)
exports("ToggleSelfieCam",     ToggleSelfieCam)
exports("ToggleCameraFrozen",  ToggleCameraFrozen)
exports("IsWalkingCamEnabled", IsWalkingCamEnabled)
exports("IsSelfieCam",         IsSelfieCam)
