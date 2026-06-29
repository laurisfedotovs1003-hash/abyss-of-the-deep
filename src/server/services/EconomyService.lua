--[[
	EconomyService — Handles dual-currency economy (Credits + Research Points)
	Manages purchases, progression XP, creature selling, and inventory.
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
		
		-- Queries
		GetBalance = Knit.CreateSignal(),
		GetInventory = Knit.CreateSignal(),
		GetShopCatalog = Knit.CreateSignal(),
		GetGearCatalog = Knit.CreateSignal(),
		
		-- Purchases
		PurchaseGear = Knit.CreateSignal(),
		PurchaseShopItem = Knit.CreateSignal(),
		SellCreature = Knit.CreateSignal(),
		
		-- Game pass / developer product redemption
		ProcessReceipt = Knit.CreateSignal(),
	}
}

-- Internal player economy state
local playerEconomy = {} -- { [UserId] = { Credits, ResearchPoints, XP, Level, Inventory{}, ActiveBoosts{}, TotalCreaturesCollected, TotalCreaturesSold } }

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

-- ============================================================
-- Initialize & Teardown
-- ============================================================

function EconomyService:KnitStart()
	print("[EconomyService] Initialized")
end

-- Called by DataStoreManager after loading a profile
function EconomyService:ReloadFromProfile(player)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profileSync = DataStoreManager:GetPlayerProfileSync(player)
	
	local level, remainingXP = CalculateLevel(profileSync.Experience or 0)
	
	playerEconomy[player.UserId] = {
		Credits = profileSync.Credits or Config.Economy.StartingCurrency,
		ResearchPoints = profileSync.ResearchPoints or 0,
		XP = profileSync.Experience or 0,
		Level = profileSync.Level or level,
		Inventory = profileSync.Inventory or {},
		ActiveBoosts = profileSync.ActiveBoosts or {},
		TotalCreaturesCollected = profileSync.TotalCreaturesCollected or 0,
		TotalCreaturesSold = profileSync.TotalCreaturesSold or 0,
	}
	
	-- Send initial update to client
	self:FireEconomyUpdate(player)
	print(string.format("[EconomyService] Loaded economy for %s (%d): ₡%d, ◎%d, Lv.%d",
		player.Name, player.UserId, playerEconomy[player.UserId].Credits,
		playerEconomy[player.UserId].ResearchPoints, playerEconomy[player.UserId].Level))
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
	data.TotalCreaturesCollected = (data.TotalCreaturesCollected or 0) + 0 -- placeholder
	
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
	
	if data.Credits < amount then
		return false
	end
	
	data.Credits -= amount
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	return true
end

