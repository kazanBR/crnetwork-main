-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Posts = {}
local Display = {}
local Active = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCOORDSFROMCAM
-----------------------------------------------------------------------------------------------------------------------------------------
function GetCoordsFromCam(Distance,Coords)
	local RadConv = math.pi / 180
	local Rotation = GetGameplayCamRot()
	local Adjustes = vec3(Rotation.x * RadConv,Rotation.y * RadConv,Rotation.z * RadConv)
	local Direction = vec3(-math.sin(Adjustes.z) * math.abs(math.cos(Adjustes.x)),math.cos(Adjustes.z) * math.abs(math.cos(Adjustes.x)),math.sin(Adjustes.x))

	return Coords + Direction * Distance
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHAT:POSTIT_NEW
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("chat:postit_new")
AddEventHandler("chat:postit_new",function(Admin)
	if not Active then
		Active = true

		CreateThread(function()
			while Active do
				local Ped = PlayerPedId()
				local Camera = GetGameplayCamCoord()
				local Handler = StartExpensiveSynchronousShapeTestLosProbe(Camera,GetCoordsFromCam(25.0,Camera),-1,Ped,4)
				local _,_,Coords = GetShapeTestResult(Handler)

				DrawMarker(28,Coords.x,Coords.y,Coords.z,0.0,0.0,0.0,0.0,0.0,0.0,0.05,0.05,0.05,88,101,242,175,false,false,false,false)

				if IsControlJustPressed(1,38) then
					if Admin then
						exports.keyboard:Copy("Cordenadas",string.format("%.2f,%.2f,%.2f",Coords.x,Coords.y,Coords.z))
					else
						vSERVER.Add(Coords)
					end

					Active = false
				end

				Wait(0)
			end
		end)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHAT:POSTIT_REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("chat:postit_remove")
AddEventHandler("chat:postit_remove",function(Route,Number)
	if Posts[Route] and Posts[Route][Number] then
		Posts[Route][Number] = nil

		if not next(Posts[Route]) then
			Posts[Route] = nil
		end
	end

	if Display[Route] and Display[Route][Number] then
		SendNUIMessage({ Action = "RemoveMe", Payload = Number })
		Display[Route][Number] = nil

		if not next(Display[Route]) then
			Display[Route] = nil
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHAT:POSTIT_ADD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("chat:postit_add")
AddEventHandler("chat:postit_add",function(Route,Number,Content)
	Posts[Route] = Posts[Route] or {}
	Posts[Route][Number] = Content
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		if LocalPlayer.state.Active and Posts[LocalPlayer.state.Route] then
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)
			local Route = LocalPlayer.state.Route

			for Number,v in pairs(Posts[Route]) do
				local Distance = #(Coords - v.Coords)

				if Distance <= v.Distance then
					TimeDistance = 1
					local _,x,y = GetScreenCoordFromWorldCoord(v.Coords.x,v.Coords.y,v.Coords.z)

					Display[Route] = Display[Route] or {}

					if not Display[Route][Number] then
						SendNUIMessage({ Action = "ShowMe", Payload = { Id = Number, Author = v.Author, Message = v.Message, X = x, Y = y, Postit = true } })
						Display[Route][Number] = true
					end

					SendNUIMessage({ Action = "UpdateMe", Payload = { Id = Number, Message = v.Message, X = x, Y = y } })

					if IsControlJustPressed(0,47) and Distance <= 2 then
						vSERVER.Delete(Route,Number)
					end
				elseif Display[Route] and Display[Route][Number] then
					SendNUIMessage({ Action = "RemoveMe", Payload = Number })
					Display[Route][Number] = nil

					if not next(Display[Route]) then
						Display[Route] = nil
					end
				end
			end
		end

		Wait(TimeDistance)
	end
end)