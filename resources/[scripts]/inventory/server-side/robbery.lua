-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
-- Last: Utilizado apenas em roubos globais e exclusivos para indicar a última ocorrência.
--        Valor padrão: 1

-- Delay: Tempo de espera antes de permitir um novo roubo, usado apenas se diferente do padrão.
--        Valor padrão: 3600 segundos

-- Timer: Duração total do roubo, utilizado somente quando o tempo for diferente do padrão.
--        Valor padrão: 30 segundos

-- Wanted: Duração do estado de procurado após o roubo, aplicado somente se for diferente do padrão.
--        Valor padrão: 60 segundos

-- Cooldown: Define o tipo de cooldown do roubo.
--           Se for uma tabela, o roubo terá múltiplos cooldowns (multiplicador).
--           Se for um timestamp (os.time()), o cooldown será único.

-- Percentage: Probabilidade, em milésimos, de chamar a polícia durante o roubo.

-- Police: Quantidade mínima de policiais em serviço necessária para iniciar o roubo.
--         Utilizado somente quando essa restrição for necessária.

-- Explosion: Flag que indica se o roubo envolve explosões.
--            Utilizado somente quando aplicável.

-- Residual: Tipo de resíduo deixado após o roubo, usado apenas se diferente do padrão.
--           Valor padrão: "Resquício de Línter"

