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

local muteButtonSounds = false

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in pairs(BBSystem.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
    for id, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
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
    sound.Volume = muteButtonSounds and 0 or 0.5
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
    sound.Volume = muteButtonSounds and 0 or 0.5
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

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

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

local blueAuraSection = shared.AddSection("Blue Aura")

blueAuraSection:AddLabel("kill them with your absolute crushing aura")

local blueAuraEnabled = false
local auraStuds = 10
local whitelist = {}
local auraMaid = Maid.new()

RootMaid:GiveTask(auraMaid)

local function getMurdererKnife()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local knife = character:FindFirstChild("Knife")
    if not knife and LocalPlayer.Backpack then
        knife = LocalPlayer.Backpack:FindFirstChild("Knife")
    end
    
    return knife
end

local function getHandleTouchedEvent()
    local knife = getMurdererKnife()
    if not knife then return nil end
    
    local events = knife:FindFirstChild("Events")
    if not events then return nil end
    
    return events:FindFirstChild("HandleTouched")
end

local function killPlayer(targetPlayer)
    local handleTouched = getHandleTouchedEvent()
    if not handleTouched then return end
    
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    
    local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")
    if torso then
        handleTouched:FireServer(torso)
    end
end

local function checkAura()
    if not blueAuraEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local handleTouched = getHandleTouchedEvent()
    if not handleTouched then return end
    
    local rootPos = root.Position
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer and not table_find(whitelist, player.UserId) then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (rootPos - targetRoot.Position).Magnitude
                    if dist <= auraStuds then
                        local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")
                        if torso then
                            handleTouched:FireServer(torso)
                        end
                    end
                end
            end
        end
    end
end

blueAuraSection:AddToggle("Enable Blue Aura", function(enabled)
    blueAuraEnabled = enabled
    auraMaid:DoCleaning()
    
    if enabled then
        task.spawn(function()
            while blueAuraEnabled do
                checkAura()
                task.wait(0.5)
            end
        end)
    end
end)

blueAuraSection:AddSlider("Aura Studs", 5, 50, 10, function(value)
    auraStuds = value
end)

blueAuraSection:AddPlayerDropdown("Whitelist Player", function(player)
    if not table_find(whitelist, player.UserId) then
        table_insert(whitelist, player.UserId)
        Notify(player.Name .. " whitelisted.", 2)
    end
end)

blueAuraSection:AddButton("Clear Whitelist", function()
    whitelist = {}
    Notify("Whitelist cleared.", 2)
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
        "Vampiric2024",
        "SynthEffect2025",
        "Sunbeams2024",
        "Snowstorm2024",
        "Retro2025",
        "Radioactive",
        "Musical",
        "Heatwave2025",
        "Heartify",
        "Gifts2024",
        "Ghosts2024",
        "Ghostify",
        "FlamingoEffect2025",
        "Burn",
        "Cursed2024",
        "Coal2025",
        "Starry2024",
        "Bats2024",
        "Aquatic2025",
        "Treats2025",
        "Confetti2025",
        "Bokeh2025",
        "Lights2025",
        "Jellyfish2024",
        "Hearts26",
        "XmasGlow2025",
        "Cats2025",
        "Carrots2025",
        "BlueFire",
        "Rainbows2025",
        "Nightsky2025",
        "Frost2025",
        "Elitify",
        "Electric",
        "Dual",
        "Abduction2025",
        "SweetEffect26",
        "UFOs2025",
        "Strawberries26",
        "Snowballs2025",
        "Leaves2025"
    }, function(s)
        selectedDualEffect = s
    end)

    duelSection:AddToggle("Auto Equip Dual Effect", function(e)
        if DualEffectMaid then
            DualEffectMaid:Destroy()
        end

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

    RootMaid:GiveTask(function()
        if DualEffectMaid then
            DualEffectMaid:Destroy()
        end
    end)
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
    local lsBindButton = nil
    local lsButtonStroke = nil
    
    RootMaid:GiveTask(function() if LegitSpeedMaid then LegitSpeedMaid:Destroy() end end)
    
    local function UpdateButtonColor()
        if not lsBindButton or not lsButtonStroke then return end
        if emOn then
            lsButtonStroke.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 200, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 0))
            })
        else
            lsButtonStroke.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 0))
            })
        end
    end
    
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
        lsBindButton = nil
        lsButtonStroke = nil
        emOn = false
        
        if e then
            LegitSpeedMaid = Maid.new()
            
            BindableButtons.AddBButton("sg_bind", "SG", function()
                emOn = not emOn
                if emOn and selEmote then 
                    playE(selEmote) 
                elseif not emOn and LocalPlayer.Character then 
                    LocalPlayer.Character.Humanoid.WalkSpeed = 16 
                end
                UpdateButtonColor()
            end)
            lsBindButton = BindableButtons.Buttons["sg_bind"]
            if lsBindButton then
                local screen = workspace.CurrentCamera.ViewportSize
                lsBindButton.Size = __UD2(lsButtonSize * (screen.Y / screen.X), 0, lsButtonSize, 0)
                lsButtonStroke = lsBindButton:FindFirstChild("@Stroke")
                UpdateButtonColor()
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
                        h.WalkSpeed = (math.abs(h.MoveDirection:Dot(r.CFrame.RightVector)) > 0.5) and spd or 16
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
        if lsBindButton then
            local screen = workspace.CurrentCamera.ViewportSize
            lsBindButton.Size = __UD2(lsButtonSize * (screen.Y / screen.X), 0, lsButtonSize, 0)
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
    local selectedPlayers = {}
    local whitelist = {}
    local flingButtonSize = 0.11
    local clickFlingEnabled = false
    local flingAuraEnabled = false
    local auraStuds = 15
    local maids = {autoSheriff=nil, autoMurderer=nil, loopPlr=nil, loopAll=nil, clickFling=nil, flingAura=nil}
    local buttonToggles = {Sheriff=false, Murderer=false, Player=false}
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    
    RootMaid:GiveTask(function() 
        for _, m in pairs(maids) do if m then m:Destroy() end end
    end)
    
    local function isWhitelisted(player)
        return whitelist[player.UserId] == true
    end
    
    local function isPlayerSelected(player)
        for _, selected in ipairs(selectedPlayers) do
            if selected.UserId == player.UserId then
                return true
            end
        end
        return false
    end
    
    local function findSheriff()
        local success, roleData = pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer()
            end
        end)
        if success and roleData then
            for playerName, data in pairs(roleData) do
                if data.Role == "Sheriff" and not data.Killed and not data.Dead then
                    local p = Players:FindFirstChild(playerName)
                    if p and not isWhitelisted(p) then return p end
                end
            end
        end
        return nil
    end
    
    local function findMurderer()
        local success, roleData = pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer()
            end
        end)
        if success and roleData then
            for playerName, data in pairs(roleData) do
                if data.Role == "Murderer" and not data.Killed and not data.Dead then
                    local p = Players:FindFirstChild(playerName)
                    if p and not isWhitelisted(p) then return p end
                end
            end
        end
        return nil
    end
    
    local function hasGun(player)
        local character = player.Character
        if not character then return false end
        
        local tools = player.Backpack:GetChildren()
        for _, tool in ipairs(tools) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or 
               tool.Name:lower():find("revolver") or tool.Name:lower():find("shotgun") or
               tool.Name:lower():find("rifle") or tool.Name:lower():find("weapon")) then
                return true
            end
        end
        
        local characterTools = character:GetChildren()
        for _, tool in ipairs(characterTools) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or 
               tool.Name:lower():find("revolver") or tool.Name:lower():find("shotgun") or
               tool.Name:lower():find("rifle") or tool.Name:lower():find("weapon")) then
                return true
            end
        end
        
        return false
    end
    
    local function findSheriffWithFallback()
        local sheriff = findSheriff()
        if sheriff then return sheriff end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isWhitelisted(player) and hasGun(player) then
                return player
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
        local target = findSheriffWithFallback()
        if target then OdhSkid(target, 2) else Notify("Error", "No Sheriff or Gun Holder Found", 3) end
    end)
    
    flingSection:AddButton("Fling Murderer", function()
        local murderer = findMurderer()
        if murderer then OdhSkid(murderer, 2) else Notify("Error", "No Murderer Found", 3) end
    end)
    
    flingSection:AddButton("Fling All", function()
        for _, p in ipairs(Players:GetPlayers()) do
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
    
    flingSection:AddPlayerDropdown("Select Players", function(p)
        if p and p ~= LocalPlayer and not isPlayerSelected(p) then
            table.insert(selectedPlayers, p)
            Notify("Selected", p.Name.." added to fling list", 3)
        elseif p and isPlayerSelected(p) then
            Notify("Error", p.Name.." is already selected", 3)
        end
    end)
    
    flingSection:AddButton("Clear Selected Players", function()
        selectedPlayers = {}
        Notify("Cleared", "All selected players removed", 3)
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
    
    createAutoFling("Sheriff", findSheriffWithFallback)
    createAutoFling("Murderer", findMurderer)
    
    local buttonConfigs = {
        {name="Sheriff", text="FS", findFunc=findSheriffWithFallback, id="fling_sheriff"},
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
    
    flingSection:AddToggle("Loop Fling Player(s)", function(s)
        if maids.loopPlr then maids.loopPlr:Destroy() end
        
        if s then
            maids.loopPlr = Maid.new()
            local thread = task.spawn(function()
                while true do
                    if flingSelPlr and flingSelPlr.Parent and not isWhitelisted(flingSelPlr) then
                        OdhSkid(flingSelPlr, 2)
                        task.wait(3)
                    end
                    
                    for _, player in ipairs(selectedPlayers) do
                        if player and player.Parent and not isWhitelisted(player) then
                            OdhSkid(player, 2)
                            task.wait(0.5)
                        end
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
                    for _, p in ipairs(Players:GetPlayers()) do
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
    
    flingSection:AddToggle("Click Fling", function(enabled)
        clickFlingEnabled = enabled
        
        if maids.clickFling then maids.clickFling:Destroy() end
        
        if enabled then
            maids.clickFling = Maid.new()
            
            local function onMouseClick(input, processed)
                if processed then return end
                
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mouse = LocalPlayer:GetMouse()
                    local target = mouse.Target
                    
                    if target then
                        local character = target:FindFirstAncestorWhichIsA("Model")
                        if character then
                            local player = Players:GetPlayerFromCharacter(character)
                            if player and player ~= LocalPlayer and not isWhitelisted(player) then
                                OdhSkid(player, 2)
                                Notify("Click Fling", "Flinging "..player.Name, 2)
                            elseif player and isWhitelisted(player) then
                                Notify("Click Fling", player.Name.." is whitelisted!", 3)
                            end
                        end
                    end
                end
            end
            
            if UserInputService.TouchEnabled then
                maids.clickFling:GiveTask(UserInputService.TouchTap:Connect(onMouseClick))
            end
            
            maids.clickFling:GiveTask(UserInputService.InputBegan:Connect(onMouseClick))
        end
    end)
    
    flingSection:AddToggle("Fling Aura", function(enabled)
        flingAuraEnabled = enabled
        
        if maids.flingAura then maids.flingAura:Destroy() end
        
        if enabled then
            maids.flingAura = Maid.new()
            local thread = task.spawn(function()
                while flingAuraEnabled do
                    task.wait(0.5)
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if rootPart then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and not isWhitelisted(player) then
                                local targetChar = player.Character
                                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                                
                                if targetRoot and rootPart then
                                    local distance = (rootPart.Position - targetRoot.Position).Magnitude
                                    if distance <= auraStuds then
                                        OdhSkid(player, 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            maids.flingAura:GiveTask(function() task.cancel(thread) end)
        end
    end)
    
    flingSection:AddSlider("Aura Studs", 5, 50, 15, function(value)
        auraStuds = value
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
    local BOMB_NAMES = {"FakeBomb"}
    local BombJumpMaid, BombJumpTimerMaid
    local bjBindButton
    local onCooldown, bombJumpEnabled = false, false
    local debounce, autoGetBomb, justRespawned = false, false, false
    local bigButtonSize = 200
    local bindButtonSize = 0.11
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
    
    local function ResetCooldown()
        onCooldown = false
        local bigBtn = BBSystem.Buttons["bombjump_big"]
        if bigBtn then bigBtn.Text = "Bomb Jump" end
        UpdateBJButton("BJ", false)
    end
    
    local function StartCooldown()
        onCooldown = true
        debounce = false
        local bigBtn = BBSystem.Buttons["bombjump_big"]
        if bigBtn then bigBtn.Text = "Wait" end
        UpdateBJButton("Wait", true)
        
        task.spawn(function()
            for i = 22, 1, -1 do
                if not onCooldown then break end
                local bigBtn = BBSystem.Buttons["bombjump_big"]
                if bigBtn then bigBtn.Text = tostring(i) end
                UpdateBJButton(tostring(i), true)
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
    
    section:AddLabel("Bomb Jump Options")
    section:AddToggle("Enable Auto Bomb Jump", function(bool) bombJumpEnabled = bool end)
    section:AddToggle("Auto-Get Fake Bomb", function(bool)
        autoGetBomb = bool
        if autoGetBomb then
            -- Fire the remote immediately when toggled on
            pcall(function() 
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
            end)
        end
    end)

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

return(function(...)local o={"\120\074\099\122\120\116\118\111\066\114\118\097\112\074\065\066\080\053\043\061","\088\111\086\068\065\074\049\118\066\107\065\052\107\105\068\047\098\116\110\061","\106\116\086\081\106\104\083\102\080\089\090\061";"\065\115\052\049\065\110\061\061";"","\106\098\122\082\088\098\113\048";"\088\053\097\111\065\110\061\061","\109\048\075\114\100\048\079\114\074\070\061\061";"\066\098\105\043\066\053\113\104\079\116\052\084\079\074\049\116","\065\109\083\051\080\085\067\061","\080\055\074\061";"\106\116\086\084\106\098\105\071\065\109\067\061";"\120\070\061\061","\103\107\065\097\113\073\097\055\080\114\070\122\098\053\052\083\065\081\119\061","\090\089\079\049\080\085\065\097";"\080\114\102\112\079\116\090\115\088\098\052\052\065\052\102\066","\071\067\119\061";"\068\077\078\115\057\073\089\078\115\075\043\113\079\076\114\101\108\111\067\122\085\051\099\089\085\105\048\103\070\098\112\088\055\121\069\081\086\106\120\052\049\115\112\061","\090\115\079\111\080\098\079\111\088\109\076\118\088\089\121\097";"\066\097\097\083\113\109\118\050\069\073\097\075\076\089\067\115\112\119\061\061","\109\105\086\099\065\098\056\061";"\065\089\121\050\080\085\067\061";"\079\053\076\047\080\116\049\102\090\097\097\122\107\074\118\107","\088\115\118\118\090\070\061\061","\069\115\065\108\110\079\076\078\076\073\119\111\065\074\118\071\076\110\061\061","\090\085\076\051\069\098\122\053";"\069\105\088\085\110\089\086\074\110\114\106\108\080\055\083\071\069\115\088\061";"\106\116\083\114\079\073\113\109\117\115\079\066\090\116\118\073\110\082\061\061";"\090\115\118\118\090\089\079\114";"\090\116\113\118\080\116\082\061";"\109\105\086\053\088\082\061\061","\088\115\086\084\088\115\052\111","\106\116\052\071\080\116\107\061";"\120\071\070\097\065\078\043\102\120\070\061\061";"\109\105\086\049\065\109\076\118\106\116\052\071\080\116\107\061";"\090\089\052\084\065\116\086\049","\066\085\068\110\106\111\106\066\090\089\118\082\103\107\105\068";"\120\052\097\118\080\114\070\061","\109\105\086\102\080\089\076\097\103\119\061\061","\112\052\097\051\079\116\076\108\112\104\065\105\069\097\068\098\112\109\067\061";"\065\079\113\100\106\105\068\109\069\111\056\122\112\074\113\067","\112\055\079\083\079\114\076\107\079\098\110\121";"\065\085\113\105\088\070\061\061";"\080\116\079\084","\065\115\105\118\106\116\113\043","\065\053\102\114\066\066\113\117\110\109\097\083\112\055\114\111\069\116\090\061","\080\055\067\061";"\080\098\052\111\069\119\061\061";"\117\115\097\073\069\082\061\061";"\114\119\072\099\107\050\051\105\050\070\061\061";"\079\116\052\049\090\116\079\051\067\074\076\097\106\116\079\073\106\116\079\114\067\110\061\061","\098\112\054\072\051\114\068\079\102\087\108\106\113\047\056\061"}local function j(j)return o[j-(-53823-(-98177))]end for j,T in ipairs({{103954-103953;-595750+595802},{-573638-(-573639),880798+-880782};{-355669+355686,-689973+690025}})do while T[-1041679+1041680]<T[-698133+698135]do o[T[701819+-701818]],o[T[139882+-139880]],T[394941-394940],T[-938537-(-938539)]=o[T[970434+-970432]],o[T[-810375+810376]],T[-299336-(-299337)]+(321075+-321074),T[1024854+-1024852]-(-496374+496375)end end do local j=math.floor local T=string.char local X=table.insert local m={W=118420-118362,c=273723+-273679,Y=432287+-432249,D=-630223+630224;s=-140572-(-140626),X=-708602-(-708626);h=756465-756458;O=-140394-(-140415),n=-862211+862227;["\056"]=283842-283786;["\057"]=702172+-702141;A=-181798-(-181823);b=146362-146340,P=1000535+-1000508,g=-869553+869583;V=-16516+16577;k=-337956+337976;U=539210-539155;Q=309819+-309768,["\047"]=444962+-444920;S=919222+-919213,B=654701-654682,L=801737+-801720;["\054"]=-500377-(-500440);i=263031-262978;d=-43240+43255,p=-1914-(-1926),J=986414+-986410,o=-451520+451572,R=-539125-(-539173),q=-145522-(-145535);m=-237664-(-237687),I=128521+-128486;w=-576221-(-576221),["\050"]=-749817-(-749864),H=-508476-(-508536);["\051"]=-801765+801815;["\055"]=-325799-(-325802);K=-544250+544261,F=283716-283684;j=289804-289775,T=262101+-262055;["\053"]=996712+-996673,["\048"]=311529-311486;v=-788866-(-788899);e=189391-189329,a=-64464-(-64501),["\043"]=-311985-(-312025);["\052"]=683255+-683250;t=692723+-692717,y=341805-341756,u=-609900-(-609918);Z=-130091+130119;C=393284+-393276,r=926251-926215;l=410600-410590,G=80866+-80832;M=-605167+605226;f=906699+-906658;x=-597020+597034;["\049"]=-209192+209237;E=900976+-900950;z=-79997-(-80054);N=535332-535330}local E=string.len local M=o local n=string.sub local W=type local D=table.concat for o=825227-825226,#M,736673-736672 do local w=M[o]if W(w)=="\115\116\114\105\110\103"then local W=E(w)local Y={}local Q=-813324-(-813325)local s=620858+-620858 local k=369283+-369283 while Q<=W do local o=n(w,Q,Q)local E=m[o]if E then s=s+E*(405907+-405843)^((624165-624162)-k)k=k+(529168-529167)if k==760460+-760456 then k=-984611+984611 local o=j(s/(295866-230330))local m=j((s%(-470152+535688))/(582307-582051))local E=s%(-1018286-(-1018542))X(Y,T(o,m,E))s=779108+-779108 end elseif o=="\061"then X(Y,T(j(s/(893089+-827553))))if Q>=W or n(w,Q+(-759267+759268),Q+(-907198-(-907199)))~="\061"then X(Y,T(j((s%(318626+-253090))/(929524-929268))))end break end Q=Q+(-200708-(-200709))end M[o]=D(Y)end end end return(function(o,X,m,E,M,n,W,w,T,r,Y,D,y,N,z,k,c,v,s,P,Q)Q,D,c,y,s,v,k,w,Y,r,N,z,P,T=1003004-1003004,{},function(o,j)local X=s(j)local m=function(...)return T(o,{...},j,X)end return m end,function(o,j)local X=s(j)local m=function(m,E,M,n,W,D)return T(o,{m;E,M,n;W,D},j,X)end return m end,function(o)for j=-736232+736233,#o,254370-254369 do w[o[j]]=(-506378+506379)+w[o[j]]end if m then local T=m(true)local X=M(T)X[j(-362342-(-406699))],X[j(-696504+740905)],X[j(486275+-441884)]=o,k,function()return 810450+-2957144 end return T else return E({},{[j(-562050-(-606451))]=k;[j(144484+-100127)]=o,[j(-742232+786623)]=function()return-901057+-1245637 end})end end,function(o)w[o]=w[o]-(-560150-(-560151))if w[o]==362549-362549 then w[o],D[o]=nil,nil end end,function(o)local j,T=-732983-(-732984),o[-73030-(-73031)]while T do w[T],j=w[T]-(665453-665452),(-466317+466318)+j if 833783+-833783==w[T]then w[T],D[T]=nil,nil end T=o[j]end end,{},function()Q=(752659-752658)+Q w[Q]=-33070+33071 return Q end,function(o,j)local X=s(j)local m=function(m,E,M,n,W)return T(o,{m,E;M,n;W},j,X)end return m end,function(o,j)local X=s(j)local m=function(m,E,M)return T(o,{m;E,M},j,X)end return m end,function(o,j)local X=s(j)local m=function(m,E)return T(o,{m;E},j,X)end return m end,function(o,j)local X=s(j)local m=function()return T(o,{},j,X)end return m end,function(T,m,E,M)local L,C,w,t,u,V,g,W,S,e,h,G,p,A,c,B,b,l,U,x,d,O,s,i,k,H,K,J,a,f,F,Z,Q,R while T do if T<192700+8690138 then if T<5135342-(-559219)then if T<114956+3004329 then if T<2675730-842359 then if T<444415+1000966 then if T<94466+711193 then if T<-1015051+1590497 then T=7801263-(-816039)e=j(115989-71613)b=o[e]W=b else i=996596+-996496 C=Y()f=j(-312223+356589)D[C]=t W=o[f]p=-29568-(-29568)a=161962+-161961 f=j(-386939-(-431345))T=W[f]f=-967581+967582 S=-893974-(-894229)W=T(f,i)i=-618089-(-618089)L=-292112-(-292114)f=Y()D[f]=W T=D[V]W=T(i,S)i=Y()D[i]=W T=D[V]U=D[f]S=556266-556265 W=T(S,U)h=j(-453818+498191)S=Y()D[S]=W W=D[V]U=W(a,L)W=938150-938149 O=1002277+-992277 T=U==W L=j(224064-179681)U=Y()D[U]=T g=o[h]u=D[V]l={u(p,O)}h=g(X(l))W=j(511320+-466916)g=j(221120-176737)K=h..g a=L..K L=j(548865-504465)T=j(752792+-708431)T=H[T]T=T(H,W,a)a=Y()K=P(11561506-(-56542),{V,C,e;s,Q,F;U;a,f,S,i,b})D[a]=T W=o[L]L={W(K)}T={X(L)}L=T T=D[U]T=T and 6492883-509274 or 15142761-280664 end else F=396800+-396799 J=#R H=k(F,J)i=797015-797014 F=G(R,H)J=D[B]f=F-i C=V(f)J[F]=C F=nil H=nil T=9013234-(-615384)end else if T<1864467-384793 then w=D[E[977533-977532]]W=#w w=-603851-(-603851)T=W==w T=T and 3883859-339346 or-896241+10018107 else T=true T=6933448-(-59293)end end else if T<819954+1729824 then if T<-113543+2560423 then if T<3378185-953088 then T=9235579-(-258667)G=nil V=nil k=nil else W={}T=true D[E[61739+-61738]]=T T=o[j(960658+-916263)]end else T=D[E[652818+-652811]]T=T and 6154742-(-253568)or-107187+4486950 end else if T<2752692-(-80536)then T=e W=b T=b and 8042129-(-575173)or 1425409-1004494 else p=-178733-(-178734)D[Q]=K l=D[S]u=l+p h=L[u]g=x+h h=-107022+107278 T=g%h u=D[i]h=B+u u=734822+-734566 g=h%u B=g x=T T=7400002-684453 end end end else if T<-710977+5024282 then if T<3928558-96728 then if T<218945+3211054 then if T<3347973-179007 then T=true T=T and-506935+16762089 or 477141+6515600 else T=true s=j(745906-701510)k=Y()Q=Y()c=Y()D[Q]=T d=r(2234121-(-212094),{c})W=o[s]w=m s=j(280764+-236401)T=W[s]s=Y()D[s]=T T=z(-372305+6560853,{})D[k]=T T=false V=j(276477+-232077)D[c]=T G=o[V]V=G(d)T=V and 11591384-(-996825)or-193944+13269973 W=V end else s=-740339-(-740368)Q=D[E[-210655-(-210657)]]w=Q*s Q=29499437123791-(-388312)W=w+Q w=396365+35184371692467 T=W%w Q=-508040-(-508041)D[E[-24616-(-24618)]]=T T=11597271-30108 w=D[E[-528994-(-528997)]]W=w~=Q end else if T<3564422-(-621243)then e=e+x R=not B d=e<=b d=R and d R=e>=b R=B and R d=R or d R=5844968-7459 T=d and R d=-146780+2541883 T=T or d else e=24722499807212-(-558348)V=j(-931910+976284)G=o[V]W={}b=j(222883-178515)d=s(b,e)T=o[j(-591252+635642)]V=Q[d]b=7272917055164-(-382590)d=j(837523+-793153)c=G[V]V=s(d,b)d=j(780411-736023)b=-901978+11949381196054 G=Q[V]k=c[G]c=j(-658376+702743)V=s(d,b)c=k[c]G=Q[V]c=c(k,G)end end else if T<990472+3356969 then if T<209119+4114492 then A=x==B T=-938545+17620533 t=A else T=6584888-(-130661)D[Q]=W end else if T<3536079-(-839228)then g=T l=1015656+-1015655 u=L[l]l=false h=u==l K=h T=h and 10290034-(-321481)or-119638+8104061 else s=D[E[-911335-(-911344)]]Q=769175-769174 k=s T={}s=-277618-(-277619)w=T c=s T=14493795-525129 s=410531+-410531 G=c<s s=Q-c end end end end else if T<-72483+6819023 then if T<-688893+6871903 then if T<-145542+6122375 then if T<-64243+5966387 then if T<5808864-39521 then T=D[V]Z=-130086+130087 J=-715817-(-715823)A=T(Z,J)J=j(497236-452871)T=j(91247-46882)o[T]=A Z=o[J]J=175811+-175809 T=Z>J T=T and 550885+7978091 or 7063646-(-615905)else Z=j(830639-786243)d=e A=o[Z]Z=j(248404-204027)t=A[Z]A=t(w,d)t=D[E[538073+-538067]]Z=t()T=-86818+3948125 F=A+Z H=F+G F=263818+-263562 R=H%F Z=-92220-(-92221)F=s[Q]G=R d=nil A=G+Z t=k[A]H=F..t s[Q]=H end else W=9195658-(-138077)s=11645537-(-942821)Q=j(-78080+122440)w=Q^s T=W-w w=T W=j(-62769+107125)T=W/w W={T}T=o[j(738794+-694436)]end else if T<6253237-112181 then K=D[Q]T=K and 1001043+3371475 or 5286724-943533 W=K else T={}D[E[579165+-579163]]=T W=D[E[795057+-795054]]k=W c=889997+35184371198835 W=Q%c D[E[-1036193+1036197]]=W d=j(-804431+848827)V=-360544+360799 G=Q%V V=-385396+385398 c=G+V T=231563+3629744 D[E[-988534-(-988539)]]=c V=o[d]d=j(27705-(-16657))G=V[d]V=G(w)d=-130517+130518 G=j(-831532+875907)s[Q]=G b=V G=83150+-83065 e=-39108-(-39109)x=e e=344007-344007 B=x<e e=d-x end end else if T<998950+5467596 then if T<755670+5507497 then W=j(170539+-126159)w=j(-159384-(-203753))T=o[W]W=T(w)W={}T=o[j(451987+-407608)]else w=j(608707+-564327)T=o[w]Q=D[E[164717-164709]]s=947941-947941 w=T(Q,s)T=-430090+4809853 end else if T<-108847+6804582 then T=o[j(-963061-(-1007425))]W={}else S=v(S)i=v(i)f=v(f)U=v(U)L=nil T=-658589+8759883 C=v(C)a=v(a)end end end else if T<7526903-(-632962)then if T<-196995+7951572 then if T<7279742-(-298533)then if T<7631962-660087 then T=358685+9135561 else T=N(15409676-(-933503),{k})A={T()}W={X(A)}T=o[j(649443-605072)]end else J=j(-1177+45542)T=o[J]J=j(929919-885538)o[J]=T T=254829+8932255 end else if T<8717728-722259 then T=g W=K T=4772178-428987 else C=not J t=t+Z W=t<=A W=C and W C=t>=A C=J and C W=C or W C=1693642-912500 T=W and C W=213315+7952620 T=T or W end end else if T<7741636-(-806879)then if T<-369003+8836125 then A=D[Q]t=A T=A and 4998449-684554 or 15757844-(-924144)else Z=j(11733-(-32640))T=o[Z]C=j(-486240+530621)J=o[C]Z=T(J)T=j(-854740+899105)o[T]=Z T=389279+8797805 end else if T<8452566-(-304508)then x=314949+-314884 b=Y()Z=j(-774342+818715)H=N(6757877-850559,{})D[b]=W T=D[V]e=-979467-(-979470)W=T(e,x)T=-329987-(-329987)x=T e=Y()D[e]=W T=-134121-(-134121)R=j(236545+-192145)B=T W=o[R]R={W(H)}W=208200+-208198 T={X(R)}R=T T=R[W]W=j(-359737-(-404119))H=T T=o[W]F=D[s]A=o[Z]Z=A(H)A=j(-1020478+1064882)t=F(Z,A)F={t()}W=T(X(F))F=Y()D[F]=W t=D[e]W=937340+-937339 A=t t=450749-450748 Z=t t=-688540-(-688540)T=-140601+8241895 J=Z<t t=W-Z else Q=D[E[-584591+584594]]s=-638801+638802 w=Q~=s T=w and-930121+16696513 or 257949+11309214 end end end end end else if T<13150191-953826 then if T<10169565-(-210400)then if T<-182671+9622366 then if T<-507881+9684948 then if T<394569+8744104 then if T<8976451-(-107552)then s=D[E[925534+-925528]]Q=s==w W=Q T=463200+12643488 else s=j(780201+-735798)Q=o[s]s=j(-389928+434313)w=Q[s]s=D[E[743984-743983]]T=o[j(-733295-(-777650))]Q={w(s)}W={X(Q)}end else F=Y()J=z(-577578+2048406,{F;b,e,c})H={}U=j(91773-47416)C=Y()D[F]=H c=v(c)i={}x=nil H=Y()k=nil h=nil D[H]=J R=nil f=j(1019492-975103)J={}D[C]=J J=o[f]x=25421286784937-627052 a=D[C]L=j(-574627-(-619032))G=nil S={[U]=a;[L]=h}f=J(i,S)d=nil V=nil d=j(-335860-(-380259))Q=f J=y(11156215-529356,{C,F,B;b,e,H})F=v(F)C=v(C)V=o[d]B=v(B)H=v(H)e=v(e)e=j(-647265-(-691643))s=J b=v(b)b=s(e,x)d=Q[b]G=V[d]b=j(304632+-260245)e=-979559+16937432699190 d=s(b,e)V=Q[d]c=G[V]G=5.865683938016e+17 k=c==G T=k and-661081+4969839 or-757134+13345366 end else if T<8276944-(-956745)then T=11353937-921988 else H=nil Q=v(Q)B=nil b=v(b)F=v(F)V=v(V)s=v(s)x=nil R=nil V=j(-387098+431464)c=v(c)e=v(e)k=v(k)b=j(252042+-207646)Q=nil d=nil x={}s=nil G=nil G=j(-674002+718368)c=o[G]G=j(-308737-(-353129))k=c[G]c=Y()D[c]=k G=o[V]d=j(908221+-863818)V=j(-288901+333307)k=G[V]e=Y()B=Y()V=o[d]d=j(-340804+385189)G=V[d]d=o[b]R={}b=j(763419-719025)V=d[b]d=385699-385699 b=Y()D[b]=d H=253346+-253345 d=928299-928297 D[e]=d d={}T=-372780+16806356 F=129140+-128884 D[B]=x x=-670269-(-670269)J=F F=-117702+117703 C=F F=581866-581866 f=C<F F=H-C end end else if T<-851822+10568750 then if T<9692942-188469 then if T<-338508+9817194 then w=j(-185128+229509)W=j(408595+-364230)T=o[W]W=o[w]w=j(443929+-399548)o[w]=T w=j(597149-552784)T=-278551+11647756 o[w]=W w=D[E[-249566+249567]]Q=w()else W={Q}T=o[j(-265837+310223)]end else F=#R J=-762692-(-762692)H=F==J T=H and 720935+8425914 or 783604+41021 end else if T<9349196-(-613173)then d=j(106311+-61911)W=j(456944+-412562)k=j(655503-611130)T=o[W]w=D[E[-902477+902481]]s=o[k]V=o[d]b=z(-441425+10818014,{})d={V(b)}V=547916+-547914 G={X(d)}c=G[V]k=s(c)s=j(285315+-240911)Q=w(k,s)w={Q()}W=T(X(w))Q=D[E[146964-146959]]T=Q and 8438475-(-579268)or 190850+12915838 w=W W=Q else W=-279403+9097439 s=803242+6761944 Q=j(-167654-(-212038))w=Q^s T=W-w W=j(19533-(-24860))w=T T=W/w W={T}T=o[j(698536+-654139)]end end end else if T<11727933-314976 then if T<11114852-488316 then if T<10198167-(-357586)then if T<797433+9626225 then T=o[j(349708+-305349)]W={}else T=true T=T and 5925661-180466 or 9649850-(-766035)end else T=7982108-(-2315)l=-137460+137462 u=L[l]l=D[a]h=u==l K=h end else if T<10968165-170320 then T=D[E[45728-45727]]Q=m[313838+-313836]s=T w=m[-594033-(-594034)]T=s[Q]T=T and 98142+6735313 or 6938572-757423 else T=true T=T and 9589151-139019 or 7028101-358592 end end else if T<12404123-668776 then if T<12420548-832536 then Q=D[E[340858+-340855]]s=391447-391337 w=Q*s Q=135545-135288 W=w%Q D[E[22003+-22000]]=W T=9243060-413447 else c=-227560+227562 k=-462013-(-462014)Q=D[E[-455447+455448]]s=Q(k,c)Q=824202+-824201 w=s==Q W=w T=w and 15494744-929148 or 12940119-940516 end else if T<-266249+12171214 then T=134003+2657081 R=j(991148-946745)B=o[R]R=j(115731-71355)x=B[R]b=x else Q=D[E[379219+-379217]]T=14850193-284597 s=D[E[-375238-(-375241)]]w=Q==s W=w end end end end else if T<32235+14366406 then if T<-213306+13308733 then if T<13614038-1025809 then if T<-379897+12959953 then if T<-407947+12729912 then T=598287+2253755 h=166382+-166381 g=L[h]K=g else H=F i=H T=15966157-(-467419)R[H]=i H=nil end else G=D[c]T=14083760-1007731 W=G end else if T<13270280-644221 then s=nil W={}Q=nil T=o[j(-423723+468121)]else d=j(195833-151430)G=W V=j(706549+-662183)W=o[V]V=j(-75982+120388)T=W[V]V=Y()B=j(-740426+784829)D[V]=T W=o[d]d=j(488055+-443653)T=W[d]d=T x=o[B]b=x e=T T=x and 11752801-(-60537)or 2596900-(-194184)end end else if T<84738+14098303 then if T<17936+13440235 then T=1950247-(-502558)w=nil D[E[324801+-324796]]=W else V=not G s=s+c Q=s<=k Q=V and Q V=s>=k V=G and V Q=V or Q V=-582516+14907895 T=Q and V Q=14220645-(-288960)T=T or Q end else if T<-535557+14782092 then T=8227934-(-1032418)else d=-347013+347013 b=-930924+931179 Q=s T=D[E[322862-322861]]V=T(d,b)T=210330+13758336 w[Q]=V Q=nil end end end else if T<15839673-53217 then if T<15343551-382563 then if T<15366456-554648 then if T<15292488-744179 then T=D[E[940194-940184]]Q=D[E[-80454-(-80465)]]w[T]=Q T=D[E[463398+-463386]]Q={T(w)}W={X(Q)}T=o[j(529004+-484632)]else T=W and-201007+9981971 or 3053105-600300 end else g=D[Q]T=g and 12642645-340421 or-532408+3384450 K=g end else if T<14600613-(-835739)then J=-137846+137846 F=#R H=F==J T=475684+348941 else s=696364+-696332 b=-79656+79658 Q=D[E[777533-777530]]w=Q%s k=D[E[753388-753384]]x=708610+-708597 V=D[E[310370+-310368]]H=D[E[-394857-(-394860)]]R=H-w H=-926670-(-926702)B=R/H e=x-B d=b^e G=V/d c=k(G)T=8790764-(-331102)k=4294368887-(-598409)d=-704725+704726 s=c%k c=665594+-665592 k=c^w Q=s/k k=D[E[-266834+266838]]V=Q%d d=4295219590-252294 G=V*d V=-270012-(-335548)c=k(G)k=D[E[246220-246216]]w=nil G=k(Q)x=-728810+729066 s=c+G c=-385021-(-450557)k=s%c G=s-k c=G/V V=-122333+122589 G=k%V b=320461+-320205 d=k-G V=d/b b=-234912-(-235168)k=nil d=c%b e=c-d s=nil b=e/x c=nil e={G,V,d;b}Q=nil d=nil D[E[451739-451738]]=e V=nil b=nil G=nil end end else if T<15673079-(-740193)then if T<15343956-(-950128)then T=983227+9448722 else T=10788087-(-581118)end else if T<-1008478+17689471 then F=F+C H=F<=J i=not f H=i and H i=F>=J i=f and i H=i or H i=-673188+13012052 T=H and i H=14965648-(-313038)T=T or H else D[Q]=t T=D[Q]T=T and 614046+13616104 or 596973-(-908372)end end end end end end end T=#M return X(W)end return(c(263904+3076212,{}))(X(W))end)(getfenv and getfenv()or _ENV,unpack or table[j(-242826-(-287202))],newproxy,setmetatable,getmetatable,select,{...})end)(...)

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
                    if humanoid then 
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        
                        if flickEnabled then
                            local wallNormal = hit.Normal
                            local newCFrame = CFrame.lookAt(root.Position, root.Position + wallNormal)
                            root.CFrame = newCFrame
                        end
                    end
                    task.wait(0.1)
                    InfiniteJumpEnabled = true
                end
            end))
        end
    end)
    
    wallhopSection:AddToggle("Enable Wallhop Flick", function(enabled) 
        flickEnabled = enabled 
    end)
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
    local enSection = shared.AddSection("Emote Noclip")

    local selEmote = nil
    local emotes = {
        ["Moonwalk"] = "79127989560307",
        ["Yungblud"] = "15610015346",
        ["Bouncy Twirl"] = "14353423348",
        ["Flex Walk"] = "15506506103"
    }

    local EmoteNoclipMaid = nil
    RootMaid:GiveTask(function()
        if EmoteNoclipMaid then
            EmoteNoclipMaid:DoCleaning()
        end
    end)

    local noclipConn = nil
    local Clip = true
    local disableTimer = nil
    local bindableButtonEnabled = false
    local bindableButtonSize = 0.11

    -- NEW: Adjustable noclip duration
    local noclipDuration = 2

    local function NoclipLoop()
        if Clip == false and LocalPlayer.Character ~= nil then
            for _, child in pairs(LocalPlayer.Character:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide == true then
                    child.CanCollide = false
                end
            end
        end
    end

    local function enableNoclip()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end

        Clip = false
        noclipConn = Services.RunService.Stepped:Connect(NoclipLoop)
    end

    local function disableNoclip()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end

        Clip = true

        if not LocalPlayer.Character then
            return
        end

        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    local function playEmoteWithNoclip(emoteId)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not humanoid then
            return
        end

        if disableTimer then
            spawn(function()
                wait(disableTimer)
                disableNoclip()
            end)
        end

        disableNoclip()

        local track
        local ok, result = pcall(function()
            return humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
        end)

        if ok and result then
            track = result
        else
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. emoteId

            track = humanoid:LoadAnimation(animation)
            track:Play()
        end

        enableNoclip()

        -- UPDATED: Uses slider value
        disableTimer = noclipDuration

        spawn(function()
            wait(noclipDuration)

            if disableTimer then
                disableNoclip()
                disableTimer = nil
            end
        end)
    end

    local function triggerEmote()
        if not selEmote then
            return
        end

        playEmoteWithNoclip(selEmote)
    end

    local function updateBindableButtonSize()
        local btn = BindableButtons.Buttons["en_bind"]

        if btn then
            local screen = workspace.CurrentCamera.ViewportSize

            btn.Size = __UD2(
                bindableButtonSize * (screen.Y / screen.X),
                0,
                bindableButtonSize,
                0
            )
        end
    end

    local selectEmoteDropdown = enSection:AddDropdown(
        "Select Emote",
        {"Moonwalk", "Yungblud", "Bouncy Twirl", "Flex Walk", "Custom"},
        function(s)
            if s ~= "Custom" then
                selEmote = emotes[s]
            else
                selEmote = nil
            end
        end
    )

    enSection:AddToggle("Enable EN Button", function(enabled)
        bindableButtonEnabled = enabled

        if enabled then
            BindableButtons.AddBButton("en_bind", "EN", triggerEmote)
            updateBindableButtonSize()
        else
            BindableButtons.DeleteBButton("en_bind")
        end
    end)

    enSection:AddSlider("EN Button Size", 5, 25, 11, function(value)
        bindableButtonSize = value / 100
        updateBindableButtonSize()
    end)

    -- NEW: Noclip duration slider
    enSection:AddSlider("Noclip Duration", 1, 15, 2, function(value)
        noclipDuration = value
    end)

    enSection:AddTextBox("Custom Emote ID", function(t)
        if t ~= "" then
            selEmote = t
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

local ggAuraSection = shared.AddSection("Grab Gun Aura")
local ggAuraEnabled, autoGGEnabled = false, false
local ggButtonSize = 0.11
local autoGGMaid = Maid.new()
local gunAuraConnection = nil

RootMaid:GiveTask(autoGGMaid)

-- Gun Aura (touch method)
local function touch(a, b)
    firetouchinterest(a, b, 0)
    firetouchinterest(a, b, 1)
end

local function bringGun()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local gunDrop = workspace:FindFirstChild("GunDrop", true)
    
    if rootPart and gunDrop then
        touch(rootPart, gunDrop)
    end
end

-- Teleport fallback method (SILENT - no notifications)
local function grabGunTeleport()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local ggDrop = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            ggDrop = obj
            break
        end
    end
    
    if not ggDrop then return false end
    
    local savedPos = root.CFrame
    root.CFrame = CFrame.new(ggDrop.Position + Vector3.new(0, 3, 0))
    task.wait(0.3)
    root.CFrame = savedPos
    return true
end

-- Check if player has gun in inventory
local function hasGunInInventory()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    
    return false
end

-- Check if a gun drop exists on the map (SILENT - no notifications)
local function gunDropExists()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            return true
        end
    end
    return false
end

-- Main grab function with aura + teleport fallback (SILENT - no notifications)
local function grabGunWithFallback(silent)
    -- Don't even try if there's no gun drop on the map
    if not gunDropExists() then
        return false
    end
    
    -- Don't try if we already have a gun
    if hasGunInInventory() then
        return true
    end
    
    -- First try aura (touch method)
    bringGun()
    task.wait(0.5)
    
    -- Check if gun was obtained
    if not hasGunInInventory() then
        grabGunTeleport()
        task.wait(0.5)
    end
    
    -- Only show notification if not silent and we actually got the gun
    if not silent and hasGunInInventory() then
        Notify("Grab Gun", "Gun grabbed successfully!", 2)
    end
    
    return hasGunInInventory()
end

-- Toggle gun aura
local function toggleGunAura(state)
    ggAuraEnabled = state
    if state then
        if gunAuraConnection then return end
        gunAuraConnection = Services.RunService.Heartbeat:Connect(function()
            if ggAuraEnabled and gunDropExists() and not hasGunInInventory() then
                bringGun()
            end
        end)
    else
        if gunAuraConnection then
            gunAuraConnection:Disconnect()
            gunAuraConnection = nil
        end
    end
end

ggAuraSection:AddToggle("Enable Gun Aura", function(enabled)
    toggleGunAura(enabled)
end)

ggAuraSection:AddToggle("Enable Auto Grab Gun", function(enabled)
    autoGGEnabled = enabled
    autoGGMaid:DoCleaning()
    
    if enabled then
        task.spawn(function()
            while autoGGEnabled do
                -- Only attempt if gun drop exists AND we don't have a gun
                if LocalPlayer.Character and gunDropExists() and not hasGunInInventory() then
                    grabGunWithFallback(true) -- Silent mode, no notifications
                end
                task.wait(3)
            end
        end)
    end
end)

ggAuraSection:AddToggle("Enable GG Button", function(enabled)
    if enabled then
        BindableButtons.AddBButton("ggaura_bind", "GG", function()
            grabGunWithFallback(false) -- Show notification only when button pressed
        end)
        local btn = BindableButtons.Buttons["ggaura_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(ggButtonSize * (screen.Y / screen.X), 0, ggButtonSize, 0)
        end
    else
        BindableButtons.DeleteBButton("ggaura_bind")
    end
end)

ggAuraSection:AddSlider("GG Button Size", 5, 25, 11, function(value)
    ggButtonSize = value / 100
    local btn = BindableButtons.Buttons["ggaura_bind"]
    if btn then
        local screen = workspace.CurrentCamera.ViewportSize
        btn.Size = __UD2(ggButtonSize * (screen.Y / screen.X), 0, ggButtonSize, 0)
    end
end)

ggAuraSection:AddButton("Grab Gun (Aura + Fallback)", function()
    grabGunWithFallback(false) -- Show notification when button pressed
end)

local ggKeybind = Services.UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.G then 
        grabGunWithFallback(false) -- Show notification when keybind pressed
    end
end)
RootMaid:GiveTask(ggKeybind)

ggAuraSection:AddLabel("Auto Grab runs silently - only shows notifications when you press the button")

local giveGunSection = shared.AddSection("Give Gun")

local giveGunEnabled, autoGiveGunEnabled = false, false
local selectedPlayer = nil
local autoGiveMaid = Maid.new()
local giveGunButtonSize = 0.11
local noclipEnabled = false
local noclipConnection = nil
local teleportDistance = 5
local dynamicTracking = false
local trackingConnection = nil
local isTrackingActive = false

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

local function enableNoclip()
    if noclipEnabled then return end
    
    noclipEnabled = true
    noclipConnection = Services.RunService.Stepped:Connect(function()
        for _, player in pairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function disableNoclip()
    if not noclipEnabled then return end
    
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    disableNoclip()
    stopDynamicTracking()
end)

local function getPlayerMoveDirection(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return Vector3.new() end
    
    local humanoid = targetChar:FindFirstChild("Humanoid")
    if not humanoid then return Vector3.new() end
    
    local moveDirection = humanoid.MoveDirection
    
    if moveDirection.Magnitude > 0.1 then
        return moveDirection.Unit
    end
    
    return Vector3.new()
end

local function startDynamicTracking(targetPlayer)
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    isTrackingActive = true
    
    trackingConnection = Services.RunService.Stepped:Connect(function()
        if not isTrackingActive or not giveGunEnabled or not selectedPlayer then
            if trackingConnection then
                trackingConnection:Disconnect()
                trackingConnection = nil
            end
            return
        end
        
        local targetChar = targetPlayer.Character
        if not targetChar then return end
        
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        
        local moveDirection = getPlayerMoveDirection(targetPlayer)
        local teleportPosition
        
        if moveDirection.Magnitude > 0 then
            teleportPosition = targetRoot.CFrame + (moveDirection * teleportDistance) + Vector3.new(0, 3, 0)
        else
            teleportPosition = targetRoot.CFrame + Vector3.new(0, 3, 0)
        end
        
        root.CFrame = teleportPosition
    end)
end

local function stopDynamicTracking()
    isTrackingActive = false
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end
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
    
    enableNoclip()
    
    if dynamicTracking then
        local moveDirection = getPlayerMoveDirection(targetPlayer)
        local initialPosition
        
        if moveDirection.Magnitude > 0 then
            initialPosition = targetRoot.CFrame + (moveDirection * teleportDistance) + Vector3.new(0, 3, 0)
        else
            initialPosition = targetRoot.CFrame + Vector3.new(0, 3, 0)
        end
        
        root.CFrame = initialPosition
        
        startDynamicTracking(targetPlayer)
        
        task.wait(0.5)
    else
        local moveDirection = getPlayerMoveDirection(targetPlayer)
        local teleportPosition
        
        if moveDirection.Magnitude > 0 then
            teleportPosition = targetRoot.CFrame + (moveDirection * teleportDistance) + Vector3.new(0, 3, 0)
        else
            teleportPosition = targetRoot.CFrame + Vector3.new(0, 3, 0)
        end
        
        root.CFrame = teleportPosition
        task.wait(0.3)
    end
    
    LocalPlayer.Character:BreakJoints()
    stopDynamicTracking()
end

local function executeGiveGun()
    if giveGunEnabled and selectedPlayer then
        giveGunToPlayer(selectedPlayer)
    end
end

giveGunSection:AddPlayerDropdown("Select Player", function(player)
    if player then
        selectedPlayer = player
    else
        selectedPlayer = nil
    end
end)

giveGunSection:AddSlider("Teleport Distance (Studs)", 1, 20, teleportDistance, function(value)
    teleportDistance = value
    Notify("Give Gun", "Teleport distance set to " .. value .. " studs", 2)
end)

giveGunSection:AddToggle("Dynamic Tracking (Stay in front)", function(enabled)
    dynamicTracking = enabled
    Notify("Give Gun", "Dynamic tracking: " .. (enabled and "ON (will activate when you give gun)" or "OFF"), 2)
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
        stopDynamicTracking()
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

local keybind = giveGunSection:AddKeybind("Give Gun Keybind", "G", function()
    if giveGunEnabled and selectedPlayer then
        executeGiveGun()
    end
end)

giveGunSection:AddLabel("Must enable auto grab gun for auto give gun to work")

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
local trueAntiFlingConnection, trueAntiAfkConnection, trueAntiVoidConnection
local originalDestroyHeight = workspace.FallenPartsDestroyHeight

true_antis_section:AddToggle("Enable IY Anti Fling", function(bool)
    if trueAntiFlingConnection then
        trueAntiFlingConnection:Disconnect()
        trueAntiFlingConnection = nil
    end
    
    if bool then
        trueAntiFlingConnection = Services.RunService.Stepped:Connect(function()
            for _, player in ipairs(Services.Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
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

true_antis_section:AddToggle("Enable True Anti Void", function(bool)
    if trueAntiVoidConnection then
        trueAntiVoidConnection:Disconnect()
        trueAntiVoidConnection = nil
    end
    
    if bool then
        workspace.FallenPartsDestroyHeight = 0/0
        
        trueAntiVoidConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            workspace.FallenPartsDestroyHeight = 0/0
        end)
    else
        workspace.FallenPartsDestroyHeight = originalDestroyHeight
    end
end)

local creditsSection = shared.AddSection("Credits")
creditsSection:AddParagraph("@lzzzx", "Made this plugin, if you have requests feel free to ask.")

shared.Notify("ATAOs ON TOP NIGGA", 5)

RootMaid:GiveTasks(
    function() if trueAntiFlingConnection then trueAntiFlingConnection:Disconnect() end end,
    function() if trueAntiAfkConnection then trueAntiAfkConnection:Disconnect() end end,
    function() if trueAntiVoidConnection then trueAntiVoidConnection:Disconnect() end end,
    function() workspace.FallenPartsDestroyHeight = originalDestroyHeight end,
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
