--[[
	Entity Detector GUI Script
	Detects entities, displays info, provides warnings, and includes a highlight feature.
	Place this LocalScript in StarterPlayer > StarterPlayerScripts.
	Make sure a folder named "Entities" exists in the workspace.
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--// Configuration
local UPDATE_INTERVAL = 0.5 -- Seconds between updates
local ENTITIES_FOLDER = workspace:WaitForChild("Entities")
local NotificationSoundId = "rbxassetid://130835569" -- Default notification sound
local ROOM_STUD_LENGTH = 66.25 -- Length of one room in studs
local ROOM_E_SECTION_LENGTH = 87.5 -- Length of an "E section" room in studs
local isESection = false

--// Player & Character Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera -- Reference to the game's camera

--// State Variables
local allSortedEntities = {}
local currentTargetIndex = 1
local nearestEntity = nil
local lastPositions = {} -- [Instance] -> Vector3
local isViewing = false
local isBlinkingOn = false
local defaultCameraType = camera.CameraType
local defaultCameraCFrame = camera.CFrame

--============================================================================--
--[[                               GUI SETUP                                ]]--
--============================================================================--

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EntityDetectorGUI"
screenGui.ResetOnSpawn = false

-- Create Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 180)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(85, 85, 85)
uiStroke.Thickness = 1
uiStroke.Parent = mainFrame

-- Create UIListLayout for automatic organization
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = mainFrame

-- Create Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.LayoutOrder = 1
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.Text = "ENTITY DETECTOR"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

local titleCorner = uiCorner:Clone()
titleCorner.Parent = titleLabel

-- Create Info Labels
local function createInfoLabel(name, order)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -20, 0, 18)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.LayoutOrder = order
	label.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	label.Text = name .. ": --"
	label.Font = Enum.Font.SourceSans
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = mainFrame
	return label
end

local entityNameLabel = createInfoLabel("Entity", 2)
local distanceLabel = createInfoLabel("Distance", 3)
local speedLabel = createInfoLabel("Speed", 4)
local warningLabel = createInfoLabel("Status", 5)
warningLabel.Font = Enum.Font.SourceSansBold
warningLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Default to green
warningLabel.Text = "Status: Initializing..."

-- Create Button Frame
local buttonFrame = Instance.new("Frame")
buttonFrame.Name = "ButtonFrame"
buttonFrame.Size = UDim2.new(1, 0, 0, 25)
buttonFrame.LayoutOrder = 6
buttonFrame.BackgroundColor3 = mainFrame.BackgroundColor3
buttonFrame.BorderSizePixel = 0
buttonFrame.Parent = mainFrame

local buttonListLayout = Instance.new("UIListLayout")
buttonListLayout.Padding = UDim.new(0, 5)
buttonListLayout.FillDirection = Enum.FillDirection.Horizontal
buttonListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonListLayout.Parent = buttonFrame

-- Create View Button
local viewButton = Instance.new("TextButton")
viewButton.Name = "ViewButton"
viewButton.Size = UDim2.new(0.5, -10, 1, 0)
viewButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
viewButton.Text = "View Nearest Entity"
viewButton.Font = Enum.Font.SourceSansBold
viewButton.TextColor3 = Color3.fromRGB(255, 255, 255)
viewButton.TextSize = 14
viewButton.Parent = buttonFrame

local viewButtonCorner = uiCorner:Clone()
viewButtonCorner.Parent = viewButton

-- Create E-Section Button
local eSectionButton = Instance.new("TextButton")
eSectionButton.Name = "ESectionButton"
eSectionButton.Size = UDim2.new(0.5, -10, 1, 0)
eSectionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
eSectionButton.Text = "E Section"
eSectionButton.Font = Enum.Font.SourceSansBold
eSectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
eSectionButton.TextSize = 14
eSectionButton.Parent = buttonFrame

local eSectionButtonCorner = uiCorner:Clone()
eSectionButtonCorner.Parent = eSectionButton

-- Create Arrow and Arrow Buttons Frame
local arrowFrame = Instance.new("Frame")
arrowFrame.Name = "ArrowFrame"
arrowFrame.Size = UDim2.new(1, 0, 0, 25)
arrowFrame.LayoutOrder = 7
arrowFrame.BackgroundColor3 = mainFrame.BackgroundColor3
arrowFrame.BorderSizePixel = 0
arrowFrame.Parent = mainFrame

