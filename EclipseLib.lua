local EclipseLib = {}
EclipseLib.__index = EclipseLib
EclipseLib.Version = "1.0.0"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui
pcall(function()
    CoreGui = game:GetService("CoreGui")
end)
if not CoreGui then
    CoreGui = gethui and gethui() or Players.LocalPlayer:WaitForChild("PlayerGui")
end

local Player = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 10)
local Mouse = Player and Player:GetMouse()

local Themes = {
    Eclipse = {
        Primary = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(20, 20, 27),
        Tertiary = Color3.fromRGB(25, 25, 35),
        Accent = Color3.fromRGB(138, 43, 226),
        AccentDark = Color3.fromRGB(108, 33, 186),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 180, 190),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69),
        Border = Color3.fromRGB(40, 40, 50)
    },
    Dark = {
        Primary = Color3.fromRGB(18, 18, 18),
        Secondary = Color3.fromRGB(25, 25, 25),
        Tertiary = Color3.fromRGB(32, 32, 32),
        Accent = Color3.fromRGB(100, 100, 255),
        AccentDark = Color3.fromRGB(70, 70, 200),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(160, 160, 160),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(255, 180, 50),
        Error = Color3.fromRGB(255, 80, 80),
        Border = Color3.fromRGB(50, 50, 50)
    },
    Light = {
        Primary = Color3.fromRGB(240, 240, 245),
        Secondary = Color3.fromRGB(250, 250, 255),
        Tertiary = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(100, 100, 230),
        AccentDark = Color3.fromRGB(80, 80, 200),
        Text = Color3.fromRGB(20, 20, 20),
        TextDark = Color3.fromRGB(100, 100, 100),
        Success = Color3.fromRGB(60, 170, 100),
        Warning = Color3.fromRGB(230, 150, 30),
        Error = Color3.fromRGB(220, 60, 60),
        Border = Color3.fromRGB(200, 200, 210)
    }
}

local function Tween(instance, properties, duration, style, direction)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, dragFrame)
    dragFrame = dragFrame or frame
    local dragging, dragInput, dragStart, startPos
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.1)
        end
    end)
end

local function CreateElement(className, properties)
    local element = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        if prop ~= "Parent" then
            element[prop] = value
        end
    end
    if properties.Parent then
        element.Parent = properties.Parent
    end
    return element
end

