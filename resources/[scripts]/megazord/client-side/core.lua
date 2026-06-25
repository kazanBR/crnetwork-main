-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("megazord")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Weapon = ""
local Injected = {}
local Visible = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- GAMEEVENTTRIGGERED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("gameEventTriggered",function(Event,Message)
	if Event ~= "CEventNetworkPlayerCollectedPickup" then
		return
	end

	if not Injected.Pickup then
		vSERVER.Warning("Pickups",true)
		Injected.Pickup = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INITIALCHARACTERSYSTEMCOMPLETE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("InitialCharacterSystemComplete",function()
	CreateThread(function()
		while true do
			local Pid = PlayerId()
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)
			local _,CurrentWeapon = GetCurrentPedWeapon(Ped)

			if IsPedArmed(Ped,7) and not Injected.Weaspawn and Weapon == "" then
				vSERVER.Warning("Spawn Weapons",true)
				Injected.Weaspawn = true
			end

			if LocalPlayer.state.Active and not LocalPlayer.state.Admin and Visible and (not IsEntityVisible(Ped) or GetEntityAlpha(Ped) ~= 255) then
				vSERVER.Warning("Entity Visible")
			end

			if not Injected.Lockon and GetLockonDistanceOfCurrentPedWeapon(Ped) > 250.0 then
				vSERVER.Warning("Lock Player",true)
				Injected.Lockon = true
			end

			for _,Texture in pairs(Textures) do
				if HasStreamedTextureDictLoaded(Texture) and not Injected["Texture-"..Texture] then
					vSERVER.Warning("Texture-"..Texture,true)
					Injected["Texture-"..Texture] = true
				end
			end

			if not Injected.SuperJumper and IsPedDoingBeastJump(Ped) then
				vSERVER.Warning("Super Jumper",true)
				Injected.SuperJumper = true
			end

			if not Injected.Ragdoll and IsPedRagdoll(Ped) and not CanPedRagdoll(Ped) and not IsPedInAnyVehicle(Ped) and not IsEntityDead(Ped) and not IsPedJumpingOutOfVehicle(Ped) and not IsPedJacking(Ped) then
				vSERVER.Warning("Ragdoll Player",true)
				Injected.Ragdoll = true
			end

			if not Injected.Franklin and AnimpostfxIsRunning("CamPushInFranklin") then
				vSERVER.Warning("Franklin Modify",true)
				Injected.Franklin = true
			end

			if not Injected.DamageModify and not LocalPlayer.state.DamageModify and (GetPlayerWeaponDefenseModifier(Pid) > 1.0 or GetPlayerMeleeWeaponDefenseModifier(Pid) > 1.0 or GetPlayerMeleeWeaponDamageModifier(Pid) > 1.0 or GetPlayerVehicleDamageModifier(Pid) > 1.0 or GetPlayerWeaponDamageModifier(Pid) > 1.0 or GetWeaponDamageModifier(CurrentWeapon) > 1.0) then
				vSERVER.Warning("Weapons Damaged Modify",true)
				Injected.DamageModify = true
			end

			if not Injected.Spectate and not LocalPlayer.state.Spectate and NetworkIsInSpectatorMode() then
				vSERVER.Warning("Spectated",true)
				Injected.Spectate = true
			end

			if not Injected.AimAssist and GetLocalPlayerAimState() ~= 3 then
				vSERVER.Warning("AimAssist")
				Injected.AimAssist = true
			end

			if not Injected.AntiMenyoo and IsPlayerCamControlDisabled() ~= false then
				vSERVER.Warning("AntiMenyoo")
				Injected.AntiMenyoo = true
			end

			if not Injected.ChangePerson and GetPedConfigFlag(Ped,223,true) then
				vSERVER.Warning("Change Person",true)
				Injected.ChangePerson = true
			end

			if not Injected.NightVision and GetUsingnightvision() then
				vSERVER.Warning("Night Vision",true)
				Injected.NightVision = true
			end

			if not Injected.ThermalVision and GetUsingseethrough() then
				vSERVER.Warning("Thermal Vision",true)
				Injected.ThermalVision = true
			end

			if not Injected.TinyPed and GetPedConfigFlag(Ped,223,true) then
				vSERVER.Warning("Player Tiny",true)
				Injected.TinyPed = true
			end

			if IsPedInAnyVehicle(Ped) then
				local Vehicle = GetVehiclePedIsIn(Ped)
				if not Injected.VehicleHealth and IsVehicleDamaged(Vehicle) and GetEntityHealth(Vehicle) > GetEntityMaxHealth(Vehicle) then
					vSERVER.Warning("Vehicle Health Check")
					Injected.VehicleHealth = true
				end

				if not Injected.VehicleInvisible and IsVehicleVisible(Vehicle) then
					vSERVER.Warning("Vehicle Invisible",true)
					Injected.VehicleInvisible = true
				end
			end

			if GetProfileSetting(19) == 1 then
				if not Injected.Disparada then
					vSERVER.Warning("Modo Disparada")
					Injected.Disparada = true
				end

				SetPedToRagdoll(Ped,1000,1000,0,0,0,0)
			end

			Wait(1000)
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HACKEREVENTS
-----------------------------------------------------------------------------------------------------------------------------------------
for Number = 1,#HackerEvents do
	RegisterNetEvent(HackerEvents[Number])
	AddEventHandler(HackerEvents[Number],function()
		vSERVER.Warning("Hacker Events",true)
		Injected.HackerEvents = true
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONRESOURCESTART
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onResourceStart",function(Resource)
	if not Injected.Scripts and not GlobalState.Resource[Resource] then
		vSERVER.Warning("onResourceStart - "..Resource)
		Injected.Scripts = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONCLIENTRESOURCESTART
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onClientResourceStart",function(Resource)
	if not Injected.Scripts and not GlobalState.Resource[Resource] then
		vSERVER.Warning("onResourceStart - "..Resource)
		Injected.Scripts = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONCLIENTRESOURCESTOP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onClientResourceStop",function(Resource)
	if not Injected.Resources then
		vSERVER.Warning("onResourceStop - "..Resource)
		Injected.Resources = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONRESOURCESTOP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onResourceStop",function(Resource)
	if not Injected.Resources then
		vSERVER.Warning("onResourceStop - "..Resource)
		Injected.Resources = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MEGAZORD:SCREENSHOT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("megazord:Screenshot")
AddEventHandler("megazord:Screenshot",function(Webhook)
	exports["screenshot-basic"]:requestScreenshotUpload(Webhook,"files[]",{ encoding = "webp", quality = 0.75 })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEAPON
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Weapon",function(Name)
	Weapon = Name
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITYVISIBLE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("EntityVisible",function(Ped,Status)
	if Status then
		SetEntityVisible(Ped,true,true)
		Visible = true
	else
		Visible = false
		SetEntityVisible(Ped,false,true)
	end
end)