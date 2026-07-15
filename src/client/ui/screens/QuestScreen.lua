--[[
    QuestScreen.lua — Quest panel for Abyss of the Deep
    4 tabs: Daily | Milestone | Event | Achievement
    Progress bars, claim buttons, rewards display, daily refresh timer, re-roll.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local QuestScreen = {}
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
-- Sample quest data (in production, comes from QuestService signals)
-- ============================================================

local TAB_NAMES = { "Daily", "Milestone", "Event", "Achievement" }
local TAB_ICONS = { "📅", "🏆", "⚡", "🎖️" }

-- ============================================================
-- CREATE: Quest Panel Screen
-- ============================================================

function QuestScreen.Create(parent)
    -- Dimmer
    local dimmer = New("Frame", {
        Name = "QuestDimmer", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6,
        Parent = parent,
    })

    -- Panel
    local panel = New("Frame", {
        Name = "QuestPanel",
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark, BackgroundTransparency = 0.05,
        ClipsDescendants = true, Parent = parent,
    })
    NewCorner(20).Parent = panel
    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = panel

    New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 12), Parent = panel })

    -- Header
    local header = New("Frame", { Name = "QuestHeader", Size = UDim2.fromScale(1, 0), Height = UDim.new(0, 44), BackgroundTransparency = 1, Parent = panel })

    local titleLabel = UIComponents.CreateTextLabel({
        Text = "📋 QUESTS", Size = UDim2.fromOffset(160, 28), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.SectionTitle, Parent = header,
    })

    -- Daily refresh timer
    local refreshTimer = UIComponents.CreateTextLabel({
        Name = "RefreshTimer", Text = "", Size = UDim2.fromOffset(140, 20), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        Color = UIStyles.Colors.TextMuted, TextSize = UIStyles.FontSizes.Tiny, TextXAlignment = Enum.TextXAlignment.Right, Parent = header,
    })

    -- Tab bar
    local tabFrame = New("Frame", { Name = "QuestTabs", Size = UDim2.fromScale(1, 0), Height = UDim.new(0, 42), Position = UDim2.fromOffset(0, 48), BackgroundTransparency = 1, Parent = panel })
    local selectedTab = 1

    local function BuildTabs()
        for _, child in ipairs(tabFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        for i, name in ipairs(TAB_NAMES) do
            local isSelected = i == selectedTab
            local tab = UIComponents.CreateButton({
                Name = "Tab_" .. name, Text = (TAB_ICONS[i] or "") .. " " .. name,
                Size = UDim2.fromOffset(0, 36), Position = UDim2.fromOffset((i - 1) * 85, 3),
                Color = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.SurfaceDark,
                Transparency = isSelected and 0.8 or 0.5,
                TextColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.TextMuted,
                FontSize = UIStyles.FontSizes.Small, CornerRadius = 8, Stroke = true,
                StrokeColor = isSelected and UIStyles.Colors.Cyan or UIStyles.Colors.Border,
                Callback = function() selectedTab = i; BuildTabs(); RefreshQuests() end,
                Parent = tabFrame,
            })
            tab.Size = UDim2.fromOffset(80, 36)
        end
    end

    -- Quest list area
    local questFrame = New("Frame", { Name = "QuestList", Size = UDim2.new(1, 0, 1, -100), Position = UDim2.fromOffset(0, 96), BackgroundTransparency = 1, Parent = panel })
    local scroll = New("ScrollingFrame", {
        Name = "QuestScroll", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ScrollBarThickness = 4, ScrollBarImageColor3 = UIStyles.Colors.Cyan,
        ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromScale(1, 3), Parent = questFrame,
    })

    -- ============================================================
    -- Sample quest data per tab
    -- ============================================================
    local SAMPLE_QUESTS = {
        Daily = {
            { name = "Ocean Sweep", desc = "Catch 5 creatures", progress = 3, target = 5, rewards = "🪙 50 + ◎ 5", completed = false, claimed = false },
            { name = "Deep Diver", desc = "Reach 500m depth", progress = 320, target = 500, rewards = "🪙 80 + ◎ 10", completed = false, claimed = false },
            { name = "Scrap Collector", desc = "Collect 20 scrap", progress = 20, target = 20, rewards = "🪙 100 + 🔩 x5", completed = true, claimed = false },
        },
        Milestone = {
            { name = "First 1,000m", desc = "Reach the Midnight Zone", progress = 1, target = 1, rewards = "🪙 200 + ◎ 25", completed = true, claimed = false },
            { name = "Creature Collector", desc = "Catch 10 unique species", progress = 7, target = 10, rewards = "🪙 150 + ◎ 15", completed = false, claimed = false },
            { name = "Treasure Hunter", desc = "Collect 5 rare items", progress = 3, target = 5, rewards = "🪙 300 + 💎 x3", completed = false, claimed = false },
        },
        Event = {
            { name = "Abyssal Storm", desc = "Catch 3 creatures during anomaly", progress = 1, target = 3, rewards = "🪙 200 + ◎ 30", completed = false, claimed = false, anomaly = true },
            { name = "Void Walker", desc = "Dive 500m during anomaly", progress = 200, target = 500, rewards = "🪙 250 + 🛡️ x1", completed = false, claimed = false, anomaly = true },
        },
        Achievement = {
            { name = "Legendary Catch", desc = "Catch a legendary creature", progress = 1, target = 1, rewards = "🏆 + 🪙 500 + ◎ 50", completed = true, claimed = false },
            { name = "Full Collection", desc = "Complete 50% of the bestiary", progress = 40, target = 50, rewards = "🏆 + 🪙 300 + ⭐ Title", completed = false, claimed = false, isPercent = true },
            { name = "Deepest Explorer", desc = "Reach 6,000m depth", progress = 2400, target = 6000, rewards = "🏆 + 🪙 1000", completed = false, claimed = false },
        },
    }

    -- ============================================================
    -- Refresh Quests
    -- ============================================================
    local function RefreshQuests()
        for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

        local tabName = TAB_NAMES[selectedTab] or "Daily"
        local quests = SAMPLE_QUESTS[tabName] or {}

        if #quests == 0 then
            local emptyLabel = UIComponents.CreateTextLabel({
                Text = "No quests available in this category",
                Size = UDim2.fromOffset(300, 40), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5),
                Color = UIStyles.Colors.TextMuted, TextSize = UIStyles.FontSizes.Body, TextXAlignment = Enum.TextXAlignment.Center, Parent = scroll,
            })
            scroll.CanvasSize = UDim2.fromOffset(0, 100)
            return
        end

        -- Re-roll button for Daily tab
        if selectedTab == 1 then
            local reRollFrame = New("Frame", {
                Name = "ReRollFrame", Size = UDim2.new(1, -8, 0, 36), Position = UDim2.fromOffset(0, 4),
                BackgroundTransparency = 1, Parent = scroll,
            })

            local reRollBtn = UIComponents.CreateButton({
                Name = "ReRollBtn", Text = "🔄 Re-Roll Daily (1 left)",
                Size = UDim2.fromOffset(180, 32), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                Color = UIStyles.Colors.DeepPurple, Transparency = 0.3, TextColor = UIStyles.Colors.TextPrimary,
                FontSize = UIStyles.FontSizes.Small, CornerRadius = 8, Stroke = true, StrokeColor = UIStyles.Colors.DeepPurple,
                Callback = function() print("[Quest] Re-Roll clicked") end,
                Parent = reRollFrame,
            })

            -- Cooldown display
            local cooldownLabel = UIComponents.CreateTextLabel({
                Name = "Cooldown", Text = "Cooldown: Ready",
                Size = UDim2.fromOffset(120, 20), Position = UDim2.new(1, -4, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                Color = UIStyles.Colors.BioGreen, TextSize = UIStyles.FontSizes.Tiny, TextXAlignment = Enum.TextXAlignment.Right, Parent = reRollFrame,
            })
        end

        for i, quest in ipairs(quests) do
            local yOffset = (selectedTab == 1 and 48 or 4) + (i - 1) * 90

            local card = New("Frame", {
                Name = "Quest_" .. quest.name,
                Size = UDim2.new(1, -8, 0, 82), Position = UDim2.fromOffset(0, yOffset),
                BackgroundColor3 = UIStyles.Colors.Elevated, BackgroundTransparency = 0.15,
                ClipsDescendants = true, Parent = scroll,
            })
            NewCorner(12).Parent = card

            if quest.anomaly then
                NewStroke(UIStyles.Colors.Danger, 0.4, 2).Parent = card
            elseif quest.completed then
                NewStroke(UIStyles.Colors.Success, 0.4, 2).Parent = card
            else
                NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = card
            end

            -- Quest name
            local nameLabel = UIComponents.CreateTextLabel({
                Name = "Name", Text = quest.name, Size = UDim2.fromOffset(220, 20), Position = UDim2.fromOffset(12, 8),
                Color = quest.completed and UIStyles.Colors.Success or UIStyles.Colors.TextPrimary,
                Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.Small, Parent = card,
            })

            -- Anomaly badge
            if quest.anomaly then
                local badge = New("Frame", { Size = UDim2.fromOffset(60, 16), Position = UDim2.new(1, -72, 0, 8), BackgroundColor3 = UIStyles.Colors.Danger, BackgroundTransparency = 0.3, Parent = card })
                NewCorner(4).Parent = badge
                local badgeLabel = UIComponents.CreateTextLabel({ Text = "⚠ EVENT", Size = UDim2.fromScale(1, 1), Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })
            end

            -- Description
            local descLabel = UIComponents.CreateTextLabel({
                Name = "Desc", Text = quest.desc, Size = UDim2.fromOffset(220, 16), Position = UDim2.fromOffset(12, 30),
                Color = UIStyles.Colors.TextSecondary, TextSize = UIStyles.FontSizes.Tiny, Parent = card,
            })

            -- Progress bar
            local progressBar = New("Frame", {
                Name = "ProgressBar", Size = UDim2.new(0.6, -20, 0, 8), Position = UDim2.fromOffset(12, 50),
                BackgroundColor3 = UIStyles.Colors.SurfaceDark, ClipsDescendants = true, Parent = card,
            })
            NewCorner(4).Parent = progressBar

            local pct = quest.target > 0 and math.min(quest.progress / quest.target, 1) or 0
            local fill = New("Frame", {
                Size = UDim2.fromScale(pct, 1), BackgroundColor3 = quest.completed and UIStyles.Colors.Success or UIStyles.Colors.Cyan,
                ClipsDescendants = true, Parent = progressBar,
            })
            NewCorner(4).Parent = fill

            local progressLabel = UIComponents.CreateTextLabel({
                Name = "Progress", Text = tostring(quest.progress) .. "/" .. tostring(quest.target),
                Size = UDim2.fromOffset(80, 16), Position = UDim2.new(0.6, -8, 0, 48),
                Color = UIStyles.Colors.TextMuted, TextSize = UIStyles.FontSizes.Tiny, Parent = card,
            })

            -- Rewards
            local rewardLabel = UIComponents.CreateTextLabel({
                Name = "Rewards", Text = "Rewards: " .. (quest.rewards or ""),
                Size = UDim2.fromOffset(220, 16), Position = UDim2.fromOffset(12, 62),
                Color = UIStyles.Colors.Gold, TextSize = UIStyles.FontSizes.Tiny, Parent = card,
            })

            -- Claim button
            if quest.completed and not quest.claimed then
                local claimBtn = UIComponents.CreateButton({
                    Name = "ClaimBtn", Text = "CLAIM",
                    Size = UDim2.fromOffset(80, 34), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                    Color = UIStyles.Colors.Cyan, Transparency = 0.15, TextColor = UIStyles.Colors.TextOnAccent,
                    FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 8,
                    Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
                    Callback = function() print("[Quest] Claiming:", quest.name); claimBtn:Destroy() end,
                    Parent = card,
                })
            elseif quest.completed and quest.claimed then
                local claimedLabel = UIComponents.CreateTextLabel({
                    Text = "✓ CLAIMED", Size = UDim2.fromOffset(80, 20), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                    Color = UIStyles.Colors.TextMuted, TextSize = UIStyles.FontSizes.Tiny, TextXAlignment = Enum.TextXAlignment.Center, Parent = card,
                })
            end
        end

        scroll.CanvasSize = UDim2.fromOffset(0, (#quests * 90) + (selectedTab == 1 and 48 or 0) + 12)
    end

    -- Build initial
    BuildTabs()
    RefreshQuests()

    -- Return API
    local api = {}

    api.UpdateRefreshTimer = function(seconds)
        if seconds and seconds > 0 then
            local mins = math.floor(seconds / 60)
            local secs = seconds % 60
            refreshTimer.Text = "Refreshes in " .. string.format("%02d:%02d", mins, secs)
        else
            refreshTimer.Text = ""
        end
    end

    api.Refresh = RefreshQuests
    api.Close = function() parent:Destroy() end

    return api
end

return QuestScreen