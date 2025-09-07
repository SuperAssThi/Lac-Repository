-- LocalScript (place in StarterPlayerScripts)
-- Enhanced NextBots Viewer + Auto-Outrun (high-frequency calculations & improved accuracy)
-- Features:
--  • Shows chams (Highlight or SelectionBox fallback), compact Billboards, and 2D tracers for models in workspace.NextBots (fallback Nextbots).
--  • Auto-Outrun walks the player (Humanoid:MoveTo) and continuously replans.
--  • This edit focuses on making Auto-Outrun perform up to MAX_CALCS_PER_SECOND (default 100) calculations/actions per second,
--    improving accuracy by using velocity-based prediction, more sampling, and more aggressive re-issuing of MoveTo.
--  • Uses only Roblox public APIs. All overlays are parented to PlayerGui (local-only).
--
-- Required: workspace.NextBots (or workspace.Nextbots) containing Model instances with at least one BasePart each.
-- WARNING (inline): Automated movement may be considered cheating on multiplayer servers. Use in testing/private servers only.

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = workspace

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- ========== CONFIG (tweak these) ==========
local NEXTBOTS_NAMES = {"NextBots", "Nextbots"}
local DISTANCE_PRECISION = 1
local TRACER_THICKNESS = 2
local BILLBOARD_SIZE = UDim2.new(0, 120, 0, 30)
local BILLBOARD_OFFSET = Vector3.new(0, 2.5, 0)

-- Auto-Outrun tuning
local MAX_CALCS_PER_SECOND = 100            -- target calculations/actions per second (best-effort)
local SAFE_SAMPLE_COUNT = 36                -- more samples -> more accurate but costlier
local SAFE_POINT_DISTANCE = 18
local SAFE_POINT_MIN_DISTANCE = 8
local PATH_AGENT_RADIUS = 2
local PATH_AGENT_HEIGHT = 5
local WAYPOINT_REACHED_RADIUS = 3
local WAYPOINT_MOVE_REISSUE_INTERVAL = 0.08 -- re-issue MoveTo frequently
local CHASE_DETECT_DISTANCE = 60
local CHASE_VELOCITY_DOT_THRESHOLD = 0.35
local PREDICTION_TIME = 0.55                 -- seconds ahead to predict bot positions for scoring
local REPLAN_HEAVY_FRAME_INTERVAL = 0       -- heavy compute every frame check (we control via MAX_CALCS_PER_SECOND)
local CAMERA_STYLE = "yaw-only"             -- "none" | "yaw-only" | "scriptable"
local ENABLE_CURVE_PATHS = true             -- use simple smoothing for visual arrows
local BLACKLIST_NAMES = { "Lava", "KillPart" }  -- names to treat as obstacles if found in Workspace
local DEBUG_MODE = false                    -- verbose prints & debug markers
-- clamp safe values
if MAX_CALCS_PER_SECOND < 10 then MAX_CALCS_PER_SECOND = 10 end
if MAX_CALCS_PER_SECOND > 200 then MAX_CALCS_PER_SECOND = 200 end
-- ============================================

-- Derived intervals
local CALC_INTERVAL = 1 / MAX_CALCS_PER_SECOND

-- UI setup (draggable, mobile-friendly)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NextbotViewer"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.new(0, 300, 0, 102)
window.Position = UDim2.new(0.02, 0, 0.08, 0)
window.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
window.BorderSizePixel = 0
window.AnchorPoint = Vector2.new(0, 0)
window.Parent = screenGui
window.Active = true
window.ClipsDescendants = false

