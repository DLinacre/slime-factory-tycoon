--!strict
--[[
	CosmeticService

	Owns cosmetic unlocking and equipping. Cosmetics are purely visual by
	design — this service deliberately has no access to the economy multiplier,
	which makes pay-to-win impossible by construction rather than by discipline.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Content = require(Modules.Content)
local Net = require(Modules.Net)
local Registry = require(Modules.ServiceRegistry)

local CosmeticService = {}

function CosmeticService:start()
	self.Data = Registry.get("DataManager")

	Net.onServer("EquipCosmetic", function(player, category, id)
		self:equip(player, category, id)
	end)
end

function CosmeticService:onPlayerAdded(player: Player)
	-- Free cosmetics are granted on join so nobody ever sees an empty wardrobe.
	local data = self.Data.get(player)
	if not data then
		return
	end
	data.cosmetics = data.cosmetics or {}
	for _, c in Content.Cosmetics do
		if c.source == "free" then
			data.cosmetics[c.id] = true
		end
	end
	self:checkUnlocks(player)
end

--- Grants any progression cosmetic whose stat threshold is met.
function CosmeticService:checkUnlocks(player: Player)
	local data = self.Data.get(player)
	if not data then
		return
	end
	data.cosmetics = data.cosmetics or {}
	local stats = data.stats or {}
	local newly = {}

	for _, c in Content.Cosmetics do
		if c.source == "progression" and c.unlockStat and c.unlockGoal then
			if not data.cosmetics[c.id] and (stats[c.unlockStat] or 0) >= c.unlockGoal then
				data.cosmetics[c.id] = true
				table.insert(newly, { id = c.id, name = c.name, rarity = c.rarity, category = c.category })
			end
		end
	end

	if #newly > 0 then
		Net.fireClient("CosmeticUpdate", player, { unlocked = newly, owned = data.cosmetics, equipped = data.equippedCosmetics })
	end
end

function CosmeticService:grant(player: Player, id: string): boolean
	local data = self.Data.get(player)
	local def = Content.getCosmetic(id)
	if not data or not def then
		return false
	end
	data.cosmetics = data.cosmetics or {}
	if data.cosmetics[id] then
		return false
	end
	data.cosmetics[id] = true
	Net.fireClient("CosmeticUpdate", player, {
		unlocked = { { id = def.id, name = def.name, rarity = def.rarity, category = def.category } },
		owned = data.cosmetics,
		equipped = data.equippedCosmetics,
	})
	return true
end

--- Buys a crystal-priced cosmetic. Robux cosmetics go through MonetizationService.
function CosmeticService:purchase(player: Player, id: string): boolean
	local data = self.Data.get(player)
	local def = Content.getCosmetic(id)
	if not data or not def or def.source ~= "crystals" or not def.cost then
		return false
	end
	if data.cosmetics and data.cosmetics[id] then
		return false
	end
	if data.crystals < def.cost then
		Net.fireClient("Notify", player, "Not enough crystals!")
		return false
	end
	data.crystals -= def.cost
	return self:grant(player, id)
end

function CosmeticService:equip(player: Player, category: string, id: string)
	local data = self.Data.get(player)
	if not data then
		return
	end
	local def = Content.getCosmetic(id)
	-- Must exist, match the claimed category, and be owned. All three checked
	-- server-side; the client's claim is only a hint.
	if not def or def.category ~= category then
		return
	end
	if not (data.cosmetics and data.cosmetics[id]) then
		return
	end

	data.equippedCosmetics = data.equippedCosmetics or {}
	data.equippedCosmetics[category] = id
	Net.fireClient("CosmeticUpdate", player, { owned = data.cosmetics, equipped = data.equippedCosmetics })
end

function CosmeticService:getState(player: Player)
	local data = self.Data.get(player)
	if not data then
		return { owned = {}, equipped = {} }
	end
	return { owned = data.cosmetics or {}, equipped = data.equippedCosmetics or {} }
end

return CosmeticService
