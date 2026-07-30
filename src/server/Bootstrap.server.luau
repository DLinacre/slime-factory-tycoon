--!strict
--[[
	Bootstrap — a *Script* (server) directly in ServerScriptService.
	All the ModuleScripts live in a folder named "Services" inside this Script's
	parent... actually simplest layout: put Bootstrap in ServerScriptService and
	a Folder "Services" next to it containing the modules. Adjust the requires
	if you nest them differently.

	This is the ONLY server Script. Everything else is a module it starts, in a
	deliberate order.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent.Services

local DataManager   = require(Services.DataManager)
local EconomyService = require(Services.EconomyService)
local MonetizationService = require(Services.MonetizationService)
local PetService    = require(Services.PetService)
local DailyRewardService = require(Services.DailyRewardService)
local LeaderboardService = require(Services.LeaderboardService)
local CodeService   = require(Services.CodeService)

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

-- ============================================================ REMOTES
-- Created in code so you can't forget one, and so names stay consistent.
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local Remotes = {}

local function makeEvent(name: string)
	local ev = remotesFolder:FindFirstChild(name) or Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotesFolder
	Remotes[name] = ev
	return ev
end

-- client -> server
local ClickRemote    = makeEvent("Click")
local BuyUpgrade     = makeEvent("BuyUpgrade")
local RebirthRemote  = makeEvent("Rebirth")
local HatchRemote    = makeEvent("Hatch")
local EquipRemote    = makeEvent("EquipPet")
local ClaimDaily     = makeEvent("ClaimDaily")
local PromptPurchase = makeEvent("PromptPurchase")
local RedeemCode     = makeEvent("RedeemCode")

-- server -> client
makeEvent("StateSync")
makeEvent("UpgradeBought")
makeEvent("Rebirthed")
makeEvent("HatchResult")
makeEvent("EquipUpdate")
makeEvent("DailyClaimed")
makeEvent("OfflineEarnings")
makeEvent("ZoneUnlocked")
makeEvent("PurchaseSuccess")
makeEvent("LeaderboardUpdate")
makeEvent("Announce")
makeEvent("Notify")
makeEvent("InitialData")
makeEvent("CodeResult")

-- ============================================================ WIRING
EconomyService.setRemotes(Remotes)
MonetizationService.setRemotes(Remotes)
PetService.setRemotes(Remotes)
PetService.setMonetization(MonetizationService)
DailyRewardService.inject(Remotes, EconomyService, PetService)
LeaderboardService.setRemotes(Remotes)
CodeService.inject(Remotes, EconomyService, PetService)

DataManager.init()
MonetizationService.init()
EconomyService.init()
LeaderboardService.init()

-- ============================================================ RATE LIMITING
-- One generic guard for every inbound remote. Exploiters spam remotes to lag
-- the server; this drops the flood before it ever reaches game logic.
local lastCall: { [Player]: { [string]: number } } = {}

local function guard(name: string, minInterval: number, handler: (Player, ...any) -> ())
	return function(player: Player, ...)
		if not DataManager.isLoaded(player) then return end
		local t = lastCall[player]
		if not t then t = {} lastCall[player] = t end
		local now = os.clock()
		if (now - (t[name] or 0)) < minInterval then return end
		t[name] = now
		local ok, err = pcall(handler, player, ...)
		if not ok then warn(("[%s] %s"):format(name, tostring(err))) end
	end
end

ClickRemote.OnServerEvent:Connect(guard("Click", 0.1, function(player, count)
	EconomyService.handleClicks(player, count)
end))

BuyUpgrade.OnServerEvent:Connect(guard("BuyUpgrade", 0.05, function(player, id, amount)
	EconomyService.buyUpgrade(player, id, amount)
end))

RebirthRemote.OnServerEvent:Connect(guard("Rebirth", 1, function(player)
	EconomyService.rebirth(player)
end))

HatchRemote.OnServerEvent:Connect(guard("Hatch", 0.3, function(player, count)
	PetService.hatch(player, count)
end))

EquipRemote.OnServerEvent:Connect(guard("EquipPet", 0.1, function(player, uid)
	PetService.equip(player, uid)
end))

ClaimDaily.OnServerEvent:Connect(guard("ClaimDaily", 1, function(player)
	DailyRewardService.claim(player)
end))

-- 1s cooldown: stops brute-forcing the code table.
RedeemCode.OnServerEvent:Connect(guard("RedeemCode", 1, function(player, code)
	CodeService.redeem(player, code)
end))

-- The client may ASK for a prompt; the server decides what's promptable.
local MarketplaceService = game:GetService("MarketplaceService")
PromptPurchase.OnServerEvent:Connect(guard("PromptPurchase", 0.5, function(player, kind, key)
	if typeof(kind) ~= "string" or typeof(key) ~= "string" then return end
	if kind == "pass" then
		local p = GameConfig.Gamepasses[key]
		if p and p.id ~= 0 then MarketplaceService:PromptGamePassPurchase(player, p.id) end
	elseif kind == "product" then
		local p = GameConfig.Products[key]
		if p and p.id ~= 0 then MarketplaceService:PromptProductPurchase(player, p.id) end
	end
end))

-- ============================================================ LIFECYCLE
local function onPlayerAdded(player: Player)
	EconomyService.setupPlayer(player)
	MonetizationService.setupPlayer(player)

	local data = DataManager.load(player)
	if not data then return end -- kicked by the session lock

	-- Classic leaderstats so names show in the player list (free social proof).
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rb = Instance.new("IntValue")
	rb.Name = "Rebirths"
	rb.Value = data.rebirths
	rb.Parent = stats
	stats.Parent = player

	EconomyService.applyOfflineEarnings(player)

	Remotes.InitialData:FireClient(player, {
		goo = data.goo,
		crystals = data.crystals,
		rebirths = data.rebirths,
		zone = data.zone,
		upgrades = data.upgrades,
		pets = data.pets,
		equipped = data.equipped,
		daily = DailyRewardService.getStatus(player),
		redeemedCodes = CodeService.getRedeemed(player),
		passes = {
			DoubleGoo = MonetizationService.hasPass(player, "DoubleGoo"),
			AutoClicker = MonetizationService.hasPass(player, "AutoClicker"),
			VIP = MonetizationService.hasPass(player, "VIP"),
			PetSlots = MonetizationService.hasPass(player, "PetSlots"),
			LuckyEgg = MonetizationService.hasPass(player, "LuckyEgg"),
			FastRebirth = MonetizationService.hasPass(player, "FastRebirth"),
		},
		isPremium = player.MembershipType == Enum.MembershipType.Premium,
	})

	-- keep leaderstats in sync cheaply
	task.spawn(function()
		while player.Parent do
			task.wait(5)
			local d = DataManager.get(player)
			if d then rb.Value = d.rebirths end
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in Players:GetPlayers() do task.spawn(onPlayerAdded, p) end

Players.PlayerRemoving:Connect(function(player)
	EconomyService.cleanupPlayer(player)
	MonetizationService.cleanupPlayer(player)
	PetService.cleanupPlayer(player)
	lastCall[player] = nil
end)

print("[SlimeFactory] server ready")
