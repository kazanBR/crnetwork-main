-- playlists and groups their songs into a Songs array.
local function FetchPlaylists()
    local rows     = AwaitCallback("music:getPlaylists")
    local playlists = {}
    local seen     = {}  -- tracks playlist IDs already added

    for _, row in ipairs(rows) do
        -- Add playlist entry the first time we encounter its ID
        if not seen[row.id] then
            seen[row.id] = true
            playlists[#playlists + 1] = {
                Id      = row.id,
                Title   = row.name,
                Cover   = row.cover,
                IsOwner = row.phone_number == currentPhone,
                Songs   = {},
            }
        end

        -- Append song to the most recently added playlist (current group)
        if row.song_id then
            local current = playlists[#playlists]
            current.Songs[#current.Songs + 1] = row.song_id
        end
    end

    return playlists
end


-- NUI callback handler: routes all Music UI actions to the appropriate server callbacks
RegisterNUICallback("Music", function(data, cb)
    local action = data.action
    debugprint("Music:" .. (action or ""))

    if action == "getConfig" then
        cb(Music)

    elseif action == "createPlaylist" then
        TriggerCallback("music:createPlaylist", cb, data.name)

    elseif action == "editPlaylist" then
        TriggerCallback("music:editPlaylist", cb, data.id, data.title, data.cover)

    elseif action == "getPlaylists" then
        cb(FetchPlaylists())

    elseif action == "deletePlaylist" then
        TriggerCallback("music:deletePlaylist", cb, data.id)

    elseif action == "savePlaylist" then
        TriggerCallback("music:savePlaylist", cb, data.id)

    elseif action == "addSong" then
        TriggerCallback("music:addSong", cb, data.id, data.song)

    elseif action == "removeSong" then
        TriggerCallback("music:removeSong", cb, data.id, data.song)
    end
end)