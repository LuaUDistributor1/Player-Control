-- GUI Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local COMMAND_PREFIX = "!"
local TARGET_USER = nil -- Will be set via GUI
local FOLLOW_SPEED = 16
local SPIN_SPEED = 10

-- State management
local isSpinning = false
local isFollowing = false
local isLoopGoto = false
local currentSpinSpeed = SPIN_SPEED
local currentFollowTarget = nil

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CommandGUI"
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 380)
mainFrame.Position = UDim2.new(0, 10, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 170, 255)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
title.Text = "Command Controller"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1, -20, 0, 60)
inputFrame.Position = UDim2.new(0, 10, 0, 50)
inputFrame.BackgroundTransparency = 1
inputFrame.Parent = mainFrame

local usernameLabel = Instance.new("TextLabel")
usernameLabel.Size = UDim2.new(1, 0, 0, 20)
usernameLabel.Text = "Target Username:"
usernameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
usernameLabel.Font = Enum.Font.Gotham
usernameLabel.TextSize = 14
usernameLabel.BackgroundTransparency = 1
usernameLabel.Parent = inputFrame

local usernameBox = Instance.new("TextBox")
usernameBox.Size = UDim2.new(1, 0, 0, 30)
usernameBox.Position = UDim2.new(0, 0, 0, 25)
usernameBox.PlaceholderText = "Enter username"
usernameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
usernameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameBox.Font = Enum.Font.Gotham
usernameBox.TextSize = 14
usernameBox.Parent = inputFrame

local setButton = Instance.new("TextButton")
setButton.Size = UDim2.new(0, 60, 0, 30)
setButton.Position = UDim2.new(1, -60, 0, 25)
setButton.Text = "SET"
setButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
setButton.TextColor3 = Color3.fromRGB(255, 255, 255)
setButton.Font = Enum.Font.GothamBold
setButton.TextSize = 14
setButton.Parent = inputFrame

local commandsFrame = Instance.new("Frame")
commandsFrame.Size = UDim2.new(1, -20, 0, 260)
commandsFrame.Position = UDim2.new(0, 10, 0, 120)
commandsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
commandsFrame.Parent = mainFrame

local commandsLabel = Instance.new("TextLabel")
commandsLabel.Size = UDim2.new(1, 0, 0, 30)
commandsLabel.Text = "Available Commands:"
commandsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
commandsLabel.Font = Enum.Font.GothamBold
commandsLabel.TextSize = 16
commandsLabel.BackgroundTransparency = 1
commandsLabel.Parent = commandsFrame

local commandsList = Instance.new("ScrollingFrame")
commandsList.Size = UDim2.new(1, 0, 1, -40)
commandsList.Position = UDim2.new(0, 0, 0, 35)
commandsList.BackgroundTransparency = 1
commandsList.ScrollBarThickness = 8
commandsList.Parent = commandsFrame

local commandLayout = Instance.new("UIListLayout")
commandLayout.Padding = UDim.new(0, 5)
commandLayout.Parent = commandsList

-- Command descriptions
local commands = {
    "!goto [username] - Teleport to player",
    "!loopgoto [username] - Loop teleport",
    "!unloopgoto - Stop loop teleport",
    "!spin [speed] - Spin player",
    "!unspin - Stop spinning",
    "!follow [username] - Follow player",
    "!unfollow - Stop following"
}

for _, command in ipairs(commands) do
    local cmdLabel = Instance.new("TextLabel")
    cmdLabel.Size = UDim2.new(1, 0, 0, 25)
    cmdLabel.Text = command
    cmdLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
    cmdLabel.Font = Enum.Font.Gotham
    cmdLabel.TextSize = 13
    cmdLabel.TextXAlignment = Enum.TextXAlignment.Left
    cmdLabel.BackgroundTransparency = 1
    cmdLabel.Parent = commandsList
end

