-- Made by Lzzzx

-- Official Safe File

-- ✅ HiddenGui Error Patch (put this first)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local hiddenGui = PlayerGui:FindFirstChild("HiddenGui")
if not hiddenGui then
    hiddenGui = Instance.new("ScreenGui")
    hiddenGui.Name = "HiddenGui"
    hiddenGui.ResetOnSpawn = false
    hiddenGui.IgnoreGuiInset = true
    hiddenGui.Parent = PlayerGui
end

-- =========================
-- Plugin: Lua File Manager
-- =========================
local shared = odh_shared_plugins
local my_own_section = shared.AddSection("Plugin Manager")

my_own_section:AddLabel("Manage .lua Files in Plugins Folder")

-- Setup folder
local baseFolder = "Ixry Shizuka"
local pluginsFolder = baseFolder .. "/plugins"

if not isfolder(baseFolder) then
    makefolder(baseFolder)
end
if not isfolder(pluginsFolder) then
    makefolder(pluginsFolder)
end

-- current dropdown reference & selected file
local fileDropdown
local selectedFile = nil

-- function to refresh list
local function refreshFileList()
    local files = {}
    for _, filePath in ipairs(listfiles(pluginsFolder)) do
        if filePath:match("%.lua$") then
            local fileName = filePath:match("[^/\\]+$") -- strip path
            table.insert(files, fileName)
        end
    end
    return files
end

-- create dropdown
fileDropdown = my_own_section:AddDropdown("Select Plugin File", refreshFileList(), function(selected)
    selectedFile = selected -- store it globally
end)

