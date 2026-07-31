--!strict
--[[
	CustomBoosterService.luau — Example of adding a new service

	Shows how easy it is to extend the template with new gameplay systems.
	This service adds temporary server-wide multipliers that can be triggered
	by code or a remote (e.g. from a dev product or admin command).

	Drop this file into src/server/Services/ and it will be automatically
	discovered and started.
]]

local Players = game:GetService("Players")

local ServiceRegistry = require(script.Parent.Parent.Parent.shared.ServiceRegistry)
local Net = require(script.Parent.Parent.Parent.shared.Net)

local CustomBoosterService = {}

-- Current active multipliers (player -> {mult, expires})
local activeBoosters: { [Player]: { mult: number, expires: number } } = {}

function CustomBoosterService.init()
	-- Declare a new remote for applying boosters (server only)
	-- In a real game you would also declare this in Net.luau
end

function CustomBoosterService.start()
	-- Listen for a purchase that gives a server boost (example)
	-- This would normally be called from MonetizationService
end

-- Apply a temporary multiplier to a single player
function CustomBoosterService.applyPlayerBoost(player: Player, mult: number, durationSeconds: number)
	activeBoosters[player] = {
		mult = mult,
		expires = os.clock() + durationSeconds,
	}

	-- Clean up later
	task.delay(durationSeconds, function()
		if activeBoosters[player] then
			activeBoosters[player] = nil
		end
	end)

	-- In a real implementation, notify the player + update their stats
	print(`[Booster] Applied {mult}x to {player.Name} for {durationSeconds}s`)
end

-- Apply a SERVER-WIDE boost (highest ROI item — see STRATEGY.md)
function CustomBoosterService.applyServerBoost(mult: number, durationSeconds: number)
	for _, player in Players:GetPlayers() do
		CustomBoosterService.applyPlayerBoost(player, mult, durationSeconds)
	end

	-- Broadcast to everyone (you would use Net.fireAll here)
	print(`[ServerBoost] {mult}x active for {durationSeconds}s`)
end

-- Hook into EconomyService (example of service-to-service communication)
-- In a real project you would resolve EconomyService and multiply income
function CustomBoosterService.getMultiplierForPlayer(player: Player): number
	local booster = activeBoosters[player]
	if booster and os.clock() < booster.expires then
		return booster.mult
	end
	return 1.0
end

-- Optional: clean up on player leave
function CustomBoosterService.onPlayerRemoving(player: Player)
	activeBoosters[player] = nil
end

return CustomBoosterService
