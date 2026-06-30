--[[
    UIController — Complete UI implementation for Abyss of the Deep
    Manages HUD, Shop, Inventory screens with mobile-first deep-sea aesthetic.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local UIStyles = require(script.Parent.Parent.ui.UIStyles)
local UIComponents = require(script.Parent.Parent.ui.UIComponents)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Helper: create Roblox instances with properties
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

local UIController = Knit.CreateController {
    Name = "UIController",
}

-- ============================================================
-- State
-- ============================================================

local currentScreen = "HUD"
local screenStack = {}
local mainHolder = nil           -- AbyssUI ScreenGui
local cachedHUD = {}             -- HUD element references
local cachedScreens = {}         -- Full screen containers
local cachedBars = {}            -- Progress bar references for updates
local activePopups = {}          -- Active popup/notification refs

-- Local player reference
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer and localPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- Helper: Create UI Container (ScreenGui)
-- ============================================================

local function CreateScreenContainer(name)
    local container = Instance.new("ScreenGui")
    container.Name = name
    container.DisplayOrder = 2
    container.IgnoreGuiInset = true
    container.ResetOnSpawn = false
    container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    container.Parent = playerGui

    -- Safe area insets for mobile notch/status bar
    container.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullScreenExtension

    return container
end

-- ============================================================
-- KnitStart: Bootstrap the UI
-- ============================================================

function UIController:KnitStart()
    print("[UIController] Initializing Abyss of the Deep UI")

    -- Create the main UI container
    mainHolder = CreateScreenContainer("AbyssUI")

    -- Build the HUD (persistent background layer)
    self:BuildHUD()

    -- Register service event listeners
    self:RegisterServiceListeners()

    -- Show initial HUD
    self:ShowScreen("HUD")

    -- Check for mobile device and adjust
    self:DetectDevice()

    print("[UIController] UI Ready — Abyss of the Deep")
end

-- ============================================================
-- Device Detection
-- ============================================================

local isMobileDevice = false

function UIController:DetectDevice()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        isMobileDevice = true
        print("[UIController] Mobile device detected — optimizing touch targets")
    end
end

-- ============================================================
-- Service Event Listeners
-- ============================================================

function UIController:RegisterServiceListeners()
    -- Oxygen updates (every 1s from server)
    local OxygenService = Knit.GetService("OxygenService")
    if OxygenService then
        OxygenService.Client:Get("GetOxygenData"):Connect(function(data)
            self:UpdateOxygenDisplay(data)
        end)
    end

    -- Depth updates
    local DepthService = Knit.GetService("DepthService")
    if DepthService then
        DepthService.Client:Get("GetDepthData"):Connect(function(data)
            self:UpdateDepthDisplay(data)
        end)

        DepthService.Client:Get("GetLayerInfo"):Connect(function(data)
            self:ShowZoneTransition(data)
        end)
    end

    -- Creature encounters
    local CreatureService = Knit.GetService("CreatureService")
    if CreatureService then
        CreatureService.Client:Get("CreatureSpawned"):Connect(function(data)
            self:ShowCreatureEncounter(data)
        end)

        CreatureService.Client:Get("CreatureCaught"):Connect(function(data)
            self:ShowCatchResult(data)
        end)
    end

    -- Economy updates
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        EconomyService.Client:Get("EconomyUpdated"):Connect(function(data)
            self:UpdateEconomyDisplay(data)
        end)
    end

    -- Collection updates
    local CollectionService = Knit.GetService("CollectionService")
    if CollectionService then
        CollectionService.Client:Get("CollectionUpdated"):Connect(function(data)
            self:UpdateCollectionDisplay(data)
        end)
    end
end

-- ============================================================
-- SCREEN MANAGEMENT
-- ============================================================

function UIController:ShowScreen(screenName)
    if currentScreen == screenName then return end

    -- Hide all screens
    self:HideAllScreens()

    -- Show the requested screen
    if screenName == "HUD" then
        self:ShowHUD()
    elseif screenName == "Shop" then
        self:ShowShop()
    elseif screenName == "Collection" then
        self:ShowCollection()
    elseif screenName == "BaseEditor" then
        self:ShowBaseEditor()
    end

    currentScreen = screenName
end

function UIController:PushScreen(screenName)
    table.insert(screenStack, currentScreen)
    self:ShowScreen(screenName)
end

function UIController:PopScreen()
    if #screenStack == 0 then
        self:ShowScreen("HUD")
        return
    end
    local previousScreen = table.remove(screenStack)
    self:ShowScreen(previousScreen)
end

function UIController:HideAllScreens()
    -- Hide any overlay screens (non-HUD)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "AbyssUI" then
            gui.Enabled = false
        end
    end

    -- Hide HUD overlay elements
    if cachedHUD.container then
        cachedHUD.container.Visible = false
    end

    -- Clean up cached screens
    for _, screen in pairs(cachedScreens) do
        if screen and screen.Parent then
            screen:Destroy()
        end
    end
    cachedScreens = {}
end

-- ============================================================
-- BUILD HUD (called once)
-- ============================================================

function UIController:BuildHUD()
    -- Clear any existing HUD
    if cachedHUD.container then
        cachedHUD.container:Destroy()
    end

    -- Create a ScreenGui within AbyssUI for HUD elements
    local hudContainer = Instance.new("ScreenGui")
    hudContainer.Name = "HUDContainer"
    hudContainer.DisplayOrder = 1
    hudContainer.IgnoreGuiInset = true
    hudContainer.ResetOnSpawn = false
    hudContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    hudContainer.Parent = mainHolder

    cachedHUD.container = hudContainer

    -- ================================================================
    -- 1. TOP-LEFT: Depth & Zone Display
    -- ================================================================
    local depthFrame = New("Frame", {
        Name = "DepthDisplay",
        Size = UDim2.fromOffset(160, 72),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Parent = hudContainer,
    })

    -- Zone name label (above depth)
    local zoneLabel = UIComponents.CreateTextLabel({
        Name = "ZoneName",
        Text = "Sunlight Zone",
        Size = UDim2.fromOffset(160, 18),
        Position = UDim2.fromScale(0, 0),
        Color = UIStyles.Colors.ElectricBlue,
        Font = UIStyles.Fonts.Body,
        TextSize = UIStyles.FontSizes.Small,
        Parent = depthFrame,
    })
    cachedHUD.zoneName = zoneLabel

    -- Depth value (large, bold)
    local depthValue = UIComponents.CreateTextLabel({
        Name = "DepthValue",
        Text = "0m",
        Size = UDim2.fromOffset(160, 38),
        Position = UDim2.fromScale(0, 0.3),
        Color = UIStyles.Colors.Cyan,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.HUDPrimary,
        Parent = depthFrame,
    })
    cachedHUD.depthValue = depthValue

    -- Sub-label
    local depthLabel = UIComponents.CreateTextLabel({
        Name = "DepthLabel",
        Text = "DEPTH",
        Size = UDim2.fromOffset(160, 14),
        Position = UDim2.fromScale(0, 0.82),
        Color = UIStyles.Colors.TextMuted,
        TextSize = UIStyles.FontSizes.Tiny,
        Parent = depthFrame,
    })

    -- ================================================================
    -- 2. TOP-RIGHT: Dive Timer
    -- ================================================================
    local timerFrame = New("Frame", {
        Name = "TimerDisplay",
        Size = UDim2.fromOffset(100, 40),
        Position = UDim2.new(1, -116, 0, 16),
        BackgroundTransparency = 1,
        Parent = hudContainer,
    })

    local timerLabel = UIComponents.CreateTextLabel({
        Name = "TimerLabel",
        Text = "DIVE TIME",
        Size = UDim2.fromOffset(100, 14),
        Position = UDim2.fromScale(0, 0),
        Color = UIStyles.Colors.TextMuted,
        TextSize = UIStyles.FontSizes.Tiny,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = timerFrame,
    })

    local timerValue = UIComponents.CreateTextLabel({
        Name = "TimerValue",
        Text = "00:00",
        Size = UDim2.fromOffset(100, 24),
        Position = UDim2.fromScale(0, 0.4),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.HUDSmall,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = timerFrame,
    })
    cachedHUD.timerValue = timerValue

    -- ================================================================
    -- 3. LEFT EDGE: O₂ Bar (Vertical)
    -- ================================================================
    local oxyBar = UIComponents.CreateVerticalBar({
        Name = "OxygenBar",
        Size = UDim2.fromOffset(8, 160),
        Position = UDim2.fromOffset(18, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        FillColor = UIStyles.Colors.Cyan,
        FillGradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
        BackgroundColor = UIStyles.Colors.SurfaceDark,
        Current = 100,
        Max = 100,
        Label = "🫧",
        ShowPercent = true,
        Parent = hudContainer,
    })
    oxyBar.Position = UDim2.fromOffset(14, 0.5)
    oxyBar.AnchorPoint = Vector2.new(0, 0.5)
    oxyBar.Parent = hudContainer
    cachedBars.oxygen = oxyBar

    -- O₂ text label next to bar
    local oxyText = UIComponents.CreateTextLabel({
        Name = "OxygenText",
        Text = "O₂",
        Size = UDim2.fromOffset(36, 16),
        Position = UDim2.fromOffset(8, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.Cyan,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Small,
        Parent = hudContainer,
    })
    oxyText.Position = UDim2.fromOffset(8, 0.5)
    oxyText.AnchorPoint = Vector2.new(0, 0.5)
    cachedHUD.oxyText = oxyText

    -- ================================================================
    -- 4. RIGHT EDGE: Pressure Meter (Vertical)
    -- ================================================================
    local pressureBar = UIComponents.CreateVerticalBar({
        Name = "PressureBar",
        Size = UDim2.fromOffset(8, 160),
        Position = UDim2.new(1, -14, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        FillColor = UIStyles.Colors.DeepPurple,
        FillGradient = {UIStyles.Colors.DeepPurple, UIStyles.Colors.ElectricBlue},
        BackgroundColor = UIStyles.Colors.SurfaceDark,
        Current = 0,
        Max = 100,
        Label = "🛡️",
        ShowPercent = false,
        Parent = hudContainer,
    })
    cachedBars.pressure = pressureBar

    -- Depth limit text below pressure
    local depthLimitText = UIComponents.CreateTextLabel({
        Name = "DepthLimit",
        Text = "Gear: T1",
        Size = UDim2.fromOffset(80, 16),
        Position = UDim2.new(1, -90, 0.5, 90),
        Color = UIStyles.Colors.DeepPurple,
        TextSize = UIStyles.FontSizes.Tiny,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = hudContainer,
    })
    cachedHUD.depthLimit = depthLimitText

    -- ================================================================
    -- 5. BOTTOM-LEFT: Currency & Resources Display
    -- ================================================================
    local currencyFrame = New("Frame", {
        Name = "CurrencyDisplay",
        Size = UDim2.fromOffset(180, 108),
        Position = UDim2.fromOffset(16, 1),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Parent = hudContainer,
    })
    currencyFrame.Position = UDim2.fromOffset(16, -156)

    -- Helper: build a currency row
    local function BuildCurrencyRow(name, icon, color, yOffset, cacheKey)
        local row = New("Frame", {
            Name = name,
            Size = UDim2.fromOffset(180, 23),
            Position = UDim2.fromOffset(0, yOffset),
            BackgroundColor3 = UIStyles.Colors.CardBG,
            BackgroundTransparency = 0.4,
            Parent = currencyFrame,
        })
        NewCorner(6).Parent = row
        NewStroke(color, 0.8, 1).Parent = row

        local iconLabel = UIComponents.CreateTextLabel({
            Name = "Icon",
            Text = icon,
            Size = UDim2.fromOffset(22, 23),
            Color = color,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = row,
        })
        local value = UIComponents.CreateTextLabel({
            Name = "Value",
            Text = "0",
            Size = UDim2.new(1, -26, 1, 0),
            Position = UDim2.fromOffset(26, 0),
            Color = color,
            Font = UIStyles.Fonts.Number,
            TextSize = UIStyles.FontSizes.HUDSmall,
            Parent = row,
        })
        cachedHUD[cacheKey] = value
    end

    -- Row 0: Depth Credits (gold)
    BuildCurrencyRow("DepthCredits", "🪙", UIStyles.Colors.Gold, 0, "credits")
    -- Row 1: Research Points (purple)
    BuildCurrencyRow("ResearchPoints", "🔬", UIStyles.Colors.DeepPurple, 26, "researchPoints")
    -- Row 2: Scrap (green)
    BuildCurrencyRow("Scrap", "🔩", UIStyles.Colors.BioGreen, 52, "scrap")
    -- Row 3: Crystal (cyan-blue)
    BuildCurrencyRow("Crystal", "💎", UIStyles.Colors.Cyan, 78, "crystal")

    -- ================================================================
    -- 6. BOTTOM-RIGHT: Action Buttons (Shop, Inventory, Journal)
    -- ================================================================
    local actionsFrame = New("Frame", {
        Name = "ActionButtons",
        Size = UDim2.fromOffset(68, 220),
        Position = UDim2.new(1, -84, 1, -260),
        BackgroundTransparency = 1,
        Parent = hudContainer,
    })

    -- Shop button
    local shopBtn = UIComponents.CreateIconButton({
        Name = "ShopButton",
        Icon = "🛒",
        Color = UIStyles.Colors.Cyan,
        StrokeColor = UIStyles.Colors.Cyan,
        Callback = function()
            self:PushScreen("Shop")
        end,
        Parent = actionsFrame,
    })
    shopBtn.Position = UDim2.fromScale(0.5, 0)

    -- Inventory button
    local invBtn = UIComponents.CreateIconButton({
        Name = "InventoryButton",
        Icon = "🎒",
        Color = UIStyles.Colors.DeepPurple,
        StrokeColor = UIStyles.Colors.DeepPurple,
        Callback = function()
            self:PushScreen("Collection")
        end,
        Parent = actionsFrame,
    })
    invBtn.Position = UDim2.fromScale(0.5, 0.37)

    -- Journal button (future feature)
    local journalBtn = UIComponents.CreateIconButton({
        Name = "JournalButton",
        Icon = "📖",
        Color = UIStyles.Colors.Gold,
        StrokeColor = UIStyles.Colors.Gold,
        Callback = function()
            self:ShowGameMessage("Journal coming soon! 📖")
        end,
        Parent = actionsFrame,
    })
    journalBtn.Position = UDim2.fromScale(0.5, 0.74)

    -- ================================================================
    -- 7. BOTTOM-CENTER: Primary Action Button (Dive/Surface)
    -- ================================================================
    local isDiving = false

    local primaryBtn = UIComponents.CreateButton({
        Name = "PrimaryAction",
        Text = "DIVE",
        Size = UDim2.fromOffset(140, 50),
        Position = UDim2.fromScale(0.5, 1),
        AnchorPoint = Vector2.new(0.5, 1),
        Color = UIStyles.Colors.Cyan,
        TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.HUDSmall,
        CornerRadius = 14,
        Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
        Callback = function()
            if isDiving then
                -- Surface
                local DepthService = Knit.GetService("DepthService")
                if DepthService then
                    DepthService.Client:Get("SurfacePlayer"):Fire()
                end
                isDiving = false
                local label = primaryBtn:FindFirstChild("Label", true)
                if label then label.Text = "DIVE" end
                cachedHUD.primaryBtn = primaryBtn
            else
                -- Dive
                local DivingController = Knit.GetController("DivingController")
                if DivingController then
                    DivingController:StartDive()
                end
                isDiving = true
                local label = primaryBtn:FindFirstChild("Label", true)
                if label then label.Text = "▲ SURFACE" end
            end
        end,
        Parent = hudContainer,
    })
    primaryBtn.Position = UDim2.fromScale(0.5, 1)
    primaryBtn.AnchorPoint = Vector2.new(0.5, 1)
    primaryBtn.Position = UDim2.fromOffset(-70, -70)
    cachedHUD.primaryBtn = primaryBtn

    -- Store dive state reference
    cachedHUD.isDivingRef = function(state)
        isDiving = state
        local label = primaryBtn:FindFirstChild("Label", true)
        if label then
            label.Text = state and "▲ SURFACE" or "DIVE"
        end
    end

    -- ================================================================
    -- 8. TOP-CENTER: Alert Zone (for anomaly warnings, transitions)
    -- ================================================================
    local alertFrame = New("Frame", {
        Name = "AlertFrame",
        Size = UDim2.fromOffset(260, 40),
        Position = UDim2.fromScale(0.5, 0.08),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = hudContainer,
    })
    cachedHUD.alertFrame = alertFrame

    -- Anomaly warning (hidden by default)
    local anomalyWarn = UIComponents.CreateTextLabel({
        Name = "AnomalyWarning",
        Text = "⚠ ANOMALY DETECTED",
        Size = UDim2.fromOffset(260, 32),
        Position = UDim2.fromScale(0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.Danger,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Center,
        Transparency = 1, -- Hidden by default
        Parent = alertFrame,
    })
    cachedHUD.anomalyWarning = anomalyWarn
end

-- ================================================================
-- SHOW HUD (toggle visibility)
-- ================================================================

function UIController:ShowHUD()
    if cachedHUD.container then
        cachedHUD.container.Visible = true
    end
end

-- ================================================================
-- UPDATE: Oxygen Display
-- ================================================================

function UIController:UpdateOxygenDisplay(data)
    if not data then return end

    local current = data.current or 0
    local maxOxygen = data.maxOxygen or Config.Player.MaxOxygen
    local isCritical = data.isCritical or (current / maxOxygen <= 0.2)

    -- Update O₂ bar
    if cachedBars.oxygen then
        cachedBars.oxygen.UpdateFill(current, maxOxygen)
    end

    -- Critical warning animation
    if isCritical and cachedHUD.oxyText then
        cachedHUD.oxyText.Text = "⚠ O₂"
        cachedHUD.oxyText.TextColor3 = UIStyles.Colors.Danger

        -- Pulse animation
        if not cachedHUD._oxyPulse then
            cachedHUD._oxyPulse = TweenService:Create(cachedHUD.oxyText,
                TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
                {TextTransparency = 0.3}
            )
            cachedHUD._oxyPulse:Play()
        end
    elseif cachedHUD.oxyText then
        cachedHUD.oxyText.Text = "O₂"
        cachedHUD.oxyText.TextColor3 = UIStyles.Colors.Cyan
        if cachedHUD._oxyPulse then
            cachedHUD._oxyPulse:Cancel()
            cachedHUD._oxyPulse = nil
        end
    end
end

-- ================================================================
-- UPDATE: Depth Display
-- ================================================================

function UIController:UpdateDepthDisplay(data)
    if not data then return end

    local depth = data.depth or 0
    local depthStr = tostring(math.floor(depth)) .. "m"
    local zoneName = data.layerName or "Sunlight Zone"
    local gearTier = data.gearTier or 1
    local maxSafeDepth = data.maxSafeDepth or 200

    -- Update depth value
    if cachedHUD.depthValue then
        cachedHUD.depthValue.Text = depthStr
    end

    -- Update zone name with color
    if cachedHUD.zoneName then
        cachedHUD.zoneName.Text = zoneName
        cachedHUD.zoneName.TextColor3 = UIStyles.DepthZoneColor(zoneName)
    end

    -- Update pressure bar
    if cachedBars.pressure then
        local pct = maxSafeDepth > 0 and math.min(depth / maxSafeDepth, 1) or 0
        cachedBars.pressure.UpdateFill(depth * 100, maxSafeDepth * 100)
    end

    -- Update depth limit text
    if cachedHUD.depthLimit then
        cachedHUD.depthLimit.Text = "Gear: T" .. tostring(gearTier) .. " | " .. tostring(maxSafeDepth) .. "m"

        -- Color based on proximity to limit
        local ratio = maxSafeDepth > 0 and depth / maxSafeDepth or 0
        if ratio >= 0.9 then
            cachedHUD.depthLimit.TextColor3 = UIStyles.Colors.Danger
        elseif ratio >= 0.7 then
            cachedHUD.depthLimit.TextColor3 = UIStyles.Colors.Warning
        else
            cachedHUD.depthLimit.TextColor3 = UIStyles.Colors.DeepPurple
        end
    end

    -- Check for anomalies
    if data.anomalyActive then
        if cachedHUD.anomalyWarning then
            cachedHUD.anomalyWarning.TextTransparency = 0
            cachedHUD.anomalyWarning.TextColor3 = UIStyles.Colors.Danger
        end
    else
        if cachedHUD.anomalyWarning then
            cachedHUD.anomalyWarning.TextTransparency = 1
        end
    end
end

-- ================================================================
-- UPDATE: Economy Display
-- ================================================================

function UIController:UpdateEconomyDisplay(data)
    if not data then return end

    -- EconomyService sends capitalized field names: Credits, ResearchPoints, XP, Level
    local credits = data.Credits or data.credits or data.currency or 0
    local researchPoints = data.ResearchPoints or data.researchPoints or data.rp or 0
    local xp = data.XP or data.experience or data.xp or 0
    local level = data.Level or data.level or 1
    local xpNeeded = data.XPNeeded or 0

    -- Scrap and Crystal are stored in the inventory or could come as separate fields
    local scrap = data.Scrap or 0
    local crystal = data.Crystal or 0
    -- Also check inventory for scrap/crystal counts
    if data.Inventory then
        scrap = data.Inventory.Scrap or data.Inventory.scrap or scrap
        crystal = data.Inventory.Crystal or data.Inventory.crystal or crystal
    end

    -- Format numbers with commas
    local function formatNum(n)
        local formatted = tostring(math.floor(n))
        while true do
            local k
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
        end
        return formatted
    end

    if cachedHUD.credits then
        cachedHUD.credits.Text = formatNum(credits)
    end

    if cachedHUD.researchPoints then
        cachedHUD.researchPoints.Text = formatNum(researchPoints)
    end

    -- Update Scrap display
    if cachedHUD.scrap then
        cachedHUD.scrap.Text = formatNum(scrap)
        -- Pulse green briefly on change
        local currentText = cachedHUD.scrap.Text
    end

    -- Update Crystal display
    if cachedHUD.crystal then
        cachedHUD.crystal.Text = formatNum(crystal)
    end
end

-- ================================================================
-- UPDATE: Collection Display
-- ================================================================

function UIController:UpdateCollectionDisplay(data)
    -- Stub — used when collection view is open
    if cachedScreens.Collection and cachedScreens.Collection._update then
        cachedScreens.Collection._update(data)
    end
end

-- ================================================================
-- SHOP SCREEN
-- ================================================================

function UIController:ShowShop()
    if cachedScreens.Shop then
        cachedScreens.Shop.Enabled = true
        return
    end

    -- Create shop container (overlay)
    local container = CreateScreenContainer("ShopUI")
    container.DisplayOrder = 5
    cachedScreens.Shop = container

    -- Background dimmer (click to close)
    local dimmer = New("Frame", {
        Name = "Dimmer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        Parent = container,
    })

    -- Shop panel (scrollable)
    local shopPanel = New("Frame", {
        Name = "ShopPanel",
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Parent = container,
    })
    NewCorner(20).Parent = shopPanel
    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = shopPanel

    -- Shop content
    local contentPadding = New("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        Parent = shopPanel,
    })

    -- Header
    local headerFrame = New("Frame", {
        Name = "ShopHeader",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 50),
        BackgroundTransparency = 1,
        Parent = shopPanel,
    })

    local titleLabel = UIComponents.CreateTextLabel({
        Name = "Title",
        Text = "🏪 EQUIPMENT SHOP",
        Size = UDim2.fromOffset(250, 28),
        Position = UDim2.fromScale(0, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        Parent = headerFrame,
    })

    local closeBtn = UIComponents.CreateIconButton({
        Name = "CloseBtn",
        Icon = "✕",
        Size = 36,
        Color = UIStyles.Colors.Elevated,
        StrokeColor = UIStyles.Colors.Border,
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Callback = function()
            self:PopScreen()
        end,
        Parent = headerFrame,
    })

    -- Currency bar
    local currencyBar = UIComponents.CreatePanel({
        Name = "ShopCurrency",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 40),
        Color = UIStyles.Colors.CardBG,
        Transparency = 0.4,
        Parent = shopPanel,
    })

    local currencyFrame = New("Frame", {
        Name = "CurrencyFrame",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = currencyBar,
    })

    -- Dynamic currency labels
    local shopCredits = UIComponents.CreateTextLabel({
        Text = "🪙 50",
        Size = UDim2.fromOffset(120, 40),
        Color = UIStyles.Colors.Gold,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.HUDSmall,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = currencyFrame,
    })

    local shopRP = UIComponents.CreateTextLabel({
        Text = "🔬 0",
        Size = UDim2.fromOffset(120, 40),
        Position = UDim2.fromOffset(140, 0),
        Color = UIStyles.Colors.DeepPurple,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.HUDSmall,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = currencyFrame,
    })

    -- Keep references for updates
    container._creditsLabel = shopCredits
    container._rpLabel = shopRP

    -- Listen for economy updates
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        EconomyService.Client:Get("EconomyUpdated"):Connect(function(data)
            if container and container.Parent then
                local c = data.currency or data.credits or 0
                local r = data.researchPoints or data.rp or 0
                shopCredits.Text = "🪙 " .. tostring(math.floor(c))
                shopRP.Text = "🔬 " .. tostring(math.floor(r))
            end
        end)
    end

    -- Category tabs
    local tabsFrame = New("Frame", {
        Name = "Tabs",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 40),
        BackgroundTransparency = 1,
        Parent = shopPanel,
    })

    local categories = {"Diving Suits", "Submarines", "Tools", "Upgrades"}
    local selectedCategory = 1

    local function BuildCategoryTab(index, name)
        local isSelected = index == selectedCategory
        local tab = UIComponents.CreateButton({
            Name = "Tab_" .. name,
            Text = name,
            Size = UDim2.fromOffset(0, 32),
            Position = UDim2.fromScale(0, 0),
            Color = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.SurfaceDark,
            Transparency = isSelected and 0.8 or 0.5,
            TextColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.TextMuted,
            FontSize = UIStyles.FontSizes.Small,
            CornerRadius = 8,
            Stroke = true,
            StrokeColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.Border,
            Callback = function()
                selectedCategory = index
                -- Rebuild tabs
                for _, child in ipairs(tabsFrame:GetChildren()) do
                    child:Destroy()
                end
                for i, catName in ipairs(categories) do
                    local newTab = BuildCategoryTab(i, catName)
                    newTab.Position = UDim2.fromOffset((i - 1) * 120, 4)
                    newTab.Size = UDim2.fromOffset(110, 32)
                    newTab.Parent = tabsFrame
                end
                -- Refresh items
                self:RefreshShopItems(shopPanel, selectedCategory)
            end,
        })
        return tab
    end

    -- Build tabs
    for i, catName in ipairs(categories) do
        local tab = BuildCategoryTab(i, catName)
        tab.Size = UDim2.fromOffset(110, 32)
        tab.Position = UDim2.fromOffset((i - 1) * 120, 4)
        tab.Parent = tabsFrame
    end

    -- Items scrolling area (filled by RefreshShopItems)
    local itemsFrame = New("Frame", {
        Name = "ItemsFrame",
        Size = UDim2.new(1, 0, 1, -170),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Parent = shopPanel,
    })
    itemsFrame.Position = UDim2.fromOffset(0, 170)
    shopPanel._itemsFrame = itemsFrame

    -- Scrolling wrapper
    local scrolling = New("ScrollingFrame", {
        Name = "ScrollingItems",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UIStyles.Colors.Cyan,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromScale(1, 1),
        Parent = itemsFrame,
    })
    shopPanel._scrolling = scrolling

    -- Populate first category
    self:RefreshShopItems(shopPanel, selectedCategory)

    -- Store close function
    container.Close = function()
        container.Enabled = false
    end
end

-- ================================================================
-- Refresh Shop Items (by category)
-- ================================================================

function UIController:RefreshShopItems(shopPanel, categoryIndex)
    local scrolling = shopPanel._scrolling
    if not scrolling then return end

    -- Clear existing items
    for _, child in ipairs(scrolling:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Gear data from Config
    local function GetGearItems()
        local items = {}
        for _, gear in ipairs(Config.DivingGear) do
            table.insert(items, {
                name = gear.Name,
                icon = gear.Tier <= 2 and "🤿" or gear.Tier <= 3 and "🫧" or gear.Tier <= 4 and "🚤" or "🛸",
                tier = gear.Tier,
                stats = string.format("O₂: +%d · Speed: x%.1f · Limit: %dm", gear.OxygenBonus, gear.SpeedModifier, gear.MaxDepth),
                price = gear.Price,
                priceType = "credits",
                category = "Diving Suits",
            })
        end
        return items
    end

    local allItems = {
        GetGearItems(),  -- Diving Suits
        {                -- Submarines
            {name = "Explorer Sub", icon = "🚤", tier = 1, stats = "Hull: 200 · Cargo: 10 · Depth: 1,000m", price = 500, priceType = "credits"},
            {name = "Nautilus MkII", icon = "🛸", tier = 2, stats = "Hull: 500 · Cargo: 25 · Depth: 4,000m", price = 2000, priceType = "credits"},
            {name = "Abyssal Crawler", icon = "⚙️", tier = 3, stats = "Hull: 1200 · Cargo: 50 · Depth: 11,000m", price = 8000, priceType = "credits"},
            {name = "Phantom Sub", icon = "👻", tier = 2, stats = "Stealth mode · Anomaly resistance", price = 350, priceType = "robux"},
        },
        {                -- Tools
            {name = "Harpoon Gun", icon = "🔱", tier = 1, stats = "Damage: 20 · Range: 50m", price = 100, priceType = "credits"},
            {name = "Deep Scanner", icon = "📡", tier = 2, stats = "Reveals rare resources · 100m range", price = 400, priceType = "credits"},
            {name = "Mining Drill", icon = "⛏️", tier = 2, stats = "Ore yield: 2x · Speed: Fast", price = 600, priceType = "credits"},
            {name = "Sonic Bait", icon = "🎵", tier = 1, stats = "Attracts rare creatures", price = 150, priceType = "robux"},
        },
        {                -- Upgrades
            {name = "O₂ Extender", icon = "🫧", tier = 1, stats = "+50 Max Oxygen", price = 200, priceType = "credits"},
            {name = "Hull Plating", icon = "🛡️", tier = 2, stats = "+20% Pressure Resistance", price = 800, priceType = "credits"},
            {name = "Speed Fins", icon = "🏊", tier = 1, stats = "+15% Swim Speed", price = 300, priceType = "credits"},
            {name = "Xp Booster", icon = "⚡", tier = 1, stats = "2x XP for 1 hour", price = 50, priceType = "robux"},
            {name = "Collection Slot+", icon = "📦", tier = 1, stats = "+20 Collection Slots", price = 100, priceType = "robux"},
        },
    }

    local items = allItems[categoryIndex] or {}

    for i, item in ipairs(items) do
        -- Determine state based on player gear
        local state = "available"
        if item.price == 0 then
            state = "owned"
        end

        local card = UIComponents.CreateShopItemCard({
            Name = item.name,
            Icon = item.icon,
            Tier = item.tier,
            Stats = item.stats,
            Price = item.price,
            PriceType = item.priceType,
            State = state,
            OnPurchase = function()
                self:ShowGameMessage("Purchase: " .. item.name .. " — " .. tostring(item.price))
                -- In production, this would call EconomyService
            end,
            Parent = scrolling,
        })
        card.Position = UDim2.fromOffset(0, (i - 1) * 98 + 4)
    end

    -- Update canvas size
    scrolling.CanvasSize = UDim2.fromOffset(0, #items * 98 + 8)
end

-- ================================================================
-- COLLECTION SCREEN (Inventory)
-- ================================================================

function UIController:ShowCollection()
    if cachedScreens.Collection then
        cachedScreens.Collection.Enabled = true
        return
    end

    local container = CreateScreenContainer("CollectionUI")
    container.DisplayOrder = 5
    cachedScreens.Collection = container

    -- Dimmer
    local dimmer = New("Frame", {
        Name = "Dimmer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        Parent = container,
    })

    -- Collection Panel
    local panel = New("Frame", {
        Name = "CollectionPanel",
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Parent = container,
    })
    NewCorner(20).Parent = panel
    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = panel

    -- Header
    local headerFrame = New("Frame", {
        Name = "CollectionHeader",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 50),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local titleLabel = UIComponents.CreateTextLabel({
        Text = "🎒 COLLECTION",
        Size = UDim2.fromOffset(250, 28),
        Position = UDim2.fromScale(0, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        Parent = headerFrame,
    })

    local closeBtn = UIComponents.CreateIconButton({
        Icon = "✕",
        Size = 36,
        Color = UIStyles.Colors.Elevated,
        StrokeColor = UIStyles.Colors.Border,
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Callback = function()
            self:PopScreen()
        end,
        Parent = headerFrame,
    })

    -- Filter tabs
    local filtersFrame = New("Frame", {
        Name = "Filters",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 36),
        BackgroundTransparency = 1,
        Parent = panel,
    })
    filtersFrame.Position = UDim2.fromOffset(0, 56)

    local filters = {"All", "Creatures", "Minerals", "Equipment", "Anomalies"}
    for i, filterName in ipairs(filters) do
        local filterTab = UIComponents.CreateButton({
            Name = "Filter_" .. filterName,
            Text = filterName,
            Size = UDim2.fromOffset(0, 30),
            Position = UDim2.fromOffset((i - 1) * 90, 0),
            Color = i == 1 and UIStyles.Colors.Cyan or UIStyles.Colors.SurfaceDark,
            Transparency = i == 1 and 0.8 or 0.5,
            TextColor = i == 1 and UIStyles.Colors.Cyan or UIStyles.Colors.TextMuted,
            FontSize = UIStyles.FontSizes.Small,
            CornerRadius = 8,
            Stroke = true,
            StrokeColor = i == 1 and UIStyles.Colors.Cyan or UIStyles.Colors.Border,
            Parent = filtersFrame,
        })
        filterTab.Size = UDim2.fromOffset(80, 30)
    end

    -- Grid (Scrollable)
    local gridFrame = New("Frame", {
        Name = "GridFrame",
        Size = UDim2.new(1, 0, 1, -106),
        Position = UDim2.fromOffset(0, 106),
        BackgroundTransparency = 1,
        Parent = panel,
    })

    local grid = New("ScrollingFrame", {
        Name = "CreatureGrid",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UIStyles.Colors.DeepPurple,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromScale(1, 2),
        Parent = gridFrame,
    })

    -- Sample creature data (in production, comes from CollectionService)
    local sampleCreatures = {
        {name = "Glowfin Tetra", icon = "🐟", rarity = "Common", sellPrice = 45, zone = "Twilight"},
        {name = "Shadow Shark", icon = "🦈", rarity = "Rare", sellPrice = 320, zone = "Midnight"},
        {name = "Void Crystal", icon = "💎", rarity = "Rare", sellPrice = 280, zone = "Abyss"},
        {name = "Biolum Coral", icon = "🪸", rarity = "Uncommon", sellPrice = 120, zone = "Twilight"},
        {name = "Phantom Squid", icon = "🐙", rarity = "Epic", sellPrice = 950, zone = "Abyss"},
        {name = "Iron Ore", icon = "🪨", rarity = "Common", sellPrice = 15, zone = "Sunlight"},
        {name = "Echo Eye", icon = "👁️", rarity = "Anomaly", sellPrice = 2400, zone = "Trench"},
        {name = "Depth Pearl", icon = "🔮", rarity = "Epic", sellPrice = 780, zone = "Midnight"},
        {name = "Kelp Sprout", icon = "🌿", rarity = "Common", sellPrice = 8, zone = "Sunlight"},
        {name = "Anglerfish", icon = "🎣", rarity = "Uncommon", sellPrice = 65, zone = "Midnight"},
        {name = "Ancient Coin", icon = "🪙", rarity = "Rare", sellPrice = 500, zone = "Abyss"},
        {name = "Abyssal Crown", icon = "👑", rarity = "Legendary", sellPrice = 5000, zone = "Trench"},
    }

    -- Build grid items in a 2-column layout
    local cols = 2
    local cardWidth = (grid.AbsoluteSize.X - 20) / cols
    local cardHeight = 170

    for i, creature in ipairs(sampleCreatures) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local card = UIComponents.CreateCreatureCard({
            Name = creature.name,
            Icon = creature.icon,
            Rarity = creature.rarity,
            SellPrice = creature.sellPrice,
            Zone = creature.zone,
            Size = cardWidth - 8,
            Position = UDim2.fromOffset(col * (cardWidth + 8), row * (cardHeight + 8) + 4),
            Parent = grid,
        })
    end

    -- Update canvas size for grid
    local totalRows = math.ceil(#sampleCreatures / cols)
    grid.CanvasSize = UDim2.fromOffset(0, totalRows * (cardHeight + 8) + 12)

    -- Add _update handler for real-time collection data from CollectionService
    -- CollectionService sends: { totalUnique, totalPossible, completion, isNewDiscovery }
    container._update = function(data)
        if not data then return end
        local totalUnique = data.totalUnique or 0
        local totalPossible = data.totalPossible or 1
        local completion = (totalPossible > 0 and math.floor((totalUnique / totalPossible) * 100)) or 0
        local isNew = data.isNewDiscovery or false

        -- Update title to show progress
        if titleLabel then
            titleLabel.Text = "🎒 COLLECTION (" .. tostring(totalUnique) .. "/" .. tostring(totalPossible) .. ")"
        end

        -- Show toast for new discovery
        if isNew then
            self:ShowGameMessage("🌟 New discovery added to collection!")
        end
    end
end

-- ================================================================
-- EVENT: Zone Transition Banner
-- ================================================================

function UIController:ShowZoneTransition(data)
    if not data or not data.layerName then return end

    local container = cachedHUD.alertFrame
    if not container then return end

    -- Remove old banners
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == "ZoneBanner" then
            child:Destroy()
        end
    end

    local banner = UIComponents.CreateZoneBanner({
        ZoneName = data.layerName,
        ZoneColor = UIStyles.DepthZoneColor(data.layerName),
        Parent = container,
    })

    -- Animate in
    local tweenIn = banner.AnimateIn(1.5)
    tweenIn.Completed:Wait()

    -- Hold for 3 seconds
    task.wait(3)

    -- Animate out
    local tweenOut = banner.AnimateOut(0.8)
    tweenOut.Completed:Wait()

    -- Cleanup
    banner:Destroy()
end

-- ================================================================
-- EVENT: Creature Encounter Popup
-- ================================================================

function UIController:ShowCreatureEncounter(data)
    if not data then return end

    local popupContainer = mainHolder

    -- Encounter card
    local encounterFrame = New("Frame", {
        Name = "CreatureEncounter",
        Size = UDim2.fromOffset(280, 180),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.1,
        ClipsDescendants = true,
        ZIndex = 15,
        Parent = popupContainer,
    })
    NewCorner(16).Parent = encounterFrame
    NewStroke(UIStyles.RarityToColor(data.rarity or "Common"), 0.4, 2).Parent = encounterFrame

    local iconLabel = UIComponents.CreateTextLabel({
        Text = data.icon or "🐟",
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.fromScale(0.5, 0.2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextSize = 48,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = encounterFrame,
    })

    local nameLabel = UIComponents.CreateTextLabel({
        Text = data.name or "Unknown Creature",
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.fromScale(0.5, 0.42),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.Colors.TextPrimary,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.ItemName,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = encounterFrame,
    })

    local rarityLabel = UIComponents.CreateTextLabel({
        Text = (data.rarity or "Common") .. " · " .. (data.size or "Medium"),
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.fromScale(0.5, 0.52),
        AnchorPoint = Vector2.new(0.5, 0),
        Color = UIStyles.RarityToColor(data.rarity or "Common"),
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = encounterFrame,
    })

    -- Catch button
    local catchBtn = UIComponents.CreateButton({
        Text = "🎣 CATCH",
        Size = UDim2.fromOffset(160, 44),
        Position = UDim2.fromScale(0.5, 0.82),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Color = UIStyles.Colors.Cyan,
        TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.Body,
        CornerRadius = 12,
        Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
        Callback = function()
            -- Send catch request to server
            local CreatureService = Knit.GetService("CreatureService")
            if CreatureService then
                CreatureService.Client:Get("RequestCatch"):Fire()
            end
            -- Close encounter
            encounterFrame:TweenSize(
                UDim2.fromOffset(0, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.3,
                true,
                function()
                    encounterFrame:Destroy()
                end
            )
        end,
        Parent = encounterFrame,
    })

    -- Animate in
    encounterFrame.Size = UDim2.fromOffset(0, 0)
    encounterFrame:TweenSize(
        UDim2.fromOffset(280, 180),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.4,
        true
    )

    -- Auto-dismiss after 10 seconds
    task.delay(10, function()
        if encounterFrame and encounterFrame.Parent then
            encounterFrame:TweenSize(
                UDim2.fromOffset(0, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.3,
                true,
                function()
                    encounterFrame:Destroy()
                end
            )
        end
    end)

    -- Cleanup if player opens another screen
    activePopups.encounter = function()
        if encounterFrame and encounterFrame.Parent then
            encounterFrame:Destroy()
        end
    end
end

-- ================================================================
-- EVENT: Catch Result Animation
-- ================================================================

function UIController:ShowCatchResult(data)
    if not data then return end

    -- Clean up encounter if still showing
    if activePopups.encounter then
        activePopups.encounter()
        activePopups.encounter = nil
    end

    local success = data.success or false

    if success then
        self:ShowGameMessage("🎉 Caught! " .. (data.name or "Creature") .. " — ★" .. tostring(data.sellPrice or 0))
    else
        self:ShowGameMessage("💨 It got away! Try again.")
    end
end

-- ================================================================
-- Toast / Game Message
-- ================================================================

function UIController:ShowGameMessage(message)
    if not message then return end

    local toast = UIComponents.CreateToast({
        Text = message,
        Color = UIStyles.Colors.SurfaceDark,
        Parent = mainHolder,
    })

    toast.AnimateIn()

    task.delay(3, function()
        if toast and toast.Parent then
            local out = toast.AnimateOut()
            out.Completed:Wait()
            toast:Destroy()
        end
    end)
end

-- ================================================================
-- Base Editor (Stub)
-- ================================================================

function UIController:ShowBaseEditor()
    self:ShowGameMessage("🏗️ Base Building — Coming in a future update!")
end

-- ================================================================
-- Cleanup
-- ================================================================

function UIController:KnitStop()
    -- Clean up all GUI instances
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "AbyssUI" or gui.Name == "ShopUI" or gui.Name == "CollectionUI" then
            gui:Destroy()
        end
    end

    cachedHUD = {}
    cachedScreens = {}
    cachedBars = {}
    activePopups = {}
    currentScreen = "HUD"
    screenStack = {}

    print("[UIController] UI cleaned up")
end

return UIController