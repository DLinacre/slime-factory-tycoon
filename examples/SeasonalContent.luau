--!strict
--[[
	SeasonalContent.luau — Example seasonal extension

	This file shows how to add seasonal content without touching core code.

	Usage:
	1. Copy the tables below into Content.luau or GameConfig.luau
	2. Or require this module from your own SeasonalService

	Seasonal events are the single biggest driver of returning players.
]]

local SeasonalContent = {}

-- Example: Halloween 2026 season
SeasonalContent.Halloween2026 = {
	name = "Spooky Slime Season",
	startDate = "2026-10-15",
	endDate = "2026-11-01",

	achievements = {
		{
			id = "spooky_taps",
			name = "Trick or Tap",
			desc = "Tap 500 times during the event",
			stat = "eventTaps",
			goal = 500,
			crystals = 300,
		},
		{
			id = "pumpkin_hatch",
			name = "Pumpkin Master",
			desc = "Hatch a Legendary during the event",
			stat = "eventLegendaries",
			goal = 1,
			crystals = 1200,
		},
	},

	cosmetics = {
		{
			id = "pumpkin_vat",
			name = "Pumpkin Vat",
			type = "vatSkin",
			unlock = { type = "event", cost = 800 },
		},
		{
			id = "ghost_trail",
			name = "Ghost Trail",
			type = "trail",
			unlock = { type = "crystals", cost = 450 },
		},
	},

	-- Special event pets (add to GameConfig.Pets or a separate pool)
	pets = {
		{ id = "ghost_slime", name = "Ghost Slime", rarity = "Epic", mult = 1.6, icon = "rbxassetid://0" },
		{ id = "pumpkin_slime", name = "Pumpkin Slime", rarity = "Legendary", mult = 4.2, icon = "rbxassetid://0" },
	},
}

-- You can have multiple seasons and switch them in a SeasonalService
return SeasonalContent
