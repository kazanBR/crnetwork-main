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
Tunnel.bindInterface("pause",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Salarys = {}
local Shopping = {}
local PlayerBox = {}
local BattleStart = 0
local Marketplace = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Disconnect()
	local source = source
	vRP.Kick(source,"Desconectado")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOME
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Home()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Identity = vRP.Identity(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not Identity or not Datatable then
		return false
	end

	local Experience = {}
	for Index,Name in pairs(Works) do
		Experience[#Experience + 1] = { Name,Datatable[Index] or 0 }
	end

	local Shop = {}
	local Count = math.min(#Shopping,15)
	for Number,Item in ipairs(Shopping) do
		if Number > Count then
			break
		end

		Shop[Number] = {
			Index = Item.Index,
			Amount = Item.Amount,
			Name = Item.Name
		}
	end

	local Consult = vRP.DatatableInformation(Passport,"MedicPlan") or 0
	local MedicRemaining = math.floor((Consult - os.time()) / 86400)
	local Playing = vRP.Playing(Passport,"Online")
	local MedicPlan = math.max(MedicRemaining,0)

	return {
		Player = {
			Medic = MedicPlan,
			Passport = Passport,
			Bank = Identity.Bank,
			Blood = Sanguine(Identity.Blood),
			Playing = CompleteTimers(Playing),
			Gemstone = vRP.UserGemstone(Identity.License),
			Name = ("%s %s"):format(Identity.Name,Identity.Lastname)
		},
		Experience = Experience,
		Shopping = Shop
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADGENERATE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local ConsultM = vRP.SingleQuery("entitydata/GetData",{ Name = "Marketplace" })
	Marketplace = ConsultM and json.decode(ConsultM.Information) or {}

	local ConsultB = vRP.SingleQuery("entitydata/GetData",{ Name = "Battlepass" })
	BattleStart = ConsultB and json.decode(ConsultB.Information) or 0
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Config()
	return {
		Levels = TableLevel(),
		HomeBoxes = HomeBoxes,
		Premium = Premium,
		Propertys = Propertys,
		Store = {
			List = ShopItens,
			All = ShopAllDisplay
		},
		Furnitures = {
			List = FurnituresItens,
			All = FurnituresAllDisplay
		},
		Battlepass = {
			Necessary = BattlepassPoints,
			Price = BattlepassPrice,
			Finish = BattleStart + 2592000,
			Free = Battlepass.Free,
			Premium = Battlepass.Premium
		},
		Boxes = Boxes,
		MarketplaceTax = MarketplaceTax,
		Daily = #Daily
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOREBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.StoreBuy(Item,Amount,OtherPassport)
	local source = source
	local Data = ShopItens[Item]
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if not (Passport and Data and not Active[Passport]) then
		return false
	end

	Active[Passport] = true

	if Amount > 1 and exports.vrp:ItemUnique(Item) then
		Amount = 1
	end

	local Price = Data.Price * (Data.Discount < 1.0 and Data.Discount or 1.0)
	local Valuation = Price * Amount

	local function FinishBuy(TargetPassport)
		if Passport ~= TargetPassport then
			local Name = vRP.FullName(Passport)
			local OtherName = vRP.FullName(TargetPassport)

			TriggerClientEvent("chat:ClientMessage",-1,"","Com grande estilo, <b><yellow>"..Name.."</yellow></b> presenteou <b><yellow>"..OtherName.."</yellow></b> com <b><green>"..Dotted(Amount).."x "..exports.vrp:ItemName(Item).."</green></b>, marcando esse momento como algo especial.","Importante",true,true)
		end

		exports.discord:Embed("Shopping","**[TIPO]:** Compra\n**[PASSAPORTE]:** "..Passport.."\n"..(TargetPassport and ("**[PARA]:** "..TargetPassport.."\n") or "").."**[ITEM]:** "..Dotted(Amount).."x "..Item.."\n**[DIAMANTES]:** "..Dotted(Valuation))
		table.insert(Shopping,1,{ Amount = Amount, Index = exports.vrp:ItemIndex(Item), Name = vRP.LowerName(TargetPassport) })
		TriggerClientEvent("pause:Notify",source,"Sucesso","Compra concluída.","verde")
		Active[Passport] = nil

		return Amount
	end

	if OtherPassport and Passport ~= OtherPassport and vRP.Identity(OtherPassport) then
		local OtherSource = vRP.Source(OtherPassport)

		if OtherSource then
			if not vRP.MaxItens(OtherPassport,Item,Amount) and vRP.PaymentGems(Passport,Valuation) then
				vRP.GenerateItem(OtherPassport,Item,Amount,false)

				return FinishBuy(OtherPassport)
			end
		else
			if vRP.PaymentGems(Passport,Valuation) then
				local Selected
				local Consult = vRP.GetSrvData("Offline:"..OtherPassport,true)

				repeat
					Selected = GenerateString("DDLLDDLL")
				until Selected and not Consult[Selected]

				Consult[Selected] = { Item = Item, Amount = Amount }
				vRP.SetSrvData("Offline:"..OtherPassport,Consult,true)

				return FinishBuy(OtherPassport)
			end
		end

		Active[Passport] = nil

		return false
	end

	if not vRP.MaxItens(Passport,Item,Amount) and vRP.PaymentGems(Passport,Valuation) then
		vRP.GenerateItem(Passport,Item,Amount,false)

		return FinishBuy(Passport)
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FURNITURESBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FurnituresBuy(Item,Amount,OtherPassport)
	local source = source
	local Data = FurnituresItens[Item]
	local Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if not (Passport and Data and not Active[Passport]) then
		return false
	end

	Active[Passport] = true

	if Amount > 1 and exports.vrp:ItemUnique(Item) then
		Amount = 1
	end

	local Price = Data.Price * (Data.Discount < 1.0 and Data.Discount or 1.0)
	local Valuation = Price * Amount

	local function FinishBuy(TargetPassport)
		if Passport ~= TargetPassport then
			local Name = vRP.FullName(Passport)
			local OtherName = vRP.FullName(TargetPassport)

			TriggerClientEvent("chat:ClientMessage",-1,"","Com grande estilo, <b><yellow>"..Name.."</yellow></b> presenteou <b><yellow>"..OtherName.."</yellow></b> com <b><green>"..Dotted(Amount).."x "..exports.vrp:ItemName(Item).."</green></b>, marcando esse momento como algo especial.","Importante",true,true)
		end

		exports.discord:Embed("Shopping","**[TIPO]:** Compra\n**[PASSAPORTE]:** "..Passport.."\n"..(TargetPassport and ("**[PARA]:** "..TargetPassport.."\n") or "").."**[ITEM]:** "..Dotted(Amount).."x "..Item.."\n**[DIAMANTES]:** "..Dotted(Valuation))
		table.insert(Shopping,1,{ Amount = Amount, Index = exports.vrp:ItemIndex(Item), Name = vRP.LowerName(TargetPassport) })
		TriggerClientEvent("pause:Notify",source,"Sucesso","Compra concluída.","verde")
		Active[Passport] = nil

		return Amount
	end

	if OtherPassport and Passport ~= OtherPassport and vRP.Identity(OtherPassport) then
		local OtherSource = vRP.Source(OtherPassport)

		if OtherSource then
			if not vRP.MaxItens(OtherPassport,Item,Amount) and vRP.PaymentGems(Passport,Valuation) then
				vRP.GenerateItem(OtherPassport,Item,Amount,false)

				return FinishBuy(OtherPassport)
			end
		else
			if vRP.PaymentGems(Passport,Valuation) then
				local Selected
				local Consult = vRP.GetSrvData("Offline:"..OtherPassport,true)

				repeat
					Selected = GenerateString("DDLLDDLL")
				until Selected and not Consult[Selected]

				Consult[Selected] = { Item = Item, Amount = Amount }
				vRP.SetSrvData("Offline:"..OtherPassport,Consult,true)

				return FinishBuy(OtherPassport)
			end
		end

		Active[Passport] = nil

		return false
	end

	if not vRP.MaxItens(Passport,Item,Amount) and vRP.PaymentGems(Passport,Valuation) then
		vRP.GenerateItem(Passport,Item,Amount,false)

		return FinishBuy(Passport)
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SALARYS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Salarys()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local CurrentTimer = os.time()
	local NextPayment = Salarys[Passport]
	if not NextPayment or NextPayment < CurrentTimer then
		local Valuation = vRP.UserSalarys(Passport)
		if Valuation and Valuation > 0 then
			Salarys[Passport] = CurrentTimer + SalaryCooldown
			vRP.GiveBank(Passport,Valuation)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Propertys()
	local source = source
	local Information = {}
	local Passport = vRP.Passport(source)
	if Passport then
		for Index,v in pairs(Propertys) do
			Information[Index] = exports.crons:Check(Passport,"WipePermission",{ Permission = v.Permission }) or (vRP.AmountGroups(v.Permission) > 0 and true) or false
		end
	end

	return Information
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PropertyBuy(Index)
	local source = source
	local Property = Propertys[Index]
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] or not Property or not Property.Permission then
		return false
	end

	if Property.Necessary and not vRP.Permission(Passport,Property.Necessary) then
		return false
	end

	local Level = 1
	local Price = Property.Price or 0
	local Permission = Property.Permission
	local Discount = Property.Discount or 1.0

	if not Permission then
		TriggerClientEvent("pause:Notify",source,"Atenção","Permissão não encontrada.","amarelo")
		return false
	end

	local Amount = vRP.AmountGroups(Propertys[Index].Permission)
	local Level = vRP.HasPermission(Passport,Propertys[Index].Permission)
	if Amount > 0 and Level and Level > 1 then
		TriggerClientEvent("pause:Notify",source,"Atenção","Propriedade indisponível.","amarelo")
		return false
	end

	Active[Passport] = true

	if Discount < 1.0 then
		Price = parseInt(Price * Discount)
	end

	if vRP.PaymentGems(Passport,Price) then
		exports.discord:Embed("Propertys","**[PASSAPORTE]:** "..Passport.."\n**[PERMISSÃO]:** "..Permission.."\n**[COMPROU]:** "..(Property.Name or "Desconhecido").."\n**[VALOR]:** "..Price.."\n**[DURAÇÃO]:** "..CompleteTimers(Property.Duration))
		TriggerClientEvent("pause:Notify",source,"Sucesso","Compra concluída.","verde")

		if not vRP.HasPermission(Passport,Permission) then
			vRP.SetPermission(Passport,Permission,Level)
		end

		Active[Passport] = nil

		return exports.crons:Insert(Passport,"WipePermission",Property.Duration,{ Permission = Permission, Level = Level })
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREMIUM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Premium()
	local source = source
	local Information = {}
	local Passport = vRP.Passport(source)
	if Passport then
		for Index,v in pairs(Premium) do
			Information[Index] = exports.crons:Check(Passport,"RemovePermission",{ Permission = v.Permission })
		end
	end

	return Information
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREMIUMBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PremiumBuy(Index,Selectable)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Data = Premium[Index]
	if not Data or not Data.Permission or Active[Passport] then
		return false
	end

	local Duration = Data.Duration or 0
	if Duration <= 0 then
		return false
	end

	Active[Passport] = true

	if Data.Group and not vRP.HasGroup(Passport,Data.Group) then
		TriggerClientEvent("pause:Notify",source,"Atenção","Permissão não encontrada.","amarelo")
		Active[Passport] = nil
		return false
	end

	if Selectable and #Selectable > 0 then
		for Number = 1,#Selectable do
			local Model = Selectable[Number]
			local Consult = vRP.SingleQuery("vehicles/selectVehicles",{ Passport = Passport, Vehicle = Model })
			if Consult and not Consult.Block then
				TriggerClientEvent("pause:Notify",source,"Aviso","Já possui um <b>"..exports.vrp:VehicleName(Model).."</b>.","amarelo")
				Active[Passport] = nil
				return false
			end
		end
	end

	local Price = Data.Price or 0
	if Data.Discount and Data.Discount < 1.0 then
		Price = math.floor(Price * Data.Discount)
	end

	if Price > 0 and not vRP.PaymentGems(Passport,Price) then
		TriggerClientEvent("pause:Notify",source,"Atenção","Diamante insuficiente.","amarelo")
		Active[Passport] = nil
		return false
	end

	if Selectable and #Selectable > 0 then
		for Number = 1,#Selectable do
			local Model = Selectable[Number]
			if not vRP.SelectVehicle(Passport,Model) then
				exports.oxmysql:insert_async("INSERT INTO vehicles (Passport,Vehicle,Plate,Weight,Tax,Work,Block) VALUES (@Passport,@Vehicle,@Plate,@Weight,@Tax,@Work,@Block)",{ Passport = Passport, Vehicle = Model, Plate = vRP.GeneratePlate(), Weight = exports.vrp:VehicleWeight(Model), Tax = os.time() + Duration, Block = 1, Work = (exports.vrp:VehicleMode(Model) == "Work" and 1 or 0) })
			end

			exports.crons:Insert(Passport,"RemoveVehicle",Duration,{ Model = Model })
		end
	end

	if not vRP.HasPermission(Passport,Data.Permission,1) then
		vRP.SetPermission(Passport,Data.Permission,1)
	end

	exports.discord:Embed("Premium","**[PASSAPORTE]:** "..Passport.."\n**[COMPROU]:** "..Data.Name.."\n**[VALOR]:** "..Price.."\n**[DURAÇÃO]:** "..CompleteTimers(Duration))
	exports.crons:Insert(Passport,"RemovePermission",Duration,{ Permission = Data.Permission, Level = 1 })
	TriggerClientEvent("pause:Notify",source,"Sucesso","Compra concluída.","verde")
	Active[Passport] = nil

	return exports.crons:Check(Passport,"RemovePermission",{ Permission = Data.Permission })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Battlepass()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Consult = vRP.Battlepass(Passport)
	if not Consult then
		return false
	end

	return { Consult.Free,Consult.Premium,Consult.Points,Consult.Active }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSRESCUE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.BattlepassRescue(Mode,Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local DataItens = Battlepass[Mode] and Battlepass[Mode][Number]
	if not DataItens then
		return false
	end

	if Active[Passport] then
		return false
	end

	if (BattleStart + 2592000) < os.time() then
		return false
	end

	Active[Passport] = true

	local Consult = vRP.Battlepass(Passport)
	if not Consult then
		Active[Passport] = nil
		return false
	end

	if Mode == "Premium" and not Consult.Active then
		Active[Passport] = nil
		return false
	end

	local Item = DataItens.Item
	local Amount = DataItens.Amount
	local Next = (Consult[Mode] or 0) + 1

	if not vRP.CheckWeight(Passport,Item,Amount) then
		Active[Passport] = nil
		return false
	end

	if Next ~= Number then
		Active[Passport] = nil
		return false
	end

	if not vRP.BattlepassPayment(Passport,Mode,BattlepassPoints) then
		Active[Passport] = nil
		return false
	end

	exports.discord:Embed("Battlepass",("**[PASSAPORTE]:** %s\n**[MODO]:** %s\n**[VALOR]:** %s"):format(Passport,Mode,Number))
	TriggerClientEvent("pause:Notify",source,"Sucesso","Resgate concluído.","verde")
	vRP.GenerateItem(Passport,Item,Amount)
	Active[Passport] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.BattlepassBuy()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Configpass = vRP.Battlepass(Passport)
	if not Configpass then
		Active[Passport] = nil
		return false
	end

	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Battlepass" })
	local Start = Consult and json.decode(Consult.Information) or 0
	local ValidPeriod = (Start + 2592000) >= os.time()

	if (ValidPeriod and not Configpass.Active and vRP.PaymentGems(Passport,BattlepassPrice)) then
		exports.discord:Embed("Battlepass",("**[PASSAPORTE]:** %s\n**[MODO]:** Comprou\n**[VALOR]:** %s"):format(Passport,BattlepassPrice))
		TriggerClientEvent("pause:Notify",source,"Sucesso","Compra concluída.","verde")
		vRP.BattlepassBuy(Passport)
		Active[Passport] = nil

		return true
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPENBOX
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.OpenBox(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] or PlayerBox[Passport] then
		return false
	end

	local Box = Boxes[Number]
	if not Box then
		return false
	end

	Active[Passport] = true

	local Price = Box.Price
	if Box.Discount and Box.Discount < 1.0 then
		Price = Price * Box.Discount
	end

	if not vRP.PaymentGems(Passport,Price) then
		Active[Passport] = nil
		return false
	end

	local Reward = RandPercentage(Box.Rewards)
	if not Reward then
		Active[Passport] = nil
		return false
	end

	PlayerBox[Passport] = Reward

	SetTimeout(6000,function()
		local CurrentReward = PlayerBox[Passport]
		if not CurrentReward then
			Active[Passport] = nil
			return false
		end

		local RewardData = Box.Rewards[CurrentReward.Id]
		if RewardData then
			exports.discord:Embed("Boxes","**[PASSAPORTE]:** "..Passport.."\n**[CAIXA]:** "..Box.Name.."\n**[PRÊMIO]:** "..RewardData.Amount.."x "..RewardData.Item)
			vRP.GenerateItem(Passport,RewardData.Item,RewardData.Amount)
		end

		PlayerBox[Passport] = nil
		Active[Passport] = nil
	end)

	return Reward.Id
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKETPLACE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Marketplace()
	local Result = {}
	local ToRemove = {}
	local CurrentTimer = os.time()
	for Index,v in pairs(Marketplace) do
		if not v or not v.item or not v.timer or v.timer <= CurrentTimer then
			ToRemove[#ToRemove + 1] = Index
			goto Continue
		end

		local Item = v.item
		if not exports.vrp:ItemExist(Item) then
			ToRemove[#ToRemove + 1] = Index
			goto Continue
		end

		local Data = {
			Index = Index,
			Price = v.price or 0,
			Amount = v.quantity or 0,
			Passport = v.passport,
			Name = exports.vrp:ItemName(Item),
			Image = v.key
		}

		local Split = splitString(Item)
		local Extra = Split and Split[2]
		if Extra then
			local Loaded = exports.vrp:ItemLoads(Item)
			if Loaded and Loaded > 0 then
				Data.Charges = parseInt(Extra * (100 / Loaded))
			end

			local Durability = exports.vrp:ItemDurability(Item)
			if Durability then
				local Elapsed = CurrentTimer - Extra
				local Remaining = Durability - Elapsed

				Data.Durability = parseInt(math.max(Remaining,0))
				Data.Days = Durability
			end
		end

		Result[#Result + 1] = Data

		::Continue::
	end

	for Number = 1,#ToRemove do
		Marketplace[ToRemove[Number]] = nil
	end

	return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKETPLACEINVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MarketplaceInventory(Mode)
	local source = source
	local Passport = vRP.Passport(source)

	if not (Passport and Mode) then
		return false
	end

	local Return = {}
	local CurrentTimer = os.time()

	if Mode == "Create" then
		local Inv = vRP.Inventory(Passport)
		for Index,v in pairs(Inv) do
			if not exports.vrp:BlockMarket(v.item) and not vRP.CheckDamaged(v.item) then
				local Table = {
					Key = v.item,
					Index = Index,
					Amount = v.amount,
					Name = exports.vrp:ItemName(v.item),
					Image = exports.vrp:ItemIndex(v.item)
				}

				local Split = splitString(v.item)
				if Split[2] then
					local Loaded = exports.vrp:ItemLoads(v.item)
					if Loaded then
						Table.Charges = parseInt(Split[2] * (100 / Loaded))
					end

					local Durability = exports.vrp:ItemDurability(v.item)
					if Durability then
						Table.Durability = parseInt(CurrentTimer - Split[2])
						Table.Days = Durability
					end
				end

				table.insert(Return,Table)
			end
		end
	elseif Mode == "Announce" then
		for Index,v in pairs(Marketplace) do
			if Passport == v.passport then
				local Table = {
					Key = Index,
					Price = v.price,
					Amount = v.quantity,
					Name = exports.vrp:ItemName(v.item),
					Image = v.key
				}

				local Split = splitString(v.item)
				if Split[2] then
					local Loaded = exports.vrp:ItemLoads(v.item)
					if Loaded then
						Table.Charges = parseInt(Split[2] * (100 / Loaded))
					end

					local Durability = exports.vrp:ItemDurability(v.item)
					if Durability then
						Table.Durability = parseInt(CurrentTimer - Split[2])
						Table.Days = Durability
					end
				end

				table.insert(Return,Table)
			end
		end
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKETPLACEANNOUNCE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MarketplaceAnnounce(Table)
	local source = source
	local Item = Table.Item
	local Price = Table.Price
	local Quantity = Table.Amount
	local Passport = vRP.Passport(source)
	if Passport and Item and Price and Quantity and not exports.vrp:BlockMarket(Item) and vRP.PaymentFull(Passport,Price * MarketplaceTax) and vRP.TakeItem(Passport,Item,Quantity) then
		repeat
			Selected = GenerateString("DDLLDDLL")
		until Selected and not Marketplace[Selected]

		Marketplace[Selected] = {
			item = Item,
			price = Price,
			quantity = Quantity,
			passport = Passport,
			key = exports.vrp:ItemIndex(Item),
			timer = os.time() + 259200
		}

		exports.discord:Embed("Marketplace","**[MODO]:** Anúncio\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Dotted(Quantity).."x "..Item.."\n**[VALOR]:** $"..Dotted(Price))

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKETPLACECANCEL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MarketplaceCancel(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Offer = Marketplace[Selected]
	if not Offer or Offer.passport ~= Passport then
		return false
	end

	if not vRP.GiveItem(Passport,Offer.item,Offer.quantity) then
		return false
	end

	exports.discord:Embed("Marketplace",("**[MODO]:** Cancelar\n**[PASSAPORTE]:** %s\n**[ITEM]:** %sx %s\n**[VALOR]:** $%s"):format(Passport,Offer.quantity,Offer.item,Offer.price))
	Marketplace[Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKETPLACEBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MarketplaceBuy(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Marketplace[Selected] and Marketplace[Selected].passport and Marketplace[Selected].passport ~= Passport then
		Active[Passport] = true

		if vRP.MaxItens(Passport,Marketplace[Selected].item,Marketplace[Selected].quantity) then
			TriggerClientEvent("pause:Notify",source,"Atenção","Limite atingido.","vermelho")
			Active[Passport] = nil

			return false
		end

		if vRP.PaymentFull(Passport,Marketplace[Selected].price) and vRP.GiveItem(Passport,Marketplace[Selected].item,Marketplace[Selected].quantity) then
			exports.discord:Embed("Marketplace","**[MODO]:** Compra\n**[PASSAPORTE]:** "..Passport.."\n**[VENDEDOR]:** "..Marketplace[Selected].passport.."\n**[ITEM]:** "..Dotted(Marketplace[Selected].quantity).."x "..Marketplace[Selected].item.."\n**[VALOR]:** $"..Dotted(Marketplace[Selected].price))
			TriggerClientEvent("pause:Notify",source,"Sucesso","Compra concluída.","verde")
			vRP.GiveBank(Marketplace[Selected].passport,Marketplace[Selected].price)
			Marketplace[Selected] = nil
			Active[Passport] = nil

			return true
		end

		Active[Passport] = nil
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Ranking(Direction)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return {}
	end

	Active[Passport] = true

	local Ranking = {}
	local Query = string.format("SELECT Name,JSON_UNQUOTE(JSON_EXTRACT(Information,'$.Online')) AS Online FROM entitydata WHERE JSON_EXTRACT(Information,'$.Online') IS NOT NULL ORDER BY CAST(JSON_UNQUOTE(JSON_EXTRACT(Information,'$.Online')) AS UNSIGNED) %s LIMIT 50",Direction)
	local Consult = exports.oxmysql:query_async(Query)
	if Consult and #Consult > 0 then
		for _,v in ipairs(Consult) do
			local OtherPassport = SplitTwo(v.Name,":")
			local Identity = vRP.Identity(OtherPassport)
			if Identity then
				Ranking[#Ranking + 1] = {
					Passport = OtherPassport,
					Name = ("%s %s"):format(Identity.Name,Identity.Lastname),
					Blood = Sanguine(Identity.Blood),
					Hours = parseInt(v.Online,true),
					LastLogin = Identity.Login
				}
			end
		end
	end

	Active[Passport] = nil

	return Ranking
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STATISTICS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Statistics()
	local Result = {
		Kills = 0,
		Deaths = 0,
		Logs = {}
	}

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return Result
	end

	local PlayerName = vRP.FullName(Passport)
	local Query = "SELECT * FROM deaths_creative WHERE Attacker = @Passport OR Victim = @Passport LIMIT 50"
	local Deaths = exports.oxmysql:query_async(Query,{ Passport = Passport })

	if not Deaths or #Deaths == 0 then
		return Result
	end

	for _,v in ipairs(Deaths) do
		local WeaponHash = tonumber(v.Weapon)
		local WeaponName = WeaponNames[WeaponHash] or v.Weapon

		local IsKiller = v.Attacker == Passport
		local Killer = IsKiller and Passport or v.Attacker
		local Victim = IsKiller and v.Victim or Passport

		local KillerName = IsKiller and PlayerName or vRP.FullName(Killer)
		local VictimName = IsKiller and vRP.FullName(Victim) or PlayerName

		if IsKiller then
			Result.Kills = Result.Kills + 1
		else
			Result.Deaths = Result.Deaths + 1
		end

		Result.Logs[#Result.Logs + 1] = {
			Killer = { Passport = Killer, Name = KillerName },
			Victim = { Passport = Victim, Name = VictimName },
			Weapon = WeaponName,
			Date = v.Timestamp
		}
	end

	return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DAILY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Daily()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return {}
	end

	local Identity = vRP.Identity(Passport)
	if not Identity or not Identity.Daily then
		return {}
	end

	local Consult = splitString(Identity.Daily)
	return { string.format("%s-%s-%s",Consult[1],Consult[2],Consult[3]),parseInt(Consult[4]),#Daily }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DAILYRESCUE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DailyRescue(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Daily[Number] or Active[Passport] then
		return false
	end

	local Identity = vRP.Identity(Passport)
	if not Identity or not Identity.Daily then
		return false
	end

	Active[Passport] = true

	local Date = os.date("%d-%m-%Y")
	local SplitDate,SplitCurrent = splitString(Date),splitString(Identity.Daily)
	local CurrentDay = os.time({ day = SplitDate[1], month = SplitDate[2], year = SplitDate[3] })
	local LastedDay = os.time({ day = SplitCurrent[1], month = SplitCurrent[2], year = SplitCurrent[3] })

	if CurrentDay > LastedDay and Number > parseInt(SplitCurrent[4]) then
		for Item,Amount in pairs(Daily[Number]) do
			vRP.GenerateItem(Passport,Item,Amount)
		end

		exports.discord:Embed("Daily","**[PASSAPORTE]:** "..Passport.."\n**[DIA]:** "..Number)
		TriggerClientEvent("pause:Notify",source,"Sucesso","Recompensa recebida.","verde")
		vRP.UpdateDaily(Passport,source,string.format("%s-%d",Date,Number))
	end

	Active[Passport] = nil

	return CurrentDay > LastedDay and Number > tonumber(SplitCurrent[4])
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Code(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local ConsultCodes = exports.oxmysql:single_async("SELECT * FROM codes_creative WHERE Code = ? LIMIT 1",{ Name })
	if not ConsultCodes then
		TriggerClientEvent("pause:Notify",source,"Aviso","Código inválido.","amarelo")
		Active[Passport] = nil
		return false
	end

	if ConsultCodes.Max > 0 and ConsultCodes.Used >= ConsultCodes.Max then
		TriggerClientEvent("pause:Notify",source,"Aviso","Limite de resgate atingido.","amarelo")
		Active[Passport] = nil
		return false
	end

	local ConsultRedemptions = exports.oxmysql:single_async("SELECT 1 FROM codes_creative_redeemd WHERE Code = ? AND Passport = ? LIMIT 1",{ Name,Passport })
	if ConsultRedemptions then
		TriggerClientEvent("pause:Notify",source,"Aviso","Código já resgatado.","amarelo")
		Active[Passport] = nil
		return false
	end

	local Rewards = json.decode(ConsultCodes.Rewards or "[]")
	for _,v in ipairs(Rewards) do
		if v.Item and exports.vrp:ItemExist(v.Item) and v.Amount and v.Amount > 0 then
			vRP.GenerateItem(Passport,v.Item,v.Amount)
		end
	end

	exports.oxmysql:transaction_async({
		{
			query = "INSERT INTO codes_creative_redeemd (Code,Passport,RedeemdAt) VALUES (?,?,?)", values = { Name,Passport,os.time() }
		},{
			query = "UPDATE codes_creative SET Used = Used + 1 WHERE Code = ?", values = { Name }
		}
	})

	TriggerClientEvent("pause:Notify",source,"Parabéns","Código resgatado com sucesso.","verde")
	Active[Passport] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WIPEBATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("pause:WipeBattlepass",function(CurrentTimer)
	BattleStart = CurrentTimer
	TriggerClientEvent("pause:UpdateConfig",-1)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if PlayerBox[Passport] then
		PlayerBox[Passport] = nil
	end

	if Active[Passport] then
		Active[Passport] = nil
	end

	if Salarys[Passport] then
		Salarys[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	vRP.Query("entitydata/SetData",{ Name = "Marketplace", Information = json.encode(Marketplace) })

	if not Silenced then
		print("O resource ^2Pause^7 salvou os dados.")
	end
end)