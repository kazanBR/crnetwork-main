-----------------------------------------------------------------------------------------------------------------------------------------
-- LIST
-----------------------------------------------------------------------------------------------------------------------------------------
local List = {
	markers = {
		Index = "markers",
		Name = "Receptor de Sinal",
		Type = "Consumível",
		Description = "Dispositivo clandestino de rastreamento pessoal, utilizado em operações criminosas, que ao ser instalado transmite sua localização em tempo real para o GPS de todos os membros do grupo selecionado que possuírem um receptor compatível.<br>Possui duração ativa de 5 dias, pode ser removido ou roubado por terceiros e é indicado para perseguições prolongadas, monitoramento estratégico e emboscadas coordenadas.",
		Weight = 0.75,
		Durability = 120,
		Execute = {
			Type = "Server",
			Event = "markers:Exit"
		}
	},
	encryptedkey = {
		Index = "encryptedkey",
		Name = "Chave Criptografada",
		Type = "Comum",
		Weight = 3.5,
		Market = true
	},
	-- BANNED
	["banned_reduce"] = {
		Index = "banned_reduce",
		Name = "Redução de Sentença",
		Description = "Reduz <b>1 minutos</b> do tempo restante.",
		Rarity = "common",
		Type = "Consumível",
		Market = true,
		Delete = true,
		Weight = 0.0
	},
	-- HALLOWEEN
	["halloween_pumpkin"] = {
		Index = "halloween_pumpkin",
		Name = "Abóbora de Halloween",
		Description = "Um enfeite para sua propriedade com a temática de halloween.",
		Rarity = "legendary",
		Type = "Consumível",
		Weight = 5.0
	},
	["halloween_ghost"] = {
		Index = "halloween_ghost",
		Name = "Fantasma de Halloween",
		Description = "Um enfeite para sua propriedade com a temática de halloween.",
		Rarity = "legendary",
		Type = "Consumível",
		Weight = 5.0
	},
	-- ESSÊNCIAS
	["blue_essence"] = {
		Index = "blue_essence",
		Name = "Essência Azul",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["purple_essence"] = {
		Index = "purple_essence",
		Name = "Essência Roxa",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["green_essence"] = {
		Index = "green_essence",
		Name = "Essência Verde",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["red_essence"] = {
		Index = "red_essence",
		Name = "Essência Vermelha",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["pink_essence"] = {
		Index = "pink_essence",
		Name = "Essência Rosa",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	-- ANIMAL
	["a_c_cat_01"] = {
		Index = "a_c_cat_01",
		Name = "Gato",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_husky"] = {
		Index = "a_c_husky",
		Name = "Husky",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_poodle"] = {
		Index = "a_c_poodle",
		Name = "Poodle",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_pug"] = {
		Index = "a_c_pug",
		Name = "Pug",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_retriever"] = {
		Index = "a_c_retriever",
		Name = "Retriever",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_rottweiler"] = {
		Index = "a_c_rottweiler",
		Name = "Rottweiler",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_shepherd"] = {
		Index = "a_c_shepherd",
		Name = "Shepherd",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	["a_c_westy"] = {
		Index = "a_c_westy",
		Name = "Westy",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Market = true,
		Delete = true,
		Rarity = "rare",
		Execute = {
			Type = "Server",
			Event = "animals:Delete"
		}
	},
	-- SPRAYS
	["spray_ballas"] = {
		Index = "sprays",
		Name = "Spray: Ballas",
		Description = "Liberte sua expressão urbana com spray de pichação, sua ferramenta para transformar paredes em telas vibrantes de criatividade.",
		Type = "Consumível",
		Weight = 0.15,
		Market = true,
		Economy = 9725
	},
	["spray_vagos"] = {
		Index = "sprays",
		Name = "Spray: Vagos",
		Description = "Liberte sua expressão urbana com spray de pichação, sua ferramenta para transformar paredes em telas vibrantes de criatividade.",
		Type = "Consumível",
		Weight = 0.15,
		Market = true,
		Economy = 9725
	},
	["spray_families"] = {
		Index = "sprays",
		Name = "Spray: Families",
		Description = "Liberte sua expressão urbana com spray de pichação, sua ferramenta para transformar paredes em telas vibrantes de criatividade.",
		Type = "Consumível",
		Weight = 0.15,
		Market = true,
		Economy = 9725
	},
	-- REPAROS
	["repairkit01"] = {
		Index = "repairkit01",
		Name = "Kit de Reparos",
		Description = "Solucione problemas com facilidade, seja em casa, no carro ou em qualquer lugar, indispensável para manter tudo funcionando perfeitamente.",
		Rarity = "common",
		Type = "Comum",
		Weight = 3.25,
		Economy = 425,
		Recycle = {
			["copper"] = 5,
			["aluminum"] = 7
		}
	},
	["repairkit02"] = {
		Index = "repairkit02",
		Name = "Kit de Reparos",
		Description = "Solucione problemas com facilidade, seja em casa, no carro ou em qualquer lugar, indispensável para manter tudo funcionando perfeitamente.",
		Rarity = "rare",
		Type = "Comum",
		Weight = 3.75,
		Economy = 875,
		Recycle = {
			["scotchtape"] = 1,
			["copper"] = 10,
			["aluminum"] = 12
		}
	},
	["repairkit03"] = {
		Index = "repairkit03",
		Name = "Kit de Reparos",
		Description = "Solucione problemas com facilidade, seja em casa, no carro ou em qualquer lugar, indispensável para manter tudo funcionando perfeitamente.",
		Rarity = "epic",
		Type = "Comum",
		Weight = 4.25,
		Economy = 2225,
		Recycle = {
			["sheetmetal"] = 1,
			["roadsigns"] = 2,
			["scotchtape"] = 2,
			["copper"] = 30,
			["aluminum"] = 35
		}
	},
	["repairkit04"] = {
		Index = "repairkit04",
		Name = "Kit de Reparos",
		Description = "Solucione problemas com facilidade, seja em casa, no carro ou em qualquer lugar, indispensável para manter tudo funcionando perfeitamente.",
		Rarity = "legendary",
		Type = "Comum",
		Weight = 4.75,
		Economy = 4275,
		Recycle = {
			["sheetmetal"] = 3,
			["roadsigns"] = 3,
			["scotchtape"] = 3,
			["copper"] = 50,
			["aluminum"] = 35
		}
	},
	-- MECANICO
	["toolbox"] = {
		Index = "toolbox",
		Name = "Kit de Ferramentas",
		Description = "Um arsenal versátil de ferramentas essenciais para todas as suas necessidades de reparo, com qualidade premium e variedade abrangente, este kit é seu parceiro e do seu veículos.",
		Type = "Consumível",
		Weight = 2.25,
		Max = 3,
		Economy = 925,
		Recycle = {
			["rubber"] = 25,
			["copper"] = 10,
			["aluminum"] = 5
		}
	},
	["advtoolbox"] = {
		Index = "advtoolbox",
		Name = "Conjunto de Ferramentas Mestre",
		Description = "Um arsenal versátil de ferramentas essenciais para todas as suas necessidades de reparo, com qualidade premium e variedade abrangente, este kit é seu parceiro e do seu veículos.",
		Type = "Consumível",
		Weight = 4.75,
		["Charges"] = 3,
		Max = 2,
		Rarity = "common",
		Economy = 2775,
		Recycle = {
			["screwnuts"] = 1,
			["rubber"] = 50,
			["copper"] = 40,
			["aluminum"] = 35
		}
	},
	["plate"] = {
		Index = "plate",
		Name = "Placa Veícular",
		Description = "Embora personalizada e distintiva, desconsidera as normas de trânsito e regulamentos legais, com um design único, destina-se a quem busca evadir-se das regras, mas não é recomendada para uso responsável e ético nas estradas.",
		Type = "Comum",
		Weight = 0.75,
		Economy = 975,
		Recycle = {
			["copper"] = 25,
			["aluminum"] = 20
		}
	},
	["nitro"] = {
		Index = "nitro",
		Name = "Garrafa de Nitro",
		Type = "Consumível",
		Description = "Uma adição emocionante para veículos motorizados, oferece um aumento instantâneo de potência e velocidade, projetado para os entusiastas da velocidade, proporciona uma aceleração surpreendente, elevando a adrenalina e a emoção das corridas e aventuras automobilísticas.",
		Weight = 7.25,
		Economy = 2775,
		Recycle = {
			["screws"] = 1,
			["screwnuts"] = 1,
			["glass"] = 60,
			["copper"] = 25,
			["aluminum"] = 20
		}
	},
	["tyres"] = {
		Index = "tyres",
		Name = "Pneu",
		Type = "Consumível",
		Weight = 2.75,
		Max = 4,
		Economy = 375,
		Recycle = {
			["rubber"] = 20
		}
	},
	-- SUCOS
	["passionjuice"] = {
		Index = "passionjuice",
		Name = "Suco de Maracujá",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		Fridge = true
	},
	["tangejuice"] = {
		Index = "tangejuice",
		Name = "Suco de Tangerina",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["orangejuice"] = {
		Index = "orangejuice",
		Name = "Suco de Laranja",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["applejuice"] = {
		Index = "applejuice",
		Name = "Suco de Maça",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["grapejuice"] = {
		Index = "grapejuice",
		Name = "Suco de Uva",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["lemonjuice"] = {
		Index = "lemonjuice",
		Name = "Suco de Limão",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["bananajuice"] = {
		Index = "bananajuice",
		Name = "Suco de Banana",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["acerolajuice"] = {
		Index = "acerolajuice",
		Name = "Suco de Acerola",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["strawberryjuice"] = {
		Index = "strawberryjuice",
		Name = "Suco de Morango",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["blueberryjuice"] = {
		Index = "blueberryjuice",
		Name = "Suco de Blueberry",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	["coffeemilk"] = {
		Index = "coffeemilk",
		Name = "Café com Leite",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		Fridge = true
	},
	-- DROGAS
	["joint"] = {
		Index = "joint",
		Name = "Cigarro de Cannabis",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 25,
		LostWater = true,
		Water = "Out"
	},
	["weedsack"] = {
		Index = "weedsack",
		Name = "Pacote de Cannabis",
		Type = "Comum",
		Arrest = true,
		Weight = 2.50,
		Market = true,
		Economy = 250
	},
	["cocaine"] = {
		Index = "cocaine",
		Name = "Carreira de Cocaína",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 25,
		LostWater = true,
		Water = "Out"
	},
	["cokesack"] = {
		Index = "cokesack",
		Name = "Pacote de Cocaína",
		Type = "Comum",
		Arrest = true,
		Weight = 2.50,
		Market = true,
		Economy = 250
	},
	["meth"] = {
		Index = "meth",
		Name = "Metanfetamina",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 25,
		LostWater = true,
		Water = "Out"
	},
	["methsack"] = {
		Index = "methsack",
		Name = "Pacote de Metanfetamina",
		Type = "Comum",
		Arrest = true,
		Weight = 2.50,
		Market = true,
		Economy = 250
	},
	["crack"] = {
		Index = "crack",
		Name = "Seringa de Crack",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 375,
		Water = "Out"
	},
	["heroin"] = {
		Index = "heroin",
		Name = "Seringa de Heroína",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 525,
		Water = "Out"
	},
	["metadone"] = {
		Index = "metadone",
		Name = "Seringa de Metadona",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 475,
		Water = "Out"
	},
	["codeine"] = {
		Index = "codeine",
		Name = "Seringa de Codeína",
		Type = "Comum",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 425
	},
	["amphetamine"] = {
		Index = "amphetamine",
		Name = "Seringa de Anfetamina",
		Type = "Comum",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 325
	},
	-- ATTACHS
	["ATTACH_FLASHLIGHT"] = {
		Index = "attach_flashlight",
		Name = "Lanterna Tatica",
		Type = "Attachs",
		Arrest = true,
		Weight = 1.0,
		Market = true,
		Economy = 2125,
		Durability = 72,
		Recycle = {
			["batteryaa"] = 1,
			["glass"] = 35,
			["plastic"] = 30
		}
	},
	["ATTACH_CROSSHAIR"] = {
		Index = "attach_crosshair",
		Name = "Mira Holográfica",
		Type = "Attachs",
		Arrest = true,
		Weight = 1.0,
		Market = true,
		Economy = 2725,
		Durability = 72,
		Recycle = {
			["batteryaa"] = 1,
			["glass"] = 45,
			["plastic"] = 45,
			["copper"] = 10
		}
	},
	["ATTACH_SILENCER"] = {
		Index = "attach_silencer",
		Name = "Silenciador",
		Type = "Attachs",
		Arrest = true,
		Weight = 1.0,
		Market = true,
		Economy = 4725,
		Durability = 72,
		Recycle = {
			["scotchtape"] = 1,
			["insulatingtape"] = 1,
			["emptybottle"] = 1,
			["plastic"] = 60,
			["copper"] = 60
		}
	},
	["ATTACH_MAGAZINE"] = {
		Index = "attach_magazine",
		Name = "Pente Estendido",
		Type = "Attachs",
		Arrest = true,
		Weight = 1.0,
		Market = true,
		Economy = 2225,
		Durability = 72,
		Recycle = {
			["rubber"] = 45,
			["plastic"] = 45,
			["aluminum"] = 10
		}
	},
	["ATTACH_GRIP"] = {
		Index = "attach_grip",
		Name = "Empunhadura",
		Type = "Attachs",
		Arrest = true,
		Weight = 1.0,
		Market = true,
		Economy = 1725,
		Durability = 72,
		Recycle = {
			["scotchtape"] = 1,
			["rubber"] = 25,
			["plastic"] = 25
		}
	},
	-- DOAÇÕES
	["backpackp"] = {
		Index = "backpackp",
		Name = "Mochila Pequena",
		Description = "Compacta e leve, perfeita para carregar o essencial de forma prática, com alças ajustáveis para conforto ao transportar.<br>Aumenta o peso de sua mochila em <epic>50Kg</epic>.",
		Repair = "sewingkit",
		Type = "Comum",
		Market = true,
		Durability = 720,
		Weight = 2.5,
		Delete = true,
		Economy = 100000,
		Rarity = "rare",
		Backpack = 50,
		Skinshop = {
			mp_m_freemode_01 = {
				Model = 123,
				Texture = 0
			},
			mp_f_freemode_01 = {
				Model = 123,
				Texture = 0
			}
		}
	},
	["backpackm"] = {
		Index = "backpackm",
		Name = "Mochila Média",
		Description = "Versátil e compacta, ideal para o dia a dia, oferecendo espaço suficiente para itens essenciais sem ser volumosa, com alças confortáveis para fácil transporte.<br>Aumenta o peso de sua mochila em <epic>75Kg</epic>.",
		Repair = "sewingkit",
		Type = "Comum",
		Market = true,
		Durability = 720,
		Weight = 2.5,
		Delete = true,
		Economy = 150000,
		Rarity = "epic",
		Backpack = 75,
		Skinshop = {
			mp_m_freemode_01 = {
				Model = 130,
				Texture = 0
			},
			mp_f_freemode_01 = {
				Model = 128,
				Texture = 0
			}
		}
	},
	["backpackg"] = {
		Index = "backpackg",
		Name = "Mochila Grande",
		Description = "Espaçosa e funcional, projetada para transportar muitos itens de forma confortável, com alças ajustáveis e compartimentos organizados para facilitar o armazenamento.<br>Aumenta o peso de sua mochila em <epic>100Kg</epic>.",
		Repair = "sewingkit",
		Type = "Comum",
		Market = true,
		Durability = 720,
		Weight = 2.5,
		Delete = true,
		Economy = 200000,
		Rarity = "legendary",
		Backpack = 100,
		Skinshop = {
			mp_m_freemode_01 = {
				Model = 129,
				Texture = 0
			},
			mp_f_freemode_01 = {
				Model = 129,
				Texture = 0
			}
		}
	},
	["teddypack"] = {
		Index = "teddypack",
		Name = "Mochila de Ursinho",
		Description = "Adorável bolsa infantil, feita de material macio e peludo, com uma carinha sorridente bordada na frente e orelhas tridimensionais, é prática e encantadora ao mesmo tempo.<br>Aumenta o peso de sua mochila em <epic>100Kg</epic>.",
		Repair = "sewingkit",
		Type = "Comum",
		Market = true,
		Durability = 720,
		Weight = 2.5,
		Delete = true,
		Economy = 200000,
		Rarity = "legendary",
		Backpack = 100,
		Skinshop = {
			mp_m_freemode_01 = {
				Model = 131,
				Texture = 0
			},
			mp_f_freemode_01 = {
				Model = 131,
				Texture = 0
			}
		}
	},
	["WEAPON_KATANA"] = {
		Index = "katana",
		Name = "Katana",
		Type = "Armamento",
		Arrest = true,
		Repair = "repairkit01",
		Durability = 240,
		Weight = 1.75,
		Delete = true,
		Economy = 5000,
		Market = true,
		Rarity = "legendary"
	},
	["adrenalineplus"] = {
		Index = "adrenaline",
		Name = "Adrenalina ++",
		Description = "Restaura o tempo ao ser ajudado com <common>Adrenalina</common>.",
		Type = "Comum",
		Weight = 0.25,
		Market = true,
		Delete = true,
		Economy = 10000,
		Rarity = "legendary"
	},
	["seatbelt"] = {
		Index = "seatbelt",
		Name = "Cinto de Corrida",
		Type = "Consumível",
		Weight = 5.75,
		Delete = true,
		Economy = 100000,
		Rarity = "legendary"
	},
	["sewingkit"] = {
		Index = "sewingkit",
		Name = "Kit de Costura",
		Description = "Utilizado para reparar mochilas <common>Pequenas</common>, <common>Médias</common> e <common>Grandes</common>.",
		Type = "Comum",
		Weight = 0.55,
		Delete = true,
		Economy = 50000,
		Rarity = "legendary"
	},
	["diagram"] = {
		Index = "diagram",
		Name = "Diagrama",
		Description = "Aumenta <common>10Kg</common> no peso do compartimento.",
		Type = "Comum",
		Weight = 0.75,
		Delete = true,
		Economy = 10000,
		Rarity = "legendary"
	},
	["gemstone"] = {
		Index = "gemstone",
		Name = "Diamante",
		Type = "Consumível",
		Weight = 0.0,
		Delete = true,
		Economy = 20,
		Rarity = "legendary"
	},
	["fishingrodplus"] = {
		Index = "fishingrod",
		Name = "Vara de Pescar ++",
		Description = "Companheira ideal para os amantes da pesca, seja em água doce ou salgada, com sua construção leve e resistente, proporciona equilíbrio perfeito e sensibilidade para detectar até os mais sutis movimentos dos peixes, seja para pescadores iniciantes ou experientes, esta vara é a escolha confiável para horas de diversão e sucesso nas pescarias.",
		Repair = "repairkit04",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.75,
		Delete = true,
		Economy = 50000,
		Rarity = "legendary",
		Water = "In"
	},
	["pickaxeplus"] = {
		Index = "pickaxe",
		Name = "Picareta ++",
		Description = "Ferramenta versátil e resistente, projetada para lidar com uma variedade de tarefas, com sua construção robusta e design ergonômico, oferece conforto e eficiência em cada movimento, seja para escavação no jardim, trabalhos de construção ou aventuras ao ar livre, essa picareta é a escolha confiável para enfrentar desafios com facilidade e precisão.",
		Repair = "repairkit04",
		Type = "Comum",
		Durability = 720,
		Weight = 2.75,
		Delete = true,
		Economy = 50000,
		Rarity = "legendary"
	},
	["axeplus"] = {
		Index = "axe",
		Name = "Machadinha ++",
		Description = "Ferramenta robusta e confiável para os desafios mais exigentes, construído com materiais de alta qualidade e design ergonômico, proporciona precisão e potência em cada golpe, ideal para cortar lenha, realizar trabalhos de construção ou aventuras ao ar livre, é o companheiro perfeito para qualquer tarefa que exija força e eficiência.",
		Repair = "repairkit04",
		Type = "Comum",
		Durability = 720,
		Weight = 2.75,
		Delete = true,
		Economy = 50000,
		Rarity = "legendary"
	},
	["lockpickplus"] = {
		Index = "lockpickplus",
		Name = "Gazua ++",
		Description = "Ferramenta fina e flexível, frequentemente feita de metal, usada para abrir fechaduras sem a chave correspondente, é uma ferramenta comum entre profissionais de segurança e em situações de emergência.",
		Repair = "repairkit04",
		Type = "Comum",
		Durability = 720,
		Weight = 1.25,
		Delete = true,
		Economy = 50000,
		Rarity = "legendary"
	},
	["premiumplate"] = {
		Index = "platepremium",
		Name = "Placa Customizada",
		Type = "Consumível",
		Description = "Uma escolha ideal para quem busca expressar sua individualidade enquanto trafega pelas estradas, feita com materiais de qualidade e design exclusivo, ela adiciona um toque único ao veículo de seu proprietário, sem comprometer a conformidade com as normas de trânsito.",
		Weight = 0.0,
		Delete = true,
		Economy = 100000,
		Rarity = "legendary"
	},
	["instagram"] = {
		Index = "instagram",
		Name = "Seguidores InstaPic",
		Type = "Consumível",
		Description = "Adiciona 100 seguidores no instapic.",
		Weight = 0.0,
		Delete = true,
		Economy = 80000,
		Rarity = "legendary"
	},
	["namechange"] = {
		Index = "namechange",
		Name = "Cartão de Nome",
		Type = "Consumível",
		Description = "Modifica o nome.",
		Weight = 0.0,
		Delete = true,
		Economy = 60000,
		Rarity = "legendary"
	},
	["mapgps"] = {
		Index = "mapgps",
		Name = "Mapa Adaptativo",
		Description = "Um dispositivo inteligente que, ao ser utilizado, ativa o gps no canto da tela, permitindo ao usuário visualizar melhor o terreno ao redor, rotas e a localização de pontos importantes. Ideal para navegação em áreas desconhecidas ou para ganhar vantagem tática em missões.",
		Type = "Consumível",
		Durability = 72,
		Weight = 0.0,
		Delete = true,
		Economy = 50000,
		Rarity = "legendary",
		Execute = {
			Type = "Client",
			Event = "hud:Radaroff"
		}
	},
	["radiomhz"] = {
		Index = "radiomhz",
		Name = "Frequência Mhz",
		Type = "Consumível",
		Description = "Transceptor compacto e poderoso que oferece uma frequência de rádio exclusiva para comunicação segura entre membros do seu grupo, ideal para operações discretas em ambientes onde privacidade é essencial.",
		Weight = 0.0,
		Delete = true,
		Economy = 100000,
		Rarity = "legendary"
	},
	["barbershop"] = {
		Index = "barbershop",
		Name = "Barbearia",
		Type = "Consumível",
		Description = "Define uma posição no mapa onde a <epic>Barbearia</epic> poderá ser acessada.",
		Weight = 0.0,
		Delete = true,
		Economy = 500000,
		Rarity = "legendary"
	},
	Skinshop = {
		Index = "skinshop",
		Name = "Loja de Roupas",
		Type = "Consumível",
		Description = "Define uma posição no mapa onde a <epic>Loja de Roupas</epic> poderá ser acessada.",
		Weight = 0.0,
		Delete = true,
		Economy = 500000,
		Rarity = "legendary"
	},
	["tattooshop"] = {
		Index = "tattooshop",
		Name = "Loja de Tatuagem",
		Type = "Consumível",
		Description = "Define uma posição no mapa onde a <epic>Loja de Tatuagem</epic> poderá ser acessada.",
		Weight = 0.0,
		Delete = true,
		Economy = 500000,
		Rarity = "legendary"
	},
	-- NAMEDS
	["alliance"] = {
		Index = "alliance",
		Name = "Aliança",
		Type = "Comum",
		Market = true,
		Weight = 0.0,
		Named = true
	},
	["alliance2"] = {
		Index = "alliance2",
		Name = "Aliança de Diamante",
		Type = "Comum",
		Description = "<epic>Este item não pode ser roubado.</epic> Uma aliança luxuosa cravejada com um <epic>diamante brilhante</epic>. Símbolo de compromisso eterno ou riqueza extrema.",
		Market = true,
		Weight = 0.0,
		Named = true,
		Rarity = "legendary",
		Delete = true
	},
	["alliance3"] = {
		Index = "alliance3",
		Name = "Porta-Aliança de Diamante",
		Description = "<epic>Este item não pode ser roubado e, ao ser utilizado no alt + Relacionamento, gera dois itens que não podem ser roubados.</epic> Um pequeno estojo luxuoso, usado para guardar alianças de valor inestimável.",
		Type = "Comum",
		Weight = 0.0,
		Rarity = "legendary",
		Delete = true
	},
	["identity"] = {
		Index = "identity",
		Name = "Passaporte",
		Type = "Comum",
		Weight = 0.0,
		Named = true,
		Market = true,
		Delete = true
	},
	-- COMPONENTES
	["circuit"] = {
		Index = "circuit",
		Name = "Circuito Eletrônico",
		Type = "Consumível",
		Arrest = true,
		Durability = 24,
		Weight = 0.75,
		LostWater = true,
		Economy = 4725
	},
	["latex"] = {
		Index = "latex",
		Name = "Frasco de Látex",
		Type = "Comum",
		Weight = 1.25,
		Economy = 175
	},
	["sand"] = {
		Index = "sand",
		Name = "Areia",
		Type = "Comum",
		Weight = 0.225,
		Economy = 20
	},
	["bauxite"] = {
		Index = "bauxite",
		Name = "Minério de Bauxita",
		Type = "Comum",
		Weight = 0.225,
		Economy = 50
	},
	["chalcopyrite"] = {
		Index = "chalcopyrite",
		Name = "Calcopirita",
		Type = "Comum",
		Weight = 0.225,
		Economy = 50
	},
	["plastic"] = {
		Index = "plastic",
		Name = "Plástico",
		Type = "Comum",
		Weight = 0.045,
		Economy = 8
	},
	["glass"] = {
		Index = "glass",
		Name = "Vidro",
		Type = "Comum",
		Weight = 0.045,
		Economy = 8
	},
	["rubber"] = {
		Index = "rubber",
		Name = "Borracha",
		Type = "Comum",
		Weight = 0.045,
		Economy = 8
	},
	["aluminum"] = {
		Index = "aluminum",
		Name = "Alumínio",
		Type = "Comum",
		Weight = 0.045,
		Economy = 10
	},
	["copper"] = {
		Index = "copper",
		Name = "Cobre",
		Type = "Comum",
		Weight = 0.045,
		Economy = 10
	},
	["sulfuric"] = {
		Index = "sulfuric",
		Name = "Ácido Sulfúrico",
		Type = "Consumível",
		Weight = 0.45,
		Economy = 75
	},
	["acetone"] = {
		Index = "acetone",
		Name = "Acetona",
		Type = "Comum",
		Weight = 0.25,
		Economy = 55
	},
	["saline"] = {
		Index = "saline",
		Name = "Soro Fisiológico",
		Type = "Comum",
		Weight = 0.35,
		Economy = 35
	},
	["alcohol"] = {
		Index = "alcohol",
		Name = "Álcool",
		Type = "Comum",
		Weight = 0.55,
		Economy = 45
	},
	["gunpowder"] = {
		Index = "gunpowder",
		Name = "Frasco de Pólvora",
		Type = "Comum",
		Weight = 0.10,
		Economy = 125,
		Arrest = true
	},
	["pistolbody"] = {
		Index = "pistolbody",
		Name = "Corpo de Pistola",
		Type = "Comum",
		Arrest = true,
		Weight = 0.75,
		Market = true,
		Economy = 275,
		Recycle = {
			["copper"] = 6,
			["aluminum"] = 7
		}
	},
	["smgbody"] = {
		Index = "smgbody",
		Name = "Corpo de Sub",
		Type = "Comum",
		Arrest = true,
		Weight = 0.75,
		Market = true,
		Economy = 525,
		Recycle = {
			["copper"] = 15,
			["aluminum"] = 10
		}
	},
	["riflebody"] = {
		Index = "riflebody",
		Name = "Corpo de Rifle",
		Type = "Comum",
		Arrest = true,
		Weight = 0.75,
		Market = true,
		Economy = 975,
		Recycle = {
			["metalspring"] = 1,
			["aluminum"] = 5
		}
	},
	["scrapmetal"] = {
		Index = "scrapmetal",
		Name = "Sucata de Metal",
		Type = "Comum",
		Weight = 0.0,
		Economy = 1
	},
	["blueprint_fragment"] = {
		Index = "blueprint_fragment",
		Name = "Fragmento de Aprendizado",
		Type = "Comum",
		Weight = 0.0
	},
	["metalspring"] = {
		Index = "metalspring",
		Name = "Mola de Metal",
		Type = "Comum",
		Weight = 0.35,
		Economy = 425,
		Recycle = {
			["copper"] = 8,
			["aluminum"] = 10
		}
	},
	["techtrash"] = {
		Index = "techtrash",
		Name = "Lixo Eletrônico",
		Type = "Comum",
		Weight = 0.65,
		LostWater = true,
		Economy = 95,
		Recycle = {
			["copper"] = 2,
			["aluminum"] = 2
		}
	},
	["tarp"] = {
		Index = "tarp",
		Name = "Lona",
		Type = "Comum",
		Weight = 0.60,
		Economy = 65,
		Recycle = {
			["plastic"] = 3
		}
	},
	["sheetmetal"] = {
		Index = "sheetmetal",
		Name = "Chapa de Metal",
		Type = "Comum",
		Weight = 0.65,
		Economy = 65,
		Recycle = {
			["aluminum"] = 3
		}
	},
	["fabric"] = {
		Index = "fabric",
		Name = "Tecido",
		Type = "Comum",
		Weight = 0.001
	},
	["ironfilings"] = {
		Index = "ironfilings",
		Name = "Limalha de Ferro",
		Type = "Comum",
		Market = true,
		Weight = 0.001
	},
	["gear"] = {
		Index = "gear",
		Name = "Engrenagem",
		Type = "Comum",
		Weight = 0.75,
		Economy = 125,
		Recycle = {
			["aluminum"] = 5
		}
	},
	["roadsigns"] = {
		Index = "roadsigns",
		Name = "Placas de Trânsito",
		Type = "Comum",
		Weight = 0.60,
		Economy = 65,
		Recycle = {
			["copper"] = 3
		}
	},
	["explosives"] = {
		Index = "explosives",
		Name = "Explosivos",
		Type = "Comum",
		Arrest = true,
		Weight = 0.45,
		LostWater = true,
		Economy = 225,
		Recycle = {
			["gunpowder"] = 1
		}
	},
	["c4"] = {
		Index = "c4",
		Name = "Explosivo C4",
		Type = "Comum",
		Market = true,
		Arrest = true,
		Weight = 1.25,
		LostWater = true,
		Economy = 1625,
		Recycle = {
			["gunpowder"] = 5,
			["plastic"] = 10
		}
	},
	["wheat"] = {
		Index = "wheat",
		Name = "Trigo",
		Type = "Comum",
		Weight = 0.05,
		Economy = 5
	},
	["scotchtape"] = {
		Index = "scotchtape",
		Name = "Fita Adesiva",
		Type = "Comum",
		Weight = 0.15,
		Economy = 45
	},
	["insulatingtape"] = {
		Index = "insulatingtape",
		Name = "Fita Isolante",
		Type = "Comum",
		Weight = 0.15,
		Economy = 55
	},
	["rammemory"] = {
		Index = "rammemory",
		Name = "Memória RAM",
		Type = "Comum",
		Weight = 0.45,
		Economy = 375,
		LostWater = true
	},
	["powersupply"] = {
		Index = "powersupply",
		Name = "Fonte de Alimentação",
		Type = "Comum",
		Weight = 2.25,
		Economy = 475,
		LostWater = true
	},
	["processorfan"] = {
		Index = "processorfan",
		Name = "Ventoinha do Processador",
		Type = "Comum",
		Weight = 0.95,
		Economy = 325,
		LostWater = true
	},
	["processor"] = {
		Index = "processor",
		Name = "Processador",
		Type = "Comum",
		Weight = 0.65,
		Economy = 725,
		LostWater = true
	},
	["screws"] = {
		Index = "screws",
		Name = "Parafusos",
		Type = "Comum",
		Weight = 0.45,
		Economy = 45
	},
	["screwnuts"] = {
		Index = "screwnuts",
		Name = "Porcas de Parafuso",
		Type = "Comum",
		Weight = 0.45,
		Economy = 45
	},
	["videocard"] = {
		Index = "videocard",
		Name = "Placa de Vídeo",
		Type = "Comum",
		Weight = 4.25,
		Economy = 4225,
		LostWater = true
	},
	["television"] = {
		Index = "television",
		Name = "Televisão",
		Description = "Uma experiência visual imersiva equipada com tecnologia LED para cores vibrantes e detalhes nítidos oferecendo entretenimento de alta qualidade.",
		Type = "Comum",
		Weight = 12.5,
		["Anim"] = "tv",
		LostWater = true,
		Economy = 5425,
		Market = true,
		Max = 1
	},
	["ssddrive"] = {
		Index = "ssddrive",
		Name = "Unidade SSD",
		Type = "Comum",
		Weight = 0.75,
		Economy = 525,
		LostWater = true
	},
	["safependrive"] = {
		Index = "safependrive",
		Name = "Pendrive Seguro",
		Type = "Comum",
		Market = true,
		Weight = 0.15,
		Economy = 3225,
		Durability = 72,
		LostWater = true
	},
	["powercable"] = {
		Index = "powercable",
		Name = "Cabo de Alimentação",
		Type = "Comum",
		Weight = 0.35,
		Economy = 225
	},
	["weaponparts"] = {
		Index = "weaponparts",
		Name = "Peças de Armas",
		Type = "Comum",
		Weight = 1.25,
		Economy = 125,
		Market = true,
		Arrest = true
	},
	["lightgunparts"] = {
		Index = "lightgunparts",
		Name = "Peças de Arma Leve",
		Blueprint = 65,
		Type = "Comum",
		Weight = 1.75,
		Economy = 625,
		Market = true
	},
	["mediumgunparts"] = {
		Index = "mediumgunparts",
		Name = "Peças de Arma Média",
		Blueprint = 125,
		Type = "Comum",
		Weight = 2.25,
		Economy = 1250,
		Market = true
	},
	["heavygunparts"] = {
		Index = "heavygunparts",
		Name = "Peças de Arma Pesada",
		Blueprint = 215,
		Type = "Comum",
		Weight = 2.75,
		Economy = 2125,
		Market = true
	},
	["electroniccomponents"] = {
		Index = "electroniccomponents",
		Name = "Componentes Eletrônicos",
		Type = "Comum",
		Weight = 0.35,
		Economy = 375,
		LostWater = true
	},
	["batteryaa"] = {
		Index = "batteryaa",
		Name = "Bateria AA",
		Type = "Comum",
		Weight = 0.15,
		Economy = 225,
		LostWater = true
	},
	["batteryaaplus"] = {
		Index = "batteryaaplus",
		Name = "Bateria AA+",
		Type = "Comum",
		Weight = 0.25,
		Economy = 275,
		LostWater = true
	},
	["goldnecklace"] = {
		Index = "goldnecklace",
		Name = "Colar de Ouro",
		Type = "Comum",
		Weight = 0.45,
		Economy = 625
	},
	["silverchain"] = {
		Index = "silverchain",
		Name = "Corrente de Prata",
		Type = "Comum",
		Weight = 0.40,
		Economy = 425
	},
	["horsefigurine"] = {
		Index = "horsefigurine",
		Name = "Estatueta de Cavalo",
		Type = "Comum",
		Weight = 1.25,
		Economy = 2425
	},
	["toothpaste"] = {
		Index = "toothpaste",
		Name = "Pasta de Dente",
		Type = "Comum",
		Weight = 0.15,
		Economy = 175
	},
	["goldenjug"] = {
		Index = "goldenjug",
		Name = "Jarro de Ouro",
		Type = "Comum",
		Weight = 7.25,
		Economy = 6775
	},
	["goldenleopard"] = {
		Index = "goldenleopard",
		Name = "Leopardo de Ouro",
		Type = "Comum",
		Weight = 8.75,
		Economy = 8225
	},
	["goldenlion"] = {
		Index = "goldenlion",
		Name = "Leão de Ouro",
		Type = "Comum",
		Weight = 10.25,
		Economy = 12225
	},
	-- COMIDAS
	["cola"] = {
		Index = "cola",
		Name = "Cola",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		Fridge = true
	},
	["tacos"] = {
		Index = "tacos",
		Name = "Tacos",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["fries"] = {
		Index = "fries",
		Name = "Fritas",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	Water = {
		Index = "water",
		Name = "Garrafa de Água",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 35,
		Market = true,
		Fridge = true
	},
	["soda"] = {
		Index = "soda",
		Name = "Sprunk",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		Fridge = true
	},
	["hotdog"] = {
		Index = "hotdog",
		Name = "Cachorro-Quente",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.45,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["donut"] = {
		Index = "donut",
		Name = "Rosquinha",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 15,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["hamburger"] = {
		Index = "hamburger",
		Name = "Hambúrguer",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.55,
		Max = 2,
		Economy = 25,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["chocolate"] = {
		Index = "chocolate",
		Name = "Chocolate",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.15,
		Max = 4,
		Economy = 20,
		Market = true,
		Fridge = true
	},
	["sandwich"] = {
		Index = "sandwich",
		Name = "Sanduiche",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["coffeecup"] = {
		Index = "coffeecup",
		Name = "Copo de Café",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	-- COMIDAS
	["nigirizushi"] = {
		Index = "nigirizushi",
		Name = "Nigirizushi",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.65,
		Max = 3,
		Economy = 60,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["sushi"] = {
		Index = "sushi",
		Name = "Sushi",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.65,
		Max = 3,
		Economy = 60,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["cupcake"] = {
		Index = "cupcake",
		Name = "Cupcake",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.55,
		Max = 3,
		Economy = 45,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["milkshake"] = {
		Index = "milkshake",
		Name = "Milk-shake",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.85,
		Max = 3,
		Economy = 75,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["cappuccino"] = {
		Index = "cappuccino",
		Name = "Cappuccino",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.65,
		Max = 3,
		Economy = 100,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["applelove"] = {
		Index = "applelove",
		Name = "Maça do Amor",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.55,
		Max = 3,
		Economy = 35,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["cookies"] = {
		Index = "cookies",
		Name = "Cookies",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 3,
		Economy = 45,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["hamburger2"] = {
		Index = "hamburger2",
		Name = "Hambúrguer Artesanal",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["hamburger3"] = {
		Index = "hamburger3",
		Name = "Hambúrguer Vegetariano",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["pizzamozzarella"] = {
		Index = "pizzamozzarella",
		Name = "Pizza de Muçarela",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["pizzabanana"] = {
		Index = "pizzabanana",
		Name = "Pizza de Banana",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	["pizzachocolate"] = {
		Index = "pizzachocolate",
		Name = "Pizza de Chocolate",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		LostWater = true,
		Fridge = true
	},
	-- BOXES
	["treasurebox"] = {
		Index = "treasurebox",
		Name = "Baú do Tesouro",
		Type = "Consumível",
		Weight = 0.0,
		Unique = true,
		Economy = 0,
		Market = true,
		Rarity = "legendary"
	},
	["notepad"] = {
		Index = "notepad",
		Name = "Bloco de Notas",
		Type = "Consumível",
		Weight = 0.0,
		Unique = true,
		Economy = 10,
		Market = true,
		Rarity = "common"
	},
	["ammobox"] = {
		Index = "ammobox",
		Name = "Caixa de Munição",
		Description = "Robusta e segura, projetada para armazenamento e transporte confiável de munições.",
		Repair = "repairkit04",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.75,
		Unique = true,
		Market = true,
		Economy = 70000,
		Rarity = "rare"
	},
	["weaponbox"] = {
		Index = "weaponbox",
		Name = "Caixa de Armamento",
		Description = "Resistente e segura, ideal para armazenamento e transporte de armas com praticidade e segurança.",
		Repair = "repairkit04",
		Type = "Consumível",
		Durability = 720,
		Weight = 3.25,
		Unique = true,
		Market = true,
		Economy = 100000,
		Rarity = "rare"
	},
	["suitcase"] = {
		Index = "suitcase",
		Name = "Mala de Dinheiro",
		Description = "Segura e discreta para guardar dinheiro, ideal para proteger e organizar seus recursos financeiros com tranquilidade.",
		Type = "Consumível",
		Weight = 1.0,
		Unique = true,
		Market = true,
		Economy = 275,
		Rarity = "common"
	},
	["medicbag"] = {
		Index = "medicbag",
		Name = "Caixa de Medicamentos",
		Description = "Projetada para armazenamento seguro e organizado de medicamentos, garantindo acessibilidade e segurança no ambiente de saúde.",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.5,
		Unique = true,
		Market = true,
		Economy = 1275,
		Rarity = "rare"
	},
	-- OBJECTS
	["pistol_bench"] = {
		Index = "pistol_bench",
		Name = "Mesa de Produção",
		Description = "Mesa para fabricação de <common>Pistolas</common>.",
		Type = "Consumível",
		Durability = 168,
		Weight = 8.75,
		Economy = 50000,
		Market = true,
		Rarity = "epic"
	},
	["smg_bench"] = {
		Index = "smg_bench",
		Name = "Mesa de Produção",
		Description = "Mesa para fabricação de <common>Submetralhadoras</common>.",
		Type = "Consumível",
		Durability = 168,
		Weight = 9.25,
		Economy = 75000,
		Market = true,
		Rarity = "epic"
	},
	["rifle_bench"] = {
		Index = "rifle_bench",
		Name = "Mesa de Produção",
		Description = "Mesa para fabricação de <common>Rifles</common>.",
		Type = "Consumível",
		Durability = 168,
		Weight = 9.75,
		Economy = 100000,
		Market = true,
		Rarity = "epic"
	},
	["drugs_bench"] = {
		Index = "drugs_bench",
		Name = "Mesa de Produção",
		Description = "Mesa para fabricação de <common>Drogas</common>.",
		Type = "Consumível",
		Durability = 168,
		Weight = 7.25,
		Economy = 50000,
		Market = true,
		Rarity = "epic"
	},
	["blueprint_bench"] = {
		Index = "blueprint_bench",
		Name = "Mesa de Aprendizado",
		Description = "Mesa para aprendizado de produção.",
		Type = "Consumível",
		Durability = 168,
		Weight = 7.25,
		Economy = 65000,
		Market = true,
		Rarity = "epic"
	},
	["securitycam"] = {
		Index = "securitycam",
		Name = "CCTV Câmera",
		Type = "Consumível",
		Durability = 240,
		Weight = 7.75,
		Market = true
	},
	["barrier"] = {
		Index = "barrier",
		Name = "Barreira",
		Type = "Consumível",
		Durability = 168,
		Weight = 2.25,
		Max = 2,
		Economy = 25,
		Market = true
	},
	["personalp"] = {
		Index = "personal",
		Name = "Compartimento Pessoal",
		Description = "Projetado para manter seus itens mais valiosos protegidos e sempre ao seu alcance, com capacidade máxima de <b>100kg</b>, ele combina segurança, praticidade e organização em um único espaço.<br><common>Ao posicionado não pode ser retirado.</common>",
		Type = "Consumível",
		Rarity = "common",
		Delete = true,
		Unique = true,
		Weight = 5.25
	},
	["personalm"] = {
		Index = "personal",
		Name = "Compartimento Pessoal",
		Description = "Projetado para manter seus itens mais valiosos protegidos e sempre ao seu alcance, com capacidade máxima de <b>250kg</b>, ele combina segurança, praticidade e organização em um único espaço.<br><common>Ao posicionado não pode ser retirado.</common>",
		Type = "Consumível",
		Rarity = "rare",
		Delete = true,
		Unique = true,
		Weight = 5.25
	},
	["personalg"] = {
		Index = "personal",
		Name = "Compartimento Pessoal",
		Description = "Projetado para manter seus itens mais valiosos protegidos e sempre ao seu alcance, com capacidade máxima de <b>500kg</b>, ele combina segurança, praticidade e organização em um único espaço.<br><common>Ao posicionado não pode ser retirado.</common>",
		Type = "Consumível",
		Rarity = "epic",
		Delete = true,
		Unique = true,
		Weight = 5.25
	},
	["chestgroupp"] = {
		Index = "chestgroup",
		Name = "Compartimento Militar",
		Description = "Projetado para manter seus e de seu grupo, itens mais valiosos protegidos e sempre ao seu alcance, com capacidade máxima de <b>1.000kg</b>, ele combina segurança, praticidade e organização em um único espaço.<br><common>Ao posicionado não pode ser retirado.</common>",
		Type = "Consumível",
		Rarity = "common",
		Delete = true,
		Unique = true,
		Weight = 5.25
	},
	["chestgroupm"] = {
		Index = "chestgroup",
		Name = "Compartimento Militar",
		Description = "Projetado para manter seus e de seu grupo, itens mais valiosos protegidos e sempre ao seu alcance, com capacidade máxima de <b>2.500kg</b>, ele combina segurança, praticidade e organização em um único espaço.<br><common>Ao posicionado não pode ser retirado.</common>",
		Type = "Consumível",
		Rarity = "rare",
		Delete = true,
		Unique = true,
		Weight = 5.25
	},
	["chestgroupg"] = {
		Index = "chestgroup",
		Name = "Compartimento Militar",
		Description = "Projetado para manter seus e de seu grupo, itens mais valiosos protegidos e sempre ao seu alcance, com capacidade máxima de <b>5.000kg</b>, ele combina segurança, praticidade e organização em um único espaço.<br><common>Ao posicionado não pode ser retirado.</common>",
		Type = "Consumível",
		Rarity = "epic",
		Delete = true,
		Unique = true,
		Weight = 5.25
	},
	["spikestrips"] = {
		Index = "spikestrips",
		Name = "Tiras de Espinhos",
		Type = "Consumível",
		Weight = 1.25,
		Max = 1,
		Economy = 275,
		Market = true
	},
	["moneywash"] = {
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><common>Lavagem diária: $250.000</common>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "common"
	},
	["moneywashplus"] = {
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><rare>Lavagem diária: $500.000</rare>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "rare"
	},
	["moneywashalpha"] = {
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><epic>Lavagem diária: $1.000.000</epic>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "epic"
	},
	["moneywashomega"] = {
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><legendary>Lavagem diária: $5.000.000</legendary>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "legendary"
	},
	["washbattery"] = {
		Index = "washbattery",
		Name = "Bateria 75Ah",
		Description = "Fonte confiável de energia, garantindo longa duração e eficiência durante os ciclos de lavagem, ideal para manter o funcionamento contínuo sem depender exclusivamente da rede elétrica.<br><br><legendary>Duração de 7 dias</legendary>",
		Type = "Comum",
		Weight = 17.5,
		Economy = 12750,
		Market = true,
		LostWater = true
	},
	["washbleach"] = {
		Index = "washbleach",
		Name = "Alvejante",
		Description = "Produto químico potente utilizado para remover manchas difíceis e desinfetar superfícies. Ideal para limpeza pesada de roupas brancas e ambientes que exigem higienização profunda. Deve ser manuseado com cuidado.<br><br><legendary>Duração de 6 horas</legendary>",
		Type = "Comum",
		Weight = 0.35,
		Economy = 22725,
		Market = true
	},
	-- MELEES
	["WEAPON_HATCHET"] = {
		Index = "hatchet",
		Name = "Machado",
		Type = "Armamento",
		Arrest = true,
		Repair = "repairkit01",
		Durability = 240,
		Weight = 1.75,
		Economy = 975,
		Market = true
	},
	["WEAPON_BAT"] = {
		Index = "bat",
		Name = "Bastão de Beisebol",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.75,
		Economy = 975,
		Market = true
	},
	["WEAPON_BATTLEAXE"] = {
		Index = "battleaxe",
		Name = "Machado de Batalha",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.75,
		Economy = 975,
		Market = true
	},
	["WEAPON_CROWBAR"] = {
		Index = "crowbar",
		Name = "Pé de Cabra",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.35,
		Economy = 975,
		Market = true
	},
	["WEAPON_SWITCHBLADE"] = {
		Index = "switchblade",
		Name = "Canivete",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 0.75,
		Economy = 975,
		Market = true
	},
	["WEAPON_GOLFCLUB"] = {
		Index = "golfclub",
		Name = "Taco de Golf",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.65,
		Economy = 975,
		Market = true
	},
	["WEAPON_HAMMER"] = {
		Index = "hammer",
		Name = "Martelo",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.45,
		Economy = 975,
		Market = true
	},
	["WEAPON_MACHETE"] = {
		Index = "machete",
		Name = "Facão",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.35,
		Economy = 975,
		Market = true
	},
	["WEAPON_POOLCUE"] = {
		Index = "poolcue",
		Name = "Taco de Sinuca",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.25,
		Economy = 975,
		Market = true
	},
	["WEAPON_STONE_HATCHET"] = {
		Index = "stonehatchet",
		Name = "Machado de Pedra",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.55,
		Economy = 975,
		Market = true
	},
	["WEAPON_WRENCH"] = {
		Index = "wrench",
		Name = "Chave Inglesa",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.45,
		Economy = 975,
		Market = true
	},
	["WEAPON_KNUCKLE"] = {
		Index = "knuckle",
		Name = "Soco Inglês",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.25,
		Economy = 975,
		Market = true
	},
	["WEAPON_FLASHLIGHT"] = {
		Index = "flashlight",
		Name = "Lanterna",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 0.75,
		Economy = 975,
		Market = true
	},
	["WEAPON_NIGHTSTICK"] = {
		Index = "nightstick",
		Name = "Cassetete",
		Repair = "repairkit01",
		Type = "Armamento",
		Arrest = true,
		Durability = 240,
		Weight = 1.15,
		Economy = 975,
		Market = true
	},
	["WEAPON_PETROLCAN"] = {
		Index = "gallon",
		Name = "Galão",
		Type = "Armamento",
		Arrest = true,
		Ammo = "WEAPON_PETROLCAN_AMMO",
		Market = true,
		Weight = 2.75,
		Economy = 500
	},
	["GADGET_PARACHUTE"] = {
		Index = "parachute",
		Name = "Paraquedas",
		Description = "Lembrando que após <common>desconectar</common> da cidade o mesmo é removido.",
		Type = "Consumível",
		Weight = 2.25,
		Max = 2,
		Economy = 225,
		Market = true
	},
	-- MUNIÇÕES
	["WEAPON_RPG_AMMO"] = {
		Index = "rocket",
		Name = "Munição de Foguete",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 2.25
	},
	["WEAPON_PISTOL_AMMO"] = {
		Index = "pistolammo",
		Name = "Munição de Pistola",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.025,
		Economy = 15
	},
	["WEAPON_SMG_AMMO"] = {
		Index = "smgammo",
		Name = "Munição de Sub",
		Type = "Munição",
		Market = true,
		Weight = 0.025,
		Economy = 20
	},
	["WEAPON_RIFLE_AMMO"] = {
		Index = "rifleammo",
		Name = "Munição de Rifle",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.025,
		Economy = 25
	},
	["WEAPON_SHOTGUN_AMMO"] = {
		Index = "shotgunammo",
		Name = "Munição de Espingarda",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.050,
		Economy = 50
	},
	["WEAPON_MUSKET_AMMO"] = {
		Index = "musketammo",
		Name = "Munição de Mosquete",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.075,
		Economy = 10
	},
	["WEAPON_PETROLCAN_AMMO"] = {
		Index = "fuel",
		Name = "Combustível",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.001,
		Economy = 0
	},
	-- ARREMESSO
	["WEAPON_ACIDPACKAGE"] = {
		Index = "newspaper",
		Name = "Jornal",
		Type = "Arremesso",
		Arrest = true,
		Vehicle = true,
		Weight = 0.75,
		Economy = 10,
		Market = true
	},
	["WEAPON_BRICK"] = {
		Index = "brick",
		Name = "Tijolo",
		Type = "Arremesso",
		Arrest = true,
		Vehicle = true,
		Weight = 0.75,
		Economy = 25,
		Market = true
	},
	["WEAPON_SNOWBALL"] = {
		Index = "snowball",
		Name = "Bola de Neve",
		Type = "Arremesso",
		Arrest = true,
		Vehicle = true,
		Weight = 0.55,
		Economy = 25,
		Market = true
	},
	["WEAPON_SHOES"] = {
		Index = "shoes",
		Name = "Tênis",
		Type = "Arremesso",
		Arrest = true,
		Vehicle = true,
		Weight = 0.755,
		Economy = 25,
		Market = true
	},
	["WEAPON_MOLOTOV"] = {
		Index = "molotov",
		Name = "Coquetel Molotov",
		Type = "Arremesso",
		Arrest = true,
		Vehicle = true,
		Market = true,
		Weight = 0.95,
		Max = 2,
		Economy = 1225
	},
	["WEAPON_SMOKEGRENADE"] = {
		Index = "smokegrenade",
		Name = "Granada de Fumaça",
		Type = "Arremesso",
		Arrest = true,
		Vehicle = true,
		Market = true,
		Weight = 0.95,
		Max = 2,
		Economy = 1225
	},
	-- ARMAMENTOS
	["WEAPON_STUNGUN"] = {
		Index = "stungun",
		Name = "Tazer",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Durability = 480,
		Market = true,
		Weight = 0.75,
		Economy = 725,
		Recycle = {
			["scrapmetal"] = 60
		}
	},
	["WEAPON_PISTOL"] = {
		Index = "m1911",
		Name = "M1911",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 2.25,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_PISTOL_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP_02"
		},
		Economy = 5725,
		Recycle = {
			["scrapmetal"] = 475
		}
	},
	["WEAPON_PISTOL_MK2"] = {
		Index = "t54",
		Name = "T54",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 2.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH_02",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_PI_RAIL",
			["ATTACH_MAGAZINE"] = "COMPONENT_PISTOL_MK2_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP_02"
		},
		Economy = 6225,
		Recycle = {
			["scrapmetal"] = 500
		}
	},
	["WEAPON_COMPACTRIFLE"] = {
		Index = "aks74u",
		Name = "AKS74U",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 4.25,
		Attachs = {
			["ATTACH_MAGAZINE"] = "COMPONENT_COMPACTRIFLE_CLIP_02"
		},
		Economy = 13225,
		Recycle = {
			["scrapmetal"] = 1075
		}
	},
	["WEAPON_APPISTOL"] = {
		Index = "kochvp9",
		Name = "Koch Vp9",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 2.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_APPISTOL_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP"
		},
		Economy = 6225,
		Recycle = {
			["scrapmetal"] = 500
		}
	},
	["WEAPON_HEAVYPISTOL"] = {
		Index = "m45a1",
		Name = "M45A1",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 2.75,
		Economy = 7225,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_HEAVYPISTOL_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP"
		},
		Recycle = {
			["scrapmetal"] = 575
		}
	},
	["WEAPON_MACHINEPISTOL"] = {
		Index = "tec9",
		Name = "Tec-9",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Repair = "repairkit03",
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 3.25,
		Attachs = {
			["ATTACH_MAGAZINE"] = "COMPONENT_MACHINEPISTOL_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP"
		},
		Economy = 8225,
		Recycle = {
			["scrapmetal"] = 675
		}
	},
	["WEAPON_MICROSMG"] = {
		Index = "uzi",
		Name = "Uzi",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Repair = "repairkit03",
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 4.25,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO",
			["ATTACH_MAGAZINE"] = "COMPONENT_MICROSMG_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 13225,
		Recycle = {
			["scrapmetal"] = 1075
		}
	},
	["WEAPON_RPG"] = {
		Index = "rpg",
		Name = "Lança Foguete",
		Description = "Armamento que utiliza <common>Munição de Foguete</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RPG_AMMO",
		Durability = 720,
		Vehicle = false,
		Market = true,
		Weight = 12.25
	},
	["WEAPON_MINISMG"] = {
		Index = "mac10",
		Name = "MAC-10",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 5.25,
		Attachs = {
			["ATTACH_MAGAZINE"] = "COMPONENT_MINISMG_CLIP_02"
		},
		Economy = 13225,
		Recycle = {
			["scrapmetal"] = 1075
		}
	},
	["WEAPON_SNSPISTOL"] = {
		Index = "f57",
		Name = "F57",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 2.25,
		Attachs = {
			["ATTACH_MAGAZINE"] = "COMPONENT_SNSPISTOL_CLIP_02"
		},
		Economy = 4725,
		Recycle = {
			["scrapmetal"] = 375
		}
	},
	["WEAPON_SNSPISTOL_MK2"] = {
		Index = "cz52",
		Name = "CZ52",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 3.25,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH_03",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_PI_RAIL_02",
			["ATTACH_MAGAZINE"] = "COMPONENT_SNSPISTOL_MK2_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP_02"
		},
		Economy = 5225,
		Recycle = {
			["scrapmetal"] = 425
		}
	},
	["WEAPON_VINTAGEPISTOL"] = {
		Index = "m1922",
		Name = "M1922",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 3.25,
		Attachs = {
			["ATTACH_MAGAZINE"] = "COMPONENT_VINTAGEPISTOL_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP"
		},
		Economy = 4725,
		Recycle = {
			["scrapmetal"] = 375
		}
	},
	["WEAPON_PISTOL50"] = {
		Index = "deagle",
		Name = "Deagle",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 3.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_PISTOL50_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 8225,
		Recycle = {
			["scrapmetal"] = 675
		}
	},
	["WEAPON_COMBATPISTOL"] = {
		Index = "g18c",
		Name = "G18C",
		Description = "Armamento que utiliza <common>Munição de Pistola</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_PISTOL_AMMO",
		Durability = 240,
		Vehicle = true,
		Market = true,
		Weight = 3.25,
		Economy = 6225,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_PI_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_COMBATPISTOL_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP"
		},
		Recycle = {
			["scrapmetal"] = 500
		}
	},
	["WEAPON_CARBINERIFLE"] = {
		Index = "m4a1",
		Name = "M4A1",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Economy = 22725,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_CARBINERIFLE_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MEDIUM"
		},
		Recycle = {
			["scrapmetal"] = 1825
		}
	},
	["WEAPON_CARBINERIFLE_MK2"] = {
		Index = "h416",
		Name = "H416",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 8.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MEDIUM_MK2",
			["ATTACH_MAGAZINE"] = "COMPONENT_CARBINERIFLE_MK2_CLIP_02",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP"
		},
		Economy = 24225,
		Recycle = {
			["scrapmetal"] = 1925
		}
	},
	["WEAPON_ADVANCEDRIFLE"] = {
		Index = "mdr",
		Name = "MDR",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_SMALL",
			["ATTACH_MAGAZINE"] = "COMPONENT_ADVANCEDRIFLE_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP"
		},
		Economy = 22725,
		Recycle = {
			["scrapmetal"] = 1825
		}
	},
	["WEAPON_BULLPUPRIFLE"] = {
		Index = "qbz95",
		Name = "QBZ-95",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_SMALL",
			["ATTACH_MAGAZINE"] = "COMPONENT_BULLPUPRIFLE_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP"
		},
		Economy = 22725,
		Recycle = {
			["scrapmetal"] = 1825
		}
	},
	["WEAPON_BULLPUPRIFLE_MK2"] = {
		Index = "l85",
		Name = "L85",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO_02_MK2",
			["ATTACH_MAGAZINE"] = "COMPONENT_BULLPUPRIFLE_MK2_CLIP_02",
			["ATTACH_GRIP"] = "COMPONENT_AT_MUZZLE_01",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP"
		},
		Economy = 24225,
		Recycle = {
			["scrapmetal"] = 1925
		}
	},
	["WEAPON_SPECIALCARBINE"] = {
		Index = "g36c",
		Name = "G36C",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 8.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MEDIUM",
			["ATTACH_MAGAZINE"] = "COMPONENT_SPECIALCARBINE_CLIP_02",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 22725,
		Recycle = {
			["scrapmetal"] = 1825
		}
	},
	["WEAPON_SPECIALCARBINE_MK2"] = {
		Index = "sigsauer556",
		Name = "Sig Sauer 556",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 8.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO_MK2",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 24225,
		Recycle = {
			["scrapmetal"] = 1925
		}
	},
	["WEAPON_PUMPSHOTGUN"] = {
		Index = "m870",
		Name = "M870",
		Description = "Armamento que utiliza <common>Munição de Espingarda</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SHOTGUN_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.25,
		Economy = 13225,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_SILENCER"] = "COMPONENT_AT_SR_SUPP"
		},
		Recycle = {
			["scrapmetal"] = 1025
		}
	},
	["WEAPON_PUMPSHOTGUN_MK2"] = {
		Index = "mp133",
		Name = "MP133",
		Description = "Armamento que utiliza <common>Munição de Espingarda</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SHOTGUN_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.25,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_SMALL_MK2",
			["ATTACH_SILENCER"] = "COMPONENT_AT_SR_SUPP_03",
			["ATTACH_GRIP"] = "COMPONENT_AT_MUZZLE_08"
		},
		Economy = 15275,
		Recycle = {
			["scrapmetal"] = 1225
		}
	},
	["WEAPON_MUSKET"] = {
		Index = "winchester",
		Name = "Winchester 1892",
		Description = "Armamento que utiliza <common>Munição de Mosquete</common>.",
		Repair = "repairkit02",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_MUSKET_AMMO",
		Durability = 360,
		Market = true,
		Weight = 6.25,
		Economy = 3225,
		Recycle = {
			["scrapmetal"] = 75
		}
	},
	["WEAPON_SAWNOFFSHOTGUN"] = {
		Index = "mossberg500",
		Name = "Mossberg 500",
		Description = "Armamento que utiliza <common>Munição de Espingarda</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SHOTGUN_AMMO",
		Durability = 360,
		Market = true,
		Weight = 5.75,
		Economy = 13225,
		Recycle = {
			["scrapmetal"] = 1025
		}
	},
	["WEAPON_SMG"] = {
		Index = "mp5",
		Name = "MP5",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 360,
		Market = true,
		Weight = 5.25,
		Economy = 12725,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_SMG_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO_02"
		},
		Recycle = {
			["scrapmetal"] = 1025
		}
	},
	["WEAPON_SMG_MK2"] = {
		Index = "mpx",
		Name = "MPX",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 360,
		Vehicle = true,
		Market = true,
		Weight = 5.25,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2",
			["ATTACH_MAGAZINE"] = "COMPONENT_SMG_MK2_CLIP_02",
			["ATTACH_GRIP"] = "COMPONENT_AT_SB_BARREL_01",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP"
		},
		Economy = 15225,
		Recycle = {
			["scrapmetal"] = 1225
		}
	},
	["WEAPON_TACTICALRIFLE"] = {
		Index = "m16",
		Name = "M16",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Economy = 24225,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_MAGAZINE"] = "COMPONENT_SMG_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_PI_SUPP",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO_02"
		},
		Recycle = {
			["scrapmetal"] = 1925
		}
	},
	["WEAPON_HEAVYRIFLE"] = {
		Index = "scarh",
		Name = "Scar-H",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MEDIUM",
			["ATTACH_MAGAZINE"] = "COMPONENT_HEAVYRIFLE_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP"
		},
		Economy = 24225,
		Recycle = {
			["scrapmetal"] = 1925
		}
	},
	["WEAPON_ASSAULTRIFLE"] = {
		Index = "ak74n",
		Name = "AK-74N",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO",
			["ATTACH_MAGAZINE"] = "COMPONENT_ASSAULTRIFLE_CLIP_02",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 22725,
		Recycle = {
			["scrapmetal"] = 1825
		}
	},
	["WEAPON_ASSAULTRIFLE_MK2"] = {
		Index = "ak102",
		Name = "AK-102",
		Description = "Armamento que utiliza <common>Munição de Rifle</common>.",
		Repair = "repairkit04",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_RIFLE_AMMO",
		Durability = 360,
		Market = true,
		Weight = 7.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MEDIUM_MK2",
			["ATTACH_MAGAZINE"] = "COMPONENT_ASSAULTRIFLE_MK2_CLIP_02",
			["ATTACH_GRIP"] = "COMPONENT_AT_AR_AFGRIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 24225,
		Recycle = {
			["scrapmetal"] = 1925
		}
	},
	["WEAPON_ASSAULTSMG"] = {
		Index = "f2000",
		Name = "F2000",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 360,
		Market = true,
		Weight = 5.75,
		Attachs = {
			["ATTACH_FLASHLIGHT"] = "COMPONENT_AT_AR_FLSH",
			["ATTACH_CROSSHAIR"] = "COMPONENT_AT_SCOPE_MACRO",
			["ATTACH_MAGAZINE"] = "COMPONENT_ASSAULTSMG_CLIP_02",
			["ATTACH_SILENCER"] = "COMPONENT_AT_AR_SUPP_02"
		},
		Economy = 15225,
		Recycle = {
			["scrapmetal"] = 1225
		}
	},
	["WEAPON_GUSENBERG"] = {
		Index = "mpf45",
		Name = "MPF45",
		Description = "Armamento que utiliza <common>Munição de Sub</common>.",
		Repair = "repairkit03",
		Type = "Armamento",
		Arrest = true,
		Serial = true,
		Ammo = "WEAPON_SMG_AMMO",
		Durability = 360,
		Market = true,
		Weight = 6.25,
		Attachs = {
			["ATTACH_MAGAZINE"] = "COMPONENT_GUSENBERG_CLIP_02"
		},
		Economy = 15225,
		Recycle = {
			["scrapmetal"] = 1225
		}
	},
	-- MEDICINAL
	["syringe01"] = {
		Index = "syringe",
		Name = "Seringa A+",
		Type = "Comum",
		Weight = 0.25,
		Economy = 45,
		Market = true,
		Recycle = {
			["plastic"] = 2
		}
	},
	["syringe02"] = {
		Index = "syringe",
		Name = "Seringa B+",
		Type = "Comum",
		Weight = 0.25,
		Economy = 45,
		Market = true,
		Recycle = {
			["plastic"] = 2
		}
	},
	["syringe03"] = {
		Index = "syringe",
		Name = "Seringa A-",
		Type = "Comum",
		Weight = 0.25,
		Economy = 45,
		Market = true,
		Recycle = {
			["plastic"] = 2
		}
	},
	["syringe04"] = {
		Index = "syringe",
		Name = "Seringa B-",
		Type = "Comum",
		Weight = 0.25,
		Economy = 45,
		Market = true,
		Recycle = {
			["plastic"] = 2
		}
	},
	["bandage"] = {
		Index = "bandage",
		Name = "Bandagem",
		Type = "Consumível",
		Weight = 0.25,
		Economy = 275,
		Blueprint = 25,
		Market = true,
		Max = 3
	},
	["medkit"] = {
		Index = "medkit",
		Name = "Kit de Primeiros Socorros",
		Type = "Consumível",
		Weight = 0.75,
		Economy = 575,
		Blueprint = 57,
		Market = true,
		Max = 1,
	},
	["ritmoneury"] = {
		Index = "ritmoneury",
		Name = "Ritmoneury",
		Type = "Consumível",
		Weight = 0.75,
		Max = 2,
		Economy = 325,
		Market = true
	},
	["sinkalmy"] = {
		Index = "sinkalmy",
		Name = "Sinkalmy",
		Type = "Consumível",
		Weight = 0.75,
		Max = 2,
		Economy = 425,
		Market = true
	},
	["analgesic"] = {
		Index = "analgesic",
		Name = "Analgésicos",
		Type = "Consumível",
		Weight = 0.25,
		Economy = 175,
		Blueprint = 17,
		Market = true
	},
	["gauze"] = {
		Index = "gauze",
		Name = "Ataduras",
		Type = "Consumível",
		Blueprint = 12,
		Weight = 0.25,
		Economy = 125,
		Market = true,
		LostWater = true
	},
	["gsrkit"] = {
		Index = "gsrkit",
		Name = "Kit Residual",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.75,
		Economy = 25,
		Market = true
	},
	["gdtkit"] = {
		Index = "gdtkit",
		Name = "Kit Químico",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.75,
		Economy = 25,
		Market = true
	},
	-- EMPREGOS
	["bait"] = {
		Index = "bait",
		Name = "Isca",
		Type = "Comum",
		Weight = 0.25,
		Economy = 5,
		Market = true
	},
	["fishfillet"] = {
		Index = "fishfillet",
		Name = "Filé de Peixe",
		Type = "Comum",
		Weight = 0.05,
		Economy = 10,
		Market = true
	},
	["meatfillet"] = {
		Index = "meatfillet",
		Name = "Filé de Carne",
		Type = "Comum",
		Weight = 0.05,
		Economy = 10,
		Market = true
	},
	["anchovy"] = {
		Index = "anchovy",
		Name = "Anchova",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 50,
		Market = true,
		Fridge = true,
		["Fishing"] = 5
	},
	["catfish"] = {
		Index = "catfish",
		Name = "Peixe-Gato",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 70,
		Market = true,
		Fridge = true,
		["Fishing"] = 7
	},
	["herring"] = {
		Index = "herring",
		Name = "Arenque",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 80,
		Market = true,
		Fridge = true,
		["Fishing"] = 8
	},
	["orangeroughy"] = {
		Index = "orangeroughy",
		Name = "Peixe Relógio",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 60,
		Market = true,
		Fridge = true,
		["Fishing"] = 6
	},
	["salmon"] = {
		Index = "salmon",
		Name = "Salmão",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 150,
		Market = true,
		Fridge = true,
		["Fishing"] = 15
	},
	["sardine"] = {
		Index = "sardine",
		Name = "Sardinha",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 60,
		Market = true,
		Fridge = true,
		["Fishing"] = 6
	},
	["smallshark"] = {
		Index = "smallshark",
		Name = "Tubarão Pequeno",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 250,
		Market = true,
		Fridge = true,
		["Fishing"] = 25
	},
	["smalltrout"] = {
		Index = "smalltrout",
		Name = "Truta Pequena",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 70,
		Market = true,
		Fridge = true,
		["Fishing"] = 7
	},
	["yellowperch"] = {
		Index = "yellowperch",
		Name = "Poleiro Amarelo",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 80,
		Market = true,
		Fridge = true,
		["Fishing"] = 8
	},
	["package"] = {
		Index = "package",
		Name = "Encomenda",
		Type = "Comum",
		Weight = 10.0,
		["Anim"] = "caixa",
		LostWater = true,
		Economy = 0,
		Market = true,
		Max = 1
	},
	["binbag"] = {
		Index = "binbag",
		Name = "Saco de Lixo",
		Type = "Comum",
		Weight = 10.0,
		["Anim"] = "lixo",
		LostWater = true,
		Economy = 0,
		Market = true,
		Max = 1
	},
	["milkbottle"] = {
		Index = "milkbottle",
		Name = "Garrafa de Leite",
		Type = "Comum",
		Weight = 0.35,
		Economy = 35,
		Market = true,
		Fridge = true
	},
	["pouch"] = {
		Index = "pouch",
		Name = "Malote",
		Type = "Comum",
		Weight = 1.25,
		Economy = 0,
		Market = true,
		LostWater = true
	},
	["woodlog"] = {
		Index = "woodlog",
		Name = "Tora de Madeira",
		Type = "Comum",
		Weight = 1.0,
		Economy = 0,
		Market = true,
		LostWater = true
	},
	["sapphire_pure"] = {
		Index = "sapphire_pure",
		Name = "Safira Lapidada",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 60,
		Market = true
	},
	["emerald_pure"] = {
		Index = "emerald_pure",
		Name = "Esmeralda Lapidada",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 75,
		Market = true
	},
	["ruby_pure"] = {
		Index = "ruby_pure",
		Name = "Ruby Lapidado",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 60,
		Market = true
	},
	["gold_pure"] = {
		Index = "gold_pure",
		Name = "Barra de Ouro",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 50,
		Market = true
	},
	["iron_pure"] = {
		Index = "iron_pure",
		Name = "Barra de Ferro",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 45,
		Market = true
	},
	["lead_pure"] = {
		Index = "lead_pure",
		Name = "Barra de Chumbo",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 40,
		Market = true
	},
	["tin_pure"] = {
		Index = "tin_pure",
		Name = "Barra de Estanho",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 40,
		Market = true
	},
	["diamond_pure"] = {
		Index = "diamond_pure",
		Name = "Diamante Lapidado",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 50,
		Market = true
	},
	["copper_pure"] = {
		Index = "copper_pure",
		Name = "Barra de Cobre",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 42,
		Market = true
	},
	["ration"] = {
		Index = "ration",
		Name = "Ração Animal",
		Type = "Consumível",
		Weight = 0.75,
		LostWater = true,
		Economy = 125,
		Market = true
	},
	["coyote1star"] = {
		Index = "box1star",
		Name = "Coyote",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true,
		Fridge = true
	},
	["coyote2star"] = {
		Index = "box2star",
		Name = "Coyote",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true,
		Fridge = true
	},
	["coyote3star"] = {
		Index = "box3star",
		Name = "Coyote",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true,
		Fridge = true
	},
	["mtlion1star"] = {
		Index = "box1star",
		Name = "Puma",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true,
		Fridge = true
	},
	["mtlion2star"] = {
		Index = "box2star",
		Name = "Puma",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true,
		Fridge = true
	},
	["mtlion3star"] = {
		Index = "box3star",
		Name = "Puma",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true,
		Fridge = true
	},
	["boar1star"] = {
		Index = "box1star",
		Name = "Javali",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true,
		Fridge = true
	},
	["boar2star"] = {
		Index = "box2star",
		Name = "Javali",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true,
		Fridge = true
	},
	["boar3star"] = {
		Index = "box3star",
		Name = "Javali",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true,
		Fridge = true
	},
	["deer1star"] = {
		Index = "box1star",
		Name = "Cervo",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true,
		Fridge = true
	},
	["deer2star"] = {
		Index = "box2star",
		Name = "Cervo",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true,
		Fridge = true
	},
	["deer3star"] = {
		Index = "box3star",
		Name = "Cervo",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true,
		Fridge = true
	},
	-- OUTROS
	["legendarykey"] = {
		Index = "legendarykey",
		Name = "Chave da Fortuna",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		["Charges"] = 3,
		Weight = 0.25,
		Economy = 4225,
		Market = true,
		Rarity = "legendary"
	},
	["weaponkey"] = {
		Index = "weaponkey",
		Name = "Chave da Harmonia",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		["Charges"] = 10,
		Weight = 0.25,
		Economy = 725,
		Market = true,
		Rarity = "epic"
	},
	["medicalkey"] = {
		Index = "medicalkey",
		Name = "Chave da Aurora",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		["Charges"] = 10,
		Weight = 0.25,
		Economy = 675,
		Market = true,
		Rarity = "rare"
	},
	["utilkey"] = {
		Index = "utilkey",
		Name = "Chave do Crepúsculo",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		["Charges"] = 10,
		Weight = 0.25,
		Economy = 625,
		Market = true,
		Rarity = "common"
	},
	["sugarbox"] = {
		Index = "sugarbox",
		Name = "Caixa de Açucar",
		Type = "Comum",
		Weight = 0.25,
		Economy = 35,
		Market = true
	},
	["condensedmilk"] = {
		Index = "condensedmilk",
		Name = "Leite Condensado",
		Type = "Comum",
		Weight = 0.25,
		Economy = 25,
		Market = true
	},
	["mayonnaise"] = {
		Index = "mayonnaise",
		Name = "Pote de Maionese",
		Type = "Comum",
		Weight = 0.45,
		Economy = 20,
		Market = true
	},
	["ryebread"] = {
		Index = "ryebread",
		Name = "Pão de Centeio",
		Type = "Comum",
		Weight = 0.15,
		Economy = 20,
		Market = true
	},
	["ricebag"] = {
		Index = "ricebag",
		Name = "Saco de Arroz",
		Type = "Comum",
		Weight = 1.25,
		Economy = 105,
		Market = true
	},
	["dogtag"] = {
		Index = "dogtag",
		Name = "Plaqueta de Identificação",
		Type = "Comum",
		Weight = 0.025,
		Market = true,
		Named = true,
		Economy = 0,
		Arrest = true
	},
	["adrenaline"] = {
		Index = "adrenaline",
		Name = "Adrenalina",
		Type = "Comum",
		Weight = 0.25,
		Market = true,
		Economy = 4225
	},
	["dismantle"] = {
		Index = "dismantle",
		Name = "Cartão Ilegível",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.0,
		Economy = 1225,
		Market = true
	},
	["platinum"] = {
		Index = "platinum",
		Name = "Platina",
		Type = "Comum",
		Weight = 0.0,
		Economy = 20
	},
	["binoculars"] = {
		Index = "binoculars",
		Name = "Binóculos",
		Type = "Consumível",
		Durability = 240,
		Weight = 1.0,
		Economy = 425,
		Recycle = {
			["glass"] = 10,
			["plastic"] = 12
		}
	},
	["camera"] = {
		Index = "camera",
		Name = "Câmera",
		Type = "Consumível",
		Durability = 240,
		Weight = 1.0,
		LostWater = true,
		Economy = 425,
		Recycle = {
			["glass"] = 10,
			["plastic"] = 12
		}
	},
	["creditcard"] = {
		Index = "creditcard",
		Name = "Cartão de Crédito",
		Type = "Comum",
		Weight = 0.25,
		Delete = true,
		Economy = 0,
		Market = true
	},
	["propertys"] = {
		Index = "propertys",
		Name = "Chave de Ferro",
		Type = "Consumível",
		Weight = 0.35,
		Delete = true,
		Economy = 0,
		Market = true
	},
	["emptypurifiedwater"] = {
		Index = "emptypurifiedwater",
		Name = "Galão de Água Vazio",
		Description = "Prático para transporte e armazenamento, ideal para reutilização ou descarte responsável.",
		Type = "Comum",
		Weight = 0.75,
		Economy = 1275,
		Market = true
	},
	["purifiedwater"] = {
		Index = "purifiedwater",
		Name = "Galão de Água Purificada",
		Description = "Essencial para hidratação segura e saudável, ideal para uso doméstico ou comercial.",
		Type = "Comum",
		Weight = 1.25,
		Economy = 1275,
		Market = true,
		["Charges"] = 10,
		["Empty"] = "emptypurifiedwater"
	},
	["racestablet"] = {
		Index = "racestablet",
		Name = "Tablet Descartável",
		Description = "Dispositivo eletrônico compacto e temporário projetado para uso prático e conveniente em situações específicas, oferecendo funcionalidades básicas de navegação na internet, leitura e comunicação, com a vantagem de ser facilmente descartável após o uso.",
		Type = "Consumível",
		Durability = 48,
		Weight = 0.475,
		Economy = 2725,
		Market = true,
		Execute = {
			Type = "Server",
			Event = "races:Clean"
		}
	},
	["racesticket"] = {
		Index = "racesticket",
		Name = "Cartão Descartável",
		Description = "Explore circuitos exclusivos e de acesso privilegiado, desbloqueie portas para emocionantes experiências em locais de elite ao redor do mundo.",
		Type = "Comum",
		Arrest = true,
		Weight = 0.15,
		Economy = 2275,
		Market = true,
		["Charges"] = 5,
		Rarity = "epic"
	},
	["mdttablet"] = {
		Index = "mdttablet",
		Name = "Tablet Policial",
		Description = "Tablet de acesso ao sistema policial.",
		Type = "Consumível",
		Rarity = "legendary",
		Durability = 168,
		Economy = 2275,
		Weight = 0.35,
	},
	["emstablet"] = {
		Index = "emstablet",
		Name = "Tablet Médico",
		Description = "Tablet de acesso ao sistema Médico.",
		Type = "Consumível",
		Rarity = "legendary",
		Durability = 168,
		Economy = 2275,
		Weight = 0.35,
	},
	["postit"] = {
		Index = "postit",
		Name = "Post-It",
		Type = "Consumível",
		Weight = 0.25,
		LostWater = true,
		Economy = 20
	},
	["blocksignal"] = {
		Index = "blocksignal",
		Name = "Bloqueador de Sinal",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.75,
		Market = true,
		LostWater = true,
		Economy = 825,
		Recycle = {
			["plastic"] = 40
		}
	},
	["coilover"] = {
		Index = "coilover",
		Name = "Suspensão Coilover",
		Description = "Projetada para oferecer ajustabilidade extrema e resposta rápida em curvas fechadas e mudanças de direção rápidas, ajuda a maximizar a aderência nas curvas e proporcionar uma sensação precisa e controlada ao volante, fundamental para executar manobras precisas e controladas durante as competições de drift.",
		Type = "Consumível",
		Weight = 15.25,
		Economy = 24725,
		Market = true
	},
	["vehiclekey"] = {
		Index = "vehiclekey",
		Name = "Chave Reserva",
		Type = "Consumível",
		Durability = 72,
		Weight = 0.25,
		LostWater = true,
		Economy = 0,
		Market = true
	},
	["radio"] = {
		Index = "radio",
		Name = "Rádio",
		Description = "Transceptor compacto e confiável que proporciona uma comunicação clara e segura para seu grupo, com uma frequência exclusiva para manter suas conversas privadas e protegidas.",
		Type = "Consumível",
		Repair = "repairkit01",
		Durability = 168,
		Weight = 0.75,
		Execute = {
			Type = "Client",
			Event = "radio:Disconnect"
		},
		LostWater = true,
		Economy = 975,
		Recycle = {
			["glass"] = 10,
			["plastic"] = 25
		}
	},
	["ballisticplate"] = {
		Index = "ballisticplate",
		Name = "Placa Balística",
		Repair = "repairkit01",
		Type = "Consumível",
		Arrest = true,
		Durability = 96,
		Weight = 3.75,
		Market = true,
		Economy = 925
	},
	["fishingrod"] = {
		Index = "fishingrod",
		Name = "Vara de Madeira",
		Description = "Companheira ideal para os amantes da pesca, seja em água doce ou salgada, com sua construção leve e resistente, proporciona equilíbrio perfeito e sensibilidade para detectar até os mais sutis movimentos dos peixes, seja para pescadores iniciantes ou experientes, esta vara é a escolha confiável para horas de diversão e sucesso nas pescarias.",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 72,
		Weight = 2.75,
		Economy = 575,
		Market = true,
		Water = "In"
	},
	["fishingrod2"] = {
		Index = "fishingrod2",
		Name = "Vara de Grafite",
		Description = "Companheira ideal para os amantes da pesca, seja em água doce ou salgada, com sua construção leve e resistente, proporciona equilíbrio perfeito e sensibilidade para detectar até os mais sutis movimentos dos peixes, seja para pescadores iniciantes ou experientes, esta vara é a escolha confiável para horas de diversão e sucesso nas pescarias.",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 72,
		Weight = 2.75,
		Economy = 875,
		Market = true,
		Water = "In"
	},
	["fishingrod3"] = {
		Index = "fishingrod3",
		Name = "Vara de Fibra",
		Description = "Companheira ideal para os amantes da pesca, seja em água doce ou salgada, com sua construção leve e resistente, proporciona equilíbrio perfeito e sensibilidade para detectar até os mais sutis movimentos dos peixes, seja para pescadores iniciantes ou experientes, esta vara é a escolha confiável para horas de diversão e sucesso nas pescarias.",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 72,
		Weight = 2.75,
		Economy = 1275,
		Market = true,
		Water = "In"
	},
	["fishingrod4"] = {
		Index = "fishingrod4",
		Name = "Vara de Carbono",
		Description = "Companheira ideal para os amantes da pesca, seja em água doce ou salgada, com sua construção leve e resistente, proporciona equilíbrio perfeito e sensibilidade para detectar até os mais sutis movimentos dos peixes, seja para pescadores iniciantes ou experientes, esta vara é a escolha confiável para horas de diversão e sucesso nas pescarias.",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 72,
		Weight = 2.75,
		Economy = 1925,
		Market = true,
		Water = "In"
	},
	["pickaxe"] = {
		Index = "pickaxe",
		Name = "Picareta",
		Description = "Ferramenta versátil e resistente, projetada para lidar com uma variedade de tarefas, com sua construção robusta e design ergonômico, oferece conforto e eficiência em cada movimento, seja para escavação no jardim, trabalhos de construção ou aventuras ao ar livre, essa picareta é a escolha confiável para enfrentar desafios com facilidade e precisão.",
		Repair = "repairkit01",
		Type = "Comum",
		Durability = 240,
		Weight = 2.75,
		Economy = 1225,
		Market = true
	},
	["axe"] = {
		Index = "axe",
		Name = "Machadinha",
		Description = "Ferramenta robusta e confiável para os desafios mais exigentes, construído com materiais de alta qualidade e design ergonômico, proporciona precisão e potência em cada golpe, ideal para cortar lenha, realizar trabalhos de construção ou aventuras ao ar livre, é o companheiro perfeito para qualquer tarefa que exija força e eficiência.",
		Repair = "repairkit01",
		Type = "Comum",
		Durability = 240,
		Weight = 2.75,
		Economy = 1225,
		Market = true
	},
	["lockpick"] = {
		Index = "lockpick",
		Name = "Gazua",
		Description = "Ferramenta fina e flexível, frequentemente feita de metal, usada para abrir fechaduras sem a chave correspondente, é uma ferramenta comum entre profissionais de segurança e em situações de emergência.",
		Repair = "repairkit01",
		Type = "Consumível",
		Arrest = true,
		Durability = 72,
		Weight = 1.25,
		Economy = 725,
		Market = true
	},
	["cellphone"] = {
		Index = "cellphone",
		Name = "Celular",
		Repair = "repairkit01",
		Type = "Comum",
		Durability = 240,
		Weight = 0.75,
		LostWater = true,
		Economy = 725,
		Recycle = {
			["glass"] = 10,
			["plastic"] = 15
		}
	},
	["scuba"] = {
		Index = "scuba",
		Name = "Roupa de Mergulho",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 72,
		Weight = 2.25,
		Execute = {
			Type = "Client",
			Event = "inventory:ScubaRemove"
		},
		Economy = 975
	},
	["handcuff"] = {
		Index = "handcuff",
		Name = "Algemas",
		Repair = "repairkit02",
		Type = "Consumível",
		Arrest = true,
		Durability = 240,
		Weight = 1.25,
		Economy = 1225,
		Market = true,
		Recycle = {
			["copper"] = 30,
			["aluminum"] = 25
		}
	},
	["rope"] = {
		Index = "rope",
		Name = "Cordas",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 240,
		Weight = 1.75,
		Economy = 925,
		Market = true,
		Water = "Out"
	},
	["hood"] = {
		Index = "hood",
		Name = "Capuz",
		Repair = "repairkit02",
		Type = "Consumível",
		Arrest = true,
		Durability = 240,
		Weight = 1.75,
		Economy = 1225,
		Market = true,
		Recycle = {
			["tarp"] = 1,
			["rubber"] = 35
		}
	},
	["cigarette"] = {
		Index = "cigarette",
		Name = "Maço de Cigarros",
		Type = "Consumível",
		Weight = 0.15,
		Max = 5,
		LostWater = true,
		Economy = 15
	},
	["lighter"] = {
		Index = "lighter",
		Name = "Isqueiro",
		Repair = "repairkit01",
		Durability = 168,
		Type = "Comum",
		Weight = 0.55,
		LostWater = true,
		Economy = 225
	},
	["vape"] = {
		Index = "vape",
		Name = "Vape",
		Repair = "repairkit02",
		Type = "Consumível",
		Durability = 240,
		Weight = 0.75,
		LostWater = true,
		Economy = 4750
	},
	["dollar"] = {
		Index = "dollar",
		Name = "Dólar",
		Type = "Comum",
		Weight = 0.0,
		Market = true,
		Economy = 1,
		Arrest = true
	},
	["dirtydollar"] = {
		Index = "dirtydollar",
		Name = "Dólar Sujo",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		LostWater = "wetdollar",
		Economy = 1
	},
	["wetdollar"] = {
		Index = "wetdollar",
		Name = "Dólar Molhado",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 1
	},
	["promissory1000"] = {
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 1000
	},
	["promissory2000"] = {
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 2000
	},
	["promissory3000"] = {
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 3000
	},
	["promissory4000"] = {
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 4000
	},
	["promissory5000"] = {
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 5000
	},
	["pager"] = {
		Index = "pager",
		Name = "Pager",
		Type = "Consumível",
		Arrest = true,
		Weight = 2.25,
		LostWater = true,
		Economy = 425,
		Recycle = {
			["glass"] = 10,
			["plastic"] = 10
		}
	},
	["soap"] = {
		Index = "soap",
		Name = "Sabonete",
		Type = "Consumível",
		Weight = 0.25,
		Water = "In",
		Economy = 125,
		Market = true
	},
	["emptybottle"] = {
		Index = "emptybottle",
		Name = "Garrafa Vazia",
		Type = "Comum",
		Weight = 0.15,
		Economy = 15,
		Recycle = {
			["plastic"] = 1
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
ListItem = List
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDITEM
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("AddItem",function(Name,Table)
	List[Name] = Table
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURITYS
-----------------------------------------------------------------------------------------------------------------------------------------
Puritys = {
	{ Percent = 0, Chance = 100 },
	{ Percent = 10, Chance = 90 },
	{ Percent = 20, Chance = 80 },
	{ Percent = 30, Chance = 70 },
	{ Percent = 40, Chance = 60 },
	{ Percent = 50, Chance = 50 },
	{ Percent = 60, Chance = 40 },
	{ Percent = 70, Chance = 30 },
	{ Percent = 80, Chance = 20 },
	{ Percent = 90, Chance = 10 },
	{ Percent = 100, Chance = 1 }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLONEVARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Clones = {
	{ Clone = "tomato", Name = "Tomate", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "passion", Name = "Maracujá", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "tange", Name = "Tangerina", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "orange", Name = "Laranja", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "apple", Name = "Maça", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "grape", Name = "Uva", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "lemon", Name = "Limão", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "banana", Name = "Banana", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "acerola", Name = "Acerola", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "strawberry", Name = "Morango", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "blueberry", Name = "Blueberry", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "coffee", Name = "Café", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01b" },
	{ Clone = "weed", Name = "Cannabis", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01a" },
	{ Clone = "coke", Name = "Cocaína", Min = 3, Max = 6, Hash = "bkr_prop_weed_med_01a" }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- FURNITURE
-----------------------------------------------------------------------------------------------------------------------------------------
Furniture = {
	{
		Item = "halloween_pumpkin",
		Name = "Abóbora de Halloween",
		Rarity = "legendary",
		Hash = "tfx-summer_abroba"
	},{
		Item = "halloween_ghost",
		Name = "Fantasma de Halloween",
		Rarity = "legendary",
		Hash = "tfx-summer_ghost"
	},{
		Item = "largebed",
		Name = "Cama",
		Hash = "hei_heist_bed_double_08"
	},{
		Item = "browncloset",
		Name = "Guarda-Roupas",
		Rarity = "epic",
		Hash = "v_res_m_armoire"
	},{
		Item = "simplebox",
		Name = "Cofre Básico",
		Hash = "prop_ld_int_safe_01",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>100KG</legendary> dentro de seu compartimento.",
		Delete = true
	},{
		Item = "safebox",
		Name = "Cofre Reforçado",
		Rarity = "rare",
		Hash = "p_v_43_safe_s",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>200KG</legendary> dentro de seu compartimento.",
		Delete = true
	},{
		Item = "officebox",
		Name = "Cofre Blindado",
		Rarity = "epic",
		Hash = "sf_prop_v_43_safe_s_bk_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>500KG</legendary> dentro de seu compartimento.",
		Delete = true
	},{
		Item = "industrialbox",
		Name = "Cofre Industrial",
		Rarity = "epic",
		Hash = "xm3_prop_xm3_safe_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>1000KG</legendary> dentro de seu compartimento.",
		Delete = true
	},{
		Item = "ornamentbox",
		Name = "Cofre Corporativo",
		Rarity = "legendary",
		Hash = "h4_prop_h4_safe_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>1500KG</legendary> dentro de seu compartimento.",
		Delete = true
	},{
		Item = "goldenbox",
		Name = "Cofre Executivo",
		Rarity = "legendary",
		Hash = "sf_prop_v_43_safe_s_gd_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>2500KG</legendary> dentro de seu compartimento.",
		Delete = true
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDITEM
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("AddItem",function(Name,Data)
	List[Name] = Data
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLUEPRINTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Item,v in pairs(List) do
		local AmountBlueprint = v.Blueprint
		if AmountBlueprint then
			List["blueprint_"..Item] = {
				Name = v.Name,
				Index = "blueprint",
				Description = "Ao consumir você aprende a receita necessária para produzi-lo sempre que desejar.",
				Type = "Consumível",
				Weight = 0.0,
				Recycle = {
					blueprint_fragment = AmountBlueprint
				}
			}
		end
	end

	for _,v in pairs(Clones) do
		List[v.Clone] = {
			Index = v.Clone,
			Name = v.Name,
			Type = "Comum",
			LostWater = true,
			Weight = 0.15,
			Market = true,
			Economy = 15
		}

		for _,w in pairs(Puritys) do
			List[v.Clone.."clone_"..w.Percent] = {
				Index = "clone",
				Name = "Clonagem de "..v.Name,
				Description = "Pureza dos frutos: <common>"..w.Percent.."%</common>",
				Type = "Consumível",
				Purity = w.Percent,
				LostWater = true,
				Weight = 0.05,
				Market = true
			}
		end
	end

	for _,v in pairs(Furniture) do
		List["furniture_"..v.Item] = {
			Name = v.Name,
			Delete = v.Delete,
			Type = "Consumível",
			Weight = v.Weight or 2.0,
			Index = "furniture_"..v.Item,
			Rarity = v.Rarity or "common",
			Description = v.Description or "Este objeto pode ser posicionado dentro de propriedades, permitindo personalizar e organizar o ambiente."
		}
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemList()
	return List
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMCLONES
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemClones()
	return Clones
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMPURITYS
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemPuritys()
	return Puritys
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMFURNITURE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemFurniture()
	return Furniture
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemExist(Item)
	return List[SplitOne(Item)]
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMINDEX
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemIndex(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Index or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMNAME
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemName(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Name or "Deletado"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMTYPE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemType(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Type or "Comum"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMTYPECHECK
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemTypeCheck(Item,Mode)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Type and List[Item].Type == Mode and true or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemVehicle(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Vehicle or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemWeight(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Weight or 0.0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMBACKPACK
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemBackpack(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Backpack or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMMAXAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemMaxAmount(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Max or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLOSTWATER
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemLostWater(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].LostWater or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMWATER
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemWater(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Water or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMDESCRIPTION
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemDescription(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Description or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMDURABILITY
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemDurability(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Durability or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLOADS
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemLoads(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Charges or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMREPAIR
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemRepair(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Repair or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMUNIQUE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemUnique(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Unique or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMANIM
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemAnim(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Anim or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMEXECUTE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemExecute(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Execute or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMARREST
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemArrest(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Arrest or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMSERIAL
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemSerial(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Serial or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMECONOMY
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemEconomy(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Economy or 0
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMRARITY
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemRarity(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Rarity or "normal"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMRECYCLE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemRecycle(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Recycle or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMFISHING
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemFishing(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Fishing or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMNAMED
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemNamed(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Named or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMEMPTY
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemEmpty(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Empty or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMSKINSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemSkinshop(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Skinshop or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLOCKED
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemLocked(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Locked or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMMARKERS
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemMarkers(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Markers or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMADMIN
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemAdmin(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].AdminLevel or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLOCKDELETE
-----------------------------------------------------------------------------------------------------------------------------------------
function BlockDelete(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Delete or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLOCKMARKET
-----------------------------------------------------------------------------------------------------------------------------------------
function BlockMarket(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Market or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMAMMO
-----------------------------------------------------------------------------------------------------------------------------------------
function WeaponAmmo(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Ammo or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEAPONATTACH
-----------------------------------------------------------------------------------------------------------------------------------------
function WeaponAttach(Item,Weapon)
	local Item = SplitOne(Item)
	return List[Weapon] and List[Weapon].Attachs and List[Weapon].Attachs[Item] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMPHONE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemPhone(Item)
    local Item = SplitOne(Item)
    return List[Item] and List[Item]["Phone"] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMFRIDGE
-----------------------------------------------------------------------------------------------------------------------------------------
function ItemFridge(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Fridge or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
ListItem = List