-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Attention = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
for Number = 1,#Objects do
	GlobalState["Farmer:"..Number] = 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MINERMAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("farmer:Minerman")
AddEventHandler("farmer:Minerman",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	if not Number or type(Number) ~= "number" then
		exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Farmer",source)

		Attention[Passport] = (Attention[Passport] or 0) + 1
		if Attention[Passport] >= 5 then
			vRP.SetBanned(Passport,-1,"Hacker")
		end
	end

	local FarmerKey = "Farmer:"..Number
	local FarmerState = GlobalState[FarmerKey]
	if not FarmerState or GlobalState.Work < FarmerState then
		return false
	end

	local Item = "pickaxe"
	local Pickaxe = vRP.ConsultItem(Passport,Item)
	local PickaxePlus = vRP.ConsultItem(Passport,Item.."plus")

	if not Pickaxe and not PickaxePlus then
		TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>1x "..ItemName(Item).."</b>.","amarelo",5000)
	else
		Active[Passport] = true
		Player(source).state.Cancel = true
		Player(source).state.Buttons = true
		vRPC.CreateObjects(source,"melee@large_wpn@streamed_core","ground_attack_on_spot","prop_tool_pickaxe",1,18905,0.10,-0.1,0.0,-92.0,260.0,5.0)

		if vRP.Task(source,Pickaxe and 10 or 5,10000) and GlobalState.Work >= FarmerState then
			FarmerState = GlobalState.Work + 60

			local Result = {
				{ Item = "tin_pure", Chance = 125, Min = 1, Max = 1 },
				{ Item = "lead_pure", Chance = 125, Min = 1, Max = 1 },
				{ Item = "copper_pure", Chance = 100, Min = 1, Max = 1 },
				{ Item = "iron_pure", Chance = 75, Min = 1, Max = 1 },
				{ Item = "gold_pure", Chance = 75, Min = 1, Max = 1 },
				{ Item = "diamond_pure", Chance = 25, Min = 1, Max = 1 },
				{ Item = "ruby_pure", Chance = 25, Min = 1, Max = 1 }
			}

			if PickaxePlus then
				Result = {
					{ Item = "tin_pure", Chance = 125, Min = 1, Max = 1 },
					{ Item = "lead_pure", Chance = 125, Min = 1, Max = 1 },
					{ Item = "copper_pure", Chance = 100, Min = 1, Max = 1 },
					{ Item = "iron_pure", Chance = 75, Min = 1, Max = 1 },
					{ Item = "gold_pure", Chance = 75, Min = 1, Max = 1 },
					{ Item = "diamond_pure", Chance = 25, Min = 1, Max = 1 },
					{ Item = "ruby_pure", Chance = 25, Min = 1, Max = 1 },
					{ Item = "sapphire_pure", Chance = 15, Min = 1, Max = 1 },
					{ Item = "emerald_pure", Chance = 10, Min = 1, Max = 1 },
					{ Item = "chalcopyrite", Chance = 1, Min = 1, Max = 1 },
					{ Item = "bauxite", Chance = 1, Min = 1, Max = 1 }
				}
			end

			local Consult = RandPercentage(Result)
			if exports.party:DoesExist(Passport,2) then
				Consult.Valuation = Consult.Valuation + (Consult.Valuation * 0.5)
			end

			if exports.inventory:Buffs("Luck",Passport) then
				Consult.Valuation = Consult.Valuation + (Consult.Valuation * 0.5)
			end

			for Permission,Multiplier in pairs({ Ouro = 0.5, Prata = 0.35, Bronze = 0.2 }) do
				if vRP.HasService(Passport,Permission) then
					Consult.Valuation = Consult.Valuation + (Consult.Valuation * Consult.Valuation * Multiplier)
				end
			end

			if vRP.CheckWeight(Passport,Consult.Item,Consult.Valuation) and not vRP.MaxItens(Passport,Consult.Item,Consult.Valuation) then
				vRP.GenerateItem(Passport,Consult.Item,Consult.Valuation,true)
			else
				TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
				exports.inventory:Drops(Passport,source,Consult.Item,Consult.Valuation)
			end

			vRP.BattlepassPoints(Passport,2)
			vRP.UpgradeStress(Passport,1)
		end

		Player(source).state.Buttons = false
		Player(source).state.Cancel = false
		Active[Passport] = nil
		vRPC.Destroy(source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LUMBERMAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("farmer:Lumberman")
AddEventHandler("farmer:Lumberman",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local FarmerKey = "Farmer:"..Number
	local FarmerState = GlobalState[FarmerKey]
	if not FarmerState or GlobalState.Work < FarmerState then
		return false
	end

	if not Number or type(Number) ~= "number" then
		exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Farmer",source)

		Attention[Passport] = (Attention[Passport] or 0) + 1
		if Attention[Passport] >= 5 then
			vRP.SetBanned(Passport,-1,"Hacker")
		end
	end

	local Item = "axe"
	local Axe = vRP.ConsultItem(Passport,Item)
	local AxePlus = vRP.ConsultItem(Passport,Item.."plus")

	if not Axe and not AxePlus then
		TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>1x "..ItemName(Item).."</b>.","amarelo",5000)
	else
		Active[Passport] = true
		Player(source).state.Cancel = true
		Player(source).state.Buttons = true
		vRPC.playAnim(source,false,{"lumberjackaxe@idle","idle"},true)

		if vRP.Task(source,Pickaxe and 10 or 5,10000) and GlobalState.Work >= FarmerState then
			FarmerState = GlobalState.Work + 30

			local Valuation = 3
			local Item = "woodlog"
			if exports.party:DoesExist(Passport,2) then
				Valuation = Valuation + (Valuation * 0.25)
			end

			if exports.inventory:Buffs("Luck",Passport) then
				Valuation = Valuation + (Valuation * 0.25)
			end

			for Permission,Multiplier in pairs({ Ouro = 0.25, Prata = 0.2, Bronze = 0.15 }) do
				if vRP.HasService(Passport,Permission) then
					Valuation = Valuation + (Valuation * Multiplier)
				end
			end

			if vRP.CheckWeight(Passport,Item,Valuation) and not vRP.MaxItens(Passport,Item,Valuation) then
				vRP.GenerateItem(Passport,Item,Valuation,true)
			else
				TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
				exports.inventory:Drops(Passport,source,Item,Valuation)
			end

			vRP.BattlepassPoints(Passport,2)
			vRP.UpgradeStress(Passport,1)
		end

		Player(source).state.Buttons = false
		Player(source).state.Cancel = false
		Active[Passport] = nil
		vRPC.Destroy(source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSPORTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("farmer:Transporter")
AddEventHandler("farmer:Transporter",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local FarmerKey = "Farmer:"..Number
	local FarmerState = GlobalState[FarmerKey]
	if not FarmerState or GlobalState.Work < FarmerState then
		return false
	end

	if not Number or type(Number) ~= "number" then
		exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Farmer",source)

		Attention[Passport] = (Attention[Passport] or 0) + 1
		if Attention[Passport] >= 5 then
			vRP.SetBanned(Passport,-1,"Hacker")
		end
	end

	if not vRPC.LastVehicle(source,"trash") then
		TriggerClientEvent("Notify",source,"Atenção","Necessário a utilização do veículo <b>Trash</b>.","amarelo",5000)
		return false
	end

	Active[Passport] = true
	Player(source).state.Cancel = true
	Player(source).state.Buttons = true
	TriggerClientEvent("Progress",source,"Coletando",1000)
	vRPC.playAnim(source,false,{ "pickup_object","pickup_low" },true)

	Wait(1000)

	if GlobalState.Work >= FarmerState then
		GlobalState[FarmerKey] = GlobalState.Work + 30

		local Amount = 1
		local Item = "pouch"
		if exports.inventory:Buffs("Luck",Passport) then
			Amount = Amount + 1
		end

		if not vRP.MaxItens(Passport,Item,Amount) and vRP.CheckWeight(Passport,Item,Amount) then
			vRP.GenerateItem(Passport,Item,Amount,true)
		else
			TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
			exports.inventory:Drops(Passport,source,Item,Amount)
		end

		vRP.BattlepassPoints(Passport,5)
		vRP.UpgradeStress(Passport,1)
	end

	Player(source).state.Buttons = false
	Player(source).state.Cancel = false
	Active[Passport] = nil
	vRPC.Destroy(source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SANDMAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("farmer:Sandman")
AddEventHandler("farmer:Sandman",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local FarmerKey = "Farmer:"..Number
	local FarmerState = GlobalState[FarmerKey]
	if not FarmerState or GlobalState.Work < FarmerState then
		return false
	end

	if not Number or type(Number) ~= "number" then
		exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Farmer",source)

		Attention[Passport] = (Attention[Passport] or 0) + 1
		if Attention[Passport] >= 5 then
			vRP.SetBanned(Passport,-1,"Hacker")
		end
	end

	if not vRPC.LastVehicle(source,"trash") then
		TriggerClientEvent("Notify",source,"Atenção","Necessário a utilização do veículo <b>Trash</b>.","amarelo",5000)
		return false
	end

	Active[Passport] = true
	Player(source).state.Cancel = true
	Player(source).state.Buttons = true
	TriggerClientEvent("Progress",source,"Coletando",1000)
	vRPC.playAnim(source,false,{ "pickup_object","pickup_low" },true)

	Wait(1000)

	if GlobalState.Work >= FarmerState then
		GlobalState[FarmerKey] = GlobalState.Work + 30

		local Amount = 1
		local Item = "sand"
		if exports.inventory:Buffs("Luck",Passport) then
			Amount = Amount + 1
		end

		if not vRP.MaxItens(Passport,Item,Amount) and vRP.CheckWeight(Passport,Item,Amount) then
			vRP.GenerateItem(Passport,Item,Amount,true)
		else
			TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
			exports.inventory:Drops(Passport,source,Item,Amount)
		end

		vRP.BattlepassPoints(Passport,5)
		vRP.UpgradeStress(Passport,1)
	end

	Player(source).state.Buttons = false
	Player(source).state.Cancel = false
	Active[Passport] = nil
	vRPC.Destroy(source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRASHER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("farmer:Trasher")
AddEventHandler("farmer:Trasher",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local FarmerKey = "Farmer:"..Number
	local FarmerState = GlobalState[FarmerKey]
	if not FarmerState or GlobalState.Work < FarmerState then
		return false
	end

	if not Number or type(Number) ~= "number" then
		exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Farmer",source)

		Attention[Passport] = (Attention[Passport] or 0) + 1
		if Attention[Passport] >= 5 then
			vRP.SetBanned(Passport,-1,"Hacker")
		end
	end

	if not vRPC.LastVehicle(source,"trash") then
		TriggerClientEvent("Notify",source,"Atenção","Necessário a utilização do veículo <b>Trash</b>.","amarelo",5000)
		return false
	end

	Active[Passport] = true
	Player(source).state.Cancel = true
	Player(source).state.Buttons = true
	TriggerClientEvent("Progress",source,"Coletando",1000)
	vRPC.playAnim(source,false,{ "pickup_object","pickup_low" },true)

	Wait(1000)

	if GlobalState.Work >= FarmerState then
		GlobalState[FarmerKey] = GlobalState.Work + 180

		local Item = "binbag"
		if not vRP.MaxItens(Passport,Item) and vRP.CheckWeight(Passport,Item) then
			vRP.GenerateItem(Passport,Item,1,true)
		else
			TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
			exports.inventory:Drops(Passport,source,Item,1)
		end

		vRP.PutExperience(Passport,"Garbageman",1)
		vRP.BattlepassPoints(Passport,1)
		vRP.UpgradeStress(Passport,1)
	end

	Player(source).state.Buttons = false
	Player(source).state.Cancel = false
	Active[Passport] = nil
	vRPC.Destroy(source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PRISON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("farmer:Prison")
AddEventHandler("farmer:Prison",function(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	if not Number or type(Number) ~= "number" then
		exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Farmer",source)

		Attention[Passport] = (Attention[Passport] or 0) + 1
		if Attention[Passport] >= 5 then
			vRP.SetBanned(Passport,-1,"Hacker")
		end
	end

	local FarmerKey = "Farmer:"..Number
	local FarmerState = GlobalState[FarmerKey]
	if not FarmerState or GlobalState.Work < FarmerState then
		return false
	end

	local Identity = vRP.Identity(Passport)
	if not Identity or (Identity.Prison or 0) <= 0 then
		return false
	end

	Active[Passport] = true
	Player(source).state.Cancel = true
	Player(source).state.Buttons = true
	TriggerClientEvent("Progress",source,"Coletando",1000)
	vRPC.playAnim(source,false,{ "pickup_object","pickup_low" },true)

	Wait(1000)

	if GlobalState.Work >= FarmerState then
		GlobalState[FarmerKey] = GlobalState.Work + 60
		vRP.UpdatePrison(Passport,1)
	end

	Player(source).state.Buttons = false
	Player(source).state.Cancel = false
	Active[Passport] = nil
	vRPC.Destroy(source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if Active[Passport] then
		Active[Passport] = nil
	end

	if Attention[Passport] then
		Attention[Passport] = nil
	end
end)