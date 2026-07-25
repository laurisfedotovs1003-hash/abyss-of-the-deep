--[[
	TradeScreen.lua — P2P creature trading UI for Abyss of the Deep.
	2-slot offer window per player, double-confirmation anti-scam flow.
	Wires to TradeService client signals: SendTradeRequest, AddTradeOffer,
	ConfirmTrade, CancelTrade, etc.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local TradeScreen = {}
local TweenService = game:GetService("TweenService")

-- Helpers
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
-- Trade Screen Frame
-- ============================================================

function TradeScreen:Create(parentFrame)
	local RARITY_COLORS = {
		Common = UIStyles.Colors.RarityCommon or Color3.fromRGB(150, 150, 150),
		Uncommon = UIStyles.Colors.RarityUncommon or Color3.fromRGB(30, 255, 30),
		Rare = UIStyles.Colors.RarityRare or Color3.fromRGB(30, 30, 255),
		Epic = UIStyles.Colors.RarityEpic or Color3.fromRGB(163, 53, 238),
		Legendary = UIStyles.Colors.RarityLegendary or Color3.fromRGB(255, 128, 0),
		Mythic = UIStyles.Colors.RarityMythic or Color3.fromRGB(255, 50, 50),
	}

	-- Main container
	local frame = New("Frame", {
		Name = "TradeScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = parentFrame,
	})
	frame.ZIndex = 5

	-- Backdrop
	local backdrop = New("Frame", {
		Size = UDim2.fromScale(0.55, 0.72),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UIStyles.Colors.DarkPanel or Color3.fromRGB(20, 20, 30),
		Parent = frame,
	})
	NewCorner(12).Parent = backdrop
	NewStroke(nil, 0.6).Parent = backdrop

	-- Title bar
	local titleBar = New("Frame", {
		Size = UDim2.fromScale(1, 0.08),
		BackgroundColor3 = UIStyles.Colors.Accent or Color3.fromRGB(30, 120, 220),
		Parent = backdrop,
	})
	NewCorner(12).Parent = titleBar
	local titleText = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = "🤝 Creature Trade",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Parent = titleBar,
	})

	-- Close button
	local closeBtn = New("TextButton", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromScale(0.96, 0.02),
		AnchorPoint = Vector2.new(1, 0),
		Text = "✕",
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Parent = backdrop,
	})

	-- === PARTNER SEARCH SECTION ===
	local searchSection = New("Frame", {
		Name = "SearchSection",
		Size = UDim2.fromScale(1, 0.1),
		Position = UDim2.fromScale(0, 0.1),
		BackgroundTransparency = 1,
		Parent = backdrop,
	})
	local searchLabel = New("TextLabel", {
		Text = "Trade with:",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(180, 180, 200),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(80, 24),
		Position = UDim2.fromScale(0.03, 0.25),
		Parent = searchSection,
	})
	local searchBox = New("TextBox", {
		PlaceholderText = "Enter player name...",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.18, 0.25),
		Parent = searchSection,
	})
	NewCorner(6).Parent = searchBox

	local sendBtn = New("TextButton", {
		Text = "Send Request",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = UIStyles.Colors.Accent or Color3.fromRGB(30, 120, 220),
		Size = UDim2.fromOffset(100, 28),
		Position = UDim2.fromScale(0.7, 0.2),
		Parent = searchSection,
	})
	NewCorner(6).Parent = sendBtn

	local searchStatus = New("TextLabel", {
		Name = "SearchStatus",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 200, 50),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.35, 0.4),
		Position = UDim2.fromScale(0.63, 0.6),
		Parent = searchSection,
	})

	-- === TRADE CONTENT (two columns) ===
	local tradeContent = New("Frame", {
		Name = "TradeContent",
		Size = UDim2.fromScale(1, 0.68),
		Position = UDim2.fromScale(0, 0.22),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = backdrop,
	})

	-- Your offer column (left)
	local yourCol = New("Frame", {
		Size = UDim2.fromScale(0.45, 1),
		Position = UDim2.fromScale(0.03, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 40),
		Parent = tradeContent,
	})
	NewCorner(8).Parent = yourCol

	local yourTitle = New("TextLabel", {
		Text = "Your Offer",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(100, 200, 255),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.08),
		Parent = yourCol,
	})

	local yourSlots = {}
	for i = 1, 2 do
		local slot = New("Frame", {
			Name = "YourSlot" .. i,
			Size = UDim2.fromScale(0.9, 0.38),
			Position = UDim2.fromScale(0.05, 0.1 + (i - 1) * 0.42),
			BackgroundColor3 = Color3.fromRGB(40, 40, 55),
			Parent = yourCol,
		})
		NewCorner(6).Parent = slot
		NewStroke(nil, 0.5).Parent = slot

		local slotText = New("TextLabel", {
			Text = "Drop creature here",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(120, 120, 140),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = slot,
		})
		yourSlots[i] = { frame = slot, text = slotText }
	end

	-- Their offer column (right)
	local theirCol = New("Frame", {
		Size = UDim2.fromScale(0.45, 1),
		Position = UDim2.fromScale(0.52, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 40),
		Parent = tradeContent,
	})
	NewCorner(8).Parent = theirCol

	local theirTitle = New("TextLabel", {
		Text = "Their Offer",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 150, 100),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.08),
		Parent = theirCol,
	})

	local theirSlots = {}
	for i = 1, 2 do
		local slot = New("Frame", {
			Name = "TheirSlot" .. i,
			Size = UDim2.fromScale(0.9, 0.38),
			Position = UDim2.fromScale(0.05, 0.1 + (i - 1) * 0.42),
			BackgroundColor3 = Color3.fromRGB(40, 40, 55),
			Parent = theirCol,
		})
		NewCorner(6).Parent = slot
		NewStroke(nil, 0.5).Parent = slot

		local slotText = New("TextLabel", {
			Text = "Waiting...",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(120, 120, 140),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = slot,
		})
		theirSlots[i] = { frame = slot, text = slotText }
	end

	-- Partner name display
	local partnerNameLabel = New("TextLabel", {
		Name = "PartnerName",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(180, 180, 200),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.05),
		Position = UDim2.fromScale(0, 0.15),
		Parent = backdrop,
	})

	-- === BOTTOM BAR — Confirm/Cancel ===
	local bottomBar = New("Frame", {
		Name = "BottomBar",
		Size = UDim2.fromScale(1, 0.12),
		Position = UDim2.fromScale(0, 0.88),
		BackgroundColor3 = Color3.fromRGB(25, 25, 35),
		Parent = backdrop,
	})
	NewCorner(12).Parent = bottomBar

	local confirmBtn = New("TextButton", {
		Name = "ConfirmBtn",
		Text = "Confirm Trade 🔒",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(40, 180, 60),
		Size = UDim2.fromScale(0.35, 0.6),
		Position = UDim2.fromScale(0.05, 0.2),
		Parent = bottomBar,
	})
	NewCorner(6).Parent = confirmBtn

	local cancelBtn = New("TextButton", {
		Name = "CancelBtn",
		Text = "Cancel ✕",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(180, 50, 50),
		Size = UDim2.fromScale(0.25, 0.6),
		Position = UDim2.fromScale(0.7, 0.2),
		Parent = bottomBar,
	})
	NewCorner(6).Parent = cancelBtn

	-- Confirmation status indicators
	local yourConfirmDot = New("Frame", {
		Name = "YourConfirmDot",
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromScale(0.42, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(100, 100, 100),
		Parent = bottomBar,
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = yourConfirmDot

	local theirConfirmDot = New("Frame", {
		Name = "TheirConfirmDot",
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromScale(0.5, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(100, 100, 100),
		Parent = bottomBar,
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = theirConfirmDot

	local confirmHint = New("TextLabel", {
		Name = "ConfirmHint",
		Text = "Both players must confirm to complete trade",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(150, 150, 170),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.55, 0.3),
		Position = UDim2.fromScale(0.42, 0.75),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = bottomBar,
	})

	-- === TRADE COMPLETE OVERLAY ===
	local completeOverlay = New("Frame", {
		Name = "TradeComplete",
		Size = UDim2.fromScale(0.8, 0.5),
		Position = UDim2.fromScale(0.1, 0.25),
		BackgroundColor3 = Color3.fromRGB(20, 30, 20),
		Visible = false,
		ZIndex = 10,
		Parent = backdrop,
	})
	NewCorner(12).Parent = completeOverlay
	NewStroke(Color3.fromRGB(40, 180, 60), 0.3, 2).Parent = completeOverlay

	local completeText = New("TextLabel", {
		Text = "✅ Trade Complete!",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(40, 255, 60),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.3),
		Parent = completeOverlay,
	})

	local completeDetails = New("TextLabel", {
		Name = "CompleteDetails",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.9, 0.4),
		Position = UDim2.fromScale(0.05, 0.35),
		TextWrapped = true,
		Parent = completeOverlay,
	})

	local doneBtn = New("TextButton", {
		Text = "Close",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(50, 150, 50),
		Size = UDim2.fromOffset(100, 30),
		Position = UDim2.fromScale(0.4, 0.75),
		Parent = completeOverlay,
	})
	NewCorner(6).Parent = doneBtn

	-- ============================================================
	-- Bind Events
	-- ============================================================

	closeBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	doneBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	-- Expose UI elements for external wiring
	frame:SetAttribute("UIElements", {
		frame = frame,
		tradeContent = tradeContent,
		searchSection = searchSection,
		searchBox = searchBox,
		sendBtn = sendBtn,
		searchStatus = searchStatus,
		confirmBtn = confirmBtn,
		cancelBtn = cancelBtn,
		yourSlots = yourSlots,
		theirSlots = theirSlots,
		partnerNameLabel = partnerNameLabel,
		yourConfirmDot = yourConfirmDot,
		theirConfirmDot = theirConfirmDot,
		completeOverlay = completeOverlay,
		completeDetails = completeDetails,
		backdrop = backdrop,
	})

	return frame
end

-- ============================================================
-- UI Update Helpers
-- ============================================================

function TradeScreen:UpdateSlot(slot, creatureData)
	if not slot then return end
	slot.text.Text = creatureData and (creatureData.DisplayName .. " (" .. creatureData.Rarity .. ")") or "Drop creature here"
	if creatureData then
		slot.frame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		slot.text.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		slot.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		slot.text.TextColor3 = Color3.fromRGB(120, 120, 140)
	end
end

function TradeScreen:UpdateConfirmDots(yourConfirmed, theirConfirmed)
	local elements = self.Frame and self.Frame:GetAttribute("UIElements")
	if not elements then return end
	elements.yourConfirmDot.BackgroundColor3 = yourConfirmed and Color3.fromRGB(40, 255, 60) or Color3.fromRGB(100, 100, 100)
	elements.theirConfirmDot.BackgroundColor3 = theirConfirmed and Color3.fromRGB(40, 255, 60) or Color3.fromRGB(100, 100, 100)
end

function TradeScreen:Show()
	if self.Frame then
		self.Frame.Visible = true
	end
end

function TradeScreen:Hide()
	if self.Frame then
		self.Frame.Visible = false
	end
end

return TradeScreen
