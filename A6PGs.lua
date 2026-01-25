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

local shared = odh_shared_plugins

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
local apConn, apCharConn

local function playSelectedSong()
    if lastSelectedSong then
        PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. lastSelectedSong.id)
    end
end

radioSection:AddToggle("Auto Play Selected Audio", function(state)
    autoPlayEnabled = state
    if apConn then apConn:Disconnect() apConn = nil end
    if apCharConn then apCharConn:Disconnect() apCharConn = nil end
    
    if autoPlayEnabled then
        apConn = RoleSelect.OnClientEvent:Connect(playSelectedSong)
        apCharConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            playSelectedSong()
        end)
        if LocalPlayer.Character then
            task.wait(1)
            playSelectedSong()
        end
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

local mapVoterSection = shared.AddSection("Map Voter")
local voterRespawnAmount = 12
local savedPos = nil
local isRespawning = false

mapVoterSection:AddSlider("Votes Amount", 1, 20, voterRespawnAmount, function(v) voterRespawnAmount = v end)
mapVoterSection:AddButton("Vote Map", function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    savedPos = LocalPlayer.Character.HumanoidRootPart.Position
    isRespawning = true
    local count = 0
    
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
    end)
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        if savedPos then
            char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(savedPos)
        end
    end)
end)

local whitelistSection = shared.AddSection("Whitelist")
local whitelist = {}

