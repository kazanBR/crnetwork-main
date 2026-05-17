local function passport(source)
    return vRP.Passport(source)
end

local function trim(value, maxLength)
    value = tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')

    if maxLength and #value > maxLength then
        value = value:sub(1, maxLength)
    end

    return value
end

local function validUrl(value)
    return type(value) == 'string' and value:match('^https?://') ~= nil
end

local function now()
    return os.time()
end

local function urlEncode(value)
    value = tostring(value or '')
    value = value:gsub('\n', '\r\n')
    value = value:gsub('([^%w%-%_%.%~])', function(char)
        return string.format('%%%02X', string.byte(char))
    end)

    return value
end

local function ensureColumns()
    local columns = exports.oxmysql:query_async([[
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'spotfly_tracks'
    ]], {}) or {}

    local existing = {}
    for _, column in ipairs(columns) do
        existing[column.COLUMN_NAME] = true
    end

    if not existing.source then
        exports.oxmysql:update_async("ALTER TABLE `spotfly_tracks` ADD COLUMN `source` VARCHAR(40) NOT NULL DEFAULT 'audio'", {})
    end

    if not existing.video_id then
        exports.oxmysql:update_async("ALTER TABLE `spotfly_tracks` ADD COLUMN `video_id` VARCHAR(80) DEFAULT ''", {})
    end
end

local function setupDatabase()
    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `spotfly_tracks` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `passport` INT NULL,
            `title` VARCHAR(120) NOT NULL,
            `artist` VARCHAR(120) NOT NULL,
            `album` VARCHAR(120) DEFAULT '',
            `cover` VARCHAR(500) DEFAULT '',
            `url` VARCHAR(700) NOT NULL,
            `source` VARCHAR(40) NOT NULL DEFAULT 'audio',
            `video_id` VARCHAR(80) DEFAULT '',
            `duration` INT DEFAULT 0,
            `genre` VARCHAR(80) DEFAULT '',
            `created_at` INT NOT NULL,
            INDEX `idx_spotfly_tracks_passport` (`passport`)
        )
    ]], {})

    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `spotfly_likes` (
            `passport` INT NOT NULL,
            `track_id` INT NOT NULL,
            `created_at` INT NOT NULL,
            PRIMARY KEY (`passport`, `track_id`)
        )
    ]], {})

    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `spotfly_playlists` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `passport` INT NOT NULL,
            `name` VARCHAR(80) NOT NULL,
            `cover` VARCHAR(500) DEFAULT '',
            `created_at` INT NOT NULL,
            INDEX `idx_spotfly_playlists_passport` (`passport`)
        )
    ]], {})

    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `spotfly_playlist_tracks` (
            `playlist_id` INT NOT NULL,
            `track_id` INT NOT NULL,
            `created_at` INT NOT NULL,
            PRIMARY KEY (`playlist_id`, `track_id`)
        )
    ]], {})

    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `spotfly_recent` (
            `passport` INT NOT NULL,
            `track_id` INT NOT NULL,
            `played_at` INT NOT NULL,
            PRIMARY KEY (`passport`, `track_id`)
        )
    ]], {})

    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `spotfly_state` (
            `passport` INT PRIMARY KEY,
            `track_id` INT DEFAULT NULL,
            `volume` INT DEFAULT 80,
            `shuffle` TINYINT DEFAULT 0,
            `repeat_mode` VARCHAR(12) DEFAULT 'off',
            `updated_at` INT NOT NULL
        )
    ]], {})

    ensureColumns()

    local count = exports.oxmysql:scalar_async('SELECT COUNT(*) FROM `spotfly_tracks` WHERE `passport` IS NULL', {}) or 0

    if count == 0 then
        for _, track in ipairs(Config.DefaultTracks or {}) do
            if validUrl(track.url) then
                exports.oxmysql:insert_async([[
                    INSERT INTO `spotfly_tracks` (passport, title, artist, album, cover, url, source, video_id, duration, genre, created_at)
                    VALUES (NULL, ?, ?, ?, ?, ?, 'audio', '', ?, ?, ?)
                ]], {
                    trim(track.title, 120),
                    trim(track.artist, 120),
                    trim(track.album, 120),
                    trim(track.cover, 500),
                    trim(track.url, 700),
                    tonumber(track.duration) or 0,
                    trim(track.genre, 80),
                    now()
                })
            end
        end
    end
end

CreateThread(setupDatabase)

local function getOwnedPlaylist(source, playlistId)
    local playerPassport = passport(source)
    playlistId = tonumber(playlistId)

    if not playerPassport or not playlistId then
        return
    end

    local result = exports.oxmysql:query_async(
        'SELECT * FROM `spotfly_playlists` WHERE `id` = ? AND `passport` = ? LIMIT 1',
        { playlistId, playerPassport }
    )

    return result and result[1]
end

