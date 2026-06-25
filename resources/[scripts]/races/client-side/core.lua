-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("races",Creative)
vSERVER = Tunnel.getInterface("races")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Object = {}
local Position = 0
local Markers = {}
local Checkpoint = 1
local Selected = false
local Progressing = false
local CircuitThread = false
local DisplayRanking = false
local Seconds = GetGameTimer()
local InitSeconds = GetGameTimer()
local PositionCooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISRACEVALID
-----------------------------------------------------------------------------------------------------------------------------------------
function IsRaceValid()
	return LocalPlayer.state.Races and Selected and Routes and Routes[Selected]
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADRACES
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	LoadModel(PropTyre)
	LoadModel(PropFlags)
	SetGhostedEntityAlpha(254)

	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)
		local Vehicle = GetVehiclePedIsUsing(Ped)
		if LocalPlayer.state.Races and LocalPlayer.state.Route == 0 and Selected then
			TimeDistance = 0

			local RouteData = Routes[Selected]
			if GlobalState["Races:"..Selected] and RouteData and RouteData.Coords and RouteData.Coords[Checkpoint] then
				Seconds = GetGameTimer() - InitSeconds
				local CheckpointData = RouteData.Coords[Checkpoint]
				local Distance = #(Coords - CheckpointData.Center)

				DrawTextRacing(CheckpointData.Center.x,CheckpointData.Center.y,CheckpointData.Center.z,Distance - CheckpointData.Distance)

				if Distance <= (CheckpointData.Distance + 1.0) then
					if Checkpoint >= #RouteData.Coords then
						FinishRace(Vehicle)
					else
						NextCheckpoint(Distance)
					end
				end
			else
				if Selected and RouteData and #(Coords - RouteData.Init) > 100 then
					StopCircuit()
				elseif IsControlJustPressed(1,38) then
					vSERVER.GlobalState(Selected)
				end
			end
		elseif IsEligibleToStart(Ped,Vehicle) then
			local RouteData = Routes[Selected]
			if RouteData then
				local InitCoords = RouteData.Init
				local Distance = #(Coords - InitCoords.xyz)

				if Distance <= 25 then
					DrawMarker(23,InitCoords.x,InitCoords.y,InitCoords.z - 0.35,0,0,0,0,0,0,10.0,10.0,10.0,88,101,242,175,false,false,0,false)
					TimeDistance = 0

					if Distance <= 5 and IsControlJustPressed(1,38) and vSERVER.Runners(Selected) then
						if StartRace(Vehicle) then
							InitCircuit()
						end
					end
				end
			end
		end

		Wait(TimeDistance > 0 and TimeDistance or 1)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISHRACE
