--[[
    DepthService — Manages depth layers, diving gear, and pressure mechanics
    Controls which zones players can access based on their gear tier.
    Integrated with EconomyService for gear purchases and DataStoreManager for persistence.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local DepthService = Knit.CreateService {
    Name = "DepthService",
    Client = {
        GetDepthData = Knit.CreateSignal(),
        GetLayerInfo = Knit.CreateSignal(),
        GetGearInfo = Knit.CreateSignal(),
        UpgradeGearRequest = Knit.CreateSignal(),
        DepthXPUpdate = Knit.CreateSignal(), -- XP earned from exploration
    }
}

-- Internal state
local playerDepths = {}    -- { [UserId] = { depth, layerIndex, gearTier, maxDepthReached, ownedGearTiers[] } }
local zoneEntryRewards = {} -- Track zone entry for first-time RP rewards

-- ============================================================
-- Initialize
-- ============================================================

function DepthService:KnitStart()
    print("[DepthService] Initialized")
end

-- Called by DataStoreManager after loading a profile
function DepthService:ReloadFromProfile(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profileSync = DataStoreManager:GetPlayerProfileSync(player)
    
    playerDepths[player.UserId] = {
        depth = 0,
        layerIndex = 1,
        gearTier = profileSync.CurrentGearTier or 1,
        maxDepthReached = profileSync.MaxDepthReached or 0,
        ownedGearTiers = profileSync.OwnedGearTiers or {1},
    }
    
    print(string.format("[DepthService] Loaded depth data for %s (%d): Gear T%d, Max Depth %dm",
        player.Name, player.UserId, playerDepths[player.UserId].gearTier, playerDepths[player.UserId].maxDepthReached))
end

function DepthService:PlayerRemoving(player)
    playerDepths[player.UserId] = nil
end

-- ============================================================
-- Depth Management
-- ============================================================

function DepthService:UpdatePlayerDepth(player, newDepth)
    local data = playerDepths[player.UserId]
    if not data then return end
    
    local clampedDepth = Util.Clamp(newDepth, 0, self:GetMaxDepthForGear(data.gearTier))
        local previousLayer = data.layerIndex
        local previousDepth = data.depth -- Track previous depth for reward calculation

        data.depth = clampedDepth
        data.layerIndex = Util.DepthToLayerIndex(clampedDepth)
    
    -- Track max depth
    if clampedDepth > data.maxDepthReached then
        data.maxDepthReached = clampedDepth
    end
    
    -- Check for zone transition
    if previousLayer ~= data.layerIndex then
        local newLayer = Config.DepthLayers[data.layerIndex]
        
        self.Client:Get("GetLayerInfo"):Fire(player, {
            index = data.layerIndex,
            name = newLayer.Name,
            description = newLayer.Description,
            color = newLayer.Color,
        })
        
        -- Award Research Points for first-time zone entry
        self:AwardZoneEntryReward(player, data.layerIndex)
        
        -- Apply pressure damage if player is below safe depth
        if data.gearTier < data.layerIndex then
            self:ApplyPressureDamage(player, data.layerIndex - data.gearTier)
        end
    end
    
    -- Award XP/Credits for exploration depth
    self:AwardDepthExplorationReward(player, clampedDepth - previousDepth)
    
    -- Send update to client
    self:FireDepthUpdate(player, data)
end

function DepthService:FireDepthUpdate(player, data)
    self.Client:Get("GetDepthData"):Fire(player, {
        depth = data.depth,
        layerIndex = data.layerIndex,
        maxDepth = self:GetMaxDepthForGear(data.gearTier),
        maxDepthReached = data.maxDepthReached,
        layerName = Config.DepthLayers[data.layerIndex].Name,
        gearTier = data.gearTier,
        ownedGearTiers = data.ownedGearTiers,
        nextGearName = Config.DivingGear[data.gearTier + 1] and Config.DivingGear[data.gearTier + 1].Name or nil,
        nextGearPrice = Config.DivingGear[data.gearTier + 1] and Config.DivingGear[data.gearTier + 1].Price or nil,
    })
end

-- ============================================================
-- Zone Entry Rewards
-- ============================================================

function DepthService:AwardZoneEntryReward(player, layerIndex)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    
    if DataStoreManager:HasDiscoveredZone(player, layerIndex) then
        return -- Already discovered this zone
    end
    
    local layer = Config.DepthLayers[layerIndex]
    if not layer or not layer.ResearchPointsPerEntry then return end
    
    -- Mark as discovered
    DataStoreManager:MarkZoneDiscovered(player, layerIndex)
    
    -- Award Research Points
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        EconomyService:AddResearchPoints(player, layer.ResearchPointsPerEntry)
        
        -- Also grant credits for milestone
        local creditsBonus = layerIndex * 15
        EconomyService:AddCredits(player, creditsBonus)
    end
    
    -- Notify player
    self.Client:Get("GetLayerInfo"):Fire(player, {
        index = layerIndex,
        name = layer.Name,
        description = layer.Description,
        color = layer.Color,
        isFirstDiscovery = true,
        rpAwarded = layer.ResearchPointsPerEntry,
        creditsAwarded = creditsBonus,
    })
end

-- ============================================================
-- Exploration Rewards
-- ============================================================

function DepthService:AwardDepthExplorationReward(player, depthDelta)
    if depthDelta <= 0 then return end
    
    local EconomyService = Knit.GetService("EconomyService")
    if not EconomyService then return end
    
    -- XP per meter
    local xpGain = math.floor(depthDelta * Config.Economy.XPPerDepthMeter)
    if xpGain > 0 then
        EconomyService:AddXP(player, xpGain)
    end
    
    -- Credits per meter (small amount)
    local creditsGain = math.floor(depthDelta * Config.Economy.CreditsPerDepthMeter)
    if creditsGain > 0 then
        EconomyService:AddCredits(player, creditsGain)
    end
end

-- ============================================================
-- Dive Complete Rewards
-- ============================================================

function DepthService:CompleteDive(player)
        local data = playerDepths[player.UserId]
        if not data then return end

        if data.depth <= 0 then return end -- No dive to complete

        local EconomyService = Knit.GetService("EconomyService")
        if not EconomyService then return end

        -- Use Config.DiveBonuses to determine bonus based on max depth reached
        local diveBonus = Config.Economy.CreditsPerDiveComplete or 15
        local diveLabel = "Dive Complete"
        for _, bonus in ipairs(Config.DiveBonuses or {}) do
            if data.maxDepthReached >= bonus.minDepth and data.maxDepthReached <= bonus.maxDepth then
                diveBonus = bonus.bonus
                diveLabel = bonus.label
                break
            end
        end

        EconomyService:AddCredits(player, diveBonus)

        -- Award resources for dive (Scrap + Crystal based on depth)
        local scrapGain = math.floor(data.maxDepthReached * (Config.Resources.Scrap.PerDepthMeter or 0.05))
        local crystalGain = math.floor(data.maxDepthReached * (Config.Resources.Crystal.PerDepthMeter or 0.01))
        if scrapGain > 0 then EconomyService:AddResource(player, "Scrap", scrapGain) end
        if crystalGain > 0 then EconomyService:AddResource(player, "Crystal", crystalGain) end

        -- Award one-time depth milestone bonuses (checked via DataStore)
        self:AwardDepthMilestones(player, data)

        -- Notify player about dive reward
        if diveBonus > 0 or scrapGain > 0 or crystalGain > 0 then
            self.Client:Get("GetDepthData"):Fire(player, {
                diveComplete = true,
                bonus = diveBonus,
                label = diveLabel,
                scrapEarned = scrapGain,
                crystalEarned = crystalGain,
            })
        end

        -- Reset surface
        data.depth = 0
        data.layerIndex = 1

        self:FireDepthUpdate(player, data)
    end

    function DepthService:AwardDepthMilestones(player, data)
        local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
        local EconomyService = Knit.GetService("EconomyService")
        if not EconomyService then return end

        for _, ms in ipairs(Config.DepthMilestones or {}) do
            if data.maxDepthReached >= ms.depth then
                -- Check if already awarded this milestone
                if not DataStoreManager:HasDiscoveredZone(player, ms.depth) then
                    -- Mark as awarded (use depth value as unique key)
                    DataStoreManager:MarkZoneDiscovered(player, ms.depth)

                    -- Award Credits
                    if ms.credits and ms.credits > 0 then
                        EconomyService:AddCredits(player, ms.credits)
                    end

                    -- Award Research Points
                    if ms.rpReward and ms.rpReward > 0 then
                        EconomyService:AddResearchPoints(player, ms.rpReward)
                    end

                    -- Notify player of milestone
                    self.Client:Get("GetLayerInfo"):Fire(player, {
                        milestoneReached = true,
                        depth = ms.depth,
                        title = ms.title,
                        creditsAwarded = ms.credits or 0,
                        rpAwarded = ms.rpReward or 0,
                    })
                end
            end
        end
    end

-- ============================================================
-- Gear System
-- ============================================================

function DepthService:GetPlayerDepth(player)
    local data = playerDepths[player.UserId]
    return data and data.depth or 0
end

function DepthService:GetPlayerGearTier(player)
    local data = playerDepths[player.UserId]
    return data and data.gearTier or 1
end

function DepthService:GetPlayerDepthData(player)
    local data = playerDepths[player.UserId]
    if not data then return {} end
    return {
        depth = data.depth,
        layerIndex = data.layerIndex,
        gearTier = data.gearTier,
        maxDepthReached = data.maxDepthReached,
        ownedGearTiers = data.ownedGearTiers,
    }
end

function DepthService:GetMaxDepthForGear(gearTier)
    local gear = Config.DivingGear[gearTier]
    return gear and gear.MaxDepth or 200
end

function DepthService:UpgradeGear(player)
    local data = playerDepths[player.UserId]
    if not data then return { success = false, reason = "Player not found" } end
    
    local nextTier = data.gearTier + 1
    local nextGear = Config.DivingGear[nextTier]
    
    if not nextGear then
        return { success = false, reason = "Maximum gear tier reached" }
    end
    
    -- Check if already owned
    if table.find(data.ownedGearTiers, nextTier) then
        data.gearTier = nextTier
        return { success = true, tier = nextTier, name = nextGear.Name }
    end
    
    -- Economy check is handled by EconomyService before calling this
    data.gearTier = nextTier
    table.insert(data.ownedGearTiers, nextTier)
    
    -- Update DataStore
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    DataStoreManager:UpdateProfile(player, function(profile)
        profile.CurrentGearTier = nextTier
        profile.OwnedGearTiers = data.ownedGearTiers
    end)
    
    self:FireDepthUpdate(player, data)
    
    return { success = true, tier = nextTier, name = nextGear.Name }
end

-- ============================================================
-- Pressure Damage
-- ============================================================

function DepthService:ApplyPressureDamage(player, levelsExceeded)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local damage = Config.Player.PressureDamagePerLevel * levelsExceeded
    humanoid:TakeDamage(damage)
    
    self.Client:Get("GetDepthData"):Fire(player, {
        pressureWarning = true,
        damage = damage,
    })
end

function DepthService:SurfacePlayer(player)
    local data = playerDepths[player.UserId]
    if not data then return end
    
    -- Complete the dive before surfacing
    self:CompleteDive(player)
end

-- ============================================================
-- Client Methods
-- ============================================================

function DepthService.Client:GetDepthData(player)
    local self = DepthService
    local data = playerDepths[player.UserId]
    if not data then return {} end
    return {
        depth = data.depth,
        layerIndex = data.layerIndex,
        maxDepth = self:GetMaxDepthForGear(data.gearTier),
        maxDepthReached = data.maxDepthReached,
        layerName = Config.DepthLayers[data.layerIndex].Name,
        gearTier = data.gearTier,
        nextGearName = Config.DivingGear[data.gearTier + 1] and Config.DivingGear[data.gearTier + 1].Name or nil,
        nextGearPrice = Config.DivingGear[data.gearTier + 1] and Config.DivingGear[data.gearTier + 1].Price or nil,
    }
end

function DepthService.Client:GetLayerInfo(player, layerIndex)
    local self = DepthService
    local layer = Config.DepthLayers[layerIndex]
    if not layer then return {} end
    return {
        index = layerIndex,
        name = layer.Name,
        description = layer.Description,
        depthRange = string.format("%d - %d m", layer.DepthMin, layer.DepthMax),
        creatureRarities = table.concat(layer.CreatureRarityPool, ", "),
        researchPointsReward = layer.ResearchPointsPerEntry,
    }
end

function DepthService.Client:GetGearInfo(player)
    local self = DepthService
    local data = playerDepths[player.UserId]
    if not data then return { currentTier = 1, ownedTiers = {1}, availableUpgrades = {} } end
    
    local upgrades = {}
    for i = data.gearTier + 1, #Config.DivingGear do
        local gear = Config.DivingGear[i]
        if gear then
            table.insert(upgrades, {
                tier = gear.Tier,
                name = gear.Name,
                description = gear.Description,
                price = gear.Price,
                currencyType = gear.PriceCurrency,
                maxDepth = gear.MaxDepth,
                oxygenBonus = gear.OxygenBonus,
            })
        end
    end
    
    return {
        currentTier = data.gearTier,
        ownedTiers = data.ownedGearTiers,
        availableUpgrades = upgrades,
    }
end

function DepthService.Client:UpgradeGearRequest(player)
    local self = DepthService
    -- Route through EconomyService which handles the purchase then calls this
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        local data = playerDepths[player.UserId]
        if data then
            return EconomyService:PurchaseGear(player, data.gearTier + 1)
        end
    end
    return { success = false, reason = "System unavailable" }
end

return DepthService