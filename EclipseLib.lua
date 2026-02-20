local EclipseLib = {}
EclipseLib.__index = EclipseLib

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function tween(obj, props, duration, style, direction)
	style = style or Enum.EasingStyle.Quart
	direction = direction or Enum.EasingDirection.Out
	local info = TweenInfo.new(duration or 0.25, style, direction)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function create(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	if props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function makeCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
		Parent = parent
	})
end

local function makeStroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thickness or 1,
		Transparency = transparency or 0.85,
		Parent = parent
	})
end

local function makePadding(parent, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top or 8),
		PaddingRight = UDim.new(0, right or 8),
		PaddingBottom = UDim.new(0, bottom or 8),
		PaddingLeft = UDim.new(0, left or 8),
		Parent = parent
	})
end

local function makeListLayout(parent, direction, padding, halign, valign)
	return create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 6),
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = valign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent
	})
end

local function hsv2rgb(h, s, v)
	local r, g, b
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
	return Color3.new(r, g, b)
end

local function rgb2hsv(color)
	local r, g, b = color.R, color.G, color.B
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h, s, v
	v = max
	local d = max - min
	if max == 0 then s = 0 else s = d / max end
	if max == min then
		h = 0
	else
		if max == r then h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4
		end
		h = h / 6
	end
	return h, s, v
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function clamp(n, min, max)
	return math.max(min, math.min(max, n))
end

local Theme = {
	Background = Color3.fromRGB(10, 10, 14),
	Surface = Color3.fromRGB(16, 16, 22),
	SurfaceAlt = Color3.fromRGB(20, 20, 28),
	SurfaceHover = Color3.fromRGB(26, 26, 36),
	Border = Color3.fromRGB(255, 255, 255),
	BorderTransparency = 0.88,
	Accent = Color3.fromRGB(108, 92, 231),
	AccentHover = Color3.fromRGB(130, 116, 245),
	AccentDim = Color3.fromRGB(68, 56, 160),
	AccentTransparency = 0.75,
	Text = Color3.fromRGB(240, 240, 255),
	TextMuted = Color3.fromRGB(140, 140, 165),
	TextDim = Color3.fromRGB(90, 90, 115),
	Success = Color3.fromRGB(72, 199, 142),
	Warning = Color3.fromRGB(255, 180, 50),
	Error = Color3.fromRGB(255, 80, 80),
	Scrollbar = Color3.fromRGB(60, 60, 85),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontSemibold = Enum.Font.GothamSemibold,
}

local ActiveWindows = {}
local ZIndexCounter = 10

local function nextZ()
	ZIndexCounter = ZIndexCounter + 1
	return ZIndexCounter
end

local function getScreenGui()
	local gui
	local success = pcall(function()
		if syn and syn.protect_gui then
			gui = create("ScreenGui", {
				Name = "EclipseLib_" .. HttpService:GenerateGUID(false):sub(1, 8),
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			})
			syn.protect_gui(gui)
			gui.Parent = CoreGui
		end
	end)
	if not success or not gui then
		local success2 = pcall(function()
			gui = create("ScreenGui", {
				Name = "EclipseLib_" .. HttpService:GenerateGUID(false):sub(1, 8),
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Parent = CoreGui,
			})
		end)
		if not success2 or not gui then
			gui = create("ScreenGui", {
				Name = "EclipseLib",
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Parent = LocalPlayer:WaitForChild("PlayerGui"),
			})
		end
	end
	return gui
end

local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragStart
	local startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	dragHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local vp = workspace.CurrentCamera.ViewportSize
			local newX = clamp(startPos.X.Offset + delta.X, 0, vp.X - frame.AbsoluteSize.X)
			local newY = clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - frame.AbsoluteSize.Y)
			frame.Position = UDim2.new(0, newX, 0, newY)
		end
	end)
end

local function ripple(button, x, y)
	local rFrame = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.7,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
		ZIndex = button.ZIndex + 5,
		ClipsDescendants = false,
		Parent = button,
	})
	makeCorner(rFrame, 999)

	tween(rFrame, {
		Size = UDim2.new(0, 200, 0, 200),
		BackgroundTransparency = 1,
	}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	task.delay(0.5, function()
		rFrame:Destroy()
	end)
end

local Notification = {}
Notification.__index = Notification

local notifGui = nil
local notifContainer = nil

local function ensureNotifContainer()
	if notifGui and notifGui.Parent then return end
	notifGui = getScreenGui()
	notifContainer = create("Frame", {
		Name = "NotifContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 1, 0),
		Position = UDim2.new(1, -330, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		Parent = notifGui,
	})
	local list = makeListLayout(notifContainer, Enum.FillDirection.Vertical, 8)
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	create("UIPadding", {
		PaddingBottom = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 0),
		Parent = notifContainer,
	})
end

function EclipseLib:Notify(opts)
	opts = opts or {}
	local title = opts.Title or "Eclipse"
	local desc = opts.Description or ""
	local duration = opts.Duration or 4
	local ntype = opts.Type or "info"
	local icon = opts.Icon

	ensureNotifContainer()

	local accentCol = Theme.Accent
	if ntype == "success" then accentCol = Theme.Success
	elseif ntype == "warning" then accentCol = Theme.Warning
	elseif ntype == "error" then accentCol = Theme.Error
	end

	local card = create("Frame", {
		Name = "Notification",
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 80),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
		Parent = notifContainer,
	})
	makeCorner(card, 10)
	makeStroke(card, Theme.Border, 1, Theme.BorderTransparency)

	local accentBar = create("Frame", {
		Name = "Accent",
		BackgroundColor3 = accentCol,
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BorderSizePixel = 0,
		Parent = card,
	})
	makeCorner(accentBar, 999)

	local inner = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	makePadding(inner, 12, 8, 12, 4)

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 14,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inner,
	})

	if desc ~= "" then
		local descLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = desc,
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			Font = Theme.Font,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 1,
			Parent = inner,
		})
	end

	makeListLayout(inner, Enum.FillDirection.Vertical, 4)

	local progress = create("Frame", {
		Name = "Progress",
		BackgroundColor3 = accentCol,
		BackgroundTransparency = 0.3,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BorderSizePixel = 0,
		Parent = card,
	})

	card.Position = UDim2.new(1, 40, 0, 0)
	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		tween(card, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }, 0.3)
		task.wait(0.35)
		card:Destroy()
	end)
end

local Window = {}
Window.__index = Window

