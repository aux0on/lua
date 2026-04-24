local table_insert = table.insert
local table_find = table.find
local math_abs = math.abs

local Maid = {}
Maid.__index = Maid

function Maid.new() 
    return setmetatable({_tasks = {}, _destroyed = false}, Maid) 
end

function Maid:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table_insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for _, task in ipairs({...}) do
        self:GiveTask(task)
    end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function Maid:Destroy() 
    self:DoCleaning() 
end

local RootMaid = Maid.new()

local shared = odh_shared_plugins
if shared.game_name ~= "Murder Mystery 2" then return end

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
    CoreGui = game:GetService("CoreGui"),
    Debris = game:GetService("Debris"),
    VirtualUser = game:GetService("VirtualUser"),
    Stats = game:GetService("Stats"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService")
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlaceId, JobId = game.PlaceId, game.JobId

local __INSERT = table.insert
local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local function getfserv(s)
    local ok, svc = pcall(function() return game:GetService(s) end)
    if ok and svc then return svc end
    ok, svc = pcall(function() return game:FindService(s) end)
    if ok and svc then return svc end
    return game[s]
end

local __RS   = getfserv("RunService")
local __UIS  = getfserv("UserInputService")
local __PLRS = getfserv("Players")
local __TS   = getfserv("TweenService")

local BBSystem = {Buttons = {}, Connections = {}}

local function bb_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BB ERROR] " .. tostring(err)) end
end

local function BB_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@BBStorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@BBStorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local __BB_GRAD_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __PCLR(0.0784314, 0.0784314, 0.0784314)),
    ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
    ColorSequenceKeypoint.new(1,    __PCLR(0.470588,  0.156863,  0.470588))
})