local arrowLayout = Instance.new("UIListLayout")
arrowLayout.Padding = UDim.new(0, 5)
arrowLayout.FillDirection = Enum.FillDirection.Horizontal
arrowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
arrowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
arrowLayout.Parent = arrowFrame

-- Create left arrow button
local leftArrow = Instance.new("TextButton")
leftArrow.Name = "LeftArrow"
leftArrow.Size = UDim2.new(0.3, 0, 1, 0)
leftArrow.Text = "<"
leftArrow.Font = Enum.Font.SourceSansBold
leftArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
leftArrow.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
leftArrow.Parent = arrowFrame

-- Create an empty label to separate buttons and display arrow info
local arrowLabel = Instance.new("TextLabel")
arrowLabel.Name = "ArrowLabel"
arrowLabel.Size = UDim2.new(0.4, 0, 1, 0)
arrowLabel.Text = "Target 1/1"
arrowLabel.Font = Enum.Font.SourceSans
arrowLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
arrowLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
arrowLabel.TextSize = 14
arrowLabel.Parent = arrowFrame

-- Create right arrow button
local rightArrow = Instance.new("TextButton")
rightArrow.Name = "RightArrow"
rightArrow.Size = UDim2.new(0.3, 0, 1, 0)
rightArrow.Text = ">"
rightArrow.Font = Enum.Font.SourceSansBold
rightArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
rightArrow.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
rightArrow.Parent = arrowFrame

-- Create Arrow Part (the visual indicator)
local arrow = Instance.new("Part")
arrow.Name = "DetectorArrow"
arrow.Size = Vector3.new(1, 1, 5)
arrow.Shape = Enum.PartType.Cylinder
arrow.Anchored = true
arrow.CanCollide = false
arrow.Transparency = 1
arrow.Parent = workspace

local arrowMesh = Instance.new("SpecialMesh")
arrowMesh.MeshType = Enum.MeshType.FileMesh
arrowMesh.MeshId = "rbxassetid://13045618"
arrowMesh.Scale = Vector3.new(2, 2, 2)
arrowMesh.Parent = arrow

local arrowLight = Instance.new("PointLight")
arrowLight.Color = Color3.fromRGB(255, 255, 0)
arrowLight.Range = 10
arrowLight.Brightness = 3
arrowLight.Parent = arrow


-- Create Highlight object (still useful for UI state, but camera will do the spectating)
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 255, 0)
highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
highlight.FillTransparency = 0.5
highlight.Enabled = false

-- Parent the GUI
screenGui.Parent = playerGui

--============================================================================--
--[[                            HELPER FUNCTIONS                            ]]--
--============================================================================--

-- Makes the GUI draggable on PC and Mobile
local function makeDraggable(guiObject)
	local dragging = false
	local dragStart
	local startPos

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Safely get the primary position of an entity (Model or BasePart)
local function getEntityPosition(entity)
	if entity:IsA("Model") and entity.PrimaryPart then
		return entity.PrimaryPart.Position
	elseif entity:IsA("BasePart") then
		return entity.Position
	end
	return nil
end

-- Show a notification
local function showNotification(message)
	local notifFrame = Instance.new("TextLabel")
	notifFrame.Text = message
	notifFrame.Size = UDim2.new(0, 250, 0, 40)
	notifFrame.Position = UDim2.new(0.5, -125, -0.1, 0)
	notifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	notifFrame.TextColor3 = Color3.fromRGB(255, 255, 0)
	notifFrame.Font = Enum.Font.SourceSansBold
	notifFrame.TextSize = 18
	notifFrame.Parent = screenGui

	local notifCorner = uiCorner:Clone()
	notifCorner.Parent = notifFrame
	
	local sound = Instance.new("Sound")
	sound.SoundId = NotificationSoundId
	sound.Parent = notifFrame
	sound:Play()

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local goalIn = {Position = UDim2.new(0.5, -125, 0.05, 0)}
	local goalOut = {Position = UDim2.new(0.5, -125, -0.1, 0)}

	TweenService:Create(notifFrame, tweenInfo, goalIn):Play()
	task.wait(3)
	TweenService:Create(notifFrame, tweenInfo, goalOut):Play()
	
	game.Debris:AddItem(notifFrame, 1)
