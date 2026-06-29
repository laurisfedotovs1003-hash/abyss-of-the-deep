--[[
	CollectionService — Tracks player creature collection, journal, and progression
	Manages the collection database and progression milestones.
	Integrated with DataStoreManager for persistence and CreatureService for tracking first discoveries.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local CollectionService = Knit.CreateService {
	Name = "CollectionService",
	Client = {
		CollectionUpdated = Knit.CreateSignal(),
		GetCollection = Knit.CreateSignal(),
		GetCollectionProgress = Knit.CreateSignal(),
		CreatureDiscovered = Knit.CreateSignal(), -- First-time discovery notification
	}
}

-- Creature definitions from CreatureService (shared reference)
local CREATURE_DEFS = {
	["clownfish"] = { Layer = 1 }, ["parrotfish"] = { Layer = 1 }, ["seahorse"] = { Layer = 1 },
	["angelfish"] = { Layer = 1 }, ["tropical_ray"] = { Layer = 1 }, ["sea_turtle"] = { Layer = 1 },
	["manta_ray"] = { Layer = 1 },
	["lanternfish"] = { Layer = 2 }, ["squid"] = { Layer = 2 }, ["hatchetfish"] = { Layer = 2 },
	["vampire_squid"] = { Layer = 2 }, ["jellyfish_glowing"] = { Layer = 2 },
	["barreleye"] = { Layer = 2 }, ["dragonfish"] = { Layer = 2 },
	["anglerfish"] = { Layer = 3 }, ["gulper_eel"] = { Layer = 3 }, ["viperfish"] = { Layer = 3 },
	["giant_squid"] = { Layer = 3 }, ["colossal_jelly"] = { Layer = 3 },
	["abyssal_grenadier"] = { Layer = 4 }, ["dumbo_octopus"] = { Layer = 4 },
	["giant_isopod"] = { Layer = 4 }, ["abyssal_angler"] = { Layer = 4 },
	["deep_sea_dragon"] = { Layer = 4 },
	["trench_eel"] = { Layer = 5 }, ["abyssal_serpent"] = { Layer = 5 },
	["void_jelly"] = { Layer = 5 }, ["leviathan"] = { Layer = 5 }, ["ancient_one"] = { Layer = 5 },
}

-- ============================================================
-- Initialize
-- ============================================================

function CollectionService:KnitStart()
	print("[CollectionService] Initialized")
end

function CollectionService:PlayerRemoving(player)
	-- State is stored in DataStore, no cleanup needed
end

-- ============================================================
-- Add Creature to Collection
-- Returns: isFirstDiscovery (boolean)
-- ============================================================

function CollectionService:AddCreatureToCollection(player, creatureData)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	
	local isFirstDiscovery = not DataStoreManager:HasDiscoveredCreature(player, creatureData.id)
	
	-- Update the creature collection in DataStore
	DataStoreManager:UpdateProfile(player, function(profile)
		if not profile.CreatureCollection then
			profile.CreatureCollection = {}
		end
		
		-- Find existing entry
		local existingIndex = nil
		for i, entry in ipairs(profile.CreatureCollection) do
			if entry.Id == creatureData.id then
				existingIndex = i
				break
			end
		end
		
		if existingIndex then
			-- Increment count
			local entry = profile.CreatureCollection[existingIndex]
			entry.Count = (entry.Count or 1) + 1
			entry.TotalWeight = (entry.TotalWeight or 0) + (creatureData.weight or 0)
		else
			-- New creature entry
			table.insert(profile.CreatureCollection, {
				Id = creatureData.id,
				DisplayName = creatureData.displayName,
				Rarity = creatureData.rarity,
				IsShiny = creatureData.isShiny or false,
				Weight = creatureData.weight or 0,
				Size = creatureData.size or 1,
				Count = 1,
				TotalWeight = creatureData.weight or 0,
				DateCollected = os.time(),
				LayerFound = CREATURE_DEFS[creatureData.id] and CREATURE_DEFS[creatureData.id].Layer or 1,
			})
		end
		
		-- Track total stats
		profile.TotalCreaturesCollected = (profile.TotalCreaturesCollected or 0) + 1
	end)
	
	-- Mark creature as globally discovered
	if isFirstDiscovery then
		DataStoreManager:MarkCreatureDiscovered(player, creatureData.id)
		
		-- Award Research Points for discovery
		local EconomyService = Knit.GetService("EconomyService")
		if EconomyService then
			local rarityConfig = Config.CreatureRarity[creatureData.rarity]
			if rarityConfig and rarityConfig.ResearchPointsOnFirstDiscovery then
				EconomyService:AddResearchPoints(player, rarityConfig.ResearchPointsOnFirstDiscovery)
			end
		end
		
		-- Fire discovery notification
		self.Client:Get("CreatureDiscovered"):Fire(player, {
			id = creatureData.id,
			displayName = creatureData.displayName,
			rarity = creatureData.rarity,
		})
	end
	
	-- Fire collection update
	local profileSync = DataStoreManager:GetPlayerProfileSync(player)
	local totalCreatures = self:GetTotalCreatureCount()
	local totalCollected = #(profileSync.CreatureCollection or {})
	
	self.Client:Get("CollectionUpdated"):Fire(player, {
		totalUnique = totalCollected,
		totalPossible = totalCreatures,
		completion = totalCreatures > 0 and totalCollected / totalCreatures or 0,
		isNewDiscovery = isFirstDiscovery,
	})
	
	return isFirstDiscovery
end

-- ============================================================
-- Collection Queries
-- ============================================================

function CollectionService:GetTotalCreatureCount()
	local count = 0
	for _, defs in pairs(CREATURE_DEFS) do
		count += 1
	end
	return count
end

-- ============================================================
-- Client Methods
-- ============================================================

function CollectionService.Client:GetCollection(player)
	local self = CollectionService
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	
	return {
		entries = profile.CreatureCollection or {},
		totalUnique = #(profile.CreatureCollection or {}),
		totalPossible = self:GetTotalCreatureCount(),
	}
end

function CollectionService.Client:GetCollectionProgress(player)
	local self = CollectionService
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	local totalCreatures = self:GetTotalCreatureCount()
	local collected = #(profile.CreatureCollection or {})
	
	return {
		totalUnique = collected,
		totalPossible = totalCreatures,
		completion = totalCreatures > 0 and collected / totalCreatures or 0,
	}
end

return CollectionService