local function BB_MakeDraggable(gui, func, ripple, sound)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local normalSize    = __UD2(0, 200, 0, 75)
    local normalTxtSize = 24
    local bigSize       = __UD2(0, 220, 0, 82.5)
    local bigTxtSize    = 26.4

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            hasMoved  = false
            dragStart = input.Position
            startPos  = gui.Position
            __TS:Create(gui, tInfo, {Size = bigSize, TextSize = bigTxtSize}):Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            sound:Play()
            __TS:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 300, 0, 300),
                BackgroundTransparency = 1
            }):Play()
            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    __TS:Create(gui, tInfo, {Size = normalSize, TextSize = normalTxtSize}):Play()
                    if not hasMoved then bb_safecallback(func) end
                    rel:Disconnect()
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    __UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            gui.Position = __UD2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function AddBigButton(id, text, func)
    if BBSystem.Buttons[id] then return end
    local storage = BB_GetStorage()
    local bb = Instance.new("TextButton")
    bb.Name = id
    bb.Size = __UD2(0, 200, 0, 75)
    bb.Position = __UD2(0.5, 0, 0.5, 0)
    bb.AnchorPoint = __V2(0.5, 0.5)
    bb.BackgroundColor3 = __RGB(255, 255, 255)
    bb.BackgroundTransparency = 0.9
    bb.BorderSizePixel = 0
    bb.Font = Enum.Font.Jura
    bb.Text = text
    bb.TextSize = 24
    bb.TextColor3 = __RGB(255, 255, 255)
    bb.TextWrapped = true
    bb.ClipsDescendants = true
    bb.AutoButtonColor = false
    bb.ZIndex = 5
    bb.Parent = storage

    Instance.new("UICorner", bb).CornerRadius = __UD(0, 5)
    local stroke = Instance.new("UIStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("UIGradient")
    gradient.Color = __BB_GRAD_SEQ
    gradient.Parent = stroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.ZIndex = 4
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.Parent = bb
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = bb

    BB_MakeDraggable(bb, func, ripple, sound)
    BBSystem.Connections[id] = __RS.RenderStepped:Connect(function()
        gradient.Rotation = (gradient.Rotation + 1) % 360
    end)
    BBSystem.Buttons[id] = bb
    return bb
end

local function DeleteBigButton(id)
    if BBSystem.Buttons[id] then
        if BBSystem.Connections[id] then
            BBSystem.Connections[id]:Disconnect()
            BBSystem.Connections[id] = nil
        end
        BBSystem.Buttons[id]:Destroy()
        BBSystem.Buttons[id] = nil
    end
end

local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    
    maid:GiveTask(gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        bind_safecallback(clickFunc)
                    end
                    rel:Disconnect()
                end
            end)
        end
    end))
    
    maid:GiveTask(gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    
    maid:GiveTask(__UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function BindableButtons.AddBButton(id, text, clickFunc)
    if BindableButtons.Buttons[id] then return end
    
    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = __SHAPES[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Jura
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 10
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", ImageButton)
    Stroke.Name = "@Stroke"
    Stroke.Color = __NORMAL_COLOR

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
    buttonMaid:GiveTask(__RS.RenderStepped:Connect(function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    if BindableButtons.Maids[id] then
        BindableButtons.Maids[id]:Destroy()
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
    end
end

local function GetSafeGuiRoot()
    local success, result = pcall(function() 
        return gethui() 
    end)
    if success and result and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local function Notify(title, text, duration)
    Services.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 2})
end

local hiddenGui = Instance.new("ScreenGui")
hiddenGui.Name = "HiddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local aboutSection = shared.AddSection("About")
aboutSection:AddParagraph("ATAOs MM2", "is the version you are using.")

local serverSection = shared.AddSection("Server Options")
serverSection:AddLabel("Might Take a Few Tries")

serverSection:AddButton("Rejoin", function()
    Services.TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
end)

serverSection:AddButton("Server Hop", function()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
    local success, servers = pcall(function()
        return Services.HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and servers and servers.data then
        local available = {}
        for _, server in ipairs(servers.data) do
            if server.id ~= JobId and server.playing < server.maxPlayers then
                table_insert(available, server)
            end
        end
        if #available > 0 then
            Notify("Server hopping...", 2)
            Services.TeleportService:TeleportToPlaceInstance(PlaceId, available[math.random(#available)].id, LocalPlayer)
            return
        end
    end
    Notify("No server found to hop to", 3)
end)

serverSection:AddButton("Join Full Server", function()
    local cursor, bestServer
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
        Notify("Joining full server...", 2)
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id, LocalPlayer)
    else
        Notify("No suitable fuller server found", 3)
    end
end)

serverSection:AddButton("Join Dead Server", function()
    local cursor, lowestServer, lowestCount
    repeat
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(PlaceId, cursor and "&cursor="..cursor or "")
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
        Notify("Joining dead server with "..lowestServer.playing.." players", 3)
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, lowestServer.id, LocalPlayer)
    else
        Notify("No dead server found", 3)
    end
end)

local PlaySong = Services.ReplicatedStorage.Remotes.Inventory.PlaySong
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
    for _, song in ipairs(savedSongs) do
        table_insert(names, song.name or song.id)
    end
    return names
end

local lastSelectedSong
local songDropdown = radioSection:AddDropdown("Saved Songs", getSongNames(), function(selectedName)
    for _, song in ipairs(savedSongs) do
        if song.name == selectedName then
            lastSelectedSong = song
            PlaySong:FireServer("https://www.roblox.com/asset/?id="..song.id)
            break
        end
    end
end)

radioSection:AddButton("Replay Audio", function()
    if lastSelectedSong then
        local url = "https://www.roblox.com/asset/?id="..lastSelectedSong.id
        PlaySong:FireServer(url)
        task.wait(0.1)
        PlaySong:FireServer(url)
    else
        Notify("No audio selected!", 2)
    end
end)

radioSection:AddTextBox("Add Audio ID", function(text)
    local id = text:match("%d+")
    if id then
        local success, info = pcall(function() return Services.MarketplaceService:GetProductInfo(tonumber(id)) end)
        local name = (success and info and info.Name) or id
        table_insert(savedSongs, {name = name, id = id})
        saveSongs()
        songDropdown.Change(getSongNames())
        Notify("Added: "..name, 2)
    else
        Notify("Invalid audio ID!", 2)
    end
end)

radioSection:AddButton("Delete Selected Audio", function()
    if lastSelectedSong then
        for i, song in ipairs(savedSongs) do
            if song.name == lastSelectedSong.name then
                table.remove(savedSongs, i)
                saveSongs()
                songDropdown.Change(getSongNames())
                Notify("Removed: "..lastSelectedSong.name, 2)
                lastSelectedSong = nil
                return
            end
        end
    end
end)

local RadioMaid
local autoPlayEnabled = false

radioSection:AddToggle("Auto Play Selected Audio", function(state)
    if RadioMaid then RadioMaid:Destroy() end
    autoPlayEnabled = state
    
    if autoPlayEnabled then
        RadioMaid = Maid.new()
        RadioMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if lastSelectedSong then
                PlaySong:FireServer("https://www.roblox.com/asset/?id="..lastSelectedSong.id)
            end
        end))
    end
end)

RootMaid:GiveTask(function() if RadioMaid then RadioMaid:Destroy() end end)

local speedGlitchSection = shared.AddSection("Auto Speedglitch")
local asgEnabled, asgHorizontal, asgValue = false, false, 0
local defaultSpeed = 16
local asgChar, asgHum, asgRoot, isInAir
local SpeedGlitchMaid

speedGlitchSection:AddToggle("Enable ASG", function(e)
    if SpeedGlitchMaid then SpeedGlitchMaid:Destroy() end
    asgEnabled = e
    
    if e then
        SpeedGlitchMaid = Maid.new()
        local function setupChar(c)
            asgChar, asgHum, asgRoot = c, c:WaitForChild("Humanoid"), c:WaitForChild("HumanoidRootPart")
            SpeedGlitchMaid:GiveTask(asgHum.StateChanged:Connect(function(_, s)
                isInAir = (s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall)
            end))
        end
        
        if LocalPlayer.Character then setupChar(LocalPlayer.Character) end
        SpeedGlitchMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(setupChar))
        
        SpeedGlitchMaid:GiveTask(Services.RunService.Stepped:Connect(function()
            if not (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled) then return end
            if not asgEnabled or not asgChar or not asgHum or not asgRoot then return end
            
            local targetSpeed = defaultSpeed + asgValue
            if isInAir then
                if asgHorizontal then
                    asgHum.WalkSpeed = (math_abs(asgHum.MoveDirection:Dot(asgRoot.CFrame.RightVector)) > 0.5) and targetSpeed or defaultSpeed
                else
                    asgHum.WalkSpeed = targetSpeed
                end
            else
                asgHum.WalkSpeed = defaultSpeed
            end
        end))
    end
end)

RootMaid:GiveTask(function() if SpeedGlitchMaid then SpeedGlitchMaid:Destroy() end end)
speedGlitchSection:AddToggle("Sideways Only", function(e) asgHorizontal = e end)
speedGlitchSection:AddSlider("Speed (0-255)", 0, 255, 0, function(v) asgValue = v end)

do
    local mapVoterSection = shared.AddSection("Map Voter")
    local voterRespawnAmount = 12
    local savedPos, isRespawning, vmButtonEnabled
    local vmButtonSize = 0.11
    
    local function voteMap()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            Notify("Error", "Character not found", 3)
            return 
        end
        
        savedPos = LocalPlayer.Character.HumanoidRootPart.Position
        isRespawning = true
        local count = 0
        
        Notify("Vote Map", "Starting "..voterRespawnAmount.." respawns...", 3)
        
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
            Notify("Vote Map", "Completed "..count.." votes!", 3)
        end)
        
        local respawnCon = LocalPlayer.CharacterAdded:Connect(function(char)
            if savedPos then
                char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(savedPos)
            else
                respawnCon:Disconnect()
            end
        end)
    end
    
    mapVoterSection:AddSlider("Votes Amount", 1, 20, voterRespawnAmount, function(v) voterRespawnAmount = v end)
    mapVoterSection:AddButton("Vote Map", voteMap)
    
    mapVoterSection:AddToggle("Enable VM Button", function(enabled)
        vmButtonEnabled = enabled
        
        if enabled then
            BindableButtons.AddBButton("vm_bind", "VM", voteMap)
            local btn = BindableButtons.Buttons["vm_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(vmButtonSize * (screen.Y / screen.X), 0, vmButtonSize, 0)
            end
        else
            BindableButtons.DeleteBButton("vm_bind")
        end
    end)
    
    mapVoterSection:AddSlider("VM Button Size", 5, 25, 11, function(value)
        vmButtonSize = value / 100
        local btn = BindableButtons.Buttons["vm_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(vmButtonSize * (screen.Y / screen.X), 0, vmButtonSize, 0)
        end
    end)
end

local whitelistSection = shared.AddSection("Kill All")
local whitelist = {}

whitelistSection:AddLabel("Ignores Whitelisted Players")
whitelistSection:AddPlayerDropdown("Whitelist Player", function(p)
    if not table_find(whitelist, p.UserId) then
        table_insert(whitelist, p.UserId)
        Notify(p.Name.." whitelisted.", 2)
    end
end)

whitelistSection:AddButton("Clear Whitelist", function()
    whitelist = {}
    Notify("Whitelist cleared.", 2)
end)

whitelistSection:AddButton("Kill All", function()
    local character = LocalPlayer.Character
    if not character then return Notify("No character found!", 2) end
    
    local knife = character:FindFirstChild("Knife") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Knife"))
    if not knife then return Notify("Knife not found!", 2) end
    
    local events = knife:FindFirstChild("Events")
    if not events then return Notify("Knife Events not found!", 2) end
    
    local handleTouched = events:FindFirstChild("HandleTouched")
    if not handleTouched then return Notify("HandleTouched event not found!", 2) end
    
    local targets = {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and not table_find(whitelist, p.UserId) and p.Character then
            local upperTorso = p.Character:FindFirstChild("UpperTorso")
            if upperTorso then table_insert(targets, upperTorso) end
        end
    end
    
    for i = 1, 6 do
        for _, upperTorso in ipairs(targets) do
            handleTouched:FireServer(upperTorso)
        end
        if i < 6 then task.wait(1) end
    end
end)

do
    local tsSection = shared.AddSection("Trickshot")
    local spinSpeed, hasJumped, tsActive = 15, false, false
    local tsButtonSize = 0.11
    local TrickshotMaid
    
    local function setupSpin(c)
        local hrp = c:WaitForChild("HumanoidRootPart")
        local hum = c:WaitForChild("Humanoid")
        
        local function doSpin()
            for _, o in ipairs(hrp:GetChildren()) do 
                if o:IsA("Torque") or o:IsA("Attachment") then o:Destroy() end 
            end
            
            local att = Instance.new("Attachment", hrp)
            local tq = Instance.new("Torque", hrp)
            tq.Attachment0 = att
            tq.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
            tq.Torque = Vector3.new(0, spinSpeed * 10000, 0)
            
            if TrickshotMaid then
                TrickshotMaid:GiveTask(hum.StateChanged:Connect(function(_, s)
                    if s == Enum.HumanoidStateType.Landed then
                        tq:Destroy()
                        att:Destroy()
                        hasJumped = false
                        tsActive = false
                    end
                end))
            end
        end
        
        if TrickshotMaid then
            TrickshotMaid:GiveTask(Services.UserInputService.JumpRequest:Connect(function()
                if tsActive and not hasJumped then
                    hasJumped = true
                    task.defer(doSpin)
                end
            end))
        end
    end
    
    tsSection:AddLabel("Spin On Next Jump")
    tsSection:AddSlider("Spin Speed (1-30)", 1, 30, 15, function(v) spinSpeed = v end)
    tsSection:AddButton("Activate", function() hasJumped = false tsActive = true end)
    
    tsSection:AddToggle("Enable TS Bindable Button", function(e)
        if e then
            BindableButtons.AddBButton("ts_bind", "TS", function()
                hasJumped = false
                tsActive = true
            end)
            local btn = BindableButtons.Buttons["ts_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(tsButtonSize * (screen.Y / screen.X), 0, tsButtonSize, 0)
            end
        else
            BindableButtons.DeleteBButton("ts_bind")
        end
    end)
    
    tsSection:AddSlider("TS Button Size", 5, 25, 11, function(value)
        tsButtonSize = value / 100
        local btn = BindableButtons.Buttons["ts_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(tsButtonSize * (screen.Y / screen.X), 0, tsButtonSize, 0)
        end
    end)
    
    TrickshotMaid = Maid.new()
    TrickshotMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(setupSpin))
    if LocalPlayer.Character then setupSpin(LocalPlayer.Character) end
    RootMaid:GiveTask(function() if TrickshotMaid then TrickshotMaid:Destroy() end end)
end

do
    local duelSection = shared.AddSection("Dual Effect")
    duelSection:AddLabel("Must Own Dual Effect + Selected Effect")
    local dualEnabled, selectedDualEffect = false, "Electric"
    local DualEffectMaid
    local RoleSelect = Services.ReplicatedStorage.Remotes.Gameplay.RoleSelect
    
    duelSection:AddDropdown("Select Second Effect", {
        "Vampiric2024", "SynthEffect2025", "Sunbeams2024", "Snowstorm2024", "Retro2025", "Radioactive", "Musical",
        "Heatwave2025", "Heartify", "Gifts2024", "Ghosts2024", "FlamingoEffect2025", "Burn", "Cursed2024",
        "Starry2024", "Bats2024", "Aquatic2025", "Jellyfish2024", "Carrots2025", "BlueFire", "Rainbows2025",
        "Elitify", "Electric", "Ghostify", "SweetEffect26"
    }, function(s) selectedDualEffect = s end)
    
    duelSection:AddToggle("Auto Equip Dual Effect", function(e)
        if DualEffectMaid then DualEffectMaid:Destroy() end
        dualEnabled = e
        
        if e then
            DualEffectMaid = Maid.new()
            DualEffectMaid:GiveTask(RoleSelect.OnClientEvent:Connect(function(role)
                if role == "Murderer" then
                    Services.ReplicatedStorage.Remotes.Inventory.Equip:FireServer("Dual", "Effects")
                    task.delay(15, function()
                        if dualEnabled then
                            Services.ReplicatedStorage.Remotes.Inventory.Equip:FireServer(selectedDualEffect, "Effects")
                        end
                    end)
                end
            end))
        end
    end)
    
    RootMaid:GiveTask(function() if DualEffectMaid then DualEffectMaid:Destroy() end end)
end

do
    local tradeSection = shared.AddSection("Disable Trading")
    tradeSection:AddLabel("Turn Off & Rejoin To Trade Again")
    local TradeMaid
    
    tradeSection:AddToggle("Decline Trades", function(t)
        if TradeMaid then TradeMaid:Destroy() end
        
        if t then
            TradeMaid = Maid.new()
            Services.ReplicatedStorage.Trade.SendRequest.OnClientInvoke = function()
                Services.ReplicatedStorage.Trade.DeclineRequest:FireServer()
            end
            TradeMaid:GiveTask(function()
                Services.ReplicatedStorage.Trade.SendRequest.OnClientInvoke = nil
            end)
        end
    end)
    
    RootMaid:GiveTask(function() if TradeMaid then TradeMaid:Destroy() end end)
end

do
    local spraySection = shared.AddSection("Spray Paint")
    local decalSave = "saved_decals.json"
    local decals = {
        ["BEST NSFW"] = 127671269169979, ["GOOD NSFW"] = 78704349540567, ["GROUP NSFW"] = 120749379081216,
        ["ODH ON TOP"] = 119795719290739, ["TT Dad Jizz"] = 10318831749, ["Racist Ice Cream"] = 14868523054,
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
    
    spraySection:AddLabel('<font color="rgb(255,0,0)">Warning: Using This In MMV Gets You Banned.</font>', nil, true)
    
    local sprayId, sprayTargetMode, spraySelectedPlr = 0, "Nearest Player", nil
    local sprayDecalName, sprayLoop, sprayBehind = nil, false, false
    local decalDropdown, SprayMaid, BoxStealthMaid, SprayAutoMaid
    local autoGet = false
    
    local function getSprayTool()
        local c = LocalPlayer.Character
        return (c and c:FindFirstChild("SprayPaint")) or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("SprayPaint"))
    end
    
    local function getSprayTarget()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    if sprayTargetMode == "Nearest Player" then
        local nearest, minDist = nil, math.huge
        local rootPos = root.Position
        
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local t = p.Character:FindFirstChild("HumanoidRootPart")
                if t then
                    local d = (rootPos - t.Position).Magnitude
                    if d < minDist then 
                        minDist = d 
                        nearest = p 
                    end
                end
            end
        end
        return nearest
    elseif sprayTargetMode == "Random" then
        local validPlayers = {}
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                validPlayers[#validPlayers + 1] = p
            end
        end
        return #validPlayers > 0 and validPlayers[math.random(#validPlayers)] or nil
    else
        return spraySelectedPlr
    end
end
    
    local function performSpray(tgt, normalId, part)
        local tool = getSprayTool()
        if not tool or not tgt or not tgt.Character then return end
        
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            tool.Parent = LocalPlayer.Character
            hum:EquipTool(tool)
        end
        
        part = part or (tgt.Character:FindFirstChild("UpperTorso") or tgt.Character:FindFirstChild("Torso") or tgt.Character:FindFirstChild("HumanoidRootPart"))
        if not part then return end
        
        local sprayPosition
        local nId = normalId or (sprayBehind and Enum.NormalId.Back or Enum.NormalId.Front)
        
        if nId == Enum.NormalId.Front then
            sprayPosition = part.CFrame + part.CFrame.LookVector * 0.6
        elseif nId == Enum.NormalId.Back then
            sprayPosition = part.CFrame - part.CFrame.LookVector * 1.2
        elseif nId == Enum.NormalId.Left then
            sprayPosition = part.CFrame - part.CFrame.RightVector * 1.2
        elseif nId == Enum.NormalId.Right then
            sprayPosition = part.CFrame + part.CFrame.RightVector * 1.2
        elseif nId == Enum.NormalId.Top then
            sprayPosition = part.CFrame + part.CFrame.UpVector * 1.2
        else
            sprayPosition = part.CFrame
        end
        
        tool:FindFirstChildWhichIsA("RemoteEvent"):FireServer(sprayId, nId, 2048, part, sprayPosition)
        if hum then hum:UnequipTools() end
    end
    
    local function sprayLooper()
        while sprayLoop do
            local t = getSprayTarget()
            if t then performSpray(t) end
            task.wait(14)
        end
    end
    
    spraySection:AddToggle("Loop Spray Paint", function(s)
        if SprayMaid then SprayMaid:Destroy() end
        sprayLoop = s
        
        if s then
            SprayMaid = Maid.new()
            local thread = task.spawn(sprayLooper)
            SprayMaid:GiveTask(function() task.cancel(thread) end)
        end
    end)
    
    RootMaid:GiveTask(function() if SprayMaid then SprayMaid:Destroy() end end)
    spraySection:AddToggle("Spray Behind Target", function(s) sprayBehind = s end)
    spraySection:AddDropdown("Target Type", {"Nearest Player", "Random", "Select Player"}, function(o) sprayTargetMode = tostring(o) end)
    spraySection:AddPlayerDropdown("Select Player", function(p) if p then spraySelectedPlr = p sprayTargetMode = "Select Player" end end)
    
    local dKeys = {}
    for k in pairs(decals) do table_insert(dKeys, k) end
    
    decalDropdown = spraySection:AddDropdown("Select Decal", dKeys, function(s) 
        sprayDecalName = s 
        sprayId = decals[s] or 0 
        saveDecals() 
    end)
    
    spraySection:AddTextBox("Add Decal (Name:ID)", function(t)
        local n, i = t:match("(.+):(%d+)")
        if n and i then
            decals[n] = tonumber(i)
            local k2 = {}
            for k in pairs(decals) do table_insert(k2, k) end
            decalDropdown.Change(k2)
            saveDecals()
        end
    end)
    
    spraySection:AddButton("Delete Selected Decal", function()
        if sprayDecalName and decals[sprayDecalName] then
            decals[sprayDecalName] = nil
            local k3 = {}
            for k in pairs(decals) do table_insert(k3, k) end
            decalDropdown.Change(k3)
            sprayDecalName = nil
            sprayId = 0
            saveDecals()
        end
    end)
    
    spraySection:AddButton("Spray Paint Player", function() performSpray(getSprayTarget()) end)
    
    spraySection:AddButton("Box Player", function()
        local tgt = getSprayTarget()
        if not tgt then return end
        
        local sides = {Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Back, Enum.NormalId.Top}
        
        task.spawn(function()
            for _, side in ipairs(sides) do
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(0.03)
                end
                
                pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint")
                end)
                
                performSpray(tgt, side)
                task.wait(0.03)
                
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Health = 0
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(0.03)
                end
            end
        end)
    end)
    
    spraySection:AddToggle("Box Player Stealth Mode", function(s)
        if BoxStealthMaid then BoxStealthMaid:Destroy() end
        
        if s then
            BoxStealthMaid = Maid.new()
            local function tpToSpace(char)
                task.spawn(function()
                    local hrp = char:WaitForChild("HumanoidRootPart", 3)
                    if hrp then hrp.CFrame = CFrame.new(0, 2000000, 0) end
                end)
            end
            
            if LocalPlayer.Character then tpToSpace(LocalPlayer.Character) end
            BoxStealthMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(tpToSpace))
        end
    end)
    
    RootMaid:GiveTask(function() if BoxStealthMaid then BoxStealthMaid:Destroy() end end)
    
    spraySection:AddToggle("Auto-Get Spray Tool", function(s)
        if SprayAutoMaid then SprayAutoMaid:Destroy() end
        autoGet = s
        
        if s then
            SprayAutoMaid = Maid.new()
            SprayAutoMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1.5)
                pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint")
                end)
            end))
        end
    end)
    
    RootMaid:GiveTask(function() if SprayAutoMaid then SprayAutoMaid:Destroy() end end)
    
    spraySection:AddButton("Get Spray Tool", function()
        pcall(function()
            Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("SprayPaint")
        end)
    end)
    
    spraySection:AddLabel('Credits: <font color="rgb(0,255,0)">@not_.gato</font>', nil, true)
end

