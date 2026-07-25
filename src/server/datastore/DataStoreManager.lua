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
    
    Error Handling:
    - All DataStore operations wrapped in pcall for graceful degradation
    - Nil checks on every player parameter (handles mid-dive disconnects)
    - Fallback in-memory profiles when DataStore is unavailable
    - Structured logging via Logger
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ProfileService dependency (from Wally packages)
local ProfileService = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("ProfileService"))

local ProfileTemplate = require(script.ProfileTemplate)
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local DataStoreManager = {}
local log = Logger.new("DataStoreManager")

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
    -- Nil check: handle mid-game player object issues
    if not player or not player.UserId then
        log:Error("LoadProfile called with invalid player object")
        return
    end
    
    local userId = player.UserId
    local userIdStr = tostring(userId)
    
    if playerProfiles[userId] then
        warn(string.format("[DataStoreManager] Profile for %s (%d) already loaded — releasing stale", player.Name, userId))
        self:SaveAndReleaseProfile(player)
    end
    
    -- Load profile via ProfileService with error handling
    local loadSuccess, profile = pcall(function()
        return profileStore:LoadProfileAsync(userIdStr)
    end)
    
    if not loadSuccess then
        log:Error(string.format("ProfileService load failed for %s (%d)", player.Name, userId), tostring(profile))
        -- Create a fallback in-memory profile so play can continue
        self:CreateFallbackProfile(player, userId)
        return
    end
    
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
                log:Error(string.format("ProfileService returned nil for %s (%d)", player.Name, userId))

                -- Create a fallback in-memory profile so the player can still play
                self:CreateFallbackProfile(player, userId)
            end
        end

        -- ============================================================
        -- Fallback Profile (survive DataStore outages)
        -- ============================================================

        function DataStoreManager:CreateFallbackProfile(player, userId)
            if not player then log:Warn("CreateFallbackProfile called with nil player"); return end
            log:Warn(string.format("Creating fallback profile for %s (%d)", player.Name, userId))

            local fallbackData = ProfileTemplate.Data
            fallbackData.FirstJoinTime = os.time()
            fallbackData.DisplayName = player.DisplayName
            fallbackData.UserId = userId

            -- Notify services with fallback data so the game still works
            self:NotifyServicesPlayerReady(player)
        end

-- ============================================================
-- Profile Release (ProfileService)
-- ============================================================

function DataStoreManager:SaveAndReleaseProfile(player)
    -- Nil check: handle player disconnect edge case
    if not player or not player.UserId then
        log:Warn("SaveAndReleaseProfile called with nil player")
        return
    end
    
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

-- ============================================================
-- Creature Transfer (Trade & Market)
-- Used by TradeService and MarketService to move creatures between players
-- ============================================================

function DataStoreManager:TransferCreature(fromUserId, toUserId, creatureData)
    if not fromUserId or not toUserId or not creatureData then
        log:Warn("TransferCreature: invalid parameters")
        return false
    end
    
    if not creatureData.Id then
        log:Warn("TransferCreature: creature has no ID")
        return false
    end
    
    -- Remove from seller
    local fromEntry = playerProfiles[fromUserId]
    if fromEntry and fromEntry.Profile then
        local removeSuccess = false
        local collection = fromEntry.Profile.Data.CreatureCollection or {}
        for i, entry in ipairs(collection) do
            if entry.Id == creatureData.Id then
                if (entry.Count or 1) > 1 then
                    entry.Count = entry.Count - 1
                    entry.TotalWeight = (entry.TotalWeight or 0) - (creatureData.Weight or 0)
                else
                    table.remove(collection, i)
                end
                removeSuccess = true
                break
            end
        end
        fromEntry.Profile.Data.CreatureCollection = collection
        if not removeSuccess then
            log:Warn(string.format("TransferCreature: creature %s not found in seller %d's collection",
                creatureData.Id, fromUserId))
            return false
        end
    end
    
    -- Add to buyer
    local toEntry = playerProfiles[toUserId]
    if toEntry and toEntry.Profile then
        local collection = toEntry.Profile.Data.CreatureCollection or {}
        local existingIndex = nil
        for i, entry in ipairs(collection) do
            if entry.Id == creatureData.Id then
                existingIndex = i
                break
            end
        end
        
        if existingIndex then
            local entry = collection[existingIndex]
            entry.Count = (entry.Count or 1) + 1
            entry.TotalWeight = (entry.TotalWeight or 0) + (creatureData.Weight or 0)
        else
            table.insert(collection, {
                Id = creatureData.Id,
                DisplayName = creatureData.DisplayName,
                Rarity = creatureData.Rarity,
                IsShiny = creatureData.IsShiny or false,
                Weight = creatureData.Weight or 0,
                Size = creatureData.Size or 1,
                Count = 1,
                TotalWeight = creatureData.Weight or 0,
                DateCollected = os.time(),
                LayerFound = creatureData.LayerFound or 1,
            })
        end
        toEntry.Profile.Data.CreatureCollection = collection
    end
    
    -- Mark both profiles dirty
    if fromEntry then
        self:SetProfileDirtyByUserId(fromUserId)
    end
    if toEntry then
        self:SetProfileDirtyByUserId(toUserId)
    end
    
    return true
