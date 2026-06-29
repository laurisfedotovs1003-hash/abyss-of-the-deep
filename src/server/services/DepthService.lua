--[[
	DepthService — Manages depth layers, diving gear, and pressure mechanics
	Controls which zones players can access based on their gear tier.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local DepthService = Knit.CreateService {
	Name = "DepthService",
	Client = {
		GetDepthData = Knit.CreateSignal(),
		GetLayerInfo = Knit.CreateSignal(),
		UpgradeGearRequest = Knit.CreateSignal(),
	}
}

-- Internal state
local playerDepths = {}	-- { [UserId] = { depth: number, layerIndex: number, gearTier: number } }

function DepthService:KnitStart()
	print("[DepthService] Initialized")
end

function DepthService:PlayerAdded(player)
	playerDepths[player.UserId] = {
		depth = 0,
		layerIndex = 1,
		gearTier = 1, -- Start with basic gear
		maxDepthReached = 0,
	}
end

function DepthService:PlayerRemoving(player)
	playerDepths[player.UserId] = nil
end

function DepthService:UpdatePlayerDepth(player, newDepth)
	local data = playerDepths[player.UserId]
	if not data then return end
	
	local clampedDepth = Util.Clamp(newDepth, 0, self:GetMaxDepthForGear(data.gearTier))
	local previousLayer = data.layerIndex
	
	data.depth = clampedDepth
	data.layerIndex = Util.DepthToLayerIndex(clampedDepth)
	
	-- Track max depth
	if clampedDepth > data.maxDepthReached then
		data.maxDepthReached = clampedDepth
	end
	
	-- Check for zone transition
	if previousLayer ~= data.layerIndex then
		local newLayer = Config.DepthLayers[data.layerIndex]
		self.Client:Get("GetLayerInfo"):Fire(player, {
			index = data.layerIndex,
			name = newLayer.Name,
			description = newLayer.Description,
			color = newLayer.Color,
		})
		
		-- Apply pressure damage if player is below safe depth
		if data.gearTier < data.layerIndex then
			self:ApplyPressureDamage(player, data.layerIndex - data.gearTier)
		end
	end
	
	-- Send update to client
	self.Client:Get("GetDepthData"):Fire(player, {
		depth = clampedDepth,
		layerIndex = data.layerIndex,
		maxDepth = self:GetMaxDepthForGear(data.gearTier),
		maxDepthReached = data.maxDepthReached,
		layerName = Config.DepthLayers[data.layerIndex].Name,
		gearTier = data.gearTier,
	})
end

function DepthService:GetPlayerDepth(player)
	local data = playerDepths[player.UserId]
	return data and data.depth or 0
end

function DepthService:GetPlayerGearTier(player)
	local data = playerDepths[player.UserId]
	return data and data.gearTier or 1
end

function DepthService:GetMaxDepthForGear(gearTier)
	local gear = Config.DivingGear[gearTier]
	return gear and gear.MaxDepth or 200
end

function DepthService:UpgradeGear(player)
	local data = playerDepths[player.UserId]
	if not data then return { success = false, reason = "Player not found" } end
	
	local nextTier = data.gearTier + 1
	local nextGear = Config.DivingGear[nextTier]
	
	if not nextGear then
		return { success = false, reason = "Maximum gear tier reached" }
	end
	
	-- Check if player can afford it (would integrate with EconomyService)
	-- local EconomyService = Knit.GetService("EconomyService")
	-- local canAfford = EconomyService:SpendCurrency(player, nextGear.Price)
	local canAfford = true -- Placeholder
	
	if not canAfford then
		return { success = false, reason = "Not enough currency" }
	end
	
	data.gearTier = nextTier
	
	self.Client:Get("GetDepthData"):Fire(player, {
		depth = data.depth,
		layerIndex = data.layerIndex,
		maxDepth = self:GetMaxDepthForGear(data.gearTier),
		maxDepthReached = data.maxDepthReached,
		layerName = Config.DepthLayers[data.layerIndex].Name,
		gearTier = data.gearTier,
	})
	
	return { success = true, tier = nextTier, name = nextGear.Name }
end

function DepthService:ApplyPressureDamage(player, levelsExceeded)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local damage = Config.Player.PressureDamagePerLevel * levelsExceeded
	humanoid:TakeDamage(damage)
	
	self.Client:Get("GetDepthData"):Fire(player, {
		pressureWarning = true,
		damage = damage,
	})
end

function DepthService:SurfacePlayer(player)
	local data = playerDepths[player.UserId]
	if not data then return end
	data.depth = 0
	data.layerIndex = 1
end

-- Client methods
function DepthService.Client:GetDepthData(player)
	local self = DepthService
	local data = playerDepths[player.UserId]
	if not data then return {} end
	return {
		depth = data.depth,
		layerIndex = data.layerIndex,
		maxDepth = self:GetMaxDepthForGear(data.gearTier),
		layerName = Config.DepthLayers[data.layerIndex].Name,
		gearTier = data.gearTier,
	}
end

function DepthService.Client:GetLayerInfo(player, layerIndex)
	local self = DepthService
	local layer = Config.DepthLayers[layerIndex]
	if not layer then return {} end
	return {
		index = layerIndex,
		name = layer.Name,
		description = layer.Description,
		depthRange = string.format("%d - %d m", layer.DepthMin, layer.DepthMax),
		creatureRarities = table.concat(layer.CreatureRarityPool, ", "),
	}
end

function DepthService.Client:UpgradeGearRequest(player)
	local self = DepthService
	return self:UpgradeGear(player)
end

return DepthService