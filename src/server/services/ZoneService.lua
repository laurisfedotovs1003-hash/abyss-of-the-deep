--[[
    ZoneService.lua — Manages physical world geometry and environmental zones
    Responsible for generating the playable Alpha Map (Zones 1-3).
]]

local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local VFXUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("VFXUtil"))
local AnimatedEnvironment = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("AnimatedEnvironmentUtil"))

local ZoneService = Knit.CreateService {
    Name = "ZoneService",
    Client = {},
}

-- Constants
local WELL_RADIUS = 200
local WELL_DEPTH_TOTAL = 4000 -- Covers Sunlight, Twilight, and Midnight
local WALL_THICKNESS = 20

-- Folder for map geometry
local MapFolder

-- Tracked animated environment objects for cleanup
local animatedKelp = {}
local animatedVents = {}
local animatedFishSchools = {}

-- ============================================================
-- Initialization
-- ============================================================

function ZoneService:KnitStart()
    print("[ZoneService] Initialized — Building Alpha Map...")

    -- Setup Map Container
    MapFolder = workspace:FindFirstChild("Map") or Instance.new("Folder")
    MapFolder.Name = "Map"
    MapFolder.Parent = workspace

    self:BuildSurfaceHub()
    self:BuildDescentWell()
    self:PopulateZones()
    self:BuildHubProps()
end

-- ============================================================
-- Hub Props
-- ============================================================

function ZoneService:BuildHubProps()
    -- Add some structural buildings to the hub for a "Research Center" feel
    local hubProps = Instance.new("Folder")
    hubProps.Name = "HubProps"
    hubProps.Parent = MapFolder

    -- Main Lab Building
    local lab = Instance.new("Part")
    lab.Name = "ResearchLab"
    lab.Size = Vector3.new(100, 40, 80)
    lab.Position = Vector3.new(0, 30, 210)
    lab.Anchored = true
    lab.Material = Enum.Material.SmoothPlastic
    lab.Color = Color3.fromRGB(200, 200, 200)
    lab.Parent = hubProps

    -- Windows for the Lab
    local window = Instance.new("Part")
    window.Name = "LabWindow"
    window.Size = Vector3.new(80, 20, 1)
    window.Position = Vector3.new(0, 30, 170)
    window.Anchored = true
    window.Material = Enum.Material.Glass
    window.Color = Color3.fromRGB(150, 200, 255)
    window.Transparency = 0.5
    window.Parent = hubProps

    -- Submersible Gantry
    local gantry = Instance.new("Part")
    gantry.Name = "SubGantry"
    gantry.Size = Vector3.new(20, 100, 20)
    gantry.Position = Vector3.new(150, 50, 0)
    gantry.Anchored = true
    gantry.Material = Enum.Material.Metal
    gantry.Color = Color3.fromRGB(50, 50, 50)
    gantry.Parent = hubProps

    local crane = gantry:Clone()
    crane.Name = "SubCrane"
    crane.Size = Vector3.new(80, 10, 10)
    crane.Position = Vector3.new(110, 95, 0)
    crane.Parent = hubProps

    print("[ZoneService] Hub Props Built")
end

-- ============================================================
-- Geometry Building
-- ============================================================

