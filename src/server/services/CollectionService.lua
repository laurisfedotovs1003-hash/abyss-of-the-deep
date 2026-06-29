--[[
	CollectionService — Tracks player creature collection, journal, and progress
	Manages the collection database and progression milestones.
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
	}
}

local playerCollections = {} -- { [UserId] = { entries = {}, totalUnique = 0 } }

function CollectionService:KnitStart()
	print("[CollectionService] Initialized")
end

function CollectionService:PlayerAdded(player)
	playerCollections[player.UserId] = {
		entries = {},
		totalUnique = 0,
	}
end

function CollectionService:PlayerRemoving(player)
	playerCollections[player.UserId] = nil
end

function CollectionService:AddCreatureToCollection(player, creatureData)
	local collection = playerCollections[player.UserId]
	if not collection then return end
	
	-- Check if already collected
	local existing = Util.TableFind(collection.entries, function(entry)
		return entry.Id == creatureData.id
	end)
	
	if existing then
		-- Increment count
		existing.Count = (existing.Count or 1) + 1
		existing.TotalWeight = (existing.TotalWeight or 0) + (creatureData.weight or 0)
	else
		-- New creature
		table.insert(collection.entries, {
			Id = creatureData.id,
			DisplayName = creatureData.displayName,
			Rarity = creatureData.rarity,
			IsShiny = creatureData.isShiny or false,
			Weight = creatureData.weight or 0,
			Size = creatureData.size or 1,
			Count = 1,
			TotalWeight = creatureData.weight or 0,
			DateCollected = os.time(),
		})
		collection.totalUnique += 1
	end
	
	-- Calculate progress
	local totalPossibleCreatures = 0
	for _, layerCreatures in ipairs(self:GetAllCreatureDefs()) do
		totalPossibleCreatures += #layerCreatures
	end
	
	self.Client:Get("CollectionUpdated"):Fire(player, {
		totalUnique = collection.totalUnique,
		totalPossible = totalPossibleCreatures,
		completion = collection.totalUnique / totalPossibleCreatures,
	})
end

function CollectionService:GetAllCreatureDefs()
	-- Import creature definitions from CreatureService
	local CreatureService = Knit.GetService("CreatureService")
	-- In practice this would be a shared module; for now return a placeholder
	return {}
end

function CollectionService:HasCreature(player, creatureId)
	local collection = playerCollections[player.UserId]
	if not collection then return false end
	
	return Util.TableFind(collection.entries, function(entry)
		return entry.Id == creatureId
	end) ~= nil
end

function CollectionService.Client:GetCollection(player)
	local self = CollectionService
	local collection = playerCollections[player.UserId]
	return collection or { entries = {}, totalUnique = 0 }
end

function CollectionService.Client:GetCollectionProgress(player)
	local self = CollectionService
	local collection = playerCollections[player.UserId]
	if not collection then return { completion = 0, totalUnique = 0, totalPossible = 0 } end
	
	return {
		totalUnique = collection.totalUnique,
		completion = collection.totalUnique / #self:GetAllCreatureDefs(),
	}
end

return CollectionService