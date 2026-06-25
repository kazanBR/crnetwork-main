-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
tvRP = {}
Proxy.addInterface("vRP",tvRP)
Tunnel.bindInterface("vRP",tvRP)
vRPS = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local BlipAdmin = false
local Information = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- DECORS
-----------------------------------------------------------------------------------------------------------------------------------------
DecorRegister("CREATIVE_PED",2)
DecorRegister("CREATIVE_CODE",2)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RELATIONSHIP
-----------------------------------------------------------------------------------------------------------------------------------------
AddRelationshipGroup("PLAYER")
AddRelationshipGroup("SURVIVAL")
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADRELATIONSHIP
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local PlayerHash = GetHashKey("PLAYER")
	local SurvivalHash = GetHashKey("SURVIVAL")

	SetRelationshipBetweenGroups(5,SurvivalHash,PlayerHash)
	SetRelationshipBetweenGroups(5,PlayerHash,SurvivalHash)
	SetRelationshipBetweenGroups(0,SurvivalHash,SurvivalHash)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THEME
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Theme",function(Data,Callback)
	Callback(Theme)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSESTPEDS
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.ClosestPeds(Radius)
	local Selected = {}
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)
	local GamePool = GetGamePool("CPed")
	local Radius = (Radius or 2.0) + 0.0001

	for _,Entitys in pairs(GamePool) do
		local Index = NetworkGetPlayerIndexFromPed(Entitys)
		if Ped ~= Entitys and Index and NetworkIsPlayerConnected(Index) and #(Coords - GetEntityCoords(Entitys)) <= Radius then
			Selected[#Selected + 1] = GetPlayerServerId(Index)
		end
	end

	return Selected
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSESTPED
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.ClosestPed(Radius)
	local Selected = false
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)
	local GamePool = GetGamePool("CPed")
	local Radius = (Radius or 2.0) + 0.0001

	for _,Entitys in pairs(GamePool) do
		local Index = NetworkGetPlayerIndexFromPed(Entitys)
		if IsPedAPlayer(Entitys) and Index and Ped ~= Entitys and NetworkIsPlayerConnected(Index) then
			local OtherCoords = GetEntityCoords(Entitys)
			local OtherDistance = #(Coords - OtherCoords)
			if OtherDistance <= Radius then
				Selected = GetPlayerServerId(Index)
				Radius = OtherDistance
			end
		end
	end

	return Selected
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
function GetPlayers()
	local Voip = {}
	local Selected = {}
	local GamePool = GetGamePool("CPed")

	for _,Entitys in pairs(GamePool) do
		local Index = NetworkGetPlayerIndexFromPed(Entitys)

		if Index and IsPedAPlayer(Entitys) and NetworkIsPlayerConnected(Index) then
			Selected[Entitys] = GetPlayerServerId(Index)
			Voip[Entitys] = Index
		end
	end

	return Selected,Voip
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.Players()
	return GetPlayers()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLIPADMIN
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.BlipAdmin()
	BlipAdmin = not BlipAdmin
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYSOUND
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.PlaySound(Dict,Name)
	PlaySoundFrontend(-1,Dict,Name,false)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORTENALBLE
-----------------------------------------------------------------------------------------------------------------------------------------
function PassportEnable()
	if Information or IsPauseMenuActive() then
		return false
	end

	Information = true

	CreateThread(function()
		while Information do
			local Ped = PlayerPedId()
			local Players = GetPlayers()
			local Coords = GetEntityCoords(Ped)

			for Entitys,source in pairs(Players) do
				if Ped ~= Entitys and DoesEntityExist(Entitys) and HasEntityClearLosToEntity(Ped,Entitys,17) and IsEntityVisible(Entitys) then
					local Passport = Player(source).state.Passport
					if Passport then
						local OtherCoords = GetEntityCoords(Entitys)
						if #(Coords - OtherCoords) <= 10.0 then
							local Head = GetPedBoneIndex(Entitys,0x796e)
							local HeadCoords = GetWorldPositionOfEntityBone(Entitys,Head)

							DrawText(HeadCoords,Passport)
						end
					end
				end
			end

			Wait(0)
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORTDISABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function PassportDisable()
	Information = false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REGISTERCOMMAND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("+Information",PassportEnable)
RegisterCommand("-Information",PassportDisable)
RegisterKeyMapping("+Information","Visualizar passaporte.","keyboard","F7")
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Dictionaries = CreateRuntimeTxd("Textures")
	for _,v in pairs(TexturePack) do
		local Loaded = LoadResourceFile("vrp","config/textures/"..v.Image..".png")
		if Loaded then
			local TextureBase = "data:image/png;base64,"..Base64(Loaded)
			local RuntimeTexture = CreateRuntimeTexture(Dictionaries,v.Image,v.Width,v.Height)
			SetRuntimeTextureImage(RuntimeTexture,TextureBase)
		end
	end

	while true do
		local TimeDistance = 999
		if LocalPlayer.state.Active and BlipAdmin then
			local Ped = PlayerPedId()
			local Players,Voip = GetPlayers()

			for Entitys,source in pairs(Players) do
				if Ped ~= Entitys then
					local PlayerState = Player(source).state
					local Passport = PlayerState and PlayerState.Passport

					if Passport then
						TimeDistance = 0

						local Armour = GetPedArmour(Entitys)
						local Health = GetEntityHealth(Entitys)
						local Head = GetPedBoneIndex(Entitys,0x796e)
						local ArmourPercent = math.min(Armour / 100,1.0)
						local Name = PlayerState.Name or "Carregando..."
						local Talking = MumbleIsPlayerTalking(Voip[Entitys])
						local HealthPercent = math.max((Health - 100) / 100,0.0)
						local HeadCoords = GetWorldPositionOfEntityBone(Entitys,Head)
						local Message = ("%s%s ~y~%s"):format(Talking and "~q~" or "",Name,Passport)

						DrawText(HeadCoords,Message,HealthPercent,ArmourPercent)
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWTEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawText(Coords,Message,Health,Armour)
	local Width = 0.05
	local Height = 0.005
	local Screen,X,Y = World3dToScreen2d(Coords.x,Coords.y,Coords.z + 0.325)

	if Screen then
		SetTextFont(4)
		SetTextOutline()
		SetTextCentre(true)
		SetTextScale(0.35,0.35)
		SetTextColour(255,255,255,255)

		BeginTextCommandDisplayText("STRING")
		AddTextComponentSubstringPlayerName(Message)
		EndTextCommandDisplayText(X,Y - 0.035)

		if Health then
			DrawRect(X,Y,Width,Height,25,25,25,125)
			DrawRect(X - (Width - Width * Health) / 2,Y,Width * Health,Height,122,215,94,200)
		end

		if Armour then
			DrawRect(X,Y - 0.005,Width,Height,25,25,25,125)
			DrawRect(X - (Width - Width * Armour) / 2,Y - 0.005,Width * Armour,Height,66,183,217,200)
		end
	end
end