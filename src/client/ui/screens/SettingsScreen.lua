--[[
    SettingsScreen.lua — Audio settings screen for Abyss of the Deep
    Provides: Master/SFX/Music/Ambient volume sliders, mute toggle, sound test mode
]]

local UIStyles = require(script.Parent.Parent.UIStyles)
local UIComponents = require(script.Parent.Parent.UIComponents)

local SettingsScreen = {}

-- ============================================================
-- Helpers
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

-- ============================================================
-- Volume Slider Component
-- ============================================================

local function CreateVolumeSlider(props)
    local parent = props.Parent
    local sliderName = props.Name or "Slider"
    local label = props.Label or "Volume"
    local icon = props.Icon or "🔊"
    local color = props.Color or UIStyles.Colors.Cyan
    local initialValue = props.InitialValue or 0.8
    local onChange = props.OnChange or function() end

    -- Container
    local container = New("Frame", {
        Name = sliderName,
        Size = UDim2.new(1, -32, 0, 48),
        Position = UDim2.fromOffset(16, props.YOffset or 0),
        BackgroundColor3 = UIStyles.Colors.CardBG,
        BackgroundTransparency = 0.5,
        Parent = parent,
    })
    NewCorner(10).Parent = container
    NewStroke(UIStyles.Colors.Border, 0.8, 1).Parent = container

    -- Icon + Label
    local iconLabel = UIComponents.CreateTextLabel({
        Name = "Icon",
        Text = icon .. " " .. label,
        Size = UDim2.fromOffset(140, 48),
        Position = UDim2.fromOffset(12, 0),
        Color = color,
        Font = UIStyles.Fonts.Body,
        TextSize = UIStyles.FontSizes.Body,
        Parent = container,
    })

    -- Value label (percentage)
    local valueLabel = UIComponents.CreateTextLabel({
        Name = "Value",
        Text = tostring(math.floor(initialValue * 100)) .. "%",
        Size = UDim2.fromOffset(44, 48),
        Position = UDim2.new(1, -48, 0, 0),
        Color = color,
        Font = UIStyles.Fonts.Number,
        TextSize = UIStyles.FontSizes.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = container,
    })

    -- Slider track
    local track = New("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -204, 0, 4),
        Position = UDim2.fromOffset(148, 22),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.3,
        Parent = container,
    })
    NewCorner(2).Parent = track

    -- Slider fill
    local fill = New("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(initialValue, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = color,
        Parent = track,
    })
    NewCorner(2).Parent = fill

    -- Slider thumb
    local thumb = New("Frame", {
        Name = "Thumb",
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.fromScale(initialValue, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color,
        ZIndex = 2,
        Parent = track,
    })
    NewCorner(10).Parent = thumb
    NewStroke(UIStyles.Colors.TextPrimary, 0.5, 2).Parent = thumb

    -- ============================================================
    -- Slider Input Handling
    -- ============================================================

    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local dragging = false
    local currentValue = initialValue

    local function SetValue(value)
        value = math.clamp(value, 0, 1)
        currentValue = value
        fill.Size = UDim2.fromScale(value, 1)
        thumb.Position = UDim2.fromScale(value, 0.5)
        valueLabel.Text = tostring(math.floor(value * 100)) .. "%"
        onChange(value)
    end

    -- Mouse/ touch input on track
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pos = input.Position.X - track.AbsolutePosition.X
            SetValue(pos / track.AbsoluteSize.X)
        end
    end)

    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Drag tracking
    local connection
    connection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X - track.AbsolutePosition.X
            SetValue(pos / track.AbsoluteSize.X)
        end
    end)

    return {
        Container = container,
        GetValue = function() return currentValue end,
        SetValue = SetValue,
        Cleanup = function()
            if connection then connection:Disconnect() end
        end,
    }
end

-- ============================================================
-- Create Settings Screen
-- ============================================================

