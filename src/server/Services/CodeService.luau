--!strict
--[[
	CodeService — ModuleScript in ServerScriptService/Services

	Promo codes. Highest-ROI feature that wasn't in the original build:
	  * gives you thumbnail material ("CODE: LAUNCH")
	  * drives YouTube/TikTok coverage (code videos are an entire content genre)
	  * measurably lifts D1 installs on update day

	Server-authoritative: the client sends a string, the server decides. Codes
	are stored here, redemptions are stored per-player so nobody can farm one twice.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local DataManager = require(script.Parent.DataManager)

local CodeService = {}

local Remotes, Economy, Pets
function CodeService.inject(r, e, p)
	Remotes, Economy, Pets = r, e, p
end

-- Add a row per update. `expires` is a unix timestamp, or nil for permanent.
-- Keep codes SHORT and UPPERCASE — players type them on phone keyboards.
local CODES: { [string]: any } = {
	LAUNCH = { crystals = 5000, expires = nil },
	SLIME = { crystals = 1000, expires = nil },
	THANKS10K = { crystals = 2500, boost = { mult = 2, seconds = 1800 }, expires = nil },
	FRIDAY = { crystals = 750, expires = nil },
	LEGENDARY = { rarity = "Legendary", expires = nil },
}

function CodeService.redeem(player: Player, rawCode: any)
	local data = DataManager.get(player)
	if not data then
		return
	end

	if typeof(rawCode) ~= "string" then
		return
	end
	-- Bound the length BEFORE doing anything else: an exploiter sending a 10MB
	-- string should cost us nothing.
	if #rawCode > 32 then
		return
	end

	local code = rawCode:upper():gsub("%s", "")
	local def = CODES[code]

	if not def then
		Remotes.CodeResult:FireClient(player, false, "Invalid code!")
		return
	end

	if def.expires and os.time() > def.expires then
		Remotes.CodeResult:FireClient(player, false, "That code has expired!")
		return
	end

	data.redeemedCodes = data.redeemedCodes or {}
	if data.redeemedCodes[code] then
		Remotes.CodeResult:FireClient(player, false, "Already redeemed!")
		return
	end

	data.redeemedCodes[code] = true

	local parts = {}
	if def.crystals then
		data.crystals += def.crystals
		table.insert(parts, ("+%d crystals"):format(def.crystals))
	end
	if def.boost then
		Economy.grantBoost(player, def.boost.mult, def.boost.seconds)
		table.insert(parts, ("%dx boost"):format(def.boost.mult))
	end
	if def.rarity then
		Pets.grantRandomOfRarity(player, def.rarity)
		table.insert(parts, ("a %s pet"):format(def.rarity))
	end

	Remotes.CodeResult:FireClient(player, true, "Redeemed: " .. table.concat(parts, ", "))
end

-- Lets the client grey out codes it already used without leaking the full list.
function CodeService.getRedeemed(player: Player)
	local data = DataManager.get(player)
	return data and data.redeemedCodes or {}
end

return CodeService
