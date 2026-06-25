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
Tunnel.bindInterface("slotmachine",Creative)
vCLIENT = Tunnel.getInterface("slotmachine")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Players = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- MACHINES
-----------------------------------------------------------------------------------------------------------------------------------------
local Machines = {
	{
		Value = 250,
		Using = false,
		Winner = false,
		Coords = vec3(984.25,64.95,122.12),
		Prop = "vw_prop_casino_slot_04a_reels"
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- IMAGES
-----------------------------------------------------------------------------------------------------------------------------------------
local Images = { "2","3","6","2","4","1","6","5","2","1","3","6","7","1","4","5" }
-----------------------------------------------------------------------------------------------------------------------------------------
-- MULTIPLIER
-----------------------------------------------------------------------------------------------------------------------------------------
local Multiplier = {
	["1"] = 2,
	["2"] = 4,
	["3"] = 6,
	["4"] = 8,
	["5"] = 10,
	["6"] = 12,
	["7"] = 14
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Check(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Machines[Selected] and not Machines[Selected].Using then
		Machines[Selected].Using = Passport
		Players[Passport] = Selected

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEAN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Clean(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Machines[Selected] then
		if Machines[Selected].Using == Passport then
			Machines[Selected].Using = false
		end

		if Machines[Selected].Winner then
			Machines[Selected].Winner = false
		end

		if Players[Passport] then
			Players[Passport] = nil
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	local Selected = Players[Passport]
	if Selected and Machines[Selected] then
		if Machines[Selected].Using == Passport then
			Machines[Selected].Using = false
		end

		if Machines[Selected].Winner then
			Machines[Selected].Winner = false
		end

		Players[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Payment(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Machines[Selected] and vRP.PaymentFull(Passport,Machines[Selected].Value) then
		return true
	end

	TriggerClientEvent("Notify",source,"Aviso","Dinheiro insuficiente.","amarelo",5000)

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTSLOTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.StartSlots(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Machines[Selected] then
		local Result = {
			A = math.random(16),
			B = math.random(16),
			C = math.random(16)
		}

		Machines[Selected].Winner = Result
		vCLIENT.MachineSlots(source,Result)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WINNER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Winner(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Machines[Selected] then
		Active[Passport] = true

		if Machines[Selected].Winner then
			local Valuation = 0
			local Spin01 = Images[Machines[Selected].Winner.A]
			local Spin02 = Images[Machines[Selected].Winner.B]
			local Spin03 = Images[Machines[Selected].Winner.C]

			if Spin01 == Spin02 and Spin01 == Spin03 then
				if Multiplier[Spin01] then
					Valuation = Machines[Selected].Value * Multiplier[Spin01]
				end
			elseif Spin01 == Spin02 or Spin02 == Spin03 or Spin01 == Spin03 then
				Valuation = Machines[Selected].Value * 2
			end

			if Valuation > 0 then
				vRP.GiveBank(Passport,Valuation,true)
			end

			Machines[Selected].Winner = false
		end

		Active[Passport] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("slotmachine:Machines",source,Machines)
end)