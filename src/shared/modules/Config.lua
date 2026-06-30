--[[
    Config.lua — Shared game configuration constants
    Used by both client and server via Knit shared module system.
]]

local Config = {}

-- ============================================================
-- Global Lighting & VFX Settings
-- ============================================================

Config.Lighting = {
    Bloom = {
        Intensity = 1,
        Size = 24,
        Threshold = 0.8
    },
    GlobalShadows = true,
    Technology = Enum.Technology.Future,
    LightShafts = {
        Count = 12,
        Size = Vector3.new(15, 600, 15),
        Transparency = 0.96,
        Color = Color3.fromRGB(59, 130, 246), -- Electric Blue
    }
}

-- ============================================================
-- Currency Definitions
-- ============================================================

Config.Currency = {
    Credits = {
        DisplayName = "Credits",
        Symbol = "₡",
        Description = "Standard currency earned from selling creatures and completing dives",
        StartingAmount = 50,
    },
    ResearchPoints = {
        DisplayName = "Research Points",
        Symbol = "◎",
        Description = "Premium currency earned from discoveries, achievements, and purchases",
        StartingAmount = 0,
        ConversionRate = 10, -- 1 RP = 10 Credits equivalent
    }
}

-- ============================================================
-- Depth Layer Definitions
-- ============================================================

Config.DepthLayers = {
    {
        Name = "Sunlight Zone",
        DepthMin = 0,
        DepthMax = 200,
        Color = Color3.fromRGB(59, 130, 246), -- Electric Blue
        AmbientLight = 0.8,
        FogStart = 10,
        FogEnd = 600,
        Brightness = 2,
        OutdoorAmbient = Color3.fromRGB(59, 130, 246),
        OxygenDrainRate = 1,
        PressureMultiplier = 1,
        CreatureRarityPool = {"Common"},
        Description = "Warm, bright waters teeming with colorful reef fish",
        ResearchPointsPerEntry = 1,
        ColorCorrection = {
            Brightness = 0,
            Contrast = 0.1,
            Saturation = 0.2,
            TintColor = Color3.fromRGB(255, 255, 255)
        }
    },
    {
        Name = "Twilight Zone",
        DepthMin = 200,
        DepthMax = 1000,
        Color = Color3.fromRGB(6, 10, 26), -- Deep Ocean
        AmbientLight = 0.2,
        FogStart = 0,
        FogEnd = 350,
        Brightness = 1,
        OutdoorAmbient = Color3.fromRGB(6, 10, 26),
        OxygenDrainRate = 1.5,
        PressureMultiplier = 2,
        CreatureRarityPool = {"Common", "Uncommon"},
        Description = "Fading light, strange shapes begin to emerge from the dark",
        ResearchPointsPerEntry = 2,
        ColorCorrection = {
            Brightness = -0.1,
            Contrast = 0.2,
            Saturation = -0.1,
            TintColor = Color3.fromRGB(200, 220, 255)
        }
    },
    {
        Name = "Midnight Zone",
        DepthMin = 1000,
        DepthMax = 4000,
        Color = Color3.fromRGB(4, 6, 16),
        AmbientLight = 0.05,
        FogStart = 0,
        FogEnd = 150,
        Brightness = 0.5,
        OutdoorAmbient = Color3.fromRGB(4, 6, 16),
        OxygenDrainRate = 2.5,
        PressureMultiplier = 4,
        CreatureRarityPool = {"Uncommon", "Rare"},
        Description = "Total darkness — bioluminescence is the only light",
        ResearchPointsPerEntry = 5,
        ColorCorrection = {
            Brightness = -0.2,
            Contrast = 0.4,
            Saturation = -0.3,
            TintColor = Color3.fromRGB(150, 180, 255)
        }
    },
    {
        Name = "Abyssal Zone",
        DepthMin = 4000,
        DepthMax = 6000,
        Color = Color3.fromRGB(2, 3, 8),
        AmbientLight = 0.01,
        FogStart = 0,
        FogEnd = 80,
        Brightness = 0.2,
        OutdoorAmbient = Color3.fromRGB(2, 3, 8),
        OxygenDrainRate = 4,
        PressureMultiplier = 8,
        CreatureRarityPool = {"Rare", "Epic"},
        Description = "The abyss — ancient creatures dwell in the crushing dark",
        ResearchPointsPerEntry = 10,
        ColorCorrection = {
            Brightness = -0.3,
            Contrast = 0.6,
            Saturation = -0.5,
            TintColor = Color3.fromRGB(100, 130, 255)
        }
    },
    {
        Name = "Trenches",
        DepthMin = 6000,
        DepthMax = 11000,
        Color = Color3.fromRGB(0, 0, 0),
        AmbientLight = 0,
        FogStart = 0,
        FogEnd = 40,
        Brightness = 0,
        OutdoorAmbient = Color3.fromRGB(0, 0, 0),
        OxygenDrainRate = 6,
        PressureMultiplier = 15,
        CreatureRarityPool = {"Epic", "Legendary"},
        Description = "The deepest places on Earth — few have ever returned",
        ResearchPointsPerEntry = 20,
        ColorCorrection = {
            Brightness = -0.5,
            Contrast = 0.8,
            Saturation = -0.8,
            TintColor = Color3.fromRGB(80, 100, 255)
        }
    }
}

