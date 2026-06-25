-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
Config = {
	DefaulName = "Posto de Combustível",
	DefaultScale = 0.5,
	DefaultColor = 47,
	DefaultIcon = 361,

	EmptyDaysStock = 3,

	MinPricePerLiter = 1.0,
	MaxPricePerLiter = 25.0,
	DefaultPricePerLiter = 5.0,
	DefaultMaxStock = 10000,

	ItemGallon = "WEAPON_PETROLCAN",
	ItemGallonFuel = "WEAPON_PETROLCAN_AMMO",
	GallonFuelAmount = 5000,
	StockGallon = 50,

	BankTaxWithdraw = 1.0,
	BankTaxTransfer = 1.0,
	TaxTransfer = 0.3,

	Replenishments = {
		{
			Name = "Abastecimento Pequeno",
			Amount = 100,
			Import = 375,
			Export = 700,
			Image = "small",
			Package = "Small"
		},{
			Name = "Abastecimento Médio",
			Amount = 250,
			Import = 925,
			Export = 1850,
			Image = "medium",
			Package = "Medium"
		},{
			Name = "Abastecimento Grande",
			Amount = 500,
			Import = 1875,
			Export = 3750,
			Image = "large",
			Package = "Large"
		}
	},

	Upgrades = {
		Stock = {
			{
				Amount = 250,
				Price = 5000
			},{
				Amount = 500,
				Price = 10000
			},{
				Amount = 1000,
				Price = 20000
			},{
				Amount = 1500,
				Price = 30000
			},{
				Amount = 2000,
				Price = 40000
			}
		},
		Truck = {
			{
				Amount = 10,
				Price = 5000
			},{
				Amount = 20,
				Price = 10000
			},{
				Amount = 30,
				Price = 15000
			},{
				Amount = 40,
				Price = 20000
			},{
				Amount = 50,
				Price = 25000
			}
		},
		Relationship = {
			{
				Amount = 5,
				Price = 5000
			},{
				Amount = 10,
				Price = 10000
			},{
				Amount = 20,
				Price = 20000
			},{
				Amount = 30,
				Price = 30000
			},{
				Amount = 40,
				Price = 40000
			}
		}
	},

	Permissions = { -- ( -1 = Ninguém tem permissão | 0 = Todos tem permissão | 2 = 2 e 1 tem permissão )
		Stock = {
			View = 0,
			Edit = 1
		},
		Replenishment = {
			View = 0,
			Import = 0,
			Export = -1
		},
		OfferJobs = {
			View = -1,
			Create = -1,
			Edit = -1,
			Destroy = -1
		},
		Bank = {
			View = 0,
			Deposit = 0,
			Withdraw = 1,
			Transfer = 1
		},
		Update = 1,
		Upgrades = -1,
		Employees = {
			View = 1,
			Create = 1,
			Edit = 1,
			Dismiss = 1
		}
	},

	OtherPermissions = {}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
Locations = {
	FuelStation01 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(289.31,-1266.87,29.44,87.88),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(266.47,-1260.89,29.13),
		Delivery = vec3(287.94,-1244.36,29.22),
		Packages = {
			Small = vec3(2588.64,405.87,108.45),
			Medium = vec3(2651.78,3268.48,55.23),
			Large = vec3(146.19,6630.78,31.66)
		}
	},
	FuelStation02 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(2673.82,3266.99,55.23,243.78),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(2680.24,3264.04,55.23),
		Delivery = vec3(2691.41,3272.88,55.23),
		Packages = {
			Small = vec3(642.77,269.82,103.14),
			Medium = vec3(826.86,-1042.74,27.03),
			Large = vec3(-66.01,-1777.43,28.68)
		}
	},
	FuelStation03 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-2072.98,-327.28,13.31,85.04),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-2096.17,-316.82,13.02),
		Delivery = vec3(-2102.82,-294.35,13.04),
		Packages = {
			Small = vec3(1197.49,-1407.13,35.22),
			Medium = vec3(2589.45,406.92,108.45),
			Large = vec3(146.19,6630.78,31.66)
		}
	},
	FuelStation04 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-2544.1,2315.93,33.21,2.84),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-2555.12,2334.27,33.08),
		Delivery = vec3(-2529.79,2333.89,33.06),
		Packages = {
			Small = vec3(-509.85,-1204.15,19.14),
			Medium = vec3(259.97,-1240.97,29.15),
			Large = vec3(1197.46,-1405.12,35.22)
		}
	},
	FuelStation05 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(161.97,6636.51,31.56,133.23),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(180.08,6602.98,31.86),
		Delivery = vec3(148.77,6629.39,31.69),
		Packages = {
			Small = vec3(1688.43,4918.25,42.07),
			Medium = vec3(1025.29,2665.53,39.55),
			Large = vec3(1177.77,-315.41,69.17)
		}
	},
	FuelStation06 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(818.17,-1040.94,26.74,0.0),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(820.07,-1028.58,26.29),
		Delivery = vec3(827.33,-1044.0,27.14),
		Packages = {
			Small = vec3(-1819.04,805.64,138.66),
			Medium = vec3(1214.85,2664.97,37.79),
			Large = vec3(1686.28,4919.35,42.07)
		}
	},
	FuelStation07 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1211.13,-1388.92,35.37,175.75),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1208.84,-1401.95,35.22),
		Delivery = vec3(1198.79,-1394.43,35.22),
		Packages = {
			Small = vec3(-1420.56,-284.53,46.24),
			Medium = vec3(275.4,2611.4,44.69),
			Large = vec3(1715.98,6414.73,33.36)
		}
	},
	FuelStation08 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1167.08,-323.32,69.25,289.14),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1181.57,-330.23,69.32),
		Delivery = vec3(1178.75,-314.9,69.17),
		Packages = {
			Small = vec3(-2095.56,-300.51,13.02),
			Medium = vec3(59.98,2775.84,57.88),
			Large = vec3(1685.86,4920.03,42.07)
		}
	},
	FuelStation09 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(646.42,267.29,103.26,62.37),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(620.89,269.12,103.09),
		Delivery = vec3(635.48,258.62,103.09),
		Packages = {
			Small = vec3(2589.09,407.98,108.45),
			Medium = vec3(1977.51,3761.5,32.18),
			Large = vec3(-2570.33,2335.07,33.06)
		}
	},
	FuelStation10 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(2559.05,373.8,108.61,274.97),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(2581.18,361.77,108.46),
		Delivery = vec3(2565.83,354.84,108.46),
		Packages = {
			Small = vec3(242.06,2600.91,45.12),
			Medium = vec3(-65.94,-1776.47,28.75),
			Large = vec3(-2568.88,2336.39,33.06)
		}
	},
	FuelStation11 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(166.73,-1553.3,29.25,223.94),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(174.98,-1561.8,29.25),
		Delivery = vec3(184.94,-1553.64,29.2),
		Packages = {
			Small = vec3(-2096.95,-300.94,13.02),
			Medium = vec3(2531.93,2621.79,37.95),
			Large = vec3(1685.1,4920.88,42.07)
		}
	},
	FuelStation12 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-342.61,-1482.96,30.72,272.13),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-319.68,-1471.58,30.55),
		Delivery = vec3(-335.96,-1481.65,30.62),
		Packages = {
			Small = vec3(-1819.81,807.25,138.72),
			Medium = vec3(2531.91,2633.28,37.95),
			Large = vec3(1685.97,4920.7,42.07)
		}
	},
	FuelStation13 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1776.28,3327.37,41.43,303.31),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1784.59,3330.11,41.27),
		Delivery = vec3(1775.29,3337.94,41.15),
		Packages = {
			Small = vec3(2566.09,401.52,108.46),
			Medium = vec3(-2571.4,2334.22,33.06),
			Large = vec3(-69.48,-1779.42,28.36)
		}
	},
	FuelStation14 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(46.62,2789.39,57.88,144.57),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(50.42,2780.25,57.88),
		Delivery = vec3(38.44,2797.94,57.88),
		Packages = {
			Small = vec3(-1819.39,808.34,138.69),
			Medium = vec3(1179.3,-314.5,69.17),
			Large = vec3(-68.76,-1779.24,28.37)
		}
	},
	FuelStation15 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(265.97,2598.23,44.84,11.34),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(263.89,2607.86,44.97),
		Delivery = vec3(243.12,2601.17,45.11),
		Packages = {
			Small = vec3(2587.77,407.98,108.45),
			Medium = vec3(1180.38,-314.29,69.17),
			Large = vec3(-337.89,-1475.76,30.58)
		}
	},
	FuelStation16 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1039.4,2664.12,39.55,0.0),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1039.22,2671.18,39.55),
		Delivery = vec3(1056.85,2668.03,39.55),
		Packages = {
			Small = vec3(636.59,259.61,103.09),
			Medium = vec3(-78.51,6432.55,31.46),
			Large = vec3(-2098.64,-297.54,13.04)
		}
	},
	FuelStation17 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1200.56,2655.74,37.84,317.49),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1207.15,2659.68,37.9),
		Delivery = vec3(1213.94,2666.35,37.79),
		Packages = {
			Small = vec3(1716.07,6415.84,33.31),
			Medium = vec3(-1820.4,807.58,138.74),
			Large = vec3(-68.82,-1779.56,28.36)
		}
	},
	FuelStation18 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(2545.28,2592.04,37.95,116.23),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(2538.72,2594.39,37.95),
		Delivery = vec3(2534.25,2636.0,37.95),
		Packages = {
			Small = vec3(1178.81,-314.7,69.17),
			Medium = vec3(271.05,-1241.47,29.17),
			Large = vec3(-2100.79,-298.48,13.04)
		}
	},
	FuelStation19 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(2001.35,3779.87,32.18,212.6),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(2004.26,3776.01,32.18),
		Delivery = vec3(1978.9,3765.28,32.18),
		Packages = {
			Small = vec3(2587.9,407.03,108.45),
			Medium = vec3(-2571.45,2336.93,33.06),
			Large = vec3(-707.23,-934.06,19.01)
		}
	},
	FuelStation20 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1710.37,4929.91,42.07,238.12),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1687.14,4929.62,42.07),
		Delivery = vec3(1682.27,4922.51,42.07),
		Packages = {
			Small = vec3(61.57,2775.74,57.88),
			Medium = vec3(637.61,261.37,103.1),
			Large = vec3(-508.61,-1202.3,19.44)
		}
	},
	FuelStation21 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(1706.15,6425.78,32.77,158.75),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(1702.55,6418.26,32.64),
		Delivery = vec3(1688.87,6427.02,32.45),
		Packages = {
			Small = vec3(1212.99,2668.32,37.79),
			Medium = vec3(2587.9,407.48,108.45),
			Large = vec3(-708.32,-936.85,19.01)
		}
	},
	FuelStation22 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-92.71,6409.89,31.64,45.36),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-93.92,6419.44,31.49),
		Delivery = vec3(-76.74,6428.64,31.44),
		Packages = {
			Small = vec3(1979.48,3769.36,32.18),
			Medium = vec3(61.34,2776.24,57.88),
			Large = vec3(826.9,-1046.32,27.38)
		}
	},
	FuelStation23 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-1819.64,797.16,138.13,314.65),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-1800.11,803.65,138.64),
		Delivery = vec3(-1818.93,807.42,138.67),
		Packages = {
			Small = vec3(-69.53,-1779.86,28.34),
			Medium = vec3(1198.19,-1409.06,35.23),
			Large = vec3(200.73,6612.27,31.69)
		}
	},
	FuelStation24 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-1427.92,-268.25,46.22,130.4),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-1436.84,-276.54,46.2),
		Delivery = vec3(-1419.85,-285.52,46.25),
		Packages = {
			Small = vec3(1197.95,-1409.41,35.22),
			Medium = vec3(2589.26,408.97,108.45),
			Large = vec3(1683.91,4920.45,42.07)
		}
	},
	FuelStation25 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-702.87,-916.76,19.21,181.42),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-724.62,-935.16,19.21),
		Delivery = vec3(-707.96,-935.63,19.01),
		Packages = {
			Small = vec3(2589.1,409.31,108.45),
			Medium = vec3(243.3,2602.81,45.12),
			Large = vec3(1683.31,4921.82,42.07)
		}
	},
	FuelStation26 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-531.41,-1221.28,18.45,334.49),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-526.39,-1210.62,18.18),
		Delivery = vec3(-511.01,-1196.22,19.85),
		Packages = {
			Small = vec3(1198.41,-1412.18,35.22),
			Medium = vec3(-1802.61,782.1,137.39),
			Large = vec3(-2527.5,2337.71,33.06)
		}
	},
	FuelStation27 = {
		Price = 100000,
		Model = "cs_jimmyboston",
		Coords = vec4(-48.06,-1761.11,29.44,144.57),
		Anim = { "anim@heists@heist_corona@single_team","single_team_loop_boss" },
		BlipCoords = vec3(-70.06,-1761.96,29.52),
		Delivery = vec3(-66.26,-1746.69,29.39),
		Packages = {
			Small = vec3(1169.69,-338.62,68.75),
			Medium = vec3(-1419.11,-284.83,46.25),
			Large = vec3(2585.2,406.0,108.45)
		}
	}
}