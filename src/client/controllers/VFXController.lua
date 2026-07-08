--[[
    VFXController — Manages client-side visual effects
    Handles atmospheric particles, zone-specific VFX, swimming effects, and feedback VFX.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local VFXUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("VFXUtil"))
local AnimatedEnvironment = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("AnimatedEnvironmentUtil"))

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
local zoneVFXObjects = {
    kelpStalks = {},
    vents = {},
    fishSchools = {},
    lightShafts = {},
}
local currentZoneIndex = 1
local lastZoneIndex = 1
local marineSnowEmitter = nil

function VFXController:KnitStart()
    print("[VFXController] Initialized")

    -- Setup constant atmospheric VFX
    self:SetupMarineSnow()
    self:SetupLightShafts()

    -- Setup zone-specific animated environment (default Zone 1)
    self:SetupZoneEnvironment(1)

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

    -- Listen for zone transitions from DepthService
    local DepthService = Knit.GetService("DepthService")
    if DepthService then
        DepthService.Client:Get("GetLayerInfo"):Connect(function(layerData)
            if layerData and layerData.index then
                currentZoneIndex = layerData.index
            end
        end)

        DepthService.Client:Get("GetDepthData"):Connect(function(data)
            if data and data.layerIndex then
                currentZoneIndex = data.layerIndex
            end
        end)
    end

    -- Update zone environment every 2 seconds (debounced zone check)
    RunService:BindToRenderStep("ZoneVFXCheck", Enum.RenderPriority.Camera.Value + 1, function()
        if currentZoneIndex ~= lastZoneIndex then
            lastZoneIndex = currentZoneIndex
            self:TransitionZoneVFX(currentZoneIndex)
        end
    end)
end

-- ================================================================
-- Zone Environment Management
-- ================================================================

function VFXController:TransitionZoneVFX(zoneIndex)
    -- Clamp to zones 1-3 for alpha
    zoneIndex = math.max(1, math.min(zoneIndex or 1, 3))
    if zoneIndex == lastZoneIndex then return end

    print("[VFXController] Transitioning to Zone", zoneIndex)

    -- Update marine snow for current zone
    self:UpdateMarineSnowForZone(zoneIndex)

    -- Update light shafts for current zone
    self:UpdateLightShaftsForZone(zoneIndex)

    -- Update zone environment assets
    self:SetupZoneEnvironment(zoneIndex)
end

function VFXController:SetupZoneEnvironment(zoneIndex)
    -- Clean up previous zone environment
    self:CleanupZoneEnvironment()

    if zoneIndex == 1 then
        -- Sunlight Zone: kelp forests + fish schools
        self:SetupKelpForest()
        self:SetupFishSchools()
    elseif zoneIndex == 2 then
        -- Twilight Zone: sparse kelp + some ambient particles
        self:SetupKelpForest(8, 0.5) -- fewer, smaller kelp
    elseif zoneIndex == 3 then
        -- Midnight Zone: hydrothermal vents + deep sea particles
        self:SetupHydrothermalVents()
    end
end

function VFXController:CleanupZoneEnvironment()
    for _, obj in ipairs(zoneVFXObjects.kelpStalks) do
        if obj.cleanup then obj.cleanup() end
    end
    for _, obj in ipairs(zoneVFXObjects.vents) do
        if obj.cleanup then obj.cleanup() end
    end
    for _, obj in ipairs(zoneVFXObjects.fishSchools) do
        if obj.cleanup then obj.cleanup() end
    end

    zoneVFXObjects.kelpStalks = {}
    zoneVFXObjects.vents = {}
    zoneVFXObjects.fishSchools = {}
end

-- ================================================================
-- Kelp Forest (Zone 1 primary, Zone 2 sparse)
-- ================================================================

function VFXController:SetupKelpForest(count, heightScale)
    count = count or 25
    heightScale = heightScale or 1.0
    local wellRadius = 180

    for i = 1, count do
        local x = math.random(-wellRadius + 20, wellRadius - 20)
        local z = math.random(-wellRadius + 20, wellRadius - 20)
        local y = -math.random(10, 180)
        local height = math.random(15, 40) * heightScale

        -- Only place in the correct depth range
        if currentZoneIndex == 1 then
            -- Kelp in Sunlight Zone (0 to -200)
            y = -math.random(10, 180)
            height = math.random(20, 50)
        elseif currentZoneIndex == 2 then
            -- Sparse kelp-like growth in Twilight (200 to 1000)
            y = -math.random(250, 800)
            height = math.random(10, 25)
        end

        local kelp = AnimatedEnvironment.CreateKelp(
            Vector3.new(x, y, z),
            height,
            math.random() * math.pi * 2
        )
        table.insert(zoneVFXObjects.kelpStalks, kelp)
    end

    print("[VFXController] Kelp forest placed:", count, "stalks")
end

-- ================================================================
-- School of Fish (Zone 1 only)
-- ================================================================

function VFXController:SetupFishSchools()
    local wellRadius = 160

    -- Place 3-4 fish schools scattered around Sunlight Zone
    for i = 1, 4 do
        local x = math.random(-wellRadius + 30, wellRadius - 30)
        local z = math.random(-wellRadius + 30, wellRadius - 30)
        local y = -math.random(20, 150)

        local school = AnimatedEnvironment.CreateFishSchool(
            Vector3.new(x, y, z),
            40,     -- radius
            6,      -- particle rate (mobile-optimized)
            Color3.fromRGB(59, 130, 246) -- ElectricBlue
        )
        table.insert(zoneVFXObjects.fishSchools, school)
    end

    print("[VFXController] Fish schools placed:", 4)
