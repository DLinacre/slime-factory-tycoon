--!strict
--[[
	Theme — ReplicatedStorage/Modules/Theme

	The single source of truth for the game's visual identity. Shared by the
	in-game UI and mirrored in the website's brand tokens, so Roblox and web
	never drift apart.

	Brand: "industrial neon" — deep violet-black machinery lit by radioactive
	green goo, with amber as the reward/premium accent. Green means income,
	amber means value, violet is the world.
]]

local Theme = {}

-- ============================================================ COLOUR
Theme.Colour = {
	-- surfaces (darkest to lightest)
	void = Color3.fromRGB(14, 10, 24),
	bg = Color3.fromRGB(24, 18, 40),
	surface = Color3.fromRGB(38, 30, 60),
	surfaceHi = Color3.fromRGB(52, 42, 78),
	line = Color3.fromRGB(72, 60, 104),

	-- brand
	slime = Color3.fromRGB(120, 255, 120),
	slimeDeep = Color3.fromRGB(64, 200, 84),
	slimeGlow = Color3.fromRGB(180, 255, 170),
	amber = Color3.fromRGB(255, 150, 40),
	amberGlow = Color3.fromRGB(255, 200, 110),
	violet = Color3.fromRGB(150, 100, 255),

	-- text
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(170, 165, 190),
	textFaint = Color3.fromRGB(120, 116, 140),

	-- semantic
	success = Color3.fromRGB(80, 220, 120),
	danger = Color3.fromRGB(255, 90, 90),
	locked = Color3.fromRGB(90, 90, 100),
}

Theme.Rarity = {
	Common = Color3.fromRGB(180, 180, 190),
	Uncommon = Color3.fromRGB(110, 220, 130),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 60),
	Mythic = Color3.fromRGB(255, 80, 140),
}

-- ============================================================ TYPE
-- GothamBold for anything the player must read at a glance; Gotham for body.
Theme.Font = {
	display = Enum.Font.GothamBlack,
	heading = Enum.Font.GothamBold,
	body = Enum.Font.Gotham,
	mono = Enum.Font.Code,
}

Theme.TextSize = {
	hero = 42,
	title = 28,
	heading = 22,
	body = 17,
	small = 15,
	tiny = 13, -- never go below this; unreadable on a phone
}

-- ============================================================ SPACE
Theme.Space = { xs = 4, sm = 8, md = 12, lg = 18, xl = 28 }
Theme.Radius = { sm = 8, md = 12, lg = 18, pill = 999 }

-- Minimum interactive target. Apple/Google both say 44pt; we honour it.
Theme.MinTouchTarget = 44

-- ============================================================ MOTION
Theme.Motion = {
	instant = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	fast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	normal = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	slow = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	pop = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	settle = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
}

-- ============================================================ LAYOUT
--- Breakpoints by viewport width. Drives phone/tablet/desktop layout switching.
function Theme.deviceClass(viewport: Vector2): "phone" | "tablet" | "desktop"
	local w = viewport.X
	if w < 700 then
		return "phone"
	elseif w < 1100 then
		return "tablet"
	end
	return "desktop"
end

--- UI scale factor. Clamped so phones stay legible and 4K doesn't look absurd.
function Theme.scaleFor(viewport: Vector2): number
	return math.clamp(viewport.Y / 800, 0.72, 1.45)
end

table.freeze(Theme)
return Theme
