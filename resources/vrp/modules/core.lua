-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Sources = {}
Characters = {}
local Arena = {}
local Prepare = {}
local Weed = {}
local Alcohol = {}
local Chemical = {}
local Service = {}
local Entitys = {}
local Spawns = {}
local Objects = {}
local Weapons = {}
local Played = {}
local Default = { Free = 0, Premium = 0, Points = 0, Active = false }
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
Playing = {}
Playing.Online = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Prepare(Name,Query)
	Prepare[Name] = Query
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- QUERY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Query(Name,Params)
	return exports.oxmysql:query_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Update(Name,Params)
    return exports.oxmysql:update_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SINGLEQUERY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SingleQuery(Name,Params)
    return exports.oxmysql:single_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SCALAR
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Scalar(Name,Params)
	return exports.oxmysql:scalar_async(Prepare[Name],Params)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- IDENTITIES
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Identities(source)
	local Identities = GetPlayerIdentifierByType(source,BaseMode)

	return Identities and SplitTwo(Identities,":") or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHIVE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Archive(Archive,Text)
	local Message = LoadResourceFile("archives",Archive)
	SaveResourceFile("archives",Archive,(Message or "")..Text.."\n",-1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Account(License)
	return vRP.SingleQuery("accounts/Account",{ License = License })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCORD
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Discord(Discord)
	return vRP.SingleQuery("accounts/Discord",{ Discord = Discord })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNTINFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AccountInformation(Passport,Mode)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)
	if not Identity then return false end

	local Account = vRP.Account(Identity.License)
	return Account and Account[Mode] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCOUNTOPTIMIZE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AccountOptimize(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and vRP.Account(Identity.License) or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserData(Passport,Key)
	local Consult = vRP.SingleQuery("playerdata/GetData",{ Passport = Passport, Name = Key })

	return Consult and json.decode(Consult.Information) or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SIMPLEDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SimpleData(Passport,Key)
	local Consult = vRP.SingleQuery("playerdata/GetData",{ Passport = Passport, Name = Key })

	return Consult and json.decode(Consult.Information) or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSIDEPROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsidePropertys(Passport,Coords)
	local Datatable = vRP.Datatable(Passport)
	if Datatable then
		Datatable.Pos = Coords
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Inventory(Passport)
	local Datatable = vRP.Datatable(Passport)

	return Datatable and (Datatable.Inventory or {}) or {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVETEMPORARY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SaveTemporary(Passport,source,Table)
	if not Arena[Passport] then
		local Datatable = vRP.Datatable(Passport)
		if Datatable then
			local Route = Table.Route
			local Ped = GetPlayerPed(source)

			Arena[Passport] = {
				Inventory = Datatable.Inventory,
				Health = GetEntityHealth(Ped),
				Armour = GetPedArmour(Ped),
				Stress = Datatable.Stress,
				Hunger = Datatable.Hunger,
				Thirst = Datatable.Thirst,
				Pos = GetEntityCoords(Ped),
				Route = Route
			}

			vRP.Armour(source,100)
			Datatable.Inventory = {}
			vRPC.SetHealth(source,200)
			vRP.UpgradeHunger(Passport,100)
			vRP.UpgradeThirst(Passport,100)
			vRP.DowngradeStress(Passport,100)

			TriggerEvent("DebugWeapons",Passport)
			GlobalState["Arena:"..Route] = GlobalState["Arena:"..Route] + 1
			TriggerEvent("inventory:SaveArena",Passport,Table.Attachs,Table.Ammos)

			for Item,v in pairs(Table.Itens) do
				vRP.GenerateItem(Passport,Item,v.Amount,false,v.Slot)
			end

			exports["vrp"]:Bucket(source,"Enter",Route)
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- APPLYTEMPORARY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ApplyTemporary(Passport,source)
	if Arena[Passport] then
		local Route = Arena[Passport].Route
		local Datatable = vRP.Datatable(Passport)
		if Datatable then
			Datatable.Stress = Arena[Passport].Stress
			Datatable.Hunger = Arena[Passport].Hunger
			Datatable.Thirst = Arena[Passport].Thirst
			Datatable.Inventory = Arena[Passport].Inventory

			TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
			TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
			TriggerClientEvent("hud:Stress",source,Datatable.Stress)
		end

		vRP.Armour(source,Arena[Passport].Armour)
		vRPC.SetHealth(source,Arena[Passport].Health)
		GlobalState["Arena:"..Route] = GlobalState["Arena:"..Route] - 1
		TriggerEvent("inventory:ApplyArena",Passport)
		TriggerEvent("vRP:ReloadWeapons",source)
		exports["vrp"]:Bucket(source,"Exit")

		Arena[Passport] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SkinCharacter(Passport,Hash)
	vRP.Query("characters/SetSkin",{ Passport = Passport, Skin = Hash })

	local source = vRP.Source(Passport)
	if Characters[source] then
		Characters[source].Skin = Hash
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Passport(source)
	return Characters[source] and Characters[source].id or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Players()
	return Sources
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETUSERSOURCE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Source(Passport)
	return Sources[parseInt(Passport)] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DATATABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Datatable(Passport)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	if Characters[source] then
		return Characters[source].Datatable
	else
		return vRP.UserData(Passport,"Datatable")
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DATATABLEINFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DatatableInformation(Passport,Mode)
	local Passport = parseInt(Passport)

	return vRP.Datatable(Passport)[Mode] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEDATATABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateDatatable(Passport,Mode,Value)
	local source = vRP.Source(Passport)
	local Datatable = Characters[source] and vRP.Datatable(Passport) or vRP.UserData(Passport,"Datatable")

	Datatable[Mode] = Value

	if not Characters[source] then
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Datatable", Information = json.encode(Datatable) })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Banned(source,Account)
	local Return = false
	local Tokens = GetNumPlayerTokens(source)
	local Identities = GetPlayerIdentifiers(source)

	local function CheckAndInsert(Token)
		local Consult = vRP.SingleQuery("hwid/Check",{ Token = Token })

		if not Consult then
			vRP.Query("hwid/Insert",{ Token = Token, Account = Account.id })
		elseif Consult.Banned then
			if Consult.Account == Account.id then
				Return = Return or "User"
			else
				vRP.Query("hwid/Insert",{ Token = Token, Account = Account.id })
				Return = Return or { "Other",Consult.Account }
			end
		end
	end

	for _,v in pairs(Identities) do
		CheckAndInsert(v)
	end

	for Number = 0,(Tokens - 1) do
		local Token = GetPlayerToken(source,Number)
		if Token then
			CheckAndInsert(Token)
		end
	end

	if Account.Banned == -1 or Account.Banned > 0 then
		vRP.Query("hwid/All",{ Account = Account.id, Banned = 1 })
		Return = Return or "User"
	else
		vRP.Query("hwid/All",{ Account = Account.id, Banned = 0 })

		if Return == "User" then
			Return = false
		end
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetBanned(Passport,Amount,Mode,Reason)
	local function SendToDiscord(Passport,Mode,Amount,Reason,Discord)
		local Message = (Mode == "Permanente") and "Permanente" or Amount
		local Motivo = Reason or "Banimento administrativo"
		exports.discord:Embed("Ban","**[PASSAPORTE]:** "..Passport.."\n**[TEMPO]:** "..Message.."\n**[MOTIVO]:** "..Motivo.."\n**[DISCORD]:** <@"..Discord..">\n**[DATA & HORA]:** "..os.date("%d/%m/%Y").." às "..os.date("%H:%M"))
	end

	local Account = vRP.AccountOptimize(Passport)
	local Permanent = (Amount == -1 or Mode == "Permanente")
	local UseReason = Reason
	if not UseReason then
		if Mode ~= "Permanente" and Mode ~= "Horas" and Mode ~= "Dias" then
			UseReason = Mode
		end
	end
	UseReason = UseReason or "Banimento administrativo"

	vRP.Query("hwid/All",{ Account = Account.id, Banned = 1 })
	local Minutes = nil
	if Permanent then
		vRP.Update("accounts/RemoveBanned",{ Account = Account.id })
		vRP.Query("accounts/BannedPermanent",{ Account = Account.id, Reason = UseReason })
	else
		if Mode == "Horas" then
			Minutes = parseInt(Amount) * 60
		elseif Mode == "Dias" then
			Minutes = parseInt(Amount) * 1440
		else
			Minutes = parseInt(Amount)
		end
		vRP.Update("accounts/RemoveBanned",{ Account = Account.id })
		vRP.Query("accounts/InsertBanned",{ Account = Account.id, Amount = Minutes, Reason = UseReason })
	end
	SendToDiscord(Passport,(Permanent and "Permanente" or "Minutos"),(Minutes or Amount),UseReason,Account.Discord)

	local source = vRP.Source(Passport)
	if source then
		if Characters[source] then
			Characters[source].Banned = Permanent and -1 or Minutes
			Characters[source].Reason = UseReason
			Characters[source].BannedTime = os.time()
			local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(source)))
			Characters[source].BannedPos = vec3(x,y,z)
		end
		
		Player(source).state:set("Banned",true,true)
		exports.vrp:Bucket(source,"Enter",Banned.Route)
		if Banned.Mute then
			TriggerClientEvent("pma-voice:Mute",source,true)
		end

		for Permission in pairs(vRP.UserGroups(Passport)) do
			if vRP.HasService(Passport,Permission) then
				vRP.ServiceLeave(source,Passport,Permission,true)
			end
		end

		local TimeText = Permanent and "Permanente" or (parseInt(Minutes).." minutos")
		TriggerClientEvent("Notify",source,ServerName,"Você foi punido "..TimeText.." de reclusão.","server",10000)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveBanned(Passport)
  local Account = vRP.AccountOptimize(Passport)
  if not Account then
    return
  end

  vRP.Update("accounts/RemoveBanned",{ Account = Account.id })
  vRP.Update("hwid/All",{ Account = Account.id, Banned = 0 })

  local source = vRP.Source(Passport)
  if source then
    Player(source).state:set("Banned",false,true)
    if Characters[source] then
      Characters[source].Banned = 0
      Characters[source].Reason = nil
      Characters[source].BannedPos = nil
    end
    exports.vrp:Bucket(source,"Exit")
    if Banned.Mute then
      TriggerClientEvent("pma-voice:Mute",source,false)
    end
    local Pos = Banned.Leave
    vRP.Teleport(source,Pos.x,Pos.y,Pos.z)
  end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEBANNED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateBanned(Passport,Amount)
  local Account = vRP.AccountOptimize(Passport)
  if not Account or Account.Banned == -1 then return end

  local source = vRP.Source(Passport)
  local Current = 0
  local BannedTime = nil
  local Character = source and Characters[source] or nil
  local CurrentTime = os.time()

  if Character and type(Character.Banned) == "number" then
    if Character.Banned == -1 then
      return
    elseif Character.Banned > 0 then
      Current = parseInt(Character.Banned)
      BannedTime = Character.BannedTime
    end
  end

  if Current <= 0 then
    Current = parseInt(Account.Banned or 0)
    if Current > 0 then
      if Character then
        if not Character.BannedTime then
          Character.BannedTime = CurrentTime
        end
        Character.Banned = Current
        BannedTime = Character.BannedTime
      else
        BannedTime = CurrentTime
      end
    end
  end

  if not BannedTime then
    BannedTime = CurrentTime
    if Character then
      Character.BannedTime = BannedTime
    end
  end

  local ElapsedMinutes = math.floor((CurrentTime - BannedTime) / 60)
  local Updated = false

  if ElapsedMinutes > 0 then
    vRP.Update("accounts/ReduceBanned",{ Account = Account.id, Amount = ElapsedMinutes })
    Current = math.max(0, Current - ElapsedMinutes)
    Updated = true

    if Character then
      Character.Banned = Current
      Character.BannedTime = CurrentTime
    end
  end

  if Current <= 0 then
    if source then
      Player(source).state:set("Banned",false,true)
      if Character then
        Character.Banned = 0
        Character.Reason = nil
        Character.BannedTime = nil
      end

      vRP.Update("accounts/RemoveBanned",{ Account = Account.id })
      vRP.Update("hwid/All",{ Account = Account.id, Banned = 0 })
      exports.vrp:Bucket(source,"Exit")

      if Banned.Mute then
        TriggerClientEvent("pma-voice:Mute",source,false)
      end

      SetTimeout(1000,function()
        vRP.Teleport(source,Banned.Leave.x,Banned.Leave.y,Banned.Leave.z)
      end)
    end
    return
  end

  if Amount then
    local Reduce = parseInt(Amount)
    Current = math.max(0, Current - Reduce)
    Updated = true

    vRP.Update("accounts/ReduceBanned",{ Account = Account.id, Amount = Reduce })

    if Character then
      Character.Banned = Current
      Character.BannedTime = CurrentTime
    end
  end

  if source then
    Player(source).state:set("Banned",Current > 0,true)

    if Updated and Current > 0 then
      TriggerClientEvent("Notify",source,ServerName,"Restam "..parseInt(Current).." minutos de reclusão.","server",5000)
    end
  end

  if Character then
    Character.Banned = Current
  end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Kick(source,Reason)
	if Disconnect(source,Reason) then
		DropPlayer(source,Reason)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERDROPPED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerDropped",function(Reason)
	Disconnect(source,Reason)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
