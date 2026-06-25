-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
PointSeconds = 15 -- Número em segundos que vai contar a pontuação.
Permission = "Admin" -- Permissão para utilizar o comando.
DominationGoal = 1000 -- Pontuação máxima para ganhar a dominação.
DeleteVehicle = false -- Coloque true caso queira que se entrar com veículo o mesmo seja deletado.
Command = "domination" -- Nome do comando para executar/finalizar manualmente uma dominação.
MaxPresenceMultiplier = 3.0 -- Máximo da multiplicação com base na quantidade de jogadores.
PresenceMultiplier = 0.25 -- Valor da multiplicação para cada jogador na area.
PointsKillFeed = 5 -- Quantos pontos o grupo vai receber ao matar outro jogador.
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
Locations = {
	Lester = {
		Name = "Lester",
		PolyWeight = 50.0,
		PolyDisplay = true,
		Permission = "Lester",
		SurvivalDistance = 500,
		Blip = vec3(1285.15,-1730.59,52.89),
		Execute = {
			Hour = 22,
			Minute = 00,
			Week = "Tuesday"
		},
		Poly = {
			vec3(1169.24,-1727.61,35.33),
			vec3(1173.05,-1723.67,35.33),
			vec3(1177.86,-1720.45,35.27),
			vec3(1218.88,-1699.0,38.01),
			vec3(1249.73,-1682.09,43.2),
			vec3(1276.01,-1666.25,47.82),
			vec3(1322.8,-1633.16,52.2),
			vec3(1326.66,-1631.28,52.13),
			vec3(1331.02,-1631.35,52.12),
			vec3(1337.17,-1633.68,52.18),
			vec3(1343.81,-1639.05,52.32),
			vec3(1365.99,-1669.84,56.48),
			vec3(1378.79,-1691.34,61.55),
			vec3(1385.17,-1707.28,64.11),
			vec3(1386.18,-1718.45,65.17),
			vec3(1394.83,-1751.97,65.66),
			vec3(1394.93,-1754.7,65.88),
			vec3(1393.82,-1756.64,66.05),
			vec3(1390.61,-1758.1,66.1),
			vec3(1335.38,-1774.73,57.69),
			vec3(1280.51,-1794.34,44.3),
			vec3(1246.04,-1806.81,40.84),
			vec3(1234.74,-1805.55,40.14),
			vec3(1211.39,-1813.68,38.13),
			vec3(1205.03,-1814.36,37.9),
			vec3(1196.92,-1812.55,37.32),
			vec3(1187.54,-1807.99,36.78),
			vec3(1180.26,-1802.88,36.78),
			vec3(1173.57,-1794.88,36.88),
			vec3(1168.84,-1784.5,36.67),
			vec3(1161.96,-1765.05,36.21),
			vec3(1160.47,-1751.41,35.91),
			vec3(1162.79,-1739.1,35.55),
			vec3(1167.84,-1729.87,35.54),
			vec3(1167.84,-1729.87,35.54)
		}
	}
}