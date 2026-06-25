-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("characters/Person","SELECT * FROM characters WHERE id = @Passport")
vRP.Prepare("characters/Delete","UPDATE characters SET Deleted = 1 WHERE id = @Passport")
vRP.Prepare("characters/SetSkin","UPDATE characters SET Skin = @Skin WHERE id = @Passport")
vRP.Prepare("characters/UpdateDaily","UPDATE characters SET Daily = @Daily WHERE id = @Passport")
vRP.Prepare("characters/AddBank","UPDATE characters SET Bank = Bank + @Bank WHERE id = @Passport")
vRP.Prepare("characters/RemBank","UPDATE characters SET Bank = Bank - @Bank WHERE id = @Passport")
vRP.Prepare("characters/ReducePrison","UPDATE characters SET Prison = Prison - 1 WHERE id = @Passport")
vRP.Prepare("characters/Characters","SELECT * FROM characters WHERE License = @License AND Deleted = 0")
vRP.Prepare("characters/LastLogin","UPDATE characters SET Login = UNIX_TIMESTAMP() WHERE id = @Passport")
vRP.Prepare("characters/UserLicense","SELECT * FROM characters WHERE id = @Passport AND License = @License")
vRP.Prepare("characters/InsertPrison","UPDATE characters SET Prison = Prison + @Prison WHERE id = @Passport")
vRP.Prepare("characters/Count","SELECT COUNT(License) FROM characters WHERE License = @License AND Deleted = 0")
vRP.Prepare("characters/UpdateName","UPDATE characters SET Name = @Name, Lastname = @Lastname WHERE id = @Passport")
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANNED
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("accounts/RemoveBanned","UPDATE accounts SET Banned = 0 WHERE id = @Account")
vRP.Prepare("accounts/ReduceBanned","UPDATE accounts SET Banned = Banned - @Amount WHERE id = @Account")
vRP.Prepare("accounts/BannedPermanent","UPDATE accounts SET Banned = -1, Reason = @Reason WHERE id = @Account")
vRP.Prepare("accounts/InsertBanned","UPDATE accounts SET Banned = Banned + @Amount, Reason = @Reason WHERE id = @Account")
-----------------------------------------------------------------------------------------------------------------------------------------
-- SMARTPHONE
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("smartphone/Phone","SELECT * FROM phone_phones WHERE owner_id = @Passport")
vRP.Prepare("smartphone/CheckInstagram","SELECT * FROM phone_instagram_accounts WHERE phone_number = @Phone")
vRP.Prepare("smartphone/Instagram","UPDATE phone_instagram_accounts SET follower_count = follower_count + @Amount WHERE username = @Username")
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNTS
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("accounts/All","SELECT * FROM accounts")
vRP.Prepare("accounts/Token","SELECT * FROM accounts WHERE Token = @Token")
vRP.Prepare("accounts/Account","SELECT * FROM accounts WHERE License = @License")
vRP.Prepare("accounts/Discord","SELECT * FROM accounts WHERE Discord = @Discord")
vRP.Prepare("accounts/Clean","UPDATE accounts SET Whitelist = 0 WHERE License = @License")
vRP.Prepare("accounts/NewAccount","INSERT INTO accounts (License,Token) VALUES (@License,@Token)")
vRP.Prepare("accounts/LastLogin","UPDATE accounts SET Login = UNIX_TIMESTAMP() WHERE License = @License")
vRP.Prepare("accounts/AddGemstone","UPDATE accounts SET Gemstone = Gemstone + @Gemstone WHERE License = @License")
vRP.Prepare("accounts/UpdateCharacters","UPDATE accounts SET Characters = Characters + 1 WHERE License = @License")
vRP.Prepare("accounts/RemoveGemstone","UPDATE accounts SET Gemstone = Gemstone - @Gemstone WHERE License = @License")
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERDATA
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("playerdata/GetData","SELECT * FROM playerdata WHERE Passport = @Passport AND Name = @Name")
vRP.Prepare("playerdata/SetData","INSERT INTO playerdata (Passport,Name,Information) VALUES (@Passport,@Name,@Information) ON DUPLICATE KEY UPDATE Name = VALUES(Name), Information = VALUES(Information)")
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITYDATA
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("entitydata/RemoveData","DELETE FROM entitydata WHERE Name = @Name")
vRP.Prepare("entitydata/GetData","SELECT Information FROM entitydata WHERE Name = @Name")
vRP.Prepare("entitydata/SetData","INSERT INTO entitydata (Name,Information) VALUES (@Name,@Information) ON DUPLICATE KEY UPDATE Information = VALUES(Information)")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLES
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("vehicles/All","SELECT * FROM vehicles")
vRP.Prepare("vehicles/plateVehicles","SELECT * FROM vehicles WHERE Plate = @Plate")
vRP.Prepare("vehicles/Arrest","UPDATE vehicles SET Arrest = 1 WHERE Plate = @Plate")
vRP.Prepare("vehicles/UserVehicles","SELECT * FROM vehicles WHERE Passport = @Passport")
vRP.Prepare("vehicles/Count","SELECT COUNT(Vehicle) FROM vehicles WHERE Vehicle = @Vehicle")
vRP.Prepare("vehicles/PlateUsers","SELECT * FROM vehicles WHERE Plate = @Plate AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/removeVehicles","DELETE FROM vehicles WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/selectVehicles","SELECT * FROM vehicles WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/CoiloverVehicles","UPDATE vehicles SET Drift = 1 WHERE Vehicle = @Vehicle AND Plate = @Plate")
vRP.Prepare("vehicles/SeatbeltVehicles","UPDATE vehicles SET Seatbelt = 1 WHERE Plate = @Plate AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/PaymentArrest","UPDATE vehicles SET Arrest = 0 WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/plateVehiclesUpdate","UPDATE vehicles SET Plate = @NewPlate WHERE Plate = @Plate AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/PlateOwner","SELECT * FROM vehicles WHERE Plate = @Plate AND Vehicle = @Vehicle AND Passport = @Passport")
vRP.Prepare("vehicles/moveVehicles","UPDATE vehicles SET Passport = @OtherPassport WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/UpdateWeight","UPDATE vehicles SET Weight = Weight + (10 * @Multiplier) WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/updateVehiclesTax","UPDATE vehicles SET Tax = UNIX_TIMESTAMP() + (86400 * 30) WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/rentalVehiclesUpdate","UPDATE vehicles SET Rental = UNIX_TIMESTAMP() + (86400 * @Days) WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/addVehicles","INSERT IGNORE INTO vehicles (Passport,Vehicle,Plate,Weight,Work,Tax) VALUES (@Passport,@Vehicle,@Plate,@Weight,@Work,UNIX_TIMESTAMP() + (86400 * 7))")
vRP.Prepare("vehicles/updateVehiclesRespawns","UPDATE vehicles SET Engine = @Engine, Body = @Body, Health = @Health, Fuel = @Fuel, Windows = @Windows, Nitro = @Nitro WHERE Passport = @Passport AND Vehicle = @Vehicle")
vRP.Prepare("vehicles/rentalVehicles","INSERT IGNORE INTO vehicles (Passport,Vehicle,Plate,Weight,Work,Rental,Tax) VALUES (@Passport,@Vehicle,@Plate,@Weight,@Work,UNIX_TIMESTAMP() + (86400 * @Days),UNIX_TIMESTAMP() + (86400 * @Days))")
vRP.Prepare("vehicles/updateVehicles","UPDATE vehicles SET Engine = @Engine, Body = @Body, Health = @Health, Fuel = @Fuel, Doors = @Doors, Windows = @Windows, Tyres = @Tyres, Nitro = @Nitro WHERE Passport = @Passport AND Vehicle = @Vehicle")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHESTS
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("chests/GetChests","SELECT * FROM chests WHERE Name = @Name")
vRP.Prepare("chests/AddChests","INSERT IGNORE INTO chests (Name,Permission) VALUES (@Name,@Name)")
vRP.Prepare("chests/UpdateWeight","UPDATE chests SET Weight = Weight + (10 * @Multiplier), Slots = Slots + (5 * @Multiplier) WHERE Name = @Name")
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("propertys/All","SELECT * FROM propertys")
vRP.Prepare("propertys/Sell","DELETE FROM propertys WHERE Name = @Name")
vRP.Prepare("propertys/Exist","SELECT * FROM propertys WHERE Name = @Name")
vRP.Prepare("propertys/Serial","SELECT * FROM propertys WHERE Serial = @Serial")
vRP.Prepare("propertys/Garages","SELECT * FROM propertys WHERE Garage IS NOT NULL")
vRP.Prepare("propertys/AllUser","SELECT * FROM propertys WHERE Passport = @Passport")
vRP.Prepare("propertys/Item","UPDATE propertys SET Item = Item + 1 WHERE Name = @Name")
vRP.Prepare("propertys/Garage","UPDATE propertys SET Garage = @Garage WHERE Name = @Name")
vRP.Prepare("propertys/Credentials","UPDATE propertys SET Serial = @Serial WHERE Name = @Name")
vRP.Prepare("propertys/Transfer","UPDATE propertys SET Passport = @Passport WHERE Name = @Name")
vRP.Prepare("propertys/Count","SELECT COUNT(Passport) FROM propertys WHERE Passport = @Passport")
vRP.Prepare("propertys/Check","SELECT * FROM propertys WHERE Name = @Name AND Passport = @Passport")
vRP.Prepare("propertys/Tax","UPDATE propertys SET Tax = UNIX_TIMESTAMP() + (86400 * 30) WHERE Name = @Name")
vRP.Prepare("propertys/Buy","INSERT INTO propertys (Name,Interior,Passport,Serial,Tax) VALUES (@Name,@Interior,@Passport,@Serial,UNIX_TIMESTAMP() + (86400 * 30))")
-----------------------------------------------------------------------------------------------------------------------------------------
-- HWID
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("hwid/Check","SELECT * FROM hwid WHERE Token = @Token")
vRP.Prepare("hwid/All","UPDATE hwid SET Banned = @Banned WHERE Account = @Account")
vRP.Prepare("hwid/Insert","INSERT INTO hwid (Token,Account) VALUES (@Token,@Account)")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARTABLES
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("summerz/Playerdata","DELETE FROM playerdata WHERE Information = '[]' OR Information = '{}'")
vRP.Prepare("summerz/Entitydata","DELETE FROM entitydata WHERE Information = '[]' OR Information = '{}'")
-----------------------------------------------------------------------------------------------------------------------------------------
-- LB-PHONE
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.Prepare("summerz/PhoneCalls","DELETE FROM phone_phone_calls WHERE timestamp < NOW() - INTERVAL 3 DAY")
vRP.Prepare("summerz/PhoneMessages","DELETE FROM phone_message_messages WHERE timestamp < NOW() - INTERVAL 3 DAY")
vRP.Prepare("summerz/PhoneServices","DELETE FROM phone_services_messages WHERE timestamp < NOW() - INTERVAL 1 DAY")
vRP.Prepare("summerz/PhoneNotifications","DELETE FROM phone_notifications WHERE timestamp < NOW() - INTERVAL 3 DAY")
vRP.Prepare("summerz/PhoneStorys","DELETE FROM phone_instagram_stories_views WHERE timestamp < NOW() - INTERVAL 3 DAY")
vRP.Prepare("summerz/PhoneInstagram","DELETE FROM phone_instagram_notifications WHERE timestamp < NOW() - INTERVAL 3 DAY")
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	vRP.Query("summerz/Playerdata")
	vRP.Query("summerz/Entitydata")

	-- LB-PHONE
	vRP.Query("summerz/PhoneCalls")
	vRP.Query("summerz/PhoneStorys")
	vRP.Query("summerz/PhoneMessages")
	vRP.Query("summerz/PhoneServices")
	vRP.Query("summerz/PhoneInstagram")
	vRP.Query("summerz/PhoneNotifications")
end)