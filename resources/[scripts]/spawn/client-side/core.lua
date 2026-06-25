-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("spawn")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Camera = nil
local Spawn = false
local Characters = {}
local Creation = false
local Cooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Config",function(Data,Callback)
	if Spawn then
		return false
	end

	local Pid = PlayerId()
	local Model = 1885233650
	local Ped = PlayerPedId()
	local Table = vSERVER.Characters()

	RequestModel(Model)
	while not HasModelLoaded(Model) do
		Wait(100)
	end

	SetPlayerModel(Pid,Model)
	SetModelAsNoLongerNeeded(Model)

	local Ped = PlayerPedId()
	SetEntityCoords(Ped,242.77,-392.07,45.3,false,false,false,false)
	SetEntityHeading(Ped,337.33)
	SetEntityVisible(Ped,false)
	NetworkSetFriendlyFireOption(false)
	FreezeEntityPosition(Ped,true)
	SetEntityInvincible(Ped,true)
	ClearPedTasksImmediately(Ped)
	SetEntityHealth(Ped,100)
	DisplayRadar(false)
	DoScreenFadeIn(0)

	Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)
	SetCamCoord(Camera,243.55,-389.67,46.25)
	SetCamRot(Camera,0.0,0.0,157.0,2)
	SetCamActive(Camera,true)

	RenderScriptCams(true,false,0,true,true)

	Characters = Table.Characters
	if #Characters > 0 then
		Customization(Characters[1])
	end

	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()
	SetNuiFocus(true,true)
	Spawn = true

	Callback(Table)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CharacterChosen",function(Data,Callback)
	if Cooldown > GetGameTimer() then
		Callback(false)
		return
	end

	Cooldown = GetGameTimer() + 1500

	if vSERVER.CharacterChosen(Data.Passport) then
		SendNUIMessage({ Action = "Close" })
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- NEWCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("NewCharacter",function(Data,Callback)
	Callback(vSERVER.NewCharacter(Data.Name,Data.Lastname,Data.Gender))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SWITCHCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("SwitchCharacter",function(Data,Callback)
	for _,Character in pairs(Characters) do
		if Character.Passport == Data.Passport then
			Customization(Character,true)
			break
		end
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Finish")
AddEventHandler("spawn:Finish",function(Coords,Created)
	local Ped = PlayerPedId()
	if IsEntityVisible(Ped) then
		SetEntityVisible(Ped,false)
	end

	if Coords then
		table.insert(Locate,1,{ Coords = Coords, Name = "" })

		for Number,v in pairs(Locate) do
			local Street = GetStreetNameAtCoord(v.Coords.x,v.Coords.y,v.Coords.z)
			v.Name = Number == 1 and "Última Localização" or GetStreetNameFromHashKey(Street)
		end

		SetCamCoord(Camera,Coords.x,Coords.y,Coords.z + 1)
		SetCamRot(Camera,0.0,0.0,0.0,2)

		SendNUIMessage({ Action = "Location", Payload = Locate })
	else
		if DoesCamExist(Camera) then
			RenderScriptCams(false,false,0,true,true)
			DestroyCam(Camera,false)
			Camera = nil
		end

		SendNUIMessage({ Action = "Close" })
		SetNuiFocus(false,false)

		if Created then
			Creation = Created
			exports.barbershop:Creation(Created)
		else
			SetTimeout(5000,function()
				SetEntityVisible(Ped,true)
				SetEntityInvincible(Ped,false)
				FreezeEntityPosition(Ped,false)

				Wait(1000)

				LocalPlayer.state:set("Active",true,true)
				TriggerServerEvent("vRP:WaitCharacters")
				TriggerEvent("hud:Active",true)
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Spawn",function(Data,Callback)
	if DoesCamExist(Camera) then
		RenderScriptCams(false,false,0,true,true)
		DestroyCam(Camera,false)
		Camera = nil
	end

	SendNUIMessage({ Action = "Close" })
	SetNuiFocus(false,false)

	if not Creation then
		SetTimeout(5000,function()
			local Ped = PlayerPedId()

			SetEntityVisible(Ped,true)
			SetEntityInvincible(Ped,false)
			FreezeEntityPosition(Ped,false)

			Wait(1000)

			LocalPlayer.state:set("Active",true,true)
			TriggerServerEvent("vRP:WaitCharacters")
			TriggerEvent("hud:Active",true)
			TriggerEvent("referrals:Open")
		end)
	else
		TriggerEvent("referrals:Open")
		TriggerEvent("hud:Active",true)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Chosen",function(Data,Callback)
	local Index = Data.Index
	local Selected = Locate[Index]
	if not Selected then
		Callback(false)
		return false
	end

	local Ped = PlayerPedId()
	local Coords = Selected.Coords

	SetEntityCoords(Ped,Coords.x,Coords.y,Coords.z - 0.75,false,false,false,false)
	SetCamCoord(Camera,Coords.x,Coords.y,Coords.z + 1.0)
	SetCamRot(Camera,0.0,0.0,0.0,2)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CUSTOMIZATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Customization(Table,Check)
	local Model = GetHashKey(Table.Skin)

	RequestModel(Model)
	while not HasModelLoaded(Model) do
		Wait(100)
	end

	local Pid = PlayerId()
	local Ped = PlayerPedId()
	if not Check or GetEntityModel(Ped) ~= Model then
		SetPlayerModel(Pid,Model)
		SetModelAsNoLongerNeeded(Model)
	end

	Ped = PlayerPedId()

	exports.skinshop:Apply(Table.Clothes,Ped)
	exports.barbershop:Apply(Table.Barber,Ped)
	exports.tattooshop:Apply(Table.Tattoos,Ped)

	FreezeEntityPosition(Ped,true)
	ClearPedTasksImmediately(Ped)
	SetEntityInvincible(Ped,true)

	if not IsEntityVisible(Ped) then
		SetEntityVisible(Ped,true)
	end

	local Anim = Anims[math.random(#Anims)]
	if Anim and LoadAnim(Anim.Dict) then
		TaskPlayAnim(Ped,Anim.Dict,Anim.Name,8.0,8.0,-1,1,1,0,0,0)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:INCREMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Increment")
AddEventHandler("spawn:Increment",function(Tables)
	for _,Coords in pairs(Tables) do
		Locate[#Locate + 1] = { Coords = Coords, Name = "" }
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REQUEST
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Request",function(Data,Callback)
	Callback(vSERVER.CheckPayment(Data.Passport))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:REQUEST
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Request")
AddEventHandler("spawn:Request",function()
	SendNUIMessage({ Action = "Request", Payload = SkinMontlyPrice })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURSCHASESLOT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("PurchaseSlot",function(Data,Callback)
	Callback(vSERVER.PurchaseSlot())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Notify")
AddEventHandler("spawn:Notify",function(Title,Message,Type)
	SendNUIMessage({ Action = "Notify", Payload = { Type = Type, Title = Title, Message = Message } })
end)