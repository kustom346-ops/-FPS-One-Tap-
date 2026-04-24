--[[
SWILL RAGE SCRIPT | FPS One Tap Place
Библиотека: Rayfield (Sirius Menu)
Дата создания скрипта: 26.09.2025
Команда: Swill Way
Протокол SWILL: только полный рабочий ответ
]]--

-- 1. Загрузка Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 2. Создание окна
local Window = Rayfield:CreateWindow({
    Name = "SWILL | FPS One Tap Rage",
    LoadingTitle = "Swill Way Injection",
    LoadingSubtitle = "by Swill Way Team",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "SwillConfigs",
       FileName = "FPSOneTapRage"
    },
    Discord = {
       Enabled = false,
       Invite = "",
       RememberJoins = false
    },
    KeySystem = false
})

-- 3. Вкладки
local AimbotTab = Window:CreateTab("🎯 Rage Aimbot", 4483362458)
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
local MiscTab = Window:CreateTab("⚙️ MISC", 4483362458)

-- 4. Сервисы
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

-- 5. Переменные состояний
local aimbotEnabled = false
local autoShotEnabled = false
local wallCheckEnabled = true
local aimPart = "Head"
local aimbotFOV = 360

local espEnabled = false
local espBoxes = false
local espDistance = false
local espHP = false
local espPlayers = {}

-- MISC переменные
local speedHackEnabled = false
local speedValue = 50
local noclipEnabled = false
local noclipConnection = nil
local speedHackConnection = nil

-- 6. Wall Check
local function isTargetVisible(targetCharacter, targetPart)
    if not wallCheckEnabled then
        return true
    end
    
    if not targetCharacter or not targetPart then
        return false
    end
    
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
    
    if not raycastResult then
        return true
    end
    
    local hitPart = raycastResult.Instance
    local hitCharacter = hitPart.Parent
    
    if hitCharacter == targetCharacter then
        return true
    end
    
    local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
    if hitPlayer then
        return false
    end
    
    return false
end

-- 7. Поиск ближайшего врага
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

        if not isTargetVisible(character, targetPart) then
            continue
        end

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

-- 8. Функция выстрела
local function fireShot()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- 9. Main Aimbot Loop
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end

    local enemy = getNearestEnemy()
    if not enemy then return end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemy.targetPart.Position)

    if autoShotEnabled then
        fireShot()
    end
end)

-- 10. ESP Система
local function createESPForPlayer(player)
    if espPlayers[player] then return end

    local espData = {
        box = Drawing.new("Square"),
        distance = Drawing.new("Text"),
        hpBar = Drawing.new("Line"),
        hpBackground = Drawing.new("Line")
    }

    espData.box.Visible = false
    espData.box.Thickness = 2
    espData.box.Color = Color3.new(1, 0, 0)
    espData.box.Filled = false
    espData.box.Transparency = 1

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

    espPlayers[player] = espData

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then
            espData.box:Remove()
            espData.distance:Remove()
            espData.hpBar:Remove()
            espData.hpBackground:Remove()
            connection:Disconnect()
            espPlayers[player] = nil
            return
        end

        local character = player.Character
        if not character then
            espData.box.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")

        if not rootPart or not humanoid then
            espData.box.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
            return
        end

        local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if onScreen and espEnabled then
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
        else
            espData.box.Visible = false
            espData.distance.Visible = false
            espData.hpBar.Visible = false
            espData.hpBackground.Visible = false
        end
    end)
end

local function clearAllESP()
    for player, espData in pairs(espPlayers) do
        espData.box:Remove()
        espData.distance:Remove()
        espData.hpBar:Remove()
        espData.hpBackground:Remove()
    end
    espPlayers = {}
end

-- 11. Отслеживание игроков
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
        espPlayers[player].distance:Remove()
        espPlayers[player].hpBar:Remove()
        espPlayers[player].hpBackground:Remove()
        espPlayers[player] = nil
    end
end)

-- 12. MISC: Спидхак с обходом античита
local function updateSpeed()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            if speedHackEnabled then
                -- Обход античита: меняем WalkSpeed напрямую
                pcall(function()
                    humanoid.WalkSpeed = speedValue
                end)
            else
                -- Возвращаем стандартную скорость
                pcall(function()
                    humanoid.WalkSpeed = 16
                end)
            end
        end
    end
end

