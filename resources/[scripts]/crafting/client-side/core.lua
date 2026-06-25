-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("crafting")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Code = false
local ItemList = {}
local Opened = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSTARTSERVER
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Index,v in pairs(List) do
		local Result = {}
		for Key,Recipe in pairs(v.List) do
			Result[#Result + 1] = {
				key = Key,
				price = Recipe.Amount,
				required = Recipe.Required
			}
		end

		ItemList[Index] = Result
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Close")
AddEventHandler("inventory:Close",function()
	Opened = false
	Code = false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPENCRAFTING
-----------------------------------------------------------------------------------------------------------------------------------------
function OpenCrafting(Mode,Main)
	Code = Main
	Opened = Mode

	TriggerEvent("inventory:Open",{
		Mode = "Buy",
		Type = "Shops",
		Right = "Produção",
		Resource = "crafting"
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	if Opened then
		local SecondaryData = ItemList[Opened] or {}
		local Primary,PrimaryWeight,PrimarySlots = vSERVER.Mount(Opened)

		Callback({
			Primary = {
				Data = Primary,
				MaxWeight = PrimaryWeight,
				Slots = PrimarySlots or Theme.inventory.slots.default
			},
			Secondary = {
				Data = SecondaryData,
				Slots = math.max(CountTable(SecondaryData),25)
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	if Opened and Data.Item and Data.Amount and MumbleIsConnected() then
		vSERVER.Take(Data.Item,Data.Amount,Data.Target,Opened,Code)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTING:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("crafting:Open",function(Number)
	if exports.hud:Wanted() then
		return false
	end

	local Data = Location[Number]
	if Data then
		if vSERVER.Permission(Data.Mode) then
			OpenCrafting(Data.Mode,Number)
		end
	else
		if vSERVER.Permission(Number) then
			OpenCrafting(Number)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Number,v in pairs(Location) do
		exports.target:AddCircleZone("Crafting:"..Number,v.Coords,v.Circle,{
			name = "Crafting:"..Number,
			heading = 0.0,
			useZ = true
		},{
			shop = Number,
			Distance = 2.0,
			options = {
				{
					event = "crafting:Open",
					label = "Abrir",
					tunnel = "client",
					service = "Open"
				},{
					event = "crafting:Rescue",
					label = "Resgatar",
					tunnel = "server",
					service = v.Mode
				}
			}
		})
	end
end)