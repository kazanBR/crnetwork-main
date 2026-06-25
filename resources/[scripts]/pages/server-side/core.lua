-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Pages = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Pages" })
	Pages = Consult and json.decode(Consult.Information) or {}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAGES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("pages",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Tertiary(source,"Coords","Distância","Link")
	if not Keyboard then
		return false
	end

	local Image = Keyboard[3]
	local Locate = Keyboard[1]
	local Distance = tonumber(Keyboard[2])

	if not Locate or not Distance or not Image then
		return false
	end

	local Split = splitString(Locate,",")
	if #Split < 3 then
		return false
	end

	local Coords = { tonumber(Split[1]),tonumber(Split[2]),tonumber(Split[3]) }
	if not Coords[1] or not Coords[2] or not Coords[3] then
		return false
	end

	repeat
		Selected = GenerateString("DDLLDDLL")
	until Selected and not Pages[Selected]

	local Data = {
		Image = Image,
		Coords = Coords,
		Distance = Distance,
		Route = GetPlayerRoutingBucket(source)
	}

	Pages[Selected] = Data
	TriggerClientEvent("pages:New",-1,Selected,Data)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAGES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("pages:Delete")
AddEventHandler("pages:Delete",function(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Pages[Selected] and vRP.HasGroup(Passport,"Admin",1) then
		TriggerClientEvent("pages:Remove",-1,Selected)
		Pages[Selected] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("pages:Table",source,Pages)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	vRP.Query("entitydata/SetData",{ Name = "Pages", Information = json.encode(Pages) })

	if not Silenced then
		print("O resource ^2Pages^7 salvou os dados.")
	end
end)