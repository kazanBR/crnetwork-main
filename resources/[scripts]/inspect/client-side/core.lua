-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("inspect")
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
		vSERVER.Reset()
		Opened = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Primary,Secondary,PrimaryWeight,SecondaryWeight,PrimarySlots,SecondarySlots = vSERVER.Mount()
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
				Slots = SecondarySlots or Theme.inventory.slots.default
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Take(Data.Item,Data.Slot,Data.Target,Data.Amount)
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
-- INSPECT:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inspect:Open")
AddEventHandler("inspect:Open",function()
	Opened = true
	TriggerEvent("inventory:Open",{
		Type = "Inspect",
		Resource = "inspect",
		Right = "Jogador"
	})
end)