-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = false
local LastError = false
local LastRayStart = false
local LastRayDirection = false
local LastComputedRayNormal = false
local LastComputedRayEndCoords = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPRAYCONTROLLING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SprayControlling(Model)
	local Application = false
	local SprayCoords = false

	if Active or not LoadModel(Model) then
		return false,false
	end

	Active = true

	local NextObject = nil
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)

	TriggerEvent("inventory:Buttons",{
		{ Letter = "F", Text = "Cancelar" },
		{ Letter = "H", Text = "Pichar" }
	})

	while true do
		local RayCoords,RayNormal = FindRaySprayCoords()
		if RayCoords and RayNormal then
			local SprayPosition = RayCoords + RayNormal * 0.050
			local Heading = GetHeadingFromVector_2d(SprayPosition.x - Coords.x,SprayPosition.y - Coords.y)

			if not NextObject then
				NextObject = CreateObjectNoOffset(Model,SprayPosition.x,SprayPosition.y,SprayPosition.z,false,false,false)

				SetEntityAlpha(NextObject,175,false)
				SetEntityCollision(NextObject,false,false)
			end

			SetEntityCoordsNoOffset(NextObject,SprayPosition.x,SprayPosition.y,SprayPosition.z,false,false,false)
			SetEntityRotation(NextObject,0.0,0.0,Heading,2,true)
		end

		if IsControlJustPressed(1,74) then
			TriggerEvent("inventory:CloseButtons")
			Application = true
			break
		end

		if IsControlJustPressed(0,49) then
			TriggerEvent("inventory:CloseButtons")
			Application = false
			break
		end

		Wait(0)
	end

	if NextObject and DoesEntityExist(NextObject) then
		local ObjectCoords = GetEntityCoords(NextObject)
		local ObjectHeading = GetEntityHeading(NextObject)

		SprayCoords = {
			Optimize(ObjectCoords.x),
			Optimize(ObjectCoords.y),
			Optimize(ObjectCoords.z),
			Optimize(ObjectHeading)
		}

		DeleteEntity(NextObject)
	end

	Active = false

	if not SprayCoords or (SprayCoords[1] == 0.0 and SprayCoords[2] == 0.0) then
		Application = false
	end

	return Application,SprayCoords
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINDRAYSPRAYCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
function FindRaySprayCoords()
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)
	local CameraCoord = GetGameplayCamCoord()
	local CameraRotation = GetGameplayCamRot()
	local Direction = RotationDirection(CameraRotation)

	if not LastRayStart or not LastRayDirection or CameraCoord ~= LastRayStart or Direction ~= LastRayDirection or not LastComputedRayEndCoords or not LastComputedRayNormal or LastError then
		LastRayStart = CameraCoord
		LastRayDirection = Direction

		local Result,RayCoords,RayNormal = FindRaycastSprayCoordsNotCached(Ped,Coords,CameraCoord,Direction)

		if Result then
			LastComputedRayEndCoords = RayCoords
			LastComputedRayNormal = RayNormal
			LastError = false
		else
			LastComputedRayEndCoords = nil
			LastComputedRayNormal = nil
			LastError = true
		end
	end

	return LastComputedRayEndCoords,LastComputedRayNormal
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINDRAYSPRAYCOORDSNOTCACHED
-----------------------------------------------------------------------------------------------------------------------------------------
function FindRaycastSprayCoordsNotCached(Ped,Coords,Start,Direction)
	local offsets = {
		vector3(0.0,0.0,0.0),
		vector3(0.0,0.0,0.2),
		vector3(1.0,0.0,0.0),
		vector3(-1.0,0.0,0.0),
		vector3(0.0,1.0,0.0),
		vector3(0.0,-1.0,0.0)
	}

	local hits = {}
	local normals = {}
	local endCoords = {}

	for i,offset in ipairs(offsets) do
		hits[i],endCoords[i],normals[i] = CheckRay(Ped,Start + offset,Direction)
	end

	if hits[1] and hits[2] and hits[3] and hits[4] and hits[5] and hits[6] then
		local allNormalsMatch = true

		for i = 2,6 do
			if not IsNormal(normals[1],normals[i]) then
				allNormalsMatch = false
				break
			end
		end

		local distanceValid = #(Coords - endCoords[1]) < 2.5

		if allNormalsMatch and distanceValid and normals[2].z <= 1.0 then
			return true,endCoords[1], normals[1]
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKRAY
-----------------------------------------------------------------------------------------------------------------------------------------
function CheckRay(Ped,Coords,Direction)
	local EndPoint = Coords + (Direction * 1000.0)
	local Handle = StartExpensiveSynchronousShapeTestLosProbe(Coords.x,Coords.y,Coords.z,EndPoint.x,EndPoint.y,EndPoint.z,1,Ped)
	local _,Hit,EndCoords,Surface,Material = GetShapeTestResultIncludingMaterial(Handle)

	return Hit == 1,EndCoords,Surface,Material
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISNORMAL
-----------------------------------------------------------------------------------------------------------------------------------------
function IsNormal(One,Two,Tolerance)
	Tolerance = Tolerance or 0.01

	return #(One - Two) < Tolerance
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATIONDIRECTION
-----------------------------------------------------------------------------------------------------------------------------------------
function RotationDirection(rotation)
	local x = math.rad(rotation["x"])
	local y = math.rad(rotation["y"])
	local z = math.rad(rotation["z"])

	return vector3(
		-math.sin(z) * math.cos(x),
		math.cos(z) * math.cos(x),
		math.sin(x)
	)
end