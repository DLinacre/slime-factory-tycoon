--!strict
--[[
	UI — StarterPlayerScripts/UI

	A small component library so screens are composed rather than hand-built.
	Every widget here is theme-aware, touch-sized, and respects the accessibility
	settings (reduced motion, high contrast, text scale).

	This replaces the ad-hoc helper functions that were duplicated inside
	UIBuilder, and is what makes new screens cheap to add.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Theme"))

local UI = {}

-- Live accessibility state, updated from SettingsService.
UI.a11y = { reducedMotion = false, highContrast = false, textScale = 1.0 }

function UI.applySettings(s: { [string]: any })
	UI.a11y.reducedMotion = s.reducedMotion == true
	UI.a11y.highContrast = s.highContrast == true
	UI.a11y.textScale = (s.textScale or 100) / 100
end

--- Tween that collapses to an instant set when Reduced Motion is on.
function UI.tween(obj: Instance, info: TweenInfo, goal: { [string]: any }): Tween?
	if UI.a11y.reducedMotion then
		for k, v in goal do
			(obj :: any)[k] = v
		end
		return nil
	end
	local t = TweenService:Create(obj, info, goal)
	t:Play()
	return t
end

function UI.corner(parent: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or Theme.Radius.md)
	c.Parent = parent
	return c
end

function UI.stroke(parent: Instance, colour: Color3, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UI.padding(parent: Instance, all: number): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, all)
	p.PaddingBottom = UDim.new(0, all)
	p.PaddingLeft = UDim.new(0, all)
	p.PaddingRight = UDim.new(0, all)
	p.Parent = parent
	return p
end

function UI.gradient(parent: Instance, from: Color3, to: Color3, rotation: number?): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(from, to)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

export type LabelProps = {
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2?,
	font: Enum.Font?,
	textSize: number?,
	colour: Color3?,
	align: Enum.TextXAlignment?,
	scaled: boolean?,
}

function UI.label(props: LabelProps): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = props.size
	l.Position = props.position or UDim2.new()
	l.Font = props.font or Theme.Font.heading
	l.Text = props.text
	l.TextColor3 = props.colour or Theme.Colour.text
	l.TextXAlignment = props.align or Enum.TextXAlignment.Center
	if props.scaled ~= false then
		l.TextScaled = true
	else
		l.TextSize = math.floor((props.textSize or Theme.TextSize.body) * UI.a11y.textScale)
	end
	l.RichText = true
	l.Parent = props.parent
	return l
end

export type ButtonProps = {
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2?,
	colour: Color3?,
	textColour: Color3?,
	onClick: (() -> ())?,
	icon: string?,
}

--- A button with built-in press feedback and a guaranteed 44px touch height.
function UI.button(props: ButtonProps): TextButton
	local b = Instance.new("TextButton")
	b.Size = props.size
	b.Position = props.position or UDim2.new()
	b.BackgroundColor3 = props.colour or Theme.Colour.surfaceHi
	b.Font = Theme.Font.heading
	b.Text = props.text
	b.TextColor3 = props.textColour or Theme.Colour.text
	b.TextScaled = true
	b.AutoButtonColor = false
	b.Parent = props.parent
	UI.corner(b)
	UI.padding(b, 6)

	if UI.a11y.highContrast then
		UI.stroke(b, Theme.Colour.text, 2)
	end

	-- press feedback: scale down slightly, spring back
	local base = props.size
	b.MouseButton1Down:Connect(function()
		UI.tween(b, Theme.Motion.instant, { BackgroundTransparency = 0.25 })
	end)
	local function release()
		UI.tween(b, Theme.Motion.fast, { BackgroundTransparency = 0 })
	end
	b.MouseButton1Up:Connect(release)
	b.MouseLeave:Connect(release)

	if props.onClick then
		b.MouseButton1Click:Connect(props.onClick)
	end
	return b
end

--- Vertical list container with automatic canvas sizing.
function UI.scrollList(parent: Instance, size: UDim2, position: UDim2, padding: number?): ScrollingFrame
	local sf = Instance.new("ScrollingFrame")
	sf.Size = size
	sf.Position = position
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 4
	sf.ScrollBarImageColor3 = Theme.Colour.line
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.CanvasSize = UDim2.new()
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	sf.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding or Theme.Space.sm)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = sf
	return sf
end

--- A card surface used for list rows.
function UI.card(parent: Instance, height: number): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, math.max(height, Theme.MinTouchTarget))
	f.BackgroundColor3 = Theme.Colour.bg
	f.BorderSizePixel = 0
	f.Parent = parent
	UI.corner(f)
	return f
