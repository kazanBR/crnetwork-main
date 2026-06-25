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
Tunnel.bindInterface("inspect",Creative)
vCLIENT = Tunnel.getInterface("inspect")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Admin = {}
local Players = {}
local Sourcers = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- INV
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("inv",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	if Admin[Passport] then
		return false
	end

	local Number = Message[1]
	if not Number then
		return false
	end

	local OtherPassport = parseInt(Number,true)
	if not OtherPassport or OtherPassport == Passport then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource or not vRP.DoesEntityExist(OtherSource) then
		return false
	end

	if Players[OtherPassport] then
		return false
	end

	Admin[Passport] = true
	Sourcers[Passport] = OtherSource
	Players[Passport] = OtherPassport

	TriggerClientEvent("inspect:Open",source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSPECT:PLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("inspect:Player")
AddEventHandler("inspect:Player",function(OtherSource)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.DoesEntityExist(OtherSource) then
		return false
	end

	local OtherPassport = vRP.Passport(OtherSource)
	if not OtherPassport or Players[OtherPassport] then
		return false
	end

	local IsPolice = vRP.HasGroup(Passport,"Policia")
	local IsOtherPolice = vRP.HasService(OtherPassport,"Policia")
	local OtherHealth = vRP.GetHealth(OtherSource)

	local CanInspect = false
	if IsPolice then
		CanInspect = true
	elseif OtherHealth <= 100 then
		CanInspect = true
	else
		CanInspect = vRP.Request(OtherSource,"Revistar","Você aceita ser revistado?")
	end

	if not CanInspect or IsOtherPolice then
		return false
	end

	local Distance = #(vRP.GetEntityCoords(source) - vRP.GetEntityCoords(OtherSource))
	if Distance > 2.0 then
		return false
	end

	Sourcers[Passport] = OtherSource
	Players[Passport] = OtherPassport

	TriggerClientEvent("inventory:Close",OtherSource)
	TriggerClientEvent("inspect:Open",source)
	FreezePlayer(OtherSource,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mount()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
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

		local Secondary = {}
		local Inv = vRP.Inventory(Players[Passport])
		for Slot,v in pairs(Inv) do
			if v.amount <= 0 or not exports.vrp:ItemExist(v.item) then
				vRP.CleanSlot(Players[Passport],Slot)
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

				Secondary[Slot] = v
			end
		end

		return Primary,Secondary,vRP.GetWeight(Passport),vRP.GetWeight(Players[Passport]),vRP.InventorySlots(Passport),vRP.InventorySlots(Players[Passport])
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Reset()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Target = Sourcers[Passport]
	if Target then
		if vRP.DoesEntityExist(Target) and not Admin[Passport] then
			FreezePlayer(Target,false)
		end

		Sourcers[Passport] = nil
	end

	Players[Passport] = nil
	Admin[Passport] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Store(Item,Slot,Amount,Target)
	local source = source
	local Slot = tostring(Slot)
	local Target = tostring(Target)
	local Passport = vRP.Passport(source)
	if not Passport or not Sourcers[Passport] or not vRP.DoesEntityExist(Sourcers[Passport]) or exports.vrp:ItemLocked(Item) then
		return false
	end

	local SelectPlayer = Players[Passport]
	if not SelectPlayer or exports.vrp:BlockDelete(Item) or vRP.MaxItens(SelectPlayer,Item,Amount) then
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	if not vRP.CheckWeight(SelectPlayer,Item,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Mochila sobrecarregada.","amarelo")
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	if not vRP.GiveItem(SelectPlayer,Item,Amount,true,Target) then
		TriggerClientEvent("inventory:Update",source)
		return false
	else
		if not vRP.TakeItem(Passport,Item,Amount,true,Slot) then
			vRP.RemoveItem(SelectPlayer,Item,Amount)
			TriggerClientEvent("inventory:Update",source)
			return false
		end
	end

	if exports.vrp:ItemType(Item) == "Armamento" then
		TriggerClientEvent("inventory:Update",source)
	end

	exports.discord:Embed("Inspect","**[PASSAPORTE]:** "..Passport.."\n**[REVISTADO]:** "..SelectPlayer.."\n**[MODO]:** Enviou\n**[ITEM]:** "..Item.."\n**[QUANTIDADE]:** "..Amount.."x")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Take(Item,Slot,Target,Amount)
	local source = source
	local Slot = tostring(Slot)
	local Target = tostring(Target)
	local Passport = vRP.Passport(source)
	if not Passport or not Sourcers[Passport] or not vRP.DoesEntityExist(Sourcers[Passport]) or exports.vrp:ItemLocked(Item) then
		return false
	end

	local SelectPlayer = Players[Passport]
	if not SelectPlayer or exports.vrp:BlockDelete(Item) or vRP.MaxItens(Passport,Item,Amount) then
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	if not vRP.CheckWeight(Passport,Item,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Mochila sobrecarregada.","amarelo")
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	if not vRP.GiveItem(Passport,Item,Amount,true,Target) then
		TriggerClientEvent("inventory:Update",source)
		return false
	else
		if not vRP.TakeItem(SelectPlayer,Item,Amount,true,Slot) then
			vRP.RemoveItem(Passport,Item,Amount)
			TriggerClientEvent("inventory:Update",source)
			return false
		end
	end

	if exports.vrp:ItemType(Item) == "Armamento" then
		TriggerClientEvent("inventory:Update",source)
	end

	exports.discord:Embed("Inspect","**[PASSAPORTE]:** "..Passport.."\n**[REVISTADO]:** "..SelectPlayer.."\n**[MODO]:** Retirou\n**[ITEM]:** "..Item.."\n**[QUANTIDADE]:** "..Amount.."x")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FREEZEPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
function FreezePlayer(source,Toggle)
	local Ped = GetPlayerPed(source)
	if DoesEntityExist(Ped) then
		FreezeEntityPosition(Ped,Toggle)
	end
end