function EconomyService:SpendResearchPoints(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return false end
	
	if data.ResearchPoints < amount then
		return false
	end
	
	data.ResearchPoints -= amount
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	return true
end

function EconomyService:AddXP(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end
	
	data.XP += amount
	data.Level, _ = CalculateLevel(data.XP)
	
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
		XP = data.XP,
		Level = data.Level,
		XPNeeded = GetXPForLevel(data.Level),
		Inventory = data.Inventory,
		ActiveBoosts = data.ActiveBoosts,
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
			-- Refund on failure
			self:AddCredits(player, gear.Price)
			return result
		end
	end
	
	self:MarkDirty(player)
	self:FireEconomyUpdate(player)
	
	-- Award Research Points for major milestone
	self:AddResearchPoints(player, gearTier * 2)
	
	return {
		success = true,
		tier = gearTier,
		name = gear.Name,
	}
end

-- ============================================================
-- Shop Item Purchase
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
	
	-- Check if item has a ResearchPointPrice alternative
	if currencyType == "Credits" and itemDef.ResearchPointPrice and data.ResearchPoints >= itemDef.ResearchPointPrice then
		-- Allow paying with Research Points instead if player chooses
		currencyType = "ResearchPoints"
		totalPrice = itemDef.ResearchPointPrice * quantity
	end
	
	if not self:CanAfford(player, totalPrice, currencyType) then
		return { success = false, reason = "Not enough " .. currencyType }
	end
	
	if not self:SpendCurrency(player, totalPrice, currencyType) then
		return { success = false, reason = "Transaction failed" }
	end
	
	-- Apply item effects or add to inventory
	if itemDef.Category == "Consumable" then
		if not data.Inventory then data.Inventory = {} end
		data.Inventory[itemKey] = (data.Inventory[itemKey] or 0) + quantity
		
		self.Client:Get("InventoryUpdated"):Fire(player, {
			inventory = data.Inventory,
			itemKey = itemKey,
			newCount = data.Inventory[itemKey],
		})
		
	elseif itemDef.Category == "Boost" then
		if not data.ActiveBoosts then data.ActiveBoosts = {} end
		table.insert(data.ActiveBoosts, {
			effect = itemDef.Effect,
			expiresAt = os.time() + itemDef.EffectValue,
			itemKey = itemKey,
		})
		
	elseif itemDef.Category == "Decoration" or itemDef.ModuleType then
		-- Decoration is handled by BaseBuildingService; mark as inventory
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
	-- This integrates with Roblox's ProcessReceipt callback
	
	local data = playerEconomy[player.UserId]
	if not data then return { success = false, reason = "Player not found" } end
	
	if receiptData.receiptType == "GamePass" then
		-- Game pass redemption logic
		if receiptData.id == Config.GamePasses.OxygenBooster then
			data.Inventory = data.Inventory or {}
			data.Inventory.PermanentOxygenBoost = true
			
		elseif receiptData.id == Config.GamePasses.SpeedDiver then
			data.Inventory = data.Inventory or {}
			data.Inventory.PermanentSpeedBoost = true
			
		elseif receiptData.id == Config.GamePasses.ExpandedCollection then
			-- Handled elsewhere via DataStore profile
			local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
			DataStoreManager:UpdateProfile(player, function(profile)
				profile.CollectionSlots = 400
			end)
			
		elseif receiptData.id == Config.GamePasses.ResearchPointsPack then
			self:AddResearchPoints(player, 25)
		end
		
	elseif receiptData.receiptType == "DeveloperProduct" then
		-- Developer product redemption
		local productMap = {
			[Config.DeveloperProducts.Credits_500] = { Credits = 500 },
			[Config.DeveloperProducts.Credits_2000] = { Credits = 2000 },
			[Config.DeveloperProducts.Credits_10000] = { Credits = 10000 },
			[Config.DeveloperProducts.ResearchPoints_50] = { ResearchPoints = 50 },
			[Config.DeveloperProducts.ResearchPoints_250] = { ResearchPoints = 250 },
			[Config.DeveloperProducts.StarterPack] = { Credits = 200, ResearchPoints = 10, inventory = { OxygenTank = 3, RareBait = 2 } },
		}
		
		local reward = productMap[receiptData.id]
		if reward then
			if reward.Credits then
				data.Credits += reward.Credits
			end
			if reward.ResearchPoints then
				data.ResearchPoints += reward.ResearchPoints
			end
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
	if not data then return { Credits = Config.Economy.StartingCurrency, ResearchPoints = 0, XP = 0, Level = 1 } end
	
	return {
		Credits = data.Credits,
		ResearchPoints = data.ResearchPoints,
		XP = data.XP,
		Level = data.Level,
		XPNeeded = GetXPForLevel(data.Level),
	}
end

function EconomyService.Client:GetInventory(player)
	local self = EconomyService
	local data = playerEconomy[player.UserId]
	if not data then return { inventory = {} } end
	
	return { inventory = data.Inventory or {} }
end

function EconomyService.Client:GetShopCatalog(player)
	local self = EconomyService
	local catalog = {}
	
	-- Gear upgrades
	for i, gear in ipairs(Config.DivingGear) do
		table.insert(catalog, {
			type = "gear",
			tier = gear.Tier,
			name = gear.Name,
			description = gear.Description,
			price = gear.Price,
			currencyType = gear.PriceCurrency,
			maxDepth = gear.MaxDepth,
			oxygenBonus = gear.OxygenBonus,
			speedModifier = gear.SpeedModifier,
		})
	end
	
	-- Shop items
	for key, item in pairs(Config.ShopItems) do
		table.insert(catalog, {
			type = "item",
			key = key,
			category = item.Category,
			name = item.Name,
			description = item.Description,
			price = item.Price,
			currencyType = item.PriceCurrency,
			researchPointPrice = item.ResearchPointPrice,
			effect = item.Effect,
			maxStack = item.MaxStack,
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

return EconomyService