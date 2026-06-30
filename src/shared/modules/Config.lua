--[[
    Config.lua — Shared game configuration constants
    Used by both client and server via Knit shared module system.
]]

local Config = {}

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
        Color = Color3.fromRGB(30, 144, 255),
        AmbientLight = 0.8,
        OxygenDrainRate = 1,
        PressureMultiplier = 1,
        CreatureRarityPool = {"Common"},
        Description = "Warm, bright waters teeming with colorful reef fish",
        ResearchPointsPerEntry = 1, -- RP awarded for first time entering this zone
    },
    {
        Name = "Twilight Zone",
        DepthMin = 200,
        DepthMax = 1000,
        Color = Color3.fromRGB(25, 25, 112),
        AmbientLight = 0.3,
        OxygenDrainRate = 1.5,
        PressureMultiplier = 2,
        CreatureRarityPool = {"Common", "Uncommon"},
        Description = "Fading light, strange shapes begin to emerge from the dark",
        ResearchPointsPerEntry = 2,
    },
    {
        Name = "Midnight Zone",
        DepthMin = 1000,
        DepthMax = 4000,
        Color = Color3.fromRGB(8, 8, 40),
        AmbientLight = 0.05,
        OxygenDrainRate = 2.5,
        PressureMultiplier = 4,
        CreatureRarityPool = {"Uncommon", "Rare"},
        Description = "Total darkness — bioluminescence is the only light",
        ResearchPointsPerEntry = 5,
    },
    {
        Name = "Abyssal Zone",
        DepthMin = 4000,
        DepthMax = 6000,
        Color = Color3.fromRGB(2, 2, 20),
        AmbientLight = 0.01,
        OxygenDrainRate = 4,
        PressureMultiplier = 8,
        CreatureRarityPool = {"Rare", "Epic"},
        Description = "The abyss — ancient creatures dwell in the crushing dark",
        ResearchPointsPerEntry = 10,
    },
    {
        Name = "Trenches",
        DepthMin = 6000,
        DepthMax = 11000,
        Color = Color3.fromRGB(0, 0, 0),
        AmbientLight = 0,
        OxygenDrainRate = 6,
        PressureMultiplier = 15,
        CreatureRarityPool = {"Epic", "Legendary"},
        Description = "The deepest places on Earth — few have ever returned",
        ResearchPointsPerEntry = 20,
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
        Price = 500,
        PriceCurrency = "Credits",
        Description = "Pressure-resistant suit with enhanced mobility"
    },
    {
        Name = "Bathysphere",
        Tier = 4,
        MaxDepth = 6000,
        OxygenBonus = 250,
        SpeedModifier = 0.9,
        Price = 1500,
        PriceCurrency = "Credits",
        Description = "Heavy submersible — protects against extreme pressure"
    },
    {
        Name = "Abyssal Exosuit",
        Tier = 5,
        MaxDepth = 11000,
        OxygenBonus = 500,
        SpeedModifier = 1.4,
        Price = 5000,
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
    StartingCurrency = 50,        -- Starting Credits (maps to Types.lua Currency field)
    StartingResearchPoints = 0,
    MaxCollectionSlots = 200,
    XPPerDepthMeter = 0.5,
    XPPerCreatureCaptured = 25,
    CreditsPerDepthMeter = 0.1,
    CreditsPerDiveComplete = 10,
    ResearchPointsPerLevel = 5,
    BaseBuildingCosts = {
        -- Simplified: 2 module types per lead instructions
        Habitat = {Credits = 100},
        Lab = {Credits = 150,},
        -- Upgrade costs scale: Tier 2 = 1.5x base, Tier 3 = 3x base
        UpgradeMultiplier = {[2] = 1.5, [3] = 3},
        MaxModules = 10,
        MaxTier = 3,
    },
}

-- ============================================================
-- Shop Definitions
-- ============================================================

Config.ShopItems = {
    -- Consumables
    OxygenTank = {
        Name = "Emergency Oxygen Tank",
        Description = "Refills 50% of your oxygen instantly",
        Category = "Consumable",
        Price = 25,
        PriceCurrency = "Credits",
        Effect = "RefillOxygen",
        EffectValue = 0.5,
        MaxStack = 10,
    },
    RareBait = {
        Name = "Rare Lure",
        Description = "Attracts rare creatures for 60 seconds",
        Category = "Consumable",
        Price = 50,
        PriceCurrency = "Credits",
        Effect = "RareLure",
        EffectValue = 60,
        MaxStack = 5,
    },
    SpeedBoost = {
        Name = "Propulsion Boost",
        Description = "+40% swim speed for 30 seconds",
        Category = "Consumable",
        Price = 30,
        PriceCurrency = "Credits",
        Effect = "SpeedBoost",
        EffectValue = 30,
        MaxStack = 5,
    },
    
    -- Gear (referenced by Config.DivingGear, shown in shop)
    
    -- Research Point shop (premium)
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
}

-- ============================================================
-- Game Pass IDs (set these after publishing)
-- ============================================================

Config.GamePasses = {
    OxygenBooster = 0,            -- +100 base oxygen capacity
    SpeedDiver = 0,                -- +20% swim speed
    ExpandedCollection = 0,        -- Double collection slots
    AbyssalPass = 0,            -- Access to exclusive trench content
    ResearchPointsPack = 0,        -- Bonus Research Points
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

return Config