-- ============================================================
-- Player Settings
-- ============================================================

Config.Player = {
    MaxOxygen = 100,
    BaseSwimSpeed = 16,
    SprintMultiplier = 1.6,
    OxygenRefillRate = 15,
    OxygenCriticalThreshold = 20,
    BaseHealth = 100,
    PressureDamageInterval = 3,
    PressureDamagePerLevel = 5,
}

-- ============================================================
-- Diving Gear Tiers
-- ============================================================

Config.DivingGear = {
    {
        Name = "Basic Gear",
        Tier = 1,
        MaxDepth = 200,
        OxygenBonus = 0,
        SpeedModifier = 1,
        Price = 0,
        PriceCurrency = "Credits",
        Description = "Standard snorkeling equipment — surface only"
    },
    {
        Name = "Scuba Kit",
        Tier = 2,
        MaxDepth = 1000,
        OxygenBonus = 50,
        SpeedModifier = 1.1,
        Price = 150,
        PriceCurrency = "Credits",
        Description = "Tank and regulator — reach the Twilight Zone"
    },
    {
        Name = "Advanced Dive Suit",
        Tier = 3,
        MaxDepth = 4000,
        OxygenBonus = 125,
        SpeedModifier = 1.2,
        Price = 400,
        PriceCurrency = "Credits",
        Description = "Pressure-resistant suit with enhanced mobility"
    },
    {
        Name = "Bathysphere",
        Tier = 4,
        MaxDepth = 6000,
        OxygenBonus = 250,
        SpeedModifier = 0.9,
        Price = 1000,
        PriceCurrency = "Credits",
        Description = "Heavy submersible — protects against extreme pressure"
    },
    {
        Name = "Abyssal Exosuit",
        Tier = 5,
        MaxDepth = 11000,
        OxygenBonus = 500,
        SpeedModifier = 1.4,
        Price = 3000,
        PriceCurrency = "Credits",
        Description = "Cutting-edge exploration suit — nothing is out of reach"
    }
}

-- ============================================================
-- Creature Rarity Configuration
-- ============================================================

Config.CreatureRarity = {
    Common = {
        Weight = 50,
        Color = Color3.fromRGB(180, 180, 180),
        XPMultiplier = 1,
        SellPriceMin = 5,
        SellPriceMax = 15,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 1,
    },
    Uncommon = {
        Weight = 30,
        Color = Color3.fromRGB(30, 200, 80),
        XPMultiplier = 2,
        SellPriceMin = 20,
        SellPriceMax = 50,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 3,
    },
    Rare = {
        Weight = 15,
        Color = Color3.fromRGB(30, 144, 255),
        XPMultiplier = 4,
        SellPriceMin = 60,
        SellPriceMax = 200,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 10,
    },
    Epic = {
        Weight = 4,
        Color = Color3.fromRGB(180, 0, 255),
        XPMultiplier = 8,
        SellPriceMin = 250,
        SellPriceMax = 800,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 25,
    },
    Legendary = {
        Weight = 1,
        Color = Color3.fromRGB(255, 180, 0),
        XPMultiplier = 16,
        SellPriceMin = 1000,
        SellPriceMax = 5000,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 50,
    }
}

