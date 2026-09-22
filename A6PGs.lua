--[[local wjskea = odh_shared_plugins
local wjjjw = wjskea.game_name

if wjjjw ~= "Murder Mystery 2" then
    return
end]]

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
    table.insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)

    for i = 1, select("#", ...) do
        local item = (select(i, ...))
        if item ~= nil then
            self:GiveTask(item)
        end
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

    local tasks = self._tasks
    self._tasks = {}
    for _, item in tasks do
        self:_cleanupTask(item)
    end
end

function Maid:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self:DoCleaning()
end

local RootMaid = Maid.new()

local shared = odh_shared_plugins
task.spawn(function()
    shared.load_from_github_url("/aux0on/CrashHandler/refs/heads/main/Prevention.lua")
end)

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

local muteButtonSounds = false
local lockBindableButtons = false

local bpSaveFile = "ATAOs_BP.json"
local savedButtonPositions = {}

if isfile and readfile and isfile(bpSaveFile) then
    local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(bpSaveFile)) end)
    if ok and type(data) == "table" then savedButtonPositions = data end
end

local function saveButtonPositions()
    if writefile then
        local dataToSave = {}
        for id, btn in (BindableButtons and BindableButtons.Buttons or {}) do
            if btn and btn.Parent then
                dataToSave[id] = {
                    xs = btn.Position.X.Scale,
                    xo = btn.Position.X.Offset,
                    ys = btn.Position.Y.Scale,
                    yo = btn.Position.Y.Offset
                }
            end
        end
        writefile(bpSaveFile, Services.HttpService:JSONEncode(dataToSave))
    end
end

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in (BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
end

BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

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

            if not lockBindableButtons then
                dragging, dragStart, startPos = true, input.Position, gui.Position
                hasMoved = false
            end

            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    if not lockBindableButtons then
                        dragging = false
                        if hasMoved then
                            saveButtonPositions()
                        end
                    end
                    if not hasMoved then
                        bind_safecallback(clickFunc)
                    end
                    rel:Disconnect()
                end
            end)
        end
    end))

    maid:GiveTask(gui.InputChanged:Connect(function(input)
        if lockBindableButtons then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:GiveTask(__UIS.InputChanged:Connect(function(input)
        if lockBindableButtons then return end
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

local strokeSpinners = setmetatable({}, {__mode = "k"})
local strokeSpinnerConn = nil

local function strokeSpinStep()
    local any = false
    for stroke, rot in strokeSpinners do
        any = true
        rot = (rot + 1) % 360
        strokeSpinners[stroke] = rot
        stroke.Rotation = rot
    end
    if not any and strokeSpinnerConn then
        strokeSpinnerConn:Disconnect()
        strokeSpinnerConn = nil
    end
end

local function addStrokeSpinner(stroke)
    strokeSpinners[stroke] = 0
    if not strokeSpinnerConn then
        strokeSpinnerConn = __RS.RenderStepped:Connect(strokeSpinStep)
    end
end

local function removeStrokeSpinner(stroke)
    strokeSpinners[stroke] = nil
end

RootMaid:GiveTask(function()
    if strokeSpinnerConn then
        strokeSpinnerConn:Disconnect()
        strokeSpinnerConn = nil
    end
    table.clear(strokeSpinners)
end)

function BindableButtons.AddBButton(id, text, clickFunc)
    if BindableButtons.Buttons[id] then return end

    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)

    local savedPos = savedButtonPositions[id]
    if savedPos then
        ImageButton.Position = __UD2(savedPos.xs or 0.1, savedPos.xo or 0, savedPos.ys or 0.9, savedPos.yo or 0)
    else
        local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
        local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))
        ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    end

    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = __SHAPES[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel")
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
    TextLabel.Parent = ImageButton

    local Aspect = Instance.new("UIAspectRatioConstraint")
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize
    Aspect.Parent = ImageButton

    local Stroke = Instance.new("UIGradient")
    Stroke.Name = "@Stroke"
    Stroke.Color = __NORMAL_COLOR
    Stroke.Parent = ImageButton

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton

    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = __UD(1, 0)
    rippleCorner.Parent = ripple

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)

    addStrokeSpinner(Stroke)
    buttonMaid:GiveTask(function() removeStrokeSpinner(Stroke) end)

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
    if type(text) ~= "string" then
        duration = tonumber(text) or duration
        text = title
        title = "ATAOs"
    end
    Services.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 2})
end

local function RefreshDropdownItems(dropdown, items)
    if type(dropdown) ~= "table" then return end
    if type(dropdown.ChangeItems) == "function" then
        dropdown:ChangeItems(items)
    elseif type(dropdown.Change) == "function" then
        dropdown.Change(items)
    end
end

local hiddenGui = Instance.new("ScreenGui")
hiddenGui.Name = "HiddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local ataos = shared.CreateTab("ATAOs", "/aux0on/AllTheAdd-OnsIcon/refs/heads/main/Untitled163_20260918192358")

local aboutSection = ataos:AddSection("About", "Info")
aboutSection:AddParagraph("ATAOs MM2", "is the version you are using.")

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

aboutSection:AddToggle("Lock Bindable Buttons", function(bool)
    lockBindableButtons = bool
end)

local serverSection = ataos:AddSection("Server Options", "MM2")
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
        for _, server in (servers.data) do
            if server.id ~= JobId and server.playing < server.maxPlayers then
                table.insert(available, server)
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
            for _, server in (response.data) do
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
            for _, server in (result.data) do
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
local radioSection = ataos:AddSection("Radio Abuse", "MM2")
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
    for _, song in (savedSongs) do
        table.insert(names, song.name or song.id)
    end
    return names
end

local lastSelectedSong
local songDropdown = radioSection:AddDropdown("Saved Songs", getSongNames(), function(selectedName)
    for _, song in (savedSongs) do
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
        table.insert(savedSongs, {name = name, id = id})
        saveSongs()
        RefreshDropdownItems(songDropdown, getSongNames())
        Notify("Added: "..name, 2)
    else
        Notify("Invalid audio ID!", 2)
    end
end)

radioSection:AddButton("Delete Selected Audio", function()
    if lastSelectedSong then
        for i, song in (savedSongs) do
            if song.name == lastSelectedSong.name then
                table.remove(savedSongs, i)
                saveSongs()
                RefreshDropdownItems(songDropdown, getSongNames())
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

local speedGlitchSection = ataos:AddSection("Auto Speedglitch", "MM2")
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

        local isTouchOnly = Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
        if isTouchOnly then
            SpeedGlitchMaid:GiveTask(Services.RunService.Stepped:Connect(function()
                if not asgEnabled or not asgChar or not asgHum or not asgRoot then return end

                if isInAir then
                    if asgHorizontal then
                        asgHum.WalkSpeed = (math.abs(asgHum.MoveDirection:Dot(asgRoot.CFrame.RightVector)) > 0.5) and (defaultSpeed + asgValue) or defaultSpeed
                    else
                        asgHum.WalkSpeed = defaultSpeed + asgValue
                    end
                else
                    asgHum.WalkSpeed = defaultSpeed
                end
            end))
        end
    end
end)