local function AddCorner(parent, radius)
    return CreateElement("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
end

local function AddStroke(parent, color, thickness)
    return CreateElement("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 70),
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function CreateIcon(parent, imageId)
    return CreateElement("ImageLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. imageId,
        Parent = parent
    })
end

function EclipseLib:CreateWindow(config)
    config = config or {}
    local WindowName = config.Name or "Eclipse"
    local Theme = config.Theme or "Eclipse"
    local Size = config.Size or UDim2.new(0, 580, 0, 460)
    local MinimizeKey = config.MinimizeKey or Enum.KeyCode.RightControl
    
    local CurrentTheme = Themes[Theme] or Themes.Eclipse
    
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.Theme = CurrentTheme
    Window.Minimized = false
    
    local ScreenGui = CreateElement("ScreenGui", {
        Name = "EclipseLibUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    local MainFrame = CreateElement("Frame", {
        Name = "Main",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset/2, 0.5, -Size.Y.Offset/2),
        BackgroundColor3 = CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = ScreenGui
    })
    AddCorner(MainFrame, 12)
    AddStroke(MainFrame, CurrentTheme.Border, 1)
    
    local Shadow = CreateElement("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Parent = MainFrame,
        ZIndex = 0
    })
    
    local TopBar = CreateElement("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    AddCorner(TopBar, 12)
    
    local TopBarMask = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 1, -25),
        BackgroundColor3 = CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Parent = TopBar
    })
    
    local TitleLabel = CreateElement("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 55, 0, 0),
        BackgroundTransparency = 1,
        Text = WindowName,
        TextColor3 = CurrentTheme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })
    
    local LogoIcon = CreateElement("ImageLabel", {
        Name = "Logo",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 12, 0, 9),
        BackgroundTransparency = 1,
        Image = "rbxassetid://127164778782059",
        Parent = TopBar
    })
    
    local MinimizeButton = CreateElement("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -82, 0, 7.5),
        BackgroundColor3 = CurrentTheme.Tertiary,
        BorderSizePixel = 0,
        Text = "",
        Parent = TopBar
    })
    AddCorner(MinimizeButton, 8)
    
    local MinimizeIcon = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = CurrentTheme.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        Parent = MinimizeButton
    })
    
    local CloseButton = CreateElement("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -42, 0, 7.5),
        BackgroundColor3 = CurrentTheme.Tertiary,
        BorderSizePixel = 0,
        Text = "",
        Parent = TopBar
    })
    AddCorner(CloseButton, 8)
    
    local CloseIcon = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = CurrentTheme.Error,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        Parent = CloseButton
    })
    
    local TabContainer = CreateElement("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 160, 1, -60),
        Position = UDim2.new(0, 10, 0, 55),
        BackgroundColor3 = CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    AddCorner(TabContainer, 10)
    
    local TabList = CreateElement("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CurrentTheme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = TabContainer
    })
    
    local TabListLayout = CreateElement("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = TabList
    })
    
    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local ContentContainer = CreateElement("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -185, 1, -60),
        Position = UDim2.new(0, 175, 0, 55),
        BackgroundColor3 = CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    AddCorner(ContentContainer, 10)
    
    MakeDraggable(MainFrame, TopBar)
    
    MinimizeButton.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            Tween(MainFrame, {Size = UDim2.new(0, Size.X.Offset, 0, 50)}, 0.3)
            MinimizeIcon.Text = "+"
        else
            Tween(MainFrame, {Size = Size}, 0.3)
            MinimizeIcon.Text = "-"
        end
    end)
    
    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = CurrentTheme.Error}, 0.2)
        CloseIcon.TextColor3 = CurrentTheme.Text
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
        CloseIcon.TextColor3 = CurrentTheme.Error
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == MinimizeKey then
            Window.Minimized = not Window.Minimized
            if Window.Minimized then
                Tween(MainFrame, {Size = UDim2.new(0, Size.X.Offset, 0, 50)}, 0.3)
                MinimizeIcon.Text = "+"
            else
                Tween(MainFrame, {Size = Size}, 0.3)
                MinimizeIcon.Text = "-"
            end
        end
    end)
    
    function Window:CreateTab(config)
        config = config or {}
        local TabName = config.Name or "Tab"
        local Icon = config.Icon
        
        local Tab = {}
        Tab.Elements = {}
        Tab.Active = false
        
        local TabButton = CreateElement("TextButton", {
            Name = "TabButton",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = CurrentTheme.Tertiary,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = TabList
        })
        AddCorner(TabButton, 8)
        
        local TabIcon = Icon and CreateElement("ImageLabel", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. Icon,
            ImageColor3 = CurrentTheme.TextDark,
            Parent = TabButton
        })
        
        local TabLabel = CreateElement("TextLabel", {
            Size = UDim2.new(1, Icon and -40 or -20, 1, 0),
            Position = UDim2.new(0, Icon and 35 or 10, 0, 0),
            BackgroundTransparency = 1,
            Text = TabName,
            TextColor3 = CurrentTheme.TextDark,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton
        })
        
        local TabContent = CreateElement("ScrollingFrame", {
            Name = "TabContent",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = CurrentTheme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = ContentContainer
        })
        
        local ContentLayout = CreateElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = TabContent
        })
        
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
        end)
        
        local function SelectTab()
            for _, tab in pairs(Window.Tabs) do
                tab.Active = false
                tab.Button.BackgroundColor3 = CurrentTheme.Tertiary
                tab.Label.TextColor3 = CurrentTheme.TextDark
                if tab.Icon then
                    tab.Icon.ImageColor3 = CurrentTheme.TextDark
                end
                tab.Content.Visible = false
            end
            
            Tab.Active = true
            Tween(TabButton, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
            TabLabel.TextColor3 = CurrentTheme.Text
            if TabIcon then
                TabIcon.ImageColor3 = CurrentTheme.Text
            end
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        TabButton.MouseButton1Click:Connect(SelectTab)
        
        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                Tween(TabButton, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
            end
        end)
        
        Tab.Button = TabButton
        Tab.Label = TabLabel
        Tab.Icon = TabIcon
        Tab.Content = TabContent
        
        if #Window.Tabs == 0 then
            SelectTab()
        end
        
        table.insert(Window.Tabs, Tab)
        
        function Tab:CreateSection(name)
            local SectionFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundTransparency = 1,
                Parent = TabContent
            })
            
            local SectionLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = CurrentTheme.Text,
                TextSize = 15,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SectionFrame
            })
            
            local SectionLine = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = CurrentTheme.Border,
                BorderSizePixel = 0,
                Parent = SectionFrame
            })
            
            return SectionFrame
        end
        
        function Tab:CreateButton(config)
            config = config or {}
            local ButtonName = config.Name or "Button"
            local Description = config.Description
            local Callback = config.Callback or function() end
            
            local ButtonHeight = Description and 60 or 40
            
            local ButtonFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, ButtonHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(ButtonFrame, 8)
            
            local ButtonObject = CreateElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = ButtonFrame
            })
            
            local ButtonLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, Description and -20 or -50, Description and 0 or 1, Description and 20 or 0),
                Position = UDim2.new(0, 15, 0, Description and 8 or 0),
                BackgroundTransparency = 1,
                Text = ButtonName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ButtonFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = ButtonFrame
                })
            end
            
            local ButtonIndicator = CreateElement("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(1, -20, 0.5, -4),
                BackgroundColor3 = CurrentTheme.Accent,
                BorderSizePixel = 0,
                Parent = ButtonFrame
            })
            AddCorner(ButtonIndicator, 4)
            
            ButtonObject.MouseButton1Click:Connect(function()
                Tween(ButtonIndicator, {BackgroundColor3 = CurrentTheme.Success}, 0.2)
                task.wait(0.1)
                Tween(ButtonIndicator, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
                
                local success, err = pcall(Callback)
                if not success then
                    warn("Button callback error: " .. tostring(err))
                end
            end)
            
            ButtonObject.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
            end)
            
            ButtonObject.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
            end)
            
            return {Frame = ButtonFrame, Button = ButtonObject}
        end
        
        function Tab:CreateToggle(config)
            config = config or {}
            local ToggleName = config.Name or "Toggle"
            local Description = config.Description
            local Default = config.Default or false
            local Callback = config.Callback or function() end
            
            local ToggleState = Default
            local ToggleHeight = Description and 60 or 40
            
            local ToggleFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, ToggleHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(ToggleFrame, 8)
            
            local ToggleLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, Description and -70 or -70, Description and 0 or 1, Description and 20 or 0),
                Position = UDim2.new(0, 15, 0, Description and 8 or 0),
                BackgroundTransparency = 1,
                Text = ToggleName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ToggleFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -70, 0, 25),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = ToggleFrame
                })
            end
            
            local ToggleButton = CreateElement("TextButton", {
                Size = UDim2.new(0, 45, 0, 22),
                Position = UDim2.new(1, -55, 0.5, -11),
                BackgroundColor3 = ToggleState and CurrentTheme.Accent or CurrentTheme.Border,
                BorderSizePixel = 0,
                Text = "",
                Parent = ToggleFrame
            })
            AddCorner(ToggleButton, 11)
            
            local ToggleCircle = CreateElement("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = ToggleState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = CurrentTheme.Text,
                BorderSizePixel = 0,
                Parent = ToggleButton
            })
            AddCorner(ToggleCircle, 9)
            
            local function UpdateToggle(newState)
                ToggleState = newState
                Tween(ToggleButton, {BackgroundColor3 = ToggleState and CurrentTheme.Accent or CurrentTheme.Border}, 0.2)
                Tween(ToggleCircle, {Position = ToggleState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.2)
                
                local success, err = pcall(Callback, ToggleState)
                if not success then
                    warn("Toggle callback error: " .. tostring(err))
                end
            end
            
            ToggleButton.MouseButton1Click:Connect(function()
                UpdateToggle(not ToggleState)
            end)
            
            ToggleButton.MouseEnter:Connect(function()
                Tween(ToggleButton, {BackgroundColor3 = ToggleState and CurrentTheme.AccentDark or CurrentTheme.Border}, 0.2)
            end)
            
            ToggleButton.MouseLeave:Connect(function()
                Tween(ToggleButton, {BackgroundColor3 = ToggleState and CurrentTheme.Accent or CurrentTheme.Border}, 0.2)
            end)
            
            return {
                Frame = ToggleFrame,
                Set = UpdateToggle,
                GetState = function() return ToggleState end
            }
        end
        
        function Tab:CreateSlider(config)
            config = config or {}
            local SliderName = config.Name or "Slider"
            local Description = config.Description
            local Min = config.Min or 0
            local Max = config.Max or 100
            local Default = config.Default or Min
            local Increment = config.Increment or 1
            local Callback = config.Callback or function() end
            
            local SliderValue = Default
            local Dragging = false
            local SliderHeight = Description and 75 or 55
            
            local SliderFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, SliderHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(SliderFrame, 8)
            
            local SliderLabel = CreateElement("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = SliderName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SliderFrame
            })
            
            local SliderValueLabel = CreateElement("TextLabel", {
                Size = UDim2.new(0.25, 0, 0, 20),
                Position = UDim2.new(0.7, 0, 0, 8),
                BackgroundTransparency = 1,
                Text = tostring(SliderValue),
                TextColor3 = CurrentTheme.Accent,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = SliderFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 15),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = SliderFrame
                })
            end
            
            local SliderTrack = CreateElement("Frame", {
                Size = UDim2.new(1, -30, 0, 6),
                Position = UDim2.new(0, 15, 1, Description and -18 or -18),
                BackgroundColor3 = CurrentTheme.Border,
                BorderSizePixel = 0,
                Parent = SliderFrame
            })
            AddCorner(SliderTrack, 3)
            
            local SliderFill = CreateElement("Frame", {
                Size = UDim2.new((SliderValue - Min) / (Max - Min), 0, 1, 0),
                BackgroundColor3 = CurrentTheme.Accent,
                BorderSizePixel = 0,
                Parent = SliderTrack
            })
            AddCorner(SliderFill, 3)
            
            local SliderButton = CreateElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = SliderTrack
            })
            
            local function UpdateSlider(value)
                value = math.clamp(value, Min, Max)
                value = math.floor(value / Increment + 0.5) * Increment
                SliderValue = value
                
                SliderValueLabel.Text = tostring(value)
                Tween(SliderFill, {Size = UDim2.new((value - Min) / (Max - Min), 0, 1, 0)}, 0.1)
                
                local success, err = pcall(Callback, value)
                if not success then
                    warn("Slider callback error: " .. tostring(err))
                end
            end
            
            local function GetSliderValue(input)
                local posX = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                return Min + (Max - Min) * posX
            end
            
            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true
                    UpdateSlider(GetSliderValue(input))
                end
            end)
            
            SliderButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(GetSliderValue(input))
                end
            end)
            
            UpdateSlider(Default)
            
            return {
                Frame = SliderFrame,
                Set = UpdateSlider,
                GetValue = function() return SliderValue end
            }
        end
        
        function Tab:CreateInput(config)
            config = config or {}
            local InputName = config.Name or "Input"
            local Description = config.Description
            local Placeholder = config.Placeholder or "Enter text..."
            local Default = config.Default or ""
            local Callback = config.Callback or function() end
            
            local InputHeight = Description and 70 or 50
            
            local InputFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, InputHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(InputFrame, 8)
            
            local InputLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = InputName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = InputFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 12),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = InputFrame
                })
            end
            
            local InputBox = CreateElement("TextBox", {
                Size = UDim2.new(1, -30, 0, 25),
                Position = UDim2.new(0, 15, 1, Description and -32 or -32),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Text = Default,
                PlaceholderText = Placeholder,
                TextColor3 = CurrentTheme.Text,
                PlaceholderColor3 = CurrentTheme.TextDark,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                Parent = InputFrame
            })
            AddCorner(InputBox, 6)
            AddStroke(InputBox, CurrentTheme.Border, 1)
            
            InputBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local success, err = pcall(Callback, InputBox.Text)
                    if not success then
                        warn("Input callback error: " .. tostring(err))
                    end
                end
            end)
            
            return {
                Frame = InputFrame,
                GetValue = function() return InputBox.Text end,
                Set = function(text) InputBox.Text = text end
            }
        end
        
        function Tab:CreateDropdown(config)
            config = config or {}
            local DropdownName = config.Name or "Dropdown"
            local Description = config.Description
            local Options = config.Options or {}
            local Default = config.Default
            local Callback = config.Callback or function() end
            
            local DropdownOpen = false
            local SelectedOption = Default or (Options[1] or "None")
            local DropdownHeight = Description and 70 or 50
            
            local DropdownFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, DropdownHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent,
                ClipsDescendants = true
            })
            AddCorner(DropdownFrame, 8)
            
            local DropdownLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = DropdownName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = DropdownFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 12),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = DropdownFrame
                })
            end
            
            local DropdownButton = CreateElement("TextButton", {
                Size = UDim2.new(1, -30, 0, 25),
                Position = UDim2.new(0, 15, 1, Description and -32 or -32),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Text = "",
                Parent = DropdownFrame
            })
            AddCorner(DropdownButton, 6)
            AddStroke(DropdownButton, CurrentTheme.Border, 1)
            
            local DropdownText = CreateElement("TextLabel", {
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = SelectedOption,
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = DropdownButton
            })
            
            local DropdownArrow = CreateElement("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -25, 0, 0),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = CurrentTheme.TextDark,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                Parent = DropdownButton
            })
            
            local OptionsList = CreateElement("Frame", {
                Size = UDim2.new(1, -30, 0, 0),
                Position = UDim2.new(0, 15, 1, Description and -7 or -7),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Parent = DropdownFrame,
                ClipsDescendants = true
            })
            AddCorner(OptionsList, 6)
            AddStroke(OptionsList, CurrentTheme.Border, 1)
            
            local OptionsLayout = CreateElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
                Parent = OptionsList
            })
            
            local function UpdateDropdown(option)
                SelectedOption = option
                DropdownText.Text = option
                DropdownOpen = false
                
                Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, DropdownHeight)}, 0.2)
                Tween(DropdownArrow, {Rotation = 0}, 0.2)
                Tween(OptionsList, {Size = UDim2.new(1, -30, 0, 0)}, 0.2)
                
                local success, err = pcall(Callback, option)
                if not success then
                    warn("Dropdown callback error: " .. tostring(err))
                end
            end
            
            for i, option in ipairs(Options) do
                local OptionButton = CreateElement("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = option == SelectedOption and CurrentTheme.Accent or CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = OptionsList
                })
                
                local OptionLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = option,
                    TextColor3 = CurrentTheme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = OptionButton
                })
                
                OptionButton.MouseButton1Click:Connect(function()
                    UpdateDropdown(option)
                    
                    for _, btn in ipairs(OptionsList:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
                        end
                    end
                    Tween(OptionButton, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    if option ~= SelectedOption then
                        Tween(OptionButton, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
                    end
                end)
            end
            
            DropdownButton.MouseButton1Click:Connect(function()
                DropdownOpen = not DropdownOpen
                
                if DropdownOpen then
                    local optionsHeight = #Options * 30
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, DropdownHeight + optionsHeight + 10)}, 0.2)
                    Tween(DropdownArrow, {Rotation = 180}, 0.2)
                    Tween(OptionsList, {Size = UDim2.new(1, -30, 0, optionsHeight)}, 0.2)
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, DropdownHeight)}, 0.2)
                    Tween(DropdownArrow, {Rotation = 0}, 0.2)
                    Tween(OptionsList, {Size = UDim2.new(1, -30, 0, 0)}, 0.2)
                end
            end)
            
            if Default then
                UpdateDropdown(Default)
            end
            
            return {
                Frame = DropdownFrame,
                GetValue = function() return SelectedOption end,
                Set = UpdateDropdown
            }
        end
        
        function Tab:CreateColorPicker(config)
            config = config or {}
            local ColorName = config.Name or "Color Picker"
            local Description = config.Description
            local Default = config.Default or Color3.fromRGB(255, 255, 255)
            local Callback = config.Callback or function() end
            
            local SelectedColor = Default
            local PickerOpen = false
            local PickerHeight = Description and 70 or 50
            
            local ColorFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, PickerHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent,
                ClipsDescendants = true
            })
            AddCorner(ColorFrame, 8)
            
            local ColorLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -70, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = ColorName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ColorFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -70, 0, 12),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = ColorFrame
                })
            end
            
            local ColorDisplay = CreateElement("TextButton", {
                Size = UDim2.new(0, 35, 0, 25),
                Position = UDim2.new(1, -50, 1, Description and -32 or -32),
                BackgroundColor3 = SelectedColor,
                BorderSizePixel = 0,
                Text = "",
                Parent = ColorFrame
            })
            AddCorner(ColorDisplay, 6)
            AddStroke(ColorDisplay, CurrentTheme.Border, 2)
            
            local ColorPalette = CreateElement("Frame", {
                Size = UDim2.new(1, -30, 0, 0),
                Position = UDim2.new(0, 15, 1, Description and -7 or -7),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Parent = ColorFrame,
                ClipsDescendants = true
            })
            AddCorner(ColorPalette, 6)
            AddStroke(ColorPalette, CurrentTheme.Border, 1)
            
            local Hue, Sat, Val = Default:ToHSV()
            
            local HueSlider = CreateElement("Frame", {
                Size = UDim2.new(1, -20, 0, 12),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = ColorPalette
            })
            AddCorner(HueSlider, 6)
            
            local HueGradient = CreateElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                }),
                Parent = HueSlider
            })
            
            local HueButton = CreateElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = HueSlider
            })
            
            local HueIndicator = CreateElement("Frame", {
                Size = UDim2.new(0, 4, 1, 4),
                Position = UDim2.new(Hue, -2, 0, -2),
                BackgroundColor3 = CurrentTheme.Text,
                BorderSizePixel = 0,
                Parent = HueSlider
            })
            AddCorner(HueIndicator, 2)
            
            local SatValFrame = CreateElement("Frame", {
                Size = UDim2.new(1, -20, 0, 100),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
                BorderSizePixel = 0,
                Parent = ColorPalette
            })
            AddCorner(SatValFrame, 6)
            
            local SatGradient = CreateElement("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Parent = SatValFrame
            })
            
            local ValOverlay = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BorderSizePixel = 0,
                Parent = SatValFrame
            })
            AddCorner(ValOverlay, 6)
            
            local ValGradient = CreateElement("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                }),
                Parent = ValOverlay
            })
            
            local SatValButton = CreateElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = SatValFrame,
                ZIndex = 3
            })
            
            local SatValIndicator = CreateElement("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(Sat, -4, 1 - Val, -4),
                BackgroundColor3 = CurrentTheme.Text,
                BorderSizePixel = 0,
                Parent = SatValFrame,
                ZIndex = 4
            })
            AddCorner(SatValIndicator, 4)
            AddStroke(SatValIndicator, Color3.fromRGB(0, 0, 0), 2)
            
            local function UpdateColor()
                SelectedColor = Color3.fromHSV(Hue, Sat, Val)
                ColorDisplay.BackgroundColor3 = SelectedColor
                SatValFrame.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                
                local success, err = pcall(Callback, SelectedColor)
                if not success then
                    warn("ColorPicker callback error: " .. tostring(err))
                end
            end
            
            local hueDragging = false
            HueButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = true
                    local posX = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                    Hue = posX
                    Tween(HueIndicator, {Position = UDim2.new(posX, -2, 0, -2)}, 0.1)
                    UpdateColor()
                end
            end)
            
            HueButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local posX = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                    Hue = posX
                    Tween(HueIndicator, {Position = UDim2.new(posX, -2, 0, -2)}, 0.1)
                    UpdateColor()
                end
            end)
            
            local satValDragging = false
            SatValButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    satValDragging = true
                    local posX = math.clamp((input.Position.X - SatValFrame.AbsolutePosition.X) / SatValFrame.AbsoluteSize.X, 0, 1)
                    local posY = math.clamp((input.Position.Y - SatValFrame.AbsolutePosition.Y) / SatValFrame.AbsoluteSize.Y, 0, 1)
                    Sat = posX
                    Val = 1 - posY
                    Tween(SatValIndicator, {Position = UDim2.new(posX, -4, posY, -4)}, 0.1)
                    UpdateColor()
                end
            end)
            
            SatValButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    satValDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if satValDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local posX = math.clamp((input.Position.X - SatValFrame.AbsolutePosition.X) / SatValFrame.AbsoluteSize.X, 0, 1)
                    local posY = math.clamp((input.Position.Y - SatValFrame.AbsolutePosition.Y) / SatValFrame.AbsoluteSize.Y, 0, 1)
                    Sat = posX
                    Val = 1 - posY
                    Tween(SatValIndicator, {Position = UDim2.new(posX, -4, posY, -4)}, 0.1)
                    UpdateColor()
                end
            end)
            
            ColorDisplay.MouseButton1Click:Connect(function()
                PickerOpen = not PickerOpen
                
                if PickerOpen then
                    Tween(ColorFrame, {Size = UDim2.new(1, 0, 0, PickerHeight + 150)}, 0.2)
                    Tween(ColorPalette, {Size = UDim2.new(1, -30, 0, 145)}, 0.2)
                else
                    Tween(ColorFrame, {Size = UDim2.new(1, 0, 0, PickerHeight)}, 0.2)
                    Tween(ColorPalette, {Size = UDim2.new(1, -30, 0, 0)}, 0.2)
                end
            end)
            
            return {
                Frame = ColorFrame,
                GetValue = function() return SelectedColor end,
                Set = function(color)
                    SelectedColor = color
                    Hue, Sat, Val = color:ToHSV()
                    ColorDisplay.BackgroundColor3 = color
                    SatValFrame.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                    HueIndicator.Position = UDim2.new(Hue, -2, 0, -2)
                    SatValIndicator.Position = UDim2.new(Sat, -4, 1 - Val, -4)
                end
            }
        end
        
        function Tab:CreateLabel(config)
            config = config or {}
            local Text = config.Text or "Label"
            local Size = config.Size or 13
            local Color = config.Color or CurrentTheme.Text
            
            local LabelFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Parent = TabContent
            })
            
            local Label = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = Text,
                TextColor3 = Color,
                TextSize = Size,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = LabelFrame
            })
            
            return {
                Frame = LabelFrame,
                SetText = function(text) Label.Text = text end,
                SetColor = function(color) Label.TextColor3 = color end
            }
        end
        
        function Tab:CreateParagraph(config)
            config = config or {}
            local Title = config.Title or "Paragraph"
            local Content = config.Content or "Content"
            
            local ParagraphFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, 70),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(ParagraphFrame, 8)
            
            local TitleLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 8),
                BackgroundTransparency = 1,
                Text = Title,
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ParagraphFrame
            })
            
            local ContentLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 1, -35),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundTransparency = 1,
                Text = Content,
                TextColor3 = CurrentTheme.TextDark,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Parent = ParagraphFrame
            })
            
            return {
                Frame = ParagraphFrame,
                SetTitle = function(text) TitleLabel.Text = text end,
                SetContent = function(text) ContentLabel.Text = text end
            }
        end
        
        function Tab:CreateKeybind(config)
            config = config or {}
            local KeybindName = config.Name or "Keybind"
            local Description = config.Description
            local Default = config.Default or Enum.KeyCode.E
            local Callback = config.Callback or function() end
            
            local CurrentKey = Default
            local Binding = false
            local KeybindHeight = Description and 60 or 40
            
            local KeybindFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, KeybindHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(KeybindFrame, 8)
            
            local KeybindLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, Description and -100 or -100, Description and 0 or 1, Description and 20 or 0),
                Position = UDim2.new(0, 15, 0, Description and 8 or 0),
                BackgroundTransparency = 1,
                Text = KeybindName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = KeybindFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -100, 0, 25),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = KeybindFrame
                })
            end
            
            local KeybindButton = CreateElement("TextButton", {
                Size = UDim2.new(0, 75, 0, 25),
                Position = UDim2.new(1, -85, 0.5, -12.5),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Text = CurrentKey.Name,
                TextColor3 = CurrentTheme.Text,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = KeybindFrame
            })
            AddCorner(KeybindButton, 6)
            AddStroke(KeybindButton, CurrentTheme.Border, 1)
            
            KeybindButton.MouseButton1Click:Connect(function()
                Binding = true
                KeybindButton.Text = "..."
                Tween(KeybindButton, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
            end)
            
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if Binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    CurrentKey = input.KeyCode
                    KeybindButton.Text = CurrentKey.Name
                    Binding = false
                    Tween(KeybindButton, {BackgroundColor3 = CurrentTheme.Primary}, 0.2)
                end
                
                if not gameProcessed and input.KeyCode == CurrentKey and not Binding then
                    local success, err = pcall(Callback)
                    if not success then
                        warn("Keybind callback error: " .. tostring(err))
                    end
                end
            end)
            
            return {
                Frame = KeybindFrame,
                GetKey = function() return CurrentKey end,
                Set = function(key)
                    CurrentKey = key
                    KeybindButton.Text = key.Name
                end
            }
        end
        
        function Tab:CreateDivider()
            local DividerFrame = CreateElement("Frame", {
                Size = UDim2.new(1, -20, 0, 1),
                BackgroundColor3 = CurrentTheme.Border,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            
            return {Frame = DividerFrame}
        end
        
        function Tab:CreateProgressBar(config)
            config = config or {}
            local ProgressName = config.Name or "Progress"
            local Description = config.Description
            local Value = config.Value or 0
            local Max = config.Max or 100
            
            local ProgressHeight = Description and 65 or 45
            
            local ProgressFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, ProgressHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(ProgressFrame, 8)
            
            local ProgressLabel = CreateElement("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = ProgressName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ProgressFrame
            })
            
            local ProgressValueLabel = CreateElement("TextLabel", {
                Size = UDim2.new(0.25, 0, 0, 20),
                Position = UDim2.new(0.7, 0, 0, 8),
                BackgroundTransparency = 1,
                Text = math.floor((Value / Max) * 100) .. "%",
                TextColor3 = CurrentTheme.Accent,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = ProgressFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 12),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = ProgressFrame
                })
            end
            
            local BarBackground = CreateElement("Frame", {
                Size = UDim2.new(1, -30, 0, 8),
                Position = UDim2.new(0, 15, 1, Description and -18 or -18),
                BackgroundColor3 = CurrentTheme.Border,
                BorderSizePixel = 0,
                Parent = ProgressFrame
            })
            AddCorner(BarBackground, 4)
            
            local BarFill = CreateElement("Frame", {
                Size = UDim2.new(Value / Max, 0, 1, 0),
                BackgroundColor3 = CurrentTheme.Accent,
                BorderSizePixel = 0,
                Parent = BarBackground
            })
            AddCorner(BarFill, 4)
            
            return {
                Frame = ProgressFrame,
                Set = function(value)
                    value = math.clamp(value, 0, Max)
                    ProgressValueLabel.Text = math.floor((value / Max) * 100) .. "%"
                    Tween(BarFill, {Size = UDim2.new(value / Max, 0, 1, 0)}, 0.3)
                end,
                GetValue = function()
                    return Value
                end
            }
        end
        
        function Tab:CreateMultiDropdown(config)
            config = config or {}
            local DropdownName = config.Name or "Multi Dropdown"
            local Description = config.Description
            local Options = config.Options or {}
            local Default = config.Default or {}
            local Callback = config.Callback or function() end
            
            local DropdownOpen = false
            local SelectedOptions = {}
            for _, opt in ipairs(Default) do
                SelectedOptions[opt] = true
            end
            
            local DropdownHeight = Description and 70 or 50
            
            local DropdownFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, DropdownHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent,
                ClipsDescendants = true
            })
            AddCorner(DropdownFrame, 8)
            
            local DropdownLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = DropdownName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = DropdownFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 12),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = DropdownFrame
                })
            end
            
            local DropdownButton = CreateElement("TextButton", {
                Size = UDim2.new(1, -30, 0, 25),
                Position = UDim2.new(0, 15, 1, Description and -32 or -32),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Text = "",
                Parent = DropdownFrame
            })
            AddCorner(DropdownButton, 6)
            AddStroke(DropdownButton, CurrentTheme.Border, 1)
            
            local function GetSelectedText()
                local selected = {}
                for opt, val in pairs(SelectedOptions) do
                    if val then table.insert(selected, opt) end
                end
                if #selected == 0 then
                    return "None Selected"
                elseif #selected == 1 then
                    return selected[1]
                else
                    return selected[1] .. " + " .. (#selected - 1) .. " more"
                end
            end
            
            local DropdownText = CreateElement("TextLabel", {
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = GetSelectedText(),
                TextColor3 = CurrentTheme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = DropdownButton
            })
            
            local DropdownArrow = CreateElement("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -25, 0, 0),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = CurrentTheme.TextDark,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                Parent = DropdownButton
            })
            
            local OptionsList = CreateElement("ScrollingFrame", {
                Size = UDim2.new(1, -30, 0, 0),
                Position = UDim2.new(0, 15, 1, Description and -7 or -7),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = CurrentTheme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                Parent = DropdownFrame,
                ClipsDescendants = true
            })
            AddCorner(OptionsList, 6)
            AddStroke(OptionsList, CurrentTheme.Border, 1)
            
            local OptionsLayout = CreateElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
                Parent = OptionsList
            })
            
            OptionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                OptionsList.CanvasSize = UDim2.new(0, 0, 0, OptionsLayout.AbsoluteContentSize.Y + 5)
            end)
            
            local function UpdateCallback()
                local selected = {}
                for opt, val in pairs(SelectedOptions) do
                    if val then table.insert(selected, opt) end
                end
                
                local success, err = pcall(Callback, selected)
                if not success then
                    warn("Multi-dropdown callback error: " .. tostring(err))
                end
            end
            
            for i, option in ipairs(Options) do
                local OptionFrame = CreateElement("Frame", {
                    Size = UDim2.new(1, -4, 0, 28),
                    BackgroundColor3 = CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Parent = OptionsList
                })
                AddCorner(OptionFrame, 4)
                
                local OptionButton = CreateElement("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = OptionFrame
                })
                
                local Checkbox = CreateElement("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 8, 0.5, -8),
                    BackgroundColor3 = SelectedOptions[option] and CurrentTheme.Accent or CurrentTheme.Border,
                    BorderSizePixel = 0,
                    Parent = OptionFrame
                })
                AddCorner(Checkbox, 4)
                
                local Checkmark = CreateElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = SelectedOptions[option] and "✓" or "",
                    TextColor3 = CurrentTheme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    Parent = Checkbox
                })
                
                local OptionLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -35, 1, 0),
                    Position = UDim2.new(0, 30, 0, 0),
                    BackgroundTransparency = 1,
                    Text = option,
                    TextColor3 = CurrentTheme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = OptionFrame
                })
                
                OptionButton.MouseButton1Click:Connect(function()
                    SelectedOptions[option] = not SelectedOptions[option]
                    
                    if SelectedOptions[option] then
                        Tween(Checkbox, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
                        Checkmark.Text = "✓"
                    else
                        Tween(Checkbox, {BackgroundColor3 = CurrentTheme.Border}, 0.2)
                        Checkmark.Text = ""
                    end
                    
                    DropdownText.Text = GetSelectedText()
                    UpdateCallback()
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    Tween(OptionFrame, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Tween(OptionFrame, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
                end)
            end
            
            DropdownButton.MouseButton1Click:Connect(function()
                DropdownOpen = not DropdownOpen
                
                if DropdownOpen then
                    local maxHeight = math.min(#Options * 30, 150)
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, DropdownHeight + maxHeight + 10)}, 0.2)
                    Tween(DropdownArrow, {Rotation = 180}, 0.2)
                    Tween(OptionsList, {Size = UDim2.new(1, -30, 0, maxHeight)}, 0.2)
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, DropdownHeight)}, 0.2)
                    Tween(DropdownArrow, {Rotation = 0}, 0.2)
                    Tween(OptionsList, {Size = UDim2.new(1, -30, 0, 0)}, 0.2)
                end
            end)
            
            return {
                Frame = DropdownFrame,
                GetSelected = function()
                    local selected = {}
                    for opt, val in pairs(SelectedOptions) do
                        if val then table.insert(selected, opt) end
                    end
                    return selected
                end,
                Set = function(options)
                    SelectedOptions = {}
                    for _, opt in ipairs(options) do
                        SelectedOptions[opt] = true
                    end
                    DropdownText.Text = GetSelectedText()
                    
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child:IsA("Frame") then
                            local optName = child:FindFirstChild("OptionLabel", true)
                            if optName then
                                local checkbox = child:FindFirstChild("Checkbox", true)
                                local checkmark = checkbox and checkbox:FindFirstChild("Checkmark")
                                if SelectedOptions[optName.Text] then
                                    checkbox.BackgroundColor3 = CurrentTheme.Accent
                                    if checkmark then checkmark.Text = "✓" end
                                else
                                    checkbox.BackgroundColor3 = CurrentTheme.Border
                                    if checkmark then checkmark.Text = "" end
                                end
                            end
                        end
                    end
                    UpdateCallback()
                end
            }
        end
        
        function Tab:CreateSearch(config)
            config = config or {}
            local SearchName = config.Name or "Search"
            local Description = config.Description
            local Placeholder = config.Placeholder or "Search..."
            local Items = config.Items or {}
            local Callback = config.Callback or function() end
            
            local SearchHeight = Description and 70 or 50
            
            local SearchFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, SearchHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(SearchFrame, 8)
            
            local SearchLabel = CreateElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 15, 0, 8),
                BackgroundTransparency = 1,
                Text = SearchName,
                TextColor3 = CurrentTheme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SearchFrame
            })
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 12),
                    Position = UDim2.new(0, 15, 0, 28),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.TextDark,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = SearchFrame
                })
            end
            
            local SearchBox = CreateElement("TextBox", {
                Size = UDim2.new(1, -30, 0, 25),
                Position = UDim2.new(0, 15, 1, Description and -32 or -32),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Text = "",
                PlaceholderText = Placeholder,
                TextColor3 = CurrentTheme.Text,
                PlaceholderColor3 = CurrentTheme.TextDark,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                Parent = SearchFrame
            })
            AddCorner(SearchBox, 6)
            AddStroke(SearchBox, CurrentTheme.Border, 1)
            
            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = SearchBox.Text:lower()
                local results = {}
                
                for _, item in ipairs(Items) do
                    if item:lower():find(query) then
                        table.insert(results, item)
                    end
                end
                
                local success, err = pcall(Callback, results, query)
                if not success then
                    warn("Search callback error: " .. tostring(err))
                end
            end)
            
            return {
                Frame = SearchFrame,
                GetQuery = function() return SearchBox.Text end,
                Clear = function() SearchBox.Text = "" end
            }
        end
        
        function Tab:CreateImage(config)
            config = config or {}
            local ImageId = config.Image or ""
            local Size = config.Size or UDim2.new(1, -20, 0, 150)
            local Description = config.Description
            
            local ImageHeight = Size.Y.Offset + (Description and 35 or 15)
            
            local ImageFrame = CreateElement("Frame", {
                Size = UDim2.new(1, 0, 0, ImageHeight),
                BackgroundColor3 = CurrentTheme.Tertiary,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            AddCorner(ImageFrame, 8)
            
            if Description then
                local DescLabel = CreateElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 18),
                    Position = UDim2.new(0, 10, 0, 8),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = CurrentTheme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ImageFrame
                })
            end
            
            local Image = CreateElement("ImageLabel", {
                Size = Size,
                Position = UDim2.new(0, 10, 0, Description and 28 or 8),
                BackgroundColor3 = CurrentTheme.Primary,
                BorderSizePixel = 0,
                Image = "rbxassetid://" .. ImageId,
                ScaleType = Enum.ScaleType.Fit,
                Parent = ImageFrame
            })
            AddCorner(Image, 6)
            
            return {
                Frame = ImageFrame,
                SetImage = function(id) Image.Image = "rbxassetid://" .. id end
            }
        end
        
        return Tab
    end
    
    function Window:CreateNotification(config)
        config = config or {}
        local Title = config.Title or "Notification"
        local Content = config.Content or ""
        local Duration = config.Duration or 3
        local Type = config.Type or "Info"
        
        local TypeColors = {
            Info = CurrentTheme.Accent,
            Success = CurrentTheme.Success,
            Warning = CurrentTheme.Warning,
            Error = CurrentTheme.Error
        }
        
        local NotificationFrame = CreateElement("Frame", {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(1, -20, 1, -20),
            BackgroundColor3 = CurrentTheme.Secondary,
            BorderSizePixel = 0,
            Parent = ScreenGui,
            ZIndex = 1000
        })
        AddCorner(NotificationFrame, 10)
        AddStroke(NotificationFrame, TypeColors[Type] or CurrentTheme.Accent, 2)
        
        local NotifShadow = CreateElement("ImageLabel", {
            Size = UDim2.new(1, 20, 1, 20),
            Position = UDim2.new(0, -10, 0, -10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://5554236805",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.7,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(23, 23, 277, 277),
            Parent = NotificationFrame,
            ZIndex = 999
        })
        
        local IconFrame = CreateElement("Frame", {
            Size = UDim2.new(0, 6, 1, 0),
            BackgroundColor3 = TypeColors[Type] or CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = NotificationFrame
        })
        AddCorner(IconFrame, 10)
        
        local IconMask = CreateElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundColor3 = CurrentTheme.Secondary,
            BorderSizePixel = 0,
            Parent = IconFrame
        })
        
        local TitleLabel = CreateElement("TextLabel", {
            Size = UDim2.new(1, -60, 0, 18),
            Position = UDim2.new(0, 20, 0, 10),
            BackgroundTransparency = 1,
            Text = Title,
            TextColor3 = CurrentTheme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = NotificationFrame
        })
        
        local ContentLabel = CreateElement("TextLabel", {
            Size = UDim2.new(1, -60, 1, -35),
            Position = UDim2.new(0, 20, 0, 30),
            BackgroundTransparency = 1,
            Text = Content,
            TextColor3 = CurrentTheme.TextDark,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = NotificationFrame
        })
        
        local CloseButton = CreateElement("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -28, 0, 8),
            BackgroundTransparency = 1,
            Text = "×",
            TextColor3 = CurrentTheme.TextDark,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            Parent = NotificationFrame
        })
        
        local ProgressBar = CreateElement("Frame", {
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundColor3 = TypeColors[Type] or CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = NotificationFrame
        })
        
        Tween(NotificationFrame, {Size = UDim2.new(0, 320, 0, 80), Position = UDim2.new(1, -340, 1, -100)}, 0.4, Enum.EasingStyle.Back)
        
        task.spawn(function()
            Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 3)}, Duration, Enum.EasingStyle.Linear)
            task.wait(Duration)
            Tween(NotificationFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(1, -20, 1, -20)}, 0.3)
            task.wait(0.3)
            NotificationFrame:Destroy()
        end)
        
        CloseButton.MouseButton1Click:Connect(function()
            Tween(NotificationFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(1, -20, 1, -20)}, 0.3)
            task.wait(0.3)
            NotificationFrame:Destroy()
        end)
        
        CloseButton.MouseEnter:Connect(function()
            CloseButton.TextColor3 = CurrentTheme.Text
        end)
        
        CloseButton.MouseLeave:Connect(function()
            CloseButton.TextColor3 = CurrentTheme.TextDark
        end)
    end
    
    Window.ConfigValues = {}
    
    function Window:SaveConfig(filename)
        filename = filename or "EclipseConfig"
        
        local HttpService = game:GetService("HttpService")
        local configData = HttpService:JSONEncode(Window.ConfigValues)
        
        if writefile then
            writefile(filename .. ".json", configData)
            Window:CreateNotification({
                Title = "Config Saved",
                Content = "Configuration saved to " .. filename .. ".json",
                Type = "Success",
                Duration = 2
            })
            return true
        else
            Window:CreateNotification({
                Title = "Save Failed",
                Content = "writefile function not available",
                Type = "Error",
                Duration = 3
            })
            return false
        end
    end
    
    function Window:LoadConfig(filename)
        filename = filename or "EclipseConfig"
        
        if readfile and isfile and isfile(filename .. ".json") then
            local HttpService = game:GetService("HttpService")
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(filename .. ".json"))
            end)
            
            if success and data then
                Window.ConfigValues = data
                Window:CreateNotification({
                    Title = "Config Loaded",
                    Content = "Configuration loaded from " .. filename .. ".json",
                    Type = "Success",
                    Duration = 2
                })
                return true
            else
                Window:CreateNotification({
                    Title = "Load Failed",
                    Content = "Failed to parse configuration file",
                    Type = "Error",
                    Duration = 3
                })
                return false
            end
        else
            Window:CreateNotification({
                Title = "Load Failed",
                Content = "Configuration file not found",
                Type = "Warning",
                Duration = 3
            })
            return false
        end
    end
    
    function Window:DeleteConfig(filename)
        filename = filename or "EclipseConfig"
        
        if delfile and isfile and isfile(filename .. ".json") then
            delfile(filename .. ".json")
            Window:CreateNotification({
                Title = "Config Deleted",
                Content = "Configuration file deleted",
                Type = "Info",
                Duration = 2
            })
            return true
        else
            Window:CreateNotification({
                Title = "Delete Failed",
                Content = "File not found or delfile unavailable",
                Type = "Error",
                Duration = 3
            })
            return false
        end
    end
    
    function Window:ListConfigs()
        if listfiles then
            local files = listfiles()
            local configs = {}
            for _, file in ipairs(files) do
                if file:sub(-5) == ".json" then
                    table.insert(configs, file)
                end
            end
            return configs
        end
        return {}
    end
    
    function Window:SetValue(key, value)
        Window.ConfigValues[key] = value
    end
    
    function Window:GetValue(key, default)
        return Window.ConfigValues[key] or default
    end
    
    function Window:SetTheme(themeName)
        local newTheme = Themes[themeName]
        if not newTheme then return end
        
        CurrentTheme = newTheme
        Window.Theme = newTheme
        
        MainFrame.BackgroundColor3 = newTheme.Primary
        TopBar.BackgroundColor3 = newTheme.Secondary
        TopBarMask.BackgroundColor3 = newTheme.Secondary
        TitleLabel.TextColor3 = newTheme.Text
        MinimizeButton.BackgroundColor3 = newTheme.Tertiary
        MinimizeIcon.TextColor3 = newTheme.Text
        CloseButton.BackgroundColor3 = newTheme.Tertiary
        TabContainer.BackgroundColor3 = newTheme.Secondary
        ContentContainer.BackgroundColor3 = newTheme.Secondary
        
        for _, tab in pairs(Window.Tabs) do
            if not tab.Active then
                tab.Button.BackgroundColor3 = newTheme.Tertiary
                tab.Label.TextColor3 = newTheme.TextDark
                if tab.Icon then
                    tab.Icon.ImageColor3 = newTheme.TextDark
                end
            else
                tab.Button.BackgroundColor3 = newTheme.Accent
                tab.Label.TextColor3 = newTheme.Text
                if tab.Icon then
                    tab.Icon.ImageColor3 = newTheme.Text
                end
            end
        end
    end
    
    function Window:AddTheme(name, theme)
        if not Themes[name] then
            Themes[name] = theme
            return true
        end
        return false
    end
    
    function Window:GetThemes()
        local themeNames = {}
        for name, _ in pairs(Themes) do
            table.insert(themeNames, name)
        end
        return themeNames
    end
    
    function Window:SetTitle(title)
        TitleLabel.Text = title
    end
    
    function Window:SetLogo(imageId)
        LogoIcon.Image = "rbxassetid://" .. imageId
    end
    
    function Window:Toggle()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            Tween(MainFrame, {Size = UDim2.new(0, Size.X.Offset, 0, 50)}, 0.3)
            MinimizeIcon.Text = "+"
        else
            Tween(MainFrame, {Size = Size}, 0.3)
            MinimizeIcon.Text = "-"
        end
    end
    
    function Window:Show()
        MainFrame.Visible = true
        Tween(MainFrame, {Size = Size}, 0.3)
    end
    
    function Window:Hide()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        MainFrame.Visible = false
    end
    
    function Window:Destroy()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end
    
    return Window