function Disconnect(source,Reason)
	local Armour = 0
	local Health = 100
	local Coords = SpawnCoords[1]
	local Ped = GetPlayerPed(source)

	if DoesEntityExist(Ped) then
		Armour = GetPedArmour(Ped)
		Health = GetEntityHealth(Ped)
		Coords = GetEntityCoords(Ped)
	end

	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Datatable = vRP.Datatable(Passport)
	if not Datatable then
		return false
	end

	if Arena[Passport] then
		Datatable.Pos = Arena[Passport].Pos
		Datatable.Stress = Arena[Passport].Stress
		Datatable.Hunger = Arena[Passport].Hunger
		Datatable.Thirst = Arena[Passport].Thirst
		Datatable.Armour = Arena[Passport].Armour
		Datatable.Health = Arena[Passport].Health
		Datatable.Inventory = Arena[Passport].Inventory

		local Route = Arena[Passport].Route
		GlobalState["Arena:"..Route] = GlobalState["Arena:"..Route] - 1
		Arena[Passport] = nil
	else
		Datatable.Armour = Armour
		Datatable.Health = Health
		Datatable.Pos = Coords
	end
	
	if DisconnectReason then
		exports.chat:Postit(Passport,Coords,Reason,DisconnectReason)
	end

	local License = vRP.Identities(source)
	TriggerEvent("Disconnect",Passport,source,License)
	vRP.Query("characters/LastLogin",{ Passport = Passport })
	vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Datatable", Information = json.encode(Datatable) })
	exports["discord"]:Embed("Disconnect","**[SOURCE]:** "..source.."\n**[PASSAPORTE]:** "..Passport.."\n**[VIDA]:** "..Datatable.Health.."\n**[COLETE]:** "..Datatable.Armour.."\n**[COORDS]:** "..Datatable.Pos.."\n**[MOTIVO]:** "..Reason)

	if Characters[source] then
		Characters[source] = nil
	end

	if Sources[Passport] then
		Sources[Passport] = nil
	end
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERCONNECTING
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerConnecting",function(_,__,deferrals)
    deferrals.defer()

    local Source = source
    local License
    local Timeout = 0

    while not License and Timeout < 20 do
        License = vRP.Identities(Source)
        Timeout = Timeout + 1
        Wait(250)
    end

    local function Present(Card,Fallback)
        if deferrals.presentCard then
            deferrals.presentCard(Card,function() deferrals.done() end)
        else
            deferrals.done(Fallback)
        end
    end

    local function Generate(Body,Actions)
        return json.encode({ ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json", type = "AdaptiveCard", version = "1.5", body = Body, actions = Actions })
    end

    if not License then
        deferrals.done("\n\nNão foi possível efetuar conexão com a Steam.")
        return false
    end

    local Account = vRP.Account(License) or ( vRP.Query("accounts/NewAccount", { License = License, Token = vRP.GenerateToken() }) and vRP.Account(License) )

    if not Account then
        deferrals.done("\n\nErro ao carregar sua conta.")
        return false
    end

    if Maintenance then
        if not Maintenance[License] then
            deferrals.done("\n\nO servidor encontra-se em manutenção.\nPara mais informações, acesse: "..ServerLink)
            return false
        end
    end

    local Banned = vRP.Banned(Source,Account)
    if Banned and Account.Banned == -1 then
        local Duration = "Permanente"
        local Reason = Banned[1] == "Other" and (Banned[2] or "Banimento") or (Account.Reason or "Banimento administrativo")
        
        Present(Generate({{ type = "Image", url = ServerAvatar or "", size = "Medium", style = "Person" }, { type = "RichTextBlock", inlines = {{ type = "TextRun", text = "Consequência: ", size = "Medium", weight = "Bolder" },{ type = "TextRun", text = "Banido", size = "Medium", weight = "Lighter" }} }, { type = "RichTextBlock", inlines = {{ type = "TextRun", text = "Tempo: ", size = "Medium", weight = "Bolder" },{ type = "TextRun", text = Duration, size = "Medium", weight = "Lighter" }} }, { type = "RichTextBlock", inlines = {{ type = "TextRun", text = "Motivo: ", size = "Medium", weight = "Bolder" },{ type = "TextRun", text = Reason, size = "Medium", weight = "Lighter" }} }}),Banned[1] == "Other" and ("\n\nBanido | "..Banned[2]) or ("\n\n<b>Consequência:</b> Banido\n<b>Tempo:</b> "..Duration.."\n<b>Motivo:</b> "..Reason))
        return false
    end

    if Whitelisted then
        if not Account.Whitelist then
            local Card = {
                type = "AdaptiveCard",
                ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
                version = "1.5",
                body = {
                    {
                        type = "TextBlock",
                        text = string.format("\n\nVocê não possui Allowlist ID: %s", Account[Liberation] or "Erro"),
                        wrap = true, fontType = "Default", size = "Medium", weight = "Lighter"
                    }
                },
                actions = {
                    { type = "Action.OpenUrl", title = "Clique para abrir o Discord", url = ServerLink }
                }
            }

            deferrals.presentCard(Card, function() deferrals.done() end)
            return false
        end
    end
	
    vRP.Query("accounts/LastLogin",{ License = License })
    deferrals.done()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CharacterChosen(source,Passport,Model)
	Sources[Passport] = source

	if not Characters[source] then
		vRP.Query("characters/LastLogin",{ Passport = Passport })

		local License = vRP.Identities(source)
		local Account = vRP.Account(License)
		local Character = vRP.SingleQuery("characters/Person",{ Passport = Passport })

		Characters[source] = { Datatable = vRP.UserData(Passport,"Datatable") }

		for Index,v in pairs(Account) do
			Characters[source][Index] = v
		end

		for Index,v in pairs(Character) do
			Characters[source][Index] = v
		end

		if Model then
			Characters[source].Datatable.Inventory = {}

			for Item,Amount in pairs(CharacterItens) do
				vRP.GenerateItem(Passport,Item,Amount,false)
			end

			local Table = {
				{ Name = "Barbershop", Information = json.encode(BarbershopInit[Model]) },
				{ Name = "Clothings", Information = json.encode(SkinshopInit[Model]) },
				{ Name = "Tattooshop", Information = json.encode({}) },
				{ Name = "Datatable", Information = json.encode({}) }
			}

			for _,v in ipairs(Table) do
				vRP.Query("playerdata/SetData",{ Passport = Passport, Name = v.Name, Information = v.Information })
			end
		end

		if Account.Gemstone > 0 then
			TriggerClientEvent("hud:AddGemstone",source,Account.Gemstone)
		end

		exports["discord"]:Embed("Connect","**[SOURCE]:** "..source.."\n**[PASSAPORTE]:** "..Passport.."\n**[ADDRESS]:** "..GetPlayerEndpoint(source).."\n**[LICENSE]:** "..Account.License.."\n**[discord:** <@"..Account.Discord..">")

		if DiscordBot then
			exports["discord"]:Content("Rename",Account.Discord.." #"..Passport.." "..Character.Name.." "..Character.Lastname)
		end

		TriggerEvent("CharacterChosen",Passport,source,Model ~= nil)
	else
		DropPlayer(source,"Desconectado")
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEDAILY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateDaily(Passport,source,Daily)
    exports.oxmysql:execute("UPDATE characters SET Daily = @Daily WHERE id = @Passport",{ Daily = Daily, Passport = Passport })

    if Characters[source] then
        Characters[source].Daily = Daily
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEEDRETURN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WeedReturn(Passport)
	local CurrentTime = os.time()
	local ExpirationTime = Weed[Passport]

	if ExpirationTime and CurrentTime < ExpirationTime then
		return parseInt(ExpirationTime - CurrentTime)
	end

	Weed[Passport] = nil

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEEDTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WeedTimer(Passport,Timer)
	Weed[Passport] = (Weed[Passport] or os.time()) + (Timer * 60)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEMICALRETURN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ChemicalReturn(Passport)
	local CurrentTime = os.time()
	local ExpirationTime = Chemical[Passport]

	if ExpirationTime and CurrentTime < ExpirationTime then
		return parseInt(ExpirationTime - CurrentTime)
	end

	Chemical[Passport] = nil

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEMICALTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ChemicalTimer(Passport,Timer)
	Chemical[Passport] = (Chemical[Passport] or os.time()) + (Timer * 60)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ALCOHOLRETURN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AlcoholReturn(Passport)
	local CurrentTime = os.time()
	local ExpirationTime = Alcohol[Passport]

	if ExpirationTime and CurrentTime < ExpirationTime then
		return parseInt(ExpirationTime - CurrentTime)
	end

	Alcohol[Passport] = nil

	return 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHEMICALTIMER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.AlcoholTimer(Passport,Timer)
	Alcohol[Passport] = (Alcohol[Passport] or os.time()) + (Timer * 60)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FORSERVICE
-----------------------------------------------------------------------------------------------------------------------------------------
for Permission in pairs(Groups) do
	Service[Permission] = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Groups()
	return Groups
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERDOMINATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserDomination(Passport)
	local Group = false

	for Index,v in pairs(Groups) do
		if v.Domination then
			if vRP.HasPermission(Passport,Index) then
				Group = Index
				break
			end
		end
	end

	return Group
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERSALARYS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserSalarys(Passport)
	local Valuation = 0

	for Permission,v in pairs(Groups) do
		local SalaryLevels = v.Salary
		if SalaryLevels then
			local Level = vRP.HasService(Passport,Permission)
			if Level and SalaryLevels[Level] then
				Valuation = Valuation + SalaryLevels[Level]
			end
		end
	end

	return Valuation
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERGROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserGroups(Passport)
	local Table = {}
	for Permission in pairs(Groups) do
		local CheckPermission = vRP.HasPermission(Passport,Permission)
		if CheckPermission then
			Table[Permission] = CheckPermission
		end
	end

	return Table
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
	return Groups[Permission] and Groups[Permission].Type or "UnWorked"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOOPPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.LoopPermission(Passport,Permission)
	if Groups[Permission] and Groups[Permission].Permission then
		for Parent in pairs(Groups[Permission].Permission) do
			if vRP.HasPermission(Passport,Parent) then
				return Parent
			end
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

	for Permission,Group in pairs(Groups) do
		if Group.Type == Type then
			local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
			if Consult[Passport] then
				return Permission
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

	if Groups[Permission].Markers then
		Player(source).state:set("Markers",true,true)
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

	if not Playing[Permission] then
		Playing[Permission] = {}
	end

	if Playing[Permission][Passport] then
		local Consult = vRP.GetSrvData("Playing:"..Passport,true)
		Consult[Permission] = (Consult[Permission] or 0) + (CurrentTimer - Playing[Permission][Passport])
		vRP.SetSrvData("Playing:"..Passport,Consult,true)

		Playing[Permission][Passport] = nil
	end

	Player(source).state[Permission] = nil

	if Groups[Permission].Markers then
		Player(source).state:set("Markers",false,true)
		exports.markers:Exit(source,Passport)
		TriggerClientEvent("radio:RadioClean",source)
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
	if Groups[Permission] then
		local Passport = tostring(Passport)
		local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
		local Hierarchy = Groups[Permission].Hierarchy and CountTable(Groups[Permission].Hierarchy) or 1

		if Mode then
			local Adjustment = (Mode == "Demote") and 1 or -1
			Consult[Passport] = math.min(math.max((Consult[Passport] or 1) + Adjustment,1),Hierarchy)
		else
			Consult[Passport] = Level and math.min(parseInt(Level),Hierarchy) or Hierarchy
		end

		vRP.ServiceEnter(vRP.Source(Passport),Passport,Permission,true)
		vRP.SetSrvData("Permissions:"..Permission,Consult,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemovePermission(Passport,Permission)
	if Groups[Permission] then
		local Passport = tostring(Passport)
		if Service[Permission] and Service[Permission][Passport] then
			Service[Permission][Passport] = nil
		end

		local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
		if Consult[Passport] then
			local source = vRP.Source(Passport)

			Consult[Passport] = nil
			vRP.ServiceLeave(source,Passport,Permission,true)
			vRP.SetSrvData("Permissions:"..Permission,Consult,true)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.HasPermission(Passport,Permission,Level)
	local PermissionParts = splitString(Permission,"-")
	if PermissionParts[2] then
		Permission,Level = PermissionParts[1],parseInt(PermissionParts[2])
	end

	if not Groups[Permission] then
		return false
	end

	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Permissions:"..Permission,true)
	local CurrentLevel = Consult[Passport]

	return (CurrentLevel and (not Level or CurrentLevel <= Level)) and CurrentLevel or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASTABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.HasTable(Passport,Table)
	local Passport = tostring(Passport)

	for _,Permission in ipairs(Table) do
		local Check = splitString(Permission)
		local PermissionName,LevelParented = Check[1],Check[2] and parseInt(Check[2]) or nil
		local Consult = vRP.GetSrvData("Permissions:"..PermissionName,true)
		local CurrentLevel = Consult[Passport]

		if CurrentLevel and (not LevelParented or CurrentLevel <= LevelParented) then
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
		Permission,Level = PermissionParts[1],parseInt(PermissionParts[2])
	end

	if Groups[Permission] and Groups[Permission].Permission then
		local Passport = tostring(Passport)
		for Parent in pairs(Groups[Permission].Permission) do
			local ParentParts = splitString(Parent)
			local ParentPermission,ParentLevel = ParentParts[1],ParentParts[2] and parseInt(ParentParts[2]) or nil
			local Consult = vRP.GetSrvData("Permissions:"..ParentPermission,true)
			local CurrentLevel = Consult[Passport]

			if CurrentLevel and ((not Level and not ParentLevel) or (not Level and ParentLevel and CurrentLevel == ParentLevel) or (Level and CurrentLevel <= Level)) then
				return CurrentLevel
			end
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
		Permission,Level = PermissionParts[1],parseInt(PermissionParts[2])
	end

	if Groups[Permission] and Groups[Permission].Permission then
		local Passport = tostring(Passport)
		for Parent in pairs(Groups[Permission].Permission) do
			local ParentParts = splitString(Parent)
			local ParentPermission,ParentLevel = ParentParts[1],ParentParts[2] and parseInt(ParentParts[2]) or nil
			local Consult = vRP.GetSrvData("Permissions:"..ParentPermission,true)
			local CurrentLevel = Consult[Passport]

			if CurrentLevel and Groups[ParentPermission] and Service[ParentPermission] and Service[ParentPermission][Passport] then
				if (not Level and not ParentLevel) or (not Level and ParentLevel and CurrentLevel == ParentLevel) or (Level and CurrentLevel <= Level) then
					return CurrentLevel
				end
			end
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Playing(Passport,Permission)
	local CurrentTimer = os.time()
	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Playing:"..Passport)
	local Return = Consult[Permission] or 0

	if Playing[Permission] and Playing[Permission][Passport] then
		Return = Return + (CurrentTimer - Playing[Permission][Passport])
	end

	return Return
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

	Playing.Online[Passport] = Playing.Online[Passport] or os.time()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	local CurrentTimer = os.time()
	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Playing:"..Passport,true)

	for Permission,v in pairs(Groups) do
		if Playing[Permission] and Playing[Permission][Passport] then
			Consult[Permission] = (Consult[Permission] or 0) + (CurrentTimer - Playing[Permission][Passport])
			Playing[Permission][Passport] = nil
		end

		if Service[Permission] and Service[Permission][Passport] then
			Service[Permission][Passport] = false
		end
	end

	if Playing.Online[Passport] then
		Consult.Online = (Consult.Online or 0) + (CurrentTimer - Playing.Online[Passport])
		Playing.Online[Passport] = nil
	end

	vRP.SetSrvData("Playing:"..Passport,Consult,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- IDENTITY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Identity(Passport)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	return Characters[source] or vRP.SingleQuery("characters/Person",{ Passport = Passport })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FULLNAME
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.FullName(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and (Identity.Name.." "..Identity.Lastname) or NameDefault
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOWERNAME
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.LowerName(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and Identity.Name or SplitOne(NameDefault," ")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AVATAR
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Avatar",function(Passport,Permission)
    if not Passport then
        return ""
    end
    
    local Consult
    
    if Permission then
        Consult = exports.oxmysql:single_async("SELECT Image FROM avatars WHERE Passport = ? AND Permission = ? LIMIT 1",{ Passport, Permission })
    else
        Consult = exports.oxmysql:single_async("SELECT Image FROM avatars WHERE Passport = ? ORDER BY id DESC LIMIT 1",{ Passport })
    end

    return Consult and Consult.Image or ""
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LICENSE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.License(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and Identity.License or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSERTPRISON
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsertPrison(Passport,Amount)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount > 0 then
		vRP.Query("characters/InsertPrison",{ Passport = Passport, Prison = Amount })

		local source = vRP.Source(Passport)
		if Characters[source] then
			Characters[source].Prison = (Characters[source].Prison or 0) + Amount
			Player(source).state.Prison = true
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPRISON
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdatePrison(Passport,Amount)
    local Amount = parseInt(Amount)
    local Passport = parseInt(Passport)

    if Amount > 0 then
        vRP.Query("characters/ReducePrison",{ Passport = Passport, Prison = Amount })

        local source = vRP.Source(Passport)
        if Characters[source] then
            local Identity = Characters[source]
            Characters[source].Prison = math.max((Characters[source].Prison or 0) - Amount,0)
            Player(source).state.Prison = Characters[source].Prison > 0

            if Identity then
                if Identity.Prison <= 0 then
                    vRP.Teleport(source,PrisonCoords.x,PrisonCoords.y,PrisonCoords.z)
                    TriggerClientEvent("Notify",source,"Boolingbroke","Serviços finalizados.","policia",5000)
                else
                    TriggerClientEvent("Notify",source,"Boolingbroke","Reduzimos "..Amount.." serviços, restando um total de "..Identity.Prison..".","policia",5000)
                end
            end
        end
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADECHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeCharacters(source)
	if Characters[source] then
		vRP.Query("accounts/UpdateCharacters",{ License = Characters[source].License })
		Characters[source].Characters = Characters[source].Characters + 1
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UserGemstone(License)
	return vRP.Account(License).Gemstone or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADEGEMSTONE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeGemstone(Passport,Amount,SendLicense)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)
	if Amount > 0 and Identity then
		vRP.Query("accounts/AddGemstone",{ License = Identity.License, Gemstone = Amount })

		if DiscordBot and SendLicense then
			local Account = vRP.Account(Identity.License)
			exports.discord:Content("Gemstone",Account.Discord.." Obrigado por sua contribuição ao **"..ServerName.."**, seus **"..Dotted(Amount).."x Diamantes** foram creditados em sua conta.")
		end

		local source = vRP.Source(Passport)
		if Characters[source] then
			TriggerClientEvent("hud:AddGemstone",source,Amount)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADENAMES
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeNames(Passport,Name,Lastname)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	if Characters[source] then
		Characters[source].Name = Name
		Characters[source].Lastname = Lastname
	end

	vRP.Query("characters/UpdateName",{ Name = Name, Lastname = Lastname, Passport = Passport })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSPORTPLATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PassportPlate(Plate)
	local Consult = vRP.SingleQuery("vehicles/plateVehicles",{ Plate = Plate })
	return Consult and Consult.Passport or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEPLATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GeneratePlate()
	repeat
		Plate = GenerateString("DDLLLDDD")
	until Plate and not vRP.PassportPlate(Plate)

	return Plate
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATETOKEN
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GenerateToken()
	repeat
		Token = GenerateString("DDDDDDD")
	until Token and not vRP.SingleQuery("accounts/Token",{ Token = Token })

	return Token
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEHASH
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GenerateHash(Index)
	repeat
		Hash = GenerateString("DDLLDDLL")
	until Hash and not vRP.SingleQuery("entitydata/GetData",{ Name = Index..":"..Hash })

	return Hash
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVECHARGES
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.RemoveCharges(Passport,Item)
	local Consult = vRP.ConsultItem(Passport,Item)

	if not (Consult and Consult.Item and Consult.Slot and Consult.Amount > 0) then
		return false
	end

	if not vRP.TakeItem(Passport,Consult.Item,1,false,Consult.Slot) then
		return false
	end

	if ItemLoads(Consult.Item) then
		local Slotable = Consult.Slot
		local Name = SplitOne(Consult.Item)
		local Charger = SplitTwo(Consult.Item) - 1

		if Consult.Amount > 1 then
			Slotable = false
		end

		if Charger >= 1 then
			vRP.GiveItem(Passport,Name.."-"..Charger,1,false,Slotable)
		else
			local Empty = ItemEmpty(Consult.Item)
			if Empty and ItemExist(Empty) then
				vRP.GenerateItem(Passport,Empty,1,false,Slotable)
			end
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONSULTITEM
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.ConsultItem(Passport,Item,Amount)
	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)
	local ItemAmount,ItemName,ItemSlot = table.unpack(vRP.InventoryItemAmount(Passport,Item))

	if ItemAmount >= Amount and not vRP.CheckDamaged(ItemName) then
		return { Amount = ItemAmount, Item = ItemName, Slot = ItemSlot }
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.GetWeight(Passport,Ignore)
	local Weight = 0
	local Passport = parseInt(Passport)
	local Datatable = vRP.Datatable(Passport)

	if Datatable then
		Datatable.Weight = Datatable.Weight or MinimumWeight
		Weight = Datatable.Weight

		if not Ignore then
			for Index,v in pairs(Groups) do
				if v and v.Backpack then
					local Permission = vRP.HasService(Passport,Index)
					if Permission and v.Backpack[Permission] then
						Weight = Weight + v.Backpack[Permission]
					end
				end
			end

			local Slotable = vRP.CheckSlotable(Passport,"104")
			if Slotable then
				Weight = Weight + ItemBackpack(Slotable)
			end
		end
	end

	return Weight
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.CheckWeight(Passport,Item,Amount)
	return ((vRP.InventoryWeight(Passport) + (ItemWeight(Item) * (Amount or 1))) <= vRP.GetWeight(Passport)) and true or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADEWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.UpgradeWeight(Passport,Amount,Mode)
	local Passport = parseInt(Passport)
	local Datatable = vRP.Datatable(Passport)
	if Datatable then
		Datatable.Weight = Datatable.Weight or MinimumWeight

		if Mode == "+" then
			Datatable.Weight = Datatable.Weight + Amount
		else
			Datatable.Weight = math.max(Datatable.Weight - Amount,MinimumWeight)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKSLOTABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CheckSlotable(Passport,Slot)
	local Slot = tostring(Slot)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)
	if Inventory and Inventory[Slot] and Inventory[Slot].item and ItemExist(Inventory[Slot].item) and Inventory[Slot].item and Inventory[Slot].amount >= 1 and not vRP.CheckDamaged(Inventory[Slot].item) then
		return Inventory[Slot].item
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SWAPSLOT	
-----------------------------------------------------------------------------------------------------------------------------------------	
function vRP.SwapSlot(Passport,Slot,Target)
	local Slot = tostring(Slot)
	local Target = tostring(Target)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	if Inventory[Slot] and Inventory[Target] then
		Inventory[Slot],Inventory[Target] = Inventory[Target],Inventory[Slot]
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventoryWeight(Passport)
	local Weight = 0
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if ItemExist(v.item) then
			Weight = Weight + ItemWeight(v.item) * v.amount
		end
	end

	return Weight
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKDAMAGED
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CheckDamaged(Item)
	local splitTime = SplitTwo(Item)
	local durability = ItemDurability(Item)

	if durability and splitTime then
		local maxTime = 3600 * durability
		local elapsedTime = os.time() - splitTime
		local remainingPercentage = (maxTime - elapsedTime) / maxTime

		if remainingPercentage <= 0.01 then
			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHESTWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ChestWeight(Data)
	local Weight = 0

	for _,v in pairs(Data) do
		if ItemExist(v.item) then
			Weight = Weight + ItemWeight(v.item) * v.amount
		end
	end

	return Weight
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYITEMAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventoryItemAmount(Passport,Item)
	local ItemSplit = SplitOne(Item)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for Slot,v in pairs(Inventory) do
		if ItemSplit == SplitOne(v.item) then
			return { v.amount,v.item,Slot }
		end
	end

	return { 0,"" }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORYFULL
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InventoryFull(Passport,Item)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if v.item == Item then
			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ItemAmount(Passport,Item)
	local Amount = 0
	local ItemSplit = SplitOne(Item)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if SplitOne(v.item) == ItemSplit then
			Amount = Amount + v.amount
		end
	end

	return Amount
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMCHESTAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ItemChestAmount(Data,Item,Save)
	local Amount = 0
	local ItemSplit = SplitOne(Item)
	local Consult = vRP.GetSrvData(Data,Save)

	for _,v in pairs(Consult) do
		if SplitOne(v.item) == ItemSplit then
			Amount = Amount + v.amount
		end
	end

	return Amount
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GIVEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GiveItem(Passport,Item,Amount,Notify,Slot)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local Animation = ItemAnim(Item)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)
	local Inventory = vRP.Inventory(Passport)

	local function AddItemToInventory(slot)
		if type(slot) ~= "string" then
			slot = tostring(slot)
		end

		if not Inventory[slot] or Inventory[slot].item == Item then
			Inventory[slot] = { item = Item, amount = (Inventory[slot] and Inventory[slot].amount or 0) + Amount }
		end

		if ItemTypeCheck(Item,"Armamento") and vRP.ConsultItem(Passport,Item) then
			TriggerClientEvent("inventory:CreateWeapon",source,Item)
		end

		if Animation then
			vRPC.PersistentBlock(source,Item,Animation)
		end

		if Notify and ItemExist(Item) then
			TriggerClientEvent("inventory:NotifyItem",source,{ Item,Amount })
		end
	end

	if not Slot then
		for Number = 0,100 do
			local SlotIndex = tostring(Number)
			if not Inventory[SlotIndex] or (Inventory[SlotIndex] and Inventory[SlotIndex].item == Item) then
				AddItemToInventory(SlotIndex)
				break
			end
		end
	else
		AddItemToInventory(Slot)
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GENERATEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GenerateItem(Passport,Item,Amount,Notify,Slot)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)
	local Inventory = vRP.Inventory(Passport)
	local Item = vRP.SortNameItem(Passport,Item)
	local Animation = ItemAnim(Item)

	local function AddItemToInventory(slot)
		if not Inventory[slot] then
			Inventory[slot] = { item = Item, amount = Amount }

			if ItemTypeCheck(Item,"Armamento") and vRP.ConsultItem(Passport,Item) then
				TriggerClientEvent("inventory:CreateWeapon",source,Item)
			end
		elseif Inventory[slot] and Inventory[slot].item == Item then
			Inventory[slot].amount = Inventory[slot].amount + Amount
		end
	end

	if not Slot then
		for Number = 0,100 do
			local SlotIndex = tostring(Number)
			if not Inventory[SlotIndex] or (Inventory[SlotIndex] and Inventory[SlotIndex].item == Item) then
				AddItemToInventory(SlotIndex)
				break
			end
		end
	else
		Slot = tostring(Slot)
		AddItemToInventory(Slot)
	end

	if Animation then
		vRPC.PersistentBlock(source,Item,Animation)
	end

	if Notify and ItemExist(Item) then
		TriggerClientEvent("inventory:NotifyItem",source,{ Item,Amount })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAXITENS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.MaxItens(Passport,Item,Amount)
	local Item = Item
	if not ItemExist(Item) then
		return false
	end

	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)
	local MaxAmount = ItemMaxAmount(Item)
	if not MaxAmount or (vRP.ItemAmount(Passport,Item) + Amount) <= MaxAmount then
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAXCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.MaxChest(Data,Item,Amount,Save)
	local Item = Item
	if not ItemExist(Item) then
		return false
	end

	local Data = Data
	local Amount = parseInt(Amount)
	local MaxAmount = ItemMaxAmount(Item)
	if not MaxAmount or (vRP.ItemChestAmount(Data,Item,Save) + Amount) <= MaxAmount then
		return false
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.TakeItem(Passport,Item,Amount,Notify,Slot)
	local Item = Item
	local Returned = false
	local Animation = ItemAnim(Item)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)
	local Amount = parseInt(Amount,true)
	local Inventory = vRP.Inventory(Passport)

	if source then
		if not Slot then
			for Index,v in pairs(Inventory) do
				if Inventory[Index].item == Item and Inventory[Index].amount >= Amount then
					Inventory[Index].amount = Inventory[Index].amount - Amount

					if Inventory[Index].amount <= 0 then
						if Animation and not vRP.ConsultItem(Passport,Item) then
							vRPC.PersistentNone(source,Item)
						end

						if ItemTypeCheck(Item,"Armamento") or ItemTypeCheck(Item,"Arremesso") then
							TriggerClientEvent("inventory:verifyWeapon",source,Item)
						end

						if Index == "104" then
							local Skinshop = ItemSkinshop(Item)
							if Skinshop then
								TriggerClientEvent("skinshop:BackpackRemove",source)
							end
						end

						local Execute = ItemExecute(Item)
						if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
							if Execute.Type == "Client" then
								TriggerClientEvent(Execute.Event,source)
							else
								TriggerEvent(Execute.Event,source,Passport)
							end
						end

						Inventory[Index] = nil
					end

					if Notify and ItemExist(Item) then
						TriggerClientEvent("inventory:NotifyItem",source,{ Item,-Amount })
					end

					Returned = true

					break
				end
			end
		else
			local Slot = tostring(Slot)
			if Inventory[Slot] and Inventory[Slot].item == Item and Inventory[Slot].amount >= Amount then
				Inventory[Slot].amount = Inventory[Slot].amount - Amount

				if Inventory[Slot].amount <= 0 then
					if Animation and not vRP.ConsultItem(Passport,Item) then
						vRPC.PersistentNone(source,Item)
					end

					if ItemTypeCheck(Item,"Armamento") or ItemTypeCheck(Item,"Arremesso") then
						TriggerClientEvent("inventory:verifyWeapon",source,Item)
					end

					if Slot == "104" then
						local Skinshop = ItemSkinshop(Item)
						if Skinshop then
							TriggerClientEvent("skinshop:BackpackRemove",source)
						end
					end

					local Execute = ItemExecute(Item)
					if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
						if Execute.Type == "Client" then
							TriggerClientEvent(Execute.Event,source)
						else
							TriggerEvent(Execute.Event,source,Passport)
						end
					end

					Inventory[Slot] = nil
				end

				if Notify and ItemExist(Item) then
					TriggerClientEvent("inventory:NotifyItem",source,{ Item,-Amount })
				end

				Returned = true
			end
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANSLOT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CleanSlot(Passport,Slot)
	local Slot = tostring(Slot)
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	if Inventory[Slot] then
		Inventory[Slot] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveItem(Passport,Item,Amount,Notify)
	local Amount = parseInt(Amount)
	if Amount <= 0 then
		return false
	end

	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)
	local Inventory = vRP.Inventory(Passport)

	for Index,v in pairs(Inventory) do
		if Inventory[Index] and Inventory[Index].item == Item and Inventory[Index].amount >= Amount then
			Inventory[Index].amount = Inventory[Index].amount - Amount

			if Inventory[Index].amount <= 0 then
				local Animation = ItemAnim(Item)
				if Animation and not vRP.ConsultItem(Passport,Item) then
					vRPC.PersistentNone(source,Item)
				end

				if ItemTypeCheck(Item,"Armamento") or ItemTypeCheck(Item,"Arremesso") then
					TriggerClientEvent("inventory:verifyWeapon",source,Item)
				end

				if ItemUnique(Item) then
					local Unique = SplitUnique(Item)
					if Unique then
						vRP.RemSrvData(Unique)
					end
				end

				local Execute = ItemExecute(Item)
				if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
					if Execute.Type == "Client" then
						TriggerClientEvent(Execute.Event,source)
					else
						TriggerEvent(Execute.Event,source,Passport)
					end
				end

				Inventory[Index] = nil
			end

			if Notify and ItemExist(Item) then
				TriggerClientEvent("inventory:NotifyItem",source,{ Item,-Amount })
			end

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETSRVDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetSrvData(Key,Save)
	if not Entitys[Key] then
		local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = Key })

		Entitys[Key] = {
			Data = Consult and Consult.Information and json.decode(Consult.Information) or {},
			Timer = os.time() + 60,
			Save = Save
		}
	end

	return Entitys[Key].Data
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETSRVDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetSrvData(Key,Data,Save)
	Entitys[Key] = {
		Data = Data,
		Timer = os.time() + 60,
		Save = Save and true or false
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMSRVDATA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemSrvData(Key)
	if Entitys[Key] then
		Entitys[Key] = nil
	end

	vRP.Query("entitydata/RemoveData",{ Name = Key })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	for Index,v in pairs(Entitys) do
		if v.Save then
			vRP.Query("entitydata/SetData",{ Name = Index, Information = json.encode(v.Data) })
		else
			if Silenced and SplitOne(Index,":") == "Trash" then
				for _,v in pairs(v.Data) do
					if v.item and ItemUnique(v.item) then
						local Unique = SplitUnique(v.item)
						if Unique then
							vRP.RemSrvData(Unique)
						end
					end
				end
			end
		end
	end

	for Passport in pairs(Sources) do
		local Datatable = vRP.Datatable(Passport)
		if Datatable then
			vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Datatable", Information = json.encode(Datatable) })
		end
	end

	if not Silenced then
		print("O resource ^2vRP^7 salvou os dados.")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(60000)

		for Key,v in pairs(Entitys) do
			if os.time() >= v.Timer and v.Save then
				local Save = type(v.Data) == "string" and v.Data or json.encode(v.Data)
				vRP.Query("entitydata/SetData",{ Name = Key, Information = Save })
				Entitys[Key] = nil
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVUPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.invUpdate(Slot,Target,Amount)
	local source = source
	local Amount = parseInt(Amount)
	local Passport = vRP.Passport(source)
	if Passport and Amount > 0 then
		local Item = nil
		local Returned = true
		local Slot = tostring(Slot)
		local Target = tostring(Target)
		local Inventory = vRP.Inventory(Passport)

		if Inventory[Slot] then
			Item = Inventory[Slot].item

			if Inventory[Target] then
				if Inventory[Slot] and Inventory[Target] then
					if Item == Inventory[Target].item then
						if Inventory[Slot].amount >= Amount then
							Inventory[Slot].amount = Inventory[Slot].amount - Amount
							Inventory[Target].amount = Inventory[Target].amount + Amount

							if Inventory[Slot].amount <= 0 then
								Inventory[Slot] = nil
							end

							Returned = false
						end
					else
						local Unique = SplitOne(Item)
						local Splice = splitString(Inventory[Target].item)
						local ItemRepair = ItemRepair(Inventory[Target].item)
						local ItemFishing = ItemFishing(Inventory[Target].item)

						if Unique == "gsrkit" and ItemSerial(Splice[1]) then
							if vRP.TakeItem(Passport,Item,1,false,Slot) then
								if Splice[4] then
									TriggerClientEvent("inventory:Notify",source,"Sucesso","Propriedade do passaporte <b>"..Splice[4].."</b>","verde")
								else
									TriggerClientEvent("inventory:Notify",source,"Aviso","Serial não encontrado.","amarelo")
								end
							end
						elseif Unique == "WEAPON_SWITCHBLADE" and not vRP.CheckDamaged(Item) and ItemFishing then
							local Temporary = Inventory[Target].amount
							if vRP.TakeItem(Passport,Inventory[Target].item,Temporary,false,Target) then
								vRP.GenerateItem(Passport,"fishfillet",Temporary * ItemFishing)
							end
						elseif vRP.CheckDamaged(Inventory[Target].item) and ItemRepair and Inventory[Target].amount == 1 and ItemRepair == Unique then
							if ItemTypeCheck(Inventory[Target].item,"Armamento") and parseInt(Splice[3]) <= 0 then
								TriggerClientEvent("inventory:Notify",source,"Aviso","Armamento não pode ser reparado.","amarelo")
							else
								if vRP.TakeItem(Passport,Item,1,false,Slot) then
									local CurrentTime = os.time() - 1
									if ItemTypeCheck(Inventory[Target].item, "Armamento") then
										local Serial = Splice[4] and "-"..(Passport or "")
										Inventory[Target].item = Splice[1].."-"..CurrentTime.."-"..parseInt(Splice[3] - 1)..Serial
									else
										if ItemUnique(Splice[1]) then
											Inventory[Target].item = Splice[1].."-"..CurrentTime.."-"..Splice[3]
										else
											Inventory[Target].item = Splice[1].."-"..CurrentTime
										end
									end
								end
							end
						else
							local Temp = Inventory[Slot]
							Inventory[Slot] = Inventory[Target]
							Inventory[Target] = Temp

							Returned = false
						end
					end
				end
			else
				if Inventory[Slot] and Inventory[Slot].amount >= Amount then
					Inventory[Target] = { item = Item, amount = Amount }
					Inventory[Slot].amount = Inventory[Slot].amount - Amount

					if Inventory[Slot].amount <= 0 then
						Inventory[Slot] = nil
					end

					Returned = false
				end
			end
		end

		if Item and (Returned or Target == "104" or Slot == "104") then
			TriggerClientEvent("inventory:Update",source)

			local Skinshop = ItemSkinshop(Item)
			if Target == "104" and Skinshop then
				TriggerClientEvent("skinshop:Backpack",source,Skinshop)
			elseif Slot == "104" and Skinshop then
				TriggerClientEvent("skinshop:BackpackRemove",source)
			end
		end

		return true
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRYCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.TakeChest(Passport,Data,Amount,Slot,Target,Save)
	local Returned = true
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount <= 0 then
		return Returned
	end

	local Slot = tostring(Slot)
	local Consult = vRP.GetSrvData(Data,Save)

	if not Consult[Slot] then
		return Returned
	end

	local source = vRP.Source(Passport)
	local Item = Consult[Slot].item
	local Animation = ItemAnim(Item)

	if vRP.MaxItens(Passport,Item,Amount) then
		TriggerClientEvent("inventory:Notify",source,"Atenção","Limite atingido.","vermelho")
		return Returned
	end

	if not vRP.CheckWeight(Passport,Item,Amount) then
		return Returned
	end

	local Target = tostring(Target)
	local Inv = vRP.Inventory(Passport)

	if Inv[Target] then
		if Inv[Target].item == Item and Consult[Slot].amount >= Amount then
			exports["discord"]:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Retirou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item.."\n**[DATA & HORA]:** "..os.date("%d/%m/%Y").." às "..os.date("%H:%M"))

			Inv[Target].amount = Inv[Target].amount + Amount
			Consult[Slot].amount = Consult[Slot].amount - Amount

			if Consult[Slot].amount <= 0 then
				Consult[Slot] = nil
			end

			Returned = false
		end
	else
		if Consult[Slot].amount >= Amount then
			exports["discord"]:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Retirou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item.."\n**[DATA & HORA]:** "..os.date("%d/%m/%Y").." às "..os.date("%H:%M"))

			Inv[Target] = { item = Item, amount = Amount }
			Consult[Slot].amount = Consult[Slot].amount - Amount

			if Consult[Slot].amount <= 0 then
				Consult[Slot] = nil
			end
			
			if Animation then
				vRPC.PersistentBlock(source,Item,Animation)
			end

			if ItemTypeCheck(Item,"Armamento") and vRP.ConsultItem(Passport,Item) then
				TriggerClientEvent("inventory:CreateWeapon",source,Item)
			end

			TriggerClientEvent("inventory:Update",source)

			if Target == "104" then
				local Skinshop = ItemSkinshop(Item)
				if Skinshop then
					TriggerClientEvent("skinshop:Backpack",source,Skinshop)
				end
			end

			Returned = false
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANSLOTCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.CleanSlotChest(Data,Slot,Save)
	local Consult = vRP.GetSrvData(Data,Save)

	if Consult and Consult[Slot] then
		Consult[Slot] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORECHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.StoreChest(Passport,Data,Amount,Weight,Slot,Target,Save,Max)
	local Returned = true
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount <= 0 then
		return Returned
	end

	local Slot = tostring(Slot)
	local Inv = vRP.Inventory(Passport)

	if Inv[Slot] then
		local Item = Inv[Slot].item
		if not Max or not vRP.MaxChest(Data,Item,Amount,Save) then
			local Target = tostring(Target)
			local source = vRP.Source(Passport)
			local Consult = vRP.GetSrvData(Data,Save)

			if (vRP.ChestWeight(Consult) + (ItemWeight(Item) * Amount)) <= Weight then
				local Animation = ItemAnim(Item)
				if Consult[Target] and Inv[Slot] then
					if Item == Consult[Target].item and Inv[Slot].amount >= Amount then
						exports["discord"]:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Guardou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item.."\n**[DATA & HORA]:** "..os.date("%d/%m/%Y").." às "..os.date("%H:%M"))

						Consult[Target].amount = Consult[Target].amount + Amount
						Inv[Slot].amount = Inv[Slot].amount - Amount

						if Inv[Slot].amount <= 0 then
							Inv[Slot] = nil

							if Slot == "104" then
								TriggerClientEvent("inventory:Update",source)

								local Skinshop = ItemSkinshop(Item)
								if Skinshop then
									TriggerClientEvent("skinshop:BackpackRemove",source)
								end
							end

							if Animation and not vRP.ConsultItem(Passport,Item) then
								vRPC.PersistentNone(source,Item)
							end

							if ItemTypeCheck(Item,"Armamento") or ItemTypeCheck(Item,"Arremesso") then
								TriggerClientEvent("inventory:verifyWeapon",source,Item)
							end

							local Execute = ItemExecute(Item)
							if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
								if Execute.Type == "Client" then
									TriggerClientEvent(Execute.Event,source)
								else
									TriggerEvent(Execute.Event,source,Passport)
								end
							end
						end

						Returned = false
					end
				else
					if Inv[Slot] and Inv[Slot].amount >= Amount then
						exports["discord"]:Embed("Chest","**[REF]:** "..Data.."\n**[MODO]:** Guardou\n**[PASSAPORTE]:** "..Passport.."\n**[ITEM]:** "..Amount.."x "..Item.."\n**[DATA & HORA]:** "..os.date("%d/%m/%Y").." às "..os.date("%H:%M"))

						Consult[Target] = { item = Item, amount = Amount }
						Inv[Slot].amount = Inv[Slot].amount - Amount

						if Inv[Slot].amount <= 0 then
							Inv[Slot] = nil

							if Slot == "104" then
								TriggerClientEvent("inventory:Update",source)

								local Skinshop = ItemSkinshop(Item)
								if Skinshop then
									TriggerClientEvent("skinshop:BackpackRemove",source)
								end
							end

							if Animation and not vRP.ConsultItem(Passport,Item) then
								vRPC.PersistentNone(source,Item)
							end

							if ItemTypeCheck(Item,"Armamento") or ItemTypeCheck(Item,"Arremesso") then
								TriggerClientEvent("inventory:verifyWeapon",source,Item)
							end

							local Execute = ItemExecute(Item)
							if Execute and Execute.Event and Execute.Type and not vRP.ConsultItem(Passport,Item) then
								if Execute.Type == "Client" then
									TriggerClientEvent(Execute.Event,source)
								else
									TriggerEvent(Execute.Event,source,Passport)
								end
							end
						end

						Returned = false
					end
				end
			else
				TriggerClientEvent("inventory:Notify",source,"Atenção","Limite de peso atingido.","vermelho")
			end
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATECHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdateChest(Passport,Data,Slot,Target,Amount,Save)
	local Returned = true
	local Slot = tostring(Slot)
	local Passport = parseInt(Passport)
	local Amount = parseInt(Amount,true)
	local Consult = vRP.GetSrvData(Data,Save)

	if Consult[Slot] then
		local Target = tostring(Target)
		if Consult[Target] and Consult[Slot].item == Consult[Target].item then
			if Consult[Slot].amount >= Amount then
				Consult[Slot].amount = Consult[Slot].amount - Amount

				if Consult[Slot].amount <= 0 then
					Consult[Slot] = nil
				end

				Consult[Target].amount = Consult[Target].amount + Amount

				Returned = false
			end
		elseif Consult[Target] then
			local Temp = Consult[Slot]
			Consult[Slot] = Consult[Target]
			Consult[Target] = Temp

			Returned = false
		else
			if Consult[Slot].amount >= Amount then
				Consult[Target] = { item = Consult[Slot].item, amount = Amount }
				Consult[Slot].amount = Consult[Slot].amount - Amount

				if Consult[Slot].amount <= 0 then
					Consult[Slot] = nil
				end

				Returned = false
			end
		end
	end

	return Returned
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARRESTITENS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ArrestItens(Passport)
	local itemsToRemove = {}
	local Passport = parseInt(Passport)
	local Inventory = vRP.Inventory(Passport)

	for _,v in pairs(Inventory) do
		if ItemArrest(v.item) then
			table.insert(itemsToRemove,{ item = v.item, amount = v.amount })
		end
	end

	for _,v in pairs(itemsToRemove) do
		vRP.RemoveItem(Passport,v.item,v.amount,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNTCONTAINER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.MountContainer(Passport,Datatable,Table,Multiplier,Save,Percentage,Dollars)
	local Itens = {}
	local Exists = {}
	local Passport = Passport
	local Multiplier = Multiplier or 1

	if not Percentage or math.random(1000) <= Percentage then
		for Number = 1,Multiplier do
			local Rand = RandPercentage(Table)
			if not Exists[Rand.Item] then
				Exists[Rand.Item] = true

				Itens[tostring(Number)] = {
					item = vRP.SortNameItem(Passport,Rand.Item),
					amount = math.random(Rand.Min,Rand.Max)
				}
			end
		end

		if Dollars then
			local Amount = CountTable(Itens)
			Itens[tostring(Amount + 1)] = {
				item = vRP.SortNameItem(Passport,Dollars.Item),
				amount = parseInt(Dollars.Amount)
			}
		end
	end

	vRP.SetSrvData(Datatable,Itens,Save or false)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SORTNAMEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SortNameItem(Passport,Item)
	local NameItem = Item
	local Passport = Passport
	local CurrentTime = os.time() - 1

	if ItemUnique(Item) then
		local Hash = vRP.GenerateHash(Item)

		if Boxes[Item] then
			local multiplierMin = Boxes[Item].Multiplier.Min
			local multiplierMax = Boxes[Item].Multiplier.Max
			vRP.MountContainer(Passport,Item..":"..Hash,Boxes[Item].List,math.random(multiplierMin,multiplierMax),true)
		end

		NameItem = Item.."-"..CurrentTime.."-"..Hash
	elseif ItemDurability(Item) then
		if ItemTypeCheck(Item,"Armamento") then
			NameItem = Item.."-"..CurrentTime.."-"..MaxRepair.."-"..Passport
		else
			NameItem = Item.."-"..CurrentTime
		end
	elseif ItemLoads(Item) then
		NameItem = Item.."-"..ItemLoads(Item)
	elseif ItemNamed(Item) then
		NameItem = Item.."-"..Passport
	end

	return NameItem
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CALLPOLICE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("CallPolice",function(Table)
	if Table.Percentage and math.random(1000) < Table.Percentage then
		return false
	end

	local source = Table.Source
	local passport = Table.Passport

	if Table.Wanted then
		TriggerEvent("Wanted",source,passport,Table.Wanted)
	end

	if Table.Marker then
		local marker = type(Table.Marker) == "number" and Table.Marker or false
		exports["markers"]:Enter(source,Table.Name,1,passport,marker)
	end

	if Table.Notify then
		TriggerClientEvent("Notify",source,"Departamento Policial","As autoridades foram acionadas.","policia",5000)
	end

	local service = vRP.NumPermission(Table.Permission)
	local coords = Table.Coords or vRP.GetEntityCoords(source)
	for _,officer in pairs(service) do
		async(function()
			vRPC.PlaySound(officer,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")

			local notification = {
				code = Table.Code or 20,
				title = Table.Name,
				x = coords.x,
				y = coords.y,
				z = coords.z,
				vehicle = Table.Vehicle,
				color = Table.Color or 44
			}

			TriggerClientEvent("NotifyPush",officer,notification)
		end)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Permissions(Permission, Column)
    local Consult = exports.oxmysql:single_async("SELECT * FROM permissions WHERE Permission = @Permission LIMIT 1", { Permission = Permission })
    if not Consult then
        exports.oxmysql:query_async("INSERT INTO permissions (Permission, Tags, Announces) VALUES (@Permission, 3, 3)", { Permission = Permission })
        Consult = {}
    end

    local Default = {
        Members = 10,
        Experience = 0,
        Points = 0,
        Bank = 0,
        Premium = 0,
        Tags = 3,
        Announces = 3
    }

    if Column == "Premium" then
        return tonumber(Consult[Column]) or Default[Column]
    end

    return Consult[Column] and tonumber(Consult[Column]) or Default[Column] or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONSUPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PermissionsUpdate(Permission,Column,Mode,Amount)
    local Consult = exports.oxmysql:single_async("SELECT * FROM permissions WHERE Permission = @Permission LIMIT 1", { Permission = Permission })
    if not Consult then
        exports.oxmysql:query_async("INSERT INTO permissions (Permission, Tags, Announces) VALUES (@Permission, 3, 3)", { Permission = Permission })
    end

    if Column == "Premium" then
        local Premium
        if Mode == "+" then
            Premium = tonumber(Amount)
        else
            local Current = tonumber(Consult.Premium) or 0
            Premium = math.max(Current - tonumber(Amount), 0)
        end

        exports.oxmysql:query_async("UPDATE permissions SET Premium = @Value WHERE Permission = @Permission", { Permission = Permission, Value = Premium })
        return
    end

	if not Contains({ "Members","Experience","Premium","Points","Bank" },Column) then
		return
	end

	local Operation = Mode == "+" and "+" or "-"
	local Query = string.format("UPDATE permissions SET %s = GREATEST(%s %s @Amount, 0) WHERE Permission = @Permission",Column,Column,Operation)
    exports.oxmysql:query_async(Query,{ Permission = Permission, Amount = parseInt(Amount) })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GIVEBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GiveBank(Passport,Amount,Notify)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount <= 0 then
		return false
	end

	vRP.Query("characters/AddBank",{ Passport = Passport, Bank = Amount })

	local source = vRP.Source(Passport)
	if Characters[source] then
		Characters[source].Bank = Characters[source].Bank + Amount

		if Notify then
			TriggerClientEvent("inventory:NotifyItem",source,{ "dollar",Amount })
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.RemoveBank(Passport,Amount)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount <= 0 then
		return false
	end

	vRP.Query("characters/RemBank",{ Passport = Passport, Bank = Amount })

	local source = vRP.Source(Passport)
	if Characters[source] then
		Characters[source].Bank = math.max(Characters[source].Bank - Amount,0)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetBank(Passport)
	local Passport = parseInt(Passport)
	local Identity = vRP.Identity(Passport)

	return Identity and Identity.Bank or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTGEMS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PaymentGems(Passport,Amount)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	if Amount > 0 and Characters[source] and vRP.UserGemstone(Characters[source].License) >= Amount then
		vRP.Query("accounts/RemoveGemstone",{ License = Characters[source].License, Gemstone = Amount })
		TriggerClientEvent("hud:RemoveGemstone",source,Amount)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PaymentBank(Passport,Amount,Notify)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	if Amount > 0 and Characters[source] and Characters[source].Bank >= Amount then
		vRP.RemoveBank(Passport,Amount,source)

		if Notify then
			TriggerClientEvent("inventory:NotifyItem",source,{ "dollar",-Amount })
		end

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTFULL
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PaymentFull(Passport,Amount,Notify)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)

	if Amount > 0 then
		return vRP.TakeItem(Passport,"dollar",Amount,Notify) or vRP.PaymentBank(Passport,Amount,Notify)
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WITHDRAWCASH
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WithdrawCash(Passport,Amount)
	local Amount = parseInt(Amount)
	local Passport = parseInt(Passport)
	local source = vRP.Source(Passport)

	if Amount > 0 and Characters[source] and Characters[source].Bank >= Amount then
		vRP.GenerateItem(Passport,"dollar",Amount,true)
		vRP.RemoveBank(Passport,Amount,source)

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("CharacterChosen",function(Passport,source,Creation)
	local Identity = vRP.Identity(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not Datatable or not Identity then return end

	if Creation then
		vRPC.NewLoadSceneStartSphere(source,CreatorCoords.xyz)

		for _,v in pairs(SpawnCoords) do
			vRPC.NewLoadSceneStartSphere(source,v)
		end
	end

	if Datatable.Pos then
		if not Datatable.Pos.x or not Datatable.Pos.y or not Datatable.Pos.z then
			Datatable.Pos = CreatorCoords.xyz
		end
	else
		Datatable.Pos = CreatorCoords.xyz
	end

	Datatable.Armour = Datatable.Armour or 0
	Datatable.Stress = Datatable.Stress or 0
	Datatable.Hunger = Datatable.Hunger or 100
	Datatable.Thirst = Datatable.Thirst or 100
	Datatable.Health = Datatable.Health or 200
	Datatable.Inventory = Datatable.Inventory or {}
	Datatable.Weight = Datatable.Weight or MinimumWeight

	vRPC.Skin(source,Identity.Skin)
	vRP.Armour(source,Datatable.Armour)
	vRPC.SetHealth(source,Datatable.Health,Datatable.Health <= 100)

	if not Creation then
		vRP.Teleport(source,Datatable.Pos.x,Datatable.Pos.y,Datatable.Pos.z)
	end

	TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
	TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
	TriggerClientEvent("hud:Stress",source,Datatable.Stress)

	if Creation then
		TriggerClientEvent("skinshop:Apply",source,vRP.UserData(Passport,"Clothings"),true)
		TriggerClientEvent("barbershop:Apply",source,vRP.UserData(Passport,"Barbershop"))
		TriggerClientEvent("tattooshop:Apply",source,vRP.UserData(Passport,"Tattooshop"))
		TriggerClientEvent("spawn:Finish",source,nil,CreatorCoords.w)
	else
		if Spawns[Passport] and Characters[source].Banned == 0 then
			exports.vrp:Bucket(source,"Exit")
			TriggerClientEvent("spawn:Finish",source)
		else
			TriggerClientEvent("spawn:Finish",source,Datatable.Pos)
		end
	end

	if Characters[source].Banned ~= 0 then
		Player(source).state:set("Banned",true,true)
		exports.vrp:Bucket(source,"Enter",Banned.Route)

		if Banned.Mute then
			TriggerClientEvent("pma-voice:Mute",source,true)
		end
	end

	TriggerClientEvent("vRP:Active",source,Passport,Identity.Name.." "..Identity.Lastname,Datatable.Inventory,Creation)
	TriggerEvent("Connect",Passport,source,not Spawns[Passport])
	GlobalState.Players = GetNumPlayerIndices()

	if not Spawns[Passport] then
        local Barbershop = vRP.UserData(Passport,"Barbershop")
        if type(Barbershop) == "table" and json.encode(Barbershop) == json.encode(BarbershopInit[Identity.Skin]) then
            Wait(6700)
            TriggerClientEvent("barbershop:Open",source,true)
        end

        Spawns[Passport] = true
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("DeleteObject")
AddEventHandler("DeleteObject",function(Index,Weapon)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		if Objects[Passport] and Objects[Passport][Index] then
			Objects[Passport][Index] = nil
		end

		if Weapon and Weapons[Passport] and Weapons[Passport][Weapon] then
			Index = Weapons[Passport][Weapon]
			Weapons[Passport][Weapon] = nil
		end
	end

	TriggerEvent("DeleteObjectServer",Index)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEOBJECTSERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("DeleteObjectServer",function(Index)
	local Networked = NetworkGetEntityFromNetworkId(Index)
	if DoesEntityExist(Networked) and not IsPedAPlayer(Networked) and GetEntityType(Networked) == 3 then
		DeleteEntity(Networked)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEPED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("DeletePed")
AddEventHandler("DeletePed",function(Index)
	local Networked = NetworkGetEntityFromNetworkId(Index)
	if DoesEntityExist(Networked) and not IsPedAPlayer(Networked) and GetEntityType(Networked) == 1 then
		DeleteEntity(Networked)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUGOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("DebugObjects",function(Passport)
	if Objects[Passport] then
		for Index,_ in pairs(Objects[Passport]) do
			TriggerEvent("DeleteObjectServer",Index)
		end

		Objects[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUGWEAPONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("DebugWeapons",function(Passport,Ignore)
	if Weapons[Passport] then
		local source = vRP.Source(Passport)
		for Name,Network in pairs(Weapons[Passport]) do
			TriggerEvent("DeleteObjectServer",Network)

			if not Ignore then
				TriggerClientEvent("inventory:RemoveWeapon",source,Name)
			end
		end

		Weapons[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDAGRADETHIRST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeThirst(Passport,Amount)
	local source = vRP.Source(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not (Datatable and source) then return end

	Datatable.Thirst = math.min(100,(Datatable.Thirst or 0) + parseInt(Amount))

	TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADEHUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeHunger(Passport,Amount)
	local source = vRP.Source(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not (Datatable and source) then return end

	Datatable.Hunger = math.min(100,(Datatable.Hunger or 0) + parseInt(Amount))

	TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADESTRESS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpgradeStress(Passport,Amount)
	local source = vRP.Source(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not (Datatable and source) then return end

	Datatable.Stress = math.min(100,(Datatable.Stress or 0) + parseInt(Amount))

	TriggerClientEvent("hud:Stress",source,Datatable.Stress)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADETHIRST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DowngradeThirst(Passport,Amount)
	local source = vRP.Source(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not (Datatable and source) then return end

	Datatable.Thirst = math.max(0,(Datatable.Thirst or 100) - parseInt(Amount))

	TriggerClientEvent("hud:Thirst",source,Datatable.Thirst)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADETHIRST
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.DowngradeThirst()
	local source = source
	local Passport = vRP.Passport(source)
	local Datatable = vRP.Datatable(Passport)
	if not (Passport and Datatable and Characters[source]) then return end

	Datatable.Thirst = math.max(0,(Datatable.Thirst or 100) - 1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADEHUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DowngradeHunger(Passport,Amount)
	local source = vRP.Source(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not (Datatable and source) then return end

	Datatable.Hunger = math.max(0,(Datatable.Hunger or 100) - parseInt(Amount))

	TriggerClientEvent("hud:Hunger",source,Datatable.Hunger)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADEHUNGER
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.DowngradeHunger()
	local source = source
	local Passport = vRP.Passport(source)
	local Datatable = vRP.Datatable(Passport)

	if not (Passport and Datatable and Characters[source]) then return end

	Datatable.Hunger = math.max(0,(Datatable.Hunger or 100) - 1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNGRADESTRESS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DowngradeStress(Passport,Amount)
	local source = vRP.Source(Passport)
	local Datatable = vRP.Datatable(Passport)
	if not source or not Datatable then return end

	Datatable.Stress = math.max(0,(Datatable.Stress or 0) - math.max(0,parseInt(Amount)))

	TriggerClientEvent("hud:Stress",source,Datatable.Stress)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETHEALTH
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetHealth(source)
	local Ped = GetPlayerPed(source)
	return (Ped and DoesEntityExist(Ped) and Characters[source]) and GetEntityHealth(Ped) or 100
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MODELPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.ModelPlayer(source)
	local Ped = GetPlayerPed(source)
	if Ped and DoesEntityExist(Ped) and Characters[source] then
		return (GetEntityModel(Ped) == GetHashKey("mp_f_freemode_01")) and "mp_f_freemode_01" or "mp_m_freemode_01"
	end

	return "mp_m_freemode_01"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETEXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetExperience(Passport,Work)
	local Datatable = vRP.Datatable(Passport)
	if Datatable then
		Datatable[Work] = Datatable[Work] or 0
	end

	return Datatable and Datatable[Work] or 0,ClassCategory(Datatable and Datatable[Work] or 0)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PUTEXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.PutExperience(Passport,Work,Number)
	local Datatable = vRP.Datatable(Passport)
	if Datatable then
		Datatable[Work] = Datatable[Work] or 0

		local CurrentLevel = Datatable[Work]
		local NewLevel = CurrentLevel + Number
		if UpperLevel[Work] then
			local AfterLevel = ClassCategory(NewLevel)
			local BeforeLevel = ClassCategory(CurrentLevel)
			if BeforeLevel ~= AfterLevel then
				local AfterKey = tostring(AfterLevel)
				if UpperLevel[Work][AfterKey] then
					for _,v in pairs(UpperLevel[Work][AfterKey]) do
						vRP.GenerateItem(Passport,v.Item,math.random(v.Min, v.Max),true)
					end
				end
			end
		end

		Datatable[Work] = NewLevel
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETARMOUR
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SetArmour(source,Amount)
	local Character = Characters[source]
	if not source or not Character then return end

	local Ped = GetPlayerPed(source)
	if DoesEntityExist(Ped) then
		local Armour = math.min(GetPedArmour(Ped) + Amount,100)
		SetPedArmour(Ped,Armour)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ARMOUR
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Armour(source,Amount)
	if not source or not Characters[source] then return end

	local Ped = GetPlayerPed(source)
	if DoesEntityExist(Ped) then
		SetPedArmour(Ped,Amount)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Teleport(source,x,y,z)
	if source and Characters[source] then
		local Ped = GetPlayerPed(source)
		if DoesEntityExist(Ped) then
			SetEntityCoords(Ped,x + 0.0001,y + 0.0001,z + 0.0001,false,false,false,false)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATION
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Creation(source)
	if source and Characters[source] then
		local Ped = GetPlayerPed(source)
		if DoesEntityExist(Ped) then
			SetEntityCoords(Ped,SpawnCoords[math.random(#SpawnCoords)])
			exports.vrp:Bucket(source,"Exit")
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HEADING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Heading(source, Heading)
	local Ped = GetPlayerPed(source)
	if source and Characters[source] and DoesEntityExist(Ped) then
		SetEntityHeading(Ped,Heading)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETENTITYCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.GetEntityCoords(source)
	local Ped = GetPlayerPed(source)
	return (source and Characters[source] and DoesEntityExist(Ped)) and GetEntityCoords(Ped) or vec3(0,0,0)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSIDEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsideVehicle(source)
	local Ped = GetPlayerPed(source)
	return source and Characters[source] and DoesEntityExist(Ped) and GetVehiclePedIsIn(Ped) ~= 0 or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSIDEVEHICLEPASSAGER
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.InsideVehiclePassager(source)
	local Ped = GetPlayerPed(source)
	return source and Characters[source] and DoesEntityExist(Ped) and GetVehiclePedIsIn(Ped) ~= 0 and GetPedInVehicleSeat(GetVehiclePedIsIn(Ped),0) == Ped or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOESENTITYEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.DoesEntityExist(source)
	return source and Characters[source] and DoesEntityExist(GetPlayerPed(source)) or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ISENTITYVISIBLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.IsEntityVisible(source)
	if source and Characters[source] then
		local Ped = GetPlayerPed(source)
		if DoesEntityExist(Ped) and not IsEntityVisible(Ped) then
			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEMODELS
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.CreateModels(Model,x,y,z,Type)
	local Hash = GetHashKey(Model)
	local Route = GetPlayerRoutingBucket(source)
	local Ped = CreatePed(Type or 4,Hash,x,y,z,true,true)

	local CurrentTime = os.time()
	while not DoesEntityExist(Ped) and (os.time() - CurrentTime) < 5 do
		Wait(1)
	end

	if DoesEntityExist(Ped) then
		SetEntityRoutingBucket(Ped,Route)
		SetEntityIgnoreRequestControlFilter(Ped,true)

		return NetworkGetNetworkIdFromEntity(Ped)
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.CreateObject(Model,x,y,z,Weapon,Component)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Model then
		local Hash = GetHashKey(Model)
		local Object = CreateObject(Component or Hash,x,y,z - 2.0,true,true,false)

		local CurrentTime = os.time()
		while not DoesEntityExist(Object) and (os.time() - CurrentTime) < 5 do
			Wait(1)
		end

		if DoesEntityExist(Object) then
			SetEntityIgnoreRequestControlFilter(Object,true)

			local NetObjects = NetworkGetNetworkIdFromEntity(Object)

			if Weapon then
				Weapons[Passport] = Weapons[Passport] or {}
				Weapons[Passport][Weapon] = NetObjects
			else
				Objects[Passport] = Objects[Passport] or {}
				Objects[Passport][NetObjects] = true
			end

			return NetObjects
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUCKET
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Bucket",function(source,Mode,Route)
	local Mode = Mode
	local Route = Route
	local source = source

	if Mode == "Enter" then
		SetPlayerRoutingBucket(source,Route)
		Player(source).state.Route = Route

		if Route > 0 then
			SetRoutingBucketEntityLockdownMode(Route,"strict")
			SetRoutingBucketPopulationEnabled(Route,false)
		end
	else
		SetPlayerRoutingBucket(source,0)
		Player(source).state.Route = 0
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:RELOADWEAPONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:ReloadWeapons",function(source)
	local source = source
	local Passport = vRP.Passport(source)
	local Inventory = vRP.Inventory(Passport)
	if Passport and Inventory then
		for _,v in pairs(Inventory) do
			if ItemTypeCheck(v.item,"Armamento") and not vRP.CheckDamaged(v.item) then
				TriggerClientEvent("inventory:CreateWeapon",source,v.item)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:WAITCHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("vRP:WaitCharacters")
AddEventHandler("vRP:WaitCharacters",function()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		if Characters[source] and Characters[source].Banned == 0 then
			exports.vrp:Bucket(source,"Exit")
		else
			TriggerClientEvent("Notify",source,ServerName,"Restam "..parseInt(Characters[source].Banned).." minutos de reclusão.","server",10000)
		end

		TriggerEvent("vRP:ReloadWeapons",source)

		if Characters[source] and Characters[source].Prison > 0 then
			Player(source).state.Prison = true
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.Barbershop(Barbershop)
    local source = source
    local Ped = GetPlayerPed(source)
    if Ped and DoesEntityExist(Ped) then		
        SetPedHeadBlendData(Ped,Barbershop[1],Barbershop[2],0,Barbershop[5],Barbershop[5],0,Barbershop[3] + 0.0,0,0,false)

        SetPedEyeColor(Ped,Barbershop[4])

        SetPedComponentVariation(Ped,2,Barbershop[10],0,0)
        SetPedHairTint(Ped,Barbershop[11],Barbershop[12])

        SetPedHeadOverlay(Ped,0,Barbershop[7],1.0)
        SetPedHeadOverlayColor(Ped,0,0,0,0)

        SetPedHeadOverlay(Ped,1,Barbershop[22],Barbershop[23] + 0.0)
        SetPedHeadOverlayColor(Ped,1,1,Barbershop[24],Barbershop[24])

        SetPedHeadOverlay(Ped,2,Barbershop[19],Barbershop[20] + 0.0)
        SetPedHeadOverlayColor(Ped,2,1,Barbershop[21],Barbershop[21])

        SetPedHeadOverlay(Ped,3,Barbershop[9],1.0)
        SetPedHeadOverlayColor(Ped,3,0,0,0)

        SetPedHeadOverlay(Ped,4,Barbershop[13],Barbershop[14] + 0.0)
        SetPedHeadOverlayColor(Ped,4,0,0,0)

        SetPedHeadOverlay(Ped,5,Barbershop[25],Barbershop[26] + 0.0)
        SetPedHeadOverlayColor(Ped,5,2,Barbershop[27],Barbershop[27])

        SetPedHeadOverlay(Ped,6,Barbershop[6],1.0)
        SetPedHeadOverlayColor(Ped,6,0,0,0)

        SetPedHeadOverlay(Ped,8,Barbershop[16],Barbershop[17] + 0.0)
        SetPedHeadOverlayColor(Ped,8,2,Barbershop[18],Barbershop[18])

        SetPedHeadOverlay(Ped,9,Barbershop[8],1.0)
        SetPedHeadOverlayColor(Ped,9,0,0,0)

        SetPedFaceFeature(Ped,0,Barbershop[28] + 0.0)
        SetPedFaceFeature(Ped,1,Barbershop[29] + 0.0)
        SetPedFaceFeature(Ped,2,Barbershop[30] + 0.0)
        SetPedFaceFeature(Ped,3,Barbershop[31] + 0.0)
        SetPedFaceFeature(Ped,4,Barbershop[32] + 0.0)
        SetPedFaceFeature(Ped,5,Barbershop[33] + 0.0)
        SetPedFaceFeature(Ped,6,Barbershop[44] + 0.0)
        SetPedFaceFeature(Ped,7,Barbershop[34] + 0.0)
        SetPedFaceFeature(Ped,8,Barbershop[36] + 0.0)
        SetPedFaceFeature(Ped,9,Barbershop[35] + 0.0)
        SetPedFaceFeature(Ped,10,Barbershop[45] + 0.0)
        SetPedFaceFeature(Ped,11,Barbershop[15] + 0.0)
        SetPedFaceFeature(Ped,12,Barbershop[42] + 0.0)
        SetPedFaceFeature(Ped,13,Barbershop[46] + 0.0)
        SetPedFaceFeature(Ped,14,Barbershop[37] + 0.0)
        SetPedFaceFeature(Ped,15,Barbershop[38] + 0.0)
        SetPedFaceFeature(Ped,16,Barbershop[40] + 0.0)
        SetPedFaceFeature(Ped,17,Barbershop[39] + 0.0)
        SetPedFaceFeature(Ped,18,Barbershop[41] + 0.0)
        SetPedFaceFeature(Ped,19,Barbershop[43] + 0.0)

        SetPedHeadOverlay(Ped, 10, Barbershop[47], Barbershop[48] + 0.0)
        SetPedHeadOverlayColor(Ped, 10, 1, Barbershop[49], Barbershop[49])
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	GlobalState.Players = GetNumPlayerIndices()

	TriggerEvent("DebugWeapons",Passport,true)
	TriggerEvent("DebugObjects",Passport)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.UpdatePlaying(Passport,Timer)
    Timer = Timer or 0

    local Consult = vRP.GetSrvData("Playing:"..Passport,true)
    Consult.Online = (Consult.Online or 0) + (Timer - (Playing.Online[Passport] or 0))
    vRP.SetSrvData("Playing:"..Passport,Consult,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TIMEPLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.TimePlaying(Passport)
    local Consult = vRP.GetSrvData("Playing:"..Passport,true)
    return Consult.Online or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WIPEPLAYING
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.WipePlaying()    
    return exports.oxmysql:query_async("UPDATE characters SET Killed = 0, Death = 0", {})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADPLAYED
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    local Timer = os.time()

    while true do
        Wait(10000)
        local Players = vRP.Players()

        for Passport, _ in pairs(Players) do
            Played[Passport] = (Played[Passport] or 0) + (os.time() - Timer)
        end

        if os.time() - Timer >= 1 then
            for Passport, Seconds in pairs(Played) do
                if Seconds > 0 then
                    vRP.UpdatePlaying(Passport,Seconds)
                    Played[Passport] = 0
                end
            end
            Timer = os.time()
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source,First)
	local Passport = tostring(Passport)
    
    if not Playing.Online then
		Playing.Online = {}
	end

	Playing.Online[Passport] = Playing.Online[Passport] or os.time()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect", function(Passport)
	local CurrentTimer = os.time()
	local Passport = tostring(Passport)
	local Consult = vRP.GetSrvData("Playing:"..Passport,true)
	
    if Playing.Online and Playing.Online[Passport] then
		Consult.Online = (Consult.Online or 0) + (CurrentTimer - Playing.Online[Passport])
		Playing.Online[Passport] = nil
	end
	
    if Playing[Passport] and Playing[Passport] > 0 then
        vRP.UpdatePlaying(Passport, Playing[Passport])
        Playing[Passport] = nil
    end

	vRP.SetSrvData("Playing:"..Passport,Consult,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.Battlepass(Passport)
	local Consult = vRP.SimpleData(Passport,"Battlepass")
	if not Consult then
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Battlepass", Information = json.encode(Default) })

		return Default
	end

	return Consult
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.BattlepassBuy(Passport)
	local Consult = vRP.SimpleData(Passport,"Battlepass")
	if Consult then
		Consult.Active = true
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Battlepass", Information = json.encode(Consult) })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSPAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.BattlepassPayment(Passport,Mode,Amount)
	local Consult = vRP.SimpleData(Passport,"Battlepass")
	if not Consult or Consult.Points < Amount then
		return false
	end

	if Mode == "Free" then
		Consult.Free = Consult.Free + 1
	elseif Mode == "Premium" then
		Consult.Premium = Consult.Premium + 1
	end

	Consult.Points = Consult.Points - Amount

	vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Battlepass", Information = json.encode(Consult) })

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASSPOINTS
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.BattlepassPoints(Passport,Amount)
	local Consult = vRP.SimpleData(Passport,"Battlepass")
	if Consult then
		Consult.Points = Consult.Points + Amount
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Battlepass", Information = json.encode(Consult) })
		TriggerClientEvent("Notify",vRP.Source(Passport),"Passe de Batalha","Você recebeu "..Dotted(Amount).." pontos.","verde",5000)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SELECTVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.SelectVehicle(Passport,Name)
	return vRP.SingleQuery("vehicles/selectVehicles",{ Passport = Passport, Vehicle = Name })
end