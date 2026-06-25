-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Sources = {}
Characters = {}
local Arena = {}
local Prepare = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Prepare(Name,Query)
	Prepare[Name] = Query
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- QUERY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Query(Name,Params)
	return exports.oxmysql:query_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SINGLEQUERY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SingleQuery(Name,Params)
	return exports.oxmysql:single_async(Prepare[Name].." LIMIT 1",Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SCALAR
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Scalar(Name,Params)
	return exports.oxmysql:scalar_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Update(Name,Params)
	return exports.oxmysql:update_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- IDENTITIES
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Identities(source)
	local Identities = GetPlayerIdentifierByType(source,BaseMode)

	return Identities and SplitTwo(Identities,":") or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Account(License)
	return vRP.SingleQuery("accounts/Account",{ License = License })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCORD
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Discord(Discord)
	return vRP.SingleQuery("accounts/Discord",{ Discord = Discord })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNTINFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AccountInformation(Passport,Mode)
	if not Mode then
		return false
	end

	local Account = vRP.AccountOptimize(Passport)
	return Account and Account[Mode] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNTOPTIMIZE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AccountOptimize(Passport)
	local Passport = parseInt(Passport)
	if Passport <= 0 then
		return false
	end

	local Identity = vRP.Identity(Passport)
	return Identity and Identity.License and vRP.Account(Identity.License) or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserData(Passport,Key)
	local Consult = vRP.SingleQuery("playerdata/GetData",{ Passport = Passport, Name = Key })

	return Consult and json.decode(Consult.Information) or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SIMPLEDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SimpleData(Passport,Key)
	local Consult = vRP.SingleQuery("playerdata/GetData",{ Passport = Passport, Name = Key })

	return Consult and json.decode(Consult.Information) or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Inventory(Passport)
	local Datatable = vRP.Datatable(Passport)

	return (Datatable and Datatable.Inventory) or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYSLOTS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventorySlots(Passport)
	local Datatable = vRP.Datatable(Passport)

	return (Datatable and Datatable.Slots) or Theme.inventory.slots.default or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVETEMPORARY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SaveTemporary(Passport,source,Table)
	if not Arena[Passport] then
		local Datatable = vRP.Datatable(Passport)
		if Datatable then
			local Route = Table.Route
			local Ped = GetPlayerPed(source)

			Arena[Passport] = {
				Inventory = Datatable.Inventory,
				Health = GetEntityHealth(Ped),
				Armour = GetPedArmour(Ped),
				Stress = Datatable.Stress,
				Hunger = Datatable.Hunger,
				Thirst = Datatable.Thirst,
				Pos = GetEntityCoords(Ped),
				Route = Route
			}

			vRP.Armour(source,100)
			Datatable.Inventory = {}
			vRPC.SetHealth(source,200)
			vRP.UpgradeHunger(Passport,100)
			vRP.UpgradeThirst(Passport,100)
			vRP.DowngradeStress(Passport,100)

			TriggerEvent("DebugWeapons",Passport)
			GlobalState["Arena:"..Route] = GlobalState["Arena:"..Route] + 1
			TriggerEvent("inventory:SaveArena",Passport,Table.Attachs,Table.Ammos)

			for Item,v in pairs(Table.Itens) do
				vRP.GenerateItem(Passport,Item,v.Amount,false,v.Slot)
			end

			exports.vrp:Bucket(source,"Enter",Route)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- APPLYTEMPORARY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ApplyTemporary(Passport,source)
	if Arena[Passport] then
		local Route = Arena[Passport].Route
		local Datatable = vRP.Datatable(Passport)
		if Datatable then
			Datatable.Stress = Arena[Passport].Stress
			Datatable.Hunger = Arena[Passport].Hunger
			Datatable.Thirst = Arena[Passport].Thirst
			Datatable.Inventory = Arena[Passport].Inventory

			TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
			TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
			TriggerClientEvent("hud:Stress",source,Datatable.Stress)
		end

		vRP.Armour(source,Arena[Passport].Armour)
		vRPC.SetHealth(source,Arena[Passport].Health)
		GlobalState["Arena:"..Route] = GlobalState["Arena:"..Route] - 1
		TriggerEvent("inventory:ApplyArena",Passport)
		TriggerEvent("vRP:ReloadWeapons",source)
		exports.vrp:Bucket(source,"Exit")

		Arena[Passport] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SkinCharacter(Passport,Hash)
	vRP.Update("characters/SetSkin",{ Passport = Passport, Skin = Hash })

	local source = vRP.Source(Passport)
	if Characters[source] then
		Characters[source].Skin = Hash
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Passport(source)
	if not source then
		return false
	end

	local Character = Characters[source]
	if not Character or not Character.id then
		return false
	end

	local Passport = Character.id
	local PlayerObject = Player(source)
	if not PlayerObject then
		return Passport
	end

	local PlayerState = PlayerObject.state
	local CurrentName = PlayerState.Name
	if not CurrentName or CurrentName == "" or CurrentName == NameDefault or CurrentName == "Desconhecido" then
		local Identity = vRP.Identity(Passport)
		if Identity then
			PlayerState.Name = ("%s %s"):format(Identity.Name,Identity.Lastname)
			exports.discord:Content("Rename",Identity.Discord.." #"..Passport.." "..Identity.Name.." "..Identity.Lastname)
		end
	end

	if PlayerState.Passport ~= Passport then
		PlayerState.Passport = Passport
	end

	return Passport
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Players()
	return Sources
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETUSERSOURCE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Source(Passport)
	return Sources[parseInt(Passport)] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DATATABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Datatable(Passport)
	local Passport = parseInt(Passport)
	if Passport <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	return (source and Characters[source] and Characters[source].Datatable) or vRP.UserData(Passport,"Datatable") or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DATATABLEINFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DatatableInformation(Passport,Mode)
	local Passport = parseInt(Passport)
	if Passport <= 0 or not Mode then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	return Datatable and Datatable[Mode] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEDATATABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateDatatable(Passport,Mode,Value)
	local Passport = parseInt(Passport)
	if Passport <= 0 or not Mode then
		return false
	end

	local source = vRP.Source(Passport)
	local Datatable = (source and Characters[source] and vRP.Datatable(Passport)) or vRP.UserData(Passport,"Datatable") or {}

	Datatable[Mode] = Value

	if not (source and Characters[source]) then
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Datatable", Information = json.encode(Datatable) })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Kick(source,Reason)
	if Disconnect(source,Reason) then
		DropPlayer(source,Reason)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERDROPPED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerDropped",function(Reason)
	Disconnect(source,Reason)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
function Disconnect(source,Reason)
	local Armour = 0
	local Health = 100
	local Coords = SpawnCoords[1]
	local Ped = GetPlayerPed(source)

	if DoesEntityExist(Ped) then
		Armour = GetPedArmour(Ped)
		Health = GetEntityHealth(Ped)
		Coords = GetEntityCoords(Ped)
	end

	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	if Arena[Passport] then
		Datatable.Pos = Arena[Passport].Pos
		Datatable.Stress = Arena[Passport].Stress
		Datatable.Hunger = Arena[Passport].Hunger
		Datatable.Thirst = Arena[Passport].Thirst
		Datatable.Armour = Arena[Passport].Armour
		Datatable.Health = Arena[Passport].Health
		Datatable.Inventory = Arena[Passport].Inventory

		local Route = Arena[Passport].Route
		GlobalState["Arena:"..Route] = GlobalState["Arena:"..Route] - 1
		TriggerEvent("inventory:ApplyArena",Passport)
		Arena[Passport] = nil
	else
		Datatable.Armour = Armour
		Datatable.Health = Health

		local Property = exports.propertys:Inside(Passport)
		if Property then
			Datatable.Pos = exports.propertys:Coords(Property) or Coords
		else
			local Security = exports.securitycam:Inside(Passport)
			Datatable.Pos = Security or Coords
		end
	end

	vRP.Update("characters/LastLogin",{ Passport = Passport })
	TriggerEvent("Disconnect",Passport,source,Characters[source].License)
	vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Datatable", Information = json.encode(Datatable) })
	exports.discord:Embed("Disconnect","**[SOURCE]:** "..source.."\n**[PASSAPORTE]:** "..Passport.."\n**[VIDA]:** "..Datatable.Health.."\n**[COLETE]:** "..Datatable.Armour.."\n**[COORDS]:** "..Datatable.Pos.."\n**[MOTIVO]:** "..Reason)

	if DisconnectReason then
		exports.chat:Postit(Passport,Coords,Reason,DisconnectReason)
	end

	if Characters[source] then
		Characters[source] = nil
	end

	if Sources[Passport] then
		Sources[Passport] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERCONNECTING
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerConnecting",function(_,__,deferrals)
	deferrals.defer()

	local source = source
	local License = vRP.Identities(source)
	local Platform = (BaseMode == "steam" and "Steam" or "Rockstar")

	if not License then
		return deferrals.update("Não foi possível efetuar conexão com a "..Platform..".")
	end

	if type(Maintenance) == "table" and not Maintenance[License] then
		return deferrals.update("Estamos realizando manutenções programadas para aplicar melhorias e correções no servidor.\nFique de olho no nosso Discord para acompanhar atualizações e o horário de retorno.\nAgradecemos pela paciência e compreensão.")
	end

	local Account = vRP.Account(License)
	if not Account then
		vRP.Query("accounts/NewAccount",{ License = License, Token = vRP.GenerateToken() })
		deferrals.update("Adicionando informações primárias ao banco de dados.")
		Account = vRP.Account(License)
	end

	if not Account then
		return deferrals.update("Não foi possível encontrar suas informações ao banco de dados.")
	end

	local Banned = vRP.Banned(source,Account)
	if Banned then
		if Banned[1] == "Other" then
			deferrals.update("Banido ( "..Banned[2].." )\nInformamos que o motivo do seu banimento é por questões unilaterais, onde outra pessoa da sua rede ou computador comprometeu sua conexão devido a uma punição.")
		else
			deferrals.update("Banimento Permanente\nMotivo: "..(Account.Reason or "Banimento administrativo"))
		end

		return false
	end

	if Whitelisted then
		if Account.Whitelist then
			deferrals.update("Registrando sua conexão ao banco de dados.")
			vRP.Update("accounts/LastLogin",{ License = License })

			return deferrals.done()
		end

		return deferrals.update("Efetue sua liberação através do discord enviando: "..Account[Liberation].."\nAcesse através do link: "..ServerLink)
	end

	deferrals.update("Registrando sua conexão ao banco de dados.")
	vRP.Update("accounts/LastLogin",{ License = License })

	deferrals.done()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CharacterChosen(source,Passport,Model)
	if not source or not Passport then
		return false
	end

	if Characters[source] then
		return DropPlayer(source,"Desconectado")
	end

	Sources[Passport] = source

	vRP.Update("characters/LastLogin",{ Passport = Passport })

	local License = vRP.Identities(source)
	local Account = vRP.Account(License) or {}
	local Character = vRP.SingleQuery("characters/Person",{ Passport = Passport }) or {}

	local Datatable = vRP.UserData(Passport,"Datatable") or {}
	Characters[source] = { Datatable = Datatable }

	for Index,Value in pairs(Account) do
		Characters[source][Index] = Value
	end

	for Index,Value in pairs(Character) do
		Characters[source][Index] = Value
	end

	if Model then
		Characters[source].Datatable.Inventory = {}

		for Item,Amount in pairs(CharacterItens) do
			vRP.GenerateItem(Passport,Item,Amount)
		end

		local Table = {
			Barbershop = BarbershopInit[Model] or {},
			Clothings = SkinshopInit[Model] or {},
			Tattooshop = {},
			Datatable = {}
		}

		for Name,v in pairs(Table) do
			vRP.Query("playerdata/SetData",{ Passport = Passport, Name = Name, Information = json.encode(v) })
		end
	end

	if (Account.Gemstone or 0) > 0 then
		TriggerClientEvent("hud:AddGemstone",source,Account.Gemstone)
	end

	exports.discord:Embed("Connect",string.format("**[SOURCE]:** %s\n**[PASSAPORTE]:** %s\n**[ADDRESS]:** %s\n**[LICENSE]:** %s\n**[DISCORD]:** <@%s>",source,Passport,GetPlayerEndpoint(source) or "N/A",Account.License or "N/A",Account.Discord or "N/A"))

	TriggerEvent("CharacterChosen",Passport,source)
end