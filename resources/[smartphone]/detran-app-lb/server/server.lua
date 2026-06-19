local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")

local Server = {}
Tunnel.bindInterface("detran-app",Server)

local function notify(source,kind,message)
	TriggerClientEvent("Notify",source,kind or "verde",message,5000)
end

local function identity(Passport)
	return vRP.Identity(parseInt(Passport)) or {}
end

local function fullName(Passport)
	local Identity = identity(Passport)
	return (Identity.name or Identity.Name or "Passaporte").." "..(Identity.name2 or Identity.Lastname or tostring(Passport))
end

local function licenseData(Passport)
	local Data = vRP.UserData(Passport,"Driverlicense") or {}
	local Categories = {}

	for Key,Value in pairs(Data.categories or {}) do
		if type(Key) == "number" then
			Categories[tostring(Value)] = true
		elseif Value then
			Categories[tostring(Key)] = true
		end
	end

	return Categories,parseInt(Data.points or Data.Points or 0),parseInt(Data.createdAt or Data.CreatedAt or os.time())
end

local function vehicleByPlate(plate)
	local Result = vRP.Query("vehicles/plateVehicles",{ plate = tostring(plate or "") })
	return Result and Result[1]
end

local function vehiclePayload(row)
	if not row then
		return false
	end

	local Tax = parseInt(row.tax or 0)
	local Seized = parseInt(row.arrest or row.seized or 0)
	local IsSeized = Seized > os.time()

	return {
		model = VehicleName(row.vehicle) or row.vehicle,
		name = VehicleName(row.vehicle) or row.vehicle,
		vehicle = row.vehicle,
		plate = row.plate,
		tax = Tax,
		seized = IsSeized and 1 or 0,
		isLate = Tax > 0 and Tax < os.time(),
		isSeized = IsSeized
	}
end

local function response(status,plate,errorMessage)
	if status then
		return { status = "success", data = Server.getVehicle(plate) }
	end

	return { status = "error", error = errorMessage or "Nao foi possivel concluir." }
end

function Server.getData()
	local Passport = vRP.Passport(source)
	if not Passport then
		return { id = 0, name = "", categories = {} }
	end

	local Identity = identity(Passport)
	local Categories,Points,CreatedAt = licenseData(Passport)

	return {
		id = Passport,
		name = fullName(Passport),
		sex = Identity.sex == "F" and "Feminino" or "Masculino",
		categories = Categories,
		licensePoints = Points,
		createdAt = CreatedAt
	}
end

function Server.getVehicles()
	local Passport = vRP.Passport(source)
	local Vehicles = {}
	if not Passport then
		return Vehicles
	end

	for _,Row in pairs(vRP.Query("vehicles/UserVehicles",{ Passport = Passport }) or {}) do
		Vehicles[#Vehicles + 1] = vehiclePayload(Row)
	end

	return Vehicles
end

function Server.getVehicle(plate)
	local Passport = vRP.Passport(source)
	local Row = vehicleByPlate(plate)
	if not Passport or not Row or parseInt(Row.Passport) ~= parseInt(Passport) then
		return false
	end

	return vehiclePayload(Row)
end

function Server.payTax(plate)
	local source = source
	local Passport = vRP.Passport(source)
	local Row = vehicleByPlate(plate)
	if not Passport or not Row or parseInt(Row.Passport) ~= parseInt(Passport) then
		return response(false,plate,"Veiculo nao encontrado.")
	end

	if parseInt(Row.tax or 0) > os.time() then
		return response(false,plate,"Licenciamento ainda esta em dia.")
	end

	local Price = parseInt((VehiclePrice(Row.vehicle) or 0) * 0.10)
	if Price <= 0 then
		Price = 5000
	end

	if vRP.PaymentFull(Passport,Price,"Detran") then
		vRP.Query("vehicles/updateVehiclesTax",{ Passport = Passport, vehicle = Row.vehicle })
		notify(source,"verde","Licenciamento renovado.")
		return response(true,plate)
	end

	return response(false,plate,"Saldo insuficiente.")
end

function Server.payImpound(plate)
	local source = source
	local Passport = vRP.Passport(source)
	local Row = vehicleByPlate(plate)
	if not Passport or not Row or parseInt(Row.Passport) ~= parseInt(Passport) then
		return response(false,plate,"Veiculo nao encontrado.")
	end

	if parseInt(Row.arrest or 0) <= os.time() then
		return response(false,plate,"Veiculo nao esta apreendido.")
	end

	local Price = parseInt((VehiclePrice(Row.vehicle) or 0) * 0.15)
	if Price <= 0 then
		Price = 7500
	end

	if vRP.PaymentFull(Passport,Price,"Detran") then
		vRP.Query("vehicles/paymentArrest",{ Passport = Passport, vehicle = Row.vehicle })
		notify(source,"verde","Veiculo liberado.")
		return response(true,plate)
	end

	return response(false,plate,"Saldo insuficiente.")
end