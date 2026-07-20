--[[
    UIComponents.lua — Reusable Roblox GUI component factories
    Builds consistent, mobile-responsive UI elements for Abyss of the Deep.
]]

local UIStyles = require(script.Parent.UIStyles)

local UIComponents = {}

-- Shared services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- Core Helpers
-- ============================================================

local function New(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

local function NewCorner(radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or UIStyles.Spacing.CornerRadius),
    })
end

local function NewStroke(color, transparency, thickness)
    return New("UIStroke", {
        Color = color or UIStyles.Colors.Border,
        Transparency = transparency or 0.8,
        Thickness = thickness or 1,
    })
end

local function NewGradient(direction, colors)
    local grad = New("UIGradient", {})
    if direction == "horizontal" then
        grad.Rotation = 0
    elseif direction == "vertical" then
        grad.Rotation = 90
    end
    if colors then
        local colorSeq = {}
        local alphaSeq = {}
        for i, c in ipairs(colors) do
            local pos = (i - 1) / (#colors - 1)
            table.insert(colorSeq, ColorSequenceKeypoint.new(pos, c.color or Color3.new()))
            table.insert(alphaSeq, NumberSequenceKeypoint.new(pos, c.alpha or 1))
        end
        grad.Color = ColorSequence.new(colorSeq)
        grad.Transparency = NumberSequence.new(alphaSeq)
    end
    return grad
end

-- ============================================================
-- Component: Text Label
-- ============================================================

function UIComponents.CreateTextLabel(props)
    local label = New("TextLabel", {
        Name = props.Name or "TextLabel",
        Text = props.Text or "",
        Size = props.Size or UDim2.fromOffset(100, 24),
        Position = props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        TextColor3 = props.Color or UIStyles.Colors.TextPrimary,
        Font = props.Font or UIStyles.Fonts.Body,
        TextSize = props.TextSize or UIStyles.FontSizes.Body,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextTransparency = props.Transparency or 0,
        ZIndex = props.ZIndex or 1,
        RichText = props.RichText ~= false,
        Parent = props.Parent,
    })
    return label
end

-- ============================================================
-- Component: Primary Button
-- ============================================================

function UIComponents.CreateButton(props)
    local frame = New("Frame", {
        Name = props.Name or "Button",
        Size = props.Size or UDim2.fromOffset(120, 44),
        Position = props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = props.Color or UIStyles.Colors.Cyan,
        BackgroundTransparency = props.Transparency or 0,
        ClipsDescendants = true,
        Parent = props.Parent,
    })

    NewCorner(props.CornerRadius or UIStyles.Spacing.CornerRadius).Parent = frame

    if props.Stroke then
        NewStroke(props.StrokeColor or UIStyles.Colors.Border, 0.6, 1).Parent = frame
    end

    if props.Gradient then
        local gradColors = {}
        for _, c in ipairs(props.Gradient) do
            table.insert(gradColors, {color = c, alpha = 1})
        end
        local g = NewGradient("horizontal", gradColors)
        g.Parent = frame
    end

    -- Icon (optional)
    if props.Icon then
        local icon = New("TextLabel", {
            Name = "Icon",
            Text = props.Icon,
            Size = UDim2.fromOffset(props.IconSize or 24, props.IconSize or 24),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            TextSize = props.IconSize or 20,
            Font = Enum.Font.GothamMedium,
            TextColor3 = props.TextColor or UIStyles.Colors.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = frame,
        })
    end

    -- Text
    local label
    if props.Text and props.Text ~= "" then
        label = UIComponents.CreateTextLabel({
            Name = "Label",
            Text = props.Text,
            Size = UDim2.fromScale(1, 1),
            Color = props.TextColor or UIStyles.Colors.TextOnAccent,
            Font = props.Font or UIStyles.Fonts.Display,
            TextSize = props.FontSize or UIStyles.FontSizes.Body,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = frame,
        })
        frame._label = label
    end

    -- Click detection (mobile + desktop compatible)
        local button = New("ImageButton", {
            Name = "Hitbox",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            ZIndex = 10,
            Parent = frame,
        })

        if props.Callback then
            button.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    props.Callback()
                end
            end)
        end

        frame._button = button
        return frame
    end

    -- ============================================================
    -- Component: Circular Icon Button (HUD)
    -- ============================================================

