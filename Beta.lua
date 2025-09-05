local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

-- Advanced Configuration
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
    VISIBILITY_CHECK = false
}

-- ESP Data
local localPlayer = Players.LocalPlayer
local espEnabled = false
local espObjects = {}
local espUpdateConnection = nil
local settingsWindow = nil
local mainUI = nil
local logoUI = nil
local dragging = false
local dragInput = nil
local dragStart = nil
local dragPos = nil
local uiVisible = true

-- Initialize local player character
local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local localHead = localCharacter:WaitForChild("Head")
local localHumanoid = localCharacter:WaitForChild("Humanoid")

-- Utility functions
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
            else
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
                        espObject.distanceLabel.Text = string.format("[%d studs]", math.floor(distance))
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
                        espObject.healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
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

-- Modern toggle switch component with text ON/OFF
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
    toggleBackground.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
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
    
    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status"
    statusText.Size = UDim2.new(0, 30, 0, 20)
    statusText.Position = UDim2.new(1, -90, 0.5, -10)
    statusText.BackgroundTransparency = 1
    statusText.Text = defaultValue and "ON" or "OFF"
    statusText.TextColor3 = defaultValue and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(180, 180, 180)
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
        local bgColor = isOn and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
        local textColor = isOn and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(180, 180, 180)
        
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

-- Notification function
local function showNotification(message)
    StarterGui:SetCore("SendNotification", {
        Title = "ZiaanESP System",
        Text = message,
        Duration = 3
    })
end

-- Function to toggle UI visibility
local function toggleUIVisibility()
    if mainUI and mainUI.Parent then
        uiVisible = not uiVisible
        mainUI.Enabled = uiVisible
        
        if uiVisible then
            showNotification("ZiaanESP UI Shown")
        else
            showNotification("ZiaanESP UI Hidden")
        end
    else
        createMainUI()
    end
end

-- Create confirmation popup
local function createConfirmationPopup(parent)
    local popup = Instance.new("Frame")
    popup.Name = "ConfirmationPopup"
    popup.Size = UDim2.new(0, 300, 0, 150)
    popup.Position = UDim2.new(0.5, -150, 0.5, -75)
    popup.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    popup.BorderSizePixel = 0
    popup.ZIndex = 10
    popup.Visible = false
    popup.Parent = parent
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 8)
    popupCorner.Parent = popup
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Confirm Action"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = popup
    
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -20, 0, 50)
    message.Position = UDim2.new(0, 10, 0, 40)
    message.BackgroundTransparency = 1
    message.Text = "Are you sure you want to close ZiaanESP?\nThis will disable all ESP features."
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.TextSize = 14
    message.Font = Enum.Font.Gotham
    message.TextWrapped = true
    message.Parent = popup
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -20, 0, 40)
    buttonContainer.Position = UDim2.new(0, 10, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = popup
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer
    
    local yesButton = Instance.new("TextButton")
    yesButton.Name = "YesButton"
    yesButton.Size = UDim2.new(0, 120, 1, 0)
    yesButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    yesButton.Text = "Yes, Close"
    yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.TextSize = 14
    yesButton.Font = Enum.Font.GothamBold
    yesButton.Parent = buttonContainer
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 6)
    yesCorner.Parent = yesButton
    
    local noButton = Instance.new("TextButton")
    noButton.Name = "NoButton"
    noButton.Size = UDim2.new(0, 120, 1, 0)
    noButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    noButton.Text = "No, Keep Open"
    noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    noButton.TextSize = 14
    noButton.Font = Enum.Font.GothamBold
    noButton.Parent = buttonContainer
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 6)
    noCorner.Parent = noButton
    
    return popup, yesButton, noButton
end

-- Create logo UI
local function createLogoUI()
    if logoUI and logoUI.Parent then
        logoUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZiaanESPLogoUI"
    screenGui.Parent = CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    local logoButton = Instance.new("ImageButton")
    logoButton.Name = "LogoButton"
    logoButton.Size = UDim2.new(0, 50, 0, 50)
    logoButton.Position = UDim2.new(0, 10, 0, 10)
    logoButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    logoButton.Image = "rbxassetid://11305923967" -- Replace with your logo asset ID
    logoButton.Parent = screenGui
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12)
    logoCorner.Parent = logoButton
    
    logoButton.MouseButton1Click:Connect(function()
        toggleUIVisibility()
    end)
    
    logoUI = screenGui
    return screenGui
end

