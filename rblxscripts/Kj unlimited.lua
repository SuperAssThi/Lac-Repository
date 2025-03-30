-- Animation ID
local animationId = 77727115892579
-- Music ID
local musicId = "rbxassetid://95410275491981"

-- Get the character and humanoid
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Load the animation
local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://" .. animationId
local animationTrack = humanoid:LoadAnimation(animation)

-- Load and play the sound
local sound = Instance.new("Sound")
sound.SoundId = musicId
sound.Parent = character.Head -- Or any other appropriate parent
sound.Looped = true
sound:Play()

-- Play the animation
animationTrack:Play()

-- Stop the animation and sound when the character dies or is removed
character.AncestryChanged:Connect(function(_, parent)
    if parent == nil then
        animationTrack:Stop()
        sound:Stop()
        sound:Destroy()
    end
end)

humanoid.Died:Connect(function()
    animationTrack:Stop()
    sound:Stop()
    sound:Destroy()
end)

-- User friendly message for success.
print("Animation and Music started successfully!")