whitelistSection:AddLabel("Ignores WL Players")
whitelistSection:AddPlayerDropdown("Whitelist Player", function(p)
    if not table.find(whitelist, p.UserId) then
        table.insert(whitelist, p.UserId)
        shared.Notify(p.Name .. " whitelisted.", 2)
    end
end)
whitelistSection:AddPlayerDropdown("Unwhitelist Player", function(p)
    for i, id in ipairs(whitelist) do
        if id == p.UserId then
            table.remove(whitelist, i)
            shared.Notify(p.Name .. " unwhitelisted.", 2)
            break
        end
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
        local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(decalSave)) end)
        if ok and type(data) == "table" then decals = data end
    end
    
    local function saveDecals()
        if writefile then writefile(decalSave, Services.HttpService:JSONEncode(decals)) end
    end
    
    local sprayId = 0
    local sprayTargetMode = "Nearest Player"
    local spraySelectedPlr = nil
    local sprayDecalName = nil
    local sprayLoop = false
    local sprayThread
    local decalDropdown
    
    local function getSprayTool()
        local c = LocalPlayer.Character
        return (c and c:FindFirstChild("SprayPaint")) or (LocalPlayer.Backpack:FindFirstChild("SprayPaint"))
    end
    
    local function getSprayTarget()
        if sprayTargetMode == "Nearest Player" then
            local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not r then return nil end
            local n, s = nil, math.huge
            for _, p in pairs(Services.Players:GetPlayers()) do
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
            for _, p in pairs(Services.Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then table.insert(t, p) end end
            return (#t > 0 and t[math.random(1, #t)]) or nil
        elseif sprayTargetMode == "Select Player" then
            return spraySelectedPlr
        end
    end
    
    local function performSpray(tgt)
        local tool = getSprayTool()
        if not tool or not tgt or not tgt.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            tool.Parent = LocalPlayer.Character
            hum:EquipTool(tool)
        end
        local torso = tgt.Character:FindFirstChild("UpperTorso") or tgt.Character:FindFirstChild("Torso") or tgt.Character:FindFirstChild("HumanoidRootPart")
        if not torso then return end
        tool:FindFirstChildWhichIsA("RemoteEvent"):FireServer(sprayId, Enum.NormalId.Front, 2048, torso, torso.CFrame + torso.CFrame.LookVector * 0.6)
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
    spraySection:AddToggle("Auto-Get Spray Tool", function(s) autoGet = s end)
    LocalPlayer.CharacterAdded:Connect(function()
        if autoGet then
            task.wait(1)
            Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint")
        end
    end)
    spraySection:AddButton("Get Spray Tool", function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint") end)
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
    local rfxSection = shared.AddSection("RFX")
    local rfx = {Blur=nil, CC=nil, Bloom=nil, Sun=nil, DOF=nil}
    local rfxOn = false
    
    local function mkRfx()
        if not rfx.Blur then rfx.Blur = Instance.new("BlurEffect", Services.Lighting) rfx.Blur.Size = 2 end
        if not rfx.CC then rfx.CC = Instance.new("ColorCorrectionEffect", Services.Lighting) rfx.CC.Brightness = 0.05 rfx.CC.Contrast = 0.1 rfx.CC.Saturation = 0.15 rfx.CC.TintColor = Color3.fromRGB(255,245,230) end
        if not rfx.Bloom then rfx.Bloom = Instance.new("BloomEffect", Services.Lighting) rfx.Bloom.Intensity = 0.5 rfx.Bloom.Size = 40 end
        if not rfx.Sun then rfx.Sun = Instance.new("SunRaysEffect", Services.Lighting) rfx.Sun.Intensity = 0.2 end
        if not rfx.DOF then rfx.DOF = Instance.new("DepthOfFieldEffect", Services.Lighting) rfx.DOF.InFocusRadius = 30 rfx.DOF.FocusDistance = 25 end
    end
    
    local function setRfx(s)
        rfxOn = s
        if s then mkRfx() end
        for _, v in pairs(rfx) do if v then v.Enabled = s end end
    end
    
    rfxSection:AddToggle("Enable RFX", setRfx)
    rfxSection:AddSlider("RFX Intensity", 1, 100, 50, function(v)
        if rfxOn then
            if rfx.Bloom then rfx.Bloom.Intensity = v/100 end
            if rfx.Sun then rfx.Sun.Intensity = v/100 * 0.4 end
            if rfx.CC then rfx.CC.Contrast = v/100 * 0.3 end
        end
    end)
    rfxSection:AddDropdown("RFX Presets", {"Cinematic", "Warm", "Cold", "HDR"}, function(p)
        if not rfxOn or not rfx.CC then return end
        if p == "Cinematic" then rfx.CC.TintColor = Color3.fromRGB(255,240,220) rfx.Bloom.Intensity = 0.3
        elseif p == "Warm" then rfx.CC.TintColor = Color3.fromRGB(255,220,180) rfx.Bloom.Intensity = 0.4
        elseif p == "Cold" then rfx.CC.TintColor = Color3.fromRGB(200,220,255) rfx.Bloom.Intensity = 0.35
        elseif p == "HDR" then rfx.CC.TintColor = Color3.new(1,1,1) rfx.Bloom.Intensity = 0.6 end
    end)
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
    local hlOn = false
    local hlOn2 = false
    local hlTrack
    local hlTrack2
    local freezeConnection
    local freezeConnection2
    local stoppedConnection
    local stoppedConnection2
    
    local function stopHl()
        if stoppedConnection then stoppedConnection:Disconnect() stoppedConnection = nil end
        if hlTrack then hlTrack:Stop() hlTrack:Destroy() hlTrack = nil end
    end
    
    local function stopHl2()
        if stoppedConnection2 then stoppedConnection2:Disconnect() stoppedConnection2 = nil end
        if hlTrack2 then hlTrack2:Stop() hlTrack2:Destroy() hlTrack2 = nil end
    end
    
    local function cleanup()
        stopHl()
        stopHl2()
        if freezeConnection then freezeConnection:Disconnect() freezeConnection = nil end
        if freezeConnection2 then freezeConnection2:Disconnect() freezeConnection2 = nil end
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
    
    -- Clean up before character is removed
    LocalPlayer.CharacterRemoving:Connect(function()
        cleanup()
    end)
    
    -- Re-enable after character is added
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if hlOn then enableHl() end
        if hlOn2 then enableHl2() end
    end)
end

do
    local flingSection = shared.AddSection("Fling")
    local flingLoopPlr = false
    local flingLoopAll = false
    local flingSelPlr = nil
    
    local function msg(t, txt, d) Services.StarterGui:SetCore("SendNotification", {Title=t, Text=txt, Duration=d}) end
    
    local function skidFling(target)
        local c = LocalPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        
        local tc = target.Character
        local tr = tc and tc:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        
        local oldPos = r.CFrame
        local bv = Instance.new("BodyVelocity", r)
        bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
        bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        local t = tick()
        while tick() - t < 2 and target.Parent and tc.Parent and r.Parent do
            r.CFrame = tr.CFrame * CFrame.new(0,0,0)
            r.Velocity = Vector3.new(9e7, 9e7*10, 9e7)
            r.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            task.wait()
        end
        
        bv:Destroy()
        r.CFrame = oldPos
        r.Velocity = Vector3.zero
    end
    
    flingSection:AddButton("Fling Sheriff", function()
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p.Backpack:FindFirstChild("Gun") then skidFling(p) return end
        end
        msg("Error", "No Sheriff", 3)
    end)
    
    flingSection:AddButton("Fling Murderer", function()
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p.Backpack:FindFirstChild("Knife") then skidFling(p) return end
        end
        msg("Error", "No Murderer", 3)
    end)
    
    flingSection:AddButton("Fling All", function() for _, p in pairs(Services.Players:GetPlayers()) do if p ~= LocalPlayer then skidFling(p) end end end)
    flingSection:AddPlayerDropdown("Fling Player", function(p) flingSelPlr = p if p ~= LocalPlayer then skidFling(p) end end)
    
    flingSection:AddToggle("Loop Fling Player", function(s)
        flingLoopPlr = s
        task.spawn(function()
            while flingLoopPlr do
                if flingSelPlr and flingSelPlr.Parent then skidFling(flingSelPlr) else flingLoopPlr = false end
            end
        end)
    end)
    
    flingSection:AddToggle("Loop Fling All", function(s)
        flingLoopAll = s
        task.spawn(function() while flingLoopAll do for _, p in pairs(Services.Players:GetPlayers()) do if p ~= LocalPlayer then skidFling(p) end end task.wait(5) end end)
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
    
    -- Clean up before character is removed
    LocalPlayer.CharacterRemoving:Connect(function()
        cleanup()
    end)
    
    -- Re-enable after character is added
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if skyOn then enSky() end
    end)
end

local shared = odh_shared_plugins
local section = shared.AddSection("Bomb Jump")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Bomb jump variables
local ScreenGui = nil
local MainFrame = nil
local CircleButton = nil
local dragging = false
local dragStart = nil
local startPos = nil
local onCooldown = false
local bombJumpEnabled = false
local guiEnabled = false
local debounce = false

-- Touch tracking for detecting real taps vs camera movement
local activeTouches = {}
local TAP_MOVEMENT_THRESHOLD = 10 -- pixels moved to be considered a drag vs tap
local TAP_TIME_THRESHOLD = 0.3 -- max time for a tap in seconds

-- Bomb names to detect
local BOMB_NAMES = {"Bomb", "PrankBomb", "FakeBomb"}

section:AddLabel("Bomb Jump Features")
section:AddParagraph("Info", "Toggle features below. Press E for manual bomb jump.")

-- Create GUI
function CreateGUI()
    if ScreenGui then ScreenGui:Destroy() end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BombJumpGUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 65, 0, 65)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.BackgroundTransparency = 1
    MainFrame.Active = true
    MainFrame.Selectable = true
    MainFrame.Parent = ScreenGui

    CircleButton = Instance.new("TextButton")
    CircleButton.Size = UDim2.new(1, 0, 1, 0)
    CircleButton.Position = UDim2.new(0, 0, 0, 0)
    CircleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    CircleButton.BackgroundTransparency = 0.5
    CircleButton.Text = "clutch"
    CircleButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.TextSize = 14
    CircleButton.AutoButtonColor = false
    CircleButton.Active = true
    CircleButton.Selectable = true
    CircleButton.Parent = MainFrame

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0.15, 0)
    UICorner.Parent = CircleButton
