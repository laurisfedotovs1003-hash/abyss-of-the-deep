--[[
	FXController — ASMR-style feedback, haptics, and premium audio-visual experience
	Client-side controller for coordinated catch satisfaction, upgrade joy, micro-feedback,
	and Audio Ambience 2.0 that makes every action in Abyss of the Deep feel rewarding.
	
	Architecture: Connects to existing services (Creature, Economy, Depth, Anomaly, Audio)
	and enhances their signals with coordinated multi-sensory feedback sequences.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local UIStyles = require(script.Parent.Parent.ui.UIStyles)

local FXController = Knit.CreateController {
	Name = "FXController",
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- ============================================================
-- State
-- ============================================================

local currentCamera = Workspace.CurrentCamera
local isDiving = false
local currentDepth = 0
local maxDepth = 0
local currentZoneIndex = 1
local activeEffects = {}        -- { [key] = Tween/Connection }
local proximityCreature = nil   -- Nearest creature within hearing range
local underwaterFilter = nil   -- SoundService equalizer/low-pass
local heartbeatSound = nil     -- Looping heartbeat for oxygen warning
local lastCoinPitch = 1         -- Tracks coin sound pitch for ascending cascade

-- ============================================================
-- Rarity Visuals
-- ============================================================

local RARITY_CONFIG = {
	Common = {
		Color = UIStyles.Colors.RarityCommon or Color3.fromRGB(180, 180, 180),
		Name = "Common",
		FlashIntensity = 0.3,
		ParticleCount = 8,
		ScreenShake = 0,
	},
	Uncommon = {
		Color = UIStyles.Colors.RarityUncommon or Color3.fromRGB(30, 200, 80),
		Name = "Uncommon",
		FlashIntensity = 0.5,
		ParticleCount = 16,
		ScreenShake = 1,
	},
	Rare = {
		Color = UIStyles.Colors.RarityRare or Color3.fromRGB(30, 144, 255),
		Name = "Rare",
		FlashIntensity = 0.7,
		ParticleCount = 24,
		ScreenShake = 2,
	},
	Epic = {
		Color = UIStyles.Colors.RarityEpic or Color3.fromRGB(180, 0, 255),
		Name = "Epic",
		FlashIntensity = 0.9,
		ParticleCount = 36,
		ScreenShake = 4,
	},
	Legendary = {
		Color = UIStyles.Colors.RarityLegendary or Color3.fromRGB(255, 180, 0),
		Name = "Legendary",
		FlashIntensity = 1.0,
		ParticleCount = 50,
		ScreenShake = 6,
	},
	Anomaly = {
		Color = UIStyles.Colors.RarityAnomaly or Color3.fromRGB(255, 50, 50),
		Name = "Anomaly",
		FlashIntensity = 1.2,
		ParticleCount = 75,
		ScreenShake = 10,
	},
}

-- ============================================================
-- Helpers
-- ============================================================

local function New(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function Lerp(a, b, t)
	return a + (b - a) * t
end

-- ============================================================
-- HAPTIC SYSTEM
-- ============================================================

function FXController:TriggerHaptic(motor, pattern)
	-- motor: "Large", "Small", "Left", "Right", "Both"
	-- pattern: "rumble", "click", "pulse"
	pcall(function()
		if not HapticService then return end
		
		local patterns = {
			rumble = function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0.6)
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.3)
				task.delay(0.2, function()
					pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0) end)
					pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0) end)
				end)
			end,
			click = function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.4)
				task.delay(0.05, function()
					pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0) end)
				end)
			end,
			pulse = function()
				for i = 1, 3 do
					task.delay((i - 1) * 0.15, function()
						pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0.3 + i * 0.1) end)
						task.delay(0.08, function()
							pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0) end)
						end)
					end)
				end
			end,
			heavy = function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0.8)
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.5)
				task.delay(0.4, function()
					pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0) end)
					pcall(function() HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0) end)
				end)
			end,
		}
		
		if patterns[pattern] then
			patterns[pattern]()
		end
	end)
end

-- ============================================================
-- SCREEN EFFECTS
-- ============================================================

