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
Tunnel.bindInterface("lscustoms",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Networked = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permission(Index)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if exports.bank:CheckTaxes(Passport) or exports.bank:CheckFines(Passport) then
		return false
	end

	local Location = Locations[Index]
	if not Location then
		return false
	end

	local Permission = Location.Permission
	if Permission and not vRP.HasService(Passport,Permission) then
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Save(Model,Plate,Initial)
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Price = Calculate(Initial,Model)
	if Price > 0 and not vRP.PaymentFull(Passport,Price,true) then
		return false
	end

	local OtherPassport = vRP.PassportPlate(Plate)
	if OtherPassport then
		local Name = OtherPassport..":"..Model
		local Consult = vRP.GetSrvData("LsCustoms:"..Name,true)
		for Index,v in pairs(Initial) do
			if Index == "VehicleExtras" then
				for Extra,Data in pairs(v) do
					if Data.Installed ~= Data.Selected then
						Consult.VehicleExtras = Consult.VehicleExtras or {}
						Consult.VehicleExtras[Extra] = Data.Selected
					end
				end
			elseif Index == "Respray" then
				Consult.Respray = {
					PrimaryColour = {
						Type = v.PrimaryColour.Selected.Type,
						Color = v.PrimaryColour.Selected.Color
					},
					SecondaryColour = {
						Type = v.SecondaryColour.Selected.Type,
						Color = v.SecondaryColour.Selected.Color
					},
					PearlescentColour = v.PearlescentColour.Selected,
					WheelColour = v.WheelColour.Selected,
					DashboardColour = v.DashboardColour.Selected,
					InteriorColour = v.InteriorColour.Selected
				}
			elseif Index == "Wheels" then
				Consult.Wheels = Consult.Wheels or {}

				for Type,Data in pairs(v) do
					if Data.Installed ~= Data.Selected then
						if Type == "TyreSmoke" then
							Consult.Wheels.TyreSmoke = Data.Selected
						elseif Type == "CustomTyres" then
							Consult.Wheels.CustomTyres = Data.Selected
						else
							Consult.Wheels.Category = Type
							Consult.Wheels.Value = Data.Selected
						end
					end
				end
			elseif v.Installed ~= v.Selected then
				Consult[Index] = v.Selected
			end
		end

		vRP.SetSrvData("LsCustoms:"..Name,Consult,true)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LSCUSTOMS:NETWORK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("lscustoms:Network")
AddEventHandler("lscustoms:Network",function(Network,Plate)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	if not Network then
		Networked[Passport] = nil
		return false
	end

	local Entity = NetworkGetEntityFromNetworkId(Network)
	if not Entity or Entity <= 0 or not DoesEntityExist(Entity) or GetEntityType(Entity) ~= 2 then
		return false
	end

	Networked[Passport] = {
		Entity = Entity,
		Network = Network,
		Plate = Plate
	}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	local Data = Networked[Passport]
	if not Data then
		return false
	end

	Networked[Passport] = nil

	SetTimeout(2500,function()
		if DoesEntityExist(Data.Entity) then
			TriggerEvent("garages:Deleted",Data.Network,Data.Plate)
		end
	end)
end)