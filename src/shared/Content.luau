--!strict
--[[
	Content — ReplicatedStorage/Modules/Content

	The expandable content framework: achievements, cosmetics, settings schema,
	and seasonal events. All declarative data, no logic.

	Adding content is adding a row. Nothing else in the codebase changes.
]]

local Content = {}

-- ============================================================ ACHIEVEMENTS
-- `stat` is a key tracked in the player's save; `goal` is the threshold.
-- Tiered achievements (I/II/III) give long-tail goals for dedicated players
-- without any extra code.
export type Achievement = {
	id: string,
	name: string,
	desc: string,
	stat: string,
	goal: number,
	crystals: number,
	hidden: boolean?,
}

local Achievements: { Achievement } = {
	-- onboarding: these fire in the first minute and teach the loop
	{ id = "first_tap", name = "First Contact", desc = "Tap the vat once", stat = "totalClicks", goal = 1, crystals = 25 },
	{ id = "first_upgrade", name = "Getting Started", desc = "Buy your first upgrade", stat = "upgradesBought", goal = 1, crystals = 50 },
	{ id = "first_zone", name = "Expanding", desc = "Unlock a second zone", stat = "zonesUnlocked", goal = 2, crystals = 100 },

	-- tap ladder
	{ id = "tap_1k", name = "Tapper I", desc = "Tap 1,000 times", stat = "totalClicks", goal = 1000, crystals = 150 },
	{ id = "tap_25k", name = "Tapper II", desc = "Tap 25,000 times", stat = "totalClicks", goal = 25000, crystals = 500 },
	{ id = "tap_250k", name = "Tapper III", desc = "Tap 250,000 times", stat = "totalClicks", goal = 250000, crystals = 2500 },

	-- rebirth ladder
	{ id = "rb_1", name = "Reborn", desc = "Rebirth once", stat = "rebirths", goal = 1, crystals = 200 },
	{ id = "rb_10", name = "Cycle Master", desc = "Rebirth 10 times", stat = "rebirths", goal = 10, crystals = 1000 },
	{ id = "rb_50", name = "Eternal", desc = "Rebirth 50 times", stat = "rebirths", goal = 50, crystals = 6000 },

	-- collection
	{ id = "pet_1", name = "Companion", desc = "Hatch your first slime", stat = "petsHatched", goal = 1, crystals = 100 },
	{ id = "pet_100", name = "Collector", desc = "Hatch 100 slimes", stat = "petsHatched", goal = 100, crystals = 800 },
	{ id = "legend_1", name = "Against The Odds", desc = "Hatch a Legendary", stat = "legendariesHatched", goal = 1, crystals = 1500 },

	-- dedication
	{ id = "streak_7", name = "Regular", desc = "Reach a 7-day login streak", stat = "bestStreak", goal = 7, crystals = 1200 },
	{ id = "streak_30", name = "Devoted", desc = "Reach a 30-day login streak", stat = "bestStreak", goal = 30, crystals = 8000 },
	{ id = "playtime_10h", name = "Settled In", desc = "Play for 10 hours", stat = "totalPlaytime", goal = 36000, crystals = 1000 },

	-- secret: discovery is its own reward, and secrets drive wiki/forum chatter
	{ id = "patient", name = "Patient", desc = "Return after 8 hours away", stat = "maxOfflineClaimed", goal = 28800, crystals = 500, hidden = true },
}
Content.Achievements = Achievements

-- ============================================================ COSMETICS
-- Cosmetics are PURELY visual. No cosmetic grants income, luck, or speed.
-- That's the ethical line: you can buy how you look, never how you win.
export type Cosmetic = {
	id: string,
	name: string,
	category: "VatSkin" | "Trail" | "Title" | "GooColour",
	rarity: string,
	source: "free" | "progression" | "crystals" | "robux" | "event",
	cost: number?, -- crystals, or Robux when source == "robux"
	unlockStat: string?, -- for progression unlocks
	unlockGoal: number?,
	data: any,
}

