--[[
	DataStoreManager — Manages player data persistence using ProfileService pattern
	Handles save/load operations with automatic periodic saving and error recovery.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local DataStoreService2 = game:GetService("DataStoreService")

local DataStoreManager = {}

-- Constants
local DATASTORE_NAME = "AbyssPlayerData_v2"
local SAVE_INTERVAL = 120 -- Seconds between auto-saves
local VERSION = 2

-- State
local playerProfiles = {} -- { [UserId] = { profile data, dirty = bool, lastSave = time } }
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
		Currency = 50,
		TotalDives = 0,
		
		-- Equipment
		CurrentGearTier = 1,
		OwnedGearTiers = {1},
		MaxDepthReached = 0,
		
		-- Collection
		CreatureCollection = {},
		CollectionSlots = 50,
		
		-- Base Building
		BaseModules = {},
		BaseLocation = { X = 0, Y = 0, Z = 0 },
		
		-- Stats
		TotalCreaturesCollected = 0,
		TotalOxygenUsed = 0,
		TotalDistanceTravelled = 0,
		TotalPlayTime = 0,
		
		-- Meta
		FirstJoinTime = os.time(),
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
		-- Continue without persistence
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
	
	-- Attempt to load from DataStore
	local success, data = pcall(function()
		return profileStore:GetAsync(tostring(userId))
	end)
	
	if success and data then
		-- Validate version
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
		playerProfiles[userId] = {
			profile = GetDefaultProfile(),
			dirty = true,
			lastSave = os.time(),
		}
		
		print(string.format("[DataStoreManager] Created new profile for %s (%d)", player.Name, userId))
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
	
	-- Update session data
	if isLeaving then
		local profile = entry.profile
		if profile then
			profile.TotalPlayTime = profile.TotalPlayTime + (os.time() - entry.lastSave)
			profile.TotalSessions = profile.TotalSessions + 1
		end
	end
	
	-- Save to DataStore
	local success, err = pcall(function()
		profileStore:SetAsync(tostring(userId), entry.profile)
	end)
	
	if success then
		entry.dirty = false
		entry.lastSave = os.time()
	else
		warn(string.format("[DataStoreManager] Failed to save profile for %s: %s", player.Name, tostring(err)))
	end
end

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

return DataStoreManager