do
    local trollSection = shared.AddSection("Troll (FE)")
    trollSection:AddLabel("Play Troll Emotes")
    local trollButtonSize = 0.11
    
    local function makeEmote(eid, txt, gn)
        local playing, track, EmoteMaid
        
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
            
            local tempMaid = Maid.new()
            tempMaid:GiveTasks(
                h.Running:Connect(function(s) if s > 0 then stopEmote() tempMaid:Destroy() end end),
                h.Jumping:Connect(function() stopEmote() tempMaid:Destroy() end),
                track.Stopped:Connect(function() stopEmote() tempMaid:Destroy() end)
            )
        end
        
        trollSection:AddToggle("Enable "..txt.." Button", function(e)
            if EmoteMaid then EmoteMaid:Destroy() EmoteMaid = nil end
            BindableButtons.DeleteBButton(gn)
            
            if e then
                EmoteMaid = Maid.new()
                BindableButtons.AddBButton(gn, txt, play)
                local btn = BindableButtons.Buttons[gn]
                if btn then
                    local screen = workspace.CurrentCamera.ViewportSize
                    btn.Size = __UD2(trollButtonSize * (screen.Y / screen.X), 0, trollButtonSize, 0)
                end
            end
        end)
        
        RootMaid:GiveTask(function() if EmoteMaid then EmoteMaid:Destroy() end end)
        trollSection:AddSlider(txt.." Button Size", 5, 25, 11, function(value)
            trollButtonSize = value / 100
            local btn = BindableButtons.Buttons[gn]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(trollButtonSize * (screen.Y / screen.X), 0, trollButtonSize, 0)
            end
        end)
        trollSection:AddButton("Play "..txt.." Emote", play)
    end
    
    makeEmote("84112287597268", "FD", "EmoteGUI_FakeDead")
    makeEmote("122366279755346", "KS", "EmoteGUI_KnifeSwing")
    makeEmote("103788740211648", "DS", "EmoteGUI_DualSwing")
end

do
    local rtxSection = shared.AddSection("RTX")
    local rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
    local RTXMaid
    
    RootMaid:GiveTask(function() if RTXMaid then RTXMaid:Destroy() end end)
    
    local function createRtxEffects()
        local effects = {
            Sky = {Class="Sky", Properties={
                SkyboxBk="http://www.roblox.com/asset/?id=144933338",
                SkyboxDn="http://www.roblox.com/asset/?id=144931530",
                SkyboxFt="http://www.roblox.com/asset/?id=144933262",
                SkyboxLf="http://www.roblox.com/asset/?id=144933244",
                SkyboxRt="http://www.roblox.com/asset/?id=144933299",
                SkyboxUp="http://www.roblox.com/asset/?id=144931564",
                StarCount=5000, SunAngularSize=5
            }},
            Bloom = {Class="BloomEffect", Properties={Intensity=0.3, Size=10, Threshold=0.8}},
            Blur = {Class="BlurEffect", Properties={Size=5}},
            CC = {Class="ColorCorrectionEffect", Properties={Brightness=0, Contrast=0.1, Saturation=0.25, TintColor=Color3.fromRGB(255,255,255)}},
            Sun = {Class="SunRaysEffect", Properties={Intensity=0.1, Spread=0.8}}
        }
        
        for name, data in pairs(effects) do
            if not rtx[name] then
                rtx[name] = Instance.new(data.Class)
                for prop, val in pairs(data.Properties) do
                    rtx[name][prop] = val
                end
                rtx[name].Parent = Services.Lighting
                if RTXMaid then RTXMaid:GiveTask(rtx[name]) end
            end
        end
    end
    
    rtxSection:AddToggle("Enable RTX", function(enabled)
        if RTXMaid then RTXMaid:Destroy() end
        
        if enabled then
            RTXMaid = Maid.new()
            rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
            createRtxEffects()
            
            Services.Lighting.Brightness = 2.25
            Services.Lighting.ExposureCompensation = 0.1
            Services.Lighting.ClockTime = 17.55
            
            RTXMaid:GiveTask(function()
                Services.Lighting.Brightness = 2
                Services.Lighting.ExposureCompensation = 0
            end)
            
            for _, v in pairs(rtx) do if v then v.Enabled = true end end
        else
            rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
        end
    end)
end

do
    local lsSection = shared.AddSection("Legit Speedglitch")
    local sideSpd, lsHori = 0, false
    local lsButtonSize = 0.11
    local emOn, selEmote = false, nil
    local emotes = {Moonwalk="79127989560307", Yungblud="15610015346", ["Bouncy Twirl"]="14353423348", ["Flex Walk"]="15506506103"}
    local lsSelectedEmoteName, lsDropdownTouched = nil, false
    local LegitSpeedMaid
    
    RootMaid:GiveTask(function() if LegitSpeedMaid then LegitSpeedMaid:Destroy() end end)
    
    local function playE(id)
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not h then return end
        
        local success = pcall(function() h:PlayEmoteAndGetAnimTrackById(id) end)
        if not success then
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://"..id
            h:LoadAnimation(a):Play()
        end
    end
    
    lsSection:AddToggle("Enable SG Bindable Button", function(e)
        if LegitSpeedMaid then LegitSpeedMaid:Destroy() LegitSpeedMaid = nil end
        BindableButtons.DeleteBButton("sg_bind")
        
        if e then
            LegitSpeedMaid = Maid.new()
            
            BindableButtons.AddBButton("sg_bind", "SG", function()
                emOn = not emOn
                if emOn and selEmote then playE(selEmote) 
                elseif LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
            end)
            local btn = BindableButtons.Buttons["sg_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(lsButtonSize * (screen.Y / screen.X), 0, lsButtonSize, 0)
            end
            
            LegitSpeedMaid:GiveTask(Services.RunService.Stepped:Connect(function()
                if not emOn or not LocalPlayer.Character then return end
                local h = LocalPlayer.Character:FindFirstChild("Humanoid")
                local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not h or not r then return end
                
                local lsAir = h:GetState() == Enum.HumanoidStateType.Freefall or h:GetState() == Enum.HumanoidStateType.Jumping
                local spd = 16 + sideSpd
                
                if lsAir then
                    if lsHori then
                        h.WalkSpeed = (math_abs(h.MoveDirection:Dot(r.CFrame.RightVector)) > 0.5) and spd or 16
                    else
                        h.WalkSpeed = spd
                    end
                else
                    h.WalkSpeed = 16
                end
            end))
        end
    end)
    
    lsSection:AddSlider("Speed (0-255)", 0, 255, sideSpd, function(v) sideSpd = v end)
    lsSection:AddSlider("Button Size", 5, 25, 11, function(value)
        lsButtonSize = value / 100
        local btn = BindableButtons.Buttons["sg_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(lsButtonSize * (screen.Y / screen.X), 0, lsButtonSize, 0)
        end
    end)
    lsSection:AddToggle("Sideways Only", function(e) lsHori = e end)
    
    lsSection:AddDropdown("SG Select Emote", {"Moonwalk", "Yungblud", "Bouncy Twirl", "Flex Walk", "Custom"}, function(s)
        lsDropdownTouched = true
        lsSelectedEmoteName = s
        selEmote = (s ~= "Custom") and emotes[s] or nil
    end)
    
    lsSection:AddTextBox("SG Custom Emote ID", function(t)
        if lsDropdownTouched and lsSelectedEmoteName == "Custom" and t ~= "" then
            selEmote = t
        end
    end)
end

do
    local hlSection = shared.AddSection("FE Headless")
    hlSection:AddLabel("V2 & Higher Require a Very Small Head")
    
    local hlConfigs = {
        {id="78837807518622", on=false, track=nil, freeze=nil, stopped=nil},
        {id="117080641351340", on=false, track=nil, freeze=nil, stopped=nil},
        {id="136055001302601", on=false, track=nil, freeze=nil, stopped=nil}
    }
    
    local function stopHl(cfg)
        if cfg.stopped then cfg.stopped:Disconnect() cfg.stopped = nil end
        if cfg.track then cfg.track:Stop() cfg.track:Destroy() cfg.track = nil end
    end
    
    local function playHl(cfg, hum)
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end
        
        stopHl(cfg)
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..cfg.id
        cfg.track = ani:LoadAnimation(a)
        cfg.track.Priority = Enum.AnimationPriority.Action
        cfg.track.Looped = true
        cfg.track:Play()
        
        cfg.stopped = cfg.track.Stopped:Connect(function()
            if cfg.on and hum.Parent then task.wait(0.1) playHl(cfg, hum) end
        end)
    end
    
    local function applyFreeze(cfg, hum)
        if cfg.freeze then cfg.freeze:Disconnect() end
        cfg.freeze = hum.StateChanged:Connect(function()
            if cfg.on and hum.Parent and (not cfg.track or not cfg.track.IsPlaying) then
                task.wait(0.05)
                if cfg.on and hum.Parent then playHl(cfg, hum) end
            end
        end)
    end
    
    local function enableHl(cfg)
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        applyFreeze(cfg, h)
        playHl(cfg, h)
    end
    
    for i, cfg in ipairs(hlConfigs) do
        local name = i == 1 and "Headless" or "Headless V"..i
        hlSection:AddToggle("Enable "..name, function(s)
            cfg.on = s
            if s then enableHl(cfg)
            else 
                stopHl(cfg)
                if cfg.freeze then cfg.freeze:Disconnect() cfg.freeze = nil end
            end
        end)
    end
    
    LocalPlayer.CharacterRemoving:Connect(function()
        for _, cfg in ipairs(hlConfigs) do
            stopHl(cfg)
            if cfg.freeze then cfg.freeze:Disconnect() cfg.freeze = nil end
        end
    end)
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        for _, cfg in ipairs(hlConfigs) do
            if cfg.on then enableHl(cfg) end
        end
    end)
end

do
    local flingSection = shared.AddSection("Fling")
    local flingSelPlr, flingActive = nil, true
    local whitelist = {}
    local flingButtonSize = 0.11
    local maids = {autoSheriff=nil, autoMurderer=nil, loopPlr=nil, loopAll=nil}
    local buttonToggles = {Sheriff=false, Murderer=false, Player=false}
    
    RootMaid:GiveTask(function() 
        for _, m in pairs(maids) do if m then m:Destroy() end end
    end)
    
    local function isWhitelisted(player)
        return whitelist[player.UserId] == true
    end
    
    local function findSheriff()
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                if p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun")) then
                    return p
                end
            end
        end
        return nil
    end
    
    local function findMurderer()
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                if p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
                    return p
                end
            end
        end
        return nil
    end
    
    local function OdhSkid(TargetPlayer, duration)
        if isWhitelisted(TargetPlayer) then
            Notify("Whitelist", TargetPlayer.Name.." is whitelisted!", 3)
            return
        end
        
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character
        
        if not (Character and Humanoid and RootPart and TCharacter) then return end
        
        local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        local TRootPart = THumanoid and THumanoid.RootPart
        local THead = TCharacter:FindFirstChild("Head")
        local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        local Handle = Accessory and Accessory:FindFirstChild("Handle")
        
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
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Services.Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
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
                for _, x in ipairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
    
    flingSection:AddButton("Fling Sheriff", function()
        local sheriff = findSheriff()
        if sheriff then OdhSkid(sheriff, 2) else Notify("Error", "No Sheriff Found", 3) end
    end)
    
    flingSection:AddButton("Fling Murderer", function()
        local murderer = findMurderer()
        if murderer then OdhSkid(murderer, 2) else Notify("Error", "No Murderer Found", 3) end
    end)
    
    flingSection:AddButton("Fling All", function()
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                OdhSkid(p, 2)
                task.wait(0.5)
            end
        end
    end)
    
    flingSection:AddPlayerDropdown("Fling Player", function(p)
        flingSelPlr = p
        if p ~= LocalPlayer and not isWhitelisted(p) then OdhSkid(p, 2) end
    end)
    
    local function createAutoFling(name, findFunc)
        flingSection:AddToggle("Auto Fling "..name, function(enabled)
            if maids["auto"..name] then maids["auto"..name]:Destroy() end
            
            if enabled then
                maids["auto"..name] = Maid.new()
                local thread = task.spawn(function()
                    while true do
                        task.wait(1)
                        local target = findFunc()
                        if target then
                            OdhSkid(target, 2)
                            task.wait(3)
                        end
                    end
                end)
                maids["auto"..name]:GiveTask(function() task.cancel(thread) end)
            end
        end)
    end
    
    createAutoFling("Sheriff", findSheriff)
    createAutoFling("Murderer", findMurderer)
    
    local buttonConfigs = {
        {name="Sheriff", text="FS", findFunc=findSheriff, id="fling_sheriff"},
        {name="Murderer", text="FM", findFunc=findMurderer, id="fling_murderer"},
        {name="Player", text="FP", findFunc=function() return flingSelPlr end, id="fling_player"}
    }
    
    for _, cfg in ipairs(buttonConfigs) do
        flingSection:AddToggle("Enable "..cfg.text.." Button", function(enabled)
            buttonToggles[cfg.name] = enabled
            
            if enabled then
                BindableButtons.AddBButton(cfg.id, cfg.text, function()
                    local target = cfg.findFunc()
                    if target then
                        OdhSkid(target, 2)
                        Notify("Success", "Flinging "..cfg.name..": "..target.Name, 2)
                    else
                        Notify("Error", "No "..cfg.name.." Found", 3)
                    end
                end)
                local btn = BindableButtons.Buttons[cfg.id]
                if btn then
                    local screen = workspace.CurrentCamera.ViewportSize
                    btn.Size = __UD2(flingButtonSize * (screen.Y / screen.X), 0, flingButtonSize, 0)
                end
            else
                BindableButtons.DeleteBButton(cfg.id)
            end
        end)
        
        flingSection:AddSlider(cfg.name.." Button Size", 5, 25, 11, function(value)
            flingButtonSize = value / 100
            local btn = BindableButtons.Buttons[cfg.id]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(flingButtonSize * (screen.Y / screen.X), 0, flingButtonSize, 0)
            end
        end)
    end
    
    flingSection:AddPlayerDropdown("Add to Whitelist", function(p)
        if p and p ~= LocalPlayer then
            whitelist[p.UserId] = true
            Notify("Whitelist", p.Name.." added to whitelist", 3)
        end
    end)
    
    flingSection:AddButton("Clear Whitelist", function()
        whitelist = {}
        Notify("Whitelist", "Whitelist cleared!", 3)
    end)
    
    flingSection:AddToggle("Loop Fling Player", function(s)
        if maids.loopPlr then maids.loopPlr:Destroy() end
        
        if s then
            maids.loopPlr = Maid.new()
            local thread = task.spawn(function()
                while true do
                    if flingSelPlr and flingSelPlr.Parent and not isWhitelisted(flingSelPlr) then
                        OdhSkid(flingSelPlr, 2)
                        task.wait(3)
                    else
                        if not flingSelPlr or not flingSelPlr.Parent then break end
                    end
                    task.wait(1)
                end
            end)
            maids.loopPlr:GiveTask(function() task.cancel(thread) end)
        end
    end)
    
    flingSection:AddToggle("Loop Fling All", function(s)
        if maids.loopAll then maids.loopAll:Destroy() end
        
        if s then
            maids.loopAll = Maid.new()
            local thread = task.spawn(function()
                while true do
                    for _, p in ipairs(Services.Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Parent and not isWhitelisted(p) then
                            OdhSkid(p, 2)
                            task.wait(0.5)
                        end
                    end
                    task.wait(3)
                end
            end)
            maids.loopAll:GiveTask(function() task.cancel(thread) end)
        end
    end)
end

do
    local perkSection = shared.AddSection("Perks")
    local hasteOn, blatantMode, hasteSpd = false, false, 18
    local PerkMaid
    
    RootMaid:GiveTask(function() if PerkMaid then PerkMaid:Destroy() end end)
    
    local function updSpd()
        if not hasteOn then return end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        if not h then return end
        
        h.WalkSpeed = (c:FindFirstChild("Knife") or (LocalPlayer.Backpack:FindFirstChild("Knife") and c:FindFirstChild("Knife"))) 
            and hasteSpd or 16
    end
    
    perkSection:AddToggle("Enable Auto Haste", function(s) 
        hasteOn = s 
        if PerkMaid then PerkMaid:Destroy() end
        
        if s then
            PerkMaid = Maid.new()
            PerkMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(c)
                local h = c:WaitForChild("Humanoid")
                PerkMaid:GiveTasks(c.ChildAdded:Connect(updSpd), c.ChildRemoved:Connect(updSpd))
                task.wait(0.5)
                updSpd()
            end))
            
            if LocalPlayer.Character then
                PerkMaid:GiveTasks(
                    LocalPlayer.Character.ChildAdded:Connect(updSpd),
                    LocalPlayer.Character.ChildRemoved:Connect(updSpd)
                )
                updSpd()
            end
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end)
    
    perkSection:AddToggle("Enable Blatant Mode", function(s)
        blatantMode = s
        hasteSpd = blatantMode and 19 or 18
        updSpd()
    end)
    perkSection:AddLabel("Stacks With Other Perks")
