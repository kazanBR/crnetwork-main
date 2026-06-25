-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mount(Bluepage)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Primary = {}
	local Secondary = {}
	local Inventory = vRP.Inventory(Passport)

	for Slot,v in pairs(Inventory) do
		if v.amount <= 0 or not exports.vrp:ItemExist(v.item) then
			vRP.CleanSlot(Passport,Slot)
		else
			v.key = v.item

			local Split = splitString(v.item)
			local Item,First,Second = Split[1],Split[2],Split[3]

			if not v.desc then
				if Item == "vehiclekey" and Second then
					local Consult = exports.oxmysql:single_async("SELECT Passport,Vehicle FROM vehicles WHERE Plate = ? LIMIT 1",{ Second })
					if Consult and exports.vrp:VehicleExist(Consult.Vehicle) then
						v.desc = ("Proprietário: <common>%s</common><br>Modelo: <common>%s</common><br>Placa: <common>%s</common>"):format(vRP.FullName(Consult.Passport),exports.vrp:VehicleName(Consult.Vehicle),Second)
					end
				elseif Item == "propertys" and First then
					local Consult = exports.oxmysql:single_async("SELECT Passport FROM propertys WHERE Serial = ? LIMIT 1",{ First })
					if Consult then
						v.desc = ("Proprietário: <common>%s</common>"):format(vRP.FullName(Consult.Passport))
					end
				elseif exports.vrp:ItemNamed(Item) and First then
					if vRP.Identity(First) then
						if Item == "identity" then
							v.desc = ("Passaporte: <rare>%s</rare><br>Nome: <rare>%s</rare><br>Telefone: <rare>%s</rare>"):format(Dotted(First),vRP.FullName(First),vRP.Phone(First))
						else
							v.desc = ("Proprietário: <common>%s</common>"):format(vRP.FullName(First))
						end
					end
				end
			end

			if First then
				local Loaded = exports.vrp:ItemLoads(v.item)
				if Loaded then
					v.charges = parseInt(First * (100 / Loaded))
				end

				local Durability = exports.vrp:ItemDurability(v.item)
				if Durability then
					local CurrentTimer = os.time()
					v.durability = parseInt(CurrentTimer - First)
					v.days = Durability
				end
			end

			Primary[Slot] = v
		end
	end

	if Bluepage then
		local Blueprints = Users.Blueprints[Passport]
		if not Blueprints then
			Blueprints = {}
			Users.Blueprints[Passport] = Blueprints
		end

		local Count = 0
		for Item in pairs(Blueprints) do
			local Data = exports.vrp:ItemExist(Item)
			if Data and Data.Blueprint then
				local Entry = { key = Item, amount = 1 }

				local Craft = Crafting[Item]
				if Craft and Craft.Required then
					Entry.required = Craft.Required
				end

				Secondary[tostring(Count)] = Entry
				Count = Count + 1
			else
				Blueprints[Item] = nil
			end
		end

		return Primary,Secondary,vRP.GetWeight(Passport),vRP.InventorySlots(Passport)
	end

	return Primary,vRP.GetWeight(Passport),vRP.InventorySlots(Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Missions()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return {}
	end

	local List = {}
	local Consult = vRP.SimpleData(Passport,"Missions") or {}

	for Index,v in pairs(Missions) do
		List[Index] = {
			Xp = v.Xp,
			Code = v.Code,
			Title = v.Title,
			Description = v.Description,
			Required = v.Required,
			Rewards = v.Rewards,
			Active = Consult[v.Code] == true
		}
	end

	return {
		Experience = vRP.GetExperience(Passport,"Missions"),
		Levels = TableLevel(),
		List = List
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESCUEMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RescueMission(Index)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Mission = Missions[Index]
	if not Mission then
		return false
	end

	local Code = Mission.Code
	if not Code then
		return false
	end

	local Consult = vRP.SimpleData(Passport,"Missions") or {}
	if Consult and Consult[Code] then
		return false
	end

	local Consume = {}
	for Item,Amount in pairs(Mission.Required) do
		local ConsultItem = vRP.ConsultItem(Passport,Item,Amount)
		if not ConsultItem then
			TriggerClientEvent("inventory:Notify",source,"Atenção","Precisa de <default>"..Dotted(Amount).."x "..exports.vrp:ItemName(Item).."</default>.","vermelho")
			return false
		end

		Consume[#Consume + 1] = {
			Item = ConsultItem.Item,
			Amount = Amount
		}
	end

	for Number = 1,#Consume do
		local v = Consume[Number]
		vRP.RemoveItem(Passport,v.Item,v.Amount)
	end

	for Item,Amount in pairs(Mission.Rewards) do
		vRP.GenerateItem(Passport,Item,Amount)
	end

	if Mission.Xp and Mission.Xp > 0 then
		vRP.PutExperience(Passport,"Missions",Mission.Xp)
	end

	Consult[Code] = true

	vRP.Query("playerdata/SetData",{
		Passport = Passport,
		Name = "Missions",
		Information = json.encode(Consult)
	})

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Crafting(Item,Amount,Target)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Item or not Crafting[Item] then
		return false
	end

	Target = tostring(Target)
	Amount = parseInt(Amount,true)
	if Amount <= 0 then
		return false
	end

	if Amount > 1 and (exports.vrp:ItemUnique(Item) or exports.vrp:ItemLoads(Item)) then
		Amount = 1
	end

	local Craft = Crafting[Item]
	local Multiplier = Craft.Amount * Amount
	if vRP.MaxItens(Passport,Item,Multiplier) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Limite atingido.","amarelo",5000)
		return false
	end

	if not vRP.CheckWeight(Passport,Item,Multiplier) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Mochila Sobrecarregada.","amarelo")
		return false
	end

	local Inventory = vRP.Inventory(Passport)
	if Inventory[Target] and Inventory[Target].item ~= Item then
		return false
	end

	local ItemList = {}
	for Index,Value in pairs(Craft.Required) do
		local RequiredAmount = Value * Amount
		local ConsultItem = vRP.ConsultItem(Passport,Index,RequiredAmount)
		if not ConsultItem then
			TriggerClientEvent("inventory:Notify",source,"Atenção","Precisa de <default>"..Dotted(RequiredAmount).."x "..exports.vrp:ItemName(Index).."</default>.","vermelho")
			return false
		end

		ItemList[ConsultItem.Item] = RequiredAmount
	end

	for Index,Value in pairs(ItemList) do
		vRP.RemoveItem(Passport,Index,Value)
	end

	vRP.GenerateItem(Passport,Item,Multiplier,false,Target)
	TriggerClientEvent("inventory:Blueprint",source)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURCHASESLOT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PurchaseSlot(Mode,Amount)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local Slots = Theme.inventory.slots
	local CurrentSlot = vRP.InventorySlots(Passport)
	if not Slots or CurrentSlot >= Slots.max or (CurrentSlot + Amount) > Slots.max then
		return false
	end

	local PriceTable
	local PaymentFunction
	if Mode == "Bank" then
		PriceTable = Slots.bank
		PaymentFunction = vRP.PaymentBank
	elseif Mode == "Gemstone" then
		PriceTable = Slots.gemstone
		PaymentFunction = vRP.PaymentGems
	else
		return false
	end

	local BaseIndex = CurrentSlot - Slots.default
	if BaseIndex < 0 then
		BaseIndex = 0
	end

	local Valuation = 0
	for Number = 1,Amount do
		local Price = PriceTable[BaseIndex + Number]
		if not Price then
			return false
		end

		Valuation = Valuation + Price
	end

	if Valuation <= 0 or not PaymentFunction(Passport,Valuation,true) then
		return false
	end

	vRP.UpgradeSlots(Passport,Amount)

	return true
end