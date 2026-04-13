flashlightEnabled = false

-- ─── setFlashlightEnabled ──────────────────────────────────────────────────────
-- Turns the flashlight on or off. Notifies the server on state change and
-- spawns a draw thread when enabling.
local function setFlashlightEnabled(enabled)
    local previous  = flashlightEnabled
    flashlightEnabled = enabled == true

    -- No change — nothing to do
    if flashlightEnabled == previous then return end

    TriggerServerEvent("phone:toggleFlashlight", flashlightEnabled)

    if not flashlightEnabled then return end

    -- Draw the flashlight every frame while it is active and the phone is open
    Citizen.CreateThreadNow(function()
        local ped = PlayerPedId()
        while flashlightEnabled do
            if phoneOpen then
                DrawFlashlight(ped)
            else
                Wait(500)
            end
            Wait(0)
        end
    end)
end

-- ─── toggleFlashlight NUI callback ────────────────────────────────────────────
-- Called by the React UI when the user taps the flashlight toggle.
-- Acknowledges the NUI callback after a short delay so the UI receives the
-- confirmed state rather than the requested state.
RegisterNUICallback("toggleFlashlight", function(data, cb)
    setFlashlightEnabled(data.toggled)
    SetTimeout(100, function()
        cb(flashlightEnabled)
    end)
end)

-- ─── ToggleFlashlight export ───────────────────────────────────────────────────
-- Allows other resources to toggle the flashlight programmatically.
-- Only works while the phone is open.
exports("ToggleFlashlight", function(enabled)
    if not phoneOpen then return end
    setFlashlightEnabled(enabled)
    SendReactMessage("toggleFlashlight", flashlightEnabled)
end)

-- ─── GetFlashlight export ──────────────────────────────────────────────────────
-- Returns whether the flashlight is currently enabled.
exports("GetFlashlight", function()
    return flashlightEnabled == true
end)

-- ─── SyncFlash (optional) ──────────────────────────────────────────────────────
-- If Config.SyncFlash is enabled, draw flashlights for other players too.
-- Uses an Interval that runs only while at least one remote flashlight is active.
if not Config.SyncFlash then return end

-- Map of playerServerId → ped, for players currently using their flashlight
local flashlightPeds = {}

-- Interval that calls DrawFlashlight for every tracked remote ped each frame
local flashlightInterval = Interval.new(Interval, function()
    for _, ped in pairs(flashlightPeds) do
        DrawFlashlight(ped)
    end
end, 0, false)

flashlightInterval.onStart = function()
    debugprint("Started drawing flashlights")
end

flashlightInterval.onStop = function()
    debugprint("Stopped drawing flashlights")
end

-- Watch the "flashlight" state bag on all players and update the ped map
AddStateBagChangeHandler("flashlight", nil, function(bagName, _, value)
    local serverId, ped = GetPlayerDataFromStateBag(bagName)

    -- Only track other players, not ourselves
    if not serverId then return end
    if serverId == GetPlayerServerId(PlayerId()) then return end

    flashlightPeds[serverId] = value and ped or nil

    -- Start the interval when at least one remote flashlight is active; stop when none are
    flashlightInterval:toggle(next(flashlightPeds) ~= nil)
end)

-- Clean up when a player leaves
RegisterNetEvent("onPlayerDropped")
AddEventHandler("onPlayerDropped", function(droppedServerId)
    flashlightPeds[droppedServerId] = nil
    flashlightInterval:toggle(next(flashlightPeds) ~= nil)
end)