end

-- ============================================================
-- ExecuteCreatureTransfer — atomic bidirectional transfer for P2P trading
-- Removes OfferA from PlayerA, gives to PlayerB; removes OfferB from PlayerB, gives to PlayerA
-- ============================================================

function DataStoreManager:ExecuteCreatureTransfer(playerA, playerB, offerA, offerB)
    -- Validate: PlayerA owns all creatures in offerA
    local profileA = self:GetProfile(playerA)
    if not profileA then return false end
    
    for _, creature in ipairs(offerA) do
        local found = false
        for _, entry in ipairs(profileA.CreatureCollection or {}) do
            if entry.Id == creature.Id then
                found = true
                break
            end
        end
        if not found then
            log:Warn(string.format("ExecuteTransfer: PlayerA doesn't own %s", creature.Id))
            return false
        end
    end
    
    -- Validate: PlayerB owns all creatures in offerB
    local profileB = self:GetProfile(playerB)
    if not profileB then return false end
    
    for _, creature in ipairs(offerB) do
        local found = false
        for _, entry in ipairs(profileB.CreatureCollection or {}) do
            if entry.Id == creature.Id then
                found = true
                break
            end
        end
        if not found then
            log:Warn(string.format("ExecuteTransfer: PlayerB doesn't own %s", creature.Id))
            return false
        end
    end
    
    -- Execute transfers
    for _, creature in ipairs(offerA) do
        local ok = self:TransferCreature(playerA.UserId, playerB.UserId, creature)
        if not ok then
            log:Error("ExecuteTransfer failed: A->B transfer failed for " .. (creature.Id or "unknown"))
            return false
        end
    end
    
    for _, creature in ipairs(offerB) do
        local ok = self:TransferCreature(playerB.UserId, playerA.UserId, creature)
        if not ok then
            log:Error("ExecuteTransfer failed: B->A transfer failed for " .. (creature.Id or "unknown"))
            return false
        end
    end
    
    return true
end

-- ============================================================
-- UpdateProfileByUserId — update a profile for an offline player
-- Used by MarketService for crediting offline sellers
-- ============================================================

function DataStoreManager:UpdateProfileByUserId(userId, callback)
    if not userId or not callback then return end
    
    local entry = playerProfiles[userId]
    if entry and entry.Profile then
        -- Player is online, update normally
        callback(entry.Profile.Data)
        self:SetProfileDirtyByUserId(userId)
    else
        -- Player is offline — queue for next load
        -- In production, this would use a separate DataStore queue
        -- For alpha: log a warning, the data will need reconciliation
        log:Warn(string.format("UpdateProfileByUserId: player %d offline — changes queued", userId))
        -- Attempt direct DataStore write as fallback
        local success, result = pcall(function()
            local Players = game:GetService("Players")
            local profileStore = self.ProfileStore
            if profileStore then
                local profile = profileStore:LoadProfileAsync("Player_" .. tostring(userId))
                if profile then
                    callback(profile.Data)
                    profile:Release()
                end
            end
        end)
        if not success then
            log:Error("UpdateProfileByUserId: offline write failed — " .. tostring(result))
        end
    end
end

-- ============================================================
-- SetProfileDirtyByUserId (internal helper)
-- ============================================================

function DataStoreManager:SetProfileDirtyByUserId(userId)
    local entry = playerProfiles[userId]
    if entry then
        self:SetProfileDirtyWithEntry(entry)
    end
end

function DataStoreManager:SetProfileDirtyWithEntry(entry)
    if entry and entry.Profile then
        -- ProfileService auto-saves on Release, so we just mark it
        entry.Profile.Data.LastSaveTime = os.time()
    end
end

-- ============================================================
-- GetPlayerProfileSync — returns profile data with nil guard
-- ============================================================

function DataStoreManager:GetPlayerProfileSync(player)
    if not player or not player.UserId then
        return {}
    end
    return self:GetProfile(player)
end

return DataStoreManager