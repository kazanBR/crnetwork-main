-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState.Hallobox = 0
GlobalState.Halloween = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
for Index in pairs(Locations) do
	GlobalState["Halloween:"..Index] = false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HALLOWEEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("halloween",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Starting = not GlobalState.Halloween
	GlobalState.Hallobox = #Locations
	GlobalState.Halloween = Starting

	if Starting then
		GlobalState.Hallobox = #Locations

		for Index in pairs(Locations) do
			local Multiplier = math.random(1,2)
			if vRP.MountContainer(Passport,"Halloween:"..Index,Loots,Multiplier) then
				GlobalState["Halloween:"..Index] = true
			end
		end
	else
		GlobalState.Hallobox = 0
	end

	local Message = Starting and "Começou a caça as abóboras." or "Terminou a caça as abóboras."
	TriggerClientEvent("Notify",-1,"Doces ou Travessuras",Message,"halloween",30000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Hallobox",nil,function(_,_,Value)
	if Value <= 0 then
		for Index in pairs(Locations) do
			GlobalState["Halloween:"..Index] = false
			vRP.RemSrvData("Halloween:"..Index,true)
		end

		TriggerClientEvent("Notify",-1,"Doces ou Travessuras","Terminou a caça as abóboras.","halloween",30000)
		GlobalState.Halloween = false
	end
end)