end

do
    local skySection = shared.AddSection("FE Blind All")
    skySection:AddLabel("Requires The Glitch Walker Bundle")
    local skyId = "70883871260184"
    local SkyboxMaid
    
    RootMaid:GiveTask(function() if SkyboxMaid then SkyboxMaid:Destroy() end end)
    
    local function playSky(hum, maid)
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end
        
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..skyId
        local skyTrack = ani:LoadAnimation(a)
        skyTrack.Priority = Enum.AnimationPriority.Action
        skyTrack.Looped = true
        skyTrack:Play()
        maid:GiveTask(function() skyTrack:Stop() skyTrack:Destroy() end)
        
        maid:GiveTask(skyTrack.Stopped:Connect(function()
            if maid._destroyed then return end
            if hum.Parent then task.wait(0.1) playSky(hum, maid) end
        end))
    end
    
    skySection:AddToggle("Enable FE Skybox", function(s)
        if SkyboxMaid then SkyboxMaid:Destroy() end
        
        if s then
            SkyboxMaid = Maid.new()
            local function enableSky()
                local c = LocalPlayer.Character
                if not c then return end
                local h = c:FindFirstChild("Humanoid")
                if not h then return end
                
                SkyboxMaid:GiveTask(h.StateChanged:Connect(function()
                    if SkyboxMaid._destroyed then return end
                    if h.Parent then
                        task.wait(0.05)
                        if not SkyboxMaid._destroyed and h.Parent then playSky(h, SkyboxMaid) end
                    end
                end))
                playSky(h, SkyboxMaid)
            end
            
            enableSky()
            SkyboxMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
                task.wait(0.5)
                enableSky()
            end))
        end
    end)
end

do
    local section = shared.AddSection("Bomb Jump+")
    local BOMB_NAMES = {"Bomb", "PrankBomb", "FakeBomb"}
    local BombJumpMaid, BombJumpTimerMaid
    local timerDisplay, bjBindButton
    local onCooldown, bombJumpEnabled, clickBombJumpEnabled = false, false, false
    local timerGuiEnabled, debounce, autoGetBomb, justRespawned = false, false, false, false
    local bigButtonSize = 200
    local bindButtonSize = 0.11
    local timerButtonSize = 0.11
    local activeTouches = {}
    
    local __READY_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
        ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
        ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
    })
    
    local __WAIT_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   __PCLR(0.827451, 0.133333, 0.133333)),
        ColorSequenceKeypoint.new(0.6, __PCLR(0.509804, 0.231373, 0.231373)),
        ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
    })
    
    RootMaid:GiveTask(function()
        if BombJumpTimerMaid then BombJumpTimerMaid:Destroy() end
        if BombJumpMaid then BombJumpMaid:Destroy() end
        DeleteBigButton("bombjump_big")
        BindableButtons.DeleteBButton("bombjump_bind")
        BindableButtons.DeleteBButton("bombjump_timer")
    end)
    
    local function UpdateBJButton(text, isWaiting)
        if not bjBindButton then 
            bjBindButton = BindableButtons.Buttons["bombjump_bind"]
        end
        if not bjBindButton then return end
        
        local textLabel = bjBindButton:FindFirstChild("@Text")
        if textLabel then
            textLabel.Text = text
        end
        
        local stroke = bjBindButton:FindFirstChild("@Stroke")
        if stroke then
            stroke.Color = isWaiting and __WAIT_COLOR or __READY_COLOR
        end
    end
    
    local function UpdateTimerDisplay(text, isWaiting)
        if not timerDisplay then return end
        
        local textLabel = timerDisplay:FindFirstChild("@Text")
        if textLabel then
            textLabel.Text = text
        end
        
        local stroke = timerDisplay:FindFirstChild("@Stroke")
        if stroke then
            stroke.Color = isWaiting and __WAIT_COLOR or __READY_COLOR
        end
    end
    
    local function ResetCooldown()
        onCooldown = false
        local bigBtn = BBSystem.Buttons["bombjump_big"]
        if bigBtn then bigBtn.Text = "Bomb Jump" end
        UpdateBJButton("BJ", false)
        UpdateTimerDisplay("Ready", false)
    end
    
    local function StartCooldown()
        onCooldown = true
        debounce = false
        local bigBtn = BBSystem.Buttons["bombjump_big"]
        if bigBtn then bigBtn.Text = "Wait" end
        UpdateBJButton("Wait", true)
        UpdateTimerDisplay("Wait", true)
        
        task.spawn(function()
            for i = 22, 1, -1 do
                if not onCooldown then break end
                local bigBtn = BBSystem.Buttons["bombjump_big"]
                if bigBtn then bigBtn.Text = tostring(i) end
                UpdateBJButton(tostring(i), true)
                UpdateTimerDisplay(tostring(i), true)
                task.wait(1)
            end
            if onCooldown then ResetCooldown() end
        end)
    end
    
    local function GetAnyBomb()
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
        
        pcall(function()
            Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
        end)
        
        for _ = 1, 5 do
            for _, bombName in ipairs(BOMB_NAMES) do
                local bomb = character:FindFirstChild(bombName)
                if bomb then return true, bomb end
                if backpack then
                    bomb = backpack:FindFirstChild(bombName)
                    if bomb then bomb.Parent = character return true, bomb end
                end
            end
            task.wait(0.05)
        end
        
        return false, nil
    end
    
    local function FastBombJump()
        if onCooldown or debounce or justRespawned then return end
        debounce = true
        
        local success, bomb = GetAnyBomb()
        if success and bomb then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local camera = workspace.CurrentCamera
                local position = character.HumanoidRootPart.Position + (camera.CFrame.LookVector * 5)
                local remote = bomb:FindFirstChild("Remote")
                
                if remote then
                    pcall(function() remote:FireServer(CFrame.new(position), 50) end)
                    character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    
                    task.spawn(function()
                        task.wait(0.5)
                        local bombInHand = character:FindFirstChild(bomb.Name)
                        if bombInHand then bombInHand.Parent = LocalPlayer.Backpack or character end
                    end)
                    
                    task.spawn(function()
                        task.wait(0.1)
                        StartCooldown()
                    end)
                end
            end
        end
        
        task.spawn(function() task.wait(0.5) debounce = false end)
    end
    
    local function IsHoldingBomb()
        local character = LocalPlayer.Character
        if not character then return false end
        
        for _, bombName in ipairs(BOMB_NAMES) do
            if character:FindFirstChild(bombName) then
                return true
            end
        end
        return false
    end
    
    local function CreateTimerDisplayButton()
        if timerDisplay then return end
        
        local buttonMaid = Maid.new()
        local camera = workspace.CurrentCamera
        local screen = camera.ViewportSize
        local buttonSizeY = timerButtonSize
        local widthScale = buttonSizeY * (screen.Y / screen.X)
        
        local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
        local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

        local ImageButton = Instance.new("ImageButton")
        ImageButton.Name = "bombjump_timer"
        ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
        ImageButton.Position = __UD2(xPos, 0, yPos, 0)
        ImageButton.AnchorPoint = __V2(0.5, 0.5)
        ImageButton.Image = __SHAPES[0]
        ImageButton.BackgroundTransparency = 1
        ImageButton.BorderSizePixel = 0
        ImageButton.ClipsDescendants = false
        ImageButton.AutoButtonColor = false
        ImageButton.Active = false
        ImageButton.Selectable = false
        ImageButton.Parent = Bind_GetStorage()
        buttonMaid:GiveTask(ImageButton)

        local TextLabel = Instance.new("TextLabel", ImageButton)
        TextLabel.Name = "@Text"
        TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
        TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
        TextLabel.AnchorPoint = __V2(0.5, 0.5)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Font = Enum.Font.Jura
        TextLabel.Text = "Ready"
        TextLabel.TextColor3 = __PCLR(1, 1, 1)
        TextLabel.TextSize = 10
        TextLabel.TextWrapped = true
        TextLabel.ZIndex = 3

        local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
        Aspect.AspectRatio = 1
        Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

        local Stroke = Instance.new("UIGradient", ImageButton)
        Stroke.Name = "@Stroke"
        Stroke.Color = __READY_COLOR

        buttonMaid:GiveTask(__RS.RenderStepped:Connect(function()
            Stroke.Rotation = (Stroke.Rotation + 1) % 360
        end))

        timerDisplay = ImageButton
        BindableButtons.Buttons["bombjump_timer"] = ImageButton
        BindableButtons.Maids["bombjump_timer"] = buttonMaid
        
        return ImageButton
    end
    
    local function DeleteTimerDisplayButton()
        if BindableButtons.Maids["bombjump_timer"] then
            BindableButtons.Maids["bombjump_timer"]:Destroy()
            BindableButtons.Maids["bombjump_timer"] = nil
            BindableButtons.Buttons["bombjump_timer"] = nil
        end
        timerDisplay = nil
    end
    
    section:AddLabel("Different Bomb Jump Options")
    section:AddToggle("Enable Auto Bomb Jump", function(bool) bombJumpEnabled = bool end)
    section:AddToggle("Enable Equip Bomb Jump", function(bool) clickBombJumpEnabled = bool end)
    section:AddToggle("Auto-Get Fake Bomb", function(bool) autoGetBomb = bool end)

    section:AddToggle("Enable BJ Big Button", function(e)
        if e then
            AddBigButton("bombjump_big", "Bomb Jump", FastBombJump)
            local btn = BBSystem.Buttons["bombjump_big"]
            if btn then
                btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375)
            end
        else
            DeleteBigButton("bombjump_big")
        end
    end)
    
    section:AddSlider("BJ Big Button Size", 100, 400, 200, function(value)
        bigButtonSize = value
        local btn = BBSystem.Buttons["bombjump_big"]
        if btn then
            btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375)
        end
    end)
    
    section:AddToggle("Enable BJ Bind Button", function(e)
        if e then
            BindableButtons.AddBButton("bombjump_bind", "BJ", FastBombJump)
            bjBindButton = BindableButtons.Buttons["bombjump_bind"]
            if bjBindButton then
                local screen = workspace.CurrentCamera.ViewportSize
                bjBindButton.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
                UpdateBJButton(onCooldown and "Wait" or "BJ", onCooldown)
            end
        else
            BindableButtons.DeleteBButton("bombjump_bind")
            bjBindButton = nil
        end
    end)
    
    section:AddSlider("BJ Bind Button Size", 5, 25, 11, function(value)
        bindButtonSize = value / 100
        if bjBindButton then
            local screen = workspace.CurrentCamera.ViewportSize
            bjBindButton.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
        end
    end)

    section:AddToggle("Enable Timer Display", function(e)
        timerGuiEnabled = e
        
        if e then
            CreateTimerDisplayButton()
            if timerDisplay then
                local screen = workspace.CurrentCamera.ViewportSize
                timerDisplay.Size = __UD2(timerButtonSize * (screen.Y / screen.X), 0, timerButtonSize, 0)
                UpdateTimerDisplay(onCooldown and "Wait" or "Ready", onCooldown)
            end
        else
            DeleteTimerDisplayButton()
        end
    end)
    
    section:AddSlider("Timer Display Size", 5, 25, 11, function(value)
        timerButtonSize = value / 100
        if timerDisplay then
            local screen = workspace.CurrentCamera.ViewportSize
            timerDisplay.Size = __UD2(timerButtonSize * (screen.Y / screen.X), 0, timerButtonSize, 0)
        end
    end)
    
    section:AddKeybind("Bomb Jump Keybind", "E", FastBombJump)
    
    BombJumpMaid = Maid.new()
    BombJumpMaid:GiveTasks(
        Services.UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                activeTouches[input] = {startPosition=input.Position, startTime=tick(), moved=false}
            end
        end),
        Services.UserInputService.InputChanged:Connect(function(input)
            local data = activeTouches[input]
            if data and (input.Position - data.startPosition).Magnitude > 10 then
                data.moved = true
            end
        end),
        Services.UserInputService.InputEnded:Connect(function(input, gp)
            if gp then activeTouches[input] = nil return end
            local data = activeTouches[input]
            if data and not data.moved and tick() - data.startTime <= 0.3 then
                if bombJumpEnabled and not onCooldown and not debounce then
                    if IsHoldingBomb() then
                        FastBombJump()
                    end
                end
            end
            activeTouches[input] = nil
        end),
        LocalPlayer.CharacterAdded:Connect(function()
            ResetCooldown()
            activeTouches = {}
            justRespawned = true
            task.wait(1)
            justRespawned = false
            if autoGetBomb then
                task.wait(0.2)
                pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb") end)
            end
        end)
    )
    RootMaid:GiveTask(BombJumpMaid)
