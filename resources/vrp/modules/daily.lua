-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEDAILY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateDaily(Passport,source,Daily)
	vRP.Update("characters/UpdateDaily",{ Passport = Passport, Daily = Daily })

	if Characters[source] then
		Characters[source].Daily = Daily
	end
end