function EclipseLib:CreateWindow(opts)
	opts = opts or {}
	local self = setmetatable({}, Window)

	self.Title = opts.Title or "Eclipse"
	self.Subtitle = opts.Subtitle or "by EclipseHub"
	self.Size = opts.Size or Vector2.new(580, 440)
	self.Position = opts.Position
	self.Logo = opts.Logo
	self.Theme = opts.Theme
	self.Tabs = {}
	self.ActiveTab = nil
	self.Minimized = false
	self.Keybind = opts.Keybind or Enum.KeyCode.RightShift
	self.Visible = true
	self.Callbacks = {}

	if opts.Theme then
		for k, v in pairs(opts.Theme) do
			Theme[k] = v
		end
	end

	self.ScreenGui = getScreenGui()

	local vp = workspace.CurrentCamera.ViewportSize
	local startPos
	if self.Position then
		startPos = UDim2.new(0, self.Position.X, 0, self.Position.Y)
	else
		startPos = UDim2.new(0.5, -self.Size.X / 2, 0.5, -self.Size.Y / 2)
	end

	self.MainFrame = create("Frame", {
		Name = "EclipseWindow",
		BackgroundColor3 = Theme.Background,
		Size = UDim2.new(0, self.Size.X, 0, self.Size.Y),
		Position = startPos,
		ClipsDescendants = false,
		ZIndex = nextZ(),
		Parent = self.ScreenGui,
	})
	makeCorner(self.MainFrame, 12)
	makeStroke(self.MainFrame, Theme.Border, 1, Theme.BorderTransparency)

	local shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.5,
		Size = UDim2.new(1, 80, 1, 80),
		Position = UDim2.new(0, -40, 0, -40),
		ZIndex = self.MainFrame.ZIndex - 1,
		Parent = self.MainFrame,
	})

	self.TopBar = create("Frame", {
		Name = "TopBar",
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 54),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = self.MainFrame.ZIndex + 1,
		ClipsDescendants = true,
		Parent = self.MainFrame,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = self.TopBar,
	})
	create("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		BorderSizePixel = 0,
		ZIndex = self.TopBar.ZIndex,
		Parent = self.TopBar,
	})
	makeStroke(self.TopBar, Theme.Border, 1, Theme.BorderTransparency)

	local logoFrame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 12, 0.5, -18),
		ZIndex = self.TopBar.ZIndex + 1,
		Parent = self.TopBar,
	})

	if opts.Logo then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = "rbxassetid://" .. tostring(opts.Logo),
			ZIndex = logoFrame.ZIndex,
			Parent = logoFrame,
		})
	else
		local logoGrad = create("Frame", {
			BackgroundColor3 = Theme.Accent,
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			ZIndex = logoFrame.ZIndex,
			Parent = logoFrame,
		})
		makeCorner(logoGrad, 8)
		create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Theme.AccentHover),
				ColorSequenceKeypoint.new(1, Theme.AccentDim),
			}),
			Rotation = 135,
			Parent = logoGrad,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = string.upper(string.sub(self.Title, 1, 1)),
			TextColor3 = Theme.Text,
			TextSize = 18,
			Font = Theme.FontBold,
			ZIndex = logoFrame.ZIndex + 1,
			Parent = logoFrame,
		})
	end

	local titleStack = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -160, 0, 38),
		Position = UDim2.new(0, 58, 0.5, -19),
		ZIndex = self.TopBar.ZIndex + 1,
		Parent = self.TopBar,
	})
	makeListLayout(titleStack, Enum.FillDirection.Vertical, 0)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Text = self.Title,
		TextColor3 = Theme.Text,
		TextSize = 16,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = self.TopBar.ZIndex + 1,
		LayoutOrder = 0,
		Parent = titleStack,
	})

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Text = self.Subtitle,
		TextColor3 = Theme.TextDim,
		TextSize = 11,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = self.TopBar.ZIndex + 1,
		LayoutOrder = 1,
		Parent = titleStack,
	})

	local controls = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 80, 0, 30),
		Position = UDim2.new(1, -92, 0.5, -15),
		ZIndex = self.TopBar.ZIndex + 1,
		Parent = self.TopBar,
	})
	makeListLayout(controls, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right)

	local function makeCtrlBtn(icon, color)
		local btn = create("TextButton", {
			BackgroundColor3 = Theme.SurfaceAlt,
			Size = UDim2.new(0, 28, 0, 28),
			Text = icon,
			TextColor3 = color or Theme.TextMuted,
			TextSize = 14,
			Font = Theme.FontBold,
			BorderSizePixel = 0,
			ZIndex = controls.ZIndex + 1,
			Parent = controls,
		})
		makeCorner(btn, 6)
		return btn
	end

	local minimizeBtn = makeCtrlBtn("-", Theme.Warning)
	local closeBtn = makeCtrlBtn("x", Theme.Error)

	closeBtn.MouseButton1Click:Connect(function()
		tween(self.MainFrame, {
			Size = UDim2.new(0, self.Size.X, 0, 0),
			BackgroundTransparency = 1,
		}, 0.2)
		task.wait(0.22)
		self.ScreenGui:Destroy()
	end)

	minimizeBtn.MouseButton1Click:Connect(function()
		self.Minimized = not self.Minimized
		if self.Minimized then
			tween(self.MainFrame, { Size = UDim2.new(0, self.Size.X, 0, 54) }, 0.3, Enum.EasingStyle.Quart)
		else
			tween(self.MainFrame, { Size = UDim2.new(0, self.Size.X, 0, self.Size.Y) }, 0.3, Enum.EasingStyle.Back)
		end
	end)

	makeDraggable(self.MainFrame, self.TopBar)

	self.TabBar = create("Frame", {
		Name = "TabBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 140, 1, -54),
		Position = UDim2.new(0, 0, 0, 54),
		ClipsDescendants = false,
		ZIndex = self.MainFrame.ZIndex + 1,
		Parent = self.MainFrame,
	})

	local tabBarBg = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		ZIndex = self.TabBar.ZIndex,
		Parent = self.TabBar,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = tabBarBg,
	})
	create("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = tabBarBg.ZIndex,
		Parent = tabBarBg,
	})
	create("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = tabBarBg.ZIndex,
		Parent = tabBarBg,
	})

	self.TabList = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -16),
		Position = UDim2.new(0, 0, 0, 12),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = self.TabBar.ZIndex + 1,
		Parent = self.TabBar,
	})
	makePadding(self.TabList, 4, 8, 4, 8)
	makeListLayout(self.TabList, Enum.FillDirection.Vertical, 2)

	local divider = create("Frame", {
		Name = "Divider",
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.88,
		Size = UDim2.new(0, 1, 1, -54),
		Position = UDim2.new(0, 140, 0, 54),
		BorderSizePixel = 0,
		ZIndex = self.MainFrame.ZIndex + 1,
		Parent = self.MainFrame,
	})

	self.ContentArea = create("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -148, 1, -62),
		Position = UDim2.new(0, 148, 0, 62),
		ClipsDescendants = true,
		ZIndex = self.MainFrame.ZIndex + 1,
		Parent = self.MainFrame,
	})

	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.Size = UDim2.new(0, self.Size.X, 0, 0)
	tween(self.MainFrame, {
		BackgroundTransparency = 0,
		Size = UDim2.new(0, self.Size.X, 0, self.Size.Y),
	}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == self.Keybind then
			self.Visible = not self.Visible
			self.MainFrame.Visible = self.Visible
		end
	end)

	table.insert(ActiveWindows, self)
	return self
end

