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
Tunnel.bindInterface("moneywash",Creative)
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local MoneyWash = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "MoneyWash" })
	MoneyWash = Consult and json.decode(Consult.Information) or {}

	while true do
		Wait(60000)

		local CurrentTimer = os.time()
		for _,v in pairs(MoneyWash) do
			if v and v.Money and v.Washed and v.Value and v.Launded and v.Timer and v.Timer >= CurrentTimer and v.Money >= v.Value then
				v.Money = v.Money - v.Value
				v.Washed = v.Washed + v.Launded

				if v.Bleach and v.Bleach > CurrentTimer then
					v.Washed = v.Washed + (v.Launded * BleachPercentage)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WASH
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Wash",function(Passport,Item,Hash,Coords,Route,Value,Launded,Dirty,Clean)
	repeat
		Selected = GenerateString("DDLLDDLL")
	until Selected and not MoneyWash[Selected]

	MoneyWash[Selected] = {
		Money = 0,
		Washed = 0,
		Hash = Hash,
		Route = Route,
		Value = Value,
		Coords = Coords,
		Launded = Launded,
		Timer = os.time(),
		Passport = Passport,
		Bleach = os.time(),
		Dirty = Dirty,
		Clean = Clean,
		Item = Item
	}

	TriggerClientEvent("moneywash:New",-1,Selected,MoneyWash[Selected])
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("UpdateObjects",function(OldPassport,NewPassport)
	for Selected,v in pairs(MoneyWash) do
		if v.Passport and v.Passport == OldPassport then
			v.Passport = NewPassport
			TriggerClientEvent("moneywash:Update",-1,Selected,NewPassport)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Information(Selected)
	local source = source
	local Select = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Select then
		return false
	end

	if Select.Passport == Passport then
		return Select
	end

	if Select.Password then
		local Keyboard = vKEYBOARD.Password(source,"Senha")
		if Keyboard and Keyboard[1] and Keyboard[1] == Select.Password then
			return Select
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSWORD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:Password")
AddEventHandler("moneywash:Password",function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Data or Data.Passport ~= Passport then
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	local Keyboard = vKEYBOARD.Password(source,"Senha")
	if Keyboard and Keyboard[1] and Keyboard[1] ~= Data.Password then
		TriggerClientEvent("Notify",source,"Sucesso","Palavra chave atualizada.","verde",5000)
		Data.Password = Keyboard[1]
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:WASHED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:Washed")
AddEventHandler("moneywash:Washed",function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Data or not Data.Washed or Active[Passport] then
		return false
	end

	Active[Passport] = true

	if Data.Washed > 0 then
		vRP.GenerateItem(Passport,Data.Clean or "dollar",Data.Washed,true)
		TriggerClientEvent("dynamic:Close",source)
		Data.Washed = 0
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:MONEY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:Money")
AddEventHandler("moneywash:Money",function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Data or not Data.Money or Active[Passport] then
		return false
	end

	Active[Passport] = true

	if Data.Money > 0 then
		vRP.GenerateItem(Passport,Data.Dirty or "dirtydollar",Data.Money,true)
		TriggerClientEvent("dynamic:Close",source)
		Data.Money = 0
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:ADD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:Add")
AddEventHandler("moneywash:Add",function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Data or not Data.Money or Active[Passport] then
		return false
	end

	TriggerClientEvent("dynamic:Close",source)

	local Keyboard = vKEYBOARD.Primary(source,"Valor")
	if Keyboard and Keyboard[1] then
		local Amount = parseInt(Keyboard[1],true)
		if vRP.TakeItem(Passport,Data.Dirty or "dirtydollar",Amount) then
			TriggerClientEvent("Notify",source,"Sucesso","Dinheiro adicionado.","verde",5000)
			Data.Money = Data.Money + Amount
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:BATTERY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:Battery")
AddEventHandler("moneywash:Battery", function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Data or not Data.Timer or Data.Timer > os.time() or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Item = "washbattery"
	local Consult = vRP.ConsultItem(Passport,Item)
	if not Consult then
		TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>1x "..exports.vrp:ItemName(Item).."</b>.","amarelo",5000)
		Active[Passport] = nil
		return false
	end

	Player(source).state.Cancel = true
	Player(source).state.Buttons = true
	TriggerClientEvent("dynamic:Close",source)
	TriggerClientEvent("Progress",source,"Trocando bateria...",10000)
	vRPC.playAnim(source,false,{ "anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer" },true)

	SetTimeout(10000,function()
		if vRP.TakeItem(Passport,Consult.Item) then
			Data.Timer = os.time() + BatteryDuration
			TriggerClientEvent("Notify",source,"Sucesso","Bateria trocada.","verde",5000)
		end

		Player(source).state.Buttons = false
		Player(source).state.Cancel = false
		Active[Passport] = nil
		vRPC.Destroy(source)
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:BLEACH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:Bleach")
AddEventHandler("moneywash:Bleach",function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not Passport or not Data or (Data.Bleach and Data.Bleach > os.time()) or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Item = "washbleach"
	local Consult = vRP.ConsultItem(Passport,Item)
	if not Consult then
		TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>1x "..exports.vrp:ItemName(Item).."</b>.","amarelo",5000)
		Active[Passport] = nil
		return false
	end

	Player(source).state.Cancel = true
	Player(source).state.Buttons = true
	TriggerClientEvent("dynamic:Close",source)
	TriggerClientEvent("Progress",source,"Colocando alvejante...",10000)
	vRPC.playAnim(source,false,{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer"},true)

	SetTimeout(10000,function()
		if vRP.TakeItem(Passport,Consult.Item) then
			Data.Bleach = os.time() + BleachDuration
			TriggerClientEvent("Notify",source,"Sucesso","Alvejante colocado.","verde",5000)
		end

		Player(source).state.Buttons = false
		Player(source).state.Cancel = false
		Active[Passport] = nil
		vRPC.Destroy(source)
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:STOREOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("moneywash:StoreObjects")
AddEventHandler("moneywash:StoreObjects",function(Selected)
	local source = source
	local Data = MoneyWash[Selected]
	local Passport = vRP.Passport(source)
	if not vRP.HasService(Passport,"Admin",1) and (not Passport or not Data or Active[Passport] or Data.Passport ~= Passport) then
		return false
	end

	if (Data.Money or 0) > 0 or (Data.Washed or 0) > 0 then
		TriggerClientEvent("Notify",source,"Atenção","Esvazie a máquina antes de recolher.","amarelo",5000)
		return false
	end

	if not vRP.CheckWeight(Passport,"moneywash") then
		TriggerClientEvent("Notify",source,"Atenção","Espaço insuficiente na mochila.","amarelo",5000)
		return false
	end

	Active[Passport] = true

	if vRP.GiveItem(Passport,Data.Item,1,true) then
		TriggerClientEvent("moneywash:Remove",-1,Selected)
		MoneyWash[Selected] = nil
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("moneywash:Table",source,MoneyWash)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if Active[Passport] then
		Active[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	vRP.Query("entitydata/SetData",{ Name = "MoneyWash", Information = json.encode(MoneyWash) })

	if not Silenced then
		print("O resource ^2MoneyWash^7 salvou os dados.")
	end
end)