-- Периодическое обновление скорости (обход античита, который сбрасывает скорость)
speedHackConnection = RunService.Heartbeat:Connect(function()
    if speedHackEnabled then
        updateSpeed()
    end
end)

-- При респавне обновляем скорость
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    if speedHackEnabled then
        updateSpeed()
    end
end)

-- 13. MISC: Ноуклип (ходить сквозь стены, без полёта)
local function enableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    
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

-- При респавне перезапускаем ноуклип
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    if noclipEnabled then
        disableNoclip()
        enableNoclip()
    end
end)

-- 14. GUI: Rage Aimbot
AimbotTab:CreateToggle({
    Name = "🎯 Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        aimbotEnabled = Value
    end
})

AimbotTab:CreateToggle({
    Name = "💀 Auto Shot",
    CurrentValue = false,
    Flag = "AutoShotToggle",
    Callback = function(Value)
        autoShotEnabled = Value
    end
})

AimbotTab:CreateToggle({
    Name = "🧱 Wall Check",
    CurrentValue = true,
    Flag = "WallCheckToggle",
    Callback = function(Value)
        wallCheckEnabled = Value
    end
})

AimbotTab:CreateDropdown({
    Name = "🎯 Aim Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Flag = "AimPartDropdown",
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
    Flag = "FOVSlider",
    Callback = function(Value)
        aimbotFOV = Value
    end
})

AimbotTab:CreateParagraph({
    Title = "⚙️ Настройки",
    Content = [[
Smoothing: 0 (Rage) - Мгновенная наводка
Wall Check: 🧱 Игнорирует цели за стенами
Auto Shot: 💀 Автострельба при наводке

Режимы:
AIMBOT = Только наводка
AIMBOT + AUTO SHOT = Наводка + Стрельба
    ]]
})

-- 15. GUI: ESP
ESPTab:CreateToggle({
    Name = "👁️ Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
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
    Flag = "BoxesToggle",
    Callback = function(Value)
        espBoxes = Value
    end
})

ESPTab:CreateToggle({
    Name = "📏 Distance",
    CurrentValue = false,
    Flag = "DistanceToggle",
    Callback = function(Value)
        espDistance = Value
    end
})

ESPTab:CreateToggle({
    Name = "❤️ HP Bar",
    CurrentValue = false,
    Flag = "HPToggle",
    Callback = function(Value)
        espHP = Value
    end
})

ESPTab:CreateParagraph({
    Title = "💀 SWILL ESP",
    Content = [[
📦 Boxes: Красные = враги, Зеленые = союзники
📏 Distance: Дистанция в метрах
❤️ HP Bar: Зеленый >50%, Желтый >25%, Красный <25%
    ]]
})

-- 16. GUI: MISC
MiscTab:CreateToggle({
    Name = "⚡ Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHackToggle",
    Callback = function(Value)
        speedHackEnabled = Value
        if Value then
            updateSpeed()
        else
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    pcall(function()
                        humanoid.WalkSpeed = 16
                    end)
                end
            end
        end
    end
})

MiscTab:CreateSlider({
    Name = "🏃 Speed Value",
    Range = {20, 200},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Flag = "SpeedSlider",
    Callback = function(Value)
        speedValue = Value
        if speedHackEnabled then
            updateSpeed()
        end
    end
})

MiscTab:CreateToggle({
    Name = "🚪 NoClip (Walk Through Walls)",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        noclipEnabled = Value
        if Value then
            enableNoclip()
        else
            disableNoclip()
        end
    end
})

MiscTab:CreateParagraph({
    Title = "⚙️ MISC Features",
    Content = [[
⚡ Speed Hack: Обход античита через Heartbeat
🏃 Speed: От 20 до 200 studs/s
🚪 NoClip: Ходьба сквозь стены (без полёта)

Анти-античит:
Speed Hack использует Heartbeat обновление
NoClip отключает CanCollide каждый кадр
Оба обходят базовый античит
    ]]
})

-- 17. Автостарт
task.wait(0.5)
aimbotEnabled = true
autoShotEnabled = false
wallCheckEnabled = true
espEnabled = true
espBoxes = true
espDistance = true
espHP = true
-- MISC по умолчанию выключены для безопасности

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPForPlayer(player)
    end
end

print("SWILL Rage Script: FPS One Tap - FULL PACK (Aimbot + ESP + MISC). Swill Way 26.09.2025")