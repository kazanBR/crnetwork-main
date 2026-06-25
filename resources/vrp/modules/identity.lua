-----------------------------------------------------------------------------------------------------------------------------------------
-- IDENTITY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Identity(Passport)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	return Characters[source] or vRP.SingleQuery("characters/Person",{ Passport = Passport })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FULLNAME
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.FullName(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and (Identity.Name.." "..Identity.Lastname) or NameDefault
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOWERNAME
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.LowerName(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and Identity.Name or SplitOne(NameDefault," ")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AVATAR
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Avatar",function(Passport,Permission)
	local Consult = exports.oxmysql:single_async("SELECT Image FROM avatars WHERE Passport = @Passport AND Permission = @Permission LIMIT 1",{ Passport = Passport, Permission = Permission })

	return Consult and Consult.Image or ""
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LICENSE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.License(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and Identity.License or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSERTPRISON
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsertPrison(Passport,Amount)
	if not Passport or Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	local Amount = parseInt(Amount,true)
	local Character = source and Characters[source]
	if not Character then
		return false
	end

	TriggerClientEvent("Notify",source,"Boolingbroke",("Você foi sentenciado a <b>%d minutos</b> de prisão."):format(Amount),"policia",10000)
	vRP.Update("characters/InsertPrison",{ Passport = Passport, Prison = Amount })
	Character.Prison = (Character.Prison or 0) + Amount
	Player(source).state.Prison = true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPRISON
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdatePrison(Passport)
	if not Passport then
		return false
	end

	local source = vRP.Source(Passport)
	local Character = source and Characters[source]
	if not Character or Character.Prison <= 0 then
		return false
	end

	vRP.Update("characters/ReducePrison",{ Passport = Passport })
	Character.Prison = Character.Prison - 1

	if Character.Prison <= 0 then
		Player(source).state.Prison = false
		vRP.Teleport(source,PrisonCoords.x,PrisonCoords.y,PrisonCoords.z)
	else
		TriggerClientEvent("Notify",source,"Boolingbroke",("Restam <b>%d minutos</b> até sua liberação."):format(Character.Prison),"policia",5000)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADECHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeCharacters(source)
	if Characters[source] then
		vRP.Update("accounts/UpdateCharacters",{ License = Characters[source].License })
		Characters[source].Characters = Characters[source].Characters + 1
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserGemstone(License)
	return vRP.Account(License).Gemstone or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADEGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeGemstone(Passport,Amount,SendLicense)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)
	if Amount > 0 and Identity then
		vRP.Update("accounts/AddGemstone",{ License = Identity.License, Gemstone = Amount })

		if DiscordBot and SendLicense then
			local Account = vRP.Account(Identity.License)
			exports.discord:Content("Gemstone",Account.Discord.." Obrigado por sua contribuição ao **"..ServerName.."**, seus **"..Dotted(Amount).."x Diamantes** foram creditados em sua conta.")
		end

		local source = vRP.Source(Passport)
		if Characters[source] then
			TriggerClientEvent("hud:AddGemstone",source,Amount)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADENAMES
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeNames(Passport,Name,Lastname)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	if Characters[source] then
		Characters[source].Name = Name
		Characters[source].Lastname = Lastname
	end

	vRP.Update("characters/UpdateName",{ Name = Name, Lastname = Lastname, Passport = Passport })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORTPLATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PassportPlate(Plate)
	local Consult = vRP.SingleQuery("vehicles/plateVehicles",{ Plate = Plate })
	return Consult and Consult.Passport or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEPLATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GeneratePlate()
	local Plate
	local Result

	repeat
		Plate = GenerateString("DDLLLDDD")
		Result = vRP.PassportPlate(Plate)
	until not Result

	return Plate
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATETOKEN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GenerateToken()
	local Token
	local Result

	repeat
		Token = GenerateString("DDDDDDD")
		Result = vRP.SingleQuery("accounts/Token",{ Token = Token })
	until not Result

	return Token
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEHASH
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GenerateHash(Index)
	local Hash
	local Result

	repeat
		Hash = GenerateString("DDLLDDLL")
		Result = vRP.SingleQuery("entitydata/GetData",{ Name = Index..":"..Hash })
	until not Result

	return Hash
end