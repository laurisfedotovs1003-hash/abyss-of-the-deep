--[[
	FishingController — "Let's Fish" style snappy fishing mechanics
	Full flow: Cast (parabolic arc) → Bobber (buoyancy + fish shadow) →
	Bite (2s window) → Hook (rod bend, struggle) → Catch/Escape.
	Mobile-optimized for smooth 60fps with minimal particle overhead.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local FishingController = Knit.CreateController {
	Name = "FishingController",
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

-- ============================================================
-- State Machine: Idle → Casting → Floating → Biting → Hooking → Reeling → End
-- ============================================================
local STATE = {
	IDLE = "Idle",
	CASTING = "Casting",
	FLOATING = "Floating",
	BITING = "Biting",
	HOOKING = "Hooking",
	REELING = "Reeling",
	ESCAPING = "Escaping",
}
local currentState = STATE.IDLE

-- Tool references
local rodTool = nil
local harvestTool = nil
local divingGearTool = nil

-- Fishing state
local waterSurfaceY = 0       -- Y position of water surface
local castDistance = 30       -- Studs forward from player
local bobberPart = nil        -- The bobber floating on water
local lineAttachment = nil    -- Line from rod to bobber
local fishShadow = nil        -- Underwater shadow approaching
local currentRodTier = "Basic"
local biteTimer = 0           -- When the bite will happen
local biteWindowEnd = 0       -- 2-second window deadline
local fishData = nil          -- What was caught

-- Rod tier config
local ROD_TIERS = {
	Basic = { CastDist = 25, BiteMin = 3, BiteMax = 8, CatchBonus = 1.0 },
	Advanced = { CastDist = 30, BiteMin = 4, BiteMax = 10, CatchBonus = 1.15 },
	Master = { CastDist = 35, BiteMin = 5, BiteMax = 12, CatchBonus = 1.35 },
	Legendary = { CastDist = 40, BiteMin = 6, BiteMax = 14, CatchBonus = 1.5 },
}

-- ============================================================
-- Initialize
-- ============================================================

function FishingController:KnitStart()
	print("[FishingController] Snappy Let's Fish mechanics ready")
	
	-- Create tools in Backpack
	self:CreateTools()
	
	-- Find water surface Y
	self:FindWaterSurface()
	
	-- Listen for ToolService responses
	local ToolService = Knit.GetService("ToolService")
	if ToolService then
		ToolService.Client:Get("FishBite"):Connect(function(data)
			self:OnFishBite(data)
		end)
		ToolService.Client:Get("FishResult"):Connect(function(data)
			self:OnFishResult(data)
		end)
		ToolService.Client:Get("CastLine"):Connect(function(data)
			if data.success then
				self:StartBiteWait(data)
			end
		end)
		ToolService.Client:Get("HarvestResult"):Connect(function(data)
			self:OnHarvestResult(data)
		end)
	end
end

function FishingController:FindWaterSurface()
	-- Water surface is at Y=0 by convention
	waterSurfaceY = 0
	-- Look for a part named "WaterSurface" if it exists
	local water = Workspace:FindFirstChild("WaterSurface")
	if water then
		waterSurfaceY = water.Position.Y
	end
end

-- ============================================================
-- Tool Creation (mobile-friendly: uses Activated = works on touch)
-- ============================================================

function FishingController:CreateTools()
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	
	-- Fishing Rod
	rodTool = Instance.new("Tool")
	rodTool.Name = "Fishing Rod"
	rodTool.ToolTip = "Cast your line" .. (isMobile and " (tap)" or " (click)")
	rodTool.RequiresHandle = false
	rodTool.CanBeDropped = false
	rodTool.Parent = localPlayer:WaitForChild("Backpack")
	
	rodTool.Activated:Connect(function()
		if currentState == STATE.IDLE then
			self:BeginCast()
		elseif currentState == STATE.BITING then
			self:HookFish()
		end
	end)
	
	-- Diving Gear
	divingGearTool = Instance.new("Tool")
	divingGearTool.Name = "Diving Gear"
	divingGearTool.ToolTip = isMobile and "Tap to toggle diving" or "Click to toggle diving"
	divingGearTool.RequiresHandle = false
	divingGearTool.CanBeDropped = false
	divingGearTool.Parent = localPlayer:WaitForChild("Backpack")
	divingGearTool.Activated:Connect(function()
		local DivingController = Knit.GetController("DivingController")
		if DivingController then
			if DivingController.isDiving then DivingController:EndDive() else DivingController:StartDive() end
		end
	end)
	
	-- Harvest Tool
	harvestTool = Instance.new("Tool")
	harvestTool.Name = "Harvest Tool"
	harvestTool.ToolTip = "Collect resources"
	harvestTool.RequiresHandle = false
	harvestTool.CanBeDropped = false
	harvestTool.Parent = localPlayer:WaitForChild("Backpack")
	harvestTool.Activated:Connect(function()
		self:HarvestNearestNode()
	end)
	
	print("[FishingController] Tools created")
end

-- ============================================================
-- CASTING: Parabolic arc → bobber → splash
-- ============================================================

function FishingController:BeginCast()
	local tierCfg = ROD_TIERS[currentRodTier]
	
	-- Calculate cast target in front of player
	local character = localPlayer.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local forward = rootPart.CFrame.LookVector
	forward = Vector3.new(forward.X, 0, forward.Z).Unit -- Flatten to horizontal
	local targetPos = rootPart.Position + forward * tierCfg.CastDist
	targetPos = Vector3.new(targetPos.X, waterSurfaceY, targetPos.Z) -- Place on water
	
	currentState = STATE.CASTING
	
	-- Play cast sound
	self:NotifyUI("Casting", {})
	
	-- Animate bobber throw with parabolic arc (0.4s)
	self:AnimateCastArc(rootPart.Position, targetPos, function()
		-- Bobber lands — create visual
		self:CreateBobber(targetPos)
		currentState = STATE.FLOATING
		
		-- Ripple effect
		self:CreateRipple(targetPos)
		
		-- Tell server we cast
		local ToolService = Knit.GetService("ToolService")
		if ToolService then
			ToolService:CastLine(currentRodTier)
		end
	end)
end

function FishingController:AnimateCastArc(fromPos, toPos, callback)
	-- Create a temporary visual projectile for the cast arc
	-- Simplified: just create a small part that flies to the target
	local projectile = Instance.new("Part")
	projectile.Size = Vector3.new(0.3, 0.3, 0.3)
	projectile.Shape = Enum.PartType.Ball
	projectile.BrickColor = BrickColor.new("Bright red")
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.Position = fromPos + Vector3.new(0, 3, 0)
	projectile.Parent = Workspace
	
	local startTime = os.clock()
	local duration = 0.4
	
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local t = math.min(elapsed / duration, 1.0)
		
		-- Parabolic arc
		local pos = fromPos:Lerp(toPos, t)
		local arcHeight = math.sin(t * math.pi) * 8 -- 8 studs high
		pos = Vector3.new(pos.X, pos.Y + arcHeight, pos.Z)
		projectile.Position = pos
		
		if t >= 1.0 then
			connection:Disconnect()
			projectile:Destroy()
			if callback then callback() end
		end
	end)
end

function FishingController:CreateBobber(position)
	-- Simple bobber part on water surface
	bobberPart = Instance.new("Part")
	bobberPart.Name = "Bobber"
	bobberPart.Size = Vector3.new(1, 0.5, 1)
	bobberPart.Shape = Enum.PartType.Ball
	bobberPart.BrickColor = BrickColor.new("Bright red")
	bobberPart.Position = position
	bobberPart.Anchored = true
	bobberPart.CanCollide = false
	bobberPart.Parent = Workspace
	
	-- Splash particles
	self:CreateSplash(position)
end

function FishingController:CreateSplash(position)
	-- Small ripple/splash effect (simplified — in production use ParticleEmitter)
	local splash = Instance.new("Part")
	splash.Size = Vector3.new(3, 0.1, 3)
	splash.Position = Vector3.new(position.X, waterSurfaceY + 0.05, position.Z)
	splash.Anchored = true
	splash.CanCollide = false
	splash.Transparency = 0.5
	splash.BrickColor = BrickColor.new("White")
	splash.Parent = Workspace
	
	-- Expand and fade
	local sizeTween = TweenService:Create(splash,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(8, 0.1, 8), Transparency = 1})
	sizeTween:Play()
	sizeTween.Completed:Wait()
	splash:Destroy()
end

function FishingController:CreateRipple(position)
	-- Animated ripple rings at bobber location
	for i = 1, 3 do
		task.delay(0.15 * i, function()
			local ring = Instance.new("Part")
			ring.Size = Vector3.new(2, 0.05, 2)
			ring.Shape = Enum.PartType.Cylinder
			ring.Position = Vector3.new(position.X, waterSurfaceY + 0.02, position.Z)
			ring.Anchored = true
			ring.CanCollide = false
			ring.Transparency = 0.6
			ring.BrickColor = BrickColor.new("Toothpaste")
			ring.Parent = Workspace
			
			TweenService:Create(ring,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = Vector3.new(10, 0.05, 10), Transparency = 1}):Play()
			task.delay(2, function() ring:Destroy() end)
		end)
	end
