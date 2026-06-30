--[[
	Types.lua — Type definitions and schemas for Abyss of the Deep
	Used to enforce data structures across client and server.
	This schema is used by ProfileService for data persistence.
]]

local Types = {}

-- ============================================================
-- Player Profile Schema
-- Used by ProfileTemplate.lua and DataStoreManager.lua
-- ============================================================

--[[
	PlayerProfile = {
		-- Identification
		UserId: number,
		DisplayName: string,
		
		-- Progression
		Experience: number,
		Level: number,
		Currency: number,			-- Credits (primary currency)
		ResearchPoints: number,		-- Premium currency
		TotalDives: number,
		
		-- Equipment
		CurrentGearTier: number,
		OwnedGearTiers: {number},
		MaxDepthReached: number,
		
		-- Inventory & Boosts
		Inventory: { [string]: number },		-- Consumable item counts
		ActiveBoosts: { BoostEntry },
		
		-- Collection
		CreatureCollection: {CreatureEntry},
		CollectionSlots: number,
		DiscoveredZones: {number},				-- Zone indices discovered
		DiscoveredCreatureIds: {string},		-- Creature IDs discovered
		
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

-- ============================================================
-- Creature Entry Schema
-- ============================================================

--[[
	CreatureEntry = {
		Id: string,
		DisplayName: string,
		Rarity: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary",
		DepthLayer: number,			-- Which depth layer it's found in (1-5)
		Size: number,				-- 1-5 scale for collection display
		Weight: number,				-- Weight in kg
		IsShiny: boolean,			-- Alternate coloration variant
		DateCollected: number,		-- os.time() when caught
		TimesViewed: number,		-- Times player inspected it
		Count: number,				-- How many of this species caught
		TotalWeight: number,		-- Cumulative weight of all catches
		LayerFound: number,			-- Depth layer where first found
	}
]]

-- ============================================================
-- Base Module Schema
-- ============================================================

--[[
	BaseModule = {
		Id: string,
		Type: "Habitat" | "Greenhouse" | "Lab" | "DefenseTurret" | "Decoration",
		Position: { X: number, Y: number, Z: number },
		Orientation: { number, number, number, number },
		Tier: number,				-- Upgrade level (1-3)
		Health: number,
		IsPowered: boolean,
		PlacedAt: number,			-- os.time()
		ModuleName: string,			-- For decorations: item key
	}
]]

-- ============================================================
-- Boost Entry Schema
-- ============================================================

--[[
	BoostEntry = {
		effect: string,				-- "XPBooster" | "CatchBoost" | "SpeedBoost"
		expiresAt: number,			-- os.time() when boost expires
		itemKey: string,			-- Original shop item key
	}
]]

-- ============================================================
-- Network Event Definitions
-- ============================================================

Types.NetworkEvents = {
	-- Client -> Server
	RequestDive = "Abyss_RequestDive",
	Surface = "Abyss_Surface",
	UseOxygenTank = "Abyss_UseOxygenTank",
	AttemptCatch = "Abyss_AttemptCatch",
	SellCreature = "Abyss_SellCreature",
	PlaceBaseModule = "Abyss_PlaceBaseModule",
	RemoveBaseModule = "Abyss_RemoveBaseModule",
	UpgradeGear = "Abyss_UpgradeGear",
	UpgradeModule = "Abyss_UpgradeModule",
	PurchaseItem = "Abyss_PurchaseItem",
	PurchaseGear = "Abyss_PurchaseGear",
	ReportDepth = "Abyss_ReportDepth",
	
	-- Server -> Client
	OxygenUpdate = "Abyss_OxygenUpdate",
	DepthUpdate = "Abyss_DepthUpdate",
	PressureWarning = "Abyss_PressureWarning",
	CreatureSpawned = "Abyss_CreatureSpawned",
	CreatureCaught = "Abyss_CreatureCaught",
	CollectionUpdate = "Abyss_CollectionUpdate",
	BaseSync = "Abyss_BaseSync",
	EconomyUpdate = "Abyss_EconomyUpdate",
	InventoryUpdate = "Abyss_InventoryUpdate",
	GameMessage = "Abyss_GameMessage",
	ZoneTransition = "Abyss_ZoneTransition",
	FirstDiscovery = "Abyss_FirstDiscovery",
}

-- ============================================================
-- Enum-like constants
-- ============================================================

Types.GameState = {
	Menu = "Menu",
	Diving = "Diving",
	BaseBuilding = "BaseBuilding",
	CollectionView = "CollectionView",
	Shop = "Shop",
	Settings = "Settings",
}

Types.CatchResult = {
	Success = "Success",
	Failed = "Failed",
	Escaped = "Escaped",
	TooDeep = "TooDeep",
	NoOxygen = "NoOxygen",
	NoBait = "NoBait",
}

Types.ModuleType = {
	Habitat = "Habitat",
	Greenhouse = "Greenhouse",
	Lab = "Lab",
	DefenseTurret = "DefenseTurret",
	Decoration = "Decoration",
}

Types.Rarity = {
	Common = "Common",
	Uncommon = "Uncommon",
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
}

-- ============================================================
-- Currency Type Constants
-- ============================================================

Types.CurrencyType = {
	Credits = "Credits",
	ResearchPoints = "ResearchPoints",
}

return Types