function Window:CreateTab(opts)
	opts = opts or {}
	local tabSelf = {
		Name = opts.Name or "Tab",
		Icon = opts.Icon,
		Elements = {},
		Window = self,
	}

	local tabBtn = create("TextButton", {
		Name = "TabBtn_" .. tabSelf.Name,
		BackgroundColor3 = Theme.SurfaceAlt,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		BorderSizePixel = 0,
		ZIndex = self.TabList.ZIndex + 1,
		AutomaticSize = Enum.AutomaticSize.None,
		Parent = self.TabList,
	})
	makeCorner(tabBtn, 8)

	local tabIcon = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		Text = opts.Icon or "",
		TextColor3 = Theme.TextMuted,
		TextSize = 14,
		Font = Theme.Font,
		ZIndex = tabBtn.ZIndex + 1,
		Visible = opts.Icon ~= nil,
		Parent = tabBtn,
	})

	local tabLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, opts.Icon and -34 or -16, 1, 0),
		Position = UDim2.new(0, opts.Icon and 30 or 10, 0, 0),
		Text = tabSelf.Name,
		TextColor3 = Theme.TextMuted,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = tabBtn.ZIndex + 1,
		Parent = tabBtn,
	})

	local activeIndicator = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0.5, -9),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = tabBtn.ZIndex + 1,
		Parent = tabBtn,
	})
	makeCorner(activeIndicator, 999)

	tabSelf.ContentFrame = create("ScrollingFrame", {
		Name = "Content_" .. tabSelf.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Scrollbar,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = self.ContentArea.ZIndex + 1,
		Visible = false,
		Parent = self.ContentArea,
	})
	makePadding(tabSelf.ContentFrame, 8, 12, 12, 8)
	makeListLayout(tabSelf.ContentFrame, Enum.FillDirection.Vertical, 6)

	tabSelf.TabBtn = tabBtn
	tabSelf.ActiveIndicator = activeIndicator
	tabSelf.TabLabel = tabLabel
	tabSelf.TabIcon = tabIcon

	local function activate()
		if self.ActiveTab then
			local prev = self.ActiveTab
			tween(prev.TabBtn, { BackgroundTransparency = 1 }, 0.15)
			tween(prev.ActiveIndicator, { BackgroundTransparency = 1 }, 0.15)
			tween(prev.TabLabel, { TextColor3 = Theme.TextMuted }, 0.15)
			prev.ContentFrame.Visible = false
		end
		self.ActiveTab = tabSelf
		tween(tabBtn, { BackgroundTransparency = 0.85 }, 0.15)
		tween(activeIndicator, { BackgroundTransparency = 0 }, 0.15)
		tween(tabLabel, { TextColor3 = Theme.Text }, 0.15)
		tabSelf.ContentFrame.Visible = true
		tabSelf.ContentFrame.BackgroundTransparency = 1

		tabSelf.ContentFrame.Position = UDim2.new(0.04, 0, 0, 0)
		tabSelf.ContentFrame.BackgroundTransparency = 1
		tween(tabSelf.ContentFrame, { Position = UDim2.new(0, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quart)
	end

	tabBtn.MouseButton1Click:Connect(activate)

	tabBtn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabSelf then
			tween(tabBtn, { BackgroundTransparency = 0.92 }, 0.1)
		end
	end)
	tabBtn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabSelf then
			tween(tabBtn, { BackgroundTransparency = 1 }, 0.1)
		end
	end)

	if #self.Tabs == 0 then
		activate()
	end

	table.insert(self.Tabs, tabSelf)

	local tabMeta = setmetatable({}, { __index = tabSelf })

	function tabMeta:AddSection(sectionOpts)
		sectionOpts = sectionOpts or {}
		local sectionName = sectionOpts.Name or ""

		local sectionFrame = create("Frame", {
			BackgroundColor3 = Theme.SurfaceAlt,
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = tabSelf.ContentFrame.ZIndex + 1,
			Parent = tabSelf.ContentFrame,
		})
		makeCorner(sectionFrame, 10)
		makeStroke(sectionFrame, Theme.Border, 1, 0.9)
		makePadding(sectionFrame, 10, 10, 10, 10)

		local sectionList = makeListLayout(sectionFrame, Enum.FillDirection.Vertical, 6)

		local sectionHeader = nil
		if sectionName ~= "" then
			sectionHeader = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = 0,
				ZIndex = sectionFrame.ZIndex + 1,
				Parent = sectionFrame,
			})

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = string.upper(sectionName),
				TextColor3 = Theme.TextDim,
				TextSize = 10,
				Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				LetterSpacing = 2,
				ZIndex = sectionHeader.ZIndex + 1,
				Parent = sectionHeader,
			})

			create("Frame", {
				BackgroundColor3 = Theme.Border,
				BackgroundTransparency = 0.88,
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BorderSizePixel = 0,
				ZIndex = sectionHeader.ZIndex,
				Parent = sectionHeader,
			})
		end

		local sectionMeta = {}
		sectionMeta._frame = sectionFrame
		sectionMeta._z = sectionFrame.ZIndex + 2
		sectionMeta._order = sectionName ~= "" and 1 or 0

		local function nextOrder()
			sectionMeta._order = sectionMeta._order + 1
			return sectionMeta._order
		end

		function sectionMeta:AddButton(btnOpts)
			btnOpts = btnOpts or {}
			local label = btnOpts.Name or btnOpts.Title or "Button"
			local desc = btnOpts.Description
			local callback = btnOpts.Callback or function() end

			local height = desc and 52 or 36
			local btn = create("TextButton", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, height),
				Text = "",
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
				ClipsDescendants = true,
			})
			makeCorner(btn, 8)
			makeStroke(btn, Theme.Border, 1, 0.9)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -40, 0, 18),
				Position = UDim2.new(0, 12, 0, desc and 8 or 9),
				Text = label,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = btn.ZIndex + 1,
				Parent = btn,
			})

			if desc then
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -40, 0, 14),
					Position = UDim2.new(0, 12, 0, 29),
					Text = desc,
					TextColor3 = Theme.TextMuted,
					TextSize = 11,
					Font = Theme.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = btn.ZIndex + 1,
					Parent = btn,
				})
			end

			local arrow = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 20, 1, 0),
				Position = UDim2.new(1, -30, 0, 0),
				Text = ">",
				TextColor3 = Theme.TextDim,
				TextSize = 14,
				Font = Theme.FontBold,
				ZIndex = btn.ZIndex + 1,
				Parent = btn,
			})

			btn.MouseEnter:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.SurfaceHover }, 0.12)
				tween(arrow, { TextColor3 = Theme.Accent }, 0.12)
			end)
			btn.MouseLeave:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.Surface }, 0.12)
				tween(arrow, { TextColor3 = Theme.TextDim }, 0.12)
			end)
			btn.MouseButton1Down:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.SurfaceAlt }, 0.08)
			end)
			btn.MouseButton1Up:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.SurfaceHover }, 0.08)
			end)

			btn.MouseButton1Click:Connect(function(x, y)
				ripple(btn, Mouse.X, Mouse.Y)
				callback()
			end)

			local btnObj = {}
			function btnObj:SetTitle(t) end
			function btnObj:Fire() callback() end
			return btnObj
		end

		function sectionMeta:AddToggle(tglOpts)
			tglOpts = tglOpts or {}
			local label = tglOpts.Name or tglOpts.Title or "Toggle"
			local desc = tglOpts.Description
			local default = tglOpts.Default or false
			local callback = tglOpts.Callback or function() end
			local flag = tglOpts.Flag

			local state = default
			local height = desc and 52 or 36

			local row = create("TextButton", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, height),
				Text = "",
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				ClipsDescendants = true,
				Parent = sectionFrame,
			})
			makeCorner(row, 8)
			makeStroke(row, Theme.Border, 1, 0.9)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -60, 0, 18),
				Position = UDim2.new(0, 12, 0, desc and 8 or 9),
				Text = label,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = row.ZIndex + 1,
				Parent = row,
			})

			if desc then
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -60, 0, 14),
					Position = UDim2.new(0, 12, 0, 29),
					Text = desc,
					TextColor3 = Theme.TextMuted,
					TextSize = 11,
					Font = Theme.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = row.ZIndex + 1,
					Parent = row,
				})
			end

			local trackOuter = create("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(0, 40, 0, 22),
				Position = UDim2.new(1, -52, 0.5, -11),
				BorderSizePixel = 0,
				ZIndex = row.ZIndex + 1,
				Parent = row,
			})
			makeCorner(trackOuter, 999)
			makeStroke(trackOuter, Theme.Border, 1, 0.85)

			local trackFill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new(state and 1 or 0, 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = trackOuter.ZIndex + 1,
				Parent = trackOuter,
			})
			makeCorner(trackFill, 999)

			local knob = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 16, 0, 16),
				Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
				BorderSizePixel = 0,
				ZIndex = trackOuter.ZIndex + 2,
				Parent = trackOuter,
			})
			makeCorner(knob, 999)

			local function setToggle(val, skipCallback)
				state = val
				tween(trackFill, { Size = UDim2.new(val and 1 or 0, 0, 1, 0) }, 0.18)
				tween(knob, { Position = val and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.18)
				tween(trackOuter, { BackgroundColor3 = val and Theme.AccentDim or Theme.SurfaceAlt }, 0.18)
				if not skipCallback then callback(val) end
			end

			row.MouseButton1Click:Connect(function()
				setToggle(not state)
			end)
			row.MouseEnter:Connect(function()
				tween(row, { BackgroundColor3 = Theme.SurfaceHover }, 0.12)
			end)
			row.MouseLeave:Connect(function()
				tween(row, { BackgroundColor3 = Theme.Surface }, 0.12)
			end)

			local tglObj = {}
			function tglObj:Set(val) setToggle(val, false) end
			function tglObj:Get() return state end
			return tglObj
		end

		function sectionMeta:AddSlider(sliderOpts)
			sliderOpts = sliderOpts or {}
			local label = sliderOpts.Name or sliderOpts.Title or "Slider"
			local min = sliderOpts.Min or 0
			local max = sliderOpts.Max or 100
			local default = sliderOpts.Default or min
			local increment = sliderOpts.Increment or 1
			local suffix = sliderOpts.Suffix or ""
			local callback = sliderOpts.Callback or function() end

			local value = clamp(default, min, max)
			value = math.floor(value / increment + 0.5) * increment

			local sliderFrame = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 56),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			makeCorner(sliderFrame, 8)
			makeStroke(sliderFrame, Theme.Border, 1, 0.9)
			makePadding(sliderFrame, 8, 12, 8, 12)

			local topRow = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				ZIndex = sliderFrame.ZIndex + 1,
				Parent = sliderFrame,
			})

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.7, 0, 1, 0),
				Text = label,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = topRow.ZIndex + 1,
				Parent = topRow,
			})

			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.3, 0, 1, 0),
				Position = UDim2.new(0.7, 0, 0, 0),
				Text = tostring(value) .. suffix,
				TextColor3 = Theme.Accent,
				TextSize = 13,
				Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = topRow.ZIndex + 1,
				Parent = topRow,
			})

			local trackBg = create("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 6),
				Position = UDim2.new(0, 0, 0, 32),
				BorderSizePixel = 0,
				ZIndex = sliderFrame.ZIndex + 1,
				Parent = sliderFrame,
			})
			makeCorner(trackBg, 999)

			local trackFill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = trackBg.ZIndex + 1,
				Parent = trackBg,
			})
			makeCorner(trackFill, 999)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentHover),
					ColorSequenceKeypoint.new(1, Theme.Accent),
				}),
				Parent = trackFill,
			})

			local handle = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 14, 0, 14),
				Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
				BorderSizePixel = 0,
				ZIndex = trackBg.ZIndex + 2,
				Parent = trackBg,
			})
			makeCorner(handle, 999)
			makeStroke(handle, Theme.Accent, 2, 0)

			local dragging = false

			local function updateValue(mouseX)
				local abs = trackBg.AbsolutePosition.X
				local w = trackBg.AbsoluteSize.X
				local t = clamp((mouseX - abs) / w, 0, 1)
				local raw = min + t * (max - min)
				local snapped = math.floor(raw / increment + 0.5) * increment
				snapped = clamp(snapped, min, max)
				value = snapped
				local frac = (value - min) / (max - min)
				trackFill.Size = UDim2.new(frac, 0, 1, 0)
				handle.Position = UDim2.new(frac, -7, 0.5, -7)
				valueLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100) .. suffix
				callback(value)
			end

			trackBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					updateValue(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					updateValue(input.Position.X)
				end
			end)

			handle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
				end
			end)

			local sliderObj = {}
			function sliderObj:Set(val)
				value = clamp(val, min, max)
				value = math.floor(value / increment + 0.5) * increment
				local frac = (value - min) / (max - min)
				tween(trackFill, { Size = UDim2.new(frac, 0, 1, 0) }, 0.15)
				handle.Position = UDim2.new(frac, -7, 0.5, -7)
				valueLabel.Text = tostring(value) .. suffix
			end
			function sliderObj:Get() return value end
			return sliderObj
		end

		function sectionMeta:AddInput(inputOpts)
			inputOpts = inputOpts or {}
			local label = inputOpts.Name or inputOpts.Title or "Input"
			local placeholder = inputOpts.Placeholder or "Type here..."
			local default = inputOpts.Default or ""
			local callback = inputOpts.Callback or function() end
			local multiline = inputOpts.MultiLine or false
			local clearOnFocus = inputOpts.ClearOnFocus ~= false
			local numeric = inputOpts.Numeric or false

			local height = multiline and 80 or 56
			local inputFrame = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, height),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			makeCorner(inputFrame, 8)
			makeStroke(inputFrame, Theme.Border, 1, 0.88)
			makePadding(inputFrame, 6, 10, 6, 10)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Text = label,
				TextColor3 = Theme.TextMuted,
				TextSize = 11,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = inputFrame.ZIndex + 1,
				LayoutOrder = 0,
				Parent = inputFrame,
			})

			local box = create("TextBox", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, multiline and 46 or 24),
				Text = default,
				PlaceholderText = placeholder,
				PlaceholderColor3 = Theme.TextDim,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = clearOnFocus,
				MultiLine = multiline,
				TextWrapped = multiline,
				ZIndex = inputFrame.ZIndex + 1,
				LayoutOrder = 1,
				Parent = inputFrame,
			})

			makeListLayout(inputFrame, Enum.FillDirection.Vertical, 4)

			local focusStroke = makeStroke(inputFrame, Theme.Border, 1, 0.88)

			box.Focused:Connect(function()
				tween(focusStroke, { Color = Theme.Accent, Transparency = 0.4 }, 0.15)
			end)
			box.FocusLost:Connect(function()
				tween(focusStroke, { Color = Theme.Border, Transparency = 0.88 }, 0.15)
				callback(box.Text)
			end)
			box:GetPropertyChangedSignal("Text"):Connect(function()
				if numeric then
					local filtered = box.Text:gsub("[^%d%.-]", "")
					if filtered ~= box.Text then
						box.Text = filtered
					end
				end
			end)

			local inputObj = {}
			function inputObj:Set(val)
				box.Text = tostring(val)
			end
			function inputObj:Get()
				return box.Text
			end
			return inputObj
		end

		function sectionMeta:AddDropdown(ddOpts)
			ddOpts = ddOpts or {}
			local label = ddOpts.Name or ddOpts.Title or "Dropdown"
			local options = ddOpts.Options or {}
			local default = ddOpts.Default
			local multi = ddOpts.MultiSelect or false
			local callback = ddOpts.Callback or function() end
			local desc = ddOpts.Description

			local selected = default or (not multi and options[1]) or {}
			if multi and type(selected) ~= "table" then selected = {} end

			local open = false

			local ddFrame = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, desc and 62 or 48),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				ClipsDescendants = false,
				Parent = sectionFrame,
			})
			makeCorner(ddFrame, 8)
			makeStroke(ddFrame, Theme.Border, 1, 0.88)

			local header = create("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36),
				Position = UDim2.new(0, 0, 0, desc and 12 or 6),
				Text = "",
				BorderSizePixel = 0,
				ZIndex = ddFrame.ZIndex + 1,
				Parent = ddFrame,
			})

			if desc then
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -20, 0, 12),
					Position = UDim2.new(0, 12, 0, 4),
					Text = label,
					TextColor3 = Theme.TextMuted,
					TextSize = 10,
					Font = Theme.FontBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = ddFrame.ZIndex + 1,
					Parent = ddFrame,
				})
			end

			local titleLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.7, 0, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Text = not desc and label or (multi and "Select..." or tostring(selected)),
				TextColor3 = not desc and Theme.Text or Theme.TextMuted,
				TextSize = 13,
				Font = not desc and Theme.FontSemibold or Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = header.ZIndex + 1,
				Parent = header,
			})

			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.45, 0, 1, 0),
				Position = UDim2.new(0.28, 0, 0, 0),
				Text = multi and "None" or tostring(selected or ""),
				TextColor3 = Theme.Accent,
				TextSize = 12,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = header.ZIndex + 1,
				Parent = header,
			})

			local arrow = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 20, 1, 0),
				Position = UDim2.new(1, -28, 0, 0),
				Text = "v",
				TextColor3 = Theme.TextDim,
				TextSize = 12,
				Font = Theme.FontBold,
				ZIndex = header.ZIndex + 1,
				Parent = header,
			})

			local dropdown = create("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 1, 4),
				ClipsDescendants = true,
				BorderSizePixel = 0,
				ZIndex = ddFrame.ZIndex + 10,
				Visible = false,
				Parent = ddFrame,
			})
			makeCorner(dropdown, 8)
			makeStroke(dropdown, Theme.Accent, 1, 0.6)

			local scroll = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.Scrollbar,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ZIndex = dropdown.ZIndex + 1,
				Parent = dropdown,
			})
			makePadding(scroll, 4, 6, 4, 6)
			makeListLayout(scroll, Enum.FillDirection.Vertical, 2)

			local optionBtns = {}
			local function refreshOptions()
				for _, v in pairs(scroll:GetChildren()) do
					if v:IsA("TextButton") then v:Destroy() end
				end
				for _, opt in ipairs(options) do
					local isSelected = multi and table.find(selected, opt) ~= nil or selected == opt
					local optBtn = create("TextButton", {
						BackgroundColor3 = isSelected and Theme.AccentDim or Theme.Surface,
						Size = UDim2.new(1, 0, 0, 28),
						Text = "",
						BorderSizePixel = 0,
						ZIndex = scroll.ZIndex + 1,
						Parent = scroll,
					})
					makeCorner(optBtn, 6)
					create("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, multi and -30 or -12, 1, 0),
						Position = UDim2.new(0, 10, 0, 0),
						Text = tostring(opt),
						TextColor3 = isSelected and Theme.Text or Theme.TextMuted,
						TextSize = 12,
						Font = isSelected and Theme.FontSemibold or Theme.Font,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = optBtn.ZIndex + 1,
						Parent = optBtn,
					})
					if multi and isSelected then
						create("TextLabel", {
							BackgroundTransparency = 1,
							Size = UDim2.new(0, 20, 1, 0),
							Position = UDim2.new(1, -28, 0, 0),
							Text = "ok",
							TextColor3 = Theme.Accent,
							TextSize = 10,
							Font = Theme.FontBold,
							ZIndex = optBtn.ZIndex + 1,
							Parent = optBtn,
						})
					end
					optBtn.MouseEnter:Connect(function()
						if not isSelected then
							tween(optBtn, { BackgroundColor3 = Theme.SurfaceHover }, 0.1)
						end
					end)
					optBtn.MouseLeave:Connect(function()
						if not isSelected then
							tween(optBtn, { BackgroundColor3 = Theme.Surface }, 0.1)
						end
					end)
					optBtn.MouseButton1Click:Connect(function()
						if multi then
							local idx = table.find(selected, opt)
							if idx then table.remove(selected, idx)
							else table.insert(selected, opt) end
							valueLabel.Text = #selected > 0 and table.concat(selected, ", ") or "None"
							callback(selected)
						else
							selected = opt
							valueLabel.Text = tostring(selected)
							callback(selected)
							header.MouseButton1Click:Fire()
						end
						refreshOptions()
					end)
				end
				local h = math.min(#options * 30 + 8, 150)
				tween(dropdown, { Size = UDim2.new(1, 0, 0, h) }, 0.2)
			end

			header.MouseButton1Click:Connect(function()
				open = not open
				if open then
					dropdown.Visible = true
					dropdown.Size = UDim2.new(1, 0, 0, 0)
					refreshOptions()
					tween(arrow, { Rotation = 180 }, 0.2)
				else
					tween(dropdown, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
					tween(arrow, { Rotation = 0 }, 0.2)
					task.wait(0.2)
					dropdown.Visible = false
				end
			end)

			local ddObj = {}
			function ddObj:Set(val)
				selected = val
				valueLabel.Text = type(val) == "table" and table.concat(val, ", ") or tostring(val)
				callback(selected)
			end
			function ddObj:Get() return selected end
			function ddObj:Refresh(newOpts)
				options = newOpts
				if not multi then selected = newOpts[1] end
			end
			return ddObj
		end

		function sectionMeta:AddColorPicker(cpOpts)
			cpOpts = cpOpts or {}
			local label = cpOpts.Name or cpOpts.Title or "Color"
			local default = cpOpts.Default or Color3.fromRGB(108, 92, 231)
			local callback = cpOpts.Callback or function() end

			local h, s, v = rgb2hsv(default)
			local alpha = cpOpts.Alpha ~= false and 1 or nil
			local open = false

			local cpFrame = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 40),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				ClipsDescendants = false,
				Parent = sectionFrame,
			})
			makeCorner(cpFrame, 8)
			makeStroke(cpFrame, Theme.Border, 1, 0.88)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.6, 0, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Text = label,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = cpFrame.ZIndex + 1,
				Parent = cpFrame,
			})

			local preview = create("TextButton", {
				BackgroundColor3 = default,
				Size = UDim2.new(0, 60, 0, 26),
				Position = UDim2.new(1, -72, 0.5, -13),
				Text = "",
				BorderSizePixel = 0,
				ZIndex = cpFrame.ZIndex + 1,
				Parent = cpFrame,
			})
			makeCorner(preview, 6)
			makeStroke(preview, Theme.Border, 1, 0.7)

			local picker = create("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 220),
				Position = UDim2.new(0, 0, 1, 6),
				Visible = false,
				ZIndex = cpFrame.ZIndex + 10,
				ClipsDescendants = true,
				Parent = cpFrame,
			})
			makeCorner(picker, 10)
			makeStroke(picker, Theme.Accent, 1, 0.6)

			local svCanvas = create("ImageLabel", {
				BackgroundColor3 = hsv2rgb(h, 1, 1),
				Size = UDim2.new(1, -20, 0, 140),
				Position = UDim2.new(0, 10, 0, 10),
				Image = "rbxassetid://6020299385",
				ZIndex = picker.ZIndex + 1,
				Parent = picker,
			})
			makeCorner(svCanvas, 6)

			local svDot = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 12, 0, 12),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0),
				BorderSizePixel = 0,
				ZIndex = svCanvas.ZIndex + 1,
				Parent = svCanvas,
			})
			makeCorner(svDot, 999)
			makeStroke(svDot, Color3.fromRGB(0, 0, 0), 2, 0)

			local hueTrack = create("ImageLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(1, -20, 0, 14),
				Position = UDim2.new(0, 10, 0, 158),
				Image = "rbxassetid://6020299385",
				ZIndex = picker.ZIndex + 1,
				Parent = picker,
			})
			makeCorner(hueTrack, 999)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
					ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
					ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				}),
				Parent = hueTrack,
			})

			local hueKnob = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 14, 0, 14),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(h, 0, 0.5, 0),
				BorderSizePixel = 0,
				ZIndex = hueTrack.ZIndex + 1,
				Parent = hueTrack,
			})
			makeCorner(hueKnob, 999)
			makeStroke(hueKnob, Color3.fromRGB(0, 0, 0), 2, 0)

			local hexInput = create("TextBox", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, -20, 0, 28),
				Position = UDim2.new(0, 10, 0, 182),
				Text = string.format("#%02X%02X%02X", math.floor(default.R*255), math.floor(default.G*255), math.floor(default.B*255)),
				TextColor3 = Theme.Text,
				PlaceholderText = "#FFFFFF",
				PlaceholderColor3 = Theme.TextDim,
				TextSize = 12,
				Font = Theme.Font,
				ClearTextOnFocus = false,
				ZIndex = picker.ZIndex + 1,
				Parent = picker,
			})
			makeCorner(hexInput, 6)
			makeStroke(hexInput, Theme.Border, 1, 0.8)

			local function updateColor()
				local color = hsv2rgb(h, s, v)
				preview.BackgroundColor3 = color
				svCanvas.BackgroundColor3 = hsv2rgb(h, 1, 1)
				svDot.Position = UDim2.new(s, 0, 1 - v, 0)
				hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
				hexInput.Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
				callback(color)
			end

			local svDragging = false
			svCanvas.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					svDragging = true
					local rel = input.Position - svCanvas.AbsolutePosition
					s = clamp(rel.X / svCanvas.AbsoluteSize.X, 0, 1)
					v = clamp(1 - rel.Y / svCanvas.AbsoluteSize.Y, 0, 1)
					updateColor()
				end
			end)

			local hueDragging = false
			hueTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					hueDragging = true
					h = clamp((input.Position.X - hueTrack.AbsolutePosition.X) / hueTrack.AbsoluteSize.X, 0, 1)
					updateColor()
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					svDragging = false
					hueDragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					if svDragging then
						local rel = input.Position - svCanvas.AbsolutePosition
						s = clamp(rel.X / svCanvas.AbsoluteSize.X, 0, 1)
						v = clamp(1 - rel.Y / svCanvas.AbsoluteSize.Y, 0, 1)
						updateColor()
					elseif hueDragging then
						h = clamp((input.Position.X - hueTrack.AbsolutePosition.X) / hueTrack.AbsoluteSize.X, 0, 1)
						updateColor()
					end
				end
			end)

			hexInput.FocusLost:Connect(function()
				local hex = hexInput.Text:gsub("#", "")
				if #hex == 6 then
					local r = tonumber(hex:sub(1,2), 16) or 255
					local g = tonumber(hex:sub(3,4), 16) or 255
					local b = tonumber(hex:sub(5,6), 16) or 255
					local color = Color3.fromRGB(r, g, b)
					h, s, v = rgb2hsv(color)
					updateColor()
				end
			end)

			preview.MouseButton1Click:Connect(function()
				open = not open
				picker.Visible = open
				if open then
					picker.Size = UDim2.new(1, 0, 0, 0)
					tween(picker, { Size = UDim2.new(1, 0, 0, 220) }, 0.25, Enum.EasingStyle.Back)
				else
					tween(picker, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
					task.wait(0.22)
					picker.Visible = false
				end
			end)

			local cpObj = {}
			function cpObj:Set(color)
				h, s, v = rgb2hsv(color)
				updateColor()
			end
			function cpObj:Get()
				return hsv2rgb(h, s, v)
			end
			return cpObj
		end

		function sectionMeta:AddKeybind(kbOpts)
			kbOpts = kbOpts or {}
			local label = kbOpts.Name or kbOpts.Title or "Keybind"
			local default = kbOpts.Default or Enum.KeyCode.Unknown
			local callback = kbOpts.Callback or function() end
			local mode = kbOpts.Mode or "Toggle"

			local bound = default
			local listening = false
			local active = false

			local kbFrame = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 36),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			makeCorner(kbFrame, 8)
			makeStroke(kbFrame, Theme.Border, 1, 0.88)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.55, 0, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Text = label,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = kbFrame.ZIndex + 1,
				Parent = kbFrame,
			})

			local keyBtn = create("TextButton", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(0, 90, 0, 24),
				Position = UDim2.new(1, -102, 0.5, -12),
				Text = bound.Name,
				TextColor3 = Theme.Accent,
				TextSize = 11,
				Font = Theme.FontBold,
				BorderSizePixel = 0,
				ZIndex = kbFrame.ZIndex + 1,
				Parent = kbFrame,
			})
			makeCorner(keyBtn, 6)
			makeStroke(keyBtn, Theme.Accent, 1, 0.7)

			keyBtn.MouseButton1Click:Connect(function()
				listening = true
				keyBtn.Text = "..."
				tween(keyBtn, { BackgroundColor3 = Theme.AccentDim }, 0.1)
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					bound = input.KeyCode
					keyBtn.Text = bound.Name
					listening = false
					tween(keyBtn, { BackgroundColor3 = Theme.SurfaceAlt }, 0.1)
				elseif not gpe and input.KeyCode == bound and not listening then
					if mode == "Toggle" then
						active = not active
						callback(active)
					else
						callback(true)
					end
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if mode == "Hold" and input.KeyCode == bound then
					callback(false)
				end
			end)

			local kbObj = {}
			function kbObj:Set(key) bound = key; keyBtn.Text = key.Name end
			function kbObj:Get() return bound end
			return kbObj
		end

		function sectionMeta:AddLabel(lOpts)
			lOpts = type(lOpts) == "string" and { Text = lOpts } or lOpts
			local text = lOpts.Text or "Label"
			local color = lOpts.Color or Theme.TextMuted
			local size = lOpts.Size or 12

			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = text,
				TextColor3 = color,
				TextSize = size,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			makePadding(label, 2, 0, 2, 2)

			local lObj = {}
			function lObj:Set(t)
				label.Text = t
			end
			function lObj:SetColor(c)
				label.TextColor3 = c
			end
			return lObj
		end

		function sectionMeta:AddParagraph(pOpts)
			pOpts = type(pOpts) == "string" and { Title = pOpts } or pOpts
			local title = pOpts.Title or ""
			local content = pOpts.Content or pOpts.Text or ""

			local pFrame = create("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				BackgroundTransparency = 0.6,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			makeCorner(pFrame, 8)
			makePadding(pFrame, 8, 10, 8, 10)
			makeListLayout(pFrame, Enum.FillDirection.Vertical, 4)

			local titleLabel = nil
			if title ~= "" then
				titleLabel = create("TextLabel", {
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
					ZIndex = pFrame.ZIndex + 1,
					Parent = pFrame,
				})
			end

			local contentLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = content,
				TextColor3 = Theme.TextMuted,
				TextSize = 12,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = 1,
				ZIndex = pFrame.ZIndex + 1,
				Parent = pFrame,
			})

			local pObj = {}
			function pObj:SetTitle(t)
				if titleLabel then titleLabel.Text = t end
			end
			function pObj:SetContent(c)
				contentLabel.Text = c
			end
			return pObj
		end

		function sectionMeta:AddDivider()
			local div = create("Frame", {
				BackgroundColor3 = Theme.Border,
				BackgroundTransparency = 0.85,
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			return div
		end

		function sectionMeta:AddImage(imgOpts)
			imgOpts = imgOpts or {}
			local id = imgOpts.Image or imgOpts.Id or ""
			local height = imgOpts.Height or 80
			local label = imgOpts.Label

			local wrapper = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, height + (label and 20 or 0)),
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})

			local img = create("ImageLabel", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, height),
				Image = "rbxassetid://" .. tostring(id),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = wrapper.ZIndex + 1,
				Parent = wrapper,
			})
			makeCorner(img, 8)

			if label then
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Position = UDim2.new(0, 0, 0, height + 4),
					Text = label,
					TextColor3 = Theme.TextMuted,
					TextSize = 11,
					Font = Theme.Font,
					ZIndex = wrapper.ZIndex + 1,
					Parent = wrapper,
				})
			end

			return wrapper
		end

		function sectionMeta:AddProgressBar(pbOpts)
			pbOpts = pbOpts or {}
			local label = pbOpts.Name or pbOpts.Title or "Progress"
			local default = pbOpts.Default or 0
			local max = pbOpts.Max or 100
			local suffix = pbOpts.Suffix or "%"

			local current = clamp(default, 0, max)

			local pbFrame = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 48),
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				ZIndex = sectionMeta._z,
				Parent = sectionFrame,
			})
			makeCorner(pbFrame, 8)
			makeStroke(pbFrame, Theme.Border, 1, 0.9)
			makePadding(pbFrame, 8, 12, 8, 12)

			local topRow = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = pbFrame.ZIndex + 1,
				Parent = pbFrame,
			})

			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.7, 0, 1, 0),
				Text = label,
				TextColor3 = Theme.TextMuted,
				TextSize = 12,
				Font = Theme.FontSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = topRow.ZIndex + 1,
				Parent = topRow,
			})

			local valLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.3, 0, 1, 0),
				Position = UDim2.new(0.7, 0, 0, 0),
				Text = tostring(current) .. suffix,
				TextColor3 = Theme.Accent,
				TextSize = 12,
				Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = topRow.ZIndex + 1,
				Parent = topRow,
			})

			local track = create("Frame", {
				BackgroundColor3 = Theme.SurfaceAlt,
				Size = UDim2.new(1, 0, 0, 6),
				Position = UDim2.new(0, 0, 0, 26),
				BorderSizePixel = 0,
				ZIndex = pbFrame.ZIndex + 1,
				Parent = pbFrame,
			})
			makeCorner(track, 999)

			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new(current / max, 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = track.ZIndex + 1,
				Parent = track,
			})
			makeCorner(fill, 999)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentHover),
					ColorSequenceKeypoint.new(1, Theme.Accent),
				}),
				Parent = fill,
			})

			local pbObj = {}
			function pbObj:Set(val)
				current = clamp(val, 0, max)
				tween(fill, { Size = UDim2.new(current / max, 0, 1, 0) }, 0.3)
				valLabel.Text = tostring(math.floor(current)) .. suffix
			end
			function pbObj:Get() return current end
			return pbObj
		end

		return sectionMeta
	end

	function tabMeta:AddButton(opts) 
		local s = self:AddSection({ Name = "" })
		return s:AddButton(opts)
	end
	function tabMeta:AddToggle(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddToggle(opts)
	end
	function tabMeta:AddSlider(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddSlider(opts)
	end
	function tabMeta:AddInput(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddInput(opts)
	end
	function tabMeta:AddDropdown(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddDropdown(opts)
	end
	function tabMeta:AddColorPicker(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddColorPicker(opts)
	end
	function tabMeta:AddKeybind(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddKeybind(opts)
	end
	function tabMeta:AddLabel(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddLabel(opts)
	end
	function tabMeta:AddParagraph(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddParagraph(opts)
	end
	function tabMeta:AddDivider()
		local s = self:AddSection({ Name = "" })
		return s:AddDivider()
	end
	function tabMeta:AddProgressBar(opts)
		local s = self:AddSection({ Name = "" })
		return s:AddProgressBar(opts)
	end

	return tabMeta
end

function Window:SelectTab(name)
	for _, t in ipairs(self.Tabs) do
		if t.Name == name then
			t.TabBtn.MouseButton1Click:Fire()
			return
		end
	end
end

function Window:SetTheme(customTheme)
	for k, v in pairs(customTheme) do
		Theme[k] = v
	end
end

function Window:Destroy()
	self.ScreenGui:Destroy()
end

function EclipseLib:SetTheme(customTheme)
	for k, v in pairs(customTheme) do
		Theme[k] = v
	end
end

function EclipseLib:GetTheme()
	return Theme
end

local ThemePresets = {
	Eclipse = {
		Background = Color3.fromRGB(10, 10, 14),
		Surface = Color3.fromRGB(16, 16, 22),
		SurfaceAlt = Color3.fromRGB(20, 20, 28),
		SurfaceHover = Color3.fromRGB(26, 26, 36),
		Accent = Color3.fromRGB(108, 92, 231),
		AccentHover = Color3.fromRGB(130, 116, 245),
		AccentDim = Color3.fromRGB(68, 56, 160),
	},
	Ocean = {
		Background = Color3.fromRGB(8, 14, 22),
		Surface = Color3.fromRGB(12, 20, 32),
		SurfaceAlt = Color3.fromRGB(16, 26, 40),
		SurfaceHover = Color3.fromRGB(22, 34, 52),
		Accent = Color3.fromRGB(50, 140, 255),
		AccentHover = Color3.fromRGB(80, 160, 255),
		AccentDim = Color3.fromRGB(30, 90, 180),
	},
	Rose = {
		Background = Color3.fromRGB(18, 10, 12),
		Surface = Color3.fromRGB(26, 14, 18),
		SurfaceAlt = Color3.fromRGB(34, 18, 24),
		SurfaceHover = Color3.fromRGB(44, 24, 32),
		Accent = Color3.fromRGB(236, 72, 112),
		AccentHover = Color3.fromRGB(255, 100, 140),
		AccentDim = Color3.fromRGB(160, 40, 72),
	},
	Forest = {
		Background = Color3.fromRGB(8, 14, 10),
		Surface = Color3.fromRGB(12, 20, 14),
		SurfaceAlt = Color3.fromRGB(16, 28, 18),
		SurfaceHover = Color3.fromRGB(22, 36, 24),
		Accent = Color3.fromRGB(52, 199, 89),
		AccentHover = Color3.fromRGB(80, 220, 110),
		AccentDim = Color3.fromRGB(30, 130, 55),
	},
	Ash = {
		Background = Color3.fromRGB(14, 14, 16),
		Surface = Color3.fromRGB(20, 20, 24),
		SurfaceAlt = Color3.fromRGB(28, 28, 32),
		SurfaceHover = Color3.fromRGB(36, 36, 42),
		Accent = Color3.fromRGB(200, 200, 220),
		AccentHover = Color3.fromRGB(220, 220, 240),
		AccentDim = Color3.fromRGB(120, 120, 140),
	},
}

function EclipseLib:ApplyPreset(presetName)
	local preset = ThemePresets[presetName]
	if preset then
		for k, v in pairs(preset) do
			Theme[k] = v
		end
	end
end

function EclipseLib:GetPresets()
	local names = {}
	for k in pairs(ThemePresets) do
		table.insert(names, k)
	end
	return names
end

local SavedConfigs = {}

function EclipseLib:SaveConfig(name, data)
	SavedConfigs[name] = data
	if writefile then
		local ok = pcall(function()
			writefile("EclipseLib_" .. name .. ".json", HttpService:JSONEncode(data))
		end)
	end
end

function EclipseLib:LoadConfig(name)
	if SavedConfigs[name] then
		return SavedConfigs[name]
	end
	if readfile then
		local ok, result = pcall(function()
			return HttpService:JSONDecode(readfile("EclipseLib_" .. name .. ".json"))
		end)
		if ok then
			SavedConfigs[name] = result
			return result
		end
	end
	return nil
end

function EclipseLib:ListConfigs()
	local list = {}
	for k in pairs(SavedConfigs) do
		table.insert(list, k)
	end
	return list
end

local DialogOpen = false

function EclipseLib:CreateDialog(opts)
	opts = opts or {}
	local title = opts.Title or "Confirm"
	local desc = opts.Description or "Are you sure?"
	local confirmText = opts.ConfirmText or "Confirm"
	local cancelText = opts.CancelText or "Cancel"
	local confirmCallback = opts.OnConfirm or function() end
	local cancelCallback = opts.OnCancel or function() end
	local dialogType = opts.Type or "confirm"

	if DialogOpen then return end
	DialogOpen = true

	local dGui = getScreenGui()

	local overlay = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 100,
		Parent = dGui,
	})

	local card = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(0, 360, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 101,
		Parent = dGui,
	})
	makeCorner(card, 12)
	makeStroke(card, Theme.Border, 1, Theme.BorderTransparency)
	makePadding(card, 20, 20, 20, 20)
	makeListLayout(card, Enum.FillDirection.Vertical, 14)

	local accentColor = Theme.Accent
	if dialogType == "warning" then accentColor = Theme.Warning
	elseif dialogType == "error" then accentColor = Theme.Error
	elseif dialogType == "success" then accentColor = Theme.Success
	end

	local iconRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 0,
		ZIndex = card.ZIndex + 1,
		Parent = card,
	})

	local iconCircle = create("Frame", {
		BackgroundColor3 = accentColor,
		BackgroundTransparency = 0.7,
		Size = UDim2.new(0, 40, 0, 40),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = iconRow.ZIndex + 1,
		Parent = iconRow,
	})
	makeCorner(iconCircle, 999)

	local iconSymbol = "?"
	if dialogType == "warning" then iconSymbol = "!"
	elseif dialogType == "error" then iconSymbol = "x"
	elseif dialogType == "success" then iconSymbol = "ok"
	elseif dialogType == "confirm" then iconSymbol = "?"
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = iconSymbol,
		TextColor3 = accentColor,
		TextSize = 18,
		Font = Theme.FontBold,
		ZIndex = iconCircle.ZIndex + 1,
		Parent = iconCircle,
	})

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 16,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		ZIndex = card.ZIndex + 1,
		Parent = card,
	})

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = desc,
		TextColor3 = Theme.TextMuted,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		LayoutOrder = 2,
		ZIndex = card.ZIndex + 1,
		Parent = card,
	})

	local btnRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 3,
		ZIndex = card.ZIndex + 1,
		Parent = card,
	})
	makeListLayout(btnRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center)

	local function makeDialogBtn(text, color, callback2)
		local b = create("TextButton", {
			BackgroundColor3 = color,
			Size = UDim2.new(0, 130, 0, 36),
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 13,
			Font = Theme.FontBold,
			BorderSizePixel = 0,
			ZIndex = btnRow.ZIndex + 1,
			ClipsDescendants = true,
			Parent = btnRow,
		})
		makeCorner(b, 8)
		b.MouseButton1Click:Connect(function()
			ripple(b, Mouse.X, Mouse.Y)
			task.wait(0.05)
			tween(overlay, { BackgroundTransparency = 1 }, 0.2)
			tween(card, { BackgroundTransparency = 1 }, 0.2)
			task.wait(0.22)
			DialogOpen = false
			dGui:Destroy()
			callback2()
		end)
		return b
	end

	makeDialogBtn(cancelText, Theme.SurfaceAlt, cancelCallback)
	makeDialogBtn(confirmText, accentColor, confirmCallback)

	tween(overlay, { BackgroundTransparency = 0.5 }, 0.01)
