local EclipseLib = {}
EclipseLib.__index = EclipseLib

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Theme = {
	Background    = Color3.fromRGB(12, 12, 18),
	Surface       = Color3.fromRGB(18, 18, 26),
	SurfaceAlt    = Color3.fromRGB(23, 23, 33),
	SurfaceHover  = Color3.fromRGB(30, 30, 44),
	SurfaceBright = Color3.fromRGB(36, 36, 52),
	Accent        = Color3.fromRGB(100, 85, 240),
	AccentLight   = Color3.fromRGB(128, 112, 255),
	AccentDark    = Color3.fromRGB(64, 52, 170),
	AccentGlow    = Color3.fromRGB(80, 65, 200),
	Text          = Color3.fromRGB(235, 235, 250),
	TextSub       = Color3.fromRGB(155, 155, 185),
	TextDim       = Color3.fromRGB(85, 85, 115),
	BorderLight   = Color3.fromRGB(255, 255, 255),
	BorderDark    = Color3.fromRGB(60, 60, 88),
	Green         = Color3.fromRGB(68, 210, 130),
	Yellow        = Color3.fromRGB(255, 190, 50),
	Red           = Color3.fromRGB(255, 75, 90),
	ScrollBar     = Color3.fromRGB(55, 55, 80),
	Font          = Enum.Font.GothamMedium,
	FontBold      = Enum.Font.GothamBold,
	FontSemi      = Enum.Font.GothamSemibold,
}

local function New(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			pcall(function() obj[k] = v end)
		end
	end
	if props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function Corner(parent, r)
	return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function Stroke(parent, col, thick, trans)
	return New("UIStroke", {
		Color = col or Theme.BorderLight,
		Thickness = thick or 1,
		Transparency = trans or 0.86,
		Parent = parent,
	})
end

local function Padding(parent, t, r, b, l)
	return New("UIPadding", {
		PaddingTop    = UDim.new(0, t or 8),
		PaddingRight  = UDim.new(0, r or 8),
		PaddingBottom = UDim.new(0, b or 8),
		PaddingLeft   = UDim.new(0, l or 8),
		Parent        = parent,
	})
end

local function List(parent, dir, pad, ha, va)
	return New("UIListLayout", {
		FillDirection       = dir or Enum.FillDirection.Vertical,
		Padding             = UDim.new(0, pad or 6),
		HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
		VerticalAlignment   = va or Enum.VerticalAlignment.Top,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Parent              = parent,
	})
end

local function Gradient(parent, colors, rotation)
	local kp = {}
	for i, c in ipairs(colors) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c)
	end
	return New("UIGradient", {
		Color    = ColorSequence.new(kp),
		Rotation = rotation or 0,
		Parent   = parent,
	})
end

local function Tween(obj, props, t, style, dir)
	local info = TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	TweenService:Create(obj, info, props):Play()
end

local function clamp(n, a, b) return math.max(a, math.min(b, n)) end

local function HSV(h, s, v)
	if s == 0 then return Color3.new(v, v, v) end
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t2 = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return Color3.new(v, t2, p)
	elseif i == 1 then return Color3.new(q, v, p)
	elseif i == 2 then return Color3.new(p, v, t2)
	elseif i == 3 then return Color3.new(p, q, v)
	elseif i == 4 then return Color3.new(t2, p, v)
	else return Color3.new(v, p, q) end
end

local function toHSV(c)
	local r, g, b = c.R, c.G, c.B
	local mx = math.max(r, g, b)
	local mn = math.min(r, g, b)
	local d  = mx - mn
	local h2, s2, v2 = 0, mx == 0 and 0 or d / mx, mx
	if d ~= 0 then
		if mx == r then h2 = (g - b) / d + (g < b and 6 or 0)
		elseif mx == g then h2 = (b - r) / d + 2
		else h2 = (r - g) / d + 4 end
		h2 = h2 / 6
	end
	return h2, s2, v2
end

local ZBase = 100

local function getGui()
	local g
	local ok = pcall(function()
		if syn and syn.protect_gui then
			g = New("ScreenGui", {
				Name = "EclipseLib",
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			})
			syn.protect_gui(g)
			g.Parent = CoreGui
		end
	end)
	if not ok or not g then
		ok = pcall(function()
			g = New("ScreenGui", {
				Name = "EclipseLib",
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Parent = CoreGui,
			})
		end)
	end
	if not ok or not g then
		g = New("ScreenGui", {
			Name = "EclipseLib",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = LocalPlayer:WaitForChild("PlayerGui"),
		})
	end
	return g
end

local function Draggable(frame, handle)
	local dragging, origin, startPos = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragging = true
		startPos = i.Position
		origin   = frame.Position
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local d  = i.Position - startPos
		local vp = workspace.CurrentCamera.ViewportSize
		local nx = clamp(origin.X.Offset + d.X, 0, vp.X - frame.AbsoluteSize.X)
		local ny = clamp(origin.Y.Offset + d.Y, 0, vp.Y - frame.AbsoluteSize.Y)
		frame.Position = UDim2.new(0, nx, 0, ny)
	end)
end

local notifGui, notifHolder = nil, nil

local function ensureNotif()
	if notifGui and notifGui.Parent then return end
	notifGui = getGui()
	notifHolder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 310, 1, 0),
		Position = UDim2.new(1, -320, 0, 0),
		Parent = notifGui,
	})
	local l = List(notifHolder, Enum.FillDirection.Vertical, 8)
	l.VerticalAlignment = Enum.VerticalAlignment.Bottom
	New("UIPadding", { PaddingBottom = UDim.new(0, 20), Parent = notifHolder })
end

function EclipseLib:Notify(opts)
	opts = opts or {}
	local title    = opts.Title or "Eclipse"
	local desc     = opts.Description or ""
	local duration = opts.Duration or 4
	local ntype    = opts.Type or "info"

	ensureNotif()

	local col = Theme.Accent
	if ntype == "success" then col = Theme.Green
	elseif ntype == "warning" then col = Theme.Yellow
	elseif ntype == "error" then col = Theme.Red end

	local card = New("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		Parent = notifHolder,
	})
	Corner(card, 10)
	Stroke(card, col, 1, 0.6)

	New("Frame", {
		BackgroundColor3 = col,
		Size = UDim2.new(0, 3, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = card,
	})

	local inner = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Padding(inner, 10, 10, 10, 2)
	List(inner, Enum.FillDirection.Vertical, 3)

	New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		ZIndex = 3,
		Parent = inner,
	})

	if desc ~= "" then
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = desc,
			TextColor3 = Theme.TextSub,
			TextSize = 11,
			Font = Theme.Font,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 1,
			ZIndex = 3,
			Parent = inner,
		})
	end

	local bar = New("Frame", {
		BackgroundColor3 = col,
		BackgroundTransparency = 0.4,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = card,
	})

	card.Position = UDim2.new(1, 20, 0, 0)
	Tween(card, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		Tween(card, { Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1 }, 0.25)
		task.wait(0.28)
		card:Destroy()
	end)
