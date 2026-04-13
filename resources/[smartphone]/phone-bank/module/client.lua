local addApp = function()
    while (GetResourceState('lb-phone') ~= 'started') do Citizen.Wait(1000); end;

    local added, errorMessage = exports['lb-phone']:AddCustomApp({
        identifier = identifier,

        name = 'Capital Bank',
        description = 'Banco digital',
        developer = 'Grupo Capital',

        defaultApp = false, 
        size = 59812,

        images = { -- OPTIONAL array of screenshots of the app, used for showcasing the app
            'https://cfx-nui-'..GetCurrentResourceName()..'/web/assets/image.png',
            'https://cfx-nui-'..GetCurrentResourceName()..'/web/assets/image2.png',
            'https://cfx-nui-'..GetCurrentResourceName()..'/web/assets/image3.png'
        },

        ui = GetCurrentResourceName()..'/web/index.html',

        icon = 'https://cfx-nui-'..GetCurrentResourceName()..'/web/assets/icon.png',

        fixBlur = true -- set to true if you use em, rem etc instead of px in your css
    })
end

addApp()

AddEventHandler('onResourceStart', function(resource)
    if (resource == 'lb-phone') then
        addApp(); 
    end
end)

--=============================================================
-- Callback's
--=============================================================
RegisterNUICallback('getReceiver', function(data, cb) cb(vSERVER.getReceiver(data)); end)
RegisterNUICallback('getUser', function(data, cb) cb(vSERVER.getUser()); end)
RegisterNUICallback('sendMoney', function(data, cb) cb(vSERVER.sendMoney(data)); end)
RegisterNUICallback('payFine', function(data, cb) cb(vSERVER.payFine(data)); end)
RegisterNUICallback('Pix', function(data, cb) cb(vSERVER.Pix(data)); end)