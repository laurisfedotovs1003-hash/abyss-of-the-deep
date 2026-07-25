--[[
	TradeService — Player-to-player creature trading with anti-scam double-confirmation.
	Features: trade requests, 2-slot offer window, confirm flow, trade history log.
	Integrates with EconomyService (no cost), CollectionService (creature ownership),
	DataStoreManager (trade history persistence), and MarketService (reputation).
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local Players = game:GetService("Players")

local TradeService = Knit.CreateService {
	Name = "TradeService",
	Client = {
		-- Trade flow
		SendTradeRequest = Knit.CreateSignal(),
		RespondToTradeRequest = Knit.CreateSignal(), -- accept / decline
		AddTradeOffer = Knit.CreateSignal(), -- add creature to offer slot
		RemoveTradeOffer = Knit.CreateSignal(), -- remove creature from offer slot
		ConfirmTrade = Knit.CreateSignal(),
		CancelTrade = Knit.CreateSignal(),
		
		-- UI updates
		TradeRequestReceived = Knit.CreateSignal(),
		TradeUpdated = Knit.CreateSignal(),
		TradeCompleted = Knit.CreateSignal(),
		TradeCancelled = Knit.CreateSignal(),
		
		-- History
		GetTradeHistory = Knit.CreateSignal(),
	}
}

local log = Logger.new("TradeService")

-- Active trade sessions: { [tradeId] = TradeSession }
local activeTrades = {}

-- Pending trade requests: { [targetUserId] = { fromUserId, fromDisplayName, timestamp } }
local pendingRequests = {}

-- ============================================================
-- TradeSession structure (with anti-scam confirmations)
--[[
	TradeSession = {
		Id: string,
		PlayerA: Player,
		PlayerB: Player,
		OfferA: { CreatureEntry },     -- what PlayerA is giving
		OfferB: { CreatureEntry },     -- what PlayerB is giving
		ConfirmedA: boolean,           -- PlayerA confirmed
		ConfirmedB: boolean,           -- PlayerB confirmed
		Status: "pending" | "confirmed" | "completed" | "cancelled",
		CreatedAt: number,
	}
]]

-- ============================================================
-- Initialize
-- ============================================================

function TradeService:KnitStart()
	log:Info("TradeService initialized")
end

function TradeService:PlayerRemoving(player)
	-- Clean up any active trades or requests involving this player
	self:CancelAllPlayerTrades(player)
	pendingRequests[player.UserId] = nil
	
	-- Clear requests this player sent to others
	for targetId, request in pairs(pendingRequests) do
		if request.fromUserId == player.UserId then
			pendingRequests[targetId] = nil
		end
	end
end

-- ============================================================
-- Trade Validation — creature ownership
-- ============================================================

function TradeService:PlayerOwnsCreature(player, creatureId)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	if not profile or not profile.CreatureCollection then
		return false
	end
	
	for _, entry in ipairs(profile.CreatureCollection) do
		if entry.Id == creatureId then
			return true
		end
	end
	return false
end

-- ============================================================
-- Send Trade Request
-- ============================================================

function TradeService.Client:SendTradeRequest(player, targetPlayerName)
	if not player or not targetPlayerName then
		return { success = false, reason = "Invalid request" }
	end
	
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		return { success = false, reason = "Player not found" }
	end
	
	if targetPlayer.UserId == player.UserId then
		return { success = false, reason = "Cannot trade with yourself" }
	end
	
	-- Check if target already has a pending request from this player
	if pendingRequests[targetPlayer.UserId] and pendingRequests[targetPlayer.UserId].fromUserId == player.UserId then
		return { success = false, reason = "Trade request already sent" }
	end
	
	pendingRequests[targetPlayer.UserId] = {
		fromUserId = player.UserId,
		fromDisplayName = player.DisplayName,
		timestamp = os.time(),
	}
	
	-- Notify target
	TradeService.Client:Get("TradeRequestReceived"):Fire(targetPlayer, {
		fromUserId = player.UserId,
		fromDisplayName = player.DisplayName,
	})
	
	log:Info(string.format("Trade request: %s -> %s", player.DisplayName, targetPlayerName))
	return { success = true }
end

-- ============================================================
-- Respond to Trade Request (Accept / Decline)
-- ============================================================

function TradeService.Client:RespondToTradeRequest(player, fromUserId, accepted)
	if not player or not fromUserId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local request = pendingRequests[player.UserId]
	if not request or request.fromUserId ~= fromUserId then
		return { success = false, reason = "No pending request from this player" }
	end
	
	-- Clear the request
	pendingRequests[player.UserId] = nil
	
	if not accepted then
		local fromPlayer = Players:GetPlayerByUserId(fromUserId)
		if fromPlayer then
			TradeService.Client:Get("TradeCancelled"):Fire(fromPlayer, {
				reason = "declined",
				otherPlayer = player.DisplayName,
			})
		end
		return { success = true, action = "declined" }
	end
	
	-- Create trade session
	local fromPlayer = Players:GetPlayerByUserId(fromUserId)
	if not fromPlayer then
		return { success = false, reason = "Other player left" }
	end
	
	-- Check neither player is in another active trade
	if TradeService:GetPlayerTrade(player) or TradeService:GetPlayerTrade(fromPlayer) then
		return { success = false, reason = "A player is already in a trade" }
	end
	
	local tradeId = "trade_" .. tostring(player.UserId) .. "_" .. tostring(fromUserId) .. "_" .. tostring(os.time())
	local session = {
		Id = tradeId,
		PlayerA = fromPlayer,
		PlayerB = player,
		OfferA = {},
		OfferB = {},
		ConfirmedA = false,
		ConfirmedB = false,
		Status = "pending",
		CreatedAt = os.time(),
	}
	
	activeTrades[tradeId] = session
	
	-- Notify both players
	local tradeState = TradeService:BuildTradeState(session, fromPlayer)
	TradeService.Client:Get("TradeUpdated"):Fire(fromPlayer, tradeState)
	
	local tradeStateB = TradeService:BuildTradeState(session, player)
	TradeService.Client:Get("TradeUpdated"):Fire(player, tradeStateB)
	
	log:Info(string.format("Trade started: %s <-> %s [%s]", fromPlayer.DisplayName, player.DisplayName, tradeId))
	return { success = true, action = "accepted", tradeId = tradeId }
end

-- ============================================================
-- Add Creature to Trade Offer
-- ============================================================

function TradeService.Client:AddTradeOffer(player, tradeId, creatureId, slotIndex)
	if not player or not tradeId or not creatureId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local session = activeTrades[tradeId]
	if not session then
		return { success = false, reason = "Trade not found" }
	end
	
	-- Identify which side this player is on
	local isPlayerA = (session.PlayerA.UserId == player.UserId)
	local isPlayerB = (session.PlayerB.UserId == player.UserId)
	
	if not isPlayerA and not isPlayerB then
		return { success = false, reason = "Not part of this trade" }
	end
	
	if session.Status ~= "pending" then
		return { success = false, reason = "Trade is locked" }
	end
	
	-- Validate ownership
	if not TradeService:PlayerOwnsCreature(player, creatureId) then
		return { success = false, reason = "You don't own this creature" }
	end
	
	-- Check creature not already in this trade
	local offer = isPlayerA and session.OfferA or session.OfferB
	for _, entry in ipairs(offer) do
		if entry.Id == creatureId then
			return { success = false, reason = "Creature already offered" }
		end
	end
	
	-- Limit to 2 slots
	if #offer >= 2 then
		return { success = false, reason = "Offer slots full (max 2)" }
	end
	
	-- Get creature data from collection
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	local creatureData = nil
	for _, entry in ipairs(profile.CreatureCollection) do
		if entry.Id == creatureId then
			creatureData = entry
			break
		end
	end
	
	if not creatureData then
		return { success = false, reason = "Creature not found in collection" }
	end
	
	-- Add to offer with slot index
	creatureData.SlotIndex = slotIndex or (#offer + 1)
	table.insert(offer, creatureData)
	
	-- Reset confirmations when offers change
	session.ConfirmedA = false
	session.ConfirmedB = false
	
	-- Push updated trade state to both players
	TradeService.Client:Get("TradeUpdated"):Fire(session.PlayerA, TradeService:BuildTradeState(session, session.PlayerA))
	TradeService.Client:Get("TradeUpdated"):Fire(session.PlayerB, TradeService:BuildTradeState(session, session.PlayerB))
	
	return { success = true }
end

-- ============================================================
-- Remove Creature from Trade Offer
-- ============================================================

function TradeService.Client:RemoveTradeOffer(player, tradeId, creatureId)
	if not player or not tradeId or not creatureId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local session = activeTrades[tradeId]
	if not session then
		return { success = false, reason = "Trade not found" }
	end
	
	local isPlayerA = (session.PlayerA.UserId == player.UserId)
	
	if not isPlayerA and session.PlayerB.UserId ~= player.UserId then
		return { success = false, reason = "Not part of this trade" }
	end
	
	if session.Status ~= "pending" then
		return { success = false, reason = "Trade is locked" }
	end
	
	local offer = isPlayerA and session.OfferA or session.OfferB
	for i, entry in ipairs(offer) do
		if entry.Id == creatureId then
			table.remove(offer, i)
			break
		end
	end
	
	-- Reset confirmations
	session.ConfirmedA = false
	session.ConfirmedB = false
	
	TradeService.Client:Get("TradeUpdated"):Fire(session.PlayerA, TradeService:BuildTradeState(session, session.PlayerA))
	TradeService.Client:Get("TradeUpdated"):Fire(session.PlayerB, TradeService:BuildTradeState(session, session.PlayerB))
	
	return { success = true }
end

-- ============================================================
-- Confirm Trade (individual player)
-- ============================================================

function TradeService.Client:ConfirmTrade(player, tradeId)
	if not player or not tradeId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local session = activeTrades[tradeId]
	if not session then
		return { success = false, reason = "Trade not found" }
	end
	
	if session.Status ~= "pending" then
		return { success = false, reason = "Trade is locked" }
	end
	
	-- Both players must offer at least one creature
	if #session.OfferA == 0 or #session.OfferB == 0 then
		return { success = false, reason = "Both players must offer something" }
	end
	
	if session.PlayerA.UserId == player.UserId then
		session.ConfirmedA = true
	elseif session.PlayerB.UserId == player.UserId then
		session.ConfirmedB = true
	else
		return { success = false, reason = "Not part of this trade" }
	end
	
	-- Notify both players of updated confirmations
	TradeService.Client:Get("TradeUpdated"):Fire(session.PlayerA, TradeService:BuildTradeState(session, session.PlayerA))
	TradeService.Client:Get("TradeUpdated"):Fire(session.PlayerB, TradeService:BuildTradeState(session, session.PlayerB))
	
	-- Check for double-confirmation — execute trade!
	if session.ConfirmedA and session.ConfirmedB then
		TradeService:ExecuteTrade(session)
	end
	
	return { success = true }
end

-- ============================================================
-- Cancel Trade
-- ============================================================

function TradeService.Client:CancelTrade(player, tradeId)
	if not player or not tradeId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local session = activeTrades[tradeId]
	if not session then
		return { success = false, reason = "Trade not found" }
	end
	
	session.Status = "cancelled"
	
	TradeService.Client:Get("TradeCancelled"):Fire(session.PlayerA, {
		reason = "cancelled",
		otherPlayer = player.DisplayName,
	})
	TradeService.Client:Get("TradeCancelled"):Fire(session.PlayerB, {
		reason = "cancelled",
		otherPlayer = player.DisplayName,
	})
	
	activeTrades[tradeId] = nil
	return { success = true }
end

-- ============================================================
-- Execute Trade (server-side, after double confirmation)
-- ============================================================

function TradeService:ExecuteTrade(session)
	session.Status = "completed"
	
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	
	-- Transfer: A's creatures -> B, B's creatures -> A
	local success = DataStoreManager:ExecuteCreatureTransfer(
		session.PlayerA, session.PlayerB,
		session.OfferA, session.OfferB
	)
	
	if not success then
		-- Rollback: trade failed
		session.Status = "cancelled"
		TradeService.Client:Get("TradeCancelled"):Fire(session.PlayerA, {
			reason = "failed",
			otherPlayer = session.PlayerB.DisplayName,
		})
		TradeService.Client:Get("TradeCancelled"):Fire(session.PlayerB, {
			reason = "failed",
			otherPlayer = session.PlayerA.DisplayName,
		})
		log:Error(string.format("Trade failed during transfer: %s <-> %s", 
			session.PlayerA.DisplayName, session.PlayerB.DisplayName))
		activeTrades[session.Id] = nil
		return
	end
	
	-- Log trade history for both players
	TradeService:LogTrade(session.PlayerA, session.PlayerB, session.OfferA, session.OfferB)
	
	-- Notify completion
	TradeService.Client:Get("TradeCompleted"):Fire(session.PlayerA, {
		tradeId = session.Id,
		partnerName = session.PlayerB.DisplayName,
		gave = session.OfferA,
		received = session.OfferB,
	})
	TradeService.Client:Get("TradeCompleted"):Fire(session.PlayerB, {
		tradeId = session.Id,
		partnerName = session.PlayerA.DisplayName,
		gave = session.OfferB,
		received = session.OfferA,
	})
	
	-- Update trade reputation (both parties +1 for successful trade)
	TradeService:UpdateReputation(session.PlayerA, 1)
	TradeService:UpdateReputation(session.PlayerB, 1)
	
	log:Info(string.format("Trade completed: %s <-> %s [%s] — A gave %d, B gave %d",
		session.PlayerA.DisplayName, session.PlayerB.DisplayName,
		session.Id, #session.OfferA, #session.OfferB))
	
	activeTrades[session.Id] = nil
end

-- ============================================================
-- Trade History / Reputation
-- ============================================================

function TradeService:LogTrade(playerA, playerB, offerA, offerB)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local timestamp = os.time()
	
	local historyEntry = {
		tradeId = "trade_" .. tostring(timestamp),
		partnerName = playerB.DisplayName,
		partnerUserId = playerB.UserId,
		gave = offerA,
		received = offerB,
		timestamp = timestamp,
	}
	
	DataStoreManager:UpdateProfile(playerA, function(profile)
		if not profile.TradeHistory then profile.TradeHistory = {} end
		table.insert(profile.TradeHistory, 1, historyEntry) -- newest first
		-- Keep last 50 trades
		while #profile.TradeHistory > 50 do
			table.remove(profile.TradeHistory)
		end
	end)
	
	-- Mirror for player B
	local historyEntryB = {
		tradeId = "trade_" .. tostring(timestamp),
		partnerName = playerA.DisplayName,
		partnerUserId = playerA.UserId,
		gave = offerB,
		received = offerA,
		timestamp = timestamp,
	}
	
	DataStoreManager:UpdateProfile(playerB, function(profile)
		if not profile.TradeHistory then profile.TradeHistory = {} end
		table.insert(profile.TradeHistory, 1, historyEntryB)
		while #profile.TradeHistory > 50 do
			table.remove(profile.TradeHistory)
		end
	end)
end

function TradeService:UpdateReputation(player, delta)
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	DataStoreManager:UpdateProfile(player, function(profile)
		profile.TradeReputation = (profile.TradeReputation or 0) + delta
		if profile.TradeReputation < 0 then profile.TradeReputation = 0 end
	end)
end

-- ============================================================
-- Helper: Get active trade for a player
-- ============================================================

function TradeService:GetPlayerTrade(player)
	if not player then return nil end
	for _, session in pairs(activeTrades) do
		if session.PlayerA.UserId == player.UserId or session.PlayerB.UserId == player.UserId then
			return session
		end
	end
	return nil
end

-- ============================================================
-- Helper: Cancel all trades for a player (on leave)
-- ============================================================

function TradeService:CancelAllPlayerTrades(player)
	if not player then return end
	for tradeId, session in pairs(activeTrades) do
		if session.PlayerA.UserId == player.UserId or session.PlayerB.UserId == player.UserId then
			session.Status = "cancelled"
			local other = session.PlayerA.UserId == player.UserId and session.PlayerB or session.PlayerA
			TradeService.Client:Get("TradeCancelled"):Fire(other, {
				reason = "player_left",
				otherPlayer = player.DisplayName,
			})
			activeTrades[tradeId] = nil
		end
	end
end

-- ============================================================
-- Build Trade State (for UI updates)
-- ============================================================

function TradeService:BuildTradeState(session, forPlayer)
	local isPlayerA = (forPlayer.UserId == session.PlayerA.UserId)
	
	return {
		tradeId = session.Id,
		yourOffer = isPlayerA and session.OfferA or session.OfferB,
		theirOffer = isPlayerA and session.OfferB or session.OfferA,
		partnerName = isPlayerA and session.PlayerB.DisplayName or session.PlayerA.DisplayName,
		partnerUserId = isPlayerA and session.PlayerB.UserId or session.PlayerA.UserId,
		youConfirmed = isPlayerA and session.ConfirmedA or session.ConfirmedB,
		theyConfirmed = isPlayerA and session.ConfirmedB or session.ConfirmedA,
		status = session.Status,
	}
end

-- ============================================================
-- Get Trade History (client query)
-- ============================================================

function TradeService.Client:GetTradeHistory(player)
	if not player then return {} end
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	return {
		history = profile.TradeHistory or {},
		reputation = profile.TradeReputation or 0,
	}
end

return TradeService
