--[[
    VFXUtil.lua — Utility functions for visual effects
    Handles bioluminescence, pulses, and other atmospheric effects.
]]

local VFXUtil = {}

local TweenService = game:GetService("TweenService")

-- Predefined Bioluminescent and UI Colors from Style Guide
VFXUtil.Colors = {
    -- Accents
    CyanGlow = Color3.fromHex("#00E5FF"),
    BioGreen = Color3.fromHex("#39FF14"),
    DeepPurple = Color3.fromHex("#8B5CF6"),
    ElectricBlue = Color3.fromHex("#3B82F6"),
    
    -- Functional
    Gold = Color3.fromHex("#FFD700"),
    Danger = Color3.fromHex("#FF6B6B"),
    Warning = Color3.fromHex("#FF8C42"),
    Success = Color3.fromHex("#22C55E"),
    
    -- Backgrounds
    DeepOcean = Color3.fromHex("#060A1A"),
    SurfaceDark = Color3.fromHex("#0B0D17"),
}

-- Apply a bioluminescent look to a part
function VFXUtil.ApplyBioluminescence(part, color, brightness)
    if not part:IsA("BasePart") then return end
    
    part.Material = Enum.Material.Neon
    part.Color = color or VFXUtil.Colors.CyanGlow
    
    -- Optionally add a PointLight for extra glow
    local light = part:FindFirstChild("BioLight") or Instance.new("PointLight")
    light.Name = "BioLight"
    light.Color = part.Color
    light.Brightness = brightness or 1
    light.Range = 10
    light.Parent = part
end

-- Create a pulsing effect
function VFXUtil.Pulse(part, color1, color2, duration)
    if not part:IsA("BasePart") then return end
    
    local info = TweenInfo.new(duration or 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(part, info, {
        Color = color2,
    })
    
    part.Color = color1
    tween:Play()
    
    return tween
end

-- Create a "breathing" light effect
function VFXUtil.BreathingLight(light, minBrightness, maxBrightness, duration)
    if not light:IsA("Light") then return end
    
    local info = TweenInfo.new(duration or 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(light, info, {
        Brightness = maxBrightness,
    })
    
    light.Brightness = minBrightness
    tween:Play()
    
    return tween
end

return VFXUtil
