--[[
    Novoline Save Manager
    Handles config saving, loading, and management
--]]

local SaveManager = {}
SaveManager.__index = SaveManager
SaveManager.Library = nil
SaveManager.ConfigFolder = "novoline/configs"
SaveManager.AutoloadFile = "novoline/autoload.txt"
SaveManager.IgnoredKeys = {}
SaveManager.Configs = {}
SaveManager.CurrentConfig = "Default"

function SaveManager:SetLibrary(library)
    self.Library = library
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoredKeys = {
        "BackgroundColorPicker",
        "MainColorPicker",
        "AccentColorPicker",
        "OutlineColorPicker",
        "FontColorPicker",
        "TextMutedPicker",
        "ThemeDropdown",
        "FontDropdown",
    }
end

function SaveManager:EnsureFolders()
    pcall(function()
        if not isfile("novoline/") then
            makefolder("novoline")
        end
        if not isfile(self.ConfigFolder .. "/") then
            makefolder(self.ConfigFolder)
        end
    end)
end

function SaveManager:GetConfigs()
    self.Configs = {}
    pcall(function()
        local success, files = pcall(listfiles, self.ConfigFolder)
        if success and files then
            for _, file in ipairs(files) do
                if file:find(".json") then
                    local name = file:match("/([^/]+)%.json$")
                    if name then
                        table.insert(self.Configs, name)
                    end
                end
            end
        end
    end)
    table.sort(self.Configs)
    return self.Configs
end

