-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
Config = {
	BankTaxWithdraw = 1.0,
	BankTaxTransfer = 1.0,
	MedicPlanDuration = 604800,

	GoalsItems = { "dollar","wetdollar","dirtydollar" },

	Paramedics = { -- Caso tenha outras permissões, adicione abaixo.
		Paramedico = true
	},

	Disabled = {
		Mansao01 = { "Tags","Bank","Goals","Perks" }
	},

	Perks = {
		{
			Increase = 1,
			Type = "Members",
			Title = "Aumento de Limite",
			Image = "nui://painel/web-side/images/user.svg",
			Description = "Aumenta o limite máximo de membros do grupo.",
			Price = { 150000,175000,200000,225000,250000,275000,300000,325000,350000,375000,400000,425000,450000,475000,500000,525000,550000,575000,600000,625000,650000,675000,700000,725000,750000,775000,800000,825000,850000,875000,900000,925000,950000,975000,1000000,1025000,1050000,1075000,1100000,1125000,1150000,1175000,1200000,1225000,1250000,1275000,1300000,1325000,1350000,1375000 }
		},{
			Price = 30000000,
			Type = "Premium",
			Increase = 2592000,
			Title = "Benefícios de Grupo",
			Description = "Adquirir por <b>30 dias</b> as bonificações abaixo.<br>• Dobro de peso no compartimento dos membros.",
			Image = "nui://painel/web-side/images/user.svg"
		},{
			Level = 10,
			Increase = 1,
			Type = "Tags",
			Price = 500000,
			Title = "Aumento de Tags",
			Description = "Aumenta o limite máximo de tags do grupo.",
			Image = "nui://painel/web-side/images/user.svg"
		},{
			Level = 10,
			Increase = 1,
			Price = 500000,
			Type = "Announces",
			Title = "Aumento de Anúncios",
			Description = "Aumenta o limite máximo de anúncios do grupo.",
			Image = "nui://painel/web-side/images/user.svg"
		}
	}
}