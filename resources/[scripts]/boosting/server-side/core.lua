-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
local Creative = {}
Tunnel.bindInterface("boosting",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Pendings = {}
local Cooldowns = {}
local ActiveMax = {}
local MaxContracts = 0
local TotalContracts = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONTRACTS
-----------------------------------------------------------------------------------------------------------------------------------------
local Contracts = {
	[1] = {
		{
			Vehicle = "gt500",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},
	},
	[2] = {
		{
			Vehicle = "specter",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		}
	},
	[3] = {
		{
			Vehicle = "jackal",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		}
	},
	[4] = {
		{
			Vehicle = "omnis",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		}
	},
	[5] = {
		{
			Vehicle = "gb200",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		}
	},
	[6] = {
		{
			Vehicle = "flashgt",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- MINIMALS
-----------------------------------------------------------------------------------------------------------------------------------------
local Minimals = {
	[1] = {
		Min = 300,
		Max = 900,
		Item = "blue_essence"
	},
	[2] = {
		Min = 600,
		Max = 1200,
		Item = "purple_essence"
	},
	[3] = {
		Min = 900,
		Max = 1500,
		Item = "green_essence"
	},
	[4] = {
		Min = 1200,
		Max = 1800,
		Item = "red_essence"
	},
	[5] = {
		Min = 1500,
		Max = 2100,
		Item = "pink_essence"
	},
	[6] = {
		Min = 1800,
		Max = 2700,
		Item = "pink_essence"
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- LEVELS
-----------------------------------------------------------------------------------------------------------------------------------------
local Levels = { 0,1000,2000,3500,5000,7500 }
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETCOOLDOWN
-----------------------------------------------------------------------------------------------------------------------------------------
function SetCooldown(Passport,Class)
	local Rand = Minimals[Class]
	if Rand then
		Cooldowns[Passport][Class] = os.time() + math.random(Rand.Min,Rand.Max)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ABOUTCLASSES
-----------------------------------------------------------------------------------------------------------------------------------------
function AboutClasses(Experience)
	local Level = 1
	for Number = 1,#Levels do
		if Experience >= Levels[Number] then
			Level = Number
		end
	end

	return Level
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Citizen.Wait(1000)

		local CurrentTimer = os.time()
		for Passport,Pending in pairs(Pendings) do
			local source = vRP.Source(Passport)
			if not source then
				goto Continue
			end

			local Experience = vRP.GetExperience(Passport,"Boosting")
			local Level = AboutClasses(Experience)
			local Class = math.random(Level)

			Cooldowns[Passport] = Cooldowns[Passport] or {}
			Cooldowns[Passport][Class] = Cooldowns[Passport][Class] or 0

			local IsMax = (Class == 6)
			local HasSlot = CountTable(Pending) < 3
			local IsCooldown = CurrentTimer >= Cooldowns[Passport][Class]
			if IsCooldown and HasSlot and (not IsMax or (MaxContracts < 3 and not ActiveMax[Passport])) then
				if IsMax then
					MaxContracts += 1
					ActiveMax[Passport] = true
				end

				TotalContracts += 1

				local ClassContracts = Contracts[Class]
				if ClassContracts and ClassContracts[1] then
					Pending[TotalContracts] = ClassContracts[math.random(#ClassContracts)]
					SetCooldown(Passport,Class)
				end
			end

			::Continue::
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Experience()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	return { vRP.GetExperience(Passport,"Boosting"),Levels }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACTIVES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Actives()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Data = Active[Passport]
	if not Data then
		return false
	end

	local CurrentTimer = os.time()
	if CurrentTimer >= Data.Timer then
		SetCooldown(Passport,Data.Class)
		Active[Passport] = nil

		return false
	end

	return {
		Number = Data.Number,
		Vehicle = exports.vrp:VehicleName(Data.Vehicle),
		Timer = Data.Timer - CurrentTimer,
		Class = Data.Class,
		Value = Data.Value,
		Exp = Data.Exp
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PENDINGS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Pendings()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return {}
	end

	Pendings[Passport] = Pendings[Passport] or {}
	Cooldowns[Passport] = Cooldowns[Passport] or {}

	local CurrentTimer = os.time()
	for Number = 1,6 do
		Cooldowns[Passport][Number] = Cooldowns[Passport][Number] or CurrentTimer
	end

	local Result = {}
	for Number,Data in pairs(Pendings[Passport]) do
		Result[#Result + 1] = {
			Number = Number,
			Vehicle = exports.vrp:VehicleName(Data.Vehicle),
			Timer = Data.Timer,
			Class = Data.Class,
			Value = Data.Value,
			Exp = Data.Exp,
			Scratch = false
		}
	end

	return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCEPT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Accept(Selected)
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Data = Pendings[Passport] and Pendings[Passport][Selected]
	if not Data then
		return false
	end

	if not vRP.TakeItem(Passport,"platinum",Data.Value) then
		return false
	end

	Active[Passport] = {
		Vehicle = Data.Vehicle,
		Class = Data.Class,
		Value = Data.Value,
		Exp = Data.Exp,
		Timer = os.time() + Data.Timer,
		Number = Selected
	}

	Pendings[Passport][Selected] = nil
	TriggerClientEvent("boosting:Active",source,Data.Vehicle,Data.Class)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SCRATCH
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Scratch(Selected)
	local source = source
	return vRP.Passport(source)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Transfer(Selected,OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Selected or not OtherPassport then
		return false
	end

	local Sender = Pendings[Passport]
	local Receiver = Pendings[OtherPassport]
	if not Sender or not Receiver then
		return false
	end

	local Contract = Sender[Selected]
	if not Contract or CountTable(Receiver) >= 3 then
		return false
	end

	TriggerClientEvent("Notify",source,"Sucesso","Transferência concluída.","verde",5000)
	SetCooldown(Passport,Contract.Class)
	Receiver[#Receiver + 1] = Contract
	Sender[Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DECLINE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Decline(Selected)
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Contract = Pendings[Passport] and Pendings[Passport][Selected]
	if not Contract then
		return false
	end

	SetCooldown(Passport,Contract.Class)
	Pendings[Passport][Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Remove",function(Passport,Plate)
	local Data = Active[Passport]
	if not Data or Data.Plate ~= Plate then
		return false
	end

	Cooldowns[Passport] = Cooldowns[Passport] or {}

	local Class = Data.Class
	local Rand = Minimals[Class]

	if Rand then
		Cooldowns[Passport][Class] = os.time() + math.random(Rand.Min,Rand.Max)
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateVehicle(Model,Class,Coords)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Vehicle = CreateVehicle(Model,Coords,true,false)
	while not DoesEntityExist(Vehicle) or NetworkGetNetworkIdFromEntity(Vehicle) == 0 do
		Wait(100)
	end

	local State = Entity(Vehicle).state
	local Plate = exports.inventory:GeneratePlate()
	SetVehicleNumberPlateText(Vehicle,Plate)

	State:set("Nitro",2000,true)
	State:set("Fuel",100.0,true)
	State:set("Tower",true,true)
	State:set("Drift",false,true)
	State:set("Seatbelt",false,true)

	Active[Passport].Plate = Plate

	TriggerEvent("inventory:Boosting",Plate,{ Amount = 0, Source = source, Passport = Passport, Class = Class })
	TriggerClientEvent("NotifyPush",source,{ code = 31, title = "Informações do Veículo", x = Coords.x, y = Coords.y, z = Coords.z, vehicle = exports.vrp:VehicleName(Model).." - "..Plate, color = 44 })

	return NetworkGetNetworkIdFromEntity(Vehicle)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Payment",function(source,Passport)
	local Data = Active[Passport]
	if not Data then
		return false
	end

	local CurrentTimer = os.time()
	if Data.Timer >= CurrentTimer then
		local Class = Data.Class
		local Experience = Data.Exp
		local Valuation = Data.Value * 3
		local Cooldown = math.random(Minimals[Class].Min,Minimals[Class].Max)
		local Consult,Members = exports.party:Room(Passport,source,25,2)
		if Consult and Members >= 2 then
			for Number = 1,Members do
				local Member = Consult[Number]
				if vRP.Passport(Member.Source) then
					local OtherPassport = Member.Passport

					vRP.GenerateItem(OtherPassport,Minimals[Class].Item,1,true)
					vRP.GenerateItem(OtherPassport,"platinum",Valuation,true)
					vRP.PutExperience(OtherPassport,"Boosting",Experience)
					vRP.BattlepassPoints(OtherPassport,Experience)

					Cooldowns[OtherPassport][Class] = CurrentTimer + Cooldown
					Active[OtherPassport] = nil
				end
			end
		else
			vRP.GenerateItem(Passport,Minimals[Class].Item,1,true)
			vRP.GenerateItem(Passport,"platinum",Valuation,true)
			vRP.PutExperience(Passport,"Boosting",Experience)
			vRP.BattlepassPoints(Passport,Experience)

			Cooldowns[Passport][Class] = CurrentTimer + Cooldown
		end
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport)
	Pendings[Passport] = Pendings[Passport] or {}

	if not Cooldowns[Passport] then
		Cooldowns[Passport] = {}
		local CurrentTimer = os.time()

		for Number = 1,6 do
			Cooldowns[Passport][Number] = CurrentTimer
		end
	end
end)