local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Silent Runners | FPS One Tap",
    LoadingTitle = "Silent Runners Injection",
    LoadingSubtitle = "by Silent Runners Team",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "SilentRunnersConfigs",
       FileName = "FPSOneTap"
    },
    Discord = {
       Enabled = false,
       Invite = "",
       RememberJoins = false
    },
    KeySystem = false
})

local RageTab = Window:CreateTab("🎯 Rage", 4483362458)
local LegitTab = Window:CreateTab("🔫 Legit Bot", 4483362458)
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
local MiscTab = Window:CreateTab("⚙️ MISC", 4483362458)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local rageEnabled = false
local rageAutoShot = false
local rageWallCheck = true
local rageAimPart = "Head"
local rageFOV = 360

local legitEnabled = false
local legitAutoShot = false
local legitAimPart = "Head"
local legitFOV = 90
local legitSmoothing = 5
local showFOV = false
local fovCircle = nil
local fovOutline = nil

local espEnabled = false
local espBoxes = false
local espDistance = false
local espHP = false
local espName = false
local espChams = false
local espTracers = false
local espPlayers = {}

local noclipEnabled = false
local noclipConnection = nil
local bunnyHopEnabled = false
local bhopConnection = nil

local function isTargetVisible(targetCharacter, targetPart)
    if not targetCharacter or not targetPart then return false end
    
    local cameraPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local ignoreList = {}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    table.insert(ignoreList, targetCharacter)
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local direction = (targetPos - cameraPos).Unit
    local distance = (targetPos - cameraPos).Magnitude
    
    local raycastResult = Workspace:Raycast(cameraPos, direction * distance, raycastParams)
    
    if not raycastResult then return true end
    
    local hitPart = raycastResult.Instance
    local hitCharacter = hitPart.Parent
    
    if hitCharacter == targetCharacter then return true end
    
    return false
end

local function getNearestEnemy(aimPart, fov, checkWall, useFOV)
    local nearestEnemy = nil
    local nearestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid or humanoid.Health <= 0 then continue end

        local targetPart = character:FindFirstChild(aimPart)
        if not targetPart then continue end

        local screenPosition, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        if useFOV and fov < 360 then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
            local distanceFromCenter = (screenPos2D - screenCenter).Magnitude
            local maxFOVDistance = (Camera.ViewportSize.Y / 2) * (fov / 90)

            if distanceFromCenter > maxFOVDistance then continue end
        end

        if checkWall and not isTargetVisible(character, targetPart) then continue end

        local distance = (Camera.CFrame.Position - targetPart.Position).Magnitude

        if distance < nearestDistance then
            nearestDistance = distance
            nearestEnemy = {
                player = player,
                character = character,
                targetPart = targetPart,
                distance = distance,
                screenPosition = screenPosition
            }
        end
    end

    return nearestEnemy
end

local function fireShot()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function drawFOVCircle()
    if fovCircle then fovCircle:Remove() fovCircle = nil end
    if fovOutline then fovOutline:Remove() fovOutline = nil end
    
    if not showFOV then return end
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    local radius = (Camera.ViewportSize.Y / 2) * (legitFOV / 90)
    
    fovOutline = Drawing.new("Circle")
    fovOutline.Visible = true
    fovOutline.Thickness = 2
    fovOutline.Color = Color3.new(0, 0, 0)
    fovOutline.Transparency = 1
    fovOutline.Filled = false
    fovOutline.NumSides = 100
    fovOutline.Radius = radius
    fovOutline.Position = Vector2.new(centerX, centerY)
    fovOutline.ZIndex = 2
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = true
    fovCircle.Thickness = 1
    fovCircle.Color = Color3.new(1, 1, 1)
    fovCircle.Transparency = 0.8
    fovCircle.Filled = true
    fovCircle.NumSides = 100
    fovCircle.Radius = radius
    fovCircle.Position = Vector2.new(centerX, centerY)
    fovCircle.ZIndex = 1
end