RootMaid:GiveTask(function() if SpeedGlitchMaid then SpeedGlitchMaid:Destroy() end end)
speedGlitchSection:AddToggle("Sideways Only", function(e) asgHorizontal = e end)
speedGlitchSection:AddSlider("Speed (0-255)", 0, 255, 0, function(v) asgValue = v end)

do
    local mapVoterSection = ataos:AddSection("Map Voter", "MM2")
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

local whitelistSection = ataos:AddSection("Kill All", "MM2")
local whitelist = {}

whitelistSection:AddLabel("Ignores Whitelisted Players")
whitelistSection:AddPlayerDropdown("Whitelist Player", function(p)
    if not table.find(whitelist, p.UserId) then
        table.insert(whitelist, p.UserId)
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
    for _, p in (Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and not table.find(whitelist, p.UserId) and p.Character then
            local upperTorso = p.Character:FindFirstChild("UpperTorso")
            if upperTorso then table.insert(targets, upperTorso) end
        end
    end

    for i = 1, 6 do
        for _, upperTorso in (targets) do
            handleTouched:FireServer(upperTorso)
        end
        if i < 6 then task.wait(1) end
    end
end)

local blueAuraSection = ataos:AddSection("Blue Aura", "MM2")

blueAuraSection:AddLabel("kill them with your absolute crushing aura")

local blueAuraEnabled = false
local blueAuraStuds = 10
local whitelist = {}
local auraMaid = Maid.new()

local fakeMurderEnabled = false
local selectedFakeMurder = nil

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

local function checkAura()
    if not blueAuraEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local handleTouched = getHandleTouchedEvent()
    if not handleTouched then return end

    local rootPos = root.Position

    for _, player in Services.Players:GetPlayers() do
        if player ~= LocalPlayer and not table.find(whitelist, player.UserId) then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (rootPos - targetRoot.Position).Magnitude
                    if dist <= blueAuraStuds then
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

local function checkFakeMurderAura()
    if not fakeMurderEnabled then return end
    if not selectedFakeMurder then return end

    local fakeMurderChar = selectedFakeMurder.Character
    if not fakeMurderChar then return end

    local fakeMurderRoot = fakeMurderChar:FindFirstChild("HumanoidRootPart")
    if not fakeMurderRoot then return end

    local handleTouched = getHandleTouchedEvent()
    if not handleTouched then return end

    local fakeMurderPos = fakeMurderRoot.Position

    for _, player in Services.Players:GetPlayers() do
        if player ~= LocalPlayer and player ~= selectedFakeMurder and not table.find(whitelist, player.UserId) then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (fakeMurderPos - targetRoot.Position).Magnitude
                    if dist <= blueAuraStuds then
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

blueAuraSection:AddToggle("Enable Fake Murderer", function(enabled)
    fakeMurderEnabled = enabled
    auraMaid:DoCleaning()

    if enabled then
        task.spawn(function()
            while fakeMurderEnabled do
                checkFakeMurderAura()
                task.wait(0.5)
            end
        end)
    end
end)

blueAuraSection:AddPlayerDropdown("Select Fake Murderer", function(player)
    selectedFakeMurder = player
end)

blueAuraSection:AddSlider("Blue Aura Studs", 5, 50, 10, function(value)
    blueAuraStuds = value
end)

blueAuraSection:AddPlayerDropdown("Whitelist Player", function(player)
    if not table.find(whitelist, player.UserId) then
        table.insert(whitelist, player.UserId)
        Notify(player.Name .. " whitelisted.", 2)
    end
end)

blueAuraSection:AddButton("Clear Whitelist", function()
    whitelist = {}
    Notify("Whitelist cleared.", 2)
end)

do
    local duelSection = ataos:AddSection("Dual Effect", "MM2")
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
        "Nightlife26",
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
    local tradeSection = ataos:AddSection("Disable Trading", "MM2")
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
    local trollSection = ataos:AddSection("Troll (FE)", "MM2")
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
            for _, t in (h:GetPlayingAnimationTracks()) do t:Stop() end

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
    local rtxSection = ataos:AddSection("RTX", "MM2")
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

        for name, data in (effects) do
            if not rtx[name] then
                rtx[name] = Instance.new(data.Class)
                for prop, val in (data.Properties) do
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

            for _, v in (rtx) do if v then v.Enabled = true end end
        else
            rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
        end
    end)
end

do
    local lsSection = ataos:AddSection("Legit Speedglitch", "MM2")
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
                if not emOn then return end

                local char = LocalPlayer.Character
                if not char then return end
                local h = char:FindFirstChild("Humanoid")
                local r = char:FindFirstChild("HumanoidRootPart")
                if not h or not r then return end

                local state = h:GetState()
                local lsAir = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
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
    local hlSection = ataos:AddSection("FE Headless", "MM2")
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

    for i, cfg in (hlConfigs) do
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

    RootMaid:GiveTask(LocalPlayer.CharacterRemoving:Connect(function()
        for _, cfg in hlConfigs do
            stopHl(cfg)
            if cfg.freeze then cfg.freeze:Disconnect() cfg.freeze = nil end
        end
    end))

    RootMaid:GiveTask(function()
        for _, cfg in hlConfigs do
            stopHl(cfg)
            if cfg.freeze then cfg.freeze:Disconnect() cfg.freeze = nil end
        end
    end)

    RootMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        for _, cfg in hlConfigs do
            if cfg.on then enableHl(cfg) end
        end
    end))
end

