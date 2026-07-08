--[[
    ShopScreen.lua — Enhanced Shop screen for Abyss of the Deep
    5 categories: Fishing Rods, Diving Gear, Consumables, Cosmetics, Base Building
    Premium items, stat comparison, confirmation dialogs, anomaly banner.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local ShopScreen = {}
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
-- Category Definitions
-- ============================================================

local CATEGORIES = {
    { name = "Fishing Rods",        icon = "🎣" },
    { name = "Diving Gear",         icon = "🤿" },
    { name = "Consumables",         icon = "🧪" },
    { name = "Cosmetics",           icon = "✨" },
    { name = "Base Building",       icon = "🏗️" },
}

-- Sample shop items per category using Config-like structure
local SHOP_ITEMS = {
    ["Fishing Rods"] = {
        { name = "Basic Rod",         icon = "🎣", tier = 1, stats = "Catch Rate: 1.0x · Range: 10m",          price = 0,    currency = "Credits", desc = "Simple starter rod", premium = false },
        { name = "Carbon Fiber Rod",  icon = "🎣", tier = 2, stats = "Catch Rate: 1.3x · Range: 20m",          price = 200,  currency = "Credits", desc = "Lightweight with better sensitivity", premium = false },
        { name = "Titanium Rod",      icon = "🎣", tier = 3, stats = "Catch Rate: 1.6x · Range: 35m",          price = 600,  currency = "Credits", desc = "Durable deep-sea rod", premium = false },
        { name = "Abyssal Harpoon",   icon = "🔱", tier = 4, stats = "Catch Rate: 2.0x · Range: 50m",          price = 2000, currency = "Credits", desc = "For the largest deep-sea creatures", premium = false },
        { name = "Void Rod",          icon = "🎣", tier = 5, stats = "Catch Rate: 2.5x · Range: 60m · Glow",   price = 800,  currency = "Robux",  desc = "Legendary glowing rod", premium = true },
    },
    ["Diving Gear"] = {
        { name = "Basic Gear",        icon = "🤿", tier = 1, stats = "O₂: +0 · Speed: 1.0x · Depth: 200m",     price = 0,    currency = "Credits", desc = "Standard snorkeling gear" },
        { name = "Scuba Kit",         icon = "🫧", tier = 2, stats = "O₂: +50 · Speed: 1.1x · Depth: 1,000m", price = 150,  currency = "Credits", desc = "Tank and regulator" },
        { name = "Advanced Suit",     icon = "🦺", tier = 3, stats = "O₂: +125 · Speed: 1.2x · Depth: 4,000m", price = 400,  currency = "Credits", desc = "Pressure-resistant" },
        { name = "Bathysphere",       icon = "🛸", tier = 4, stats = "O₂: +250 · Speed: 0.9x · Depth: 6,000m", price = 1000, currency = "Credits", desc = "Heavy submersible" },
        { name = "Abyssal Exosuit",   icon = "⚙️", tier = 5, stats = "O₂: +500 · Speed: 1.4x · Depth: 11,000m",price = 3000, currency = "Credits", desc = "Cutting-edge tech" },
        { name = "Speed Flippers",    icon = "🏊", tier = 2, stats = "Speed: +20% · Manueverability: +15%",    price = 80,   currency = "Robux",  desc = "Premium swim assist", premium = true },
    },
    ["Consumables"] = {
        { name = "Oxygen Tank (S)",   icon = "🫧", tier = 1, stats = "Restores +50 O₂ instantly",               price = 25,   currency = "Credits", desc = "Small oxygen refill", stackable = 10 },
        { name = "Oxygen Tank (L)",   icon = "🫧", tier = 2, stats = "Restores +200 O₂ instantly",             price = 80,   currency = "Credits", desc = "Large oxygen refill", stackable = 5 },
        { name = "Standard Bait",     icon = "🪱", tier = 1, stats = "Common fish bait · 3 uses",              price = 15,   currency = "Credits", desc = "Attracts common fish", stackable = 20 },
        { name = "Rare Bait",         icon = "🪱", tier = 2, stats = "Rare fish bait · 3 uses",                price = 50,   currency = "Credits", desc = "Attracts rare fish", stackable = 10 },
        { name = "Speed Boost",       icon = "⚡", tier = 1, stats = "+30% speed for 30s",                      price = 40,   currency = "Credits", desc = "Short speed burst", stackable = 15 },
        { name = "Anomaly Shield",    icon = "🛡️", tier = 3, stats = "Blocks anomaly damage for 60s",          price = 120,  currency = "Credits", desc = "Anomaly protection", stackable = 5 },
        { name = "Lucky Lure",        icon = "🍀", tier = 2, stats = "Doubles rare encounter rate · 10 min",   price = 60,   currency = "Robux",  desc = "Premium lure", premium = true, stackable = 5 },
    },
    ["Cosmetics"] = {
        { name = "Neon Diving Suit",  icon = "👕", tier = 1, stats = "Custom neon skin for diving suit",        price = 150,  currency = "Credits", desc = "Stand out in the depths" },
        { name = "Glow Rod Skin",     icon = "✨", tier = 1, stats = "Bioluminescent rod appearance",           price = 200,  currency = "Credits", desc = "Makes your rod glow" },
        { name = "Submarine Wrap",    icon = "🚤", tier = 1, stats = "Camo pattern for your sub",              price = 300,  currency = "Credits", desc = "Submarine camo skin" },
        { name = "Depth Crown",       icon = "👑", tier = 2, stats = "Animated crown · shows depth record",     price = 500,  currency = "Robux",  desc = "Flex your achievements", premium = true },
        { name = "Phantom Aura",      icon = "🌀", tier = 3, stats = "Misty aura effect while diving",          price = 800,  currency = "Robux",  desc = "Rare phantom effect", premium = true },
    },
    ["Base Building"] = {
        { name = "Habitat Module",    icon = "🏠", tier = 1, stats = "Living quarters · oxygen regen",          price = 200,  currency = "Credits", desc = "Rest while deep diving", costRP = 10 },
        { name = "Greenhouse",        icon = "🌱", tier = 2, stats = "Grows resources over time",              price = 300,  currency = "Credits", desc = "Passive income", costRP = 20 },
        { name = "Research Lab",      icon = "🔬", tier = 3, stats = "+50% Research Point gain",              price = 500,  currency = "Credits", desc = "Boost RP gains", costRP = 40 },
        { name = "Defense Turret",    icon = "🔫", tier = 2, stats = "Repels creatures during anomalies",      price = 400,  currency = "Credits", desc = "Anomaly defense", costRP = 15 },
        { name = "Beacon of Light",   icon = "💡", tier = 3, stats = "Illuminates large area",                 price = 800,  currency = "Credits", desc = "Light up the deep", costRP = 30 },
        { name = "Crystal Resonator", icon = "💎", tier = 3, stats = "Doubles crystal yield",                   price = 600,  currency = "Robux",  desc = "Crystal multiplier", premium = true },
    },
}

-- ============================================================
-- Sparkle effect for premium items
-- ============================================================

local function AddSparkleEffect(frame)
    local sparkle = New("ImageLabel", {
        Name = "Sparkle",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5025537645", -- Soft glow circle
        ImageColor3 = UIStyles.Colors.Gold,
        ImageTransparency = 0.6,
        ZIndex = 5,
        Parent = frame,
    })

    -- Pulse animation
    local pulse = TweenService:Create(sparkle,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
        { ImageTransparency = 0.3 }
    )
    pulse:Play()
    return sparkle
end

-- ============================================================
-- Build confirmation dialog
-- ============================================================

local function BuildConfirmationDialog(parent, itemData, onConfirm)
    local dimmer = New("Frame", {
        Name = "ConfirmDimmer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.7,
        ZIndex = 50,
        Parent = parent,
    })

    local dialog = New("Frame", {
        Name = "ConfirmDialog",
        Size = UDim2.fromOffset(300, 220),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.05,
        ZIndex = 51,
        Parent = dimmer,
    })
    NewCorner(16).Parent = dialog
    NewStroke(UIStyles.Colors.Cyan, 0.4, 2).Parent = dialog

    -- Icon
    local icon = UIComponents.CreateTextLabel({
        Name = "Icon",
        Text = itemData.icon or "📦",
        Size = UDim2.fromOffset(48, 48),
        Position = UDim2.fromScale(0.5, 0.18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextSize = 40,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 52,
        Parent = dialog,
    })

    -- Text
    local confirmText = UIComponents.CreateTextLabel({
        Name = "Text",
        Text = ("Buy " .. (itemData.name or "?") .. "?"),
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.fromScale(0.5, 0.35),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.ItemName,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 52,
        Parent = dialog,
    })

    local priceStr = ""
    if itemData.currency == "Robux" then
        priceStr = "⭐ " .. tostring(itemData.price) .. " Robux"
    else
        priceStr = "🪙 " .. tostring(itemData.price) .. " Credits"
        if itemData.costRP then
            priceStr = priceStr .. " + ◎ " .. tostring(itemData.costRP) .. " RP"
        end
    end

    local priceLabel = UIComponents.CreateTextLabel({
        Name = "Price",
        Text = priceStr,
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.fromScale(0.5, 0.45),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.Gold,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 52,
        Parent = dialog,
    })

    local descLabel = UIComponents.CreateTextLabel({
        Name = "Desc",
        Text = itemData.desc or "",
        Size = UDim2.new(1, -24, 0, 16),
        Position = UDim2.fromScale(0.5, 0.52),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.TextSecondary,
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 52,
        Parent = dialog,
    })

    -- Buttons
    local btnFrame = New("Frame", {
        Name = "BtnFrame",
        Size = UDim2.new(1, -32, 0, 44),
        Position = UDim2.fromScale(0.5, 0.72),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 52,
        Parent = dialog,
    })

    -- Cancel button
    local cancelBtn = UIComponents.CreateButton({
        Name = "Cancel",
        Text = "CANCEL",
        Size = UDim2.fromOffset(120, 44),
        Position = UDim2.fromScale(0.25, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Color = UIStyles.Colors.Elevated,
        TextColor = UIStyles.Colors.TextSecondary,
        FontSize = UIStyles.FontSizes.Small,
        CornerRadius = 10,
        Stroke = true,
        Callback = function()
            dimmer:Destroy()
        end,
        Parent = btnFrame,
    })

    -- Confirm button
    local confirmBtn = UIComponents.CreateButton({
        Name = "Confirm",
        Text = "BUY",
        Size = UDim2.fromOffset(120, 44),
        Position = UDim2.fromScale(0.75, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Color = UIStyles.Colors.Cyan,
        TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.Small,
        CornerRadius = 10,
        Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
        Callback = function()
            dimmer:Destroy()
            if onConfirm then
                onConfirm()
            end
        end,
        Parent = btnFrame,
    })

    -- Animate in
    dialog.Size = UDim2.fromOffset(0, 0)
    dialog:TweenSize(
        UDim2.fromOffset(320, 240),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.35,
        true
    )

    return dimmer
end

-- ============================================================
-- Build stats comparison panel
-- ============================================================

local function BuildStatComparison(parent, itemData, equippedData)
    local panel = New("Frame", {
        Name = "StatComparison",
        Size = UDim2.new(1, -24, 0, 70),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.CardBG,
        BackgroundTransparency = 0.4,
        ZIndex = 15,
        Visible = false,
        Parent = parent,
    })
    NewCorner(10).Parent = panel
    NewStroke(UIStyles.Colors.Cyan, 0.6, 1).Parent = panel

    local header = UIComponents.CreateTextLabel({
        Name = "Header",
        Text = "⬆ STAT COMPARISON",
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.fromOffset(6, 4),
        Color = UIStyles.Colors.Cyan,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Tiny,
        Parent = panel,
    })

    local equippedText = UIComponents.CreateTextLabel({
        Name = "Equipped",
        Text = "Equipped: " .. (equippedData and equippedData.name or "None"),
        Size = UDim2.new(0.5, -8, 0, 18),
        Position = UDim2.fromOffset(6, 26),
        Color = UIStyles.Colors.TextSecondary,
        TextSize = UIStyles.FontSizes.Tiny,
        Parent = panel,
    })

    local newText = UIComponents.CreateTextLabel({
        Name = "New",
        Text = "New: " .. (itemData and itemData.name or "?"),
        Size = UDim2.new(0.5, -8, 0, 18),
        Position = UDim2.new(0.5, 2, 0, 26),
        Color = UIStyles.Colors.Cyan,
        TextSize = UIStyles.FontSizes.Tiny,
        Parent = panel,
    })

    -- Stat differences (simplified for demo)
    local diffLabel = UIComponents.CreateTextLabel({
        Name = "Diff",
        Text = "↑ Catch Rate +0.3x · ↑ Range +10m",
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.fromOffset(6, 46),
        Color = UIStyles.Colors.BioGreen,
        TextSize = UIStyles.FontSizes.Tiny,
        Parent = panel,
    })

    return panel
end

-- ============================================================
-- Build anomaly banner
-- ============================================================

local function BuildAnomalyBanner(parent)
    local banner = New("Frame", {
        Name = "AnomalyBanner",
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.fromScale(0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = UIStyles.Colors.Danger,
        BackgroundTransparency = 0.4,
        ZIndex = 10,
        Visible = false,
        Parent = parent,
    })
    NewCorner(8).Parent = banner
    NewStroke(UIStyles.Colors.Danger, 0.4, 2).Parent = banner

    local label = UIComponents.CreateTextLabel({
        Name = "Label",
        Text = "⚠ ANOMALY ACTIVE — Limited time items available!",
        Size = UDim2.fromScale(1, 1),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = banner,
    })

    -- Pulse
    local pulse = TweenService:Create(banner,
        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
        { BackgroundTransparency = 0.2 }
    )
    pulse:Play()

    return banner
end

-- ============================================================
-- CREATE: Main Shop Screen
-- ============================================================

function ShopScreen.Create(parent)
    -- parent = ScreenGui container

    -- Dimmer
    local dimmer = New("Frame", {
        Name = "ShopDimmer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        Parent = parent,
    })

    -- Main panel
    local panel = New("Frame", {
        Name = "ShopPanel",
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Parent = parent,
    })
    NewCorner(20).Parent = panel
    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = panel

    -- Padding
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 12),
        Parent = panel,
    })

    -- Anomaly banner (top area)
    local anomalyBanner = BuildAnomalyBanner(panel)
    anomalyBanner.Position = UDim2.fromOffset(12, 8)

    -- Header
    local header = New("Frame", {
        Name = "ShopHeader",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 48),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local titleLabel = UIComponents.CreateTextLabel({
        Name = "Title",
        Text = "🏪 SHOP",
        Size = UDim2.fromOffset(120, 28),
        Position = UDim2.fromScale(0, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        Parent = header,
    })

    -- Currency bar (compact)
    local currencyBar = New("Frame", {
        Name = "CurrencyBar",
        Size = UDim2.fromOffset(200, 32),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = UIStyles.Colors.CardBG,
        BackgroundTransparency = 0.4,
        Parent = header,
    })
    NewCorner(8).Parent = currencyBar

    local credLabel = UIComponents.CreateTextLabel({
        Name = "Credits",
        Text = "🪙 50",
        Size = UDim2.fromOffset(90, 32),
        Color = UIStyles.Colors.Gold,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = currencyBar,
    })

    local rpLabel = UIComponents.CreateTextLabel({
        Name = "RP",
        Text = "◎ 0",
        Size = UDim2.fromOffset(90, 32),
        Position = UDim2.fromOffset(100, 0),
        Color = UIStyles.Colors.DeepPurple,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = currencyBar,
    })

    -- Category tabs
    local tabFrame = New("Frame", {
        Name = "CategoryTabs",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 44),
        Position = UDim2.fromOffset(0, 90), -- below header + anomaly banner
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local selectedCategory = 1
    local tabRefs = {}

    local function BuildTabs()
        for _, child in ipairs(tabFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        tabRefs = {}

        for i, cat in ipairs(CATEGORIES) do
            local isSelected = i == selectedCategory
            local tab = UIComponents.CreateButton({
                Name = "Tab_" .. cat.name,
                Text = cat.icon .. " " .. cat.name,
                Size = UDim2.fromOffset(0, 38),
                Position = UDim2.fromOffset((i - 1) * 120, 3),
                Color = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.SurfaceDark,
                Transparency = isSelected and 0.8 or 0.5,
                TextColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.TextMuted,
                FontSize = UIStyles.FontSizes.Small,
                CornerRadius = 10,
                Stroke = true,
                StrokeColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.Border,
                Callback = function()
                    selectedCategory = i
                    BuildTabs()
                    RefreshItems()
                end,
                Parent = tabFrame,
            })
            tab.Size = UDim2.fromOffset(110, 38)
            tabRefs[i] = tab
        end
    end

    -- Items grid (scrollable)
    local gridFrame = New("Frame", {
        Name = "ItemsGridFrame",
        Size = UDim2.new(1, 0, 1, -145),
        Position = UDim2.fromOffset(0, 140),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local grid = New("ScrollingFrame", {
        Name = "ItemsGrid",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UIStyles.Colors.Cyan,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromScale(1, 3),
        Parent = gridFrame,
    })

    -- Anomaly banner visibility control
    local showAnomaly = false

    -- ============================================================
    -- Refresh Items
    -- ============================================================

    local function RefreshItems()
        -- Clear grid
        for _, child in ipairs(grid:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        local catName = CATEGORIES[selectedCategory] and CATEGORIES[selectedCategory].name or "Fishing Rods"
        local items = SHOP_ITEMS[catName] or {}

        local cols = 2
        local cardWidth = (gridFrame.AbsoluteSize.X - 24) / cols
        if cardWidth < 140 then cardWidth = gridFrame.AbsoluteSize.X - 12; cols = 1 end

        for i, item in ipairs(items) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)

            local isEquipped = (i == 1) -- Simulated: first item is always "owned"
            local isOwned = (i <= 2 and catName ~= "Consumables") -- Simulated: first two items owned

            -- Determine button state
            local btnText, btnColor, btnEnabled
            if catName == "Consumables" then
                btnText = "BUY"
                btnColor = UIStyles.Colors.Cyan
                btnEnabled = true
            elseif isEquipped then
                btnText = "EQUIPPED ✓"
                btnColor = UIStyles.Colors.Success
                btnEnabled = false
            elseif isOwned then
                btnText = "EQUIP"
                btnColor = UIStyles.Colors.ElectricBlue
                btnEnabled = true
            else
                btnText = "BUY"
                btnColor = UIStyles.Colors.Cyan
                btnEnabled = true
            end

            local card = New("Frame", {
                Name = "ShopCard_" .. item.name,
                Size = UDim2.fromOffset(cardWidth - 8, 130),
                Position = UDim2.fromOffset(col * (cardWidth + 4), row * 138 + 4),
                BackgroundColor3 = UIStyles.Colors.Elevated,
                BackgroundTransparency = 0.2,
                ClipsDescendants = true,
                Parent = grid,
            })
            NewCorner(14).Parent = card

            -- Premium treatment
            if item.premium then
                NewStroke(UIStyles.Colors.Gold, 0.3, 2).Parent = card
                AddSparkleEffect(card)
                -- Gold border glow
                local glow = New("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 0.95,
                    BackgroundColor3 = UIStyles.Colors.Gold,
                    ZIndex = 1,
                    Parent = card,
                })
                NewCorner(14).Parent = glow
            else
                NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = card
            end

            -- Icon area (left side)
            local iconFrame = New("Frame", {
                Size = UDim2.fromOffset(52, 52),
                Position = UDim2.fromOffset(10, 10),
                BackgroundColor3 = UIStyles.Colors.CardBG,
                BackgroundTransparency = 0.2,
                Parent = card,
            })
            NewCorner(12).Parent = iconFrame

            local icon = UIComponents.CreateTextLabel({
                Text = item.icon or "📦",
                Size = UDim2.fromScale(1, 1),
                TextSize = 28,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = iconFrame,
            })

            -- Premium badge
            if item.premium then
                local badge = New("Frame", {
                    Size = UDim2.fromOffset(40, 16),
                    Position = UDim2.new(1, 8, 0, 8),
                    AnchorPoint = Vector2.new(0, 0),
                    BackgroundColor3 = UIStyles.Colors.Gold,
                    BackgroundTransparency = 0.2,
                    ZIndex = 3,
                    Parent = card,
                })
                NewCorner(4).Parent = badge
                local badgeLabel = UIComponents.CreateTextLabel({
                    Text = "⭐ PREMIUM",
                    Size = UDim2.fromScale(1, 1),
                    Color = UIStyles.Colors.TextOnAccent,
                    Font = UIStyles.Fonts.Display,
                    TextSize = 7,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 4,
                    Parent = badge,
                })
            end

            -- Item name
            local nameLabel = UIComponents.CreateTextLabel({
                Name = "Name",
                Text = item.name,
                Size = UDim2.fromOffset(cardWidth - 80, 20),
                Position = UDim2.fromOffset(70, 8),
                Color = isOwned and UIStyles.Colors.TextPrimary or (item.premium and UIStyles.Colors.Gold or UIStyles.Colors.TextPrimary),
                Font = UIStyles.Fonts.Display,
                TextSize = UIStyles.FontSizes.Small,
                Parent = card,
            })

            -- Stats/description
            local statsLabel = UIComponents.CreateTextLabel({
                Name = "Stats",
                Text = item.stats or item.desc or "",
                Size = UDim2.fromOffset(cardWidth - 80, 34),
                Position = UDim2.fromOffset(70, 30),
                Color = UIStyles.Colors.TextSecondary,
                TextSize = UIStyles.FontSizes.Tiny,
                Parent = card,
            })

            -- Price display
            local priceStr = ""
            if item.price == 0 then
                priceStr = "FREE"
            elseif item.currency == "Robux" then
                priceStr = "⭐ " .. tostring(item.price)
            else
                priceStr = "🪙 " .. tostring(item.price)
                if item.costRP then
                    priceStr = priceStr .. " + ◎" .. tostring(item.costRP)
                end
            end

            local priceLabel = UIComponents.CreateTextLabel({
                Name = "Price",
                Text = priceStr,
                Size = UDim2.fromOffset(cardWidth - 20, 18),
                Position = UDim2.fromOffset(10, 68),
                Color = item.price == 0 and UIStyles.Colors.Success or (item.currency == "Robux" and UIStyles.Colors.Gold or UIStyles.Colors.Gold),
                Font = UIStyles.Fonts.Number,
                TextSize = UIStyles.FontSizes.Tiny,
                Parent = card,
            })

            -- Stackable count
            if item.stackable then
                local stackLabel = UIComponents.CreateTextLabel({
                    Name = "Stack",
                    Text = "Max: " .. tostring(item.stackable),
                    Size = UDim2.fromOffset(80, 14),
                    Position = UDim2.new(1, -90, 0, 68),
                    Color = UIStyles.Colors.TextMuted,
                    TextSize = UIStyles.FontSizes.Tiny,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = card,
                })
            end

            -- Action button
            local actionBtn = UIComponents.CreateButton({
                Name = "ActionBtn",
                Text = btnText,
                Size = UDim2.fromOffset(90, 36),
                Position = UDim2.fromOffset(10, 88),
                Color = btnColor,
                Transparency = btnEnabled and 0.15 or 0.5,
                TextColor = UIStyles.Colors.TextPrimary,
                FontSize = UIStyles.FontSizes.Small,
                CornerRadius = 8,
                Callback = not btnEnabled and nil or function()
                    if btnText == "BUY" then
                        -- Show confirmation dialog
                        BuildConfirmationDialog(parent, item, function()
                            -- In production, call EconomyService.PurchaseShopItem
                            if item.currency == "Robux" then
                                print("[Shop] Purchasing premium:", item.name)
                            else
                                print("[Shop] Purchasing:", item.name, "for", item.price, "Credits")
                            end
                        end)
                    elseif btnText == "EQUIP" then
                        print("[Shop] Equipping:", item.name)
                        nameLabel.TextColor3 = UIStyles.Colors.Cyan
                        -- In production, call DepthService.UpgradeGear
                    end
                end,
                Parent = card,
            })
        end

        -- Update canvas size
        local totalRows = math.ceil(#items / cols)
        grid.CanvasSize = UDim2.fromOffset(0, totalRows * 138 + 12)
    end

    -- Build initial UI
    BuildTabs()
    RefreshItems()

    -- Return public API
    local api = {}

    api.UpdateCurrency = function(credits, rp)
        if credLabel then credLabel.Text = "🪙 " .. tostring(math.floor(credits)) end
        if rpLabel then rpLabel.Text = "◎ " .. tostring(math.floor(rp)) end
    end

    api.SetAnomalyActive = function(active)
        showAnomaly = active
        if anomalyBanner then
            anomalyBanner.Visible = active
        end
        -- Adjust layout
        if active then
            tabFrame.Position = UDim2.fromOffset(0, 130)
            gridFrame.Position = UDim2.fromOffset(0, 180)
            gridFrame.Size = UDim2.new(1, 0, 1, -185)
        else
            tabFrame.Position = UDim2.fromOffset(0, 90)
            gridFrame.Position = UDim2.fromOffset(0, 140)
            gridFrame.Size = UDim2.new(1, 0, 1, -145)
        end
    end

    api.Refresh = RefreshItems
    api.Close = function()
        parent:Destroy()
    end

    return api
end

return ShopScreen