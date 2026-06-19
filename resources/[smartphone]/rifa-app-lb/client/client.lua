local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

-----------------------------------------------------------------------------------------------------------------------------------------
-- APP REGISTRATION
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    exports['lb-phone']:AddCustomApp({
        identifier = 'raffle-app',
        name = 'Rifas Pro',
        description = 'Marketplace de Veículos Verificados',
        developer = 'Ks Developments',
        defaultApp = true,
        fixBlur = true,
        size = 77700,
        ui = GetCurrentResourceName() .. '/web/index.html',
        icon = "nui://rifa-app-lb/web/assets/logo.png",
    })
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- NUI CALLBACKS
-----------------------------------------------------------------------------------------------------------------------------------------

RegisterNUICallback("loadData", function(data, cb)
    print("oi")
    cb(vSERVER.loadData())
end)

RegisterNUICallback("getMyVehicles", function(data, cb)
    cb(vSERVER.GetVehicles())
end)



RegisterNUICallback("createRaffle", function(data, cb)
    cb(vSERVER.createRaffle(data))
end)

RegisterNUICallback("buyTicket", function(data, cb)
    cb(vSERVER.buyTicket(data))
end)


RegisterNUICallback("getWinners", function(data, cb)
    cb(vSERVER.getWinners())
end)
RegisterNUICallback("getMyTickets", function(data, cb)
    cb(vSERVER.getMyTickets())
end)