function UIComponents.CreateIconButton(props)
    local size = props.Size or UIStyles.Button.HUDActionSize
    local frame = New("Frame", {
        Name = props.Name or "IconButton",
        Size = UDim2.fromOffset(size, size),
        Position = props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = props.Color or UIStyles.Colors.Elevated,
        BackgroundTransparency = 0.1,
        ClipsDescendants = true,
        Parent = props.Parent,
    })

    NewCorner(100).Parent = frame
    NewStroke(props.StrokeColor or UIStyles.Colors.Cyan, 0.5, 2).Parent = frame

    -- Glow behind
    local glow = New("ImageLabel", {
        Name = "Glow",
        Size = UDim2.fromOffset(size + 16, size + 16),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5025537645",
        ImageColor3 = props.StrokeColor or UIStyles.Colors.Cyan,
        ImageTransparency = 0.7,
        ZIndex = 0,
        Parent = frame,
    })

    -- Icon
    local icon = New("TextLabel", {
        Name = "Icon",
        Text = props.Icon or "?",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        TextSize = size * 0.45,
        Font = Enum.Font.GothamMedium,
        TextColor3 = UIStyles.Colors.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 2,
        Parent = frame,
    })

    -- Hitbox
    local button = New("ImageButton", {
        Name = "Hitbox",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        ZIndex = 10,
        Parent = frame,
    })

    if props.Callback then
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                -- Scale press feedback
                local tween = TweenService:Create(frame,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                    {BackgroundTransparency = 0.3})
                tween:Play()
                tween.Completed:Wait()
                local tween2 = TweenService:Create(frame,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                    {BackgroundTransparency = 0.1})
                tween2:Play()
                props.Callback()
            end
        end)
    end

    frame._button = button
    return frame
end

-- ============================================================
-- Component: Vertical Progress Bar
-- ============================================================

