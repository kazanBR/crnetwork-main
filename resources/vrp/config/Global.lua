-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
MaxRepair = 1
MinimumWeight = 15
PrisonCoords = vec3(1896.15,2604.44,45.75)
CreatorCoords = vec4(242.77,-392.07,46.3,337.33)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANNED
-----------------------------------------------------------------------------------------------------------------------------------------
Banned = {
	Mute = true,
	Route = 9999998,
	Leave = vec3(242.77,-392.07,46.3)
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVERINFO
-----------------------------------------------------------------------------------------------------------------------------------------
Currency = "$"
DiscordBot = true
BaseMode = "steam"
Whitelisted = false
Liberation = "Token"
DisconnectReason = 30
NameDefault = "Indivíduo Indigente"
-----------------------------------------------------------------------------------------------------------------------------------------
-- SERVER
-----------------------------------------------------------------------------------------------------------------------------------------
ServerName = "Creative Network"
ServerLink = "https://creativenetwork.dev.br"
ServerAvatar = "https://i.imgur.com/Yih0uoA.png"
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAINTENANCE
-----------------------------------------------------------------------------------------------------------------------------------------
Maintenance = false
--{
--	["11000010c6d36de"] = true
--}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWNCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
SpawnCoords = {
	vec3(-1039.89,-2740.74,13.88)
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- TEXTUREPACK
-----------------------------------------------------------------------------------------------------------------------------------------
TexturePack = {
	{ Width = 72, Height = 72, Image = "E" },
	{ Width = 72, Height = 72, Image = "H" },
	{ Width = 43, Height = 67, Image = "Races" },
	{ Width = 72, Height = 72, Image = "Normal" },
	{ Width = 72, Height = 72, Image = "Marker" }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- GROUPS
-----------------------------------------------------------------------------------------------------------------------------------------
Groups = {
	Admin = {
		Permission = {
			Admin = true
		},
		Hierarchy = { "Administrador","Diretor","Moderador","Suporte","Ajudante" },
		Name = "Adminstradores",
		Service = true,
		Chat = true,
		Max = 30
	},
	Ouro = {
		Permission = {
			Ouro = true
		},
		Hierarchy = { "Membro" },
		Salary = { 3750 },
		Backpack = { 25 },
		Service = true,
		Block = true
	},
	Prata = {
		Permission = {
			Prata = true
		},
		Hierarchy = { "Membro" },
		Salary = { 2500 },
		Backpack = { 15 },
		Service = true,
		Block = true
	},
	Bronze = {
		Permission = {
			Bronze = true
		},
		Hierarchy = { "Membro" },
		Salary = { 1250 },
		Backpack = { 5 },
		Service = true,
		Block = true
	},
	LSPD = {
		Permission = {
			LSPD = true
		},
		Hierarchy = { "Coronel","Tenente-Coronel","Major","Capitão","1º Tenente","2º Tenente","Aspirante","Subtenente","1º Sargento","2º Sargento","3º Sargento","Cabo","Soldado","Recruta","Delegada" },
		Salary = { 10000,9750,9500,9250,9000,8750,8500,8250,8000,7750,7500,7250,7000,6750,6500 },
		Name = "Los Santos Police Department",
		SecurityCam = true,
		Service = true,
		Type = "Work",
		Markers = 26,
		Banned = true,
		Chat = true
	},
	BCSO = {
		Permission = {
			BCSO = true
		},
		Hierarchy = { "Coronel","Tenente-Coronel","Major","Capitão","1º Tenente","2º Tenente","Aspirante","Subtenente","1º Sargento","2º Sargento","3º Sargento","Cabo","Soldado","Recruta","Delegada" },
		Salary = { 10000,9750,9500,9250,9000,8750,8500,8250,8000,7750,7500,7250,7000,6750,6500 },
		Name = "Blaine County Sheriff Officer",
		SecurityCam = true,
		Service = true,
		Type = "Work",
		Markers = 15,
		Banned = true,
		Chat = true
	},
	SAPR = {
		Permission = {
			SAPR = true
		},
		Hierarchy = { "Coronel","Tenente-Coronel","Major","Capitão","1º Tenente","2º Tenente","Aspirante","Subtenente","1º Sargento","2º Sargento","3º Sargento","Cabo","Soldado","Recruta","Delegada" },
		Salary = { 10000,9750,9500,9250,9000,8750,8500,8250,8000,7750,7500,7250,7000,6750,6500 },
		Name = "San Andreas Park Ranger",
		SecurityCam = true,
		Service = true,
		Type = "Work",
		Markers = 17,
		Banned = true,
		Chat = true
	},
	Paramedico = {
		Permission = {
			Paramedico = true
		},
		Hierarchy = { "Diretor-Geral","Diretor Clínico","Diretor Técnico","Chefe de Corpo Clínico","Médico Supervisor","Médico Cirurgião","Médico Plantonista","Médico Especialista","Médico Clínico","Residente","Enfermeiro","Técnico de Enfermagem","Auxiliar de Enfermagem","Estagiário de Medicina","Estagiário de Enfermagem" },
		Salary = { 8750,8500,8250,8000,7750,7500,7250,7000,6750,6500,6250,6000,5750,5500,5250 },
		Service = true,
		Type = "Work",
		Markers = 34,
		Banned = true,
		Chat = true
	},
	Ballas = {
		Permission = {
			Ballas = true
		},
		Hierarchy = { "Chefe","Subchefe","Conselheiro","General","Veterano","Executor","Operacional","Soldado","Novato","Aspirante" },
		SecurityCam = true,
		Domination = true,
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Vagos = {
		Permission = {
			Vagos = true
		},
		Hierarchy = { "Chefe","Subchefe","Conselheiro","General","Veterano","Executor","Operacional","Soldado","Novato","Aspirante" },
		SecurityCam = true,
		Domination = true,
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Families = {
		Permission = {
			Families = true
		},
		Hierarchy = { "Chefe","Subchefe","Conselheiro","General","Veterano","Executor","Operacional","Soldado","Novato","Aspirante" },
		SecurityCam = true,
		Domination = true,
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Marabunta = {
		Permission = {
			Marabunta = true
		},
		Hierarchy = { "Chefe","Subchefe","Conselheiro","General","Veterano","Executor","Operacional","Soldado","Novato","Aspirante" },
		SecurityCam = true,
		Domination = true,
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Aztecas = {
		Permission = {
			Aztecas = true
		},
		Hierarchy = { "Chefe","Subchefe","Conselheiro","General","Veterano","Executor","Operacional","Soldado","Novato","Aspirante" },
		SecurityCam = true,
		Domination = true,
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Bennys = {
		Permission = {
			Bennys = true
		},
		Hierarchy = { "Dono","Gerente de Oficina","Supervisor de Oficina","Especialista Automotivo","Mecânico Sênior","Mecânico Pleno","Mecânico Júnior","Ajudante de Mecânico","Estagiário de Mecânica" },
		Salary = { 4000,3750,3500,3250,3000,2750,2500,2250,2000 },
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Bahamas = {
		Permission = {
			Bahamas = true
		},
		Hierarchy = { "Dono","Sócio","Gerente","Maitré","Especialista","Cozinheiro Sênior","Cozinheiro Pleno","Cozinheiro Júnior","Ajudante de Cozinha","Estagiário de Cozinha" },
		Salary = { 4000,3750,3500,3250,3000,2750,2500,2250,2000,1750 },
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Restaurante = {
		Permission = {
			Restaurante = true
		},
		Hierarchy = { "Dono","Sócio","Gerente","Maitré","Especialista","Cozinheiro Sênior","Cozinheiro Pleno","Cozinheiro Júnior","Ajudante de Cozinha","Estagiário de Cozinha" },
		Salary = { 4000,3750,3500,3250,3000,2750,2500,2250,2000,1750 },
		Service = true,
		Chest = true,
		Type = "Work"
	},
	Booster = {
		Permission = {
			Booster = true
		},
		Hierarchy = { "Membro" },
		Service = true,
		Salary = { 2500 },
		Block = true
	},
	Freecam = {
		Permission = {
			Freecam = true
		},
		Hierarchy = { "Membro" },
		Service = true,
		Block = true
	},
	Policia = {
		Permission = {
			LSPD = true,
			BCSO = true,
			SAPR = true
		},
		Hierarchy = { "Membro" },
		Block = true
	},
	Emergencia = {
		Permission = {
			LSPD = true,
			BCSO = true,
			SAPR = true,
			Paramedico = true
		},
		Hierarchy = { "Membro" },
		Block = true
	},
	Corredor = {
		Permission = {
			Corredor = true
		},
		Hierarchy = { "Jogador" },
		Markers = 46,
		Block = true
	},
	Boosting = {
		Permission = {
			Boosting = true
		},
		Hierarchy = { "Jogador" },
		Markers = 50,
		Block = true
	},
	-- FUELSTATIONS
	FuelStation01 = {
		Permission = {
			FuelStation01 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation02 = {
		Permission = {
			FuelStation02 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation03 = {
		Permission = {
			FuelStation03 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation04 = {
		Permission = {
			FuelStation04 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation05 = {
		Permission = {
			FuelStation05 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation06 = {
		Permission = {
			FuelStation06 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation07 = {
		Permission = {
			FuelStation07 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation08 = {
		Permission = {
			FuelStation08 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation09 = {
		Permission = {
			FuelStation09 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation10 = {
		Permission = {
			FuelStation10 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation11 = {
		Permission = {
			FuelStation11 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation12 = {
		Permission = {
			FuelStation12 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation13 = {
		Permission = {
			FuelStation13 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation14 = {
		Permission = {
			FuelStation14 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation15 = {
		Permission = {
			FuelStation15 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation16 = {
		Permission = {
			FuelStation16 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation17 = {
		Permission = {
			FuelStation17 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation18 = {
		Permission = {
			FuelStation18 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation19 = {
		Permission = {
			FuelStation19 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation20 = {
		Permission = {
			FuelStation20 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation21 = {
		Permission = {
			FuelStation21 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation22 = {
		Permission = {
			FuelStation22 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation23 = {
		Permission = {
			FuelStation23 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation24 = {
		Permission = {
			FuelStation24 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation25 = {
		Permission = {
			FuelStation25 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation26 = {
		Permission = {
			FuelStation26 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	FuelStation27 = {
		Permission = {
			FuelStation27 = true
		},
		Hierarchy = { "Proprietário","Gerente","Atendente","Frentista" },
		Service = true,
		Type = "Fuel",
		Block = true,
		Max = 3
	},
	-- PROPRIEDADES
	Mansao01 = { -- Exemplo de propriedade com painel/permissão
		Permission = {
			Mansao01 = true
		},
		Name = "Mansão",
		Hierarchy = { "Proprietário","Morador" },
		Type = "Propertys",
		Service = true,
		Max = 5
	},
	-- DOMINATION
	Lester = {
		Permission = {
			Lester = true
		},
		Hierarchy = { "Chefe","Subchefe","Membro" },
		Service = true
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERITENS
-----------------------------------------------------------------------------------------------------------------------------------------
CharacterItens = {
	soda = 2,
	identity = 1,
	hamburger = 2
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- BOXES
-----------------------------------------------------------------------------------------------------------------------------------------
Boxes = {
	treasurebox = {
		Multiplier = { Min = 1, Max = 1 },
		List = {
			{ Item = "dollar", Chance = 100, Min = 4250, Max = 6250 }
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPPERLEVEL
-----------------------------------------------------------------------------------------------------------------------------------------
UpperLevel = {
	Trucker = {
		{
			{ Item = "bandage", Min = 1, Max = 2 },
			{ Item = "advtoolbox", Min = 1, Max = 1 }
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINSHOPINIT
-----------------------------------------------------------------------------------------------------------------------------------------
SkinshopInit = {
	mp_m_freemode_01 = {
		pants = { item = 4, texture = 1 },
		arms = { item = 0, texture = 0 },
		tshirt = { item = 15, texture = 0 },
		torso = { item = 273, texture = 0 },
		vest = { item = 0, texture = 0 },
		shoes = { item = 1, texture = 6 },
		mask = { item = 0, texture = 0 },
		backpack = { item = 0, texture = 0 },
		hat = { item = -1, texture = 0 },
		glass = { item = 0, texture = 0 },
		ear = { item = -1, texture = 0 },
		watch = { item = -1, texture = 0 },
		bracelet = { item = -1, texture = 0 },
		accessory = { item = 0, texture = 0 },
		decals = { item = 0, texture = 0 }
	},
	mp_f_freemode_01 = {
		pants = { item = 4, texture = 1 },
		arms = { item = 14, texture = 0 },
		tshirt = { item = 3, texture = 0 },
		torso = { item = 338, texture = 2 },
		vest = { item = 0, texture = 0 },
		shoes = { item = 1, texture = 6 },
		mask = { item = 0, texture = 0 },
		backpack = { item = 0, texture = 0 },
		hat = { item = -1, texture = 0 },
		glass = { item = 0, texture = 0 },
		ear = { item = -1, texture = 0 },
		watch = { item = -1, texture = 0 },
		bracelet = { item = -1, texture = 0 },
		accessory = { item = 0, texture = 0 },
		decals = { item = 0, texture = 0 }
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARBERSHOPINIT
-----------------------------------------------------------------------------------------------------------------------------------------
BarbershopInit = {
	mp_m_freemode_01 = { 13,25,0,3,0,-1,-1,-1,-1,13,38,38,0,0,0,0,0.5,0,0,1,0,10,1,0,1,0.5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,38 },
	mp_f_freemode_01 = { 13,25,1,3,0,-1,-1,-1,-1,1,38,38,0,0,0,0,1,0,0,1,0,0,0,0,1,0.5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,38 }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THEME
-----------------------------------------------------------------------------------------------------------------------------------------
Theme = {
	shadow = true,
	main = "#5865f2",
	mainText = "#ffffff",
	currency = Currency,
	items = ListItem,
	vehicles = ListVehicles,
	groups = Groups,
	levels = Levels,
	common = "#6fc66a",
	rare = "#6ac6c5",
	epic = "#c66a75",
	legendary = "#c6986a",
	accept = {
		letter = "#dcffe9",
		background = "#3fa466"
	},
	reject = {
		letter = "#ffe8e8",
		background = "#ad4443"
	},
	loading = {
		mode = "dark", -- [ Opções disponíveis: dark,light ],
		model = 2, -- [ Opções disponíveis: 1,2 ],
		progress = true -- [ Opções disponíveis: true, false ],
	},
	chat = {
		Importante = {
			background = "#9d194e",
			letter = "#f7c1d6"
		},
		LSPD = {
			background = "#16468b",
			letter = "#ffffff"
		},
		BCSO = {
			background = "#463939",
			letter = "#ffffff"
		},
		SAPR = {
			background = "#2d402d",
			letter = "#ffffff"
		},
		Paramedico = {
			background = "#9f1918",
			letter = "#ffffff"
		},
		Families = {
			background = "#4d7a06",
			letter = "#ffffff"
		},
		Ballas = {
			background = "#430d8e",
			letter = "#ffffff"
		},
		Vagos = {
			background = "#948209",
			letter = "#ffffff"
		}
	},
	hud = {
		modes = {
			info = 3, -- [ Opções disponíveis: 1,2,3 ],
			icon = "fill", -- [ Opções disponíveis: fill,line ],
			status = 10, -- [ Opções disponíveis: 1 a 12 ],
			vehicle = 3 -- [ Opções disponíveis: 1,2,3 ]
		},
		logo = 75, -- tamanho da logo
		alwaysWanted = true,
		percentage = true,
		icons = "#FFFFFF",
		nitro = "#F69D2A",
		rpm = "#FFFFFF",
		fuel = "#F94C54",
		engine = "#FF4C55",
		health = "#76B984",
		armor = "#A66FED",
		hunger = "#F4B266",
		thirst = "#7FC8F8",
		oxygen = "#38F8F8",
		stress = "#E287C9",
		luck = "#F18A7C",
		dexterity = "#E4E76E",
		repose = "#7FCCC7",
		pointer = "#EF4444",
		progress = {
			background = "#FFFFFF",
			circle = "#5865f2",
			letter = "#FFFFFF"
		}
	},
	notifyitem = {
		add = {
			letter = "#dcffe9",
			background = "#3fa466"
		},
		remove = {
			letter = "#ffe8e8",
			background = "#ad4443"
		}
	},
	pause = {
		premium = true,
		propertys = true,
		store = true,
		battlepass = true,
		boxes = true,
		marketplace = true,
		skinweapon = true,
		ranking = true,
		statistics = true,
		daily = true,
		code = true,
		map = true,
		settings = true,
		hud = true,
		disconnect = true,
		furnitures = true
	},
	scripts = {
		taximeter = {
			main = "#efcf2f",
			mainText = "#120b02"
		}
	},
	inventory = {
		missions = true,
		blueprint = true,
		slots = {
			max = 100,
			default = 25,
			gemstone = { 250,275,300,325,350,375,400,425,450,475,500,525,550,575,600,625,650,675,700,725,750,775,800,825,850,875,900,925,950,975,1000,1025,1050,1075,1100,1125,1150,1175,1200,1225,1250,1275,1300,1325,1350,1375,1400,1425,1450,1475,1500,1525,1550,1575,1600,1625,1650,1675,1700,1725,1750,1775,1800,1825,1850,1875,1900,1925,1950,1975,2000,2025,2050,2075,2100,2125,2150,2175,2200,2225,2250,2275,2300,2325,2350,2375,2400,2425,2450,2475,2500,2525,2550,2575,2600,2625,2650,2675,2700,2725,2750,2775,2800,2825,2850,2875,2900,2925,2950,2975,3000,3025,3050,3075,3100,3125,3150,3175,3200,3225,3250,3275,3300,3325,3350,3375,3400,3425,3450,3475,3500,3525,3550,3575,3600,3625,3650,3675,3700,3725,3750,3775,3800,3825,3850,3875,3900,3925,3950,3975,4000,4025,4050,4075,4100,4125,4150,4175,4200,4225,4250,4275,4300,4325,4350,4375,4400,4425,4450,4475,4500,4525,4550,4575,4600,4625,4650,4675,4700,4725,4750,4775,4800,4825,4850,4875,4900,4925,4950,4975,5000,5025,5050,5075,5100,5125,5150,5175,5200,5225 },
			bank = { 100000,110000,120000,130000,140000,150000,160000,170000,180000,190000,200000,210000,220000,230000,240000,250000,260000,270000,280000,290000,300000,310000,320000,330000,340000,350000,360000,370000,380000,390000,400000,410000,420000,430000,440000,450000,460000,470000,480000,490000,500000,510000,520000,530000,540000,550000,560000,570000,580000,590000,600000,610000,620000,630000,640000,650000,660000,670000,680000,690000,700000,710000,720000,730000,740000,750000,760000,770000,780000,790000,800000,810000,820000,830000,840000,850000,860000,870000,880000,890000,900000,910000,920000,930000,940000,950000,960000,970000,980000,990000,1000000,1010000,1020000,1030000,1040000,1050000,1060000,1070000,1080000,1090000,1100000,1110000,1120000,1130000,1140000,1150000,1160000,1170000,1180000,1190000,1200000,1210000,1220000,1230000,1240000,1250000,1260000,1270000,1280000,1290000,1300000,1310000,1320000,1330000,1340000,1350000,1360000,1370000,1380000,1390000,1400000,1410000,1420000,1430000,1440000,1450000,1460000,1470000,1480000,1490000,1500000,1510000,1520000,1530000,1540000,1550000,1560000,1570000,1580000,1590000,1600000,1610000,1620000,1630000,1640000,1650000,1660000,1670000,1680000,1690000,1700000,1710000,1720000,1730000,1740000,1750000,1760000,1770000,1780000,1790000,1800000,1810000,1820000,1830000,1840000,1850000,1860000,1870000,1880000,1890000,1900000,1910000,1920000,1930000,1940000,1950000,1960000,1970000,1980000,1990000,2000000,2010000,2020000,2030000,2040000,2050000,2060000,2070000,2080000,2090000 }
		}
	},
	eyeColorAtBarbershop = true
}