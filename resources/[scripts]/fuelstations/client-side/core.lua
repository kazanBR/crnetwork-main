-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("fuelstations")
vGARAGE = Tunnel.getInterface("garages")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local List = {}
local Blips = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATIONS:CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("fuelstations:Connect")
AddEventHandler("fuelstations:Connect",function(Table)
	Locations = Table

	for Permission,v in pairs(Locations) do
		Blips[Permission] = AddBlipForCoord(v.BlipCoords)
		SetBlipSprite(Blips[Permission],v.Blip or Config.DefaultIcon)
		SetBlipDisplay(Blips[Permission],4)
		SetBlipAsShortRange(Blips[Permission],true)
		SetBlipColour(Blips[Permission],v.Color or Config.DefaultColor)
		SetBlipScale(Blips[Permission],Config.DefaultScale)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.Name or Config.DefaulName)
		EndTextCommandSetBlipName(Blips[Permission])

		Wait(10)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADPEDS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)

		for Permission,v in pairs(Locations) do
			if #(Coords - v.Coords.xyz) then
				if not List[Permission] and LoadModel(v.Model) then
					List[Permission] = CreatePed(26,v.Model,v.Coords.x,v.Coords.y,v.Coords.z - 1,v.Coords.w,false,false)

					SetEntityInvincible(List[Permission],true)
					FreezeEntityPosition(List[Permission],true)
					DecorSetBool(List[Permission],"CREATIVE_PED",true)
					SetEntityAsMissionEntity(List[Permission],true,true)
					SetBlockingOfNonTemporaryEvents(List[Permission],true)
					TaskPlayAnim(List[Permission],v.Anim[1],v.Anim[2],8.0,8.0,-1,1,0,0,0,0)

					exports.target:AddBoxZone("FuelStations:"..Permission,v.Coords.xyz,0.75,0.75,{
						name = "FuelStations:"..Permission,
						heading = v.Coords.w,
						minZ = v.Coords.z - 1.0,
						maxZ = v.Coords.z + 1.0
					},{
						Distance = 1.75,
						shop = Permission,
						options = {
							{
								event = "fuelstations:Open",
								label = "Abrir",
								tunnel = "server"
							},{
								event = "fuelstations:Gallon",
								label = "Comprar Galão",
								tunnel = "server"
							}
						}
					})
				end
			else
				if List[Permission] then
					if DoesEntityExist(List[Permission]) then
						DeleteEntity(List[Permission])
					end

					exports.target:RemCircleZone("FuelStations:"..Permission)
					List[Permission] = nil
				end
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATIONS:BLIP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("fuelstations:Blip")
AddEventHandler("fuelstations:Blip",function(Permission,Name,Color,Blip)
	if Locations[Permission] then
		Locations[Permission].Name = Name
		Locations[Permission].Color = Color
		Locations[Permission].Blip = Blip
	end

	if Blips[Permission] then
		SetBlipSprite(Blips[Permission],Blip)
		SetBlipColour(Blips[Permission],Color)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(Name)
		EndTextCommandSetBlipName(Blips[Permission])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATIONS:OPENED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("fuelstations:Opened")
AddEventHandler("fuelstations:Opened",function()
	SetNuiFocus(true,true)
	TransitionToBlurred(1000)
	SetCursorLocation(0.5,0.5)
	TriggerEvent("hud:Active",false)
	SendNUIMessage({ Action = "Open", Payload = vSERVER.Player() })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATIONS:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("fuelstations:Notify")
AddEventHandler("fuelstations:Notify",function(Title,Message,Type)
	SendNUIMessage({ Action = "Notify", Payload = { Title = Title, Message = Message, Type = Type } })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	SetNuiFocus(false,false)
	SetCursorLocation(0.5,0.5)
	TransitionFromBlurred(1000)
	TriggerEvent("hud:Active",true)

	Callback("Ok")
end)

-- SendNUIMessage({
-- 	Action = "Jobs",
--     Payload = { -- Dados do player
--     	Name = "",
--     	Avatar = ""
--     }
-- })
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOME
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Home",function(Data,Callback)
	Callback(vSERVER.Home())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Update",function(Data,Callback)
	Callback(vSERVER.Update(Data))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOCK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Stock",function(Data,Callback)
	Callback(vSERVER.Stock())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATESTOCK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("UpdateStock",function(Data,Callback)
	Callback(vSERVER.UpdateStock(Data.Price))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Bank",function(Data,Callback)
	Callback(vSERVER.Bank())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPOSITBANK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("DepositBank",function(Data,Callback)
	Callback(vSERVER.DepositBank(Data.Value))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WITHDRAWBANK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("WithdrawBank",function(Data,Callback)
	Callback(vSERVER.WithdrawBank(Data.Value))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFERBANK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("TransferBank",function(Data,Callback)
	Callback(vSERVER.TransferBank(Data.Passport,Data.Value))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Replenishment",function(Data,Callback)
	Callback({
		Active = vSERVER.Replenishment(),
		Shipments = Config.Replenishments
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTSHIPMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("StartShipment",function(Data,Callback)
	Callback(vSERVER.StartShipment(Data.Index,Data.Mode))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISHSHIPMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("FinishShipment",function(Data,Callback)
    Callback(vSERVER.FinishShipment())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("OfferJobs",function(Data,Callback)
    Callback({ -- Lista dos empregos oferecidos
    	{
    		Id = 1,
    		Name = "Carga pequena",
    		Amount = 50,
    		Reward = 1000
    	}
    })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CreateJob",function(Data,Callback)
    -- Name
    -- Amount
    -- Reward
    Callback(true) -- true ou false (true se deu certo a criação)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("UpdateJob",function(Data,Callback)
    -- Id
    -- Name
    -- Amount
    -- Reward
    Callback(true) -- true ou false (true se deu certo a alteração)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("DestroyJob",function(Data,Callback)
    -- Id
    Callback(true) -- true ou false (true se deu certo a exclusão)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Upgrades",function(Data,Callback)
	Callback({
        { -- Dados da Capacidade de estoque
            Level = 0, -- Level atual
            List = { -- Lista de níveis disponíveis
            	{
            		Amount = 250,
            		Price = 500
            	}
            }
        },
        { -- Dados da Capacidade do caminhão
            Level = 0, -- Level atual
            List = { -- Lista de níveis disponíveis
            	{
            		Amount = 250,
            		Price = 500
            	}
            }
        },
        { -- Dados do Relacionamento
            Level = 0, -- Level atual
            List = { -- Lista de níveis disponíveis
            	{
            		Amount = 250,
            		Price = 500
            	}
            }
        }
    })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Upgrade",function(Data,Callback)
    -- Mode ( "Stock" | "Truck" | "Relationship" )
    Callback(true) -- true ou false (true se deu certo o upgrade)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EMPLOYEES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Employees",function(Data,Callback)
	Callback(vSERVER.Employees())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVITEEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("InviteEmployee",function(Data,Callback)
	Callback(vSERVER.InviteEmployee(Data.Passport))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHYEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("HierarchyEmployee",function(Data,Callback)
	Callback(vSERVER.HierarchyEmployee(Data))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMISSEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("DismissEmployee",function(Data,Callback)
	Callback(vSERVER.DismissEmployee(Data.Passport))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Jobs",function(Data,Callback)
	Callback({
        1, -- Indíce do emprego ativo ( se não houver ativo, enviar "nil" )
        "Name", -- Nome do posto que está
        { -- Lista dos empregos oferecidos
        	{
        		Id = 1,
        		Name = "Carga pequena",
        		Amount = 50,
        		Reward = 50000
        	}
        }
    })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("StartJob",function(Data,Callback)
    -- Id
    Callback(true) -- true ou false (true se deu certo o inicío do serviço)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("FinishJob",function(Data,Callback)
    -- Id
    Callback(true) -- true ou false (true se deu certo a finalização do serviço)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFEROWNERSHIP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("TransferOwnership",function(Data,Callback)
	Callback(vSERVER.TransferOwnership(Data.Passport))
end)