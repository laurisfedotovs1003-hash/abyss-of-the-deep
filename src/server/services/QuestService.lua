--[[
    QuestService — Knit service for quest lifecycle management.
    Handles daily quests, milestone quests, event quests, and achievements.
    Integrates with CreatureService, DepthService, EconomyService, AnomalyService.
    Extends ProfileTemplate with quest tracking fields.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))
local Players = game:GetService("Players")

local QuestService = Knit.CreateService {
    Name = "QuestService",
    Client = {
        -- ============================================================
        -- Signals
        -- ============================================================
        
        -- Fired when any quest's progress changes (for UI updates)
        QuestProgressUpdated = Knit.CreateSignal(),
        -- Fired when a quest becomes completable (all conditions met)
        QuestCompleted = Knit.CreateSignal(),
        -- Fired when a player claims their quest reward
        QuestClaimed = Knit.CreateSignal(),
        -- Fired when daily quests refresh (new day / new pool)
        DailyQuestRefresh = Knit.CreateSignal(),
        -- Fired when an anomaly-based event quest is auto-accepted
        EventQuestStarted = Knit.CreateSignal(),
        
        -- ============================================================
        -- Queries
        -- ============================================================
        
        GetActiveQuests = Knit.CreateSignal(),
        GetCompletedQuests = Knit.CreateSignal(),
        GetAvailableQuests = Knit.CreateSignal(),
        GetQuestCatalog = Knit.CreateSignal(),
        
        -- ============================================================
        -- Actions
        -- ============================================================
        
        AcceptDailyQuest = Knit.CreateSignal(),
        ClaimQuestReward = Knit.CreateSignal(),
        ReRollDailyQuest = Knit.CreateSignal(),
    }
}

-- ============================================================
-- Internal State
-- ============================================================

-- Per-player quest state (mirrors profile data, cached in memory)
-- { [UserId] = { activeQuests: {}, completedQuests: {}, dailyState: {}, sessionProgress: {} } }
local playerQuestState = {}

-- Event hook references (for cleanup on player remove)
local eventConnections = {}

-- ============================================================
-- Initialization
-- ============================================================

function QuestService:KnitStart()
    print("[QuestService] Initialized — Quest/Mission system ready")
    
    -- Register hooks into other services
    self:RegisterEventHooks()
    
    -- Start daily refresh checker (checks every 5 minutes)
    self:StartDailyRefreshLoop()
end

-- ============================================================
-- Profile Integration (called by DataStoreManager)
-- ============================================================

