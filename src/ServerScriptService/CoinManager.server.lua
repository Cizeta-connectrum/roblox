local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local function makeRemote(cls, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(cls); r.Name = name; r.Parent = RS end
	return r
end
local evCoinsUpdated  = makeRemote("RemoteEvent",    "CoinsUpdated")
local evShowEffect    = makeRemote("RemoteEvent",    "ShowEffect")
local evAnnounce      = makeRemote("RemoteEvent",    "EventAnnounce")
local fnPurchase      = makeRemote("RemoteFunction", "PurchaseUpgrade")
local evRankingUpdate = makeRemote("RemoteEvent",    "RankingUpdate")
local fnGachaSpin     = makeRemote("RemoteFunction", "GachaSpin")

local playerData = {}

-- ===== GACHA ITEMS =====
local GACHA_ALL_ITEMS = {
	{id="skin_red",      rarity="C", label="🔴 Red Skin",       color=Color3.fromRGB(255,50,50)},
	{id="skin_blue",     rarity="C", label="🔵 Blue Skin",      color=Color3.fromRGB(50,100,255)},
	{id="skin_yellow",   rarity="C", label="🟡 Yellow Skin",    color=Color3.fromRGB(255,230,50)},
	{id="skin_green",    rarity="C", label="🟢 Green Skin",     color=Color3.fromRGB(50,200,80)},
	{id="skin_purple",   rarity="C", label="🟣 Purple Skin",    color=Color3.fromRGB(160,50,220)},
	{id="trail_star",    rarity="R", label="⭐ Star Trail"},
	{id="trail_fire",    rarity="R", label="🔥 Fire Trail"},
	{id="trail_ice",     rarity="R", label="❄️ Ice Trail"},
	{id="skin_black",    rarity="R", label="⬛ Shadow Skin",    color=Color3.fromRGB(20,20,20)},
	{id="skin_white",    rarity="R", label="⬜ Ghost Skin",     color=Color3.fromRGB(240,240,240)},
	{id="crown_gold",    rarity="E", label="👑 Gold Crown"},
	{id="crown_diamond", rarity="E", label="💎 Diamond Crown"},
	{id="aura_fire",     rarity="E", label="🔥 Fire Aura"},
	{id="aura_dark",     rarity="E", label="⚫ Dark Aura"},
	{id="aura_rainbow",  rarity="L", label="🌈 Rainbow Aura"},
	{id="aura_galaxy",   rarity="L", label="🌌 Galaxy Aura"},
	{id="trail_galaxy",  rarity="L", label="✨ Galaxy Trail"},
}
-- Gacha tiers: {label, cost, pool with weights per rarity C/R/E/L}
local GACHA_TIERS = {
	{id=1, label="🥉 Bronze",   cost=200,   weights={C=70,R=28,E=2,L=0}},
	{id=2, label="🥈 Silver",   cost=500,   weights={C=40,R=48,E=11,L=1}},
	{id=3, label="🥇 Gold",     cost=1500,  weights={C=10,R=48,E=36,L=6}},
	{id=4, label="💎 Platinum", cost=5000,  weights={C=0, R=20,E=55,L=25}},
	{id=5, label="🌌 Legend",   cost=20000, weights={C=0, R=0, E=30,L=70}},
}
local function getGachaTier(tierId)
	for _, t in ipairs(GACHA_TIERS) do if t.id == tierId then return t end end
	return GACHA_TIERS[1]
end
local function rollGachaItem(tier)
	local w = tier.weights
	local total = w.C + w.R + w.E + w.L
	local roll = math.random() * total
	local targetRarity
	if roll < w.C then targetRarity = "C"
	elseif roll < w.C + w.R then targetRarity = "R"
	elseif roll < w.C + w.R + w.E then targetRarity = "E"
	else targetRarity = "L" end
	-- Filter items by rarity
	local pool = {}
	for _, item in ipairs(GACHA_ALL_ITEMS) do
		if item.rarity == targetRarity then table.insert(pool, item) end
	end
	if #pool == 0 then return GACHA_ALL_ITEMS[1] end
	return pool[math.random(#pool)]
end

-- ===== BATTLE ZONE =====
local BATTLE_ZONE_CENTER = Vector3.new(0, 0.3, 80)
local BATTLE_ZONE_RADIUS = 20
local pvpCooldowns = {} -- "userId1_userId2" -> tick()

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

-- Moving pads table: {part, velX, velZ, speed}
local movingPads = {}
-- Thieves table: {model, target}
local thieves = {}

local function calcSpeed(data)
	return math.min(16 + math.floor(data.total / 50), 60)
end

local function getWave(total)
	if total >= 8000 then return 5
	elseif total >= 3000 then return 4
	elseif total >= 800 then return 3
	elseif total >= 200 then return 2
	else return 1 end
end

local function fireUpdate(player)
	local data = playerData[player.UserId]
	if not data then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Coins.Value=data.coins; ls.Total.Value=data.total end
	evCoinsUpdated:FireClient(player, {
		coins=data.coins, combo=data.combo, comboMultiplier=data.comboMultiplier,
		multiplier=data.multiplier, magnetRadius=data.magnetRadius,
		upgrades=data.upgrades, speed=calcSpeed(data), wave=getWave(data.total),
	})
end

local function applySpeed(player)
	local data = playerData[player.UserId]
	if not data or data.boosted or data.slowed then return end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = calcSpeed(data) end
end

-- ===== COSMETIC APPLICATION =====
local currentKingId = nil -- UserId of current #1 player

local function applyCosmetics(player, char)
	local data = playerData[player.UserId]
	if not data then return end
	local items = data.gachaItems

	-- Skin colors
	local skinColor = nil
	if items["skin_red"]    then skinColor = Color3.fromRGB(255,50,50)
	elseif items["skin_blue"]   then skinColor = Color3.fromRGB(50,100,255)
	elseif items["skin_yellow"] then skinColor = Color3.fromRGB(255,230,50)
	end
	if skinColor then
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("Part") and part.Name ~= "HumanoidRootPart" then
				part.Color = skinColor
			end
		end
	end

	-- Trails
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		if items["trail_star"] then
			local sp = hrp:FindFirstChildOfClass("Sparkles") or Instance.new("Sparkles")
			sp.SparkleColor = Color3.fromRGB(255,255,100)
			sp.Parent = hrp
		end
		if items["trail_fire"] then
			local fire = hrp:FindFirstChildOfClass("Fire") or Instance.new("Fire")
			fire.Color = Color3.fromRGB(255,80,0); fire.SecondaryColor = Color3.fromRGB(255,200,0); fire.Parent = hrp
		end
		if items["trail_ice"] then
			local sp = hrp:FindFirstChild("IceSparkles") or Instance.new("Sparkles")
			sp.Name="IceSparkles"; sp.SparkleColor=Color3.fromRGB(100,200,255); sp.Parent=hrp
		end
		if items["trail_galaxy"] then
			local sp = hrp:FindFirstChild("GalaxySparkles") or Instance.new("Sparkles")
			sp.Name="GalaxySparkles"; sp.SparkleColor=Color3.fromRGB(200,100,255); sp.Parent=hrp
		end
	end

	-- Gacha crown (cosmetic item, different from king crown)
	if items["crown_gold"] then
		local head = char:FindFirstChild("Head")
		if head then
			local existing = head:FindFirstChild("GachaCrown")
			if not existing then
				local crown = Instance.new("Part")
				crown.Name = "GachaCrown"
				crown.Size = Vector3.new(1.8, 0.5, 1.8)
				crown.Shape = Enum.PartType.Cylinder
				crown.Color = Color3.fromRGB(255,200,0)
				crown.Material = Enum.Material.Neon
				crown.Anchored = false
				crown.CanCollide = false
				crown.Parent = char
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = head
				weld.Part1 = crown
				weld.Parent = crown
				crown.CFrame = head.CFrame * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.pi/2)
			end
		end
	end

	-- Auras
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if torso then
		local function makeAura(name, color, transparency)
			if torso:FindFirstChild(name) then return end
			local ring = Instance.new("Part"); ring.Name=name
			ring.Size=Vector3.new(0.3,5,5); ring.Shape=Enum.PartType.Cylinder
			ring.Color=color; ring.Material=Enum.Material.Neon
			ring.Transparency=transparency; ring.Anchored=false; ring.CanCollide=false; ring.Parent=char
			local weld=Instance.new("WeldConstraint"); weld.Part0=torso; weld.Part1=ring; weld.Parent=ring
			ring.CFrame=torso.CFrame
		end
		if items["aura_rainbow"]  then makeAura("RainbowAura", Color3.fromRGB(255,100,200), 0.4) end
		if items["aura_galaxy"]   then makeAura("GalaxyAura",  Color3.fromRGB(100,50,200),  0.3) end
		if items["aura_fire"]     then makeAura("FireAura",    Color3.fromRGB(255,80,0),    0.4) end
		if items["aura_dark"]     then makeAura("DarkAura",    Color3.fromRGB(20,20,20),    0.2) end
	end

	-- Diamond crown
	if items["crown_diamond"] then
		local head = char:FindFirstChild("Head")
		if head and not head:FindFirstChild("DiamondCrown") then
			local crown=Instance.new("Part"); crown.Name="DiamondCrown"
			crown.Size=Vector3.new(1.8,0.5,1.8); crown.Shape=Enum.PartType.Cylinder
			crown.Color=Color3.fromRGB(100,200,255); crown.Material=Enum.Material.Neon
			crown.Anchored=false; crown.CanCollide=false; crown.Parent=char
			local weld=Instance.new("WeldConstraint"); weld.Part0=head; weld.Part1=crown; weld.Parent=crown
			crown.CFrame=head.CFrame*CFrame.new(0,1.1,0)*CFrame.Angles(0,0,math.pi/2)
		end
	end
end

local function applyKingCrown(player, char)
	-- Remove existing king crown from this character
	local head = char:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild("KingCrown")
		if old then old:Destroy() end
	end
	-- Only apply if this player is current king
	if currentKingId ~= player.UserId then return end
	if not head then return end
	local crown = Instance.new("Part")
	crown.Name = "KingCrown"
	crown.Size = Vector3.new(2.2, 0.7, 2.2)
	crown.Shape = Enum.PartType.Cylinder
	crown.Color = Color3.fromRGB(255,215,0)
	crown.Material = Enum.Material.Neon
	crown.Anchored = false
	crown.CanCollide = false
	crown.Parent = char
	local pl = Instance.new("PointLight")
	pl.Brightness = 3; pl.Range = 12; pl.Color = Color3.fromRGB(255,215,0); pl.Parent = crown
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = crown
	weld.Parent = crown
	crown.CFrame = head.CFrame * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.pi/2)
end

local function updateKingCrown(newKingId)
	if currentKingId == newKingId then return end
	-- Remove crown from old king
	if currentKingId then
		local oldKing = Players:GetPlayerByUserId(currentKingId)
		if oldKing and oldKing.Character then
			local head = oldKing.Character:FindFirstChild("Head")
			if head then
				local c = head:FindFirstChild("KingCrown")
				if c then c:Destroy() end
			end
		end
	end
	currentKingId = newKingId
	-- Apply crown to new king
	if newKingId then
		local newKing = Players:GetPlayerByUserId(newKingId)
		if newKing and newKing.Character then
			applyKingCrown(newKing, newKing.Character)
		end
	end
end

local function onPlayerAdded(player)
	local ls = Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
	local cv = Instance.new("IntValue"); cv.Name="Coins"; cv.Parent=ls
	local tv = Instance.new("IntValue"); tv.Name="Total"; tv.Parent=ls
	playerData[player.UserId] = {
		coins=0, total=0, radius=10, multiplier=1, magnetRadius=0,
		combo=0, lastCollect=0, comboMultiplier=1,
		upgrades={}, boosted=false, slowed=false, taxCooldown=false,
		lastWave=1, gachaItems={},
	}
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		applySpeed(player)
		applyCosmetics(player, char)
		applyKingCrown(player, char)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p) playerData[p.UserId]=nil end)

