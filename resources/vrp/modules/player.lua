-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Spawns = {}
local Objects = {}
local Weapons = {}
local Buckets = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("CharacterChosen",function(Passport,source)
	if not Passport or not source then
		return false
	end

	local Identity = vRP.Identity(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not Datatable or not Identity then
		return false
	end

	local Position = Datatable.Pos
	if not Position or not Position.x or not Position.y or not Position.z then
		Position = SpawnCoords[math.random(#SpawnCoords)]
		Datatable.Pos = Position
	end

	Datatable.Armour = Datatable.Armour or 0
	Datatable.Stress = Datatable.Stress or 0
	Datatable.Hunger = Datatable.Hunger or 100
	Datatable.Thirst = Datatable.Thirst or 100
	Datatable.Health = Datatable.Health or 200
	Datatable.Inventory = Datatable.Inventory or {}
	Datatable.Weight = Datatable.Weight or MinimumWeight
	Datatable.Slots = Datatable.Slots or Theme.inventory.slots.default

	vRPC.Skin(source,Identity.Skin)
	vRPC.SetHealth(source,Datatable.Health,Datatable.Health <= 100)

	TriggerClientEvent("barbershop:Apply",source,vRP.UserData(Passport,"Barbershop"))
	TriggerClientEvent("tattooshop:Apply",source,vRP.UserData(Passport,"Tattooshop"))
	TriggerClientEvent("skinshop:Apply",source,vRP.UserData(Passport,"Clothings"))

	if not Datatable.Creation then
		TriggerClientEvent("spawn:Finish",source,false,true)
	else
		vRP.Armour(source,Datatable.Armour)

		TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
		TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
		TriggerClientEvent("hud:Stress",source,Datatable.Stress)

		vRP.Teleport(source,Position.x,Position.y,Position.z - 1)

		TriggerClientEvent("spawn:Finish",source,not Spawns[Passport] and Position or false)
	end

	TriggerClientEvent("vRP:Active",source,Passport,Identity.Name.." "..Identity.Lastname,Datatable.Inventory)
	TriggerEvent("Connect",Passport,source,not Spawns[Passport])
	GlobalState.Players = GetNumPlayerIndices()

	if not Spawns[Passport] then
		Spawns[Passport] = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("DeleteObject")
AddEventHandler("DeleteObject",function(Index,Weapon)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		if Objects[Passport] and Objects[Passport][Index] then
			Objects[Passport][Index] = nil
		end

		if Weapon and Weapons[Passport] and Weapons[Passport][Weapon] then
			Index = Weapons[Passport][Weapon]
			Weapons[Passport][Weapon] = nil
		end
	end

	TriggerEvent("DeleteObjectServer",Index)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEOBJECTSERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("DeleteObjectServer",function(Index)
	local Networked = NetworkGetEntityFromNetworkId(Index)
	if DoesEntityExist(Networked) and not IsPedAPlayer(Networked) and GetEntityType(Networked) == 3 then
		DeleteEntity(Networked)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEPED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("DeletePed")
AddEventHandler("DeletePed",function(Index)
	local Networked = NetworkGetEntityFromNetworkId(Index)
	if DoesEntityExist(Networked) and not IsPedAPlayer(Networked) and GetEntityType(Networked) == 1 then
		DeleteEntity(Networked)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUGOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("DebugObjects",function(Passport)
	if Objects[Passport] then
		for Index,_ in pairs(Objects[Passport]) do
			TriggerEvent("DeleteObjectServer",Index)
		end

		Objects[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUGWEAPONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("DebugWeapons",function(Passport,Ignore,Created)
	if Weapons[Passport] then
		local source = vRP.Source(Passport)
		for Name,Network in pairs(Weapons[Passport]) do
			TriggerEvent("DeleteObjectServer",Network)

			if not Ignore then
				TriggerClientEvent("inventory:RemoveWeapon",source,Name)
			end
		end

		Weapons[Passport] = nil

		if Created then
			TriggerEvent("vRP:ReloadWeapons",source,Passport)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADESLOTS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeSlots(Passport,Amount)
	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Slots = math.min(Theme.inventory.slots.max,(Datatable.Slots or Theme.inventory.slots.default or 0) + Amount)

	return Datatable.Slots
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADEHUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeHunger(Passport,Amount)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Hunger = math.min(100,(Datatable.Hunger or 0) + Amount)

	TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADEHUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DowngradeHunger(Passport,Amount)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Hunger = math.max(0,(Datatable.Hunger or 100) - Amount)

	TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADEHUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.DowngradeHunger()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Hunger = math.max(0,(Datatable.Hunger or 100) - 1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDAGRADETHIRST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeThirst(Passport,Amount)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Thirst = math.min(100,(Datatable.Thirst or 0) + Amount)

	TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADETHIRST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DowngradeThirst(Passport,Amount)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Thirst = math.max(0,(Datatable.Thirst or 100) - Amount)

	TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADETHIRST
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.DowngradeThirst()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Thirst = math.max(0,(Datatable.Thirst or 100) - 1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADESTRESS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeStress(Passport,Amount)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Stress = math.min(100,(Datatable.Stress or 0) + Amount)

	TriggerClientEvent("hud:Stress",source,Datatable.Stress)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADESTRESS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DowngradeStress(Passport,Amount)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Stress = math.max(0,(Datatable.Stress or 0) - Amount)

	TriggerClientEvent("hud:Stress",source,Datatable.Stress)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETHEALTH
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetHealth(source)
	local Ped = GetPlayerPed(source)
	return (Ped and DoesEntityExist(Ped) and Characters[source]) and GetEntityHealth(Ped) or 100
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MODELPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ModelPlayer(source)
	local Ped = GetPlayerPed(source)
	if Ped and DoesEntityExist(Ped) and Characters[source] then
		return (GetEntityModel(Ped) == GetHashKey("mp_f_freemode_01")) and "mp_f_freemode_01" or "mp_m_freemode_01"
	end

	return "mp_m_freemode_01"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETEXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetExperience(Passport,Work)
	local Datatable = vRP.Datatable(Passport)
	if Datatable then
		Datatable[Work] = Datatable[Work] or 0
	end

	return Datatable and Datatable[Work] or 0,ClassCategory(Datatable and Datatable[Work] or 0)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PUTEXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PutExperience(Passport,Work,Amount)
	if not Amount or Amount <= 0 then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable[Work] = Datatable[Work] or 0

	local CurrentExperience = Datatable[Work]
	local NewExperience = math.max(CurrentExperience + Amount,0)
	if UpperLevel[Work] then
		local BeforeLevel = ClassCategory(CurrentExperience)
		local AfterLevel = ClassCategory(NewExperience)

		if AfterLevel > BeforeLevel then
			for Level = BeforeLevel + 1,AfterLevel do
				local Key = tostring(Level)
				if UpperLevel[Work][Key] then
					for _,v in pairs(UpperLevel[Work][Key]) do
						vRP.GenerateItem(Passport,v.Item,math.random(v.Min,v.Max),true)
					end
				end
			end
		end
	end

	Datatable[Work] = NewExperience

	local Source = vRP.Source(Passport)
	if Source then
		TriggerClientEvent("hud:DisplayExperience",Source,"Experience",Amount)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETARMOUR
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetArmour(source,Amount)
	local Character = Characters[source]
	if not source or not Character then return end

	local Ped = GetPlayerPed(source)
	if DoesEntityExist(Ped) then
		local Armour = math.min(GetPedArmour(Ped) + Amount,100)
		SetPedArmour(Ped,Armour)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARMOUR
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Armour(source,Amount)
	if not source or not Characters[source] then return end

	local Ped = GetPlayerPed(source)
	if DoesEntityExist(Ped) then
		SetPedArmour(Ped,Amount)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Teleport(source,x,y,z)
	local Character = source and Characters[source]
	if not Character or not Character.id then
		return false
	end

	local Ped = GetPlayerPed(source)
	if not DoesEntityExist(Ped) then
		return false
	end

	x,y,z = tonumber(x) or 0.0,tonumber(y) or 0.0,tonumber(z) or 0.0
	SetEntityCoords(Ped,x + 0.0001,y + 0.0001,z + 0.0001,false,false,false,false)
	TriggerEvent("DebugWeapons",Character.id,false,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Creation(Passport)
	if not Passport then
		return false
	end

	local source = vRP.Source(Passport)
	if not source then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	Datatable.Creation = true
	exports.vrp:Bucket(source,"Exit")

	if not SpawnCoords or #SpawnCoords == 0 then
		return false
	end

	local Spawn = SpawnCoords[math.random(#SpawnCoords)]
	vRP.Teleport(source,Spawn.x,Spawn.y,Spawn.z)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HEADING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Heading(source,Heading)
	local Ped = GetPlayerPed(source)
	if source and Characters[source] and DoesEntityExist(Ped) then
		SetEntityHeading(Ped,Heading)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETENTITYCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetEntityCoords(source)
	local Ped = GetPlayerPed(source)
	return (source and Characters[source] and DoesEntityExist(Ped)) and GetEntityCoords(Ped) or vec3(0,0,0)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETENTITYHEADING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetEntityHeading(source)
	local Ped = GetPlayerPed(source)
	return (source and Characters[source] and DoesEntityExist(Ped)) and GetEntityHeading(Ped) or 0.0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSIDEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsideVehicle(source)
	local Ped = GetPlayerPed(source)
	return source and Characters[source] and DoesEntityExist(Ped) and GetVehiclePedIsIn(Ped) ~= 0 or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSIDEVEHICLEPASSAGER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsideVehiclePassager(source)
	local Ped = GetPlayerPed(source)
	return source and Characters[source] and DoesEntityExist(Ped) and GetVehiclePedIsIn(Ped) ~= 0 and GetPedInVehicleSeat(GetVehiclePedIsIn(Ped),0) == Ped or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOESENTITYEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DoesEntityExist(source)
	return source and Characters[source] and DoesEntityExist(GetPlayerPed(source)) or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISENTITYVISIBLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.IsEntityVisible(source)
	local Character = source and Characters[source]
	if not Character or not Character.id then
		return false
	end

	local Ped = GetPlayerPed(source)
	if DoesEntityExist(Ped) and not IsEntityVisible(Ped) then
		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.CreateObject(Model,x,y,z,Weapon,Component)
	local source = source
	local Character = Characters[source]
	if not Character or not Character.id then
		return false
	end

	local Hash = GetHashKey(Model)
	local CurrentTimer = os.time() + 10
	local Route = GetPlayerRoutingBucket(source)
	local Entity = CreateObject(Component or Hash,x,y,z - 2.0,true,true,false)

	while not DoesEntityExist(Entity) or NetworkGetNetworkIdFromEntity(Entity) == 0 do
		if os.time() >= CurrentTimer then
			return false
		end

		Wait(10)
	end

	SetEntityRoutingBucket(Entity,Route)

	local NetObjects = NetworkGetNetworkIdFromEntity(Entity)

	if Weapon then
		Weapons[Character.id] = Weapons[Character.id] or {}
		Weapons[Character.id][Weapon] = NetObjects
	else
		Objects[Character.id] = Objects[Character.id] or {}
		Objects[Character.id][NetObjects] = true
	end

	return NetObjects
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:BUCKET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("vRP:Bucket")
AddEventHandler("vRP:Bucket",function(Mode)
	local source = source
	local Character = Characters[source]
	if not Character or not Character.id then
		return false
	end

	exports.vrp:Bucket(source,Mode,Character.id)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUCKET
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Bucket",function(source,Mode,Route)
	local PlayerState = Player(source)
	if not PlayerState then
		return false
	end

	local State = PlayerState.state
	Route = math.max(0,tonumber(Route) or 0)

	if Mode == "Enter" then
		if State.Route ~= Route then
			State.Route = Route
			SetPlayerRoutingBucket(source,Route)

			local Character = Characters[source]
			if Character and Character.id then
				TriggerEvent("DebugWeapons",Character.id,false,true)
			end

			if Route > 0 and not Buckets[Route] then
				Buckets[Route] = true
				SetRoutingBucketEntityLockdownMode(Route,"strict")
				SetRoutingBucketPopulationEnabled(Route,false)
			end
		end
	else
		if State.Route ~= 0 then
			State.Route = 0
			SetPlayerRoutingBucket(source,0)

			local Character = Characters[source]
			if Character and Character.id then
				TriggerEvent("DebugWeapons",Character.id,false,true)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:RELOADWEAPONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:ReloadWeapons",function(source)
	local Character = source and Characters[source]
	if not Character or not Character.id then
		return false
	end

	local Inventory = vRP.Inventory(Character.id)
	for _,v in pairs(Inventory) do
		if v and v.item and exports.vrp:ItemTypeCheck(v.item,"Armamento") and not vRP.CheckDamaged(v.item) then
			TriggerClientEvent("inventory:CreateWeapon",source,v.item)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:WAITCHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("vRP:WaitCharacters")
AddEventHandler("vRP:WaitCharacters",function()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Character = Characters[source]
	if not Character then
		return false
	end

	if Character.Banned and Character.Banned > 0 then
		Player(source).state.Banned = true
		exports.vrp:Bucket(source,"Enter",Banned.Route)
		TriggerClientEvent("Notify",source,ServerName,"Restam "..parseInt(Character.Banned).." minutos de reclusão.","server",10000)
		vRP.LeaveServiceBanned(Passport,source)

		if Banned.Mute then
			TriggerClientEvent("pma-voice:Mute",source,true)
		end
	else
		exports.vrp:Bucket(source,"Exit")

		if Character.Prison and Character.Prison > 0 then
			Player(source).state.Prison = true
		end
	end

	TriggerEvent("vRP:ReloadWeapons",source,Passport)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.Barbershop(Barbershop)
	local source = source
	local Ped = GetPlayerPed(source)
	if Ped and DoesEntityExist(Ped) then
		SetPedHeadBlendData(Ped,Barbershop[1],Barbershop[2],0,Barbershop[53],Barbershop[54],0,Barbershop[3] + 0.0,Barbershop[5] + 0.0,0.0,false)

		SetPedEyeColor(Ped,Barbershop[4])

		SetPedComponentVariation(Ped,2,Barbershop[10],0,0)
		SetPedHairTint(Ped,Barbershop[11],Barbershop[12])

		SetPedHeadOverlay(Ped,0,Barbershop[7],1.0)
		SetPedHeadOverlayColor(Ped,0,0,0,0)

		SetPedHeadOverlay(Ped,1,Barbershop[22],Barbershop[23] + 0.0)
		SetPedHeadOverlayColor(Ped,1,1,Barbershop[24],Barbershop[24])

		SetPedHeadOverlay(Ped,2,Barbershop[19],Barbershop[20] + 0.0)
		SetPedHeadOverlayColor(Ped,2,1,Barbershop[21],Barbershop[21])

		SetPedHeadOverlay(Ped,3,Barbershop[9],1.0)
		SetPedHeadOverlayColor(Ped,3,0,0,0)

		SetPedHeadOverlay(Ped,4,Barbershop[13],Barbershop[14] + 0.0)
		SetPedHeadOverlayColor(Ped,4,1,Barbershop[50],Barbershop[51])

		SetPedHeadOverlay(Ped,5,Barbershop[25],Barbershop[26] + 0.0)
		SetPedHeadOverlayColor(Ped,5,2,Barbershop[27],Barbershop[27])

		SetPedHeadOverlay(Ped,6,Barbershop[6],1.0)
		SetPedHeadOverlayColor(Ped,6,0,0,0)

		SetPedHeadOverlay(Ped,7,Barbershop[52],1.0)
		SetPedHeadOverlayColor(Ped,7,0,0,0)

		SetPedHeadOverlay(Ped,8,Barbershop[16],Barbershop[17] + 0.0)
		SetPedHeadOverlayColor(Ped,8,2,Barbershop[18],Barbershop[18])

		SetPedHeadOverlay(Ped,9,Barbershop[8],1.0)
		SetPedHeadOverlayColor(Ped,9,0,0,0)

		SetPedHeadOverlay(Ped,10,Barbershop[47],Barbershop[48] + 0.0)
		SetPedHeadOverlayColor(Ped,10,1,Barbershop[49],Barbershop[49])

		SetPedHeadOverlay(Ped,11,Barbershop[55],1.0)
		SetPedHeadOverlayColor(Ped,11,0,0,0)

		SetPedHeadOverlay(Ped,12,Barbershop[56],1.0)
		SetPedHeadOverlayColor(Ped,12,0,0,0)

		SetPedFaceFeature(Ped,0,Barbershop[28] + 0.0)
		SetPedFaceFeature(Ped,1,Barbershop[29] + 0.0)
		SetPedFaceFeature(Ped,2,Barbershop[30] + 0.0)
		SetPedFaceFeature(Ped,3,Barbershop[31] + 0.0)
		SetPedFaceFeature(Ped,4,Barbershop[32] + 0.0)
		SetPedFaceFeature(Ped,5,Barbershop[33] + 0.0)
		SetPedFaceFeature(Ped,6,Barbershop[44] + 0.0)
		SetPedFaceFeature(Ped,7,Barbershop[34] + 0.0)
		SetPedFaceFeature(Ped,8,Barbershop[36] + 0.0)
		SetPedFaceFeature(Ped,9,Barbershop[35] + 0.0)
		SetPedFaceFeature(Ped,10,Barbershop[45] + 0.0)
		SetPedFaceFeature(Ped,11,Barbershop[15] + 0.0)
		SetPedFaceFeature(Ped,12,Barbershop[42] + 0.0)
		SetPedFaceFeature(Ped,13,Barbershop[46] + 0.0)
		SetPedFaceFeature(Ped,14,Barbershop[37] + 0.0)
		SetPedFaceFeature(Ped,15,Barbershop[38] + 0.0)
		SetPedFaceFeature(Ped,16,Barbershop[40] + 0.0)
		SetPedFaceFeature(Ped,17,Barbershop[39] + 0.0)
		SetPedFaceFeature(Ped,18,Barbershop[41] + 0.0)
		SetPedFaceFeature(Ped,19,Barbershop[43] + 0.0)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	GlobalState.Players = GetNumPlayerIndices()

	TriggerEvent("DebugWeapons",Passport,true)
	TriggerEvent("DebugObjects",Passport)
end)