end

function Window:CreateSearchBar(opts)
	opts = opts or {}
	local placeholder = opts.Placeholder or "Search elements..."
	local callback = opts.Callback or function() end

	local searchFrame = create("Frame", {
		BackgroundColor3 = Theme.SurfaceAlt,
		Size = UDim2.new(1, -24, 0, 32),
		Position = UDim2.new(0, 12, 0, 60),
		ZIndex = self.MainFrame.ZIndex + 5,
		Parent = self.MainFrame,
	})
	makeCorner(searchFrame, 8)
	makeStroke(searchFrame, Theme.Border, 1, 0.88)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		Text = "S",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.FontBold,
		ZIndex = searchFrame.ZIndex + 1,
		Parent = searchFrame,
	})

	local box = create("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.new(0, 28, 0, 0),
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = Theme.TextDim,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = searchFrame.ZIndex + 1,
		Parent = searchFrame,
	})

	box:GetPropertyChangedSignal("Text"):Connect(function()
		callback(box.Text)
	end)

	return searchFrame
end

function Window:SetBadge(tabName, text, color)
	for _, t in ipairs(self.Tabs) do
		if t.Name == tabName then
			local existing = t.TabBtn:FindFirstChild("Badge")
			if existing then existing:Destroy() end

			if text then
				local badge = create("Frame", {
					Name = "Badge",
					BackgroundColor3 = color or Theme.Error,
					Size = UDim2.new(0, 18, 0, 16),
					Position = UDim2.new(1, -22, 0.5, -8),
					BorderSizePixel = 0,
					ZIndex = t.TabBtn.ZIndex + 2,
					Parent = t.TabBtn,
				})
				makeCorner(badge, 999)
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = tostring(text),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 9,
					Font = Theme.FontBold,
					ZIndex = badge.ZIndex + 1,
					Parent = badge,
				})
			end
			return
		end
	end
