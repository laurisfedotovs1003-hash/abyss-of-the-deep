--[[
    AnimatedEnvironmentUtil.lua — Creates animated environmental assets
    Generates swaying kelp, hydrothermal vent effects, fish schools, and
    zone-specific ambient particles. All effects are optimized for mobile
    (low particle rates, simple sine animations, no physics).
]]

local AnimatedEnvironmentUtil = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- ================================================================
-- Public Interface
-- ================================================================

--- Creates a swaying kelp/seaweed stalk.
-- @param position Vector3 — world position for the base of the kelp
-- @param height number — height of the kelp stalk (default 30)
-- @param delayOffset number — random offset for sway phase (default random)
-- @return table { rootPart, handle: function cleanup }
function AnimatedEnvironmentUtil.CreateKelp(position, height, delayOffset)
    height = height or math.random(20, 50)
    local phaseOffset = delayOffset or math.random() * math.pi * 2

    -- Root part (base — anchored, keeps kelp in place)
    local root = Instance.new("Part")
    root.Name = "KelpRoot"
    root.Size = Vector3.new(2, 1, 2)
    root.Position = position
    root.Anchored = true
    root.CanCollide = false
    root.Material = Enum.Material.Grass
    root.Color = Color3.fromRGB(34, 139, 34)
    root.Transparency = 1
    root.Parent = workspace

    -- Stalk segments — a chain of thin anchored parts that rotate smoothly
    local segments = {}
    local numSegments = math.max(3, math.floor(height / 10))
    local segmentHeight = height / numSegments
    local swayAmount = math.random(3, 6) -- degrees of sway

    for i = 1, numSegments do
        local seg = Instance.new("Part")
        seg.Name = "KelpSegment_" .. i
        seg.Size = Vector3.new(1.5, segmentHeight * 0.9, 1.5)
        seg.Position = position + Vector3.new(0, (i - 0.5) * segmentHeight, 0)
        seg.Anchored = true
        seg.CanCollide = false
        seg.Material = Enum.Material.Grass
        seg.Color = Color3.fromRGB(
            34 + math.random(0, 20),
            139 + math.random(0, 20),
            34 + math.random(0, 10)
        )
        seg.CastShadow = false
        seg.Parent = workspace

        -- Add a WeldConstraint so segments move together — each segment
        -- inherits the position from its base position but we rotate it
        -- independently via RunService bind. We CANNOT weld them because
        -- they are anchored — instead we rotate each in place.

        table.insert(segments, seg)
    end

    -- Top frond (wider, slightly different color)
    local frond = Instance.new("Part")
    frond.Name = "KelpFrond"
    frond.Size = Vector3.new(4, 2, 4)
    frond.Position = position + Vector3.new(0, height, 0)
    frond.Anchored = true
    frond.CanCollide = false
    frond.Material = Enum.Material.Grass
    frond.Color = Color3.fromRGB(50, 180, 50)
    frond.Shape = Enum.PartType.Cylinder
    frond.CastShadow = false
    frond.Parent = workspace

    table.insert(segments, frond)

    -- Initial rotation (slight random lean)
    local baseLean = (math.random() - 0.5) * 4
    for _, seg in ipairs(segments) do
        seg.Orientation = Vector3.new(baseLean, 0, baseLean)
    end

    -- Animate swaying using RunService bind
    local bindName = "KelpSway_" .. tostring(position)
    local timeAccum = 0

    local connection = RunService:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value + 1, function(dt)
        timeAccum += dt

        for i, seg in ipairs(segments) do
            -- Each segment sways more at the tip (i / #segments factor)
            local intensity = (i / #segments) * swayAmount
            local speed = 0.8 + (i / #segments) * 0.3
            local phase = phaseOffset + i * 0.5

            local swayX = math.sin(timeAccum * speed + phase) * intensity
            local swayZ = math.cos(timeAccum * speed * 0.7 + phase * 1.3) * intensity * 0.6

            seg.Orientation = Vector3.new(baseLean + swayX, 0, baseLean + swayZ)
        end
    end)

    return {
        rootPart = root,
        segments = segments,
        cleanup = function()
            RunService:UnbindFromRenderStep(bindName)
            for _, seg in ipairs(segments) do
                seg:Destroy()
            end
            root:Destroy()
        end
    }
end

--- Creates a hydrothermal vent with bubble/heat particles.
-- @param position Vector3 — base position of the vent
-- @param height number — chimney height (default 20)
-- @param bubbleColor Color3 — color of emitted bubbles (default DeepPurple)
-- @return table { cleanup: function }
function AnimatedEnvironmentUtil.CreateHydrothermalVent(position, height, bubbleColor)
    height = height or math.random(15, 30)
    local color = bubbleColor or Color3.fromHex("#8B5CF6") -- DeepPurple

    -- Chimney stack (base rock formation)
    local chimney = Instance.new("Part")
    chimney.Name = "VentChimney"
    chimney.Size = Vector3.new(8, height, 8)
    chimney.Position = position + Vector3.new(0, height / 2, 0)
    chimney.Anchored = true
    chimney.CanCollide = false
    chimney.Material = Enum.Material.Basalt
    chimney.Color = Color3.fromRGB(30, 30, 40)
    chimney.CastShadow = false
    chimney.Parent = workspace

    -- Rim detail
    local rim = Instance.new("Part")
    rim.Name = "VentRim"
    rim.Size = Vector3.new(12, 3, 12)
    rim.Position = position + Vector3.new(0, height, 0)
    rim.Anchored = true
    rim.CanCollide = false
    rim.Material = Enum.Material.Rock
    rim.Color = Color3.fromRGB(50, 40, 30)
    rim.CastShadow = false
    rim.Shape = Enum.PartType.Cylinder
    rim.Parent = workspace

    -- Attachment at vent mouth for particles
    local ventAttachment = Instance.new("Attachment")
    ventAttachment.Name = "VentEmission"
    ventAttachment.Position = Vector3.new(0, height + 2, 0)
    ventAttachment.Parent = chimney

    -- Bubble emitter (rising bubble stream)
    local bubbleEmitter = Instance.new("ParticleEmitter")
    bubbleEmitter.Name = "VentBubbles"
    bubbleEmitter.Texture = "rbxassetid://585075134" -- Bubble texture
    bubbleEmitter.Color = ColorSequence.new(color)
    bubbleEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0.1)
    })
    bubbleEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(0.3, 0.2),
        NumberSequenceKeypoint.new(1, 0.9)
    })
    bubbleEmitter.Lifetime = NumberRange.new(2, 5)
    bubbleEmitter.Rate = 8 -- Low rate for mobile
    bubbleEmitter.Speed = NumberRange.new(3, 8)
    bubbleEmitter.SpreadAngle = Vector2.new(10, 10)
    bubbleEmitter.EmissionDirection = Enum.NormalId.Top
    bubbleEmitter.VelocityInheritance = 0.3
    bubbleEmitter.LightEmission = 0.2
    bubbleEmitter.Parent = ventAttachment

    -- Heat haze effect (uses a translucent beam above the vent)
    local heatHaze = Instance.new("Part")
    heatHaze.Name = "VentHeatHaze"
    heatHaze.Size = Vector3.new(4, 20, 4)
    heatHaze.Position = position + Vector3.new(0, height + 12, 0)
    heatHaze.Anchored = true
    heatHaze.CanCollide = false
    heatHaze.Material = Enum.Material.Glass
    heatHaze.Color = color:Lerp(Color3.new(1, 1, 1), 0.3)
    heatHaze.Transparency = 0.85
    heatHaze.CastShadow = false
    heatHaze.Parent = workspace

    -- Subtle wobble animation on the heat haze
    local wobbleBind = "VentWobble_" .. tostring(position)
    local wobbleTime = 0
    local wobbleConn = RunService:BindToRenderStep(wobbleBind, Enum.RenderPriority.Last.Value + 2, function(dt)
        wobbleTime += dt
        local wobbleX = math.sin(wobbleTime * 0.5) * 2
        local wobbleZ = math.cos(wobbleTime * 0.4 + 1.2) * 2
        heatHaze.Orientation = Vector3.new(wobbleX, 0, wobbleZ)

        -- Pulse transparency for shimmer
        heatHaze.Transparency = 0.8 + math.sin(wobbleTime * 1.2) * 0.08
    end)

    -- Glow light at vent mouth (ambient bioluminescence)
    local glowLight = Instance.new("PointLight")
    glowLight.Color = color
    glowLight.Brightness = 2
    glowLight.Range = 15
    glowLight.Parent = rim

    TweenService:Create(glowLight, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Brightness = 4
    }):Play()

    return {
        chimney = chimney,
        rim = rim,
        cleanup = function()
            RunService:UnbindFromRenderStep(wobbleBind)
            chimney:Destroy()
            rim:Destroy()
            heatHaze:Destroy()
        end
    }