RunService.RenderStepped:Connect(function()
    if rageEnabled then
        local useFOV = rageFOV < 360
        local enemy = getNearestEnemy(rageAimPart, rageFOV, rageWallCheck, useFOV)
        if enemy then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemy.targetPart.Position)
            if rageAutoShot then fireShot() end
        end
    elseif legitEnabled then
        local useFOV = legitFOV < 360
        local enemy = getNearestEnemy(legitAimPart, legitFOV, true, useFOV)
        if enemy then
            local targetPos = enemy.targetPart.Position
            local smoothFactor = math.min(legitSmoothing / 10, 1)
            local newCFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), smoothFactor)
            Camera.CFrame = newCFrame
            
            if legitAutoShot then
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local screenPos2D = Vector2.new(enemy.screenPosition.X, enemy.screenPosition.Y)
                local distanceFromCenter = (screenPos2D - screenCenter).Magnitude
                if distanceFromCenter < 10 then fireShot() end
            end
        end
    end
    
    drawFOVCircle()
end)

local function createESPForPlayer(player)
    if espPlayers[player] then return end

    local espData = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        hpBar = Drawing.new("Line"),
        hpBackground = Drawing.new("Line"),
        tracer = Drawing.new("Line"),
        chams = nil
    }

    espData.box.Visible = false
    espData.box.Thickness = 2
    espData.box.Color = Color3.new(1, 0, 0)
    espData.box.Filled = false
    espData.box.Transparency = 1

    espData.name.Visible = false
    espData.name.Size = 14
    espData.name.Color = Color3.new(1, 1, 1)
    espData.name.Center = true
    espData.name.Outline = true
    espData.name.OutlineColor = Color3.new(0, 0, 0)

    espData.distance.Visible = false
    espData.distance.Size = 14
    espData.distance.Color = Color3.new(1, 1, 1)
    espData.distance.Center = true
    espData.distance.Outline = true
    espData.distance.OutlineColor = Color3.new(0, 0, 0)

    espData.hpBar.Visible = false
    espData.hpBar.Thickness = 2
    espData.hpBar.Color = Color3.new(0, 1, 0)

    espData.hpBackground.Visible = false
    espData.hpBackground.Thickness = 2
    espData.hpBackground.Color = Color3.new(0.3, 0.3, 0.3)

    espData.tracer.Visible = false
    espData.tracer.Thickness = 1
    espData.tracer.Color = Color3.new(1, 1, 1)

    espPlayers[player] = espData

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then
            espData.box:Remove()
            espData.name:Remove()
            espData.distance:Remove()
            espData.hpBar:Remove()
            espData.hpBackground:Remove()
            espData.tracer:Remove()
            if espData.chams then
                for _, part in ipairs(espData.chams) do part:Destroy() end
            end
            connection:Disconnect()
            espPlayers[player] = nil
            return
        end

        local character = player.Character
        if not character then
            espData.box.Visible = false
            espData.name.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
            espData.tracer.Visible = false
            if espData.chams then
                for _, part in ipairs(espData.chams) do part:Destroy() end
                espData.chams = nil
            end
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")

        if not rootPart or not humanoid then
            espData.box.Visible = false
            espData.name.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
            espData.tracer.Visible = false
            if espData.chams then
                for _, part in ipairs(espData.chams) do part:Destroy() end
                espData.chams = nil
            end
            return
        end

        local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if espEnabled then
            if espChams then
                if not espData.chams then
                    espData.chams = {}
                    for _, part in ipairs(character:GetChildren()) do
                        if part:IsA("BasePart") and part.Transparency < 0.5 then
                            local cham = Instance.new("BoxHandleAdornment")
                            cham.Size = part.Size
                            cham.Adornee = part
                            cham.AlwaysOnTop = true
                            cham.ZIndex = 1
                            cham.Transparency = 0.7
                            cham.Color3 = player.Team == LocalPlayer.Team and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                            cham.Parent = part
                            table.insert(espData.chams, cham)
                        end
                    end
                end
            else
                if espData.chams then
                    for _, part in ipairs(espData.chams) do part:Destroy() end
                    espData.chams = nil
                end
            end

            if onScreen then
                local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local scale = 1500 / math.max(distance, 1)
                local boxWidth = math.clamp(scale * 1.2, 20, 200)
                local boxHeight = math.clamp(scale * 2.5, 40, 400)

                if espBoxes then
                    espData.box.Visible = true
                    espData.box.Position = Vector2.new(position.X - boxWidth/2, position.Y - boxHeight/2)
                    espData.box.Size = Vector2.new(boxWidth, boxHeight)

                    if player.Team == LocalPlayer.Team then
                        espData.box.Color = Color3.new(0, 1, 0)
                    else
                        espData.box.Color = Color3.new(1, 0, 0)
                    end
                else
                    espData.box.Visible = false
                end

                if espName then
                    espData.name.Visible = true
                    espData.name.Position = Vector2.new(position.X, position.Y - boxHeight/2 - 30)
                    espData.name.Text = player.Name
                else
                    espData.name.Visible = false
                end

                if espDistance then
                    espData.distance.Visible = true
                    espData.distance.Position = Vector2.new(position.X, position.Y - boxHeight/2 - 15)
                    espData.distance.Text = string.format("%.0fm", distance)
                else
                    espData.distance.Visible = false
                end

                if espHP and humanoid.Health > 0 then
                    espData.hpBar.Visible = true
                    espData.hpBackground.Visible = true

                    local hpPercent = humanoid.Health / humanoid.MaxHealth
                    local barWidth = boxWidth * 0.9
                    local barX = position.X - barWidth/2
                    local barY = position.Y - boxHeight/2 - 5

                    espData.hpBackground.From = Vector2.new(barX, barY)
                    espData.hpBackground.To = Vector2.new(barX + barWidth, barY)

                    espData.hpBar.From = Vector2.new(barX, barY)
                    espData.hpBar.To = Vector2.new(barX + barWidth * hpPercent, barY)

                    if hpPercent > 0.5 then
                        espData.hpBar.Color = Color3.new(0, 1, 0)
                    elseif hpPercent > 0.25 then
                        espData.hpBar.Color = Color3.new(1, 1, 0)
                    else
                        espData.hpBar.Color = Color3.new(1, 0, 0)
                    end
                else
                    espData.hpBar.Visible = false
                    espData.hpBackground.Visible = false
                end

                if espTracers then
                    espData.tracer.Visible = true
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    espData.tracer.From = screenCenter
                    espData.tracer.To = Vector2.new(position.X, position.Y)
                    
                    if player.Team == LocalPlayer.Team then
                        espData.tracer.Color = Color3.new(0, 1, 0)
                    else
                        espData.tracer.Color = Color3.new(1, 0, 0)
                    end
                else
                    espData.tracer.Visible = false
                end
            else
                espData.box.Visible = false
                espData.name.Visible = false
                espData.distance.Visible = false
                espData.hpBar.Visible = false
                espData.hpBackground.Visible = false
                espData.tracer.Visible = false
            end
        else
            espData.box.Visible = false
            espData.name.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
            espData.tracer.Visible = false
            if espData.chams then
                for _, part in ipairs(espData.chams) do part:Destroy() end
                espData.chams = nil
            end
        end
    end)