end

function Window:Disable()
	tween(self.MainFrame, { BackgroundTransparency = 0.5 }, 0.2)
	for _, child in ipairs(self.MainFrame:GetDescendants()) do
		if child:IsA("GuiButton") then
			child.Active = false
		end
	end
end

function Window:Enable()
	tween(self.MainFrame, { BackgroundTransparency = 0 }, 0.2)
	for _, child in ipairs(self.MainFrame:GetDescendants()) do
		if child:IsA("GuiButton") then
			child.Active = true
		end
	end
end

function Window:SetTitle(title, subtitle)
	for _, d in ipairs(self.TopBar:GetDescendants()) do
		if d:IsA("TextLabel") then
			if d.TextSize == 16 then
				if title then d.Text = title end
			elseif d.TextSize == 11 then
				if subtitle then d.Text = subtitle end
			end
		end
	end
end

local ContextMenu = {}
ContextMenu.__index = ContextMenu

function EclipseLib:CreateContextMenu(opts)
	opts = opts or {}
	local items = opts.Items or {}

	local self = setmetatable({}, ContextMenu)
	self.Items = items
	self.Open = false

	local gui = getScreenGui()

	self.Frame = create("Frame", {
		BackgroundColor3 = Theme.SurfaceAlt,
		Size = UDim2.new(0, 180, 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 200,
		ClipsDescendants = true,
		Parent = gui,
	})
	makeCorner(self.Frame, 8)
	makeStroke(self.Frame, Theme.Accent, 1, 0.7)
	makePadding(self.Frame, 4, 4, 4, 4)
	makeListLayout(self.Frame, Enum.FillDirection.Vertical, 2)

	function self:Show(x, y)
		self.Open = true
		for _, c in ipairs(self.Frame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, item in ipairs(self.Items) do
			if item == "separator" then
				create("Frame", {
					BackgroundColor3 = Theme.Border,
					BackgroundTransparency = 0.85,
					Size = UDim2.new(1, 0, 0, 1),
					BorderSizePixel = 0,
					ZIndex = self.Frame.ZIndex + 1,
					Parent = self.Frame,
				})
			else
				local btn = create("TextButton", {
					BackgroundColor3 = Theme.SurfaceAlt,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 28),
					Text = "",
					BorderSizePixel = 0,
					ZIndex = self.Frame.ZIndex + 1,
					Parent = self.Frame,
				})
				makeCorner(btn, 6)
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					Text = item.Name or "",
					TextColor3 = item.Color or Theme.Text,
					TextSize = 12,
					Font = Theme.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = btn.ZIndex + 1,
					Parent = btn,
				})
				btn.MouseEnter:Connect(function()
					tween(btn, { BackgroundTransparency = 0.88 }, 0.08)
				end)
				btn.MouseLeave:Connect(function()
					tween(btn, { BackgroundTransparency = 1 }, 0.08)
				end)
				btn.MouseButton1Click:Connect(function()
					self:Hide()
					if item.Callback then item.Callback() end
				end)
			end
		end
		self.Frame.Position = UDim2.new(0, x, 0, y)
		self.Frame.Visible = true
		self.Frame.Size = UDim2.new(0, 180, 0, 0)
		local targetH = #self.Items * 30 + 8
		tween(self.Frame, { Size = UDim2.new(0, 180, 0, targetH) }, 0.18, Enum.EasingStyle.Back)
	end

	function self:Hide()
		self.Open = false
		tween(self.Frame, { Size = UDim2.new(0, 180, 0, 0) }, 0.15)
		task.wait(0.16)
		self.Frame.Visible = false
	end

	UserInputService.InputBegan:Connect(function(input)
		if self.Open and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mPos = Vector2.new(input.Position.X, input.Position.Y)
			local fPos = self.Frame.AbsolutePosition
			local fSize = self.Frame.AbsoluteSize
			if mPos.X < fPos.X or mPos.X > fPos.X + fSize.X or mPos.Y < fPos.Y or mPos.Y > fPos.Y + fSize.Y then
				self:Hide()
			end
		end
	end)

	return self
