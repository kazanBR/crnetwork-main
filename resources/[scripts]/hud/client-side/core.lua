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
Creative = {}
Tunnel.bindInterface("hud",Creative)
vSERVER = Tunnel.getInterface("hud")
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBAL
-----------------------------------------------------------------------------------------------------------------------------------------
Radar = false
Display = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Hood = false
local Gemstone = 0
local Pause = false
local Road = "Roads"
local Underwater = false
local Crossing = "Crossing"
-----------------------------------------------------------------------------------------------------------------------------------------
-- PRINCIPAL
-----------------------------------------------------------------------------------------------------------------------------------------
local Armour = 0
local Health = 200
-----------------------------------------------------------------------------------------------------------------------------------------
-- THIRST
-----------------------------------------------------------------------------------------------------------------------------------------
local Thirst = 100
local ThirstTimer = 0
local ThirstAmount = 180000
local ThirstDelay = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
local Hunger = 100
local HungerTimer = 0
local HungerAmount = 180000
local HungerDelay = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- STRESS
-----------------------------------------------------------------------------------------------------------------------------------------
local Stress = 0
local StressTimer = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- WANTED
-----------------------------------------------------------------------------------------------------------------------------------------
local Wanted = 0
local WantedMax = 0
local WantedTimer = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPOSE
-----------------------------------------------------------------------------------------------------------------------------------------
local Repose = 0
local ReposeMax = 0
local ReposeTimer = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- LUCK
-----------------------------------------------------------------------------------------------------------------------------------------
local Luck = 0
local LuckTimer = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEXTERITY
-----------------------------------------------------------------------------------------------------------------------------------------
local Dexterity = 0
local DexterityTimer = GetNetworkTime()
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	LoadMovement("move_m@injured")

	while true do
		if LocalPlayer.state.Active then
			local Pid = PlayerId()
			local Ped = PlayerPedId()

			if IsPauseMenuActive() then
				if not Pause and Display then
					Pause = true
					SendNUIMessage({ Action = "Body", Payload = false })
				end
			else
				if Display then
					if Pause then
						SendNUIMessage({ Action = "Body", Payload = true })
						Pause = false
					end

					local Coords = GetEntityCoords(Ped)
					local Armouring = GetPedArmour(Ped)
					local Healing = GetEntityHealth(Ped) - 100
					local MinRoad,MinCross = GetStreetNameAtCoord(Coords.x,Coords.y,Coords.z)
					local FullRoad = GetStreetNameFromHashKey(MinRoad)
					local FullCross = GetStreetNameFromHashKey(MinCross)

					if GetEntityMaxHealth(Ped) ~= 200 then
						if Health ~= parseInt(Healing * 0.66) then
							Healing = parseInt(Healing * 0.66)

							if Healing > 100 then
								Healing = 100
							end

							SendNUIMessage({ Action = "Health", Payload = Healing })
							Health = Healing
						end
					else
						if Healing > 100 then
							SetEntityHealth(Ped,200)
							Healing = 100
						end

						if Health ~= Healing then
							SendNUIMessage({ Action = "Health", Payload = Healing })
							Health = Healing
						end

						if not IsPedSwimming(Ped) then
							if Healing <= 30 and GetPedMovementClipset(Ped) ~= -650503762 then
								LocalPlayer.state:set("Walk",false,false)
								SetPedMovementClipset(Ped,"move_m@injured",0.5)
							elseif Healing > 30 and GetPedMovementClipset(Ped) == -650503762 then
								LocalPlayer.state:set("Walk",false,false)
							end
						end
					end

					if Armour ~= Armouring then
						SendNUIMessage({ Action = "Armour", Payload = Armouring })
						Armour = Armouring
					end

					if FullRoad ~= "" and Road ~= FullRoad then
						SendNUIMessage({ Action = "Road", Payload = FullRoad })
						Road = FullRoad
					end

					if FullCross ~= "" and Crossing ~= FullCross then
						SendNUIMessage({ Action = "Crossing", Payload = FullCross })
						Crossing = FullCross
					end

					SendNUIMessage({ Action = "Clock", Payload = { GlobalState.Hours,GlobalState.Minutes } })
				end
			end

			if Luck > 0 and LuckTimer <= GetNetworkTime() then
				Luck = Luck - 1
				LuckTimer = GetNetworkTime() + 1000

				SendNUIMessage({ Action = "Luck", Payload = Luck })
			end

			if Dexterity > 0 and DexterityTimer <= GetNetworkTime() then
				Dexterity = Dexterity - 1
				DexterityTimer = GetNetworkTime() + 1000

				SendNUIMessage({ Action = "Dexterity", Payload = Dexterity })
			end

			if Wanted > 0 and WantedTimer <= GetNetworkTime() then
				Wanted = Wanted - 1
				WantedTimer = GetNetworkTime() + 1000

				SendNUIMessage({ Action = "Wanted", Payload = { Wanted,WantedMax } })
			end

			if Repose > 0 and ReposeTimer <= GetNetworkTime() then
				Repose = Repose - 1
				ReposeTimer = GetNetworkTime() + 1000

				SendNUIMessage({ Action = "Repose", Payload = { Repose,ReposeMax } })
			end

			if not LocalPlayer.state.Banned and not LocalPlayer.state.Prison and GetEntityHealth(Ped) > 100 then
				if Hunger <= 10 and HungerTimer <= GetNetworkTime() then
					ApplyDamageToPed(Ped,1,false)
					HungerTimer = GetNetworkTime() + 60000
					TriggerEvent("Notify","Alimentação","Sofrendo com a <b>fome</b>.","fome",2500)
				end

				if Thirst <= 10 and ThirstTimer <= GetNetworkTime() then
					ApplyDamageToPed(Ped,1,false)
					ThirstTimer = GetNetworkTime() + 60000
					TriggerEvent("Notify","Hidratação","Sofrendo com a <b>sede</b>.","sede",2500)
				end

				if Stress ~= 999 and Stress >= 50 and StressTimer <= GetNetworkTime() then
					AnimpostfxPlay("MenuMGIn")
					SetTimeout(1000,function()
						AnimpostfxStop("MenuMGIn")
					end)

					StressTimer = GetNetworkTime() + 30000
				end

				if Hunger > 0 and HungerDelay <= GetNetworkTime() then
					Hunger = Hunger - 1
					vRPS.DowngradeHunger()
					HungerDelay = GetNetworkTime() + HungerAmount

					SendNUIMessage({ Action = "Hunger", Payload = Hunger })
				end

				if Thirst > 0 and ThirstDelay <= GetNetworkTime() then
					Thirst = Thirst - 1
					vRPS.DowngradeThirst()
					ThirstDelay = GetNetworkTime() + ThirstAmount

					SendNUIMessage({ Action = "Thirst", Payload = Thirst })
				end

				if IsPedSwimmingUnderWater(Ped) then
					local IsScuba = GetPedConfigFlag(Ped,135)
					local Remaining = GetPlayerUnderwaterTimeRemaining(Pid)
					local Calculated = (Remaining / (IsScuba and 10000 or 10) * 100)

					SendNUIMessage({ Action = "Oxygen", Payload = Calculated })
					Underwater = true
				else
					if Underwater then
						SendNUIMessage({ Action = "Oxygen" })
						Underwater = false
					end
				end
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITYVELOCITY
-----------------------------------------------------------------------------------------------------------------------------------------
function EntityVelocity(Ped)
	local Velocity = GetEntityVelocity(Ped)

	return math.min(math.sqrt(Velocity.x * Velocity.x + Velocity.y * Velocity.y + Velocity.z * Velocity.z),10)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Passport",("player:%s"):format(LocalPlayer.state.Source),function(Name,Key,Value)
	SendNUIMessage({ Action = "Passport", Payload = Value })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Players",nil,function(Name,Key,Value)
	SendNUIMessage({ Action = "Players", Payload = Value })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Safezone",("player:%s"):format(LocalPlayer.state.Source),function(Name,Key,Value)
	SendNUIMessage({ Action = "Safezone", Payload = (Value and true or false) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:VOIP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("hud:Voip",function(Number)
	local Target = { "BAIXO","NORMAL","MÉDIO","ALTO" }

	SendNUIMessage({ Action = "Voip", Payload = Target[Number] })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:VOICE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("hud:Voice",function(Status)
	SendNUIMessage({ Action = "Voice", Payload = Status })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:WANTED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Wanted")
AddEventHandler("hud:Wanted",function(Seconds)
	WantedMax = Seconds
	Wanted = Seconds
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WANTED
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Wanted",function()
	return Wanted > 0 and true or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:REPOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Repose")
AddEventHandler("hud:Repose",function(Seconds)
	ReposeMax = Seconds
	Repose = Seconds
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPOSE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Repose",function()
	return Repose > 0 and true or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:VIDEO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Video")
AddEventHandler("hud:Video",function(Code)
	if Code then
		SetNuiFocus(true,false)
		SendNUIMessage({ Action = "Body", Payload = true })
		SendNUIMessage({ Action = "Video", Payload = Code })
	else
		SendNUIMessage({ Action = "Body", Payload = Display })
		SendNUIMessage({ Action = "Video" })
		SetNuiFocus(false,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:ACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("hud:Active",function(Status)
	Display = Status
	SendNUIMessage({ Action = "Body", Payload = Display })

	if IsMinimapRendering() then
		DisplayRadar(false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("hud",function()
	Display = not Display
	SendNUIMessage({ Action = "Body", Payload = Display })

	if IsMinimapRendering() then
		DisplayRadar(false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:MENU
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("hud:Menu",function()
	SendNUIMessage({ Action = "Menu", Payload = true })
	SetNuiFocus(true,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSEMENU
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CloseMenu",function(Data,Callback)
	ExecuteCommand("PauseBreak")
	SetNuiFocus(false,false)

	Callback(true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:RADAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Radar")
AddEventHandler("hud:Radar",function()
	Radar = not Radar

	TriggerEvent("inventory:Notify","Sucesso","Mapa adaptativo "..(Radar and "ativado" or "desativado")..".","verde")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:RADAROFF
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Radaroff")
AddEventHandler("hud:Radaroff",function()
	Radar = false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROGRESS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("Progress")
AddEventHandler("Progress",function(Message,Timer)
	SendNUIMessage({ Action = "Progress", Payload = Timer - 300 })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:THIRST
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Thirst")
AddEventHandler("hud:Thirst",function(Number)
	if Thirst ~= Number then
		SendNUIMessage({ Action = "Thirst", Payload = Number })
		Thirst = Number
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:HUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Hunger")
AddEventHandler("hud:Hunger",function(Number)
	if Hunger ~= Number then
		SendNUIMessage({ Action = "Hunger", Payload = Number })
		Hunger = Number
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:STRESS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Stress")
AddEventHandler("hud:Stress",function(Number)
	if Stress ~= Number then
		SendNUIMessage({ Action = "Stress", Payload = Number })
		Stress = Number
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:LUCK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Luck")
AddEventHandler("hud:Luck",function(Seconds)
	Luck = Seconds
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:DEXTERITY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Dexterity")
AddEventHandler("hud:Dexterity",function(Seconds)
	Dexterity = Seconds
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:ADDGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:AddGemstone")
AddEventHandler("hud:AddGemstone",function(Number)
	Gemstone = Gemstone + Number

	SendNUIMessage({ Action = "Gemstone", Payload = Gemstone })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:REMOVEGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:RemoveGemstone",function(Number)
	Gemstone = Gemstone - Number

	if Gemstone < 0 then
		Gemstone = 0
	end

	SendNUIMessage({ Action = "Gemstone", Payload = Gemstone })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Hunger",function(Value)
	HungerAmount = Value
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THIRST
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Thirst",function(Value)
	ThirstAmount = Value
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:HOOD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:Hood",function()
	if Hood then
		DoScreenFadeIn(2500)
		Hood = false
	else
		DoScreenFadeOut(0)
		Hood = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOMINATION:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("domination:Update",function(Data,Max)
	SendNUIMessage({ Action = "Domination", Payload = { Data = Data, Max = Max } })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOMINATION:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("domination:Close",function()
	SendNUIMessage({ Action = "Domination" })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOMINATION:KILLFEED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("domination:KillFeed",function(Attacker,Victim)
	SendNUIMessage({ Action = "Killfeed", Payload = { Killer = Attacker, Victim = Victim } })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HUD:DISPLAYEXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hud:DisplayExperience",function(Type,Amount)
	SendNUIMessage({ Action = Type, Payload = Amount })
end)