local titleBar = Instance.new("Frame", window)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Name = "Title"
title.Size = UDim2.new(1, -12, 1, 0)
title.Position = UDim2.new(0, 6, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Nextbot Viewer"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Font = Enum.Font.SourceSansSemibold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

local showButton = Instance.new("TextButton", window)
showButton.Name = "ShowButton"
showButton.Size = UDim2.new(0.5, -10, 0, 40)
showButton.Position = UDim2.new(0, 6, 0, 44)
showButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
showButton.BorderSizePixel = 0
showButton.Text = "Show NextBots"
showButton.TextColor3 = Color3.fromRGB(230,230,230)
showButton.Font = Enum.Font.SourceSans
showButton.TextSize = 14

local autoButton = Instance.new("TextButton", window)
autoButton.Name = "AutoButton"
autoButton.Size = UDim2.new(0.5, -10, 0, 40)
autoButton.Position = UDim2.new(0.5, 4, 0, 44)
autoButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
autoButton.BorderSizePixel = 0
autoButton.Text = "Auto-Outrun: Off"
autoButton.TextColor3 = Color3.fromRGB(230,230,230)
autoButton.Font = Enum.Font.SourceSans
autoButton.TextSize = 13

-- make draggable (touch + mouse)
do
	local dragging, dragStart, startPos = false, nil, nil
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local delta = inp.Position - dragStart
			window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Storage
local overlays = {} -- model -> { highlight, billboard, nameLabel, distLabel, tracer, part, selectionBoxes (if fallback) }
local enabled = false
local autoOutrunEnabled = false
local updateConn = nil
local folderChildConns = {}
local NEXTBOTS_PATH = nil

-- Reusable RaycastParams to avoid allocations
local rayParamsLine = RaycastParams.new()
rayParamsLine.FilterType = Enum.RaycastFilterType.Blacklist
rayParamsLine.FilterDescendantsInstances = {} -- will set to {NEXTBOTS_PATH} later
rayParamsLine.IgnoreWater = true

-- Helper: find NextBots folder (prefers exact "NextBots")
local function getNextBotsFolder()
	for _, name in ipairs(NEXTBOTS_NAMES) do
		local f = Workspace:FindFirstChild(name)
		if f and f:IsA("Folder") then return f end
	end
	for _, name in ipairs(NEXTBOTS_NAMES) do
		local ok, res = pcall(function() return Workspace:WaitForChild(name, 3) end)
		if ok and res then return res end
	end
	return nil
end

-- Helper: find a primary/base part for a model
local function findModelPrimaryPart(model)
	if not model then return nil end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

-- Create overlay for a model
local function createOverlayFor(model)
	if overlays[model] then return end
	local part = findModelPrimaryPart(model)
	if not part then return end

	local highlight
	-- try Highlight in a pcall (some older clients may not support)
	local okHighlight
	okHighlight, highlight = pcall(function()
		local h = Instance.new("Highlight")
		h.Name = "NextbotHighlight"
		h.Adornee = model
		h.Parent = playerGui
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillTransparency = 0.6
		h.OutlineTransparency = 0
		h.OutlineColor = Color3.fromRGB(255,120,80)
		h.FillColor = Color3.fromRGB(255,150,120)
		return h
	end)
	local selectionBoxes = nil
	if not okHighlight or not highlight then
		-- fallback: per-part SelectionBox instances (slower)
		selectionBoxes = {}
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				local sb = Instance.new("SelectionBox")
				sb.Adornee = p
				sb.LineThickness = 0.02
				sb.SurfaceTransparency = 0.8
				sb.Parent = playerGui
				table.insert(selectionBoxes, sb)
			end
		end
	end

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NextbotBillboard"
	billboard.Adornee = part
	billboard.Size = BILLBOARD_SIZE
	billboard.StudsOffset = BILLBOARD_OFFSET
	billboard.AlwaysOnTop = true
	billboard.Parent = playerGui

	local bg = Instance.new("Frame", billboard)
	bg.Size = UDim2.new(1,0,1,0)
	bg.BackgroundTransparency = 0.6
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = Color3.fromRGB(10,10,10)

	local nameLabel = Instance.new("TextLabel", bg)
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -8, 0.5, -2)
	nameLabel.Position = UDim2.new(0, 4, 0, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = model.Name
	nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextSize = 14
	nameLabel.TextYAlignment = Enum.TextYAlignment.Top

	local distLabel = Instance.new("TextLabel", bg)
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, -8, 0.5, -2)
	distLabel.Position = UDim2.new(0, 4, 0.5, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "0.0 studs"
	distLabel.TextColor3 = Color3.fromRGB(220,220,220)
	distLabel.Font = Enum.Font.SourceSans
	distLabel.TextSize = 12

	-- tracer (screen)
	local tracer = Instance.new("Frame", screenGui)
	tracer.Name = "Tracer"
	tracer.Size = UDim2.new(0,0,0,TRACER_THICKNESS)
	tracer.AnchorPoint = Vector2.new(0.5,0.5)
	tracer.BorderSizePixel = 0
	tracer.Rotation = 0
	tracer.Transparency = 0
	tracer.BackgroundColor3 = Color3.fromRGB(255,160,120)
	tracer.Visible = false

	overlays[model] = {
		highlight = highlight,
		selectionBoxes = selectionBoxes,
		billboard = billboard,
		nameLabel = nameLabel,
		distLabel = distLabel,
		tracer = tracer,
		part = part,
	}
end

local function clearOverlays()
	for m, data in pairs(overlays) do
		if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
		if data.selectionBoxes then
			for _, sb in ipairs(data.selectionBoxes) do if sb and sb.Parent then sb:Destroy() end end
		end
		if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
		if data.tracer and data.tracer.Parent then data.tracer:Destroy() end
	end
	overlays = {}
end

-- Refresh overlays for current NextBots folder
local function refreshOverlays()
	if not NEXTBOTS_PATH or not NEXTBOTS_PATH.Parent then NEXTBOTS_PATH = getNextBotsFolder() end
	if not NEXTBOTS_PATH then return end
	-- update rayParams blacklist
	rayParamsLine.FilterDescendantsInstances = { NEXTBOTS_PATH }

	for _, m in ipairs(NEXTBOTS_PATH:GetChildren()) do
		if m:IsA("Model") then createOverlayFor(m) end
	end
	-- cleanup removed models
	for m, data in pairs(overlays) do
		if not m or not m.Parent or (NEXTBOTS_PATH and not m:IsDescendantOf(NEXTBOTS_PATH)) then
			if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
			if data.selectionBoxes then for _, sb in ipairs(data.selectionBoxes) do if sb and sb.Parent then sb:Destroy() end end end
			if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
			if data.tracer and data.tracer.Parent then data.tracer:Destroy() end
			overlays[m] = nil
		end
	end
end

-- Screen projection helper
local function worldToScreenVec(pos)
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera then return Vector2.new(0,0), false end
	local x, y, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(x,y), onScreen
end

-- Per-frame overlay update
local function onUpdate()
	if not player or not player.Character or not Camera then return end
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not hrp and not head then return end
	local playerPos = (hrp and hrp.Position) or (head and head.Position)

	local screenCenterFallback = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.9)
	local playerScreenPos, playerOnScreen = worldToScreenVec(playerPos)
	if not playerOnScreen then playerScreenPos = screenCenterFallback end

	for model, data in pairs(overlays) do
		if not model or not model.Parent or not data.part or not data.part.Parent then
			if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
			if data.selectionBoxes then for _, sb in ipairs(data.selectionBoxes) do if sb and sb.Parent then sb:Destroy() end end end
			if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
			if data.tracer and data.tracer.Parent then data.tracer:Destroy() end
			overlays[model] = nil
		else
			local targetPos = data.part.Position
			local dist = (targetPos - playerPos).Magnitude
			if data.distLabel then data.distLabel.Text = string.format("%."..tostring(DISTANCE_PRECISION).."f studs", dist) end

			local screenPos, onScreen = worldToScreenVec(targetPos)
			if onScreen then
				data.tracer.Visible = true
				local delta = screenPos - playerScreenPos
				local length = delta.Magnitude
				local mid = playerScreenPos + delta * 0.5
				data.tracer.Size = UDim2.new(0, math.max(2, length), 0, TRACER_THICKNESS)
				data.tracer.Position = UDim2.new(0, mid.X, 0, mid.Y)
				data.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
				data.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
			else
				data.tracer.Visible = false
			end
		end
	end
