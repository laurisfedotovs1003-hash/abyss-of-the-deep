--[[
    SocialScreen.lua — Social hub for Abyss of the Deep
    Tabs: Friends | Co-op Party | Leaderboards | Titles
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local SocialScreen = {}
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

local TAB_NAMES = { "Friends", "Co-op", "Leaderboard", "Titles" }
local TAB_ICONS = { "👥", "🤝", "🏆", "⭐" }

-- ============================================================
-- Sample Data
-- ============================================================

local SAMPLE_FRIENDS = {
    { name = "DeepExplorer_42", online = true,   depth = 2450, creatures = 28, mutual = true  },
    { name = "CoralKing",      online = true,   depth = 1200, creatures = 15, mutual = true  },
    { name = "AbyssalQueen",   online = false,  depth = 5800, creatures = 42, mutual = true  },
    { name = "ReefRunner99",   online = true,   depth = 800,  creatures = 10, mutual = true  },
    { name = "VoidWalker_X",   online = false,  depth = 8900, creatures = 55, mutual = false },
}

local SAMPLE_PARTY = {
    members = {
        { name = "You", isLeader = true, oxygen = 85, depth = 1240 },
        { name = "DeepExplorer_42", isLeader = false, oxygen = 72, depth = 1200 },
    },
    sharedOxygen = 157,
    sharedOxygenMax = 200,
}

local SAMPLE_LEADERBOARD = {
    { rank = 1,  name = "VoidWalker_X",    value = 8900,  title = "Abyssal Lord",     reward = "🏆 5000 Credits" },
    { rank = 2,  name = "AbyssalQueen",    value = 5800,  title = "Deep Explorer",    reward = "🏆 3000 Credits" },
    { rank = 3,  name = "OceanMaster",     value = 5100,  title = "Marine Sage",      reward = "🏆 1500 Credits" },
    { rank = 4,  name = "ShadowDiver",     value = 4200,  title = "Twilight Walker" },
    { rank = 5,  name = "ReefLord",        value = 3800,  title = "Coral Guardian" },
    { rank = 6,  name = "DeepExplorer_42", value = 2450,  title = "Kelpie Hunter" },
    { rank = 7,  name = "CurrentRider",    value = 2200,  title = "" },
    { rank = 8,  name = "CoralKing",       value = 1200,  title = "" },
    { rank = 9,  name = "ReefRunner99",    value = 800,   title = "" },
    { rank = 10, name = "DiveNewbie_001",  value = 420,   title = "" },
}

local SAMPLE_TITLES = {
    { name = "Abyssal Explorer",  rarity = "Legendary", unlocked = true,  equipped = true,  requirement = "Reach 8000m depth" },
    { name = "Deep Diver",        rarity = "Rare",      unlocked = true,  equipped = false, requirement = "Reach 1000m depth" },
    { name = "Creature Hunter",   rarity = "Uncommon",  unlocked = true,  equipped = false, requirement = "Catch 20 creatures" },
    { name = "Legendary Catcher", rarity = "Legendary", unlocked = false, equipped = false, requirement = "Catch 3 legendary" },
    { name = "Anomaly Survivor",  rarity = "Epic",      unlocked = true,  equipped = false, requirement = "Survive 10 anomalies" },
    { name = "Base Builder",      rarity = "Uncommon",  unlocked = true,  equipped = false, requirement = "Build 5 modules" },
    { name = "Treasure Hoarder",  rarity = "Epic",      unlocked = false, equipped = false, requirement = "Collect 100k credits" },
    { name = "Co-op Champion",    rarity = "Rare",      unlocked = false, equipped = false, requirement = "Complete 10 co-op dives" },
}

local LEADERBOARD_CATS = { "Deepest Dive", "Most Credits", "Most Creatures", "Largest Collection", "Most Boss Kills" }

-- ============================================================
-- CREATE
-- ============================================================

function SocialScreen.Create(parent)
    local dimmer = New("Frame", {
        Name = "SocialDimmer", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, Parent = parent,
    })

    local panel = New("Frame", {
        Name = "SocialPanel", Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark, BackgroundTransparency = 0.05,
        ClipsDescendants = true, Parent = parent,
    })
    NewCorner(20).Parent = panel
    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = panel
    New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 12), Parent = panel })

    -- Header
    local header = New("Frame", { Name = "SocialHeader", Size = UDim2.fromScale(1, 0), Height = UDim.new(0, 44), BackgroundTransparency = 1, Parent = panel })
    local titleLabel = UIComponents.CreateTextLabel({
        Text = "👥 SOCIAL", Size = UDim2.fromOffset(160, 28), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.SectionTitle, Parent = header,
    })

    -- Tab bar
    local tabFrame = New("Frame", { Name = "SocialTabs", Size = UDim2.fromScale(1, 0), Height = UDim.new(0, 42), Position = UDim2.fromOffset(0, 48), BackgroundTransparency = 1, Parent = panel })
    local selectedTab = 1
    local tabCounts = { #SAMPLE_FRIENDS, #(SAMPLE_PARTY.members), #SAMPLE_LEADERBOARD, #SAMPLE_TITLES }

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
                Callback = function() selectedTab = i; BuildTabs(); RefreshContent() end,
                Parent = tabFrame,
            })
            tab.Size = UDim2.fromOffset(82, 36)
        end
    end

    -- Content
    local contentFrame = New("Frame", { Name = "SocialContent", Size = UDim2.new(1, 0, 1, -100), Position = UDim2.fromOffset(0, 96), BackgroundTransparency = 1, Parent = panel })
    local scroll = New("ScrollingFrame", {
        Name = "SocialScroll", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ScrollBarThickness = 4, ScrollBarImageColor3 = UIStyles.Colors.Cyan,
        ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromScale(1, 3), Parent = contentFrame,
    })

    local function RefreshContent()
        for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

        if selectedTab == 1 then
            -- ======================================== FRIENDS TAB ========================================
            -- Friend bonus banner
            local bonusBanner = New("Frame", {
                Name = "FriendBonus", Size = UDim2.new(1, -8, 0, 36), Position = UDim2.fromOffset(0, 4),
                BackgroundColor3 = UIStyles.Colors.BioGreen, BackgroundTransparency = 0.15, Parent = scroll,
            })
            NewCorner(8).Parent = bonusBanner
            local bonusText = UIComponents.CreateTextLabel({
                Text = "🤝 Friend Bonus: +10% XP & Credits when diving together!", Size = UDim2.fromScale(1, 1),
                Color = UIStyles.Colors.BioGreen, TextSize = UIStyles.FontSizes.Tiny, TextXAlignment = Enum.TextXAlignment.Center, Parent = bonusBanner,
            })

            for i, friend in ipairs(SAMPLE_FRIENDS) do
                local yOff = 48 + (i - 1) * 80
                local card = New("Frame", {
                    Name = "Friend_" .. friend.name, Size = UDim2.new(1, -8, 0, 72), Position = UDim2.fromOffset(0, yOff),
                    BackgroundColor3 = UIStyles.Colors.Elevated, BackgroundTransparency = 0.15, ClipsDescendants = true, Parent = scroll,
                })
                NewCorner(12).Parent = card
                NewStroke(friend.online and UIStyles.Colors.Success or UIStyles.Colors.TextMuted, 0.5, friend.online and 2 or 1).Parent = card

                -- Status dot
                local dotColor = friend.online and UIStyles.Colors.Success or UIStyles.Colors.TextMuted
                local dot = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(12, 14), BackgroundColor3 = dotColor, Parent = card })
                NewCorner(5).Parent = dot
                if friend.online then
                    local dotGlow = New("ImageLabel", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://5025537645", ImageColor3 = UIStyles.Colors.Success, ImageTransparency = 0.5, Parent = dot })
                end

                -- Name + status
                local nameLabel = UIComponents.CreateTextLabel({ Text = friend.name, Size = UDim2.fromOffset(180, 20), Position = UDim2.fromOffset(30, 10), Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.Small, Parent = card })
                local statusLabel = UIComponents.CreateTextLabel({ Text = friend.online and "🟢 Online" or "⚫ Offline — Last seen 2h ago", Size = UDim2.fromOffset(200, 16), Position = UDim2.fromOffset(30, 30), Color = friend.online and UIStyles.Colors.Success or UIStyles.Colors.TextMuted, TextSize = UIStyles.FontSizes.Tiny, Parent = card })
                local statsLabel = UIComponents.CreateTextLabel({ Text = "Depth: " .. tostring(friend.depth) .. "m · " .. tostring(friend.creatures) .. " creatures", Size = UDim2.fromOffset(200, 14), Position = UDim2.fromOffset(30, 48), Color = UIStyles.Colors.TextMuted, TextSize = 9, Parent = card })

                -- Invite button
                if friend.online then
                    local inviteBtn = UIComponents.CreateButton({
                        Name = "Invite", Text = "🤝 INVITE", Size = UDim2.fromOffset(90, 34),
                        Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                        Color = UIStyles.Colors.Cyan, Transparency = 0.15, TextColor = UIStyles.Colors.TextPrimary,
                        FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 8,
                        Callback = function() print("[Social] Invited:", friend.name) end,
                        Parent = card,
                    })

                    -- Gift button
                    local giftBtn = UIComponents.CreateButton({
                        Name = "Gift", Text = "🎁", Size = UDim2.fromOffset(40, 34),
                        Position = UDim2.new(1, -108, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                        Color = UIStyles.Colors.Gold, Transparency = 0.3, TextColor = UIStyles.Colors.TextPrimary,
                        FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 8,
                        Callback = function() print("[Social] Gifting to:", friend.name) end,
                        Parent = card,
                    })
                end
            end

            scroll.CanvasSize = UDim2.fromOffset(0, 48 + #SAMPLE_FRIENDS * 80 + 12)

        elseif selectedTab == 2 then
            -- ======================================== CO-OP TAB ========================================
            -- Party header
            local partyHeader = New("Frame", {
                Name = "PartyHeader", Size = UDim2.new(1, -8, 0, 60), Position = UDim2.fromOffset(0, 4),
                BackgroundColor3 = UIStyles.Colors.DeepPurple, BackgroundTransparency = 0.2, Parent = scroll,
            })
            NewCorner(10).Parent = partyHeader
            local partyTitle = UIComponents.CreateTextLabel({
                Text = "🤝 CO-OP PARTY (" .. tostring(#SAMPLE_PARTY.members) .. "/4)", Size = UDim2.fromOffset(240, 24), Position = UDim2.fromOffset(12, 6),
                Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.ItemName, Parent = partyHeader,
            })

            -- Shared oxygen
            local oxyText = UIComponents.CreateTextLabel({
                Text = "🫧 Shared O₂: " .. tostring(SAMPLE_PARTY.sharedOxygen) .. "/" .. tostring(SAMPLE_PARTY.sharedOxygenMax),
                Size = UDim2.fromOffset(240, 16), Position = UDim2.fromOffset(12, 32),
                Color = UIStyles.Colors.Cyan, TextSize = UIStyles.FontSizes.Tiny, Parent = partyHeader,
            })
            local oxyBar = New("Frame", { Size = UDim2.fromOffset(120, 6), Position = UDim2.fromOffset(12, 50), BackgroundColor3 = UIStyles.Colors.SurfaceDark, ClipsDescendants = true, Parent = partyHeader })
            NewCorner(3).Parent = oxyBar
            local oxyFill = New("Frame", { Size = UDim2.fromScale(SAMPLE_PARTY.sharedOxygen / SAMPLE_PARTY.sharedOxygenMax, 1), BackgroundColor3 = UIStyles.Colors.Cyan, ClipsDescendants = true, Parent = oxyBar })
            NewCorner(3).Parent = oxyFill

            -- Invite code
            local inviteCode = New("Frame", { Name = "InviteCode", Size = UDim2.new(1, -8, 0, 36), Position = UDim2.fromOffset(0, 72), BackgroundColor3 = UIStyles.Colors.Elevated, BackgroundTransparency = 0.2, Parent = scroll })
            NewCorner(8).Parent = inviteCode
            local codeLabel = UIComponents.CreateTextLabel({ Text = "📋 Invite Code: A3X9-K2", Size = UDim2.fromOffset(180, 36), Position = UDim2.fromOffset(12, 0), Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Mono, TextSize = UIStyles.FontSizes.Small, Parent = inviteCode })
            local copyBtn = UIComponents.CreateButton({ Name = "Copy", Text = "COPY", Size = UDim2.fromOffset(60, 28), Position = UDim2.new(1, -8, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Color = UIStyles.Colors.Cyan, Transparency = 0.2, TextColor = UIStyles.Colors.TextPrimary, FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 6, Parent = inviteCode })

            -- Party members
            for i, member in ipairs(SAMPLE_PARTY.members) do
                local yOff = 116 + (i - 1) * 64
                local mCard = New("Frame", { Name = "Member_" .. member.name, Size = UDim2.new(1, -8, 0, 56), Position = UDim2.fromOffset(0, yOff), BackgroundColor3 = UIStyles.Colors.Elevated, BackgroundTransparency = 0.15, ClipsDescendants = true, Parent = scroll })
                NewCorner(10).Parent = mCard
                if member.isLeader then NewStroke(UIStyles.Colors.Gold, 0.4, 2).Parent = mCard else NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = mCard end

                local leaderBadge = member.isLeader and "👑 " or ""
                UIComponents.CreateTextLabel({ Text = leaderBadge .. member.name, Size = UDim2.fromOffset(180, 20), Position = UDim2.fromOffset(12, 8), Color = member.isLeader and UIStyles.Colors.Gold or UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.Small, Parent = mCard })
                UIComponents.CreateTextLabel({ Text = "🫧 O₂: " .. tostring(member.oxygen) .. "% · Depth: " .. tostring(member.depth) .. "m", Size = UDim2.fromOffset(200, 14), Position = UDim2.fromOffset(12, 30), Color = UIStyles.Colors.TextMuted, TextSize = 9, Parent = mCard })

                if not member.isLeader and member.name ~= "You" then
                    local kickBtn = UIComponents.CreateButton({ Name = "Kick", Text = "✕", Size = UDim2.fromOffset(36, 30), Position = UDim2.new(1, -8, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Color = UIStyles.Colors.Danger, Transparency = 0.4, TextColor = UIStyles.Colors.TextPrimary, FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 6, Parent = mCard })
                end
            end

            -- Start / Leave co-op buttons
            local coOpBtns = New("Frame", { Name = "CoOpBtns", Size = UDim2.new(1, -8, 0, 40), Position = UDim2.fromOffset(0, 116 + #SAMPLE_PARTY.members * 64 + 8), BackgroundTransparency = 1, Parent = scroll })
            local startDiveBtn = UIComponents.CreateButton({ Name = "StartCoop", Text = "🌊 START CO-OP DIVE", Size = UDim2.fromOffset(220, 38), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = UIStyles.Colors.Cyan, Transparency = 0.15, TextColor = UIStyles.Colors.TextPrimary, FontSize = UIStyles.FontSizes.Small, CornerRadius = 10, Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue}, Parent = coOpBtns })

            scroll.CanvasSize = UDim2.fromOffset(0, 116 + #SAMPLE_PARTY.members * 64 + 80 + 20)

        elseif selectedTab == 3 then
            -- ======================================== LEADERBOARD TAB ========================================
            -- Category selector
            local catFrame = New("Frame", { Name = "CatSelector", Size = UDim2.new(1, -8, 0, 36), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Parent = scroll })
            for i, cat in ipairs(LEADERBOARD_CATS) do
                local catBtn = UIComponents.CreateButton({
                    Name = "Cat_" .. cat, Text = cat, Size = UDim2.fromOffset(72, 30), Position = UDim2.fromOffset((i - 1) * 78, 3),
                    Color = i == 1 and UIStyles.Colors.Cyan or UIStyles.Colors.SurfaceDark, Transparency = i == 1 and 0.8 or 0.5,
                    TextColor = i == 1 and UIStyles.Colors.Cyan or UIStyles.Colors.TextMuted,
                    FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 6, Stroke = true,
                    StrokeColor = i == 1 and UIStyles.Colors.Cyan or UIStyles.Colors.Border,
                    Callback = function() print("[Social] Leaderboard:", cat) end,
                    Parent = catFrame,
                })
            end

            -- Podium for top 3
            local podium = New("Frame", { Name = "Podium", Size = UDim2.new(1, -8, 0, 100), Position = UDim2.fromOffset(0, 48), BackgroundTransparency = 1, Parent = scroll })
            local top3 = { SAMPLE_LEADERBOARD[1], SAMPLE_LEADERBOARD[2], SAMPLE_LEADERBOARD[3] }
            local podiumPositions = {
                { x = 0.5, medal = "🥇", color = UIStyles.Colors.Gold, size = 48 },
                { x = 0.2, medal = "🥈", color = "#C0C0C0", size = 40 },
                { x = 0.8, medal = "🥉", color = "#CD7F32", size = 36 },
            }
            for i, pos in ipairs(podiumPositions) do
                local entry = top3[i]
                local podiumItem = New("Frame", { Name = "Podium" .. i, Size = UDim2.fromOffset(pos.size, pos.size), Position = UDim2.fromScale(pos.x, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UIStyles.Colors.Elevated, BackgroundTransparency = 0.2, ClipsDescendants = true, Parent = podium })
                NewCorner(12).Parent = podiumItem
                UIComponents.CreateTextLabel({ Text = pos.medal, Size = UDim2.fromOffset(pos.size, pos.size), Color = UIStyles.Colors.TextPrimary, TextSize = pos.size * 0.5, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = podiumItem })
                if entry then
                    UIComponents.CreateTextLabel({ Text = entry.name, Size = UDim2.fromOffset(80, 16), Position = UDim2.fromScale(0.5, 1), AnchorPoint = Vector2.new(0.5, 0), Color = UIStyles.Colors.TextPrimary, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center, Parent = podiumItem })
                    UIComponents.CreateTextLabel({ Text = tostring(entry.value) .. "m", Size = UDim2.fromOffset(60, 14), Position = UDim2.fromScale(0.5, 1), AnchorPoint = Vector2.new(0.5, 0), Color = pos.color, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, Font = UIStyles.Fonts.Display, Parent = podiumItem })
                    UIComponents.CreateTextLabel({ Text = entry.reward or "", Size = UDim2.fromOffset(120, 12), Position = UDim2.fromScale(0.5, 1), AnchorPoint = Vector2.new(0.5, 0), Color = UIStyles.Colors.Gold, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Center, Parent = podiumItem })
                    local rewardY = pos.size * 0.5 + 44
                end
            end

            -- Rank list
            for i, entry in ipairs(SAMPLE_LEADERBOARD) do
                local isPlayer = entry.name == "You"
                local yOff = 156 + (i - 1) * 48
                local row = New("Frame", { Name = "Rank_" .. i, Size = UDim2.new(1, -8, 0, 42), Position = UDim2.fromOffset(0, yOff), BackgroundColor3 = isPlayer and UIStyles.Colors.CardBG or UIStyles.Colors.Elevated, BackgroundTransparency = isPlayer and 0.3 or 0.15, ClipsDescendants = true, Parent = scroll })
                NewCorner(8).Parent = row
                if isPlayer then NewStroke(UIStyles.Colors.Cyan, 0.5, 2).Parent = row end

                local rankColor = UIStyles.Colors.TextSecondary
                if i == 1 then rankColor = UIStyles.Colors.Gold
                elseif i == 2 then rankColor = Color3.fromRGB(192, 192, 192)
                elseif i == 3 then rankColor = Color3.fromRGB(205, 127, 50) end

                UIComponents.CreateTextLabel({ Text = "#" .. tostring(entry.rank), Size = UDim2.fromOffset(32, 42), Color = rankColor, Font = UIStyles.Fonts.Number, TextSize = UIStyles.FontSizes.HUDSmall, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
                UIComponents.CreateTextLabel({ Text = entry.name, Size = UDim2.fromOffset(140, 20), Position = UDim2.fromOffset(36, 4), Color = isPlayer and UIStyles.Colors.Cyan or UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.Small, Parent = row })
                if entry.title and entry.title ~= "" then
                    UIComponents.CreateTextLabel({ Text = "⭐ " .. entry.title, Size = UDim2.fromOffset(120, 14), Position = UDim2.fromOffset(36, 24), Color = UIStyles.Colors.Gold, TextSize = 8, Parent = row })
                end
                UIComponents.CreateTextLabel({ Text = tostring(entry.value) .. "m", Size = UDim2.fromOffset(80, 42), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Color = rankColor, Font = UIStyles.Fonts.Number, TextSize = UIStyles.FontSizes.HUDSmall, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
            end

            scroll.CanvasSize = UDim2.fromOffset(0, 156 + #SAMPLE_LEADERBOARD * 48 + 12)

        elseif selectedTab == 4 then
            -- ======================================== TITLES TAB ========================================
            for i, title in ipairs(SAMPLE_TITLES) do
                local yOff = (i - 1) * 78
                local card = New("Frame", { Name = "Title_" .. title.name, Size = UDim2.new(1, -8, 0, 70), Position = UDim2.fromOffset(0, yOff + 4), BackgroundColor3 = UIStyles.Colors.Elevated, BackgroundTransparency = title.unlocked and 0.15 or 0.4, ClipsDescendants = true, Parent = scroll })
                NewCorner(12).Parent = card

                if title.equipped then NewStroke(UIStyles.Colors.Cyan, 0.4, 2).Parent = card
                elseif title.unlocked then NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = card
                else NewStroke(UIStyles.Colors.TextMuted, 0.9, 1).Parent = card end

                local rarityColorMap = { Legendary = UIStyles.Colors.Gold, Epic = UIStyles.Colors.DeepPurple, Rare = UIStyles.Colors.ElectricBlue, Uncommon = UIStyles.Colors.BioGreen, Common = Color3.fromRGB(180, 180, 180) }
                local rColor = rarityColorMap[title.rarity] or Color3.new(1, 1, 1)

                UIComponents.CreateTextLabel({ Text = title.name, Size = UDim2.fromOffset(200, 22), Position = UDim2.fromOffset(12, 8), Color = title.unlocked and rColor or UIStyles.Colors.TextMuted, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.Small, Parent = card })
                UIComponents.CreateTextLabel({ Text = "[" .. title.rarity .. "] " .. (title.unlocked and "Unlocked" or title.requirement), Size = UDim2.fromOffset(220, 14), Position = UDim2.fromOffset(12, 32), Color = UIStyles.Colors.TextSecondary, TextSize = 9, Parent = card })
                UIComponents.CreateTextLabel({ Text = title.unlocked and (title.equipped and "✓ EQUIPPED" or (title.rarity .. " Title")) or "🔒 LOCKED", Size = UDim2.fromOffset(80, 16), Position = UDim2.fromOffset(12, 48), Color = title.equipped and UIStyles.Colors.Success or (title.unlocked and rColor or UIStyles.Colors.TextMuted), TextSize = UIStyles.FontSizes.Tiny, Font = UIStyles.Fonts.Display, Parent = card })

                if title.unlocked and not title.equipped then
                    UIComponents.CreateButton({
                        Name = "Equip", Text = "EQUIP", Size = UDim2.fromOffset(70, 34),
                        Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                        Color = UIStyles.Colors.Cyan, Transparency = 0.15, TextColor = UIStyles.Colors.TextPrimary,
                        FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 8,
                        Callback = function() print("[Social] Equipping title:", title.name) end,
                        Parent = card,
                    })
                end
            end

            scroll.CanvasSize = UDim2.fromOffset(0, #SAMPLE_TITLES * 78 + 12)
        end
    end

    BuildTabs()
    RefreshContent()

    local api = {}
    api.Refresh = RefreshContent
    api.Close = function() parent:Destroy() end
    return api
end

return SocialScreen