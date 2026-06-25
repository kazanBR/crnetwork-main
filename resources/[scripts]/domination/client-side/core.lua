-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("domination")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Poly = nil
local Alpha = nil
local Bliped = nil
local InsideZone = false
local InsideMarked = false
local CurrentLocation = false
local Cooldown = GetGameTimer()
local FeedCooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETUPPOLY
-----------------------------------------------------------------------------------------------------------------------------------------
function SetupPoly(Location)
	if Poly then
		Poly:destroy()
		Poly = nil
	end

	local Data = Locations[Location]
	if not Data then return end

	Poly = PolyZone:Create(Data.Poly,{
		name = Data.Name,
		debugPoly = Data.PolyDisplay,
		minZ = Data.Blip.z - Data.PolyWeight,
		maxZ = Data.Blip.z + Data.PolyWeight
	})

	Poly:onPlayerInOut(function(Inside)
		InsideZone = Inside
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(1000)

		if not CurrentLocation then
			goto Continue
		end

		local Location = Locations[CurrentLocation]
		if not Location or not Location.SurvivalDistance then
			goto Continue
		end

		local Ped = PlayerPedId()
		if not DoesEntityExist(Ped) then
			goto Continue
		end

		if #(GetEntityCoords(Ped) - Location.Blip) > Location.SurvivalDistance then
			if InsideMarked then
				InsideMarked = false
				vSERVER.Progress("Exit")
				TriggerEvent("domination:Close")
			end

			goto Continue
		end

		if not InsideMarked then
			InsideMarked = true
			vSERVER.Progress("Enter")

			if DeleteVehicle then
				local Vehicle = GetVehiclePedIsUsing(Ped)
				if DoesEntityExist(Vehicle) then
					TriggerEvent("garages:Delete",Vehicle)
				end
			end
		end

		if GetEntityHealth(Ped) <= 100 then
			TriggerServerEvent("player:Survival")
			exports.survival:FinishSurvival()

			goto Continue
		end

		if InsideZone and not IsPedInAnyVehicle(Ped) and GetGameTimer() >= Cooldown then
			Cooldown = GetGameTimer() + (PointSeconds * 1000)

			if CurrentLocation then
				vSERVER.Pontuation(CurrentLocation)
			end
		end

		::Continue::
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOMINATION:START
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("domination:Start")
AddEventHandler("domination:Start",function(Location)
	InsideZone = false
	InsideMarked = false
	CurrentLocation = Location
	SetupPoly(Location)

	if DoesBlipExist(Bliped) then
		RemoveBlip(Bliped)
		Bliped = nil
	end

	if DoesBlipExist(Alpha) then
		RemoveBlip(Alpha)
		Alpha = nil
	end

	local Select = Locations[Location]
	if Select and Select.Blip then
		Bliped = AddBlipForCoord(Select.Blip)
		SetBlipSprite(Bliped,303)
		SetBlipDisplay(Bliped,4)
		SetBlipAsShortRange(Bliped,true)
		SetBlipColour(Bliped,49)
		SetBlipScale(Bliped,1.0)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Dominação: "..(Select.Name or Location))
		EndTextCommandSetBlipName(Bliped)

		Alpha = AddBlipForRadius(Select.Blip,(Select.SurvivalDistance or 500) + 0.0)
		SetBlipColour(Alpha,49)
		SetBlipAlpha(Alpha,150)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOMINATION:FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("domination:Finish")
AddEventHandler("domination:Finish",function(Winner)
	CurrentLocation = false

	if InsideZone then
		vSERVER.Progress("Exit")
		InsideZone = false
	end

	if InsideMarked then
		TriggerEvent("domination:Close")
		InsideMarked = false
	end

	if Poly then
		Poly:destroy()
		Poly = nil
	end

	if DoesBlipExist(Bliped) then
		RemoveBlip(Bliped)
	end

	if DoesBlipExist(Alpha) then
		RemoveBlip(Alpha)
	end

	Bliped = nil
	Alpha = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GAMEEVENTTRIGGERED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("gameEventTriggered",function(Event,Message)
	local CurrentTimer = GetGameTimer()
	if Event ~= "CEventNetworkEntityDamage" or not InsideMarked or LocalPlayer.state.Arena or LocalPlayer.state.Death or LocalPlayer.state.Crawl or FeedCooldown > CurrentTimer then
		return false
	end

	local Ped = PlayerPedId()
	local Weaponed = Message[7]
	local Victim,Attacker = Message[1],Message[2]
	if Victim ~= Ped or Victim == Attacker or not IsEntityAPed(Victim) or GetEntityHealth(Victim) > 100 then
		return false
	end

	local Index = NetworkGetPlayerIndexFromPed(Attacker)
	if Index and NetworkIsPlayerConnected(Index) then
		FeedCooldown = CurrentTimer + 10000
		TriggerServerEvent("domination:KillFeed",GetPlayerServerId(Index))
	end
end)