-- refresh button
my_own_section:AddButton("Refresh File List", function()
    local files = refreshFileList()
    fileDropdown.Change(files)
    selectedFile = nil -- reset selection after refresh
    shared.Notify("File list refreshed ("..#files.." files)", 2)
end)

-- delete button
my_own_section:AddButton("Delete Selected File", function()
    if selectedFile then
        local fullPath = pluginsFolder.."/"..selectedFile
        if isfile(fullPath) then
            delfile(fullPath)
            shared.Notify("Deleted: " .. selectedFile, 3)
            -- refresh dropdown after deletion
            local files = refreshFileList()
            fileDropdown.Change(files)
            selectedFile = nil -- clear selection after delete
        else
            shared.Notify("File not found: " .. selectedFile, 3)
        end
    else
        shared.Notify("No file selected", 3)
    end
end)

-- rename textbox
my_own_section:AddTextBox("Rename Plugin", function(newFileName)
    if not selectedFile then
        shared.Notify("No file selected to rename", 3)
        return
    end
    if not newFileName:match("%.lua$") then
        shared.Notify("Enter a valid new name ending with .lua", 3)
        return
    end
    local oldPath = pluginsFolder.."/"..selectedFile
    local newPath = pluginsFolder.."/"..newFileName
    if not isfile(oldPath) then
        shared.Notify("File not found: " .. selectedFile, 3)
        return
    end
    if isfile(newPath) then
        shared.Notify("A file with that name already exists", 3)
        return
    end
    writefile(newPath, readfile(oldPath))
    delfile(oldPath)
    shared.Notify("Renamed "..selectedFile.." → "..newFileName, 4)

    -- refresh dropdown
    local files = refreshFileList()
    fileDropdown.Change(files)
    selectedFile = nil
end)

-- =====================
-- Watcher (Rejoin logic)
-- =====================
local watcherActive = false
local lastFiles = {}

local function getFiles()
    local files = {}
    for _, f in ipairs(listfiles(pluginsFolder)) do
        if f:match("%.lua$") then
            files[f:match("[^/\\]+$")] = true
        end
    end
    return files
end

local function startWatcher()
    task.spawn(function()
        local startTime = os.clock()
        while watcherActive and (os.clock() - startTime < 30) do
            task.wait(1)

            local currentFiles = getFiles()
            for f in pairs(currentFiles) do
                if not lastFiles[f] then
                    shared.Notify("New plugin detected: " .. f, 5)
                    game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
                    return
                end
            end
            lastFiles = currentFiles
        end
        if watcherActive then
            shared.Notify("Checking Disabled (No New Plugins Found)", 3)
            watcherActive = false
        end
    end)
end

my_own_section:AddToggle("Rejoin When New Plugin Added", function(enabled)
    watcherActive = enabled
    if enabled then
        lastFiles = getFiles() -- reset baseline
        shared.Notify("Checking Enabled", 3)
        startWatcher()
    else
        shared.Notify("Checker Disabled", 3)
    end
end)

-- =========================
-- Server Options
-- =========================

local shared = odh_shared_plugins
local my_own_section = shared.AddSection("Server Options")

--// Services
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--// Place + Job info
local PlaceId = game.PlaceId
local JobId = game.JobId

----------------------------------------------------------------
-- Rejoin
----------------------------------------------------------------
local function rejoin()
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
end

----------------------------------------------------------------
-- Server Hop (Random Server)
----------------------------------------------------------------
local function serverHop()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
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
            TeleportService:TeleportToPlaceInstance(PlaceId, randomServer.id, Players.LocalPlayer)
            return
        end
    end

    shared.Notify("No server found to hop to", 3)
end

----------------------------------------------------------------
-- Full Server
----------------------------------------------------------------
local serversApi = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100"

local function getServers(cursor)
    local url = serversApi
    if cursor then
        url = url.."&cursor="..cursor
    end

    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and response and response.data then
        return response
    else
        return nil
    end
end

local function findFullerServer()
    local cursor = nil
    local bestServer = nil

    repeat
        local servers = getServers(cursor)
        if not servers then break end

        for _, server in ipairs(servers.data) do
            if server.id ~= JobId and server.playing < server.maxPlayers then
                if not bestServer or server.playing > bestServer.playing then
                    bestServer = server
                end
            end
        end

        cursor = servers.nextPageCursor
    until not cursor or bestServer

    return bestServer
end

local function joinFullServer()
    local target = findFullerServer()
    if target then
        shared.Notify("Joining full server...", 2)
        TeleportService:TeleportToPlaceInstance(PlaceId, target.id, Players.LocalPlayer)
    else
        shared.Notify("No suitable fuller server found", 3)
    end
end

----------------------------------------------------------------
-- Dead Server
----------------------------------------------------------------
local function fetchServers(cursor)
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(
        PlaceId,
        cursor and "&cursor=" .. cursor or ""
    )

    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and result and result.data then
        return result
    else
        warn("Failed to fetch servers")
        return nil
    end
end

local function findDeadServer()
    local lowestServer, lowestCount
    local cursor = nil

    repeat
        local page = fetchServers(cursor)
        if not page then break end

        for _, server in ipairs(page.data) do
            if server.id ~= JobId and server.playing > 0 then
                if not lowestCount or server.playing < lowestCount then
                    lowestCount = server.playing
                    lowestServer = server
                end
            end
        end

        cursor = page.nextPageCursor
        task.wait(1.5) -- avoid rate limit
    until not cursor

    return lowestServer
end

local function joinDeadServer()
    local server = findDeadServer()
    if server then
        shared.Notify("Joining dead server with " .. server.playing .. " players", 3)
        TeleportService:TeleportToPlaceInstance(PlaceId, server.id, Players.LocalPlayer)
    else
        shared.Notify("No dead server found", 3)
    end
end

----------------------------------------------------------------
-- UI Elements
----------------------------------------------------------------
my_own_section:AddLabel("Might Take a Few Tries")

-- Buttons in the order you want
my_own_section:AddButton("Rejoin", function()
    rejoin()
end)

my_own_section:AddButton("Server Hop", function()
    serverHop()
end)

my_own_section:AddButton("Join Full Server", function()
    joinFullServer()
end)

my_own_section:AddButton("Join Dead Server", function()
    joinDeadServer()
end)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local PlaySong = ReplicatedStorage.Remotes.Inventory.PlaySong -- RemoteEvent 
local RoleSelect = ReplicatedStorage.Remotes.Gameplay.RoleSelect -- RemoteEvent 

-- Shared
local shared = odh_shared_plugins
local my_own_section = shared.AddSection("Radio Abuse")

-- File to store saved songs
local saveFile = "saved_songs.json"

-- Load saved songs
local savedSongs = {}
if isfile and readfile and isfile(saveFile) then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(saveFile))
    end)
    if ok and type(data) == "table" then
        savedSongs = data
    end
end

-- Function to save songs
local function saveSongs()
    if writefile then
        writefile(saveFile, HttpService:JSONEncode(savedSongs))
    end
end

-- Convert savedSongs into a list of names for the dropdown
local function getSongNames()
    local names = {}
    for _, song in ipairs(savedSongs) do
        table.insert(names, song.name or song.id)
    end
    return names
