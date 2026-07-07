--[[
    Novoline Hub - Example Usage
    Demonstrates all features of the Novoline UI Library
--]]

-- In a real scenario, these would be loaded from a repo
-- local Library = loadstring(game:HttpGet("LOCAL_REPO/Library.lua"))()
-- local ThemeManager = loadstring(game:HttpGet("LOCAL_REPO/addons/ThemeManager.lua"))()
-- local SaveManager = loadstring(game:HttpGet("LOCAL_REPO/addons/SaveManager.lua"))()

-- For local testing, require the files directly
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/Novoline/main/Library.lua"))() or -- Fallback to inline
(function()
    -- Inline Library code would go here for fully local testing
    -- This is just a placeholder structure
    return getgenv().Novoline or {}
end)()

local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/Novoline/main/addons/ThemeManager.lua"))() or
(function()
    return getgenv().NovolineThemeManager or {}
end)()

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/Novoline/main/addons/SaveManager.lua"))() or
(function()
    return getgenv().NovolineSaveManager or {}
end)()

-- Aliases
local Options = Library.Options
local Toggles = Library.Toggles

-- Library Settings
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- Create Window
local Window = Library:CreateWindow({
    Title = "Novoline Hub",
    Footer = "v1.0.0",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- Store tabs
local Tabs = {}

-- ============ MAIN TAB ============
Tabs["Main"] = Window:AddTab({Title = "Main", Icon = nil})

-- Left Groupbox - Combat
local CombatBox = Tabs["Main"]:AddLeftGroupbox({Title = "Combat"})

CombatBox:AddToggle({
    Text = "Enable Combat",
    Default = false,
    Key = "CombatEnabled",
    Callback = function(value)
        print("Combat enabled:", value)
    end
})

CombatBox:AddToggle({
    Text = "Silent Aim",
    Default = false,
    Key = "SilentAim",
    Callback = function(value)
        print("Silent aim:", value)
    end,
    Color = {
        Default = Color3.fromRGB(255, 50, 50),
        Callback = function(color)
            print("Silent aim color:", color)
        end
    }
})

CombatBox:AddSlider({
    Text = "Hit Chance",
    Min = 0,
    Max = 100,
    Default = 75,
    Rounding = 0,
    Suffix = "%",
    Key = "HitChance",
    Callback = function(value)
        print("Hit chance:", value)
    end
})

CombatBox:AddSlider({
    Text = "FOV Radius",
    Min = 10,
    Max = 500,
    Default = 120,
    Rounding = 0,
    Suffix = "px",
    Key = "FOVRadius",
    Callback = function(value)
        print("FOV radius:", value)
    end
})

CombatBox:AddDropdown({
    Text = "Target Part",
    Values = {"Head", "HumanoidRootPart", "Torso", "Neck"},
    Default = "Head",
    Key = "TargetPart",
    Callback = function(value)
        print("Target part:", value)
    end
})

CombatBox:AddDropdown({
    Text = "Whitelist",
    Values = {"All", "Enemies Only", "Friends Only", "Custom"},
    Default = "All",
    Key = "TargetWhitelist",
    Callback = function(value)
        print("Whitelist:", value)
    end
})

-- Right Groupbox - Movement
local MoveBox = Tabs["Main"]:AddRightGroupbox({Title = "Movement"})

MoveBox:AddToggle({
    Text = "Speed Hack",
    Default = false,
    Key = "SpeedHack",
    Callback = function(value)
        print("Speed hack:", value)
    end
})

MoveBox:AddSlider({
    Text = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 50,
    Rounding = 0,
    Key = "WalkSpeed",
    Callback = function(value)
        print("Walk speed:", value)
    end
})

MoveBox:AddToggle({
    Text = "Jump Power",
    Default = false,
    Key = "JumpPowerEnabled",
    Callback = function(value)
        print("Jump power enabled:", value)
    end
})

MoveBox:AddSlider({
    Text = "Jump Height",
    Min = 50,
    Max = 500,
    Default = 150,
    Rounding = 0,
    Key = "JumpHeight",
    Callback = function(value)
        print("Jump height:", value)
    end
})

MoveBox:AddToggle({
    Text = "No Clip",
    Default = false,
    Key = "NoClip",
    Callback = function(value)
        print("No clip:", value)
    end
})

MoveBox:AddToggle({
    Text = "Fly",
    Default = false,
    Key = "FlyEnabled",
    Callback = function(value)
        print("Fly:", value)
    end
})

MoveBox:AddSlider({
    Text = "Fly Speed",
    Min = 10,
    Max = 300,
    Default = 80,
    Rounding = 0,
    Key = "FlySpeed",
    Callback = function(value)
        print("Fly speed:", value)
    end
})

-- ============ PLAYER TAB ============
Tabs["Player"] = Window:AddTab({Title = "Player", Icon = nil})

local PlayerBox = Tabs["Player"]:AddLeftGroupbox({Title = "Player Options"})

PlayerBox:AddToggle({
    Text = "God Mode",
    Default = false,
    Key = "GodMode",
    Callback = function(value)
        print("God mode:", value)
    end
})

PlayerBox:AddToggle({
    Text = "Infinite Jump",
    Default = false,
    Key = "InfiniteJump",
    Callback = function(value)
        print("Infinite jump:", value)
    end
})

PlayerBox:AddToggle({
    Text = "No Fall Damage",
    Default = false,
    Key = "NoFallDamage",
    Callback = function(value)
        print("No fall damage:", value)
    end
})

PlayerBox:AddDivider()

PlayerBox:AddLabel("Character Appearance")

PlayerBox:AddToggle({
    Text = "Invisible",
    Default = false,
    Key = "Invisible",
    Callback = function(value)
        print("Invisible:", value)
    end
})

PlayerBox:AddColorPicker({
    Text = "Body Color",
    Default = Color3.fromRGB(100, 100, 255),
    Key = "BodyColor",
    Callback = function(color)
        print("Body color:", color)
    end
})

local TargetBox = Tabs["Player"]:AddRightGroupbox({Title = "Target Player"})

TargetBox:AddDropdown({
    Text = "Select Player",
    SpecialType = "Player",
    Key = "TargetPlayer",
    Callback = function(value)
        print("Target player:", value)
    end
})

TargetBox:AddButton({
    Text = "Teleport To Player",
    Callback = function()
        print("Teleporting to:", Options.TargetPlayer.Value)
    end
})

TargetBox:AddButton({
    Text = "View Player",
    Callback = function()
        print("Viewing:", Options.TargetPlayer.Value)
    end
}):AddButton({
    Text = "Spectate Player",
    Callback = function()
        print("Spectating:", Options.TargetPlayer.Value)
    end
})

-- ============ VISUALS TAB ============
Tabs["Visuals"] = Window:AddTab({Title = "Visuals", Icon = nil})

local EspBox = Tabs["Visuals"]:AddLeftGroupbox({Title = "ESP"})

EspBox:AddToggle({
    Text = "Enable ESP",
    Default = false,
    Key = "ESPEnabled",
    Callback = function(value)
        print("ESP enabled:", value)
    end
})

EspBox:AddToggle({
    Text = "Box ESP",
    Default = true,
    Key = "BoxESP",
    Callback = function(value)
        print("Box ESP:", value)
    end
})

EspBox:AddToggle({
    Text = "Name ESP",
    Default = true,
    Key = "NameESP",
    Callback = function(value)
        print("Name ESP:", value)
    end
})

EspBox:AddToggle({
    Text = "Health Bar",
    Default = false,
    Key = "HealthBar",
    Callback = function(value)
        print("Health bar:", value)
    end
})

EspBox:AddToggle({
    Text = "Tracers",
    Default = false,
    Key = "Tracers",
    Callback = function(value)
        print("Tracers:", value)
    end
})

EspBox:AddColorPicker({
    Text = "Enemy Color",
    Default = Color3.fromRGB(255, 50, 50),
    Key = "EnemyColor",
    Callback = function(color)
        print("Enemy color:", color)
    end
})

EspBox:AddColorPicker({
    Text = "Team Color",
    Default = Color3.fromRGB(50, 255, 50),
    Key = "TeamColor",
    Callback = function(color)
        print("Team color:", color)
    end
})

local WorldBox = Tabs["Visuals"]:AddRightGroupbox({Title = "World"})

WorldBox:AddToggle({
    Text = "Full Bright",
    Default = false,
    Key = "FullBright",
    Callback = function(value)
        print("Full bright:", value)
    end
})

WorldBox:AddToggle({
    Text = "No Fog",
    Default = false,
    Key = "NoFog",
    Callback = function(value)
        print("No fog:", value)
    end
})

WorldBox:AddToggle({
    Text = "Ambient Light",
    Default = false,
    Key = "AmbientLight",
    Callback = function(value)
        print("Ambient light:", value)
    end,
    Color = {
        Default = Color3.fromRGB(255, 200, 100),
        Callback = function(color)
            print("Ambient color:", color)
        end
    }
})

WorldBox:AddSlider({
    Text = "Time of Day",
    Min = 0,
    Max = 24,
    Default = 14,
    Rounding = 1,
    Suffix = "h",
    Key = "TimeOfDay",
    Callback = function(value)
        print("Time of day:", value)
    end
})

WorldBox:AddDivider()

WorldBox:AddLabel("FOV Settings")

WorldBox:AddToggle({
    Text = "Show FOV Circle",
    Default = false,
    Key = "ShowFOV",
    Callback = function(value)
        print("Show FOV:", value)
    end
})

WorldBox:AddSlider({
    Text = "FOV Size",
    Min = 10,
    Max = 500,
    Default = 120,
    Rounding = 0,
    Key = "FOVSize",
    Callback = function(value)
        print("FOV size:", value)
    end
})

WorldBox:AddColorPicker({
    Text = "FOV Color",
    Default = Color3.fromRGB(255, 255, 255),
    Key = "FOVColor",
    Callback = function(color)
        print("FOV color:", color)
    end,
    Transparency = 0.5
})

-- ============ MISC TAB ============
Tabs["Misc"] = Window:AddTab({Title = "Misc", Icon = nil})

local MiscBox = Tabs["Misc"]:AddLeftGroupbox({Title = "Miscellaneous"})

MiscBox:AddToggle({
    Text = "Anti-AFK",
    Default = true,
    Key = "AntiAFK",
    Callback = function(value)
        print("Anti-AFK:", value)
    end
})

MiscBox:AddToggle({
    Text = "Auto Rejoin",
    Default = false,
    Key = "AutoRejoin",
    Callback = function(value)
        print("Auto rejoin:", value)
    end
})

MiscBox:AddDropdown({
    Text = "Server Hop Method",
    Values = {"Teleport", "Rejoin", "Low Server"},
    Default = "Teleport",
    Key = "ServerHopMethod",
    Callback = function(value)
        print("Server hop method:", value)
    end
})

MiscBox:AddDivider()

MiscBox:AddLabel("Chat Settings")

MiscBox:AddToggle({
    Text = "Chat Bypass",
    Default = false,
    Key = "ChatBypass",
    Callback = function(value)
        print("Chat bypass:", value)
    end
})

MiscBox:AddToggle({
    Text = "Spam Chat",
    Default = false,
    Key = "SpamChat",
    Callback = function(value)
        print("Spam chat:", value)
    end
})

MiscBox:AddInput({
    Text = "Spam Message",
    Placeholder = "Enter message...",
    Default = "Novoline Hub on top!",
    Key = "SpamMessage",
    Callback = function(value)
        print("Spam message:", value)
    end
})

MiscBox:AddSlider({
    Text = "Spam Delay",
    Min = 0.5,
    Max = 10,
    Default = 2,
    Rounding = 1,
    Suffix = "s",
    Key = "SpamDelay",
    Callback = function(value)
        print("Spam delay:", value)
    end
})

local ScriptBox = Tabs["Misc"]:AddRightGroupbox({Title = "Script Hub"})

ScriptBox:AddDropdown({
    Text = "Select Script",
    Values = {"Infinite Yield", "Owl Hub", "Dark Dex", "SimpleSpy", "RemoteSpy"},
    Default = "Infinite Yield",
    Searchable = true,
    Key = "SelectedScript",
    Callback = function(value)
        print("Selected script:", value)
    end
})

ScriptBox:AddButton({
    Text = "Execute Script",
    Callback = function()
        print("Executing:", Options.SelectedScript.Value)
        Window:Notify({
            Title = "Script Hub",
            Content = "Executing " .. Options.SelectedScript.Value .. "..."
        })
    end
})

ScriptBox:AddDivider()

ScriptBox:AddLabel("Custom Script")

ScriptBox:AddInput({
    Text = "Script URL",
    Placeholder = "https://...",
    Key = "CustomScriptURL",
    Callback = function(value)
        print("Script URL:", value)
    end
})

ScriptBox:AddButton({
    Text = "Load Custom Script",
    Callback = function()
        print("Loading custom script...")
    end
})

-- Multi-select dropdown example
local MultiBox = Tabs["Misc"]:AddRightGroupbox({Title = "Multi-Select Example"})

MultiBox:AddLabel("Features to Enable:")

MultiBox:AddDropdown({
    Text = "Features",
    Values = {"Feature 1", "Feature 2", "Feature 3", "Feature 4", "Feature 5"},
    Multi = true,
    Default = {"Feature 1", "Feature 3"},
    Searchable = true,
    Key = "MultiFeatures",
    Callback = function(selected)
        print("Selected features:", selected)
    end
})

-- ============ KEYBINDS TAB ============
Tabs["Keybinds"] = Window:AddTab({Title = "Keybinds", Icon = nil})

local KeybindBox = Tabs["Keybinds"]:AddLeftGroupbox({Title = "Combat Keybinds"})

local combatToggle = KeybindBox:AddToggle({
    Text = "Combat",
    Default = false,
    Key = "CombatKeybindToggle"
})

KeybindBox:AddKeyPicker({
    Text = "Combat Toggle",
    Default = "Q",
    Mode = "Toggle",
    SyncToggle = combatToggle,
    Key = "CombatKeybind",
    Callback = function(value)
        print("Combat keybind:", value)
    end
})

KeybindBox:AddKeyPicker({
    Text = "Aim Lock",
    Default = "E",
    Mode = "Hold",
    Key = "AimLockKeybind",
    Callback = function(value)
        print("Aim lock:", value)
    end
})

local MoveKeyBox = Tabs["Keybinds"]:AddRightGroupbox({Title = "Movement Keybinds"})

local speedToggle = MoveKeyBox:AddToggle({
    Text = "Speed",
    Default = false,
    Key = "SpeedKeybindToggle"
})

MoveKeyBox:AddKeyPicker({
    Text = "Speed Toggle",
    Default = "LeftControl",
    Mode = "Toggle",
    SyncToggle = speedToggle,
    Key = "SpeedKeybind",
    Callback = function(value)
        print("Speed keybind:", value)
    end
})

local flyToggle = MoveKeyBox:AddToggle({
    Text = "Fly",
    Default = false,
    Key = "FlyKeybindToggle"
})

MoveKeyBox:AddKeyPicker({
    Text = "Fly Toggle",
    Default = "F",
    Mode = "Toggle",
    SyncToggle = flyToggle,
    Key = "FlyKeybind",
    Callback = function(value)
        print("Fly keybind:", value)
    end
})

MoveKeyBox:AddKeyPicker({
    Text = "No Clip",
    Default = "N",
    Mode = "Toggle",
    Key = "NoClipKeybind",
    Callback = function(value)
        print("No clip keybind:", value)
    end
})

-- ============ UI SETTINGS TAB ============
Tabs["UI Settings"] = Window:AddTab({Title = "UI Settings", Icon = nil})

local UISettingsBox = Tabs["UI Settings"]:AddLeftGroupbox({Title = "UI Options"})

UISettingsBox:AddToggle({
    Text = "Show Custom Cursor",
    Default = true,
    Key = "ShowCursor",
    Callback = function(value)
        -- Would toggle cursor visibility
    end
})

UISettingsBox:AddToggle({
    Text = "Show Notifications",
    Default = true,
    Key = "ShowNotifications",
    Callback = function(value)
        print("Show notifications:", value)
    end
})

UISettingsBox:AddSlider({
    Text = "Notification Duration",
    Min = 1,
    Max = 10,
    Default = 4,
    Rounding = 1,
    Suffix = "s",
    Key = "NotificationDuration",
    Callback = function(value)
        print("Notification duration:", value)
    end
})

UISettingsBox:AddDropdown({
    Text = "Notification Side",
    Values = {"Left", "Right"},
    Default = "Right",
    Key = "NotificationSide",
    Callback = function(value)
        print("Notification side:", value)
    end
})

UISettingsBox:AddDivider()

UISettingsBox:AddLabel("Menu Position")

UISettingsBox:AddButton({
    Text = "Reset Position",
    Callback = function()
        print("Reset window position")
    end
})

UISettingsBox:AddButton({
    Text = "Unload UI",
    Callback = function()
        Library:Unload()
    end
})

-- Roblox Versions Section
local RobloxBox = Tabs["UI Settings"]:AddRightGroupbox({Title = "Roblox Versions"})

RobloxBox:AddLabel("Current Version Tracker")
RobloxBox:AddDivider()

local windowsLabel = RobloxBox:AddLabel("Windows: Loading...")
local macLabel = RobloxBox:AddLabel("Mac: Loading...")
local androidLabel = RobloxBox:AddLabel("Android: Loading...")
local iosLabel = RobloxBox:AddLabel("iOS: Loading...")

local function FetchVersions()
    pcall(function()
        local response = game:HttpGet("https://weao.xyz/api/versions/current", true)
        local data = HttpService:JSONDecode(response)
        
        if data then
            windowsLabel:SetText("Windows: " .. (data.Windows or "N/A"))
            macLabel:SetText("Mac: " .. (data.Mac or "N/A"))
            androidLabel:SetText("Android: " .. (data.Android or "N/A"))
            iosLabel:SetText("iOS: " .. (data.iOS or "N/A"))
        end
    end)
end

FetchVersions()

RobloxBox:AddDivider()

RobloxBox:AddLabel("License Info")
local licenseLabel = RobloxBox:AddLabel("License: Free")
local expiresLabel = RobloxBox:AddLabel("Expires: Never")

RobloxBox:AddDivider()

RobloxBox:AddButton({
    Text = "Refresh Versions",
    Callback = function()
        windowsLabel:SetText("Windows: Loading...")
        macLabel:SetText("Mac: Loading...")
        androidLabel:SetText("Android: Loading...")
        iosLabel:SetText("iOS: Loading...")
        FetchVersions()
        Window:Notify({
