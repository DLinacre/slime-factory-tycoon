--!strict
--[[
	MonetizationService — ModuleScript in ServerScriptService/Services

	Handles gamepasses (cached) and developer products (idempotent ProcessReceipt).

	CRITICAL: ProcessReceipt must be set on exactly ONE script in the whole game,
	and it must be idempotent. If you grant the reward and then fail to save, the
	player is charged and gets nothing — that's a refund request and a bad review.
	The order below (record -> save -> grant -> confirm) is the safe one.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local GameConfig = require(Modules.GameConfig)
local Net = require(Modules.Net)
local Registry = require(Modules.ServiceRegistry)
local DataManager = require(script.Parent.DataManager)
local EconomyService = require(script.Parent.EconomyService)

local MonetizationService = {}

local passCache: { [Player]: { [string]: boolean } } = {}

-- Gamepass ownership is checked ONCE at join, then cached. Calling
-- UserOwnsGamePassAsync every frame will get you rate-limited.
function MonetizationService:onPlayerAdded(player: Player)
	MonetizationService.setupPlayer(player)
end

function MonetizationService:onPlayerRemoving(player: Player)
	MonetizationService.cleanupPlayer(player)
end

function MonetizationService.setupPlayer(player: Player)
	local cache = {}
	passCache[player] = cache
	for name, pass in GameConfig.Gamepasses do
		if pass.id and pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			cache[name] = ok and owns or false
		else
			cache[name] = false
		end
	end
end

function MonetizationService.cleanupPlayer(player: Player)
	passCache[player] = nil
end

function MonetizationService.hasPass(player: Player, name: string): boolean
	local c = passCache[player]
	return c ~= nil and c[name] == true
end

-- Wire the lookup into EconomyService so multipliers can see gamepasses.
EconomyService.hasPass = MonetizationService.hasPass

local function grantProduct(player: Player, productName: string): boolean
	local data = DataManager.get(player)
	if not data then return false end
	local def = GameConfig.Products[productName]
	if not def then return false end

	if def.crystals then
		data.crystals += def.crystals
	end
	if def.boost then
		EconomyService.grantBoost(player, def.boost.mult, def.boost.seconds)
	end
	if def.serverBoost then
		EconomyService.grantServerBoost(player, def.serverBoost.mult, def.serverBoost.seconds)
	end
	if productName == "InstantRebirth" then
		data.goo = math.max(data.goo, GameConfig.rebirthCost(data.rebirths))
		EconomyService.rebirth(player)
	end
	if productName == "SkipEggCd" then
		Registry.get("PetService").clearCooldown(player)
	end
	-- Robux cosmetics: the product id is looked up by cosmetic id
	if def.cosmetic then
		Registry.get("CosmeticService"):grant(player, def.cosmetic)
	end
	return true
end

local function productNameFromId(id: number): string?
	for name, def in GameConfig.Products do
		if def.id == id then return name end
	end
	return nil
end

function MonetizationService:start()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- Player left. Do NOT grant. Returning NotProcessedYet means Roblox
			-- will call us again next time they join.
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local data = DataManager.get(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local key = tostring(receiptInfo.PurchaseId)

		-- IDEMPOTENCY: already granted? confirm again and move on. This is what
		-- stops double-grants when Roblox retries a receipt.
		if data.purchaseHistory[key] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local name = productNameFromId(receiptInfo.ProductId)
		if not name then
			warn("[Monetization] unknown product id", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok, err = pcall(grantProduct, player, name)
		if not ok then
			warn("[Monetization] grant failed:", err)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Record BEFORE we confirm, and force a save so a crash can't lose it.
		data.purchaseHistory[key] = true
		local saved = pcall(DataManager.save, player, false)
		if not saved then
			data.purchaseHistory[key] = nil
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		Net.fireClient("PurchaseSuccess", player, name)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Live gamepass purchases: update the cache immediately so the perk applies
	-- without a rejoin. Players who have to rejoin often just refund instead.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then return end
		local cache = passCache[player]
		if not cache then return end
		for name, pass in GameConfig.Gamepasses do
			if pass.id == passId then
				cache[name] = true
				Net.fireClient("PurchaseSuccess", player, name)
			end
		end
	end)
end

return MonetizationService
