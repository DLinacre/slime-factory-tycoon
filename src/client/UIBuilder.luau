--!strict
--[[
	UIBuilder — ModuleScript inside StarterPlayerScripts, next to ClientMain.

	Builds the ENTIRE interface in code. Why: you never have to drag a Frame in
	Studio, the layout is version-controllable, and mobile scaling is handled
	once with UIScale + Scale-based UDim2 instead of pixel guesswork.

	Mobile-first rules applied here:
	  * every tap target is >= 44px tall
	  * the main vat button sits in the lower-middle (thumb zone)
	  * nav buttons are on the LEFT edge so a right thumb doesn't cover them
	  * no text smaller than 14; TextScaled where possible
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Format = require(ReplicatedStorage.Modules.Format)

local UIBuilder = {}

local PALETTE = {
	bg      = Color3.fromRGB(24, 18, 40),
	panel   = Color3.fromRGB(38, 30, 60),
	accent  = Color3.fromRGB(120, 255, 120),
	accent2 = Color3.fromRGB(255, 150, 40),
	text    = Color3.fromRGB(255, 255, 255),
	dim     = Color3.fromRGB(170, 165, 190),
}

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function stroke(parent: Instance, colour: Color3, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness or 2
	s.Parent = parent
	return s
end

local function label(parent: Instance, text: string, size: UDim2, pos: UDim2)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = Enum.Font.GothamBold
	l.Text = text
	l.TextColor3 = PALETTE.text
	l.TextScaled = true
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string, size: UDim2, pos: UDim2, colour: Color3)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = colour
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.TextColor3 = PALETTE.text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b)
	return b
end

function UIBuilder.build(player: Player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SlimeFactoryUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	-- One UIScale handles phone vs tablet vs desktop in a single place.
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local function updateScale()
		local vp = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(vp.Y / 800, 0.7, 1.4)
	end
	updateScale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

	local ui: any = { gui = gui, upgradeRows = {}, buyAmount = { value = 1 } }

	-- ---------------------------------------------------- top bar
	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, -20, 0, 70)
	top.Position = UDim2.new(0, 10, 0, 10)
	top.BackgroundColor3 = PALETTE.panel
	top.BackgroundTransparency = 0.1
	top.Parent = gui
	corner(top)

	ui.gooLabel = label(top, "0 Goo", UDim2.new(0.5, -10, 0, 34), UDim2.new(0, 12, 0, 6))
	ui.gooLabel.TextXAlignment = Enum.TextXAlignment.Left
	ui.gooLabel.TextColor3 = PALETTE.accent

	ui.rateLabel = label(top, "+0/s", UDim2.new(0.5, -10, 0, 22), UDim2.new(0, 12, 0, 42))
	ui.rateLabel.TextXAlignment = Enum.TextXAlignment.Left
	ui.rateLabel.TextColor3 = PALETTE.dim

	ui.crystalLabel = label(top, "0 💎", UDim2.new(0.4, -12, 0, 34), UDim2.new(0.6, 0, 0, 18))
	ui.crystalLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- ---------------------------------------------------- the vat (main tap)
	-- Positioned low-centre: this is the natural thumb resting zone on a phone.
	ui.vatButton = Instance.new("ImageButton")
	ui.vatButton.Size = UDim2.new(0, 220, 0, 220)
	ui.vatButton.Position = UDim2.new(0.5, 0, 0.62, 0)
	ui.vatButton.AnchorPoint = Vector2.new(0.5, 0.5)
	ui.vatButton.BackgroundColor3 = PALETTE.accent
	ui.vatButton.Image = "" -- put your slime vat image asset id here
	ui.vatButton.Parent = gui
	corner(ui.vatButton, 110)
	stroke(ui.vatButton, Color3.fromRGB(255, 255, 255), 4)
	label(ui.vatButton, "TAP", UDim2.new(0.6, 0, 0.25, 0), UDim2.new(0.2, 0, 0.375, 0)).TextColor3 = Color3.fromRGB(20, 40, 20)

	ui.vatSizeUp = UDim2.new(0, 220, 0, 220)
	ui.vatSizeDown = UDim2.new(0, 200, 0, 200)

	-- ---------------------------------------------------- side nav (left edge)
	local nav = Instance.new("Frame")
	nav.Size = UDim2.new(0, 74, 0, 300)
	nav.Position = UDim2.new(0, 10, 0.5, -120)
	nav.BackgroundTransparency = 1
	nav.Parent = gui
	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding = UDim.new(0, 8)
	navLayout.Parent = nav

	local panels = {}
	local function makePanel(name: string)
		local p = Instance.new("Frame")
		p.Name = name
		p.Size = UDim2.new(0, 340, 0, 400)
		p.Position = UDim2.new(0.5, 0, 0.5, 0)
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.BackgroundColor3 = PALETTE.panel
		p.Visible = false
		p.Parent = gui
		corner(p)
		stroke(p, PALETTE.accent, 2)
		local title = label(p, name, UDim2.new(1, -60, 0, 36), UDim2.new(0, 12, 0, 8))
		title.TextXAlignment = Enum.TextXAlignment.Left
		local close = button(p, "X", UDim2.new(0, 40, 0, 40), UDim2.new(1, -48, 0, 6), Color3.fromRGB(200, 60, 60))
		close.MouseButton1Click:Connect(function() p.Visible = false end)
		panels[name] = p
		return p
	end

	local function navButton(text: string, panelName: string)
		local b = button(nav, text, UDim2.new(0, 74, 0, 56), UDim2.new(), PALETTE.panel)
		b.MouseButton1Click:Connect(function()
			for n, p in panels do p.Visible = (n == panelName) and not p.Visible end
		end)
		return b
	end

	local upgradesPanel = makePanel("Upgrades")
	local petsPanel = makePanel("Pets")
	local shopPanel = makePanel("Shop")
	local boardPanel = makePanel("Top Players")
	local codesPanel = makePanel("Codes")

	navButton("⬆️", "Upgrades")
	navButton("🥚", "Pets")
	navButton("🛒", "Shop")
	navButton("🏆", "Top Players")
	navButton("🎟️", "Codes")

	ui.dailyButton = button(nav, "🎁", UDim2.new(0, 74, 0, 56), UDim2.new(), PALETTE.accent2)

	-- ---------------------------------------------------- upgrades panel
	local upScroll = Instance.new("ScrollingFrame")
	upScroll.Size = UDim2.new(1, -20, 1, -110)
	upScroll.Position = UDim2.new(0, 10, 0, 52)
	upScroll.BackgroundTransparency = 1
	upScroll.ScrollBarThickness = 4
	upScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	upScroll.CanvasSize = UDim2.new()
	upScroll.Parent = upgradesPanel
	local upLayout = Instance.new("UIListLayout")
	upLayout.Padding = UDim.new(0, 8)
	upLayout.Parent = upScroll

	for _, def in GameConfig.Upgrades do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundColor3 = PALETTE.bg
		row.Parent = upScroll
		corner(row)
		local t = label(row, def.name, UDim2.new(0.55, 0, 0, 26), UDim2.new(0, 10, 0, 6))
		t.TextXAlignment = Enum.TextXAlignment.Left
		local sub = label(row, ("+%d tap  +%d/s"):format(def.addClick, def.addAuto), UDim2.new(0.55, 0, 0, 18), UDim2.new(0, 10, 0, 32))
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextColor3 = PALETTE.dim
		local b = button(row, "0", UDim2.new(0.38, 0, 0, 44), UDim2.new(0.6, 0, 0, 6), Color3.fromRGB(60, 200, 110))
		ui.upgradeRows[def.id] = { frame = row, title = t, button = b }
	end

	-- buy-amount toggle: x1 / x10 / MAX. Fewer taps = more purchases.
	local amounts = { 1, 10, 100 }
	local amtIndex = 1
	local amtBtn = button(upgradesPanel, "Buy x1", UDim2.new(0.45, 0, 0, 44), UDim2.new(0, 10, 1, -52), Color3.fromRGB(70, 90, 160))
	amtBtn.MouseButton1Click:Connect(function()
		amtIndex = (amtIndex % #amounts) + 1
		ui.buyAmount.value = amounts[amtIndex]
		amtBtn.Text = "Buy x" .. amounts[amtIndex]
	end)

	ui.rebirthButton = button(upgradesPanel, "REBIRTH", UDim2.new(0.48, 0, 0, 44), UDim2.new(0.5, 0, 1, -52), PALETTE.accent2)

	-- ---------------------------------------------------- pets panel
	local petScroll = Instance.new("ScrollingFrame")
	petScroll.Size = UDim2.new(1, -20, 1, -160)
	petScroll.Position = UDim2.new(0, 10, 0, 52)
	petScroll.BackgroundTransparency = 1
	petScroll.ScrollBarThickness = 4
	petScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petScroll.CanvasSize = UDim2.new()
	petScroll.Parent = petsPanel
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 96, 0, 96)
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.Parent = petScroll
	ui.petScroll = petScroll

	ui.hatchButton = button(petsPanel, ("Hatch (%d 💎)"):format(GameConfig.EggCost), UDim2.new(0.48, 0, 0, 44), UDim2.new(0, 10, 1, -100), Color3.fromRGB(60, 200, 110))
	ui.hatch10Button = button(petsPanel, "Hatch x10", UDim2.new(0.45, 0, 0, 44), UDim2.new(0.52, 0, 1, -100), Color3.fromRGB(70, 90, 160))

	-- Published odds. Required practice for paid randomisation, and honestly it
	-- increases spend because players trust the numbers.
	local oddsText = {}
	local totalW = 0
	for _, r in GameConfig.Rarities do totalW += r.weight end
	for name, r in GameConfig.Rarities do
		table.insert(oddsText, ("%s %.2f%%"):format(name, r.weight / totalW * 100))
	end
	local odds = label(petsPanel, table.concat(oddsText, "  |  "), UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 1, -48))
	odds.TextColor3 = PALETTE.dim

	-- ---------------------------------------------------- shop panel
	local shopScroll = Instance.new("ScrollingFrame")
	shopScroll.Size = UDim2.new(1, -20, 1, -60)
	shopScroll.Position = UDim2.new(0, 10, 0, 52)
	shopScroll.BackgroundTransparency = 1
	shopScroll.ScrollBarThickness = 4
	shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopScroll.CanvasSize = UDim2.new()
	shopScroll.Parent = shopPanel
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 8)
	shopLayout.Parent = shopScroll
	ui.shopEntries = {}

	local function shopRow(kind: string, key: string, title: string, price: number, desc: string)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 62)
		row.BackgroundColor3 = PALETTE.bg
		row.Parent = shopScroll
		corner(row)
		local t = label(row, title, UDim2.new(0.6, 0, 0, 26), UDim2.new(0, 10, 0, 6))
		t.TextXAlignment = Enum.TextXAlignment.Left
		local d = label(row, desc, UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 10, 0, 34))
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.TextColor3 = PALETTE.dim
		local b = button(row, ("R$ %d"):format(price), UDim2.new(0.33, 0, 0, 46), UDim2.new(0.65, 0, 0, 8), Color3.fromRGB(60, 200, 110))
		table.insert(ui.shopEntries, { kind = kind, key = key, button = b })
	end

	shopRow("pass", "DoubleGoo", "2x Goo", GameConfig.Gamepasses.DoubleGoo.price, "Permanently double all income")
	shopRow("pass", "AutoClicker", "Auto Clicker", GameConfig.Gamepasses.AutoClicker.price, "Taps for you — no more thumb ache")
	shopRow("pass", "VIP", "VIP", GameConfig.Gamepasses.VIP.price, "2x luck, chat tag, VIP zone")
	shopRow("pass", "PetSlots", "+5 Pet Slots", GameConfig.Gamepasses.PetSlots.price, "Equip 8 pets at once")
	shopRow("pass", "LuckyEgg", "Lucky Egg", GameConfig.Gamepasses.LuckyEgg.price, "Permanently better hatch odds")
	shopRow("product", "ServerBoost", "Server 2x Boost", GameConfig.Products.ServerBoost.price, "15 min for EVERYONE — be the hero")
	shopRow("product", "Boost3x", "3x Boost 30min", GameConfig.Products.Boost3x.price, "Triple income right now")
	shopRow("product", "Crystals1k", "1,000 Crystals", GameConfig.Products.Crystals1k.price, "Hatch 4 eggs")
	shopRow("product", "Crystals6k", "6,000 Crystals", GameConfig.Products.Crystals6k.price, "BEST VALUE")
	shopRow("product", "Crystals15k", "15,000 Crystals", GameConfig.Products.Crystals15k.price, "Whale pack")

	-- ---------------------------------------------------- leaderboard panel
	local boardScroll = Instance.new("ScrollingFrame")
	boardScroll.Size = UDim2.new(1, -20, 1, -60)
	boardScroll.Position = UDim2.new(0, 10, 0, 52)
	boardScroll.BackgroundTransparency = 1
	boardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	boardScroll.CanvasSize = UDim2.new()
	boardScroll.ScrollBarThickness = 4
	boardScroll.Parent = boardPanel
	local bl = Instance.new("UIListLayout")
	bl.Padding = UDim.new(0, 4)
	bl.Parent = boardScroll
	ui.boardScroll = boardScroll

	-- ---------------------------------------------------- codes panel
	local codeBox = Instance.new("TextBox")
	codeBox.Size = UDim2.new(1, -20, 0, 52)
	codeBox.Position = UDim2.new(0, 10, 0, 60)
	codeBox.BackgroundColor3 = PALETTE.bg
	codeBox.Font = Enum.Font.GothamBold
	codeBox.PlaceholderText = "ENTER CODE"
	codeBox.Text = ""
	codeBox.TextColor3 = PALETTE.text
	codeBox.TextScaled = true
	codeBox.ClearTextOnFocus = false
	codeBox.Parent = codesPanel
	corner(codeBox)
	ui.codeBox = codeBox

	ui.codeSubmit = button(codesPanel, "REDEEM", UDim2.new(1, -20, 0, 48), UDim2.new(0, 10, 0, 120), PALETTE.accent2)

	ui.codeStatus = label(codesPanel, "Follow the group for new codes!", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 178))
	ui.codeStatus.TextColor3 = PALETTE.dim

	-- ---------------------------------------------------- transient layers
	ui.toastLabel = label(gui, "", UDim2.new(0, 300, 0, 40), UDim2.new(0.5, -150, 0, 90))
	ui.toastLabel.TextTransparency = 1

	ui.bannerLabel = label(gui, "", UDim2.new(0, 420, 0, 60), UDim2.new(0.5, -210, 0.3, 0))
	ui.bannerLabel.TextTransparency = 1
	ui.bannerLabel.TextColor3 = PALETTE.accent2

	ui.announceLabel = label(gui, "", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 86))
	ui.announceLabel.TextTransparency = 1
	ui.announceLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

	ui.popLayer = Instance.new("Frame")
	ui.popLayer.Size = UDim2.new(1, 0, 1, 0)
	ui.popLayer.BackgroundTransparency = 1
	ui.popLayer.Parent = gui

	ui.panels = panels
	return ui