end

--- Creates a non-interactable school of fish (particle-based, mobile-friendly).
-- @param centerPosition Vector3 — center of the fish school area
-- @param radius number — radius of the school (default 50)
-- @param particleCount number — particle rate (default 8)
-- @param fishColor Color3 — color tint (default ElectricBlue)
-- @return table { attachment, cleanup: function }
function AnimatedEnvironmentUtil.CreateFishSchool(centerPosition, radius, particleCount, fishColor)
    radius = radius or 50
    particleCount = particleCount or 8
    local color = fishColor or Color3.fromHex("#3B82F6")

    -- Create a transparent anchor part to hold the emitter
    local anchor = Instance.new("Part")
    anchor.Name = "FishSchoolAnchor"
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Position = centerPosition
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.CastShadow = false
    anchor.Parent = workspace

    local attachment = Instance.new("Attachment")
    attachment.Name = "FishSchoolAttachment"
    attachment.Parent = anchor

    -- Fish particles — use a simple fish-like texture
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "FishSchool"
    emitter.Texture = "rbxassetid://2442214466" -- Sparkle/star — reads as small fish at distance
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
        ColorSequenceKeypoint.new(1, color)
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 0.8)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.6)
    })
    emitter.Lifetime = NumberRange.new(3, 6)
    emitter.Rate = particleCount
    emitter.Speed = NumberRange.new(5, 12)
    emitter.SpreadAngle = Vector2.new(60, 60)
    emitter.EmissionDirection = Enum.NormalId.Right
    emitter.VelocityInheritance = 0.2
    emitter.RotSpeed = NumberRange.new(-90, 90)
    emitter.RotType = Enum.ParticleRotationType.VelocityRelative
    emitter.LightEmission = 0.1
    emitter.Parent = attachment

    -- Make the school drift slowly
    local driftBind = "FishDrift_" .. tostring(centerPosition)
    local driftTime = 0
    local driftConn = RunService:BindToRenderStep(driftBind, Enum.RenderPriority.Last.Value + 3, function(dt)
        driftTime += dt
        -- Slow circular drift
        local driftX = math.sin(driftTime * 0.05) * radius * 0.3
        local driftZ = math.cos(driftTime * 0.07) * radius * 0.3
        anchor.Position = centerPosition + Vector3.new(driftX, math.sin(driftTime * 0.03) * 10, driftZ)
    end)

    return {
        anchor = anchor,
        attachment = attachment,
        emitter = emitter,
        cleanup = function()
            RunService:UnbindFromRenderStep(driftBind)
            anchor:Destroy()
        end
    }
