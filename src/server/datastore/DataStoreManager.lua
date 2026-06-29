--[[
	DataStoreManager — Manages player data persistence using ProfileService pattern
	Handles save/load operations with automatic periodic saving and error recovery.
	Central hub that all services pull from for player profile data.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local DataStoreService2 = game:GetService("DataStoreService")

local DataStoreManager = {}

-- Constants
local DATASTORE_NAME = "AbyssPlayerData_v3"
local SAVE_INTERVAL = 120 -- Seconds between auto-saves
local VERSION = 3

-- State
local playerProfiles = {} -- { [UserId] = { profile = {}, dirty = bool, lastSave = number } }
local profileStore = nil

-- ============================================================
-- Default/New Player Profile
-- ============================================================

local function GetDefaultProfile()
	return {
		Version = VERSION,
		
		-- Progression
		Experience = 0,
		Level = 1,
		TotalDives = 0,
		
		-- Economy (dual currency)
		Credits = 50,
		ResearchPoints = 0,
		TotalCreditsEarned = 0,
		TotalResearchPointsEarned = 0,
		
		-- Equipment
		CurrentGearTier = 1,
		OwnedGearTiers = {1},
		MaxDepthReached = 0,
		
		-- Inventory (consumable items)
		Inventory = {},
		-- Example: { OxygenTank = 2, RareBait = 0, SpeedBoost = 1 }
		
		-- Active boosts
		ActiveBoosts = {},
		-- Example: { { effect = "XPBooster", expiresAt = 1234567890 } }
		
		-- Collection
		CreatureCollection = {},
		CollectionSlots = 50,
		DiscoveredZones = {}, -- Track which zone IDs player has entered
		DiscoveredCreatureIds = {}, -- Track which creature IDs have been discovered
		
		-- Base Building
		BaseModules = {},
		BaseLocation = { X = 0, Y = 0, Z = 0 },
		
		-- Stats
		TotalCreaturesCollected = 0,
		TotalCreaturesSold = 0,
		TotalOxygenUsed = 0,
		TotalDistanceTravelled = 0,
		TotalPlayTime = 0,
		
		-- Meta
		FirstJoinTime = os.time(),
		LastLoginTime = os.time(),
		TotalSessions = 0,
	}
end

-- ============================================================
-- Initialization
-- ============================================================

function DataStoreManager:Initialize()
	print("[DataStoreManager] Initializing...")
	
	local success, err = pcall(function()
		profileStore = DataStoreService2:GetDataStore(DATASTORE_NAME)
	end)
	
	if success then
		print("[DataStoreManager] DataStore connected")
	else
		warn("[DataStoreManager] Failed to connect DataStore: " .. tostring(err))
	end
	
	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		self:LoadProfile(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:SaveProfile(player, true)
		playerProfiles[player.UserId] = nil
	end)
	
	-- Auto-save loop
	self:StartAutoSave()
	
	print("[DataStoreManager] Initialization complete")
end

-- ============================================================
-- Profile Loading
-- ============================================================

function DataStoreManager:LoadProfile(player)
	local userId = player.UserId
	
	local success, data = pcall(function()
		return profileStore:GetAsync(tostring(userId))
	end)
	
	if success and data then
		if data.Version ~= VERSION then
			data = self:MigrateProfile(data)
		end
		
		playerProfiles[userId] = {
			profile = data,
			dirty = false,
			lastSave = os.time(),
		}
		
		print(string.format("[DataStoreManager] Loaded profile for %s (%d)", player.Name, userId))
	else
		-- New player
		local defaultProfile = GetDefaultProfile()
		defaultProfile.FirstJoinTime = os.time()
		
		playerProfiles[userId] = {
			profile = defaultProfile,
			dirty = true,
			lastSave = os.time(),
		}
		
		print(string.format("[DataStoreManager] Created new profile for %s (%d)", player.Name, userId))
	end
	
	-- After loading profile, hydrate connected services
	self:NotifyServicesPlayerReady(player)
end

function DataStoreManager:NotifyServicesPlayerReady(player)
	-- Tells economy service to reload from profile
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService and EconomyService.ReloadFromProfile then
		EconomyService:ReloadFromProfile(player)
	end
	
	-- Tells depth service to reload gear from profile
	local DepthService = Knit.GetService("DepthService")
	if DepthService and DepthService.ReloadFromProfile then
		DepthService:ReloadFromProfile(player)
	end
end

-- ============================================================
-- Profile Saving
-- ============================================================

function DataStoreManager:SaveProfile(player, isLeaving)
	local userId = player.UserId
	local entry = playerProfiles[userId]
	
	if not entry or not entry.dirty then
		return
	end
	
	if isLeaving then
		local profile = entry.profile
		if profile then
			profile.TotalPlayTime = profile.TotalPlayTime + (os.time() - entry.lastSave)
			profile.TotalSessions = profile.TotalSessions + 1
			profile.LastLoginTime = os.time()
			
			-- Sync economy data back to profile before saving
			self:SyncEconomyToProfile(player)
			self:SyncDepthToProfile(player)
		end
	end
	
	local success, err = pcall(function()
		profileStore:SetAsync(tostring(userId), entry.profile)
	end)
	
	if success then
		entry.dirty = false
		entry.lastSave = os.time()
		print(string.format("[DataStoreManager] Saved profile for %s (%d)", player.Name, userId))
	else
		warn(string.format("[DataStoreManager] Failed to save profile for %s: %s", player.Name, tostring(err)))
	end
end

-- ============================================================
-- Cross-service sync (pull live data into profile before save)
-- ============================================================

function DataStoreManager:SyncEconomyToProfile(player)
	local EconomyService = Knit.GetService("EconomyService")
	if not EconomyService then return end
	
	local data = EconomyService:GetPlayerData(player)
	if not data then return end
	
	local profile = self:GetProfile(player)
	if not profile then return end
	
	profile.Credits = data.Credits
	profile.ResearchPoints = data.ResearchPoints
	profile.Experience = data.XP
	profile.Level = data.Level
	profile.TotalCreaturesCollected = data.TotalCreaturesCollected
	profile.TotalCreaturesSold = data.TotalCreaturesSold
	profile.Inventory = data.Inventory
	profile.ActiveBoosts = data.ActiveBoosts
end

function DataStoreManager:SyncDepthToProfile(player)
	local DepthService = Knit.GetService("DepthService")
	if not DepthService then return end
	
	local data = DepthService:GetPlayerDepthData(player)
	if not data then return end
	
	local profile = self:GetProfile(player)
	if not profile then return end
	
	profile.CurrentGearTier = data.gearTier
	profile.MaxDepthReached = math.max(profile.MaxDepthReached, data.maxDepthReached or 0)
end

-- ============================================================
-- Auto-save loop
-- ============================================================

function DataStoreManager:StartAutoSave()
	while task.wait(SAVE_INTERVAL) do
		for _, player in ipairs(Players:GetPlayers()) do
			self:SaveProfile(player, false)
		end
	end
end

-- ============================================================
-- Profile Migration
-- ============================================================

function DataStoreManager:MigrateProfile(oldData)
	print("[DataStoreManager] Migrating profile from version " .. tostring(oldData.Version) .. " to v" .. tostring(VERSION))
	
	local newData = GetDefaultProfile()
	
	-- Copy over compatible fields
	for k, v in pairs(oldData) do
		if newData[k] ~= nil then
			newData[k] = v
		end
	end
	
	-- Handle v1 -> v2: Add ResearchPoints if missing
	if newData.ResearchPoints == nil then
		newData.ResearchPoints = 0
	end
	
	-- Handle v2 -> v3: Map old Currency -> Credits, add new fields
	if oldData.Currency and newData.Credits == 50 then
		-- If old Currency was set differently, carry it over
		newData.Credits = oldData.Currency
	end
	
	newData.Version = VERSION
	return newData
end

-- ============================================================
-- Public API
-- ============================================================

function DataStoreManager:GetProfile(player)
	local entry = playerProfiles[player.UserId]
	return entry and entry.profile or GetDefaultProfile()
end

function DataStoreManager:SetProfileDirty(player)
	local entry = playerProfiles[player.UserId]
	if entry then
		entry.dirty = true
	end
end

function DataStoreManager:UpdateProfile(player, updateFn)
	local entry = playerProfiles[player.UserId]
	if not entry then return end
	
	updateFn(entry.profile)
	entry.dirty = true
end

function DataStoreManager:GetPlayerProfileSync(player)
	-- For services that need profile data directly (read-heavy operations)
	local profile = self:GetProfile(player)
	return {
		Credits = profile.Credits,
		ResearchPoints = profile.ResearchPoints,
		Level = profile.Level,
		Experience = profile.Experience,
		CurrentGearTier = profile.CurrentGearTier,
		OwnedGearTiers = profile.OwnedGearTiers,
		MaxDepthReached = profile.MaxDepthReached,
		CollectionSlots = profile.CollectionSlots,
		Inventory = profile.Inventory,
		ActiveBoosts = profile.ActiveBoosts,
		DiscoveredZones = profile.DiscoveredZones,
		DiscoveredCreatureIds = profile.DiscoveredCreatureIds,
	}
end

function DataStoreManager:HasDiscoveredZone(player, zoneIndex)
	local profile = self:GetProfile(player)
	if not profile.DiscoveredZones then return false end
	return table.find(profile.DiscoveredZones, zoneIndex) ~= nil
end

function DataStoreManager:MarkZoneDiscovered(player, zoneIndex)
	self:UpdateProfile(player, function(profile)
		if not profile.DiscoveredZones then
			profile.DiscoveredZones = {}
		end
		if not table.find(profile.DiscoveredZones, zoneIndex) then
			table.insert(profile.DiscoveredZones, zoneIndex)
		end
	end)
end

function DataStoreManager:HasDiscoveredCreature(player, creatureId)
	local profile = self:GetProfile(player)
	if not profile.DiscoveredCreatureIds then return false end
	return table.find(profile.DiscoveredCreatureIds, creatureId) ~= nil
end

function DataStoreManager:MarkCreatureDiscovered(player, creatureId)
	self:UpdateProfile(player, function(profile)
		if not profile.DiscoveredCreatureIds then
			profile.DiscoveredCreatureIds = {}
		end
		if not table.find(profile.DiscoveredCreatureIds, creatureId) then
			table.insert(profile.DiscoveredCreatureIds, creatureId)
		end
	end)
end

return DataStoreManager