-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local DropLock = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEDROP
-----------------------------------------------------------------------------------------------------------------------------------------
local function RemoveDrop(Route,Number)
	local List = Drops[Route]
	if not List or not List[Number] then
		return false
	end

	TriggerClientEvent("inventory:DropsRemover",-1,Route,Number)
	List[Number] = nil

	if next(List) == nil then
		Drops[Route] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HANDLEDROPREMOVAL
-----------------------------------------------------------------------------------------------------------------------------------------
local function HandleDropRemoval(Route,Number,v)
	if RemoveDrop(Route,Number) and v.key and exports.vrp:ItemUnique(v.key) then
		local Unique = SplitUnique(v.key)
		if Unique then
			vRP.RemSrvData(Unique)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	if Silenced then
		return false
	end

	for Route,List in pairs(Drops) do
		local Clone = {}
		for Index,v in pairs(List) do
			Clone[Index] = v
		end

		for Number,v in pairs(Clone) do
			HandleDropRemoval(Route,Number,v)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADREMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(60000)

		local CurrentTimer = os.time()
		for Route,List in pairs(Drops) do
			for Number,v in pairs(List) do
				if v.created and v.created <= CurrentTimer then
					HandleDropRemoval(Route,Number,v)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEDROPS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Drops",function(Passport,source,Item,Amount,Force,Coords)
	Amount = parseInt(Amount,true)
	if Amount < 1 or not exports.vrp:ItemExist(Item) or DropLock then
		return false
	end

	local Route = GetPlayerRoutingBucket(source) or 0
	Drops[Route] = Drops[Route] or {}
	DropLock = true

	local Selected
	for Number = 1,50 do
		local Generate = GenerateString("DDDDDD")
		if not Drops[Route][Generate] then
			Selected = Generate
			break
		end
	end

	if not Selected then
		DropLock = false
		return false
	end

	local Provisory = {
		route = Route,
		id = Selected,
		amount = Amount,
		created = os.time() + 600,
		coords = Coords or vRP.GetEntityCoords(source),
		key = Force and Item or vRP.SortNameItem(Passport,Item)
	}

	local Split = splitString(Provisory.key)
	if Split[1] == "vehiclekey" and Split[3] then
		CreateThread(function()
			local Consult = exports.oxmysql:single_async("SELECT * FROM vehicles WHERE Plate = ? LIMIT 1",{ Split[3] })
			if Consult and exports.vrp:VehicleExist(Consult.Vehicle) then
				Provisory.desc = ("Proprietário: <common>%s</common><br>Modelo: <common>%s</common><br>Placa: <common>%s</common>"):format(vRP.FullName(Consult.Passport),exports.vrp:VehicleName(Consult.Vehicle),Split[3])
			end
		end)
	end

	local Value = parseInt(Split[2],true)
	if Value > 0 then
		local Loaded = exports.vrp:ItemLoads(Provisory.key)
		if Loaded then
			Provisory.charges = parseInt(Value * (100 / Loaded))
		end

		local Durability = exports.vrp:ItemDurability(Provisory.key)
		if Durability then
			Provisory.durability = math.max(0,os.time() - Value)
			Provisory.days = Durability
		end
	end

	Drops[Route][Selected] = Provisory
	DropLock = false

	TriggerClientEvent("inventory:DropsAdicionar",-1,Route,Selected,Provisory)

	return true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Drops(Item,Slot,Amount)
	local source = source
	Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if not Passport or Amount < 1 or not exports.vrp:ItemExist(Item) or exports.vrp:ItemLocked(Item) then
		return false
	end

	if Active[Passport] or Player(source).state.Handcuff or exports.hud:Wanted(Passport) or vRP.InsideVehicle(source) then
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	Active[Passport] = true

	local Success = false
	if vRP.TakeItem(Passport,Item,Amount,false,Slot) then
		Success = exports.inventory:Drops(Passport,source,Item,Amount,true)
	end

	Active[Passport] = nil

	if not Success then
		TriggerClientEvent("inventory:Update",source)
	end

	return Success
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PICKUP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Pickup(Number,Route,Target,Amount)
	local source = source
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if not Passport or Amount < 1 or not Target or Active[Passport] then
		return false
	end

	local Info = Drops[Route] and Drops[Route][Number]
	if not Info or not Info.key or Info.amount < Amount then
		return false
	end

	Active[Passport] = true

	local Inv = vRP.Inventory(Passport)
	if Inv[Target] and Inv[Target].item ~= Info.key then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Slot inválido.","amarelo")
		goto finish
	end

	if vRP.MaxItens(Passport,Info.key,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Limite atingido.","amarelo")
		goto finish
	end

	if not vRP.CheckWeight(Passport,Info.key,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Mochila cheia.","amarelo")
		goto finish
	end

	if vRP.GiveItem(Passport,Info.key,Amount,false,Target) then
		Info.amount = Info.amount - Amount

		if Info.amount <= 0 then
			RemoveDrop(Route,Number)
		else
			TriggerClientEvent("inventory:DropsAtualizar",-1,Route,Number,Info.amount)
		end

		Active[Passport] = nil

		return true
	end

	::finish::

	TriggerClientEvent("inventory:Update",source)
	Active[Passport] = nil

	return false
end