function FXController:ScreenFlash(intensity, color, duration)
	local screenGui = nil
	pcall(function()
		screenGui = Player.PlayerGui:FindFirstChild("AbyssUI")
	end)
	if not screenGui then return end

	local flash = New("Frame", {
		Name = "ScreenFlash",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = color or Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Parent = screenGui,
	})

	local tween = TweenService:Create(flash,
		TweenInfo.new((duration or 0.3) * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 - (intensity or 0.5) }
	)
	local tweenOut = TweenService:Create(flash,
		TweenInfo.new((duration or 0.3) * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ BackgroundTransparency = 1 }
	)

	tween.Completed:Connect(function()
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			flash:Destroy()
		end)
	end)
	tween:Play()
end

function FXController:ScreenShake(magnitude, duration)
	if not currentCamera then return end
	magnitude = magnitude or 2
	duration = duration or 0.3

	local startPos = currentCamera.CFrame.Position
	local startTime = tick()

	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			currentCamera.CFrame = CFrame.new(startPos) * CFrame.Angles(0, 0, 0)
			connection:Disconnect()
			return
		end
		local decay = 1 - (elapsed / duration)
		local shakeX = (math.random() - 0.5) * magnitude * 2 * decay
		local shakeY = (math.random() - 0.5) * magnitude * 2 * decay
		local shakeZ = (math.random() - 0.5) * magnitude * decay
		currentCamera.CFrame = CFrame.new(startPos) * CFrame.Angles(shakeX * 0.01, shakeY * 0.01, shakeZ * 0.01)
	end)
end

function FXController:CameraZoom(targetFov, duration, callback)
	if not currentCamera then return end
	local startFov = currentCamera.FieldOfView
	local startTime = tick()

	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local t = math.min(elapsed / (duration or 0.5), 1)
		-- Ease in-out
		local eased = t < 0.5 and 2 * t * t or 1 - math.pow(-2 * t + 2, 2) / 2
		currentCamera.FieldOfView = Lerp(startFov, targetFov, eased)
		if t >= 1 then
			connection:Disconnect()
			if callback then callback() end
		end
	end)
end

-- ============================================================
-- PARTICLE SYSTEM
-- ============================================================

function FXController:SpawnParticles(position, color, count, size, lifetime)
	local container = New("Part", {
		Name = "FeedbackParticles",
		Position = position or (Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position) or Vector3.zero,
		Anchored = true,
		CanCollide = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		Parent = Workspace,
	})

	local particleList = {}
	for i = 1, (count or 10) do
		local p = New("Part", {
			Name = "Particle",
			Position = container.Position,
			Size = Vector3.new((size or 0.2), (size or 0.2), (size or 0.2)),
			Shape = Enum.PartType.Ball,
			Color = color or Color3.new(1, 1, 1),
			Material = Enum.Material.Neon,
			Anchored = true,
			CanCollide = false,
			Parent = container,
		})

		-- Random velocity
		local vel = Vector3.new(
			(math.random() - 0.5) * 10,
			math.random() * 8 + 2,
			(math.random() - 0.5) * 10
		)

		local startTime = tick()
		local life = lifetime or 1.5
		table.insert(particleList, { part = p, vel = vel, startTime = startTime, life = life })
	end

	-- Animate particles
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local allDone = true
		for _, particle in ipairs(particleList) do
			local elapsed = tick() - particle.startTime
			if elapsed < particle.life then
				allDone = false
				local alpha = 1 - (elapsed / particle.life)
				particle.part.Position = particle.part.Position + particle.vel * dt * alpha
				particle.part.Transparency = 1 - (alpha * 0.7)
				particle.part.Size = particle.part.Size * 0.995
			else
				particle.part:Destroy()
			end
		end
		if allDone then
			connection:Disconnect()
			container:Destroy()
		end
	end)

	-- Safety cleanup
	task.delay((lifetime or 1.5) + 0.5, function()
		if container and container.Parent then
			container:Destroy()
		end
	end)
end

-- ============================================================
-- SECTION 1: CATCH SATISFACTION SYSTEM
-- ============================================================

-- Stage 1: Hook — creature bites, time to react
function FXController:PlayCatchStageHook(data)
	if not data then return end
	local rarity = data.rarity or "Common"
	local config = RARITY_CONFIG[rarity] or RARITY_CONFIG.Common

	-- Haptic rumble
	self:TriggerHaptic("Both", "rumble")

	-- Camera zoom in slightly
	self:CameraZoom(55, 0.3)

	-- Audio: the 'bite' sound (already defined in AudioController CreatureSpawned/Caught)
	local AudioController = Knit.GetController("AudioController")
	if AudioController and AudioController.PlaySFX then
		AudioController:PlaySFX("CreatureSpawned")
	end

	print("[FXController] Catch Hook — rarity:", rarity)
