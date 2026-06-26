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
Tunnel.bindInterface("admin",Creative)
vKEYBOARD = Tunnel.getInterface("keyboard")
vSKINWEAPON = Tunnel.getInterface("skinweapon")
vCLIENT = Tunnel.getInterface("admin")
vHUD = Tunnel.getInterface("hud")
-----------------------------------------------------------------------------------------------------------------------------------------
-- POLLCREATIVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("PollCreative",function(Passport,source)
	local Code = "NEW"
	local Consult = exports.oxmysql:single_async("SELECT 1 FROM poll_creative WHERE Code = ? AND Passport = ? LIMIT 1",{ Code,Passport })
	if Consult then
		return false
	end

	local Question = ""
	local Keyboard = vKEYBOARD.Instagram(source,{ "Teste 01","Teste 02","Teste 03" },"Enquete",Question)
	if not Keyboard then
		return false
	end

	local Answer = Keyboard[1]
	if not Answer or Answer == "" then
		TriggerClientEvent("Notify",source,"Enquete","Resposta inválida.","vermelho",5000)
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO poll_creative (Question,Code,Passport,Answer) VALUES (?,?,?,?)",{ Question,Code,Passport,Answer })
	TriggerClientEvent("Notify",source,"Enquete","Resposta enviada com sucesso.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENQUETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("enquete",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Codes = exports.oxmysql:query_async("SELECT DISTINCT Code FROM poll_creative ORDER BY Code ASC")
	if not Codes or #Codes <= 0 then
		TriggerClientEvent("Notify",source,"Enquete","Nenhuma enquete encontrada.","amarelo",5000)
		return false
	end

	local Options = {}
	for _,v in pairs(Codes) do
		Options[#Options + 1] = "["..v.Code.."] Ver resultado"
	end

	local Keyboard = vKEYBOARD.Instagram(source,Options)
	if not Keyboard then
		return false
	end

	local Selected = Keyboard[1]
	if not Selected then
		return false
	end

	local Code = Selected:match("%[(.-)%]")
	local Consult = exports.oxmysql:query_async("SELECT Answer,COUNT(*) as Total FROM poll_creative WHERE Code = ? GROUP BY Answer ORDER BY Total DESC",{ Code })
	if not Consult or #Consult <= 0 then
		TriggerClientEvent("Notify",source,"Enquete","Nenhuma resposta encontrada.","amarelo",5000)
		return false
	end

	local TotalVotes = 0
	for _,v in pairs(Consult) do
		TotalVotes = TotalVotes + v.Total
	end

	local Message = ""
	for _,v in pairs(Consult) do
		local Percent = math.floor((v.Total / TotalVotes) * 100)
		Message = Message..v.Answer.." - "..v.Total.." voto(s)".." ("..Percent.."%)<br>"
	end

	TriggerClientEvent("Notify",source,"Enquete: "..Code,Message,"verde",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSAPORTE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("passaporte",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport then
		local Allowed = {}
		local Consult = exports.oxmysql:query_async("SELECT n.id AS missing_id FROM (SELECT n1.n + n10.n * 10 + n100.n * 100 + 1 AS id FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) n1, (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) n10, (SELECT 0 AS n UNION ALL SELECT 1) n100) n LEFT JOIN characters c ON c.id = n.id WHERE n.id BETWEEN 1 AND 200 AND c.id IS NULL ORDER BY n.id")
		for _,v in ipairs(Consult) do
			Allowed[#Allowed + 1] = tostring(v.missing_id)
		end

		local Keyboard = vKEYBOARD.Instagram(source,Allowed)
		if Keyboard then
			local Price = 20000
			local OtherPassport = Passport
			local NewPassport = parseInt(Keyboard[1])

			if not vRP.Request(source,"Deseja efetuar o número do passaporte para <b>"..NewPassport.."</b>? A mudança tem o custo de <b>"..Dotted(Price).." Diamantes</b>.") then
				return false
			end

			if not vRP.PaymentGems(Passport,Price) then
				TriggerClientEvent("Notify",source,"Aviso","Diamantes insuficientes.","amarelo",5000)
				return false
			end

			if vRP.Identity(NewPassport) then
				TriggerClientEvent("Notify",source,"Aviso","Passaporte escolhido já existe.","amarelo",5000)
				return false
			end

			vRP.Kick(source,"Desconectado para mudança de passaporte, aguarde 60 segundos e tente conectar novamente.")

			while vRP.Source(Passport) do
				Wait(100)
			end

			local Vehicles = exports.oxmysql:query_async("SELECT * FROM vehicles WHERE Passport = ?",{ OtherPassport })
			if Vehicles and #Vehicles > 0 then
				for _,v in pairs(Vehicles) do
					local LsCustoms = vRP.GetSrvData("LsCustoms:"..OtherPassport..":"..v.Vehicle,true)
					local Trunkchest = vRP.GetSrvData("Trunkchest:"..OtherPassport..":"..v.Vehicle,true)

					vRP.SetSrvData("Trunkchest:"..NewPassport..":"..v.Vehicle,Trunkchest,true)
					vRP.SetSrvData("LsCustoms:"..NewPassport..":"..v.Vehicle,LsCustoms,true)
					vRP.RemSrvData("Trunkchest:"..OtherPassport..":"..v.Vehicle)
					vRP.RemSrvData("LsCustoms:"..OtherPassport..":"..v.Vehicle)
				end

				exports.oxmysql:update_async("UPDATE vehicles SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local NewEntitydata = "Personal:"..NewPassport
			local ActualEntitydata = "Personal:"..OtherPassport
			local Entitydata = exports.oxmysql:query_async("SELECT * FROM entitydata WHERE Name = ?",{ ActualEntitydata })
			if Entitydata and #Entitydata > 0 then
				exports.oxmysql:update_async("UPDATE entitydata SET Name = ? WHERE Name = ?",{ NewEntitydata,ActualEntitydata })
			end

			local Character = exports.oxmysql:query_async("SELECT * FROM characters WHERE id = ?",{ OtherPassport })
			if Character and #Character > 0 then
				exports.oxmysql:update_async("UPDATE characters SET id = ? WHERE id = ?",{ NewPassport,OtherPassport })
			end

			local Transactions = exports.oxmysql:query_async("SELECT * FROM transactions WHERE Passport = ?",{ OtherPassport })
			if Transactions and #Transactions > 0 then
				exports.oxmysql:update_async("UPDATE transactions SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Taxs = exports.oxmysql:query_async("SELECT * FROM taxes WHERE Passport = ?",{ OtherPassport })
			if Taxs and #Taxs > 0 then
				exports.oxmysql:update_async("UPDATE taxes SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Races = exports.oxmysql:query_async("SELECT * FROM races WHERE Passport = ?",{ OtherPassport })
			if Races and #Races > 0 then
				exports.oxmysql:update_async("UPDATE races SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Propertys = exports.oxmysql:query_async("SELECT * FROM propertys WHERE Passport = ?",{ OtherPassport })
			if Propertys and #Propertys > 0 then
				exports.oxmysql:update_async("UPDATE propertys SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Playerdata = exports.oxmysql:query_async("SELECT * FROM playerdata WHERE Passport = ?",{ OtherPassport })
			if Playerdata and #Playerdata > 0 then
				exports.oxmysql:update_async("UPDATE playerdata SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Painel_Transactions = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Passport = ?",{ OtherPassport })
			if Painel_Transactions and #Painel_Transactions > 0 then
				exports.oxmysql:update_async("UPDATE painel_creative_transactions SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Painel_Transactions_Transfer = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Transfer = ?",{ OtherPassport })
			if Painel_Transactions_Transfer and #Painel_Transactions_Transfer > 0 then
				exports.oxmysql:update_async("UPDATE painel_creative_transactions SET Transfer = ? WHERE Transfer = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Arrest = exports.oxmysql:query_async("SELECT * FROM mdt_creative_arrest WHERE Passport = ?",{ OtherPassport })
			if MDT_Arrest and #MDT_Arrest > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_arrest SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Arrest_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_arrest WHERE Officer = ?",{ OtherPassport })
			if MDT_Arrest_Officer and #MDT_Arrest_Officer > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_arrest SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Fines = exports.oxmysql:query_async("SELECT * FROM mdt_creative_fines WHERE Passport = ?",{ OtherPassport })
			if MDT_Fines and #MDT_Fines > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_fines SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Fines_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_fines WHERE Officer = ?",{ OtherPassport })
			if MDT_Fines_Officer and #MDT_Fines_Officer > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_fines SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Medals_Officers = exports.oxmysql:query_async("SELECT * FROM mdt_creative_medals")
			if MDT_Medals_Officers and #MDT_Medals_Officers > 0 then
				for _,v in pairs(MDT_Medals_Officers) do
					local Updated = false
					local Officers = json.decode(v.Officers)
					for Index,Number in pairs(Officers) do
						if OtherPassport == Number then
							Officers[Index] = NewPassport
							Updated = true

							break
						end
					end

					if Updated then
						exports.oxmysql:update_async("UPDATE mdt_creative_medals SET Officers = ? WHERE id = ?",{ json.encode(Officers),v.id })
					end
				end
			end

			local MDT_Reports = exports.oxmysql:query_async("SELECT * FROM mdt_creative_reports WHERE Passport = ?",{ OtherPassport })
			if MDT_Reports and #MDT_Reports > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_reports SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Reports_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_reports WHERE Officer = ?",{ OtherPassport })
			if MDT_Reports_Officer and #MDT_Reports_Officer > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_reports SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Units_Officers = exports.oxmysql:query_async("SELECT * FROM mdt_creative_units")
			if MDT_Units_Officers and #MDT_Units_Officers > 0 then
				for _,v in pairs(MDT_Units_Officers) do
					local Updated = false
					local Officers = json.decode(v.Officers)
					for Index,Number in pairs(Officers) do
						if OtherPassport == Number then
							Officers[Index] = NewPassport
							Updated = true

							break
						end
					end

					if Updated then
						exports.oxmysql:update_async("UPDATE mdt_creative_units SET Officers = ? WHERE id = ?",{ json.encode(Officers),v.id })
					end
				end
			end

			local MDT_Vehicles = exports.oxmysql:query_async("SELECT * FROM mdt_creative_vehicles WHERE Passport = ?",{ OtherPassport })
			if MDT_Vehicles and #MDT_Vehicles > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_vehicles SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Vehicles_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_vehicles WHERE Officer = ?",{ OtherPassport })
			if MDT_Vehicles_Officer and #MDT_Vehicles_Officer > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_vehicles SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Wanted = exports.oxmysql:query_async("SELECT * FROM mdt_creative_wanted WHERE Passport = ?",{ OtherPassport })
			if MDT_Wanted and #MDT_Wanted > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_wanted SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Wanted_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_wanted WHERE Officer = ?",{ OtherPassport })
			if MDT_Wanted_Officer and #MDT_Wanted_Officer > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_wanted SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Warning = exports.oxmysql:query_async("SELECT * FROM mdt_creative_warning WHERE Passport = ?",{ OtherPassport })
			if MDT_Warning and #MDT_Warning > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_warning SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local MDT_Warning_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_warning WHERE Officer = ?",{ OtherPassport })
			if MDT_Warning_Officer and #MDT_Warning_Officer > 0 then
				exports.oxmysql:update_async("UPDATE mdt_creative_warning SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
			end

			local Invoices = exports.oxmysql:query_async("SELECT * FROM invoices WHERE Passport = ?",{ OtherPassport })
			if Invoices and #Invoices > 0 then
				exports.oxmysql:update_async("UPDATE invoices SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
			end

			local Invoices_Received = exports.oxmysql:query_async("SELECT * FROM invoices WHERE Received = ?",{ OtherPassport })
			if Invoices_Received and #Invoices_Received > 0 then
				exports.oxmysql:update_async("UPDATE invoices SET Received = ? WHERE Received = ?",{ NewPassport,OtherPassport })
			end

			local Phone = exports.oxmysql:query_async("SELECT * FROM phone_phones WHERE owner_id = ?",{ OtherPassport })
			if Phone and #Phone > 0 then
				exports.oxmysql:update_async("UPDATE phone_phones SET owner_id = ?, id = ? WHERE owner_id = ?",{ NewPassport,NewPassport,OtherPassport })
			end

			local Permissions = vRP.UserGroups(OtherPassport)
			for Permission,Level in pairs(Permissions) do
				vRP.RemovePermission(OtherPassport,Permission)
				vRP.SetPermission(NewPassport,Permission,Level)
			end

			exports.oxmysql:update_async("UPDATE tickets_creative SET Author = ? WHERE Author = ?",{ NewPassport,OtherPassport })
			exports.oxmysql:update_async("UPDATE tickets_creative SET Assumed = ? WHERE Assumed = ?",{ NewPassport,OtherPassport })
			exports.oxmysql:update_async("UPDATE tickets_creative_messages SET Staff = ? WHERE Staff = ?",{ NewPassport,OtherPassport })
			exports.oxmysql:update_async("UPDATE tickets_creative_messages SET Author = ? WHERE Author = ?",{ NewPassport,OtherPassport })

			exports.crons:Swap(OtherPassport,NewPassport)
			exports.moneywash:UpdateObjects(OtherPassport,NewPassport)
			exports.inventory:UpdateObjects(OtherPassport,NewPassport)

			local Playing = vRP.GetSrvData("Playing:"..OtherPassport,true)
			vRP.SetSrvData("Playing:"..NewPassport,Playing,true)
			vRP.RemSrvData("Playing:"..OtherPassport)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("passport",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",1) then
		local Keyboard = vKEYBOARD.Secondary(source,"Atual","Novo")
		if Keyboard then
			local NewPassport = parseInt(Keyboard[2])
			local OtherPassport = parseInt(Keyboard[1])
			if NewPassport > 0 and OtherPassport > 0 then
				if vRP.Source(OtherPassport) then
					return TriggerClientEvent("Notify",source,"Atenção","O passaporte "..OtherPassport.." precisa estar desconectado.","amarelo",5000)
				end

				if not vRP.Identity(OtherPassport) then
					return TriggerClientEvent("Notify",source,"Atenção","O passaporte "..OtherPassport.." não existe.","amarelo",5000)
				end

				if vRP.Identity(NewPassport) then
					return TriggerClientEvent("Notify",source,"Atenção","O passaporte "..NewPassport.." já existe.","amarelo",5000)
				end

				local Vehicles = exports.oxmysql:query_async("SELECT * FROM vehicles WHERE Passport = ?",{ OtherPassport })
				if Vehicles and #Vehicles > 0 then
					for _,v in pairs(Vehicles) do
						local LsCustoms = vRP.GetSrvData("LsCustoms:"..OtherPassport..":"..v.Vehicle,true)
						local Trunkchest = vRP.GetSrvData("Trunkchest:"..OtherPassport..":"..v.Vehicle,true)

						vRP.SetSrvData("Trunkchest:"..NewPassport..":"..v.Vehicle,Trunkchest,true)
						vRP.SetSrvData("LsCustoms:"..NewPassport..":"..v.Vehicle,LsCustoms,true)
						vRP.RemSrvData("Trunkchest:"..OtherPassport..":"..v.Vehicle)
						vRP.RemSrvData("LsCustoms:"..OtherPassport..":"..v.Vehicle)
					end

					exports.oxmysql:update_async("UPDATE vehicles SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local NewEntitydata = "Personal:"..NewPassport
				local ActualEntitydata = "Personal:"..OtherPassport
				local Entitydata = exports.oxmysql:query_async("SELECT * FROM entitydata WHERE Name = ?",{ ActualEntitydata })
				if Entitydata and #Entitydata > 0 then
					exports.oxmysql:update_async("UPDATE entitydata SET Name = ? WHERE Name = ?",{ NewEntitydata,ActualEntitydata })
				end

				local Character = exports.oxmysql:query_async("SELECT * FROM characters WHERE id = ?",{ OtherPassport })
				if Character and #Character > 0 then
					exports.oxmysql:update_async("UPDATE characters SET id = ? WHERE id = ?",{ NewPassport,OtherPassport })
				end

				local Transactions = exports.oxmysql:query_async("SELECT * FROM transactions WHERE Passport = ?",{ OtherPassport })
				if Transactions and #Transactions > 0 then
					exports.oxmysql:update_async("UPDATE transactions SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Taxs = exports.oxmysql:query_async("SELECT * FROM taxes WHERE Passport = ?",{ OtherPassport })
				if Taxs and #Taxs > 0 then
					exports.oxmysql:update_async("UPDATE taxes SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Races = exports.oxmysql:query_async("SELECT * FROM races WHERE Passport = ?",{ OtherPassport })
				if Races and #Races > 0 then
					exports.oxmysql:update_async("UPDATE races SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Propertys = exports.oxmysql:query_async("SELECT * FROM propertys WHERE Passport = ?",{ OtherPassport })
				if Propertys and #Propertys > 0 then
					exports.oxmysql:update_async("UPDATE propertys SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Playerdata = exports.oxmysql:query_async("SELECT * FROM playerdata WHERE Passport = ?",{ OtherPassport })
				if Playerdata and #Playerdata > 0 then
					exports.oxmysql:update_async("UPDATE playerdata SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Painel_Transactions = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Passport = ?",{ OtherPassport })
				if Painel_Transactions and #Painel_Transactions > 0 then
					exports.oxmysql:update_async("UPDATE painel_creative_transactions SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Painel_Transactions_Transfer = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Transfer = ?",{ OtherPassport })
				if Painel_Transactions_Transfer and #Painel_Transactions_Transfer > 0 then
					exports.oxmysql:update_async("UPDATE painel_creative_transactions SET Transfer = ? WHERE Transfer = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Arrest = exports.oxmysql:query_async("SELECT * FROM mdt_creative_arrest WHERE Passport = ?",{ OtherPassport })
				if MDT_Arrest and #MDT_Arrest > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_arrest SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Arrest_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_arrest WHERE Officer = ?",{ OtherPassport })
				if MDT_Arrest_Officer and #MDT_Arrest_Officer > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_arrest SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Fines = exports.oxmysql:query_async("SELECT * FROM mdt_creative_fines WHERE Passport = ?",{ OtherPassport })
				if MDT_Fines and #MDT_Fines > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_fines SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Fines_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_fines WHERE Officer = ?",{ OtherPassport })
				if MDT_Fines_Officer and #MDT_Fines_Officer > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_fines SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Medals_Officers = exports.oxmysql:query_async("SELECT * FROM mdt_creative_medals")
				if MDT_Medals_Officers and #MDT_Medals_Officers > 0 then
					for _,v in pairs(MDT_Medals_Officers) do
						local Updated = false
						local Officers = json.decode(v.Officers)
						for Index,Number in pairs(Officers) do
							if OtherPassport == Number then
								Officers[Index] = NewPassport
								Updated = true

								break
							end
						end

						if Updated then
							exports.oxmysql:update_async("UPDATE mdt_creative_medals SET Officers = ? WHERE id = ?",{ json.encode(Officers),v.id })
						end
					end
				end

				local MDT_Reports = exports.oxmysql:query_async("SELECT * FROM mdt_creative_reports WHERE Passport = ?",{ OtherPassport })
				if MDT_Reports and #MDT_Reports > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_reports SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Reports_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_reports WHERE Officer = ?",{ OtherPassport })
				if MDT_Reports_Officer and #MDT_Reports_Officer > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_reports SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Units_Officers = exports.oxmysql:query_async("SELECT * FROM mdt_creative_units")
				if MDT_Units_Officers and #MDT_Units_Officers > 0 then
					for _,v in pairs(MDT_Units_Officers) do
						local Updated = false
						local Officers = json.decode(v.Officers)
						for Index,Number in pairs(Officers) do
							if OtherPassport == Number then
								Officers[Index] = NewPassport
								Updated = true

								break
							end
						end

						if Updated then
							exports.oxmysql:update_async("UPDATE mdt_creative_units SET Officers = ? WHERE id = ?",{ json.encode(Officers),v.id })
						end
					end
				end

				local MDT_Vehicles = exports.oxmysql:query_async("SELECT * FROM mdt_creative_vehicles WHERE Passport = ?",{ OtherPassport })
				if MDT_Vehicles and #MDT_Vehicles > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_vehicles SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Vehicles_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_vehicles WHERE Officer = ?",{ OtherPassport })
				if MDT_Vehicles_Officer and #MDT_Vehicles_Officer > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_vehicles SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Wanted = exports.oxmysql:query_async("SELECT * FROM mdt_creative_wanted WHERE Passport = ?",{ OtherPassport })
				if MDT_Wanted and #MDT_Wanted > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_wanted SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Wanted_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_wanted WHERE Officer = ?",{ OtherPassport })
				if MDT_Wanted_Officer and #MDT_Wanted_Officer > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_wanted SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Warning = exports.oxmysql:query_async("SELECT * FROM mdt_creative_warning WHERE Passport = ?",{ OtherPassport })
				if MDT_Warning and #MDT_Warning > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_warning SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local MDT_Warning_Officer = exports.oxmysql:query_async("SELECT * FROM mdt_creative_warning WHERE Officer = ?",{ OtherPassport })
				if MDT_Warning_Officer and #MDT_Warning_Officer > 0 then
					exports.oxmysql:update_async("UPDATE mdt_creative_warning SET Officer = ? WHERE Officer = ?",{ NewPassport,OtherPassport })
				end

				local Invoices = exports.oxmysql:query_async("SELECT * FROM invoices WHERE Passport = ?",{ OtherPassport })
				if Invoices and #Invoices > 0 then
					exports.oxmysql:update_async("UPDATE invoices SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
				end

				local Invoices_Received = exports.oxmysql:query_async("SELECT * FROM invoices WHERE Received = ?",{ OtherPassport })
				if Invoices_Received and #Invoices_Received > 0 then
					exports.oxmysql:update_async("UPDATE invoices SET Received = ? WHERE Received = ?",{ NewPassport,OtherPassport })
				end

				local Phone = exports.oxmysql:query_async("SELECT * FROM phone_phones WHERE owner_id = ?",{ OtherPassport })
				if Phone and #Phone > 0 then
					exports.oxmysql:update_async("UPDATE phone_phones SET owner_id = ?, id = ? WHERE owner_id = ?",{ NewPassport,NewPassport,OtherPassport })
				end

				local Permissions = vRP.UserGroups(OtherPassport)
				for Permission,Level in pairs(Permissions) do
					vRP.RemovePermission(OtherPassport,Permission)
					vRP.SetPermission(NewPassport,Permission,Level)
				end

				exports.crons:Swap(OtherPassport,NewPassport)
				exports.moneywash:UpdateObjects(OtherPassport,NewPassport)
				exports.inventory:UpdateObjects(OtherPassport,NewPassport)

				local Playing = vRP.GetSrvData("Playing:"..OtherPassport,true)
				vRP.SetSrvData("Playing:"..NewPassport,Playing,true)
				vRP.RemSrvData("Playing:"..OtherPassport)

				TriggerClientEvent("Notify",source,"Sucesso","Atualização de passaporte concluída.","verde",5000)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("players",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Number = 0
		local Message = ""
		local Players = vRP.Players()
		local Amounts = CountTable(Players)
		for OtherPassport in pairs(Players) do
			Number = Number + 1
			Message = Message..OtherPassport..(Number < Amounts and ", " or "")
		end

		TriggerClientEvent("chat:ClientMessage",source,"JOGADORES CONECTADOS",Message,"OOC")
		TriggerClientEvent("Notify",source,"Listagem","<b>Jogadores Conectados:</b> "..GetNumPlayerIndices(),"verde",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLONE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("clone",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") and Message[1] and parseInt(Message[1]) > 0 then
		local OtherPassport = parseInt(Message[1])
		local Identity = vRP.Identity(OtherPassport)
		if Identity then
			vRPC.Skin(source,Identity.Skin)
			TriggerClientEvent("skinshop:Apply",source,vRP.UserData(OtherPassport,"Clothings"))
			TriggerClientEvent("barbershop:Apply",source,vRP.UserData(OtherPassport,"Barbershop"))
			TriggerClientEvent("tattooshop:Apply",source,vRP.UserData(OtherPassport,"Tattooshop"))

			TriggerClientEvent("Notify",source,"Clonagem","Alterações conclúidas.","verde",5000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PRINT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("print",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") and parseInt(Message[1]) > 0 then
		local OtherPassport = parseInt(Message[1])
		local OtherSource = vRP.Source(OtherPassport)
		local Webhook = exports.discord:Webhook("Print")
		if OtherPassport and OtherSource and Webhook ~= "" then
			TriggerClientEvent("megazord:Screenshot",OtherSource,Webhook)
		end
	end
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- POINTBATTLEPASS
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("pointbattlepass",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasPermission(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Quantidade")
	if not Keyboard then
		return false
	end

	local Amount = parseInt(Keyboard[2])
	local OtherPassport = parseInt(Keyboard[1])

	if OtherPassport <= 0 or not vRP.Identity(OtherPassport) then
		TriggerClientEvent("Notify",source,"Aviso","Passaporte inválido.","amarelo",5000)
		return false
	end

	if Amount <= 0 then
		TriggerClientEvent("Notify",source,"Aviso","Quantidade inválida.","amarelo",5000)
		return false
	end

	vRP.BattlepassPoints(OtherPassport,Amount)
	TriggerClientEvent("Notify",source,"Sucesso","Pontos enviados com sucesso.","verde",5000)
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- POINTEXPERIENCE
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("pointexperience",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasPermission(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Tertiary(source,"Passaporte","Trabalho","Quantidade")
	if not Keyboard then
		return false
	end

	local Work = Keyboard[2]
	local Amount = parseInt(Keyboard[3])
	local OtherPassport = parseInt(Keyboard[1])

	if OtherPassport <= 0 or not vRP.Identity(OtherPassport) then
		TriggerClientEvent("Notify",source,"Aviso","Passaporte inválido.","amarelo",5000)
		return false
	end

	if Amount <= 0 then
		TriggerClientEvent("Notify",source,"Aviso","Quantidade inválida.","amarelo",5000)
		return false
	end

	vRP.PutExperience(OtherPassport,Work,Amount)
	TriggerClientEvent("Notify",source,"Sucesso","Pontos enviados com sucesso.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CODES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("codes",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Codes(source,"Código","Usos","Recompensas")
	if Keyboard then
		local Code = Keyboard[1]
		local Max = parseInt(Keyboard[2])
		local Rewards = ConvertStringToTable(Keyboard[3])

		local ConsultCodes = exports.oxmysql:single_async("SELECT * FROM codes_creative WHERE Code = ? LIMIT 1",{ Code })
		if ConsultCodes then
			TriggerClientEvent("Notify",source,"Aviso","Código já existe.","amarelo",5000)
			return false
		end

		exports.oxmysql:insert_async("INSERT INTO codes_creative (Code,Rewards,Max,CreatedAt) VALUES (?,?,?,?)",{ Code,json.encode(Rewards),Max,os.time() })
		TriggerClientEvent("Notify",source,"Sucesso","Código criado.","verde",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WIPEBATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("wipebattlepass",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",1) then
		local CurrentTimer = os.time()

		vRP.Query("entitydata/SetData",{ Name = "Battlepass", Information = CurrentTimer })
		exports.oxmysql:query_async("DELETE FROM playerdata WHERE Name = ?",{ "Battlepass" })

		TriggerClientEvent("Notify",source,"Sucesso","Passe de batalha resetado.","verde",5000)
		TriggerEvent("pause:WipeBattlepass",CurrentTimer)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WIPEONLINE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("wipeonline",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",1) then
		vRP.WipePlaying()
		exports.oxmysql:query_async("DELETE FROM entitydata WHERE Name LIKE 'Playing:%'")
		TriggerClientEvent("Notify",source,"Sucesso","Tempo online resetado.","verde",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WIPEDAILY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("wipedaily",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",1) then
		exports.oxmysql:update_async("UPDATE characters SET Daily = ?",{ "09-01-1990-0" })
		TriggerClientEvent("Notify",source,"Sucesso","Daily resetado.","verde",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("skinshop",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("skinshop:Open",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("barbershop",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("barbershop:Open",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINWEAPON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("skinweapon",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("skinweapon:Open",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LSCUSTOMS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("lscustoms",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("lscustoms:Open",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TATTOOSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("tattooshop",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("tattooshop:Open",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- POSTIT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("postit",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("chat:postit_new",source,true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- USOURCE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("usource",function(source,Message)
	local Passport = vRP.Passport(source)
	local OtherSource = parseInt(Message[1])
	if Passport and OtherSource and OtherSource > 0 and vRP.Passport(OtherSource) and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("Notify",source,"Informações","<b>Passaporte:</b> "..vRP.Passport(OtherSource),"default",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CAM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("cam",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Freecam") then
		TriggerClientEvent("creative:Freecam",source,Message)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ID
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("id",function(source,Message)
	local OtherPassport = Message[1]
	local Passport = vRP.Passport(source)
	if Passport and OtherPassport and vRP.Identity(OtherPassport) and vRP.HasGroup(Passport,"Admin") then
		local CountGroups = 0
		local Radio = "Desligado"
		local Message = "<br><br>"
		local Groups = vRP.UserGroups(OtherPassport)
		local OtherSource = vRP.Source(OtherPassport)
		for Permission,Level in pairs(Groups) do
			CountGroups = CountGroups + 1
			Message = Message.."[ <warning>"..Permission.."</warning> ] "..vRP.NameHierarchy(Permission,Level).." ( "..Level.." )<br>"
		end

		if OtherSource then
			Radio = vHUD.Radio(OtherSource)
		end

		TriggerClientEvent("Notify",source,"Informações","<b>Passaporte:</b> "..OtherPassport.."<br><b>Nome:</b> "..vRP.FullName(OtherPassport).."<br><b>Banco:</b> "..Currency..Dotted(vRP.GetBank(OtherPassport)).."<br><b>Radio:</b> "..(Radio ~= ("Desligado" or 0) and Radio.."Mhz" or "Desligado").."<br><b>Telefone:</b> "..vRP.Phone(OtherPassport).."<br><b>Grupos Participantes:</b> "..CountGroups..(CountGroups >= 1 and Message or ""),(OtherSource and "verde" or "vermelho"),10000)
	end
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- WIPEPERMISSIONS
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("wipepermissions",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasPermission(Passport,"Admin") then
		local Permissions = {}
		for Permission in pairs(Groups) do
			Permissions[#Permissions + 1] = Permission
		end

		table.sort(Permissions,function(a,b) return a < b end)

		local Keyboard = vKEYBOARD.Instagram(source,Permissions)
		if Keyboard then
			local Permission = Keyboard[1]
			local Consult = exports.oxmysql:query_async("SELECT * FROM chests WHERE Permission LIKE ?",{ Permission.."%" })
			for _,v in pairs(Consult) do
				if v.Permission and SplitOne(v.Permission) == Permission and vRP.GetSrvData("Chest:"..v.Name,true) then
					vRP.RemSrvData("Chest:"..v.Name)
				end

				if v.id then
					exports.oxmysql:query_async("DELETE FROM chests WHERE id = ?",{ v.id })
				end
			end

			local Data = vRP.GetSrvData("Permissions:"..Permission,true)
			if Data then
				for OtherPassport in pairs(Data) do
					local OtherSource = vRP.Source(OtherPassport)
					if OtherSource then
						vRP.ServiceLeave(OtherSource,OtherPassport,Permission,true)
					end
				end

				vRP.RemSrvData("Permissions:"..Permission)
			end

			exports.oxmysql:query_async("DELETE FROM permissions WHERE Permission = ?",{ Permission })
		end
	end
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- REFERRAL
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("referral",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasPermission(Passport,"Admin") then
		local Keyboard = vKEYBOARD.Primary(source,"Código")
		if Keyboard then
			local Code = Keyboard[1]
			local Amount = exports.oxmysql:scalar_async("SELECT COUNT(Referral) FROM accounts WHERE Referral = ?",{ Code })

			TriggerClientEvent("Notify",source,Code,"Utilizado por <b>"..Amount.."</b> pessoas.","verde",10000)
		end
	end
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- CLEARPERMISSION
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("clearpermission",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasPermission(Passport,"Admin") then
		local Keyboard = vKEYBOARD.Primary(source,"Passaporte")
		if Keyboard then
			local OtherPassport = parseInt(Keyboard[1])
			if vRP.Identity(OtherPassport) then
				local Permissions = vRP.UserGroups(OtherPassport)
				for Permission,Level in pairs(Permissions) do
					vRP.RemovePermission(OtherPassport,Permission)
				end

				TriggerClientEvent("Notify",source,"Sucesso","Limpeza concluída.","verde",5000)
			end
		end
	end
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- STATUS
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("status",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasPermission(Passport,"Admin") then
		local Permissions = {}
		for Permission in pairs(Groups) do
			table.insert(Permissions,Permission)
		end

		table.sort(Permissions,function(a,b) return a < b end)

		local Keyboard = vKEYBOARD.Instagram(source,Permissions)
		if Keyboard then
			local Online = ""
			local Offline = ""
			local Permission = Keyboard[1]
			local Consult,Amount = vRP.DataGroups(Permission)
			local Table,Connects = vRP.NumPermission(Permission)

			local Message = "<warning>Jogadores Conectados:</warning> "..Connects.."<br><warning>Jogadores Participantes:</warning> "..Amount..(Amount >= 1 and "<br><br>" or "")

			for OtherPassport in pairs(Consult) do
				if Table[OtherPassport] then
					Online = Online.."<online>•</online> "..vRP.FullName(OtherPassport).." ( "..OtherPassport.." )<br>"
				else
					Offline = Offline.."<offline>•</offline> "..vRP.FullName(OtherPassport).." ( "..OtherPassport.." )<br>"
				end
			end

			TriggerClientEvent("Notify",source,Permission,Message..Online..Offline,"default",15000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKIN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("skin",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Tertiary(source,"Passaporte","Modelo","Dias")
	if not Keyboard then
		return false
	end

	local Model = Keyboard[2]
	if not vRPC.ModelExist(source,Model) then
		TriggerClientEvent("Notify",source,"Aviso","Modelo inválido.","amarelo",5000)
		return false
	end

	local Days = parseInt(Keyboard[3],true)
	local OtherPassport = parseInt(Keyboard[1])
	local OtherSource = vRP.Source(OtherPassport)
	if OtherSource then
		vRPC.Skin(OtherSource,Model)
	end

	if Days > 0 then
		local CurrentTimer = os.time()
		local ExpireTime = Days * 86400
		local Consult = exports.oxmysql:single_async("SELECT SkinMontly FROM characters WHERE id = ? LIMIT 1",{ OtherPassport })
		if Consult then
			local NewExpire = (Consult.SkinMontly or 0) > CurrentTimer and Consult.SkinMontly + ExpireTime or CurrentTimer + ExpireTime
			exports.oxmysql:update_async("UPDATE characters SET SkinMontly = ? WHERE id = ?",{ NewExpire,OtherPassport })
		end
	end

	vRP.SkinCharacter(OtherPassport,Model)
	TriggerClientEvent("Notify",source,"Sucesso","Aplicação concluída.","verde",5000)
	exports.discord:Embed("Skin","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[MODEL]:** "..Model.."\n**[DIAS]:** "..Days)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARINV
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("clearinv",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and parseInt(Message[1]) > 0 and vRP.HasGroup(Passport,"Admin",2) then
		vRP.ClearInventory(Message[1],true)
		TriggerClientEvent("Notify",source,"Sucesso","Limpeza concluída.","verde",5000)
		exports.discord:Embed("ClearInv","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..Message[1])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DIMA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("dima",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Quantidade")
	if not Keyboard then
		return false
	end

	local Amount = Keyboard[2]
	local OtherPassport = Keyboard[1]
	if not vRP.Identity(OtherPassport) then
		TriggerClientEvent("Notify",source,"Aviso","Passaporte inválido.","vermelho",5000)
		return false
	end

	vRP.UpgradeGemstone(OtherPassport,Amount,true)
	TriggerClientEvent("Notify",source,"Sucesso","Diamantes entregues.","verde",5000)
	exports.discord:Embed("Dima",("**[ADMIN]:** %s\n**[PASSAPORTE]:** %s\n**[QUANTIDADE]:** %sx"):format(Passport,OtherPassport,Amount))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("money",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Quantidade")
	if not Keyboard then
		return false
	end

	local Amount = Keyboard[2]
	local OtherPassport = Keyboard[1]
	if not vRP.Identity(OtherPassport) then
		TriggerClientEvent("Notify",source,"Aviso","Passaporte inválido.","vermelho",5000)
		return false
	end

	vRP.GiveBank(OtherPassport,Amount,true)
	TriggerClientEvent("Notify",source,"Sucesso","Dinheiros entregues.","verde",5000)
	exports.discord:Embed("Money",("**[ADMIN]:** %s\n**[PASSAPORTE]:** %s\n**[QUANTIDADE]:** %sx"):format(Passport,OtherPassport,Amount))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLIPS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("blips",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		vRPC.BlipAdmin(source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GOD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("god",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		if Message[1] then
			local OtherPassport = parseInt(Message[1])
			local OtherSource = vRP.Source(OtherPassport)
			if OtherSource then
				vRP.Revive(OtherSource,300)
				vRP.UpgradeThirst(OtherPassport,10)
				vRP.UpgradeHunger(OtherPassport,10)
				vRP.DowngradeStress(OtherPassport,100)
				TriggerClientEvent("paramedic:Reset",OtherSource)

				exports.discord:Embed("God","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport)
			end
		else
			vRP.Revive(source,300)
			vRP.Armour(source,100)
			vRP.UpgradeThirst(Passport,100)
			vRP.UpgradeHunger(Passport,100)
			vRP.DowngradeStress(Passport,100)
			TriggerClientEvent("paramedic:Reset",source)

			exports.discord:Embed("God","**[ADMIN]:** "..Passport)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("item",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",2) then
		if not Message[1] then
			local Keyboard = vKEYBOARD.Item(source,"Passaporte","Item","Quantidade",{ "Jogador","Todos","Area" },"Distância")
			if Keyboard and exports.vrp:ItemExist(Keyboard[2]) then
				local Item = Keyboard[2]
				local Action = Keyboard[4]
				local OtherPassport = Keyboard[1]
				local Amount = parseInt(Keyboard[3],true)
				local Distance = parseInt(Keyboard[5],true)

				if Action == "Jogador" then
					if vRP.Source(OtherPassport) then
						vRP.GenerateItem(OtherPassport,Item,Amount,true)
						TriggerClientEvent("Notify",source,"Sucesso","Entregue ao destinatário.","verde",5000)
					else
						local Selected = GenerateString("DDLLDDLL")
						local Consult = vRP.GetSrvData("Offline:"..OtherPassport,true)

						repeat
							Selected = GenerateString("DDLLDDLL")
						until Selected and not Consult[Selected]

						TriggerClientEvent("Notify",source,"Sucesso","Adicionado a lista de entregas.","verde",5000)
						Consult[Selected] = { Item = Item, Amount = Amount }
						vRP.SetSrvData("Offline:"..OtherPassport,Consult,true)
					end
				elseif Action == "Todos" then
					local List = vRP.Players()
					for OtherPlayer in pairs(List) do
						async(function()
							vRP.GenerateItem(OtherPlayer,Item,Amount,true)
						end)
					end
				elseif Action == "Area" then
					local PlayerList = GetPlayers()
					local Coords = vRP.GetEntityCoords(source)

					for _,OtherSource in ipairs(PlayerList) do
						async(function()
							local OtherSource = parseInt(OtherSource)
							local OtherPassport = vRP.Passport(OtherSource)
							local OtherCoords = vRP.GetEntityCoords(OtherSource)

							if OtherCoords and OtherPassport and #(Coords - OtherCoords) <= Distance then
								vRP.GenerateItem(OtherPassport,Item,Amount,true)
							end
						end)
					end
				end

				exports.discord:Embed("Item","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[ITEM]:** "..Item.."\n**[QUANTIDADE]:** "..Amount.."x")
			end
		elseif Message[1] and Message[2] then
			vRP.GenerateItem(Passport,Message[1],Message[2],true)
			exports.discord:Embed("Item","**[ADMIN]:** "..Passport.."\n**[ITEM]:** "..Message[1].."\n**[QUANTIDADE]:** "..Message[2].."x")
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("skins",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",2) then
		local Keyboard = vKEYBOARD.Skins(source,"Passaporte","Número","Weapon","Component",{ "Jogador","Todos" })
		if Keyboard then
			if Keyboard[5] == "Jogador" then
				local OtherPassport = parseInt(Keyboard[1])
				if vRP.Identity(OtherPassport) then
					TriggerEvent("inventory:SkinPlayer",OtherPassport,Keyboard[2],Keyboard[3],Keyboard[4])
				end
			elseif Keyboard[5] == "Todos" then
				local List = vRP.Players()
				for OtherPassport in pairs(List) do
					async(function()
						TriggerEvent("inventory:SkinPlayer",OtherPassport,Keyboard[2],Keyboard[3],Keyboard[4])
					end)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("delete",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and Message[1] and vRP.HasGroup(Passport,"Admin",2) then
		vRP.Update("characters/Delete",{ Passport = Message[1] })
		TriggerClientEvent("Notify",source,"Sucesso","Personagem <b>"..Message[1].."</b> deletado.","verde",5000)
		exports.discord:Embed("Delete","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..Message[1])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- NC
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("nc",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		TriggerClientEvent("creative:NoClip",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("kick",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") and parseInt(Message[1]) > 0 then
		local OtherPassport = Message[1]
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource then
			vRP.Kick(OtherSource,"Expulso da cidade")
			TriggerClientEvent("Notify",source,"Sucesso","Passaporte <b>"..OtherPassport.."</b> expulso.","verde",5000)
			exports.discord:Embed("Kick","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BAN2
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("ban2",function(source,Message)
    local Passport = vRP.Passport(source)
    if Passport and vRP.HasGroup(Passport,"Admin") then
        local Keyboard = vKEYBOARD.Banned(source,"Passaporte","Motivo")
        if Keyboard then
            local OtherPassport = parseInt(Keyboard[1])
            local Reason = Keyboard[2]
            local Identity = vRP.Identity(OtherPassport)
            if Identity and Identity.License then
                local Account = vRP.Query("accounts/Account",{ License = Identity.License })
                if Account[1] then
                    local AccountID = Account[1].id
                    vRP.Query("accounts/BannedPermanent",{ Account = AccountID, Reason = Reason })
                    local OtherSource = vRP.Source(OtherPassport)
                    if OtherSource then
                        vRP.Kick(OtherSource,"Você foi banido permanentemente: "..Reason)
                    end

                    TriggerClientEvent("Notify",source,"Sucesso","Banimento PERMANENTE aplicado ao passaporte <b>"..OtherPassport.."</b>.","verde",5000)
					
                    exports.discord:Embed("Ban","**[ADMIN]:** "..Passport.."\n**[BANIU]:** "..OtherPassport.."\n**[MODO]:** Permanente".."\n**[RAZÃO]:** "..Reason)
					
                else
                    TriggerClientEvent("Notify",source,"Erro","Conta não encontrada no banco de dados.","vermelho",5000)
                end
            else
                TriggerClientEvent("Notify",source,"Erro","Passaporte inválido ou não encontrado.","vermelho",5000)
            end
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("ban",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Codes(source,"Passaporte","Minutos","Motivo")
	if not Keyboard then
		return false
	end

	local Reason = Keyboard[3]
	local Duration = Keyboard[2]
	local OtherPassport = Keyboard[1]
	if not vRP.Identity(OtherPassport) then
		return false
	end

	vRP.SetBanned(OtherPassport,Duration,Reason,Passport)
	TriggerClientEvent("Notify",source,"Sucesso","Banimento aplicado ao passaporte <b>"..OtherPassport.."</b>.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("banr",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Minutos")
	if not Keyboard then
		return false
	end

	local Duration = Keyboard[2]
	local OtherPassport = Keyboard[1]
	if not vRP.Identity(OtherPassport) then
		return false
	end

	vRP.UpdateBanned(OtherPassport,Duration)
	TriggerClientEvent("Notify",source,"Sucesso","Banimento reduzido ao passaporte <b>"..OtherPassport.."</b>.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UNBAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("unban",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Primary(source,"Passaporte")
	if not Keyboard then
		return false
	end

	local OtherPassport = Keyboard[1]
	if not vRP.Identity(OtherPassport) then
		return false
	end

	vRP.RemoveBanned(OtherPassport)
	exports.discord:Embed("Ban","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[MODO]:** Unban")
	TriggerClientEvent("Notify",source,"Sucesso","Revogado o banimento do passaporte <b>"..OtherPassport.."</b>.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSERTCRON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("insertcron",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Skins(source,"Passaporte","Permissão","Hierarquia","Quantidade",{ "Horas","Dias" })
	if not Keyboard then
		return false
	end

	local OtherPassport = parseInt(Keyboard[1])
	local Permission = tostring(Keyboard[2] or "")
	local Hierarchy = parseInt(Keyboard[3],true)
	local Amount = parseInt(Keyboard[4],true)
	local Mode = tostring(Keyboard[5] or "")

	if not OtherPassport or OtherPassport <= 0 then
		return TriggerClientEvent("Notify",source,"Erro","Passaporte inválido.","vermelho",5000)
	end

	if Permission == "" then
		return TriggerClientEvent("Notify",source,"Erro","Permissão inválida.","vermelho",5000)
	end

	if not Hierarchy or Hierarchy < 0 then
		return TriggerClientEvent("Notify",source,"Erro","Hierarquia inválida.","vermelho",5000)
	end

	if not Amount or Amount <= 0 then
		return TriggerClientEvent("Notify",source,"Erro","Quantidade inválida.","vermelho",5000)
	end

	local Timer = 0
	if Mode == "Horas" then
		Timer = Amount * 3600
	elseif Mode == "Dias" then
		Timer = Amount * 86400
	else
		return TriggerClientEvent("Notify",source,"Erro","Modo inválido.","vermelho",5000)
	end

	if Timer <= 0 then
		return false
	end

	if not vRP.HasPermission(OtherPassport,Permission,Hierarchy) then
		vRP.SetPermission(OtherPassport,Permission,Hierarchy)
	end

	exports.crons:Insert(OtherPassport,"RemovePermission",Timer,{ Permission = Permission, Level = Hierarchy })
	TriggerClientEvent("Notify",source,"Sucesso","Permissão adicionada com tempo definido.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVECRON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("removecron",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Permissão")
	if not Keyboard then
		return false
	end

	local OtherPassport = parseInt(Keyboard[1])
	local Permission = tostring(Keyboard[2] or "")
	if not OtherPassport or OtherPassport <= 0 then
		return TriggerClientEvent("Notify",source,"Erro","Passaporte inválido.","vermelho",5000)
	end

	if Permission == "" then
		return TriggerClientEvent("Notify",source,"Erro","Permissão inválida.","vermelho",5000)
	end

	exports.crons:Remove(OtherPassport,"RemovePermission",Permission)
	TriggerClientEvent("Notify",source,"Sucesso","Cron removido com sucesso.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TPCDS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("tpcds",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Keyboard = vKEYBOARD.Primary(source,"Cordenadas")
		if Keyboard then
			local Split = splitString(Keyboard[1],",")
			if Split[1] and Split[2] and Split[3] then
				vRP.Teleport(source,Split[1],Split[2],Split[3])
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUCKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("bucket",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		exports.vrp:Bucket(source,"Enter",Message[1])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CDS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("cds",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.DoesEntityExist(source) and vRP.HasGroup(Passport,"Admin") then
		local Ped = GetPlayerPed(source)
		local Coords = GetEntityCoords(Ped)
		local Heading = GetEntityHeading(Ped)

		vKEYBOARD.Copy(source,"Cordenadas",Optimize(Coords.x)..","..Optimize(Coords.y)..","..Optimize(Coords.z)..","..Optimize(Heading))
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GROUP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("group",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and Message[1] and Message[2] and vRP.HasGroup(Passport,"Admin",2) then
		local Permission = Message[2]
		local OtherPassport = Message[1]
		if Permission == "Admin" and vRP.HasPermission(Passport,Permission) >= 2 then
			return false
		end

		vRP.SetPermission(OtherPassport,Permission,Message[3])
		TriggerClientEvent("Notify",source,"Sucesso","Adicionado <b>"..Permission.."</b> ao passaporte <b>"..OtherPassport.."</b>.","verde",5000)
		exports.discord:Embed("Group","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[GRUPO]:** "..Permission.."\n**[Modo]:** Adicionou")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UNGROUP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("ungroup",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and Message[1] and Message[2] and vRP.HasGroup(Passport,"Admin",2) then
		local Permission = Message[2]
		local OtherPassport = Message[1]
		if Permission == "Admin" and vRP.HasPermission(Passport,Permission) >= 2 then
			return false
		end

		vRP.RemovePermission(OtherPassport,Permission)
		TriggerClientEvent("Notify",source,"Sucesso","Removido <b>"..Permission.."</b> ao passaporte <b>"..OtherPassport.."</b>.","verde",5000)
		exports.discord:Embed("Group","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[GRUPO]:** "..Permission.."\n**[Modo]:** Removeu")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TPTOME
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("tptome",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and Message[1] and vRP.HasGroup(Passport,"Admin") then
		local OtherPassport = parseInt(Message[1])
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and vRP.DoesEntityExist(OtherSource) then
			local Ped = GetPlayerPed(source)
			local Coords = GetEntityCoords(Ped)

			vRP.Teleport(OtherSource,Coords.x,Coords.y,Coords.z)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TPTO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("tpto",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and Message[1] and vRP.HasGroup(Passport,"Admin") then
		local OtherPassport = parseInt(Message[1])
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and vRP.DoesEntityExist(OtherSource) then
			local Ped = GetPlayerPed(OtherSource)
			local Coords = GetEntityCoords(Ped)

			vRP.Teleport(source,Coords.x,Coords.y,Coords.z)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TPWAY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("tpway",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		vCLIENT.teleportWay(source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TUNING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("tuning",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",1) then
		TriggerClientEvent("admin:Tuning",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FIX
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("fix",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Vehicle,Network,Plate = vRPC.VehicleList(source)
		if Vehicle then
			local Players = vRPC.Players(source)
			for _,OtherSource in pairs(Players) do
				async(function()
					TriggerClientEvent("inventory:RepairAdmin",OtherSource,Network,Plate)
				end)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:DOORS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("admin:Doords")
AddEventHandler("admin:Doords",function(Coords,Model,Heading)
	exports.admin:Archive("coordenadas.txt","Coords = "..Coords..", Heading = "..Heading..", Hash = "..Model..", Disabled = false, Lock = true, Distance = 1.75")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CDS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.buttonTxt()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and vRP.DoesEntityExist(source) and vRP.HasGroup(Passport,"Admin") then
		local Ped = GetPlayerPed(source)
		local Coords = GetEntityCoords(Ped)
		local Heading = GetEntityHeading(Ped)

		exports.admin:Archive(Passport..".txt",Optimize(Coords.x)..","..Optimize(Coords.y)..","..Optimize(Coords.z)..","..Optimize(Heading))
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANNOUNCE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("announce",function(source,Message,History)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",2) then
		local Keyboard = vKEYBOARD.Announce(source,"Título","Mensagem","Segundos",{ "amarelo","verde","vermelho","fome","sede","default","sangue","policia" },{ "middle-left","middle-right","top-left","top-center","top-right","bottom-left","bottom-center","bottom-right" })
		if Keyboard then
			local Title = Keyboard[1]
			local Colors = Keyboard[4]
			local Message = Keyboard[2]
			local Direction = Keyboard[5]
			local Seconds = parseInt(Keyboard[3],true) * 1000

			TriggerClientEvent("Notify",-1,Title,Message,Colors,Seconds,Direction)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- NAMEDS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("nameds",function(source)
	if source ~= 0 then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT id,Name,Lastname FROM characters")
	for _,v in ipairs(Consult) do
		local Name = v.Name ~= "" and FirstName(v.Name) or "Indivíduo"
		local Lastname = v.Lastname ~= "" and FirstName(v.Lastname) or "Indigente"

		exports.oxmysql:update_async("UPDATE characters SET Name = ?, Lastname = ? WHERE id = ?",{ Name,Lastname,v.id })

		Wait(100)
	end

	print(("Nomes ajustados para %d personagens."):format(#Consult))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONSOLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("console",function(source,Message,History)
	if source == 0 then
		TriggerClientEvent("Notify",-1,"Prefeitura",History:sub(8),"default",60000,"bottom-center")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICKALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("kickall",function(source)
	if source ~= 0 then
		local Passport = vRP.Passport(source)
		if not vRP.HasGroup(Passport,"Admin",1) then
			return
		end
	end

	TriggerClientEvent("Notify",-1,"Prefeitura","Terremoto se aproxima em 3 minutos.","default",60000,"bottom-center")
	GlobalState.Weather = "RAIN"
	Wait(60000)

	TriggerClientEvent("Notify",-1,"Prefeitura","Terremoto se aproxima em 2 minutos.","default",60000,"bottom-center")
	Wait(60000)

	TriggerClientEvent("Notify",-1,"Prefeitura","Terremoto se aproxima em 1 minuto.","default",60000,"bottom-center")
	GlobalState.Weather = "THUNDER"
	Wait(60000)

	local List = vRP.Players()
	for _,OtherSource in pairs(List) do
		vRP.Kick(OtherSource,"Desconectado, a cidade reiniciou")
		Wait(100)
	end

	TriggerEvent("SaveServer",false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICKALL2
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("kickall2",function(source)
	if source ~= 0 then
		local Passport = vRP.Passport(source)
		if not vRP.HasGroup(Passport,"Admin",1) then
			return
		end
	end

	local List = vRP.Players()
	for _,OtherSource in pairs(List) do
		vRP.Kick(OtherSource,"Desconectado, a cidade reiniciou")
		Wait(100)
	end

	TriggerEvent("SaveServer",false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("save",function(source)
	if source ~= 0 then
		local Passport = vRP.Passport(source)
		if not vRP.HasGroup(Passport,"Admin",1) then
			return
		end
	end

	TriggerEvent("SaveServer",false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOGSERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(10 * 60000)

		local Message = "**LISTAGEM DE JOGADORES**\n\n**[ PLAYERS ]:** "..GetNumPlayerIndices().."\n"
		for Permission in pairs(Groups) do
			Message = Message.."**[ "..string.upper(Permission).." ]:** "..vRP.AmountService(Permission).."\n"

			Wait(1000)
		end

		exports.discord:Embed("Permissions",Message)
		TriggerEvent("SaveServer",true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACECONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RaceConfig(Left,Center,Right,Distance,Name)
	exports.admin:Archive(Name..".txt","{")
	exports.admin:Archive(Name..".txt","['Left'] = vec3("..Optimize(Left.x)..","..Optimize(Left.y)..","..Optimize(Left.z).."),")
	exports.admin:Archive(Name..".txt","['Center'] = vec3("..Optimize(Center.x)..","..Optimize(Center.y)..","..Optimize(Center.z).."),")
	exports.admin:Archive(Name..".txt","['Right'] = vec3("..Optimize(Right.x)..","..Optimize(Right.y)..","..Optimize(Right.z).."),")
	exports.admin:Archive(Name..".txt","['Distance'] = "..Distance)
	exports.admin:Archive(Name..".txt","},")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
local Spectate = {}
RegisterCommand("spectate",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	if Spectate[Passport] then
		local Ped = GetPlayerPed(Spectate[Passport])
		if DoesEntityExist(Ped) then
			SetEntityDistanceCullingRadius(Ped,0.0)
		end

		TriggerClientEvent("admin:resetSpectate",source)
		Spectate[Passport] = nil

		return false
	end

	local OtherPassport = parseInt(Message[1])
	local OtherSource = vRP.Source(OtherPassport)
	if OtherSource then
		local Ped = GetPlayerPed(OtherSource)
		if DoesEntityExist(Ped) then
			Spectate[Passport] = OtherSource
			SetEntityDistanceCullingRadius(Ped,999999.0)

			SetTimeout(1000,function()
				TriggerClientEvent("admin:initSpectate",source,OtherSource)
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- QUAKE
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState.Quake = false
RegisterCommand("quake",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",1) then
		TriggerClientEvent("Notify",-1,"Terromoto","Os geólogos informaram para nossa unidade governamental que foi encontrado um abalo de magnitude <b>60</b> na <b>Escala Richter</b>, encontrem abrigo até que o mesmo passe.","amarelo",60000)
		GlobalState.Quake = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LIMPAREA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("limparea",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Ped = GetPlayerPed(source)
		local Coords = GetEntityCoords(Ped)
		local Players = vRPC.Players(source)
		for _,Sources in pairs(Players) do
			async(function()
				vCLIENT.Limparea(Sources,Coords)
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VIDEO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("video",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Keyboard = vKEYBOARD.Instagram(source,{ "Passporte","Permissão","Area","Global","Fechar" })
		if Keyboard then
			if Keyboard[1] == "Passporte" then
				local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Código Vimeo")
				if Keyboard then
					local OtherPassport = parseInt(Keyboard[1])
					local OtherSource = vRP.Source(OtherPassport)
					if OtherSource then
						TriggerClientEvent("hud:Video",OtherSource,Keyboard[2])
						TriggerClientEvent("Notify",source,"Sucesso","Vídeo executado com sucesso.","verde",5000)
					end
				end
			elseif Keyboard[1] == "Global" then
				local Keyboard = vKEYBOARD.Primary(source,"Código Vimeo")
				if Keyboard then
					TriggerClientEvent("hud:Video",-1,Keyboard[1])
				end
			elseif Keyboard[1] == "Permissão" then
				local Permissions = {}
				for Permission in pairs(Groups) do
					table.insert(Permissions,Permission)
				end

				table.sort(Permissions,function(a,b) return a < b end)
				local Keyboard = vKEYBOARD.Options(source,"Código Vimeo",Permissions)
				if Keyboard then
					local Service = vRP.NumPermission(Keyboard[2])
					for Passports,Sources in pairs(Service) do
						async(function()
							TriggerClientEvent("hud:Video",Sources,Keyboard[1])
						end)
					end

					TriggerClientEvent("Notify",source,"Sucesso","Vídeo executado com sucesso.","verde",5000)
				end
			elseif Keyboard[1] == "Area" then
				local Keyboard = vKEYBOARD.Secondary(source,"Distância","Código Vimeo")
				if Keyboard then
					local PlayerList = GetPlayers()
					local Coords = vRP.GetEntityCoords(source)

					for _,OtherSource in ipairs(PlayerList) do
						async(function()
							local OtherSource = parseInt(OtherSource)
							local OtherCoords = vRP.GetEntityCoords(OtherSource)

							if OtherCoords and #(Coords - OtherCoords) <= parseInt(Keyboard[1]) then
								TriggerClientEvent("hud:Video",OtherSource,Keyboard[2])
							end
						end)
					end

					TriggerClientEvent("Notify",source,"Sucesso","Vídeo executado com sucesso.","verde",5000)
				end
			elseif Keyboard[1] == "Fechar" then
				TriggerClientEvent("hud:Video",-1)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RENAME
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("rename",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Tertiary(source,"Passaporte","Nome","Sobrenome")
	if not Keyboard then
		return false
	end

	local Name = Keyboard[2]
	local Lastname = Keyboard[3]
	local OtherPassport = parseInt(Keyboard[1])

	local Identity = vRP.Identity(OtherPassport)
	if not Identity then
		TriggerClientEvent("Notify",source,"Erro","Passaporte inválido.","vermelho",5000)
		return false
	end

	vRP.UpgradeNames(OtherPassport,Name,Lastname)
	TriggerClientEvent("Notify",source,"Sucesso","Nome atualizado.","verde",5000)

	local Account = vRP.Account(Identity.License)
	if Account and Account.Discord then
		exports.discord:Content("Rename",account.Discord.." #"..OtherPassport.." "..Name.." "..Lastname)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDCAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("addcar",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasPermission(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Vehicle(source,"Passaporte","Modelo",{ "Mensal","Permanente","Dias" },"Dias",{ "Sim","Não" })
	if not Keyboard then
		return false
	end

	local OtherPassport = parseInt(Keyboard[1],true)
	if not OtherPassport or OtherPassport <= 0 or not vRP.Identity(OtherPassport) then
		TriggerClientEvent("Notify",source,"Atenção","Passaporte inválido.","vermelho",5000)
		return false
	end

	local Model = Keyboard[2]
	if not Model or Model == "" or not exports.vrp:VehicleExist(Model) then
		TriggerClientEvent("Notify",source,"Atenção","Modelo de veículo inválido.","vermelho",5000)
		return false
	end

	local Mode = Keyboard[3]
	local Days = parseInt(Keyboard[4],true)
	if Mode == "Dias" and Days <= 0 then
		TriggerClientEvent("Notify",source,"Atenção","Quantidade de dias inválida.","vermelho",5000)
		return false
	end

	local VehicleExists = exports.oxmysql:single_async("SELECT id FROM vehicles WHERE Passport = ? AND Vehicle = ? LIMIT 1",{ OtherPassport,Model })
	if VehicleExists then
		TriggerClientEvent("Notify",source,"Atenção","Este passaporte já possui este veículo.","vermelho",5000)
		return false
	end

	local Tax = nil
	local Rental = nil
	local CurrentTimer = os.time()
	if Mode == "Mensal" then
		Rental = CurrentTimer + 2592000
		Tax = Rental
	elseif Mode == "Dias" then
		Rental = CurrentTimer + (86400 * Days)
		Tax = Rental
	elseif Mode == "Permanente" then
		Tax = CurrentTimer + 2592000
	end

	local Plate = vRP.GeneratePlate()
	local Block = Keyboard[5] == "Sim"
	local Weight = exports.vrp:VehicleWeight(Model)
	local Work = exports.vrp:VehicleMode(Model) == "Work"
	local Inserted = exports.oxmysql:insert_async("INSERT INTO vehicles (Passport,Vehicle,Plate,Weight,Work,Rental,Tax,Block) VALUES (?,?,?,?,?,?,?,?)",{ OtherPassport,Model,Plate,Weight,Work,Rental,Tax,Block })
	if not Inserted then
		TriggerClientEvent("Notify",source,"Erro","Falha ao registrar o veículo.","vermelho",5000)
		return false
	end

	exports.discord:Embed("AddCar",("**[ADMIN]:** %s\n**[PASSAPORTE]:** %s\n**[MODEL]:** %s\n**[TIPO]:** %s\n**[PLACA]:** %s"):format(Passport,OtherPassport,Model,Mode,Plate))
	TriggerClientEvent("Notify",source,"Sucesso",("Veículo <b>%s</b> entregue para o passaporte <b>%s</b>."):format(exports.vrp:VehicleName(Model),OtherPassport),"verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMCAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("remcar",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Primary(source,"Passaporte")
	if not Keyboard then
		return false
	end

	local OtherPassport = parseInt(Keyboard[1])
	local UserVehicles = vRP.Query("vehicles/UserVehicles",{ Passport = OtherPassport })
	if not UserVehicles or #UserVehicles == 0 then
		TriggerClientEvent("Notify",source,"Erro","Este usuário não possui veículos.","vermelho",5000)
		return false
	end

	local VehicleList = {}
	for _,v in ipairs(UserVehicles) do
		VehicleList[#VehicleList + 1] = v.Vehicle
	end

	local Keyboard = vKEYBOARD.Instagram(source,VehicleList)
	if not Keyboard then
		return false
	end

	local Selected = Keyboard[1]
	vRP.RemSrvData("LsCustoms:"..OtherPassport..":"..Selected)
	vRP.RemSrvData("Trunkchest:"..OtherPassport..":"..Selected)
	vRP.Query("vehicles/removeVehicles",{ Passport = OtherPassport, Vehicle = Selected })

	TriggerClientEvent("Notify",source,"Sucesso","Veículo <b>"..exports.vrp:VehicleName(Selected).."</b> removido.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- NITRO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("nitro",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") and vRP.InsideVehicle(source) then
		local Vehicle,Network,Plate = vRPC.VehicleList(source)
		if Vehicle then
			local Networked = NetworkGetEntityFromNetworkId(Network)
			if DoesEntityExist(Networked) then
				Entity(Networked).state:set("Nitro",2000,true)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUEL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("fuel",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") and vRP.InsideVehicle(source) then
		TriggerClientEvent("engine:FuelAdmin",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KILL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("kill",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin",2) and Message[1] and parseInt(Message[1]) > 0 then
		local ClosestPed = vRP.Source(Message[1])
		if ClosestPed then
			vRPC.SetHealth(ClosestPed,100)
		end
	end
end)
------------------------------------------------------------------------------------------------------------------------------------------
-- LEADERS
------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("leaders",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasPermission(Passport,"Admin") then
		return false
	end

	local Message = {}
	local HasLeaders = false
	for Permission,v in pairs(Groups) do
		if not v.Block then
			local PermissionData = vRP.GetSrvData("Permissions:"..Permission,true)
			for OtherPassport,Level in pairs(PermissionData) do
				if Level <= 1 and vRP.Source(OtherPassport) then
					HasLeaders = true
					Message[#Message + 1] = string.format("%s - %s ( %s )<br>",Permission,vRP.FullName(OtherPassport),OtherPassport)
				end
			end
		end
	end

	if HasLeaders then
		TriggerClientEvent("Notify",source,"Líderes de Grupo",table.concat(Message),"verde",30000)
	else
		TriggerClientEvent("Notify",source,"Líderes de Grupo","Nenhum líder online no momento.","amarelo",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	local Consult = vRP.GetSrvData("Offline:"..Passport,true)
	if Consult and next(Consult) then
		for _,v in ipairs(Consult) do
			vRP.GenerateItem(Passport,v.Item,v.Amount,true)
		end

		vRP.RemSrvData("Offline:"..Passport)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if Spectate[Passport] then
		local Ped = GetPlayerPed(Spectate[Passport])
		if Ped and DoesEntityExist(Ped) then
			SetEntityDistanceCullingRadius(Ped,0.0)
		end

		Spectate[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETHTTPHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
SetHttpHandler(function(Request,Result)
	if Request.headers.Auth ~= "SuaAuthCode" then
		return SendMessageDiscord(Result,400,"Falha na autenticação.")
	end

	local Commands = {
		["/god"] = function(Data)
			local v = json.decode(Data)
			local OtherPassport = parseInt(v.Passport)
			local OtherSource = vRP.Source(OtherPassport)

			if OtherPassport and OtherSource then
				vRP.Revive(OtherSource,300)
				vRP.UpgradeThirst(OtherPassport,100)
				vRP.UpgradeHunger(OtherPassport,100)
				TriggerClientEvent("paramedic:Reset",OtherSource)

				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Personagem indisponível no momento.")
			end
		end,

		["/dima"] = function(Data)
			local v = json.decode(Data)
			local Amount = parseInt(v.Amount)
			local OtherPassport = parseInt(v.Passport)

			if OtherPassport and Amount > 0 then
				vRP.UpgradeGemstone(OtherPassport,Amount,true)
				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Personagem não encontrado.")
			end
		end,

		["/print"] = function(Data)
			local v = json.decode(Data)
			local OtherPassport = parseInt(v.Passport)
			local OtherSource = vRP.Source(OtherPassport)
			local Webhook = exports.discord:Webhook("Print")

			if OtherPassport and OtherSource and Webhook ~= "" then
				TriggerClientEvent("megazord:Screenshot",OtherSource,Webhook)
				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Personagem indisponível no momento.")
			end
		end,

		["/tdiscord"] = function(Data)
			local v = json.decode(Data)
			local NewDiscord = v.NewDiscord
			local CurrentDiscord = v.CurrentDiscord

			if NewDiscord and CurrentDiscord then
				local Consult = exports.oxmysql:single_async("SELECT * FROM accounts WHERE Discord = ? LIMIT 1",{ CurrentDiscord })
				if Consult then
					exports.oxmysql:update_async("UPDATE accounts SET Discord = ? WHERE id = ?",{ NewDiscord,Consult.id })
					SendMessageDiscord(Result,200,"Comando executado com sucesso.")
				else
					SendMessageDiscord(Result,404,"Não foi encontrado o discord no banco de dados.")
				end
			else
				SendMessageDiscord(Result,404,"Preencha os campos necessários.")
			end
		end,

		["/thex"] = function(Data)
			local v = json.decode(Data)
			local NewHexPlayer = v.NewHex
			local ActualHexPlayer = v.ActualHex

			if NewHexPlayer and ActualHexPlayer then
				exports.oxmysql:query_async("DELETE FROM accounts WHERE License = ?",{ NewHexPlayer })
				exports.oxmysql:query_async("DELETE FROM characters WHERE License = ?",{ NewHexPlayer })
				exports.oxmysql:update_async("UPDATE accounts SET License = ? WHERE License = ?",{ NewHexPlayer,ActualHexPlayer })
				exports.oxmysql:update_async("UPDATE characters SET License = ? WHERE License = ?",{ NewHexPlayer,ActualHexPlayer })

				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Troca indisponível no momento.")
			end
		end,

		["/banned"] = function(Data)
			local v = json.decode(Data)
			local Duration = parseInt(v.Duration)
			local OtherPassport = parseInt(v.Passport)

			if OtherPassport and vRP.Identity(OtherPassport) then
				vRP.SetBanned(OtherPassport,Duration,v.Reason)
				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Personagem indisponível no momento.")
			end
		end,

		["/unbanned"] = function(Data)
			local v = json.decode(Data)
			local OtherPassport = parseInt(v.Passport)

			if OtherPassport and vRP.Identity(OtherPassport) then
				vRP.RemoveBanned(OtherPassport)
				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Personagem indisponível no momento.")
			end
		end,

		["/limbo"] = function(Data)
			local v = json.decode(Data)
			local OtherPassport = parseInt(v.Passport)
			local OtherSource = vRP.Source(OtherPassport)

			if OtherPassport and OtherSource then
				vRP.Teleport(OtherSource,164.3,-998.45,29.35)
				SendMessageDiscord(Result,200,"Comando executado com sucesso.")
			else
				SendMessageDiscord(Result,404,"Personagem indisponível no momento.")
			end
		end
	}

	if Commands[Request.path] then
		Request.setDataHandler(function(Table)
			Commands[Request.path](Table)
		end)
	else
		SendMessageDiscord(Result,404,"Comando indisponível no momento.")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDMESSAGEDISCORD
-----------------------------------------------------------------------------------------------------------------------------------------
function SendMessageDiscord(Result,Code,Message)
	Result.writeHead(Code,{ ["Content-Type"] = "application/json" })
	Result.send(json.encode({ message = Message }))
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLACKOUT
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState.Blackout = false
RegisterCommand("blackout",function(source,Message)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		GlobalState.Blackout = not GlobalState.Blackout
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHIVE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Archive",function(Name,Message)
	local Path = GetResourcePath(GetCurrentResourceName())
	local File = io.open(Path.."/"..Name,"a")
	if File then
		File:write(Message.."\n")
		File:close()
	end
end)