local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")


-- ==================== CONFIGURATION ====================
local ESP_CONFIG = {
    COLOR_NEAR = Color3.fromRGB(0, 255, 0),
    COLOR_MID = Color3.fromRGB(255, 165, 0),
    COLOR_FAR = Color3.fromRGB(255, 0, 0),
    COLOR_FRIENDLY = Color3.fromRGB(0, 150, 255),
    COLOR_ENEMY = Color3.fromRGB(255, 50, 50),
    TEAM_CHECK = true,
    SHOW_NAMES = true,
    SHOW_DISTANCE = true,
    SHOW_HEALTH = true,
    SHOW_HEALTH_BAR = true,
    SHOW_BOXES = true,
    SHOW_TRACERS = true,
    SHOW_HEAD_DOTS = true,
    SHOW_VIEW_ANGLES = true,
    SHOW_WEAPONS = true,
    SHOW_STATUS = true,
    MAX_DISTANCE = 1000,
    TEXT_SIZE = 16,
    TEXT_OUTLINE = true,
    BOX_TRANSPARENCY = 0.5,
    TRACER_TRANSPARENCY = 0.5,
    UPDATE_RATE = 0.1,
    FONT = Enum.Font.GothamBold,
    GLOW_EFFECT = true,
    SMOOTH_ANIMATIONS = true,
    VISIBILITY_CHECK = true
}


-- ==================== VARIABLES ====================
local localPlayer = Players.LocalPlayer
local espEnabled = false
local espObjects = {}
local espUpdateConnection = nil
local settingsWindow = nil
local mainUI = nil
local dragging = false
local dragInput = nil
local dragStart = nil
local dragPos = nil
local uiVisible = true
local themeColor = Color3.fromRGB(0, 170, 255) -- Primary theme color
local accentColor = Color3.fromRGB(255, 70, 70) -- Secondary accent color
local uiTransparency = 0.05 -- Lower = more solid
local cornerRadius = 8
local animationSpeed = 0.2
local uiScale = 1.0 -- UI scale multiplier


-- Initialize local player character
local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local localHead = localCharacter:WaitForChild("Head")
local localHumanoid = localCharacter:WaitForChild("Humanoid")


-- ==================== UTILITY FUNCTIONS ====================
local function calculateDistance(position)
    return (localHead.Position - position).Magnitude
end


local function isPlayerFriendly(player)
    if not ESP_CONFIG.TEAM_CHECK then return false end
    return player.Team == localPlayer.Team
end


local function getColorByDistance(distance, isFriendly)
    if isFriendly then
        return ESP_CONFIG.COLOR_FRIENDLY
    end


if distance < 20 then 
    return ESP_CONFIG.COLOR_NEAR 
elseif distance < 50 then 
    return ESP_CONFIG.COLOR_MID 
else 
    return ESP_CONFIG.COLOR_FAR 
end

end


local function getTeamColor(player)
    if ESP_CONFIG.TEAM_CHECK and player.Team then
        return isPlayerFriendly(player) and ESP_CONFIG.COLOR_FRIENDLY or ESP_CONFIG.COLOR_ENEMY
    end
    return getColorByDistance(calculateDistance(player.Character and player.Character:FindFirstChild("Head") and player.Character.Head.Position or Vector3.new(0, 0, 0)), false)
end


local function createESPObject(player)
    if espObjects[player] then return espObjects[player] end


local espObject = { 
    player = player, 
    nameLabel = nil, 
    distanceLabel = nil, 
    healthLabel = nil, 
    healthBar = nil, 
    healthBarBackground = nil, 
    box = nil, 
    tracer = nil, 
    headDot = nil, 
    viewAngle = nil, 
    weaponLabel = nil, 
    statusLabel = nil, 
    connections = {} 
}

espObjects[player] = espObject 
return espObject 

end


local function removeESPObject(player)
    if not espObjects[player] then return end


local espObject = espObjects[player] 
if espObject.nameLabel then espObject.nameLabel:Remove() end 
if espObject.distanceLabel then espObject.distanceLabel:Remove() end 
if espObject.healthLabel then espObject.healthLabel:Remove() end 
if espObject.healthBar then espObject.healthBar:Remove() end 
if espObject.healthBarBackground then espObject.healthBarBackground:Remove() end 
if espObject.box then espObject.box:Remove() end 
if espObject.tracer then espObject.tracer:Remove() end 
if espObject.headDot then espObject.headDot:Remove() end 
if espObject.viewAngle then espObject.viewAngle:Remove() end 
if espObject.weaponLabel then espObject.weaponLabel:Remove() end 
if espObject.statusLabel then espObject.statusLabel:Remove() end 

for _, connection in pairs(espObject.connections) do 
    connection:Disconnect() 
end 

espObjects[player] = nil 

end


local function updateESP()
    if not espEnabled then return end


