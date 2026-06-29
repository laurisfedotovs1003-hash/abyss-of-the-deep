--[[
	BaseBuildingService — Handles underwater habitat construction and upgrades
	Players can build, upgrade, and decorate their deep-sea bases.
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
	}
}

local playerBases = {} -- { [UserId] = { modules = {}, location = Vector3.new(0,0,0) } }

function BaseBuildingService:KnitStart()
	print("[BaseBuildingService] Initialized")
end

function BaseBuildingService:PlayerAdded(player)
	playerBases[player.UserId] = {
		modules = {},
		location = Vector3.new(0, 0, 0), -- Default, would be saved from DataStore
		totalModules = 0,
		powerLevel = 0,
	}
end

function BaseBuildingService:PlayerRemoving(player)
	playerBases[player.UserId] = nil
end

function BaseBuildingService:PlaceModule(player, moduleType, position, orientation)
	local base = playerBases[player.UserId]
	if not base then return { success = false, reason = "Base not found" } end
	
	-- Check if module type is valid
	local cost = Config.Economy.BaseBuildingCosts[moduleType]
	if not cost then
		return { success = false, reason = "Invalid module type" }
	end
	
	-- Check max modules
	if base.totalModules >= 20 then
		return { success = false, reason = "Maximum modules reached" }
	end
	
	-- Would check economy here (via EconomyService)
	
	local moduleData = {
		Id = tostring(os.time() + math.random()),
		Type = moduleType,
		Position = position,
		Orientation = orientation,
		Tier = 1,
		Health = 100,
		IsPowered = false,
		PlacedAt = os.time(),
	}
	
	table.insert(base.modules, moduleData)
	base.totalModules += 1
	
	self.Client:Get("ModulePlaced"):Fire(player, moduleData)
	self.Client:Get("BaseSynced"):Fire(player, base)
	
	return { success = true, module = moduleData }
end

function BaseBuildingService:RemoveModule(player, moduleId)
	local base = playerBases[player.UserId]
	if not base then return { success = false } end
	
	for i, mod in ipairs(base.modules) do
		if mod.Id == moduleId then
			table.remove(base.modules, i)
			base.totalModules -= 1
			
			self.Client:Get("ModuleRemoved"):Fire(player, { id = moduleId })
			self.Client:Get("BaseSynced"):Fire(player, base)
			return { success = true }
		end
	end
	
	return { success = false, reason = "Module not found" }
end

function BaseBuildingService:UpgradeModule(player, moduleId)
	local base = playerBases[player.UserId]
	if not base then return { success = false } end
	
	for _, mod in ipairs(base.modules) do
		if mod.Id == moduleId then
			if mod.Tier >= 3 then
				return { success = false, reason = "Maximum tier reached" }
			end
			
			mod.Tier += 1
			mod.Health += 50
			
			self.Client:Get("BaseSynced"):Fire(player, base)
			return { success = true, module = mod }
		end
	end
	
	return { success = false, reason = "Module not found" }
end

-- Client methods
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

return BaseBuildingService