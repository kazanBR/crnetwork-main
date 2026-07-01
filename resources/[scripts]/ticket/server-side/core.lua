-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("ticket",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Cooldown = { Ticket = {}, Message = {} }
local Spectate = {}
local FrozenPlayers = {}
local WaypointTracking = {}
local WeatherWhitelist = {
	["CLEAR"] = true, ["EXTRASUNNY"] = true, ["NEUTRAL"] = true, ["SMOG"] = true,
	["FOGGY"] = true, ["OVERCAST"] = true, ["CLOUDS"] = true, ["CLEARING"] = true,
	["RAIN"] = true, ["THUNDER"] = true, ["SNOW"] = true, ["BLIZZARD"] = true,
	["SNOWLIGHT"] = true, ["XMAS"] = true, ["HALLOWEEN"] = true,
	["RAIN_HALLOWEEN"] = true, ["SNOW_HALLOWEEN"] = true
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permissions()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then return false end

	local Payload = {
		Characters = {
			View = false, Spectate = false, Revive = false, Kill = false,
			Freeze = false, Goto = false, Bring = false, Waypoint = false,
			SendPrivateMessage = false, AddGroup = false, RemoveGroup = false,
			Screenshot = false, ClearInventory = false, SetPed = false,
			Bank = { View = false, Add = false, Remove = false },
			Gemstone = { View = false, Add = false, Remove = false },
			Inventory = { View = false, Give = false, Remove = false },
			Vehicles = { View = false, Add = false, Remove = false }
		},
		Tickets = true,
		Server = false
	}

	if vRP.HasPermission(Passport,Config.Administrator) then
		for Index,_ in pairs(Payload.Characters) do
			if type(Payload.Characters[Index]) == "boolean" then
				Payload.Characters[Index] = true
			elseif type(Payload.Characters[Index]) == "table" then
				for Nested,_ in pairs(Payload.Characters[Index]) do
					Payload.Characters[Index][Nested] = true
				end
			end
		end
		Payload.Server = true
	end

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Groups()
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	local Payload = {}
	if not Groups then
		return Payload
	end

	for Permission,Data in pairs(Groups) do
		Payload[Permission] = {
			Name = Data.Name or Permission,
			Block = Data.Block or false,
			Hierarchy = Data.Hierarchy or {}
		}
	end

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Characters()
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	local Result = exports.oxmysql:query_async("SELECT id,Name,Lastname FROM characters ORDER BY id DESC LIMIT 1000",{})
	if not Result then
		return {}
	end

	local Characters = {}
	for _,Row in ipairs(Result) do
		local CharacterPassport = parseInt(Row.id)
		local TargetSource = vRP.Source(CharacterPassport)
		local FullName = vRP.FullName(CharacterPassport) or ("%s %s"):format(Row.Name or "",Row.Lastname or ""):gsub("^%s+",""):gsub("%s+$","")
		
		if FullName == "" then
			FullName = ("Usuario #%s"):format(CharacterPassport)
		end

		Characters[#Characters + 1] = {
			Passport = CharacterPassport,
			Name = FullName,
			Online = TargetSource ~= nil
		}
	end

	return Characters
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Character(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local Identity = vRP.Identity(TargetPassport)
	if not Identity then
		return false
	end

	local Account = vRP.Account(Identity.License)
	local TargetSource = vRP.Source(TargetPassport)
	local Groups = vRP.UserGroups(TargetPassport) or {}

	local PayloadGroups = {}
	for GroupName,Hierarchy in pairs(Groups) do
		PayloadGroups[#PayloadGroups + 1] = {
			Name = GroupName,
			Hierarchy = Hierarchy or 0
		}
	end

	local LastLogin = Identity.Login or 0
	
	local TotalPlaying = vRP.Playing(TargetPassport,"Online") or 0

	return {
		Passport = TargetPassport,
		Name = vRP.FullName(TargetPassport) or ("Usuario #%s"):format(TargetPassport),
		Online = TargetSource ~= nil,
		Discord = Account and Account.Discord or "0",
		License = Identity.License or "0",
		LastLogin = LastLogin,
		Playing = TotalPlaying,
		Bank = vRP.GetBank(TargetPassport) or 0,
		Gemstone = (Identity.License and vRP.UserGemstone(Identity.License)) or 0,
		Groups = PayloadGroups,
		Avatar = ""
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Spectate(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	if Spectate[Passport] then
		local Ped = GetPlayerPed(Spectate[Passport])
		if DoesEntityExist(Ped) then
			SetEntityDistanceCullingRadius(Ped,0.0)
		end

		TriggerClientEvent("ticket:resetSpectate",Source)
		Spectate[Passport] = nil
		TriggerClientEvent("ticket:Notify",Source,"Sucesso","Voce parou de espectar.","verde")

		return true
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local Ped = GetPlayerPed(TargetSource)
	if DoesEntityExist(Ped) then
		Spectate[Passport] = TargetSource
		SetEntityDistanceCullingRadius(Ped,999999.0)

		SetTimeout(1000,function()
			TriggerClientEvent("ticket:initSpectate",Source,TargetSource)
		end)

		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce esta espectando #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REVIVE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Revive(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport, Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify", Source, "Atenção", "Jogador não está online.", "amarelo")
		return false
	end

	vRP.Revive(TargetSource, 300)
	vRP.UpgradeThirst(TargetPassport, 10)
	vRP.UpgradeHunger(TargetPassport, 10)
	vRP.DowngradeStress(TargetPassport, 100)
	TriggerClientEvent("paramedic:Reset", TargetSource)

	TriggerClientEvent("ticket:Notify", Source, "Sucesso", ("Você reviveu #%s - %s."):format(TargetPassport, vRP.FullName(TargetPassport)), "verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KILL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Kill(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	vRPC.SetHealth(TargetSource,0)

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce matou #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FREEZE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Freeze(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local IsFrozen = FrozenPlayers[TargetSource] or false
	
	FrozenPlayers[TargetSource] = not IsFrozen
	
	TriggerClientEvent("ticket:Freeze",TargetSource,not IsFrozen)
	
	if not IsFrozen then
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce congelou #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	else
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce descongelou #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GOTO
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Goto(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	if vRP.DoesEntityExist(TargetSource) then
		local Ped = GetPlayerPed(TargetSource)
		local Coords = GetEntityCoords(Ped)
		
		if Coords then
			vRP.Teleport(Source,Coords.x,Coords.y,Coords.z)
			TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce foi teleportado para #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
		else
			TriggerClientEvent("ticket:Notify",Source,"Atencao","Nao foi possivel obter as coordenadas do jogador.","amarelo")
		end
	else
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao existe.","amarelo")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BRING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Bring(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	if vRP.DoesEntityExist(Source) and vRP.DoesEntityExist(TargetSource) then
		local Ped = GetPlayerPed(Source)
		local Coords = GetEntityCoords(Ped)

		if Coords then
			vRP.Teleport(TargetSource,Coords.x,Coords.y,Coords.z)
			TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce trouxe #%s - %s ate voce."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
		else
			TriggerClientEvent("ticket:Notify",Source,"Atencao","Nao foi possivel obter as coordenadas.","amarelo")
		end
	else
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao existe.","amarelo")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WAYPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Waypoint(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local TrackingKey = Source..":"..TargetPassport
	
	if WaypointTracking[TrackingKey] then
		WaypointTracking[TrackingKey] = nil
		TriggerClientEvent("ticket:StopWaypoint",Source)
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce parou de rastrear #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
		return true
	end

	WaypointTracking[TrackingKey] = {
		AdminSource = Source,
		TargetSource = TargetSource,
		TargetPassport = TargetPassport
	}

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce esta rastreando #%s - %s no mapa."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	
	local Coords = vRP.GetEntityCoords(TargetSource)
	if Coords then
		TriggerClientEvent("ticket:Waypoint",Source,Coords.x,Coords.y,true)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KILL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Kill(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	vRPC.SetHealth(TargetSource,0)

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce matou #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FREEZE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Freeze(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local IsFrozen = FrozenPlayers[TargetSource] or false
	
	FrozenPlayers[TargetSource] = not IsFrozen
	
	TriggerClientEvent("ticket:Freeze",TargetSource,not IsFrozen)
	
	if not IsFrozen then
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce congelou #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	else
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce descongelou #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GOTO
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Goto(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	if vRP.DoesEntityExist(TargetSource) then
		local Ped = GetPlayerPed(TargetSource)
		local Coords = GetEntityCoords(Ped)
		
		if Coords then
			vRP.Teleport(Source,Coords.x,Coords.y,Coords.z)
			TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce foi teleportado para #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
		else
			TriggerClientEvent("ticket:Notify",Source,"Atencao","Nao foi possivel obter as coordenadas do jogador.","amarelo")
		end
	else
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao existe.","amarelo")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BRING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Bring(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	if vRP.DoesEntityExist(Source) and vRP.DoesEntityExist(TargetSource) then
		local Ped = GetPlayerPed(Source)
		local Coords = GetEntityCoords(Ped)

		if Coords then
			vRP.Teleport(TargetSource,Coords.x,Coords.y,Coords.z)
			TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce trouxe #%s - %s ate voce."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
		else
			TriggerClientEvent("ticket:Notify",Source,"Atencao","Nao foi possivel obter as coordenadas.","amarelo")
		end
	else
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao existe.","amarelo")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WAYPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Waypoint(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local TrackingKey = Source..":"..TargetPassport
	
	if WaypointTracking[TrackingKey] then
		WaypointTracking[TrackingKey] = nil
		TriggerClientEvent("ticket:StopWaypoint",Source)
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce parou de rastrear #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
		return true
	end

	WaypointTracking[TrackingKey] = {
		AdminSource = Source,
		TargetSource = TargetSource,
		TargetPassport = TargetPassport
	}

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Voce esta rastreando #%s - %s no mapa."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	
	local Coords = vRP.GetEntityCoords(TargetSource)
	if Coords then
		TriggerClientEvent("ticket:Waypoint",Source,Coords.x,Coords.y,true)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(1000)

		for TrackingKey,Data in pairs(WaypointTracking) do
			local TargetSource = Data.TargetSource
			local AdminSource = Data.AdminSource
			local TargetPassport = Data.TargetPassport

			if not vRP.Passport(AdminSource) then
				WaypointTracking[TrackingKey] = nil
				goto continue
			end

			local CurrentSource = vRP.Source(TargetPassport)
			if not CurrentSource then
				WaypointTracking[TrackingKey] = nil
				TriggerClientEvent("ticket:StopWaypoint",AdminSource)
				TriggerClientEvent("ticket:Notify",AdminSource,"Atencao",("Jogador #%s - %s saiu do servidor."):format(TargetPassport,vRP.FullName(TargetPassport)),"amarelo")
				goto continue
			end

			Data.TargetSource = CurrentSource

			local Coords = vRP.GetEntityCoords(CurrentSource)
			if Coords then
				TriggerClientEvent("ticket:Waypoint",AdminSource,Coords.x,Coords.y,false)
			end

			::continue::
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDPRIVATEMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SendPrivateMessage(TargetPassport,Message)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)

	if TargetPassport <= 0 or Message == "" then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	TriggerClientEvent("Notify",TargetSource,"Administracao",("#%s: %s"):format(Passport,Message),"verde",5000)
	TriggerClientEvent("ticket:Notify",Source,"Administracao",("Mensagem %s enviada ao #%s - %s."):format(Message,TargetPassport,vRP.FullName(TargetPassport)),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDGROUP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AddGroup(TargetPassport,Group,Hierarchy)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	Hierarchy = parseInt(Hierarchy or 0)

	if TargetPassport <= 0 or Group == "" or Hierarchy < 0 then
		return false
	end

	local GroupInfo = Groups and Groups[Group]
	if not GroupInfo then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Grupo informado não existe.","vermelho")
		return false
	end

	local MaxHierarchy = (GroupInfo.Hierarchy and CountTable(GroupInfo.Hierarchy) or 1)
	if Hierarchy <= 0 or Hierarchy > MaxHierarchy then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Hierarquia inválida para este grupo.","vermelho")
		return false
	end

	if vRP.HasPermission(TargetPassport,Group) then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador já possui este grupo.","amarelo")
		return false
	end

	if Group == "Admin" and vRP.HasPermission(Passport,Group) < 2 then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Voce nao tem permissao para adicionar Admin.","vermelho")
		return false
	end

	vRP.SetPermission(TargetPassport,Group,Hierarchy)
	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Grupo %s adicionado ao #%s - %s."):format(Group,TargetPassport,vRP.FullName(TargetPassport)),"verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEGROUP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveGroup(TargetPassport,Group)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)

	if TargetPassport <= 0 or Group == "" then
		return false
	end

	if Group == "Admin" and vRP.HasPermission(Passport,Group) < 2 then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Voce nao tem permissao para remover Admin.","vermelho")
		return false
	end

	vRP.RemovePermission(TargetPassport,Group)
	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Grupo %s removido do #%s - %s."):format(Group,TargetPassport,vRP.FullName(TargetPassport)),"verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SCREENSHOT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Screenshot(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local Webhook = exports["discord"]:Webhook("Print")
	if Webhook and Webhook ~= "" then
		TriggerClientEvent("megazord:Screenshot",TargetSource,Webhook)
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Screenshot solicitado de #%s - %s."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")
	else
		TriggerClientEvent("ticket:Notify",Source,"Erro","Webhook nao configurado.","vermelho")
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARINVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ClearInventory(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	vRP.ClearInventory(TargetPassport,true)
	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Inventario de #%s - %s foi limpo."):format(TargetPassport,vRP.FullName(TargetPassport)),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETINVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetInventory(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		return {}
	end

	local Inventory = vRP.Inventory(TargetPassport)
	if not Inventory then
		return {}
	end
	local Payload = {}

	for Slot,v in pairs(Inventory) do
		if v.item and v.amount and v.amount > 0 and exports.vrp:ItemExist(v.item) then
			local Data = exports.vrp:ItemExist(v.item)
			Payload[#Payload + 1] = {
				Slot = Slot,
				Item = v.item,
				Name = exports.vrp:ItemName(v.item),
				Amount = v.amount,
				Index = Data and Data.Index or v.item
			}
		end
	end

	table.sort(Payload,function(a,b) return tonumber(a.Slot) < tonumber(b.Slot) end)

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GIVEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GiveItem(TargetPassport,Item,Amount)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	Amount = parseInt(Amount or 1)
	if TargetPassport <= 0 or Amount <= 0 or not Item or Item == "" then
		return false
	end

	if not exports.vrp:ItemExist(Item) then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Item nao existe.","vermelho")
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	vRP.GiveItem(TargetPassport,Item,Amount,false)
	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Adicionado %sx %s ao inventario de #%s - %s."):format(Amount,exports.vrp:ItemName(Item),TargetPassport,vRP.FullName(TargetPassport)),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCHITEMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SearchItems(Query)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	Query = tostring(Query or ""):lower():gsub("^%s+",""):gsub("%s+$","")
	if Query == "" then return {} end

	local AllItems = exports.vrp:ItemList()
	local Payload = {}
	local Count = 0

	for Index,Data in pairs(AllItems) do
		if Count >= 20 then break end
		local Name = exports.vrp:ItemName(Index) or Index
		if Index:lower():find(Query,1,true) or Name:lower():find(Query,1,true) then
			Payload[#Payload + 1] = {
				Id = Index,
				Name = Name,
				Image = Index
			}
			Count = Count + 1
		end
	end

	table.sort(Payload,function(a,b) return a.Name < b.Name end)

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETALLITEMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetAllItems()
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	local AllItems = exports.vrp:ItemList()
	local Payload = {}

	for Index,Data in pairs(AllItems) do
		local Name = exports.vrp:ItemName(Index) or Index
		local ItemData = exports.vrp:ItemExist(Index)
		Payload[#Payload + 1] = {
			Id = Index,
			Name = Name,
			Index = ItemData and ItemData.Index or Index
		}
	end

	table.sort(Payload,function(a,b) return a.Name < b.Name end)

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETVEHICLES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetVehicles(TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 then
		return {}
	end

	local UserVehicles = vRP.Query("vehicles/UserVehicles",{ Passport = TargetPassport })
	if not UserVehicles or #UserVehicles == 0 then
		return {}
	end

	local Payload = {}
	for _,v in ipairs(UserVehicles) do
		local Mode = "Permanente"
		if v.Rental and v.Rental > 0 then
			Mode = "Alugado"
		end
		Payload[#Payload + 1] = {
			Vehicle = v.Vehicle,
			Name = exports.vrp:VehicleName(v.Vehicle) or v.Vehicle,
			Plate = v.Plate or "",
			Mode = Mode,
			Rental = v.Rental or nil,
			Block = v.Block or false
		}
	end

	table.sort(Payload,function(a,b) return a.Name < b.Name end)

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETALLVEHICLES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetAllVehicles()
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	local AllVehicles = exports.vrp:VehicleList()
	local Payload = {}

	for Index,Data in pairs(AllVehicles) do
		local Name = exports.vrp:VehicleName(Index) or Index
		Payload[#Payload + 1] = {
			Id = Index,
			Name = Name
		}
	end

	table.sort(Payload,function(a,b) return a.Name < b.Name end)

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AddVehicle(TargetPassport,Model,Mode,Days)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	Days = parseInt(Days or 0)
	if TargetPassport <= 0 or not Model or Model == "" then
		return false
	end

	if not exports.vrp:VehicleExist(Model) then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Modelo de veículo inválido.","vermelho")
		return false
	end

	local VehicleExists = exports.oxmysql:single_async("SELECT id FROM vehicles WHERE Passport = ? AND Vehicle = ? LIMIT 1",{ TargetPassport,Model })
	if VehicleExists then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Este passaporte já possui este veículo.","amarelo")
		return false
	end

	local Tax = nil
	local Rental = 0
	local CurrentTimer = os.time()
	if Mode == "Mensal" then
		Rental = CurrentTimer + 2592000
		Tax = Rental
	elseif Mode == "Dias" then
		if Days <= 0 then
			TriggerClientEvent("ticket:Notify",Source,"Erro","Quantidade de dias inválida.","vermelho")
			return false
		end
		Rental = CurrentTimer + (86400 * Days)
		Tax = Rental
	elseif Mode == "Permanente" then
		Rental = 0
		Tax = CurrentTimer + 2592000
	end

	local Plate = vRP.GeneratePlate()
	local Weight = exports.vrp:VehicleWeight(Model)
	local Work = exports.vrp:VehicleMode(Model) == "Work"
	local Inserted = exports.oxmysql:insert_async("INSERT INTO vehicles (Passport,Vehicle,Plate,Weight,Work,Rental,Tax,Block) VALUES (?,?,?,?,?,?,?,?)",{ TargetPassport,Model,Plate,Weight,Work,Rental,Tax,false })
	if not Inserted then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Falha ao registrar o veículo.","vermelho")
		return false
	end

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Veículo %s entregue para o passaporte #%s - %s."):format(exports.vrp:VehicleName(Model),TargetPassport,vRP.FullName(TargetPassport)),"verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveVehicle(TargetPassport,Vehicle)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	if TargetPassport <= 0 or not Vehicle or Vehicle == "" then
		return false
	end

	vRP.RemSrvData("LsCustoms:"..TargetPassport..":"..Vehicle)
	vRP.RemSrvData("Trunkchest:"..TargetPassport..":"..Vehicle)
	vRP.Query("vehicles/removeVehicles",{ Passport = TargetPassport, Vehicle = Vehicle })

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Veículo %s removido de #%s - %s."):format(exports.vrp:VehicleName(Vehicle),TargetPassport,vRP.FullName(TargetPassport)),"verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveItem(TargetPassport,Item,Amount)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	Amount = parseInt(Amount or 1)
	if TargetPassport <= 0 or Amount <= 0 or not Item or Item == "" then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	local Removed = vRP.TakeItem(TargetPassport,Item,Amount,false)
	if not Removed then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Nao foi possivel remover o item.","vermelho")
		return false
	end

	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Removido %sx %s do inventario de #%s - %s."):format(Amount,exports.vrp:ItemName(Item),TargetPassport,vRP.FullName(TargetPassport)),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETPED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SetPed(TargetPassport,Model)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)

	if TargetPassport <= 0 or Model == "" then
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Jogador nao esta online.","amarelo")
		return false
	end

	if not vRPC.ModelExist(Source,Model) then
		TriggerClientEvent("ticket:Notify",Source,"Erro","Modelo invalido.","vermelho")
		return false
	end

	vRPC.Skin(TargetSource,Model)
	vRP.SkinCharacter(TargetPassport,Model)
	TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Ped de #%s - %s foi alterado para %s."):format(TargetPassport,vRP.FullName(TargetPassport),Model),"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Bank(TargetPassport,Amount,Type)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	Amount = parseInt(Amount or 0)

	if TargetPassport <= 0 or Amount <= 0 then
		return false
	end

	if Type ~= "Add" and Type ~= "Remove" then
		return false
	end

	local CurrentBank = vRP.GetBank(TargetPassport) or 0

	if Type == "Remove" and Amount > CurrentBank then
		TriggerClientEvent("ticket:Notify",Source,"Erro","O jogador nao possui saldo suficiente no banco.","vermelho")
		return false
	end

	if Type == "Add" then
		vRP.GiveBank(TargetPassport,Amount)
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Adicionado %s ao banco de #%s - %s."):format(Amount,TargetPassport,vRP.FullName(TargetPassport)),"verde")
	else
		vRP.RemoveBank(TargetPassport,Amount)
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Removido %s do banco de #%s - %s."):format(Amount,TargetPassport,vRP.FullName(TargetPassport)),"verde")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Gemstone(TargetPassport,Amount,Type)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TargetPassport = parseInt(TargetPassport)
	Amount = parseInt(Amount or 0)

	if TargetPassport <= 0 or Amount <= 0 then
		return false
	end

	if Type ~= "Add" and Type ~= "Remove" then
		return false
	end

	local Identity = vRP.Identity(TargetPassport)
	if not Identity then
		return false
	end

	local CurrentGemstone = vRP.UserGemstone(Identity.License) or 0

	if Type == "Remove" and Amount > CurrentGemstone then
		TriggerClientEvent("ticket:Notify",Source,"Erro","O jogador nao possui diamantes suficientes.","vermelho")
		return false
	end

	if Type == "Add" then
		vRP.UpgradeGemstone(TargetPassport,Amount,true)
		TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Adicionado %s diamantes ao #%s - %s."):format(Amount,TargetPassport,vRP.FullName(TargetPassport)),"verde")
	else
		local Identity = vRP.Identity(TargetPassport)
		if Identity then
			vRP.Query("accounts/RemoveGemstone",{ License = Identity.License, Gemstone = Amount })
			local TargetSource = vRP.Source(TargetPassport)
			if TargetSource then
				TriggerClientEvent("hud:RemoveGemstone",TargetSource,Amount)
			end
			TriggerClientEvent("ticket:Notify",Source,"Sucesso",("Removido %s diamantes do #%s - %s."):format(Amount,TargetPassport,vRP.FullName(TargetPassport)),"verde")
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVER INFO
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Server()
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	return {
		Weather = GlobalState.Weather or "CLEAR",
		Clock = { GlobalState.Hours or 0, GlobalState.Minutes or 0 }
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SET TIME
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SetTime(Data)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) or type(Data) ~= "table" then
		return false
	end

	local Hour = parseInt(Data.Hour)
	local Minute = parseInt(Data.Minute)
	if Hour < 0 or Hour > 23 or Minute < 0 or Minute > 59 then return false end

	GlobalState.Hours = Hour
	GlobalState.Minutes = Minute
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SET WEATHER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SetWeather(Data)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) or type(Data) ~= "table" then
		return false
	end

	local Weather = tostring(Data.Weather or ""):upper()
	if not WeatherWhitelist[Weather] then return false end

	GlobalState.Weather = Weather
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKETS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Tickets(AdminView)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport then return {} end
	if AdminView and not vRP.HasPermission(Passport,Config.Administrator) then return {} end

	local Result
	if AdminView then
		Result = exports.oxmysql:query_async("SELECT * FROM tickets_creative ORDER BY Status DESC, CreatedAt DESC",{})
	else
		Result = exports.oxmysql:query_async("SELECT * FROM tickets_creative WHERE Author = ? OR JSON_CONTAINS(IFNULL(Members,'[]'), JSON_OBJECT('Passport', ?),'$') ORDER BY Status DESC, CreatedAt DESC",{ Passport,Passport })
	end

	local Tickets = {}
	for _,Row in ipairs(Result or {}) do
		local AssumedPassport = parseInt(Row.Assumed)
		Tickets[#Tickets + 1] = {
			Id = Row.id,
			Subject = Row.Subject or "Sem assunto",
			Category = Row.Category or "Outros",
			Status = Row.Status,
			CreatedAt = Row.CreatedAt or 0,
			Assumed = AssumedPassport > 0 and ("#%s - %s"):format(AssumedPassport,vRP.FullName(AssumedPassport)) or nil
		}
	end

	return Tickets
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Ticket(TicketId)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport then return false end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row then return false end

	local Author = parseInt(Row.Author)
	local Decoded = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local Members = {}
	local Index = {}

	for _,Entry in ipairs(Decoded) do
		local Pass = parseInt(Entry.Passport or Entry)
		if Pass > 0 and not Index[Pass] then
			Members[#Members + 1] = { Passport = Pass, Participant = Entry.Participant ~= false }
			Index[Pass] = #Members
		end
	end

	if Author > 0 and not Index[Author] then
		Members[#Members + 1] = { Passport = Author, Participant = true }
		Index[Author] = #Members
	end

	if Passport ~= Author and not Index[Passport] and not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	local Messages = exports.oxmysql:query_async("SELECT * FROM tickets_creative_messages WHERE Ticket = ? ORDER BY CreatedAt DESC, id DESC LIMIT ?",{ TicketId,Config.MessagesLoad })
	local PayloadMessages = {}

	for i = #Messages,1,-1 do
		local Msg = Messages[i]
		local MsgPassport = parseInt(Msg.Author)
		local Staff = Msg.Staff == 1

		PayloadMessages[#PayloadMessages + 1] = {
			Id = Msg.id,
			Type = Msg.Type or "User",
			Staff = Staff,
			Message = Msg.Message or "",
			CreatedAt = Msg.CreatedAt or os.time(),
			Author = {
				Passport = MsgPassport,
				Staff = Staff,
				Name = Staff and vRP.FullName(MsgPassport) or nil
			}
		}
	end

	local MembersPayload = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport)
		local Name = vRP.FullName(Pass)
		MembersPayload[#MembersPayload + 1] = {
			Passport = tostring(Pass),
			Name = Name and Name ~= "" and Name or ("Usuario #%s"):format(Pass),
			Participant = Entry.Participant and true or false
		}
	end

	local Identity = vRP.Identity(Author)
	local Account = Identity and vRP.Account(Identity.License) or {}
	local AssumedPassport = parseInt(Row.Assumed)

	return {
		Subject = Row.Subject or "Sem assunto",
		Status = Row.Status,
		Category = Row.Category or "Outros",
		CreatedAt = Row.CreatedAt or 0,
		ClosedAt = Row.ClosedAt or 0,
		Assumed = AssumedPassport > 0 and ("#%s - %s"):format(AssumedPassport,vRP.FullName(AssumedPassport)) or nil,
		Author = {
			Passport = Author,
			Name = vRP.FullName(Author),
			Discord = Account.Discord or "0",
			License = Identity and Identity.License or "0"
		},
		Members = MembersPayload,
		Messages = PayloadMessages
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOADMESSAGES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.LoadMessages(TicketId,Before)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport then return {} end

	TicketId = parseInt(TicketId)
	Before = parseInt(Before)
	if TicketId <= 0 then return {} end
	if Before <= 0 then Before = os.time() end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row then return {} end

	local Author = parseInt(Row.Author)
	local Decoded = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local Index = {}

	for _,Entry in ipairs(Decoded) do
		local Pass = parseInt(Entry.Passport or Entry)
		if Pass > 0 then Index[Pass] = true end
	end

	if Author > 0 then Index[Author] = true end

	if not Index[Passport] and not vRP.HasPermission(Passport,Config.Administrator) then
		return {}
	end

	local Messages = exports.oxmysql:query_async("SELECT * FROM tickets_creative_messages WHERE Ticket = ? AND CreatedAt < ? ORDER BY CreatedAt DESC, id DESC LIMIT ?",{ TicketId,Before,Config.MessagesLoad })
	local Payload = {}

	for i = #Messages,1,-1 do
		local Msg = Messages[i]
		local MsgPassport = parseInt(Msg.Author)
		local Staff = Msg.Staff == 1

		Payload[#Payload + 1] = {
			Id = Msg.id,
			Type = Msg.Type or "User",
			Staff = Staff,
			Message = Msg.Message or "",
			CreatedAt = Msg.CreatedAt or os.time(),
			Author = {
				Passport = MsgPassport,
				Staff = Staff,
				Name = Staff and vRP.FullName(MsgPassport) or nil
			}
		}
	end

	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SendMessage(TicketId,Message)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport then return false end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	Message = tostring(Message or ""):gsub("^%s+",""):gsub("%s+$","")
	if #Message > 2000 then Message = Message:sub(1,2000) end
	if Message == "" then return false end

	local Now = os.time()
	if Cooldown.Message[Passport] and Cooldown.Message[Passport] > Now then
		TriggerClientEvent("ticket:Notify",Source,"Atencao",("Aguarde %ss para enviar uma nova mensagem."):format(Cooldown.Message[Passport] - Now),"amarelo")
		return false
	end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row then return false end

	local Author = parseInt(Row.Author)
	local Decoded = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local Members = {}
	local Index = {}

	for _,Entry in ipairs(Decoded) do
		local Pass = parseInt(Entry.Passport or Entry)
		if Pass > 0 and not Index[Pass] then
			Members[#Members + 1] = { Passport = Pass, Participant = Entry.Participant ~= false }
			Index[Pass] = #Members
		end
	end

	if Author > 0 and not Index[Author] then
		Members[#Members + 1] = { Passport = Author, Participant = true }
		Index[Author] = #Members
	end

	if Passport ~= Author and not Index[Passport] and not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	if not Index[Passport] then
		Members[#Members + 1] = { Passport = Passport, Participant = true }
		exports.oxmysql:update_async("UPDATE tickets_creative SET Members = ? WHERE id = ?",{ json.encode(Members),TicketId })
		Index[Passport] = #Members
	end

	local IsStaff = vRP.HasPermission(Passport,Config.Administrator)
	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"User",Passport,IsStaff and 1 or 0,Message,Timestamp })
	if not MessageId then return false end

	Cooldown.Message[Passport] = Now + Config.Cooldown

	local Payload = {
		Id = MessageId,
		Type = "User",
		Staff = IsStaff,
		Message = Message,
		CreatedAt = Timestamp,
		Author = {
			Passport = Passport,
			Staff = IsStaff,
			Name = IsStaff and vRP.FullName(Passport) or nil
		}
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Src = vRP.Source(Entry.Passport)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Message = Payload })
	end

	if IsStaff and Author > 0 and Author ~= Passport then
		local AuthorSource = vRP.Source(Author)
		if AuthorSource then
			TriggerClientEvent("ticket:Notify",AuthorSource,"Atendimento",("#%s - %s respondeu o atendimento #%s."):format(Passport,vRP.FullName(Passport),TicketId),"amarelo",5000)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CloseTicket(TicketId,Message)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status then return false end

	local Members = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local CloseMessage = tostring(Message or ("Atendimento encerrado por #%s - %s."):format(Passport,vRP.FullName(Passport)))
	if #CloseMessage > 4000 then CloseMessage = CloseMessage:sub(1,4000) end

	local Timestamp = os.time()
	exports.oxmysql:update_async("UPDATE tickets_creative SET Status = 0, ClosedAt = ?, Assumed = ? WHERE id = ?",{ Timestamp,Row.Assumed,TicketId })

	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,CloseMessage,Timestamp })

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = CloseMessage,
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport or Entry)
		local Src = vRP.Source(Pass)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Status = false, ClosedAt = Timestamp, Message = PayloadMessage })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REOPENTICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ReopenTicket(TicketId)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status then return false end

	local Members = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	exports.oxmysql:update_async("UPDATE tickets_creative SET Status = 1, ClosedAt = NULL, Assumed = NULL WHERE id = ?",{ TicketId })

	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,("#%s - %s reabriu o atendimento."):format(Passport,vRP.FullName(Passport)),Timestamp })

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = ("#%s - %s reabriu o atendimento."):format(Passport,vRP.FullName(Passport)),
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport or Entry)
		local Src = vRP.Source(Pass)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Status = true, ClosedAt = 0, Assumed = nil, Message = PayloadMessage })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSUMETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssumeTicket(TicketId)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status or Row.Assumed then return false end

	local Author = parseInt(Row.Author)
	local Decoded = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local Members = {}
	local Index = {}

	for _,Entry in ipairs(Decoded) do
		local Pass = parseInt(Entry.Passport or Entry)
		if Pass > 0 and not Index[Pass] then
			Members[#Members + 1] = { Passport = Pass, Participant = Entry.Participant ~= false }
			Index[Pass] = #Members
		end
	end

	if Author > 0 and not Index[Author] then
		Members[#Members + 1] = { Passport = Author, Participant = true }
		Index[Author] = #Members
	end

	if not Index[Passport] then
		Members[#Members + 1] = { Passport = Passport, Participant = true }
		Index[Passport] = #Members
	end

	exports.oxmysql:update_async("UPDATE tickets_creative SET Assumed = ?, Members = ? WHERE id = ?",{ Passport,json.encode(Members),TicketId })

	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,("#%s - %s assumiu o atendimento."):format(Passport,vRP.FullName(Passport)),Timestamp })

	local MembersPayload = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport)
		local Name = vRP.FullName(Pass)
		MembersPayload[#MembersPayload + 1] = {
			Passport = tostring(Pass),
			Name = Name and Name ~= "" and Name or ("Usuario #%s"):format(Pass),
			Participant = Entry.Participant and true or false
		}
	end

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = ("#%s - %s assumiu o atendimento."):format(Passport,vRP.FullName(Passport)),
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Src = vRP.Source(Entry.Passport)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Assumed = ("#%s - %s"):format(Passport,vRP.FullName(Passport)), Members = MembersPayload, Message = PayloadMessage })
	end

	if Author > 0 and Author ~= Passport then
		local AuthorSource = vRP.Source(Author)
		if AuthorSource then
			TriggerClientEvent("ticket:Notify",AuthorSource,"Atendimento",("#%s - %s assumiu o atendimento #%s."):format(Passport,vRP.FullName(Passport),TicketId),"amarelo")
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHANGESUBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ChangeSubject(TicketId,Subject)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	Subject = tostring(Subject or ""):gsub("^%s+",""):gsub("%s+$","")
	if #Subject > 255 then Subject = Subject:sub(1,255) end
	if Subject == "" then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status then return false end

	local Members = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	exports.oxmysql:update_async("UPDATE tickets_creative SET Subject = ? WHERE id = ?",{ Subject,TicketId })

	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,("#%s - %s alterou o assunto para \"%s\"."):format(Passport,vRP.FullName(Passport),Subject),Timestamp })

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = ("#%s - %s alterou o assunto para \"%s\"."):format(Passport,vRP.FullName(Passport),Subject),
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport or Entry)
		local Src = vRP.Source(Pass)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Subject = Subject, Message = PayloadMessage })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHANGECATEGORY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ChangeCategory(TicketId,Category)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	if TicketId <= 0 then return false end

	Category = tostring(Category or ""):gsub("^%s+",""):gsub("%s+$","")
	if #Category > 100 then Category = Category:sub(1,100) end

	local ValidCategory = false
	for _,Value in ipairs(Config.Categories or {}) do
		if Value == Category then
			ValidCategory = true
			break
		end
	end

	if not ValidCategory then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status then return false end

	local Members = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	exports.oxmysql:update_async("UPDATE tickets_creative SET Category = ? WHERE id = ?",{ Category,TicketId })

	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,("#%s - %s alterou a categoria para \"%s\"."):format(Passport,vRP.FullName(Passport),Category),Timestamp })

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = ("#%s - %s alterou a categoria para \"%s\"."):format(Passport,vRP.FullName(Passport),Category),
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport or Entry)
		local Src = vRP.Source(Pass)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Category = Category, Message = PayloadMessage })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDPARTICIPANT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AddParticipant(TicketId,TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	TargetPassport = parseInt(TargetPassport)
	if TicketId <= 0 or TargetPassport <= 0 then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status then return false end

	local Decoded = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local Members = {}
	local Index = {}

	for _,Entry in ipairs(Decoded) do
		local Pass = parseInt(Entry.Passport or Entry)
		if Pass > 0 and not Index[Pass] then
			Members[#Members + 1] = { Passport = Pass, Participant = Entry.Participant ~= false }
			Index[Pass] = #Members
		end
	end

	if Index[TargetPassport] then
		TriggerClientEvent("ticket:Notify",Source,"Atendimento","O jogador ja esta no atendimento.","amarelo")
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("ticket:Notify",Source,"Atendimento","Jogador nao existe ou esta offline.","amarelo")
		return false
	end

	Members[#Members + 1] = { Passport = TargetPassport, Participant = true }
	exports.oxmysql:update_async("UPDATE tickets_creative SET Members = ? WHERE id = ?",{ json.encode(Members),TicketId })

	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,("#%s - %s adicionou #%s - %s ao atendimento."):format(Passport,vRP.FullName(Passport),TargetPassport,vRP.FullName(TargetPassport)),Timestamp })

	local MembersPayload = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport)
		local Name = vRP.FullName(Pass)
		MembersPayload[#MembersPayload + 1] = {
			Passport = tostring(Pass),
			Name = Name and Name ~= "" and Name or ("Usuario #%s"):format(Pass),
			Participant = Entry.Participant and true or false
		}
	end

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = ("#%s - %s adicionou #%s - %s ao atendimento."):format(Passport,vRP.FullName(Passport),TargetPassport,vRP.FullName(TargetPassport)),
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Src = vRP.Source(Entry.Passport)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Members = MembersPayload, Message = PayloadMessage })
	end

	TriggerClientEvent("ticket:Notify",TargetSource,"Atendimento","Voce foi adicionado ao atendimento #"..TicketId..".","amarelo")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEPARTICIPANT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveParticipant(TicketId,TargetPassport)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport or not vRP.HasPermission(Passport,Config.Administrator) then
		return false
	end

	TicketId = parseInt(TicketId)
	TargetPassport = parseInt(TargetPassport)
	if TicketId <= 0 or TargetPassport <= 0 then return false end

	local Row = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ TicketId })
	if not Row or not Row.Status or TargetPassport == parseInt(Row.Author) then return false end

	local Decoded = Row.Members and Row.Members ~= "" and json.decode(Row.Members) or {}
	local Members = {}
	local Index = {}

	for _,Entry in ipairs(Decoded) do
		local Pass = parseInt(Entry.Passport or Entry)
		if Pass > 0 and not Index[Pass] then
			Members[#Members + 1] = { Passport = Pass, Participant = Entry.Participant ~= false }
			Index[Pass] = #Members
		end
	end

	if not Index[TargetPassport] then return false end

	table.remove(Members,Index[TargetPassport])
	exports.oxmysql:update_async("UPDATE tickets_creative SET Members = ? WHERE id = ?",{ json.encode(Members),TicketId })

	local Timestamp = os.time()
	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"System",Passport,1,("#%s - %s removeu #%s - %s do atendimento."):format(Passport,vRP.FullName(Passport),TargetPassport,vRP.FullName(TargetPassport)),Timestamp })

	local MembersPayload = {}
	for _,Entry in ipairs(Members) do
		local Pass = parseInt(Entry.Passport)
		local Name = vRP.FullName(Pass)
		MembersPayload[#MembersPayload + 1] = {
			Passport = tostring(Pass),
			Name = Name and Name ~= "" and Name or ("Usuario #%s"):format(Pass),
			Participant = Entry.Participant and true or false
		}
	end

	local PayloadMessage = {
		Id = MessageId,
		Type = "System",
		Staff = true,
		Message = ("#%s - %s removeu #%s - %s do atendimento."):format(Passport,vRP.FullName(Passport),TargetPassport,vRP.FullName(TargetPassport)),
		CreatedAt = Timestamp,
		Author = { Passport = Passport, Staff = true, Name = vRP.FullName(Passport) }
	}

	local Receivers = {}
	for _,Entry in ipairs(Members) do
		local Src = vRP.Source(Entry.Passport)
		if Src then Receivers[Src] = true end
	end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then Receivers[StaffSource] = true end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{ Id = TicketId, Members = MembersPayload, Message = PayloadMessage })
	end

	local TargetSource = vRP.Source(TargetPassport)
	if TargetSource then
		TriggerClientEvent("ticket:Notify",TargetSource,"Atendimento","Voce foi removido do atendimento #"..TicketId..".","amarelo")
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateTicket(Subject,Category,Message)
	local Source = source
	local Passport = vRP.Passport(Source)
	if not Passport then return false end

	local Now = os.time()
	if Cooldown.Ticket[Passport] and Cooldown.Ticket[Passport] > Now then
		TriggerClientEvent("ticket:Notify",Source,"Atencao",("Voce so podera abrir outro atendimento em %ss."):format(Cooldown.Ticket[Passport] - Now),"amarelo")
		return false
	end

	Subject = tostring(Subject or ""):gsub("^%s+",""):gsub("%s+$","")
	Message = tostring(Message or ""):gsub("^%s+",""):gsub("%s+$","")
	Category = tostring(Category or ""):gsub("^%s+",""):gsub("%s+$","")

	if #Subject > 255 then Subject = Subject:sub(1,255) end
	if #Message > 2000 then Message = Message:sub(1,2000) end
	if #Category > 100 then Category = Category:sub(1,100) end

	if Subject == "" or Message == "" then return false end

	local ValidCategory = false
	for _,Value in ipairs(Config.Categories or {}) do
		if Value == Category then
			ValidCategory = true
			break
		end
	end

	if not ValidCategory then return false end

	local OpenInCategory = exports.oxmysql:scalar_async("SELECT COUNT(id) FROM tickets_creative WHERE Author = ? AND Category = ? AND Status = 1",{ Passport,Category })
	if Config.MaxTicketCategory > 0 and OpenInCategory and OpenInCategory >= Config.MaxTicketCategory then
		TriggerClientEvent("ticket:Notify",Source,"Atencao","Voce ja possui um atendimento aberto nesta categoria.","amarelo")
		return false
	end

	local CreatedAt = os.time()
	local Members = {{ Passport = Passport, Participant = true }}

	local TicketId = exports.oxmysql:insert_async("INSERT INTO tickets_creative (Subject,Category,Assumed,Status,CreatedAt,Author,Members) VALUES (?,?,?,?,?,?,?)",{ Subject,Category,nil,1,CreatedAt,Passport,json.encode(Members) })
	if not TicketId then return false end

	local MessageId = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ TicketId,"User",Passport,0,Message,CreatedAt })

	Cooldown.Ticket[Passport] = Now + Config.CreateInterval

	local PayloadMessage = {
		Id = MessageId,
		Type = "User",
		Staff = false,
		Message = Message,
		CreatedAt = CreatedAt,
		Author = { Passport = Passport, Staff = false }
	}

	local Receivers = {}
	local MemberSource = vRP.Source(Passport)
	if MemberSource then Receivers[MemberSource] = true end

	if Config.Administrator ~= "" then
		for _,StaffSource in pairs(vRP.NumPermission(Config.Administrator)) do
			if StaffSource then
				Receivers[StaffSource] = true
				TriggerClientEvent("ticket:Notify",StaffSource,"Atendimento","#"..TicketId.." aberto por #"..Passport..".","amarelo")
			end
		end
	end

	for Src in pairs(Receivers) do
		TriggerClientEvent("ticket:Update",Src,{
			Id = TicketId,
			Subject = Subject,
			Category = Category,
			Status = true,
			CreatedAt = CreatedAt,
			Members = {{
				Passport = tostring(Passport),
				Name = vRP.FullName(Passport),
				Participant = true
			}},
			Message = PayloadMessage
		})
	end

	return TicketId
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,Source)
	for TrackingKey,Data in pairs(WaypointTracking) do
		if Data.AdminSource == Source then
			WaypointTracking[TrackingKey] = nil
		end
	end

	if Spectate[Passport] then
		local Ped = GetPlayerPed(Spectate[Passport])
		if DoesEntityExist(Ped) then
			SetEntityDistanceCullingRadius(Ped,0.0)
		end
		Spectate[Passport] = nil
	end

	if FrozenPlayers[Source] then
		FrozenPlayers[Source] = nil
	end
end)
