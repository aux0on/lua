-- =========================
-- Auto Speed Glitch
-- =========================
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

-- =========================
-- Map Voter
-- =========================
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

-- =========================
-- Whitelist + Kill All
-- =========================
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

-- =========================
-- Trickshot + TS Button
-- =========================
do
    local shared = odh_shared_plugins
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local spinSpeed = 15
    local hasJumped = false
    local spinStopped = false
    local active = false
    local connections = {}

    -- UI refs
    local guiEnabled = false
    local tsGui
    local tsButton
    local tsButtonSize = 40 -- default size

    local function clearConnections()
        for _, c in ipairs(connections) do
            c:Disconnect()
        end
        table.clear(connections)
    end

    local function setupSpin(character)
        local hrp = character:WaitForChild("HumanoidRootPart")

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

            table.insert(connections, RunService.Heartbeat:Connect(function()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end
                if hasJumped and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    if spinStopped then
                        spinStopped = false
                        torque:Destroy()
                    end
                end
            end))
        end

        table.insert(connections, UserInputService.JumpRequest:Connect(function()
            if active and not hasJumped then
                hasJumped = true
                startSpin()
            end
        end))

        table.insert(connections, hrp.Touched:Connect(function(hit)
            if active and hit:IsA("BasePart") and not spinStopped then
                spinStopped = true
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("Torque") then
                        obj:Destroy()
                    end
                end
            end
        end))
    end

    local function createGuiButton()
        if tsGui then tsGui:Destroy() end

        tsGui = Instance.new("ScreenGui")
        tsGui.Name = "TSGui"
        tsGui.ResetOnSpawn = false
        tsGui.Parent = player:WaitForChild("PlayerGui")

        tsButton = Instance.new("TextButton")
        tsButton.Name = "TSButton"
        tsButton.Text = "TS"
        tsButton.Font = Enum.Font.SourceSansBold
        tsButton.TextSize = tsButtonSize / 2
        tsButton.TextColor3 = Color3.new(1, 1, 1)
        tsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tsButton.Size = UDim2.new(0, tsButtonSize, 0, tsButtonSize)
        tsButton.Position = UDim2.new(0.5, -tsButtonSize/2, 0.8, 0)
        tsButton.AnchorPoint = Vector2.new(0.5, 0.5)
        tsButton.Parent = tsGui

        local uicorner = Instance.new("UICorner", tsButton)
        uicorner.CornerRadius = UDim.new(1, 0)

        tsButton.MouseButton1Click:Connect(function()
            hasJumped = false
            spinStopped = false
            active = true
        end)

        -- draggable (pc + mobile)
        local dragging = false
        local dragStart, startPos

        local function inputBegan(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = tsButton.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end

        local function inputChanged(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                tsButton.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end

        tsButton.InputBegan:Connect(inputBegan)
        tsButton.InputChanged:Connect(inputChanged)
    end

    local my_own_section = shared.AddSection("Trickshot")
    my_own_section:AddLabel("Spin On Next Jump")

    my_own_section:AddSlider("Spin Speed (1-30)", 1, 30, 15, function(value)
        spinSpeed = value
    end)

    my_own_section:AddButton("Activate", function()
        hasJumped = false
        spinStopped = false
        active = true
    end)

    my_own_section:AddToggle("Enable TS GUI Button", function(enabled)
        guiEnabled = enabled
        if guiEnabled then
            createGuiButton()
        else
            if tsGui then tsGui:Destroy() end
        end
    end)

    my_own_section:AddSlider("TS GUI Button Size", 30, 150, tsButtonSize, function(size)
        tsButtonSize = size
        if tsButton then
            tsButton.Size = UDim2.new(0, tsButtonSize, 0, tsButtonSize)
            tsButton.TextSize = tsButtonSize / 2
        end
    end)

    player.CharacterAdded:Connect(function(char)
        clearConnections()
        setupSpin(char)
    end)
    if player.Character then
        setupSpin(player.Character)
    end
end

-- =========================
-- Dual Effect
-- =========================
do
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
end

-- =========================
-- Disable Trading
-- =========================
do
    local shared = odh_shared_plugins
    local my_own_section = shared.AddSection("Disable Trading")
    my_own_section:AddLabel("Turn Off & Rejoin To Trade Again")

    my_own_section:AddToggle("Decline Trades", function(isToggled)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local SendRequest = ReplicatedStorage.Trade.SendRequest -- RemoteFunction
        local DeclineRequest = ReplicatedStorage.Trade.DeclineRequest -- RemoteEvent

        if isToggled then
            SendRequest.OnClientInvoke = function(player)
                DeclineRequest:FireServer()
            end
        else
            -- optional: restore default behavior by clearing the hook
            SendRequest.OnClientInvoke = nil
        end
    end)
end

-- =========================
-- Spray Paint (moved OUTSIDE the toggle and fixed)
-- =========================
do
    local shared = odh_shared_plugins
    local my_own_section = shared.AddSection("Spray Paint")

    -- services / locals
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer

    local decalSaveFile = "saved_decals.json"
    local defaultDecals = {
        ["Nerd"] = 9433300824,
        ["AV Furry"] = 107932217202466,
        ["Femboy Furry"] = 79763371295949,
        ["True Female"] = 14731393433,
        ["TT Dad Jizz"] = 10318831749,
        ["Racist Ice Cream"] = 14868523054,
        ["Nigga"] = 109017596954035,
        ["Roblox Ban"] = 16272310274,
        ["dsgcj"] = 13896748164,
        ["Ra ist"] = 17059177886,
        ["Edp Ironic"] = 84041995770527,
        ["Ragebait"] = 118997417727905,
        ["Clown"] = 3277992656,
        ["Job App"] = 131353391074818,
    }

    -- load decals
    local decals = {}
    if isfile and isfile(decalSaveFile) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(decalSaveFile)) end)
        if ok and type(data) == "table" then
            decals = data
        else
            decals = defaultDecals
        end
    else
        decals = defaultDecals
    end

    local function saveDecals()
        if writefile then
            local ok, encoded = pcall(function() return HttpService:JSONEncode(decals) end)
            if ok then
                writefile(decalSaveFile, encoded)
            else
                warn("Failed to encode decals")
            end
        end
    end

    -- vars
    local decalId = 0
    local sprayOffset = 0.6
    local selectedTargetType = "Nearest Player"
    local selectedPlayer = nil
    local selectedDecalName = nil
    local loopJOB = false
    local loopThread
    local decalDropdown

    -- helpers
    local function getSprayTool()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        return (char and char:FindFirstChild("SprayPaint")) or (backpack and backpack:FindFirstChild("SprayPaint"))
    end
    local function equipTool(tool)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and tool then
            tool.Parent = char
            hum:EquipTool(tool)
        end
    end
    local function unequipTool()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
    end
    local function getTarget()
        if selectedTargetType == "Nearest Player" then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return nil end
            local nearest, shortest = nil, math.huge
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local torso = p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("LowerTorso") or p.Character:FindFirstChild("HumanoidRootPart")
                    if torso then
                        local d = (root.Position - torso.Position).Magnitude
                        if d < shortest then
                            shortest = d
                            nearest = p
                        end
                    end
                end
            end
            return nearest
        elseif selectedTargetType == "Random" then
            local t = {}
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    table.insert(t,p)
                end
            end
            return #t > 0 and t[math.random(1,#t)] or nil
        elseif selectedTargetType == "Select Player" then
            return selectedPlayer
        end
        return nil
    end

    local function spray(target)
        local tool = getSprayTool()
        if not tool or not target or not target.Character then return end
        equipTool(tool)
        local torso = target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("LowerTorso") or target.Character:FindFirstChild("HumanoidRootPart")
        if not torso then return end
        local cframe = torso.CFrame + torso.CFrame.LookVector * sprayOffset
        local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
        if remote then
            remote:FireServer(decalId, Enum.NormalId.Front, 2048, torso, cframe)
        else
            warn("No remote found in spray tool!")
        end
        unequipTool()
    end

    local function loopSpray()
        while loopJOB do
            local target = getTarget()
            if target then spray(target) end
            task.wait(14) -- matches spray cooldown
        end
        loopThread = nil
    end

    -- UI
    if my_own_section then
        my_own_section:AddToggle("Loop Spray Paint", function(state)
            loopJOB = state
            if loopJOB and not loopThread then
                loopThread = task.spawn(loopSpray)
            end
        end)

        my_own_section:AddDropdown("Target Type", {"Nearest Player","Random","Select Player"}, function(opt)
            selectedTargetType = tostring(opt)
        end)

        my_own_section:AddPlayerDropdown("Select Player", function(player)
            if player then
                selectedPlayer = player
                selectedTargetType = "Select Player"
            end
        end)

        local keys = {}
        for k,_ in pairs(decals) do table.insert(keys,k) end
        decalDropdown = my_own_section:AddDropdown("Select Decal", keys, function(selected)
            selectedDecalName = selected
            decalId = decals[selected] or 0
            saveDecals()
        end)

        my_own_section:AddTextBox("Add Decal (Name:ID)", function(text)
            local name, id = text:match("(.+):(%d+)")
            if name and id then
                decals[name] = tonumber(id)
                -- refresh dropdown
                local keys2 = {}
                for k,_ in pairs(decals) do table.insert(keys2,k) end
                decalDropdown.Change(keys2)
                saveDecals()
            else
                print("Format must be Name:ID")
            end
        end)

        my_own_section:AddButton("Delete Selected Decal", function()
            if selectedDecalName and decals[selectedDecalName] then
                decals[selectedDecalName] = nil
                local keys3 = {}
                for k,_ in pairs(decals) do table.insert(keys3,k) end
                decalDropdown.Change(keys3)
                selectedDecalName = nil
                decalId = 0
                saveDecals()
            else
                print("No decal selected to delete.")
            end
        end)

        my_own_section:AddButton("Spray Paint Player", function()
            local target = getTarget()
            if not target then return end
            spray(target)
        end)

        -- Auto-Get Spray Tool (fixed the broken line)
        local autoGetTool = false
        my_own_section:AddToggle("Auto-Get Spray Tool", function(state)
            autoGetTool = state
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            if autoGetTool then
                task.wait(1)
                local args = {"SprayPaint"}
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("ReplicateToy"):InvokeServer(unpack(args))
            end
        end)

        my_own_section:AddButton("Get Spray Tool", function()
            local args = {"SprayPaint"}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("ReplicateToy"):InvokeServer(unpack(args))
        end)

        my_own_section:AddLabel("Spray Paint made by @not_.gato")
    else
        warn("Failed to create Spray Paint section! Plugin not loaded.")
    end
