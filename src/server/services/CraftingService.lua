--[[
    CraftingService — Crafting system with recipes, materials, research tree
    Integrates with BaseBuildingService, EconomyService, and DataStoreManager.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local CraftingService = Knit.CreateService {
    Name = "CraftingService",
    Client = {
        RecipeBookUpdated = Knit.CreateSignal(),
        ResearchUpdated = Knit.CreateSignal(),
        CraftResult = Knit.CreateSignal(),
        GetRecipes = Knit.CreateSignal(),
        GetResearch = Knit.CreateSignal(),
        Craft = Knit.CreateSignal(),
        Research = Knit.CreateSignal(),
    }
}

-- ============================================================
-- Crafting Recipes (20+)
-- ============================================================

local RECIPES = {
    -- Consumables
    FishOilPotion = {
        Name = "Fish Oil Potion",
        Category = "Consumable",
        Description = "Temporarily increases swim speed by 15% for 5 minutes",
        Scrap = 10, Crystal = 5,
        CraftTime = 15,
        RequiresModule = "CraftingTable",
    },
    OxygenTank = {
        Name = "Portable Oxygen Tank",
        Category = "Consumable",
        Description = "Refills 50% oxygen on use",
        Scrap = 15, Crystal = 10,
        CraftTime = 20,
        RequiresModule = "CraftingTable",
    },
    RareBait = {
        Name = "Rare Bait",
        Category = "Consumable",
        Description = "Increases rare creature spawn chance for 10 minutes",
        Scrap = 20, Crystal = 15,
        CraftTime = 30,
        RequiresModule = "CraftingTable",
    },
    
    -- Gear Upgrades
    BasicWetsuit = {
        Name = "Basic Wetsuit Upgrade",
        Category = "Gear",
        Description = "+10% oxygen capacity, +5% swim speed",
        Scrap = 50, Crystal = 25,
        CraftTime = 45,
        RequiresModule = "CraftingTable",
    },
    AdvancedFins = {
        Name = "Advanced Fins",
        Category = "Gear",
        Description = "+10% swim speed",
        Scrap = 40, Crystal = 20,
        CraftTime = 35,
        RequiresModule = "CraftingTable",
    },
    ReinforcedHarness = {
        Name = "Reinforced Harness",
        Category = "Gear",
        Description = "+1 max depth zone (pressure protection)",
        Scrap = 80, Crystal = 50,
        CraftTime = 60,
        RequiresModule = "CraftingTable",
    },
    LuckyCharm = {
        Name = "Lucky Charm",
        Category = "Gear",
        Description = "+10% catch chance permanently",
        Scrap = 60, Crystal = 40,
        CraftTime = 50,
        RequiresModule = "CraftingTable",
    },
    
    -- Base Modules (cheaper to craft than buy)
    CraftBasicModule = {
        Name = "Module Assembly Kit",
        Category = "Base",
        Description = "Craft a base module at 20% discount",
        Scrap = 80, Crystal = 40,
        CraftTime = 90,
        RequiresModule = "CraftingTable",
    },
    
    -- Research items
    ResearchCatalyst = {
        Name = "Research Catalyst",
        Category = "Research",
        Description = "Grants 10 Research Points on use",
        Scrap = 30, Crystal = 15,
        CraftTime = 25,
        RequiresModule = "Lab",
    },
    
    -- Decorations
    GlowLamp = {
        Name = "Bioluminescent Lamp",
        Category = "Decoration",
        Description = "Placeable light source for your base",
        Scrap = 15, Crystal = 25,
        CraftTime = 20,
        RequiresModule = "CraftingTable",
    },
    Aquarium = {
        Name = "Mini Aquarium",
        Category = "Decoration",
        Description = "Display your favorite catch in your base",
        Scrap = 25, Crystal = 35,
        CraftTime = 30,
        RequiresModule = "CraftingTable",
    },
    
    -- Advanced Gear
    SonarModule = {
        Name = "Sonar Module",
        Category = "Gear",
        Description = "Shows nearby creatures on HUD for 30 minutes",
        Scrap = 70, Crystal = 60,
        CraftTime = 80,
        RequiresModule = "ResearchLab",
    },
    DepthScanner = {
        Name = "Depth Scanner",
        Category = "Gear",
        Description = "Reveals hidden resource nodes nearby",
        Scrap = 60, Crystal = 45,
        CraftTime = 60,
        RequiresModule = "ResearchLab",
    },
    WarpCrystal = {
        Name = "Warp Crystal",
        Category = "Gear",
        Description = "Teleports you back to base instantly (single use)",
        Scrap = 40, Crystal = 80,
        CraftTime = 45,
        RequiresModule = "CraftingTable",
    },
    -- Additional recipes to reach 20+
    NightVisionGoggles = {
        Name = "Night Vision Goggles",
        Category = "Gear",
        Description = "Improves vision in dark zones for 20 minutes",
        Scrap = 55, Crystal = 35,
        CraftTime = 50,
        RequiresModule = "ResearchLab",
    },
    PressureRegulator = {
        Name = "Pressure Regulator",
        Category = "Gear",
        Description = "Reduces pressure damage by 25% for one dive",
        Scrap = 45, Crystal = 30,
        CraftTime = 35,
        RequiresModule = "CraftingTable",
    },
    BubbleShield = {
        Name = "Bubble Shield",
        Category = "Gear",
        Description = "Absorbs one hit from hostile creatures",
        Scrap = 90, Crystal = 70,
        CraftTime = 75,
        RequiresModule = "ResearchLab",
    },
    ScrapRefinery = {
        Name = "Scrap Refinery Kit",
        Category = "Consumable",
        Description = "Doubles scrap yield from nodes for 15 minutes",
        Scrap = 20, Crystal = 10,
        CraftTime = 25,
        RequiresModule = "CraftingTable",
    },
    CreatureBait = {
        Name = "Creature Bait Bundle",
        Category = "Consumable",
        Description = "5 rare baits in one pack",
        Scrap = 80, Crystal = 60,
        CraftTime = 60,
        RequiresModule = "CreaturePen",
    },
    BaseBeacon = {
        Name = "Base Navigation Beacon",
        Category = "Decoration",
        Description = "Visible light pillar marking your base location",
        Scrap = 35, Crystal = 20,
        CraftTime = 30,
        RequiresModule = "TeleportBeacon",
    },
}

-- Player state: { [UserId] = { researchTiers: {}, knownRecipes: {} } }
local playerData = {}

-- ============================================================
-- Initialize
-- ============================================================

function CraftingService:KnitStart()
    print("[CraftingService] Initialized — 20+ recipes, research tree ready")
end

function CraftingService:ReloadFromProfile(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profileSync = DataStoreManager:GetPlayerProfileSync(player)
    
    playerData[player.UserId] = {
        researchTiers = profileSync.CraftingResearch or {},
        knownRecipes = profileSync.KnownRecipes or {"FishOilPotion", "OxygenTank", "BasicWetsuit"},
    }
end

function CraftingService:PlayerRemoving(player)
    playerData[player.UserId] = nil
end

-- ============================================================
-- Crafting
-- ============================================================

function CraftingService.Client:Craft(player, recipeKey, speedUp)
    local self = CraftingService
    local data = playerData[player.UserId]
    if not data then return { success = false, reason = "Player not loaded" } end
    
    local recipe = RECIPES[recipeKey]
    if not recipe then return { success = false, reason = "Unknown recipe" } end
    
    -- Check if recipe is known
    if not data.knownRecipes[recipeKey] then
        return { success = false, reason = "Recipe not unlocked" }
    end
    
    -- Check required module exists in base
    if recipe.RequiresModule then
        local BaseBuildingService = Knit.GetService("BaseBuildingService")
        if BaseBuildingService then
            local baseData = BaseBuildingService:GetBaseData(player)
            local hasModule = false
            for _, mod in ipairs(baseData.modules or {}) do
                if mod.Type == recipe.RequiresModule then
                    hasModule = true
                    break
                end
            end
            if not hasModule then
                return { success = false, reason = "Requires " .. recipe.RequiresModule .. " in your base" }
            end
        end
    end
    
    -- Calculate material cost with research bonuses
    local craftingEfficiency = data.researchTiers["CraftingEfficiency"] or 0
    local discount = craftingEfficiency * 10 -- 10% per tier
    local scrapCost = math.max(1, math.floor(recipe.Scrap * (100 - discount) / 100))
    local crystalCost = math.max(1, math.floor(recipe.Crystal * (100 - discount) / 100))
    
    -- Spend resources
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        if not EconomyService:SpendResource(player, "Scrap", scrapCost) then
            return { success = false, reason = string.format("Need %d Scrap (have %d)", scrapCost, EconomyService:GetResource(player, "Scrap")) }
        end
        if not EconomyService:SpendResource(player, "Crystal", crystalCost) then
            EconomyService:AddResource(player, "Scrap", scrapCost) -- Refund
            return { success = false, reason = string.format("Need %d Crystal (have %d)", crystalCost, EconomyService:GetResource(player, "Crystal")) }
        end
    end
    
    -- Craft time (speed-up costs credits)
    local craftTime = recipe.CraftTime
    if speedUp then
        local speedCost = math.ceil(craftTime * 2)
        if EconomyService and not EconomyService:SpendCredits(player, speedCost) then
            return { success = false, reason = string.format("Speed-up costs %d Credits", speedCost) }
        end
        craftTime = 0
    end
    
    local result = {
        success = true,
        recipe = recipeKey,
        name = recipe.Name,
        craftTime = craftTime,
        category = recipe.Category,
        scrapCost = scrapCost,
        crystalCost = crystalCost,
    }
    
    self.Client:Get("CraftResult"):Fire(player, result)
    
    print(string.format("[CraftingService] %s crafted %s (time=%ds, scrap=%d, crystal=%d)",
        player.Name, recipe.Name, craftTime, scrapCost, crystalCost))
    
    return result
end

-- ============================================================
-- Research
-- ============================================================

function CraftingService.Client:Research(player, upgradeKey)
    local self = CraftingService
    local data = playerData[player.UserId]
    if not data then return { success = false, reason = "Not loaded" } end
    
    local upgrade = Config.ResearchTree[upgradeKey]
    if not upgrade then return { success = false, reason = "Unknown research" } end
    
    local currentTier = data.researchTiers[upgradeKey] or 0
    local nextTier = currentTier + 1
    
    if nextTier > upgrade.MaxTier then
        return { success = false, reason = "Max tier reached" }
    end
    
    local cost = upgrade.CostPerTier[nextTier]
    if not cost then return { success = false, reason = "Cost not defined" } end
    
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        if not EconomyService:SpendResearchPoints(player, cost) then
            return { success = false, reason = string.format("Need %d RP", cost) }
        end
    end
    
    data.researchTiers[upgradeKey] = nextTier
    
    self.Client:Get("ResearchUpdated"):Fire(player, {
        upgradeKey = upgradeKey,
        tier = nextTier,
        maxTier = upgrade.MaxTier,
        bonus = upgrade.BonusPerTier * nextTier,
    })
    
    return { success = true, tier = nextTier }
end

-- ============================================================
-- Query Methods
-- ============================================================

function CraftingService.Client:GetRecipes(player)
    local data = playerData[player.UserId]
    return {
        recipes = RECIPES,
        knownRecipes = data and data.knownRecipes or {},
    }
end

function CraftingService.Client:GetResearch(player)
    local data = playerData[player.UserId]
    return {
        tree = Config.ResearchTree,
        tiers = data and data.researchTiers or {},
    }
end

return CraftingService