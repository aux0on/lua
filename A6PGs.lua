local shared = odh_shared_plugins
local _game = shared.game_name
if _game == "Murder Mystery 2" or _game == "Murder Mystery Modded" then

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    MarketplaceService = game:GetService("MarketplaceService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function GetSafeGuiRoot()
    local success, result = pcall(function() return gethui() end)
    if success and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local function ApplyCustomStyle(button)
    button.Font = Enum.Font.SourceSansLight
    button.BackgroundTransparency = 0.3
    
    local stroke = Instance.new("UIStroke", button)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local gradient = Instance.new("UIGradient", stroke)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    gradient.Rotation = 45
    
    button.MouseButton1Click:Connect(function()
        local sfx = Instance.new("Sound", button)
        sfx.Name = "reina ins't gay :|||"
        sfx.SoundId = "rbxassetid://12221967"
        sfx.Volume = 1
        sfx:Play()
        Services.Debris:AddItem(sfx, 1)
    end)
end

local hiddenGuiParent = GetSafeGuiRoot()
local hiddenGui = hiddenGuiParent:FindFirstChild("HiddenGui")
if not hiddenGui then
    hiddenGui = Instance.new("ScreenGui")
    hiddenGui.Name = "HiddenGui"
    hiddenGui.ResetOnSpawn = false
    hiddenGui.IgnoreGuiInset = true
    hiddenGui.Parent = hiddenGuiParent
end

local serverSection = shared.AddSection("Server Options")

local PlaceId = game.PlaceId
local JobId = game.JobId

serverSection:AddLabel("Might Take a Few Tries")

serverSection:AddButton("Rejoin", function()
    Services.TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
end)

serverSection:AddButton("Server Hop", function()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
    local success, servers = pcall(function()
        return Services.HttpService:JSONDecode(game:HttpGet(url))
    end)
    if success and servers and servers.data and #servers.data > 0 then
        local available = {}
        for _, server in ipairs(servers.data) do
            if server.id ~= JobId and server.playing < server.maxPlayers then
                table.insert(available, server)
            end
        end
        if #available > 0 then
            local randomServer = available[math.random(1, #available)]
            shared.Notify("Server hopping...", 2)
            Services.TeleportService:TeleportToPlaceInstance(PlaceId, randomServer.id, LocalPlayer)
            return
        end
    end
    shared.Notify("No server found to hop to", 3)
end)

serverSection:AddButton("Join Full Server", function()
    local cursor
    local bestServer
    repeat
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
        if cursor then url = url.."&cursor="..cursor end
        local success, response = pcall(function()
            return Services.HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and response and response.data then
            for _, server in ipairs(response.data) do
                if server.id ~= JobId and server.playing < server.maxPlayers then
                    if not bestServer or server.playing > bestServer.playing then
                        bestServer = server
                    end
                end
            end
            cursor = response.nextPageCursor
        else
            cursor = nil
        end
    until not cursor or bestServer
    
    if bestServer then
        shared.Notify("Joining full server...", 2)
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id, LocalPlayer)
    else
        shared.Notify("No suitable fuller server found", 3)
    end
end)

serverSection:AddButton("Join Dead Server", function()
    local cursor
    local lowestServer, lowestCount
    repeat
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(PlaceId, cursor and "&cursor=" .. cursor or "")
        local success, result = pcall(function()
            return Services.HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.id ~= JobId and server.playing > 0 then
                    if not lowestCount or server.playing < lowestCount then
                        lowestCount = server.playing
                        lowestServer = server
                    end
                end
            end
            cursor = result.nextPageCursor
            task.wait(1.5)
        else
            cursor = nil
        end
    until not cursor
    if lowestServer then
        shared.Notify("Joining dead server with " .. lowestServer.playing .. " players", 3)
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, lowestServer.id, LocalPlayer)
    else
        shared.Notify("No dead server found", 3)
    end
end)

local PlaySong = Services.ReplicatedStorage.Remotes.Inventory.PlaySong
local RoleSelect = Services.ReplicatedStorage.Remotes.Gameplay.RoleSelect
local radioSection = shared.AddSection("Radio Abuse")
local songSaveFile = "saved_songs.json"
local savedSongs = {}
if isfile and readfile and isfile(songSaveFile) then
    local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(songSaveFile)) end)
    if ok and type(data) == "table" then savedSongs = data end
end
local function saveSongs()
    if writefile then writefile(songSaveFile, Services.HttpService:JSONEncode(savedSongs)) end
end
local function getSongNames()
    local names = {}
    for _, song in ipairs(savedSongs) do table.insert(names, song.name or song.id) end
    return names
end
local songDropdown
local lastSelectedSong = nil
songDropdown = radioSection:AddDropdown("Saved Songs", getSongNames(), function(selectedName)
    for _, song in ipairs(savedSongs) do
        if song.name == selectedName then
            lastSelectedSong = song
            PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. song.id)
            break
        end
    end
end)
radioSection:AddTextBox("Add Audio ID", function(text)
    local id = text:match("%d+")
    if id then
        local success, info = pcall(function() return Services.MarketplaceService:GetProductInfo(tonumber(id)) end)
        local name = (success and info and info.Name) or id
        table.insert(savedSongs, {name = name, id = id})
        saveSongs()
        songDropdown.Change(getSongNames())
        shared.Notify("Added: " .. name, 2)
    else
        shared.Notify("Invalid audio ID!", 2)
    end
end)
radioSection:AddButton("Delete Selected Audio", function()
    if lastSelectedSong then
        for i, song in ipairs(savedSongs) do
            if song.name == lastSelectedSong.name then
                table.remove(savedSongs, i)
                saveSongs()
                songDropdown.Change(getSongNames())
                shared.Notify("Removed: " .. lastSelectedSong.name, 2)
                lastSelectedSong = nil
                return
            end
        end
    end
end)
local autoPlayEnabled = false
local apCharConn
local function playSelectedSong()
    if lastSelectedSong then
        PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. lastSelectedSong.id)
    end
end
radioSection:AddToggle("Auto Play Selected Audio", function(state)
    autoPlayEnabled = state
    if apCharConn then apCharConn:Disconnect() apCharConn = nil end
    
    if autoPlayEnabled then
        apCharConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            playSelectedSong()
        end)
    end
end)
radioSection:AddLabel("Credits: <font color='rgb(170,0,255)'>@lzzzx</font>")

local speedGlitchSection = shared.AddSection("Auto Speedglitch")
local asgEnabled = false
local asgHorizontal = false
local asgValue = 0
local defaultSpeed = 16
local asgChar, asgHum, asgRoot
local isInAir = false

local function asgCharSetup(c)
    asgChar, asgHum, asgRoot = c, c:WaitForChild("Humanoid"), c:WaitForChild("HumanoidRootPart")
    asgHum.StateChanged:Connect(function(_, s)
        isInAir = (s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall)
    end)
end

if LocalPlayer.Character then asgCharSetup(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(asgCharSetup)

speedGlitchSection:AddToggle("Enable ASG", function(e) asgEnabled = e end)
speedGlitchSection:AddToggle("Sideways Only", function(e) asgHorizontal = e end)
speedGlitchSection:AddSlider("Speed (0–255)", 0, 255, 0, function(v) asgValue = v end)

Services.RunService.Stepped:Connect(function()
    if not (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled) then return end
    if not asgEnabled or not asgChar or not asgHum or not asgRoot then return end
    
    local targetSpeed = defaultSpeed + asgValue
    if isInAir then
        if asgHorizontal then
            if math.abs(asgHum.MoveDirection:Dot(asgRoot.CFrame.RightVector)) > 0.5 then
                asgHum.WalkSpeed = targetSpeed
            else
                asgHum.WalkSpeed = defaultSpeed
            end
        else
            asgHum.WalkSpeed = targetSpeed
        end
    else
        asgHum.WalkSpeed = defaultSpeed
    end
end)

do
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local mapVoterSection = shared.AddSection("Map Voter")
    local voterRespawnAmount = 12
    local savedPos = nil
    local isRespawning = false
    local vmButtonEnabled = false
    local vmButtonGui = nil
    local vmButtonSize = 60
    
    local function msg(t, txt, d) 
        Services.StarterGui:SetCore("SendNotification", {Title=t, Text=txt, Duration=d}) 
    end
    
    -- Create draggable button
    local function createDraggableButton(text, position, size, callback)
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VMButton_" .. text
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local Button = Instance.new("TextButton")
        Button.Name = "DragButton"
        Button.Parent = ScreenGui
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Button.Size = UDim2.new(0, size, 0, size)
        Button.Position = UDim2.new(0, position.X, 0, position.Y)
        Button.Font = Enum.Font.SourceSansLight
        Button.Text = text
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 18
        Button.TextWrapped = true
        Button.BackgroundTransparency = 0.3
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Button
        
        local stroke = Instance.new("UIStroke", Button)
        stroke.Thickness = 2.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local gradient = Instance.new("UIGradient", stroke)
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        }
        gradient.Rotation = 45
        
        -- Dragging functionality
        local dragging = false
        local dragStart, startPos
        
        Button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Button.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Button.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Button click
        Button.MouseButton1Click:Connect(callback)
        
        ScreenGui.Parent = Services.CoreGui or LocalPlayer:WaitForChild("PlayerGui")
        
        return ScreenGui, Button
    end
    
    local function voteMap()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            msg("Error", "Character not found", 3)
            return 
        end
        
        savedPos = LocalPlayer.Character.HumanoidRootPart.Position
        isRespawning = true
        local count = 0
        
        msg("Vote Map", "Starting " .. voterRespawnAmount .. " respawns...", 3)
        
        task.spawn(function()
            while count < voterRespawnAmount and isRespawning do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Health = 0
                    count += 1
                end
                task.wait(0.3)
            end
            isRespawning = false
            savedPos = nil
            msg("Vote Map", "Completed " .. count .. " votes!", 3)
        end)
        
        LocalPlayer.CharacterAdded:Connect(function(char)
            if savedPos then
                char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(savedPos)
            end
        end)
    end
    
    mapVoterSection:AddSlider("Votes Amount", 1, 20, voterRespawnAmount, function(v) 
        voterRespawnAmount = v 
    end)
    
    mapVoterSection:AddButton("Vote Map", function()
        voteMap()
    end)
    
    mapVoterSection:AddToggle("Enable VM Button", function(enabled)
        vmButtonEnabled = enabled
        
        if enabled then
            vmButtonGui, vmButton = createDraggableButton("VM", {X = 310, Y = 100}, vmButtonSize, function()
                voteMap()
            end)
        else
            if vmButtonGui then
                vmButtonGui:Destroy()
                vmButtonGui = nil
            end
        end
    end)
    
    mapVoterSection:AddSlider("VM Button Size", 30, 150, vmButtonSize, function(size)
        vmButtonSize = size
        if vmButtonGui then
            local button = vmButtonGui:FindFirstChild("DragButton")
            if button then
                button.Size = UDim2.new(0, size, 0, size)
            end
        end
    end)
