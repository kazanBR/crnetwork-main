-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Permissions(Permission,Column)
	local Permissions = SplitOne(Permission)
	local Consult = exports.oxmysql:single_async("SELECT * FROM permissions WHERE Permission = @Permission LIMIT 1",{ Permission = Permissions })
	if not Consult then
		exports.oxmysql:query_async("INSERT INTO permissions (Permission) VALUES (@Permission)",{ Permission = Permissions })
	end

	local Default = {
		Members = 3,
		Experience = 0,
		Announces = 3,
		Premium = 0,
		Points = 0,
		Bank = 0,
		Tags = 3
	}

	return Consult and Consult[Column] or Default[Column] or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONSUPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PermissionsUpdate(Permission,Column,Mode,Amount)
	local Amount = parseInt(Amount)
	local Permissions = SplitOne(Permission)

	local Consult = exports.oxmysql:single_async("SELECT * FROM permissions WHERE Permission = @Permission LIMIT 1", { Permission = Permissions })
	if not Consult then
		exports.oxmysql:query_async("INSERT INTO permissions (Permission) VALUES (@Permission)", { Permission = Permissions })
	end

	if not Contains({ "Members","Announces","Tags","Experience","Premium","Points","Bank" },Column) then
		return
	end

	if Column == "Premium" then
		exports.oxmysql:update_async("UPDATE permissions SET Premium = CASE WHEN Premium > UNIX_TIMESTAMP() THEN Premium + @Amount ELSE UNIX_TIMESTAMP() + @Amount END WHERE Permission = @Permission",{ Permission = Permissions, Amount = Amount })
	else
		local Operation = Mode == "+" and "+" or "-"
		local Query = string.format("UPDATE permissions SET %s = GREATEST(%s %s @Amount,0) WHERE Permission = @Permission",Column,Column,Operation)
		exports.oxmysql:query_async(Query,{ Permission = Permissions, Amount = Amount })
	end
end