-- ============================================================
-- Economy & Progression
-- ============================================================

Config.Economy = {
    StartingCurrency = 50,
    MaxCollectionSlots = 200,
    XPPerDepthMeter = 0.5,
    XPPerCreatureCaptured = 25,
    CreditsPerDepthMeter = 0.2,
    CreditsPerDiveComplete = 25,
    ResearchPointsPerLevel = 5,
    BaseBuildingCosts = {
                -- Simplified: 2 module types per lead instructions
                Habitat = {Credits = 100, Scrap = 30, Crystal = 10},
                Lab = {Credits = 150, Scrap = 50, Crystal = 20},
                -- Upgrade costs: T2 = 1.5x base, T3 = 3x base
                UpgradeMultiplier = {[2] = 1.5, [3] = 3},
                MaxModules = 10,
                MaxTier = 3,
        },
}

-- ============================================================
-- Resource Definitions (for base building)
-- ============================================================

Config.Resources = {
    Scrap = {
        DisplayName = "Scrap Metal",
        Description = "Recycled metal from ocean debris and broken equipment",
        StartingAmount = 0,
        MaxStack = 999,
        PerDepthMeter = 0.05,      -- ~10 Scrap per 200m dive
        RarityWeights = { Common = 60, Uncommon = 30, Rare = 10 },
    },
    Crystal = {
        DisplayName = "Bioluminescent Crystal",
        Description = "Rare crystals found in deep-sea mineral deposits",
        StartingAmount = 0,
        MaxStack = 999,
        PerDepthMeter = 0.01,      -- ~2 Crystal per 200m dive (rarer)
        RarityWeights = { Common = 40, Uncommon = 35, Rare = 20, Epic = 5 },
    },
    ResourceNodeHarvest = {
        Scrap = { min = 3, max = 8 },
        Crystal = { min = 1, max = 3 },
    },
}

-- ============================================================
-- Depth Milestone Bonuses (one-time rewards for reaching new depths)
-- ============================================================

Config.DepthMilestones = {
    { depth = 200,  credits = 50,  rpReward = 1,  title = "Surface Scratcher" },
    { depth = 1000, credits = 200, rpReward = 3,  title = "Twilight Traveler" },
    { depth = 4000, credits = 500, rpReward = 5,  title = "Midnight Marauder" },
    { depth = 6000, credits = 1000, rpReward = 10, title = "Abyss Walker" },
    { depth = 11000, credits = 2000, rpReward = 25, title = "Trench Dweller" },
}

-- ============================================================
-- Dive Completion Bonuses (scaled by max depth reached)
-- ============================================================

Config.DiveBonuses = {
    { minDepth = 0,    maxDepth = 200,   bonus = 15,  label = "Shallow Dive" },
    { minDepth = 200,  maxDepth = 1000,  bonus = 40,  label = "Twilight Expedition" },
    { minDepth = 1000, maxDepth = 4000,  bonus = 100, label = "Midnight Descent" },
    { minDepth = 4000, maxDepth = 6000,  bonus = 250, label = "Abyssal Voyage" },
    { minDepth = 6000, maxDepth = 11000, bonus = 500, label = "Trench Exploration" },
}

-- ============================================================
-- Daily Reward System (D1/D7 retention driver)
-- ============================================================

Config.DailyRewards = {
    Enabled = true,
    StreakLength = 7,
    ResetOnMiss = false,  -- Streak protection
    Rewards = {
        { day = 1, type = "Credits",    amount = 25 },
        { day = 2, type = "Consumable", item = "OxygenTank",       count = 1 },
        { day = 3, type = "Credits",    amount = 50 },
        { day = 4, type = "Consumable", item = "PropulsionBoost",  count = 1 },
        { day = 5, type = "Credits",    amount = 75 },
        { day = 6, type = "Consumable", item = "RareBait",         count = 1 },
        { day = 7, type = "ResearchPoints", amount = 5 },
    },
}

