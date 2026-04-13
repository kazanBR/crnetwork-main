-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local GarageSpawnVehicles = {}
local CurrentRotationObject = nil
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

			local Taxs = exports.oxmysql:query_async("SELECT * FROM taxs WHERE Passport = ?",{ OtherPassport })
			if Taxs and #Taxs > 0 then
				exports.oxmysql:update_async("UPDATE taxs SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
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

			local Investments = exports.oxmysql:query_async("SELECT * FROM investments WHERE Passport = ?",{ OtherPassport })
			if Investments and #Investments > 0 then
				exports.oxmysql:update_async("UPDATE investments SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
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

				local Taxs = exports.oxmysql:query_async("SELECT * FROM taxs WHERE Passport = ?",{ OtherPassport })
				if Taxs and #Taxs > 0 then
					exports.oxmysql:update_async("UPDATE taxs SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
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

				local Investments = exports.oxmysql:query_async("SELECT * FROM investments WHERE Passport = ?",{ OtherPassport })
				if Investments and #Investments > 0 then
					exports.oxmysql:update_async("UPDATE investments SET Passport = ? WHERE Passport = ?",{ NewPassport,OtherPassport })
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
	if Passport and vRP.HasPermission(Passport,"Admin",1) then
		local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Quantidade")
		if Keyboard then
			local Amount = parseInt(Keyboard[2])
			local OtherPassport = parseInt(Keyboard[1])
			if vRP.Identity(OtherPassport) then
				vRP.BattlepassPoints(OtherPassport,Amount)
				TriggerClientEvent("Notify",source,"Sucesso","Pontos enviados.","verde",5000)
			end
		end
	end
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
		TriggerClientEvent("freecam:Active",source,Message)
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
			if Keyboard and ItemExist(Keyboard[2]) then
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
		TriggerClientEvent("creative:NoClip", source)
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

	vRP.SetBanned(OtherPassport,Duration,Reason)
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
	exports.discord:Embed("Ban","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[NOVA DURAÇÃO]:** "..Duration.." minutos\n**[MODO]:** Ban Reduzido")
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
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Keyboard = vKEYBOARD.Skins(source,"Passaporte","Permissão","Hierarquia","Quantidade",{ "Horas","Dias" })
		if Keyboard then
			local Timer = 0
			local Mode = Keyboard[5]
			local Permission = Keyboard[2]
			local OtherPassport = Keyboard[1]
			local Amount = parseInt(Keyboard[4],true)
			local Hierarchy = parseInt(Keyboard[3],true)

			if not vRP.HasPermission(OtherPassport,Permission) then
				vRP.SetPermission(OtherPassport,Permission)
			end

			if Mode == "Horas" then
				Timer = Amount * 3600
			elseif Mode == "Dias" then
				Timer = Amount * 86400
			end

			exports.crons:Insert(OtherPassport,"RemovePermission",Timer,{ Permission = Permission, Level = Hierarchy })
			TriggerClientEvent("Notify",source,"Sucesso","Adição efetuada.","verde",5000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVECRON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("removecron",function(source)
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasGroup(Passport,"Admin") then
		local Keyboard = vKEYBOARD.Secondary(source,"Passaporte","Permissão")
		if Keyboard then
			exports.crons:Remove(Keyboard[1],"RemovePermission",Keyboard[2])
			TriggerClientEvent("Notify",source,"Sucesso","Remoção efetuada.","verde",5000)
		end
	end
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
	vRP.Archive("coordenadas.txt","Coords = "..Coords..", Heading = "..Heading..", Hash = "..Model..", Disabled = false, Lock = true, Distance = 1.75")
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

		vRP.Archive(Passport..".txt",Optimize(Coords.x)..","..Optimize(Coords.y)..","..Optimize(Coords.z)..","..Optimize(Heading))
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
-- TXADMIN:EVENTS:SERVERSHUTTINGDOWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("txAdmin:events:serverShuttingDown",function()
    TriggerEvent("SaveServer")
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
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACECONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RaceConfig(Left,Center,Right,Distance,Name)
	vRP.Archive(Name..".txt","{")

	vRP.Archive(Name..".txt","['Left'] = vec3("..Optimize(Left.x)..","..Optimize(Left.y)..","..Optimize(Left.z).."),")
	vRP.Archive(Name..".txt","['Center'] = vec3("..Optimize(Center.x)..","..Optimize(Center.y)..","..Optimize(Center.z).."),")
	vRP.Archive(Name..".txt","['Right'] = vec3("..Optimize(Right.x)..","..Optimize(Right.y)..","..Optimize(Right.z).."),")
	vRP.Archive(Name..".txt","['Distance'] = "..Distance)

	vRP.Archive(Name..".txt","},")
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
		exports.discord:Content("Rename",Account.Discord.." #"..OtherPassport.." "..Name.." "..Lastname)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDCAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("addcar",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin",1) then
		return false
	end

	local Keyboard = vKEYBOARD.Vehicle(source,"Passaporte","Modelo",{ "Mensal","Permanente","Dias" },"Dias",{ "Sim","Não" })
	if not Keyboard then return end

	local Mode = Keyboard[3]
	local Model = Keyboard[2]
	local Block = Keyboard[5] == "Sim"
	local Days = parseInt(Keyboard[4],true)
	local OtherPassport = parseInt(Keyboard[1],true)

	if not VehicleExist(Model) then
		TriggerClientEvent("Notify",source,"Erro","Modelo de veículo inválido.","vermelho",5000)
		return false
	end

	local Rental,Tax = nil,nil
	local CurrentTimer = os.time()
	local Plate = vRP.GeneratePlate()
	local Weight = VehicleWeight(Model)
	local Work = VehicleMode(Model) == "Work"

	if Mode == "Mensal" then
		Rental = CurrentTimer + 30 * 24 * 60 * 60
		Tax = Rental
	elseif Mode == "Dias" then
		Rental = CurrentTimer + (86400 * Days)
		Tax = Rental
	elseif Mode == "Permanente" then
		Tax = CurrentTimer + 30 * 24 * 60 * 60
	end

	exports.oxmysql:query_async("INSERT IGNORE INTO vehicles (Passport,Vehicle,Plate,Weight,Work,Rental,Tax,Block) VALUES (@Passport,@Vehicle,@Plate,@Weight,@Work,@Rental,@Tax,@Block)",{ Passport = OtherPassport, Vehicle = Model, Plate = Plate, Weight = Weight, Work = Work, Rental = Rental, Tax = Tax, Block = Block })
	exports.discord:Embed("AddCar","**[ADMIN]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport.."\n**[MODEL]:** "..Model.."\n**[TIPO]:** "..Mode)
	TriggerClientEvent("Notify",source,"Sucesso","Veículo <b>"..VehicleName(Model).."</b> entregue.","verde",5000)
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

	TriggerClientEvent("Notify",source,"Sucesso","Veículo <b>"..VehicleName(Selected).."</b> removido.","verde",5000)
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
			local NewDiscord = parseInt(v.NewDiscord)
			local OtherPassport = parseInt(v.Passport)
			local CurrentDiscord = parseInt(v.CurrentDiscord)

			if NewDiscord and OtherPassport and CurrentDiscord then
				local Account = vRP.AccountInformation(OtherPassport,"Discord")
				if Account and parseInt(Account) == CurrentDiscord then
					exports.oxmysql:update_async("UPDATE accounts SET Discord = ? WHERE Discord = ?",{ NewDiscord,Account })
					SendMessageDiscord(Result,200,"Comando executado com sucesso.")
				else
					SendMessageDiscord(Result,404,"Discord atual é diferente do enviado.")
				end
			else
				SendMessageDiscord(Result,404,"Personagem indisponível no momento.")
			end
		end,

		["/thex"] = function(Data)
			local v = json.decode(Data)
			local NewHexPlayer = v.NewHex
			local ActualHexPlayer = v.NewHex

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
-- GETPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetPermissions()
	local Permissions = {}
	if Groups then
		for Permission,Data in pairs(Groups) do
			Permissions[#Permissions + 1] = { Label = Data.Name or Permission, Value = Permission }
		end
	end
	return Permissions
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TXADMIN:EVENTS:SERVERSHUTTINGDOWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("txAdmin:events:serverShuttingDown",function()
    TriggerEvent("SaveServer")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("wl",function(source,Message,rawCommand)
    local Passport = vRP.Passport(source)
    if Passport and vRP.HasGroup(Passport,"Admin") then
        if Message[1] then
            local OtherPassport = Message[1]
    
            exports.oxmysql:update_async("UPDATE accounts SET Whitelist = ? WHERE id = ?", { 1, OtherPassport })
            
            exports.discord:Embed("Wl","**[ADMIN]:** "..Passport.."\n**[ADICIONOU WL]:** "..OtherPassport)

            TriggerClientEvent("Notify",source,"Sucesso","ID <b>"..OtherPassport.."</b> adicionado à Whitelist.","verde",5000)
        else
            TriggerClientEvent("Notify",source,"Aviso","Especifique o ID: /wl 1","amarelo",5000)
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UNWL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("unwl",function(source,Message,rawCommand)
    local Passport = vRP.Passport(source)
    if Passport and vRP.HasGroup(Passport,"Admin") then
        if Message[1] then
            local OtherPassport = Message[1]
            
            exports.oxmysql:update_async("UPDATE accounts SET Whitelist = ? WHERE id = ?", { 0, OtherPassport })
            
            exports.discord:Embed("Unwl","**[ADMIN]:** "..Passport.."\n**[REMOVEU WL]:** "..OtherPassport)

            TriggerClientEvent("Notify",source,"Sucesso","ID <b>"..OtherPassport.."</b> removido da Whitelist.","verde",5000)
        else
            TriggerClientEvent("Notify",source,"Aviso","Especifique o ID: /unwl 1","amarelo",5000)
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ALGEMA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("algema",function(source,args,rawCommand)
	local Passport = vRP.Passport(source)
	if Passport then
		if vRP.HasPermission(Passport,"Admin") then
			local ClosestPed = nil

			if args[1] then
				ClosestPed = vRP.Source(parseInt(args[1]))
			else
				ClosestPed = vRPC.ClosestPed(source)
			end

			if ClosestPed then
				local OtherPassport = vRP.Passport(ClosestPed)

				if Player(ClosestPed).state.Handcuff then
					Player(ClosestPed).state.Handcuff = false
					Player(ClosestPed).state.Commands = false
			
					TriggerClientEvent("sounds:Private",source,"uncuff",0.5)
					SetTimeout(100,function()
						TriggerClientEvent("sounds:Private",ClosestPed,"uncuff",0.5)
					end)

					vRPC.Destroy(ClosestPed)
					vRPC.Destroy(source)
					
					TriggerClientEvent("Notify",source,"Sucesso","Você <b>desalgemou</b> o passaporte <b>"..OtherPassport.."</b>.","verde",5000)
				else
					Player(ClosestPed).state.Handcuff = true
					Player(ClosestPed).state.Commands = true
					
					TriggerClientEvent("inventory:Close",ClosestPed)
					TriggerClientEvent("radio:RadioClean",ClosestPed)
					
					TriggerClientEvent("sounds:Private",source,"cuff",0.5)
					SetTimeout(100,function()
						TriggerClientEvent("sounds:Private",ClosestPed,"cuff",0.5)
					end)

					if not args[1] then
						vRPC.playAnim(source,false,{"mp_arrest_paired","cop_p2_back_left"},false)
						vRPC.playAnim(ClosestPed,false,{"mp_arrest_paired","crook_p2_back_left"},false)
					else
						vRPC.playAnim(ClosestPed,false,{"mp_arresting","idle"},true)
					end

					SetTimeout(3500,function()
						vRPC.Destroy(ClosestPed)
						vRPC.Destroy(source)
					end)

					TriggerClientEvent("Notify",source,"Sucesso","Você <b>algemou</b> o passaporte <b>"..OtherPassport.."</b>.","verde",5000)
				end
			else
				TriggerClientEvent("Notify",source,"Importante","Nenhum jogador encontrado.","vermelho",5000)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("ban",function(source,Message)
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
-- MOCHILA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("mochila",function(source,args,rawCommand)
    local Passport = vRP.Passport(source)
    if Passport and vRP.HasGroup(Passport,"Admin",1) then
        local OtherPassport = tonumber(args[1])
        local Amount = tonumber(args[2])

        if OtherPassport and Amount then
            local Identity = vRP.Identity(OtherPassport)
            local Name = "Desconhecido"

            if Identity then
                Name = Identity.Name.." "..Identity.Lastname
            end

            vRP.UpgradeWeight(OtherPassport,Amount,"+")
            
            TriggerClientEvent("Notify",source,"sucesso","Você adicionou <b>"..Amount.."kg</b> para <b>"..Name.."</b> (ID: "..OtherPassport..").","verde",5000)
            
            local OtherSource = vRP.Source(OtherPassport)
            if OtherSource then
                TriggerClientEvent("Notify",OtherSource,"Aviso","Sua mochila foi aumentada em <b>"..Amount.."kg</b>.","amarelo",5000)
            end
        else
            TriggerClientEvent("Notify",source,"Aviso","Utilize: <b>/mochila [id] [quantidade]</b>","amarelo",5000)
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STATUSPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("statusplayer",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasPermission(Passport,"Admin",2) then
		return
	end

	local Predestinado = Message[1] and parseInt(Message[1]) or nil
	if not Predestinado or Predestinado <= 0 then
		TriggerClientEvent("Notify",source,"Atenção","Use: /statusplayer [ID]","amarelo",5000)
		return
	end

	local Identity = vRP.Identity(Predestinado)
	if not Identity then
		TriggerClientEvent("Notify",source,"Erro","Passaporte <b>"..Predestinado.."</b> não encontrado.","vermelho",5000)
		return
	end

	local PlayerName = vRP.FullName(Predestinado)
	local BankAmount = vRP.GetBank(Predestinado) or 0
	local CashAmount = vRP.ItemAmount(Predestinado,"dollar") or 0
	local TotalMoney = BankAmount + CashAmount

	local Vehicles = vRP.Query("vehicles/UserVehicles",{ Passport = Predestinado })
	local VehicleCount = Vehicles and #Vehicles or 0
	local PropertyCount = vRP.Scalar("propertys/Count",{ Passport = Predestinado }) or 0

	local License = Identity.License or vRP.License(Predestinado)
	local GemstoneAmount = 0
	if License then
		local Account = vRP.Account(License)
		if Account then
			GemstoneAmount = Account.Gemstone or 0
		end
	end

	local MessageText = string.format(
		"<b>Nome:</b> %s<br>"..
		"🆔 <b>ID Passaporte:</b> %d<br><br>"..
		"💵 <b>Dinheiro em Mãos:</b> $%s<br>"..
		"💰 <b>Dinheiro no Banco:</b> $%s<br>"..
		"💸 <b>Total de Dinheiro:</b> $%s<br><br>"..
		"🚗 <b>Total de Veículos:</b> %d<br>"..
		"🏠 <b>Total de Casas:</b> %d<br>"..
		"💎 <b>Gemas:</b> %s",
		PlayerName,
		Predestinado,
		Dotted(CashAmount),
		Dotted(BankAmount),
		Dotted(TotalMoney),
		VehicleCount,
		PropertyCount,
		Dotted(GemstoneAmount)
	)

	TriggerClientEvent("Notify",source,"Status Player",MessageText,"azul",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDGARAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("addgarage",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local MAX_SPAWNS = 20
	local GARAGE_OBJECT_HASH = "prop_offroad_tyres02"
	local VEHICLE_PREVIEW_HASH = "sultanrs"

	local GarageTypes = {
		{ Label = "Garage (Comum)", Value = "Garage|true" },
		{ Label = "Policia", Value = "Policia|false" },
		{ Label = "Paramedico", Value = "Paramedico|false" },
		{ Label = "Helicopters", Value = "Helicopters|false" },
		{ Label = "Boats", Value = "Boats|false" },
		{ Label = "Bikes", Value = "Bikes|false" },
		{ Label = "Trabalhos", Value = "Work|false" }
	}

	local MarkerTypes = {
		{ Label = "Marker 33 (Avião)", Value = 33 },
		{ Label = "Marker 34 (Helicóptero)", Value = 34 },
		{ Label = "Marker 35 (Barco)", Value = 35 },
		{ Label = "Marker 36 (Carro)", Value = 36 },
		{ Label = "Marker 37 (Moto)", Value = 37 },
		{ Label = "Marker 38 (Bike)", Value = 38 },
		{ Label = "Marker 39 (Caminhão)", Value = 39 }
	}

	local InteriorTypes = {
		{ Label = "Sem Interior", Value = "none" },
		{ Label = "Interior 1", Value = "01" },
		{ Label = "Interior 2", Value = "02" },
		{ Label = "Interior 3", Value = "03" },
		{ Label = "Interior 4", Value = "04" },
		{ Label = "Interior 5", Value = "05" }
	}

	local Permissions = Creative.GetPermissions()
	if not Permissions or #Permissions == 0 then
		TriggerClientEvent("Notify",source,"Erro","Nenhuma permissão encontrada.","vermelho",5000)
		return false
	end

	table.insert(Permissions, 1, { Label = "Sem Permissão (Pública)", Value = "none" })

	local Results = vKEYBOARD.Garages(source,GarageTypes,Permissions,MarkerTypes,InteriorTypes)
	
	if not Results or #Results < 3 or not Results[1] or not Results[2] or not Results[3] then
		return false
	end

	local GarageTypeData = Results[1]
	local SelectedMarker = Results[3]
	local SelectedInterior = Results[4]
	local GarageTypeSplit = {}
	for part in string.gmatch(GarageTypeData, "[^|]+") do
		table.insert(GarageTypeSplit, part)
	end
	
	if #GarageTypeSplit < 2 then
		TriggerClientEvent("Notify",source,"Erro","Formato de tipo de garagem inválido.","vermelho",5000)
		return false
	end
	
	local GarageType = GarageTypeSplit[1] or "Garage"
	local SavePosition = GarageTypeSplit[2] == "true"
	local Permission = Results[2]
	local MarkerId = tonumber(SelectedMarker) or 36

	if not GarageType or GarageType == "" then
		TriggerClientEvent("Notify",source,"Erro","Tipo de garagem inválido.","vermelho",5000)
		return false
	end

	TriggerClientEvent("Notify",source,"Aviso","Selecione o local da garagem (blip).","amarelo",5000)

	local Success,GarageCoords = vRPC.ObjectControlling(source,GARAGE_OBJECT_HASH)

	if not Success or not GarageCoords or type(GarageCoords) ~= "table" or #GarageCoords < 3 then
		TriggerClientEvent("Notify",source,"Aviso","Posicionamento do blip cancelado ou inválido.","vermelho",5000)
		vCLIENT.ClearGarageSpawns(source)
		return false
	end

	local Spawns = {}
	local AddingSpawns = true
	local SpawnCount = 0

	while AddingSpawns do
		SpawnCount = SpawnCount + 1
		
		if SpawnCount > MAX_SPAWNS then
			TriggerClientEvent("Notify",source,"Aviso",("Limite máximo de %d vagas atingido!"):format(MAX_SPAWNS),"amarelo",5000)
			AddingSpawns = false
			break
		end
		
		local HasSpawns = #Spawns > 0
		TriggerClientEvent("admin:GarageButtons",source,HasSpawns)

		local SuccessSpawn,SpawnCoords = vCLIENT.PositionGarageSpawn(source,VEHICLE_PREVIEW_HASH)

		if SuccessSpawn and SpawnCoords and type(SpawnCoords) == "table" and #SpawnCoords >= 4 then
			table.insert(Spawns,SpawnCoords)
			TriggerClientEvent("Notify",source,"Sucesso",("Vaga %d adicionada!"):format(SpawnCount),"verde",3000)
		else
			SpawnCount = SpawnCount - 1
			AddingSpawns = false
		end
	end

	if #Spawns == 0 then
		vCLIENT.ClearGarageSpawns(source)
		TriggerClientEvent("Notify",source,"Aviso","Nenhuma vaga adicionada. Cancelado.","vermelho",5000)
		return false
	end

	local SpawnLines = {}
	for i, coords in ipairs(Spawns) do
		local Line = string.format('\t\t\t["%d"] = { %.2f,%.2f,%.2f,%.2f }',
			i, coords[1], coords[2], coords[3] + 1, coords[4])
		if i < #Spawns then
			Line = Line .. ","
		end
		table.insert(SpawnLines, Line)
	end
	local SpawnText = table.concat(SpawnLines, "\n")

	local PermissionString = ""
	if Permission and Permission ~= "none" then
		if Permission == "custom" then
			PermissionString = 'Permission = "CUSTOM_PERMISSION"'
		else
			PermissionString = string.format('Permission = "%s"', Permission)
		end
	else
		PermissionString = string.format('Save = %s', SavePosition and "true" or "false")
	end

	local InteriorString = ""
	if SelectedInterior and SelectedInterior ~= "none" then
		InteriorString = string.format('\n\t\tInterior = "%s",', SelectedInterior)
	end

	local FullCode = string.format([[["ID"] = {
		Name = "%s",
		%s,
		Marker = %d,
		Coords = vec3(%.2f,%.2f,%.2f),%s
		Spawns = {
%s
		}
	},]],
		GarageType,
		PermissionString,
		MarkerId,
		GarageCoords[1], GarageCoords[2], GarageCoords[3] + 1,
		InteriorString,
		SpawnText
	)

	vKEYBOARD.Copy(source,"Código:",FullCode)
	TriggerClientEvent("Notify",source,"Sucesso",("Código gerado com %d vaga(s)!"):format(#Spawns),"verde",10000)
	
	vCLIENT.ClearGarageSpawns(source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDBED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("addbed",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local MAX_BEDS = 50

	local Beds = {}
	local AddingBeds = true
	local BedCount = 0

	TriggerClientEvent("Notify",source,"Aviso","Comece a adicionar macas. Pressione F para finalizar.","amarelo",5000)

	while AddingBeds do
		BedCount = BedCount + 1
		
		if BedCount > MAX_BEDS then
			TriggerClientEvent("Notify",source,"Aviso",("Limite máximo de %d macas atingido!"):format(MAX_BEDS),"amarelo",5000)
			AddingBeds = false
			break
		end
		
		local HasBeds = #Beds > 0
		TriggerClientEvent("admin:BedButtons",source,HasBeds)

		local SuccessBed,BedCoords = vCLIENT.PositionBed(source)

		if SuccessBed and BedCoords and type(BedCoords) == "table" and #BedCoords >= 4 then
			table.insert(Beds,{
				Coords = { BedCoords[1], BedCoords[2], BedCoords[3], BedCoords[4] }
			})
			
			TriggerClientEvent("Notify",source,"Sucesso",("Maca %d adicionada!"):format(BedCount),"verde",3000)
		else
			BedCount = BedCount - 1
			AddingBeds = false
		end
	end

	if #Beds == 0 then
		TriggerClientEvent("Notify",source,"Aviso","Nenhuma maca adicionada. Cancelado.","vermelho",5000)
		return false
	end

	local BedLines = {}
	for i, bed in ipairs(Beds) do
		local Line = string.format('\t{ Coords = vec4(%.2f,%.2f,%.2f,%.2f), Invert = 0.0 },',
			bed.Coords[1], bed.Coords[2], bed.Coords[3], bed.Coords[4])
		table.insert(BedLines, Line)
	end
	local BedText = table.concat(BedLines, "\n")

	local FullCode = string.format([[-- BEDS

%s]],
		BedText
	)

	vKEYBOARD.Copy(source,"Código:",FullCode)
	vCLIENT.ClearBedPreviews(source)
	TriggerClientEvent("Notify",source,"Sucesso",("Código gerado com %d maca(s)!"):format(#Beds),"verde",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDLSCUSTOMS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("addlscustoms",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Keyboard = vKEYBOARD.Secondary(source,"Nome da Logo (Ex: lscustoms.png)","Permissão (Opcional)")
	if not Keyboard or not Keyboard[1] then
		return false
	end

	local Logo = Keyboard[1]
	local Permission = Keyboard[2]
	local VEHICLE_PREVIEW_HASH = "sultanrs"
	local CollectedCoords = {}
	local Active = true
	local Count = 0

	TriggerClientEvent("Notify",source,"Aviso","Posicione o veículo e pressione H para confirmar. Pressione F ou ESC para finalizar.","amarelo",5000)

	while Active do
		Count = Count + 1
		local Success,Coords = vCLIENT.PositionGarageSpawn(source,VEHICLE_PREVIEW_HASH)

		if Success and Coords and #Coords >= 4 then
			table.insert(CollectedCoords, Coords)
			TriggerClientEvent("Notify",source,"Sucesso",("Local %d adicionado!"):format(Count),"verde",3000)
		else
			Active = false
		end
	end

	if #CollectedCoords > 0 then
		local Output = ""
		for _, Coords in ipairs(CollectedCoords) do
			Output = Output .. "	{\n"
			Output = Output .. string.format('		Logo = "%s",\n', Logo)
			
			if Permission and Permission ~= "" then
				Output = Output .. string.format('		Permission = "%s",\n', Permission)
			else
				Output = Output .. '		--Permission = "Mecanico",\n'
			end

			Output = Output .. string.format('		Coords = vec4(%.2f,%.2f,%.2f,%.2f)\n', Coords[1], Coords[2], Coords[3] + 1, Coords[4])
			Output = Output .. "	},\n"
		end

		vKEYBOARD.Copy(source,"Código LSCustoms:",Output)
		TriggerClientEvent("Notify",source,"Sucesso",("Código gerado com %d locais!"):format(#CollectedCoords),"verde",5000)
	else
		TriggerClientEvent("Notify",source,"Erro","Cancelado.","vermelho",5000)
	end

	vCLIENT.ClearGarageSpawns(source)
end)