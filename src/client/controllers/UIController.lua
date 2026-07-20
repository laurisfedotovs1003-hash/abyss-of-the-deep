--[[
    UIController — Complete UI implementation for Abyss of the Deep
    Manages HUD, Shop, Inventory screens with mobile-first deep-sea aesthetic.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local UIStyles = require(script.Parent.Parent.ui.UIStyles)
local UIComponents = require(script.Parent.Parent.ui.UIComponents)
local ShopScreen = require(script.Parent.Parent.ui.screens.ShopScreen)
local InventoryScreen = require(script.Parent.Parent.ui.screens.InventoryScreen)
local SettingsScreen = require(script.Parent.Parent.ui.screens.SettingsScreen)
local QuestScreen = require(script.Parent.Parent.ui.screens.QuestScreen)
local TutorialOverlay = require(script.Parent.Parent.ui.screens.TutorialOverlay)

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
local cachedTutorial = nil       -- Tutorial overlay instance

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

            -- Anomaly / Echo Event listeners
            local AnomalyService = Knit.GetService("AnomalyService")
            if AnomalyService then
                -- Warning — show countdown banner 10s before event
                AnomalyService.Client:Get("AnomalyWarning"):Connect(function(data)
                    self:ShowAnomalyWarning(data)
                end)

                -- Anomaly started — show active banner with lighting shift
                AnomalyService.Client:Get("AnomalyStarted"):Connect(function(data)
                    self:ShowAnomalyActive(data)
                end)

                -- Anomaly ended — clear banner, restore normal UI
                AnomalyService.Client:Get("AnomalyEnded"):Connect(function(data)
                    self:ShowAnomalyEnded(data)
                end)
            end
        end

    -- Quest service signals
    local QuestService = Knit.GetService("QuestService")
    if QuestService then
        QuestService.Client:Get("QuestProgressUpdated"):Connect(function(data)
            -- Optional: show subtle toast when progress changes
        end)

        QuestService.Client:Get("QuestCompleted"):Connect(function(data)
            if data and data.questName then
                self:ShowGameMessage("🎯 Quest Complete: " .. data.questName .. "!")
            end
        end)

        QuestService.Client:Get("DailyQuestRefresh"):Connect(function(data)
            self:ShowGameMessage("📅 Daily quests refreshed! Check your quests.")
        end)

        QuestService.Client:Get("EventQuestStarted"):Connect(function(data)
            if data and data.questName then
                self:ShowGameMessage("⚡ Event Quest: " .. data.questName .. " is now active!")
            end
        end)
    end

    -- Tutorial service signals
    local TutorialService = Knit.GetService("TutorialService")
    if TutorialService then
        TutorialService.Client:Get("TutorialStepStarted"):Connect(function(data)
            if data and data.step then
                self:ShowTutorialStep(data)
            end
        end)

        TutorialService.Client:Get("TutorialStepCompleted"):Connect(function(data)
            if data and data.step then
                self:ShowTutorialStepComplete(data)
            end
        end)

        TutorialService.Client:Get("TutorialCompleted"):Connect(function(data)
            self:ShowGameMessage("🎉 " .. (data and data.message or "Tutorial complete!"))
            if cachedTutorial and cachedTutorial.Hide then
                cachedTutorial.Hide()
            end
        end)
    end
end

-- ============================================================
-- SCREEN MANAGEMENT (with animated transitions)
-- ============================================================

function UIController:ShowScreen(screenName)
    if currentScreen == screenName then return end

    -- Animated transition effect
    local transition = UIComponents.CreateScreenTransition({
        Direction = "fade",
        Duration = 0.15,
        Parent = mainHolder,
    })
    transition.FadeIn()

    -- Hide all screens
    self:HideAllScreens()

    -- Show the requested screen
    if screenName == "HUD" then
        self:ShowHUD()
    elseif screenName == "Shop" then
        self:ShowShop()
    elseif screenName == "Collection" then
        self:ShowCollection()
    elseif screenName == "Settings" then
        self:ShowSettings()
    elseif screenName == "BaseEditor" then
        self:ShowBaseEditor()
    elseif screenName == "Quest" then
        self:ShowQuestScreen()
    end

    currentScreen = screenName

    -- End transition
    task.delay(0.1, function()
        transition.FadeOut(function()
            transition.Destroy()
        end)
    end)

    -- Audio hook for screen change
    local AudioController = Knit.GetController("AudioController")
    if AudioController then
        AudioController:PlayUIClick()
    end
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

    -- Settings button (gear icon at top-right)
    local settingsBtn = UIComponents.CreateIconButton({
        Name = "SettingsButton",
        Icon = "⚙",
        Color = UIStyles.Colors.TextMuted,
        StrokeColor = UIStyles.Colors.Border,
        Callback = function()
            self:PushScreen("Settings")
        end,
        Parent = hudContainer,
    })
    settingsBtn.Position = UDim2.new(1, -52, 0, 16)
    settingsBtn.Size = UDim2.fromOffset(36, 36)
    cachedHUD.settingsBtn = settingsBtn

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

    -- Scrap and Crystal are stored in the inventory
    local scrap = data.Scrap or 0
    local crystal = data.Crystal or 0
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

    -- Animate currency change with count-up effect
    local function AnimatedCurrencyUpdate(textLabel, newValue)
        if not textLabel then return end
        local currentText = textLabel.Text
        local currentNum = tonumber(currentText:gsub(",", "")) or 0
        if currentNum == newValue then return end

        -- Quick scale pulse on change
        local scaleTween = TweenService:Create(textLabel,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {TextTransparency = 0.3}
        )
        scaleTween:Play()
        scaleTween.Completed:Wait()
        
        textLabel.Text = formatNum(newValue)
        
        TweenService:Create(textLabel,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            {TextTransparency = 0}
        ):Play()
    end

    if cachedHUD.credits then
        AnimatedCurrencyUpdate(cachedHUD.credits, credits)
    end

    if cachedHUD.researchPoints then
        AnimatedCurrencyUpdate(cachedHUD.researchPoints, researchPoints)
    end

    if cachedHUD.scrap then
        AnimatedCurrencyUpdate(cachedHUD.scrap, scrap)
    end

    if cachedHUD.crystal then
        AnimatedCurrencyUpdate(cachedHUD.crystal, crystal)
    end

    -- Level-up detection: check if level changed from last known
    if cachedHUD._lastLevel and cachedHUD._lastLevel < level then
        -- Trigger level-up celebration
        local diffLevels = level - cachedHUD._lastLevel
        local xpPercent = xpNeeded > 0 and xp / xpNeeded or 0
        
        -- Build reward list from milestone data
        local rewards = {}
        for _, milestone in ipairs(Config.LevelMilestones or {}) do
            if milestone.level >= cachedHUD._lastLevel + 1 and milestone.level <= level then
                table.insert(rewards, {
                    icon = "🏆",
                    text = "Title: " .. milestone.title,
                    color = UIStyles.Colors.Gold,
                })
            end
        end
        -- Generic level-up rewards
        table.insert(rewards, {
            icon = "🪙",
            text = "Reward pending...",
            color = UIStyles.Colors.Cyan,
        })

        self:ShowLevelUp(level, xpPercent, xp, rewards)
    end
    cachedHUD._lastLevel = level
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
    if cachedScreens.Shop and cachedScreens.Shop.Enabled then
        cachedScreens.Shop.Enabled = true
        return
    end

    local container = CreateScreenContainer("ShopUI")
    container.DisplayOrder = 5
    cachedScreens.Shop = container

    -- Build the enhanced shop screen using ShopScreen module
    local shopAPI = ShopScreen.Create(container)

    -- Wire close button
    local closeBtn = UIComponents.CreateIconButton({
        Icon = "✕", Size = 36, Color = UIStyles.Colors.Elevated,
        StrokeColor = UIStyles.Colors.Border,
        Position = UDim2.new(1, -20, 0, 20), AnchorPoint = Vector2.new(1, 0),
        Callback = function() self:PopScreen() end,
        Parent = container,
    })

    -- Update currency on economy events
    local EconomyService = Knit.GetService("EconomyService")
    if EconomyService then
        EconomyService.Client:Get("EconomyUpdated"):Connect(function(data)
            if container and container.Parent and shopAPI.UpdateCurrency then
                shopAPI.UpdateCurrency(data.Credits or data.credits or 0, data.ResearchPoints or data.researchPoints or 0)
            end
        end)
    end

    -- Listen for anomaly state
    local AnomalyService = Knit.GetService("AnomalyService")
    if AnomalyService then
        AnomalyService.Client:Get("AnomalyStateChanged"):Connect(function(data)
            if container and container.Parent and shopAPI.SetAnomalyActive then
                shopAPI.SetAnomalyActive(data.active or false)
            end
        end)
    end
end

-- ================================================================
-- COLLECTION / INVENTORY SCREEN
-- ================================================================

function UIController:ShowCollection()
    if cachedScreens.Collection and cachedScreens.Collection.Enabled then
        cachedScreens.Collection.Enabled = true
        return
    end

    local container = CreateScreenContainer("CollectionUI")
    container.DisplayOrder = 5
    cachedScreens.Collection = container

    -- Build the enhanced inventory screen
    local invAPI = InventoryScreen.Create(container)

    -- Wire close button
    local closeBtn = UIComponents.CreateIconButton({
        Icon = "✕", Size = 36, Color = UIStyles.Colors.Elevated,
        StrokeColor = UIStyles.Colors.Border,
        Position = UDim2.new(1, -20, 0, 20), AnchorPoint = Vector2.new(1, 0),
        Callback = function() self:PopScreen() end,
        Parent = container,
    })

    -- _update handler for collection data from CollectionService
    container._update = function(data)
        if not data or not invAPI.UpdateProgress then return end
        invAPI.UpdateProgress(data.totalUnique or 0, data.totalPossible or 1)
        if data.isNewDiscovery then
            self:ShowGameMessage("🌟 New discovery added to collection!")
        end
    end

    -- Fetch initial collection data
    local CollectionService = Knit.GetService("CollectionService")
    if CollectionService and CollectionService.Client then
        local ok, result = pcall(function()
            return CollectionService.Client:Get("GetCollectionProgress"):Fire()
        end)
        if ok and result then
            invAPI.UpdateProgress(result.totalUnique or 0, result.totalPossible or 1)
        end
    end
end

-- ================================================================
-- SETTINGS SCREEN
-- ================================================================

function UIController:ShowSettings()
    if cachedScreens.Settings and cachedScreens.Settings.Enabled then
        cachedScreens.Settings.Enabled = true
        return
    end

    local container = CreateScreenContainer("SettingsUI")
    container.DisplayOrder = 10
    cachedScreens.Settings = container

    -- Build the settings screen
    local settingsAPI = SettingsScreen.Create(container)

    -- Wire close button
    local closeBtn = UIComponents.CreateIconButton({
        Icon = "✕", Size = 36, Color = UIStyles.Colors.Elevated,
        StrokeColor = UIStyles.Colors.Border,
        Position = UDim2.new(1, -20, 0, 20), AnchorPoint = Vector2.new(1, 0),
        Callback = function() self:PopScreen() end,
        Parent = container,
    })
end

-- ================================================================
-- QUEST SCREEN
-- ================================================================

function UIController:ShowQuestScreen()
    if cachedScreens.Quest and cachedScreens.Quest.Enabled then
        cachedScreens.Quest.Enabled = true
        return
    end

    local container = CreateScreenContainer("QuestUI")
    container.DisplayOrder = 5
    cachedScreens.Quest = container

    local questAPI = QuestScreen.Create(container)

    -- Close button
    local closeBtn = UIComponents.CreateIconButton({
        Icon = "✕", Size = 36, Color = UIStyles.Colors.Elevated,
        StrokeColor = UIStyles.Colors.Border,
        Position = UDim2.new(1, -20, 0, 20), AnchorPoint = Vector2.new(1, 0),
        Callback = function() self:PopScreen() end,
        Parent = container,
    })

    -- Fetch initial quest data
    local QuestService = Knit.GetService("QuestService")
    if QuestService and QuestService.Client then
        local ok, result = pcall(function()
            return QuestService.Client:Get("GetAvailableQuests"):Fire()
        end)
        if ok and result and result.reRollCooldown then
            questAPI.UpdateRefreshTimer(result.reRollCooldown)
        end
    end
end

-- ================================================================
-- TUTORIAL OVERLAY
-- ================================================================

function UIController:ShowTutorialStep(data)
    if not data then return end

    -- Initialize tutorial overlay on first call
    if not cachedTutorial then
        cachedTutorial = TutorialOverlay.Create(mainHolder)
        cachedTutorial.OnComplete(function()
            cachedTutorial = nil
            self:ShowGameMessage("🎉 Tutorial complete! The depths await!")
        end)
        cachedTutorial.OnSkip(function()
            cachedTutorial = nil
            self:ShowGameMessage("Tutorial skipped — you can always replay from settings.")
        end)
    end

    cachedTutorial.Show(data.step, data)
end

function UIController:ShowTutorialStepComplete(data)
    if not data or not cachedTutorial then return end

    cachedTutorial.ShowStepComplete(
        data.completionMessage,
        data.rewardType,
        data.rewardAmount
    )
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
        -- Play VFX effect for the catch
        local VFXController = Knit.GetController("VFXController")
        if VFXController and VFXController.PlayFishingCatchEffect then
            local playerChar = localPlayer.Character
            local rootPart = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
            local pos = rootPart and rootPart.Position or Vector3.new(0, 0, 0)
            VFXController:PlayFishingCatchEffect(pos, data.rarity or data.creature and data.creature.rarity, data.creature and data.creature.isShiny)
        end

        -- Audio hook
        local AudioController = Knit.GetController("AudioController")
        if AudioController then
            AudioController:PlaySFX("CreatureCaught")
        end

        -- Game message with creature name
        self:ShowGameMessage("🎉 Caught! " .. (data.name or data.creature and data.creature.displayName or "Creature") .. " — ★" .. tostring(data.sellPrice or 0))
    else
        -- Escape sound
        local AudioController = Knit.GetController("AudioController")
        if AudioController then
            AudioController:PlaySFX("CreatureEscape")
        end

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
-- ANOMALY / ECHO EVENT UI
-- ================================================================

local activeAnomalyBanner = nil

function UIController:ShowAnomalyWarning(data)
    if not data then return end
    
    -- Display warning banner: "⚠️ Corrupted Depths incoming in 10s!"
    local warningText = string.format("⚠️ %s incoming!", data.displayName or "Echo Event")
    self:ShowGameMessage(warningText)
    
    -- Create a pulsing warning banner at the top of the screen
    local container = CreateScreenContainer("AnomalyWarning")
    container.DisplayOrder = 20  -- Above other UI
    container.Name = "AnomalyWarning"
    
    local banner = New("Frame", {
        Name = "AnomalyWarningBanner",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 100, 0),
        BackgroundTransparency = 0.3,
        Parent = container,
    })
    
    local label = UIComponents.CreateTextLabel({
        Name = "WarningLabel",
        Text = warningText,
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 50),
        Color = Color3.fromRGB(255, 255, 255),
        Font = UIStyles.Fonts.Display,
        TextSize = 22,
        TextStrokeTransparency = 0.3,
        Parent = banner,
    })
    
    -- Animate banner sliding in
    banner.Size = UDim2.new(1, 0, 0, 0)
    banner:TweenSize(
        UDim2.new(1, 0, 0, 50),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        0.5,
        true
    )
    
    activeAnomalyBanner = container
    
    -- Auto-destroy warning when anomaly starts (replaced by active banner)
    task.delay(data.startsIn or 10, function()
        if container and container.Parent then
            container:Destroy()
        end
    end)
