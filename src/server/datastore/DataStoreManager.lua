--[[
	DataStoreManager — Manages player data persistence via ProfileService
	ProfileService handles: auto-saving, profile locking, global updates,
	retry-on-failure, and release management.
	
	Dependencies: ProfileService 2.0.0 (madstudios/profile-service)
	Schema: Defined in ProfileTemplate.lua, aligned with Types.lua
	
	Architecture:
	- On PlayerAdded: LoadProfileAsync() → hydrate services via ReloadFromProfile()
	- ProfileService auto-saves on ListenToRelease() callback
	- Services call MarkDirty() to trigger saves on next release/cycle
	- On PlayerRemoving: Sync service data → profile:Release()
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ProfileService dependency (from Wally packages)
local ProfileService = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("ProfileService"))

local ProfileTemplate = require(script.ProfileTemplate)
local DataStoreManager = {}

-- Constants
local DATASTORE_NAME = "AbyssPlayerData_v4"
local SAVE_INTERVAL = 120 -- Seconds between forced syncs (ProfileService handles auto-save, this is belt-and-suspenders)

-- State
local playerProfiles = {} -- { [UserId] = { Profile: ProfileService profile, dirty: bool } }
local profileStore = nil

-- ============================================================
-- Initialization
-- ============================================================

function DataStoreManager:Initialize()
	print("[DataStoreManager] Initializing with ProfileService...")
	
	-- Create the ProfileStore using the template
	local success, err = pcall(function()
		profileStore = ProfileService.GetProfileStore(DATASTORE_NAME, ProfileTemplate.Data)
	end)
	
	if success and profileStore then
		print("[DataStoreManager] ProfileStore created successfully")
	else
		warn("[DataStoreManager] Failed to create ProfileStore: " .. tostring(err))
		-- ProfileService handles retries internally, but we warn
	end
	
	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		self:LoadProfile(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:SaveAndReleaseProfile(player)
	end)
	
	-- Periodic integrity check (not saves — ProfileService handles those)
	self:StartIntegrityCheck()
	
	print("[DataStoreManager] Initialization complete")
end

-- ============================================================
-- Profile Loading (ProfileService)
-- ============================================================

function DataStoreManager:LoadProfile(player)
	local userId = player.UserId
	local userIdStr = tostring(userId)
	
	if playerProfiles[userId] then
		warn(string.format("[DataStoreManager] Profile for %s (%d) already loaded — releasing stale", player.Name, userId))
		self:SaveAndReleaseProfile(player)
	end
	
	-- Load profile via ProfileService
	local profile = profileStore:LoadProfileAsync(userIdStr)
	
	if profile then
		-- Profile loaded successfully (new or existing player)
		playerProfiles[userId] = {
			Profile = profile,
			dirty = true, -- ProfileService handles this, but we track it too
		}
		
		-- Check for first join (ProfileService sets .Data to template if new)
		local isNewPlayer = (profile.Data.FirstJoinTime == 0)
		if isNewPlayer then
			profile.Data.FirstJoinTime = os.time()
			profile.Data.DisplayName = player.DisplayName
			profile.Data.UserId = userId
		end
		
		-- Listen for ProfileService release (auto-save trigger)
		profile:ListenToRelease(function()
			print(string.format("[DataStoreManager] Profile released for %s (%d)", player.Name, userId))
			playerProfiles[userId] = nil
		end)
		
		print(string.format("[DataStoreManager] Profile loaded for %s (%d) [%s]",
			player.Name, userId, isNewPlayer and "NEW" or "EXISTING"))
		
		-- Hydrate all services with profile data
		self:NotifyServicesPlayerReady(player)
	else
		-- Profile load failed (ProfileService couldn't connect to DataStore)
		warn(string.format("[DataStoreManager] CRITICAL: Failed to load profile for %s (%d) — ProfileService returned nil",
			player.Name, userId))
		
		-- Create a fallback in-memory profile so the player can still play
		-- (data won't persist but game won't crash)
		local fallbackData = ProfileTemplate.Data
		fallbackData.FirstJoinTime = os.time()
		fallbackData.DisplayName = player.DisplayName
		fallbackData.UserId = userId
		
		-- Notify services with fallback data
		self:NotifyServicesPlayerReady(player)
	end
end

-- ============================================================
-- Profile Release (ProfileService)
-- ============================================================

function DataStoreManager:SaveAndReleaseProfile(player)
	local userId = player.UserId
	local entry = playerProfiles[userId]
	
	if not entry then
		return
	end
	
	local profile = entry.Profile
	if not profile then
		playerProfiles[userId] = nil
		return
	end
	
	-- Sync service data back into profile before release
	self:SyncAllServicesToProfile(player)
	
	-- Update session metadata
	profile.Data.LastSaveTime = os.time()
	
	-- ProfileService:Release() auto-saves to DataStore
	profile:Release()
	
	playerProfiles[userId] = nil
	
	print(string.format("[DataStoreManager] Profile released for %s (%d)", player.Name, userId))
end

-- ============================================================
-- Service Hydration
-- ============================================================

function DataStoreManager:NotifyServicesPlayerReady(player)
	-- EconomyService: Reload from profile
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService and EconomyService.ReloadFromProfile then
		EconomyService:ReloadFromProfile(player)
	end
	
	-- DepthService: Reload gear from profile
	local DepthService = Knit.GetService("DepthService")
	if DepthService and DepthService.ReloadFromProfile then
		DepthService:ReloadFromProfile(player)
	end
	
	-- BaseBuildingService: Reload base from profile
	local BaseBuildingService = Knit.GetService("BaseBuildingService")
	if BaseBuildingService and BaseBuildingService.ReloadFromProfile then
		BaseBuildingService:ReloadFromProfile(player)
	end
end

-- ============================================================
-- Cross-service sync (pull live data into profile before save)
-- ============================================================

function DataStoreManager:SyncAllServicesToProfile(player)
	local entry = playerProfiles[player.UserId]
	if not entry or not entry.Profile then return end
	
	local profile = entry.Profile
	local data = profile.Data
	
	-- Sync from EconomyService
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService then
		local ecoData = EconomyService:GetPlayerData(player)
		if ecoData then
			data.Currency = ecoData.Credits or data.Currency
			data.ResearchPoints = ecoData.ResearchPoints or data.ResearchPoints
			data.Experience = ecoData.XP or data.Experience
			data.Level = ecoData.Level or data.Level
			data.Inventory = ecoData.Inventory or data.Inventory
			data.ActiveBoosts = ecoData.ActiveBoosts or data.ActiveBoosts
			data.TotalCreaturesCollected = ecoData.TotalCreaturesCollected or data.TotalCreaturesCollected
			data.TotalCreaturesSold = ecoData.TotalCreaturesSold or data.TotalCreaturesSold
			data.TotalCreditsEarned = ecoData.TotalCreditsEarned or data.TotalCreditsEarned
		end
	end
	
	-- Sync from DepthService
	local DepthService = Knit.GetService("DepthService")
	if DepthService then
		local depthData = DepthService:GetPlayerDepthData(player)
		if depthData then
			data.CurrentGearTier = depthData.gearTier or data.CurrentGearTier
			data.MaxDepthReached = math.max(depthData.maxDepthReached or 0, data.MaxDepthReached)
			data.OwnedGearTiers = depthData.ownedGearTiers or data.OwnedGearTiers
		end
	end
	
	-- Sync TotalDives and PlayTime
	data.TotalDives = (data.TotalDives or 0)
	data.TotalPlayTime = (data.TotalPlayTime or 0) + SAVE_INTERVAL
	data.TotalSessions = (data.TotalSessions or 0) + 1
	
	-- Sync play time if we have last save
	local lastSave = data.LastSaveTime or os.time()
	data.TotalPlayTime = data.TotalPlayTime + (os.time() - lastSave)
end

-- ============================================================
-- Integrity Check (periodic sync, not saves)
-- ============================================================

function DataStoreManager:StartIntegrityCheck()
	-- ProfileService handles auto-save internally on release.
	-- This loop exists to periodically sync live service data back
	-- into the profile data so it's ready for a clean release.
	while task.wait(SAVE_INTERVAL) do
		for _, player in ipairs(Players:GetPlayers()) do
			local entry = playerProfiles[player.UserId]
			if entry and entry.Profile then
				-- Sync data but don't force a save — ProfileService
				-- will save whenever the profile is released or globally updated
				self:SyncAllServicesToProfile(player)
			end
		end
	end
end

-- ============================================================
-- Public API
-- ============================================================

function DataStoreManager:GetProfile(player)
	local entry = playerProfiles[player.UserId]
	if entry and entry.Profile then
		return entry.Profile.Data
	end
	-- Return a copy of the template as fallback
	local fallback = {}
	for k, v in pairs(ProfileTemplate.Data) do
		fallback[k] = v
	end
	return fallback
end

function DataStoreManager:SetProfileDirty(player)
	local entry = playerProfiles[player.UserId]
	if entry then
		entry.dirty = true
	end
end

function DataStoreManager:UpdateProfile(player, updateFn)
	local entry = playerProfiles[player.UserId]
	if not entry or not entry.Profile then return end
	
	updateFn(entry.Profile.Data)
	entry.dirty = true
end

function DataStoreManager:GetPlayerProfileSync(player)
	-- For services that need profile data directly (read-heavy operations)
	local profile = self:GetProfile(player)
	return {
		-- Identification
		UserId = profile.UserId,
		DisplayName = profile.DisplayName,
		
		-- Progression
		Experience = profile.Experience,
		Level = profile.Level,
		
		-- Economy (Types.lua uses Currency, we keep it as Credits)
		Credits = profile.Currency or 0,
		ResearchPoints = profile.ResearchPoints or 0,
		TotalCreditsEarned = profile.TotalCreditsEarned or 0,
		TotalResearchPointsEarned = profile.TotalResearchPointsEarned or 0,
		TotalDives = profile.TotalDives or 0,
		
		-- Equipment
		CurrentGearTier = profile.CurrentGearTier or 1,
		OwnedGearTiers = profile.OwnedGearTiers or {1},
		MaxDepthReached = profile.MaxDepthReached or 0,
		
		-- Inventory
		Inventory = profile.Inventory or {},
		ActiveBoosts = profile.ActiveBoosts or {},
		
		-- Collection
		CreatureCollection = profile.CreatureCollection or {},
		CollectionSlots = profile.CollectionSlots or 50,
		DiscoveredZones = profile.DiscoveredZones or {},
		DiscoveredCreatureIds = profile.DiscoveredCreatureIds or {},
		
		-- Base
		BaseModules = profile.BaseModules or {},
		BaseLocation = profile.BaseLocation or Vector3.new(0, 0, 0),
		
		-- Stats
		TotalCreaturesCollected = profile.TotalCreaturesCollected or 0,
		TotalCreaturesSold = profile.TotalCreaturesSold or 0,
		TotalPlayTime = profile.TotalPlayTime or 0,
		
		-- Meta
		PremiumBenefits = profile.PremiumBenefits or false,
	}
end

-- ============================================================
-- Discovery Tracking (used by DepthService & CollectionService)
-- ============================================================

function DataStoreManager:HasDiscoveredZone(player, zoneIndex)
	local profile = self:GetProfile(player)
	if not profile.DiscoveredZones then return false end
	return table.find(profile.DiscoveredZones, zoneIndex) ~= nil
end

function DataStoreManager:MarkZoneDiscovered(player, zoneIndex)
	self:UpdateProfile(player, function(data)
		if not data.DiscoveredZones then
			data.DiscoveredZones = {}
		end
		if not table.find(data.DiscoveredZones, zoneIndex) then
			table.insert(data.DiscoveredZones, zoneIndex)
		end
	end)
end

function DataStoreManager:HasDiscoveredCreature(player, creatureId)
	local profile = self:GetProfile(player)
	if not profile.DiscoveredCreatureIds then return false end
	return table.find(profile.DiscoveredCreatureIds, creatureId) ~= nil
end

function DataStoreManager:MarkCreatureDiscovered(player, creatureId)
	self:UpdateProfile(player, function(data)
		if not data.DiscoveredCreatureIds then
			data.DiscoveredCreatureIds = {}
		end
		if not table.find(data.DiscoveredCreatureIds, creatureId) then
			table.insert(data.DiscoveredCreatureIds, creatureId)
		end
	end)
end

return DataStoreManager