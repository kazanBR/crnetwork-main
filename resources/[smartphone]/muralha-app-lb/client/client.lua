local Proxy = module('vrp', 'lib/Proxy')
local Tunnel = module('vrp', 'lib/Tunnel')
local vRP = Proxy.getInterface('vRP')
local Server = Tunnel.getInterface('muralha-app')

CreateThread(function()
    exports['lb-phone']:AddCustomApp({
        identifier = 'muralha',
        name = 'Muralha Connect',
        description = 'Consciência situacional de alarmes para a Polícia.',
        developer = 'Vasco',
        defaultApp = false,
        fixBlur = true,
        size = 21700,
        ui = GetCurrentResourceName() .. '/web/index.html',
        icon = 'https://cdn2.igorcalabraro.com.br/smartphone/muralha.png',
    })
end)

local PoliceStates = {
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

local function hasLocalPoliceState()
    for _, State in pairs(PoliceStates) do
        if LocalPlayer.state[State] then
            return true,State
        end
    end

    return false,false
end

RegisterNUICallback('login', function(data, cb)
    local Response = Server.login()
    print("[muralha-app] Login response: "..json.encode(Response or {}))

    if Response and Response.status == "authorized" then
        cb(Response)
        return
    end

    local HasState,State = hasLocalPoliceState()
    if HasState then
        cb({ status = "authorized", group = State, source = "client-state" })
        return
    end

    cb(Response or { status = "unauthorized" })
end)

RegisterNUICallback('getVehicle', function(data, cb)
    if data.plate then
        cb(Server.getVehicle(data.plate))
    else
        cb({ validPlate = false })
    end
end)

RegisterNUICallback('getWeapon', function(data, cb)
    if data.serial then
        cb(Server.getWeapon(data.serial))
    else
        cb({ validSerial = false })
    end
end)

RegisterNUICallback('getIdentity', function(data, cb)
    if data.identity then
        cb(Server.getIdentity(data.identity))
    else
        cb({ validIdentity = false })
    end
end)

RegisterNUICallback("getDetran", function (data, cb)
    if data.identity then
        cb(Server.getDetran(data.identity))
    else
        cb({ validIdentity = false })
    end
end)

RegisterNUICallback('setMap', function(data, cb)
    SetNewWaypoint(data.x, data.y)
    cb(true)
end)

RegisterNUICallback('callPhone', function(data, cb)
    exports['lb-phone']:CreateCall({ number = data.phone })
    cb(true)
end)

RegisterNUICallback('getBodycamOfficers', function(_, cb)
    local pedCoords = GetEntityCoords(PlayerPedId())
    cb({ officers = Server.getBodycamOfficers(), myselfLocation = { x = pedCoords.x, y = pedCoords.y } })
end)

RegisterNUICallback('requestVideoPreview', function(data, cb)
    if data.officerId then
        cb(Server.requestVideoPreview(data.officerId))
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('getWanteds', function(_, cb)
    cb(Server.getWanteds())
end)