end

-- Stage 2: Struggle — reeling in, tension building
function FXController:PlayCatchStageStruggle(data)
	if not data then return end
	local rarity = data.rarity or "Common"
	local config = RARITY_CONFIG[rarity] or RARITY_CONFIG.Common

	-- Pulsing haptic as the line fights
	self:TriggerHaptic("Both", "pulse")

	-- Screen shake proportional to creature rarity
	if config.ScreenShake > 0 then
		self:ScreenShake(config.ScreenShake, 0.5)
	end

	-- Keep camera tight during struggle
	self:CameraZoom(58, 0.2)

	print("[FXController] Catch Struggle — rarity:", rarity)
end

-- Stage 3: Reel — SUCCESS! The catch is secured
function FXController:PlayCatchStageReel(data)
	if not data then return end
	local rarity = data.rarity or "Common"
	local config = RARITY_CONFIG[rarity] or RARITY_CONFIG.Common

	-- Heavy haptic on success
	self:TriggerHaptic("Both", "heavy")

	-- Screen flash with rarity color
	self:ScreenFlash(config.FlashIntensity, config.Color, 0.6)

	-- Particle burst around player
	local pos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position
	if pos then
		self:SpawnParticles(pos, config.Color, config.ParticleCount, 0.25, 2.0)
	end

	-- Camera snap back + slight bounce
	self:CameraZoom(70, 0.4, function()
		self:CameraZoom(70, 0.1)
	end)

	-- Audio: satisfying 'pop' catch sound
	local AudioController = Knit.GetController("AudioController")
	if AudioController then
		AudioController:PlaySFX("CreatureCaught")
		if data.isFirstDiscovery then
			AudioController:PlaySFX("MilestoneReached")
		end
	end

	-- Rarity-specific extra effects
	if rarity == "Epic" or rarity == "Legendary" or rarity == "Anomaly" then
		-- Extra confetti / glow
		if pos then
			self:SpawnParticles(pos + Vector3.new(0, 3, 0), UIStyles.Colors.Gold, 20, 0.3, 3.0)
		end
		self:ScreenShake(config.ScreenShake * 1.5, 0.8)
	end

	print("[FXController] Catch Reel — SUCCESS! rarity:", rarity)
end

-- Full catch sequence
function FXController:PlayCatchSequence(data)
	self:PlayCatchStageHook(data)
	task.delay(0.3, function()
		self:PlayCatchStageStruggle(data)
	end)
	task.delay(0.8, function()
		self:PlayCatchStageReel(data)
	end)
end

-- ============================================================
-- SECTION 2: UPGRADE SATISFACTION
-- ============================================================

-- Gear upgrade animation
function FXController:PlayGearUpgrade(data)
	if not data then return end
	local gearName = data.gearName or "Gear"
	local tier = data.tier or 1

	-- Screen shake
	self:ScreenShake(tier * 2, 0.6)

	-- Golden flash
	self:ScreenFlash(0.6, UIStyles.Colors.Gold, 0.8)

	-- Particle burst representing 'old gear'
	local pos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position
	if pos then
		self:SpawnParticles(pos, Color3.fromRGB(100, 100, 100), 12, 0.15, 1.0)
		task.delay(0.4, function()
			-- New gear assembles with golden light rays
			self:SpawnParticles(pos + Vector3.new(0, 2, 0), UIStyles.Colors.Gold, 20, 0.25, 2.0)
		end)
	end

	-- Audio
	local AudioController = Knit.GetController("AudioController")
	if AudioController and AudioController.PlaySFX then
		task.delay(0.2, function()
			AudioController:PlaySFX("UIPurchase")
		end)
		task.delay(0.6, function()
			AudioController:PlaySFX("LevelUp")
		end)
	end

	print("[FXController] Gear upgraded:", gearName, "→ Tier", tier)
end