-- Coins
local function spawnCoin()
	if #coins >= MAX_COINS then return end
	local roll=math.random(100); local cum=0; local ct=COIN_TYPES[1]
	for _,t in ipairs(COIN_TYPES) do cum=cum+t.weight; if roll<=cum then ct=t; break end end
	local isLucky = math.random()<0.04
	local value = ct.value*(isLucky and 10 or 1)
	local part = Instance.new("Part")
	part.Shape=Enum.PartType.Ball; part.Size=Vector3.new(ct.size,ct.size,ct.size)
	part.Color=isLucky and Color3.fromRGB(255,255,100) or ct.color
	part.Material=(ct.name=="Common") and Enum.Material.SmoothPlastic or Enum.Material.Neon
	part.Anchored=true; part.CanCollide=false; part.CastShadow=false
	part.Position=Vector3.new(math.random(-180,180),1.5,math.random(-180,180))
	part.Parent=coinFolder
	if isLucky or ct.name=="Legendary" then
		local sp=Instance.new("Sparkles"); sp.SparkleColor=part.Color; sp.Parent=part
	end
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,60,0,26); bb.StudsOffset=Vector3.new(0,2.5,0); bb.Parent=part
	local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
	lbl.Text=(isLucky and "⭐" or "+")..value; lbl.TextColor3=Color3.new(1,1,1)
	lbl.TextStrokeTransparency=0; lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
	table.insert(coins, {part=part,value=value,lucky=isLucky})
