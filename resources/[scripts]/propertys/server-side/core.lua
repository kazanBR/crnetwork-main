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
Tunnel.bindInterface("propertys",Creative)
vKEYBOARD = Tunnel.getInterface("keyboard")
vSKINSHOP = Tunnel.getInterface("skinshop")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Lock = {}
local Saved = {}
local Inside = {}
local Active = {}
local Within = {}
local Robbery = {}
local Markers = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPROPERTYNUMBER
-----------------------------------------------------------------------------------------------------------------------------------------
function GetPropertyNumber(Name,Passport)
	local Routing = tonumber(Name:match("%d+")) or 0
	return Name ~= "Hotel" and (100000 + Routing) or (200000 + Routing + Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:ROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Robbery")
AddEventHandler("propertys:Robbery",function(Name)
	if not Name then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] or not Propertys[Name] then
		return false
	end

	Active[Passport] = true
	TriggerClientEvent("dynamic:Close",source)

	local CanEnter = false
	local Service = vRP.HasService(Passport,"Policia")
	local Lockpick = vRP.ConsultItem(Passport,"lockpick")
	local LockpickPlus = vRP.ConsultItem(Passport,"lockpickplus")
	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })

	if Service then
		CanEnter = true
	elseif (Lockpick or LockpickPlus) and vRP.Task(source,5,5000) then
		CanEnter = true
	end

	if not CanEnter then
		Active[Passport] = nil
		return false
	end

	Saved[Name] = Saved[Name] or (Consult and Consult.Interior or exports.propertys:Informations())
	Robbery[Name] = Robbery[Name] or {}

	if not Service then
		if Lockpick then
			vRP.RemoveItem(Passport,Lockpick.Item,1,true)
		end

		if Consult then
			local OtherSource = vRP.Source(Consult.Passport)
			if OtherSource then
				TriggerClientEvent("Notify",OtherSource,"Alerta de Segurança","Sua propriedade está sendo invadida.","policia",10000)
			end
		end
	end

	if Name ~= "Hotel" then
		Within[Name] = Within[Name] or {}
		Within[Name][Passport] = source
	end

	TriggerClientEvent("propertys:Enter",source,Name,Saved[Name])
	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:ROBBERYITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:RobberyItem")
