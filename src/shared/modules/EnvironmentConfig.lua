--[[
    EnvironmentConfig.lua — Day/Night, Weather, and Season configuration
    Used by TimeService, WeatherService, CameraController, and VFXController.
]]

local EnvironmentConfig = {}

-- ============================================================
-- Day/Night Cycle
-- ============================================================

EnvironmentConfig.TimeCycle = {
    CycleDuration = 1200,        -- 20 minutes per full cycle
    DayDuration = 720,           -- 12 minutes of daylight
    NightDuration = 480,         -- 8 minutes of night
    TransitionDuration = 30,     -- 30-second smooth transition between phases

    -- Phase definitions (0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk)
    DayPhase = {
        -- Dawn (0.2 - 0.3): gentle warm light
        Dawn = {
            AmbientLight = 0.6,
            Brightness = 1.5,
            FogColor = Color3.fromRGB(255, 220, 180),
            FogEnd = 600,
            TintColor = Color3.fromRGB(255, 240, 220),
            WaterColor = Color3.fromRGB(100, 200, 255),
        },
        -- Noon (0.3 - 0.7): bright clear water
        Noon = {
            AmbientLight = 0.8,
            Brightness = 2,
            FogColor = Color3.fromRGB(135, 206, 250),
            FogEnd = 800,
            TintColor = Color3.fromRGB(255, 255, 255),
            WaterColor = Color3.fromRGB(80, 180, 240),
        },
        -- Dusk (0.7 - 0.8): orange light fading
        Dusk = {
            AmbientLight = 0.4,
            Brightness = 1.2,
            FogColor = Color3.fromRGB(255, 150, 80),
            FogEnd = 400,
            TintColor = Color3.fromRGB(255, 180, 140),
            WaterColor = Color3.fromRGB(60, 80, 150),
        },
    },

    NightPhase = {
        -- Early night (0.8 - 0.95): darkness settles
        EarlyNight = {
            AmbientLight = 0.1,
            Brightness = 0.5,
            FogColor = Color3.fromRGB(15, 25, 60),
            FogEnd = 150,
            TintColor = Color3.fromRGB(50, 80, 180),
            WaterColor = Color3.fromRGB(5, 10, 30),
        },
        -- Midnight (0.95 - 0.05): total darkness
        Midnight = {
            AmbientLight = 0.03,
            Brightness = 0.3,
            FogColor = Color3.fromRGB(5, 8, 25),
            FogEnd = 80,
            TintColor = Color3.fromRGB(20, 40, 120),
            WaterColor = Color3.fromRGB(2, 4, 15),
        },
        -- Pre-dawn (0.05 - 0.2): faint glow on horizon
        PreDawn = {
            AmbientLight = 0.08,
            Brightness = 0.4,
            FogColor = Color3.fromRGB(30, 40, 80),
            FogEnd = 120,
            TintColor = Color3.fromRGB(80, 100, 180),
            WaterColor = Color3.fromRGB(4, 8, 25),
        },
    },

    -- Time-of-day spawn modifiers
    DaySpawnModifiers = {
        CommonMultiplier = 1.5,
        UncommonMultiplier = 1.2,
        RareMultiplier = 1.0,
        EpicMultiplier = 0.8,
        LegendaryMultiplier = 0.5,
    },
    NightSpawnModifiers = {
        CommonMultiplier = 0.5,
        UncommonMultiplier = 0.8,
        RareMultiplier = 1.0,
        EpicMultiplier = 1.5,
        LegendaryMultiplier = 3.0,
    },

    -- Day-only creatures
    DayOnlyCreatures = {
        { Id = "sun_ray", DisplayName = "Sun Ray", Rarity = "Uncommon", Zone = 1 },
        { Id = "golden_grouper", DisplayName = "Golden Grouper", Rarity = "Rare", Zone = 2 },
        { Id = "daylight_angelfish", DisplayName = "Daylight Angelfish", Rarity = "Uncommon", Zone = 1 },
    },

    -- Night-only creatures
    NightOnlyCreatures = {
        { Id = "moon_jelly", DisplayName = "Moon Jelly", Rarity = "Uncommon", Zone = 2 },
        { Id = "nightshade_eel", DisplayName = "Nightshade Eel", Rarity = "Rare", Zone = 3 },
        { Id = "starlight_turtle", DisplayName = "Starlight Turtle", Rarity = "Epic", Zone = 2 },
    },
}

-- ============================================================
-- Weather System
-- ============================================================