end

-- ================================================================
-- Level-Up Celebration Screen
-- ================================================================

function UIController:ShowLevelUp(level, xpPercent, xpRemaining, rewards)
    -- Play VFX level-up particles
    local VFXController = Knit.GetController("VFXController")
    if VFXController and VFXController.PlayLevelUpEffect then
        VFXController:PlayLevelUpEffect(level)
    end

    -- Play audio
    local AudioController = Knit.GetController("AudioController")
    if AudioController then
        AudioController:PlaySFX("LevelUp")
    end

    -- Show celebration UI
    local levelUpUI = UIComponents.CreateLevelUpScreen({
        Level = level,
        XPPercent = xpPercent,
        XPRemaining = xpRemaining,
        Rewards = rewards,
        Parent = mainHolder,
    })

    -- Store reference for cleanup
    activePopups.levelUp = levelUpUI
end

-- ================================================================
-- Anomaly Escalation UI
-- ================================================================

function UIController:ShowAnomalyActive(data)
    if not data then return end

    -- Clear warning banner if still visible
    if activeAnomalyBanner and activeAnomalyBanner.Parent then
        activeAnomalyBanner:Destroy()
        activeAnomalyBanner = nil
    end

    -- Show active anomaly banner
    local desc = data.description or ""
    local duration = data.duration or 60
    local endsAt = data.endsAt or (os.time() + duration)
    local startedAt = data.startedAt or os.time()
    local totalDuration = duration

    local container = CreateScreenContainer("AnomalyActive")
    container.DisplayOrder = 19
    container.Name = "AnomalyActive"

    -- Top banner with color based on anomaly priority
    local priorityColors = {
        [1] = Color3.fromRGB(180, 30, 30),    -- Corrupted: dark red
        [2] = Color3.fromRGB(200, 170, 50),   -- Enchanted: gold
        [3] = Color3.fromRGB(150, 0, 200),    -- Bloom: purple
        [4] = Color3.fromRGB(10, 10, 60),     -- Surge: dark blue
        [5] = Color3.fromRGB(0, 180, 220),    -- Migration: cyan
    }
    local bannerColor = priorityColors[data.priority] or Color3.fromRGB(100, 100, 100)

    local banner = New("Frame", {
        Name = "AnomalyActiveBanner",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = bannerColor,
        BackgroundTransparency = 0.2,
        Parent = container,
    })

    -- Event name
    local nameLabel = UIComponents.CreateTextLabel({
        Name = "AnomalyName",
        Text = "⚡ " .. (data.displayName or "Echo Event") .. " ⚡",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 28),
        Position = UDim2.fromOffset(0, 6),
        Color = Color3.fromRGB(255, 255, 255),
        Font = UIStyles.Fonts.Display,
        TextSize = 20,
        TextStrokeTransparency = 0.2,
        Parent = banner,
    })

    -- Duration timer with intensity escalation
    local timerLabel = UIComponents.CreateTextLabel({
        Name = "AnomalyTimer",
        Text = tostring(duration) .. "s remaining",
        Size = UDim2.fromScale(1, 0),
        Height = UDim.new(0, 20),
        Position = UDim2.fromOffset(0, 34),
        Color = Color3.fromRGB(200, 200, 200),
        Font = UIStyles.Fonts.Number,
        TextSize = 14,
        Parent = banner,
    })

    -- Animate in
    banner.Size = UDim2.new(1, 0, 0, 0)
    local inTween = banner:TweenSize(
        UDim2.new(1, 0, 0, 56),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        0.5,
        true
    )

    -- Update timer and intensity every second
    local heartbeat
    heartbeat = RunService.Heartbeat:Connect(function()
        if not container or not container.Parent then
            heartbeat:Disconnect()
            return
        end
        local remaining = math.max(0, endsAt - os.time())
        local elapsed = os.time() - startedAt
        local progress = totalDuration > 0 and math.min(elapsed / totalDuration, 1) or 0

        if timerLabel and timerLabel.Parent then
            timerLabel.Text = string.format("%ds remaining — %s", remaining, desc)
        end

        -- Escalate intensity: pulse the banner faster as anomaly progresses
        local intensity = 0.5 + progress * 0.5
        local pulseAlpha = 0.15 + math.sin(os.clock() * (2 + progress * 4)) * intensity * 0.1
        banner.BackgroundTransparency = pulseAlpha

        if remaining <= 0 and heartbeat then
            heartbeat:Disconnect()
        end
    end)

    activeAnomalyBanner = container

    -- Notify VFXController of anomaly intensity
    local VFXController = Knit.GetController("VFXController")
    if VFXController and VFXController.SetAnomalyIntensity then
        -- Update intensity every 2 seconds
        local intensityThread = task.spawn(function()
            while activeAnomalyBanner == container and container.Parent do
                local elapsed = os.time() - startedAt
                local progress = totalDuration > 0 and math.min(elapsed / totalDuration, 1) or 0
                VFXController:SetAnomalyIntensity(progress)
                task.wait(2)
            end
        end)
    end