end

local function removeCoin(entry)
	for i,c in ipairs(coins) do if c==entry then table.remove(coins,i); break end end
	if entry.part and entry.part.Parent then entry.part:Destroy() end
end

local function collectCoin(player, entry)
	local data = playerData[player.UserId]
	if not data then return end
	local now = tick()
	if now-data.lastCollect<1.5 then data.combo=math.min(data.combo+1,50) else data.combo=1 end
	data.lastCollect=now
	data.comboMultiplier=math.min(1+math.floor(data.combo/10),5)
	local earned=entry.value*data.multiplier*data.comboMultiplier
	data.coins=data.coins+earned; data.total=data.total+earned
	evShowEffect:FireClient(player,{
		type=entry.lucky and "lucky" or "collect",
		position=entry.part and entry.part.Position or Vector3.new(0,2,0),
		value=earned, combo=data.combo,
	})
	applySpeed(player)
	fireUpdate(player)
end

fnPurchase.OnServerInvoke = function(player, id)
	local data=playerData[player.UserId]
	if not data then return {success=false,message="No data"} end
	local upg=UPGRADES[id]; if not upg then return {success=false,message="Unknown"} end
	if data.upgrades[id] then return {success=false,message="Already owned!"} end
	if data.coins<upg.cost then return {success=false,message="Need 🪙"..upg.cost} end
	data.coins=data.coins-upg.cost; data.upgrades[id]=true; upg.apply(data)
	fireUpdate(player)
	return {success=true,message="Bought: "..upg.label,upgrades=data.upgrades}