end

local whitelistSection = shared.AddSection("Kill All")
local whitelist = {}

whitelistSection:AddLabel("Ignores Whitelisted Players")
whitelistSection:AddPlayerDropdown("Whitelist Player", function(p)
    if not table.find(whitelist, p.UserId) then
        table.insert(whitelist, p.UserId)
        shared.Notify(p.Name .. " whitelisted.", 2)
    end
end)
whitelistSection:AddButton("Clear Whitelist", function()
    whitelist = {}
    shared.Notify("Whitelist cleared.", 2)
end)

whitelistSection:AddButton("Kill All", function()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local knife = (bp and bp:FindFirstChild("Knife"))
    if not knife then return shared.Notify("Knife not found!", 2) end
    
    knife.Parent = LocalPlayer.Character
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local offset = -2
    local targets = {}
    
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and not table.find(whitelist, p.UserId) and p.Character and p.Character.PrimaryPart then
            table.insert(targets, p.Character)
        end
    end
    
    local start = tick()
    local con
    con = Services.RunService.RenderStepped:Connect(function()
        if tick() - start > 3 then
            con:Disconnect()
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
            for _, c in pairs(targets) do for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
            return
        end
        
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        
        for _, c in pairs(targets) do
            if c.PrimaryPart then
                c:SetPrimaryPartCFrame(root.CFrame * CFrame.new(0, 0, offset))
                for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
            end
        end
    end)
end)

do
    local tsSection = shared.AddSection("Trickshot")
    local spinSpeed = 15
    local hasJumped = false
    local tsActive = false
    local tsConns = {}
    local tsGui, tsBtn
    local tsSize = 40
    
    local function clearTs()
        for _, c in ipairs(tsConns) do c:Disconnect() end
        table.clear(tsConns)
    end
    
    local function setupSpin(c)
        local hrp = c:WaitForChild("HumanoidRootPart")
        local hum = c:WaitForChild("Humanoid")
        
        local function doSpin()
            for _, o in ipairs(hrp:GetChildren()) do if o:IsA("Torque") or o:IsA("Attachment") then o:Destroy() end end
            local att = Instance.new("Attachment", hrp)
            local tq = Instance.new("Torque", hrp)
            tq.Attachment0 = att
            tq.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
            tq.Torque = Vector3.new(0, spinSpeed * 10000, 0)
            
            table.insert(tsConns, hum.StateChanged:Connect(function(_, s)
                if s == Enum.HumanoidStateType.Landed then
                    tq:Destroy()
                    hasJumped = false
                    tsActive = false
                end
            end))
        end
        
        table.insert(tsConns, Services.UserInputService.JumpRequest:Connect(function()
            if tsActive and not hasJumped then
                hasJumped = true
                task.defer(doSpin)
            end
        end))
    end
    
    tsSection:AddLabel("Spin On Next Jump")
    tsSection:AddSlider("Spin Speed (1-30)", 1, 30, 15, function(v) spinSpeed = v end)
    tsSection:AddButton("Activate", function() hasJumped = false tsActive = true end)
    
    local function createTsBtn()
        if tsGui then tsGui:Destroy() end
        tsGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
        tsGui.Name = "TSGui"
        tsGui.ResetOnSpawn = false
        
        tsBtn = Instance.new("TextButton", tsGui)
        tsBtn.Name = "TSButton"
        tsBtn.Text = "TS"
        tsBtn.TextSize = tsSize / 2
        tsBtn.Size = UDim2.new(0, tsSize, 0, tsSize)
        tsBtn.Position = UDim2.new(0.5, -tsSize/2, 0.8, 0)
        tsBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        tsBtn.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", tsBtn).CornerRadius = UDim.new(1,0)
        ApplyCustomStyle(tsBtn)
        
        tsBtn.MouseButton1Click:Connect(function() hasJumped = false tsActive = true end)
        
        local dragging, dragStart, startPos
        tsBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = tsBtn.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        tsBtn.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                tsBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    
    tsSection:AddToggle("Enable TS Bindable Button", function(e)
        if e then createTsBtn() else if tsGui then tsGui:Destroy() end end
    end)
    tsSection:AddSlider("TS Button Size", 30, 150, tsSize, function(s)
        tsSize = s
        if tsBtn then tsBtn.Size = UDim2.new(0, s, 0, s) tsBtn.TextSize = s/2 end
    end)
    
    LocalPlayer.CharacterAdded:Connect(function(c) clearTs() setupSpin(c) end)
    if LocalPlayer.Character then setupSpin(LocalPlayer.Character) end
end

do
    local duelSection = shared.AddSection("Dual Effect")
    duelSection:AddLabel("Must Own Dual Effect + Selected Effect")
    local dualEnabled = false
    local dualConn
    local selectedDualEffect = "Electric"
    
    duelSection:AddDropdown("Select Second Effect", {
        "Vampiric2024", "SynthEffect2025", "Sunbeams2024", "Snowstorm2024", "Retro2025", "Radioactive", "Musical",
        "Heatwave2025", "Heartify", "Gifts2024", "Ghosts2024", "FlamingoEffect2025", "Burn", "Cursed2024",
        "Starry2024", "Bats2024", "Aquatic2025", "Jellyfish2024", "Carrots2025", "BlueFire", "Rainbows2025",
        "Elitify", "Electric", "Ghostify"
    }, function(s) selectedDualEffect = s end)
    
    duelSection:AddToggle("Auto Equip Dual Effect", function(e)
        dualEnabled = e
        if dualConn then dualConn:Disconnect() dualConn = nil end
        if e then
            dualConn = RoleSelect.OnClientEvent:Connect(function(...)
                local args = {...}
                if args[1] == "Murderer" then
                    Services.ReplicatedStorage.Remotes.Inventory.Equip:FireServer("Dual", "Effects")
                    task.delay(18, function()
                        if dualEnabled then
                            Services.ReplicatedStorage.Remotes.Inventory.Equip:FireServer(selectedDualEffect, "Effects")
                        end
                    end)
                end
            end)
        end
    end)
end

do
    local tradeSection = shared.AddSection("Disable Trading")
    tradeSection:AddLabel("Turn Off & Rejoin To Trade Again")
    tradeSection:AddToggle("Decline Trades", function(t)
        if t then
            Services.ReplicatedStorage.Trade.SendRequest.OnClientInvoke = function()
                Services.ReplicatedStorage.Trade.DeclineRequest:FireServer()
            end
        else
            Services.ReplicatedStorage.Trade.SendRequest.OnClientInvoke = nil
        end
    end)
