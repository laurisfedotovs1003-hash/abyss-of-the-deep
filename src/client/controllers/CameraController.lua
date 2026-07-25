--[[
    CameraController — Manages underwater camera effects and transitions
    Handles depth-based fog, color tinting, and immersive camera behavior.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))
local EnvConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("EnvironmentConfig"))

local CameraController = Knit.CreateController {
    Name = "CameraController",
}

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Player = game:GetService("Players").LocalPlayer

-- State
local currentLayerIndex = 1
local currentDepth = 0
local targetFogColor = Color3.fromRGB(30, 144, 255)
local targetFogEnd = 500
local underwaterEffect = 0 -- 0 = surface, 1 = fully underwater

-- Time of Day & Weather overlays
local timeOfDayLighting = nil     -- Current time-of-day lighting table
local weatherLighting = nil       -- Current weather lighting modifiers
local weatherModifiers = nil      -- Current weather modifiers
local savedTimeLighting = {}      -- Saved before anomaly overrides

-- Active connections for cleanup
local connections = {}

function CameraController:KnitStart()
    print("[CameraController] Initialized")
    
    -- Listen for depth updates from DepthService
    local DepthService = Knit.GetService("DepthService")
    if DepthService then
        table.insert(connections, DepthService.Client:Get("GetDepthData"):Connect(function(data)
            currentDepth = data.depth or 0
            currentLayerIndex = data.layerIndex or 1
        end))
        
        table.insert(connections, DepthService.Client:Get("GetLayerInfo"):Connect(function(layerData)
            self:TransitionToLayer(layerData)
        end))
    end
    
    -- Listen for anomaly events (lighting shifts)
    local AnomalyService = Knit.GetService("AnomalyService")
    if AnomalyService then
        table.insert(connections, AnomalyService.Client:Get("AnomalyStarted"):Connect(function(data)
            if data.lighting then
                self:ApplyAnomalyLighting(data.lighting)
            end
        end))
        
        table.insert(connections, AnomalyService.Client:Get("AnomalyEnded"):Connect(function()
            self:RevertAnomalyLighting()
        end))
    end

    -- Listen for time-of-day changes
    local TimeService = Knit.GetService("TimeService")
    if TimeService then
        table.insert(connections, TimeService.Client:Get("TimeStateChanged"):Connect(function(data)
            if data.lighting then
                timeOfDayLighting = data.lighting
            end
        end))
    end

    -- Listen for weather changes
    local WeatherService = Knit.GetService("WeatherService")
    if WeatherService then
        table.insert(connections, WeatherService.Client:Get("WeatherStateChanged"):Connect(function(data)
            weatherLighting = data.lighting or {}
            weatherModifiers = data.modifiers or {}
        end))
    end
    
    -- Setup overlays
    self:SetupDepthVignette()
    self:SetupBlurOverlay()

    -- Rendering loop
    RunService:BindToRenderStep("AbyssCamera", Enum.RenderPriority.Camera.Value, function(dt)
        UpdateShake(dt)
        self:ApplyCameraOffset()
        self:UpdateCameraEffects(dt)
    end)
end

function CameraController:TransitionToLayer(layerData)
    -- Smoothly transition fog and lighting to match new layer
    local layer = Config.DepthLayers[layerData.index]
    if not layer then return end
    
    local Lighting = game:GetService("Lighting")
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)

    targetFogColor = layer.Color
    targetFogEnd = layer.FogEnd or 500

    -- Apply Color Correction from config
    if layer.ColorCorrection then
        TweenService:Create(colorCorrection, TweenInfo.new(2), {
            Brightness = layer.ColorCorrection.Brightness or 0,
            Contrast = layer.ColorCorrection.Contrast or 0,
            Saturation = layer.ColorCorrection.Saturation or 0,
            TintColor = layer.ColorCorrection.TintColor or Color3.new(1,1,1)
        }):Play()
    end

    -- Apply Lighting settings
    TweenService:Create(Lighting, TweenInfo.new(2), {
        Ambient = layer.Color:Lerp(Color3.new(0,0,0), 0.8),
        OutdoorAmbient = layer.OutdoorAmbient or layer.Color,
        Brightness = layer.Brightness or 1
    }):Play()

    -- Calculate underwater blend

end