end

-- ===== GACHA SPIN =====
fnGachaSpin.OnServerInvoke = function(player, tierId)
	local data = playerData[player.UserId]
	if not data then return {success=false, message="No data"} end
	local tier = getGachaTier(tierId or 1)
	if data.coins < tier.cost then return {success=false, message="Need 🪙"..tier.cost.." for "..tier.label} end
	data.coins = data.coins - tier.cost
	local chosen = rollGachaItem(tier)
	local alreadyOwned = data.gachaItems[chosen.id]
	data.gachaItems[chosen.id] = true
	fireUpdate(player)
	if player.Character then applyCosmetics(player, player.Character) end
	local msg = alreadyOwned and (chosen.label.." (duplicate+10%)") or chosen.label
	if alreadyOwned then data.coins = data.coins + math.floor(tier.cost * 0.10) end
	return {success=true, item=chosen, message=msg, alreadyOwned=alreadyOwned, gachaItems=data.gachaItems}
end

-- ===== RANKING BROADCAST =====
task.spawn(function()
	while true do
		task.wait(2)
		-- Build top 5 list
		local list = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local data = playerData[player.UserId]
			if data then
				table.insert(list, {name=player.Name, coins=data.coins, userId=player.UserId})
			end
		end
		table.sort(list, function(a,b) return a.coins > b.coins end)
		local top5 = {}
		for i = 1, math.min(5, #list) do
			table.insert(top5, {name=list[i].name, coins=list[i].coins})
		end
		evRankingUpdate:FireAllClients(top5)
		-- Update king crown
		local kingId = list[1] and list[1].userId or nil
		updateKingCrown(kingId)
	end
end)

-- ===== WAVE SYSTEM =====

local function makePad(name, color, pos, size)
	local p = Instance.new("Part")
	p.Name=name; p.Size=Vector3.new(size,0.6,size); p.Position=pos
	p.Anchored=true; p.CanCollide=true; p.Color=color
	p.Material=Enum.Material.Neon; p.Parent=workspace
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,150,0,50)
	bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.Parent=p
	local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
	lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.BackgroundTransparency=0.35
	lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
	lbl.TextStrokeTransparency=0; lbl.Parent=bb
	Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,8)
	local pl=Instance.new("PointLight"); pl.Brightness=2; pl.Range=14; pl.Color=color; pl.Parent=p
	if name=="SlowZone" then
		lbl.Text="🐌 SLOW!"; lbl.TextColor3=Color3.fromRGB(200,100,255)
	elseif name=="TaxZone" then
		lbl.Text="💸 TAX -20%"; lbl.TextColor3=Color3.fromRGB(255,80,80)
	end
	return p