end

function EclipseLib:Notify(config)
    local TempGui = CreateElement("ScreenGui", {
        Name = "EclipseNotif",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    config = config or {}
    local Title = config.Title or "Notification"
    local Content = config.Content or ""
    local Duration = config.Duration or 3
    local Type = config.Type or "Info"
    
    local DefaultTheme = Themes.Eclipse
    local TypeColors = {
        Info = DefaultTheme.Accent,
        Success = DefaultTheme.Success,
        Warning = DefaultTheme.Warning,
        Error = DefaultTheme.Error
    }
    
    local NotificationFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(1, -20, 1, -20),
        BackgroundColor3 = DefaultTheme.Secondary,
        BorderSizePixel = 0,
        Parent = TempGui,
        ZIndex = 1000
    })
    AddCorner(NotificationFrame, 10)
    AddStroke(NotificationFrame, TypeColors[Type] or DefaultTheme.Accent, 2)
    
    local NotifShadow = CreateElement("ImageLabel", {
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Parent = NotificationFrame,
        ZIndex = 999
    })
    
    local IconFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 6, 1, 0),
        BackgroundColor3 = TypeColors[Type] or DefaultTheme.Accent,
        BorderSizePixel = 0,
        Parent = NotificationFrame
    })
    AddCorner(IconFrame, 10)
    
    local IconMask = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = DefaultTheme.Secondary,
        BorderSizePixel = 0,
        Parent = IconFrame
    })
    
    local TitleLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -60, 0, 18),
        Position = UDim2.new(0, 20, 0, 10),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = DefaultTheme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = NotificationFrame
    })
    
    local ContentLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -60, 1, -35),
        Position = UDim2.new(0, 20, 0, 30),
        BackgroundTransparency = 1,
        Text = Content,
        TextColor3 = DefaultTheme.TextDark,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = NotificationFrame
    })
    
    local CloseButton = CreateElement("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0, 8),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = DefaultTheme.TextDark,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Parent = NotificationFrame
    })
    
    local ProgressBar = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = TypeColors[Type] or DefaultTheme.Accent,
        BorderSizePixel = 0,
        Parent = NotificationFrame
    })
    
    Tween(NotificationFrame, {Size = UDim2.new(0, 320, 0, 80), Position = UDim2.new(1, -340, 1, -100)}, 0.4, Enum.EasingStyle.Back)
    
    task.spawn(function()
        Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 3)}, Duration, Enum.EasingStyle.Linear)
        task.wait(Duration)
        Tween(NotificationFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(1, -20, 1, -20)}, 0.3)
        task.wait(0.3)
        TempGui:Destroy()
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(NotificationFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(1, -20, 1, -20)}, 0.3)
        task.wait(0.3)
        TempGui:Destroy()
    end)
    
    CloseButton.MouseEnter:Connect(function()
        CloseButton.TextColor3 = DefaultTheme.Text
    end)
    
    CloseButton.MouseLeave:Connect(function()
        CloseButton.TextColor3 = DefaultTheme.TextDark
    end)
