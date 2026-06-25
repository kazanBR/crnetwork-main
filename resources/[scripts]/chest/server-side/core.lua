-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("chest",Creative)
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Open = {}
local Cooldown = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHESTITENS
-----------------------------------------------------------------------------------------------------------------------------------------
local ChestItens = {
	["chestgroupp"] = {
		Slots = 100,
		Weight = 1000,
		Block = true
	},
	["chestgroupm"] = {
		Slots = 100,
		Weight = 2500,
		Block = true
	},
	["chestgroupg"] = {
		Slots = 100,
		Weight = 5000,
		Block = true
	},
	["suitcase"] = {
		Slots = 25,
		Weight = 10,
		Close = true,
		Itens = {
			["dollar"] = true,
			["dirtydollar"] = true,
			["wetdollar"] = true,
			["promissory"] = true
		}
	},
	["ammobox"] = {
		Slots = 25,
		Weight = 12,
		Close = true,
		Itens = {
			["WEAPON_PISTOL_AMMO"] = true,
			["WEAPON_SMG_AMMO"] = true,
			["WEAPON_RIFLE_AMMO"] = true,
			["WEAPON_SHOTGUN_AMMO"] = true,
			["WEAPON_MUSKET_AMMO"] = true
		}
	},
	["weaponbox"] = {
		Slots = 50,
		Weight = 100,
		Close = true,
		Itens = {
			["WEAPON_STUNGUN"] = true,
			["WEAPON_PISTOL"] = true,
			["WEAPON_PISTOL_MK2"] = true,
			["WEAPON_COMPACTRIFLE"] = true,
			["WEAPON_APPISTOL"] = true,
			["WEAPON_HEAVYPISTOL"] = true,
			["WEAPON_MACHINEPISTOL"] = true,
			["WEAPON_MICROSMG"] = true,
			["WEAPON_RPG"] = true,
			["WEAPON_MINISMG"] = true,
			["WEAPON_SNSPISTOL"] = true,
			["WEAPON_SNSPISTOL_MK2"] = true,
			["WEAPON_VINTAGEPISTOL"] = true,
			["WEAPON_PISTOL50"] = true,
			["WEAPON_COMBATPISTOL"] = true,
			["WEAPON_CARBINERIFLE"] = true,
			["WEAPON_CARBINERIFLE_MK2"] = true,
			["WEAPON_ADVANCEDRIFLE"] = true,
			["WEAPON_BULLPUPRIFLE"] = true,
			["WEAPON_BULLPUPRIFLE_MK2"] = true,
			["WEAPON_SPECIALCARBINE"] = true,
			["WEAPON_SPECIALCARBINE_MK2"] = true,
			["WEAPON_PUMPSHOTGUN"] = true,
			["WEAPON_PUMPSHOTGUN_MK2"] = true,
			["WEAPON_MUSKET"] = true,
			["WEAPON_SAWNOFFSHOTGUN"] = true,
			["WEAPON_SMG"] = true,
			["WEAPON_SMG_MK2"] = true,
			["WEAPON_TACTICALRIFLE"] = true,
			["WEAPON_HEAVYRIFLE"] = true,
			["WEAPON_ASSAULTRIFLE"] = true,
			["WEAPON_ASSAULTRIFLE_MK2"] = true,
			["WEAPON_ASSAULTSMG"] = true,
			["WEAPON_GUSENBERG"] = true
		}
	},
	["medicbag"] = {
		Slots = 25,
		Weight = 10,
		Close = true,
		Itens = {
			bandage = true,
			gauze = true,
			gdtkit = true,
			medkit = true,
			sinkalmy = true,
			analgesic = true,
			ritmoneury = true,
			adrenaline = true
		}
	},
	["mechanicbag"] = {
		Slots = 5,
		Weight = 20,
		Close = true,
		Itens = {
			advtoolbox = true,
			toolbox = true,
			WEAPON_WRENCH = true,
			tyres = true
		}
	},
	["treasurebox"] = {
		Slots = 25,
		Weight = 50,
		Close = true
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permissions(Name,Mode,Item)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport then
		return false
	end

	if Mode == "Goals" then
		local SplitName = splitString(Name,":")
		if SplitName[1] and SplitName[2] and SplitName[3] and SplitName[1] == "Painel" and SplitName[2] == "Goals" then
			if vRP.HasService(Passport,SplitName[3]) then
				Open[Passport] = {
					Name = "Goals:"..SplitName[3],
					Permission = SplitName[3],
					Weight = 1000,
					Save = true,
					Slots = 200,
					Goals = true
				}

				return true
			end
		end
	elseif Mode == "Personal" then
		local ServiceName = SplitOne(Name)
		if vRP.HasService(Passport,ServiceName) then
			Open[Passport] = {
				Name = "Personal:"..Passport,
				Weight = 50,
				Save = true,
				Slots = 25
			}

			return true
		end
	elseif Mode == "Tray" then
		local isRecycle = (Name == "Recycle")

		Open[Passport] = {
			Slots = 25,
			Name = Name,
			Save = true,
			Recycle = isRecycle,
			Weight = isRecycle and 100 or 25
		}

		return true
	elseif Mode == "Custom" or Mode == "Trash" then
		if SplitBoolean(Name,"Helicrash",":") and Cooldown[Name] and Cooldown[Name] > os.time() then
			TriggerClientEvent("Notify",source,"Atenção","Aguarde até que esfrie o compartimento.","amarelo",10000)
			vRPC.DowngradeHealth(source,10)

			return false
		end

		Open[Passport] = {
			Name = (Mode == "Trash" and "Trash:"..Name or Name),
			Weight = 50,
			Slots = 25,
			Mode = "Custom"
		}

		return true
	elseif Mode == "Item" then
		local UniqueName = SplitOne(Name,":")
		if ChestItens[UniqueName] then
			Open[Passport] = {
				Name = Name,
				Save = true,
				Unique = UniqueName,
				Slots = ChestItens[UniqueName].Slots,
				Weight = ChestItens[UniqueName].Weight,
				Item = Item
			}

			return true
		end
	else
		local Consult = vRP.SingleQuery("chests/GetChests",{ Name = Name })
		if not Consult then
			vRP.Query("chests/AddChests",{ Name = Name })
			Consult = vRP.SingleQuery("chests/GetChests",{ Name = Name })
		end

		if Consult and vRP.HasService(Passport,Consult.Permission) then
			local IsPremium = vRP.Permissions(Consult.Permission,"Premium") > os.time()

			Open[Passport] = {
				Weight = IsPremium and Consult.Weight * 2 or Consult.Weight,
				Chest = Name,
				Slots = Consult.Slots,
				Name = "Chest:"..Name,
				Save = true
			}

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mount()
	local source = source
	local Passport = vRP.Passport(source)

	if not (Passport and Open[Passport]) then
		return false
	end

	local function ProcessItem(Slot,v,Prefix,Key,Save)
		if v.amount <= 0 or not exports.vrp:ItemExist(v.item) then
			if Prefix == "Inventory" then
				vRP.CleanSlot(Passport,Slot)
			elseif Prefix == "Chest" then
				vRP.CleanSlotChest(Key,Slot,Save)
			end

			return false
		end

		v.key = v.item

		local Split = splitString(v.item)
		local Item = Split[1]

		if Prefix == "Inventory" and ChestItens[Item] and ChestItens[Item].Close then
			v.block = true
		end

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

		return v
	end

	local Primary = {}
	local Inventory = vRP.Inventory(Passport)
	for Slot,v in pairs(Inventory) do
		local Processed = ProcessItem(Slot,v,"Inventory")
		if Processed then
			Primary[Slot] = Processed
		end
	end

	local Secondary = {}
	if Open[Passport] and Open[Passport].Name then
		local ChestData = Open[Passport].Name
		local Chest = vRP.GetSrvData(ChestData,Open[Passport].Save)
		for Slot,v in pairs(Chest) do
			local Processed = ProcessItem(Slot,v,"Chest",ChestData,Open[Passport].Save)
			if Processed then
				Secondary[Slot] = Processed
			end
		end
	end

	return Primary,Secondary,vRP.GetWeight(Passport),Open[Passport].Weight,vRP.InventorySlots(Passport),Open[Passport].Slots
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Store(Item,Slot,Amount,Target,Inactived)
	local source = source
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	local OpenData = Passport and Open[Passport]
	if not Passport or not OpenData or Inactived then
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	local function UpdateInventory()
		TriggerClientEvent("inventory:Update",source)
	end

	local function NotifyError(Message)
		TriggerClientEvent("inventory:Notify",source,"Atenção",Message,"amarelo")
		UpdateInventory()
	end

	if OpenData.Recycle then
		if exports.vrp:ItemDurability(Item) and not vRP.CheckDamaged(Item) then
			NotifyError(exports.vrp:ItemName(Item).." não pode ser reciclado.")
			return false
		end

		local Recycled = exports.vrp:ItemRecycle(Item)
		if not Recycled or not vRP.TakeItem(Passport,Item,Amount) then
			NotifyError(exports.vrp:ItemName(Item).." não pode ser reciclado.")
			return false
		end

		for Index,Number in pairs(Recycled) do
			vRP.GenerateItem(Passport,Index,Number * Amount)
		end

		UpdateInventory()

		return false
	else
		if exports.vrp:ItemLocked(Item) then
			UpdateInventory()
			return false
		end
	end

	if Item == "diagram" and OpenData.Chest and vRP.TakeItem(Passport,Item,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Sucesso","Armazenamento melhorado.","verde")
		vRP.Update("chests/UpdateWeight",{ Name = OpenData.Chest, Multiplier = Amount })
		OpenData.Weight = OpenData.Weight + (10 * Amount)
		UpdateInventory()

		return false
	end

	local Cleaned = SplitOne(Item)
	local Uniqued = OpenData.Unique
	local ChestConfig = ChestItens[Uniqued]
	if (ChestItens[Cleaned] and ChestItens[Cleaned].Block) or (Uniqued and ChestConfig and ChestConfig.Itens and not ChestConfig.Itens[Cleaned]) then
		if Uniqued and Cleaned == Uniqued then
			TriggerClientEvent("inventory:Open",source,{
				Type = "Inventory",
				Resource = "inventory",
				Right = "Proximidade"
			},true)
		else
			UpdateInventory()
		end

		return false
	end

	if OpenData.Goals and OpenData.Permission then
		if exports.vrp:ItemDurability(Item) and vRP.CheckDamaged(Item) then
			UpdateInventory()
			return false
		end

		local Weekday = os.date("*t")
		local Goals = vRP.GetSrvData("Painel:Goals:"..OpenData.Permission,true) or {}
		local MyGoals = vRP.GetSrvData("Goals:"..OpenData.Permission..":"..Passport,true) or {}

		MyGoals.Items = MyGoals.Items or {}
		MyGoals.Week = MyGoals.Week or { false,false,false,false,false,false,false }
		MyGoals.Rescued = MyGoals.Rescued or false

		if not Goals.Items then
			UpdateInventory()
			return false
		end

		local Limit = Goals.Items[Cleaned]
		if not Limit then
			UpdateInventory()
			return false
		end

		MyGoals.Items[Cleaned] = MyGoals.Items[Cleaned] or 0

		if (MyGoals.Items[Cleaned] + Amount) > Limit then
			UpdateInventory()
			return false
		end

		if vRP.StoreChest(Passport,OpenData.Name,Amount,OpenData.Weight,Slot,Target,OpenData.Save,ChestConfig) then
			UpdateInventory()
			return false
		end

		MyGoals.Items[Cleaned] = MyGoals.Items[Cleaned] + Amount

		local Completed = true
		for Item,Needed in pairs(Goals.Items) do
			if (MyGoals.Items[Item] or 0) < Needed then
				Completed = false
				break
			end
		end

		if Completed then
			MyGoals.Week[Weekday.wday] = true
		end

		vRP.SetSrvData("Goals:"..OpenData.Permission..":"..Passport,MyGoals,true)
	else
		if vRP.StoreChest(Passport,OpenData.Name,Amount,OpenData.Weight,Slot,Target,OpenData.Save,ChestConfig) then
			UpdateInventory()
			return false
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Take(Item,Slot,Amount,Target,Inactived)
	local source = source
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if not Passport or not Open[Passport] then
		TriggerClientEvent("inventory:Update",source)

		return false
	end

	if Inactived then
		local Permission = Open[Passport].Permission
		if not Permission or not vRP.HasService(Passport,Permission,2) then
			TriggerClientEvent("inventory:Update",source)

			return false
		end
	end

	local Name = Open[Passport].Name
	local Saved = Open[Passport].Save
	if vRP.TakeChest(Passport,Name,Amount,Slot,Target,Saved) then
		TriggerClientEvent("inventory:Update",source)

		return false
	end

	local Data = vRP.GetSrvData(Name,Saved)    
	if (Open[Passport].Mode or Open[Passport].Item) and json.encode(Data) == "[]" then
		if Open[Passport].Item and vRP.TakeItem(Passport,Open[Passport].Item) then
			TriggerClientEvent("inventory:Open",source,{ Type = "Inventory", Resource = "inventory", Right = "Baú" },true)
		end

		if SplitBoolean(Name,"Helicrash",":") then
			GlobalState.Helibox = (GlobalState.Helibox or 1) - 1
		elseif SplitBoolean(Name,"Halloween",":") then
			GlobalState.Hallobox = (GlobalState.Hallobox or 1) - 1
			GlobalState[Name] = false
		elseif SplitBoolean(Name,"Christmas",":") then
			GlobalState.Christbox = (GlobalState.Christbox or 1) - 1
			GlobalState[Name] = false
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Slot,Target,Amount)
	local source = source
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)

	if not Passport or not Open[Passport] then
		return false
	end

	local Name = Open[Passport].Name
	local Saved = Open[Passport].Save
	if vRP.UpdateChest(Passport,Name,Slot,Target,Amount,Saved) then
		TriggerClientEvent("inventory:Update",source)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEST:COOLDOWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("chest:Cooldown",function(Name)
	Cooldown[Name] = os.time() + 600
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEST:ARMOUR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("chest:Armour")
AddEventHandler("chest:Armour",function()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasService(Passport,"Policia") then
		vRP.Armour(source,100)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Open[Passport] then
		Open[Passport] = nil
	end
end)