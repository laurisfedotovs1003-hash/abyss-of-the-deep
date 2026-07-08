--[[
	ToolService — Server-side tool logic for Fishing Rod, Harvest Tool, etc.
	Validates tool actions, manages rod tiers, processes harvest results.
	Integrates with CreatureService, EconomyService, and DataStoreManager.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local ToolService = Knit.CreateService {
	Name = "ToolService",
	Client = {
		-- Fishing
		CastLine = Knit.CreateSignal(),
		FishBite = Knit.CreateSignal(),
		FishResult = Knit.CreateSignal(),
		
		-- Harvest
		HarvestResult = Knit.CreateSignal(),
		HarvestNode = Knit.CreateSignal(),
		
		-- Tool equip state
		ToolEquipped = Knit.CreateSignal(),
		
		-- Game message
		GameMessage = Knit.CreateSignal(),
	}
}

-- ============================================================
-- Configuration
-- ============================================================

local ROD_TIERS = {
	Basic = { BiteTimeMin = 3, BiteTimeMax = 8, CatchBonus = 1.0, Price = 0 },
	Advanced = { BiteTimeMin = 4, BiteTimeMax = 12, CatchBonus = 1.15, Price = 200 },
	Master = { BiteTimeMin = 5, BiteTimeMax = 15, CatchBonus = 1.35, Price = 800 },
	Legendary = { BiteTimeMin = 6, BiteTimeMax = 18, CatchBonus = 1.5, Price = 3000 },
}

local ZONE_DIFFICULTY = {
	[1] = { Name = "Sunlight", BiteMult = 1.0, CatchMult = 1.0 },
	[2] = { Name = "Twilight", BiteMult = 0.85, CatchMult = 0.9 },
	[3] = { Name = "Midnight", BiteMult = 0.7, CatchMult = 0.8 },
	[4] = { Name = "Abyssal", BiteMult = 0.55, CatchMult = 0.65 },
	[5] = { Name = "Trenches", BiteMult = 0.4, CatchMult = 0.5 },
}

-- Active fishing sessions: { [playerUserId] = { rodTier, castAt, reelWindow, zoneIndex, lineCastId } }
local activeFishing = {}

-- ============================================================
-- Initialize
-- ============================================================

function ToolService:KnitStart()
	print("[ToolService] Initialized — Player tools ready")
end

-- ============================================================
-- FISHING ROD
-- ============================================================

-- Client calls this to start casting
function ToolService.Client:CastLine(player, rodTier)
	local self = ToolService
	local userId = player.UserId
	
	-- Check if already fishing
	if activeFishing[userId] then
		return { success = false, reason = "Already fishing!" }
	end
	
	-- Validate rod tier
	local tierConfig = ROD_TIERS[rodTier]
	if not tierConfig then
		tierConfig = ROD_TIERS.Basic
	end
	
	-- Get current depth zone
	local DepthService = Knit.GetService("DepthService")
	local depth = DepthService and DepthService:GetPlayerDepth(player) or 0
	local zoneIndex = Util.DepthToLayerIndex(depth)
	local zone = ZONE_DIFFICULTY[zoneIndex] or ZONE_DIFFICULTY[1]
	
	-- Calculate bite timer (randomized within tier range, multiplied by zone difficulty)
	local biteTime = math.random(tierConfig.BiteTimeMin * 10, tierConfig.BiteTimeMax * 10) / 10
	biteTime = biteTime / zone.BiteMult
	
	-- Create fishing session
	activeFishing[userId] = {
		rodTier = rodTier,
		castAt = os.time(),
		biteAt = os.time() + biteTime,
		reelWindow = 1.5, -- Seconds to react when bite happens
		zoneIndex = zoneIndex,
		tierConfig = tierConfig,
		zoneConfig = zone,
		hasBitten = false,
	}
	
	-- Send success back to client
	self.Client:Get("CastLine"):Fire(player, {
		success = true,
		biteTime = biteTime,
		zoneName = zone.Name,
	})
	
	print(string.format("[ToolService] %s cast line (Tier: %s, Zone: %s, Bite in %.1fs)",
		player.Name, rodTier, zone.Name, biteTime))
	
	return { success = true, biteTime = biteTime }
end

-- Server check — called by client when fish bites (polling or event)
function ToolService.Client:CheckBite(player)
	local self = ToolService
	local session = activeFishing[player.UserId]
	
	if not session then
		return { bite = false, reason = "Not fishing" }
	end
	
	local now = os.time()
	
	if not session.hasBitten and now >= session.biteAt then
		-- FISH BITES! Start the reel window
		session.hasBitten = true
		session.reelDeadline = now + session.reelWindow
		
		self.Client:Get("FishBite"):Fire(player, {
			bite = true,
			reelWindow = session.reelWindow,
			zoneName = session.zoneConfig.Name,
		})
		
		return { bite = true, reelWindow = session.reelWindow }
	end
	
	if session.hasBitten and now > session.reelDeadline then
		-- Missed the catch window
		activeFishing[player.UserId] = nil
		self.Client:Get("FishResult"):Fire(player, {
			result = "Missed",
			reason = "The fish got away!",
		})
		return { bite = false, result = "Missed", reason = "Fish got away" }
	end
	
	return { bite = false, waiting = true }
end

-- Client calls this to reel in the catch
function ToolService.Client:ReelIn(player)
	local self = ToolService
	local session = activeFishing[player.UserId]
	
	if not session then
		return { success = false, reason = "Not fishing" }
	end
	
	-- Check if we're in the reel window
	local now = os.time()
	if not session.hasBitten then
		return { success = false, reason = "No fish on the line yet!" }
	end
	
	if now > session.reelDeadline then
		activeFishing[player.UserId] = nil
		return { success = false, reason = "Too late!", result = "Missed" }
	end
	
	-- Success! Determine what was caught
	activeFishing[player.UserId] = nil
	
	-- Use CreatureService to roll an encounter with zone and rod bonuses
	local CreatureService = Knit.GetService("CreatureService")
	if not CreatureService then
		return { success = false, reason = "System unavailable" }
	end
	
	local creatureDef, isShiny = CreatureService:RollEncounter(session.zoneIndex)
	if not creatureDef then
		return { success = false, reason = "Nothing on the line..." }
	end
	
	-- Apply rod tier catch bonus
	local catchBonus = session.tierConfig.CatchBonus * session.zoneConfig.CatchMult
	local rarityConfig = Config.CreatureRarity[creatureDef.Rarity]
	local baseCatchChance = 0.6
	local rarityMod = rarityConfig.Weight / 50
	local finalChance = math.min(baseCatchChance * rarityMod * catchBonus, 0.95)
	
	local success = math.random() <= finalChance
	
	if success then
		-- Creature caught! Add to collection and award rewards
		local EconomyService = Knit.GetService("EconomyService")
		local CollectionService = Knit.GetService("CollectionService")
		
		local sellPrice = math.random(rarityConfig.SellPriceMin, rarityConfig.SellPriceMax)
		if isShiny then
			sellPrice = sellPrice * 3
		end
		
		local xpReward = rarityConfig.XPMultiplier * Config.Economy.XPPerCreatureCaptured
		
		if CollectionService then
			CollectionService:AddCreatureToCollection(player, {
				id = creatureDef.Id,
				displayName = creatureDef.DisplayName,
				rarity = creatureDef.Rarity,
				isShiny = isShiny,
				weight = creatureDef.Weight,
				size = creatureDef.Size,
			})
		end
		
		if EconomyService then
			EconomyService:AddCredits(player, sellPrice)
			EconomyService:AddXP(player, xpReward)
		end
		
		self.Client:Get("FishResult"):Fire(player, {
			result = "Caught",
			creature = {
				id = creatureDef.Id,
				displayName = creatureDef.DisplayName,
				rarity = creatureDef.Rarity,
				rarityColor = rarityConfig.Color,
				isShiny = isShiny,
				weight = creatureDef.Weight,
				size = creatureDef.Size,
			},
			sellPrice = sellPrice,
			xpReward = xpReward,
		})
		
		return {
			success = true,
			result = "Caught",
			creature = {
				id = creatureDef.Id, displayName = creatureDef.DisplayName,
				rarity = creatureDef.Rarity, isShiny = isShiny,
			},
			sellPrice = sellPrice, xpReward = xpReward,
		}
	else
		self.Client:Get("FishResult"):Fire(player, {
			result = "Escaped",
			reason = "It slipped away!",
		})
		return { success = false, result = "Escaped", reason = "It slipped away!" }
	end
end

-- ============================================================
-- HARVEST TOOL
-- ============================================================

-- Client calls this when harvesting a resource node
function ToolService.Client:HarvestNode(player, nodeType)
	local self = ToolService
	
	local EconomyService = Knit.GetService("EconomyService")
	if not EconomyService then
		return { success = false, reason = "Economy unavailable" }
	end
	
	local harvestResults = {}
	
	if nodeType == "Scrap" then
		local amount = math.random(3, 8)
		harvestResults = { type = "Scrap", amount = amount }
		-- Scrap is a resource tracked on the DataStore profile
		local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
		DataStoreManager:UpdateProfile(player, function(profile)
			profile.Resources = profile.Resources or { Scrap = 0 }
			profile.Resources.Scrap = (profile.Resources.Scrap or 0) + amount
		end)
		
	elseif nodeType == "Crystal" then
		local amount = math.random(1, 3)
		harvestResults = { type = "Crystal", amount = amount }
		local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
		DataStoreManager:UpdateProfile(player, function(profile)
			profile.Resources = profile.Resources or { Crystal = 0 }
			profile.Resources.Crystal = (profile.Resources.Crystal or 0) + amount
		end)
		
	elseif nodeType == "CreatureEncounter" then
		-- Trigger a creature encounter via CreatureService
		local CreatureService = Knit.GetService("CreatureService")
		if CreatureService then
			local DepthService = Knit.GetService("DepthService")
			local depth = DepthService and DepthService:GetPlayerDepth(player) or 0
			local layerIndex = Util.DepthToLayerIndex(depth)
			CreatureService:SpawnCreatureForPlayer(player, layerIndex)
		end
		harvestResults = { type = "CreatureEncounter", amount = 1 }
		
	else
		return { success = false, reason = "Unknown node type" }
	end
	
	self.Client:Get("HarvestResult"):Fire(player, harvestResults)
	
	return { success = true, results = harvestResults }
end

-- ============================================================
-- Query: Get rod tier info
-- ============================================================

function ToolService:GetRodTierInfo()
	return ROD_TIERS
end

function ToolService:GetRodTier(tierName)
	return ROD_TIERS[tierName] or ROD_TIERS.Basic
end

return ToolService