-- Level-up fanfare with confetti + sound crescendo
function FXController:PlayLevelUp(data)
	if not data then return end
	local level = data.level or 1

	-- Screen shake proportional to level
	self:ScreenShake(math.min(level * 0.5, 8), 0.8)

	-- Golden light flash
	self:ScreenFlash(0.8, UIStyles.Colors.Gold, 1.0)

	-- Confetti burst
	local pos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position
	if pos then
		-- Multicolor confetti
		for _, color in ipairs({UIStyles.Colors.Cyan, UIStyles.Colors.Gold, UIStyles.Colors.DeepPurple, UIStyles.Colors.BioGreen}) do
			self:SpawnParticles(pos + Vector3.new(0, 2, 0), color, 8, 0.2, 2.5)
		end
	end

	-- Audio: level up chime
	local AudioController = Knit.GetController("AudioController")
	if AudioController then
		AudioController:PlaySFX("LevelUp")
	end

	-- Haptic pulse
	self:TriggerHaptic("Both", "pulse")

	print("[FXController] Level Up! →", level)
end

-- Base module construction complete
function FXController:PlayModuleComplete(data)
	if not data then return end
	local moduleName = data.moduleName or "Module"

	-- Heavy screen shake
	self:ScreenShake(5, 0.7)

	-- Bright flash
	self:ScreenFlash(0.7, UIStyles.Colors.Cyan, 1.0)

	local AudioController = Knit.GetController("AudioController")
	if AudioController and AudioController.PlaySFX then
		AudioController:PlaySFX("ModulePlace")
	end

	self:TriggerHaptic("Both", "heavy")

	print("[FXController] Module built:", moduleName)
end

-- Quest completion dopamine hit
function FXController:PlayQuestComplete(data)
	if not data then return end
	local questName = data.questName or "Quest"

	-- Golden glow
	self:ScreenFlash(0.5, UIStyles.Colors.Gold, 1.2)

	-- Sparkles
	local pos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position
	if pos then
		self:SpawnParticles(pos + Vector3.new(0, 1.5, 0), UIStyles.Colors.Gold, 15, 0.2, 2.0)
	end

	-- Cash register + milestone sounds
	local AudioController = Knit.GetController("AudioController")
	if AudioController then
		AudioController:PlaySFX("UIPurchase")
		task.delay(0.3, function()
			AudioController:PlaySFX("MilestoneReached")
		end)
	end

	self:TriggerHaptic("Both", "pulse")

	print("[FXController] Quest completed:", questName)
end

-- ============================================================
-- SECTION 3: MICRO-FEEDBACK
-- ============================================================

-- Button press: subtle haptic click + scale tween
function FXController:PlayButtonFeedback(button)
	self:TriggerHaptic("Small", "click")
	if button and button:IsA("GuiObject") then
		local originalSize = button.Size
		local tweenIn = TweenService:Create(button,
			TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = originalSize * 1.05 }
		)
		local tweenOut = TweenService:Create(button,
			TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{ Size = originalSize }
		)
		tweenIn:Play()
		tweenIn.Completed:Connect(function() tweenOut:Play() end)
	end
end

-- Currency gain: coin sounds that pitch up with larger amounts
function FXController:PlayCurrencyGain(amount, currencyType)
	local AudioController = Knit.GetController("AudioController")
	if not AudioController then return end

	-- Pitch: bigger amounts = higher pitch cascade
	local numPings = math.min(math.ceil(math.log10(math.max(amount, 1))) + 1, 8)
	for i = 1, numPings do
		task.delay((i - 1) * 0.06, function()
			if currencyType == "Credits" then
				AudioController:PlaySFX("UIPurchase")
			else
				AudioController:PlaySFX("UIClick")
			end
		end)
	end

	-- Screen micro-flash for large amounts
	if amount >= 500 then
		self:ScreenFlash(0.15, UIStyles.Colors.Gold, 0.3)
	elseif amount >= 100 then
		self:ScreenFlash(0.08, UIStyles.Colors.Cyan, 0.2)
	end

	print("[FXController] Currency gained: +" .. tostring(amount) .. " " .. tostring(currencyType))
end

-- Resource collection: Scrap = metallic clink, Crystal = glass chime
function FXController:PlayResourceCollect(resourceType)
	local AudioController = Knit.GetController("AudioController")
	if not AudioController then return end

	if resourceType == "Scrap" then
		-- Metallic, heavier feel
		AudioController:PlaySFX("ModulePlace")
		self:TriggerHaptic("Small", "click")
	elseif resourceType == "Crystal" then
		-- Glass chime, lighter
		AudioController:PlaySFX("UIClick")
		self:TriggerHaptic("Small", "click")
	else
		AudioController:PlaySFX("UIClick")
	end

	print("[FXController] Resource collected:", resourceType)
