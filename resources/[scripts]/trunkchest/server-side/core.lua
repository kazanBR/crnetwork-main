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
Tunnel.bindInterface("trunkchest",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Open = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
local Store = {
	ratloader = {
		woodlog = true
	},
	stockade = {
		pouch = true
	},
	trash = {
		binbag = true
	},
	flatbed = {
		plastic = true,
		glass = true,
		rubber = true,
		aluminum = true,
		tyres = true,
		copper = true,
		toolbox = true,
		advtoolbox = true
	},
	boxville2 = {
		package = true
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLOCKED
-----------------------------------------------------------------------------------------------------------------------------------------
local Blocked = {
	dollar = true,
	dirtydollar = true,
	wetdollar = true,
	promissory1000 = true,
	promissory2000 = true,
	promissory3000 = true,
	promissory4000 = true,
	promissory5000 = true
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mount()
	local Primary = {}
	local Secondary = {}
	local source = source
	local Passport = vRP.Passport(source)

	if not (Passport and Open[Passport]) then
		return Primary,Secondary
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

	local Inventory = vRP.Inventory(Passport)
	for Slot,v in pairs(Inventory) do
		local Processed = ProcessItem(Slot,v,"Inventory")
		if Processed then
			Primary[Slot] = Processed
		end
	end

	if Open[Passport] and Open[Passport].Data then
		local ChestData = Open[Passport].Data
		local Chest = vRP.GetSrvData(ChestData,true)
		for Slot,v in pairs(Chest) do
			local Processed = ProcessItem(Slot,v,"Chest",ChestData,true)
			if Processed then
				Secondary[Slot] = Processed
			end
		end
	end

	return Primary,Secondary,vRP.GetWeight(Passport),Open[Passport] and Open[Passport].Weight or 0,vRP.InventorySlots(Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Slot,Target,Amount)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Open[Passport] then
		return false
	end

	local Amount = parseInt(Amount,true)
	if vRP.UpdateChest(Passport,Open[Passport].Data,Slot,Target,Amount,true) then
		TriggerClientEvent("inventory:Update",source)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Store(Item,Slot,Amount,Target)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Open[Passport] then
		return false
	end

	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local Split = SplitOne(Item)
	local Data = Open[Passport].Data
	local Model = Open[Passport].Model
	local Weight  = Open[Passport].Weight

	if (Store[Model] and not Store[Model][Split]) or (Blocked[Split] and Store[Model] and not Store[Model][Split]) or (Blocked[Split] and not Store[Model]) or exports.vrp:ItemLocked(Split) then
		TriggerClientEvent("Notify",source,"Aviso","Armazenamento proibido.","amarelo",5000)
		TriggerClientEvent("inventory:Update",source)

		return false
	end

	if Split == "diagram" then
		local NewWeight = Weight + (10 * Amount)
		local MaxWeight = exports.vrp:VehicleWeight(Model) * 5

		if NewWeight <= MaxWeight and vRP.TakeItem(Passport,Item,Amount) then
			vRP.Update("vehicles/UpdateWeight",{ Passport = Open[Passport].Passport, Vehicle  = Model, Multiplier = Amount })
			TriggerClientEvent("inventory:Notify",source,"Sucesso","Armazenamento melhorado.","verde")
			Open[Passport].Weight = NewWeight
		else
			TriggerClientEvent("inventory:Notify",source,"Atenção","Limite atingido.","vermelho")
		end

		TriggerClientEvent("inventory:Update",source)
	else
		if Data and Weight and vRP.StoreChest(Passport,Data,Amount,Weight,Slot,Target,true) then
			TriggerClientEvent("inventory:Update",source)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Take(Slot,Amount,Target)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Open[Passport] then
		return false
	end

	local Amount = parseInt(Amount,true)
	if vRP.TakeChest(Passport,Open[Passport].Data,Amount,Slot,Target,true) then
		TriggerClientEvent("inventory:Update",source)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Close()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Open[Passport] then
		Open[Passport] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRUNKCHEST:OPENTRUNK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("trunkchest:openTrunk")
AddEventHandler("trunkchest:openTrunk",function(Entity)
	local source = source
	local Plate,Model = Entity[1],Entity[2]
	if not Plate or not Model or not exports.vrp:VehicleExist(Model) then
		return false
	end

	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Spawn = exports.garages:Spawn(Plate)
	if not Spawn or Spawn[2] ~= Model then
		return false
	end

	local OtherPassport = vRP.PassportPlate(Plate)
	if not OtherPassport or Spawn[1] ~= OtherPassport then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource then
		return false
	end

	local Consult = vRP.SelectVehicle(OtherPassport,Model)
	local Weight = Consult and Consult.Weight or exports.vrp:VehicleWeight(Model)
	if Passport ~= OtherPassport and not vRP.Request(OtherSource,"Porta-Malas","Permitir que o mesmo seja aberto por <b>"..vRP.FullName(Passport).."</b>?") then
		return false
	end

	Open[Passport] = { Model = Model, Weight = Weight, Passport = OtherPassport, Data = ("Trunkchest:%s:%s"):format(OtherPassport,Model) }
	TriggerClientEvent("trunkchest:Open",source,Entity[3])
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	Open[Passport] = nil
end)