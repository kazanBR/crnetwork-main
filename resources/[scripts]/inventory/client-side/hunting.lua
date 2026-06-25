-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Model = nil
local Entity = nil
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS
-----------------------------------------------------------------------------------------------------------------------------------------
local Animals = {
	"deer","boar","mtlion","coyote"
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKRATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CheckRation()
	if not Entity or not DoesEntityExist(Entity) then
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Animals()
	return Entity,Model
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:RATION
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Ration")
AddEventHandler("inventory:Ration",function(Coords)
	local Cooldown = 0
	local FoundSafe = false
	local Ped = PlayerPedId()
	local SpawnPosition = nil
	local Coords = GetEntityCoords(Ped)

	repeat
		Cooldown = Cooldown + 1
		local x = Coords.x + math.random(-75,75)
		local y = Coords.y + math.random(-75,75)
		local z = Coords.z

		local Hitz,Groundz = GetGroundZFor_3dCoord(x,y,z,true)
		local SafeHitz,SafeCoords = GetSafeCoordForPed(x,y,Groundz,false,16)

		if Hitz and SafeHitz then
			FoundSafe = true
			SpawnPosition = SafeCoords
		end
	until FoundSafe or Cooldown >= 100

	if FoundSafe and SpawnPosition then
		Model = Animals[math.random(#Animals)]
		if LoadModel("a_c_"..Model) then
			Entity = CreatePed(28,"a_c_"..Model,SpawnPosition.x,SpawnPosition.y,SpawnPosition.z,0.0,true,false)

			SetPedAlertness(Entity,3)
			SetPedPathAvoidFire(Entity,1)
			SetPedSeeingRange(Entity,250.0)
			SetPedHearingRange(Entity,250.0)
			DisablePedPainAudio(Entity,true)
			SetPedFleeAttributes(Entity,0,0)
			SetPedPathCanUseLadders(Entity,1)
			SetPedDiesWhenInjured(Entity,true)
			SetPedPathCanUseClimbovers(Entity,1)
			SetPedPathCanDropFromHeight(Entity,1)
			SetPedCombatAttributes(Entity,5,true)
			SetPedCombatAttributes(Entity,2,true)
			SetPedCombatAttributes(Entity,1,true)
			SetPedCombatAttributes(Entity,16,true)
			SetPedCombatAttributes(Entity,46,true)
			SetPedCombatAttributes(Entity,26,true)
			SetPedCombatAttributes(Entity,3,false)
			SetCanAttackFriendly(Entity,false,true)
			SetPedSuffersCriticalHits(Entity,false)
			SetPedEnableWeaponBlocking(Entity,true)
			SetPedDropsWeaponsWhenDead(Entity,false)
			DecorSetBool(Entity,"CREATIVE_PED",true)
			SetEntityAsMissionEntity(Entity,true,true)
			SetBlockingOfNonTemporaryEvents(Entity,true)

			TaskGoStraightToCoord(Entity,Coords.x,Coords.y,Coords.z,1.0,-1,0.0,0.0)

			local Blip = AddBlipForEntity(Entity)
			SetBlipSprite(Blip,141)
			SetBlipAsShortRange(Blip,true)
		end
	end
end)