end

local function clearAllESP()
    for player, espData in pairs(espPlayers) do
        espData.box:Remove()
        espData.name:Remove()
        espData.distance:Remove()
        espData.hpBar:Remove()
        espData.hpBackground:Remove()
        espData.tracer:Remove()
        if espData.chams then
            for _, part in ipairs(espData.chams) do part:Destroy() end
        end
    end
    espPlayers = {}
end

Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            createESPForPlayer(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espPlayers[player] then
        espPlayers[player].box:Remove()
        espPlayers[player].name:Remove()
        espPlayers[player].distance:Remove()
        espPlayers[player].hpBar:Remove()
        espPlayers[player].hpBackground:Remove()
        espPlayers[player].tracer:Remove()
        if espPlayers[player].chams then
            for _, part in ipairs(espPlayers[player].chams) do part:Destroy() end
        end
        espPlayers[player] = nil
    end
end)

local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    if noclipEnabled then
        disableNoclip()
        enableNoclip()
    end
end)

local function enableBunnyHop()
    if bhopConnection then bhopConnection:Disconnect() end
    bhopConnection = RunService.Heartbeat:Connect(function()
        if not bunnyHopEnabled then return end
        if not LocalPlayer.Character then return end
        
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootPart then return end
        
        local moveDirection = humanoid.MoveDirection
        local isMoving = moveDirection.Magnitude > 0
        
        if not isMoving then
            humanoid.WalkSpeed = 16
            return
        end
        
        if humanoid.WalkSpeed < 32 then
            humanoid.WalkSpeed = 32
        end
        
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed then
            humanoid.Jump = true
        end
    end)
end

local function disableBunnyHop()
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

RageTab:CreateToggle({
    Name = "🎯 Enable Rage",
    CurrentValue = false,
    Callback = function(Value)
        rageEnabled = Value
        if Value then legitEnabled = false end
    end
})