end

do
    local feAnimSection = shared.AddSection("FE Animations")
    local FEAnimMaid = Maid.new()
    RootMaid:GiveTask(FEAnimMaid)
    
    local feAnimEnabled = false
    local animState = {all="Default", idle="Default", walk="Default", run="Default", jump="Default", climb="Default", fall="Default"}
    local originalAnims = {}
    
    local animPresets = {
        ["Default"] = nil,
        ["OG Rthro Run"] = {run = "http://www.roblox.com/asset/?id=9801814462"},
        ["Vampire"] = {
            idle1 = "http://www.roblox.com/asset/?id=1083445855",
            idle2 = "http://www.roblox.com/asset/?id=1083450166",
            walk  = "http://www.roblox.com/asset/?id=1083473930",
            run   = "http://www.roblox.com/asset/?id=1083462077",
            jump  = "http://www.roblox.com/asset/?id=1083455352",
            climb = "http://www.roblox.com/asset/?id=1083439238",
            fall  = "http://www.roblox.com/asset/?id=1083443587"
        },
        ["Hero"] = {
            idle1 = "http://www.roblox.com/asset/?id=616111295",
            idle2 = "http://www.roblox.com/asset/?id=616113536",
            walk  = "http://www.roblox.com/asset/?id=616122287",
            run   = "http://www.roblox.com/asset/?id=616117076",
            jump  = "http://www.roblox.com/asset/?id=616115533",
            climb = "http://www.roblox.com/asset/?id=616104706",
            fall  = "http://www.roblox.com/asset/?id=616108001"
        },
        ["Zombie Classic"] = {
            idle1 = "http://www.roblox.com/asset/?id=616158929",
            idle2 = "http://www.roblox.com/asset/?id=616160636",
            walk  = "http://www.roblox.com/asset/?id=616168032",
            run   = "http://www.roblox.com/asset/?id=616163682",
            jump  = "http://www.roblox.com/asset/?id=616161997",
            climb = "http://www.roblox.com/asset/?id=616156119",
            fall  = "http://www.roblox.com/asset/?id=616157476"
        },
        ["Mage"] = {
            idle1 = "http://www.roblox.com/asset/?id=707742142",
            idle2 = "http://www.roblox.com/asset/?id=707855907",
            walk  = "http://www.roblox.com/asset/?id=707897309",
            run   = "http://www.roblox.com/asset/?id=707861613",
            jump  = "http://www.roblox.com/asset/?id=707853694",
            climb = "http://www.roblox.com/asset/?id=707826056",
            fall  = "http://www.roblox.com/asset/?id=707829716"
        },
        ["Ghost"] = {
            idle1 = "http://www.roblox.com/asset/?id=616006778",
            idle2 = "http://www.roblox.com/asset/?id=616008087",
            walk  = "http://www.roblox.com/asset/?id=616010382",
            run   = "http://www.roblox.com/asset/?id=616013216",
            jump  = "http://www.roblox.com/asset/?id=616008936",
            climb = "http://www.roblox.com/asset/?id=616003713",
            fall  = "http://www.roblox.com/asset/?id=616005863"
        },
        ["Elder"] = {
            idle1 = "http://www.roblox.com/asset/?id=845397899",
            idle2 = "http://www.roblox.com/asset/?id=845400520",
            walk  = "http://www.roblox.com/asset/?id=845403856",
            run   = "http://www.roblox.com/asset/?id=845386501",
            jump  = "http://www.roblox.com/asset/?id=845398858",
            climb = "http://www.roblox.com/asset/?id=845392038",
            fall  = "http://www.roblox.com/asset/?id=845396048"
        },
        ["Levitation"] = {
            idle1 = "http://www.roblox.com/asset/?id=616006778",
            idle2 = "http://www.roblox.com/asset/?id=616008087",
            walk  = "http://www.roblox.com/asset/?id=616013216",
            run   = "http://www.roblox.com/asset/?id=616010382",
            jump  = "http://www.roblox.com/asset/?id=616008936",
            climb = "http://www.roblox.com/asset/?id=616003713",
            fall  = "http://www.roblox.com/asset/?id=616005863"
        },
        ["Astronaut"] = {
            idle1 = "http://www.roblox.com/asset/?id=891621366",
            idle2 = "http://www.roblox.com/asset/?id=891633237",
            walk  = "http://www.roblox.com/asset/?id=891667138",
            run   = "http://www.roblox.com/asset/?id=891636393",
            jump  = "http://www.roblox.com/asset/?id=891627522",
            climb = "http://www.roblox.com/asset/?id=891609353",
            fall  = "http://www.roblox.com/asset/?id=891617961"
        },
        ["Ninja"] = {
            idle1 = "http://www.roblox.com/asset/?id=656117400",
            idle2 = "http://www.roblox.com/asset/?id=656118341",
            walk  = "http://www.roblox.com/asset/?id=656121766",
            run   = "http://www.roblox.com/asset/?id=656118852",
            jump  = "http://www.roblox.com/asset/?id=656117878",
            climb = "http://www.roblox.com/asset/?id=656114359",
            fall  = "http://www.roblox.com/asset/?id=656115606"
        },
        ["Werewolf"] = {
            idle1 = "http://www.roblox.com/asset/?id=1083195517",
            idle2 = "http://www.roblox.com/asset/?id=1083214717",
            walk  = "http://www.roblox.com/asset/?id=1083178339",
            run   = "http://www.roblox.com/asset/?id=1083216690",
            jump  = "http://www.roblox.com/asset/?id=1083218792",
            climb = "http://www.roblox.com/asset/?id=1083182000",
            fall  = "http://www.roblox.com/asset/?id=1083189019"
        },
        ["Cartoon"] = {
            idle1 = "http://www.roblox.com/asset/?id=742637544",
            idle2 = "http://www.roblox.com/asset/?id=742638445",
            walk  = "http://www.roblox.com/asset/?id=742640026",
            run   = "http://www.roblox.com/asset/?id=742638842",
            jump  = "http://www.roblox.com/asset/?id=742637942",
            climb = "http://www.roblox.com/asset/?id=742636889",
            fall  = "http://www.roblox.com/asset/?id=742637151"
        },
        ["Pirate"] = {
            idle1 = "http://www.roblox.com/asset/?id=750781874",
            idle2 = "http://www.roblox.com/asset/?id=750782770",
            walk  = "http://www.roblox.com/asset/?id=750785693",
            run   = "http://www.roblox.com/asset/?id=750783738",
            jump  = "http://www.roblox.com/asset/?id=750782230",
            climb = "http://www.roblox.com/asset/?id=750779899",
            fall  = "http://www.roblox.com/asset/?id=750780242"
        },
        ["Sneaky"] = {
            idle1 = "http://www.roblox.com/asset/?id=1132473842",
            idle2 = "http://www.roblox.com/asset/?id=1132477671",
            walk  = "http://www.roblox.com/asset/?id=1132510133",
            run   = "http://www.roblox.com/asset/?id=1132494274",
            jump  = "http://www.roblox.com/asset/?id=1132489853",
            climb = "http://www.roblox.com/asset/?id=1132461372",
            fall  = "http://www.roblox.com/asset/?id=1132469004"
        },
        ["Toy"] = {
            idle1 = "http://www.roblox.com/asset/?id=782841498",
            idle2 = "http://www.roblox.com/asset/?id=782845736",
            walk  = "http://www.roblox.com/asset/?id=782843345",
            run   = "http://www.roblox.com/asset/?id=782842708",
            jump  = "http://www.roblox.com/asset/?id=782847020",
            climb = "http://www.roblox.com/asset/?id=782843869",
            fall  = "http://www.roblox.com/asset/?id=782846423"
        },
        ["Knight"] = {
            idle1 = "http://www.roblox.com/asset/?id=657595757",
            idle2 = "http://www.roblox.com/asset/?id=657568135",
            walk  = "http://www.roblox.com/asset/?id=657552124",
            run   = "http://www.roblox.com/asset/?id=657564596",
            jump  = "http://www.roblox.com/asset/?id=658409194",
            climb = "http://www.roblox.com/asset/?id=658360781",
            fall  = "http://www.roblox.com/asset/?id=657600338"
        },
        ["Confident"] = {
            idle1 = "http://www.roblox.com/asset/?id=1069977950",
            idle2 = "http://www.roblox.com/asset/?id=1069987858",
            walk  = "http://www.roblox.com/asset/?id=1070017263",
            run   = "http://www.roblox.com/asset/?id=1070001516",
            jump  = "http://www.roblox.com/asset/?id=1069984524",
            climb = "http://www.roblox.com/asset/?id=1069946257",
            fall  = "http://www.roblox.com/asset/?id=1069973677"
        },
        ["Popstar"] = {
            idle1 = "http://www.roblox.com/asset/?id=1212900985",
            idle2 = "http://www.roblox.com/asset/?id=1212900985",
            walk  = "http://www.roblox.com/asset/?id=1212980338",
            run   = "http://www.roblox.com/asset/?id=1212980348",
            jump  = "http://www.roblox.com/asset/?id=1212954642",
            climb = "http://www.roblox.com/asset/?id=1213044953",
            fall  = "http://www.roblox.com/asset/?id=1212900995"
        },
        ["Princess"] = {
            idle1 = "http://www.roblox.com/asset/?id=941003647",
            idle2 = "http://www.roblox.com/asset/?id=941013098",
            walk  = "http://www.roblox.com/asset/?id=941028902",
            run   = "http://www.roblox.com/asset/?id=941015281",
            jump  = "http://www.roblox.com/asset/?id=941008832",
            climb = "http://www.roblox.com/asset/?id=940996062",
            fall  = "http://www.roblox.com/asset/?id=941000007"
        },
        ["Cowboy"] = {
            idle1 = "http://www.roblox.com/asset/?id=1014390418",
            idle2 = "http://www.roblox.com/asset/?id=1014398616",
            walk  = "http://www.roblox.com/asset/?id=1014421541",
            run   = "http://www.roblox.com/asset/?id=1014401683",
            jump  = "http://www.roblox.com/asset/?id=1014394726",
            climb = "http://www.roblox.com/asset/?id=1014380606",
            fall  = "http://www.roblox.com/asset/?id=1014384571"
        },
        ["Patrol"] = {
            idle1 = "http://www.roblox.com/asset/?id=1149612882",
            idle2 = "http://www.roblox.com/asset/?id=1150842221",
            walk  = "http://www.roblox.com/asset/?id=1151231493",
            run   = "http://www.roblox.com/asset/?id=1150967949",
            jump  = "http://www.roblox.com/asset/?id=1150944216",
            climb = "http://www.roblox.com/asset/?id=1148811837",
            fall  = "http://www.roblox.com/asset/?id=1148863382"
        },
        ["Zombie FE"] = {
            idle1 = "http://www.roblox.com/asset/?id=3489171152",
            idle2 = "http://www.roblox.com/asset/?id=3489171152",
            walk  = "http://www.roblox.com/asset/?id=3489174223",
            run   = "http://www.roblox.com/asset/?id=3489173414",
            jump  = "http://www.roblox.com/asset/?id=616161997",
            climb = "http://www.roblox.com/asset/?id=616156119",
            fall  = "http://www.roblox.com/asset/?id=616157476"
        },
        ["Catwalk Glam"] = {
            idle1 = "http://www.roblox.com/asset/?id=133806214992291",
            idle2 = "http://www.roblox.com/asset/?id=133806214992291",
            walk  = "http://www.roblox.com/asset/?id=109168724482748",
            run   = "http://www.roblox.com/asset/?id=81024476153754",
            jump  = "http://www.roblox.com/asset/?id=116936326516985",
            climb = "http://www.roblox.com/asset/?id=119377220967554",
            fall  = "http://www.roblox.com/asset/?id=92294537340807"
        },
        ["Amazon Unboxed"] = {
            idle1 = "http://www.roblox.com/asset/?id=98281136301627",
            idle2 = "http://www.roblox.com/asset/?id=98281136301627",
            walk  = "http://www.roblox.com/asset/?id=90478085024465",
            run   = "http://www.roblox.com/asset/?id=134824450619865",
            jump  = "http://www.roblox.com/asset/?id=121454505477205",
            climb = "http://www.roblox.com/asset/?id=121145883950231",
            fall  = "http://www.roblox.com/asset/?id=94788218468396"
        },
        ["Glow Motion"] = {
            idle1 = "https://www.roblox.com/asset/?id=137764781910579",
            idle2 = "https://www.roblox.com/asset/?id=137764781910579",
            walk  = "http://www.roblox.com/asset/?id=85809016093530",
            run   = "http://www.roblox.com/asset/?id=101925097435036",
            jump  = "http://www.roblox.com/asset/?id=74159004634379",
            climb = "http://www.roblox.com/asset/?id=108236155509584",
            fall  = "https://www.roblox.com/asset/?id=98070939608691"
        },
        ["Bubbly"] = {
            idle1 = "https://www.roblox.com/asset/?id=10921054344",
            idle2 = "https://www.roblox.com/asset/?id=10921054344",
            walk  = "http://www.roblox.com/asset/?id=10980888364",
            run   = "http://www.roblox.com/asset/?id=10921057244",
            jump  = "http://www.roblox.com/asset/?id=10921062673",
            climb = "http://www.roblox.com/asset/?id=10921053544",
            fall  = "https://www.roblox.com/asset/?id=10921061530"
        },
        ["Adidas Comm"] = {
            idle1 = "https://www.roblox.com/asset/?id=122257458498464",
            idle2 = "https://www.roblox.com/asset/?id=122257458498464",
            walk  = "http://www.roblox.com/asset/?id=122150855457006",
            run   = "http://www.roblox.com/asset/?id=82598234841035",
            jump  = "http://www.roblox.com/asset/?id=75290611992385",
            climb = "http://www.roblox.com/asset/?id=88763136693023",
            fall  = "https://www.roblox.com/asset/?id=98600215928904"
        },
        ["KATSEYE"] = {
            idle1 = "https://www.roblox.com/asset/?id=108187809145790",
            idle2 = "https://www.roblox.com/asset/?id=108187809145790",
            walk  = "http://www.roblox.com/asset/?id=99182913548783",
            run   = "http://www.roblox.com/asset/?id=73117360545482",
            jump  = "http://www.roblox.com/asset/?id=103632305262747",
            climb = "http://www.roblox.com/asset/?id=106213237973858",
            fall  = "https://www.roblox.com/asset/?id=127802717128367"
        },
        ["Wicked Popular"] = {
            idle1 = "https://www.roblox.com/asset/?id=118832222982049",
            idle2 = "https://www.roblox.com/asset/?id=118832222982049",
            walk  = "http://www.roblox.com/asset/?id=92072849924640",
            run   = "http://www.roblox.com/asset/?id=72301599441680",
            jump  = "http://www.roblox.com/asset/?id=104325245285198",
            climb = "http://www.roblox.com/asset/?id=131326830509784",
            fall  = "https://www.roblox.com/asset/?id=121152442762481"
        },
    }
    
    local animMap = {
        idle  = { folder = "idle",  slots = { { child = "Animation1", origKey = "idle1" }, { child = "Animation2", origKey = "idle2" } } },
        walk  = { folder = "walk",  slots = { { child = "WalkAnim",   origKey = "walk"  } } },
        run   = { folder = "run",   slots = { { child = "RunAnim",    origKey = "run"   } } },
        jump  = { folder = "jump",  slots = { { child = "JumpAnim",   origKey = "jump"  } } },
        climb = { folder = "climb", slots = { { child = "ClimbAnim",  origKey = "climb" } } },
        fall  = { folder = "fall",  slots = { { child = "FallAnim",   origKey = "fall"  } } },
    }
    
    local function saveOriginalAnimations(character)
        local Animate = character:FindFirstChild("Animate")
        if not Animate then return end

        for _, info in pairs(animMap) do
            local folder = Animate:FindFirstChild(info.folder)
            if folder then
                for _, slot in ipairs(info.slots) do
                    local anim = folder:FindFirstChild(slot.child)
                    if anim then
                        originalAnims[slot.origKey] = anim.AnimationId
                    end
                end
            end
        end
    end

    local function stopAllAnimations()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end

    local function restoreDefaultAnimations()
        if not LocalPlayer or not LocalPlayer.Character then return end
        local character = LocalPlayer.Character
        local Animate = character:FindFirstChild("Animate")
        if not Animate then return end

        stopAllAnimations()
        Animate.Disabled = true
        task.wait(0.1)

        for _, info in pairs(animMap) do
            local folder = Animate:FindFirstChild(info.folder)
            if folder then
                for _, slot in ipairs(info.slots) do
                    local anim = folder:FindFirstChild(slot.child)
                    if anim and originalAnims[slot.origKey] then
                        anim.AnimationId = originalAnims[slot.origKey]
                    end
                end
            end
        end

        Animate.Disabled = false
    end

    local function getPresetForType(animType)
        if animState[animType] ~= "Default" then return animState[animType] end
        if animState.all ~= "Default" then return animState.all end
        return "Default"
    end

    local function applyAnimations()
        if not feAnimEnabled then return end
        if not LocalPlayer or not LocalPlayer.Character then return end

        local character = LocalPlayer.Character
        local Animate = character:FindFirstChild("Animate")
        if not Animate then return end

        stopAllAnimations()
        Animate.Disabled = true
        task.wait(0.1)

        for animType, info in pairs(animMap) do
            local presetName = getPresetForType(animType)
            local preset = animPresets[presetName]
            local folder = Animate:FindFirstChild(info.folder)

            if folder then
                for _, slot in ipairs(info.slots) do
                    local anim = folder:FindFirstChild(slot.child)
                    if anim then
                        if presetName == "Default" then
                            if originalAnims[slot.origKey] then
                                anim.AnimationId = originalAnims[slot.origKey]
                            end
                        elseif preset and preset[slot.origKey] then
                            anim.AnimationId = preset[slot.origKey]
                        end
                    end
                end
            end
        end

        Animate.Disabled = false
    end

    local feAnimCharConn = nil

