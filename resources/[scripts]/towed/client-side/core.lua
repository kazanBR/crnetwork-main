-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("towed")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Blip = nil
local Destiny = 1
local Vehicle = nil
local Locale = false
local Service = false
local ModelSelected = ""
local VehiclePlate = false
local LastSpawnRequest = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("towed:Init",function(Data)
	if Blip and DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	if not Data or not Locations or not Locations[Data] then
		return false
	end

	Service = not Service

	if not Service then
		TriggerEvent("Notify","Central de Empregos","Você acabou de finalizar sua jornada de trabalho, esperamos que tenha aprendido bastante hoje.","default",5000)
		exports.target:LabelText("Towed:"..Data,"Iniciar Expediente")
		VehiclePlate = nil
		Locale = false
		Destiny = nil

		return false
	end

	TriggerEvent("Notify","Central de Empregos","Você acabou de iniciar sua jornada de trabalho, lembre-se de equilibrar trabalho e descanso.","default",5000)
	exports.target:LabelText("Towed:"..Data,"Finalizar Expediente")
	Locale = Data

	local Located = Locations[Data]
	if not Models or #Models == 0 then
		return false
	end

	ModelSelected = Models[math.random(#Models)]
	Destiny = math.random(#Located)
	VehiclePlate = false

	MarkedVehicle()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:INATIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("towed:Inative")
AddEventHandler("towed:Inative", function(Plate)
	if not Plate or VehiclePlate ~= Plate then
		return false
	end

	if not Service or not Locale or not Locations or not Locations[Locale] then
		return false
	end

	if not Models or #Models == 0 then
		return false
	end

	ModelSelected = Models[math.random(#Models)]
	Destiny = math.random(#Locations[Locale])
	VehiclePlate = nil
	Vehicle = nil

	MarkedVehicle()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Name,v in pairs(Init) do
		exports.target:AddBoxZone("Towed:"..Name,v.xyz,0.75,0.75,{
			name = "Towed:"..Name,
			heading = v.w,
			minZ = v.z - 1.0,
			maxZ = v.z + 1.0
		},{
			shop = Name,
			Distance = 1.75,
			options = {
				{
					event = "towed:Init",
					label = "Iniciar Expediente",
					tunnel = "client"
				}
			}
		})
	end

	while true do
		local TimeDistance = 999

		if Service then
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)
			local Target = (Locale and Destiny and Locations[Locale] and Locations[Locale][Destiny]) and Locations[Locale][Destiny].xyz

			if not Vehicle and not VehiclePlate and Target then
				if #(Coords - Target) <= 50 then
					local CurrentTimer = GetGameTimer()
					if CurrentTimer >= LastSpawnRequest then
						LastSpawnRequest = CurrentTimer + 5000

						local Networked,Plate = vSERVER.Vehicle(ModelSelected,Locale,Destiny)
						if Networked then
							local Entity = LoadNetwork(Networked)
							local Cooldown = GetGameTimer() + 5000
							while not DoesEntityExist(Entity) do
								if GetGameTimer() >= Cooldown then
									break
								end

								Wait(100)
							end

							if DoesEntityExist(Entity) then
								if DoesBlipExist(Blip) then
									RemoveBlip(Blip)
									Blip = nil
								end

								Vehicle = Entity
								VehiclePlate = Plate

								SetVehicleEngineHealth(Vehicle,10.0)
								SetVehicleOnGroundProperly(Vehicle)
							end
						end
					end
				end
			elseif Vehicle and DoesEntityExist(Vehicle) then
				if not Entity(Vehicle).state.Tow then
					local VehicleCoords = GetEntityCoords(Vehicle)
					if #(Coords - VehicleCoords) <= 50 then
						TimeDistance = 1
						DrawMarker(22,VehicleCoords.x,VehicleCoords.y,VehicleCoords.z + 2.5,0.0,0.0,0.0,0.0,180.0,0.0,2.5,2.5,1.5,88,101,242,175,false,false,0,true)
					end
				end
			else
				Vehicle = nil
				VehiclePlate = nil
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKEDPASSENGER
-----------------------------------------------------------------------------------------------------------------------------------------
function MarkedVehicle()
	if not Locale or not Destiny or not Locations or not Locations[Locale] then
		return false
	end

	local Point = Locations[Locale][Destiny]
	if not Point or not Point.xyz then
		return false
	end

	if Blip and DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	Blip = AddBlipForCoord(Point.xyz)

	if not Blip then
		return false
	end

	SetBlipSprite(Blip,1)
	SetBlipDisplay(Blip,4)
	SetBlipAsShortRange(Blip,true)
	SetBlipColour(Blip,77)
	SetBlipScale(Blip,0.75)
	SetBlipRoute(Blip,true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Veículo")
	EndTextCommandSetBlipName(Blip)
end