-- Update player ESP
for player, espObject in pairs(espObjects) do 
    if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then 
        local character = player.Character 
        local head = character.Head 
        local humanoid = character.Humanoid 
        local rootPart = character.HumanoidRootPart 
        local distance = calculateDistance(head.Position) 
        
        if distance > ESP_CONFIG.MAX_DISTANCE then 
            if espObject.nameLabel then espObject.nameLabel.Visible = false end 
            if espObject.distanceLabel then espObject.distanceLabel.Visible = false end 
            if espObject.healthLabel then espObject.healthLabel.Visible = false end 
            if espObject.healthBar then espObject.healthBar.Visible = false end 
            if espObject.healthBarBackground then espObject.healthBarBackground.Visible = false end 
            if espObject.box then espObject.box.Visible = false end 
            if espObject.tracer then espObject.tracer.Visible = false end 
            if espObject.headDot then espObject.headDot.Visible = false end 
            if espObject.viewAngle then espObject.viewAngle.Visible = false end 
            if espObject.weaponLabel then espObject.weaponLabel.Visible = false end 
            if espObject.statusLabel then espObject.statusLabel.Visible = false end 
            continue 
        end 
        
        local isFriendly = isPlayerFriendly(player) 
        local color = getTeamColor(player) 
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position) 
        
        if onScreen then 
            -- Name Label
            if ESP_CONFIG.SHOW_NAMES then 
                if not espObject.nameLabel then 
                    espObject.nameLabel = Drawing.new("Text")
                    espObject.nameLabel.ZIndex = 1
                    espObject.nameLabel.Center = true
                    espObject.nameLabel.Outline = ESP_CONFIG.TEXT_OUTLINE
                    espObject.nameLabel.Size = ESP_CONFIG.TEXT_SIZE
                    espObject.nameLabel.Font = ESP_CONFIG.FONT
                end
                espObject.nameLabel.Visible = true
                espObject.nameLabel.Text = player.Name
                espObject.nameLabel.Color = color
                espObject.nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 50)
            elseif espObject.nameLabel then 
                espObject.nameLabel.Visible = false 
            end 
            
            -- Distance Label
            if ESP_CONFIG.SHOW_DISTANCE then 
                if not espObject.distanceLabel then 
                    espObject.distanceLabel = Drawing.new("Text")
                    espObject.distanceLabel.ZIndex = 1
                    espObject.distanceLabel.Center = true
                    espObject.distanceLabel.Outline = ESP_CONFIG.TEXT_OUTLINE
                    espObject.distanceLabel.Size = ESP_CONFIG.TEXT_SIZE - 2
                    espObject.distanceLabel.Font = ESP_CONFIG.FONT
                end
                espObject.distanceLabel.Visible = true
                espObject.distanceLabel.Text = string.format("[%d studs]", distance)
                espObject.distanceLabel.Color = color
                espObject.distanceLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
            elseif espObject.distanceLabel then 
                espObject.distanceLabel.Visible = false 
            end 
            
            -- Health Label
            if ESP_CONFIG.SHOW_HEALTH then 
                if not espObject.healthLabel then 
                    espObject.healthLabel = Drawing.new("Text")
                    espObject.healthLabel.ZIndex = 1
                    espObject.healthLabel.Center = true
                    espObject.healthLabel.Outline = ESP_CONFIG.TEXT_OUTLINE
                    espObject.healthLabel.Size = ESP_CONFIG.TEXT_SIZE - 2
                    espObject.healthLabel.Font = ESP_CONFIG.FONT
                end
                espObject.healthLabel.Visible = true
                espObject.healthLabel.Text = string.format("HP: %d/%d", humanoid.Health, humanoid.MaxHealth)
                espObject.healthLabel.Color = Color3.fromRGB(255, 255, 255)
                espObject.healthLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 10)
            elseif espObject.healthLabel then 
                espObject.healthLabel.Visible = false 
            end 
            
            -- Health Bar
            if ESP_CONFIG.SHOW_HEALTH_BAR then 
                local healthPercentage = humanoid.Health / humanoid.MaxHealth 
                if not espObject.healthBarBackground then 
                    espObject.healthBarBackground = Drawing.new("Square")
                    espObject.healthBarBackground.Thickness = 1
                    espObject.healthBarBackground.Filled = true
                    espObject.healthBarBackground.ZIndex = 0
                end 
                if not espObject.healthBar then 
                    espObject.healthBar = Drawing.new("Square")
                    espObject.healthBar.Thickness = 1
                    espObject.healthBar.Filled = true
                    espObject.healthBar.ZIndex = 1
                end 
                
                local rootPos = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position) 
                local rootSize = rootPart.Size / 2 
                local topFrontLeft = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position + Vector3.new(-rootSize.X, rootSize.Y, -rootSize.Z)) 
                local bottomBackRight = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position + Vector3.new(rootSize.X, -rootSize.Y, rootSize.Z)) 
                local boxWidth = math.abs(topFrontLeft.X - bottomBackRight.X) 
                local boxHeight = math.abs(topFrontLeft.Y - bottomBackRight.Y) 
                local boxX = math.min(topFrontLeft.X, bottomBackRight.X) 
                local boxY = math.min(topFrontLeft.Y, bottomBackRight.Y) 
                
                espObject.healthBarBackground.Visible = true
                espObject.healthBarBackground.Color = Color3.fromRGB(50, 50, 50)
                espObject.healthBarBackground.Size = Vector2.new(4, boxHeight + 4)
                espObject.healthBarBackground.Position = Vector2.new(boxX - 8, boxY - 2)
                
                espObject.healthBar.Visible = true
                espObject.healthBar.Color = Color3.fromRGB(255 - 255 * healthPercentage, 255 * healthPercentage, 0)
                espObject.healthBar.Size = Vector2.new(4, (boxHeight + 4) * healthPercentage)
                espObject.healthBar.Position = Vector2.new(boxX - 8, boxY - 2 + (boxHeight + 4) * (1 - healthPercentage))
            else 
                if espObject.healthBar then espObject.healthBar.Visible = false end 
                if espObject.healthBarBackground then espObject.healthBarBackground.Visible = false end 
            end 
            
            -- Box ESP
            if ESP_CONFIG.SHOW_BOXES then 
                if not espObject.box then 
                    espObject.box = Drawing.new("Square")
                    espObject.box.Thickness = 2
                    espObject.box.Filled = false
                    espObject.box.ZIndex = 2
                end 
                
                local rootPos = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position) 
                local rootSize = rootPart.Size / 2 
                local topFrontLeft = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position + Vector3.new(-rootSize.X, rootSize.Y, -rootSize.Z)) 
                local bottomBackRight = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position + Vector3.new(rootSize.X, -rootSize.Y, rootSize.Z)) 
                
                espObject.box.Visible = true
                espObject.box.Color = color
                espObject.box.Size = Vector2.new(math.abs(topFrontLeft.X - bottomBackRight.X), math.abs(topFrontLeft.Y - bottomBackRight.Y))
                espObject.box.Position = Vector2.new(
                    math.min(topFrontLeft.X, bottomBackRight.X),
                    math.min(topFrontLeft.Y, bottomBackRight.Y)
                )
            elseif espObject.box then 
                espObject.box.Visible = false 
            end 
            
            -- Tracer
            if ESP_CONFIG.SHOW_TRACERS then 
                if not espObject.tracer then 
                    espObject.tracer = Drawing.new("Line")
                    espObject.tracer.Thickness = 1
                    espObject.tracer.ZIndex = 3
                end 
                
                espObject.tracer.Visible = true
                espObject.tracer.Color = Color3.new(color.R, color.G, color.B)
                espObject.tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                espObject.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            elseif espObject.tracer then 
                espObject.tracer.Visible = false 
            end 
            
            -- Head Dot
            if ESP_CONFIG.SHOW_HEAD_DOTS then 
                if not espObject.headDot then 
                    espObject.headDot = Drawing.new("Circle")
                    espObject.headDot.Thickness = 1
                    espObject.headDot.Filled = true
                    espObject.headDot.ZIndex = 4
                    espObject.headDot.NumSides = 12
                    espObject.headDot.Radius = 4
                end 
                
                espObject.headDot.Visible = true
                espObject.headDot.Color = color
                espObject.headDot.Position = Vector2.new(screenPos.X, screenPos.Y)
            elseif espObject.headDot then 
                espObject.headDot.Visible = false 
            end 
            
            -- View Angle
            if ESP_CONFIG.SHOW_VIEW_ANGLES then 
                if not espObject.viewAngle then 
                    espObject.viewAngle = Drawing.new("Line")
                    espObject.viewAngle.Thickness = 2
                    espObject.viewAngle.ZIndex = 5
                end 
                
                local lookVector = rootPart.CFrame.LookVector * 5 
                local lookEnd = head.Position + lookVector 
                local lookScreenPos = workspace.CurrentCamera:WorldToViewportPoint(lookEnd) 
                
                if lookScreenPos.Z > 0 then 
                    espObject.viewAngle.Visible = true
                    espObject.viewAngle.Color = color
                    espObject.viewAngle.From = Vector2.new(screenPos.X, screenPos.Y)
                    espObject.viewAngle.To = Vector2.new(lookScreenPos.X, lookScreenPos.Y)
                else 
                    espObject.viewAngle.Visible = false 
                end 
            elseif espObject.viewAngle then 
                espObject.viewAngle.Visible = false 
            end 
            
            -- Weapon Label
            if ESP_CONFIG.SHOW_WEAPONS then 
                local tool = character:FindFirstChildOfClass("Tool") 
                if tool then 
                    if not espObject.weaponLabel then 
                        espObject.weaponLabel = Drawing.new("Text")
                        espObject.weaponLabel.ZIndex = 1
                        espObject.weaponLabel.Center = true
                        espObject.weaponLabel.Outline = ESP_CONFIG.TEXT_OUTLINE
                        espObject.weaponLabel.Size = ESP_CONFIG.TEXT_SIZE - 2
                        espObject.weaponLabel.Font = ESP_CONFIG.FONT
                    end 
                    
                    espObject.weaponLabel.Visible = true
                    espObject.weaponLabel.Text = "[" .. tool.Name .. "]"
                    espObject.weaponLabel.Color = Color3.fromRGB(255, 255, 100)
                    espObject.weaponLabel.Position = Vector2.new(screenPos.X, screenPos.Y + 10)
                elseif espObject.weaponLabel then 
                    espObject.weaponLabel.Visible = false 
                end 
            elseif espObject.weaponLabel then 
                espObject.weaponLabel.Visible = false 
            end 
            
            -- Status Label
            if ESP_CONFIG.SHOW_STATUS then 
                local status = "" 
                if humanoid.Sit then 
                    status = "Sitting" 
                elseif humanoid.Jump then 
                    status = "Jumping" 
                elseif humanoid.MoveDirection.Magnitude > 0 then 
                    status = "Moving" 
                else 
                    status = "Idle" 
                end 
                
                if not espObject.statusLabel then 
                    espObject.statusLabel = Drawing.new("Text")
                    espObject.statusLabel.ZIndex = 1
                    espObject.statusLabel.Center = true
                    espObject.statusLabel.Outline = ESP_CONFIG.TEXT_OUTLINE
                    espObject.statusLabel.Size = ESP_CONFIG.TEXT_SIZE - 2
                    espObject.statusLabel.Font = ESP_CONFIG.FONT
                end 
                
                espObject.statusLabel.Visible = true
                espObject.statusLabel.Text = status
                espObject.statusLabel.Color = Color3.fromRGB(200, 200, 200)
                espObject.statusLabel.Position = Vector2.new(screenPos.X, screenPos.Y + 30)
            elseif espObject.statusLabel then 
                espObject.statusLabel.Visible = false 
            end 
        else 
            if espObject.nameLabel then espObject.nameLabel.Visible = false end 
            if espObject.distanceLabel then espObject.distanceLabel.Visible = false end 
            if espObject.healthLabel then espObject.healthLabel.Visible = false end 
            if espObject.healthBar then espObject.healthBar.Visible = false end 
            if espObject.healthBarBackground then espObject.healthBarBackground.Visible = false end 
            if espObject.box then espObject.box.Visible = false end 
            if espObject.tracer then espObject.tracer.Visible = false end 
            if espObject.headDot then espObject.headDot.Visible = false end 
            if espObject.viewAngle then espObject.viewAngle.Visible = false end 
            if espObject.weaponLabel then espObject.weaponLabel.Visible = false end 
            if espObject.statusLabel then espObject.statusLabel.Visible = false end 
        end 
    else 
        removeESPObject(player) 
    end 
