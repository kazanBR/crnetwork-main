local resourceName = GetCurrentResourceName()

-- Read and validate resource version from manifest
local resourceVersion = GetResourceMetadata(resourceName, "version", 0) or "0.0.0"
if not resourceVersion:match("^%d+%.%d+%.%d+$") then
    resourceVersion = "0.0.0"
end

-- True when the resource is running with a custom UI (not the standard dist build)
local isCustomUi = GetResourceMetadata(resourceName, "ui_page", 0) ~= "ui/dist/index.html"

-- Video file extensions used to classify media attachments
local VIDEO_EXTENSIONS = { "webm", "mp4", "mov" }

-- Maximum events buffered before a flush is forced
local MAX_BUFFER_SIZE = 25

-- State
local eventBuffer  = {}   -- queued events waiting to be sent
local eventCount   = 0    -- number of events currently in the buffer
local cachedServerId = nil -- resolved CFX server ID, cached after first lookup

-- ─── flushEvents ───────────────────────────────────────────────────────────────
-- Sends all buffered events to the tracking endpoint, then resets the buffer.
-- Pass force=true to flush even when the buffer hasn't reached MAX_BUFFER_SIZE.
local function flushEvents(force)
    local shouldFlush = force or (eventCount >= MAX_BUFFER_SIZE)
    if not shouldFlush or eventCount == 0 then return end

    -- Resolve the CFX server ID from the web_baseUrl convar (cached after first call)
    if not cachedServerId then
        local baseUrl = GetConvar("web_baseUrl", "")
        if baseUrl == "" then return end

        -- Extract the subdomain part before ".users.cfx.re"
        local reversed   = baseUrl:reverse()
        local dashPos    = reversed:find("-") or (#baseUrl + 1)
        local startPos   = (#baseUrl - dashPos) + 2
        local endPos     = #baseUrl - #".users.cfx.re"
        cachedServerId   = baseUrl:sub(startPos, endPos)
    end

    local payload = json.encode({
        serverId = cachedServerId,
        version  = resourceVersion,
        events   = eventBuffer,
    })

    -- Reset buffer before the async HTTP call
    eventCount  = 0
    eventBuffer = {}

    PerformHttpRequest(
        "https://track.lbscripts.com/",
        function() end, -- response callback (unused)
        "POST",
        payload,
        { ["Content-Type"] = "application/json" }
    )
end

-- ─── TrackSimpleEvent ──────────────────────────────────────────────────────────
-- Records a named event with no additional metadata.
function TrackSimpleEvent(eventName)
    if isCustomUi then return end

    eventCount = eventCount + 1
    eventBuffer[eventCount] = { event = eventName }
    flushEvents()
end

-- ─── TrackSocialMediaPost ──────────────────────────────────────────────────────
-- Records a social media post event, classifying each attachment as a video or photo.
function TrackSocialMediaPost(appName, attachments)
    if isCustomUi then return end

    local videoCount = 0
    local photoCount = 0

    if attachments then
        for _, attachment in ipairs(attachments) do
            local ext = attachment:match("%.([^.]+)$") or "webp"
            if table.contains(VIDEO_EXTENSIONS, ext) then
                videoCount = videoCount + 1
            else
                photoCount = photoCount + 1
            end
        end
    end

    eventCount = eventCount + 1
    eventBuffer[eventCount] = {
        event        = "social_media_post",
        app          = appName,
        amountVideos = videoCount,
        amountPhotos = photoCount,
    }
    flushEvents()
end

-- ─── Event hooks ───────────────────────────────────────────────────────────────

-- Flush on the 1-minute warning before a scheduled txAdmin restart
AddEventHandler("txAdmin:events:scheduledRestart", function(data)
    if data.secondsRemaining == 60 then
        flushEvents(true)
    end
end)

-- Flush immediately when the server is shutting down
AddEventHandler("txAdmin:events:serverShuttingDown", function()
    flushEvents(true)
end)

-- Flush when this resource is stopped
AddEventHandler("onResourceStop", function(stoppedResource)
    if stoppedResource == GetCurrentResourceName() then
        flushEvents(true)
    end
end)