end

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    
    local spraySection = shared.AddSection("Spray Paint")
    local decalSave = "saved_decals.json"
    local decals = {
        ["Nerd"] = 9433300824, ["AV Furry"] = 107932217202466, ["Femboy Furry"] = 79763371295949,
        ["True Female"] = 14731393433, ["TT Dad Jizz"] = 10318831749, ["Racist Ice Cream"] = 14868523054,
        ["Nigga"] = 109017596954035, ["Roblox Ban"] = 16272310274, ["dsgcj"] = 13896748164,
        ["Ra ist"] = 17059177886, ["Edp Ironic"] = 84041995770527, ["Ragebait"] = 118997417727905,
        ["Clown"] = 3277992656, ["Job App"] = 131353391074818
    }
    
    if isfile and isfile(decalSave) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(decalSave)) end)
        if ok and type(data) == "table" then decals = data end
    end
    
    local function saveDecals()
        if writefile then writefile(decalSave, HttpService:JSONEncode(decals)) end
    end

    spraySection:AddLabel('<font color="rgb(255,0,0)">Warning: Using This In MMV Gets You Banned.</font>', nil, true)

    local sprayId = 0
    local sprayTargetMode = "Nearest Player"
    local spraySelectedPlr = nil
    local sprayDecalName = nil
    local sprayLoop = false
    local sprayBehind = false
    local sprayThread
    local decalDropdown
    
    local function getSprayTool()
        local c = LocalPlayer.Character
        return (c and c:FindFirstChild("SprayPaint")) or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("SprayPaint"))
    end
    
    local function getSprayTarget()
        if sprayTargetMode == "Nearest Player" then
            local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not r then return nil end
            local n, s = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local t = p.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local d = (r.Position - t.Position).Magnitude
                        if d < s then s = d n = p end
                    end
                end
            end
            return n
        elseif sprayTargetMode == "Random" then
            local t = {}
            for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then table.insert(t, p) end end
            return (#t > 0 and t[math.random(1, #t)]) or nil
        elseif sprayTargetMode == "Select Player" then
            return spraySelectedPlr
        end
    end
    
    local function performSpray(tgt)
        local tool = getSprayTool()
        if not tool or not tgt or not tgt.Character then return end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            tool.Parent = LocalPlayer.Character
            hum:EquipTool(tool)
        end
        local torso = tgt.Character:FindFirstChild("UpperTorso") or tgt.Character:FindFirstChild("Torso") or tgt.Character:FindFirstChild("HumanoidRootPart")
        if not torso then return end
        
        -- Determine spray position based on sprayBehind toggle
        local sprayPosition, normalId
        if sprayBehind then
            -- Spray on the back (facing away from the target's view) - slightly further back
            normalId = Enum.NormalId.Back
            sprayPosition = torso.CFrame - torso.CFrame.LookVector * 1.2
        else
            -- Spray on the front (default behavior)
            normalId = Enum.NormalId.Front
            sprayPosition = torso.CFrame + torso.CFrame.LookVector * 0.6
        end
        
        tool:FindFirstChildWhichIsA("RemoteEvent"):FireServer(sprayId, normalId, 2048, torso, sprayPosition)
        
        if hum then hum:UnequipTools() end
    end
    
    local function sprayLooper()
        while sprayLoop do
            local t = getSprayTarget()
            if t then performSpray(t) end
            task.wait(14)
        end
        sprayThread = nil
    end
    
    spraySection:AddToggle("Loop Spray Paint", function(s)
        sprayLoop = s
        if s and not sprayThread then sprayThread = task.spawn(sprayLooper) end
    end)
    
    spraySection:AddToggle("Spray Behind Target", function(s)
        sprayBehind = s
    end)
    
    spraySection:AddDropdown("Target Type", {"Nearest Player", "Random", "Select Player"}, function(o) sprayTargetMode = tostring(o) end)
    spraySection:AddPlayerDropdown("Select Player", function(p) if p then spraySelectedPlr = p sprayTargetMode = "Select Player" end end)
    
    local dKeys = {} for k in pairs(decals) do table.insert(dKeys, k) end
    decalDropdown = spraySection:AddDropdown("Select Decal", dKeys, function(s) sprayDecalName = s sprayId = decals[s] or 0 saveDecals() end)
    
    spraySection:AddTextBox("Add Decal (Name:ID)", function(t)
        local n, i = t:match("(.+):(%d+)")
        if n and i then
            decals[n] = tonumber(i)
            local k2 = {} for k in pairs(decals) do table.insert(k2, k) end
            decalDropdown.Change(k2)
            saveDecals()
        end
    end)
    
    spraySection:AddButton("Delete Selected Decal", function()
        if sprayDecalName and decals[sprayDecalName] then
            decals[sprayDecalName] = nil
            local k3 = {} for k in pairs(decals) do table.insert(k3, k) end
            decalDropdown.Change(k3)
            sprayDecalName = nil
            sprayId = 0
            saveDecals()
        end
    end)
    
    spraySection:AddButton("Spray Paint Player", function() performSpray(getSprayTarget()) end)
    
    local autoGet = false
    spraySection:AddToggle("Auto-Get Spray Tool", function(s) 
        autoGet = s 
    end)
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        if autoGet then
            task.wait(1.5)
            pcall(function()
                ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint")
            end)
        end
    end)
    
    spraySection:AddButton("Get Spray Tool", function() 
        pcall(function()
            ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint")
        end)
    end)
    
    spraySection:AddLabel('Credits: <font color="rgb(0,255,0)">@not_.gato</font>', nil, true)
end

do
    local trollSection = shared.AddSection("Troll (FE)")
    trollSection:AddLabel("Play Troll Emotes")
    
    local function makeEmote(eid, txt, gn)
        local playing, track, guiBtn, gEnabled
        local gSize = 40
        
        local function stopEmote()
            if track then track:Stop() track = nil end
            playing = false
            if LocalPlayer.Character then
                local ani = LocalPlayer.Character:FindFirstChild("Animate")
                if ani then ani.Disabled = false end
            end
        end
        
        local function play()
            if playing then return end
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("Humanoid")
            if not h then return end
            
            local ani = c:FindFirstChild("Animate")
            if ani then ani.Disabled = true end
            for _, t in pairs(h:GetPlayingAnimationTracks()) do t:Stop() end
            
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://"..eid
            track = h:LoadAnimation(a)
            track.Priority = Enum.AnimationPriority.Action
            track:Play()
            playing = true
            
            local c1, c2
            c1 = h.Running:Connect(function(s) if s > 0 then stopEmote() c1:Disconnect() c2:Disconnect() end end)
            c2 = h.Jumping:Connect(function() stopEmote() c1:Disconnect() c2:Disconnect() end)
            track.Stopped:Connect(stopEmote)
        end
        
        local function mkGui()
            if guiBtn then guiBtn:Destroy() end
            local sg = LocalPlayer.PlayerGui:FindFirstChild(gn) or Instance.new("ScreenGui", LocalPlayer.PlayerGui)
            sg.Name = gn
            sg.ResetOnSpawn = false
            
            guiBtn = Instance.new("TextButton", sg)
            guiBtn.Size = UDim2.new(0, gSize, 0, gSize)
            guiBtn.Position = UDim2.new(0.5, 0, 0.8, 0)
            guiBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            guiBtn.TextColor3 = Color3.new(1,1,1)
            guiBtn.Text = txt
            guiBtn.TextSize = gSize/2
            Instance.new("UICorner", guiBtn).CornerRadius = UDim.new(1,0)
            ApplyCustomStyle(guiBtn)
            
            local drag, start, pos
            guiBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true start = i.Position pos = guiBtn.Position i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end) end end)
            guiBtn.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - start guiBtn.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y) end end)
            guiBtn.MouseButton1Click:Connect(play)
        end
        
        trollSection:AddToggle("Enable "..txt.." Button", function(e)
            gEnabled = e
            if e then mkGui() else if guiBtn then guiBtn:Destroy() end end
        end)
        trollSection:AddSlider(txt.." Button Size", 30, 150, gSize, function(s) gSize = s if guiBtn then guiBtn.Size = UDim2.new(0, s, 0, s) guiBtn.TextSize = s/2 end end)
        trollSection:AddButton("Play "..txt.." Emote", play)
    end
    
    makeEmote("84112287597268", "FD", "EmoteGUI_FakeDead")
    makeEmote("122366279755346", "KS", "EmoteGUI_KnifeSwing")
    makeEmote("103788740211648", "DS", "EmoteGUI_DualSwing")
end

local muteSection = shared.AddSection("Mute Buttons")
muteSection:AddLabel("Turn Off and Rejoin to Enable Sounds Again")
local muteTarget = "rbxassetid://3868133279"
local muteEnabled = false
local muteConns = {}

local function doMute(s)
    if s.SoundId == muteTarget then
        s.Volume = 0
        table.insert(muteConns, s:GetPropertyChangedSignal("Volume"):Connect(function() if muteEnabled and s.Volume > 0 then s.Volume = 0 end end))
    end
end

muteSection:AddToggle("Disable ODH Button Sounds", function(s)
    muteEnabled = s
    if s then
        for _, o in ipairs(workspace:GetDescendants()) do if o:IsA("Sound") then doMute(o) end end
        table.insert(muteConns, workspace.DescendantAdded:Connect(function(o) if o:IsA("Sound") then doMute(o) end end))
    else
        for _, c in ipairs(muteConns) do c:Disconnect() end
        table.clear(muteConns)
    end
end)

do
    local rtxSection = shared.AddSection("RTX")
    local rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
    local rtxOn = false
    
    local function createRtxEffects()
        -- Create Sky
        if not rtx.Sky then
            rtx.Sky = Instance.new("Sky")
            rtx.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=144933338"
            rtx.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=144931530"
            rtx.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=144933262"
            rtx.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=144933244"
            rtx.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=144933299"
            rtx.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=144931564"
            rtx.Sky.StarCount = 5000
            rtx.Sky.SunAngularSize = 5
            rtx.Sky.Parent = Services.Lighting
        end
        
        -- Create Bloom
        if not rtx.Bloom then
            rtx.Bloom = Instance.new("BloomEffect")
            rtx.Bloom.Intensity = 0.3
            rtx.Bloom.Size = 10
            rtx.Bloom.Threshold = 0.8
            rtx.Bloom.Parent = Services.Lighting
        end
        
        -- Create Blur
        if not rtx.Blur then
            rtx.Blur = Instance.new("BlurEffect")
            rtx.Blur.Size = 5
            rtx.Blur.Parent = Services.Lighting
        end
        
        -- Create Color Correction
        if not rtx.CC then
            rtx.CC = Instance.new("ColorCorrectionEffect")
            rtx.CC.Brightness = 0
            rtx.CC.Contrast = 0.1
            rtx.CC.Saturation = 0.25
            rtx.CC.TintColor = Color3.fromRGB(255, 255, 255)
            rtx.CC.Parent = Services.Lighting
        end
        
        -- Create Sun Rays
        if not rtx.Sun then
            rtx.Sun = Instance.new("SunRaysEffect")
            rtx.Sun.Intensity = 0.1
            rtx.Sun.Spread = 0.8
            rtx.Sun.Parent = Services.Lighting
        end
    end
    
    local function setRtx(enabled)
        rtxOn = enabled
        
        if enabled then
            -- Create effects
            createRtxEffects()
            
            -- Set lighting properties
            Services.Lighting.Brightness = 2.25
            Services.Lighting.ExposureCompensation = 0.1
            Services.Lighting.ClockTime = 17.55
            
            -- Enable all effects
            for _, v in pairs(rtx) do
                if v then v.Enabled = true end
            end
        else
            -- Destroy all RTX effects
            for _, v in pairs(rtx) do
                if v then
                    v:Destroy()
                end
            end
            
            -- Reset rtx table
            rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
            
            -- Reset lighting properties
            Services.Lighting.Brightness = 2
            Services.Lighting.ExposureCompensation = 0
        end
    end
    
    rtxSection:AddToggle("Enable RTX", setRtx)
end

do
    local lsSection = shared.AddSection("Legit Speedglitch")
    local sideSpd = 0
    local btnSz = 50
    local emOn = false
    local selEmote = nil
    local lsGui, lsBtn
    local lsHori = false
    local lsAir = false
    local emotes = {["Moonwalk"]="79127989560307", ["Yungblud"]="15610015346", ["Bouncy Twirl"]="14353423348", ["Flex Walk"]="15506506103"}
    
    local function playE(id)
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not h then return end
        local s = pcall(function() h:PlayEmoteAndGetAnimTrackById(id) end)
        if not s then
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://"..id
            h:LoadAnimation(a):Play()
        end
    end
    
    local function mkLsBtn()
        if lsGui then lsGui:Destroy() end
        lsGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
        lsGui.Name = "SGGui"
        lsGui.ResetOnSpawn = false
        lsBtn = Instance.new("TextButton", lsGui)
        lsBtn.Name = "SGButton"
        lsBtn.Text = "SG"
        lsBtn.TextSize = btnSz/2
        lsBtn.TextColor3 = Color3.new(1,0,0)
        lsBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        lsBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
        lsBtn.Position = UDim2.new(0.5, -btnSz/2, 0.7, 0)
        Instance.new("UICorner", lsBtn).CornerRadius = UDim.new(1,0)
        ApplyCustomStyle(lsBtn)
        
        lsBtn.MouseButton1Click:Connect(function()
            emOn = not emOn
            lsBtn.TextColor3 = emOn and Color3.new(0,1,0) or Color3.new(1,0,0)
            if emOn and selEmote then playE(selEmote) elseif LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
        end)
        
        local d, s, p
        lsBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true s = i.Position p = lsBtn.Position i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end) end end)
        lsBtn.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - s lsBtn.Position = UDim2.new(p.X.Scale, p.X.Offset + delta.X, p.Y.Scale, p.Y.Offset + delta.Y) end end)
    end
    
    Services.RunService.Stepped:Connect(function()
        if not emOn or not LocalPlayer.Character then return end
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end
        
        lsAir = h:GetState() == Enum.HumanoidStateType.Freefall or h:GetState() == Enum.HumanoidStateType.Jumping
        local spd = 16 + sideSpd
        if lsAir then
            if lsHori then
                if math.abs(h.MoveDirection:Dot(r.CFrame.RightVector)) > 0.5 then h.WalkSpeed = spd else h.WalkSpeed = 16 end
            else
                h.WalkSpeed = spd
            end
        else
            h.WalkSpeed = 16
        end
    end)
    
    lsSection:AddToggle("Enable SG Bindable Button", function(e) if e then mkLsBtn() else if lsGui then lsGui:Destroy() end lsGui=nil lsBtn=nil emOn=false end end)
    lsSection:AddSlider("Speed (0–255)", 0, 255, sideSpd, function(v) sideSpd = v end)
    lsSection:AddSlider("Button Size", 30, 150, btnSz, function(v) btnSz = v if lsBtn then lsBtn.Size = UDim2.new(0, v, 0, v) lsBtn.TextSize = v/2 end end)
    lsSection:AddToggle("Sideways Only", function(e) lsHori = e end)
    lsSection:AddDropdown("Select Emote", {"Moonwalk", "Yungblud", "Bouncy Twirl", "Flex Walk", "Custom"}, function(s) if s ~= "Custom" then selEmote = emotes[s] else selEmote = nil end end)
    lsSection:AddTextBox("Custom Emote ID", function(t) if t ~= "" then selEmote = t end end)
