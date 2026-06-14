-- CoinManager: simplified, robust server script
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Create RemoteEvents directly (no module indirection)
local function makeRemote(cls, name)
	local r = RS:FindFirstChild(name)
	if not r then
		r = Instance.new(cls); r.Name = name; r.Parent = RS
	end
	return r
end

local evCoinsUpdated  = makeRemote("RemoteEvent",    "CoinsUpdated")
local evShowEffect    = makeRemote("RemoteEvent",    "ShowEffect")
local evAnnounce      = makeRemote("RemoteEvent",    "EventAnnounce")
local fnPurchase      = makeRemote("RemoteFunction", "PurchaseUpgrade")

-- Player data
local playerData = {}

local UPGRADES = {
	radius1  = {cost=100,   label="🔵 Radius I",    apply=function(d) d.radius=14 end},
	radius2  = {cost=500,   label="🔵 Radius II",   apply=function(d) d.radius=22 end},
	radius3  = {cost=2000,  label="🔵 Radius MAX",  apply=function(d) d.radius=35 end},
	multi2   = {cost=300,   label="✨ 2x Coins",    apply=function(d) d.multiplier=2 end},
	multi3   = {cost=1200,  label="✨ 3x Coins",    apply=function(d) d.multiplier=3 end},
	multi5   = {cost=4000,  label="✨ 5x Coins",    apply=function(d) d.multiplier=5 end},
	multi10  = {cost=15000, label="✨ 10x Coins",   apply=function(d) d.multiplier=10 end},
	magnet1  = {cost=600,   label="🧲 Magnet I",    apply=function(d) d.magnetRadius=25 end},
	magnet2  = {cost=2500,  label="🧲 Magnet II",   apply=function(d) d.magnetRadius=55 end},
	magnet3  = {cost=10000, label="🧲 Magnet MAX",  apply=function(d) d.magnetRadius=110 end},
}

local COIN_TYPES = {
	{name="Common",    color=Color3.fromRGB(255,215,0),  value=1,   size=1.8, weight=60},
	{name="Rare",      color=Color3.fromRGB(100,149,237),value=5,   size=2.2, weight=25},
	{name="Epic",      color=Color3.fromRGB(148,0,211),  value=20,  size=2.7, weight=12},
	{name="Legendary", color=Color3.fromRGB(255,100,0),  value=100, size=3.5, weight=3},
}

local coins = {}
local MAX_COINS = 150
local coinFolder = Instance.new("Folder"); coinFolder.Name="Coins"; coinFolder.Parent=workspace

-- Speed from coins: base 16, +1 per 50 coins, max 60
local function calcSpeed(data)
	local bonus = math.min(math.floor(data.total / 50), 44)
	return 16 + bonus
end

local function fireUpdate(player)
	local data = playerData[player.UserId]
	if not data then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Coins.Value = data.coins; ls.Total.Value = data.total end
	evCoinsUpdated:FireClient(player, {
		coins=data.coins, combo=data.combo, comboMultiplier=data.comboMultiplier,
		multiplier=data.multiplier, magnetRadius=data.magnetRadius,
		upgrades=data.upgrades, speed=calcSpeed(data),
	})
end

local function applySpeed(player)
	local data = playerData[player.UserId]
	if not data then return end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = calcSpeed(data) end
end

-- PlayerAdded - connect IMMEDIATELY before anything else
local function onPlayerAdded(player)
	local ls = Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
	local cv = Instance.new("IntValue"); cv.Name="Coins"; cv.Parent=ls
	local tv = Instance.new("IntValue"); tv.Name="Total"; tv.Parent=ls

	playerData[player.UserId] = {
		coins=0, total=0, radius=10, multiplier=1, magnetRadius=0,
		combo=0, lastCollect=0, comboMultiplier=1,
		upgrades={}, boosted=false, slowed=false, taxCooldown=false,
	}

	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		applySpeed(player)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p) playerData[p.UserId] = nil end)

