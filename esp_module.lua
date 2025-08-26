--nigga why u use https spy kys bro i hope u die soon (by ilya)
local ESP = {}
ESP.__index = ESP

local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local plr = game.Players.LocalPlayer

ESP.settings = {
    Mon = false,
    Fruit = false,
    Chest = false,
    Quest = false,
    Player = false,
    PeliBag = false,
    ShowDistance = true,
    ShowPeliBagAmount = true,
    PlayerNameType = "DisplayName",
    TextSize = 12
}

ESP.objects = {
    Mon = {},
    Fruit = {},
    Chest = {},
    Quest = {},
    Player = {},
    PeliBag = {}
}

local notifierRef = nil
local updateConnection = nil
local eventConnections = {}

function ESP:init(notifier)
    notifierRef = notifier
    return self
end

local function WTS(part)
    local screen, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part)
    return Vector2.new(screen.X, screen.Y), onScreen
end

local function getDistanceStuff(part)
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        return math.floor((part.Position - plr.Character.HumanoidRootPart.Position).Magnitude)
    end
    return 0
end

local function makeESPLabel(part, text, color, espType)
    local labelThing = Drawing.new("Text")
    
    local finalTxt = text
    if ESP.settings.ShowDistance then
        local distanceNum = getDistanceStuff(part)
        finalTxt = text .. " [" .. distanceNum .. "m]"
    end
    
    labelThing.Text = finalTxt
    labelThing.Color = color
    labelThing.Size = ESP.settings.TextSize
    labelThing.Outline = true
    labelThing.Center = true
    labelThing.Visible = false
    labelThing.Font = 2
    
    local espData = {
        label = labelThing,
        part = part,
        text = text,
        color = color
    }
    
    table.insert(ESP.objects[espType], espData)
    return espData
end

local function updateLabelsLoop()
    for espType, objects in pairs(ESP.objects) do
        if ESP.settings[espType] then
            for i = #objects, 1, -1 do
                local espData = objects[i]
                pcall(function()
                    if espData.part and espData.part.Parent then
                        local pos, onScreen = WTS(espData.part.Position)
                        if onScreen then
                            local finalTxt = espData.text
                            if ESP.settings.ShowDistance then
                                local distanceNum = getDistanceStuff(espData.part)
                                finalTxt = espData.text .. " [" .. distanceNum .. "m]"
                            end
                            espData.label.Text = finalTxt
                            espData.label.Size = ESP.settings.TextSize
                            espData.label.Position = pos
                            espData.label.Visible = true
                        else
                            espData.label.Visible = false
                        end
                    else
                        espData.label:Remove()
                        table.remove(objects, i)
                    end
                end)
            end
        else
            for i = #objects, 1, -1 do
                objects[i].label:Remove()
                table.remove(objects, i)
            end
        end
    end
end

function ESP:clearESP(espType)
    for i = #self.objects[espType], 1, -1 do
        self.objects[espType][i].label:Remove()
        table.remove(self.objects[espType], i)
    end
end

function ESP:updateMonESP()
    self:clearESP("Mon")
    if not self.settings.Mon then return end
    
    for _, npc in pairs(workspace.NPCs:GetChildren()) do
        if not npc:FindFirstChild("ForceField") and npc:FindFirstChild("HumanoidRootPart") then
            makeESPLabel(npc.HumanoidRootPart, npc.Name, Color3.fromRGB(255, 0, 0), "Mon")
        end
    end
end

function ESP:updateFruitESP()
    self:clearESP("Fruit")
    if not self.settings.Fruit then return end
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:FindFirstChild("FruitModel") then
            local espPart = obj:FindFirstChild("Handle") or 
                           obj:FindFirstChild("HumanoidRootPart") or 
                           obj:FindFirstChildOfClass("Part")
            
            if espPart then
                makeESPLabel(espPart, obj.Name, Color3.fromRGB(255, 165, 0), "Fruit")
            end
        end
    end
end