end

-- Dropdown (shows names, plays IDs)
local dropdown
local lastSelected = nil
dropdown = my_own_section:AddDropdown("Saved Songs", getSongNames(), function(selectedName)
    for _, song in ipairs(savedSongs) do
        if song.name == selectedName then
            lastSelected = song
            local url = "https://www.roblox.com/asset/?id=" .. song.id
            PlaySong:FireServer(url)
            break
        end
    end
end)

-- Textbox to add songs (just ID or full URL)
my_own_section:AddTextBox("Add Audio ID", function(text)
    local id = text:match("%d+")
    if id then
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(tonumber(id))
        end)
        if success and info and info.Name then
            table.insert(savedSongs, {name = info.Name, id = id})
            saveSongs()
            dropdown.Change(getSongNames())
            shared.Notify("Added new song: " .. info.Name, 2)
        else
            shared.Notify("Failed to fetch song name, saved as ID only", 3)
            table.insert(savedSongs, {name = id, id = id})
            saveSongs()
            dropdown.Change(getSongNames())
        end
    else
        shared.Notify("Invalid audio ID!", 2)
    end
end)

-- Button to remove selected song
my_own_section:AddButton("Delete Selected Audio", function()
    if lastSelected then
        for i, song in ipairs(savedSongs) do
            if song.name == lastSelected.name then
                table.remove(savedSongs, i)
                saveSongs()
                dropdown.Change(getSongNames())
                shared.Notify("Removed song: " .. lastSelected.name, 2)
                lastSelected = nil
                return
            end
        end
        shared.Notify("Selected song not found in list", 2)
    else
        shared.Notify("No song selected to remove", 2)
    end
end)

----------------------------------------------------------------
-- 🔥 Auto Play Toggle
----------------------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local autoPlayEnabled = false
local connection
local charConnection

-- Function to play selected audio
local function playSelectedSong()
    if lastSelected then
        local url = "https://www.roblox.com/asset/?id=" .. lastSelected.id
        PlaySong:FireServer(url)
    else
        shared.Notify("No song selected for auto-play!", 3)
    end
end

my_own_section:AddToggle("Auto Play Selected Audio", function(state)
    autoPlayEnabled = state

    -- Disconnect old connections
    if connection then
        connection:Disconnect()
        connection = nil
    end
    if charConnection then
        charConnection:Disconnect()
        charConnection = nil
    end

    if autoPlayEnabled then
        -- Trigger when RoleSelect remote fires
        connection = RoleSelect.OnClientEvent:Connect(function(...)
            playSelectedSong()
        end)

        -- Trigger after each respawn
        charConnection = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1) -- short delay to ensure character fully loads
            playSelectedSong()
        end)

        -- Also play immediately if you’re already spawned
        if LocalPlayer.Character then
            task.wait(1)
            playSelectedSong()
        end
    end
end)

----------------------------------------------------------------
-- ✅ Credits Label (at the very bottom of the section)
----------------------------------------------------------------
my_own_section:AddLabel("Credits: <font color='rgb(170,0,255)'>@lzzzx</font>")

