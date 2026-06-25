-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
vSERVER = Tunnel.getInterface("inventory")
Tunnel.bindInterface("skinweapon",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = 1
local Camera = nil
local Gemstone = 0
local Objects = nil
local WeaponRotation = nil
local Coords = vec3(235.86,-977.57,-98.80)
local Default = vec3(234.86,-977.57,-98.65)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYCAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
function DestroyCamera()
	if Camera and DoesCamExist(Camera) then
		RenderScriptCams(false,true,250,true,true)
		DestroyCam(Camera,false)
		Camera = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYPREVIEW
-----------------------------------------------------------------------------------------------------------------------------------------
function DestroyPreview()
	if Objects and DoesEntityExist(Objects) then
		DeleteEntity(Objects)
		SetModelAsNoLongerNeeded(GetEntityModel(Objects))
		Objects = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOADMODELS
-----------------------------------------------------------------------------------------------------------------------------------------
function LoadModels(Model)
	if not IsModelInCdimage(Model) then
		return false
	end

	if HasModelLoaded(Model) then
		return true
	end

	RequestModel(Model)
	while not HasModelLoaded(Model) do
		Wait(0)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINWEAPON:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("skinweapon:Open")
AddEventHandler("skinweapon:Open",function()
	DestroyCamera()
	DestroyPreview()

	NewLoadSceneStartSphere(Coords,100.0,2)
	while not IsNewLoadSceneLoaded() do
		Wait(0)
	end

	Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)
	SetCamCoord(Camera,Default)
	SetCamRot(Camera,0.0,0.0,-90.0,2)
	SetCamFov(Camera,60.0)
	SetCamActive(Camera,true)

	RenderScriptCams(true,false,0,true,true)

	SendNUIMessage({ Action = "Gemstone", Payload = Gemstone })
	SendNUIMessage({ Action = "Open" })
	TriggerEvent("hud:Active",false)
	SetNuiFocus(true,true)
	UserSkins()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	TriggerEvent("hud:Active",true)
	SetNuiFocus(false,false)
	NewLoadSceneStop()
	DestroyPreview()
	DestroyCamera()

	ExecuteCommand("PauseBreak")

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Page",function(Data,Callback)
	if Data.Page == "Skins" then
		UserSkins()
	elseif Data.Page == "Store" then
		for Number = 1,#Weapons do
			if Weapons[Number] and not Weapons[Number].hide then
				CreateObjects(Number)
				break
			end
		end

		SendNUIMessage({ Action = "Store", Payload = Weapons })
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Transfer",function(Data,Callback)
	local Number = Data.Skin
	if Number and vSERVER.TransferSkin(Data.Passport,Number,Weapons[Number].weapon,Weapons[Number].component) then
		SendNUIMessage({ Action = "Gemstone", Payload = Gemstone })
		UserSkins()
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Buy",function(Data,Callback)
	if vSERVER.BuySkin(Weapons[Data.Skin]) then
		SendNUIMessage({ Action = "Gemstone", Payload = Gemstone })
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Active",function(Data,Callback)
	local Number = Data.Skin
	local Weapon = Weapons[Number].weapon
	local Component = Weapons[Number].component

	Callback(vSERVER.ActiveSkin(Weapon,Component))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Inactive",function(Data,Callback)
	local Number = Data.Skin
	local Weapon = Weapons[Number].weapon
	local Component = Weapons[Number].component

	Callback(vSERVER.InactiveSkin(Weapon,Component))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mouse",function(Data,Callback)
	if not Objects or not DoesEntityExist(Objects) then
		return false
	end

	if Weapons[Active] and Weapons[Active].rotate and WeaponRotation then
		SetEntityRotation(Objects,WeaponRotation[1] + (Data.Y / 200),WeaponRotation[2],WeaponRotation[3] - (Data.X / 200))
		WeaponRotation = GetEntityRotation(Objects)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SELECTED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Selected",function(Data,Callback)
	CreateObjects(Data.Skin)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERSKINS
-----------------------------------------------------------------------------------------------------------------------------------------
function UserSkins()
	local Skins = {}
	local Selected = false
	local Consult = vSERVER.UserSkins()
	if Consult then
		for Number,v in pairs(Consult.List) do
			local Save = #Skins + 1
			local Number = parseInt(Number)

			Skins[Save] = Weapons[Number]

			local Weapon = Weapons[Number].weapon
			if Consult[Weapon] and Weapons[Number].component == Consult[Weapon] then
				Skins[Save].active = true
			else
				Skins[Save].active = false
			end

			if not Selected then
				Selected = Skins[Save].id
			end
		end
	end

	if Selected then
		CreateObjects(Selected)
	elseif Objects and DoesEntityExist(Objects) then
		DestroyPreview()
	end

	SendNUIMessage({ Action = "Skins", Payload = Skins })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
function CreateObjects(Number)
	if not Weapons[Number] then
		return false
	end

	DestroyPreview()

	local Data = Weapons[Number]
	local Hash = GetHashKey(Data.component)
	local Model = GetWeaponComponentTypeModel(Hash)
	if not LoadModels(Model) then
		return false
	end

	Objects = CreateObject(Model,Coords.x - Data.offset.x,Coords.y - Data.offset.y,Coords.z - Data.offset.z,false,false,false)

	SetEntityRotation(Objects,Data.rotation)
	FreezeEntityPosition(Objects,true)
	SetEntityAlpha(Objects,0,false)

	CreateThread(function()
		local Alpha = 0
		while Alpha < 255 do
			Alpha = math.min(255,Alpha + 15)
			SetEntityAlpha(Objects,Alpha,false)
			Wait(15)
		end
	end)

	PlaySoundFrontend(-1,"SELECT","HUD_FRONTEND_DEFAULT_SOUNDSET",true)
	WeaponRotation = GetEntityRotation(Objects)
	Active = Number
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:ADDGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:AddGemstone")
AddEventHandler("hud:AddGemstone",function(Number)
	Gemstone = Gemstone + Number
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:REMOVEGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:RemoveGemstone")
AddEventHandler("hud:RemoveGemstone",function(Number)
	Gemstone = Gemstone - Number

	if Gemstone < 0 then
		Gemstone = 0
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEAPONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Weapons()
	return Weapons
end