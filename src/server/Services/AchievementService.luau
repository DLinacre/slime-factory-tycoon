--!strict
--[[
	AchievementService

	Stat-driven achievements. Services bump stats via :bump(player, stat, n) and
	this service works out what that unlocked. No achievement logic ever leaks
	into gameplay code.

	Rewards are granted automatically on unlock — no "claim" button. Making
	players click to receive something they already earned is friction that
	serves nobody.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Content = require(Modules.Content)
local Net = require(Modules.Net)
local Registry = require(Modules.ServiceRegistry)

local AchievementService = {}

-- stat -> list of achievements watching it, so a bump is O(watchers) not O(all)
local watchers: { [string]: { Content.Achievement } } = {}

function AchievementService:init()
	for _, a in Content.Achievements do
		local list = watchers[a.stat]
		if not list then
			list = {}
			watchers[a.stat] = list
		end
		table.insert(list, a)
	end
end

function AchievementService:start()
	self.Data = Registry.get("DataManager")
end

--- Increases a tracked stat and unlocks anything it completes.
function AchievementService:bump(player: Player, stat: string, amount: number?)
	local data = self.Data.get(player)
	if not data then
		return
	end

	data.stats = data.stats or {}
	local current = (data.stats[stat] or 0) + (amount or 1)
	data.stats[stat] = current

	local list = watchers[stat]
	if not list then
		return
	end

	data.achievements = data.achievements or {}
	for _, a in list do
		if current >= a.goal and not data.achievements[a.id] then
			data.achievements[a.id] = os.time()
			data.crystals += a.crystals
			Net.fireClient("AchievementUnlocked", player, {
				id = a.id,
				name = a.name,
				desc = a.desc,
				crystals = a.crystals,
			})
			-- Cosmetics can be gated on the same stats; re-check on every unlock.
			local cos = Registry.tryGet("CosmeticService")
			if cos then
				cos:checkUnlocks(player)
			end
		end
	end
end

--- Sets a stat to an absolute value (for things like rebirth count that are
--- already authoritative elsewhere). Only ever moves upward.
function AchievementService:setStat(player: Player, stat: string, value: number)
	local data = self.Data.get(player)
	if not data then
		return
	end
	data.stats = data.stats or {}
	if value > (data.stats[stat] or 0) then
		local delta = value - (data.stats[stat] or 0)
		self:bump(player, stat, delta)
	end
end

function AchievementService:getProgress(player: Player)
	local data = self.Data.get(player)
	if not data then
		return {}
	end
	local stats = data.stats or {}
	local unlocked = data.achievements or {}
	local out = {}
	for _, a in Content.Achievements do
		-- Hidden achievements stay hidden until earned, then display normally.
		if not a.hidden or unlocked[a.id] then
			table.insert(out, {
				id = a.id,
				name = a.name,
				desc = a.desc,
				goal = a.goal,
				crystals = a.crystals,
				progress = math.min(stats[a.stat] or 0, a.goal),
				unlocked = unlocked[a.id] ~= nil,
			})
		end
	end
	return out
end

return AchievementService