end

local Window = {}
Window.__index = Window

function EclipseLib:CreateWindow(opts)
	opts = opts or {}
	local self      = setmetatable({}, Window)
	self.Title      = opts.Title or "Eclipse"
	self.Sub        = opts.Subtitle or "Hub"
	self.WSize      = opts.Size or Vector2.new(600, 460)
	self.Keybind    = opts.Keybind or Enum.KeyCode.RightShift
	self.Logo       = opts.Logo
	self.Tabs       = {}
	self.ActiveTab  = nil
	self.Open       = true
	self.Minimized  = false

	if opts.Theme then
		for k, v in pairs(opts.Theme) do Theme[k] = v end
	end

	self.Gui = getGui()

	local startPos = opts.Position
		and UDim2.new(0, opts.Position.X, 0, opts.Position.Y)
		or UDim2.new(0.5, -self.WSize.X / 2, 0.5, -self.WSize.Y / 2)

	self.Root = New("Frame", {
		Name = "EclipseWindow",
		BackgroundColor3 = Theme.Background,
		Size = UDim2.new(0, self.WSize.X, 0, 0),
		Position = startPos,
		BackgroundTransparency = 1,
		ZIndex = ZBase,
		ClipsDescendants = false,
		Parent = self.Gui,
	})
	Corner(self.Root, 14)
	Stroke(self.Root, Theme.BorderLight, 1, 0.89)

	local glow = New("Frame", {
		BackgroundColor3 = Theme.AccentGlow,
		BackgroundTransparency = 0.92,
		Size = UDim2.new(1, 50, 0, 80),
		Position = UDim2.new(0, -25, 0, -25),
		ZIndex = ZBase - 1,
		BorderSizePixel = 0,
		Parent = self.Root,
	})
	Corner(glow, 30)

	self.TopBar = New("Frame", {
		Name = "TopBar",
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 52),
		ZIndex = ZBase + 1,
		ClipsDescendants = true,
		Parent = self.Root,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 14), Parent = self.TopBar })
	New("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		BorderSizePixel = 0,
		ZIndex = ZBase + 1,
		Parent = self.TopBar,
	})

	local accentLine = New("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -1),
		BorderSizePixel = 0,
		ZIndex = ZBase + 3,
		Parent = self.TopBar,
	})
	Gradient(accentLine, { Theme.AccentLight, Theme.Accent, Theme.AccentDark })
	task.delay(0.05, function()
		Tween(accentLine, { Size = UDim2.new(1, 0, 0, 2) }, 0.7, Enum.EasingStyle.Quint)
	end)

	local logoHolder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(0, 12, 0.5, -16),
		ZIndex = ZBase + 2,
		Parent = self.TopBar,
	})

	if self.Logo then
		New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = "rbxassetid://" .. tostring(self.Logo),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = ZBase + 3,
			Parent = logoHolder,
		})
	else
		local logoBg = New("Frame", {
			BackgroundColor3 = Theme.Accent,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = ZBase + 2,
			BorderSizePixel = 0,
			Parent = logoHolder,
		})
		Corner(logoBg, 9)
		Gradient(logoBg, { Theme.AccentLight, Theme.AccentDark }, 135)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = string.upper(string.sub(self.Title, 1, 1)),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 15,
			Font = Theme.FontBold,
			ZIndex = ZBase + 3,
			Parent = logoBg,
		})
	end

	local titleBlock = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -190, 0, 34),
		Position = UDim2.new(0, 54, 0.5, -17),
		ZIndex = ZBase + 2,
		Parent = self.TopBar,
	})
	List(titleBlock, Enum.FillDirection.Vertical, 1)

	self._titleLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 19),
		Text = self.Title,
		TextColor3 = Theme.Text,
		TextSize = 15,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		ZIndex = ZBase + 3,
		Parent = titleBlock,
	})

	self._subLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 13),
		Text = self.Sub,
		TextColor3 = Theme.TextDim,
		TextSize = 11,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		ZIndex = ZBase + 3,
		Parent = titleBlock,
	})

	local ctrlFrame = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 62, 0, 26),
		Position = UDim2.new(1, -74, 0.5, -13),
		ZIndex = ZBase + 2,
		Parent = self.TopBar,
	})
	List(ctrlFrame, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right)

	local function ctrlBtn(txt, col)
		local b = New("TextButton", {
			BackgroundColor3 = Theme.SurfaceAlt,
			Size = UDim2.new(0, 26, 0, 26),
			Text = txt,
			TextColor3 = col or Theme.TextDim,
			TextSize = 13,
			Font = Theme.FontBold,
			BorderSizePixel = 0,
			ZIndex = ZBase + 3,
			Parent = ctrlFrame,
		})
		Corner(b, 7)
		b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme.SurfaceBright }, 0.1) end)
		b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.SurfaceAlt }, 0.1) end)
		return b
	end

	local minBtn   = ctrlBtn("-", Theme.Yellow)
	local closeBtn = ctrlBtn("x", Theme.Red)

	closeBtn.MouseButton1Click:Connect(function()
		Tween(self.Root, { BackgroundTransparency = 1, Size = UDim2.new(0, self.WSize.X, 0, 0) }, 0.28, Enum.EasingStyle.Quint)
		task.wait(0.3)
		self.Gui:Destroy()
	end)

	minBtn.MouseButton1Click:Connect(function()
		self.Minimized = not self.Minimized
		if self.Minimized then
			Tween(self.Root, { Size = UDim2.new(0, self.WSize.X, 0, 52) }, 0.28, Enum.EasingStyle.Quint)
		else
			Tween(self.Root, { Size = UDim2.new(0, self.WSize.X, 0, self.WSize.Y) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end)

	Draggable(self.Root, self.TopBar)

	self.Sidebar = New("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0, 148, 1, -52),
		Position = UDim2.new(0, 0, 0, 52),
		ZIndex = ZBase + 1,
		ClipsDescendants = false,
		Parent = self.Root,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 14), Parent = self.Sidebar })
	New("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = ZBase + 1,
		Parent = self.Sidebar,
	})
	New("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = ZBase + 1,
		Parent = self.Sidebar,
	})

	self.TabScroll = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -14),
		Position = UDim2.new(0, 0, 0, 10),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = ZBase + 2,
		Parent = self.Sidebar,
	})
	Padding(self.TabScroll, 4, 8, 4, 8)
	List(self.TabScroll, Enum.FillDirection.Vertical, 3)

	New("Frame", {
		BackgroundColor3 = Theme.BorderDark,
		Size = UDim2.new(0, 1, 1, -52),
		Position = UDim2.new(0, 148, 0, 52),
		BorderSizePixel = 0,
		ZIndex = ZBase + 1,
		Parent = self.Root,
	})

	self.Content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -156, 1, -60),
		Position = UDim2.new(0, 156, 0, 58),
		ClipsDescendants = true,
		ZIndex = ZBase + 1,
		Parent = self.Root,
	})

	Tween(self.Root, {
		BackgroundTransparency = 0,
		Size = UDim2.new(0, self.WSize.X, 0, self.WSize.Y),
	}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	UserInputService.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.KeyCode == self.Keybind then
			self.Open = not self.Open
			self.Root.Visible = self.Open
		end
	end)

	return self
