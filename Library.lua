--[[
    Novoline UI Library
    Made by @thedude_whotalks
    
    A complete, object-oriented Roblox UI Library
    Zero syn dependencies - Pure Roblox API
--]]

local Novoline = {}
Novoline.__index = Novoline

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Global State
getgenv().NovolineToggles = {}
getgenv().NovolineOptions = {}
Novoline.Toggles = getgenv().NovolineToggles
Novoline.Options = getgenv().NovolineOptions
Novoline.Connections = {}
Novoline.ColorRegistry = {}
Novoline.Unloaded = false
Novoline.ForceCheckbox = false
Novoline.ShowToggleFrameInKeybinds = true
Novoline.GUI = nil

-- Default Color Scheme
Novoline.Scheme = {
    BackgroundColor = Color3.fromRGB(12, 12, 16),
    MainColor = Color3.fromRGB(20, 20, 28),
    AccentColor = Color3.fromRGB(90, 120, 255),
    OutlineColor = Color3.fromRGB(35, 35, 50),
    FontColor = Color3.fromRGB(220, 220, 230),
    DarkAccent = Color3.fromRGB(60, 80, 180),
    TextMuted = Color3.fromRGB(100, 100, 120),
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(255, 90, 90),
    Warning = Color3.fromRGB(255, 200, 60),
}

-- Utility Functions
local function Clamp(value, min, max)
    return math.clamp(value, min, max)
end

local function Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function HexToColor3(hex)
    if type(hex) ~= "string" then return Color3.fromRGB(255, 255, 255) end
    hex = hex:gsub("#", "")
    if #hex < 6 then return Color3.fromRGB(255, 255, 255) end
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16) or 255,
        tonumber(hex:sub(3, 4), 16) or 255,
        tonumber(hex:sub(5, 6), 16) or 255
    )
end

local function Color3ToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(Clamp(color.R, 0, 1) * 255),
        math.floor(Clamp(color.G, 0, 1) * 255),
        math.floor(Clamp(color.B, 0, 1) * 255)
    )
end

local function HSVToColor3(h, s, v)
    return Color3.fromHSV(Clamp(h, 0, 1), Clamp(s, 0, 1), Clamp(v, 0, 1))
end

local function Color3ToHSV(color)
    return Color3.toHSV(color)
end

local function DarkenColor(color, amount)
    return Color3.new(
        Clamp(color.R - amount, 0, 1),
        Clamp(color.G - amount, 0, 1),
        Clamp(color.B - amount, 0, 1)
    )
end

local function LightenColor(color, amount)
    return Color3.new(
        Clamp(color.R + amount, 0, 1),
        Clamp(color.G + amount, 0, 1),
        Clamp(color.B + amount, 0, 1)
    )
end

-- Instance Creation Helper
local function Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

-- Tween Helper
local function Tween(instance, props, duration, style, direction)
    if Novoline.Unloaded or not instance or not instance.Parent then return nil end
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    table.insert(Novoline.Connections, tween)
    return tween
end

-- Color Registry Management
local function RegisterColor(element, property, colorKey)
    if not element or not property or not colorKey then return end
    table.insert(Novoline.ColorRegistry, {
        Element = element,
        Property = property,
        ColorKey = colorKey
    })
end

function Novoline:UpdateColorsUsingRegistry()
    for _, entry in ipairs(self.ColorRegistry) do
        if entry.Element and entry.Element.Parent and self.Scheme[entry.ColorKey] then
            pcall(function()
                entry.Element[entry.Property] = self.Scheme[entry.ColorKey]
            end)
        end
    end
end

function Novoline:SetScheme(scheme)
    for k, v in pairs(scheme) do
        if self.Scheme[k] ~= nil then
            self.Scheme[k] = v
        end
    end
    self:UpdateColorsUsingRegistry()
end

-- Connection Management
local function Connect(event, callback)
    if Novoline.Unloaded then return nil end
    local conn = event:Connect(callback)
    table.insert(Novoline.Connections, conn)
    return conn
end

-- Unload Function
function Novoline:Unload()
    self.Unloaded = true
    for _, conn in ipairs(self.Connections) do
        pcall(function()
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            elseif typeof(conn) == "Tween" then
                conn:Cancel()
            end
        end)
    end
    self.Connections = {}
    if self.GUI then
        pcall(function() self.GUI:Destroy() end)
        self.GUI = nil
    end
end