end

-- ============================================================ effects
function UIBuilder.popText(ui, text: string)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(0, 120, 0, 30)
	l.Position = UDim2.new(0.5, math.random(-60, 60), 0.55, math.random(-20, 20))
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Font = Enum.Font.GothamBold
	l.Text = text
	l.TextColor3 = Color3.fromRGB(180, 255, 180)
	l.TextScaled = true
	l.Parent = ui.popLayer
	TweenService:Create(l, TweenInfo.new(0.7), {
		Position = l.Position - UDim2.new(0, 0, 0.08, 0),
		TextTransparency = 1,
	}):Play()
	task.delay(0.75, function() l:Destroy() end)
end

function UIBuilder.toast(ui, text: string)
	ui.toastLabel.Text = text
	ui.toastLabel.TextTransparency = 0
	TweenService:Create(ui.toastLabel, TweenInfo.new(1.6), { TextTransparency = 1 }):Play()
end

function UIBuilder.bigBanner(ui, text: string)
	ui.bannerLabel.Text = text
	ui.bannerLabel.TextTransparency = 0
	ui.bannerLabel.Size = UDim2.new(0, 300, 0, 50)
	TweenService:Create(ui.bannerLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 60),
	}):Play()
	task.delay(1.4, function()
		TweenService:Create(ui.bannerLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	end)
end

function UIBuilder.announce(ui, text: string)
	ui.announceLabel.Text = text
	ui.announceLabel.TextTransparency = 0
	task.delay(3, function()
		TweenService:Create(ui.announceLabel, TweenInfo.new(1), { TextTransparency = 1 }):Play()
	end)
end

function UIBuilder.pulse(guiObject: GuiObject)
	task.spawn(function()
		local base = guiObject.Size
		while guiObject.Parent do
			TweenService:Create(guiObject, TweenInfo.new(0.5), { Size = base + UDim2.new(0, 8, 0, 8) }):Play()
			task.wait(0.5)
			TweenService:Create(guiObject, TweenInfo.new(0.5), { Size = base }):Play()
			task.wait(0.5)
		end
	end)
end

function UIBuilder.hatchReveal(ui, petDef)
	local r = GameConfig.Rarities[petDef.rarity]
	UIBuilder.bigBanner(ui, ("%s  [%s]"):format(petDef.name, petDef.rarity))
	ui.bannerLabel.TextColor3 = r.colour
end

function UIBuilder.offlinePopup(ui, amount: number, seconds: number)
	UIBuilder.bigBanner(ui, ("Welcome back! You earned %s Goo while away (%s)")
		:format(Format.number(amount), Format.time(seconds)))
end

function UIBuilder.renderPets(ui, pets, equipped, onClick)
	for _, c in ui.petScroll:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local equippedSet = {}
	for _, uid in equipped do equippedSet[uid] = true end

	-- Cap rendered cards. A player with 500 pets should not create 500 frames.
	local shown = 0
	for _, owned in pets do
		if shown >= 60 then break end
		local def = GameConfig.getPet(owned.id)
		if def then
			shown += 1
			local rarity = GameConfig.Rarities[def.rarity]
			local card = Instance.new("TextButton")
			card.Size = UDim2.new(0, 96, 0, 96)
			card.BackgroundColor3 = Color3.fromRGB(30, 24, 48)
			card.Text = ("%s\n+%.0f%%"):format(def.name, def.mult * 100)
			card.Font = Enum.Font.GothamBold
			card.TextColor3 = Color3.fromRGB(255, 255, 255)
			card.TextSize = 13
			card.TextWrapped = true
			card.Parent = ui.petScroll
			corner(card, 10)
			stroke(card, rarity.colour, equippedSet[owned.uid] and 4 or 2)
			card.MouseButton1Click:Connect(function() onClick(owned.uid) end)
		end
	end
end

function UIBuilder.renderLeaderboard(ui, top)
	for _, c in ui.boardScroll:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	for _, entry in (top.rebirths or {}) do
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 0, 26)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.Gotham
		l.TextSize = 15
		l.TextColor3 = Color3.fromRGB(255, 255, 255)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = ("#%d  %s  —  %d rebirths"):format(entry.rank, entry.name, entry.value)
		l.Parent = ui.boardScroll
	end
end

function UIBuilder.bindShop(ui, onPrompt)
	for _, entry in ui.shopEntries do
		entry.button.MouseButton1Click:Connect(function()
			onPrompt(entry.kind, entry.key)
		end)
	end
end

return UIBuilder
