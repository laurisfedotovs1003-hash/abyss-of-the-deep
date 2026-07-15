--[[
	LeaderboardService — Manages game leaderboards and stat tracking
	Supports depth records, collection completion, and currency rankings.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local DataStoreService2 = game:GetService("DataStoreService")

local LeaderboardService = Knit.CreateService {
	Name = "LeaderboardService",
	Client = {
		LeaderboardUpdated = Knit.CreateSignal(),
		GetLeaderboard = Knit.CreateSignal(),
		GetPlayerStats = Knit.CreateSignal(),
	}
}

local leaderboardStore = nil -- DataStore instance
local cachedLeaderboard = {} -- In-memory cache
local playerStats = {} -- { [UserId] = { maxDepth, creaturesCollected, currencyEarned, ... } }

local LEADERBOARD_KEY = "AbyssLeaderboard_v1"
local CACHE_REFRESH_INTERVAL = 120 -- seconds

function LeaderboardService:KnitStart()
	print("[LeaderboardService] Initialized")
	
	-- Initialize DataStore
	local success, err = pcall(function()
		leaderboardStore = DataStoreService2:GetOrderedDataStore("AbyssDepthLeaderboard")
	end)
	
	if not success then
		warn("[LeaderboardService] DataStore unavailable: " .. tostring(err))
	end
	
	-- Periodic leaderboard refresh
	while task.wait(CACHE_REFRESH_INTERVAL) do
		self:RefreshLeaderboard()
	end
end

function LeaderboardService:PlayerAdded(player)
	playerStats[player.UserId] = {
		maxDepth = 0,
		creaturesCollected = 0,
		currencyEarned = 0,
		totalDives = 0,
		playTime = 0,
	}
end

function LeaderboardService:PlayerRemoving(player)
	-- Flush stats to DataStore
	if leaderboardStore then
		local stats = playerStats[player.UserId]
		if stats and stats.maxDepth > 0 then
			pcall(function()
				leaderboardStore:SetAsync(tostring(player.UserId), stats.maxDepth)
			end)
		end
	end
	playerStats[player.UserId] = nil
end

function LeaderboardService:UpdateStat(player, statName, value)
	local stats = playerStats[player.UserId]
	if not stats then return end
	
	stats[statName] = value
	
	-- Update DataStore for depth specifically
	if statName == "maxDepth" and leaderboardStore then
		pcall(function()
			leaderboardStore:SetAsync(tostring(player.UserId), value)
		end)
	end
end

function LeaderboardService:RefreshLeaderboard()
	if not leaderboardStore then return end
	
	local entries = {}
	local success, pages = pcall(function()
		return leaderboardStore:GetSortedAsync(false, 100)
	end)
	
	if success then
		local data = pages:GetCurrentPage()
		for _, entry in ipairs(data) do
			table.insert(entries, {
				userId = tonumber(entry.key),
				depth = entry.value,
				rank = #entries + 1,
			})
		end
	end
	
	cachedLeaderboard = entries
end

function LeaderboardService:GetCachedLeaderboard()
	return cachedLeaderboard
end

-- Client methods
function LeaderboardService.Client:GetLeaderboard(player, category)
	local self = LeaderboardService
	local entries = self:GetCachedLeaderboard()
	
	-- Find requesting player's rank
	local playerEntry = nil
	for _, entry in ipairs(entries) do
		if entry.userId == player.UserId then
			playerEntry = entry
			break
		end
	end
	
	return {
		entries = entries,
		playerRank = playerEntry,
	}
end

function LeaderboardService.Client:GetPlayerStats(player)
	local self = LeaderboardService
	return playerStats[player.UserId] or {
		maxDepth = 0,
		creaturesCollected = 0,
		currencyEarned = 0,
		totalDives = 0,
		playTime = 0,
	}
end

return LeaderboardService
