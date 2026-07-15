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
        Price = 400, -- Balanced down from 500
        PriceCurrency = "Credits",
        Description = "Pressure-resistant suit with enhanced mobility"
    },
    {
        Name = "Bathysphere",
        Tier = 4,
        MaxDepth = 6000,
        OxygenBonus = 250,
        SpeedModifier = 0.9,
        Price = 1000, -- Balanced down from 1500
        PriceCurrency = "Credits",
        Description = "Heavy submersible — protects against extreme pressure"
    },
    {
        Name = "Abyssal Exosuit",
        Tier = 5,
        MaxDepth = 11000,
        OxygenBonus = 500,
        SpeedModifier = 1.4,
        Price = 3000, -- Balanced down from 5000
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
        CatchChance = 0.8,
    },
    Uncommon = {
        Weight = 30,
        Color = Color3.fromRGB(30, 200, 80),
        XPMultiplier = 2,
        SellPriceMin = 20,
        SellPriceMax = 50,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 3,
        CatchChance = 0.6,
    },
    Rare = {
        Weight = 15,
        Color = Color3.fromRGB(30, 144, 255),
        XPMultiplier = 4,
        SellPriceMin = 60,
        SellPriceMax = 200,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 10,
        CatchChance = 0.4,
    },
    Epic = {
        Weight = 4,
        Color = Color3.fromRGB(180, 0, 255),
        XPMultiplier = 8,
        SellPriceMin = 250,
        SellPriceMax = 800,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 25,
        CatchChance = 0.2,
    },
    Legendary = {
        Weight = 1,
        Color = Color3.fromRGB(255, 180, 0),
        XPMultiplier = 16,
        SellPriceMin = 1000,
        SellPriceMax = 5000,
        SellPriceCurrency = "Credits",
        ResearchPointsOnFirstDiscovery = 50,
        CatchChance = 0.05,
    }
}

-- ============================================================
-- Creature Data (25+ unique creatures)
-- ============================================================