local function enableFEAnims()
    if feAnimCharConn then
        feAnimCharConn:Disconnect()
        feAnimCharConn = nil
    end

    if LocalPlayer.Character then
        saveOriginalAnimations(LocalPlayer.Character)
        applyAnimations()
    end

    feAnimCharConn = LocalPlayer.CharacterAdded:Connect(function(character)
        if not feAnimEnabled then return end
        originalAnims = {}

        -- Use WaitForChild with timeout instead of repeat loop
        local Animate = character:WaitForChild("Animate", 10)
        if not Animate then return end
        
        local idle = Animate:WaitForChild("idle", 5)
        if idle then
            local anim1 = idle:WaitForChild("Animation1", 3)
            if anim1 and anim1.AnimationId ~= "" then
                saveOriginalAnimations(character)
                applyAnimations()
            end
        end
    end)

    FEAnimMaid:GiveTask(feAnimCharConn)
end

    local function disableFEAnims()
        if feAnimCharConn then
            feAnimCharConn:Disconnect()
            feAnimCharConn = nil
        end
        FEAnimMaid:DoCleaning()

        animState.all   = "Default"
        animState.idle  = "Default"
        animState.walk  = "Default"
        animState.run   = "Default"
        animState.jump  = "Default"
        animState.climb = "Default"
        animState.fall  = "Default"

        restoreDefaultAnimations()
    end

    local animOptions = {
        "Default", "OG Rthro Run", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost",
        "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon",
        "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar",
        "Princess", "Cowboy", "Patrol", "Zombie FE", "Catwalk Glam", "Amazon Unboxed",
        "Glow Motion", "Bubbly", "Adidas Comm", "KATSEYE", "Wicked Popular"
    }

    feAnimSection:AddToggle("Enable FE Anims", function(enabled)
        feAnimEnabled = enabled
        if enabled then
            enableFEAnims()
        else
            disableFEAnims()
        end
    end)

    feAnimSection:AddDropdown("All Animations", animOptions, function(selected)
        if not feAnimEnabled then return end
        animState.all = selected
        applyAnimations()
    end)

    local dropdowns = {
        { label = "Idle Animation",  key = "idle"  },
        { label = "Walk Animation",  key = "walk"  },
        { label = "Run Animation",   key = "run"   },
        { label = "Jump Animation",  key = "jump"  },
        { label = "Climb Animation", key = "climb" },
        { label = "Fall Animation",  key = "fall"  },
    }

    for _, dd in ipairs(dropdowns) do
        feAnimSection:AddDropdown(dd.label, animOptions, function(selected)
            if not feAnimEnabled then return end
            animState[dd.key] = selected
            applyAnimations()
        end)
    end

    RootMaid:GiveTask(function()
        feAnimEnabled = false
        disableFEAnims()
    end)
end

do
    local wallhopSection = shared.AddSection("Wallhop")
    local wallhopToggle, flickEnabled, InfiniteJumpEnabled = false, false, true
    local WallhopMaid
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    RootMaid:GiveTask(function() if WallhopMaid then WallhopMaid:Destroy() end end)
    
    wallhopSection:AddToggle("Enable Wallhop", function(enabled)
        if WallhopMaid then WallhopMaid:Destroy() end
        wallhopToggle = enabled
        
        if enabled then
            WallhopMaid = Maid.new()
            WallhopMaid:GiveTask(Services.UserInputService.JumpRequest:Connect(function()
                if not wallhopToggle or not InfiniteJumpEnabled then return end
                
                local character = LocalPlayer.Character
                if not character then return end
                
                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                raycastParams.FilterDescendantsInstances = {character}
                local hit = workspace:Raycast(root.Position, root.CFrame.LookVector * 2, raycastParams)
                
                if hit then
                    InfiniteJumpEnabled = false
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                    task.wait(0.1)
                    InfiniteJumpEnabled = true
                end
            end))
        end
    end)
    
    wallhopSection:AddToggle("Enable Wallhop Flick", function(enabled) flickEnabled = enabled end)
end

do
    local lagVCSection = shared.AddSection("FE Lag VC")
    local LagVCMaid
    
    RootMaid:GiveTask(function() if LagVCMaid then LagVCMaid:Destroy() end end)
    
    lagVCSection:AddToggle("Enable Lag VC", function(state)
        if LagVCMaid then LagVCMaid:Destroy() end
        
        if state then
            LagVCMaid = Maid.new()
            PlaySong:FireServer("https://www.roblox.com/asset/?id=6691278175")
            LagVCMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                PlaySong:FireServer("https://www.roblox.com/asset/?id=6691278175")
            end))
        end
    end)
end