RageTab:CreateToggle({
    Name = "💀 Auto Shot",
    CurrentValue = false,
    Callback = function(Value) rageAutoShot = Value end
})

RageTab:CreateToggle({
    Name = "🧱 Wall Check",
    CurrentValue = true,
    Callback = function(Value) rageWallCheck = Value end
})

RageTab:CreateDropdown({
    Name = "🎯 Aim Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(Option) rageAimPart = Option end
})

RageTab:CreateSlider({
    Name = "🔭 FOV",
    Range = {10, 360},
    Increment = 10,
    Suffix = "°",
    CurrentValue = 360,
    Callback = function(Value) rageFOV = Value end
})

RageTab:CreateParagraph({
    Title = "Rage Features",
    Content = "FOV 360 = targets any visible enemy\nInstant aim + instant shot"
})

LegitTab:CreateToggle({
    Name = "🔫 Enable Legit Bot",
    CurrentValue = false,
    Callback = function(Value)
        legitEnabled = Value
        if Value then rageEnabled = false end
    end
})

LegitTab:CreateToggle({
    Name = "💀 Auto Shot",
    CurrentValue = false,
    Callback = function(Value) legitAutoShot = Value end
})

LegitTab:CreateDropdown({
    Name = "🎯 Aim Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(Option) legitAimPart = Option end
})

LegitTab:CreateSlider({
    Name = "🔭 FOV",
    Range = {10, 180},
    Increment = 5,
    Suffix = "°",
    CurrentValue = 90,
    Callback = function(Value) legitFOV = Value end
})

LegitTab:CreateToggle({
    Name = "👁️ Show FOV",
    CurrentValue = false,
    Callback = function(Value) showFOV = Value end
})

LegitTab:CreateSlider({
    Name = "🖱️ Smoothing",
    Range = {1, 12},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Callback = function(Value) legitSmoothing = Value end
})

LegitTab:CreateParagraph({
    Title = "Legit Bot Features",
    Content = "Smooth aim with visible FOV circle\nWall Check always ON"
})

ESPTab:CreateToggle({
    Name = "👁️ Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        espEnabled = Value
        if Value then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then createESPForPlayer(player) end
            end
        else
            clearAllESP()
        end
    end
})

ESPTab:CreateToggle({Name = "📦 Boxes", CurrentValue = false, Callback = function(Value) espBoxes = Value end})
ESPTab:CreateToggle({Name = "📛 Name", CurrentValue = false, Callback = function(Value) espName = Value end})
ESPTab:CreateToggle({Name = "📏 Distance", CurrentValue = false, Callback = function(Value) espDistance = Value end})
ESPTab:CreateToggle({Name = "❤️ HP Bar", CurrentValue = false, Callback = function(Value) espHP = Value end})

ESPTab:CreateToggle({
    Name = "🌈 Chams",
    CurrentValue = false,
    Callback = function(Value)
        espChams = Value
        if not Value then
            for player, espData in pairs(espPlayers) do
                if espData.chams then
                    for _, part in ipairs(espData.chams) do part:Destroy() end
                    espData.chams = nil
                end
            end
        end
    end
})

ESPTab:CreateToggle({Name = "📍 Tracers", CurrentValue = false, Callback = function(Value) espTracers = Value end})

ESPTab:CreateParagraph({
    Title = "Silent Runners ESP",
    Content = "Boxes: Red = enemy, Green = ally\nName: Player name\nDistance: meters\nHP Bar: Green >50%, Yellow >25%, Red <25%\nChams: See enemies through walls\nTracers: Lines to enemies"
})

MiscTab:CreateToggle({
    Name = "🚪 NoClip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
        if Value then enableNoclip() else disableNoclip() end
    end
})

MiscTab:CreateToggle({
    Name = "🐰 BunnyHop",
    CurrentValue = false,
    Callback = function(Value)
        bunnyHopEnabled = Value
        if Value then enableBunnyHop() else disableBunnyHop() end
    end
})

MiscTab:CreateParagraph({
    Title = "Silent Runners MISC",
    Content = "NoClip: Walk through walls\nBunnyHop: Auto jump + speed 32 studs/s when moving"
})

print("Silent Runners Script: FPS One Tap - Loaded. Silent Runners Team 26.09.2025")