end 

end


local function toggleESP()
    espEnabled = not espEnabled


if espEnabled then 
    -- Create ESP objects for all players
    for _, player in ipairs(Players:GetPlayers()) do 
        if player ~= localPlayer then 
            createESPObject(player) 
        end 
    end 
    
    -- Start update loop
    if espUpdateConnection then 
        espUpdateConnection:Disconnect() 
    end 
    espUpdateConnection = RunService.RenderStepped:Connect(updateESP) 
else 
    -- Remove all ESP objects
    for player, _ in pairs(espObjects) do 
        removeESPObject(player) 
    end 
    
    -- Disconnect update loop
    if espUpdateConnection then 
        espUpdateConnection:Disconnect() 
        espUpdateConnection = nil 
    end 
end 

return espEnabled 

end


-- ==================== UI COMPONENTS ====================


-- Create a shadow effect for UI elements
local function createShadow(parent, size, position, radius)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = position or UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = size or UDim2.new(1, 8, 1, 8)
    shadow.ZIndex = 0
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.SliceScale = 0.1
    shadow.Parent = parent


return shadow

end


-- Create a modern toggle switch with animation
local function createToggleSwitch(parent, name, defaultValue, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = name .. "Toggle"
    toggleFrame.Size = UDim2.new(1, 0, 0, 36)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent


local toggleLabel = Instance.new("TextLabel") 
toggleLabel.Name = "Label" 
toggleLabel.Size = UDim2.new(0.7, -10, 1, 0) 
toggleLabel.Position = UDim2.new(0, 5, 0, 0)
toggleLabel.BackgroundTransparency = 1 
toggleLabel.Text = name 
toggleLabel.TextColor3 = Color3.fromRGB(230, 230, 230) 
toggleLabel.TextSize = 14 
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left 
toggleLabel.Font = Enum.Font.GothamSemibold 
toggleLabel.Parent = toggleFrame 

-- Modern toggle switch background
local toggleBackground = Instance.new("Frame")
toggleBackground.Name = "Background"
toggleBackground.Size = UDim2.new(0, 50, 0, 24)
toggleBackground.Position = UDim2.new(1, -55, 0.5, -12)
toggleBackground.BackgroundColor3 = defaultValue and themeColor or Color3.fromRGB(80, 80, 80)
toggleBackground.Parent = toggleFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleBackground

-- Toggle knob
local toggleKnob = Instance.new("Frame")
toggleKnob.Name = "Knob"
toggleKnob.Size = UDim2.new(0, 18, 0, 18)
toggleKnob.Position = UDim2.new(defaultValue and 1 or 0, defaultValue and -22 or 3, 0.5, -9)
toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
toggleKnob.Parent = toggleBackground

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = toggleKnob

-- Shadow for knob
createShadow(toggleKnob, UDim2.new(1, 6, 1, 6), UDim2.new(0.5, 0, 0.5, 0))

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Name = "Status"
statusText.Size = UDim2.new(0, 30, 0, 20)
statusText.Position = UDim2.new(1, -90, 0.5, -10)
statusText.BackgroundTransparency = 1
statusText.Text = defaultValue and "ON" or "OFF"
statusText.TextColor3 = defaultValue and themeColor or Color3.fromRGB(180, 180, 180)
statusText.TextSize = 12
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Right
statusText.Parent = toggleFrame

-- Click detection for the entire frame
local button = Instance.new("TextButton")
button.Name = "Button"
button.Size = UDim2.new(0, 80, 1, 0)
button.Position = UDim2.new(1, -80, 0, 0)
button.BackgroundTransparency = 1
button.Text = ""
button.Parent = toggleFrame

local isOn = defaultValue

button.MouseButton1Click:Connect(function()
    isOn = not isOn
    
    -- Animate the toggle
    local knobPosition = isOn and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    local bgColor = isOn and themeColor or Color3.fromRGB(80, 80, 80)
    local textColor = isOn and themeColor or Color3.fromRGB(180, 180, 180)
    
    TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = knobPosition}):Play()
    TweenService:Create(toggleBackground, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = bgColor}):Play()
    TweenService:Create(statusText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = textColor}):Play()
    
    statusText.Text = isOn and "ON" or "OFF"
    
    if callback then
        callback(isOn)
    end