end

local function addMovingPad(pad, speed)
	local angle = math.random()*math.pi*2
	table.insert(movingPads, {
		part=pad, velX=math.cos(angle)*speed, velZ=math.sin(angle)*speed
	})
end

-- Wave event flags
local waveActivated = {[1]=false,[2]=false,[3]=false,[4]=false,[5]=false}

local function activateWave2(boostPads, slowZones)
	if waveActivated[2] then return end
	waveActivated[2] = true
	evAnnounce:FireAllClients("⚠️ WAVE 2! Pads moving faster!")
	-- Speed up existing moving pads
	for _, mp in ipairs(movingPads) do
		local spd = math.sqrt(mp.velX^2+mp.velZ^2)
		local scale = math.min(spd*1.8, 5) / math.max(spd,0.1)
		mp.velX=mp.velX*scale; mp.velZ=mp.velZ*scale
	end
end

local function activateWave3(slowZones, taxZones)
	if waveActivated[3] then return end
	waveActivated[3] = true
	evAnnounce:FireAllClients("🔥 WAVE 3! Tax zones moving + New slow zones!")
	-- Move tax zones
	for _, pad in ipairs(taxZones) do addMovingPad(pad, 2.5) end
	-- Spawn 2 extra slow zones
	for i=1,2 do
		local pos=Vector3.new(math.random(-150,150),0.3,math.random(-150,150))
		local pad=makePad("SlowZone",Color3.fromRGB(80,0,160),pos,16)
		table.insert(slowZones, pad)
		addMovingPad(pad, 3)
	end
end

local function spawnThief(index)
	-- Simple thief NPC: grey ball that chases player
	local model = Instance.new("Model"); model.Name="Thief"..index; model.Parent=workspace
	local body = Instance.new("Part"); body.Name="HumanoidRootPart"
	body.Shape=Enum.PartType.Ball; body.Size=Vector3.new(3,3,3)
	body.Color=Color3.fromRGB(80,80,80); body.Material=Enum.Material.Neon
	body.Anchored=true; body.CanCollide=false
	body.Position=Vector3.new(math.random(-150,150),2,math.random(-150,150))
	body.Parent=model
	-- Label
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,140,0,45)
	bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=body
	local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
	lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.BackgroundTransparency=0.3
	lbl.Text="👻 THIEF! -10%"; lbl.TextColor3=Color3.fromRGB(255,50,50)
	lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.TextStrokeTransparency=0; lbl.Parent=bb
	Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,8)
	local pl=Instance.new("PointLight"); pl.Brightness=3; pl.Range=16
	pl.Color=Color3.fromRGB(200,50,50); pl.Parent=body
	table.insert(thieves, {body=body, stealCooldown=false})
	return model