do
    local flingSection = ataos:AddSection("Fling", "MM2")
    local flingSelPlr, flingActive = nil, true
    local selectedPlayers = {}
    local whitelist = {}
    local flingButtonSize = 0.11
    local clickFlingEnabled = false
    local flingAuraEnabled = false
    local flingAuraStuds = 15
    local maids = {autoSheriff=nil, autoMurderer=nil, loopPlr=nil, loopAll=nil, clickFling=nil, flingAura=nil}
    local buttonToggles = {Sheriff=false, Murderer=false, Player=false}

    local ReplicatedStorage = Services.ReplicatedStorage
    local Players = Services.Players
    local UserInputService = Services.UserInputService

    RootMaid:GiveTask(function()
        for _, m in maids do if m then m:Destroy() end end
    end)

    local function isWhitelisted(player)
        return whitelist[player.UserId] == true
    end

    local function isPlayerSelected(player)
        for _, selected in selectedPlayers do
            if selected.UserId == player.UserId then
                return true
            end
        end
        return false
    end

    local playerDataRemote = nil
    local function getPlayerDataRemote()
        local cached = playerDataRemote
        if cached and cached.Parent then return cached end
        local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if remote and remote:IsA("RemoteFunction") then
            playerDataRemote = remote
            return remote
        end
        playerDataRemote = nil
        return nil
    end

    local function findRoleHolder(role)
        local success, roleData = pcall(function()
            local remote = getPlayerDataRemote()
            if remote then
                return remote:InvokeServer()
            end
        end)
        if success and roleData then
            for playerName, data in roleData do
                if data.Role == role and not data.Killed and not data.Dead then
                    local p = Players:FindFirstChild(playerName)
                    if p and not isWhitelisted(p) then return p end
                end
            end
        end
        return nil
    end

    local function findSheriff()
        return findRoleHolder("Sheriff")
    end

    local function findMurderer()
        return findRoleHolder("Murderer")
    end

    local GUN_NAME_KEYWORDS = {"gun", "pistol", "revolver", "shotgun", "rifle", "weapon"}

    local function nameLooksLikeGun(name)
        local lowered = name:lower()
        for _, keyword in GUN_NAME_KEYWORDS do
            if lowered:find(keyword, 1, true) then return true end
        end
        return false
    end

    local function hasGun(player)
        local character = player.Character
        if not character then return false end

        for _, tool in player.Backpack:GetChildren() do
            if tool:IsA("Tool") and nameLooksLikeGun(tool.Name) then
                return true
            end
        end

        for _, tool in character:GetChildren() do
            if tool:IsA("Tool") and nameLooksLikeGun(tool.Name) then
                return true
            end
        end

        return false
    end

    local function findSheriffWithFallback()
        local sheriff = findSheriff()
        if sheriff then return sheriff end

        for _, player in (Players:GetPlayers()) do
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

        local genv = getgenv()

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
            genv.OldPos = RootPart.CFrame
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
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        BV.Parent = RootPart

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

        local RECOVER_OFFSET = CFrame.new(0, .5, 0)
        local ZERO_VELOCITY = Vector3.new()

        repeat
            local oldPos = genv.OldPos
            if Character and Humanoid and RootPart and oldPos then
                local recoverCFrame = oldPos * RECOVER_OFFSET
                RootPart.CFrame = recoverCFrame
                Character:SetPrimaryPartCFrame(recoverCFrame)
                Humanoid:ChangeState("GettingUp")
                for _, x in Character:GetChildren() do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = ZERO_VELOCITY, ZERO_VELOCITY
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and genv.OldPos and (RootPart.Position - genv.OldPos.p).Magnitude < 25)

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
        for _, p in (Players:GetPlayers()) do
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

    for _, cfg in (buttonConfigs) do
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

                    for _, player in (selectedPlayers) do
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
                    for _, p in (Players:GetPlayers()) do
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

            local mouse = LocalPlayer:GetMouse()

            local function onMouseClick(input, processed)
                if processed then return end

                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
                        for _, player in (Players:GetPlayers()) do
                            if player ~= LocalPlayer and not isWhitelisted(player) then
                                local targetChar = player.Character
                                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                                if targetRoot and rootPart then
                                    local distance = (rootPart.Position - targetRoot.Position).Magnitude
                                    if distance <= flingAuraStuds then
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

    flingSection:AddSlider("Fling Aura Studs", 5, 50, 15, function(value)
        flingAuraStuds = value
    end)
end

do
    local perkSection = ataos:AddSection("Perks", "MM2")
    local hasteOn, blatantMode, hasteSpd = false, false, 18
    local PerkMaid

    RootMaid:GiveTask(function() if PerkMaid then PerkMaid:Destroy() end end)

    local function updSpd()
        if not hasteOn then return end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        if not h then return end

        local knifeInChar = c:FindFirstChild("Knife")
        h.WalkSpeed = (knifeInChar or (LocalPlayer.Backpack:FindFirstChild("Knife") and knifeInChar))
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
    local wallhopSection = ataos:AddSection("Wallhop", "MM2")
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
    local enSection = ataos:AddSection("Emote Noclip", "MM2")

    local selEmote = nil
    local emotes = {
        ["Moonwalk"] = "79127989560307",
        ["Yungblud"] = "15610015346",
        ["Bouncy Twirl"] = "14353423348",
        ["Flex Walk"] = "15506506103"
    }

    local EmoteNoclipMaid = Maid.new()
    RootMaid:GiveTask(EmoteNoclipMaid)

    local noclipConn = nil
    local Clip = true
    local disableTimer = nil
    local bindableButtonEnabled = false
    local bindableButtonSize = 0.11

    local noclipDuration = 2

    local noclipParts = {}
    local noclipPartsChar = nil
    local noclipDescConn = nil

    local function noclipTrackDescendant(inst)
        if inst:IsA("BasePart") then
            noclipParts[#noclipParts + 1] = inst
        end
    end

    local function noclipRebuildParts(char)
        if noclipDescConn then
            noclipDescConn:Disconnect()
            noclipDescConn = nil
        end
        table.clear(noclipParts)
        noclipPartsChar = char
        if not char then return end
        for _, inst in char:GetDescendants() do
            if inst:IsA("BasePart") then
                noclipParts[#noclipParts + 1] = inst
            end
        end
        noclipDescConn = char.DescendantAdded:Connect(noclipTrackDescendant)
    end

    local function noclipReleaseParts()
        if noclipDescConn then
            noclipDescConn:Disconnect()
            noclipDescConn = nil
        end
        table.clear(noclipParts)
        noclipPartsChar = nil
    end

    local function NoclipLoop()
        if Clip then return end
        local char = LocalPlayer.Character
        if char == nil then return end
        if char ~= noclipPartsChar then
            noclipRebuildParts(char)
        end
        for _, part in noclipParts do
            if part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    local function enableNoclip()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end

        Clip = false
        noclipRebuildParts(LocalPlayer.Character)
        noclipConn = Services.RunService.Stepped:Connect(NoclipLoop)
    end

    local function disableNoclip()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end

        Clip = true
        noclipReleaseParts()

        if not LocalPlayer.Character then
            return
        end

        for _, part in LocalPlayer.Character:GetDescendants() do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    EmoteNoclipMaid:GiveTask(function()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        noclipReleaseParts()
    end)

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
    local ssSection = ataos:AddSection("Sign Spam", "MM2")
    local spamming, ssButtonEnabled, autoGetGG = false, false, false
    local ssButtonSize = 0.11
    local SignSpamMaid, SignSpamAutoMaid

    RootMaid:GiveTask(function()
        if SignSpamMaid then SignSpamMaid:Destroy() end
        if SignSpamAutoMaid then SignSpamAutoMaid:Destroy() end
    end)

    local function findSign()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        for _, tool in (backpack:GetChildren()) do
            if tool:IsA("Tool") and string.lower(tool.Name):find("sign") then
                return tool, backpack
            end
        end

        local character = LocalPlayer.Character
        if character then
            for _, tool in (character:GetChildren()) do
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

local Players = Services.Players
local PlaySong = Services.ReplicatedStorage.Remotes.Inventory.PlaySong
local sfxSection = ataos:AddSection("FE SFX", "MM2")

sfxSection:AddLabel("Radio Required")

local songSaveFile = "saved_gunshot_audio.json"
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
    for _, song in (savedSongs) do
        table.insert(names, song.name or song.id)
    end
    return names
end

local lastSelectedSong
local songDropdown = sfxSection:AddDropdown("Saved Gunshot Audio", getSongNames(), function(selectedName)
    for _, song in (savedSongs) do
        if song.name == selectedName then
            lastSelectedSong = song
            break
        end
    end
end)

sfxSection:AddTextBox("Add Gunshot Audio ID", function(text)
    local id = text:match("%d+")
    if id then
        local success, info = pcall(function() return Services.MarketplaceService:GetProductInfo(tonumber(id)) end)
        local name = (success and info and info.Name) or id
        table.insert(savedSongs, {name = name, id = id})
        saveSongs()
        RefreshDropdownItems(songDropdown, getSongNames())
        Notify("Added: "..name, 2)
    else
        Notify("Invalid audio ID!", 2)
    end
end)

sfxSection:AddButton("Delete Selected Gunshot Audio", function()
    if lastSelectedSong then
        for i, song in (savedSongs) do
            if song.name == lastSelectedSong.name then
                table.remove(savedSongs, i)
                saveSongs()
                RefreshDropdownItems(songDropdown, getSongNames())
                Notify("Removed: "..lastSelectedSong.name, 2)
                lastSelectedSong = nil
                return
            end
        end
    end
end)

local delayTime = 0.8
sfxSection:AddTextBox("Gunshot Delay (Seconds)", function(text)
    local val = tonumber(text)
    if val and val >= 0 then
        delayTime = val
        Notify("Delay set to: " .. val .. "s", 2)
    else
        Notify("Invalid delay value!", 2)
    end
end)

local feGunshotEnabled = false
sfxSection:AddToggle("Enable FE Gunshot", function(state)
    feGunshotEnabled = state
    Notify(state and "FE Gunshot Enabled" or "FE Gunshot Disabled", 2)
end)

local killSaveFile = "saved_killsound_audio.json"
local savedKillSongs = {}

if isfile and readfile and isfile(killSaveFile) then
    local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(killSaveFile)) end)
    if ok and type(data) == "table" then savedKillSongs = data end
