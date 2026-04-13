if Config.Framework ~= "standalone" then
    return
end

---Get the bank balance of a player
---@param source number
---@return integer
function GetBalance(source)
    local Passport = vRP.Passport(source)
    if Passport then
        return vRP.GetBank(Passport)
    end

    return 0
end

---Add money to a player's bank account
---@param source number
---@param amount integer
---@return boolean success
function AddMoney(source, amount)
    local Passport = vRP.Passport(source)
    if Passport then
        vRP.GiveBank(Passport,amount)

        return true
    end

    return false
end

---@param identifier string
---@param amount number
---@return boolean success
function AddMoneyOffline(identifier, amount)
    return false
end

---Remove money from a player's bank account
---@param source number
---@param amount integer
---@return boolean success
function RemoveMoney(source, amount)
    local Passport = vRP.Passport(source)
    if Passport and vRP.PaymentBank(Passport,amount) then
        return true
    end

    return false
end