function UIComponents.CreateVerticalBar(props)
    local height = props.Size and props.Size.Y.Offset or UIStyles.HUD.MaxBarHeight
    local width = props.Size and props.Size.X.Offset or UIStyles.HUD.BarWidth

    local container = New("Frame", {
        Name = props.Name or "VerticalBar",
        Size = UDim2.fromOffset(width + 20, height + 40),
        Position = props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = props.Parent,
    })

    -- Track
    local track = New("Frame", {
        Name = "Track",
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = props.BackgroundColor or UIStyles.Colors.SurfaceDark,
        ClipsDescendants = true,
        Parent = container,
    })
    NewCorner(6).Parent = track
    NewStroke(UIStyles.Colors.Border, 0.85, 1).Parent = track

    -- Fill
    local fill = New("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 1),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = props.FillColor or UIStyles.Colors.Cyan,
        ClipsDescendants = true,
        Parent = track,
    })
    NewCorner(6).Parent = fill

    -- Label above
    if props.Label then
        local label = UIComponents.CreateTextLabel({
            Name = "Label",
            Text = props.Label,
            Size = UDim2.fromOffset(40, 20),
            Position = UDim2.fromScale(0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            Color = props.FillColor or UIStyles.Colors.Cyan,
            TextSize = UIStyles.FontSizes.Small,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = container,
        })
    end

    -- Percentage
    if props.ShowPercent ~= false then
        local pctLabel = UIComponents.CreateTextLabel({
            Name = "Percent",
            Text = "100%",
            Size = UDim2.fromOffset(44, 18),
            Position = UDim2.fromScale(0.5, 1),
            AnchorPoint = Vector2.new(0.5, 1),
            Color = props.FillColor or UIStyles.Colors.Cyan,
            Font = UIStyles.Fonts.Mono,
            TextSize = UIStyles.FontSizes.Tiny,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = container,
        })
        container._pctLabel = pctLabel
    end

    -- Update method
    container.UpdateFill = function(current, max)
        local pct = max > 0 and current / max or 0
        pct = math.clamp(pct, 0, 1)
        fill.Size = UDim2.fromScale(1, pct)
        if container._pctLabel then
            container._pctLabel.Text = math.floor(pct * 100) .. "%"
        end
        -- Color at critical
        if pct <= 0.2 then
            fill.BackgroundColor3 = UIStyles.Colors.Danger
        elseif pct <= 0.5 then
            fill.BackgroundColor3 = UIStyles.Colors.Warning
        else
            fill.BackgroundColor3 = props.FillColor or UIStyles.Colors.Cyan
        end
    end

    container._fill = fill
    return container
end

-- ============================================================
-- Component: Glass Panel
-- ============================================================

function UIComponents.CreatePanel(props)
    local panel = New("Frame", {
        Name = props.Name or "Panel",
        Size = props.Size or UDim2.fromOffset(300, 200),
        Position = props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = props.Color or UIStyles.Colors.CardBG,
        BackgroundTransparency = props.Transparency or 0.3,
        ClipsDescendants = props.ClipsDescendants ~= false,
        ZIndex = props.ZIndex or 1,
        Parent = props.Parent,
    })
    NewCorner(props.CornerRadius or UIStyles.Spacing.CardRadius).Parent = panel
    NewStroke(props.StrokeColor or UIStyles.Colors.Border, 0.85, 1).Parent = panel
    return panel
end

-- ============================================================
-- Component: Shop Item Card
-- ============================================================

function UIComponents.CreateShopItemCard(props)
    local state = props.State or "available"
    local strokeColor = UIStyles.Colors.Border
    if state == "available" then
        strokeColor = UIStyles.Colors.Cyan
    elseif state == "owned" then
        strokeColor = UIStyles.Colors.Success
    end

    local card = New("Frame", {
        Name = "ShopItem_" .. (props.Name or "Item"),
        Size = UDim2.new(1, -16, 0, 90),
        BackgroundColor3 = UIStyles.Colors.Elevated,
        BackgroundTransparency = state == "locked" and 0.6 or 0.2,
        ClipsDescendants = true,
        Parent = props.Parent,
    })
    NewCorner(UIStyles.Spacing.CardRadius).Parent = card
    NewStroke(strokeColor, state == "locked" and 0.9 or 0.6, state == "locked" and 1 or 2).Parent = card

    -- Icon area
    local iconFrame = New("Frame", {
        Size = UDim2.fromOffset(66, 66),
        Position = UDim2.fromOffset(12, 12),
        BackgroundColor3 = UIStyles.Colors.CardBG,
        BackgroundTransparency = 0.2,
        Parent = card,
    })
    NewCorner(UIStyles.Spacing.CornerRadius).Parent = iconFrame

    local icon = UIComponents.CreateTextLabel({
        Text = props.Icon or "📦",
        Size = UDim2.fromScale(1, 1),
        TextSize = 32,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = iconFrame,
    })

    -- Item name
    local nameLabel = UIComponents.CreateTextLabel({
        Name = "Name",
        Text = props.Name or "Unknown Item",
        Size = UDim2.fromOffset(180, 22),
        Position = UDim2.fromOffset(90, 12),
        Color = state == "locked" and UIStyles.Colors.TextMuted or UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.ItemName,
        Parent = card,
    })

    -- Stats
    local statsLabel = UIComponents.CreateTextLabel({
        Name = "Stats",
        Text = props.Stats or "",
        Size = UDim2.fromOffset(180, 18),
        Position = UDim2.fromOffset(90, 38),
        Color = UIStyles.Colors.TextSecondary,
        TextSize = UIStyles.FontSizes.Small,
        Parent = card,
    })

    -- Status / Price
    local statusText = ""
    local statusColor = UIStyles.Colors.Success
    if state == "owned" then
        statusText = "✓ OWNED"
        statusColor = UIStyles.Colors.Success
    elseif state == "locked" then
        statusText = props.LockReason or "🔒 LOCKED"
        statusColor = UIStyles.Colors.Danger
    elseif props.Price then
        local symbol = props.PriceType == "robux" and "⭐" or "🪙"
        statusText = symbol .. " " .. tostring(props.Price)
        if props.PriceType == "credits" then statusText = statusText .. " Credits" end
        statusColor = UIStyles.Colors.Gold
    end

    local statusLabel = UIComponents.CreateTextLabel({
        Name = "Status",
        Text = statusText,
        Size = UDim2.fromOffset(180, 16),
        Position = UDim2.fromOffset(90, 60),
        Color = statusColor,
        Font = state == "owned" and UIStyles.Fonts.Body or UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Small,
        Parent = card,
    })

    -- Action button
    if state ~= "owned" then
        local btnText = state == "locked" and "LOCKED" or "BUY"
        local btn = UIComponents.CreateButton({
            Name = "ActionBtn",
            Text = btnText,
            Size = UDim2.fromOffset(90, 44),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Color = state == "locked" and UIStyles.Colors.SurfaceDark or UIStyles.Colors.Cyan,
            Transparency = state == "locked" and 0.5 or 0.15,
            TextColor = UIStyles.Colors.TextPrimary,
            FontSize = UIStyles.FontSizes.Small,
            CornerRadius = 8,
            Callback = state ~= "locked" and props.OnPurchase or nil,
            Parent = card,
        })
    end

    return card
end

-- ============================================================
-- Component: Creature Card (Inventory Grid)
-- ============================================================

function UIComponents.CreateCreatureCard(props)
    local rarityColor = UIStyles.RarityToColor(props.Rarity or "Common")
    local cardSize = props.Size or 160
    local cardHeight = cardSize + 24 -- extra room for text labels
    local iconAreaHeight = cardSize * 0.5

    local card = New("Frame", {
        Name = "Creature_" .. (props.Name or "Creature"),
        Size = UDim2.fromOffset(cardSize, cardHeight),
        BackgroundColor3 = UIStyles.Colors.Elevated,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Parent = props.Parent,
    })
    NewCorner(UIStyles.Spacing.CardRadius).Parent = card
    NewStroke(rarityColor, 0.5, 2).Parent = card

    -- Icon centered in upper half of card
    local icon = UIComponents.CreateTextLabel({
        Name = "Icon",
        Text = props.Icon or "🐟",
        Size = UDim2.fromOffset(cardSize - 16, iconAreaHeight - 8),
        Position = UDim2.fromScale(0.5, 0.45),
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextSize = math.min(cardSize * 0.35, 48),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = card,
    })

    -- Name
    local nameLabel = UIComponents.CreateTextLabel({
        Name = "Name",
        Text = props.Name or "Unknown",
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.fromOffset(6, iconAreaHeight - 2),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Small,
        Parent = card,
    })

    -- Rarity + Zone
    local metaLabel = UIComponents.CreateTextLabel({
        Name = "Meta",
        Text = (props.Rarity or "Common") .. " · " .. (props.Zone or ""),
        Size = UDim2.new(1, -12, 0, 16),
        Position = UDim2.fromOffset(6, iconAreaHeight + 18),
        Color = rarityColor,
        TextSize = UIStyles.FontSizes.Tiny,
        Parent = card,
    })

    -- Price
    local priceLabel = UIComponents.CreateTextLabel({
        Name = "Price",
        Text = "★ " .. tostring(props.SellPrice or 0),
        Size = UDim2.new(1, -12, 0, 16),
        Position = UDim2.fromOffset(6, iconAreaHeight + 36),
        Color = UIStyles.Colors.Gold,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Small,
        Parent = card,
    })

    return card
end

-- ============================================================
-- Component: Zone Transition Banner
-- ============================================================

function UIComponents.CreateZoneBanner(props)
    local zoneColor = props.ZoneColor or UIStyles.DepthZoneColor(props.ZoneName)
    local frameWidth = 320
    local frameHeight = 60

    local banner = New("Frame", {
        Name = "ZoneBanner",
        Size = UDim2.fromOffset(frameWidth, frameHeight),
        Position = UDim2.fromScale(0.5, -0.15),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = props.Parent,
    })
    NewCorner(UIStyles.Spacing.CornerRadius).Parent = banner
    NewStroke(zoneColor, 0.4, 2).Parent = banner

    -- Glow
    local glow = New("ImageLabel", {
        Size = UDim2.fromOffset(frameWidth, frameHeight),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5025537645",
        ImageColor3 = zoneColor,
        ImageTransparency = 0.85,
        ScaleType = Enum.ScaleType.Slice,
        ZIndex = 9,
        Parent = banner,
    })

    local title = UIComponents.CreateTextLabel({
        Name = "Title",
        Text = "⬇ ENTERING " .. string.upper(props.ZoneName or "UNKNOWN") .. " ⬇",
        Size = UDim2.fromScale(1, 1),
        Color = zoneColor,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = banner,
    })

    banner.AnimateIn = function(duration)
        duration = duration or 2
        return game:GetService("TweenService"):Create(banner,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.fromScale(0.5, 0.15)}
        )
    end

    banner.AnimateOut = function(duration)
        duration = duration or 1
        return game:GetService("TweenService"):Create(banner,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.fromScale(0.5, -0.15)}
        )
    end

    return banner