do
    local ssSection = shared.AddSection("Sign Spam")
    local spamming, ssButtonEnabled, autoGetGG = false, false, false
    local ssButtonSize = 0.11
    local SignSpamMaid, SignSpamAutoMaid
    
    RootMaid:GiveTask(function()
        if SignSpamMaid then SignSpamMaid:Destroy() end
        if SignSpamAutoMaid then SignSpamAutoMaid:Destroy() end
    end)
    
    local function findSign()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and string.lower(tool.Name):find("sign") then
                return tool, backpack
            end
        end
        
        local character = LocalPlayer.Character
        if character then
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and string.lower(tool.Name):find("sign") then
                    return tool, character
                end
            end
        end
        
        return nil, nil
    end
    
    local function startSpam()
        spamming = true
        if SignSpamMaid then SignSpamMaid:Destroy() end
        SignSpamMaid = Maid.new()
        
        local thread = task.spawn(function()
            while spamming do
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                
                if humanoid then
                    local tool, location = findSign()
                    if tool then
                        if location == LocalPlayer.Backpack then
                            humanoid:EquipTool(tool)
                        end
                        task.wait(0.05)
                        humanoid:UnequipTools()
                        task.wait(0.05)
                    else
                        task.wait(0.5)
                    end
                else
                    task.wait(0.1)
                end
            end
        end)
        SignSpamMaid:GiveTask(function() task.cancel(thread) end)
    end
    
    local function stopSpam()
        spamming = false
        if SignSpamMaid then SignSpamMaid:Destroy() end
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:UnequipTools() end
        end
    end
    
    ssSection:AddToggle("Enable Auto-Get GG", function(state)
        if SignSpamAutoMaid then SignSpamAutoMaid:Destroy() end
        autoGetGG = state
        
        if state then
            SignSpamAutoMaid = Maid.new()
            pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GGSign") end)
            SignSpamAutoMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if autoGetGG then
                    pcall(function() Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GGSign") end)
                end
            end))
        end
    end)
    
    ssSection:AddToggle("Enable Sign Spam", function(state)
        if state then startSpam() else stopSpam() end
    end)
    
    ssSection:AddToggle("Enable SS Button", function(enabled)
        ssButtonEnabled = enabled
        
        if enabled then
            BindableButtons.AddBButton("ss_bind", "SS", function()
                if spamming then stopSpam() else startSpam() end
            end)
            local btn = BindableButtons.Buttons["ss_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(ssButtonSize * (screen.Y / screen.X), 0, ssButtonSize, 0)
            end
        else
            BindableButtons.DeleteBButton("ss_bind")
        end
    end)
    
    ssSection:AddSlider("SS Button Size", 5, 25, 11, function(value)
        ssButtonSize = value / 100
        local btn = BindableButtons.Buttons["ss_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(ssButtonSize * (screen.Y / screen.X), 0, ssButtonSize, 0)
        end
    end)
end

do
    local GGTLSection = shared.AddSection("Grab Gun (TL)")
    local ggButtonEnabled, autoGGEnabled = false, false
    local ggButtonSize = 0.11
    local autoGGMaid = Maid.new()
    
    RootMaid:GiveTask(autoGGMaid)
    
    local function findNearestGG()
        local character = LocalPlayer.Character
        if not character then return nil end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        
        local nearest, minDist = nil, math.huge
        local rootPos = root.Position
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                local dist = (rootPos - obj.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
        
        return nearest
    end
    
    local function grabGG()
        local char = LocalPlayer.Character
        if not char then 
            Notify("Grab Gun", "Character not found!", 3)
            return 
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then 
            Notify("Grab Gun", "Root part not found!", 3)
            return 
        end
        
        local ggDrop = findNearestGG()
        if not ggDrop then 
            Notify("Grab Gun", "No gun drop found!", 3)
            return 
        end
        
        local savedPos = root.CFrame
        Notify("Grab Gun", "Grabbing gun...", 2)
        
        root.CFrame = CFrame.new(ggDrop.Position + Vector3.new(0, 3, 0))
        
        task.wait(0.3)
        
        root.CFrame = savedPos
        Notify("Grab Gun", "Returned to original position!", 2)
    end
    
    GGTLSection:AddToggle("Enable GG Button", function(enabled)
        ggButtonEnabled = enabled
        
        if enabled then
            BindableButtons.AddBButton("gg_bind", "GG", grabGG)
            local btn = BindableButtons.Buttons["gg_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(ggButtonSize * (screen.Y / screen.X), 0, ggButtonSize, 0)
            end
        else
            BindableButtons.DeleteBButton("gg_bind")
        end
    end)
    
    GGTLSection:AddToggle("Enable Auto GG", function(enabled)
        autoGGEnabled = enabled
        autoGGMaid:DoCleaning()
        
        if enabled then
            task.spawn(function()
                while autoGGEnabled do
                    local gg = findNearestGG()
                    if gg and LocalPlayer.Character then
                        grabGG()
                    end
                    task.wait(2)
                end
            end)
            
            autoGGMaid:GiveTask(workspace.DescendantAdded:Connect(function(obj)
                if autoGGEnabled and obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    task.wait(0.1)
                    if LocalPlayer.Character then
                        grabGG()
                    end
                end
            end))
        end
    end)
    
    GGTLSection:AddSlider("GG Button Size", 5, 25, 11, function(value)
        ggButtonSize = value / 100
        local btn = BindableButtons.Buttons["gg_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(ggButtonSize * (screen.Y / screen.X), 0, ggButtonSize, 0)
        end
    end)
    
    GGTLSection:AddButton("Grab Gun", grabGG)
    
    local ggKeybind = Services.UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.G then 
            grabGG() 
        end
    end)
    RootMaid:GiveTask(ggKeybind)
end

local giveGunSection = shared.AddSection("Give Gun")

local giveGunEnabled, autoGiveGunEnabled = false, false
local selectedPlayer = nil
local autoGiveMaid = Maid.new()
local giveGunButtonSize = 0.11

RootMaid:GiveTask(autoGiveMaid)

local function hasGunInInventory()
    local player = LocalPlayer
    local character = player.Character
    local backpack = player.Backpack
    
    if not character then return false end
    
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("gun") or (tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("Gun"))) then
            return true
        end
    end
    
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or (tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("Gun"))) then
                return true
            end
        end
    end
    
    return false
end

local function giveGunToPlayer(targetPlayer)
    if not targetPlayer then
        Notify("Give Gun", "No player selected!", 3)
        return
    end
    
    if not hasGunInInventory() then
        Notify("Give Gun", "You don't have a gun in your inventory!", 3)
        return
    end
    
    local char = LocalPlayer.Character
    if not char then
        Notify("Give Gun", "Character not found!", 3)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        Notify("Give Gun", "Root part not found!", 3)
        return
    end
    
    local targetChar = targetPlayer.Character
    if not targetChar then
        Notify("Give Gun", "Target character not found!", 3)
        return
    end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Notify("Give Gun", "Target root part not found!", 3)
        return
    end
    
    Notify("Give Gun", "Giving gun to " .. targetPlayer.Name .. "...", 2)
    
    root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
    
    task.wait(0.3)
    
    LocalPlayer.Character:BreakJoints()
end

local function executeGiveGun()
    if giveGunEnabled and selectedPlayer then
        giveGunToPlayer(selectedPlayer)
    end
end

local players = {}
for _, player in pairs(game.Players:GetPlayers()) do
    if player ~= LocalPlayer then
        table.insert(players, player.Name)
    end
end

local playerDropdown = giveGunSection:AddDropdown("Select Player", players, function(value)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Name == value then
            selectedPlayer = player
            break
        end
    end
end)

giveGunSection:AddToggle("Auto Give Gun", function(enabled)
    autoGiveGunEnabled = enabled
    autoGiveMaid:DoCleaning()
    
    if enabled then
        task.spawn(function()
            while autoGiveGunEnabled do
                if giveGunEnabled and selectedPlayer and hasGunInInventory() then
                    giveGunToPlayer(selectedPlayer)
                end
                task.wait(2)
            end
        end)
    end
end)

giveGunSection:AddButton("Give Gun", executeGiveGun)

giveGunSection:AddToggle("Enable Give Gun Button", function(enabled)
    giveGunEnabled = enabled
    
    if enabled then
        BindableButtons.AddBButton("givegun_bind", "Give Gun", executeGiveGun)
        local btn = BindableButtons.Buttons["givegun_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(giveGunButtonSize * (screen.Y / screen.X), 0, giveGunButtonSize, 0)
        end
    else
        BindableButtons.DeleteBButton("givegun_bind")
    end
end)

giveGunSection:AddSlider("Give Gun Button Size", 5, 25, 11, function(value)
    giveGunButtonSize = value / 100
    local btn = BindableButtons.Buttons["givegun_bind"]
    if btn then
        local screen = workspace.CurrentCamera.ViewportSize
        btn.Size = __UD2(giveGunButtonSize * (screen.Y / screen.X), 0, giveGunButtonSize, 0)
    end
end)

giveGunSection:AddLabel("Must enable auto grab gun for auto give gun to work")

local giveGunKeybind = Services.UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.G and giveGunEnabled and selectedPlayer then
        executeGiveGun()
    end
end)
RootMaid:GiveTask(giveGunKeybind)

local flick_section = shared.AddSection("Flick to Murderer")
flick_section:AddLabel("Credits: idk_367.5")

local flickEnabled    = false
local flickSpeed      = 1
local autoShootEnabled = false
local bigButtonSize   = 200
local bindButtonSize  = 0.11

local function findMurderer()
    if game.PlaceId == 142823291 then
        local success, roleData = pcall(function()
            local remote = Services.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer()
            end
        end)
        if success and roleData then
            for playerName, data in pairs(roleData) do
                if data.Role == "Murderer" and not data.Killed and not data.Dead then
                    local p = Services.Players:FindFirstChild(playerName)
                    if p then return p end
                end
            end
        end
        return nil
    else
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum  = char:FindFirstChild("Humanoid")
                if root and hum and hum.Health > 0 then
                    local bp = player:FindFirstChild("Backpack")
                    if bp and bp:FindFirstChild("Knife") then return player end
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name == "Knife" then return player end
                    end
                end
            end
        end
        return nil
    end
end

local function findShootRemote()
    local ns = Services.ReplicatedStorage:FindFirstChild("Axioria Solver was here.")
    if not ns then return nil end
    for _, v in ipairs(ns:GetChildren()) do
        if v:IsA("RemoteEvent") then return v end
    end
    return nil
end

local function autoShoot(murderer)
    if not autoShootEnabled then return end
    if not murderer or not murderer.Character then return end
    local remote = findShootRemote()
    if not remote then return end
    local murdererRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not murdererRoot then return end
    pcall(function()
        remote:FireServer(table.unpack({
            [1] = workspace.CurrentCamera.CFrame,
            [2] = CFrame.new(murdererRoot.Position),
        }))
    end)
end

local function flickToMurderer()
    if not flickEnabled then 
        Notify("Flick", "Flick is disabled!", 3)
        return 
    end
    local murderer = findMurderer()
    if not murderer or not murderer.Character or not murderer.Character:FindFirstChild("HumanoidRootPart") then
        Notify("Flick", "Murderer not found!", 3)
        return
    end
    local cam   = workspace.CurrentCamera
    local char  = LocalPlayer.Character
    if not char then return end
    local root  = char:FindFirstChild("HumanoidRootPart")
    local hum   = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    local targetPos   = murderer.Character.HumanoidRootPart.Position
    local oldCFrame   = cam.CFrame
    local targetCFrame = CFrame.lookAt(oldCFrame.Position, targetPos)
    local steps    = 8
    local waitTime = (flickSpeed / 1000) / steps

    for i = 1, steps do
        cam.CFrame = oldCFrame:Lerp(targetCFrame, i / steps)
        task.wait(waitTime)
    end
    autoShoot(murderer)
    for i = 1, steps do
        cam.CFrame = targetCFrame:Lerp(oldCFrame, i / steps)
        task.wait(waitTime * 0.7)
    end
    cam.CFrame = oldCFrame
end

flick_section:AddToggle("Enable Flick", function(state)
    flickEnabled = state
    Notify("Flick", state and "Flick enabled" or "Flick disabled", state and 1 or 3)
end)

flick_section:AddSlider("Flick Speed (ms)", 1, 50, 1, function(value)
    flickSpeed = value
end)

flick_section:AddKeybind("Flick Key", "F", function()
    flickToMurderer()
end)

flick_section:AddToggle("Auto Shoot on Flick", function(state)
    autoShootEnabled = state
    Notify("Auto Shoot", state and "Auto Shoot ON" or "Auto Shoot OFF", state and 1 or 3)
end)

flick_section:AddToggle("Show Big Button", function(state)
    if state then
        AddBigButton("flick_big", "FLICK", flickToMurderer)
        local btn = BBSystem.Buttons["flick_big"]
        if btn then
            btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375)
        end
    else
        DeleteBigButton("flick_big")
    end
end)

flick_section:AddSlider("Big Button Size", 100, 400, 200, function(value)
    bigButtonSize = value
    local btn = BBSystem.Buttons["flick_big"]
    if btn then
        btn.Size = __UD2(0, bigButtonSize, 0, bigButtonSize * 0.375)
    end
end)

flick_section:AddToggle("Show Bind Button", function(state)
    if state then
        BindableButtons.AddBButton("flick_bind", "FLICK", flickToMurderer)
        local btn = BindableButtons.Buttons["flick_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
        end
    else
        BindableButtons.DeleteBButton("flick_bind")
    end
end)

flick_section:AddSlider("Bind Button Size", 5, 25, 11, function(value)
    bindButtonSize = value / 100
    local btn = BindableButtons.Buttons["flick_bind"]
    if btn then
        local screen = workspace.CurrentCamera.ViewportSize
        btn.Size = __UD2(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
    end
end)

local statColorsEnabled = false
local uiPosition = "Top Right"
local positionPresets = {
    ["Top Right"] = UDim2.new(0.80, 0, 0, 15),
    ["Top Left"] = UDim2.new(0.02, 0, 0, 15),
    ["Top Center"] = UDim2.new(0.44, 0, 0, 15),
    ["Bottom Right"] = UDim2.new(0.80, 0, 0.85, 0),
    ["Bottom Left"] = UDim2.new(0.02, 0, 0.85, 0),
}

local function getFpsCap()
    return workspace:GetAttribute("FPSCap") or 60
end

local function getFpsColor(fps)
    local cap = getFpsCap()
    if fps >= cap * 0.85 then return Color3.fromRGB(0, 255, 0)
    elseif fps >= cap * 0.5 then return Color3.fromRGB(255, 200, 0)
    else return Color3.fromRGB(255, 0, 0) end
end

local function getPingColor(ping)
    if ping <= 80 then return Color3.fromRGB(0, 255, 0)
    elseif ping <= 150 then return Color3.fromRGB(255, 200, 0)
    else return Color3.fromRGB(255, 0, 0) end
end

local function createFpsPingGui()
    if _G.FpsPingGui then _G.FpsPingGui:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FpsPingMonitor"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _G.FpsPingGui = ScreenGui
    
    local Fps = Instance.new("TextLabel")
    Fps.BackgroundTransparency = 1
    Fps.Size = UDim2.new(0, 120, 0, 25)
    Fps.Font = Enum.Font.SourceSans
    Fps.TextColor3 = Color3.fromRGB(255, 255, 255)
    Fps.TextScaled = true
    Fps.Text = "0"
    Fps.Parent = ScreenGui
    _G.FpsLabel = Fps
    
    local Ping = Instance.new("TextLabel")
    Ping.BackgroundTransparency = 1
    Ping.Size = UDim2.new(0, 120, 0, 25)
    Ping.Font = Enum.Font.SourceSans
    Ping.TextColor3 = Color3.fromRGB(255, 255, 255)
    Ping.TextScaled = true
    Ping.Text = "0"
    Ping.Parent = ScreenGui
    _G.PingLabel = Ping
    
    local base = positionPresets[uiPosition] or positionPresets["Top Right"]
    Fps.Position = base
    Ping.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 28)
    
    local lastFPS, lastPing, lastPingUpdate = -1, -1, 0
    
    local connection = Services.RunService.RenderStepped:Connect(function(frame)
        if not _G.FpsPingGui or not _G.FpsPingGui.Parent then
            connection:Disconnect()
            return
        end
        
        local fps = math.floor(1 / frame + 0.5)
        if fps ~= lastFPS then
            lastFPS = fps
            Fps.Text = tostring(fps)
            Fps.TextColor3 = statColorsEnabled and getFpsColor(fps) or Color3.fromRGB(255, 255, 255)
        end
        
        local now = os.clock()
        if now - lastPingUpdate >= 0.5 then
            lastPingUpdate = now
            local pingValue = Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            local rawPing = tonumber(pingValue:match("%-?%d+")) or 0
            if rawPing ~= lastPing then
                lastPing = rawPing
                Ping.Text = tostring(rawPing)
                Ping.TextColor3 = statColorsEnabled and getPingColor(rawPing) or Color3.fromRGB(255, 255, 255)
            end
        end
    end)
end

local fps_ping_section = shared.AddSection("FPS & PING MONITOR")
fps_ping_section:AddToggle("Enable Monitor UI", function(bool)
    if bool then createFpsPingGui()
    elseif _G.FpsPingGui then
        _G.FpsPingGui:Destroy()
        _G.FpsPingGui = nil
    end
end)

fps_ping_section:AddToggle("Enable Statistic Colors", function(bool) statColorsEnabled = bool end)
fps_ping_section:AddDropdown("UI Position", {"Top Right", "Top Left", "Top Center", "Bottom Right", "Bottom Left"}, function(s)
    uiPosition = s
    if _G.FpsLabel and _G.PingLabel then
        local base = positionPresets[s] or positionPresets["Top Right"]
        _G.FpsLabel.Position = base
        _G.PingLabel.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 28)
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local perf_section = shared.AddSection("Performance Optimization")

local original_materials = {}
local original_particle_states = {}
local original_textures = {}
local original_mesh_transparency = {}
local original_accessories = {}

local conns = {
    Meshes = nil,
    Smooth = nil,
    Particles = nil,
    Textures = nil,
    CharacterAdded = nil
}

local fpsBoostEnabled = false

local function isPlayerDescendant(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
end

local function applyMeshToObj(obj)
    if isPlayerDescendant(obj) then return end

    if obj:IsA("MeshPart") then
        if original_mesh_transparency[obj] == nil then
            original_mesh_transparency[obj] = obj.Transparency
        end
        obj.Transparency = 1
        return
    end

    if obj:IsA("SpecialMesh") or obj:IsA("BlockMesh") or obj:IsA("CylinderMesh") then
        local parent = obj.Parent
        if parent and parent:IsA("BasePart") and not isPlayerDescendant(parent) then
            if original_mesh_transparency[parent] == nil then
                original_mesh_transparency[parent] = parent.Transparency
            end
            parent.Transparency = 1
        end
    end
end

local function setMeshes(on)
    if on then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            applyMeshToObj(obj)
        end
        if not conns.Meshes then
            conns.Meshes = Workspace.DescendantAdded:Connect(function(obj)
                task.defer(function() applyMeshToObj(obj) end)
            end)
        end
    else
        for part, trans in pairs(original_mesh_transparency) do
            if part and part.Parent then
                pcall(function() part.Transparency = trans end)
            end
        end
        original_mesh_transparency = {}
        if conns.Meshes then
            conns.Meshes:Disconnect()
            conns.Meshes = nil
        end
    end
end

local function setSmoothPlastic(on)
    if on then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not isPlayerDescendant(obj) and obj.Material ~= Enum.Material.SmoothPlastic then
                original_materials[obj] = obj.Material
                obj.Material = Enum.Material.SmoothPlastic
            end
        end
        if not conns.Smooth then
            conns.Smooth = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("BasePart") and not isPlayerDescendant(obj) then
                    original_materials[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end)
        end
    else
        for part, mat in pairs(original_materials) do
            if part and part.Parent then
                pcall(function() part.Material = mat end)
            end
        end
        original_materials = {}
        if conns.Smooth then 
            conns.Smooth:Disconnect() 
            conns.Smooth = nil 
        end
    end
end

local function setParticles(on)
    if on then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                original_particle_states[obj] = obj.Enabled
                obj.Enabled = false
            end
        end
        if not conns.Particles then
            conns.Particles = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    original_particle_states[obj] = obj.Enabled
                    obj.Enabled = false
                end
            end)
        end
    else
        for obj, state in pairs(original_particle_states) do
            if obj and obj.Parent then
                pcall(function() obj.Enabled = state end)
            end
        end
        original_particle_states = {}
        if conns.Particles then 
            conns.Particles:Disconnect() 
            conns.Particles = nil 
        end
    end
end

local function setTextures(on)
    if on then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                if original_textures[obj] == nil then
                    original_textures[obj] = obj.Texture
                end
                obj.Texture = ""
            end
        end
        if not conns.Textures then
            conns.Textures = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    if original_textures[obj] == nil then
                        original_textures[obj] = obj.Texture
                    end
                    obj.Texture = ""
                end
            end)
        end
    else
        for obj, tex in pairs(original_textures) do
            if obj and obj.Parent then
                pcall(function() obj.Texture = tex end)
            end
        end
        original_textures = {}
        if conns.Textures then 
            conns.Textures:Disconnect() 
            conns.Textures = nil 
        end
    end
end

local function setShadows(on)
    Lighting.GlobalShadows = not on
end

local function setAccessories(on)
    if on then
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                for _, acc in ipairs(char:GetChildren()) do
                    if acc:IsA("Accessory") then
                        original_accessories[acc] = plr
                        acc.Parent = nil
                    end
                end
            end
        end
        if not conns.CharacterAdded then
            conns.CharacterAdded = Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function(ch)
                    task.defer(function()
                        for _, acc in ipairs(ch:GetChildren()) do
                            if acc:IsA("Accessory") then
                                original_accessories[acc] = p
                                acc.Parent = nil
                            end
                        end
                    end)
                end)
            end)
        end
    else
        for acc, owner in pairs(original_accessories) do
            if owner and owner.Character and acc and not acc.Parent then
                pcall(function() acc.Parent = owner.Character end)
            end
        end
        original_accessories = {}
        if conns.CharacterAdded then
            conns.CharacterAdded:Disconnect()
            conns.CharacterAdded = nil
        end
    end
