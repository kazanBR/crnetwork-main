-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("taxi")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Blip = nil
local Current = nil
local Service = false
local Walking = false
local Locate = "South"
local PaymentActive = false
local Lasted = math.random(#Locations[Locate])
local Selected = math.random(#Locations[Locate])
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVETAXIPED
-----------------------------------------------------------------------------------------------------------------------------------------
local function RemoveTaxiPed(Ped)
	if not Ped or not DoesEntityExist(Ped) then
		return false
	end

	SetPedKeepTask(Ped,false)
	SetBlockingOfNonTemporaryEvents(Ped,false)

	if IsPedInAnyVehicle(Ped) then
		TaskLeaveAnyVehicle(Ped,0,0)

		local Timeout = GetGameTimer() + 3000
		while IsPedInAnyVehicle(Ped) and GetGameTimer() <= Timeout do
			Wait(100)
		end
	end

	SetEntityAsMissionEntity(Ped,false,false)

	local Net = NetworkGetNetworkIdFromEntity(Ped)
	if Net and Net > 0 then
		TriggerServerEvent("DeletePed",Net)
	else
		DeleteEntity(Ped)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESETSERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
local function ResetService()
	Walking = false
	PaymentActive = false

	if DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	if Current then
		RemoveTaxiPed(Current)
		Current = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISVALIDTAXI
-----------------------------------------------------------------------------------------------------------------------------------------
local function IsValidTaxi(Vehicle)
	return DoesEntityExist(Vehicle) and GetEntityModel(Vehicle) == `taxi`
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETRANDOMLOCATION
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetRandomLocation()
	local NewSelected

	repeat
		NewSelected = math.random(#Locations[Locate])
	until NewSelected ~= Lasted

	Lasted = NewSelected

	return NewSelected
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKEDPASSENGER
-----------------------------------------------------------------------------------------------------------------------------------------
local function MarkedPassenger()
	if DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	local Coords = Locations[Locate][Selected].Vehicle

	Blip = AddBlipForCoord(Coords.x,Coords.y,Coords.z)
	SetBlipSprite(Blip,1)
	SetBlipDisplay(Blip,4)
	SetBlipAsShortRange(Blip,true)
	SetBlipColour(Blip,77)
	SetBlipScale(Blip,0.75)
	SetBlipRoute(Blip,true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Passageiro")
	EndTextCommandSetBlipName(Blip)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEPASSENGER
-----------------------------------------------------------------------------------------------------------------------------------------
local function CreatePassenger(Vehicle)
	if Walking or PaymentActive then
		return false
	end

	if not IsValidTaxi(Vehicle) then
		return false
	end

	if not IsVehicleSeatFree(Vehicle,2,false) then
		TriggerEvent("Notify","Taxista","O banco do passageiro está ocupado.","amarelo",5000)
		return false
	end

	ResetService()

	local PedCoords = Locations[Locate][Selected].Ped
	local Model = Models[math.random(#Models)]
	if not LoadModel(Model) then
		return false
	end

	local Ground,GroundZ = GetGroundZFor_3dCoord(PedCoords.x,PedCoords.y,PedCoords.z + 10.0,false)
	if Ground then
		PedCoords = vector3(PedCoords.x,PedCoords.y,GroundZ)
	end

	Current = CreatePed(4,Model,PedCoords.x,PedCoords.y,PedCoords.z,0.0,true,true)
	if not Current or not DoesEntityExist(Current) then
		Current = nil
		return false
	end

	SetEntityAsMissionEntity(Current,true,true)
	SetBlockingOfNonTemporaryEvents(Current,true)
	SetPedKeepTask(Current,true)
	SetEntityInvincible(Current,true)
	SetPedCanRagdoll(Current,false)
	SetPedFleeAttributes(Current,0,false)
	SetPedCombatAttributes(Current,17,true)
	SetPedDiesWhenInjured(Current,false)
	SetPedSeeingRange(Current,0.0)
	SetPedHearingRange(Current,0.0)

	DecorSetBool(Current,"CREATIVE_PED",true)

	Walking = true

	TaskEnterVehicle(Current,Vehicle,15000,2,1.0,1,0)

	local Entered = false
	local Timeout = GetGameTimer() + 15000

	while GetGameTimer() <= Timeout do
		if not DoesEntityExist(Current) then
			break
		end

		if not DoesEntityExist(Vehicle) then
			break
		end

		if not IsPedInAnyVehicle(PlayerPedId()) then
			break
		end

		if GetVehiclePedIsUsing(PlayerPedId()) ~= Vehicle then
			break
		end

		if IsPedDeadOrDying(Current) then
			break
		end

		if IsPedInVehicle(Current,Vehicle,false) then
			Entered = true
			break
		end

		Wait(500)
	end

	Walking = false

	if not Entered then
		RemoveTaxiPed(Current)
		TriggerEvent("Notify","Taxista","O passageiro não conseguiu entrar no veículo.","amarelo",5000)
		Current = nil

		return false
	end

	PaymentActive = true
	Selected = GetRandomLocation()
	MarkedPassenger()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISHRACE
-----------------------------------------------------------------------------------------------------------------------------------------
local function FinishRace(Vehicle)
	if not PaymentActive then
		return false
	end

	if not Current or not DoesEntityExist(Current) then
		PaymentActive = false
		return false
	end

	TaskLeaveVehicle(Current,Vehicle,64)
	local Timeout = GetGameTimer() + 7000

	while GetGameTimer() <= Timeout do
		if not DoesEntityExist(Current) then
			break
		end

		if not IsPedInVehicle(Current,Vehicle,false) then
			break
		end

		Wait(250)
	end

	if DoesEntityExist(Current) then
		TaskWanderStandard(Current,10.0,10)
		local Ped = Current

		SetTimeout(10000,function()
			RemoveTaxiPed(Ped)
		end)
	end

	vSERVER.Payment(Locate,Selected)

	Current = nil
	PaymentActive = false
	Selected = GetRandomLocation()

	MarkedPassenger()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTTHREAD
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Index,v in pairs(Init) do
		exports.target:AddBoxZone("WorkTaxi:"..Index,v.xyz,0.75,0.75,{
			name = "WorkTaxi:"..Index,
			heading = v.w,
			minZ = v.z - 1.0,
			maxZ = v.z + 1.0
		},{
			shop = Index,
			Distance = 1.75,
			options = {
				{
					event = "taxi:Init",
					label = "Iniciar Expediente",
					tunnel = "client"
				}
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAXI:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("taxi:Init",function(Location)
	ResetService()

	if Service then
		Service = false
		exports.target:LabelText("WorkTaxi:"..Locate,"Iniciar Expediente")
		TriggerEvent("Notify","Central de Empregos","Você finalizou seu expediente.","default",5000)

		return false
	end

	Service = true
	Locate = Location
	exports.target:LabelText("WorkTaxi:"..Locate,"Finalizar Expediente")
	TriggerEvent("Notify","Central de Empregos","Você iniciou seu expediente de taxista.","default",5000)
	MarkedPassenger()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAINTHREAD
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 1000
		if Service then
			local Ped = PlayerPedId()
			if not IsPedDeadOrDying(Ped) and IsPedInAnyVehicle(Ped) then
				local Vehicle = GetVehiclePedIsUsing(Ped)

				if IsValidTaxi(Vehicle) then
					local Coords = GetEntityCoords(Ped)
					local Target = Locations[Locate][Selected].Vehicle
					local Distance = #(Coords - Target)

					if Distance <= 100.0 then
						TimeDistance = 1

						DrawMarker(21,Target.x,Target.y,Target.z,0.0,0.0,0.0,0.0,180.0,130.0,1.5,1.5,1.0,88,101,242,175,false,true,0,true)

						if Distance <= 2.5 and IsControlJustPressed(1,38) then
							if PaymentActive then
								FinishRace(Vehicle)
							else
								CreatePassenger(Vehicle)
							end
						end
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONRESOURCESTOP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onResourceStop",function(Resource)
	if Resource ~= GetCurrentResourceName() then
		return false
	end

	ResetService()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:ACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vRP:Active")
AddEventHandler("vRP:Active",function()
	ResetService()

	Service = false
end)