AddEventHandler("propertys:RobberyItem",function(Complete)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Data = splitString(Complete)
	local Name,Selected,ModelHash = Data[1],Data[2],Data[3]
	if not Name or not Selected or not ModelHash or not Propertys[Name] then
		return false
	end

	local RobberyData = Robbery[Name]
	if not RobberyData then
		return false
	end

	Active[Passport] = true

	local CurrentTimer = os.time()
	local Container = "Propertys:"..Name..":"..Selected
	local Lockpick = vRP.ConsultItem(Passport,"lockpick")
	local LockpickPlus = vRP.ConsultItem(Passport,"lockpickplus")
	if not Lockpick and not LockpickPlus then
		Active[Passport] = nil
		return false
	end

	RobberyData[Selected] = RobberyData[Selected] or CurrentTimer
	if RobberyData[Selected] > CurrentTimer then
		TriggerClientEvent("chest:Open",source,Container,"Custom",false,true)
		Active[Passport] = nil
		return false
	end

	local IsLocker = Chests[ModelHash]
	local Coords = vRP.GetEntityCoords(source)
	local Success = IsLocker and vRP.LetterGame(source) or vRP.Task(source,5,5000)
	if not Success then
		if Lockpick and math.random(100) >= 95 then
			vRP.RemoveItem(Passport,Lockpick.Item,1,true)
		end

		exports.vrp:CallPolice({
			Source = source,
			Passport = Passport,
			Coords = Propertys[Name],
			Permission = "Policia",
			Name = "Roubo a Propriedade",
			Wanted = 30,
			Code = 31,
			Color = 44
		})

		TriggerClientEvent("sounds:Area",-1,"alarm",1.0,Coords,125,GetPropertyNumber(Name))
		Active[Passport] = nil

		return false
	end

	local Bonus = false
	local Amount = IsLocker and 1 or math.random(3)
	local Itens = RobberyItens[ModelHash] or OtherItens
	if GlobalState.Blackout then
		Bonus = {
			Item = "dirtydollar",
			Amount = math.random(100,250)
		}
	end

	if vRP.MountContainer(Passport,Container,Itens,Amount,false,IsLocker and 675 or 775,Bonus) then
		TriggerClientEvent("chest:Open",source,Container,"Custom",false,true)
	end

	RobberyData[Selected] = CurrentTimer + 1800
	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- POLICE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Police(Outside,Inside,Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	TriggerClientEvent("sounds:Area",-1,"alarm",1.0,Inside,125,GetPropertyNumber(Name))

	exports.vrp:CallPolice({
		Source = source,
		Passport = Passport,
		Coords = Outside,
		Permission = "Policia",
		Name = "Roubo a Propriedade",
		Wanted = 300,
		Code = 31,
		Color = 44
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Propertys(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name then
		return false
	end

	if Name == "Hotel" then
		return vRP.Scalar("propertys/Count",{ Passport = Passport }) <= 0 and "Hotel" or false
	end

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult then
		return "Nothing"
	end

	local Owner = Consult.Passport == Passport
	local CheckKey = vRP.InventoryFull(Passport,"propertys-"..Consult.Serial)
	if Lock[Name] and not Owner and not CheckKey then
		return false
	end

	local Interior = Saved[Name]
	if not Interior then
		Interior = Consult.Interior
		Saved[Name] = Interior
	end

	local InteriorData = Informations[Interior]
	if not InteriorData or not InteriorData.Price then
		return false
	end

	local CurrentTimer = os.time()
	local Price = math.floor(InteriorData.Price * 0.25)
	local TaxTime = Consult.Tax - CurrentTimer
	local Tax = CompleteTimers(TaxTime)

	if TaxTime <= 0 then
		Tax = "Efetue o pagamento da <b>Hipoteca</b>."
		if not vRP.Request(source,"Propriedades","Deseja pagar a hipoteca de <b>"..Currency..Dotted(Price).."</b>?") then
			return false
		end

		if not vRP.PaymentFull(Passport,Price) then
			TriggerClientEvent("Notify",source,"Propriedades","Saldo insuficiente.","amarelo",5000)
			return false
		end

		vRP.Update("propertys/Tax",{ Name = Name })
		Tax = CompleteTimers(2592000)
	end

	return {
		Interior = Interior,
		Lock = Lock[Name],
		Key = CheckKey,
		Owner = Owner,
		Tax = Tax
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOGGLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Toggle(Name,Mode)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name then
		return false
	end

	TriggerEvent("animals:Delete",Passport,source)

	if Mode == "Exit" then
		Inside[Passport] = nil

		if Name ~= "Hotel" and Within[Name] then
			Within[Name][Passport] = nil

			if CountTable(Within[Name]) <= 0 then
				Within[Name] = nil
			end
		end

		exports.vrp:Bucket(source,"Exit")
		TriggerEvent("vRP:ReloadWeapons",source)

		return false
	else
		exports.vrp:Bucket(source,"Enter",GetPropertyNumber(Name,Passport))
		TriggerEvent("DebugWeapons",Passport)
		Inside[Passport] = Name

		if Name ~= "Hotel" then
			Within[Name] = Within[Name] or {}
			Within[Name][Passport] = source
		end

		return vRP.GetSrvData("Probjects:"..Name,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:BUY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Buy")
AddEventHandler("propertys:Buy",function(Name)
	local source = source
	local Split = splitString(Name)
	local Passport = vRP.Passport(source)
	if not Passport or exports.bank:CheckTaxes(Passport) or exports.bank:CheckFines(Passport) then
		return false
	end

	local Name,Interior,Mode = Split[1],Split[2],Split[3]
	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if Consult then
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	if not vRP.Request(source,"Propriedades","Deseja comprar a propriedade?") then
		return false
	end

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if Consult then
		return false
	end

	local Payment = false
	if Mode == "Dollar" then
		Payment = vRP.PaymentFull(Passport,Informations[Interior].Price)
	elseif Mode == "Gemstone" then
		Payment = vRP.PaymentGems(Passport,Informations[Interior].Gemstone)
	end

	if not Payment then
		TriggerClientEvent("Notify",source,"Propriedades",Mode == "Dollar" and "Dinheiro insuficiente." or "Diamante insuficiente.","amarelo",10000)
		return false
	end

	Lock[Name] = true
	Saved[Name] = Interior
	local Serial = PropertysSerials()
	vRP.GiveItem(Passport,"propertys-"..Serial,3,true)
	TriggerClientEvent("Notify",source,"Propriedades","Compra concluída.","verde",10000)

	if Mode == "Dollar" then
		exports.bank:AddTaxes(Passport,"Propriedades",Informations[Interior].Price,"Compra de propriedade.")
	end

	vRP.Query("propertys/Buy",{
		Name = Name,
		Interior = Interior,
		Passport = Passport,
		Serial = Serial
	})

	Markers[Name] = true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:LOCK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Lock")
AddEventHandler("propertys:Lock",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name then
		return false
	end

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult then
		return false
	end

	if Consult.Passport ~= Passport and not vRP.InventoryFull(Passport,"propertys-"..Consult.Serial) then
		return false
	end

	Lock[Name] = not Lock[Name]
	TriggerClientEvent("Notify",source,"Aviso","Propriedade "..(Lock[Name] and "trancada" or "destrancada")..".","default",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:INTERIOR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Interior")
AddEventHandler("propertys:Interior",function(Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Data then
		return false
	end

	local Split = splitString(Data)
	local Name,Interior = Split[1],Split[2]
	if not Name or not Interior then
		return false
	end

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult or Consult.Passport ~= Passport or Consult.Interior == Interior then
		return false
	end

	local NewInterior = Informations[Interior]
	local OldInterior = Informations[Consult.Interior]
	if not NewInterior or not OldInterior then
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	local function ApplyInteriorChange()
		local Consult = exports.oxmysql:update_async("UPDATE propertys SET Interior = ? WHERE Name = ? AND Interior = ?",{ Interior,Name,Consult.Interior })
		if Consult and Consult > 0 then
			TriggerClientEvent("Notify",source,"Propriedades","Interior alterado com sucesso.","verde",10000)
			exports.oxmysql:query_async("DELETE FROM entitydata WHERE Name LIKE ?",{ "Vault:"..Name..":%" })
			vRP.RemSrvData("Probjects:"..Name)
			Saved[Name] = Interior
		end
	end

	local PriceDiff = (NewInterior.Gemstone or 0) - (OldInterior.Gemstone or 0)
	if PriceDiff <= 0 then
		ApplyInteriorChange()
		return false
	end

	if vRP.Request(source,"Propriedades","Deseja trocar para o <b>"..Interior.."</b> por <b>"..Dotted(PriceDiff).." diamantes</b>?<br>Todos os objetos do interior serão removidos.") then
		if vRP.PaymentGems(Passport,PriceDiff) then
			ApplyInteriorChange()
		else
			TriggerClientEvent("Notify",source,"Propriedades","Diamantes insuficientes.","amarelo",10000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:SELL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Sell")
AddEventHandler("propertys:Sell",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name or Active[Passport] or not Propertys[Name] then
		return false
	end

	Active[Passport] = true

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult or Consult.Passport ~= Passport then
		Active[Passport] = nil
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	local InteriorData = Informations[Consult.Interior]
	if not InteriorData or not InteriorData.Price then
		Active[Passport] = nil
		return false
	end

	local Price = math.floor(InteriorData.Price * 0.25)
	if vRP.Request(source,"Propriedades","Vender por <b>"..Currency..Dotted(Price).."</b>?") then
		if Markers[Name] then
			Markers[Name] = nil
		end

		vRP.GiveBank(Passport,Price)
		vRP.RemSrvData("Probjects:"..Name)
		vRP.Query("propertys/Sell",{ Name = Name })
		TriggerClientEvent("garages:Clean",-1,Name)
		TriggerClientEvent("Notify",source,"Propriedades","Venda concluída.","verde",10000)
		exports.oxmysql:query_async("DELETE FROM entitydata WHERE Name LIKE ?",{ "Vault:"..Name..":%" })
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Transfer")
AddEventHandler("propertys:Transfer",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not (Consult and Consult.Passport == Passport) then
		Active[Passport] = nil
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	local Keyboard = vKEYBOARD.Primary(source,"Passaporte")
	local OtherPassport = Keyboard and Keyboard[1]
	if OtherPassport and vRP.Identity(OtherPassport) and vRP.Request(source,"Propriedades","Deseja transferir para o passaporte <b>"..OtherPassport.."</b>?") then
		vRP.Update("propertys/Transfer",{ Name = Name, Passport = OtherPassport })
		TriggerClientEvent("Notify",source,"Propriedades","Transferência concluída.","verde",10000)
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:CREDENTIALS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Credentials")
AddEventHandler("propertys:Credentials",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult or Consult.Passport ~= Passport then
		Active[Passport] = nil
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	if not vRP.Request(source,"Propriedades","Ao prosseguir, todas as chaves atuais deixarão de funcionar. Deseja continuar?") then
		Active[Passport] = nil
		return false
	end

	local Serial = PropertysSerials()
	if not Serial then
		Active[Passport] = nil
		return false
	end

	Saved[Name] = nil
	Active[Passport] = nil
	vRP.GiveItem(Passport,"propertys-"..Serial,Consult.Item or 1,true)
	vRP.Update("propertys/Credentials",{ Name = Name, Serial = Serial })
	TriggerClientEvent("Notify",source,"Propriedades","Novas credenciais geradas com sucesso.","verde",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:ITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Item")
AddEventHandler("propertys:Item",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult or Consult.Passport ~= Passport or Consult.Item >= 5 then
		Active[Passport] = nil
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	local Price = 150000
	if not vRP.Request(source,"Propriedades","Comprar uma chave adicional por <b>"..Currency..Dotted(Price).."</b>?") then
		Active[Passport] = nil
		return false
	end

	if not vRP.PaymentFull(Passport,Price) then
		TriggerClientEvent("Notify",source,"Aviso","Dinheiro insuficiente.","amarelo",10000)
		Active[Passport] = nil
		return false
	end

	Active[Passport] = nil
	vRP.Update("propertys/Item",{ Name = Name })
	vRP.GiveItem(Passport,"propertys-"..Consult.Serial,1,true)
	TriggerClientEvent("Notify",source,"Propriedades","Chave adicional adquirida.","verde",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOTHES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Clothes(Property,Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Property or not Selected then
		return {}
	end

	local Clothes = {}
	local Consult = vRP.GetSrvData("Wardrobe:"..Property..":"..Selected,true) or {}
	for Name in pairs(Consult) do
		table.insert(Clothes,Name)
	end

	return Clothes
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:CLOTHES:APPLY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Clothes:Apply")
AddEventHandler("propertys:Clothes:Apply",function(Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Data then
		return false
	end

	local Split = splitString(Data)
	local Property,Selected,Name = Split[1],Split[2],Split[3]
	if not Property or not Selected or not Name then
		return false
	end

	local Consult = vRP.GetSrvData("Wardrobe:"..Property..":"..Selected,true)
	if Consult[Name] then
		TriggerClientEvent("skinshop:Apply",source,Consult[Name],true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:CLOTHES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Clothes:Delete")
AddEventHandler("propertys:Clothes:Delete",function(Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Data then
		return false
	end

	local Split = splitString(Data)
	local Property,Selected,Name = Split[1],Split[2],Split[3]
	if not Property or not Selected or not Name then
		return false
	end

	local Consult = vRP.GetSrvData("Wardrobe:"..Property..":"..Selected,true)
	if Consult[Name] then
		Consult[Name] = nil
		vRP.SetSrvData("Wardrobe:"..Property..":"..Selected,Consult,true)
		TriggerClientEvent("Notify",source,"Armário","Roupa removida.","verde",10000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:CLOTHES:SAVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("propertys:Clothes:Save")
AddEventHandler("propertys:Clothes:Save",function(Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Data then
		return false
	end

	local Split = splitString(Data)
	local Property,Selected,Hash = Split[1],Split[2],Split[3]
	if not Property or not Selected or not Hash then
		return false
	end

	local Consult = vRP.GetSrvData("Wardrobe:"..Property..":"..Selected,true)

	if CountTable(Consult) >= (Wardrobes[Hash] or 3) then
		TriggerClientEvent("Notify",source,"Armário","Limite de roupas atingido.","amarelo",10000)
		return false
	end

	local Keyboard = vKEYBOARD.Primary(source,"Nome")
	if not Keyboard or not Keyboard[1] then
		return false
	end

	local Name = sanitizeString(Keyboard[1],"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
	if #Name < 4 then
		TriggerClientEvent("Notify",source,"Armário","O nome precisa ter no mínimo 4 caracteres.","amarelo",10000)
		return false
	end

	if Consult[Name] then
		TriggerClientEvent("Notify",source,"Armário","Já existe uma roupa com esse nome.","amarelo",10000)
		return false
	end

	Consult[Name] = vSKINSHOP.Customization(source)
	vRP.SetSrvData("Wardrobe:"..Property..":"..Selected,Consult,true)
	TriggerClientEvent("Notify",source,"Armário","Roupa salva com sucesso.","verde",10000)

	TriggerClientEvent("dynamic:AddMenu",source,Name,"Informações da vestimenta.",Name)
	TriggerClientEvent("dynamic:AddButton",source,"Aplicar","Vestir-se com esta roupa.","propertys:Clothes:Apply",Property.."-"..Selected.."-"..Name,Name,true)
	TriggerClientEvent("dynamic:AddButton",source,"Remover","Deletar esta roupa.","propertys:Clothes:Delete",Property.."-"..Selected.."-"..Name,Name,true,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYSSERIALS
-----------------------------------------------------------------------------------------------------------------------------------------
function PropertysSerials()
	local Serial
	local Consult

	repeat
		Serial = GenerateString("LDLDLDLDLD")
		Consult = vRP.SingleQuery("propertys/Serial",{ Serial = Serial })
	until Serial and not Consult

	return Serial
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permission(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if Name == "Hotel" then
		return true
	end

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult then
		return false
	end

	if Consult.Passport == Passport then
		return true
	end

	if vRP.InventoryFull(Passport,"propertys-"..Consult.Serial) then
		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mount(Name,Mode)
	local Weight = 25
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Name or not Mode then
		return false
	end

	if Name == "Hotel" then
		Name = Mode..":Hotel:"..Passport
	else
		local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
		if not Consult then
			return false
		end

		Name = "Vault:"..Name..":"..SplitOne(Mode)
		Weight = Chests[SplitTwo(Mode)] or 25
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

	local Primary = {}
	local Secondary = {}
	local Chest = vRP.GetSrvData(Name,true)
	local Inventory = vRP.Inventory(Passport)

	for Slot,v in pairs(Inventory) do
		local Processed = ProcessItem(Slot,v,"Inventory")
		if Processed then
			Primary[Slot] = Processed
		end
	end

	for Slot,v in pairs(Chest) do
		local Processed = ProcessItem(Slot,v,"Chest",Name,true)
		if Processed then
			Secondary[Slot] = Processed
		end
	end

	return Primary,Secondary,vRP.GetWeight(Passport),Weight,vRP.InventorySlots(Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Store(Item,Slot,Amount,Target,Name,Mode)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if exports.vrp:ItemLocked(Item) then
		TriggerClientEvent("inventory:Update",source)
		return false
	end

	local Chest
	local MaxWeight = 25
	local Amount = parseInt(Amount,true)
	if Name == "Hotel" then
		Chest = Mode..":Hotel:"..Passport
	else
		Chest = "Vault:"..Name..":"..SplitOne(Mode)
		MaxWeight = Chests[SplitTwo(Mode)] or 25
	end

	if vRP.StoreChest(Passport,Chest,Amount,MaxWeight,Slot,Target,true) then
		TriggerClientEvent("inventory:Update",source)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Take(Slot,Amount,Target,Name,Mode)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Chest
	local Amount = parseInt(Amount,true)
	if Name == "Hotel" then
		Chest = Mode..":Hotel:"..Passport
	else
		Chest = "Vault:"..Name..":"..SplitOne(Mode)
	end

	if vRP.TakeChest(Passport,Chest,Amount,Slot,Target,true) then
		TriggerClientEvent("inventory:Update",source)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Slot,Target,Amount,Name,Mode)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Chest
	local Amount = parseInt(Amount,true)
	if Name == "Hotel" then
		Chest = Mode..":Hotel:"..Passport
	else
		Chest = "Vault:"..Name..":"..SplitOne(Mode)
	end

	if vRP.UpdateChest(Passport,Chest,Slot,Target,Amount,true) then
		TriggerClientEvent("inventory:Update",source)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if not Passport then
		return false
	end

	local Name = Inside[Passport]
	if Name and Name ~= "Hotel" and Propertys[Name] and Within[Name] then
		Within[Name][Passport] = nil

		if CountTable(Within[Name]) <= 0 then
			Within[Name] = nil
		end
	end

	Inside[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Additional = 1296000
	local CurrentTimer = os.time()
	local Consult = vRP.Query("propertys/All")
	if not Consult or #Consult <= 0 then
		return false
	end

	for Number = 1,#Consult do
		local Data = Consult[Number]
		local Name = Data.Name

		if (Data.Tax + Additional) <= CurrentTimer then
			vRP.RemSrvData("Probjects:"..Name)
			vRP.Query("propertys/Sell",{ Name = Name })
			exports.oxmysql:query_async("DELETE FROM entitydata WHERE Name LIKE ?",{ "Vault:"..Name..":%" })
		else
			if Propertys[Name] then
				Markers[Name] = true
				Lock[Name] = true
			end
		end

		Wait(10)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("CharacterChosen",function(Passport,source)
	if not Passport or not source then
		return false
	end

	local Increments = {}
	local Count = vRP.Scalar("propertys/Count",{ Passport = Passport })
	if Count <= 0 then
		if Propertys.Hotel then
			Increments[1] = Propertys.Hotel
		end
	else
		local Consult = vRP.Query("propertys/AllUser",{ Passport = Passport })
		if Consult and #Consult > 0 then
			for Number = 1,#Consult do
				local Data = Consult[Number]
				local Property = Propertys[Data.Name]
				if Property then
					Increments[#Increments + 1] = Property
				end
			end
		end
	end

	if #Increments > 0 then
		TriggerClientEvent("spawn:Increment",source,Increments)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Markers()
	return Markers
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("propertys:Adicionar",function(Name,Selected,Table)
	local Data = Within[Name]
	if not Data then
		return false
	end

	for Passport,Source in pairs(Data) do
		if vRP.Passport(Source) then
			TriggerClientEvent("propertys:Adicionar",Source,Selected,Table)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("propertys:Remover",function(Name,Selected)
	local Data = Within[Name]
	if not Data then
		return false
	end

	for Passport,Source in pairs(Data) do
		if vRP.Passport(Source) then
			TriggerClientEvent("propertys:Remover",Source,Selected)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSIDE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Inside",function(Passport)
	return Inside[Passport]
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- COORDS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Coords",function(Name)
	return Name and Propertys[Name] or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SURVIVAL
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Survival",function(Passport,source)
	local Name = Inside[Passport]
	if Name and Name ~= "Hotel" and Propertys[Name] and Within[Name] then
		Within[Name][Passport] = nil
		Inside[Passport] = nil

		if CountTable(Within[Name]) <= 0 then
			Within[Name] = nil
		end

		exports.vrp:Bucket(source,"Exit")
		TriggerEvent("vRP:ReloadWeapons",source)
	end
end)