end

-- ============================================================
-- FLOATING: Bobber bobs on water, fish shadow approaches
-- ============================================================

function FishingController:StartBiteWait(data)
	currentState = STATE.FLOATING
	biteTimer = os.clock() + (data.biteTime or 5)
	
	-- Bobber bobbing animation
	self:AnimateBobberBobbing()
	
	-- Start bite check loop
	task.spawn(function()
		while currentState == STATE.FLOATING do
			task.wait(0.2)
			-- Show fish shadow approaching after ~70% of wait time
			local elapsed = biteTimer - os.clock()
			local totalWait = data.biteTime or 5
			if elapsed < totalWait * 0.3 and not fishShadow then
				self:ShowFishShadow()
			end
			-- Bobber animation intensifies as bite approaches
			if elapsed < 1.5 then
				self:AnimateBobberAgitation()
			end
		end
	end)
	
	-- Timer-based bite trigger (server-independent fallback)
	task.delay(data.biteTime or 5, function()
		if currentState == STATE.FLOATING then
			self:TriggerBite()
		end
	end)
end

function FishingController:AnimateBobberBobbing()
	if not bobberPart or bobberPart.Parent == nil then return end
	
	task.spawn(function()
		while currentState == STATE.FLOATING or currentState == STATE.BITING do
			local bobY = waterSurfaceY + math.sin(os.clock() * 3) * 0.3
			bobberPart.Position = Vector3.new(bobberPart.Position.X, bobY, bobberPart.Position.Z)
			task.wait(0.05)
		end
	end)
