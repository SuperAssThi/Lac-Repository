-- Universal Script Executor for Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptExecutorGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false -- Prevent GUI from resetting on character respawn

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui
MainFrame.BorderSizePixel = 0

local TextBox = Instance.new("TextBox")
TextBox.Name = "ScriptInput"
TextBox.Size = UDim2.new(0.9, 0, 0.7, 0)
TextBox.Position = UDim2.new(0.05, 0, 0.05, 0)
TextBox.PlaceholderText = "Enter your Lua script here..."
TextBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
TextBox.TextColor3 = Color3.new(1, 1, 1)
TextBox.Parent = MainFrame

local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Name = "ExecuteButton"
ExecuteButton.Size = UDim2.new(0.2, 0, 0.1, 0)
ExecuteButton.Position = UDim2.new(0.05, 0, 0.8, 0)
ExecuteButton.Text = "Execute"
ExecuteButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
ExecuteButton.TextColor3 = Color3.new(1, 1, 1)
ExecuteButton.Parent = MainFrame

local SaveButton = Instance.new("TextButton")
SaveButton.Name = "SaveButton"
SaveButton.Size = UDim2.new(0.2, 0, 0.1, 0)
SaveButton.Position = UDim2.new(0.27, 0, 0.8, 0)
SaveButton.Text = "Save"
SaveButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
SaveButton.TextColor3 = Color3.new(1, 1, 1)
SaveButton.Parent = MainFrame

local ClearButton = Instance.new("TextButton")
ClearButton.Name = "ClearButton"
ClearButton.Size = UDim2.new(0.2, 0, 0.1, 0)
ClearButton.Position = UDim2.new(0.49, 0, 0.8, 0)
ClearButton.Text = "Clear"
ClearButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Parent = MainFrame

local LogBox = Instance.new("TextBox")
LogBox.Name = "LogBox"
LogBox.Size = UDim2.new(0.2, 0, 0.8, 0)
LogBox.Position = UDim2.new(0.75, 0, 0.05, 0)
LogBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
LogBox.TextColor3 = Color3.new(1, 1, 1)
LogBox.ReadOnly = true -- Prevent user from editing the log
LogBox.Parent = MainFrame

local SavedScripts = {}

-- Function to execute the script
local function executeScript(script)
    local environment = {
        workspace = workspace,
        game = game,
        script = script,
        print = function(...)
            local args = {...}
            local logString = ""
            for i, v in ipairs(args) do
                logString = logString .. tostring(v) .. " "
            end
            LogBox.Text = LogBox.Text .. logString .. "\n"
        end,
        warn = warn,
        error = error,
        tick = tick,
        wait = wait,
        delay = delay,
        spawn = spawn,
        UserInputService = UserInputService,
        Players = Players,
        RunService = RunService,
        Debris = Debris,
        HttpService = HttpService,
        ReplicatedStorage = ReplicatedStorage,
        StarterGui = StarterGui,
        -- Add more globals as needed
    }

    local scriptFunction = loadstring(script)
    if scriptFunction then
        setfenv(scriptFunction, environment)
        local success, result = pcall(scriptFunction)
        if success then
            LogBox.Text = LogBox.Text .. "Script executed successfully: " .. tostring(result) .. "\n"
        else
            LogBox.Text = LogBox.Text .. "Error executing script: " .. tostring(result) .. "\n"
        end
    else
        LogBox.Text = LogBox.Text .. "Invalid script source.\n"
    end
end

-- Button click event
ExecuteButton.MouseButton1Click:Connect(function()
    local inputScript = TextBox.Text
    LogBox.Text = "" -- Clear log before each execution
    executeScript(inputScript)
end)

SaveButton.MouseButton1Click:Connect(function()
    local inputScript = TextBox.Text
    local scriptName = HttpService:GenerateGUID()
    SavedScripts[scriptName] = inputScript
    LogBox.Text = LogBox.Text .. "Script saved.\n"
end)

ClearButton.MouseButton1Click:Connect(function()
    TextBox.Text = ""
    LogBox.Text = ""
end)