end

local function saveKillSongs()
    if writefile then writefile(killSaveFile, Services.HttpService:JSONEncode(savedKillSongs)) end
end

local function getKillSongNames()
    local names = {}
    for _, song in (savedKillSongs) do
        table.insert(names, song.name or song.id)
    end
    return names
end

local lastSelectedKillSong
local killSongDropdown = sfxSection:AddDropdown("Saved Kill Sound Audio", getKillSongNames(), function(selectedName)
    for _, song in (savedKillSongs) do
        if song.name == selectedName then
            lastSelectedKillSong = song
            break
        end
    end
end)

sfxSection:AddTextBox("Add Kill Audio ID", function(text)
    local id = text:match("%d+")
    if id then
        local success, info = pcall(function() return Services.MarketplaceService:GetProductInfo(tonumber(id)) end)
        local name = (success and info and info.Name) or id
        table.insert(savedKillSongs, {name = name, id = id})
        saveKillSongs()
        RefreshDropdownItems(killSongDropdown, getKillSongNames())
        Notify("Added Kill Audio: "..name, 2)
    else
        Notify("Invalid audio ID!", 2)
    end
end)

sfxSection:AddButton("Delete Selected Kill Audio", function()
    if lastSelectedKillSong then
        for i, song in (savedKillSongs) do
            if song.name == lastSelectedKillSong.name then
                table.remove(savedKillSongs, i)
                saveKillSongs()
                RefreshDropdownItems(killSongDropdown, getKillSongNames())
                Notify("Removed Kill Audio: "..lastSelectedKillSong.name, 2)
                lastSelectedKillSong = nil
                return
            end
        end
    end
end)

local killDelayTime = 0.8
sfxSection:AddTextBox("Kill Delay (Seconds)", function(text)
    local val = tonumber(text)
    if val and val >= 0 then
        killDelayTime = val
        Notify("Kill Delay set to: " .. val .. "s", 2)
    else
        Notify("Invalid delay value!", 2)
    end
end)

local feKillSoundEnabled = false
sfxSection:AddToggle("Enable FE Kill Sound", function(state)
    feKillSoundEnabled = state
    Notify(state and "FE Kill Sound Enabled" or "FE Kill Sound Disabled", 2)
end)

local shootTargetIds = {
    ["76834305559381"] = true,
    ["7808472682"] = true,
    ["10209803"] = true,
}

local pendingGunshotThread = nil
local lastTrigger = 0
local debounceCooldown = 0.15

local SfxCharacterMaid = Maid.new()
RootMaid:GiveTask(SfxCharacterMaid)

local function monitorSound(sound)
    if not sound:IsA("Sound") then return end
    SfxCharacterMaid:GiveTask(sound:GetPropertyChangedSignal("Playing"):Connect(function()
        if not sound.Playing then return end

        if not feGunshotEnabled or not lastSelectedSong then return end

        local currentTime = tick()
        if currentTime - lastTrigger < debounceCooldown then return end

        local soundIdNumber = sound.SoundId:match("%d+")
        if not soundIdNumber then return end

        if shootTargetIds[soundIdNumber] then
            lastTrigger = currentTime

            local url = "https://www.roblox.com/asset/?id="..lastSelectedSong.id
            PlaySong:FireServer(url)

            if pendingGunshotThread then
                task.cancel(pendingGunshotThread)
                pendingGunshotThread = nil
            end

            pendingGunshotThread = task.spawn(function()
                task.wait(delayTime)
                pendingGunshotThread = nil
                if feGunshotEnabled and lastSelectedSong then
                    PlaySong:FireServer(url)
                end
            end)
        end
    end))
end

