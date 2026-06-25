-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Walk = nil
local Binded = {}
local Object = nil
local Point = false
local Crouch = false
local Persistent = nil
local PersistentList = {}
local Button = GetNetworkTime()
local AnimVars = { nil,nil,false,49 }
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADBLOCK
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local CreativeBinds = GetResourceKvpString("CreativeBinds")
	Binded = (CreativeBinds and json.decode(CreativeBinds)) or {}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCALPLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
LocalPlayer.state:set("Route",0,true)
LocalPlayer.state:set("Passport",0,true)
LocalPlayer.state:set("Bed",false,false)
LocalPlayer.state:set("Carry",false,true)
LocalPlayer.state:set("Walk",false,false)
LocalPlayer.state:set("Arena",false,true)
LocalPlayer.state:set("Active",false,true)
LocalPlayer.state:set("Chair",false,false)
LocalPlayer.state:set("Cancel",false,true)
LocalPlayer.state:set("Banned",false,true)
LocalPlayer.state:set("Prison",false,true)
LocalPlayer.state:set("Races",false,false)
LocalPlayer.state:set("Hoverfy",true,false)
LocalPlayer.state:set("Bennys",false,false)
LocalPlayer.state:set("Handcuff",false,true)
LocalPlayer.state:set("Commands",false,true)
LocalPlayer.state:set("Safezone",false,true)
LocalPlayer.state:set("Spectate",false,false)
LocalPlayer.state:set("Creation",false,false)
LocalPlayer.state:set("ItemCamera",false,true)
LocalPlayer.state:set("SecurityCam",false,true)
LocalPlayer.state:set("DamageModify",false,false)
LocalPlayer.state:set("Name","Desconhecido",true)