-- Update commands list size
commandsList.CanvasSize = UDim2.new(0, 0, 0, #commands * 30)

-- Function to find player by username with shorthand support
local function findPlayer(username)
    if not username or username == "" then return nil end
    
    local lowerUsername = string.lower(username)
    local exactMatch = nil
    local partialMatches = {}
    local displayNameMatches = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        -- Check exact name match
        if string.lower(player.Name) == lowerUsername then
            exactMatch = player
            break
        end
        
        -- Check exact display name match
        if string.lower(player.DisplayName) == lowerUsername then
            exactMatch = player
            break
        end
        
        -- Check partial name match (shorthand)
        if string.lower(string.sub(player.Name, 1, #username)) == lowerUsername then
            table.insert(partialMatches, player)
        end
        
        -- Check partial display name match
        if string.lower(string.sub(player.DisplayName, 1, #username)) == lowerUsername then
            table.insert(displayNameMatches, player)
        end
    end
    
    -- Return priority: exact name > exact display name > partial name > partial display name
    if exactMatch then
        return exactMatch
    elseif #partialMatches == 1 then
        return partialMatches[1]
    elseif #displayNameMatches == 1 then
        return displayNameMatches[1]
    elseif #partialMatches > 1 then
        -- If multiple partial matches, return the first one
        return partialMatches[1]
    elseif #displayNameMatches > 1 then
        return displayNameMatches[1]
    end
    
    return nil
end

-- Function to get character humanoid root part
local function getCharacterRoot(player)
    if player and player.Character then
        return player.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- Teleport functions
local function teleportToPlayer(targetName)
    local targetPlayer = findPlayer(targetName)
    if targetPlayer then
        local targetRoot = getCharacterRoot(targetPlayer)
        if targetRoot and humanoidRootPart then
            humanoidRootPart.CFrame = targetRoot.CFrame
            return true
        end
    end
    return false
end

-- Spin function
local function startSpinning(speed)
    if not speed then speed = SPIN_SPEED end
    currentSpinSpeed = tonumber(speed) or SPIN_SPEED
    isSpinning = true
    
    while isSpinning and humanoidRootPart do
        humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, math.rad(currentSpinSpeed), 0)
        RunService.Heartbeat:Wait()
    end
end

local function stopSpinning()
    isSpinning = false
end

-- Follow function
local function startFollowing(targetName)
    local targetPlayer = findPlayer(targetName)
    if not targetPlayer then return end
    
    isFollowing = true
    currentFollowTarget = targetPlayer
    
    while isFollowing and currentFollowTarget and humanoidRootPart do
        local targetRoot = getCharacterRoot(currentFollowTarget)
        if targetRoot then
            local direction = (targetRoot.Position - humanoidRootPart.Position).Unit
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, 
                humanoidRootPart.Position + direction)
            
            -- Move towards target
            humanoidRootPart.Velocity = direction * FOLLOW_SPEED
        end
        RunService.Heartbeat:Wait()
    end
    
    if humanoidRootPart then
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

local function stopFollowing()
    isFollowing = false
    currentFollowTarget = nil
end

-- Command parser
local function parseCommand(message)
    if not TARGET_USER then return end
    
    local args = {}
    for arg in message:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then return end
    
    local command = string.lower(args[1])
    
    if command == "!goto" and args[2] then
        teleportToPlayer(args[2])
        
    elseif command == "!loopgoto" and args[2] then
        isLoopGoto = true
        spawn(function()
            while isLoopGoto do
                teleportToPlayer(args[2])
                wait(0.1)
            end
        end)
        
    elseif command == "!unloopgoto" then
        isLoopGoto = false
        print("Loop teleport stopped")
        
    elseif command == "!spin" then
        startSpinning(args[2])
        
    elseif command == "!unspin" then
        stopSpinning()
        
    elseif command == "!follow" and args[2] then
        startFollowing(args[2])
        
    elseif command == "!unfollow" then
        stopFollowing()
    end
end

-- Chat listener
local function onChatMessage(message, speaker)
    if speaker == TARGET_USER then
        parseCommand(message)
    end
end

-- Set up chat monitoring
if TextChatService then
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if channel then
        channel.OnIncomingMessage = function(message)
            local speaker = message.TextSource
            if speaker then
                local player = Players:GetPlayerByUserId(speaker.UserId)
                if player then
                    onChatMessage(message.Text, player)
                end
            end
        end
    end
end

-- Alternative method for older chat
local function setupChatListener()
    if game:GetService("Chat"):GetSpeaker(localPlayer.Name) then
        game:GetService("Chat"):Chat(localPlayer.Character, "") -- Initialize chat
    end
end

-- GUI event handlers
setButton.MouseButton1Click:Connect(function()
    local username = usernameBox.Text
    if username and username ~= "" then
        local player = findPlayer(username)
        if player then
            TARGET_USER = player
            usernameBox.Text = player.Name
            print("Target set to:", player.Name)
        else
            usernameBox.Text = "Player not found"
            TARGET_USER = nil
        end
    end
end)

-- Status indicator
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 390)
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = mainFrame

-- Update status function
local function updateStatus()
    local status = "Ready"
    local color = Color3.fromRGB(0, 255, 100)
    
    if isSpinning then
        status = "Spinning"
        color = Color3.fromRGB(255, 150, 0)
    elseif isFollowing then
        status = "Following " .. (currentFollowTarget and currentFollowTarget.Name or "someone")
        color = Color3.fromRGB(0, 200, 255)
    elseif isLoopGoto then
        status = "Loop Teleporting"
        color = Color3.fromRGB(255, 100, 100)
    end
    
    statusLabel.Text = "Status: " .. status
    statusLabel.TextColor3 = color
end

-- Status update loop
spawn(function()
    while true do
        updateStatus()
        wait(0.5)
    end
end)

-- Cleanup on respawn
localPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    wait(1)
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Reset states on respawn
    stopSpinning()
    stopFollowing()
    isLoopGoto = false
end)

-- Initialize
setupChatListener()
print("Command GUI loaded. Set target username to begin.")

-- Shorthand usage instructions
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 30)
infoLabel.Position = UDim2.new(0, 10, 1, -35)
infoLabel.Text = "Shorthand: Use first few letters of username"
infoLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.BackgroundTransparency = 1
infoLabel.Parent = mainFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = mainFrame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    -- Clean up all processes
    stopSpinning()
    stopFollowing()
    isLoopGoto = false
end)