end

-- ============================================================
-- Component: Toast Notification
-- ============================================================

function UIComponents.CreateToast(props)
    local toast = New("Frame", {
        Name = "Toast",
        Size = UDim2.fromOffset(280, 44),
        Position = UDim2.fromScale(0.5, -0.1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = props.Color or UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.15,
        ClipsDescendants = true,
        ZIndex = 20,
        Parent = props.Parent,
    })
    NewCorner(UIStyles.Spacing.CornerRadius).Parent = toast

    local text = UIComponents.CreateTextLabel({
        Name = "Text",
        Text = (props.Icon or "") .. "  " .. (props.Text or ""),
        Size = UDim2.fromScale(1, 1),
        TextSize = UIStyles.FontSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = toast,
    })

    toast.AnimateIn = function()
        return game:GetService("TweenService"):Create(toast,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.fromScale(0.5, 0.1)}
        ):Play()
    end

    toast.AnimateOut = function()
        return game:GetService("TweenService"):Create(toast,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.fromScale(0.5, -0.1)}
        ):Play()
    end

    return toast
end

-- ================================================================
-- Component: Screen Transition Overlay
-- ================================================================

function UIComponents.CreateScreenTransition(props)
    local TweenService = game:GetService("TweenService")
    local direction = props.Direction or "left"  -- "left", "right", "up", "down", "fade"
    local duration = props.Duration or 0.25
    local parent = props.Parent

    local overlay = New("Frame", {
        Name = "ScreenTransition",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = UIStyles.Colors.DeepOcean,
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = parent,
    })

    local api = {}

    function api.SlideIn(callback)
        overlay.BackgroundTransparency = 0
        -- Start off-screen
        if direction == "left" then
            overlay.Position = UDim2.new(1, 0, 0, 0)
        elseif direction == "right" then
            overlay.Position = UDim2.new(-1, 0, 0, 0)
        elseif direction == "up" then
            overlay.Position = UDim2.new(0, 0, 1, 0)
        elseif direction == "down" then
            overlay.Position = UDim2.new(0, 0, -1, 0)
        end

        TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(0, 0)
        }):Play()

        if callback then
            task.delay(duration, callback)
        end
        return overlay
    end

    function api.SlideOut(callback)
        TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.fromScale(1, 0)
        }):Play()

        if callback then
            task.delay(duration, callback)
        end
        return overlay
    end

    function api.FadeIn(callback)
        TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        }):Play()

        if callback then
            task.delay(duration, callback)
        end
        return overlay
    end

    function api.FadeOut(callback)
        TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()

        if callback then
            task.delay(duration, callback)
        end
        return overlay
    end

    function api.Destroy()
        overlay:Destroy()
    end

    return api
