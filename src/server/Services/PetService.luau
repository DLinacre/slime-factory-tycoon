--!strict
--[[
	PetService — ModuleScript in ServerScriptService/Services
	Server-authoritative hatching. The client NEVER rolls the dice.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local DataManager = require(script.Parent.DataManager)

local PetService = {}
local cooldowns: { [Player]: number } = {}
local rng = Random.new()

local Remotes, Monetization
function PetService.setRemotes(r) Remotes = r end
function PetService.setMonetization(m) Monetization = m end

function PetService.clearCooldown(player: Player)
	cooldowns[player] = 0
end

function PetService.cleanupPlayer(player: Player)
	cooldowns[player] = nil
end

-- Luck shifts weight from Common toward the rarer tiers. We divide the common
-- weight rather than multiplying rare weights, which keeps the published odds
-- easy to state honestly in the UI.
local function rollPet(luck: number)
	local pool = {}
	local total = 0
	for _, pet in GameConfig.Pets do
		local r = GameConfig.Rarities[pet.rarity]
		local w = r.weight
		if pet.rarity == "Common" then w /= luck end
		total += w
		table.insert(pool, { pet = pet, w = w })
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, entry in pool do
		acc += entry.w
		if roll <= acc then return entry.pet end
	end
	return pool[1].pet
end

function PetService.hatch(player: Player, count: any)
	local data = DataManager.get(player)
	if not data then return end

	local now = os.clock()
	if (cooldowns[player] or 0) > now then return end

	local amount = if typeof(count) == "number" then math.clamp(math.floor(count), 1, 10) else 1

	local luck = 1
	if Monetization.hasPass(player, "VIP") then luck *= GameConfig.Gamepasses.VIP.luck end
	if Monetization.hasPass(player, "LuckyEgg") then luck *= GameConfig.Gamepasses.LuckyEgg.luck end

	local results = {}
	for _ = 1, amount do
		if data.crystals < GameConfig.EggCost then break end
		data.crystals -= GameConfig.EggCost
		local pet = rollPet(luck)
		local owned = { id = pet.id, uid = HttpService:GenerateGUID(false) }
		table.insert(data.pets, owned)
		table.insert(results, owned)
	end

	if #results == 0 then return end
	cooldowns[player] = now + GameConfig.EggCooldown
	Remotes.HatchResult:FireClient(player, results)

	-- Legendary announcements make the whole server want to hatch. Free marketing.
	for _, owned in results do
		local def = GameConfig.getPet(owned.id)
		if def and def.rarity == "Legendary" then
			Remotes.Announce:FireAllClients(("%s hatched a %s!"):format(player.DisplayName, def.name))
		end
	end
end

function PetService.grantPet(player: Player, petId: string)
	local data = DataManager.get(player)
	if not data or not GameConfig.getPet(petId) then return end
	local owned = { id = petId, uid = HttpService:GenerateGUID(false) }
	table.insert(data.pets, owned)
	Remotes.HatchResult:FireClient(player, { owned })
end

function PetService.grantRandomOfRarity(player: Player, rarity: string)
	local candidates = {}
	for _, p in GameConfig.Pets do
		if p.rarity == rarity then table.insert(candidates, p) end
	end
	if #candidates == 0 then return end
	PetService.grantPet(player, candidates[rng:NextInteger(1, #candidates)].id)
end

function PetService.maxSlots(player: Player): number
	local n = GameConfig.BasePetSlots
	if Monetization.hasPass(player, "PetSlots") then n += GameConfig.GamepassPetSlots end
	return n
end

function PetService.equip(player: Player, uid: any)
	local data = DataManager.get(player)
	if not data or typeof(uid) ~= "string" then return end

	-- Verify ownership. Never trust a uid from the client.
	local owns = false
	for _, p in data.pets do
		if p.uid == uid then owns = true break end
	end
	if not owns then return end

	for i, e in data.equipped do
		if e == uid then
			table.remove(data.equipped, i)
			Remotes.EquipUpdate:FireClient(player, data.equipped)
			return
		end
	end

	if #data.equipped >= PetService.maxSlots(player) then
		Remotes.Notify:FireClient(player, "Pet slots full! Get +5 slots in the shop.")
		return
	end

	table.insert(data.equipped, uid)
	Remotes.EquipUpdate:FireClient(player, data.equipped)
end

return PetService
