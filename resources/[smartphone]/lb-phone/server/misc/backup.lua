-- Create or update a backup entry linking this player's identifier to their phone number
BaseCallback("backup:createBackup", function(source, phoneNumber)
  local rowsAffected = MySQL.update.await([[
        INSERT INTO phone_backups (id, phone_number) VALUES (@identifier, @phoneNumber)
        ON DUPLICATE KEY UPDATE phone_number = @phoneNumber
    ]], {
    ["@identifier"]   = GetIdentifier(source),
    ["@phoneNumber"]  = phoneNumber,
  })

  return rowsAffected > 0
end)

-- ─── backup:applyBackup ──────────────────────────────────────────────────────

-- Restore data from a backup phone number onto the player's current phone number.
-- Copies settings, photos, contacts, and map locations (skipping duplicates).
BaseCallback("backup:applyBackup", function(source, currentNumber, backupNumber)
  local identifier = GetIdentifier(source)

  -- Verify the backup belongs to this player and isn't the active number
  local backupExists = MySQL.scalar.await(
    "SELECT 1 FROM phone_backups WHERE id = ? AND phone_number = ?",
    { identifier, backupNumber }
  )

  if not backupExists or currentNumber == backupNumber then
    return false
  end

  local params = {
    ["@number"]       = backupNumber,
    ["@phoneNumber"]  = currentNumber,
  }

  -- Fetch settings rows for both numbers so we can merge security settings
  local rows = MySQL.query.await(
    "SELECT settings, pin, face_id, phone_number FROM phone_phones WHERE phone_number = @number OR phone_number = @phoneNumber",
    params
  )

  -- Identify which row belongs to the current number and which to the backup
  local currentRow, backupRow
  if rows[1] and rows[1].phone_number == currentNumber then
    currentRow = rows[1]
    backupRow  = rows[2]
  else
    currentRow = rows[2]
    backupRow  = rows[1]
  end

  if not currentRow or not backupRow then
    return false
  end

  -- Decode the backup's settings and merge security flags from the current phone
  local settings = json.decode(backupRow.settings)

  -- If the backup had a PIN set but the current phone has no PIN, disable it
  if settings.security.pinCode and not currentRow.pin then
    settings.security.pinCode = false
  end

  -- If the backup had Face ID set but the current phone has no Face ID, disable it
  if settings.security.faceId and not currentRow.face_id then
    settings.security.faceId = false
  end

  -- Apply merged settings to the current phone
  MySQL.update.await(
    "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
    { json.encode(settings), currentNumber }
  )

  -- Copy photos from backup that don't already exist on the current phone
  MySQL.update.await([[
        INSERT IGNORE INTO phone_photos (phone_number, link, is_video, size, `timestamp`)
        SELECT @phoneNumber, link, is_video, size, `timestamp`
        FROM phone_photos
        WHERE phone_number = @number AND link NOT IN (SELECT link FROM phone_photos WHERE phone_number = @phoneNumber)
    ]], params)

  -- Copy contacts from backup that don't already exist on the current phone
  MySQL.update.await([[
        INSERT IGNORE INTO phone_phone_contacts (contact_phone_number, firstname, lastname, profile_image, favourite, phone_number)
        SELECT contact_phone_number, firstname, lastname, profile_image, favourite, @phoneNumber
        FROM phone_phone_contacts
        WHERE phone_number = @number AND contact_phone_number NOT IN (SELECT contact_phone_number FROM phone_phone_contacts WHERE phone_number = @phoneNumber)
    ]], params)

  -- Copy map locations from backup that don't already exist on the current phone
  MySQL.update.await([[
        INSERT IGNORE INTO phone_maps_locations (id, phone_number, `name`, x_pos, y_pos)
        SELECT id, @phoneNumber, `name`, x_pos, y_pos
        FROM phone_maps_locations
        WHERE phone_number = @number AND id NOT IN (SELECT id FROM phone_maps_locations WHERE phone_number = @phoneNumber)
    ]], params)

  return true
end)

-- ─── backup:deleteBackup ─────────────────────────────────────────────────────

-- Delete a backup entry for the given phone number, verified by player identifier
BaseCallback("backup:deleteBackup", function(source, _currentNumber, backupNumber)
  local rowsAffected = MySQL.update.await(
    "DELETE FROM phone_backups WHERE id = ? AND phone_number = ?",
    { GetIdentifier(source), backupNumber }
  )

  return rowsAffected > 0
end)

-- ─── backup:getBackups ───────────────────────────────────────────────────────

-- Return all backed-up phone numbers associated with this player's identifier
BaseCallback("backup:getBackups", function(source, _phoneNumber)
  return MySQL.query.await(
    "SELECT phone_number AS `number` FROM phone_backups WHERE id = ?",
    { GetIdentifier(source) }
  )
end)