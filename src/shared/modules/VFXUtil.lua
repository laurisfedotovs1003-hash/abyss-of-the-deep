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

-- ================================================================
-- Particle 2.0 System
-- ================================================================

-- Create a light-emitting particle emitter
function VFXUtil.CreateLightParticles(parent, config)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = config.Texture or "rbxassetid://2442214466"
    emitter.Color = config.Color or ColorSequence.new(VFXUtil.Colors.CyanGlow)
    emitter.Size = config.Size or NumberSequence.new(0.3, 0.6)
    emitter.Transparency = config.Transparency or NumberSequence.new(0, 0.8)
    emitter.Lifetime = config.Lifetime or NumberRange.new(1, 3)
    emitter.Rate = config.Rate or 10
    emitter.Speed = config.Speed or NumberRange.new(2, 8)
    emitter.SpreadAngle = config.SpreadAngle or Vector2.new(30, 30)
    emitter.LightEmission = config.LightEmission or 0.3
    emitter.LightInfluence = config.LightInfluence or 0.5
    emitter.VelocityInheritance = config.VelocityInheritance or 0.2
    emitter.RotSpeed = config.RotSpeed or NumberRange.new(-90, 90)
    emitter.RotType = config.RotType or Enum.ParticleRotationType.VelocityRelative
    emitter.ZOffset = config.ZOffset or 0
    emitter.Parent = parent

    if config.Acceleration then
        emitter.Acceleration = config.Acceleration
    end
    if config.Drag then
        emitter.Drag = config.Drag
    end

    return emitter
end

-- Create a glow trail on a moving object (e.g., rare/epic creatures)
function VFXUtil.CreateGlowTrail(attachmentA, attachmentB, color, lifetime)
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachmentA
    trail.Attachment1 = attachmentB
    trail.Color = ColorSequence.new(color or VFXUtil.Colors.CyanGlow)
    trail.Lifetime = lifetime or 1.5
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.9)
    })
    trail.LightEmission = 0.4
    trail.LightInfluence = 0.3
    trail.Enabled = true
    trail.Texture = "rbxassetid://2442214466"
    return trail
end

-- Create mesh-style bubble particles (better than flat sprites)
function VFXUtil.CreateMeshBubbles(parent, config)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://585075134" -- Bubble texture (round)
    emitter.Color = config.Color or ColorSequence.new(Color3.fromRGB(180, 220, 255))
    emitter.Size = config.Size or NumberSequence.new(0.2, 0.5)
    emitter.Transparency = config.Transparency or NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.3, 0.1),
        NumberSequenceKeypoint.new(1, 0.7)
    })
    emitter.Lifetime = config.Lifetime or NumberRange.new(1, 4)
    emitter.Rate = config.Rate or 6
    emitter.Speed = config.Speed or NumberRange.new(1, 4)
    emitter.SpreadAngle = config.SpreadAngle or Vector2.new(10, 10)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.LightEmission = 0.15
    emitter.LightInfluence = 0.3
    emitter.VelocityInheritance = 0.4
    emitter.Squish = config.Squish or 0 -- Keep bubbles round
    emitter.Parent = parent
    return emitter
end

-- Create burst particle effect with physics-like behavior
function VFXUtil.CreateBurstEffect(position, color, particleCount, parent)
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = parent or workspace.Terrain

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://2442214466"
    emitter.Color = ColorSequence.new(color or VFXUtil.Colors.CyanGlow)
    emitter.Size = NumberSequence.new(0.5, 0)
    emitter.Transparency = NumberSequence.new(0, 0.9)
    emitter.Lifetime = NumberRange.new(0.4, 1.0)
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(8, 20)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.LightEmission = 0.5
    emitter.LightInfluence = 0.4
    emitter.Acceleration = Vector3.new(0, 2, 0) -- Float upward
    emitter.Drag = 1
    emitter.Parent = attachment

    emitter:Emit(particleCount or 20)

    task.delay(1.5, function()
        attachment:Destroy()
    end)

    return emitter
end

return VFXUtil

