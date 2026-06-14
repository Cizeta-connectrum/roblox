-- HungerController.client.lua
-- Manages client-side hunger: decreases over time, warns at low hunger, damages at 0

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))

local HUNGER_MAX = 100
local HUNGER_DECREASE_RATE = 1        -- per tick
local HUNGER_TICK_INTERVAL = 10       -- seconds between decreases
local HUNGER_WARNING_THRESHOLD = 20
local STARVATION_DAMAGE = 5           -- damage per second when hunger = 0
local STARVATION_TICK = 1             -- seconds between starvation damage

local hunger = HUNGER_MAX
local isStarving = false
local hungerTimer = 0
local starvationTimer = 0

-- Wait for HUD from ClientMain
local hud = PlayerGui:WaitForChild("HUD", 10)
local hungerBar = hud and hud:FindFirstChild("HungerBar")

-- Create warning label
local warningGui = Instance.new("ScreenGui")
warningGui.Name = "HungerWarningUI"
warningGui.ResetOnSpawn = false
warningGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
warningGui.Parent = PlayerGui

local warningLabel = Instance.new("TextLabel")
warningLabel.Name = "HungerWarning"
warningLabel.Size = UDim2.new(0, 300, 0, 50)
warningLabel.Position = UDim2.new(0.5, -150, 0.15, 0)
warningLabel.BackgroundColor3 = Color3.fromRGB(180, 50, 0)
warningLabel.BackgroundTransparency = 0.3
warningLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
warningLabel.TextScaled = true
warningLabel.Font = Enum.Font.GothamBold
warningLabel.Text = "HUNGRY! Find food!"
warningLabel.Visible = false
warningLabel.Parent = warningGui

local starvationLabel = Instance.new("TextLabel")
starvationLabel.Name = "StarvationWarning"
starvationLabel.Size = UDim2.new(0, 300, 0, 50)
starvationLabel.Position = UDim2.new(0.5, -150, 0.22, 0)
starvationLabel.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
starvationLabel.BackgroundTransparency = 0.2
starvationLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
starvationLabel.TextScaled = true
starvationLabel.Font = Enum.Font.GothamBold
starvationLabel.Text = "STARVING! Taking damage!"
starvationLabel.Visible = false
starvationLabel.Parent = warningGui

-- Update the hunger bar UI
local function updateHungerBar()
	local fraction = hunger / HUNGER_MAX

	-- Try to get hungerBar from HUD if not found yet
	if not hungerBar then
		hud = PlayerGui:FindFirstChild("HUD")
		if hud then
			hungerBar = hud:FindFirstChild("HungerBar")
		end
	end

	if hungerBar then
		hungerBar.Size = UDim2.new(fraction, 0, 1, 0)

		-- Color: green -> yellow -> red
		if fraction > 0.5 then
			hungerBar.BackgroundColor3 = Color3.fromRGB(220, 140, 20)
		elseif fraction > 0.2 then
			hungerBar.BackgroundColor3 = Color3.fromRGB(220, 80, 0)
		else
			hungerBar.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
		end
	end

	-- Warnings
	warningLabel.Visible = hunger <= HUNGER_WARNING_THRESHOLD and hunger > 0
	starvationLabel.Visible = hunger <= 0

	-- Blink warning label
	if warningLabel.Visible then
		warningLabel.BackgroundTransparency = (math.sin(tick() * 3) + 1) / 2 * 0.4 + 0.3
	end
end

-- Deal starvation damage to local player via character humanoid
local function dealStarvationDamage()
	local char = LocalPlayer.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(STARVATION_DAMAGE)
		print("[HungerController] Starvation damage:", STARVATION_DAMAGE, "HP remaining:", humanoid.Health)
		if humanoid.Health <= 0 then
			RemoteEvents.PlayerDied:FireServer()
		end
	end
end

-- Main hunger loop using Heartbeat
RunService.Heartbeat:Connect(function(dt)
	hungerTimer = hungerTimer + dt
	starvationTimer = starvationTimer + dt

	-- Decrease hunger every HUNGER_TICK_INTERVAL seconds
	if hungerTimer >= HUNGER_TICK_INTERVAL then
		hungerTimer = 0
		if hunger > 0 then
			hunger = math.max(0, hunger - HUNGER_DECREASE_RATE)
			isStarving = hunger <= 0
			print("[HungerController] Hunger:", hunger)
		end
	end

	-- Deal damage when starving
	if isStarving and starvationTimer >= STARVATION_TICK then
		starvationTimer = 0
		dealStarvationDamage()
	end

	updateHungerBar()
end)

-- Expose hunger for other systems
_G.GetHunger = function()
	return hunger
end

_G.AddHunger = function(amount)
	hunger = math.min(HUNGER_MAX, hunger + amount)
	isStarving = hunger <= 0
	print("[HungerController] Hunger restored to:", hunger)
end

-- Reset hunger on respawn
LocalPlayer.CharacterAdded:Connect(function()
	hunger = HUNGER_MAX
	isStarving = false
	hungerTimer = 0
	starvationTimer = 0
	print("[HungerController] Hunger reset on respawn")
end)

print("[HungerController] Hunger Controller initialized.")
