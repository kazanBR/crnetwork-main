-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("throwing")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local List = {}
local Blips = {}
local Deliverys = 0
local Service = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	exports.target:AddBoxZone("Throwing",Init.xyz,0.75,0.75,{
		name = "Throwing",
		heading = Init.w,
		minZ = Init.z - 1.0,
		maxZ = Init.z + 1.0
	},{
		Distance = 1.75,
		options = {
			{
				event = "throwing:Init",
				label = "Iniciar Expediente",
				tunnel = "client"
			}
		}
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAXI:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("throwing:Init",function()
	if Service then
		TriggerEvent("Notify","Central de Empregos","Você acaba finalizar sua jornada de trabalho, esperamos que você tenha aprendido bastante hoje.","default",5000)
		exports.target:LabelText("Throwing","Iniciar Expediente")

		for _,v in pairs(Blips) do
			if DoesBlipExist(v) then
				RemoveBlip(v)
			end
		end

		Service = false
		Blips = {}
	else
		TriggerEvent("Notify","Central de Empregos","Você acaba de dar inicio a sua jornada de trabalho, lembrando que a sua vida não se resume só a isso.","default",5000)
		exports.target:LabelText("Throwing","Finalizar Expediente")

		if Deliverys <= 0 then
			List = {}
			for Number = 1,#Locations do
				List[Number] = Locations[Number]
			end

			Deliverys = #List
		end

		for Index,Coords in pairs(List) do
			Blips[Index] = AddBlipForCoord(Coords)
			SetBlipSprite(Blips[Index],40)
			SetBlipDisplay(Blips[Index],4)
			SetBlipAsShortRange(Blips[Index],true)
			SetBlipColour(Blips[Index],61)
			SetBlipScale(Blips[Index],0.6)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString("Entrega")
			EndTextCommandSetBlipName(Blips[Index])

			Wait(10)
		end

		Service = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		if Service then
			local Ped = PlayerPedId()
			if IsPedInAnyVehicle(Ped) then
				local Vehicle = GetVehiclePedIsUsing(Ped)
				if Vehicle and VehicleList[GetEntityArchetypeName(Vehicle)] then
					local Coords = GetEntityCoords(Ped)

					for Line,v in pairs(List) do
						if #(Coords - v) <= 100 then
							TimeDistance = 1
							DrawMarker(1,v.x,v.y,v.z - 1.5,0,0,0,0,0,0,4.0,4.0,2.0,227,14,88,165,0,0,0,0)

							if IsProjectileTypeWithinDistance(v.x,v.y,v.z,-135142818,3.0,true) then
								if Blips[Line] and DoesBlipExist(Blips[Line]) then
									RemoveBlip(Blips[Line])
								end

								List[Line] = nil
								Blips[Line] = nil
								Deliverys = Deliverys - 1
								vSERVER.Payment()

								if Deliverys <= 0 then
									TriggerEvent("Notify","Central de Empregos","Você finalizou todas as entregas, volte até a central para iniciar novamente.","default",5000)
									exports.target:LabelText("Throwing","Iniciar Expediente")

									for _,v in pairs(Blips) do
										if DoesBlipExist(v) then
											RemoveBlip(v)
										end
									end

									List = {}
									Blips = {}
									Deliverys = 0
									Service = false
								else
									TriggerEvent("Notify","Central de Empregos","Restam "..Deliverys.." entregas.","amarelo",5000)
								end
							end
						end
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)