function ESP:updatePeliBagESP()
    self:clearESP("PeliBag")
    if not self.settings.PeliBag then return end
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "PeliBag" and obj:FindFirstChild("am") then
            local espPart = obj:FindFirstChild("Handle") or 
                           obj:FindFirstChild("HumanoidRootPart") or 
                           obj:FindFirstChildOfClass("Part")
            
            if espPart then
                local bagName = "PeliBag"
                if self.settings.ShowPeliBagAmount and obj.am.Value then
                    bagName = "PeliBag [" .. obj.am.Value .. "]"
                end
                makeESPLabel(espPart, bagName, Color3.fromRGB(255, 255, 0), "PeliBag")
            end
        end
    end
end

function ESP:updateChestESP()
    self:clearESP("Chest")
    if not self.settings.Chest then return end
    
    for _, chest in pairs(workspace.Env:GetChildren()) do
        if chest:FindFirstChild("ProximityPrompt") then
            makeESPLabel(chest, "Chest", Color3.fromRGB(255, 255, 0), "Chest")
        end
    end
end

function ESP:updateQuestESP()
    self:clearESP("Quest")
    if not self.settings.Quest then return end
    
    for _, npc in pairs(workspace.NPCs:GetChildren()) do
        if npc:FindFirstChild("ForceField") and npc:FindFirstChild("HumanoidRootPart") then
            makeESPLabel(npc.HumanoidRootPart, npc.Name .. " [Quest]", Color3.fromRGB(0, 255, 0), "Quest")
        end
    end
end

function ESP:updatePlayerESP()
    self:clearESP("Player")
    if not self.settings.Player then return end
    
    for _, player in pairs(workspace.PlayerCharacters:GetChildren()) do
        if player:FindFirstChild("Humanoid") and player.Name ~= plr.Name and player:FindFirstChild("HumanoidRootPart") then
            local playerObj = game.Players:FindFirstChild(player.Name)
            local displayName = player.Name
            
            if playerObj then
                if self.settings.PlayerNameType == "DisplayName" then
                    displayName = playerObj.DisplayName
                else
                    displayName = playerObj.Name
                end
            end
            
            makeESPLabel(player.HumanoidRootPart, displayName, Color3.fromRGB(0, 255, 255), "Player")
        end
    end
end

function ESP:refreshAllESP()
    if self.settings.Mon then self:updateMonESP() end
    if self.settings.Fruit then self:updateFruitESP() end
    if self.settings.PeliBag then self:updatePeliBagESP() end
    if self.settings.Chest then self:updateChestESP() end
    if self.settings.Quest then self:updateQuestESP() end
    if self.settings.Player then self:updatePlayerESP() end
end

function ESP:clearAllESP()
    for espType, _ in pairs(self.objects) do
        self:clearESP(espType)
    end
end