end

do
    local hlSection = shared.AddSection("FE Headless")
    local hlId = 78837807518622
    local hlId2 = 117080641351340
    local hlId3 = 136055001302601
    local hlOn = false
    local hlOn2 = false
    local hlOn3 = false
    local hlTrack
    local hlTrack2
    local hlTrack3
    local freezeConnection
    local freezeConnection2
    local freezeConnection3
    local stoppedConnection
    local stoppedConnection2
    local stoppedConnection3
    
    local function stopHl()
        if stoppedConnection then stoppedConnection:Disconnect() stoppedConnection = nil end
        if hlTrack then hlTrack:Stop() hlTrack:Destroy() hlTrack = nil end
    end
    
    local function stopHl2()
        if stoppedConnection2 then stoppedConnection2:Disconnect() stoppedConnection2 = nil end
        if hlTrack2 then hlTrack2:Stop() hlTrack2:Destroy() hlTrack2 = nil end
    end
    
    local function stopHl3()
        if stoppedConnection3 then stoppedConnection3:Disconnect() stoppedConnection3 = nil end
        if hlTrack3 then hlTrack3:Stop() hlTrack3:Destroy() hlTrack3 = nil end
    end
    
    local function cleanup()
        stopHl()
        stopHl2()
        stopHl3()
        if freezeConnection then freezeConnection:Disconnect() freezeConnection = nil end
        if freezeConnection2 then freezeConnection2:Disconnect() freezeConnection2 = nil end
        if freezeConnection3 then freezeConnection3:Disconnect() freezeConnection3 = nil end
    end
    
    local function playHl(hum)
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end
        stopHl()
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..hlId
        hlTrack = ani:LoadAnimation(a)
        hlTrack.Priority = Enum.AnimationPriority.Action
        hlTrack.Looped = true
        hlTrack:Play()
        if stoppedConnection then stoppedConnection:Disconnect() end
        stoppedConnection = hlTrack.Stopped:Connect(function()
            if hlOn and hum.Parent then task.wait(0.1) playHl(hum) end
        end)
    end
    
    local function playHl2(hum)
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end
        stopHl2()
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..hlId2
        hlTrack2 = ani:LoadAnimation(a)
        hlTrack2.Priority = Enum.AnimationPriority.Action
        hlTrack2.Looped = true
        hlTrack2:Play()
        if stoppedConnection2 then stoppedConnection2:Disconnect() end
        stoppedConnection2 = hlTrack2.Stopped:Connect(function()
            if hlOn2 and hum.Parent then task.wait(0.1) playHl2(hum) end
        end)
    end
    
    local function playHl3(hum)
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end
        stopHl3()
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..hlId3
        hlTrack3 = ani:LoadAnimation(a)
        hlTrack3.Priority = Enum.AnimationPriority.Action
        hlTrack3.Looped = true
        hlTrack3:Play()
        if stoppedConnection3 then stoppedConnection3:Disconnect() end
        stoppedConnection3 = hlTrack3.Stopped:Connect(function()
            if hlOn3 and hum.Parent then task.wait(0.1) playHl3(hum) end
        end)
    end
    
    local function applyFreeze(hum)
        if freezeConnection then freezeConnection:Disconnect() end
        freezeConnection = hum.StateChanged:Connect(function()
            if hlOn and hum.Parent and (not hlTrack or not hlTrack.IsPlaying) then
                task.wait(0.05)
                if hlOn and hum.Parent then playHl(hum) end
            end
        end)
    end
    
    local function applyFreeze2(hum)
        if freezeConnection2 then freezeConnection2:Disconnect() end
        freezeConnection2 = hum.StateChanged:Connect(function()
            if hlOn2 and hum.Parent and (not hlTrack2 or not hlTrack2.IsPlaying) then
                task.wait(0.05)
                if hlOn2 and hum.Parent then playHl2(hum) end
            end
        end)
    end
    
    local function applyFreeze3(hum)
        if freezeConnection3 then freezeConnection3:Disconnect() end
        freezeConnection3 = hum.StateChanged:Connect(function()
            if hlOn3 and hum.Parent and (not hlTrack3 or not hlTrack3.IsPlaying) then
                task.wait(0.05)
                if hlOn3 and hum.Parent then playHl3(hum) end
            end
        end)
    end
    
    local function enableHl()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        applyFreeze(h)
        playHl(h)
    end
    
    local function enableHl2()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        applyFreeze2(h)
        playHl2(h)
    end
    
    local function enableHl3()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        applyFreeze3(h)
        playHl3(h)
    end
    
    hlSection:AddToggle("Enable Headless", function(s)
        hlOn = s
        if s then
            enableHl()
        else
            stopHl()
            if freezeConnection then freezeConnection:Disconnect() freezeConnection = nil end
        end
    end)
    
    hlSection:AddToggle("Enable Headless V2", function(s)
        hlOn2 = s
        if s then
            enableHl2()
        else
            stopHl2()
            if freezeConnection2 then freezeConnection2:Disconnect() freezeConnection2 = nil end
        end
    end)
    
    hlSection:AddToggle("Enable Headless V3", function(s)
        hlOn3 = s
        if s then
            enableHl3()
        else
            stopHl3()
            if freezeConnection3 then freezeConnection3:Disconnect() freezeConnection3 = nil end
        end
    end)
    
    LocalPlayer.CharacterRemoving:Connect(function()
        cleanup()
    end)
    
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if hlOn then enableHl() end
        if hlOn2 then enableHl2() end
        if hlOn3 then enableHl3() end
    end)
end

