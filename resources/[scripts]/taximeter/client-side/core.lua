-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Focus = false
local Driver = false
local Display = false
local LastCoords = vec3(0,0,0)
local ExtraDecor = "_CREATIVE_TAXI_EXTRA_"
local TariffDecor = "_CREATIVE_TAXI_TARIFF_"
local StarterDecor = "_CREATIVE_TAXI_STARTER_"
local DistanceDecor = "_CREATIVE_TAXI_DISTANCE_"
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLETAXI
-----------------------------------------------------------------------------------------------------------------------------------------
function VehicleTaxi(Vehicle)
	for _,v in ipairs(Vehicles) do
		if GetEntityArchetypeName(Vehicle) == v then
			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	DecorRegister(ExtraDecor,1)
	DecorRegister(TariffDecor,1)
	DecorRegister(StarterDecor,1)
	DecorRegister(DistanceDecor,1)

	while true do
		local Ped = PlayerPedId()
		local Vehicle = GetVehiclePedIsIn(Ped)
		if Vehicle ~= 0 and VehicleTaxi(Vehicle) then
			if not Display then
				Display = true
				LastCoords = GetEntityCoords(Ped)
				SendNUIMessage({ Action = "Display", Payload = true })
			end

			if GetPedInVehicleSeat(Vehicle,-1) == Ped then
				if not Driver then
					Driver = true
					SendNUIMessage({ Action = "Driver", Payload = true })
					UpdatePrice()
				end

				local Coords = GetEntityCoords(Ped)
				if DecorGetBool(Vehicle,StarterDecor) and Coords ~= LastCoords then
					local DecorDistance = DecorGetFloat(Vehicle,DistanceDecor)
					DecorDistance = DecorDistance + #(Coords - LastCoords)
					DecorSetFloat(Vehicle,DistanceDecor,DecorDistance)

					LastCoords = Coords
					UpdatePrice()
				end
			else
				if Driver then
					Driver = false
					SendNUIMessage({ Action = "Driver", Payload = false })
				end

				UpdatePrice()
			end
		elseif Display then
			Display = false
			SendNUIMessage({ Action = "Display", Payload = false })
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Config",function(Data,Callback)
	Callback({ Tariffs = Tariffs, ExtraPrice = ExtraPrice })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXTRAS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Extras",function(Data,Callback)
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsIn(Ped)
	local Extra = DecorGetFloat(Vehicle,ExtraDecor)

	if Data.Mode == "Add" then
		Extra = Extra + ExtraPrice
	elseif Data.Mode == "Remove" and Extra >= ExtraPrice then
		Extra = Extra - ExtraPrice
	end

	DecorSetFloat(Vehicle,ExtraDecor,Extra)
	UpdatePrice()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- START
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Start",function(Data,Callback)
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsIn(Ped)

	DecorSetBool(Vehicle,StarterDecor,true)
	LastCoords = GetEntityCoords(Ped)
	UpdatePrice()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Stop",function(Data,Callback)
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsIn(Ped)

	DecorSetBool(Vehicle,StarterDecor,false)
	UpdatePrice()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARIFF
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Tariff",function(Data,Callback)
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsIn(Ped)

	DecorSetFloat(Vehicle,TariffDecor,Data.Number)
	UpdatePrice()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Reset",function(Data,Callback)
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsIn(Ped)

	DecorSetFloat(Vehicle,DistanceDecor,0)
	DecorSetFloat(Vehicle,TariffDecor,1)
	DecorSetFloat(Vehicle,ExtraDecor,0)
	UpdatePrice()

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPRICE
-----------------------------------------------------------------------------------------------------------------------------------------
function UpdatePrice()
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsIn(Ped)

	SendNUIMessage({ Action = "Update", Payload = { Started = DecorGetBool(Vehicle,StarterDecor), Distance = DecorGetFloat(Vehicle,DistanceDecor), Extras = DecorGetFloat(Vehicle,ExtraDecor), Tariff = DecorGetFloat(Vehicle,TariffDecor) } })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- +TAXIMETER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("+Taximeter",function()
	if not Driver then
		return false
	end

	Focus = not Focus
	SetNuiFocus(Focus,Focus)
	SetNuiFocusKeepInput(Focus)
	SendNUIMessage({ Action = "Focus", Payload = Focus })

	if Focus then
		SetCursorLocation(0.85,0.85)

		CreateThread(function()
			while true do
				DisableControlAction(0,1,true)
				DisableControlAction(0,2,true)

				if not Focus then
					break
				end

				Wait(1)
			end
		end)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("+Taximeter","Interação com o taximetro.","keyboard","F3")