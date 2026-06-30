--[[
    UIStyles.lua — Design system constants for Abyss of the Deep
    Matches the UI Style Guide v1.0 (deep-sea bioluminescent theme)
]]

local UIStyles = {}

-- ============================================================
-- Color Palette
-- ============================================================

UIStyles.Colors = {
    -- Backgrounds
    DeepOcean = Color3.fromRGB(6, 10, 26),       -- #060A1A
    SurfaceDark = Color3.fromRGB(11, 13, 23),     -- #0B0D17
    CardBG = Color3.fromRGB(15, 23, 42),          -- #0F172A
    Elevated = Color3.fromRGB(26, 29, 54),        -- #1A1D36
    Border = Color3.fromRGB(30, 41, 59),          -- #1E293B

    -- Primary Accents (Bioluminescence)
    Cyan = Color3.fromRGB(0, 229, 255),           -- #00E5FF
    BioGreen = Color3.fromRGB(57, 255, 20),       -- #39FF14
    DeepPurple = Color3.fromRGB(139, 92, 246),    -- #8B5CF6
    ElectricBlue = Color3.fromRGB(59, 130, 246),  -- #3B82F6

    -- Functional Colors
    Gold = Color3.fromRGB(255, 215, 0),           -- #FFD700
    Danger = Color3.fromRGB(255, 107, 107),       -- #FF6B6B
    Warning = Color3.fromRGB(255, 140, 66),       -- #FF8C42
    Success = Color3.fromRGB(34, 197, 94),        -- #22C55E

    -- Text
    TextPrimary = Color3.fromRGB(241, 245, 249),  -- #F1F5F9
    TextSecondary = Color3.fromRGB(148, 163, 184),-- #94A3B8
    TextMuted = Color3.fromRGB(100, 116, 139),    -- #64748B
    TextOnAccent = Color3.fromRGB(6, 10, 26),     -- #060A1A

    -- Rarity Colors (matching Config.CreatureRarity)
    RarityCommon = Color3.fromRGB(180, 180, 180),
    RarityUncommon = Color3.fromRGB(30, 200, 80),
    RarityRare = Color3.fromRGB(30, 144, 255),
    RarityEpic = Color3.fromRGB(180, 0, 255),
    RarityLegendary = Color3.fromRGB(255, 180, 0),
    RarityAnomaly = Color3.fromRGB(255, 50, 50),
}

-- ============================================================
-- Font Settings
-- ============================================================

UIStyles.Fonts = {
    Display = Enum.Font.GothamBlack,       -- Bold, futuristic feel
    Body = Enum.Font.GothamMedium,         -- Clean, readable
    Mono = Enum.Font.SourceSans,           -- For numbers
    Number = Enum.Font.FredokaOne,         -- Rounded numbers for HUD
}

UIStyles.FontSizes = {
    HUDPrimary = 36,       -- Depth number, big currency values
    HUDSmall = 14,         -- Zone name, labels
    SectionTitle = 22,     -- Panel titles
    ItemName = 18,         -- Item card names
    Body = 14,             -- Descriptions
    Small = 12,            -- Captions, tags
    Tiny = 10,             -- Badges, metadata
}

-- ============================================================
-- Sizing & Spacing
-- ============================================================

UIStyles.Spacing = {
    Padding = 16,
    SmallPad = 8,
    LargePad = 24,
    CornerRadius = 12,
    CardRadius = 16,
    RoundRadius = 100,
}

UIStyles.Button = {
    MinTouchSize = 44,
    HUDActionSize = 56,
    PrimaryHeight = 44,
    TabHeight = 36,
}

UIStyles.HUD = {
    SideMargin = 12,
    TopMargin = 16,
    BottomMargin = 16,
    BarWidth = 8,
    MaxBarHeight = 180,
    ButtonClusterSpacing = 12,
}

-- ============================================================
-- Utility Functions
-- ============================================================

function UIStyles.UDim2FromScale(x, y)
    return UDim2.fromScale(x, y)
end

function UIStyles.UDim2FromOffset(x, y)
    return UDim2.fromOffset(x, y)
end

function UIStyles.RarityToColor(rarity)
    local rarityColors = {
        Common = UIStyles.Colors.RarityCommon,
        Uncommon = UIStyles.Colors.RarityUncommon,
        Rare = UIStyles.Colors.RarityRare,
        Epic = UIStyles.Colors.RarityEpic,
        Legendary = UIStyles.Colors.RarityLegendary,
        Anomaly = UIStyles.Colors.RarityAnomaly,
    }
    return rarityColors[rarity] or UIStyles.Colors.TextMuted
end

function UIStyles.DepthZoneColor(zoneName)
    local zoneColors = {
        ["Sunlight Zone"] = UIStyles.Colors.ElectricBlue,
        ["Twilight Zone"] = UIStyles.Colors.Cyan,
        ["Midnight Zone"] = UIStyles.Colors.DeepPurple,
        ["Abyssal Zone"] = UIStyles.Colors.Danger,
        ["Trenches"] = Color3.fromRGB(180, 0, 0),
    }
    return zoneColors[zoneName] or UIStyles.Colors.TextSecondary
end

return UIStyles