end

function UIController:ShowAnomalyEnded(data)
    if not data then return end
    
    -- Clear active banner
    if activeAnomalyBanner and activeAnomalyBanner.Parent then
        activeAnomalyBanner:Destroy()
        activeAnomalyBanner = nil
    end
    
    -- Show end message
    self:ShowGameMessage(string.format("✅ %s has passed. The depths return to normal.", data.displayName or "Echo Event"))
end

-- ================================================================
-- Fishing & Harvest Event Handling
-- ================================================================

function UIController:HandleFishingEvent(eventName, data)
    if not eventName then return end

    if eventName == "FishingRodEquipped" then
        self:ShowGameMessage("🎣 Fishing Rod equipped — click to cast!")
        
    elseif eventName == "Casting" then
        self:ShowGameMessage("🎣 Casting line...")
        
    elseif eventName == "LineCast" then
        self:ShowGameMessage(string.format("🎣 Line cast in %s — waiting for a bite...", data and data.zoneName or "the depths"))
        
    elseif eventName == "FishBite" then
        self:ShowGameMessage("⚡ FISH ON! Click to reel in!")
        
    elseif eventName == "Reeling" then
        self:ShowGameMessage("🎣 Reeling in...")
        
    elseif eventName == "FishingEnded" then
        -- Result already shown via GameMessage
        
    elseif eventName == "HarvestToolEquipped" then
        self:ShowGameMessage("🔧 Harvest Tool equipped — aim at resources and click")
        
    elseif eventName == "Harvesting" then
        self:ShowGameMessage("🪨 Harvesting " .. (data and data.type or "resources") .. "...")
        
    elseif eventName == "GameMessage" and data then
        self:ShowGameMessage(data.Text or "")
        
    elseif eventName == "DiveStarted" then
        self:ShowGameMessage("🌊 Diving beneath the surface...")
        
    elseif eventName == "DiveEnded" then
        self:ShowGameMessage("🌊 Returned to the surface")
        
    elseif eventName == "CriticalOxygen" then
        self:ShowGameMessage("⚠️ CRITICAL OXYGEN — Surface immediately!")
    end
end

-- ================================================================
-- Cleanup
-- ================================================================

function UIController:KnitStop()
    -- Clean up anomaly banners
    if activeAnomalyBanner and activeAnomalyBanner.Parent then
        activeAnomalyBanner:Destroy()
        activeAnomalyBanner = nil
    end

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