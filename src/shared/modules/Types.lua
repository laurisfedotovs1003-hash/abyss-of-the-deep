--[[
	Types.lua — Type definitions and schemas for Abyss of the Deep
	Used to enforce data structures across client and server.
]]

local Types = {}

-- ============================================================
-- Player Profile Schema
-- ============================================================

--[[
	PlayerProfile = {
		UserId: number,
		DisplayName: string,
		
		-- Progression
		Experience: number,
		Level: number,
		Currency: number,
		TotalDives: number,
		
		-- Equipment
		CurrentGearTier: number,
		OwnedGearTiers: {number},
		MaxDepthReached: number,
		
		-- Collection
		CreatureCollection: {CreatureEntry},
		CollectionSlots: number,
		
		-- Base Building
		BaseModules: {BaseModule},
		BaseLocation: Vector3,
		
		-- Stats
		TotalCreaturesCollected: number,
		TotalOxygenUsed: number,
		TotalDistanceTravelled: number,
		TotalPlayTime: number,
		
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
		Id: string,				-- Unique creature ID (e.g., "glowing_jellyfish")
		DisplayName: string,	-- Player-facing name
		Rarity: string,			-- "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
		DepthLayer: number,		-- Which depth layer it's found in (1-5)
		Size: number,			-- 1-5 scale for collection display
		Weight: number,			-- Weight in kg (for display/score)
		IsShiny: boolean,		-- Alternate coloration variant
		DateCollected: number,	-- os.time() when caught
		TimesViewed: number,	-- How many times player has inspected it
	}
]]

-- ============================================================
-- Base Module Schema
-- ============================================================

--[[
	BaseModule = {
		Id: string,
		Type: "Habitat" | "Greenhouse" | "Lab" | "DefenseTurret" | "Decoration",
		Position: Vector3,
		Orientation: CFrame,
		Tier: number,			-- Upgrade level (1-3)
		Health: number,
		IsPowered: boolean,
		PlacedAt: number,		-- os.time()
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
	PlaceBaseModule = "Abyss_PlaceBaseModule",
	UpgradeGear = "Abyss_UpgradeGear",
	PurchaseItem = "Abyss_PurchaseItem",
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
	GameMessage = "Abyss_GameMessage",
	ZoneTransition = "Abyss_ZoneTransition",
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
}

Types.CatchResult = {
	Success = "Success",
	Failed = "Failed",
	Escaped = "Escaped",
	TooDeep = "TooDeep",
	NoOxygen = "NoOxygen",
	NoBait = "NoBait",
}

return Types