--!strict
--[[
	LeaderboardService — ModuleScript in ServerScriptService/Services
	OrderedDataStore has tight limits. We write at most once every 2 minutes per
	player and read the global top list once every 2 minutes per SERVER.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataManager = require(script.Parent.DataManager)

local LeaderboardService = {}

local rebirthBoard = DataStoreService:GetOrderedDataStore("Board_Rebirths_v1")
local gooBoard = DataStoreService:GetOrderedDataStore("Board_LifetimeGoo_v1")

local WRITE_INTERVAL = 120
local READ_INTERVAL = 120
local TOP_N = 50

local cachedTop = { rebirths = {}, goo = {} }
local Remotes
function LeaderboardService.setRemotes(r) Remotes = r end

local function readBoard(store, key)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_N)
	end)
	if not ok then return end
	local entries = {}
	for rank, entry in pages:GetCurrentPage() do
		local name = "Player"
		local nameOk, resolved = pcall(function()
			return Players:GetNameFromUserIdAsync(tonumber(entry.key) or 0)
		end)
		if nameOk then name = resolved end
		table.insert(entries, { rank = rank, name = name, value = entry.value })
	end
	cachedTop[key] = entries
end

function LeaderboardService.getTop()
	return cachedTop
end

function LeaderboardService.init()
	task.spawn(function()
		while true do
			readBoard(rebirthBoard, "rebirths")
			task.wait(1)
			readBoard(gooBoard, "goo")
			Remotes.LeaderboardUpdate:FireAllClients(cachedTop)
			task.wait(READ_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(WRITE_INTERVAL)
			for _, player in Players:GetPlayers() do
				local data = DataManager.get(player)
				if data then
					local uid = tostring(player.UserId)
					pcall(function() rebirthBoard:SetAsync(uid, data.rebirths) end)
					-- OrderedDataStore only stores integers within int64. Store
					-- log-scaled goo so huge idle numbers still sort correctly.
					local scaled = math.floor(math.log10(math.max(1, data.lifetimeGoo)) * 1000)
					pcall(function() gooBoard:SetAsync(uid, scaled) end)
					task.wait(0.5)
				end
			end
		end
	end)
end

return LeaderboardService