end

-- =========================
-- Fake Dead Emote (Animator API)
-- =========================
do
    local shared = odh_shared_plugins
    local my_own_section = shared.AddSection("Fake Dead Emote")

    my_own_section:AddLabel("Troll Murd by Faking Dead")

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local EMOTE_ID = 84112287597268
    local playingEmote = false
    local currentTrack
    local animateScript
    local guiButton
    local guiSize = 40
    local guiEnabled = false

    local function stopDefaultAnimations(humanoid, character)
        animateScript = character:FindFirstChild("Animate")
        if animateScript then animateScript.Disabled = true end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end

    local function restoreDefaultAnimations()
        if animateScript then animateScript.Disabled = false end
    end

    local function stopEmote()
        if currentTrack then
            currentTrack:Stop()
            currentTrack = nil
        end
        playingEmote = false
        restoreDefaultAnimations()
    end

    local function playEmote()
        if playingEmote then return end
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

        stopDefaultAnimations(humanoid, character)

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://"..EMOTE_ID

        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if not ok or not track then return end

        currentTrack = track
        currentTrack.Priority = Enum.AnimationPriority.Action
        currentTrack:Play()
        playingEmote = true

        local conn1, conn2
        conn1 = humanoid.Running:Connect(function(speed)
            if speed > 0 then 
                stopEmote()
                if conn1 then conn1:Disconnect() end
                if conn2 then conn2:Disconnect() end
            end
        end)
        conn2 = humanoid.Jumping:Connect(function()
            stopEmote()
            if conn1 then conn1:Disconnect() end
            if conn2 then conn2:Disconnect() end
        end)

        currentTrack.Stopped:Connect(stopEmote)
    end

    local function createGuiButton()
        if guiButton then guiButton:Destroy() end

        local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("EmoteGUI")
        if not screenGui then
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "EmoteGUI"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = player:WaitForChild("PlayerGui")
        end

        guiButton = Instance.new("TextButton")
        guiButton.Size = UDim2.new(0, guiSize, 0, guiSize)
        guiButton.Position = UDim2.new(0.4, 0, 0.8, 0)
        guiButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        guiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        guiButton.Font = Enum.Font.SourceSansBold
        guiButton.TextSize = guiSize/2
        guiButton.Text = "FD"
        guiButton.Parent = screenGui

        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(1, 0)
        uicorner.Parent = guiButton

        -- draggable (mobile-friendly)
        local dragging, dragStart, startPos
        guiButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = guiButton.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        guiButton.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                guiButton.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)

        guiButton.MouseButton1Click:Connect(playEmote)
    end

    my_own_section:AddToggle("Enable FD GUI Button", function(enabled)
        guiEnabled = enabled
        if guiEnabled then
            createGuiButton()
        else
            if guiButton then guiButton:Destroy() end
        end
    end)

    my_own_section:AddSlider("GUI Button Size", 30, 150, guiSize, function(size)
        guiSize = size
        if guiButton then
            guiButton.Size = UDim2.new(0, guiSize, 0, guiSize)
            guiButton.TextSize = guiSize/2
        end
    end)

    my_own_section:AddButton("Play Fake Dead Emote", function()
        playEmote()
    end)
end
