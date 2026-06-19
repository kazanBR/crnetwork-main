local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")

local Server = {}
Tunnel.bindInterface(GetCurrentResourceName(),Server)

local dataKey = "rifa-app-lb:Data"
local state = vRP.GetSrvData(dataKey,true)
state.raffles = state.raffles or {}
state.winners = state.winners or {}
state.nextId = state.nextId or 0

local function save()
	vRP.SetSrvData(dataKey,state,true)
end

local function fullName(Passport)
	local Identity = vRP.Identity(Passport) or {}
	return (Identity.name or Identity.Name or "Passaporte").." "..(Identity.name2 or Identity.Lastname or tostring(Passport))
end

local function vehicleByPlate(plate)
	local result = vRP.Query("vehicles/plateVehicles",{ plate = tostring(plate or "") })
	return result and result[1]
end

local function raffleList()
	local list = {}
	for _,raffle in pairs(state.raffles) do
		list[#list + 1] = raffle
	end
	table.sort(list,function(a,b) return a.id < b.id end)
	return list
end

function Server.loadData()
	local Passport = vRP.Passport(source)
	return {
		active = raffleList(),
		user = {
			id = Passport,
			name = Passport and fullName(Passport) or ""
		}
	}
end

function Server.GetVehicles()
	local Passport = vRP.Passport(source)
	local list = {}
	if not Passport then
		return list
	end

	for _,row in pairs(vRP.Query("vehicles/UserVehicles",{ Passport = Passport }) or {}) do
		list[#list + 1] = {
			model = row.vehicle,
			name = VehicleName(row.vehicle) or row.vehicle,
			plate = row.plate,
			status = "Regular",
			canRaffle = true
		}
	end

	return list
end

function Server.createRaffle(payload)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or type(payload) ~= "table" then
		return false
	end

	local plate = tostring(payload.plate or "")
	local row = vehicleByPlate(plate)
	if not row or parseInt(row.Passport) ~= parseInt(Passport) then
		TriggerClientEvent("Notify",source,"vermelho","Veiculo invalido.",5000)
		return false
	end

	state.nextId = parseInt(state.nextId) + 1
	state.raffles[tostring(state.nextId)] = {
		id = state.nextId,
		passport = Passport,
		owner = Passport,
		vehicle = row.vehicle,
		vehicle_name = payload.name or VehicleName(row.vehicle) or row.vehicle,
		plate = row.plate,
		image_url = payload.image or "",
		price = parseInt(payload.price),
		total_tickets = math.max(1,parseInt(payload.total)),
		sold_tickets = 0,
		tickets = {},
		created_at = os.date("%d/%m/%Y")
	}

	save()
	return true
end

function Server.buyTicket(payload)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or type(payload) ~= "table" then
		return { success = false, msg = "Usuario invalido." }
	end

	local raffle = state.raffles[tostring(payload.id)]
	if not raffle then
		return { success = false, msg = "Rifa indisponivel." }
	end

	local quantity = math.max(1,parseInt(payload.quantity or 1))
	local free = {}
	local used = {}
	for _,ticket in ipairs(raffle.tickets) do
		used[parseInt(ticket.number)] = true
	end
	for number = 1,parseInt(raffle.total_tickets) do
		if not used[number] then
			free[#free + 1] = number
		end
	end

	if #free < quantity then
		return { success = false, msg = "Cotas insuficientes." }
	end

	local total = parseInt(raffle.price) * quantity
	if not vRP.PaymentFull(Passport,total,"Rifa") then
		return { success = false, msg = "Pagamento recusado." }
	end

	local numbers = {}
	for i = 1,quantity do
		local number = table.remove(free,math.random(#free))
		numbers[#numbers + 1] = number
		raffle.tickets[#raffle.tickets + 1] = {
			passport = Passport,
			number = number,
			status = "paid"
		}
	end
	raffle.sold_tickets = #raffle.tickets

	if raffle.sold_tickets >= parseInt(raffle.total_tickets) then
		local winnerTicket = raffle.tickets[math.random(#raffle.tickets)]
		local row = vehicleByPlate(raffle.plate)
		if row then
			vRP.Query("vehicles/moveVehicles",{ Passport = raffle.owner, OtherPassport = winnerTicket.passport, vehicle = raffle.vehicle })
		end
		vRP.GiveBank(raffle.owner,parseInt(raffle.price) * parseInt(raffle.total_tickets))
		state.winners[#state.winners + 1] = {
			id = raffle.id,
			name = raffle.vehicle_name,
			vehicle_name = raffle.vehicle_name,
			plate = raffle.plate,
			image_url = raffle.image_url,
			passport = winnerTicket.passport,
			winner_name = fullName(winnerTicket.passport),
			winner_number = winnerTicket.number,
			date = os.date("%d/%m/%Y")
		}
		state.raffles[tostring(raffle.id)] = nil
	end

	save()
	return { success = true, msg = "Compra aprovada.", numbers = numbers }
end

function Server.getWinners()
	return state.winners
end

function Server.getMyTickets()
	local Passport = vRP.Passport(source)
	local list = {}
	if not Passport then
		return list
	end

	for _,raffle in pairs(state.raffles) do
		for _,ticket in ipairs(raffle.tickets or {}) do
			if parseInt(ticket.passport) == parseInt(Passport) then
				list[#list + 1] = {
					raffle_id = raffle.id,
					number = ticket.number,
					status = ticket.status,
					vehicle_name = raffle.vehicle_name,
					plate = raffle.plate,
					image_url = raffle.image_url
				}
			end
		end
	end
	return list
end
