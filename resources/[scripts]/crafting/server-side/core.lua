-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("crafting",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Produce = {}
local RescueLock = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Crafting" })
	Produce = Consult and json.decode(Consult.Information) or {}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permission(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not List[Name] then
		return false
	end

	if exports.bank:CheckTaxes(Passport) or exports.bank:CheckFines(Passport) then
		return false
	end

	local Permission = List[Name].Permission
	return not Permission or vRP.HasService(Passport,Permission)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mount(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Name and List[Name] then
		local Primary = {}
		local Inv = vRP.Inventory(Passport)
		for Slot,v in pairs(Inv) do
			if v.amount <= 0 or not exports.vrp:ItemExist(v.item) then
				vRP.CleanSlot(Passport,Slot)
			else
				v.key = v.item

				local Split = splitString(v.item)
				local Item = Split[1]

				if not v.desc then
					if Item == "vehiclekey" and Split[3] then
						local Consult = exports.oxmysql:single_async("SELECT * FROM vehicles WHERE Plate = ? LIMIT 1",{ Split[3] })
						if Consult and exports.vrp:VehicleExist(Consult.Vehicle) then
							v.desc = "Proprietário: <common>"..vRP.FullName(Consult.Passport).."</common><br>Modelo: <common>"..exports.vrp:VehicleName(Consult.Vehicle).."</common><br>Placa: <common>"..Split[3].."</common>"
						end
					elseif Item == "propertys" and Split[2] then
						local Consult = exports.oxmysql:single_async("SELECT * FROM propertys WHERE Serial = ? LIMIT 1",{ Split[2] })
						if Consult then
							v.desc = "Proprietário: <common>"..vRP.FullName(Consult.Passport).."</common>"
						end
					elseif exports.vrp:ItemNamed(Item) and Split[2] and vRP.Identity(Split[2]) then
						if Item == "identity" then
							v.desc = "Passaporte: <rare>"..Dotted(Split[2]).."</rare><br>Nome: <rare>"..vRP.FullName(Split[2]).."</rare><br>Telefone: <rare>"..vRP.Phone(Split[2]).."</rare>"
						else
							v.desc = "Proprietário: <common>"..vRP.FullName(Split[2]).."</common>"
						end
					end
				end

				if Split[2] then
					local Loaded = exports.vrp:ItemLoads(v.item)
					if Loaded then
						v.charges = parseInt(Split[2] * (100 / Loaded))
					end

					if exports.vrp:ItemDurability(v.item) then
						v.durability = parseInt(os.time() - Split[2])
						v.days = exports.vrp:ItemDurability(v.item)
					end
				end

				Primary[Slot] = v
			end
		end

		return Primary,vRP.GetWeight(Passport),vRP.InventorySlots(Passport)
	end
end
---------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Take(Item,Amount,Target,Name,Code)
	local source = source
	local Target = tostring(Target)
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Craft = List[Name]
	if not Craft then
		return false
	end

	local Recipe = Craft.List and Craft.List[Item]
	if not Recipe then
		return false
	end

	local CraftLocation = Code and Location[Code]
	local Unique = CraftLocation and CraftLocation.Unique
	if Code and not Unique then
		return false
	end

	local Permission = Craft.Permission
	if Permission and not vRP.HasService(Passport,Permission) then
		return false
	end

	Amount = parseInt(Amount,true)
	if exports.vrp:ItemUnique(Item) then
		Amount = 1
	end

	local ItemData = exports.vrp:ItemExist(Item)
	local TotalAmount = (Recipe.Amount or 1) * Amount
	if ItemData and ItemData.Blueprint and not exports.inventory:Blueprint(Passport,Item) then
		TriggerClientEvent("inventory:Notify",source,"Produção","Aprendizado não encontrado.","amarelo")
		return false
	end

	if Code then
		Produce[Unique] = Produce[Unique] or {}

		if #Produce[Unique] >= 25 then
			TriggerClientEvent("inventory:Notify",source,"Produção","Fila de produção cheia.","amarelo")
			return false
		end
	else
		local Inventory = vRP.Inventory(Passport)
		if vRP.MaxItens(Passport,Item,TotalAmount) or not vRP.CheckWeight(Passport,Item,TotalAmount) or (Inventory[Target] and Inventory[Target].item ~= Item) then
			return false
		end
	end

	local Removed = {}
	local RemoveList = {}
	for Required,Multiplier in pairs(Recipe.Required) do
		local NeedAmount = Multiplier * Amount
		local ConsultItem = vRP.ConsultItem(Passport,Required,NeedAmount)

		if not ConsultItem then
			TriggerClientEvent("inventory:Notify",source,"Produção","Precisa de <default>"..Dotted(NeedAmount).."x "..exports.vrp:ItemName(Required).."</default>.","vermelho")
			return false
		end

		RemoveList[ConsultItem.Item] = (RemoveList[ConsultItem.Item] or 0) + NeedAmount
	end

	for ItemName,ItemAmount in pairs(RemoveList) do
		if not vRP.RemoveItem(Passport,ItemName,ItemAmount) then
			for _,DataRollback in ipairs(Removed) do
				vRP.GenerateItem(Passport,DataRollback.Item,DataRollback.Amount)
			end

			return false
		end

		Removed[#Removed + 1] = {
			Item = ItemName,
			Amount = ItemAmount
		}
	end

	if Code then
		local ProductionTimer = Recipe.Timer
		if ProductionTimer and ProductionTimer > 0 then
			ProductionTimer = ProductionTimer * Amount

			local Now = os.time()
			local LastedTimer = Now
			local Queue = Produce[Unique]

			for Number = 1,#Queue do
				local Production = Queue[Number]
				if Production.Timer > LastedTimer then
					LastedTimer = Production.Timer
				end
			end

			local Position = #Queue + 1
			local FinishTimer = LastedTimer + ProductionTimer

			Queue[Position] = {
				Item = Item,
				Amount = TotalAmount,
				Timer = FinishTimer
			}

			TriggerClientEvent("inventory:Notify",source,"Produção",("Posição: <common>#%s na fila</common><br>Produto: <rare>%sx %s</rare><br>Tempo: <epic>%s</epic>"):format(Position,Amount,exports.vrp:ItemName(Item),CompleteTimers(FinishTimer - Now)),"verde")
			vRP.Query("entitydata/SetData",{ Name = "Crafting", Information = json.encode(Produce) })
		else
			vRP.GenerateItem(Passport,Item,TotalAmount,false,Target)
		end
	else
		vRP.GenerateItem(Passport,Item,TotalAmount,false,Target)
	end

	TriggerClientEvent("inventory:Update",source)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTING:RESCUE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("crafting:Rescue")
AddEventHandler("crafting:Rescue",function(Index,Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Craft = List[Name]
	if not Craft then
		return false
	end

	local Permission = Craft.Permission
	if Permission and not vRP.HasService(Passport,Permission) then
		return false
	end

	local CraftLocation = Location[Index]
	if not CraftLocation then
		return false
	end

	local Unique = CraftLocation.Unique
	if not Unique or RescueLock[Unique] then
		return false
	end

	RescueLock[Unique] = true

	local Queue = Produce[Unique]
	if not Queue or #Queue <= 0 then
		RescueLock[Unique] = nil
		return false
	end

	local CurrentTimer = os.time()
	for Number = #Queue,1,-1 do
		local Production = Queue[Number]
		if Production and Production.Timer <= CurrentTimer and not vRP.MaxItens(Passport,Production.Item,Production.Amount) and vRP.CheckWeight(Passport,Production.Item,Production.Amount) then
			vRP.GenerateItem(Passport,Production.Item,Production.Amount,true)
			table.remove(Queue,Number)
		end
	end

	if #Queue <= 0 then
		Produce[Unique] = nil
	end

	vRP.Query("entitydata/SetData",{ Name = "Crafting", Information = json.encode(Produce) })

	RescueLock[Unique] = nil
end)