if Config.Framework ~= "standalone" then
    return
end

---@param source number
---@return string
function GetJob(source)
    local Passport = vRP.Passport(source)
    if Passport then
        return vRP.GetUserType(Passport,"Work")
    end

    return "Desempregado"
end

function Creative.GetJob()
    local source = source
    return GetJob(source)
end

---Get all players with a specific job (including offline players)
---@param job string
---@return { firstname: string, lastname: string, grade: string, number: string }[] employees
function GetAllEmployees(job)
    return {}
end

---Get all online players with a specific job
---@param job string
---@return number[] # An array of sources with this job
function GetEmployees(job)
    local Services = {}
    local Permissions = vRP.NumPermission(job)
    for Passport,Sources in pairs(Permissions) do
        Services[#Services + 1] = Sources
    end

    return Services
end

---Refresh all companies and update the open status
function RefreshCompanies()
    for i = 1, #Config.Companies.Services do
        local jobData = Config.Companies.Services[i]

        jobData.open = vRP.AmountService(jobData.job) > 0
    end
end