--!strict
--[[
	InventoryService

	A generic, reusable item container. Pets currently live here, but so can
	boosts, event tokens, materials, or anything added later — the framework
	doesn't care what an item *is*.

	Design notes:
	  * Every item instance gets a server-generated UID. Clients reference items
	    by UID and the server always verifies ownership before acting.
	  * Stack limits are enforced so a bug can't produce an unbounded save file
	    (a 4MB DataStore ceiling is reachable if you let arrays grow forever).
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Registry = require(Modules.ServiceRegistry)

local InventoryService = {}

-- Hard ceiling per container. Beyond this we auto-prune the lowest-value items
-- rather than refusing, so the player never hits an invisible wall mid-hatch.
local MAX_ITEMS = 500

function InventoryService:start()
	self.Data = Registry.get("DataManager")
end

local function container(data: any, kind: string)
	data.inventory = data.inventory or {}
	data.inventory[kind] = data.inventory[kind] or {}
	return data.inventory[kind]
end

--- Adds an item. `payload` is arbitrary per-item data (e.g. { id = "gold_slime" }).
function InventoryService:add(player: Player, kind: string, payload: any): any?
	local data = self.Data.get(player)
	if not data then
		return nil
	end
	local items = container(data, kind)

	local entry = table.clone(payload)
	entry.uid = HttpService:GenerateGUID(false)
	entry.at = os.time()
	table.insert(items, entry)

	if #items > MAX_ITEMS then
		self:prune(player, kind)
	end
	return entry
end

function InventoryService:remove(player: Player, kind: string, uid: string): boolean
	local data = self.Data.get(player)
	if not data then
		return false
	end
	local items = container(data, kind)
	for i, item in items do
		if item.uid == uid then
			table.remove(items, i)
			return true
		end
	end
	return false
end

function InventoryService:owns(player: Player, kind: string, uid: string): boolean
	local data = self.Data.get(player)
	if not data then
		return false
	end
	for _, item in container(data, kind) do
		if item.uid == uid then
			return true
		end
	end
	return false
end

function InventoryService:get(player: Player, kind: string): { any }
	local data = self.Data.get(player)
	if not data then
		return {}
	end
	return container(data, kind)
end

function InventoryService:count(player: Player, kind: string): number
	return #self:get(player, kind)
end

--- Drops the least valuable items when over the cap. Equipped items are never
--- pruned — losing something you're actively using would be indefensible.
function InventoryService:prune(player: Player, kind: string)
	local data = self.Data.get(player)
	if not data then
		return
	end
	local items = container(data, kind)
	if #items <= MAX_ITEMS then
		return
	end

	local equipped = {}
	for _, uid in (data.equipped or {}) do
		equipped[uid] = true
	end

	local scorer = self.valueOf and self.valueOf or function()
		return 0
	end

	table.sort(items, function(a, b)
		local ae, be = equipped[a.uid] and 1 or 0, equipped[b.uid] and 1 or 0
		if ae ~= be then
			return ae > be
		end
		return scorer(a) > scorer(b)
	end)

	for i = #items, MAX_ITEMS + 1, -1 do
		items[i] = nil
	end
end

return InventoryService
