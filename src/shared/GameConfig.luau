--!strict
--[[
	GameConfig — ModuleScript
	Location: ReplicatedStorage/Modules/GameConfig

	THIS FILE IS YOUR GAME DESIGN. 95% of your balancing happens here and
	nowhere else. Shared by server and client so the UI never hardcodes numbers.
]]

local GameConfig = {}

-- ============================================================ CORE ECONOMY
GameConfig.BaseClickPower = 1
GameConfig.AutoTickRate = 1 -- seconds between passive income ticks
GameConfig.MaxOfflineHours = 8 -- cap so nobody returns to an absurd number
GameConfig.OfflineEfficiency = 0.5 -- offline earns 50% of online rate

-- Anti-cheat: max clicks we will honour per second from one player.
-- A fast human taps ~12/s. 20 gives headroom without letting autoclickers print money.
GameConfig.MaxClicksPerSecond = 20
GameConfig.ClickBatchWindow = 0.2 -- client batches taps and sends every 0.2s

-- ============================================================ UPGRADES
-- cost = baseCost * (growth ^ level).  Growth of ~1.15 is the genre standard:
-- fast early wins, meaningful late-game walls that sell boosts.
GameConfig.Upgrades = {
	{ id = "click",   name = "Stronger Tap",   baseCost = 10,   growth = 1.15, addClick = 1,  addAuto = 0,   maxLevel = 500 },
	{ id = "auto",    name = "Goo Pump",       baseCost = 100,  growth = 1.18, addClick = 0,  addAuto = 1,   maxLevel = 500 },
	{ id = "vat",     name = "Bigger Vat",     baseCost = 1500, growth = 1.22, addClick = 5,  addAuto = 3,   maxLevel = 300 },
	{ id = "reactor", name = "Goo Reactor",    baseCost = 5e4,  growth = 1.25, addClick = 0,  addAuto = 25,  maxLevel = 300 },
	{ id = "quantum", name = "Quantum Sludge", baseCost = 2e6,  growth = 1.28, addClick = 50, addAuto = 120, maxLevel = 250 },
}

-- ============================================================ ZONES
-- Gated by LIFETIME goo earned (not current goo) so rebirthing never locks a
-- player out of content they already unlocked. Zones give a flat income mult.
GameConfig.Zones = {
	{ id = 1, name = "Starter Shed",   requiredLifetime = 0,    incomeMult = 1.0 },
	{ id = 2, name = "Goo Refinery",   requiredLifetime = 5e3,  incomeMult = 1.5 },
	{ id = 3, name = "Toxic Caverns",  requiredLifetime = 2.5e5,incomeMult = 2.5 },
	{ id = 4, name = "Neon Labs",      requiredLifetime = 1e7,  incomeMult = 4.0 },
	{ id = 5, name = "Orbital Plant",  requiredLifetime = 5e8,  incomeMult = 7.0 },
	{ id = 6, name = "Void Foundry",   requiredLifetime = 2e10, incomeMult = 12.0 },
}

-- ============================================================ REBIRTH
-- Cost curve and reward curve. Multiplier is (1 + rebirths * 0.5) so the
-- second rebirth feels great and the tenth still matters.
GameConfig.Rebirth = {
	-- Tuned via tools/balance_sim.py: 1e5 put the first rebirth at ~33 min,
	-- past the point most players churn. 5e4 lands it at ~22 min.
	baseCost = 5e4,
	growth = 4.5,
	multPerRebirth = 0.5,
	crystalsBase = 50,
	crystalsGrowth = 1.6,
}

-- ============================================================ PETS
-- Odds are PUBLISHED in the UI. This is both a Roblox policy expectation for
-- paid randomisation and, practically, a trust signal that increases spend.
GameConfig.EggCost = 250 -- crystals
GameConfig.EggCooldown = 3 -- seconds
GameConfig.BasePetSlots = 3
GameConfig.GamepassPetSlots = 5 -- extra

GameConfig.Rarities = {
	Common    = { weight = 6000, colour = Color3.fromRGB(180, 180, 180) },
	Rare      = { weight = 3000, colour = Color3.fromRGB(70, 150, 255) },
	Epic      = { weight = 900,  colour = Color3.fromRGB(180, 90, 255) },
	Legendary = { weight = 100,  colour = Color3.fromRGB(255, 190, 60) },
}

