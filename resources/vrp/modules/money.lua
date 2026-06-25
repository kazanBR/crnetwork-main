-----------------------------------------------------------------------------------------------------------------------------------------
-- SANITIZE
-----------------------------------------------------------------------------------------------------------------------------------------
local function Sanitize(Passport,Amount)
	return parseInt(Passport),parseInt(Amount)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VALIDAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
local function ValidAmount(Amount)
	return Amount and Amount > 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetCharacter(source)
	return source and Characters[source]
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GIVEBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GiveBank(Passport,Amount,Notify)
	Passport,Amount = Sanitize(Passport,Amount)
	if not ValidAmount(Amount) then
		return false
	end

	vRP.Update("characters/AddBank",{ Passport = Passport, Bank = Amount })
	exports.discord:Embed("Bank",("**[PASSAPORTE]:** %d\n**[VALOR]:** %d\n**[MODO]:** GiveBank"):format(Passport,Amount))

	local source = vRP.Source(Passport)
	local ValidCharacter = GetCharacter(source)
	if not ValidCharacter then
		return true
	end

	ValidCharacter.Bank = ValidCharacter.Bank + Amount

	if Notify then
		TriggerClientEvent("inventory:NotifyItem",source,{ Index = "dollar", Amount = Amount })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveBank(Passport,Amount)
	Passport,Amount = Sanitize(Passport,Amount)
	if not ValidAmount(Amount) then
		return false
	end

	vRP.Update("characters/RemBank",{ Passport = Passport, Bank = Amount })
	exports.discord:Embed("Bank",("**[PASSAPORTE]:** %d\n**[VALOR]:** %d\n**[MODO]:** RemoveBank"):format(Passport,Amount))

	local source = vRP.Source(Passport)
	local ValidCharacter = source and GetCharacter(source)
	if not ValidCharacter then
		return true
	end

	ValidCharacter.Bank = math.max(ValidCharacter.Bank - Amount,0)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetBank(Passport)
	Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)
	return Identity and Identity.Bank or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTGEMS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PaymentGems(Passport,Amount)
	Passport,Amount = Sanitize(Passport,Amount)
	if not ValidAmount(Amount) then
		return false
	end

	local source = vRP.Source(Passport)
	local ValidCharacter = GetCharacter(source)
	if not ValidCharacter then
		return false
	end

	local License = ValidCharacter.License
	local Gemstone = vRP.UserGemstone(License)
	if parseInt(Gemstone) < Amount then
		return false
	end

	vRP.Update("accounts/RemoveGemstone",{ License = License, Gemstone = Amount })
	TriggerClientEvent("hud:RemoveGemstone",source,Amount)

	return true
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PaymentBank(Passport,Amount,Notify)
	Passport,Amount = Sanitize(Passport,Amount)
	if not ValidAmount(Amount) then
		return false
	end

	local source = vRP.Source(Passport)
	local ValidCharacter = GetCharacter(source)
	if not ValidCharacter or ValidCharacter.Bank < Amount then
		return false
	end

	vRP.RemoveBank(Passport,Amount,source)

	if Notify then
		TriggerClientEvent("inventory:NotifyItem",source,{ Index = "dollar", Amount = -Amount })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTFULL
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PaymentFull(Passport,Amount,Notify)
	Passport,Amount = Sanitize(Passport,Amount)
	if not ValidAmount(Amount) then
		return false
	end

	return vRP.TakeItem(Passport,"dollar",Amount,Notify) or vRP.PaymentBank(Passport,Amount,Notify)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WITHDRAWCASH
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WithdrawCash(Passport,Amount)
	Passport,Amount = Sanitize(Passport,Amount)
	if not ValidAmount(Amount) then
		return false
	end

	local source = vRP.Source(Passport)
	local ValidCharacter = GetCharacter(source)
	if not ValidCharacter or ValidCharacter.Bank < Amount then
		return false
	end

	vRP.GenerateItem(Passport,"dollar",Amount,true)
	vRP.RemoveBank(Passport,Amount,source)

	return true
end