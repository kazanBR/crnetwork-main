-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("shops")
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
		Opened = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Primary,PrimaryWeight,PrimarySlots = vSERVER.Mount(Opened)
	if Primary then
		Callback({
			Primary = {
				Data = Primary,
				MaxWeight = PrimaryWeight,
				Slots = PrimarySlots or Theme.inventory.slots.default
			},
			Secondary = {
				Data = ItemList[Opened],
				Slots = math.max(CountTable(ItemList[Opened]),25)
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Take(Data.Item,Data.Amount,Data.Target,Opened)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Store",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Store(Data.Item,Data.Amount,Data.Target,Opened)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SHOPS:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("shops:Open",function(Number)
	if exports.hud:Wanted() then
		return
	end

	local Shop = Location[Number]
	if not Shop then
		if vSERVER.Permission(Number) and List[Number] then
			Opened = Number

			TriggerEvent("inventory:Open",{
				Type = "Shops",
				Mode = List[Opened].Mode,
				Item = List[Opened].Item or "dollar",
				Resource = "shops",
				Right = "Loja"
			})
		end

		return
	end

	local RouteMatch = not Shop.Route or Shop.Route == LocalPlayer.state.Route
	if not RouteMatch or not vSERVER.Permission(Shop.Mode) then
		return
	end

	Opened = Shop.Mode

	TriggerEvent("inventory:Open",{
		Type = "Shops",
		Mode = List[Opened].Mode,
		Item = List[Opened].Item or "dollar",
		Resource = "shops",
		Right = Shop.Name or "Loja"
	})

	if Shop.Sound then
		TriggerEvent("sounds:Private","shop",0.5)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Number,v in pairs(Location) do
		if v.Circle then
			exports.target:AddCircleZone("Shops:"..Number,v.Coords,v.Circle,{
				name = "Shops:"..Number,
				heading = 0.0,
				useZ = true
			},{
				shop = Number,
				Distance = 2.0,
				options = {
					{
						event = "shops:Open",
						label = "Abrir",
						tunnel = "client"
					}
				}
			})
		else
			exports.target:AddBoxZone("Shops:"..Number,v.Coords,0.75,0.75,{
				name = "Shops:"..Number,
				heading = 0.0,
				minZ = v.Coords.z - 1.0,
				maxZ = v.Coords.z + 1.0
			},{
				shop = Number,
				Distance = 2.0,
				options = {
					{
						event = "shops:Open",
						label = "Abrir",
						tunnel = "client"
					}
				}
			})
		end
	end
end)