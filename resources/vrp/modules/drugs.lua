-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Weed = {}
local Alcohol = {}
local Chemical = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEEDRETURN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WeedReturn(Passport)
	local CurrentTime = os.time()
	local ExpirationTime = Weed[Passport]

	if ExpirationTime and CurrentTime < ExpirationTime then
		return parseInt(ExpirationTime - CurrentTime)
	end

	Weed[Passport] = nil

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEEDTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WeedTimer(Passport,Timer)
	Weed[Passport] = (Weed[Passport] or os.time()) + (Timer * 60)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEMICALRETURN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ChemicalReturn(Passport)
	local CurrentTime = os.time()
	local ExpirationTime = Chemical[Passport]

	if ExpirationTime and CurrentTime < ExpirationTime then
		return parseInt(ExpirationTime - CurrentTime)
	end

	Chemical[Passport] = nil

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEMICALTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ChemicalTimer(Passport,Timer)
	Chemical[Passport] = (Chemical[Passport] or os.time()) + (Timer * 60)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ALCOHOLRETURN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AlcoholReturn(Passport)
	local CurrentTime = os.time()
	local ExpirationTime = Alcohol[Passport]

	if ExpirationTime and CurrentTime < ExpirationTime then
		return parseInt(ExpirationTime - CurrentTime)
	end

	Alcohol[Passport] = nil

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEMICALTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AlcoholTimer(Passport,Timer)
	Alcohol[Passport] = (Alcohol[Passport] or os.time()) + (Timer * 60)
end