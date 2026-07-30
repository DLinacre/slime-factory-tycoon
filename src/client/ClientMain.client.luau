--!strict
--[[
	ClientMain — a *LocalScript* in StarterPlayer/StarterPlayerScripts

	Client responsibilities ONLY:
	  * draw the UI
	  * batch taps and send a count
	  * predict the goo counter locally so the number feels instant,
	    then reconcile with the server's authoritative value 4x a second

	The client stores no truth. If an exploiter edits these numbers, their
	screen lies to them and nothing else changes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local GameConfig = require(Modules.GameConfig)
local Format = require(Modules.Format)
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

-- ============================================================ local state
local state = {
	goo = 0, crystals = 0, rebirths = 0, zone = 1,
	clickPower = 1, autoIncome = 0, mult = 1,
	upgrades = {}, pets = {}, equipped = {}, passes = {},
}

local displayedGoo = 0 -- smoothed for the counter animation
local pendingClicks = 0

local ui = UIBuilder.build(player)

-- ============================================================ helpers
local function refreshTopBar()
	ui.gooLabel.Text = Format.number(displayedGoo) .. " Goo"
	ui.crystalLabel.Text = Format.number(state.crystals) .. " 💎"
	ui.rateLabel.Text = ("+%s/s  •  x%.1f"):format(Format.number(state.autoIncome), state.mult)
end

local function refreshUpgrades()
	for _, def in GameConfig.Upgrades do
		local row = ui.upgradeRows[def.id]
		if row then
			local level = state.upgrades[def.id] or 0
			local cost = GameConfig.upgradeCost(def.id, level)
			row.title.Text = ("%s  Lv.%d"):format(def.name, level)
			row.button.Text = Format.number(cost)
			local affordable = state.goo >= cost
			row.button.BackgroundColor3 = affordable
				and Color3.fromRGB(60, 200, 110)
				or Color3.fromRGB(90, 90, 100)
			row.button.AutoButtonColor = affordable
		end
	end
	local cost = GameConfig.rebirthCost(state.rebirths)
	ui.rebirthButton.Text = ("REBIRTH  (%s)"):format(Format.number(cost))
	ui.rebirthButton.BackgroundColor3 = state.goo >= cost
		and Color3.fromRGB(255, 150, 40) or Color3.fromRGB(90, 90, 100)
end

local function refreshPets()
	UIBuilder.renderPets(ui, state.pets, state.equipped, function(uid)
		Remotes.EquipPet:FireServer(uid)
	end)
end

-- ============================================================ tap handling
-- Every tap is instant on screen; we send the COUNT every 0.2s. One remote call
-- per fifth of a second instead of one per tap = ~10x less network churn.
local function onTap()
	pendingClicks += 1
	displayedGoo += state.clickPower
	refreshTopBar()
	UIBuilder.popText(ui, "+" .. Format.number(state.clickPower))
	-- squash-and-stretch feedback: cheap, and it makes the tap feel good
	local t = TweenService:Create(ui.vatButton, TweenInfo.new(0.08), { Size = ui.vatSizeDown })
	t:Play()
	t.Completed:Once(function()
		TweenService:Create(ui.vatButton, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = ui.vatSizeUp }):Play()
	end)
end

ui.vatButton.MouseButton1Down:Connect(onTap)

-- Spacebar for PC players (mobile is the priority but PC costs one line)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Space then onTap() end
end)

task.spawn(function()
	while true do
		task.wait(GameConfig.ClickBatchWindow)
		if pendingClicks > 0 then
			Remotes.Click:FireServer(pendingClicks)
			pendingClicks = 0
		end
	end
end)

-- ============================================================ buttons
for _, def in GameConfig.Upgrades do
	local row = ui.upgradeRows[def.id]
	if row then
		row.button.MouseButton1Click:Connect(function()
			Remotes.BuyUpgrade:FireServer(def.id, ui.buyAmount.value)
		end)
	end
end

ui.rebirthButton.MouseButton1Click:Connect(function()
	Remotes.Rebirth:FireServer()
end)

ui.hatchButton.MouseButton1Click:Connect(function()
	Remotes.Hatch:FireServer(1)
end)

ui.hatch10Button.MouseButton1Click:Connect(function()
	Remotes.Hatch:FireServer(10)
end)

ui.dailyButton.MouseButton1Click:Connect(function()
	Remotes.ClaimDaily:FireServer()
end)