end

-- Creature sell: coins shower effect scaled to value
function FXController:PlayCreatureSell(data)
	if not data then return end
	local value = data.sellPrice or 0
	local pos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position

	if pos and value > 0 then
		local coinCount = math.min(math.floor(value / 10), 30)
		for i = 1, coinCount do
			task.delay(i * 0.04, function()
				self:SpawnParticles(
					pos + Vector3.new((math.random() - 0.5) * 4, 1 + math.random() * 3, (math.random() - 0.5) * 4),
					UIStyles.Colors.Gold,
					1, 0.15, 1.5
				)
			end)
		end
	end

	local AudioController = Knit.GetController("AudioController")
	if AudioController then
		for i = 1, math.min(math.ceil(value / 50), 5) do
			task.delay(i * 0.08, function()
				AudioController:PlaySFX("UIPurchase")
			end)
		end
	end

	print("[FXController] Creature sold:", data.name, "for", value)
end

-- Oxygen warning: escalating heartbeat sound
function FXController:SetOxygenWarning(isActive, isCritical)
	if isActive and not heartbeatSound then
		-- Start heartbeat
		heartbeatSound = New("Sound", {
			SoundId = "rbxassetid://0", -- Placeholder, will use AudioController's OxygenLow/OxygenCritical
			Volume = 0.3,
			Looped = true,
			Parent = SoundService,
		})
		heartbeatSound:Play()
	elseif not isActive and heartbeatSound then
		if heartbeatSound.Parent then
			heartbeatSound:Stop()
			heartbeatSound:Destroy()
		end
		heartbeatSound = nil
	end
end

-- ============================================================
-- SECTION 4: AUDIO AMBIENCE 2.0
-- ============================================================

-- Underwater muffled audio filter (low-pass when diving)
function FXController:SetUnderwaterFilter(enabled)
	if enabled and not underwaterFilter then
		-- Apply low-pass EQ to SoundService
		pcall(function()
			underwaterFilter = New("EqualizerSoundEffect", {
				Name = "UnderwaterMuffled",
				HighGain = -80,
				MidGain = -40 + -20 * (currentDepth / (maxDepth or 1000)),
				LowGain = 0,
				Parent = SoundService,
			})
		end)
	elseif not enabled and underwaterFilter then
		if underwaterFilter.Parent then
			underwaterFilter:Destroy()
		end
		underwaterFilter = nil
	end
end

-- Surface vs depth audio mix: more bass as you go deeper
function FXController:UpdateDepthAudioMix(depth)
	if not underwaterFilter then return end
	local depthRatio = math.clamp(depth / (maxDepth or 6000), 0, 1)
	pcall(function()
		-- More bass, less treble at depth
		underwaterFilter.HighGain = -80 * depthRatio
		underwaterFilter.MidGain = -40 - 20 * depthRatio
	end)
end

-- Creature proximity sounds: hear them before you see them
function FXController:SetCreatureProximity(creatureData)
	if not creatureData then
		proximityCreature = nil
		return
	end
	if not Player.Character or not Player.Character.PrimaryPart then return end

	local playerPos = Player.Character.PrimaryPart.Position
	local creaturePos = creatureData.Position or playerPos
	local distance = (playerPos - creaturePos).Magnitude
	local maxHearDistance = creatureData.maxHearDistance or 200

	if distance <= maxHearDistance then
		local alpha = 1 - math.clamp(distance / maxHearDistance, 0, 1)

		-- Spawn proximity sound if close enough
		if not proximityCreature and alpha > 0.5 then
			proximityCreature = New("Sound", {
				SoundId = "rbxassetid://0", -- Placeholder for creature proximity
				Volume = 0.2 * alpha,
				Looped = true,
				Parent = SoundService,
			})
			proximityCreature:Play()
		elseif proximityCreature then
			proximityCreature.Volume = 0.2 * alpha
		end
	elseif proximityCreature then
		proximityCreature:Stop()
		proximityCreature:Destroy()
		proximityCreature = nil
	end
end