local Cosmetics: { Cosmetic } = {
	-- free defaults so every player has a full set to choose from immediately
	{ id = "vat_default", name = "Standard Vat", category = "VatSkin", rarity = "Common", source = "free", data = { primary = Color3.fromRGB(120, 255, 120) } },
	{ id = "goo_green", name = "Classic Green", category = "GooColour", rarity = "Common", source = "free", data = { colour = Color3.fromRGB(120, 255, 120) } },
	{ id = "title_novice", name = "Novice", category = "Title", rarity = "Common", source = "free", data = { text = "Novice" } },

	-- earned through play — the most-worn cosmetics in any good game are the
	-- ones that prove you did something, not the ones you bought
	{ id = "vat_rusted", name = "Rusted Vat", category = "VatSkin", rarity = "Uncommon", source = "progression", unlockStat = "rebirths", unlockGoal = 5, data = { primary = Color3.fromRGB(180, 110, 60) } },
	{ id = "vat_chrome", name = "Chrome Vat", category = "VatSkin", rarity = "Rare", source = "progression", unlockStat = "rebirths", unlockGoal = 15, data = { primary = Color3.fromRGB(220, 225, 235) } },
	{ id = "title_reborn", name = "Reborn", category = "Title", rarity = "Rare", source = "progression", unlockStat = "rebirths", unlockGoal = 10, data = { text = "Reborn" } },
	{ id = "title_collector", name = "Collector", category = "Title", rarity = "Epic", source = "progression", unlockStat = "petsHatched", unlockGoal = 100, data = { text = "Collector" } },
	{ id = "trail_bubbles", name = "Bubble Trail", category = "Trail", rarity = "Uncommon", source = "progression", unlockStat = "totalClicks", unlockGoal = 10000, data = { particle = "bubbles" } },

	-- crystal shop: buyable with the currency you earn by playing
	{ id = "goo_violet", name = "Violet Goo", category = "GooColour", rarity = "Rare", source = "crystals", cost = 3000, data = { colour = Color3.fromRGB(170, 110, 255) } },
	{ id = "goo_cyan", name = "Cryo Goo", category = "GooColour", rarity = "Rare", source = "crystals", cost = 3000, data = { colour = Color3.fromRGB(90, 220, 255) } },
	{ id = "goo_magma", name = "Magma Goo", category = "GooColour", rarity = "Epic", source = "crystals", cost = 8000, data = { colour = Color3.fromRGB(255, 110, 60) } },
	{ id = "trail_sparks", name = "Spark Trail", category = "Trail", rarity = "Epic", source = "crystals", cost = 12000, data = { particle = "sparks" } },

	-- premium cosmetics: Robux, cosmetic-only, clearly worth it visually
	{ id = "vat_golden", name = "Golden Vat", category = "VatSkin", rarity = "Legendary", source = "robux", cost = 199, data = { primary = Color3.fromRGB(255, 205, 80), shimmer = true } },
	{ id = "vat_void", name = "Void Vat", category = "VatSkin", rarity = "Mythic", source = "robux", cost = 349, data = { primary = Color3.fromRGB(40, 20, 70), aura = true } },
	{ id = "trail_rainbow", name = "Rainbow Trail", category = "Trail", rarity = "Legendary", source = "robux", cost = 249, data = { particle = "rainbow" } },
}
Content.Cosmetics = Cosmetics

-- ============================================================ SETTINGS
-- Accessibility is not optional. Reduced motion, high contrast, and text scale
-- cost almost nothing to implement and make the game usable for far more people.
export type Setting = {
	key: string,
	label: string,
	category: "Audio" | "Graphics" | "Accessibility" | "Gameplay",
	kind: "toggle" | "slider" | "choice",
	default: any,
	min: number?,
	max: number?,
	choices: { string }?,
	desc: string?,
}

local Settings: { Setting } = {
	{ key = "musicVolume", label = "Music", category = "Audio", kind = "slider", default = 50, min = 0, max = 100 },
	{ key = "sfxVolume", label = "Sound Effects", category = "Audio", kind = "slider", default = 70, min = 0, max = 100 },

	{ key = "particles", label = "Particle Effects", category = "Graphics", kind = "choice", default = "Auto", choices = { "Off", "Low", "Auto", "High" }, desc = "Auto reduces effects on slower devices" },
	{ key = "screenShake", label = "Screen Shake", category = "Graphics", kind = "toggle", default = true },
	{ key = "damageNumbers", label = "Floating Numbers", category = "Graphics", kind = "toggle", default = true },

	{ key = "reducedMotion", label = "Reduced Motion", category = "Accessibility", kind = "toggle", default = false, desc = "Minimises animation for motion sensitivity" },
	{ key = "highContrast", label = "High Contrast", category = "Accessibility", kind = "toggle", default = false },
	{ key = "textScale", label = "Text Size", category = "Accessibility", kind = "slider", default = 100, min = 80, max = 150 },
	{ key = "colourBlindMode", label = "Colour Blind Mode", category = "Accessibility", kind = "choice", default = "Off", choices = { "Off", "Deuteranopia", "Protanopia", "Tritanopia" } },

	{ key = "confirmPurchases", label = "Confirm Crystal Spends", category = "Gameplay", kind = "toggle", default = true, desc = "Ask before spending crystals" },
	{ key = "autoEquipBest", label = "Auto-Equip Best Pets", category = "Gameplay", kind = "toggle", default = false },
	{ key = "showOffers", label = "Show Special Offers", category = "Gameplay", kind = "toggle", default = true, desc = "Turn off to hide all shop popups" },
}
Content.Settings = Settings

function Content.defaultSettings(): { [string]: any }
	local out = {}
	for _, s in Settings do
		out[s.key] = s.default
	end
	return out
end

-- ============================================================ SEASONS
-- A season is a themed reskin plus a track of goals. Everything reuses existing
-- systems, so a full event is a data edit rather than a build.
export type Season = {
	id: string,
	name: string,
	startsAt: number,
	endsAt: number,
	accent: Color3,
	currencyName: string,
	track: { { goal: number, reward: string, crystals: number? } },
}

local Seasons: { Season } = {
	-- Placeholder-free: no season is live yet, so the list is empty and the UI
	-- honestly shows "No active event". Populate before launch day.
}
Content.Seasons = Seasons

function Content.activeSeason(): Season?
	local now = os.time()
	for _, s in Seasons do
		if now >= s.startsAt and now < s.endsAt then
			return s
		end
	end
	return nil
end

function Content.getAchievement(id: string): Achievement?
	for _, a in Achievements do
		if a.id == id then
			return a
		end
	end
	return nil
end

function Content.getCosmetic(id: string): Cosmetic?
	for _, c in Cosmetics do
		if c.id == id then
			return c
		end
	end
	return nil
end

return Content