function ZoneService:BuildSurfaceHub()
    -- The Surface Hub is where players start
    local hub = Instance.new("Part")
    hub.Name = "SurfaceHub"
    hub.Size = Vector3.new(500, 10, 500)
    hub.Position = Vector3.new(0, 5, 0)
    hub.Anchored = true
    hub.Material = Enum.Material.Concrete
    hub.Color = Color3.fromRGB(100, 100, 100)
    hub.Parent = MapFolder

    -- Create a hole for the descent
    -- In a real scenario, we'd use multiple parts to form a hole
    -- For now, let's just make the hub a ring or a platform with a gap
    hub.Transparency = 1
    hub.CanCollide = false

    -- Real platform parts
    local p1 = hub:Clone()
    p1.Name = "Platform_North"
    p1.Size = Vector3.new(500, 10, 150)
    p1.Position = Vector3.new(0, 5, 175)
    p1.Transparency = 0
    p1.CanCollide = true
    p1.Parent = MapFolder

    local p2 = p1:Clone()
    p2.Name = "Platform_South"
    p2.Position = Vector3.new(0, 5, -175)
    p2.Parent = MapFolder

    local p3 = p1:Clone()
    p3.Name = "Platform_East"
    p3.Size = Vector3.new(150, 10, 200)
    p3.Position = Vector3.new(175, 5, 0)
    p3.Parent = MapFolder

    local p4 = p3:Clone()
    p4.Name = "Platform_West"
    p4.Position = Vector3.new(-175, 5, 0)
    p4.Parent = MapFolder

    -- Spawn Location
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SurfaceSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 10.5, 150)
    spawn.Anchored = true
    spawn.Parent = MapFolder

    print("[ZoneService] Surface Hub Built")
end

function ZoneService:BuildDescentWell()
    -- Build the walls of the descent path
    local wellContainer = Instance.new("Folder")
    wellContainer.Name = "DescentWell"
    wellContainer.Parent = MapFolder

    -- We'll build the well in segments corresponding to depth layers
    for i = 1, 3 do -- Zones 1-3 (Sunlight, Twilight, Midnight)
        local layer = Config.DepthLayers[i]
        local segmentDepth = layer.DepthMax - layer.DepthMin
        local segmentY = -(layer.DepthMin + segmentDepth/2)

        -- Create 4 walls for this segment
        local wallSizeH = Vector3.new(WELL_RADIUS * 2 + WALL_THICKNESS, segmentDepth, WALL_THICKNESS)
        local wallSizeV = Vector3.new(WALL_THICKNESS, segmentDepth, WELL_RADIUS * 2 + WALL_THICKNESS)

        local north = Instance.new("Part")
        north.Name = layer.Name .. "_Wall_North"
        north.Size = wallSizeH
        north.Position = Vector3.new(0, segmentY, WELL_RADIUS)
        north.Anchored = true
        north.Material = Enum.Material.Rock
        north.Color = layer.Color:Lerp(Color3.new(0,0,0), 0.5)
        north.Parent = wellContainer

        local south = north:Clone()
        south.Name = layer.Name .. "_Wall_South"
        south.Position = Vector3.new(0, segmentY, -WELL_RADIUS)
        south.Parent = wellContainer

        local east = Instance.new("Part")
        east.Name = layer.Name .. "_Wall_East"
        east.Size = wallSizeV
        east.Position = Vector3.new(WELL_RADIUS, segmentY, 0)
        east.Anchored = true
        east.Material = Enum.Material.Rock
        east.Color = north.Color
        east.Parent = wellContainer

        local west = east:Clone()
        west.Name = layer.Name .. "_Wall_West"
        west.Position = Vector3.new(-WELL_RADIUS, segmentY, 0)
        west.Parent = wellContainer
    end

    print("[ZoneService] Descent Well Built (Zones 1-3)")
end

function ZoneService:PopulateZones()
    -- Add environmental details to each zone
    -- Uses AnimatedEnvironmentUtil for dynamic, immersive assets

    self:PopulateSunlightZone()
    self:PopulateTwilightZone()
    self:PopulateMidnightZone()

    print("[ZoneService] Environmental Population Complete")
end

-- ============================================================
-- Zone 1: Sunlight Zone (0-200m)
-- Animated kelp forests + fish schools + glowing corals
-- ============================================================