end

local function activateWave4()
	if waveActivated[4] then return end
	waveActivated[4] = true
	evAnnounce:FireAllClients("💀 WAVE 4! A COIN THIEF has appeared!")
	spawnThief(1)
end

local function activateWave5(slowZones, taxZones)
	if waveActivated[5] then return end
	waveActivated[5] = true
	evAnnounce:FireAllClients("🌋 WAVE 5! MAXIMUM CHAOS! Everything moves FAST!")
	-- Speed up all moving pads
	for _, mp in ipairs(movingPads) do
		local spd = math.sqrt(mp.velX^2+mp.velZ^2)
		local scale = 5/math.max(spd,0.1)
		mp.velX=mp.velX*scale; mp.velZ=mp.velZ*scale
	end
	-- Add more pads
	for i=1,3 do
		local pos=Vector3.new(math.random(-150,150),0.3,math.random(-150,150))
		local pad=makePad("TaxZone",Color3.fromRGB(200,30,30),pos,14)
		table.insert(taxZones,pad); addMovingPad(pad, 5)
	end
	-- Second thief
	spawnThief(2)
end

-- Coin spinning
task.spawn(function()
	local angle=0
	while true do
		task.wait(0.05); angle=angle+0.05
		for _,e in ipairs(coins) do
			if e.part and e.part.Parent then
				e.part.CFrame=CFrame.new(e.part.Position)*CFrame.Angles(0,angle,0)
			end
		end
	end
end)

-- Coin spawn
task.spawn(function()
	for i=1,60 do spawnCoin() end
	while true do task.wait(1.2); spawnCoin(); spawnCoin() end
end)

-- Coin rain
task.spawn(function()
	while true do
		task.wait(45)
		evAnnounce:FireAllClients("🌧️ COIN RAIN! Bonus coins for 15s!")
		for i=1,30 do task.wait(0.5); spawnCoin(); spawnCoin(); spawnCoin() end
	end
end)

