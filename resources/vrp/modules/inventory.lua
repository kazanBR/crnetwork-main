-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Entitys = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- HANDLEITEMEFFECTS
-----------------------------------------------------------------------------------------------------------------------------------------
function HandleItemEffects(source,Item,Amount,Notify)
	if not source then
		return false
	end

	if exports.vrp:ItemTypeCheck(Item,"Armamento") then
		TriggerClientEvent("inventory:CreateWeapon",source,Item)
	end

	local Animation = exports.vrp:ItemAnim(Item)
	if Animation then
		vRPC.PersistentBlock(source,Item,Animation)
	end

	local Marker = exports.vrp:ItemMarkers(Item)
	if Marker then
		exports.markers:Enter(source,Marker)
	end

	if Notify and exports.vrp:ItemExist(Item) then
		TriggerClientEvent("inventory:NotifyItem",source,{ Index = Item, Amount = Amount })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINDSLOT
-----------------------------------------------------------------------------------------------------------------------------------------
function FindSlot(Inventory,Slots,Item)
	local EmptySlot,StackSlot = nil,nil

	for Number = 0,Slots - 1 do
		local Sloted = tostring(Number)
		local Data = Inventory[Sloted]

		if Data then
			if Data.item == Item then
				StackSlot = Sloted
				break
			end
		elseif Sloted ~= "4" then
			EmptySlot = EmptySlot or Sloted
		end
	end

	return StackSlot or EmptySlot
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVECHARGES
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveCharges(Passport,Item)
	local Consult = vRP.ConsultItem(Passport,Item)
	if not Consult or not Consult.Item or not Consult.Slot or Consult.Amount <= 0 then
		return false
	end

	if not vRP.TakeItem(Passport,Consult.Item,1,false,Consult.Slot) then
		return false
	end

	if exports.vrp:ItemLoads(Consult.Item) then
		local Slotable = Consult.Slot
		local Name = SplitOne(Consult.Item)
		local Charges = tonumber(SplitTwo(Consult.Item)) or 0
		local Charger = Charges - 1

		if Consult.Amount > 1 then
			Slotable = false
		end

		if Charger >= 1 then
			vRP.GiveItem(Passport,Name.."-"..Charger,1,false,Slotable)
		else
			local Empty = exports.vrp:ItemEmpty(Consult.Item)
			if Empty and exports.vrp:ItemExist(Empty) then
				vRP.GenerateItem(Passport,Empty,1,false,Slotable)
			end
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONSULTITEM
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.ConsultItem(Passport,Item,Amount)
	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)
	local ItemAmount,ItemName,ItemSlot = table.unpack(vRP.InventoryItemAmount(Passport,Item))

	if ItemAmount >= Amount and not vRP.CheckDamaged(ItemName) then
		return { Amount = ItemAmount, Item = ItemName, Slot = ItemSlot }
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.GetWeight(Passport,Ignore)
	local Weight = 0
	local Passport = parseInt(Passport)
	local Datatable = vRP.Datatable(Passport)

	if Datatable then
		Datatable.Weight = Datatable.Weight or MinimumWeight
		Weight = Datatable.Weight

		if not Ignore then
			for Index,v in pairs(Groups) do
				if v and v.Backpack then
					local Permission = vRP.HasService(Passport,Index)
					if Permission and v.Backpack[Permission] then
						Weight = Weight + v.Backpack[Permission]
					end
				end
			end

			local Slotable = vRP.CheckSlotable(Passport,"4")
			if Slotable then
				Weight = Weight + exports.vrp:ItemBackpack(Slotable)
			end
		end
	end

	return Weight
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.CheckWeight(Passport,Item,Amount)
	return ((vRP.InventoryWeight(Passport) + (exports.vrp:ItemWeight(Item) * (Amount or 1))) <= vRP.GetWeight(Passport)) and true or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADEWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.UpgradeWeight(Passport,Amount,Mode)
	local Passport = parseInt(Passport)
	local Datatable = vRP.Datatable(Passport)
	if Datatable then
		Datatable.Weight = Datatable.Weight or MinimumWeight

		if Mode == "+" then
			Datatable.Weight = Datatable.Weight + Amount
		else
			Datatable.Weight = math.max(Datatable.Weight - Amount,MinimumWeight)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKSLOTABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CheckSlotable(Passport,Slot)
	local Slot = tostring(Slot)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)
	if Inventory and Inventory[Slot] and Inventory[Slot].item and exports.vrp:ItemExist(Inventory[Slot].item) and Inventory[Slot].item and Inventory[Slot].amount >= 1 and not vRP.CheckDamaged(Inventory[Slot].item) then
		return Inventory[Slot].item
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SWAPSLOT	
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.SwapSlot(Passport,Slot,Target)
	local Slot = tostring(Slot)
	local Target = tostring(Target)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	if Inventory[Slot] and Inventory[Target] then
		Inventory[Slot],Inventory[Target] = Inventory[Target],Inventory[Slot]
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventoryWeight(Passport)
	local Weight = 0
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)
	if not Inventory then
		return Weight
	end

	for _,v in next,Inventory do
		if exports.vrp:ItemExist(v.item) then
			Weight = Weight + exports.vrp:ItemWeight(v.item) * v.amount
		end
	end

	return Weight
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKDAMAGED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CheckDamaged(Item)
	local SplitTimer = SplitTwo(Item)
	local Durability = exports.vrp:ItemDurability(Item)

	if Durability and SplitTimer then
		local MaxTimer = 3600 * Durability
		return (os.time() - SplitTimer) >= (MaxTimer * 0.99)
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHESTWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ChestWeight(Data)
	local Weight = 0

	for _,v in pairs(Data) do
		if exports.vrp:ItemExist(v.item) then
			Weight = Weight + exports.vrp:ItemWeight(v.item) * v.amount
		end
	end

	return Weight
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYITEMAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventoryItemAmount(Passport,Item)
	local ItemSplit = SplitOne(Item)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for Slot,v in next,Inventory do
		if ItemSplit == SplitOne(v.item) then
			return { v.amount,v.item,Slot }
		end
	end

	return { 0,"" }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYFULL
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventoryFull(Passport,Item)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if v.item == Item then
			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ItemAmount(Passport,Item)
	local Amount = 0
	local ItemSplit = SplitOne(Item)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if SplitOne(v.item) == ItemSplit then
			Amount = Amount + v.amount
		end
	end

	return Amount
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMCHESTAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ItemChestAmount(Data,Item,Save)
	local Amount = 0
	local ItemSplit = SplitOne(Item)
	local Consult = vRP.GetSrvData(Data,Save)

	for _,v in pairs(Consult) do
		if SplitOne(v.item) == ItemSplit then
			Amount = Amount + v.amount
		end
	end

	return Amount
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GIVEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GiveItem(Passport,Item,Amount,Notify,Slot)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	if not Passport or not Item or Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Inventory = vRP.Inventory(Passport)
	if type(Inventory) ~= "table" then
		return false
	end

	local TargetSlot = nil
	local Slots = vRP.InventorySlots(Passport)

	if Slot then
		local Sloted = tostring(Slot)
		local Data = Inventory[Sloted]

		if not Data or Data.item == Item then
			TargetSlot = Sloted
		else
			return false
		end
	end

	if not TargetSlot then
		TargetSlot = FindSlot(Inventory,Slots,Item)
	end

	if not TargetSlot then
		TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
		exports.inventory:Drops(Passport,source,Item,Amount)
	else
		local Data = Inventory[TargetSlot]
		if not Data then
			Inventory[TargetSlot] = { item = Item, amount = Amount }
		else
			Data.amount = Data.amount + Amount
		end

		HandleItemEffects(source,Item,Amount,Notify)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GenerateItem(Passport,Item,Amount,Notify,Slot)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	if not Passport or not Item or Amount <= 0 then
		return false
	end

	local Inventory = vRP.Inventory(Passport)
	if type(Inventory) ~= "table" then
		return false
	end

	local TargetSlot = nil
	local source = vRP.Source(Passport)
	local Slots = vRP.InventorySlots(Passport)
	local NameItem = vRP.SortNameItem(Passport,Item)

	if Slot and tonumber(Slot) and tonumber(Slot) < Slots then
		local Data = Inventory[tostring(Slot)]
		if not Data or Data.item == NameItem then
			TargetSlot = tostring(Slot)
		end
	end

	if not TargetSlot then
		TargetSlot = FindSlot(Inventory,Slots,NameItem)
	end

	if not TargetSlot then
		if source then
			TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
			exports.inventory:Drops(Passport,source,NameItem,Amount)
		end

		return false
	end

	local Data = Inventory[TargetSlot]
	if not Data then
		Inventory[TargetSlot] = { item = NameItem, amount = Amount }
	else
		Data.amount = Data.amount + Amount
	end

	HandleItemEffects(source,NameItem,Amount,Notify)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAXITENS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.MaxItens(Passport,Item,Amount)
	local Item = Item
	if not exports.vrp:ItemExist(Item) then
		return false
	end

	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)
	local MaxAmount = exports.vrp:ItemMaxAmount(Item)
	if not MaxAmount or (vRP.ItemAmount(Passport,Item) + Amount) <= MaxAmount then
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAXCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.MaxChest(Data,Item,Amount,Save)
	local Item = Item
	if not exports.vrp:ItemExist(Item) then
		return false
	end

	local Data = Data
	local Amount = parseInt(Amount)
	local MaxAmount = exports.vrp:ItemMaxAmount(Item)
	if not MaxAmount or (vRP.ItemChestAmount(Data,Item,Save) + Amount) <= MaxAmount then
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.TakeItem(Passport,Item,Amount,Notify,Slot)
	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local SlotFound = nil
	local Inventory = vRP.Inventory(Passport)
	if type(Inventory) ~= "table" then
		return false
	end

	if Slot then
		local Sloted = tostring(Slot)
		local Data = Inventory[Sloted]
		if Data and Data.item == Item and Data.amount >= Amount then
			SlotFound = Sloted
		end
	else
		for Sloted,v in next,Inventory do
			if v.item == Item and v.amount >= Amount then
				SlotFound = Sloted
				break
			end
		end
	end

	if not SlotFound then
		return false
	end

	local Data = Inventory[SlotFound]
	Data.amount = Data.amount - Amount

	if Data.amount <= 0 then
		local HasItem = vRP.ConsultItem(Passport,Item)
		if not HasItem then
			local Animation = exports.vrp:ItemAnim(Item)
			if Animation and source then
				vRPC.PersistentNone(source,Item)
			end

			local Markers = exports.vrp:ItemMarkers(Item)
			if Markers and source then
				exports.markers:Exit(source,Markers)
			end
		end

		if exports.vrp:ItemTypeCheck(Item,"Armamento") or exports.vrp:ItemTypeCheck(Item,"Arremesso") then
			TriggerClientEvent("inventory:verifyWeapon",source,Item)
		end

		if SlotFound == "4" and exports.vrp:ItemSkinshop(Item) then
			TriggerClientEvent("skinshop:BackpackRemove",source)
		end

		local Execute = exports.vrp:ItemExecute(Item)
		if Execute and Execute.Event and Execute.Type and not HasItem then
			if Execute.Type == "Client" then
				TriggerClientEvent(Execute.Event,source)
			else
				TriggerEvent(Execute.Event,source,Passport)
			end
		end

		Inventory[SlotFound] = nil
	end

	if Notify and exports.vrp:ItemExist(Item) then
		TriggerClientEvent("inventory:NotifyItem",source,{ Index = Item, Amount = -Amount })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANSLOT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CleanSlot(Passport,Slot)
	local Slot = tostring(Slot)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	if Inventory[Slot] then
		Inventory[Slot] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANSLOTCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CleanSlotChest(Key,Slot,Save)
	local Slot = tostring(Slot)
	local Data = vRP.GetSrvData(Key,Save)

	if Data[Slot] then
		Data[Slot] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveItem(Passport,Item,Amount,Notify)
	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local SlotFound = nil
	local source = vRP.Source(Passport)
	local Inventory = vRP.Inventory(Passport)
	if not Inventory then
		return false
	end

	for Sloted,v in pairs(Inventory) do
		if v.item == Item and v.amount >= Amount then
			SlotFound = tostring(Sloted)
			break
		end
	end

	if not SlotFound then
		return false
	end

	local Data = Inventory[SlotFound]
	Data.amount = Data.amount - Amount

	if Data.amount <= 0 then
		local HasItem = vRP.ConsultItem(Passport,Item)
		if not HasItem then
			local Animation = exports.vrp:ItemAnim(Item)
			if Animation and source then
				vRPC.PersistentNone(source,Item)
			end

			local Markers = exports.vrp:ItemMarkers(Item)
			if Markers and source then
				exports.markers:Exit(source,Markers)
			end
		end

		if source and (exports.vrp:ItemTypeCheck(Item,"Armamento") or exports.vrp:ItemTypeCheck(Item,"Arremesso")) then
			TriggerClientEvent("inventory:verifyWeapon",source,Item)
		end

		if exports.vrp:ItemUnique(Item) then
			local Unique = SplitUnique(Item)
			if Unique then
				vRP.RemSrvData(Unique)
			end
		end

		local Execute = exports.vrp:ItemExecute(Item)
		if Execute and Execute.Event and Execute.Type and not HasItem then
			if Execute.Type == "Client" then
				TriggerClientEvent(Execute.Event,source)
			else
				TriggerEvent(Execute.Event,source,Passport)
			end
		end

		Inventory[SlotFound] = nil
	end

	if Notify and exports.vrp:ItemExist(Item) and source then
		TriggerClientEvent("inventory:NotifyItem",source,{ Index = Item, Amount = -Amount })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETSRVDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetSrvData(Key,Save)
	if not Entitys[Key] then
		local Decoded = {}
		local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = Key })
		if Consult and Consult.Information then
			local Success,Result = pcall(json.decode,Consult.Information)
			if Success and type(Result) == "table" then
				Decoded = Result
			end
		end

		Entitys[Key] = {
			Data = Decoded,
			Save = Save and true or false,
			Timer = os.time() + 300
		}
	end

	return Entitys[Key].Data
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETSRVDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetSrvData(Key,Data,Save)
	Entitys[Key] = {
		Data = Data,
		Timer = os.time() + 300,
		Save = Save and true or false
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMSRVDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemSrvData(Key,Ignore)
	if Entitys[Key] then
		Entitys[Key] = nil
	end

	if not Ignore then
		vRP.Query("entitydata/RemoveData",{ Name = Key })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETSRVDATAGLOBAL
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetSrvDataGlobal()
	return Entitys
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	for Key,v in pairs(Entitys) do
		if v.Save then
			local Success,Encoded = pcall(json.encode,v.Data)
			if Success then
				vRP.Query("entitydata/SetData",{ Name = Key, Information = Encoded })
			end
		elseif not Silenced and SplitOne(Key,":") == "Trash" then
			for _,x in pairs(v.Data) do
				if x.item and exports.vrp:ItemUnique(x.item) then
					local Unique = SplitUnique(x.item)
					if Unique then
						vRP.RemSrvData(Unique)
					end
				end
			end
		end
	end

	for Passport in pairs(Sources) do
		local Datatable = vRP.Datatable(Passport)
		if Datatable then
			local Success,Encoded = pcall(json.encode,Datatable)
			if Success then
				vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Datatable", Information = Encoded })
			end
		end
	end

	if not Silenced then
		print("O resource ^2vRP^7 salvou os dados.")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(60000)

		local CurrentTime = os.time()
		for Key,v in pairs(Entitys) do
			if CurrentTime > v.Timer and v.Save then
				local Success,Encoded = pcall(json.encode,v.Data)
				if Success then
					vRP.Query("entitydata/SetData",{ Name = Key, Information = Encoded })
				end

				Entitys[Key] = nil
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVUPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.invUpdate(Slot,Target,Amount)
	local source = source
	local Returned = false
	local Amount = parseInt(Amount)
	local Passport = vRP.Passport(source)

	if not Passport or Amount <= 0 then
		return Returned
	end

	local Slot = tostring(Slot)
	local Target = tostring(Target)
	local Inventory = vRP.Inventory(Passport)
	local TargetData = Inventory[Target]
	local SlotData = Inventory[Slot]

	if not SlotData then
		return Returned
	end

	local Item = SlotData.item
	local ItemTarget = TargetData and TargetData.item

	if TargetData and Item == ItemTarget then
		if SlotData.amount >= Amount then
			SlotData.amount = SlotData.amount - Amount
			TargetData.amount = TargetData.amount + Amount

			if SlotData.amount <= 0 then
				Inventory[Slot] = nil
			end

			Returned = true
		end
	elseif TargetData then
		local Unique = SplitOne(Item)
		local Splice = splitString(ItemTarget)
		local ItemRepair = exports.vrp:ItemRepair(ItemTarget)
		local ItemFishing = exports.vrp:ItemFishing(ItemTarget)

		if Unique == "gsrkit" and exports.vrp:ItemSerial(Splice[1]) then
			if vRP.TakeItem(Passport,Item,1,false,Slot) then
				if Splice[4] then
					TriggerClientEvent("inventory:Notify",source,"Sucesso","Propriedade do passaporte <b>"..Splice[4].."</b>","verde")
				else
					TriggerClientEvent("inventory:Notify",source,"Aviso","Serial não encontrado.","amarelo")
				end
			end
		elseif Unique == "WEAPON_SWITCHBLADE" and not vRP.CheckDamaged(Item) and ItemFishing then
			local Count = TargetData.amount
			if vRP.TakeItem(Passport,ItemTarget,Count,false,Target) then
				vRP.GenerateItem(Passport,"fishfillet",Count * ItemFishing)
			end
		elseif vRP.CheckDamaged(ItemTarget) and ItemRepair and TargetData.amount == 1 and ItemRepair == Unique then
			if exports.vrp:ItemTypeCheck(ItemTarget,"Armamento") and parseInt(Splice[3]) <= 0 then
				TriggerClientEvent("inventory:Notify",source,"Aviso","Armamento não pode ser reparado.","amarelo")
			elseif vRP.TakeItem(Passport,Item,1,false,Slot) then
				local CurrentTime = os.time() - 1

				if exports.vrp:ItemTypeCheck(ItemTarget,"Armamento") then
					local Serial = Splice[4] and "-"..(Passport or "")
					Inventory[Target].item = Splice[1].."-"..CurrentTime.."-"..parseInt(Splice[3] - 1)..Serial
				elseif exports.vrp:ItemUnique(Splice[1]) then
					Inventory[Target].item = Splice[1].."-"..CurrentTime.."-"..Splice[3]
				else
					Inventory[Target].item = Splice[1].."-"..CurrentTime
				end
			end
		elseif (Slot == "4" and exports.vrp:ItemBackpack(ItemTarget) > 0) or (Target == "4" and exports.vrp:ItemBackpack(Item) > 0) or (Slot ~= "4" and Target ~= "4") then
			Inventory[Slot] = TargetData
			Inventory[Target] = SlotData
			Returned = true
		end
	elseif SlotData.amount >= Amount and (Target ~= "4" or exports.vrp:ItemBackpack(Item) > 0) then
		Inventory[Target] = { item = Item, amount = Amount }
		SlotData.amount = SlotData.amount - Amount

		if SlotData.amount <= 0 then
			Inventory[Slot] = nil
		end

		Returned = true
	end

	if Item and (not Returned or Target == "4" or Slot == "4") then
		TriggerClientEvent("inventory:Update",source)

		local Skinshop = exports.vrp:ItemSkinshop(Item)
		if Skinshop then
			if Target == "4" then
				TriggerClientEvent("skinshop:Backpack",source,Skinshop)
			elseif Slot == "4" then
				TriggerClientEvent("skinshop:BackpackRemove",source)
			end
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKECHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.TakeChest(Passport,Data,Amount,Slot,Target,Save)
	local Returned = true
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount <= 0 then
		return Returned
	end

	local Slot = tostring(Slot)
	local Consult = vRP.GetSrvData(Data,Save)

	if not Consult[Slot] then
		return Returned
	end

	local source = vRP.Source(Passport)
	local Item = Consult[Slot].item

	if vRP.MaxItens(Passport,Item,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Atenção","Limite atingido.","vermelho")
		return Returned
	end

	if not vRP.CheckWeight(Passport,Item,Amount) then
		return Returned
	end

	local Target = tostring(Target)
	local Inv = vRP.Inventory(Passport)

	if Inv[Target] then
		if Inv[Target].item == Item and Consult[Slot].amount >= Amount then
			exports.discord:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Retirou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item)

			Inv[Target].amount = Inv[Target].amount + Amount
			Consult[Slot].amount = Consult[Slot].amount - Amount

			if Consult[Slot].amount <= 0 then
				Consult[Slot] = nil
			end

			Returned = false
		end
	else
		if Consult[Slot].amount >= Amount then
			exports.discord:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Retirou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item)

			Inv[Target] = { item = Item, amount = Amount }
			Consult[Slot].amount = Consult[Slot].amount - Amount

			if Consult[Slot].amount <= 0 then
				Consult[Slot] = nil
			end

			local Animation = exports.vrp:ItemAnim(Item)
			if Animation and source then
				vRPC.PersistentBlock(source,Item,Animation)
			end

			local Markers = exports.vrp:ItemMarkers(Item)
			if Markers and source then
				exports.markers:Enter(source,Markers)
			end

			if exports.vrp:ItemTypeCheck(Item,"Armamento") and vRP.ConsultItem(Passport,Item) then
				TriggerClientEvent("inventory:CreateWeapon",source,Item)
			end

			TriggerClientEvent("inventory:Update",source)

			if Target == "4" then
				local Skinshop = exports.vrp:ItemSkinshop(Item)
				if Skinshop then
					TriggerClientEvent("skinshop:Backpack",source,Skinshop)
				end
			end

			Returned = false
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORECHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.StoreChest(Passport,Data,Amount,Weight,Slot,Target,Save,Max)
	local Returned = true
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount <= 0 then
		return Returned
	end

	local Slot = tostring(Slot)
	local Inv = vRP.Inventory(Passport)

	if Inv[Slot] then
		local Item = Inv[Slot].item
		if not Max or not vRP.MaxChest(Data,Item,Amount,Save) then
			local Target = tostring(Target)
			local source = vRP.Source(Passport)
			local Consult = vRP.GetSrvData(Data,Save)

			if (vRP.ChestWeight(Consult) + (exports.vrp:ItemWeight(Item) * Amount)) <= Weight then
				if Consult[Target] and Inv[Slot] then
					if Item == Consult[Target].item and Inv[Slot].amount >= Amount then
						exports.discord:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Guardou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item)

						Consult[Target].amount = Consult[Target].amount + Amount
						Inv[Slot].amount = Inv[Slot].amount - Amount

						if Inv[Slot].amount <= 0 then
							Inv[Slot] = nil

							if Slot == "4" then
								TriggerClientEvent("inventory:Update",source)

								local Skinshop = exports.vrp:ItemSkinshop(Item)
								if Skinshop then
									TriggerClientEvent("skinshop:BackpackRemove",source)
								end
							end

							local HasItem = vRP.ConsultItem(Passport,Item)
							if not HasItem then
								local Animation = exports.vrp:ItemAnim(Item)
								if Animation and source then
									vRPC.PersistentNone(source,Item)
								end

								local Markers = exports.vrp:ItemMarkers(Item)
								if Markers and source then
									exports.markers:Exit(source,Markers)
								end
							end

							if exports.vrp:ItemTypeCheck(Item,"Armamento") or exports.vrp:ItemTypeCheck(Item,"Arremesso") then
								TriggerClientEvent("inventory:verifyWeapon",source,Item)
							end

							local Execute = exports.vrp:ItemExecute(Item)
							if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
								if Execute.Type == "Client" then
									TriggerClientEvent(Execute.Event,source)
								else
									TriggerEvent(Execute.Event,source,Passport)
								end
							end
						end

						Returned = false
					end
				else
					if Inv[Slot] and Inv[Slot].amount >= Amount then
						exports.discord:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Guardou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item)

						Consult[Target] = { item = Item, amount = Amount }
						Inv[Slot].amount = Inv[Slot].amount - Amount

						if Inv[Slot].amount <= 0 then
							Inv[Slot] = nil

							if Slot == "4" then
								TriggerClientEvent("inventory:Update",source)

								local Skinshop = exports.vrp:ItemSkinshop(Item)
								if Skinshop then
									TriggerClientEvent("skinshop:BackpackRemove",source)
								end
							end

							local HasItem = vRP.ConsultItem(Passport,Item)
							if not HasItem then
								local Animation = exports.vrp:ItemAnim(Item)
								if Animation and source then
									vRPC.PersistentNone(source,Item)
								end

								local Markers = exports.vrp:ItemMarkers(Item)
								if Markers and source then
									exports.markers:Exit(source,Markers)
								end
							end

							if exports.vrp:ItemTypeCheck(Item,"Armamento") or exports.vrp:ItemTypeCheck(Item,"Arremesso") then
								TriggerClientEvent("inventory:verifyWeapon",source,Item)
							end

							local Execute = exports.vrp:ItemExecute(Item)
							if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
								if Execute.Type == "Client" then
									TriggerClientEvent(Execute.Event,source)
								else
									TriggerEvent(Execute.Event,source,Passport)
								end
							end
						end

						Returned = false
					end
				end
			else
				TriggerClientEvent("inventory:Notify",source,"Atenção","Limite de peso atingido.","vermelho")
			end
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATECHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateChest(Passport,Data,Slot,Target,Amount,Save)
	local Returned = true
	local Slot = tostring(Slot)
	local Target = tostring(Target)
	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)
	local Consult = vRP.GetSrvData(Data,Save)

	if Consult[Slot] then
		if Consult[Target] and Consult[Slot].item == Consult[Target].item then
			if Consult[Slot].amount >= Amount then
				Consult[Slot].amount = Consult[Slot].amount - Amount

				if Consult[Slot].amount <= 0 then
					Consult[Slot] = nil
				end

				Consult[Target].amount = Consult[Target].amount + Amount

				Returned = false
			end
		elseif Consult[Target] then
			local Temp = Consult[Slot]
			Consult[Slot] = Consult[Target]
			Consult[Target] = Temp

			Returned = false
		else
			if Consult[Slot].amount >= Amount then
				Consult[Target] = { item = Consult[Slot].item, amount = Amount }
				Consult[Slot].amount = Consult[Slot].amount - Amount

				if Consult[Slot].amount <= 0 then
					Consult[Slot] = nil
				end

				Returned = false
			end
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARRESTITENS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ArrestItens(Passport)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if exports.vrp:ItemArrest(v.item) then
			vRP.RemoveItem(Passport,v.item,v.amount,true)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNTCONTAINER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.MountContainer(Passport,Datatable,Table,Multiplier,Save,Percentage,Dollars)
	local Itens = {}
	local Exists = {}
	local Attempts = 0
	local Passport = Passport
	local Multiplier = parseInt(Multiplier,true)

	if not Percentage or math.random(1000) <= Percentage then
		for Number = 0,(Multiplier - 1) do
			repeat
				Attempts = Attempts + 1
				Rand = RandPercentage(Table)
			until (not Exists[Rand.Item] or Attempts > 1000)

			Exists[Rand.Item] = true

			Itens[tostring(Number)] = {
				item = vRP.SortNameItem(Passport,Rand.Item),
				amount = math.random(Rand.Min,Rand.Max)
			}
		end

		if Dollars then
			local Amount = CountTable(Itens)
			Itens[tostring(Amount)] = {
				item = vRP.SortNameItem(Passport,Dollars.Item),
				amount = parseInt(Dollars.Amount)
			}
		end
	end

	vRP.SetSrvData(Datatable,Itens,Save or false)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SORTNAMEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SortNameItem(Passport,Item)
	local NameItem = Item
	local Passport = Passport
	local CurrentTimer = os.time() - 1

	if exports.vrp:ItemUnique(Item) then
		local Hash = vRP.GenerateHash(Item)

		if Boxes[Item] then
			local MultiplierMin = Boxes[Item].Multiplier.Min
			local MultiplierMax = Boxes[Item].Multiplier.Max
			vRP.MountContainer(Passport,Item..":"..Hash,Boxes[Item].List,math.random(MultiplierMin,MultiplierMax),true)
		end

		NameItem = Item.."-"..CurrentTimer.."-"..Hash
	elseif exports.vrp:ItemDurability(Item) then
		if exports.vrp:ItemTypeCheck(Item,"Armamento") then
			NameItem = Item.."-"..CurrentTimer.."-"..MaxRepair.."-"..Passport
		else
			NameItem = Item.."-"..CurrentTimer
		end
	elseif exports.vrp:ItemLoads(Item) then
		NameItem = Item.."-"..exports.vrp:ItemLoads(Item)
	elseif exports.vrp:ItemNamed(Item) then
		NameItem = Item.."-"..Passport
	end

	return NameItem
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CALLPOLICE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("CallPolice",function(Table)
	if Table.Percentage and math.random(1000) < Table.Percentage then
		return false
	end

	local source = Table.Source
	local passport = Table.Passport

	if Table.Wanted then
		TriggerEvent("Wanted",source,passport,Table.Wanted)
	end

	if Table.Notify then
		TriggerClientEvent("Notify",source,"Departamento Policial","As autoridades foram acionadas.","policia",5000)
	end

	local Service = vRP.NumPermission(Table.Permission)
	local Coords = Table.Coords or vRP.GetEntityCoords(source)
	for _,OtherSource in pairs(Service) do
		async(function()
			vRPC.PlaySound(OtherSource,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")
			TriggerClientEvent("NotifyPush",OtherSource,{ code = Table.Code or 20, title = Table.Name, x = Coords.x, y = Coords.y, z = Coords.z, vehicle = Table.Vehicle, color = Table.Color or 44 })
		end)
	end
end)