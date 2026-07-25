--[[
	MarketScreen.lua — Creature marketplace UI for Abyss of the Deep.
	Browse listings, search/filter, buy-now, bid on auctions, featured section.
	Wires to MarketService client signals: BrowseListings, BuyNow, PlaceBid, etc.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local MarketScreen = {}
local TweenService = game:GetService("TweenService")

local function New(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function NewCorner(radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius or UIStyles.Spacing.CornerRadius) })
end

local function NewStroke(color, transparency, thickness)
	return New("UIStroke", { Color = color or UIStyles.Colors.Border, Transparency = transparency or 0.8, Thickness = thickness or 1 })
end

local RARITY_COLORS = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(30, 255, 30),
	Rare = Color3.fromRGB(30, 30, 255),
	Epic = Color3.fromRGB(163, 53, 238),
	Legendary = Color3.fromRGB(255, 128, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
}

-- ============================================================
-- Create Market Screen
-- ============================================================

function MarketScreen:Create(parentFrame)
	local frame = New("Frame", {
		Name = "MarketScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = parentFrame,
	})
	frame.ZIndex = 5

	-- Backdrop
	local backdrop = New("Frame", {
		Size = UDim2.fromScale(0.65, 0.78),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UIStyles.Colors.DarkPanel or Color3.fromRGB(20, 20, 30),
		Parent = frame,
	})
	NewCorner(12).Parent = backdrop
	NewStroke(nil, 0.6).Parent = backdrop

	-- Title bar
	local titleBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.07),
		BackgroundColor3 = UIStyles.Colors.Accent or Color3.fromRGB(30, 120, 220),
		Parent = backdrop,
	})
	NewCorner(12).Parent = titleBar

	local titleText = New("TextLabel", {
		Text = "🏪 Creature Marketplace",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = titleBar,
	})

	local closeBtn = New("TextButton", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromScale(0.96, 0.01),
		AnchorPoint = Vector2.new(1, 0),
		Text = "✕",
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Parent = backdrop,
	})

	-- Tabs: BuyNow | Auctions | My Listings
	local tabBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.06),
		Position = UDim2.fromScale(0, 0.07),
		BackgroundColor3 = Color3.fromRGB(25, 25, 38),
		Parent = backdrop,
	})

	local tabs = {}
	local tabNames = { "All", "Buy Now", "Auctions" }
	for i, name in ipairs(tabNames) do
		local tab = New("TextButton", {
			Name = "Tab" .. name,
			Text = name,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170),
			BackgroundColor3 = i == 1 and Color3.fromRGB(40, 40, 55) or Color3.fromRGB(25, 25, 38),
			Size = UDim2.fromScale(0.18, 1),
			Position = UDim2.fromScale((i - 1) * 0.19 + 0.02, 0),
			Parent = tabBar,
		})
		NewCorner(6).Parent = tab
		tabs[name] = tab
	end

	-- My Listings button
	local myListingsBtn = New("TextButton", {
		Text = "📋 My Listings",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 200, 220),
		BackgroundColor3 = Color3.fromRGB(50, 50, 70),
		Size = UDim2.fromScale(0.13, 0.7),
		Position = UDim2.fromScale(0.85, 0.15),
		Parent = tabBar,
	})
	NewCorner(6).Parent = myListingsBtn

	-- === SEARCH BAR ===
	local searchFrame = New("Frame", {
		Size = UDim2.fromScale(1, 0.06),
		Position = UDim2.fromScale(0, 0.13),
		BackgroundColor3 = Color3.fromRGB(22, 22, 33),
		Parent = backdrop,
	})

	local searchBox = New("TextBox", {
		Name = "SearchBox",
		PlaceholderText = "Search creatures...",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Size = UDim2.fromScale(0.35, 0.6),
		Position = UDim2.fromScale(0.02, 0.2),
		Parent = searchFrame,
	})
	NewCorner(6).Parent = searchBox

	-- Rarity filter
	local rarityFilter = New("TextButton", {
		Name = "RarityFilter",
		Text = "Rarity ▼",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 200, 220),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Size = UDim2.fromOffset(90, 26),
		Position = UDim2.fromScale(0.39, 0.2),
		Parent = searchFrame,
	})
	NewCorner(6).Parent = rarityFilter

	-- Sort buttons
	local sortByPrice = New("TextButton", {
		Text = "💰 Price",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(180, 180, 200),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Size = UDim2.fromOffset(70, 26),
		Position = UDim2.fromScale(0.55, 0.2),
		Parent = searchFrame,
	})
	NewCorner(6).Parent = sortByPrice

	local sortByTime = New("TextButton", {
		Text = "🕐 Newest",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(50, 60, 75),
		Size = UDim2.fromOffset(80, 26),
		Position = UDim2.fromScale(0.65, 0.2),
		Parent = searchFrame,
	})
	NewCorner(6).Parent = sortByTime

	local refreshBtn = New("TextButton", {
		Text = "🔄",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(200, 200, 220),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Size = UDim2.fromOffset(36, 26),
		Position = UDim2.fromScale(0.92, 0.2),
		Parent = searchFrame,
	})
	NewCorner(6).Parent = refreshBtn

	-- === LISTINGS SCROLL VIEW ===
	local listingsScroll = New("ScrollingFrame", {
		Name = "ListingsScroll",
		Size = UDim2.fromScale(1, 0.68),
		Position = UDim2.fromScale(0, 0.19),
		BackgroundColor3 = Color3.fromRGB(18, 18, 28),
		ScrollBarThickness = 6,
		CanvasSize = UDim2.fromScale(0, 0),
		Parent = backdrop,
	})

	local listingsLayout = New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listingsScroll,
	})

	local listingsList = New("Frame", {
		Name = "ListingsContainer",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = listingsScroll,
	})

	local statusLabel = New("TextLabel", {
		Name = "StatusLabel",
		Text = "Loading listings...",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 150, 170),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.05),
		Position = UDim2.fromScale(0, 0.88),
		Parent = backdrop,
	})

	-- === bottom bar — listing action ===
	local bottomBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.07),
		Position = UDim2.fromScale(0, 0.93),
		BackgroundColor3 = Color3.fromRGB(25, 25, 35),
		Parent = backdrop,
	})
	NewCorner(12).Parent = bottomBar

	local listBtn = New("TextButton", {
		Name = "ListCreatureBtn",
		Text = "📤 List Creature",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(50, 150, 80),
		Size = UDim2.fromScale(0.22, 0.65),
		Position = UDim2.fromScale(0.02, 0.17),
		Parent = bottomBar,
	})
	NewCorner(6).Parent = listBtn

	local marketFeeLabel = New("TextLabel", {
		Text = "5% market fee · 1% listing fee",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 140, 160),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.3, 0.5),
		Position = UDim2.fromScale(0.27, 0.25),
		Parent = bottomBar,
	})

	-- ============================================================
	-- Listing Card Builder
	-- ============================================================

	function MarketScreen:CreateListingCard(listing, parentContainer)
		local card = New("Frame", {
			Name = "Card_" .. listing.id,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(28, 28, 40),
			Parent = parentContainer,
		})
		NewCorner(6).Parent = card
		NewStroke(RARITY_COLORS[listing.creature.Rarity] or Color3.fromRGB(150, 150, 150), 0.4, 2).Parent = card

		local creature = listing.creature
		local rarityColor = RARITY_COLORS[creature.Rarity] or Color3.fromRGB(150, 150, 150)

		-- Left: creature info
		local infoFrame = New("Frame", {
			Size = UDim2.fromScale(0.55, 1),
			Position = UDim2.fromScale(0.01, 0),
			BackgroundTransparency = 1,
			Parent = card,
		})

		local emoji = New("TextLabel", {
			Text = creature.IsShiny and "✨ " or "",
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(24, 22),
			Position = UDim2.fromOffset(4, 4),
			Parent = infoFrame,
		})

		local nameLabel = New("TextLabel", {
			Text = creature.DisplayName or creature.Id,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.9, 0.4),
			Position = UDim2.fromOffset(30, 4),
			Parent = infoFrame,
		})

		local rarityLabel = New("TextLabel", {
			Text = creature.Rarity,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = rarityColor,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.4, 0.35),
			Position = UDim2.fromOffset(30, 24),
			Parent = infoFrame,
		})

		local sellerLabel = New("TextLabel", {
			Text = "by " .. (listing.sellerName or "Unknown"),
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = Color3.fromRGB(140, 140, 160),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.5, 0.3),
			Position = UDim2.fromOffset(4, 26),
			Parent = infoFrame,
		})

		-- Right: price + action
		local actionFrame = New("Frame", {
			Size = UDim2.fromScale(0.43, 1),
			Position = UDim2.fromScale(0.56, 0),
			BackgroundTransparency = 1,
			Parent = card,
		})

		local priceLabel = New("TextLabel", {
			Text = "₡" .. tostring(listing.price),
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(255, 220, 80),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.6, 0.5),
			Position = UDim2.fromScale(0, 0.05),
			Parent = actionFrame,
		})

		if listing.listingType == "auction" and listing.currentBid > 0 then
			priceLabel.Text = "₡" .. tostring(listing.currentBid) .. " bid"
		end

		local actionBtn = New("TextButton", {
			Text = listing.listingType == "buynow" and "Buy Now" or "Bid",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundColor3 = listing.listingType == "buynow" and Color3.fromRGB(40, 160, 60) or Color3.fromRGB(200, 130, 40),
			Size = UDim2.fromScale(0.8, 0.45),
			Position = UDim2.fromScale(0.1, 0.5),
			Parent = actionFrame,
		})
		NewCorner(4).Parent = actionBtn

		card:SetAttribute("listingData", listing)
		card:SetAttribute("actionBtn", actionBtn)
		card:SetAttribute("priceLabel", priceLabel)

		return card
	end

	-- Expose elements
	frame:SetAttribute("UIElements", {
		frame = frame,
		backdrop = backdrop,
		searchBox = searchBox,
		searchFrame = searchFrame,
		listingsScroll = listingsScroll,
		listingsLayout = listingsLayout,
		listingsList = listingsList,
		listingsContainer = listingsList,
		statusLabel = statusLabel,
		bottomBar = bottomBar,
		listBtn = listBtn,
		myListingsBtn = myListingsBtn,
		tabs = tabs,
		tabBar = tabBar,
		rarityFilter = rarityFilter,
		sortByPrice = sortByPrice,
		sortByTime = sortByTime,
		refreshBtn = refreshBtn,
		CreateListingCard = self.CreateListingCard,
	})

	closeBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	return frame
end

function MarketScreen:ClearListings()
	if not self.Frame then return end
	local elements = self.Frame:GetAttribute("UIElements")
	if elements and elements.listingsContainer then
		for _, child in ipairs(elements.listingsContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
	end
end

function MarketScreen:Show()
	if self.Frame then self.Frame.Visible = true end
end

function MarketScreen:Hide()
	if self.Frame then self.Frame.Visible = false end
end

return MarketScreen