end


--============================================================================--
--[[                             EVENT HANDLERS                             ]]--
--============================================================================--

-- Toggle View mode
viewButton.MouseButton1Click:Connect(function()
	isViewing = not isViewing
	
	if isViewing then
		viewButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
		viewButton.Text = "Viewing Nearest..."
		highlight.Enabled = true -- Keep highlight for a visual cue
		if nearestEntity then
			highlight.Parent = nearestEntity
			highlight.Adornee = nearestEntity:IsA("Model") and nearestEntity.PrimaryPart or nearestEntity
			camera.CameraType = Enum.CameraType.Scriptable
		end
	else
		viewButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		viewButton.Text = "View Nearest Entity"
		highlight.Enabled = false
		highlight.Parent = nil
		highlight.Adornee = nil
		camera.CameraType = defaultCameraType
		camera.CFrame = defaultCameraCFrame
	end
end)

-- Toggle E Section mode
eSectionButton.MouseButton1Click:Connect(function()
	isESection = not isESection
	if isESection then
		eSectionButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
		eSectionButton.Text = "E Section Active"
	else
		eSectionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		eSectionButton.Text = "E Section"
	end
end)

-- Cycle to the next nearest entity
rightArrow.MouseButton1Click:Connect(function()
	if #allSortedEntities > 0 then
		currentTargetIndex = currentTargetIndex + 1
		if currentTargetIndex > #allSortedEntities then
			currentTargetIndex = 1
		end
		nearestEntity = allSortedEntities[currentTargetIndex].entity
		highlight.Parent = nearestEntity
		highlight.Adornee = nearestEntity:IsA("Model") and nearestEntity.PrimaryPart or nearestEntity
		arrowLabel.Text = `Target {currentTargetIndex}/{#allSortedEntities}`
	end
end)

-- Cycle to the previous nearest entity
leftArrow.MouseButton1Click:Connect(function()
	if #allSortedEntities > 0 then
		currentTargetIndex = currentTargetIndex - 1
		if currentTargetIndex < 1 then
			currentTargetIndex = #allSortedEntities
		end
		nearestEntity = allSortedEntities[currentTargetIndex].entity
		highlight.Parent = nearestEntity
		highlight.Adornee = nearestEntity:IsA("Model") and nearestEntity.PrimaryPart or nearestEntity
		arrowLabel.Text = `Target {currentTargetIndex}/{#allSortedEntities}`
	end
end)

-- Spawn Notifications
ENTITIES_FOLDER.ChildAdded:Connect(function(child)
	showNotification(`"{child.Name}" has spawned in!`)
end)

-- Despawn Notifications
ENTITIES_FOLDER.ChildRemoved:Connect(function(child)
	showNotification(`"{child.Name}" has despawned!`)
end)


--============================================================================--
--[[                              MAIN LOOP                                 ]]--
--============================================================================--

makeDraggable(mainFrame)

