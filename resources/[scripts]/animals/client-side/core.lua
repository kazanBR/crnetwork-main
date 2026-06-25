-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Animal = nil
local Follow = false
local AnimalNet = nil
local FollowThread = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISVALIDENTITY
-----------------------------------------------------------------------------------------------------------------------------------------
local function IsValidEntity(Entity)
	return Entity and Entity ~= 0 and DoesEntityExist(Entity)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPLAYERVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetPlayerVehicle(Ped)
	if IsPedInAnyVehicle(Ped) then
		local Vehicle = GetVehiclePedIsIn(Ped,false)
		if IsValidEntity(Vehicle) then
			return Vehicle
		end
	end

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARANIMAL
-----------------------------------------------------------------------------------------------------------------------------------------
local function ClearAnimal()
	if IsValidEntity(Animal) then
		TriggerServerEvent("animals:Cleaner")

		if DoesEntityExist(Animal) then
			DeleteEntity(Animal)
		end
	end

	Animal = nil
	Follow = false
	AnimalNet = nil
	FollowThread = false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTFOLLOWTHREAD
-----------------------------------------------------------------------------------------------------------------------------------------
local function StartFollowThread()
	if FollowThread then
		return false
	end

	FollowThread = true

	CreateThread(function()
		while FollowThread do
			local Ped = PlayerPedId()
			if not IsValidEntity(Ped) or not IsValidEntity(Animal) then
				ClearAnimal()
				break
			end

			if AnimalNet and not NetworkDoesEntityExistWithNetworkId(AnimalNet) then
				ClearAnimal()
				break
			end

			local Timeout = GetGameTimer() + 2000
			while not NetworkHasControlOfEntity(Animal) and GetGameTimer() < Timeout do
				NetworkRequestControlOfEntity(Animal)
				Wait(100)
			end

			local Coords = GetEntityCoords(Ped)
			local AnimalCoords = GetEntityCoords(Animal)
			if #(Coords - AnimalCoords) >= 25.0 then
				SetEntityCoordsNoOffset(Animal,Coords.x,Coords.y,Coords.z - 1,false,false,false)
				ClearPedTasksImmediately(Animal)
				TaskFollowToOffsetOfEntity(Animal,Ped,0.5,0.0,0.0,5.0,-1,0.0,true)
			end

			if not FollowThread then
				break
			end

			Wait(1000)
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:DYNAMIC
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("animals:Dynamic",function()
	if IsValidEntity(Animal) then
		exports.dynamic:AddMenu("Domésticos","Todas as funções dos animais domésticos.","animal")
		exports.dynamic:AddButton("Ficar/Seguir","Alternar comportamento.","animals:Functions","Seguir","animal",false)
		exports.dynamic:AddButton("Guardar","Guardar animal.","animals:Functions","Deletar","animal",false)

		local Ped = PlayerPedId()
		local Vehicle = GetPlayerVehicle(Ped)
		if Vehicle ~= 0 and not IsPedOnAnyBike(Ped) then
			if not IsPedInAnyVehicle(Animal) then
				exports.dynamic:AddButton("Colocar","Colocar no veículo.","animals:Functions","Colocar","animal",false)
			else
				exports.dynamic:AddButton("Remover","Remover do veículo.","animals:Functions","Remover","animal",false)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("animals:Delete")
AddEventHandler("animals:Delete",function()
	ClearAnimal()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("animals:Spawn")
AddEventHandler("animals:Spawn",function(Model)
	if IsValidEntity(Animal) then
		return false
	end

	if not LoadModel(Model) then
		return false
	end

	local Ped = PlayerPedId()
	if not IsValidEntity(Ped) then
		return false
	end

	if not IsModelInCdimage(Model) then
		return false
	end

	local Heading = GetEntityHeading(Ped)
	local Coords = GetOffsetFromEntityInWorldCoords(Ped,0.0,1.0,0.0)
	local Entity = CreatePed(28,Model,Coords.x,Coords.y,Coords.z - 1,Heading,true,true)
	if not IsValidEntity(Entity) then
		return false
	end

	Animal = Entity
	AnimalNet = NetworkGetNetworkIdFromEntity(Animal)

	SetNetworkIdCanMigrate(AnimalNet,true)
	DecorSetBool(Animal,"CREATIVE_PED",true)
	SetEntityAsMissionEntity(Animal,true,true)

	SetPedKeepTask(Animal,true)
	SetEntityInvincible(Animal,true)
	SetBlockingOfNonTemporaryEvents(Animal,true)
	SetPedFleeAttributes(Animal,0,0)
	SetPedConfigFlag(Animal,185,true)
	SetPedCanRagdoll(Animal,false)
	SetEntityCollision(Animal,true,true)
	SetEntityLoadCollisionFlag(Animal,true)
	SetPedCanBeTargetted(Animal,false)

	ClearPedTasksImmediately(Animal)
	TaskFollowToOffsetOfEntity(Animal,Ped,0.5,0.0,0.0,5.0,-1,0.0,true)
	TriggerServerEvent("animals:Register",AnimalNet)
	TriggerEvent("dynamic:Close")
	StartFollowThread()
	Follow = true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("animals:Functions",function(Mode)
	if not IsValidEntity(Animal) then
		ClearAnimal()
		return false
	end

	local Ped = PlayerPedId()
	if not IsValidEntity(Ped) then
		return false
	end

	local Vehicle = GetPlayerVehicle(Ped)
	if not NetworkHasControlOfEntity(Animal) then
		NetworkRequestControlOfEntity(Animal)
	end

	if Mode == "Seguir" then
		Follow = not Follow
		ClearPedTasksImmediately(Animal)

		if Follow then
			TaskFollowToOffsetOfEntity(Animal,Ped,0.5,0.0,0.0,5.0,-1,0.0,true)
			StartFollowThread()
		end
	elseif Mode == "Colocar" then
		if Vehicle ~= 0 and IsVehicleSeatFree(Vehicle,0) then
			ClearPedTasksImmediately(Animal)
			TaskEnterVehicle(Animal,Vehicle,-1,0,1.0,16,0)
			FollowThread = false
			Follow = false
		end
	elseif Mode == "Remover" then
		if Vehicle ~= 0 then
			Follow = true
			TaskLeaveVehicle(Animal,Vehicle,16)
			TaskFollowToOffsetOfEntity(Animal,Ped,0.5,0.0,0.0,5.0,-1,0.0,true)
			StartFollowThread()
		end
	elseif Mode == "Deletar" then
		TriggerEvent("dynamic:Close")
		ClearAnimal()
	end
end)