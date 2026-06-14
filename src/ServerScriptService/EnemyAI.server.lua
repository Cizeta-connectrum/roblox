-- EnemyAI.server.lua
-- Controls zombie NPC behavior: chase players, deal damage, die and drop loot

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

local DETECT_RANGE = 50       -- studs to detect player
local ATTACK_RANGE = 5        -- studs to deal damage
local ATTACK_DAMAGE = 10      -- damage per attack
local ATTACK_COOLDOWN = 1     -- seconds between attacks
local MOVE_SPEED = 10         -- studs/second
local AI_TICK = 1             -- seconds between AI updates
local LOOT_DROP_ITEMS = { "wood", "stone", "fiber" }

-- Track last attack times per zombie
local lastAttackTime = {}

-- Add loot to player inventory
local function addToInventory(player, itemId, amount)
	local PlayerData = _G.PlayerData
	if not PlayerData then return end
	local data = PlayerData[player.UserId]
	if not data then return end
	data.inventory[itemId] = (data.inventory[itemId] or 0) + amount
	RemoteEvents.UpdateInventory:FireClient(player, data.inventory)
end

-- Drop a resource item in the world at a position
local function dropLoot(position)
	local itemName = LOOT_DROP_ITEMS[math.random(1, #LOOT_DROP_ITEMS)]

	local lootPart = Instance.new("Part")
	lootPart.Name = "Loot_" .. itemName
	lootPart.Size = Vector3.new(1, 1, 1)
	lootPart.BrickColor = BrickColor.new("Bright yellow")
	lootPart.Shape = Enum.PartType.Ball
	lootPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	lootPart.Anchored = false
	lootPart.Parent = workspace

	-- Tag it so players can pick it up by touching
	local lootTag = Instance.new("StringValue")
	lootTag.Name = "LootItem"
	lootTag.Value = itemName
	lootTag.Parent = lootPart

	-- Auto-collect on touch
	lootPart.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if player then
			addToInventory(player, itemName, 1)
			lootPart:Destroy()
			print("[EnemyAI] Player", player.Name, "picked up", itemName)
		end
	end)

	-- Cleanup after 30 seconds
	task.delay(30, function()
		if lootPart and lootPart:IsDescendantOf(workspace) then
			lootPart:Destroy()
		end
	end)
end

-- Get all zombie models
local function getZombies()
	local zombies = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChild("IsZombie") and obj:FindFirstChild("Humanoid") then
			if obj:FindFirstChild("Humanoid").Health > 0 then
				table.insert(zombies, obj)
			end
		end
	end
	return zombies
end

-- Find nearest player to a position
local function getNearestPlayer(position)
	local nearest = nil
	local nearestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = player
			end
		end
	end

	return nearest, nearestDist
end

-- Main AI loop
local aiTimer = 0

RunService.Heartbeat:Connect(function(dt)
	aiTimer = aiTimer + dt
	if aiTimer < AI_TICK then return end
	aiTimer = 0

	local now = tick()
	local zombies = getZombies()

	for _, zombie in ipairs(zombies) do
		local humanoid = zombie:FindFirstChild("Humanoid")
		local rootPart = zombie:FindFirstChild("HumanoidRootPart")

		if not humanoid or not rootPart or humanoid.Health <= 0 then
			continue
		end

		local zombiePos = rootPart.Position
		local nearestPlayer, dist = getNearestPlayer(zombiePos)

		if nearestPlayer and dist <= DETECT_RANGE then
			local targetChar = nearestPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

			if targetRoot then
				local targetPos = targetRoot.Position

				if dist <= ATTACK_RANGE then
					-- Attack player
					local lastAttack = lastAttackTime[zombie] or 0
					if now - lastAttack >= ATTACK_COOLDOWN then
						lastAttackTime[zombie] = now
						local playerHumanoid = targetChar:FindFirstChild("Humanoid")
						if playerHumanoid and playerHumanoid.Health > 0 then
							playerHumanoid:TakeDamage(ATTACK_DAMAGE)
							print("[EnemyAI] Zombie attacked", nearestPlayer.Name, "for", ATTACK_DAMAGE, "damage")
						end
					end
				else
					-- Move toward player
					local direction = (targetPos - zombiePos).Unit
					local moveAmount = direction * MOVE_SPEED * AI_TICK
					local newPos = zombiePos + moveAmount

					-- Keep zombie on ground level approximately
					newPos = Vector3.new(newPos.X, zombiePos.Y, newPos.Z)

					rootPart.CFrame = CFrame.new(newPos, Vector3.new(targetPos.X, newPos.Y, targetPos.Z))
				end
			end
		end

		-- Check if zombie is dead
		if humanoid.Health <= 0 then
			dropLoot(zombiePos)
			lastAttackTime[zombie] = nil
			zombie:Destroy()
			print("[EnemyAI] Zombie destroyed and dropped loot")
		end
	end
end)

-- Listen for zombie health reaching 0 via Humanoid.Died
local function onZombieAdded(model)
	if not model:FindFirstChild("IsZombie") then return end
	local humanoid = model:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid.Died:Connect(function()
		local rootPart = model:FindFirstChild("HumanoidRootPart")
		if rootPart then
			dropLoot(rootPart.Position)
		end
		task.delay(0.5, function()
			if model and model:IsDescendantOf(workspace) then
				lastAttackTime[model] = nil
				model:Destroy()
			end
		end)
		print("[EnemyAI] Zombie died (Humanoid.Died)")
	end)
end

-- Watch for new zombies added to workspace
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Model") and obj:FindFirstChild("IsZombie") then
		onZombieAdded(obj)
	end
end)

print("[EnemyAI] Enemy AI initialized.")
