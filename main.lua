--// AUTOFARM SCRIPT - FULLY WORKING WITH RAYFIELD
--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// BOOT RAYFIELD LIBRARY
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// CREATE RAYFIELD WINDOW
local Window = Rayfield:CreateWindow({
    Name = "⚔️ Autofarm Hub",
    Icon = 0,
    LoadingTitle = "Autofarm Interface",
    LoadingSubtitle = "Loading farming modules...",
    Theme = "Default",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutofarmConfig",
        FileName = "AutofarmSettings"
    },
    Discord = {Enabled = false},
    KeySystem = false
})

--// PLAYER SETUP
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    print("✅ Character reloaded")
end)

--// GAME FOLDERS
local EnemiesFolder = workspace:WaitForChild("Enemies")

--// REMOTE EVENTS
local RS = game:GetService("ReplicatedStorage")
local CombatRemote = RS:WaitForChild("Net"):WaitForChild("Events"):WaitForChild("Combat")
local LootRemote = RS:WaitForChild("Net"):WaitForChild("Events"):WaitForChild("LootDrop")
local StatRemote = RS:WaitForChild("Net"):WaitForChild("Events"):WaitForChild("StatChange")

--// LEADERSTATS HANDLING
local leaderstats = nil
local function getLeaderstats()
    if not leaderstats then
        leaderstats = player:FindFirstChild("leaderstats") or 
                     player:FindFirstChild("Stats") or 
                     player:FindFirstChild("stats") or 
                     player:FindFirstChild("PlayerStats")
    end
    return leaderstats
end
getLeaderstats()

--// CONFIGURATION
local config = {
    autofarm = false,
    useAbility = true,
    lootEnabled = true,
    autoStat = false,
    selectedEnemyName = nil,
    selectedStat = "Damage",
    attackDelay = 0.2,
    abilityCooldown = 3,
    lootDelay = 0.4,
    statDelay = 0.5,
    orbitRadius = 12,
    orbitSpeed = 1.5,
    undergroundDepth = -3,
    maxTargetDistance = 100,
    attackRange = 25
}

-- Timing trackers
local lastAttack, lastAbility, lastLoot, lastStat = 0, 0, 0, 0
local orbitAngle = 0

--// CREATE TABS
local FarmingTab = Window:CreateTab("Farming", "swords")
local LootTab = Window:CreateTab("Loot", "coins")
local StatsTab = Window:CreateTab("Stats", "trending-up")
local SettingsTab = Window:CreateTab("Settings", "settings")

--// FARMING TAB
FarmingTab:CreateSection("Farming Controls")

local AutofarmToggle = FarmingTab:CreateToggle({
    Name = "🚀 Enable Autofarm",
    CurrentValue = config.autofarm,
    Flag = "AutofarmToggle",
    Callback = function(Value)
        config.autofarm = Value
        Rayfield:Notify({
            Title = "Autofarm",
            Content = Value and "Autofarming ENABLED!" or "Autofarming DISABLED!",
            Duration = 3
        })
    end
})

local AbilityToggle = FarmingTab:CreateToggle({
    Name = "⚡ Use Ability Attacks",
    CurrentValue = config.useAbility,
    Flag = "AbilityToggle",
    Callback = function(Value)
        config.useAbility = Value
    end
})

-- Enemy dropdown with live enemy list
local function updateEnemyList()
    local enemyOptions = {}
    for _, enemy in pairs(EnemiesFolder:GetChildren()) do
        if enemy:IsA("Model") then
            table.insert(enemyOptions, enemy.Name)
        end
    end
    if #enemyOptions == 0 then
        table.insert(enemyOptions, "No enemies found")
    end
    return enemyOptions
end

local enemyOptions = updateEnemyList()
config.selectedEnemyName = tostring(enemyOptions[1])

