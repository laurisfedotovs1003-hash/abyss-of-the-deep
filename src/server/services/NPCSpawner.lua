--[[
    NPCSpawner — Server-side NPC management for the Surface Hub
    Spawns 4 ambient characters: Old Diver, Shopkeeper, Marine Biologist, Engineer.
    Each NPC has idle behaviors and simple interaction handling.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local NPCSpawner = Knit.CreateService {
    Name = "NPCSpawner",
    Client = {
        NPCDialogue = Knit.CreateSignal(),
        NPCTalkRequest = Knit.CreateSignal(),
    }
}

-- ============================================================
-- NPC Definitions
-- ============================================================

local NPC_DEFINITIONS = {
    OldDiver = {
        Name = "Captain Marlow",
        Title = "The Old Diver",
        Color = Color3.fromRGB(230, 200, 160),
        Size = Vector3.new(4, 6, 2),
        Position = Vector3.new(-120, 10, 100),
        Dialogue = {
            "The deep holds secrets, lad. Listen to the echoes.",
            "Stormy days bring the rarest catches — if you dare.",
            "I've seen things at 4000 meters you wouldn't believe.",
            "The Moon Jelly only appears when darkness falls.",
            "Bioluminescent water? That's when the magic happens.",
            "Check your gear before a deep dive. Pressure is no joke.",
            "The Trench Leviathan? Aye... she's real.",
        },
        DailyTipCooldown = 86400, -- Once per day per player
    },
    Shopkeeper = {
        Name = "Mira",
        Title = "Gear Shopkeeper",
        Color = Color3.fromRGB(180, 220, 255),
        Size = Vector3.new(4, 6, 2),
        Position = Vector3.new(80, 10, 180),
        Dialogue = {
            "Welcome! New gear just came in from the surface.",
            "I've got a special deal today — check the shop!",
            "Upgrade your rod for deeper waters.",
            "Need oxygen tanks? I've got you covered.",
            "The Abyssal Exosuit is my finest piece. Expensive, though.",
            "Bundles save you credits in the long run.",
        },
    },
    MarineBiologist = {
        Name = "Dr. Elara",
        Title = "Marine Biologist",
        Color = Color3.fromRGB(180, 255, 200),
        Size = Vector3.new(4, 6, 2),
        Position = Vector3.new(0, 10, 50),
        Dialogue = {
            "I'm studying the migration patterns of deep-sea creatures.",
            "Bring me a rare specimen and I'll reward you handsomely.",
            "Did you know anglerfish can live for over 30 years?",
            "The bioluminescent properties of Midnight Zone creatures are fascinating.",
            "I need samples from the Kelp Forest. Can you help?",
            "New species discovered! We need expedition volunteers.",
        },
        -- Creature hunting requests
        CurrentRequest = nil,
    },
    Engineer = {
        Name = "Rusty",
        Title = "Base Engineer",
        Color = Color3.fromRGB(200, 160, 100),
        Size = Vector3.new(4, 6, 2),
        Position = Vector3.new(140, 10, -80),
        Dialogue = {
            "Your habitat needs reinforcing? I've got materials.",
            "Scrap metal and crystals — that's what you need for upgrades.",
            "A well-built base keeps the giants out.",
            "I can sell you rare materials... for a price.",
            "The deeper you build, the stronger your modules need to be.",
            "Ever seen a base at 6000 meters? Now that's engineering.",
        },
        -- Rare material shop access
        MaterialShop = {
            "ReinforcedAlloy" = { Price = 50, Currency = "Credits", Description = "Strengthens base modules" },
            "CrystalCluster" = { Price = 100, Currency = "Credits", Description = "Rare crystal for upgrades" },
        },
    },
}

-- ============================================================
-- NPC Instance Storage
-- ============================================================

local spawnedNPCs = {}       -- { [npcKey] = { model, parts, ... } }
local playerDailyTips = {}   -- { [userId] = { [npcKey] = lastTipTime } }

-- ============================================================
-- Initialize
-- ============================================================

function NPCSpawner:KnitStart()
    Logger:Info("[NPCSpawner] Spawning ambient characters")
    SpawnAllNPCs()
end

-- ============================================================
-- Spawning
-- ============================================================

function SpawnAllNPCs()
    for npcKey, def in pairs(NPC_DEFINITIONS) do
        SpawnNPC(npcKey, def)
    end
end

function SpawnNPC(npcKey, def)
    -- Folders for organization
    local npcFolder = workspace:FindFirstChild("NPCs") or Instance.new("Folder", workspace)
    npcFolder.Name = "NPCs"

    local model = Instance.new("Model")
    model.Name = npcKey
    model.Parent = npcFolder

    -- Body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = def.Size
    body.Position = def.Position
    body.Anchored = true
    body.CanCollide = true
    body.Material = Enum.Material.SmoothPlastic
    body.Color = def.Color
    body.CastShadow = true
    body.Parent = model

    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(3, 3, 3)
    head.Position = def.Position + Vector3.new(0, def.Size.Y / 2 + 2, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Material = Enum.Material.SmoothPlastic
    head.Color = def.Color:Lerp(Color3.new(1, 1, 1), 0.2)
    head.CastShadow = true
    head.Parent = model

    -- Hat/accessory (distinctive marker)
    local hat = Instance.new("Part")
    hat.Name = "Hat"
    hat.Size = Vector3.new(4, 1.5, 4)
    hat.Position = head.Position + Vector3.new(0, 1.8, 0)
    hat.Anchored = true
    hat.CanCollide = false
    hat.Material = Enum.Material.Metal
    hat.Parent = model

    -- NPC-specific colors
    if npcKey == "OldDiver" then
        hat.Color = Color3.fromRGB(180, 130, 80)  -- Brown diver cap
    elseif npcKey == "Shopkeeper" then
        hat.Color = Color3.fromRGB(255, 215, 0)  -- Gold accent
    elseif npcKey == "MarineBiologist" then
        hat.Color = Color3.fromRGB(255, 255, 255)  -- Lab coat white
        hat.Size = Vector3.new(3, 0.5, 2)
    elseif npcKey == "Engineer" then
        hat.Color = Color3.fromRGB(255, 100, 30)  -- Orange hardhat
    end

    -- Name floating label
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(4, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, def.Size.Y + 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = model

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.fromScale(1, 1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = def.Name .. "\n" .. def.Title
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = billboard

    -- Interaction detector (proximity based)
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.CursorIcon = "rbxasset://textures/Cursors/crossIcon.png"
    clickDetector.Parent = model

    clickDetector.MouseClick:Connect(function(player)
        HandleNPCInteraction(player, npcKey, def)
    end)

    -- Interaction for mobile (ProximityPrompt)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Talk to " .. def.Name
    prompt.ObjectText = def.Title
    prompt.RequiresLineOfSight = true
    prompt.MaxActivationDistance = 20
    prompt.HoldDuration = 0.5
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = body

    prompt.Triggered:Connect(function(player)
        HandleNPCInteraction(player, npcKey, def)
    end)

    -- Store in tracking table
    spawnedNPCs[npcKey] = {
        model = model,
        body = body,
        head = head,
        def = def,
    }

    -- Start idle animation
    task.spawn(function()
        IdleAnimation(model, head, body)
    end)

    Logger:Debug(string.format("[NPCSpawner] Spawned %s (%s)", npcKey, def.Name))
end

-- ============================================================
-- Idle Animation
-- ============================================================

function IdleAnimation(model, head, body)
    local baseHeadPos = head.Position
    while model and model.Parent do
        -- Subtle head bobbing
        local bob = math.sin(os.clock() * 1.5) * 0.2
        head.Position = baseHeadPos + Vector3.new(0, bob, 0)

        task.wait(0.05)
    end
end

-- ============================================================
-- Interaction Handling
-- ============================================================

function HandleNPCInteraction(player, npcKey, def)
    local dialogue = def.Dialogue
    local message = dialogue[math.random(1, #dialogue)]

    -- Enforce daily tip cooldown for Old Diver
    if npcKey == "OldDiver" and def.DailyTipCooldown then
        local now = os.time()
        if not playerDailyTips[player.UserId] then
            playerDailyTips[player.UserId] = {}
        end
        local lastTip = playerDailyTips[player.UserId][npcKey] or 0
        if now - lastTip < def.DailyTipCooldown then
            message = "I've told you all I know for today. Come back tomorrow, lad."
        else
            playerDailyTips[player.UserId][npcKey] = now
        end
    end

    -- Special dialogue for Marine Biologist if they have a request
    if npcKey == "MarineBiologist" and def.CurrentRequest then
        message = string.format("I'm looking for a %s. Bring it back for a reward!",
            def.CurrentRequest.DisplayName or "rare specimen")
    end

    -- Notify client
    local self = NPCSpawner or Knit.GetService("NPCSpawner")
    if self then
        self.Client:Get("NPCDialogue"):Fire(player, {
            npcName = def.Name,
            npcTitle = def.Title,
            message = message,
            npcKey = npcKey,
        })
    end
end

-- ============================================================
-- Query
-- ============================================================

function NPCSpawner:GetNPCData(npcKey)
    return NPC_DEFINITIONS[npcKey]
end

function NPCSpawner:GetAllNPCData()
    return NPC_DEFINITIONS
end

function NPCSpawner.Client:TalkToNPC(player, npcKey)
    local self = NPCSpawner
    local def = NPC_DEFINITIONS[npcKey]
    if not def then return end
    HandleNPCInteraction(player, npcKey, def)
end

return NPCSpawner
