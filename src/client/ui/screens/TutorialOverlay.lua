--[[
    TutorialOverlay.lua — Step-by-step tutorial overlay for Abyss of the Deep
    8-step onboarding with backdrop cutout, instruction panel, progress, skip button.
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local TutorialOverlay = {}
local TweenService = game:GetService("TweenService")

-- Step definitions (mirrors server TUTORIAL_STEPS)
local STEPS = {
    { step = 1, title = "Welcome to the Deep",      instruction = "Welcome, Explorer! Press [E] at the Diving Locker to begin." },
    { step = 2, title = "Visit the Shop",            instruction = "Head to the Shop. Press [B] or click the Shop button." },
    { step = 3, title = "Equip Your Gear",           instruction = "Open your Inventory with [G] and click 'Equip' on your Basic Gear." },
    { step = 4, title = "First Dive",                instruction = "Walk to the dock and press [F] to dive into the Sunlight Zone." },
    { step = 5, title = "Catch a Creature",          instruction = "Click [Left Mouse] when the reticle lines up to catch a creature!" },
    { step = 6, title = "Surface Safely",            instruction = "Surface by pressing [F] or swimming up to the boat." },
    { step = 7, title = "Sell Your Catch",           instruction = "Open your Collection with [C] and click 'Sell' on your creature." },
    { step = 8, title = "Upgrade & Continue",        instruction = "Open Shop [B] and buy the Scuba Kit to explore deeper!" },
}

-- ============================================================
-- CREATE: Tutorial overlay
-- ============================================================

function TutorialOverlay.Create(parent)
    local currentStep = 1
    local active = false
    local callbackOnComplete = nil
    local callbackOnSkip = nil
    local callbackOnStepComplete = nil

    -- Full screen backdrop
    local backdrop = New("Frame", {
        Name = "TutorialBackdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        ZIndex = 100,
        Visible = false,
        Parent = parent,
    })

    -- Instruction panel
    local panel = New("Frame", {
        Name = "TutorialPanel",
        Size = UDim2.fromOffset(320, 200),
        Position = UDim2.fromScale(0.5, 0.85),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        ZIndex = 101,
        Visible = false,
        Parent = parent,
    })
    NewCorner(16).Parent = panel
    NewStroke(UIStyles.Colors.Cyan, 0.3, 2).Parent = panel

    -- Glow effect on panel
    local glow = New("ImageLabel", {
        Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, Image = "rbxassetid://5025537645", ImageColor3 = UIStyles.Colors.Cyan,
        ImageTransparency = 0.9, ScaleType = Enum.ScaleType.Slice, ZIndex = 100, Parent = panel,
    })

    -- Step indicator bar at top
    local stepIndicator = New("Frame", {
        Name = "StepIndicator", Size = UDim2.new(1, -32, 0, 4), Position = UDim2.fromOffset(16, 12),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark, ClipsDescendants = true, ZIndex = 102, Parent = panel,
    })
    NewCorner(2).Parent = stepIndicator

    local stepFill = New("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = UIStyles.Colors.Cyan,
        ClipsDescendants = true, ZIndex = 103, Parent = stepIndicator,
    })
    NewCorner(2).Parent = stepFill

    -- Step counter
    local stepCounter = UIComponents.CreateTextLabel({
        Name = "StepCounter", Text = "Step 1/8",
        Size = UDim2.fromOffset(100, 18), Position = UDim2.fromOffset(16, 22),
        Color = UIStyles.Colors.Cyan, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.Tiny, ZIndex = 102, Parent = panel,
    })

    -- Title
    local titleLabel = UIComponents.CreateTextLabel({
        Name = "Title", Text = "Welcome!",
        Size = UDim2.new(1, -32, 0, 24), Position = UDim2.fromOffset(16, 44),
        Color = UIStyles.Colors.TextPrimary, Font = UIStyles.Fonts.Display, TextSize = UIStyles.FontSizes.ItemName, ZIndex = 102, Parent = panel,
    })

    -- Instruction text
    local instructionLabel = UIComponents.CreateTextLabel({
        Name = "Instruction", Text = "",
        Size = UDim2.new(1, -32, 0, 60), Position = UDim2.fromOffset(16, 72),
        Color = UIStyles.Colors.TextSecondary, TextSize = UIStyles.FontSizes.Body, ZIndex = 102, Parent = panel,
    })

    -- Highlight target frame (positioned absolutely on screen)
    local highlightFrame = New("Frame", {
        Name = "HighlightTarget",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 0.2,
        BackgroundColor3 = UIStyles.Colors.Cyan,
        ZIndex = 101,
        Visible = false,
        Parent = parent,
    })
    NewCorner(8).Parent = highlightFrame

    -- Pulse animation on highlight
    local highlightPulse = nil

    -- Rewards info
    local rewardLabel = UIComponents.CreateTextLabel({
        Name = "Reward", Text = "Reward: 🪙 10 Credits",
        Size = UDim2.new(1, -32, 0, 16), Position = UDim2.fromOffset(16, 136),
        Color = UIStyles.Colors.Gold, TextSize = UIStyles.FontSizes.Tiny, ZIndex = 102, Parent = panel,
    })

    -- Completion message (small, below instruction)
    local completionMsg = UIComponents.CreateTextLabel({
        Name = "CompletionMsg", Text = "",
        Size = UDim2.new(1, -32, 0, 16), Position = UDim2.fromOffset(16, 120),
        Color = UIStyles.Colors.Success, TextSize = UIStyles.FontSizes.Tiny, ZIndex = 102, Visible = false, Parent = panel,
    })

    -- Buttons frame
    local btnFrame = New("Frame", {
        Name = "TutorialBtns", Size = UDim2.new(1, -32, 0, 36), Position = UDim2.fromOffset(16, 155),
        BackgroundTransparency = 1, ZIndex = 102, Parent = panel,
    })

    -- Skip button (visible after step 1)
    local skipBtn = UIComponents.CreateButton({
        Name = "SkipBtn", Text = "✕ Skip Tutorial",
        Size = UDim2.fromOffset(120, 36), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5),
        Color = UIStyles.Colors.Elevated, Transparency = 0.3, TextColor = UIStyles.Colors.TextMuted,
        FontSize = UIStyles.FontSizes.Tiny, CornerRadius = 8, Stroke = true, StrokeColor = UIStyles.Colors.Border,
        Visible = false, ZIndex = 103,
        Callback = function()
            Hide()
            if callbackOnSkip then callbackOnSkip() end
        end,
        Parent = btnFrame,
    })

    -- Continue button (shows after step completion)
    local continueBtn = UIComponents.CreateButton({
        Name = "ContinueBtn", Text = "Done → Next",
        Size = UDim2.fromOffset(130, 36), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        Color = UIStyles.Colors.Cyan, Transparency = 0.15, TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.Small, CornerRadius = 8, ZIndex = 103,
        Gradient = {UIStyles.Colors.Cyan, UIStyles.Colors.ElectricBlue},
        Visible = false,
        Callback = function()
            if currentStep < 8 then
                AdvanceStep(currentStep + 1)
            else
                Hide()
                if callbackOnComplete then callbackOnComplete() end
            end
        end,
        Parent = btnFrame,
    })

    -- ============================================================
    -- Show/Hide Logic
    -- ============================================================

    function Show(stepNum, data)
        currentStep = stepNum or 1
        active = true

        backdrop.Visible = true
        panel.Visible = true

        local step = STEPS[currentStep]
        if not step then
            Hide()
            return
        end

        -- Update display
        stepCounter.Text = "Step " .. tostring(currentStep) .. "/8"
        stepFill.Size = UDim2.fromScale(currentStep / 8, 1)
        titleLabel.Text = step.title
        instructionLabel.Text = step.instruction

        -- Reward display from server data if available
        if data and data.rewardType and data.rewardAmount then
            rewardLabel.Text = "Reward: " .. (data.rewardType == "Credits" and "🪙 " or "◎ ") .. tostring(data.rewardAmount)
        else
            rewardLabel.Text = "Reward: 🪙 " .. tostring(10 + currentStep * 5) .. " Credits"
        end

        -- Completion message
        completionMsg.Visible = false

        -- Skip button visible after step 1
        skipBtn.Visible = currentStep > 1

        -- Continue button hidden until step completed
        continueBtn.Visible = false

        -- Highlight target if specified
        if data and data.highlightTarget then
            highlightFrame.Visible = true
            -- In production, find the actual UI element and position the highlight around it
            -- For now, highlight center of screen
            highlightFrame.Size = UDim2.fromOffset(120, 60)
            highlightFrame.Position = UDim2.fromScale(0.5, 0.35)
            highlightFrame.AnchorPoint = Vector2.new(0.5, 0.5)

            -- Pulse animation
            if highlightPulse then highlightPulse:Cancel() end
            highlightPulse = TweenService:Create(highlightFrame,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
                { BackgroundTransparency = 0.4 }
            )
            highlightPulse:Play()
        else
            highlightFrame.Visible = false
        end

        -- Animate panel in
        panel.Position = UDim2.fromScale(0.5, 0.9)
        local tweenIn = TweenService:Create(panel,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.fromScale(0.5, 0.85) }
        )
        tweenIn:Play()

        print("[Tutorial] Showing step", currentStep, ":", step.title)
    end

    function Hide()
        active = false
        backdrop.Visible = false
        panel.Visible = false
        highlightFrame.Visible = false
        if highlightPulse then highlightPulse:Cancel(); highlightPulse = nil end
    end

    function AdvanceStep(stepNum)
        if stepNum > 8 then
            Hide()
            if callbackOnComplete then callbackOnComplete() end
            return
        end
        Show(stepNum)
    end

    function ShowStepComplete(message, rewardType, rewardAmount)
        completionMsg.Visible = true
        completionMsg.Text = "✅ " .. (message or "Step complete!")
        continueBtn.Visible = true
        continueBtn.Text = currentStep >= 8 and "🎉 Finish!" or "Done → Next"
    end

    -- ============================================================
    -- Public API
    -- ============================================================

    local api = {}

    api.Show = function(stepNum, data)
        Show(stepNum, data)
    end

    api.Hide = Hide

    api.AdvanceStep = AdvanceStep

    api.ShowStepComplete = ShowStepComplete

    api.IsActive = function() return active end

    api.GetCurrentStep = function() return currentStep end

    api.OnComplete = function(cb)
        callbackOnComplete = cb
    end

    api.OnSkip = function(cb)
        callbackOnSkip = cb
    end

    return api
end

local function New(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

return TutorialOverlay