-- Insert a new note and return its new DB id
BaseCallback("notes:createNote", function(source, phoneNumber, title, content)
    return MySQL.insert.await(
        "INSERT INTO phone_notes (phone_number, title, content) VALUES (?, ?, ?)",
        { phoneNumber, title, content }
    )
end)

-- Update an existing note's title and content; returns true if a row was affected
BaseCallback("notes:saveNote", function(source, phoneNumber, noteId, title, content)
    return MySQL.update.await(
        "UPDATE phone_notes SET title = ?, content = ? WHERE id = ? AND phone_number = ?",
        { title, content, noteId, phoneNumber }
    ) > 0
end)

-- Delete a note; returns true if a row was removed
BaseCallback("notes:removeNote", function(source, phoneNumber, noteId)
    return MySQL.update.await(
        "DELETE FROM phone_notes WHERE id = ? AND phone_number = ?",
        { noteId, phoneNumber }
    ) > 0
end)

-- Fetch all notes for a given phone number
BaseCallback("notes:getNotes", function(source, phoneNumber)
    return MySQL.query.await(
        "SELECT id, title, content, `timestamp` FROM phone_notes WHERE phone_number = ?",
        { phoneNumber }
    )
end)