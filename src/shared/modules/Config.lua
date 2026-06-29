--[[
	Config.lua — Shared game configuration constants
	Used by both client and server via Knit shared module system.
]]

local Config = {}

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
		Description = "Warm, bright waters teeming with colorful reef fish"
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
		Description = "Fading light, strange shapes begin to emerge from the dark"
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
		Description = "Total darkness — bioluminescence is the only light"
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
		Description = "The abyss — ancient creatures dwell in the crushing dark"
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
		Description = "The deepest places on Earth — few have ever returned"
	}
}

-- ============================================================
-- Player Settings
-- ============================================================

Config.Player = {
	MaxOxygen = 100,
	BaseSwimSpeed = 16,			-- Roblox studs/second
	SprintMultiplier = 1.6,
	OxygenRefillRate = 15,		-- Oxygen per second at surface
	OxygenCriticalThreshold = 20, -- Below this, warning effects activate
	BaseHealth = 100,
	PressureDamageInterval = 3,	-- Seconds between pressure damage ticks
	PressureDamagePerLevel = 5,	-- Damage per pressure level exceeded
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
		Price = 0,				-- Free starter gear
		Description = "Standard snorkeling equipment — surface only"
	},
	{
		Name = "Scuba Kit",
		Tier = 2,
		MaxDepth = 1000,
		OxygenBonus = 50,
		SpeedModifier = 1.1,
		Price = 150,
		Description = "Tank and regulator — reach the Twilight Zone"
	},
	{
		Name = "Advanced Dive Suit",
		Tier = 3,
		MaxDepth = 4000,
		OxygenBonus = 125,
		SpeedModifier = 1.2,
		Price = 500,
		Description = "Pressure-resistant suit with enhanced mobility"
	},
	{
		Name = "Bathysphere",
		Tier = 4,
		MaxDepth = 6000,
		OxygenBonus = 250,
		SpeedModifier = 0.9,
		Price = 1500,
		Description = "Heavy submersible — protects against extreme pressure"
	},
	{
		Name = "Abyssal Exosuit",
		Tier = 5,
		MaxDepth = 11000,
		OxygenBonus = 500,
		SpeedModifier = 1.4,
		Price = 5000,
		Description = "Cutting-edge exploration suit — nothing is out of reach"
	}
}

-- ============================================================
-- Creature Rarity Configuration
-- ============================================================

Config.CreatureRarity = {
	Common = {
		Weight = 50,
		Color = Color3.fromRGB(180, 180, 180),	-- Gray
		XPMultiplier = 1,
		SellPriceMin = 5,
		SellPriceMax = 15,
	},
	Uncommon = {
		Weight = 30,
		Color = Color3.fromRGB(30, 200, 80),	-- Green
		XPMultiplier = 2,
		SellPriceMin = 20,
		SellPriceMax = 50,
	},
	Rare = {
		Weight = 15,
		Color = Color3.fromRGB(30, 144, 255),	-- Blue
		XPMultiplier = 4,
		SellPriceMin = 60,
		SellPriceMax = 200,
	},
	Epic = {
		Weight = 4,
		Color = Color3.fromRGB(180, 0, 255),	-- Purple
		XPMultiplier = 8,
		SellPriceMin = 250,
		SellPriceMax = 800,
	},
	Legendary = {
		Weight = 1,
		Color = Color3.fromRGB(255, 180, 0),	-- Gold
		XPMultiplier = 16,
		SellPriceMin = 1000,
		SellPriceMax = 5000,
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
	BaseBuildingCosts = {
		Habitat = {Scrap = 50, Crystal = 10},
		Greenhouse = {Scrap = 30, Crystal = 20},
		Lab = {Scrap = 80, Crystal = 40},
		DefenseTurret = {Scrap = 60, Crystal = 15},
	},
}

-- ============================================================
-- Game Pass IDs (set these after publishing)
-- ============================================================

Config.GamePasses = {
	OxygenBooster = 0,			-- +100 base oxygen capacity
	SpeedDiver = 0,				-- +20% swim speed
	ExpandedCollection = 0,		-- Double collection slots
	AbyssalPass = 0,			-- Access to exclusive trench content
}

-- ============================================================
-- Developer Product IDs (set these after publishing)
-- ============================================================

Config.DeveloperProducts = {
	OxygenRefillPack = 0,		-- Consumable oxygen refill bundle
	BaitPack = 0,				-- Rare bait bundle
	DecorativeBundle = 0,		-- Base decoration items
	XPBooster = 0,				-- 2x XP for 1 hour
}

-- ============================================================
-- Analytics Tags
-- ============================================================

Config.Analytics = {
	Enabled = true,
	SessionTimeout = 300,		-- Seconds of inactivity to end session
	EventPrefix = "Abyss_",
}

return Config