Config.Creatures = {
    -- Sunlight Zone (0-200m)
    {
        Name = "Clownfish",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Description = "Small orange fish with iconic white stripes. Often hides in anemones.",
        ModelAssetId = 0,
    },
    {
        Name = "Blue Tang",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Description = "Vibrant blue body with a yellow tail. A favorite for reef watchers.",
        ModelAssetId = 0,
    },
    {
        Name = "Parrotfish",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Description = "Colorful fish with beak-like teeth used to scrape algae off coral.",
        ModelAssetId = 0,
    },
    {
        Name = "Sea Turtle",
        Rarity = "Uncommon",
        Zone = "Sunlight Zone",
        Description = "A gentle green turtle that glides gracefully through the shallow reefs.",
        ModelAssetId = 0,
    },
    {
        Name = "Reef Shark",
        Rarity = "Rare",
        Zone = "Sunlight Zone",
        Description = "A sleek predator of the shallows. Generally cautious but powerful.",
        ModelAssetId = 0,
    },
    {
        Name = "Golden Manta Ray",
        Rarity = "Legendary",
        Zone = "Sunlight Zone",
        Description = "A majestic, shimmering ray that only appears when the sun hits the water just right.",
        ModelAssetId = 0,
    },

    -- Twilight Zone (200-1000m)
    {
        Name = "Hatchetfish",
        Rarity = "Common",
        Zone = "Twilight Zone",
        Description = "Paper-thin fish with giant, upward-facing eyes to spot prey above.",
        ModelAssetId = 0,
    },
    {
        Name = "Lanternfish",
        Rarity = "Common",
        Zone = "Twilight Zone",
        Description = "Small fish with photophores along its body that blink in the dark.",
        ModelAssetId = 0,
    },
    {
        Name = "Barracuda",
        Rarity = "Uncommon",
        Zone = "Twilight Zone",
        Description = "A fast, silver predator with razor-sharp teeth. Known for its ambush attacks.",
        ModelAssetId = 0,
    },
    {
        Name = "Oarfish",
        Rarity = "Rare",
        Zone = "Twilight Zone",
        Description = "An incredibly long, ribbon-like silver fish. Often mistaken for sea serpents.",
        ModelAssetId = 0,
    },
    {
        Name = "Giant Squid",
        Rarity = "Epic",
        Zone = "Twilight Zone",
        Description = "A massive cephalopod with eyes the size of dinner plates. Rarely seen alive.",
        ModelAssetId = 0,
    },
    {
        Name = "The Silver Serpent",
        Rarity = "Legendary",
        Zone = "Twilight Zone",
        Description = "A legendary eel-like creature that leaves a trail of glowing bubbles.",
        ModelAssetId = 0,
    },

    -- Midnight Zone (1000-4000m)
    {
        Name = "Anglerfish",
        Rarity = "Common",
        Zone = "Midnight Zone",
        Description = "A nightmare of the deep with a glowing lure to attract unsuspecting prey.",
        ModelAssetId = 0,
    },
    {
        Name = "Gulper Eel",
        Rarity = "Common",
        Zone = "Midnight Zone",
        Description = "Has a massive, hinged jaw that can swallow prey much larger than itself.",
        ModelAssetId = 0,
    },
    {
        Name = "Vampire Squid",
        Rarity = "Uncommon",
        Zone = "Midnight Zone",
        Description = "A deep-red cephalopod with webbed arms that look like a cape.",
        ModelAssetId = 0,
    },
    {
        Name = "Blobfish",
        Rarity = "Rare",
        Zone = "Midnight Zone",
        Description = "A gelatinous mass that looks grumpy in the low-pressure surface world.",
        ModelAssetId = 0,
    },
    {
        Name = "Colossal Squid",
        Rarity = "Epic",
        Zone = "Midnight Zone",
        Description = "The heaviest squid ever found, featuring rotating hooks on its tentacles.",
        ModelAssetId = 0,
    },
    {
        Name = "Abyssal Kraken",
        Rarity = "Legendary",
        Zone = "Midnight Zone",
        Description = "A creature of myth, its presence is felt long before its glowing eyes emerge from the dark.",
        ModelAssetId = 0,
    },

    -- Abyssal Zone (4000-6000m)
    {
        Name = "Fangtooth",
        Rarity = "Common",
        Zone = "Abyssal Zone",
        Description = "Small but terrifying fish with teeth so long it can't fully close its mouth.",
        ModelAssetId = 0,
    },
    {
        Name = "Dumbo Octopus",
        Rarity = "Uncommon",
        Zone = "Abyssal Zone",
        Description = "A cute octopus with ear-like fins used to 'fly' through the water.",
        ModelAssetId = 0,
    },
    {
        Name = "Tripod Fish",
        Rarity = "Uncommon",
        Zone = "Abyssal Zone",
        Description = "Stands on the sea floor using three extremely long fins like stilts.",
        ModelAssetId = 0,
    },
    {
        Name = "Ghost Shark",
        Rarity = "Rare",
        Zone = "Abyssal Zone",
        Description = "A pale, cartilaginous fish with stitching-like patterns on its skin.",
        ModelAssetId = 0,
    },
    {
        Name = "Abyssal Dragonfish",
        Rarity = "Epic",
        Zone = "Abyssal Zone",
        Description = "A black, serpent-like fish with a long, glowing barbel attached to its chin.",
        ModelAssetId = 0,
    },
    {
        Name = "Living Fossil",
        Rarity = "Legendary",
        Zone = "Abyssal Zone",
        Description = "A creature thought to be extinct for millions of years, perfectly preserved in the cold dark.",
        ModelAssetId = 0,
    },

    -- Trenches (6000-11000m)
    {
        Name = "Snailfish",
        Rarity = "Common",
        Zone = "Trenches",
        Description = "Translucent and delicate-looking, yet able to withstand crushing pressure.",
        ModelAssetId = 0,
    },
    {
        Name = "Deep-Sea Jellyfish",
        Rarity = "Uncommon",
        Zone = "Trenches",
        Description = "A massive, dark red jelly that pulses with eerie internal lights.",
        ModelAssetId = 0,
    },
    {
        Name = "Xenophyophore",
        Rarity = "Rare",
        Zone = "Trenches",
        Description = "A giant single-celled organism that looks like a structured sponge.",
        ModelAssetId = 0,
    },
    {
        Name = "Trench Leviathan",
        Rarity = "Epic",
        Zone = "Trenches",
        Description = "An ancient, armored serpent that circles the deepest rifts of the world.",
        ModelAssetId = 0,
    },
    {
        Name = "The Void Soul",
        Rarity = "Legendary",
        Zone = "Trenches",
        Description = "A ghostly, translucent entity that seems to be made of pure bioluminescence.",
        ModelAssetId = 0,
    },
}

-- ============================================================
-- Economy & Progression
-- ============================================================