function SaveManager:SaveConfig(name)
    if not self.Library then return false end
    
    self:EnsureFolders()
    
    local data = {
        Toggles = {},
        Options = {},
    }
    
    -- Save Toggles
    for key, toggle in pairs(self.Library.Toggles) do
        if type(toggle) == "table" and toggle.Type == "Toggle" then
            data.Toggles[key] = toggle.Value
        end
    end
    
    -- Save Options
    for key, option in pairs(self.Library.Options) do
        if type(option) == "table" and not table.find(self.IgnoredKeys, key) then
            if option.Type == "Slider" then
                data.Options[key] = option.Value
            elseif option.Type == "Dropdown" and not option.Multi then
                data.Options[key] = option.Value
            elseif option.Type == "Dropdown" and option.Multi then
                local selected = {}
                for k, v in pairs(option.Selected) do
                    if v then
                        table.insert(selected, k)
                    end
                end
                data.Options[key] = selected
            elseif option.Type == "Input" then
                data.Options[key] = option.Value
            elseif option.Type == "KeyPicker" then
                data.Options[key] = option.Value
            elseif option.Type == "ColorPicker" then
                data.Options[key] = {
                    R = math.floor(option.Value.R * 255) / 255,
                    G = math.floor(option.Value.G * 255) / 255,
                    B = math.floor(option.Value.B * 255) / 255,
                }
            end
        end
    end
    
    local success, err = pcall(function()
        writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    
    return success
end

function SaveManager:LoadConfig(name)
    if not self.Library then return false end
    
    local data = nil
    local success, err = pcall(function()
        local content = readfile(self.ConfigFolder .. "/" .. name .. ".json")
        data = HttpService:JSONDecode(content)
    end)
    
    if not success or not data then
        return false
    end
    
    self.CurrentConfig = name
    
    -- Load Toggles
    if data.Toggles then
        for key, value in pairs(data.Toggles) do
            local toggle = self.Library.Toggles[key]
            if toggle and type(toggle) == "table" and toggle.SetValue then
                toggle:SetValue(value)
            end
        end
    end
    
    -- Load Options
    if data.Options then
        for key, value in pairs(data.Options) do
            if not table.find(self.IgnoredKeys, key) then
                local option = self.Library.Options[key]
                if option and type(option) == "table" and option.SetValue then
                    if option.Type == "ColorPicker" and type(value) == "table" then
                        option:SetValue(Color3.new(value.R or 1, value.G or 1, value.B or 1))
                    else
                        option:SetValue(value)
                    end
                end
            end
        end
    end
    
    return true
end

function SaveManager:DeleteConfig(name)
    local success, err = pcall(function()
        if isfile(self.ConfigFolder .. "/" .. name .. ".json") then
            delfile(self.ConfigFolder .. "/" .. name .. ".json")
        end
    end)
    return success
end

function SaveManager:SetAutoload(name)
    pcall(function()
        writefile(self.AutoloadFile, name)
    end)
end

function SaveManager:GetAutoload()
    local name = nil
    pcall(function()
        if isfile(self.AutoloadFile) then
            name = readfile(self.AutoloadFile)
        end
    end)
    return name
end

function SaveManager:LoadAutoloadConfig()
    local autoloadName = self:GetAutoload()
    if autoloadName and autoloadName ~= "" then
        local success = self:LoadConfig(autoloadName)
        return success
    end
    return false
end

function SaveManager:BuildConfigSection(tab)
    if not self.Library then return end
    
    self:EnsureFolders()
    self:GetConfigs()
    
    local configGroup = tab:AddLeftGroupbox({Title = "Configuration"})
    
    -- Config Name Input
    local configNameInput = configGroup:AddInput({
        Text = "Config Name",
        Placeholder = "Enter config name...",
        Default = self.CurrentConfig
    })
    
    -- Config Dropdown
    local configDropdown = configGroup:AddDropdown({
        Text = "Configs",
        Values = self.Configs,
        Default = self.CurrentConfig,
        Callback = function(value)
            self.CurrentConfig = value
            configNameInput:SetValue(value)
        end
    })
    
    -- Buttons
    configGroup:AddButton({
        Text = "Save Config",
        Callback = function()
            local name = configNameInput.Value
            if name and name ~= "" then
                if self:SaveConfig(name) then
                    self.Library:Notify({
                        Title = "Save Manager",
                        Content = "Config '" .. name .. "' saved successfully!"
                    })
                    self:GetConfigs()
                    configDropdown:Refresh(self.Configs)
                    configDropdown:SetValue(name)
                    self.CurrentConfig = name
                else
                    self.Library:Notify({
                        Title = "Save Manager",
                        Content = "Failed to save config!"
                    })
                end
            end
        end
    })
    
    configGroup:AddButton({
        Text = "Load Config",
        Callback = function()
            local name = configDropdown.Value
            if name then
                if self:LoadConfig(name) then
                    self.Library:Notify({
                        Title = "Save Manager",
                        Content = "Config '" .. name .. "' loaded successfully!"
                    })
                    configNameInput:SetValue(name)
                else
                    self.Library:Notify({
                        Title = "Save Manager",
                        Content = "Failed to load config!"
                    })
                end
            end
        end
    }):AddButton({
        Text = "Delete Config",
        Callback = function()
            local name = configDropdown.Value
            if name then
                if self:DeleteConfig(name) then
                    self.Library:Notify({
                        Title = "Save Manager",
                        Content = "Config '" .. name .. "' deleted!"
                    })
                    self:GetConfigs()
                    configDropdown:Refresh(self.Configs)
                    if self.CurrentConfig == name then
                        self.CurrentConfig = "Default"
                        configNameInput:SetValue("Default")
                    end
                else
                    self.Library:Notify({
                        Title = "Save Manager",
                        Content = "Failed to delete config!"
                    })
                end
            end
        end
    })
    
    configGroup:AddDivider()
    
    -- Autoload
    local autoloadToggle = configGroup:AddToggle({
        Text = "Autoload Config",
        Default = self:GetAutoload() ~= nil,
        Callback = function(value)
            if value then
                self:SetAutoload(self.CurrentConfig)
                self.Library:Notify({
                    Title = "Save Manager",
                    Content = "Autoload enabled for '" .. self.CurrentConfig .. "'"
                })
            else
                pcall(function()
                    if isfile(self.AutoloadFile) then
                        delfile(self.AutoloadFile)
                    end
                end)
                self.Library:Notify({
                    Title = "Save Manager",
                    Content = "Autoload disabled"
                })
            end
        end
    })
    
    configGroup:AddButton({
        Text = "Refresh Configs",
        Callback = function()
            self:GetConfigs()
            configDropdown:Refresh(self.Configs)
            self.Library:Notify({
                Title = "Save Manager",
                Content = "Config list refreshed!"
            })
        end
    })
end

return SaveManager
