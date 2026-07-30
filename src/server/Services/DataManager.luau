--!strict
--[[
	DataManager — ModuleScript inside ServerScriptService/Services

	Responsibilities:
	  * Load / create profile with a SESSION LOCK (prevents the #1 cause of
	    item duplication: the same player loaded on two servers at once).
	  * Autosave every 60s, save on leave, save on shutdown (BindToClose).
	  * Retry with backoff. Never overwrite good data with a failed load.

	Why not ProfileService? You can use it and it's excellent. This is a
	dependency-free version so you can paste it and go. It implements the same
	core ideas: session locking, reconciliation, and safe shutdown.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataManager = {}

local STORE_NAME = "SlimeFactory_v1" -- bump the version to wipe data during testing
local AUTOSAVE_INTERVAL = 60
local LOCK_TIMEOUT = 60 * 5 -- a lock older than this is considered stale

local store = DataStoreService:GetDataStore(STORE_NAME)

local profiles: { [Player]: any } = {}
local loaded: { [Player]: boolean } = {}

-- The single source of truth for what a save file looks like.
local TEMPLATE = {
	goo = 0,
	lifetimeGoo = 0,
	crystals = 0,
	rebirths = 0,
	upgrades = {},        -- [upgradeId] = level
	pets = {},            -- array of { id = string, uid = string }
	equipped = {},        -- array of uid
	zone = 1,
	lastLogin = 0,
	dailyStreak = 0,
	lastDailyClaim = 0,
	totalPlaytime = 0,
	purchaseHistory = {}, -- [receiptId] = true  (idempotency for dev products)
	redeemedCodes = {},   -- [code] = true

	-- framework additions
	stats = {},             -- [statKey] = number   (drives achievements + cosmetics)
	achievements = {},      -- [achievementId] = unlockTimestamp
	cosmetics = {},         -- [cosmeticId] = true
	equippedCosmetics = {}, -- [category] = cosmeticId
	settings = {},          -- [settingKey] = value
	inventory = {},         -- [kind] = { items }
	seasonProgress = {},    -- [seasonId] = points

	version = 2,
}

-- Fills in any keys added in a later update without touching existing values.
local function reconcile(data: any): any
	for key, default in TEMPLATE do
		if data[key] == nil then
			data[key] = if typeof(default) == "table" then table.clone(default) else default
		end
	end
	return data
end

local function keyFor(player: Player): string
	return "p_" .. player.UserId
end

local function retry<T>(fn: () -> T, attempts: number): (boolean, T?)
	local lastErr
	for i = 1, attempts do
		local ok, result = pcall(fn)
		if ok then return true, result end
		lastErr = result
		task.wait(2 ^ i) -- exponential backoff: 2s, 4s, 8s
	end
	warn("[DataManager] all attempts failed:", lastErr)
	return false, nil
end

function DataManager.load(player: Player)
	local key = keyFor(player)
	local jobId = game.JobId ~= "" and game.JobId or "studio"

	local ok, result = retry(function()
		return store:UpdateAsync(key, function(old)
			old = old or table.clone(TEMPLATE)

			-- SESSION LOCK CHECK
			local lock = old.__lock
			if lock and lock.jobId ~= jobId and (os.time() - lock.at) < LOCK_TIMEOUT then
				return nil -- abort the write; another live server owns this profile
			end

			old.__lock = { jobId = jobId, at = os.time() }
			return old
		end)
	end, 4)

	if not ok or result == nil then
		-- Could not acquire the lock. Kick rather than run on unsaveable data —
		-- this is what stops duplication and rollback complaints.
		player:Kick("Your save is still active on another server. Please rejoin in ~30 seconds.")
		return nil
	end

	local data = reconcile(result)
	data.__lock = nil
	profiles[player] = data
	loaded[player] = true
	return data
end

function DataManager.get(player: Player): any?
	return profiles[player]
end

function DataManager.isLoaded(player: Player): boolean
	return loaded[player] == true
end

function DataManager.save(player: Player, releaseLock: boolean?)
	local data = profiles[player]
	if not data then return end
	local key = keyFor(player)
	local jobId = game.JobId ~= "" and game.JobId or "studio"

	local snapshot = table.clone(data)
	snapshot.lastLogin = os.time()

	retry(function()
		return store:UpdateAsync(key, function(old)
			-- Only write if we still own the lock (or nobody does).
			if old and old.__lock and old.__lock.jobId ~= jobId then
				local age = os.time() - old.__lock.at
				if age < LOCK_TIMEOUT then return nil end
			end
			snapshot.__lock = if releaseLock then nil else { jobId = jobId, at = os.time() }
			return snapshot
		end)
	end, 3)
end

function DataManager.release(player: Player)
	DataManager.save(player, true)
	profiles[player] = nil
	loaded[player] = nil
end

function DataManager:init()
	Players.PlayerRemoving:Connect(function(player)
		DataManager.release(player)
	end)

	-- Autosave loop, staggered so 30 players don't hit the datastore in one frame.
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				if profiles[player] then
					DataManager.save(player, false)
					task.wait(0.3)
				end
			end
		end
	end)

	-- Shutdown / server migration: Roblox gives us up to 30 seconds here.
	game:BindToClose(function()
		if RunService:IsStudio() then return end
		local threads = 0
		for _, player in Players:GetPlayers() do
			threads += 1
			task.spawn(function()
				DataManager.release(player)
				threads -= 1
			end)
		end
		local deadline = os.clock() + 25
		while threads > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataManager
