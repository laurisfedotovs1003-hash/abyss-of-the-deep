--[[
    ProfileTemplate — Player profile schema for ProfileService
    Follows the Types.lua schema definition with extended economy fields.
    This is the template that ProfileService uses to validate and structure player data.
]]

local ProfileTemplate = {}

-- ============================================================
-- Player Profile Schema (as defined in Types.lua)
-- ============================================================

--[[
    PlayerProfile = {
        UserId: number,
        DisplayName: string,
        
        -- Progression
        Experience: number,
        Level: number,
        Currency: number,            -- Mapped to Credits in dual-currency system
        ResearchPoints: number,        -- Extended: premium currency
        TotalDives: number,
        
        -- Equipment
        CurrentGearTier: number,
        OwnedGearTiers: {number},
        MaxDepthReached: number,
        
        -- Inventory & Boosts
        Inventory: { [string]: number },    -- Consumable item counts
        ActiveBoosts: { { effect: string, expiresAt: number } },
        
        -- Collection
        CreatureCollection: {CreatureEntry},
        CollectionSlots: number,
        DiscoveredZones: {number},            -- Zone indices discovered
        DiscoveredCreatureIds: {string},    -- Creature IDs discovered
        
        -- Base Building
        BaseModules: {BaseModule},
        BaseLocation: Vector3,
        
        -- Stats
        TotalCreaturesCollected: number,
        TotalCreaturesSold: number,
        TotalOxygenUsed: number,
        TotalDistanceTravelled: number,
        TotalPlayTime: number,
        TotalCreditsEarned: number,
        TotalResearchPointsEarned: number,
        
        -- Meta
        LastSaveTime: number,
        FirstJoinTime: number,
        TotalSessions: number,
        PremiumBenefits: boolean,
    }
]]

-- CreatureEntry schema (from Types.lua)
--[[
    CreatureEntry = {
        Id: string,
        DisplayName: string,
        Rarity: string,
        DepthLayer: number,
        Size: number,
        Weight: number,
        IsShiny: boolean,
        DateCollected: number,
        TimesViewed: number,
        Count: number,            -- Extended: how many of this species caught
        TotalWeight: number,    -- Extended: cumulative weight
    }
]]

-- BaseModule schema (from Types.lua)
--[[
    BaseModule = {
        Id: string,
        Type: "Habitat" | "Greenhouse" | "Lab" | "DefenseTurret" | "Decoration",
        Position: Vector3,
        Orientation: CFrame,
        Tier: number,
        Health: number,
        IsPowered: boolean,
        PlacedAt: number,
    }
]]

-- ============================================================
-- Default Profile Data
-- ============================================================

ProfileTemplate.Data = {
    -- Identification (set on load, not stored persistently in the same way)
    UserId = 0,
    DisplayName = "Explorer",
    
    -- ============================================================
    -- Progression
    -- ============================================================
    
    Experience = 0,
    Level = 1,
    
    -- Dual-currency economy (Currency = primary Credits)
    Currency = 50,                -- Primary currency (Credits) — matches Types.lua schema
    ResearchPoints = 0,            -- Premium currency
    
    TotalDives = 0,
    
    -- ============================================================
    -- Equipment & Gear
    -- ============================================================
    
    CurrentGearTier = 1,
    OwnedGearTiers = {1},
    MaxDepthReached = 0,
    
    -- ============================================================
    -- Inventory & Boosts
    -- ============================================================
    
    Inventory = {},
    -- { OxygenTank: number, RareBait: number, SpeedBoost: number, ... }
    
    ActiveBoosts = {},
    -- { { effect = "XPBooster", expiresAt = timestamp }, ... }
    
    -- ============================================================
    -- Collection
    -- ============================================================
    
    CreatureCollection = {},
    -- { CreatureEntry, CreatureEntry, ... }
    
    CollectionSlots = 50,
    
    DiscoveredZones = {},
    -- { 1, 2, 3, ... } — zone indices discovered
    
    DiscoveredCreatureIds = {},
    -- { "clownfish", "anglerfish", ... } — creature IDs discovered
    
    -- ============================================================
    -- Base Building
    -- ============================================================
    
    BaseModules = {},
    -- { BaseModule, BaseModule, ... }
    
    BaseLocation = Vector3.new(0, 0, 0),
    
    -- ============================================================
    -- Lifetime Stats
    -- ============================================================
    
    TotalCreaturesCollected = 0,
    TotalCreaturesSold = 0,
    TotalOxygenUsed = 0,
    TotalDistanceTravelled = 0,
    TotalPlayTime = 0,
    TotalCreditsEarned = 0,
    TotalResearchPointsEarned = 0,

            -- ============================================================
            -- Quest Tracking
            -- ============================================================

            ActiveQuests = {},
            -- { { questKey: string, questType: string ("Daily"|"Event"|"Milestone"|"Achievement"),
            --     progress: { conditionIndex: currentValue }, acceptedAt: number }, ... }

            CompletedQuests = {},
            -- { [questKey] = { completedAt: number, status: "completed", questType: string } }

            ClaimedQuests = {},
            -- { [questKey] = true }

            DailyQuestState = {
                RefreshDay = 0,                -- Date of last daily refresh (YYYYMMDD)
                AcceptedDailyKeys = {},        -- Up to MaxDailyQuests keys
                ReRollsUsed = 0,            -- Re-rolls used today
                LastReRollTime = 0,            -- os.time() of last re-roll
                CompletedToday = {},        -- { [questKey] = true }
            },

            -- ============================================================
            -- Tutorial Tracking
            -- ============================================================

            TutorialState = {
                Completed = false,            -- True after all 8 steps are done
                CurrentStep = 0,            -- 0 = not started, 1-8 = in progress, 9 = done
                StepCompleted = {},            -- { [1] = true, [2] = true, ... }
                FirstJoinTime = 0,            -- os.time() of first join
            },

            -- ============================================================
            -- Cosmetics & Titles (unlocked via quests/milestones)
            -- ============================================================

            UnlockedCosmetics = {},
            -- { "item1", "item2", ... } — cosmetic item keys

            EquippedTitle = "",            -- Current visible title above player name

            -- ============================================================
            -- Meta
            -- ============================================================

            LastSaveTime = 0,            -- Set on save
            FirstJoinTime = 0,            -- Set on first join
            TotalSessions = 0,
            PremiumBenefits = false,
        }

return ProfileTemplate