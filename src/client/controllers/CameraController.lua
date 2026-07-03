--[[
    CameraController — Manages underwater camera effects and transitions
    Handles depth-based fog, color tinting, and immersive camera behavior.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local CameraController = Knit.CreateController {
    Name = "CameraController",
}

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- State
local currentLayerIndex = 1
local currentDepth = 0
local targetFogColor = Color3.fromRGB(30, 144, 255)
local targetFogEnd = 500
local underwaterEffect = 0 -- 0 = surface, 1 = fully underwater

function CameraController:KnitStart()
    print("[CameraController] Initialized")
    
    -- Listen for depth updates from DepthService
    local DepthService = Knit.GetService("DepthService")
    if DepthService then
        DepthService.Client:Get("GetDepthData"):Connect(function(data)
            currentDepth = data.depth or 0
            currentLayerIndex = data.layerIndex or 1
        end)
        
        DepthService.Client:Get("GetLayerInfo"):Connect(function(layerData)
            self:TransitionToLayer(layerData)
        end)
    end
    
    -- Listen for anomaly events (lighting shifts)
    local AnomalyService = Knit.GetService("AnomalyService")
    if AnomalyService then
        AnomalyService.Client:Get("AnomalyStarted"):Connect(function(data)
            if data.lighting then
                self:ApplyAnomalyLighting(data.lighting)
            end
        end)
        
        AnomalyService.Client:Get("AnomalyEnded"):Connect(function()
            self:RevertAnomalyLighting()
        end)
    end
    
    -- Rendering loop
    RunService:BindToRenderStep("AbyssCamera", Enum.RenderPriority.Camera.Value, function(dt)
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

    -- Update fog
    Lighting.FogColor = Lighting.FogColor:Lerp(targetFogColor, speed)
    Lighting.FogEnd = Util.Lerp(Lighting.FogEnd, targetFogEnd, speed)

    -- Underwater blur / distortion effect
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

function CameraController:KnitStop()
    RunService:UnbindFromRenderStep("AbyssCamera")
end

return CameraController