while task.wait(UPDATE_INTERVAL) do
	character = player.Character -- Ensure we always have the latest character model
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")

	if not playerRoot then continue end

	local playerPos = playerRoot.Position
	allSortedEntities = {}
	
	-- Find and sort all entities by distance
	for _, entity in ipairs(ENTITIES_FOLDER:GetChildren()) do
		local entityPos = getEntityPosition(entity)
		if entityPos then
			local distance = (playerPos - entityPos).Magnitude
			table.insert(allSortedEntities, {entity = entity, distance = distance})
		end
	end
	
	table.sort(allSortedEntities, function(a, b)
		return a.distance < b.distance
	end)
	
	-- Set the nearest entity based on the current target index
	if #allSortedEntities > 0 then
		nearestEntity = allSortedEntities[currentTargetIndex].entity
		local minDistance = allSortedEntities[currentTargetIndex].distance
		
		-- Update camera and arrow if we are in "viewing" mode
		if isViewing and nearestEntity then
			local entityPart = nearestEntity:IsA("Model") and nearestEntity.PrimaryPart or nearestEntity
			local cameraPos = entityPart.Position + Vector3.new(0, 10, 10) -- Adjust for desired third-person view
			local newCFrame = CFrame.new(cameraPos, entityPart.Position)
			camera.CFrame = newCFrame
		end

		-- Update the arrow's position and orientation
		if playerRoot and nearestEntity then
			local targetPos = getEntityPosition(nearestEntity)
			local direction = (targetPos - playerRoot.Position).unit
			arrow.CFrame = CFrame.new(playerRoot.Position + direction * 10, targetPos)
			arrow.Transparency = 0
		else
			arrow.Transparency = 1
		end

		-- Convert distance from studs to rooms
		local currentRoomLength = isESection and ROOM_E_SECTION_LENGTH or ROOM_STUD_LENGTH
		local distanceInRooms = minDistance / currentRoomLength

		-- Update Text
		entityNameLabel.Text = "Entity: " .. nearestEntity.Name
		distanceLabel.Text = string.format("Distance: %.1f rooms", distanceInRooms)
		
		-- Calculate Speed and convert to rooms/s
		local entityPos = getEntityPosition(nearestEntity)
		if lastPositions[nearestEntity] then
			local speedInStuds = (entityPos - lastPositions[nearestEntity]).Magnitude / UPDATE_INTERVAL
			local speedInRooms = speedInStuds / currentRoomLength
			speedLabel.Text = string.format("Speed: %.1f rooms/s", speedInRooms)
		else
			speedLabel.Text = "Speed: Calculating..."
		end
		lastPositions[nearestEntity] = entityPos

		-- Update Warning System & Colors
		local distanceThresholds = {
			danger = 250 / currentRoomLength, -- 250 studs
			caution = 500 / currentRoomLength, -- 500 studs
			safe = 1000 / currentRoomLength -- 1000 studs
		}

		if distanceInRooms <= distanceThresholds.danger then
			warningLabel.Text = "Status: DANGER! Too Close!"
			-- Blinking effect
			isBlinkingOn = not isBlinkingOn
			warningLabel.TextColor3 = isBlinkingOn and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(150, 0, 0)
		elseif distanceInRooms <= distanceThresholds.caution then
			warningLabel.Text = "Status: Caution"
			warningLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Yellow
		elseif distanceInRooms <= distanceThresholds.safe then
			warningLabel.Text = "Status: Safe to Teleport"
			warningLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Green
		else
			warningLabel.Text = "Status: Entity Detected"
			warningLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
		end
		
		-- Update Highlight if active
		if isViewing then
			highlight.Parent = nearestEntity
			highlight.Adornee = nearestEntity:IsA("Model") and nearestEntity.PrimaryPart or nearestEntity
		end
		
	else
		-- Reset GUI to default state if no entities are found
		entityNameLabel.Text = "Entity: --"
		distanceLabel.Text = "Distance: --"
		speedLabel.Text = "Speed: --"
		warningLabel.Text = "Status: No entities detected"
		warningLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		
		-- Disable highlight, arrow, and reset camera if no entity is available
		if isViewing then
			highlight.Enabled = false
			highlight.Parent = nil
			highlight.Adornee = nil
			camera.CameraType = defaultCameraType
			camera.CFrame = defaultCameraCFrame
			isViewing = false
			viewButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			viewButton.Text = "View Nearest Entity"
		end
		arrow.Transparency = 1
	end
	
	-- Clean up old positions from the tracking table to prevent memory leaks
	local currentEntities = {}
	for _, child in ipairs(ENTITIES_FOLDER:GetChildren()) do
		currentEntities[child] = true
	end
	for entity, _ in pairs(lastPositions) do
		if not currentEntities[entity] then
			lastPositions[entity] = nil
		end
	end

	-- Ensure currentTargetIndex is valid after entity list is updated
	if currentTargetIndex > #allSortedEntities and #allSortedEntities > 0 then
		currentTargetIndex = #allSortedEntities
	elseif #allSortedEntities == 0 then
		currentTargetIndex = 1
	end
	
	arrowLabel.Text = `Target {currentTargetIndex}/{#allSortedEntities}`
end

---
[Roblox Lua Basics: Find the Closest Player to Any Target](https://www.youtube.com/watch?v=3f3ir2csGf4)
This video is relevant because it explains the fundamental concept of finding the closest target in Roblox, which is a core part of the updated script's functionality.
http://googleusercontent.com/youtube_content/1 *YouTube video views will be stored in your YouTube History, and your data will be stored and used by YouTube according to its [Terms of Service](https://www.youtube.com/static?template=terms)*



