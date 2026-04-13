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
Tunnel.bindInterface("barbershop",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Purchase = {
	Import = {},
	Export = {}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
local Locations = {
	{ Coords = vec4(-813.37,-183.85,37.57,330.0) },
	{ Coords = vec4(138.13,-1706.46,29.3,140.0) },
	{ Coords = vec4(-1280.92,-1117.07,7.0,110.0) },
	{ Coords = vec4(1930.54,3732.06,32.85,209.0) },
	{ Coords = vec4(1214.2,-473.18,66.21,80.0) },
	{ Coords = vec4(-33.61,-154.52,57.08,340.0) },
	{ Coords = vec4(-276.65,6226.76,31.7,42.0) }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Table,Creation)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Barbershop", Information = json.encode(Table) })

		if Creation then
			vRP.Creation(Passport)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mode()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Identity = vRP.Identity(Passport)
	if not Identity or not Identity.Created then
		return false
	end

	return (Identity.Created + (3 * 86400)) >= os.time() and true or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURCHASE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Purchase(Mode,Ignore)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or (Mode ~= "Import" and Mode ~= "Export") then
		return false
	end

	local CurrentTimer = os.time()
	if Purchase[Mode][Passport] and Purchase[Mode][Passport] > CurrentTimer then
		return true
	end

	if not Ignore and vRP.PaymentGems(Passport,Config[Mode].Price) then
		Purchase[Mode][Passport] = CurrentTimer + (Config[Mode].Minutes * 60)
		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Barbershop" })
	local Result = Consult and json.decode(Consult.Information) or {}

	for _,v in pairs(Result) do
		table.insert(Locations,v)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADD
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Add",function(Table)
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Barbershop" })
	local Result = Consult and json.decode(Consult.Information) or {}

	table.insert(Result,Table)
	table.insert(Locations,Table)

	TriggerClientEvent("barbershop:Insert",-1,Table)
	vRP.Query("entitydata/SetData",{ Name = "Barbershop", Information = json.encode(Result) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("barbershop:Init",source,Locations)
end)