EnvironmentConfig.Weather = {
    -- How often weather changes (seconds)
    ChangeIntervalMin = 180, -- 3 minutes minimum
    ChangeIntervalMax = 480, -- 8 minutes maximum

    -- Transition duration (seconds for visual blend)
    TransitionDuration = 10,

    Types = {
        Clear = {
            Weight = 70,
            DurationMin = 120,
            DurationMax = 300,
            Lighting = {
                FogMultiplier = 1.0,
                BrightnessMultiplier = 1.0,
                AmbientMultiplier = 1.0,
                TintColor = Color3.new(1, 1, 1),
                ParticleMultiplier = 0, -- No extra particles
            },
            Modifiers = {
                CreatureSpawnMultiplier = 1.0,
                OxygenDrainMultiplier = 1.0,
                RareBonus = 0,
                EpicBonus = 0,
                LegendaryBonus = 0,
            },
            Description = "Clear skies above — perfect diving conditions",
        },
        Stormy = {
            Weight = 15,
            DurationMin = 60,
            DurationMax = 150,
            Lighting = {
                FogMultiplier = 0.5,       -- Darker (fog closer)
                BrightnessMultiplier = 0.7,
                AmbientMultiplier = 0.6,
                TintColor = Color3.fromRGB(100, 120, 150),
                ParticleMultiplier = 1.5,  -- More marine snow
            },
            Modifiers = {
                CreatureSpawnMultiplier = 1.25,
                OxygenDrainMultiplier = 1.3,
                RareBonus = 25,           -- +25% Rare+ spawn rate
                EpicBonus = 15,
                LegendaryBonus = 10,
            },
            Description = "A storm rages above — rough currents and aggressive creatures",
        },
        Bioluminescent = {
            Weight = 10,
            DurationMin = 45,
            DurationMax = 90,
            Lighting = {
                FogMultiplier = 1.2,
                BrightnessMultiplier = 1.1,
                AmbientMultiplier = 1.3,
                TintColor = Color3.fromRGB(150, 100, 255),
                ParticleMultiplier = 3.0,  -- Heavy neon particles
            },
            Modifiers = {
                CreatureSpawnMultiplier = 2.0,
                OxygenDrainMultiplier = 0.9,
                RareBonus = 50,
                EpicBonus = 100,          -- 2x Epic rate
                LegendaryBonus = 100,     -- 2x Legendary rate
            },
            Description = "The sea glows with neon bioluminescence — rare creatures emerge!",
        },
        BloodMoon = {
            Weight = 5,
            DurationMin = 30,
            DurationMax = 60,
            Lighting = {
                FogMultiplier = 0.4,       -- Very dark, red-tinted
                BrightnessMultiplier = 0.5,
                AmbientMultiplier = 0.4,
                TintColor = Color3.fromRGB(255, 100, 100),
                ParticleMultiplier = 2.0,
            },
            Modifiers = {
                CreatureSpawnMultiplier = 3.0,  -- ALL creatures spawn
                OxygenDrainMultiplier = 1.5,
                RareBonus = 100,
                EpicBonus = 150,
                LegendaryBonus = 300,     -- 3x Legendary rate
            },
            Description = "Blood Moon rises — all creatures surface, even the legendary ones!",
        },
    },
}

-- ============================================================
-- Season System
-- ============================================================

EnvironmentConfig.Seasons = {
    {
        Id = "coral",
        DisplayName = "Season of Coral",
        Month = 1,
        Theme = Color3.fromRGB(255, 130, 130), -- Coral pink
        Bonuses = {
            ExtraCoralNodes = true,
            CoralCreatureBonus = 1.5,
        },
        ExclusiveCreatures = {
            { Id = "coral_serpent", DisplayName = "Coral Serpent", Rarity = "Rare", Zone = 1 },
            { Id = "reef_guardian", DisplayName = "Reef Guardian", Rarity = "Epic", Zone = 2 },
        },
        Cosmetics = {
            "Coral Crown",
            "Reef Suit",
            "Coral Rod Skin",
        },
    },
    {
        Id = "deep",
        DisplayName = "Season of the Deep",
        Month = 2,
        Theme = Color3.fromRGB(30, 50, 150), -- Deep blue
        Bonuses = {
            DepthXPBoost = 2.0,
            MidnightZoneBonus = true,
        },
        ExclusiveCreatures = {
            { Id = "abyssal_specter", DisplayName = "Abyssal Specter", Rarity = "Epic", Zone = 3 },
            { Id = "trench_stalker", DisplayName = "Trench Stalker", Rarity = "Legendary", Zone = 4 },
        },
        Cosmetics = {
            "Abyssal Crown",
            "Deep Drifter Suit",
            "Trench Rod Skin",
        },
    },
    {
        Id = "storms",
        DisplayName = "Season of Storms",
        Month = 3,
        Theme = Color3.fromRGB(80, 80, 120), -- Stormy grey
        Bonuses = {
            StormFrequencyDouble = true,
            StormCatchBonus = 1.25,
        },
        ExclusiveCreatures = {
            { Id = "storm_leviathan", DisplayName = "Storm Leviathan", Rarity = "Legendary", Zone = 2 },
            { Id = "lightning_eel", DisplayName = "Lightning Eel", Rarity = "Epic", Zone = 1 },
        },
        Cosmetics = {
            "Storm Crown",
            "Tempest Suit",
            "Lightning Rod Skin",
        },
    },
}

return EnvironmentConfig