end

function Window:SelectTab(name)
	for _, t in ipairs(self.Tabs) do
		if t.Name == name then t._activate() end
	end
end

function Window:SetBadge(tabName, text, color)
	for _, t in ipairs(self.Tabs) do
		if t.Name == tabName then
			local old = t._btn:FindFirstChild("Badge")
			if old then old:Destroy() end
			if not text then return end
			local b = New("Frame", {
				Name = "Badge",
				BackgroundColor3 = color or Theme.Red,
				Size = UDim2.new(0, 16, 0, 14),
				Position = UDim2.new(1, -20, 0.5, -7),
				BorderSizePixel = 0,
				ZIndex = ZBase + 5,
				Parent = t._btn,
			})
			Corner(b, 999)
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = tostring(text),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 8,
				Font = Theme.FontBold,
				ZIndex = ZBase + 6,
				Parent = b,
			})
			return
		end
	end
end

function Window:SetTitle(title, sub)
	if title and self._titleLabel then self._titleLabel.Text = title end
	if sub and self._subLabel then self._subLabel.Text = sub end
end

function Window:CreateTab(opts)
	opts = opts or {}
	local tabData = {
		Name = opts.Name or "Tab",
	}

	local btn = New("TextButton", {
		BackgroundColor3 = Theme.SurfaceAlt,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		BorderSizePixel = 0,
		ZIndex = ZBase + 3,
		Parent = self.TabScroll,
	})
	Corner(btn, 8)
	tabData._btn = btn

	local indicator = New("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 3, 0, 14),
		Position = UDim2.new(0, 0, 0.5, -7),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = ZBase + 4,
		Parent = btn,
	})
	Corner(indicator, 999)

	local tabLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -22, 1, 0),
		Position = UDim2.new(0, 13, 0, 0),
		Text = tabData.Name,
		TextColor3 = Theme.TextDim,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = ZBase + 4,
		Parent = btn,
	})

	local page = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.ScrollBar,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = ZBase + 2,
		Visible = false,
		Parent = self.Content,
	})
	Padding(page, 4, 10, 14, 4)
	List(page, Enum.FillDirection.Vertical, 7)
	tabData._page = page

	local function deactivate()
		Tween(btn, { BackgroundTransparency = 1 }, 0.15)
		Tween(indicator, { BackgroundTransparency = 1 }, 0.15)
		Tween(tabLabel, { TextColor3 = Theme.TextDim }, 0.15)
		tabLabel.Font = Theme.Font
		page.Visible = false
	end

	local function activate()
		if self.ActiveTab and self.ActiveTab ~= tabData then
			self.ActiveTab._deactivate()
		end
		self.ActiveTab = tabData
		Tween(btn, { BackgroundTransparency = 0.88 }, 0.15)
		Tween(indicator, { BackgroundTransparency = 0 }, 0.15)
		Tween(tabLabel, { TextColor3 = Theme.Text }, 0.15)
		tabLabel.Font = Theme.FontSemi
		page.Visible = true
		page.Position = UDim2.new(0.025, 0, 0, 0)
		Tween(page, { Position = UDim2.new(0, 0, 0, 0) }, 0.16, Enum.EasingStyle.Quint)
	end

	tabData._activate   = activate
	tabData._deactivate = deactivate

	btn.MouseButton1Click:Connect(activate)
	btn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabData then
			Tween(btn, { BackgroundTransparency = 0.94 }, 0.1)
			Tween(tabLabel, { TextColor3 = Theme.TextSub }, 0.1)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabData then
			Tween(btn, { BackgroundTransparency = 1 }, 0.1)
			Tween(tabLabel, { TextColor3 = Theme.TextDim }, 0.1)
		end
	end)

	if #self.Tabs == 0 then activate() end
	table.insert(self.Tabs, tabData)

	local Tab = setmetatable({}, { __index = tabData })

	local function makeSection(sOpts)
		sOpts = sOpts or {}
		local name = sOpts.Name or ""

		local section = New("Frame", {
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = ZBase + 3,
			Parent = page,
		})
		Corner(section, 10)
		Stroke(section, Theme.BorderLight, 1, 0.91)

		local sInner = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = ZBase + 3,
			Parent = section,
		})
		Padding(sInner, name ~= "" and 38 or 8, 10, 10, 10)
		List(sInner, Enum.FillDirection.Vertical, 5)

		if name ~= "" then
			local header = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 28),
				Position = UDim2.new(0, 10, 0, 6),
				ZIndex = ZBase + 4,
				Parent = section,
			})
			New("Frame", {
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 0.45,
				Size = UDim2.new(0, 3, 0, 14),
				Position = UDim2.new(0, 0, 0.5, -7),
				BorderSizePixel = 0,
				ZIndex = ZBase + 5,
				Parent = header,
			})
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -12, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				Text = name,
				TextColor3 = Theme.TextSub,
				TextSize = 12,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = ZBase + 5,
				Parent = header,
			})
			New("Frame", {
				BackgroundColor3 = Theme.BorderDark,
				Size = UDim2.new(1, -20, 0, 1),
				Position = UDim2.new(0, 10, 0, 28),
				BorderSizePixel = 0,
				ZIndex = ZBase + 4,
				Parent = section,
			})
		end

		local S = {}
		local order = 0
		local Z = ZBase + 4

		local function nextOrd()
			order = order + 1
			return order
		end

		local function makeRipple(btn2)
			local r = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.82,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0, Mouse.X - btn2.AbsolutePosition.X, 0, Mouse.Y - btn2.AbsolutePosition.Y),
				ZIndex = btn2.ZIndex + 5,
				Parent = btn2,
			})
			Corner(r, 999)
			Tween(r, { Size = UDim2.new(0, 220, 0, 220), BackgroundTransparency = 1 }, 0.42, Enum.EasingStyle.Quart)
			task.delay(0.44, function() r:Destroy() end)
		end

		function S:Button(o)
			o = o or {}
			local lbl  = o.Name or o.Title or "Button"
			local desc = o.Description
			local cb   = o.Callback or function() end
			local h    = desc and 54 or 36

			local row = New("TextButton", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, h),
				Text = "",
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				ClipsDescendants = true,
				Parent = sInner,
			})
			Corner(row, 8)
			Stroke(row, Theme.BorderLight, 1, 0.93)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -44, 0, 16),
				Position = UDim2.new(0, 12, 0, desc and 9 or 10),
				Text = lbl,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 1,
				Parent = row,
			})

			if desc then
				New("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -44, 0, 13),
					Position = UDim2.new(0, 12, 0, 28),
					Text = desc,
					TextColor3 = Theme.TextDim,
					TextSize = 11,
					Font = Theme.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					ZIndex = Z + 1,
					Parent = row,
				})
			end

			local chev = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 28, 1, 0),
				Position = UDim2.new(1, -34, 0, 0),
				Text = ">",
				TextColor3 = Theme.TextDim,
				TextSize = 13,
				Font = Theme.FontBold,
				ZIndex = Z + 1,
				Parent = row,
			})

			row.MouseEnter:Connect(function()
				Tween(row, { BackgroundColor3 = Theme.SurfaceHover }, 0.1)
				Tween(chev, { TextColor3 = Theme.AccentLight }, 0.1)
			end)
			row.MouseLeave:Connect(function()
				Tween(row, { BackgroundColor3 = Theme.SurfaceAlt }, 0.1)
				Tween(chev, { TextColor3 = Theme.TextDim }, 0.1)
			end)
			row.MouseButton1Down:Connect(function()
				Tween(row, { BackgroundColor3 = Theme.SurfaceBright }, 0.06)
			end)
			row.MouseButton1Up:Connect(function()
				Tween(row, { BackgroundColor3 = Theme.SurfaceHover }, 0.06)
			end)
			row.MouseButton1Click:Connect(function()
				makeRipple(row)
				task.spawn(cb)
			end)

			local obj = {}
			function obj:Fire() task.spawn(cb) end
			return obj
		end

		function S:Toggle(o)
			o = o or {}
			local lbl  = o.Name or o.Title or "Toggle"
			local desc = o.Description
			local val  = o.Default ~= nil and o.Default or false
			local cb   = o.Callback or function() end
			local h    = desc and 54 or 36

			local row = New("TextButton", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, h),
				Text = "",
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				ClipsDescendants = false,
				Parent = sInner,
			})
			Corner(row, 8)
			Stroke(row, Theme.BorderLight, 1, 0.93)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -58, 0, 16),
				Position = UDim2.new(0, 12, 0, desc and 9 or 10),
				Text = lbl,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 1,
				Parent = row,
			})

			if desc then
				New("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -58, 0, 13),
					Position = UDim2.new(0, 12, 0, 28),
					Text = desc,
					TextColor3 = Theme.TextDim,
					TextSize = 11,
					Font = Theme.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					ZIndex = Z + 1,
					Parent = row,
				})
			end

			local track = New("Frame", {
				BackgroundColor3 = val and Theme.Accent or Theme.SurfaceBright,
				Size = UDim2.new(0, 38, 0, 20),
				Position = UDim2.new(1, -50, 0.5, -10),
				BorderSizePixel = 0,
				ZIndex = Z + 1,
				Parent = row,
			})
			Corner(track, 999)
			Stroke(track, Theme.BorderLight, 1, 0.82)

			local knob = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(0, 14, 0, 14),
				Position = val and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
				BorderSizePixel = 0,
				ZIndex = Z + 2,
				Parent = track,
			})
			Corner(knob, 999)

			local function set(v, silent)
				val = v
				Tween(track, { BackgroundColor3 = v and Theme.Accent or Theme.SurfaceBright }, 0.16)
				Tween(knob, { Position = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) }, 0.16, Enum.EasingStyle.Back)
				if not silent then task.spawn(cb, v) end
			end

			row.MouseButton1Click:Connect(function() set(not val) end)
			row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.SurfaceHover }, 0.1) end)
			row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.SurfaceAlt }, 0.1) end)

			local obj = {}
			function obj:Set(v) set(v) end
			function obj:Get() return val end
			return obj
		end

		function S:Slider(o)
			o = o or {}
			local lbl = o.Name or o.Title or "Slider"
			local min = o.Min or 0
			local max = o.Max or 100
			local inc = o.Increment or 1
			local suf = o.Suffix or ""
			local val = clamp(o.Default or min, min, max)
			local cb  = o.Callback or function() end

			val = math.floor(val / inc + 0.5) * inc

			local frame = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 54),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			Corner(frame, 8)
			Stroke(frame, Theme.BorderLight, 1, 0.93)
			Padding(frame, 9, 12, 9, 12)

			local topRow = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = Z + 1,
				Parent = frame,
			})
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.65, 0, 1, 0),
				Text = lbl,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 2,
				Parent = topRow,
			})
			local vLabel = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.35, 0, 1, 0),
				Position = UDim2.new(0.65, 0, 0, 0),
				Text = tostring(val) .. suf,
				TextColor3 = Theme.AccentLight,
				TextSize = 13,
				Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = Z + 2,
				Parent = topRow,
			})

			local trackBg = New("Frame", {
				BackgroundColor3 = Theme.SurfaceBright,
				Size = UDim2.new(1, 0, 0, 5),
				Position = UDim2.new(0, 0, 0, 32),
				BorderSizePixel = 0,
				ZIndex = Z + 1,
				Parent = frame,
			})
			Corner(trackBg, 999)

			local fill = New("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = Z + 2,
				Parent = trackBg,
			})
			Corner(fill, 999)
			Gradient(fill, { Theme.AccentLight, Theme.Accent })

			local handle = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(0, 14, 0, 14),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0),
				BorderSizePixel = 0,
				ZIndex = Z + 3,
				Parent = trackBg,
			})
			Corner(handle, 999)
			Stroke(handle, Theme.Accent, 2, 0.1)

			local sliding = false

			local function updateFromX(mx)
				local frac = clamp((mx - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
				val = math.floor((min + frac * (max - min)) / inc + 0.5) * inc
				val = clamp(val, min, max)
				local f2 = (val - min) / (max - min)
				fill.Size = UDim2.new(f2, 0, 1, 0)
				handle.Position = UDim2.new(f2, 0, 0.5, 0)
				local disp = inc < 1 and math.floor(val * 100 + 0.5) / 100 or math.floor(val)
				vLabel.Text = tostring(disp) .. suf
				task.spawn(cb, val)
			end

			trackBg.InputBegan:Connect(function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				sliding = true
				updateFromX(i.Position.X)
			end)
			handle.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
			end)
			UserInputService.InputChanged:Connect(function(i)
				if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
					updateFromX(i.Position.X)
				end
			end)
			handle.MouseEnter:Connect(function() Tween(handle, { Size = UDim2.new(0, 17, 0, 17) }, 0.1) end)
			handle.MouseLeave:Connect(function() Tween(handle, { Size = UDim2.new(0, 14, 0, 14) }, 0.1) end)

			local obj = {}
			function obj:Set(v)
				val = clamp(math.floor(v / inc + 0.5) * inc, min, max)
				local f = (val - min) / (max - min)
				Tween(fill, { Size = UDim2.new(f, 0, 1, 0) }, 0.15)
				handle.Position = UDim2.new(f, 0, 0.5, 0)
				vLabel.Text = tostring(val) .. suf
			end
			function obj:Get() return val end
			return obj
		end

		function S:Input(o)
			o = o or {}
			local lbl   = o.Name or o.Title or "Input"
			local ph    = o.Placeholder or "Type here..."
			local def   = o.Default or ""
			local multi = o.MultiLine or false
			local num   = o.Numeric or false
			local cb    = o.Callback or function() end
			local h     = multi and 80 or 52

			local frame = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, h),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			Corner(frame, 8)
			local stroke = Stroke(frame, Theme.BorderLight, 1, 0.91)
			Padding(frame, 7, 10, 7, 10)
			List(frame, Enum.FillDirection.Vertical, 3)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 13),
				Text = lbl,
				TextColor3 = Theme.TextDim,
				TextSize = 11,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 0,
				ZIndex = Z + 1,
				Parent = frame,
			})

			local box = New("TextBox", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, multi and 44 or 20),
				Text = def,
				PlaceholderText = ph,
				PlaceholderColor3 = Theme.TextDim,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				MultiLine = multi,
				TextWrapped = multi,
				LayoutOrder = 1,
				ZIndex = Z + 1,
				Parent = frame,
			})

			box.Focused:Connect(function()
				Tween(stroke, { Color = Theme.Accent, Transparency = 0.4 }, 0.14)
				Tween(frame, { BackgroundColor3 = Theme.SurfaceHover }, 0.14)
			end)
			box.FocusLost:Connect(function()
				Tween(stroke, { Color = Theme.BorderLight, Transparency = 0.91 }, 0.14)
				Tween(frame, { BackgroundColor3 = Theme.SurfaceAlt }, 0.14)
				task.spawn(cb, box.Text)
			end)

			if num then
				box:GetPropertyChangedSignal("Text"):Connect(function()
					local f = box.Text:gsub("[^%d%.-]", "")
					if f ~= box.Text then box.Text = f end
				end)
			end

			local obj = {}
			function obj:Set(v) box.Text = tostring(v) end
			function obj:Get() return box.Text end
			return obj
		end

		function S:Dropdown(o)
			o = o or {}
			local lbl   = o.Name or o.Title or "Dropdown"
			local opts3 = o.Options or {}
			local multi = o.MultiSelect or false
			local cb    = o.Callback or function() end
			local sel   = o.Default or (not multi and opts3[1]) or {}
			if multi and type(sel) ~= "table" then sel = {} end

			local open = false

			local frame = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 40),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				ClipsDescendants = false,
				Parent = sInner,
			})
			Corner(frame, 8)
			Stroke(frame, Theme.BorderLight, 1, 0.91)

			local header = New("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				BorderSizePixel = 0,
				ZIndex = Z + 1,
				Parent = frame,
			})

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.52, 0, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Text = lbl,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 2,
				Parent = header,
			})

			local valLabel = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.36, 0, 1, 0),
				Position = UDim2.new(0.4, 0, 0, 0),
				Text = multi and "None" or tostring(sel or ""),
				TextColor3 = Theme.AccentLight,
				TextSize = 12,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = Z + 2,
				Parent = header,
			})

			local arrow = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 20, 1, 0),
				Position = UDim2.new(1, -26, 0, 0),
				Text = "v",
				TextColor3 = Theme.TextDim,
				TextSize = 11,
				Font = Theme.FontBold,
				ZIndex = Z + 2,
				Parent = header,
			})

			local dropdown = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 1, 5),
				ClipsDescendants = true,
				BorderSizePixel = 0,
				ZIndex = Z + 12,
				Visible = false,
				Parent = frame,
			})
			Corner(dropdown, 8)
			Stroke(dropdown, Theme.Accent, 1, 0.6)

			local ddScroll = New("ScrollingFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.ScrollBar,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ZIndex = Z + 13,
				Parent = dropdown,
			})
			Padding(ddScroll, 4, 6, 4, 6)
			List(ddScroll, Enum.FillDirection.Vertical, 2)

			local function refreshDD()
				for _, c in ipairs(ddScroll:GetChildren()) do
					if c:IsA("TextButton") then c:Destroy() end
				end
				for _, opt in ipairs(opts3) do
					local isActive = multi and table.find(sel, opt) ~= nil or sel == opt
					local ob = New("TextButton", {
						BackgroundColor3 = isActive and Theme.AccentDark or Theme.Surface,
						Size = UDim2.new(1, 0, 0, 28),
						Text = "",
						BorderSizePixel = 0,
						ZIndex = Z + 14,
						Parent = ddScroll,
					})
					Corner(ob, 6)
					New("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -14, 1, 0),
						Position = UDim2.new(0, 10, 0, 0),
						Text = tostring(opt),
						TextColor3 = isActive and Theme.Text or Theme.TextSub,
						TextSize = 12,
						Font = isActive and Theme.FontSemi or Theme.Font,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = Z + 15,
						Parent = ob,
					})
					ob.MouseEnter:Connect(function()
						if not isActive then Tween(ob, { BackgroundColor3 = Theme.SurfaceHover }, 0.08) end
					end)
					ob.MouseLeave:Connect(function()
						if not isActive then Tween(ob, { BackgroundColor3 = Theme.Surface }, 0.08) end
					end)
					ob.MouseButton1Click:Connect(function()
						if multi then
							local idx = table.find(sel, opt)
							if idx then table.remove(sel, idx) else table.insert(sel, opt) end
							valLabel.Text = #sel > 0 and table.concat(sel, ", ") or "None"
							task.spawn(cb, sel)
						else
							sel = opt
							valLabel.Text = tostring(sel)
							task.spawn(cb, sel)
							header.MouseButton1Click:Fire()
						end
						refreshDD()
					end)
				end
				local targetH = math.min(#opts3 * 30 + 8, 160)
				Tween(dropdown, { Size = UDim2.new(1, 0, 0, targetH) }, 0.2, Enum.EasingStyle.Back)
			end

			header.MouseButton1Click:Connect(function()
				open = not open
				if open then
					dropdown.Visible = true
					dropdown.Size = UDim2.new(1, 0, 0, 0)
					refreshDD()
					Tween(arrow, { Rotation = 180 }, 0.2)
				else
					Tween(dropdown, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
					Tween(arrow, { Rotation = 0 }, 0.2)
					task.wait(0.17)
					dropdown.Visible = false
				end
			end)
			header.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.SurfaceHover }, 0.1) end)
			header.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.SurfaceAlt }, 0.1) end)

			local obj = {}
			function obj:Set(v)
				sel = v
				valLabel.Text = type(v) == "table" and table.concat(v, ", ") or tostring(v)
			end
			function obj:Get() return sel end
			function obj:Refresh(newOpts)
				opts3 = newOpts
				if not multi then sel = newOpts[1] end
				if open then refreshDD() end
			end
			return obj
		end

		function S:ColorPicker(o)
			o = o or {}
			local lbl = o.Name or o.Title or "Color"
			local def = o.Default or Color3.fromRGB(100, 85, 240)
			local cb  = o.Callback or function() end

			local ch, cs, cv = toHSV(def)
			local open = false

			local frame = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 40),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				ClipsDescendants = false,
				Parent = sInner,
			})
			Corner(frame, 8)
			Stroke(frame, Theme.BorderLight, 1, 0.91)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.6, 0, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Text = lbl,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 1,
				Parent = frame,
			})

			local preview = New("TextButton", {
				BackgroundColor3 = def,
				Size = UDim2.new(0, 56, 0, 24),
				Position = UDim2.new(1, -68, 0.5, -12),
				Text = "",
				BorderSizePixel = 0,
				ZIndex = Z + 1,
				Parent = frame,
			})
			Corner(preview, 7)
			Stroke(preview, Theme.BorderLight, 1, 0.74)

			local picker = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 1, 5),
				Visible = false,
				ClipsDescendants = false,
				ZIndex = Z + 10,
				Parent = frame,
			})
			Corner(picker, 10)
			Stroke(picker, Theme.Accent, 1, 0.6)
			Padding(picker, 10, 10, 10, 10)
			List(picker, Enum.FillDirection.Vertical, 8)

			local svBox = New("ImageLabel", {
				Size = UDim2.new(1, 0, 0, 130),
				BackgroundColor3 = HSV(ch, 1, 1),
				Image = "rbxassetid://6020299385",
				LayoutOrder = 0,
				ZIndex = Z + 11,
				Parent = picker,
			})
			Corner(svBox, 7)

			local svDot = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(0, 12, 0, 12),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(cs, 0, 1 - cv, 0),
				BorderSizePixel = 0,
				ZIndex = Z + 12,
				Parent = svBox,
			})
			Corner(svDot, 999)
			Stroke(svDot, Color3.new(0, 0, 0), 2, 0)

			local hueBar = New("Frame", {
				Size = UDim2.new(1, 0, 0, 11),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				ZIndex = Z + 11,
				Parent = picker,
			})
			Corner(hueBar, 999)
			Gradient(hueBar, {
				Color3.fromHSV(0, 1, 1), Color3.fromHSV(0.17, 1, 1), Color3.fromHSV(0.33, 1, 1),
				Color3.fromHSV(0.5, 1, 1), Color3.fromHSV(0.67, 1, 1), Color3.fromHSV(0.83, 1, 1), Color3.fromHSV(1, 1, 1),
			})

			local hKnob = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(0, 12, 0, 17),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(ch, 0, 0.5, 0),
				BorderSizePixel = 0,
				ZIndex = Z + 12,
				Parent = hueBar,
			})
			Corner(hKnob, 4)
			Stroke(hKnob, Color3.new(0, 0, 0), 2, 0)

			local hexRow = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = 2,
				ZIndex = Z + 11,
				Parent = picker,
			})

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 28, 1, 0),
				Text = "HEX",
				TextColor3 = Theme.TextDim,
				TextSize = 10,
				Font = Theme.FontBold,
				ZIndex = Z + 12,
				Parent = hexRow,
			})

			local hexBox = New("TextBox", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, -32, 1, 0),
				Position = UDim2.new(0, 32, 0, 0),
				Text = "#" .. string.format("%02X%02X%02X", math.floor(def.R * 255), math.floor(def.G * 255), math.floor(def.B * 255)),
				TextColor3 = Theme.Text,
				TextSize = 12,
				Font = Theme.Font,
				ClearTextOnFocus = false,
				ZIndex = Z + 12,
				Parent = hexRow,
			})
			Corner(hexBox, 6)
			Stroke(hexBox, Theme.BorderLight, 1, 0.85)

			local function updateColor()
				local col = HSV(ch, cs, cv)
				preview.BackgroundColor3 = col
				svBox.BackgroundColor3   = HSV(ch, 1, 1)
				svDot.Position           = UDim2.new(cs, 0, 1 - cv, 0)
				hKnob.Position           = UDim2.new(ch, 0, 0.5, 0)
				hexBox.Text              = "#" .. string.format("%02X%02X%02X", math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255))
				task.spawn(cb, col)
			end

			local svDrag, hDrag = false, false

			svBox.InputBegan:Connect(function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				svDrag = true
				local rel = i.Position - svBox.AbsolutePosition
				cs = clamp(rel.X / svBox.AbsoluteSize.X, 0, 1)
				cv = clamp(1 - rel.Y / svBox.AbsoluteSize.Y, 0, 1)
				updateColor()
			end)
			hueBar.InputBegan:Connect(function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				hDrag = true
				ch = clamp((i.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				updateColor()
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					svDrag = false
					hDrag  = false
				end
			end)
			UserInputService.InputChanged:Connect(function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				if svDrag then
					local rel = i.Position - svBox.AbsolutePosition
					cs = clamp(rel.X / svBox.AbsoluteSize.X, 0, 1)
					cv = clamp(1 - rel.Y / svBox.AbsoluteSize.Y, 0, 1)
					updateColor()
				elseif hDrag then
					ch = clamp((i.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
					updateColor()
				end
			end)

			hexBox.FocusLost:Connect(function()
				local hex = hexBox.Text:gsub("#", "")
				if #hex == 6 then
					local r2 = tonumber(hex:sub(1, 2), 16) or 255
					local g2 = tonumber(hex:sub(3, 4), 16) or 255
					local b2 = tonumber(hex:sub(5, 6), 16) or 255
					ch, cs, cv = toHSV(Color3.fromRGB(r2, g2, b2))
					updateColor()
				end
			end)

			preview.MouseButton1Click:Connect(function()
				open = not open
				picker.Visible = true
				if open then
					picker.Size = UDim2.new(1, 0, 0, 0)
					Tween(picker, { Size = UDim2.new(1, 0, 0, 210) }, 0.28, Enum.EasingStyle.Back)
				else
					Tween(picker, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
					task.wait(0.22)
					picker.Visible = false
				end
			end)

			local obj = {}
			function obj:Set(col)
				ch, cs, cv = toHSV(col)
				updateColor()
			end
			function obj:Get() return HSV(ch, cs, cv) end
			return obj
		end

		function S:Keybind(o)
			o = o or {}
			local lbl    = o.Name or o.Title or "Keybind"
			local def    = o.Default or Enum.KeyCode.Unknown
			local mode   = o.Mode or "Toggle"
			local cb     = o.Callback or function() end
			local bound  = def
			local listen = false
			local active = false

			local row = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 36),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			Corner(row, 8)
			Stroke(row, Theme.BorderLight, 1, 0.91)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.55, 0, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Text = lbl,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 1,
				Parent = row,
			})

			local kbtn = New("TextButton", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(0, 86, 0, 22),
				Position = UDim2.new(1, -98, 0.5, -11),
				Text = bound.Name,
				TextColor3 = Theme.AccentLight,
				TextSize = 11,
				Font = Theme.FontBold,
				BorderSizePixel = 0,
				ZIndex = Z + 1,
				Parent = row,
			})
			Corner(kbtn, 6)
			Stroke(kbtn, Theme.Accent, 1, 0.65)

			kbtn.MouseButton1Click:Connect(function()
				listen = true
				kbtn.Text = "..."
				Tween(kbtn, { BackgroundColor3 = Theme.AccentDark }, 0.1)
			end)
			kbtn.MouseEnter:Connect(function() Tween(kbtn, { BackgroundColor3 = Theme.SurfaceHover }, 0.1) end)
			kbtn.MouseLeave:Connect(function() Tween(kbtn, { BackgroundColor3 = listen and Theme.AccentDark or Theme.Surface }, 0.1) end)

			UserInputService.InputBegan:Connect(function(i, gp)
				if listen and i.UserInputType == Enum.UserInputType.Keyboard then
					bound = i.KeyCode
					kbtn.Text = bound.Name
					listen = false
					Tween(kbtn, { BackgroundColor3 = Theme.Surface }, 0.1)
					return
				end
				if gp or listen or i.KeyCode ~= bound then return end
				if mode == "Toggle" then
					active = not active
					task.spawn(cb, active)
				elseif mode == "Hold" then
					task.spawn(cb, true)
				end
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.KeyCode == bound and mode == "Hold" then
					task.spawn(cb, false)
				end
			end)

			local obj = {}
			function obj:Set(k) bound = k; kbtn.Text = k.Name end
			function obj:Get() return bound end
			return obj
		end

		function S:Label(o)
			o = type(o) == "string" and { Text = o } or o
			local lab = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = o.Text or "",
				TextColor3 = o.Color or Theme.TextSub,
				TextSize = o.Size or 12,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			local obj = {}
			function obj:Set(t) lab.Text = t end
			function obj:SetColor(c) lab.TextColor3 = c end
			return obj
		end

		function S:Paragraph(o)
			o = type(o) == "string" and { Title = o } or o
			local title   = o.Title or ""
			local content = o.Content or o.Text or ""

			local pFrame = New("Frame", {
				BackgroundColor3 = Theme.Surface,
				BackgroundTransparency = 0.35,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			Corner(pFrame, 8)
			Stroke(pFrame, Theme.BorderLight, 1, 0.93)
			Padding(pFrame, 10, 12, 10, 12)
			List(pFrame, Enum.FillDirection.Vertical, 4)

			local tLabel, cLabel

			if title ~= "" then
				tLabel = New("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Text = title,
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Theme.FontBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					LayoutOrder = 0,
					ZIndex = Z + 1,
					Parent = pFrame,
				})
			end

			cLabel = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = content,
				TextColor3 = Theme.TextSub,
				TextSize = 12,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = 1,
				ZIndex = Z + 1,
				Parent = pFrame,
			})

			local obj = {}
			function obj:SetTitle(t) if tLabel then tLabel.Text = t end end
			function obj:SetContent(c) cLabel.Text = c end
			return obj
		end

		function S:Divider()
			return New("Frame", {
				BackgroundColor3 = Theme.BorderDark,
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
		end

		function S:ProgressBar(o)
			o = o or {}
			local lbl  = o.Name or o.Title or "Progress"
			local max2 = o.Max or 100
			local val  = clamp(o.Default or 0, 0, max2)
			local suf  = o.Suffix or "%"

			local frame = New("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 46),
				BorderSizePixel = 0,
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			Corner(frame, 8)
			Stroke(frame, Theme.BorderLight, 1, 0.91)
			Padding(frame, 8, 12, 8, 12)

			local top = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				ZIndex = Z + 1,
				Parent = frame,
			})
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.6, 0, 1, 0),
				Text = lbl,
				TextColor3 = Theme.TextSub,
				TextSize = 12,
				Font = Theme.FontSemi,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = Z + 2,
				Parent = top,
			})
			local vl = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.4, 0, 1, 0),
				Position = UDim2.new(0.6, 0, 0, 0),
				Text = tostring(math.floor(val)) .. suf,
				TextColor3 = Theme.AccentLight,
				TextSize = 12,
				Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = Z + 2,
				Parent = top,
			})
			local track = New("Frame", {
				BackgroundColor3 = Theme.SurfaceBright,
				Size = UDim2.new(1, 0, 0, 5),
				Position = UDim2.new(0, 0, 0, 24),
				BorderSizePixel = 0,
				ZIndex = Z + 1,
				Parent = frame,
			})
			Corner(track, 999)
			local fill = New("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new(val / max2, 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = Z + 2,
				Parent = track,
			})
			Corner(fill, 999)
			Gradient(fill, { Theme.AccentLight, Theme.Accent })

			local obj = {}
			function obj:Set(v)
				v = clamp(v, 0, max2)
				Tween(fill, { Size = UDim2.new(v / max2, 0, 1, 0) }, 0.3)
				vl.Text = tostring(math.floor(v)) .. suf
			end
			function obj:Get() return val end
			return obj
		end

		function S:Image(o)
			o = o or {}
			local id = tostring(o.Image or o.Id or "")
			local h  = o.Height or 80

			local wrapper = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, h),
				LayoutOrder = nextOrd(),
				ZIndex = Z,
				Parent = sInner,
			})
			local img = New("ImageLabel", {
				BackgroundColor3 = Theme.SurfaceBright,
				Size = UDim2.new(1, 0, 1, 0),
				Image = "rbxassetid://" .. id,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = Z + 1,
				Parent = wrapper,
			})
			Corner(img, 8)
			return wrapper
		end

		return S
	end

	function Tab:AddSection(o) return makeSection(o) end

	function Tab:Button(o)      return makeSection({ Name = "" }):Button(o) end
	function Tab:Toggle(o)      return makeSection({ Name = "" }):Toggle(o) end
	function Tab:Slider(o)      return makeSection({ Name = "" }):Slider(o) end
	function Tab:Input(o)       return makeSection({ Name = "" }):Input(o) end
	function Tab:Dropdown(o)    return makeSection({ Name = "" }):Dropdown(o) end
	function Tab:ColorPicker(o) return makeSection({ Name = "" }):ColorPicker(o) end
	function Tab:Keybind(o)     return makeSection({ Name = "" }):Keybind(o) end
	function Tab:Label(o)       return makeSection({ Name = "" }):Label(o) end
	function Tab:Paragraph(o)   return makeSection({ Name = "" }):Paragraph(o) end
	function Tab:Divider()      return makeSection({ Name = "" }):Divider() end
	function Tab:ProgressBar(o) return makeSection({ Name = "" }):ProgressBar(o) end
	function Tab:Image(o)       return makeSection({ Name = "" }):Image(o) end

	return Tab