end

local function setGraySky(on)
    if on then
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                obj:Destroy()
            end
        end
        local sky = Instance.new("Sky")
        local assetId = "rbxassetid://99742693890881"
        sky.SkyboxBk = assetId
        sky.SkyboxDn = assetId
        sky.SkyboxFt = assetId
        sky.SkyboxLf = assetId
        sky.SkyboxRt = assetId
        sky.SkyboxUp = assetId
        sky.Parent = Lighting
    else
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                obj:Destroy()
            end
        end
    end
end

local function removeWeaponDisplays()
    local wd = Workspace:FindFirstChild("WeaponDisplays")
    if wd then 
        wd:Destroy() 
    end
end

local function degradePart(obj)
    if obj:IsA("BasePart") then
        obj.CastShadow = false
        obj.RenderFidelity = Enum.RenderFidelity.Disabled
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        obj.Enabled = false
    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        obj.Enabled = false
    end
end

local function setFrameEnhancement(bool)
    fpsBoostEnabled = bool
    
    if bool then
        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Disabled
        workspace.Terrain.Decoration = false
        
        for _, obj in ipairs(workspace:GetDescendants()) do 
            degradePart(obj) 
        end
        
        _G.FpsBoostConnection = workspace.DescendantAdded:Connect(degradePart)
    else
        Lighting.GlobalShadows = true
        Lighting.Brightness = 2
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Full
        workspace.Terrain.Decoration = true
        
        if _G.FpsBoostConnection then
            _G.FpsBoostConnection:Disconnect()
            _G.FpsBoostConnection = nil
        end
    end
end

perf_section:AddToggle("No Textures (SmoothPlastic)", setSmoothPlastic)
perf_section:AddToggle("Disable Shadows", setShadows)
perf_section:AddToggle("Disable Particles/Trails", setParticles)
perf_section:AddToggle("Hide Meshes (world only)", setMeshes)
perf_section:AddToggle("Remove Textures/Decals", setTextures)
perf_section:AddToggle("Remove Accessories", setAccessories)
perf_section:AddToggle("Gray Skybox", setGraySky)
perf_section:AddButton("Remove Weapon Displays", removeWeaponDisplays)
perf_section:AddToggle("Enable Frame Enhancement", setFrameEnhancement)

local true_antis_section = shared.AddSection("True Anti's")
local trueAntiFlingConnection, trueAntiAfkConnection

true_antis_section:AddToggle("Enable IY Anti Fling", function(bool)
    if trueAntiFlingConnection then
        trueAntiFlingConnection:Disconnect()
        trueAntiFlingConnection = nil
    end
    
    if bool then
        local playerCache = {}
        
        local function updateCache()
            playerCache = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    playerCache[p] = true
                end
            end
        end
        updateCache()
        
        local playerAddedConn = Services.Players.PlayerAdded:Connect(updateCache)
        local playerRemovingConn = Services.Players.PlayerRemoving:Connect(updateCache)
        
        trueAntiFlingConnection = Services.RunService.Heartbeat:Connect(function()
            for player in pairs(playerCache) do
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then 
                            part.CanCollide = false 
                        end
                    end
                end
            end
        end)
        
        _G.AntiFlingCleanup = {playerAddedConn, playerRemovingConn}
    else
        if _G.AntiFlingCleanup then
            for _, conn in ipairs(_G.AntiFlingCleanup) do
                conn:Disconnect()
            end
            _G.AntiFlingCleanup = nil
        end
    end
end)

true_antis_section:AddToggle("Enable True Anti AFK", function(bool)
    if trueAntiAfkConnection then
        trueAntiAfkConnection:Disconnect()
        trueAntiAfkConnection = nil
    end
    
    if bool then
        trueAntiAfkConnection = LocalPlayer.Idled:Connect(function()
            Services.VirtualUser:CaptureController()
            Services.VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

local creditsSection = shared.AddSection("Credits")
creditsSection:AddParagraph("@lzzzx", "Made this plugin, if you have requests feel free to ask.")

RootMaid:GiveTasks(
    function() if trueAntiFlingConnection then trueAntiFlingConnection:Disconnect() end end,
    function() if trueAntiAfkConnection then trueAntiAfkConnection:Disconnect() end end,
    function() 
        for id, _ in pairs(BBSystem.Buttons) do
            DeleteBigButton(id)
        end
    end,
    function()
        for id, _ in pairs(BindableButtons.Buttons) do
            BindableButtons.DeleteBButton(id)
        end
    end
)