-----------------------------------------------------------------------------------------------------------------------------------------
function FinishRace(Vehicle)
	DisplayRanking = true
	PlaySoundFrontend(-1,"RACE_PLACED","HUD_AWARDS",true)

	SetLocalPlayerAsGhost(false)
	if Vehicle and DoesEntityExist(Vehicle) then
		SetNetworkVehicleAsGhost(Vehicle,false)
		Vehicle = GetEntityArchetypeName(Vehicle)
	end

	vSERVER.Finish(Selected,Seconds,Vehicle)

	SendNUIMessage({
		Action = "Results",
		Payload = vSERVER.Ranking(Selected,ResultFinish,true)
	})

	SetTimeout(ResultFinish * 1000,function()
		SendNUIMessage({ Action = "Close" })
		DisplayRanking = false
	end)

	StopCircuit(true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NEXTCHECKPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
function NextCheckpoint(Distance)
	if DoesBlipExist(Markers[Checkpoint]) then
		RemoveBlip(Markers[Checkpoint])
		Markers[Checkpoint] = nil
	end

	Checkpoint = Checkpoint + 1
	vSERVER.UpdatePosition(Selected,Checkpoint,Distance)
	PlaySoundFrontend(-1,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET",true)

	if Markers[Checkpoint] then
		SetBlipRoute(Markers[Checkpoint],true)
	end

	CreatedTyres()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISELIGIBLETOSTART
-----------------------------------------------------------------------------------------------------------------------------------------
function IsEligibleToStart(Ped,Vehicle)
	return IsPedInAnyVehicle(Ped) and not IsPedInAnyHeli(Ped) and not IsPedInAnyBoat(Ped) and not IsPedInAnyPlane(Ped) and GetPedInVehicleSeat(Vehicle,-1) == Ped and Selected and Routes[Selected]
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTRACE
-----------------------------------------------------------------------------------------------------------------------------------------
function StartRace(Vehicle)
	if Progressing or not vSERVER.Start(Selected) then
		return false
	end

	if not Vehicle or not DoesEntityExist(Vehicle) or not IsVehicleDriveable(Vehicle,false) then
		return false
	end

	TriggerEvent("hoverfy:Show",{ Key = "E", Title = "Pressione", Legend = "para iniciar a corrida" })

	Checkpoint = 1
	SetLocalPlayerAsGhost(true)
	InitSeconds = GetGameTimer()
	SetNetworkVehicleAsGhost(Vehicle,true)
	LocalPlayer.state:set("Races",true,false)
	CreatedTyres()

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INITCIRCUIT
-----------------------------------------------------------------------------------------------------------------------------------------
function InitCircuit()
	if CircuitThread then
		return false
	end

	local RouteData = Routes[Selected]
	if not RouteData or not RouteData.Coords then
		return false
	end

	local CoordsList = RouteData.Coords
	local TotalCoords = #CoordsList
	local Lasted = TotalCoords - 1

	for Index = 1,TotalCoords do
		local v = CoordsList[Index]
		local IsCheckpoint = Index <= Lasted

		local Blip = AddBlipForCoord(v.Center)
		SetBlipSprite(Blip,IsCheckpoint and 1 or 38)
		SetBlipScale(Blip,IsCheckpoint and 0.85 or 0.75)
		SetBlipColour(Blip,ColourMarker)
		SetBlipAsShortRange(Blip,true)

		if IsCheckpoint then
			ShowNumberOnBlip(Blip,Index)
		end

		Markers[Index] = Blip
	end

	CircuitThread = true
	CreateThread(function()
		while CircuitThread do
			if not IsRaceValid() then
				break
			end

			local Ped = PlayerPedId()
			local Vehicle = GetVehiclePedIsUsing(Ped)
			if not Vehicle or not DoesEntityExist(Vehicle) then
				break
			end

			if GetPedInVehicleSeat(Vehicle,-1) ~= Ped then
				break
			end

			local CheckpointData = CoordsList[Checkpoint]
			if not CheckpointData then
				break
			end

			local Coords = GetEntityCoords(Ped)
			local CurrentTimer = GetGameTimer()
			local Distance = #(Coords - CheckpointData.Center)
			if CurrentTimer >= PositionCooldown then
				PositionCooldown = CurrentTimer + 1000
				vSERVER.UpdatePosition(Selected,Checkpoint,Distance)
			end

			Wait(250)
		end

		CircuitThread = false
		StopCircuit()
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWTEXTRACING
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawTextRacing(x,y,z,Text)
	SetDrawOrigin(x,y,z + 5)
	DrawSprite("Textures","Races",0.0,0.0,0.022,0.034 * GetAspectRatio(false),0.0,214,150,0,255)

	SetTextFont(4)
	SetTextOutline()
	SetTextCentre(true)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,255)

	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(string.format("%.1f m",Text))
	EndTextCommandDisplayText(0.0,0.0)

	ClearDrawOrigin()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEDTYRES
-----------------------------------------------------------------------------------------------------------------------------------------
function CreatedTyres()
	CleanObjects()

	local Route = Routes[Selected]
	if not Route or not Route.Coords then
		return false
	end

	local Coords = Route.Coords[Checkpoint]
	if not Coords then
		return false
	end

	local Prop = Checkpoint >= #Route.Coords and PropFlags or PropTyre

	Object.Left = CreateObjectNoOffset(Prop,Coords.Left.x,Coords.Left.y,Coords.Left.z,false,false,false)
	Object.Right = CreateObjectNoOffset(Prop,Coords.Right.x,Coords.Right.y,Coords.Right.z,false,false,false)

	for _,v in pairs(Object) do
		SetEntityLodDist(v,0xFFFF)
		PlaceObjectOnGroundProperly(v)
		SetEntityCollision(v,false,false)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANMARKER
-----------------------------------------------------------------------------------------------------------------------------------------
function CleanMarker()
	for _,v in pairs(Markers) do
		if DoesBlipExist(v) then
			RemoveBlip(v)
		end
	end

	Markers = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
function CleanObjects()
	for _,v in pairs(Object) do
		if DoesEntityExist(v) then
			DeleteEntity(v)
		end
	end

	Object = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOPCIRCUIT
-----------------------------------------------------------------------------------------------------------------------------------------
function StopCircuit(Finish)
	local Ped = PlayerPedId()
	local Vehicle = GetVehiclePedIsUsing(Ped)
	if Vehicle and DoesEntityExist(Vehicle) then
		SetNetworkVehicleAsGhost(Vehicle,false)
	end

	if not Finish and Progressing and LocalPlayer.state.Races and not DisplayRanking then
		vSERVER.Cancel()
	end

	if not DisplayRanking then
		SendNUIMessage({ Action = "Close" })
	end

	LocalPlayer.state:set("Races",false,false)
	TriggerEvent("hoverfy:Hide")
	CleanObjects()
	CleanMarker()

	Object = {}
	Markers = {}
	Position = 0
	Checkpoint = 1
	InitSeconds = 0
	Selected = false
	Progressing = false
	CircuitThread = false

	SetLocalPlayerAsGhost(false)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("races:Update")
AddEventHandler("races:Update",function(PositionActual,Runners)
	if not Runners or not Selected then
		return
	end

	local Route = Routes[Selected]
	if not Route then
		return
	end

	Position = PositionActual

	local Coords = Route.Coords
	local Timer = (Progressing and Seconds and (Seconds / 1000)) or 0

	SendNUIMessage({
		Action = "Racing",
		Payload = {
			Runners = Runners,
			Position = PositionActual,
			Stats = {
				Time = Timer,
				Checkpoint = {
					Current = Checkpoint or 0,
					Total = Coords and #Coords or 0
				}
			}
		}
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:START
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("races:Start")
AddEventHandler("races:Start",function(Selectedz)
	if Selected ~= Selectedz then
		return false
	end

	local Ped = PlayerPedId()
	if not IsPedInAnyVehicle(Ped) then
		StopCircuit()
		return false
	end

	local RouteData = Routes[Selected]
	if not RouteData or not RouteData.Positions then
		return false
	end

	local Vehicle = GetVehiclePedIsUsing(Ped)
	local StartPosition = RouteData.Positions[Position]
	if not StartPosition then
		StopCircuit()
		return false
	end

	SendNUIMessage({ Action = "StartCountdown", Payload = SecondsInit })
	SetEntityCoordsNoOffset(Vehicle,StartPosition.xyz)
	SetEntityHeading(Vehicle,StartPosition.w)
	SetVehicleOnGroundProperly(Vehicle)
	FreezeEntityPosition(Vehicle,true)
	TriggerEvent("hoverfy:Hide")

	SetTimeout((SecondsInit + 1) * 1000,function()
		Progressing = true
		Seconds = GetGameTimer()
		InitSeconds = GetGameTimer()
		PositionCooldown = GetGameTimer()
		FreezeEntityPosition(Vehicle,false)
		SendNUIMessage({ Action = "StopCountdown" })
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("races:Open")
AddEventHandler("races:Open",function()
	if LocalPlayer.state.Races then
		return false
	end

	SetNuiFocus(true,true)
	TransitionToBlurred(1000)
	TriggerEvent("hud:Active",false)
	SendNUIMessage({
		Action = "Open",
		Payload = {
			Player = {
				Name = LocalPlayer.state.Name,
				Passport = LocalPlayer.state.Passport
			},
			Routes = Routes,
			Experience = vSERVER.Information(),
			MaxRanking = RankingTablet
		}
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	SetNuiFocus(false,false)
	TransitionFromBlurred(1000)
	TriggerEvent("hud:Active",true)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RUN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Run",function(Data,Callback)
	Selected = Data.Route

	local RouteData = Routes[Selected]
	if RouteData and RouteData.Init then
		SetNewWaypoint(RouteData.Init.x,RouteData.Init.y)
	end

	SetNuiFocus(false,false)
	TransitionFromBlurred(1000)
	TriggerEvent("hud:Active",true)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Ranking",function(Data,Callback)
	Callback(vSERVER.Ranking(Data.Route,RankingTablet))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKINGGLOBAL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("RankingGlobal",function(Data,Callback)
	Callback(vSERVER.RankingGlobal())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Market",function(Data,Callback)
	Callback(vSERVER.Market())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RENTALVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("RentalVehicle",function(Data,Callback)
	Callback(vSERVER.RentalVehicle(Data.Model))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("races:Notify")
AddEventHandler("races:Notify",function(Title,Message,Type)
	SendNUIMessage({
		Action = "Notify",
		Payload = {
			Title = Title,
			Message = Message,
			Type = Type
		}
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACES:ITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("races:Item")
AddEventHandler("races:Item",function()
	if not Selected then
		return false
	end

	StopCircuit()
end)