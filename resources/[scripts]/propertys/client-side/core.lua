-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("propertys")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Init = {}
local Blips = {}
local Objects = {}
local Inside = false
local Opened = false
local Policed = false
local Stealing = false
local Interior = false
local HoverFy = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCALPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
LocalPlayer.state:set("Propertys",false,false)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	RemoveIpl("propertys_shells")

	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if not IsPedInAnyVehicle(Ped) then
			local Coords = GetEntityCoords(Ped)

			if not Inside then
				for Name,OtherCoords in next,Propertys do
					if #(Coords - OtherCoords) < 1.0 then
						TimeDistance = 1

						if not HoverFy then
							TriggerEvent("hoverfy:Show",{ Key = "E", Title = "Pressione", Legend = "para acessar" })
							HoverFy = Name
						end

						if IsControlJustPressed(1,38) then
							local Dynamic = exports.dynamic
							local Consult = vSERVER.Propertys(Name)

							if Consult then
								if Consult == "Nothing" then
									for Line,v in next,Informations do
										Dynamic:AddMenu(Line,"Informações sobre o interior.",Line)
										Dynamic:AddButton("Credenciais","Máximo <yellow>1</yellow> proprietário e <yellow>3</yellow> adicionais.","","",Line,false)

										if v.Price then
											Dynamic:AddButton("Comprar com Dinheiro","Custo de <yellow>"..Currency..Dotted(v.Price).."</yellow>.","propertys:Buy",Name.."-"..Line.."-Dollar",Line,true)
										end

										if v.Gemstone then
											Dynamic:AddButton("Comprar com Diamantes","Custo de <yellow>"..Dotted(v.Gemstone).."</yellow>.","propertys:Buy",Name.."-"..Line.."-Gemstone",Line,true)
										end
									end

									Dynamic:Open()
								elseif Name == "Hotel" then
									if Consult == Name then
										Interior = Name
										TriggerEvent("propertys:Enter",Name,false)
									end
								elseif not Consult.Owner then
									Interior = Consult.Interior

									if Consult.Key then
										Dynamic:AddButton("Entrar","Adentrar a propriedade.","propertys:Enter",Name,false,false)
										Dynamic:AddButton("Fechadura","Trancar/Destrancar a propriedade.","propertys:Lock",Name,false,true)
									elseif not Consult.Lock then
										Dynamic:AddButton("Entrar","Adentrar a propriedade.","propertys:Enter",Name,false,false)
									else
										Dynamic:AddButton("Invadir","Forçar a fechadura.","propertys:Robbery",Name,false,true)
									end

									Dynamic:Open()
								else
									Interior = Consult.Interior

									Dynamic:AddButton("Entrar","Adentrar a propriedade.","propertys:Enter",Name,false,false)
									Dynamic:AddButton("Cartões","Comprar um novo cartão de acesso.","propertys:Item",Name,false,true)
									Dynamic:AddButton("Fechadura","Trancar/Destrancar a propriedade.","propertys:Lock",Name,false,true)
									Dynamic:AddButton("Credenciais","Reconfigurar os cartões de acesso.","propertys:Credentials",Name,false,true)
									Dynamic:AddButton("Garagem","Adicionar/Reajustar a garagem.","garages:Propertys",Name,false,true)
									Dynamic:AddButton("Vender","Se desfazer da propriedade.","propertys:Sell",Name,false,true)
									Dynamic:AddButton("Transferência","Mudar proprietário.","propertys:Transfer",Name,false,true)
									Dynamic:AddButton("Hipoteca",Consult.Tax,"","",false,false)

									local Display = false
									local InteriorData = Informations[Interior]
									local Valuation = InteriorData and InteriorData.Gemstone or 0
									for Line,v in next,Informations do
										if v.Gemstone and v.Gemstone > Valuation then
											if not Display then
												Dynamic:AddMenu("Interior","Trocar interior da propriedade.","interior")
												Display = true
											end

											Dynamic:AddButton(Line,"Custo de <yellow>"..Dotted(v.Gemstone - Valuation).." diamantes</yellow>.","propertys:Interior",Name.."-"..Line,"interior",true)
										end
									end

									Dynamic:Open()
								end
							elseif Name ~= "Hotel" then
								Dynamic:AddButton("Invadir","Forçar a fechadura.","propertys:Robbery",Name,false,true)
								Dynamic:Open()
							end
						end
					elseif HoverFy and HoverFy == Name then
						TriggerEvent("hoverfy:Hide")
						HoverFy = false
					end
				end
			elseif Inside then
				local PropertyCoords = Propertys[Inside]
				local InternalData = Interior and Internal[Interior]
				if PropertyCoords and InternalData then
					SetPlayerBlipPositionThisFrame(PropertyCoords.x,PropertyCoords.y)

					if Coords.z < (InternalData.Exit.z - 25.0) then
						SetEntityCoordsNoOffset(Ped,InternalData.Exit)
					end

					if Stealing and Policed and Policed <= GetGameTimer() then
						local Pid = PlayerId()
						if GetPedMovementClipset(Ped) ~= -1155413492 or IsPedSprinting(Ped) or MumbleIsPlayerTalking(Pid) then
							vSERVER.Police(PropertyCoords,Coords,Inside)
							Policed = GetGameTimer() + 15000
						end
					end

					for Line,v in next,InternalData do
						if #(Coords - v) <= 1.0 and IsControlJustPressed(1,38) then
							if Line == "Exit" then
								LocalPlayer.state:set("Propertys",false,false)
								SetEntityCoordsNoOffset(Ped,PropertyCoords)
								RemoveIpl("propertys_shells")
								vSERVER.Toggle(Inside,"Exit")
								Interior = false
								Stealing = false
								Policed = false
								Inside = false
							elseif Line == "Vault" and not Stealing and vSERVER.Permission(Inside) then
								Opened = Line
								vRP.playAnim(false,{"amb@prop_human_bum_bin@base","base"},true)

								TriggerEvent("inventory:Open",{
									Type = "Chest",
									Resource = "propertys",
									Right = "Propriedade"
								})
							end
						end
					end

					TimeDistance = 1
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:ENTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("propertys:Enter")
AddEventHandler("propertys:Enter",function(Name,Theft)
	if Theft then
		Stealing = true
		Interior = Theft
		Policed = GetGameTimer() + 15000
		TriggerEvent("player:Residual","Resquício de Línter")
	end

	if HoverFy then
		TriggerEvent("hoverfy:Hide")
		HoverFy = false
	end

	DoScreenFadeOut(0)
	SetEntityVisible(Ped,false)
	SetEntityInvincible(Ped,true)
	FreezeEntityPosition(Ped,true)

	Inside = Name
	local Ped = PlayerPedId()
	TriggerEvent("dynamic:Close")
	RequestIpl("propertys_shells")
	TriggerEvent("hud:Active",false)
	Objects = vSERVER.Toggle(Inside,"Enter")
	LocalPlayer.state:set("Propertys",true,false)
	SetEntityCoordsNoOffset(Ped,Internal[Interior].Exit)

	SetTimeout(5000,function()
		TriggerEvent("hud:Active",true)
		FreezeEntityPosition(Ped,false)
		SetEntityInvincible(Ped,false)
		SetEntityVisible(Ped,true)
		DoScreenFadeIn(2500)
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Primary,Secondary,PrimaryWeight,SecondaryWeight,PrimarySlots = vSERVER.Mount(Inside,Opened)
	if Primary then
		Callback({
			Primary = {
				Data = Primary,
				MaxWeight = PrimaryWeight,
				Slots = PrimarySlots or Theme.inventory.slots.default
			},
			Secondary = {
				Data = Secondary,
				MaxWeight = SecondaryWeight,
				Slots = math.max(CountTable(Secondary),100)
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Close")
AddEventHandler("inventory:Close",function()
	if not Opened then
		return false
	end

	Opened = false
	vRP.Destroy()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	vSERVER.Take(Data.Slot,Data.Amount,Data.Target,Inside,Opened)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Store",function(Data,Callback)
	vSERVER.Store(Data.Item,Data.Slot,Data.Amount,Data.Target,Inside,Opened)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Update",function(Data,Callback)
	vSERVER.Update(Data.Slot,Data.Target,Data.Amount,Inside,Opened)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:BLIPS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("propertys:Blips")
AddEventHandler("propertys:Blips",function()
	if next(Blips) then
		for _,Blip in pairs(Blips) do
			if DoesBlipExist(Blip) then
				RemoveBlip(Blip)
			end
		end

		TriggerEvent("Notify","Propriedades","Marcações desativadas.","default",10000)
		Blips = {}

		return false
	end

	local Markers = vSERVER.Markers()
	for Name,OtherCoords in pairs(Propertys) do
		if Name ~= "Hotel" then
			Blips[Name] = AddBlipForCoord(OtherCoords)

			SetBlipScale(Blips[Name],0.5)
			SetBlipSprite(Blips[Name],374)
			SetBlipAsShortRange(Blips[Name],true)
			SetBlipColour(Blips[Name],Markers[Name] and 35 or 43)
		end
	end

	TriggerEvent("Notify","Propriedades","Marcações ativadas.","default",10000)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEANDMANAGEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function CreateAndManageObject(Selected,Data,Coords,Theft)
	if not Selected or not Data or not Data.Coords then
		return false
	end

	local CurrentEntity = Init[Selected]
	local Distance = Data.Distance or 100.0
	local ObjCoords = vec3(Data.Coords[1],Data.Coords[2],Data.Coords[3])
	if #(Coords - ObjCoords) > Distance then
		if CurrentEntity and DoesEntityExist(CurrentEntity) then
			DestroyObject(Selected,Data)
		end

		return false
	end

	if CurrentEntity and DoesEntityExist(CurrentEntity) then
		return false
	end

	if not LoadModel(Data.Object) then
		return false
	end

	local Options = nil
	local ModelHash = GetHashKey(Data.Object)
	local Entity = CreateObjectNoOffset(ModelHash,ObjCoords.x,ObjCoords.y,ObjCoords.z,false,false,false)
	if not Entity or not DoesEntityExist(Entity) then
		return false
	end

	SetEntityHeading(Entity,Data.Coords[4] or 0.0)
	SetEntityAsMissionEntity(Entity,true,true)
	DecorSetBool(Entity,"CREATIVE_CODE",true)
	FreezeEntityPosition(Entity,true)
	SetEntityLodDist(Entity,1000)
	Init[Selected] = Entity

	if Theft then
		if Inside and not RobberyBlock[Data.Object] and RobberyItens[Data.Object] then
			Options = {
				{
					event = "propertys:RobberyItem",
					label = "Roubar",
					tunnel = "proserver",
					service = Inside.."-"..Selected.."-"..Data.Object
				}
			}
		end
	elseif Inside then
		if Wardrobes[Data.Object] then
			Options = {
				{
					event = "propertys:Wardrobes",
					label = "Armário",
					tunnel = "products",
					service = {
						Name = Inside,
						Selected = Selected,
						Hash = Data.Object
					}
				},{
					event = "skinshop:Open",
					label = "Customizar",
					tunnel = "client"
				},{
					event = "inventory:StoreObjects",
					label = "Guardar",
					tunnel = "server",
					service = "Wardrobe:"..Inside..":"..Selected
				}
			}
		elseif Chests[Data.Object] then
			Options = {
				{
					event = "propertys:Chests",
					label = "Abrir",
					tunnel = "products",
					service = Selected.."-"..Data.Object
				},{
					event = "inventory:StoreObjects",
					label = "Guardar",
					tunnel = "server",
					service = "Vault:"..Inside..":"..Selected
				}
			}
		else
			Options = {
				{
					event = "inventory:StoreObjects",
					label = "Guardar",
					tunnel = "server"
				}
			}
		end
	end

	if Options then
		exports.target:AddCode(Selected,{
			Entity = Entity,
			Model = ModelHash,
			options = Options,
			Distance = 1.75
		})
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function DestroyObject(Selected)
	if not Selected then
		return false
	end

	local Entity = Init[Selected]
	if Entity and DoesEntityExist(Entity) then
		DeleteEntity(Entity)
	end

	if Objects[Selected] then
		exports.target:RemCode(Selected)
		Objects[Selected] = nil
	end

	Init[Selected] = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		if Inside and Inside ~= "Hotel" then
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)

			for Selected,Data in pairs(Objects) do
				CreateAndManageObject(Selected,Data,Coords,Stealing)
			end
		elseif next(Init) then
			for Selected in pairs(Init) do
				DestroyObject(Selected)
			end

			Objects = {}
			Init = {}
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("propertys:Adicionar",function(Selected,Data)
	if not Selected or not Data then
		return false
	end

	Objects[Selected] = Data
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("propertys:Remover",function(Selected)
	DestroyObject(Selected)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:WARDROBES
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("propertys:Wardrobes",function(Data)
	if not Stealing then
		exports.dynamic:AddButton("Guardar","Salvar vestimentas do corpo.","propertys:Clothes:Save",Data.Name.."-"..Data.Selected.."-"..Data.Hash,false,true)

		local Clothes = vSERVER.Clothes(Data.Name,Data.Selected)
		for _,Name in pairs(Clothes) do
			exports.dynamic:AddMenu(Name,"Informações da vestimenta.",Name)
			exports.dynamic:AddButton("Aplicar","Vestir-se com as vestimentas.","propertys:Clothes:Apply",Data.Name.."-"..Data.Selected.."-"..Name,Name,true)
			exports.dynamic:AddButton("Remover","Deletar a vestimenta do armário.","propertys:Clothes:Delete",Data.Name.."-"..Data.Selected.."-"..Name,Name,true,true)
		end

		exports.dynamic:Open()
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:CHESTS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("propertys:Chests",function(Selected)
	if not Stealing and Inside and vSERVER.Permission(Inside) then
		Opened = Selected
		vRP.playAnim(false,{"amb@prop_human_bum_bin@base","base"},true)

		TriggerEvent("inventory:Open",{
			Type = "Chest",
			Resource = "propertys",
			Right = "Propriedade"
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:DYNAMIC
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("propertys:Dynamic",function()
	if not next(Objects) or Stealing or not Inside or not vSERVER.Permission(Inside) then
		return false
	end

	exports.dynamic:AddMenu("Propriedade","Controle completo de seus móveis.","propertys")

	for Selected,Data in pairs(Objects) do
		local Suffix = ""
		if Wardrobes[Data.Object] then
			Suffix = "-Wardrobe"
		elseif Chests[Data.Object] then
			Suffix = "-Vault"
		end

		exports.dynamic:AddButton(exports.vrp:ItemName(Data.Item),"Clique para remover o objeto.","propertys:DynamicButton",Suffix ~= "" and (Selected..Suffix) or Selected,"propertys",false,true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS:DYNAMICBUTTON
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("propertys:DynamicButton",function(Data)
	if not Data or Stealing or not Inside then
		return false
	end

	local Event = nil
	local Mode = SplitTwo(Data)
	local Selected = SplitOne(Data)

	if Mode and (Mode == "Wardrobe" or Mode == "Vault") then
		Event = Mode..":"..Inside..":"..Selected

		TriggerEvent("dynamic:Close")
	end

	TriggerServerEvent("inventory:StoreObjects",Selected,Event)
end)