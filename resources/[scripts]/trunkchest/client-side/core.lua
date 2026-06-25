-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("trunkchest")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Opened = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Close")
AddEventHandler("inventory:Close",function()
	if Opened then
		vSERVER.Close()
		Opened = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRUNK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("trunkchest:Open")
AddEventHandler("trunkchest:Open",function(Vehicle)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	Opened = Vehicle

	TriggerEvent("inventory:Open",{
		Type = "Chest",
		Right = "Porta-Malas",
		Resource = "trunkchest"
	})

	CreateThread(function()
		while Opened do
			if not DoesEntityExist(Opened) then
				TriggerEvent("inventory:Close")
				break
			end

			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)
			local OtherCoords = GetEntityCoords(Opened)

			if #(Coords - OtherCoords) > 10 then
				TriggerEvent("inventory:Close")
				break
			end

			Wait(1000)
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Take(Data.Slot,Data.Amount,Data.Target)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Store",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Store(Data.Item,Data.Slot,Data.Amount,Data.Target)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Update",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Update(Data.Slot,Data.Target,Data.Amount)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Primary,Secondary,PrimaryWeight,SecondaryWeight,PrimarySlots = vSERVER.Mount()
	if Primary then
		Callback({
			Primary = {
				Data = Primary,
				MaxWeight = PrimaryWeight,
				Slots = PrimarySlots or Theme.inventory.slots.default
			},
			Secondary = {
				Data = Secondary,
				MaxWeight = SecondaryWeight,
				Slots = math.max(CountTable(Secondary),25)
			}
		})
	end
end)