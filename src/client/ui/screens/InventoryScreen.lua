--[[
    InventoryScreen.lua — Enhanced Inventory screen for Abyss of the Deep
    4 tabs: Creatures | Resources | Equipment | Consumables
    Sell, Use, Equip buttons. Sort/filter options. Rarity grid.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local InventoryScreen = {}
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
-- Sample data (in production, comes from CollectionService)
-- ============================================================

local CREATURES = {
    { name = "Glowfin Tetra",     icon = "🐟", rarity = "Common",    sellPrice = 45,  zone = "Twilight",  count = 3 },
    { name = "Shadow Shark",      icon = "🦈", rarity = "Rare",      sellPrice = 320, zone = "Midnight",  count = 1 },
    { name = "Void Crystal",      icon = "💎", rarity = "Rare",      sellPrice = 280, zone = "Abyss",     count = 2 },
    { name = "Biolum Coral",      icon = "🪸", rarity = "Uncommon",  sellPrice = 120, zone = "Twilight",  count = 5 },
    { name = "Phantom Squid",     icon = "🐙", rarity = "Epic",      sellPrice = 950, zone = "Abyss",     count = 1 },
    { name = "Iron Ore",          icon = "🪨", rarity = "Common",    sellPrice = 15,  zone = "Sunlight",  count = 12 },
    { name = "Echo Eye",          icon = "👁️", rarity = "Anomaly",  sellPrice = 2400,zone = "Trench",    count = 1 },
    { name = "Depth Pearl",       icon = "🔮", rarity = "Epic",      sellPrice = 780, zone = "Midnight",  count = 2 },
    { name = "Kelp Sprout",       icon = "🌿", rarity = "Common",    sellPrice = 8,   zone = "Sunlight",  count = 7 },
    { name = "Anglerfish",        icon = "🎣", rarity = "Uncommon",  sellPrice = 65,  zone = "Midnight",  count = 3 },
    { name = "Ancient Coin",      icon = "🪙", rarity = "Rare",      sellPrice = 500, zone = "Abyss",     count = 1 },
    { name = "Abyssal Crown",     icon = "👑", rarity = "Legendary", sellPrice = 5000,zone = "Trench",    count = 1 },
}

local RESOURCES = {
    { name = "Scrap Metal",       icon = "🔩", count = 240, color = UIStyles.Colors.BioGreen,       desc = "Used for base building" },
    { name = "Crystal Shards",    icon = "💎", count = 85,  color = UIStyles.Colors.Cyan,           desc = "Used for upgrades" },
    { name = "Biolum Goo",        icon = "🟢", count = 32,  color = UIStyles.Colors.BioGreen,       desc = "Crafting material" },
    { name = "Void Essence",      icon = "🌀", count = 12,  color = UIStyles.Colors.DeepPurple,     desc = "Rare anomaly material" },
    { name = "Ancient Relic",     icon = "🏺", count = 4,   color = UIStyles.Colors.Gold,           desc = "Valuable artifact" },
}

local EQUIPMENT = {
    { name = "Basic Rod",         icon = "🎣", equipped = true,  tier = "T1", stats = "Catch: 1.0x" },
    { name = "Scuba Kit",         icon = "🤿", equipped = true,  tier = "T2", stats = "O₂: +50 · Depth: 1,000m" },
    { name = "Harpoon Gun",       icon = "🔱", equipped = false, tier = "T1", stats = "Damage: 20" },
    { name = "Carbon Rod",        icon = "🎣", equipped = false, tier = "T2", stats = "Catch: 1.3x · Range: 20m" },
    { name = "Deep Scanner",      icon = "📡", equipped = false, tier = "T2", stats = "Reveals resources" },
}

local CONSUMABLES_INV = {
    { name = "Oxygen Tank (S)",   icon = "🫧", count = 5,  desc = "+50 O₂",        useEffect = "oxygen" },
    { name = "Oxygen Tank (L)",   icon = "🫧", count = 2,  desc = "+200 O₂",       useEffect = "oxygen" },
    { name = "Standard Bait",     icon = "🪱", count = 8,  desc = "Common bait",    useEffect = "bait" },
    { name = "Rare Bait",         icon = "🦐", count = 3,  desc = "Rare bait",      useEffect = "bait" },
    { name = "Speed Boost",       icon = "⚡", count = 4,  desc = "+30% speed 30s", useEffect = "speed" },
    { name = "Anomaly Shield",    icon = "🛡️", count = 1,  desc = "Anomaly protect",useEffect = "shield" },
}

-- Rarity ordering for sort
local RARITY_ORDER = { ["Legendary"] = 0, ["Epic"] = 1, ["Rare"] = 2, ["Anomaly"] = 3, ["Uncommon"] = 4, ["Common"] = 5 }

-- ============================================================
-- CREATE: Main Inventory Screen
-- ============================================================

function InventoryScreen.Create(parent)
    -- parent = ScreenGui container

    -- Dimmer
    local dimmer = New("Frame", {
        Name = "InvDimmer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        Parent = parent,
    })

    -- Main panel
    local panel = New("Frame", {
        Name = "InvPanel",
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

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 12),
        Parent = panel,
    })

    -- Header
    local header = New("Frame", {
        Name = "InvHeader",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 44),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local titleLabel = UIComponents.CreateTextLabel({
        Name = "Title",
        Text = "🎒 INVENTORY",
        Size = UDim2.fromOffset(200, 28),
        Position = UDim2.fromScale(0, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        Parent = header,
    })

    -- Collection progress
    local progressText = UIComponents.CreateTextLabel({
        Name = "Progress",
        Text = "12/30 collected",
        Size = UDim2.fromOffset(120, 20),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Color = UIStyles.Colors.Cyan,
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = header,
    })

    -- Tab bar
    local TAB_NAMES = { "Creatures", "Resources", "Equipment", "Consumables" }
    local tabFrame = New("Frame", {
        Name = "InvTabs",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 42),
        Position = UDim2.fromOffset(0, 50),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    -- Sort/Filter bar (below tabs)
    local filterFrame = New("Frame", {
        Name = "FilterBar",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 36),
        Position = UDim2.fromOffset(0, 94),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local selectedTab = 1
    local sortMode = "rarity" -- "rarity", "type", "newest"

    local function BuildTabs()
        for _, child in ipairs(tabFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for i, name in ipairs(TAB_NAMES) do
            local isSelected = i == selectedTab
            local tab = UIComponents.CreateButton({
                Name = "Tab_" .. name,
                Text = name,
                Size = UDim2.fromOffset(0, 36),
                Position = UDim2.fromOffset((i - 1) * 85, 3),
                Color = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.SurfaceDark,
                Transparency = isSelected and 0.8 or 0.5,
                TextColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.TextMuted,
                FontSize = UIStyles.FontSizes.Small,
                CornerRadius = 8,
                Stroke = true,
                StrokeColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.Border,
                Callback = function()
                    selectedTab = i
                    BuildTabs()
                    RefreshContent()
                end,
                Parent = tabFrame,
            })
            tab.Size = UDim2.fromOffset(78, 36)
        end
    end

    -- Build filter/sort bar
    local function BuildFilterBar()
        for _, child in ipairs(filterFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        if selectedTab == 1 then
            -- Sort options for Creatures
            local sorts = { "Rarity", "Type", "Newest" }
            for i, s in ipairs(sorts) do
                local isActive = sortMode == string.lower(s)
                local btn = UIComponents.CreateButton({
                    Name = "Sort_" .. s,
                    Text = s,
                    Size = UDim2.fromOffset(0, 30),
                    Position = UDim2.fromOffset((i - 1) * 85, 3),
                    Color = isActive and UIStyles.Colors.DeepPurple or UIStyles.Colors.SurfaceDark,
                    Transparency = isActive and 0.7 or 0.5,
                    TextColor = isActive and UIStyles.Colors.DeepPurple or UIStyles.Colors.TextMuted,
                    FontSize = UIStyles.FontSizes.Tiny,
                    CornerRadius = 6,
                    Stroke = true,
                    StrokeColor = isActive and UIStyles.Colors.DeepPurple or UIStyles.Colors.Border,
                    Callback = function()
                        sortMode = string.lower(s)
                        BuildFilterBar()
                        RefreshContent()
                    end,
                    Parent = filterFrame,
                })
                btn.Size = UDim2.fromOffset(78, 30)
            end
        end
    end

    -- Content area (scrollable)
    local contentFrame = New("Frame", {
        Name = "InvContent",
        Size = UDim2.new(1, 0, 1, -140),
        Position = UDim2.fromOffset(0, 136),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local scroll = New("ScrollingFrame", {
        Name = "InvScroll",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UIStyles.Colors.DeepPurple,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromScale(1, 3),
        Parent = contentFrame,
    })

    -- ============================================================
    -- Refresh content based on selected tab
    -- ============================================================

    local function RefreshContent()
        -- Clear scroll
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        if selectedTab == 1 then
            -- CREATURES TAB
            local data = CREATURES

            -- Sort
            if sortMode == "rarity" then
                table.sort(data, function(a, b)
                    local ra = RARITY_ORDER[a.rarity] or 99
                    local rb = RARITY_ORDER[b.rarity] or 99
                    if ra == rb then return a.name < b.name end
                    return ra < rb
                end)
            elseif sortMode == "type" then
                table.sort(data, function(a, b) return a.zone < b.zone end)
            elseif sortMode == "newest" then
                -- Keep original order (simulated "newest first")
            end

            local cols = 2
            local cardWidth = (contentFrame.AbsoluteSize.X - 8) / cols
            if cardWidth < 140 then cardWidth = contentFrame.AbsoluteSize.X - 4; cols = 1 end

            for i, creature in ipairs(data) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local rarityColor = UIStyles.RarityToColor(creature.rarity)

                local card = New("Frame", {
                    Name = "Creature_" .. creature.name,
                    Size = UDim2.fromOffset(cardWidth - 6, 116),
                    Position = UDim2.fromOffset(col * (cardWidth + 4), row * 122 + 4),
                    BackgroundColor3 = UIStyles.Colors.Elevated,
                    BackgroundTransparency = 0.15,
                    ClipsDescendants = true,
                    Parent = scroll,
                })
                NewCorner(12).Parent = card
                NewStroke(rarityColor, 0.4, 2).Parent = card

                -- Icon
                local icon = UIComponents.CreateTextLabel({
                    Text = creature.icon or "🐟",
                    Size = UDim2.fromOffset(48, 48),
                    Position = UDim2.fromOffset(8, 8),
                    TextSize = 32,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Parent = card,
                })

                -- Name
                local nameLabel = UIComponents.CreateTextLabel({
                    Name = "Name",
                    Text = creature.name,
                    Size = UDim2.fromOffset(cardWidth - 70, 20),
                    Position = UDim2.fromOffset(62, 6),
                    Color = UIStyles.Colors.TextPrimary,
                    Font = UIStyles.Fonts.Display,
                    TextSize = UIStyles.FontSizes.Small,
                    Parent = card,
                })

                -- Rarity + Zone
                local metaLabel = UIComponents.CreateTextLabel({
                    Name = "Meta",
                    Text = creature.rarity .. " · " .. creature.zone,
                    Size = UDim2.fromOffset(cardWidth - 70, 16),
                    Position = UDim2.fromOffset(62, 28),
                    Color = rarityColor,
                    TextSize = UIStyles.FontSizes.Tiny,
                    Parent = card,
                })

                -- Count
                local countLabel = UIComponents.CreateTextLabel({
                    Name = "Count",
                    Text = "×" .. tostring(creature.count or 1),
                    Size = UDim2.fromOffset(40, 16),
                    Position = UDim2.new(1, -48, 0, 8),
                    Color = UIStyles.Colors.TextMuted,
                    TextSize = UIStyles.FontSizes.Tiny,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = card,
                })

                -- Sell price
                local sellLabel = UIComponents.CreateTextLabel({
                    Name = "SellPrice",
                    Text = "★ " .. tostring(creature.sellPrice),
                    Size = UDim2.fromOffset(80, 18),
                    Position = UDim2.fromOffset(62, 46),
                    Color = UIStyles.Colors.Gold,
                    Font = UIStyles.Fonts.Number,
                    TextSize = UIStyles.FontSizes.Tiny,
                    Parent = card,
                })

                -- Sell button
                local sellBtn = UIComponents.CreateButton({
                    Name = "SellBtn",
                    Text = "SELL",
                    Size = UDim2.fromOffset(70, 32),
                    Position = UDim2.fromOffset(8, 76),
                    Color = UIStyles.Colors.Danger,
                    Transparency = 0.3,
                    TextColor = UIStyles.Colors.TextPrimary,
                    FontSize = UIStyles.FontSizes.Tiny,
                    CornerRadius = 8,
                    Callback = function()
                        print("[Inv] Selling:", creature.name, "for ★" .. tostring(creature.sellPrice))
                        -- In production, call EconomyService.SellCreature
                    end,
                    Parent = card,
                })
            end

            local totalRows = math.ceil(#data / cols)
            scroll.CanvasSize = UDim2.fromOffset(0, totalRows * 122 + 12)

        elseif selectedTab == 2 then
            -- RESOURCES TAB
            for i, res in ipairs(RESOURCES) do
                local row = New("Frame", {
                    Name = "Resource_" .. res.name,
                    Size = UDim2.new(1, -8, 0, 52),
                    Position = UDim2.fromOffset(0, (i - 1) * 58 + 4),
                    BackgroundColor3 = UIStyles.Colors.Elevated,
                    BackgroundTransparency = 0.15,
                    ClipsDescendants = true,
                    Parent = scroll,
                })
                NewCorner(10).Parent = row
                NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = row

                local icon = UIComponents.CreateTextLabel({
                    Text = res.icon or "📦",
                    Size = UDim2.fromOffset(36, 36),
                    Position = UDim2.fromOffset(8, 8),
                    TextSize = 24,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Parent = row,
                })

                local nameLabel = UIComponents.CreateTextLabel({
                    Name = "Name",
                    Text = res.name,
                    Size = UDim2.fromOffset(140, 20),
                    Position = UDim2.fromOffset(52, 6),
                    Color = UIStyles.Colors.TextPrimary,
                    TextSize = UIStyles.FontSizes.Small,
                    Font = UIStyles.Fonts.Display,
                    Parent = row,
                })

                local descLabel = UIComponents.CreateTextLabel({
                    Name = "Desc",
                    Text = res.desc or "",
                    Size = UDim2.fromOffset(140, 16),
                    Position = UDim2.fromOffset(52, 28),
                    Color = UIStyles.Colors.TextSecondary,
                    TextSize = UIStyles.FontSizes.Tiny,
                    Parent = row,
                })

                local countLabel = UIComponents.CreateTextLabel({
                    Name = "Count",
                    Text = "×" .. tostring(res.count),
                    Size = UDim2.fromOffset(80, 36),
                    Position = UDim2.new(1, -88, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Color = res.color or UIStyles.Colors.TextPrimary,
                    Font = UIStyles.Fonts.Number,
                    TextSize = UIStyles.FontSizes.HUDSmall,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = row,
                })
            end

            scroll.CanvasSize = UDim2.fromOffset(0, #RESOURCES * 58 + 12)

        elseif selectedTab == 3 then
            -- EQUIPMENT TAB
            for i, equip in ipairs(EQUIPMENT) do
                local card = New("Frame", {
                    Name = "Equip_" .. equip.name,
                    Size = UDim2.new(1, -8, 0, 72),
                    Position = UDim2.fromOffset(0, (i - 1) * 78 + 4),
                    BackgroundColor3 = UIStyles.Colors.Elevated,
                    BackgroundTransparency = 0.15,
                    ClipsDescendants = true,
                    Parent = scroll,
                })
                NewCorner(10).Parent = card

                if equip.equipped then
                    NewStroke(UIStyles.Colors.Cyan, 0.4, 2).Parent = card
                else
                    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = card
                end

                local icon = UIComponents.CreateTextLabel({
                    Text = equip.icon or "🔧",
                    Size = UDim2.fromOffset(44, 44),
                    Position = UDim2.fromOffset(10, 14),
                    TextSize = 28,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Parent = card,
                })

                local nameLabel = UIComponents.CreateTextLabel({
                    Name = "Name",
                    Text = equip.name .. (equip.equipped and " [Equipped]" or ""),
                    Size = UDim2.fromOffset(180, 20),
                    Position = UDim2.fromOffset(62, 8),
                    Color = equip.equipped and UIStyles.Colors.Cyan or UIStyles.Colors.TextPrimary,
                    Font = UIStyles.Fonts.Display,
                    TextSize = UIStyles.FontSizes.Small,
                    Parent = card,
                })

                local tierLabel = UIComponents.CreateTextLabel({
                    Name = "Tier",
                    Text = equip.tier or "" .. " · " .. (equip.stats or ""),
                    Size = UDim2.fromOffset(200, 16),
                    Position = UDim2.fromOffset(62, 30),
                    Color = UIStyles.Colors.TextSecondary,
                    TextSize = UIStyles.FontSizes.Tiny,
                    Parent = card,
                })

                -- Equip/Unequip button
                local btnText = equip.equipped and "UNEQUIP" or "EQUIP"
                local btnColor = equip.equipped and UIStyles.Colors.Warning or UIStyles.Colors.Cyan
                local actionBtn = UIComponents.CreateButton({
                    Name = "ActionBtn",
                    Text = btnText,
                    Size = UDim2.fromOffset(80, 34),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Color = btnColor,
                    Transparency = 0.15,
                    TextColor = UIStyles.Colors.TextPrimary,
                    FontSize = UIStyles.FontSizes.Tiny,
                    CornerRadius = 8,
                    Callback = function()
                        print("[Inv] Toggling equip:", equip.name)
                        -- In production, call DepthService.UpgradeGear or similar
                    end,
                    Parent = card,
                })
            end

            scroll.CanvasSize = UDim2.fromOffset(0, #EQUIPMENT * 78 + 12)

        elseif selectedTab == 4 then
            -- CONSUMABLES TAB
            for i, item in ipairs(CONSUMABLES_INV) do
                local card = New("Frame", {
                    Name = "Consume_" .. item.name,
                    Size = UDim2.new(1, -8, 0, 64),
                    Position = UDim2.fromOffset(0, (i - 1) * 70 + 4),
                    BackgroundColor3 = UIStyles.Colors.Elevated,
                    BackgroundTransparency = 0.15,
                    ClipsDescendants = true,
                    Parent = scroll,
                })
                NewCorner(10).Parent = card
                NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = card

                local icon = UIComponents.CreateTextLabel({
                    Text = item.icon or "📦",
                    Size = UDim2.fromOffset(40, 40),
                    Position = UDim2.fromOffset(10, 12),
                    TextSize = 26,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Parent = card,
                })

                local nameLabel = UIComponents.CreateTextLabel({
                    Name = "Name",
                    Text = item.name,
                    Size = UDim2.fromOffset(140, 20),
                    Position = UDim2.fromOffset(58, 8),
                    Color = UIStyles.Colors.TextPrimary,
                    TextSize = UIStyles.FontSizes.Small,
                    Font = UIStyles.Fonts.Display,
                    Parent = card,
                })

                local descLabel = UIComponents.CreateTextLabel({
                    Name = "Desc",
                    Text = item.desc or "" .. " · x" .. tostring(item.count),
                    Size = UDim2.fromOffset(140, 16),
                    Position = UDim2.fromOffset(58, 30),
                    Color = UIStyles.Colors.TextSecondary,
                    TextSize = UIStyles.FontSizes.Tiny,
                    Parent = card,
                })

                -- Use button
                local useBtn = UIComponents.CreateButton({
                    Name = "UseBtn",
                    Text = "USE",
                    Size = UDim2.fromOffset(70, 34),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Color = UIStyles.Colors.BioGreen,
                    Transparency = 0.3,
                    TextColor = UIStyles.Colors.TextPrimary,
                    FontSize = UIStyles.FontSizes.Tiny,
                    CornerRadius = 8,
                    Callback = function()
                        print("[Inv] Using:", item.name)
                        -- In production, call OxygenService.UseEmergencyTank or similar
                    end,
                    Parent = card,
                })
            end

            scroll.CanvasSize = UDim2.fromOffset(0, #CONSUMABLES_INV * 70 + 12)
        end
    end

    -- Build initial UI
    BuildTabs()
    BuildFilterBar()
    RefreshContent()

    -- Return public API
    local api = {}

    api.UpdateProgress = function(unique, total)
        if progressText then
            progressText.Text = tostring(unique) .. "/" .. tostring(total) .. " collected"
        end
        if titleLabel then
            titleLabel.Text = "🎒 INVENTORY (" .. tostring(unique) .. "/" .. tostring(total) .. ")"
        end
    end

    api.Refresh = RefreshContent
    api.Close = function()
        parent:Destroy()
    end

    return api
end

return InventoryScreen