-- ============================================================
-- Level Milestone Titles (engagement driver)
-- ============================================================

Config.LevelMilestones = {
    { level = 5,  title = "Diver" },
    { level = 10, title = "Explorer" },
    { level = 15, title = "Deep Explorer" },
    { level = 20, title = "Abyssal Lord" },
    { level = 25, title = "Ocean Master" },
    { level = 50, title = "Leviathan Slayer" },
}

-- ============================================================
-- Shop Definitions
-- ============================================================

Config.ShopItems = {
    -- Consumables (priced for impulse buying)
    OxygenTank = {
        Name = "Emergency Oxygen Tank",
        Description = "Refills 50% of your oxygen instantly",
        Category = "Consumable",
        Price = 10,
        PriceCurrency = "Credits",
        Effect = "RefillOxygen",
        EffectValue = 0.5,
        MaxStack = 10,
    },
    RareBait = {
        Name = "Rare Lure",
        Description = "Attracts rare creatures for 60 seconds",
        Category = "Consumable",
        Price = 20,
        PriceCurrency = "Credits",
        Effect = "RareLure",
        EffectValue = 60,
        MaxStack = 5,
    },
    SpeedBoost = {
        Name = "Propulsion Boost",
        Description = "+40% swim speed for 30 seconds",
        Category = "Consumable",
        Price = 15,
        PriceCurrency = "Credits",
        Effect = "SpeedBoost",
        EffectValue = 30,
        MaxStack = 5,
    },
    
    -- Gear (referenced by Config.DivingGear, shown in shop)
    -- Base building modules
    Decoration_PottedPlant = {
        Name = "Potted Seaweed",
        Description = "A decorative plant for your base",
        Category = "Decoration",
        Price = 15,
        PriceCurrency = "Credits",
        ModuleType = "Decoration",
    },
    Decoration_Biolight = {
        Name = "Bioluminescent Light",
        Description = "Glowing light fixture for your base",
        Category = "Decoration",
        Price = 40,
        PriceCurrency = "Credits",
        ModuleType = "Decoration",
    },
    
    -- Bundle items (discounted multi-packs)
    DiveBundle = {
        Name = "Diver's Bundle (5-pack)",
        Description = "5 Oxygen Tanks + 2 Rare Lures at a discount",
        Category = "Bundle",
        Price = 60,
        PriceCurrency = "Credits",
        Contains = { OxygenTank = 5, RareLure = 2 },
    },
    
    -- Research Point shop (premium currency — aspirational purchases)
    Research_XPBooster = {
        Name = "XP Booster",
        Description = "Double XP for 1 hour",
        Category = "Research",
        Price = 15,
        PriceCurrency = "ResearchPoints",
        Effect = "XPBooster",
        EffectValue = 3600,
    },
    Research_LuckyCharm = {
        Name = "Lucky Charm",
        Description = "+25% catch rate for 30 minutes",
        Category = "Research",
        Price = 10,
        PriceCurrency = "ResearchPoints",
        Effect = "CatchBoost",
        EffectValue = 1800,
    },
    
    -- RP-exclusive permanent items (aspirational purchases)
    AbyssalBeacon = {
        Name = "Abyssal Beacon",
        Description = "Teleports you to your deepest reached depth on next dive",
        Category = "PermanentUpgrade",
        Price = 50,
        PriceCurrency = "ResearchPoints",
        Effect = "UnlockTeleport",
        Exclusive = true,
    },
    BioluminescenceAura = {
        Name = "Bioluminescent Aura",
        Description = "Permanent glowing effect on your diving suit",
        Category = "Cosmetic",
        Price = 30,
        PriceCurrency = "ResearchPoints",
        Effect = "CosmeticAura",
        Exclusive = true,
    },
    DeepLungsUpgrade = {
        Name = "Deep Lungs Upgrade",
        Description = "Permanently +25 base oxygen capacity",
        Category = "PermanentUpgrade",
        Price = 40,
        PriceCurrency = "ResearchPoints",
        Effect = "PermaOxygen",
        Exclusive = true,
    },
    VoidJellyfish = {
        Name = "Void Jellyfish Egg",
        Description = "Hatch an exclusive Trenches-born pet that follows you",
        Category = "Companion",
        Price = 75,
        PriceCurrency = "ResearchPoints",
        Effect = "CompanionPet",
        Exclusive = true,
    },
}

