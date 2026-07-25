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
        Description = "The abyss — ancient creatures dwell in the crushing dark. A Void Leviathan phases through the rock, hunting.",
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
        Description = "The deepest places on Earth — few have ever returned. The Ancient One watches from the darkness.",
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
    },
    {
        Name = "Legendary Diving Suit",
        Tier = 6,
        MaxDepth = 11000,
        OxygenBonus = 1000,
        SpeedModifier = 1.8,
        Price = 8000,
        PriceCurrency = "Credits",
        Description = "Forged from the essence of defeated leviathans. Nothing in the ocean can stop you now.",
        BossSpecial = true,  -- 50% damage reduction from boss attacks, 15% auto-dodge
    }
}

-- ============================================================
-- Fishing Rods (Fishing Tools)
-- ============================================================

Config.FishingRods = {
    {
        Name = "Basic Rod",
        Tier = 1,
        Power = 1,
        LineStrength = 100,
        ReelSpeed = 1,
        LureChance = 1,
        Price = 0,
        PriceCurrency = "Credits",
        Description = "A simple wooden rod. Gets the job done in shallow waters.",
    },
    {
        Name = "Twilight Rod",
        Tier = 2,
        Power = 2,
        LineStrength = 200,
        ReelSpeed = 1.2,
        LureChance = 1.1,
        Price = 200,
        PriceCurrency = "Credits",
        Description = "Reinforced rod for the dim Twilight Zone. Better tension control.",
    },
    {
        Name = "Midnight Rod",
        Tier = 3,
        Power = 3,
        LineStrength = 350,
        ReelSpeed = 1.4,
        LureChance = 1.25,
        Price = 500,
        PriceCurrency = "Credits",
        Description = "Steel-core rod built for the crushing dark of the Midnight Zone.",
    },
    {
        Name = "Abyssal Rod",
        Tier = 4,
        Power = 5,
        LineStrength = 600,
        ReelSpeed = 1.6,
        LureChance = 1.4,
        Price = 1200,
        PriceCurrency = "Credits",
        Description = "Titanium-alloy rod engineered for the extreme pressure of the Abyss.",
    },
    {
        Name = "Trenches Rod",
        Tier = 5,
        Power = 8,
        LineStrength = 1000,
        ReelSpeed = 1.8,
        LureChance = 1.6,
        Price = 3500,
        PriceCurrency = "Credits",
        Description = "The ultimate deep-sea rod. Built to reel in creatures from the ocean's deepest trenches.",
    },
    {
        Name = "Boss Rod",
        Tier = 5,
        Power = 12,
        LineStrength = 2000,
        ReelSpeed = 2.0,
        LureChance = 2.0,
        Price = 5000,
        PriceCurrency = "Credits",
        Description = "Legendary rod designed specifically for battling massive boss creatures. Devastating power.",
        BossFishingBonus = true,
    },
}

-- ============================================================
-- Diving Suits (Cosmetic + minor stat boosts)
-- ============================================================

