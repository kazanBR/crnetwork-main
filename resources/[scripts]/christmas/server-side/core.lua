-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState.Christbox = 0
GlobalState.Christmas = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
for Index in pairs(Locations) do
	GlobalState["Christmas:"..Index] = false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHRISTMAS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("christmas",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Starting = not GlobalState.Christmas
	GlobalState.Christbox = #Locations
	GlobalState.Christmas = Starting

	if Starting then
		GlobalState.Christbox = #Locations

		for Index in pairs(Locations) do
			local Multiplier = math.random(1,2)
			if vRP.MountContainer(Passport,"Christmas:"..Index,Loots,Multiplier) then
				GlobalState["Christmas:"..Index] = true
			end
		end
	else
		GlobalState.Christbox = 0
	end

	local Message = Starting and "Começou a caça aos presentes." or "Terminou a caça aos presentes."
	TriggerClientEvent("Notify",-1,"Merry Christmas",Message,"christmas",30000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Christbox",nil,function(_,_,Value)
	if Value <= 0 then
		for Index in pairs(Locations) do
			GlobalState["Christmas:"..Index] = false
			vRP.RemSrvData("Christmas:"..Index,true)
		end

		TriggerClientEvent("Notify",-1,"Merry Christmas","Terminou a caça aos presentes.","christmas",30000)
		GlobalState.Christmas = false
	end
end)