do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    
    local flingSection = shared.AddSection("Fling")
    local flingLoopPlr = false
    local flingLoopAll = false
    local flingSelPlr = nil
    local flingActive = true
    local autoFlingSheriff = false
    local autoFlingMurderer = false
    
    -- Whitelist
    local whitelist = {}
    
    -- Bindable button states
    local sheriffButtonEnabled = false
    local murdererButtonEnabled = false
    local playerButtonEnabled = false
    local sheriffButtonGui = nil
    local murdererButtonGui = nil
    local playerButtonGui = nil
    local sheriffButtonSize = 60
    local murdererButtonSize = 60
    local playerButtonSize = 60
    
    local function msg(t, txt, d) 
        Services.StarterGui:SetCore("SendNotification", {Title=t, Text=txt, Duration=d}) 
    end
    
    -- Whitelist functions
    local function isWhitelisted(player)
        return whitelist[player.UserId] == true
    end
    
    local function addToWhitelist(player)
        whitelist[player.UserId] = true
        msg("Whitelist", player.Name .. " added to whitelist", 3)
    end
    
    local function clearWhitelist()
        whitelist = {}
        msg("Whitelist", "Whitelist cleared!", 3)
    end
    
    -- Better detection for Sheriff and Murderer
    local function findSheriff()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                if p.Backpack:FindFirstChild("Gun") then
                    return p
                end
                if p.Character and p.Character:FindFirstChild("Gun") then
                    return p
                end
            end
        end
        return nil
    end
    
    local function findMurderer()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                if p.Backpack:FindFirstChild("Knife") then
                    return p
                end
                if p.Character and p.Character:FindFirstChild("Knife") then
                    return p
                end
            end
        end
        return nil
    end
    
    local function OdhSkid(TargetPlayer, duration)
        if isWhitelisted(TargetPlayer) then
            msg("Whitelist", TargetPlayer.Name .. " is whitelisted!", 3)
            return
        end
        
        local localPlayer = Players.LocalPlayer
        local Character = localPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart

        local TCharacter = TargetPlayer.Character
        if not TCharacter then return end
        
        local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        local TRootPart = THumanoid and THumanoid.RootPart
        local THead = TCharacter:FindFirstChild("Head")
        local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        local Handle = Accessory and Accessory:FindFirstChild("Handle")

        if not (Character and Humanoid and RootPart) then return end
        
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
        end
        
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                table.foreach(Character:GetChildren(), function(_, x)
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end)
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
    
    -- Create draggable buttons (similar to bomb jump script)
    local function createDraggableButton(text, position, size, callback)
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "FlingButton_" .. text
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local Button = Instance.new("TextButton")
        Button.Name = "DragButton"
        Button.Parent = ScreenGui
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Button.Size = UDim2.new(0, size, 0, size)
        Button.Position = UDim2.new(0, position.X, 0, position.Y)
        Button.Font = Enum.Font.SourceSansLight
        Button.Text = text
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 18
        Button.TextWrapped = true
        Button.BackgroundTransparency = 0.3
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Button
        
        local stroke = Instance.new("UIStroke", Button)
        stroke.Thickness = 2.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local gradient = Instance.new("UIGradient", stroke)
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        }
        gradient.Rotation = 45
        
        -- Dragging functionality
        local dragging = false
        local dragStart, startPos
        
        Button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Button.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Button.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Button click
        Button.MouseButton1Click:Connect(callback)
        
        ScreenGui.Parent = Services.CoreGui or LocalPlayer:WaitForChild("PlayerGui")
        
        return ScreenGui, Button
    end
    
    -- Auto fling loops
    task.spawn(function()
        while true do
            task.wait(1)
            if autoFlingSheriff then
                local sheriff = findSheriff()
                if sheriff then
                    OdhSkid(sheriff, 2)
                    task.wait(3) -- Wait for cooldown
                end
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(1)
            if autoFlingMurderer then
                local murderer = findMurderer()
                if murderer then
                    OdhSkid(murderer, 2)
                    task.wait(3) -- Wait for cooldown
                end
            end
        end
    end)
    
    -- Regular buttons
    flingSection:AddButton("Fling Sheriff", function()
        local sheriff = findSheriff()
        if sheriff then
            OdhSkid(sheriff, 2)
        else
            msg("Error", "No Sheriff Found", 3)
        end
    end)
    
    flingSection:AddButton("Fling Murderer", function()
        local murderer = findMurderer()
        if murderer then
            OdhSkid(murderer, 2)
        else
            msg("Error", "No Murderer Found", 3)
        end
    end)
    
    flingSection:AddButton("Fling All", function() 
        for _, p in pairs(Players:GetPlayers()) do 
            if p ~= LocalPlayer and not isWhitelisted(p) then 
                OdhSkid(p, 2)
                task.wait(0.5)
            end 
        end 
    end)
    
    flingSection:AddPlayerDropdown("Fling Player", function(p) 
        flingSelPlr = p 
        if p ~= LocalPlayer and not isWhitelisted(p) then 
            OdhSkid(p, 2) 
        end 
    end)
    
    -- Auto fling toggles
    flingSection:AddToggle("Auto Fling Sheriff", function(enabled)
        autoFlingSheriff = enabled
        if enabled then
            msg("Auto Fling", "Auto fling sheriff enabled", 3)
        else
            msg("Auto Fling", "Auto fling sheriff disabled", 3)
        end
    end)
    
    flingSection:AddToggle("Auto Fling Murderer", function(enabled)
        autoFlingMurderer = enabled
        if enabled then
            msg("Auto Fling", "Auto fling murderer enabled", 3)
        else
            msg("Auto Fling", "Auto fling murderer disabled", 3)
        end
    end)
    
    -- Bindable button toggles
    flingSection:AddToggle("Enable FS Button", function(enabled)
        sheriffButtonEnabled = enabled
        
        if enabled then
            sheriffButtonGui, sheriffButton = createDraggableButton("FS", {X = 100, Y = 100}, sheriffButtonSize, function()
                local sheriff = findSheriff()
                if sheriff then
                    OdhSkid(sheriff, 2)
                    msg("Success", "Flinging Sheriff: " .. sheriff.Name, 2)
                else
                    msg("Error", "No Sheriff Found", 3)
                end
            end)
        else
            if sheriffButtonGui then
                sheriffButtonGui:Destroy()
                sheriffButtonGui = nil
            end
        end
    end)
    
    flingSection:AddSlider("Sheriff Button Size", 30, 150, sheriffButtonSize, function(size)
        sheriffButtonSize = size
        if sheriffButtonGui then
            local button = sheriffButtonGui:FindFirstChild("DragButton")
            if button then
                button.Size = UDim2.new(0, size, 0, size)
            end
        end
    end)
    
    flingSection:AddToggle("Enable FM Button", function(enabled)
        murdererButtonEnabled = enabled
        
        if enabled then
            murdererButtonGui, murdererButton = createDraggableButton("FM", {X = 170, Y = 100}, murdererButtonSize, function()
                local murderer = findMurderer()
                if murderer then
                    OdhSkid(murderer, 2)
                    msg("Success", "Flinging Murderer: " .. murderer.Name, 2)
                else
                    msg("Error", "No Murderer Found", 3)
                end
            end)
        else
            if murdererButtonGui then
                murdererButtonGui:Destroy()
                murdererButtonGui = nil
            end
        end
    end)
    
    flingSection:AddSlider("Murderer Button Size", 30, 150, murdererButtonSize, function(size)
        murdererButtonSize = size
        if murdererButtonGui then
            local button = murdererButtonGui:FindFirstChild("DragButton")
            if button then
                button.Size = UDim2.new(0, size, 0, size)
            end
        end
    end)
    
    flingSection:AddToggle("Enable FP Bindable Button", function(enabled)
        playerButtonEnabled = enabled
        
        if enabled then
            playerButtonGui, playerButton = createDraggableButton("FP", {X = 240, Y = 100}, playerButtonSize, function()
                if flingSelPlr and flingSelPlr.Parent then
                    if not isWhitelisted(flingSelPlr) then
                        OdhSkid(flingSelPlr, 2)
                        msg("Success", "Flinging Player: " .. flingSelPlr.Name, 2)
                    else
                        msg("Whitelist", flingSelPlr.Name .. " is whitelisted!", 3)
                    end
                else
                    msg("Error", "No Player Selected", 3)
                end
            end)
        else
            if playerButtonGui then
                playerButtonGui:Destroy()
                playerButtonGui = nil
            end
        end
    end)
    
    flingSection:AddSlider("FP Button Size", 30, 150, playerButtonSize, function(size)
        playerButtonSize = size
        if playerButtonGui then
            local button = playerButtonGui:FindFirstChild("DragButton")
            if button then
                button.Size = UDim2.new(0, size, 0, size)
            end
        end
    end)
    
    -- Whitelist management
    flingSection:AddPlayerDropdown("Add to Whitelist", function(p)
        if p and p ~= LocalPlayer then
            addToWhitelist(p)
        end
    end)
    
    flingSection:AddButton("Clear Whitelist", function()
        clearWhitelist()
    end)
    
    -- Loop toggles (FIXED - added delay to prevent crash)
    flingSection:AddToggle("Loop Fling Player", function(s)
        flingLoopPlr = s
        task.spawn(function()
            while flingLoopPlr do
                if flingSelPlr and flingSelPlr.Parent and not isWhitelisted(flingSelPlr) then 
                    OdhSkid(flingSelPlr, 2)
                    task.wait(3) -- Wait for cooldown before next fling (same as other flings)
                else 
                    flingLoopPlr = false
                    if not flingSelPlr or not flingSelPlr.Parent then
                        msg("Error", "Target left or invalid", 3)
                    end
                end
            end
        end)
    end)
    
    flingSection:AddToggle("Loop Fling All", function(s)
        flingLoopAll = s
        task.spawn(function() 
            while flingLoopAll do 
                for _, p in pairs(Players:GetPlayers()) do 
                    if p ~= LocalPlayer and p.Parent and not isWhitelisted(p) then 
                        OdhSkid(p, 2)
                        task.wait(0.5)
                    end 
                end 
                task.wait(3) -- Wait between full cycles
            end 
        end)
    end)
    
    -- Cleanup when player leaves
    Players.PlayerRemoving:Connect(function(player)
        if flingSelPlr == player then
            flingSelPlr = nil
            flingLoopPlr = false
        end
    end)
end

do
    local perkSection = shared.AddSection("Perks")
    local hasteOn = false
    local hasteSpd = 18
    local hConn
    
    local function updSpd()
        if not hasteOn then return end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        if not h then return end
        
        if (c:FindFirstChild("Knife") or (LocalPlayer.Backpack:FindFirstChild("Knife") and c:FindFirstChild("Knife"))) then
            h.WalkSpeed = hasteSpd
        else
            h.WalkSpeed = 16
        end
    end
    
    local function setupHaste()
        if hConn then hConn:Disconnect() hConn = nil end
        if not hasteOn then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
            return
        end
        
        hConn = LocalPlayer.CharacterAdded:Connect(function(c)
            local h = c:WaitForChild("Humanoid")
            c.ChildAdded:Connect(updSpd)
            c.ChildRemoved:Connect(updSpd)
            task.wait(0.5)
            updSpd()
        end)
        
        if LocalPlayer.Character then
            LocalPlayer.Character.ChildAdded:Connect(updSpd)
            LocalPlayer.Character.ChildRemoved:Connect(updSpd)
            updSpd()
        end
    end
    
    perkSection:AddToggle("Enable Auto Haste", function(s) hasteOn = s setupHaste() end)
    perkSection:AddLabel("Stacks With Other Perks")
end

do
    local skySection = shared.AddSection("Skybox")
    local skyId = 70883871260184
    local skyOn = false
    local skyTrack
    local freezeConnection
    local stoppedConnection
    
    local function stopSky()
        if stoppedConnection then stoppedConnection:Disconnect() stoppedConnection = nil end
        if skyTrack then skyTrack:Stop() skyTrack:Destroy() skyTrack = nil end
    end
    
    local function cleanup()
        stopSky()
        if freezeConnection then freezeConnection:Disconnect() freezeConnection = nil end
    end
    
    local function playSky(hum)
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end
        stopSky()
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..skyId
        skyTrack = ani:LoadAnimation(a)
        skyTrack.Priority = Enum.AnimationPriority.Action
        skyTrack.Looped = true
        skyTrack:Play()
        if stoppedConnection then stoppedConnection:Disconnect() end
        stoppedConnection = skyTrack.Stopped:Connect(function()
            if skyOn and hum.Parent then task.wait(0.1) playSky(hum) end
        end)
    end
    
    local function applyFreeze(hum)
        if freezeConnection then freezeConnection:Disconnect() end
        freezeConnection = hum.StateChanged:Connect(function()
            if skyOn and hum.Parent and (not skyTrack or not skyTrack.IsPlaying) then
                task.wait(0.05)
                if skyOn and hum.Parent then playSky(hum) end
            end
        end)
    end
    
    local function enSky()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        applyFreeze(h)
        playSky(h)
    end
    
    skySection:AddToggle("Enable FE Skybox", function(s)
        skyOn = s
        if s then
            enSky()
        else
            stopSky()
            if freezeConnection then freezeConnection:Disconnect() freezeConnection = nil end
        end
    end)
    
    LocalPlayer.CharacterRemoving:Connect(function()
        cleanup()
    end)
    
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if skyOn then enSky() end
    end)
end

local section = shared.AddSection("Bomb Jump+")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local bjGui = nil
local bjBtn = nil
local timerGui = nil
local timerDisplay = nil
local onCooldown = false
local bombJumpEnabled = false
local clickBombJumpEnabled = false
local guiEnabled = false
local timerGuiEnabled = false
local debounce = false
local bjSize = 40
local timerSize = 40
local autoGetBomb = false
local justRespawned = false

local activeTouches = {}
local TAP_MOVEMENT_THRESHOLD = 10
local TAP_TIME_THRESHOLD = 0.3

local BOMB_NAMES = {"Bomb", "PrankBomb", "FakeBomb"}

local bombEquipConnections = {}

section:AddLabel("Different Bomb Jump Options")

function CreateBJButton()
    if bjGui then bjGui:Destroy() end
    
    bjGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    bjGui.Name = "BJGui"
    bjGui.ResetOnSpawn = false
    
    bjBtn = Instance.new("TextButton", bjGui)
    bjBtn.Name = "BJButton"
    bjBtn.Text = "Ready"
    bjBtn.TextSize = 14
    bjBtn.Size = UDim2.new(0, bjSize, 0, bjSize)
    bjBtn.Position = UDim2.new(0.5, -bjSize/2, 0.8, 0)
    bjBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bjBtn.TextColor3 = Color3.new(1, 1, 1)
    bjBtn.Font = Enum.Font.SourceSansLight
    bjBtn.BackgroundTransparency = 0.3
    Instance.new("UICorner", bjBtn).CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke", bjBtn)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local gradient = Instance.new("UIGradient", stroke)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    gradient.Rotation = 45
    
    bjBtn.MouseButton1Click:Connect(function()
        if not onCooldown and not debounce then
            FastBombJump()
        end
    end)
    
    local dragging, dragStart, startPos
    bjBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bjBtn.Position
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end 
            end)
        end
    end)
    
    bjBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            bjBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function CreateTimerDisplay()
    if timerGui then timerGui:Destroy() end
    
    timerGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    timerGui.Name = "TimerGui"
    timerGui.ResetOnSpawn = false
    
    timerDisplay = Instance.new("TextLabel", timerGui)
    timerDisplay.Name = "TimerDisplay"
    timerDisplay.Text = "Ready"
    timerDisplay.TextSize = 14
    timerDisplay.Size = UDim2.new(0, timerSize, 0, timerSize)
    timerDisplay.Position = UDim2.new(0.5, -timerSize/2 + 60, 0.8, 0)
    timerDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    timerDisplay.TextColor3 = Color3.new(1, 1, 1)
    timerDisplay.Font = Enum.Font.SourceSansLight
    timerDisplay.BackgroundTransparency = 0.3
    Instance.new("UICorner", timerDisplay).CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke", timerDisplay)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local gradient = Instance.new("UIGradient", stroke)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    gradient.Rotation = 45
    
    local dragging = false
    local dragStart, startPos
    
    timerDisplay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = timerDisplay.Position
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end 
            end)
        end
    end)
    
    timerDisplay.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            timerDisplay.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function GetCenterPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local camera = Workspace.CurrentCamera
        local lookDir = camera.CFrame.LookVector
        return character.HumanoidRootPart.Position + (lookDir * 5)
    end
    return nil
