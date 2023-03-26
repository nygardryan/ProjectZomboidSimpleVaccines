

local forageDefs = {}

local DirtySyringe = {
	type = "FAVACCINE.DirtySyringe",
	minCount = 1,
	maxCount = 1,
	skill = 1,
	xp = 5,
	snowChance = -10,
	categories = { "Trash" },
	zones = {
		TownZone      = 10,
		TrailerPark    = 15,
		Nav        = 15,
	},
	months = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
	spawnFuncs = {},
	itemSizeModifier = 1.0,
	isItemOverrideSize = true,
}