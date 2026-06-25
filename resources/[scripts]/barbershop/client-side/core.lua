-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPS = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("barbershop")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Lasted = {}
local Heading = 0.0
local Opened = false
local Locations = {}
local Barbershop = {}
local Creation = false
local ActiveCamera = nil
local CurrentCamera = nil
local OriginalHeading = 0.0
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMS
-----------------------------------------------------------------------------------------------------------------------------------------
local Anims = {
	Body = { Dict = "move_f@multiplayer", Name = "idle" },
	Others = { Dict = "mp_sleep", Name = "bind_pose_180" }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CAMERAS
-----------------------------------------------------------------------------------------------------------------------------------------
local Cameras = {
	Body = { Coords = vec3(0.0,2.5,0.8), Point = vec3(0.0,0.0,0.0) },
	Head = { Coords = vec3(0.0,0.5,0.7), Point = vec3(0.0,0.0,0.67) },
	Eye = { Coords = vec3(0.0,0.3,0.7), Point = vec3(0.0,0.0,0.7) },
	Mouth = { Coords = vec3(0.0,0.3,0.63), Point = vec3(0.0,0.0,0.63) },
	Chest = { Coords = vec3(0.0,1.2,0.4), Point = vec3(0.0,0.0,0.2) }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETCAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
function SetCamera(Name)
	if not Cameras[Name] then
		return false
	end

	if Name == ActiveCamera then
		return false
	end

	local Ped = PlayerPedId()
	local Camera = Cameras[Name]
	local Coords = GetEntityCoords(Ped)
	
	local CameraZ = Coords.z + Camera.Coords.z
	local CameraHeading = math.rad(OriginalHeading)
	local CameraX = Coords.x + Camera.Coords.x * math.cos(CameraHeading) - Camera.Coords.y * math.sin(CameraHeading)
	local CameraY = Coords.y + Camera.Coords.x * math.sin(CameraHeading) + Camera.Coords.y * math.cos(CameraHeading)
	local Coord = vec3(CameraX,CameraY,CameraZ)
	
	local PointZ = Coords.z + Camera.Point.z
	local PointX = Coords.x + Camera.Point.x * math.cos(CameraHeading) - Camera.Point.y * math.sin(CameraHeading)
	local PointY = Coords.y + Camera.Point.x * math.sin(CameraHeading) + Camera.Point.y * math.cos(CameraHeading)
	local PointCoords = vec3(PointX,PointY,PointZ)

	if not DoesCamExist(CurrentCamera) then
		local GroundCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA")
		AttachCamToEntity(GroundCamera,Ped,0.0,-2.0,0.0)
		SetCamActive(GroundCamera,true)
		RenderScriptCams(true,false,1,true,true)
		
		CurrentCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",Coord,0,0,0,50.0)
		PointCamAtCoord(CurrentCamera,PointCoords)
		SetCamActive(CurrentCamera,true)
		SetCamActiveWithInterp(CurrentCamera,GroundCamera,1000,true,true)

		local Anim = Anims[Name == "Body" and "Body" or "Others"]
		if not IsEntityPlayingAnim(Ped,Anim.Dict,Anim.Name,3) then
			vRP.playAnim(false,{Anim.Dict,Anim.Name},true)
		end

		ActiveCamera = Name

		CreateThread(function()
			Wait(1000)
			DestroyCam(GroundCamera)
		end)

		Wait(1000)

		return true
	else
		local TemporaryCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",Coord,0,0,0,50.0)
		SetCamActive(TemporaryCamera,true)
		SetCamActiveWithInterp(TemporaryCamera,CurrentCamera,600,true,true)
		PointCamAtCoord(TemporaryCamera,PointCoords)

		local Anim = Anims[Name == "Body" and "Body" or "Others"]
		if not IsEntityPlayingAnim(Ped,Anim.Dict,Anim.Name,3) then
			vRP.playAnim(false,{Anim.Dict,Anim.Name},true)
		end

		ActiveCamera = Name

		CreateThread(function()
			Wait(600)
			DestroyCam(CurrentCamera)
			CurrentCamera = TemporaryCamera
		end)

		Wait(600)

		return true
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETECAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
function DeleteCamera()
	if DoesCamExist(CurrentCamera) then
		DestroyCam(CurrentCamera)
		CurrentCamera = nil
	end

	DestroyAllCams(true)
	RenderScriptCams(false,true,500,true,true)
	ActiveCamera = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Save",function(Data,Callback)
	local Ped = PlayerPedId()
	Opened = false
	DeleteCamera()

	if Creation then
		DoScreenFadeOut(0)

		SetTimeout(2500,function()
			local Ped = PlayerPedId()

			LocalPlayer.state:set("Active",true,true)
			TriggerServerEvent("vRP:WaitCharacters")
			FreezeEntityPosition(Ped,false)
			TriggerEvent("hud:Active",true)
			TriggerEvent("referrals:Open")
			SetEntityInvincible(Ped,false)

			DoScreenFadeIn(2500)
		end)
	else
		TriggerEvent("hud:Active",true)
		TriggerServerEvent("vRP:Bucket","Exit")
	end

	exports.skinshop:Apply()
	ClearFacialIdleAnimOverride(Ped)
	LocalPlayer.state:set("Hoverfy",true,false)
	vSERVER.Update(Barbershop,Creation)
	SetNuiFocus(false,false)
	Creation = false
	vRP.Destroy()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Reset",function(Data,Callback)
	local Ped = PlayerPedId()
	Opened = false
	DeleteCamera()

	if Creation then
		DoScreenFadeOut(0)

		SetTimeout(2500,function()
			local Ped = PlayerPedId()

			LocalPlayer.state:set("Active",true,true)
			TriggerServerEvent("vRP:WaitCharacters")
			FreezeEntityPosition(Ped,false)
			TriggerEvent("hud:Active",true)
			TriggerEvent("referrals:Open")
			SetEntityInvincible(Ped,false)

			DoScreenFadeIn(2500)
		end)
	else
		TriggerEvent("hud:Active",true)
		TriggerServerEvent("vRP:Bucket","Exit")
	end

	exports.skinshop:Apply()
	ClearFacialIdleAnimOverride(Ped)
	LocalPlayer.state:set("Hoverfy",true,false)
	exports.barbershop:Apply(Lasted)
	vSERVER.Update(Lasted,Creation)
	SetNuiFocus(false,false)
	Creation = false
	vRP.Destroy()
	Lasted = {}

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Update",function(Data,Callback)
	exports.barbershop:Apply(Data)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP:APPLY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("barbershop:Apply")
AddEventHandler("barbershop:Apply",function(Data)
	exports.barbershop:Apply(Data)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- APPLY
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Apply",function(Data,Ped)
	Ped = Ped or PlayerPedId()

	if Data then
		Barbershop = Data
	end

	for Number = 1,56 do
		if Barbershop[Number] == nil then
			Barbershop[Number] = (Number >= 6 and Number <= 9) and -1 or 0
		end
	end

	vRPS.Barbershop(Barbershop)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("barbershop:Open")
AddEventHandler("barbershop:Open",function(Created)
	if Created then
		exports.barbershop:Creation()
	else
		OpenBarbershop(true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPENBARBERSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
function OpenBarbershop(Mode,BarbershopCoords)
	for Number = 1,56 do
		if Barbershop[Number] == nil then
			Barbershop[Number] = (Number >= 6 and Number <= 9) and -1 or 0
		end
	end

	LocalPlayer.state:set("Hoverfy",false,false)
	TriggerEvent("hud:Active",false)

	Lasted = Barbershop

	local Ped = PlayerPedId()
	DoScreenFadeOut(300)
	Wait(320)

	Opened = true
	TriggerServerEvent("vRP:Bucket","Enter")

	ClearPedTasks(Ped)
	ClearPedSecondaryTask(Ped)
	ClearPedTasksImmediately(Ped)
	Wait(300)

	if BarbershopCoords then
		SetEntityCoords(Ped,BarbershopCoords.x,BarbershopCoords.y,BarbershopCoords.z)
		SetEntityHeading(Ped,BarbershopCoords.w)
		Heading = BarbershopCoords.w
		OriginalHeading = BarbershopCoords.w
	else
		local CurrentHeading = GetEntityHeading(Ped)
		Heading = CurrentHeading
		OriginalHeading = CurrentHeading
	end

	local Model = GetEntityModel(Ped)
	if Config.Outfit[Model] then
		for Component,Drawable in pairs(Config.Outfit[Model]) do
			SetPedComponentVariation(Ped,Component,Drawable,0,0)
		end
	end

	ClearAllPedProps(Ped)
	SetFacialIdleAnimOverride(Ped,"pose_normal_1",0)
	vRP.playAnim(false,{"mp_sleep","bind_pose_180"},true)
	Wait(200)
	SetEntityHeading(Ped,OriginalHeading)
	Wait(800)
	SetCamera(Mode and "Body" or "Eye")
	Wait(1000)

	SendNUIMessage({ Action = "Open", Payload = { Current = Barbershop, MaxHair = GetNumberOfPedDrawableVariations(Ped,2) - 1, Creation = Mode, Config = Config } })
	SetNuiFocus(true,true)

	if Creation then
		DoScreenFadeIn(2500)
	else
		DoScreenFadeIn(300)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("barbershop:Init")
AddEventHandler("barbershop:Init",function(Data)
	Locations = Data

	local Table = {}
	for _,v in pairs(Locations) do
		if v.Coords then
			table.insert(Table,{ vec3(v.Coords.x,v.Coords.y,v.Coords.z),2.5,"E","Pressione","para abrir" })
		end
	end

	TriggerEvent("hoverfy:Insert",Table)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP:INSERT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("barbershop:Insert")
AddEventHandler("barbershop:Insert",function(Data)
	table.insert(Locations,Data)

	if Data.Coords then
		TriggerEvent("hoverfy:Insert",{
			{ vec3(Data.Coords.x,Data.Coords.y,Data.Coords.z),2.5,"E","Pressione","para abrir" }
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOPEN
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for _,v in pairs(Anims) do
		LoadAnim(v.Dict)
	end

	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if not IsPedInAnyVehicle(Ped) then
			local Coords = GetEntityCoords(Ped)

			for _,v in pairs(Locations) do
				if #(Coords - vec3(v.Coords.x,v.Coords.y,v.Coords.z)) <= 2.5 then
					TimeDistance = 1

					if IsControlJustPressed(1,38) and not exports.hud:Wanted() and (not v.Permission or LocalPlayer.state[v.Permission]) then
						OpenBarbershop(vSERVER.Mode(),v.Coords)
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATION
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Creation",function()
	local Ped = PlayerPedId()
	if not IsEntityVisible(Ped) then
		SetEntityVisible(Ped,true)
	end

	Creation = true
	OpenBarbershop(true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Rotate",function(Data,Callback)
	local Step = 5.0
	local Ped = PlayerPedId()
	local Direction = Data.Direction
	Heading = Heading or GetEntityHeading(Ped)

	if Direction == "Left" then
		Heading -= Step
	elseif Direction == "Right" then
		Heading += Step
	end

	if Heading < 0.0 then
		Heading += 360.0
	elseif Heading >= 360.0 then
		Heading -= 360.0
	end

	SetEntityHeading(Ped,Heading)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Camera",function(Data,Callback)
	Callback(SetCamera(Data.Camera))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURCHASE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Purchase",function(Data,Callback)
	Callback(vSERVER.Purchase(Data.Mode))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETIMPORTEXPORT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("GetImportExport",function(Data,Callback)
	Callback(vSERVER.Purchase(Data.Mode,true))
end)