function ZoneService:PopulateSunlightZone()
    -- Animated swaying kelp stalks (25-30 stalks)
    for i = 1, 30 do
        local x = math.random(-WELL_RADIUS + 20, WELL_RADIUS - 20)
        local z = math.random(-WELL_RADIUS + 20, WELL_RADIUS - 20)
        local y = -math.random(10, 180)
        local height = math.random(20, 50)

        local kelp = AnimatedEnvironment.CreateKelp(
            Vector3.new(x, y, z),
            height,
            math.random() * math.pi * 2
        )
        table.insert(animatedKelp, kelp)
    end

    -- Scattered coral/reef structures (decorative anchored parts)
    for i = 1, 15 do
        local coral = Instance.new("Part")
        coral.Name = "Coral"
        coral.Size = Vector3.new(math.random(3, 8), math.random(3, 8), math.random(3, 8))
        coral.Position = Vector3.new(
            math.random(-WELL_RADIUS + 20, WELL_RADIUS - 20),
            -math.random(10, 180),
            math.random(-WELL_RADIUS + 20, WELL_RADIUS - 20)
        )
        coral.Anchored = true
        coral.CanCollide = false
        coral.Material = Enum.Material.SmoothPlastic
        coral.Color = Color3.fromRGB(math.random(200, 255), math.random(100, 150), math.random(100, 150))
        coral.CastShadow = false
        coral.Shape = Enum.PartType.Ball
        coral.Parent = MapFolder
    end

    -- Sand patches on the sea floor
    for i = 1, 10 do
        local sand = Instance.new("Part")
        sand.Name = "SandPatch"
        sand.Size = Vector3.new(math.random(20, 50), 1, math.random(20, 50))
        sand.Position = Vector3.new(
            math.random(-WELL_RADIUS + 30, WELL_RADIUS - 30),
            -math.random(180, 195),
            math.random(-WELL_RADIUS + 30, WELL_RADIUS - 30)
        )
        sand.Anchored = true
        sand.CanCollide = false
        sand.Material = Enum.Material.Sand
        sand.Color = Color3.fromRGB(194, 178, 128)
        sand.CastShadow = false
        sand.Parent = MapFolder
    end
end

-- ============================================================
-- Zone 2: Twilight Zone (200-1000m)
-- Glowing anemones, rock formations, sparse kelp
-- ============================================================

function ZoneService:PopulateTwilightZone()
    -- Sparse animated kelp-like growth (half as many, shorter)
    for i = 1, 12 do
        local x = math.random(-WELL_RADIUS + 25, WELL_RADIUS - 25)
        local z = math.random(-WELL_RADIUS + 25, WELL_RADIUS - 25)
        local y = -math.random(300, 900)
        local height = math.random(10, 25)

        local kelp = AnimatedEnvironment.CreateKelp(
            Vector3.new(x, y, z),
            height,
            math.random() * math.pi * 2
        )
        table.insert(animatedKelp, kelp)
    end

    -- Glowing bioluminescent rock formations
    for i = 1, 15 do
        local bioRock = Instance.new("Part")
        bioRock.Name = "BioRock"
        bioRock.Size = Vector3.new(math.random(10, 20), math.random(10, 20), math.random(10, 20))
        bioRock.Position = Vector3.new(
            math.random(-WELL_RADIUS + 30, WELL_RADIUS - 30),
            -math.random(250, 950),
            math.random(-WELL_RADIUS + 30, WELL_RADIUS - 30)
        )
        bioRock.Anchored = true
        bioRock.CanCollide = false
        bioRock.Material = Enum.Material.Basalt
        bioRock.CastShadow = false
        bioRock.Parent = MapFolder

        -- Add a glowing anemone on top
        local glow = Instance.new("Part")
        glow.Size = Vector3.new(3, 6, 3)
        glow.Position = bioRock.Position + Vector3.new(0, bioRock.Size.Y/2, 0)
        glow.Anchored = true
        glow.CanCollide = false
        glow.CastShadow = false
        glow.Parent = bioRock

        local glowColor = Color3.fromRGB(
            math.random(50, 200),
            math.random(200, 255),
            math.random(100, 200)
        )
        VFXUtil.ApplyBioluminescence(glow, glowColor, 3)
        VFXUtil.Pulse(glow, glowColor, Color3.new(1, 1, 1), 2 + math.random() * 2)
    end

    -- Rocky outcroppings (terrain-like structures)
    for i = 1, 8 do
        local rock = Instance.new("Part")
        rock.Name = "TwilightRock"
        rock.Size = Vector3.new(math.random(15, 35), math.random(15, 30), math.random(15, 35))
        rock.Position = Vector3.new(
            math.random(-WELL_RADIUS + 25, WELL_RADIUS - 25),
            -math.random(300, 900),
            math.random(-WELL_RADIUS + 25, WELL_RADIUS - 25)
        )
        rock.Anchored = true
        rock.CanCollide = false
        rock.Material = Enum.Material.Basalt
        rock.Color = Color3.fromRGB(40, 40, 50)
        rock.CastShadow = false
        rock.Parent = MapFolder
    end
