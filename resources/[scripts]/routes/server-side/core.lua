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
Tunnel.bindInterface("routes",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Players = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permission(Service)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport then
		return false
	end

	local ServiceConfig = Config[Service]
	if not ServiceConfig then
		return false
	end

	if not ServiceConfig.Permission then
		return true
	end

	return vRP.HasService(Passport,ServiceConfig.Permission)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- START
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Start(Table,Service)
	local source = source
	local Passport = vRP.Passport(source)
	local ServiceConfig = Config[Service]

	if not Passport or not ServiceConfig or Players[Passport] then
		return false
	end

	local PlayerData = {
		List = {},
		Price = 0,
		Service = Service,
		Mode = ServiceConfig.Mode
	}

	for _,Number in pairs(Table) do
		local Item = ServiceConfig.List[Number]
		if Item then
			table.insert(PlayerData.List,Item)
			PlayerData.Price = PlayerData.Price + (Item.Price or 0)
		end
	end

	Players[Passport] = PlayerData

	local Mode = PlayerData.Mode
	if Mode == "Never" or Mode == "Always" then
		return true
	elseif Mode == "Init" then
		if vRP.PaymentFull(Passport,PlayerData.Price) then
			return true
		else
			Players[Passport] = nil

			return false
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Finish()
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport or not Players[Passport] then
		return false
	end

	Players[Passport] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELIVER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Deliver()
	local source = source
	local Passport = vRP.Passport(source)
	local PlayerData = Players[Passport]

	if not Passport or not PlayerData then
		return false
	end

	local Mode = PlayerData.Mode
	local Service = PlayerData.Service
	local ServiceConfig = Config[Service]

	if Mode ~= "Never" and Mode ~= "Init" then
		if Mode == "Always" and not vRP.PaymentFull(Passport,PlayerData.Price) then
			return false
		end
	end

	local Result = RandPercentage(PlayerData.List)
	if not Result then
		return false
	end

	if not vRP.MaxItens(Passport,Result.Item,Result.Valuation) and vRP.CheckWeight(Passport,Result.Item,Result.Valuation) then
		vRP.GenerateItem(Passport,Result.Item,Result.Valuation,true)
	else
		TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
		exports.inventory:Drops(Passport,source,Result.Item,Result.Valuation)
	end

	if ServiceConfig.Experience then
		vRP.PutExperience(Passport,ServiceConfig.Experience.Name,ServiceConfig.Experience.Amount)
	end

	if ServiceConfig.Battlepass then
		vRP.BattlepassPoints(Passport,ServiceConfig.Battlepass)
	end

	if ServiceConfig.Wanted then
		TriggerEvent("Wanted",source,Passport,ServiceConfig.Wanted)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Players[Passport] then
		Players[Passport] = nil
	end
end)