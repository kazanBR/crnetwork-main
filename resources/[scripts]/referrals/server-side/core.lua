-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("referrals",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Check()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if vRP.AccountInformation(Passport,"Referral") then
		TriggerEvent("PollCreative",Passport,source)
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIRM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Confirm(Origin,Code)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Account = vRP.AccountOptimize(Passport)
	if Account.Referral then
		return false
	end

	exports.oxmysql:update_async("UPDATE accounts SET Referral = ? WHERE id = ?",{ Origin,Account.id })
	exports.discord:Embed("Referral",("**[PASSAPORTE]:** %s\n**[REFERÊNCIA]:** %s\n**[CÓDIGO]:** %s"):format(Passport,Origin,Code))
	TriggerClientEvent("Notify",source,ServerName,"Seja bem-vindo(a) à nossa comunidade, Sua referência foi devidamente registrada em nosso banco de dados e caso o código informado seja validado, sua recompensa estará com você.","default",30000,"bottom-center")

	local Rewards = Codes[Code]
	if Rewards then
		for Item,Amount in pairs(Rewards) do
			local Split = splitString(Item,":")
			if Split[1] == "Vehicle" then
				local Model = Split[2]
				local Vehicle = vRP.SelectVehicle(Passport,Model)

				if not Vehicle then
					exports.oxmysql:query_async("INSERT IGNORE INTO vehicles (Passport,Vehicle,Plate,Weight,Work,Rental,Tax) VALUES (@Passport,@Vehicle,@Plate,@Weight,@Work,UNIX_TIMESTAMP() + (86400 * @Days),UNIX_TIMESTAMP() + (86400 * @Days))",{ Passport = Passport, Vehicle = Model, Plate = vRP.GeneratePlate(), Days = Amount, Weight = exports.vrp:VehicleWeight(Model), Work = 0 })
				elseif Vehicle.Rental > os.time() then
					exports.oxmysql:update_async("UPDATE vehicles SET Rental = Rental + (86400 * @Days) WHERE Passport = @Passport AND Vehicle = @Vehicle",{ Passport = Passport, Vehicle = Model, Days = Amount })
				else
					exports.oxmysql:update_async("UPDATE vehicles SET Rental = UNIX_TIMESTAMP() + (86400 * @Days) WHERE Passport = @Passport AND Vehicle = @Vehicle",{ Passport = Passport, Vehicle = Model, Days = Amount })
				end

				TriggerClientEvent("Notify",source,"Sucesso","Veículo <b>"..exports.vrp:VehicleName(Model).."</b> recebido.","verde",5000)
			else
				vRP.GenerateItem(Passport,Item,Amount,true)
			end
		end
	end

	TriggerEvent("PollCreative",Passport,source)

	return true
end