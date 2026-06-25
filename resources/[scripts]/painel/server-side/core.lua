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
Tunnel.bindInterface("painel",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Division = {}
local Permissions = {}
local LastResetDay = nil
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEFAULTPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
local DefaultPermissions = {
	Management = {
		View = false,
		Create = false,
		Dismiss = false,
		Edit = false
	},
	Announcements = {
		Create = false,
		Edit = false,
		Delete = false
	},
	Tags = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false,
		Assign = false
	},
	Bank = {
		View = false,
		Deposit = false,
		Withdraw = false,
		Transfer = false
	},
	Goals = {
		MyGoals = false,
		All = false,
		Edit = false
	},
	Perks = false
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAINEL:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("painel:Open")
AddEventHandler("painel:Open",function(Permission)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Level = vRP.HasService(Passport,Permission)
	if not Level then
		return false
	end

	local Consult = {}
	local Levels = tostring(Level)

	if Level == 1 then
		local Leader = {}
		for Index,Value in pairs(DefaultPermissions) do
			if type(Value) == "table" then
				Leader[Index] = {}

				for Parent in pairs(Value) do
					Leader[Index][Parent] = true
				end
			else
				Leader[Index] = true
			end
		end

		Consult[Levels] = Leader
	else
		Consult = vRP.GetSrvData("Painel:"..Permission,true)
	end

	Division[Passport] = Permission
	Permissions[Passport] = Consult[Levels] or DefaultPermissions

	TriggerClientEvent("painel:Opened",source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPARTMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Department()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	return Passport and Departmenty
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

	return {
		Player = {
			Passport = Passport,
			Name = Player(source).state.Name,
			Level = vRP.HasPermission(Passport,Departmenty)
		},
		Group = Departmenty,
		Permissions = Permissions[Passport],
		Disabled = Config.Disabled[Departmenty] or {}
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCHUSER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SearchUser(Search)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	if type(Search) == "number" then
		local Identity = vRP.Identity(Search)
		if Identity then
			table.insert(Table,{
				Passport = Search,
				Name = Identity.Name.." "..Identity.Lastname
			})
		end
	else
		local Consult = exports.oxmysql:query_async("SELECT id,CONCAT(Name,' ',Lastname) AS FullName FROM characters WHERE Name LIKE CONCAT('%',@Search,'%') OR Lastname LIKE CONCAT('%',@Search,'%') LIMIT 10",{ Search = Search })
		if Consult and #Consult > 0 then
			for _,v in ipairs(Consult) do
				local Identity = vRP.Identity(v.id)
				if Identity then
					table.insert(Table,{
						Passport = v.id,
						Name = Identity.Name.." "..Identity.Lastname
					})
				end
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MEMBERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Members(Ranking)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return Table
	end

	local NumGroups = vRP.NumGroups(Departmenty)
	local Max = vRP.Permissions(Departmenty,"Members")
	local Tags = exports.oxmysql:query_async("SELECT * FROM painel_creative_tags WHERE Permission = @Permission",{ Permission = Departmenty })

	for OtherPassport,v in pairs(NumGroups) do
		local OtherPassport = parseInt(OtherPassport)
		local Identity = vRP.Identity(OtherPassport)
		if Identity then
			local TablePlayer = {
				Passport = OtherPassport,
				Name = Identity.Name.." "..Identity.Lastname,
				Hierarchy = v.Level,
				Tags = {}
			}

			if Ranking then
				TablePlayer.Hours = vRP.Playing(OtherPassport,v.Permission)
			else
				local Calculated = CompleteTimers(os.time() - (Identity.Login or 0),true)
				local Activated = (vRP.Source(OtherPassport) and "Ativo" or "Inativo").." a "..Calculated

				TablePlayer.Status = Activated
				TablePlayer.Service = vRP.HasService(OtherPassport,v.Permission)
			end

			if Tags and #Tags > 0 then
				for _,Tag in pairs(Tags) do
					local Members = json.decode(Tag.Members)
					if Contains(Members,TablePlayer.Passport) then
						table.insert(TablePlayer.Tags,{ Name = Tag.Name, Image = Tag.Image })
					end
				end
			end

			table.insert(Table,TablePlayer)
		else
			vRP.RemovePermission(OtherPassport,Departmenty)
		end
	end

	return { Members = Table, Max = Max }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAGS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Tags()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	if not Permissions[Passport].Tags.View then
		return Table
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_tags WHERE Permission = @Permission ORDER BY Name ASC",{ Permission = Departmenty })
	if Consult and #Consult > 0 then
		for _,v in ipairs(Consult) do
			table.insert(Table,{
				Id = v.id,
				Image = v.Image,
				Name = v.Name,
				Members = #json.decode(v.Members)
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETTAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetTag(Number)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	if not Permissions[Passport].Tags.View then
		return Table
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM painel_creative_tags WHERE id = @Number",{ Number = Number })
	if Consult then
		Table = {
			Id = Consult.id,
			Image = Consult.Image,
			Name = Consult.Name,
			Members = {}
		}

		if Consult.Members then
			local Members = json.decode(Consult.Members)
			for _,v in pairs(Members) do
				table.insert(Table.Members,{
					Passport = v,
					Name = vRP.FullName(v)
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATETAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateTag(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if exports.oxmysql:scalar_async("SELECT COUNT(Permission) FROM painel_creative_tags WHERE Permission = @Permission",{ Permission = Departmenty }) >= vRP.Permissions(Departmenty,"Tags") then
		TriggerClientEvent("painel:Notify",source,"Atenção","Limite de tags atingido.","amarelo")

		return false
	end

	if not Permissions[Passport].Tags.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO painel_creative_tags (Name,Image,Permission) VALUES (@Name,@Image,@Permission)",{ Name = Table.Name, Image = Table.Image, Permission = Departmenty })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag criada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATETAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateTag(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Tags.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE painel_creative_tags SET Name = @Name, Image = @Image WHERE id = @Id",{ Id = Table.Id, Name = Table.Name, Image = Table.Image })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYTAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyTag(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Tags.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM painel_creative_tags WHERE id = @id",{ id = Number })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag removida.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSIGNTAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssignTag(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not Table.Passport or not vRP.HasService(Passport,Departmenty) or not vRP.HasPermission(Table.Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Tags.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Members,Name FROM painel_creative_tags WHERE id = @Number",{ Number = Table.Id })
	if Consult and Consult.Members then
		local Members = json.decode(Consult.Members)
		for _,v in ipairs(Members) do
			if Table.Passport == v then
				return false
			end
		end

		table.insert(Members,Table.Passport)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Tag atribuida.","verde")
		exports.oxmysql:update_async("UPDATE painel_creative_tags SET Members = @Members WHERE id = @Id",{ Id = Table.Id, Members = json.encode(Members) })

		local OtherSource = vRP.Source(Table.Passport)
		if OtherSource then
			TriggerClientEvent("Notify",OtherSource,Consult.Name,"Parabéns você recebeu uma tag.","verde",10000)
		end

		return { Passport = Table.Passport, Name = vRP.FullName(Table.Passport) }
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVETAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveTag(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Tags.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Members FROM painel_creative_tags WHERE id = @Number",{ Number = Table.Id })
	if Consult and Consult.Members then
		local Members = json.decode(Consult.Members)
		for Index,v in ipairs(Members) do
			if Table.Passport == v then
				table.remove(Members,Index)
				TriggerClientEvent("painel:Notify",source,"Sucesso","Tag removida.","verde")
				exports.oxmysql:update_async("UPDATE painel_creative_tags SET Members = @Members WHERE id = @Id",{ Id = Table.Id, Members = json.encode(Members) })

				return true
			end
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVITE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Invite(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not OtherPassport or Passport == OtherPassport or not Departmenty then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource then
		TriggerClientEvent("painel:Notify",source,"Atenção","Usuário indisponível no momento.","amarelo")

		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	if not Identity or not Permissions[Passport].Management.Create then
		return false
	end

	if vRP.AmountGroups(Departmenty) >= vRP.Permissions(Departmenty,"Members") then
		TriggerClientEvent("painel:Notify",source,"Atenção","Limite de membros atingido.","amarelo")

		return false
	end

	if Groups[Departmenty].Type and vRP.GetUserType(OtherPassport,Groups[Departmenty].Type) then
		TriggerClientEvent("painel:Notify",source,"Atenção","O passaporte já pertence a outro grupo.","amarelo")

		return false
	end

	if vRP.Request(OtherSource,"Grupos","Você foi convidado(a) para participar do grupo <b>"..Departmenty.."</b>, gostaria de estar entrando no mesmo?") then
		vRP.SetPermission(OtherPassport,Departmenty)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Passaporte adicionado.","verde")
		exports.discord:Embed("Painel","**[MODO]:** Convidou\n**[PERMISSÃO]:** "..Departmenty.."\n**[PASSAPORTE]:** "..Passport.."\n**[MEMBRO]:** "..OtherPassport)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Hierarchy(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local Mode,OtherPassport = Table.Mode,Table.Passport

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	local MemberLevel = vRP.HasPermission(OtherPassport,Departmenty)
	if not MemberLevel or Passport == OtherPassport or not Permissions[Passport].Management.Edit then
		return false
	end

	local Modify = (Mode == "Demote" and Level < MemberLevel and MemberLevel < #Groups[Departmenty].Hierarchy) or (Mode == "Promote" and MemberLevel > (Level + 1))
	if Modify then
		vRP.SetPermission(OtherPassport,Departmenty,nil,Mode)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Membro "..(Mode == "Promote" and "promovido" or "rebaixado")..".","verde")

		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource then
			TriggerClientEvent("Notify",OtherSource,Departmenty,"Você foi <b>"..(Mode == "Promote" and "promovido" or "rebaixado").."</b> do seu cargo atual.","verde",10000)
		end

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMISS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Dismiss(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Passport == OtherPassport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	local MemberLevel = vRP.HasPermission(OtherPassport,Departmenty)
	if MemberLevel and Level < MemberLevel and Permissions[Passport].Management.Dismiss then
		exports.discord:Embed("Painel","**[MODO]:** Removeu\n**[PERMISSÃO]:** "..Departmenty.."\n**[PASSAPORTE]:** "..Passport.."\n**[MEMBRO]:** "..OtherPassport)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Membro removido.","verde")
		vRP.RemovePermission(OtherPassport,Departmenty)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANNOUNCEMENTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Announcements()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Passport == OtherPassport or not Departmenty then
		return Table
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_announcements WHERE Permission = @Permission ORDER BY Timestamp DESC",{ Permission = Departmenty })
	if Consult and #Consult > 0 then
		for _,v in pairs(Consult) do
			table.insert(Table,{
				Id = v.id,
				Title = v.Title,
				Date = v.Timestamp,
				Description = v.Description,
				Updated = v.Updated
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEANNOUNCEMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateAnnouncement(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Announcements.Create then
		return false
	end

	if exports.oxmysql:scalar_async("SELECT COUNT(Permission) FROM painel_creative_announcements WHERE Permission = @Permission",{ Permission = Departmenty }) >= vRP.Permissions(Departmenty,"Announces") then
		TriggerClientEvent("painel:Notify",source,"Atenção","Limite de avisos atingido.","amarelo")

		return false
	end

	local Number = exports.oxmysql:insert_async("INSERT INTO painel_creative_announcements (Title,Description,Timestamp,Permission) VALUES (@Title,@Description,@Timestamp,@Permission)",{ Title = Table.Title, Description = Table.Description, Timestamp = os.time(), Permission = Departmenty })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Aviso criado.","verde")

	return Number
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEANNOUNCEMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateAnnouncement(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Announcements.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE painel_creative_announcements SET Title = @Title, Description = @Description, Updated = @Updated WHERE id = @Number",{ Number = Table.Id, Title = Table.Title, Description = Table.Description, Updated = os.time() })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Aviso atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYANNOUNCEMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyAnnouncement(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Announcements.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM painel_creative_announcements WHERE id = @Number",{ Number = Number })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Aviso removido.","verde")

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

	if not Permissions[Passport].Bank.Deposit then
		return false
	end

	Active[Passport] = true

	if vRP.PaymentBank(Passport,Value) then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Deposit", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
		TriggerClientEvent("painel:Notify",source,"Sucesso","Deposito realizado.","verde")
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

	if not Permissions[Passport].Bank.Withdraw then
		return false
	end

	Active[Passport] = true

	if vRP.Permissions(Departmenty,"Bank") >= Value then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Withdraw", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
		TriggerClientEvent("painel:Notify",source,"Sucesso","Saque realizado.","verde")
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

	if not Permissions[Passport].Bank.Transfer then
		return false
	end

	Active[Passport] = true

	local Identity = vRP.Identity(OtherPassport)
	if Identity and vRP.Permissions(Departmenty,"Bank") >= Value then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)",{ Type = "Transfer", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = OtherPassport, Permission = Departmenty })
		TriggerClientEvent("painel:Notify",source,"Sucesso","Transferência realizada.","verde")
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
-- PERKS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Perks()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	local Perks = {}
	for _,v in pairs(Config.Perks) do
		local Price = v.Price
		local Activated = false
		local Description = v.Description

		if v.Type == "Members" then
			local Members = vRP.Permissions(Departmenty,"Members")
			Activated = Groups[Departmenty].Max and Members >= Groups[Departmenty].Max

			if type(Price) == "table" then
				Price = Price[Members + 1] or Price[#Price]
			end
		elseif v.Type == "Premium" then
			local CurrentTimer = vRP.Permissions(Departmenty,"Premium")

			Activated = CurrentTimer > os.time()
			if Activated then
				Description = "Os benefícios ainda vão durar "..CompleteTimers(CurrentTimer - os.time())
			end
		end

		table.insert(Perks, {
			Price = Price,
			Title = v.Title,
			Active = Activated,
			Description = Description,
			Image = v.Image
		})
	end

	return {
		Levels = TableLevelPainel(),
		Xp = vRP.Permissions(Departmenty,"Experience"),
		List = Perks
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERKSBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PerksBuy(Index)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if Config.Perks[Index].Level then
		local Experience = vRP.Permissions(Departmenty,"Experience")
		if PainelCategory(Experience) < Config.Perks[Index].Level then
			TriggerClientEvent("painel:Notify",source,"Atenção","Level <b>"..Config.Perks[Index].Level.."</b> necessário.","amarelo")
			return false
		end
	end

	if Config.Perks[Index].Type == "Premium" and Groups[Departmenty].Type == "Propertys" then
		TriggerClientEvent("painel:Notify",source,"Atenção","Indisponível para propriedades.","amarelo")
		return false
	end

	if Config.Perks[Index].Type == "Members" and Groups[Departmenty].Max and vRP.Permissions(Departmenty,"Members") >= Groups[Departmenty].Max then
		TriggerClientEvent("painel:Notify",source,"Atenção","Limite de membros atingido.","amarelo")
		return false
	end

	if not Permissions[Passport].Perks then
		TriggerClientEvent("painel:Notify",source,"Atenção","Permissão indisponível.","amarelo")
		return false
	end

	Active[Passport] = true

	local Price = Config.Perks[Index].Price
	if type(Price) == "table" then
		local Members = vRP.Permissions(Departmenty,"Members")
		Price = Price[Members + 1] or Price[#Price]
	end

	if (Groups[Departmenty].Type == "Propertys" and vRP.PaymentBank(Passport,Price)) or vRP.Permissions(Departmenty,"Bank") >= Price then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Perks", Passport = Passport, Value = Price, Timestamp = os.time(), Permission = Departmenty })
		vRP.PermissionsUpdate(Departmenty,Config.Perks[Index].Type,"+",Config.Perks[Index].Increase)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Vantagem adquirida.","verde")

		if Groups[Departmenty].Type ~= "Propertys" then
			vRP.PermissionsUpdate(Departmenty,"Bank","-",Price)
		end

		Active[Passport] = nil

		return true
	else
		TriggerClientEvent("painel:Notify",source,"Aviso","Dinheiro insuficiente.","amarelo")
	end

	Active[Passport] = nil

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permissions()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if Level ~= 1 then
		return false
	end

	local Return = {}
	local Hierarchy = #Groups[Departmenty].Hierarchy
	local Consult = vRP.GetSrvData("Painel:"..Departmenty,true)

	for Number = 1,Hierarchy do
		local Levels = tostring(Number)
		Return[Levels] = Consult[Levels] or DefaultPermissions
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVEPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SavePermissions(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if Level ~= 1 then
		return false
	end

	vRP.SetSrvData("Painel:"..Departmenty,Table,true)
	TriggerClientEvent("painel:Notify",source,"Sucesso","Permissões atualizadas.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GOALS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Goals()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Departmenty = Division[Passport]
	if not Departmenty then
		return false
	end

	Active[Passport] = true

	local PanelKey = "Painel:Goals:"..Departmenty
	local Goals = vRP.GetSrvData(PanelKey,true) or {}
	if not Goals.Items or not Goals.Reward then
		Goals = { Reward = 0, Items = {} }
		vRP.SetSrvData(PanelKey,Goals,true)
	end

	local PlayerKey = "Goals:"..Departmenty..":"..Passport
	local MyGoals = vRP.GetSrvData(PlayerKey,true) or {}

	MyGoals.Week = MyGoals.Week or { false,false,false,false,false,false,false }
	MyGoals.Rescued = MyGoals.Rescued or false
	MyGoals.Items = MyGoals.Items or {}

	for Item in pairs(Goals.Items) do
		MyGoals.Items[Item] = MyGoals.Items[Item] or 0
	end

	local AllMembers = {}
	local DataGroups = vRP.DataGroups(Departmenty) or {}
	for OtherPassport in pairs(DataGroups) do
		local OtherKey = "Goals:"..Departmenty..":"..OtherPassport
		local Data = vRP.GetSrvData(OtherKey,true) or {}

		table.insert(AllMembers,{
			Player = {
				Passport = OtherPassport,
				Name = vRP.FullName(OtherPassport)
			},
			Week = Data.Week or { false,false,false,false,false,false,false },
			Items = Data.Items or {}
		})
	end

	Active[Passport] = nil

	return {
		Goals = Goals,
		MyGoals = MyGoals,
		All = AllMembers
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEGOALS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateGoals(Table,Money)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Departmenty = Division[Passport]
	if not Departmenty then
		return false
	end

	if not Permissions[Passport].Goals.Edit then
		return false
	end

	vRP.SetSrvData("Painel:Goals:"..Departmenty,{ Items = Table or {}, Reward = Money or 0 },true)
	TriggerClientEvent("painel:Notify",source,"Sucesso","Metas atualizadas.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLAIMGOALSREWARD
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ClaimGoalsReward()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Departmenty = Division[Passport]
	if not Departmenty then
		return false
	end

	Active[Passport] = true

	local PanelKey = "Painel:Goals:"..Departmenty
	local PlayerKey = "Goals:"..Departmenty..":"..Passport

	local Goals = vRP.GetSrvData(PanelKey,true) or {}
	local MyGoals = vRP.GetSrvData(PlayerKey,true) or {}

	MyGoals.Week = MyGoals.Week or { false,false,false,false,false,false,false }
	MyGoals.Rescued = MyGoals.Rescued or false
	MyGoals.Items = MyGoals.Items or {}

	if MyGoals.Rescued then
		Active[Passport] = nil
		return false
	end

	if not Goals.Reward or Goals.Reward <= 0 then
		Active[Passport] = nil
		return false
	end

	local Balance = vRP.Permissions(Departmenty,"Bank") or 0
	if Goals.Reward > Balance then
		Active[Passport] = nil
		return false
	end

	MyGoals.Rescued = true
	vRP.GiveBank(Passport,Goals.Reward)
	vRP.SetSrvData(PlayerKey,MyGoals,true)
	vRP.PermissionsUpdate(Departmenty,"Bank","-",Goals.Reward)
	exports.oxmysql:insert_async("INSERT INTO transactions (Passport,Type,Price,Timestamp,Reference) VALUES (@Passport,@Type,@Price,@Timestamp,@Reference)",{ Passport = Passport, Type = "Goals", Price = Goals.Reward, Timestamp = os.time(), Reference = Departmenty })
	exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Goals", Passport = Passport, Value = Goals.Reward, Timestamp = os.time(), Permission = Departmenty })
	Active[Passport] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
local function ThreadTick()
	local Now = os.date("*t")
	if Now.hour == 0 and Now.min <= 5 and LastResetDay ~= Now.day then
		LastResetDay = Now.day

		for Departmenty in pairs(Groups or {}) do
			local DataGroups = vRP.DataGroups(Departmenty)

			for OtherPassport in pairs(DataGroups or {}) do
				local Key = "Goals:"..Departmenty..":"..OtherPassport
				local Data = vRP.GetSrvData(Key,true) or {}

				Data.Week = Data.Week or { false,false,false,false,false,false,false }
				Data.Rescued = false
				Data.Items = {}

				if Now.wday == 2 then
					Data.Week = { false,false,false,false,false,false,false }
				end

				vRP.SetSrvData(Key,Data,true)
			end
		end
	end

	SetTimeout(30000,ThreadTick)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
ThreadTick()
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
end)