end

-- ================================================================
-- Component: Level-Up Celebration Screen
-- ================================================================

function UIComponents.CreateLevelUpScreen(props)
    local TweenService = game:GetService("TweenService")
    local level = props.Level or 1
    local rewards = props.Rewards or {}
    local parent = props.Parent

    -- Full-screen overlay
    local overlay = New("Frame", {
        Name = "LevelUpOverlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        ZIndex = 30,
        Parent = parent,
    })

    -- Central celebration panel
    local panel = New("Frame", {
        Name = "LevelUpPanel",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        ZIndex = 31,
        Parent = overlay,
    })
    NewCorner(UIStyles.Spacing.CardRadius).Parent = panel
    NewStroke(UIStyles.Colors.Gold, 0.3, 3).Parent = panel

    -- Level up text
    local levelLabel = UIComponents.CreateTextLabel({
        Name = "LevelUpLabel",
        Text = "⬆ LEVEL UP! ⬆",
        Size = UDim2.fromOffset(280, 36),
        Position = UDim2.fromScale(0.5, 0.08),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.Gold,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 32,
        Parent = panel,
    })

    -- Level number (big)
    local levelValue = UIComponents.CreateTextLabel({
        Name = "LevelValue",
        Text = "Level " .. tostring(level),
        Size = UDim2.fromOffset(280, 60),
        Position = UDim2.fromScale(0.5, 0.2),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.Gold,
        Font = UIStyles.Fonts.Number,
        TextSize = 48,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 32,
        Parent = panel,
    })

    -- XP Bar
    local xpBar = New("Frame", {
        Name = "XPBar",
        Size = UDim2.fromOffset(260, 16),
        Position = UDim2.fromScale(0.5, 0.45),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.3,
        ClipsDescendants = true,
        ZIndex = 32,
        Parent = panel,
    })
    NewCorner(8).Parent = xpBar

    local xpFill = New("Frame", {
        Name = "XPFill",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = UIStyles.Colors.Cyan,
        ClipsDescendants = true,
        ZIndex = 33,
        Parent = xpBar,
    })
    NewCorner(8).Parent = xpFill

    local xpLabel = UIComponents.CreateTextLabel({
        Name = "XPLabel",
        Text = "XP  " .. tostring(props.XPRemaining or 0) .. " → NEXT LEVEL",
        Size = UDim2.fromOffset(260, 18),
        Position = UDim2.fromScale(0.5, 0.55),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.TextSecondary,
        TextSize = UIStyles.FontSizes.Tiny,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 32,
        Parent = panel,
    })

    -- Rewards list
    local rewardY = 0.62
    for _, reward in ipairs(rewards) do
        local rewardText = reward.icon and (reward.icon .. "  " .. reward.text) or reward.text
        local rLabel = UIComponents.CreateTextLabel({
            Name = "Reward_" .. tostring(_),
            Text = "+ " .. rewardText,
            Size = UDim2.fromOffset(260, 22),
            Position = UDim2.fromScale(0.5, rewardY),
            AnchorPoint = Vector2.new(0.5, 0),
            Color = reward.color or UIStyles.Colors.Gold,
            TextSize = UIStyles.FontSizes.Body,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 32,
            Parent = panel,
        })
        rewardY += 0.07
    end

    -- Continue button
    local continueBtn = UIComponents.CreateButton({
        Name = "ContinueBtn",
        Text = "CONTINUE",
        Size = UDim2.fromOffset(180, 48),
        Position = UDim2.fromScale(0.5, 0.9),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Color = UIStyles.Colors.Cyan,
        TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.Body,
        CornerRadius = 12,
        Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
        Callback = function()
            -- Animate out
            panel:TweenSize(
                UDim2.fromOffset(0, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.3,
                true,
                function()
                    overlay:Destroy()
                end
            )
        end,
        Parent = panel,
    })

    -- Animate panel in (scale-up)
    panel.Size = UDim2.fromOffset(0, 0)
    local inTween = panel:TweenSize(
        UDim2.fromOffset(300, 440),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.6,
        true
    )

    -- Animate XP bar fill after panel appears
    inTween.Completed:Wait()
    task.wait(0.2)
    TweenService:Create(xpFill, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(props.XPPercent or 0, 1)
    }):Play()

    -- Reward labels originally hidden, fade in
    for i, child in ipairs(panel:GetChildren()) do
        if child.Name:find("Reward_") then
            child.TextTransparency = 1
        end
    end
    task.delay(0.2, function()
        for i, child in ipairs(panel:GetChildren()) do
            if child.Name:find("Reward_") then
                task.wait(0.15)
                TweenService:Create(child, TweenInfo.new(0.3), {
                    TextTransparency = 0
                }):Play()
            end
        end
    end)

    return {
        overlay = overlay,
        panel = panel,
        Destroy = function()
            overlay:Destroy()
        end
    }
end

return UIComponents