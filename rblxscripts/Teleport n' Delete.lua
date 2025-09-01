local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "GuaranteedDeleteGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 480, 0, 240)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 26)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 17
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Guaranteed Timer Deleter (Teleport + Delete)"

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0.22, -8, 0, 34)
startBtn.Position = UDim2.new(0, 10, 0, 42)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 16
startBtn.BackgroundColor3 = Color3.fromRGB(90, 190, 90)

local teleportToggle = Instance.new("TextButton", frame)
teleportToggle.Size = UDim2.new(0.22, -8, 0, 34)
teleportToggle.Position = UDim2.new(0.24, 8, 0, 42)
teleportToggle.Text = "Teleport: On"
teleportToggle.Font = Enum.Font.SourceSans
teleportToggle.TextSize = 14
teleportToggle.BackgroundColor3 = Color3.fromRGB(100,150,255)

local secondsBox = Instance.new("TextBox", frame)
secondsBox.Size = UDim2.new(0.18, -8, 0, 34)
secondsBox.Position = UDim2.new(0.48, 16, 0, 42)
secondsBox.PlaceholderText = "Seconds"
secondsBox.Text = "60"
secondsBox.Font = Enum.Font.SourceSans
secondsBox.TextSize = 14
secondsBox.ClearTextOnFocus = false
secondsBox.BackgroundColor3 = Color3.fromRGB(55,55,55)
secondsBox.TextColor3 = Color3.new(1,1,1)

local infoLabel = Instance.new("TextLabel", frame)
infoLabel.Size = UDim2.new(0.32, -8, 0, 34)
infoLabel.Position = UDim2.new(0.66, 24, 0, 42)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 14
infoLabel.TextColor3 = Color3.fromRGB(220,220,220)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Text = "Total: 0  •  Progress: 0/0"

local timeLabel = Instance.new("TextLabel", frame)
timeLabel.Size = UDim2.new(1, -20, 0, 20)
timeLabel.Position = UDim2.new(0, 10, 0, 86)
timeLabel.BackgroundTransparency = 1
timeLabel.Font = Enum.Font.SourceSans
timeLabel.TextSize = 14
timeLabel.TextColor3 = Color3.fromRGB(200,200,200)
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.Text = "Time Left: 01:00"

local leftLabel = Instance.new("TextLabel", frame)
leftLabel.Size = UDim2.new(1, -20, 0, 18)
leftLabel.Position = UDim2.new(0, 10, 0, 108)
leftLabel.BackgroundTransparency = 1
leftLabel.Font = Enum.Font.SourceSans
leftLabel.TextSize = 14
leftLabel.TextColor3 = Color3.fromRGB(200,200,200)
leftLabel.TextXAlignment = Enum.TextXAlignment.Left
leftLabel.Text = "Objects Left: 0"

local progressBG = Instance.new("Frame", frame)
progressBG.Size = UDim2.new(1, -20, 0, 18)
progressBG.Position = UDim2.new(0, 10, 0, 134)
progressBG.BackgroundColor3 = Color3.fromRGB(60,60,60)
progressBG.BorderSizePixel = 0

local progressFill = Instance.new("Frame", progressBG)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(100,200,100)
progressFill.BorderSizePixel = 0