function ESP:createTab(window)
    local VisualTab = window:DrawTab({
        Name = "Visual ESP",
        Icon = "eye",
        EnableScrolling = true
    })
    
    local VisualSettingsSection = VisualTab:DrawSection({
        Name = "ESP Settings",
        Position = 'left'	
    })

    VisualSettingsSection:AddSlider({
        Name = "ESP Text Size",
        Min = 10,
        Max = 30,
        Default = 12,
        Round = 0,
        Callback = function(val)
            ESP.settings.TextSize = val
            for _, espType in pairs(ESP.objects) do
                for _, espData in pairs(espType) do
                    espData.label.Size = val
                end
            end
        end
    })

    VisualSettingsSection:AddToggle({
        Name = "Show Distance",
        Default = true,
        Callback = function(val)
            ESP.settings.ShowDistance = val
        end
    })

    VisualSettingsSection:AddToggle({
        Name = "Show PeliBag Amount",
        Default = true,
        Callback = function(val)
            ESP.settings.ShowPeliBagAmount = val
            if ESP.settings.PeliBag then
                ESP:updatePeliBagESP()
            end
        end
    })

    VisualSettingsSection:AddDropdown({
        Name = "Player Name Type",
        Default = "DisplayName",
        Values = {"DisplayName", "Username"},
        Callback = function(val)
            ESP.settings.PlayerNameType = val
            if ESP.settings.Player then
                ESP:updatePlayerESP()
            end
        end
    })

    local ESPTypesSection = VisualTab:DrawSection({
        Name = "ESP Types",
        Position = 'right'
    })

    ESPTypesSection:AddToggle({
        Name = "Monster ESP",
        Default = false,
        Callback = function(val)
            ESP.settings.Mon = val
            ESP:updateMonESP()
        end
    })

    ESPTypesSection:AddToggle({
        Name = "Fruit ESP",
        Default = false,
        Callback = function(val)
            ESP.settings.Fruit = val
            ESP:updateFruitESP()
        end
    })

    ESPTypesSection:AddToggle({
        Name = "PeliBag ESP",
        Default = false,
        Callback = function(val)
            ESP.settings.PeliBag = val
            ESP:updatePeliBagESP()
        end
    })

    ESPTypesSection:AddToggle({
        Name = "Chest ESP",
        Default = false,
        Callback = function(val)
            ESP.settings.Chest = val
            ESP:updateChestESP()
        end
    })

    ESPTypesSection:AddToggle({
        Name = "Quest ESP",
        Default = false,
        Callback = function(val)
            ESP.settings.Quest = val
            ESP:updateQuestESP()
        end
    })

    ESPTypesSection:AddToggle({
        Name = "Player ESP", 
        Default = false,
        Callback = function(val)
            ESP.settings.Player = val
            ESP:updatePlayerESP()
        end
    })

    local ActionsSection = VisualTab:DrawSection({
        Name = "ESP Actions",
        Position = 'left'
    })

    ActionsSection:AddButton({
        Name = "Refresh All ESP",
        Callback = function()
            ESP:refreshAllESP()
            
            if notifierRef then
                notifierRef.new({
                    Title = "ESP System",
                    Content = "All ESP refreshed successfully!",
                    Duration = 3,
                    Icon = "rbxassetid://120245531583106"
                })
            end
        end
    })

    ActionsSection:AddButton({
        Name = "Clear All ESP",
        Callback = function()
            ESP:clearAllESP()
            
            if notifierRef then
                notifierRef.new({
                    Title = "ESP System",
                    Content = "All ESP cleared!",
                    Duration = 3,
                    Icon = "rbxassetid://120245531583106"
                })
            end
        end
    })
    
    return VisualTab
end

function ESP:startUpdates()
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    updateConnection = runService.Stepped:Connect(function()
        updateLabelsLoop()
    end)
    
    eventConnections[#eventConnections + 1] = workspace.NPCs.ChildAdded:Connect(function()
        task.wait()
        if ESP.settings.Mon then ESP:updateMonESP() end
        if ESP.settings.Quest then ESP:updateQuestESP() end
    end)

    eventConnections[#eventConnections + 1] = workspace.ChildAdded:Connect(function(obj)
        if obj.ClassName == "Tool" and obj:FindFirstChild("FruitModel") then
            task.wait()
            if ESP.settings.Fruit then ESP:updateFruitESP() end
        end
        if obj.Name == "PeliBag" and obj:FindFirstChild("am") then
            task.wait()
            if ESP.settings.PeliBag then ESP:updatePeliBagESP() end
        end
    end)

    eventConnections[#eventConnections + 1] = workspace.PlayerCharacters.ChildAdded:Connect(function()
        task.wait()
        if ESP.settings.Player then ESP:updatePlayerESP() end
    end)

    eventConnections[#eventConnections + 1] = workspace.Env.ChildAdded:Connect(function()
        task.wait()
        if ESP.settings.Chest then ESP:updateChestESP() end
    end)
end

function ESP:stopUpdates()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    for _, conn in pairs(eventConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    eventConnections = {}
end

function ESP:destroy()
    self:stopUpdates()
    self:clearAllESP()
end

return ESP