end

EclipseLib.AnimationPresets = {
    FadeIn = function(element, duration)
        element.Transparency = 1
        return Tween(element, {Transparency = 0}, duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end,
    
    FadeOut = function(element, duration)
        return Tween(element, {Transparency = 1}, duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end,
    
    SlideIn = function(element, direction, duration)
        direction = direction or "Left"
        local startPos = element.Position
        local offset = 100
        
        if direction == "Left" then
            element.Position = startPos + UDim2.new(0, -offset, 0, 0)
        elseif direction == "Right" then
            element.Position = startPos + UDim2.new(0, offset, 0, 0)
        elseif direction == "Top" then
            element.Position = startPos + UDim2.new(0, 0, 0, -offset)
        elseif direction == "Bottom" then
            element.Position = startPos + UDim2.new(0, 0, 0, offset)
        end
        
        return Tween(element, {Position = startPos}, duration or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end,
    
    ScaleIn = function(element, duration)
        element.Size = UDim2.new(0, 0, 0, 0)
        local targetSize = element.Size
        return Tween(element, {Size = targetSize}, duration or 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end,
    
    Shake = function(element, intensity, duration)
        intensity = intensity or 5
        duration = duration or 0.5
        
        local originalPos = element.Position
        local elapsed = 0
        local connection
        
        connection = RunService.RenderStepped:Connect(function(dt)
            elapsed = elapsed + dt
            if elapsed >= duration then
                element.Position = originalPos
                connection:Disconnect()
                return
            end
            
            local offsetX = math.random(-intensity, intensity)
            local offsetY = math.random(-intensity, intensity)
            element.Position = originalPos + UDim2.new(0, offsetX, 0, offsetY)
        end)
        
        return connection
    end,
    
    Pulse = function(element, scale, duration)
        scale = scale or 1.1
        duration = duration or 0.3
        
        local originalSize = element.Size
        Tween(element, {Size = originalSize * scale}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.wait(duration)
        return Tween(element, {Size = originalSize}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end,
    
    Rotate = function(element, rotation, duration)
        return Tween(element, {Rotation = rotation}, duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end,
    
    Bounce = function(element, height, duration)
        height = height or 20
        duration = duration or 0.5
        
        local originalPos = element.Position
        Tween(element, {Position = originalPos + UDim2.new(0, 0, 0, -height)}, duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.wait(duration / 2)
        return Tween(element, {Position = originalPos}, duration / 2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
    end
}

EclipseLib.SoundEffects = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079853",
    Toggle = "rbxassetid://6895079853",
    Success = "rbxassetid://6895079853",
    Error = "rbxassetid://6895079853",
    Notification = "rbxassetid://6895079853"
}

function EclipseLib:PlaySound(soundId, volume)
    volume = volume or 0.5
    if not soundId then return end
    
    local SoundService = game:GetService("SoundService")
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Parent = SoundService
    sound:Play()
    
    game:GetService("Debris"):AddItem(sound, 2)
    return sound
end

function EclipseLib:ColorFromHex(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return Color3.fromRGB(r, g, b)
end

function EclipseLib:HexFromColor(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

function EclipseLib:LerpColor(color1, color2, alpha)
    return Color3.new(
        color1.R + (color2.R - color1.R) * alpha,
        color1.G + (color2.G - color1.G) * alpha,
        color1.B + (color2.B - color1.B) * alpha
    )
end

function EclipseLib:RGBRainbow(speed)
    speed = speed or 1
    local hue = (tick() * speed) % 360
    return Color3.fromHSV(hue / 360, 1, 1)
end

function EclipseLib:GetContrastColor(color)
    local brightness = (color.R * 299 + color.G * 587 + color.B * 114) / 1000
    return brightness > 0.5 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
end

function EclipseLib:Darken(color, amount)
    amount = amount or 0.2
    return Color3.new(
        math.max(color.R - amount, 0),
        math.max(color.G - amount, 0),
        math.max(color.B - amount, 0)
    )
end

function EclipseLib:Lighten(color, amount)
    amount = amount or 0.2
    return Color3.new(
        math.min(color.R + amount, 1),
        math.min(color.G + amount, 1),
        math.min(color.B + amount, 1)
    )
end

function EclipseLib:CreateRipple(parent, x, y)
    local ripple = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, x, 0, y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = parent,
        ZIndex = 1000
    })
    AddCorner(ripple, 999)
    
    local targetSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    
    Tween(ripple, {
        Size = UDim2.new(0, targetSize, 0, targetSize),
        BackgroundTransparency = 1
    }, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    task.wait(0.6)
    ripple:Destroy()
end

function EclipseLib:FormatNumber(number)
    if number >= 1000000000 then
        return string.format("%.1fB", number / 1000000000)
    elseif number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function EclipseLib:Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function EclipseLib:Lerp(start, finish, alpha)
    return start + (finish - start) * alpha
end

function EclipseLib:Round(number, decimals)
    decimals = decimals or 0
    local mult = 10^decimals
    return math.floor(number * mult + 0.5) / mult
end

function EclipseLib:TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function EclipseLib:TableMerge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

function EclipseLib:DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for k, v in next, original, nil do
            copy[EclipseLib:DeepCopy(k)] = EclipseLib:DeepCopy(v)
        end
        setmetatable(copy, EclipseLib:DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

function EclipseLib:WaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    local startTime = tick()
    
    while not parent:FindFirstChild(childName) do
        if tick() - startTime > timeout then
            return nil
        end
        task.wait(0.1)
    end
    
    return parent:FindFirstChild(childName)
end

function EclipseLib:GetChildren(parent, className)
    local children = {}
    for _, child in ipairs(parent:GetChildren()) do
        if not className or child:IsA(className) then
            table.insert(children, child)
        end
    end
    return children
end

function EclipseLib:GetDescendants(parent, className)
    local descendants = {}
    for _, descendant in ipairs(parent:GetDescendants()) do
        if not className or descendant:IsA(className) then
            table.insert(descendants, descendant)
        end
    end
    return descendants
end

function EclipseLib:Debounce(func, delay)
    delay = delay or 0.3
    local lastCall = 0
    
    return function(...)
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

function EclipseLib:Throttle(func, delay)
    delay = delay or 0.1
    local lastCall = 0
    local scheduled = false
    
    return function(...)
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        elseif not scheduled then
            scheduled = true
            task.delay(delay - (now - lastCall), function()
                scheduled = false
                lastCall = tick()
                func(...)
            end)
        end
    end
end

function EclipseLib:CreatePromise(executor)
    local promise = {
        _status = "pending",
        _value = nil,
        _callbacks = {}
    }
    
    function promise:andThen(callback)
        if self._status == "fulfilled" then
            callback(self._value)
        else
            table.insert(self._callbacks, callback)
        end
        return self
    end
    
    function promise:catch(callback)
        if self._status == "rejected" then
            callback(self._value)
        end
        return self
    end
    
    local function resolve(value)
        if promise._status == "pending" then
            promise._status = "fulfilled"
            promise._value = value
            for _, callback in ipairs(promise._callbacks) do
                callback(value)
            end
        end
    end
    
    local function reject(reason)
        if promise._status == "pending" then
            promise._status = "rejected"
            promise._value = reason
        end
    end
    
    task.spawn(function()
        executor(resolve, reject)
    end)
    
    return promise
end

function EclipseLib:GetScreenSize()
    local viewport = workspace.CurrentCamera.ViewportSize
    return {
        Width = viewport.X,
        Height = viewport.Y
    }
end

function EclipseLib:IsVisible(element)
    if not element or not element:IsA("GuiObject") then return false end
    
    local current = element
    while current do
        if not current.Visible then
            return false
        end
        if current.Parent and current.Parent:IsA("GuiObject") then
            current = current.Parent
        else
            break
        end
    end
    
    return true
end

function EclipseLib:GetMouseLocation()
    return {
        X = Mouse.X,
        Y = Mouse.Y
    }
end

function EclipseLib:IsPointInBounds(point, element)
    local pos = element.AbsolutePosition
    local size = element.AbsoluteSize
    
    return point.X >= pos.X and point.X <= pos.X + size.X and
           point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

function EclipseLib:GetRelativePosition(element, parent)
    local elementPos = element.AbsolutePosition
    local parentPos = parent.AbsolutePosition
    
    return {
        X = elementPos.X - parentPos.X,
        Y = elementPos.Y - parentPos.Y
    }
end

function EclipseLib:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("EclipseLib Error: " .. tostring(result))
    end
    return success, result
end

function EclipseLib:Log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[%s][EclipseLib][%s]", timestamp, level)
end

function EclipseLib:GetVersion()
    return EclipseLib.Version
end

function EclipseLib:CreateDialog(config)
    config = config or {}
    local Title = config.Title or "Dialog"
    local Content = config.Content or ""
    local Buttons = config.Buttons or {"OK"}
    local Callback = config.Callback or function() end
    
    local DialogGui = CreateElement("ScreenGui", {
        Name = "EclipseDialog",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    local Overlay = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = DialogGui,
        ZIndex = 900
    })
    
    local DialogFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Themes.Eclipse.Secondary,
        BorderSizePixel = 0,
        Parent = DialogGui,
        ZIndex = 1001
    })
    AddCorner(DialogFrame, 12)
    AddStroke(DialogFrame, Themes.Eclipse.Border, 2)
    
    local TitleLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.new(0, 20, 0, 15),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = Themes.Eclipse.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = DialogFrame,
        ZIndex = 1002
    })
    
    local ContentLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -40, 0, 60),
        Position = UDim2.new(0, 20, 0, 50),
        BackgroundTransparency = 1,
        Text = Content,
        TextColor3 = Themes.Eclipse.TextDark,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = DialogFrame,
        ZIndex = 1002
    })
    
    local ButtonContainer = CreateElement("Frame", {
        Size = UDim2.new(1, -40, 0, 35),
        Position = UDim2.new(0, 20, 1, -50),
        BackgroundTransparency = 1,
        Parent = DialogFrame,
        ZIndex = 1002
    })
    
    local ButtonLayout = CreateElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = ButtonContainer
    })
    
    for i, buttonText in ipairs(Buttons) do
        local Button = CreateElement("TextButton", {
            Size = UDim2.new(0, 80, 0, 35),
            BackgroundColor3 = i == #Buttons and Themes.Eclipse.Accent or Themes.Eclipse.Tertiary,
            BorderSizePixel = 0,
            Text = buttonText,
            TextColor3 = Themes.Eclipse.Text,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            LayoutOrder = i,
            Parent = ButtonContainer,
            ZIndex = 1002
        })
        AddCorner(Button, 6)
        
        Button.MouseButton1Click:Connect(function()
            Tween(DialogFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
            Tween(Overlay, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.2)
            DialogGui:Destroy()
            Callback(buttonText)
        end)
        
        Button.MouseEnter:Connect(function()
            Tween(Button, {BackgroundColor3 = Themes.Eclipse.AccentDark}, 0.2)
        end)
        
        Button.MouseLeave:Connect(function()
            Tween(Button, {BackgroundColor3 = i == #Buttons and Themes.Eclipse.Accent or Themes.Eclipse.Tertiary}, 0.2)
        end)
    end
    
    Overlay.BackgroundTransparency = 1
    Tween(Overlay, {BackgroundTransparency = 0.5}, 0.2)
    Tween(DialogFrame, {Size = UDim2.new(0, 400, 0, 180)}, 0.3, Enum.EasingStyle.Back)
end

function EclipseLib:CreateTooltip(element, text)
    local Tooltip = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, -5),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Themes.Eclipse.Tertiary,
        BorderSizePixel = 0,
        Visible = false,
        Parent = element,
        ZIndex = 2000
    })
    AddCorner(Tooltip, 6)
    AddStroke(Tooltip, Themes.Eclipse.Border, 1)
    
    local TooltipLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -16, 1, -8),
        Position = UDim2.new(0, 8, 0, 4),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Themes.Eclipse.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Tooltip,
        ZIndex = 2001
    })
    
    local textSize = game:GetService("TextService"):GetTextSize(
        text,
        11,
        Enum.Font.Gotham,
        Vector2.new(200, 1000)
    )
    
    element.MouseEnter:Connect(function()
        Tooltip.Size = UDim2.new(0, textSize.X + 16, 0, textSize.Y + 8)
        Tooltip.Visible = true
        Tween(Tooltip, {BackgroundTransparency = 0}, 0.2)
    end)
    
    element.MouseLeave:Connect(function()
        Tween(Tooltip, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        Tooltip.Visible = false
    end)
    
    return Tooltip
end

function EclipseLib:CreateContextMenu(options, position)
    options = options or {}
    position = position or EclipseLib:GetMouseLocation()
    
    local ContextGui = CreateElement("ScreenGui", {
        Name = "EclipseContext",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    local MenuFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, position.X, 0, position.Y),
        BackgroundColor3 = Themes.Eclipse.Secondary,
        BorderSizePixel = 0,
        Parent = ContextGui,
        ClipsDescendants = true,
        ZIndex = 1500
    })
    AddCorner(MenuFrame, 8)
    AddStroke(MenuFrame, Themes.Eclipse.Border, 1)
    
    local MenuLayout = CreateElement("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = MenuFrame
    })
    
    local function CloseMenu()
        Tween(MenuFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
        task.wait(0.2)
        ContextGui:Destroy()
    end
    
    for i, option in ipairs(options) do
        local OptionButton = CreateElement("TextButton", {
            Size = UDim2.new(1, -4, 0, 30),
            Position = UDim2.new(0, 2, 0, 2 + (i-1) * 32),
            BackgroundColor3 = Themes.Eclipse.Tertiary,
            BorderSizePixel = 0,
            Text = "",
            LayoutOrder = i,
            Parent = MenuFrame,
            ZIndex = 1501
        })
        AddCorner(OptionButton, 6)
        
        local OptionLabel = CreateElement("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = option.Text or "Option",
            TextColor3 = option.Color or Themes.Eclipse.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = OptionButton,
            ZIndex = 1501
        })
        
        OptionButton.MouseButton1Click:Connect(function()
            CloseMenu()
            if option.Callback then
                option.Callback()
            end
        end)
        
        OptionButton.MouseEnter:Connect(function()
            Tween(OptionButton, {BackgroundColor3 = Themes.Eclipse.Tertiary}, 0.2)
        end)
        
        OptionButton.MouseLeave:Connect(function()
            Tween(OptionButton, {BackgroundColor3 = Themes.Eclipse.Tertiary}, 0.2)
        end)
    end
    
    MenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Tween(MenuFrame, {Size = UDim2.new(0, 180, 0, MenuLayout.AbsoluteContentSize.Y + 4)}, 0.2)
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not EclipseLib:IsPointInBounds(EclipseLib:GetMouseLocation(), MenuFrame) then
                CloseMenu()
            end
        end
    end)
    
    return ContextGui