-- Coins
local function spawnCoin()
	if #coins >= MAX_COINS then return end
	local roll = math.random(100); local cum=0; local ct=COIN_TYPES[1]
	for _, t in ipairs(COIN_TYPES) do
		cum=cum+t.weight; if roll<=cum then ct=t; break end
	end
	local isLucky = math.random() < 0.04
	local value = ct.value * (isLucky and 10 or 1)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(ct.size, ct.size, ct.size)
	part.Color = isLucky and Color3.fromRGB(255,255,100) or ct.color
	part.Material = (ct.name=="Common") and Enum.Material.SmoothPlastic or Enum.Material.Neon
	part.Anchored = true; part.CanCollide = false; part.CastShadow = false
	part.Position = Vector3.new(math.random(-180,180), 1.5, math.random(-180,180))
	part.Parent = coinFolder
	if isLucky or ct.name=="Legendary" then
		local sp=Instance.new("Sparkles"); sp.SparkleColor=part.Color; sp.Parent=part
	end
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,60,0,26); bb.StudsOffset=Vector3.new(0,2.5,0); bb.Parent=part
	local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
	lbl.Text=(isLucky and "⭐" or "+")..value; lbl.TextColor3=Color3.new(1,1,1)
	lbl.TextStrokeTransparency=0; lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
	local entry = {part=part, value=value, lucky=isLucky}
	table.insert(coins, entry)
end

local function removeCoin(entry)
	for i,c in ipairs(coins) do if c==entry then table.remove(coins,i); break end end
	if entry.part and entry.part.Parent then entry.part:Destroy() end
end

local function collectCoin(player, entry)
	local data = playerData[player.UserId]
	if not data then return end
	local now = tick()
	if now - data.lastCollect < 1.5 then
		data.combo = math.min(data.combo+1, 50)
	else
		data.combo = 1
	end
	data.lastCollect = now
	data.comboMultiplier = math.min(1 + math.floor(data.combo/10), 5)
	local earned = entry.value * data.multiplier * data.comboMultiplier
	data.coins = data.coins + earned
	data.total = data.total + earned
	evShowEffect:FireClient(player, {
		type=entry.lucky and "lucky" or "collect",
		position=entry.part and entry.part.Position or Vector3.new(0,2,0),
		value=earned, combo=data.combo,
	})
	-- Speed scales with total coins
	applySpeed(player)
	fireUpdate(player)
end

-- Purchase
fnPurchase.OnServerInvoke = function(player, id)
	local data = playerData[player.UserId]
	if not data then return {success=false,message="No data"} end
	local upg = UPGRADES[id]
	if not upg then return {success=false,message="Unknown upgrade"} end
	if data.upgrades[id] then return {success=false,message="Already owned!"} end
	if data.coins < upg.cost then return {success=false,message="Need 🪙"..upg.cost} end
	data.coins = data.coins - upg.cost
	data.upgrades[id] = true
	upg.apply(data)
	fireUpdate(player)
	return {success=true, message="Bought: "..upg.label, upgrades=data.upgrades}
end

-- Coin spinning
task.spawn(function()
	local angle = 0
	while true do
		task.wait(0.05); angle = angle + 0.05
		for _, entry in ipairs(coins) do
			if entry.part and entry.part.Parent then
				entry.part.CFrame = CFrame.new(entry.part.Position) * CFrame.Angles(0, angle, 0)
			end
		end
	end
end)

-- Spawn loop
task.spawn(function()
	for i=1,60 do spawnCoin() end
	while true do task.wait(1.2); spawnCoin(); spawnCoin() end
end)

-- Coin rain every 45s
task.spawn(function()
	while true do
		task.wait(45)
		evAnnounce:FireAllClients("🌧️ COIN RAIN! Bonus coins for 15s!")
		for i=1,30 do task.wait(0.5); spawnCoin(); spawnCoin(); spawnCoin() end
	end
end)

