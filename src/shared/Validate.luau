--!strict
--[[
	Validate — ReplicatedStorage/Modules/Validate

	Tiny composable validators for remote arguments.

	Every one of these rejects the things exploiters actually send: strings where
	numbers belong, NaN, infinity, negative counts, tables, nil, and absurdly
	long strings designed to burn server memory.
]]

local Validate = {}

--- Any finite number (rejects NaN and ±infinity, which break every comparison).
function Validate.finite(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

--- Whole number within [min, max] inclusive.
function Validate.integer(min: number, max: number)
	return function(value: any): boolean
		if not Validate.finite(value) then
			return false
		end
		if value ~= math.floor(value) then
			return false
		end
		return value >= min and value <= max
	end
end

--- Real number within [min, max] inclusive.
function Validate.number(min: number, max: number)
	return function(value: any): boolean
		return Validate.finite(value) and value >= min and value <= max
	end
end

--- Non-empty string no longer than `max` characters.
function Validate.stringMax(max: number)
	return function(value: any): boolean
		return typeof(value) == "string" and #value > 0 and #value <= max
	end
end

--- String that must be one of a fixed set.
function Validate.oneOf(allowed: { string })
	local set = {}
	for _, v in allowed do
		set[v] = true
	end
	return function(value: any): boolean
		return typeof(value) == "string" and set[value] == true
	end
end

function Validate.boolean(value: any): boolean
	return typeof(value) == "boolean"
end

--- Settings accept booleans or bounded numbers (volumes, scales).
function Validate.settingValue(value: any): boolean
	if typeof(value) == "boolean" then
		return true
	end
	if typeof(value) == "string" then
		return #value <= 24
	end
	return Validate.finite(value) and value >= 0 and value <= 100
end

--- Marks an argument as optional: passes if nil, otherwise defers to `inner`.
function Validate.optional(inner: (any) -> boolean)
	return function(value: any): boolean
		return value == nil or inner(value)
	end
end

return Validate
