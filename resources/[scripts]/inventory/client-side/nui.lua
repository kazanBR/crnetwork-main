-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Drops = {}
local Opened = false
local Cooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Open")
AddEventHandler("inventory:Open",function(Data,Ignore)
	local Pid = PlayerId()
	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and (not Opened or Data.Force or Ignore) and not IsPauseMenuActive() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not IsPlayerFreeAiming(Pid) then
		if not Opened and not Data.Force then
			SetCursorLocation(0.5,0.5)
		end

		Data.Player = {
			Passport = LocalPlayer.state.Passport,
			Name = LocalPlayer.state.Name or NameDefault
		}

		Opened = true
		SetNuiFocus(true,true)
		TransitionToBlurred(1000)
		TriggerEvent("hud:Active",false)
		SendNUIMessage({ Action = "Open", Payload = Data })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Close")
AddEventHandler("inventory:Close",function()
	if not Opened then
		return false
	end

	Opened = false
	SetNuiFocus(false,false)
	SetCursorLocation(0.5,0.5)
	TransitionFromBlurred(1000)
	TriggerEvent("hud:Active",true)
	SendNUIMessage({ Action = "Close" })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BACKINVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("BackInventory",function(Data,Callback)
	local State = LocalPlayer.state
	local IsAdmin = State.Admin and {
		Level = State.Admin,
		Spawn = { "area","player","all" }
	} or false

	TriggerEvent("inventory:Open",{
		Type = "Inventory",
		Resource = "inventory",
		Right = "Proximidade",
		Admin = IsAdmin
	},true)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:BUTTONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:Buttons",function(Data)
	SendNUIMessage({ Action = "Buttons", Payload = Data })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSEBUTTONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:CloseButtons",function()
	SendNUIMessage({ Action = "Close" })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Notify")
AddEventHandler("inventory:Notify",function(Title,Message,Type)
	if Opened then
		SendNUIMessage({ Action = "Notify", Payload = { Title = Title, Message = Message, Type = Type } })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	TriggerEvent("inventory:Close")

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:USE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:Use",function(Slot,Amount)
	vSERVER.Use(Slot,Amount or 1)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- USE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Use",function(Data,Callback)
	local Sucess = false
	if GetGameTimer() >= Cooldown then
		Sucess = vSERVER.Use(Data.Slot,Data.Amount)
		Cooldown = GetGameTimer() + 1000
	end

	Callback(Sucess)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWNITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("SpawnItem",function(Data,Callback)
	Callback(vSERVER.SpawnItem(Data.Passport,Data.Item,Data.Amount,Data.Mode,Data.Distance))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Send",function(Data,Callback)
	local Sucess = false
	if MumbleIsConnected() and not TakeWeapon and not StoreWeapon and not LocalPlayer.state.Arena then
		Sucess = vSERVER.Send(Data.Slot,Data.Amount)
	end

	Callback(Sucess)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Store",function(Data,Callback)
	local Sucess = false
	if MumbleIsConnected() and not TakeWeapon and not StoreWeapon and not LocalPlayer.state.Arena then
		Sucess = vSERVER.Drops(Data.Item,Data.Slot,Data.Amount)
	end

	Callback(Sucess)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	Callback(vSERVER.Pickup(Data.Id,Data.Route,Data.Target,Data.Amount))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Update",function(Data,Callback)
	Callback(vRPS.invUpdate(Data.Slot,Data.Target,Data.Amount))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Update")
AddEventHandler("inventory:Update",function()
	if Opened then
		SendNUIMessage({ Action = "Backpack" })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:BLUEPRINT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Blueprint")
AddEventHandler("inventory:Blueprint",function()
	local Primary,Secondary,MaxWeight,AmountSlots = vSERVER.Mount("Blueprint")
	if Primary then
		TriggerEvent("inventory:Open",{
			Force = true,
			Type = "Blueprint",
			Right = "Aprendizado",
			Resource = "inventory",
			Primary = {
				Data = Primary,
				MaxWeight = MaxWeight,
				Slots = AmountSlots or Theme.inventory.slots.default
			},
			Secondary = {
				Data = Secondary,
				Slots = math.max(CountTable(Secondary),25)
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("Inventory",function()
	local State = LocalPlayer.state
	local IsAdmin = State.Admin and {
		Level = State.Admin,
		Spawn = { "area","player","all" }
	} or false

	TriggerEvent("inventory:Open",{
		Type = "Inventory",
		Resource = "inventory",
		Right = "Proximidade",
		Admin = IsAdmin
	},true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("Inventory","Abrir/Fechar a mochila.","keyboard","OEM_3")
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Drops")
AddEventHandler("inventory:Drops",function(Table)
	Drops = Table or {}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPSREMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:DropsRemover")
AddEventHandler("inventory:DropsRemover",function(Route,Selected)
	if Drops[Route] then
		Drops[Route][Selected] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPSATUALIZAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:DropsAtualizar")
AddEventHandler("inventory:DropsAtualizar",function(Route,Selected,Amount)
	if Drops[Route] and Drops[Route][Selected] then
		Drops[Route][Selected].amount = Amount
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPSADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:DropsAdicionar")
AddEventHandler("inventory:DropsAdicionar",function(Route,Selected,Table)
	if not Route or not Table then
		return false
	end

	Drops[Route] = Drops[Route] or {}
	Drops[Route][Selected] = Table

	if Opened and Table.coords then
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)

		local First = Coords.x - Table.coords.x
		local Second = Coords.y - Table.coords.y
		local Third = Coords.z - Table.coords.z

		if (First * First + Second * Second + Third * Third) <= (DistanceDrops * DistanceDrops) then
			SendNUIMessage({ Action = "Backpack" })
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Secondary = {}
	local Ped = PlayerPedId()
	local Route = LocalPlayer.state.Route
	local Primary,MaxWeight,AmountSlots = vSERVER.Mount()

	if not IsPedInAnyVehicle(Ped) and Route and Drops[Route] then
		local Coords = GetEntityCoords(Ped)

		for _,v in pairs(Drops[Route]) do
			local DropCoords = v.coords
			if DropCoords then
				local First = Coords.x - DropCoords.x
				local Second = Coords.y - DropCoords.y
				local Third = Coords.z - DropCoords.z

				if (First * First + Second * Second + Third * Third) <= 1.0 then
					Secondary[#Secondary + 1] = v
				end
			end
		end
	end

	Callback({
		Primary = {
			Data = Primary,
			MaxWeight = MaxWeight,
			Slots = AmountSlots or Theme.inventory.slots.default
		},
		Secondary = {
			Data = Secondary,
			Slots = math.max(#Secondary,25)
		}
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURCHASESLOT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("PurchaseSlot",function(Data,Callback)
	Callback(vSERVER.PurchaseSlot(Data.Mode,Data.Amount))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLUEPRINT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Blueprint",function(Data,Callback)
	TriggerEvent("inventory:Blueprint")

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Crafting",function(Data,Callback)
	Callback(vSERVER.Crafting(Data.Item,Data.Amount,Data.Target))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Missions",function(Data,Callback)
	Callback(vSERVER.Missions())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESCUEMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("RescueMission",function(Data,Callback)
	Callback(vSERVER.RescueMission(Data.Index))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:NOTIFYITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:NotifyItem")
AddEventHandler("inventory:NotifyItem",function(Data)
	if not Opened then
		SendNUIMessage({ Action = "NotifyItem", Payload = Data })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADDROPS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if not IsPedInAnyVehicle(Ped) then
			local Route = LocalPlayer.state.Route
			local RouteDrops = Route and Drops[Route]

			if RouteDrops then
				local Coords = GetEntityCoords(Ped)

				for _,v in pairs(RouteDrops) do
					local DropCoords = v.coords
					if DropCoords then
						local First = Coords.x - DropCoords.x
						local Second = Coords.y - DropCoords.y
						local Third = Coords.z - DropCoords.z

						if (First * First + Second * Second + Third * Third) <= (DistanceDrops * DistanceDrops) then
							SetDrawOrigin(DropCoords.x,DropCoords.y,DropCoords.z - 0.75)
							DrawSprite("Textures","Normal",0.0,0.0,0.0185,0.0185 * GetAspectRatio(false),0.0,88,101,242,255)
							ClearDrawOrigin()

							TimeDistance = 1
						end
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)