Config.DivingSuits = {
    {
        Name = "Abyssal Suit",
        Tier = 4,
        OxygenBonus = 30,
        SpeedModifier = 1.05,
        DepthGated = 4000,
        Price = 800,
        PriceCurrency = "Credits",
        Description = "Heavy-duty suit with reinforced plating for Abyssal Zone diving.",
        CosmeticEffect = "MetallicSheen",
    },
    {
        Name = "Trenches Suit",
        Tier = 5,
        OxygenBonus = 50,
        SpeedModifier = 1.1,
        DepthGated = 6000,
        Price = 2000,
        PriceCurrency = "Credits",
        Description = "Experimental suit rated for the crushing pressure of the deepest trenches.",
        CosmeticEffect = "BioluminescentVeins",
    },
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
    -- Zone 1: Sunlight Zone (0-200m) — 11 creatures
    {
        Name = "Clownfish",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Emoji = "🤿",
        DepthRange = {0, 200},
        CatchDifficulty = 1,
        Value = 10,
        StatWeights = { Size = 30, Speed = 60, Rarity = 10 },
        Behavior = "Hides in anemones. Curious and playful.",
        Description = "Small orange fish with iconic white stripes. Often hides in anemones.",
        ModelAssetId = 0,
    },
    {
        Name = "Blue Tang",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Emoji = "🐠",
        DepthRange = {0, 200},
        CatchDifficulty = 1,
        Value = 10,
        StatWeights = { Size = 25, Speed = 70, Rarity = 5 },
        Behavior = "Schooling fish. Moves in dazzling blue shoals.",
        Description = "Vibrant blue body with a yellow tail. A favorite for reef watchers.",
        ModelAssetId = 0,
    },
    {
        Name = "Parrotfish",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Emoji = "🦜",
        DepthRange = {0, 150},
        CatchDifficulty = 1,
        Value = 12,
        StatWeights = { Size = 35, Speed = 40, Rarity = 25 },
        Behavior = "Grinds coral with beak-like teeth. Produces sand.",
        Description = "Colorful fish with beak-like teeth used to scrape algae off coral.",
        ModelAssetId = 0,
    },
    {
        Name = "Seahorse",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Emoji = "🐴",
        DepthRange = {0, 100},
        CatchDifficulty = 2,
        Value = 15,
        StatWeights = { Size = 10, Speed = 20, Rarity = 70 },
        Behavior = "Timid. Wraps tail around coral to anchor in currents.",
        Description = "Delicate fish with a curled tail and horse-like head. Famous for male pregnancy.",
        ModelAssetId = 0,
    },
    {
        Name = "Hermit Crab",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Emoji = "🐚",
        DepthRange = {0, 50},
        CatchDifficulty = 1,
        Value = 8,
        StatWeights = { Size = 20, Speed = 15, Rarity = 65 },
        Behavior = "Scavenges shells on the ocean floor. Swaps homes when growing.",
        Description = "A crab that lives inside discarded shells, changing homes as it grows.",
        ModelAssetId = 0,
    },
    {
        Name = "Sea Turtle",
        Rarity = "Uncommon",
        Zone = "Sunlight Zone",
        Emoji = "🐢",
        DepthRange = {0, 200},
        CatchDifficulty = 3,
        Value = 40,
        StatWeights = { Size = 70, Speed = 20, Rarity = 10 },
        Behavior = "Passive. Gracefully glides through the water.",
        Description = "A gentle green turtle that glides gracefully through the shallow reefs.",
        ModelAssetId = 0,
    },
    {
        Name = "Turtle Hatchling",
        Rarity = "Uncommon",
        Zone = "Sunlight Zone",
        Emoji = "🐣",
        DepthRange = {0, 50},
        CatchDifficulty = 4,
        Value = 35,
        StatWeights = { Size = 5, Speed = 80, Rarity = 15 },
        Behavior = "Frantic. Races toward the surface after hatching.",
        Description = "A newborn sea turtle making its first dash for the open ocean.",
        ModelAssetId = 0,
    },
    {
        Name = "Pufferfish",
        Rarity = "Uncommon",
        Zone = "Sunlight Zone",
        Emoji = "🐡",
        DepthRange = {0, 150},
        CatchDifficulty = 3,
        Value = 30,
        StatWeights = { Size = 30, Speed = 25, Rarity = 45 },
        Behavior = "Defensive. Inflates into a spiky ball when threatened.",
        Description = "A spiky fish that inflates to several times its size as a defense mechanism.",
        ModelAssetId = 0,
    },
    {
        Name = "Lionfish",
        Rarity = "Rare",
        Zone = "Sunlight Zone",
        Emoji = "🦁",
        DepthRange = {50, 200},
        CatchDifficulty = 5,
        Value = 100,
        StatWeights = { Size = 40, Speed = 30, Rarity = 30 },
        Behavior = "Aggressive. Fans out venomous spines in a display of dominance.",
        Description = "A stunning but venomous reef predator with flowing striped fins.",
        ModelAssetId = 0,
    },
    {
        Name = "Manta Ray",
        Rarity = "Rare",
        Zone = "Sunlight Zone",
        Emoji = "🦋",
        DepthRange = {100, 200},
        CatchDifficulty = 6,
        Value = 150,
        StatWeights = { Size = 90, Speed = 5, Rarity = 5 },
        Behavior = "Passive. Glides through sunlit waters like an underwater bird.",
        Description = "A massive, elegant ray that soars through the water on wing-like fins.",
        ModelAssetId = 0,
    },
    {
        Name = "Golden Manta Ray",
        Rarity = "Legendary",
        Zone = "Sunlight Zone",
        Emoji = "✨",
        DepthRange = {150, 200},
        CatchDifficulty = 10,
        Value = 3000,
        StatWeights = { Size = 95, Speed = 3, Rarity = 2 },
        Behavior = "Mythic. Only appears when sunlight hits the water at the perfect angle.",
        Description = "A majestic, shimmering ray that only appears when the sun hits the water just right.",
        ModelAssetId = 0,
    },

    -- Zone 2: Twilight Zone (200-1000m) — 11 creatures
    {
        Name = "Lanternfish",
        Rarity = "Common",
        Zone = "Twilight Zone",
        Emoji = "🏮",
        DepthRange = {200, 1000},
        CatchDifficulty = 2,
        Value = 15,
        StatWeights = { Size = 20, Speed = 50, Rarity = 30 },
        Behavior = "Bioluminescent. Blinks photophores along its body in rhythmic patterns.",
        Description = "Small fish with photophores along its body that blink in the dark.",
        ModelAssetId = 0,
    },
    {
        Name = "Hatchetfish",
        Rarity = "Common",
        Zone = "Twilight Zone",
        Emoji = "🪓",
        DepthRange = {200, 800},
        CatchDifficulty = 2,
        Value = 12,
        StatWeights = { Size = 15, Speed = 40, Rarity = 45 },
        Behavior = "Timid. Uses giant upward-facing eyes to spot predators above.",
        Description = "Paper-thin fish with giant, upward-facing eyes to spot prey above.",
        ModelAssetId = 0,
    },
    {
        Name = "Ratfish",
        Rarity = "Common",
        Zone = "Twilight Zone",
        Emoji = "🐀",
        DepthRange = {300, 900},
        CatchDifficulty = 2,
        Value = 18,
        StatWeights = { Size = 25, Speed = 35, Rarity = 40 },
        Behavior = "Timid. Cruises the twilight depths with a rodent-like snout.",
        Description = "A cartilaginous fish with a long rat-like tail and venomous dorsal spine.",
        ModelAssetId = 0,
    },
    {
        Name = "Barracuda",
        Rarity = "Uncommon",
        Zone = "Twilight Zone",
        Emoji = "🔪",
        DepthRange = {200, 600},
        CatchDifficulty = 4,
        Value = 45,
        StatWeights = { Size = 60, Speed = 35, Rarity = 5 },
        Behavior = "Aggressive. Ambush predator that strikes with lightning speed.",
        Description = "A fast, silver predator with razor-sharp teeth. Known for its ambush attacks.",
        ModelAssetId = 0,
    },
    {
        Name = "Firefly Squid",
        Rarity = "Uncommon",
        Zone = "Twilight Zone",
        Emoji = "🦑",
        DepthRange = {400, 800},
        CatchDifficulty = 3,
        Value = 35,
        StatWeights = { Size = 15, Speed = 45, Rarity = 40 },
        Behavior = "Bioluminescent. Thousands of photophores light up like a starry night.",
        Description = "A tiny squid covered in glowing blue dots that flash in mesmerizing patterns.",
        ModelAssetId = 0,
    },
    {
        Name = "Glass Squid",
        Rarity = "Uncommon",
        Zone = "Twilight Zone",
        Emoji = "🫧",
        DepthRange = {500, 1000},
        CatchDifficulty = 3,
        Value = 40,
        StatWeights = { Size = 20, Speed = 40, Rarity = 40 },
        Behavior = "Timid. Nearly invisible, uses transparency to evade predators.",
        Description = "A transparent cephalopod whose internal organs can be seen through its body.",
        ModelAssetId = 0,
    },
    {
        Name = "Oarfish",
        Rarity = "Rare",
        Zone = "Twilight Zone",
        Emoji = "🐍",
        DepthRange = {600, 1000},
        CatchDifficulty = 7,
        Value = 180,
        StatWeights = { Size = 100, Speed = 0, Rarity = 0 },
        Behavior = "Serpentine. Undulates vertically through the water column.",
        Description = "An incredibly long, ribbon-like silver fish. Often mistaken for sea serpents.",
        ModelAssetId = 0,
    },
    {
        Name = "Viperfish",
        Rarity = "Rare",
        Zone = "Twilight Zone",
        Emoji = "🐍",
        DepthRange = {700, 1000},
        CatchDifficulty = 7,
        Value = 160,
        StatWeights = { Size = 30, Speed = 60, Rarity = 10 },
        Behavior = "Aggressive. Uses needle-sharp teeth to impale prey from below.",
        Description = "A fearsome predator with teeth so long they don't fit inside its mouth.",
        ModelAssetId = 0,
    },
    {
        Name = "Dragonfish",
        Rarity = "Epic",
        Zone = "Twilight Zone",
        Emoji = "🐉",
        DepthRange = {800, 1000},
        CatchDifficulty = 8,
        Value = 500,
        StatWeights = { Size = 35, Speed = 55, Rarity = 10 },
        Behavior = "Aggressive. Produces its own red light to hunt unseen by prey.",
        Description = "A jet-black fish with a glowing barbel and the ability to produce red bioluminescence.",
        ModelAssetId = 0,
    },
    {
        Name = "Giant Squid",
        Rarity = "Epic",
        Zone = "Twilight Zone",
        Emoji = "🦑",
        DepthRange = {600, 1000},
        CatchDifficulty = 9,
        Value = 600,
        StatWeights = { Size = 95, Speed = 3, Rarity = 2 },
        Behavior = "Aggressive. A deep-sea titan whose massive eyes pierce the darkness.",
        Description = "A massive cephalopod with eyes the size of dinner plates. Rarely seen alive.",
        ModelAssetId = 0,
    },
    {
        Name = "The Silver Serpent",
        Rarity = "Legendary",
        Zone = "Twilight Zone",
        Emoji = "🐉",
        DepthRange = {900, 1000},
        CatchDifficulty = 10,
        Value = 4000,
        StatWeights = { Size = 85, Speed = 10, Rarity = 5 },
        Behavior = "Mythic. Leaves a shimmering trail of glowing bubbles in its wake.",
        Description = "A legendary eel-like creature that leaves a trail of glowing bubbles.",
        ModelAssetId = 0,
    },

    -- Zone 3: Midnight Zone (1000-4000m) — 13 creatures
    {
        Name = "Anglerfish",
        Rarity = "Common",
        Zone = "Midnight Zone",
        Emoji = "🎣",
        DepthRange = {1000, 3000},
        CatchDifficulty = 3,
        Value = 20,
        StatWeights = { Size = 25, Speed = 20, Rarity = 55 },
        Behavior = "Aggressive. Dangles a glowing lure to attract prey in the darkness.",
        Description = "A nightmare of the deep with a glowing lure to attract unsuspecting prey.",
        ModelAssetId = 0,
    },
    {
        Name = "Snipe Eel",
        Rarity = "Common",
        Zone = "Midnight Zone",
        Emoji = "📏",
        DepthRange = {1500, 4000},
        CatchDifficulty = 3,
        Value = 22,
        StatWeights = { Size = 80, Speed = 10, Rarity = 10 },
        Behavior = "Passive. Drifts with its jaws open to scoop up plankton.",
        Description = "An extraordinarily slender eel with a beak-like mouth gaping wide in the dark.",
        ModelAssetId = 0,
    },
    {
        Name = "Coelacanth",
        Rarity = "Common",
        Zone = "Midnight Zone",
        Emoji = "🦕",
        DepthRange = {2000, 4000},
        CatchDifficulty = 3,
        Value = 25,
        StatWeights = { Size = 70, Speed = 15, Rarity = 15 },
        Behavior = "Passive. An ancient living fossil, unchanged for 400 million years.",
        Description = "A prehistoric fish thought extinct until rediscovered in 1938. A true living fossil.",
        ModelAssetId = 0,
    },
    {
        Name = "Vampire Squid",
        Rarity = "Uncommon",
        Zone = "Midnight Zone",
        Emoji = "🧛",
        DepthRange = {1000, 3500},
        CatchDifficulty = 4,
        Value = 45,
        StatWeights = { Size = 20, Speed = 30, Rarity = 50 },
        Behavior = "Defensive. Wraps webbed arms around itself like a cape when threatened.",
        Description = "A deep-red cephalopod with webbed arms that look like a cape.",
        ModelAssetId = 0,
    },
    {
        Name = "Giant Isopod",
        Rarity = "Uncommon",
        Zone = "Midnight Zone",
        Emoji = "🪲",
        DepthRange = {2000, 4000},
        CatchDifficulty = 3,
        Value = 40,
        StatWeights = { Size = 40, Speed = 10, Rarity = 50 },
        Behavior = "Passive. Rolls into a defensive armored ball when disturbed.",
        Description = "A giant pill-bug-like crustacean that scavenges the deep sea floor.",
        ModelAssetId = 0,
    },
    {
        Name = "Blobfish",
        Rarity = "Rare",
        Zone = "Midnight Zone",
        Emoji = "😐",
        DepthRange = {2500, 4000},
        CatchDifficulty = 5,
        Value = 130,
        StatWeights = { Size = 30, Speed = 5, Rarity = 65 },
        Behavior = "Passive. Floats motionless, letting the pressure shape its gelatinous body.",
        Description = "A gelatinous mass that looks grumpy in the low-pressure surface world.",
        ModelAssetId = 0,
    },
    {
        Name = "Zombie Worm",
        Rarity = "Rare",
        Zone = "Midnight Zone",
        Emoji = "🦴",
        DepthRange = {3000, 4000},
        CatchDifficulty = 6,
        Value = 140,
        StatWeights = { Size = 10, Speed = 5, Rarity = 85 },
        Behavior = "Stationary. Bores into whale bones on the sea floor using acid.",
        Description = "A bone-eating worm that dissolves skeletons with acid to feed in the deep.",
        ModelAssetId = 0,
    },
    {
        Name = "Yeti Crab",
        Rarity = "Epic",
        Zone = "Midnight Zone",
        Emoji = "🦀",
        DepthRange = {3000, 4000},
        CatchDifficulty = 7,
        Value = 450,
        StatWeights = { Size = 25, Speed = 15, Rarity = 60 },
        Behavior = "Passive. Wields fuzzy claws covered in bacteria near hydrothermal vents.",
        Description = "A pale, furry-armed crustacean that farms bacteria on its claws for food.",
        ModelAssetId = 0,
    },
    {
        Name = "Sea Spider",
        Rarity = "Epic",
        Zone = "Midnight Zone",
        Emoji = "🕷️",
        DepthRange = {2500, 4000},
        CatchDifficulty = 7,
        Value = 400,
        StatWeights = { Size = 60, Speed = 20, Rarity = 20 },
        Behavior = "Aggressive. Uses impossibly long legs to stalk the abyssal floor.",
        Description = "A spindly-legged arthropod that looks like a spider adapted for the deep sea.",
        ModelAssetId = 0,
    },
    {
        Name = "Black Dragonfish",
        Rarity = "Epic",
        Zone = "Midnight Zone",
        Emoji = "🐲",
        DepthRange = {3000, 4000},
        CatchDifficulty = 8,
        Value = 550,
        StatWeights = { Size = 30, Speed = 60, Rarity = 10 },
        Behavior = "Aggressive. Produces infrared light to hunt unseen in the midnight zone.",
        Description = "A pitch-black predator that glows with an eerie red light invisible to prey.",
        ModelAssetId = 0,
    },
    {
        Name = "Colossal Squid",
        Rarity = "Epic",
        Zone = "Midnight Zone",
        Emoji = "🦑",
        DepthRange = {2000, 4000},
        CatchDifficulty = 9,
        Value = 700,
        StatWeights = { Size = 100, Speed = 0, Rarity = 0 },
        Behavior = "Aggressive. The heaviest squid ever found, with rotating hooks on its tentacles.",
        Description = "The heaviest squid ever found, featuring rotating hooks on its tentacles.",
        ModelAssetId = 0,
    },
    {
        Name = "Abyssal Kraken",
        Rarity = "Legendary",
        Zone = "Midnight Zone",
        Emoji = "🐙",
        DepthRange = {3500, 4000},
        CatchDifficulty = 10,
        Value = 5000,
        StatWeights = { Size = 100, Speed = 0, Rarity = 0 },
        Behavior = "Mythic. Its presence is felt long before its glowing eyes emerge from the dark.",
        Description = "A creature of myth, its presence is felt long before its glowing eyes emerge from the dark.",
        ModelAssetId = 0,
    },

    -- Zone 4: Abyssal Zone (4000-6000m) — 16 creatures
    {
        Name = "Fangtooth",
        Rarity = "Common",
        Zone = "Abyssal Zone",
        Emoji = "🦷",
        DepthRange = {4000, 6000},
        CatchDifficulty = 3,
        Value = 18,
        StatWeights = { Size = 15, Speed = 30, Rarity = 55 },
        Behavior = "Aggressive. Teeth so large it can't fully close its mouth.",
        Description = "Small but terrifying fish with teeth so long it can't fully close its mouth.",
        ModelAssetId = 0,
    },
    {
        Name = "Sea Butterfly",
        Rarity = "Common",
        Zone = "Abyssal Zone",
        Emoji = "🦋",
        DepthRange = {4000, 5500},
        CatchDifficulty = 2,
        Value = 15,
        StatWeights = { Size = 5, Speed = 30, Rarity = 65 },
        Behavior = "Passive. Flutters through the abyss on delicate wing-like fins.",
        Description = "A tiny, translucent snail that 'flies' through the water on wing-like appendages.",
        ModelAssetId = 0,
    },
    {
        Name = "Abyssal Grenadier",
        Rarity = "Common",
        Zone = "Abyssal Zone",
        Emoji = "🐟",
        DepthRange = {4500, 6000},
        CatchDifficulty = 3,
        Value = 20,
        StatWeights = { Size = 50, Speed = 20, Rarity = 30 },
        Behavior = "Passive. Slowly patrols the abyssal plains with a long, tapering tail.",
        Description = "A large-headed fish with a whip-like tail, the most abundant fish in the abyss.",
        ModelAssetId = 0,
    },
    {
        Name = "Dumbo Octopus",
        Rarity = "Uncommon",
        Zone = "Abyssal Zone",
        Emoji = "🐘",
        DepthRange = {4000, 5500},
        CatchDifficulty = 4,
        Value = 50,
        StatWeights = { Size = 20, Speed = 35, Rarity = 45 },
        Behavior = "Passive. Flaps ear-like fins to 'fly' through the water.",
        Description = "A cute octopus with ear-like fins used to 'fly' through the water.",
        ModelAssetId = 0,
    },
    {
        Name = "Tripod Fish",
        Rarity = "Uncommon",
        Zone = "Abyssal Zone",
        Emoji = "🦵",
        DepthRange = {4500, 6000},
        CatchDifficulty = 3,
        Value = 45,
        StatWeights = { Size = 25, Speed = 5, Rarity = 70 },
        Behavior = "Stationary. Stands on the sea floor using three elongated fins like stilts.",
        Description = "Stands on the sea floor using three extremely long fins like stilts.",
        ModelAssetId = 0,
    },
    {
        Name = "Glass Octopus",
        Rarity = "Uncommon",
        Zone = "Abyssal Zone",
        Emoji = "👻",
        DepthRange = {5000, 6000},
        CatchDifficulty = 4,
        Value = 55,
        StatWeights = { Size = 15, Speed = 40, Rarity = 45 },
        Behavior = "Timid. Nearly invisible — only its eyes and digestive gland are visible.",
        Description = "A ghostly, transparent octopus found in the deepest, darkest waters.",
        ModelAssetId = 0,
    },
    {
        Name = "Ghost Shark",
        Rarity = "Rare",
        Zone = "Abyssal Zone",
        Emoji = "👻",
        DepthRange = {4500, 6000},
        CatchDifficulty = 6,
        Value = 150,
        StatWeights = { Size = 55, Speed = 30, Rarity = 15 },
        Behavior = "Timid. Glides silently through the abyss with stitching-like skin patterns.",
        Description = "A pale, cartilaginous fish with stitching-like patterns on its skin.",
        ModelAssetId = 0,
    },
    {
        Name = "Goblin Shark",
        Rarity = "Rare",
        Zone = "Abyssal Zone",
        Emoji = "👺",
        DepthRange = {5000, 6000},
        CatchDifficulty = 7,
        Value = 180,
        StatWeights = { Size = 65, Speed = 25, Rarity = 10 },
        Behavior = "Aggressive. Launches its jaw forward to snatch prey in a split second.",
        Description = "A bizarre shark with a retractable jaw that shoots out to ambush prey.",
        ModelAssetId = 0,
    },
    {
        Name = "Frilled Shark",
        Rarity = "Rare",
        Zone = "Abyssal Zone",
        Emoji = "🦎",
        DepthRange = {5000, 6000},
        CatchDifficulty = 7,
        Value = 200,
        StatWeights = { Size = 70, Speed = 20, Rarity = 10 },
        Behavior = "Aggressive. Moves like an eel, striking with six rows of needle teeth.",
        Description = "A primitive shark with a serpentine body and frilled gills. A living fossil.",
        ModelAssetId = 0,
    },
    {
        Name = "Nautilus",
        Rarity = "Rare",
        Zone = "Abyssal Zone",
        Emoji = "🐚",
        DepthRange = {4000, 5500},
        CatchDifficulty = 5,
        Value = 160,
        StatWeights = { Size = 25, Speed = 15, Rarity = 60 },
        Behavior = "Passive. Drifts through ancient waters in its spiral shell, unchanged for millennia.",
        Description = "A spiral-shelled cephalopod that has survived unchanged for over 500 million years.",
        ModelAssetId = 0,
    },
    {
        Name = "Stargazer",
        Rarity = "Epic",
        Zone = "Abyssal Zone",
        Emoji = "⭐",
        DepthRange = {5000, 6000},
        CatchDifficulty = 8,
        Value = 450,
        StatWeights = { Size = 40, Speed = 15, Rarity = 45 },
        Behavior = "Aggressive. Buried in sand, its upward-facing eyes wait for prey to pass.",
        Description = "A fish that buries itself in the sea floor and ambushes prey with electric shocks.",
        ModelAssetId = 0,
    },
    {
        Name = "Helicoprion",
        Rarity = "Epic",
        Zone = "Abyssal Zone",
        Emoji = "🦈",
        DepthRange = {5500, 6000},
        CatchDifficulty = 9,
        Value = 650,
        StatWeights = { Size = 85, Speed = 10, Rarity = 5 },
        Behavior = "Aggressive. An extinct shark brought back — its buzzsaw jaw never stops spinning.",
        Description = "A prehistoric shark whose spiral-toothed jaw resembles a circular saw blade.",
        ModelAssetId = 0,
    },
    {
        Name = "Pelican Eel",
        Rarity = "Epic",
        Zone = "Abyssal Zone",
        Emoji = "🎈",
        DepthRange = {5000, 6000},
        CatchDifficulty = 7,
        Value = 500,
        StatWeights = { Size = 75, Speed = 15, Rarity = 10 },
        Behavior = "Aggressive. Inflates its massive throat pouch to swallow prey whole.",
        Description = "An eel with a balloon-like mouth that can swallow creatures larger than itself.",
        ModelAssetId = 0,
    },
    {
        Name = "Barrel Eye Fish",
        Rarity = "Epic",
        Zone = "Abyssal Zone",
        Emoji = "👁️",
        DepthRange = {5000, 6000},
        CatchDifficulty = 8,
        Value = 550,
        StatWeights = { Size = 20, Speed = 35, Rarity = 45 },
        Behavior = "Timid. Its transparent head reveals upward-rotating barrel-shaped eyes.",
        Description = "A fish with a completely transparent head and rotating tubular eyes.",
        ModelAssetId = 0,
    },
    {
        Name = "Abyssal Dragonfish",
        Rarity = "Epic",
        Zone = "Abyssal Zone",
        Emoji = "🐉",
        DepthRange = {4000, 6000},
        CatchDifficulty = 8,
        Value = 550,
        StatWeights = { Size = 30, Speed = 55, Rarity = 15 },
        Behavior = "Aggressive. Drawn to light, then strikes with bioluminescent fury.",
        Description = "A black, serpent-like fish with a long, glowing barbel attached to its chin.",
        ModelAssetId = 0,
    },
    {
        Name = "Living Fossil",
        Rarity = "Legendary",
        Zone = "Abyssal Zone",
        Emoji = "🦴",
        DepthRange = {5500, 6000},
        CatchDifficulty = 10,
        Value = 6000,
        StatWeights = { Size = 90, Speed = 5, Rarity = 5 },
        Behavior = "Mythic. A creature thought to be extinct — perfectly preserved in the cold, dark abyss.",
        Description = "A creature thought to be extinct for millions of years, perfectly preserved in the cold dark.",
        ModelAssetId = 0,
    },

    -- Zone 5: Trenches (6000-11000m) — 15 creatures
    {
        Name = "Snailfish",
        Rarity = "Common",
        Zone = "Trenches",
        Emoji = "🐌",
        DepthRange = {6000, 11000},
        CatchDifficulty = 4,
        Value = 25,
        StatWeights = { Size = 15, Speed = 20, Rarity = 65 },
        Behavior = "Passive. Translucent and delicate, yet able to withstand crushing pressure.",
        Description = "Translucent and delicate-looking, yet able to withstand crushing pressure.",
        ModelAssetId = 0,
    },
    {
        Name = "Hadal Snailfish",
        Rarity = "Common",
        Zone = "Trenches",
        Emoji = "🐌",
        DepthRange = {7000, 11000},
        CatchDifficulty = 4,
        Value = 30,
        StatWeights = { Size = 20, Speed = 15, Rarity = 65 },
        Behavior = "Passive. The deepest-living fish known, surviving at pressures that crush steel.",
        Description = "The world's deepest-living fish, thriving in the hadal zone beyond 7,000 meters.",
        ModelAssetId = 0,
    },
    {
        Name = "Bone Worm",
        Rarity = "Common",
        Zone = "Trenches",
        Emoji = "🦴",
        DepthRange = {6000, 9000},
        CatchDifficulty = 3,
        Value = 20,
        StatWeights = { Size = 5, Speed = 5, Rarity = 90 },
        Behavior = "Stationary. Emerges from whale falls to consume what little life remains.",
        Description = "A pale worm that colonizes sunken bones on the trench floor.",
        ModelAssetId = 0,
    },
    {
        Name = "Deep-Sea Jellyfish",
        Rarity = "Uncommon",
        Zone = "Trenches",
        Emoji = "🪼",
        DepthRange = {6000, 10000},
        CatchDifficulty = 5,
        Value = 55,
        StatWeights = { Size = 60, Speed = 10, Rarity = 30 },
        Behavior = "Bioluminescent. Pulses with eerie internal lights that shift through the color spectrum.",
        Description = "A massive, dark red jelly that pulses with eerie internal lights.",
        ModelAssetId = 0,
    },
    {
        Name = "Deep Sea Lizardfish",
        Rarity = "Uncommon",
        Zone = "Trenches",
        Emoji = "🦎",
        DepthRange = {7000, 11000},
        CatchDifficulty = 5,
        Value = 50,
        StatWeights = { Size = 35, Speed = 40, Rarity = 25 },
        Behavior = "Aggressive. A reptilian predator that drags prey down into the sediment.",
        Description = "A lizard-like fish with a gaping mouth lined with rows of needle-sharp teeth.",
        ModelAssetId = 0,
    },
    {
        Name = "Crystal Eel",
        Rarity = "Uncommon",
        Zone = "Trenches",
        Emoji = "💎",
        DepthRange = {8000, 11000},
        CatchDifficulty = 5,
        Value = 60,
        StatWeights = { Size = 25, Speed = 45, Rarity = 30 },
        Behavior = "Bioluminescent. Its crystalline body refracts light into prismatic patterns.",
        Description = "A translucent eel whose crystalline body sparkles with prismatic bioluminescence.",
        ModelAssetId = 0,
    },
    {
        Name = "Xenophyophore",
        Rarity = "Rare",
        Zone = "Trenches",
        Emoji = "🦠",
        DepthRange = {6500, 11000},
        CatchDifficulty = 6,
        Value = 170,
        StatWeights = { Size = 45, Speed = 5, Rarity = 50 },
        Behavior = "Stationary. A giant single-celled organism older than most civilizations.",
        Description = "A giant single-celled organism that looks like a structured sponge.",
        ModelAssetId = 0,
    },
    {
        Name = "Phantom Shark",
        Rarity = "Rare",
        Zone = "Trenches",
        Emoji = "🦈",
        DepthRange = {8000, 11000},
        CatchDifficulty = 8,
        Value = 220,
        StatWeights = { Size = 75, Speed = 20, Rarity = 5 },
        Behavior = "Aggressive. Appears and vanishes in the trench mist like a ghost.",
        Description = "A ghostly white shark that appears only in the deepest trenches, then disappears.",
        ModelAssetId = 0,
    },
    {
        Name = "Void Ctenophore",
        Rarity = "Rare",
        Zone = "Trenches",
        Emoji = "💫",
        DepthRange = {9000, 11000},
        CatchDifficulty = 7,
        Value = 200,
        StatWeights = { Size = 35, Speed = 30, Rarity = 35 },
        Behavior = "Bioluminescent. Ripples with rainbow light like a living aurora.",
        Description = "A comb jelly that creates hypnotizing rainbow light displays in the void.",
        ModelAssetId = 0,
    },
    {
        Name = "Trench Leviathan",
        Rarity = "Epic",
        Zone = "Trenches",
        Emoji = "🐉",
        DepthRange = {7000, 11000},
        CatchDifficulty = 9,
        Value = 700,
        StatWeights = { Size = 100, Speed = 0, Rarity = 0 },
        Behavior = "Aggressive. An ancient, armored serpent that circles the deepest rifts.",
        Description = "An ancient, armored serpent that circles the deepest rifts of the world.",
        ModelAssetId = 0,
    },
    {
        Name = "Deep Reef Stalker",
        Rarity = "Epic",
        Zone = "Trenches",
        Emoji = "👣",
        DepthRange = {8000, 11000},
        CatchDifficulty = 9,
        Value = 650,
        StatWeights = { Size = 60, Speed = 30, Rarity = 10 },
        Behavior = "Aggressive. Tracks divers from the shadows before striking from below.",
        Description = "A shadowy predator that stalks divers through the trench darkness.",
        ModelAssetId = 0,
    },
    {
        Name = "Abyssal Hydra",
        Rarity = "Epic",
        Zone = "Trenches",
        Emoji = "🐍",
        DepthRange = {9000, 11000},
        CatchDifficulty = 10,
        Value = 800,
        StatWeights = { Size = 85, Speed = 10, Rarity = 5 },
        Behavior = "Aggressive. Multiple head-like appendages whip through the water independently.",
        Description = "A nightmarish creature with multiple serpentine necks rising from a single body.",
        ModelAssetId = 0,
    },
    {
        Name = "The Drowned One",
        Rarity = "Legendary",
        Zone = "Trenches",
        Emoji = "💀",
        DepthRange = {10000, 11000},
        CatchDifficulty = 10,
        Value = 7000,
        StatWeights = { Size = 50, Speed = 25, Rarity = 25 },
        Behavior = "Mythic. A humanoid shadow that beckons divers deeper into the abyss.",
        Description = "A mysterious humanoid figure that appears at the very bottom of the world.",
        ModelAssetId = 0,
    },
    {
        Name = "The Void Soul",
        Rarity = "Legendary",
        Zone = "Trenches",
        Emoji = "👁️",
        DepthRange = {10500, 11000},
        CatchDifficulty = 10,
        Value = 8000,
        StatWeights = { Size = 70, Speed = 15, Rarity = 15 },
        Behavior = "Mythic. Made of pure bioluminescence, it drifts between the world of life and void.",
        Description = "A ghostly, translucent entity that seems to be made of pure bioluminescence.",
        ModelAssetId = 0,
    },
    {
        Name = "Hadal Leviathan",
        Rarity = "Legendary",
        Zone = "Trenches",
        Emoji = "🌊",
        DepthRange = {10500, 11000},
        CatchDifficulty = 10,
        Value = 10000,
        StatWeights = { Size = 100, Speed = 0, Rarity = 0 },
        Behavior = "Mythic. The undisputed ruler of the hadal depths — its size is beyond measurement.",
        Description = "The ultimate apex predator of the trenches. Few have seen it and returned to tell the tale.",
        ModelAssetId = 0,
    },
}-- ============================================================
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
                         MaxModules = 20,
                         MaxTier = 3,
                         -- New module types
                         CraftingTable = {Credits = 50, Scrap = 100, Crystal = 50},
                         OxygenGenerator = {Credits = 200, Scrap = 80, Crystal = 30},
                         CreaturePen = {Credits = 150, Scrap = 60, Crystal = 40},
                         ResearchLab = {Credits = 300, Scrap = 120, Crystal = 80},
                         TradingPost = {Credits = 250, Scrap = 100, Crystal = 60},
                         TeleportBeacon = {Credits = 400, Scrap = 200, Crystal = 100},
        },
}

