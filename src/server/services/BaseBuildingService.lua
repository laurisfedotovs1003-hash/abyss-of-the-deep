--[[
	BaseBuildingService — Handles underwater habitat construction and upgrades
	Players can build, upgrade, and decorate their deep-sea bases.
	Integrated with EconomyService for purchase checking and DataStoreManager for persistence.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local BaseBuildingService = Knit.CreateService {
	Name = "BaseBuildingService",
	Client = {
		BaseSynced = Knit.CreateSignal(),
		ModulePlaced = Knit.CreateSignal(),
		ModuleRemoved = Knit.CreateSignal(),
		PlaceModule = Knit.CreateSignal(),
		RemoveModule = Knit.CreateSignal(),
		UpgradeModule = Knit.CreateSignal(),
		GetBaseData = Knit.CreateSignal(),
	}
}

local PLAYER_MAX_MODULES = 20

-- Player base state (loaded from DataStore on login)
local playerBases = {} -- { [UserId] = { modules = {}, location = Vector3, totalModules = 0, powerLevel = 0 } }

-- ============================================================
-- Initialize
-- ============================================================

function BaseBuildingService:KnitStart()
	print("[BaseBuildingService] Initialized")
end

function BaseBuildingService:ReloadFromProfile(player)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profileSync = DataStoreManager:GetPlayerProfileSync(player)
	
	playerBases[player.UserId] = {
		modules = profileSync.BaseModules or {},
		location = Vector3.new(
			(profileSync.BaseLocation and profileSync.BaseLocation.X) or 0,
			(profileSync.BaseLocation and profileSync.BaseLocation.Y) or 0,
			(profileSync.BaseLocation and profileSync.BaseLocation.Z) or 0
		),
		totalModules = #(profileSync.BaseModules or {}),
		powerLevel = 0,
	}
	
	print(string.format("[BaseBuildingService] Loaded base for %s (%d): %d modules",
		player.Name, player.UserId, playerBases[player.UserId].totalModules))
end

function BaseBuildingService:PlayerRemoving(player)
	-- Sync base data before removal
	local data = playerBases[player.UserId]
	if data then
		local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
		DataStoreManager:UpdateProfile(player, function(profile)
			profile.BaseModules = data.modules
			profile.BaseLocation = {
				X = data.location.X,
				Y = data.location.Y,
				Z = data.location.Z,
			}
		end)
	end
	
	playerBases[player.UserId] = nil
end

-- ============================================================
-- Module Placement
-- ============================================================

function BaseBuildingService:PlaceModule(player, moduleType, position, orientation)
	local base = playerBases[player.UserId]
	if not base then return { success = false, reason = "Base not found" } end
	
	-- Validate module type
	local cost = Config.Economy.BaseBuildingCosts[moduleType]
	if not cost then
		return { success = false, reason = "Invalid module type. Available: Habitat, Greenhouse, Lab, DefenseTurret, Decoration" }
	end
	
	-- Check max modules
	if base.totalModules >= PLAYER_MAX_MODULES then
		return { success = false, reason = "Maximum modules reached (" .. PLAYER_MAX_MODULES .. ")" }
	end
	
	-- Check economy: deduct Credits cost
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService then
		local creditCost = cost.Credits or 0
		if creditCost > 0 then
			if not EconomyService:SpendCredits(player, creditCost) then
				return { success = false, reason = "Not enough Credits! Need ₡" .. creditCost }
			end
		end
	end
	
	-- Create module
	local moduleData = {
		Id = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
		Type = moduleType,
		Position = {
			X = position and position.X or 0,
			Y = position and position.Y or 0,
			Z = position and position.Z or 0,
		},
		Orientation = orientation or { 0, 0, 0, 1 }, -- Default CFrame rotation
		Tier = 1,
		Health = 100,
		IsPowered = false,
		PlacedAt = os.time(),
	}
	
	table.insert(base.modules, moduleData)
	base.totalModules += 1
	
	-- Save to DataStore
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	DataStoreManager:UpdateProfile(player, function(profile)
		profile.BaseModules = base.modules
	end)
	
	-- Fire events
	self.Client:Get("ModulePlaced"):Fire(player, moduleData)
	self.Client:Get("BaseSynced"):Fire(player, {
		modules = base.modules,
		totalModules = base.totalModules,
		maxModules = PLAYER_MAX_MODULES,
		location = { X = base.location.X, Y = base.location.Y, Z = base.location.Z },
	})
	
	return { success = true, module = moduleData }
end

-- ============================================================
Module Removal
-- ============================================================

function BaseBuildingService:RemoveModule(player, moduleId)
	local base = playerBases[player.UserId]
	if not base then return { success = false, reason = "Base not found" } end
	
	for i, mod in ipairs(base.modules) do
		if mod.Id == moduleId then
			table.remove(base.modules, i)
			base.totalModules -= 1
			
			-- Save to DataStore
			local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
			DataStoreManager:UpdateProfile(player, function(profile)
				profile.BaseModules = base.modules
			end)
			
			self.Client:Get("ModuleRemoved"):Fire(player, { id = moduleId })
			self.Client:Get("BaseSynced"):Fire(player, {
				modules = base.modules,
				totalModules = base.totalModules,
				maxModules = PLAYER_MAX_MODULES,
			})
			
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
			if mod.Tier >= 3 then
				return { success = false, reason = "Maximum tier reached (Tier 3)" }
			end
			
			-- Calculate upgrade cost
			local upgradeCost = (mod.Tier + 1) * 50 -- 100 for T2, 150 for T3
			
			local EconomyService = Knit.GetService("EconomyService")
			if EconomyService then
				if not EconomyService:SpendCredits(player, upgradeCost) then
					return { success = false, reason = "Not enough Credits! Need ₡" .. upgradeCost .. " to upgrade" }
				end
			end
			
			mod.Tier += 1
			mod.Health += 50
			
			-- Save to DataStore
			local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
			DataStoreManager:UpdateProfile(player, function(profile)
				profile.BaseModules = base.modules
			end)
			
			self.Client:Get("BaseSynced"):Fire(player, {
				modules = base.modules,
				totalModules = base.totalModules,
				maxModules = PLAYER_MAX_MODULES,
				upgradedModule = { id = mod.Id, tier = mod.Tier },
			})
			
			return { success = true, module = mod }
		end
	end
	
	return { success = false, reason = "Module not found" }
end

-- ============================================================
-- Client Methods
-- ============================================================

function BaseBuildingService.Client:PlaceModule(player, moduleType, position, orientation)
	local self = BaseBuildingService
	return self:PlaceModule(player, moduleType, position, orientation)
end

function BaseBuildingService.Client:RemoveModule(player, moduleId)
	local self = BaseBuildingService
	return self:RemoveModule(player, moduleId)
end

function BaseBuildingService.Client:UpgradeModule(player, moduleId)
	local self = BaseBuildingService
	return self:UpgradeModule(player, moduleId)
end

function BaseBuildingService.Client:GetBaseData(player)
	local self = BaseBuildingService
	local base = playerBases[player.UserId]
	if not base then return { modules = {}, totalModules = 0, maxModules = PLAYER_MAX_MODULES } end
	
	return {
		modules = base.modules,
		totalModules = base.totalModules,
		maxModules = PLAYER_MAX_MODULES,
		location = { X = base.location.X, Y = base.location.Y, Z = base.location.Z },
	}
end

return BaseBuildingService