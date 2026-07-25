--[[
	MyListingsScreen.lua — Manage your market listings and active bids.
	Shows: active listings (with cancel), sold history, active bids.
	Wires to MarketService client signals: GetMyListings, GetMyBids, CancelListing.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local MyListingsScreen = {}
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

-- ============================================================
-- Create Screen
-- ============================================================

function MyListingsScreen:Create(parentFrame)
	local frame = New("Frame", {
		Name = "MyListingsScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = parentFrame,
	})
	frame.ZIndex = 6

	local backdrop = New("Frame", {
		Size = UDim2.fromScale(0.5, 0.68),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UIStyles.Colors.DarkPanel or Color3.fromRGB(20, 20, 30),
		Parent = frame,
	})
	NewCorner(12).Parent = backdrop
	NewStroke(nil, 0.6).Parent = backdrop

	-- Title
	local titleBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.08),
		BackgroundColor3 = Color3.fromRGB(50, 50, 70),
		Parent = backdrop,
	})
	NewCorner(12).Parent = titleBar

	New("TextLabel", {
		Text = "📋 My Listings & Bids",
		Font = Enum.Font.GothamBold,
		TextSize = 17,
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

	-- Tabs: Listings | Bids
	local tabBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.06),
		Position = UDim2.fromScale(0, 0.09),
		BackgroundColor3 = Color3.fromRGB(25, 25, 38),
		Parent = backdrop,
	})

	local listingsTab = New("TextButton", {
		Text = "📦 My Listings",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Size = UDim2.fromScale(0.48, 1),
		Parent = tabBar,
	})
	NewCorner(6).Parent = listingsTab

	local bidsTab = New("TextButton", {
		Text = "💰 My Bids",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(150, 150, 170),
		BackgroundColor3 = Color3.fromRGB(25, 25, 38),
		Size = UDim2.fromScale(0.48, 1),
		Position = UDim2.fromScale(0.52, 0),
		Parent = tabBar,
	})
	NewCorner(6).Parent = bidsTab

	-- === LISTINGS SCROLL ===
	local listingsScroll = New("ScrollingFrame", {
		Name = "ListingsScroll",
		Size = UDim2.fromScale(1, 0.72),
		Position = UDim2.fromScale(0, 0.16),
		BackgroundColor3 = Color3.fromRGB(18, 18, 28),
		ScrollBarThickness = 6,
		CanvasSize = UDim2.fromScale(0, 0),
		Parent = backdrop,
	})

	New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listingsScroll,
	})

	local listingsContainer = New("Frame", {
		Name = "ListingsContainer",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = listingsScroll,
	})

	-- === BIDS SCROLL (hidden initially) ===
	local bidsScroll = New("ScrollingFrame", {
		Name = "BidsScroll",
		Size = UDim2.fromScale(1, 0.72),
		Position = UDim2.fromScale(0, 0.16),
		BackgroundColor3 = Color3.fromRGB(18, 18, 28),
		ScrollBarThickness = 6,
		CanvasSize = UDim2.fromScale(0, 0),
		Visible = false,
		Parent = backdrop,
	})

	New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bidsScroll,
	})

	local bidsContainer = New("Frame", {
		Name = "BidsContainer",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = bidsScroll,
	})

	-- Status text
	local statusLabel = New("TextLabel", {
		Name = "StatusLabel",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(150, 150, 170),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.06),
		Position = UDim2.fromScale(0, 0.89),
		Parent = backdrop,
	})

	-- Bottom bar
	local bottomBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.07),
		Position = UDim2.fromScale(0, 0.93),
		BackgroundColor3 = Color3.fromRGB(25, 25, 35),
		Parent = backdrop,
	})
	NewCorner(12).Parent = bottomBar

	local closeBottomBtn = New("TextButton", {
		Text = "Close",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(80, 80, 100),
		Size = UDim2.fromScale(0.2, 0.65),
		Position = UDim2.fromScale(0.4, 0.17),
		Parent = bottomBar,
	})
	NewCorner(6).Parent = closeBottomBtn

	-- === LISTING CARD BUILDER ===
	function MyListingsScreen:CreateListingCard(listing, container)
		local card = New("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(28, 28, 40),
			Parent = container,
		})
		NewCorner(6).Parent = card

		local infoFrame = New("Frame", {
			Size = UDim2.fromScale(0.6, 1),
			Position = UDim2.fromScale(0.01, 0),
			BackgroundTransparency = 1,
			Parent = card,
		})

		New("TextLabel", {
			Text = listing.CreatureData.DisplayName or listing.CreatureData.Id,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.45),
			Position = UDim2.fromOffset(4, 3),
			Parent = infoFrame,
		})

		local statusText = listing.Status == "active" and "🟢 Active" or
			listing.Status == "sold" and "🟡 Sold" or "🔴 " .. (listing.Status or "Ended")

		New("TextLabel", {
			Text = statusText .. " · ₡" .. tostring(listing.Price),
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = Color3.fromRGB(140, 140, 160),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.4),
			Position = UDim2.fromOffset(4, 22),
			Parent = infoFrame,
		})

		if listing.Status == "active" then
			local cancelBtn = New("TextButton", {
				Text = "Cancel",
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(180, 50, 50),
				Size = UDim2.fromOffset(60, 24),
				Position = UDim2.fromScale(0.82, 0.25),
				Parent = card,
			})
			NewCorner(4).Parent = cancelBtn
			card:SetAttribute("cancelBtn", cancelBtn)
		end

		return card
	end

	-- === BID CARD BUILDER ===
	function MyListingsScreen:CreateBidCard(bid, container)
		local card = New("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(28, 28, 40),
			Parent = container,
		})
		NewCorner(6).Parent = card

		New("TextLabel", {
			Text = bid.creatureName or "Unknown",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.6, 0.5),
			Position = UDim2.fromOffset(6, 4),
			Parent = card,
		})

		New("TextLabel", {
			Text = "Bid: ₡" .. tostring(bid.amount) .. " · Seller: " .. (bid.sellerName or "Unknown"),
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = Color3.fromRGB(140, 140, 160),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.4),
			Position = UDim2.fromOffset(6, 22),
			Parent = card,
		})

		return card
	end

	-- Tab switching
	listingsTab.MouseButton1Click:Connect(function()
		listingsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		listingsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		bidsTab.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
		bidsTab.TextColor3 = Color3.fromRGB(150, 150, 170)
		listingsScroll.Visible = true
		bidsScroll.Visible = false
		statusLabel.Text = ""
	end)

	bidsTab.MouseButton1Click:Connect(function()
		bidsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		bidsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		listingsTab.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
		listingsTab.TextColor3 = Color3.fromRGB(150, 150, 170)
		listingsScroll.Visible = false
		bidsScroll.Visible = true
		statusLabel.Text = ""
	end)

	closeBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	closeBottomBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	-- Expose
	frame:SetAttribute("UIElements", {
		frame = frame,
		listingsContainer = listingsContainer,
		bidsContainer = bidsContainer,
		statusLabel = statusLabel,
		CreateListingCard = self.CreateListingCard,
		CreateBidCard = self.CreateBidCard,
	})

	return frame
end

function MyListingsScreen:ClearListings()
	if not self.Frame then return end
	local elements = self.Frame:GetAttribute("UIElements")
	for _, name in ipairs({ "listingsContainer", "bidsContainer" }) do
		local container = elements[name]
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
		end
	end
end

function MyListingsScreen:Show()
	if self.Frame then self.Frame.Visible = true end
end

function MyListingsScreen:Hide()
	if self.Frame then self.Frame.Visible = false end
end

return MyListingsScreen