-- Create professional draggable UI
local function createMainUI()
    if mainUI and mainUI.Parent then
        mainUI.Enabled = not mainUI.Enabled
        uiVisible = mainUI.Enabled
        return
    end

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZiaanESPProUI"
    screenGui.Parent = CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Main container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ZIAAN ESP PRO"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button (X)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    -- Hide button (-)
    local hideButton = Instance.new("TextButton")
    hideButton.Name = "HideButton"
    hideButton.Size = UDim2.new(0, 30, 0, 30)
    hideButton.Position = UDim2.new(1, -70, 0.5, -15)
    hideButton.BackgroundTransparency = 1
    hideButton.Text = "-"
    hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideButton.TextSize = 20
    hideButton.Font = Enum.Font.GothamBold
    hideButton.Parent = header
    
    hideButton.MouseButton1Click:Connect(function()
        toggleUIVisibility()
    end)
    
    -- Content frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -10, 1, -50)
    contentFrame.Position = UDim2.new(0, 5, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = contentFrame
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Main toggle button
    local espToggleButton = Instance.new("TextButton")
    espToggleButton.Name = "ToggleESPButton"
    espToggleButton.Size = UDim2.new(1, -20, 0, 40)
    espToggleButton.Position = UDim2.new(0, 10, 0, 10)
    espToggleButton.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    espToggleButton.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    espToggleButton.TextSize = 16
    espToggleButton.Font = Enum.Font.GothamBold
    espToggleButton.Parent = contentFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = espToggleButton
    
    espToggleButton.MouseButton1Click:Connect(function()
        local enabled = toggleESP()
        espToggleButton.Text = enabled and "ESP: ON" or "ESP: OFF"
        espToggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Visual settings section
    local visualSection = Instance.new("Frame")
    visualSection.Name = "VisualSection"
    visualSection.Size = UDim2.new(1, 0, 0, 30)
    visualSection.BackgroundTransparency = 1
    visualSection.Parent = contentFrame
    
    local visualTitle = Instance.new("TextLabel")
    visualTitle.Name = "Title"
    visualTitle.Size = UDim2.new(1, 0, 1, 0)
    visualTitle.BackgroundTransparency = 1
    visualTitle.Text = "VISUAL SETTINGS"
    visualTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    visualTitle.TextSize = 16
    visualTitle.Font = Enum.Font.GothamBold
    visualTitle.TextXAlignment = Enum.TextXAlignment.Left
    visualTitle.Parent = visualSection
    
    -- Visual toggles
    createToggleSwitch(contentFrame, "Show Names", ESP_CONFIG.SHOW_NAMES, function(value)
        ESP_CONFIG.SHOW_NAMES = value
    end)
    
    createToggleSwitch(contentFrame, "Show Distance", ESP_CONFIG.SHOW_DISTANCE, function(value)
        ESP_CONFIG.SHOW_DISTANCE = value
    end)
    
    createToggleSwitch(contentFrame, "Show Health", ESP_CONFIG.SHOW_HEALTH, function(value)
        ESP_CONFIG.SHOW_HEALTH = value
    end)
    
    createToggleSwitch(contentFrame, "Health Bars", ESP_CONFIG.SHOW_HEALTH_BAR, function(value)
        ESP_CONFIG.SHOW_HEALTH_BAR = value
    end)
    
    createToggleSwitch(contentFrame, "Show Boxes", ESP_CONFIG.SHOW_BOXES, function(value)
        ESP_CONFIG.SHOW_BOXES = value
    end)
    
    createToggleSwitch(contentFrame, "Show Tracers", ESP_CONFIG.SHOW_TRACERS, function(value)
        ESP_CONFIG.SHOW_TRACERS = value
    end)
    
    createToggleSwitch(contentFrame, "Head Dots", ESP_CONFIG.SHOW_HEAD_DOTS, function(value)
        ESP_CONFIG.SHOW_HEAD_DOTS = value
    end)
    
    createToggleSwitch(contentFrame, "View Angles", ESP_CONFIG.SHOW_VIEW_ANGLES, function(value)
        ESP_CONFIG.SHOW_VIEW_ANGLES = value
    end)
    
    createToggleSwitch(contentFrame, "Show Weapons", ESP_CONFIG.SHOW_WEAPONS, function(value)
        ESP_CONFIG.SHOW_WEAPONS = value
    end)
    
    createToggleSwitch(contentFrame, "Show Status", ESP_CONFIG.SHOW_STATUS, function(value)
        ESP_CONFIG.SHOW_STATUS = value
    end)
    
    createToggleSwitch(contentFrame, "Team Check", ESP_CONFIG.TEAM_CHECK, function(value)
        ESP_CONFIG.TEAM_CHECK = value
    end)
    
    createToggleSwitch(contentFrame, "Smooth Animations", ESP_CONFIG.SMOOTH_ANIMATIONS, function(value)
        ESP_CONFIG.SMOOTH_ANIMATIONS = value
    end)
    
    createToggleSwitch(contentFrame, "Glow Effect", ESP_CONFIG.GLOW_EFFECT, function(value)
        ESP_CONFIG.GLOW_EFFECT = value
    end)
    
    -- Max distance slider
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "DistanceSlider"
    sliderFrame.Size = UDim2.new(1, 0, 0, 60)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = contentFrame
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Name = "Label"
    sliderLabel.Size = UDim2.new(1, -10, 0, 20)
    sliderLabel.Position = UDim2.new(0, 5, 0, 0)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Max Distance: " .. ESP_CONFIG.MAX_DISTANCE
    sliderLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    sliderLabel.TextSize = 14
    sliderLabel.Font = Enum.Font.GothamSemibold
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local slider = Instance.new("Frame")
    slider.Name = "Slider"
    slider.Size = UDim2.new(1, -10, 0, 20)
    slider.Position = UDim2.new(0, 5, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    slider.BorderSizePixel = 0
    slider.Parent = sliderFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 8)
    sliderCorner.Parent = slider
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((ESP_CONFIG.MAX_DISTANCE - 100) / 4900, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = fill
    
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((ESP_CONFIG.MAX_DISTANCE - 100) / 4900, -10, 0, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = slider
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 10)
    knobCorner.Parent = knob
    
    -- Slider interaction
    local isDragging = false
    
    local function updateSlider(value)
        value = math.clamp(value, 100, 5000)
        ESP_CONFIG.MAX_DISTANCE = value
        sliderLabel.Text = "Max Distance: " .. math.floor(value)
        fill.Size = UDim2.new((value - 100) / 4900, 0, 1, 0)
        knob.Position = UDim2.new((value - 100) / 4900, -10, 0, 0)
    end
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            local pos = input.Position.X - slider.AbsolutePosition.X
            local value = 100 + (pos / slider.AbsoluteSize.X) * 4900
            updateSlider(value)
        end
    end)
    
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position.X - slider.AbsolutePosition.X
            local value = 100 + (pos / slider.AbsoluteSize.X) * 4900
            updateSlider(value)
        end
    end)
    
    -- Credit section
    local creditFrame = Instance.new("Frame")
    creditFrame.Name = "CreditFrame"
    creditFrame.Size = UDim2.new(1, -10, 0, 30)
    creditFrame.Position = UDim2.new(0, 5, 1, -35)
    creditFrame.BackgroundTransparency = 1
    creditFrame.Parent = mainFrame
    
    local creditText = Instance.new("TextLabel")
    creditText.Name = "CreditText"
    creditText.Size = UDim2.new(1, 0, 1, 0)
    creditText.BackgroundTransparency = 1
    creditText.Text = "Made by @ziaanstore"
    creditText.TextColor3 = Color3.fromRGB(0, 170, 255)
    creditText.TextSize = 14
    creditText.Font = Enum.Font.GothamBold
    creditText.TextXAlignment = Enum.TextXAlignment.Center
    creditText.Parent = creditFrame
    
    -- Create confirmation popup
    local confirmationPopup, yesButton, noButton = createConfirmationPopup(mainFrame)
    
    -- Close button functionality with confirmation
    closeButton.MouseButton1Click:Connect(function()
        confirmationPopup.Visible = true
    end)
    
    yesButton.MouseButton1Click:Connect(function()
        -- Disable ESP
        if espEnabled then
            toggleESP()
        end
        
        -- Close UI
        screenGui:Destroy()
        mainUI = nil
        uiVisible = false
        
        -- Also remove logo UI
        if logoUI then
            logoUI:Destroy()
            logoUI = nil
        end
        
        showNotification("ZiaanESP has been closed completely")
    end)
    
    noButton.MouseButton1Click:Connect(function()
        confirmationPopup.Visible = false
    end)
    
    -- Make UI draggable
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            dragPos = mainFrame.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
        end
    end)
    
    mainUI = screenGui
    uiVisible = true
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

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.T then
        toggleESP()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        createMainUI()
    elseif input.KeyCode == Enum.KeyCode.Minus then
        toggleUIVisibility()
    end
end)

-- Create the UI and logo
createMainUI()
createLogoUI()

showNotification("ZiaanESP System Loaded! Use the logo button to toggle UI, RightShift to reopen, and Minus to hide/show.")