-- Need: Item(s) obrigatório(s) que o jogador deve possuir para iniciar o roubo.
--       Utilizado apenas quando houver essa exigência.
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
local Config = {
	Register = {
		Timer = 15,
		Cooldown = {},
		Percentage = 750,
		Name = "Roubo a Registradora",
		Payment = {
			Multiplier = { Min = 1, Max = 2 },
			Money = { Item = "dirtydollar", Min = 325, Max = 375 },
			List = {
				{ Item = "water", Chance = 100, Min = 1, Max = 2 },
				{ Item = "bandage", Chance = 100, Min = 1, Max = 2 },
				{ Item = "weedclone_0", Chance = 100, Min = 1, Max = 2 }
			}
		},
		Animation = {
			Dict = "oddjobs@shop_robbery@rob_till",
			Name = "loop"
		}
	},
	Container = {
		Wanted = 120,
		Cooldown = {},
		Percentage = 750,
		Name = "Roubo a Container",
		Payment = {
			Multiplier = { Min = 1, Max = 2 },
			Money = { Item = "dirtydollar", Min = 325, Max = 375 },
			List = {
				{ Item = "water", Chance = 100, Min = 1, Max = 2 },
				{ Item = "bandage", Chance = 100, Min = 1, Max = 2 },
				{ Item = "weedclone_0", Chance = 100, Min = 1, Max = 2 }
			}
		},
		Animation = {
			Dict = "oddjobs@shop_robbery@rob_till",
			Name = "loop"
		}
	},
	Eletronic = {
		Police = 5,
		Delay = 300,
		Wanted = 600,
		Cooldown = {},
		Explosion = true,
		Name = "Caixa Eletrônico",
		Need = { Amount = 1, Item = "c4", Consume = true },
		Payment = {
			Money = { Item = "dirtydollar", Min = 325, Max = 375 }
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:ROBBERYACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:RobberyActive",function(Mode,Number)
	local Configuration = Config[Mode]
	if Configuration then
		if type(Configuration.Cooldown) == "table" then
			Configuration.Cooldown[Number] = os.time()
		else
			if Configuration.Last and Configuration.Last == Number then
				Configuration.Cooldown = os.time()
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:ROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("inventory:Robbery")
AddEventHandler("inventory:Robbery",function(Number,Mode)
	local source = source
	local Configuration = Config[Mode]
	local Passport = vRP.Passport(source)

	if not Passport or Active[Passport] or not Configuration then
		return false
	end

	if Configuration.Police and vRP.AmountService("Policia") < Configuration.Police then
		TriggerClientEvent("Notify",source,"Atenção","Contingente indisponível.","amarelo",5000)
		return false
	end

	local RequiredItem = true
	if Configuration.Need then
		RequiredItem = vRP.ConsultItem(Passport,Configuration.Need.Item,Configuration.Need.Amount)
		if not RequiredItem then
			TriggerClientEvent("Notify",source,"Atenção","Precisa de <b>"..Configuration.Need.Amount.."x "..exports.vrp:ItemName(Configuration.Need.Item).."</b>.","amarelo",5000)
			return false
		end
	end

	local CurrentTimer = os.time()
	local Type = type(Configuration.Cooldown)
	local Cooldown = Type == "table" and (Configuration.Cooldown[Number] or 0) or (Configuration.Cooldown or 0)
	if CurrentTimer < Cooldown then
		local Remaining = Cooldown - CurrentTimer
		if not Configuration.Explosion and Remaining >= ((Configuration.Delay or 3600) - 300) and (Type == "table" or (Type == "number" and (Configuration.Last or 1) == Number)) then
			TriggerClientEvent("chest:Open",source,Mode..":"..Number,"Custom",false,true)
		else
			TriggerClientEvent("Notify",source,"Atenção","Aguarde "..CompleteTimers(Remaining)..".","amarelo",5000)
		end

		return false
	else
		if Type == "table" then
			Configuration.Cooldown[Number] = os.time() + (Configuration.Delay or 3600)
		else
			Configuration.Last = Number
			Configuration.Cooldown = os.time() + (Configuration.Delay or 3600)
		end
	end

	Player(source).state.Buttons = true
	Robberys[Passport] = { Mode = Mode, Number = Number }
	Active[Passport] = CurrentTimer + (Configuration.Timer or 30)
	TriggerClientEvent("Progress",source,"Roubando",(Configuration.Timer or 30) * 1000)
	TriggerClientEvent("player:Residual",source,Configuration.Residual or "Resquício de Línter")

	if Configuration.Explosion then
		vRPC.playAnim(source,false,{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer"},true)

		SetTimeout(5000,function()
			vRPC.Destroy(source)
		end)
	elseif Configuration.Animation then
		vRPC.playAnim(source,false,{Configuration.Animation.Dict,Configuration.Animation.Name},true)
	end

	exports.vrp:CallPolice({
		Source = source,
		Passport = Passport,
		Permission = "Policia",
		Name = Configuration.Name,
		Percentage = Configuration.Percentage,
		Wanted = Configuration.Wanted or 60,
		Code = 31,
		Color = 22
	})

	CreateThread(function()
		while Active[Passport] and os.time() < Active[Passport] do
			Wait(100)
		end

		vRPC.Destroy(source)
		Robberys[Passport] = nil
		Player(source).state.Buttons = false

		if Active[Passport] then
			Active[Passport] = nil

			if (not Configuration.Need) or (RequiredItem and (not Configuration.Need.Consume or vRP.TakeItem(Passport,RequiredItem.Item,Configuration.Need.Amount))) then
				local Valuation = math.random(Configuration.Payment.Money.Min,Configuration.Payment.Money.Max)

				if exports.party:DoesExist(Passport,2) then
					Valuation = Valuation * 1.1
				end

				if exports.inventory:Buffs("Dexterity",Passport) then
					Valuation = Valuation * 1.1
				end

				for Permission,Multiplier in pairs({ Ouro = 0.1, Prata = 0.075, Bronze = 0.05 }) do
					if vRP.HasService(Passport,Permission) then
						Valuation = Valuation * (1 + Multiplier)
					end
				end

				if Configuration.Explosion then
					for _,v in pairs(vRPC.Players(source)) do
						async(function()
							TriggerClientEvent("inventory:Explosion",v,Robbery[Number].Coords)
						end)
					end

					exports.inventory:Drops(Passport,source,Configuration.Payment.Money.Item,Valuation,false,Robbery[Number].Coords)
				else
					local Multiplier = math.random(Configuration.Payment.Multiplier.Min,Configuration.Payment.Multiplier.Max)
					if vRP.MountContainer(Passport,Mode..":"..Number,Configuration.Payment.List,Multiplier,false,false,{ Item = Configuration.Payment.Money.Item, Amount = Valuation }) then
						TriggerClientEvent("chest:Open",source,Mode..":"..Number,"Custom",false,true)
					end
				end
			end
		end
	end)
end)