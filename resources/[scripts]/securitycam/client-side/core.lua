-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("securitycam")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Camera
local Objects = {}
local Cooldown = 0
local Heading = 0.0
local CameraRot = vec3(0.0,0.0,0.0)
local LastCoords = vec3(0.0,0.0,0.0)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Index,v in pairs(Locations) do
		exports.target:AddCircleZone("SecurityCam:"..Index,v.Coords,0.1,{
			name = "SecurityCam:"..Index,
			heading = 0.0,
			useZ = true
		},{
			Distance = v.Distance,
			options = {
				{
					event = "securitycam:Open",
					label = "Abrir",
					tunnel = "products",
					legend = "Câmeras de Segurança",
					service = Index
				},
				v.Hacker and {
					event = "securitycam:Inative",
					label = "Desativar",
					tunnel = "client"
				},
				v.Hacker and {
					event = "securitycam:Hacker",
					label = "Hackear",
					tunnel = "client"
				}
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:TABLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Table",function(Table)
	for Number,v in pairs(Table) do
		if v.Mode == "Camera" then
			Objects[Number] = v
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Adicionar")
AddEventHandler("objects:Adicionar",function(Number,Table)
	if Table and Table.Mode == "Camera" then
		Objects[Number] = Table
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Remover")
AddEventHandler("objects:Remover",function(Number)
	if Objects[Number] then
		Objects[Number] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLAMP
-----------------------------------------------------------------------------------------------------------------------------------------
function Clamp(Value,Minimal,Maximum)
	return math.max(Minimal,math.min(Maximum,Value))
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLAMYAWTORANGE
-----------------------------------------------------------------------------------------------------------------------------------------
function ClampYawToRange(Current,Minimal,Maximum)
	Current = (Current + 360.0) % 360.0
	Minimal = (Minimal + 360.0) % 360.0
	Maximum = (Maximum + 360.0) % 360.0

	if Minimal < Maximum then
		return Clamp(Current,Minimal,Maximum)
	end

	if Current > Maximum and Current < Minimal then
		return ((Current - Maximum) < (Minimal - Current)) and Maximum or Minimal
	end

	return Current
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SECURITYCAM:INATIVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("securitycam:Inative",function()
	if not next(Objects) then
		TriggerEvent("Notify","Câmeras de Segurança","Nenhuma câmera encontrada no sistema.","vermelho",5000)
		return false
	end

	if not vSERVER.Connections() then
		TriggerEvent("Notify","Câmeras de Segurança","Sistema desativado temporariamente.","vermelho",5000)
		return false
	end

	if (HackerItem and not vSERVER.TakeItem()) or not exports.lettergame:LetterGame(LetterDuration,LetterSpeed) then
		return false
	end

	TriggerEvent("Notify","Câmeras de Segurança","Sistema desativado com sucesso.","verde",5000)
	vSERVER.Inative()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SECURITYCAM:HACKER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("securitycam:Hacker",function()
	if not next(Objects) then
		TriggerEvent("Notify","Câmeras de Segurança","Nenhuma câmera encontrada no sistema.","vermelho",5000)
		return false
	end

	if not vSERVER.Connections() then
		TriggerEvent("Notify","Câmeras de Segurança","Sistema desativado temporariamente.","vermelho",5000)
		return false
	end

	if (HackerItem and not vSERVER.TakeItem()) or not exports.lettergame:LetterGame(LetterDuration,LetterSpeed) or Cooldown > GetGameTimer() then
		return false
	end

	TriggerEvent("Notify","Câmeras de Segurança","Sistema hackeado com sucesso, agora você consegue visualizar câmeras da cidade.","verde",5000)
	Cooldown = GetGameTimer() + (HackerDuration * 60000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SECURITYCAM:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("securitycam:Open",function(Index)
	if not next(Objects) then
		TriggerEvent("Notify","Câmeras de Segurança","Nenhuma câmera encontrada no sistema.","vermelho",5000)
		return false
	end

	if not vSERVER.Connections() then
		TriggerEvent("Notify","Câmeras de Segurança","Sistema desativado temporariamente.","vermelho",5000)
		return false
	end

	local Display = 0
	local Selected = Index and Locations[Index]

	for Number,v in pairs(Objects) do
		if (Selected and v.Permission and v.Permission == Selected.Permission) or (not v.Permission and (CheckPolice() or Cooldown > GetGameTimer())) then
			local MinRoad,MinCross = GetStreetNameAtCoord(v.Coords[1],v.Coords[2],v.Coords[3])
			local FullRoad,FullCross = GetStreetNameFromHashKey(MinRoad),GetStreetNameFromHashKey(MinCross)
			exports.dynamic:AddButton(v.Name,FullRoad.."  |  "..FullCross,"securitycam:Selected",Number,false,false)

			Display += 1
		end
	end

	if Display > 0 then
		exports.dynamic:Open()
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SECURITYCAM:SELECTED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("securitycam:Selected",function(Number)
	if not Objects[Number] then
		return false
	end

	TriggerEvent("dynamic:Close")

	if LocalPlayer.state.SecurityCam and Camera and DoesCamExist(Camera) then
		TriggerEvent("securitycam:Destroy")
	end

	local Ped = PlayerPedId()
	local Selected = Objects[Number].Coords
	local Coords = GetOffsetFromCoordAndHeadingInWorldCoords(Selected[1],Selected[2],Selected[3] - 0.25,Selected[4],0.0,-0.05,0.0)

	Heading = (Selected[4] + 180.0) % 360.0
	CameraRot = vec3(-30.0,0.0,Heading)
	LastCoords = GetEntityCoords(Ped)

	Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)
	SetCamCoord(Camera,Coords.x,Coords.y,Coords.z)
	RenderScriptCams(true,false,0,true,true)
	SetCamRot(Camera,CameraRot,2)
	SetCamActive(Camera,true)
	SetCamFov(Camera,60.0)

	SetEntityVisible(Ped,false)
	SetEntityInvincible(Ped,true)
	FreezeEntityPosition(Ped,true)
	SetEntityCoordsNoOffset(Ped,Coords.x,Coords.y,Coords.z)

	LocalPlayer.state:set("SecurityCam",true,true)
	LocalPlayer.state:set("Commands",true,true)
	LocalPlayer.state:set("Buttons",true,true)

	SetTimecycleModifier("scanline_cam_cheap")
	TriggerEvent("pma-voice:Mute",true)
	SetTimecycleModifierStrength(2.0)
	TriggerEvent("hud:Active",false)
	vSERVER.Initialize(LastCoords)

	CreateThread(function()
		while LocalPlayer.state.SecurityCam and Camera and DoesCamExist(Camera) do
			local XRel = GetDisabledControlNormal(0,1)
			local YRel = GetDisabledControlNormal(0,2)
			if XRel ~= 0.0 or YRel ~= 0.0 then
				local NewPitch = Clamp(CameraRot.x - YRel * 0.2 * 10.0, -45.0,0.0)
				local NewYaw = ClampYawToRange(CameraRot.z - XRel * 0.2 * 10.0,Heading - 90.0,Heading + 90.0)
				CameraRot = vec3(NewPitch,0.0,NewYaw)
				SetCamRot(Camera,CameraRot,2)
			end

			Wait(0)
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SECURITYCAM:DESTROY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("securitycam:Destroy")
AddEventHandler("securitycam:Destroy",function()
	if LocalPlayer.state.SecurityCam and Camera and DoesCamExist(Camera) then
		local Ped = PlayerPedId()

		SetEntityCoordsNoOffset(Ped,LastCoords.x,LastCoords.y,LastCoords.z - 1)

		LocalPlayer.state:set("SecurityCam",false,true)
		LocalPlayer.state:set("Commands",false,true)
		LocalPlayer.state:set("Buttons",false,true)

		ClearTimecycleModifier("scanline_cam_cheap")
		RenderScriptCams(false,true,100,true,true)
		TriggerEvent("pma-voice:Mute",false)
		SetTimecycleModifierStrength(0.0)
		TriggerEvent("hud:Active",true)
		DestroyCam(Camera,false)
		vSERVER.Finalizing()
		Camera = nil

		SetTimeout(1000,function()
			FreezeEntityPosition(Ped,false)
			SetEntityInvincible(Ped,false)
			SetEntityVisible(Ped,true)
		end)
	end
end)