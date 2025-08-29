local shared = odh_shared_plugins
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local speed_glitch_section = shared.AddSection("Auto Speed Glitch")

local speed_glitch_enabled = false
local horizontal_only = false
local speed_slider_value = 0
local default_speed = 16

local character, humanoid, rootPart
local is_in_air = false

local function onCharacterAdded(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
            is_in_air = true
        else
            is_in_air = false
        end
    end)
end

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

speed_glitch_section:AddToggle("Enable ASG", function(enabled)
    speed_glitch_enabled = enabled
end)

speed_glitch_section:AddToggle("Sideways Only", function(enabled)
    horizontal_only = enabled
end)

speed_glitch_section:AddSlider("Speed (0–255)", 0, 255, 0, function(value)
    speed_slider_value = value
end)

RunService.Stepped:Connect(function()
    if not isMobile() then return end
    if not speed_glitch_enabled then return end
    if not character or not humanoid or not rootPart then return end

    local final_speed = default_speed + speed_slider_value

    if is_in_air then
        if horizontal_only then
            local moveDir = humanoid.MoveDirection
            local rightDir = rootPart.CFrame.RightVector
            local horizontalAmount = moveDir:Dot(rightDir)

            if math.abs(horizontalAmount) > 0.5 then
                humanoid.WalkSpeed = final_speed
            else
                humanoid.WalkSpeed = default_speed
            end
        else
            humanoid.WalkSpeed = final_speed
        end
    else
        humanoid.WalkSpeed = default_speed
    end
end)

local map_voter_section = shared.AddSection("Map Voter")

local savedPosition = nil
local respawning = false
local selectedRespawnAmount = 12

map_voter_section:AddSlider("Votes Amount", 1, 20, selectedRespawnAmount, function(value)
    selectedRespawnAmount = value
end)

map_voter_section:AddButton("Vote Map", function()
    local player = game.Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    savedPosition = player.Character.HumanoidRootPart.Position
    respawning = true
    local respawnCount = 0
    local maxRespawns = selectedRespawnAmount

    task.spawn(function()
        while respawnCount < maxRespawns and respawning do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = 0
                respawnCount += 1
            end
            task.wait(0.3)
        end

        respawning = false
        savedPosition = nil
    end)

    player.CharacterAdded:Connect(function(char)
        if savedPosition then
            char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(savedPosition)
        end
    end)
end)

local whitelist = {}

local whitelist_section = shared.AddSection("Whitelist")
whitelist_section:AddLabel("Ignores WL Players")

whitelist_section:AddPlayerDropdown("Whitelist Player", function(player)
    if not table.find(whitelist, player.UserId) then
        table.insert(whitelist, player.UserId)
        shared.Notify(player.Name .. " has been whitelisted.", 2)
    else
        shared.Notify(player.Name .. " is already whitelisted.", 2)
    end
end)

whitelist_section:AddPlayerDropdown("Unwhitelist Player", function(player)
    for i, id in ipairs(whitelist) do
        if id == player.UserId then
            table.remove(whitelist, i)
            shared.Notify(player.Name .. " has been removed from the whitelist.", 2)
            break
        end
    end
end)

whitelist_section:AddButton("Clear Whitelist", function()
    whitelist = {}
    shared.Notify("Whitelist has been cleared.", 2)
end)

whitelist_section:AddButton("Kill All", function()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local knife = backpack and backpack:FindFirstChild("Knife")
    
    if not knife then
        shared.Notify("Knife not found in your inventory!", 2)
        return
    end

    knife.Parent = LocalPlayer.Character

    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local offsetDistance = -2

    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local toNoClip = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not table.find(whitelist, player.UserId) then
            local char = player.Character
            if char and char.PrimaryPart then
                local targetPos = root.CFrame * CFrame.new(0, 0, offsetDistance)
                char:SetPrimaryPartCFrame(targetPos)
                table.insert(toNoClip, char)

                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end

    local startTime = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if tick() - startTime > 3 then
            conn:Disconnect()

            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end

            for _, char in pairs(toNoClip) do
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            return
        end

        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        for _, char in pairs(toNoClip) do
            if char and char.PrimaryPart then
                local freezePos = root.CFrame * CFrame.new(0, 0, offsetDistance)
                char:SetPrimaryPartCFrame(freezePos)

                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

local shared = odh_shared_plugins

local my_own_section = shared.AddSection("Trickshot")

my_own_section:AddLabel("Spin On Next Jump")

my_own_section:AddSlider("Spin Speed (1-30)", 1, 30, 15, function(spinSpeed)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local hasJumped = false
    local spinStopped = false

    local function startSpin()
        for _, obj in ipairs(hrp:GetChildren()) do
            if obj:IsA("Torque") or obj:IsA("Attachment") then
                obj:Destroy()
            end
        end
        
        local attachment = Instance.new("Attachment", hrp)
        local torque = Instance.new("Torque")
        torque.Attachment0 = attachment
        torque.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
        torque.Torque = Vector3.new(0, spinSpeed * 10000, 0)
        torque.Parent = hrp

        game:GetService("RunService").Heartbeat:Connect(function()
            if not character:FindFirstChild("HumanoidRootPart") then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            if hasJumped and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                if spinStopped then
                    spinStopped = false
                    torque:Destroy()
                end
            end
        end)
    end
    
    local function resetAndPrepareForSpin()
        hasJumped = false
        spinStopped = false
    end
    
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if not hasJumped then
            hasJumped = true
            startSpin()
        end
    end)
    
    hrp.Touched:Connect(function(hit)
        if hit and hit:IsA("BasePart") and not spinStopped then
            spinStopped = true
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("Torque") then
                    obj:Destroy()
                end
            end
        end
    end)

    my_own_section:AddButton("Activate", function()
        resetAndPrepareForSpin()
    end)
end)

local shared = odh_shared_plugins

local my_own_section = shared.AddSection("Dual Effect")
my_own_section:AddLabel("Must Own Dual Effect")

local toggle_enabled = false
local connection

my_own_section:AddToggle("Auto Equip Dual Effect", function(enabled)
    toggle_enabled = enabled

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RoleSelect = ReplicatedStorage.Remotes.Gameplay.RoleSelect
    local Equip = ReplicatedStorage.Remotes.Inventory.Equip

    if connection then
        connection:Disconnect()
        connection = nil
    end

    if enabled then
        connection = RoleSelect.OnClientEvent:Connect(function(...)
            local args = { ... }

            if args[1] == "Murderer" then
                Equip:FireServer("Dual", "Effects")

                task.delay(18, function()
                    if toggle_enabled then
                        Equip:FireServer("Electric", "Effects")
                    end
                end)
            end
        end)
    end
end)

local shared = odh_shared_plugins

local my_own_section = shared.AddSection("Disable Trading")

my_own_section:AddLabel("Turn Off & Rejoin To Trade Again")

my_own_section:AddToggle("Decline Trades", function(isToggled)
    if isToggled then
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        
        local SendRequest = ReplicatedStorage.Trade.SendRequest -- RemoteFunction
        local DeclineRequest = ReplicatedStorage.Trade.DeclineRequest -- RemoteEvent

        SendRequest.OnClientInvoke = function(player)
            DeclineRequest:FireServer()
        end
        
    else
    end
end)