function CameraController:UpdateCameraEffects(dt)
    local speed = dt * 2
    local Lighting = game:GetService("Lighting")

    -- Base fog from layer
    local baseFogColor = targetFogColor
    local baseFogEnd = targetFogEnd

    -- Blend time-of-day lighting into fog
    if timeOfDayLighting then
        baseFogColor = baseFogColor:Lerp(timeOfDayLighting.FogColor or baseFogColor, 0.5)
        baseFogEnd = baseFogEnd * 0.7 + (timeOfDayLighting.FogEnd or baseFogEnd) * 0.3
    end

    -- Blend weather lighting into fog
    if weatherLighting then
        baseFogColor = baseFogColor:Lerp(weatherLighting.TintColor or baseFogColor, 0.3)
        baseFogEnd = baseFogEnd * (weatherLighting.FogMultiplier or 1.0)

        -- Weather ambient/brightness
        local targetAmbient = baseFogColor:Lerp(Color3.new(0, 0, 0), 0.8)
        targetAmbient = targetAmbient * (weatherLighting.AmbientMultiplier or 1.0)
        Lighting.Ambient = Lighting.Ambient:Lerp(targetAmbient, speed)

        local targetBrightness = (Config.DepthLayers[currentLayerIndex] and Config.DepthLayers[currentLayerIndex].Brightness or 1)
        targetBrightness = targetBrightness * (weatherLighting.BrightnessMultiplier or 1.0)
        Lighting.Brightness = Util.Lerp(Lighting.Brightness, targetBrightness, speed)
    end

    -- Apply fog
    Lighting.FogColor = Lighting.FogColor:Lerp(baseFogColor, speed)
    Lighting.FogEnd = Util.Lerp(Lighting.FogEnd, baseFogEnd, speed)

    -- Night particle multiplier — pass to VFXController
    if timeOfDayLighting and timeOfDayLighting.ParticleMultiplier then
        local VFXController = Knit.GetController("VFXController")
        if VFXController and VFXController.SetTimeOfDayMultiplier then
            VFXController:SetTimeOfDayMultiplier(timeOfDayLighting.ParticleMultiplier or 1)
        end
    end

    -- Depth progress
    local depthProgress = Util.DepthToProgress(currentDepth)
end

function CameraController:OnSurface()
    -- Transition back to surface visuals
    targetFogColor = Color3.fromRGB(135, 206, 250) -- Light sky blue
    targetFogEnd = 1000
    underwaterEffect = 0
end

-- ================================================================
-- Anomaly Lighting Effects
-- ================================================================

local savedLayerLighting = {} -- Stores layer lighting before anomaly override

function CameraController:ApplyAnomalyLighting(lightingConfig)
    if not lightingConfig then return end
    
    local Lighting = game:GetService("Lighting")
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    
    -- Save current layer lighting so we can restore it later
    savedLayerLighting = {
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        -- ColorCorrection
        CCBrightness = colorCorrection and colorCorrection.Brightness or 0,
        CCContrast = colorCorrection and colorCorrection.Contrast or 0,
        CCSaturation = colorCorrection and colorCorrection.Saturation or 0,
        CCTintColor = colorCorrection and colorCorrection.TintColor or Color3.new(1, 1, 1),
    }
    
    -- Tween to anomaly lighting
    targetFogColor = lightingConfig.FogColor or Color3.new(0, 0, 0)
    targetFogEnd = lightingConfig.FogEnd or 40
    
    if colorCorrection then
        TweenService:Create(colorCorrection, TweenInfo.new(2), {
            Brightness = lightingConfig.Brightness or 0,
            Contrast = lightingConfig.Contrast or 0.5,
            Saturation = lightingConfig.Saturation or 0,
            TintColor = lightingConfig.TintColor or Color3.new(1, 1, 1),
        }):Play()
    end
    
    TweenService:Create(Lighting, TweenInfo.new(2), {
        Ambient = Color3.new(lightingConfig.AmbientLight or 0.1, lightingConfig.AmbientLight or 0.1, lightingConfig.AmbientLight or 0.1),
        Brightness = lightingConfig.Brightness or 0.5,
    }):Play()
    
    -- Boost bloom for anomaly effects
    if bloom then
        TweenService:Create(bloom, TweenInfo.new(2), {
            Intensity = 1.5,
            Size = 32,
        }):Play()
    end
    
    print("[CameraController] Anomaly lighting applied")
end

function CameraController:RevertAnomalyLighting()
    if not next(savedLayerLighting) then return end
    
    local Lighting = game:GetService("Lighting")
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    
    -- Restore saved layer lighting
    targetFogColor = savedLayerLighting.FogColor
    targetFogEnd = savedLayerLighting.FogEnd
    
    if colorCorrection then
        TweenService:Create(colorCorrection, TweenInfo.new(3), {
            Brightness = savedLayerLighting.CCBrightness,
            Contrast = savedLayerLighting.CCContrast,
            Saturation = savedLayerLighting.CCSaturation,
            TintColor = savedLayerLighting.CCTintColor,
        }):Play()
    end
    
    TweenService:Create(Lighting, TweenInfo.new(3), {
        Ambient = savedLayerLighting.Ambient,
        OutdoorAmbient = savedLayerLighting.OutdoorAmbient,
        Brightness = savedLayerLighting.Brightness,
    }):Play()
    
    -- Restore bloom
    if bloom then
        TweenService:Create(bloom, TweenInfo.new(3), {
            Intensity = 1,
            Size = 24,
        }):Play()
    end
    
    savedLayerLighting = {}
    print("[CameraController] Normal lighting restored")
