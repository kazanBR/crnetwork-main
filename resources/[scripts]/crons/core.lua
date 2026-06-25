-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Crons = {}
local SavePending = false
local Archive = "config.json"
local Resource = GetCurrentResourceName()
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVE
-----------------------------------------------------------------------------------------------------------------------------------------
local function SaveCrons()
	if SavePending then
		return false
	end

	SavePending = true

	SetTimeout(1000,function()
		local Clean = {}
		for Number = 1,#Crons do
			local v = Crons[Number]
			if v then
				Clean[#Clean + 1] = v
			end
		end

		Crons = Clean
		SaveResourceFile(Resource,Archive,json.encode(Crons,{ indent = true }),-1)
		SavePending = false
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FIND CRON
-----------------------------------------------------------------------------------------------------------------------------------------
local function FindCron(Passport,Mode,Params)
	if not Params or not next(Params) then
		return false
	end

	local PassportParsed = parseInt(Passport)

	for Index,v in ipairs(Crons) do
		if v and v.Passport == PassportParsed and v.Mode == Mode and type(v.Params) == "table" then
			if (Mode == "SetPermission" or Mode == "RemovePermission" or Mode == "WipePermission") and Params.Permission and v.Params.Permission == Params.Permission then
				return Index,v
			elseif Mode == "RemoveVehicle" and Params.Model and v.Params.Model == Params.Model then
				return Index,v
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSERT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Insert",function(Passport,Mode,Seconds,Params)
	if not Passport or not Mode or not Seconds then
		return false
	end

	local Params = Params or {}
	local CurrentTimer = os.time()
	local PassportParsed = parseInt(Passport)
	local Index,Data = FindCron(PassportParsed,Mode,Params)

	if Data then
		if Data.Timer <= CurrentTimer then
			Data.Timer = CurrentTimer + Seconds
		else
			Data.Timer = Data.Timer + Seconds
		end

		SaveCrons()

		return math.max(0,(Data.Timer - CurrentTimer) - 1)
	end

	Crons[#Crons + 1] = {
		Mode = Mode,
		Passport = PassportParsed,
		Timer = CurrentTimer + Seconds,
		Params = Params or {}
	}

	SaveCrons()

	return Seconds
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Remove",function(Passport,Mode,Permission)
	local PassportParsed = parseInt(Passport)
	for _,v in ipairs(Crons) do
		if v.Passport == PassportParsed and v.Mode == Mode and v.Params and v.Params.Permission == Permission then
			v.Timer = os.time()
			break
		end
	end

	SaveCrons()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SWAP
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Swap",function(Passport,OtherPassport)
	local PassportParsed = parseInt(Passport)
	local OtherPassport = parseInt(OtherPassport)

	for _,v in ipairs(Crons) do
		if v.Passport == PassportParsed then
			v.Passport = OtherPassport
		end
	end

	SaveCrons()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Check",function(Passport,Mode,Params)
	if not Params or not next(Params) then
		return false
	end

	local CurrentTimer = os.time()
	local PassportParsed = parseInt(Passport)

	for _,v in ipairs(Crons) do
		if v and v.Passport == PassportParsed and v.Mode == Mode and v.Timer >= CurrentTimer and v.Params and Params.Permission and v.Params.Permission == Params.Permission then
			local Level = v.Params.Level or 1
			if not vRP.HasPermission(PassportParsed,v.Params.Permission,Level) then
				vRP.SetPermission(PassportParsed,v.Params.Permission,Level)
			end

			return (v.Timer - CurrentTimer)
		end
	end

	return false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXECUTOR
-----------------------------------------------------------------------------------------------------------------------------------------
local function ExecuteCron(v)
	local Mode = v.Mode
	local Params = v.Params or {}
	local Passport = v.Passport and parseInt(v.Passport) or 0

	if Mode == "SetPermission" and Passport > 0 and Params.Permission then
		if not vRP.HasPermission(Passport,Params.Permission) then
			vRP.SetPermission(Passport,Params.Permission,Params.Level or 1)
		end

		exports.discord:Embed("Crons","**[CRON]:** "..Mode.."\n**[PASSAPORTE]:** "..Passport.."\n**[PERMISSION]:** "..Params.Permission)
	elseif Mode == "RemovePermission" and Passport > 0 and Params.Permission then
		if vRP.HasPermission(Passport,Params.Permission) then
			vRP.RemovePermission(Passport,Params.Permission)
		end

		exports.discord:Embed("Crons","**[CRON]:** "..Mode.."\n**[PASSAPORTE]:** "..Passport.."\n**[PERMISSION]:** "..Params.Permission)
	elseif Mode == "WipePermission" and Params.Permission then
		local Consult = exports.oxmysql:query_async("SELECT * FROM chests")
		for _,Chest in pairs(Consult) do
			if SplitOne(Chest.Permission) == Params.Permission then
				vRP.RemSrvData("Chest:"..Chest.Name)
				exports.oxmysql:query_async("DELETE FROM chests WHERE id = ?",{ Chest.id })
			end
		end

		vRP.RemSrvData("Permissions:"..Params.Permission)
		exports.oxmysql:query_async("DELETE FROM permissions WHERE Permission = ?",{ Params.Permission })

		exports.discord:Embed("Crons","**[CRON]:** "..Mode.."\n**[PASSAPORTE]:** "..Passport.."\n**[PERMISSION]:** "..Params.Permission)
	elseif Mode == "RemoveVehicle" and Passport > 0 and Params.Model then
		vRP.RemSrvData("LsCustoms:"..Passport..":"..Params.Model)
		vRP.RemSrvData("Trunkchest:"..Passport..":"..Params.Model)
		exports.oxmysql:query_async("DELETE FROM vehicles WHERE Passport = ? AND Vehicle = ?",{ Passport,Params.Model })

		exports.discord:Embed("Crons","**[CRON]:** "..Mode.."\n**[PASSAPORTE]:** "..Passport.."\n**[MODEL]:** "..Params.Model)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Clean = {}
	local CurrentTimer = os.time()
	local Data = LoadResourceFile(Resource,Archive)
	local Decoded = Data and json.decode(Data) or {}

	for Number = 1,#Decoded do
		local v = Decoded[Number]
		if v and v.Timer then
			if v.Timer and v.Timer <= CurrentTimer then
				ExecuteCron(v)
			else
				Clean[#Clean + 1] = v
			end
		end
	end

	Crons = Clean
	SaveResourceFile(Resource,Archive,json.encode(Crons,{ indent = true }),-1)

	while true do
		local Updated = false
		local CurrentTimer = os.time()

		for Number = #Crons,1,-1 do
			local v = Crons[Number]
			if v and v.Timer and v.Timer <= CurrentTimer then
				ExecuteCron(v)
				table.remove(Crons,Number)
				Updated = true
			end
		end

		if Updated then
			SaveCrons()
		end

		Wait(30000)
	end
end)