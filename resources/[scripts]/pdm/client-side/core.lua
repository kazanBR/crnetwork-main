-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("pdm")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Lasted = ""
local Camera = nil
local Selected = 1
local Preview = nil
local Vehicles = exports.vrp:VehicleList()
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
local Config = {
	{
		List = {},
		Coords = vec3(-56.86,-1097.95,26.33),
		Cam = vec4(-49.14,-1099.56,26.92,294.81),
		Spawn = vec4(-44.42,-1097.44,26.23,28.35),
		DriveIn = vec4(-54.56,-1075.18,26.45,68.04),
		DriveOut = vec4(-58.04,-1096.02,25.42,209.77),
		Classes = {
			--Compactos = true,
			--Esportivos = true
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINIT
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Index,v in pairs(Config) do
		exports.target:AddCircleZone("PDM:"..Index,v.Coords,0.1,{
			name = "PDM:"..Index,
			heading = 0.0,
			useZ = true
		},{
			shop = Index,
			Distance = 1.25,
			options = {
				{ event = "pdm:Open", label = "Abrir", tunnel = "client" }
			}
		})

		if v.Classes and next(v.Classes) then
			for Model,Vehicle in pairs(Vehicles) do
				if Vehicle.Class and v.Classes[Vehicle.Class] then
					v.List[Model] = Vehicle
				end
			end
		else
			v.List = Vehicles
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
function Close()
	if DoesEntityExist(Preview) then
		DeleteEntity(Preview)
		Preview = nil
	end

	if DoesCamExist(Camera) then
		RenderScriptCams(false,false,0,false,false)
		DestroyCam(Camera,false)
		Camera = nil
	end

	Lasted = ""
	SetNuiFocus(false,false)
	SetCursorLocation(0.5,0.5)
	TriggerEvent("hud:Active",true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CAMERAACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
function CameraActive()
	if DoesCamExist(Camera) then
		RenderScriptCams(false,false,0,false,false)
		DestroyCam(Camera,false)
		Camera = nil
	end

	Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)
	SetCamRot(Camera,0.0,0.0,Config[Selected].Cam.w)
	SetCamCoord(Camera,Config[Selected].Cam.xyz)
	RenderScriptCams(true,false,0,false,false)
	SetCamActive(Camera,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PDM:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("pdm:Open",function(Number)
	if DoesEntityExist(Preview) then
		DeleteEntity(Preview)
		Preview = nil
	end

	if not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not exports.hud:Wanted() then
		CameraActive()
		Selected = Number
		SetNuiFocus(true,true)
		SetCursorLocation(0.5,0.5)
		TriggerEvent("hud:Active",false)
		SendNUIMessage({ Action = "Open", Payload = { Vehicles = Config[Selected].List, Discounts = vSERVER.Discount(), Tax = 0.25, TaxTime = "MENSAL" } })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	Close()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Model = Data.Vehicle
	if LoadModel(Model) and Lasted ~= Model then
		if DoesEntityExist(Preview) then
			DeleteEntity(Preview)
			Preview = nil
		end

		Preview = CreateVehicle(Model,Config[Selected].Spawn,false,false)
		SetVehicleCustomSecondaryColour(Preview,88,101,242)
		SetVehicleCustomPrimaryColour(Preview,88,101,242)
		SetVehicleNumberPlateText(Preview,"PDMSPORT")
		SetEntityCollision(Preview,false,false)
		FreezeEntityPosition(Preview,true)
		SetEntityInvincible(Preview,true)
		SetVehicleDirtLevel(Preview,0.0)
		Lasted = Model
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Buy",function(Data,Callback)
	local Sucess = vSERVER.Buy(Data.Vehicle,Data.Rental)

	if Sucess then
		SendNUIMessage({ Action = "Close" })
		Close()
	end

	Callback(Sucess)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Rotate",function(Data,Callback)
	if DoesEntityExist(Preview) then
		local Offset = Data.Direction == "Left" and -5 or 5
		SetEntityHeading(Preview,GetEntityHeading(Preview) + Offset)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Drive", function(Data, Callback)
	if not vSERVER.Check() or not LoadModel(Data.Vehicle) then
		return Callback("Ok")
	end

	SendNUIMessage({ Action = "Close" })
	Close()

	if DoesEntityExist(Preview) then
		DeleteEntity(Preview)
		Preview = nil
	end

	Preview = CreateVehicle(Data.Vehicle,Config[Selected].DriveIn,false,false)

	SetVehicleModKit(Preview,0)
	SetVehicleDirtLevel(Preview,0.0)
	ToggleVehicleMod(Preview,18,true)
	SetEntityInvincible(Preview,true)
	SetPedIntoVehicle(PlayerPedId(),Preview,-1)
	SetVehicleNumberPlateText(Preview,"PDMSPORT")
	SetVehicleCustomPrimaryColour(Preview,88,101,242)
	SetVehicleCustomSecondaryColour(Preview,88,101,242)

	for _,Type in ipairs({ 11,12,13,15 }) do
		SetVehicleMod(Preview,Type,GetNumVehicleMods(Preview,Type) - 1,false)
	end

	LocalPlayer.state:set("Commands",true,true)

	CreateThread(function()
		while true do
			local Ped = PlayerPedId()
			if not IsPedInAnyVehicle(Ped) then
				vSERVER.Remove()
				LocalPlayer.state:set("Commands",false,true)

				SetEntityHeading(Ped,Config[Selected].DriveOut.w)
				SetEntityCoordsNoOffset(Ped,Config[Selected].DriveOut.xyz)

				if DoesEntityExist(Preview) then
					DeleteEntity(Preview)
					Preview = nil

					break
				end
			end

			Wait(1)
		end
	end)

	Callback("Ok")
end)