function QuestService:ReloadFromProfile(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profileSync = DataStoreManager:GetPlayerProfileSync(player)
    if not profileSync then return end
    
    -- Initialize quest state from profile
    playerQuestState[player.UserId] = {
        activeQuests = profileSync.ActiveQuests or {},
        completedQuests = profileSync.CompletedQuests or {},
        claimedQuests = profileSync.ClaimedQuests or {},
        dailyState = profileSync.DailyQuestState or {
            RefreshDay = 0,
            AcceptedDailyKeys = {},
            ReRollsUsed = 0,
            LastReRollTime = 0,
            CompletedToday = {},
        },
        sessionProgress = {},  -- Resets each session (not persisted)
    }
    
    -- Refresh daily quests if it's a new day
    self:CheckAndRefreshDailyQuests(player)
    
    print(string.format("[QuestService] Loaded quest data for %s (%d): %d active quests",
        player.Name, player.UserId, #playerQuestState[player.UserId].activeQuests))
end

function QuestService:PlayerRemoving(player)
    -- Save current quest state to profile
    self:SaveQuestState(player)
    playerQuestState[player.UserId] = nil
    eventConnections[player.UserId] = nil
end

-- ============================================================
-- Event Hooks Registration
-- ============================================================

function QuestService:RegisterEventHooks()
    -- Hook: creature caught → update catch-based quests
    local CreatureService = Knit.GetService("CreatureService")
    if CreatureService and CreatureService.OnCreatureCaught then
        CreatureService.OnCreatureCaught:Connect(function(player, creatureData)
            self:OnCreatureCaught(player, creatureData)
        end)
    end
    
    -- Hook: depth update → update depth-based quests
    local DepthService = Knit.GetService("DepthService")
    if DepthService then
        -- Using the signal from DepthService if available
        -- Fallback: connect to depth update remote
        if DepthService.OnDepthUpdate then
            DepthService.OnDepthUpdate:Connect(function(player, depthData)
                self:OnDepthUpdate(player, depthData)
            end)
        end
    end
    
    -- Hook: dive surface → check dive completion quests
    if DepthService and DepthService.OnSurface then
        DepthService.OnSurface:Connect(function(player, diveStats)
            self:OnDiveComplete(player, diveStats)
        end)
    end
    
    -- Hook: creature sold
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService and EconomyService.OnCreatureSold then
        EconomyService.OnCreatureSold:Connect(function(player, creatureData)
            self:OnCreatureSold(player, creatureData)
        end)
    end
    
    -- Hook: gear purchased
    if EconomyService and EconomyService.OnGearPurchased then
        EconomyService.OnGearPurchased:Connect(function(player, gearTier)
            self:OnGearPurchased(player, gearTier)
        end)
    end
    
    -- Hook: anomaly events
    local AnomalyService = Knit.GetService("AnomalyService")
    if AnomalyService then
        if AnomalyService.OnAnomalyStarted then
            AnomalyService.OnAnomalyStarted:Connect(function(anomalyKey)
                self:OnAnomalyStarted(anomalyKey)
            end)
        end
        if AnomalyService.OnAnomalyEnded then
            AnomalyService.OnAnomalyEnded:Connect(function(anomalyKey)
                self:OnAnomalyEnded(anomalyKey)
            end)
        end
    end
    
    -- Hook: base building
    local BaseBuildingService = Knit.GetService("BaseBuildingService")
    if BaseBuildingService and BaseBuildingService.OnModulePlaced then
        BaseBuildingService.OnModulePlaced:Connect(function(player, moduleData)
            self:OnModulePlaced(player, moduleData)
        end)
    end
end

-- ============================================================
-- Event Handlers
-- ============================================================

function QuestService:OnCreatureCaught(player, creatureData)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    -- Update session progress
    local session = state.sessionProgress
    if not session.CreaturesCaught then session.CreaturesCaught = {} end
    if not session.RarityCounts then session.RarityCounts = {} end
    
    local creatureId = creatureData.id or creatureData.DisplayName
    local rarity = creatureData.Rarity or "Common"
    
    session.CreaturesCaught[creatureId] = (session.CreaturesCaught[creatureId] or 0) + 1
    session.RarityCounts[rarity] = (session.RarityCounts[rarity] or 0) + 1
    
    -- Update all active quests
    self:UpdateAllQuestProgress(player, "CreatureCaught", creatureData)
end

function QuestService:OnDepthUpdate(player, depthData)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    -- Track max depth this session
    local session = state.sessionProgress
    local newDepth = depthData.newDepth or depthData.depth or 0
    local maxDepth = depthData.maxDepth or depthData.maxDepthReached or 0
    session.MaxDepth = math.max(session.MaxDepth or 0, newDepth)
    
    -- Track depth gain during anomaly
    local AnomalyService = Knit.GetService("AnomalyService")
    if AnomalyService and AnomalyService.IsAnomalyActive then
        local activeAnomaly = AnomalyService:GetActiveAnomaly()
        if activeAnomaly then
            if not session.AnomalyStartDepth then
                session.AnomalyStartDepth = newDepth
            end
            session.AnomalyDepthGain = newDepth - session.AnomalyStartDepth
        else
            -- Reset anomaly tracking when no anomaly
            session.AnomalyStartDepth = nil
            session.AnomalyDepthGain = 0
        end
    end
    
    -- Get lifetime max for milestone evaluation
    local profile = self:GetProfile(player)
    local lifetimeMax = math.max(maxDepth, profile and profile.MaxDepthReached or 0)
    
    self:UpdateAllQuestProgress(player, "DepthUpdate", {
        newDepth = newDepth,
        maxDepth = lifetimeMax,
        sessionMaxDepth = session.MaxDepth,
    })
end

function QuestService:OnDiveComplete(player, diveStats)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    -- Track oxygen usage
    local session = state.sessionProgress
    session.OxygenUsed = (session.OxygenUsed or 0) + (diveStats.oxygenUsed or 0)
    
    -- Track scrap/crystal collected
    session.ScrapCollected = (session.ScrapCollected or 0) + (diveStats.scrapCollected or 0)
    session.CrystalCollected = (session.CrystalCollected or 0) + (diveStats.crystalCollected or 0)
    
    self:UpdateAllQuestProgress(player, "DiveComplete", diveStats)
    
    -- Reset session-scoped progress if needed (but keep session-long counters)
    -- Session-scoped progress resets here for "single_dive" conditions
    -- The session counters persist, but individual dive counters are evaluated and can be reset
end

function QuestService:OnCreatureSold(player, creatureData)
    self:UpdateAllQuestProgress(player, "CreatureSold", creatureData)
end

function QuestService:OnGearPurchased(player, gearTier)
    self:UpdateAllQuestProgress(player, "GearPurchased", { tier = gearTier })
end

function QuestService:OnAnomalyStarted(anomalyKey)
    -- Auto-accept event quests for all active players
    for _, player in ipairs(Players:GetPlayers()) do
        local state = playerQuestState[player.UserId]
        if state then
            self:AutoAcceptEventQuest(player, anomalyKey)
        end
    end
end

function QuestService:OnAnomalyEnded(anomalyKey)
    -- Remove expired event quests for all players
    for _, player in ipairs(Players:GetPlayers()) do
        local state = playerQuestState[player.UserId]
        if state then
            self:RemoveExpiredEventQuests(player, anomalyKey)
        end
    end
end

function QuestService:OnModulePlaced(player, moduleData)
    self:UpdateAllQuestProgress(player, "ModulePlaced", moduleData)
end

-- ============================================================
-- Core Quest Progress Update
-- ============================================================

function QuestService:UpdateAllQuestProgress(player, eventType, eventData)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    local anyProgressChanged = false
    local anyCompleted = false
    
    -- Check all active quests
    for i, questEntry in ipairs(state.activeQuests) do
        local questKey = questEntry.questKey
        local questDef = self:GetQuestDefinition(questKey, questEntry.questType)
        if not questDef then continue end
        
        local allConditionsMet = true
        
        -- Check if quest is already completed (not yet claimed)
        if state.completedQuests and state.completedQuests[questKey] then
            local claimData = state.completedQuests[questKey]
            if claimData.status == "completed" then
                -- Already complete, skip evaluation
                continue
            end
        end
        
        -- Evaluate each condition
        for condIdx, condition in ipairs(questDef.Conditions or {}) do
            local currentValue = self:GetConditionCurrentValue(player, condition, eventType, eventData)
            local isMet = self:EvaluateCondition(condition, currentValue)
            
            -- Track progress
            if questEntry.progress then
                questEntry.progress[condIdx] = currentValue
            end
            
            if not isMet then
                allConditionsMet = false
            end
        end
        
        -- Mark quest as completable if all conditions met
        if allConditionsMet and not (state.completedQuests[questKey] and state.completedQuests[questKey].status == "completed") then
            if not state.completedQuests then state.completedQuests = {} end
            state.completedQuests[questKey] = {
                completedAt = os.time(),
                status = "completed",
                questType = questEntry.questType,
            }
            anyCompleted = true
            
            -- Fire completed signal
            self.Client:Get("QuestCompleted"):Fire(player, {
                questKey = questKey,
                questName = questDef.Name,
                questType = questEntry.questType,
            })
        end
        
        anyProgressChanged = true
    end
    
    -- Also check milestone and achievement quests (always active, auto-tracked)
    local progressChangedMilestones = self:UpdateAutoTrackedQuestProgress(player, eventType, eventData)
    
    if anyProgressChanged or progressChangedMilestones then
        -- Fire progress update signal
        self.Client:Get("QuestProgressUpdated"):Fire(player, {
            activeCount = #state.activeQuests,
            hasCompleted = anyCompleted,
        })
    end
    
    -- Save state periodically
    self:SaveQuestState(player)
end

-- ============================================================
-- Auto-Tracked Quests (Milestones & Achievements)
-- ============================================================

function QuestService:UpdateAutoTrackedQuestProgress(player, eventType, eventData)
    local state = playerQuestState[player.UserId]
    if not state then return false end
    
    local anyChanged = false
    
    -- Check milestones
    for questKey, questDef in pairs(Config.MilestoneQuests or {}) do
        -- Skip if already claimed
        if state.claimedQuests and state.claimedQuests[questKey] then continue end
        
        -- Skip if prerequisites not met
        if questDef.Prerequisites then
            local prereqsMet = true
            for _, prereqKey in ipairs(questDef.Prerequisites) do
                if not (state.claimedQuests and state.claimedQuests[prereqKey]) then
                    prereqsMet = false
                    break
                end
            end
            if not prereqsMet then continue end
        end
        
        -- Check conditions
        local allMet = true
        for _, condition in ipairs(questDef.Conditions or {}) do
            local currentValue = self:GetConditionCurrentValue(player, condition, eventType, eventData)
            if not self:EvaluateCondition(condition, currentValue) then
                allMet = false
                break
            end
        end
        
        if allMet then
            -- Mark as completable
            if not state.completedQuests then state.completedQuests = {} end
            state.completedQuests[questKey] = {
                completedAt = os.time(),
                status = "completed",
                questType = "Milestone",
            }
            anyChanged = true
            
            self.Client:Get("QuestCompleted"):Fire(player, {
                questKey = questKey,
                questName = questDef.Name,
                questType = "Milestone",
            })
        end
    end
    
    -- Check achievements
    for questKey, questDef in pairs(Config.Achievements or {}) do
        if state.claimedQuests and state.claimedQuests[questKey] then continue end
        
        local allMet = true
        for _, condition in ipairs(questDef.Conditions or {}) do
            local currentValue = self:GetConditionCurrentValue(player, condition, eventType, eventData)
            if not self:EvaluateCondition(condition, currentValue) then
                allMet = false
                break
            end
        end
        
        if allMet then
            if not state.completedQuests then state.completedQuests = {} end
            state.completedQuests[questKey] = {
                completedAt = os.time(),
                status = "completed",
                questType = "Achievement",
            }
            anyChanged = true
            
            self.Client:Get("QuestCompleted"):Fire(player, {
                questKey = questKey,
                questName = questDef.Name,
                questType = "Achievement",
            })
        end
    end
    
    return anyChanged
end

-- ============================================================
-- Condition Evaluation
-- ============================================================

function QuestService:GetConditionCurrentValue(player, condition, eventType, eventData)
    local condType = condition.type
    local scope = condition.scope or "session"
    local profile = self:GetProfile(player)
    local state = playerQuestState[player.UserId]
    local session = state and state.sessionProgress or {}
    
    -- Lifetime scope values (from profile)
    if scope == "lifetime" then
        if condType == "MaxDepthReached" then
            return profile and profile.MaxDepthReached or 0
        elseif condType == "UniqueSpeciesCaught" then
            return profile and #(profile.DiscoveredCreatureIds or {}) or 0
        elseif condType == "TotalCreaturesCollected" then
            return profile and profile.TotalCreaturesCollected or 0
        elseif condType == "TotalCreaturesSold" then
            return profile and profile.TotalCreaturesSold or 0
        elseif condType == "TotalDives" then
            return profile and profile.TotalDives or 0
        elseif condType == "GearTierReached" then
            return profile and profile.CurrentGearTier or 1
        elseif condType == "BaseModulesPlaced" then
            return profile and #(profile.BaseModules or {}) or 0
        elseif condType == "BaseModuleMaxTier" then
            -- Find the highest tier among base modules
            local maxTier = 0
            for _, mod in ipairs(profile and profile.BaseModules or {}) do
                if mod.Tier and mod.Tier > maxTier then maxTier = mod.Tier end
            end
            return maxTier
        elseif condType == "ShinyCreaturesCaught" then
            -- Count shiny creatures in collection
            local count = 0
            for _, entry in ipairs(profile and profile.CreatureCollection or {}) do
                if entry.IsShiny then count = count + (entry.Count or 1) end
            end
            return count
        elseif condType == "LegendaryCaught" then
            local count = 0
            for _, entry in ipairs(profile and profile.CreatureCollection or {}) do
                if entry.Rarity == "Legendary" then count = count + (entry.Count or 1) end
            end
            return count
        elseif condType == "LifetimeCreditsEarned" then
            return profile and profile.TotalCreditsEarned or 0
        end
    end
    
    -- Session scope values (from session state)
    if scope == "session" or scope == nil then
        if condType == "CreaturesCaughtInSession" then
            local count = 0
            for _, c in pairs(session.CreaturesCaught or {}) do count = count + c end
            return count
        elseif condType == "CreaturesCaughtByRarity" then
            return session.RarityCounts and (session.RarityCounts[condition.rarity] or 0) or 0
        elseif condType == "CatchDuringAnomaly" then
            return self:GetAnomalyCatchCount(player, condition.anomaly)
        elseif condType == "CatchRarityDuringAnomaly" then
            return self:GetAnomalyCatchCountByRarity(player, condition.anomaly, condition.rarity)
        end
    end
    
    -- Single dive scope
    if scope == "single_dive" then
        if condType == "MaxDepthReached" then
            return session.MaxDepth or 0
        elseif condType == "OxygenUsed" then
            return session.OxygenUsed or 0
        elseif condType == "ScrapCollected" then
            return session.ScrapCollected or 0
        elseif condType == "CrystalCollected" then
            return session.CrystalCollected or 0
        elseif condType == "DepthGainDuringAnomaly" then
            return session.AnomalyDepthGain or 0
        end
    end
    
    -- Fallback: try to read from event data
    if condType == "MaxDepthReached" then
        return eventData and (eventData.maxDepth or eventData.newDepth or 0) or 0
    end
    
    return 0
end

function QuestService:EvaluateCondition(condition, currentValue)
    local comparison = condition.comparison or ">="
    local target = condition.value or condition.count or 0
    
    if comparison == ">=" then
        return currentValue >= target
    elseif comparison == ">" then
        return currentValue > target
    elseif comparison == "==" then
        return currentValue == target
    elseif comparison == "<=" then
        return currentValue <= target
    end
    
    return false
end

function QuestService:GetAnomalyCatchCount(player, anomalyKey)
    local state = playerQuestState[player.UserId]
    if not state then return 0 end
    return state.sessionProgress.AnomalyCatches and state.sessionProgress.AnomalyCatches[anomalyKey] or 0
end

function QuestService:GetAnomalyCatchCountByRarity(player, anomalyKey, rarity)
    local state = playerQuestState[player.UserId]
    if not state then return 0 end
    local catches = state.sessionProgress.AnomalyRarityCatches
    if not catches then return 0 end
    if not catches[anomalyKey] then return 0 end
    return catches[anomalyKey][rarity] or 0
end

-- ============================================================
-- Quest Definition Lookup
-- ============================================================

function QuestService:GetQuestDefinition(questKey, questType)
    if questType == "Daily" then
        return Config.DailyQuests and Config.DailyQuests[questKey]
    elseif questType == "Milestone" then
        return Config.MilestoneQuests and Config.MilestoneQuests[questKey]
    elseif questType == "Event" then
        return Config.EventQuests and Config.EventQuests[questKey]
    elseif questType == "Achievement" then
        return Config.Achievements and Config.Achievements[questKey]
    end
    return nil
end

-- ============================================================
-- Daily Quest Management
-- ============================================================

function QuestService:CheckAndRefreshDailyQuests(player)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    local now = os.time()
    local currentDay = os.date("!%Y%m%d", now)
    local storedDay = state.dailyState.RefreshDay or 0
    
    if tostring(currentDay) ~= tostring(storedDay) then
        -- New day — refresh daily quest pool
        self:RefreshDailyQuests(player)
    end
end

function QuestService:RefreshDailyQuests(player)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    local profile = self:GetProfile(player)
    if not profile then return end
    
    -- Build valid daily quest pool based on player level/depth
    local validPool = {}
    for key, def in pairs(Config.DailyQuests or {}) do
        local minLevel = def.MinPlayerLevel or 1
        local minDepth = def.MinPlayerDepth or 0
        local maxDepth = def.MaxPlayerDepth or math.huge
        
        if (profile.Level or 1) >= minLevel
            and (profile.MaxDepthReached or 0) >= minDepth
            and (profile.MaxDepthReached or 0) <= maxDepth then
            table.insert(validPool, { key = key, def = def })
        end
    end
    
    -- Weighted random selection
    local selectedKeys = {}
    local poolCopy = { table.unpack(validPool) }
    
    local maxQuests = Config.QuestSystem and Config.QuestSystem.MaxDailyQuests or 3
    
    for i = 1, math.min(maxQuests, #poolCopy) do
        -- Weighted selection
        local totalWeight = 0
        for _, entry in ipairs(poolCopy) do
            totalWeight = totalWeight + (entry.def.Weight or 10)
        end
        
        if totalWeight <= 0 then break end
        
        local roll = math.random() * totalWeight
        local cumulative = 0
        local pickedIdx = 1
        for idx, entry in ipairs(poolCopy) do
            cumulative = cumulative + (entry.def.Weight or 10)
            if roll <= cumulative then
                pickedIdx = idx
                break
            end
        end
        
        table.insert(selectedKeys, poolCopy[pickedIdx].key)
        table.remove(poolCopy, pickedIdx)
    end
    
    -- Update state
    state.dailyState = {
        RefreshDay = tonumber(os.date("!%Y%m%d", os.time())),
        AcceptedDailyKeys = selectedKeys,
        ReRollsUsed = 0,
        LastReRollTime = 0,
        CompletedToday = {},
    }
    
    -- Add daily quests to active quests (if not already there)
    -- Remove old dailies first
    local nonDailies = {}
    for _, q in ipairs(state.activeQuests) do
        if q.questType ~= "Daily" then
            table.insert(nonDailies, q)
        end
    end
    state.activeQuests = nonDailies
    
    -- Add new daily quests
    for _, key in ipairs(selectedKeys) do
        table.insert(state.activeQuests, {
            questKey = key,
            questType = "Daily",
            progress = {},
            acceptedAt = os.time(),
        })
    end
    
    -- Fire refresh signal
    self.Client:Get("DailyQuestRefresh"):Fire(player, {
        dailyKeys = selectedKeys,
    })
    
    self:SaveQuestState(player)
    
    print(string.format("[QuestService] Refreshed dailies for %s: %s",
        player.Name, table.concat(selectedKeys, ", ")))
end

-- ============================================================
-- Event Quest Management
-- ============================================================

function QuestService:AutoAcceptEventQuest(player, anomalyKey)
    -- Find the event quest definition
    local eventQuestDef = nil
    local eventQuestKey = nil
    for key, def in pairs(Config.EventQuests or {}) do
        if def.AnomalyKey == anomalyKey then
            eventQuestDef = def
            eventQuestKey = key
            break
        end
    end
    
    if not eventQuestDef then return end
    
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    -- Add event quest if not already active
    for _, q in ipairs(state.activeQuests) do
        if q.questKey == eventQuestKey then return end
    end
    
    table.insert(state.activeQuests, {
        questKey = eventQuestKey,
        questType = "Event",
        progress = {},
        acceptedAt = os.time(),
    })
    
    self.Client:Get("EventQuestStarted"):Fire(player, {
        questKey = eventQuestKey,
        questName = eventQuestDef.Name,
        anomalyKey = anomalyKey,
    })
    
    self:SaveQuestState(player)
end

function QuestService:RemoveExpiredEventQuests(player, anomalyKey)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    local toRemove = {}
    for idx, q in ipairs(state.activeQuests) do
        if q.questType == "Event" then
            local def = Config.EventQuests and Config.EventQuests[q.questKey]
            if def and def.AnomalyKey == anomalyKey then
                table.insert(toRemove, idx)
            end
        end
    end
    
    for i = #toRemove, 1, -1 do
        table.remove(state.activeQuests, toRemove[i])
    end
end

-- ============================================================
-- Reward Claiming
-- ============================================================

function QuestService:ClaimReward(player, questKey)
    local state = playerQuestState[player.UserId]
    if not state then
        return { success = false, reason = "Quest state not loaded" }
    end
    
    -- Check quest is completed (in completedQuests)
    local completedData = state.completedQuests and state.completedQuests[questKey]
    if not completedData or completedData.status ~= "completed" then
        return { success = false, reason = "Quest is not yet completed" }
    end
    
    -- Check quest not already claimed
    if state.claimedQuests and state.claimedQuests[questKey] then
        return { success = false, reason = "Quest already claimed" }
    end
    
    -- Get quest definition
    local questDef = self:GetQuestDefinition(questKey, completedData.questType)
    if not questDef then
        return { success = false, reason = "Quest definition not found" }
    end
    
    -- Deliver rewards
    local EconomyService = Knit.GetService("EconomyService")
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    
    for _, reward in ipairs(questDef.Rewards or {}) do
        if reward.type == "Credits" then
            EconomyService:AddCredits(player, reward.amount)
        elseif reward.type == "ResearchPoints" then
            EconomyService:AddResearchPoints(player, reward.amount)
        elseif reward.type == "XP" then
            EconomyService:AddXP(player, reward.amount)
        elseif reward.type == "Consumable" then
            EconomyService:AddItemToInventory(player, reward.item, reward.count or 1)
        elseif reward.type == "Scrap" then
            EconomyService:AddResource(player, "Scrap", reward.amount)
        elseif reward.type == "Crystal" then
            EconomyService:AddResource(player, "Crystal", reward.amount)
        elseif reward.type == "Title" then
            DataStoreManager:UpdateProfile(player, function(profile)
                if not profile.EquippedTitle then profile.EquippedTitle = {} end
                profile.EquippedTitle = reward.title
            end)
        elseif reward.type == "Cosmetic" then
            DataStoreManager:UpdateProfile(player, function(profile)
                if not profile.UnlockedCosmetics then profile.UnlockedCosmetics = {} end
                table.insert(profile.UnlockedCosmetics, reward.item)
            end)
        end
    end
    
    -- Mark as claimed
    if not state.claimedQuests then state.claimedQuests = {} end
    state.claimedQuests[questKey] = true
    
    -- If it's a daily quest, track completion for today
    if completedData.questType == "Daily" then
        if state.dailyState then
            if not state.dailyState.CompletedToday then state.dailyState.CompletedToday = {} end
            state.dailyState.CompletedToday[questKey] = true
        end
    end
    
    -- Save and fire signal
    self:SaveQuestState(player)
    
    self.Client:Get("QuestClaimed"):Fire(player, {
        questKey = questKey,
        questName = questDef.Name,
        rewards = questDef.Rewards,
    })
    
    print(string.format("[QuestService] %s claimed reward for '%s' (type: %s)",
        player.Name, questDef.Name, completedData.questType))
    
    return { success = true }
end

-- ============================================================
-- Quest Accept (for daily quests)
-- ============================================================

function QuestService:AcceptDailyQuest(player, questKey)
    local state = playerQuestState[player.UserId]
    if not state then
        return { success = false, reason = "Quest state not loaded" }
    end
    
    -- Check if this quest key is in the offered pool
    local isOffered = false
    if state.dailyState and state.dailyState.AcceptedDailyKeys then
        for _, key in ipairs(state.dailyState.AcceptedDailyKeys) do
            if key == questKey then isOffered = true; break end
        end
    end
    
    if not isOffered then
        return { success = false, reason = "Quest not available in today's pool" }
    end
    
    -- Check if already active
    for _, q in ipairs(state.activeQuests) do
        if q.questKey == questKey then
            return { success = true } -- Already accepted, treat as no-op
        end
    end
    
    table.insert(state.activeQuests, {
        questKey = questKey,
        questType = "Daily",
        progress = {},
        acceptedAt = os.time(),
    })
    
    self:SaveQuestState(player)
    return { success = true }
end

-- ============================================================
-- Daily Re-roll
-- ============================================================

function QuestService:ReRollDailyQuest(player, questKey)
    local state = playerQuestState[player.UserId]
    if not state then
        return { success = false, reason = "Quest state not loaded" }
    end
    
    -- Check re-roll limit
    local maxReRolls = Config.QuestSystem and Config.QuestSystem.MaxReRollsPerDay or 1
    local cooldown = Config.QuestSystem and Config.QuestSystem.ReRollCooldown or 1800
    
    if (state.dailyState.ReRollsUsed or 0) >= maxReRolls then
        return { success = false, reason = "No re-rolls remaining today" }
    end
    
    if (os.time() - (state.dailyState.LastReRollTime or 0)) < cooldown then
        return { success = false, reason = "Re-roll on cooldown" }
    end
    
    -- Remove the old daily quest
    for i, q in ipairs(state.activeQuests) do
        if q.questKey == questKey and q.questType == "Daily" then
            table.remove(state.activeQuests, i)
            break
        end
    end
    
    -- Remove from accepted keys
    if state.dailyState and state.dailyState.AcceptedDailyKeys then
        for i, key in ipairs(state.dailyState.AcceptedDailyKeys) do
            if key == questKey then
                table.remove(state.dailyState.AcceptedDailyKeys, i)
                break
            end
        end
    end
    
    -- Pick a new quest from remaining pool
    local validPool = {}
    for key, def in pairs(Config.DailyQuests or {}) do
        -- Skip if already active
        local isActive = false
        for _, q in ipairs(state.activeQuests) do
            if q.questKey == key then isActive = true; break end
        end
        -- Skip if already completed today
        local isCompleted = state.dailyState.CompletedToday and state.dailyState.CompletedToday[key]
        
        if not isActive and not isCompleted then
            table.insert(validPool, { key = key, def = def })
        end
    end
    
    if #validPool > 0 then
        local pick = validPool[math.random(1, #validPool)]
        table.insert(state.activeQuests, {
            questKey = pick.key,
            questType = "Daily",
            progress = {},
            acceptedAt = os.time(),
        })
        table.insert(state.dailyState.AcceptedDailyKeys, pick.key)
    end
    
    -- Update state
    state.dailyState.ReRollsUsed = (state.dailyState.ReRollsUsed or 0) + 1
    state.dailyState.LastReRollTime = os.time()
    
    self:SaveQuestState(player)
    
    self.Client:Get("DailyQuestRefresh"):Fire(player, {
        dailyKeys = state.dailyState.AcceptedDailyKeys,
    })
    
    return { success = true }
end

-- ============================================================
-- Daily Refresh Loop
-- ============================================================

function QuestService:StartDailyRefreshLoop()
    while task.wait(300) do -- Check every 5 minutes
        for _, player in ipairs(Players:GetPlayers()) do
            self:CheckAndRefreshDailyQuests(player)
        end
    end
end

-- ============================================================
-- Client Handlers
-- ============================================================

function QuestService.Client:GetActiveQuests(player)
    local self = QuestService
    local state = playerQuestState[player.UserId]
    if not state then return { quests = {} } end
    
    -- Build response with progress info
    local questList = {}
    for _, q in ipairs(state.activeQuests) do
        local def = self:GetQuestDefinition(q.questKey, q.questType)
        table.insert(questList, {
            questKey = q.questKey,
            questType = q.questType,
            name = def and def.Name or "Unknown",
            description = def and def.Description or "",
            acceptedAt = q.acceptedAt,
            progress = q.progress,
            isCompleted = state.completedQuests and state.completedQuests[q.questKey] and
                state.completedQuests[q.questKey].status == "completed",
            isClaimed = state.claimedQuests and state.claimedQuests[q.questKey] or false,
            conditions = def and def.Conditions or {},
            rewards = def and def.Rewards or {},
        })
    end
    
    return { quests = questList }
end

function QuestService.Client:GetCompletedQuests(player)
    local self = QuestService
    local state = playerQuestState[player.UserId]
    if not state then return { quests = {} } end
    
    local completedList = {}
    for questKey, data in pairs(state.completedQuests or {}) do
        if data.status == "completed" and not (state.claimedQuests and state.claimedQuests[questKey]) then
            local def = self:GetQuestDefinition(questKey, data.questType)
            table.insert(completedList, {
                questKey = questKey,
                questType = data.questType,
                name = def and def.Name or "Unknown",
                description = def and def.Description or "",
                completedAt = data.completedAt,
                rewards = def and def.Rewards or {},
            })
        end
    end
    
    return { quests = completedList }
end

function QuestService.Client:GetAvailableQuests(player)
    local self = QuestService
    local state = playerQuestState[player.UserId]
    if not state then return { quests = {} } end
    
    -- Return offered daily pool keys + active count
    return {
        dailyKeys = state.dailyState and state.dailyState.AcceptedDailyKeys or {},
        reRollsRemaining = (Config.QuestSystem and Config.QuestSystem.MaxReRollsPerDay or 1)
            - (state.dailyState and state.dailyState.ReRollsUsed or 0),
        reRollCooldown = math.max(0, (Config.QuestSystem and Config.QuestSystem.ReRollCooldown or 1800)
            - (os.time() - (state.dailyState and state.dailyState.LastReRollTime or 0))),
    }
end

function QuestService.Client:GetQuestCatalog(player)
    local self = QuestService
    
    -- Return all quest definitions (for UI catalog display)
    local catalog = {
        milestones = {},
        achievements = {},
        dailyDefs = {},
        eventDefs = {},
    }
    
    for key, def in pairs(Config.MilestoneQuests or {}) do
        table.insert(catalog.milestones, { key = key, name = def.Name, description = def.Description, order = def.Order or 99 })
    end
    for key, def in pairs(Config.Achievements or {}) do
        table.insert(catalog.achievements, { key = key, name = def.Name, description = def.Description })
    end
    for key, def in pairs(Config.DailyQuests or {}) do
        table.insert(catalog.dailyDefs, { key = key, name = def.Name, description = def.Description })
    end
    for key, def in pairs(Config.EventQuests or {}) do
        table.insert(catalog.eventDefs, { key = key, name = def.Name, description = def.Description, anomalyKey = def.AnomalyKey })
    end
    
    return catalog
end

function QuestService.Client:AcceptDailyQuest(player, questKey)
    return QuestService:AcceptDailyQuest(player, questKey)
end

function QuestService.Client:ClaimQuestReward(player, questKey)
    return QuestService:ClaimReward(player, questKey)
end

function QuestService.Client:ReRollDailyQuest(player, questKey)
    return QuestService:ReRollDailyQuest(player, questKey)
end

-- ============================================================
-- Persistence Helpers
-- ============================================================

function QuestService:GetProfile(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    return DataStoreManager:GetPlayerProfileSync(player)
end

function QuestService:SaveQuestState(player)
    local state = playerQuestState[player.UserId]
    if not state then return end
    
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    DataStoreManager:UpdateProfile(player, function(profile)
        profile.ActiveQuests = state.activeQuests
        profile.CompletedQuests = state.completedQuests
        profile.ClaimedQuests = state.claimedQuests
        profile.DailyQuestState = state.dailyState
    end)
end

return QuestService