end)

return toggleFrame

end


-- Create a color picker button
local function createColorButton(parent, name, defaultColor, callback)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = name .. "Color"
    buttonFrame.Size = UDim2.new(1, 0, 0, 36)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = parent


local buttonLabel = Instance.new("TextLabel")
buttonLabel.Name = "Label"
buttonLabel.Size = UDim2.new(0.6, -10, 1, 0)
buttonLabel.Position = UDim2.new(0, 5, 0, 0)
buttonLabel.BackgroundTransparency = 1
buttonLabel.Text = name
buttonLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
buttonLabel.TextSize = 14
buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
buttonLabel.Font = Enum.Font.GothamSemibold
buttonLabel.Parent = buttonFrame

-- Color display box with gradient effect
local colorBox = Instance.new("Frame")
colorBox.Name = "ColorBox"
colorBox.Size = UDim2.new(0, 60, 0, 24)
colorBox.Position = UDim2.new(1, -65, 0.5, -12)
colorBox.BackgroundColor3 = defaultColor
colorBox.BorderSizePixel = 0
colorBox.Parent = buttonFrame

local colorCorner = Instance.new("UICorner")
colorCorner.CornerRadius = UDim.new(0, 6)
colorCorner.Parent = colorBox

-- Add gradient overlay
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 0.2)
})
gradient.Parent = colorBox

-- Add shadow
createShadow(colorBox, UDim2.new(1, 8, 1, 8))

-- Click detection
local button = Instance.new("TextButton")
button.Name = "Button"
button.Size = UDim2.new(0, 60, 0, 24)
button.Position = UDim2.new(1, -65, 0.5, -12)
button.BackgroundTransparency = 1
button.Text = ""
button.Parent = buttonFrame

-- Hover effect
button.MouseEnter:Connect(function()
    TweenService:Create(colorBox, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 26)}):Play()
    TweenService:Create(colorBox, TweenInfo.new(0.2), {Position = UDim2.new(1, -67, 0.5, -13)}):Play()
    TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 26)}):Play()
    TweenService:Create(button, TweenInfo.new(0.2), {Position = UDim2.new(1, -67, 0.5, -13)}):Play()
end)

button.MouseLeave:Connect(function()
    TweenService:Create(colorBox, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 24)}):Play()
    TweenService:Create(colorBox, TweenInfo.new(0.2), {Position = UDim2.new(1, -65, 0.5, -12)}):Play()
    TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 24)}):Play()
    TweenService:Create(button, TweenInfo.new(0.2), {Position = UDim2.new(1, -65, 0.5, -12)}):Play()
end)

button.MouseButton1Click:Connect(function()
    -- Here you would implement a color picker UI
    -- For now, we'll just cycle through some preset colors as an example
    local colors = {
        Color3.fromRGB(255, 0, 0),   -- Red
        Color3.fromRGB(255, 165, 0), -- Orange
        Color3.fromRGB(255, 255, 0), -- Yellow
        Color3.fromRGB(0, 255, 0),   -- Green
        Color3.fromRGB(0, 170, 255), -- Blue
        Color3.fromRGB(170, 0, 255), -- Purple
        Color3.fromRGB(255, 0, 255)  -- Pink
    }
    
    -- Find current color index
    local currentIndex = 1
    for i, color in ipairs(colors) do
        if color == defaultColor then
            currentIndex = i
            break
        end
    end
    
    -- Get next color
    local nextIndex = currentIndex % #colors + 1
    local nextColor = colors[nextIndex]
    
    -- Update color
    defaultColor = nextColor
    TweenService:Create(colorBox, TweenInfo.new(0.3), {BackgroundColor3 = nextColor}):Play()
    
    if callback then
        callback(nextColor)
    end
end)

return buttonFrame

end


-- Create a slider control
local function createSlider(parent, name, min, max, default, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = name .. "Slider"
    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent


local sliderLabel = Instance.new("TextLabel")
sliderLabel.Name = "Label"
sliderLabel.Size = UDim2.new(1, -10, 0, 20)
sliderLabel.Position = UDim2.new(0, 5, 0, 0)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = name
sliderLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
sliderLabel.TextSize = 14
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Font = Enum.Font.GothamSemibold
sliderLabel.Parent = sliderFrame

-- Value display
local valueLabel = Instance.new("TextLabel")
valueLabel.Name = "Value"
valueLabel.Size = UDim2.new(0, 40, 0, 20)
valueLabel.Position = UDim2.new(1, -45, 0, 0)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = tostring(default)
valueLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
valueLabel.TextSize = 14
valueLabel.TextXAlignment = Enum.TextXAlignment.Right
valueLabel.Font = Enum.Font.GothamMono
valueLabel.Parent = sliderFrame

-- Slider background
local sliderBg = Instance.new("Frame")
sliderBg.Name = "Background"
sliderBg.Size = UDim2.new(1, -10, 0, 8)
sliderBg.Position = UDim2.new(0, 5, 0, 30)
sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = sliderFrame

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = sliderBg

-- Slider fill
local sliderFill = Instance.new("Frame")
sliderFill.Name = "Fill"
local fillPercent = (default - min) / (max - min)
sliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
sliderFill.BackgroundColor3 = themeColor
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = sliderFill

-- Slider knob
local sliderKnob = Instance.new("Frame")
sliderKnob.Name = "Knob"
sliderKnob.Size = UDim2.new(0, 16, 0, 16)
sliderKnob.Position = UDim2.new(fillPercent, -8, 0.5, -8)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.Parent = sliderBg

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

-- Shadow for knob
createShadow(sliderKnob, UDim2.new(1, 6, 1, 6))

-- Slider interaction
local isDragging = false
local currentValue = default

local function updateSlider(input)
    local pos = input.Position.X
    local relativePos = math.clamp((pos - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
    local value = min + (max - min) * relativePos
    
    -- Round to nearest integer if min and max are integers
    if math.floor(min) == min and math.floor(max) == max then
        value = math.floor(value + 0.5)
    else
        -- Round to 2 decimal places for floating point
        value = math.floor(value * 100 + 0.5) / 100
    end
    
    currentValue = value
    valueLabel.Text = tostring(value)
    
    -- Update slider visuals
    sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
    sliderKnob.Position = UDim2.new(relativePos, -8, 0.5, -8)
    
    if callback then
        callback(value)
    end
end

sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        updateSlider(input)
    end
end)

sliderBg.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider(input)
    end
end)

return sliderFrame, function() return currentValue end

end


-- Create a section title with animation
local function createSectionTitle(text, parent)
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Name = text .. "Section"
    sectionFrame.Size = UDim2.new(1, 0, 0, 35)
    sectionFrame.BackgroundTransparency = 1
    sectionFrame.Parent = parent


local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = text
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = sectionFrame

local line = Instance.new("Frame")
line.Name = "Line"
line.Size = UDim2.new(0, 0, 0, 2)
line.Position = UDim2.new(0, 0, 1, -2)
line.BackgroundColor3 = themeColor
line.BorderSizePixel = 0
line.Parent = sectionFrame

-- Animate line
TweenService:Create(line, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)}):Play()

