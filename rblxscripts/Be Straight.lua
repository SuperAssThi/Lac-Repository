--[[
    "Be Straight" Draggable Button
    Author: Gemini
    Date: August 3, 2025

    Creates a draggable button that rotates the player to the nearest 90-degree angle
    and then adjusts the camera to be directly behind the player.

    Place this LocalScript inside StarterPlayer.StarterPlayerScripts.
]]

-- || Services & Player Variables ||
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") -- Added for smooth camera movement
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- || GUI Creation ||
-- Create the main container for the UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StraightenGui"
screenGui.ResetOnSpawn = false -- So the UI stays when the player respawns

-- Create the main button
local straightenButton = Instance.new("TextButton")
straightenButton.Name = "StraightenButton"
straightenButton.Draggable = true -- Makes the button draggable
straightenButton.Active = true    -- Ensures the button can be interacted with
straightenButton.Size = UDim2.new(0, 150, 0, 50)
straightenButton.Position = UDim2.new(0, 30, 0, 30)

-- Style the button's appearance
straightenButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Grey background
straightenButton.Text = "Be Straight"
straightenButton.Font = Enum.Font.SourceSansBold -- Bold font
straightenButton.TextColor3 = Color3.fromRGB(15, 15, 15) -- Black text color
straightenButton.TextSize = 22
straightenButton.Parent = screenGui

-- Add a corner radius for a softer, modern look
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = straightenButton

-- Create the blue outline using UIStroke
local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 110, 255) -- A nice blue color
uiStroke.Thickness = 2.5 -- The thickness of the outline
uiStroke.Parent = straightenButton


-- || Core Logic ||
-- This function runs when the button is clicked.

local function onStraightenClick()
    -- 🏃‍♂️ Get the player's character and key parts
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")

    -- Exit if the character isn't fully loaded
    if not rootPart or not head then
        warn("Straighten Button: Character parts not found!")
        return
    end

    -- === Part 1: Rotate the Player ===
    local _, yRotation, _ = rootPart.CFrame:ToEulerAnglesYXZ()
    local yDegrees = math.deg(yRotation)
    local nearestY = math.round(yDegrees / 90) * 90
    local newYRadians = math.rad(nearestY)
    rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.fromEulerAnglesYXZ(0, newYRadians, 0)

    -- === Part 2: Adjust the Camera ===
    task.wait() -- Wait a single frame for the character rotation to apply fully

    -- Define the camera's position relative to the player's head
    local cameraDistance = 8 -- How many studs behind the player
    local cameraHeight = 1.5 -- How many studs above the head's center

    -- Calculate the target CFrame for the camera
    local cameraLookAt = head.Position
    local cameraPosition = cameraLookAt - (rootPart.CFrame.LookVector * cameraDistance) + Vector3.new(0, cameraHeight, 0)
    local targetCFrame = CFrame.new(cameraPosition, cameraLookAt)

    -- Create a smooth tween to move the camera
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local cameraTween = TweenService:Create(camera, tweenInfo, { CFrame = targetCFrame })

    -- Temporarily set the camera to be script-controlled
    camera.CameraType = Enum.CameraType.Scriptable
    cameraTween:Play()

    -- 🤝 When the tween finishes, give camera control back to the player
    cameraTween.Completed:Connect(function()
        camera.CameraType = Enum.CameraType.Custom
    end)
end

-- Connect the function to the button's click event
straightenButton.MouseButton1Click:Connect(onStraightenClick)

-- Parent the final GUI to the player's screen
screenGui.Parent = player:WaitForChild("PlayerGui")
