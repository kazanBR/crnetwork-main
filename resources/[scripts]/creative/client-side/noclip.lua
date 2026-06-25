-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local NoClip = false
local ShowNoClipShortcuts = true
local NoClipShortcuts = {
	{ Letter = "Q", Text = "Subir" },
	{ Letter = "E", Text = "Descer" },
	{ Letter = "Shift", Text = "Velocidade Rápida" },
	{ Letter = "Alt", Text = "Velocidade Muito Rápida" },
	{ Letter = "Ctrl", Text = "Velocidade Lenta" },
	{ Letter = "F6", Text = "Exibir/Ocultar Atalhos" },
}
local PlayerPed = nil
local NoClipEntity = nil
local Camera = nil
local PlayerIsInVehicle = false
local PedFirstPersonNoClip = true
local VehFirstPersonNoClip = false
local Speed, MaxSpeed = 1.0, 16.0
local MinY, MaxY = -89.0, 89.0
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISCONTROLALWAYSPRESSED
-----------------------------------------------------------------------------------------------------------------------------------------
local function IsControlAlwaysPressed(InputGroup, Control)
	return IsControlPressed(InputGroup, Control) or IsDisabledControlPressed(InputGroup, Control)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISPEDDRIVINGVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
local function IsPedDrivingVehicle(Ped, Veh)
	return Ped == GetPedInVehicleSeat(Veh, -1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETUPCAM
-----------------------------------------------------------------------------------------------------------------------------------------
local function SetupCam()
	local EntityRot = GetEntityRotation(NoClipEntity)
	Camera = CreateCameraWithParams(
		"DEFAULT_SCRIPTED_CAMERA",
		GetEntityCoords(NoClipEntity),
		vec3(0.0, 0.0, EntityRot.z),
		75.0
	)
	SetCamActive(Camera, true)
	RenderScriptCams(true, true, 200, false, false)

	if PlayerIsInVehicle == 1 then
		AttachCamToEntity(
			Camera,
			NoClipEntity,
			0.0,
			VehFirstPersonNoClip == true and 0.5 or -4.5,
			VehFirstPersonNoClip == true and 1.0 or 2.0,
			true
		)
	else
		AttachCamToEntity(
			Camera,
			NoClipEntity,
			0.0,
			PedFirstPersonNoClip == true and 0.0 or -2.0,
			PedFirstPersonNoClip == true and 1.0 or 0.5,
			true
		)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYCAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
local function DestroyCamera()
	SetGameplayCamRelativeHeading(0)
	RenderScriptCams(false, true, 200, true, true)
	DetachEntity(NoClipEntity, true, true)
	SetCamActive(Camera, false)
	DestroyCam(Camera, true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETGROUNDCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetGroundCoords(Coords)
	local RayCast = StartShapeTestRay(Coords.x, Coords.y, Coords.z, Coords.x, Coords.y, -10000.0, 1, 0)
	local _, Hit, HitCoords = GetShapeTestResult(RayCast)
	return (Hit == 1 and HitCoords) or Coords
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKINPUTROTATION
-----------------------------------------------------------------------------------------------------------------------------------------
local function CheckInputRotation()
	local RightAxisX = GetControlNormal(0, 220)
	local RightAxisY = GetControlNormal(0, 221)
	local Rotation = GetCamRot(Camera, 2)
	local YValue = RightAxisY * -5
	local NewX
	local NewZ = Rotation.z + (RightAxisX * -10)

	if (Rotation.x + YValue > MinY) and (Rotation.x + YValue < MaxY) then
		NewX = Rotation.x + YValue
	end

	if NewX ~= nil and NewZ ~= nil then
		SetCamRot(Camera, vec3(NewX, Rotation.y, NewZ), 2)
	end

	SetEntityHeading(NoClipEntity, math.max(0, (Rotation.z % 360)))
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RUNNOCLIPTHREAD
-----------------------------------------------------------------------------------------------------------------------------------------
local function RunNoClipThread()
	CreateThread(function()
		while NoClip do
			Wait(0)
			CheckInputRotation()

			if IsControlAlwaysPressed(2, 14) then
				Speed = Speed - 0.5
				if Speed < 0.5 then
					Speed = 0.5
				end
			elseif IsControlAlwaysPressed(2, 15) then
				Speed = Speed + 0.5
				if Speed > MaxSpeed then
					Speed = MaxSpeed
				end
			elseif IsDisabledControlJustReleased(0, 348) then
				Speed = 1.0
			end

			local Multi = 1.0
			if IsControlAlwaysPressed(0, 21) then
				Multi = 2
			elseif IsControlAlwaysPressed(0, 19) then
				Multi = 4
			elseif IsControlAlwaysPressed(0, 36) then
				Multi = 0.25
			end

			if IsControlAlwaysPressed(0, 32) then
				local Pitch = GetCamRot(Camera, 0)
				if Pitch.x >= 0 then
					SetEntityCoordsNoOffset(
						NoClipEntity,
						GetOffsetFromEntityInWorldCoords(
							NoClipEntity,
							0.0,
							0.5 * (Speed * Multi),
							(Pitch.x * ((Speed / 2) * Multi)) / 89
						)
					)
				else
					SetEntityCoordsNoOffset(
						NoClipEntity,
						GetOffsetFromEntityInWorldCoords(
							NoClipEntity,
							0.0,
							0.5 * (Speed * Multi),
							-1 * ((math.abs(Pitch.x) * ((Speed / 2) * Multi)) / 89)
						)
					)
				end
			elseif IsControlAlwaysPressed(0, 33) then
				local Pitch = GetCamRot(Camera, 2)
				if Pitch.x >= 0 then
					SetEntityCoordsNoOffset(
						NoClipEntity,
						GetOffsetFromEntityInWorldCoords(
							NoClipEntity,
							0.0,
							-0.5 * (Speed * Multi),
							-1 * (Pitch.x * ((Speed / 2) * Multi)) / 89
						)
					)
				else
					SetEntityCoordsNoOffset(
						NoClipEntity,
						GetOffsetFromEntityInWorldCoords(
							NoClipEntity,
							0.0,
							-0.5 * (Speed * Multi),
							((math.abs(Pitch.x) * ((Speed / 2) * Multi)) / 89)
						)
					)
				end
			end

			if IsControlAlwaysPressed(0, 34) then
				SetEntityCoordsNoOffset(
					NoClipEntity,
					GetOffsetFromEntityInWorldCoords(NoClipEntity, -0.5 * (Speed * Multi), 0.0, 0.0)
				)
			elseif IsControlAlwaysPressed(0, 35) then
				SetEntityCoordsNoOffset(
					NoClipEntity,
					GetOffsetFromEntityInWorldCoords(NoClipEntity, 0.5 * (Speed * Multi), 0.0, 0.0)
				)
			end

			if IsControlAlwaysPressed(0, 44) then
				SetEntityCoordsNoOffset(
					NoClipEntity,
					GetOffsetFromEntityInWorldCoords(NoClipEntity, 0.0, 0.0, 0.5 * (Speed * Multi))
				)
			elseif IsControlAlwaysPressed(0, 46) then
				SetEntityCoordsNoOffset(
					NoClipEntity,
					GetOffsetFromEntityInWorldCoords(NoClipEntity, 0.0, 0.0, -0.5 * (Speed * Multi))
				)
			end

			local Coords = GetEntityCoords(NoClipEntity)
			RequestCollisionAtCoord(Coords.x, Coords.y, Coords.z)
			FreezeEntityPosition(NoClipEntity, true)
			SetEntityCollision(NoClipEntity, false, false)
			SetEntityVisible(NoClipEntity, false, false)
			SetEntityInvincible(NoClipEntity, true)

			SetEveryoneIgnorePlayer(PlayerPed, true)
			SetPoliceIgnorePlayer(PlayerPed, true)

			if IsControlJustPressed(0, 167) then
				ShowNoClipShortcuts = not ShowNoClipShortcuts
				if ShowNoClipShortcuts then
					TriggerEvent("inventory:Buttons", NoClipShortcuts)
				else
					TriggerEvent("inventory:Buttons", { { Letter = "F6", Text = "Exibir/Ocultar Atalhos" } })
				end
			end
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOPNOCLIP
-----------------------------------------------------------------------------------------------------------------------------------------
local function StopNoClip()
	FreezeEntityPosition(NoClipEntity, false)
	SetEntityCollision(NoClipEntity, true, true)
	SetEntityVisible(NoClipEntity, true, false)
	SetLocalPlayerVisibleLocally(true)
	SetEveryoneIgnorePlayer(PlayerPed, false)
	SetPoliceIgnorePlayer(PlayerPed, false)

	if GetVehiclePedIsIn(PlayerPed, false) ~= 0 then
		while (not IsVehicleOnAllWheels(NoClipEntity)) and not NoClip do
			Wait(0)
		end
		while not NoClip do
			Wait(0)
			if IsVehicleOnAllWheels(NoClipEntity) then
				return SetEntityInvincible(NoClipEntity, false)
			end
		end
	else
		if IsPedFalling(NoClipEntity) and math.abs(1 - GetEntityHeightAboveGround(NoClipEntity)) > 1.00 then
			while (IsPedStopped(NoClipEntity) or not IsPedFalling(NoClipEntity)) and not NoClip do
				Wait(0)
			end
		end
		while not NoClip do
			Wait(0)
			if (not IsPedFalling(NoClipEntity)) and (not IsPedRagdoll(NoClipEntity)) then
				return SetEntityInvincible(NoClipEntity, false)
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATIVE:NOCLIP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("creative:NoClip")
AddEventHandler("creative:NoClip", function()
	NoClip = not NoClip
	PlayerPed = PlayerPedId()
	PlayerIsInVehicle = IsPedInAnyVehicle(PlayerPed, false)

	if PlayerIsInVehicle ~= 0 and IsPedDrivingVehicle(PlayerPed, GetVehiclePedIsIn(PlayerPed, false)) then
		NoClipEntity = GetVehiclePedIsIn(PlayerPed, false)
		SetVehicleEngineOn(NoClipEntity, not NoClip, true, NoClip)
		NoClipAlpha = PedFirstPersonNoClip == true and 0 or 51
	else
		NoClipEntity = PlayerPed
		NoClipAlpha = VehFirstPersonNoClip == true and 0 or 51
	end

	if NoClip then
		SetupCam()

		if not PlayerIsInVehicle then
			ClearPedTasksImmediately(PlayerPed)
			if PedFirstPersonNoClip then
				Wait(200)
			end
		else
			if VehFirstPersonNoClip then
				Wait(200)
			end
		end

		if ShowNoClipShortcuts then
			TriggerEvent("inventory:Buttons", NoClipShortcuts)
		else
			TriggerEvent("inventory:Buttons", { { Letter = "F6", Text = "Exibir/Ocultar Atalhos" } })
		end
		RunNoClipThread()
	else
		local GroundCoords = GetGroundCoords(GetEntityCoords(NoClipEntity))
		SetEntityCoords(NoClipEntity, GroundCoords.x, GroundCoords.y, GroundCoords.z)
		Wait(50)
		DestroyCamera()
		TriggerEvent("inventory:CloseButtons")
		StopNoClip()
	end
end)
