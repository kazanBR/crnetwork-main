-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("bus")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Route = 1
local Blip = nil
local Selected = 1
local Active = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUS:DYNAMIC
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("bus:Dynamic",function()
	if Active then
		exports.dynamic:AddButton("Finalizar Expediente","Cancelar a rota atual.","bus:Init","Finalizar",false,false)
	else
		exports.dynamic:AddMenu("Iniciar Expediente","Selecionar as rotas disponíveis.","routes")

		for Index,v in pairs(Locations) do
			exports.dynamic:AddButton(v.Name or "Rota",v.Description or "Sem descrição","bus:Init",Index,"routes",false)
		end
	end

	exports.dynamic:Open()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUS:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("bus:Init",function(Mode)
	TriggerEvent("dynamic:Close")

	if Mode == "Finalizar" then
		if Blip and DoesBlipExist(Blip) then
			RemoveBlip(Blip)
			Blip = nil
		end

		TriggerEvent("Notify","Central de Empregos","Você acaba de finalizar sua jornada de trabalho, esperamos que você tenha aprendido bastante hoje.","default",5000)
		Active = false

		return false
	end

	TriggerEvent("Notify","Central de Empregos","Você acaba de dar início à sua jornada de trabalho, lembrando que a sua vida não se resume só a isso.","default",5000)
	Active = true
	Route = Mode
	MakeBlips()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	exports.target:AddBoxZone("WorkBus",Init.xyz,0.75,0.75,{
		name = "WorkBus",
		heading = Init.w,
		minZ = Init.z - 1.0,
		maxZ = Init.z + 1.0
	},{
		Distance = 1.75,
		options = {
			{
				label = "Abrir",
				tunnel = "client",
				event = "bus:Dynamic"
			}
		}
	})

	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if Active then
			local Vehicle = GetVehiclePedIsUsing(Ped)
			if Vehicle ~= 0 and GetEntityArchetypeName(Vehicle) == "bus" then
				local Coords = GetEntityCoords(Ped)
				local Destination = Locations[Route].Coords[Selected]
				local Distance = #(Coords - Destination)

				if Distance <= 200 then
					TimeDistance = 1

					DrawMarker(22,Destination.x,Destination.y,Destination.z + 3.0,0.0,0.0,0.0,0.0,180.0,0.0,7.5,7.5,5.0,88,101,242,175,0,0,0,1)
					DrawMarker(1,Destination.x,Destination.y,Destination.z - 3.0,0.0,0.0,0.0,0.0,0.0,0.0,15.0,15.0,10.0,255,255,255,50,0,0,0,0)

					if Distance <= 10 then
						vSERVER.Payment(Route,Selected)
						Selected = (Selected % #Locations[Route].Coords) + 1
						MakeBlips()
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAKEBLIPS
-----------------------------------------------------------------------------------------------------------------------------------------
function MakeBlips()
	if DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	Blip = AddBlipForCoord(Locations[Route].Coords[Selected].x,Locations[Route].Coords[Selected].y,Locations[Route].Coords[Selected].z)
	SetBlipSprite(Blip,1)
	SetBlipDisplay(Blip,4)
	SetBlipColour(Blip,77)
	SetBlipScale(Blip,0.75)
	SetBlipRoute(Blip,true)
	SetBlipAsShortRange(Blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Motorista")
	EndTextCommandSetBlipName(Blip)
end