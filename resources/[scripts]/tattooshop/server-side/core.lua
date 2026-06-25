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
Tunnel.bindInterface("tattooshop",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
local Locations = {
	{ Coords = vec3(1321.46,-1653.91,52.27) },
	{ Coords = vec3(-1155.66,-1427.18,4.95) },
	{ Coords = vec3(324.47,180.0,103.59) },
	{ Coords = vec3(-3169.29,1077.59,20.83) },
	{ Coords = vec3(1864.45,3746.73,33.03) },
	{ Coords = vec3(-294.34,6200.93,31.48) }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Tattooshop", Information = json.encode(Table) })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Tattooshop" })
	local Result = Consult and json.decode(Consult.Information) or {}

	for _,v in pairs(Result) do
		table.insert(Locations,v)
	end

	TriggerClientEvent("tattooshop:Init",-1,Locations)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADD
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Add",function(Table)
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Tattooshop" })
	local Result = Consult and json.decode(Consult.Information) or {}

	table.insert(Result,Table)
	table.insert(Locations,Table)

	TriggerClientEvent("tattooshop:Insert",-1,Table)
	vRP.Query("entitydata/SetData",{ Name = "Tattooshop", Information = json.encode(Result) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("tattooshop:Init",source,Locations)
end)