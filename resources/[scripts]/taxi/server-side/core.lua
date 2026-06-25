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
Tunnel.bindInterface("taxi",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Attention = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Payment(Locate,Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Locations[Locate] and Locations[Locate][Selected] then
		Active[Passport] = true

		local Coords = vRP.GetEntityCoords(source)
		if not vRPC.LastVehicle(source,"taxi") or #(Coords - Locations[Locate][Selected].Vehicle) > 5 then
			exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Taxista",source)

			Attention[Passport] = (Attention[Passport] or 0) + 1
			if Attention[Passport] >= 5 then
				vRP.SetBanned(Passport,-1,"Hacker")
			end
		end

		local GainExperience = 3
		local Amount = math.random(275,325)
		local Experience,Level = vRP.GetExperience(Passport,"Taxi")
		local Valuation = Amount + Amount * (0.05 * Level)

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation + (Valuation * 0.1)
		end

		for Permission,Multiplier in pairs({ Ouro = 0.1, Prata = 0.075, Bronze = 0.05 }) do
			if vRP.HasService(Passport,Permission) then
				Valuation = Valuation + (Valuation * Multiplier)
				GainExperience = GainExperience + 3
			end
		end

		vRP.GenerateItem(Passport,"dollar",Valuation,true)
		vRP.PutExperience(Passport,"Taxi",GainExperience)
		vRP.BattlepassPoints(Passport,GainExperience)
		vRP.UpgradeStress(Passport,3)

		Active[Passport] = nil
	end
end
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