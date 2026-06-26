-----------------------------------------------------------------------------------------------------------------------------------------
-- BANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Banned(source,Account)
	if not source or not Account then
		return false
	end

	local Return = false
	local Tokens = GetNumPlayerTokens(source)
	local Identities = GetPlayerIdentifiers(source)

	local function CheckAndInsert(Token)
		if not Token then
			return false
		end

		local Consult = vRP.SingleQuery("hwid/Check",{ Token = Token })
		if not Consult then
			vRP.Query("hwid/Insert",{ Token = Token, Account = Account.id })
			return false
		end

		if Consult.Banned then
			if Consult.Account == Account.id then
				Return = Return or "User"
			else
				vRP.Query("hwid/Insert",{ Token = Token, Account = Account.id })
				Return = Return or { "Other",Consult.Account }
			end
		end
	end

	for _,Token in ipairs(Identities) do
		CheckAndInsert(Token)
	end

	for Number = 0,Tokens - 1 do
		CheckAndInsert(GetPlayerToken(source,Number))
	end

	if Account.Banned == -1 or Account.Banned > 0 then
		vRP.Update("hwid/All",{ Account = Account.id, Banned = 1 })
		Return = Return or "User"
	else
		vRP.Update("hwid/All",{ Account = Account.id, Banned = 0 })

		if Return == "User" then
			Return = false
		end
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetBanned(Passport,Amount,Reason,Admin)
	if not Passport or not Reason then
		return false
	end

	local Account = vRP.AccountOptimize(Passport)
	if not Account then
		return false
	end

	local Duration = parseInt(Amount)
	local IsPermanente = Duration <= 0
	local source = vRP.Source(Passport)
	local Mode = IsPermanente and "Permanente" or "Minutos"

	if IsPermanente then
		vRP.Update("hwid/All",{ Account = Account.id, Banned = 1 })
		vRP.Update("accounts/BannedPermanent",{ Account = Account.id, Reason = Reason })

		if source then
			vRP.Kick(source,"Consequência: Banido\nTempo: Permanente\nMotivo: "..Reason)
		end
	else
		vRP.Update("accounts/InsertBanned",{ Account = Account.id, Amount = Duration, Reason = Reason })

		local Character = source and Characters[source]
		if Character then
			TriggerClientEvent("Notify",source,ServerName,("Você foi punido <b>%d minutos</b> de reclusão."):format(Duration),"default",10000)
			Character.Banned = (Character.Banned or 0) + Duration
			TriggerClientEvent("radio:Disconnect",source)
			vRP.LeaveServiceBanned(Passport,source)
			Player(source).state.Banned = true

			if Banned.Mute then
				TriggerClientEvent("pma-voice:Mute",source,true)
			end

			if GetPlayerRoutingBucket(source) ~= Banned.Route then
				exports.vrp:Bucket(source,"Enter",Banned.Route)
			end
		end
	end

	if Admin then
		exports.discord:Embed("Ban",("**[ADMIN]:** %s\n**[PASSAPORTE]:** %s\n**[MODO]:** %s\n**[TEMPO]:** %d\n**[MOTIVO]:** %s\n**[DISCORD]:** <@%s>"):format(Admin,Passport,Mode,Duration,Reason,Account.Discord or "Desconhecido"))
	else
		exports.discord:Embed("Ban",("**[PASSAPORTE]:** %s\n**[MODO]:** %s\n**[TEMPO]:** %d\n**[MOTIVO]:** %s\n**[DISCORD]:** <@%s>"):format(Passport,Mode,Duration,Reason,Account.Discord or "Desconhecido"))
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateBanned(Passport,Amount)
	if not Passport then
		return false
	end

	local Reduce = parseInt(Amount,true)
	local Account = vRP.AccountOptimize(Passport)
	if not Account then
		return false
	end

	local source = vRP.Source(Passport)
	local Character = source and Characters[source] or Account
	if (Character.Banned or 0) <= 0 then
		return false
	end

	vRP.Update("accounts/ReduceBanned",{ Account = Account.id, Amount = Reduce })
	Character.Banned = Character.Banned - Reduce

	if Character.Banned <= 0 then
		vRP.Update("hwid/All",{ Account = Account.id, Banned = 0 })
		Character.Banned = 0

		if source then
			exports.vrp:Bucket(source,"Exit")
			Player(source).state.Banned = false
			vRP.Teleport(source,Banned.Leave.x,Banned.Leave.y,Banned.Leave.z)

			if Banned.Mute then
				TriggerClientEvent("pma-voice:Mute",source,false)
			end

			if Character.Prison and Character.Prison > 0 then
				Player(source).state.Prison = true
			end
		end
	else
		if source then
			TriggerClientEvent("Notify",source,ServerName,("Restam <b>%d minutos</b> até sua liberação."):format(Character.Banned),"default",5000)

			if GetPlayerRoutingBucket(source) ~= Banned.Route then
				exports.vrp:Bucket(source,"Enter",Banned.Route)
			end
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveBanned(Passport)
	if not Passport then
		return false
	end

	local Account = vRP.AccountInformation(Passport,"id")
	if not Account then
		return false
	end

	vRP.Update("hwid/All",{ Account = Account, Banned = 0 })
	vRP.Update("accounts/RemoveBanned",{ Account = Account })

	local source = vRP.Source(Passport)
	local Character = source and Characters[source]
	if not Character then
		return false
	end

	Character.Banned = 0
	exports.vrp:Bucket(source,"Exit")
	Player(source).state.Banned = false
	vRP.Teleport(source,Banned.Leave.x,Banned.Leave.y,Banned.Leave.z)

	if Banned.Mute then
		TriggerClientEvent("pma-voice:Mute",source,false)
	end

	if Character.Prison > 0 then
		Player(source).state.Prison = true
	end
end