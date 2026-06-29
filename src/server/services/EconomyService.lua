--[[
	EconomyService — Handles player currency, purchases, and progression XP
	All monetary transactions go through this service.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local EconomyService = Knit.CreateService {
	Name = "EconomyService",
	Client = {
		EconomyUpdated = Knit.CreateSignal(),
		GetBalance = Knit.CreateSignal(),
		PurchaseGear = Knit.CreateSignal(),
		PurchaseConsumable = Knit.CreateSignal(),
	}
}

local playerEconomy = {} -- { [UserId] = { currency: number, xp: number, level: number } }

-- XP thresholds for each level
local function GetXPForLevel(level)
	return 100 * level * 1.5
end

function EconomyService:KnitStart()
	print("[EconomyService] Initialized")
end

function EconomyService:PlayerAdded(player)
	playerEconomy[player.UserId] = {
		currency = Config.Economy.StartingCurrency,
		xp = 0,
		level = 1,
	}
end

function EconomyService:PlayerRemoving(player)
	playerEconomy[player.UserId] = nil
end

function EconomyService:AddCurrency(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end
	
	data.currency += amount
	
	self.Client:Get("EconomyUpdated"):Fire(player, {
		currency = data.currency,
		xp = data.xp,
		level = data.level,
	})
end

function EconomyService:SpendCurrency(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return false end
	
	if data.currency < amount then
		return false
	end
	
	data.currency -= amount
	
	self.Client:Get("EconomyUpdated"):Fire(player, {
		currency = data.currency,
		xp = data.xp,
		level = data.level,
	})
	
	return true
end

function EconomyService:AddXP(player, amount)
	local data = playerEconomy[player.UserId]
	if not data then return end
	
	data.xp += amount
	
	-- Check level up
	local xpNeeded = GetXPForLevel(data.level)
	while data.xp >= xpNeeded do
		data.xp -= xpNeeded
		data.level += 1
		xpNeeded = GetXPForLevel(data.level)
		
		-- Level up bonus currency
		data.currency += data.level * 10
	end
	
	self.Client:Get("EconomyUpdated"):Fire(player, {
		currency = data.currency,
		xp = data.xp,
		level = data.level,
		xpNeeded = xpNeeded,
	})
end

function EconomyService:GetPlayerData(player)
	return playerEconomy[player.UserId]
end

-- Client methods
function EconomyService.Client:GetBalance(player)
	local self = EconomyService
	local data = playerEconomy[player.UserId]
	if not data then return { currency = 0, xp = 0, level = 1 } end
	return {
		currency = data.currency,
		xp = data.xp,
		level = data.level,
		xpNeeded = GetXPForLevel(data.level),
	}
end

function EconomyService.Client:PurchaseGear(player, gearTier)
	local self = EconomyService
	local gear = Config.DivingGear[gearTier]
	if not gear then
		return { success = false, reason = "Invalid gear tier" }
	end
	
	if not self:SpendCurrency(player, gear.Price) then
		return { success = false, reason = "Not enough currency" }
	end
	
	return { success = true, tier = gearTier, name = gear.Name }
end

function EconomyService.Client:PurchaseConsumable(player, productId)
	local self = EconomyService
	-- Would integrate with Roblox Developer Products API
	return { success = false, reason = "Not implemented — use ProcessReceipt" }
end

return EconomyService