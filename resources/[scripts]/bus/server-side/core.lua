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
Tunnel.bindInterface("bus",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Attention = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Payment(Route,Selected)
	local source = source
	local Select = Locations[Route]
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Select then
		Active[Passport] = true

		local Coords = vRP.GetEntityCoords(source)
		local Inside = vRPC.LastVehicle(source,"bus")
		local Distance = #(Coords - Select.Coords[Selected])
		if not Selected or not Inside or Distance > 25 then
			exports.discord:Embed("Hackers","**[PASSAPORTE]:** "..Passport.."\n**[FUNÇÃO]:** Payment do Motorista",source)

			Attention[Passport] = (Attention[Passport] or 0) + 1
			if Attention[Passport] >= 5 then
				vRP.SetBanned(Passport,-1,"Hacker")
			end
		end

		local Amount = math.random(Select.Payment.Min,Select.Payment.Max)
		local _,Level = vRP.GetExperience(Passport,"Driver")
		local Valuation = Amount + Amount * (0.05 * Level)
		local GainExperience = 1

		if exports.party:DoesExist(Passport,4) then
			Valuation = Valuation + (Valuation * 0.1)
		end

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation + (Valuation * 0.1)
		end

		for Permission,Multiplier in pairs({ Ouro = 0.10, Prata = 0.075, Bronze = 0.05 }) do
			if vRP.HasService(Passport,Permission) then
				Valuation = Valuation + (Valuation * Multiplier)
				GainExperience = GainExperience + 1
			end
		end

		vRP.PutExperience(Passport,"Driver",GainExperience)
		vRP.GenerateItem(Passport,"dollar",Valuation,true)
		vRP.BattlepassPoints(Passport,GainExperience)
		vRP.UpgradeStress(Passport,1)

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