if Config.Framework ~= "standalone" then
    return
end

---@param source number
---@return VehicleData[] vehicles # An array of vehicles that the player owns. You can view the data in lb-phone/server/apps/framework/garage.lua
function GetPlayerVehicles(source)
    local source = source 
    local Passport = vRP.Passport(source)
    if not Passport then 
        return {}
    end

    local Vehicles = {}
    local Query = exports["oxmysql"]:query_async("SELECT Vehicle,Plate,Engine,Body,Health,Fuel FROM vehicles WHERE Passport = @Id",{ Id = Passport })
    for _, v in pairs(Query) do 
        table.insert(Vehicles,{
            plate = v.Plate,
            type = v.Vehicle,
            model = v.Vehicle,
            location = exports["garages"]:Signal(v.Plate) and "out" or "Garage",
            statistics = {
                engine = v.Engine or 1000.0,
                body = v.Body or 1000.0,
                health = v.Health or 1000.0,
                fuel = v.Fuel or 100.0
            }
        })
    end

    return Vehicles
end

---@param source number
---@param plate string
---@return table? vehicleData
function GetVehicle(source, plate)
    return nil
end