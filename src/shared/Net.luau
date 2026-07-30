--!strict
--[[
	Net — ReplicatedStorage/Modules/Net

	A declarative networking layer. Every remote in the game is DECLARED here
	with a validator, so:

	  * You can never typo a remote name (it's a table lookup, not a string).
	  * Validation is impossible to forget — it lives with the declaration,
	    not in the handler where someone will eventually skip it.
	  * Rate limits are part of the contract, not scattered through Bootstrap.
	  * Remotes are created automatically on the server and awaited on the client.

	This replaces the hand-rolled `makeEvent` + `guard` pattern. Adding a new
	remote is now one row in REMOTES.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(script.Parent.Validate)

local Net = {}

export type Direction = "ClientToServer" | "ServerToClient"

export type RemoteDef = {
	direction: Direction,
	-- Validators for each argument sent client -> server. Server -> client
	-- traffic is trusted (we sent it) so it needs no validator.
	args: { (value: any) -> boolean }?,
	-- Minimum seconds between accepted calls, per player.
	cooldown: number?,
}

-- ============================================================ DECLARATIONS
local REMOTES: { [string]: RemoteDef } = {
	-- ---- client -> server (all validated + rate limited)
	Click = { direction = "ClientToServer", args = { t.integer(1, 100) }, cooldown = 0.1 },
	BuyUpgrade = { direction = "ClientToServer", args = { t.stringMax(32), t.integer(1, 100) }, cooldown = 0.05 },
	Rebirth = { direction = "ClientToServer", cooldown = 1 },
	Hatch = { direction = "ClientToServer", args = { t.integer(1, 10) }, cooldown = 0.3 },
	EquipPet = { direction = "ClientToServer", args = { t.stringMax(64) }, cooldown = 0.1 },
	ClaimDaily = { direction = "ClientToServer", cooldown = 1 },
	RedeemCode = { direction = "ClientToServer", args = { t.stringMax(32) }, cooldown = 1 },
	PromptPurchase = { direction = "ClientToServer", args = { t.stringMax(16), t.stringMax(32) }, cooldown = 0.5 },
	EquipCosmetic = { direction = "ClientToServer", args = { t.stringMax(16), t.stringMax(48) }, cooldown = 0.2 },
	SetSetting = { direction = "ClientToServer", args = { t.stringMax(32), t.settingValue }, cooldown = 0.1 },
	ClaimAchievement = { direction = "ClientToServer", args = { t.stringMax(48) }, cooldown = 0.2 },

	-- ---- server -> client
	InitialData = { direction = "ServerToClient" },
	StateSync = { direction = "ServerToClient" },
	UpgradeBought = { direction = "ServerToClient" },
	Rebirthed = { direction = "ServerToClient" },
	HatchResult = { direction = "ServerToClient" },
	EquipUpdate = { direction = "ServerToClient" },
	DailyClaimed = { direction = "ServerToClient" },
	OfflineEarnings = { direction = "ServerToClient" },
	ZoneUnlocked = { direction = "ServerToClient" },
	PurchaseSuccess = { direction = "ServerToClient" },
	LeaderboardUpdate = { direction = "ServerToClient" },
	Announce = { direction = "ServerToClient" },
	Notify = { direction = "ServerToClient" },
	CodeResult = { direction = "ServerToClient" },
	AchievementUnlocked = { direction = "ServerToClient" },
	CosmeticUpdate = { direction = "ServerToClient" },
	SettingsUpdate = { direction = "ServerToClient" },
}

Net.REMOTES = REMOTES

-- ============================================================ IMPLEMENTATION
local folder: Folder
local cache: { [string]: RemoteEvent } = {}

local function ensureFolder(): Folder
	if folder then
		return folder
	end
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild("Remotes")
		if not existing then
			existing = Instance.new("Folder")
			existing.Name = "Remotes"
			existing.Parent = ReplicatedStorage
		end
		folder = existing :: Folder
	else
		folder = ReplicatedStorage:WaitForChild("Remotes", 30) :: Folder
	end
	return folder
end

--- Creates every declared remote. Server only, called once at boot.
function Net.build()
	assert(RunService:IsServer(), "Net.build is server-only")
	local f = ensureFolder()
	for name in REMOTES do
		if not f:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = f
		end
	end
end

--- Fetches a declared remote. Errors on an undeclared name, which turns a
--- silent runtime nil-index into an immediate, obvious boot failure.
function Net.get(name: string): RemoteEvent
	if cache[name] then
		return cache[name]
	end
	assert(REMOTES[name], ("Net: undeclared remote '%s'"):format(name))
	local f = ensureFolder()
	local ev = if RunService:IsServer() then f:FindFirstChild(name) else f:WaitForChild(name, 30)
	assert(ev, ("Net: remote '%s' missing"):format(name))
	cache[name] = ev :: RemoteEvent
	return cache[name]
end

-- Per-player, per-remote timestamps for cooldown enforcement.
local lastCall: { [Player]: { [string]: number } } = {}

function Net.forget(player: Player)
	lastCall[player] = nil
end

--[[
	Binds a server handler with automatic validation + rate limiting.

	The handler only ever runs with arguments that passed their validators, so
	handler code can be written as if the input were trustworthy — which is the
	entire point. Validation you have to remember is validation you'll forget.
]]
function Net.onServer(name: string, handler: (Player, ...any) -> ())
	assert(RunService:IsServer(), "Net.onServer is server-only")
	local def = REMOTES[name]
	assert(def and def.direction == "ClientToServer", ("Net: '%s' is not a client->server remote"):format(name))

	Net.get(name).OnServerEvent:Connect(function(player: Player, ...)
		-- rate limit
		if def.cooldown then
			local bucket = lastCall[player]
			if not bucket then
				bucket = {}
				lastCall[player] = bucket
			end
			local now = os.clock()
			if now - (bucket[name] or 0) < def.cooldown then
				return
			end
			bucket[name] = now
		end

		-- validate
		if def.args then
			local packed = table.pack(...)
			for i, validator in def.args do
				if not validator(packed[i]) then
					return -- silently drop; never tell an exploiter why
				end
			end
		end

		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(("[Net:%s] handler error: %s"):format(name, tostring(err)))
		end
	end)
end

function Net.onClient(name: string, handler: (...any) -> ())
	assert(RunService:IsClient(), "Net.onClient is client-only")
	Net.get(name).OnClientEvent:Connect(function(...)
		local ok, err = pcall(handler, ...)
		if not ok then
			warn(("[Net:%s] handler error: %s"):format(name, tostring(err)))
		end
	end)
end

function Net.fireClient(name: string, player: Player, ...)
	Net.get(name):FireClient(player, ...)
end

function Net.fireAll(name: string, ...)
	Net.get(name):FireAllClients(...)
end

function Net.fireServer(name: string, ...)
	Net.get(name):FireServer(...)
end

return Net