return sectionFrame

end


-- Create a button with hover and click effects
local function createButton(parent, text, color, callback)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = text .. "Button"
    buttonFrame.Size = UDim2.new(1, 0, 0, 40)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = parent


local button = Instance.new("TextButton")
button.Name = "Button"
button.Size = UDim2.new(1, -20, 1, -10)
button.Position = UDim2.new(0, 10, 0, 5)
button.BackgroundColor3 = color
button.Text = text
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = buttonFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

-- Add gradient
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 0.2)
})
gradient.Parent = button

-- Add shadow
createShadow(button)

-- Hover and click effects
button.MouseEnter:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(
        math.min(color.R * 1.1, 1),
        math.min(color.G * 1.1, 1),
        math.min(color.B * 1.1, 1)
    )}):Play()
end)

button.MouseLeave:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
end)

button.MouseButton1Down:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -24, 1, -14), Position = UDim2.new(0, 12, 0, 7)}):Play()
end)

button.MouseButton1Up:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -20, 1, -10), Position = UDim2.new(0, 10, 0, 5)}):Play()
    if callback then
        callback()
    end
end)

return buttonFrame

end


-- Create a tab button for tab system
local function createTabButton(parent, text, isActive, callback)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = text .. "Tab"
    tabButton.Size = UDim2.new(1/#parent:GetChildren() + 1, 0, 1, 0)
    tabButton.BackgroundTransparency = isActive and 0 or 0.9
    tabButton.BackgroundColor3 = isActive and themeColor or Color3.fromRGB(60, 60, 65)
    tabButton.Text = text
    tabButton.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    tabButton.TextSize = 14
    tabButton.Font = Enum.Font.GothamBold
    tabButton.Parent = parent


local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.Size = UDim2.new(1, 0, 0, 2)
indicator.Position = UDim2.new(0, 0, 1, -2)
indicator.BackgroundColor3 = themeColor
indicator.BorderSizePixel = 0
indicator.Visible = isActive
indicator.Parent = tabButton

tabButton.MouseButton1Click:Connect(function()
    if callback then
        callback(tabButton)
    end
end)

return tabButton

end


-- Create a notification system
local notificationSystem = {}


function notificationSystem:Init()
    self.container = Instance.new("Frame")
    self.container.Name = "NotificationContainer"
    self.container.Size = UDim2.new(0, 300, 1, 0)
    self.container.Position = UDim2.new(1, -310, 0, 0)
    self.container.BackgroundTransparency = 1
    self.container.Parent = CoreGui:FindFirstChild("ESPProUI") or CoreGui


local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = self.container

self.notifications = {}

end


function notificationSystem:Show(title, message, type, duration)
    type = type or "info" -- info, success, warning, error
    duration = duration or 3


-- Colors based on type
local colors = {
    info = Color3.fromRGB(0, 170, 255),
    success = Color3.fromRGB(0, 180, 120),
    warning = Color3.fromRGB(255, 165, 0),
    error = Color3.fromRGB(255, 50, 50)
}

-- Icons based on type
local icons = {
    info = "rbxassetid://6031071053",
    success = "rbxassetid://6031094670",
    warning = "rbxassetid://6031071057",
    error = "rbxassetid://6031071053"
}

-- Create notification frame
local notification = Instance.new("Frame")
notification.Name = "Notification_" .. HttpService:GenerateGUID(false)
notification.Size = UDim2.new(1, -20, 0, 80)
notification.Position = UDim2.new(1, 0, 1, -90)
notification.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
notification.BackgroundTransparency = 0.1
notification.BorderSizePixel = 0
notification.Parent = self.container

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = notification

-- Add shadow
createShadow(notification)

-- Add color bar
local colorBar = Instance.new("Frame")
colorBar.Name = "ColorBar"
colorBar.Size = UDim2.new(0, 4, 1, 0)
colorBar.BackgroundColor3 = colors[type]
colorBar.BorderSizePixel = 0
colorBar.Parent = notification

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 8)
barCorner.Parent = colorBar

-- Add icon
local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 24, 0, 24)
icon.Position = UDim2.new(0, 14, 0, 10)
icon.BackgroundTransparency = 1
icon.Image = icons[type]
icon.ImageColor3 = colors[type]
icon.Parent = notification

-- Add title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -60, 0, 20)
titleLabel.Position = UDim2.new(0, 45, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = title
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = notification

-- Add message
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.Size = UDim2.new(1, -60, 0, 40)
messageLabel.Position = UDim2.new(0, 45, 0, 30)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = message
messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
messageLabel.TextSize = 14
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextWrapped = true
messageLabel.Parent = notification

-- Add close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 10)
closeButton.BackgroundTransparency = 1
closeButton.Text = "\u00d7"
closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = notification

-- Add progress bar
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(1, 0, 0, 2)
progressBar.Position = UDim2.new(0, 0, 1, -2)
progressBar.BackgroundColor3 = colors[type]
progressBar.BorderSizePixel = 0
progressBar.Parent = notification

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 8)
progressCorner.Parent = progressBar

-- Animation: Slide in
notification.Position = UDim2.new(1, 0, 1, -90)
TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 10, 1, -90)}):Play()

-- Progress bar animation
TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
    TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(1, 0, 1, -90)}):Play()
    wait(0.3)
    notification:Destroy()
end)

-- Auto close after duration
delay(duration, function()
    if notification and notification.Parent then
        TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(1, 0, 1, -90)}):Play()
        wait(0.3)
        if notification and notification.Parent then
            notification:Destroy()
        end
    end
end)

table.insert(self.notifications, notification)
return notification

end


-- Initialize notification system
notificationSystem:Init()


-- Create a modern, professional UI
local function createMainUI()
    if mainUI and mainUI.Parent then
        mainUI.Enabled = not mainUI.Enabled
        uiVisible = mainUI.Enabled
        return
    end


-- Create ScreenGui
local screenGui = Instance.new("ScreenGui") 
screenGui.Name = "ESPProUI" 
screenGui.Parent = CoreGui 
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
screenGui.ResetOnSpawn = false 

-- Main container with blur effect
local mainFrame = Instance.new("Frame") 
mainFrame.Name = "MainFrame" 
mainFrame.Size = UDim2.new(0, 400, 0, 520) 
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -260) 
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35) 
mainFrame.BackgroundTransparency = uiTransparency
mainFrame.BorderSizePixel = 0 
mainFrame.ClipsDescendants = true 
mainFrame.Parent = screenGui 

-- Add blur effect
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 10
blurEffect.Parent = Lighting

-- Add corner radius
local corner = Instance.new("UICorner") 
corner.CornerRadius = UDim.new(0, cornerRadius) 
corner.Parent = mainFrame 

-- Add shadow
createShadow(mainFrame, UDim2.new(1, 20, 1, 20))

-- Header with gradient
local header = Instance.new("Frame") 
header.Name = "Header" 
header.Size = UDim2.new(1, 0, 0, 50) 
header.BackgroundColor3 = Color3.fromRGB(40, 40, 45) 
header.BackgroundTransparency = uiTransparency
header.BorderSizePixel = 0 
header.Parent = mainFrame 

