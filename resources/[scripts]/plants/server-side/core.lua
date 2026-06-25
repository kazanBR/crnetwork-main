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
Tunnel.bindInterface("plants",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Plants = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local CurrentTimer = os.time()
	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "Plants" })
	Plants = Consult and json.decode(Consult.Information) or {}

	for Index,v in pairs(Plants) do
		if v.Timer and (CurrentTimer - v.Timer) > 36000 then
			Plants[Index] = nil
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLANTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Plants",function(Hash,Coords,Route,Item,Amount,Purity)
	repeat
		Selected = GenerateString("LLDD")
	until Selected and not Plants[Selected]

	Plants[Selected] = {
		Water = 0.0,
		Hash = Hash,
		Item = Item,
		Route = Route,
		Coords = Coords,
		Purity = Purity,
		Timer = os.time() + 7200,
		Amount = math.random(Amount.Min,Amount.Max)
	}

	TriggerClientEvent("plants:New",-1,Selected,Plants[Selected])
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKDEATH
-----------------------------------------------------------------------------------------------------------------------------------------
function CheckDeath(source,Number)
	if Number and Plants[Number] and Plants[Number].Timer and (os.time() - Plants[Number].Timer) > 36000 then
		Plants[Number] = nil
		TriggerClientEvent("dynamic:Close",source)
		TriggerClientEvent("plants:Remove",-1,Number)
		TriggerClientEvent("Notify",source,"Horticultura","A plantação apodreceu.","vermelho",5000)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLANTS:COLLECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("plants:Collect")
AddEventHandler("plants:Collect",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Plants[Number] and Plants[Number].Timer and not CheckDeath(source,Number) and os.time() >= Plants[Number].Timer then
		local Temporary = Plants[Number]

		Plants[Number] = nil
		Active[Passport] = true
		Player(source).state.Cancel = true
		Player(source).state.Buttons = true
		TriggerClientEvent("dynamic:Close",source)
		TriggerClientEvent("Progress",source,"Coletando",10000)
		vRPC.playAnim(source,false,{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer"},true)

		SetTimeout(10000,function()
			local Amount = Temporary.Amount or 1
			local Purity = Temporary.Purity or 0
			local Valuation = Amount * (1 + (Purity / 100))

			if Temporary.Water and Valuation then
				Valuation = Valuation + (Valuation * Temporary.Water)
			end

			if vRP.CheckWeight(Passport,Temporary.Item,Valuation) then
				vRP.GenerateItem(Passport,Temporary.Item,Valuation,true)
			else
				TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
				exports.inventory:Drops(Passport,source,Temporary.Item,Valuation)
			end

			TriggerClientEvent("plants:Remove",-1,Number)
			Player(source).state.Buttons = false
			Player(source).state.Cancel = false
			Active[Passport] = nil

			vRPC.Destroy(source)
		end)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLANTS:CLONING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("plants:Cloning")
AddEventHandler("plants:Cloning",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Plants[Number] and Plants[Number].Timer and not CheckDeath(source,Number) and (Plants[Number].Timer - os.time()) <= 3600 then
		local Temporary = Plants[Number]

		Plants[Number] = nil
		Active[Passport] = true
		Player(source).state.Cancel = true
		Player(source).state.Buttons = true
		TriggerClientEvent("dynamic:Close",source)
		TriggerClientEvent("Progress",source,"Coletando",10000)
		vRPC.playAnim(source,false,{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer"},true)

		SetTimeout(10000,function()
			local Valuation = 2
			local Purity = Temporary.Purity or 0
			if Purity == 0 then
				local Puritys = exports.vrp:ItemPuritys()
				Purity = RandPercentage(Puritys).Percent
			end

			local NameClone = string.format("%sclone_%d",Temporary.Item,Purity)

			if Temporary.Water then
				Valuation = Valuation + (Valuation * Temporary.Water)
			end

			if vRP.CheckWeight(Passport,NameClone,Valuation) then
				vRP.GenerateItem(Passport,NameClone,Valuation,true)
			else
				TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
				exports.inventory:Drops(Passport,source,NameClone,Valuation)
			end

			TriggerClientEvent("plants:Remove",-1,Number)
			Player(source).state.Buttons = false
			Player(source).state.Cancel = false
			Active[Passport] = nil

			vRPC.Destroy(source)
		end)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLANTS:WATER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("plants:Water")
AddEventHandler("plants:Water",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Plants[Number] and Plants[Number].Timer and not CheckDeath(source,Number) and Plants[Number].Timer >= os.time() then
		if Plants[Number].Water and Plants[Number].Water < 1.0 and vRP.ConsultItem(Passport,"purifiedwater") then
			Active[Passport] = true
			Player(source).state.Cancel = true
			Player(source).state.Buttons = true
			TriggerClientEvent("dynamic:Close",source)
			TriggerClientEvent("Progress",source,"Coletando",10000)
			vRPC.CreateObjects(source,"weapon@w_sp_jerrycan","fire","prop_wateringcan",1,28422,0.4,0.1,0.0,90.0,180.0,0.0)

			SetTimeout(10000,function()
				if Plants[Number] and Plants[Number].Water < 1.0 and vRP.RemoveCharges(Passport,"purifiedwater") then
					Plants[Number].Water = Plants[Number].Water + 0.20
				end

				Player(source).state.Buttons = false
				Player(source).state.Cancel = false
				Active[Passport] = nil

				vRPC.Destroy(source)
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLANTS:DESTROY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("plants:Destroy")
AddEventHandler("plants:Destroy",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Plants[Number] then
		TriggerClientEvent("plants:Remove",-1,Number)
		TriggerClientEvent("dynamic:Close",source)
		Plants[Number] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INFORMATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Informations(Number)
	local source = source
	local Plant = Plants[Number]
	if not (Number and Plant and Plant.Timer and not CheckDeath(source,Number)) then
		return false
	end

	local Remaining = Plant.Timer - os.time()

	local function GetStatus(TimeLeft,Delay)
		if TimeLeft > Delay then
			return "Aguarde "..CompleteTimers(TimeLeft - Delay)
		end

		return "Processo concluído."
	end

	local CollectStatus = GetStatus(Remaining,0)
	local CloneStatus = GetStatus(Remaining,3600)

	return { CollectStatus,CloneStatus,Plant.Item,Plant.Water,Plant.Purity or 0 }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("plants:Table",source,Plants)
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
	vRP.Query("entitydata/SetData",{ Name = "Plants", Information = json.encode(Plants) })

	if not Silenced then
		print("O resource ^2Plants^7 salvou os dados.")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPLOSIONEVENT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("explosionEvent",function(source,Data)
	if Data.explosionType == 3 then
		local Route = GetPlayerRoutingBucket(source)

		for Selected,v in pairs(Plants) do
			if Route == v.Route then
				local Coords = vec3(v.Coords[1],v.Coords[2],v.Coords[3])
				local MolotovCoords = vec3(Data.posX,Data.posY,Data.posZ)
				if #(Coords - MolotovCoords) <= 5 then
					TriggerClientEvent("plants:Remove",-1,Selected)
					Plants[Selected] = nil
				end
			end
		end
	end
end)