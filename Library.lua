--[[
    Novoline UI Library
    Obsidian/Linoria API Compatible
    Made by @thedude_whotalks
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
Novoline.Elements = {}
Novoline.KeybindFrame = nil
Novoline.ShowCustomCursor = true
Novoline.ToggleKeybind = nil
Novoline.UnloadCallbacks = {}
Novoline.NotifySide = "Left"
Novoline.DPIScale = 1
Novoline.Minimized = false

-- Default Color Scheme
Novoline.Scheme = {
    BackgroundColor = Color3.fromRGB(19, 19, 27),
    MainColor = Color3.fromRGB(25, 25, 35),
    AccentColor = Color3.fromRGB(79, 84, 235),
    OutlineColor = Color3.fromRGB(36, 36, 50),
    FontColor = Color3.fromRGB(200, 200, 210),
    DarkAccent = Color3.fromRGB(55, 58, 165),
    TextMuted = Color3.fromRGB(98, 98, 118),
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(235, 87, 87),
    Warning = Color3.fromRGB(235, 196, 73),
    SidebarColor = Color3.fromRGB(22, 22, 32),
    TopbarColor = Color3.fromRGB(24, 24, 34),
    InputColor = Color3.fromRGB(30, 30, 42),
    HoverColor = Color3.fromRGB(38, 38, 52),
    Red = Color3.fromRGB(235, 87, 87),
}

-- Utility Functions
local function Clamp(value, min, max) return math.clamp(value, min, max) end
local function Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

local function HexToColor3(hex)
    if type(hex) ~= "string" then return Color3.fromRGB(255, 255, 255) end
    hex = hex:gsub("#", "")
    if #hex < 6 then return Color3.fromRGB(255, 255, 255) end
    return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255)
end

local function Color3ToHex(color)
    return string.format("#%02X%02X%02X", math.floor(Clamp(color.R, 0, 1) * 255), math.floor(Clamp(color.G, 0, 1) * 255), math.floor(Clamp(color.B, 0, 1) * 255))
end

local function HSVToColor3(h, s, v) return Color3.fromHSV(Clamp(h, 0, 1), Clamp(s, 0, 1), Clamp(v, 0, 1)) end
local function Color3ToHSV(color) return Color3.toHSV(color) end
local function LightenColor(color, amount)
    return Color3.new(Clamp(color.R + amount, 0, 1), Clamp(color.G + amount, 0, 1), Clamp(color.B + amount, 0, 1))
end

-- Instance Creation Helper
local function Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() inst[k] = v end) end
    end
    if parent then inst.Parent = parent end
    return inst
end

-- Tween Helper
local function Tween(instance, props, duration, style, direction)
    if Novoline.Unloaded or not instance or not instance.Parent then return nil end
    local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
    tween:Play()
    table.insert(Novoline.Connections, tween)
    return tween
end

-- Color Registry
local function RegisterColor(element, property, colorKey)
    if not element or not property or not colorKey then return end
    table.insert(Novoline.ColorRegistry, { Element = element, Property = property, ColorKey = colorKey })
end

function Novoline:UpdateColorsUsingRegistry()
    for _, entry in ipairs(self.ColorRegistry) do
        if entry.Element and entry.Element.Parent and self.Scheme[entry.ColorKey] then
            pcall(function() entry.Element[entry.Property] = self.Scheme[entry.ColorKey] end)
        end
    end
end

function Novoline:SetScheme(scheme)
    for k, v in pairs(scheme) do
        if self.Scheme[k] ~= nil then self.Scheme[k] = v end
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

-- Unload
function Novoline:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, cb in ipairs(self.UnloadCallbacks) do pcall(cb) end
    for _, conn in ipairs(self.Connections) do
        pcall(function()
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect()
            elseif typeof(conn) == "Tween" then conn:Cancel() end
        end)
    end
    self.Connections = {}
    if self.GUI then pcall(function() self.GUI:Destroy() end) self.GUI = nil end
    UserInputService.MouseIconEnabled = true
end

function Novoline:OnUnload(callback)
    table.insert(self.UnloadCallbacks, callback)
end

function Novoline:SetNotifySide(side)
    self.NotifySide = side
end

function Novoline:SetDPIScale(scale)
    self.DPIScale = scale / 100
end

-- Search Functionality
function Novoline:SearchElements(query)
    query = query:lower():gsub("^%s*(.-)%s*$", "%1")
    if query == "" then
        for _, elem in ipairs(self.Elements) do
            if elem.Frame then elem.Frame.Visible = elem._OriginalVisible ~= false end
        end
        return
    end
    for _, elem in ipairs(self.Elements) do
        if elem.Frame and elem._SearchName then
            elem.Frame.Visible = elem._SearchName:lower():find(query, 1, true) ~= nil
        end
    end
end

