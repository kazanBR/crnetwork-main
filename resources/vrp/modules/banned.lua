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

	local IsBanned = Account.Banned and Account.Banned == -1
	vRP.Update("hwid/All",{ Account = Account.id, Banned = IsBanned and 1 or 0 })

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

	if not IsBanned and Return == "User" then
		Return = false
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
			TriggerClientEvent("Notify",source,ServerName,("Você foi punido <b>%d minutos</b> de reclusão."):format(Duration),"server",10000)
			Character.Banned = (Character.Banned or 0) + Duration
			Character.BannedTime = os.time()
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

	local Account = vRP.AccountOptimize(Passport)
	if not Account or Account.Banned == -1 then
		return false
	end

	local source = vRP.Source(Passport)
	local Character = source and Characters[source] or nil
	local CurrentTime = os.time()
	local Current = 0
	local BannedTime = nil
	local Updated = false

	if Character and type(Character.Banned) == "number" then
		if Character.Banned == -1 then
			return false
		elseif Character.Banned > 0 then
			Current = parseInt(Character.Banned)
			BannedTime = Character.BannedTime
		end
	end

	if Current <= 0 then
		Current = parseInt(Account.Banned or 0)
		if Current > 0 and Character then
			if not Character.BannedTime then
				Character.BannedTime = CurrentTime
			end
			Character.Banned = Current
			BannedTime = Character.BannedTime
		end
	end

	if Current <= 0 then
		return false
	end

	if not BannedTime then
		BannedTime = CurrentTime
		if Character then
			Character.BannedTime = BannedTime
		end
	end

	local ElapsedMinutes = math.floor((CurrentTime - BannedTime) / 60)
	local TotalReduce = ElapsedMinutes

	if Amount then
		TotalReduce = TotalReduce + parseInt(Amount)
	end

	if TotalReduce > 0 then
		vRP.Update("accounts/ReduceBanned",{ Account = Account.id, Amount = TotalReduce })
		Current = math.max(0,Current - TotalReduce)
		Updated = true

		if Character then
			Character.Banned = Current
			Character.BannedTime = CurrentTime
		end
	end

	if Current <= 0 then
		vRP.Update("hwid/All",{ Account = Account.id, Banned = 0 })
		vRP.Update("accounts/RemoveBanned",{ Account = Account.id })

		if Character then
			Character.Banned = 0
			Character.BannedTime = nil
		end

		if source then
			exports.vrp:Bucket(source,"Exit")
			Player(source).state.Banned = false
			vRP.Teleport(source,Banned.Leave.x,Banned.Leave.y,Banned.Leave.z)

			if Banned.Mute then
				TriggerClientEvent("pma-voice:Mute",source,false)
			end

			if Character and Character.Prison and Character.Prison > 0 then
				Player(source).state.Prison = true
			end
		end

		return true
	end

	if source then
		if Updated then
			TriggerClientEvent("Notify",source,ServerName,("Restam <b>%d minutos</b> até sua liberação."):format(Current),"default",5000)
		end

		if GetPlayerRoutingBucket(source) ~= Banned.Route then
			exports.vrp:Bucket(source,"Enter",Banned.Route)
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
	Character.BannedTime = nil
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