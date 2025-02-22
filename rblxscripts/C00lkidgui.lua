-- c00lkidd Theme GUI Script for Roblox

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c00lkiddGUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Title Label
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
TitleLabel.TextColor3 = Color3.fromRGB(255, 100, 255) -- Vibrant pink
TitleLabel.Text = "c00lkidd Hub"
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = MainFrame

-- Input Label
local InputLabel = Instance.new("TextLabel")
InputLabel.Name = "InputLabel"
InputLabel.Size = UDim2.new(0.9, 0, 0, 20)
InputLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
InputLabel.BackgroundColor3 = Color3.new(1,1,1)
InputLabel.BackgroundTransparency = 1
InputLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Lime green
InputLabel.Text = "Enter Text:"
InputLabel.TextScaled = true
InputLabel.Font = Enum.Font.SourceSansBold
InputLabel.Parent = MainFrame

-- Input TextBox
local InputTextBox = Instance.new("TextBox")
InputTextBox.Name = "InputTextBox"
InputTextBox.Size = UDim2.new(0.9, 0, 0, 30)
InputTextBox.Position = UDim2.new(0.05, 0, 0.3, 0)
InputTextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InputTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputTextBox.TextScaled = true
InputTextBox.Font = Enum.Font.SourceSans
InputTextBox.Parent = MainFrame

-- Display Label
local DisplayLabel = Instance.new("TextLabel")
DisplayLabel.Name = "DisplayLabel"
DisplayLabel.Size = UDim2.new(0.9, 0, 0, 20)
DisplayLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
DisplayLabel.BackgroundColor3 = Color3.new(1,1,1)
DisplayLabel.BackgroundTransparency = 1
DisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
DisplayLabel.Text = "Display:"
DisplayLabel.TextScaled = true
DisplayLabel.Font = Enum.Font.SourceSansBold
DisplayLabel.Parent = MainFrame

-- Display Text Label
local DisplayTextLabel = Instance.new("TextLabel")
DisplayTextLabel.Name = "DisplayTextLabel"
DisplayTextLabel.Size = UDim2.new(0.9, 0, 0, 30)
DisplayTextLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
DisplayTextLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DisplayTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DisplayTextLabel.TextScaled = true
DisplayTextLabel.Font = Enum.Font.SourceSans
DisplayTextLabel.Parent = MainFrame

-- Update Button
local UpdateButton = Instance.new("TextButton")
UpdateButton.Name = "UpdateButton"
UpdateButton.Size = UDim2.new(0.4, 0, 0, 30)
UpdateButton.Position = UDim2.new(0.05, 0, 0.8, 0)
UpdateButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255) -- Light blue
UpdateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UpdateButton.Text = "Update"
UpdateButton.TextScaled = true
UpdateButton.Font = Enum.Font.SourceSansBold
UpdateButton.Parent = MainFrame

-- Unanchor All Button
local UnanchorButton = Instance.new("TextButton")
UnanchorButton.Name = "UnanchorButton"
UnanchorButton.Size = UDim2.new(0.4, 0, 0, 30)
UnanchorButton.Position = UDim2.new(0.55, 0, 0.8, 0)
UnanchorButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Light red
UnanchorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnanchorButton.Text = "Unanchor All"
UnanchorButton.TextScaled = true
UnanchorButton.Font = Enum.Font.SourceSansBold
UnanchorButton.Parent = MainFrame

-- Button Functionality
UpdateButton.MouseButton1Click:Connect(function()
    DisplayTextLabel.Text = InputTextBox.Text
end)

UnanchorButton.MouseButton1Click:Connect(function()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
end)
