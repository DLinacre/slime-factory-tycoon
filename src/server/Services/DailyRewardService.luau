--!strict
--[[
	DailyRewardService — ModuleScript in ServerScriptService/Services
	Uses os.time() (UTC, server side). Never trust the client's clock.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local Net = require(Modules.Net)
local Registry = require(Modules.ServiceRegistry)
local DataManager = require(script.Parent.DataManager)

local DailyRewardService = {}
local DAY = 86400

local Economy, Pets

function DailyRewardService:start()
	Economy = Registry.get("EconomyService")
	Pets = Registry.get("PetService")
	Net.onServer("ClaimDaily", function(player) DailyRewardService.claim(player) end)
end

local function dayIndex(t: number): number
	return math.floor(t / DAY)
end

function DailyRewardService.getStatus(player: Player)
	local data = DataManager.get(player)
	if not data then return nil end
	local today = dayIndex(os.time())
	local last = dayIndex(data.lastDailyClaim)
	return {
		canClaim = data.lastDailyClaim == 0 or today > last,
		streak = data.dailyStreak,
		nextIn = math.max(0, ((last + 1) * DAY) - os.time()),
	}
end

function DailyRewardService.claim(player: Player)
	local data = DataManager.get(player)
	if not data then return end

	local now = os.time()
	local today = dayIndex(now)
	local last = dayIndex(data.lastDailyClaim)

	if data.lastDailyClaim ~= 0 and today <= last then return end -- already claimed

	-- Consecutive day continues the streak; a gap resets it.
	if data.lastDailyClaim ~= 0 and today == last + 1 then
		data.dailyStreak += 1
	else
		data.dailyStreak = 1
	end
	if data.dailyStreak > #GameConfig.DailyRewards then data.dailyStreak = 1 end

	data.lastDailyClaim = now

	local reward = GameConfig.DailyRewards[data.dailyStreak]
	data.crystals += reward.crystals
	if reward.boost then Economy.grantBoost(player, reward.boost.mult, reward.boost.seconds) end
	if reward.guaranteedRarity then Pets.grantRandomOfRarity(player, reward.guaranteedRarity) end

	Net.fireClient("DailyClaimed", player, data.dailyStreak, reward)

	local ach = Registry.tryGet("AchievementService")
	if ach then ach:setStat(player, "bestStreak", data.dailyStreak) end
end

return DailyRewardService
