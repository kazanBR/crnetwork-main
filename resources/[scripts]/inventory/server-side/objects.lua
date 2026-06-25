-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Delay = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEFAULT
-----------------------------------------------------------------------------------------------------------------------------------------
local Default = {
	-- LOOT MEDICS
	{ Coords = { 594.59,146.52,97.30,70.04 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 660.44,268.29,102.04,152.09 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 552.54,-198.45,53.75,89.32 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 339.75,-580.95,73.42,67.19 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 696.12,-965.69,23.26,271.33 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -2235.42,363.52,173.91,23.73 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1382.1,-2081.97,51.25,220.16 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 589.32,-2802.73,5.32,328.01 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -453.19,-2810.47,6.56,225.82 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1007.18,-2836.12,13.20,149.3 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -2018.21,-361.03,47.36,324.55 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1727.77,250.26,61.65,24.7 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1089.6,2717.05,18.33,40.52 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 321.27,2874.98,42.71,27.62 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1163.47,2722.09,37.26,179.11 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1745.86,3326.69,40.30,115.55 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2013.4,3934.36,31.65,236.38 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2526.3,4191.6,44.53,236.44 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2874.05,4861.57,61.35,87.57 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1985.16,6200.39,41.33,330.21 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1552.97,6610.24,2.12,145.64 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -298.32,6392.66,29.87,302.99 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -813.88,5384.45,33.77,356.87 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1606.5,5259.26,1.35,114.45 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -199.22,3638.8,63.70,39.84 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1487.45,2688.99,2.94,317.89 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -3266.12,1139.82,1.91,249.17 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 170.71,-1070.94,28.5,339.6 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 487.23,-1093.93,28.71,0.74 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 584.63,-1419.69,18.52,180.41 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 694.07,-1453.5,19.03,0.45 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 892.49,-2490.3,28.88,175.48 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1463.09,-2613.91,48.17,76.65 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1877.42,-1065.71,80.22,97.79 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2557.67,-598.5,64.23,12.71 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2546.8,395.31,107.92,268.3 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2074.59,1403.29,74.88,300.3 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2405.44,2903.85,39.67,217.41 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 2895.84,3735.4,43.5,289.37 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 1677.25,4882.36,46.62,59.7 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -437.08,6339.84,12.06,216.59 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { 431.15,6472.57,28.08,140.5 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -2303.74,3389.16,30.56,324.26 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -2096.92,3258.17,32.12,239.97 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1773.55,2995.46,32.11,330.02 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -2086.61,2816.89,32.27,354.52 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },
	{ Coords = { -1511.83,1520.27,114.59,255.31 }, Object = "sm_prop_smug_crate_s_medical", Mode = "LootMedics", Weight = 0.15, Line = true },

	-- LOOT WEAPONS
	{ Coords = { 574.01,132.56,98.48,70.99 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 344.79,929.2,202.44,268.09 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -123.8,1896.67,196.34,358.95 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1099.85,2703.51,21.99,221.35 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -2198.91,4243.21,46.92,128.84 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1487.02,4983.14,62.67,174.11 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1346.49,6396.73,32.42,90.94 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 2535.72,4661.39,33.08,316.4 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1155.62,-1334.48,33.72,174.97 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1116.06,-2498.07,32.37,193.39 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 261.06,-3135.82,4.8,88.83 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1619.81,-1035.0,12.16,50.84 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -3420.87,977.0,10.91,226.29 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1909.53,4624.93,56.07,135.57 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 894.51,3211.45,38.09,273.04 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1791.71,4602.84,36.69,185.86 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 464.8,6462.03,28.76,334.71 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 63.22,6323.67,37.87,301.22 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -736.64,5594.98,40.66,268.78 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 720.76,2330.87,50.76,179.99 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1909.47,611.47,177.41,65.57 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1796.6,-1350.06,98.75,61.5 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 955.32,-3101.26,4.91,266.38 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1306.41,-3387.9,12.95,59.92 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1219.66,-2079.82,13.16,351.04 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1203.53,-1804.25,2.91,245.4 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -720.47,-399.49,33.9,351.27 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -503.39,-1438.17,13.16,346.71 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { 1398.24,2117.57,104.02,131.36 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1811.62,3104.09,31.85,60.36 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1812.86,3101.95,31.85,62.1 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -1850.29,3156.66,31.82,150.22 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -2052.86,3173.31,31.82,240.03 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -2409.94,3355.95,31.83,61.29 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },
	{ Coords = { -2450.39,2946.63,31.97,330.0 }, Object = "prop_mb_crate_01a", Mode = "LootWeapons", Weight = 0.35, Line = true },

	-- LOOT SUPPLIES
	{ Coords = { -257.5,-966.54,30.22,26.06 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -2682.86,2304.87,20.85,164.19 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -1282.33,2559.98,17.4,148.06 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 159.65,3118.8,42.44,16.37 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1061.43,3527.62,33.15,255.93 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2370.22,3156.55,47.21,221.77 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2520.51,2637.83,36.95,314.33 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2572.37,477.44,107.68,269.49 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1223.15,-1079.56,37.53,123.38 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1048.49,-247.53,68.66,149.33 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 499.41,-529.38,23.76,262.13 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 592.53,-2115.87,4.76,100.96 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 523.43,-2578.67,13.82,318.38 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -2.98,-1299.67,28.28,359.37 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 183.11,-1086.93,28.28,348.57 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 713.88,-850.95,23.3,271.63 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -2438.82,2999.82,32.07,194.35 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -2440.04,2999.46,32.07,194.41 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -2092.59,3113.14,31.82,240.25 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -1824.95,3016.0,31.82,329.62 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -202.03,3651.99,50.74,192.39 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -203.41,3651.71,50.74,192.96 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2007.81,4964.86,40.71,158.28 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1904.26,4930.73,47.97,156.61 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1702.14,4819.3,40.96,97.05 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2030.66,4727.43,40.61,294.35 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2122.12,4784.69,39.98,116.71 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2177.23,2169.39,116.31,229.64 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2395.2,2032.72,90.35,318.06 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 2619.31,1691.36,26.6,270.01 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1454.52,-1680.69,65.03,25.31 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 1453.05,-1681.37,64.96,24.93 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { 240.42,-1864.8,25.82,49.31 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -139.01,-1995.56,21.81,181.56 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -343.54,-1333.09,36.31,89.4 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -350.99,-1333.15,36.31,269.98 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -346.45,-1337.38,36.31,359.9 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },
	{ Coords = { -267.45,-971.56,30.22,25.86 }, Object = "gr_prop_gr_rsply_crate03a", Mode = "LootSupplies", Weight = 0.35, Line = true },

	-- LOOTS LEGENDARY
	{ Coords = { -860.77,6575.79,-32.07,243.63 }, Object = "sf_prop_sf_crate_ammu_01a", Mode = "LootLegendary", Weight = 0.5, Line = true },

	-- LOOTS CODE
	{ Coords = { 930.83,34.14,80.1,239.12 }, Object = "m23_2_prop_m32_safe_01a", Mode = "LootCode", Weight = 1.0, Line = true },

	-- ROBBERY AMMUNATION
	{ Coords = { 256.35,-47.51,69.7,249.76 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 846.13,-1036.62,27.95,178.74 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -335.18,6083.29,31.21,45.57 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -665.98,-932.24,21.58,358.38 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -1301.93,-391.36,36.45,255.85 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -1122.59,2698.25,18.31,42.82 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 2571.67,291.28,108.49,180.02 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 2571.66,291.29,108.49,181.06 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 19.57,-1103.0,29.55,339.07 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 813.92,-2160.34,29.37,179.33 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 1688.78,3759.13,34.46,47.5 }, Object = "p_v_43_safe_s", Ground = true },

	-- ROBBERY DEPARTMENT
	{ Coords = { 28.18,-1338.55,29.24,359.45 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 2548.61,384.87,108.36,87.98 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 1159.12,-316.72,68.95,100.36 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -710.58,-906.72,18.96,90.17 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -45.73,-1749.8,29.17,50.77 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 378.3,334.01,103.31,346.27 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -3250.66,1004.43,12.57,85.32 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 1735.06,6421.41,34.78,333.6 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 546.53,2662.18,41.89,186.7 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 1958.93,3749.46,32.09,30.17 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 2672.21,3286.9,54.98,61.68 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { 1706.27,4922.6,41.81,324.6 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -1828.06,796.31,137.93,132.2 }, Object = "p_v_43_safe_s", Ground = true },
	{ Coords = { -3048.43,585.41,7.66,106.96 }, Object = "p_v_43_safe_s", Ground = true },

	-- PROPERTYS
	{ Coords = { 0.38,203.2,-100.81,0.76 }, Object = "p_v_43_safe_s", Ground = true }, -- Hotel

	-- SLOTMACHINE
	{ Coords = { 984.25,64.95,122.12,149.36 }, Object = "vw_prop_casino_slot_04a", Ground = true },

	-- LUCKYWHEEL
	{ Coords = { 167.62,-980.22,29.1,311.78 }, Object = "vw_prop_vw_luckywheel_01a", Ground = true },
	{ Coords = { 167.66,-980.19,29.11,312.67 }, Object = "vw_prop_vw_jackpot_on", Ground = true },

	-- ADMIN
	{ Coords = { 268.53,2861.36,42.65,31.46 }, Object = "prop_byard_machine03", Mode = "Recycle", Weight = 1.0 },
	{ Coords = { -179.99,6263.39,30.51,41.2 }, Object = "prop_byard_machine03", Mode = "Recycle", Weight = 1.0 },
	{ Coords = { 966.66,-1912.34,30.15,0.51 }, Object = "prop_byard_machine03", Mode = "Recycle", Weight = 1.0 },

	-- CAMERAS
	{ Coords = { 155.03,-1038.76,32.31,181.06 }, Name = "Praça", Object = "prop_cctv_cam_06a", Mode = "Camera", Weight = -0.25, Ground = true, BlockStore = true }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for _,v in pairs(Default) do
		repeat
			Selected = GenerateString("DDLLDDLL")
		until Selected and not Objects[Selected]

		Objects[Selected] = v
	end

	local Consult = vRP.SingleQuery("entitydata/GetData",{ Name = "SaveObjects" })
	SaveObjects = Consult and json.decode(Consult.Information) or {}

	for Index,v in pairs(SaveObjects) do
		if v.Item and exports.vrp:ItemDurability(v.Item) and vRP.CheckDamaged(v.Item) then
			SaveObjects[Index] = nil
		else
			Objects[Index] = v
		end
	end

	while true do
		local CurrentTimer = os.time()
		for Permission,v in pairs(Delay) do
			local Number = v.Number

			if v.Timer <= CurrentTimer and Objects[Number] then
				TriggerClientEvent("objects:Remover",-1,Number)

				SaveObjects[Number] = nil
				Delay[Permission] = nil
				Objects[Number] = nil
			end
		end

		Wait(60000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("objects",function(source,Message)
	local Passport = vRP.Passport(source)
	if not Passport or not Message[1] or not vRP.HasGroup(Passport,"Admin") then
		return false
	end

	local Hash = Message[1]
	local Success,Coords = vRPC.ObjectControlling(source,Hash)

	if Success and Coords then
		local Selected
		repeat
			Selected = GenerateString("DDLLDDLL")
		until Selected and not Objects[Selected]

		local Data = {
			Coords = Coords,
			Object = Hash,
			Mode = "Store",
			Ground = true,
			Bucket = GetPlayerRoutingBucket(source)
		}

		Objects[Selected] = Data
		TriggerClientEvent("objects:Adicionar",-1,Selected,Data)

		exports.admin:Archive("coordenadas.txt",json.encode(Data))
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:STOREOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("inventory:StoreObjects")
AddEventHandler("inventory:StoreObjects",function(Number,Hash)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Object
	local Probjects
	local Property = exports.propertys:Inside(Passport)
	if Property then
		Probjects = vRP.GetSrvData("Probjects:"..Property,true)
		Object = Probjects[Number]
	else
		Object = Objects[Number]
	end

	Active[Passport] = true
	if not Object or Object.BlockStore then
		Active[Passport] = nil
		return false
	end

	local CurrentTimer = os.time()
	local Permission = Object.Permission
	local IsAdmin = vRP.HasService(Passport,"Admin")
	if Object.Timer and Object.Timer >= CurrentTimer then
		TriggerClientEvent("Notify",source,"Atenção","Aguarde "..CompleteTimers(Object.Timer - CurrentTimer)..".","amarelo",5000)
		Active[Passport] = nil
		return false
	end

	if Hash and not vRP.Request(source,"Propriedades","Ao aceitar todo conteúdo será perdido") then
		Active[Passport] = nil
		return false
	end

	if Property or Object.Mode ~= "Sprays" then
		local Item = Object.Item
		if Item and Item ~= "spikestrips" then
			if not IsAdmin and Object.Passport and Object.Passport ~= Passport then
				Active[Passport] = nil
				return false
			end

			if Property then
				local Consult = vRP.SingleQuery("propertys/Exist",{ Name = Property })
				if not Consult or (Consult.Passport ~= Passport and not vRP.InventoryFull(Passport,"propertys-"..Consult.Serial)) then
					Active[Passport] = nil
					return false
				end
			end

			if not vRP.MaxItens(Passport,Item) and vRP.CheckWeight(Passport,Item) then
				vRP.GiveItem(Passport,Item,1,true)
			else
				TriggerClientEvent("Notify",source,"Mochila Sobrecarregada","Sua recompensa caiu no chão.","amarelo",5000)
				exports.inventory:Drops(Passport,source,Item,1,true)
			end
		end

		if Property then
			if Probjects and Probjects[Number] then
				Probjects[Number] = nil
				vRP.SetSrvData("Probjects:"..Property,Probjects,true)
			end

			TriggerEvent("propertys:Remover",Property,Number)

			if Hash then
				vRP.RemSrvData(Hash)
			end
		else
			TriggerClientEvent("objects:Remover",-1,Number)
			SaveObjects[Number] = nil
			Objects[Number] = nil
		end
	else
		if not Delay[Permission] then
			Delay[Permission] = { Timer = CurrentTimer + 600, Number = Number }

			local Coords = Object.Coords or { 0,0,0 }
			for _,OtherSource in pairs(vRP.NumPermission(Permission)) do
				async(function()
					vRPC.PlaySound(OtherSource,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")
					TriggerClientEvent("NotifyPush",OtherSource,{ code = "Aviso", title = "Violação de Spray", x = Coords[1], y = Coords[2], z = Coords[3], color = 44 })
				end)
			end

			TriggerClientEvent("Notify",source,"Atenção","O grupo responsável foi avisado. Se ninguém proteger em <b>10 minutos</b> o spray será removido.","amarelo",10000)
		elseif vRP.HasService(Passport,Permission) then
			TriggerClientEvent("Notify",source,"Atenção","Remoção cancelada.","amarelo",5000)
			Delay[Permission] = nil
		end
	end

	Active[Passport] = nil
end)