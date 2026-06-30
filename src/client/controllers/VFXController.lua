--[[
	VFXController — Manages client-side visual effects
	Handles atmospheric particles, swimming effects, and feedback VFX.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local VFXUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("VFXUtil"))

local VFXController = Knit.CreateController {
	Name = "VFXController",
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- State
local activeEmitters = {}
local activeTrails = {}

function VFXController:KnitStart()
	print("[VFXController] Initialized")
	
	-- Setup constant atmospheric VFX
	self:SetupMarineSnow()
	self:SetupLightShafts()
	
	-- Listen for local swimming state
	RunService:BindToRenderStep("VFXUpdate", Enum.RenderPriority.Last.Value, function(dt)
		self:UpdateSwimmingEffects(dt)
	end)

	-- Handle character spawning for trails/bubbles attachments
	Player.CharacterAdded:Connect(function(character)
		self:SetupCharacterVFX(character)
	end)
	
	if Player.Character then
		self:SetupCharacterVFX(Player.Character)
	end
end

function VFXController:SetupCharacterVFX(character)
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Create attachment for swimming bubbles
	local bubbleAttachment = Instance.new("Attachment")
	bubbleAttachment.Name = "BubbleAttachment"
	bubbleAttachment.Parent = rootPart
	
	-- Create Trail for swimming
	local trail = Instance.new("Trail")
	trail.Name = "SwimmingTrail"
	-- Try to find feet for attachment points
	local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
	local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
	
	if leftFoot and rightFoot then
		trail.Attachment0 = Instance.new("Attachment", leftFoot)
		trail.Attachment1 = Instance.new("Attachment", rightFoot)
	else
		-- Fallback to rootpart attachments
		trail.Attachment0 = Instance.new("Attachment", rootPart)
		trail.Attachment1 = Instance.new("Attachment", rootPart)
		trail.Attachment1.Position = Vector3.new(0, -2, 0)
	end
	
	trail.Color = ColorSequence.new(VFXUtil.Colors.ElectricBlue)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.5
	trail.Enabled = false
	trail.Parent = rootPart
	activeTrails[character] = trail

	-- Create swimming bubbles emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SwimmingBubbles"
	emitter.Texture = "rbxassetid://585075134" -- Bubble texture
	emitter.Size = NumberSequence.new(0.1, 0.3)
	emitter.Transparency = NumberSequence.new(0, 0.8)
	emitter.Lifetime = NumberRange.new(0.5, 1.5)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(2, 5)
	emitter.VelocityInheritance = 0.5
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = bubbleAttachment
	activeEmitters[character] = emitter

	-- Surface Splash Detection
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Swimming or oldState == Enum.HumanoidStateType.Swimming then
			self:PlaySurfaceSplash(rootPart.Position)
		end
	end)
end

function VFXController:PlaySurfaceSplash(position)
	local splashPart = Instance.new("Part")
	splashPart.Size = Vector3.new(1, 1, 1)
	splashPart.Transparency = 1
	splashPart.Anchored = true
	splashPart.CanCollide = false
	splashPart.Position = position
	splashPart.Parent = workspace.Terrain
	
	local attachment = Instance.new("Attachment", splashPart)
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://290610311" -- Water splash
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	emitter.Size = NumberSequence.new(1, 5)
	emitter.Transparency = NumberSequence.new(0.5, 1)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(5, 15)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = attachment
	
	emitter:Emit(30)
	
	task.delay(1.5, function()
		splashPart:Destroy()
	end)
end

function VFXController:SetupLightShafts()
	-- Create god rays for the Sunlight zone
	local folder = workspace:FindFirstChild("AtmosphericVFX") or Instance.new("Folder", workspace)
	folder.Name = "AtmosphericVFX"
	
	for i = 1, 10 do
		local shaft = Instance.new("Part")
		shaft.Name = "LightShaft"
		shaft.Size = Vector3.new(10, 500, 10)
		shaft.Position = Vector3.new(math.random(-500, 500), 200, math.random(-500, 500))
		shaft.Orientation = Vector3.new(0, 0, 15)
		shaft.CastShadow = false
		shaft.CanCollide = false
		shaft.Anchored = true
		shaft.Material = Enum.Material.SmoothPlastic
		shaft.Transparency = 0.95
		shaft.Color = VFXUtil.Colors.ElectricBlue
		shaft.Parent = folder
		
		-- Subtle pulse to make them feel alive
		VFXUtil.Pulse(shaft, shaft.Color, Color3.new(1, 1, 1), 5 + math.random())
	end
end

function VFXController:SetupMarineSnow()
	-- Marine snow is essential for deep-sea atmosphere
	local camera = workspace.CurrentCamera
	local snowAttachment = camera:FindFirstChild("MarineSnowAttachment") or Instance.new("Attachment")
	snowAttachment.Name = "MarineSnowAttachment"
	snowAttachment.Parent = camera
	
	local emitter = snowAttachment:FindFirstChild("MarineSnow") or Instance.new("ParticleEmitter")
	emitter.Name = "MarineSnow"
	emitter.Texture = "rbxassetid://6031735118"
	emitter.Color = ColorSequence.new(Color3.new(0.8, 0.9, 1))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 0.05)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(4, 8)
	emitter.Rate = 100
	emitter.Speed = NumberRange.new(0.1, 0.3)
	emitter.VelocityInheritance = 0.1
	emitter.EmissionDirection = Enum.NormalId.Back
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = snowAttachment
end

function VFXController:UpdateSwimmingEffects(dt)
	local character = Player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end
	
	local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
	local speed = rootPart.AssemblyLinearVelocity.Magnitude
	
	-- Update Bubbles and Trails
	local emitter = activeEmitters[character]
	local trail = activeTrails[character]
	
	if isSwimming and speed > 5 then
		if emitter then emitter.Rate = speed * 2 end
		if trail then trail.Enabled = true end
	else
		if emitter then emitter.Rate = 0 end
		if trail then trail.Enabled = false end
	end
end

function VFXController:PlayCollectionEffect(position, color)
	local attachment = Instance.new("Attachment")
	attachment.Position = position
	attachment.Parent = workspace.Terrain
	
	-- Burst Emitter
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxassetid://2442214466" -- Sparkle/Star
	burst.Color = ColorSequence.new(color or VFXUtil.Colors.CyanGlow)
	burst.Size = NumberSequence.new(0.5, 0)
	burst.Lifetime = NumberRange.new(0.3, 0.6)
	burst.Speed = NumberRange.new(10, 20)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.Parent = attachment
	burst:Emit(20)
	
	-- Light burst
	local light = Instance.new("PointLight")
	light.Color = color or VFXUtil.Colors.CyanGlow
	light.Range = 15
	light.Brightness = 8
	light.Parent = attachment
	
	TweenService:Create(light, TweenInfo.new(0.5), {Brightness = 0}):Play()
	
	task.delay(1, function()
		attachment:Destroy()
	end)
end

return VFXController