local EnemyDropdown = FarmingTab:CreateDropdown({
    Name = "🎯 Target Enemy",
    Options = enemyOptions,
    CurrentOption = config.selectedEnemyName,
    Flag = "EnemyDropdown",
    Callback = function(Option)
        config.selectedEnemyName = tostring(Option)
    end
})

-- Sliders
local AttackSpeedSlider = FarmingTab:CreateSlider({
    Name = "⚡ Attack Speed",
    Range = {0.1, 1.0},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = config.attackDelay,
    Flag = "AttackSpeed",
    Callback = function(Value)
        config.attackDelay = Value
    end
})

local OrbitSlider = FarmingTab:CreateSlider({
    Name = "🔄 Orbit Radius",
    Range = {8, 25},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = config.orbitRadius,
    Flag = "OrbitRadius",
    Callback = function(Value)
        config.orbitRadius = Value
    end
})

local AttackRangeSlider = FarmingTab:CreateSlider({
    Name = "🎯 Attack Range",
    Range = {15, 50},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = config.attackRange,
    Flag = "AttackRange",
    Callback = function(Value)
        config.attackRange = Value
    end
})

FarmingTab:CreateSection("Status")
local StatusLabel = FarmingTab:CreateLabel("🔴 Status: Ready")

--// LOOT TAB
LootTab:CreateSection("Loot Collection")

local LootToggle = LootTab:CreateToggle({
    Name = "💰 Enable Loot Aura",
    CurrentValue = config.lootEnabled,
    Flag = "LootToggle",
    Callback = function(Value)
        config.lootEnabled = Value
    end
})

local LootDelaySlider = LootTab:CreateSlider({
    Name = "⏱️ Loot Speed",
    Range = {0.2, 2.0},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = config.lootDelay,
    Flag = "LootDelay",
    Callback = function(Value)
        config.lootDelay = Value
    end
})

--// STATS TAB
StatsTab:CreateSection("Auto-Stat Upgrades")

local StatToggle = StatsTab:CreateToggle({
    Name = "📈 Enable Auto-Stat",
    CurrentValue = config.autoStat,
    Flag = "StatToggle",
    Callback = function(Value)
        config.autoStat = Value
    end
})

local StatDropdown = StatsTab:CreateDropdown({
    Name = "📊 Stat to Upgrade",
    Options = {"Damage", "Defence", "Health"},
    CurrentOption = config.selectedStat,
    Flag = "StatDropdown",
    Callback = function(Option)
        config.selectedStat = tostring(Option)
    end
})