local headerCorner = Instance.new("UICorner") 
headerCorner.CornerRadius = UDim.new(0, cornerRadius) 
headerCorner.Parent = header 

-- Add gradient to header
local headerGradient = Instance.new("UIGradient")
headerGradient.Rotation = 90
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 45))
})
headerGradient.Parent = header

-- Title with icon
local titleIcon = Instance.new("ImageLabel")
titleIcon.Name = "Icon"
titleIcon.Size = UDim2.new(0, 24, 0, 24)
titleIcon.Position = UDim2.new(0, 15, 0.5, -12)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://6034509993" -- Eye icon
titleIcon.ImageColor3 = themeColor
titleIcon.Parent = header

local title = Instance.new("TextLabel") 
title.Name = "Title" 
title.Size = UDim2.new(0.7, -50, 1, 0) 
title.Position = UDim2.new(0, 50, 0, 0) 
title.BackgroundTransparency = 1 
title.Text = "ADVANCED ESP PRO" 
title.TextColor3 = Color3.fromRGB(255, 255, 255) 
title.TextSize = 18 
title.Font = Enum.Font.GothamBlack 
title.TextXAlignment = Enum.TextXAlignment.Left 
title.Parent = header 

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "Version"
versionLabel.Size = UDim2.new(0, 60, 0, 20)
versionLabel.Position = UDim2.new(0, 50, 0, 25)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v3.0"
versionLabel.TextColor3 = themeColor
versionLabel.TextSize = 12
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = header

-- Close and minimize buttons
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(0, 80, 1, 0)
buttonContainer.Position = UDim2.new(1, -80, 0, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = header

local closeButton = Instance.new("ImageButton") 
closeButton.Name = "CloseButton" 
closeButton.Size = UDim2.new(0, 30, 0, 30) 
closeButton.Position = UDim2.new(1, -40, 0.5, -15) 
closeButton.BackgroundTransparency = 1 
closeButton.Image = "rbxassetid://6031094678" -- X icon
closeButton.ImageColor3 = Color3.fromRGB(220, 220, 220) 
closeButton.Parent = buttonContainer

local minimizeButton = Instance.new("ImageButton") 
minimizeButton.Name = "MinimizeButton" 
minimizeButton.Size = UDim2.new(0, 30, 0, 30) 
minimizeButton.Position = UDim2.new(1, -80, 0.5, -15) 
minimizeButton.BackgroundTransparency = 1 
minimizeButton.Image = "rbxassetid://6031090990" -- Minimize icon
minimizeButton.ImageColor3 = Color3.fromRGB(220, 220, 220) 
minimizeButton.Parent = buttonContainer

-- Button hover effects
local function setupButtonHover(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {ImageColor3 = themeColor}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(220, 220, 220)}):Play()
    end)
end

setupButtonHover(closeButton)
setupButtonHover(minimizeButton)

closeButton.MouseButton1Click:Connect(function() 
    -- Fade out animation
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, -200, 1.2, 0)}):Play()
    TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
    
    wait(0.3)
    blurEffect:Destroy()
    screenGui:Destroy() 
    mainUI = nil 
end) 

minimizeButton.MouseButton1Click:Connect(function() 
    uiVisible = not uiVisible 
    
    if uiVisible then 
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 400, 0, 520)}):Play() 
    else 
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 400, 0, 50)}):Play() 
    end 
end) 

-- Make window draggable with smooth animation
local function updateDrag(input) 
    local delta = input.Position - dragStart 
    local targetPosition = UDim2.new(
        dragPos.X.Scale, 
        dragPos.X.Offset + delta.X, 
        dragPos.Y.Scale, 
        dragPos.Y.Offset + delta.Y
    )
    
    TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = targetPosition}):Play()
end 

header.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = true 
        dragStart = input.Position 
        dragPos = mainFrame.Position 
        
        input.Changed:Connect(function() 
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
            end 
        end) 
    end 
end) 

header.InputChanged:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then 
        updateDrag(input) 
    end 
end) 

UserInputService.InputChanged:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then 
        updateDrag(input) 
    end 
end) 

-- Tab system
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 40)
tabContainer.Position = UDim2.new(0, 0, 0, 50)
tabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
tabContainer.BackgroundTransparency = uiTransparency
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIGridLayout")
tabLayout.CellSize = UDim2.new(0.25, 0, 1, 0)
tabLayout.CellPadding = UDim2.new(0, 0, 0, 0)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabContainer

-- Content frame for tab content
local contentFrame = Instance.new("Frame") 
contentFrame.Name = "ContentFrame" 
contentFrame.Size = UDim2.new(1, 0, 1, -90) 
contentFrame.Position = UDim2.new(0, 0, 0, 90) 
contentFrame.BackgroundTransparency = 1 
contentFrame.Parent = mainFrame 

-- Create tab pages
local tabPages = {}

local function createTabPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -20, 1, -10)
    page.Position = UDim2.new(0, 10, 0, 5)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page
    
    -- Auto-size canvas
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    tabPages[name] = page
    return page
end

-- Create tabs
local tabs = {"Visual", "Settings", "Colors", "About"}
local tabButtons = {}

local function selectTab(tabName)
    for name, page in pairs(tabPages) do
        page.Visible = (name == tabName)
    end
    
    for _, button in pairs(tabButtons) do
        local isSelected = button.Name == tabName .. "Tab"
        button.BackgroundTransparency = isSelected and 0 or 0.9
        button.BackgroundColor3 = isSelected and themeColor or Color3.fromRGB(60, 60, 65)
        button.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        button:FindFirstChild("Indicator").Visible = isSelected
    end
end

for i, tabName in ipairs(tabs) do
    local isActive = (i == 1)
    local button = createTabButton(tabContainer, tabName, isActive, function()
        selectTab(tabName)
    end)
    tabButtons[tabName] = button
    createTabPage(tabName)
end

-- Select first tab by default
selectTab("Visual")

-- Create Visual tab content
local visualPage = tabPages["Visual"]

