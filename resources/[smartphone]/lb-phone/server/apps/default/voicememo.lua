-- Callback: save a new voice memo recording for the player
BaseCallback("voiceMemo:saveRecording", function(src, phoneNumber, recording)
    -- Require both a file URL and duration before saving
    if not recording.src or not recording.duration then
        debugprint("VoiceMemo: no src/duration, not saving")
        return
    end

    return MySQL.insert.await(
        "INSERT INTO phone_voice_memos_recordings (phone_number, file_name, file_url, file_length) VALUES (?, ?, ?, ?)",
        {
            phoneNumber,
            recording.title or "Unknown",
            recording.src,
            recording.duration,
        }
    )
end)

-- Callback: fetch all voice memos for the player, newest first
BaseCallback("voiceMemo:getMemos", function(src, phoneNumber)
    return MySQL.query.await(
        "SELECT id, file_name AS `title`, file_url AS `src`, file_length AS `duration`, created_at AS `timestamp` FROM phone_voice_memos_recordings WHERE phone_number = ? ORDER BY created_at DESC",
        { phoneNumber }
    )
end, {})

-- Callback: delete a memo by ID (scoped to the player's phone number)
BaseCallback("voiceMemo:deleteMemo", function(src, phoneNumber, memoId)
    local affected = MySQL.update.await(
        "DELETE FROM phone_voice_memos_recordings WHERE id = ? AND phone_number = ?",
        { memoId, phoneNumber }
    )
    return affected > 0
end)

-- Callback: rename a memo by ID (scoped to the player's phone number)
BaseCallback("voiceMemo:renameMemo", function(src, phoneNumber, memoId, newTitle)
    local affected = MySQL.update.await(
        "UPDATE phone_voice_memos_recordings SET file_name = ? WHERE id = ? AND phone_number = ?",
        { newTitle, memoId, phoneNumber }
    )
    return affected > 0
end)