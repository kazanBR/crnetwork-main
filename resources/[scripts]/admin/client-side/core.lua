-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("admin",Creative)
vSERVER = Tunnel.getInterface("admin")
-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORTWAY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.teleportWay()
	local Ped = PlayerPedId()
	if IsPedInAnyVehicle(Ped) then
		Ped = GetVehiclePedIsUsing(Ped)
	end

	local Waypoint = GetFirstBlipInfoId(8)
	if not DoesBlipExist(Waypoint) then
		return false
	end

	local Coords = GetBlipCoords(Waypoint)
	for Height = 1,1000 do
		SetEntityCoordsNoOffset(Ped,Coords.x,Coords.y,Height + 0.0,true,false,false)

		RequestCollisionAtCoord(Coords.x,Coords.y,Coords.z)
		while not HasCollisionLoadedAroundEntity(Ped) do
			Wait(1)
		end

		local Found,GroundZ = GetGroundZFor_3dCoord(Coords.x,Coords.y,Height + 0.0)
		if Found then
			SetEntityCoordsNoOffset(Ped,Coords.x,Coords.y,GroundZ + 1.0,true,false,false)
			break
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:TUNING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:Tuning",function()
	local Ped = PlayerPedId()
	if not IsPedInAnyVehicle(Ped) then
		return false
	end

	local Vehicle = GetVehiclePedIsUsing(Ped)

	SetVehicleModKit(Vehicle,0)
	ToggleVehicleMod(Vehicle,18,true)

	for _,Mod in ipairs({ 11,12,13,15 }) do
		SetVehicleMod(Vehicle,Mod,GetNumVehicleMods(Vehicle,Mod) - 1,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUTTONCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
-- CreateThread(function()
-- 	while true do
-- 		if IsControlJustPressed(1,38) then
-- 			vSERVER.buttonTxt()
-- 		end
-- 		Wait(1)
-- 	end
-- end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Markers = {}
local DefaultLeft = 2.0
local ConfigRace = false
local DefaultRight = -2.0
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIGRACE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("configrace",function(_,Message)
	if not LocalPlayer.state.Admin then
		return false
	end

	for _,v in pairs(Markers) do
		if DoesBlipExist(v.Blip) then
			RemoveBlip(v.Blip)
		end
	end

	local RaceName = Message[1] or "nulled"
	DefaultLeft, DefaultRight = 2.0, -2.0
	ConfigRace = not ConfigRace
	Markers = {}

	while ConfigRace do
		Wait(1)

		local Ped = PlayerPedId()
		local Vehicle = GetVehiclePedIsUsing(Ped)
		if not Vehicle or not DoesEntityExist(Vehicle) then
			ConfigRace = false
			break
		end

		local Center = GetOffsetFromEntityInWorldCoords(Vehicle,0.0,5.0,0.0)
		local Left = GetOffsetFromEntityInWorldCoords(Vehicle,DefaultLeft,5.0,0.0)
		local Right = GetOffsetFromEntityInWorldCoords(Vehicle,DefaultRight,5.0,0.0)

		if IsDisabledControlPressed(1,10) then
			DefaultLeft += 0.1
			DefaultRight -= 0.1
		elseif IsDisabledControlPressed(1,11) then
			DefaultLeft -= 0.1
			DefaultRight += 0.1
		end

		DefaultLeft = math.max(DefaultLeft,2.0)
		DefaultRight = math.min(DefaultRight,-2.0)

		if IsControlJustPressed(1,38) then
			local Number = #Markers + 1
			vSERVER.RaceConfig(Left,Center,Right,DefaultLeft * 0.8,RaceName)

			local Blip = AddBlipForCoord(Center.x,Center.y,Center.z)
			SetBlipSprite(Blip,1)
			SetBlipColour(Blip,2)
			SetBlipScale(Blip,0.85)
			ShowNumberOnBlip(Blip,Number)
			SetBlipAsShortRange(Blip,true)

			Markers[Number] = { Left = Left, Right = Right, Blip = Blip }
		end

		DrawMarker(1,Left.x,Left.y,Left.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,88,101,242,175,false,false,0,false)
		DrawMarker(1,Right.x,Right.y,Right.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,88,101,242,175,false,false,0,false)
		DrawMarker(1,Center.x,Center.y,Center.z - 100,0,0,0,0,0,0,0.75,0.75,200.0,255,255,255,25,false,false,0,false)

		for _,v in pairs(Markers) do
			DrawMarker(1,v.Left.x,v.Left.y,v.Left.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,0,255,0,100,false,false,0,false)
			DrawMarker(1,v.Right.x,v.Right.y,v.Right.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,0,255,0,100,false,false,0,false)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:INITSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:initSpectate",function(OtherSource)
	if NetworkIsInSpectatorMode() then
		return false
	end

	local TargetPlayer = GetPlayerFromServerId(OtherSource)
	if TargetPlayer == -1 then
		return false
	end

	local TargetPed = GetPlayerPed(TargetPlayer)
	LocalPlayer.state:set("Spectate",true,false)
	NetworkSetInSpectatorMode(true,TargetPed)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:RESETSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:resetSpectate",function()
	if not NetworkIsInSpectatorMode() then
		return false
	end

	NetworkSetInSpectatorMode(false)
	LocalPlayer.state:set("Spectate",false,false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Quake",nil,function(Name,Key,Value)
	ShakeGameplayCam("SKY_DIVING_SHAKE",1.0)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LIMPAREA
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Limparea(Coords)
	local Radius = 100.0
	local x,y,z = Coords.x,Coords.y,Coords.z

	ClearAreaOfPeds(x,y,z,Radius,0)
	ClearAreaOfCops(x,y,z,Radius,0)
	ClearAreaOfObjects(x,y,z,Radius,0)
	ClearAreaOfProjectiles(x,y,z,Radius,0)
	ClearArea(x,y,z,Radius,true,false,false,false)
	ClearAreaOfVehicles(x,y,z,Radius,false,false,false,false,false)
	ClearAreaLeaveVehicleHealth(x,y,z,Radius,false,false,false,false)
end