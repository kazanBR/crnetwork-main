-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("markers",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Players = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Users()
	local Markers = {}
	for TargetSource,v in pairs(Players) do
		local Ped = GetPlayerPed(TargetSource)
		if Ped and DoesEntityExist(Ped) then
			Markers[TargetSource] = {
				Level = v.Level,
				Permission = v.Permission,
				Coords = GetEntityCoords(Ped)
			}
		else
			Players[TargetSource] = nil
		end
	end

	return Markers
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTER
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Enter",function(source,Permission,Level)
	if not source or not Permission then
		return false
	end

	if Players[source] then
		Players[source].Level = Level or Players[source].Level
		return true
	end

	Players[source] = {
		Permission = Permission,
		Level = Level or 1
	}

	for TargetSource in pairs(Players) do
		if TargetSource ~= source then
			TriggerClientEvent("markers:Add",TargetSource,source,Players[source])
		end
	end

	TriggerClientEvent("markers:Full",source,Players)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS:ENTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("markers:Enter")
AddEventHandler("markers:Enter",function(Permission)
	local source = source
	if Permission then
		exports.markers:Enter(source,Permission)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXIT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Exit",function(source,Permission)
	if source and Players[source] and (not Permission or Players[source].Permission == Permission) then
		Players[source] = nil

		for TargetSource in pairs(Players) do
			TriggerClientEvent("markers:Remove",TargetSource,source)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS:EXIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("markers:Exit",function(source)
	local User = source and Player(source)
	if User and User.state.Markers then
		User.state.Markers = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if source and Players[source] then
		exports.markers:Exit(source)
	end
end)