end

-- ============================================================
-- Zone 3: Midnight Zone (1000-4000m)
-- Hydrothermal vents + bioluminescent crystals
-- ============================================================

function ZoneService:PopulateMidnightZone()
    -- Hydrothermal vent structures (3-5 vents with animated bubble/heathaze particles)
    local ventColors = {
        Color3.fromHex("#8B5CF6"), -- DeepPurple
        Color3.fromHex("#00E5FF"), -- CyanGlow
        Color3.fromHex("#39FF14"), -- BioGreen
    }

    for i = 1, 5 do
        local x = math.random(-WELL_RADIUS + 35, WELL_RADIUS - 35)
        local z = math.random(-WELL_RADIUS + 35, WELL_RADIUS - 35)
        local y = -math.random(1200, 3800)

        local vent = AnimatedEnvironment.CreateHydrothermalVent(
            Vector3.new(x, y, z),
            math.random(15, 35),
            ventColors[math.random(1, #ventColors)]
        )
        table.insert(animatedVents, vent)
    end

    -- Bioluminescent crystal formations (glowing/pulsing)
    for i = 1, 12 do
        local crystal = Instance.new("Part")
        crystal.Name = "MidnightCrystal"
        crystal.Size = Vector3.new(5, math.random(10, 25), 5)
        crystal.Position = Vector3.new(
            math.random(-WELL_RADIUS + 40, WELL_RADIUS - 40),
            -math.random(1100, 3900),
            math.random(-WELL_RADIUS + 40, WELL_RADIUS - 40)
        )
        crystal.Rotation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))
        crystal.Anchored = true
        crystal.CanCollide = false
        crystal.CastShadow = false
        crystal.Parent = MapFolder

        local crystalColor = ventColors[math.random(1, #ventColors)]
        VFXUtil.ApplyBioluminescence(crystal, crystalColor, 4)
        VFXUtil.Pulse(crystal, crystalColor, VFXUtil.Colors.ElectricBlue, 2 + math.random() * 2)
    end

    -- Deep sea floor features (rocky spires)
    for i = 1, 6 do
        local spire = Instance.new("Part")
        spire.Name = "MidnightSpire"
        spire.Size = Vector3.new(math.random(4, 8), math.random(20, 50), math.random(4, 8))
        spire.Position = Vector3.new(
            math.random(-WELL_RADIUS + 30, WELL_RADIUS - 30),
            -math.random(1200, 3800),
            math.random(-WELL_RADIUS + 30, WELL_RADIUS - 30)
        )
        spire.Anchored = true
        spire.CanCollide = false
        spire.Material = Enum.Material.Slate
        spire.Color = Color3.fromRGB(20, 25, 35)
        spire.CastShadow = false
        spire.Parent = MapFolder
    end
end

function ZoneService:KnitStop()
    -- Cleanup animated environment objects
    for _, kelp in ipairs(animatedKelp) do
        if kelp.cleanup then kelp.cleanup() end
    end
    for _, vent in ipairs(animatedVents) do
        if vent.cleanup then vent.cleanup() end
    end
    for _, school in ipairs(animatedFishSchools) do
        if school.cleanup then school.cleanup() end
    end
    animatedKelp = {}
    animatedVents = {}
    animatedFishSchools = {}
end

return ZoneService