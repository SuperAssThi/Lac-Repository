--!strict
-- Main Teleportation Script (Modified for toggling)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local teleportInterval = 1
local teleportConnection: RBXScriptConnection | nil = nil
local lastTeleportedHead: BasePart | nil = nil
local scriptEnabled = false -- New: State variable for the script

-- Function to wait for the player to be grounded
local function waitUntilGrounded()
    if not humanoid then warn("waitUntilGrounded: Humanoid not found! Cannot wait for grounded state.") return end

    if not humanoid.Parent or not humanoid.Parent:IsA("Model") then
        warn("waitUntilGrounded: Humanoid's parent (character) is invalid. Skipping grounded check.")
        return
    end

    while humanoid.FloorMaterial == Enum.Material.Air do
        task.wait(0.1)
    end
    print("DEBUG: Player is now grounded.")
end

-- Function to find and store all eligible "Head" parts within "Button" models
local function findButtonHeads(): {BasePart}
    local foundHeads: {BasePart} = {}
    print("DEBUG: Starting search for 'Head' objects inside 'Button' models.")
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name == "Head" then
            local currentParent = descendant.Parent
            while currentParent do
                if currentParent:IsA("Model") and currentParent.Name == "Button" then
                    print("DEBUG: Found 'Button' model parent for 'Head': " .. currentParent:GetFullName() .. " (Child: " .. descendant:GetFullName() .. ")")
                    table.insert(foundHeads, descendant)
                    break
                end
                currentParent = currentParent.Parent
            end
        end
    end
    print("DEBUG: Finished search. Found " .. #foundHeads .. " eligible 'Head' parts.")
    return foundHeads
end

local currentCycleHeads: {BasePart} = {}
local currentIndex: number = 1

-- This function now accepts the 'initialTargetHead' that the player touched
local function startTeleportCycle(initialTargetHead: BasePart)
    if not scriptEnabled then return end -- Only run if enabled

    local allHeadsInButtons = findButtonHeads()

    if #allHeadsInButtons == 0 then
        warn("No 'Head' objects found inside 'Button' models in the workspace to teleport to. Aborting teleport cycle.")
        lastTeleportedHead = nil
        return
    end

    currentCycleHeads = {}
    currentIndex = 1

    local foundInitial = false
    for i, head in ipairs(allHeadsInButtons) do
        if head == initialTargetHead then
            table.insert(currentCycleHeads, head)
            currentIndex = 1
            foundInitial = true
            break
        end
    end

    if not foundInitial then
        warn("DEBUG: Initial touched 'Head' was not found in the 'allHeadsInButtons' list. Choosing a random one to start.")
        if #allHeadsInButtons > 0 then
            table.insert(currentCycleHeads, allHeadsInButtons[math.random(1, #allHeadsInButtons)])
            currentIndex = 1
        else
            warn("Cannot start teleport cycle: No valid heads found.")
            lastTeleportedHead = nil
            return
        end
    end

    for _, head in ipairs(allHeadsInButtons) do
        local alreadyAdded = false
        for _, existingHead in ipairs(currentCycleHeads) do
            if head == existingHead then
                alreadyAdded = true
                break
            end
        end
        if not alreadyAdded then
            table.insert(currentCycleHeads, head)
        end
    end

    if #currentCycleHeads <= 1 then
        warn("DEBUG: Only one or no eligible 'Head' parts found. Player will stay at the touched head if valid.")
        if currentCycleHeads[1] and currentCycleHeads[1].Parent then
            waitUntilGrounded()
            rootPart.CFrame = currentCycleHeads[1].CFrame * CFrame.new(0, 5, 0)
            lastTeleportedHead = currentCycleHeads[1]
        end
        return
    end

    for i = #currentCycleHeads, 2, -1 do
        local j = math.random(2, i)
        currentCycleHeads[i], currentCycleHeads[j] = currentCycleHeads[j], currentCycleHeads[i]
    end

    if teleportConnection then
        print("DEBUG: Disconnecting previous teleportConnection.")
        teleportConnection:Disconnect()
        teleportConnection = nil
    end

    teleportConnection = RunService.Heartbeat:Connect(function()
        if not scriptEnabled then
            if teleportConnection then
                teleportConnection:Disconnect()
                teleportConnection = nil
            end
            return
        end

        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
            warn("DEBUG: Player, Character, HumanoidRootPart, or Humanoid became invalid during teleport cycle. Disconnecting Heartbeat.")
            if teleportConnection then
                teleportConnection:Disconnect()
                teleportConnection = nil
            end
            lastTeleportedHead = nil
            return
        end

        rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        humanoid = player.Character:FindFirstChild("Humanoid")

        if not rootPart or not humanoid then
            warn("DEBUG: HumanoidRootPart or Humanoid is nil after re-check within Heartbeat. Skipping this tick.")
            return
        end

        if humanoid.Health <= 0 then
            warn("DEBUG: Player is dead. Disconnecting teleport cycle.")
            if teleportConnection then
                teleportConnection:Disconnect()
                teleportConnection = nil
            end
            lastTeleportedHead = nil
            return
        end

        if not player.Character.Parent then
            warn("DEBUG: Player character's parent is nil. Potentially respawning or being destroyed. Disconnecting.")
            if teleportConnection then
                teleportConnection:Disconnect()
                teleportConnection = nil
            end
            lastTeleportedHead = nil
            return
        end

        waitUntilGrounded()

        local targetHead = currentCycleHeads[currentIndex]

        if not targetHead then
            warn("ERROR: targetHead at index " .. currentIndex .. " is nil in 'currentCycleHeads'. This indicates a corrupted list. Rebuilding.")
            startTeleportCycle(initialTargetHead)
            return
        end
        if not targetHead.Parent then
            warn("DEBUG: Target Head (" .. targetHead.Name .. ") at index " .. currentIndex .. " has been destroyed or moved (Parent is nil). Rebuilding head list and attempting to restart cycle.")
            startTeleportCycle(initialTargetHead)
            return
        end
        if not targetHead:IsA("BasePart") then
             warn("DEBUG: Target Head (" .. targetHead.Name .. ") at index " .. currentIndex .. " is no longer a BasePart. Skipping this specific teleport.")
             currentIndex = currentIndex + 1
             if currentIndex > #currentCycleHeads then
                 currentIndex = 1
             end
             return
        end

        if lastTeleportedHead == targetHead then
            print("DEBUG: Next target head is the same as the last one. Skipping to next in sequence.")
            currentIndex = currentIndex + 1
            if currentIndex > #currentCycleHeads then
                currentIndex = 1
            end
            targetHead = currentCycleHeads[currentIndex]

            if #currentCycleHeads > 1 and lastTeleportedHead == targetHead then
                warn("DEBUG: After advancing, next target is still the same as the last one. Re-picking a non-duplicate if possible.")
                local originalTarget = targetHead
                repeat
                    currentIndex = currentIndex + 1
                    if currentIndex > #currentCycleHeads then
                        currentIndex = 1
                    end
                    targetHead = currentCycleHeads[currentIndex]
                until targetHead ~= originalTarget or #currentCycleHeads <= 1
                if #currentCycleHeads <= 1 then
                    warn("DEBUG: Only one head or problematic setup, cannot avoid immediate repeat.")
                end
            end
        end

        print("DEBUG: Attempting to teleport to " .. targetHead:GetFullName() .. " (Index: " .. currentIndex .. ")")
        local newCFrame = targetHead.CFrame * CFrame.new(0, 5, 0)
        rootPart.CFrame = newCFrame
        lastTeleportedHead = targetHead

        currentIndex = currentIndex + 1
        if currentIndex > #currentCycleHeads then
            currentIndex = 1
        end
    end)
end

local connectedTriggerObjects: {RBXScriptConnection} = {}

local function setupTouchTriggers()
    if not scriptEnabled then
        for _, connection in pairs(connectedTriggerObjects) do
            connection:Disconnect()
        end
        connectedTriggerObjects = {}
        return
    end

    print("DEBUG: Setting up touch triggers.")
    for i, connection in pairs(connectedTriggerObjects) do
        print("DEBUG: Disconnecting old trigger connection " .. i)
        connection:Disconnect()
    end
    connectedTriggerObjects = {}

    local eligibleHeads = findButtonHeads()

    if #eligibleHeads > 0 then
        for _, headPart in ipairs(eligibleHeads) do
            print("DEBUG: Connecting Touched event for trigger: " .. headPart:GetFullName())
            local connection = headPart.Touched:Connect(function(hit)
                if scriptEnabled then -- Double-check if enabled on touch
                    local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
                    if hitPlayer == player then
                        print("DEBUG: Player touched " .. headPart:GetFullName() .. "! Preparing to teleport.")
                        waitUntilGrounded()
                        lastTeleportedHead = headPart
                        startTeleportCycle(headPart)
                    end
                end
            end)
            table.insert(connectedTriggerObjects, connection)
        end
        print("DEBUG: Successfully set up touch triggers for " .. #eligibleHeads .. " 'Head' parts in 'Button' models.")
    else
        warn("No 'Head' objects found inside 'Button' models to set up as triggers.")
    end
end

local function setupPlayerAndTriggers()
    print("DEBUG: setupPlayerAndTriggers called.")
    task.wait(2)
    setupTouchTriggers()
end

player.CharacterAdded:Connect(function(newCharacter)
    print("DEBUG: CharacterAdded event fired. New character loaded.")
    character = newCharacter
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
    humanoid = newCharacter:WaitForChild("Humanoid")
    setupPlayerAndTriggers()
end)

-- GUI Script
local guiEnabled = true -- Initial state for the GUI visibility

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportToggleGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50) -- Center of the screen
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 2
frame.Draggable = true -- Make the frame draggable
frame.Active = true -- Enable input events for dragging
frame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
titleLabel.BorderColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.BorderSizePixel = 1
titleLabel.Text = "Teleport Script Toggle"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.8, 0, 0, 40)
toggleButton.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
toggleButton.BorderColor3 = Color3.fromRGB(20, 20, 20)
toggleButton.BorderSizePixel = 1
toggleButton.Text = "Enable Teleport"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 20
toggleButton.Parent = frame

local function updateToggleButtonText()
    if scriptEnabled then
        toggleButton.Text = "Disable Teleport"
        toggleButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60) -- Red for disabled
    else
        toggleButton.Text = "Enable Teleport"
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60) -- Green for enabled
    end
end

local function toggleScript()
    scriptEnabled = not scriptEnabled
    updateToggleButtonText()
    if not scriptEnabled then
        -- If disabling, disconnect the heartbeat connection
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
            print("Teleport script disabled: Heartbeat connection disconnected.")
        end
        -- Disconnect all touch triggers
        for _, connection in pairs(connectedTriggerObjects) do
            connection:Disconnect()
        end
        connectedTriggerObjects = {}
        print("Teleport script disabled: Touch triggers disconnected.")
    else
        -- If enabling, re-setup the touch triggers
        setupTouchTriggers()
        print("Teleport script enabled: Touch triggers re-initialized.")
    end
end

toggleButton.MouseButton1Click:Connect(toggleScript)

-- Initial state for the button
updateToggleButtonText()

-- You can optionally hide the GUI with a keybind
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then -- Or any other keybind you prefer
        guiEnabled = not guiEnabled
        screenGui.Enabled = guiEnabled
    end
end)

-- Initial call to set up the player and triggers (script starts disabled)
-- The original script's initial setup was at the end, now it's controlled by the GUI.
-- We want the script to start in a disabled state, waiting for the toggle.
-- So, we don't call setupPlayerAndTriggers() here. It will be called when the user enables it.
