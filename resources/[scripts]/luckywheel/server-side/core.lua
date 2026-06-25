-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Progress = os.time()
-----------------------------------------------------------------------------------------------------------------------------------------
-- LUCKYWHEEL:TARGET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("luckywheel:Target")
AddEventHandler("luckywheel:Target",function()
	local source = source
	local CurrentTimer = os.time()
	local Passport = vRP.Passport(source)

	if not Passport or Active[Passport] then
		return false
	end

	if CurrentTimer < Progress then
		TriggerClientEvent("Notify",source,"Atenção","Aguarde <b>"..(Progress - CurrentTimer).."</b> segundos.","amarelo",5000)
		return false
	end

	if not vRP.TakeItem(Passport,ItemNecessary,AmountNecessary) then
		TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>"..Dotted(AmountNecessary).."x "..exports.vrp:ItemName(ItemNecessary).."</b>.","amarelo",5000)
		return false
	end

	Active[Passport] = true
	Progress = CurrentTimer + 15
	local Result = GetWheelRandom(Rewards)

	exports.discord:Embed("Luckywheel","**[PASSAPORTE]:** "..Passport.."\n**[RESULTADO]:** "..Result.."\n**[ITEM]:** "..Dotted(Rewards[Result].Amount).."x "..exports.vrp:ItemName(Rewards[Result].Item))

	for _,OtherSource in pairs(vRPC.Players(source)) do
		async(function()
			TriggerClientEvent("luckywheel:Start",OtherSource,Result)
		end)
	end

	SetTimeout(10000,function()
		if Rewards[Result] then
			vRP.GenerateItem(Passport,Rewards[Result].Item,Rewards[Result].Amount,true)
		end

		Active[Passport] = nil
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETWHEELRANDOM
-----------------------------------------------------------------------------------------------------------------------------------------
function GetWheelRandom(Table)
	local PoolSize = 0
	for Number = 1,#Table do
		PoolSize = PoolSize + Table[Number].Chance
	end

	local Selected = math.random(1,PoolSize)
	for Index,v in pairs(Table) do
		Selected = Selected - v.Chance

		if (Selected <= 0) then
			return Index
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Active[Passport] then
		Active[Passport] = nil
	end
end)