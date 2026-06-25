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
Tunnel.bindInterface("towed",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Impound = {}
local Services = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
local Drops = {
	{ Item = "plastic", Chance = 75, Min = 25, Max = 45, Addition = 0.050 },
	{ Item = "glass", Chance = 75, Min = 25, Max = 45, Addition = 0.050 },
	{ Item = "rubber", Chance = 75, Min = 25, Max = 45, Addition = 0.050 },
	{ Item = "aluminum", Chance = 25, Min = 15, Max = 25, Addition = 0.025 },
	{ Item = "copper", Chance = 25, Min = 15, Max = 25, Addition = 0.025 }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- BONUS
-----------------------------------------------------------------------------------------------------------------------------------------
local Bonus = {
	Ouro = {
		Stress = 3,
		Experience = 3,
		Multiplier = 0.1,
		Battlepass = 3
	},
	Prata = {
		Stress = 2,
		Experience = 2,
		Multiplier = 0.075,
		Battlepass = 2
	},
	Bronze = {
		Stress = 1,
		Experience = 1,
		Multiplier = 0.05,
		Battlepass = 1
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Service()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if not Services[Passport] then
		Services[Passport] = source
	else
		Services[Passport] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Vehicle(Model,Locale,Destiny)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Coords = Locations[Locale] and Locations[Locale][Destiny]
	if not Coords then
		return false
	end

	local Timeout = os.time() + 10
	local Vehicle = CreateVehicle(Model,Coords,true,false)

	while not DoesEntityExist(Vehicle) do
		if os.time() >= Timeout then
			return false
		end

		Wait(100)
	end

	local Network = NetworkGetNetworkIdFromEntity(Vehicle)
	if not Network or Network == 0 then
		return false
	end

	local Plate = vRP.GeneratePlate()

	SetEntityRoutingBucket(Vehicle,0)
	SetVehicleBodyHealth(Vehicle,10.0)
	SetVehicleNumberPlateText(Vehicle,Plate)

	Entity(Vehicle).state:set("Fuel",0,true)

	Impound[Plate] = {
		Source = source,
		Network = Network
	}

	return Network,Plate
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Delete")
AddEventHandler("garages:Delete",function(Network,Plate)
	local Data = Impound[Plate]
	if not Data then
		return false
	end

	if Data.Source then
		TriggerClientEvent("towed:Inative",Data.Source,Plate)
	end

	Impound[Plate] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("towed:Payment")
AddEventHandler("towed:Payment",function(Plate)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Data = Impound[Plate]
	if not Data or not Data.Network then
		return false
	end

	Active[Passport] = true

	local Success,Error = pcall(function()
		local Result = RandPercentage(Drops)
		if not Result then
			return false
		end

		local Stress = 10
		local Battlepass = 2
		local GainExperience = 2
		local _,Level = vRP.GetExperience(Passport,"Towed")
		local Valuation = Result.Valuation * (1 + (Result.Addition * Level))

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation * 1.1
		end

		for Permission,v in pairs(Bonus) do
			if vRP.HasService(Passport,Permission) then
				Stress = Stress - v.Stress
				Battlepass = Battlepass + v.Battlepass
				Valuation = Valuation * (1 + v.Multiplier)
				GainExperience = GainExperience + v.Experience
			end
		end

		vRP.GenerateItem(Passport,Result.Item,Valuation,true)
		vRP.PutExperience(Passport,"Towed",GainExperience)
		vRP.BattlepassPoints(Passport,Battlepass)
		vRP.UpgradeStress(Passport,Stress)

		TriggerEvent("garages:Delete",Data.Network,Plate)
	end)

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:IMPOUND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("towed:Impound")
AddEventHandler("towed:Impound",function(Data)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasService(Passport,"Policia") then
		return false
	end

	if type(Data) ~= "table" then
		return false
	end

	local Plate = Data[1]
	local Models = Data[2]
	local Network = Data[4]
	if not Plate or not Models or not Network or Impound[Plate] then
		return false
	end

	Impound[Plate] = {
		Network = Network
	}

	TriggerClientEvent("Notify",source,"Departamento Policial","Registro encaminhado aos trabalhadores.","policia",5000)

	local Coords = vRP.GetEntityCoords(source)
	local VehicleLabel = (exports.vrp:VehicleName(Models) or "Veículo").." - "..Plate
	for Passports,Sources in pairs(Services) do
		if Sources then
			async(function()
				vRPC.PlaySound(Sources,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")
				TriggerClientEvent("NotifyPush",Sources,{ code = 20, title = "Impound Solicitado", x = Coords.x, y = Coords.y, z = Coords.z, vehicle = VehicleLabel, color = 44 })
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if Active[Passport] then
		Active[Passport] = nil
	end

	if Services[Passport] then
		Services[Passport] = nil
	end
end)