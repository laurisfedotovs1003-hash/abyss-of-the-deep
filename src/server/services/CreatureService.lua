--[[
    CreatureService — Handles creature spawning, AI behavior, catch mechanics
    Manages rarity pools per depth layer and creature encounter logic.
    Integrated with EconomyService for catch rewards and CollectionService for tracking.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local CreatureService = Knit.CreateService {
    Name = "CreatureService",
    Client = {
        CreatureSpawned = Knit.CreateSignal(),
        CreatureCaught = Knit.CreateSignal(),
        RequestCatch = Knit.CreateSignal(),
        CreatureDespawned = Knit.CreateSignal(),
        RequestSellCreature = Knit.CreateSignal(),
        
        -- Discovery signals
        FirstDiscovery = Knit.CreateSignal(),
    }
}

-- Creature definitions per depth layer
local creatures = {
    [1] = { -- Sunlight Zone
        { Id = "clownfish", DisplayName = "Clownfish", Rarity = "Common", Weight = 0.2, Size = 1 },
        { Id = "parrotfish", DisplayName = "Parrotfish", Rarity = "Common", Weight = 0.5, Size = 1 },
        { Id = "seahorse", DisplayName = "Seahorse", Rarity = "Common", Weight = 0.1, Size = 1 },
        { Id = "angelfish", DisplayName = "Angelfish", Rarity = "Common", Weight = 0.3, Size = 1 },
        { Id = "tropical_ray", DisplayName = "Spotted Ray", Rarity = "Uncommon", Weight = 15, Size = 2 },
        { Id = "sea_turtle", DisplayName = "Sea Turtle", Rarity = "Uncommon", Weight = 80, Size = 2 },
        { Id = "manta_ray", DisplayName = "Manta Ray", Rarity = "Rare", Weight = 200, Size = 3 },
    },
    [2] = { -- Twilight Zone
        { Id = "lanternfish", DisplayName = "Lanternfish", Rarity = "Common", Weight = 0.05, Size = 1 },
        { Id = "squid", DisplayName = "Squid", Rarity = "Common", Weight = 2, Size = 1 },
        { Id = "hatchetfish", DisplayName = "Hatchetfish", Rarity = "Common", Weight = 0.1, Size = 1 },
        { Id = "vampire_squid", DisplayName = "Vampire Squid", Rarity = "Uncommon", Weight = 1, Size = 1 },
        { Id = "jellyfish_glowing", DisplayName = "Glowing Jellyfish", Rarity = "Uncommon", Weight = 0.5, Size = 2 },
        { Id = "barreleye", DisplayName = "Barreleye Fish", Rarity = "Rare", Weight = 0.3, Size = 1 },
        { Id = "dragonfish", DisplayName = "Dragonfish", Rarity = "Rare", Weight = 0.5, Size = 1 },
    },
    [3] = { -- Midnight Zone
        { Id = "anglerfish", DisplayName = "Anglerfish", Rarity = "Uncommon", Weight = 3, Size = 2 },
        { Id = "gulper_eel", DisplayName = "Gulper Eel", Rarity = "Uncommon", Weight = 5, Size = 2 },
        { Id = "viperfish", DisplayName = "Viperfish", Rarity = "Rare", Weight = 1, Size = 1 },
        { Id = "giant_squid", DisplayName = "Giant Squid", Rarity = "Epic", Weight = 500, Size = 4 },
        { Id = "colossal_jelly", DisplayName = "Colossal Jellyfish", Rarity = "Epic", Weight = 300, Size = 4 },
    },
    [4] = { -- Abyssal Zone
        { Id = "abyssal_grenadier", DisplayName = "Abyssal Grenadier", Rarity = "Rare", Weight = 2, Size = 2 },
        { Id = "dumbo_octopus", DisplayName = "Dumbo Octopus", Rarity = "Epic", Weight = 8, Size = 2 },
        { Id = "giant_isopod", DisplayName = "Giant Isopod", Rarity = "Rare", Weight = 2, Size = 2 },
        { Id = "abyssal_angler", DisplayName = "Abyssal Angler", Rarity = "Epic", Weight = 10, Size = 3 },
        { Id = "deep_sea_dragon", DisplayName = "Deep Sea Dragon", Rarity = "Legendary", Weight = 1000, Size = 5 },
    },
    [5] = { -- Trenches
        { Id = "trench_eel", DisplayName = "Trench Eel", Rarity = "Epic", Weight = 50, Size = 3 },
        { Id = "abyssal_serpent", DisplayName = "Abyssal Serpent", Rarity = "Legendary", Weight = 2000, Size = 5 },
        { Id = "void_jelly", DisplayName = "Void Jelly", Rarity = "Epic", Weight = 100, Size = 3 },
        { Id = "leviathan", DisplayName = "Leviathan", Rarity = "Legendary", Weight = 5000, Size = 5 },
        { Id = "ancient_one", DisplayName = "Ancient One", Rarity = "Legendary", Weight = 10000, Size = 5 },
    },
}

local activeEncounteredCreatures = {} -- { [playerUserId] = { creature = {}, isShiny, spawnedAt } }

-- ============================================================
-- Initialize
-- ============================================================

function CreatureService:KnitStart()
    print("[CreatureService] Initialized")
    
    -- Creature encounter check loop (every 5 seconds)
    while task.wait(5) do
        self:ProcessEncounters()
    end
end

-- ============================================================
-- Creature Pool & Rolling
-- ============================================================

function CreatureService:GetCreaturesForDepthLayer(layerIndex)
    return creatures[layerIndex] or creatures[1]
end

function CreatureService:RollEncounter(layerIndex)
    local pool = creatures[layerIndex]
    if not pool or #pool == 0 then return nil end
    
    local ConfigLayer = Config.DepthLayers[layerIndex]
    local rarityPool = ConfigLayer.CreatureRarityPool
    
    local candidates = {}
    for _, creatureDef in ipairs(pool) do
        if table.find(rarityPool, creatureDef.Rarity) then
            table.insert(candidates, creatureDef)
        end
    end
    
    if #candidates == 0 then
        candidates = pool
    end
    
    local creatureDef = candidates[math.random(#candidates)]
    local isShiny = math.random() <= 0.01
    
    return creatureDef, isShiny
end

-- ============================================================
-- Encounter Management
-- ============================================================

function CreatureService:ProcessEncounters()
    for userId, encounter in pairs(activeEncounteredCreatures) do
        if os.time() - encounter.spawnedAt > 30 then
            local player = game:GetService("Players"):GetPlayerByUserId(userId)
            if player then
                self.Client:Get("CreatureDespawned"):Fire(player, {
                    creatureId = encounter.creature.Id,
                })
            end
            activeEncounteredCreatures[userId] = nil
        end
    end
end

function CreatureService:SpawnCreatureForPlayer(player, layerIndex)
    local creatureDef, isShiny = self:RollEncounter(layerIndex)
    if not creatureDef then return end
    
    local rarityConfig = Config.CreatureRarity[creatureDef.Rarity]
    
    activeEncounteredCreatures[player.UserId] = {
        creature = creatureDef,
        isShiny = isShiny,
        spawnedAt = os.time(),
    }
    
    self.Client:Get("CreatureSpawned"):Fire(player, {
        id = creatureDef.Id,
        displayName = creatureDef.DisplayName,
        rarity = creatureDef.Rarity,
        rarityColor = rarityConfig.Color,
        isShiny = isShiny,
        weight = creatureDef.Weight,
        size = creatureDef.Size,
        rarityWeight = rarityConfig.Weight,
    })
end

-- ============================================================
-- Catch Logic (with Economy Integration)
-- ============================================================

function CreatureService.Client:RequestCatch(player)
    local self = CreatureService
    local encounter = activeEncounteredCreatures[player.UserId]
    
    if not encounter then
        return { result = "NoCreature", reason = "No creature nearby" }
    end
    
    local creatureDef = encounter.creature
    local rarityConfig = Config.CreatureRarity[creatureDef.Rarity]
    
    -- Skill-based catch: ~60% base chance, modified by rarity
    local baseCatchChance = 0.6
    local catchModifier = 1 / (rarityConfig.Weight / 15)
    local catchChance = baseCatchChance * catchModifier
    
    -- Check for active catch rate boosts from inventory
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        local ecoData = EconomyService:GetPlayerData(player)
        if ecoData and ecoData.ActiveBoosts then
            for _, boost in ipairs(ecoData.ActiveBoosts) do
                if boost.effect == "CatchBoost" and boost.expiresAt > os.time() then
                    catchChance = catchChance * 1.25 -- Lucky Charm boost
                end
            end
        end
    end
    
    local success = math.random() <= catchChance
    
    if success then
        activeEncounteredCreatures[player.UserId] = nil
        
        -- Calculate rewards
        local sellPrice = math.random(rarityConfig.SellPriceMin, rarityConfig.SellPriceMax)
        if encounter.isShiny then
            sellPrice = sellPrice * 3
        end
        
        local xpReward = rarityConfig.XPMultiplier * Config.Economy.XPPerCreatureCaptured
        local rpReward = 0
        
        -- Award XP and Credits through EconomyService
        if EconomyService then
            EconomyService:AddXP(player, xpReward)
            EconomyService:AddCredits(player, sellPrice) -- Auto-cash on catch
        end
        
        -- Add to collection
        local CollectionService = Knit.GetService("CollectionService")
        local isFirstDiscovery = false
        if CollectionService then
            isFirstDiscovery = CollectionService:AddCreatureToCollection(player, {
                id = creatureDef.Id,
                displayName = creatureDef.DisplayName,
                rarity = creatureDef.Rarity,
                isShiny = encounter.isShiny,
                weight = creatureDef.Weight,
                size = creatureDef.Size,
            })
        end
        
        -- Award Research Points for first-time discovery
        if isFirstDiscovery and rarityConfig.ResearchPointsOnFirstDiscovery then
            rpReward = rarityConfig.ResearchPointsOnFirstDiscovery
            if EconomyService then
                EconomyService:AddResearchPoints(player, rpReward)
            end
        end
        
        -- Fire catch event to client
        self.Client:Get("CreatureCaught"):Fire(player, {
            id = creatureDef.Id,
            displayName = creatureDef.DisplayName,
            rarity = creatureDef.Rarity,
            rarityColor = rarityConfig.Color,
            isShiny = encounter.isShiny,
            weight = creatureDef.Weight,
            size = creatureDef.Size,
            sellPrice = sellPrice,
            xpReward = xpReward,
            rpReward = rpReward,
            isFirstDiscovery = isFirstDiscovery,
        })
        
        return {
            result = "Success",
            creature = {
                id = creatureDef.Id,
                displayName = creatureDef.DisplayName,
                rarity = creatureDef.Rarity,
                isShiny = encounter.isShiny,
                weight = creatureDef.Weight,
            },
            creditsAwarded = sellPrice,
            xpGained = xpReward,
            rpGained = rpReward,
            isFirstDiscovery = isFirstDiscovery,
        }
    else
        -- Creature escapes but stays for another attempt
        return { result = "Failed", reason = "It got away! Try again." }
    end
end

-- ============================================================
-- Sell Creature (from collection inventory)
-- ============================================================

function CreatureService.Client:RequestSellCreature(player, creatureEntryId)
    local self = CreatureService
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profileData = DataStoreManager:GetPlayerProfileSync(player)
    
    if not profileData or not profileData.CreatureCollection then
        return { success = false, reason = "No creature found" }
    end
    
    -- Find creature in collection
    local creatureToSell = nil
    local creatureIndex = nil
    for i, entry in ipairs(profileData.CreatureCollection) do
        if entry.Id == creatureEntryId then
            creatureToSell = entry
            creatureIndex = i
            break
        end
    end
    
    if not creatureToSell then
        return { success = false, reason = "Creature not in collection" }
    end
    
    -- Remove from collection (or decrement count)
    DataStoreManager:UpdateProfile(player, function(profile)
        if creatureToSell.Count and creatureToSell.Count > 1 then
            creatureToSell.Count -= 1
        else
            table.remove(profile.CreatureCollection, creatureIndex)
        end
    end)
    
    -- Award credits
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        local result = EconomyService:SellCreatureToEconomy(player, {
            Rarity = creatureToSell.Rarity,
            DisplayName = creatureToSell.DisplayName,
            IsShiny = creatureToSell.IsShiny or false,
            Weight = creatureToSell.Weight,
        })
        
        -- Mark DataStore dirty
        DataStoreManager:SetProfileDirty(player)
        
        return result
    end
    
    return { success = false, reason = "Economy system unavailable" }
end

return CreatureService