end

function MakeCharacterJump()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

function ResetCooldown()
    onCooldown = false
    
    if bjBtn and bjBtn.Parent then
        bjBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        bjBtn.Text = "Ready"
    end
    
    if timerDisplay and timerDisplay.Parent then
        timerDisplay.Text = "Ready"
        timerDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end

function StartCooldown()
    onCooldown = true
    debounce = false
    
    if bjBtn then
        bjBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        bjBtn.Text = "Wait"
    end
    
    if timerDisplay then
        timerDisplay.Text = "Wait"
        timerDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
    
    task.spawn(function()
        for i = 22, 1, -1 do
            if not onCooldown then break end
            
            if bjBtn and bjBtn.Parent then
                bjBtn.Text = tostring(i)
            end
            
            if timerDisplay then
                timerDisplay.Text = tostring(i)
            end
            task.wait(1)
        end
        
        if onCooldown then
            ResetCooldown()
        end
    end)
end

function UnequipBomb()
    task.spawn(function()
        task.wait(0.5)
        local character = LocalPlayer.Character
        if character then
            for _, bombName in ipairs(BOMB_NAMES) do
                local bomb = character:FindFirstChild(bombName)
                if bomb then
                    bomb.Parent = LocalPlayer.Backpack or character
                    break
                end
            end
        end
    end)
end

function GetBombInHand()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    for _, bombName in ipairs(BOMB_NAMES) do
        local bomb = character:FindFirstChild(bombName)
        if bomb then
            return bomb
        end
    end
    
    return nil
end

function GetAnyBomb()
    local character = LocalPlayer.Character
    if not character then return false, nil end
    
    for _, bombName in ipairs(BOMB_NAMES) do
        local bomb = character:FindFirstChild(bombName)
        if bomb then return true, bomb end
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, bombName in ipairs(BOMB_NAMES) do
            local bomb = backpack:FindFirstChild(bombName)
            if bomb then
                bomb.Parent = character
                return true, bomb
            end
        end
    end
    
    local success = pcall(function()
        ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
    end)
    
    if success then
        for _ = 1, 5 do
            for _, bombName in ipairs(BOMB_NAMES) do
                local bomb = character:FindFirstChild(bombName)
                if bomb then return true, bomb end
                
                if backpack then
                    bomb = backpack:FindFirstChild(bombName)
                    if bomb then
                        bomb.Parent = character
                        return true, bomb
                    end
                end
            end
            task.wait(0.05)
        end
    end
    
    return false, nil
end

function FastBombJump()
    if onCooldown or debounce or justRespawned then return end
    debounce = true
    
    local success, bomb = GetAnyBomb()
    
    if success and bomb then
        local position = GetCenterPosition()
        if position then
            local remote = bomb:FindFirstChild("Remote")
            if remote then
                pcall(function()
                    remote:FireServer(CFrame.new(position), 50)
                end)
            end
            
            MakeCharacterJump()
            UnequipBomb()
            
            task.spawn(function()
                task.wait(0.1)
                StartCooldown()
            end)
        end
    end
    
    task.spawn(function()
        task.wait(0.5)
        debounce = false
    end)
end

function SetupBombEquipDetection()
    for _, connection in pairs(bombEquipConnections) do
        connection:Disconnect()
    end
    bombEquipConnections = {}
    
    if not clickBombJumpEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local connection = character.ChildAdded:Connect(function(child)
        if not clickBombJumpEnabled or justRespawned then return end
        
        for _, bombName in ipairs(BOMB_NAMES) do
            if child.Name == bombName then
                if not onCooldown and not debounce then
                    FastBombJump()
                end
                break
            end
        end
    end)
    
    table.insert(bombEquipConnections, connection)
end

local inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        
        activeTouches[input] = {
            startPosition = input.Position,
            startTime = tick(),
            moved = false
        }
    end
end)

local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
    local touchData = activeTouches[input]
    if not touchData then return end
    
    local delta = input.Position - touchData.startPosition
    local distance = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)
    
    if distance > TAP_MOVEMENT_THRESHOLD then
        touchData.moved = true
    end
end)

local inputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then 
        activeTouches[input] = nil
        return 
    end
    
    local touchData = activeTouches[input]
    if not touchData then return end
    
    local touchDuration = tick() - touchData.startTime
    local isRealTap = not touchData.moved and touchDuration <= TAP_TIME_THRESHOLD
    
    if isRealTap and bombJumpEnabled and not onCooldown and not debounce then
        local bombInHand = GetBombInHand()
        if bombInHand then
            FastBombJump()
        end
    end
    
    activeTouches[input] = nil
end)

local characterConnection = LocalPlayer.CharacterAdded:Connect(function()
    ResetCooldown()
    activeTouches = {}
    justRespawned = true
    
    task.spawn(function()
        task.wait(1)
        justRespawned = false
    end)
    
    if autoGetBomb then
        task.wait(1.2)
        pcall(function()
            ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
        end)
    end
    
    if clickBombJumpEnabled then
        task.wait(1.2)
        SetupBombEquipDetection()
    end
end)

section:AddToggle("Enable Auto Bomb Jump", function(bool)
    bombJumpEnabled = bool
end)

section:AddToggle("Enable Equip Bomb Jump", function(bool)
    clickBombJumpEnabled = bool
    
    if bool then
        SetupBombEquipDetection()
    else
        for _, connection in pairs(bombEquipConnections) do
            connection:Disconnect()
        end
        bombEquipConnections = {}
    end
end)

section:AddToggle("Auto-Get Fake Bomb", function(bool)
    autoGetBomb = bool
end)

section:AddToggle("Enable BJ Button", function(e)
    guiEnabled = e
    if e then 
        CreateBJButton() 
    else 
        if bjGui then bjGui:Destroy() end 
    end
end)

section:AddSlider("BJ Button Size", 30, 150, bjSize, function(s)
    bjSize = s
    if bjBtn then 
        bjBtn.Size = UDim2.new(0, s, 0, s)
        bjBtn.Position = UDim2.new(0.5, -s/2, 0.8, 0)
    end
end)

section:AddToggle("Enable Timer Display", function(e)
    timerGuiEnabled = e
    if e then 
        CreateTimerDisplay() 
    else 
        if timerGui then timerGui:Destroy() end 
    end
end)

section:AddSlider("Timer Display Size", 30, 150, timerSize, function(s)
    timerSize = s
    if timerDisplay then 
        timerDisplay.Size = UDim2.new(0, s, 0, s)
        timerDisplay.Position = UDim2.new(0.5, -s/2 + 60, 0.8, 0)
    end
end)

section:AddKeybind("Manual Bomb Jump", "E", function()
    if not onCooldown and not debounce then
        FastBombJump()
    end
end)

local function Cleanup()
    if bjGui then bjGui:Destroy() end
    if timerGui then timerGui:Destroy() end
    
    if inputBeganConnection then inputBeganConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    if inputEndedConnection then inputEndedConnection:Disconnect() end
    if characterConnection then characterConnection:Disconnect() end
    
    for _, connection in pairs(bombEquipConnections) do
        connection:Disconnect()
    end
    
    activeTouches = {}
    bombEquipConnections = {}
    ResetCooldown()
    bombJumpEnabled = false
    clickBombJumpEnabled = false
    guiEnabled = false
    timerGuiEnabled = false
    autoGetBomb = false
end

