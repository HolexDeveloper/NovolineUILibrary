--[[
    Novoline Theme Manager
    Handles theme switching and customization
--]]

local ThemeManager = {}
ThemeManager.__index = ThemeManager
ThemeManager.Library = nil
ThemeManager.ThemeFolder = "novoline/themes"
ThemeManager.BuiltInThemes = {}
ThemeManager.CustomThemes = {}
ThemeManager.CurrentTheme = "Default"

-- 18 Built-in Themes
ThemeManager.BuiltInThemes = {
    ["Default"] = {
        BackgroundColor = Color3.fromRGB(12, 12, 16),
        MainColor = Color3.fromRGB(20, 20, 28),
        AccentColor = Color3.fromRGB(90, 120, 255),
        OutlineColor = Color3.fromRGB(35, 35, 50),
        FontColor = Color3.fromRGB(220, 220, 230),
        TextMuted = Color3.fromRGB(100, 100, 120),
    },
    ["Midnight"] = {
        BackgroundColor = Color3.fromRGB(10, 10, 18),
        MainColor = Color3.fromRGB(18, 18, 30),
        AccentColor = Color3.fromRGB(120, 80, 255),
        OutlineColor = Color3.fromRGB(30, 30, 50),
        FontColor = Color3.fromRGB(210, 210, 230),
        TextMuted = Color3.fromRGB(90, 90, 120),
    },
    ["Ocean"] = {
        BackgroundColor = Color3.fromRGB(8, 15, 22),
        MainColor = Color3.fromRGB(15, 25, 38),
        AccentColor = Color3.fromRGB(0, 180, 220),
        OutlineColor = Color3.fromRGB(25, 40, 55),
        FontColor = Color3.fromRGB(200, 220, 240),
        TextMuted = Color3.fromRGB(80, 120, 150),
    },
    ["Forest"] = {
        BackgroundColor = Color3.fromRGB(10, 18, 12),
        MainColor = Color3.fromRGB(18, 30, 22),
        AccentColor = Color3.fromRGB(80, 200, 120),
        OutlineColor = Color3.fromRGB(30, 50, 38),
        FontColor = Color3.fromRGB(200, 230, 210),
        TextMuted = Color3.fromRGB(80, 130, 100),
    },
    ["Blood"] = {
        BackgroundColor = Color3.fromRGB(18, 8, 10),
        MainColor = Color3.fromRGB(30, 15, 18),
        AccentColor = Color3.fromRGB(220, 50, 60),
        OutlineColor = Color3.fromRGB(50, 25, 30),
        FontColor = Color3.fromRGB(240, 200, 200),
        TextMuted = Color3.fromRGB(150, 90, 95),
    },
    ["Sunset"] = {
        BackgroundColor = Color3.fromRGB(20, 12, 15),
        MainColor = Color3.fromRGB(35, 22, 28),
        AccentColor = Color3.fromRGB(255, 120, 60),
        OutlineColor = Color3.fromRGB(55, 35, 42),
        FontColor = Color3.fromRGB(255, 220, 200),
        TextMuted = Color3.fromRGB(160, 110, 100),
    },
    ["Purple"] = {
        BackgroundColor = Color3.fromRGB(15, 10, 22),
        MainColor = Color3.fromRGB(25, 18, 38),
        AccentColor = Color3.fromRGB(160, 80, 255),
        OutlineColor = Color3.fromRGB(40, 28, 60),
        FontColor = Color3.fromRGB(220, 200, 250),
        TextMuted = Color3.fromRGB(120, 90, 160),
    },
    ["Pink"] = {
        BackgroundColor = Color3.fromRGB(20, 10, 18),
        MainColor = Color3.fromRGB(35, 18, 32),
        AccentColor = Color3.fromRGB(255, 80, 150),
        OutlineColor = Color3.fromRGB(55, 28, 48),
        FontColor = Color3.fromRGB(255, 210, 230),
        TextMuted = Color3.fromRGB(160, 90, 130),
    },
    ["Gold"] = {
        BackgroundColor = Color3.fromRGB(18, 16, 10),
        MainColor = Color3.fromRGB(32, 28, 18),
        AccentColor = Color3.fromRGB(255, 200, 50),
        OutlineColor = Color3.fromRGB(52, 45, 28),
        FontColor = Color3.fromRGB(255, 240, 200),
        TextMuted = Color3.fromRGB(160, 140, 80),
    },
    ["Cyan"] = {
        BackgroundColor = Color3.fromRGB(8, 18, 20),
        MainColor = Color3.fromRGB(15, 30, 35),
        AccentColor = Color3.fromRGB(0, 220, 255),
        OutlineColor = Color3.fromRGB(25, 48, 55),
        FontColor = Color3.fromRGB(200, 240, 250),
        TextMuted = Color3.fromRGB(80, 150, 165),
    },
    ["Lime"] = {
        BackgroundColor = Color3.fromRGB(12, 18, 8),
        MainColor = Color3.fromRGB(22, 32, 15),
        AccentColor = Color3.fromRGB(150, 255, 50),
        OutlineColor = Color3.fromRGB(38, 52, 25),
        FontColor = Color3.fromRGB(220, 250, 200),
        TextMuted = Color3.fromRGB(100, 150, 70),
    },
    ["Ruby"] = {
        BackgroundColor = Color3.fromRGB(22, 8, 15),
        MainColor = Color3.fromRGB(38, 15, 25),
        AccentColor = Color3.fromRGB(230, 30, 80),
        OutlineColor = Color3.fromRGB(60, 25, 40),
        FontColor = Color3.fromRGB(255, 200, 220),
        TextMuted = Color3.fromRGB(170, 80, 110),
    },
    ["Sapphire"] = {
        BackgroundColor = Color3.fromRGB(8, 12, 22),
        MainColor = Color3.fromRGB(15, 22, 40),
        AccentColor = Color3.fromRGB(50, 100, 255),
        OutlineColor = Color3.fromRGB(25, 38, 65),
        FontColor = Color3.fromRGB(200, 215, 255),
        TextMuted = Color3.fromRGB(80, 110, 180),
    },
    ["Emerald"] = {
        BackgroundColor = Color3.fromRGB(8, 18, 14),
        MainColor = Color3.fromRGB(15, 32, 25),
        AccentColor = Color3.fromRGB(30, 220, 130),
        OutlineColor = Color3.fromRGB(25, 52, 42),
        FontColor = Color3.fromRGB(200, 250, 225),
        TextMuted = Color3.fromRGB(70, 150, 110),
    },
    ["Amber"] = {
        BackgroundColor = Color3.fromRGB(20, 15, 8),
        MainColor = Color3.fromRGB(35, 26, 15),
        AccentColor = Color3.fromRGB(255, 170, 30),
        OutlineColor = Color3.fromRGB(55, 42, 25),
        FontColor = Color3.fromRGB(255, 235, 195),
        TextMuted = Color3.fromRGB(165, 125, 65),
    },
    ["Rose"] = {
        BackgroundColor = Color3.fromRGB(22, 12, 16),
        MainColor = Color3.fromRGB(38, 20, 28),
        AccentColor = Color3.fromRGB(255, 100, 130),
        OutlineColor = Color3.fromRGB(60, 32, 45),
        FontColor = Color3.fromRGB(255, 215, 225),
        TextMuted = Color3.fromRGB(170, 100, 120),
    },
    ["Storm"] = {
        BackgroundColor = Color3.fromRGB(14, 14, 18),
        MainColor = Color3.fromRGB(24, 24, 32),
        AccentColor = Color3.fromRGB(130, 140, 180),
        OutlineColor = Color3.fromRGB(40, 40, 55),
        FontColor = Color3.fromRGB(210, 215, 230),
        TextMuted = Color3.fromRGB(110, 115, 140),
    },
    ["Void"] = {
        BackgroundColor = Color3.fromRGB(5, 5, 8),
        MainColor = Color3.fromRGB(12, 12, 18),
        AccentColor = Color3.fromRGB(100, 100, 140),
        OutlineColor = Color3.fromRGB(25, 25, 38),
        FontColor = Color3.fromRGB(180, 180, 200),
        TextMuted = Color3.fromRGB(80, 80, 110),
    },
}

