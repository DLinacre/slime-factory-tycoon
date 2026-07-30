--!strict
-- Format — ModuleScript at ReplicatedStorage/Modules/Format
-- Abbreviates big numbers the way idle-game players expect: 1.2K, 3.4M, 5.6aa

local Format = {}

local SHORT = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local ALPHA = "abcdefghijklmnopqrstuvwxyz"

local function alphaSuffix(tier: number): string
	-- after the named tiers we go aa, ab, ac ... zz (standard incremental notation)
	local n = tier - #SHORT
	local first = math.floor((n - 1) / 26) + 1
	local second = ((n - 1) % 26) + 1
	return ALPHA:sub(first, first) .. ALPHA:sub(second, second)
end

function Format.number(value: number): string
	if value ~= value or value == math.huge then return "∞" end
	local neg = value < 0
	value = math.abs(value)
	if value < 1000 then
		local s = string.format("%.0f", value)
		return (neg and "-" or "") .. s
	end
	local tier = math.floor(math.log(value, 1000))
	local scaled = value / (1000 ^ tier)
	local suffix = SHORT[tier + 1] or alphaSuffix(tier + 1)
	-- 3 significant figures reads best on a phone screen
	local s = if scaled < 10 then string.format("%.2f", scaled)
		elseif scaled < 100 then string.format("%.1f", scaled)
		else string.format("%.0f", scaled)
	return (neg and "-" or "") .. s .. suffix
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then return string.format("%dh %dm", h, m) end
	if m > 0 then return string.format("%dm %ds", m, s) end
	return string.format("%ds", s)
end

table.freeze(Format)
return Format
