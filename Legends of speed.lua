local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Создание окна
local Window = Rayfield:CreateWindow({
    Name = "Silent Runners | Legends of Speed",
    LoadingTitle = "SILENT RUNNERS FARM",
    LoadingSubtitle = "by Silent Runners TEAM",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

-- Вкладки
local FarmTab = Window:CreateTab("🌀 Orb Farm", 4483362458)
local MiscTab = Window:CreateTab("⚡ Misc", 4483362458)

-- Переменные
local orbFarmEnabled = false
local autoRebirthEnabled = false
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Функция: сбор всех орбов к игроку
local function collectAllOrbs()
    task.spawn(function()
        while orbFarmEnabled do
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant.Name == "Orb" or descendant.Name == "SpeedOrb" or descendant.Name == "Gem" or descendant.Name == "Coin" then
                    if descendant:IsA("BasePart") or descendant:IsA("MeshPart") or descendant:IsA("Part") then
                        descendant.CFrame = rootPart.CFrame + Vector3.new(0, 3, 0)
                        descendant.Velocity = Vector3.new(0, 0, 0)
                        descendant.Anchored = false
                    end
                end
                if descendant:IsA("Model") and (descendant.Name:find("Orb") or descendant.Name:find("orb") or descendant.Name:find("Gem") or descendant.Name:find("Coin")) then
                    for _, part in pairs(descendant:GetDescendants()) do
                        if part:IsA("BasePart") or part:IsA("MeshPart") then
                            descendant:PivotTo(rootPart.CFrame * CFrame.new(0, 3, 0))
                            break
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

-- Функция: авторебёрс
local function performAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            local rebirthScreen = player.PlayerGui:FindFirstChild("RebirthGui") or player.PlayerGui:FindFirstChild("PrestigeGui")
            if rebirthScreen then
                local rebirthActivate = rebirthScreen:FindFirstChild("RebirthButton") or rebirthScreen:FindFirstChild("Button") or rebirthScreen:FindFirstChild("PrestigeButton")
                if rebirthActivate and (rebirthActivate:IsA("TextButton") or rebirthActivate:IsA("ImageButton")) then
                    firesignal(rebirthActivate.MouseButton1Click)
                    task.wait(0.5)
                end
            end
            for _, guiElement in pairs(player.PlayerGui:GetDescendants()) do
                if guiElement.Name:lower():find("rebirth") and guiElement:IsA("TextButton") then
                    firesignal(guiElement.MouseButton1Click)
                    task.wait(0.5)
                end
            end
            task.wait(1)
        end
    end)
end

-- Тоггл: орб фарм
local orbCollectToggle = FarmTab:CreateToggle({
    Name = "Collect All Orbs To Player",
    CurrentValue = false,
    Flag = "OrbCollectActive",
    Callback = function(state)
        orbFarmEnabled = state
        if orbFarmEnabled then
            collectAllOrbs()
        end
    end,
})

-- Тоггл: авторебёрс
local autoRebirthToggle = FarmTab:CreateToggle({
    Name = "Auto Rebirth System",
    CurrentValue = false,
    Flag = "RebirthActive",
    Callback = function(state)
        autoRebirthEnabled = state
        if autoRebirthEnabled then
            performAutoRebirth()
        end
    end,
})

-- Слайдер скорости
MiscTab:CreateSlider({
    Name = "Movement Speed",
    Range = {16, 500},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "MoveSpeedValue",
    Callback = function(value)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = value
        end
    end,
})

-- Слайдер прыжка
MiscTab:CreateSlider({
    Name = "Leap Power",
    Range = {50, 500},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "LeapPowerValue",
    Callback = function(value)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = value
        end
    end,
})

-- Телепорт на финиш
MiscTab:CreateButton({
    Name = "Warp to Finish Line",
    Callback = function()
        local finishMarker = workspace:FindFirstChild("Finish") or workspace:FindFirstChild("End") or workspace:FindFirstChild("FinishLine")
        if finishMarker then
            if finishMarker:IsA("BasePart") then
                character:MoveTo(finishMarker.Position)
            elseif finishMarker:IsA("Model") and finishMarker.PrimaryPart then
                character:MoveTo(finishMarker.PrimaryPart.Position)
            end
        else
            local checkpointFolder = workspace:FindFirstChild("Stages") or workspace:FindFirstChild("Checkpoints")
            if checkpointFolder then
                local finalCheckpoint = nil
                for _, point in pairs(checkpointFolder:GetChildren()) do
                    finalCheckpoint = point
                end
                if finalCheckpoint and finalCheckpoint:IsA("BasePart") then
                    character:MoveTo(finalCheckpoint.Position)
                end
            end
        end
    end,
})

-- Автосбор по радиусу
local radiusCollectEnabled = false
local collectionRadius = 100

MiscTab:CreateToggle({
    Name = "Radius Collection System",
    CurrentValue = false,
    Flag = "RadiusCollectActive",
    Callback = function(state)
        radiusCollectEnabled = state
        if radiusCollectEnabled then
            task.spawn(function()
                while radiusCollectEnabled do
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                            if obj.Name:find("Orb") or obj.Name:find("orb") or obj.Name:find("Gem") or obj.Name:find("Coin") or obj.Name:find("Collect") then
                                local distance = (obj.Position - rootPart.Position).Magnitude
                                if distance <= collectionRadius then
                                    obj.CFrame = rootPart.CFrame
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

MiscTab:CreateSlider({
    Name = "Collection Radius",
    Range = {10, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 100,
    Flag = "RadiusValue",
    Callback = function(value)
        collectionRadius = value
    end,
})

-- Обновление персонажа при респауне
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    rootPart = character:WaitForChild("HumanoidRootPart")
    task.wait(1)
    local savedSpeed = Rayfield.Flags["MoveSpeedValue"]
    local savedJump = Rayfield.Flags["LeapPowerValue"]
    if savedSpeed and savedSpeed.CurrentValue and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = savedSpeed.CurrentValue
    end
    if savedJump and savedJump.CurrentValue and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = savedJump.CurrentValue
    end
end)

print("Silent Runners TEAM | Legends of Speed Farm - ACTIVE")