end

function FishingController:AnimateBobberAgitation()
	if not bobberPart or currentState ~= STATE.FLOATING then return end
	-- Bobber bobs faster and deeper as fish approaches
	local fastBobY = waterSurfaceY + math.sin(os.clock() * 8) * 0.6
	bobberPart.Position = Vector3.new(bobberPart.Position.X, fastBobY, bobberPart.Position.Z)
end

function FishingController:ShowFishShadow()
	if not bobberPart then return end
	
	fishShadow = Instance.new("Part")
	fishShadow.Size = Vector3.new(3, 0.1, 6)
	fishShadow.BrickColor = BrickColor.new("Really black")
	fishShadow.Transparency = 0.7
	fishShadow.Anchored = true
	fishShadow.CanCollide = false
	fishShadow.Position = Vector3.new(
		bobberPart.Position.X + math.random(-5, 5),
		waterSurfaceY - 5,
		bobberPart.Position.Z + math.random(-5, 5)
	)
	fishShadow.Parent = Workspace
	
	-- Shadow circles toward bobber
	TweenService:Create(fishShadow,
		TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{Position = Vector3.new(bobberPart.Position.X, waterSurfaceY - 3, bobberPart.Position.Z)}
	):Play()
end

-- ============================================================
-- BITING: Bobber plunges, 2-second window
-- ============================================================

function FishingController:TriggerBite()
	if currentState ~= STATE.FLOATING then return end
	currentState = STATE.BITING
	biteWindowEnd = os.clock() + 2.0
	
	-- Bobber VIOLENTLY plunges
	if bobberPart then
		TweenService:Create(bobberPart,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{Position = Vector3.new(bobberPart.Position.X, waterSurfaceY - 3, bobberPart.Position.Z)}
		):Play()
	end
	
	-- Splash effect
	if bobberPart then
		self:CreateSplash(bobberPart.Position)
	end
	
	-- Screen flash
	self:NotifyUI("FishBite", { reelWindow = 2.0 })
	self:NotifyUI("GameMessage", { Text = "FISH ON! Tap anywhere!", Type = "Action" })
	
	-- Check if player misses the window
	task.delay(2.0, function()
		if currentState == STATE.BITING then
			self:OnFishEscape("tooSlow")
		end
	end)
end

function FishingController:OnFishEscape(reason)
	if fishShadow and fishShadow.Parent then
		-- Fish swims away with bubble trail
		local escapeTween = TweenService:Create(fishShadow,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad),
			{Position = fishShadow.Position + Vector3.new(math.random(-20, 20), waterSurfaceY - 15, math.random(-20, 20)), Transparency = 1})
		escapeTween:Play()
		task.delay(1, function() if fishShadow then fishShadow:Destroy(); fishShadow = nil end end)
	end
	
	self:CleanupFishing()
	currentState = STATE.IDLE
	
	local msg = reason == "tooSlow" and "Too slow! Try again." or "The big one got away..."
	self:NotifyUI("GameMessage", { Text = msg, Type = "Warning" })
	self:NotifyUI("FishingEnded", { result = "Escaped" })
end

-- ============================================================
-- HOOKING: Rod bends, line strains, 1-second struggle
-- ============================================================

