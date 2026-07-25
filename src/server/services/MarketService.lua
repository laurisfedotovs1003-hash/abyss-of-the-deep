--[[
	MarketService — Creature marketplace with listings and auctions.
	Features: list for Credits/RP, buy-now, timed auctions, search/filter, 5% tax.
	Integrates with EconomyService (payments), CollectionService (ownership),
	DataStoreManager (listings/bids persistence), and TradeService (reputation).
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local Players = game:GetService("Players")

local MarketService = Knit.CreateService {
	Name = "MarketService",
	Client = {
		-- Listing management
		ListCreature = Knit.CreateSignal(),
		CancelListing = Knit.CreateSignal(),
		GetMyListings = Knit.CreateSignal(),
		GetMyBids = Knit.CreateSignal(),
		
		-- Market browsing
		BrowseListings = Knit.CreateSignal(),    -- search + filter
		GetFeaturedListings = Knit.CreateSignal(),
		
		-- Purchase / Bid
		BuyNow = Knit.CreateSignal(),
		PlaceBid = Knit.CreateSignal(),
		
		-- Notifications
		ListingSold = Knit.CreateSignal(),
		ListingExpired = Knit.CreateSignal(),
		AuctionWon = Knit.CreateSignal(),
		Outbid = Knit.CreateSignal(),
	}
}

local log = Logger.new("MarketService")

-- Active market listings: { [listingId] = Listing }
-- Persisted to DataStore per player, but server cache for search
local activeListings = {}

-- ============================================================
-- Listing structure
--[[
	Listing = {
		Id: string,
		SellerUserId: number,
		SellerName: string,
		CreatureData: CreatureEntry,
		ListingType: "buynow" | "auction",
		Price: number,                -- Credits (buy-now) or starting bid (auction)
		Currency: "Credits" | "ResearchPoints",
		BuyNowPrice: number,          -- optional, for auctions
		CurrentBid: number,
		BidderUserId: number,
		BidderName: string,
		Bids: { { userId, name, amount, timestamp } },
		AuctionEndTime: number,       -- os.time() for auction end
		ListedAt: number,
		Status: "active" | "sold" | "expired" | "cancelled",
	}
]]

-- ============================================================
-- Initialize
-- ============================================================

function MarketService:KnitStart()
	log:Info("MarketService initialized")
	-- Load existing active listings from all player profiles into cache
	-- (simplified: listings are loaded on demand via BrowseListings)
end

function MarketService:PlayerRemoving(player)
	-- Listings persist via DataStore, no in-memory cleanup needed
end

-- ============================================================
-- Creature Value System — Calculate estimated market value
-- ============================================================

function MarketService:CalculateEstimatedValue(creatureData)
	if not creatureData or not creatureData.Rarity then return 0 end
	
	local marketConfig = Config.CreatureMarket or {}
	local baseValues = marketConfig.BaseValues or {
		Common = 50,
		Uncommon = 150,
		Rare = 500,
		Epic = 1500,
		Legendary = 5000,
		Mythic = 15000,
	}
	
	local baseValue = baseValues[creatureData.Rarity] or 50
	local rarityMultiplier = (marketConfig.RarityMultipliers or {})[creatureData.Rarity] or 1.0
	
	-- Size and weight bonuses
	local sizeBonus = 1 + ((creatureData.Size or 1) - 1) * 0.15
	local weightBonus = 1 + math.min((creatureData.Weight or 0) / 100, 0.5)
	
	-- Shiny multiplier
	local shinyMultiplier = creatureData.IsShiny and 3.0 or 1.0
	
	local estimatedValue = baseValue * rarityMultiplier * sizeBonus * weightBonus * shinyMultiplier
	
	-- Clamp to reasonable range
	local minPrice = baseValue * 0.5
	local maxPrice = baseValue * rarityMultiplier * 5
	
	return math.clamp(math.floor(estimatedValue), minPrice, maxPrice)
end

-- ============================================================
-- List Creature on Market
-- ============================================================

function MarketService.Client:ListCreature(player, creatureId, listingType, price, auctionDurationHours, buyNowPrice)
	if not player or not creatureId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	
	-- Validate ownership
	local profile = DataStoreManager:GetProfile(player)
	if not profile then
		return { success = false, reason = "Profile not found" }
	end
	
	local creatureEntry = nil
	local creatureIndex = nil
	for i, entry in ipairs(profile.CreatureCollection or {}) do
		if entry.Id == creatureId then
			creatureEntry = entry
			creatureIndex = i
			break
		end
	end
	
	if not creatureEntry then
		return { success = false, reason = "Creature not found in collection" }
	end
	
	if not listingType or (listingType ~= "buynow" and listingType ~= "auction") then
		return { success = false, reason = "Invalid listing type" }
	end
	
	if not price or price <= 0 then
		return { success = false, reason = "Invalid price" }
	end
	
	-- Listing fee: 1% of ask price (minimum 1 credit)
	local listingFee = math.max(1, math.floor(price * 0.01))
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService and listingFee > 0 then
		local canAffordFee = EconomyService:CanAfford(player, listingFee, "Credits")
		if not canAffordFee then
			return { success = false, reason = "Cannot afford listing fee of " .. tostring(listingFee) .. " Credits" }
		end
		EconomyService:SpendCredits(player, listingFee)
	end
	
	local listingId = "listing_" .. tostring(player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
	
	local listing = {
		Id = listingId,
		SellerUserId = player.UserId,
		SellerName = player.DisplayName,
		CreatureData = creatureEntry,
		ListingType = listingType,
		Price = price,
		Currency = "Credits",
		BuyNowPrice = buyNowPrice or nil,
		CurrentBid = 0,
		BidderUserId = nil,
		BidderName = nil,
		Bids = {},
		AuctionEndTime = listingType == "auction" and (os.time() + (auctionDurationHours or 24) * 3600) or nil,
		ListedAt = os.time(),
		Status = "active",
	}
	
	-- Persist listing to player profile
	DataStoreManager:UpdateProfile(player, function(prof)
		if not prof.MarketListings then prof.MarketListings = {} end
		table.insert(prof.MarketListings, listing)
	end)
	
	-- Add to active cache
	activeListings[listingId] = listing
	
	log:Info(string.format("Listed: %s by %s for %d Credits (%s)", 
		creatureEntry.DisplayName, player.DisplayName, price, listingType))
	
	return {
		success = true,
		listingId = listingId,
		estimatedValue = MarketService:CalculateEstimatedValue(creatureEntry),
	}
end

-- ============================================================
-- Cancel Listing
-- ============================================================

function MarketService.Client:CancelListing(player, listingId)
	if not player or not listingId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	
	local found = false
	DataStoreManager:UpdateProfile(player, function(profile)
		if not profile.MarketListings then profile.MarketListings = {} end
		for i, listing in ipairs(profile.MarketListings) do
			if listing.Id == listingId and listing.Status == "active" then
				listing.Status = "cancelled"
				found = true
				break
			end
		end
	end)
	
	if found then
		activeListings[listingId] = nil
		log:Info(string.format("Listing cancelled: %s by %s", listingId, player.DisplayName))
		return { success = true }
	end
	
	return { success = false, reason = "Listing not found or already ended" }
end

-- ============================================================
-- Buy Now
-- ============================================================

function MarketService.Client:BuyNow(player, listingId)
	if not player or not listingId then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local EconomyService = Knit.GetService("EconomyService")
	
	-- Find listing in all profiles (search active listings + profiles)
	local listing = nil
	local sellerProfile = nil
	
	-- First check cache
	if activeListings[listingId] then
		listing = activeListings[listingId]
	else
		return { success = false, reason = "Listing not found" }
	end
	
	if listing.Status ~= "active" then
		activeListings[listingId] = nil
		return { success = false, reason = "Listing is no longer available" }
	end
	
	if listing.SellerUserId == player.UserId then
		return { success = false, reason = "Cannot buy your own listing" }
	end
	
	local price = listing.BuyNowPrice or listing.Price
	
	-- Check buyer can afford
	if not EconomyService:CanAfford(player, price, "Credits") then
		return { success = false, reason = "Not enough Credits" }
	end
	
	-- PROCESS THE SALE
	-- 1. Charge buyer
	EconomyService:SpendCredits(player, price)
	
	-- 2. Market tax: 5%
	local marketTax = math.floor(price * 0.05)
	local sellerPayout = price - marketTax
	
	-- 3. Credit seller
	local sellerPlayer = Players:GetPlayerByUserId(listing.SellerUserId)
	if EconomyService and sellerPlayer then
		EconomyService:AddCredits(sellerPlayer, sellerPayout)
	else
		-- Seller offline: credit via DataStore
		DataStoreManager:UpdateProfileByUserId(listing.SellerUserId, function(profile)
			profile.Currency = (profile.Currency or 0) + sellerPayout
		end)
	end
	
	-- 4. Transfer creature: remove from seller, add to buyer
	TradeService = Knit.GetService("TradeService")
	local transferSuccess = DataStoreManager:TransferCreature(
		listing.SellerUserId, player.UserId, listing.CreatureData
	)
	
	if not transferSuccess then
		-- Rollback payment
		EconomyService:AddCredits(player, price)
		log:Error(string.format("Creature transfer failed for listing %s", listingId))
		return { success = false, reason = "Transfer failed — purchase refunded" }
	end
	
	-- 5. Mark listing as sold
	listing.Status = "sold"
	activeListings[listingId] = nil
	
	-- Update seller's profile
	DataStoreManager:UpdateProfileByUserId(listing.SellerUserId, function(profile)
		if not profile.MarketListings then profile.MarketListings = {} end
		for i, l in ipairs(profile.MarketListings) do
			if l.Id == listingId then
				l.Status = "sold"
				break
			end
		end
	end)
	
	-- 6. Notify seller
	if sellerPlayer then
		MarketService.Client:Get("ListingSold"):Fire(sellerPlayer, {
			listingId = listingId,
			creatureName = listing.CreatureData.DisplayName,
			price = price,
			payout = sellerPayout,
			tax = marketTax,
			buyerName = player.DisplayName,
		})
	end
	
	-- 7. Update trade reputation
	local TradeService = Knit.GetService("TradeService")
	if TradeService then
		TradeService:UpdateReputation(player, 1)
		if sellerPlayer then
			TradeService:UpdateReputation(sellerPlayer, 1)
		else
			DataStoreManager:UpdateProfileByUserId(listing.SellerUserId, function(profile)
				profile.TradeReputation = (profile.TradeReputation or 0) + 1
			end)
		end
	end
	
	log:Info(string.format("Market sale: %s bought %s from %s for %d Cr (tax: %d)",
		player.DisplayName, listing.CreatureData.DisplayName,
		listing.SellerName, price, marketTax))
	
	return {
		success = true,
		creatureName = listing.CreatureData.DisplayName,
		price = price,
	}
end

-- ============================================================
-- Place Bid (Auction)
-- ============================================================

function MarketService.Client:PlaceBid(player, listingId, bidAmount)
	if not player or not listingId or not bidAmount then
		return { success = false, reason = "Invalid parameters" }
	end
	
	local listing = activeListings[listingId]
	if not listing then
		return { success = false, reason = "Listing not found" }
	end
	
	if listing.Status ~= "active" then
		return { success = false, reason = "Listing is no longer active" }
	end
	
	if listing.ListingType ~= "auction" then
		return { success = false, reason = "Not an auction listing" }
	end
	
	if listing.AuctionEndTime and os.time() > listing.AuctionEndTime then
		MarketService:EndAuction(listing)
		return { success = false, reason = "Auction has ended" }
	end
	
	if listing.SellerUserId == player.UserId then
		return { success = false, reason = "Cannot bid on your own auction" }
	end
	
	local minBid = math.max(listing.CurrentBid + 1, listing.Price)
	if bidAmount < minBid then
		return { success = false, reason = "Bid too low (min: " .. tostring(minBid) .. ")" }
	end
	
	local EconomyService = Knit.GetService("EconomyService")
	if not EconomyService:CanAfford(player, bidAmount, "Credits") then
		return { success = false, reason = "Not enough Credits" }
	end
	
	-- Refund previous bidder
	if listing.BidderUserId and listing.CurrentBid > 0 then
		local prevBidder = Players:GetPlayerByUserId(listing.BidderUserId)
		if prevBidder then
			EconomyService:AddCredits(prevBidder, listing.CurrentBid)
			MarketService.Client:Get("Outbid"):Fire(prevBidder, {
				listingId = listingId,
				creatureName = listing.CreatureData.DisplayName,
				newBid = bidAmount,
			})
		else
			-- Refund to offline player
			local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
			DataStoreManager:UpdateProfileByUserId(listing.BidderUserId, function(profile)
				profile.Currency = (profile.Currency or 0) + listing.CurrentBid
			end)
		end
	end
	
	-- Charge new bidder
	EconomyService:SpendCredits(player, bidAmount)
	
	-- Update listing
	listing.CurrentBid = bidAmount
	listing.BidderUserId = player.UserId
	listing.BidderName = player.DisplayName
	table.insert(listing.Bids, {
		userId = player.UserId,
		name = player.DisplayName,
		amount = bidAmount,
		timestamp = os.time(),
	})
	
	-- Persist bid
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	DataStoreManager:UpdateProfileByUserId(listing.SellerUserId, function(profile)
		if not profile.MarketListings then return end
		for _, l in ipairs(profile.MarketListings) do
			if l.Id == listingId then
				l.CurrentBid = bidAmount
				l.BidderUserId = player.UserId
				l.BidderName = player.DisplayName
				l.Bids = listing.Bids
				break
			end
		end
	end)
	
	-- Track bid in bidder's profile
	DataStoreManager:UpdateProfile(player, function(profile)
		if not profile.ActiveBids then profile.ActiveBids = {} end
		profile.ActiveBids[listingId] = {
			listingId = listingId,
			amount = bidAmount,
			creatureName = listing.CreatureData.DisplayName,
			sellerName = listing.SellerName,
			placedAt = os.time(),
		}
	end)
	
	log:Info(string.format("Bid: %s bid %d on %s (auction %s)", 
		player.DisplayName, bidAmount, listing.CreatureData.DisplayName, listingId))
	
	return { success = true, currentBid = bidAmount }
end

-- ============================================================
-- End Auction (called when expired and next loaded)
-- ============================================================

function MarketService:EndAuction(listing)
	if not listing or listing.Status ~= "active" then return end
	
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local EconomyService = Knit.GetService("EconomyService")
	
	listing.Status = "sold"
	activeListings[listing.Id] = nil
	
	if listing.BidderUserId and listing.CurrentBid > 0 then
		-- Auction sold — transfer creature and credit seller
		local sellerPayout = math.floor(listing.CurrentBid * 0.95) -- 5% tax
		
		local sellerPlayer = Players:GetPlayerByUserId(listing.SellerUserId)
		local buyerPlayer = Players:GetPlayerByUserId(listing.BidderUserId)
		
		-- Pay seller
		if sellerPlayer and EconomyService then
			EconomyService:AddCredits(sellerPlayer, sellerPayout)
		else
			DataStoreManager:UpdateProfileByUserId(listing.SellerUserId, function(profile)
				profile.Currency = (profile.Currency or 0) + sellerPayout
			end)
		end
		
		-- Transfer creature
		DataStoreManager:TransferCreature(listing.SellerUserId, listing.BidderUserId, listing.CreatureData)
		
		-- Notify winner
		if buyerPlayer then
			MarketService.Client:Get("AuctionWon"):Fire(buyerPlayer, {
				listingId = listing.Id,
				creatureName = listing.CreatureData.DisplayName,
				winningBid = listing.CurrentBid,
			})
		end
		
		-- Notify seller
		if sellerPlayer then
			MarketService.Client:Get("ListingSold"):Fire(sellerPlayer, {
				listingId = listing.Id,
				creatureName = listing.CreatureData.DisplayName,
				price = listing.CurrentBid,
				payout = sellerPayout,
				tax = listing.CurrentBid - sellerPayout,
				buyerName = listing.BidderName,
			})
		end
		
		log:Info(string.format("Auction ended SOLD: %s to %s for %d Cr",
			listing.CreatureData.DisplayName, listing.BidderName or "unknown", listing.CurrentBid))
	else
		-- No bids — return to seller
		if sellerPlayer then
			MarketService.Client:Get("ListingExpired"):Fire(sellerPlayer, {
				listingId = listing.Id,
				creatureName = listing.CreatureData.DisplayName,
				reason = "no_bids",
			})
		end
		listing.Status = "expired"
		log:Info(string.format("Auction expired (no bids): %s", listing.CreatureData.DisplayName))
	end
	
	-- Update seller profile
	DataStoreManager:UpdateProfileByUserId(listing.SellerUserId, function(profile)
		if not profile.MarketListings then return end
		for _, l in ipairs(profile.MarketListings) do
			if l.Id == listing.Id then
				l.Status = listing.Status
				break
			end
		end
	end)
	
	-- Clear active bids for winner
	if listing.BidderUserId then
		DataStoreManager:UpdateProfileByUserId(listing.BidderUserId, function(profile)
			if profile.ActiveBids then
				profile.ActiveBids[listing.Id] = nil
			end
		end)
	end
end

-- ============================================================
-- Browse Listings (search + filter)
-- ============================================================

function MarketService.Client:BrowseListings(player, filters)
	filters = filters or {}
	-- filters: { search = string, rarity = string, listingType = string, 
	--            sortBy = "price"|"time"|"rarity", sortOrder = "asc"|"desc",
	--            minPrice = number, maxPrice = number, page = number, pageSize = number }
	
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	
	-- Collect active listings from cache
	local results = {}
	for _, listing in pairs(activeListings) do
		if listing.Status == "active" then
			-- Check auction expiry
			if listing.ListingType == "auction" and listing.AuctionEndTime and os.time() > listing.AuctionEndTime then
				MarketService:EndAuction(listing)
			elseif listing.SellerUserId ~= player.UserId then
				-- Apply filters
				local match = true
				
				if filters.search and filters.search ~= "" then
					local searchLower = string.lower(filters.search)
					local nameLower = string.lower(listing.CreatureData.DisplayName or "")
					if not string.find(nameLower, searchLower, 1, true) then
						match = false
					end
				end
				
				if filters.rarity and listing.CreatureData.Rarity ~= filters.rarity then
					match = false
				end
				
				if filters.listingType and listing.ListingType ~= filters.listingType then
					match = false
				end
				
				if filters.minPrice and listing.Price < filters.minPrice then
					match = false
				end
				
				if filters.maxPrice and listing.Price > filters.maxPrice then
					match = false
				end
				
				if match then
					table.insert(results, listing)
				end
			end
		end
	end
	
	-- Sort
	local sortBy = filters.sortBy or "time"
	local sortDesc = filters.sortOrder ~= "asc"
	
	table.sort(results, function(a, b)
		if sortBy == "price" then
			local priceA = a.BuyNowPrice or a.Price
			local priceB = b.BuyNowPrice or b.Price
			return sortDesc and (priceA > priceB) or (priceA < priceB)
		elseif sortBy == "rarity" then
			local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
			local rA = rarityOrder[a.CreatureData.Rarity] or 0
			local rB = rarityOrder[b.CreatureData.Rarity] or 0
			return sortDesc and (rA > rB) or (rA < rB)
		else -- time
			return sortDesc and (a.ListedAt > b.ListedAt) or (a.ListedAt < b.ListedAt)
		end
	end)
	
	-- Paginate
	local page = filters.page or 1
	local pageSize = filters.pageSize or 20
	local startIdx = (page - 1) * pageSize + 1
	local endIdx = math.min(startIdx + pageSize - 1, #results)
	
	local pageResults = {}
	if startIdx <= #results then
		for i = startIdx, endIdx do
			local listing = results[i]
			table.insert(pageResults, {
				id = listing.Id,
				sellerName = listing.SellerName,
				creature = listing.CreatureData,
				listingType = listing.ListingType,
				price = listing.Price,
				buyNowPrice = listing.BuyNowPrice,
				currentBid = listing.CurrentBid,
				currency = listing.Currency,
				auctionEndTime = listing.AuctionEndTime,
				listedAt = listing.ListedAt,
				estimatedValue = MarketService:CalculateEstimatedValue(listing.CreatureData),
			})
		end
	end
	
	return {
		listings = pageResults,
		totalResults = #results,
		page = page,
		totalPages = math.max(1, math.ceil(#results / pageSize)),
	}
end

-- ============================================================
-- Get My Listings / Bids
-- ============================================================

function MarketService.Client:GetMyListings(player)
	if not player then return {} end
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	return profile.MarketListings or {}
end

function MarketService.Client:GetMyBids(player)
	if not player then return {} end
	local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
	local profile = DataStoreManager:GetProfile(player)
	return profile.ActiveBids or {}
end

-- ============================================================
-- Get Featured Listings (newest 6 active listings)
-- ============================================================

function MarketService.Client:GetFeaturedListings(player)
	local results = {}
	local count = 0
	for _, listing in pairs(activeListings) do
		if listing.Status == "active" and listing.SellerUserId ~= player.UserId then
			table.insert(results, {
				id = listing.Id,
				creature = listing.CreatureData,
				price = listing.Price,
				listingType = listing.ListingType,
				currentBid = listing.CurrentBid,
			})
			count = count + 1
			if count >= 6 then break end
		end
	end
	return results
end

return MarketService
