-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("chat",Creative)
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHAT:SERVERMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("chat:ServerMessage")
AddEventHandler("chat:ServerMessage",function(Mode,Message)
	if Mode == "Importante" then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Name = vRP.FullName(Passport)
	local Messenger = (Message or ""):gsub("[<>]","")

	if Groups[Mode] then
		if vRP.GetHealth(source) > 100 and vRP.HasService(Passport,Mode) then
			local Service = vRP.NumPermission(Mode)
			for _,TargetSource in pairs(Service) do
				async(function()
					TriggerClientEvent("chat:ClientMessage",TargetSource,Name,Messenger,Mode)
				end)
			end
		end

		return false
	end

	if Mode == "OOC" then
		TriggerClientEvent("chat:ClientMessage",source,Name,Messenger,Mode)

		local NearbyPlayers = vRPC.ClosestPeds(source,10)
		for _,TargetSource in pairs(NearbyPlayers) do
			async(function()
				TriggerClientEvent("chat:ClientMessage",TargetSource,Name,Messenger,Mode)
			end)
		end

		return false
	end

	if Mode == "Ação" then
		TriggerClientEvent("chat:ClientMessage",-1,"Anônimo",Messenger,Mode)
		exports.discord:Embed("Chat","**[SOURCE]:** "..source.."\n**[PASSAPORTE]:** "..Passport.."\n**[MENSAGEM]:** "..Messenger..".")

		return false
	end

	TriggerClientEvent("chat:ClientMessage",-1,Name,Messenger,Mode)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ME
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("me",function(source,Message,History)
	local Passport = vRP.Passport(source)
	if Passport and Message[1] then
		local Name = vRP.FullName(Passport)
		local Message = string.sub(History:sub(4),1,100)

		for _,v in pairs(vRPC.Players(source)) do
			async(function()
				TriggerClientEvent("chat:me_new",v,source,Name,Message,10)
			end)
		end
	end
end)