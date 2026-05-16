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
Tunnel.bindInterface("garages",Creative)
vCLIENT = Tunnel.getInterface("garages")
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local Spawn = {}
local Active = {}
local Signal = {}
local Changed = {}
local Searched = {}
local Respawns = {}
local Propertys = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITYREMOVED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("entityRemoved",function(Entitys)
	if IsPedAPlayer(Entitys) or GetEntityType(Entitys) ~= 2 then
		return false
	end

	local Plate = GetVehicleNumberPlateText(Entitys)
	Plate = Changed[Plate] or Plate

	local Data = Spawn[Plate]
	if not Data then
		return false
	end

	local State = Entity(Entitys).state
	local Health = GetEntityHealth(Entitys)
	local Coords = GetEntityCoords(Entitys)
	local Heading = GetEntityHeading(Entitys)
	local Body = GetVehicleBodyHealth(Entitys)
	local Engine = GetVehicleEngineHealth(Entitys)

	local Windows = {}
	for Number = 0,5 do
		Windows[Number] = IsVehicleWindowIntact(Entitys,Number)
	end

	local VehicleCoords = vec4(Coords.x,Coords.y,Coords.z,Heading)
	Respawns[Plate] = VehicleCoords

	TriggerClientEvent("garages:Respawn",-1,"Add",Plate,VehicleCoords)

	vRP.Update("vehicles/updateVehiclesRespawns",{ Passport = Data[1], Vehicle = Data[2], Nitro = parseInt(State.Nitro) or 0, Engine = parseInt(Engine), Body = parseInt(Body), Health = parseInt(Health), Fuel = parseInt(State.Fuel) or 0, Windows = json.encode(Windows) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVERVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ServerVehicle(Model,Coords,Plate,Nitrox,Doors,Body,Fuel,Seatbelt,Drift)
	local CurrentTimer = os.time() + 10
	local Vehicle = CreateVehicle(Model,Coords,true,false)

	while not DoesEntityExist(Vehicle) or NetworkGetNetworkIdFromEntity(Vehicle) == 0 do
		if os.time() >= CurrentTimer then
			return false
		end

		Wait(100)
	end

	local State = Entity(Vehicle).state
	Plate = Plate or vRP.GeneratePlate()
	SetVehicleNumberPlateText(Vehicle,Plate)
	SetVehicleBodyHealth(Vehicle,(Body or 1000) + 0.0)

	if Doors then
		local Decoded = json.decode(Doors)
		if type(Decoded) == "table" then
			for Number,v in pairs(Decoded) do
				if v then
					SetVehicleDoorBroken(Vehicle,parseInt(Number),true)
				end
			end
		end
	end

	State:set("Nitro",Nitrox or 0,true)
	if (Nitrox or 0) > 0 then
		State:set("NitroType","normal",true)
	end
	State:set("Fuel",Fuel or 100.0,true)
	State:set("Drift",Drift or false,true)
	State:set("Seatbelt",Seatbelt or false,true)

	return true,NetworkGetNetworkIdFromEntity(Vehicle),Vehicle,Plate
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:RESPAWNS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Respawns")
AddEventHandler("garages:Respawns",function(Plate)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Spawn = Spawn[Plate]
	local Respawn = Respawns[Plate]
	if not (Respawn and Spawn and Spawn[1] == Passport) then
		return false
	end

	local OtherPassport,Model = Spawn[1],Spawn[2]
	local VehicleData = vRP.SelectVehicle(OtherPassport,Model)
	if not VehicleData then
		return false
	end

	local Mods = vRP.GetSrvData("LsCustoms:"..OtherPassport..":"..Model,true)
	local Exist,Network,Vehicle = Creative.ServerVehicle(Model,Respawn,Plate,VehicleData.Nitro,VehicleData.Doors,VehicleData.Body,VehicleData.Fuel,VehicleData.Seatbelt,VehicleData.Drift)

	if not Exist then
		return false
	end

	for _,OtherSource in pairs(vRPC.Players(source)) do
		async(function()
			vCLIENT.CreateVehicle(OtherSource,Model,Network,VehicleData.Engine,VehicleData.Health,Mods,VehicleData.Windows,VehicleData.Tyres)
		end)
	end

	Entity(Vehicle).state:set("Lockpick",OtherPassport,true)
	TaskWarpPedIntoVehicle(GetPlayerPed(source),Vehicle,-1)
	TriggerClientEvent("garages:Respawn",-1,"Remove",Plate)
	Spawn[Plate] = { OtherPassport,Model,Vehicle }
	Respawns[Plate] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:CHANGEPLATE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("garages:ChangePlate",function(Plate,NewPlate)
	Changed[NewPlate] = Plate
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SIGNALREMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SignalRemove",function(Plate)
	if not Signal[Plate] then
		Signal[Plate] = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Vehicles(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Garage = Garages[Number]
	if not Garage then
		return false
	end

	if Garage.Permission and not vRP.HasService(Passport,Garage.Permission) then
		return false
	end

	local Vehicles = {}
	local Selected = Garage.Name

	if Works[Selected] then
		for _,Model in pairs(Works[Selected]) do
			if VehicleExist(Model) then
				local TaxTimer,RentalTimer = false,false
				local Consult = vRP.SelectVehicle(Passport,Model)

				if Consult then
					if Consult.Tax > os.time() then
						TaxTimer = CompleteTimers(Consult.Tax - os.time())
					end

					if Consult.Rental ~= 0 then
						if Consult.Rental > os.time() then
							RentalTimer = CompleteTimers(Consult.Rental - os.time())
						else
							RentalTimer = "Vencido"
						end
					end

					table.insert(Vehicles,{
						Model = Model,
						Name = VehicleName(Model),
						Tax = VehiclePrice(Model) * 0.15,
						Mode = VehicleMode(Model),
						Weight = Consult.Weight,
						Engine = Consult.Engine / 10,
						Body = Consult.Body / 10,
						Fuel = Consult.Fuel,
						TaxTime = TaxTimer,
						RentalTime = RentalTimer
					})
				else
					table.insert(Vehicles,{
						Model = Model,
						Name = VehicleName(Model),
						Tax = VehiclePrice(Model) * 0.15,
						Mode = VehicleMode(Model),
						Weight = VehicleWeight(Model),
						Engine = 100,
						Body = 100,
						Fuel = 100,
						TaxTime = "30 Dias e 29 Horas",
						RentalTime = false
					})
				end
			end
		end
	else
		if string.sub(Number,1,9) == "Propertys" then
			local Consult = vRP.Query("propertys/Exist",{ Name = Number })
			local Property = Consult[1]
			if not Property then
				return false
			end

			local OwnerProperty = vRP.InventoryFull(Passport,"propertys-"..Property.Serial) or Property.Passport == Passport
			if not OwnerProperty or os.time() > Property.Tax then
				return false
			end
		end

		local Consult = vRP.Query("vehicles/UserVehicles",{ Passport = Passport })
		for _,v in pairs(Consult) do
			if VehicleExist(v.Vehicle) and not v.Work then
				local TaxTimer,RentalTimer = false,false

				if v.Tax > os.time() then
					TaxTimer = CompleteTimers(v.Tax - os.time())
				end

				if v.Rental ~= 0 then
					if v.Rental > os.time() then
						RentalTimer = CompleteTimers(v.Rental - os.time())
					else
						RentalTimer = "Vencido"
					end
				end

				table.insert(Vehicles,{
					Model = v.Vehicle,
					Name = VehicleName(v.Vehicle),
					Tax = VehiclePrice(v.Vehicle) * 0.15,
					Mode = VehicleMode(v.Vehicle),
					Weight = v.Weight,
					Engine = v.Engine / 10,
					Body = v.Body / 10,
					Fuel = v.Fuel,
					TaxTime = TaxTimer,
					RentalTime = RentalTimer
				})
			end
		end
	end

	return Vehicles
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:SELL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Sell")
AddEventHandler("garages:Sell",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Mode = VehicleMode(Name)
	local Class = VehicleClass(Name)
	if Mode == "Work" or Mode == "Rental" or Class == "Races" then
		return false
	end

	Active[Passport] = true
	TriggerClientEvent("garages:Close",source)

	local Price = VehiclePrice(Name) * 0.5
	local VehicleName = VehicleName(Name)
	local FormattedPrice = Dotted(Price)

	if vRP.Request(source,"Garagem","Vender o veículo <b>"..VehicleName.."</b> por <b>$"..FormattedPrice.."</b>?") then
		local Vehicle = vRP.SelectVehicle(Passport,Name)
		if Vehicle and not Vehicle.Block then
			vRP.GiveBank(Passport,Price)
			vRP.RemSrvData("LsCustoms:"..Passport..":"..Name)
			vRP.RemSrvData("Trunkchest:"..Passport..":"..Name)
			vRP.Query("vehicles/removeVehicles",{ Passport = Passport, Vehicle = Name })
			TriggerClientEvent("Notify",source,VehicleName,"Veículo vendido com sucesso.","verde",5000)
		end
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Transfer")
AddEventHandler("garages:Transfer",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Vehicle = vRP.SelectVehicle(Passport,Name)
	if not Vehicle or Vehicle.Block then
		return false
	end

	TriggerClientEvent("garages:Close",source)

	local Keyboard = vKEYBOARD.Primary(source,"Passaporte")
	if not Keyboard then
		return false
	end

	local OtherPassport = parseInt(Keyboard[1])
	if OtherPassport <= 0 or OtherPassport == Passport then
		TriggerClientEvent("Notify",source,"Negado","Passaporte inválido.","vermelho",5000)
		return false
	end

	local OtherName = vRP.FullName(OtherPassport) or "Desconhecido"
	if not vRP.Request(source,"Garagem","Transferir o veículo <b>"..VehicleName(Name).."</b> para <b>"..OtherName.."</b>?") then
		return false
	end

	if vRP.SelectVehicle(OtherPassport,Name) then
		TriggerClientEvent("Notify",source,"Atenção","<b>"..OtherName.."</b> já possui este modelo de veículo.","amarelo",5000)
		return false
	end

	vRP.Update("vehicles/moveVehicles",{ Passport = Passport, OtherPassport = OtherPassport, Vehicle = Name })

	local LsData = vRP.GetSrvData("LsCustoms:"..Passport..":"..Name,true)
	vRP.SetSrvData("LsCustoms:"..OtherPassport..":"..Name,LsData,true)
	vRP.RemSrvData("LsCustoms:"..Passport..":"..Name)

	local TrunkData = vRP.GetSrvData("Trunkchest:"..Passport..":"..Name,true)
	vRP.SetSrvData("Trunkchest:"..OtherPassport..":"..Name,TrunkData,true)
	vRP.RemSrvData("Trunkchest:"..Passport..":"..Name)

	TriggerClientEvent("Notify",source,"Sucesso","Transferência concluída para <b>"..OtherName.."</b>.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:TAX
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Tax")
AddEventHandler("garages:Tax",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Vehicle = vRP.SelectVehicle(Passport,Name)
	if not Vehicle or Vehicle.Tax > os.time() then
		return false
	end

	TriggerClientEvent("garages:Close",source)

	local Price = VehiclePrice(Name) * 0.15
	local VehicleName = VehicleName(Name)
	local FormattedPrice = Dotted(Price)

	if not vRP.Request(source,"Garagem","Pagar o <b>IPVA</b> do veículo <b>"..VehicleName.."</b> por <b>$"..FormattedPrice.."</b>?") then
		return false
	end

	if vRP.PaymentFull(Passport,Price) then
		vRP.Update("vehicles/updateVehiclesTax",{ Passport = Passport, Vehicle = Name })
		TriggerClientEvent("Notify",source,"Sucesso","Pagamento concluído.","verde",5000)
	else
		TriggerClientEvent("Notify",source,"Aviso","Dinheiro insuficiente.","amarelo",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Spawn")
AddEventHandler("garages:Spawn",function(Name,Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] or not VehicleExist(Name) then
		return false
	end

	Active[Passport] = true

	local Coin = "Diamantes"
	local Class = VehicleClass(Name)
	local Price = VehiclePrice(Name)
	local Gemstone = VehicleGemstone(Name)
	local Vehicle = vRP.SelectVehicle(Passport,Name)

	local function CancelProcess(Message)
		TriggerClientEvent("Notify",source,"Aviso",Message,"amarelo",5000)
		Active[Passport] = nil
		return false
	end

	if not Vehicle and Class ~= "Races" then
		if Gemstone > 0 then
			TriggerClientEvent("garages:Close",source)

			if Garages[Number] and Garages[Number].Platinum then
				Coin = "Platinas"
			end

			local Discount = 1.0
			if Coin == "Diamantes" then
				for k,v in pairs(Groups) do
					if v.Advantages and v.Advantages.VehiclePriceRate[Class] and vRP.HasService(Passport,k) then
						Discount = math.min(Discount,v.Advantages.VehiclePriceRate[Class])
					end
				end
			end

			local PaymentValue = (Coin == "Diamantes") and (Gemstone * Discount) or Gemstone
			if vRP.Request(source,"Garagem",("Pagar o aluguel do veículo <b>%s</b> por <b>%s</b> %s?"):format(VehicleName(Name),PaymentValue,Coin)) then
				if (Coin == "Diamantes" and not vRP.PaymentGems(Passport,PaymentValue)) or (Coin == "Platinas" and not vRP.TakeItem(Passport,"platinum",PaymentValue)) then
					return CancelProcess(Coin.." insuficiente.")
				end

				vRP.Query("vehicles/rentalVehicles",{ Passport = Passport, Vehicle = Name, Plate = vRP.GeneratePlate(), Days = 30, Weight = VehicleWeight(Name), Work = 1 })
				exports.discord:Embed("Vehicles","**[PASSAPORTE]:** "..Passport.."\n**[RENOVOU]:** "..Name.."\n**[VALOR]:** "..Dotted(PaymentValue).." "..Coin)
				TriggerClientEvent("Notify",source,"Sucesso","Aluguel do veículo <b>"..VehicleName(Name).."</b> concluído.","verde",5000)
				Vehicle = vRP.SelectVehicle(Passport,Name)
			else
				return CancelProcess("Processo cancelado.")
			end
		else
			if Price > 0 then
				TriggerClientEvent("garages:Close",source)

				if vRP.Request(source,"Garagem",("Comprar o veículo <b>%s</b> por <b>%s%s</b>?"):format(VehicleName(Name),Currency,Dotted(Price))) then
					if not vRP.PaymentFull(Passport,Price) then
						return CancelProcess("Dinheiro insuficiente.")
					end

					vRP.Query("vehicles/addVehicles",{ Passport = Passport, Vehicle = Name, Plate = vRP.GeneratePlate(), Weight = VehicleWeight(Name), Work = 1 })
					exports.discord:Embed("Vehicles","**[PASSAPORTE]:** "..Passport.."\n**[COMPROU]:** "..Name.."\n**[VALOR]:** "..Currency..Dotted(Price))
					exports.bank:AddTaxes(Passport,source,"Concessionária",Price,"Compra do veículo "..VehicleName(Name)..".")
					Vehicle = vRP.SelectVehicle(Passport,Name)
				else
					return CancelProcess("Processo cancelado.")
				end
			else
				vRP.Query("vehicles/addVehicles",{ Passport = Passport, Vehicle = Name, Plate = vRP.GeneratePlate(), Weight = VehicleWeight(Name), Work = 1 })
				Vehicle = vRP.SelectVehicle(Passport,Name)
			end
		end
	end

	if not Vehicle then
		Active[Passport] = nil
		return false
	end

	local Plate = Vehicle.Plate
	if Spawn[Plate] then
		if not Signal[Plate] then
			if os.time() >= (Searched[Passport] or 0) then
				Searched[Passport] = os.time() + 60

				if not Respawns[Plate] then
					if DoesEntityExist(Spawn[Plate][3]) and not IsPedAPlayer(Spawn[Plate][3]) and GetEntityType(Spawn[Plate][3]) == 2 then
						vCLIENT.SearchBlip(source,GetEntityCoords(Spawn[Plate][3]))
						TriggerClientEvent("Notify",source,"Atenção","Rastreador ativado por <b>30</b> segundos. A localização pode ser imprecisa se estiver em movimento.","policia",10000)
					else
						Spawn[Plate] = nil
						TriggerClientEvent("Notify",source,"Sucesso","Seguradora resgatou seu veículo. Já está disponível para retirada.","policia",5000)
					end
				else
					vCLIENT.SearchBlip(source,Respawns[Plate].xyz)
					TriggerClientEvent("Notify",source,"Atenção","Rastreador ativado por <b>30</b> segundos. A localização pode ser imprecisa se estiver em movimento.","policia",10000)
				end
			else
				TriggerClientEvent("Notify",source,"Aviso","Rastreador pode ser ativado a cada <b>60</b> segundos.","policia",5000)
			end
		else
			TriggerClientEvent("Notify",source,"Aviso","Rastreador está desativado.","policia",5000)
		end
	else
		local SaveGarage = Vehicle.Save
		if Number ~= SaveGarage then
			if Garages[SaveGarage] and Garages[Number] and Garages[Number].Save then
				TriggerClientEvent("Notify",source,"Aviso","O veículo não está neste local, mas será marcado no mapa por 30 segundos.","amarelo",5000)
				TriggerClientEvent("garages:Close",source)
				vCLIENT.SearchBlip(source,SaveGarage)

				if vRP.Request(source,"Garagem",("Resgatar o veículo custa <b>%s%s</b>, deseja prosseguir?"):format(Currency,Dotted(Price * 0.1))) then
					if not vRP.PaymentFull(Passport,Price * 0.1) then
						return CancelProcess("Dinheiro insuficiente.")
					end

					vRP.Update("vehicles/UpdateSave",{ Passport = Passport, Vehicle = Name, Save = Number })
					TriggerClientEvent("Notify",source,"Sucesso","Resgate concluído.","verde",5000)
				else
					return CancelProcess("Processo cancelado.")
				end
			else
				vRP.Update("vehicles/UpdateSave",{ Passport = Passport, Vehicle = Name, Save = Number })
			end
		end

		if Vehicle.Arrest then
			TriggerClientEvent("garages:Close",source)

			if vRP.Request(source,"Garagem",("Liberar veículo custa <b>%s%s</b>, deseja prosseguir?"):format(Currency,Dotted(Price * 0.1))) then
				if not vRP.PaymentFull(Passport,Price * 0.1) then
					return CancelProcess("Dinheiro insuficiente.")
				end

				vRP.Update("vehicles/PaymentArrest",{ Passport = Passport, Vehicle = Name })
				exports.bank:AddTaxes(Passport,source,"Garagem",Price,"Liberação do veículo.")
				TriggerClientEvent("Notify",source,"Sucesso","Veículo liberado.","policia",10000)
			else
				return CancelProcess("Processo cancelado.")
			end
		end

		if Vehicle.Tax <= os.time() then
			TriggerClientEvent("garages:Close",source)

			if vRP.Request(source,"Garagem",("Pagar a taxa do veículo <b>%s</b> por <b>%s%s</b>?"):format(VehicleName(Name),Currency,Dotted(Price * 0.15))) then
				if not vRP.PaymentFull(Passport,Price * 0.15) then
					return CancelProcess("Dinheiro insuficiente.")
				end

				vRP.Update("vehicles/updateVehiclesTax",{ Passport = Passport, Vehicle = Name })
				TriggerClientEvent("Notify",source,"Sucesso","Pagamento concluído.","verde",5000)
			else
				return CancelProcess("Processo cancelado.")
			end
		end

		if Gemstone > 0 and Vehicle.Rental ~= 0 and Vehicle.Rental <= os.time() then
			TriggerClientEvent("garages:Close",source)

			if Garages[Number] and Garages[Number].Platinum then
				Coin = "Platinas"
			end

			local Discount = 1.0
			if Coin == "Diamantes" then
				for k,v in pairs(Groups) do
					if v.Advantages and v.Advantages.VehiclePriceRate[Class] and vRP.HasService(Passport,k) then
						Discount = math.min(Discount,v.Advantages.VehiclePriceRate[Class])
					end
				end
			end

			local PaymentValue = (Coin == "Diamantes") and (Gemstone * Discount) or Gemstone
			if vRP.Request(source,"Garagem",("Pagar aluguel do veículo <b>%s</b> por <b>%s %s</b>?"):format(VehicleName(Name),Dotted(PaymentValue),Coin)) then
				if (Coin == "Diamantes" and vRP.PaymentGems(Passport,PaymentValue)) or (Coin == "Platinas" and vRP.TakeItem(Passport,"platinum",PaymentValue)) then
					vRP.Update("vehicles/rentalVehiclesUpdate",{ Passport = Passport, Vehicle = Name, Days = 30 })
					TriggerClientEvent("Notify",source,"Sucesso","Aluguel do veículo <b>"..VehicleName(Name).."</b> atualizado.","verde",5000)
					exports.discord:Embed("Vehicles","**[PASSAPORTE]:** "..Passport.."\n**[RENOVOU]:** "..Name.."\n**[VALOR]:** "..Dotted(PaymentValue).." "..Coin)
				else
					return CancelProcess(Coin.." insuficiente.")
				end
			else
				return CancelProcess("Processo cancelado.")
			end
		end

		local Coords = vCLIENT.SpawnPosition(source,Number)
		if Coords then
			local Mods = vRP.GetSrvData("LsCustoms:"..Passport..":"..Name,true)
			local Exist,Network,Entitys = Creative.ServerVehicle(Name,Coords,Plate,Vehicle.Nitro,Vehicle.Doors,Vehicle.Body,Vehicle.Fuel,Vehicle.Seatbelt,Vehicle.Drift)
			if Exist then
				for _,OtherSource in pairs(vRPC.Players(source)) do
					async(function()
						vCLIENT.CreateVehicle(OtherSource,Name,Network,Vehicle.Engine,Vehicle.Health,Mods,Vehicle.Windows,Vehicle.Tyres)
					end)
				end

				Entity(Entitys).state:set("Lockpick",Passport,true)
				Spawn[Plate] = { Passport,Name,Entitys }
			end
		end
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("car",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") or not Message[1] then
		return false
	end

	local Model = Message[1]
	local Ped = GetPlayerPed(source)
	local Coords = GetEntityCoords(Ped)
	local Heading = GetEntityHeading(Ped)
	local Plate = "VEH"..(10000 + Passport)

	local Exist,Network,Vehicle = Creative.ServerVehicle(Model,vec4(Coords.x,Coords.y,Coords.z,Heading),Plate,2000,nil,1000,100,true,false)
	if not Exist then
		return false
	end

	for _,OtherSource in pairs(vRPC.Players(source)) do
		async(function()
			vCLIENT.CreateVehicle(OtherSource,Model,Network,1000,1000,nil,false,false,false)
		end)
	end

	Entity(Vehicle).state:set("Lockpick",Passport,true)
	Spawn[Plate] = { Passport,Model,Vehicle }
	TaskWarpPedIntoVehicle(Ped,Vehicle,-1)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DV
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("dv",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	TriggerClientEvent("garages:Delete",source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:KEY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Key")
AddEventHandler("garages:Key",function(entityData)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Plate = entityData[1]
	local Network = entityData[4]
	local Entitys = NetworkGetEntityFromNetworkId(Network)
	if not DoesEntityExist(Entitys) then
		return false
	end

	local State = Entity(Entitys).state
	if State and State.Lockpick == Passport then
		vRP.GiveItem(Passport,"vehiclekey-"..os.time().."-"..Plate,1,true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:LOCK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Lock")
AddEventHandler("garages:Lock",function(Network)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Entitys = NetworkGetEntityFromNetworkId(Network)
	if not DoesEntityExist(Entitys) then
		return false
	end

	local State = Entity(Entitys).state
	if State and State.Lockpick == Passport then
		TriggerEvent("garages:LockVehicle",source,Network)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:LOCKVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("garages:LockVehicle",function(source,Network)
	local Vehicle = NetworkGetEntityFromNetworkId(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	local DoorStatus = tonumber(GetVehicleDoorLockStatus(Vehicle)) or 0

	if DoorStatus <= 1 then
		TriggerClientEvent("Notify",source,"Aviso","Veículo trancado.","verde",5000)
		TriggerClientEvent("sounds:Private",source,"locked",0.5)
		SetVehicleDoorsLocked(Vehicle,2)
	else
		TriggerClientEvent("Notify",source,"Aviso","Veículo destrancado.","amarelo",5000)
		TriggerClientEvent("sounds:Private",source,"unlocked",0.5)
		SetVehicleDoorsLocked(Vehicle,1)
	end

	if not vRP.InsideVehicle(source) then
		vRPC.playAnim(source,true,{"anim@mp_player_intmenu@key_fob@","fob_click_fp"},false)
		Wait(350)
		vRPC.stopAnim(source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Delete(Network,Doors,Tyres,Plate,Save)
	local Networked = NetworkGetEntityFromNetworkId(Network)
	if not DoesEntityExist(Networked) or IsPedAPlayer(Networked) or GetEntityType(Networked) ~= 2 or GetVehicleNumberPlateText(Networked) ~= Plate then
		return false
	end

	local Primary = Changed[Plate] and Plate or false
	if Primary then
		Plate = Changed[Plate]
	end

	if Spawn[Plate] then
		local Name = Spawn[Plate][2]
		local Passport = Spawn[Plate][1]
		if vRP.SelectVehicle(Passport,Name) then
			local Health = GetEntityHealth(Networked)
			local Body = GetVehicleBodyHealth(Networked)
			local Engine = GetVehicleEngineHealth(Networked)

			local Windows = {}
			for Number = 0,5 do
				Windows[Number] = IsVehicleWindowIntact(Networked,Number)
			end

			local State = Entity(Networked).state
			local Nitro = State.Nitro or 0
			local Fuel = State.Fuel or 0

			local DoorsJson = json.encode(Doors)
			local WindowsJson = json.encode(Windows)
			local TyresJson = json.encode(Tyres)

			if VehicleMode(Name) ~= "Work" and Save and Garages[Save] and Garages[Save].Name == "Garage" then
				vRP.Update("vehicles/updateVehiclesSave",{ Passport = Passport, Vehicle = Name, Nitro = Nitro, Engine = math.floor(Engine), Body = math.floor(Body), Health = math.floor(Health), Fuel = Fuel, Doors = DoorsJson, Windows = WindowsJson, Tyres = TyresJson, Save = Save })
			else
				vRP.Update("vehicles/updateVehicles",{ Passport = Passport, Vehicle = Name, Nitro = Nitro, Engine = math.floor(Engine), Body = math.floor(Body), Health = math.floor(Health), Fuel = Fuel, Doors = DoorsJson, Windows = WindowsJson, Tyres = TyresJson })
			end
		end
	end

	TriggerEvent("garages:Delete",Network,Plate)

	if Primary then
		TriggerEvent("garages:Delete",Network,Primary)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:DELETED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Deleted")
AddEventHandler("garages:Deleted",function(Network,Plate)
	Creative.Delete(Network,{},{},Plate)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Delete")
AddEventHandler("garages:Delete",function(Network,Plate)
	if not Network or not Plate then
		return false
	end

	if Signal[Plate] then
		Signal[Plate] = nil
	end

	if Changed[Plate] then
		local Backup = Changed[Plate]
		if Spawn[Backup] then
			Spawn[Backup] = nil
		end

		Changed[Plate] = nil
	end

	if Spawn[Plate] then
		Spawn[Plate] = nil
	end

	local Entitys = NetworkGetEntityFromNetworkId(Network)
	if DoesEntityExist(Entitys) and not IsPedAPlayer(Entitys) and GetEntityType(Entitys) == 2 and GetVehicleNumberPlateText(Entitys) == Plate then
		DeleteEntity(Entitys)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:PROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Propertys")
AddEventHandler("garages:Propertys",function(Name)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Name })
	if not Consult or Consult.Passport ~= Passport then
		return false
	end

	Active[Passport] = true

	TriggerClientEvent("dynamic:Close",source)
	TriggerClientEvent("Notify",source,"Aviso","Selecione o local da garagem.","amarelo",5000)

	local Hash = "prop_offroad_tyres02"
	local Sucess,GarageCoords = vRPC.ObjectControlling(source,Hash)
	if not Sucess then
		Active[Passport] = nil
		return false
	end

	local PropertyCoords = exports.propertys:Coords(Name)
	if #(vec3(GarageCoords[1],GarageCoords[2],GarageCoords[3]) - PropertyCoords) > 25 then
		TriggerClientEvent("Notify",source,"Aviso","A garagem precisa ser próximo da entrada.","amarelo",5000)
		Active[Passport] = nil
		return false
	end

	TriggerClientEvent("Notify",source,"Aviso","Selecione o local do veículo.","amarelo",5000)

	local VehicleHash = "sultanrs"
	local Sucess,VehicleCoords = vRPC.ObjectControlling(source,VehicleHash)
	if not Sucess then
		Active[Passport] = nil
		return false
	end

	if #(vec3(VehicleCoords[1],VehicleCoords[2],VehicleCoords[3]) - PropertyCoords) > 25 then
		TriggerClientEvent("Notify",source,"Aviso","A garagem precisa ser próximo da entrada.","amarelo",5000)
		Active[Passport] = nil
		return false
	end

	local NewGarage = {
		Coords = { GarageCoords[1],GarageCoords[2],GarageCoords[3] + 1 },
		Spawn = { VehicleCoords[1],VehicleCoords[2],VehicleCoords[3] + 1,VehicleCoords[4] }
	}

	Garages[Name] = { Name = "Garage", Save = true }
	Propertys[Name] = {
		Coords = vec3(NewGarage.Coords[1],NewGarage.Coords[2],NewGarage.Coords[3]),
		Spawns = {
			["1"] = NewGarage.Spawn
		}
	}

	vRP.Update("propertys/Garage",{ Name = Name, Garage = json.encode(NewGarage) })
	TriggerClientEvent("garages:Propertys",-1,Propertys)

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for _,v in pairs(vRP.Query("propertys/Garages")) do
		if not Propertys[v.Name] and v.Garage then
			local GarageData = json.decode(v.Garage)
			if GarageData and GarageData.Coords and GarageData.Spawn then
				Garages[v.Name] = { Name = "Garage", Save = true }
				Propertys[v.Name] = {
					Coords = vec3(GarageData.Coords[1],GarageData.Coords[2],GarageData.Coords[3]),
					Spawns = {
						["1"] = GarageData.Spawn
					}
				}
			end
		end
	end

	local Additional = 1296000
	local CurrentTimer = os.time()
	for _,v in ipairs(vRP.Query("vehicles/All")) do
		if (v.Tax + Additional) <= CurrentTimer then
			vRP.Query("entitydata/RemoveData",{ Name = "Mods:"..v.Passport..":"..v.Vehicle })
			vRP.Query("vehicles/removeVehicles",{ Passport = v.Passport, Vehicle = v.Vehicle })
			vRP.Query("entitydata/RemoveData",{ Name = "Trunkchest:"..v.Passport..":"..v.Vehicle })

			Wait(100)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SIGNAL
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Signal",function(Plate)
	return Signal[Plate]
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Spawn",function(Plate)
	return Spawn[Plate]
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("garages:Propertys",source,Propertys,Respawns)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if Active[Passport] then
		Active[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITYCREATING
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("entityCreating",function(Entity)
	if DoesEntityExist(Entity) and GetEntityType(Entity) == 2 then
		SetVehicleDoorsLocked(Entity,2)
	end
end)