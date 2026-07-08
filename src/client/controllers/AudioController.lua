--[[
	AudioController — Client-side audio manager for Abyss of the Deep
	Listens to service signals and plays appropriate sounds via SoundService.
	
	Architecture: Client-side only — hooks into existing Knit service signals.
	No server AudioService needed; sounds are defined here by zone and event type.
	
	Sounds are expected to be in SoundService under folders matching these keys.
	Uses Roblox Sound objects placed in ReplicatedStorage/Sounds/ at build time.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local AudioController = Knit.CreateController {
	Name = "AudioController",
}

local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

-- ============================================================
-- Sound Definitions
-- ============================================================

local SOUNDS = {
	-- Ambient tracks (looping, zone-specific)
	Ambient = {
		Surface = { SoundId = "rbxassetid://0", Volume = 0.3, Looped = true },
		SunlightZone = { SoundId = "rbxassetid://0", Volume = 0.4, Looped = true },
		TwilightZone = { SoundId = "rbxassetid://0", Volume = 0.5, Looped = true },
		MidnightZone = { SoundId = "rbxassetid://0", Volume = 0.6, Looped = true },
		AbyssalZone = { SoundId = "rbxassetid://0", Volume = 0.7, Looped = true },
		Trenches = { SoundId = "rbxassetid://0", Volume = 0.8, Looped = true },
	},
	
	-- Music tracks (non-looping, one-at-a-time)
	Music = {
		Exploration = { SoundId = "rbxassetid://0", Volume = 0.3 },
		Tension = { SoundId = "rbxassetid://0", Volume = 0.4 },
		Triumph = { SoundId = "rbxassetid://0", Volume = 0.5 },
		Anomaly = { SoundId = "rbxassetid://0", Volume = 0.5 },
	},
	
	-- SFX (one-shot sounds)
	SFX = {
		Dive = { SoundId = "rbxassetid://0", Volume = 0.6 },
		Surface = { SoundId = "rbxassetid://0", Volume = 0.5 },
		OxygenLow = { SoundId = "rbxassetid://0", Volume = 0.4, Looped = true },
		OxygenCritical = { SoundId = "rbxassetid://0", Volume = 0.6, Looped = true },
		CreatureSpawned = { SoundId = "rbxassetid://0", Volume = 0.3 },
		CreatureCaught = { SoundId = "rbxassetid://0", Volume = 0.5 },
		CreatureEscape = { SoundId = "rbxassetid://0", Volume = 0.4 },
		AnomalyWarning = { SoundId = "rbxassetid://0", Volume = 0.6 },
		AnomalyStart = { SoundId = "rbxassetid://0", Volume = 0.7 },
		ModulePlace = { SoundId = "rbxassetid://0", Volume = 0.4 },
		LevelUp = { SoundId = "rbxassetid://0", Volume = 0.6 },
		MilestoneReached = { SoundId = "rbxassetid://0", Volume = 0.5 },
		UIClick = { SoundId = "rbxassetid://0", Volume = 0.2 },
		UIPurchase = { SoundId = "rbxassetid://0", Volume = 0.3 },
	},
}

-- ============================================================
-- State
-- ============================================================

local activeSounds = {}	-- { [key] = Sound }
local currentAmbient = nil	-- Current ambient Sound object
local currentMusic = nil	-- Current music Sound object
local currentZoneIndex = 1
local oxygenWarningActive = false

-- ============================================================
-- Sound Helper
-- ============================================================

local function CreateSound(soundDef, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = soundDef.SoundId
	sound.Volume = soundDef.Volume
	sound.Looped = soundDef.Looped or false
	sound.Parent = parent or SoundService
	return sound
end

local function PlayOneShot(soundDef, parent)
	local sound = CreateSound(soundDef, parent)
	sound:Play()
	-- Clean up after playing
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	-- Safety cleanup after max duration
	task.delay(30, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
	return sound
end

local function PlayLooped(soundDef, key, parent)
	-- Stop existing looped sound with this key
	local existing = activeSounds[key]
	if existing then
		existing:Stop()
		existing:Destroy()
	end
	
	local sound = CreateSound(soundDef, parent)
	sound:Play()
	activeSounds[key] = sound
	return sound
end

local function StopLooped(key)
	local sound = activeSounds[key]
	if sound then
		sound:Stop()
		sound:Destroy()
		activeSounds[key] = nil
	end
end

local function FadeVolume(sound, targetVol, duration)
	if not sound then return end
	local startVol = sound.Volume
	local startTime = tick()
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local t = math.min(elapsed / duration, 1)
		sound.Volume = startVol + (targetVol - startVol) * t
		if t >= 1 then
			connection:Disconnect()
		end
	end)
end

-- ============================================================
-- Initialize
-- ============================================================

function AudioController:KnitStart()
	print("[AudioController] Initialized")
	
	-- Hook into service signals for SFX triggers
	self:HookServiceSignals()
	
	-- Start surface ambient
	self:PlayAmbient("Surface")
end

function AudioController:HookServiceSignals()
	-- Oxygen signals
	local OxygenService = Knit.GetService("OxygenService")
	if OxygenService then
		OxygenService.Client:Get("GetOxygenData"):Connect(function(data)
			if data.isCritical then
				if not oxygenWarningActive then
					oxygenWarningActive = true
					PlayLooped(SOUNDS.SFX.OxygenCritical, "OxygenWarning")
				end
			elseif data.current > Config.Player.OxygenCriticalThreshold then
				if oxygenWarningActive then
					oxygenWarningActive = false
					StopLooped("OxygenWarning")
				end
			end
		end)
	end
	
	-- Depth/Zone signals
	local DepthService = Knit.GetService("DepthService")
	if DepthService then
		DepthService.Client:Get("GetLayerInfo"):Connect(function(data)
			if data.isFirstDiscovery then
				PlayOneShot(SOUNDS.SFX.MilestoneReached)
			end
			self:PlayAmbientForZone(data.index)
		end)
		
		DepthService.Client:Get("GetDepthData"):Connect(function(data)
			if data.diveComplete then
				PlayOneShot(SOUNDS.SFX.Surface)
				StopLooped("OxygenWarning")
				oxygenWarningActive = false
			end
		end)
	end
	
	-- Creature signals
	local CreatureService = Knit.GetService("CreatureService")
	if CreatureService then
		CreatureService.Client:Get("CreatureSpawned"):Connect(function(data)
			if data.rarity == "Epic" or data.rarity == "Legendary" then
				PlayOneShot(SOUNDS.SFX.CreatureSpawned)
			end
		end)
		
		CreatureService.Client:Get("CreatureCaught"):Connect(function(data)
			PlayOneShot(SOUNDS.SFX.CreatureCaught)
			if data.isFirstDiscovery then
				PlayOneShot(SOUNDS.SFX.MilestoneReached)
			end
		end)
	end
	
	-- Economy signals
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService then
		EconomyService.Client:Get("EconomyUpdated"):Connect(function(data)
			-- Check for level up (detect via XP/Level change)
			-- Level-up detection handled by comparing previous level
		end)
	end
	
	-- Anomaly signals
	local AnomalyService = Knit.GetService("AnomalyService")
	if AnomalyService then
		AnomalyService.Client:Get("AnomalyWarning"):Connect(function(data)
			PlayOneShot(SOUNDS.SFX.AnomalyWarning)
		end)
		
		AnomalyService.Client:Get("AnomalyStarted"):Connect(function(data)
			PlayOneShot(SOUNDS.SFX.AnomalyStart)
			self:PlayMusic("Anomaly")
		end)
		
		AnomalyService.Client:Get("AnomalyEnded"):Connect(function()
			self:StopMusic()
			self:PlayMusic("Exploration")
		end)
	end
	
	-- Base building signals
	local BaseBuildingService = Knit.GetService("BaseBuildingService")
	if BaseBuildingService then
		BaseBuildingService.Client:Get("ModulePlaced"):Connect(function(data)
			PlayOneShot(SOUNDS.SFX.ModulePlace)
		end)
	end
end

-- ============================================================
-- Ambient System
-- ============================================================

function AudioController:PlayAmbient(zoneKey)
	-- Stop current ambient
	if currentAmbient then
		FadeVolume(currentAmbient, 0, 2)
		task.delay(2, function()
			if currentAmbient then
				currentAmbient:Stop()
				currentAmbient:Destroy()
				currentAmbient = nil
			end
		end)
	end
	
	-- Start new ambient with fade-in
	local def = SOUNDS.Ambient[zoneKey]
	if not def then return end
	
	task.wait(1.5)
	currentAmbient = CreateSound(def, SoundService)
	currentAmbient.Volume = 0
	currentAmbient:Play()
	FadeVolume(currentAmbient, def.Volume, 3)
end

function AudioController:PlayAmbientForZone(layerIndex)
	local zoneNames = {
		[1] = "SunlightZone",
		[2] = "TwilightZone",
		[3] = "MidnightZone",
		[4] = "AbyssalZone",
		[5] = "Trenches",
	}
	
	local key = zoneNames[layerIndex]
	if key and key ~= currentAmbient then
		self:PlayAmbient(key)
	end
	currentZoneIndex = layerIndex
end

-- ============================================================
-- Music System
-- ============================================================

function AudioController:PlayMusic(musicKey)
	-- Stop current music
	if currentMusic then
		currentMusic:Stop()
		currentMusic:Destroy()
		currentMusic = nil
	end
	
	local def = SOUNDS.Music[musicKey]
	if not def then return end
	
	currentMusic = CreateSound(def, SoundService)
	currentMusic:Play()
end

function AudioController:StopMusic()
	if currentMusic then
		FadeVolume(currentMusic, 0, 2)
		task.delay(2, function()
			if currentMusic then
				currentMusic:Stop()
				currentMusic:Destroy()
				currentMusic = nil
			end
		end)
	end
end

-- ============================================================
-- Public Play API (for UIController to call)
-- ============================================================

function AudioController:PlaySFX(sfxKey)
	local def = SOUNDS.SFX[sfxKey]
	if def then
		PlayOneShot(def)
	end
end

function AudioController:PlayUIClick()
	PlayOneShot(SOUNDS.SFX.UIClick)
end

function AudioController:PlayUIPurchase()
	PlayOneShot(SOUNDS.SFX.UIPurchase)
end

-- ============================================================
-- Cleanup
-- ============================================================

function AudioController:KnitStop()
	-- Stop all sounds
	for key, sound in pairs(activeSounds) do
		sound:Stop()
		sound:Destroy()
	end
	activeSounds = {}
	
	if currentAmbient then
		currentAmbient:Stop()
		currentAmbient:Destroy()
		currentAmbient = nil
	end
	
	if currentMusic then
		currentMusic:Stop()
		currentMusic:Destroy()
		currentMusic = nil
	end
end

return AudioController