-- Notification System
local function CreateNotification(gui, config, scheme)
    local side = config.Side or "Right"
    local container = gui:FindFirstChild("NotifyContainer_" .. side)
    if not container then
        container = Create("Frame", {
            Name = "NotifyContainer_" .. side,
            Size = UDim2.new(0, 280, 1, 0),
            Position = side == "Left" and UDim2.new(0, 15, 0, 0) or UDim2.new(1, -295, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 500
        }, gui)
        
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        }, container)
        
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 15),
        }, container)
    end
    
    local notify = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 501,
        LayoutOrder = -math.floor(tick() * 10000)
    }, container)
    
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, notify)
    
    local outline = Create("UIStroke", {
        Color = scheme.OutlineColor,
        Thickness = 1,
    }, notify)
    RegisterColor(outline, "Color", "OutlineColor")
    RegisterColor(notify, "BackgroundColor3", "MainColor")
    
    local accent = Create("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = scheme.AccentColor,
        BorderSizePixel = 0,
        ZIndex = 502
    }, notify)
    Create("UICorner", { CornerRadius = UDim.new(0, 2) }, accent)
    RegisterColor(accent, "BackgroundColor3", "AccentColor")
    
    local title = Create("TextLabel", {
        Text = config.Title or "Notification",
        Size = UDim2.new(1, -25, 0, 22),
        Position = UDim2.new(0, 18, 0, 8),
        BackgroundTransparency = 1,
        TextColor3 = scheme.FontColor,
        TextSize = 13,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 503
    }, notify)
    RegisterColor(title, "TextColor3", "FontColor")
    
    local content = Create("TextLabel", {
        Text = config.Content or "",
        Size = UDim2.new(1, -25, 0, 18),
        Position = UDim2.new(0, 18, 0, 32),
        BackgroundTransparency = 1,
        TextColor3 = scheme.TextMuted,
        TextSize = 11,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 503
    }, notify)
    RegisterColor(content, "TextColor3", "TextMuted")
    
    Tween(notify, {
        Size = UDim2.new(1, 0, 0, 58)
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    local duration = config.Duration or 4
    task.delay(duration, function()
        if notify and notify.Parent then
            Tween(notify, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(side == "Left" and -1 or 1, 0, 0, 0)
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.35, function()
                pcall(function() notify:Destroy() end)
            end)
        end
    end)
    
    return notify
end

-- Main Window Creation
function Novoline:CreateWindow(config)
    if self.Unloaded then return nil end
    
    config = config or {}
    local Window = {}
    Window.__index = Window
    Window.Config = config
    
    -- ScreenGui
    local gui = Create("ScreenGui", {
        Name = "Novoline_" .. math.random(10000, 99999),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999
    }, CoreGui)
    
    self.GUI = gui
    
    -- Dropdown/Popup Container (High Z-Index for no clipping)
    local popupContainer = Create("Frame", {
        Name = "PopupContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100,
        ClipsDescendants = false
    }, gui)
    
    -- Main Window Frame
    local mainWindow = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 560, 0, 420),
        Position = UDim2.new(0.5, -280, 0.5, -210),
        BackgroundColor3 = self.Scheme.BackgroundColor,
        BorderSizePixel = 0,
        ClipsDescendants = false
    }, gui)
    
    Create("UICorner", { CornerRadius = UDim.new(0, 10) }, mainWindow)
    RegisterColor(mainWindow, "BackgroundColor3", "BackgroundColor")
    
    local mainOutline = Create("UIStroke", {
        Color = self.Scheme.OutlineColor,
        Thickness = 1.5,
    }, mainWindow)
    RegisterColor(mainOutline, "Color", "OutlineColor")
    
    -- Shadow Effect
    local shadow = Create("ImageLabel", {
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1
    }, mainWindow)
    
    -- Title Bar
    local titleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 10
    }, mainWindow)
    
    local titleCorner = Create("UICorner", { CornerRadius = UDim.new(0, 10) }, titleBar)
    RegisterColor(titleBar, "BackgroundColor3", "MainColor")
    
    local titleFix = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = self.Scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 10
    }, titleBar)
    RegisterColor(titleFix, "BackgroundColor3", "MainColor")
    
    -- Title Bar Content
    local titleContent = Create("Frame", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 11
    }, titleBar)
    
    -- Icon
    if config.Icon then
        Create("ImageLabel", {
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(0, 8, 0.5, -11),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. tostring(config.Icon),
            ZIndex = 12
        }, titleContent)
    end
    
    local iconOffset = config.Icon and 36 or 10
    
    local titleText = Create("TextLabel", {
        Text = config.Title or "Novoline",
        Size = UDim2.new(1, -iconOffset - 70, 1, 0),
        Position = UDim2.new(0, iconOffset, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Scheme.FontColor,
        TextSize = 14,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12
    }, titleContent)
    RegisterColor(titleText, "TextColor3", "FontColor")
    
    -- Window Controls
    local minimizeBtn = Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -62, 0.5, -14),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = self.Scheme.TextMuted,
        TextSize = 14,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        ZIndex = 12
    }, titleContent)
    RegisterColor(minimizeBtn, "TextColor3", "TextMuted")
    
    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -32, 0.5, -14),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = self.Scheme.TextMuted,
        TextSize = 18,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        ZIndex = 12
    }, titleContent)
    RegisterColor(closeBtn, "TextColor3", "TextMuted")
    
    -- Button Hover Effects
    minimizeBtn.MouseEnter:Connect(function()
        Tween(minimizeBtn, {TextColor3 = self.Scheme.FontColor}, 0.15)
    end)
    minimizeBtn.MouseLeave:Connect(function()
        Tween(minimizeBtn, {TextColor3 = self.Scheme.TextMuted}, 0.15)
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {TextColor3 = Color3.fromRGB(255, 85, 85)}, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {TextColor3 = self.Scheme.TextMuted}, 0.15)
    end)
    
    -- Minimize Logic
    local isMinimized = false
    local contentArea = nil
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if contentArea then
            Tween(contentArea, {
                Size = isMinimized and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 1, -63),
                BackgroundTransparency = isMinimized and 1 or 0
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)
    
    -- Close Logic
    closeBtn.MouseButton1Click:Connect(function()
        Tween(mainWindow, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.4, function()
            self:Unload()
        end)
    end)
    
    -- Drag Logic
    local dragging = false
    local dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainWindow.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainWindow.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Tab Navigation Bar
    local tabBar = Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = self.Scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 9
    }, mainWindow)
    RegisterColor(tabBar, "BackgroundColor3", "MainColor")
    
    local tabListLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    }, tabBar)
    
    local tabPadding = Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 4),
    }, tabBar)
    
    -- Content Area
    contentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -63),
        Position = UDim2.new(0, 0, 0, 63),
        BackgroundColor3 = self.Scheme.BackgroundColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 5
    }, mainWindow)
    RegisterColor(contentArea, "BackgroundColor3", "BackgroundColor")
    
    -- Footer
    local footer = Create("Frame", {
        Name = "Footer",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -24),
        BackgroundColor3 = self.Scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 10
    }, mainWindow)
    
    local footerCorner = Create("UICorner", { CornerRadius = UDim.new(0, 10) }, footer)
    RegisterColor(footer, "BackgroundColor3", "MainColor")
    
    local footerFix = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 10
    }, footer)
    RegisterColor(footerFix, "BackgroundColor3", "MainColor")
    
    local footerText = Create("TextLabel", {
        Text = (config.Footer or "") .. " | made by @thedude_whotalks For Novoline",
        Size = UDim2.new(1, -15, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Scheme.TextMuted,
        TextSize = 10,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11
    }, footer)
    RegisterColor(footerText, "TextColor3", "TextMuted")
    
    -- Tab Storage
    local tabs = {}
    local selectedTab = nil
    
    -- Custom Cursor
    if config.ShowCustomCursor then
        local cursorFrame = Create("Frame", {
            Name = "CustomCursor",
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundTransparency = 1,
            ZIndex = 9999
        }, gui)
        
        local cursorH = Create("Frame", {
            Size = UDim2.new(0, 10, 0, 2),
            Position = UDim2.new(0, 4, 0, 8),
            BackgroundColor3 = self.Scheme.AccentColor,
            BorderSizePixel = 0,
            ZIndex = 10000
        }, cursorFrame)
        
        local cursorV = Create("Frame", {
            Size = UDim2.new(0, 2, 0, 10),
            Position = UDim2.new(0, 8, 0, 4),
            BackgroundColor3 = self.Scheme.AccentColor,
            BorderSizePixel = 0,
            ZIndex = 10000
        }, cursorFrame)
        
        local cursorDot = Create("Frame", {
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(0, 7, 0, 7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 10001
        }, cursorFrame)
        
        RegisterColor(cursorH, "BackgroundColor3", "AccentColor")
        RegisterColor(cursorV, "BackgroundColor3", "AccentColor")
        
        Connect(UserInputService.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                cursorFrame.Position = UDim2.new(0, input.Position.X - 9, 0, input.Position.Y - 9)
            end
        end)
        
        UserInputService.MouseIconEnabled = false
    end
    
    -- Add Tab Function
    function Window:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local Tab = {}
        Tab.__index = Tab
        Tab.Title = tabConfig.Title or "Tab"
        Tab.Icon = tabConfig.Icon
        Tab.Groupboxes = {}
        
        -- Tab Button
        local tabBtn = Create("TextButton", {
            Name = "TabBtn_" .. self.Title,
            Size = UDim2.new(0, 75, 0, 21),
            BackgroundTransparency = 1,
            Text = self.Title,
            TextColor3 = self.Scheme.TextMuted,
            TextSize = 11,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            ZIndex = 10,
            LayoutOrder = #tabs + 1,
            AutoButtonColor = false
        }, tabBar)
        RegisterColor(tabBtn, "TextColor3", "TextMuted")
        
        -- Tab Indicator
        local tabIndicator = Create("Frame", {
            Size = UDim2.new(0.7, 0, 0, 2),
            Position = UDim2.new(0.15, 0, 1, -2),
            BackgroundColor3 = self.Scheme.AccentColor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 10
        }, tabBtn)
        RegisterColor(tabIndicator, "BackgroundColor3", "AccentColor")
        
        -- Tab Content
        local tabContent = Create("Frame", {
            Name = "TabContent_" .. self.Title,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 5
        }, contentArea)
        
        local contentPadding = Create("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 30),
        }, tabContent)
        
        local contentList = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        }, tabContent)
        
        Tab.Button = tabBtn
        Tab.Content = tabContent
        Tab.Indicator = tabIndicator
        
        -- Select Tab Function
        local function SelectTab()
            if selectedTab then
                selectedTab.Content.Visible = false
                Tween(selectedTab.Button, {TextColor3 = Novoline.Scheme.TextMuted}, 0.2)
                Tween(selectedTab.Indicator, {BackgroundTransparency = 1}, 0.2)
            end
            selectedTab = Tab
            Tab.Content.Visible = true
            Tween(tabBtn, {TextColor3 = Novoline.Scheme.AccentColor}, 0.2)
            Tween(tabIndicator, {BackgroundTransparency = 0}, 0.2)
        end
        
        -- Hover Effect
        tabBtn.MouseEnter:Connect(function()
            if selectedTab ~= Tab then
                Tween(tabBtn, {TextColor3 = Novoline.Scheme.FontColor}, 0.15)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if selectedTab ~= Tab then
                Tween(tabBtn, {TextColor3 = Novoline.Scheme.TextMuted}, 0.15)
            end
        end)
        
        tabBtn.MouseButton1Click:Connect(SelectTab)
        
        tabs[#tabs + 1] = Tab
        
        if #tabs == 1 then
            SelectTab()
        end
        
        -- AddLeftGroupbox
        function Tab:AddLeftGroupbox(gbConfig)
            return Tab:AddGroupbox(gbConfig, 0)
        end
        
        -- AddRightGroupbox
        function Tab:AddRightGroupbox(gbConfig)
            return Tab:AddGroupbox(gbConfig, 1)
        end
        
        -- AddGroupbox (Core)
        function Tab:AddGroupbox(gbConfig, side)
            gbConfig = gbConfig or {}
            local Groupbox = {}
            Groupbox.__index = Groupbox
            Groupbox.Title = gbConfig.Title or "Groupbox"
            Groupbox.Elements = {}
            
            local groupBox = Create("Frame", {
                Name = "GB_" .. self.Title,
                Size = UDim2.new(0.5, -3, 1, 0),
                BackgroundColor3 = Novoline.Scheme.MainColor,
                BorderSizePixel = 0,
                LayoutOrder = side,
                ZIndex = 5
            }, tabContent)
            
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }, groupBox)
            RegisterColor(groupBox, "BackgroundColor3", "MainColor")
            
            local gbOutline = Create("UIStroke", {
                Color = Novoline.Scheme.OutlineColor,
                Thickness = 1,
            }, groupBox)
            RegisterColor(gbOutline, "Color", "OutlineColor")
            
            -- Groupbox Title
            local gbTitle = Create("TextLabel", {
                Text = self.Title,
                Size = UDim2.new(1, -15, 0, 26),
                Position = UDim2.new(0, 12, 0, 2),
                BackgroundTransparency = 1,
                TextColor3 = Novoline.Scheme.FontColor,
                TextSize = 12,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, groupBox)
            RegisterColor(gbTitle, "TextColor3", "FontColor")
            
            -- Title underline
            local titleLine = Create("Frame", {
                Size = UDim2.new(1, -20, 0, 1),
                Position = UDim2.new(0, 10, 0, 28),
                BackgroundColor3 = Novoline.Scheme.OutlineColor,
                BorderSizePixel = 0,
                ZIndex = 6
            }, groupBox)
            RegisterColor(titleLine, "BackgroundColor3", "OutlineColor")
            
            -- Elements Scroll Frame
            local scrollFrame = Create("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, -35),
                Position = UDim2.new(0, 0, 0, 33),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Color3.fromRGB(50, 50, 70),
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 6
            }, groupBox)
            
            local elementList = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 3),
            }, scrollFrame)
            
            local elementPadding = Create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 8),
            }, scrollFrame)
            
            Groupbox.Container = scrollFrame
            Groupbox.Frame = groupBox
            
            -- ============ TOGGLE ============
            function Groupbox:AddToggle(toggleConfig)
                toggleConfig = toggleConfig or {}
                local Toggle = {}
                Toggle.Type = "Toggle"
                Toggle.Value = toggleConfig.Default or false
                Toggle.Callback = toggleConfig.Callback or function() end
                Toggle.ChangedCallbacks = {}
                
                if toggleConfig.Key then
                    Novoline.Toggles[toggleConfig.Key] = Toggle
                end
                
                local toggleFrame = Create("Frame", {
                    Name = "Toggle",
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local toggleLabel = Create("TextLabel", {
                    Text = toggleConfig.Text or "Toggle",
                    Size = UDim2.new(1, -48, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 8
                }, toggleFrame)
                RegisterColor(toggleLabel, "TextColor3", "FontColor")
                
                -- Toggle Switch Background
                local toggleBg = Create("Frame", {
                    Size = UDim2.new(0, 38, 0, 18),
                    Position = UDim2.new(1, -42, 0.5, -9),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 55),
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, toggleFrame)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, toggleBg)
                
                -- Toggle Switch Circle
                local toggleCircle = Create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 2, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(80, 80, 100),
                    BorderSizePixel = 0,
                    ZIndex = 9
                }, toggleBg)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, toggleCircle)
                
                local function UpdateToggleVisual()
                    if Toggle.Value then
                        Tween(toggleBg, {BackgroundColor3 = Novoline.Scheme.AccentColor}, 0.2)
                        Tween(toggleCircle, {Position = UDim2.new(0, 22, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                    else
                        Tween(toggleBg, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}, 0.2)
                        Tween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(80, 80, 100)}, 0.2)
                    end
                end
                
                function Toggle:SetValue(value)
                    Toggle.Value = value
                    UpdateToggleVisual()
                    Toggle.Callback(value)
                    for _, cb in ipairs(Toggle.ChangedCallbacks) do
                        cb(value)
                    end
                end
                
                function Toggle:OnChanged(callback)
                    table.insert(Toggle.ChangedCallbacks, callback)
                end
                
                function Toggle:SetVisible(visible)
                    toggleFrame.Visible = visible
                end
                
                toggleFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Toggle:SetValue(not Toggle.Value)
                    end
                end)
                
                -- Color Picker Attachment
                if toggleConfig.Color then
                    local colorIndicator = Create("Frame", {
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = UDim2.new(0, -18, 0.5, -7),
                        BackgroundColor3 = toggleConfig.Color.Default or Color3.fromRGB(255, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 8
                    }, toggleLabel)
                    Create("UICorner", { CornerRadius = UDim.new(0, 3) }, colorIndicator)
                    
                    local cp = self:AddColorPicker({
                        Default = toggleConfig.Color.Default or Color3.fromRGB(255, 0, 0),
                        Callback = toggleConfig.Color.Callback or function() end,
                        Transparency = toggleConfig.Color.Transparency
                    })
                    cp:SetVisible(false)
                    
                    colorIndicator.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            cp:SetVisible(not cp.Popup.Visible)
                            local pos = colorIndicator.AbsolutePosition
                            cp.Popup.Position = UDim2.new(0, pos.X, 0, pos.Y + 20)
                        end
                    end)
                    
                    cp:OnChanged(function(color)
                        colorIndicator.BackgroundColor3 = color
                    end)
                end
                
                if Toggle.Value then
                    task.defer(UpdateToggleVisual)
                end
                
                Toggle.Frame = toggleFrame
                self.Elements[#self.Elements + 1] = Toggle
                return Toggle
            end
            
            -- ============ SLIDER ============
            function Groupbox:AddSlider(sliderConfig)
                sliderConfig = sliderConfig or {}
                local Slider = {}
                Slider.Type = "Slider"
                Slider.Value = sliderConfig.Default or sliderConfig.Min or 0
                Slider.Min = sliderConfig.Min or 0
                Slider.Max = sliderConfig.Max or 100
                Slider.Rounding = sliderConfig.Rounding or 1
                Slider.Callback = sliderConfig.Callback or function() end
                Slider.ChangedCallbacks = {}
                Slider.Suffix = sliderConfig.Suffix or ""
                
                if sliderConfig.Key then
                    Novoline.Options[sliderConfig.Key] = Slider
                end
                
                local sliderFrame = Create("Frame", {
                    Name = "Slider",
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                -- Header
                local sliderHeader = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    ZIndex = 8
                }, sliderFrame)
                
                local sliderLabel = Create("TextLabel", {
                    Text = sliderConfig.Text or "Slider",
                    Size = UDim2.new(0.65, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 9
                }, sliderHeader)
                RegisterColor(sliderLabel, "TextColor3", "FontColor")
                
                local sliderValueLabel = Create("TextLabel", {
                    Text = Round(Slider.Value, Slider.Rounding) .. Slider.Suffix,
                    Size = UDim2.new(0.35, 0, 1, 0),
                    Position = UDim2.new(0.65, 0, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.AccentColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 9
                }, sliderHeader)
                RegisterColor(sliderValueLabel, "TextColor3", "AccentColor")
                
                -- Track
                local sliderTrack = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 8),
                    Position = UDim2.new(0, 0, 0, 28),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, sliderFrame)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderTrack)
                
                -- Fill
                local sliderFill = Create("Frame", {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Novoline.Scheme.AccentColor,
                    BorderSizePixel = 0,
                    ZIndex = 9
                }, sliderTrack)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderFill)
                RegisterColor(sliderFill, "BackgroundColor3", "AccentColor")
                
                -- Handle
                local sliderHandle = Create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, -7, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 2,
                    BorderColor3 = Novoline.Scheme.AccentColor,
                    ZIndex = 10
                }, sliderTrack)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderHandle)
                
                local isSliding = false
                
                local function UpdateSliderVisual()
                    local percent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    percent = Clamp(percent, 0, 1)
                    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    sliderHandle.Position = UDim2.new(percent, -7, 0.5, -7)
                    sliderValueLabel.Text = Round(Slider.Value, Slider.Rounding) .. Slider.Suffix
                end
                
                function Slider:SetValue(value)
                    Slider.Value = Clamp(Round(value, Slider.Rounding), Slider.Min, Slider.Max)
                    UpdateSliderVisual()
                    Slider.Callback(Slider.Value)
                    for _, cb in ipairs(Slider.ChangedCallbacks) do
                        cb(Slider.Value)
                    end
                end
                
                function Slider:OnChanged(callback)
                    table.insert(Slider.ChangedCallbacks, callback)
                end
                
                function Slider:SetVisible(visible)
                    sliderFrame.Visible = visible
                end
                
                local function HandleSliderInput(input)
                    local percent = Clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
                    Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * percent)
                end
                
                sliderTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isSliding = true
                        HandleSliderInput(input)
                    end
                end)
                
                sliderTrack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isSliding = false
                    end
                end)
                
                Connect(UserInputService.InputChanged, function(input)
                    if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        HandleSliderInput(input)
                    end
                end)
                
                UpdateSliderVisual()
                Slider.Frame = sliderFrame
                self.Elements[#self.Elements + 1] = Slider
                return Slider
            end
            
            -- ============ DROPDOWN ============
            function Groupbox:AddDropdown(ddConfig)
                ddConfig = ddConfig or {}
                local Dropdown = {}
                Dropdown.Type = "Dropdown"
                Dropdown.Value = ddConfig.Default or nil
                Dropdown.Values = ddConfig.Values or {}
                Dropdown.Multi = ddConfig.Multi or false
                Dropdown.Searchable = ddConfig.Searchable or false
                Dropdown.SpecialType = ddConfig.SpecialType or nil
                Dropdown.Callback = ddConfig.Callback or function() end
                Dropdown.ChangedCallbacks = {}
                Dropdown.Selected = {}
                
                if ddConfig.Key then
                    Novoline.Options[ddConfig.Key] = Dropdown
                end
                
                if Dropdown.Multi then
                    for _, v in ipairs(Dropdown.Values) do
                        Dropdown.Selected[v] = false
                    end
                    if type(ddConfig.Default) == "table" then
                        for _, v in ipairs(ddConfig.Default) do
                            Dropdown.Selected[v] = true
                        end
                    end
                end
                
                local ddFrame = Create("Frame", {
                    Name = "Dropdown",
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                -- Dropdown Button
                local ddBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    Text = Dropdown.Multi and "Select..." or (Dropdown.Value or ddConfig.Text or "Dropdown"),
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 11,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 8,
                    AutoButtonColor = false
                }, ddFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }, ddBtn)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, ddBtn)
                RegisterColor(ddBtn, "TextColor3", "FontColor")
                
                local ddArrow = Create("TextLabel", {
                    Text = "▾",
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -22, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.TextMuted,
                    TextSize = 12,
                    ZIndex = 9
                }, ddBtn)
                RegisterColor(ddArrow, "TextColor3", "TextMuted")
                
                -- Dropdown List (in popup container for Z-indexing)
                local ddList = Create("Frame", {
                    Name = "DropdownList",
                    BackgroundColor3 = Novoline.Scheme.MainColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 100
                }, popupContainer)
                Create("UICorner", { CornerRadius = UDim.new(0, 8) }, ddList)
                RegisterColor(ddList, "BackgroundColor3", "MainColor")
                
                local ddListOutline = Create("UIStroke", {
                    Color = Novoline.Scheme.OutlineColor,
                    Thickness = 1,
                }, ddList)
                RegisterColor(ddListOutline, "Color", "OutlineColor")
                
                local ddScroll = Create("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Color3.fromRGB(50, 50, 70),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 101
                }, ddList)
                
                local ddListLayout = Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                }, ddScroll)
                
                local ddListPadding = Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                }, ddScroll)
                
                -- Search Box
                local searchBox = nil
                if Dropdown.Searchable then
                    searchBox = Create("TextBox", {
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                        BorderSizePixel = 0,
                        Text = "",
                        PlaceholderText = "Search...",
                        PlaceholderColor3 = Novoline.Scheme.TextMuted,
                        TextColor3 = Novoline.Scheme.FontColor,
                        TextSize = 11,
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                        ClearTextOnFocus = false,
                        ZIndex = 102,
                        LayoutOrder = -1
                    }, ddScroll)
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }, searchBox)
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, searchBox)
                    RegisterColor(searchBox, "TextColor3", "FontColor")
                    
                    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        for _, child in ipairs(ddScroll:GetChildren()) do
                            if child:IsA("TextButton") then
                                child.Visible = child.Text:lower():find(searchBox.Text:lower()) ~= nil
                            end
                        end
                    end)
                end
                
                local isOpen = false
                local optionButtons = {}
                
                local function UpdateListPosition()
                    local btnPos = ddBtn.AbsolutePosition
                    local btnSize = ddBtn.AbsoluteSize
                    ddList.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + btnSize.Y + 2)
                    local listHeight = #Dropdown.Values * 24 + (searchBox and 30 or 8)
                    ddList.Size = UDim2.new(0, btnSize.X, 0, math.min(160, listHeight))
                end
                
                local function CreateOptions()
                    for _, btn in ipairs(optionButtons) do
                        pcall(function() btn:Destroy() end)
                    end
                    optionButtons = {}
                    
                    for i, value in ipairs(Dropdown.Values) do
                        local optBtn = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 22),
                            BackgroundColor3 = Color3.fromRGB(35, 35, 50),
                            BorderSizePixel = 0,
                            Text = tostring(value),
                            TextColor3 = Novoline.Scheme.FontColor,
                            TextSize = 11,
                            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 102,
                            LayoutOrder = i,
                            AutoButtonColor = false
                        }, ddScroll)
                        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, optBtn)
                        Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, optBtn)
                        RegisterColor(optBtn, "TextColor3", "FontColor")
                        
                        if Dropdown.Multi then
                            local check = Create("TextLabel", {
                                Text = Dropdown.Selected[value] and "✓" or "",
                                Size = UDim2.new(0, 20, 1, 0),
                                Position = UDim2.new(1, -22, 0, 0),
                                BackgroundTransparency = 1,
                                TextColor3 = Novoline.Scheme.AccentColor,
                                TextSize = 12,
                                ZIndex = 103
                            }, optBtn)
                            RegisterColor(check, "TextColor3", "AccentColor")
                        end
                        
                        optBtn.MouseEnter:Connect(function()
                            Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(45, 45, 65)}, 0.12)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}, 0.12)
                        end)
                        
                        optBtn.MouseButton1Click:Connect(function()
                            if Dropdown.Multi then
                                Dropdown.Selected[value] = not Dropdown.Selected[value]
                                for _, child in ipairs(optBtn:GetChildren()) do
                                    if child:IsA("TextLabel") and child.ZIndex == 103 then
                                        child.Text = Dropdown.Selected[value] and "✓" or ""
                                    end
                                end
                                Dropdown.Callback(Dropdown.Selected)
                                for _, cb in ipairs(Dropdown.ChangedCallbacks) do
                                    cb(Dropdown.Selected)
                                end
                            else
                                Dropdown.Value = value
                                ddBtn.Text = tostring(value)
                                ddList.Visible = false
                                isOpen = false
                                Tween(ddArrow, {Rotation = 0}, 0.2)
                                Dropdown.Callback(value)
                                for _, cb in ipairs(Dropdown.ChangedCallbacks) do
                                    cb(value)
                                end
                            end
                        end)
                        
                        table.insert(optionButtons, optBtn)
                    end
                end
                
                CreateOptions()
                
                -- Player Special Type
                if Dropdown.SpecialType == "Player" then
                    local function UpdatePlayers()
                        Dropdown.Values = {}
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= Players.LocalPlayer then
                                table.insert(Dropdown.Values, player.Name)
                            end
                        end
                        table.insert(Dropdown.Values, "All")
                        CreateOptions()
                    end
                    
                    Connect(Players.PlayerAdded, function(player)
                        if player ~= Players.LocalPlayer then
                            table.insert(Dropdown.Values, player.Name)
                            CreateOptions()
                        end
                    end)
                    
                    Connect(Players.PlayerRemoving, function(player)
                        for i, name in ipairs(Dropdown.Values) do
                            if name == player.Name then
                                table.remove(Dropdown.Values, i)
                                break
                            end
                        end
                        CreateOptions()
                    end)
                    
                    UpdatePlayers()
                end
                
                ddBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        UpdateListPosition()
                        ddList.Visible = true
                        Tween(ddArrow, {Rotation = 180}, 0.2)
                    else
                        ddList.Visible = false
                        Tween(ddArrow, {Rotation = 0}, 0.2)
                    end
                end)
                
                function Dropdown:SetValue(value)
                    if Dropdown.Multi then
                        Dropdown.Selected = value or {}
                        for _, btn in ipairs(optionButtons) do
                            for _, child in ipairs(btn:GetChildren()) do
                                if child:IsA("TextLabel") and child.ZIndex == 103 then
                                    child.Text = Dropdown.Selected[btn.Text] and "✓" or ""
                                end
                            end
                        end
                        Dropdown.Callback(Dropdown.Selected)
                    else
                        Dropdown.Value = value
                        ddBtn.Text = tostring(value)
                        Dropdown.Callback(value)
                    end
                    for _, cb in ipairs(Dropdown.ChangedCallbacks) do
                        cb(Dropdown.Multi and Dropdown.Selected or Dropdown.Value)
                    end
                end
                
                function Dropdown:OnChanged(callback)
                    table.insert(Dropdown.ChangedCallbacks, callback)
                end
                
                function Dropdown:SetVisible(visible)
                    ddFrame.Visible = visible
                    if not visible then ddList.Visible = false end
                end
                
                function Dropdown:Refresh(values)
                    Dropdown.Values = values or {}
                    CreateOptions()
                end
                
                Dropdown.Frame = ddFrame
                Dropdown.ListFrame = ddList
                self.Elements[#self.Elements + 1] = Dropdown
                return Dropdown
            end
            
            -- ============ COLOR PICKER ============
            function Groupbox:AddColorPicker(cpConfig)
                cpConfig = cpConfig or {}
                local ColorPicker = {}
                ColorPicker.Type = "ColorPicker"
                ColorPicker.Value = cpConfig.Default or Color3.fromRGB(255, 0, 0)
                ColorPicker.Transparency = cpConfig.Transparency or 0
                ColorPicker.Callback = cpConfig.Callback or function() end
                ColorPicker.ChangedCallbacks = {}
                
                if cpConfig.Key then
                    Novoline.Options[cpConfig.Key] = ColorPicker
                end
                
                local cpFrame = Create("Frame", {
                    Name = "ColorPicker",
                    Size = UDim2.new(1, 0, 0, cpConfig.Text and 28 or 0),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local cpLabel = nil
                if cpConfig.Text and cpConfig.Text ~= "" then
                    cpLabel = Create("TextLabel", {
                        Text = cpConfig.Text,
                        Size = UDim2.new(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        TextColor3 = Novoline.Scheme.FontColor,
                        TextSize = 12,
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 8
                    }, cpFrame)
                    RegisterColor(cpLabel, "TextColor3", "FontColor")
                end
                
                -- Color Preview
                local colorPreview = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, cpConfig.Text and 22 or 0),
                    BackgroundColor3 = ColorPicker.Value,
                    BorderSizePixel = 0,
                    Text = "",
                    ZIndex = 8,
                    AutoButtonColor = false
                }, cpFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }, colorPreview)
                
                -- Popup (in popup container)
                local cpPopup = Create("Frame", {
                    BackgroundColor3 = Novoline.Scheme.MainColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 100,
                    Size = UDim2.new(0, 210, 0, 180)
                }, popupContainer)
                Create("UICorner", { CornerRadius = UDim.new(0, 8) }, cpPopup)
                RegisterColor(cpPopup, "BackgroundColor3", "MainColor")
                
                local cpPopupOutline = Create("UIStroke", {
                    Color = Novoline.Scheme.OutlineColor,
                    Thickness = 1,
                }, cpPopup)
                RegisterColor(cpPopupOutline, "Color", "OutlineColor")
                
                -- Saturation/Brightness Box
                local sbBox = Create("Frame", {
                    Size = UDim2.new(1, -12, 0, 120),
                    Position = UDim2.new(0, 6, 0, 6),
                    BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 101,
                    ClipsDescendants = true
                }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }, sbBox)
                
                -- White gradient
                local whiteOverlay = Create("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 102
                }, sbBox)
                Create("UIGradient", {
                    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
                    Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                }, whiteOverlay)
                
                -- Black gradient
                local blackOverlay = Create("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 103
                }, sbBox)
                Create("UIGradient", {
                    Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                    Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
                    Rotation = 90
                }, blackOverlay)
                
                -- SB Cursor
                local sbCursor = Create("Frame", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0, -5, 0, -5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 2,
                    BorderColor3 = Color3.new(0, 0, 0),
                    ZIndex = 105
                }, sbBox)
                
                -- Hue Slider
                local hueSlider = Create("Frame", {
                    Size = UDim2.new(1, -12, 0, 14),
                    Position = UDim2.new(0, 6, 0, 132),
                    BackgroundColor3 = Color3.new(1, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 101
                }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, hueSlider)
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                    })
                }, hueSlider)
                
                local hueCursor = Create("Frame", {
                    Size = UDim2.new(0, 8, 0, 18),
                    Position = UDim2.new(0, -4, 0.5, -9),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 1,
                    BorderColor3 = Color3.new(0, 0, 0),
                    ZIndex = 102
                }, hueSlider)
                
                -- Transparency Slider (if enabled)
                local transSlider = nil
                if ColorPicker.Transparency ~= nil then
                    transSlider = Create("Frame", {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 6, 0, 150),
                        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
                        BorderSizePixel = 0,
                        ZIndex = 101
                    }, cpPopup)
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, transSlider)
                    
                    local transFill = Create("Frame", {
                        Size = UDim2.new(1 - ColorPicker.Transparency, 0, 1, 0),
                        BackgroundColor3 = ColorPicker.Value,
                        BorderSizePixel = 0,
                        ZIndex = 102
                    }, transSlider)
                end
                
                -- Hex Input
                local hexInput = Create("TextBox", {
                    Size = UDim2.new(0.5, -9, 0, 18),
                    Position = UDim2.new(0, 6, 0, 160),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    Text = Color3ToHex(ColorPicker.Value),
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 10,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                    ZIndex = 101,
                    ClearTextOnFocus = false
                }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, hexInput)
                RegisterColor(hexInput, "TextColor3", "FontColor")
                
                -- RGB Input
                local rgbInput = Create("TextBox", {
                    Size = UDim2.new(0.5, -9, 0, 18),
                    Position = UDim2.new(0.5, 3, 0, 160),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    Text = string.format("%d, %d, %d", math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255)),
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 10,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                    ZIndex = 101,
                    ClearTextOnFocus = false
                }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, rgbInput)
                RegisterColor(rgbInput, "TextColor3", "FontColor")
                
                -- State
                local hue, sat, val = Color3ToHSV(ColorPicker.Value)
                local sbDragging = false
                local hueDragging = false
                
                local function UpdateColorFromHSV()
                    local color = HSVToColor3(hue, sat, val)
                    ColorPicker.Value = color
                    colorPreview.BackgroundColor3 = color
                    sbBox.BackgroundColor3 = HSVToColor3(hue, 1, 1)
                    hexInput.Text = Color3ToHex(color)
                    rgbInput.Text = string.format("%d, %d, %d", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
                    if transFill then transFill.BackgroundColor3 = color end
                    ColorPicker.Callback(color)
                    for _, cb in ipairs(ColorPicker.ChangedCallbacks) do
                        cb(color)
                    end
                end
                
                local function UpdateCursors()
                    sbCursor.Position = UDim2.new(sat, -5, 1 - val, -5)
                    hueCursor.Position = UDim2.new(hue, -4, 0.5, -9)
                end
                
                -- SB Dragging
                sbBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sbDragging = true
                        sat = Clamp((input.Position.X - sbBox.AbsolutePosition.X) / sbBox.AbsoluteSize.X, 0, 1)
                        val = 1 - Clamp((input.Position.Y - sbBox.AbsolutePosition.Y) / sbBox.AbsoluteSize.Y, 0, 1)
                        UpdateCursors()
                        UpdateColorFromHSV()
                    end
                end)
                
                sbBox.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sbDragging = false
                    end
                end)
                
                -- Hue Dragging
                hueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        hue = Clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
                        UpdateCursors()
                        UpdateColorFromHSV()
                    end
                end)
                
                hueSlider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = false
                    end
                end)
                
                -- Global Input Changed
                Connect(UserInputService.InputChanged, function(input)
                    if sbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        sat = Clamp((input.Position.X - sbBox.AbsolutePosition.X) / sbBox.AbsoluteSize.X, 0, 1)
                        val = 1 - Clamp((input.Position.Y - sbBox.AbsolutePosition.Y) / sbBox.AbsoluteSize.Y, 0, 1)
                        UpdateCursors()
                        UpdateColorFromHSV()
                    elseif hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        hue = Clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
                        UpdateCursors()
                        UpdateColorFromHSV()
                    end
                end)
                
                -- Hex Input
                hexInput.FocusLost:Connect(function()
                    local success, color = pcall(HexToColor3, hexInput.Text)
                    if success then
                        hue, sat, val = Color3ToHSV(color)
                        UpdateCursors()
                        UpdateColorFromHSV()
                    else
                        hexInput.Text = Color3ToHex(ColorPicker.Value)
                    end
                end)
                
                -- RGB Input
                rgbInput.FocusLost:Connect(function()
                    local parts = {}
                    for num in rgbInput.Text:gmatch("%d+") do
                        table.insert(parts, tonumber(num))
                    end
                    if #parts >= 3 then
                        local color = Color3.fromRGB(Clamp(parts[1], 0, 255), Clamp(parts[2], 0, 255), Clamp(parts[3], 0, 255))
                        hue, sat, val = Color3ToHSV(color)
                        UpdateCursors()
                        UpdateColorFromHSV()
                    else
                        rgbInput.Text = string.format("%d, %d, %d", math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255))
                    end
                end)
                
                -- Toggle Popup
                colorPreview.MouseButton1Click:Connect(function()
                    local isVisible = not cpPopup.Visible
                    if isVisible then
                        local pos = colorPreview.AbsolutePosition
                        local size = colorPreview.AbsoluteSize
                        cpPopup.Position = UDim2.new(0, pos.X, 0, pos.Y + size.Y + 4)
                    end
                    cpPopup.Visible = isVisible
                end)
                
                function ColorPicker:SetValue(color)
                    ColorPicker.Value = color
                    hue, sat, val = Color3ToHSV(color)
                    colorPreview.BackgroundColor3 = color
                    sbBox.BackgroundColor3 = HSVToColor3(hue, 1, 1)
                    hexInput.Text = Color3ToHex(color)
                    rgbInput.Text = string.format("%d, %d, %d", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
                    if transFill then transFill.BackgroundColor3 = color end
                    UpdateCursors()
                    ColorPicker.Callback(color)
                    for _, cb in ipairs(ColorPicker.ChangedCallbacks) do
                        cb(color)
                    end
                end
                
                function ColorPicker:OnChanged(callback)
                    table.insert(ColorPicker.ChangedCallbacks, callback)
                end
                
                function ColorPicker:SetVisible(visible)
                    cpFrame.Visible = visible
                    if not visible then cpPopup.Visible = false end
                end
                
                UpdateCursors()
                ColorPicker.Frame = cpFrame
                ColorPicker.Popup = cpPopup
                self.Elements[#self.Elements + 1] = ColorPicker
                return ColorPicker
            end
            
            -- ============ KEY PICKER ============
            function Groupbox:AddKeyPicker(kpConfig)
                kpConfig = kpConfig or {}
                local KeyPicker = {}
                KeyPicker.Type = "KeyPicker"
                KeyPicker.Value = kpConfig.Default or "None"
                KeyPicker.Mode = kpConfig.Mode or "Toggle"
                KeyPicker.Callback = kpConfig.Callback or function() end
                KeyPicker.ChangedCallbacks = {}
                KeyPicker.HoldState = false
                KeyPicker.ToggleState = false
                KeyPicker.SyncToggle = kpConfig.SyncToggle or nil
                
                if kpConfig.Key then
                    Novoline.Options[kpConfig.Key] = KeyPicker
                end
                
                local kpFrame = Create("Frame", {
                    Name = "KeyPicker",
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local kpLabel = Create("TextLabel", {
                    Text = kpConfig.Text or "Keybind",
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 8
                }, kpFrame)
                RegisterColor(kpLabel, "TextColor3", "FontColor")
                
                local kpBtn = Create("TextButton", {
                    Size = UDim2.new(0.5, -5, 0, 20),
                    Position = UDim2.new(0.5, 5, 0.5, -10),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    Text = KeyPicker.Value,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 10,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    ZIndex = 8,
                    AutoButtonColor = false
                }, kpFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, kpBtn)
                RegisterColor(kpBtn, "TextColor3", "FontColor")
                
                local waitingForKey = false
                
                kpBtn.MouseButton1Click:Connect(function()
                    waitingForKey = not waitingForKey
                    if waitingForKey then
                        kpBtn.Text = "[...]"
                        kpBtn.TextColor3 = Novoline.Scheme.AccentColor
                    else
                        kpBtn.Text = KeyPicker.Value
                        kpBtn.TextColor3 = Novoline.Scheme.FontColor
                    end
                end)
                
                Connect(UserInputService.InputBegan, function(input, processed)
                    if waitingForKey then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            KeyPicker.Value = input.KeyCode.Name
                        elseif input.UserInputType.Name:find("MouseButton") then
                            KeyPicker.Value = input.UserInputType.Name
                        else
                            return
                        end
                        kpBtn.Text = KeyPicker.Value
                        kpBtn.TextColor3 = Novoline.Scheme.FontColor
                        waitingForKey = false
                        KeyPicker.Callback(KeyPicker.Value)
                        for _, cb in ipairs(KeyPicker.ChangedCallbacks) do
                            cb(KeyPicker.Value)
                        end
                        return
                    end
                    
                    if processed and not kpConfig.NoInputHandled then return end
                    
                    local inputName = nil
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        inputName = input.KeyCode.Name
                    elseif input.UserInputType.Name:find("MouseButton") then
                        inputName = input.UserInputType.Name
                    end
                    
                    if inputName and inputName == KeyPicker.Value then
                        if KeyPicker.Mode == "Toggle" then
                            KeyPicker.ToggleState = not KeyPicker.ToggleState
                            KeyPicker.Callback(KeyPicker.ToggleState)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do
                                cb(KeyPicker.ToggleState)
                            end
                            if KeyPicker.SyncToggle then
                                KeyPicker.SyncToggle:SetValue(KeyPicker.ToggleState)
                            end
                        elseif KeyPicker.Mode == "Hold" then
                            KeyPicker.HoldState = true
                            KeyPicker.Callback(true)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do
                                cb(true)
                            end
                        elseif KeyPicker.Mode == "Always" then
                            KeyPicker.Callback(true)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do
                                cb(true)
                            end
                        end
                    end
                end)
                
                Connect(UserInputService.InputEnded, function(input)
                    if KeyPicker.Mode == "Hold" then
                        local inputName = nil
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            inputName = input.KeyCode.Name
                        elseif input.UserInputType.Name:find("MouseButton") then
                            inputName = input.UserInputType.Name
                        end
                        
                        if inputName and inputName == KeyPicker.Value and KeyPicker.HoldState then
                            KeyPicker.HoldState = false
                            KeyPicker.Callback(false)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do
                                cb(false)
                            end
                        end
                    end
                end)
                
                function KeyPicker:SetValue(value)
                    KeyPicker.Value = value
                    kpBtn.Text = value
                    KeyPicker.Callback(value)
                    for _, cb in ipairs(KeyPicker.ChangedCallbacks) do
                        cb(value)
                    end
                end
                
                function KeyPicker:OnChanged(callback)
                    table.insert(KeyPicker.ChangedCallbacks, callback)
                end
                
                function KeyPicker:SetVisible(visible)
                    kpFrame.Visible = visible
                end
                
                KeyPicker.Frame = kpFrame
                self.Elements[#self.Elements + 1] = KeyPicker
                return KeyPicker
            end
            
            -- ============ INPUT ============
            function Groupbox:AddInput(inputConfig)
                inputConfig = inputConfig or {}
                local Input = {}
                Input.Type = "Input"
                Input.Value = inputConfig.Default or ""
                Input.Placeholder = inputConfig.Placeholder or "Input..."
                Input.Callback = inputConfig.Callback or function() end
                Input.ChangedCallbacks = {}
                Input.Numeric = inputConfig.Numeric or false
                
                if inputConfig.Key then
                    Novoline.Options[inputConfig.Key] = Input
                end
                
                local inputFrame = Create("Frame", {
                    Name = "Input",
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local inputLabel = Create("TextLabel", {
                    Text = inputConfig.Text or "Input",
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 8
                }, inputFrame)
                RegisterColor(inputLabel, "TextColor3", "FontColor")
                
                local inputBox = Create("TextBox", {
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    Text = Input.Value,
                    PlaceholderText = Input.Placeholder,
                    PlaceholderColor3 = Novoline.Scheme.TextMuted,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    ClearTextOnFocus = false,
                    ZIndex = 8
                }, inputFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }, inputBox)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, inputBox)
                RegisterColor(inputBox, "TextColor3", "FontColor")
                RegisterColor(inputBox, "PlaceholderColor3", "TextMuted")
                
                if Input.Numeric then
                    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                        if inputBox.Text ~= "" and not inputBox.Text:match("^%d*%.?%d*$") then
                            inputBox.Text = inputBox.Text:gsub("[^%d.]", "")
                        end
                    end)
                end
                
                inputBox.FocusLost:Connect(function()
                    Input.Value = inputBox.Text
                    Input.Callback(Input.Value)
                    for _, cb in ipairs(Input.ChangedCallbacks) do
                        cb(Input.Value)
                    end
                end)
                
                function Input:SetValue(value)
                    Input.Value = value
                    inputBox.Text = value
                    Input.Callback(value)
                    for _, cb in ipairs(Input.ChangedCallbacks) do
                        cb(value)
                    end
                end
                
                function Input:OnChanged(callback)
                    table.insert(Input.ChangedCallbacks, callback)
                end
                
                function Input:SetVisible(visible)
                    inputFrame.Visible = visible
                end
                
                Input.Frame = inputFrame
                self.Elements[#self.Elements + 1] = Input
                return Input
            end
            
            -- ============ BUTTON ============
            function Groupbox:AddButton(btnConfig)
                btnConfig = btnConfig or {}
                local Button = {}
                Button.Type = "Button"
                Button.Callback = btnConfig.Callback or function() end
                Button.ChangedCallbacks = {}
                
                local btnFrame = Create("Frame", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local btn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Novoline.Scheme.AccentColor,
                    BorderSizePixel = 0,
                    Text = btnConfig.Text or "Button",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                    ZIndex = 8,
                    AutoButtonColor = false
                }, btnFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)
                RegisterColor(btn, "BackgroundColor3", "AccentColor")
                
                btn.MouseEnter:Connect(function()
                    Tween(btn, {BackgroundColor3 = LightenColor(Novoline.Scheme.AccentColor, 0.15)}, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, {BackgroundColor3 = Novoline.Scheme.AccentColor}, 0.15)
                end)
                
                btn.MouseButton1Click:Connect(function()
                    Button.Callback()
                    Tween(btn, {Size = UDim2.new(0.98, 0, 0.92, 0)}, 0.08)
                    task.delay(0.1, function()
                        Tween(btn, {Size = UDim2.new(1, 0, 1, 0)}, 0.08)
                    end)
                end)
                
                function Button:SetVisible(visible)
                    btnFrame.Visible = visible
                end
                
                function Button:AddButton(subConfig)
                    subConfig = subConfig or {}
                    local SubButton = {}
                    SubButton.Type = "Button"
                    SubButton.Callback = subConfig.Callback or function() end
                    
                    local subFrame = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundTransparency = 1,
                        ZIndex = 7,
                        LayoutOrder = #self.Elements + 1
                    }, scrollFrame)
                    
                    local subBtn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3 = Color3.fromRGB(40, 40, 58),
                        BorderSizePixel = 0,
                        Text = subConfig.Text or "Button",
                        TextColor3 = Novoline.Scheme.FontColor,
                        TextSize = 11,
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                        ZIndex = 8,
                        AutoButtonColor = false
                    }, subFrame)
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }, subBtn)
                    RegisterColor(subBtn, "TextColor3", "FontColor")
                    
                    subBtn.MouseEnter:Connect(function()
                        Tween(subBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 70)}, 0.12)
                    end)
                    subBtn.MouseLeave:Connect(function()
                        Tween(subBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 58)}, 0.12)
                    end)
                    
                    subBtn.MouseButton1Click:Connect(function()
                        SubButton.Callback()
                    end)
                    
                    function SubButton:SetVisible(visible)
                        subFrame.Visible = visible
                    end
                    
                    SubButton.Frame = subFrame
                    self.Elements[#self.Elements + 1] = SubButton
                    return SubButton
                end
                
                Button.Frame = btnFrame
                self.Elements[#self.Elements + 1] = Button
                return Button
            end
            
            -- ============ LABEL ============
            function Groupbox:AddLabel(labelConfig)
                labelConfig = labelConfig or {}
                local Label = {}
                Label.Type = "Label"
                Label.Value = labelConfig.Text or "Label"
                Label.ChangedCallbacks = {}
                
                local labelFrame = Create("Frame", {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local label = Create("TextLabel", {
                    Text = Label.Value,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 8
                }, labelFrame)
                RegisterColor(label, "TextColor3", "FontColor")
                
                function Label:SetText(text)
                    Label.Value = text
                    label.Text = text
                    for _, cb in ipairs(Label.ChangedCallbacks) do
                        cb(text)
                    end
                end
                
                function Label:OnChanged(callback)
                    table.insert(Label.ChangedCallbacks, callback)
                end
                
                function Label:SetVisible(visible)
                    labelFrame.Visible = visible
                end
                
                Label.Frame = labelFrame
                self.Elements[#self.Elements + 1] = Label
                return Label
            end
            
            -- ============ DIVIDER ============
            function Groupbox:AddDivider()
                local Divider = {}
                Divider.Type = "Divider"
                
                local divFrame = Create("Frame", {
                    Name = "Divider",
                    Size = UDim2.new(1, 0, 0, 10),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local line = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundColor3 = Novoline.Scheme.OutlineColor,
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, divFrame)
                RegisterColor(line, "BackgroundColor3", "OutlineColor")
                
                function Divider:SetVisible(visible)
                    divFrame.Visible = visible
                end
                
                Divider.Frame = divFrame
                self.Elements[#self.Elements + 1] = Divider
                return Divider
            end
            
            -- ============ CHECKBOX (ForceCheckbox mode) ============
            function Groupbox:AddCheckbox(cbConfig)
                if not Novoline.ForceCheckbox then
                    return self:AddToggle(cbConfig)
                end
                
                cbConfig = cbConfig or {}
                local Checkbox = {}
                Checkbox.Type = "Checkbox"
                Checkbox.Value = cbConfig.Default or false
                Checkbox.Callback = cbConfig.Callback or function() end
                Checkbox.ChangedCallbacks = {}
                
                if cbConfig.Key then
                    Novoline.Toggles[cbConfig.Key] = Checkbox
                end
                
                local cbFrame = Create("Frame", {
                    Name = "Checkbox",
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    ZIndex = 7,
                    LayoutOrder = #self.Elements + 1
                }, scrollFrame)
                
                local cbBox = Create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 0, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, cbFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }, cbBox)
                
                local cbCheck = Create("TextLabel", {
                    Text = "",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 11,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
                    ZIndex = 9
                }, cbBox)
                
                local cbLabel = Create("TextLabel", {
                    Text = cbConfig.Text or "Checkbox",
                    Size = UDim2.new(1, -24, 1, 0),
                    Position = UDim2.new(0, 24, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Novoline.Scheme.FontColor,
                    TextSize = 12,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 8
                }, cbFrame)
                RegisterColor(cbLabel, "TextColor3", "FontColor")
                
                local function UpdateCBVisual()
                    if Checkbox.Value then
                        Tween(cbBox, {BackgroundColor3 = Novoline.Scheme.AccentColor}, 0.2)
                        cbCheck.Text = "✓"
                    else
                        Tween(cbBox, {BackgroundColor3 = Color3.fromRGB(30, 30, 45)}, 0.2)
                        cbCheck.Text = ""
                    end
                end
                
                function Checkbox:SetValue(value)
                    Checkbox.Value = value
                    UpdateCBVisual()
                    Checkbox.Callback(value)
                    for _, cb in ipairs(Checkbox.ChangedCallbacks) do
                        cb(value)
                    end
                end
                
                function Checkbox:OnChanged(callback)
                    table.insert(Checkbox.ChangedCallbacks, callback)
                end
                
                function Checkbox:SetVisible(visible)
                    cbFrame.Visible = visible
                end
                
                cbFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Checkbox:SetValue(not Checkbox.Value)
                    end
                end)
                
                UpdateCBVisual()
                Checkbox.Frame = cbFrame
                self.Elements[#self.Elements + 1] = Checkbox
                return Checkbox
            end
            
            Tab.Groupboxes[#Tab.Groupboxes + 1] = Groupbox
            return Groupbox
        end
        
        -- AddKeybox (for key system)
        function Tab:AddKeybox(keyboxConfig)
            keyboxConfig = keyboxConfig or {}
            local Keybox = {}
            Keybox.Type = "Keybox"
            Keybox.Callback = keyboxConfig.Callback or function() end
            
            local kbFrame = Create("Frame", {
                Name = "Keybox",
                Size = UDim2.new(0.85, 0, 0, 140),
                Position = UDim2.new(0.075, 0, 0.25, 0),
                BackgroundColor3 = Novoline.Scheme.MainColor,
                BorderSizePixel = 0,
                ZIndex = 10
            }, tabContent)
            Create("UICorner", { CornerRadius = UDim.new(0, 10) }, kbFrame)
            RegisterColor(kbFrame, "BackgroundColor3", "MainColor")
            
            local kbOutline = Create("UIStroke", {
                Color = Novoline.Scheme.OutlineColor,
                Thickness = 1,
            }, kbFrame)
            RegisterColor(kbOutline, "Color", "OutlineColor")
            
            local kbTitle = Create("TextLabel", {
                Text = keyboxConfig.Title or "Key System",
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundTransparency = 1,
                TextColor3 = Novoline.Scheme.FontColor,
                TextSize = 15,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
                ZIndex = 11
            }, kbFrame)
            RegisterColor(kbTitle, "TextColor3", "FontColor")
            
            local kbInput = Create("TextBox", {
                Size = UDim2.new(0.85, 0, 0, 38),
                Position = UDim2.new(0.075, 0, 0, 42),
                BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                BorderSizePixel = 0,
                Text = "",
                PlaceholderText = keyboxConfig.Placeholder or "Enter your key...",
                PlaceholderColor3 = Novoline.Scheme.TextMuted,
                TextColor3 = Novoline.Scheme.FontColor,
                TextSize = 13,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                ClearTextOnFocus = false,
                ZIndex = 11
            }, kbFrame)
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }, kbInput)
            Create("UIPadding", { PaddingLeft = UDim.new(0, 12) }, kbInput)
            RegisterColor(kbInput, "TextColor3", "FontColor")
            
            local kbBtn = Create("TextButton", {
                Size = UDim2.new(0.85, 0, 0, 35),
                Position = UDim2.new(0.075, 0, 0, 88),
                BackgroundColor3 = Novoline.Scheme.AccentColor,
                BorderSizePixel = 0,
                Text = keyboxConfig.ButtonText or "Submit",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 13,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                ZIndex = 11,
                AutoButtonColor = false
            }, kbFrame)
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }, kbBtn)
            RegisterColor(kbBtn, "BackgroundColor3", "AccentColor")
            
            local kbStatus = Create("TextLabel", {
                Text = "",
                Size = UDim2.new(1, 0, 0, 15),
                Position = UDim2.new(0, 0, 1, -15),
                BackgroundTransparency = 1,
                TextColor3 = Novoline.Scheme.Error,
                TextSize = 11,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                ZIndex = 11
            }, kbFrame)
            
            kbBtn.MouseButton1Click:Connect(function()
                Keybox.Callback(kbInput.Text, function(success, msg)
                    kbStatus.Text = msg or ""
                    kbStatus.TextColor3 = success and Novoline.Scheme.Success or Novoline.Scheme.Error
                end)
            end)
            
            kbInput.FocusLost:Connect(function(enter)
                if enter then
                    kbBtn.MouseButton1Click:Fire()
                end
            end)
            
            function Keybox:SetVisible(visible)
                kbFrame.Visible = visible
            end
            
            Keybox.Frame = kbFrame
            return Keybox
        end
        
        return Tab
    end
    
    -- Notify Function
    function Window:Notify(notifyConfig)
        notifyConfig = notifyConfig or {}
        return CreateNotification(gui, {
            Title = notifyConfig.Title or "Notification",
            Content = notifyConfig.Content or "",
            Duration = notifyConfig.Duration or 4,
            Side = config.NotifySide or "Right"
        }, Novoline.Scheme)
    end
    
    return Window
end

return Novoline
