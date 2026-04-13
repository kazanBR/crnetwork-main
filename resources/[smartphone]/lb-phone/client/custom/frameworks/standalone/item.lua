if Config.Framework ~= "standalone" then
    return
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("lb-phone")

---@param itemName string
---@return boolean
function HasItem(itemName)
    if not LocalPlayer["state"]["Active"] or IsPauseMenuActive() or LocalPlayer["state"]["Buttons"] or LocalPlayer["state"]["Commands"] or LocalPlayer["state"]["Handcuff"] or LocalPlayer["state"]["Cancel"] or IsPedReloading(Ped) then
        return false
    end

    return vSERVER.CheckPhone()
end