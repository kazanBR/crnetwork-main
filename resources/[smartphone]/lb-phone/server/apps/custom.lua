-- =====================================================
--  lb-phone · server/apps/custom.lua
--  Deobfuscated by Eazy Fxap
-- =====================================================

RegisterNetEvent("lb-phone:customApp", function(appName)
    local playerId = source
    local customApp = Config.CustomApps[appName]

    if customApp and customApp.onServerUse then
        customApp.onServerUse(playerId)
    end
end)
