-- Callback: create a new playlist and auto-save it for the creator
BaseCallback("music:createPlaylist", function(source, phoneNumber, name)
    local playlistId = MySQL.insert.await(
        "INSERT INTO phone_music_playlists (`name`, phone_number) VALUES (?, ?)",
        { name, phoneNumber }
    )

    if not playlistId then
        return false
    end

    -- Auto-save the new playlist to the creator's library
    MySQL.update.await(
        "INSERT INTO phone_music_saved_playlists (playlist_id, phone_number) VALUES (?, ?)",
        { playlistId, phoneNumber }
    )

    return playlistId
end)


-- Callback: edit a playlist's name and cover (owner only)
BaseCallback("music:editPlaylist", function(source, phoneNumber, playlistId, name, cover)
    local affected = MySQL.update.await(
        "UPDATE phone_music_playlists SET `name` = ?, cover = ? WHERE id = ? AND phone_number = ?",
        { name, cover, playlistId, phoneNumber }
    )
    return affected > 0
end)


-- Callback: get all playlists saved by this phone number, with their songs
BaseCallback("music:getPlaylists", function(source, phoneNumber)
    return MySQL.query.await([[
        SELECT s.song_id, p.id, p.`name`, p.cover, p.phone_number
        FROM phone_music_playlists p
        LEFT JOIN phone_music_saved_playlists p2 ON p2.playlist_id = p.id
        LEFT JOIN phone_music_songs s ON s.playlist_id = p.id
        WHERE p2.phone_number = ?
        ORDER BY p.`name` ASC
    ]], { phoneNumber })
end)


-- Callback: delete a playlist (owner only)
BaseCallback("music:deletePlaylist", function(source, phoneNumber, playlistId)
    local affected = MySQL.update.await(
        "DELETE FROM phone_music_playlists WHERE id = ? AND phone_number = ?",
        { playlistId, phoneNumber }
    )
    return affected > 0
end)


-- Callback: save (follow) a playlist to this phone number's library
BaseCallback("music:savePlaylist", function(source, phoneNumber, playlistId)
    local affected = MySQL.update.await(
        "INSERT INTO phone_music_saved_playlists (playlist_id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = phone_number",
        { playlistId, phoneNumber }
    )
    return affected > 0
end)


-- Callback: add a song to a playlist (owner only)
BaseCallback("music:addSong", function(source, phoneNumber, playlistId, songId)
    -- Verify ownership before allowing modification
    local isOwner = MySQL.scalar.await(
        "SELECT 1 FROM phone_music_playlists WHERE id = ? AND phone_number = ?",
        { playlistId, phoneNumber }
    )

    if not isOwner then
        return false
    end

    local affected = MySQL.update.await(
        "INSERT INTO phone_music_songs (playlist_id, song_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE song_id = song_id",
        { playlistId, songId }
    )
    return affected > 0
end)


-- Callback: remove a song from a playlist (owner only)
BaseCallback("music:removeSong", function(source, phoneNumber, playlistId, songId)
    -- Verify ownership before allowing modification
    local isOwner = MySQL.scalar.await(
        "SELECT 1 FROM phone_music_playlists WHERE id = ? AND phone_number = ?",
        { playlistId, phoneNumber }
    )

    if not isOwner then
        return false
    end

    local affected = MySQL.update.await(
        "DELETE FROM phone_music_songs WHERE playlist_id = ? AND song_id = ?",
        { playlistId, songId }
    )
    return affected > 0
end)