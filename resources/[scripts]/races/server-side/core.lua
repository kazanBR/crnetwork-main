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
Tunnel.bindInterface("races",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Players = {}
local Freezing = {}
local Cooldowns = {}
local Participants = {}
local Valuations = {}
local Finished = {}
local Market = {}
local ArrivalOrder = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINIT
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Selected in pairs(Routes) do
		Players[Selected] = {}
		Freezing[Selected] = {}
		Valuations[Selected] = 0
		Participants[Selected] = 0
		ArrivalOrder[Selected] = 0
		Cooldowns[Selected] = os.time()
		GlobalState["Races:"..Selected] = false
	end

	for Index,v in pairs(exports.vrp:VehicleList()) do
		if v.Class == "Races" then
			Market[Index] = {
				Price = v.Gemstone,
				Stock = (v.Stock or 0) - vRP.Scalar("vehicles/Count",{ Vehicle = Index })
			}
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKET
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Market()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Consult = vRP.InventoryItemAmount(Passport,ExchangeItem) or 0

	return { Platinums = Consult[1] or 0, Vehicles = Market }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RENTALVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RentalVehicle(Model)
	local source = source
	local Passport = vRP.Passport(source)
	if not (Passport and Market[Model]) then
		return false
	end

	if Market[Model].Stock <= 0 then
		TriggerClientEvent("races:Notify",source,"Aviso","Estoque insuficiente.","amarelo")
		return false
	end

	if vRP.SelectVehicle(Passport,Model) then
		TriggerClientEvent("races:Notify",source,"Aviso","Já possui um <b>"..exports.vrp:VehicleName(Model).."</b>.","amarelo")
		return false
	end

	if vRP.TakeItem(Passport,ExchangeItem,Market[Model].Price) then
		exports.oxmysql:insert_async("INSERT INTO vehicles (Passport,Vehicle,Plate,Weight,Tax,Work,Block) VALUES (@Passport,@Vehicle,@Plate,@Weight,@Tax,@Work,@Block)",{ Passport = Passport, Vehicle = Model, Plate = vRP.GeneratePlate(), Weight = exports.vrp:VehicleWeight(Model), Tax = os.time() + VehicleDuration, Block = 1, Work = (exports.vrp:VehicleMode(Model) == "Work") })
		exports.discord:Embed("Races","**[PASSAPORTE]:** "..Passport.."\n**[MODELO]:** "..Model.."\n**[PLATINAS]:** "..Dotted(Market[Model].Price))
		TriggerClientEvent("races:Notify",source,"Sucesso","Aluguel do veículo <b>"..exports.vrp:VehicleName(Model).."</b> concluído.","verde")
		Market[Model].Stock = Market[Model].Stock - 1

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Finish(Selected,Points,Vehicle)
	local source = source
	if not Selected or not Routes[Selected] then
		return false
	end

	if type(Points) ~= "number" or Points <= 0 then
		return false
	end

	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if not Active[Passport] or Active[Passport].Selected ~= Selected then
		return false
	end

	Finished[Selected] = Finished[Selected] or {}
	if Finished[Selected][Passport] then
		return false
	end

	Finished[Selected][Passport] = true
	ArrivalOrder[Selected] = (ArrivalOrder[Selected] or 0) + 1

	local Reward = 0
	local GainExperience = 8
	local RealPosition = ArrivalOrder[Selected]
	local PlayersSelected = Players[Selected] or {}
	local TotalPlayers = Participants[Selected] or 0
	if TotalPlayers <= 0 then
		TotalPlayers = 1
	end

	if Vehicle then
		local RouteValuation = Valuations[Selected] or 0
		local _,Level = vRP.GetExperience(Passport,"Race")
		local Valuation = RouteValuation * (1 + (0.025 * Level))

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation * 1.1
		end

		for Permission,Bonus in pairs({ Ouro = 0.10, Prata = 0.075, Bronze = 0.05 }) do
			if vRP.HasService(Passport,Permission) then
				Valuation = Valuation * (1 + Bonus)
				GainExperience = GainExperience + 2
			end
		end

		local WinnerName = vRP.FullName(Passport) or "Corredor"

		local function NotifyAll()
			TriggerClientEvent("Notify",source,"Corridas","Você venceu a corrida!","verde",10000)

			for _,v in pairs(PlayersSelected) do
				if v.Source and v.Source ~= source then
					TriggerClientEvent("Notify",v.Source,"Corridas","<b>"..WinnerName.."</b> venceu a corrida.","verde",10000)
				end
			end
		end

		if TotalPlayers <= 1 then
			Reward = Valuation * (Multipliers.Solo[RealPosition] or 0)
			GainExperience = GainExperience * 0.50
		elseif TotalPlayers == 2 then
			Reward = Valuation * (Multipliers.Duo[RealPosition] or 0)
			GainExperience = GainExperience * 0.75

			if RealPosition <= 1 then
				NotifyAll()
			end
		else
			local Multiplier = Multipliers and Multipliers.Full and Multipliers.Full[RealPosition]
			if Multiplier then
				Reward = Valuation * Multiplier
			else
				Reward = Valuation * 0.1
			end

			if RealPosition <= 3 then
				vRP.GenerateItem(Passport,"racetrophy"..RealPosition,1,true)
			end

			if RealPosition == 1 then
				NotifyAll()
			end
		end

		vRP.UpgradeStress(Passport,10)
		vRP.BattlepassPoints(Passport,GainExperience)
		vRP.PutExperience(Passport,"Race",GainExperience)
		vRP.GenerateItem(Passport,ExchangeItem,Reward,true)

		Freezing[Selected] = Freezing[Selected] or {}
		Freezing[Selected][Passport] = RealPosition
	end

	if Vehicle then
		exports.oxmysql:execute_async("INSERT INTO races (Name,Race,Passport,Vehicle,Points) VALUES (@Name,@Race,@Passport,@Vehicle,@Points) ON DUPLICATE KEY UPDATE Points = LEAST(Points,VALUES(Points)),Vehicle = VALUES(Vehicle)",{ Name = vRP.FullName(Passport), Race = Selected, Passport = Passport, Vehicle = Vehicle, Points = Points })
	end

	local FinishedCount = CountTable(Finished[Selected] or {})
	if FinishedCount >= TotalPlayers then
		TriggerEvent("races:Clean",source,Passport)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RUNNERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Runners(Selected)
	local Route = Routes[Selected]
	if not Route then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if Active[Passport] then
		TriggerClientEvent("races:Notify",source,"Aviso","Você ainda está participando de uma corrida.","amarelo")
		return false
	end

	local Positions = Route.Positions
	if not Positions then
		return false
	end

	local CurrentRunners = Participants[Selected] or 0
	local MaxRunners = CountTable(Positions)

	return CurrentRunners < MaxRunners
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- START
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Start(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Routes[Selected] then
		return false
	end

	if GlobalState["Races:"..Selected] then
		TriggerClientEvent("Notify",source,"Atenção","Circuito em andamento.","amarelo",5000)
		return false
	end

	local CurrentTimer = os.time()
	local Cooldown = Cooldowns[Selected]
	if Cooldown and Cooldown >= CurrentTimer then
		TriggerClientEvent("Notify",source,"Atenção","Aguarde "..CompleteTimers(Cooldown - CurrentTimer)..".","amarelo",5000)
		return false
	end

	if not vRP.RemoveCharges(Passport,RaceItem) then
		TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>1x "..exports.vrp:ItemName(RaceItem).."</b>.","amarelo",5000)
		return false
	end

	Players[Selected] = Players[Selected] or {}
	Finished[Selected] = Finished[Selected] or {}
	Participants[Selected] = (Participants[Selected] or 0) + 1
	Valuations[Selected] = (Valuations[Selected] or 0) + Routes[Selected].Payment
	Active[Passport] = { Selected = Selected }

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CANCEL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Cancel()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	TriggerEvent("races:Clean",source,Passport,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GlobalState(Selected)
	local source = source
	if not Selected or not Routes[Selected] then
		return false
	end

	local Key = "Races:"..Selected
	if GlobalState[Key] then
		return false
	end

	local PlayersSelected = Players[Selected]
	if not PlayersSelected then
		return false
	end

	GlobalState[Key] = true

	exports.vrp:CallPolice({
		Source = source,
		Permission = "Policia",
		Name = "Corrida Clandestina",
		Code = 20,
		Color = 46
	})

	local Markers = {}
	for _,v in pairs(PlayersSelected) do
		TriggerClientEvent("races:Start",v.Source,Selected)
		exports.markers:Enter(v.Source,"Corredor")
		Markers[#Markers + 1] = v.Source
	end

	SetTimeout(DurationMarkers,function()
		for _,OtherSource in pairs(Markers) do
			exports.markers:Exit(OtherSource,"Corredor")
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Ranking(Selected,Results,Back)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Routes[Selected] then
		return {}
	end

	local Ranking = {}
	local Consult = exports.oxmysql:query_async("SELECT MIN(Points) AS Points,Name,Vehicle FROM races WHERE Race = @Race GROUP BY Name ORDER BY Points ASC LIMIT @Count",{ Race = Selected, Count = Results })
	for _,v in ipairs(Consult) do
		table.insert(Ranking,{ Time = v.Points / 1000, Name = v.Name, Vehicle = v.Vehicle })
	end

	if Back then
		return Ranking
	end

	local CurrentPosition = exports.oxmysql:single_async("SELECT Position,Points,Name,Vehicle FROM (SELECT ROW_NUMBER() OVER (ORDER BY Points ASC) AS Position,Points,Name,Vehicle,Passport FROM races WHERE Race = ?) AS ranking WHERE Passport = ? LIMIT 1",{ Selected,Passport })
	if CurrentPosition then
		CurrentPosition = { Position = CurrentPosition.Position, Time = CurrentPosition.Points / 1000, Name = CurrentPosition.Name, Vehicle = CurrentPosition.Vehicle }
	end

	return { Runners = Ranking, Current = CurrentPosition }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKINGGLOBAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RankingGlobal()
	local Consult = exports.oxmysql:query_async("SELECT Race,Name,Passport,Points FROM (SELECT Race,Name,Passport,Points,ROW_NUMBER() OVER (PARTITION BY Race ORDER BY Points ASC) AS rn FROM races) x WHERE rn <= 50 ORDER BY Race,Points ASC")
	if not Consult or #Consult <= 0 then
		return {}
	end

	local Ranking = {}
	for Number = 1,#Consult do
		local v = Consult[Number]
		local Key = tostring(v.Race or "default")
		local List = Ranking[Key] or {}

		Ranking[Key] = List

		List[#List + 1] = {
			Name = v.Name,
			Points = v.Points,
			Passport = v.Passport
		}
	end

	return Ranking
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPOSITION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdatePosition(Selected,Checkpoint,Distance)
	if not Selected or not Routes[Selected] then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or type(Distance) ~= "number" or type(Checkpoint) ~= "number" then
		return false
	end

	Freezing[Selected] = Freezing[Selected] or {}
	Players[Selected] = Players[Selected] or {}

	local ListPlayers = Players[Selected]
	local PlayerData = ListPlayers[Passport]
	if PlayerData then
		if PlayerData.Checkpoint ~= Checkpoint or math.abs((PlayerData.Distance or 0) - Distance) > 5.0 then
			PlayerData.Distance = Distance
			PlayerData.Checkpoint = Checkpoint
		end
	else
		ListPlayers[Passport] = {
			Source = source,
			Distance = Distance,
			Checkpoint = Checkpoint,
			Name = vRP.FullName(Passport)
		}
	end

	local Positions = {}
	local ListFreez = Freezing[Selected]
	for OtherPassport,Data in pairs(ListPlayers) do
		Positions[#Positions + 1] = {
			Name = Data.Name,
			Distance = Data.Distance,
			Passport = OtherPassport,
			Checkpoint = Data.Checkpoint,
			Freezing = ListFreez[OtherPassport]
		}
	end

	table.sort(Positions,function(a,b)
		if a.Freezing and b.Freezing then
			return a.Freezing < b.Freezing
		elseif a.Freezing then
			return true
		elseif b.Freezing then
			return false
		end

		if a.Checkpoint == b.Checkpoint then
			return a.Distance < b.Distance
		end

		return a.Checkpoint > b.Checkpoint
	end)

	local CurrentPosition = 1
	for Number = 1,CountTable(Positions) do
		if Positions[Number].Passport == Passport then
			CurrentPosition = Number
			break
		end
	end

	TriggerClientEvent("races:Update",source,CurrentPosition,Positions)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Information()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	return { Levels = TableLevel(), Xp = vRP.GetExperience(Passport,"Race") }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:CLEAN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("races:Clean",function(source,Passport,Force)
	if not Passport then
		return false
	end

	local ActiveData = Active[Passport]
	if not ActiveData then
		return false
	end

	local Selected = ActiveData.Selected
	if not Selected then
		return false
	end

	if not Force then
		local Total = Participants[Selected] or 0
		local FinishedCount = CountTable(Finished[Selected] or {})
		if FinishedCount < Total then
			return false
		end
	end

	local ListPlayers = Players[Selected]
	if ListPlayers then
		for OtherPassport in pairs(ListPlayers) do
			Active[OtherPassport] = nil
		end
	end

	Players[Selected] = {}
	Freezing[Selected] = {}
	Finished[Selected] = {}

	local Key = "Races:"..Selected
	if GlobalState[Key] then
		GlobalState[Key] = false
	end

	Cooldowns[Selected] = os.time() + CooldownRaces
	Participants[Selected] = 0
	ArrivalOrder[Selected] = 0
	Valuations[Selected] = 0
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:ITEM
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("races:Item",function(source,Passport)
	TriggerEvent("races:Clean",source,Passport,true)
	TriggerClientEvent("races:Item",source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	TriggerEvent("races:Clean",source,Passport,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERDROPPED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerDropped",function()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	TriggerEvent("races:Clean",source,Passport,true)
end)