-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
local vSERVER = Tunnel.getInterface("party")
-----------------------------------------------------------------------------------------------------------------------------------------
-- STATE
-----------------------------------------------------------------------------------------------------------------------------------------
local Markers = {}
local Opened = false
local LastMarker = 0
local MaxScale = 0.012
local MinScale = 0.006
local Rendering = false
local ScaleDistance = 100.0
local MarkerCooldown = 1000
local RenderDistance = 500.0
-----------------------------------------------------------------------------------------------------------------------------------------
-- CANINTERACT
-----------------------------------------------------------------------------------------------------------------------------------------
local function CanInteract()
	return LocalPlayer.state.Active and not IsPauseMenuActive()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPENNUI
-----------------------------------------------------------------------------------------------------------------------------------------
local function OpenNUI()
	if Opened then return end

	Opened = true
	SetNuiFocus(true,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSENUI
-----------------------------------------------------------------------------------------------------------------------------------------
local function CloseNUI()
	if not Opened then return end

	Opened = false
	SetNuiFocus(false,false)
	SendNUIMessage({ Action = "Close" })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCOORDSFROMCAM
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetCoordsFromCam(Distance)
	local Rotation = GetGameplayCamRot()
	local Position = GetGameplayCamCoord()

	local x = Rotation.x * math.pi / 180
	local z = Rotation.z * math.pi / 180

	local Direction = vec3(-math.sin(z) * math.abs(math.cos(x)),math.cos(z) * math.abs(math.cos(x)),math.sin(x))

	return Position + (Direction * Distance)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RAYCASTFROMCAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
local function RaycastFromCamera(Distance)
	local Ped = PlayerPedId()
	local Position = GetGameplayCamCoord()
	local Target = GetCoordsFromCam(Distance)

	local Handle = StartExpensiveSynchronousShapeTestLosProbe(Position,Target,-1,Ped,4)
	local _,Hit,Coords = GetShapeTestResult(Handle)

	return Hit == 1 and Coords or nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTRENDERING
-----------------------------------------------------------------------------------------------------------------------------------------
function StartRendering()
	if Rendering then return end
	Rendering = true
	CreateThread(function()
		while true do
			if not next(Markers) then
				Rendering = false
				break
			end

			local TimeDistance = 500

			if CanInteract() then
				local Ped = PlayerPedId()
				local Coords = GetEntityCoords(Ped)
				local Aspect = GetAspectRatio(false)

				for _,v in next,Markers do
					if v and v.Coords and type(v.Coords) == "vector3" then
						local Distance = #(Coords - v.Coords)
						if Distance <= RenderDistance then
							TimeDistance = 1

							local Factor = 1.0 - math.min(Distance / ScaleDistance,1.0)
							local Scale = MinScale + (Factor * (MaxScale - MinScale))
							local Color = v.Color or {}

							SetDrawOrigin(v.Coords.x,v.Coords.y,v.Coords.z)
							DrawSprite("Textures","Marker",0.0,0.0,Scale,Scale * Aspect,0.0,Color.r or 255,Color.g or 255,Color.b or 255,255)
							ClearDrawOrigin()
						end
					end
				end
			end

			Wait(TimeDistance)
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARTYS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("Partys",function()
	local Ped = PlayerPedId()
	if Opened or IsPedInAnyVehicle(Ped) then return end

	OpenNUI()
	SendNUIMessage({ Action = "Open", Payload = { LocalPlayer.state.Passport, vSERVER.GetRooms() } })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("Markers",function()
	local Ped = PlayerPedId()
	local Timer = GetGameTimer()
	if GetEntityHealth(Ped) <= 100 then
		return false
	end

	if (Timer - LastMarker) < MarkerCooldown then
		return false
	end

	local Coords = RaycastFromCamera(300.0)
	if not Coords then
		return false
	end

	LastMarker = Timer
	TriggerServerEvent("party:MarkerAdd",Coords)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETROOMS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("GetRooms",function(Data,Callback)
	Callback(vSERVER.GetRooms())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMEMBERS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("GetMembers",function(Data,Callback)
	Callback(vSERVER.GetMembers(Data.Id))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LEAVEROOM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("LeaveRoom",function(_,Callback)
	Callback(vSERVER.LeaveRoom())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEROOM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CreateRoom",function(Data,Callback)
	Callback(vSERVER.CreateRoom(Data.Name,Data.Password))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICKROOM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("KickRoom",function(Data,Callback)
	Callback(vSERVER.KickRoom(Data.Room,Data.Passport))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTERROOM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("EnterRoom",function(Data,Callback)
	Callback(vSERVER.EnterRoom(Data.Room,Data.Password))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	CloseNUI()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARTY:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("party:Close",CloseNUI)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARTY:MARKERADD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("party:MarkerAdd",function(Passport,Data)
	if not Passport or not Data or not Data.Coords then
		return false
	end

	PlaySoundFrontend(-1,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET",false)
	Markers[Passport] = Data
	StartRendering()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARTY:MARKERDELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("party:MarkerDelete",function(Passport)
	Markers[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("Partys","Abrir grupos","keyboard","G")
RegisterKeyMapping("Markers","Marcar/Desmarcar local","mouse_button","mouse_middle")