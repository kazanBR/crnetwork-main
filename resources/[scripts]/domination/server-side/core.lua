-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("domination",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TUNNEL
-----------------------------------------------------------------------------------------------------------------------------------------
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Scoreboard = {}
local ActivePlayers = {}
local PermissionPlayers = {}
local CurrentLocation = false
------------------------------------------------------------------------------------------------------------------------------------------
-- SYNCSCOREBOARD
------------------------------------------------------------------------------------------------------------------------------------------
function SyncScoreboard()
	for _,v in pairs(ActivePlayers) do
		async(function()
			TriggerClientEvent("domination:Update",v.Source,Scoreboard,DominationGoal)
		end)
	end
end
------------------------------------------------------------------------------------------------------------------------------------------
-- SYNCFINISH
------------------------------------------------------------------------------------------------------------------------------------------
function SyncFinish(Message,Color)
	for _,v in pairs(ActivePlayers) do
		async(function()
			TriggerClientEvent("Notify",v.Source,"Dominação",Message,Color,10000)
		end)
	end
end
------------------------------------------------------------------------------------------------------------------------------------------
-- ENDDOMINATION
------------------------------------------------------------------------------------------------------------------------------------------
function EndDomination(Winner)
	if Winner then
		SyncFinish("<b>"..(Groups[Winner].Name or Winner).."</b> atingiu <b>"..DominationGoal.." Pontos</b> e ganhou.","verde")
		exports.discord:Embed("Domination","**[LOCAL]:** "..CurrentLocation.."\n**[GRUPO]:** "..Winner)
		TriggerClientEvent("domination:Finish",-1,Winner)

		local Permission = Locations[CurrentLocation] and Locations[CurrentLocation].Permission
		if Permission then
			local Consult = exports.oxmysql:query_async("SELECT * FROM chests WHERE Permission LIKE ?",{ Permission.."%" })
			for _,v in pairs(Consult) do
				if v.Permission and SplitOne(v.Permission) == Permission and vRP.GetSrvData("Chest:"..v.Name,true) then
					vRP.RemSrvData("Chest:"..v.Name)
				end

				if v.id then
					exports.oxmysql:query_async("DELETE FROM chests WHERE id = ?",{ v.id })
				end
			end

			local Data = vRP.GetSrvData("Permissions:"..Permission,true)
			if Data then
				for OtherPassport in pairs(Data) do
					local OtherSource = vRP.Source(OtherPassport)
					if OtherSource then
						vRP.ServiceLeave(OtherSource,OtherPassport,Permission,true)
					end
				end

				vRP.RemSrvData("Permissions:"..Permission)
			end

			exports.oxmysql:query_async("DELETE FROM permissions WHERE Permission = ?",{ Permission })

			local Data = vRP.DataGroups(Winner)
			for Passport,Level in pairs(Data) do
				local NewLevel = (Level <= 2) and Level or 3
				vRP.SetPermission(Passport,Permission,NewLevel)
			end
		end
	else
		exports.discord:Embed("Domination","**[LOCAL]:** "..CurrentLocation.."\n**[ADMIN]:** Cancelado")
		SyncFinish("Um membro da administração finalizou.","amarelo")
		TriggerClientEvent("domination:Finish",-1)
	end

	CurrentLocation = false
	ActivePlayers = {}
	Scoreboard = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROGRESS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Progress(Mode)
	if not CurrentLocation then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)

	if not Passport or not CurrentLocation then
		return false
	end

	if Mode == "Enter" then
		if ActivePlayers[Passport] then
			return false
		end

		local Permission = vRP.UserDomination(Passport)
		if not Permission then
			return false
		end

		PermissionPlayers[Permission] = (PermissionPlayers[Permission] or 0) + 1
		ActivePlayers[Passport] = { Source = source, Permission = Permission, Update = os.time(), Name = vRP.FullName(Passport) }

		if not Scoreboard[Permission] then
			Scoreboard[Permission] = 0
		end

		SyncScoreboard()
	elseif Mode == "Exit" then
		local Active = ActivePlayers[Passport]
		if not Active then
			return false
		end

		local Permission = Active.Permission
		if Permission then
			PermissionPlayers[Permission] = math.max(0,(PermissionPlayers[Permission] or 0) - 1)
		end

		ActivePlayers[Passport] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PONTUATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Pontuation(Location)
	if not CurrentLocation then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	local Active = ActivePlayers[Passport]

	if not Passport or not Active or not Active.Update or Active.Update > os.time() or Location ~= CurrentLocation then
		return false
	end

	local CurrentTimer = os.time()
	local Permission = Active.Permission
	local PlayerCount = PermissionPlayers[Permission] or 1
	local Multiplier = 1.0 + math.min(MaxPresenceMultiplier - 1.0,(PlayerCount - 1) * PresenceMultiplier)
	local Reward = math.max(1,math.floor(1 * Multiplier))

	for Parent in pairs(Scoreboard) do
		if Parent == Permission then
			Scoreboard[Parent] = (Scoreboard[Parent] or 0) + Reward
		else
			Scoreboard[Parent] = math.max(0,(Scoreboard[Parent] or 0) - 1)
		end
	end

	ActivePlayers[Passport].Update = CurrentTimer + PointSeconds

	if Scoreboard[Permission] >= DominationGoal then
		EndDomination(Permission)
	else
		SyncScoreboard()
	end
