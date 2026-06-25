-----------------------------------------------------------------------------------------------------------------------------------------
-- BUYSKIN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.BuySkin(Table)
	local source = source
	local Number = tostring(Table["id"])
	local Passport = vRP.Passport(source)
	if Passport and Number and Users["Skins"][Passport] then
		if not Users["Skins"][Passport]["List"] then
			Users["Skins"][Passport]["List"] = {}
		end

		if Users["Skins"][Passport]["List"][Number] then
			return false
		end

		if vRP.PaymentGems(Passport,Table["price"]) then
			exports.discord:Embed("Weaponskins",
				"**[TIPO]:** Compra\n"..
				"**[PASSAPORTE]:** "..Passport.."\n"..
				"**[NÚMERO]:** "..Number
			)

			Users["Skins"][Passport]["List"][Number] = {
				["Weapon"] = Table["weapon"],
				["Component"] = Table["component"]
			}

			TriggerClientEvent("inventory:Skins",source,Users["Skins"][Passport])

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:SKINPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:SkinPlayer",function(Passport,Number,Weapon,Component)
	if not Users["Skins"][Passport] then
		Users["Skins"][Passport] = vRP.UserData(Passport,"Skins")
	end

	if not Users["Skins"][Passport]["List"] then
		Users["Skins"][Passport]["List"] = {}
	end

	if not Users["Skins"][Passport]["List"][Number] then
		Users["Skins"][Passport]["List"][Number] = {
			["Weapon"] = Weapon,
			["Component"] = Component
		}

		local source = vRP.Source(Passport)
		if source then
			TriggerClientEvent("inventory:Skins",source,Users["Skins"][Passport])
		else
			vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Skins", Information = json.encode(Users["Skins"][Passport]) })
			Users["Skins"][Passport] = nil
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXISTSKIN
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ExistSkin",function(Passport,Number)
	if not Users["Skins"][Passport] then
		Users["Skins"][Passport] = vRP.UserData(Passport,"Skins")
	end

	if not Users["Skins"][Passport]["List"] then
		Users["Skins"][Passport]["List"] = {}
	end

	return Users["Skins"][Passport]["List"][Number]
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFERSKIN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TransferSkin(OtherPassport,Number,Weapon,Component)
	if not (Number and Weapon and Component) then return false end

	local source = source
	local Number = tostring(Number)
	local Passport = vRP.Passport(source)
	local OtherPassport = parseInt(OtherPassport)
	if Passport and Users["Skins"][Passport] and Users["Skins"][Passport]["List"] and Users["Skins"][Passport]["List"][Number] then
		local OtherSource = vRP.Source(OtherPassport)
		if not OtherSource and not Users["Skins"][OtherPassport] then
			Users["Skins"][OtherPassport] = vRP.UserData(OtherPassport,"Skins")
		end

		if not Users["Skins"][OtherPassport]["List"] then
			Users["Skins"][OtherPassport]["List"] = {}
		end

		if not Users["Skins"][OtherPassport]["List"][Number] then
			exports.discord:Embed("Weaponskins",
				"**[TIPO]:** Transferência\n"..
				"**[PASSAPORTE]:** "..Passport.."\n"..
				"**[PARA]:** "..OtherPassport.."\n"..
				"**[NÚMERO]:** "..Number
			)

			Users["Skins"][OtherPassport]["List"][Number] = {
				["Weapon"] = Weapon,
				["Component"] = Component
			}

			if Users["Skins"][Passport][Weapon] == Component then
				Users["Skins"][Passport][Weapon] = nil
			end

			Users["Skins"][Passport]["List"][Number] = nil
			TriggerClientEvent("inventory:Skins",source,Users["Skins"][Passport])

			if not OtherSource and Users["Skins"][OtherPassport] then
				vRP.Query("playerdata/SetData",{ Passport = OtherPassport, Name = "Skins", Information = json.encode(Users["Skins"][OtherPassport]) })
				Users["Skins"][OtherPassport] = nil
			end

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACTIVESKIN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ActiveSkin(Weapon,Component)
	if not (Weapon and Component) then return false end

	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Users["Skins"][Passport] and not Users["Skins"][Passport][Weapon] then
		Users["Skins"][Passport][Weapon] = Component
		TriggerClientEvent("inventory:Skins",source,Users["Skins"][Passport])

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INACTIVESKIN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InactiveSkin(Weapon,Component)
	if Weapon and Component then
		local source = source
		local Passport = vRP.Passport(source)
		if Passport and Users["Skins"][Passport] and Users["Skins"][Passport][Weapon] then
			Users["Skins"][Passport][Weapon] = nil
			TriggerClientEvent("inventory:Skins",source,Users["Skins"][Passport])

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERSKINS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UserSkins()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Users["Skins"][Passport] and Users["Skins"][Passport]["List"] then
		return Users["Skins"][Passport]
	end

	return {
		["List"] = {}
	}
end