-- ===== MAIN GAME LOOP =====
task.spawn(function()
	task.wait(2) -- wait for map

	-- Cache initial pads
	local boostPads, slowZones, taxZones, holes = {},{},{},{}
	for _,obj in ipairs(workspace:GetChildren()) do
		local n=obj.Name
		if n=="BoostPad" then table.insert(boostPads,obj)
		elseif n=="SlowZone" then table.insert(slowZones,obj)
		elseif n=="TaxZone" then table.insert(taxZones,obj)
		elseif n=="Hole" then table.insert(holes,obj)
		end
	end
	print("Pads: boost="..#boostPads.." slow="..#slowZones.." tax="..#taxZones)

	-- Start moving pads immediately (wave 1: slow start)
	for _, pad in ipairs(slowZones) do addMovingPad(pad, 2) end
	for _, pad in ipairs(taxZones) do addMovingPad(pad, 1.5) end
	for _, pad in ipairs(boostPads) do addMovingPad(pad, 1) end
	waveActivated[2] = true -- already started, skip duplicate

	local tick05 = 0 -- 0.5s counter for moving pads & thieves

	while true do
		task.wait(0.1)
		tick05 = tick05 + 0.1

		-- ===== MOVE PADS (every 0.1s) =====
		for _, mp in ipairs(movingPads) do
			if mp.part and mp.part.Parent then
				local pos = mp.part.Position
				local nx = pos.X + mp.velX * 0.1
				local nz = pos.Z + mp.velZ * 0.1
				-- Bounce off map edges
				if nx > 180 or nx < -180 then mp.velX = -mp.velX; nx = math.clamp(nx,-180,180) end
				if nz > 180 or nz < -180 then mp.velZ = -mp.velZ; nz = math.clamp(nz,-180,180) end
				mp.part.Position = Vector3.new(nx, pos.Y, nz)
			end
		end

		-- ===== THIEF AI (every 0.5s) =====
		if tick05 >= 0.5 then
			tick05 = 0
			-- Find target player (highest coins)
			local target, targetData, targetPos = nil, nil, nil
			for _, player in ipairs(Players:GetPlayers()) do
				local data = playerData[player.UserId]
				if data and (not targetData or data.coins > targetData.coins) then
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						target = player; targetData = data
						targetPos = char.HumanoidRootPart.Position
					end
				end
			end

			for _, thief in ipairs(thieves) do
				if thief.body and thief.body.Parent then
					if targetPos then
						-- Chase player
						local tpos = thief.body.Position
						local dir = (targetPos - tpos)
						local dist = dir.Magnitude
						local wave = getWave(targetData and targetData.total or 0)
						local thiefSpeed = (wave >= 5) and 6 or 4
						if dist > 2 then
							local move = dir.Unit * math.min(thiefSpeed, dist)
							thief.body.Position = Vector3.new(tpos.X+move.X, 2, tpos.Z+move.Z)
						end

						-- Steal if close
						if dist < 5 and not thief.stealCooldown then
							thief.stealCooldown = true
							if targetData and targetData.coins > 0 then
								local stolen = math.floor(targetData.coins * 0.10)
								if stolen > 0 then
									targetData.coins = targetData.coins - stolen
									evAnnounce:FireClient(target, "👻 THIEF stole 🪙"..stolen.."!")
									evShowEffect:FireClient(target,{type="tax",position=targetPos,value=-stolen})
									fireUpdate(target)
								end
							end
							task.delay(2, function() thief.stealCooldown = false end)
						end
					end
				end
			end
		end

		-- ===== PLAYER LOOP =====
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
			local wave = getWave(data.total)

			-- Wave transitions
			if wave >= 2 and not waveActivated[2] then activateWave2(boostPads, slowZones) end
			if wave >= 3 and not waveActivated[3] then activateWave3(slowZones, taxZones) end
			if wave >= 4 and not waveActivated[4] then activateWave4() end
			if wave >= 5 and not waveActivated[5] then activateWave5(slowZones, taxZones) end

			-- Wave changed notification
			if wave ~= data.lastWave then
				data.lastWave = wave
				fireUpdate(player)
			end

			-- ⚡ Boost pads
			if not data.boosted then
				for _, pad in ipairs(boostPads) do
					if pad.Parent and (pad.Position-pos).Magnitude < 7 then
						data.boosted=true
						hum.WalkSpeed=calcSpeed(data)*2.5
						evAnnounce:FireClient(player,"⚡ SPEED BOOST! 5 seconds!")
						task.delay(5,function()
							data.boosted=false
							if not data.slowed then
								local h=char and char:FindFirstChildOfClass("Humanoid")
								if h then h.WalkSpeed=calcSpeed(data) end
							end
						end)
						break
					end
				end
			end

			-- 🐌 Slow zones (all slow zones including dynamic ones)
			local allSlow = slowZones
			local inSlow = false
			for _, pad in ipairs(allSlow) do
				if pad.Parent then
					if (Vector3.new(pad.Position.X,pos.Y,pad.Position.Z)-pos).Magnitude < 9 then
						inSlow=true; break
					end
				end
			end
			-- Also check dynamic pads by name
			if not inSlow then
				for _, mp in ipairs(movingPads) do
					if mp.part and mp.part.Parent and mp.part.Name=="SlowZone" then
						if (Vector3.new(mp.part.Position.X,pos.Y,mp.part.Position.Z)-pos).Magnitude < 9 then
							inSlow=true; break
						end
					end
				end
			end
			if inSlow and not data.slowed then
				data.slowed=true
				if not data.boosted then hum.WalkSpeed=math.max(5, calcSpeed(data)*0.3) end
				evAnnounce:FireClient(player,"🐌 SLOW ZONE! Escape!")
			elseif not inSlow and data.slowed then
				data.slowed=false
				if not data.boosted then hum.WalkSpeed=calcSpeed(data) end
			end

			-- 💸 Tax zones
			if not data.taxCooldown then
				local allTax = taxZones
				for _, pad in ipairs(allTax) do
					if pad.Parent and (Vector3.new(pad.Position.X,pos.Y,pad.Position.Z)-pos).Magnitude < 9 then
						data.taxCooldown=true
						local lost=math.floor(data.coins*0.20)
						if lost>0 then
							data.coins=data.coins-lost
							evAnnounce:FireClient(player,"💸 TAXED! Lost 🪙"..lost.."!")
							evShowEffect:FireClient(player,{type="tax",position=pos,value=-lost})
							fireUpdate(player)
						end
						task.delay(3,function() data.taxCooldown=false end)
						break
					end
				end
			end

			-- 🕳️ Holes
			for _, hole in ipairs(holes) do
				local hp=hole.Position
				if (Vector3.new(hp.X,pos.Y,hp.Z)-pos).Magnitude < 7 then
					local lost=math.floor(data.coins*0.30)
					if lost>0 then
						data.coins=data.coins-lost
						evAnnounce:FireClient(player,"🕳️ HOLE! Lost 🪙"..lost.."!")
						fireUpdate(player)
					end
					root.CFrame=CFrame.new(0,5,0)
					break
				end
			end

			-- ⚔️ PvP Battle Zone steal
			local inBattle = (pos - BATTLE_ZONE_CENTER).Magnitude < BATTLE_ZONE_RADIUS
			if inBattle then
				for _, other in ipairs(Players:GetPlayers()) do
					if other == player then continue end
					local otherData = playerData[other.UserId]
					if not otherData then continue end
					local otherChar = other.Character
					if not otherChar then continue end
					local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
					if not otherRoot then continue end
					local otherPos = otherRoot.Position
					-- Check other also in battle zone
					local otherInBattle = (otherPos - BATTLE_ZONE_CENTER).Magnitude < BATTLE_ZONE_RADIUS
					if not otherInBattle then continue end
					-- Check proximity
					if (pos - otherPos).Magnitude > 8 then continue end
					-- Check cooldown
					local ids = tostring(math.min(player.UserId, other.UserId)).."_"..tostring(math.max(player.UserId, other.UserId))
					local lastSteal = pvpCooldowns[ids] or 0
					if tick() - lastSteal < 3 then continue end
					pvpCooldowns[ids] = tick()
					-- Steal 5% from other player
					local stolen = math.floor(otherData.coins * 0.05)
					if stolen < 1 then stolen = 1 end
					if otherData.coins >= stolen then
						otherData.coins = otherData.coins - stolen
						data.coins = data.coins + stolen
						local msg1 = "⚔️ You stole 🪙"..stolen.." from "..other.Name.."!"
						local msg2 = "⚔️ "..player.Name.." stole 🪙"..stolen.." from you!"
						evAnnounce:FireClient(player, msg1)
						evAnnounce:FireClient(other, msg2)
						fireUpdate(player)
						fireUpdate(other)
					end
				end
			end

			-- 🧲 Magnet
			if data.magnetRadius>0 then
				for _,entry in ipairs(coins) do
					if entry.part and entry.part.Parent then
						local dist=(entry.part.Position-pos).Magnitude
						if dist<data.magnetRadius and dist>data.radius then
							entry.part.Position=entry.part.Position+(pos-entry.part.Position).Unit*3
						end
					end
				end
			end

			-- Auto-collect
			local toCollect={}
			for _,entry in ipairs(coins) do
				if entry.part and entry.part.Parent then
					if (entry.part.Position-pos).Magnitude<data.radius then
						table.insert(toCollect,entry)
					end
				end
			end
			for _,entry in ipairs(toCollect) do collectCoin(player,entry); removeCoin(entry) end
		end
	end
end)

print("CoinManager loaded!")