function SettingsScreen.Create(container)
    local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
    local AudioController = Knit.GetController("AudioController")
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer

    -- ============================================================
    -- Background overlay
    -- ============================================================
    local overlay = New("Frame", {
        Name = "SettingsOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        Parent = container,
    })

    -- ============================================================
    -- Settings panel
    -- ============================================================
    local panel = New("Frame", {
        Name = "SettingsPanel",
        Size = UDim2.fromOffset(380, 440),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIStyles.Colors.DeepOcean,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Parent = container,
    })
    NewCorner(20).Parent = panel
    NewStroke(UIStyles.Colors.Border, 0.6, 2).Parent = panel

    -- Title
    local titleLabel = UIComponents.CreateTextLabel({
        Name = "Title",
        Text = "⚙  SETTINGS",
        Size = UDim2.fromOffset(380, 44),
        Position = UDim2.fromOffset(0, 16),
        Color = UIStyles.Colors.Cyan,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.SectionTitle,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = panel,
    })

    -- Divider
    local divider = New("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.fromOffset(16, 60),
        BackgroundColor3 = UIStyles.Colors.Border,
        Parent = panel,
    })

    -- ============================================================
    -- Volume Sliders
    -- ============================================================
    local sliders = {}
    local sliderStartY = 76

    -- Load saved settings or use defaults
    local savedSettings = {
        MasterVolume = 0.8,
        SFXVolume = 0.9,
        MusicVolume = 0.5,
        AmbientVolume = 0.75,
        Muted = false,
    }

    -- Try loading from player profile
    pcall(function()
        if Player and Player:FindFirstChild("ProfileData") then
            local data = Player.ProfileData.Value
            if data and data.AudioSettings then
                savedSettings = data.AudioSettings
            end
        end
    end)

    -- Master Volume
    sliders.Master = CreateVolumeSlider({
        Name = "MasterSlider",
        Label = "Master Volume",
        Icon = "🔊",
        Color = UIStyles.Colors.Cyan,
        YOffset = sliderStartY,
        InitialValue = savedSettings.MasterVolume or 0.8,
        Parent = panel,
        OnChange = function(value)
            savedSettings.MasterVolume = value
            if AudioController and AudioController.SetVolumeMultiplier then
                AudioController:SetVolumeMultiplier("Master", value)
            end
            AudioController:PlayUIClick()
        end,
    })

    -- SFX Volume
    sliders.SFX = CreateVolumeSlider({
        Name = "SFXSlider",
        Label = "SFX Volume",
        Icon = "💥",
        Color = UIStyles.Colors.Gold,
        YOffset = sliderStartY + 56,
        InitialValue = savedSettings.SFXVolume or 0.9,
        Parent = panel,
        OnChange = function(value)
            savedSettings.SFXVolume = value
            if AudioController and AudioController.SetVolumeMultiplier then
                AudioController:SetVolumeMultiplier("SFX", value)
            end
        end,
    })

    -- Music Volume
    sliders.Music = CreateVolumeSlider({
        Name = "MusicSlider",
        Label = "Music Volume",
        Icon = "🎵",
        Color = UIStyles.Colors.DeepPurple,
        YOffset = sliderStartY + 112,
        InitialValue = savedSettings.MusicVolume or 0.5,
        Parent = panel,
        OnChange = function(value)
            savedSettings.MusicVolume = value
            if AudioController and AudioController.SetVolumeMultiplier then
                AudioController:SetVolumeMultiplier("Music", value)
            end
        end,
    })

    -- Ambient Volume
    sliders.Ambient = CreateVolumeSlider({
        Name = "AmbientSlider",
        Label = "Ambient Volume",
        Icon = "🌊",
        Color = UIStyles.Colors.BioGreen,
        YOffset = sliderStartY + 168,
        InitialValue = savedSettings.AmbientVolume or 0.75,
        Parent = panel,
        OnChange = function(value)
            savedSettings.AmbientVolume = value
            if AudioController and AudioController.SetVolumeMultiplier then
                AudioController:SetVolumeMultiplier("Ambient", value)
            end
        end,
    })

    -- ============================================================
    -- Mute All Toggle
    -- ============================================================
    local muteBtn = UIComponents.CreateButton({
        Name = "MuteButton",
        Text = savedSettings.Muted and "🔇 Unmute All" or "🔊 Mute All",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, sliderStartY + 232),
        Color = savedSettings.Muted and UIStyles.Colors.Danger or UIStyles.Colors.Elevated,
        TextColor = UIStyles.Colors.TextPrimary,
        FontSize = UIStyles.FontSizes.Body,
        CornerRadius = 10,
        Parent = panel,
        Callback = function()
            savedSettings.Muted = not savedSettings.Muted
            muteBtn:FindFirstChild("Label", true).Text = savedSettings.Muted and "🔇 Unmute All" or "🔊 Mute All"
            muteBtn.BackgroundColor3 = savedSettings.Muted and UIStyles.Colors.Danger or UIStyles.Colors.Elevated
            if AudioController and AudioController.SetMuted then
                AudioController:SetMuted(savedSettings.Muted)
            end
        end,
    })

    -- ============================================================
    -- Sound Test Mode
    -- ============================================================
    local testLabel = UIComponents.CreateTextLabel({
        Name = "TestLabel",
        Text = "🔬 Sound Test",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.fromOffset(16, sliderStartY + 282),
        Color = UIStyles.Colors.TextMuted,
        Font = UIStyles.Fonts.Display,
        TextSize = UIStyles.FontSizes.Small,
        Parent = panel,
    })

    -- Sound test input
    local testInput = New("TextBox", {
        Name = "SoundTestInput",
        Size = UDim2.new(1, -100, 0, 32),
        Position = UDim2.fromOffset(16, sliderStartY + 304),
        BackgroundColor3 = UIStyles.Colors.SurfaceDark,
        BackgroundTransparency = 0.3,
        PlaceholderText = "Enter SFX name...",
        PlaceholderColor3 = UIStyles.Colors.TextMuted,
        TextColor3 = UIStyles.Colors.TextPrimary,
        Text = "",
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        ClearTextOnFocus = false,
        Parent = panel,
    })
    NewCorner(8).Parent = testInput
    NewStroke(UIStyles.Colors.Border, 0.7, 1).Parent = testInput

    -- Play button
    local playTestBtn = UIComponents.CreateButton({
        Name = "PlayTest",
        Text = "▶ Play",
        Size = UDim2.fromOffset(68, 32),
        Position = UDim2.new(1, -84, 0, sliderStartY + 304),
        Color = UIStyles.Colors.Cyan,
        TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.Small,
        CornerRadius = 8,
        Parent = panel,
        Callback = function()
            local sfxName = testInput.Text
            if sfxName and #sfxName > 0 and AudioController then
                -- Try playing as SFX, ambient, or music
                local ok = pcall(function()
                    if AudioController.PlaySFX then
                        AudioController:PlaySFX(sfxName)
                    elseif AudioController.PlayAmbient then
                        AudioController:PlayAmbient(sfxName)
                    elseif AudioController.PlayMusic then
                        AudioController:PlayMusic(sfxName)
                    end
                end)
                if not ok then
                    -- Show error toast
                    print("[Settings] Unknown sound: " .. sfxName)
                end
            end
        end,
    })

    -- ============================================================
    -- Save Button
    -- ============================================================
    local saveBtn = UIComponents.CreateButton({
        Name = "SaveButton",
        Text = "💾 SAVE",
        Size = UDim2.new(1, -32, 0, 44),
        Position = UDim2.fromOffset(16, sliderStartY + 350),
        Color = UIStyles.Colors.Success,
        TextColor = UIStyles.Colors.TextOnAccent,
        FontSize = UIStyles.FontSizes.Body,
        CornerRadius = 12,
        Parent = panel,
        Callback = function()
            -- Save to player profile
            pcall(function()
                if Player and Player:FindFirstChild("ProfileData") then
                    local profile = Player.ProfileData.Value
                    if profile then
                        profile.AudioSettings = savedSettings
                        Player.ProfileData.Value = profile
                    end
                end
            end)
            -- Also save to AudioController
            if AudioController and AudioController.SaveSettings then
                AudioController:SaveSettings(savedSettings)
            end
            -- Show confirmation
            if AudioController and AudioController.PlayUIPurchase then
                AudioController:PlayUIPurchase()
            end
            print("[Settings] Audio settings saved")
        end,
    })

    -- ============================================================
    -- API
    -- ============================================================

    return {
        Container = panel,
        GetSettings = function() return savedSettings end,
        SetSlider = function(sliderName, value)
            if sliders[sliderName] and sliders[sliderName].SetValue then
                sliders[sliderName]:SetValue(value)
            end
        end,
        Cleanup = function()
            for _, slider in pairs(sliders) do
                if slider.Cleanup then slider:Cleanup() end
            end
        end,
        UpdateCurrency = function() end, -- Stub: no currency in settings
        SetAnomalyActive = function() end, -- Stub: no anomaly in settings
    }
end

return SettingsScreen