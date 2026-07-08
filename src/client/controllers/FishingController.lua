--[[
    FishingController — Client-side fishing rod mechanics
    Manages tool creation, line casting, bite detection, and reel-in mini-game.
    Communicates with ToolService and CreatureService via Knit client proxies.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local FishingController = Knit.CreateController {
    Name = "FishingController",
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

-- Rod tier configuration (must match ToolService's ROD_TIERS)
local ROD_TIERS = {
    Basic = { BiteTimeMin = 3, BiteTimeMax = 8, CatchBonus = 1.0, Price = 0 },
    Advanced = { BiteTimeMin = 4, BiteTimeMax = 12, CatchBonus = 1.15, Price = 200 },
    Master = { BiteTimeMin = 5, BiteTimeMax = 15, CatchBonus = 1.35, Price = 800 },
    Legendary = { BiteTimeMin = 6, BiteTimeMax = 18, CatchBonus = 1.5, Price = 3000 },
}

-- State
local currentRodTier = "Basic"
local isCasting = false
local isFishing = false
local hasBite = false
local reelWindowEnd = 0
local biteCheckThread = nil
local rodTool = nil
local harvestTool = nil
local divingGearTool = nil

-- Tool objects (created in KnitStart)
local toolCache = {}

-- ============================================================
-- Initialize
-- ============================================================

function FishingController:KnitStart()
    print("[FishingController] Initialized — Rod, Diving Gear & Harvest tools ready")
    
    -- Listen for ToolService responses
    local ToolService = Knit.GetService("ToolService")
    if ToolService then
        -- Fish bite notification
        ToolService.Client:Get("FishBite"):Connect(function(data)
            self:OnFishBite(data)
        end)
        
        -- Fish result notification
        ToolService.Client:Get("FishResult"):Connect(function(data)
            self:OnFishResult(data)
        end)
        
        -- Harvest result
        ToolService.Client:Get("HarvestResult"):Connect(function(data)
            self:OnHarvestResult(data)
        end)
        
        -- Cast line response
        ToolService.Client:Get("CastLine"):Connect(function(data)
            if data.success then
                self:StartBiteWait(data)
            end
        end)
    end
    
    -- Create tool instances
    self:CreateTools()
end

-- ============================================================
-- Tool Creation
-- ============================================================

function FishingController:CreateTools()
    -- Create Fishing Rod Tool
    local rod = Instance.new("Tool")
    rod.Name = "Fishing Rod"
    rod.ToolTip = "Cast your line into the depths"
    rod.RequiresHandle = false
    rod.CanBeDropped = false
    rod.Parent = localPlayer:WaitForChild("Backpack")
    
    rod.Activated:Connect(function()
        self:CastRod()
    end)
    
    rod.Equipped:Connect(function()
        self:NotifyUI("FishingRodEquipped", { tier = currentRodTier })
    end)
    
    rod.Unequipped:Connect(function()
        if isFishing then
            self:CancelFishing()
        end
    end)
    
    rodTool = rod
    
    -- Create Diving Gear Tool
    local divingGear = Instance.new("Tool")
    divingGear.Name = "Diving Gear"
    divingGear.ToolTip = "Toggle diving mode"
    divingGear.RequiresHandle = false
    divingGear.CanBeDropped = false
    divingGear.Parent = localPlayer:WaitForChild("Backpack")
    
    divingGear.Activated:Connect(function()
        self:ToggleDiving()
    end)
    
    divingGear.Equipped:Connect(function()
        self:NotifyUI("GameMessage", {
            Text = "🤿 Diving Gear — activate to dive, deactivate to surface",
            Type = "Info",
        })
    end)
    
    divingGearTool = divingGear
    
    -- Create Harvest Tool
    local harvest = Instance.new("Tool")
    harvest.Name = "Harvest Tool"
    harvest.ToolTip = "Collect resources and interact with the environment"
    harvest.RequiresHandle = false
    harvest.CanBeDropped = false
    harvest.Parent = localPlayer:WaitForChild("Backpack")
    
    harvest.Activated:Connect(function()
        self:HarvestNearestNode()
    end)
    
    harvest.Equipped:Connect(function()
        self:NotifyUI("HarvestToolEquipped", {})
    end)
    
    harvestTool = harvest
    
    print("[FishingController] Tools created: Fishing Rod, Diving Gear, Harvest Tool")
end

-- ============================================================
-- DIVING GEAR TOGGLE
-- ============================================================

function FishingController:ToggleDiving()
    local DivingController = Knit.GetController("DivingController")
    if not DivingController then return end
    
    -- Check current dive state
    if DivingController.isDiving then
        DivingController:EndDive()
        self:NotifyUI("DiveEnded", {})
    else
        DivingController:StartDive()
        self:NotifyUI("DiveStarted", {})
    end
end

-- ============================================================
-- FISHING ROD MECHANICS
-- ============================================================

function FishingController:CastRod()
    if isFishing then
        self:ReelIn()
        return
    end
    
    local ToolService = Knit.GetService("ToolService")
    if not ToolService then return end
    
    isCasting = true
    
    -- Notify UI
    self:NotifyUI("Casting", {})
    
    -- Call server to cast line
    local result = ToolService:CastLine(currentRodTier)
    
    if not result.success then
        self:NotifyUI("GameMessage", {
            Text = result.reason or "Can't fish here!",
            Type = "Warning",
        })
        isCasting = false
    end
    -- On success, CastLine signal handler will call StartBiteWait
end

function FishingController:StartBiteWait(data)
    isFishing = true
    isCasting = false
    
    self:NotifyUI("LineCast", {
        biteTime = data.biteTime,
        zoneName = data.zoneName,
    })
    
    -- Start bite check loop
    if biteCheckThread then
        biteCheckThread:Cancel()
    end
    
    biteCheckThread = task.spawn(function()
        while isFishing do
            task.wait(0.5)
            local ToolService = Knit.GetService("ToolService")
            if ToolService then
                local result = ToolService:CheckBite()
                if result and result.bite then
                    -- OnFishBite signal handler will fire
                    break
                elseif result and result.result == "Missed" then
                    isFishing = false
                    self:NotifyUI("GameMessage", {
                        Text = "The fish got away!",
                        Type = "Warning",
                    })
                    break
                end
            end
            if not isFishing then break end
        end
    end)
end

function FishingController:OnFishBite(data)
    if not isFishing then return end
    
    hasBite = true
    reelWindowEnd = os.clock() + (data.reelWindow or 1.5)
    
    self:NotifyUI("FishBite", {
        reelWindow = data.reelWindow,
        zoneName = data.zoneName,
    })
    
    -- Show reel-in prompt
    self:NotifyUI("GameMessage", {
        Text = "⚡ FISH ON! Click to reel in!",
        Type = "Action",
    })
end

function FishingController:ReelIn()
    if not isFishing or not hasBite then return end
    
    local ToolService = Knit.GetService("ToolService")
    if not ToolService then return end
    
    hasBite = false
    isFishing = false
    
    if biteCheckThread then
        biteCheckThread:Cancel()
        biteCheckThread = nil
    end
    
    self:NotifyUI("Reeling", {})
    
    local result = ToolService:ReelIn()
    
    if not result or not result.success then
        self:NotifyUI("GameMessage", {
            Text = (result and result.reason) or "Nothing on the line...",
            Type = "Warning",
        })
    end
    -- On success, FishResult signal handler fires
end

function FishingController:OnFishResult(data)
    if data.result == "Caught" then
        local creature = data.creature
        if creature then
            self:NotifyUI("GameMessage", {
                Text = string.format("🎣 Caught %s %s! Worth ★%d", 
                    creature.isShiny and "✨ SHINY" or "",
                    creature.displayName or "something",
                    data.sellPrice or 0),
                Type = "Success",
            })
        end
        
    elseif data.result == "Escaped" or data.result == "Missed" then
        self:NotifyUI("GameMessage", {
            Text = data.reason or "The fish got away!",
            Type = "Warning",
        })
    end
    
    isFishing = false
    hasBite = false
    self:NotifyUI("FishingEnded", { result = data.result })
end

function FishingController:CancelFishing()
    isFishing = false
    hasBite = false
    isCasting = false
    
    if biteCheckThread then
        biteCheckThread:Cancel()
        biteCheckThread = nil
    end
    
    self:NotifyUI("GameMessage", {
        Text = "Fishing cancelled",
        Type = "Info",
    })
end

-- ============================================================
-- HARVEST TOOL MECHANICS
-- ============================================================

function FishingController:HarvestNearestNode()
    -- Simple raycast from camera to detect resource nodes
    local camera = workspace.CurrentCamera
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = { localPlayer.Character }
    
    local rayResult = workspace:Raycast(
        camera.CFrame.Position,
        camera.CFrame.LookVector * 50,
        raycastParams
    )
    
    if rayResult then
        local hit = rayResult.Instance
        local harvestType = nil
        
        -- Detect node type by collection group or tag
        if hit:GetAttribute("ResourceType") then
            harvestType = hit:GetAttribute("ResourceType")
        elseif hit:GetAttribute("CreatureNode") then
            harvestType = "CreatureEncounter"
        end
        
        if harvestType then
            local ToolService = Knit.GetService("ToolService")
            if ToolService then
                self:NotifyUI("Harvesting", { type = harvestType })
                local result = ToolService:HarvestNode(harvestType)
                
                if not result.success then
                    self:NotifyUI("GameMessage", {
                        Text = result.reason or "Nothing to harvest here",
                        Type = "Warning",
                    })
                end
            end
        else
            self:NotifyUI("GameMessage", {
                Text = "Nothing to harvest here",
                Type = "Info",
            })
        end
    else
        self:NotifyUI("GameMessage", {
            Text = "Nothing in range",
            Type = "Info",
        })
    end
end

function FishingController:OnHarvestResult(data)
    if data and data.type then
        self:NotifyUI("GameMessage", {
            Text = string.format("🪨 Collected %d %s", data.amount or 0, data.type),
            Type = "Success",
        })
    end
end

-- ============================================================
-- Rod Tier Upgrades
-- ============================================================

function FishingController:UpgradeRod(newTier)
    if ROD_TIERS[newTier] then
        currentRodTier = newTier
        self:NotifyUI("GameMessage", {
            Text = string.format("🎣 Rod upgraded to %s!", newTier),
            Type = "Success",
        })
        return true
    end
    return false
end

-- ============================================================
-- UI Communication
-- ============================================================

function FishingController:NotifyUI(eventName, data)
    local UIController = Knit.GetController("UIController")
    if UIController then
        if UIController.HandleFishingEvent then
            UIController:HandleFishingEvent(eventName, data)
        end
    end
end

-- ============================================================
-- Cleanup
-- ============================================================

function FishingController:KnitStop()
    if rodTool and rodTool.Parent then
        rodTool:Destroy()
    end
    if divingGearTool and divingGearTool.Parent then
        divingGearTool:Destroy()
    end
    if harvestTool and harvestTool.Parent then
        harvestTool:Destroy()
    end
    if biteCheckThread then
        biteCheckThread:Cancel()
        biteCheckThread = nil
    end
end

return FishingController