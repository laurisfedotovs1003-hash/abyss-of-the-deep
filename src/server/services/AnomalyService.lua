--[[
	AnomalyService — Manages Echo Events / World Anomalies
	Triggers random environmental events that modify lighting, creature rarity, and rewards.
	Broadcasts state changes to clients (CameraController, UIController) and provides
	query methods for CreatureService to apply anomaly modifiers.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local AnomalyService = Knit.CreateService {
	Name = "AnomalyService",
	Client = {
		-- Fired when an anomaly starts (includes Lightning + modifiers data)
		AnomalyStarted = Knit.CreateSignal(),
		-- Fired when the anomaly ends / expires
		AnomalyEnded = Knit.CreateSignal(),
		-- Warning ~10 seconds before anomaly starts
		AnomalyWarning = Knit.CreateSignal(),
	}
}

-- ============================================================
-- Internal State
-- ============================================================

local state = {
	activeAnomaly = nil,		-- { key: string, config: table, startedAt: number, duration: number }
	lastTriggerTime = 0,		-- Global cooldown tracker (os.time)
	lastAnomalyByType = {},		-- { [anomalyKey] = lastTriggerTime }
	globalCooldown = 0,			-- Seconds since last anomaly ended
}

local ANOMALY_CHECK_INTERVAL = 30	-- Check for new anomaly every 30s
local MIN_PLAYERS_FOR_ANOMALY = 1	-- Need at least 1 diving player
local GLOBAL_COOLDOWN = 120			-- 2 min minimum between anomalies
local WARNING_LEAD_TIME = 10		-- Warning fires 10s before start

-- ============================================================
-- Initialize
-- ============================================================

function AnomalyService:KnitStart()
	print("[AnomalyService] Initialized — Echo Events system ready")

	-- Master loop: check for trigger, manage active anomaly lifecycle
	self:RunAnomalyLoop()
end

function AnomalyService:RunAnomalyLoop()
	while task.wait(ANOMALY_CHECK_INTERVAL) do
		-- If an anomaly is active, check if it expired
		if state.activeAnomaly then
			local elapsed = os.time() - state.activeAnomaly.startedAt
			if elapsed >= state.activeAnomaly.duration then
				self:EndActiveAnomaly()
			end
			continue
		end

		-- Check global cooldown
		if os.time() - state.lastTriggerTime < GLOBAL_COOLDOWN then
			continue
		end

		-- Only trigger if players are diving
		if not self:HasDivingPlayers() then
			continue
		end

		-- Roll for anomaly trigger (~15% chance per check, every 30s)
		if math.random() <= 0.15 then
			self:TryTriggerAnomaly()
		end
	end
end

-- ============================================================
-- Trigger Logic
-- ============================================================

function AnomalyService:HasDivingPlayers()
	local OxygenService = Knit.GetService("OxygenService")
	if not OxygenService then return false end

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local oxyData = OxygenService:GetPlayerOxygenState(player)
		if oxyData and oxyData.isDiving then
			return true
		end
	end
	return false
end

function AnomalyService:TryTriggerAnomaly()
	-- Build weighted table from anomaly definitions
	local weightedTable = {}
	for key, anomaly in pairs(Config.AnomalyEvents) do
		-- Check per-type cooldown
		local lastTime = state.lastAnomalyByType[key] or 0
		if os.time() - lastTime >= anomaly.CooldownAfter then
			table.insert(weightedTable, {
				value = key,
				weight = anomaly.Weight,
			})
		end
	end

	if #weightedTable == 0 then return end

	-- Pick anomaly using weighted random
	local chosenKey = Util.WeightedRandom(weightedTable)
	if not chosenKey then return end

	local anomalyConfig = Config.AnomalyEvents[chosenKey]
	local duration = math.random(anomalyConfig.DurationMin, anomalyConfig.DurationMax)

	state.lastTriggerTime = os.time()
	state.lastAnomalyByType[chosenKey] = os.time()

	-- Send warning to all players
	self:SendAnomalyWarning(chosenKey, anomalyConfig)

	-- Wait warning lead time, then start
	task.wait(WARNING_LEAD_TIME)

	self:StartAnomaly(chosenKey, anomalyConfig, duration)
end

-- ============================================================
-- Anomaly Lifecycle
-- ============================================================

function AnomalyService:SendAnomalyWarning(key, config)
	local warningData = {
		key = key,
		displayName = config.DisplayName,
		description = config.Description,
		priority = config.Priority,
		startsIn = WARNING_LEAD_TIME,
	}

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		self.Client:Get("AnomalyWarning"):Fire(player, warningData)
	end

	print(string.format("[AnomalyService] WARNING: %s incoming in %ds!", config.DisplayName, WARNING_LEAD_TIME))
end

function AnomalyService:StartAnomaly(key, config, duration)
	state.activeAnomaly = {
		key = key,
		config = config,
		startedAt = os.time(),
		duration = duration,
	}

	local startData = {
		key = key,
		displayName = config.DisplayName,
		description = config.Description,
		priority = config.Priority,
		duration = duration,
		startedAt = os.time(),
		endsAt = os.time() + duration,
		lighting = config.Lighting,
		modifiers = config.Modifiers,
	}

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		self.Client:Get("AnomalyStarted"):Fire(player, startData)
	end

	print(string.format("[AnomalyService] ANOMALY ACTIVE: %s (%d seconds)", config.DisplayName, duration))
end

function AnomalyService:EndActiveAnomaly()
	if not state.activeAnomaly then return end

	local endedKey = state.activeAnomaly.key
	local endedName = state.activeAnomaly.config.DisplayName

	local endData = {
		key = endedKey,
		displayName = endedName,
		reason = "expired",
	}

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		self.Client:Get("AnomalyEnded"):Fire(player, endData)
	end

	state.activeAnomaly = nil

	print(string.format("[AnomalyService] Anomaly ended: %s", endedName))
end

-- ============================================================
-- Public Query API (for CreatureService, OxygenService, etc.)
-- ============================================================

function AnomalyService:GetActiveAnomaly()
	return state.activeAnomaly
end

function AnomalyService:GetAnomalyModifiers()
	if not state.activeAnomaly then
		return nil
	end
	return state.activeAnomaly.config.Modifiers
end

function AnomalyService:IsAnomalyActive()
	return state.activeAnomaly ~= nil
end

function AnomalyService:GetRarityWeightMultiplier(rarityName)
	if not state.activeAnomaly then
		return 1.0
	end
	local mods = state.activeAnomaly.config.Modifiers
	if mods and mods.CreatureRarityWeightMultiplier then
		return mods.CreatureRarityWeightMultiplier[rarityName] or 1.0
	end
	return 1.0
end

function AnomalyService:GetCatchChanceMultiplier()
	if not state.activeAnomaly then
		return 1.0
	end
	return state.activeAnomaly.config.Modifiers.CatchChanceMultiplier or 1.0
end

function AnomalyService:GetXPMultiplier()
	if not state.activeAnomaly then
		return 1.0
	end
	return state.activeAnomaly.config.Modifiers.XPMultiplier or 1.0
end

function AnomalyService:GetCreditMultiplier()
	if not state.activeAnomaly then
		return 1.0
	end
	return state.activeAnomaly.config.Modifiers.CreditMultiplier or 1.0
end

function AnomalyService:GetSpawnRateMultiplier()
	if not state.activeAnomaly then
		return 1.0
	end
	return state.activeAnomaly.config.Modifiers.SpawnRateMultiplier or 1.0
end

-- ============================================================
-- Client Methods
-- ============================================================

function AnomalyService.Client:GetActiveAnomaly(player)
	local self = AnomalyService
	return self:GetActiveAnomaly()
end

return AnomalyService