end
------------------------------------------------------------------------------------------------------------------------------------------
-- COMMAND
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand(Command,function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasPermission(Passport,Permission) then
		return false
	end

	local Options = { "Finalizar" }
	for Name in pairs(Locations) do
		table.insert(Options,Name)
	end

	local Keyboard = vKEYBOARD.Instagram(source,Options)
	if not Keyboard then
		return false
	end

	if Keyboard[1] == "Finalizar" then
		EndDomination()
		TriggerClientEvent("Notify",source,"Atenção","Dominação cancelada.","amarelo",5000)
	else
		Scoreboard = {}
		ActivePlayers = {}
		PermissionPlayers = {}
		CurrentLocation = Keyboard[1]

		TriggerClientEvent("domination:Start",-1,CurrentLocation)
		TriggerClientEvent("Notify",source,"Dominação Iniciada!","A disputa pelo território <b>"..Locations[CurrentLocation].Name.."</b> começou!<br>Reúna seu grupo e lute pelo controle da área.<br>A primeira equipe a atingir <b>"..DominationGoal.." pontos</b> será a vencedora!","verde",15000)
		exports.discord:Embed("Domination","**[LOCAL]:** "..CurrentLocation.."\n**[ADMIN]:** "..Passport.."\n**[MODO]:** Iniciar")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOMINATION:KILLFEED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("domination:KillFeed")
AddEventHandler("domination:KillFeed",function(OtherSource)
	local source = source
	local Passport = vRP.Passport(source)
	local OtherPassport = vRP.Passport(OtherSource)
	if not (Passport and OtherPassport and Passport ~= OtherPassport) then
		return false
	end

	local VictimActive = ActivePlayers[Passport]
	local AttackerActive = ActivePlayers[OtherPassport]
	if not (AttackerActive and VictimActive) then
		return false
	end

	ActivePlayers[Passport] = nil

	local VictimName = VictimActive.Name
	local AttackerName = AttackerActive.Name

	for _,v in pairs(ActivePlayers) do
		async(function()
			TriggerClientEvent("domination:KillFeed",v.Source,AttackerName,VictimName)
		end)
	end

	local Permission = AttackerActive.Permission
	Scoreboard[Permission] = (Scoreboard[Permission] or 0) + PointsKillFeed

	if Scoreboard[Permission] >= DominationGoal then
		EndDomination(Permission)
	else
		SyncScoreboard()
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	if CurrentLocation then
		TriggerClientEvent("domination:Start",source,CurrentLocation)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	local Active = ActivePlayers[Passport]
	if not Active then
		return false
	end

	local Permission = Active.Permission
	if Permission then
		PermissionPlayers[Permission] = math.max(0,(PermissionPlayers[Permission] or 0) - 1)
	end

	ActivePlayers[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
function ThreadTick()
	local Week = os.date("%A")
	local Hour = os.date("%H")
	local Minute = os.date("%M")

	for Location,v in pairs(Locations) do
		if not CurrentLocation and Week == v.Execute.Week and Hour == string.format("%02d",v.Execute.Hour) and Minute == string.format("%02d",v.Execute.Minute) then
			Scoreboard = {}
			ActivePlayers = {}
			PermissionPlayers = {}
			CurrentLocation = Location

			TriggerClientEvent("domination:Start",-1,CurrentLocation)
			exports.discord:Embed("Domination","**[LOCAL]:** "..CurrentLocation.."\n**[MODO]:** Automático")
			TriggerClientEvent("Notify",-1,"Dominação Iniciada!","A disputa pelo território <b>"..v.Name.."</b> começou!<br>Reúna seu grupo e lute pelo controle da área.<br>A primeira equipe a atingir <b>"..DominationGoal.." pontos</b> será a vencedora!","verde",15000)
		end
	end

	SetTimeout(30000,ThreadTick)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
ThreadTick()