--[[
    BaseBuildingService — Simplified underwater base construction (v2)
    Players can build Habitats and Labs, upgrade them, and persist via ProfileService.
    
    Design (per lead instructions):
    - 2 module types: Habitat (₡100) → Provides oxygen regen, Lab (₡150) → Research bonuses
    - 3 upgrade tiers per module (cost scales: T2=1.5x, T3=3x base price)
    - Max 10 modules per player
    - Credit-based economy (spends from EconomyService)
    - Persisted via DataStoreManager (ProfileService pattern)
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local VALID_MODULES = { Habitat = true, Lab = true }

local BaseBuildingService = Knit.CreateService {
    Name = "BaseBuildingService",
    Client = {
        BaseSynced = Knit.CreateSignal(),
        ModulePlaced = Knit.CreateSignal(),
        ModuleRemoved = Knit.CreateSignal(),
        ModuleUpgraded = Knit.CreateSignal(),
        PlaceModule = Knit.CreateSignal(),
        RemoveModule = Knit.CreateSignal(),
        UpgradeModule = Knit.CreateSignal(),
        GetBaseData = Knit.CreateSignal(),
    }
}

local playerBases = {} -- { [UserId] = { modules = {}, location = Vector3 } }

-- ============================================================
-- Helpers
-- ============================================================

local function GetDataStoreManager()
    return require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
end

local function SaveModules(player, base)
    local DataStoreManager = GetDataStoreManager()
    DataStoreManager:UpdateProfile(player, function(profile)
        profile.BaseModules = base.modules
    end)
end

local function FireBaseSync(player, base, extra)
    local data = {
        modules = base.modules,
        totalModules = #base.modules,
        maxModules = Config.Economy.BaseBuildingCosts.MaxModules or 10,
    }
    if extra then
        for k, v in pairs(extra) do data[k] = v end
    end
    BaseBuildingService.Client:Get("BaseSynced"):Fire(player, data)
end

-- ============================================================
-- Initialize
-- ============================================================

function BaseBuildingService:KnitStart()
    print("[BaseBuildingService] Initialized (simplified: Habitat + Lab)")
end

function BaseBuildingService:ReloadFromProfile(player)
    local profileSync = GetDataStoreManager():GetPlayerProfileSync(player)
    
    playerBases[player.UserId] = {
        modules = profileSync.BaseModules or {},
        location = profileSync.BaseLocation or Vector3.new(0, -50, 0), -- Default underwater base location
    }
    
    print(string.format("[BaseBuildingService] Loaded base for %s (%d): %d modules",
        player.Name, player.UserId, #playerBases[player.UserId].modules))
end

function BaseBuildingService:PlayerRemoving(player)
    local base = playerBases[player.UserId]
    if base then
        SaveModules(player, base)
    end
    playerBases[player.UserId] = nil
end

-- ============================================================
-- Module Placement
-- ============================================================

function BaseBuildingService:PlaceModule(player, moduleType, position, orientation)
    local base = playerBases[player.UserId]
    if not base then return { success = false, reason = "Base not found" } end
    
    -- Validate module type (only Habitat and Lab)
    if not VALID_MODULES[moduleType] then
        return { success = false, reason = "Invalid module type. Available: Habitat, Lab" }
    end
    
    -- Check max modules
    local maxModules = Config.Economy.BaseBuildingCosts.MaxModules or 10
    if #base.modules >= maxModules then
        return { success = false, reason = "Maximum modules reached (" .. maxModules .. ")" }
    end
    
    -- Check and spend Credits + Resources
    local cost = Config.Economy.BaseBuildingCosts[moduleType]
    if not cost then return { success = false, reason = "Module cost not defined" } end
    
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        local creditCost = cost.Credits or 0
        if creditCost > 0 and not EconomyService:SpendCredits(player, creditCost) then
            return { success = false, reason = "Not enough Credits! Need ₡" .. creditCost .. " for " .. moduleType }
        end
        
        -- Check and spend Scrap
        local scrapCost = cost.Scrap or 0
        if scrapCost > 0 and not EconomyService:SpendResource(player, "Scrap", scrapCost) then
            -- Refund Credits on resource failure
            if creditCost > 0 then EconomyService:AddCredits(player, creditCost) end
            return { success = false, reason = "Not enough Scrap! Need " .. scrapCost .. " for " .. moduleType }
        end
        
        -- Check and spend Crystal
        local crystalCost = cost.Crystal or 0
        if crystalCost > 0 and not EconomyService:SpendResource(player, "Crystal", crystalCost) then
            -- Refund Credits + Scrap on crystal failure
            if creditCost > 0 then EconomyService:AddCredits(player, creditCost) end
            if scrapCost > 0 then EconomyService:AddResource(player, "Scrap", scrapCost) end
            return { success = false, reason = "Not enough Crystal! Need " .. crystalCost .. " for " .. moduleType }
        end
    end
    
    -- Create module instance
    local moduleData = {
        Id = tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999)),
        Type = moduleType,
        Position = {
            X = position and position.X or 0,
            Y = position and position.Y or 0,
            Z = position and position.Z or 0,
        },
        Tier = 1,
        Health = 100,
        PlacedAt = os.time(),
    }
    
    table.insert(base.modules, moduleData)
    
    -- Persist immediately
    SaveModules(player, base)
    
    -- Fire client events
    self.Client:Get("ModulePlaced"):Fire(player, moduleData)
    FireBaseSync(player, base)
    
    print(string.format("[BaseBuildingService] %s placed %s (₡%d)", player.Name, moduleType, cost.Credits))
    return { success = true, module = moduleData }
end

-- ============================================================
-- Module Removal
-- ============================================================

function BaseBuildingService:RemoveModule(player, moduleId)
    local base = playerBases[player.UserId]
    if not base then return { success = false, reason = "Base not found" } end
    
    for i, mod in ipairs(base.modules) do
        if mod.Id == moduleId then
            local moduleType = mod.Type
            table.remove(base.modules, i)
            
            -- Persist immediately
            SaveModules(player, base)
            
            self.Client:Get("ModuleRemoved"):Fire(player, { id = moduleId, type = moduleType })
            FireBaseSync(player, base)
            
            print(string.format("[BaseBuildingService] %s removed %s", player.Name, moduleType))
            return { success = true }
        end
    end
    
    return { success = false, reason = "Module not found" }
end

-- ============================================================
-- Module Upgrades
-- ============================================================

function BaseBuildingService:UpgradeModule(player, moduleId)
    local base = playerBases[player.UserId]
    if not base then return { success = false, reason = "Base not found" } end
    
    for _, mod in ipairs(base.modules) do
        if mod.Id == moduleId then
            local maxTier = Config.Economy.BaseBuildingCosts.MaxTier or 3
            if mod.Tier >= maxTier then
                return { success = false, reason = "Maximum tier reached (Tier " .. maxTier .. ")" }
            end
            
            -- Calculate upgrade cost: base price * upgrade multiplier
            local baseCost = Config.Economy.BaseBuildingCosts[mod.Type]
            if not baseCost then return { success = false, reason = "Unknown module type" } end
            
            local multiplier = Config.Economy.BaseBuildingCosts.UpgradeMultiplier
            local upgradeMul = (multiplier and multiplier[mod.Tier + 1]) or (mod.Tier + 1)
            local upgradeCost = math.floor((baseCost.Credits or 100) * upgradeMul)
            
            -- Spend Credits
            local EconomyService = Knit.GetService("EconomyService")
            if EconomyService then
                if not EconomyService:SpendCredits(player, upgradeCost) then
                    return { success = false, reason = "Not enough Credits! Need ₡" .. upgradeCost .. " to upgrade to Tier " .. (mod.Tier + 1) }
                end
            end
            
            -- Apply upgrade
            local oldTier = mod.Tier
            mod.Tier += 1
            mod.Health = 100 + (mod.Tier * 25) -- T1=125, T2=150, T3=175
            
            -- Persist immediately
            SaveModules(player, base)
            
            self.Client:Get("ModuleUpgraded"):Fire(player, {
                id = mod.Id,
                type = mod.Type,
                oldTier = oldTier,
                newTier = mod.Tier,
                health = mod.Health,
            })
            FireBaseSync(player, base, {
                upgradedModule = { id = mod.Id, type = mod.Type, tier = mod.Tier },
            })
            
            print(string.format("[BaseBuildingService] %s upgraded %s to T%d (₡%d)", player.Name, mod.Type, mod.Tier, upgradeCost))
            return { success = true, module = mod, upgradeCost = upgradeCost }
        end
    end
    
    return { success = false, reason = "Module not found" }
end

-- ============================================================
-- Client Methods
-- ============================================================

function BaseBuildingService.Client:PlaceModule(player, moduleType, position, orientation)
    return BaseBuildingService:PlaceModule(player, moduleType, position, orientation)
end

function BaseBuildingService.Client:RemoveModule(player, moduleId)
    return BaseBuildingService:RemoveModule(player, moduleId)
end

function BaseBuildingService.Client:UpgradeModule(player, moduleId)
    return BaseBuildingService:UpgradeModule(player, moduleId)
end

function BaseBuildingService.Client:GetBaseData(player)
    local base = playerBases[player.UserId]
    if not base then
        return { modules = {}, totalModules = 0, maxModules = Config.Economy.BaseBuildingCosts.MaxModules or 10 }
    end
    local maxModules = Config.Economy.BaseBuildingCosts.MaxModules or 10
    return {
        modules = base.modules,
        totalModules = #base.modules,
        maxModules = maxModules,
        location = { X = base.location.X, Y = base.location.Y, Z = base.location.Z },
        validTypes = { "Habitat", "Lab" },
    }
end

return BaseBuildingService