end

-- ========== Auto-Outrun: helpers for detection, sampling, scoring ==========

local function getNextBotsList()
	local list = {}
	if NEXTBOTS_PATH then
		for _, m in ipairs(NEXTBOTS_PATH:GetChildren()) do
			if m:IsA("Model") then table.insert(list, m) end
		end
	end
	return list
end

-- Predict future position based on current velocity (simple linear prediction)
local function predictBotPosition(part, dt)
	if not part then return nil end
	local vel = part.Velocity or Vector3.new()
	return part.Position + vel * dt
end

-- Threat detection using velocity direction towards player with prediction
local function botIsMovingTowardPlayer(botModel, playerPos)
	local part = findModelPrimaryPart(botModel)
	if not part then return false, 0, 0 end
	local vel = part.Velocity or Vector3.new()
	local speed = vel.Magnitude
	if speed < 0.6 then return false, speed, 0 end -- nearly stationary
	-- predict a short time ahead
	local predictPos = predictBotPosition(part, PREDICTION_TIME)
	local dirToPlayer = (playerPos - predictPos)
	local mag = dirToPlayer.Magnitude
	if mag <= 0.001 then return false, speed, 0 end
	local dirToPlayerUnit = dirToPlayer.Unit
	local velUnit = vel.Unit
	local dot = velUnit:Dot(dirToPlayerUnit)
	return dot >= CHASE_VELOCITY_DOT_THRESHOLD, speed, dot