GameConfig.Pets = {
	{ id = "green_blob",  name = "Green Blob",   rarity = "Common",    mult = 0.10, icon = "rbxassetid://0" },
	{ id = "blue_blob",   name = "Blue Blob",    rarity = "Common",    mult = 0.12, icon = "rbxassetid://0" },
	{ id = "mud_blob",    name = "Mud Blob",     rarity = "Common",    mult = 0.15, icon = "rbxassetid://0" },
	{ id = "spark_slime", name = "Spark Slime",  rarity = "Rare",      mult = 0.35, icon = "rbxassetid://0" },
	{ id = "frost_slime", name = "Frost Slime",  rarity = "Rare",      mult = 0.40, icon = "rbxassetid://0" },
	{ id = "magma_slime", name = "Magma Slime",  rarity = "Rare",      mult = 0.45, icon = "rbxassetid://0" },
	{ id = "prism_slime", name = "Prism Slime",  rarity = "Epic",      mult = 1.00, icon = "rbxassetid://0" },
	{ id = "storm_slime", name = "Storm Slime",  rarity = "Epic",      mult = 1.20, icon = "rbxassetid://0" },
	{ id = "void_slime",  name = "Void Slime",   rarity = "Legendary", mult = 3.50, icon = "rbxassetid://0" },
	{ id = "gold_slime",  name = "Golden Slime", rarity = "Legendary", mult = 5.00, icon = "rbxassetid://0" },
}

-- ============================================================ DAILY REWARDS
GameConfig.DailyRewards = {
	{ day = 1, crystals = 100,  boost = nil },
	{ day = 2, crystals = 200,  boost = nil },
	{ day = 3, crystals = 400,  boost = { mult = 2, seconds = 600 } },
	{ day = 4, crystals = 800,  boost = nil },
	{ day = 5, crystals = 1500, boost = { mult = 2, seconds = 900 } },
	{ day = 6, crystals = 2500, boost = nil },
	{ day = 7, crystals = 5000, boost = { mult = 3, seconds = 1800 }, guaranteedRarity = "Legendary" },
}

-- ============================================================ MONETIZATION
-- REPLACE every 0 with your real asset IDs from the Creator Dashboard.
GameConfig.Gamepasses = {
	DoubleGoo    = { id = 0, mult = 2,    label = "2x Goo",        price = 199 },
	AutoClicker  = { id = 0, cps = 10,    label = "Auto Clicker",  price = 149 },
	VIP          = { id = 0, luck = 2,    label = "VIP",           price = 399 },
	PetSlots     = { id = 0,              label = "+5 Pet Slots",  price = 299 },
	LuckyEgg     = { id = 0, luck = 1.5,  label = "Lucky Egg",     price = 349 },
	FastRebirth  = { id = 0,              label = "Fast Rebirth",  price = 249 },
}

GameConfig.Products = {
	Crystals1k   = { id = 0, crystals = 1000,  price = 99 },
	Crystals6k   = { id = 0, crystals = 6000,  price = 499 },
	Crystals15k  = { id = 0, crystals = 15000, price = 999 },
	Boost3x      = { id = 0, boost = { mult = 3, seconds = 1800 }, price = 79 },
	ServerBoost  = { id = 0, serverBoost = { mult = 2, seconds = 900 }, price = 199 },
	InstantRebirth = { id = 0, price = 149 },
	SkipEggCd    = { id = 0, price = 49 },
}

GameConfig.PremiumMultiplier = 1.25 -- Premium Payout incentive

-- ============================================================ HELPERS
function GameConfig.getUpgrade(id: string)
	for _, u in GameConfig.Upgrades do
		if u.id == id then return u end
	end
	return nil
end

function GameConfig.upgradeCost(id: string, level: number): number
	local u = GameConfig.getUpgrade(id)
	if not u then return math.huge end
	return math.floor(u.baseCost * (u.growth ^ level))
end

function GameConfig.rebirthCost(rebirths: number): number
	local r = GameConfig.Rebirth
	return math.floor(r.baseCost * (r.growth ^ rebirths))
end

function GameConfig.rebirthCrystals(rebirths: number): number
	local r = GameConfig.Rebirth
	return math.floor(r.crystalsBase * (r.crystalsGrowth ^ rebirths))
end

function GameConfig.getPet(id: string)
	for _, p in GameConfig.Pets do
		if p.id == id then return p end
	end
	return nil
end

table.freeze(GameConfig)
return GameConfig
