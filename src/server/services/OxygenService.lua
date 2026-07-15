--[[
    OxygenService — Manages player oxygen levels underwater
    Knit service that handles oxygen drain, refills, and critical state.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local OxygenService = Knit.CreateService {
    Name = "OxygenService",
    Client = {
        GetOxygenData = Knit.CreateSignal(),
        RequestRefill = Knit.CreateSignal(),
        UseEmergencyTank = Knit.CreateSignal(),
    }
}

-- Internal player state
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local playerOxygen = {} -- { [UserId] = { current: number, max: number, isDiving: bool, tickCounter: number } }

function OxygenService:KnitStart()
    print("[OxygenService] Initialized")

    -- Core loop — oxygen drain every second
    while task.wait(1) do
        self:ProcessOxygenTick()
    end
end

function OxygenService:PlayerAdded(player)
    local userId = player.UserId
    playerOxygen[userId] = {
        current = Config.Player.MaxOxygen,
        max = Config.Player.MaxOxygen,
        isDiving = false,
        tickCounter = 0,
    }
end

function OxygenService:PlayerRemoving(player)
    playerOxygen[player.UserId] = nil
end

function OxygenService:StartDive(player)
    local data = playerOxygen[player.UserId]
    if not data then return end
    data.isDiving = true
end

function OxygenService:EndDive(player)
    local data = playerOxygen[player.UserId]
    if not data then return end
    data.isDiving = false
    -- Refill oxygen at surface
    data.current = data.max
end

function OxygenService:ProcessOxygenTick()
    for userId, data in pairs(playerOxygen) do
        if data.isDiving then
            -- Calculate drain rate based on depth layer
            local player = game:GetService("Players"):GetPlayerByUserId(userId)
            if not player then continue end

            -- Get current depth from DepthService
            local DepthService = Knit.GetService("DepthService")
            local currentDepth = DepthService:GetPlayerDepth(player)
            local layerIndex = Util.DepthToLayerIndex(currentDepth)
            local layer = Config.DepthLayers[layerIndex]

            -- Apply drain (modified by gear)
            local drain = layer.OxygenDrainRate
            local gearTier = DepthService:GetPlayerGearTier(player)
            local gear = Config.DivingGear[gearTier]
            if gear then
                drain = drain / gear.SpeedModifier
            end

            data.current = math.max(0, data.current - drain)
            data.tickCounter = (data.tickCounter or 0) + 1

            -- Check for critical oxygen — always send these immediately
            if data.current <= Config.Player.OxygenCriticalThreshold and data.current > 0 then
                -- Critical warning — send every tick
                self.Client:Get("GetOxygenData"):Fire(player, {
                    current = data.current,
                    max = data.max,
                    isCritical = true,
                    layerName = layer.Name,
                })
            elseif data.current <= 0 then
                -- Player is out of oxygen — surface them
                self:ForceSurface(player)
            elseif data.tickCounter % 3 == 0 then
                -- Normal update — throttle to every 3rd tick (3s intervals)
                -- Reduces network traffic by 66% for non-critical updates
                self.Client:Get("GetOxygenData"):Fire(player, {
                    current = data.current,
                    max = data.max,
                    isCritical = false,
                    layerName = layer.Name,
                })
            end
        end
    end
end

function OxygenService:ForceSurface(player)
    local DepthService = Knit.GetService("DepthService")
    DepthService:SurfacePlayer(player)
    
    local data = playerOxygen[player.UserId]
    if data then
        data.current = data.max
    end
    
    self.Client:Get("GetOxygenData"):Fire(player, {
        current = data and data.max or Config.Player.MaxOxygen,
        max = data and data.max or Config.Player.MaxOxygen,
        isCritical = false,
        layerName = "Surface",
    })
    
    -- Notify player
    self.Client:Get("GameMessage"):Fire(player, {
        Text = "You ran out of oxygen! Resurfacing...",
        Type = "Warning",
    })
end

function OxygenService:AddOxygenBonus(player, bonusAmount)
    local data = playerOxygen[player.UserId]
    if not data then return end
    data.max = Config.Player.MaxOxygen + bonusAmount
    data.current = data.max -- Refill on upgrade
end

-- Called by CreatureService to check if a player is currently diving
function OxygenService:GetPlayerOxygenState(player)
    return playerOxygen[player.UserId]
end

-- Client methods
function OxygenService.Client:GetOxygenData(player)
    local self = OxygenService
    local data = playerOxygen[player.UserId]
    if not data then
        return { current = Config.Player.MaxOxygen, max = Config.Player.MaxOxygen, isCritical = false }
    end
    return {
        current = data.current,
        max = data.max,
        isCritical = data.current <= Config.Player.OxygenCriticalThreshold,
    }
end

function OxygenService.Client:RequestRefill(player)
    local self = OxygenService
    -- Check if player has consumable oxygen tank
    -- This would integrate with EconomyService
    return { success = false, reason = "No oxygen tanks available" }
end

return OxygenService
