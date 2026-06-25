-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Travel = {}
Boosting = {}
Dismantle = {}
local Dismantled = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEPLATE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("GeneratePlate",function()
	repeat
		Plate = GenerateString("LLDDDLLL")
	until Plate and not Dismantle[Plate] and not Boosting[Plate]

	return Plate
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:BOOSTING
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:Boosting",function(Plate,Status)
	if not Boosting[Plate] then
		Boosting[Plate] = Status
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Delete")
AddEventHandler("garages:Delete",function(Network,Plate)
	if Plate then
		if Dismantle[Plate] then
			local source = vRP.Passport(Dismantle[Plate])
			if source then
				TriggerClientEvent("dismantle:Reset",source)
			end

			Dismantle[Plate] = nil
		end

		if Boosting[Plate] then
			local source = vRP.Passport(Boosting[Plate].Source)
			if source then
				TriggerClientEvent("boosting:Reset",Boosting[Plate].Source)
			end

			exports.boosting:Remove(Boosting[Plate].Passport,Plate)
			Boosting[Plate] = nil
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateVehicle(Model,Coords)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		local CurrentTimer = os.time() + 10
		local Vehicle = CreateVehicle(Model,Coords,true,false)

		while not DoesEntityExist(Vehicle) or NetworkGetNetworkIdFromEntity(Vehicle) == 0 do
			if os.time() >= CurrentTimer then
				return false
			end
	
			Wait(100)
		end

		local Plate = exports.inventory:GeneratePlate()

		SetVehicleNumberPlateText(Vehicle,Plate)
		SetVehicleCustomPrimaryColour(Vehicle,math.random(255),math.random(255),math.random(255))
		SetVehicleCustomSecondaryColour(Vehicle,math.random(255),math.random(255),math.random(255))

		Entity(Vehicle).state:set("Nitro",0,true)
		Entity(Vehicle).state:set("Fuel",100,true)
		Entity(Vehicle).state:set("Tower",true,true)

		Dismantle[Plate] = source

		exports.vrp:CallPolice({
			Source = source,
			Passport = Passport,
			Permission = "Policia",
			Name = "Desmanche de Veículo",
			Vehicle = exports.vrp:VehicleName(Model).." - "..Plate,
			Coords = Coords,
			Code = 31,
			Color = 44
		})

		return NetworkGetNetworkIdFromEntity(Vehicle)
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMANTLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("inventory:Dismantle")
AddEventHandler("inventory:Dismantle",function(Entity)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Plate = Entity[1]
	local Model = Entity[2]
	local Network = Entity[4]
	local UserVehicle = vRP.PassportPlate(Plate)

	if Dismantled[Plate] then
		TriggerClientEvent("Notify",source,"Atenção","Esse veículo já está sendo desmanchado.","amarelo",5000)
		return false
	end

	if not exports.vrp:VehicleExist(Model) or exports.vrp:VehicleMode(Model) == "Work" or (not UserVehicle and not Dismantle[Plate]) then
		TriggerClientEvent("Notify",source,"Atenção","Esse carro não pode ser desmanchado","amarelo",5000)
		return false
	end

	Dismantled[Plate] = Passport
	Active[Passport] = os.time() + 30
	Player(source).state.Buttons = true
	TriggerClientEvent("Progress",source,"Desmanchando",30000)
	vRPC.playAnim(source,false,{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer"},true)

	CreateThread(function()
		while Active[Passport] and os.time() < Active[Passport] do
			Wait(100)
		end

		vRPC.Destroy(source)
		Player(source).state.Buttons = false

		if not Active[Passport] or (Dismantled[Plate] and Dismantled[Plate] ~= Passport) or (not UserVehicle and not Dismantle[Plate]) or (UserVehicle and not exports.garages:Spawn(Plate)) then
			if Dismantled[Plate] and Dismantled[Plate] == Passport then
				Dismantled[Plate] = nil
			end

			Active[Passport] = nil
			return false
		end

		TriggerClientEvent("dismantle:Reset",source)
		TriggerEvent("garages:Deleted",Network,Plate)

		local GainExperience = 3
		local _,Level = vRP.GetExperience(Passport,"Dismantle")
		local Amount = exports.vrp:VehiclePrice(Model) * (UserVehicle and 0.07 or 0.04)
		local Bonus = (Level > 21 and 0.06) or (Level > 10 and 0.03) or 0.02
		local Valuation = Amount + (Amount * (Bonus * Level))

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation * 1.1
		end

		for Permission,Multiplier in pairs({ Ouro = 0.10, Prata = 0.075, Bronze = 0.05 }) do
			if vRP.HasService(Passport,Permission) then
				GainExperience = GainExperience + 1
				Valuation = Valuation * (1 + Multiplier)
			end
		end

		local Members = 1
		if exports.party:DoesExist(Passport,2) then
			Members = Members + 1
		end

		if UserVehicle and vRP.SingleQuery("vehicles/plateVehicles",{ Plate = Plate }) then
			vRP.Update("vehicles/Arrest",{ Plate = Plate })
		end

		vRP.BattlepassPoints(Passport,GainExperience)
		vRP.PutExperience(Passport,"Dismantle",GainExperience)
		vRP.GenerateItem(Passport,"ironfilings",Valuation * Members,true)

		Dismantled[Plate] = nil
		Active[Passport] = nil
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Experience()
	local source = source
	local Passport = vRP.Passport(source)

	return Passport and vRP.GetExperience(Passport,"Dismantle") or 0
end