-- Ambient sound triggers for environmental events
function FXController:TriggerAmbientEvent(eventType, data)
	local AudioController = Knit.GetController("AudioController")
	if not AudioController then return end

	local events = {
		storm = function()
			AudioController:PlaySFX("AnomalyWarning")
			self:ScreenShake(3, 0.5)
		end,
		whale_song = function()
			AudioController:PlaySFX("CreatureSpawned")
			AudioController:PlaySFX("MilestoneReached")
		end,
		migration = function()
			AudioController:PlaySFX("AnomalyStart")
		end,
		calm = function()
			-- Returns to exploration music
			AudioController:PlayMusic("Exploration")
		end,
	}

	if events[eventType] then
		events[eventType]()
	end
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

function FXController:KnitStart()
	print("[FXController] ASMR feedback system initialized")

	-- Hook into existing service signals for enhanced feedback

	-- Creature catch signals
	local CreatureService = Knit.GetService("CreatureService")
	if CreatureService then
		CreatureService.Client:Get("CreatureCaught"):Connect(function(data)
			self:PlayCatchSequence(data)
		end)
	end

	-- Economy signals — currency gain
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService then
		EconomyService.Client:Get("EconomyUpdated"):Connect(function(data)
			if data.LevelUp then
				self:PlayLevelUp({ level = data.Level })
			end
			if data.LastTransaction and data.LastTransaction.amount > 0 then
				self:PlayCurrencyGain(data.LastTransaction.amount, data.LastTransaction.type)
			end
		end)
	end

	-- Depth signals — update audio mix
	local DepthService = Knit.GetService("DepthService")
	if DepthService then
		DepthService.Client:Get("GetDepthData"):Connect(function(data)
			currentDepth = data.depth or 0
			self:UpdateDepthAudioMix(currentDepth)

			-- Toggle underwater filter when diving/surfacing
			if data.diveComplete then
				self:SetUnderwaterFilter(false)
				isDiving = false
			elseif not isDiving and data.depth > 0 then
				isDiving = true
				self:SetUnderwaterFilter(true)
			end

			-- Creature proximity
			if data.creatureData then
				self:SetCreatureProximity(data.creatureData)
			end
		end)

		DepthService.Client:Get("GetLayerInfo"):Connect(function(data)
			currentZoneIndex = data.index or 1
		end)
	end

	-- Anomaly signals
	local AnomalyService = Knit.GetService("AnomalyService")
	if AnomalyService then
		AnomalyService.Client:Get("AnomalyStarted"):Connect(function(data)
			self:TriggerAmbientEvent("storm")
		end)
		AnomalyService.Client:Get("AnomalyEnded"):Connect(function()
			self:TriggerAmbientEvent("calm")
		end)
	end

	-- Base building signals
	local BaseBuildingService = Knit.GetService("BaseBuildingService")
	if BaseBuildingService then
		BaseBuildingService.Client:Get("ModulePlaced"):Connect(function(data)
			self:PlayModuleComplete(data)
		end)
	end

	-- Quest completion signals
	local QuestService = Knit.GetService("QuestService")
	if QuestService then
		QuestService.Client:Get("QuestCompleted"):Connect(function(data)
			self:PlayQuestComplete(data)
		end)
	end

	-- Gear/tool upgrades via tool service
	local ToolService = Knit.GetService("ToolService")
	if ToolService then
		ToolService.Client:Get("ToolUpgraded"):Connect(function(data)
			self:PlayGearUpgrade(data)
		end)
	end

	print("[FXController] All ASMR feedback systems online")
end

-- ============================================================
-- CLEANUP
-- ============================================================

function FXController:KnitStop()
	for _, effect in pairs(activeEffects) do
		pcall(function()
			if effect.Disconnect then effect:Disconnect() end
			if effect.Cancel then effect:Cancel() end
		end)
	end
	activeEffects = {}

	if heartbeatSound and heartbeatSound.Parent then
		heartbeatSound:Destroy()
		heartbeatSound = nil
	end

	if proximityCreature and proximityCreature.Parent then
		proximityCreature:Destroy()
		proximityCreature = nil
	end

	if underwaterFilter and underwaterFilter.Parent then
		underwaterFilter:Destroy()
		underwaterFilter = nil
	end

	print("[FXController] Cleaned up")
end

return FXController