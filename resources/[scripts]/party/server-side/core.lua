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
Tunnel.bindInterface("party",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Markers = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
local Config = {
	Room = {},
	Users = {}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- COUNTUSERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function CountUsers(Table)
	return Table and next(Table) and CountTable(Table) or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPASSPORT
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetPassport(source)
	return source and vRP.Passport(source)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETROOM
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetRoom(Selected)
	local Room = Selected and Config.Room[Selected]
	if Room and Room.Users then
		return Room
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEUSERFROMROOM
-----------------------------------------------------------------------------------------------------------------------------------------
local function RemoveUserFromRoom(Room,Passport,Source)
	if Source then
		TriggerClientEvent("party:Close",Source)
	end

	if Markers[Passport] then
		for _,OtherSource in pairs(Room.Users) do
			TriggerClientEvent("party:MarkerDelete",OtherSource,Passport)
		end

		Markers[Passport] = nil
	end

	Room.Users[Passport] = nil
	Config.Users[Passport] = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NOTIFYROOM
-----------------------------------------------------------------------------------------------------------------------------------------
local function NotifyRoom(Room,Event,Passport,Data)
	if not (Room and Room.Users) then
		return false
	end

	for _,OtherSource in pairs(Room.Users) do
		TriggerClientEvent(Event,OtherSource,Passport,Data)
	end

	if Event == "party:MarkerDelete" and Markers[Passport] then
		Markers[Passport] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROMOTENEWOWNER
-----------------------------------------------------------------------------------------------------------------------------------------
local function PromoteNewOwner(Selected)
	local Room = GetRoom(Selected)
	if not Room then
		return
	end

	if CountUsers(Room.Users) <= 0 then
		Config.Room[Selected] = nil
		return false
	end

	local NewOwnerPassport
	for Passport in pairs(Room.Users) do
		if not NewOwnerPassport or Passport < NewOwnerPassport then
			NewOwnerPassport = Passport
		end
	end

	if NewOwnerPassport then
		Room.Created = NewOwnerPassport
		Room.Identity = vRP.FullName(NewOwnerPassport)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDEXISTINGMARKERSTOSOURCE
-----------------------------------------------------------------------------------------------------------------------------------------
local function SendExistingMarkersToSource(Selected,Source,Passport)
	if not Source then
		return false
	end

	for OtherPassport,MarkerData in pairs(Markers) do
		if MarkerData.Party == Selected then
			TriggerClientEvent("party:MarkerAdd",Source,OtherPassport,MarkerData)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETROOMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetRooms()
	local source = source
	local Passport = GetPassport(source)
	if not Passport then
		return false
	end

	local Rooms = {}
	for _,Room in pairs(Config.Room) do
		Rooms[#Rooms + 1] = {
			Id = Room.Id,
			Name = Room.Name,
			Creator = Room.Created,
			Identity = Room.Identity,
			Members = CountUsers(Room.Users),
			Mode = Room.Password and "private" or "public"
		}
	end

	return {
		Passport = Passport,
		Group = Config.Users[Passport] or false,
		Rooms = Rooms
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMEMBERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetMembers(Selected)
	local source = source
	local Room = GetRoom(Selected)
	local Passport = GetPassport(source)
	if not (Passport and Room) then
		return false
	end

	local Members = {}
	for OtherPassport in pairs(Room.Users) do
		Members[#Members + 1] = {
			Passport = OtherPassport,
			Name = vRP.FullName(OtherPassport)
		}
	end

	return Members
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEROOM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateRoom(Name,Password)
	local source = source
	local Passport = GetPassport(source)
	if not Passport or Config.Users[Passport] then
		return false
	end

	repeat
		Selected = GenerateString("DLDLDL")
	until Selected and not Config.Room[Selected]

	Config.Room[Selected] = {
		Name = Name,
		Id = Selected,
		Created = Passport,
		Password = Password,
		Identity = vRP.FullName(Passport),
		Users = { [Passport] = source }
	}

	Config.Users[Passport] = Selected

	return Selected
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICKMEMBER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.KickMember(Selected,OtherPassport)
	local source = source
	local Room = GetRoom(Selected)
	local Passport = GetPassport(source)
	local OtherPassport = parseInt(OtherPassport)
	if not (Passport and Room and Room.Users[Passport]) then
		return false
	end

	if Room.Created == OtherPassport then
		PromoteNewOwner(Selected)
	end

	local OtherSource = vRP.Source(OtherPassport)
	if OtherSource then
		RemoveUserFromRoom(Room,OtherPassport,OtherSource)
	else
		if Markers[OtherPassport] and Markers[OtherPassport].Party == Selected then
			Markers[OtherPassport] = nil
		end

		Room.Users[OtherPassport] = nil
		Config.Users[OtherPassport] = nil
	end

	if CountUsers(Room.Users) <= 0 then
		Config.Room[Selected] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTERROOM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.EnterRoom(Selected,Password)
	local source = source
	local Room = GetRoom(Selected)
	local Passport = GetPassport(source)
	if not (Passport and Room and not Config.Users[Passport] and CountUsers(Room.Users) < MaxMembersParty) then
		return false
	end

	if Room.Password and Room.Password ~= Password then
		return false
	end

	Room.Users[Passport] = source
	Config.Users[Passport] = Selected

	SendExistingMarkersToSource(Selected,source,Passport)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROOM
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Room",function(Passport,source,Radius,Max)
	local Members = {}
	local Selected = Config.Users[Passport]
	local Room = GetRoom(Selected)

	if not (Room and vRP.DoesEntityExist(source)) then
		return Members,0
	end

	local Coords = vRP.GetEntityCoords(source)
	for OtherPassport,OtherSource in pairs(Room.Users) do
		if vRP.DoesEntityExist(OtherSource) and #(Coords - vRP.GetEntityCoords(OtherSource)) <= Radius then
			Members[#Members + 1] = { Passport = OtherPassport, Source = OtherSource }

			if Max and #Members >= Max then
				break
			end
		end
	end

	return Members,#Members
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOESEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
exports("DoesExist",function(Passport,Players)
	local Selected = Config.Users[Passport]
	if not Selected then
		return false
	end

	if not Players then
		return Selected
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Members = exports.party:Room(Passport,source,DefaultDistance)

	return (#Members >= Players) and Members or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	local Selected = Config.Users[Passport]
	local Room = GetRoom(Selected)

	if not Room then
		return
	end

	RemoveUserFromRoom(Room,Passport,source)

	if CountUsers(Room.Users) <= 0 then
		Config.Room[Selected] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCOLORFROMPASSPORT
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetColorFromPassport(Passport)
	local Index = (Passport % #ColorList) + 1
	return ColorList[Index]
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTMARKERTIME
-----------------------------------------------------------------------------------------------------------------------------------------
local function StartMarkerTimer(Passport,Party)
	SetTimeout(SecondsMarkers * 1000,function()
		local Marker = Markers[Passport]
		if Marker and Marker.Party == Party and Marker.Timer <= os.time() then
			local Room = GetRoom(Party)
			if Room then
				NotifyRoom(Room,"party:MarkerDelete",Passport)
			else
				Markers[Passport] = nil
			end
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARTY:MARKERADD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("party:MarkerAdd")
AddEventHandler("party:MarkerAdd",function(Coords)
	local source = source
	local Passport = GetPassport(source)
	if not Passport then
		return false
	end

	local CurrentTimer = os.time()
	local Selected = Markers[Passport]
	if Selected then
		local OldRoom = GetRoom(Selected.Party)
		if OldRoom then
			NotifyRoom(OldRoom,"party:MarkerDelete",Passport)
		else
			Markers[Passport] = nil
		end

		return true
	end

	local Party = exports.party:DoesExist(Passport)
	if not Party then
		return false
	end

	local Room = GetRoom(Party)
	if not Room then
		return false
	end

	Markers[Passport] = {
		Party = Party,
		Coords = Coords,
		Timer = CurrentTimer + SecondsMarkers,
		Color = GetColorFromPassport(Passport)
	}

	NotifyRoom(Room,"party:MarkerAdd",Passport,Markers[Passport])
	StartMarkerTimer(Passport,Party)

	return true
end)