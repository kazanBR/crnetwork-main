-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
MarketplaceTax = 0.03 -- Taxa em cima do valor do item anunciado.
SalaryCooldown = 1800 -- Quantidade de segundos.
HomeBoxes = { 1,2,3 } -- ID das caixas que vão aparecer no inicio
ShopAllDisplay = false -- Mostra a opção "Todos" na Loja
FurnituresAllDisplay = false -- Mostra a opção "Todos" na Loja de Móveis
BattlepassPoints = 500 -- Pontos para resgatar cada item
BattlepassPrice = 10000 -- Valor para comprar o passe
StatisticsMessage = "As informações apresentadas nesta página não devem ser utilizadas dentro do roleplay.<br>Todo o conteúdo aqui exibido tem caráter informativo e de consulta pessoal apenas.<br>O uso dessas informações para obter vantagens, reproduzir situações ou influenciar eventos dentro do servidor é estritamente proibido e pode resultar em punições administrativas." -- Mensagem que aparece nas estatisticas, false para remover
-----------------------------------------------------------------------------------------------------------------------------------------
-- BOXES
-----------------------------------------------------------------------------------------------------------------------------------------
Boxes = {
	{
		Id = 1,
		Name = "Caixa de Diamantes",
		Image = "gemstone",
		Price = 500,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 250,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 500
			},{
				Id = 2,
				Amount = 375,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 250
			},{
				Id = 3,
				Amount = 500,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 200
			},{
				Id = 4,
				Amount = 625,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 150
			},{
				Id = 5,
				Amount = 750,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 100
			},{
				Id = 6,
				Amount = 1000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 5
			},{
				Id = 7,
				Amount = 2000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 4
			},{
				Id = 8,
				Amount = 3000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 3
			},{
				Id = 9,
				Amount = 4000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 2
			},{
				Id = 10,
				Amount = 5000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 1
			},{
				Id = 11,
				Amount = 10000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 0
			},{
				Id = 12,
				Amount = 20000,
				Image = "gemstone",
				Item = "gemstone",
				Name = "Diamante",
				Chance = 0
			}
		}
	},{
		Id = 2,
		Name = "Caixa de Platinas",
		Image = "platinum",
		Price = 1000,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 500,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 300
			},{
				Id = 2,
				Amount = 750,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 200
			},{
				Id = 3,
				Amount = 1000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 175
			},{
				Id = 4,
				Amount = 1250,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 150
			},{
				Id = 5,
				Amount = 1500,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 100
			},{
				Id = 6,
				Amount = 2000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 5
			},{
				Id = 7,
				Amount = 3000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 4
			},{
				Id = 8,
				Amount = 4000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 3
			},{
				Id = 9,
				Amount = 5000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 2
			},{
				Id = 10,
				Amount = 7500,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 1
			},{
				Id = 11,
				Amount = 10000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 0
			},{
				Id = 12,
				Amount = 20000,
				Image = "platinum",
				Item = "platinum",
				Name = "Platina",
				Chance = 0
			}
		}
	},{
		Id = 3,
		Name = "Caixa de Alumínio",
		Image = "aluminum",
		Price = 500,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 500,
				Image = "aluminum",
				Item = "aluminum",
				Name = "Alumínio",
				Chance = 500
			},{
				Id = 2,
				Amount = 750,
				Image = "aluminum",
				Item = "aluminum",
				Name = "Alumínio",
				Chance = 250
			},{
				Id = 3,
				Amount = 1000,
				Image = "aluminum",
				Item = "aluminum",
				Name = "Alumínio",
				Chance = 200
			},{
				Id = 4,
				Amount = 1250,
				Image = "aluminum",
				Item = "aluminum",
				Name = "Alumínio",
				Chance = 150
			},{
				Id = 5,
				Amount = 1500,
				Image = "aluminum",
				Item = "aluminum",
				Name = "Alumínio",
				Chance = 100
			},{
				Id = 6,
				Amount = 2250,
				Image = "aluminum",
				Item = "aluminum",
				Name = "Alumínio",
				Chance = 10
			}
		}
	},{
		Id = 4,
		Name = "Caixa de Vidro",
		Image = "glass",
		Price = 500,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 500,
				Image = "glass",
				Item = "glass",
				Name = "Vidro",
				Chance = 500
			},{
				Id = 2,
				Amount = 750,
				Image = "glass",
				Item = "glass",
				Name = "Vidro",
				Chance = 250
			},{
				Id = 3,
				Amount = 1000,
				Image = "glass",
				Item = "glass",
				Name = "Vidro",
				Chance = 200
			},{
				Id = 4,
				Amount = 1250,
				Image = "glass",
				Item = "glass",
				Name = "Vidro",
				Chance = 150
			},{
				Id = 5,
				Amount = 1500,
				Image = "glass",
				Item = "glass",
				Name = "Vidro",
				Chance = 100
			},{
				Id = 6,
				Amount = 2250,
				Image = "glass",
				Item = "glass",
				Name = "Vidro",
				Chance = 10
			}
		}
	},{
		Id = 5,
		Name = "Caixa de Cobre",
		Image = "copper",
		Price = 500,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 500,
				Image = "copper",
				Item = "copper",
				Name = "Cobre",
				Chance = 500
			},{
				Id = 2,
				Amount = 750,
				Image = "copper",
				Item = "copper",
				Name = "Cobre",
				Chance = 250
			},{
				Id = 3,
				Amount = 1000,
				Image = "copper",
				Item = "copper",
				Name = "Cobre",
				Chance = 200
			},{
				Id = 4,
				Amount = 1250,
				Image = "copper",
				Item = "copper",
				Name = "Cobre",
				Chance = 150
			},{
				Id = 5,
				Amount = 1500,
				Image = "copper",
				Item = "copper",
				Name = "Cobre",
				Chance = 100
			},{
				Id = 6,
				Amount = 2250,
				Image = "copper",
				Item = "copper",
				Name = "Cobre",
				Chance = 10
			}
		}
	},{
		Id = 6,
		Name = "Caixa de Borracha",
		Image = "rubber",
		Price = 500,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 500,
				Image = "rubber",
				Item = "rubber",
				Name = "Borracha",
				Chance = 500
			},{
				Id = 2,
				Amount = 750,
				Image = "rubber",
				Item = "rubber",
				Name = "Borracha",
				Chance = 250
			},{
				Id = 3,
				Amount = 1000,
				Image = "rubber",
				Item = "rubber",
				Name = "Borracha",
				Chance = 200
			},{
				Id = 4,
				Amount = 1250,
				Image = "rubber",
				Item = "rubber",
				Name = "Borracha",
				Chance = 150
			},{
				Id = 5,
				Amount = 1500,
				Image = "rubber",
				Item = "rubber",
				Name = "Borracha",
				Chance = 100
			},{
				Id = 6,
				Amount = 2250,
				Image = "rubber",
				Item = "rubber",
				Name = "Borracha",
				Chance = 10
			}
		}
	},{
		Id = 7,
		Name = "Caixa de Plástico",
		Image = "plastic",
		Price = 500,
		Discount = 1.0,
		Rewards = {
			{
				Id = 1,
				Amount = 500,
				Image = "plastic",
				Item = "plastic",
				Name = "Plástico",
				Chance = 500
			},{
				Id = 2,
				Amount = 750,
				Image = "plastic",
				Item = "plastic",
				Name = "Plástico",
				Chance = 250
			},{
				Id = 3,
				Amount = 1000,
				Image = "plastic",
				Item = "plastic",
				Name = "Plástico",
				Chance = 200
			},{
				Id = 4,
				Amount = 1250,
				Image = "plastic",
				Item = "plastic",
				Name = "Plástico",
				Chance = 150
			},{
				Id = 5,
				Amount = 1500,
				Image = "plastic",
				Item = "plastic",
				Name = "Plástico",
				Chance = 100
			},{
				Id = 6,
				Amount = 2250,
				Image = "plastic",
				Item = "plastic",
				Name = "Plástico",
				Chance = 10
			}
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- WORKS
-----------------------------------------------------------------------------------------------------------------------------------------
Works = {
	Grime = "Grime",
	Taxi = "Taxista",
	Towed = "Impound",
	Dismantle = "Desmanche",
	Delivery = "Entregador",
	Transporter = "Transportador",
	Lumberman = "Lenhador",
	Milkman = "Leiteiro",
	Trucker = "Caminhoneiro",
	Fisherman = "Pescador",
	Driver = "Motorista",
	Traffic = "Traficante",
	Hunting = "Caçador",
	Garbageman = "Lixeiro",
	Throwing = "Entregador de Jornal"
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREMIUM
-----------------------------------------------------------------------------------------------------------------------------------------
Premium = {
	{
		Name = "Ouro",
		Image = "gold",
		Permission = "Ouro",
		Price = 20000,
		Discount = 1.0,
		Duration = 2592000,
		Rewards = {
			{
				Type = "Info",
				Name = "Reduz 20% de quebrar a Lockpick"
			},{
				Type = "Info",
				Name = "Recebe 100 Kilos de peso na mochila"
			},{
				Type = "Info",
				Name = "20% de bonificação nos empregos"
			},{
				Type = "Info",
				Name = "Salário de $10.000 a cada 30 minutos"
			},{
				Type = "Info",
				Name = "75% de desconto em todos os impostos"
			},{
				Type = "Vehicle",
				Name = "Veículo Básico"
			},{
				Type = "Vehicle",
				Name = "Veículo Esportivo"
			}
		},
		Selectables = {
			{
				Name = "Veículo Básico",
				Options = {
					{
						Name = "Panto",
						Index = "panto"
					},{
						Name = "Brioso",
						Index = "brioso"
					}
				}
			},{
				Name = "Veículo Esportivo",
				Options = {
					{
						Name = "Sultan",
						Index = "sultan"
					},{
						Name = "Sultan RS",
						Index = "sultanrs"
					}
				}
			}
		}
	},{
		Name = "Prata",
		Image = "silver",
		Permission = "Prata",
		Price = 10000,
		Discount = 1.0,
		Duration = 2592000,
		Rewards = {
			{
				Type = "Info",
				Name = "Reduz 10% de quebrar a Lockpick"
			},{
				Type = "Info",
				Name = "50 Kilos de peso na mochila"
			},{
				Type = "Info",
				Name = "10% de bonificação nos empregos"
			},{
				Type = "Info",
				Name = "Salário de $5.000 a cada 30 minutos"
			},{
				Type = "Info",
				Name = "50% de desconto em todos os impostos"
			}
		}
	},{
		Name = "Bronze",
		Image = "bronze",
		Permission = "Bronze",
		Price = 5000,
		Discount = 1.0,
		Duration = 2592000,
		Rewards = {
			{
				Type = "Info",
				Name = "Reduz 5% de quebrar a Lockpick"
			},{
				Type = "Info",
				Name = "25 Kilos de peso na mochila"
			},{
				Type = "Info",
				Name = "5% de bonificação nos empregos"
			},{
				Type = "Info",
				Name = "Salário de $2.500 a cada 30 minutos"
			},{
				Type = "Info",
				Name = "25% de desconto em todos os impostos"
			}
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
Propertys = {
	{
		Name = "Fazenda 01",
		Image = "fazenda",
		Permission = "Fazenda",
		Coords = vec3(0.0,0.0,0.0),
		Price = 100000,
		Discount = 1.0,
		Duration = 2592000,
		Category = "Fazendas",
		Rewards = {
			"Textos da descrição. 01",
			"Textos da descrição. 02",
			"Textos da descrição. 03"
		}
	},{
		Name = "Fazenda 02",
		Image = "fazenda",
		Permission = "Fazenda",
		Coords = vec3(0.0,0.0,0.0),
		Price = 100000,
		Discount = 1.0,
		Duration = 2592000,
		Category = "Mansões",
		Rewards = {
			"Textos da descrição. 01",
			"Textos da descrição. 02",
			"Textos da descrição. 03"
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SHOPITENS
-----------------------------------------------------------------------------------------------------------------------------------------
ShopItens = {
	gemstone = {
		Price = 1,
		Discount = 1.0,
		Category = "Diamantes"
	},
	chestgroupp = {
		Price = 25000,
		Discount = 1.0,
		Category = "Grupos"
	},
	chestgroupm = {
		Price = 50000,
		Discount = 1.0,
		Category = "Grupos"
	},
	chestgroupg = {
		Price = 75000,
		Discount = 1.0,
		Category = "Grupos"
	},
	skinshop = {
		Price = 25000,
		Discount = 1.0,
		Category = "Grupos"
	},
	barbershop = {
		Price = 25000,
		Discount = 1.0,
		Category = "Grupos"
	},
	tattooshop = {
		Price = 25000,
		Discount = 1.0,
		Category = "Grupos"
	},
	premiumplate = {
		Price = 5000,
		Discount = 1.0,
		Category = "Veículos"
	},
	namechange = {
		Price = 3000,
		Discount = 1.0,
		Category = "Utilidades"
	},
	diagram = {
		Price = 500,
		Discount = 1.0,
		Category = "Utilidades"
	},
	WEAPON_KATANA = {
		Price = 500,
		Discount = 1.0,
		Category = "Armamentos"
	},
	pickaxeplus = {
		Price = 2500,
		Discount = 1.0,
		Category = "Empregos"
	},
	fishingrodplus = {
		Price = 2500,
		Discount = 1.0,
		Category = "Empregos"
	},
	axeplus = {
		Price = 2500,
		Discount = 1.0,
		Category = "Empregos"
	},
	backpackp = {
		Price = 2000,
		Discount = 1.0,
		Category = "Vestimentas"
	},
	backpackm = {
		Price = 3500,
		Discount = 1.0,
		Category = "Vestimentas"
	},
	backpackg = {
		Price = 5000,
		Discount = 1.0,
		Category = "Vestimentas"
	},
	teddypack = {
		Price = 5000,
		Discount = 1.0,
		Category = "Vestimentas"
	},
	weaponbox = {
		Price = 5000,
		Discount = 1.0,
		Category = "Armamentos"
	},
	ammobox = {
		Price = 3500,
		Discount = 1.0,
		Category = "Armamentos"
	},
	sewingkit = {
		Price = 2500,
		Discount = 1.0,
		Category = "Utilidades"
	},
	seatbelt = {
		Price = 5000,
		Discount = 1.0,
		Category = "Veículos"
	},
	adrenalineplus = {
		Price = 500,
		Discount = 1.0,
		Category = "Medicamentos"
	},
	moneywash = {
		Price = 5000,
		Discount = 1.0,
		Category = "Lavagem"
	},
	moneywashplus = {
		Price = 10000,
		Discount = 0.95,
		Category = "Lavagem"
	},
	moneywashalpha = {
		Price = 20000,
		Discount = 0.90,
		Category = "Lavagem"
	},
	moneywashomega = {
		Price = 100000,
		Discount = 0.85,
		Category = "Lavagem"
	},
	washbattery = {
		Price = 750,
		Discount = 1.0,
		Category = "Lavagem"
	},
	washbleach = {
		Price = 500,
		Discount = 1.0,
		Category = "Lavagem"
	},
	radiomhz = {
		Price = 7500,
		Discount = 1.0,
		Category = "Utilidades"
	},
	a_c_cat_01 = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_husky = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_poodle = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_pug = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_retriever = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_rottweiler = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_shepherd = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	},
	a_c_westy = {
		Price = 5000,
		Discount = 1.0,
		Category = "Domésticos"
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- FURNITURESITENS
-----------------------------------------------------------------------------------------------------------------------------------------
FurnituresItens = {
	furniture_simplebox = {
		Price = 5000,
		Discount = 1.0,
		Category = "Cofres"
	},
	furniture_safebox = {
		Price = 10000,
		Discount = 1.0,
		Category = "Cofres"
	},
	furniture_officebox = {
		Price = 25000,
		Discount = 1.0,
		Category = "Cofres"
	},
	furniture_industrialbox = {
		Price = 50000,
		Discount = 1.0,
		Category = "Cofres"
	},
	furniture_ornamentbox = {
		Price = 75000,
		Discount = 1.0,
		Category = "Cofres"
	},
	furniture_goldenbox = {
		Price = 125000,
		Discount = 1.0,
		Category = "Cofres"
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- BATTLEPASS
-----------------------------------------------------------------------------------------------------------------------------------------
Battlepass = {
	Free = {
		{
			Amount = 1000,
			Item = "dollar"
		},{
			Amount = 1000,
			Item = "dollar"
		},{
			Amount = 1000,
			Item = "dollar"
		},{
			Amount = 1,
			Item = "repairkit01"
		},{
			Amount = 1,
			Item = "repairkit02"
		},{
			Amount = 1,
			Item = "repairkit03"
		},{
			Amount = 1000,
			Item = "dollar"
		},{
			Amount = 1250,
			Item = "dollar"
		},{
			Amount = 1500,
			Item = "dollar"
		},{
			Amount = 1750,
			Item = "dollar"
		},{
			Amount = 1,
			Item = "medkit"
		},{
			Amount = 3,
			Item = "bandage"
		},{
			Amount = 3,
			Item = "analgesic"
		},{
			Amount = 5,
			Item = "gauze"
		},{
			Amount = 1,
			Item = "medicalkey"
		},{
			Amount = 1,
			Item = "utilkey"
		},{
			Amount = 3,
			Item = "toolbox"
		},{
			Amount = 1,
			Item = "advtoolbox"
		},{
			Amount = 1,
			Item = "adrenalineplus"
		},{
			Amount = 100,
			Item = "plastic"
		},{
			Amount = 100,
			Item = "glass"
		},{
			Amount = 100,
			Item = "rubber"
		},{
			Amount = 100,
			Item = "aluminum"
		},{
			Amount = 100,
			Item = "copper"
		},{
			Amount = 275,
			Item = "blueprint_fragment"
		},{
			Amount = 325,
			Item = "blueprint_fragment"
		},{
			Amount = 375,
			Item = "blueprint_fragment"
		},{
			Amount = 1,
			Item = "television"
		},{
			Amount = 1,
			Item = "safependrive"
		},{
			Amount = 1,
			Item = "goldenjug"
		}
	},
	Premium = {
		{
			Amount = 2500,
			Item = "dollar"
		},{
			Amount = 2750,
			Item = "dollar"
		},{
			Amount = 3000,
			Item = "dollar"
		},{
			Amount = 1,
			Item = "repairkit01"
		},{
			Amount = 1,
			Item = "repairkit02"
		},{
			Amount = 1,
			Item = "repairkit03"
		},{
			Amount = 1,
			Item = "repairkit04"
		},{
			Amount = 3,
			Item = "toolbox"
		},{
			Amount = 3,
			Item = "advtoolbox"
		},{
			Amount = 2500,
			Item = "dollar"
		},{
			Amount = 2750,
			Item = "dollar"
		},{
			Amount = 3000,
			Item = "dollar"
		},{
			Amount = 1,
			Item = "backpackp"
		},{
			Amount = 3,
			Item = "adrenalineplus"
		},{
			Amount = 3,
			Item = "diagram"
		},{
			Amount = 3,
			Item = "diagram"
		},{
			Amount = 225,
			Item = "plastic"
		},{
			Amount = 225,
			Item = "glass"
		},{
			Amount = 225,
			Item = "rubber"
		},{
			Amount = 225,
			Item = "aluminum"
		},{
			Amount = 225,
			Item = "copper"
		},{
			Amount = 625,
			Item = "blueprint_fragment"
		},{
			Amount = 725,
			Item = "blueprint_fragment"
		},{
			Amount = 825,
			Item = "blueprint_fragment"
		},{
			Amount = 928,
			Item = "blueprint_fragment"
		},{
			Amount = 1,
			Item = "goldenleopard"
		},{
			Amount = 1,
			Item = "goldenlion"
		},{
			Amount = 1,
			Item = "blueprint_bench"
		},{
			Amount = 1,
			Item = "goldenjug"
		},{
			Amount = 1,
			Item = "moneywash"
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Daily = {
	{
		blue_essence = 10
	},{
		blue_essence = 10
	},{
		blue_essence = 20
	},{
		blue_essence = 20
	},{
		blue_essence = 30
	},{
		blue_essence = 30
	},{
		blue_essence = 40
	},{
		blue_essence = 40
	},{
		blue_essence = 50
	},{
		blue_essence = 50
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEAPONNAMES
-----------------------------------------------------------------------------------------------------------------------------------------
WeaponNames = {
	[-1834847097] = "Adaga",
	[-155058791] = "WEAPON_TECP",
	[-771403250] = "M45A1",
	[133987706] = "Atropelado",
	[-1238556825] = "WEAPON_RAYMINIGUN",
	[101631238] = "Extintor",
	[-1600701090] = "WEAPON_BZGAS",
	[-102323637] = "Garrafa de Vidro",
	[1834241177] = "WEAPON_RAILGUN",
	[1317494643] = "Martelo",
	[324215364] = "Uzi",
	[-1466123874] = "Winchester 1892",
	[-270015777] = "F2000",
	[984333226] = "WEAPON_HEAVYSHOTGUN",
	[911657153] = "Tazer",
	[85055149] = "Tênis",
	[-608341376] = "WEAPON_COMBATMG_MK2",
	[1703483498] = "Bengala Doce",
	[-1169823560] = "WEAPON_PIPEBOMB",
	[1141786504] = "Taco de Golf",
	[1627465347] = "MPF45",
	[-1660422300] = "WEAPON_MG",
	[-879347409] = "WEAPON_REVOLVER_MK2",
	[2144741730] = "WEAPON_COMBATMG",
	[-1074790547] = "AK-74N",
	[1064738331] = "Tijolo",
	[-2009644972] = "CZ52",
	[126349499] = "Bola de Neve",
	[1853742572] = "WEAPON_PRECISIONRIFLE",
	[1171102963] = "Tazer",
	[-1786099057] = "Bastão de Beisebol",
	[-1553120962] = "Atropelado",
	[-538741184] = "Canivete",
	[1198256469] = "WEAPON_RAYCARBINE",
	[-1355376991] = "WEAPON_RAYPISTOL",
	[1305664598] = "WEAPON_GRENADELAUNCHER_SMOKE",
	[-38085395] = "WEAPON_DIGISCANNER",
	[177293209] = "WEAPON_HEAVYSNIPER_MK2",
	[-135142818] = "Jornal",
	[-37975472] = "Granada de Fumaça",
	[-1075685676] = "T54",
	[205991906] = "WEAPON_HEAVYSNIPER",
	[600439132] = "Bola de Baseball",
	[100416529] = "WEAPON_SNIPERRIFLE",
	[1233104067] = "Sinalizador",
	[-618237638] = "WEAPON_EMPLAUNCHER",
	[741814745] = "WEAPON_STICKYBOMB",
	[615608432] = "Coquetel Molotov",
	[961495388] = "AK102",
	[-1420407917] = "WEAPON_PROXMINE",
	[-1813897027] = "Granada",
	[-952879014] = "WEAPON_MARKSMANRIFLE",
	[2132975508] = "QBZ-95",
	[-1658906650] = "WEAPON_MILITARYRIFLE",
	[736523883] = "MP5",
	[1737195953] = "Cassetete",
	[-1312131151] = "Lança Foguete",
	[2138347493] = "Fogos de Artifício",
	[1119849093] = "WEAPON_MINIGUN",
	[-72657034] = "Paraquedas",
	[-1568386805] = "WEAPON_GRENADELAUNCHER",
	[1785463520] = "WEAPON_MARKSMANRIFLE_MK2",
	[317205821] = "WEAPON_AUTOSHOTGUN",
	[-598887786] = "WEAPON_MARKSMANPISTOL",
	[-1716189206] = "Faca",
	[-275439685] = "WEAPON_DBSHOTGUN",
	[1470379660] = "WEAPON_GADGETPISTOL",
	[-494615257] = "WEAPON_ASSAULTSHOTGUN",
	[137902532] = "M1922",
	[2017895192] = "Mossberg 500",
	[-86904375] = "H416",
	[-1951375401] = "Lanterna",
	[487013001] = "M870",
	[-853065399] = "Machado de Batalha",
	[-656458692] = "Soco Inglês",
	[-774507221] = "M16",
	[-1853920116] = "WEAPON_NAVYREVOLVER",
	[1672152130] = "WEAPON_HOMINGLAUNCHER",
	[125959754] = "WEAPON_COMPACTLAUNCHER",
	[1649403952] = "AKS74U",
	[-947031628] = "Scar-H",
	[-102973651] = "Machado",
	[-1810795771] = "Taco de Sinuca",
	[-2067956739] = "Pé de Cabra",
	[-1746263880] = "WEAPON_DOUBLEACTION",
	[-22923932] = "WEAPON_RAILGUNXM3",
	[-1768145561] = "Sig Sauer 556",
	[-1063057011] = "G36C",
	[-1357824103] = "MDR",
	[-2084633992] = "M4A1",
	[-1654528753] = "WEAPON_BULLPUPSHOTGUN",
	[872155819] = "WEAPON_SERVICECARBINE",
	[1593441988] = "G18C",
	[171789620] = "WEAPON_COMBATPDW",
	[940833800] = "Machado de Pedra",
	[-2066285827] = "L85",
	[584646201] = "Koch Vp9",
	[465894841] = "WEAPON_PISTOLXM3",
	[-1121678507] = "MAC-10",
	[727643628] = "WEAPON_CERAMICPISTOL",
	[-1045183535] = "WEAPON_REVOLVER",
	[-581044007] = "Facão",
	[453432689] = "M1911",
	[1198879012] = "WEAPON_FLAREGUN",
	[-619010992] = "Tec-9",
	[-1076751822] = "F57",
	[419712736] = "Chave Inglesa",
	[2024373456] = "MPX",
	[-1716589765] = "Deagle",
	[883325847] = "Galão",
	[1432025498] = "MP133",
	[-1569615261] = "Punhos"
}