end

--- Determinate progress bar. Used for achievements and season tracks.
function UI.progressBar(parent: Instance, size: UDim2, position: UDim2): (Frame, (number) -> ())
	local track = Instance.new("Frame")
	track.Size = size
	track.Position = position
	track.BackgroundColor3 = Theme.Colour.void
	track.BorderSizePixel = 0
	track.Parent = parent
	UI.corner(track, Theme.Radius.pill)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Theme.Colour.slime
	fill.BorderSizePixel = 0
	fill.Parent = track
	UI.corner(fill, Theme.Radius.pill)

	local function set(alpha: number)
		alpha = math.clamp(alpha, 0, 1)
		UI.tween(fill, Theme.Motion.normal, { Size = UDim2.new(alpha, 0, 1, 0) })
		fill.BackgroundColor3 = if alpha >= 1 then Theme.Colour.success else Theme.Colour.slime
	end

	return track, set
end

--- Modal panel with a scrim. Returns the content frame and a close function.
function UI.panel(parent: Instance, title: string, size: UDim2): (Frame, Frame, () -> ())
	local scrim = Instance.new("TextButton")
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = Theme.Colour.void
	scrim.BackgroundTransparency = 0.4
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Visible = false
	scrim.ZIndex = 10
	scrim.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Theme.Colour.surface
	frame.BorderSizePixel = 0
	frame.ZIndex = 11
	frame.Parent = scrim
	UI.corner(frame, Theme.Radius.lg)
	UI.stroke(frame, Theme.Colour.line, 2)

	local header = UI.label({
		parent = frame,
		text = title,
		size = UDim2.new(1, -70, 0, 38),
		position = UDim2.new(0, Theme.Space.md, 0, Theme.Space.sm),
		font = Theme.Font.display,
		align = Enum.TextXAlignment.Left,
	})
	header.ZIndex = 12

	local function close()
		UI.tween(frame, Theme.Motion.fast, { Size = UDim2.new(size.X.Scale * 0.94, size.X.Offset, size.Y.Scale * 0.94, size.Y.Offset) })
		task.delay(UI.a11y.reducedMotion and 0 or 0.12, function()
			scrim.Visible = false
			frame.Size = size
		end)
	end

	local closeBtn = UI.button({
		parent = frame,
		text = "✕",
		size = UDim2.new(0, 42, 0, 42),
		position = UDim2.new(1, -50, 0, 8),
		colour = Theme.Colour.danger,
		onClick = close,
	})
	closeBtn.ZIndex = 12

	scrim.MouseButton1Click:Connect(close)

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, 0, 1, -54)
	content.Position = UDim2.new(0, 0, 0, 54)
	content.BackgroundTransparency = 1
	content.ZIndex = 11
	content.Parent = frame

	return scrim, content, close
end

function UI.open(scrim: Frame)
	scrim.Visible = true
	local frame = scrim:FindFirstChildWhichIsA("Frame")
	if frame and not UI.a11y.reducedMotion then
		local target = frame.Size
		frame.Size = UDim2.new(target.X.Scale * 0.9, target.X.Offset, target.Y.Scale * 0.9, target.Y.Offset)
		UI.tween(frame, Theme.Motion.pop, { Size = target })
	end
end

return UI
