
local addApp = function()
  while (GetResourceState('lb-phone') ~= 'started') do Citizen.Wait(1000); end;

  local added, errorMessage = exports['lb-phone']:AddCustomApp({
    identifier = identifier,

    name = 'Weazel News',
    description = 'Cobertura, anúncios e notícias oficiais da cidade.',
    developer = 'Legado City',

    defaultApp = false, 
    size = 59812,
    ui = GetCurrentResourceName()..'/web/index.html',

    icon = 'https://cfx-nui-'..GetCurrentResourceName()..'/web/assets/icon.png',

    fixBlur = true
  })
end

addApp()

AddEventHandler('onResourceStart', function(resource)
  if (resource == 'lb-phone') then
    addApp(); 
  end
end)

RegisterNUICallback('createPost', function(data, cb)
  cb( vSERVER.createPost(data) )
end)

RegisterNUICallback('editPost', function(data, cb)
  cb( vSERVER.editPost(data) )
end)

RegisterNUICallback('deletePost', function(data, cb)
  cb( vSERVER.deletePost(data) )
end)

RegisterNUICallback('setVisualization', function(data, cb)
  vSERVER.setVisualization(data.id)

  cb('Ok')
end)

RegisterNUICallback('getNews', function(data, cb)
  cb( vSERVER.getNews() )
end)

RegisterNUICallback('hasPermission', function(data, cb)
  cb( vSERVER.hasPermission() )
end)
