--!strict
--[[
	EconomyService — ModuleScript in ServerScriptService/Services

	THE GOLDEN RULE: the client never tells the server how much money it has.
	The client only says "I tapped N times". The server decides what that's worth.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local DataManager = require(script.Parent.DataManager)

local EconomyService = {}

-- Per-player runtime state that does NOT need saving.
local runtime: { [Player]: any } = {}

-- Server-wide boost from the ServerBoost dev product.
local serverBoost = { mult = 1, expires = 0 }

local Remotes -- injected by Bootstrap

function EconomyService.setRemotes(r) Remotes = r end

function EconomyService.setupPlayer(player: Player)
	runtime[player] = {
		clickBudget = GameConfig.MaxClicksPerSecond,
		lastRefill = os.clock(),
		boostMult = 1,
		boostExpires = 0,
		lastSync = 0,
		suspicion = 0,
	}
end

function EconomyService.cleanupPlayer(player: Player)
	runtime[player] = nil
end

-- ---------------------------------------------------------- multipliers
-- Everything that scales income funnels through here so there is exactly ONE
-- place to reason about balance.
function EconomyService.getMultiplier(player: Player): number
	local data = DataManager.get(player)
	local rt = runtime[player]
	if not data or not rt then return 1 end

	local mult = 1

	-- rebirth
	mult *= 1 + (data.rebirths * GameConfig.Rebirth.multPerRebirth)

	-- zone
	local zone = GameConfig.Zones[data.zone] or GameConfig.Zones[1]
	mult *= zone.incomeMult

	-- pets (only equipped ones count)
	local petMult = 1
	local byUid = {}
	for _, owned in data.pets do byUid[owned.uid] = owned.id end
	for _, uid in data.equipped do
		local def = GameConfig.getPet(byUid[uid] or "")
		if def then petMult += def.mult end
	end
	mult *= petMult

	-- gamepass
	if EconomyService.hasPass and EconomyService.hasPass(player, "DoubleGoo") then
		mult *= GameConfig.Gamepasses.DoubleGoo.mult
	end

	-- Roblox Premium (drives Premium Payout revenue)
	if player.MembershipType == Enum.MembershipType.Premium then
		mult *= GameConfig.PremiumMultiplier
	end

	-- timed personal boost
	if os.clock() < rt.boostExpires then mult *= rt.boostMult end

	-- server-wide boost
	if os.clock() < serverBoost.expires then mult *= serverBoost.mult end

	return mult
end

function EconomyService.getClickPower(player: Player): number
	local data = DataManager.get(player)
	if not data then return 0 end
	local base = GameConfig.BaseClickPower
	for _, u in GameConfig.Upgrades do
		base += (data.upgrades[u.id] or 0) * u.addClick
	end
	return base * EconomyService.getMultiplier(player)
end

function EconomyService.getAutoIncome(player: Player): number
	local data = DataManager.get(player)
	if not data then return 0 end
	local auto = 0
	for _, u in GameConfig.Upgrades do
		auto += (data.upgrades[u.id] or 0) * u.addAuto
	end
	if EconomyService.hasPass and EconomyService.hasPass(player, "AutoClicker") then
		auto += GameConfig.Gamepasses.AutoClicker.cps * GameConfig.BaseClickPower
	end
	return auto * EconomyService.getMultiplier(player)
end

function EconomyService.addGoo(player: Player, amount: number)
	local data = DataManager.get(player)
	if not data or amount <= 0 then return end
	data.goo += amount
	data.lifetimeGoo += amount
	EconomyService.checkZone(player)
end

function EconomyService.checkZone(player: Player)
	local data = DataManager.get(player)
	if not data then return end
	for i = #GameConfig.Zones, 1, -1 do
		if data.lifetimeGoo >= GameConfig.Zones[i].requiredLifetime then
			if data.zone < i then
				data.zone = i
				Remotes.ZoneUnlocked:FireClient(player, i)
			end
			break
		end
	end
end

-- ---------------------------------------------------------- clicks
-- Token-bucket rate limit. Refills at MaxClicksPerSecond, caps at 2x that so a
-- brief lag spike doesn't cost a legitimate player their taps.
function EconomyService.handleClicks(player: Player, count: any)
	local rt = runtime[player]
	if not rt then return end

	-- Strict type/sanity validation. Exploiters send strings, NaN, inf, tables.
	if typeof(count) ~= "number" then return end
	if count ~= count or count == math.huge or count < 1 then return end
	count = math.floor(math.min(count, 100))

	local now = os.clock()
	local cap = GameConfig.MaxClicksPerSecond * 2
	rt.clickBudget = math.min(cap, rt.clickBudget + (now - rt.lastRefill) * GameConfig.MaxClicksPerSecond)
	rt.lastRefill = now

	local granted = math.min(count, math.floor(rt.clickBudget))
	if granted < count then
		rt.suspicion += (count - granted)
		if rt.suspicion > 500 then
			-- Don't kick on the first offence: lag and legit macros exist.
			-- Log it, and only act on sustained abuse.
			warn(("[AntiCheat] %s sustained click overflow (%d)"):format(player.Name, rt.suspicion))
			rt.suspicion = 0
		end
	end
	if granted <= 0 then return end

	rt.clickBudget -= granted
	EconomyService.addGoo(player, granted * EconomyService.getClickPower(player))
end

-- ---------------------------------------------------------- upgrades
function EconomyService.buyUpgrade(player: Player, upgradeId: any, requestedAmount: any)
	local data = DataManager.get(player)
	if not data then return end
	if typeof(upgradeId) ~= "string" then return end

	local def = GameConfig.getUpgrade(upgradeId)
	if not def then return end -- unknown id => forged remote

	local amount = if typeof(requestedAmount) == "number" then math.clamp(math.floor(requestedAmount), 1, 100) else 1
	local level = data.upgrades[upgradeId] or 0
	local bought, spent = 0, 0

	for _ = 1, amount do
		if level >= def.maxLevel then break end
		local cost = GameConfig.upgradeCost(upgradeId, level)
		if data.goo < cost then break end
		data.goo -= cost
		level += 1
		bought += 1
		spent += cost
	end

	if bought > 0 then
		data.upgrades[upgradeId] = level
		Remotes.UpgradeBought:FireClient(player, upgradeId, level, spent)
	end
end

-- ---------------------------------------------------------- rebirth
function EconomyService.rebirth(player: Player)
	local data = DataManager.get(player)
	if not data then return end
	local cost = GameConfig.rebirthCost(data.rebirths)
	if data.goo < cost then return end

	local gained = GameConfig.rebirthCrystals(data.rebirths)
	data.goo = 0
	data.upgrades = {}
	data.rebirths += 1
	data.crystals += gained
	-- NOTE: lifetimeGoo, pets and zone are deliberately preserved.
	Remotes.Rebirthed:FireClient(player, data.rebirths, gained)
end

-- ---------------------------------------------------------- boosts
function EconomyService.grantBoost(player: Player, mult: number, seconds: number)
	local rt = runtime[player]
	if not rt then return end
	-- Stack by extending time if the same multiplier, else take the better one.
	if rt.boostMult == mult and os.clock() < rt.boostExpires then
		rt.boostExpires += seconds
	else
		rt.boostMult = math.max(rt.boostMult, mult)
		rt.boostExpires = os.clock() + seconds
	end
end

function EconomyService.grantServerBoost(buyer: Player, mult: number, seconds: number)
	serverBoost.mult = math.max(serverBoost.mult, mult)
	serverBoost.expires = math.max(serverBoost.expires, os.clock()) + seconds
	-- The social broadcast IS the product. Everyone sees who paid.
	Remotes.Announce:FireAllClients(("%s activated a server-wide %dx boost!"):format(buyer.DisplayName, mult))
end

-- ---------------------------------------------------------- offline earnings
-- The single highest-impact retention feature in the game.
function EconomyService.applyOfflineEarnings(player: Player)
	local data = DataManager.get(player)
	if not data or data.lastLogin == 0 then return 0 end

	local elapsed = math.max(0, os.time() - data.lastLogin)
	local capped = math.min(elapsed, GameConfig.MaxOfflineHours * 3600)
	if capped < 60 then return 0 end

	local earned = EconomyService.getAutoIncome(player) * capped * GameConfig.OfflineEfficiency
	if earned <= 0 then return 0 end

	EconomyService.addGoo(player, earned)
	Remotes.OfflineEarnings:FireClient(player, earned, capped)
	return earned
end

-- ---------------------------------------------------------- loops
function EconomyService.init()
	-- ONE loop for every player. Never one loop per player — that is how idle
	-- games melt their servers at 30 concurrent.
	task.spawn(function()
		while true do
			local dt = task.wait(GameConfig.AutoTickRate)
			for _, player in Players:GetPlayers() do
				if DataManager.isLoaded(player) then
					local income = EconomyService.getAutoIncome(player) * dt
					if income > 0 then EconomyService.addGoo(player, income) end
				end
			end
		end
	end)

	-- Throttled state sync: 4 Hz is plenty and cuts network traffic ~15x versus
	-- firing on every change. Mobile players notice bandwidth.
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in Players:GetPlayers() do
				local data = DataManager.get(player)
				if data then
					Remotes.StateSync:FireClient(player, {
						goo = data.goo,
						crystals = data.crystals,
						rebirths = data.rebirths,
						zone = data.zone,
						clickPower = EconomyService.getClickPower(player),
						autoIncome = EconomyService.getAutoIncome(player),
						mult = EconomyService.getMultiplier(player),
					})
				end
			end
		end
	end)
end

return EconomyService
