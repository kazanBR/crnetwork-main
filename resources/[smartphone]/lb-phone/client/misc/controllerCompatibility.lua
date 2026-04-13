-- Current virtual cursor position (normalised 0–1)
local cursorX  = 0.5
local cursorY  = 0.5

-- How much each frame of stick input moves the cursor
local CURSOR_SPEED = 0.005

-- Whether the NUI keyboard is currently active (set by toggleInput)
local keyboardActive = false

-- ─── isUsingController ─────────────────────────────────────────────────────────
-- Returns true when the player is using a gamepad rather than keyboard/mouse.
local function isUsingController()
    return not IsUsingKeyboard(0)
end

-- ─── getStickAxis ──────────────────────────────────────────────────────────────
-- Returns the normalised value of a disabled control axis, dead-zoned to 0
-- for values within ±0.1 of centre.
local function getStickAxis(controlId)
    local value = GetDisabledControlNormal(0, controlId)
    if value < -0.1 or value > 0.1 then
        return value
    end
    return 0.0
end

-- ─── Controller keyboard toggle ───────────────────────────────────────────────
-- Called internally when the UI signals a text-input focus change.
-- Manages the on-screen keyboard visibility for controller users.
-- The NUI "toggleInput" callback is registered in client.lua and calls this
-- function after handling SetNuiFocusKeepInput, so we do NOT register a second
-- NUI callback here (which would silently overwrite the one in client.lua and
-- break the cb() response, hanging the UI on every focus change).
function ControllerToggleKeyboard(enabled)
    if not isUsingController() then return end

    keyboardActive = enabled == true

    if not enabled then
        Wait(250)
        -- Abort if keyboard was re-enabled during the delay
        if keyboardActive then return end
    end

    SendReactMessage("controller:toggleKeyboard", keyboardActive)
end

-- ─── processControllerFrame ────────────────────────────────────────────────────
-- Runs every frame while the phone is open and NUI is focused.
-- Moves the virtual cursor, fires press/release/scroll/back events,
-- and suppresses all normal control actions.
local function processControllerFrame()
    local axisX   = getStickAxis(1)   -- left stick horizontal
    local axisY   = getStickAxis(2)   -- left stick vertical
    local scroll  = getStickAxis(31)  -- right stick vertical (scroll)

    -- Move cursor and clamp to screen bounds
    cursorX = math.min(0.99999, math.max(0, cursorX + axisX * CURSOR_SPEED))
    cursorY = math.min(1.0,     math.max(0, cursorY + axisY * CURSOR_SPEED))

    -- Primary button (control 18) press / release
    if IsDisabledControlJustPressed(0, 18) then
        SendReactMessage("controller:press",   { x = cursorX, y = cursorY })
    elseif IsDisabledControlJustReleased(0, 18) then
        SendReactMessage("controller:release", { x = cursorX, y = cursorY })
    elseif IsDisabledControlJustReleased(0, 199) or IsDisabledControlJustReleased(0, 177) then
        -- Back / cancel buttons (B / Backspace)
        ToggleOpen(false)
    end

    -- Move the OS cursor to the virtual position if the stick is being used
    if axisX ~= 0.0 or axisY ~= 0.0 then
        SetCursorLocation(cursorX, cursorY)
    end

    -- Scroll if the right stick has input
    if scroll ~= 0.0 then
        SendReactMessage("controller:scroll", {
            amount = math.floor(scroll * 25),
            x      = cursorX,
            y      = cursorY,
        })
    end

    -- Suppress all game controls while the phone UI is open
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    InvalidateIdleCam()
end

-- ─── ControllerThread ──────────────────────────────────────────────────────────
-- Runs while the phone is open. Polls every frame when using a controller and
-- NUI is focused; otherwise polls at a reduced rate (500ms) to save resources.
-- Resets the cursor to centre when the phone closes.
function ControllerThread()
    while phoneOpen do
        Wait(0)

        if isUsingController() then
            if IsNuiFocused() then
                processControllerFrame()
            end
        else
            Wait(500)
        end
    end

    -- Reset cursor to centre for next time the phone opens
    cursorX = 0.5
    cursorY = 0.5

    if isUsingController() then
        SetCursorLocation(cursorX, cursorY)
    end
end