-- Notification System
local function CreateNotification(gui, config, scheme)
    local side = config.Side or scheme.NotifySide or "Left"
    local container = gui:FindFirstChild("NotifyContainer_" .. side)
    if not container then
        container = Create("Frame", {
            Name = "NotifyContainer_" .. side,
            Size = UDim2.new(0, 280, 1, 0),
            Position = side == "Left" and UDim2.new(0, 12, 0, 0) or UDim2.new(1, -292, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 500
        }, gui)
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom }, container)
        Create("UIPadding", { PaddingBottom = UDim.new(0, 12) }, container)
    end

    local notify = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = scheme.MainColor,
        BorderSizePixel = 0,
        ZIndex = 501,
        LayoutOrder = -math.floor(tick() * 10000)
    }, container)
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, notify)
    Create("UIStroke", { Color = scheme.OutlineColor, Thickness = 1 }, notify)
    RegisterColor(notify, "BackgroundColor3", "MainColor")

    local accent = Create("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = scheme.AccentColor, BorderSizePixel = 0, ZIndex = 502 }, notify)
    Create("UICorner", { CornerRadius = UDim.new(0, 2) }, accent)
    RegisterColor(accent, "BackgroundColor3", "AccentColor")

    Create("TextLabel", { Text = config.Title or "Notification", Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 15, 0, 6), BackgroundTransparency = 1, TextColor3 = scheme.FontColor, TextSize = 12, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 503 }, notify)
    Create("TextLabel", { Text = config.Content or config.Description or "", Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 15, 0, 26), BackgroundTransparency = 1, TextColor3 = scheme.TextMuted, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 503, TextWrapped = true }, notify)

    Tween(notify, { Size = UDim2.new(1, 0, 0, 52) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(config.Duration or config.Time or 4, function()
        if notify and notify.Parent then
            Tween(notify, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(side == "Left" and -1 or 1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.25, function() pcall(function() notify:Destroy() end) end)
        end
    end)
    return notify
end

function Novoline:Notify(config)
    if type(config) == "string" then config = { Title = config, Description = "", Duration = 4 } end
    if self.GUI then CreateNotification(self.GUI, config, self) end
end

-- Create Tooltip
local function CreateTooltip(instance, text)
    if not text or text == "" then return end
    local tooltip = Create("TextLabel", {
        Size = UDim2.new(0, 200, 0, 30),
        BackgroundColor3 = Novoline.Scheme.MainColor,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Novoline.Scheme.FontColor,
        TextSize = 11,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        TextWrapped = true,
        Visible = false,
        ZIndex = 1000
    }, CoreGui)
    Create("UICorner", { CornerRadius = UDim.new(0, 4) }, tooltip)
    Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, tooltip)

    instance.MouseEnter:Connect(function()
        tooltip.Visible = true
        local pos = UserInputService:GetMouseLocation()
        tooltip.Position = UDim2.new(0, pos.X + 10, 0, pos.Y - 30)
    end)
    instance.MouseLeave:Connect(function() tooltip.Visible = false end)
    Connect(UserInputService.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and tooltip.Visible then
            local pos = input.Position
            tooltip.Position = UDim2.new(0, pos.X + 10, 0, pos.Y - 30)
        end
    end)
end

-- Main Window Creation
function Novoline:CreateWindow(config)
    if self.Unloaded then return nil end
    config = config or {}
    local Window = {}
    Window.__index = Window
    Window.Config = config
    Window.Tabs = {}

    local gui = Create("ScreenGui", {
        Name = "Novoline_" .. math.random(10000, 99999),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999
    }, CoreGui)
    self.GUI = gui

    local popupContainer = Create("Frame", { Name = "PopupContainer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 100, ClipsDescendants = false }, gui)

    local mainWindow = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 550, 0, 450),
        Position = config.Position or UDim2.new(0.5, -275, 0.5, -225),
        BackgroundColor3 = self.Scheme.BackgroundColor,
        BorderSizePixel = 0,
        ClipsDescendants = false
    }, gui)
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, mainWindow)
    RegisterColor(mainWindow, "BackgroundColor3", "BackgroundColor")
    Create("UIStroke", { Color = self.Scheme.OutlineColor, Thickness = 1 }, mainWindow)

    Create("ImageLabel", {
        Size = UDim2.new(1, 24, 1, 24), Position = UDim2.new(0, -12, 0, -12),
        BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = -1
    }, mainWindow)

    -- TOPBAR
    local topbar = Create("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = self.Scheme.TopbarColor, BorderSizePixel = 0, ZIndex = 10 }, mainWindow)
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, topbar)
    RegisterColor(topbar, "BackgroundColor3", "TopbarColor")
    Create("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = self.Scheme.TopbarColor, BorderSizePixel = 0, ZIndex = 10 }, topbar)

    local titleText = Create("TextLabel", {
        Text = tostring(config.Title or "Novoline"),
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Scheme.FontColor,
        TextSize = 13,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11
    }, topbar)
    RegisterColor(titleText, "TextColor3", "FontColor")

    -- Search Bar
    local searchFrame = Create("Frame", { Size = UDim2.new(0, 180, 0, 22), Position = UDim2.new(0.5, -90, 0.5, -11), BackgroundColor3 = self.Scheme.InputColor, BorderSizePixel = 0, ZIndex = 11 }, topbar)
    Create("UICorner", { CornerRadius = UDim.new(0, 4) }, searchFrame)
    RegisterColor(searchFrame, "BackgroundColor3", "InputColor")
    Create("TextLabel", { Text = "⌕", Size = UDim2.new(0, 18, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, TextColor3 = self.Scheme.TextMuted, TextSize = 12, ZIndex = 12 }, searchFrame)
    local searchBox = Create("TextBox", {
        Size = UDim2.new(1, -25, 1, 0), Position = UDim2.new(0, 22, 0, 0), BackgroundTransparency = 1,
        Text = "", PlaceholderText = "Search...", PlaceholderColor3 = self.Scheme.TextMuted,
        TextColor3 = self.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        ClearTextOnFocus = false, ZIndex = 12
    }, searchFrame)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() self:SearchElements(searchBox.Text) end)

    -- Close Button Only (No Minimize)
    local closeBtn = Create("TextButton", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -32, 0.5, -14), BackgroundTransparency = 1, Text = "×", TextColor3 = self.Scheme.TextMuted, TextSize = 18, ZIndex = 11 }, topbar)

    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {TextColor3 = Color3.fromRGB(255, 85, 85)}, 0.1) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {TextColor3 = self.Scheme.TextMuted}, 0.1) end)

    closeBtn.MouseButton1Click:Connect(function()
        Tween(mainWindow, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.35, function() self:Unload() end)
    end)

    -- Drag Logic (Fixed)
    local dragging = false
    local dragStart, startPos
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Don't drag if clicking on buttons or search
            if input.Target == closeBtn then return end
            if input.Target == searchBox or searchFrame:IsAncestorOf(input.Target) then return end
            
            dragging = true
            dragStart = input.Position
            startPos = mainWindow.Position
        end
    end)
    
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- K Keybind for Minimize/Unminimize
    Connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.K then
            Novoline.Minimized = not Novoline.Minimized
            if Novoline.Minimized then
                Tween(mainWindow, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            else
                Tween(mainWindow, {Size = UDim2.new(0, 550, 0, 450), Position = UDim2.new(0.5, -275, 0.5, -225)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
        end
    end)

    -- SIDEBAR
    local sidebarArea = Create("Frame", { Name = "Sidebar", Size = UDim2.new(0, 110, 1, -57), Position = UDim2.new(0, 0, 0, 34), BackgroundColor3 = self.Scheme.SidebarColor, BorderSizePixel = 0, ZIndex = 5 }, mainWindow)
    RegisterColor(sidebarArea, "BackgroundColor3", "SidebarColor")
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, sidebarArea)
    Create("UIPadding", { PaddingTop = UDim.new(0, 4) }, sidebarArea)

    -- CONTENT AREA
    local contentArea = Create("Frame", { Name = "ContentArea", Size = UDim2.new(1, -110, 1, -57), Position = UDim2.new(0, 110, 0, 34), BackgroundColor3 = self.Scheme.BackgroundColor, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5 }, mainWindow)
    RegisterColor(contentArea, "BackgroundColor3", "BackgroundColor")

    -- FOOTER
    local footer = Create("Frame", { Name = "Footer", Size = UDim2.new(1, 0, 0, 23), Position = UDim2.new(0, 0, 1, -23), BackgroundColor3 = self.Scheme.TopbarColor, BorderSizePixel = 0, ZIndex = 10 }, mainWindow)
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, footer)
    RegisterColor(footer, "BackgroundColor3", "TopbarColor")
    Create("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = self.Scheme.TopbarColor, BorderSizePixel = 0, ZIndex = 10 }, footer)
    Create("TextLabel", { Text = tostring(config.Footer or "") .. " | made by @thedude_whotalks For Novoline", Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, TextColor3 = self.Scheme.TextMuted, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 }, footer)

    -- Custom Cursor
    if config.ShowCustomCursor ~= false then
        local cursorFrame = Create("Frame", { Name = "CustomCursor", Size = UDim2.new(0, 16, 0, 16), BackgroundTransparency = 1, ZIndex = 9999 }, gui)
        Create("Frame", { Size = UDim2.new(0, 8, 0, 2), Position = UDim2.new(0, 4, 0, 7), BackgroundColor3 = self.Scheme.AccentColor, BorderSizePixel = 0, ZIndex = 10000 }, cursorFrame)
        Create("Frame", { Size = UDim2.new(0, 2, 0, 8), Position = UDim2.new(0, 7, 0, 4), BackgroundColor3 = self.Scheme.AccentColor, BorderSizePixel = 0, ZIndex = 10000 }, cursorFrame)
        Connect(UserInputService.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                cursorFrame.Position = UDim2.new(0, input.Position.X - 8, 0, input.Position.Y - 8)
            end
        end)
        UserInputService.MouseIconEnabled = false
    end

    -- Keybind Frame
    local keybindFrame = Create("Frame", {
        Name = "KeybindFrame",
        Size = UDim2.new(0, 300, 0, 250),
        Position = UDim2.new(0.5, -150, 0.5, -125),
        BackgroundColor3 = self.Scheme.BackgroundColor,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200
    }, gui)
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, keybindFrame)
    Create("UIStroke", { Color = self.Scheme.OutlineColor, Thickness = 1 }, keybindFrame)
    local kbTitle = Create("TextLabel", { Text = "Keybinds", Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = self.Scheme.TopbarColor, TextColor3 = self.Scheme.FontColor, TextSize = 13, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), ZIndex = 201 }, keybindFrame)
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, kbTitle)
    local keybindScroll = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -35), Position = UDim2.new(0, 0, 0, 32), BackgroundTransparency = 1, ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 201 }, keybindFrame)
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, keybindScroll)
    Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, keybindScroll)
    self.KeybindFrame = keybindFrame

    local selectedTab = nil

    -- ADD TAB (Fixed)
    function Window:AddTab(title, icon)
        -- Ensure title is a string
        title = tostring(title or "Tab")
        icon = icon or nil
        
        local Tab = {}
        Tab.__index = Tab
        Tab.Title = title
        Tab.Icon = icon
        Tab.Groupboxes = {}
        Tab.WarningBox = nil

        local tabBtn = Create("TextButton", {
            Name = "TabBtn_" .. title,
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = "  " .. title,
            TextColor3 = self.Scheme.TextMuted,
            TextSize = 11,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
            LayoutOrder = #Window.Tabs + 1,
            AutoButtonColor = false
        }, sidebarArea)
        RegisterColor(tabBtn, "TextColor3", "TextMuted")

        local tabIndicator = Create("Frame", {
            Size = UDim2.new(0, 2, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = self.Scheme.AccentColor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 7
        }, tabBtn)
        RegisterColor(tabIndicator, "BackgroundColor3", "AccentColor")

        local tabContent = Create("Frame", {
            Name = "TabContent_" .. title,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 5
        }, contentArea)
        Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, tabContent)
        Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, tabContent)

        -- Warning Box
        local warningBox = Create("Frame", { Size = UDim2.new(1, -12, 0, 0), BackgroundColor3 = Color3.fromRGB(60, 40, 30), BorderSizePixel = 0, Visible = false, ZIndex = 4, LayoutOrder = -1 }, tabContent)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, warningBox)
        Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, warningBox)
        local warningTitle = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 200, 100), TextSize = 12, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, warningBox)
        local warningText = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220, 180, 140), TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 5 }, warningBox)
        Tab.WarningBox = warningBox

        function Tab:UpdateWarningBox(options)
            warningBox.Visible = options.Visible or false
            warningTitle.Text = tostring(options.Title or "")
            warningText.Text = tostring(options.Text or "")
            if options.Visible then
                warningBox.Size = UDim2.new(1, -12, 0, 50)
            else
                warningBox.Size = UDim2.new(1, -12, 0, 0)
            end
        end

        Tab.Button = tabBtn
        Tab.Content = tabContent
        Tab.Indicator = tabIndicator

        local function SelectTab()
            if selectedTab then
                selectedTab.Content.Visible = false
                Tween(selectedTab.Button, {TextColor3 = Novoline.Scheme.TextMuted, BackgroundTransparency = 1}, 0.15)
                Tween(selectedTab.Indicator, {BackgroundTransparency = 1}, 0.15)
            end
            selectedTab = Tab
            Tab.Content.Visible = true
            Tween(tabBtn, {TextColor3 = Novoline.Scheme.FontColor, BackgroundTransparency = 0.9}, 0.15)
            Tween(tabIndicator, {BackgroundTransparency = 0}, 0.15)
            tabBtn.BackgroundColor3 = Novoline.Scheme.HoverColor
        end

        tabBtn.MouseEnter:Connect(function() if selectedTab ~= Tab then Tween(tabBtn, {TextColor3 = Novoline.Scheme.FontColor}, 0.1) end end)
        tabBtn.MouseLeave:Connect(function() if selectedTab ~= Tab then Tween(tabBtn, {TextColor3 = Novoline.Scheme.TextMuted}, 0.1) end end)
        tabBtn.MouseButton1Click:Connect(SelectTab)

        Window.Tabs[title] = Tab
        if #Window.Tabs == 1 then SelectTab() end

        -- ADD GROUPBOX
        function Tab:AddLeftGroupbox(title) return Tab:AddGroupbox(tostring(title), 0) end
        function Tab:AddRightGroupbox(title) return Tab:AddGroupbox(tostring(title), 1) end

        function Tab:AddGroupbox(title, side)
            local Groupbox = {}
            Groupbox.__index = Groupbox
            Groupbox.Title = tostring(title)
            Groupbox.Elements = {}

            local groupBox = Create("Frame", { Name = "GB_" .. title, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Novoline.Scheme.MainColor, BorderSizePixel = 0, LayoutOrder = side, ZIndex = 5 }, tabContent)
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }, groupBox)
            RegisterColor(groupBox, "BackgroundColor3", "MainColor")
            Create("UIStroke", { Color = Novoline.Scheme.OutlineColor, Thickness = 1 }, groupBox)

            local gbTitle = Create("TextLabel", { Text = "  " .. title, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Novoline.Scheme.SidebarColor, BorderSizePixel = 0, TextColor3 = Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, groupBox)
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }, gbTitle)
            Create("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = Novoline.Scheme.SidebarColor, BorderSizePixel = 0, ZIndex = 6 }, gbTitle)
            RegisterColor(gbTitle, "BackgroundColor3", "SidebarColor")
            RegisterColor(gbTitle, "TextColor3", "FontColor")

            local scrollFrame = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -24), Position = UDim2.new(0, 0, 0, 24), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(45, 45, 60), BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6 }, groupBox)
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, scrollFrame)
            Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6) }, scrollFrame)

            Groupbox.Container = scrollFrame
            Groupbox.Frame = groupBox

            -- ADD TOGGLE
            function Groupbox:AddToggle(idx, options)
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "Toggle_" .. math.random(1000, 9999) end
                local Toggle = {}
                Toggle.Type = "Toggle"
                Toggle.Value = options.Default or false
                Toggle.Callback = options.Callback or function() end
                Toggle.ChangedCallbacks = {}
                Toggle._SearchName = tostring(options.Text or "Toggle")
                Toggle._OriginalVisible = options.Visible ~= false
                if options.Key then idx = options.Key end
                Novoline.Toggles[idx] = Toggle

                local toggleFrame = Create("Frame", { Name = "Toggle_" .. idx, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                toggleFrame.Visible = Toggle._OriginalVisible

                local toggleLabel = Create("TextLabel", { Text = tostring(options.Text or "Toggle"), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1, TextColor3 = options.Risky and Novoline.Scheme.Red or Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, toggleFrame)
                RegisterColor(toggleLabel, "TextColor3", "FontColor")
                if options.Tooltip then CreateTooltip(toggleFrame, options.Tooltip) end

                local toggleBg = Create("Frame", { Size = UDim2.new(0, 34, 0, 16), Position = UDim2.new(1, -38, 0.5, -8), BackgroundColor3 = Color3.fromRGB(35, 35, 50), BorderSizePixel = 0, ZIndex = 8 }, toggleFrame)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, toggleBg)
                local toggleCircle = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(70, 70, 90), BorderSizePixel = 0, ZIndex = 9 }, toggleBg)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, toggleCircle)

                local function UpdateToggleVisual()
                    if Toggle.Value then
                        Tween(toggleBg, {BackgroundColor3 = Novoline.Scheme.AccentColor}, 0.15)
                        Tween(toggleCircle, {Position = UDim2.new(0, 20, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
                    else
                        Tween(toggleBg, {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}, 0.15)
                        Tween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(70, 70, 90)}, 0.15)
                    end
                end

                function Toggle:SetValue(value)
                    Toggle.Value = value
                    UpdateToggleVisual()
                    Toggle.Callback(value)
                    for _, cb in ipairs(Toggle.ChangedCallbacks) do cb(value) end
                end

                function Toggle:OnChanged(callback) table.insert(Toggle.ChangedCallbacks, callback) end
                function Toggle:SetVisible(visible) Toggle._OriginalVisible = visible; toggleFrame.Visible = visible end

                if not options.Disabled then
                    toggleFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            Toggle:SetValue(not Toggle.Value)
                        end
                    end)
                end

                if Toggle.Value then task.defer(UpdateToggleVisual) end

                Toggle.Frame = toggleFrame
                table.insert(Novoline.Elements, Toggle)
                Groupbox.Elements[#Groupbox.Elements + 1] = Toggle

                function Toggle:AddColorPicker(cpIdx, cpOptions)
                    cpOptions = cpOptions or {}
                    if type(cpIdx) ~= "string" then cpOptions = cpIdx; cpIdx = "ColorPicker_" .. math.random(1000, 9999) end
                    if cpOptions.Key then cpIdx = cpOptions.Key end

                    local colorIndicator = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, -16, 0.5, -6), BackgroundColor3 = cpOptions.Default or Color3.fromRGB(255, 0, 0), BorderSizePixel = 0, ZIndex = 8 }, toggleLabel)
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }, colorIndicator)

                    local cp = Groupbox:AddColorPicker(cpIdx, cpOptions)
                    cp:SetVisible(false)

                    colorIndicator.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            cp:SetVisible(not cp.Popup.Visible)
                            local pos = colorIndicator.AbsolutePosition
                            cp.Popup.Position = UDim2.new(0, pos.X, 0, pos.Y + 18)
                        end
                    end)
                    cp:OnChanged(function(color) colorIndicator.BackgroundColor3 = color end)
                    return cp
                end

                return Toggle
            end

            -- ADD CHECKBOX
            function Groupbox:AddCheckbox(idx, options)
                if not Novoline.ForceCheckbox then return Groupbox:AddToggle(idx, options) end
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "Checkbox_" .. math.random(1000, 9999) end
                if options.Key then idx = options.Key end

                local Checkbox = {}
                Checkbox.Type = "Checkbox"
                Checkbox.Value = options.Default or false
                Checkbox.Callback = options.Callback or function() end
                Checkbox.ChangedCallbacks = {}
                Checkbox._SearchName = tostring(options.Text or "Checkbox")
                Checkbox._OriginalVisible = options.Visible ~= false
                Novoline.Toggles[idx] = Checkbox

                local cbFrame = Create("Frame", { Name = "Checkbox_" .. idx, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                cbFrame.Visible = Checkbox._OriginalVisible

                local cbBox = Create("Frame", { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 0, 0.5, -7), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, ZIndex = 8 }, cbFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }, cbBox)
                local cbCheck = Create("TextLabel", { Text = "", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), ZIndex = 9 }, cbBox)

                Create("TextLabel", { Text = tostring(options.Text or "Checkbox"), Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, TextColor3 = options.Risky and Novoline.Scheme.Red or Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, cbFrame)
                if options.Tooltip then CreateTooltip(cbFrame, options.Tooltip) end

                local function UpdateCBVisual()
                    if Checkbox.Value then Tween(cbBox, {BackgroundColor3 = Novoline.Scheme.AccentColor}, 0.12); cbCheck.Text = "✓"
                    else Tween(cbBox, {BackgroundColor3 = Novoline.Scheme.InputColor}, 0.12); cbCheck.Text = "" end
                end

                function Checkbox:SetValue(value) Checkbox.Value = value; UpdateCBVisual(); Checkbox.Callback(value); for _, cb in ipairs(Checkbox.ChangedCallbacks) do cb(value) end end
                function Checkbox:OnChanged(callback) table.insert(Checkbox.ChangedCallbacks, callback) end
                function Checkbox:SetVisible(visible) Checkbox._OriginalVisible = visible; cbFrame.Visible = visible end

                if not options.Disabled then
                    cbFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            Checkbox:SetValue(not Checkbox.Value)
                        end
                    end)
                end
                UpdateCBVisual()
                Checkbox.Frame = cbFrame
                table.insert(Novoline.Elements, Checkbox)
                Groupbox.Elements[#Groupbox.Elements + 1] = Checkbox
                return Checkbox
            end

            -- ADD BUTTON
            function Groupbox:AddButton(options)
                options = options or {}
                local Button = {}
                Button.Type = "Button"
                Button.Callback = options.Func or options.Callback or function() end
                Button.ChangedCallbacks = {}
                Button._SearchName = tostring(options.Text or "Button")
                Button._OriginalVisible = options.Visible ~= false
                local doubleClick = options.DoubleClick or false
                local lastClick = 0

                local btnFrame = Create("Frame", { Name = "Button", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                btnFrame.Visible = Button._OriginalVisible

                local btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Novoline.Scheme.AccentColor, BorderSizePixel = 0, Text = tostring(options.Text or "Button"), TextColor3 = options.Risky and Color3.fromRGB(255, 200, 200) or Color3.fromRGB(255, 255, 255), TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), ZIndex = 8, AutoButtonColor = false }, btnFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
                RegisterColor(btn, "BackgroundColor3", "AccentColor")
                if options.Tooltip then CreateTooltip(btn, options.Tooltip) end

                if not options.Disabled then
                    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = LightenColor(Novoline.Scheme.AccentColor, 0.12)}, 0.1) end)
                    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Novoline.Scheme.AccentColor}, 0.1) end)
                    btn.MouseButton1Click:Connect(function()
                        if doubleClick then
                            local now = tick()
                            if now - lastClick < 0.3 then Button.Callback() end
                            lastClick = now
                        else
                            Button.Callback()
                        end
                        Tween(btn, {Size = UDim2.new(0.98, 0, 0.92, 0)}, 0.06)
                        task.delay(0.08, function() Tween(btn, {Size = UDim2.new(1, 0, 1, 0)}, 0.06) end)
                    end)
                end

                function Button:SetVisible(visible) Button._OriginalVisible = visible; btnFrame.Visible = visible end

                function Button:AddButton(subOptions)
                    subOptions = subOptions or {}
                    local SubButton = {}
                    SubButton.Type = "Button"
                    SubButton.Callback = subOptions.Func or subOptions.Callback or function() end
                    SubButton._SearchName = tostring(subOptions.Text or "Button")
                    SubButton._OriginalVisible = subOptions.Visible ~= false

                    local subFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                    subFrame.Visible = SubButton._OriginalVisible

                    local subBtn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Novoline.Scheme.HoverColor, BorderSizePixel = 0, Text = tostring(subOptions.Text or "Button"), TextColor3 = Novoline.Scheme.FontColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 8, AutoButtonColor = false }, subFrame)
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }, subBtn)
                    if subOptions.Tooltip then CreateTooltip(subBtn, subOptions.Tooltip) end

                    subBtn.MouseEnter:Connect(function() Tween(subBtn, {BackgroundColor3 = Color3.fromRGB(48, 48, 68)}, 0.08) end)
                    subBtn.MouseLeave:Connect(function() Tween(subBtn, {BackgroundColor3 = Novoline.Scheme.HoverColor}, 0.08) end)
                    subBtn.MouseButton1Click:Connect(function() SubButton.Callback() end)

                    function SubButton:SetVisible(visible) SubButton._OriginalVisible = visible; subFrame.Visible = visible end
                    SubButton.Frame = subFrame
                    table.insert(Novoline.Elements, SubButton)
                    Groupbox.Elements[#Groupbox.Elements + 1] = SubButton
                    return SubButton
                end

                Button.Frame = btnFrame
                table.insert(Novoline.Elements, Button)
                Groupbox.Elements[#Groupbox.Elements + 1] = Button
                return Button
            end

            -- ADD LABEL
            function Groupbox:AddLabel(idxOrText, optionsOrWrap, idx)
                local options = {}
                local labelIdx = "Label_" .. math.random(1000, 9999)
                
                if type(idxOrText) == "string" and idx then
                    labelIdx = idxOrText
                    options.Text = idxOrText
                elseif type(idxOrText) == "table" then
                    options = idxOrText
                    if options.Idx then labelIdx = options.Idx end
                elseif type(idxOrText) == "string" and type(optionsOrWrap) == "boolean" then
                    options.Text = idxOrText
                    options.DoesWrap = optionsOrWrap
                    if idx then labelIdx = idx end
                else
                    options.Text = tostring(idxOrText)
                    if type(optionsOrWrap) == "table" then options = optionsOrWrap end
                end

                local Label = {}
                Label.Type = "Label"
                Label.Value = tostring(options.Text or "Label")
                Label.ChangedCallbacks = {}
                Label._SearchName = Label.Value
                Label._OriginalVisible = true
                Novoline.Options[labelIdx] = Label

                local labelFrame = Create("Frame", { Name = "Label_" .. labelIdx, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                local label = Create("TextLabel", { Text = Label.Value, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = options.Size or 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = options.DoesWrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd, TextWrapped = options.DoesWrap or false, ZIndex = 8 }, labelFrame)
                RegisterColor(label, "TextColor3", "FontColor")

                function Label:SetText(text) Label.Value = tostring(text); Label._SearchName = Label.Value; label.Text = Label.Value; for _, cb in ipairs(Label.ChangedCallbacks) do cb(Label.Value) end end
                function Label:OnChanged(callback) table.insert(Label.ChangedCallbacks, callback) end
                function Label:SetVisible(visible) Label._OriginalVisible = visible; labelFrame.Visible = visible end

                function Label:AddColorPicker(cpIdx, cpOptions)
                    cpOptions = cpOptions or {}
                    if type(cpIdx) ~= "string" then cpOptions = cpIdx; cpIdx = "ColorPicker_" .. math.random(1000, 9999) end
                    if cpOptions.Key then cpIdx = cpOptions.Key end

                    local colorIndicator = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = cpOptions.Default or Color3.fromRGB(0, 255, 0), BorderSizePixel = 0, ZIndex = 8 }, label)
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }, colorIndicator)
                    label.Size = UDim2.new(1, -18, 1, 0)

                    local cp = Groupbox:AddColorPicker(cpIdx, cpOptions)
                    cp:SetVisible(false)

                    colorIndicator.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            cp:SetVisible(not cp.Popup.Visible)
                            local pos = colorIndicator.AbsolutePosition
                            cp.Popup.Position = UDim2.new(0, pos.X, 0, pos.Y + 18)
                        end
                    end)
                    cp:OnChanged(function(color) colorIndicator.BackgroundColor3 = color end)
                    return cp
                end

                function Label:AddKeyPicker(kpIdx, kpOptions)
                    kpOptions = kpOptions or {}
                    if type(kpIdx) ~= "string" then kpOptions = kpIdx; kpIdx = "KeyPicker_" .. math.random(1000, 9999) end
                    if kpOptions.Key then kpIdx = kpOptions.Key end
                    return Groupbox:AddKeyPicker(kpIdx, kpOptions)
                end

                Label.Frame = labelFrame
                table.insert(Novoline.Elements, Label)
                Groupbox.Elements[#Groupbox.Elements + 1] = Label
                return Label
            end

            -- ADD DIVIDER
            function Groupbox:AddDivider()
                local divFrame = Create("Frame", { Name = "Divider", Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Novoline.Scheme.OutlineColor, BorderSizePixel = 0, ZIndex = 8 }, divFrame)
                return divFrame
            end

            -- ADD SLIDER
            function Groupbox:AddSlider(idx, options)
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "Slider_" .. math.random(1000, 9999) end
                if options.Key then idx = options.Key end

                local Slider = {}
                Slider.Type = "Slider"
                Slider.Value = options.Default or 0
                Slider.Min = options.Min or 0
                Slider.Max = options.Max or 100
                Slider.Rounding = options.Rounding or 1
                Slider.Callback = options.Callback or function() end
                Slider.ChangedCallbacks = {}
                Slider.Suffix = tostring(options.Suffix or "")
                Slider._SearchName = tostring(options.Text or "Slider")
                Slider._OriginalVisible = options.Visible ~= false
                Novoline.Options[idx] = Slider

                local sliderFrame = Create("Frame", { Name = "Slider_" .. idx, Size = UDim2.new(1, 0, 0, options.Compact and 20 or 36), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                sliderFrame.Visible = Slider._OriginalVisible

                if not options.Compact then
                    local sliderHeader = Create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 8 }, sliderFrame)
                    Create("TextLabel", { Text = tostring(options.Text or "Slider"), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 }, sliderHeader)
                end

                local sliderValueLabel = Create("TextLabel", { Text = Round(Slider.Value, Slider.Rounding) .. (options.HideMax and Slider.Suffix or (" / " .. Slider.Max .. Slider.Suffix)), Size = UDim2.new(options.Compact and 1 or 0.4, 0, options.Compact and 1 or 1, 0), Position = options.Compact and UDim2.new(0, 0, 0, 0) or UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.AccentColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 9 }, sliderFrame)
                RegisterColor(sliderValueLabel, "TextColor3", "AccentColor")

                local sliderTrack = Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, options.Compact and 8 or 24), BackgroundColor3 = Color3.fromRGB(28, 28, 40), BorderSizePixel = 0, ZIndex = 8 }, sliderFrame)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderTrack)
                local sliderFill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Novoline.Scheme.AccentColor, BorderSizePixel = 0, ZIndex = 9 }, sliderTrack)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderFill)
                RegisterColor(sliderFill, "BackgroundColor3", "AccentColor")
                local sliderHandle = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, -6, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 2, BorderColor3 = Novoline.Scheme.AccentColor, ZIndex = 10 }, sliderTrack)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderHandle)

                local isSliding = false
                local function UpdateSliderVisual()
                    local percent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    percent = Clamp(percent, 0, 1)
                    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    sliderHandle.Position = UDim2.new(percent, -6, 0.5, -6)
                    sliderValueLabel.Text = Round(Slider.Value, Slider.Rounding) .. (options.HideMax and Slider.Suffix or (" / " .. Slider.Max .. Slider.Suffix))
                end

                function Slider:SetValue(value)
                    Slider.Value = Clamp(Round(value, Slider.Rounding), Slider.Min, Slider.Max)
                    UpdateSliderVisual()
                    Slider.Callback(Slider.Value)
                    for _, cb in ipairs(Slider.ChangedCallbacks) do cb(Slider.Value) end
                end

                function Slider:OnChanged(callback) table.insert(Slider.ChangedCallbacks, callback) end
                function Slider:SetVisible(visible) Slider._OriginalVisible = visible; sliderFrame.Visible = visible end

                local function HandleSliderInput(input)
                    local percent = Clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
                    Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * percent)
                end

                sliderTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isSliding = true; HandleSliderInput(input)
                    end
                end)
                sliderTrack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isSliding = false end
                end)
                Connect(UserInputService.InputChanged, function(input)
                    if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then HandleSliderInput(input) end
                end)

                UpdateSliderVisual()
                Slider.Frame = sliderFrame
                table.insert(Novoline.Elements, Slider)
                Groupbox.Elements[#Groupbox.Elements + 1] = Slider
                return Slider
            end

            -- ADD INPUT
            function Groupbox:AddInput(idx, options)
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "Input_" .. math.random(1000, 9999) end
                if options.Key then idx = options.Key end

                local Input = {}
                Input.Type = "Input"
                Input.Value = tostring(options.Default or "")
                Input.Callback = options.Callback or function() end
                Input.ChangedCallbacks = {}
                Input._SearchName = tostring(options.Text or "Input")
                Input._OriginalVisible = true
                Novoline.Options[idx] = Input

                local inputFrame = Create("Frame", { Name = "Input_" .. idx, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                inputFrame.Visible = Input._OriginalVisible
                Create("TextLabel", { Text = tostring(options.Text or "Input"), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, inputFrame)
                local inputBox = Create("TextBox", { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 18), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = Input.Value, PlaceholderText = tostring(options.Placeholder or ""), PlaceholderColor3 = Novoline.Scheme.TextMuted, TextColor3 = Novoline.Scheme.FontColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ClearTextOnFocus = options.ClearTextOnFocus ~= false, ZIndex = 8 }, inputFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, inputBox)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, inputBox)
                if options.Tooltip then CreateTooltip(inputFrame, options.Tooltip) end

                if options.Numeric then
                    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                        if inputBox.Text ~= "" and not inputBox.Text:match("^%d*%.?%d*$") then inputBox.Text = inputBox.Text:gsub("[^%d.]", "") end
                    end)
                end

                inputBox.FocusLost:Connect(function(enter)
                    if options.Finished and not enter then return end
                    Input.Value = inputBox.Text
                    Input.Callback(Input.Value)
                    for _, cb in ipairs(Input.ChangedCallbacks) do cb(Input.Value) end
                end)

                function Input:SetValue(value) Input.Value = tostring(value); inputBox.Text = Input.Value; Input.Callback(Input.Value); for _, cb in ipairs(Input.ChangedCallbacks) do cb(Input.Value) end end
                function Input:OnChanged(callback) table.insert(Input.ChangedCallbacks, callback) end
                function Input:SetVisible(visible) Input._OriginalVisible = visible; inputFrame.Visible = visible end

                Input.Frame = inputFrame
                table.insert(Novoline.Elements, Input)
                Groupbox.Elements[#Groupbox.Elements + 1] = Input
                return Input
            end

            -- ADD DROPDOWN
            function Groupbox:AddDropdown(idx, options)
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "Dropdown_" .. math.random(1000, 9999) end
                if options.Key then idx = options.Key end

                local Dropdown = {}
                Dropdown.Type = "Dropdown"
                Dropdown.Values = options.Values or {}
                Dropdown.Multi = options.Multi or false
                Dropdown.Searchable = options.Searchable or false
                Dropdown.SpecialType = options.SpecialType or nil
                Dropdown.Callback = options.Callback or function() end
                Dropdown.ChangedCallbacks = {}
                Dropdown.Selected = {}
                Dropdown.FormatDisplayValue = options.FormatDisplayValue or nil
                Dropdown.DisabledValues = options.DisabledValues or {}
                Dropdown.MaxVisibleDropdownItems = options.MaxVisibleDropdownItems or 8
                Dropdown._SearchName = tostring(options.Text or "Dropdown")
                Dropdown._OriginalVisible = options.Visible ~= false
                Novoline.Options[idx] = Dropdown

                if type(options.Default) == "number" then
                    Dropdown.Value = Dropdown.Values[options.Default] or nil
                else
                    Dropdown.Value = options.Default or nil
                end

                if Dropdown.Multi then
                    for _, v in ipairs(Dropdown.Values) do Dropdown.Selected[v] = false end
                    if type(options.Default) == "table" then
                        for _, v in ipairs(options.Default) do Dropdown.Selected[v] = true end
                    elseif type(options.Default) == "number" and Dropdown.Values[options.Default] then
                        Dropdown.Selected[Dropdown.Values[options.Default]] = true
                    end
                end

                local ddFrame = Create("Frame", { Name = "Dropdown_" .. idx, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                ddFrame.Visible = Dropdown._OriginalVisible

                local displayValue = Dropdown.Multi and "Select..." or (Dropdown.FormatDisplayValue and Dropdown.FormatDisplayValue(Dropdown.Value) or Dropdown.Value or tostring(options.Text or "Dropdown"))
                local ddBtn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = displayValue, TextColor3 = Novoline.Scheme.FontColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, AutoButtonColor = false }, ddFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, ddBtn)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, ddBtn)
                RegisterColor(ddBtn, "TextColor3", "FontColor")
                local ddArrow = Create("TextLabel", { Text = "▾", Size = UDim2.new(0, 18, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.TextMuted, TextSize = 10, ZIndex = 9 }, ddBtn)
                if options.Tooltip then CreateTooltip(ddFrame, options.Tooltip) end

                local ddList = Create("Frame", { Name = "DropdownList", BackgroundColor3 = Novoline.Scheme.MainColor, BorderSizePixel = 0, Visible = false, ZIndex = 100 }, popupContainer)
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }, ddList)
                Create("UIStroke", { Color = Novoline.Scheme.OutlineColor, Thickness = 1 }, ddList)
                local ddScroll = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(45, 45, 60), BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 101 }, ddList)
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, ddScroll)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, ddScroll)

                local searchBox = nil
                if Dropdown.Searchable then
                    searchBox = Create("TextBox", { Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Novoline.Scheme.TextMuted, TextColor3 = Novoline.Scheme.FontColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ClearTextOnFocus = false, ZIndex = 102, LayoutOrder = -1 }, ddScroll)
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }, searchBox)
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }, searchBox)
                    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        for _, child in ipairs(ddScroll:GetChildren()) do
                            if child:IsA("TextButton") then child.Visible = child.Text:lower():find(searchBox.Text:lower()) ~= nil end
                        end
                    end)
                end

                local isOpen = false
                local optionButtons = {}

                local function UpdateListPosition()
                    local btnPos = ddBtn.AbsolutePosition
                    local btnSize = ddBtn.AbsoluteSize
                    ddList.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + btnSize.Y + 2)
                    local listHeight = math.min(Dropdown.MaxVisibleDropdownItems, #Dropdown.Values) * 20 + (searchBox and 24 or 6)
                    ddList.Size = UDim2.new(0, btnSize.X, 0, listHeight)
                end

                local function CreateOptions()
                    for _, btn in ipairs(optionButtons) do pcall(function() btn:Destroy() end) end
                    optionButtons = {}

                    for i, value in ipairs(Dropdown.Values) do
                        local isDisabled = table.find(Dropdown.DisabledValues, value) ~= nil
                        local optBtn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = Novoline.Scheme.HoverColor, BorderSizePixel = 0, Text = tostring(value), TextColor3 = isDisabled and Novoline.Scheme.TextMuted or Novoline.Scheme.FontColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102, LayoutOrder = i, AutoButtonColor = false }, ddScroll)
                        Create("UICorner", { CornerRadius = UDim.new(0, 3) }, optBtn)
                        Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }, optBtn)

                        if Dropdown.Multi then
                            Create("TextLabel", { Text = Dropdown.Selected[value] and "✓" or "", Size = UDim2.new(0, 18, 1, 0), Position = UDim2.new(1, -18, 0, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.AccentColor, TextSize = 10, ZIndex = 103 }, optBtn)
                        end

                        if not isDisabled then
                            optBtn.MouseEnter:Connect(function() Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(48, 48, 68)}, 0.1) end)
                            optBtn.MouseLeave:Connect(function() Tween(optBtn, {BackgroundColor3 = Novoline.Scheme.HoverColor}, 0.1) end)
                            optBtn.MouseButton1Click:Connect(function()
                                if Dropdown.Multi then
                                    Dropdown.Selected[value] = not Dropdown.Selected[value]
                                    for _, child in ipairs(optBtn:GetChildren()) do
                                        if child:IsA("TextLabel") and child.ZIndex == 103 then child.Text = Dropdown.Selected[value] and "✓" or "" end
                                    end
                                    Dropdown.Callback(Dropdown.Selected)
                                    for _, cb in ipairs(Dropdown.ChangedCallbacks) do cb(Dropdown.Selected) end
                                else
                                    Dropdown.Value = value
                                    ddBtn.Text = Dropdown.FormatDisplayValue and Dropdown.FormatDisplayValue(value) or tostring(value)
                                    ddList.Visible = false; isOpen = false; Tween(ddArrow, {Rotation = 0}, 0.15)
                                    Dropdown.Callback(value)
                                    for _, cb in ipairs(Dropdown.ChangedCallbacks) do cb(value) end
                                end
                            end)
                        else
                            optBtn.TextTransparency = 0.4
                        end
                        table.insert(optionButtons, optBtn)
                    end
                end

                CreateOptions()

                if Dropdown.SpecialType == "Player" then
                    local function UpdatePlayers()
                        Dropdown.Values = {}
                        for _, player in ipairs(Players:GetPlayers()) do
                            if not (options.ExcludeLocalPlayer and player == Players.LocalPlayer) then
                                table.insert(Dropdown.Values, player.Name)
                            end
                        end
                        if not options.ExcludeLocalPlayer then table.insert(Dropdown.Values, "All") end
                        CreateOptions()
                    end
                    Connect(Players.PlayerAdded, function(player) if not (options.ExcludeLocalPlayer and player == Players.LocalPlayer) then table.insert(Dropdown.Values, player.Name); CreateOptions() end end)
                    Connect(Players.PlayerRemoving, function(player) for i, name in ipairs(Dropdown.Values) do if name == player.Name then table.remove(Dropdown.Values, i); break end end; CreateOptions() end)
                    UpdatePlayers()
                elseif Dropdown.SpecialType == "Team" then
                    local function UpdateTeams()
                        Dropdown.Values = {}
                        for _, team in ipairs(game:GetService("Teams"):GetChildren()) do table.insert(Dropdown.Values, team.Name) end
                        CreateOptions()
                    end
                    game:GetService("Teams").ChildAdded:Connect(function() UpdateTeams() end)
                    game:GetService("Teams").ChildRemoved:Connect(function() UpdateTeams() end)
                    UpdateTeams()
                end

                ddBtn.MouseButton1Click:Connect(function()
                    if options.Disabled then return end
                    isOpen = not isOpen
                    if isOpen then UpdateListPosition(); ddList.Visible = true; Tween(ddArrow, {Rotation = 180}, 0.15)
                    else ddList.Visible = false; Tween(ddArrow, {Rotation = 0}, 0.15) end
                end)

                function Dropdown:SetValue(value)
                    if Dropdown.Multi then
                        Dropdown.Selected = value or {}
                        for _, btn in ipairs(optionButtons) do
                            for _, child in ipairs(btn:GetChildren()) do
                                if child:IsA("TextLabel") and child.ZIndex == 103 then child.Text = Dropdown.Selected[btn.Text] and "✓" or "" end
                            end
                        end
                        Dropdown.Callback(Dropdown.Selected)
                    else
                        Dropdown.Value = value
                        ddBtn.Text = Dropdown.FormatDisplayValue and Dropdown.FormatDisplayValue(value) or tostring(value)
                        Dropdown.Callback(value)
                    end
                    for _, cb in ipairs(Dropdown.ChangedCallbacks) do cb(Dropdown.Multi and Dropdown.Selected or Dropdown.Value) end
                end

                function Dropdown:OnChanged(callback) table.insert(Dropdown.ChangedCallbacks, callback) end
                function Dropdown:SetVisible(visible) Dropdown._OriginalVisible = visible; ddFrame.Visible = visible; if not visible then ddList.Visible = false end end
                function Dropdown:Refresh(values) Dropdown.Values = values or {}; CreateOptions() end

                Dropdown.Frame = ddFrame
                Dropdown.ListFrame = ddList
                table.insert(Novoline.Elements, Dropdown)
                Groupbox.Elements[#Groupbox.Elements + 1] = Dropdown
                return Dropdown
            end

            -- ADD COLOR PICKER
            function Groupbox:AddColorPicker(idx, options)
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "ColorPicker_" .. math.random(1000, 9999) end
                if options.Key then idx = options.Key end

                local ColorPicker = {}
                ColorPicker.Type = "ColorPicker"
                ColorPicker.Value = options.Default or Color3.fromRGB(255, 0, 0)
                ColorPicker.Transparency = options.Transparency or nil
                ColorPicker.Callback = options.Callback or function() end
                ColorPicker.ChangedCallbacks = {}
                ColorPicker._SearchName = tostring(options.Text or options.Title or "ColorPicker")
                ColorPicker._OriginalVisible = true
                Novoline.Options[idx] = ColorPicker

                local cpFrame = Create("Frame", { Name = "ColorPicker_" .. idx, Size = UDim2.new(1, 0, 0, options.Text and 24 or 0), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                cpFrame.Visible = ColorPicker._OriginalVisible

                if options.Text and options.Text ~= "" then
                    Create("TextLabel", { Text = tostring(options.Text), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, cpFrame)
                end

                local colorPreview = Create("TextButton", { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, options.Text and 18 or 0), BackgroundColor3 = ColorPicker.Value, BorderSizePixel = 0, Text = "", ZIndex = 8, AutoButtonColor = false }, cpFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, colorPreview)

                local yOff = ColorPicker.Transparency ~= nil and 170 or 148
                local cpPopup = Create("Frame", { BackgroundColor3 = Novoline.Scheme.MainColor, BorderSizePixel = 0, Visible = false, ZIndex = 100, Size = UDim2.new(0, 190, 0, yOff) }, popupContainer)
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }, cpPopup)
                Create("UIStroke", { Color = Novoline.Scheme.OutlineColor, Thickness = 1 }, cpPopup)

                local sbBox = Create("Frame", { Size = UDim2.new(1, -10, 0, 100), Position = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.fromHSV(0, 1, 1), BorderSizePixel = 0, ZIndex = 101, ClipsDescendants = true }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }, sbBox)
                
                local whiteOv = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 102 }, sbBox)
                Create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}) }, whiteOv)
                local blackOv = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 103 }, sbBox)
                Create("UIGradient", { Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 90 }, blackOv)
                
                local sbCursor = Create("Frame", { Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, -4, 0, -4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 1, BorderColor3 = Color3.new(0, 0, 0), ZIndex = 105 }, sbBox)

                local hueSlider = Create("Frame", { Size = UDim2.new(1, -10, 0, 12), Position = UDim2.new(0, 5, 0, 110), BackgroundColor3 = Color3.new(1, 0, 0), BorderSizePixel = 0, ZIndex = 101 }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }, hueSlider)
                Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)), ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)), ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)), ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))}) }, hueSlider)
                local hueCursor = Create("Frame", { Size = UDim2.new(0, 6, 0, 16), Position = UDim2.new(0, -3, 0.5, -8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 1, BorderColor3 = Color3.new(0, 0, 0), ZIndex = 102 }, hueSlider)

                local transSlider = nil
                local transCursor = nil
                local hexYOff = 128
                
                if ColorPicker.Transparency ~= nil then
                    transSlider = Create("Frame", { Size = UDim2.new(1, -10, 0, 12), Position = UDim2.new(0, 5, 0, hexYOff), BackgroundColor3 = Color3.fromRGB(30, 30, 42), BorderSizePixel = 0, ZIndex = 101 }, cpPopup)
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, transSlider)
                    local transFill = Create("Frame", { Size = UDim2.new(1 - ColorPicker.Transparency, 0, 1, 0), BackgroundColor3 = ColorPicker.Value, BorderSizePixel = 0, ZIndex = 102 }, transSlider)
                    transCursor = Create("Frame", { Size = UDim2.new(0, 6, 0, 16), Position = UDim2.new(1 - ColorPicker.Transparency, -3, 0.5, -8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 1, BorderColor3 = Color3.new(0, 0, 0), ZIndex = 103 }, transSlider)
                    hexYOff = hexYOff + 16
                end

                local hexInput = Create("TextBox", { Size = UDim2.new(0.5, -8, 0, 16), Position = UDim2.new(0, 5, 0, hexYOff), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = Color3ToHex(ColorPicker.Value), TextColor3 = Novoline.Scheme.FontColor, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), ZIndex = 101, ClearTextOnFocus = false }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }, hexInput)
                local rgbInput = Create("TextBox", { Size = UDim2.new(0.5, -8, 0, 16), Position = UDim2.new(0.5, 3, 0, hexYOff), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = string.format("%d, %d, %d", math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255)), TextColor3 = Novoline.Scheme.FontColor, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), ZIndex = 101, ClearTextOnFocus = false }, cpPopup)
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }, rgbInput)

                local hue, sat, val = Color3ToHSV(ColorPicker.Value)
                local sbDragging, hueDragging, transDragging = false, false, false

                local function UpdateColorFromHSV()
                    local color = HSVToColor3(hue, sat, val)
                    ColorPicker.Value = color
                    colorPreview.BackgroundColor3 = color
                    sbBox.BackgroundColor3 = HSVToColor3(hue, 1, 1)
                    hexInput.Text = Color3ToHex(color)
                    rgbInput.Text = string.format("%d, %d, %d", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
                    if transSlider then transSlider:FindFirstChildOfClass("Frame").BackgroundColor3 = color end
                    ColorPicker.Callback(color)
                    for _, cb in ipairs(ColorPicker.ChangedCallbacks) do cb(color) end
                end

                local function UpdateCursors()
                    sbCursor.Position = UDim2.new(sat, -4, 1 - val, -4)
                    hueCursor.Position = UDim2.new(hue, -3, 0.5, -8)
                end

                sbBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sbDragging = true; sat = Clamp((input.Position.X - sbBox.AbsolutePosition.X) / sbBox.AbsoluteSize.X, 0, 1); val = 1 - Clamp((input.Position.Y - sbBox.AbsolutePosition.Y) / sbBox.AbsoluteSize.Y, 0, 1); UpdateCursors(); UpdateColorFromHSV()
                    end
                end)
                sbBox.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sbDragging = false end end)

                hueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true; hue = Clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1); UpdateCursors(); UpdateColorFromHSV()
                    end
                end)
                hueSlider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = false end end)

                if transSlider then
                    transSlider.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            transDragging = true
                            ColorPicker.Transparency = 1 - Clamp((input.Position.X - transSlider.AbsolutePosition.X) / transSlider.AbsoluteSize.X, 0, 1)
                            transCursor.Position = UDim2.new(1 - ColorPicker.Transparency, -3, 0.5, -8)
                            if transSlider:FindFirstChildOfClass("Frame") then transSlider:FindFirstChildOfClass("Frame").Size = UDim2.new(1 - ColorPicker.Transparency, 0, 1, 0) end
                        end
                    end)
                    transSlider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then transDragging = false end end)
                end

                Connect(UserInputService.InputChanged, function(input)
                    if sbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        sat = Clamp((input.Position.X - sbBox.AbsolutePosition.X) / sbBox.AbsoluteSize.X, 0, 1); val = 1 - Clamp((input.Position.Y - sbBox.AbsolutePosition.Y) / sbBox.AbsoluteSize.Y, 0, 1); UpdateCursors(); UpdateColorFromHSV()
                    elseif hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        hue = Clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1); UpdateCursors(); UpdateColorFromHSV()
                    elseif transDragging and transSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        ColorPicker.Transparency = 1 - Clamp((input.Position.X - transSlider.AbsolutePosition.X) / transSlider.AbsoluteSize.X, 0, 1)
                        transCursor.Position = UDim2.new(1 - ColorPicker.Transparency, -3, 0.5, -8)
                        if transSlider:FindFirstChildOfClass("Frame") then transSlider:FindFirstChildOfClass("Frame").Size = UDim2.new(1 - ColorPicker.Transparency, 0, 1, 0) end
                    end
                end)

                hexInput.FocusLost:Connect(function()
                    local success, color = pcall(HexToColor3, hexInput.Text)
                    if success then hue, sat, val = Color3ToHSV(color); UpdateCursors(); UpdateColorFromHSV()
                    else hexInput.Text = Color3ToHex(ColorPicker.Value) end
                end)
                rgbInput.FocusLost:Connect(function()
                    local parts = {}
                    for num in rgbInput.Text:gmatch("%d+") do table.insert(parts, tonumber(num)) end
                    if #parts >= 3 then
                        local color = Color3.fromRGB(Clamp(parts[1], 0, 255), Clamp(parts[2], 0, 255), Clamp(parts[3], 0, 255))
                        hue, sat, val = Color3ToHSV(color); UpdateCursors(); UpdateColorFromHSV()
                    else rgbInput.Text = string.format("%d, %d, %d", math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255)) end
                end)

                colorPreview.MouseButton1Click:Connect(function()
                    local isVisible = not cpPopup.Visible
                    if isVisible then local pos = colorPreview.AbsolutePosition; local size = colorPreview.AbsoluteSize; cpPopup.Position = UDim2.new(0, pos.X, 0, pos.Y + size.Y + 3) end
                    cpPopup.Visible = isVisible
                end)

                function ColorPicker:SetValue(color)
                    ColorPicker.Value = color; hue, sat, val = Color3ToHSV(color); colorPreview.BackgroundColor3 = color; sbBox.BackgroundColor3 = HSVToColor3(hue, 1, 1); hexInput.Text = Color3ToHex(color); rgbInput.Text = string.format("%d, %d, %d", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)); if transSlider and transSlider:FindFirstChildOfClass("Frame") then transSlider:FindFirstChildOfClass("Frame").BackgroundColor3 = color end; UpdateCursors(); ColorPicker.Callback(color); for _, cb in ipairs(ColorPicker.ChangedCallbacks) do cb(color) end
                end
                function ColorPicker:SetValueRGB(color) ColorPicker:SetValue(color) end
                function ColorPicker:OnChanged(callback) table.insert(ColorPicker.ChangedCallbacks, callback) end
                function ColorPicker:SetVisible(visible) ColorPicker._OriginalVisible = visible; cpFrame.Visible = visible; if not visible then cpPopup.Visible = false end end

                UpdateCursors()
                ColorPicker.Frame = cpFrame
                ColorPicker.Popup = cpPopup
                table.insert(Novoline.Elements, ColorPicker)
                Groupbox.Elements[#Groupbox.Elements + 1] = ColorPicker
                return ColorPicker
            end

            -- ADD KEY PICKER
            function Groupbox:AddKeyPicker(idx, options)
                options = options or {}
                if type(idx) ~= "string" then options = idx; idx = "KeyPicker_" .. math.random(1000, 9999) end
                if options.Key then idx = options.Key end

                local KeyPicker = {}
                KeyPicker.Type = "KeyPicker"
                local defaultValue = options.Default or "None"
                if type(defaultValue) == "table" then
                    KeyPicker.Value = defaultValue[1] or "None"
                    KeyPicker.Mode = defaultValue[2] or options.Mode or "Toggle"
                else
                    KeyPicker.Value = tostring(defaultValue)
                    KeyPicker.Mode = options.Mode or "Toggle"
                end
                KeyPicker.Callback = options.Callback or function() end
                KeyPicker.ChangedCallback = options.ChangedCallback or function() end
                KeyPicker.ChangedCallbacks = {}
                KeyPicker.ClickCallbacks = {}
                KeyPicker.HoldState = false
                KeyPicker.ToggleState = false
                KeyPicker.SyncToggle = options.SyncToggleState and options.SyncToggle or nil
                KeyPicker._SearchName = tostring(options.Text or "KeyPicker")
                KeyPicker._OriginalVisible = options.NoUI ~= true
                KeyPicker.NoUI = options.NoUI or false
                Novoline.Options[idx] = KeyPicker

                if KeyPicker.SyncToggle then
                    KeyPicker.SyncToggle:OnChanged(function(value) KeyPicker.ToggleState = value end)
                end

                local kpFrame = Create("Frame", { Name = "KeyPicker_" .. idx, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 7, LayoutOrder = #Groupbox.Elements + 1 }, scrollFrame)
                kpFrame.Visible = KeyPicker._OriginalVisible

                Create("TextLabel", { Text = tostring(options.Text or "Keybind"), Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, kpFrame)
                local kpBtn = Create("TextButton", { Size = UDim2.new(0.5, -5, 0, 16), Position = UDim2.new(0.5, 5, 0.5, -8), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = KeyPicker.Value, TextColor3 = Novoline.Scheme.FontColor, TextSize = 9, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 8, AutoButtonColor = false }, kpFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }, kpBtn)
                RegisterColor(kpBtn, "TextColor3", "FontColor")

                if Novoline.ShowToggleFrameInKeybinds and not KeyPicker.NoUI then
                    local kbEntry = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Novoline.Scheme.MainColor, BorderSizePixel = 0, ZIndex = 202 }, keybindScroll)
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }, kbEntry)
                    Create("TextLabel", { Text = tostring(options.Text or "Keybind"), Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203 }, kbEntry)
                    local kbValue = Create("TextLabel", { Text = KeyPicker.Value .. " [" .. KeyPicker.Mode .. "]", Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.AccentColor, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 203 }, kbEntry)
                    KeyPicker._kbValue = kbValue
                end

                local waitingForKey = false

                kpBtn.MouseButton1Click:Connect(function()
                    waitingForKey = not waitingForKey
                    if waitingForKey then kpBtn.Text = "[...]"; kpBtn.TextColor3 = Novoline.Scheme.AccentColor
                    else kpBtn.Text = KeyPicker.Value; kpBtn.TextColor3 = Novoline.Scheme.FontColor end
                end)

                Connect(UserInputService.InputBegan, function(input, processed)
                    if waitingForKey then
                        if input.UserInputType == Enum.UserInputType.Keyboard then KeyPicker.Value = input.KeyCode.Name
                        elseif input.UserInputType.Name:find("MouseButton") then KeyPicker.Value = input.UserInputType.Name
                        else return end
                        kpBtn.Text = KeyPicker.Value; kpBtn.TextColor3 = Novoline.Scheme.FontColor; waitingForKey = false
                        if KeyPicker._kbValue then KeyPicker._kbValue.Text = KeyPicker.Value .. " [" .. KeyPicker.Mode .. "]" end
                        KeyPicker.ChangedCallback(KeyPicker.Value)
                        for _, cb in ipairs(KeyPicker.ChangedCallbacks) do cb(KeyPicker.Value) end
                        return
                    end

                    if processed then return end
                    local inputName = nil
                    if input.UserInputType == Enum.UserInputType.Keyboard then inputName = input.KeyCode.Name
                    elseif input.UserInputType.Name:find("MouseButton") then inputName = input.UserInputType.Name end

                    if inputName and inputName == KeyPicker.Value then
                        if KeyPicker.Mode == "Toggle" then
                            KeyPicker.ToggleState = not KeyPicker.ToggleState
                            KeyPicker.Callback(KeyPicker.ToggleState)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do cb(KeyPicker.ToggleState) end
                            for _, cb in ipairs(KeyPicker.ClickCallbacks) do cb(KeyPicker.ToggleState) end
                            if KeyPicker.SyncToggle then KeyPicker.SyncToggle:SetValue(KeyPicker.ToggleState) end
                        elseif KeyPicker.Mode == "Hold" then
                            KeyPicker.HoldState = true; KeyPicker.Callback(true)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do cb(true) end
                        elseif KeyPicker.Mode == "Always" then
                            KeyPicker.Callback(true)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do cb(true) end
                        end
                    end
                end)

                Connect(UserInputService.InputEnded, function(input)
                    if KeyPicker.Mode == "Hold" then
                        local inputName = nil
                        if input.UserInputType == Enum.UserInputType.Keyboard then inputName = input.KeyCode.Name
                        elseif input.UserInputType.Name:find("MouseButton") then inputName = input.UserInputType.Name end
                        if inputName and inputName == KeyPicker.Value and KeyPicker.HoldState then
                            KeyPicker.HoldState = false; KeyPicker.Callback(false)
                            for _, cb in ipairs(KeyPicker.ChangedCallbacks) do cb(false) end
                        end
                    end
                end)

                function KeyPicker:SetValue(value)
                    if type(value) == "table" then KeyPicker.Value = value[1] or "None"; KeyPicker.Mode = value[2] or "Toggle"
                    else KeyPicker.Value = tostring(value) end
                    kpBtn.Text = KeyPicker.Value
                    if KeyPicker._kbValue then KeyPicker._kbValue.Text = KeyPicker.Value .. " [" .. KeyPicker.Mode .. "]" end
                    KeyPicker.ChangedCallback(KeyPicker.Value)
                    for _, cb in ipairs(KeyPicker.ChangedCallbacks) do cb(KeyPicker.Value) end
                end

                function KeyPicker:GetState() return KeyPicker.HoldState or KeyPicker.ToggleState end
                function KeyPicker:OnClick(callback) table.insert(KeyPicker.ClickCallbacks, callback) end
                function KeyPicker:OnChanged(callback) table.insert(KeyPicker.ChangedCallbacks, callback) end
                function KeyPicker:SetVisible(visible) KeyPicker._OriginalVisible = visible; kpFrame.Visible = visible end

                KeyPicker.Frame = kpFrame
                table.insert(Novoline.Elements, KeyPicker)
                Groupbox.Elements[#Groupbox.Elements + 1] = KeyPicker
                return KeyPicker
            end

            -- ADD LEFT TABBOX
            function Tab:AddLeftTabbox()
                local tabboxFrame = Create("Frame", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Novoline.Scheme.MainColor, BorderSizePixel = 0, LayoutOrder = 0, ZIndex = 5 }, tabContent)
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }, tabboxFrame)
                Create("UIStroke", { Color = Novoline.Scheme.OutlineColor, Thickness = 1 }, tabboxFrame)

                local tabBtnContainer = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Novoline.Scheme.SidebarColor, BorderSizePixel = 0, ZIndex = 6 }, tabboxFrame)
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }, tabBtnContainer)
                Create("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = Novoline.Scheme.SidebarColor, BorderSizePixel = 0, ZIndex = 6 }, tabBtnContainer)
                Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }, tabBtnContainer)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4) }, tabBtnContainer)

                local tabContentContainer = Create("Frame", { Size = UDim2.new(1, 0, 1, -24), Position = UDim2.new(0, 0, 0, 24), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6 }, tabboxFrame)

                local TabBox = {}
                TabBox.__index = TabBox
                TabBox.Frame = tabboxFrame
                TabBox.Tabs = {}
                TabBox.SelectedTab = nil

                function TabBox:AddTab(title)
                    local TabTab = {}
                    TabTab.__index = TabTab
                    TabTab.Title = tostring(title)

                    local tabBtn = Create("TextButton", { Size = UDim2.new(0, 60, 0, 20), BackgroundColor3 = Color3.fromRGB(35, 35, 50), BorderSizePixel = 0, Text = TabTab.Title, TextColor3 = Novoline.Scheme.TextMuted, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 7, LayoutOrder = #TabBox.Tabs + 1, AutoButtonColor = false }, tabBtnContainer)
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }, tabBtn)

                    local tabContent = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 7 }, tabContentContainer)
                    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, tabContent)
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, tabContent)

                    TabTab.Button = tabBtn
                    TabTab.Content = tabContent

                    local function SelectTabTab()
                        if TabBox.SelectedTab then
                            TabBox.SelectedTab.Content.Visible = false
                            Tween(TabBox.SelectedTab.Button, {BackgroundColor3 = Color3.fromRGB(35, 35, 50), TextColor3 = Novoline.Scheme.TextMuted}, 0.1)
                        end
                        TabBox.SelectedTab = TabTab
                        TabTab.Content.Visible = true
                        Tween(tabBtn, {BackgroundColor3 = Novoline.Scheme.AccentColor, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.1)
                    end

                    tabBtn.MouseButton1Click:Connect(SelectTabTab)

                    TabBox.Tabs[#TabBox.Tabs + 1] = TabTab
                    if #TabBox.Tabs == 1 then SelectTabTab() end

                    TabTab.Container = tabContent
                    for k, v in pairs(Groupbox) do
                        if type(v) == "function" and k ~= "AddLeftTabbox" and k ~= "AddRightTabbox" then
                            TabTab[k] = function(self, ...) return v(Groupbox, ...) end
                        end
                    end

                    return TabTab
                end

                Groupbox.Elements[#Groupbox.Elements + 1] = TabBox
                return TabBox
            end

            function Tab:AddRightTabbox()
                local tabbox = Tab:AddLeftTabbox()
                tabbox.Frame.LayoutOrder = 1
                return tabbox
            end

            Tab.Groupboxes[#Tab.Groupboxes + 1] = Groupbox
            return Groupbox
        end

        -- ADD KEY BOX
        function Tab:AddKeyBox(idxOrFunc, callback)
            local expectedKey = type(idxOrFunc) == "string" and idxOrFunc or nil
            local keyCallback = type(idxOrFunc) == "function" and idxOrFunc or callback

            local kbFrame = Create("Frame", { Name = "Keybox", Size = UDim2.new(0.8, 0, 0, 120), Position = UDim2.new(0.1, 0, 0.2, 0), BackgroundColor3 = Novoline.Scheme.MainColor, BorderSizePixel = 0, ZIndex = 10 }, tabContent)
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }, kbFrame)
            Create("UIStroke", { Color = Novoline.Scheme.OutlineColor, Thickness = 1 }, kbFrame)

            if expectedKey then
                Create("TextLabel", { Text = "Key: " .. expectedKey, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.FontColor, TextSize = 13, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), ZIndex = 11, TextWrapped = true }, kbFrame)
            end

            local kbInput = Create("TextBox", { Size = UDim2.new(0.85, 0, 0, 32), Position = UDim2.new(0.075, 0, 0, expectedKey and 36 or 6), BackgroundColor3 = Novoline.Scheme.InputColor, BorderSizePixel = 0, Text = "", PlaceholderText = "Enter your key...", PlaceholderColor3 = Novoline.Scheme.TextMuted, TextColor3 = Novoline.Scheme.FontColor, TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ClearTextOnFocus = false, ZIndex = 11 }, kbFrame)
            Create("UICorner", { CornerRadius = UDim.new(0, 5) }, kbInput)
            Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, kbInput)

            local kbBtn = Create("TextButton", { Size = UDim2.new(0.85, 0, 0, 30), Position = UDim2.new(0.075, 0, 0, expectedKey and 74 or 44), BackgroundColor3 = Novoline.Scheme.AccentColor, BorderSizePixel = 0, Text = "Submit", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 11, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), ZIndex = 11, AutoButtonColor = false }, kbFrame)
            Create("UICorner", { CornerRadius = UDim.new(0, 5) }, kbBtn)

            local kbStatus = Create("TextLabel", { Text = "", Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundTransparency = 1, TextColor3 = Novoline.Scheme.Error, TextSize = 10, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 11 }, kbFrame)

            kbBtn.MouseButton1Click:Connect(function() keyCallback(true, kbInput.Text) end)
            kbInput.FocusLost:Connect(function(enter) if enter then kbBtn.MouseButton1Click:Fire() end end)

            return kbFrame
        end

        return Tab
    end

    -- ADD KEY TAB (special tab for key system)
    function Window:AddKeyTab(title)
        return Window:AddTab(tostring(title or "Key System"))
    end

    Window.Tabs = Window.Tabs
    return Window
end

return Novoline