end

-- ================================================================
-- Camera Shake
-- ================================================================

local shakeIntensity = 0
local shakeDuration = 0
local shakeElapsed = 0
local cameraOffset = Vector3.new(0, 0, 0)

function CameraController:CameraShake(intensity, duration)
    shakeIntensity = intensity or 2
    shakeDuration = duration or 0.3
    shakeElapsed = 0
end

local function UpdateShake(dt)
    if shakeElapsed < shakeDuration then
        shakeElapsed += dt
        local t = shakeElapsed / shakeDuration
        local decay = 1 - t
        local intensity = shakeIntensity * decay
        cameraOffset = Vector3.new(
            (math.random() - 0.5) * intensity * 2,
            (math.random() - 0.5) * intensity * 2,
            (math.random() - 0.5) * intensity * 1
        )
    else
        cameraOffset = Vector3.new(0, 0, 0)
    end
end

-- ================================================================
-- Depth Vignette (ScreenGui overlay)
-- ================================================================

local vignetteFrame = nil

function CameraController:SetupDepthVignette()
    -- Create a ScreenGui for the vignette overlay
    local playerGui = Player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "DepthVignette"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 8
    gui.Parent = playerGui

    vignetteFrame = Instance.new("Frame")
    vignetteFrame.Name = "Vignette"
    vignetteFrame.Size = UDim2.fromScale(1, 1)
    vignetteFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    vignetteFrame.BackgroundTransparency = 1
    vignetteFrame.BorderSizePixel = 0
    vignetteFrame.Parent = gui

    -- Corner corners for vignette effect
    local cornerSize = 0.3
    local function CreateCorner(anchor, pos)
        local c = Instance.new("Frame")
        c.Size = UDim2.fromScale(cornerSize, cornerSize)
        c.AnchorPoint = anchor
        c.Position = pos
        c.BackgroundColor3 = Color3.new(0, 0, 0)
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.Parent = vignetteFrame
        return c
    end

    -- Use a single gradient approach: a frame with UIListLayout and corner images
    -- Simpler: use image corners with gRadient
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 0
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(0.6, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(0.8, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1)),
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 0),
        NumberSequenceKeypoint.new(0.8, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradient.Parent = vignetteFrame
end

function CameraController:UpdateDepthVignette(depth, maxDepth)
    if not vignetteFrame then return end
    local pressure = maxDepth > 0 and math.min(depth / maxDepth, 1) or 0
    -- Pressure 0 = no vignette, pressure 1 = dark edges (0.85 transparency)
    local targetTransparency = 1 - pressure * 0.85
    vignetteFrame.BackgroundTransparency = targetTransparency
end

-- ================================================================
-- Surface Transition Blur
-- ================================================================

function CameraController:PlaySurfaceTransition()
    -- Brief camera distortion effect
    self:CameraShake(1.5, 0.4)

    -- Flash white briefly to simulate light return
    local lighting = game:GetService("Lighting")
    local bloom = lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then
        TweenService:Create(bloom, TweenInfo.new(0.1), { Intensity = 3, Size = 48 }):Play()
        task.delay(0.2, function()
            if bloom then
                TweenService:Create(bloom, TweenInfo.new(0.4), { Intensity = 1, Size = 24 }):Play()
            end
        end)
    end
end

-- ================================================================
-- Blur Effect (ScreenGui based)
-- ================================================================

local blurOverlay = nil

function CameraController:SetupBlurOverlay()
    -- Reuse PlayerGui
    local playerGui = Player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("ScreenBlur") then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ScreenBlur"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9
    gui.Parent = playerGui

    -- Use a frame with slight transparency to simulate blur
    blurOverlay = Instance.new("Frame")
    blurOverlay.Name = "BlurFrame"
    blurOverlay.Size = UDim2.fromScale(1, 1)
    blurOverlay.BackgroundColor3 = Color3.new(0.1, 0.15, 0.3)
    blurOverlay.BackgroundTransparency = 1
    blurOverlay.BorderSizePixel = 0
    blurOverlay.Parent = gui
end

function CameraController:SetBlur(intensity)
    -- intensity: 0 = no blur, 1 = full blur
    if not blurOverlay then return end
    -- We use transparency: 1 = invisible, 0.85 + intensity * 0.15 = visible blur
    local targetTrans = 1 - intensity * 0.15
    TweenService:Create(blurOverlay, TweenInfo.new(0.3), {
        BackgroundTransparency = targetTrans
    }):Play()
end

-- ================================================================
-- Modified Update loop
-- ================================================================

function CameraController:KnitStop()
    -- Disconnect all signal connections to prevent memory leaks
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    
    RunService:UnbindFromRenderStep("AbyssCamera")
    print("[CameraController] Stopped — connections cleaned up")
end

-- Update camera with shake offset
function CameraController:ApplyCameraOffset()
    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = camera.CFrame * CFrame.new(cameraOffset)
    end
end

return CameraController