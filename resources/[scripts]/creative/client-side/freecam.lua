-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Speed = 0.3
local Zoom = 60.0
local Camera = nil
local Freecam = false
local MaxDistance = 8.0
local SmoothPosition = 0.15
local SmoothRotation = 0.25
local NextCollisionCheck = 0
local MouseSensitivity = 6.0
-----------------------------------------------------------------------------------------------------------------------------------------
-- RORATIONTODIRECTION
-----------------------------------------------------------------------------------------------------------------------------------------
function RotationToDirection(Rotation)
	local Z = math.rad(Rotation.z)
	local X = math.rad(Rotation.x)
	local CosX = math.abs(math.cos(X))

	return vec3(-math.sin(Z) * CosX,math.cos(Z) * CosX,math.sin(X))
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTFREECAM
-----------------------------------------------------------------------------------------------------------------------------------------
function StartFreecam()
	local Ped = PlayerPedId()
	local Coords = GetOffsetFromEntityInWorldCoords(Ped,0.0,3.0,-1.0)

	Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)

	SetCamCoord(Camera,Coords.x,Coords.y,Coords.z + 1.0)
	SetCamRot(Camera,0.0,0.0,GetEntityHeading(Ped) - 180.0,2)
	RenderScriptCams(true,false,0,false,false)
	SetEntityCollision(Ped,false,false)
	FreezeEntityPosition(Ped,true)
	SetCamFov(Camera,Zoom)

	CreateThread(function()
		while Freecam do
			DisableControlAction(0,1,true)
			DisableControlAction(0,2,true)
			DisableControlAction(0,30,true)
			DisableControlAction(0,31,true)
			DisableControlAction(0,21,true)
			DisableControlAction(0,22,true)

			local Ped = PlayerPedId()
			local PedCoords = GetEntityCoords(Ped)
			local CamCoords = GetCamCoord(Camera)
			local CamRot = GetCamRot(Camera,2)

			local MouseX = GetDisabledControlNormal(0,1)
			local MouseY = GetDisabledControlNormal(0,2)

			local TargetRotX = CamRot.x + MouseY * -MouseSensitivity
			local TargetRotZ = CamRot.z + MouseX * -MouseSensitivity

			TargetRotX = math.max(-89.0,math.min(89.0,TargetRotX))

			local RotX = CamRot.x + (TargetRotX - CamRot.x) * SmoothRotation
			local RotZ = CamRot.z + (TargetRotZ - CamRot.z) * SmoothRotation

			SetCamRot(Camera,RotX,0.0,RotZ,2)

			local ForwardMove = -GetDisabledControlNormal(0,31)
			local RightMove = -GetDisabledControlNormal(0,30)
			if ForwardMove ~= 0.0 or RightMove ~= 0.0 or IsDisabledControlPressed(0,44) or IsDisabledControlPressed(0,48) then
				local Forward = RotationToDirection(vec3(RotX,0.0,RotZ))
				local Right = RotationToDirection(vec3(0.0,0.0,RotZ + 90.0))
				local TargetCoords = vec3(CamCoords.x,CamCoords.y,CamCoords.z)

				TargetCoords += Forward * ForwardMove * Speed
				TargetCoords += Right * RightMove * Speed

				if IsDisabledControlPressed(0,44) then
					TargetCoords += vec3(0.0,0.0,0.1)
				end

				if IsDisabledControlPressed(0,48) then
					TargetCoords -= vec3(0.0,0.0,0.1)
				end

				CamCoords = CamCoords + (TargetCoords - CamCoords) * SmoothPosition
				SetCamCoord(Camera,CamCoords)
			end

			if IsDisabledControlJustPressed(0,241) then
				Zoom = math.max(10.0,Zoom - 2.0)
				SetCamFov(Camera,Zoom)
			elseif IsDisabledControlJustPressed(0,242) then
				Zoom = math.min(90.0,Zoom + 2.0)
				SetCamFov(Camera,Zoom)
			end

			local GameTimer = GetGameTimer()
			if GameTimer >= NextCollisionCheck then
				NextCollisionCheck = GameTimer + 120

				local Ray = StartShapeTestRay(PedCoords.x,PedCoords.y,PedCoords.z,CamCoords.x,CamCoords.y,CamCoords.z,1,Ped,0)
				local _,Hit,EndCoords = GetShapeTestResult(Ray)

				if Hit == 1 then
					SetCamCoord(Camera,EndCoords)
				end
			end

			if #(PedCoords - CamCoords) >= MaxDistance then
				StopFreecam()
			end

			Wait(1)
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOPFREECAM
-----------------------------------------------------------------------------------------------------------------------------------------
function StopFreecam()
	local Ped = PlayerPedId()
	if DoesCamExist(Camera) then
		DestroyCam(Camera,false)
	end

	RenderScriptCams(false,false,0,false,false)
	SetEntityCollision(Ped,true,true)
	FreezeEntityPosition(Ped,false)
	Freecam = false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATIVE:FREECAM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("creative:Freecam")
AddEventHandler("creative:Freecam",function()
	Freecam = not Freecam

	if Freecam then
		StartFreecam()
	else
		StopFreecam()
	end
end)