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
Tunnel.bindInterface("fuelstations",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Division = {}
local Shipments = {}
local Permissions = {}
local CooldownUpdate = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Stations = exports.oxmysql:query_async("SELECT Permission,Name,Color,Blip FROM fuelstations_creative")
	if Stations and #Stations > 0 then
		for _,v in ipairs(Stations) do
			local Permission = v.Permission
			local Location = Locations[Permission]

			if Location then
				Location.Name = v.Name
				Location.Color = v.Color
				Location.Blip = v.Blip
			end
		end
	end

	while true do
		local CurrentTime = os.time()
		local Consult = exports.oxmysql:query_async("SELECT Permission FROM fuelstations_creative WHERE Empty > 0 AND Empty < ?",{ CurrentTime })
		if Consult and #Consult > 0 then
			for _,v in ipairs(Consult) do
				local Permission = v.Permission
				local Data = vRP.GetSrvData("Permissions:"..Permission,true)
				if Data then
					for Passport in pairs(Data) do
						local Source = vRP.Source(Passport)
						if Source then
							vRP.ServiceLeave(Source,Passport,Permission,true)
						end
					end

					vRP.RemSrvData("Permissions:"..Permission)
				end

				exports.oxmysql:update_async("DELETE FROM permissions WHERE Permission = ?",{ Permission })
				exports.oxmysql:update_async("DELETE FROM fuelstations_creative WHERE Permission = ?",{ Permission })

				local Location = Locations[Permission]
				if Location then
					Location.Name = Config.DefaulName
					Location.Color = Config.DefaultColor
					Location.Blip = Config.DefaultIcon
				end

				TriggerClientEvent("fuelstations:Blip",-1,Permission,Config.DefaulName,Config.DefaultColor,Config.DefaultIcon)
			end
		end

		Wait(600000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATIONS:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("fuelstations:Open")
AddEventHandler("fuelstations:Open",function(Permission)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if not Permission or type(Permission) ~= "string" then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Permission })
	if not Consult then
		local Location = Locations[Permission]
		if not Location then
			return false
		end

		local Price = Location.Price or 0
		local Name = Config.DefaulName or "Posto de Combustível"
		if not vRP.Request(source,Name,"Comprar o estabelecimento por <b>"..Currency..Dotted(Location.Price).."</b>?") then
			return false
		end

		if not vRP.PaymentFull(Passport,Price) then
			TriggerClientEvent("Notify",source,"Aviso","Dinheiro insuficiente.","amarelo",5000)
			return false
		end

		vRP.SetPermission(Passport,Permission,1)
		exports.oxmysql:insert_async("INSERT INTO fuelstations_creative (Permission,Name,Color,Blip,FuelPrice,Empty) VALUES (?,?,?,?,?,?)",{ Permission,Name,Config.DefaultColor,Config.DefaultIcon,Config.DefaultPricePerLiter,(os.time() + (Config.EmptyDaysStock * 86400)) })
	end

	if vRP.HasService(Passport,Permission) then
		Division[Passport] = Permission
		Permissions[Passport] = Config.OtherPermissions[Permission] or Config.Permissions
		TriggerClientEvent("fuelstations:Opened",source)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function HasPermission(Level,Permission)
	if not Permission or Permission == -1 then
		return false
	end

	if Permission == 0 then
		return true
	end

	return Level and Level <= Permission
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Player()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)

	return {
		MaxGroup = Groups[Departmenty].Max or 3,
		Hierarchy = Groups[Departmenty].Hierarchy,
		Player = {
			Level = Level,
			Passport = Passport,
			Name = vRP.FullName(Passport) or NameDefault
		},
		Permissions = {
			Stock = {
				View = HasPermission(Level,Permissions[Passport].Stock.View),
				Edit = HasPermission(Level,Permissions[Passport].Stock.Edit)
			},
			Replenishment = {
				View = HasPermission(Level,Permissions[Passport].Replenishment.View),
				Import = HasPermission(Level,Permissions[Passport].Replenishment.Import),
				Export = HasPermission(Level,Permissions[Passport].Replenishment.Export)
			},
			OfferJobs = {
				View = HasPermission(Level,Permissions[Passport].OfferJobs.View),
				Create = HasPermission(Level,Permissions[Passport].OfferJobs.Create),
				Edit = HasPermission(Level,Permissions[Passport].OfferJobs.Edit),
				Destroy = HasPermission(Level,Permissions[Passport].OfferJobs.Destroy)
			},
			Bank = {
				View = HasPermission(Level,Permissions[Passport].Bank.View),
				Deposit = HasPermission(Level,Permissions[Passport].Bank.Deposit),
				Withdraw = HasPermission(Level,Permissions[Passport].Bank.Withdraw),
				Transfer = HasPermission(Level,Permissions[Passport].Bank.Transfer)
			},
			Update = HasPermission(Level,Permissions[Passport].Update),
			Upgrades = HasPermission(Level,Permissions[Passport].Upgrades),
			Employees = {
				View = HasPermission(Level,Permissions[Passport].Employees.View),
				Create = HasPermission(Level,Permissions[Passport].Employees.Create),
				Edit = HasPermission(Level,Permissions[Passport].Employees.Edit),
				Dismiss = HasPermission(Level,Permissions[Passport].Employees.Dismiss)
			}
		}
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOME
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Home()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })

	return {
		Name = Consult.Name,
		Color = Consult.Color,
		Icon = Consult.Blip,
		Statistics = {
			MoneyEarned = Consult.MoneyEarned,
			MoneySpent = Consult.MoneySpent,
			FuelImported = Consult.FuelImported,
			Visits = Consult.Visits
		},
		Stock = Consult.Stock,
		MaxStock = Config.DefaultMaxStock
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if CooldownUpdate[Departmenty] and CooldownUpdate[Departmenty] > os.time() then
		TriggerClientEvent("fuelstations:Notify",source,"Negado","Tente novamente mais tarde.","vermelho")
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Update) then
		return false
	end

	exports.oxmysql:update_async("UPDATE fuelstations_creative SET Name = ?, Color = ?, Blip = ? WHERE Permission = ?",{ Data.Name,Data.Color,Data.Icon,Departmenty })
	TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Informações atualizadas.","verde")
	TriggerClientEvent("fuelstations:Blip",-1,Departmenty,Data.Name,Data.Color,Data.Icon)
	CooldownUpdate[Departmenty] = os.time() + 600
	Locations[Departmenty].Name = Data.Name
	Locations[Departmenty].Color = Data.Color
	Locations[Departmenty].Blip = Data.Icon

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Stock()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Stock.View) then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })

	return {
		Price = Consult.FuelPrice,
		MinPrice = Config.MinPricePerLiter,
		MaxPrice = Config.MaxPricePerLiter,
		Stock = Consult.Stock,
		MaxStock = Config.DefaultMaxStock
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATESTOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateStock(Price)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty or Price > Config.MaxPricePerLiter or Price < Config.MinPricePerLiter then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Stock.Edit) then
		return false
	end

	exports.oxmysql:update_async("UPDATE fuelstations_creative SET FuelPrice = ? WHERE Permission = ?",{ Price,Departmenty })
	TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Preço por litro atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Bank()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Table = {}
	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Permission = @Permission AND Timestamp >= UNIX_TIMESTAMP(DATE_SUB(NOW(),INTERVAL 30 DAY)) ORDER BY Timestamp DESC LIMIT 50",{ Permission = Departmenty })
	if Consult and #Consult > 0 then
		for _,v in pairs(Consult) do
			table.insert(Table,{
				Type = v.Type,
				Value = v.Value,
				Date = v.Timestamp,
				Player = {
					Passport = v.Passport,
					Name = vRP.FullName(v.Passport)
				},
				To = (v.Type ~= "Transfer" and nil or {
					Passport = v.Transfer,
					Name = vRP.FullName(v.Transfer)
				})
			})
		end
	end

	return { Balance = vRP.Permissions(Departmenty,"Bank"), Historical = Table }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPOSITBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DepositBank(Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.Deposit) then
		return false
	end

	Active[Passport] = true

	if vRP.PaymentBank(Passport,Value) then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Deposit", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Deposito realizado.","verde")
		vRP.PermissionsUpdate(Departmenty,"Bank","+",Value)
		Active[Passport] = nil

		return true
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WITHDRAWBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.WithdrawBank(Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.Withdraw) then
		return false
	end

	Active[Passport] = true

	if vRP.Permissions(Departmenty,"Bank") >= Value then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Withdraw", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Saque realizado.","verde")
		vRP.GiveBank(Passport,Value * Config.BankTaxWithdraw)
		vRP.PermissionsUpdate(Departmenty,"Bank","-",Value)
		Active[Passport] = nil

		return true
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFERBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TransferBank(OtherPassport,Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.Transfer) then
		return false
	end

	Active[Passport] = true

	local Identity = vRP.Identity(OtherPassport)
	if Identity and vRP.Permissions(Departmenty,"Bank") >= Value then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)",{ Type = "Transfer", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = OtherPassport, Permission = Departmenty })
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Transferência realizada.","verde")
		vRP.GiveBank(OtherPassport,Value * Config.BankTaxTransfer,true)
		vRP.PermissionsUpdate(Departmenty,"Bank","-",Value)
		Active[Passport] = nil

		return {
			Passport = OtherPassport,
			Name = Identity.Name.." "..Identity.Lastname
		}
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Replenishment()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	return Shipments[Passport]
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTSHIPMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.StartShipment(Index,Mode)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport or Active[Passport] or Shipments[Passport] then
		return false
	end

	local Departmenty = Division[Passport]
	if not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Replenishment[Mode]) then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Stock FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
	if not Consult then
		return false
	end

	local Select = Config.Replenishments[Index]
	if not Select then
		return false
	end

	if Mode == "Export" then
		TriggerClientEvent("fuelstations:Notify",source,"Negado","Indisponível no momento.","vermelho")
		return false
	end

	if Mode == "Import" then
		if vRP.Permissions(Departmenty,"Bank") < Select[Mode] then
			TriggerClientEvent("fuelstations:Notify",source,"Negado","Dinheiro insuficiente.","vermelho")
			return false
		end

		if (Consult.Stock + Select.Amount) > Config.DefaultMaxStock then
			TriggerClientEvent("fuelstations:Notify",source,"Negado","Estoque máximo atingido.","vermelho")
			return false
		end
	end

	local Location = Locations[Departmenty]
	if not Location or not Location.Packages or not Location.Delivery then
		TriggerClientEvent("fuelstations:Notify",source,"Erro","Local de entrega inválido.","vermelho")
		return false
	end

	Shipments[Passport] = { Permission = Departmenty, Index = Index, Mode = Mode }
	TriggerClientEvent("fuelstations:Init",source,{ Location.Packages[Select.Package],Location.Delivery })

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISHSHIPMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FinishShipment()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty or not Shipments[Passport] then
		return false
	end

	TriggerClientEvent("fuelstations:Finish",source)
	Shipments[Passport] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FuelStock(Permission)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport or not Permission then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Name,Stock,FuelPrice FROM fuelstations_creative WHERE Permission = ?",{ Permission })

	return {
		Name = Consult and Consult.Name or DefaulName,
		Stock = Consult and Consult.Stock or false,
		FuelPrice = Consult and Consult.FuelPrice or Config.DefaultPricePerLiter
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATIONS:GALLON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("fuelstations:Gallon")
AddEventHandler("fuelstations:Gallon",function(Permission)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permission then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Name,Stock,FuelPrice FROM fuelstations_creative WHERE Permission = ?",{ Permission })
	if Consult and Consult.Stock < Config.StockGallon then
		TriggerClientEvent("Notify",source,Consult.Name,"Combustível insuficiente.","amarelo",5000)
		return false
	end

	local WeightGallon = exports.vrp:ItemWeight(Config.ItemGallon)
	local WeightGallonFuel = exports.vrp:ItemWeight(Config.ItemGallonFuel)
	local TotalWeight = WeightGallon + (WeightGallonFuel * Config.StockGallon)
	if vRP.GetWeight(Passport) < TotalWeight then
		TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Não foi possível efetuar sua compra.","amarelo",5000)
		return false
	end

	local Price = (Consult and Consult.FuelPrice or Config.DefaultPricePerLiter) * Config.StockGallon
	local StationName = Consult and Consult.Name or Config.DefaultName
	local PriceText = string.format("%s%s",Currency,Dotted(Price))
	if not vRP.Request(source,StationName,"Deseja efetuar o pagamento de <b>"..PriceText.."</b>?") then
		return false
	end

	if not vRP.PaymentFull(Passport,Price) then
		TriggerClientEvent("Notify",source,StationName,"Você não possui dinheiro suficiente.","amarelo",5000)
		return false
	end

	if Consult then
		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = Stock - ? WHERE Permission = ?",{ Config.StockGallon,Permission })
		vRP.PermissionsUpdate(Permission,"Bank","+",Price)
	end

	vRP.GenerateItem(Passport,Config.ItemGallonFuel,Config.StockGallon * 100,true)
	vRP.GenerateItem(Passport,Config.ItemGallon,1,true)

	return true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EMPLOYEES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Employees()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return Table
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Employees.View) then
		return Table
	end

	local NumGroups = vRP.NumGroups(Departmenty)
	for OtherPassport,v in pairs(NumGroups) do
		local OtherPassport = parseInt(OtherPassport)
		local Identity = vRP.Identity(OtherPassport)
		if Identity then
			local Calculated = CompleteTimers(os.time() - (Identity.Login or 0),true)
			local Activated = (vRP.Source(OtherPassport) and "Ativo" or "Inativo").." a "..Calculated

			table.insert(Table,{
				Passport = OtherPassport,
				Name = Identity.Name.." "..Identity.Lastname,
				Hierarchy = v.Level,
				Status = Activated
			})
		else
			vRP.RemovePermission(OtherPassport,Departmenty)
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVITEEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InviteEmployee(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not OtherPassport or Passport == OtherPassport or not Departmenty then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource then
		TriggerClientEvent("fuelstations:Notify",source,"Atenção","Usuário indisponível no momento.","amarelo")

		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Name FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
	if not Consult then
		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	local Level = vRP.HasPermission(Passport,Departmenty)
	if not Identity or not HasPermission(Level,Permissions[Passport].Employees.Create) then
		return false
	end

	if vRP.AmountGroups(Departmenty) >= (Groups[Departmenty].Max or 3) then
		TriggerClientEvent("fuelstations:Notify",source,"Atenção","Limite de membros atingido.","amarelo")

		return false
	end

	if vRP.Request(OtherSource,Consult.Name,"Você foi convidado(a) para participar do <b>"..Consult.Name.."</b>, gostaria de participar do mesmo?") then
		vRP.SetPermission(OtherPassport,Departmenty)
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Passaporte adicionado.","verde")

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHYEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.HierarchyEmployee(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local Mode,OtherPassport = Table.Mode,Table.Passport

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	local MemberLevel = vRP.HasPermission(OtherPassport,Departmenty)
	if not MemberLevel or Passport == OtherPassport or not HasPermission(Level,Permissions[Passport].Employees.Edit) then
		return false
	end

	local Modify = (Mode == "Demote" and Level < MemberLevel and MemberLevel < #Groups[Departmenty].Hierarchy) or (Mode == "Promote" and MemberLevel > (Level + 1))
	if Modify then
		vRP.SetPermission(OtherPassport,Departmenty,nil,Mode)
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Membro "..(Mode == "Promote" and "promovido" or "rebaixado")..".","verde")

		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource then
			TriggerClientEvent("Notify",OtherSource,Departmenty,"Você foi <b>"..(Mode == "Promote" and "promovido" or "rebaixado").."</b> do seu cargo atual.","verde",10000)
		end

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMISSEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DismissEmployee(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Passport == OtherPassport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	local MemberLevel = vRP.HasPermission(OtherPassport,Departmenty)
	if MemberLevel and Level < MemberLevel and HasPermission(Level,Permissions[Passport].Employees.Dismiss) then
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Membro removido.","verde")
		vRP.RemovePermission(OtherPassport,Departmenty)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATESTOCK
-----------------------------------------------------------------------------------------------------------------------------------------
exports("UpdateStock",function(Permission,Stock,Mode,Price)
	if not Permission or not Stock or not Mode then
		return false
	end

	local Querys = {}
	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Permission })
	if not Consult then
		return false
	end

	if Mode == "+" then
		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = Stock + ?, Empty = 0 WHERE Permission = ?",{ Stock,Permission })
	elseif Mode == "-" then
		local Empty = (Consult.Stock - Stock <= 0)
		local EmptyTimer = Empty and (os.time() + (Config.EmptyDaysStock * 86400)) or Consult.Empty
		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = Stock - ?, Empty = ? WHERE Permission = ?",{ Stock,EmptyTimer,Permission })
	end

	if Price then
		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Visits = Visits + 1, MoneyEarned = MoneyEarned + ? WHERE Permission = ?",{ Price,Permission })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Shipments",function(Passport,source)
	local Shipment = Shipments[Passport]
	if not Shipment then
		return false
	end

	local Permission = Shipment.Permission
	local Index = Shipment.Index
	local Mode = Shipment.Mode

	if Mode == "Import" then
		local Replenishment = Config.Replenishments[Index]
		if not Replenishment or not Replenishment[Mode] or not Replenishment.Amount then
			Shipments[Passport] = nil
			return false
		end

		local Cost = Replenishment[Mode]
		local Amount = Replenishment.Amount
		if vRP.Permissions(Permission,"Bank") < Cost then
			Shipments[Passport] = nil
			return false
		end

		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = Stock + @Amount, FuelImported = FuelImported + @Amount, MoneySpent = MoneySpent + @Cost, Empty = 0 WHERE Permission = @Permission",{ Amount = Amount, Permission = Permission, Cost = Cost })
		TriggerClientEvent("Notify",source,Config.DefaulName,"Adicionado <b>"..Amount.."Lts</b> de combustível ao posto.","verde",5000)
		vRP.PermissionsUpdate(Permission,"Bank","-",Cost)
	end

	Shipments[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Payment()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	exports.fuelstations:Shipments(Passport,source)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFEROWNERSHIP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TransferOwnership(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or Passport == OtherPassport or not Departmenty or not vRP.HasPermission(Passport,Departmenty,1) then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource then
		TriggerClientEvent("fuelstations:Notify",source,"Aviso","Jogador indisponível no momento.","amarelo")
		return false
	end

	local Price = Locations[Departmenty].Price
	local GovernamentTax = Price + (Price * Config.TaxTransfer)
	if vRP.Request(OtherSource,Config.DefaulName,"Pagar <b>"..Currency..GovernamentTax.."</b> na compra do <b>"..Config.DefaulName.."</b>?") then
		if vRP.PaymentFull(OtherPassport,GovernamentTax,true) then
			vRP.GiveBank(Passport,Price,true)
			vRP.RemovePermission(Passport,Departmenty)
			vRP.SetPermission(OtherPassport,Departmenty,1)
			TriggerClientEvent("Notify",source,Config.DefaulName,"Transferência concluída.","verde",5000)

			return true
		else
			TriggerClientEvent("fuelstations:Notify",source,"Aviso","Jogador não possuí dinheiro suficiente.","amarelo")
			TriggerClientEvent("Notify",OtherSource,"Aviso","Dinheiro insuficiente.","amarelo")
		end
	else
		TriggerClientEvent("fuelstations:Notify",source,"Aviso","Proposta recusada.","vermelho")
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("fuelstations:Connect",source,Locations)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Active[Passport] then
		Active[Passport] = nil
	end

	if Division[Passport] then
		Division[Passport] = nil
	end

	if Permissions[Passport] then
		Permissions[Passport] = nil
	end

	if Shipments[Passport] then
		Shipments[Passport] = nil
	end
end)