end

function QuickButtonPress()
    if not CircleButton then return end
    
    CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    
    task.spawn(function()
        task.wait(0.1)
        if CircleButton and not onCooldown then
            CircleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
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
    
    if CircleButton and CircleButton.Parent then
        CircleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        CircleButton.Text = "clutch"
    end
end

function StartCooldown()
    onCooldown = true
    debounce = false
    
    if CircleButton then
        CircleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        CircleButton.Text = "24"
    end
    
    task.spawn(function()
        for i = 23, 0, -1 do
            if onCooldown and CircleButton then
                CircleButton.Text = tostring(i)
                task.wait(1)
            else
                break
            end
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
    
    -- Check if any bomb is currently equipped
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
    
    -- First check if bomb is in hand
    for _, bombName in ipairs(BOMB_NAMES) do
        local bomb = character:FindFirstChild(bombName)
        if bomb then return true, bomb end
    end
    
    -- Check backpack
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
    
    -- Try to get FakeBomb from server
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
    if onCooldown or debounce then return end
    debounce = true
    
    QuickButtonPress()
    
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

function SetupInputSystem()
    if not MainFrame or not CircleButton then return end
    
    local connection
    local dragInput
    
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    CircleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                end
            end)
        end
    end)
    
    CircleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    CircleButton.MouseButton1Click:Connect(function()
        if not onCooldown and not dragging then
            FastBombJump()
        end
    end)
    
    if UserInputService.TouchEnabled then
        CircleButton.TouchTap:Connect(function()
            if not onCooldown and not dragging then
                FastBombJump()
            end
        end)
    end
