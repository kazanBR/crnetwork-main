-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Init = {}
local Sprays = {}
local Objects = {}
local Switch = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPRAYEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.SprayExist(Distance)
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)
	local MaxDistance = (Distance or 250.0) ^ 2

	for _,Spray in pairs(Sprays) do
		local Dist = Coords - Spray.Coords
		if (Dist.x * Dist.x + Dist.y * Dist.y + Dist.z * Dist.z) <= MaxDistance then
			return Spray.Permission
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:TABLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Table")
AddEventHandler("objects:Table",function(Data)
	Objects = Data or {}

	for Number,Object in pairs(Objects) do
		if Object.Mode == "Sprays" and not Sprays[Number] then
			local x,y,z = table.unpack(Object.Coords)
			local Blip = AddBlipForRadius(x,y,z,250.0)

			SetBlipColour(Blip,Object.Color)
			SetBlipAlpha(Blip,150)

			Sprays[Number] = {
				Blip = Blip,
				Coords = vec3(x,y,z),
				Permission = Object.Permission
			}
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Adicionar")
AddEventHandler("objects:Adicionar",function(Number,Data)
	if not Data then
		return false
	end

	Objects[Number] = Data

	if Data.Mode ~= "Sprays" or Sprays[Number] then
		return false
	end

	local x,y,z = table.unpack(Data.Coords)
	local Blip = AddBlipForRadius(x,y,z,250.0)
	SetBlipColour(Blip,Data.Color)
	SetBlipAlpha(Blip,150)

	Sprays[Number] = {
		Blip = Blip,
		Coords = vec3(x,y,z),
		Permission = Data.Permission
	}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Remover")
AddEventHandler("objects:Remover",function(Number)
	local Entity = Init[Number]
	local Data = Objects[Number]
	if Entity then
		if DoesEntityExist(Entity) then
			DeleteEntity(Entity)
		end

		if Data and Data.Mode then
			exports.target:RemCircleZone("Objects:" .. Number)
		end

		Init[Number] = nil
	end

	if Data and Data.Active == "Spikes" then
		TriggerEvent("spikes:Remover",Number)
	end

	local Spray = Sprays[Number]
	if Spray then
		local Blip = Spray.Blip
		if Blip and DoesBlipExist(Blip) then
			RemoveBlip(Blip)
		end

		Sprays[Number] = nil
	end

	Objects[Number] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Update")
AddEventHandler("objects:Update",function(Number,Passport)
	if Objects[Number] then
		Objects[Number].Passport = Passport
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDTARGETZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddTargetZone(Number,Coords,Weight,Options,Size,Box)
	if not Coords or not Size or not Options then
		return false
	end

	local z = Coords[3]
	local Zone = "Objects:"..Number
	local Params = { name = Zone, heading = Coords[4] or 0.0 }
	local Center = vec3(Coords[1],Coords[2],z + (Weight or 0.0))

	if Box then
		Params.minZ = z
		Params.maxZ = z + (Size.maxZ or 1.5)

		exports.target:AddBoxZone(Zone,Center,Size.width or 1.0,Size.height or 1.0,Params,Options)
	else
		Params.useZ = true
		exports.target:AddCircleZone(Zone,Center,Size.radius or 1.0,Params,Options)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGETLABEL
-----------------------------------------------------------------------------------------------------------------------------------------
function TargetLabel(Number,Coords,Mode,Weight,Item)
	local Modes = {
		Store = {
			isBox = false,
			size = { radius = 0.75 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Camera = {
			isBox = false,
			size = { radius = 0.25 },
			options = {
				shop = Number,
				Distance = 5.0,
				options = {
					{ event = "inventory:StoreObjects", label = "Retirar", tunnel = "server" }
				}
			}
		},
		Destroy = {
			isBox = false,
			size = { radius = 0.75 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:StoreObjects", label = "Destruir", tunnel = "server" }
				}
			}
		},
		Craftings = {
			isBox = false,
			size = { radius = 0.25 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "crafting:Open", label = "Abrir", tunnel = "products", service = Item and SplitOne(Item) or "" },
					{ event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Shops = {
			isBox = false,
			size = { radius = 0.45 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "shops:Open", label = "Abrir", tunnel = "products", service = Item and SplitOne(Item) or "" },
					{ event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Chests = {
			isBox = true,
			size = { width = 0.65, height = 0.95, maxZ = 0.5 },
			options = {
				shop = Number,
				Distance = 1.75,
				options = {
					{ event = "chest:Item", label = "Abrir", tunnel = "products", service = Item },
					LocalPlayer.state.Admin and { event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Sprays = {
			isBox = false,
			size = { radius = 1.0 },
			options = {
				shop = Number,
				Distance = 2.5,
				options = {
					{ event = "inventory:StoreObjects", label = "Violar", tunnel = "server" }
				}
			}
		},
		Recycle = {
			isBox = true,
			size = { width = 1.5, height = 3.75, maxZ = 2.0 },
			options = {
				shop = Number,
				Distance = 2.25,
				options = {
					{ event = "chest:Recycle", label = "Abrir", tunnel = "client" }
				}
			}
		},
		LootLegendary = {
			isBox = true,
			size = { width = 1.15, height = 2.15, maxZ = 0.8 },
			options = {
				shop = Number,
				Distance = 2.0,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootSupplies = {
			isBox = true,
			size = { width = 0.5, maxZ = 0.55 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootWeapons = {
			isBox = true,
			size = { width = 0.9, height = 1.5, maxZ = 0.65 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootMedics = {
			isBox = true,
			size = { width = 0.75, maxZ = 0.55 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootCode = {
			isBox = true,
			size = { maxZ = 1.75 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		}
	}

	if Modes[Mode] then
		AddTargetZone(Number,Coords,Weight,Modes[Mode].options,Modes[Mode].size,Modes[Mode].isBox)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEANDMANAGEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function CreateAndManageObject(Number,Table,Coords)
	if not Table or not Table.Coords then
		return false
	end

	local x = Table.Coords[1]
	local y = Table.Coords[2]
	local z = Table.Coords[3]

	local Distance = Table.Distance or 100.0
	local ConsultObject = Init[Number]
	local Ped = PlayerPedId()

	local dx = Coords.x - x
	local dy = Coords.y - y
	local dz = Coords.z - z

	if (dx * dx + dy * dy + dz * dz) > (Distance * Distance) then
		if ConsultObject then
			DestroyObject(Number,Table)
		end

		return false
	end

	if ConsultObject then
		if Table.Line then
			if HasEntityClearLosToEntity(Ped,ConsultObject,17) then
				SetEntityDrawOutline(ConsultObject,true)
			else
				SetEntityDrawOutline(ConsultObject,false)
			end
		end

		return false
	end

	if Table.Mode == "Chests" and Table.Permission then
		local Permission = SplitOne(Table.Permission)
		local Hierarchy = tonumber(SplitTwo(Table.Permission)) or 0

		local Level = LocalPlayer.state[Permission]
		if not Level or Level > Hierarchy then
			return false
		end
	end

	if not LoadModel(Table.Object) then
		return false
	end

	local Ped = PlayerPedId()
	local Entitys = CreateObjectNoOffset(Table.Object,x,y,z,false,false,false)
	if not DoesEntityExist(Entitys) then
		return false
	end

	Init[Number] = Entitys

	SetEntityHeading(Entitys,Table.Coords[4] or 0.0)
	FreezeEntityPosition(Entitys,true)
	SetEntityLodDist(Entitys,200)

	if Table.Line then
		SetEntityDrawOutlineShader(0)
		SetEntityDrawOutlineColor(88,101,242,200)
		SetEntityDrawOutline(Entitys,false)
	end

	if IsPedInAnyVehicle(Ped,false) then
		local Vehicle = GetVehiclePedIsUsing(Ped)
		if Vehicle ~= 0 and DoesEntityExist(Vehicle) then
			SetEntityNoCollisionEntity(Vehicle,Entitys,false)
		end
	end

	if not Table.Ground then
		PlaceObjectOnGroundProperly(Entitys)
	end

	if Table.Mode then
		TargetLabel(Number,Table.Coords,Table.Mode,Table.Weight or 0.0,Table.Item)
	end

	if Table.Active == "Spikes" then
		local MaxOffset = GetOffsetFromEntityInWorldCoords(Entitys,0.0,1.84,0.1)
		local MinOffset = GetOffsetFromEntityInWorldCoords(Entitys,0.0,-1.84,-0.1)
		TriggerEvent("spikes:Adicionar",Number,Table.Coords,MinOffset,MaxOffset)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)
		local Route = LocalPlayer.state.Route

		for Number,v in pairs(Objects) do
			local Bucket = v.Bucket
			if not Bucket or Bucket == Route then
				CreateAndManageObject(Number,v,Coords)
			elseif Init[Number] then
				DestroyObject(Number,v)
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function DestroyObject(Number,Data)
	local ConsultObject = Init[Number]
	if not ConsultObject then
		return false
	end

	Init[Number] = nil

	if Data.Mode then
		exports.target:RemCircleZone("Objects:"..Number)
	end

	if DoesEntityExist(ConsultObject) then
		if Data.Line then
			SetEntityDrawOutline(ConsultObject,false)
		end

		SetEntityAsMissionEntity(ConsultObject,true,true)
		DeleteEntity(ConsultObject)
	end

	if Data.Active == "Spikes" then
		TriggerEvent("spikes:Remover",Number)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTCONTROLLING
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.ObjectControlling(Model,Rotate,Align)
	local Switch = false
	local Aplication = false
	local OtherCoords = false

	if not LoadModel(Model) then
		return false,false
	end

	local Ped = PlayerPedId()
	local Heading = GetEntityHeading(Ped)
	local BaseCoords = GetOffsetFromEntityInWorldCoords(Ped,0.0,Align or 1.0,0.0)
	local NextObject = CreateObjectNoOffset(Model,BaseCoords.x,BaseCoords.y,BaseCoords.z)

	SetEntityAlpha(NextObject,200,false)
	SetEntityCollision(NextObject,false,false)
	SetEntityHeading(NextObject,Heading + (Rotate or 0.0))
	PlaceObjectOnGroundProperly(NextObject)

	local DefaultButtons = {
		{ Letter = "F", Text = "Cancelar" },
		{ Letter = "H", Text = "Posicionar" },
		{ Letter = "Q", Text = "Rotacionar Esquerda" },
		{ Letter = "E", Text = "Rotacionar Direita" },
		{ Letter = "Z", Text = "Trocar Modo" }
	}

	local ExtendedButtons = {
		{ Letter = "F", Text = "Cancelar" },
		{ Letter = "H", Text = "Posicionar" },
		{ Letter = "Q", Text = "Rotacionar Esquerda" },
		{ Letter = "E", Text = "Rotacionar Direita" },
		{ Letter = "-", Text = "Descer" },
		{ Letter = "+", Text = "Subir" },
		{ Letter = "↑", Text = "Frente" },
		{ Letter = "←", Text = "Esquerda" },
		{ Letter = "↓", Text = "Trás" },
		{ Letter = "→", Text = "Direita" },
		{ Letter = "Z", Text = "Trocar Modo" }
	}

	TriggerEvent("inventory:Buttons",DefaultButtons)

	local Progress = true

	while Progress do
		local ControlPressed = GetMovementControls(NextObject)
		if ControlPressed then
			MoveObject(NextObject,ControlPressed)
		end

		RotateObject(NextObject)
		DrawGraphOutline(NextObject)

		if not Switch then
			local Cam = GetGameplayCamCoord()
			local Dest = GetCoordsFromCam(10.0,Cam)
			local Handle = StartExpensiveSynchronousShapeTestLosProbe(Cam.x,Cam.y,Cam.z,Dest.x,Dest.y,Dest.z,-1,Ped,4)
			local _,Hit,Coords = GetShapeTestResult(Handle)
			if Hit == 1 then
				SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
			end
		end

		if IsControlJustPressed(0,48) then
			Switch = not Switch
			TriggerEvent("inventory:Buttons",Switch and ExtendedButtons or DefaultButtons)
		elseif IsControlJustPressed(1,74) then
			TriggerEvent("inventory:CloseButtons")
			Aplication = true
			Progress = false
		elseif IsControlJustPressed(0,49) then
			TriggerEvent("inventory:CloseButtons")
			Aplication = false
			Progress = false
		end

		Wait(0)
	end

	if DoesEntityExist(NextObject) then
		local oCoords = GetEntityCoords(NextObject)
		local oHeading = GetEntityHeading(NextObject)

		OtherCoords = {
			Optimize(oCoords.x),
			Optimize(oCoords.y),
			Optimize(oCoords.z),
			Optimize(oHeading)
		}

		DeleteEntity(NextObject)
	end

	if not OtherCoords or (OtherCoords[1] == 0.0 and OtherCoords[2] == 0.0) then
		Aplication = false
	end

	return Aplication,OtherCoords
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMOVEMENTCONTROLS
-----------------------------------------------------------------------------------------------------------------------------------------
function GetMovementControls(NextObject)
	local Controls = false

	if IsDisabledControlPressed(1,314) then
		Controls = {}
		Controls.zMoveUp = true
	elseif IsDisabledControlPressed(1,315) then
		Controls = {}
		Controls.zMoveDown = true
	end

	if IsDisabledControlPressed(1,172) then
		Controls = {}
		Controls.xMoveRight = true
	elseif IsDisabledControlPressed(1,173) then
		Controls = {}
		Controls.xMoveLeft = true
	end

	if IsDisabledControlPressed(1,174) then
		Controls = {}
		Controls.yMoveBackward = true
	elseif IsDisabledControlPressed(1,175) then
		Controls = {}
		Controls.yMoveForward = true
	end

	return Controls
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOVEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function MoveObject(NextObject,Controls)
	local Coords = GetEntityCoords(NextObject)

	if Controls.zMoveUp then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,0.0,0.001)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	elseif Controls.zMoveDown then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,0.0,-0.001)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	end

	if Controls.xMoveRight then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,0.001,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	elseif Controls.xMoveLeft then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,-0.001,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	end

	if Controls.yMoveBackward then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,-0.001,0.0,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	elseif Controls.yMoveForward then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.001,0.0,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function RotateObject(NextObject)
	if IsControlPressed(0,38) then
		SetEntityHeading(NextObject,GetEntityHeading(NextObject) + 0.05)
	elseif IsControlPressed(0,52) then
		SetEntityHeading(NextObject,GetEntityHeading(NextObject) - 0.05)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWGRAPHOUTLINE
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawGraphOutline(Object)
	local Coords = GetEntityCoords(Object)

	local offsetX = GetOffsetFromEntityInWorldCoords(Object,2.0,0.0,0.0)
	local offsetY = GetOffsetFromEntityInWorldCoords(Object,0.0,2.0,0.0)
	local offsetZ = GetOffsetFromEntityInWorldCoords(Object,0.0,0.0,2.0)

	local x1,x2 = Coords.x - offsetX.x,Coords.x + offsetX.x
	local y1,y2 = Coords.y - offsetY.y,Coords.y + offsetY.y
	local z1,z2 = Coords.z - offsetZ.z,Coords.z + offsetZ.z

	DrawLine(x1,Coords.y,Coords.z,x2,Coords.y,Coords.z,255,0,0,255)
	DrawLine(Coords.x,y1,Coords.z,Coords.x,y2,Coords.z,0,0,255,255)
	DrawLine(Coords.x,Coords.y,z1,Coords.x,Coords.y,z2,0,255,0,255)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCOORDSFROMCAM
-----------------------------------------------------------------------------------------------------------------------------------------
function GetCoordsFromCam(Distance,Coords)
	local Rotation = GetGameplayCamRot()
	local Pitch = math.rad(Rotation.x)
	local Roll = math.rad(Rotation.z)
	local Direction = vec3(-math.sin(Roll) * math.abs(math.cos(Pitch)),math.cos(Roll) * math.abs(math.cos(Pitch)),math.sin(Pitch))

	return vec3(Coords.x + Direction.x * Distance,Coords.y + Direction.y * Distance,Coords.z + Direction.z * Distance)
end