-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local NoClip = false
local PlayerPed = nil
local PlayerVehicle = 0
local NoClipEntity = nil
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISCONTROLALWAYSPRESSED
-----------------------------------------------------------------------------------------------------------------------------------------
local function IsControlAlwaysPressed(Input,Control)
	return IsControlPressed(Input,Control) or IsDisabledControlPressed(Input,Control)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCAMDIRECTION
-----------------------------------------------------------------------------------------------------------------------------------------
function GetCamDirections()
	local Pitch = GetGameplayCamRelativePitch()
	local Heading = GetEntityHeading(NoClipEntity)
	local Calculate = GetGameplayCamRelativeHeading() + Heading

	local x = -math.sin(Calculate * math.pi / 180.0)
	local y = math.cos(Calculate * math.pi / 180.0)
	local z = math.sin(Pitch * math.pi / 180.0)

	local Len = math.sqrt(x * x + y * y + z * z)
	if Len ~= 0 then
		x,y,z = x / Len,y / Len,z / Len
	end

	SetEntityHeading(NoClipEntity,Calculate)

	return vec3(x,y,z)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RUNNOCLIPTHREAD
-----------------------------------------------------------------------------------------------------------------------------------------
local function RunNoClipThread()
	CreateThread(function()
		while NoClip do
			Wait(0)

			local Change = false
			local Direction = GetCamDirections()
			local Coords = GetEntityCoords(NoClipEntity)
			local x,y,z = table.unpack(Coords)
			local Multiplier = IsControlAlwaysPressed(0,21) and 5.0 or 1.0

			if IsControlAlwaysPressed(0,21) then
				Multiplier = 5.0
			end

			if IsControlAlwaysPressed(0,32) then
				x = x + Multiplier * Direction.x
				y = y + Multiplier * Direction.y
				z = z + Multiplier * Direction.z
				Change = true
			end

			if IsControlAlwaysPressed(0,33) then
				x = x - Multiplier * Direction.x
				y = y - Multiplier * Direction.y
				z = z - Multiplier * Direction.z
				Change = true
			end

			if Change then
				SetEntityCoordsNoOffset(NoClipEntity,x,y,z)
				FreezeEntityPosition(NoClipEntity,true)
			end

			if PlayerVehicle ~= 0 then
				BlockWeaponWheelThisFrame()
				SetVehicleEngineOn(NoClipEntity,false,true,true)
			end
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATIVE:NOCLIP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("creative:NoClip")
AddEventHandler("creative:NoClip",function()
	NoClip = not NoClip
	PlayerPed = PlayerPedId()
	PlayerVehicle = GetVehiclePedIsUsing(PlayerPed)
	NoClipEntity = PlayerVehicle ~= 0 and PlayerVehicle or PlayerPed

	if NoClip then
		SetEntityCompletelyDisableCollision(NoClipEntity,false,false)
		SetEntityCollision(NoClipEntity,false,false)
		FreezeEntityPosition(NoClipEntity,true)
		SetEntityInvincible(NoClipEntity,true)
		SetEntityVisible(NoClipEntity,false)

		RunNoClipThread()
	else
		SetEntityCompletelyDisableCollision(NoClipEntity,true,true)
		SetEntityCollision(NoClipEntity,true,true)
		FreezeEntityPosition(NoClipEntity,false)
		SetEntityInvincible(NoClipEntity,false)
		SetEntityVisible(NoClipEntity,true)
	end
end)