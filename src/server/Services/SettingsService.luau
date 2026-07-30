--!strict
--[[
	SettingsService

	Settings persist server-side so they follow the player across devices —
	someone who enables Reduced Motion on their phone shouldn't have to do it
	again on a PC. Validation is schema-driven from Content.Settings.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Content = require(Modules.Content)
local Net = require(Modules.Net)
local Registry = require(Modules.ServiceRegistry)

local SettingsService = {}

local schema: { [string]: Content.Setting } = {}

function SettingsService:init()
	for _, s in Content.Settings do
		schema[s.key] = s
	end
end

function SettingsService:start()
	self.Data = Registry.get("DataManager")

	Net.onServer("SetSetting", function(player, key, value)
		self:set(player, key, value)
	end)
end

--- Coerces a value into the schema's allowed range, or returns nil to reject.
local function coerce(def: Content.Setting, value: any): any?
	if def.kind == "toggle" then
		if typeof(value) ~= "boolean" then
			return nil
		end
		return value
	elseif def.kind == "slider" then
		if typeof(value) ~= "number" or value ~= value then
			return nil
		end
		return math.clamp(math.floor(value), def.min or 0, def.max or 100)
	elseif def.kind == "choice" then
		if typeof(value) ~= "string" or not def.choices then
			return nil
		end
		for _, c in def.choices do
			if c == value then
				return value
			end
		end
		return nil
	end
	return nil
end

function SettingsService:set(player: Player, key: string, value: any)
	local def = schema[key]
	if not def then
		return
	end
	local data = self.Data.get(player)
	if not data then
		return
	end

	local clean = coerce(def, value)
	if clean == nil then
		return
	end

	data.settings = data.settings or Content.defaultSettings()
	data.settings[key] = clean
	Net.fireClient("SettingsUpdate", player, data.settings)
end

function SettingsService:get(player: Player): { [string]: any }
	local data = self.Data.get(player)
	if not data then
		return Content.defaultSettings()
	end
	-- Merge over defaults so settings added in a future update appear
	-- immediately on existing saves without a migration.
	local out = Content.defaultSettings()
	for k, v in (data.settings or {}) do
		if schema[k] then
			out[k] = v
		end
	end
	data.settings = out
	return out
end

return SettingsService