Config.Economy = {
    StartingCurrency = 50,
    MaxCollectionSlots = 200,
    XPPerDepthMeter = 0.5,
    XPPerCreatureCaptured = 25,
    CreditsPerDepthMeter = 0.2, -- Balanced up from 0.1
    CreditsPerDiveComplete = 25, -- Balanced up from 10
    XPScalingPerLevel = 0.02,   -- +2% XP per level (Level 50 = 2x XP, makes endgame achievable)
    ResearchPointsPerLevel = function(level) -- Scaling RP reward
        return 5 + math.floor(level / 5)
    end,
    BaseBuildingCosts = {
                 Habitat = {Credits = 100, Scrap = 30, Crystal = 10},
                 Lab = {Credits = 150, Scrap = 50, Crystal = 20},
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
        Price = 10, -- Balanced down from 25
        PriceCurrency = "Credits",
        Effect = "RefillOxygen",
        EffectValue = 0.5,
        MaxStack = 10,
    },
    RareBait = {
        Name = "Rare Lure",
        Description = "Attracts rare creatures for 60 seconds",
        Category = "Consumable",
        Price = 20, -- Balanced down from 50
        PriceCurrency = "Credits",
        Effect = "RareLure",
        EffectValue = 60,
        MaxStack = 5,
    },
    SpeedBoost = {
        Name = "Propulsion Boost",
        Description = "+40% swim speed for 30 seconds",
        Category = "Consumable",
        Price = 15, -- Balanced down from 30
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
    
    -- Anomaly consumables
    EmergencyBeacon = {
        Name = "Emergency Beacon",
        Description = "Teleports you to the surface instantly during an anomaly",
        Category = "Consumable",
        Price = 25,
        PriceCurrency = "Credits",
        Effect = "EmergencyTeleport",
        MaxStack = 3,
    },
    AnomalyBait = {
        Name = "Anomaly Lure",
        Description = "Increases anomaly encounter chance by 50% for 10 minutes",
        Category = "Consumable",
        Price = 50,
        PriceCurrency = "Credits",
        Effect = "AnomalyAttract",
        EffectValue = 600,
        MaxStack = 5,
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
    OxygenBooster = 0,            -- +100 base oxygen capacity (79 R$)
    SpeedDiver = 0,               -- +20% swim speed (49 R$)
    ExpandedCollection = 0,       -- Double collection slots (99 R$)
    AbyssalPass = 0,              -- Access to exclusive trench content (199 R$)
    ResearchPointsPack = 0,       -- Bonus Research Points (49 R$)
    VIPStatus = 0,                -- +25% Credits, +15% XP, +5 max O2, VIP title (249 R$)
    AnomalyScanner = 0,           -- See anomaly events 30s before they happen (49 R$)
    AnomalyShield = 0,            -- Take 50% less damage during anomalies (79 R$)
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
-- Quest System Configuration
-- ============================================================

Config.QuestSystem = {
    MaxDailyQuests = 3,
    MaxReRollsPerDay = 1,
    ReRollCooldown = 1800,  -- 30 min between re-rolls
}

-- ============================================================
-- Daily Quests (3 per day, refresh every 24h)
-- ============================================================

Config.DailyQuests = {
    Daily_Catch5 = {
        Name = "Catch 5 Creatures",
        Description = "Catch any 5 creatures during a dive",
        Type = "Daily",
        Condition = { type = "CreatureCaught", count = 5 },
        Rewards = { Credits = 30 },
        XP_Reward = 50,
        Difficulty = "Easy",
    },
    Daily_Dive200m = {
        Name = "Descend 200 Meters",
        Description = "Reach a depth of 200 meters in a single dive",
        Type = "Daily",
        Condition = { type = "DepthUpdate", threshold = 200 },
        Rewards = { Credits = 40 },
        XP_Reward = 75,
        Difficulty = "Easy",
    },
    Daily_SellCreatures = {
        Name = "Sell 3 Creatures",
        Description = "Sell 3 creatures from your collection",
        Type = "Daily",
        Condition = { type = "CreatureSold", count = 3 },
        Rewards = { Credits = 25 },
        XP_Reward = 50,
        Difficulty = "Easy",
    },
    Daily_CatchUncommon = {
        Name = "Catch an Uncommon Creature",
        Description = "Catch a creature of Uncommon rarity or higher",
        Type = "Daily",
        Condition = { type = "CreatureCaught", rarity = "Uncommon", count = 1 },
        Rewards = { Credits = 50 },
        XP_Reward = 100,
        Difficulty = "Medium",
    },
    Daily_Dive500m = {
        Name = "Deep Dive",
        Description = "Reach a depth of 500 meters in a single dive",
        Type = "Daily",
        Condition = { type = "DepthUpdate", threshold = 500 },
        Rewards = { Credits = 60 },
        XP_Reward = 125,
        Difficulty = "Medium",
    },
    Daily_UseOxygenTank = {
        Name = "Emergency Refill",
        Description = "Use an Emergency Oxygen Tank while diving",
        Type = "Daily",
        Condition = { type = "UseItem", item = "OxygenTank", count = 1 },
        Rewards = { Credits = 15 },
        XP_Reward = 25,
        Difficulty = "Easy",
    },
}

-- ============================================================
-- Milestone Quests (one-time, progression-gated)
-- ============================================================

Config.MilestoneQuests = {
    Milestone_FirstDive = {
        Name = "First Dive",
        Description = "Complete your first dive and return to the surface",
        Condition = { type = "DiveComplete", minDepth = 1 },
        Rewards = { Credits = 50, ResearchPoints = 2 },
        XP_Reward = 100,
        Order = 1,
    },
    Milestone_ReachTwilight = {
        Name = "Into the Twilight",
        Description = "Reach the Twilight Zone (200m depth)",
        Condition = { type = "DepthUpdate", threshold = 200 },
        Rewards = { Credits = 100, ResearchPoints = 3 },
        XP_Reward = 200,
        Order = 2,
    },
    Milestone_BuyScuba = {
        Name = "Better Equipment",
        Description = "Purchase your first gear upgrade (Scuba Kit)",
        Condition = { type = "GearPurchased", tier = 2 },
        Rewards = { Credits = 75 },
        XP_Reward = 150,
        Order = 3,
    },
    Milestone_ReachMidnight = {
        Name = "Darkness Falls",
        Description = "Reach the Midnight Zone (1,000m depth)",
        Condition = { type = "DepthUpdate", threshold = 1000 },
        Rewards = { Credits = 200, ResearchPoints = 5 },
        XP_Reward = 400,
        Order = 4,
    },
    Milestone_CatchRare = {
        Name = "Rare Find",
        Description = "Catch your first Rare creature",
        Condition = { type = "CreatureCaught", rarity = "Rare", count = 1 },
        Rewards = { Credits = 150 },
        XP_Reward = 300,
        Order = 5,
    },
    Milestone_ReachAbyss = {
        Name = "Into the Abyss",
        Description = "Reach the Abyssal Zone (4,000m depth)",
        Condition = { type = "DepthUpdate", threshold = 4000 },
        Rewards = { Credits = 500, ResearchPoints = 10 },
        XP_Reward = 750,
        Order = 6,
    },
    Milestone_CatchEpic = {
        Name = "Epic Discovery",
        Description = "Catch your first Epic creature",
        Condition = { type = "CreatureCaught", rarity = "Epic", count = 1 },
        Rewards = { Credits = 400, ResearchPoints = 5 },
        XP_Reward = 500,
        Order = 7,
    },
    Milestone_ReachTrench = {
        Name = "The Deepest Place",
        Description = "Reach the Trenches (6,000m depth)",
        Condition = { type = "DepthUpdate", threshold = 6000 },
        Rewards = { Credits = 1000, ResearchPoints = 15 },
        XP_Reward = 1000,
        Order = 8,
    },
    Milestone_CatchLegendary = {
        Name = "Legendary Hunter",
        Description = "Catch your first Legendary creature",
        Condition = { type = "CreatureCaught", rarity = "Legendary", count = 1 },
        Rewards = { Credits = 1000, ResearchPoints = 20 },
        XP_Reward = 1500,
        Order = 9,
    },
    Milestone_BuildHabitat = {
        Name = "Home in the Deep",
        Description = "Place your first Habitat module",
        Condition = { type = "ModulePlaced", moduleType = "Habitat", count = 1 },
        Rewards = { Credits = 200 },
        XP_Reward = 300,
        Order = 10,
    },
    Milestone_CompleteZone = {
        Name = "Master Collector",
        Description = "Catch all creatures in a single zone",
        Condition = { type = "ZoneComplete", zoneIndex = 1 },
        Rewards = { Credits = 500, ResearchPoints = 10 },
        XP_Reward = 1000,
        Order = 11,
    },
}

-- ============================================================
-- Event Quests (triggered by Anomaly events)
-- ============================================================

Config.EventQuests = {
    Event_CatchInAnomaly = {
        Name = "Anomaly Hunter",
        Description = "Catch 3 creatures during an anomaly event",
        Type = "Event",
        TriggerEvent = "any",
        Condition = { type = "CreatureCaught", duringAnomaly = true, count = 3 },
        Rewards = { Credits = 100, ResearchPoints = 3 },
        XP_Reward = 200,
        Duration = 600,
    },
    Event_CatchLegendaryInAnomaly = {
        Name = "Legendary Sighting",
        Description = "Catch a Legendary creature during an anomaly",
        Type = "Event",
        TriggerEvent = "AncientMigration",
        Condition = { type = "CreatureCaught", rarity = "Legendary", duringAnomaly = true, count = 1 },
        Rewards = { Credits = 500, ResearchPoints = 15 },
        XP_Reward = 1000,
        Duration = 900,
    },
    Event_SurviveAnomaly = {
        Name = "Weather the Storm",
        Description = "Survive an anomaly event without surfacing",
        Type = "Event",
        TriggerEvent = "AbyssalSurge",
        Condition = { type = "SurviveAnomaly", duration = 60 },
        Rewards = { Credits = 200, ResearchPoints = 5 },
        XP_Reward = 400,
        Duration = 300,
    },
}

-- ============================================================
-- Achievements (long-term, collection-based)
-- ============================================================

Config.Achievements = {
    Achievement_10Species = {
        Name = "Species Collector",
        Description = "Catch 10 different species",
        Condition = { type = "UniqueSpecies", count = 10 },
        Rewards = { Credits = 500, ResearchPoints = 5 },
        XP_Reward = 1000,
    },
    Achievement_20Species = {
        Name = "Oceanographer",
        Description = "Catch 20 different species",
        Condition = { type = "UniqueSpecies", count = 20 },
        Rewards = { Credits = 1500, ResearchPoints = 15 },
        XP_Reward = 2000,
    },
    Achievement_AllSpecies = {
        Name = "Abyssal Professor",
        Description = "Catch ALL species",
        Condition = { type = "UniqueSpecies", count = 26 },
        Rewards = { Credits = 5000, ResearchPoints = 50 },
        XP_Reward = 5000,
    },
    Achievement_100Dives = {
        Name = "Century Diver",
        Description = "Complete 100 dives",
        Condition = { type = "DiveComplete", count = 100 },
        Rewards = { Credits = 1000, ResearchPoints = 10 },
        XP_Reward = 2000,
    },
    Achievement_500Dives = {
        Name = "Deep Sea Veteran",
        Description = "Complete 500 dives",
        Condition = { type = "DiveComplete", count = 500 },
        Rewards = { Credits = 5000, ResearchPoints = 25 },
        XP_Reward = 5000,
    },
    Achievement_10000Credits = {
        Name = "Wealthy Diver",
        Description = "Earn a total of 10,000 Credits",
        Condition = { type = "TotalCreditsEarned", count = 10000 },
        Rewards = { Credits = 1000, ResearchPoints = 5 },
        XP_Reward = 1000,
    },
    Achievement_1MCredits = {
        Name = "Billionaire of the Deep",
        Description = "Earn a total of 1,000,000 Credits",
        Condition = { type = "TotalCreditsEarned", count = 1000000 },
        Rewards = { Credits = 25000, ResearchPoints = 100 },
        XP_Reward = 10000,
    },
    Achievement_BuildAllModules = {
        Name = "Base Architect",
        Description = "Place all base module types",
        Condition = { type = "AllModuleTypesPlaced", count = 1 },
        Rewards = { Credits = 1000, ResearchPoints = 10 },
        XP_Reward = 2000,
    },
    Achievement_SurviveAllAnomalies = {
        Name = "Anomaly Survivor",
        Description = "Survive each type of anomaly at least once",
        Condition = { type = "AllAnomaliesSurvived", count = 1 },
        Rewards = { Credits = 2000, ResearchPoints = 20 },
        XP_Reward = 3000,
    },
    Achievement_TotalXP100K = {
        Name = "Master Diver",
        Description = "Earn 100,000 total XP",
        Condition = { type = "TotalXP", count = 100000 },
        Rewards = { Credits = 5000, ResearchPoints = 30 },
        XP_Reward = 5000,
    },
}

-- ============================================================
-- Developer Product IDs (set these after publishing)
-- ============================================================

Config.DeveloperProducts = {
    Credits_500 = 0,              -- 500 Credits (49 R$)
    Credits_2000 = 0,             -- 2,000 Credits (149 R$)
    Credits_10000 = 0,            -- 10,000 Credits (499 R$)
    ResearchPoints_10 = 0,        -- 10 RP (49 R$)
    ResearchPoints_50 = 0,        -- 50 RP (199 R$)
    ResearchPoints_250 = 0,       -- 250 RP (799 R$)
    StarterPack = 0,              -- 200 Cr + 10 RP + items (99 R$)
    AnomalyPass = 0,              -- Anomaly content micro-pass, 2 weeks (149 R$)
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