ui.codeSubmit.MouseButton1Click:Connect(function()
	local code = ui.codeBox.Text
	if #code > 0 then
		Remotes.RedeemCode:FireServer(code)
	end
end)

Remotes.CodeResult.OnClientEvent:Connect(function(ok, message)
	ui.codeStatus.Text = message
	ui.codeStatus.TextColor3 = ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 110, 110)
	if ok then
		ui.codeBox.Text = ""
		UIBuilder.bigBanner(ui, message)
	end
end)

UIBuilder.bindShop(ui, function(kind, key)
	Remotes.PromptPurchase:FireServer(kind, key)
end)

-- ============================================================ server events
Remotes.InitialData.OnClientEvent:Connect(function(data)
	for k, v in data do state[k] = v end
	displayedGoo = data.goo
	refreshTopBar(); refreshUpgrades(); refreshPets()
	if data.daily and data.daily.canClaim then
		UIBuilder.pulse(ui.dailyButton)
	end
	if data.isPremium then
		UIBuilder.toast(ui, ("Premium bonus active: %.2fx Goo!"):format(GameConfig.PremiumMultiplier))
	end
end)

Remotes.StateSync.OnClientEvent:Connect(function(s)
	state.goo = s.goo
	state.crystals = s.crystals
	state.rebirths = s.rebirths
	state.zone = s.zone
	state.clickPower = s.clickPower
	state.autoIncome = s.autoIncome
	state.mult = s.mult
	-- Reconcile: if prediction drifted more than 2%, snap back to the server.
	if math.abs(displayedGoo - s.goo) > math.max(10, s.goo * 0.02) then
		displayedGoo = s.goo
	end
	refreshUpgrades()
end)

Remotes.UpgradeBought.OnClientEvent:Connect(function(id, level, spent)
	state.upgrades[id] = level
	displayedGoo -= spent
	refreshUpgrades(); refreshTopBar()
	UIBuilder.toast(ui, "Upgraded!")
end)

Remotes.Rebirthed.OnClientEvent:Connect(function(rebirths, crystals)
	state.rebirths = rebirths
	state.upgrades = {}
	displayedGoo = 0
	refreshUpgrades(); refreshTopBar()
	UIBuilder.bigBanner(ui, ("REBIRTH %d!  +%s 💎"):format(rebirths, Format.number(crystals)))
end)

Remotes.HatchResult.OnClientEvent:Connect(function(results)
	for _, owned in results do
		table.insert(state.pets, owned)
	end
	refreshPets()
	local last = results[#results]
	local def = GameConfig.getPet(last.id)
	if def then
		UIBuilder.hatchReveal(ui, def)
	end
end)

Remotes.EquipUpdate.OnClientEvent:Connect(function(equipped)
	state.equipped = equipped
	refreshPets()
end)

Remotes.OfflineEarnings.OnClientEvent:Connect(function(amount, seconds)
	UIBuilder.offlinePopup(ui, amount, seconds)
end)

Remotes.ZoneUnlocked.OnClientEvent:Connect(function(zoneId)
	local z = GameConfig.Zones[zoneId]
	if z then UIBuilder.bigBanner(ui, ("UNLOCKED: %s (x%.1f)"):format(z.name, z.incomeMult)) end
end)

Remotes.DailyClaimed.OnClientEvent:Connect(function(day, reward)
	UIBuilder.bigBanner(ui, ("Day %d claimed! +%s 💎"):format(day, Format.number(reward.crystals)))
end)

Remotes.Announce.OnClientEvent:Connect(function(msg)
	UIBuilder.announce(ui, msg)
end)

Remotes.Notify.OnClientEvent:Connect(function(msg)
	UIBuilder.toast(ui, msg)
end)

Remotes.PurchaseSuccess.OnClientEvent:Connect(function(name)
	UIBuilder.bigBanner(ui, "Purchase complete — thank you!")
end)

Remotes.LeaderboardUpdate.OnClientEvent:Connect(function(top)
	UIBuilder.renderLeaderboard(ui, top)
end)

-- ============================================================ render loop
-- Smoothly count the number up. Runs on the client only, costs nothing on the
-- server, and makes idle income feel alive.
RunService.RenderStepped:Connect(function(dt)
	local target = state.goo
	if displayedGoo < target then
		displayedGoo = math.min(target, displayedGoo + math.max((target - displayedGoo) * dt * 4, state.autoIncome * dt))
	end
	refreshTopBar()
end)
