local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")

local Server = {}
Tunnel.bindInterface("muralha-app",Server)

local function query(sql,params)
	local ok,result = pcall(function()
		return exports.oxmysql:query_async(sql,params or {})
	end)

	if ok and type(result) == "table" then
		return result
	end

	return {}
end

local function identity(Passport)
	return vRP.Identity(parseInt(Passport)) or {}
end

local function fullNameFromIdentity(Passport)
	local Identity = identity(Passport)
	return (Identity.name or Identity.Name or "Passaporte").." "..(Identity.name2 or Identity.Lastname or tostring(Passport))
end

local function fullName(row)
	if not row then
		return "Desconhecido"
	end

	return tostring(row.name or row.Name or "Passaporte").." "..tostring(row.name2 or row.Lastname or row.lastname or row.id or "")
end

local function phone(row,Passport)
	local Identity = Passport and identity(Passport) or {}
	return tostring(row and (row.phone or row.Phone) or Identity.phone or Identity.Phone or "Desconhecido")
end

local function licenseCategories(Passport)
	local Data = vRP.UserData(Passport,"Driverlicense") or {}
	local Categories = {}

	for Key,Value in pairs(Data.categories or {}) do
		if type(Key) == "number" then
			Categories[#Categories + 1] = tostring(Value)
		elseif Value then
			Categories[#Categories + 1] = tostring(Key)
		end
	end

	table.sort(Categories)
	return Categories
end

local AuthorizedGroups = {
	"Admin",
	"Policia",
	"Pmesp",
	"Pcesp",
	"Pf",
	"SSP",
	"Prf",
	"Bprv",
	"Gcm",
	"Detran",
	"Rota",
	"Anchieta",
	"Humaita",
	"Cptran",
	"Sap",
	"Ft",
	"Baep",
	"Caep",
	"CAvPM",
	"Coe/Gate",
	"3BPCHQ"
}

local function accessGroup(Passport)
	if not Passport then
		return false
	end

	for _,Group in pairs(AuthorizedGroups) do
		if vRP.HasGroup(Passport,Group) or vRP.HasPermission(Passport,Group) or vRP.HasService(Passport,Group) then
			return Group
		end
	end

	local TypeGroup = vRP.GetUserType(Passport,"Policia")
	if TypeGroup and TypeGroup ~= "Bombeiro" then
		return TypeGroup
	end

	return false
end

function Server.login()
	local Passport = vRP.Passport(source)
	local Group = accessGroup(Passport)

	if not Group then
		print(("[muralha-app] Acesso negado source=%s passport=%s stateCheck=server."):format(source,tostring(Passport)))
		return { status = "unauthorized", passport = Passport }
	end

	print(("[muralha-app] Acesso liberado source=%s passport=%s group=%s."):format(source,tostring(Passport),tostring(Group)))
	return {
		status = "authorized",
		id = Passport,
		name = fullNameFromIdentity(Passport),
		group = Group
	}
end
local function personById(Passport)
	local Rows = query([[SELECT id,name,name2,phone,sex,blood,age,prison FROM characters WHERE id = @Passport LIMIT 1]],{ Passport = parseInt(Passport) })
	return Rows[1]
end

local function wanted(Passport,row)
	row = row or personById(Passport)
	return parseInt(row and row.prison or 0) > 0
end

local function personPayload(row)
	if not row then
		return nil
	end

	local Passport = parseInt(row.id)
	local Fines = vRP.Query("fines/List",{ Passport = Passport }) or {}
	local History = {}

	for _,Fine in ipairs(Fines) do
		History[#History + 1] = {
			fine = parseInt(Fine.Value or 0),
			reason = Fine.Message or "Registro",
			created_at = os.time(),
			arrest_time = 0
		}
	end

	return {
		id = Passport,
		user_id = Passport,
		name = fullName(row),
		phone = phone(row,Passport),
		age = parseInt(row.age or 20),
		gender = row.sex == "F" and "Feminino" or "Masculino",
		blood = tostring(row.blood or "1"),
		gun_license = false,
		wanted = { status = wanted(Passport,row), reason = wanted(Passport,row) and "Prisao ativa" or nil },
		criminal_history = History
	}
end

local function vehicleRowsByPlate(plate)
	return query([[
		SELECT v.*, c.id, c.name, c.name2, c.phone, c.prison
		FROM vehicles v
		LEFT JOIN characters c ON c.id = v.Passport
		WHERE v.plate = @Plate
		LIMIT 1
	]],{ Plate = tostring(plate or "") })
end

function Server.getVehicle(plate)
	local Row = vehicleRowsByPlate(plate)[1]
	if not Row then
		return { validPlate = false, customErrorMessage = "Placa invalida" }
	end

	local Owner = parseInt(Row.Passport or Row.id or 0)
	return {
		validPlate = true,
		vehicle = {
			ownerName = fullName(Row),
			ownerId = Owner,
			ownerPhone = phone(Row,Owner),
			ownerIsWanted = wanted(Owner,Row),
			vehicleModel = VehicleName(Row.vehicle) or Row.vehicle,
			vehiclePlate = Row.plate,
			vehicleTax = parseInt(Row.tax or 0),
			isVehicleApprehended = parseInt(Row.arrest or 0) > os.time(),
			isVehicleStolen = false
		}
	}
end

function Server.getWeapon(serial)
	return { validSerial = false, customErrorMessage = "Registro nao encontrado" }
end

function Server.getIdentity(identityId)
	local Row = personById(identityId)
	if not Row then
		return { validIdentity = false, customErrorMessage = "RG invalido" }
	end

	return { validIdentity = true, identity = personPayload(Row) }
end

function Server.getDetran(identityId)
	local Row = personById(identityId)
	if not Row then
		return { validIdentity = false, customErrorMessage = "RG invalido" }
	end

	local Passport = parseInt(Row.id)
	local Vehicles = {}
	for _,Vehicle in pairs(vRP.Query("vehicles/UserVehicles",{ Passport = Passport }) or {}) do
		Vehicles[#Vehicles + 1] = {
			model = VehicleName(Vehicle.vehicle) or Vehicle.vehicle,
			plate = Vehicle.plate
		}
	end

	local Payload = personPayload(Row)
	Payload.cnh = licenseCategories(Passport)
	Payload.vehicles = Vehicles
	return { validIdentity = true, identity = Payload }
end

function Server.getBodycamOfficers()
	local Officers = {}
	local Services = vRP.NumPermission("Policia")

	for Passport,TargetSource in pairs(Services or {}) do
		if TargetSource and TargetSource > 0 then
			local Ped = GetPlayerPed(TargetSource)
			local Coords = Ped and GetEntityCoords(Ped) or vector3(0.0,0.0,0.0)
			Officers[#Officers + 1] = {
				id = parseInt(Passport),
				name = fullNameFromIdentity(Passport),
				phone = phone(nil,Passport),
				location = { x = Coords.x, y = Coords.y, z = Coords.z },
				timeInService = os.time()
			}
		end
	end

	return Officers
end

function Server.requestVideoPreview(officerId)
	return { success = false }
end

function Server.getWanteds()
	local Rows = query([[SELECT id,name,name2 FROM characters WHERE deleted = 0 AND prison > 0 ORDER BY prison DESC LIMIT 20]])
	local Wanteds = {}

	for _,Row in ipairs(Rows) do
		Wanteds[#Wanteds + 1] = {
			id = parseInt(Row.id),
			name = fullName(Row),
			image = ""
		}
	end

	return Wanteds
end