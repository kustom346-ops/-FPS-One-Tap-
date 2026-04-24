local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Silent Runners | FPS One Tap Rage",
    LoadingTitle = "Silent Runners Injection",
    LoadingSubtitle = "by Silent Runners Team",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "SilentRunnersConfigs",
       FileName = "FPSOneTapRage"
    },
    Discord = {
       Enabled = false,
       Invite = "",
       RememberJoins = false
    },
    KeySystem = false
})

local AimbotTab = Window:CreateTab("🎯 Rage", 4483362458)
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
local MiscTab = Window:CreateTab("⚙️ MISC", 4483362458)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")

local aimbotEnabled = false
local autoShotEnabled = false
local wallCheckEnabled = true
local aimPart = "Head"
local aimbotFOV = 360

local espEnabled = false
local espBoxes = false
local espDistance = false
local espHP = false
local espName = false
local espChams = false
local espTracers = false
local espPlayers = {}

local speedHackEnabled = false
local speedValue = 50
local noclipEnabled = false
local noclipConnection = nil
local speedHackConnection = nil

local function isTargetVisible(targetCharacter, targetPart)
    if not wallCheckEnabled then return true end
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

local function getNearestEnemy()
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

        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
        local distanceFromCenter = (screenPos2D - screenCenter).Magnitude
        local maxFOVDistance = (Camera.ViewportSize.Y / 2) * (aimbotFOV / 90)

        if distanceFromCenter > maxFOVDistance then continue end

        if not isTargetVisible(character, targetPart) then continue end

        local distance = (Camera.CFrame.Position - targetPart.Position).Magnitude

        if distance < nearestDistance then
            nearestDistance = distance
            nearestEnemy = {
                player = player,
                character = character,
                targetPart = targetPart,
                distance = distance
            }
        end
    end

    return nearestEnemy
end

local function fireShot()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end

    local enemy = getNearestEnemy()
    if not enemy then return end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemy.targetPart.Position)

    if autoShotEnabled then
        fireShot()
    end
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
                for _, part in ipairs(espData.chams) do
                    part:Destroy()
                end
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
                for _, part in ipairs(espData.chams) do
                    part:Destroy()
                end
                espData.chams = nil
            end
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")

        if not rootPart or not humanoid then
            espData.box.Visible = false
            espData.name.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
            espData.tracer.Visible = false
            if espData.chams then
                for _, part in ipairs(espData.chams) do
                    part:Destroy()
                end
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
                    for _, part in ipairs(espData.chams) do
                        part:Destroy()
                    end
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
                for _, part in ipairs(espData.chams) do
                    part:Destroy()
                end
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
            for _, part in ipairs(espData.chams) do
                part:Destroy()
            end
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
            for _, part in ipairs(espPlayers[player].chams) do
                part:Destroy()
            end
        end
        espPlayers[player] = nil
    end
end)

local function updateSpeed()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            if speedHackEnabled then
                humanoid.WalkSpeed = speedValue
            else
                humanoid.WalkSpeed = 16
            end
        end
    end
end

speedHackConnection = RunService.Heartbeat:Connect(function()
    if speedHackEnabled then updateSpeed() end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    if speedHackEnabled then updateSpeed() end
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

AimbotTab:CreateToggle({
    Name = "🎯 Enable Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        aimbotEnabled = Value
    end
})

AimbotTab:CreateToggle({
    Name = "💀 Auto Shot",
    CurrentValue = false,
    Callback = function(Value)
        autoShotEnabled = Value
    end
})

AimbotTab:CreateToggle({
    Name = "🧱 Wall Check",
    CurrentValue = true,
    Callback = function(Value)
        wallCheckEnabled = Value
    end
})

AimbotTab:CreateDropdown({
    Name = "🎯 Aim Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(Option)
        aimPart = Option
    end
})

AimbotTab:CreateSlider({
    Name = "🔭 FOV",
    Range = {10, 360},
    Increment = 10,
    Suffix = "°",
    CurrentValue = 360,
    Callback = function(Value)
        aimbotFOV = Value
    end
})

AimbotTab:CreateParagraph({
    Title = "Rage Features",
    Content = "Aimbot + Auto Shot = aim and shoot\nOnly Aimbot = only aim"
})

ESPTab:CreateToggle({
    Name = "👁️ Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        espEnabled = Value
        if Value then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    createESPForPlayer(player)
                end
            end
        else
            clearAllESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "📦 Boxes",
    CurrentValue = false,
    Callback = function(Value)
        espBoxes = Value
    end
})

ESPTab:CreateToggle({
    Name = "📛 Name",
    CurrentValue = false,
    Callback = function(Value)
        espName = Value
    end
})

ESPTab:CreateToggle({
    Name = "📏 Distance",
    CurrentValue = false,
    Callback = function(Value)
        espDistance = Value
    end
})

ESPTab:CreateToggle({
    Name = "❤️ HP Bar",
    CurrentValue = false,
    Callback = function(Value)
        espHP = Value
    end
})

ESPTab:CreateToggle({
    Name = "🌈 Chams",
    CurrentValue = false,
    Callback = function(Value)
        espChams = Value
        if not Value then
            for player, espData in pairs(espPlayers) do
                if espData.chams then
                    for _, part in ipairs(espData.chams) do
                        part:Destroy()
                    end
                    espData.chams = nil
                end
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "📍 Tracers",
    CurrentValue = false,
    Callback = function(Value)
        espTracers = Value
    end
})

ESPTab:CreateParagraph({
    Title = "Silent Runners ESP",
    Content = "Boxes: Red = enemy, Green = ally\nName: Player name\nDistance: meters\nHP Bar: Green >50%, Yellow >25%, Red <25%\nChams: See enemies through walls\nTracers: Lines to enemies"
})

MiscTab:CreateToggle({
    Name = "⚡ Speed Hack",
    CurrentValue = false,
    Callback = function(Value)
        speedHackEnabled = Value
        updateSpeed()
    end
})

MiscTab:CreateSlider({
    Name = "🏃 Speed Value",
    Range = {20, 200},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Callback = function(Value)
        speedValue = Value
        if speedHackEnabled then updateSpeed() end
    end
})

MiscTab:CreateToggle({
    Name = "🚪 NoClip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
        if Value then enableNoclip() else disableNoclip() end
    end
})

MiscTab:CreateParagraph({
    Title = "Silent Runners MISC",
    Content = "Speed Hack: Anti-cheat bypass\nSpeed: 20 to 200 studs/s\nNoClip: Walk through walls"
})

print("Silent Runners Rage Script: FPS One Tap - Loaded. Silent Runners Team 26.09.2025")