end

-- Reusable line check (ignores NextBots folder and optionally other blacklisted objects)
local function isLineClear(a, b)
	if not a or not b then return false end
	rayParamsLine.FilterDescendantsInstances = { NEXTBOTS_PATH } -- ignore NextBots in obstacles
	-- also add explicit blacklisted objects if present
	for _, name in ipairs(BLACKLIST_NAMES) do
		local obj = Workspace:FindFirstChild(name, true)
		if obj then
			table.insert(rayParamsLine.FilterDescendantsInstances, obj)
		end
	end
	local dir = (b - a)
	local res = Workspace:Raycast(a, dir, rayParamsLine)
	return not res
end

-- Sample candidate safe points around player (raycast down to find ground)
local function sampleSafePoints(origin)
	local candidates = {}
	local twoPi = math.pi * 2
	for i = 1, SAFE_SAMPLE_COUNT do
		local angle = (i-1) * (twoPi / SAFE_SAMPLE_COUNT)
		local dx = math.cos(angle) * SAFE_POINT_DISTANCE
		local dz = math.sin(angle) * SAFE_POINT_DISTANCE
		local candidate = origin + Vector3.new(dx, 0, dz)
		-- raycast down from above candidate to find ground
		local above = candidate + Vector3.new(0, 40, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = { NEXTBOTS_PATH }
		params.IgnoreWater = true
		-- also filter blacklisted named objects
		for _, name in ipairs(BLACKLIST_NAMES) do
			local obj = Workspace:FindFirstChild(name, true)
			if obj then table.insert(params.FilterDescendantsInstances, obj) end
		end
		local res = Workspace:Raycast(above, Vector3.new(0, -80, 0), params)
		if res and res.Position then
			local ground = res.Position
			-- ensure there's a clear line (ignoring NextBots)
			if isLineClear(origin, ground) then
				table.insert(candidates, ground)
			end
		end
	end
	return candidates
end

-- score candidate by predicted min distance to bots (use predicted positions for accuracy)
local function scoreCandidate(candidate, bots)
	local minDist = math.huge
	for _, b in ipairs(bots) do
		local p = findModelPrimaryPart(b)
		if p then
			local predicted = predictBotPosition(p, PREDICTION_TIME)
			local d = (predicted - candidate).Magnitude
			if d < minDist then minDist = d end
		end
	end
	-- return min distance (higher is safer)
	return minDist
end

-- compute best safe point and path with scoring (returns path or nil)
local function findSafePointAndPath(playerPos, bots)
	local candidates = sampleSafePoints(playerPos)
	local bestScore = -math.huge
	local bestPath = nil
	local bestGoal = nil

	for _, cand in ipairs(candidates) do
		local sc = scoreCandidate(cand, bots)
		if sc >= SAFE_POINT_MIN_DISTANCE then
			local path = PathfindingService:CreatePath({
				AgentRadius = PATH_AGENT_RADIUS,
				AgentHeight = PATH_AGENT_HEIGHT,
				AgentCanJump = true
			})
			local ok = pcall(function() path:ComputeAsync(playerPos, cand) end)
			if ok and path.Status == Enum.PathStatus.Success then
				-- optionally check waypoint clearance (quick)
				local wps = path:GetWaypoints()
				local lastWP = wps[#wps]
				if lastWP then
					-- score against bots using predicted positions
					local finalScore = scoreCandidate(lastWP.Position, bots)
					if finalScore > bestScore then
						bestScore = finalScore
						bestPath = path
						bestGoal = cand
					end
				end
			end
		end
	end

	return bestGoal, bestPath, bestScore
end

-- Path safety: ensure no waypoint is dangerously close to predicted bot positions
local function pathIsSafe(path, bots)
	if not path or path.Status ~= Enum.PathStatus.Success then return false end
	local wps = path:GetWaypoints()
	for _, wp in ipairs(wps) do
		for _, b in ipairs(bots) do
			local p = findModelPrimaryPart(b)
			if p then
				local predicted = predictBotPosition(p, PREDICTION_TIME)
				if (predicted - wp.Position).Magnitude < SAFE_POINT_MIN_DISTANCE * 0.8 then
					return false
				end
			end
		end
	end
	return true
end

-- Simple smoothing for path visuals (Catmull-Rom style approximation)
local function smoothWaypoints(waypoints)
	if not ENABLE_CURVE_PATHS then return waypoints end
	local pts = {}
	for i, wp in ipairs(waypoints) do
		table.insert(pts, wp.Position)
	end
	-- If too few points, return original
	if #pts < 3 then return waypoints end
	-- Simple interpolation: insert midpoints for smoother visual
	local sm = {}
	for i = 1, #pts - 1 do
		table.insert(sm, pts[i])
		local mid = (pts[i] + pts[i+1]) * 0.5
		table.insert(sm, mid)
	end
	table.insert(sm, pts[#pts])
	-- convert to table of simplistic waypoint-like tables {Position = v}
	local out = {}
	for _, v in ipairs(sm) do table.insert(out, { Position = v }) end
	return out
end

-- ========== Path visualization (markers + optional lines) ==========
local pathVisual = {}
local pathVisualConn = nil
local function clearPathVisuals()
	for _, v in ipairs(pathVisual) do
		if v and v.Parent then v:Destroy() end
	end
	pathVisual = {}
	if pathVisualConn and pathVisualConn.Connected then
		pathVisualConn:Disconnect()
		pathVisualConn = nil
	end
end

local function showPathVisual(waypoints)
	clearPathVisuals()
	if not waypoints or #waypoints == 0 then return end
	-- optionally smooth
	local displayWps = smoothWaypoints(waypoints)

	for i, wp in ipairs(displayWps) do
		local marker = Instance.new("ImageLabel", screenGui)
		marker.Size = UDim2.new(0, 10, 0, 10)
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.BorderSizePixel = 0
		marker.BackgroundTransparency = 1
		marker.Image = "" -- leave blank for simple frame if desired
		marker.Name = "PathMarker_" .. i
		-- fallback visual: small Frame
		local f = Instance.new("Frame", marker)
		f.Size = UDim2.new(1,0,1,0)
		f.BackgroundTransparency = 0.2
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(160, 255, 160)
		table.insert(pathVisual, marker)
	end

	-- per-frame update to position markers
	pathVisualConn = RunService.Heartbeat:Connect(function()
		if not Camera then return end
		for i, wp in ipairs(displayWps) do
			local marker = pathVisual[i]
			if marker then
				local screenPos, onScreen = worldToScreenVec(wp.Position)
				if onScreen then
					marker.Visible = true
					marker.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
				else
					marker.Visible = false
				end
			end
		end
	end)
end

-- ========== Movement following (walk, reissue MoveTo) ==========
local function followPathContinuous(path, stopFlag)
	if not player or not player.Character then return false end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end
	if not path or path.Status ~= Enum.PathStatus.Success then return false end

	local waypoints = path:GetWaypoints()
	if #waypoints == 0 then return false end

	-- show visuals
	showPathVisual(waypoints)

	-- optionally set camera behavior (we default to yaw-only)
	local prevCameraType, prevCameraSubject
	if CAMERA_STYLE == "scriptable" and Camera then
		prevCameraType = Camera.CameraType
		prevCameraSubject = Camera.CameraSubject
		Camera.CameraType = Enum.CameraType.Scriptable
	end

	local lastMoveIssue = 0
	local idx = 1
	while true do
		-- stop conditions
		if stopFlag and stopFlag.value then break end
		if not player or not player.Character then break end
		local curHrP = player.Character:FindFirstChild("HumanoidRootPart")
		if not curHrP then break end

		-- if no more waypoints, we're done
		if idx > #waypoints then
			break
		end

		local wp = waypoints[idx]
		local target = wp.Position

		-- reissue MoveTo often for responsiveness
		if tick() - lastMoveIssue >= WAYPOINT_MOVE_REISSUE_INTERVAL then
			lastMoveIssue = tick()
			pcall(function() humanoid:MoveTo(target) end)
		end

		-- rotate character smoothly toward movement if configured
		if CAMERA_STYLE ~= "scriptable" and CAMERA_STYLE ~= "none" then
			local dir = (Vector3.new(target.X, curHrP.Position.Y, target.Z) - curHrP.Position)
			if dir.Magnitude > 0.1 then
				local desired = CFrame.new(curHrP.Position, curHrP.Position + dir)
				-- apply yaw-only rotation
				local _, y, _ = desired:ToEulerAnglesYXZ()
				curHrP.CFrame = CFrame.new(curHrP.Position) * CFrame.Angles(0, y, 0)
			end
		end

		-- detect reached
		if (curHrP.Position - target).Magnitude <= WAYPOINT_REACHED_RADIUS then
			idx = idx + 1
			RunService.Heartbeat:Wait()
			-- continue loop (no 'continue' keyword)
		else
			-- heartbeat wait allows other logic to run (including replanning)
			RunService.Heartbeat:Wait()
		end
	end

	-- restore camera
	if CAMERA_STYLE == "scriptable" and Camera then
		pcall(function()
			Camera.CameraType = prevCameraType or Enum.CameraType.Custom
			Camera.CameraSubject = prevCameraSubject or player.Character:FindFirstChildOfClass("Humanoid")
		end)
	end

	clearPathVisuals()
	return true
end

-- ========== Auto-Outrun main worker with high-frequency schedule ==========
local autoLoopRunning = false
local function autoOutrunWorker()
	if autoLoopRunning then return end
	autoLoopRunning = true

	local lastCalc = tick()
	local stopFlag = { value = false }

	while autoOutrunEnabled and player and player.Character do
		local now = tick()
		local elapsed = now - lastCalc
		if elapsed >= CALC_INTERVAL then
			-- perform one high-frequency calculation+action step
			lastCalc = now

			-- ensure character and humanoid exist
			local char = player.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not humanoid or not hrp then
				-- small yield to avoid tight busy-wait if character missing
				task.wait(CALC_INTERVAL)
				goto continue_main_loop
			end

			local playerPos = hrp.Position
			-- gather bots and detect chasing (use prediction)
			local bots = getNextBotsList()
			local chasing = {}
			for _, b in ipairs(bots) do
				local p = findModelPrimaryPart(b)
				if p then
					local dist = (p.Position - playerPos).Magnitude
					if dist <= CHASE_DETECT_DISTANCE then
						local isChasing, speed, dot = botIsMovingTowardPlayer(b, playerPos)
						if isChasing then
							table.insert(chasing, { model = b, dist = dist, speed = speed, dot = dot })
						end
					end
				end
			end

			-- no immediate threat -> nothing to do this step
			if #chasing == 0 then
				-- yield minimal time (respect CPU)
				task.wait(CALC_INTERVAL)
				goto continue_main_loop
			end

			-- Find best safe path (heavy work) - only do heavy path compute if necessary:
			-- We attempt a quick heuristic: try direct-away path first (cheap), then sample & path.
			local goal, path, pathScore = nil, nil, -math.huge

			-- 1) direct-away quick attempt (cheap): point away from nearest chaser and attempt path compute
			do
				local nearest = chasing[1]
				for _, c in ipairs(chasing) do if c.dist < nearest.dist then nearest = c end end
				if nearest then
					local nbp = findModelPrimaryPart(nearest.model)
					if nbp then
						local awayDir = (playerPos - nbp.Position)
						if awayDir.Magnitude > 0.001 then
							awayDir = awayDir.Unit
							local fallbackGoal = playerPos + awayDir * SAFE_POINT_DISTANCE * 0.9
							local tryPath = PathfindingService:CreatePath({
								AgentRadius = PATH_AGENT_RADIUS,
								AgentHeight = PATH_AGENT_HEIGHT,
								AgentCanJump = true
							})
							local ok, _ = pcall(function() tryPath:ComputeAsync(playerPos, fallbackGoal) end)
							if ok and tryPath.Status == Enum.PathStatus.Success then
								goal = fallbackGoal
								path = tryPath
								pathScore = scoreCandidate(fallbackGoal, bots)
							end
						end
					end
				end
			end

			-- 2) if direct-away not good or not safe enough, do sampled candidates + path compute (more costly)
			if not path or pathScore < SAFE_POINT_MIN_DISTANCE + 2 then
				local candidateGoal, candidatePath, candidateScore = findSafePointAndPath(playerPos, bots)
				if candidatePath and candidatePath.Status == Enum.PathStatus.Success and candidateScore > pathScore then
					goal = candidateGoal
					path = candidatePath
					pathScore = candidateScore
				end
			end

			-- 3) If we have a valid path, follow it (in a spawned task) while continuing high-frequency checks each CALC_INTERVAL.
			if path and path.Status == Enum.PathStatus.Success then
				-- stop any existing local follow by signaling a stopFlag; then start fresh follow
				stopFlag.value = true
				-- tiny yield to let follower stop if running
				task.wait(0.001)
				stopFlag = { value = false }
				-- spawn follower
				local followStopFlag = stopFlag
				task.spawn(function()
					-- followPathContinuous will run and be interruptible by followStopFlag.value = true
					pcall(function() followPathContinuous(path, followStopFlag) end)
				end)

				-- While following, we still run high-frequency checks each loop and may interrupt/replace path if better found
				-- We continue to next high-frequency step (no blocking) to allow path to be followed and re-evaluated in subsequent iterations.
				-- (This keeps action frequency approx MAX_CALCS_PER_SECOND.)
			else
				-- no path found: try small evasive micro-movement (sidestep) or re-evaluate next iteration
				if humanoid and hrp then
					-- attempt a quick sidestep perpendicular to nearest chaser if safe
					local nearest = chasing[1]
					for _, c in ipairs(chasing) do if c.dist < nearest.dist then nearest = c end end
					if nearest and nearest.model then
						local nbp = findModelPrimaryPart(nearest.model)
						if nbp then
							local away = (playerPos - nbp.Position)
							if away.Magnitude > 0.001 then
								local right = Vector3.new(-away.Z, 0, away.X).Unit
								-- try both directions, pick one with clear line
								local candA = playerPos + right * (SAFE_POINT_DISTANCE * 0.4)
								local candB = playerPos - right * (SAFE_POINT_DISTANCE * 0.4)
								if isLineClear(playerPos, candA) then
									pcall(function() humanoid:MoveTo(candA) end)
								elseif isLineClear(playerPos, candB) then
									pcall(function() humanoid:MoveTo(candB) end)
								else
									-- if neither side ok, try jumping in-place to break ties
									pcall(function() humanoid.Jump = true end)
								end
							end
						end
					end
				end
			end

			-- next small sleep to avoid busy CPU usage (we already spaced using CALC_INTERVAL)
			-- Continue to next iteration (no long waits)
			task.wait(0) -- yield to scheduler slightly

			::continue_main_loop::
		else
			-- not time yet for another calc; yield until a small amount of time
			-- using Heartbeat wait is preferable to keep precise scheduling
			RunService.Heartbeat:Wait()
		end
	end

	autoLoopRunning = false
end

-- ========== Persistence and toggles ==========

local function saveToggleState()
	player:SetAttribute("NextbotViewerEnabled", enabled and true or false)
	player:SetAttribute("NextbotAutoOutrun", autoOutrunEnabled and true or false)
end

local function restoreToggleState()
	local attEnabled = player:GetAttribute("NextbotViewerEnabled")
	local attAuto = player:GetAttribute("NextbotAutoOutrun")
	if attEnabled == true then
		if not enabled then
			enabled = true
			showButton.Text = "Hide NextBots"
			refreshOverlays()
			if not updateConn then updateConn = RunService.Heartbeat:Connect(onUpdate) end
		end
	end
	if attAuto == true then
		if not autoOutrunEnabled then
			autoOutrunEnabled = true
			autoButton.Text = "Auto-Outrun: On"
			task.spawn(autoOutrunWorker)
		end
	end
end

local function toggleViewer(state)
	enabled = state
	if enabled then
		showButton.Text = "Hide NextBots"
		refreshOverlays()
		if not updateConn then updateConn = RunService.Heartbeat:Connect(onUpdate) end
	else
		showButton.Text = "Show NextBots"
		if updateConn then updateConn:Disconnect() updateConn = nil end
		clearOverlays()
	end
	saveToggleState()
end

local function toggleAuto(state)
	autoOutrunEnabled = state
	if autoOutrunEnabled then
		autoButton.Text = "Auto-Outrun: On"
		if not enabled then toggleViewer(true) end
		task.spawn(autoOutrunWorker)
	else
		autoButton.Text = "Auto-Outrun: Off"
	end
	saveToggleState()
end

showButton.MouseButton1Click:Connect(function() toggleViewer(not enabled) end)
autoButton.MouseButton1Click:Connect(function() toggleAuto(not autoOutrunEnabled) end)

-- folder signals
local function connectFolderSignals()
	for _, c in ipairs(folderChildConns) do if c and c.Connected then c:Disconnect() end end
	folderChildConns = {}
	if NEXTBOTS_PATH then
		table.insert(folderChildConns, NEXTBOTS_PATH.ChildAdded:Connect(function() task.wait(0.05) refreshOverlays() end))
		table.insert(folderChildConns, NEXTBOTS_PATH.ChildRemoved:Connect(refreshOverlays))
	end
end

-- Character respawn handling
player.CharacterAdded:Connect(function(char)
	-- small delay to allow character initialize
	task.wait(0.35)
	restoreToggleState()
	if enabled and not updateConn then updateConn = RunService.Heartbeat:Connect(onUpdate) end
end)

-- Cleanup on leaving
player.AncestryChanged:Connect(function()
	if not player:IsDescendantOf(game) then
		if updateConn then updateConn:Disconnect() end
		clearPathVisuals()
		clearOverlays()
	end
end)

-- initial setup: find NextBots folder
NEXTBOTS_PATH = getNextBotsFolder()
if NEXTBOTS_PATH then
	connectFolderSignals()
else
	-- poll in background
	task.spawn(function()
		while not NEXTBOTS_PATH do
			task.wait(1.5)
			NEXTBOTS_PATH = getNextBotsFolder()
			if NEXTBOTS_PATH then
				connectFolderSignals()
				refreshOverlays()
				break
			end
		end
	end)
end

-- restore persisted toggles
restoreToggleState()
if not enabled then toggleViewer(false) end

-- Inline note about limitations:
--  • Achieving a true 100 calculations/actions per second is best-effort. The actual achievable rate depends on the client's CPU and the Roblox scheduler (frame rate).
--  • Use MAX_CALCS_PER_SECOND carefully — very high values increase CPU usage and may cause frame drops.
--  • This script does not bypass server-side physics or authority; it instructs the Humanoid to move via legitimate APIs but automates decision-making client-side.
--  • Tuning parameters (SAFE_SAMPLE_COUNT, PREDICTION_TIME, MAX_CALCS_PER_SECOND) will affect responsiveness and CPU usage.

-- End of script
