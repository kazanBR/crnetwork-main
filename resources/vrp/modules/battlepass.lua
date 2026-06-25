-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Default = { Free = 0, Premium = 0, Points = 0, Active = false }
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETBATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetBattlepass(Passport)
	local Consult = vRP.SimpleData(Passport,"Battlepass")

	if type(Consult) ~= "table" then
		Consult = table.clone(Default)
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Battlepass", Information = json.encode(Consult) })

		return Consult
	end

	for Index,v in pairs(Default) do
		if Consult[Index] == nil then
			Consult[Index] = v
		end
	end

	return Consult
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVEBATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
local function SaveBattlepass(Passport,Data)
	vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Battlepass", Information = json.encode(Data) })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Battlepass(Passport)
	return GetBattlepass(Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.BattlepassBuy(Passport)
	local Consult = GetBattlepass(Passport)

	Consult.Active = true
	SaveBattlepass(Passport,Consult)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSPAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.BattlepassPayment(Passport,Mode,Amount)
	local Consult = GetBattlepass(Passport)

	if Consult.Points < Amount then
		return false
	end

	if Mode == "Free" then
		Consult.Free = Consult.Free + 1
	elseif Mode == "Premium" then
		Consult.Premium = Consult.Premium + 1
	end

	Consult.Points = Consult.Points - Amount
	SaveBattlepass(Passport,Consult)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSPOINTS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.BattlepassPoints(Passport,Amount)
	if Amount <= 0 then
		return false
	end

	local Consult = GetBattlepass(Passport)

	Consult.Points = Consult.Points + Amount
	SaveBattlepass(Passport,Consult)

	local Source = vRP.Source(Passport)
	if Source then
		TriggerClientEvent("hud:DisplayExperience",Source,"Battlepass",Amount)
	end
end