end

-- ================================================================
-- Hydrothermal Vents (Zone 3 only)
-- ================================================================

function VFXController:SetupHydrothermalVents()
    local wellRadius = 170

    -- Place 3-5 vents in Midnight Zone
    for i = 1, 4 do
        local x = math.random(-wellRadius + 40, wellRadius - 40)
        local z = math.random(-wellRadius + 40, wellRadius - 40)
        local y = -math.random(1200, 3500)

        local colors = {
            Color3.fromHex("#8B5CF6"), -- DeepPurple
            Color3.fromHex("#00E5FF"), -- CyanGlow
            Color3.fromHex("#39FF14"), -- BioGreen
        }
        local ventColor = colors[math.random(1, #colors)]

        local vent = AnimatedEnvironment.CreateHydrothermalVent(
            Vector3.new(x, y, z),
            math.random(15, 35),
            ventColor
        )
        table.insert(zoneVFXObjects.vents, vent)
    end

    print("[VFXController] Hydrothermal vents placed:", 4)
end

-- ================================================================
-- Marine Snow (per-zone variation)
-- ================================================================

function VFXController:SetupMarineSnow()
    -- Create the attachment on the camera if it doesn't exist
    local camera = workspace.CurrentCamera
    local snowAttachment = camera:FindFirstChild("MarineSnowAttachment") or Instance.new("Attachment")
    snowAttachment.Name = "MarineSnowAttachment"
    snowAttachment.Parent = camera

    -- Remove old emitter if present
    local oldEmitter = snowAttachment:FindFirstChild("MarineSnow")
    if oldEmitter then
        oldEmitter:Destroy()
    end

    -- Start with Sunlight Zone config
    local config = AnimatedEnvironment.GetMarineSnowConfig(1)

    marineSnowEmitter = Instance.new("ParticleEmitter")
    marineSnowEmitter.Name = "MarineSnow"
    marineSnowEmitter.Texture = "rbxassetid://6031735118"
    marineSnowEmitter.Color = config.color
    marineSnowEmitter.Size = config.size
    marineSnowEmitter.Transparency = config.transparency
    marineSnowEmitter.Lifetime = NumberRange.new(4, 8)
    marineSnowEmitter.Rate = config.rate
    marineSnowEmitter.Speed = config.speed
    marineSnowEmitter.VelocityInheritance = 0.1
    marineSnowEmitter.EmissionDirection = Enum.NormalId.Back
    marineSnowEmitter.SpreadAngle = Vector2.new(180, 180)
    marineSnowEmitter.Parent = snowAttachment
end

function VFXController:UpdateMarineSnowForZone(zoneIndex)
    if not marineSnowEmitter then return end

    local config = AnimatedEnvironment.GetMarineSnowConfig(zoneIndex)

    -- Tween particle properties for a smooth transition
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    TweenService:Create(marineSnowEmitter, tweenInfo, {
        Rate = config.rate,
        Speed = config.speed,
    }):Play()

    -- Color, size, and transparency need to be set directly (not tweenable on ParticleEmitter)
    marineSnowEmitter.Color = config.color
    marineSnowEmitter.Size = config.size
    marineSnowEmitter.Transparency = config.transparency
end

-- ================================================================
-- Light Shafts (per-zone variation)
-- ================================================================

function VFXController:SetupLightShafts()
    -- Start with Zone 1 config
    self:UpdateLightShaftsForZone(1)
end

function VFXController:UpdateLightShaftsForZone(zoneIndex)
    local config = AnimatedEnvironment.GetLightShaftConfig(zoneIndex)
    local shaftColor = config.color
    local shaftSize = config.size
    local transparency = config.transparency
    local count = config.count
    local yBase = config.yBase

    -- Clean up existing shafts
    for _, shaft in ipairs(zoneVFXObjects.lightShafts) do
        shaft:Destroy()
    end
    zoneVFXObjects.lightShafts = {}

    local folder = workspace:FindFirstChild("AtmosphericVFX") or Instance.new("Folder", workspace)
    folder.Name = "AtmosphericVFX"

    for i = 1, count do
        local shaft = Instance.new("Part")
        shaft.Name = "LightShaft"
        shaft.Size = shaftSize
        shaft.Position = Vector3.new(
            math.random(-350, 350),
            yBase + math.random(-50, 50),
            math.random(-350, 350)
        )
        shaft.Orientation = Vector3.new(
            math.random(-5, 5),
            0,
            math.random(10, 20)
        )
        shaft.CastShadow = false
        shaft.CanCollide = false
        shaft.Anchored = true
        shaft.Material = Enum.Material.SmoothPlastic
        shaft.Transparency = transparency + (math.random() - 0.5) * 0.02
        shaft.Color = shaftColor
        shaft.Parent = folder

        table.insert(zoneVFXObjects.lightShafts, shaft)

        -- Subtle pulse effect
        VFXUtil.Pulse(shaft, shaftColor, Color3.new(1, 1, 1), 5 + math.random() * 5)
    end
end

-- ================================================================
-- Character VFX (swimming bubbles, trails)
-- ================================================================

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

-- ================================================================
-- Update Loop
-- ================================================================

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

-- ================================================================
-- Feedback VFX
-- ================================================================

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

function VFXController:KnitStop()
    RunService:UnbindFromRenderStep("VFXUpdate")
    RunService:UnbindFromRenderStep("ZoneVFXCheck")
    self:CleanupZoneEnvironment()
end

return VFXController