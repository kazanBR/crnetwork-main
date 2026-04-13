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
Tunnel.bindInterface("shops",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permission(Name)
	local source = source
	local Data = List[Name]
	local Passport = vRP.Passport(source)
	if not Passport or not Data then
		return false
	end

	if Name ~= "Banned" and (exports.bank:CheckTaxes(Passport) or exports.bank:CheckFines(Passport)) then
		return false
	end

	if not Data.Permission then
		return true
	end

	return vRP.HasService(Passport,Data.Permission) and true or false
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
			if v.amount <= 0 or not ItemExist(v.item) then
				vRP.CleanSlot(Passport,Slot)
			else
				v.key = v.item

				local Split = splitString(v.item)
				local Item = Split[1]

				if not v.desc then
					if Item == "vehiclekey" and Split[3] then
						local Consult = exports.oxmysql:single_async("SELECT * FROM vehicles WHERE Plate = ? LIMIT 1",{ Split[3] })
						if Consult and VehicleExist(Consult.Vehicle) then
							v.desc = "Proprietário: <common>"..vRP.FullName(Consult.Passport).."</common><br>Modelo: <common>"..VehicleName(Consult.Vehicle).."</common><br>Placa: <common>"..Split[3].."</common>"
						end
					elseif Item == "propertys" and Split[2] then
						local Consult = exports.oxmysql:single_async("SELECT * FROM propertys WHERE Serial = ? LIMIT 1",{ Split[2] })
						if Consult then
							v.desc = "Proprietário: <common>"..vRP.FullName(Consult.Passport).."</common>"
						end
					elseif ItemNamed(Item) and Split[2] and vRP.Identity(Split[2]) then
						if Item == "identity" then
							v.desc = "Passaporte: <rare>"..Dotted(Split[2]).."</rare><br>Nome: <rare>"..vRP.FullName(Split[2]).."</rare><br>Telefone: <rare>"..vRP.Phone(Split[2]).."</rare>"
						else
							v.desc = "Proprietário: <common>"..vRP.FullName(Split[2]).."</common>"
						end
					end
				end

				if Split[2] then
					local Loaded = ItemLoads(v.item)
					if Loaded then
						v.charges = parseInt(Split[2] * (100 / Loaded))
					end

					if ItemDurability(v.item) then
						v.durability = parseInt(os.time() - Split[2])
						v.days = ItemDurability(v.item)
					end
				end

				Primary[Slot] = v
			end
		end

		return Primary,vRP.GetWeight(Passport)
	end
end
---------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Take(Item,Amount,Target,Name)
	local source = source
	local Target = tostring(Target)
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if Passport and Item and Target and List[Name] and List[Name]["Type"] and List[Name]["List"] and List[Name]["List"][Item] then
		if Amount > 1 and (ItemUnique(Item) or ItemLoads(Item)) then
			Amount = 1
		end

		if List[Name].Route and List[Name].Route ~= GetPlayerRoutingBucket(source) then
			TriggerClientEvent("inventory:Update",source)
			return false
		end

		local Inventory = vRP.Inventory(Passport)
		if not vRP.MaxItens(Passport,Item,Amount) and vRP.CheckWeight(Passport,Item,Amount) and (not Inventory[Target] or (Inventory[Target] and Inventory[Target]["item"] == Item)) then
			if List[Name]["Type"] == "Cash" then
				if vRP.PaymentFull(Passport,List[Name]["List"][Item] * Amount) then
					vRP.GenerateItem(Passport,Item,Amount,false,Target)
				else
					TriggerClientEvent("inventory:Notify",source,"Aviso","Dinheiro insuficiente.","amarelo")
				end
			elseif List[Name]["Type"] == "Consume" and List[Name]["Item"] then
				if vRP.TakeItem(Passport,List[Name]["Item"],List[Name]["List"][Item] * Amount) then
					vRP.GenerateItem(Passport,Item,Amount,false,Target)
				else
					TriggerClientEvent("inventory:Notify",source,"Atenção","<b>"..ItemName(List[Name]["Item"]).."</b> insuficiente.","vermelho")
				end
			elseif List[Name]["Type"] == "Gemstone" then
				if vRP.PaymentGems(Passport,List[Name]["List"][Item] * Amount) then
					vRP.GenerateItem(Passport,Item,Amount,false,Target)
				else
					TriggerClientEvent("inventory:Notify",source,"Atenção","<b>Diamantes</b> insuficiente.","vermelho")
				end
			end
		end
	end

	TriggerClientEvent("inventory:Update",source)
end
---------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Store(Item,Amount,Slot,Name)
	local source = source
	local Split = SplitOne(Item)
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if Passport and List[Name] and List[Name]["List"] and List[Name]["Type"] and List[Name]["List"][Split] and not vRP.CheckDamaged(Item) then
		if List[Name]["Type"] == "Cash" then
			if vRP.TakeItem(Passport,Item,Amount,false,Slot) then
				vRP.GenerateItem(Passport,"dollar",List[Name]["List"][Split] * Amount,false)
			end
		elseif List[Name]["Type"] == "Consume" then
			if vRP.TakeItem(Passport,Item,Amount,false,Slot) then
				vRP.GenerateItem(Passport,List[Name]["Item"],List[Name]["List"][Split] * Amount,false)
			end
		end
	end

	TriggerClientEvent("inventory:Update",source)
end