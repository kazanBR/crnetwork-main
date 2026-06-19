local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")

local Server = {}
Tunnel.bindInterface(GetCurrentResourceName(),Server)

local tuneKey = "athlon-app-lb:Tunes"
local tunes = vRP.GetSrvData(tuneKey,true)

local function notify(source,kind,message)
	TriggerClientEvent("Notify",source,kind or "verde",message,5000)
end

RegisterNetEvent("athlon:server:getTune",function(key)
	local source = source
	if type(key) ~= "string" then
		return
	end

	TriggerClientEvent("athlon:client:receiveTune",source,tunes[key] or {})
end)

RegisterNetEvent("athlon:server:saveTune",function(key,tuneData)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or type(key) ~= "string" or type(tuneData) ~= "table" then
		return
	end

	if Config and Config.RequiredItem and Config.RequiredItem ~= "" and not vRP.ConsultItem(Passport,Config.RequiredItem,1) then
		notify(source,"vermelho","Item necessario nao encontrado.")
		return
	end

	tunes[key] = tuneData
	vRP.SetSrvData(tuneKey,tunes,true)
	notify(source,"verde","Ajuste salvo.")
end)

RegisterNetEvent("athlon:server:triggerFoguinho",function(netVeh,intensity)
	TriggerClientEvent("athlon:client:spawnFoguinho",-1,netVeh,tonumber(intensity) or 1.0)
end)
