-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
MaxRepair = 1
MinimumWeight = 15
PrisonCoords = vec3(1896.15,2604.44,45.75)
CreatorCoords = vec4(149.57,-158.09,-23.99,303.31)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANNED
-----------------------------------------------------------------------------------------------------------------------------------------
Banned = {
	Mute = true,
	Route = 9999998,
	Leave = vec3(242.71,-392.01,46.30)
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
	{ Width = 19, Height = 20, Image = "E" },
	{ Width = 19, Height = 20, Image = "H" },
	{ Width = 72, Height = 72, Image = "Drop" },
	{ Width = 43, Height = 67, Image = "Races" },
	{ Width = 72, Height = 72, Image = "Normal" },
	{ Width = 102, Height = 20, Image = "EPress" },
	{ Width = 102, Height = 20, Image = "HPress" },
	{ Width = 72, Height = 72, Image = "Selected" },
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
		Block = true,
		Multiplier = {
			Dynamic = 2, -- Bônus de roupas no Dynamic
			Target = 20, -- Bônus de peso no Target
			Weight = 5, -- Redução de peso no inventário
			Work = 10, -- Bônus em trabalhos (Trucker, Bus, Towed, Throwing, Grime, Taxi) - em porcentagem
			Bank = 15, -- Desconto em taxas bancárias - em porcentagem
			PDM = 10, -- Desconto em veículos PDM - em porcentagem
			Garage = 10, -- Desconto em garagens - em porcentagem
			Farmer = { 20, 15 } -- Bônus no Farmer (primeiro valor para venda, segundo para colheita) - em porcentagem
		}
	},
	Prata = {
		Permission = {
			Prata = true
		},
		Hierarchy = { "Membro" },
		Salary = { 2500 },
		Backpack = { 15 },
		Service = true,
		Block = true,
		Multiplier = {
			Dynamic = 2, -- Bônus de roupas no Dynamic
			Target = 20, -- Bônus de peso no Target
			Weight = 5, -- Redução de peso no inventário
			Work = 7.5, -- Bônus em trabalhos (Trucker, Bus, Towed, Throwing, Grime, Taxi) - em porcentagem
			Bank = 15, -- Desconto em taxas bancárias - em porcentagem
			PDM = 10, -- Desconto em veículos PDM - em porcentagem
			Garage = 10, -- Desconto em garagens - em porcentagem
			Farmer = { 20, 15 } -- Bônus no Farmer (primeiro valor para venda, segundo para colheita) - em porcentagem
		}
	},
	Bronze = {
		Permission = {
			Bronze = true
		},
		Hierarchy = { "Membro" },
		Salary = { 1250 },
		Backpack = { 5 },
		Service = true,
		Block = true,
		Multiplier = {
			Dynamic = 2, -- Bônus de roupas no Dynamic
			Target = 20, -- Bônus de peso no Target
			Weight = 5, -- Redução de peso no inventário
			Work = 5, -- Bônus em trabalhos (Trucker, Bus, Towed, Throwing, Grime, Taxi) - em porcentagem
			Bank = 15, -- Desconto em taxas bancárias - em porcentagem
			PDM = 10, -- Desconto em veículos PDM - em porcentagem
			Garage = 10, -- Desconto em garagens - em porcentagem
			Farmer = { 20, 15 } -- Bônus no Farmer (primeiro valor para venda, segundo para colheita) - em porcentagem
		}
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
    mp_m_freemode_01 = { 0,25,0,0,0,-1,-1,-1,-1,3,0,0,0,0,0,0,0,0,0,1,0,3,0.5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 },
    mp_f_freemode_01 = { 13,25,1,3,0,-1,-1,-1,-1,42,0,0,0,0,0,0,1,0,0,1,0,0,0,0,1,0.5,0,0,0,0,0,0,0,0,0,0,-0.5,0,-0.7,0,0,0,0,0,0,-0.49,0,0,0}
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
	groups = Groups,

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
		percentage = true,
		icons = "#FFFFFF",
		nitro = "#f69d2a",
		rpm = "#FFFFFF",
		fuel = "#f94c54",
		engine = "#ff4c55",
		health = "#76B984",
		armor = "#A66FED",
		hunger = "#F4B266",
		thirst = "#7FC8F8",
		oxygen = "#38F8F8",
		stress = "#E287C9",
		luck = "#F18A7C",
		dexterity = "#E4E76E",
		repose = "#7FCCC7",
		pointer = "#ef4444",
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
		disconnect = true
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
			max = 500,
			default = 25,
			gemstone = { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 },
			bank = { 100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000,100000 }
		}
	},
	eyeColorAtBarbershop = true
}