end

-- Track touch inputs to distinguish real taps from camera drags
local inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        
        -- Store touch data
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
    
    -- Calculate distance moved
    local delta = input.Position - touchData.startPosition
    local distance = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)
    
    -- Mark as moved if exceeds threshold
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
    
    -- Check if this was a real tap (not moved and quick)
    local touchDuration = tick() - touchData.startTime
    local isRealTap = not touchData.moved and touchDuration <= TAP_TIME_THRESHOLD
    
    -- Only trigger auto bomb jump on real taps
    if isRealTap and bombJumpEnabled and not onCooldown and not debounce then
        local bombInHand = GetBombInHand()
        if bombInHand then
            FastBombJump()
        end
    end
    
    -- Clean up
    activeTouches[input] = nil
end)

-- Character respawn handler
local characterConnection = LocalPlayer.CharacterAdded:Connect(function()
    ResetCooldown()
    activeTouches = {} -- Clear touch tracking on respawn
end)

-- Plugin Toggles
section:AddToggle("Enable Auto Bomb Jump", function(bool)
    bombJumpEnabled = bool
end)

section:AddToggle("Show Clutch Button", function(bool)
    guiEnabled = bool
    if bool then
        CreateGUI()
        SetupInputSystem()
    else
        if ScreenGui then
            ScreenGui:Destroy()
            ScreenGui = nil
        end
    end
end)

section:AddButton("Reset Button Position", function()
    if MainFrame and guiEnabled then
        MainFrame.Position = UDim2.new(0, 20, 0, 20)
    end
end)

section:AddKeybind("Manual Bomb Jump", "E", function()
    if not onCooldown and not debounce then
        FastBombJump()
    end
end)

-- Cleanup function
local function Cleanup()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
    end
    
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
    end
    
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
    end
    
    if characterConnection then
        characterConnection:Disconnect()
    end
    
    activeTouches = {}
    ResetCooldown()
    bombJumpEnabled = false
    guiEnabled = false
end

return Cleanup
