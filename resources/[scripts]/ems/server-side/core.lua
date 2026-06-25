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
Tunnel.bindInterface("ems",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Division = {}
local Permissions = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEFAULTPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
local DefaultPermissions = {
	Consultations = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false
	},
	Exams = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false
	},
	MedicPlan = false,
	Announcements = {
		Create = false,
		Edit = false,
		Delete = false
	},
	Bank = {
		View = false,
		Deposit = false,
		Withdraw = false,
		Transfer = false
	},
	Specialties = {
		View = false,
		Create = false,
		Edit = false,
		Delete = false,
		Assign = false
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
-- EMS:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("ems:Open")
AddEventHandler("ems:Open",function(Permission)
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
		Consult = vRP.GetSrvData("EMS:"..Permission,true)
	end

	Division[Passport] = Permission
	Permissions[Passport] = Consult[Levels] or DefaultPermissions

	TriggerClientEvent("ems:Opened",source)
end)
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
				Name = Identity.Name.." "..Identity.Lastname,
				MedicPlan = vRP.DatatableInformation(Search,"MedicPlan") or 0
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
						Name = Identity.Name.." "..Identity.Lastname,
						MedicPlan = vRP.DatatableInformation(v.id,"MedicPlan") or 0
					})
				end
			end
		end
	end

	return Table
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
		Permissions = Permissions[Passport]
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONSULTATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Home()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	Table = {
		Users = {},
		Consultations = {},
		Exams = {}
	}

	local Service = vRP.NumPermission(Departmenty)
	for OtherPassport in pairs(Service) do
		table.insert(Table.Users,{
			Passport = OtherPassport,
			Name = vRP.FullName(OtherPassport)
		})
	end

	local ConsultConsultations = exports.oxmysql:query_async("SELECT * FROM ems_creative_consultations WHERE Permission = @Permission AND Status = @Status ORDER BY Timestamp DESC",{ Permission = Departmenty, Status = "appointment" })
	if ConsultConsultations and #ConsultConsultations > 0 then
		for _,v in ipairs(ConsultConsultations) do
			table.insert(Table.Consultations,{
				Patient = {
					Passport = v.Passport,
					Name = vRP.FullName(v.Passport)
				},
				Doctor = {
					Passport = v.Doctor,
					Name = vRP.FullName(v.Doctor)
				},
				Date = v.Timestamp
			})
		end
	end

	local ConsultExams = exports.oxmysql:query_async("SELECT * FROM ems_creative_exams WHERE Permission = @Permission AND Status = @Status ORDER BY Timestamp DESC",{ Permission = Departmenty, Status = "appointment" })
	if ConsultExams and #ConsultExams > 0 then
		for _,v in ipairs(ConsultExams) do
			table.insert(Table.Exams,{
				Patient = {
					Passport = v.Passport,
					Name = vRP.FullName(v.Passport)
				},
				Doctor = {
					Passport = v.Doctor,
					Name = vRP.FullName(v.Doctor)
				},
				Date = v.Timestamp
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONSULTATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Consultations()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return Table
	end

	if not Permissions[Passport].Consultations.View then
		return Table
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM ems_creative_consultations WHERE Permission = @Permission ORDER BY Timestamp DESC",{ Permission = Departmenty })
	if Consult and #Consult > 0 then
		for _,v in ipairs(Consult) do
			table.insert(Table,{
				Id = v.id,
				Reason = v.Reason,
				Patient = {
					Passport = v.Passport,
					Name = vRP.FullName(v.Passport)
				},
				Doctor = {
					Passport = v.Doctor,
					Name = vRP.FullName(v.Doctor)
				},
				Date = v.Timestamp,
				Status = v.Status,
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetConsultation(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Consultations.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM ems_creative_consultations WHERE id = @Number ORDER BY id LIMIT 1",{ Number = Number })
	if Consult then
		local Identity = vRP.Identity(Consult.Passport)
		if Identity then
			return {
				Id = Consult.id,
				Reason = Consult.Reason,
				Patient = {
					Passport = Consult.Passport,
					Name = vRP.FullName(Consult.Passport)
				},
				Doctor = {
					Passport = Consult.Doctor,
					Name = vRP.FullName(Consult.Doctor)
				},
				Date = Consult.Timestamp,
				Status = Consult.Status,
				Description = Consult.Description
			}
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATECONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateConsultation(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Consultations.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO ems_creative_consultations (Reason,Passport,Doctor,Status,Timestamp,Description,Permission) VALUES (@Reason,@Passport,@Doctor,@Status,@Timestamp,@Description,@Permission)",{ Reason = Table.Reason, Passport = Table.Passport, Doctor = Passport, Status = Table.Status, Timestamp = Table.Date, Description = Table.Description, Permission = Departmenty })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Consulta criada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATECONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateConsultation(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Consultations.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE ems_creative_consultations SET Reason = @Reason, Timestamp = @Timestamp, Status = @Status, Description = @Description WHERE id = @Id",{ Id = Table.Id, Reason = Table.Reason, Timestamp = Table.Date, Status = Table.Status, Description = Table.Description })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Consulta atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYCONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyConsultation(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Consultations.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM ems_creative_consultations WHERE id = @id",{ id = Number })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Consulta removida.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXAMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Exams()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	if not Permissions[Passport].Exams.View then
		return Table
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM ems_creative_exams WHERE Permission = @Permission ORDER BY Timestamp DESC",{ Permission = Departmenty })
	if Consult and #Consult > 0 then
		for _,v in ipairs(Consult) do
			table.insert(Table,{
				Id = v.id,
				Name = v.Name,
				Patient = {
					Passport = v.Passport,
					Name = vRP.FullName(v.Passport)
				},
				Doctor = {
					Passport = v.Doctor,
					Name = vRP.FullName(v.Doctor)
				},
				Date = v.Timestamp,
				Status = v.Status,
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETEXAM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetExam(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Exams.View then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM ems_creative_exams WHERE id = @Number ORDER BY id LIMIT 1",{ Number = Number })
	if Consult then
		local Identity = vRP.Identity(Consult.Passport)
		if Identity then
			return {
				Id = Consult.id,
				Name = Consult.Name,
				Patient = {
					Passport = Consult.Passport,
					Name = vRP.FullName(Consult.Passport)
				},
				Doctor = {
					Passport = Consult.Doctor,
					Name = vRP.FullName(Consult.Doctor)
				},
				Date = Consult.Timestamp,
				Status = Consult.Status,
				Description = Consult.Description
			}
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATECONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateExam(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Exams.Create then
		return false
	end

	exports.oxmysql:insert_async("INSERT INTO ems_creative_exams (Name,Passport,Doctor,Status,Timestamp,Description,Permission) VALUES (@Name,@Passport,@Doctor,@Status,@Timestamp,@Description,@Permission)",{ Name = Table.Name, Passport = Table.Passport, Doctor = Passport, Status = Table.Status, Timestamp = Table.Date, Description = Table.Description, Permission = Departmenty })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Exame criado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATECONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateExam(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Exams.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE ems_creative_exams SET Name = @Name, Timestamp = @Timestamp, Status = @Status, Description = @Description WHERE id = @Id",{ Id = Table.Id, Name = Table.Name, Timestamp = Table.Date, Status = Table.Status, Description = Table.Description })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Exame atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYCONSULTATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyExam(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].Exams.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM ems_creative_exams WHERE id = @id",{ id = Number })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Exame removido.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.User(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local OtherPassport = parseInt(OtherPassport)

	if not Passport or Active[Passport] or not Departmenty then
		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	if Identity then
		return {
			Passport = OtherPassport,
			Name = Identity.Name.." "..Identity.Lastname,
			Blood = Sanguine(Identity.Blood),
			Phone = vRP.Phone(OtherPassport),
			MedicPlan = vRP.DatatableInformation(OtherPassport,"MedicPlan") or 0,
			Avatar = exports.vrp:Avatar(OtherPassport,Departmenty)
		}
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERCONSULTATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UserConsultations(OtherPassport)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local OtherPassport = parseInt(OtherPassport)

	if not Passport or Active[Passport] or not Departmenty then
		return Table
	end

	if not Permissions[Passport].Consultations.View then
		return Table
	end

	local Identity = vRP.Identity(OtherPassport)
	if Identity then
		local Consult = exports.oxmysql:query_async("SELECT * FROM ems_creative_consultations WHERE Passport = @Passport AND Permission = @Permission ORDER BY Timestamp DESC",{ Passport = OtherPassport, Permission = Departmenty })

		if Consult and #Consult > 0 then
			for _,v in ipairs(Consult) do
				table.insert(Table,{
					Id = v.id,
					Reason = v.Reason,
					Patient = {
						Passport = v.Passport,
						Name = vRP.FullName(v.Passport)
					},
					Doctor = {
						Passport = v.Doctor,
						Name = vRP.FullName(v.Doctor)
					},
					Date = v.Timestamp,
					Status = v.Status
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USEREXAMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UserExams(OtherPassport)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local OtherPassport = parseInt(OtherPassport)

	if not Passport or Active[Passport] or not Departmenty then
		return Table
	end

	if not Permissions[Passport].Exams.View then
		return Table
	end

	local Identity = vRP.Identity(OtherPassport)
	if Identity then
		local Consult = exports.oxmysql:query_async("SELECT * FROM ems_creative_exams WHERE Passport = @Passport AND Permission = @Permission ORDER BY Timestamp DESC",{ Passport = OtherPassport, Permission = Departmenty })

		if Consult and #Consult > 0 then
			for _,v in ipairs(Consult) do
				table.insert(Table,{
					Id = v.id,
					Name = v.Name,
					Patient = {
						Passport = v.Passport,
						Name = vRP.FullName(v.Passport)
					},
					Doctor = {
						Passport = v.Doctor,
						Name = vRP.FullName(v.Doctor)
					},
					Date = v.Timestamp,
					Status = v.Status
				})
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AVATAR
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Avatar(OtherPassport,Link)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local OtherPassport = parseInt(OtherPassport)

	if not Passport or not OtherPassport or Active[Passport] or not Departmenty then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM avatars WHERE Passport = @Passport AND Permission = @Permission LIMIT 1",{ Passport = OtherPassport, Permission = Departmenty })
	if Consult then
		exports.oxmysql:update_async("UPDATE avatars SET Image = @Image WHERE Passport = @Passport AND Permission = @Permission",{ Passport = OtherPassport, Image = Link, Permission = Departmenty })
	else
		exports.oxmysql:insert_async("INSERT INTO avatars (Passport,Image,Permission) VALUES (@Passport,@Image,@Permission)",{ Passport = OtherPassport, Image = Link, Permission = Departmenty })
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MEDICPLAN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MedicPlan(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local OtherPassport = parseInt(OtherPassport)

	if not Passport or not OtherPassport or Active[Passport] or not Departmenty then
		return false
	end

	if not Permissions[Passport].MedicPlan then
		return false
	end

	local CurrentTimer = os.time()
	local ActualPlan = vRP.DatatableInformation(OtherPassport,"MedicPlan") or 0
	local UpdatePlan = (ActualPlan > CurrentTimer and ActualPlan + Config.MedicPlanDuration) or (CurrentTimer + Config.MedicPlanDuration)

	vRP.UpdateDatatable(OtherPassport,"MedicPlan",UpdatePlan)
	TriggerClientEvent("ems:Notify",source,"Sucesso","Plano médico atualizado.","verde")

	return UpdatePlan
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
	local Specialties = exports.oxmysql:query_async("SELECT * FROM ems_creative_specialties WHERE Permission = @Permission",{ Permission = Departmenty })

	for OtherPassport,v in pairs(NumGroups) do
		local OtherPassport = parseInt(OtherPassport)
		local Identity = vRP.Identity(OtherPassport)
		if Identity then
			local TablePlayer = {
				Passport = OtherPassport,
				Name = Identity.Name.." "..Identity.Lastname,
				Hierarchy = v.Level,
				Specialties = {}
			}

			if Ranking then
				TablePlayer.Hours = vRP.Playing(OtherPassport,v.Permission)
			else
				local Calculated = CompleteTimers(os.time() - (Identity.Login or 0),true)
				local Activated = (vRP.Source(OtherPassport) and "Ativo" or "Inativo").." a "..Calculated

				TablePlayer.Status = Activated
				TablePlayer.Service = vRP.HasService(OtherPassport,v.Permission)
			end

			if Specialties and #Specialties > 0 then
				for _,Specialty in pairs(Specialties) do
					local Members = json.decode(Specialty.Members)
					if Contains(Members,TablePlayer.Passport) then
						table.insert(TablePlayer.Specialties,Specialty.Name)
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
-- SPECIALTIES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Specialties()
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	if not Permissions[Passport].Specialties.View then
		return Table
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM ems_creative_specialties WHERE Permission = @Permission ORDER BY Name ASC",{ Permission = Departmenty })
	if Consult and #Consult > 0 then
		for _,v in ipairs(Consult) do
			table.insert(Table,{
				Id = v.id,
				Name = v.Name,
				Members = #json.decode(v.Members)
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETSPECIALTY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetSpecialty(Number)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return Table
	end

	if not Permissions[Passport].Specialties.View then
		return Table
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM ems_creative_specialties WHERE id = @Number",{ Number = Number })
	if Consult then
		Table = {
			Id = Consult.id,
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
-- CREATESPECIALTY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateSpecialty(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if exports.oxmysql:scalar_async("SELECT COUNT(Permission) FROM ems_creative_specialties WHERE Permission = @Permission",{ Permission = Departmenty }) >= Config.MaxSpecialties then
		TriggerClientEvent("ems:Notify",source,"Atenção","Limite de especialidades atingido.","amarelo")

		return false
	end

	if not Permissions[Passport].Specialties.Create then
		return false
	end

	local Number = exports.oxmysql:insert_async("INSERT INTO ems_creative_specialties (Name,Permission) VALUES (@Name,@Permission)",{ Name = Table.Name, Permission = Departmenty })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Especialidade criada.","verde")

	return Number
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATESPECIALTY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateSpecialty(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Specialties.Edit then
		return false
	end

	exports.oxmysql:update_async("UPDATE ems_creative_specialties SET Name = @Name WHERE id = @Id",{ Id = Table.Id, Name = Table.Name })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Especialidade atualizada.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYSPECIALTY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroySpecialty(Number)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Specialties.Delete then
		return false
	end

	exports.oxmysql:query_async("DELETE FROM ems_creative_specialties WHERE id = @id",{ id = Number })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Especialidade removida.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSIGNSPECIALTY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssignSpecialty(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not Table.Passport or not vRP.HasService(Passport,Departmenty) or not vRP.HasPermission(Table.Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Specialties.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Members,Name FROM ems_creative_specialties WHERE id = @Number",{ Number = Table.Id })
	if Consult and Consult.Members then
		local Members = json.decode(Consult.Members)
		for _,v in ipairs(Members) do
			if Table.Passport == v then
				return false
			end
		end

		table.insert(Members,Table.Passport)
		TriggerClientEvent("ems:Notify",source,"Sucesso","Especialidade atribuida.","verde")
		exports.oxmysql:update_async("UPDATE ems_creative_specialties SET Members = @Members WHERE id = @Id",{ Id = Table.Id, Members = json.encode(Members) })

		local OtherSource = vRP.Source(Table.Passport)
		if OtherSource then
			TriggerClientEvent("Notify",OtherSource,Consult.Name,"Parabéns você recebeu uma especialidade.","verde",10000)
		end

		return { Passport = Table.Passport, Name = vRP.FullName(Table.Passport) }
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVESPECIALTY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveSpecialty(Table)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or not vRP.HasService(Passport,Departmenty) then
		return false
	end

	if not Permissions[Passport].Specialties.Assign then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT Members FROM ems_creative_specialties WHERE id = @Number",{ Number = Table.Id })
	if Consult and Consult.Members then
		local Members = json.decode(Consult.Members)
		for Index,v in ipairs(Members) do
			if Table.Passport == v then
				table.remove(Members,Index)
				TriggerClientEvent("ems:Notify",source,"Sucesso","Especialidade removida.","verde")
				exports.oxmysql:update_async("UPDATE ems_creative_specialties SET Members = @Members WHERE id = @Id",{ Id = Table.Id, Members = json.encode(Members) })

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
		TriggerClientEvent("ems:Notify",source,"Atenção","Usuário indisponível no momento.","amarelo")

		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	if not Identity or not Permissions[Passport].Management.Create then
		return false
	end

	if vRP.AmountGroups(Departmenty) >= vRP.Permissions(Departmenty,"Members") then
		TriggerClientEvent("ems:Notify",source,"Atenção","Limite de membros atingido.","amarelo")

		return false
	end

	if Groups[Departmenty].Type and vRP.GetUserType(OtherPassport,Groups[Departmenty].Type) then
		TriggerClientEvent("ems:Notify",source,"Atenção","O passaporte já pertence a outro grupo.","amarelo")

		return false
	end

	if vRP.Request(OtherSource,"Grupos","Você foi convidado(a) para participar do grupo <b>"..Departmenty.."</b>, gostaria de estar entrando no mesmo?") then
		vRP.SetPermission(OtherPassport,Departmenty)
		TriggerClientEvent("ems:Notify",source,"Sucesso","Passaporte adicionado.","verde")

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
		TriggerClientEvent("ems:Notify",source,"Sucesso","Membro "..(Mode == "Promote" and "promovido" or "rebaixado")..".","verde")

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
		TriggerClientEvent("ems:Notify",source,"Sucesso","Membro removido.","verde")
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
		TriggerClientEvent("ems:Notify",source,"Atenção","Limite de avisos atingido.","amarelo")

		return false
	end

	local Number = exports.oxmysql:insert_async("INSERT INTO painel_creative_announcements (Title,Description,Timestamp,Permission) VALUES (@Title,@Description,@Timestamp,@Permission)",{ Title = Table.Title, Description = Table.Description, Timestamp = os.time(), Permission = Departmenty })
	TriggerClientEvent("ems:Notify",source,"Sucesso","Aviso criado.","verde")

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
	TriggerClientEvent("ems:Notify",source,"Sucesso","Aviso atualizado.","verde")

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
	TriggerClientEvent("ems:Notify",source,"Sucesso","Aviso removido.","verde")

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
		TriggerClientEvent("ems:Notify",source,"Sucesso","Deposito realizado.","verde")
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
		TriggerClientEvent("ems:Notify",source,"Sucesso","Saque realizado.","verde")
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
		TriggerClientEvent("ems:Notify",source,"Sucesso","Transferência realizada.","verde")
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
	local Consult = vRP.GetSrvData("EMS:"..Departmenty,true)

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

	vRP.SetSrvData("EMS:"..Departmenty,Table,true)
	TriggerClientEvent("ems:Notify",source,"Sucesso","Permissões atualizadas.","verde")

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