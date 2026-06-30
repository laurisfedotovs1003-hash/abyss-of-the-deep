--[[
	EconomyService — Handles dual-currency economy (Credits + Research Points)
	+ Resource economy (Scrap, Crystal) for base building.
	Manages purchases, progression XP, creature selling, inventory, and daily rewards.
	Integrates with DataStoreManager for persistence and other services for validation.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Players = game:GetService("Players")

local EconomyService = Knit.CreateService {
	Name = "EconomyService",
	Client = {
		-- Economy state updates
		EconomyUpdated = Knit.CreateSignal(),
		InventoryUpdated = Knit.CreateSignal(),
		DailyRewardClaimed = Knit.CreateSignal(),

		-- Queries
		GetBalance = Knit.CreateSignal(),
		GetInventory = Knit.CreateSignal(),
		GetShopCatalog = Knit.CreateSignal(),
		GetGearCatalog = Knit.CreateSignal(),
		GetDailyRewardStatus = Knit.CreateSignal(),

		-- Purchases
		PurchaseGear = Knit.CreateSignal(),
		PurchaseShopItem = Knit.CreateSignal(),
		SellCreature = Knit.CreateSignal(),
		ClaimDailyReward = Knit.CreateSignal(),

		-- Game pass / developer product redemption
		ProcessReceipt = Knit.CreateSignal(),
	}
}

-- Internal player economy state
-- { [UserId] = { Credits, ResearchPoints, Scrap, Crystal, XP, Level,
--   Inventory{}, ActiveBoosts{}, PermanentUpgrades{}, 
--   DailyRewardDay, LastDailyClaim, TotalCreaturesCollected, TotalCreaturesSold } }
local playerEconomy = {}

-- ============================================================
-- XP/Level System
-- ============================================================

local function GetXPForLevel(level)
	return math.floor(100 * level * 1.5)
end

local function CalculateLevel(experience)
	local level = 1
	local xpRemaining = experience
	while xpRemaining >= GetXPForLevel(level) do
		xpRemaining = xpRemaining - GetXPForLevel(level)
		level = level + 1
	end
	return level, xpRemaining
end

-- Scaled RP reward: higher levels give more RP
local function GetRPForLevel(level)
	return 5 + math.floor(level / 5)  -- level 1: 5, level 10: 7, level 25: 10, level 50: 15
end

-- ============================================================
-- Initialize & Teardown
-- ============================================================

function EconomyService:KnitStart()
	print("[EconomyService] Initialized with Resources, Daily Rewards, and RP-exclusive items")
end

-- Called by DataStoreManager after loading a profile
function EconomyService:ReloadFromProfile(player)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profileSync = DataStoreManager:GetPlayerProfileSync(player)

	local level, remainingXP = CalculateLevel(profileSync.Experience or 0)

	playerEconomy[player.UserId] = {
		Credits = profileSync.Credits or Config.Economy.StartingCurrency,
		ResearchPoints = profileSync.ResearchPoints or 0,
		Scrap = profileSync.Scrap or 0,
		Crystal = profileSync.Crystal or 0,
		XP = profileSync.Experience or 0,
		Level = profileSync.Level or level,
		Inventory = profileSync.Inventory or {},
		ActiveBoosts = profileSync.ActiveBoosts or {},
		PermanentUpgrades = profileSync.PermanentUpgrades or {},
		DailyRewardDay = profileSync.DailyRewardDay or 1,
		LastDailyClaim = profileSync.LastDailyClaim or 0,
		MilestonesClaimed = profileSync.MilestonesClaimed or {},
		TotalCreaturesCollected = profileSync.TotalCreaturesCollected or 0,
		TotalCreaturesSold = profileSync.TotalCreaturesSold or 0,
	}

	-- Send initial update to client
	self:FireEconomyUpdate(player)
	print(string.format("[EconomyService] Loaded economy for %s (%d): ₡%d, ◎%d, Scrap %d, Crystal %d, Lv.%d",
		player.Name, player.UserId, playerEconomy[player.UserId].Credits,
		playerEconomy[player.UserId].ResearchPoints, playerEconomy[player.UserId].Scrap,
		playerEconomy[player.UserId].Crystal, playerEconomy[player.UserId].Level))
end

function EconomyService:PlayerRemoving(player)
	playerEconomy[player.UserId] = nil
end

-- ============================================================
-- Internal API (called by other services)
-- ============================================================

function EconomyService:GetPlayerData(player)
	return playerEconomy[player.UserId]
end

function EconomyService:AddCredits(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end
	data.Credits += amount
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
end

function EconomyService:AddResearchPoints(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end
	data.ResearchPoints += amount
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
end

function EconomyService:SpendCredits(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return false end
	if data.Credits < amount then return false end
	data.Credits -= amount
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	return true
end

function EconomyService:SpendResearchPoints(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return false end
	if data.ResearchPoints < amount then return false end
	data.ResearchPoints -= amount
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	return true
end

-- ============================================================
-- Resource API (Scrap, Crystal for base building)
-- ============================================================

function EconomyService:AddResource(player, resourceType, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end
	if resourceType == "Scrap" then
		data.Scrap = (data.Scrap or 0) + amount
	elseif resourceType == "Crystal" then
		data.Crystal = (data.Crystal or 0) + amount
	else
		return
	end
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
end

function EconomyService:SpendResource(player, resourceType, amount)
	local data = playerEconomy[player.UserId]
	if not data then return false end
	local current = 0
	if resourceType == "Scrap" then
		current = data.Scrap or 0
	elseif resourceType == "Crystal" then
		current = data.Crystal or 0
	else
		return false
	end
	if current < amount then return false end
	if resourceType == "Scrap" then
		data.Scrap = current - amount
	elseif resourceType == "Crystal" then
		data.Crystal = current - amount
	end
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	return true
end

function EconomyService:CanAffordResources(player, costs)
	-- costs = { Credits = number, Scrap = number, Crystal = number }
	local data = playerEconomy[player.UserId]
	if not data then return false end
	if costs.Credits and data.Credits < costs.Credits then return false end
	if costs.Scrap and (data.Scrap or 0) < costs.Scrap then return false end
	if costs.Crystal and (data.Crystal or 0) < costs.Crystal then return false end
	return true
end

function EconomyService:SpendResources(player, costs)
	if not self:CanAffordResources(player, costs) then return false end
	if costs.Credits then self:SpendCredits(player, costs.Credits) end
	if costs.Scrap then self:SpendResource(player, "Scrap", costs.Scrap) end
	if costs.Crystal then self:SpendResource(player, "Crystal", costs.Crystal) end
	return true
end

-- ============================================================
-- Depth Milestone Rewards
-- ============================================================

function EconomyService:AwardDepthMilestone(player, depth)
	local data = playerEconomy[player.UserId]
	if not data then return end
	if not data.MilestonesClaimed then data.MilestonesClaimed = {} end

	for _, milestone in ipairs(Config.DepthMilestones) do
		if depth >= milestone.depth and not data.MilestonesClaimed[milestone.depth] then
			data.MilestonesClaimed[milestone.depth] = true
			if milestone.credits then self:AddCredits(player, milestone.credits) end
			if milestone.rpReward then self:AddResearchPoints(player, milestone.rpReward) end
			print(string.format("[EconomyService] Depth milestone '%s' awarded to %s", milestone.title, player.Name))
		end
	end
end

-- ============================================================
-- Dive Completion (scaled by max depth, called by DepthService)
-- ============================================================

function EconomyService:AwardDiveCompletion(player, maxDepth)
	local data = playerEconomy[player.UserId]
	if not data then return end

	for _, bonus in ipairs(Config.DiveBonuses) do
		if maxDepth >= bonus.minDepth and maxDepth <= bonus.maxDepth then
			self:AddCredits(player, bonus.bonus)
			print(string.format("[EconomyService] Dive completion: %s — +₡%d", bonus.label, bonus.bonus))
			return bonus.bonus
		end
	end

	-- Fallback for depths beyond max
	self:AddCredits(player, 500)
end

-- ============================================================
-- Daily Reward System
-- ============================================================

function EconomyService:ClaimDailyReward(player)
	local data = playerEconomy[player.UserId]
	if not data then return { success = false, reason = "Player data not found" } end

	if not Config.DailyRewards.Enabled then
		return { success = false, reason = "Daily rewards disabled" }
	end

	local now = os.time()
	local lastClaim = data.LastDailyClaim or 0
	local secondsSinceMidnight = now % 86400
	local todayStart = now - secondsSinceMidnight

	-- Check if already claimed today
	if lastClaim >= todayStart then
		return { success = false, reason = "Already claimed today" }
	end

	local dayIndex = data.DailyRewardDay or 1
	if dayIndex > Config.DailyRewards.StreakLength then
		dayIndex = 1
	end

	-- Find the reward for this day
	local reward = nil
	for _, r in ipairs(Config.DailyRewards.Rewards) do
		if r.day == dayIndex then
			reward = r
			break
		end
	end

	if not reward then
		return { success = false, reason = "No reward configured for this day" }
	end

	-- Award the reward
	if reward.type == "Credits" then
		self:AddCredits(player, reward.amount)
	elseif reward.type == "ResearchPoints" then
		self:AddResearchPoints(player, reward.amount)
	elseif reward.type == "Consumable" then
		if not data.Inventory then data.Inventory = {} end
		data.Inventory[reward.item] = (data.Inventory[reward.item] or 0) + reward.count
	end

	-- Update streak
	data.DailyRewardDay = dayIndex + 1
	data.LastDailyClaim = now

	self:MarkDirty(player)
	self:FireEconomyUpdate(player)

	self.Client:Get("DailyRewardClaimed"):Fire(player, {
		day = dayIndex,
		rewardType = reward.type,
		rewardAmount = reward.amount or reward.count,
		rewardItem = reward.item,
		nextDay = data.DailyRewardDay > Config.DailyRewards.StreakLength and 1 or data.DailyRewardDay,
	})

	return { success = true, day = dayIndex, rewardType = reward.type }
end

-- ============================================================
-- Level Up Rewards (scaled RP + milestone titles)
-- ============================================================

function EconomyService:AddXP(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end

	local oldLevel = data.Level
	data.XP += amount
	data.Level, _ = CalculateLevel(data.XP)

	-- Award RP and check level milestones on level up
	if data.Level > oldLevel then
		local rpReward = GetRPForLevel(data.Level)
		data.ResearchPoints += rpReward

		-- Check level milestone titles
		for _, ms in ipairs(Config.LevelMilestones) do
			if data.Level >= ms.level then
				if not data.Inventory then data.Inventory = {} end
				local titleKey = "title_" .. ms.title
				if not data.Inventory[titleKey] then
					data.Inventory[titleKey] = true
					print(string.format("[EconomyService] %s earned title '%s'", player.Name, ms.title))
				end
			end
		end
	end

	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
end

function EconomyService:MarkDirty(player)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	DataStoreManager:SetProfileDirty(player)
end

function EconomyService:FireEconomyUpdate(player)
	local data = playerEconomy[player.UserId]
	if not data then return end

	self.Client:Get("EconomyUpdated"):Fire(player, {
		Credits = data.Credits,
		ResearchPoints = data.ResearchPoints,
		Scrap = data.Scrap or 0,
		Crystal = data.Crystal or 0,
		XP = data.XP,
		Level = data.Level,
		XPNeeded = GetXPForLevel(data.Level),
		Inventory = data.Inventory,
		ActiveBoosts = data.ActiveBoosts,
		PermanentUpgrades = data.PermanentUpgrades,
	})
end

-- ============================================================
-- Creature Selling
-- ============================================================

function EconomyService:SellCreatureToEconomy(player, creatureData)
	local data = playerEconomy[player.UserId]
	if not data then return { success = false, reason = "Player data not found" } end

	local rarityConfig = Config.CreatureRarity[creatureData.Rarity]
	if not rarityConfig then
		return { success = false, reason = "Invalid creature rarity" }
	end

	if rarityConfig.SellPriceCurrency ~= "Credits" then
		return { success = false, reason = "Cannot sell this creature type" }
	end

	local basePrice = math.random(rarityConfig.SellPriceMin, rarityConfig.SellPriceMax)
	if creatureData.IsShiny then
		basePrice = basePrice * 3
	end

	data.Credits += basePrice
	data.TotalCreaturesSold = (data.TotalCreaturesSold or 0) + 1

	self:MarkDirty(player)
	self:FireEconomyUpdate(player)

	return {
		success = true,
		creditsAwarded = basePrice,
		creatureName = creatureData.DisplayName,
	}
end

-- ============================================================
-- Shop / Purchase Logic
-- ============================================================

function EconomyService:CanAfford(player, price, currencyType)
	local data = playerEconomy[player.UserId]
	if not data then return false end
	if currencyType == "Credits" then
		return data.Credits >= price
	elseif currencyType == "ResearchPoints" then
		return data.ResearchPoints >= price
	end
	return false
end

function EconomyService:SpendCurrency(player, price, currencyType)
	if currencyType == "Credits" then
		return self:SpendCredits(player, price)
	elseif currencyType == "ResearchPoints" then
		return self:SpendResearchPoints(player, price)
	end
	return false
end

-- ============================================================
-- Gear Purchase
-- ============================================================

function EconomyService:PurchaseGear(player, gearTier)
	local data = playerEconomy[player.UserId]
	if not data then return { success = false, reason = "Player data not found" } end

	local gear = Config.DivingGear[gearTier]
	if not gear then
		return { success = false, reason = "Invalid gear tier" }
	end

	-- Check if already owned
	local DepthService = Knit.GetService("DepthService")
	local currentGear = DepthService and DepthService:GetPlayerGearTier(player) or 1

	-- Can only buy the next tier up
	if gearTier ~= currentGear + 1 then
		if gearTier <= currentGear then
			return { success = false, reason = "You already own this gear" }
		else
			return { success = false, reason = "You must purchase previous tiers first" }
		end
	end

	-- Check affordability
	if not self:CanAfford(player, gear.Price, gear.PriceCurrency) then
		return { success = false, reason = "Not enough " .. gear.PriceCurrency }
	end

	-- Spend currency
	if not self:SpendCurrency(player, gear.Price, gear.PriceCurrency) then
		return { success = false, reason = "Transaction failed" }
	end

	-- Apply gear upgrade through DepthService
	if DepthService then
		local result = DepthService:UpgradeGear(player)
		if not result.success then
			self:AddCredits(player, gear.Price) -- Refund on failure
			return result
		end
	end

	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	self:AddResearchPoints(player, gearTier * 2)

	return {
		success = true,
		tier = gearTier,
		name = gear.Name,
	}
end

-- ============================================================
-- Shop Item Purchase (handles Consumables, Bundles, Boosts,
--   PermanentUpgrades, Cosmetics, Companions, Decorations)
-- ============================================================

function EconomyService:PurchaseShopItem(player, itemKey, quantity)
	quantity = quantity or 1

	local data = playerEconomy[player.UserId]
	if not data then return { success = false, reason = "Player data not found" } end

	local itemDef = Config.ShopItems[itemKey]
	if not itemDef then
		return { success = false, reason = "Unknown item" }
	end

	local totalPrice = itemDef.Price * quantity
	local currencyType = itemDef.PriceCurrency or "Credits"

	if not self:CanAfford(player, totalPrice, currencyType) then
		return { success = false, reason = "Not enough " .. currencyType }
	end

	if not self:SpendCurrency(player, totalPrice, currencyType) then
		return { success = false, reason = "Transaction failed" }
	end

	-- Apply item effects
	if itemDef.Category == "Consumable" then
		if not data.Inventory then data.Inventory = {} end
		data.Inventory[itemKey] = (data.Inventory[itemKey] or 0) + quantity
		self.Client:Get("InventoryUpdated"):Fire(player, {
			inventory = data.Inventory, itemKey = itemKey, newCount = data.Inventory[itemKey],
		})

	elseif itemDef.Category == "Bundle" then
		if not data.Inventory then data.Inventory = {} end
		if itemDef.Contains then
			for containedKey, count in pairs(itemDef.Contains) do
				data.Inventory[containedKey] = (data.Inventory[containedKey] or 0) + count
			end
		end
		self.Client:Get("InventoryUpdated"):Fire(player, {
			inventory = data.Inventory, itemKey = itemKey, bundleUnpacked = true,
		})

	elseif itemDef.Category == "Boost" then
		if not data.ActiveBoosts then data.ActiveBoosts = {} end
		table.insert(data.ActiveBoosts, {
			effect = itemDef.Effect, expiresAt = os.time() + itemDef.EffectValue, itemKey = itemKey,
		})

	elseif itemDef.Category == "PermanentUpgrade" then
		if not data.PermanentUpgrades then data.PermanentUpgrades = {} end
		data.PermanentUpgrades[itemDef.Effect] = true

	elseif itemDef.Category == "Cosmetic" then
		if not data.Inventory then data.Inventory = {} end
		local cosmeticKey = "cosmetic_" .. itemKey
		data.Inventory[cosmeticKey] = true

	elseif itemDef.Category == "Companion" then
		if not data.PermanentUpgrades then data.PermanentUpgrades = {} end
		data.PermanentUpgrades[itemDef.Effect] = itemKey

	elseif itemDef.Category == "Decoration" or itemDef.ModuleType then
		if not data.Inventory then data.Inventory = {} end
		local decoKey = "deco_" .. itemKey
		data.Inventory[decoKey] = (data.Inventory[decoKey] or 0) + quantity
	end

	self:MarkDirty(player)
	self:FireEconomyUpdate(player)

	return {
		success = true,
		itemKey = itemKey,
		name = itemDef.Name,
		quantity = quantity,
		currencyType = currencyType,
		totalPrice = totalPrice,
	}
end

-- ============================================================
-- Process Receipt (Roblox purchases)
-- ============================================================

function EconomyService:ProcessReceipt(player, receiptData)
	-- receiptData: { receiptType = "GamePass" | "DeveloperProduct", id = number }

	local data = playerEconomy[player.UserId]
	if not data then return { success = false, reason = "Player not found" } end

	if receiptData.receiptType == "GamePass" then
		if receiptData.id == Config.GamePasses.OxygenBooster then
			data.Inventory = data.Inventory or {}
			data.Inventory.PermanentOxygenBoost = true

		elseif receiptData.id == Config.GamePasses.SpeedDiver then
			data.Inventory = data.Inventory or {}
			data.Inventory.PermanentSpeedBoost = true

		elseif receiptData.id == Config.GamePasses.ExpandedCollection then
			local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
			DataStoreManager:UpdateProfile(player, function(profile)
				profile.CollectionSlots = 400
			end)

		elseif receiptData.id == Config.GamePasses.ResearchPointsPack then
			self:AddResearchPoints(player, 25)

		elseif receiptData.id == Config.GamePasses.VIPStatus then
			if not data.PermanentUpgrades then data.PermanentUpgrades = {} end
			data.PermanentUpgrades.VIP = true
		end

	elseif receiptData.receiptType == "DeveloperProduct" then
		local productMap = {
			[Config.DeveloperProducts.Credits_500] = { Credits = 500 },
			[Config.DeveloperProducts.Credits_2000] = { Credits = 2000 },
			[Config.DeveloperProducts.Credits_10000] = { Credits = 10000 },
			[Config.DeveloperProducts.ResearchPoints_10] = { ResearchPoints = 10 },
			[Config.DeveloperProducts.ResearchPoints_50] = { ResearchPoints = 50 },
			[Config.DeveloperProducts.ResearchPoints_250] = { ResearchPoints = 250 },
			[Config.DeveloperProducts.StarterPack] = { Credits = 200, ResearchPoints = 10, inventory = { OxygenTank = 3, RareBait = 2 } },
		}

		local reward = productMap[receiptData.id]
		if reward then
			if reward.Credits then data.Credits += reward.Credits end
			if reward.ResearchPoints then data.ResearchPoints += reward.ResearchPoints end
			if reward.inventory then
				for itemKey, count in pairs(reward.inventory) do
					data.Inventory = data.Inventory or {}
					data.Inventory[itemKey] = (data.Inventory[itemKey] or 0) + count
				end
			end
		end
	end

	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	return { success = true }
end

-- ============================================================
-- Client-facing methods
-- ============================================================

function EconomyService.Client:GetBalance(player)
	local self = EconomyService
	local data = playerEconomy[player.UserId]
	if not data then
		return { Credits = Config.Economy.StartingCurrency, ResearchPoints = 0, Scrap = 0, Crystal = 0, XP = 0, Level = 1 }
	end
	return {
		Credits = data.Credits,
		ResearchPoints = data.ResearchPoints,
		Scrap = data.Scrap or 0,
		Crystal = data.Crystal or 0,
		XP = data.XP,
		Level = data.Level,
		XPNeeded = GetXPForLevel(data.Level),
	}
end

function EconomyService.Client:GetInventory(player)
	local self = EconomyService
	local data = playerEconomy[player.UserId]
	if not data then return { inventory = {}, permanentUpgrades = {} } end
	return {
		inventory = data.Inventory or {},
		permanentUpgrades = data.PermanentUpgrades or {},
	}
end

function EconomyService.Client:GetDailyRewardStatus(player)
	local self = EconomyService
	local data = playerEconomy[player.UserId]
	if not data then return { day = 1, canClaim = true } end
	local now = os.time()
	local secondsSinceMidnight = now % 86400
	local todayStart = now - secondsSinceMidnight
	return {
		day = data.DailyRewardDay or 1,
		canClaim = (data.LastDailyClaim or 0) < todayStart,
		totalDays = Config.DailyRewards.StreakLength,
		streakProtected = Config.DailyRewards.ResetOnMiss == false,
	}
end

function EconomyService.Client:ClaimDailyReward(player)
	local self = EconomyService
	return self:ClaimDailyReward(player)
end

function EconomyService.Client:GetShopCatalog(player)
	local self = EconomyService
	local catalog = {}

	-- Gear upgrades
	for i, gear in ipairs(Config.DivingGear) do
		table.insert(catalog, {
			type = "gear", tier = gear.Tier, name = gear.Name,
			description = gear.Description, price = gear.Price,
			currencyType = gear.PriceCurrency, maxDepth = gear.MaxDepth,
			oxygenBonus = gear.OxygenBonus, speedModifier = gear.SpeedModifier,
		})
	end

	-- Shop items
	for key, item in pairs(Config.ShopItems) do
		table.insert(catalog, {
			type = "item", key = key, category = item.Category,
			name = item.Name, description = item.Description,
			price = item.Price, currencyType = item.PriceCurrency,
			effect = item.Effect, maxStack = item.MaxStack,
			exclusive = item.Exclusive,
		})
	end

	return { catalog = catalog }
end

function EconomyService.Client:PurchaseGear(player, gearTier)
	local self = EconomyService
	return self:PurchaseGear(player, gearTier)
end

function EconomyService.Client:PurchaseShopItem(player, itemKey, quantity)
	local self = EconomyService
	return self:PurchaseShopItem(player, itemKey, quantity)
end

function EconomyService.Client:SellCreature(player, creatureData)
	local self = EconomyService
	return self:SellCreatureToEconomy(player, creatureData)
end

function EconomyService.Client:ProcessReceipt(player, receiptData)
	local self = EconomyService
	return self:ProcessReceipt(player, receiptData)
end

return EconomyService