end

function EclipseLib:CreateDialog(opts)
	opts = opts or {}
	local title    = opts.Title or "Confirm"
	local desc     = opts.Description or ""
	local dtype    = opts.Type or "confirm"
	local onOk     = opts.OnConfirm or function() end
	local onCancel = opts.OnCancel or function() end
	local okText   = opts.ConfirmText or "Confirm"
	local noText   = opts.CancelText or "Cancel"

	local dGui = getGui()

	local overlay = New("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 900,
		Parent = dGui,
	})
	Tween(overlay, { BackgroundTransparency = 0.45 }, 0.2)

	local col = Theme.Accent
	if dtype == "warning" then col = Theme.Yellow
	elseif dtype == "error" then col = Theme.Red
	elseif dtype == "success" then col = Theme.Green end

	local card = New("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0, 340, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.6, 0),
		ZIndex = 901,
		Parent = dGui,
	})
	Corner(card, 14)
	Stroke(card, col, 1, 0.6)
	Padding(card, 22, 22, 22, 22)
	List(card, Enum.FillDirection.Vertical, 12)

	Tween(card, { Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.28, Enum.EasingStyle.Back)

	New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 16,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 0,
		ZIndex = 902,
		Parent = card,
	})

	if desc ~= "" then
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = desc,
			TextColor3 = Theme.TextSub,
			TextSize = 12,
			Font = Theme.Font,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
			LayoutOrder = 1,
			ZIndex = 902,
			Parent = card,
		})
	end

	local btnRow = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 2,
		ZIndex = 902,
		Parent = card,
	})
	List(btnRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center)

	local function dlgBtn(txt, bg, cb2)
		local b = New("TextButton", {
			BackgroundColor3 = bg,
			Size = UDim2.new(0, 120, 0, 34),
			Text = txt,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 13,
			Font = Theme.FontBold,
			BorderSizePixel = 0,
			ZIndex = 903,
			Parent = btnRow,
		})
		Corner(b, 8)
		b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.15 }, 0.1) end)
		b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 0 }, 0.1) end)
		b.MouseButton1Click:Connect(function()
			Tween(overlay, { BackgroundTransparency = 1 }, 0.2)
			Tween(card, { BackgroundTransparency = 1 }, 0.2)
			task.wait(0.22)
			dGui:Destroy()
			task.spawn(cb2)
		end)
	end

	dlgBtn(noText, Theme.SurfaceAlt, onCancel)
	dlgBtn(okText, col, onOk)