end

--- Returns zone-specific marine snow config overrides.
-- @param zoneIndex number 1=Sunlight, 2=Twilight, 3=Midnight
-- @return table { rate, size, color, transparency, speed }
function AnimatedEnvironmentUtil.GetMarineSnowConfig(zoneIndex)
    local configs = {
        [1] = { -- Sunlight Zone — gentle, bright, sparse
            rate = 40,
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.03),
                NumberSequenceKeypoint.new(0.5, 0.08),
                NumberSequenceKeypoint.new(1, 0.03)
            }),
            color = ColorSequence.new(Color3.fromRGB(200, 220, 255)),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.6),
                NumberSequenceKeypoint.new(1, 1)
            }),
            speed = NumberRange.new(0.1, 0.2),
        },
        [2] = { -- Twilight Zone — denser, slightly blue-green
            rate = 80,
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.5, 0.12),
                NumberSequenceKeypoint.new(1, 0.05)
            }),
            color = ColorSequence.new(Color3.fromRGB(150, 200, 200)),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.15, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            }),
            speed = NumberRange.new(0.15, 0.3),
        },
        [3] = { -- Midnight Zone — heavy, slow, bioluminescent
            rate = 120,
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.08),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(1, 0.08)
            }),
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 200, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 255))
            }),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0.3),
                NumberSequenceKeypoint.new(0.7, 0.4),
                NumberSequenceKeypoint.new(1, 1)
            }),
            speed = NumberRange.new(0.1, 0.2),
        },
    }
    return configs[zoneIndex] or configs[1]
end

--- Returns zone-specific light shaft configuration.
-- @param zoneIndex number 1=Sunlight, 2=Twilight, 3=Midnight
-- @return table { count, color, size, transparency }
function AnimatedEnvironmentUtil.GetLightShaftConfig(zoneIndex)
    local configs = {
        [1] = { -- Sunlight — many bright blue shafts from above
            count = 10,
            color = Color3.fromHex("#3B82F6"),
            size = Vector3.new(12, 500, 12),
            transparency = 0.96,
            yBase = 200,
        },
        [2] = { -- Twilight — fewer, dimmer, angled
            count = 5,
            color = Color3.fromHex("#1E3A5F"),
            size = Vector3.new(8, 400, 8),
            transparency = 0.97,
            yBase = -200,
        },
        [3] = { -- Midnight — very few, thin, eerie
            count = 3,
            color = Color3.fromHex("#8B5CF6"),
            size = Vector3.new(4, 300, 4),
            transparency = 0.98,
            yBase = -1000,
        },
    }
    return configs[zoneIndex] or configs[1]
end

return AnimatedEnvironmentUtil