local function setupCharacter(char)
    SfxCharacterMaid:DoCleaning()
    SfxCharacterMaid:GiveTask(char.DescendantAdded:Connect(monitorSound))
    for _, desc in char:GetDescendants() do
        monitorSound(desc)
    end
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
RootMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(setupCharacter))

local function hasToolWithTag(player, tag)
    tag = tag:lower()
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in (backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(tag) then
                return true
            end
        end
    end
    local char = player.Character
    if char then
        for _, item in (char:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(tag) then
                return true
            end
        end
    end
    return false
end

local function onPlayerDied(player)
    if not feKillSoundEnabled or not lastSelectedKillSong then return end
    if not hasToolWithTag(player, "knife") then return end
    if not hasToolWithTag(LocalPlayer, "gun") then return end

    if pendingGunshotThread then
        task.cancel(pendingGunshotThread)
        pendingGunshotThread = nil
    end

    local killUrl = "https://www.roblox.com/asset/?id="..lastSelectedKillSong.id
    PlaySong:FireServer(killUrl)

    task.spawn(function()
        task.wait(killDelayTime)
        if feKillSoundEnabled and lastSelectedKillSong then
            PlaySong:FireServer(killUrl)
        end
    end)
end

local SfxOtherPlayersMaid = Maid.new()
RootMaid:GiveTask(SfxOtherPlayersMaid)

local function setupOtherPlayer(player)
    if player == LocalPlayer then return end
    SfxOtherPlayersMaid:GiveTask(player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            SfxOtherPlayersMaid:GiveTask(humanoid.Died:Connect(function()
                onPlayerDied(player)
            end))
        end
    end))
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            SfxOtherPlayersMaid:GiveTask(humanoid.Died:Connect(function()
                onPlayerDied(player)
            end))
        end
    end
end

for _, p in Players:GetPlayers() do
    setupOtherPlayer(p)
end
SfxOtherPlayersMaid:GiveTask(Players.PlayerAdded:Connect(setupOtherPlayer))

local autoGGSection = ataos:AddSection("Auto Grab Gun", "MM2")
local autoGGEnabled = false
local autoGGMaid = Maid.new()
RootMaid:GiveTask(autoGGMaid)

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

local function hasGunInInventory()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if char then
        for _, tool in (char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    if backpack then
        for _, tool in (backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    return false
end

local function gunDropExists()
    local drop = workspace:FindFirstChild("GunDrop", true)
    return drop ~= nil and drop:IsA("BasePart")
end

local function grabGun()
    if not gunDropExists() then return false end
    if hasGunInInventory() then return true end
    bringGun()
    task.wait(0.5)
    return hasGunInInventory()
end

autoGGSection:AddToggle("Enable Auto GG", function(enabled)
    autoGGEnabled = enabled
    autoGGMaid:DoCleaning()
    if enabled then
        task.spawn(function()
            while autoGGEnabled do
                if LocalPlayer.Character and gunDropExists() and not hasGunInInventory() then
                    grabGun()
                end
                task.wait(0.5)
            end
        end)
    end
end)

local giveGunSection = ataos:AddSection("Give Gun", "MM2")

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

local function isGunTool(tool)
    if not tool:IsA("Tool") then return false end
    if tool.Name:lower():find("gun", 1, true) then return true end
    local handle = tool:FindFirstChild("Handle")
    return handle ~= nil and handle:FindFirstChild("Gun") ~= nil
end

local function hasGunInInventory()
    local character = LocalPlayer.Character
    if not character then return false end

    for _, tool in character:GetChildren() do
        if isGunTool(tool) then return true end
    end

    local backpack = LocalPlayer.Backpack
    if backpack then
        for _, tool in backpack:GetChildren() do
            if isGunTool(tool) then return true end
        end
    end

    return false
end

local function CreateOtherPlayerPartCache()
    local parts = {}
    local maid = Maid.new()
    local charConns = {}
    local rebuildQueued = false
    local destroyed = false
    local rebuild

    local function addPart(inst)
        if inst:IsA("BasePart") then
            parts[#parts + 1] = inst
        end
    end

    function rebuild()
        rebuildQueued = false
        if destroyed then return end
        for _, conn in charConns do
            conn:Disconnect()
        end
        table.clear(charConns)
        table.clear(parts)
        for _, player in Services.Players:GetPlayers() do
            if player ~= LocalPlayer then
                local char = player.Character
                if char then
                    for _, inst in char:GetDescendants() do
                        if inst:IsA("BasePart") then
                            parts[#parts + 1] = inst
                        end
                    end
                    charConns[#charConns + 1] = char.DescendantAdded:Connect(addPart)
                end
            end
        end
    end

    local function queueRebuild()
        if rebuildQueued or destroyed then return end
        rebuildQueued = true
        task.defer(rebuild)
    end

    local function watchPlayer(player)
        if player == LocalPlayer then return end
        maid:GiveTasks(
            player.CharacterAdded:Connect(queueRebuild),
            player.CharacterRemoving:Connect(queueRebuild)
        )
    end

    for _, player in Services.Players:GetPlayers() do
        watchPlayer(player)
    end

    maid:GiveTasks(
        Services.Players.PlayerAdded:Connect(function(player)
            watchPlayer(player)
            queueRebuild()
        end),
        Services.Players.PlayerRemoving:Connect(queueRebuild),
        function()

            destroyed = true
            for _, conn in charConns do
                conn:Disconnect()
            end
            table.clear(charConns)
            table.clear(parts)
        end
    )

    rebuild()
    return parts, maid
end

local noclipPartCacheMaid = nil

local function enableNoclip()
    if noclipEnabled then return end

    noclipEnabled = true
    local parts, cacheMaid = CreateOtherPlayerPartCache()
    noclipPartCacheMaid = cacheMaid
    noclipConnection = Services.RunService.Stepped:Connect(function()
        for _, part in parts do
            if part.CanCollide then
                part.CanCollide = false
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
    if noclipPartCacheMaid then
        noclipPartCacheMaid:Destroy()
        noclipPartCacheMaid = nil
    end

    for _, player in Services.Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            for _, part in player.Character:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local stopDynamicTracking

RootMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
    disableNoclip()
    stopDynamicTracking()
end))

local ZERO_MOVE_DIRECTION = Vector3.new()
local TRACKING_HEIGHT_OFFSET = Vector3.new(0, 3, 0)

local function getPlayerMoveDirection(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return ZERO_MOVE_DIRECTION end

    local humanoid = targetChar:FindFirstChild("Humanoid")
    if not humanoid then return ZERO_MOVE_DIRECTION end

    local moveDirection = humanoid.MoveDirection

    if moveDirection.Magnitude > 0.1 then
        return moveDirection.Unit
    end

    return ZERO_MOVE_DIRECTION
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
            teleportPosition = targetRoot.CFrame + (moveDirection * teleportDistance) + TRACKING_HEIGHT_OFFSET
        else
            teleportPosition = targetRoot.CFrame + TRACKING_HEIGHT_OFFSET
        end

        root.CFrame = teleportPosition
    end)
end

function stopDynamicTracking()
    isTrackingActive = false
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end
end

RootMaid:GiveTask(function()
    stopDynamicTracking()
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if noclipPartCacheMaid then
        noclipPartCacheMaid:Destroy()
        noclipPartCacheMaid = nil
    end
end)

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
            initialPosition = targetRoot.CFrame + (moveDirection * teleportDistance) + TRACKING_HEIGHT_OFFSET
        else
            initialPosition = targetRoot.CFrame + TRACKING_HEIGHT_OFFSET
        end

        root.CFrame = initialPosition

        startDynamicTracking(targetPlayer)

        task.wait(0.5)
    else
        local moveDirection = getPlayerMoveDirection(targetPlayer)
        local teleportPosition

        if moveDirection.Magnitude > 0 then
            teleportPosition = targetRoot.CFrame + (moveDirection * teleportDistance) + TRACKING_HEIGHT_OFFSET
        else
            teleportPosition = targetRoot.CFrame + TRACKING_HEIGHT_OFFSET
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

giveGunSection:AddKeybind("Give Gun Keybind", "G", function()
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

local STAT_WHITE = Color3.fromRGB(255, 255, 255)
local STAT_GREEN = Color3.fromRGB(0, 255, 0)
local STAT_AMBER = Color3.fromRGB(255, 200, 0)
local STAT_RED = Color3.fromRGB(255, 0, 0)

local function getFpsColor(fps)
    local cap = getFpsCap()
    if fps >= cap * 0.85 then return STAT_GREEN
    elseif fps >= cap * 0.5 then return STAT_AMBER
    else return STAT_RED end
end

local function getPingColor(ping)
    if ping <= 80 then return STAT_GREEN
    elseif ping <= 150 then return STAT_AMBER
    else return STAT_RED end
end

local FpsPingMaid = Maid.new()
RootMaid:GiveTask(FpsPingMaid)

local function createFpsPingGui()
    if _G.FpsPingGui then _G.FpsPingGui:Destroy() end
    FpsPingMaid:DoCleaning()

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FpsPingMonitor"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Services.CoreGui
    _G.FpsPingGui = ScreenGui
    FpsPingMaid:GiveTask(ScreenGui)

    local base = positionPresets[uiPosition] or positionPresets["Top Right"]

    local Fps = Instance.new("TextLabel")
    Fps.BackgroundTransparency = 1
    Fps.Size = UDim2.new(0, 120, 0, 25)
    Fps.Font = Enum.Font.SourceSans
    Fps.TextColor3 = STAT_WHITE
    Fps.TextScaled = true
    Fps.Text = "0"
    Fps.Position = base
    Fps.Parent = ScreenGui
    _G.FpsLabel = Fps

    local Ping = Instance.new("TextLabel")
    Ping.BackgroundTransparency = 1
    Ping.Size = UDim2.new(0, 120, 0, 25)
    Ping.Font = Enum.Font.SourceSans
    Ping.TextColor3 = STAT_WHITE
    Ping.TextScaled = true
    Ping.Text = "0"
    Ping.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 28)
    Ping.Parent = ScreenGui
    _G.PingLabel = Ping

    local dataPingItem = Services.Stats.Network.ServerStatsItem["Data Ping"]

    local lastFPS, lastPing, lastPingUpdate = -1, -1, 0

    local connection
    connection = Services.RunService.RenderStepped:Connect(function(frame)

        if ScreenGui.Parent == nil then
            connection:Disconnect()
            return
        end

        local fps = math.floor(1 / frame + 0.5)
        if fps ~= lastFPS then
            lastFPS = fps
            Fps.Text = tostring(fps)
            Fps.TextColor3 = statColorsEnabled and getFpsColor(fps) or STAT_WHITE
        end

        local now = os.clock()
        if now - lastPingUpdate >= 0.5 then
            lastPingUpdate = now
            local pingValue = dataPingItem:GetValueString()
            local rawPing = tonumber(pingValue:match("%-?%d+")) or 0
            if rawPing ~= lastPing then
                lastPing = rawPing
                Ping.Text = tostring(rawPing)
                Ping.TextColor3 = statColorsEnabled and getPingColor(rawPing) or STAT_WHITE
            end
        end
    end)

    FpsPingMaid:GiveTask(connection)
end

local fps_ping_section = ataos:AddSection("FPS & PING MONITOR", "MM2")
fps_ping_section:AddToggle("Enable Monitor UI", function(bool)
    if bool then createFpsPingGui()
    elseif _G.FpsPingGui then
        FpsPingMaid:DoCleaning()
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

local Players = Services.Players
local Workspace = Services.Workspace
local Lighting = Services.Lighting

local perf_section = ataos:AddSection("Performance Optimization", "MM2")

local WEAK_KEYS = {__mode = "ks"}
local original_materials = setmetatable({}, WEAK_KEYS)
local original_particle_states = setmetatable({}, WEAK_KEYS)
local original_textures = setmetatable({}, WEAK_KEYS)
local original_mesh_transparency = setmetatable({}, WEAK_KEYS)

local original_accessories = {}

local conns = {
    Meshes = nil,
    Smooth = nil,
    Particles = nil,
    Textures = nil,
    CharacterAdded = nil
}

local fpsBoostEnabled = false
local meshGen = 0
local smoothGen = 0
local particleGen = 0
local textureGen = 0
local fpsGen = 0

local function getCharacterList()
    local allPlayers = Players:GetPlayers()
    local chars = table.create(#allPlayers)
    for _, plr in allPlayers do
        local char = plr.Character
        if char then
            chars[#chars + 1] = char
        end
    end
    return chars
end

local function isDescendantOfAny(obj, chars)
    for _, char in chars do
        if obj:IsDescendantOf(char) then
            return true
        end
    end
    return false
end

local function isPlayerDescendant(obj)
    return isDescendantOfAny(obj, getCharacterList())
end

local function applyMeshToObj(obj, chars)
    chars = chars or getCharacterList()
    if isDescendantOfAny(obj, chars) then return end

    if obj:IsA("MeshPart") then
        if original_mesh_transparency[obj] == nil then
            original_mesh_transparency[obj] = obj.Transparency
        end
        obj.Transparency = 1
        return
    end

    if obj:IsA("SpecialMesh") or obj:IsA("BlockMesh") or obj:IsA("CylinderMesh") then
        local parent = obj.Parent
        if parent and parent:IsA("BasePart") and not isDescendantOfAny(parent, chars) then
            if original_mesh_transparency[parent] == nil then
                original_mesh_transparency[parent] = parent.Transparency
            end
            parent.Transparency = 1
        end
    end
end

local function assignProperty(inst, prop, value)
    inst[prop] = value
end

local function setMeshes(on)
    if on then
        meshGen = meshGen + 1
        local gen = meshGen
        local chars = getCharacterList()
        if not conns.Meshes then
            conns.Meshes = Workspace.DescendantAdded:Connect(function(obj)
                task.defer(applyMeshToObj, obj)
            end)
        end
        local all = Workspace:GetDescendants()
        local total = #all
        local i = 1
        while i <= total do
            if gen ~= meshGen then return end
            local stop = math.min(i + 499, total)
            for j = i, stop do
                applyMeshToObj(all[j], chars)
            end
            i = stop + 1
            task.wait()
        end
    else
        meshGen = meshGen + 1
        for part, trans in original_mesh_transparency do
            if part and part.Parent then
                pcall(assignProperty, part, "Transparency", trans)
            end
        end
        table.clear(original_mesh_transparency)
        if conns.Meshes then
            conns.Meshes:Disconnect()
            conns.Meshes = nil
        end
    end
end

local function setSmoothPlastic(on)
    if on then
        smoothGen = smoothGen + 1
        local gen = smoothGen
        local chars = getCharacterList()
        if not conns.Smooth then
            conns.Smooth = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("BasePart") and not isPlayerDescendant(obj) then
                    original_materials[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end)
        end
        local all = Workspace:GetDescendants()
        local total = #all
        local i = 1
        while i <= total do
            if gen ~= smoothGen then return end
            local stop = math.min(i + 499, total)
            for j = i, stop do
                local obj = all[j]
                if obj:IsA("BasePart") and not isDescendantOfAny(obj, chars) and obj.Material ~= Enum.Material.SmoothPlastic then
                    original_materials[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
            i = stop + 1
            task.wait()
        end
    else
        smoothGen = smoothGen + 1
        for part, mat in original_materials do
            if part and part.Parent then
                pcall(assignProperty, part, "Material", mat)
            end
        end
        table.clear(original_materials)
        if conns.Smooth then
            conns.Smooth:Disconnect()
            conns.Smooth = nil
        end
    end
end

local function setParticles(on)
    if on then
        particleGen = particleGen + 1
        local gen = particleGen
        if not conns.Particles then
            conns.Particles = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    if original_particle_states[obj] == nil then
                        original_particle_states[obj] = obj.Enabled
                    end
                    obj.Enabled = false
                end
            end)
        end
        local all = Workspace:GetDescendants()
        local total = #all
        local i = 1
        while i <= total do
            if gen ~= particleGen then return end
            local stop = math.min(i + 499, total)
            for j = i, stop do
                local obj = all[j]
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    if original_particle_states[obj] == nil then
                        original_particle_states[obj] = obj.Enabled
                    end
                    obj.Enabled = false
                end
            end
            i = stop + 1
            task.wait()
        end
    else
        particleGen = particleGen + 1
        for obj, state in original_particle_states do
            if obj and obj.Parent then
                pcall(assignProperty, obj, "Enabled", state)
            end
        end
        table.clear(original_particle_states)
        if conns.Particles then
            conns.Particles:Disconnect()
            conns.Particles = nil
        end
    end
end

local function setTextures(on)
    if on then
        textureGen = textureGen + 1
        local gen = textureGen
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
        local all = Workspace:GetDescendants()
        local total = #all
        local i = 1
        while i <= total do
            if gen ~= textureGen then return end
            local stop = math.min(i + 499, total)
            for j = i, stop do
                local obj = all[j]
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    if original_textures[obj] == nil then
                        original_textures[obj] = obj.Texture
                    end
                    obj.Texture = ""
                end
            end
            i = stop + 1
            task.wait()
        end
    else
        textureGen = textureGen + 1
        for obj, tex in original_textures do
            if obj and obj.Parent then
                pcall(assignProperty, obj, "Texture", tex)
            end
        end
        table.clear(original_textures)
        if conns.Textures then
            conns.Textures:Disconnect()
            conns.Textures = nil
        end
    end
end

local function setShadows(on)
    Lighting.GlobalShadows = not on
end

local function stripAccessories(char, owner)
    for _, acc in char:GetChildren() do
        if acc:IsA("Accessory") then
            original_accessories[acc] = owner
            acc.Parent = nil
        end
    end
end

local accessoryPlayerConns = {}

local function disconnectAccessoryPlayerConns()
    for _, conn in accessoryPlayerConns do
        conn:Disconnect()
    end
    table.clear(accessoryPlayerConns)
end

local function setAccessories(on)
    if on then
        for _, plr in Players:GetPlayers() do
            local char = plr.Character
            if char then
                stripAccessories(char, plr)
            end
        end
        if not conns.CharacterAdded then
            conns.CharacterAdded = Players.PlayerAdded:Connect(function(p)
                accessoryPlayerConns[#accessoryPlayerConns + 1] = p.CharacterAdded:Connect(function(ch)
                    task.defer(stripAccessories, ch, p)
                end)
            end)
        end
    else
        for acc, owner in original_accessories do
            if owner and owner.Character and acc and not acc.Parent then
                pcall(assignProperty, acc, "Parent", owner.Character)
            end
        end
        table.clear(original_accessories)
        disconnectAccessoryPlayerConns()
        if conns.CharacterAdded then
            conns.CharacterAdded:Disconnect()
            conns.CharacterAdded = nil
        end
    end
end

local function destroyLightingSkies()
    for _, obj in Lighting:GetChildren() do
        if obj:IsA("Sky") then
            obj:Destroy()
        end
    end
end

local function setGraySky(on)
    destroyLightingSkies()
    if on then

        local sky = Instance.new("Sky")
        local assetId = "rbxassetid://99742693890881"
        sky.SkyboxBk = assetId
        sky.SkyboxDn = assetId
        sky.SkyboxFt = assetId
        sky.SkyboxLf = assetId
        sky.SkyboxRt = assetId
        sky.SkyboxUp = assetId
        sky.Parent = Lighting
    end
end

local function removeWeaponDisplays()
    local wd = Workspace:FindFirstChild("WeaponDisplays")
    if wd then
        wd:Destroy()
    end
end

local function dgBasePart(obj)
    obj.CastShadow = false
    obj.RenderFidelity = Enum.RenderFidelity.Disabled
end

local function dgEnabledOff(obj)
    obj.Enabled = false
end

local degradeByClass = {}

local function resolveDegrade(obj)
    if obj:IsA("BasePart") then return dgBasePart
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then return dgEnabledOff
    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then return dgEnabledOff
    end
    return false
end

local function degradePart(obj)
    local cn = obj.ClassName
    local h = degradeByClass[cn]
    if h == nil then
        h = resolveDegrade(obj)
        degradeByClass[cn] = h
    end
    if h then h(obj) end
end

local function setFrameEnhancement(bool)
    fpsBoostEnabled = bool

    local rendering = settings().Rendering

    if bool then
        fpsGen = fpsGen + 1
        local gen = fpsGen
        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        rendering.QualityLevel = Enum.QualityLevel.Level01
        rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Disabled
        workspace.Terrain.Decoration = false

        if _G.FpsBoostConnection then
            _G.FpsBoostConnection:Disconnect()
            _G.FpsBoostConnection = nil
        end
        _G.FpsBoostConnection = workspace.DescendantAdded:Connect(degradePart)
        local all = workspace:GetDescendants()
        local total = #all
        local i = 1
        while i <= total do
            if gen ~= fpsGen then return end
            local stop = math.min(i + 499, total)
            for j = i, stop do
                degradePart(all[j])
            end
            i = stop + 1
            task.wait()
        end
    else
        fpsGen = fpsGen + 1
        Lighting.GlobalShadows = true
        Lighting.Brightness = 2
        rendering.QualityLevel = Enum.QualityLevel.Automatic
        rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Full
        workspace.Terrain.Decoration = true

        if _G.FpsBoostConnection then
            _G.FpsBoostConnection:Disconnect()
            _G.FpsBoostConnection = nil
        end
    end
end

RootMaid:GiveTask(function()
    for key, conn in conns do
        if conn then
            conn:Disconnect()
            conns[key] = nil
        end
    end
    disconnectAccessoryPlayerConns()
    if _G.FpsBoostConnection then
        _G.FpsBoostConnection:Disconnect()
        _G.FpsBoostConnection = nil
    end
end)

perf_section:AddToggle("No Textures (SmoothPlastic)", setSmoothPlastic)
perf_section:AddToggle("Disable Shadows", setShadows)
perf_section:AddToggle("Disable Particles/Trails", setParticles)
perf_section:AddToggle("Hide Meshes (world only)", setMeshes)
perf_section:AddToggle("Remove Textures/Decals", setTextures)
perf_section:AddToggle("Remove Accessories", setAccessories)
perf_section:AddToggle("Gray Skybox", setGraySky)
perf_section:AddButton("Remove Weapon Displays", removeWeaponDisplays)
perf_section:AddToggle("Enable Frame Enhancement", setFrameEnhancement)

local true_antis_section = ataos:AddSection("True Anti's", "MM2")
local trueAntiFlingConnection, lowEndAntiFlingConnection, trueAntiAfkConnection, trueAntiVoidConnection
local trueAntiFlingCacheMaid = nil
local originalDestroyHeight = workspace.FallenPartsDestroyHeight

true_antis_section:AddToggle("Enable IY Anti Fling", function(bool)
    if trueAntiFlingConnection then
        trueAntiFlingConnection:Disconnect()
        trueAntiFlingConnection = nil
    end
    if trueAntiFlingCacheMaid then
        trueAntiFlingCacheMaid:Destroy()
        trueAntiFlingCacheMaid = nil
    end

    if bool then

        local parts, cacheMaid = CreateOtherPlayerPartCache()
        trueAntiFlingCacheMaid = cacheMaid
        trueAntiFlingConnection = Services.RunService.Stepped:Connect(function()
            for _, part in parts do
                if part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

true_antis_section:AddToggle("Enable Low-End Device Anti-Fling", function(bool)
    if lowEndAntiFlingConnection then
        if typeof(lowEndAntiFlingConnection) == "table" then
            for _, conn in lowEndAntiFlingConnection do
                conn:Disconnect()
            end
        else
            lowEndAntiFlingConnection:Disconnect()
        end
        lowEndAntiFlingConnection = nil
    end

    if bool then
        local connections = {}

        local function uncollidePart(part)
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        local function setupCharacter(char)
            for _, part in char:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            table.insert(connections, char.DescendantAdded:Connect(uncollidePart))
        end

        for _, player in Services.Players:GetPlayers() do
            if player ~= LocalPlayer then
                if player.Character then
                    setupCharacter(player.Character)
                end
                table.insert(connections, player.CharacterAdded:Connect(setupCharacter))
            end
        end

        table.insert(connections, Services.Players.PlayerAdded:Connect(function(player)
            table.insert(connections, player.CharacterAdded:Connect(setupCharacter))
        end))

        lowEndAntiFlingConnection = connections
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

local Camera = workspace.CurrentCamera

local cameraSection = ataos:AddSection("Camera Stretch", "MM2")

local cameraStretchEnabled = false
local stretchStrength = 0.80

local STRETCH_CFRAME = CFrame.new(0, 0, 0, 1, 0, 0, 0, stretchStrength, 0, 0, 0, 1)
local cameraStretchConnection = nil

cameraSection:AddToggle("Enable Camera Stretch", function(on)
    cameraStretchEnabled = on

    if cameraStretchConnection then
        cameraStretchConnection:Disconnect()
        cameraStretchConnection = nil
    end

    if on then
        cameraStretchConnection = Services.RunService.RenderStepped:Connect(function()
            Camera.CFrame = Camera.CFrame * STRETCH_CFRAME
        end)
    end
end)

local creditsSection = ataos:AddSection("Credits", "Info")
creditsSection:AddParagraph("@lzzzx", "Made this plugin, if you have requests feel free to ask.")

shared.Notify("ATAOs Successfully Loaded!", 2)

RootMaid:GiveTasks(
    function() if trueAntiFlingConnection then trueAntiFlingConnection:Disconnect() end end,
    function() if trueAntiFlingCacheMaid then trueAntiFlingCacheMaid:Destroy() end end,
    function()
        if typeof(lowEndAntiFlingConnection) == "table" then
            for _, conn in lowEndAntiFlingConnection do conn:Disconnect() end
        elseif lowEndAntiFlingConnection then
            lowEndAntiFlingConnection:Disconnect()
        end
    end,
    function() if trueAntiAfkConnection then trueAntiAfkConnection:Disconnect() end end,
    function() if trueAntiVoidConnection then trueAntiVoidConnection:Disconnect() end end,
    function() if cameraStretchConnection then cameraStretchConnection:Disconnect() end end,
    function() workspace.FallenPartsDestroyHeight = originalDestroyHeight end,
    function()
        for id in BindableButtons.Buttons do
            BindableButtons.DeleteBButton(id)
        end
    end
)
