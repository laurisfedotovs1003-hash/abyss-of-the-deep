--[[
    PostProcessingController — Client-side post-processing effects stack
    Manages Bloom, ColorCorrection, DepthOfField, SunRays, BlurEffect.
    Provides zone-based and anomaly-based visual upgrades.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local VFXUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("VFXUtil"))

local PostProcessingController = Knit.CreateController {
    Name = "PostProcessingController",
}

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ================================================================
-- Post-Processing Instances
-- ================================================================

local bloom = nil
local colorCorrection = nil
local depthOfField = nil
local sunRays = nil
local blurEffect = nil

-- ================================================================
-- Initialize
-- ================================================================

function PostProcessingController:KnitStart()
    print("[PostProcessingController] AAA Graphics Pipeline initializing")

    -- Enable Future lighting for PBR
    self:ApplyLightingTechnology()
    self:SetupPostProcessing()
    self:SetupCaustics()

    -- Listen for zone changes to adjust effects
    local DepthService = Knit.GetService("DepthService")
    if DepthService then
        DepthService.Client:Get("GetLayerInfo"):Connect(function(data)
            self:ApplyZoneEffects(data)
        end)
    end

    -- Listen for anomaly effects
    local AnomalyService = Knit.GetService("AnomalyService")
    if AnomalyService then
        AnomalyService.Client:Get("AnomalyStarted"):Connect(function(data)
            if data.lighting then
                self:BoostAnomalyEffects(data.lighting)
            end
        end)
        AnomalyService.Client:Get("AnomalyEnded"):Connect(function()
            self:RevertAnomalyEffects()
        end)
    end

    print("[PostProcessingController] Graphics pipeline active — Future + PBR + PostFX")
end

-- ================================================================
-- 1. Lighting Technology (Future)
-- ================================================================

function PostProcessingController:ApplyLightingTechnology()
    -- Enable Future technology for PBR rendering
    Lighting.Technology = Enum.Technology.Future
    Lighting.EnvironmentDiffuseScale = 1.0
    Lighting.EnvironmentSpecularScale = 1.0

    -- Soft shadows
    Lighting.ShadowSoftness = 0.3
    Lighting.ClockTime = 12  -- Noon by default, TimeService will override
    Lighting.GeographicLatitude = 30

    -- Ambient occlusion
    Lighting.AmbientOcclusion = true

    -- Global illumination
    Lighting.GlobalShadows = true

    -- Reflection probe for surface water
    local existingProbe = Lighting:FindFirstChildOfClass("ReflectionProbe")
    if not existingProbe then
        local probe = Instance.new("ReflectionProbe")
        probe.Name = "WaterReflectionProbe"
        probe.Size = Vector3.new(1000, 50, 1000)
        probe.Position = Vector3.new(0, 0, 0)
        probe.AmbientDiffuse = Color3.new(0.95, 0.95, 1)
        probe.AmbientSpecular = Color3.new(0.7, 0.85, 1)
        probe.Brightness = 1.2
        probe.Parent = Lighting
    end

    print("[PostProcessingController] Future lighting + PBR + Reflection Probe active")
end

-- ================================================================
-- 2. Post-Processing Stack
-- ================================================================

function PostProcessingController:SetupPostProcessing()
    -- Bloom
    bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.4
    bloom.Size = 24
    bloom.Threshold = 0.8

    -- ColorCorrection
    colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    colorCorrection.Brightness = 0
    colorCorrection.Contrast = 0.15
    colorCorrection.Saturation = 0.1
    colorCorrection.TintColor = Color3.fromRGB(180, 210, 255)  -- Subtle ocean blue tint

    -- DepthOfField
    depthOfField = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect", Lighting)
    depthOfField.Enabled = true
    depthOfField.FarIntensity = 0.3
    depthOfField.FocusDistance = 30    -- Focus on nearby objects
    depthOfField.InFocusRadius = 20    -- Sharp region around player
    depthOfField.NearIntensity = 0

    -- SunRays (god rays)
    sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
    sunRays.Intensity = 0.15
    sunRays.Spread = 0.5

    -- Blur (disabled by default, used for transitions)
    blurEffect = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect", Lighting)
    blurEffect.Enabled = false
    blurEffect.Size = 0

    print("[PostProcessingController] PostFX stack: Bloom + CC + DoF + SunRays + Blur")
end

-- ================================================================
-- 3. Zone-Based Effect Adjustments
-- ================================================================

function PostProcessingController:ApplyZoneEffects(layerData)
    local zoneIndex = layerData and layerData.index or layerData and layerData.layerIndex or 1

    if zoneIndex == 1 then
        -- Sunlight: bright, high visibility
        if bloom then TweenService:Create(bloom, TweenInfo.new(2), { Intensity = 0.4, Threshold = 0.8 }):Play() end
        if sunRays then TweenService:Create(sunRays, TweenInfo.new(2), { Intensity = 0.15 }):Play() end
        if depthOfField then TweenService:Create(depthOfField, TweenInfo.new(2), { FarIntensity = 0.2 }):Play() end

    elseif zoneIndex == 2 then
        -- Twilight: fading light, deeper blue
        if bloom then TweenService:Create(bloom, TweenInfo.new(2), { Intensity = 0.6, Threshold = 0.6 }):Play() end
        if sunRays then TweenService:Create(sunRays, TweenInfo.new(2), { Intensity = 0.05 }):Play() end
        if depthOfField then TweenService:Create(depthOfField, TweenInfo.new(2), { FarIntensity = 0.4 }):Play() end

    elseif zoneIndex == 3 then
        -- Midnight: heavy bloom from bioluminescence, total darkness
        if bloom then TweenService:Create(bloom, TweenInfo.new(2), { Intensity = 1.0, Threshold = 0.3 }):Play() end
        if sunRays then TweenService:Create(sunRays, TweenInfo.new(2), { Intensity = 0 }):Play() end
        if depthOfField then TweenService:Create(depthOfField, TweenInfo.new(2), { FarIntensity = 0.6 }):Play() end

        -- ColorCorrection: deep blue/purple tint, high contrast
        if colorCorrection then
            TweenService:Create(colorCorrection, TweenInfo.new(2), {
                Brightness = -0.2,
                Contrast = 0.4,
                Saturation = -0.2,
                TintColor = Color3.fromRGB(120, 160, 255)
            }):Play()
        end
    end
end

-- ================================================================
-- 4. Anomaly Effect Boost
-- ================================================================

function PostProcessingController:BoostAnomalyEffects(anomalyLighting)
    -- Boost bloom during anomalies
    if bloom then
        TweenService:Create(bloom, TweenInfo.new(2), {
            Intensity = 1.5,
            Size = 32,
            Threshold = 0.4,
        }):Play()
    end

    -- Apply anomaly tint via color correction
    if colorCorrection and anomalyLighting then
        TweenService:Create(colorCorrection, TweenInfo.new(2), {
            Brightness = anomalyLighting.Brightness or 0,
            Contrast = anomalyLighting.Contrast or 0.5,
            Saturation = anomalyLighting.Saturation or 0,
            TintColor = anomalyLighting.TintColor or Color3.new(1, 1, 1),
        }):Play()
    end

    -- Blur kick during anomaly start
    self:ApplyBlurEffect(0.3, 8)
end

function PostProcessingController:RevertAnomalyEffects()
    if bloom then
        TweenService:Create(bloom, TweenInfo.new(3), { Intensity = 0.4, Size = 24, Threshold = 0.8 }):Play()
    end

    if blurEffect then
        TweenService:Create(blurEffect, TweenInfo.new(2), { Size = 0 }):Play()
        task.delay(2, function() blurEffect.Enabled = false end)
    end
end

-- ================================================================
-- 5. Transition Blur
-- ================================================================

function PostProcessingController:ApplyBlurEffect(size, duration)
    size = size or 12
    duration = duration or 2
    if blurEffect then
        blurEffect.Enabled = true
        TweenService:Create(blurEffect, TweenInfo.new(duration * 0.5), { Size = size }):Play()
        task.delay(duration, function()
            TweenService:Create(blurEffect, TweenInfo.new(duration * 0.5), { Size = 0 }):Play()
            task.delay(duration * 0.5, function() blurEffect.Enabled = false end)
        end)
    end
end

-- ================================================================
-- 6. Water Caustics System
-- ================================================================

local causticParts = {}
local causticTime = 0

function PostProcessingController:SetupCaustics()
    -- Create a beam-like projector that casts caustic patterns
    -- We use a series of semi-transparent parts with animated textures to simulate caustics
    local causticFolder = workspace:FindFirstChild("Caustics") or Instance.new("Folder", workspace)
    causticFolder.Name = "Caustics"

    -- Clean up old caustics
    for _, child in ipairs(causticFolder:GetChildren()) do
        child:Destroy()
    end

    -- Create caustic light projectors in Sunlight zone (depth 0-200)
    for i = 1, 8 do
        local x = math.random(-150, 150)
        local z = math.random(-150, 150)
        local y = -math.random(20, 180)

        local caustic = Instance.new("Part")
        caustic.Name = "CausticLight"
        caustic.Size = Vector3.new(40, 0.5, 40)
        caustic.Position = Vector3.new(x, y, z)
        caustic.Anchored = true
        caustic.CanCollide = false
        caustic.Material = Enum.Material.Glass
        caustic.Transparency = 0.9
        caustic.Color = Color3.fromRGB(180, 230, 255)
        caustic.CastShadow = false
        caustic.Parent = causticFolder

        -- Surface light that projects downward
        local light = Instance.new("SurfaceLight")
        light.Name = "CausticGlow"
        light.Color = Color3.fromRGB(150, 220, 255)
        light.Brightness = 2
        light.Range = 30
        light.Face = Enum.NormalId.Top
        light.Parent = caustic

        table.insert(causticParts, { part = caustic, light = light, phase = math.random() * math.pi * 2 })
    end

    -- Animate caustic shimmer
    RunService:BindToRenderStep("CausticAnim", Enum.RenderPriority.Last.Value + 5, function(dt)
        causticTime = causticTime + dt
        for _, caustic in ipairs(causticParts) do
            local flicker = 0.7 + math.sin(causticTime * 0.3 + caustic.phase) * 0.3
            caustic.light.Brightness = flicker * 2
            caustic.part.Transparency = 0.85 + math.sin(causticTime * 0.5 + caustic.phase) * 0.1
        end
    end)

    print("[PostProcessingController] Caustic light system set up")
end

-- ================================================================
-- 7. Material Upgrade Utility
-- ================================================================

function PostProcessingController:UpgradeMaterial(part, materialType)
    if not part or not part:IsA("BasePart") then return end

    if materialType == "Bioluminescent" then
        part.Material = Enum.Material.Neon
        -- Add glow light
        if not part:FindFirstChildOfClass("PointLight") then
            local light = Instance.new("PointLight")
            light.Color = part.Color
            light.Brightness = 1
            light.Range = 8
            light.Parent = part
        end
    elseif materialType == "Metal" then
        part.Material = Enum.Material.Metal
    elseif materialType == "Organic" then
        part.Material = Enum.Material.Foil
    elseif materialType == "Glass" then
        part.Material = Enum.Material.Glass
        part.Transparency = 0.2
    elseif materialType == "Concrete" then
        part.Material = Enum.Material.Concrete
    end
end

function PostProcessingController:UpgradeAllBaseMaterials()
    -- Scan workspace for Map objects and upgrade materials
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return end

    for _, child in ipairs(mapFolder:GetDescendants()) do
        if child:IsA("BasePart") then
            if child.Name:find("Crystal") or child.Name:find("BioRock") or child.Name:find("Glow") then
                self:UpgradeMaterial(child, "Bioluminescent")
            elseif child.Name:find("Gantry") or child.Name:find("Crane") or child.Name:find("Metal") then
                self:UpgradeMaterial(child, "Metal")
            elseif child.Name:find("Vent") or child.Name:find("Chimney") then
                self:UpgradeMaterial(child, "Concrete")
                if child:FindFirstChild("VentRim") then
                    self:UpgradeMaterial(child, "Metal")
                end
            elseif child.Name:find("Lab") and child.Material == Enum.Material.SmoothPlastic then
                self:UpgradeMaterial(child, "Glass")
            end
        end
    end
    print("[PostProcessingController] Material upgrade pass complete")
end

-- ================================================================
-- Cleanup
-- ================================================================

function PostProcessingController:KnitStop()
    RunService:UnbindFromRenderStep("CausticAnim")
    for _, caustic in ipairs(causticParts) do
        caustic.part:Destroy()
    end
    causticParts = {}
end

return PostProcessingController
