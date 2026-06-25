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
Tunnel.bindInterface("mdt",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Patrols = {}
local Division = {}
local Operations = {}
local Permissions = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEFAULTPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
local DefaultPermissions = {
	Board = false,
	Firearms = false,
	Flyingarms = false,
	ClearRecord = false,
	Patrol = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false
	},
	Operations = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false
	},
	Arrest = false,
	Fine = false,
	Warning = false,
	PoliceReports = {
		View = false,
		Create = false,
		Edit = false,
		Archive = false
	},
	InternalAffairs = {
		View = false,
		Create = false,
		Edit = false,
		Archive = false
	},
	Wanted = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false
	},
	SeizedVehicles = false,
	EditPenalCode = false,
	Medals = {
		View = false,
		Create = false,
		Assign = false,
		Edit = false,
		Delete = false
	},
	Units = {
		View = false,
		Create = false,
		Assign = false,
		Edit = false,
		Delete = false
	},
	Bank = {
		View = false,
		Deposit = false,
		Withdraw = false,
		Transfer = false
	},
	Management = {
		View = false,
		Create = false,
		Dismiss = false,
		RemoveService = false,
		Edit = false
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- MDT:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("mdt:Open")
AddEventHandler("mdt:Open",function(Permission)
	TriggerClientEvent("dynamic:Close",source)

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasService(Passport,Permission) then
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

	TriggerClientEvent("mdt:Opened",source)
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

	local Level = vRP.HasGroup(Passport,Departmenty)

	return {
		Group = {
			Max = vRP.Permissions(Departmenty,"Members"),
			Name = Departmenty,
		},
		Player = {
			Level = Level,
			Passport = Passport,
			Name = vRP.FullName(Passport) or NameDefault
		},
		Permissions = Permissions[Passport],
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOME
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Home()
	local Table = {
		Title = "Titulo do aviso",
		Description = "Descrição do aviso.",
		Divisions = {}
	}

	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasPermission(Passport,Departmenty) then
		return Table
	end

	local Consult = exports.oxmysql:single_async("SELECT Title,Description FROM mdt_creative_board WHERE Permission = @Permission ORDER BY id DESC LIMIT 1",{ Permission = Departmenty })
	if Consult then
		Table.Title = Consult.Title
		Table.Description = Consult.Description
	else
		exports.oxmysql:insert_async("INSERT INTO mdt_creative_board (Title,Description,Permission) VALUES (@Title,@Description,@Permission)",{
			Title = Table.Title,
			Description = Table.Description,
			Permission = Departmenty
		})
	end

	for Index,Name in pairs(Groups[Departmenty].Hierarchy) do
		table.insert(Table.Divisions, {
			Amount = vRP.AmountService(Departmenty,Index),
			Name = Name
		})
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEBOARD
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateBoard(Title,Description)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Board then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_board SET Title = @Title, Description = @Description WHERE Permission = @Permission",{ Title = Title, Description = Description, Permission = Departmenty })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Mensagem inicial atualizada.","verde")

	local Service = vRP.NumPermission(Departmenty)
	for _,Sources in pairs(Service) do
		async(function()
			TriggerClientEvent("Notify",Sources,(Groups[Departmenty].Name or "Policia"),"Mensagem inicial foi atualizada.","policia",10000)
		end)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCHOFFICER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SearchOfficer(Search,Div)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasGroup(Passport,Config.Group) then
		return Table
	end

	if type(Search) == "number" then
		local Identity = vRP.Identity(Search)
		if Identity and vRP.HasGroup(Search,Div and Departmenty or Config.Group) then
			table.insert(Table,{
				Passport = Search,
				Name = Identity.Name.." "..Identity.Lastname
			})
		end
	else
		local Consult = exports.oxmysql:query_async("SELECT id,CONCAT(Name,' ',Lastname) AS FullName FROM characters WHERE Name LIKE CONCAT('%',@Search,'%') OR Lastname LIKE CONCAT('%',@Search,'%') LIMIT 10",{ Search = Search })
		if Consult and #Consult > 0 then
			for _,v in ipairs(Consult) do
				if vRP.HasGroup(v.id,Div and Departmenty or Config.Group) then
					table.insert(Table,{
						Passport = v.id,
						Name = v.FullName
					})
				end
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCHUSER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SearchUser(Search,Select)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,Config.Group) then
		return false
	end

	if type(Search) == "number" then
		local Identity = vRP.Identity(Search)
		if Identity then
			table.insert(Table,{
				Passport = Search,
				Name = Identity.Name.." "..Identity.Lastname,
				Wanted = Select and false or exports.oxmysql:single_async("SELECT * FROM mdt_creative_wanted WHERE Passport = @Passport LIMIT 1",{ Passport = Search }) and true or false
			})
		end
	else
		local Consult = exports.oxmysql:query_async("SELECT id,CONCAT(Name,' ',Lastname) AS FullName FROM characters WHERE Name LIKE CONCAT('%',@Search,'%') OR Lastname LIKE CONCAT('%',@Search,'%') LIMIT 10",{ Search = Search })
		if Consult and #Consult > 0 then
			for _,v in ipairs(Consult) do
				table.insert(Table,{
					Passport = v.id,
					Name = v.FullName,
					Wanted = Select and false or exports.oxmysql:single_async("SELECT * FROM mdt_creative_wanted WHERE Passport = @Passport LIMIT 1",{ Passport = v.id }) and true or false
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.User(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local OtherPassport = parseInt(OtherPassport)
	if not Passport or not vRP.HasGroup(Passport,Config.Group) then
		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	if not Identity then
		return false
	end

	local Arrests = exports.oxmysql:query_async("SELECT * FROM mdt_creative_arrest WHERE Passport = @Passport ORDER BY Timestamp DESC",{ Passport = OtherPassport })
	local Warnings = exports.oxmysql:query_async("SELECT * FROM mdt_creative_warning WHERE Passport = @Passport ORDER BY Timestamp DESC",{ Passport = OtherPassport })
	local Wanted = exports.oxmysql:single_async("SELECT * FROM mdt_creative_wanted WHERE Passport = @Passport LIMIT 1",{ Passport = OtherPassport })
	local Fines = exports.oxmysql:query_async("SELECT * FROM mdt_creative_fines WHERE Passport = @Passport ORDER BY Timestamp DESC",{ Passport = OtherPassport })

	local User = {
		Passport = OtherPassport,
		Name = Identity.Name.." "..Identity.Lastname,
		Phone = vRP.Phone(OtherPassport),
		Wanted = Wanted and true or false,
		Firearms = vRP.DatatableInformation(OtherPassport,"Firearms"),
		Flyingarms = vRP.DatatableInformation(OtherPassport,"Flyingarms"),
		Services = Identity.Prison <= 0 and 0 or Identity.Prison,
		Avatar = exports.vrp:Avatar(OtherPassport,Config.Group),
		Fines = 0
	}
	local Historical = {}

	if Arrests and #Arrests > 0 then
		for _,v in ipairs(Arrests) do
			table.insert(Historical,{
				Id = v.id,
				Type = "arrest",
				Date = v.Timestamp,
				Officer = vRP.FullName(v.Officer) or NameDefault,
				Arrest = v.Arrest,
				Fine = v.Fine
			})
		end
	end

	if Fines and #Fines > 0 then
		for _,v in ipairs(Fines) do
			if not v.Arrest then
				table.insert(Historical,{
					Id = v.id,
					Type = "fine",
					Date = v.Timestamp,
					Officer = vRP.FullName(v.Officer) or NameDefault,
					Fine = v.Fine
				})
			end

			if not v.Paid and v.Fine > 0 then
				User.Fines = User.Fines + v.Fine
			end
		end
	end

	if Warnings and #Warnings > 0 then
		for _,v in ipairs(Warnings) do
			table.insert(Historical,{
				Id = v.id,
				Type = "warning",
				Date = v.Timestamp,
				Officer = vRP.FullName(v.Officer) or NameDefault
			})
		end
	end

	return {
		User = User,
		Historical = Historical
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AVATAR
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Avatar(OtherPassport,Link)
	local source = source
	local Passport = vRP.Passport(source)
	local OtherPassport = parseInt(OtherPassport)
	if not Passport or not OtherPassport or not vRP.HasGroup(Passport,Config.Group) then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM avatars WHERE Passport = @Passport AND Permission = @Permission LIMIT 1",{ Passport = OtherPassport, Permission = Config.Group })
	if Consult then
		exports.oxmysql:update_async("UPDATE avatars SET Image = @Image WHERE Passport = @Passport AND Permission = @Permission",{ Passport = OtherPassport, Image = Link, Permission = Config.Group })
	else
		exports.oxmysql:insert_async("INSERT INTO avatars (Passport,Image,Permission) VALUES (@Passport,@Image,@Permission)",{ Passport = OtherPassport, Image = Link, Permission = Config.Group })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FLYINGARMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Flyingarms(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport or not Permissions[Passport].Flyingarms then
		return false
	end

	local OtherPassport = parseInt(OtherPassport)
	local Flyingarms = vRP.DatatableInformation(OtherPassport,"Flyingarms")

	vRP.UpdateDatatable(OtherPassport,"Flyingarms",not Flyingarms)
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Licença de aviação atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FIREARMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Firearms(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport or not Permissions[Passport].Firearms then
		return false
	end

	local OtherPassport = parseInt(OtherPassport)
	local Firearms = vRP.DatatableInformation(OtherPassport,"Firearms")

	vRP.UpdateDatatable(OtherPassport,"Firearms",not Firearms)
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Porte de Armas atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARRECORD
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ClearRecord(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].ClearRecord then
		return false
	end

	local Records = {
		arrest = { Table = "mdt_creative_arrest", Message = "Prisão removida com sucesso." },
		fine = { Table = "mdt_creative_fines", Message = "Multa removida com sucesso." },
		warning = { Table = "mdt_creative_warning", Message = "Aviso removido com sucesso." }
	}

	local Recording = Records[Table.Type]
	if not Recording then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM "..Recording.Table.." WHERE id = @id",{ id = Table.Id })
	TriggerClientEvent("mdt:Notify",source,"Sucesso",Recording.Message,"verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARRECORDS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ClearRecords(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].ClearRecord then
		return false
	end

	local Records = {
		"mdt_creative_fines",
		"mdt_creative_arrest",
		"mdt_creative_warning"
	}

	for _,v in ipairs(Records) do
		exports.oxmysql:query_async("DELETE FROM "..v.." WHERE Passport = @Passport",{ Passport = OtherPassport })
	end

	TriggerClientEvent("mdt:Notify",source,"Sucesso","Registros removidos com sucesso.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RECORD
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Record(Selected,Type)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,Config.Group) then
		return false
	end

	local Return = {}
	if Type == "arrest" then
		local Consult = exports.oxmysql:single_async("SELECT mdt_creative_arrest.*,mdt_creative_fines.Paid FROM mdt_creative_arrest LEFT JOIN mdt_creative_fines ON mdt_creative_arrest.id = mdt_creative_fines.Arrest WHERE mdt_creative_arrest.id = @id LIMIT 1",{ id = Selected })
		if Consult then
			Return = {
				Date = Consult.Timestamp,
				Officer = vRP.FullName(Consult.Officer) or NameDefault,
				Officers = Consult.Officers,
				Arrest = Consult.Arrest,
				Fine = Consult.Fine,
				Paid = Consult.Paid,
				Infractions = Consult.Infractions,
				Description = Consult.Description
			}
		end
	elseif Type == "fine" then
		local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_fines WHERE id = @id LIMIT 1",{ id = Selected })
		if Consult then
			Return = {
				Date = Consult.Timestamp,
				Officer = vRP.FullName(Consult.Officer) or NameDefault,
				Fine = Consult.Fine,
				Paid = Consult.Paid,
				Infractions = Consult.Infractions,
				Description = Consult.Description
			}
		end
	elseif Type == "warning" then
		local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_warning WHERE id = @id LIMIT 1",{ id = Selected })
		if Consult then
			Return = {
				Date = Consult.Timestamp,
				Officer = vRP.FullName(Consult.Officer) or NameDefault,
				Description = Consult.Description
			}
		end
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PATROL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Patrol()
	return Patrols
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPATROL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetPatrol(Selected)
	local source = source
	local Passport = vRP.Passport(source)

	return Passport and Permissions[Passport].Patrol.View and Patrols[Selected] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEPATROL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreatePatrol(Vehicle,Unit,Officers)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Patrol.Create then
		return false
	end

	local Departmenty = Division[Passport]
	if not Departmenty then
		return false
	end

	repeat
		Selected = GenerateString("DDD")
	until Selected and not Patrols[Selected]

	Patrols[Selected] = {
		Unit = Unit,
		Car = Vehicle,
		Officers = {},
		Group = Departmenty,
		Creator = {
			Passport = Passport,
			Name = vRP.FullName(Passport)
		}
	}

	for _,v in pairs(Officers) do
		table.insert(Patrols[Selected].Officers,{
			Passport = v,
			Name = vRP.FullName(v)
		})
	end

	TriggerClientEvent("mdt:Notify",source,"Sucesso","Patrulamento criado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPATROL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdatePatrol(Selected,Vehicle,Unit,Officers)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Patrols[Selected] or not Patrols[Selected].Creator or not Permissions[Passport].Patrol.Edit then
		return false
	end

	Patrols[Selected].Unit = Unit
	Patrols[Selected].Officers = {}
	Patrols[Selected].Car = Vehicle

	for _,v in pairs(Officers) do
		table.insert(Patrols[Selected].Officers,{
			Passport = v,
			Name = vRP.FullName(v)
		})
	end

	TriggerClientEvent("mdt:Notify",source,"Sucesso","Patrulamento atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYPATROL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyPatrol(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Patrols[Selected] or not Patrols[Selected].Creator or not Permissions[Passport].Patrol.Delete then
		return false
	end

	TriggerClientEvent("mdt:Notify",source,"Sucesso","Patrulamento removido.","verde")
	Patrols[Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPERATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Operations()
	return Operations
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPERATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetOperation(Selected)
	return Operations and Operations[Selected] or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEOPERATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateOperation(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Operations.Create then
		return false
	end

	local Departmenty = Division[Passport]
	if not Departmenty then
		return false
	end

	local Consult = exports.hud:RadioExist(Table.Radio)
	if Consult and not vRP.HasService(Passport,Consult) then
		TriggerClientEvent("mdt:Notify",source,"Atenção","Frequência indisponível.","amarelo")
		return false
	end

	repeat
		Selected = GenerateString("DDD")
	until Selected and not Operations[Selected]

	Operations[Selected] = {
		Radio = Table.Radio,
		Location = Table.Location,
		Group = Departmenty,
		Creator = {
			Passport = Passport,
			Name = vRP.FullName(Passport)
		},
		Candidates = {},
		Escalates = {}
	}

	table.insert(Operations[Selected].Escalates,Operations[Selected].Creator)

	local Service = vRP.NumPermission(Config.Group)
	for _,Sources in pairs(Service) do
		async(function()
			TriggerClientEvent("Notify",Sources,(Groups[Departmenty].Name or "Policia"),"Operação ( <b>"..Config.OperationsLocations[Table.Location].Name.."</b> ) encontra-se disponível, candidate-se para participar e aguarde confirmação no rádio <b>"..Table.Radio.."</b>.","policia",15000)
		end)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEOPERATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateOperation(Selected,Location,Radio)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Operations[Selected] or not Operations[Selected].Creator or not Permissions[Passport].Operations.Edit then
		return false
	end

	Operations[Selected].Radio = Radio
	Operations[Selected].Location = Location

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYOPERATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyOperation(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Operations[Selected] or not Operations[Selected].Creator or not Permissions[Passport].Operations.Delete then
		return false
	end

	Operations[Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ESCALATEDOPERATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.EscalatedOperation(Selected,Mode,OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Operations[Selected] or not Permissions[Passport].Operations.Edit then
		return false
	end

	local Operation = Operations[Selected]
	local CreatorPassport = Operation.Creator.Passport
	local Location = Config.OperationsLocations[Operation.Location]

	if Mode == "Add" and CreatorPassport == Passport then
		if Location and Location.Max and #Operation.Escalates < Location.Max then
			for Index,v in pairs(Operation.Candidates) do
				if v.Passport == OtherPassport then
					local OtherSource = vRP.Source(OtherPassport)
					if OtherSource then
						TriggerClientEvent("Notify",OtherSource,"Operações","Você foi escalado para a operação <b>"..Location.Name.."</b>.","verde",10000)
					end

					table.insert(Operation.Escalates,Operation.Candidates[Index])
					table.remove(Operation.Candidates,Index)

					return true
				end
			end
		end
	elseif Mode == "Remove" and CreatorPassport == Passport then
		for Index,v in pairs(Operation.Escalates) do
			if v.Passport == OtherPassport then
				table.insert(Operation.Candidates,Operation.Escalates[Index])
				table.remove(Operation.Escalates,Index)

				return true
			end
		end
	elseif Mode == "Apply" and CreatorPassport ~= Passport then
		local DoesExistPlayer = false
		for _,v in pairs(Operation.Candidates) do
			if v.Passport == OtherPassport then
				DoesExistPlayer = true

				break
			end
		end

		if not DoesExistPlayer then
			table.insert(Operation.Candidates,{
				Passport = OtherPassport,
				Name = vRP.FullName(OtherPassport)
			})

			local OtherSource = vRP.Source(CreatorPassport)
			if OtherSource then
				TriggerClientEvent("mdt:Refresh",OtherSource,"Operation")
			end

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARRESTRECORDS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ArrestRecords()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,Config.Group) then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_arrest ORDER BY Timestamp DESC LIMIT 50")
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in ipairs(Consult) do
		local Identity = vRP.Identity(v.Passport)
		if Identity then
			local OfficerFullName = vRP.FullName(v.Officer) or NameDefault
			local OfficersList = v.Officers and v.Officers ~= "" and ", " .. v.Officers or ""

			table.insert(Table,{
				Id = v.id,
				Avatar = exports.vrp:Avatar(v.Passport,Config.Group),
				Passport = v.Passport,
				Name = Identity.Name.." "..Identity.Lastname,
				Officers = OfficerFullName..OfficersList,
				Arrest = v.Arrest,
				Fine = v.Fine,
				Date = v.Timestamp
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARREST
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Arrest(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Arrest then
		return false
	end

	local Identity = vRP.Identity(Table.Offender)
	if not Identity then
		return false
	end

	local Officers = ""
	local Bail,Fine,Arrest,Infractions = 0,0,0,{}
	for _,InfractionId in pairs(Table.Infractions) do
		local Resume = exports.oxmysql:single_async("SELECT * FROM mdt_creative_penalcode_articles WHERE id = @Number LIMIT 1",{ Number = InfractionId })
		if Resume then
			table.insert(Infractions, string.format("%s - %s",Resume.Article,Resume.Contravention))

			Fine = Fine + (Resume.Fine or 0)
			Arrest = Arrest + (Resume.Arrest or 0)
			Bail = Bail + (Resume.Bail or 0)
		end
	end

	Fine = math.min(Fine - (Fine * (math.min(Table.ReductionFine,Config.MaxReductionFine) / 100)),Config.MaxFine)
	Arrest = math.min(Arrest - (Arrest * (math.min(Table.ReductionArrest,Config.MaxReductionArrest) / 100)),Config.MaxArrest)

	if type(Table.OfficersInvolved) == "table" and #Table.OfficersInvolved > 0 then
		for Index,v in pairs(Table.OfficersInvolved) do
			Table.OfficersInvolved[Index] = vRP.FullName(v)
		end

		Officers = table.concat(Table.OfficersInvolved,", ")
	end

	local Number = exports.oxmysql:insert_async("INSERT INTO mdt_creative_arrest (Passport,Officer,Officers,Timestamp,Infractions,Arrest,Fine,Description) VALUES (@Passport,@Officer,@Officers,@Timestamp,@Infractions,@Arrest,@Fine,@Description)",{
		Passport = Table.Offender,
		Officer = Passport,
		Officers = Officers,
		Timestamp = os.time(),
		Infractions = table.concat(Infractions,", "),
		Arrest = Arrest,
		Fine = Fine,
		Description = Table.Description
	})

	if Arrest > 0 then
		vRP.InsertPrison(Table.Offender,Arrest)
		exports.discord:Embed("Mdt","**[MODO]:** Prisão\n**[POLICIAL]:** "..Passport.."\n**[PASSAPORTE]:** "..Table.Offender.."\n**[TEMPO]:** "..Arrest)

		local OtherSource = vRP.Source(Table.Offender)
		if OtherSource then
			if Player(OtherSource)["state"]["Handcuff"] then
				Player(OtherSource)["state"]["Handcuff"] = false
				Player(OtherSource)["state"]["Commands"] = false

				vRPC.Destroy(OtherSource)
			end

			TriggerClientEvent("Notify",OtherSource,(Groups[Departmenty].Name or "Policia"),"Você recebeu a pena de <b>"..Arrest.."</b> serviços.","verde",10000)
		end
	elseif Bail > 0 then
		Fine = Fine + Bail
	end

	if Fine > 0 then
		exports.discord:Embed("Mdt","**[MODO]:** Multa\n**[POLICIAL]:** "..Passport.."\n**[PASSAPORTE]:** "..Table.Offender.."\n**[VALOR]:** "..Fine)

		exports.oxmysql:query_async("INSERT INTO mdt_creative_fines (Passport,Officer,Timestamp,Infractions,Fine,Description,Arrest) VALUES (@Passport,@Officer,@Timestamp,@Infractions,@Fine,@Description,@Arrest)",{
			Passport = Table.Offender,
			Officer = Passport,
			Timestamp = os.time(),
			Infractions = table.concat(Infractions,", "),
			Fine = Fine,
			Description = Table.Description,
			Arrest = Number
		})
	end

	TriggerClientEvent("mdt:Notify",source,"Sucesso","Registro enviado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Fine(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Fine then
		return false
	end

	local Identity = vRP.Identity(Table.Offender)
	if not Identity then
		return false
	end

	local Fine = 0
	local Infractions = {}

	for _,v in pairs(Table.Infractions) do
		local Resume = exports.oxmysql:single_async("SELECT * FROM mdt_creative_penalcode_articles WHERE id = @Number LIMIT 1",{ Number = v })

		table.insert(Infractions,string.format("%s - %s",Resume.Article,Resume.Contravention))

		if Resume.Fine then
			Fine = Fine + Resume.Fine
		end
	end

	Fine = Fine - (Fine * (math.min(Table.ReductionFine,Config.MaxReductionFine) / 100))

	if Fine > 0 then
		exports.oxmysql:query_async("INSERT INTO mdt_creative_fines (Passport,Officer,Timestamp,Infractions,Fine,Description) VALUES (@Passport,@Officer,@Timestamp,@Infractions,@Fine,@Description)",{ Passport = Table.Offender, Officer = Passport, Timestamp = os.time(), Infractions = table.concat(Infractions,", "), Fine = Fine, Description = Table.Description })
	end

	TriggerClientEvent("mdt:Notify",source,"Sucesso","Multa enviada com sucesso.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WARNING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Warning(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Warning then
		return false
	end

	local Identity = vRP.Identity(Table.Passport)
	if not Identity then
		return false
	end

	exports.oxmysql:query_async("INSERT INTO mdt_creative_warning (Passport,Officer,Timestamp,Description) VALUES (@Passport,@Officer,@Timestamp,@Description)",{ Passport = Table.Passport, Officer = Passport, Timestamp = os.time(), Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Aviso enviado com sucesso.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- POLICEREPORTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PoliceReports()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].PoliceReports.View then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_reports ORDER BY id DESC")
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in ipairs(Consult) do
		table.insert(Table,{
			Id = v.id,
			Title = v.Title,
			Archive = v.Archive,
			Date = v.Timestamp,
			Applicant = {
				Passport = v.Passport,
				Name = vRP.FullName(v.Passport)
			},
			Creator = {
				Passport = v.Officer,
				Name = vRP.FullName(v.Officer)
			}
		})
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPOLICEREPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetPoliceReport(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].PoliceReports.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_reports WHERE id = @Number ORDER BY id LIMIT 1",{ Number = Number })
	if not Consult then
		return false
	end

	local Identity = vRP.Identity(Consult.Passport)
	if not Identity then
		return false
	end

	local Table = {
		Title = Consult.Title,
		Archive = Consult.Archive,
		Applicant = {
			Passport = Consult.Passport,
			Name = Identity.Name.." "..Identity.Lastname
		},
		Suspects = {},
		Description = Consult.Description,
		Date = Consult.Timestamp,
		Creator = {
			Passport = Consult.Officer,
			Name = vRP.FullName(Consult.Officer)
		}
	}

	if Consult.Suspects then
		local Suspects = json.decode(Consult.Suspects)
		for _,v in pairs(Suspects) do
			table.insert(Table.Suspects,{
				Passport = v,
				Name = vRP.FullName(v)
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEPOLICEREPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreatePoliceReport(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].PoliceReports.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO mdt_creative_reports (Passport,Title,Suspects,Officer,Timestamp,Description) VALUES (@Passport,@Title,@Suspects,@Officer,@Timestamp,@Description)",{ Passport = Table.Applicant, Title = Table.Title, Suspects = json.encode(Table.Suspects), Officer = Passport, Timestamp = os.time(), Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Boletim de ocorrência registrado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPOLICEREPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdatePoliceReport(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].PoliceReports.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_reports SET Title = @Title, Passport = @Passport, Suspects = @Suspects, Description = @Description WHERE id = @Id",{ Id = Table.Id, Passport = Table.Applicant, Title = Table.Title, Suspects = json.encode(Table.Suspects), Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Boletim de ocorrência atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHIVEPOLICEREPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ArchivePoliceReport(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].PoliceReports.Archive then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_reports SET Archive = @Archive WHERE id = @Id",{ Id = Number, Archive = 1 })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Boletim de ocorrência arquivado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INTERNALAFFAIRS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InternalAffairs()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].InternalAffairs.View then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_internalaffairs ORDER BY id DESC")
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in ipairs(Consult) do
		table.insert(Table,{
			Id = v.id,
			Title = v.Title,
			Archive = v.Archive,
			Date = v.Timestamp,
			Applicant = {
				Passport = v.Passport,
				Name = vRP.FullName(v.Passport)
			},
			Creator = {
				Passport = Consult.Officer,
				Name = vRP.FullName(Consult.Officer)
			}
		})
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETINTERNALAFFAIRS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetInternalAffairs(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].InternalAffairs.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_internalaffairs WHERE id = @Number ORDER BY id LIMIT 1",{ Number = Number })
	if not Consult then
		return false
	end

	local Identity = vRP.Identity(Consult.Passport)
	if not Identity then
		return false
	end

	return {
		Title = Consult.Title,
		Archive = Consult.Archive,
		Applicant = {
			Passport = Consult.Passport,
			Name = Identity.Name.." "..Identity.Lastname
		},
		Accused = {
			Passport = Consult.Accused,
			Name = vRP.FullName(Consult.Accused)
		},
		Description = Consult.Description,
		Date = Consult.Timestamp,
		Creator = {
			Passport = Consult.Officer,
			Name = vRP.FullName(Consult.Officer)
		}
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEINTERNALAFFAIRS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateInternalAffairs(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].InternalAffairs.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO mdt_creative_internalaffairs (Passport,Title,Accused,Officer,Timestamp,Description) VALUES (@Passport,@Title,@Accused,@Officer,@Timestamp,@Description)",{ Passport = Table.Applicant, Title = Table.Title, Accused = Table.Accused, Officer = Passport, Timestamp = os.time(), Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Denúncia registrada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEINTERNALAFFAIRS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateInternalAffairs(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].InternalAffairs.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_internalaffairs SET Title = @Title, Passport = @Passport, Accused = @Accused, Description = @Description WHERE id = @Id",{ Id = Table.Id, Passport = Table.Applicant, Title = Table.Title, Accused = Table.Accused, Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Denúncia atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHIVEINTERNALAFFAIRS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ArchiveInternalAffairs(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].InternalAffairs.Archive then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_internalaffairs SET Archive = @Archive WHERE id = @Id",{ Id = Number, Archive = 1 })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Denúncia arquivada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WANTED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Wanted()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Wanted.View then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_wanted ORDER BY id DESC")
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in ipairs(Consult) do
		local Identity = vRP.Identity(v.Passport)
		if Identity and (v.HowLong == 0 or (v.Timestamp + (v.HowLong * 86400)) >= os.time()) then
			table.insert(Table,{
				Id = v.id,
				Citizen = {
					Passport = v.Passport,
					Name = Identity.Name.." "..Identity.Lastname
				},
				Date = v.Timestamp
			})
		else
			exports.oxmysql:query_async("DELETE FROM mdt_creative_wanted WHERE id = @id",{ id = v.id })
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETWANTED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetWanted(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Wanted.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_wanted WHERE id = @Number ORDER BY id LIMIT 1",{ Number = Number })
	if not Consult then
		return false
	end

	local Identity = vRP.Identity(Consult.Passport)
	if not Identity then
		return false
	end

	return {
		Image = Consult.Image,
		Citizen = {
			Passport = Consult.Passport,
			Name = Identity.Name.." "..Identity.Lastname
		},
		Accusations = json.decode(Consult.Accusations) or {},
		Officer = {
			Passport = Consult.Officer,
			Name = vRP.FullName(Consult.Officer) or NameDefault
		},
		Date = Consult.Timestamp,
		HowLong = Consult.HowLong,
		Description = Consult.Description
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEWANTED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateWanted(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Wanted.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO mdt_creative_wanted (Passport,Image,Accusations,Officer,Timestamp,HowLong,Description) VALUES (@Passport,@Image,@Accusations,@Officer,@Timestamp,@HowLong,@Description)",{ Passport = Table.Citizen, Image = Table.Image, Accusations = json.encode(Table.Accusations), Officer = Passport, Timestamp = os.time(), HowLong = Table.HowLong, Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Procurado registrado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEWANTED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateWanted(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Wanted.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_wanted SET Image = @Image, Accusations = @Accusations, HowLong = @HowLong, Description = @Description WHERE id = @Id",{ Id = Table.Id, Image = Table.Image, Accusations = json.encode(Table.Accusations), HowLong = Table.HowLong, Description = Table.Description })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Procurado atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYWANTED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyWanted(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Wanted.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM mdt_creative_wanted WHERE id = @id",{ id = Number })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Procurado removido.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEIZEDVEHICLES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SeizedVehicles()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].SeizedVehicles then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_vehicles ORDER BY Timestamp DESC LIMIT 50")
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in pairs(Consult) do
		table.insert(Table,{
			Image = v.Image,
			Vehicle = v.Vehicle,
			Plate = v.Plate,
			Name = vRP.FullName(v.Passport),
			Location = v.Location,
			Officer = {
				Passport = v.Officer,
				Name = vRP.FullName(v.Officer)
			},
			Description = v.Description,
			Date = v.Timestamp
		})
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATESEIZEDVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateSeizedVehicle(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].SeizedVehicles or not vRP.PassportPlate(Table.Plate) then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM vehicles WHERE Plate = @Plate LIMIT 1",{ Plate = Table.Plate })
	if not Consult then
		return false
	end

	if Consult.Arrest then
		TriggerClientEvent("Notify",source,"Departamento Policial","Veículo já se encontra apreendido.","policia",5000)
		return false
	end

	TriggerClientEvent("Notify",source,"Departamento Policial","Veículo apreendido.","policia",5000)
	exports.oxmysql:update_async("UPDATE vehicles SET Arrest = 1 WHERE Plate = @Plate",{ Plate = Table.Plate })
	exports.oxmysql:insert_async("INSERT INTO mdt_creative_vehicles (Passport,Officer,Image,Vehicle,Plate,Location,Timestamp,Description) VALUES (@Passport,@Officer,@Image,@Vehicle,@Plate,@Location,@Timestamp,@Description)",{ Passport = Table.Passport, Officer = Passport, Image = Table.Image, Vehicle = Table.Vehicle, Plate = Table.Plate, Location = Table.Location, Timestamp = os.time(), Description = Table.Description })

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MDT:VEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("mdt:Vehicle")
AddEventHandler("mdt:Vehicle",function(Entity)
	local source = source
	local Passport = vRP.Passport(source)

	if not Passport then
		return false
	end

	if not Division[Passport] then
		Division[Passport] = vRP.LoopPermission(Passport,Config.Group)
		Departmenty = Division[Passport]
	end

	if not Departmenty then
		return false
	end

	if not Permissions[Passport] then
		local Level = vRP.HasService(Passport,Departmenty)
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
			Consult = vRP.GetSrvData("Painel:"..Departmenty,true)
		end

		Permissions[Passport] = Consult[Levels] or DefaultPermissions
	end

	if not Permissions[Passport].SeizedVehicles then
		return false
	end

	local Consult = vRP.SingleQuery("vehicles/plateVehicles",{ Plate = Entity[1] })
	if Consult then
		if not Consult.Arrest then
			TriggerClientEvent("mdt:Vehicle",source,Consult.Passport,vRP.FullName(Consult.Passport),Entity[1],Entity[2])
		else
			TriggerClientEvent("Notify",source,"Departamento Policial","Veículo já se encontra apreendido.","policia",5000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PENALCODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PenalCode(Mode)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,Config.Group) then
		return false
	end

	local Table = {}

	if Mode == "Arrest" or Mode == "Fine" then
		local Consult = (Mode == "Arrest" and exports.oxmysql:query_async("SELECT * FROM mdt_creative_penalcode_articles WHERE Arrest > 0")) or exports.oxmysql:query_async("SELECT * FROM mdt_creative_penalcode_articles WHERE Fine > 0 AND Arrest <= 0")
		if not Consult or #Consult == 0 then
			return false
		end

		for _,v in pairs(Consult) do
			table.insert(Table,{
				Id = v.id,
				Article = v.Article,
				Contravention = v.Contravention,
				Fine = v.Fine,
				Arrest = v.Arrest,
				Bail = v.Bail
			})
		end
	else
		local Consult = exports.oxmysql:query_async("SELECT s.id AS sid, s.Type, s.Title, s.Description, s.Order AS sOrder, a.id AS aid, a.Section, a.Article, a.Contravention, a.Fine, a.Arrest, a.Bail, a.Order AS aOrder FROM mdt_creative_penalcode_sections s LEFT JOIN mdt_creative_penalcode_articles a ON s.id = a.Section")
		if not Consult or #Consult == 0 then
			return false
		end

		for _,v in pairs(Consult) do
			local Number = tostring(v.sid)
			if not Table[Number] then
				Table[Number] = {
					Order = v.sOrder,
					Id = v.sid,
					Type = v.Type,
					Title = v.Title,
					Description = v.Description,
					Infractions = {}
				}
			end

			if v.aid then
				table.insert(Table[Number].Infractions,{
					Order = v.aOrder,
					Id = v.aid,
					Article = v.Article,
					Contravention = v.Contravention,
					Fine = v.Fine,
					Arrest = v.Arrest,
					Bail = v.Bail
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEPENALCODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreatePenalCode(Mode,Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].EditPenalCode then
		return false
	end

	if Mode == "Article" then
		local Consult = exports.oxmysql:query_async("SELECT COALESCE(MAX(`Order`),0) + 1 AS NextOrder FROM mdt_creative_penalcode_articles WHERE Section = @Section",{ Section = Data.Section })
		if not Consult or #Consult == 0 then
			return false
		end

		local Number = exports.oxmysql:insert_async("INSERT INTO mdt_creative_penalcode_articles (Section,Article,Contravention,Fine,Arrest,Bail,`Order`) VALUES (@Section,@Article,@Contravention,@Fine,@Arrest,@Bail,@Order)",{ Section = Data.Section, Article = Data.Article, Contravention = Data.Contravention, Fine = Data.Fine or 0, Arrest = Data.Arrest or 0, Bail = Data.Bail or 0, Order = Consult[1].NextOrder })

		return Number
	elseif Mode == "Section" then
		local Consult = exports.oxmysql:query_async("SELECT COALESCE(MAX(`Order`),0) + 1 AS NextOrder FROM mdt_creative_penalcode_sections")
		if not Consult or #Consult == 0 then
			return false
		end

		local Number = exports.oxmysql:insert_async("INSERT INTO mdt_creative_penalcode_sections (Title,Description,Type,`Order`) VALUES (@Title,@Description,@Type,@Order)",{ Title = Data.Title, Description = Data.Description, Type = Data.Type, Order = Consult[1].NextOrder })

		return Number
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPENALCODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdatePenalCode(Number,Mode,Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].EditPenalCode then
		return false
	end

	if Mode == "Article" then
		exports.oxmysql:update_async("UPDATE mdt_creative_penalcode_articles SET Article = @Article, Contravention = @Contravention, Fine = @Fine, Arrest = @Arrest, Bail = @Bail WHERE id = @id",{ id = Number, Article = Data.Article, Contravention = Data.Contravention, Fine = Data.Fine or 0, Arrest = Data.Arrest or 0, Bail = Data.Bail or 0 })

		return true
	elseif Mode == "Section" then
		exports.oxmysql:update_async("UPDATE mdt_creative_penalcode_sections SET Title = @Title, Description = @Description WHERE id = @id",{ id = Number, Title = Data.Title, Description = Data.Description })

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYPENALCODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyPenalCode(Number,Mode)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].EditPenalCode then
		return false
	end

	if Mode == "Article" then
		local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_penalcode_articles WHERE id = @Number LIMIT 1",{ Number = Number })
		if not Consult then
			return false
		end

		exports.oxmysql:query_async("DELETE FROM mdt_creative_penalcode_articles WHERE id = @Number",{ Number = Number })
		exports.oxmysql:update_async("UPDATE mdt_creative_penalcode_articles SET `Order` = `Order` - 1 WHERE `Order` > @Order",{ Order = Consult.Order })

		return true
	elseif Mode == "Section" then
		local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_penalcode_sections WHERE id = @Number LIMIT 1",{ Number = Number })
		if not Consult then
			return false
		end

		exports.oxmysql:query_async("DELETE FROM mdt_creative_penalcode_sections WHERE id = @Number",{ Number = Number })
		exports.oxmysql:update_async("UPDATE mdt_creative_penalcode_sections SET `Order` = `Order` - 1 WHERE `Order` > @Order",{ Order = Consult.Order })

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ORDERPENALCODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.OrderPenalCode(Number,Mode,Direction,Section)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].EditPenalCode then
		return false
	end

	if Mode == "Article" then
		local ConsultOrder = exports.oxmysql:single_async("SELECT MAX(`Order`) AS MaxOrder FROM mdt_creative_penalcode_articles WHERE Section = @Section",{ Section = Section })
		local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_penalcode_articles WHERE id = @Id LIMIT 1",{ Id = Number })
		if Consult and ((Direction == "Up" and Consult.Order > 1) or (Direction == "Down" and Consult.Order < ConsultOrder.MaxOrder)) then
			local Order = Consult.Order
			local OtherOrder = Direction == "Up" and Order - 1 or Order + 1

			exports.oxmysql:update_async("UPDATE mdt_creative_penalcode_articles SET `Order` = CASE WHEN `Order` = @Order THEN @OtherOrder WHEN `Order` = @OtherOrder THEN @Order END WHERE `Order` IN (@Order,@OtherOrder) AND Section = @Section",{ Order = Order, OtherOrder = OtherOrder, Section = Section })

			return true
		end
	elseif Mode == "Section" then
		local ConsultOrder = exports.oxmysql:single_async("SELECT MAX(`Order`) AS MaxOrder FROM mdt_creative_penalcode_sections")
		local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_penalcode_sections WHERE id = @Id LIMIT 1",{ Id = Number })
		if Consult and ((Direction == "Up" and Consult.Order > 1) or (Direction == "Down" and Consult.Order < ConsultOrder.MaxOrder)) then
			local Order = Consult.Order
			local OtherOrder = Direction == "Up" and Order - 1 or Order + 1

			exports.oxmysql:update_async("UPDATE mdt_creative_penalcode_sections SET `Order` = CASE WHEN `Order` = @Order THEN @OtherOrder WHEN `Order` = @OtherOrder THEN @Order END WHERE `Order` IN (@Order,@OtherOrder)",{ Order = Order, OtherOrder = OtherOrder })

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MEDALS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Medals()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Medals.View then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_medals WHERE Permission = @Permission ORDER BY Name ASC",{ Permission = Departmenty })
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in ipairs(Consult) do
		table.insert(Table,{
			Id = v.id,
			Image = v.Image,
			Name = v.Name,
			Officers = #json.decode(v.Officers)
		})
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMEDAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetMedal(Number,GetOfficers)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permissions[Passport].Medals.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_medals WHERE id = @Number LIMIT 1",{ Number = Number })
	if not Consult then
		return false
	end

	local Table = {
		Id = Consult.id,
		Image = Consult.Image,
		Name = Consult.Name
	}

	if GetOfficers then
		Table.Officers = {}

		if Consult.Officers then
			local Officers = json.decode(Consult.Officers)
			for _,v in pairs(Officers) do
				table.insert(Table.Officers,{
					Passport = v,
					Name = vRP.FullName(v)
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEMEDAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateMedal(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty or not Table.Name or not Table.Image then
		return false
	end

	if not Permissions[Passport].Medals.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO mdt_creative_medals (Name,Image,Permission) VALUES (@Name,@Image,@Permission)",{ Name = Table.Name, Image = Table.Image, Permission = Departmenty })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Medalha criada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEMEDAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateMedal(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty or not Table.Id or not Table.Name or not Table.Image then
		return false
	end

	if not Permissions[Passport].Medals.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_medals SET Name = @Name, Image = @Image WHERE id = @Id",{ Id = Table.Id, Name = Table.Name, Image = Table.Image })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Medalha atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYMEDAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyMedal(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty or not Number then
		return false
	end

	if not Permissions[Passport].Medals.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM mdt_creative_medals WHERE id = @id",{ id = Number })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Medalha removida.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSIGNMEDAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssignMedal(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Medals.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Officers,Name FROM mdt_creative_medals WHERE id = @Number",{ Number = Table.Id })
	if not Consult or not Consult.Officers then
		return false
	end

	local Officers = json.decode(Consult.Officers)
	for _,v in ipairs(Officers) do
		if Table.Officer == v then
			TriggerClientEvent("mdt:Notify",source,"Atenção","O oficial já possui esta medalha.","amarelo")
			return false
		end
	end

	table.insert(Officers,Table.Officer)
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Medalha atribuida.","verde")
	exports.oxmysql:update_async("UPDATE mdt_creative_medals SET Officers = @Officers WHERE id = @Id",{ Id = Table.Id, Officers = json.encode(Officers) })

	local OtherSource = vRP.Source(Table.Officer)
	if OtherSource then
		TriggerClientEvent("Notify",OtherSource,(Groups[Departmenty].Name or "Policia"),"Parabéns você recebeu uma medalha.","verde",10000)
	end

	return {
		Passport = Table.Officer,
		Name = vRP.FullName(Table.Officer)
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEMEDAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveMedal(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Medals.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Officers FROM mdt_creative_medals WHERE id = @Number",{ Number = Table.Id })
	if not Consult or not Consult.Officers then
		return false
	end

	local Officers = json.decode(Consult.Officers)
	for Index,Officer in ipairs(Officers) do
		if Table.Officer == Officer then
			table.remove(Officers,Index)
			TriggerClientEvent("mdt:Notify",source,"Sucesso","Medalha removida.","verde")
			exports.oxmysql:update_async("UPDATE mdt_creative_medals SET Officers = @Officers WHERE id = @Id",{ Id = Table.Id, Officers = json.encode(Officers) })

			local OtherSource = vRP.Source(Table.Officer)
			if OtherSource then
				TriggerClientEvent("Notify",OtherSource,(Groups[Departmenty].Name or "Policia"),"Removeram a sua medalha <b>"..Consult.Name.."</b>.","verde",10000)
			end

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UNITS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Units(Select)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Units.View then
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM mdt_creative_units WHERE Permission = @Permission ORDER BY Name ASC",{ Permission = Departmenty })
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
	for _,v in ipairs(Consult) do
		table.insert(Table,Select and {
			Value = v.id,
			Label = v.Name
		} or {
			Id = v.id,
			Image = v.Image,
			Name = v.Name,
			Officers = #json.decode(v.Officers)
		})
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETUNIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetUnit(Number,GetOfficers)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Units.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM mdt_creative_units WHERE id = @Number",{ Number = Number })
	if not Consult then
		return false
	end

	local Table = {
		Image = Consult.Image,
		Name = Consult.Name
	}

	if GetOfficers then
		Table.Officers = {}

		if Consult.Officers then
			local Officers = json.decode(Consult.Officers)
			for _,v in pairs(Officers) do
				table.insert(Table.Officers,{
					Passport = v,
					Name = vRP.FullName(v)
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEUNIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateUnit(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty or not Table.Name or not Table.Image then
		return false
	end

	if not Permissions[Passport].Units.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO mdt_creative_units (Name,Image,Permission) VALUES (@Name,@Image,@Permission)",{ Name = Table.Name, Image = Table.Image, Permission = Departmenty })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Unidade criada.","verde")

	return {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEUNIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateUnit(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty or not Table.Id or not Table.Name or not Table.Image then
		return false
	end

	if not Permissions[Passport].Units.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE mdt_creative_units SET Name = @Name, Image = @Image WHERE id = @Id",{ Id = Table.Id, Name = Table.Name, Image = Table.Image })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Unidade atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYUNIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyUnit(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty or not Number then
		return false
	end

	if not Permissions[Passport].Units.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM mdt_creative_units WHERE id = @id",{ id = Number })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Unidade removida.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSIGNUNIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssignUnit(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Units.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Officers,Name FROM mdt_creative_units WHERE id = @Number",{ Number = Table.Id })
	if not Consult or not Consult.Officers then
		return false
	end

	local Officers = json.decode(Consult.Officers)
	for _,v in ipairs(Officers) do
		if Table.Officer == v then
			TriggerClientEvent("mdt:Notify",source,"Atenção","O oficial já está na unidade.","amarelo")
			return false
		end
	end

	table.insert(Officers,Table.Officer)
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Unidade atribuida.","verde")
	exports.oxmysql:update_async("UPDATE mdt_creative_units SET Officers = @Officers WHERE id = @Id",{ Id = Table.Id, Officers = json.encode(Officers) })

	local OtherSource = vRP.Source(Table.Officer)
	if OtherSource then
		TriggerClientEvent("Notify",OtherSource,(Groups[Departmenty].Name or "Policia"),"Você foi adicionado a unidade <b>"..Consult.Name.."</b>.","verde",10000)
	end

	return {
		Passport = Table.Officer,
		Name = vRP.FullName(Table.Officer)
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEUNIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveUnit(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	if not Permissions[Passport].Units.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Officers,Name FROM mdt_creative_units WHERE id = @Number",{ Number = Table.Id })
	if not Consult or not Consult.Officers then
		return false
	end

	local Officers = json.decode(Consult.Officers)
	for Index,Officer in ipairs(Officers) do
		if Table.Officer == Officer then
			table.remove(Officers,Index)
			TriggerClientEvent("mdt:Notify",source,"Sucesso","Unidade removida.","verde")
			exports.oxmysql:update_async("UPDATE mdt_creative_units SET Officers = @Officers WHERE id = @Id",{ Id = Table.Id, Officers = json.encode(Officers) })

			local OtherSource = vRP.Source(Table.Officer)
			if OtherSource then
				TriggerClientEvent("Notify",OtherSource,(Groups[Departmenty].Name or "Policia"),"Você foi removido da unidade <b>"..Consult.Name.."</b>.","verde",10000)
			end

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OFFICERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Officers(Management,Ranking)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not Departmenty then
		return false
	end

	local Medals,Units,Table = {},{},{}
	local NumGroups = vRP.NumGroups(Departmenty)
	if not Management and Permissions[Passport].Management.View then
		if not Ranking then
			Units = exports.oxmysql:query_async("SELECT * FROM mdt_creative_units WHERE Permission = @Permission",{ Permission = Departmenty })
		end

		Medals = exports.oxmysql:query_async("SELECT * FROM mdt_creative_medals")
	end

	for OtherPassport,v in pairs(NumGroups) do
		local OtherPassport = parseInt(OtherPassport)
		local Identity = vRP.Identity(OtherPassport)
		if Identity then
			local TableOfficer = {
				Passport = OtherPassport,
				Name = Identity.Name.." "..Identity.Lastname,
				Patent = v.Level,
				Medals = {},
				Units = {},
				Hours = Ranking and vRP.Playing(OtherPassport,v.Permission) or nil,
				Service = not Ranking and vRP.HasService(OtherPassport,v.Permission) or nil
			}

			if not Management then
				if Medals and #Medals > 0 then
					for _,Medal in pairs(Medals) do
						if Contains(json.decode(Medal.Officers),TableOfficer.Passport) then
							table.insert(TableOfficer.Medals,{ Id = OtherPassport, Name = Medal.Name, Image = Medal.Image })
						end
					end
				end

				if not Ranking and Units and #Units > 0 then
					for _,Unit in pairs(Units) do
						if Contains(json.decode(Unit.Officers),TableOfficer.Passport) then
							table.insert(TableOfficer.Units,{ Id = OtherPassport, Name = Unit.Name, Image = Unit.Image })
						end
					end
				end
			else
				local Calculated = CompleteTimers(os.time() - (Identity.Login or 0),true)
				local Activated = (vRP.Source(OtherPassport) and "Ativo" or "Inativo").." a "..Calculated

				TableOfficer.Status = Activated
			end

			table.insert(Table,TableOfficer)
		else
			vRP.RemovePermission(OtherPassport,Departmenty)
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEOFFICER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateOfficer(Table)
	local source = source
	local OtherPassport = Table.Passport
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or not OtherPassport or Passport == OtherPassport or not Departmenty then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource then
		TriggerClientEvent("mdt:Notify",source,"Atenção","Usuário indisponível no momento.","amarelo")

		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	if not Identity or not Permissions[Passport].Management.Create then
		return false
	end

	if vRP.AmountGroups(Departmenty) >= vRP.Permissions(Departmenty,"Members") then
		TriggerClientEvent("mdt:Notify",source,"Atenção","Limite de membros atingido.","amarelo")

		return false
	end

	if Groups[Departmenty].Type and Groups[Departmenty].Type == "Work" and vRP.GetUserType(OtherPassport,"Work") then
		TriggerClientEvent("mdt:Notify",source,"Atenção","O passaporte já pertence a outro grupo.","amarelo")

		return false
	end

	if vRP.Request(OtherSource,"Grupos","Você foi convidado(a) para participar do grupo <b>"..Departmenty.."</b>, gostaria de estar entrando no mesmo?") then
		vRP.SetPermission(OtherPassport,Departmenty)
		TriggerClientEvent("mdt:Notify",source,"Sucesso","Passaporte adicionado.","verde")
		exports.discord:Embed("Mdt","**[MODO]:** Convidou\n**[POLICIAL]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHYOFFICER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.HierarchyOfficer(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local Mode,OtherPassport = Table.Mode,Table.Passport
	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasGroup(Passport,Departmenty)
	local OfficerLevel = vRP.HasPermission(OtherPassport,Departmenty)

	if not OfficerLevel or not Permissions[Passport].Management.Edit or Passport == OtherPassport then
		return false
	end

	local Modify = (Mode == "Demote" and Level < OfficerLevel and OfficerLevel < #Groups[Departmenty].Hierarchy) or (Mode == "Promote" and OfficerLevel > (Level + 1))
	if not Modify then
		return false
	end

	vRP.SetPermission(OtherPassport,Departmenty,nil,Mode)
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Membro "..(Mode == "Promote" and "promovido" or "rebaixado")..".","verde")

	local OtherSource = vRP.Source(OtherPassport)
	if OtherSource then
		TriggerClientEvent("Notify",OtherSource,(Groups[Departmenty].Name or "Policia"),"Você foi <b>"..(Mode == "Promote" and "promovido" or "rebaixado").."</b> do seu cargo atual.","verde",10000)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMISSOFFICER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DismissOfficer(Table)
	local source = source
	local OtherPassport = Table.Passport
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or Passport == OtherPassport or not Departmenty then
		return false
	end

	local Level = vRP.HasGroup(Passport,Departmenty)
	local OfficerLevel = vRP.HasPermission(OtherPassport,Departmenty)
	if not Permissions[Passport].Management.Dismiss or not OfficerLevel or Level >= OfficerLevel then
		return false
	end

	exports.discord:Embed("Mdt","**[MODO]:** Removeu\n**[POLICIAL]:** "..Passport.."\n**[PASSAPORTE]:** "..OtherPassport)
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Membro removido.","verde")
	vRP.RemovePermission(OtherPassport,Departmenty)

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

	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Permission = @Permission AND Timestamp >= UNIX_TIMESTAMP(DATE_SUB(NOW(),INTERVAL 30 DAY)) ORDER BY Timestamp DESC LIMIT 50",{ Permission = Departmenty })
	if not Consult or #Consult == 0 then
		return false
	end

	local Table = {}
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

	if not vRP.PaymentBank(Passport,Value) then
		Active[Passport] = nil

		return false
	end

	exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Deposit", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Deposito realizado.","verde")
	vRP.PermissionsUpdate(Departmenty,"Bank","+",Value)
	Active[Passport] = nil

	return true
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

	if vRP.Permissions(Departmenty,"Bank") < Value then
		Active[Passport] = nil

		return false
	end

	exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Withdraw", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Saque realizado.","verde")
	vRP.GiveBank(Passport,Value * Config.BankTaxWithdraw)
	vRP.PermissionsUpdate(Departmenty,"Bank","-",Value)
	Active[Passport] = nil

	return true
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
	if not Identity or vRP.Permissions(Departmenty,"Bank") < Value then
		Active[Passport] = nil

		return false
	end

	exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)",{ Type = "Transfer", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = OtherPassport, Permission = Departmenty })
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Transferência realizada.","verde")
	vRP.GiveBank(OtherPassport,Value * Config.BankTaxTransfer,true)
	vRP.PermissionsUpdate(Departmenty,"Bank","-",Value)
	Active[Passport] = nil

	return {
		Passport = OtherPassport,
		Name = Identity.Name.." "..Identity.Lastname
	}
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
	TriggerClientEvent("mdt:Notify",source,"Sucesso","Permissões atualizadas.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVESERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveService(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	if not Passport or Active[Passport] or not Departmenty or not vRP.HasService(OtherPassport,Departmenty) then
		return false
	end

	local OtherSource = vRP.Source(OtherPassport)
	if not OtherSource then
		return false
	end

	vRP.ServiceLeave(OtherSource,OtherPassport,Departmenty,true)
	TriggerClientEvent("ems:Notify",source,"Sucesso","Serviço removido.","verde")

	return true
end
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