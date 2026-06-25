-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Animals = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISBALIDNET
-----------------------------------------------------------------------------------------------------------------------------------------
local function IsValidNet(Network)
	return Network and type(Network) == "number" and Network > 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEANIMAL
-----------------------------------------------------------------------------------------------------------------------------------------
local function DeleteAnimal(Passport)
	local Network = Animals[Passport]
	if Network and NetworkGetEntityFromNetworkId(Network) then
		TriggerEvent("DeletePed",Network)
	end

	Animals[Passport] = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:REGISTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("animals:Register")
AddEventHandler("animals:Register",function(Network)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if not IsValidNet(Network) or not NetworkGetEntityFromNetworkId(Network) then
		return false
	end

	if Animals[Passport] then
		DeleteAnimal(Passport)
	end

	local Entity = NetworkGetEntityFromNetworkId(Network)
	if not Entity or GetEntityType(Entity) ~= 1 then
		return false
	end

	Animals[Passport] = Network
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:CLEANER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("animals:Cleaner")
AddEventHandler("animals:Cleaner",function()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	DeleteAnimal(Passport)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("animals:Delete",function(source,Passport)
	if not Passport then
		return false
	end

	if Animals[Passport] then
		TriggerClientEvent("animals:Delete",source)
		DeleteAnimal(Passport)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Passport and Animals[Passport] then
		DeleteAnimal(Passport)
	end
end)