-- ============================================================
-- Research Tree Upgrades
-- ============================================================

Config.ResearchTree = {
    OxygenEfficiency = {
        DisplayName = "Oxygen Efficiency",
        MaxTier = 5,
        CostPerTier = {[1] = 5, [2] = 10, [3] = 20, [4] = 35, [5] = 50},
        BonusPerTier = 10, -- +10% O₂ per dive
    },
    SwimSpeed = {
        DisplayName = "Swim Speed",
        MaxTier = 5,
        CostPerTier = {[1] = 5, [2] = 10, [3] = 20, [4] = 35, [5] = 50},
        BonusPerTier = 5, -- +5% speed
    },
    CreatureLure = {
        DisplayName = "Creature Lure",
        MaxTier = 3,
        CostPerTier = {[1] = 10, [2] = 20, [3] = 40},
        BonusPerTier = 15, -- +15% spawn rate
    },
    CraftingEfficiency = {
        DisplayName = "Crafting Efficiency",
        MaxTier = 3,
        CostPerTier = {[1] = 10, [2] = 20, [3] = 40},
        BonusPerTier = 10, -- -10% material cost
    },
    MarketFeeReduction = {
        DisplayName = "Market Fee Reduction",
        MaxTier = 3,
        CostPerTier = {[1] = 5, [2] = 15, [3] = 30},
        BonusPerTier = 1, -- -1% tax
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
    BioluminescentGoo = {
        DisplayName = "Bioluminescent Goo",
        Description = "High-value alchemy ingredient dropped by deep-sea creatures",
        StartingAmount = 0,
        MaxStack = 99,
        PerDepthMeter = 0.002,     -- Extremely rare, ~0.4 per 200m dive
        SellPrice = 100,
        RarityWeights = { Common = 0, Uncommon = 20, Rare = 40, Epic = 25, Legendary = 15 },
    },
    VoidEssence = {
        DisplayName = "Void Essence",
        Description = "Super-rare essence from the void between dimensions — used for ultimate upgrades",
        StartingAmount = 0,
        MaxStack = 20,
        PerDepthMeter = 0.0005,    -- Ultra rare, only in deepest zones
        SellPrice = 500,
        RarityWeights = { Common = 0, Uncommon = 0, Rare = 10, Epic = 30, Legendary = 60 },
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
    
    -- New consumables
    LuckCharm = {
        Name = "Luck Charm",
        Description = "+20% legendary creature encounter rate for 5 minutes",
        Category = "Consumable",
        Price = 35,
        PriceCurrency = "Credits",
        Effect = "LegendaryLure",
        EffectValue = 300,
        MaxStack = 3,
    },
    DepthBooster = {
        Name = "Depth Booster",
        Description = "Temporarily increases your max depth by 200m for one dive",
        Category = "Consumable",
        Price = 40,
        PriceCurrency = "Credits",
        Effect = "TempDepthBoost",
        EffectValue = 200,
        MaxStack = 3,
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

-- ============================================================
-- Creature Trading & Marketplace
-- ============================================================

Config.CreatureMarket = {
    -- Market tax rate (5% on all sales)
    MarketTaxRate = 0.05,
    
    -- Listing fee (1% of ask price, minimum 1 credit)
    ListingFeeRate = 0.01,
    ListingFeeMinimum = 1,
    
    -- Max listings per player
    MaxActiveListings = 10,
    
    -- Default auction duration (hours)
    DefaultAuctionDuration = 24,
    MaxAuctionDuration = 72,
    
    -- Creature base values by rarity (before multipliers)
    BaseValues = {
        Common = 50,
        Uncommon = 150,
        Rare = 500,
        Epic = 1500,
        Legendary = 5000,
        Mythic = 15000,
    },
    
    -- Rarity multipliers for market value
    RarityMultipliers = {
        Common = 1.0,
        Uncommon = 1.5,
        Rare = 3.0,
        Epic = 6.0,
        Legendary = 12.0,
        Mythic = 25.0,
    },
    
    -- Trade reputation range
    MinTradeReputation = 0,
    MaxTradeReputation = 100,
    ReputationGainPerTrade = 1,
    
    -- Maximum trade history entries per player
    MaxTradeHistoryEntries = 50,
}

-- ============================================================
-- Boss Configuration (5 zone bosses)
-- ============================================================

Config.Bosses = {
    {
        Key = "CoralGuardian",
        Name = "Coral Guardian",
        Zone = "Sunlight Zone",
        ZoneIndex = 1,
        DepthMin = 150,
        DepthMax = 200,
        Rarity = "Common",
        HP = 500,
        BiteWindow = 2.5,
        DodgeCount = 2,
        DodgeWarningTime = 1.5,
        SpawnCooldown = 600,
        EngagementRange = 40,
        ArenaRadius = 80,
        AttackPatterns = {
            { name = "Claw_Slam", damage = 15, windup = 3.0, type = "cone" },
            { name = "Coral_Shrapnel", damage = 6, windup = 2.0, type = "projectile", count = 5 },
            { name = "Anemone_Shield", damage = 0, windup = 0, type = "passive", triggerPercent = 50 },
        },
        Rewards = {
            Credits = 100,
            XP = 50,
            Material = "CoralFragment",
            Title = "Reef Champion",
            CosmeticDrop = { item = "GuardianShell", chance = 0.10 },
        },
        ModelAssetId = 0,
    },
    {
        Key = "KrakenWraith",
        Name = "Kraken Wraith",
        Zone = "Twilight Zone",
        ZoneIndex = 2,
        DepthMin = 600,
        DepthMax = 900,
        Rarity = "Uncommon",
        HP = 1200,
        BiteWindow = 2.0,
        DodgeCount = 3,
        DodgeWarningTime = 1.3,
        SpawnCooldown = 900,
        EngagementRange = 50,
        ArenaRadius = 100,
        AttackPatterns = {
            { name = "Tentacle_Grab", damage = 20, windup = 2.0, type = "grab" },
            { name = "Ink_Cloud", damage = 0, windup = 0, type = "blind", duration = 4 },
            { name = "Phase_Rush", damage = 30, windup = 1.5, type = "charge" },
        },
        Rewards = {
            Credits = 300,
            XP = 200,
            Material = "WraithEssence",
            Title = "Twilight Exorcist",
            CosmeticDrop = { item = "WraithMantle", chance = 0.15 },
        },
        ModelAssetId = 0,
    },
    {
        Key = "AbyssalLeviathan",
        Name = "Abyssal Leviathan",
        Zone = "Midnight Zone",
        ZoneIndex = 3,
        DepthMin = 2500,
        DepthMax = 3500,
        Rarity = "Rare",
        HP = 2500,
        HeadsCount = 3,
        HPPerHead = 833,
        BiteWindow = 2.0,
        DodgeCount = 4,
        DodgeWarningTime = 1.2,
        SpawnCooldown = 1200,
        EngagementRange = 60,
        ArenaRadius = 120,
        AttackPatterns = {
            { name = "Lure_Bite", damage = 25, windup = 1.5, type = "lunge" },
            { name = "Triple_Beam", damage = 40, windup = 3.0, type = "sweep" },
            { name = "Vent_Eruption", damage = 10, windup = 2.0, type = "aoe_dot", triggerPercent = 66 },
        },
        Rewards = {
            Credits = 800,
            XP = 500,
            Material = "LeviathanScale",
            Title = "Midnight Slayer",
            CosmeticDrop = { item = "LeviathanJawTrophy", chance = 0.20 },
            GuaranteedDrop = "LeviathanTooth",
        },
        ModelAssetId = 0,
    },
    {
        Key = "VoidLeviathan",
        Name = "Void Leviathan",
        Zone = "Abyssal Zone",
        ZoneIndex = 4,
        DepthMin = 4800,
        DepthMax = 5500,
        Rarity = "Epic",
        HP = 5000,
        BiteWindow = 3.0,
        DodgeCount = 5,
        DodgeWarningTime = 1.0,
        SpawnCooldown = 1800,
        EngagementRange = 70,
        ArenaRadius = 160,
        AttackPatterns = {
            { name = "Rock_Phase", damage = 35, windup = 0, type = "ambush", delay = 2.0 },
            { name = "Void_Scream", damage = 15, windup = 2.0, type = "aoe", disorient = 3 },
            { name = "Phantom_Swarm", damage = 20, windup = 1.0, type = "split", triggerPercent = 50, copyCount = 3 },
            { name = "Abyssal_Crush", damage = 50, windup = 5.0, type = "vortex" },
        },
        Rewards = {
            Credits = 2000,
            XP = 1500,
            Material = "VoidCrystal",
            Title = "Void Walker",
            CosmeticDrop = { item = "VoidEssenceAura", chance = 0.25 },
            GuaranteedDrop = "VoidFragment",
        },
        ModelAssetId = 0,
    },
    {
        Key = "TheAncientOne",
        Name = "The Ancient One",
        Zone = "Trenches",
        ZoneIndex = 5,
        DepthMin = 9500,
        DepthMax = 11000,
        Rarity = "Legendary",
        HP = 10000,
        BiteWindow = 2.0,
        DodgeCount = 6,
        DodgeWarningTime = 0.8,
        SpawnCooldown = 3600,
        EngagementRange = 100,
        ArenaRadius = 200,
        AttackPatterns = {
            { name = "Gaze_of_the_Deep", damage = 2, windup = 0, type = "passive_dot", ticksPerSecond = true },
            { name = "Tentacle_Sweep", damage = 60, windup = 4.0, type = "sweep" },
            { name = "Crushing_Depths", damage = 0, windup = 0, type = "passive", triggerPercent = 50, effect = "doubleOxygen" },
            { name = "Abyssal_Roar", damage = 40, windup = 6.0, type = "rain", count = 8 },
            { name = "Final_Gaze", damage = 80, windup = 1.5, type = "lookAway", triggerPercent = 10 },
        },
        Rewards = {
            Credits = 5000,
            XP = 4000,
            Material = "AncientFragment",
            Title = "Ancient Bane",
            CosmeticDrop = { item = "AncientSuitSkin", chance = 0.50 },
            GuaranteedDrop = "AncientEyeShard",
        },
        ModelAssetId = 0,
    },
}

-- ============================================================
-- Boss Materials
-- ============================================================

Config.BossMaterials = {
    CoralFragment = {
        DisplayName = "Coral Fragment",
        Description = "A piece of the Coral Guardian's shell. Pulses with warm energy.",
        Rarity = "Rare",
    },
    WraithEssence = {
        DisplayName = "Wraith Essence",
        Description = "Ethereal residue from the Kraken Wraith. Cold to the touch and semi-transparent.",
        Rarity = "Rare",
    },
    LeviathanScale = {
        DisplayName = "Leviathan Scale",
        Description = "An impossibly tough scale from the Abyssal Leviathan. Light bends around it.",
        Rarity = "Epic",
    },
    LeviathanTooth = {
        DisplayName = "Leviathan Tooth",
        Description = "A serrated fang from the Abyssal Leviathan. Still sharp enough to cut steel.",
        Rarity = "Epic",
    },
    VoidCrystal = {
        DisplayName = "Void Crystal",
        Description = "Crystallized void energy from the Void Leviathan. Absorbs all light that touches it.",
        Rarity = "Epic",
    },
    VoidFragment = {
        DisplayName = "Void Fragment",
        Description = "A shard of the Void Leviathan's skeleton. Cold and weightless.",
        Rarity = "Epic",
    },
    AncientFragment = {
        DisplayName = "Ancient Fragment",
        Description = "A piece of The Ancient One's eye casing. It seems to watch you.",
        Rarity = "Legendary",
    },
    AncientEyeShard = {
        DisplayName = "Ancient Eye Shard",
        Description = "A crystallized tear from The Ancient One. Contains the light of a dying star.",
        Rarity = "Legendary",
    },
}

-- ============================================================
-- Boss-Tier Fishing Rods (crafted from boss materials)
-- ============================================================

Config.BossRods = {
    GuardianRod = {
        Name = "Guardian Rod",
        Tier = 6,
        Description = "Crafted from the Coral Guardian's essence. Reef creatures respect its power.",
        CraftCosts = {
            CoralFragment = 3,
            WraithEssence = 2,
            LeviathanScale = 1,
            LeviathanTooth = 1,
        },
        Effects = {
            CatchRateBonus = 0.15,
            BiteTimeReduction = 1,
            RestrictedZones = { 1, 2 },
        },
    },
    MasterBossRod = {
        Name = "Master Boss Rod",
        Tier = 7,
        Description = "Forged from the void itself. All creatures feel its pull.",
        CraftCosts = {
            VoidCrystal = 2,
            VoidFragment = 1,
            LeviathanScale = 3,
        },
        Effects = {
            CatchRateBonus = 0.20,
            RareChanceBonus = 0.10,
        },
    },
    LegendaryRod = {
        Name = "Legendary Rod",
        Tier = 8,
        Description = "Contains the power of The Ancient One. The ocean itself obeys.",
        CraftCosts = {
            AncientFragment = 3,
            AncientEyeShard = 1,
            VoidCrystal = 3,
        },
        Effects = {
            CatchRateBonus = 0.25,
            LegendaryChanceBonus = 0.15,
            RevealsShiny = true,
        },
    },
}

-- ============================================================
-- Boss-Related Shop Items
-- ============================================================

Config.ShopItems.BossBait = {
    Name = "Boss Lure",
    Description = "Forces the zone boss to spawn immediately (if available)",
    Category = "Consumable",
    Price = 200,
    PriceCurrency = "Credits",
    Effect = "SpawnBoss",
    MaxStack = 1,
}
Config.ShopItems.BossRadar = {
    Name = "Boss Sonar",
    Description = "Shows the exact location of the nearest boss for 5 minutes",
    Category = "Consumable",
    Price = 100,
    PriceCurrency = "Credits",
    Effect = "RevealBoss",
    EffectValue = 300,
    MaxStack = 3,
}

-- ============================================================
-- Boss Daily Quest (1 per day)
-- ============================================================

Config.DailyQuests.Daily_BossHunter = {
    Name = "Boss Hunter",
    Description = "Defeat any zone boss",
    Type = "Daily",
    Condition = { type = "BossDefeated", boss = "any", count = 1 },
    Rewards = { Credits = 300, Consumable = "BossBait", count = 1 },
    XP_Reward = 500,
    Difficulty = "Hard",
}

-- ============================================================
-- Boss Milestone Quests (one-time)
-- ============================================================

Config.MilestoneQuests.Milestone_DefeatCoralGuardian = {
    Name = "Guardian's Downfall",
    Description = "Defeat the Coral Guardian in the Sunlight Zone",
    Condition = { type = "BossDefeated", boss = "CoralGuardian" },
    Rewards = { Credits = 500, ResearchPoints = 5 },
    XP_Reward = 500,
    Order = 15,
}
Config.MilestoneQuests.Milestone_DefeatKrakenWraith = {
    Name = "Wraith Hunter",
    Description = "Defeat the Kraken Wraith in the Twilight Zone",
    Condition = { type = "BossDefeated", boss = "KrakenWraith" },
    Rewards = { Credits = 1000, ResearchPoints = 10 },
    XP_Reward = 750,
    Order = 16,
}
Config.MilestoneQuests.Milestone_DefeatLeviathan = {
    Name = "Leviathan's Bane",
    Description = "Defeat the Abyssal Leviathan in the Midnight Zone",
    Condition = { type = "BossDefeated", boss = "AbyssalLeviathan" },
    Rewards = { Credits = 2000, ResearchPoints = 15 },
    XP_Reward = 1000,
    Order = 17,
}
Config.MilestoneQuests.Milestone_DefeatVoid = {
    Name = "Void Cleanser",
    Description = "Defeat the Void Leviathan in the Abyssal Zone",
    Condition = { type = "BossDefeated", boss = "VoidLeviathan" },
    Rewards = { Credits = 4000, ResearchPoints = 25 },
    XP_Reward = 1500,
    Order = 18,
}
Config.MilestoneQuests.Milestone_DefeatAncient = {
    Name = "Ancient's End",
    Description = "Defeat The Ancient One in the Trenches",
    Condition = { type = "BossDefeated", boss = "TheAncientOne" },
    Rewards = { Credits = 8000, ResearchPoints = 50 },
    XP_Reward = 3000,
    Order = 19,
}

-- ============================================================
-- Boss Achievements
-- ============================================================

Config.Achievements.Achievement_DefeatAllBosses = {
    Name = "Leviathan Bane",
    Description = "Defeat all 5 zone bosses",
    Condition = { type = "AllBossesDefeated" },
    Rewards = { Credits = 10000, ResearchPoints = 50 },
    XP_Reward = 10000,
}
Config.Achievements.Achievement_SpeedKiller = {
    Name = "Speed Killer",
    Description = "Defeat a boss in under 5 minutes",
    Condition = { type = "BossDefeatedFast", timeLimit = 300 },
    Rewards = { Credits = 1000, ResearchPoints = 10 },
    XP_Reward = 1000,
}
Config.Achievements.Achievement_Untouchable = {
    Name = "Untouchable",
    Description = "Defeat any boss without taking damage",
    Condition = { type = "BossDefeatedFlawless" },
    Rewards = { Credits = 2000, ResearchPoints = 25 },
    XP_Reward = 2000,
}

-- ============================================================
-- Boss Fight Scaling Constants
-- ============================================================

Config.BossFight = {
    MultiplayerHPScaling = 0.5,       -- HP multiplier per additional player: HP * (1 + 0.5 * (N-1))
    DamageBonusForTopDPS = 0.25,      -- +25% Credits for highest damage dealer
    MinDamageForReward = 0.01,        -- Must deal 1%+ of total HP to qualify for rewards
    ArenaLeaveTimeout = 5,            -- Seconds outside arena before fight resets
    BossReengageCooldown = 300,       -- 5 min cooldown after death
    IdleDespawnTime = 600,            -- 10 min without engagement → despawn
    IdleDespawnCooldown = 0.5,        -- 50% cooldown after idle despawn
    MaxClicksPerSecond = 8,           -- Anti-auto-clicker cap
}

-- ============================================================
-- Anomaly-Boss Interaction Modifiers
-- ============================================================

Config.AnomalyBossModifiers = {
    CorruptedDepths = {
        BossDamageMultiplier = 1.25,
        BossRewardMultiplier = 1.5,
        BossSpawnCooldownMultiplier = 1.0,
    },
    EnchantedWaters = {
        BossDamageMultiplier = 1.0,
        BossRewardMultiplier = 1.25,
        BossSpawnCooldownMultiplier = 0.5,
    },
    BioluminescentBloom = {
        BossDamageMultiplier = 0.8,
        BossRewardMultiplier = 1.0,
        BossSpawnCooldownMultiplier = 1.0,
    },
    AbyssalSurge = {
        BossDamageMultiplier = 1.5,
        BossRewardMultiplier = 2.0,
        BossSpawnCooldownMultiplier = 0.75,
    },
    AncientMigration = {
        BossDamageMultiplier = 1.0,
        BossRewardMultiplier = 3.0,
        BossSpawnCooldownMultiplier = 0.25,
        AncientOnePermanentOpen = true,
    },
}

return Config