do
    local Players = game:GetService("Players")
    local plr = Players.LocalPlayer
    
    local feAnimSection = shared.AddSection("FE Animations")
    
    local animState = {
        all = "Default",
        idle = "Default",
        walk = "Default",
        run = "Default",
        jump = "Default",
        climb = "Default",
        fall = "Default"
    }
    
    local originalAnims = {}
    
    local animPresets = {
        ["Default"] = nil,
        ["Vampire"] = {
            idle1 = "http://www.roblox.com/asset/?id=1083445855",
            idle2 = "http://www.roblox.com/asset/?id=1083450166",
            walk = "http://www.roblox.com/asset/?id=1083473930",
            run = "http://www.roblox.com/asset/?id=1083462077",
            jump = "http://www.roblox.com/asset/?id=1083455352",
            climb = "http://www.roblox.com/asset/?id=1083439238",
            fall = "http://www.roblox.com/asset/?id=1083443587"
        },
        ["Hero"] = {
            idle1 = "http://www.roblox.com/asset/?id=616111295",
            idle2 = "http://www.roblox.com/asset/?id=616113536",
            walk = "http://www.roblox.com/asset/?id=616122287",
            run = "http://www.roblox.com/asset/?id=616117076",
            jump = "http://www.roblox.com/asset/?id=616115533",
            climb = "http://www.roblox.com/asset/?id=616104706",
            fall = "http://www.roblox.com/asset/?id=616108001"
        },
        ["Zombie Classic"] = {
            idle1 = "http://www.roblox.com/asset/?id=616158929",
            idle2 = "http://www.roblox.com/asset/?id=616160636",
            walk = "http://www.roblox.com/asset/?id=616168032",
            run = "http://www.roblox.com/asset/?id=616163682",
            jump = "http://www.roblox.com/asset/?id=616161997",
            climb = "http://www.roblox.com/asset/?id=616156119",
            fall = "http://www.roblox.com/asset/?id=616157476"
        },
        ["Mage"] = {
            idle1 = "http://www.roblox.com/asset/?id=707742142",
            idle2 = "http://www.roblox.com/asset/?id=707855907",
            walk = "http://www.roblox.com/asset/?id=707897309",
            run = "http://www.roblox.com/asset/?id=707861613",
            jump = "http://www.roblox.com/asset/?id=707853694",
            climb = "http://www.roblox.com/asset/?id=707826056",
            fall = "http://www.roblox.com/asset/?id=707829716"
        },
        ["Ghost"] = {
            idle1 = "http://www.roblox.com/asset/?id=616006778",
            idle2 = "http://www.roblox.com/asset/?id=616008087",
            walk = "http://www.roblox.com/asset/?id=616010382",
            run = "http://www.roblox.com/asset/?id=616013216",
            jump = "http://www.roblox.com/asset/?id=616008936",
            climb = "http://www.roblox.com/asset/?id=616003713",
            fall = "http://www.roblox.com/asset/?id=616005863"
        },
        ["Elder"] = {
            idle1 = "http://www.roblox.com/asset/?id=845397899",
            idle2 = "http://www.roblox.com/asset/?id=845400520",
            walk = "http://www.roblox.com/asset/?id=845403856",
            run = "http://www.roblox.com/asset/?id=845386501",
            jump = "http://www.roblox.com/asset/?id=845398858",
            climb = "http://www.roblox.com/asset/?id=845392038",
            fall = "http://www.roblox.com/asset/?id=845396048"
        },
        ["Levitation"] = {
            idle1 = "http://www.roblox.com/asset/?id=616006778",
            idle2 = "http://www.roblox.com/asset/?id=616008087",
            walk = "http://www.roblox.com/asset/?id=616013216",
            run = "http://www.roblox.com/asset/?id=616010382",
            jump = "http://www.roblox.com/asset/?id=616008936",
            climb = "http://www.roblox.com/asset/?id=616003713",
            fall = "http://www.roblox.com/asset/?id=616005863"
        },
        ["Astronaut"] = {
            idle1 = "http://www.roblox.com/asset/?id=891621366",
            idle2 = "http://www.roblox.com/asset/?id=891633237",
            walk = "http://www.roblox.com/asset/?id=891667138",
            run = "http://www.roblox.com/asset/?id=891636393",
            jump = "http://www.roblox.com/asset/?id=891627522",
            climb = "http://www.roblox.com/asset/?id=891609353",
            fall = "http://www.roblox.com/asset/?id=891617961"
        },
        ["Ninja"] = {
            idle1 = "http://www.roblox.com/asset/?id=656117400",
            idle2 = "http://www.roblox.com/asset/?id=656118341",
            walk = "http://www.roblox.com/asset/?id=656121766",
            run = "http://www.roblox.com/asset/?id=656118852",
            jump = "http://www.roblox.com/asset/?id=656117878",
            climb = "http://www.roblox.com/asset/?id=656114359",
            fall = "http://www.roblox.com/asset/?id=656115606"
        },
        ["Werewolf"] = {
            idle1 = "http://www.roblox.com/asset/?id=1083195517",
            idle2 = "http://www.roblox.com/asset/?id=1083214717",
            walk = "http://www.roblox.com/asset/?id=1083178339",
            run = "http://www.roblox.com/asset/?id=1083216690",
            jump = "http://www.roblox.com/asset/?id=1083218792",
            climb = "http://www.roblox.com/asset/?id=1083182000",
            fall = "http://www.roblox.com/asset/?id=1083189019"
        },
        ["Cartoon"] = {
            idle1 = "http://www.roblox.com/asset/?id=742637544",
            idle2 = "http://www.roblox.com/asset/?id=742638445",
            walk = "http://www.roblox.com/asset/?id=742640026",
            run = "http://www.roblox.com/asset/?id=742638842",
            jump = "http://www.roblox.com/asset/?id=742637942",
            climb = "http://www.roblox.com/asset/?id=742636889",
            fall = "http://www.roblox.com/asset/?id=742637151"
        },
        ["Pirate"] = {
            idle1 = "http://www.roblox.com/asset/?id=750781874",
            idle2 = "http://www.roblox.com/asset/?id=750782770",
            walk = "http://www.roblox.com/asset/?id=750785693",
            run = "http://www.roblox.com/asset/?id=750783738",
            jump = "http://www.roblox.com/asset/?id=750782230",
            climb = "http://www.roblox.com/asset/?id=750779899",
            fall = "http://www.roblox.com/asset/?id=750780242"
        },
        ["Sneaky"] = {
            idle1 = "http://www.roblox.com/asset/?id=1132473842",
            idle2 = "http://www.roblox.com/asset/?id=1132477671",
            walk = "http://www.roblox.com/asset/?id=1132510133",
            run = "http://www.roblox.com/asset/?id=1132494274",
            jump = "http://www.roblox.com/asset/?id=1132489853",
            climb = "http://www.roblox.com/asset/?id=1132461372",
            fall = "http://www.roblox.com/asset/?id=1132469004"
        },
        ["Toy"] = {
            idle1 = "http://www.roblox.com/asset/?id=782841498",
            idle2 = "http://www.roblox.com/asset/?id=782845736",
            walk = "http://www.roblox.com/asset/?id=782843345",
            run = "http://www.roblox.com/asset/?id=782842708",
            jump = "http://www.roblox.com/asset/?id=782847020",
            climb = "http://www.roblox.com/asset/?id=782843869",
            fall = "http://www.roblox.com/asset/?id=782846423"
        },
        ["Knight"] = {
            idle1 = "http://www.roblox.com/asset/?id=657595757",
            idle2 = "http://www.roblox.com/asset/?id=657568135",
            walk = "http://www.roblox.com/asset/?id=657552124",
            run = "http://www.roblox.com/asset/?id=657564596",
            jump = "http://www.roblox.com/asset/?id=658409194",
            climb = "http://www.roblox.com/asset/?id=658360781",
            fall = "http://www.roblox.com/asset/?id=657600338"
        },
        ["Confident"] = {
            idle1 = "http://www.roblox.com/asset/?id=1069977950",
            idle2 = "http://www.roblox.com/asset/?id=1069987858",
            walk = "http://www.roblox.com/asset/?id=1070017263",
            run = "http://www.roblox.com/asset/?id=1070001516",
            jump = "http://www.roblox.com/asset/?id=1069984524",
            climb = "http://www.roblox.com/asset/?id=1069946257",
            fall = "http://www.roblox.com/asset/?id=1069973677"
        },
        ["Popstar"] = {
            idle1 = "http://www.roblox.com/asset/?id=1212900985",
            idle2 = "http://www.roblox.com/asset/?id=1212900985",
            walk = "http://www.roblox.com/asset/?id=1212980338",
            run = "http://www.roblox.com/asset/?id=1212980348",
            jump = "http://www.roblox.com/asset/?id=1212954642",
            climb = "http://www.roblox.com/asset/?id=1213044953",
            fall = "http://www.roblox.com/asset/?id=1212900995"
        },
        ["Princess"] = {
            idle1 = "http://www.roblox.com/asset/?id=941003647",
            idle2 = "http://www.roblox.com/asset/?id=941013098",
            walk = "http://www.roblox.com/asset/?id=941028902",
            run = "http://www.roblox.com/asset/?id=941015281",
            jump = "http://www.roblox.com/asset/?id=941008832",
            climb = "http://www.roblox.com/asset/?id=940996062",
            fall = "http://www.roblox.com/asset/?id=941000007"
        },
        ["Cowboy"] = {
            idle1 = "http://www.roblox.com/asset/?id=1014390418",
            idle2 = "http://www.roblox.com/asset/?id=1014398616",
            walk = "http://www.roblox.com/asset/?id=1014421541",
            run = "http://www.roblox.com/asset/?id=1014401683",
            jump = "http://www.roblox.com/asset/?id=1014394726",
            climb = "http://www.roblox.com/asset/?id=1014380606",
            fall = "http://www.roblox.com/asset/?id=1014384571"
        },
        ["Patrol"] = {
            idle1 = "http://www.roblox.com/asset/?id=1149612882",
            idle2 = "http://www.roblox.com/asset/?id=1150842221",
            walk = "http://www.roblox.com/asset/?id=1151231493",
            run = "http://www.roblox.com/asset/?id=1150967949",
            jump = "http://www.roblox.com/asset/?id=1150944216",
            climb = "http://www.roblox.com/asset/?id=1148811837",
            fall = "http://www.roblox.com/asset/?id=1148863382"
        },
        ["Zombie FE"] = {
            idle1 = "http://www.roblox.com/asset/?id=3489171152",
            idle2 = "http://www.roblox.com/asset/?id=3489171152",
            walk = "http://www.roblox.com/asset/?id=3489174223",
            run = "http://www.roblox.com/asset/?id=3489173414",
            jump = "http://www.roblox.com/asset/?id=616161997",
            climb = "http://www.roblox.com/asset/?id=616156119",
            fall = "http://www.roblox.com/asset/?id=616157476"
        }
    }
    
    local function saveOriginalAnimations(character)
        local Animate = character:FindFirstChild("Animate")
        if not Animate then return end
        
        if originalAnims.idle1 then return end
        
        if Animate:FindFirstChild("idle") then
            local anim1 = Animate.idle:FindFirstChild("Animation1")
            local anim2 = Animate.idle:FindFirstChild("Animation2")
            if anim1 then originalAnims.idle1 = anim1.AnimationId end
            if anim2 then originalAnims.idle2 = anim2.AnimationId end
        end
        
        if Animate:FindFirstChild("walk") then
            local walkAnim = Animate.walk:FindFirstChild("WalkAnim")
            if walkAnim then originalAnims.walk = walkAnim.AnimationId end
        end
        
        if Animate:FindFirstChild("run") then
            local runAnim = Animate.run:FindFirstChild("RunAnim")
            if runAnim then originalAnims.run = runAnim.AnimationId end
        end
        
        if Animate:FindFirstChild("jump") then
            local jumpAnim = Animate.jump:FindFirstChild("JumpAnim")
            if jumpAnim then originalAnims.jump = jumpAnim.AnimationId end
        end
        
        if Animate:FindFirstChild("climb") then
            local climbAnim = Animate.climb:FindFirstChild("ClimbAnim")
            if climbAnim then originalAnims.climb = climbAnim.AnimationId end
        end
        
        if Animate:FindFirstChild("fall") then
            local fallAnim = Animate.fall:FindFirstChild("FallAnim")
            if fallAnim then originalAnims.fall = fallAnim.AnimationId end
        end
    end
    
    local function stopAllAnimations()
        local character = plr.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
    
    -- NEW: Check if any animation is set to non-Default
    local function shouldApplyAnimations()
        -- If "All Animations" is set to something other than Default, apply
        if animState.all ~= "Default" then
            return true
        end
        
        -- Check if ANY individual category is set to non-Default
        if animState.idle ~= "Default" then return true end
        if animState.walk ~= "Default" then return true end
        if animState.run ~= "Default" then return true end
        if animState.jump ~= "Default" then return true end
        if animState.climb ~= "Default" then return true end
        if animState.fall ~= "Default" then return true end
        
        -- All are Default, don't touch animations
        return false
    end
    
    local function applyAnimations()
        if not plr or not plr.Character then 
            return 
        end
        
        -- NEW: Don't apply if everything is Default
        if not shouldApplyAnimations() then
            return
        end
        
        local character = plr.Character
        local Animate = character:FindFirstChild("Animate")
        
        if not Animate then
            return
        end
        
        saveOriginalAnimations(character)
        
        stopAllAnimations()
        
        Animate.Disabled = true
        task.wait(0.1)
        
        local function getPresetForType(animType)
            if animState[animType] ~= "Default" then
                return animState[animType]
            end
            if animState.all ~= "Default" then
                return animState.all
            end
            return "Default"
        end
        
        local idlePreset = getPresetForType("idle")
        if Animate:FindFirstChild("idle") then
            local anim1 = Animate.idle:FindFirstChild("Animation1")
            local anim2 = Animate.idle:FindFirstChild("Animation2")
            
            if idlePreset == "Default" then
                if anim1 and originalAnims.idle1 then anim1.AnimationId = originalAnims.idle1 end
                if anim2 and originalAnims.idle2 then anim2.AnimationId = originalAnims.idle2 end
            elseif animPresets[idlePreset] then
                local preset = animPresets[idlePreset]
                if anim1 and preset.idle1 then anim1.AnimationId = preset.idle1 end
                if anim2 and preset.idle2 then anim2.AnimationId = preset.idle2 end
            end
        end
        
        local walkPreset = getPresetForType("walk")
        if Animate:FindFirstChild("walk") then
            local walkAnim = Animate.walk:FindFirstChild("WalkAnim")
            
            if walkPreset == "Default" then
                if walkAnim and originalAnims.walk then walkAnim.AnimationId = originalAnims.walk end
            elseif animPresets[walkPreset] then
                local preset = animPresets[walkPreset]
                if walkAnim and preset.walk then walkAnim.AnimationId = preset.walk end
            end
        end
        
        local runPreset = getPresetForType("run")
        if Animate:FindFirstChild("run") then
            local runAnim = Animate.run:FindFirstChild("RunAnim")
            
            if runPreset == "Default" then
                if runAnim and originalAnims.run then runAnim.AnimationId = originalAnims.run end
            elseif animPresets[runPreset] then
                local preset = animPresets[runPreset]
                if runAnim and preset.run then runAnim.AnimationId = preset.run end
            end
        end
        
        local jumpPreset = getPresetForType("jump")
        if Animate:FindFirstChild("jump") then
            local jumpAnim = Animate.jump:FindFirstChild("JumpAnim")
            
            if jumpPreset == "Default" then
                if jumpAnim and originalAnims.jump then jumpAnim.AnimationId = originalAnims.jump end
            elseif animPresets[jumpPreset] then
                local preset = animPresets[jumpPreset]
                if jumpAnim and preset.jump then jumpAnim.AnimationId = preset.jump end
            end
        end
        
        local climbPreset = getPresetForType("climb")
        if Animate:FindFirstChild("climb") then
            local climbAnim = Animate.climb:FindFirstChild("ClimbAnim")
            
            if climbPreset == "Default" then
                if climbAnim and originalAnims.climb then climbAnim.AnimationId = originalAnims.climb end
            elseif animPresets[climbPreset] then
                local preset = animPresets[climbPreset]
                if climbAnim and preset.climb then climbAnim.AnimationId = preset.climb end
            end
        end
        
        local fallPreset = getPresetForType("fall")
        if Animate:FindFirstChild("fall") then
            local fallAnim = Animate.fall:FindFirstChild("FallAnim")
            
            if fallPreset == "Default" then
                if fallAnim and originalAnims.fall then fallAnim.AnimationId = originalAnims.fall end
            elseif animPresets[fallPreset] then
                local preset = animPresets[fallPreset]
                if fallAnim and preset.fall then fallAnim.AnimationId = preset.fall end
            end
        end
        
        Animate.Disabled = false
    end
    
    plr.CharacterAdded:Connect(function(character)
        character:WaitForChild("Animate")
        task.wait(0.5)
        applyAnimations()
    end)
    
    if plr.Character then
        saveOriginalAnimations(plr.Character)
    end
    
    feAnimSection:AddDropdown("All Animations", {
        "Default", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost", 
        "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon", 
        "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar", 
        "Princess", "Cowboy", "Patrol", "Zombie FE"
    }, function(selected)
        animState.all = selected
        applyAnimations()
    end)
    
    local animOptions = {
        "Default", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost", 
        "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon", 
        "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar", 
        "Princess", "Cowboy", "Patrol", "Zombie FE"
    }
    
    feAnimSection:AddDropdown("Idle Animation", animOptions, function(selected)
        animState.idle = selected
        applyAnimations()
    end)
    
    feAnimSection:AddDropdown("Walk Animation", animOptions, function(selected)
        animState.walk = selected
        applyAnimations()
    end)
    
    feAnimSection:AddDropdown("Run Animation", animOptions, function(selected)
        animState.run = selected
        applyAnimations()
    end)
    
    feAnimSection:AddDropdown("Jump Animation", animOptions, function(selected)
        animState.jump = selected
        applyAnimations()
    end)
    
    feAnimSection:AddDropdown("Climb Animation", animOptions, function(selected)
        animState.climb = selected
        applyAnimations()
    end)
    
    feAnimSection:AddDropdown("Fall Animation", animOptions, function(selected)
        animState.fall = selected
        applyAnimations()
    end)