-- Main ESP toggle button
local espToggleButton = createButton(visualPage, "ESP: OFF", Color3.fromRGB(60, 60, 70), function()
    local enabled = toggleESP()
    espToggleButton:FindFirstChild("Button").Text = "ESP: " .. (enabled and "ON" or "OFF")
    
    if enabled then
        TweenService:Create(espToggleButton:FindFirstChild("Button"), TweenInfo.new(0.2), {BackgroundColor3 = themeColor}):Play()
        notificationSystem:Show("ESP Enabled", "Player ESP features are now active", "success", 2)
    else
        TweenService:Create(espToggleButton:FindFirstChild("Button"), TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
        notificationSystem:Show("ESP Disabled", "Player ESP features are now inactive", "info", 2)
    end
end)

-- Visual settings section
createSectionTitle("VISUAL ELEMENTS", visualPage)

-- Visual toggles in two columns
local visualGrid = Instance.new("Frame")
visualGrid.Name = "VisualGrid"
visualGrid.Size = UDim2.new(1, 0, 0, 180)
visualGrid.BackgroundTransparency = 1
visualGrid.Parent = visualPage

local visualLayout = Instance.new("UIGridLayout")
visualLayout.CellSize = UDim2.new(0.5, -5, 0, 36)
visualLayout.CellPadding = UDim2.new(0, 10, 0, 5)
visualLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
visualLayout.SortOrder = Enum.SortOrder.LayoutOrder
visualLayout.Parent = visualGrid

createToggleSwitch(visualGrid, "Show Names", ESP_CONFIG.SHOW_NAMES, function(value) ESP_CONFIG.SHOW_NAMES = value end)
createToggleSwitch(visualGrid, "Show Boxes", ESP_CONFIG.SHOW_BOXES, function(value) ESP_CONFIG.SHOW_BOXES = value end)
createToggleSwitch(visualGrid, "Show Tracers", ESP_CONFIG.SHOW_TRACERS, function(value) ESP_CONFIG.SHOW_TRACERS = value end)
createToggleSwitch(visualGrid, "Show Health", ESP_CONFIG.SHOW_HEALTH, function(value) ESP_CONFIG.SHOW_HEALTH = value end)
createToggleSwitch(visualGrid, "Show Distance", ESP_CONFIG.SHOW_DISTANCE, function(value) ESP_CONFIG.SHOW_DISTANCE = value end)
createToggleSwitch(visualGrid, "Show Weapons", ESP_CONFIG.SHOW_WEAPONS, function(value) ESP_CONFIG.SHOW_WEAPONS = value end)
createToggleSwitch(visualGrid, "Health Bars", ESP_CONFIG.SHOW_HEALTH_BAR, function(value) ESP_CONFIG.SHOW_HEALTH_BAR = value end)
createToggleSwitch(visualGrid, "Head Dots", ESP_CONFIG.SHOW_HEAD_DOTS, function(value) ESP_CONFIG.SHOW_HEAD_DOTS = value end)
createToggleSwitch(visualGrid, "View Angles", ESP_CONFIG.SHOW_VIEW_ANGLES, function(value) ESP_CONFIG.SHOW_VIEW_ANGLES = value end)
createToggleSwitch(visualGrid, "Status", ESP_CONFIG.SHOW_STATUS, function(value) ESP_CONFIG.SHOW_STATUS = value end)

-- Create Settings tab content
local settingsPage = tabPages["Settings"]

createSectionTitle("GENERAL SETTINGS", settingsPage)

-- Advanced toggles
local advancedGrid = Instance.new("Frame")
advancedGrid.Name = "AdvancedGrid"
advancedGrid.Size = UDim2.new(1, 0, 0, 90)
advancedGrid.BackgroundTransparency = 1
advancedGrid.Parent = settingsPage

local advancedLayout = Instance.new("UIGridLayout")
advancedLayout.CellSize = UDim2.new(0.5, -5, 0, 36)
advancedLayout.CellPadding = UDim2.new(0, 10, 0, 5)
advancedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
advancedLayout.SortOrder = Enum.SortOrder.LayoutOrder
advancedLayout.Parent = advancedGrid

createToggleSwitch(advancedGrid, "Team Check", ESP_CONFIG.TEAM_CHECK, function(value) ESP_CONFIG.TEAM_CHECK = value end)
createToggleSwitch(advancedGrid, "Smooth Animations", ESP_CONFIG.SMOOTH_ANIMATIONS, function(value) ESP_CONFIG.SMOOTH_ANIMATIONS = value end)
createToggleSwitch(advancedGrid, "Glow Effect", ESP_CONFIG.GLOW_EFFECT, function(value) ESP_CONFIG.GLOW_EFFECT = value end)
createToggleSwitch(advancedGrid, "Visibility Check", ESP_CONFIG.VISIBILITY_CHECK, function(value) ESP_CONFIG.VISIBILITY_CHECK = value end)

createSectionTitle("DISPLAY SETTINGS", settingsPage)

-- Sliders
local maxDistanceSlider, getMaxDistance = createSlider(settingsPage, "Max Distance", 100, 2000, ESP_CONFIG.MAX_DISTANCE, function(value)
    ESP_CONFIG.MAX_DISTANCE = value
end)

local textSizeSlider, getTextSize = createSlider(settingsPage, "Text Size", 10, 24, ESP_CONFIG.TEXT_SIZE, function(value)
    ESP_CONFIG.TEXT_SIZE = value
end)

local boxTransparencySlider, getBoxTransparency = createSlider(settingsPage, "Box Transparency", 0, 1, ESP_CONFIG.BOX_TRANSPARENCY, function(value)
    ESP_CONFIG.BOX_TRANSPARENCY = value
end)

local tracerTransparencySlider, getTracerTransparency = createSlider(settingsPage, "Tracer Transparency", 0, 1, ESP_CONFIG.TRACER_TRANSPARENCY, function(value)
    ESP_CONFIG.TRACER_TRANSPARENCY = value
end)

-- Create Colors tab content
local colorsPage = tabPages["Colors"]

createSectionTitle("COLOR SETTINGS", colorsPage)

-- Color buttons
createColorButton(colorsPage, "Friendly", ESP_CONFIG.COLOR_FRIENDLY, function(color)
    ESP_CONFIG.COLOR_FRIENDLY = color
end)

createColorButton(colorsPage, "Enemy", ESP_CONFIG.COLOR_ENEMY, function(color)
    ESP_CONFIG.COLOR_ENEMY = color
end)

createColorButton(colorsPage, "Near", ESP_CONFIG.COLOR_NEAR, function(color)
    ESP_CONFIG.COLOR_NEAR = color
end)

createColorButton(colorsPage, "Mid", ESP_CONFIG.COLOR_MID, function(color)
    ESP_CONFIG.COLOR_MID = color
end)

createColorButton(colorsPage, "Far", ESP_CONFIG.COLOR_FAR, function(color)
    ESP_CONFIG.COLOR_FAR = color
end)

createSectionTitle("UI THEME", colorsPage)

-- Theme color selection
local themeGrid = Instance.new("Frame")
themeGrid.Name = "ThemeGrid"
themeGrid.Size = UDim2.new(1, 0, 0, 120)
themeGrid.BackgroundTransparency = 1
themeGrid.Parent = colorsPage

local themeLayout = Instance.new("UIGridLayout")
themeLayout.CellSize = UDim2.new(0.25, -10, 0, 50)
themeLayout.CellPadding = UDim2.new(0, 10, 0, 10)
themeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
themeLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeLayout.Parent = themeGrid

-- Theme color options
local themeColors = {
    {name = "Blue", color = Color3.fromRGB(0, 170, 255)},
    {name = "Red", color = Color3.fromRGB(255, 50, 50)},
    {name = "Green", color = Color3.fromRGB(0, 180, 120)},
    {name = "Purple", color = Color3.fromRGB(170, 0, 255)},
    {name = "Orange", color = Color3.fromRGB(255, 120, 0)},
    {name = "Pink", color = Color3.fromRGB(255, 0, 180)},
    {name = "Teal", color = Color3.fromRGB(0, 180, 180)},
    {name = "Gold", color = Color3.fromRGB(255, 200, 0)}
}

local function createThemeButton(themeData)
    local button = Instance.new("TextButton")
    button.Name = themeData.name
    button.BackgroundColor3 = themeData.color
    button.Text = ""
    button.Parent = themeGrid
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0.5, -10)
    label.BackgroundTransparency = 1
    label.Text = themeData.name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = button
    
    -- Add shadow
    createShadow(button)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, -2, 0, -2)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        -- Update theme color
        themeColor = themeData.color
        
        -- Update UI elements
        titleIcon.ImageColor3 = themeColor
        versionLabel.TextColor3 = themeColor
        
        -- Update all tab indicators
        for _, tab in pairs(tabButtons) do
            if tab:FindFirstChild("Indicator") then
                tab:FindFirstChild("Indicator").BackgroundColor3 = themeColor
            end
            if tab.BackgroundTransparency == 0 then
                tab.BackgroundColor3 = themeColor
            end
        end
        
        -- Notification
        notificationSystem:Show("Theme Updated", "UI theme changed to " .. themeData.name, "info", 2)
    end)
