-- Pendant flight controller
-- When player has pendant: Space held = float upward
-- Also shows pendant status in HUD

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local evPendantUnlocked = RS:WaitForChild("PendantUnlocked", 30)

local hasPendant = false
local bodyVel = nil

-- Pendant UI badge
local gui = Instance.new("ScreenGui")
gui.Name = "PendantGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = player.PlayerGui

local pendantBadge = Instance.new("Frame")
pendantBadge.Size = UDim2.new(0, 200, 0, 48)
pendantBadge.Position = UDim2.new(0.5, -100, 0, 160)
pendantBadge.BackgroundColor3 = Color3.fromRGB(180, 140, 0)
pendantBadge.BackgroundTransparency = 1
pendantBadge.BorderSizePixel = 0; pendantBadge.Parent = gui
Instance.new("UICorner", pendantBadge).CornerRadius = UDim.new(0, 10)

local pendantLabel = Instance.new("TextLabel")
pendantLabel.Size = UDim2.new(1,0,1,0); pendantLabel.BackgroundTransparency = 1
pendantLabel.Text = "LAPUTA PENDANT\n[SPACE] to fly"
pendantLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
pendantLabel.TextScaled = true; pendantLabel.Font = Enum.Font.GothamBold
pendantLabel.TextStrokeTransparency = 0; pendantLabel.Parent = pendantBadge

local function showPendantUnlock()
	hasPendant = true
	pendantBadge.BackgroundTransparency = 0.2
	for i = 1, 5 do
		TweenService:Create(pendantBadge, TweenInfo.new(0.2), {BackgroundTransparency=0}):Play()
		task.wait(0.2)
		TweenService:Create(pendantBadge, TweenInfo.new(0.2), {BackgroundTransparency=0.4}):Play()
		task.wait(0.2)
	end
	TweenService:Create(pendantBadge, TweenInfo.new(0.3), {BackgroundTransparency=0.2}):Play()
end

evPendantUnlocked.OnClientEvent:Connect(showPendantUnlock)

-- Flight using BodyVelocity on Space hold
RunService.Heartbeat:Connect(function()
	if not hasPendant then return end
	local char = player.Character; if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

	local spaceHeld = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	local pos = hrp.Position
	local inSkyArea = pos.Y > 50

	if spaceHeld and inSkyArea then
		if not bodyVel then
			bodyVel = Instance.new("BodyVelocity")
			bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
			bodyVel.Velocity = Vector3.new(0, 0, 0)
			bodyVel.Parent = hrp
		end
		local targetVel = math.min(30, math.max(0, 500 - pos.Y))
		bodyVel.Velocity = Vector3.new(0, targetVel, 0)
		hum.PlatformStand = false
	else
		if bodyVel then
			bodyVel:Destroy(); bodyVel = nil
		end
	end
end)