srv.getData = function()
    local source = source
    local playerPassport = passport(source)

    if not playerPassport then
        return { tracks = {}, likes = {}, playlists = {}, recent = {}, state = {} }
    end

    local tracks = exports.oxmysql:query_async([[
        SELECT * FROM `spotfly_tracks`
        WHERE `passport` IS NULL OR `passport` = ?
        ORDER BY `passport` IS NOT NULL DESC, `id` DESC
    ]], { playerPassport }) or {}

    local likes = exports.oxmysql:query_async(
        'SELECT `track_id` FROM `spotfly_likes` WHERE `passport` = ?',
        { playerPassport }
    ) or {}

    local playlists = exports.oxmysql:query_async(
        'SELECT * FROM `spotfly_playlists` WHERE `passport` = ? ORDER BY `id` DESC',
        { playerPassport }
    ) or {}

    local playlistTracks = exports.oxmysql:query_async([[
        SELECT pt.playlist_id, pt.track_id
        FROM `spotfly_playlist_tracks` pt
        INNER JOIN `spotfly_playlists` p ON p.id = pt.playlist_id
        WHERE p.passport = ?
    ]], { playerPassport }) or {}

    local recent = exports.oxmysql:query_async([[
        SELECT `track_id` FROM `spotfly_recent`
        WHERE `passport` = ?
        ORDER BY `played_at` DESC
        LIMIT 20
    ]], { playerPassport }) or {}

    local state = exports.oxmysql:query_async(
        'SELECT * FROM `spotfly_state` WHERE `passport` = ? LIMIT 1',
        { playerPassport }
    ) or {}

    return {
        tracks = tracks,
        likes = likes,
        playlists = playlists,
        playlistTracks = playlistTracks,
        recent = recent,
        state = state[1] or { volume = 80, shuffle = 0, repeat_mode = 'off' }
    }
end

srv.searchYouTube = function(data)
    if not Config.YouTube or Config.YouTube.enabled == false then
        return { ok = false, error = 'youtube_disabled', results = {} }
    end

    local apiKey = trim(Config.YouTube.apiKey, 200)
    if apiKey == '' then
        return { ok = false, error = 'missing_api_key', results = {} }
    end

    local term = type(data) == 'table' and trim(data.term, 120) or ''
    if #term < 2 then
        return { ok = true, results = {} }
    end

    local maxResults = tonumber(Config.YouTube.maxResults) or 20
    maxResults = math.max(1, math.min(25, maxResults))

    local regionCode = trim(Config.YouTube.regionCode or 'BR', 4)
    local url = ('https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&videoCategoryId=10&maxResults=%s&regionCode=%s&q=%s&key=%s'):format(
        maxResults,
        urlEncode(regionCode),
        urlEncode(term),
        urlEncode(apiKey)
    )

    local request = promise.new()

    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or not body then
            request:resolve({ ok = false, error = 'request_failed', status = status, results = {} })
            return
        end

        local decoded = json.decode(body)
        if not decoded or not decoded.items then
            request:resolve({ ok = false, error = 'invalid_response', results = {} })
            return
        end

        local results = {}

        for _, item in ipairs(decoded.items) do
            local videoId = item.id and item.id.videoId
            local snippet = item.snippet or {}
            local thumbnails = snippet.thumbnails or {}
            local cover = (thumbnails.high and thumbnails.high.url)
                or (thumbnails.medium and thumbnails.medium.url)
                or (thumbnails.default and thumbnails.default.url)
                or ''

            if videoId then
                results[#results + 1] = {
                    id = 'youtube-' .. videoId,
                    external = true,
                    youtube = true,
                    source = 'youtube',
                    videoId = videoId,
                    title = snippet.title or 'Video do YouTube',
                    artist = snippet.channelTitle or 'YouTube',
                    album = 'YouTube',
                    genre = 'YouTube',
                    cover = cover,
                    url = 'https://www.youtube.com/watch?v=' .. videoId,
                    duration = 0
                }
            end
        end

        request:resolve({ ok = true, results = results })
    end, 'GET')

    return Citizen.Await(request)
end

