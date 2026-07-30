--!strict
--[[
	Bootstrap — the only server Script.

	Its entire job is now: build remotes, register services, start them, and fan
	player lifecycle events out. Adding a new system means dropping a
	ModuleScript into Services/ — this file never needs to change again.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = require(Modules.Net)
local Registry = require(Modules.ServiceRegistry)
local GameConfig = require(Modules.GameConfig)
local Content = require(Modules.Content)

-- 1. Remotes must exist before any service binds a handler to them.
Net.build()

-- 2. Auto-discover and register every service module.
Registry.registerFolder(script.Parent.Services)

-- 3. init() on all, then start() on all.
Registry.start()

local DataManager = Registry.get("DataManager")
local Economy = Registry.get("EconomyService")
local Monetization = Registry.get("MonetizationService")
local Achievements = Registry.get("AchievementService")
local Cosmetics = Registry.get("CosmeticService")
local Settings = Registry.get("SettingsService")
local Daily = Registry.get("DailyRewardService")
local Codes = Registry.get("CodeService")

-- ============================================================ SHOP PROMPTS
-- The client sends a key, never an asset id. The server resolves it, so a
-- tampered client can only ever prompt for products that genuinely exist.
Net.onServer("PromptPurchase", function(player, kind, key)
	if kind == "pass" then
		local p = GameConfig.Gamepasses[key]
		if p and p.id ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, p.id)
		end
	elseif kind == "product" then
		local p = GameConfig.Products[key]
		if p and p.id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, p.id)
		end
	elseif kind == "cosmetic" then
		-- crystal-priced cosmetics resolve entirely server-side
		Cosmetics:purchase(player, key)
	end
end)

-- ============================================================ LIFECYCLE
local function onPlayerAdded(player: Player)
	-- Data must load before any service touches the profile, so this is not
	-- part of the generic dispatch.
	local data = DataManager.load(player)
	if not data then
		return -- session lock kicked them; nothing more to do
	end

	Registry.dispatch("onPlayerAdded", player)

	-- leaderstats: free social proof in the player list
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rb = Instance.new("IntValue")
	rb.Name = "Rebirths"
	rb.Value = data.rebirths
	rb.Parent = stats
	stats.Parent = player

	Economy.applyOfflineEarnings(player)

	-- Backfill stats for saves created before the achievement system existed,
	-- so returning players immediately receive what they already earned.
	Achievements:setStat(player, "rebirths", data.rebirths)
	Achievements:setStat(player, "zonesUnlocked", data.zone)

	Net.fireClient("InitialData", player, {
		goo = data.goo,
		crystals = data.crystals,
		rebirths = data.rebirths,
		zone = data.zone,
		upgrades = data.upgrades,
		pets = data.pets,
		equipped = data.equipped,
		daily = Daily.getStatus(player),
		redeemedCodes = Codes.getRedeemed(player),
		achievements = Achievements:getProgress(player),
		cosmetics = Cosmetics:getState(player),
		settings = Settings:get(player),
		season = Content.activeSeason(),
		passes = (function()
			local out = {}
			for name in GameConfig.Gamepasses do
				out[name] = Monetization.hasPass(player, name)
			end
			return out
		end)(),
		isPremium = player.MembershipType == Enum.MembershipType.Premium,
	})

	-- Playtime drives achievements and is cheap to track on a slow loop.
	task.spawn(function()
		while player.Parent do
			task.wait(30)
			local d = DataManager.get(player)
			if d then
				rb.Value = d.rebirths
				Achievements:bump(player, "totalPlaytime", 30)
			end
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	Registry.dispatch("onPlayerRemoving", player)
	Net.forget(player)
end)

print("[SlimeFactory] server ready —", #Content.Achievements, "achievements,", #Content.Cosmetics, "cosmetics")
