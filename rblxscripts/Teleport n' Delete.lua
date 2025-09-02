local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local task = task

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GuaranteedDeleteWithUndoGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 220)
frame.Position = UDim2.new(0.5, -210, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -24, 0, 28)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Guaranteed Fast Deleter (Undo + Teleport)"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(230,230,230)
title.TextXAlignment = Enum.TextXAlignment.Left

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0.28, -12, 0, 36)
startBtn.Position = UDim2.new(0, 12, 0, 42)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 16
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)

local undoBtn = Instance.new("TextButton", frame)
undoBtn.Size = UDim2.new(0.12, -6, 0, 36)
undoBtn.Position = UDim2.new(0.30, 8, 0, 42)
undoBtn.Text = "Undo"
undoBtn.Font = Enum.Font.SourceSansBold
undoBtn.TextSize = 14
undoBtn.BackgroundColor3 = Color3.fromRGB(200,160,80)

local teleportToggle = Instance.new("TextButton", frame)
teleportToggle.Size = UDim2.new(0.20, -6, 0, 36)
teleportToggle.Position = UDim2.new(0.42, 6, 0, 42)
teleportToggle.Text = "Teleport: On"
teleportToggle.Font = Enum.Font.SourceSans
teleportToggle.TextSize = 14
teleportToggle.BackgroundColor3 = Color3.fromRGB(100,150,255)

local secondsBox = Instance.new("TextBox", frame)
secondsBox.Size = UDim2.new(0.28, -12, 0, 36)
secondsBox.Position = UDim2.new(0.62, 6, 0, 42)
secondsBox.PlaceholderText = "Seconds"
secondsBox.Text = "60"
secondsBox.Font = Enum.Font.SourceSans
secondsBox.TextSize = 14
secondsBox.BackgroundColor3 = Color3.fromRGB(48,48,48)
secondsBox.TextColor3 = Color3.fromRGB(230,230,230)
secondsBox.ClearTextOnFocus = false

local timeLabel = Instance.new("TextLabel", frame)
timeLabel.Size = UDim2.new(1, -24, 0, 22)
timeLabel.Position = UDim2.new(0, 12, 0, 86)
timeLabel.BackgroundTransparency = 1
timeLabel.Font = Enum.Font.SourceSans
timeLabel.TextSize = 14
timeLabel.TextColor3 = Color3.fromRGB(200,200,200)
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.Text = "Time Left: 00:00:00.00"

local leftLabel = Instance.new("TextLabel", frame)
leftLabel.Size = UDim2.new(1, -24, 0, 18)
leftLabel.Position = UDim2.new(0, 12, 0, 110)
leftLabel.BackgroundTransparency = 1
leftLabel.Font = Enum.Font.SourceSans
leftLabel.TextSize = 14
leftLabel.TextColor3 = Color3.fromRGB(200,200,200)
leftLabel.TextXAlignment = Enum.TextXAlignment.Left
leftLabel.Text = "Objects Left: 0"

local infoLabel = Instance.new("TextLabel", frame)
infoLabel.Size = UDim2.new(1, -24, 0, 18)
infoLabel.Position = UDim2.new(0, 12, 0, 128)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 14
infoLabel.TextColor3 = Color3.fromRGB(200,200,200)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Text = "Total: 0  •  Progress: 0/0"

local progressBG = Instance.new("Frame", frame)
progressBG.Size = UDim2.new(1, -24, 0, 18)
progressBG.Position = UDim2.new(0, 12, 0, 152)
progressBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
progressBG.BorderSizePixel = 0

local progressFill = Instance.new("Frame", progressBG)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 150)

