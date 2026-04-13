-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("markers")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Markers = {}
local Players = {}
local Pause = false
local ParentOfs = {}
local Permissions = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARENTPAIRS
-----------------------------------------------------------------------------------------------------------------------------------------
for Index,List in pairs(ParentGroups) do
	for _,Permission in ipairs(List) do
		ParentOfs[Permission] = Index
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARENTS
-----------------------------------------------------------------------------------------------------------------------------------------
local function CheckParents(Permission)
	local Group = ParentOfs[Permission]
	if not Group then
		return false
	end

	for _,Index in ipairs(ParentGroups[Group]) do
		if Permissions[Index] then
			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEORUPDATEBLIP
-----------------------------------------------------------------------------------------------------------------------------------------
local function CreateOrUpdateBlip(Index,Coords,Permission,Level,Ped)
	if not Groups[Permission] then
		return false
	end

	if not Markers[Index] then
		if Ped and Ped ~= 0 then
			Markers[Index] = AddBlipForEntity(Ped)
		elseif Coords then
			Markers[Index] = AddBlipForCoord(Coords)
		else
			return false
		end
	end

	local Blip = Markers[Index]
	if not DoesBlipExist(Blip) then
		Markers[Index] = nil
		return false
	end

	SetBlipSprite(Blip,1)
	SetBlipDisplay(Blip,4)
	SetBlipAsShortRange(Blip,false)
	SetBlipScale(Blip,0.65)

	local GroupData = Groups[Permission]
	local LevelName = GroupData.Hierarchy and GroupData.Hierarchy[Level] or "Membro"

	SetBlipColour(Blip,GroupData.Markers or 1)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("! "..Permission.." : "..LevelName)
	EndTextCommandSetBlipName(Blip)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEMARKER
-----------------------------------------------------------------------------------------------------------------------------------------
local function RemoveMarker(Index)
	local Blip = Markers[Index]
	if Blip and DoesBlipExist(Blip) then
		RemoveBlip(Blip)
	end

	Markers[Index] = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetPlayers()
	local Selected = {}
	for _,Ped in ipairs(GetGamePool("CPed")) do
		if IsPedAPlayer(Ped) then
			local Index = NetworkGetPlayerIndexFromPed(Ped)
			if Index and NetworkIsPlayerConnected(Index) then
				Selected[GetPlayerServerId(Index)] = Ped
			end
		end
	end

	return Selected
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANMARKERS
-----------------------------------------------------------------------------------------------------------------------------------------
function CleanMarkers()
	for _,Blip in pairs(Markers) do
		if DoesBlipExist(Blip) then
			RemoveBlip(Blip)
		end
	end

	Markers = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOVEBLIPSMOOTH
-----------------------------------------------------------------------------------------------------------------------------------------
function MoveBlipSmooth(Blip,Coords)
	if not DoesBlipExist(Blip) or not Coords then
		return
	end

	local Timer = 0.0
	local Init = GetBlipCoords(Blip)
	local LastUpdate = GetGameTimer()

	while Timer < 1.0 do
		local CurrentTimer = GetGameTimer()
		if CurrentTimer - LastUpdate >= 10 then
			Timer = Timer + 0.02
			LastUpdate = CurrentTimer
			SetBlipCoords(Blip,Init + (Coords - Init) * Timer)
		end

		Wait(1)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADMARKERS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Permission,v in pairs(Groups) do
		if v.Markers then
			AddStateBagChangeHandler(Permission,("player:%s"):format(LocalPlayer.state.Source),function(_,Key,Value)
				if Value then
					Permissions[Permission] = true
				else
					if Permissions[Permission] then
						Permissions[Permission] = nil
						CleanMarkers()
					end
				end
			end)
		end
	end

	while true do
		local TimeDistance = 999
		if LocalPlayer.state.Active and LocalPlayer.state.Markers and next(Permissions) then
			if IsPauseMenuActive() then
				if not Pause then
					Pause = true
					CleanMarkers()
				end

				local Users = vSERVER.Users()
				for Index,v in pairs(Users) do
					if Groups[v.Permission] and Groups[v.Permission].Markers and (Permissions[v.Permission] or CheckParents(v.Permission)) then
						if Markers[Index] then
							async(function()
								MoveBlipSmooth(Markers[Index],v.Coords)
							end)
						else
							CreateOrUpdateBlip(Index,v.Coords,v.Permission,v.Level)
						end
					end
				end
			else
				if Pause then
					Pause = false
					CleanMarkers()
				end

				if IsMinimapRendering() then
					TimeDistance = 100

					local List = GetPlayers()
					for Index,v in pairs(Players) do
						if List[Index] then
							if Groups[v.Permission] and Groups[v.Permission].Markers and not Markers[Index] and (Permissions[v.Permission] or CheckParents(v.Permission)) then
								local TargetPlayer = GetPlayerFromServerId(Index)
								local TargetPed = GetPlayerPed(TargetPlayer)

								CreateOrUpdateBlip(Index,nil,v.Permission,v.Level,TargetPed)
							end
						else
							RemoveMarker(Index)
						end
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS:ADD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("markers:Add")
AddEventHandler("markers:Add",function(Source,Data)
	if Source and Data then
		Players[Source] = Data
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS:FULL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("markers:Full")
AddEventHandler("markers:Full",function(Data)
	Players = Data or {}
	CleanMarkers()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKERS:REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("markers:Remove")
AddEventHandler("markers:Remove",function(Source)
	Players[Source] = nil
	RemoveMarker(Source)
end)