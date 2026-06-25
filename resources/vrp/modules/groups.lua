-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Service = {}
local Playing = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- FORSERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
for Permission in pairs(Groups) do
	Service[Permission] = {}
	Playing[Permission] = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERSALARYS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserSalarys(Passport)
	local Valuation = 0
	for Permission,v in pairs(Groups) do
		local Salary = v.Salary
		if Salary then
			local Level = vRP.HasService(Passport,Permission)
			if Level then
				local Value = Salary[Level]
				if Value then
					Valuation = Valuation + Value
				end
			end
		end
	end

	return Valuation
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERGROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserGroups(Passport)
	local Result = {}
	for Permission in pairs(Groups) do
		local Level = vRP.HasPermission(Passport,Permission)
		if Level then
			Result[Permission] = Level
		end
	end

	return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DATAGROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DataGroups(Permission)
	local Table = vRP.GetSrvData("Permissions:"..Permission,true)
	return Table,CountTable(Table) or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AMOUNTGROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AmountGroups(Permission)
	local Amount = vRP.GetSrvData("Permissions:"..Permission,true)
	return CountTable(Amount) or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GROUPTYPE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GroupType(Permission)
	local Group = Groups[Permission]
	return Group and Group.Type or "UnWorked"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOOPPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.LoopPermission(Passport,Permission)
	local Group = Groups[Permission]
	if not Group or not Group.Permission then
		return false
	end

	for Parent in pairs(Group.Permission) do
		if vRP.HasPermission(Passport,Parent) then
			return Parent
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAINELBLOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PainelBlock(Permission)
	return Groups[Permission] and Groups[Permission].Block or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETUSERTYPE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetUserType(Passport,Type)
	local Passport = tostring(Passport)
	for Permission,v in pairs(Groups) do
		if v.Type == Type then
			local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
			if Consult and Consult[Passport] then
				return Permission
			end
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERDOMINATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserDomination(Passport)
	local Passport = tostring(Passport)
	for Permission,v in pairs(Groups) do
		if v.Domination then
			for Parent in pairs(v.Permission) do
				local Consult = vRP.GetSrvData("Permissions:"..Parent,true)
				if Consult and Consult[Passport] then
					return Permission
				end
			end
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Hierarchy(Permission)
	return Groups[Permission] and Groups[Permission].Hierarchy or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NAMEHIERARCHY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.NameHierarchy(Permission,Level)
	return Groups[Permission] and Groups[Permission].Hierarchy and Groups[Permission].Hierarchy[Level] or Permission
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NUMPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.NumPermission(Permission)
	local Table = {}
	if Groups[Permission] and Groups[Permission].Permission then
		for Parent in pairs(Groups[Permission].Permission) do
			if Service[Parent] then
				for Passport,source in pairs(Service[Parent]) do
					if source and Characters[source] and not Table[Passport] then
						Table[Passport] = source
					end
				end
			end
		end
	end

	return Table,CountTable(Table) or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NUMGROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.NumGroups(Permission)
	local Table = {}
	if Groups[Permission] and Groups[Permission].Permission then
		for Parent in pairs(Groups[Permission].Permission) do
			local Players = vRP.DataGroups(Parent)
			if Groups[Parent] and Players then
				for Passport,Level in pairs(Players) do
					if not Table[Passport] then
						Table[Passport] = { Level = Level, Permission = Parent }
					end
				end
			end
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AMOUNTSERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AmountService(Permission,Level)
	local PermissionParts = splitString(Permission,"-")
	if PermissionParts[2] then
		Permission,Level = PermissionParts[1],parseInt(PermissionParts[2])
	end

	local Table = {}
	if Groups[Permission] and Groups[Permission].Permission then
		for Parent in pairs(Groups[Permission].Permission) do
			if Service[Parent] then
				for Passport,source in pairs(Service[Parent]) do
					if source and Characters[source] and not Table[Passport] and (not Level or (Level and Level == vRP.HasPermission(Passport,Parent))) then
						Table[Passport] = true
					end
				end
			end
		end
	end

	return CountTable(Table) or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVICETOGGLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ServiceToggle(source,Passport,Permission,Silenced)
	if not Characters[source] then
		return false
	end

	if Groups[Permission] then
		local Passport = tostring(Passport)
		local Permission = SplitOne(Permission)
		if Service[Permission] and Service[Permission][Passport] then
			vRP.ServiceLeave(source,Passport,Permission,Silenced)
		elseif vRP.HasPermission(Passport,Permission) then
			vRP.ServiceEnter(source,Passport,Permission,Silenced)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVICEENTER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ServiceEnter(source,Passport,Permission,Silenced)
	if not source or not Passport or not Permission or not Characters[source] or not Groups[Permission] then
		return false
	end

	local CurrentTimer = os.time()
	local Passport = tostring(Passport)
	local Level = vRP.HasPermission(Passport,Permission)

	if not Playing[Permission] then
		Playing[Permission] = {}
	end

	Playing[Permission][Passport] = Playing[Permission][Passport] or CurrentTimer

	Player(source).state[Permission] = Level

	if Groups[Permission].Markers and Groups["Emergencia"].Permission[Permission] then
		Player(source).state.Markers = true
		exports.markers:Enter(source,Permission,Level)
	end

	if Service[Permission] then
		Service[Permission][Passport] = source
		TriggerClientEvent("service:Client",source,Permission,true)
	end

	if not Silenced then
		TriggerClientEvent("Notify",source,"Central de Empregos","Você acaba de dar inicio a sua jornada de trabalho, lembrando que a sua vida não se resume só a isso.","default",5000)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVICELEAVE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ServiceLeave(source,Passport,Permission,Silenced)
	if not Characters[source] or not Groups[Permission] then
		return false
	end

	local CurrentTimer = os.time()
	local Passport = tostring(Passport)

	Playing[Permission] = Playing[Permission] or {}
	if Playing[Permission][Passport] then
		local Consult = vRP.GetSrvData("Playing:"..Passport,true)
		local Timer = Playing[Permission][Passport] or CurrentTimer
		Consult[Permission] = (Consult[Permission] or 0) + (CurrentTimer - Timer)
		vRP.SetSrvData("Playing:"..Passport,Consult,true)

		Playing[Permission][Passport] = nil
	end

	Player(source).state[Permission] = nil

	if Groups[Permission].Markers then
		if Groups["Emergencia"].Permission[Permission] then
			Player(source).state.Markers = false
			exports.markers:Exit(source)
		end

		TriggerClientEvent("radio:Disconnect",source)
	end

	if Service[Permission] and Service[Permission][Passport] then
		TriggerClientEvent("service:Client",source,Permission,false)
		Service[Permission][Passport] = nil
	end

	if not Silenced then
		TriggerClientEvent("Notify",source,"Central de Empregos","Você acaba finalizar sua jornada de trabalho, esperamos que você tenha aprendido bastante hoje.","default",5000)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetPermission(Passport,Permission,Level,Mode)
	if not Groups[Permission] then
		return false
	end

	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
	local Hierarchy = Groups[Permission].Hierarchy and CountTable(Groups[Permission].Hierarchy) or 1

	local function Clamp(value,min,max)
		return math.min(math.max(value,min),max)
	end

	if Mode then
		local Adjustment = (Mode == "Demote") and 1 or -1
		local Current = Consult[Passport] or 1
		Consult[Passport] = Clamp(Current + Adjustment,1,Hierarchy)
	else
		if Level then
			Consult[Passport] = Clamp(parseInt(Level),1,Hierarchy)
		else
			Consult[Passport] = Hierarchy
		end
	end

	local Discord = vRP.DiscordGroups(Permission)
	local DiscordNumber = vRP.AccountInformation(Passport,"Discord")
	if DiscordBot and Discord and DiscordNumber and DiscordNumber ~= 0 then
		exports.discord:Content("Roles",DiscordNumber.." "..Discord.." Adicionar")
	end

	vRP.SetSrvData("Permissions:"..Permission,Consult,true)

	local source = vRP.Source(Passport)
	if source then
		vRP.ServiceEnter(source,Passport,Permission,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemovePermission(Passport,Permission)
	if not Groups[Permission] then
		return false
	end

	local Passport = tostring(Passport)
	if Service[Permission] and Service[Permission][Passport] then
		Service[Permission][Passport] = nil
	end

	local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
	if not Consult[Passport] then
		return false
	end

	local Discord = vRP.DiscordGroups(Permission)
	local DiscordNumber = vRP.AccountInformation(Passport,"Discord")
	if DiscordBot and Discord and DiscordNumber and DiscordNumber ~= 0 then
		exports.discord:Content("Roles",DiscordNumber.." "..Discord.." Remover")
	end

	Consult[Passport] = nil
	vRP.RemSrvData("Painel:Goals:"..Permission,true)
	vRP.SetSrvData("Permissions:"..Permission,Consult,true)
	vRP.RemSrvData("Goals:"..Permission..":"..Passport,true)

	local source = vRP.Source(Passport)
	if source then
		vRP.ServiceLeave(source,Passport,Permission,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.HasPermission(Passport,Permission,Level)
	if not Permission then
		return false
	end

	local PermissionParts = splitString(Permission)
	if PermissionParts[2] then
		Permission = PermissionParts[1]
		Level = parseInt(PermissionParts[2])
	end

	if not Groups[Permission] then
		return false
	end

	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
	local CurrentLevel = Consult[Passport]
	if not CurrentLevel then
		return false
	end

	if not Level or CurrentLevel <= Level then
		return CurrentLevel
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASTABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.HasTable(Passport,Table)
	local Passport = tostring(Passport)

	for _,Permission in ipairs(Table) do
		local PermissionParts = splitString(Permission)
		if PermissionParts[2] then
			PermissionName = PermissionParts[1]
			Level = parseInt(PermissionParts[2])
		end

		local Consult = vRP.GetSrvData("Permissions:"..PermissionName,true)
		local CurrentLevel = Consult[Passport]

		if CurrentLevel and (not Level or CurrentLevel <= Level) then
			return Permission
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASGROUP
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.HasGroup(Passport,Permission,Level)
	if not Passport or not Permission then
		return false
	end

	local PermissionParts = splitString(Permission)
	if PermissionParts[2] then
		Permission = PermissionParts[1]
		Level = parseInt(PermissionParts[2])
	end

	if not Groups[Permission] or not Groups[Permission].Permission then
		return false
	end

	local Passport = tostring(Passport)
	for Parent in pairs(Groups[Permission].Permission) do
		local Consult = vRP.GetSrvData("Permissions:"..Parent,true)
		local CurrentLevel = Consult[Passport]

		if CurrentLevel and (not Level or CurrentLevel <= Level) then
			return CurrentLevel
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASSERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.HasService(Passport,Permission,Level)
	local PermissionParts = splitString(Permission)
	if PermissionParts[2] then
		Permission = PermissionParts[1]
		Level = parseInt(PermissionParts[2])
	end

	if not Groups[Permission] or not Groups[Permission].Permission then
		return false
	end

	local Passport = tostring(Passport)
	for Parent in pairs(Groups[Permission].Permission) do
		local Consult = vRP.GetSrvData("Permissions:"..Parent,true)
		local CurrentLevel = Consult[Passport]

		if CurrentLevel and Service[Parent] and Service[Parent][Passport] and (not Level or CurrentLevel <= Level) then
			return CurrentLevel
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCORDGROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DiscordGroups(Permission)
	return Groups[Permission] and Groups[Permission].Discord or nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Playing(Passport,Permission)
	local CurrentTimer = os.time()
	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Playing:"..Passport,true)
	local Return = Consult[Permission] or 0

	Playing[Permission] = Playing[Permission] or {}
	if Playing[Permission] and Playing[Permission][Passport] then
		Return = Return + (CurrentTimer - Playing[Permission][Passport])
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WIPEPLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WipePlaying()
	for Permission in pairs(Groups) do
		Playing[Permission] = {}
	end

	local Consult = vRP.GetSrvDataGlobal()
	for Key in pairs(Consult) do
		if SplitOne(Key,":") == "Playing" then
			vRP.RemSrvData(Key,true)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LEAVESERVICEBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.LeaveServiceBanned(Passport,source)
	for Permission,v in pairs(Groups) do
		if v.Banned and vRP.HasService(Passport,Permission) then
			vRP.ServiceLeave(source,Passport,Permission,true)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source,First)
	local Passport = tostring(Passport)
	for Permission,v in pairs(Groups) do
		if v.Service and vRP.HasPermission(Passport,Permission) and Service[Permission] and (Service[Permission][Passport] == false or (First and Service[Permission][Passport] == nil)) then
			vRP.ServiceEnter(source,Passport,Permission,true)
		end
	end

	Playing.Online = Playing.Online or {}
	Playing.Online[Passport] = Playing.Online[Passport] or os.time()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if not Passport then
		return false
	end

	local CurrentTimer = os.time()
	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Playing:"..Passport,true)

	for Permission in pairs(Groups) do
		Playing[Permission] = Playing[Permission] or {}
		Playing[Permission][Passport] = Playing[Permission][Passport] or CurrentTimer
		Consult[Permission] = (Consult[Permission] or 0) + (CurrentTimer - Playing[Permission][Passport])
		Playing[Permission][Passport] = nil

		if Service[Permission] and Service[Permission][Passport] then
			Service[Permission][Passport] = false
		end
	end

	Playing.Online = Playing.Online or {}
	Playing.Online[Passport] = Playing.Online[Passport] or CurrentTimer
	Consult.Online = (Consult.Online or 0) + (CurrentTimer - Playing.Online[Passport])
	Playing.Online[Passport] = nil

	vRP.SetSrvData("Playing:"..Passport,Consult,true)
end)