-- ============================================================
-- Game Pass IDs (set these after publishing)
-- ============================================================

Config.GamePasses = {
    OxygenBooster = 0,            -- +100 base oxygen capacity
    SpeedDiver = 0,                -- +20% swim speed
    ExpandedCollection = 0,        -- Double collection slots
    AbyssalPass = 0,               -- Access to exclusive trench content
    ResearchPointsPack = 0,        -- Bonus Research Points
    VIPStatus = 0,                 -- +25% Credits, +15% XP, +5 max O₂, VIP title
}

-- ============================================================
-- Depth Pass (Seasonal Battle Pass) — aligned with RIVALS model
-- ============================================================

Config.DepthPass = {
    Enabled = true,
    SeasonDuration = 604800 * 4,  -- 4 weeks
    PriceRobux = 399,
    FreeTier = {
        { level = 1,  type = "Credits",       amount = 50 },
        { level = 5,  type = "Consumable",    item = "OxygenTank", count = 2 },
        { level = 10, type = "Title",         title = "Season 1 Diver" },
        { level = 15, type = "Credits",       amount = 200 },
        { level = 20, type = "ResearchPoints",amount = 10 },
        { level = 25, type = "Consumable",    item = "RareBait",   count = 3 },
    },
    PremiumTier = {
        { level = 1,  type = "Cosmetic",      item = "Season 1 Suit Skin" },
        { level = 5,  type = "Consumable",    item = "RareLure",   count = 5 },
        { level = 10, type = "Cosmetic",      item = "Season 1 Sub Skin" },
        { level = 15, type = "ResearchPoints", amount = 25 },
        { level = 20, type = "Cosmetic",      item = "Season 1 Base Deco Set" },
        { level = 25, type = "Creature",      item = "Season 1 Exclusive Creature" },
    },
}

-- ============================================================
-- Developer Product IDs (set these after publishing)
-- ============================================================

Config.DeveloperProducts = {
    Credits_500 = 0,
    Credits_2000 = 0,
    Credits_10000 = 0,
    ResearchPoints_10 = 0,
    ResearchPoints_50 = 0,
    ResearchPoints_250 = 0,
    StarterPack = 0,
}

-- ============================================================
-- Analytics Tags
-- ============================================================

Config.Analytics = {
    Enabled = true,
    SessionTimeout = 300,
    EventPrefix = "Abyss_",
}

-- ============================================================
-- Anomaly / Echo Event Definitions
-- ============================================================

-- Each anomaly is a timed global event that modifies environment, creature rarity, and rewards.
-- Only one anomaly can be active at a time. They trigger randomly while players are diving.

