RegisterNetEvent("lb-phone:customApp")
AddEventHandler("lb-phone:customApp", function(appName)
    local playerId = source
    local appConfig = Config.CustomApps[appName]

    if appConfig and appConfig.onServerUse then
        appConfig.onServerUse(playerId)
    end
end)