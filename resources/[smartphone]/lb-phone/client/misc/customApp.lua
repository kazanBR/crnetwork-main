-- Converts a raw CustomApps config entry into the shape expected by the React UI.
function FormatCustomAppDataForUI(appData)
    return {
        identifier               = appData.identifier,
        resourceName             = appData.resourceName,
        custom                   = true,
        name                     = appData.name,
        icon                     = appData.icon,
        description              = appData.description,
        images                   = appData.images,
        developer                = appData.developer,
        size                     = appData.size or 42000,
        price                    = appData.price,
        game                     = appData.game,
        landscape                = appData.landscape or false,
        removable                = not appData.defaultApp,
        disableInAppNotifications = appData.disableInAppNotifications,
        ui                       = appData.ui,
        fixBlur                  = appData.fixBlur,
        access                   = HasAccessToApp(appData.identifier),
    }
end

-- ─── SendCustomAppMessage ──────────────────────────────────────────────────────
-- Sends a message to a custom app's NUI iframe.
-- Only the resource that registered the app may send messages to it.
exports("SendCustomAppMessage", function(identifier, message)
    local callerResource = GetInvokingResource()

    if not identifier then
        infoprint("error", "SendCustomAppMessage: No identifier provided by resource " .. callerResource)
        return false, "No identifier provided"
    end

    if not Config.CustomApps[identifier] then
        infoprint("error", "SendCustomAppMessage: App " .. identifier .. " does not exist. Triggered by: " .. callerResource)
        return false, "App does not exist"
    end

    if Config.CustomApps[identifier].resourceName ~= callerResource then
        infoprint("error", "SendCustomAppMessage: App " .. identifier .. " was not created by " .. callerResource)
        return false, "App was not created by " .. callerResource
    end

    SendReactMessage("customApp:sendMessage", { identifier = identifier, message = message })
    return true
end)

-- ─── AddCustomApp ──────────────────────────────────────────────────────────────
-- Registers a new custom app at runtime, making it available in the phone UI.
-- The calling resource is recorded as the app's owner.
exports("AddCustomApp", function(appData)
    local callerResource = GetInvokingResource()

    if not (appData and appData.identifier) then
        return false, "No identifier provided"
    end
    if not appData.name then
        return false, "No name provided"
    end
    if not appData.description then
        return false, "No description provided"
    end

    if Config.CustomApps[appData.identifier] then
        return false, "App already exists"
    end

    -- Store the full app definition (including server-side callbacks) in config
    Config.CustomApps[appData.identifier] = {
        identifier               = appData.identifier,
        resourceName             = callerResource,
        custom                   = true,
        name                     = appData.name,
        icon                     = appData.icon,
        description              = appData.description,
        images                   = appData.images,
        developer                = appData.developer,
        size                     = appData.size or 42000,
        price                    = appData.price,
        game                     = appData.game,
        landscape                = appData.landscape or false,
        removable                = not appData.defaultApp,
        defaultApp               = appData.defaultApp,
        disableInAppNotifications = appData.disableInAppNotifications,
        ui                       = appData.ui,
        fixBlur                  = appData.fixBlur,
        onOpen                   = appData.onOpen,
        onClose                  = appData.onClose,
        onUse                    = appData.onUse,
        onDelete                 = appData.onDelete,
        onInstall                = appData.onInstall,
    }

    debugprint("adding custom app", appData.identifier)
    SendReactMessage("addCustomApp", FormatCustomAppDataForUI(Config.CustomApps[appData.identifier]))
    return true
end)

-- ─── RemoveCustomApp ───────────────────────────────────────────────────────────
-- Unregisters a custom app and removes it from the phone UI.
-- Only the resource that originally registered the app may remove it.
exports("RemoveCustomApp", function(identifier)
    local callerResource = GetInvokingResource()

    if not identifier then
        return false, "No identifier provided"
    end

    if not Config.CustomApps[identifier] then
        return false, "App does not exist"
    end

    if Config.CustomApps[identifier].resourceName ~= callerResource then
        return false, "App was not created by " .. callerResource
    end

    Config.CustomApps[identifier] = nil
    SendReactMessage("removeCustomApp", identifier)
    return true
end)

-- ─── onResourceStop ────────────────────────────────────────────────────────────
-- Automatically removes all custom apps registered by a resource when it stops.
AddEventHandler("onResourceStop", function(stoppedResource)
    for identifier, appData in pairs(Config.CustomApps) do
        if appData.resourceName == stoppedResource then
            Config.CustomApps[identifier] = nil
            SendReactMessage("removeCustomApp", identifier)
            debugprint("Removed app " .. identifier .. " due to resource stopping")
        end
    end
end)