local StatDelaySlider = StatsTab:CreateSlider({
    Name = "⏱️ Upgrade Delay",
    Range = {0.3, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = config.statDelay,
    Flag = "StatDelay",
    Callback = function(Value)
        config.statDelay = Value
    end
})

StatsTab:CreateSection("Stat Info")
local StatInfoLabel = StatsTab:CreateLabel("Searching for stats...")

--// SETTINGS TAB
SettingsTab:CreateSection("Interface")

local ThemeDropdown = SettingsTab:CreateDropdown({
    Name = "🎨 Interface Theme",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = "Default",
    Flag = "Theme",
    Callback = function(Option)
        Window:SetTheme(Option)
    end
})

local UndergroundDepthSlider = SettingsTab:CreateSlider({
    Name = "⬇️ Orbit Height",
    Range = {-10, 10},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = config.undergroundDepth,
    Flag = "UndergroundDepth",
    Callback = function(Value)
        config.undergroundDepth = Value
    end
})

local OrbitSpeedSlider = SettingsTab:CreateSlider({
    Name = "🌀 Orbit Speed",
    Range = {0.5, 5},
    Increment = 0.5,
    Suffix = " speed",
    CurrentValue = config.orbitSpeed,
    Flag = "OrbitSpeed",
    Callback = function(Value)
        config.orbitSpeed = Value
    end
})

--// CORE FUNCTIONS
local function isValidEnemy(enemy)
    if not enemy or not enemy:IsA("Model") then return false end
    local humanoid = enemy:FindFirstChild("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    return humanoid and humanoid.Health > 0 and root
end

local function findBestEnemy()
    if not config.selectedEnemyName then return nil end
    local best = nil
    local closest = config.maxTargetDistance
    local pos = hrp.Position

    for _, enemy in pairs(EnemiesFolder:GetChildren()) do
        if enemy.Name == tostring(config.selectedEnemyName) and isValidEnemy(enemy) then
            local root = enemy.HumanoidRootPart
            local dist = (pos - root.Position).Magnitude
            if dist < closest then
                closest = dist
                best = enemy
            end
        end
    end

    return best, closest
end

-- ATTACK
local function performAttack(enemy)
    if not enemy then return false end
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local dist = (hrp.Position - root.Position).Magnitude
    if dist > config.attackRange then
        return false
    end

    local success = pcall(function()
        CombatRemote:FireServer("s", "Attack", 28)
    end)

    return success
end

-- ABILITY
local function performAbility(enemy)
    if not enemy then return false end
    local success = pcall(function()
        CombatRemote:FireServer("s", "swirling_slash", 33)
    end)
    return success
end

-- ORBIT MOVEMENT
RunService.Heartbeat:Connect(function(dt)
    if not config.autofarm then return end

    local enemy, dist = findBestEnemy()
    if not enemy then
        StatusLabel:Set("🔴 No enemy found")
        return
    end

    local root = enemy:FindFirstChild("HumanoidRootPart")
    if not root then
        StatusLabel:Set("🔴 Enemy missing root")
        return
    end

    orbitAngle += config.orbitSpeed * dt

    local orbitX = math.cos(orbitAngle) * config.orbitRadius
    local orbitZ = math.sin(orbitAngle) * config.orbitRadius

    local targetPos = root.Position + Vector3.new(orbitX, config.undergroundDepth, orbitZ)

    hrp.CFrame = CFrame.new(targetPos, root.Position)

    if dist <= config.attackRange then
        StatusLabel:Set("🟢 In range: " .. tostring(enemy.Name))
    else
        StatusLabel:Set("🟡 Moving to: " .. tostring(enemy.Name))
    end
end)

-- COMBAT LOOP
task.spawn(function()
    while true do
        if config.autofarm then
            local enemy, dist = findBestEnemy()

            if enemy then
                local now = tick()

                if now - lastAttack >= config.attackDelay then
                    performAttack(enemy)
                    lastAttack = now
                end

                if config.useAbility and now - lastAbility >= config.abilityCooldown then
                    performAbility(enemy)
                    lastAbility = now
                end
            end
        end
        task.wait(0.05)
    end
end)

-- LOOT LOOP
task.spawn(function()
    while true do
        if config.lootEnabled then
            local now = tick()
            if now - lastLoot >= config.lootDelay then
                pcall(function()
                    LootRemote:FireServer(1)
                end)
                lastLoot = now
            end
        end
        task.wait(0.1)
    end
end)

-- STAT LOOP
task.spawn(function()
    while true do
        if config.autoStat then
            local now = tick()
            if now - lastStat >= config.statDelay then
                local ls = getLeaderstats()
                if ls then
                    local statObj = ls:FindFirstChild(config.selectedStat)
                    if statObj then
                        pcall(function()
                            StatRemote:FireServer("a", config.selectedStat, 1)
                        end)
                    end
                end
                lastStat = now
            end
        end
        task.wait(0.5)
    end
end)

-- AUTO-SELECT FIRST ENEMY
task.wait(1)
if config.selectedEnemyName == "No enemies found" then
    for _, enemy in pairs(EnemiesFolder:GetChildren()) do
        if enemy:IsA("Model") then
            config.selectedEnemyName = enemy.Name
            EnemyDropdown:Set(enemy.Name)
            break
        end
    end
end

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "Autofarm Hub v5.0",
    Content = "Loaded successfully!",
    Duration = 5
})

print("Autofarm Loaded")