LocalPlayer.state:set("Nitro",false,true)
LocalPlayer.state:set("Buttons",false,true)
LocalPlayer.state:set("BlockLocked",false,false)
LocalPlayer.state:set("Source",GetPlayerServerId(PlayerId()),true)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WALKERS
-----------------------------------------------------------------------------------------------------------------------------------------
local Walkers = {
	"move_m@alien","anim_group_move_ballistic","move_f@arrogant@a","move_m@brave","move_m@casual@a","move_m@casual@b","move_m@casual@c",
	"move_m@casual@d","move_m@casual@e","move_m@casual@f","move_f@chichi","move_m@confident","move_m@business@a","move_m@business@b",
	"move_m@business@c","move_m@drunk@a","move_m@drunk@slightlydrunk","move_m@buzzed","move_m@drunk@verydrunk","move_f@femme@",
	"move_characters@franklin@fire","move_characters@michael@fire","move_m@fire","move_f@flee@a","move_p_m_one","move_m@gangster@generic",
	"move_m@gangster@ng","move_m@gangster@var_e","move_m@gangster@var_f","move_m@gangster@var_i","anim@move_m@grooving@","move_f@heels@c",
	"move_m@hipster@a","move_m@hobo@a","move_f@hurry@a","move_p_m_zero_janitor","move_p_m_zero_slow","move_m@jog@","anim_group_move_lemar_alley",
	"move_heist_lester","move_f@maneater","move_m@money","move_m@posh@","move_f@posh@","move_m@quick","female_fast_runner","move_m@sad@a",
	"move_m@sassy","move_f@sassy","move_f@scared","move_f@sexy@a","move_m@shadyped@a","move_characters@jimmy@slow@","move_m@swagger",
	"move_m@tough_guy@","move_f@tough_guy@","move_p_m_two","move_m@bag","move_m@intimidation@cop@unarmed"
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Walk",("player:%s"):format(LocalPlayer.state.Source),function(Name,Key,Value)
	local Ped = PlayerPedId()

	if Walk == Value then
		return false
	end

	if not Value then
		Walk = nil

		if not Crouch then
			ResetPedMovementClipset(Ped,0.25)
		end

		return false
	end

	if Crouch then
		Walk = Value
		return false
	end

	if LoadMovement(Value) then
		SetPedMovementClipset(Ped,Value,0.25)
		Walk = Value
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANDAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("andar",function(source,Message)
	if not Message[1] then
		LocalPlayer.state:set("Walk",false,false)
		return false
	end

	local Mode = parseInt(Message[1])
	if not Walkers[Mode] then
		return false
	end

	LocalPlayer.state:set("Walk",Walkers[Mode],true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADBLOCK
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		if LocalPlayer.state.Active then
			local Ped = PlayerPedId()

			if LocalPlayer.state.Cancel then
				TimeDistance = 0

				local Controls = { 24,25,38,47,257,140,142,137 }
				for _,Control in ipairs(Controls) do
					DisableControlAction(0,Control,true)
				end

				DisablePlayerFiring(Ped,true)
			end

			if Crouch then
				TimeDistance = 0
				DisableControlAction(0,21,true)
				DisableControlAction(0,22,true)
				DisablePlayerFiring(Ped,true)
			end

			if exports["lb-phone"]:IsOpen() or AnimVars[3] then
				TimeDistance = 0

				local Controls = { 18,24,25,68,70,91,140,142,143,257 }
				for _,Control in ipairs(Controls) do
					DisableControlAction(0,Control,true)
				end

				DisablePlayerFiring(Ped,true)

				if AnimVars[3] and not IsEntityPlayingAnim(Ped,AnimVars[1],AnimVars[2],3) then
					TaskPlayAnim(Ped,AnimVars[1],AnimVars[2],8.0,8.0,-1,AnimVars[4],1,0,0,0)
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.CreateObjects(Dict,Anim,Prop,Flag,Hands,Height,Pos1,Pos2,Pos3,Pos4,Pos5)
	local Ped = PlayerPedId()
	if DoesEntityExist(Object) then
		TriggerServerEvent("DeleteObject",NetworkGetNetworkIdFromEntity(Object))
		Object = nil
	end

	if Anim ~= "" then
		if LoadAnim(Dict) then
			TaskPlayAnim(Ped,Dict,Anim,8.0,8.0,-1,Flag,1,0,0,0)
		end

		AnimVars = { Dict,Anim,true,Flag }
	end

	if IsPedInAnyVehicle(Ped) then
		return false
	end

	local Coords = GetEntityCoords(Ped)
	local Networked = vRPS.CreateObject(Prop,Coords.x,Coords.y,Coords.z)
	if not Networked then return end

	local Entity = LoadNetwork(Networked)
	local Timeout = GetNetworkTime() + 5000
	while not DoesEntityExist(Entity) do
		if GetNetworkTime() > Timeout then
			return false
		end

		Wait(100)
	end

	Object = Entity

	SetEntityCollision(Object,false,true)
	SetEntityCompletelyDisableCollision(Object,true,true)
	SetEntityNoCollisionEntity(Object,Ped,true)

	if Height then
		AttachEntityToEntity(Object,Ped,GetPedBoneIndex(Ped,Hands),Height,Pos1,Pos2,Pos3,Pos4,Pos5,true,true,false,false,1,true)
	else
		AttachEntityToEntity(Object,Ped,GetPedBoneIndex(Ped,Hands),0.0,0.0,0.0,0.0,0.0,0.0,true,true,false,false,2,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROY
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.Destroy(Mode)
	if LocalPlayer.state.Chair then
		TriggerEvent("target:UpChair")
	end

	if LocalPlayer.state.Bed then
		TriggerEvent("target:UpBed")
	end

	if Mode == "one" then
		tvRP.stopAnim(true)
	elseif Mode == "two" then
		tvRP.stopAnim(false)
	else
		tvRP.stopAnim(true)
		tvRP.stopAnim(false)
	end

	AnimVars[3] = false

	if Object and DoesEntityExist(Object) then
		if NetworkGetEntityIsNetworked(Object) then
			TriggerServerEvent("DeleteObject",NetworkGetNetworkIdFromEntity(Object))
		else
			DeleteEntity(Object)
		end

		Object = nil
	end

	if Persistent and Persistent.Anim then
		SetTimeout(250,function()
			local Ped = PlayerPedId()
			if Persistent and DoesEntityExist(Ped) and not IsPedInAnyVehicle(Ped) and GetEntityHealth(Ped) > 100 then
				TriggerEvent("emotes",Persistent.Anim)
			end
		end)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 250
		if LocalPlayer.state.Active and Point then
			TimeDistance = 0

			local Ped = PlayerPedId()
			if not DoesEntityExist(Ped) or IsPedInAnyVehicle(Ped) or GetEntityHealth(Ped) <= 100 then
				Wait(500)
				goto continue
			end

			local CamPitch = GetGameplayCamRelativePitch()
			CamPitch = math.max(-70.0, math.min(42.0,CamPitch))
			CamPitch = (CamPitch + 70.0) / 112.0

			local CamHeading = GetGameplayCamRelativeHeading()
			CamHeading = math.max(-180.0, math.min(180.0,CamHeading))

			local HeadingNormalized = (CamHeading + 180.0) / 360.0

			local cosH = math.cos(CamHeading)
			local sinH = math.sin(CamHeading)

			local blocked = false
			local Coords = GetOffsetFromEntityInWorldCoords(Ped,(cosH * -0.2) - (sinH * (0.4 * HeadingNormalized + 0.3)),(sinH * -0.2) + (cosH * (0.4 * HeadingNormalized + 0.3)),0.6)
			local Ray = Cast_3dRayPointToPoint(Coords.x,Coords.y,Coords.z - 0.2,Coords.x,Coords.y,Coords.z + 0.2,0.4,95,Ped,7)

			local _,hit = GetRaycastResult(Ray)
			blocked = hit == 1

			SetTaskMoveNetworkSignalFloat(Ped,"Pitch",CamPitch)
			SetTaskMoveNetworkSignalFloat(Ped,"Heading",HeadingNormalized * -1.0 + 1.0)
			SetTaskMoveNetworkSignalBool(Ped,"isBlocked",blocked)
			SetTaskMoveNetworkSignalBool(Ped,"isFirstPerson",GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
		end

		::continue::
		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUICANCEL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiCancel",function()
	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and GetNetworkTime() >= Button and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Handcuff and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) then
		Button = GetNetworkTime() + 1000
		TriggerServerEvent("inventory:Cancel")

		if LocalPlayer.state.Arena then
			TriggerEvent("arena:Exit")
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUIHANDSUP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiHandsUp",function()
	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not IsPedInAnyVehicle(Ped) and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) then
		if IsEntityPlayingAnim(Ped,"random@mugging3","handsup_standing_base",3) then
			StopAnimTask(Ped,"random@mugging3","handsup_standing_base",8.0)
			tvRP.AnimActive()
		else
			if LoadAnim("random@mugging3") then
				tvRP.playAnim(true,{"random@mugging3","handsup_standing_base"},true)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUIPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiPoint",function()
	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not IsPedInAnyVehicle(Ped) and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) then
		if Point then
			RequestTaskMoveNetworkStateTransition(Ped,"Stop")

			if not IsPedInjured(Ped) then
				ClearPedSecondaryTask(Ped)
			end

			SetPedConfigFlag(Ped,36,false)
			Point = false

			return false
		end

		if LoadAnim("anim@mp_point") then
			tvRP.AnimActive()
			SetPedConfigFlag(Ped,36,true)
			TaskMoveNetwork(Ped,"task_mp_pointing",0.5,0,"anim@mp_point",24)
			Point = true
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUIENGINE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiEngine",function()
	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) then
		local Vehicle = GetVehiclePedIsIn(Ped,false)
		if Vehicle == 0 then
			return false
		end

		if GetPedInVehicleSeat(Vehicle,-1) ~= Ped then
			return false
		end

		local Running = GetIsVehicleEngineRunning(Vehicle)
		local NewState = not Running

		SetVehicleEngineOn(Vehicle,NewState,true,true)
		SetVehicleUndriveable(Vehicle,not NewState)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUICROUCH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiCrouch",function()
	DisableControlAction(0,36,true)

	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not IsPedInAnyVehicle(Ped) and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) then
		if Crouch then
			Crouch = false

			ResetPedStrafeClipset(Ped)
			SetPedMoveRateOverride(Ped,1.0)
			ResetPedMovementClipset(Ped,0.25)

			if Walk and LoadMovement(Walk) then
				SetPedMovementClipset(Ped,Walk,0.25)
			end
		else
			if LoadMovement("move_ped_crouched") and LoadMovement("move_ped_crouched_strafing") then
				SetPedStrafeClipset(Ped,"move_ped_crouched_strafing")
				SetPedMovementClipset(Ped,"move_ped_crouched",0.25)
				SetPedMoveRateOverride(Ped,0.75)

				Crouch = true
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUIBIND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiBind",function(source,Message)
	local Ped = PlayerPedId()
	if not (GetNetworkTime() >= Button and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not LocalPlayer.state.Cancel and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not IsPedReloading(Ped)) then
		return false
	end

	local Slot = parseInt(Message[1])
	if not Slot or Slot < 0 or Slot > 3 then
		return false
	end

	Button = GetNetworkTime() + 1000

	TriggerEvent("inventory:Use",Slot)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUIPADS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiPads",function(source,Message)
	local Ped = PlayerPedId()
	if Message[1] and (Binded[Message[1]] or Message[1] == "0") and LocalPlayer.state.Active and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) and not LocalPlayer.state.Handcuff and not IsPedInAnyVehicle(Ped) and not IsPedArmed(Ped,7) and not IsPedSwimming(Ped) then
		local Key = tostring(Message[1])
		if not Key then
			return false
		end

		if not Binded[Key] and Key ~= "0" then
			return false
		end

		if Key == "0" then
			SetPedToRagdoll(Ped,2500,2500,0,0,0,0)
			return false
		end

		TriggerEvent("emotes",Binded[Key])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BINDS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("binds",function(source,Message)
	local Anim = Message[2]
	local Key = parseInt(Message[1])
	if not Key or Key < 1 or Key > 9 then
		return false
	end

	if not Anim or Anim == "" then
		return false
	end

	Anim = Anim:lower()
	Binded[tostring(Key)] = Anim
	SetResourceKvp("CreativeBinds",json.encode(Binded))
	TriggerEvent("Notify","Animações","A animação <b>"..Anim.."</b> foi salva na tecla <b>"..Key.."</b>.","verde",5000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GUILOCK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("GuiLock",function()
	local Ped = PlayerPedId()
	if LocalPlayer.state.Active and not LocalPlayer.state.BlockLocked and GetNetworkTime() >= Button and not IsPauseMenuActive() and not IsPedReloading(Ped) and not LocalPlayer.state.Buttons and not LocalPlayer.state.Commands and not LocalPlayer.state.Handcuff and not exports["lb-phone"]:IsOpen() and GetEntityHealth(Ped) > 100 and not LocalPlayer.state.Cancel and not IsPedReloading(Ped) then
		local Vehicle,Network = tvRP.VehicleList()
		if not Vehicle or not Network then
			return false
		end

		Button = GetNetworkTime() + 1000

		TriggerServerEvent("garages:Lock",Network)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERSISTENTBLOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.PersistentBlock(ItemName,Animation)
	local ParsedItem = SplitOne(ItemName)
	if not ParsedItem or not Animation then
		return false
	end

	PersistentList = PersistentList or {}

	if not Persistent then
		Persistent = {
			Item = ParsedItem,
			Anim = Animation
		}

		TriggerEvent("emotes",Animation)

		return false
	end

	if Persistent.Item == ParsedItem then
		return false
	end

	for _,v in ipairs(PersistentList) do
		if v.Item == ParsedItem then
			return false
		end
	end

	PersistentList[#PersistentList + 1] = {
		Item = ParsedItem,
		Anim = Animation
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERSISTENTNONE
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.PersistentNone(ItemName)
	local ParsedItem = SplitOne(ItemName)
	if not ParsedItem then
		return false
	end

	PersistentList = PersistentList or {}

	if Persistent and ParsedItem == Persistent.Item then
		Persistent = nil
		tvRP.Destroy()
	else
		for i = #PersistentList,1,-1 do
			if PersistentList[i].Item == ParsedItem then
				table.remove(PersistentList,i)
				break
			end
		end
	end

	if not Persistent then
		local Next = PersistentList[1]
		if Next then
			table.remove(PersistentList,1)

			Persistent = {
				Item = Next.Item,
				Anim = Next.Anim
			}

			TriggerEvent("emotes",Next.Anim)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("GuiCancel","Cancelar todas as ações.","keyboard","F6")
RegisterKeyMapping("GuiHandsUp","Levantar as mãos.","keyboard","X")
RegisterKeyMapping("GuiPoint","Apontar os dedos.","keyboard","B")
RegisterKeyMapping("GuiCrouch","Agachar.","keyboard","LCONTROL")
RegisterKeyMapping("GuiEngine","Ligar o veículo.","keyboard","Z")
RegisterKeyMapping("GuiLock","Trancar/Destrancar.","keyboard","L")

RegisterKeyMapping("GuiBind 0","Interação do botão 1.","keyboard","1")
RegisterKeyMapping("GuiBind 1","Interação do botão 2.","keyboard","2")
RegisterKeyMapping("GuiBind 2","Interação do botão 3.","keyboard","3")
RegisterKeyMapping("GuiBind 3","Interação do botão 4.","keyboard","4")

RegisterKeyMapping("GuiPads 0","Interação de animação 0.","keyboard","NUMPAD0")
RegisterKeyMapping("GuiPads 1","Interação de animação 1.","keyboard","NUMPAD1")
RegisterKeyMapping("GuiPads 2","Interação de animação 2.","keyboard","NUMPAD2")
RegisterKeyMapping("GuiPads 3","Interação de animação 3.","keyboard","NUMPAD3")
RegisterKeyMapping("GuiPads 4","Interação de animação 4.","keyboard","NUMPAD4")
RegisterKeyMapping("GuiPads 5","Interação de animação 5.","keyboard","NUMPAD5")
RegisterKeyMapping("GuiPads 6","Interação de animação 6.","keyboard","NUMPAD6")
RegisterKeyMapping("GuiPads 7","Interação de animação 7.","keyboard","NUMPAD7")
RegisterKeyMapping("GuiPads 8","Interação de animação 8.","keyboard","NUMPAD8")
RegisterKeyMapping("GuiPads 9","Interação de animação 9.","keyboard","NUMPAD9")