end

local Tooltip = {}
Tooltip.__index = Tooltip

function EclipseLib:AddTooltip(element, text)
	if not element then return end
	local gui = getScreenGui()

	local tip = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(20, 20, 28),
		Size = UDim2.new(0, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		ZIndex = 300,
		Parent = gui,
	})
	makeCorner(tip, 6)
	makeStroke(tip, Theme.Border, 1, 0.8)
	makePadding(tip, 0, 10, 0, 10)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = text,
		TextColor3 = Theme.TextMuted,
		TextSize = 11,
		Font = Theme.Font,
		ZIndex = tip.ZIndex + 1,
		Parent = tip,
	})

	element.MouseEnter:Connect(function()
		tip.Visible = true
		tip.BackgroundTransparency = 0
	end)
	element.MouseLeave:Connect(function()
		tip.Visible = false
	end)
	element.MouseMoved:Connect(function(x, y)
		tip.Position = UDim2.new(0, x + 14, 0, y - 14)
	end)
end

local ScrollToTop = {}

function Window:AddScrollToTop(tab)
	if not tab or not tab.ContentFrame then return end
	local btn = create("TextButton", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.2,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -40, 1, -40),
		Text = "^",
		TextColor3 = Theme.Text,
		TextSize = 16,
		Font = Theme.FontBold,
		BorderSizePixel = 0,
		ZIndex = self.ContentArea.ZIndex + 5,
		Visible = false,
		Parent = self.ContentArea,
	})
	makeCorner(btn, 999)
	makeStroke(btn, Theme.Accent, 1, 0.5)

	tab.ContentFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		btn.Visible = tab.ContentFrame.CanvasPosition.Y > 60
	end)

	btn.MouseButton1Click:Connect(function()
		tween(tab.ContentFrame, { CanvasPosition = Vector2.new(0, 0) }, 0.4, Enum.EasingStyle.Quart)
	end)
	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundTransparency = 0 }, 0.1)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundTransparency = 0.2 }, 0.1)
	end)
end

local AccentLine = {}

function Window:AddAccentLine()
	local line = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 0, 54),
		BorderSizePixel = 0,
		ZIndex = self.MainFrame.ZIndex + 2,
		Parent = self.MainFrame,
	})
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.AccentHover),
			ColorSequenceKeypoint.new(0.5, Theme.Accent),
			ColorSequenceKeypoint.new(1, Theme.AccentDim),
		}),
		Parent = line,
	})
end

local function makeRainbowLine(parent, zIndex)
	local line = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 0, 54),
		BorderSizePixel = 0,
		ZIndex = (zIndex or 10) + 2,
		Parent = parent,
	})
	local grad = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
			ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
			ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
			ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
		}),
		Parent = grad,
	})
	local hueOffset = 0
	RunService.RenderStepped:Connect(function(dt)
		hueOffset = (hueOffset + dt * 0.3) % 1
		grad.Offset = Vector2.new(-hueOffset, 0)
	end)
	return line
end

function Window:AddRainbowLine()
	makeRainbowLine(self.MainFrame, self.MainFrame.ZIndex)
end

function EclipseLib.Version()
	return "1.0.0"
end

function EclipseLib.Credits()
	return "EclipseLib by EclipseHub"
end

return EclipseLib
