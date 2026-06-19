function RegisterEvent(eventName, isNetworked, callback)
    if isNetworked then
        RegisterNetEvent(eventName, callback)
    else
        AddEventHandler(eventName, callback)
    end
end
