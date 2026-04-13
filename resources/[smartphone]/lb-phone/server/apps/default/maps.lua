-- Fetch all saved locations for a phone number, normalising the DB row format
BaseCallback("maps:getSavedLocations", function(source, phoneNumber)
    local rows = MySQL.query.await(
        "SELECT id, `name`, x_pos, y_pos FROM phone_maps_locations WHERE phone_number = ? ORDER BY `name` ASC",
        { phoneNumber }
    )

    -- Re-map each row into the standard { id, name, position = {y, x} } shape
    for i = 1, #rows do
        local row = rows[i]
        rows[i] = {
            id       = row.id,
            name     = row.name,
            position = { row.y_pos, row.x_pos },
        }
    end

    return rows
end, {})

-- Insert a new saved location and return its new DB id
BaseCallback("maps:addLocation", function(source, phoneNumber, name, x, y)
    return MySQL.insert.await(
        "INSERT INTO phone_maps_locations (phone_number, `name`, x_pos, y_pos) VALUES (?, ?, ?, ?)",
        { phoneNumber, name, x, y }
    )
end)

-- Rename a saved location; returns true if a row was updated
BaseCallback("maps:renameLocation", function(source, phoneNumber, locationId, newName)
    return MySQL.update.await(
        "UPDATE phone_maps_locations SET `name` = ? WHERE id = ? AND phone_number = ?",
        { newName, locationId, phoneNumber }
    ) > 0
end)

-- Delete a saved location; returns true if a row was removed
BaseCallback("maps:removeLocation", function(source, phoneNumber, locationId)
    return MySQL.update.await(
        "DELETE FROM phone_maps_locations WHERE id = ? AND phone_number = ?",
        { locationId, phoneNumber }
    ) > 0
end)