Config.AnomalyEvents = {
    CorruptedDepths = {
        DisplayName = "Corrupted Depths",
        Description = "A dark corruption spreads through the water... creatures are more aggressive!",
        Weight = 30,
        DurationMin = 60,
        DurationMax = 120,
        CooldownAfter = 180,
        Priority = 1,
        Lighting = {
            FogColor = Color3.fromRGB(80, 10, 10),
            AmbientLight = 0.15,
            FogStart = 0,
            FogEnd = 80,
            Brightness = 0.4,
            TintColor = Color3.fromRGB(200, 50, 50),
            Saturation = 0.2,
            Contrast = 0.6,
        },
        Modifiers = {
            CreatureRarityWeightMultiplier = { Common = 0.5, Uncommon = 1.0, Rare = 1.5, Epic = 2.0, Legendary = 3.0 },
            CatchChanceMultiplier = 0.7,
            XPMultiplier = 1.5,
            CreditMultiplier = 1.5,
            SpawnRateMultiplier = 1.5,
        },
    },
    EnchantedWaters = {
        DisplayName = "Enchanted Waters",
        Description = "Golden energy ripples through the depths... rare creatures emerge!",
        Weight = 25,
        DurationMin = 90,
        DurationMax = 150,
        CooldownAfter = 240,
        Priority = 2,
        Lighting = {
            FogColor = Color3.fromRGB(255, 215, 100),
            AmbientLight = 0.5,
            FogStart = 5,
            FogEnd = 200,
            Brightness = 1.2,
            TintColor = Color3.fromRGB(255, 230, 150),
            Saturation = 0.3,
            Contrast = 0.2,
        },
        Modifiers = {
            CreatureRarityWeightMultiplier = { Common = 0.3, Uncommon = 0.8, Rare = 2.0, Epic = 2.5, Legendary = 4.0 },
            CatchChanceMultiplier = 1.2,
            XPMultiplier = 2.0,
            CreditMultiplier = 2.0,
            SpawnRateMultiplier = 1.3,
        },
    },
    BioluminescentBloom = {
        DisplayName = "Bioluminescent Bloom",
        Description = "The sea lights up with neon colors — every creature glows!",
        Weight = 25,
        DurationMin = 75,
        DurationMax = 120,
        CooldownAfter = 200,
        Priority = 3,
        Lighting = {
            FogColor = Color3.fromRGB(100, 0, 150),
            AmbientLight = 0.6,
            FogStart = 2,
            FogEnd = 150,
            Brightness = 1.5,
            TintColor = Color3.fromRGB(200, 100, 255),
            Saturation = 0.6,
            Contrast = 0.1,
        },
        Modifiers = {
            CreatureRarityWeightMultiplier = { Common = 2.0, Uncommon = 1.5, Rare = 1.0, Epic = 0.5, Legendary = 0.3 },
            CatchChanceMultiplier = 1.5,
            XPMultiplier = 1.0,
            CreditMultiplier = 0.8,
            SpawnRateMultiplier = 2.0,
        },
    },
    AbyssalSurge = {
        DisplayName = "Abyssal Surge",
        Description = "A powerful current sweeps through — hold on tight!",
        Weight = 15,
        DurationMin = 45,
        DurationMax = 90,
        CooldownAfter = 300,
        Priority = 4,
        Lighting = {
            FogColor = Color3.fromRGB(5, 5, 30),
            AmbientLight = 0.03,
            FogStart = 0,
            FogEnd = 50,
            Brightness = 0.15,
            TintColor = Color3.fromRGB(30, 60, 150),
            Saturation = -0.2,
            Contrast = 0.7,
        },
        Modifiers = {
            CreatureRarityWeightMultiplier = { Common = 0.8, Uncommon = 1.0, Rare = 1.2, Epic = 1.5, Legendary = 1.0 },
            CatchChanceMultiplier = 0.5,
            XPMultiplier = 3.0,
            CreditMultiplier = 2.0,
            SpawnRateMultiplier = 0.6,
        },
    },
    AncientMigration = {
        DisplayName = "Ancient Migration",
        Description = "Deep-sea leviathans rise from the abyss... legendary sightings!",
        Weight = 5,
        DurationMin = 120,
        DurationMax = 180,
        CooldownAfter = 600,
        Priority = 5,
        Lighting = {
            FogColor = Color3.fromRGB(0, 200, 255),
            AmbientLight = 0.3,
            FogStart = 0,
            FogEnd = 300,
            Brightness = 0.8,
            TintColor = Color3.fromRGB(0, 180, 255),
            Saturation = 0.4,
            Contrast = 0.3,
        },
        Modifiers = {
            CreatureRarityWeightMultiplier = { Common = 0.1, Uncommon = 0.3, Rare = 0.5, Epic = 3.0, Legendary = 8.0 },
            CatchChanceMultiplier = 0.3,
            XPMultiplier = 4.0,
            CreditMultiplier = 4.0,
            SpawnRateMultiplier = 0.8,
        },
    },
}

return Config
