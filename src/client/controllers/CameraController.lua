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
	
	-- Rendering loop
	RunService:BindToRenderStep("AbyssCamera", Enum.RenderPriority.Camera.Value, function(dt)
		self:UpdateCameraEffects(dt)
	end)
end

function CameraController:TransitionToLayer(layerData)
	-- Smoothly transition fog and lighting to match new layer
	local layer = Config.DepthLayers[layerData.index]
	if not layer then return end
	
	targetFogColor = layer.Color
	-- Fog distance decreases as depth increases
	targetFogEnd = math.max(20, 500 - (layerData.index - 1) * 100)
	
	-- Calculate underwater blend
	underwaterEffect = Util.Lerp(underwaterEffect, 1, 0.1)
end

function CameraController:UpdateCameraEffects(dt)
	local speed = dt * 2
	
	-- Update fog
	Camera.FogColor = Camera.FogColor:Lerp(targetFogColor, speed)
	Camera.FogEnd = Util.Lerp(Camera.FogEnd, targetFogEnd, speed)
	
	-- Underwater blur / distortion effect
	local blurAmount = Util.Clamp(underwaterEffect * 6, 0, 8)
	local depthProgress = Util.DepthToProgress(currentDepth)
end

function CameraController:OnSurface()
	-- Transition back to surface visuals
	targetFogColor = Color3.fromRGB(135, 206, 250) -- Light sky blue
	targetFogEnd = 1000
	underwaterEffect = 0
end

function CameraController:KnitStop()
	RunService:UnbindFromRenderStep("AbyssCamera")
end

return CameraController