-- Main loop (0.1s tick)
task.spawn(function()
	-- Wait for map to be ready
	task.wait(2)

	-- Cache pad positions
	local boostPads, slowZones, taxZones, holes = {}, {}, {}, {}
	for _, obj in ipairs(workspace:GetChildren()) do
		local n = obj.Name
		if n=="BoostPad" then table.insert(boostPads, obj)
		elseif n=="SlowZone" then table.insert(slowZones, obj)
		elseif n=="TaxZone" then table.insert(taxZones, obj)
		elseif n=="Hole" then table.insert(holes, obj)
		end
	end
	print("Pads: boost="..#boostPads.." slow="..#slowZones.." tax="..#taxZones.." holes="..#holes)

	while true do
		task.wait(0.1)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = playerData[player.UserId]
			if not data then continue end
			local char = player.Character
			if not char then continue end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then continue end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then continue end
			local pos = root.Position

			-- ⚡ Boost
			if not data.boosted then
				for _, pad in ipairs(boostPads) do
					if (pad.Position - pos).Magnitude < 7 then
						data.boosted = true
						hum.WalkSpeed = calcSpeed(data) * 2.5
						evAnnounce:FireClient(player, "⚡ SPEED BOOST! 5 seconds!")
						task.delay(5, function()
							data.boosted = false
							if not data.slowed then
								local h = char and char:FindFirstChildOfClass("Humanoid")
								if h then h.WalkSpeed = calcSpeed(data) end
							end
						end)
						break
					end
				end
			end

			-- 🐌 Slow
			local inSlow = false
			for _, pad in ipairs(slowZones) do
				if (Vector3.new(pad.Position.X,pos.Y,pad.Position.Z)-pos).Magnitude < 9 then
					inSlow = true; break
				end
			end
			if inSlow and not data.slowed then
				data.slowed = true
				if not data.boosted then hum.WalkSpeed = 5 end
				evAnnounce:FireClient(player, "🐌 Slow zone! Escape!")
			elseif not inSlow and data.slowed then
				data.slowed = false
				if not data.boosted then hum.WalkSpeed = calcSpeed(data) end
			end

			-- 💸 Tax
			if not data.taxCooldown then
				for _, pad in ipairs(taxZones) do
					if (Vector3.new(pad.Position.X,pos.Y,pad.Position.Z)-pos).Magnitude < 9 then
						data.taxCooldown = true
						local lost = math.floor(data.coins * 0.20)
						if lost > 0 then
							data.coins = data.coins - lost
							evAnnounce:FireClient(player, "💸 TAXED! Lost 🪙"..lost.."!")
							evShowEffect:FireClient(player, {type="tax", position=pos, value=-lost})
							fireUpdate(player)
						end
						task.delay(3, function() data.taxCooldown = false end)
						break
					end
				end
			end

			-- 🕳️ Holes
			for _, hole in ipairs(holes) do
				local hp = hole.Position
				if (Vector3.new(hp.X,pos.Y,hp.Z)-pos).Magnitude < 7 then
					local lost = math.floor(data.coins * 0.30)
					if lost > 0 then
						data.coins = data.coins - lost
						evAnnounce:FireClient(player, "🕳️ HOLE! Lost 🪙"..lost.."!")
						fireUpdate(player)
					end
					root.CFrame = CFrame.new(0, 5, 0)
					break
				end
			end

			-- 🧲 Magnet
			if data.magnetRadius > 0 then
				for _, entry in ipairs(coins) do
					if entry.part and entry.part.Parent then
						local dist = (entry.part.Position - pos).Magnitude
						if dist < data.magnetRadius and dist > data.radius then
							entry.part.Position = entry.part.Position + (pos - entry.part.Position).Unit * 3
						end
					end
				end
			end

			-- Auto-collect
			local toCollect = {}
			for _, entry in ipairs(coins) do
				if entry.part and entry.part.Parent then
					if (entry.part.Position - pos).Magnitude < data.radius then
						table.insert(toCollect, entry)
					end
				end
			end
			for _, entry in ipairs(toCollect) do
				collectCoin(player, entry)
				removeCoin(entry)
			end
		end
	end
end)

print("CoinManager loaded!")