end

do
    local wallhopSection = shared.AddSection("Wallhop")
    
    -- Services
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    
    -- Player specific
    local player = Players.LocalPlayer
    
    -- Variables for Wallhop Functionality
    local wallhopToggle = false
    local InfiniteJumpEnabled = true
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local jumpConnection = nil
    
    -- Precise wall detection function
    local function getWallRaycastResult()
        local character = player.Character
        if not character then return nil end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return nil end
    
        raycastParams.FilterDescendantsInstances = {character}
        local detectionDistance = 2
        local closestHit = nil
        local minDistance = detectionDistance + 1
        local hrpCF = humanoidRootPart.CFrame
    
        for i = 0, 7 do
            local angle = math.rad(i * 45)
            local direction = (hrpCF * CFrame.Angles(0, angle, 0)).LookVector
            local ray = Workspace:Raycast(humanoidRootPart.Position, direction * detectionDistance, raycastParams)
            if ray and ray.Instance and ray.Distance < minDistance then
                minDistance = ray.Distance
                closestHit = ray
            end
        end
    
        local blockCastSize = Vector3.new(1.5, 1, 0.5)
        local blockCastOffset = CFrame.new(0, -1, -0.5)
        local blockCastOriginCF = hrpCF * blockCastOffset
        local blockCastDirection = hrpCF.LookVector
        local blockCastDistance = 1.5
        local blockResult = Workspace:Blockcast(blockCastOriginCF, blockCastSize, blockCastDirection * blockCastDistance, raycastParams)
    
        if blockResult and blockResult.Instance and blockResult.Distance < minDistance then
             minDistance = blockResult.Distance
             closestHit = blockResult
        end
    
        return closestHit
    end
    
    -- Core Wall Jump Execution Function
    local function executeWallJump(wallRayResult)
        if not InfiniteJumpEnabled then return end
    
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera
    
        if not (humanoid and rootPart and camera and humanoid:GetState() ~= Enum.HumanoidStateType.Dead and wallRayResult) then
            return
        end
    
        InfiniteJumpEnabled = false
    
        local maxInfluenceAngleRight = math.rad(20)
        local maxInfluenceAngleLeft  = math.rad(-100)
    
        local wallNormal = wallRayResult.Normal
        local baseDirectionAwayFromWall = Vector3.new(wallNormal.X, 0, wallNormal.Z).Unit
        if baseDirectionAwayFromWall.Magnitude < 0.1 then
             local dirToHit = (wallRayResult.Position - rootPart.Position) * Vector3.new(1,0,1)
             baseDirectionAwayFromWall = -dirToHit.Unit
             if baseDirectionAwayFromWall.Magnitude < 0.1 then
                 baseDirectionAwayFromWall = -rootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
                 if baseDirectionAwayFromWall.Magnitude > 0.1 then baseDirectionAwayFromWall = baseDirectionAwayFromWall.Unit end
                 if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall = Vector3.new(0,0,1) end
             end
        end
        baseDirectionAwayFromWall = Vector3.new(baseDirectionAwayFromWall.X, 0, baseDirectionAwayFromWall.Z).Unit
        if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall = Vector3.new(0,0,1) end
    
        local cameraLook = camera.CFrame.LookVector
        local horizontalCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
        if horizontalCameraLook.Magnitude < 0.1 then horizontalCameraLook = baseDirectionAwayFromWall end
    
        local dot = math.clamp(baseDirectionAwayFromWall:Dot(horizontalCameraLook), -1, 1)
        local angleBetween = math.acos(dot)
        local cross = baseDirectionAwayFromWall:Cross(horizontalCameraLook)
        local rotationSign = -math.sign(cross.Y)
        if rotationSign == 0 then angleBetween = 0 end
    
        local actualInfluenceAngle
        if rotationSign == 1 then
            actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleRight)
        elseif rotationSign == -1 then
            actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleLeft)
        else
            actualInfluenceAngle = 0
        end
    
        local adjustmentRotation = CFrame.Angles(0, actualInfluenceAngle * rotationSign, 0)
        local initialTargetLookDirection = adjustmentRotation * baseDirectionAwayFromWall
    
        rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + initialTargetLookDirection)
        RunService.Heartbeat:Wait()
    
        local didJump = false
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
             humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
             didJump = true
    
             rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, -1, 0)
             task.wait(0.15)
             rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, 1, 0)
        end
    
        if didJump then
             local directionTowardsWall = -baseDirectionAwayFromWall
             task.wait(0.05)
             rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + directionTowardsWall)
        end
    
        task.wait(0.1)
        InfiniteJumpEnabled = true
    end
    
    -- Main Wallhop Toggle
    wallhopSection:AddToggle("Enable Wallhop", function(enabled)
        wallhopToggle = enabled
        
        if enabled then
            if jumpConnection then jumpConnection:Disconnect() end
            
            jumpConnection = UserInputService.JumpRequest:Connect(function()
                if not wallhopToggle then return end
                
                local wallRayResult = getWallRaycastResult()
                if wallRayResult then
                    executeWallJump(wallRayResult)
                end
            end)
        else
            if jumpConnection then
                jumpConnection:Disconnect()
                jumpConnection = nil
            end
        end
    end)
    
    -- Cleanup on player leaving
    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then
            if jumpConnection then jumpConnection:Disconnect() end
        end
    end)
end

end