end

local ThemePresets = {
	Eclipse = { Accent = Color3.fromRGB(100,85,240), AccentLight = Color3.fromRGB(128,112,255), AccentDark = Color3.fromRGB(64,52,170), AccentGlow = Color3.fromRGB(80,65,200) },
	Ocean   = { Accent = Color3.fromRGB(40,140,255), AccentLight = Color3.fromRGB(70,165,255),  AccentDark = Color3.fromRGB(20,90,180),  AccentGlow = Color3.fromRGB(30,110,210) },
	Rose    = { Accent = Color3.fromRGB(236,72,112), AccentLight = Color3.fromRGB(255,100,140), AccentDark = Color3.fromRGB(160,40,72),  AccentGlow = Color3.fromRGB(190,55,90) },
	Mint    = { Accent = Color3.fromRGB(52,210,130), AccentLight = Color3.fromRGB(80,230,155),  AccentDark = Color3.fromRGB(30,140,80),  AccentGlow = Color3.fromRGB(40,170,100) },
	Gold    = { Accent = Color3.fromRGB(220,170,40), AccentLight = Color3.fromRGB(245,195,60),  AccentDark = Color3.fromRGB(150,110,20), AccentGlow = Color3.fromRGB(180,140,30) },
	Mono    = { Accent = Color3.fromRGB(190,190,210), AccentLight = Color3.fromRGB(215,215,235), AccentDark = Color3.fromRGB(120,120,145), AccentGlow = Color3.fromRGB(150,150,175) },
}

function EclipseLib:ApplyPreset(name)
	local p = ThemePresets[name]
	if not p then return end
	for k, v in pairs(p) do Theme[k] = v end
end

function EclipseLib:GetPresets()
	local list = {}
	for k in pairs(ThemePresets) do table.insert(list, k) end
	return list
end

function EclipseLib:SetTheme(t)
	for k, v in pairs(t) do Theme[k] = v end
end

function EclipseLib:GetTheme()
	return Theme
end

local savedConfigs = {}

function EclipseLib:SaveConfig(name, data)
	savedConfigs[name] = data
	pcall(function()
		if writefile then
			writefile("EclipseLib_" .. name .. ".json", HttpService:JSONEncode(data))
		end
	end)
end

function EclipseLib:LoadConfig(name)
	if savedConfigs[name] then return savedConfigs[name] end
	local ok, res = pcall(function()
		if readfile then
			return HttpService:JSONDecode(readfile("EclipseLib_" .. name .. ".json"))
		end
	end)
	if ok and res then
		savedConfigs[name] = res
		return res
	end
	return nil
end

EclipseLib.Version = "2.0.0"

return EclipseLib
