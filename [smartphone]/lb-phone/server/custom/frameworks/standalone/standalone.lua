if Config.Framework ~= "standalone" then
    return
end

function Creative.CheckPhone()
    local source = source
    local Passport = vRP.Passport(source)
    if Passport and not Player(source)["state"]["Cancel"] and not Player(source)["state"]["Buttons"] and vRP.ConsultItem(Passport,Config.Item.Name) then
        return true
    end
    local FullName = vRP.FullName(Passport) 
    TriggerClientEvent("Notify",source,"Atenção","Você não Possui um celular.","amarelo",5000)
    return false
end

function IsAdmin(source)
    local Passport = vRP.Passport(source)
    if Passport and vRP.HasPermission(Passport,"Admin") then
        return true
    end

    return false
end

---@param source number
---@return string | nil
function GetIdentifier(source)
    local Passport = vRP.Passport(source)
    if not Passport then return end 
    
    return tostring(Passport)
end

---@param identifier string
---@return number?
function GetSourceFromIdentifier(identifier)
    local players = GetPlayers()

    for i = 1, #players do
        if GetPlayerIdentifierByType(players[i], "steam") == identifier then
            ---@diagnostic disable-next-line: return-type-mismatch
            return players[i]
        end
    end
end

---@param source number
---@param itemName string
function HasItem(source, itemName)
    return true
end

---Get a player's character name
---@param source number
---@return string # Firstname
---@return string # Lastname
function GetCharacterName(source)
    local Passport = vRP.Passport(source)
    if Passport then
        return vRP.FullName(Passport),""
    end

    return "Individuo Indigente",""
end