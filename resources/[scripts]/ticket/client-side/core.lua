-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("ticket")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local IsAdmin = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET:DYNAMIC
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("ticket:Dynamic",function()
	exports.dynamic:AddButton("Atendimento","Abrir a central de suporte.","ticket:Opened",false,false,false)
	if LocalPlayer.state[Config.Administrator] then
		exports.dynamic:AddButton("Atendimento","Abrir a central de administração.","ticket:Opened",true,false,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("ticket:Opened",function(Admin)
	IsAdmin = Admin
	SetNuiFocus(true,true)
	TransitionToBlurred(1000)
	SetCursorLocation(0.5,0.5)
	TriggerEvent("dynamic:Close")
	TriggerEvent("hud:Active",false)

	SendNUIMessage({
		Action = IsAdmin and "OpenAdmin" or "OpenTickets",
		Payload = {
			Player = {
				Name = LocalPlayer.state.Name,
				Passport = LocalPlayer.state.Passport
			},
			Permissions = not IsAdmin and {} or {
				Characters = {
					View = false,
					Spectate = false,
					Revive = false,
					Kill = false,
					Freeze = false,
					Goto = false,
					Bring = false,
					Waypoint = false,
					SendPrivateMessage = false,
					AddGroup = false,
					RemoveGroup = false,
					Screenshot = false,
					ClearInventory = false,
					SetPed = false,
					Bank = {
						View = false,
						Add = false,
						Remove = false
					},
					Gemstone = {
						View = false,
						Add = false,
						Remove = false
					}
				},
				Tickets = true
			}
		}
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("ticket:Notify")
AddEventHandler("ticket:Notify",function(Title,Message,Type)
	SendNUIMessage({ Action = "Notify", Payload = { Title = Title, Message = Message, Type = Type } })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("ticket:Update")
AddEventHandler("ticket:Update",function(Table)
	SendNUIMessage({ Action = "UpdateTicket", Payload = Table })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	SetNuiFocus(false,false)
	SetCursorLocation(0.5,0.5)
	TransitionFromBlurred(1000)
	TriggerEvent("hud:Active",true)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Config",function(Data,Callback)
	Callback({
		Cooldown = Config.Cooldown,
		Categories = Config.Categories,
		BaseMode = BaseMode
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKETS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Tickets",function(Data,Callback)
	Callback(vSERVER.Tickets(IsAdmin))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Ticket",function(Data,Callback)
	Callback(vSERVER.Ticket(Data.Id))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("SendMessage",function(Data,Callback)
	Callback(vSERVER.SendMessage(Data.Id,Data.Message))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CloseTicket",function(Data,Callback)
	Callback(vSERVER.CloseTicket(Data.Id,Data.Message))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REOPENTICKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("ReopenTicket",function(Data,Callback)
	Callback(vSERVER.ReopenTicket(Data.Id))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDPARTICIPANT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("AddParticipant",function(Data,Callback)
	Callback(vSERVER.AddParticipant(Data.Id,Data.Passport))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEPARTICIPANT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("RemoveParticipant",function(Data,Callback)
	Callback(vSERVER.RemoveParticipant(Data.Id,Data.Passport))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSUMETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("AssumeTicket",function(Data,Callback)
	Callback(vSERVER.AssumeTicket(Data.Id))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHANGESUBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("ChangeSubject",function(Data,Callback)
	Callback(vSERVER.ChangeSubject(Data.Id,Data.Subject))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHANGECATEGORY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("ChangeCategory",function(Data,Callback)
	Callback(vSERVER.ChangeCategory(Data.Id,Data.Category))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOADMESSAGES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("LoadMessages",function(Data,Callback)
	Callback(vSERVER.LoadMessages(Data.Id,Data.Before))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATETICKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CreateTicket",function(Data,Callback)
	Callback(vSERVER.CreateTicket(Data.Subject,Data.Category,Data.Message))
end)