-----------------------------------------------------------------------------------------------------------------------------------------
-- INFORMATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
Informations = {
	Amethyst = {
		Price = 2000000,
		Gemstone = 100000
	},
	Amber = {
		Price = 2000000,
		Gemstone = 100000
	},
	Sapphire = {
		Price = 2000000,
		Gemstone = 100000
	},
	Emerald = {
		Price = 2000000,
		Gemstone = 100000
	},
	Topaz = {
		Price = 2000000,
		Gemstone = 100000
	},
	Opal = {
		Price = 2000000,
		Gemstone = 100000
	},
	Jade = {
		Price = 2000000,
		Gemstone = 100000
	},
	Pearl = {
		Price = 2000000,
		Gemstone = 100000
	},
	Aquamarine = {
		Price = 2000000,
		Gemstone = 100000
	},
	Turquoise = {
		Price = 2000000,
		Gemstone = 100000
	},
	Onyx = {
		Price = 2000000,
		Gemstone = 100000
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPORTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Informations",function()
	local Interiors = {}
	for Name in pairs(Informations) do
		Interiors[#Interiors + 1] = Name
	end

	return Interiors[math.random(1,#Interiors)]
end)