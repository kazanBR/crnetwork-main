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
Tunnel.bindInterface("slotmachine",Creative)
vSERVER = Tunnel.getInterface("slotmachine")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Machines = {}
local Selected = nil
local Spinning = false
local Spin01,Spin02,Spin03 = nil
-----------------------------------------------------------------------------------------------------------------------------------------
-- SLOTMACHINE:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("slotmachine:Init",function(Table)
	Selected = nil

	for Index,v in pairs(Machines) do
		if #(v.Coords - Table[4]) <= 0.25 then
			Selected = Index
			break
		end
	end

	if Selected and vSERVER.Check(Selected) then
		LocalPlayer["state"]:set("Cancel",true,true)
		LocalPlayer["state"]:set("Buttons",true,true)

		local Ped = PlayerPedId()
		local Heading = GetEntityHeading(Table[1])
		local Bone = GetEntityBoneIndexByName(Table[1],"Chair_Base_01")
		local Chairs = GetWorldPositionOfEntityBone(Table[1],Bone)

		SetEntityHeading(Ped,Heading)
		SetEntityCoords(Ped,Chairs.x,Chairs.y,Chairs.z + 0.65,false,false,false,false)
		vRP.playAnim(false,{ task = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" },false)

		local TableCoords = GetEntityCoords(Table[1])
		local Leave = GetOffsetFromEntityInWorldCoords(Table[1],0.0,-1.5,0.0)
		local Offset01 = GetObjectOffsetFromCoords(TableCoords,Heading,-0.118,0.05,0.9)
		local Offset02 = GetObjectOffsetFromCoords(TableCoords,Heading,0.000,0.05,0.9)
		local Offset03 = GetObjectOffsetFromCoords(TableCoords,Heading,0.118,0.05,0.9)

		if LoadModel(Machines[Selected].Prop) then
			Spin01 = CreateObject(Machines[Selected].Prop,Offset01.x,Offset01.y,Offset01.z,false,false,false)
			Spin02 = CreateObject(Machines[Selected].Prop,Offset02.x,Offset02.y,Offset02.z,false,false,false)
			Spin03 = CreateObject(Machines[Selected].Prop,Offset03.x,Offset03.y,Offset03.z,false,false,false)

			SetEntityHeading(Spin01,Heading)
			SetEntityHeading(Spin02,Heading)
			SetEntityHeading(Spin03,Heading)

			TriggerEvent("inventory:Buttons",{
				{ Letter = "E", Text = "Jogar" },
				{ Letter = "S", Text = "Sair" }
			})

			CreateThread(function()
				while Spin01 do
					if IsDisabledControlJustPressed(0,72) and not Spinning then
						if DoesEntityExist(Spin01) then
							DeleteEntity(Spin01)
						end

						if DoesEntityExist(Spin02) then
							DeleteEntity(Spin02)
						end

						if DoesEntityExist(Spin03) then
							DeleteEntity(Spin03)
						end

						SetEntityCoords(Ped,Leave,false,false,false,false)
						LocalPlayer["state"]:set("Buttons",false,true)
						LocalPlayer["state"]:set("Cancel",false,true)
						TriggerEvent("inventory:CloseButtons")
						vSERVER.Clean(Selected)
						vRP.Destroy()

						Selected,Spinning = nil,false
						Spin01,Spin02,Spin03 = nil,nil,nil
					end

					if IsDisabledControlJustPressed(0,38) and not Spinning and vSERVER.Payment(Selected) then
						Spinning = true
						vRP.playAnim(true,{"anim_casino_a@amb@casino@games@slots@female","press_spin_a"},false)
						vSERVER.StartSlots(Selected)
					end

					Wait(1)
				end
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MACHINESLOTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MachineSlots(Result)
	if Spinning then
		for i = 1,300 do
			local Rotation01 = GetEntityRotation(Spin01)
			local Rotation02 = GetEntityRotation(Spin02)
			local Rotation03 = GetEntityRotation(Spin03)

			if i < 180 then
				SetEntityRotation(Spin01,Rotation01.x + math.random(40,100) / 10,Rotation01.y,Rotation01.z,1,true)
			elseif i == 180 then
				SetEntityRotation(Spin01,Result.A * 22.5 - 180 + 0.0,Rotation01.y,Rotation01.z,1,false)
			end

			if i < 240 then
				SetEntityRotation(Spin02,Rotation02.x + math.random(40,100) / 10,Rotation02.y,Rotation02.z,1,true)
			elseif i == 240 then
				SetEntityRotation(Spin02,Result.B * 22.5 - 180 + 0.0,Rotation02.y,Rotation02.z,1,false)
			end

			if i < 300 then
				SetEntityRotation(Spin03,Rotation03.x + math.random(40,100) / 10,Rotation03.y,Rotation03.z,1,true)
			elseif i == 300 then
				SetEntityRotation(Spin03,Result.C * 22.5 - 180 + 0.0,Rotation03.y,Rotation03.z,1,false)
			end

			Wait(10)
		end

		Spinning = false
		vSERVER.Winner(Selected)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SLOTMACHINE:MACHINES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("slotmachine:Machines")
AddEventHandler("slotmachine:Machines",function(Table)
	Machines = Table
end)