function FishingController:HookFish()
	if currentState ~= STATE.BITING then return end
	currentState = STATE.HOOKING
	
	-- Line tightens, rod bends (visual feedback)
	self:NotifyUI("Reeling", {})
	
	-- 1-second struggle
	task.delay(0.3, function()
		if currentState ~= STATE.HOOKING then return end
		
		-- Fish splashes at surface
		if fishShadow then
			TweenService:Create(fishShadow,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{Position = Vector3.new(fishShadow.Position.X, waterSurfaceY, fishShadow.Position.Z)}
			):Play()
		end
	end)
	
	-- 5% chance fish escapes
	local escapes = math.random() <= 0.05
	
	task.delay(1.0, function()
		if currentState ~= STATE.HOOKING then return end
		
		if escapes then
			-- LINE SNAP!
			self:OnFishEscape("snapped")
		else
			-- Fish caught! Call server to process
			currentState = STATE.REELING
			local ToolService = Knit.GetService("ToolService")
			if ToolService then
				ToolService:ReelIn()
			end
		end
	end)
end

-- ============================================================
-- CATCH RESULT
-- ============================================================

function FishingController:OnFishResult(data)
	currentState = STATE.IDLE
	self:CleanupFishing()
	
	if data.result == "Caught" then
		local creature = data.creature
		if creature then
			-- Fish leaps out of water! (visual)
			self:AnimateFishLeap(data)
			
			self:NotifyUI("GameMessage", {
				Text = string.format("Caught %s! Worth %d credits",
					creature.displayName or "something",
					data.sellPrice or 0),
				Type = "Success",
			})
		end
	elseif data.result == "Escaped" then
		self:OnFishEscape("escaped")
	end
	
	self:NotifyUI("FishingEnded", { result = data.result })
end

function FishingController:AnimateFishLeap(data)
	if not bobberPart then return end
	
	local leapPart = Instance.new("Part")
	leapPart.Size = Vector3.new(1, 1, 3)
	leapPart.BrickColor = BrickColor.new("Bright blue") -- Should use creature color
	leapPart.Anchored = true
	leapPart.CanCollide = false
	leapPart.Position = bobberPart.Position
	leapPart.Parent = Workspace
	
	local peakY = waterSurfaceY + 10
	local landY = waterSurfaceY
	
	-- Leap up
	TweenService:Create(leapPart,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = Vector3.new(leapPart.Position.X, peakY, leapPart.Position.Z)}
	):Play()
	
	-- Spin mid-air then splash
	task.delay(0.3, function()
		TweenService:Create(leapPart,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = Vector3.new(leapPart.Position.X, landY - 1, leapPart.Position.Z)}
		):Play()
	end)
	
	-- Cleanup
	task.delay(1, function() if leapPart then leapPart:Destroy() end end)
end

function FishingController:CleanupFishing()
	if bobberPart and bobberPart.Parent then bobberPart:Destroy() end
	bobberPart = nil
	if fishShadow and fishShadow.Parent then fishShadow:Destroy() end
	fishShadow = nil
	biteTimer = 0
	biteWindowEnd = 0
	fishData = nil
	currentState = STATE.IDLE
end

-- ============================================================
-- HARVEST TOOL
-- ============================================================

function FishingController:HarvestNearestNode()
	local camera = Workspace.CurrentCamera
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = { localPlayer.Character }
	
	local rayResult = Workspace:Raycast(
		camera.CFrame.Position,
		camera.CFrame.LookVector * 30,
		raycastParams
	)
	
	if rayResult then
		local harvestType = rayResult.Instance:GetAttribute("ResourceType")
			or (rayResult.Instance:GetAttribute("CreatureNode") and "CreatureEncounter")
		
		if harvestType then
			local ToolService = Knit.GetService("ToolService")
			if ToolService then
				self:NotifyUI("Harvesting", { type = harvestType })
				ToolService:HarvestNode(harvestType)
			end
		end
	end
end

function FishingController:OnHarvestResult(data)
	if data and data.type then
		self:NotifyUI("GameMessage", {
			Text = string.format("Collected %d %s", data.amount or 0, data.type),
			Type = "Success",
		})
	end
end

-- ============================================================
-- UI Communication
-- ============================================================

function FishingController:NotifyUI(eventName, data)
	local UIController = Knit.GetController("UIController")
	if UIController and UIController.HandleFishingEvent then
		UIController:HandleFishingEvent(eventName, data)
	end
end

-- ============================================================
-- Cleanup
-- ============================================================

function FishingController:KnitStop()
	self:CleanupFishing()
	if rodTool and rodTool.Parent then rodTool:Destroy() end
	if divingGearTool and divingGearTool.Parent then divingGearTool:Destroy() end
	if harvestTool and harvestTool.Parent then harvestTool:Destroy() end
end

return FishingController