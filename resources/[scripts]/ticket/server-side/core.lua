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
Tunnel.bindInterface("ticket",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local CooldownError = {}
local CooldownCreate = {}
local CooldownMessage = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKETS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Tickets(IsAdmin)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return Table
	end

	local ConsultTicket = {}
	if IsAdmin and vRP.HasGroup(Passport,Config.Administrator) then
		ConsultTicket = exports.oxmysql:query_async("SELECT t.*, m.Staff as LastMessageStaff FROM tickets_creative t LEFT JOIN tickets_creative_messages m ON t.id = m.Ticket AND m.CreatedAt = (SELECT MAX(CreatedAt) FROM tickets_creative_messages WHERE Ticket = t.id) WHERE t.Author <> ? ORDER BY t.CreatedAt DESC",{ Passport })
	else
		ConsultTicket = exports.oxmysql:query_async("SELECT t.*, m.Staff as LastMessageStaff FROM tickets_creative t LEFT JOIN tickets_creative_messages m ON t.id = m.Ticket AND m.CreatedAt = (SELECT MAX(CreatedAt) FROM tickets_creative_messages WHERE Ticket = t.id) WHERE t.Author = ? OR t.Members LIKE ? ORDER BY t.CreatedAt DESC",{ Passport,'%"'..Passport..'":true%' })
	end

	if not ConsultTicket or #ConsultTicket <= 0 then
		return Table
	end

	for _,v in ipairs(ConsultTicket) do
		Table[#Table + 1] = {
			Id = v.id,
			Subject = v.Subject,
			Category = v.Category,
			Assumed = v.Assumed and vRP.FullName(v.Assumed) or false,
			CreatedAt = v.CreatedAt,
			Status = v.Status,
			NewMessage = not v.LastMessageStaff
		}
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Ticket(Number)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return Table
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return Table
	end

	local ListMembers = {}
	local Account = vRP.AccountOptimize(ConsultTicket.Author)
	local Members = json.decode(ConsultTicket.Members or "[]")
	for OtherPassport,Participant in pairs(Members) do
		ListMembers[#ListMembers + 1] = {
			Passport = OtherPassport,
			Name = vRP.FullName(OtherPassport),
			Participant = Participant
		}
	end

	Table = {
		Subject = ConsultTicket.Subject,
		Status = ConsultTicket.Status,
		Category = ConsultTicket.Category,
		CreatedAt = ConsultTicket.CreatedAt,
		ClosedAt = ConsultTicket.ClosedAt,
		Assumed = ConsultTicket.Assumed and vRP.FullName(ConsultTicket.Assumed) or false,
		Author = {
			Passport = ConsultTicket.Author,
			Name = vRP.FullName(ConsultTicket.Author),
			Discord = Account.Discord,
			License = Account.License
		},
		Members = ListMembers,
		Messages = {}
	}

	local ConsultMessages = exports.oxmysql:query_async("SELECT * FROM tickets_creative_messages WHERE Ticket = ? ORDER BY CreatedAt DESC LIMIT ?",{ Number,Config.MessagesLoad })
	for _,v in ipairs(ConsultMessages) do
		Table.Messages[#Table.Messages + 1] = {
			Id = v.id,
			Type = v.Type,
			Author = v.Type == "User" and { Passport = v.Author, Staff = v.Staff } or false,
			Message = v.Message,
			CreatedAt = v.CreatedAt
		}
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SendMessage(Number,Message)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local CurrentTimer = os.time()
	if CooldownMessage[Passport] and CooldownMessage[Passport] >= CurrentTimer then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket or not ConsultTicket.Status then
		return false
	end

	CooldownMessage[Passport] = CurrentTimer + Config.Cooldown

	local MembersList = false
	local Passport = tostring(Passport)
	local Members = json.decode(ConsultTicket.Members or "[]")
	if not Members[Passport] then
		MembersList = true
		Members[Passport] = false
		exports.oxmysql:update_async("UPDATE tickets_creative SET Members = ? WHERE id = ?",{ json.encode(Members),Number })
	end

	local UpdateList = {}
	local FormattedMembers = MembersList and {} or false
	for OtherPassport,Participant in pairs(Members) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end

		if MembersList and FormattedMembers then
			FormattedMembers[#FormattedMembers + 1] = {
				Passport = OtherPassport,
				Name = vRP.FullName(OtherPassport),
				Participant = Participant
			}
		end
	end

	local Admins = vRP.DataGroups(Config.Administrator)
	for OtherPassport in pairs(Admins) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	local IsAdmin = vRP.HasGroup(Passport,Config.Administrator)
	local MessageNumber = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (?,?,?,?,?,?)",{ Number,"User",Passport,IsAdmin,Message,CurrentTimer })

	for _,OtherSource in pairs(UpdateList) do
		async(function()
			TriggerClientEvent("ticket:Update",OtherSource,{
				Id = Number,
				Members = FormattedMembers,
				Message = {
					Id = MessageNumber,
					Type = "User",
					Author = {
						Passport = parseInt(Passport),
						Staff = IsAdmin
					},
					Message = Message,
					CreatedAt = CurrentTimer
				}
			})
		end)
	end

	if Passport ~= ConsultTicket.Author then
		local source = vRP.Source(ConsultTicket.Author)
		if source then
			TriggerClientEvent("Notify",source,"Aviso","Nova mensagem no seu atendimento.","amarelo",5000)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CloseTicket(Number,Message)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return false
	end

	local UpdateList = {}
	local CurrentTimer = os.time()
	local Members = json.decode(ConsultTicket.Members or "[]")
	for OtherPassport in pairs(Members) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	local Admins = vRP.DataGroups(Config.Administrator)
	for OtherPassport in pairs(Admins) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	exports.oxmysql:update_async("UPDATE tickets_creative SET Status = ?, ClosedAt = ? WHERE id = ?",{ false,CurrentTimer,Number })
	local Consult = exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Message,CreatedAt) VALUES (@Ticket,@Type,@Message,@CreatedAt)",{ Ticket = Number, Type = "System", Message = Message, CreatedAt = CurrentTimer })

	for _,OtherSource in pairs(UpdateList) do
		async(function()
			TriggerClientEvent("ticket:Update",OtherSource,{
				Id = Number,
				Status = false,
				ClosedAt = CurrentTimer,
				Message = {
					Id = Consult,
					Type = "System",
					Message = Message,
					CreatedAt = CurrentTimer
				}
			})
		end)
	end

	if Passport ~= ConsultTicket.Author then
		local source = vRP.Source(ConsultTicket.Author)
		if source then
			TriggerClientEvent("Notify",source,"Aviso","Atendimento encerrado.","amarelo",5000)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REOPENTICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ReopenTicket(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return false
	end

	exports.oxmysql:update_async("UPDATE tickets_creative SET Status = ?, ClosedAt = ? WHERE id = ?",{ true,nil,Number })

	local UpdateList = {}
	local Members = json.decode(ConsultTicket.Members or "[]")
	for OtherPassport in pairs(Members) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	local Admins = vRP.DataGroups(Config.Administrator)
	for OtherPassport in pairs(Admins) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	for _,OtherSource in pairs(UpdateList) do
		async(function()
			TriggerClientEvent("ticket:Update",OtherSource,{
				Id = Number,
				Status = true,
				ClosedAt = 0
			})
		end)
	end

	if Passport ~= ConsultTicket.Author then
		local source = vRP.Source(ConsultTicket.Author)
		if source then
			TriggerClientEvent("Notify",source,"Aviso","Atendimento reaberto.","amarelo",5000)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDPARTICIPANT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AddParticipant(Number,TargetPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Identity = vRP.Identity(TargetPassport)
	if not Identity then
		TriggerClientEvent("ticket:Notify",source,"Aviso","Passaporte indisponível.","amarelo")
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return false
	end

	local TargetPassport = tostring(TargetPassport)
	local IsAdmin = vRP.HasGroup(TargetPassport,Config.Administrator)
	if IsAdmin then
		TriggerClientEvent("ticket:Notify",source,"Aviso","Membros da administração não podem ser adicionados.","amarelo")
		return false
	end

	local Members = json.decode(ConsultTicket.Members or "[]")
	if not Members[TargetPassport] then
		Members[TargetPassport] = true
		exports.oxmysql:update_async("UPDATE tickets_creative SET Members = ? WHERE id = ?",{ json.encode(Members),Number })

		local UpdateList = {}
		local MembersList = {}
		local TargetName = vRP.FullName(TargetPassport)
		for OtherPassport,Participant in pairs(Members) do
			local OtherSource = vRP.Source(OtherPassport)
			if OtherSource and not UpdateList[OtherPassport] then
				UpdateList[OtherPassport] = OtherSource
			end

			MembersList[#MembersList + 1] = {
				Passport = OtherPassport,
				Name = vRP.FullName(OtherPassport),
				Participant = Participant
			}
		end

		local Admins = vRP.DataGroups(Config.Administrator)
		for OtherPassport in pairs(Admins) do
			local OtherSource = vRP.Source(OtherPassport)
			if OtherSource and not UpdateList[OtherPassport] then
				UpdateList[OtherPassport] = OtherSource
			end
		end

		for _,OtherSource in pairs(UpdateList) do
			async(function()
				TriggerClientEvent("ticket:Update",OtherSource,{
					Id = Number,
					Members = MembersList
				})
			end)
		end

		return TargetName
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEPARTICIPANT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveParticipant(Number,TargetPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return false
	end

	local TargetPassport = tostring(TargetPassport)
	local Members = json.decode(ConsultTicket.Members or "[]")
	if Members[TargetPassport] then
		Members[TargetPassport] = false
		exports.oxmysql:update_async("UPDATE tickets_creative SET Members = ? WHERE id = ?",{ json.encode(Members),Number })

		local UpdateList = {}
		local MembersList = {}
		for OtherPassport,Participant in pairs(Members) do
			local OtherSource = vRP.Source(OtherPassport)
			if OtherSource and not UpdateList[OtherPassport] then
				UpdateList[OtherPassport] = OtherSource
			end

			MembersList[#MembersList + 1] = {
				Passport = OtherPassport,
				Name = vRP.FullName(OtherPassport),
				Participant = Participant
			}
		end

		local Admins = vRP.DataGroups(Config.Administrator)
		for OtherPassport in pairs(Admins) do
			local OtherSource = vRP.Source(OtherPassport)
			if OtherSource and not UpdateList[OtherPassport] then
				UpdateList[OtherPassport] = OtherSource
			end
		end

		for _,OtherSource in pairs(UpdateList) do
			async(function()
				TriggerClientEvent("ticket:Update",OtherSource,{
					Id = Number,
					Members = MembersList
				})
			end)
		end

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSUMETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssumeTicket(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket or ConsultTicket.Assumed == Passport then
		return false
	end

	exports.oxmysql:update_async("UPDATE tickets_creative SET Assumed = ? WHERE id = ?",{ Passport,Number })

	local UpdateList = {}
	local FullName = vRP.FullName(Passport)
	local Members = json.decode(ConsultTicket.Members or "[]")
	for OtherPassport,Participant in pairs(Members) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	local Admins = vRP.DataGroups(Config.Administrator)
	for OtherPassport in pairs(Admins) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	for _,OtherSource in pairs(UpdateList) do
		async(function()
			TriggerClientEvent("ticket:Update",OtherSource,{
				Id = Number,
				Assumed = FullName
			})
		end)
	end

	if Passport ~= ConsultTicket.Author then
		local source = vRP.Source(ConsultTicket.Author)
		if source then
			TriggerClientEvent("Notify",source,"Aviso","Atendimento assumido por um moderador.","amarelo",5000)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHANGESUBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ChangeSubject(Number,Title)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return false
	end

	exports.oxmysql:update_async("UPDATE tickets_creative SET Subject = ? WHERE id = ?",{ Title,Number })

	local UpdateList = {}
	local Members = json.decode(ConsultTicket.Members or "[]")
	for OtherPassport,Participant in pairs(Members) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	local Admins = vRP.DataGroups(Config.Administrator)
	for OtherPassport in pairs(Admins) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	for _,OtherSource in pairs(UpdateList) do
		async(function()
			TriggerClientEvent("ticket:Update",OtherSource,{
				Id = Number,
				Subject = Title
			})
		end)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHANGECATEGORY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ChangeCategory(Number,Category)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return false
	end

	exports.oxmysql:update_async("UPDATE tickets_creative SET Category = ? WHERE id = ?",{ Category,Number })

	local UpdateList = {}
	local Members = json.decode(ConsultTicket.Members or "[]")
	for OtherPassport,Participant in pairs(Members) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	local Admins = vRP.DataGroups(Config.Administrator)
	for OtherPassport in pairs(Admins) do
		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource and not UpdateList[OtherPassport] then
			UpdateList[OtherPassport] = OtherSource
		end
	end

	for _,OtherSource in pairs(UpdateList) do
		async(function()
			TriggerClientEvent("ticket:Update",OtherSource,{
				Id = Number,
				Category = Category
			})
		end)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOADMESSAGES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.LoadMessages(Number,Before)
	local Table = {}
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return Table
	end

	local ConsultTicket = exports.oxmysql:single_async("SELECT * FROM tickets_creative WHERE id = ? LIMIT 1",{ Number })
	if not ConsultTicket then
		return Table
	end

	local BeforeTimer = Before or os.time()
	local ConsultMessages = exports.oxmysql:query_async("SELECT * FROM tickets_creative_messages WHERE Ticket = ? AND CreatedAt < ? ORDER BY CreatedAt DESC LIMIT ?",{ Number,BeforeTimer,Config.MessagesLoad })
	for _,v in ipairs(ConsultMessages) do
		Table[#Table + 1] = {
			Id = v.id,
			Type = v.Type,
			Author = v.Type == "User" and { Passport = v.Author, Staff = v.Staff } or false,
			Message = v.Message,
			CreatedAt = v.CreatedAt
		}
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateTicket(Subject,Category,Message)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local CurrentTimer = os.time()
	if CooldownCreate[Passport] and CooldownCreate[Passport] >= CurrentTimer then
		TriggerClientEvent("ticket:Notify",source,"Aviso","Você não pode abrir um novo atendimento no momento.","amarelo")
		return false
	end

	if CooldownError[Passport] and CooldownError[Passport] >= CurrentTimer then
		TriggerClientEvent("ticket:Notify",source,"Aviso","Tente novamente mais tarde.","amarelo")
		return false
	end

	local ConsultTicket = exports.oxmysql:scalar_async("SELECT COUNT(Author) FROM tickets_creative WHERE Author = ? AND Status = 1 AND Category = ?",{ Passport,Category })
	if ConsultTicket >= Config.MaxTicketCategory then
		TriggerClientEvent("ticket:Notify",source,"Aviso","Limite de atendimento atingido nessa categoria.","amarelo")
		CooldownError[Passport] = CurrentTimer + 10
		return false
	end

	CooldownCreate[Passport] = CurrentTimer + Config.CreateInterval

	local IsAdmin = vRP.HasGroup(Passport,Config.Administrator)
	local Number = exports.oxmysql:insert_async("INSERT INTO tickets_creative (Subject,Category,Author,CreatedAt,Members) VALUES (@Subject,@Category,@Author,@CreatedAt,@Members)",{ Subject = Subject, Category = Category, CreatedAt = CurrentTimer, Author = Passport, Members = '{"'..Passport..'":true}' })
	exports.oxmysql:insert_async("INSERT INTO tickets_creative_messages (Ticket,Type,Author,Staff,Message,CreatedAt) VALUES (@Ticket,@Type,@Author,@Staff,@Message,@CreatedAt)",{ Ticket = Number, Type = "User", Author = Passport, Staff = IsAdmin, Message = Message, CreatedAt = CurrentTimer })

	local Service = vRP.NumPermission(Config.Administrator)
	for _,OtherSource in pairs(Service) do
		async(function()
			TriggerClientEvent("Notify",OtherSource,"Aviso","Novo atendimento encontrado.","amarelo",5000)
		end)
	end

	return Number
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if CooldownError[Passport] then
		CooldownError[Passport] = nil
	end

	if CooldownMessage[Passport] then
		CooldownMessage[Passport] = nil
	end
end)