-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("moneywash")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Objects = {}
local MoneyWash = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		if LocalPlayer.state.Active then
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)
			local Route = LocalPlayer.state.Route
			local Vehicle = GetVehiclePedIsUsing(Ped)

			for Index,v in pairs(MoneyWash) do
				if v.Route == Route then
					local OtherCoords = vec3(v.Coords[1],v.Coords[2],v.Coords[3])
					if #(Coords - OtherCoords) <= 50 then
						if not Objects[Index] then
							exports.target:AddBoxZone("MoneyWash:"..Index,vec3(OtherCoords.x,OtherCoords.y,OtherCoords.z + 1.1),1.4,1.4,{
								name = "MoneyWash:"..Index,
								heading = v.Coords[4] or 0.0,
								maxZ = OtherCoords.z + 2.25,
								minZ = OtherCoords.z + 0.0
							},{
								shop = Index,
								Distance = 1.5,
								options = {
									{
										event = "moneywash:Information",
										label = "Informações",
										tunnel = "client"
									},{
										event = "moneywash:StoreObjects",
										label = "Guardar",
										tunnel = "server"
									}
								}
							})

							CreateModels(Index,v.Hash,v.Coords)
						elseif DoesEntityExist(Vehicle) then
							SetEntityNoCollisionEntity(Objects[Index],Vehicle,false)
						end
					elseif Objects[Index] then
						ClearObjects(Index)
					end
				elseif Objects[Index] then
					ClearObjects(Index)
				end
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:INFORMATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("moneywash:Information",function(Selected)
	local Information = vSERVER.Information(Selected)
	if not Information then
		return false
	end

	local OsTime = math.randomseed()
	local Battery = "Coloque uma bateria de 75Ah."
	if Information.Timer and Information.Timer >= OsTime then
		Battery = "Restam "..CompleteTimers(Information.Timer - OsTime).."."
	end

	local Bleach = "Adicione 5lts de alvejante."
	if Information.Bleach and Information.Bleach >= OsTime then
		Bleach = "Restam "..CompleteTimers(Information.Bleach - OsTime).."."
	end

	exports.dynamic:AddButton("Compartimento","Primário: <rare>"..Currency..Dotted(Information.Money).."</rare>  /  Secundário: <epic>"..Currency..Dotted(Information.Washed).."</epic>","","",false,false)
	exports.dynamic:AddButton("Primário","Esvaziar compartimento primário.","moneywash:Money",Selected,false,true)
	exports.dynamic:AddButton("Secundário","Esvaziar compartimento secundário.","moneywash:Washed",Selected,false,true)
	exports.dynamic:AddButton("Adicionar","Guardar no compartimento primário.","moneywash:Add",Selected,false,true)
	exports.dynamic:AddButton("Energia",Battery,"moneywash:Battery",Selected,false,true)
	exports.dynamic:AddButton("Alvejante",Bleach,"moneywash:Bleach",Selected,false,true)

	if Information.Passport == LocalPlayer.state.Passport then
		exports.dynamic:AddButton("Senha","Trocar palavra chave.","moneywash:Password",Selected,false,true)
	end

	exports.dynamic:Open()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEMODELS
-----------------------------------------------------------------------------------------------------------------------------------------
function CreateModels(Number,Hash,Coords)
	if LoadModel(Hash) then
		local Object = CreateObjectNoOffset(Hash,Coords[1],Coords[2],Coords[3],false,false,false)
		if not DoesEntityExist(Object) then
			return false
		end

		Objects[Number] = Object

		local Ped = PlayerPedId()
		local Vehicle = GetVehiclePedIsUsing(Ped)
		if DoesEntityExist(Vehicle) then
			SetEntityNoCollisionEntity(Object,Vehicle,false)
		end

		FreezeEntityPosition(Object,true)
		SetEntityHeading(Object,Coords[4])
		PlaceObjectOnGroundProperly(Object)
		SetModelAsNoLongerNeeded(Hash)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:TABLE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("moneywash:Table")
AddEventHandler("moneywash:Table",function(Table)
	MoneyWash = Table
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:NEW
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("moneywash:New")
AddEventHandler("moneywash:New",function(Selected,Table)
	MoneyWash[Selected] = Table
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("moneywash:Update")
AddEventHandler("moneywash:Update",function(Selected,Passport)
	if MoneyWash[Selected] then
		MoneyWash[Selected].Passport = Passport
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEAROBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
function ClearObjects(Index)
	local Object = Objects[Index]
	if not Object then
		return false
	end

	if DoesEntityExist(Object) then
		DeleteEntity(Object)
	end

	exports.target:RemCircleZone("MoneyWash:"..Index)
	Objects[Index] = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MONEYWASH:REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("moneywash:Remove")
AddEventHandler("moneywash:Remove",function(Selected)
	if MoneyWash[Selected] then
		MoneyWash[Selected] = nil
	end

	ClearObjects(Selected)
end)