end

function EclipseLib:Confirm(title, content, callback)
    return EclipseLib:CreateDialog({
        Title = title or "Confirm",
        Content = content or "Are you sure?",
        Buttons = {"Cancel", "Confirm"},
        Callback = function(button)
            if callback then
                callback(button == "Confirm")
            end
        end
    })
end

function EclipseLib:Alert(title, content, callback)
    return EclipseLib:CreateDialog({
        Title = title or "Alert",
        Content = content or "",
        Buttons = {"OK"},
        Callback = callback
    })
end

function EclipseLib:Prompt(title, content, callback)
    local PromptGui = CreateElement("ScreenGui", {
        Name = "EclipsePrompt",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    local Overlay = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = PromptGui,
        ZIndex = 900
    })
    
    local PromptFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Themes.Eclipse.Secondary,
        BorderSizePixel = 0,
        Parent = PromptGui,
        ZIndex = 1001
    })
    AddCorner(PromptFrame, 12)
    AddStroke(PromptFrame, Themes.Eclipse.Border, 2)
    
    local TitleLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.new(0, 20, 0, 15),
        BackgroundTransparency = 1,
        Text = title or "Prompt",
        TextColor3 = Themes.Eclipse.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = PromptFrame,
        ZIndex = 1002
    })
    
    local ContentLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.new(0, 20, 0, 50),
        BackgroundTransparency = 1,
        Text = content or "Enter value:",
        TextColor3 = Themes.Eclipse.TextDark,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = PromptFrame,
        ZIndex = 1002
    })
    
    local InputBox = CreateElement("TextBox", {
        Size = UDim2.new(1, -40, 0, 35),
        Position = UDim2.new(0, 20, 0, 85),
        BackgroundColor3 = Themes.Eclipse.Primary,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Type here...",
        TextColor3 = Themes.Eclipse.Text,
        PlaceholderColor3 = Themes.Eclipse.TextDark,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = PromptFrame,
        ZIndex = 1002
    })
    AddCorner(InputBox, 6)
    AddStroke(InputBox, Themes.Eclipse.Border, 1)
    
    local ButtonContainer = CreateElement("Frame", {
        Size = UDim2.new(1, -40, 0, 35),
        Position = UDim2.new(0, 20, 0, 135),
        BackgroundTransparency = 1,
        Parent = PromptFrame,
        ZIndex = 1002
    })
    
    local CancelButton = CreateElement("TextButton", {
        Size = UDim2.new(0, 80, 0, 35),
        Position = UDim2.new(1, -170, 0, 0),
        BackgroundColor3 = Themes.Eclipse.Tertiary,
        BorderSizePixel = 0,
        Text = "Cancel",
        TextColor3 = Themes.Eclipse.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = ButtonContainer,
        ZIndex = 1002
    })
    AddCorner(CancelButton, 6)
    
    local ConfirmButton = CreateElement("TextButton", {
        Size = UDim2.new(0, 80, 0, 35),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundColor3 = Themes.Eclipse.Accent,
        BorderSizePixel = 0,
        Text = "Confirm",
        TextColor3 = Themes.Eclipse.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = ButtonContainer,
        ZIndex = 1002
    })
    AddCorner(ConfirmButton, 6)
    
    local function Close()
        Tween(PromptFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
        Tween(Overlay, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        PromptGui:Destroy()
    end
    
    CancelButton.MouseButton1Click:Connect(function()
        Close()
        if callback then callback(nil) end
    end)
    
    ConfirmButton.MouseButton1Click:Connect(function()
        local text = InputBox.Text
        Close()
        if callback then callback(text) end
    end)
    
    CancelButton.MouseEnter:Connect(function()
        Tween(CancelButton, {BackgroundColor3 = Themes.Eclipse.Tertiary}, 0.2)
    end)
    
    ConfirmButton.MouseEnter:Connect(function()
        Tween(ConfirmButton, {BackgroundColor3 = Themes.Eclipse.AccentDark}, 0.2)
    end)
    
    Overlay.BackgroundTransparency = 1
    Tween(Overlay, {BackgroundTransparency = 0.5}, 0.2)
    Tween(PromptFrame, {Size = UDim2.new(0, 400, 0, 190)}, 0.3, Enum.EasingStyle.Back)
end

return EclipseLib
