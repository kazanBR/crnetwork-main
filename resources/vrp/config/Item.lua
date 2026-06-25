-----------------------------------------------------------------------------------------------------------------------------------------
-- LIST
-----------------------------------------------------------------------------------------------------------------------------------------
local List = {
	markers = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "encryptedkey",
		Name = "Chave Criptografada",
		Type = "Comum",
		Weight = 3.5,
		Market = true
	},
	-- BANNED
	["banned_reduce"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "halloween_pumpkin",
		Name = "Abóbora de Halloween",
		Description = "Um enfeite para sua propriedade com a temática de halloween.",
		Rarity = "legendary",
		Type = "Consumível",
		Weight = 5.0
	},
	["halloween_ghost"] = {
		AdminLevel = 1,
		Index = "halloween_ghost",
		Name = "Fantasma de Halloween",
		Description = "Um enfeite para sua propriedade com a temática de halloween.",
		Rarity = "legendary",
		Type = "Consumível",
		Weight = 5.0
	},
	-- ESSÊNCIAS
	["blue_essence"] = {
		AdminLevel = 1,
		Index = "blue_essence",
		Name = "Essência Azul",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["purple_essence"] = {
		AdminLevel = 1,
		Index = "purple_essence",
		Name = "Essência Roxa",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["green_essence"] = {
		AdminLevel = 1,
		Index = "green_essence",
		Name = "Essência Verde",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["red_essence"] = {
		AdminLevel = 1,
		Index = "red_essence",
		Name = "Essência Vermelha",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	["pink_essence"] = {
		AdminLevel = 1,
		Index = "pink_essence",
		Name = "Essência Rosa",
		Description = "Componente químico utilizado em experimentos, possui propriedades energéticas únicas que alimentam dispositivos experimentais, aprimoram armas modificadas ou são vendidas por um bom dinheiro.",
		Type = "Comum",
		Weight = 0.0,
		Delete = true
	},
	-- ANIMAL
	["a_c_cat_01"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "sprays",
		Name = "Spray: Ballas",
		Description = "Liberte sua expressão urbana com spray de pichação, sua ferramenta para transformar paredes em telas vibrantes de criatividade.",
		Type = "Consumível",
		Weight = 0.15,
		Market = true,
		Economy = 9725
	},
	["spray_vagos"] = {
		AdminLevel = 1,
		Index = "sprays",
		Name = "Spray: Vagos",
		Description = "Liberte sua expressão urbana com spray de pichação, sua ferramenta para transformar paredes em telas vibrantes de criatividade.",
		Type = "Consumível",
		Weight = 0.15,
		Market = true,
		Economy = 9725
	},
	["spray_families"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "advtoolbox",
		Name = "Conjunto de Ferramentas Mestre",
		Description = "Um arsenal versátil de ferramentas essenciais para todas as suas necessidades de reparo, com qualidade premium e variedade abrangente, este kit é seu parceiro e do seu veículos.",
		Type = "Consumível",
		Weight = 4.75,
		Charges = 3,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "passionjuice",
		Name = "Suco de Maracujá",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true
	},
	["tangejuice"] = {
		AdminLevel = 1,
		Index = "tangejuice",
		Name = "Suco de Tangerina",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["orangejuice"] = {
		AdminLevel = 1,
		Index = "orangejuice",
		Name = "Suco de Laranja",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["applejuice"] = {
		AdminLevel = 1,
		Index = "applejuice",
		Name = "Suco de Maça",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["grapejuice"] = {
		AdminLevel = 1,
		Index = "grapejuice",
		Name = "Suco de Uva",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["lemonjuice"] = {
		AdminLevel = 1,
		Index = "lemonjuice",
		Name = "Suco de Limão",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["bananajuice"] = {
		AdminLevel = 1,
		Index = "bananajuice",
		Name = "Suco de Banana",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["acerolajuice"] = {
		AdminLevel = 1,
		Index = "acerolajuice",
		Name = "Suco de Acerola",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["strawberryjuice"] = {
		AdminLevel = 1,
		Index = "strawberryjuice",
		Name = "Suco de Morango",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["blueberryjuice"] = {
		AdminLevel = 1,
		Index = "blueberryjuice",
		Name = "Suco de Blueberry",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	["coffeemilk"] = {
		AdminLevel = 1,
		Index = "coffeemilk",
		Name = "Café com Leite",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true
	},
	-- DROGAS
	["joint"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "weedsack",
		Name = "Pacote de Cannabis",
		Type = "Comum",
		Arrest = true,
		Weight = 2.50,
		Market = true,
		Economy = 250
	},
	["cocaine"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "cokesack",
		Name = "Pacote de Cocaína",
		Type = "Comum",
		Arrest = true,
		Weight = 2.50,
		Market = true,
		Economy = 250
	},
	["meth"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "methsack",
		Name = "Pacote de Metanfetamina",
		Type = "Comum",
		Arrest = true,
		Weight = 2.50,
		Market = true,
		Economy = 250
	},
	["crack"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "codeine",
		Name = "Seringa de Codeína",
		Type = "Comum",
		Arrest = true,
		Weight = 0.25,
		Market = true,
		Economy = 425
	},
	["amphetamine"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "seatbelt",
		Name = "Cinto de Corrida",
		Type = "Consumível",
		Weight = 5.75,
		Delete = true,
		Economy = 100000,
		Rarity = "legendary"
	},
	["sewingkit"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "gemstone",
		Name = "Diamante",
		Type = "Consumível",
		Weight = 0.0,
		Delete = true,
		Economy = 20,
		Rarity = "legendary"
	},
	["fishingrodplus"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "barbershop",
		Name = "Barbearia",
		Type = "Consumível",
		Description = "Define uma posição no mapa onde a <epic>Barbearia</epic> poderá ser acessada.",
		Weight = 0.0,
		Delete = true,
		Economy = 500000,
		Rarity = "legendary"
	},
	["skinshop"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "alliance",
		Name = "Aliança",
		Type = "Comum",
		Market = true,
		Weight = 0.0,
		Named = true
	},
	["alliance2"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "alliance3",
		Name = "Porta-Aliança de Diamante",
		Description = "<epic>Este item não pode ser roubado e, ao ser utilizado no alt + Relacionamento, gera dois itens que não podem ser roubados.</epic> Um pequeno estojo luxuoso, usado para guardar alianças de valor inestimável.",
		Type = "Comum",
		Weight = 0.0,
		Rarity = "legendary",
		Delete = true
	},
	["identity"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "latex",
		Name = "Frasco de Látex",
		Type = "Comum",
		Weight = 1.25,
		Economy = 175
	},
	["sand"] = {
		AdminLevel = 1,
		Index = "sand",
		Name = "Areia",
		Type = "Comum",
		Weight = 0.225,
		Economy = 20
	},
	["bauxite"] = {
		AdminLevel = 1,
		Index = "bauxite",
		Name = "Minério de Bauxita",
		Type = "Comum",
		Weight = 0.225,
		Economy = 50
	},
	["chalcopyrite"] = {
		AdminLevel = 1,
		Index = "chalcopyrite",
		Name = "Calcopirita",
		Type = "Comum",
		Weight = 0.225,
		Economy = 50
	},
	["plastic"] = {
		AdminLevel = 1,
		Index = "plastic",
		Name = "Plástico",
		Type = "Comum",
		Weight = 0.045,
		Economy = 8
	},
	["glass"] = {
		AdminLevel = 1,
		Index = "glass",
		Name = "Vidro",
		Type = "Comum",
		Weight = 0.045,
		Economy = 8
	},
	["rubber"] = {
		AdminLevel = 1,
		Index = "rubber",
		Name = "Borracha",
		Type = "Comum",
		Weight = 0.045,
		Economy = 8
	},
	["aluminum"] = {
		AdminLevel = 1,
		Index = "aluminum",
		Name = "Alumínio",
		Type = "Comum",
		Weight = 0.045,
		Economy = 10
	},
	["copper"] = {
		AdminLevel = 1,
		Index = "copper",
		Name = "Cobre",
		Type = "Comum",
		Weight = 0.045,
		Economy = 10
	},
	["sulfuric"] = {
		AdminLevel = 1,
		Index = "sulfuric",
		Name = "Ácido Sulfúrico",
		Type = "Consumível",
		Weight = 0.45,
		Economy = 75
	},
	["acetone"] = {
		AdminLevel = 1,
		Index = "acetone",
		Name = "Acetona",
		Type = "Comum",
		Weight = 0.25,
		Economy = 55
	},
	["saline"] = {
		AdminLevel = 1,
		Index = "saline",
		Name = "Soro Fisiológico",
		Type = "Comum",
		Weight = 0.35,
		Economy = 35
	},
	["alcohol"] = {
		AdminLevel = 1,
		Index = "alcohol",
		Name = "Álcool",
		Type = "Comum",
		Weight = 0.55,
		Economy = 45
	},
	["gunpowder"] = {
		AdminLevel = 1,
		Index = "gunpowder",
		Name = "Frasco de Pólvora",
		Type = "Comum",
		Weight = 0.10,
		Economy = 125,
		Arrest = true
	},
	["pistolbody"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "scrapmetal",
		Name = "Sucata de Metal",
		Type = "Comum",
		Weight = 0.0,
		Economy = 1
	},
	["blueprint_fragment"] = {
		AdminLevel = 1,
		Index = "blueprint_fragment",
		Name = "Fragmento de Aprendizado",
		Type = "Comum",
		Weight = 0.0
	},
	["metalspring"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "fabric",
		Name = "Tecido",
		Type = "Comum",
		Weight = 0.001
	},
	["ironfilings"] = {
		AdminLevel = 1,
		Index = "ironfilings",
		Name = "Limalha de Ferro",
		Type = "Comum",
		Market = true,
		Weight = 0.001
	},
	["gear"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "wheat",
		Name = "Trigo",
		Type = "Comum",
		Weight = 0.05,
		Economy = 5
	},
	["scotchtape"] = {
		AdminLevel = 1,
		Index = "scotchtape",
		Name = "Fita Adesiva",
		Type = "Comum",
		Weight = 0.15,
		Economy = 45
	},
	["insulatingtape"] = {
		AdminLevel = 1,
		Index = "insulatingtape",
		Name = "Fita Isolante",
		Type = "Comum",
		Weight = 0.15,
		Economy = 55
	},
	["rammemory"] = {
		AdminLevel = 1,
		Index = "rammemory",
		Name = "Memória RAM",
		Type = "Comum",
		Weight = 0.45,
		Economy = 375,
		LostWater = true
	},
	["powersupply"] = {
		AdminLevel = 1,
		Index = "powersupply",
		Name = "Fonte de Alimentação",
		Type = "Comum",
		Weight = 2.25,
		Economy = 475,
		LostWater = true
	},
	["processorfan"] = {
		AdminLevel = 1,
		Index = "processorfan",
		Name = "Ventoinha do Processador",
		Type = "Comum",
		Weight = 0.95,
		Economy = 325,
		LostWater = true
	},
	["processor"] = {
		AdminLevel = 1,
		Index = "processor",
		Name = "Processador",
		Type = "Comum",
		Weight = 0.65,
		Economy = 725,
		LostWater = true
	},
	["screws"] = {
		AdminLevel = 1,
		Index = "screws",
		Name = "Parafusos",
		Type = "Comum",
		Weight = 0.45,
		Economy = 45
	},
	["screwnuts"] = {
		AdminLevel = 1,
		Index = "screwnuts",
		Name = "Porcas de Parafuso",
		Type = "Comum",
		Weight = 0.45,
		Economy = 45
	},
	["videocard"] = {
		AdminLevel = 1,
		Index = "videocard",
		Name = "Placa de Vídeo",
		Type = "Comum",
		Weight = 4.25,
		Economy = 4225,
		LostWater = true
	},
	["television"] = {
		AdminLevel = 1,
		Index = "television",
		Name = "Televisão",
		Description = "Uma experiência visual imersiva equipada com tecnologia LED para cores vibrantes e detalhes nítidos oferecendo entretenimento de alta qualidade.",
		Type = "Comum",
		Weight = 12.5,
		Anim = "tv",
		LostWater = true,
		Economy = 5425,
		Market = true,
		Max = 1
	},
	["ssddrive"] = {
		AdminLevel = 1,
		Index = "ssddrive",
		Name = "Unidade SSD",
		Type = "Comum",
		Weight = 0.75,
		Economy = 525,
		LostWater = true
	},
	["safependrive"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "powercable",
		Name = "Cabo de Alimentação",
		Type = "Comum",
		Weight = 0.35,
		Economy = 225
	},
	["weaponparts"] = {
		AdminLevel = 1,
		Index = "weaponparts",
		Name = "Peças de Armas",
		Type = "Comum",
		Weight = 1.25,
		Economy = 125,
		Market = true,
		Arrest = true
	},
	["lightgunparts"] = {
		AdminLevel = 1,
		Index = "lightgunparts",
		Name = "Peças de Arma Leve",
		Blueprint = 65,
		Type = "Comum",
		Weight = 1.75,
		Economy = 625,
		Market = true
	},
	["mediumgunparts"] = {
		AdminLevel = 1,
		Index = "mediumgunparts",
		Name = "Peças de Arma Média",
		Blueprint = 125,
		Type = "Comum",
		Weight = 2.25,
		Economy = 1250,
		Market = true
	},
	["heavygunparts"] = {
		AdminLevel = 1,
		Index = "heavygunparts",
		Name = "Peças de Arma Pesada",
		Blueprint = 215,
		Type = "Comum",
		Weight = 2.75,
		Economy = 2125,
		Market = true
	},
	["electroniccomponents"] = {
		AdminLevel = 1,
		Index = "electroniccomponents",
		Name = "Componentes Eletrônicos",
		Type = "Comum",
		Weight = 0.35,
		Economy = 375,
		LostWater = true
	},
	["batteryaa"] = {
		AdminLevel = 1,
		Index = "batteryaa",
		Name = "Bateria AA",
		Type = "Comum",
		Weight = 0.15,
		Economy = 225,
		LostWater = true
	},
	["batteryaaplus"] = {
		AdminLevel = 1,
		Index = "batteryaaplus",
		Name = "Bateria AA+",
		Type = "Comum",
		Weight = 0.25,
		Economy = 275,
		LostWater = true
	},
	["goldnecklace"] = {
		AdminLevel = 1,
		Index = "goldnecklace",
		Name = "Colar de Ouro",
		Type = "Comum",
		Weight = 0.45,
		Economy = 625
	},
	["silverchain"] = {
		AdminLevel = 1,
		Index = "silverchain",
		Name = "Corrente de Prata",
		Type = "Comum",
		Weight = 0.40,
		Economy = 425
	},
	["horsefigurine"] = {
		AdminLevel = 1,
		Index = "horsefigurine",
		Name = "Estatueta de Cavalo",
		Type = "Comum",
		Weight = 1.25,
		Economy = 2425
	},
	["toothpaste"] = {
		AdminLevel = 1,
		Index = "toothpaste",
		Name = "Pasta de Dente",
		Type = "Comum",
		Weight = 0.15,
		Economy = 175
	},
	["goldenjug"] = {
		AdminLevel = 1,
		Index = "goldenjug",
		Name = "Jarro de Ouro",
		Type = "Comum",
		Weight = 7.25,
		Economy = 6775
	},
	["goldenleopard"] = {
		AdminLevel = 1,
		Index = "goldenleopard",
		Name = "Leopardo de Ouro",
		Type = "Comum",
		Weight = 8.75,
		Economy = 8225
	},
	["goldenlion"] = {
		AdminLevel = 1,
		Index = "goldenlion",
		Name = "Leão de Ouro",
		Type = "Comum",
		Weight = 10.25,
		Economy = 12225
	},
	-- COMIDAS
	["cola"] = {
		AdminLevel = 1,
		Index = "cola",
		Name = "Cola",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true
	},
	["tacos"] = {
		AdminLevel = 1,
		Index = "tacos",
		Name = "Tacos",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true
	},
	["fries"] = {
		AdminLevel = 1,
		Index = "fries",
		Name = "Fritas",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true
	},
	["water"] = {
		AdminLevel = 1,
		Index = "water",
		Name = "Garrafa de Água",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 35,
		Market = true
	},
	["soda"] = {
		AdminLevel = 1,
		Index = "soda",
		Name = "Sprunk",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true
	},
	["hotdog"] = {
		AdminLevel = 1,
		Index = "hotdog",
		Name = "Cachorro-Quente",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.45,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true
	},
	["donut"] = {
		AdminLevel = 1,
		Index = "donut",
		Name = "Rosquinha",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 15,
		Market = true,
		LostWater = true
	},
	["hamburger"] = {
		AdminLevel = 1,
		Index = "hamburger",
		Name = "Hambúrguer",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.55,
		Max = 2,
		Economy = 25,
		Market = true,
		LostWater = true
	},
	["chocolate"] = {
		AdminLevel = 1,
		Index = "chocolate",
		Name = "Chocolate",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.15,
		Max = 4,
		Economy = 20,
		Market = true
	},
	["sandwich"] = {
		AdminLevel = 1,
		Index = "sandwich",
		Name = "Sanduiche",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true
	},
	["coffeecup"] = {
		AdminLevel = 1,
		Index = "coffeecup",
		Name = "Copo de Café",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 2,
		Economy = 20,
		Market = true,
		LostWater = true
	},
	-- COMIDAS
	["nigirizushi"] = {
		AdminLevel = 1,
		Index = "nigirizushi",
		Name = "Nigirizushi",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.65,
		Max = 3,
		Economy = 60,
		Market = true,
		LostWater = true
	},
	["sushi"] = {
		AdminLevel = 1,
		Index = "sushi",
		Name = "Sushi",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.65,
		Max = 3,
		Economy = 60,
		Market = true,
		LostWater = true
	},
	["cupcake"] = {
		AdminLevel = 1,
		Index = "cupcake",
		Name = "Cupcake",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.55,
		Max = 3,
		Economy = 45,
		Market = true,
		LostWater = true
	},
	["milkshake"] = {
		AdminLevel = 1,
		Index = "milkshake",
		Name = "Milk-shake",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.85,
		Max = 3,
		Economy = 75,
		Market = true,
		LostWater = true
	},
	["cappuccino"] = {
		AdminLevel = 1,
		Index = "cappuccino",
		Name = "Cappuccino",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.65,
		Max = 3,
		Economy = 100,
		Market = true,
		LostWater = true
	},
	["applelove"] = {
		AdminLevel = 1,
		Index = "applelove",
		Name = "Maça do Amor",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.55,
		Max = 3,
		Economy = 35,
		Market = true,
		LostWater = true
	},
	["cookies"] = {
		AdminLevel = 1,
		Index = "cookies",
		Name = "Cookies",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.25,
		Max = 3,
		Economy = 45,
		Market = true,
		LostWater = true
	},
	["hamburger2"] = {
		AdminLevel = 1,
		Index = "hamburger2",
		Name = "Hambúrguer Artesanal",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		LostWater = true
	},
	["hamburger3"] = {
		AdminLevel = 1,
		Index = "hamburger3",
		Name = "Hambúrguer Vegetariano",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 125,
		Market = true,
		LostWater = true
	},
	["pizzamozzarella"] = {
		AdminLevel = 1,
		Index = "pizzamozzarella",
		Name = "Pizza de Muçarela",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		LostWater = true
	},
	["pizzabanana"] = {
		AdminLevel = 1,
		Index = "pizzabanana",
		Name = "Pizza de Banana",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		LostWater = true
	},
	["pizzachocolate"] = {
		AdminLevel = 1,
		Index = "pizzachocolate",
		Name = "Pizza de Chocolate",
		Type = "Consumível",
		Durability = 6,
		Weight = 0.75,
		Max = 3,
		Economy = 175,
		Market = true,
		LostWater = true
	},
	-- BOXES
	["treasurebox"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		Rarity = "rare",
		Locked = true
	},
	["mechanicbag"] = {
		AdminLevel = 1,
		Index = "mechanicbag",
		Name = "Caixa de Ferramentas",
		Description = "Projetada para armazenamento seguro e organizado de ferramentas, garantindo acessibilidade e segurança no ambiente de manutenção.",
		Repair = "repairkit01",
		Type = "Consumível",
		Durability = 720,
		Weight = 5.0,
		Unique = true,
		Market = true,
		Economy = 4275,
		Locked = true
	},
	-- OBJECTS
	["watercooler"] = {
		AdminLevel = 1,
		Index = "watercooler",
		Name = "Bebedouro",
		Type = "Consumível",
		Durability = 720,
		Weight = 2.25,
		Market = true
	},
	["pistol_bench"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "securitycam",
		Name = "CCTV Câmera",
		Description = "Câmera de segurança instalável que permite o monitoramento em tempo real de áreas estratégicas. Após instalada, o acesso ao painel de controle fica disponível dentro do local selecionado dos grupos em suas bases, garantindo vigilância, controle e segurança do perímetro.",
		Type = "Consumível",
		Durability = 240,
		Weight = 7.75,
		Delete = true,
		Market = true
	},
	["barrier"] = {
		AdminLevel = 1,
		Index = "barrier",
		Name = "Barreira",
		Type = "Consumível",
		Durability = 168,
		Weight = 2.25,
		Max = 2,
		Economy = 25,
		Market = true
	},
	["chestgroupp"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "spikestrips",
		Name = "Tiras de Espinhos",
		Type = "Consumível",
		Weight = 1.25,
		Max = 1,
		Economy = 275,
		Market = true
	},
	["moneywash"] = {
		AdminLevel = 1,
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><common>Lavagem diária: $250.000</common>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "common"
	},
	["moneywashplus"] = {
		AdminLevel = 1,
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><rare>Lavagem diária: $500.000</rare>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "rare"
	},
	["moneywashalpha"] = {
		AdminLevel = 1,
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><epic>Lavagem diária: $1.000.000</epic>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "epic"
	},
	["moneywashomega"] = {
		AdminLevel = 1,
		Index = "moneywash",
		Name = "Máquina de Lavar",
		Description = "Compacta e discreta que transforma dinheiro molhado em dinheiro limpo e pronto para uso, seja para jogos ou necessidades do dia a dia, esta máquina é a solução perfeita para lavagem de dinheiro de forma rápida e eficiente.<br><br><legendary>Lavagem diária: $5.000.000</legendary>",
		Type = "Consumível",
		Weight = 50.0,
		Market = true,
		Rarity = "legendary"
	},
	["washbattery"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "rocket",
		Name = "Munição de Foguete",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 2.25
	},
	["WEAPON_PISTOL_AMMO"] = {
		AdminLevel = 1,
		Index = "pistolammo",
		Name = "Munição de Pistola",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.025,
		Economy = 15
	},
	["WEAPON_SMG_AMMO"] = {
		AdminLevel = 1,
		Index = "smgammo",
		Name = "Munição de Sub",
		Type = "Munição",
		Market = true,
		Weight = 0.025,
		Economy = 20
	},
	["WEAPON_RIFLE_AMMO"] = {
		AdminLevel = 1,
		Index = "rifleammo",
		Name = "Munição de Rifle",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.025,
		Economy = 25
	},
	["WEAPON_SHOTGUN_AMMO"] = {
		AdminLevel = 1,
		Index = "shotgunammo",
		Name = "Munição de Espingarda",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.050,
		Economy = 50
	},
	["WEAPON_MUSKET_AMMO"] = {
		AdminLevel = 1,
		Index = "musketammo",
		Name = "Munição de Mosquete",
		Type = "Munição",
		Arrest = true,
		Market = true,
		Weight = 0.075,
		Economy = 10
	},
	["WEAPON_PETROLCAN_AMMO"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "ritmoneury",
		Name = "Ritmoneury",
		Type = "Consumível",
		Weight = 0.75,
		Max = 2,
		Economy = 325,
		Market = true
	},
	["sinkalmy"] = {
		AdminLevel = 1,
		Index = "sinkalmy",
		Name = "Sinkalmy",
		Type = "Consumível",
		Weight = 0.75,
		Max = 2,
		Economy = 425,
		Market = true
	},
	["analgesic"] = {
		AdminLevel = 1,
		Index = "analgesic",
		Name = "Analgésicos",
		Type = "Consumível",
		Weight = 0.25,
		Economy = 175,
		Blueprint = 17,
		Market = true
	},
	["gauze"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "gsrkit",
		Name = "Kit Residual",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.75,
		Economy = 25,
		Market = true
	},
	["gdtkit"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "bait",
		Name = "Isca",
		Type = "Comum",
		Weight = 0.25,
		Economy = 5,
		Market = true
	},
	["fishfillet"] = {
		AdminLevel = 1,
		Index = "fishfillet",
		Name = "Filé de Peixe",
		Type = "Comum",
		Weight = 0.05,
		Economy = 10,
		Market = true
	},
	["meatfillet"] = {
		AdminLevel = 1,
		Index = "meatfillet",
		Name = "Filé de Carne",
		Type = "Comum",
		Weight = 0.05,
		Economy = 10,
		Market = true
	},
	["anchovy"] = {
		AdminLevel = 1,
		Index = "anchovy",
		Name = "Anchova",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 50,
		Market = true,
		Fishing = 5
	},
	["catfish"] = {
		AdminLevel = 1,
		Index = "catfish",
		Name = "Peixe-Gato",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 70,
		Market = true,
		Fishing = 7
	},
	["herring"] = {
		AdminLevel = 1,
		Index = "herring",
		Name = "Arenque",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 80,
		Market = true,
		Fishing = 8
	},
	["orangeroughy"] = {
		AdminLevel = 1,
		Index = "orangeroughy",
		Name = "Peixe Relógio",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 60,
		Market = true,
		Fishing = 6
	},
	["salmon"] = {
		AdminLevel = 1,
		Index = "salmon",
		Name = "Salmão",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 150,
		Market = true,
		Fishing = 15
	},
	["sardine"] = {
		AdminLevel = 1,
		Index = "sardine",
		Name = "Sardinha",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 60,
		Market = true,
		Fishing = 6
	},
	["smallshark"] = {
		AdminLevel = 1,
		Index = "smallshark",
		Name = "Tubarão Pequeno",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 250,
		Market = true,
		Fishing = 25
	},
	["smalltrout"] = {
		AdminLevel = 1,
		Index = "smalltrout",
		Name = "Truta Pequena",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 70,
		Market = true,
		Fishing = 7
	},
	["yellowperch"] = {
		AdminLevel = 1,
		Index = "yellowperch",
		Name = "Poleiro Amarelo",
		Type = "Comum",
		Weight = 0.50,
		LostWater = true,
		Economy = 80,
		Market = true,
		Fishing = 8
	},
	["package"] = {
		AdminLevel = 1,
		Index = "package",
		Name = "Encomenda",
		Type = "Comum",
		Weight = 10.0,
		Anim = "caixa",
		LostWater = true,
		Economy = 0,
		Market = true,
		Max = 1
	},
	["binbag"] = {
		AdminLevel = 1,
		Index = "binbag",
		Name = "Saco de Lixo",
		Type = "Comum",
		Weight = 10.0,
		Anim = "lixo",
		LostWater = true,
		Economy = 0,
		Market = true,
		Max = 1
	},
	["milkbottle"] = {
		AdminLevel = 1,
		Index = "milkbottle",
		Name = "Garrafa de Leite",
		Type = "Comum",
		Weight = 0.35,
		Economy = 35,
		Market = true
	},
	["pouch"] = {
		AdminLevel = 1,
		Index = "pouch",
		Name = "Malote",
		Type = "Comum",
		Weight = 1.25,
		Economy = 0,
		Market = true,
		LostWater = true
	},
	["woodlog"] = {
		AdminLevel = 1,
		Index = "woodlog",
		Name = "Tora de Madeira",
		Type = "Comum",
		Weight = 1.0,
		Economy = 0,
		Market = true,
		LostWater = true
	},
	["sapphire_pure"] = {
		AdminLevel = 1,
		Index = "sapphire_pure",
		Name = "Safira Lapidada",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 60,
		Market = true
	},
	["emerald_pure"] = {
		AdminLevel = 1,
		Index = "emerald_pure",
		Name = "Esmeralda Lapidada",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 75,
		Market = true
	},
	["ruby_pure"] = {
		AdminLevel = 1,
		Index = "ruby_pure",
		Name = "Ruby Lapidado",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 60,
		Market = true
	},
	["gold_pure"] = {
		AdminLevel = 1,
		Index = "gold_pure",
		Name = "Barra de Ouro",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 50,
		Market = true
	},
	["iron_pure"] = {
		AdminLevel = 1,
		Index = "iron_pure",
		Name = "Barra de Ferro",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 45,
		Market = true
	},
	["lead_pure"] = {
		AdminLevel = 1,
		Index = "lead_pure",
		Name = "Barra de Chumbo",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 40,
		Market = true
	},
	["tin_pure"] = {
		AdminLevel = 1,
		Index = "tin_pure",
		Name = "Barra de Estanho",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 40,
		Market = true
	},
	["diamond_pure"] = {
		AdminLevel = 1,
		Index = "diamond_pure",
		Name = "Diamante Lapidado",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 50,
		Market = true
	},
	["copper_pure"] = {
		AdminLevel = 1,
		Index = "copper_pure",
		Name = "Barra de Cobre",
		Type = "Comum",
		Weight = 0.5,
		LostWater = true,
		Economy = 42,
		Market = true
	},
	["ration"] = {
		AdminLevel = 1,
		Index = "ration",
		Name = "Ração Animal",
		Type = "Consumível",
		Weight = 0.75,
		LostWater = true,
		Economy = 125,
		Market = true
	},
	["coyote1star"] = {
		AdminLevel = 1,
		Index = "box1star",
		Name = "Coyote",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true
	},
	["coyote2star"] = {
		AdminLevel = 1,
		Index = "box2star",
		Name = "Coyote",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true
	},
	["coyote3star"] = {
		AdminLevel = 1,
		Index = "box3star",
		Name = "Coyote",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true
	},
	["mtlion1star"] = {
		AdminLevel = 1,
		Index = "box1star",
		Name = "Puma",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true
	},
	["mtlion2star"] = {
		AdminLevel = 1,
		Index = "box2star",
		Name = "Puma",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true
	},
	["mtlion3star"] = {
		AdminLevel = 1,
		Index = "box3star",
		Name = "Puma",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true
	},
	["boar1star"] = {
		AdminLevel = 1,
		Index = "box1star",
		Name = "Javali",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true
	},
	["boar2star"] = {
		AdminLevel = 1,
		Index = "box2star",
		Name = "Javali",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true
	},
	["boar3star"] = {
		AdminLevel = 1,
		Index = "box3star",
		Name = "Javali",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true
	},
	["deer1star"] = {
		AdminLevel = 1,
		Index = "box1star",
		Name = "Cervo",
		Type = "Comum",
		Weight = 2.25,
		Economy = 275,
		Market = true
	},
	["deer2star"] = {
		AdminLevel = 1,
		Index = "box2star",
		Name = "Cervo",
		Type = "Comum",
		Weight = 2.25,
		Economy = 300,
		Market = true
	},
	["deer3star"] = {
		AdminLevel = 1,
		Index = "box3star",
		Name = "Cervo",
		Type = "Comum",
		Weight = 2.25,
		Economy = 325,
		Market = true
	},
	-- OUTROS
	["legendarykey"] = {
		AdminLevel = 1,
		Index = "legendarykey",
		Name = "Chave da Fortuna",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		Charges = 3,
		Weight = 0.25,
		Economy = 4225,
		Market = true,
		Rarity = "legendary"
	},
	["weaponkey"] = {
		AdminLevel = 1,
		Index = "weaponkey",
		Name = "Chave da Harmonia",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		Charges = 10,
		Weight = 0.25,
		Economy = 725,
		Market = true,
		Rarity = "epic"
	},
	["medicalkey"] = {
		AdminLevel = 1,
		Index = "medicalkey",
		Name = "Chave da Aurora",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		Charges = 10,
		Weight = 0.25,
		Economy = 675,
		Market = true,
		Rarity = "rare"
	},
	["utilkey"] = {
		AdminLevel = 1,
		Index = "utilkey",
		Name = "Chave do Crepúsculo",
		Description = "Projetada para ser encontrada e utilizada como parte da progressão na história ou na resolução de um enigma, adicionando um elemento de interatividade e imersão à experiência.",
		Type = "Comum",
		Charges = 10,
		Weight = 0.25,
		Economy = 625,
		Market = true,
		Rarity = "common"
	},
	["sugarbox"] = {
		AdminLevel = 1,
		Index = "sugarbox",
		Name = "Caixa de Açucar",
		Type = "Comum",
		Weight = 0.25,
		Economy = 35,
		Market = true
	},
	["condensedmilk"] = {
		AdminLevel = 1,
		Index = "condensedmilk",
		Name = "Leite Condensado",
		Type = "Comum",
		Weight = 0.25,
		Economy = 25,
		Market = true
	},
	["mayonnaise"] = {
		AdminLevel = 1,
		Index = "mayonnaise",
		Name = "Pote de Maionese",
		Type = "Comum",
		Weight = 0.45,
		Economy = 20,
		Market = true
	},
	["ryebread"] = {
		AdminLevel = 1,
		Index = "ryebread",
		Name = "Pão de Centeio",
		Type = "Comum",
		Weight = 0.15,
		Economy = 20,
		Market = true
	},
	["ricebag"] = {
		AdminLevel = 1,
		Index = "ricebag",
		Name = "Saco de Arroz",
		Type = "Comum",
		Weight = 1.25,
		Economy = 105,
		Market = true
	},
	["dogtag"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "adrenaline",
		Name = "Adrenalina",
		Type = "Comum",
		Weight = 0.25,
		Market = true,
		Economy = 4225
	},
	["dismantle"] = {
		AdminLevel = 1,
		Index = "dismantle",
		Name = "Cartão Ilegível",
		Type = "Consumível",
		Arrest = true,
		Weight = 0.0,
		Economy = 1225,
		Market = true
	},
	["platinum"] = {
		AdminLevel = 1,
		Index = "platinum",
		Name = "Platina",
		Type = "Comum",
		Weight = 0.0,
		Economy = 20
	},
	["binoculars"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "creditcard",
		Name = "Cartão de Crédito",
		Type = "Comum",
		Weight = 0.25,
		Delete = true,
		Economy = 0,
		Market = true
	},
	["propertys"] = {
		AdminLevel = 1,
		Index = "propertys",
		Name = "Chave de Ferro",
		Type = "Consumível",
		Weight = 0.35,
		Delete = true,
		Economy = 0,
		Market = true
	},
	["emptypurifiedwater"] = {
		AdminLevel = 1,
		Index = "emptypurifiedwater",
		Name = "Galão de Água Vazio",
		Description = "Prático para transporte e armazenamento, ideal para reutilização ou descarte responsável.",
		Type = "Comum",
		Weight = 0.75,
		Economy = 1275,
		Market = true
	},
	["purifiedwater"] = {
		AdminLevel = 1,
		Index = "purifiedwater",
		Name = "Galão de Água Purificada",
		Description = "Essencial para hidratação segura e saudável, ideal para uso doméstico ou comercial.",
		Type = "Comum",
		Weight = 1.25,
		Economy = 1275,
		Market = true,
		Charges = 10,
		Empty = "emptypurifiedwater"
	},
	["racestablet"] = {
		AdminLevel = 1,
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
			Event = "races:Item"
		}
	},
	["racesticket"] = {
		AdminLevel = 1,
		Index = "racesticket",
		Name = "Cartão Descartável",
		Description = "Explore circuitos exclusivos e de acesso privilegiado, desbloqueie portas para emocionantes experiências em locais de elite ao redor do mundo.",
		Type = "Comum",
		Arrest = true,
		Weight = 0.15,
		Economy = 2275,
		Market = true,
		Charges = 5,
		Rarity = "epic"
	},
	["racetrophy1"] = {
		AdminLevel = 1,
		Index = "racetrophy1",
		Name = "Troféu 1º Lúgar",
		Description = "Conquistado apenas por quem cruza a linha de chegada em primeiro lugar, este item representa habilidade, precisão e domínio absoluto nas pistas. Símbolo máximo de desempenho nas corridas, o Troféu do Campeão comprova que seu portador superou todos os adversários com excelência, garantindo seu lugar no topo do ranking.",
		Rarity = "legendary",
		Type = "Comum",
		Weight = 0.0
	},
	["racetrophy2"] = {
		AdminLevel = 1,
		Index = "racetrophy2",
		Name = "Troféu 2º Lúgar",
		Description = "Conquistado apenas por quem cruza a linha de chegada em segundo lugar, este item representa habilidade, precisão e domínio absoluto nas pistas. Símbolo máximo de desempenho nas corridas, o Troféu do Campeão comprova que seu portador superou todos os adversários com excelência, garantindo seu lugar no topo do ranking.",
		Rarity = "epic",
		Type = "Comum",
		Weight = 0.0
	},
	["racetrophy3"] = {
		AdminLevel = 1,
		Index = "racetrophy3",
		Name = "Troféu 3º Lúgar",
		Description = "Conquistado apenas por quem cruza a linha de chegada em terceiro lugar, este item representa habilidade, precisão e domínio absoluto nas pistas. Símbolo máximo de desempenho nas corridas, o Troféu do Campeão comprova que seu portador superou todos os adversários com excelência, garantindo seu lugar no topo do ranking.",
		Rarity = "rare",
		Type = "Comum",
		Weight = 0.0
	},
	["postit"] = {
		AdminLevel = 1,
		Index = "postit",
		Name = "Post-It",
		Type = "Consumível",
		Weight = 0.25,
		LostWater = true,
		Economy = 20
	},
	["blocksignal"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "coilover",
		Name = "Suspensão Coilover",
		Description = "Projetada para oferecer ajustabilidade extrema e resposta rápida em curvas fechadas e mudanças de direção rápidas, ajuda a maximizar a aderência nas curvas e proporcionar uma sensação precisa e controlada ao volante, fundamental para executar manobras precisas e controladas durante as competições de drift.",
		Type = "Consumível",
		Weight = 15.25,
		Economy = 24725,
		Market = true
	},
	["vehiclekey"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "cigarette",
		Name = "Maço de Cigarros",
		Type = "Consumível",
		Weight = 0.15,
		Max = 5,
		LostWater = true,
		Economy = 15
	},
	["lighter"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "dollar",
		Name = "Dólar",
		Type = "Comum",
		Weight = 0.0,
		Market = true,
		Economy = 1,
		Arrest = true
	},
	["dirtydollar"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "wetdollar",
		Name = "Dólar Molhado",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 1
	},
	["promissory1000"] = {
		AdminLevel = 1,
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 1000
	},
	["promissory2000"] = {
		AdminLevel = 1,
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 2000
	},
	["promissory3000"] = {
		AdminLevel = 1,
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 3000
	},
	["promissory4000"] = {
		AdminLevel = 1,
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 4000
	},
	["promissory5000"] = {
		AdminLevel = 1,
		Index = "promissory",
		Name = "Nota Promissória",
		Type = "Comum",
		Arrest = true,
		Weight = 0.0,
		Market = true,
		Economy = 5000
	},
	["pager"] = {
		AdminLevel = 1,
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
		AdminLevel = 1,
		Index = "soap",
		Name = "Sabonete",
		Type = "Consumível",
		Weight = 0.25,
		Water = "In",
		Economy = 125,
		Market = true
	},
	["emptybottle"] = {
		AdminLevel = 1,
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
-- PURITYS
-----------------------------------------------------------------------------------------------------------------------------------------
Puritys = {
	{
		Percent = 0,
		Chance = 100
	},{
		Percent = 10,
		Chance = 90
	},{
		Percent = 20,
		Chance = 80
	},{
		Percent = 30,
		Chance = 70
	},{
		Percent = 40,
		Chance = 60
	},{
		Percent = 50,
		Chance = 50
	},{
		Percent = 60,
		Chance = 40
	},{
		Percent = 70,
		Chance = 30
	},{
		Percent = 80,
		Chance = 20
	},{
		Percent = 90,
		Chance = 10
	},{
		Percent = 100,
		Chance = 1
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLONEVARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
Clones = {
	{
		Clone = "tomato",
		Name = "Tomate",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "passion",
		Name = "Maracujá",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "tange",
		Name = "Tangerina",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "orange",
		Name = "Laranja",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "apple",
		Name = "Maça",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "grape",
		Name = "Uva",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "lemon",
		Name = "Limão",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "banana",
		Name = "Banana",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "acerola",
		Name = "Acerola",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "strawberry",
		Name = "Morango",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "blueberry",
		Name = "Blueberry",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "coffee",
		Name = "Café",
		Hash = "bkr_prop_weed_med_01b",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "weed",
		Name = "Cannabis",
		Hash = "bkr_prop_weed_med_01a",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	},{
		Clone = "coke",
		Name = "Cocaína",
		Hash = "bkr_prop_weed_med_01a",
		AdminLevel = 1,
		Min = 3,
		Max = 6
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- FURNITURE
-----------------------------------------------------------------------------------------------------------------------------------------
Furniture = {
	{
		Item = "pack_bathcab",
		Name = "Armário de Banheiro",
		Hash = "gcom_dec_pack_bathcab",
		AdminLevel = 1
	},{
		Item = "pack_cabinet",
		Name = "Armário Quatro Portas",
		Hash = "gcom_dec_pack_cabinet",
		AdminLevel = 1
	},{
		Item = "pack_cabinet_2",
		Name = "Hack de Televisão",
		Hash = "gcom_dec_pack_cabinet_2",
		AdminLevel = 1
	},{
		Item = "pack_table_1",
		Name = "Mesa de Escritório",
		Hash = "gcom_dec_pack_table_1",
		AdminLevel = 1
	},{
		Item = "pack_table_2",
		Name = "Mesa de Jantar",
		Hash = "gcom_dec_pack_table_2",
		AdminLevel = 1
	},{
		Item = "pack_wall",
		Name = "Divisor de Ambiente",
		Hash = "gcom_dec_pack_wall",
		AdminLevel = 1
	},{
		Item = "pack_wardrobe_1",
		Name = "Guarda-Roupas Quatro Portas",
		Hash = "gcom_dec_pack_wardrobe_1",
		AdminLevel = 1
	},{
		Item = "pack_wardrobe_2",
		Name = "Guarda-Roupas Seis Portas",
		Hash = "gcom_dec_pack_wardrobe_2",
		AdminLevel = 1
	},{
		Item = "pack_cabinet_3",
		Name = "Guarda-Roupas Antigo",
		Hash = "murm_dec_pack_cabinet",
		AdminLevel = 1
	},{
		Item = "pack_chair_1",
		Name = "Cadeira de Madeira",
		Hash = "murm_dec_pack_chair_1",
		AdminLevel = 1
	},{
		Item = "pack_chair_2",
		Name = "Cadeira de Couro",
		Hash = "murm_dec_pack_chair_2",
		AdminLevel = 1
	},{
		Item = "pack_dresser",
		Name = "Cômoda de Madeira",
		Hash = "murm_dec_pack_dresser",
		AdminLevel = 1
	},{
		Item = "pack_sofa",
		Name = "Sofá de Courino",
		Hash = "murm_dec_pack_sofa",
		AdminLevel = 1
	},{
		Item = "pack_table",
		Name = "Mesa de Madeira",
		Hash = "murm_dec_pack_table",
		AdminLevel = 1
	},{
		Item = "halloween_pumpkin",
		Name = "Abóbora de Halloween",
		Hash = "tfx-summer_abroba",
		AdminLevel = 1
	},{
		Item = "halloween_ghost",
		Name = "Fantasma de Halloween",
		Hash = "tfx-summer_ghost",
		AdminLevel = 1
	},{
		Item = "largebed",
		Name = "Cama",
		Hash = "hei_heist_bed_double_08",
		AdminLevel = 1
	},{
		Item = "browncloset",
		Name = "Guarda-Roupas Duas Portas",
		Rarity = "epic",
		Hash = "v_res_m_armoire",
		AdminLevel = 1
	},{
		Item = "simplebox",
		Name = "Cofre Básico",
		Hash = "prop_ld_int_safe_01",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>100KG</legendary> dentro de seu compartimento.",
		Delete = true,
		AdminLevel = 1
	},{
		Item = "safebox",
		Name = "Cofre Reforçado",
		Rarity = "rare",
		Hash = "p_v_43_safe_s",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>200KG</legendary> dentro de seu compartimento.",
		Delete = true,
		AdminLevel = 1
	},{
		Item = "officebox",
		Name = "Cofre Blindado",
		Rarity = "epic",
		Hash = "sf_prop_v_43_safe_s_bk_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>500KG</legendary> dentro de seu compartimento.",
		Delete = true,
		AdminLevel = 1
	},{
		Item = "industrialbox",
		Name = "Cofre Industrial",
		Rarity = "epic",
		Hash = "xm3_prop_xm3_safe_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>1000KG</legendary> dentro de seu compartimento.",
		Delete = true,
		AdminLevel = 1
	},{
		Item = "ornamentbox",
		Name = "Cofre Corporativo",
		Rarity = "legendary",
		Hash = "h4_prop_h4_safe_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>1500KG</legendary> dentro de seu compartimento.",
		Delete = true,
		AdminLevel = 1
	},{
		Item = "goldenbox",
		Name = "Cofre Executivo",
		Rarity = "legendary",
		Hash = "sf_prop_v_43_safe_s_gd_01a",
		Description = "Este objeto pode ser posicionado dentro de propriedades, permitindo guardar <legendary>2500KG</legendary> dentro de seu compartimento.",
		Delete = true,
		AdminLevel = 1
	}
}
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
				AdminLevel = v.AdminLevel or 1,
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
			AdminLevel = v.AdminLevel or 1,
			LostWater = true,
			Weight = 0.15,
			Market = true,
			Economy = 15
		}

		for _,w in pairs(Puritys) do
			List[v.Clone.."clone_"..w.Percent] = {
				Index = "clone",
				Name = "Clonagem de "..v.Name,
				AdminLevel = v.AdminLevel or 1,
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
			AdminLevel = v.AdminLevel or 1,
			Description = v.Description or "Este objeto pode ser posicionado dentro de propriedades, permitindo personalizar e organizar o ambiente."
		}
	end

	for Model,v in pairs(ListVehicles) do
		if v.Item then
			List["vehicle_"..Model] = {
				Index = "vehicle",
				Name = v.Name,
				Type = "Consumível",
				Delete = true,
				Weight = 0.0
			}
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLIST
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemList",function()
	return List
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMCLONES
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemClones",function()
	return Clones
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMPURITYS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemPuritys",function()
	return Puritys
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMFURNITURE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemFurniture",function()
	return Furniture
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemExist",function(Item)
	return List[SplitOne(Item)]
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMINDEX
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemIndex",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Index or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMNAME
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemName",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Name or "Deletado"
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMTYPE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemType",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Type or "Comum"
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMTYPECHECK
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemTypeCheck",function(Item,Mode)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Type and List[Item].Type == Mode and true or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemVehicle",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Vehicle or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMWEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemWeight",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Weight or 0.0
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMBACKPACK
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemBackpack",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Backpack or 0
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMMAXAMOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemMaxAmount",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Max or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLOSTWATER
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemLostWater",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].LostWater or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMWATER
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemWater",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Water or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMDESCRIPTION
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemDescription",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Description or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMDURABILITY
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemDurability",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Durability or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLOADS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemLoads",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Charges or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMREPAIR
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemRepair",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Repair or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMUNIQUE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemUnique",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Unique or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMANIM
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemAnim",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Anim or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMEXECUTE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemExecute",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Execute or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMARREST
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemArrest",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Arrest or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMSERIAL
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemSerial",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Serial or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMECONOMY
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemEconomy",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Economy or 0
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMRARITY
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemRarity",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Rarity or "normal"
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMRECYCLE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemRecycle",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Recycle or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMFISHING
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemFishing",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Fishing or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMNAMED
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemNamed",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Named or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMEMPTY
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemEmpty",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Empty or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMSKINSHOP
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemSkinshop",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Skinshop or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMLOCKED
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemLocked",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Locked or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMMARKERS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemMarkers",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Markers or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMADMIN
-----------------------------------------------------------------------------------------------------------------------------------------
exports("ItemAdmin",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].AdminLevel or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLOCKDELETE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("BlockDelete",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Delete or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLOCKMARKET
-----------------------------------------------------------------------------------------------------------------------------------------
exports("BlockMarket",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Market or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMAMMO
-----------------------------------------------------------------------------------------------------------------------------------------
exports("WeaponAmmo",function(Item)
	local Item = SplitOne(Item)
	return List[Item] and List[Item].Ammo or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEAPONATTACH
-----------------------------------------------------------------------------------------------------------------------------------------
exports("WeaponAttach",function(Item,Weapon)
	local Item = SplitOne(Item)
	return List[Weapon] and List[Weapon].Attachs and List[Weapon].Attachs[Item] or false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
ListItem = List