function ThemeManager:SetLibrary(library)
    self.Library = library
end

function ThemeManager:LoadThemes()
    self.CustomThemes = {}
    
    pcall(function()
        if not isfile(self.ThemeFolder .. "/") then
            makefolder(self.ThemeFolder)
        end
        
        local success, files = pcall(listfiles, self.ThemeFolder)
        if success and files then
            for _, file in ipairs(files) do
                if file:find(".json") then
                    local success, data = pcall(function()
                        return HttpService:JSONDecode(readfile(file))
                    end)
                    if success and data then
                        local themeName = file:match("/([^/]+)%.json$")
                        if themeName then
                            self.CustomThemes[themeName] = {
                                BackgroundColor = Color3.fromRGB(data.BackgroundColor or 12, data.BackgroundColor and 0 or 12, data.BackgroundColor and 0 or 16),
                                MainColor = Color3.fromRGB(data.MainColor or 20, data.MainColor and 0 or 20, data.MainColor and 0 or 28),
                                AccentColor = Color3.fromRGB(data.AccentColor or 90, data.AccentColor and 0 or 120, data.AccentColor and 0 or 255),
                                OutlineColor = Color3.fromRGB(data.OutlineColor or 35, data.OutlineColor and 0 or 35, data.OutlineColor and 0 or 50),
                                FontColor = Color3.fromRGB(data.FontColor or 220, data.FontColor and 0 or 220, data.FontColor and 0 or 230),
                                TextMuted = Color3.fromRGB(data.TextMuted or 100, data.TextMuted and 0 or 100, data.TextMuted and 0 or 120),
                            }
                            -- Properly parse colors if they're tables
                            if type(data.BackgroundColor) == "table" then
                                self.CustomThemes[themeName].BackgroundColor = Color3.fromRGB(data.BackgroundColor[1] or 12, data.BackgroundColor[2] or 12, data.BackgroundColor[3] or 16)
                            end
                            if type(data.MainColor) == "table" then
                                self.CustomThemes[themeName].MainColor = Color3.fromRGB(data.MainColor[1] or 20, data.MainColor[2] or 20, data.MainColor[3] or 28)
                            end
                            if type(data.AccentColor) == "table" then
                                self.CustomThemes[themeName].AccentColor = Color3.fromRGB(data.AccentColor[1] or 90, data.AccentColor[2] or 120, data.AccentColor[3] or 255)
                            end
                            if type(data.OutlineColor) == "table" then
                                self.CustomThemes[themeName].OutlineColor = Color3.fromRGB(data.OutlineColor[1] or 35, data.OutlineColor[2] or 35, data.OutlineColor[3] or 50)
                            end
                            if type(data.FontColor) == "table" then
                                self.CustomThemes[themeName].FontColor = Color3.fromRGB(data.FontColor[1] or 220, data.FontColor[2] or 220, data.FontColor[3] or 230)
                            end
                            if type(data.TextMuted) == "table" then
                                self.CustomThemes[themeName].TextMuted = Color3.fromRGB(data.TextMuted[1] or 100, data.TextMuted[2] or 100, data.TextMuted[3] or 120)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function ThemeManager:GetThemes()
    local themes = {}
    for name, _ in pairs(self.BuiltInThemes) do
        table.insert(themes, name)
    end
    for name, _ in pairs(self.CustomThemes) do
        table.insert(themes, name)
    end
    table.sort(themes)
    return themes
end

function ThemeManager:GetTheme(name)
    return self.BuiltInThemes[name] or self.CustomThemes[name] or self.BuiltInThemes["Default"]
end

function ThemeManager:SetTheme(name)
    local theme = self:GetTheme(name)
    if theme and self.Library then
        self.Library:SetScheme(theme)
        self.CurrentTheme = name
    end
end

function ThemeManager:SaveTheme(name, themeData)
    pcall(function()
        if not isfile(self.ThemeFolder .. "/") then
            makefolder(self.ThemeFolder)
        end
        
        local data = {
            BackgroundColor = {math.floor(themeData.BackgroundColor.R * 255), math.floor(themeData.BackgroundColor.G * 255), math.floor(themeData.BackgroundColor.B * 255)},
            MainColor = {math.floor(themeData.MainColor.R * 255), math.floor(themeData.MainColor.G * 255), math.floor(themeData.MainColor.B * 255)},
            AccentColor = {math.floor(themeData.AccentColor.R * 255), math.floor(themeData.AccentColor.G * 255), math.floor(themeData.AccentColor.B * 255)},
            OutlineColor = {math.floor(themeData.OutlineColor.R * 255), math.floor(themeData.OutlineColor.G * 255), math.floor(themeData.OutlineColor.B * 255)},
            FontColor = {math.floor(themeData.FontColor.R * 255), math.floor(themeData.FontColor.G * 255), math.floor(themeData.FontColor.B * 255)},
            TextMuted = {math.floor(themeData.TextMuted.R * 255), math.floor(themeData.TextMuted.G * 255), math.floor(themeData.TextMuted.B * 255)},
        }
        
        writefile(self.ThemeFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        self:LoadThemes()
    end)
end

function ThemeManager:ApplyToTab(tab)
    if not self.Library then return end
    
    local themeGroup = tab:AddLeftGroupbox({Title = "Theme"})
    
    -- Theme Dropdown
    local themeDropdown = themeGroup:AddDropdown({
        Text = "Theme",
        Values = self:GetThemes(),
        Default = self.CurrentTheme,
        Callback = function(value)
            self:SetTheme(value)
        end
    })
    
    themeGroup:AddDivider()
    
    -- Color Pickers
    local bgPicker = themeGroup:AddColorPicker({
        Text = "Background",
        Default = self.Library.Scheme.BackgroundColor,
        Callback = function(color)
            self.Library.Scheme.BackgroundColor = color
            self.Library:UpdateColorsUsingRegistry()
        end
    })
    
    local mainPicker = themeGroup:AddColorPicker({
        Text = "Main",
        Default = self.Library.Scheme.MainColor,
        Callback = function(color)
            self.Library.Scheme.MainColor = color
            self.Library:UpdateColorsUsingRegistry()
        end
    })
    
    local accentPicker = themeGroup:AddColorPicker({
        Text = "Accent",
        Default = self.Library.Scheme.AccentColor,
        Callback = function(color)
            self.Library.Scheme.AccentColor = color
            self.Library:UpdateColorsUsingRegistry()
        end
    })
    
    local outlinePicker = themeGroup:AddColorPicker({
        Text = "Outline",
        Default = self.Library.Scheme.OutlineColor,
        Callback = function(color)
            self.Library.Scheme.OutlineColor = color
            self.Library:UpdateColorsUsingRegistry()
        end
    })
    
    local fontPicker = themeGroup:AddColorPicker({
        Text = "Font",
        Default = self.Library.Scheme.FontColor,
        Callback = function(color)
            self.Library.Scheme.FontColor = color
            self.Library:UpdateColorsUsingRegistry()
        end
    })
    
    local mutedPicker = themeGroup:AddColorPicker({
        Text = "Text Muted",
        Default = self.Library.Scheme.TextMuted,
        Callback = function(color)
            self.Library.Scheme.TextMuted = color
            self.Library:UpdateColorsUsingRegistry()
        end
    })
    
    -- Save Custom Theme Button
    themeGroup:AddDivider()
    
    local themeNameInput = themeGroup:AddInput({
        Text = "Theme Name",
        Placeholder = "Enter theme name...",
        Default = "MyTheme"
    })
    
    themeGroup:AddButton({
        Text = "Save Custom Theme",
        Callback = function()
            self:SaveTheme(themeNameInput.Value, self.Library.Scheme)
            themeDropdown:Refresh(self:GetThemes())
        end
    })
    
    -- Update picker values when theme changes
    themeDropdown:OnChanged(function(value)
        local theme = self:GetTheme(value)
        if theme then
            bgPicker:SetValue(theme.BackgroundColor)
            mainPicker:SetValue(theme.MainColor)
            accentPicker:SetValue(theme.AccentColor)
            outlinePicker:SetValue(theme.OutlineColor)
            fontPicker:SetValue(theme.FontColor)
            mutedPicker:SetValue(theme.TextMuted)
        end
    end)
end

function ThemeManager:IgnoreThemeSettings()
    -- Placeholder for SaveManager integration
end

return ThemeManager