end

for _, themeData in ipairs(themeColors) do
    createThemeButton(themeData)
end

-- Create About tab content
local aboutPage = tabPages["About"]

-- Logo and version
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, 0, 0, 100)
logoFrame.BackgroundTransparency = 1
logoFrame.Parent = aboutPage

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 80, 0, 80)
logo.Position = UDim2.new(0.5, -40, 0, 10)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://6034509993" -- Eye icon
logo.ImageColor3 = themeColor
logo.Parent = logoFrame

local versionInfo = Instance.new("TextLabel")
versionInfo.Size = UDim2.new(1, 0, 0, 30)
versionInfo.Position = UDim2.new(0, 0, 0, 100)
versionInfo.BackgroundTransparency = 1
versionInfo.Text = "Advanced ESP Pro v3.0"
versionInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
versionInfo.TextSize = 18
versionInfo.Font = Enum.Font.GothamBold
versionInfo.Parent = aboutPage

-- Features list
createSectionTitle("FEATURES", aboutPage)

local featuresFrame = Instance.new("Frame")
featuresFrame.Size = UDim2.new(1, 0, 0, 150)
featuresFrame.BackgroundTransparency = 1
featuresFrame.Parent = aboutPage

local featuresText = Instance.new("TextLabel")
featuresText.Size = UDim2.new(1, -20, 1, 0)
featuresText.Position = UDim2.new(0, 10, 0, 0)
featuresText.BackgroundTransparency = 1
featuresText.Text = "\u2022 Advanced player ESP with multiple visualization options\

\u2022 Team-based color coding\
\u2022 Distance-based color gradients\
\u2022 Health and status indicators\
\u2022 Customizable visual elements\
\u2022 Performance optimized rendering\
\u2022 Modern, professional user interface\
\u2022 Multiple theme options"
    featuresText.TextColor3 = Color3.fromRGB(220, 220, 220)
    featuresText.TextSize = 14
    featuresText.Font = Enum.Font.Gotham
    featuresText.TextXAlignment = Enum.TextXAlignment.Left
    featuresText.TextYAlignment = Enum.TextYAlignment.Top
    featuresText.Parent = featuresFrame


-- Hotkeys info
createSectionTitle("HOTKEYS", aboutPage)

local hotkeysFrame = Instance.new("Frame")
hotkeysFrame.Size = UDim2.new(1, 0, 0, 100)
hotkeysFrame.BackgroundTransparency = 1
hotkeysFrame.Parent = aboutPage

local hotkeysText = Instance.new("TextLabel")
hotkeysText.Size = UDim2.new(1, -20, 1, 0)
hotkeysText.Position = UDim2.new(0, 10, 0, 0)
hotkeysText.BackgroundTransparency = 1
hotkeysText.Text = "T - Toggle ESP On/Off\

U - Quick Settings\
H - Hide/Show UI\
RightShift - Open Main Menu"
    hotkeysText.TextColor3 = Color3.fromRGB(220, 220, 220)
    hotkeysText.TextSize = 14
    hotkeysText.Font = Enum.Font.Gotham
    hotkeysText.TextXAlignment = Enum.TextXAlignment.Left
    hotkeysText.TextYAlignment = Enum.TextYAlignment.Top
    hotkeysText.Parent = hotkeysFrame


-- Credits
createSectionTitle("CREDITS", aboutPage)

local creditsFrame = Instance.new("Frame")
creditsFrame.Size = UDim2.new(1, 0, 0, 30)
creditsFrame.BackgroundTransparency = 1
creditsFrame.Parent = aboutPage

local creditsText = Instance.new("TextLabel")
creditsText.Size = UDim2.new(1, -20, 1, 0)
creditsText.Position = UDim2.new(0, 10, 0, 0)
creditsText.BackgroundTransparency = 1
creditsText.Text = "Created by NinjaTech Team \u00a9 2025"
creditsText.TextColor3 = Color3.fromRGB(180, 180, 180)
creditsText.TextSize = 14
creditsText.Font = Enum.Font.Gotham
creditsText.TextXAlignment = Enum.TextXAlignment.Center
creditsText.Parent = creditsFrame

-- Entrance animation
mainFrame.Position = UDim2.new(0.5, -200, 1.2, 0)
TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -200, 0.5, -260)}):Play()
TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 10}):Play()

-- Show welcome notification
wait(0.6)
notificationSystem:Show("ESP Pro Loaded", "Welcome to Advanced ESP Pro v3.0", "success", 3)

mainUI = screenGui

end


-- Initialize
localPlayer.CharacterAdded:Connect(function(character)
    localCharacter = character
    localHead = character:WaitForChild("Head")
    localHumanoid = character:WaitForChild("Humanoid")
end)


if localPlayer.Character then
    localCharacter = localPlayer.Character
    localHead = localCharacter:WaitForChild("Head")
    localHumanoid = localCharacter:WaitForChild("Humanoid")
end


-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    removeESPObject(player)
end)


-- Create ESP for new players
Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= localPlayer then
        createESPObject(player)
    end
end)


-- Enhanced notification function
local function showNotification(title, message, type, duration)
    notificationSystem:Show(title, message, type or "info", duration or 3)
end


-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end


if input.KeyCode == Enum.KeyCode.T then 
    local enabled = toggleESP() 
    showNotification("ESP " .. (enabled and "Enabled" or "Disabled"), 
                    enabled and "Player ESP features are now active" or "Player ESP features are now inactive", 
                    enabled and "success" or "info")
elseif input.KeyCode == Enum.KeyCode.U then 
    -- Quick settings popup would go here
    showNotification("Quick Settings", "Quick settings feature coming soon", "info") 
elseif input.KeyCode == Enum.KeyCode.H then 
    if mainUI then 
        uiVisible = not uiVisible 
        if mainUI:FindFirstChild("MainFrame") then 
            local mainFrame = mainUI.MainFrame 
            
            if uiVisible then 
                TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 400, 0, 520)}):Play() 
            else 
                TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 400, 0, 50)}):Play() 
            end 
        end 
    end 
elseif input.KeyCode == Enum.KeyCode.RightShift then 
    createMainUI() 
end 

end)


-- Create the UI automatically
createMainUI()


-- Show welcome notification
showNotification("ESP Pro Loaded", "Welcome to Advanced ESP Pro v3.0", "success", 3)


return {
    toggleESP = toggleESP,
    showUI = createMainUI,
    showNotification = showNotification,
    config = ESP_CONFIG
}
