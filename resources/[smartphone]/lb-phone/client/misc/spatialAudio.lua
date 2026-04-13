-- ── Helper: rotate a vector by Euler angles (pitch=x, roll=y, yaw=z, in degrees) ──
local function rotateVectorByEuler(vec, rotation)
    -- Convert each Euler angle from degrees to radians
    local pitch = math.rad(rotation.x)
    local roll  = math.rad(rotation.y)
    local yaw   = math.rad(rotation.z)

    -- Precompute sin/cos for each axis
    local cosPitch = math.cos(pitch)
    local sinPitch = math.sin(pitch)
    local cosRoll  = math.cos(roll)
    local sinRoll  = math.sin(roll)
    local cosYaw   = math.cos(yaw)
    local sinYaw   = math.sin(yaw)

    -- Apply yaw (Z) rotation to X/Y
    local rotX = vec.x * cosYaw - vec.y * sinYaw
    local rotY = vec.x * sinYaw + vec.y * cosYaw

    -- Apply roll (Y) rotation to the result using Z component
    local rotZ    = vec.z
    local afterX  = rotX
    local afterY  = rotY * cosPitch - rotZ * sinPitch
    local afterZ  = rotY * sinPitch + rotZ * cosPitch

    -- Apply pitch (X) rotation
    local finalX =  afterX  * cosRoll + afterZ * sinRoll
    local finalY =  afterY
    local finalZ = -afterX  * sinRoll + afterZ * cosRoll

    return vector3(finalX, finalY, finalZ)
end

-- ── CalculateSpatialAudio ────────────────────────────────────────────────────
-- Returns a table of {frontLeft, frontRight, rearLeft, rearRight} volume weights
-- based on the relative position of a sound source to the listener.
--
-- Parameters:
--   listenerPos  (vector3) – world position of the listener
--   listenerRot  (vector3) – Euler rotation of the listener (degrees)
--   sourcePos    (vector3) – world position of the sound source
--   maxDist      (number)  – distance beyond which volume is zero
--   volume       (number)  – master volume scale [0.0–1.0], defaults to 1.0
function CalculateSpatialAudio(listenerPos, listenerRot, sourcePos, maxDist, volume)
    -- Clamp volume to [0, 1], defaulting to 1.0 if not provided
    volume = math.clamp(volume or 1.0, 0.0, 1.0)

    -- Vector from listener to source, and its scalar distance
    local toSource = sourcePos - listenerPos
    local dist     = #toSource

    -- Source is beyond max distance — all speakers silent
    if maxDist <= dist then
        return { frontLeft = 0.0, frontRight = 0.0, rearLeft = 0.0, rearRight = 0.0 }
    end

    -- Rotate the to-source vector into listener-local space using the inverse
    -- rotation (negate the rotation angles to get listener-relative direction)
    local negRot       = vector3(-listenerRot.x, -listenerRot.y, -listenerRot.z)
    local localDir     = rotateVectorByEuler(toSource, negRot)

    -- Project onto the horizontal plane and normalise to get a 2D pan direction
    local panDir = norm(vector2(localDir.x, localDir.y))

    -- Map the normalised direction to [0, 1] pan coordinates:
    --   panX: 0 = full left,  1 = full right
    --   panY: 0 = full rear,  1 = full front
    local panX = (panDir.x + 1.0) * 0.5
    local panY = (panDir.y + 1.0) * 0.5

    local right = panX
    local left  = 1.0 - panX
    local front = panY
    local rear  = 1.0 - panY

    -- Compute raw per-speaker weights (bilinear blend of pan axes)
    local speakers = {
        frontLeft  = front * left,
        frontRight = front * right,
        rearLeft   = rear  * left,
        rearRight  = rear  * right,
    }

    -- Normalise speaker weights so the loudest combination sums to 1
    local sumSq = speakers.frontLeft  ^ 2
               + speakers.frontRight ^ 2
               + speakers.rearLeft   ^ 2
               + speakers.rearRight  ^ 2

    if sumSq > 0 then
        local invLen = 1.0 / math.sqrt(sumSq)
        speakers.frontLeft  = speakers.frontLeft  * invLen
        speakers.frontRight = speakers.frontRight * invLen
        speakers.rearLeft   = speakers.rearLeft   * invLen
        speakers.rearRight  = speakers.rearRight  * invLen
    end

    -- Distance falloff: quadratic fade from 1 at the listener to 0 at maxDist,
    -- then scaled by the master volume
    local distFactor = math.clamp((1.0 - dist / maxDist) ^ 2, 0.0, 1.0) * volume

    return {
        frontLeft  = speakers.frontLeft  * distFactor,
        frontRight = speakers.frontRight * distFactor,
        rearLeft   = speakers.rearLeft   * distFactor,
        rearRight  = speakers.rearRight  * distFactor,
    }
end
