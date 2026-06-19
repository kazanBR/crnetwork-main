local function waitForPhone()
    while GetResourceState('lb-phone') ~= 'started' do
        Wait(1000)
    end
end

local function addApp()
    waitForPhone()

    local app = Config.App or {}
    local added, errorMessage = exports['lb-phone']:AddCustomApp({
        identifier = identifier,
        name = app.name or 'VIP Store',
        description = app.description or 'Loja VIP por diamantes',
        developer = app.developer or 'zVegas',
        defaultApp = app.defaultApp ~= false,
        size = app.size or 37600,
        ui = GetCurrentResourceName() .. '/web/index.html',
        icon = 'https://cfx-nui-' .. GetCurrentResourceName() .. '/web/assets/icon.svg',
        fixBlur = true
    })

    if not added then
        print(('[phone-vipstore] Falha ao registrar app no lb-phone: %s'):format(errorMessage or 'erro desconhecido'))
    end
end

CreateThread(addApp)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'lb-phone' then
        addApp()
    end
end)

local function notify(title, content)
    exports['lb-phone']:SendNotification({
        app = identifier,
        title = title,
        content = content
    })
end

RegisterNetEvent('phone-vipstore:notify', function(title, content)
    notify(title or 'VIP Store', content or '')
end)

RegisterNUICallback('getData', function(data, cb)
    cb(vSERVER.getData())
end)

RegisterNUICallback('buyItem', function(data, cb)
    cb(vSERVER.buyItem(data))
end)

RegisterNUICallback('redeemPending', function(data, cb)
    cb(vSERVER.redeemPending(data))
end)

RegisterNUICallback('redeemAll', function(data, cb)
    cb(vSERVER.redeemAll())
end)