local percentLabel = Instance.new("TextLabel", progressBG)
percentLabel.Size = UDim2.new(1, 0, 1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Font = Enum.Font.SourceSansBold
percentLabel.TextSize = 12
percentLabel.TextColor3 = Color3.fromRGB(0,0,0)
percentLabel.Text = "0%"

local note = Instance.new("TextLabel", frame)
note.Size = UDim2.new(1, -20, 0, 18)
note.Position = UDim2.new(0, 10, 0, 156)
note.BackgroundTransparency = 1
note.Font = Enum.Font.SourceSans
note.TextSize = 12
note.TextColor3 = Color3.fromRGB(180,180,180)
note.Text = "Will teleport to each target (if enabled) then delete. Enter seconds -> Start."

do
	local dragging = false
	local dragInput, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	RunService.RenderStepped:Connect(function()
		if dragInput and dragging and dragStart and startPos then
			local delta = dragInput.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function getAnyRootPart()
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then return root end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("BasePart") then return v end
	end
	return nil
end

local function fmtTimeLeft(sec)
	if sec < 0 then sec = 0 end
	sec = math.floor(sec + 0.5)
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("Time Left: %02d:%02d", m, s)
end

local function collectFadeTargets(inst)
	local out = {}
	if not inst then return out end
	local ok = pcall(function() local _ = inst.Transparency end)
	if ok and inst:IsA("BasePart") then table.insert(out, inst) end
	for _, d in ipairs(inst:GetDescendants()) do
		local ok2 = pcall(function() local _ = d.Transparency end)
		if ok2 and d:IsA("BasePart") then table.insert(out, d) end
	end
	return out
end

local function fadeThenDestroy(part, dur)
	if not part or not part.Parent then return end
	local items = collectFadeTargets(part)
	local ti = TweenInfo.new(math.max(0.001, dur), Enum.EasingStyle.Linear)
	local tweens = {}
	for _, obj in ipairs(items) do
		if obj and obj.Parent then
			local ok = pcall(function() local _ = obj.Transparency end)
			if ok then
				local tw = TweenService:Create(obj, ti, {Transparency = 1})
				table.insert(tweens, tw)
			end
		end
	end
	for _, tw in ipairs(tweens) do pcall(function() tw:Play() end) end
	local finishAt = os.clock() + math.max(0.001, dur)
	while os.clock() < finishAt do
		if not part or not part.Parent then return end
		RunService.Heartbeat:Wait()
	end
	if part and part.Parent then pcall(function() part:Destroy() end) end
end

local function instantDestroy(part)
	if part and part.Parent then pcall(function() part:Destroy() end) end
end

local function snapshotNearestFirst()
	local arr = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") and not inst:IsDescendantOf(player.Character or {}) then
			table.insert(arr, inst)
		end
	end
	local root = getAnyRootPart()
	if root then
		table.sort(arr, function(a, b)
			if not a.Parent then return false end
			if not b.Parent then return true end
			return (root.Position - a.Position).Magnitude < (root.Position - b.Position).Magnitude
		end)
	end
	return arr
end

local function updateUI(total, done)
	total = total or 0
	done = done or 0
	if done < 0 then done = 0 end
	if done > total then done = total end
	infoLabel.Text = string.format("Total: %d  •  Progress: %d/%d", total, done, total)
	leftLabel.Text = string.format("Objects Left: %d", math.max(0, total - done))
	local pct = (total > 0) and math.clamp(done / total, 0, 1) or 1
	progressFill.Size = UDim2.new(pct, 0, 1, 0)
	percentLabel.Text = string.format("%d%%", math.floor(pct * 100 + 0.5))
end

local function readDuration()
	local n = tonumber(secondsBox.Text)
	if not n or n <= 0 then return 60 end
	n = math.floor(n)
	n = math.clamp(n, 1, 3600)
	return n
end

local running = false
local teleportEnabled = true

teleportToggle.MouseButton1Click:Connect(function()
	teleportEnabled = not teleportEnabled
	if teleportEnabled then
		teleportToggle.Text = "Teleport: On"
		teleportToggle.BackgroundColor3 = Color3.fromRGB(100,150,255)
	else
		teleportToggle.Text = "Teleport: Off"
		teleportToggle.BackgroundColor3 = Color3.fromRGB(110,110,110)
	end
end)

local function findNextExistingIndex(list, startIdx)
	for j = startIdx, #list do
		local p = list[j]
		if p and p.Parent then
			return j
		end
	end
	return nil
end

local function guaranteedDelete()
	if running then return end
	running = true
	startBtn.Text = "Stop"
	startBtn.BackgroundColor3 = Color3.fromRGB(200,100,100)

	local duration = readDuration()
	local list = snapshotNearestFirst()
	local total = #list
	local done = 0
	updateUI(total, done)

	if total == 0 then
		timeLabel.Text = fmtTimeLeft(0)
		startBtn.Text = "Start"
		startBtn.BackgroundColor3 = Color3.fromRGB(90,190,90)
		running = false
		return
	end

	local startT = os.clock()
	local endT = startT + duration
	local MIN_FADE = 0.01
	local MAX_FADE = 0.6
	local SAFETY = 0.01

	task.spawn(function()
		while running do
			local now = os.clock()
			timeLabel.Text = fmtTimeLeft(endT - now)
			RunService.Heartbeat:Wait()
		end
	end)

	local i = 1
	while i <= total and running do
		local remainingCount = 0
		for j = i, total do
			local p = list[j]
			if p and p.Parent then remainingCount = remainingCount + 1 end
		end
		if remainingCount == 0 then break end

		local now = os.clock()
		local remainingTime = endT - now
		local capacity = 0
		if remainingTime > SAFETY then
			capacity = math.floor((remainingTime - SAFETY) / MIN_FADE)
		else
			capacity = 0
		end

		if remainingCount > capacity then
			local toDeleteNow = remainingCount - capacity
			for k = 1, toDeleteNow do
				if not running then break end
				local idx = findNextExistingIndex(list, i)
				if not idx then break end
				local part = list[idx]
				if teleportEnabled and part and part.Parent then
					pcall(function()
						local root = getAnyRootPart()
						if root and root.Parent then
							root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
						end
					end)
				end
				instantDestroy(part)
				done = done + 1
				updateUI(total, done)
				if idx == i then
					i = i + 1
				end
				RunService.Heartbeat:Wait()
			end
			goto continue_main
		end

		local per = (remainingTime - SAFETY) / math.max(1, remainingCount)
		local fadeDur = math.clamp(per * 0.9, MIN_FADE, MAX_FADE)

		local nextIdx = findNextExistingIndex(list, i)
		if not nextIdx then break end
		local part = list[nextIdx]

		if teleportEnabled and part and part.Parent then
			pcall(function()
				local root = getAnyRootPart()
				if root and root.Parent then
					root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
				end
			end)
		end

		if part and part.Parent then
			pcall(function() fadeThenDestroy(part, fadeDur) end)
			done = done + 1
			updateUI(total, done)
		else
			done = done + 1
			updateUI(total, done)
		end

		if nextIdx and nextIdx >= i then
			i = nextIdx + 1
		else
			i = i + 1
		end

		::continue_main::
		RunService.Heartbeat:Wait()
	end

	if running then
		while running do
			local remaining = {}
			for _, inst in ipairs(workspace:GetDescendants()) do
				if inst:IsA("BasePart") and inst.Parent and not inst:IsDescendantOf(player.Character or {}) then
					table.insert(remaining, inst)
				end
			end
			if #remaining == 0 then break end
			for _, part in ipairs(remaining) do
				if not running then break end
				if part and part.Parent then
					if teleportEnabled then
						pcall(function()
							local root = getAnyRootPart()
							if root and root.Parent then
								root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
							end
						end)
					end
					instantDestroy(part)
					if done < total then done = done + 1 end
					updateUI(total, done)
				end
				RunService.Heartbeat:Wait()
			end
		end
	end

	updateUI(total, total)
	timeLabel.Text = fmtTimeLeft(0)
	startBtn.Text = "Start"
	startBtn.BackgroundColor3 = Color3.fromRGB(90,190,90)
	running = false
end

startBtn.MouseButton1Click:Connect(function()
	if running then
		running = false
	else
		task.spawn(guaranteedDelete)
	end
end)

secondsBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local v = tonumber(secondsBox.Text)
		if not v or v <= 0 then secondsBox.Text = "60" else secondsBox.Text = tostring(math.clamp(math.floor(v), 1, 3600)) end
	end
end)