-- =========================
-- Auto Speed Glitch
-- =========================
local shared = odh_shared_plugins
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local speed_glitch_section = shared.AddSection("Auto Speedglitch")

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
-- Trickshot + TS Button (Fixed)
-- =========================
do
    local shared = odh_shared_plugins
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer

    local spinSpeed = 15
    local hasJumped = false
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
        local humanoid = character:WaitForChild("Humanoid")

        local function startSpin()
            -- clear old forces
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

            -- Stop spin when landed
            table.insert(connections, humanoid.StateChanged:Connect(function(_, newState)
                if newState == Enum.HumanoidStateType.Landed then
                    torque:Destroy()
                    hasJumped = false -- reset so spin can work on next jump
                    active = false
                end
            end))
        end

        table.insert(connections, UserInputService.JumpRequest:Connect(function()
            if active and not hasJumped then
                hasJumped = true
                task.defer(startSpin) -- ensure jump actually registered before spin
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
        active = true
    end)

    my_own_section:AddToggle("Enable TS Bindable Button", function(enabled)
        guiEnabled = enabled
        if guiEnabled then
            createGuiButton()
        else
            if tsGui then tsGui:Destroy() end
        end
    end)

    my_own_section:AddSlider("TS Bindable Button Size", 30, 150, tsButtonSize, function(size)
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
    my_own_section:AddLabel("Must Own Dual Effect + Selected Effect")
    
    local toggle_enabled = false
    local connection
    local selected_effect = "Electric" -- Default effect
    
    -- Add dropdown for effect selection
    my_own_section:AddDropdown("Select Second Effect", {
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
        "FlamingoEffect2025",
        "Burn",
        "Cursed2024",
        "Starry2024",
        "Bats2024",
        "Aquatic2025",
        "Jellyfish2024",
        "Carrots2025",
        "BlueFire",
        "Rainbows2025",
        "Elitify",
        "Electric",
        "Ghostify"
    }, function(selected)
        selected_effect = selected
    end)
    
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
                            Equip:FireServer(selected_effect, "Effects")
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

        my_own_section:AddLabel('Credits: <font color="rgb(0,255,0)">@not_.gato</font>', nil, true)
    else
        warn("Failed to create Spray Paint section! Plugin not loaded.")
    end
end

-- =========================
-- Troll (FE) Emotes (Animator API)
-- =========================
do
    local shared = odh_shared_plugins
    local my_own_section = shared.AddSection("Troll (FE)")

    my_own_section:AddLabel("Play Troll Emotes")

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Shared emote handler generator
    local function makeEmoteHandler(emoteId, buttonText, guiName)
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
            anim.AnimationId = "rbxassetid://"..emoteId

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

            local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild(guiName)
            if not screenGui then
                screenGui = Instance.new("ScreenGui")
                screenGui.Name = guiName
                screenGui.ResetOnSpawn = false
                screenGui.Parent = player:WaitForChild("PlayerGui")
            end

            guiButton = Instance.new("TextButton")
            guiButton.Size = UDim2.new(0, guiSize, 0, guiSize)
            guiButton.Position = UDim2.new(0.5, 0, 0.8, 0) -- same spot, draggable
            guiButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            guiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            guiButton.Font = Enum.Font.SourceSansBold
            guiButton.TextSize = guiSize/2
            guiButton.Text = buttonText
            guiButton.Parent = screenGui

            local uicorner = Instance.new("UICorner")
            uicorner.CornerRadius = UDim.new(1, 0)
            uicorner.Parent = guiButton

            -- draggable
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

        -- Add settings to the UI
        my_own_section:AddToggle("Enable "..buttonText.." Button", function(enabled)
            guiEnabled = enabled
            if guiEnabled then
                createGuiButton()
            else
                if guiButton then guiButton:Destroy() end
            end
        end)

        my_own_section:AddSlider(buttonText.." Button Size", 30, 150, guiSize, function(size)
            guiSize = size
            if guiButton then
                guiButton.Size = UDim2.new(0, guiSize, 0, guiSize)
                guiButton.TextSize = guiSize/2
            end
        end)

        my_own_section:AddButton("Play "..buttonText.." Emote", function()
            playEmote()
        end)
    end

-- Register each emote
makeEmoteHandler("84112287597268", "FD", "EmoteGUI_FakeDead")  -- Fake Dead
makeEmoteHandler("122366279755346", "KS", "EmoteGUI_KnifeSwing") -- Knife Swing
makeEmoteHandler("103788740211648", "DS", "EmoteGUI_DualSwing")  -- Dual Swing

end

-- =========================
-- Mute ODH Buttons
-- =========================

local shared = odh_shared_plugins

local mute_section = shared.AddSection("Mute Buttons")
mute_section:AddLabel("Turn Off and Rejoin to Enable Sounds Again")

-- Variables
local targetId = "rbxassetid://3868133279"
local mutingEnabled = false
local muteConnections = {}

-- Helper: mutes a sound and prevents it from being unmuted
local function muteSound(sound)
    if sound.SoundId == targetId then
        sound.Volume = 0
        table.insert(muteConnections, sound:GetPropertyChangedSignal("Volume"):Connect(function()
            if mutingEnabled and sound.Volume > 0 then
                sound.Volume = 0
            end
        end))
    end
end

-- Enable muting
local function enableMuting()
    -- Mute existing sounds
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Sound") then
            muteSound(obj)
        end
    end

    -- Watch for new sounds
    table.insert(muteConnections, workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Sound") then
            muteSound(obj)
        end
    end))
end

-- Disable muting
local function disableMuting()
    for _, conn in ipairs(muteConnections) do
        conn:Disconnect()
    end
    table.clear(muteConnections)
end

-- Toggle
mute_section:AddToggle("Disable ODH Button Sounds", function(state)
    mutingEnabled = state
    if mutingEnabled then
        enableMuting()
    else
        disableMuting()
    end
end)

-- =========================
-- RFX Visual Enhancer w/ Presets
-- =========================
do
    local shared = odh_shared_plugins
    local Lighting = game:GetService("Lighting")

    local rfx_section = shared.AddSection("RFX")

    local rfx = {
        Blur = nil,
        ColorCorrection = nil,
        Bloom = nil,
        SunRays = nil,
        DepthOfField = nil,
    }

    local enabled = false

    local function createEffects()
        if not rfx.Blur then
            local blur = Instance.new("BlurEffect")
            blur.Size = 2
            blur.Parent = Lighting
            rfx.Blur = blur
        end

        if not rfx.ColorCorrection then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Brightness = 0.05
            cc.Contrast = 0.1
            cc.Saturation = 0.15
            cc.TintColor = Color3.fromRGB(255, 245, 230)
            cc.Parent = Lighting
            rfx.ColorCorrection = cc
        end

        if not rfx.Bloom then
            local bloom = Instance.new("BloomEffect")
            bloom.Intensity = 0.5
            bloom.Threshold = 0.9
            bloom.Size = 40
            bloom.Parent = Lighting
            rfx.Bloom = bloom
        end

        if not rfx.SunRays then
            local sr = Instance.new("SunRaysEffect")
            sr.Intensity = 0.2
            sr.Spread = 0.8
            sr.Parent = Lighting
            rfx.SunRays = sr
        end

        if not rfx.DepthOfField then
            local dof = Instance.new("DepthOfFieldEffect")
            dof.InFocusRadius = 30
            dof.NearIntensity = 0.1
            dof.FarIntensity = 0.15
            dof.FocusDistance = 25
            dof.Parent = Lighting
            rfx.DepthOfField = dof
        end
    end

    local function setEnabled(state)
        enabled = state
        if state then
            createEffects()
            for _, v in pairs(rfx) do
                if v then v.Enabled = true end
            end
        else
            for _, v in pairs(rfx) do
                if v then v.Enabled = false end
            end
        end
    end

    -- Apply preset styles
    local function applyPreset(preset)
        if not enabled then return end
        if not rfx.ColorCorrection or not rfx.Bloom or not rfx.SunRays then return end

        if preset == "Cinematic" then
            rfx.ColorCorrection.Brightness = 0.05
            rfx.ColorCorrection.Contrast = 0.25
            rfx.ColorCorrection.Saturation = -0.05
            rfx.ColorCorrection.TintColor = Color3.fromRGB(255, 240, 220)
            rfx.Bloom.Intensity = 0.3
            rfx.SunRays.Intensity = 0.15

        elseif preset == "Warm" then
            rfx.ColorCorrection.Brightness = 0.1
            rfx.ColorCorrection.Contrast = 0.15
            rfx.ColorCorrection.Saturation = 0.2
            rfx.ColorCorrection.TintColor = Color3.fromRGB(255, 220, 180)
            rfx.Bloom.Intensity = 0.4
            rfx.SunRays.Intensity = 0.2

        elseif preset == "Cold" then
            rfx.ColorCorrection.Brightness = -0.05
            rfx.ColorCorrection.Contrast = 0.2
            rfx.ColorCorrection.Saturation = -0.1
            rfx.ColorCorrection.TintColor = Color3.fromRGB(200, 220, 255)
            rfx.Bloom.Intensity = 0.35
            rfx.SunRays.Intensity = 0.25

        elseif preset == "HDR" then
            rfx.ColorCorrection.Brightness = 0.15
            rfx.ColorCorrection.Contrast = 0.3
            rfx.ColorCorrection.Saturation = 0.25
            rfx.ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
            rfx.Bloom.Intensity = 0.6
            rfx.SunRays.Intensity = 0.35
        end
    end

    -- Plugin UI
    rfx_section:AddToggle("Enable RFX", function(state)
        setEnabled(state)
    end)

    rfx_section:AddSlider("RFX Intensity", 1, 100, 50, function(value)
        if enabled then
            if rfx.Bloom then rfx.Bloom.Intensity = value / 100 * 1 end
            if rfx.SunRays then rfx.SunRays.Intensity = value / 100 * 0.4 end
            if rfx.ColorCorrection then rfx.ColorCorrection.Contrast = value / 100 * 0.3 end
        end
    end)

    rfx_section:AddDropdown("RFX Presets", {"Cinematic", "Warm", "Cold", "HDR"}, function(preset)
        applyPreset(preset)
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Section
local speedSection = shared.AddSection("Legit Speedglitch")

-- Variables
local sideSpeed = 0
local buttonSize = 50
local emoteEnabled = false
local selectedEmoteId = nil
local customEmoteEnabled = false
local sgGui, sgButton
local horizontal_only = false
local default_speed = 16
local character, humanoid, rootPart
local is_in_air = false

-- Predefined emotes
local emotes = {
    ["Moonwalk"] = "79127989560307",
    ["Yungblud"] = "15610015346",
    ["Bouncy Twirl"] = "14353423348",
    ["Flex Walk"] = "15506506103"
}

-- ======= Character Handling =======
local function setupCharacter(char)
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
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- ======= Play Emote =======
local function playEmote(assetId)
    if not character or not humanoid then return end
    local success = pcall(function()
        humanoid:PlayEmoteAndGetAnimTrackById(assetId)
    end)
    if not success then
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://"..assetId
        humanoid:LoadAnimation(anim):Play()
    end
end

-- ======= Create SG Button =======
local function createSGButton()
    if sgGui then sgGui:Destroy() end

    sgGui = Instance.new("ScreenGui")
    sgGui.Name = "SGGui"
    sgGui.ResetOnSpawn = false
    sgGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    sgButton = Instance.new("TextButton")
    sgButton.Name = "SGButton"
    sgButton.Text = "SG"
    sgButton.Font = Enum.Font.SourceSansBold
    sgButton.TextSize = buttonSize / 2
    sgButton.TextColor3 = Color3.new(1, 0, 0) -- red
    sgButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sgButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    sgButton.Position = UDim2.new(0.5, -buttonSize/2, 0.7, 0)
    sgButton.AnchorPoint = Vector2.new(0.5, 0.5)
    sgButton.Parent = sgGui

    local uicorner = Instance.new("UICorner", sgButton)
    uicorner.CornerRadius = UDim.new(1, 0)

    sgButton.MouseButton1Click:Connect(function()
        emoteEnabled = not emoteEnabled
        if emoteEnabled then
            sgButton.TextColor3 = Color3.new(0, 1, 0) -- green
            if selectedEmoteId then playEmote(selectedEmoteId) end
        else
            sgButton.TextColor3 = Color3.new(1, 0, 0) -- red
            if humanoid then humanoid.WalkSpeed = default_speed end
        end
    end)

    -- draggable
    local dragging, dragStart, startPos
    sgButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = sgButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    sgButton.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            sgButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ======= Movement Logic (ASG style) =======
RunService.Stepped:Connect(function()
    if not emoteEnabled or not character or not humanoid or not rootPart then return end

    local final_speed = default_speed + sideSpeed

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

-- =====================
-- SpeedGlitch GUI
-- =====================
speedSection:AddToggle("Enable SG Bindable Button", function(bool)
    if bool then
        createSGButton()
    else
        if sgGui then sgGui:Destroy() end
        sgGui, sgButton = nil, nil
        emoteEnabled = false
        if humanoid then humanoid.WalkSpeed = default_speed end
    end
end)

speedSection:AddSlider("Speed (0–255)", 0, 255, sideSpeed, function(val)
    sideSpeed = val
end)

speedSection:AddSlider("Button Size", 30, 150, buttonSize, function(val)
    buttonSize = val
    if sgButton then
        sgButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
        sgButton.TextSize = buttonSize / 2
    end
end)

speedSection:AddToggle("Sideways Only", function(enabled)
    horizontal_only = enabled
end)

-- Dropdown: Emotes
speedSection:AddDropdown("Select Emote", {"Moonwalk","Yungblud","Bouncy Twirl","Flex Walk","Custom"}, function(selected)
    if selected == "Custom" then
        customEmoteEnabled = true
        selectedEmoteId = nil
    else
        customEmoteEnabled = false
        selectedEmoteId = emotes[selected]
    end
end)

-- Textbox: Custom emote ID
speedSection:AddTextBox("Custom Emote ID", function(text)
    if text ~= "" then
        selectedEmoteId = text
        customEmoteEnabled = true
    end
end)

local shared = odh_shared_plugins
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Section
local headless_section = shared.AddSection("FE Headless")

-- Default Headless Emote ID
local headlessEmoteId = 78837807518622

-- Vars
local headlessEnabled = false
local currentTrack
local frozen = true -- freeze always ON

-- === Play Emote (from Emotes.lua) ===
local function playEmote(humanoid, emoteId)
    if not humanoid or not humanoid:IsDescendantOf(workspace) then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    -- stop any running track
    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
    end

    -- load new track
    local emote = Instance.new("Animation")
    emote.AnimationId = "rbxassetid://" .. tostring(emoteId)
    currentTrack = animator:LoadAnimation(emote)
    currentTrack.Priority = Enum.AnimationPriority.Action
    currentTrack.Looped = true
    currentTrack:Play()

    -- loop fixer: if Roblox cancels the track, restart it
    currentTrack.Stopped:Connect(function()
        if headlessEnabled and humanoid and humanoid.Parent then
            task.wait(0.1)
            playEmote(humanoid, emoteId)
        end
    end)
end

-- === Stop Emote ===
local function stopEmote()
    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
    end
end

-- === Apply Freeze Mode (fixed: allow movement) ===
local function applyFreeze(humanoid)
    if humanoid and frozen then
        humanoid.StateChanged:Connect(function(_, new)
            if headlessEnabled and humanoid.Parent then
                if not currentTrack or not currentTrack.IsPlaying then
                    task.wait(0.05)
                    playEmote(humanoid, headlessEmoteId)
                end
            end
        end)
    end
end

-- === Enable Headless ===
local function enableHeadless()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")

    applyFreeze(humanoid)
    playEmote(humanoid, headlessEmoteId)
end

-- Toggle
headless_section:AddToggle("Enable Headless", function(state)
    headlessEnabled = state
    if state then
        enableHeadless()
    else
        stopEmote()
    end
end)

-- Respawn support (auto re-enable if toggle is on)
LocalPlayer.CharacterAdded:Connect(function(char)
    if headlessEnabled then
        local humanoid = char:WaitForChild("Humanoid")
        task.wait(0.5)
        enableHeadless()
    end
end)

local shared = odh_shared_plugins
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local AllBool = false

-- === Helper Message Function === --
local function Message(_Title, _Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = _Title, Text = _Text, Duration = Time})
end

-- === Advanced SkidFling Function === --
local function SkidFling(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THumanoid and THumanoid.Sit and not AllBool then
            return Message("Error Occurred", "Target is sitting", 5)
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
            local TimeToWait = 2
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
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end
        
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
        else
            return Message("Error Occurred", "Target is missing everything", 5)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            table.foreach(Character:GetChildren(), function(_, x)
                if x:IsA("BasePart") then
                    x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                end
            end)
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    else
        return Message("Error Occurred", "Random error", 5)
    end
end

-- === Helper Functions === --
local function FindMurderer()
    for _, plr in pairs(Players:GetPlayers()) do
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp and bp:FindFirstChild("Knife") then
            return plr
        end
    end
end

local function FindSheriff()
    for _, plr in pairs(Players:GetPlayers()) do
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp and bp:FindFirstChild("Gun") then
            return plr
        end
    end
end

local function FlingAll()
    AllBool = true
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then
            SkidFling(plr)
        end
    end
    AllBool = false
end

-- === Plugin Section === --
local fling_section = shared.AddSection("Fling")

fling_section:AddButton("Fling Sheriff", function()
    local sheriff = FindSheriff()
    if sheriff then
        SkidFling(sheriff)
    else
        Message("Error", "Sheriff not found", 3)
    end
end)

fling_section:AddButton("Fling Murderer", function()
    local murderer = FindMurderer()
    if murderer then
        SkidFling(murderer)
    else
        Message("Error", "Murderer not found", 3)
    end
end)

fling_section:AddButton("Fling All", function()
    FlingAll()
end)

local selectedPlayer = nil
fling_section:AddPlayerDropdown("Fling Player", function(player)
    selectedPlayer = player
    if player and player ~= Player then
        SkidFling(player)
    end
end)

-- === Loop Fling Player Toggle === --
local loopingPlayer = false
fling_section:AddToggle("Loop Fling Player", function(state)
    loopingPlayer = state
    task.spawn(function()
        while loopingPlayer do
            if selectedPlayer and selectedPlayer ~= Player and selectedPlayer.Parent == Players then
                SkidFling(selectedPlayer)
            else
                Message("Error", "No valid player selected", 3)
                loopingPlayer = false
                break
            end
        end
    end)
end)

-- === Loop Fling All Toggle === --
local loopingAll = false
fling_section:AddToggle("Loop Fling All", function(state)
    loopingAll = state
    task.spawn(function()
        while loopingAll do
            FlingAll()
            task.wait(5) -- repeat every 5 seconds, adjust as needed
        end
    end)
end)

local shared = odh_shared_plugins
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local auto_haste_section = shared.AddSection("Perks")

local autoHasteEnabled = false
local defaultSpeed = 16
local hasteSpeed = 18
local connection

local function hasKnife()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    if backpack and backpack:FindFirstChild("Knife") then
        return true
    end
    
    if character and character:FindFirstChild("Knife") then
        return true
    end
    
    return false
end

local function isKnifeEquipped()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Knife") then
        return true
    end
    return false
end

local function updateSpeed()
    if not autoHasteEnabled then return end
    if not hasKnife() then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if isKnifeEquipped() then
        humanoid.WalkSpeed = hasteSpeed
    else
        humanoid.WalkSpeed = defaultSpeed
    end
end

local function setupAutoHaste()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if not autoHasteEnabled then
        -- Reset speed when disabled
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = defaultSpeed
            end
        end
        return
    end
    
    -- Monitor character changes
    connection = LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        character.ChildAdded:Connect(function(child)
            if child.Name == "Knife" then
                updateSpeed()
            end
        end)
        
        character.ChildRemoved:Connect(function(child)
            if child.Name == "Knife" then
                updateSpeed()
            end
        end)
        
        task.wait(0.5)
        updateSpeed()
    end)
    
    if LocalPlayer.Character then
        local character = LocalPlayer.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if humanoid then
            character.ChildAdded:Connect(function(child)
                if child.Name == "Knife" then
                    updateSpeed()
                end
            end)
            
            character.ChildRemoved:Connect(function(child)
                if child.Name == "Knife" then
                    updateSpeed()
                end
            end)
            
            updateSpeed()
        end
    end
end

auto_haste_section:AddToggle("Enable Auto Haste", function(bool)
    autoHasteEnabled = bool
    setupAutoHaste()
end)

-- Only 1 label now + renamed
auto_haste_section:AddLabel("Stacks With Other Perks")

local shared = odh_shared_plugins
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Section
local blind_section = shared.AddSection("Blind Everyone")

-- Default Blind Emote ID
local blindEmoteId = 70883871260184

-- Vars
local blindEnabled = false
local currentTrack
local frozen = true -- freeze always ON

-- === Play Emote (from Emotes.lua) ===
local function playEmote(humanoid, emoteId)
    if not humanoid or not humanoid:IsDescendantOf(workspace) then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    -- stop any running track
    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
    end

    -- load new track
    local emote = Instance.new("Animation")
    emote.AnimationId = "rbxassetid://" .. tostring(emoteId)
    currentTrack = animator:LoadAnimation(emote)
    currentTrack.Priority = Enum.AnimationPriority.Action
    currentTrack.Looped = true
    currentTrack:Play()

    -- loop fixer: if Roblox cancels the track, restart it
    currentTrack.Stopped:Connect(function()
        if blindEnabled and humanoid and humanoid.Parent then
            task.wait(0.1)
            playEmote(humanoid, emoteId)
        end
    end)
end

-- === Stop Emote ===
local function stopEmote()
    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
    end
end

-- === Apply Freeze Mode (fixed: allow movement) ===
local function applyFreeze(humanoid)
    if humanoid and frozen then
        humanoid.StateChanged:Connect(function(_, new)
            if blindEnabled and humanoid.Parent then
                if not currentTrack or not currentTrack.IsPlaying then
                    task.wait(0.05)
                    playEmote(humanoid, blindEmoteId)
                end
            end
        end)
    end
end

-- === Enable Blind ===
local function enableBlind()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")

    applyFreeze(humanoid)
    playEmote(humanoid, blindEmoteId)
end

-- Toggle
headless_section:AddToggle("Enable Blind All", function(state)
    blindEnabled = state
    if state then
        enableBlind()
    else
        stopEmote()
    end
end)

-- Respawn support (auto re-enable if toggle is on)
LocalPlayer.CharacterAdded:Connect(function(char)
    if blindEnabled then
        local humanoid = char:WaitForChild("Humanoid")
        task.wait(0.5)
        enableBlind()
    end
end)