local percentLabel = Instance.new("TextLabel", progressBG)
percentLabel.Size = UDim2.new(1, 0, 1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Font = Enum.Font.SourceSansBold
percentLabel.TextSize = 12
percentLabel.TextColor3 = Color3.fromRGB(10,10,10)
percentLabel.Text = "0%"

local note = Instance.new("TextLabel", frame)
note.Size = UDim2.new(1, -24, 0, 20)
note.Position = UDim2.new(0, 12, 0, 176)
note.BackgroundTransparency = 1
note.Font = Enum.Font.SourceSans
note.TextSize = 12
note.TextColor3 = Color3.fromRGB(160,160,160)
note.TextXAlignment = Enum.TextXAlignment.Left
note.Text = "Deletes BaseParts (excludes your character). Timer -> instant delete at 0."

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

local function formatTime_hh_mm_ss_cs(t)
	if t < 0 then t = 0 end
	local hours = math.floor(t / 3600)
	local mins = math.floor((t % 3600) / 60)
	local secs = math.floor(t % 60)
	local centis = math.floor((t - math.floor(t)) * 100 + 0.5)
	if centis >= 100 then centis = 99 end
	return string.format("%02d:%02d:%02d.%02d", hours, mins, secs, centis)
end

local function collectFadeTargets(inst)
	local out = {}
	if not inst then return out end
	if inst:IsA("BasePart") then table.insert(out, inst) end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(out, d) end
	end
	return out
end

local function fadeThenDestroy(inst, dur)
	if not inst or not inst.Parent then return end
	local parts = collectFadeTargets(inst)
	local ti = TweenInfo.new(math.max(0.001, dur), Enum.EasingStyle.Linear)
	local tweens = {}
	for _, p in ipairs(parts) do
		if p and p.Parent then
			local ok = pcall(function() local _ = p.Transparency end)
			if ok then table.insert(tweens, TweenService:Create(p, ti, {Transparency = 1})) end
		end
	end
	for _, tw in ipairs(tweens) do pcall(function() tw:Play() end) end
	local finishAt = os.clock() + math.max(0.001, dur)
	while os.clock() < finishAt do
		if not inst or not inst.Parent then return end
		RunService.Heartbeat:Wait()
	end
	if inst and inst.Parent then pcall(function() inst:Destroy() end) end
end

local function instantDestroy(inst)
	if inst and inst.Parent then pcall(function() inst:Destroy() end) end
end

local function buildSnapshot()
	local arr = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") and not inst:IsDescendantOf(player.Character or {}) then
			table.insert(arr, inst)
		end
	end
	local root = getAnyRootPart()
	if root then
		table.sort(arr, function(a,b)
			if not a.Parent then return false end
			if not b.Parent then return true end
			return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
		end)
	end
	return arr
end

local function updateUI(total, processed)
	total = total or 0
	processed = processed or 0
	local left = math.max(0, total - processed)
	infoLabel.Text = string.format("Total: %d  •  Progress: %d/%d", total, processed, total)
	leftLabel.Text = "Objects Left: " .. tostring(left)
	local pct = (total > 0) and math.clamp(processed / total, 0, 1) or 1
	progressFill.Size = UDim2.new(pct, 0, 1, 0)
	percentLabel.Text = string.format("%d%%", math.floor(pct * 100 + 0.5))
end

local function readSeconds()
	local n = tonumber(secondsBox.Text)
	if not n or n <= 0 then return 60 end
	n = math.floor(n)
	return math.clamp(n, 1, 36000)
end

local function findNextIndex(list, startIdx)
	for i = startIdx, #list do
		local p = list[i]
		if p and p.Parent then return i end
	end
	return nil
end

local function instantDeleteAllRemaining(snapshot)
	for _, p in ipairs(snapshot) do
		if p and p.Parent and not p:IsDescendantOf(player.Character or {}) then
			pcall(function() p:Destroy() end)
		end
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") and inst.Parent and not inst:IsDescendantOf(player.Character or {}) then
			pcall(function() inst:Destroy() end)
		end
	end
end

local running = false
local teleportEnabled = true
local lastBackup = nil
local lastDuration = nil

teleportToggle.MouseButton1Click:Connect(function()
	teleportEnabled = not teleportEnabled
	if teleportEnabled then
		teleportToggle.Text = "Teleport: On"
		teleportToggle.BackgroundColor3 = Color3.fromRGB(100,150,255)
	else
		teleportToggle.Text = "Teleport: Off"
		teleportToggle.BackgroundColor3 = Color3.fromRGB(100,100,100)
	end
end)

startBtn.MouseButton1Click:Connect(function()
	if running then return end
	local seconds = readSeconds()
	lastDuration = seconds
	local snapshot = buildSnapshot()
	local total = #snapshot
	if total == 0 then
		timeLabel.Text = "Time Left: 00:00:00.00"
		updateUI(0,0)
		return
	end

	local backup = {}
	for i, part in ipairs(snapshot) do
		if part and part.Parent then
			local ok, clone = pcall(function() return part:Clone() end)
			local entry = { clone = nil, originalParent = nil, cframe = nil, transparency = nil }
			if ok and clone then
				entry.clone = clone
				entry.originalParent = part.Parent
				entry.cframe = (pcall(function() return part.CFrame end) and part.CFrame) or nil
				entry.transparency = (pcall(function() return part.Transparency end) and part.Transparency) or 0
				clone.Parent = nil
			end
			table.insert(backup, entry)
		else
			table.insert(backup, { clone = nil, originalParent = nil, cframe = nil, transparency = nil })
		end
	end
	lastBackup = backup
	lastDuration = seconds

	running = true
	startBtn.Text = "Running..."
	startBtn.BackgroundColor3 = Color3.fromRGB(200,100,100)

	task.spawn(function()
		local processed = 0
		updateUI(total, processed)
		local startT = os.clock()
		local endT = startT + seconds
		local i = 1
		local MIN_FADE = 0.01
		local MAX_FADE = 0.6
		local SAFETY = 0.005

		while running do
			local now = os.clock()
			local remainingTime = endT - now
			if remainingTime <= 0 then
				instantDeleteAllRemaining(snapshot)
				processed = total
				updateUI(total, processed)
				break
			end

			local remainingCount = 0
			for j = i, total do
				local p = snapshot[j]
				if p and p.Parent then remainingCount = remainingCount + 1 end
			end

			if remainingCount == 0 then
				local found = false
				for _, inst in ipairs(workspace:GetDescendants()) do
					if inst:IsA("BasePart") and inst.Parent and not inst:IsDescendantOf(player.Character or {}) then found = true; break end
				end
				if not found then break end
			end

			local framesLeft = math.max(1, math.floor(remainingTime * 60))
			local toDeleteThisFrame = math.ceil(math.max(1, remainingCount) / framesLeft)
			local perItemTime = (remainingTime - SAFETY) / math.max(1, remainingCount)
			local fadeDur = math.clamp(perItemTime * 0.9, MIN_FADE, MAX_FADE)

			for k = 1, toDeleteThisFrame do
				if not running then break end
				local nextIdx = findNextIndex(snapshot, i)
				if not nextIdx then break end
				local part = snapshot[nextIdx]
				if part and part.Parent then
					if teleportEnabled then
						pcall(function()
							local root = getAnyRootPart()
							if root and root.Parent then
								root.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
							end
						end)
					end
					if fadeDur <= 0.012 or remainingTime <= 0.02 then
						task.spawn(function() instantDestroy(part) end)
					else
						task.spawn(function() fadeThenDestroy(part, fadeDur) end)
					end
				end
				processed = processed + 1
				updateUI(total, processed)
				if nextIdx and nextIdx >= i then i = nextIdx + 1 end
			end

			timeLabel.Text = "Time Left: " .. formatTime_hh_mm_ss_cs(math.max(0, endT - os.clock()))
			RunService.Heartbeat:Wait()
		end

		instantDeleteAllRemaining(snapshot)
		updateUI(total, total)
		timeLabel.Text = "Time Left: 00:00:00.00"
		running = false
		startBtn.Text = "Start"
		startBtn.BackgroundColor3 = Color3.fromRGB(80,200,120)
	end)
end)

undoBtn.MouseButton1Click:Connect(function()
	if not lastBackup or #lastBackup == 0 then return end
	if running then
		running = false
		startBtn.Text = "Start"
		startBtn.BackgroundColor3 = Color3.fromRGB(80,200,120)
	end
	local backup = lastBackup
	local seconds = lastDuration or readSeconds()
	task.spawn(function()
		local total = #backup
		updateUI(total, 0)
		local startT = os.clock()
		local endT = startT + seconds
		local processed = 0

		for _, e in ipairs(backup) do
			if e.clone then
				local parts = collectFadeTargets(e.clone)
				for _, p in ipairs(parts) do
					if p then p.Transparency = 1 end
				end
			end
		end

		local i = 1
		while i <= total do
			local now = os.clock()
			local remainingTime = endT - now
			if remainingTime <= 0 then
				for j = i, total do
					local e = backup[j]
					if e and e.clone then
						local parent = (e.originalParent and e.originalParent.Parent) and e.originalParent or workspace
						-- teleport to this object's stored CFrame before restoring (if enabled)
						if teleportEnabled and e.cframe then
							pcall(function()
								local root = getAnyRootPart()
								if root and root.Parent then
									root.CFrame = CFrame.new(e.cframe.p + Vector3.new(0,3,0))
								end
							end)
						end
						e.clone.Parent = parent
						if e.cframe then
							pcall(function()
								if e.clone:IsA("BasePart") then
									e.clone.CFrame = e.cframe
								else
									if e.clone.PrimaryPart then e.clone:SetPrimaryPartCFrame(e.cframe) end
								end
							end)
						end
						task.spawn(function()
							local parts = collectFadeTargets(e.clone)
							local ti = TweenInfo.new(0.04, Enum.EasingStyle.Linear)
							for _, p in ipairs(parts) do
								if p and p.Parent then
									p.Transparency = 1
									local ok, tw = pcall(function() return TweenService:Create(p, ti, {Transparency = 0}) end)
									if ok and tw then pcall(function() tw:Play() end) end
								end
							end
						end)
					end
					processed = processed + 1
					updateUI(total, processed)
				end
				break
			end

			local remainingCount = 0
			for j = i, total do
				local e = backup[j]
				if e and e.clone then remainingCount = remainingCount + 1 end
			end
			if remainingCount == 0 then break end

			local framesLeft = math.max(1, math.floor(remainingTime * 60))
			local toAddThisFrame = math.ceil(remainingCount / framesLeft)
			toAddThisFrame = math.max(1, toAddThisFrame)

			for k = 1, toAddThisFrame do
				local idx = nil
				for j = i, total do
					if backup[j] and backup[j].clone then idx = j; break end
				end
				if not idx then break end
				local e = backup[idx]
				local c = e.clone
				if c then
					local parent = (e.originalParent and e.originalParent.Parent) and e.originalParent or workspace
					-- teleport to this object's stored CFrame before restoring (if enabled)
					if teleportEnabled and e.cframe then
						pcall(function()
							local root = getAnyRootPart()
							if root and root.Parent then
								root.CFrame = CFrame.new(e.cframe.p + Vector3.new(0,3,0))
							end
						end)
					end
					c.Parent = parent
					if e.cframe then
						pcall(function()
							if c:IsA("BasePart") then
								c.CFrame = e.cframe
							else
								if c.PrimaryPart then c:SetPrimaryPartCFrame(e.cframe) end
							end
						end)
					end
					task.spawn(function()
						local parts = collectFadeTargets(c)
						local dur = math.clamp((remainingTime / math.max(1, remainingCount)) * 0.9, 0.01, 0.5)
						local ti = TweenInfo.new(dur, Enum.EasingStyle.Linear)
						for _, p in ipairs(parts) do
							if p and p.Parent then
								p.Transparency = 1
								local ok, tw = pcall(function() return TweenService:Create(p, ti, {Transparency = 0}) end)
								if ok and tw then pcall(function() tw:Play() end) end
							end
						end
					end)
				end
				processed = processed + 1
				updateUI(total, processed)
				if idx and idx >= i then i = idx + 1 end
			end

			timeLabel.Text = "Time Left: " .. formatTime_hh_mm_ss_cs(math.max(0, endT - os.clock()))
			RunService.Heartbeat:Wait()
		end

		updateUI(total, total)
		timeLabel.Text = "Time Left: 00:00:00.00"
	end)
end)

secondsBox.FocusLost:Connect(function(enter)
	if enter then
		local n = tonumber(secondsBox.Text)
		if not n or n <= 0 then secondsBox.Text = "60" else secondsBox.Text = tostring(math.clamp(math.floor(n), 1, 36000)) end
	end
end)