srv.saveState = function(data)
    local playerPassport = passport(source)

    if not playerPassport or type(data) ~= 'table' then
        return false
    end

    local trackId = tonumber(data.trackId)
    local volume = math.max(0, math.min(100, tonumber(data.volume) or 80))
    local shuffle = data.shuffle and 1 or 0
    local repeatMode = trim(data.repeatMode or 'off', 12)

    if repeatMode ~= 'off' and repeatMode ~= 'all' and repeatMode ~= 'one' then
        repeatMode = 'off'
    end

    exports.oxmysql:update_async([[
        INSERT INTO `spotfly_state` (passport, track_id, volume, shuffle, repeat_mode, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE track_id = VALUES(track_id), volume = VALUES(volume), shuffle = VALUES(shuffle), repeat_mode = VALUES(repeat_mode), updated_at = VALUES(updated_at)
    ]], { playerPassport, trackId, volume, shuffle, repeatMode, now() })

    return true
end

srv.toggleLike = function(data)
    local playerPassport = passport(source)
    local trackId = type(data) == 'table' and tonumber(data.trackId)

    if not playerPassport or not trackId then
        return false
    end

    local liked = exports.oxmysql:scalar_async(
        'SELECT 1 FROM `spotfly_likes` WHERE `passport` = ? AND `track_id` = ? LIMIT 1',
        { playerPassport, trackId }
    )

    if liked then
        exports.oxmysql:update_async('DELETE FROM `spotfly_likes` WHERE `passport` = ? AND `track_id` = ?', { playerPassport, trackId })
        return { liked = false }
    end

    exports.oxmysql:insert_async('INSERT IGNORE INTO `spotfly_likes` (passport, track_id, created_at) VALUES (?, ?, ?)', { playerPassport, trackId, now() })
    return { liked = true }
end

srv.createPlaylist = function(data)
    local playerPassport = passport(source)

    if not playerPassport or type(data) ~= 'table' then
        return false
    end

    local name = trim(data.name, 80)
    local cover = trim(data.cover, 500)

    if name == '' then
        return false
    end

    local id = exports.oxmysql:insert_async(
        'INSERT INTO `spotfly_playlists` (passport, name, cover, created_at) VALUES (?, ?, ?, ?)',
        { playerPassport, name, cover, now() }
    )

    return { id = id, name = name, cover = cover }
end

srv.deletePlaylist = function(data)
    local playlist = getOwnedPlaylist(source, type(data) == 'table' and data.playlistId)

    if not playlist then
        return false
    end

    exports.oxmysql:update_async('DELETE FROM `spotfly_playlist_tracks` WHERE `playlist_id` = ?', { playlist.id })
    exports.oxmysql:update_async('DELETE FROM `spotfly_playlists` WHERE `id` = ?', { playlist.id })
    return true
end

srv.addToPlaylist = function(data)
    local playlist = getOwnedPlaylist(source, type(data) == 'table' and data.playlistId)
    local trackId = type(data) == 'table' and tonumber(data.trackId)

    if not playlist or not trackId then
        return false
    end

    exports.oxmysql:insert_async(
        'INSERT IGNORE INTO `spotfly_playlist_tracks` (playlist_id, track_id, created_at) VALUES (?, ?, ?)',
        { playlist.id, trackId, now() }
    )

    return true
end

srv.removeFromPlaylist = function(data)
    local playlist = getOwnedPlaylist(source, type(data) == 'table' and data.playlistId)
    local trackId = type(data) == 'table' and tonumber(data.trackId)

    if not playlist or not trackId then
        return false
    end

    exports.oxmysql:update_async(
        'DELETE FROM `spotfly_playlist_tracks` WHERE `playlist_id` = ? AND `track_id` = ?',
        { playlist.id, trackId }
    )

    return true
end

srv.addTrack = function(data)
    local playerPassport = passport(source)

    if not playerPassport or type(data) ~= 'table' then
        return false
    end

    local title = trim(data.title, 120)
    local artist = trim(data.artist, 120)
    local album = trim(data.album, 120)
    local cover = trim(data.cover, 500)
    local url = trim(data.url, 700)
    local genre = trim(data.genre, 80)
    local duration = tonumber(data.duration) or 0
    local sourceType = trim(data.source or 'audio', 40)
    local videoId = trim(data.videoId or data.video_id, 80)

    if sourceType ~= 'youtube' then
        sourceType = 'audio'
        videoId = ''
    end

    if title == '' or artist == '' or not validUrl(url) then
        return false
    end

    local id = exports.oxmysql:insert_async([[
        INSERT INTO `spotfly_tracks` (passport, title, artist, album, cover, url, source, video_id, duration, genre, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { playerPassport, title, artist, album, cover, url, sourceType, videoId, duration, genre, now() })

    return {
        id = id,
        passport = playerPassport,
        title = title,
        artist = artist,
        album = album,
        cover = cover,
        url = url,
        source = sourceType,
        video_id = videoId,
        videoId = videoId,
        duration = duration,
        genre = genre,
        created_at = now()
    }
end

srv.addRecent = function(data)
    local playerPassport = passport(source)
    local trackId = type(data) == 'table' and tonumber(data.trackId)

    if not playerPassport or not trackId then
        return false
    end

    exports.oxmysql:update_async([[
        INSERT INTO `spotfly_recent` (passport, track_id, played_at)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE played_at = VALUES(played_at)
    ]], { playerPassport, trackId, now() })

    return true
end

local vehicleOutputs = {}

srv.claimVehicleOutput = function(vehicleNet)
    local source = source
    vehicleNet = tonumber(vehicleNet)

    if not vehicleNet then
        return false
    end

    local previous = vehicleOutputs[vehicleNet]

    if previous and previous ~= source then
        TriggerClientEvent('spotfy:vehicleOutputTaken', previous, vehicleNet)
    end

    vehicleOutputs[vehicleNet] = source
    return true
end

srv.releaseVehicleOutput = function(vehicleNet)
    local source = source
    vehicleNet = tonumber(vehicleNet)

    if vehicleNet and vehicleOutputs[vehicleNet] == source then
        vehicleOutputs[vehicleNet] = nil
    end

    return true
end

AddEventHandler('playerDropped', function()
    local source = source

    for vehicleNet, owner in pairs(vehicleOutputs) do
        if owner == source then
            vehicleOutputs[vehicleNet] = nil
        end
    end
end)
