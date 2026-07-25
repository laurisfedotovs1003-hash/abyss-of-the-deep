--[[
    TimeService — Server-authoritative day/night cycle
    Manages 20-minute day/night cycle, broadcasts TimeStateChanged to clients,
    provides spawn modifier queries for CreatureService/OxygenService.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local EnvConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("EnvironmentConfig"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))

local TimeService = Knit.CreateService {
    Name = "TimeService",
    Client = {
        TimeStateChanged = Knit.CreateSignal(),
        GetTimeData = Knit.CreateSignal(),
    }
}

-- ============================================================
-- State
-- ============================================================

local timeState = {
    dayProgress = 0,        -- 0-1 progress through day/night phase
    isDay = true,           -- Is it currently day?
    phase = "Noon",         -- Current named phase
    cycleElapsed = 0,       -- Seconds into current cycle
    dayCount = 0,           -- Number of full cycles completed
    timeOfDay = 0.5,        -- 0 = midnight, 0.5 = noon
}

local PHASE_ORDER = { "Midnight", "PreDawn", "Dawn", "Noon", "Dusk", "EarlyNight", "Midnight" }

local function GetTimeOfDay()
    return timeState.timeOfDay
end

local function GetPhaseName(timeOfDay)
    if timeOfDay < 0.05 then return "Midnight"
    elseif timeOfDay < 0.2 then return "PreDawn"
    elseif timeOfDay < 0.3 then return "Dawn"
    elseif timeOfDay < 0.7 then return "Noon"
    elseif timeOfDay < 0.8 then return "Dusk"
    elseif timeOfDay < 0.95 then return "EarlyNight"
    else return "Midnight"
    end
end

local function GetLightingForPhase(phase)
    local dayPhases = EnvConfig.TimeCycle.DayPhase
    local nightPhases = EnvConfig.TimeCycle.NightPhase

    if dayPhases[phase] then return dayPhases[phase] end
    if nightPhases[phase] then return nightPhases[phase] end
    return dayPhases.Noon
end

local function IsDaytime(phase)
    return phase == "Dawn" or phase == "Noon" or phase == "Dusk"
end

-- ============================================================
-- Initialize
-- ============================================================

function TimeService:KnitStart()
    Logger:Info("[TimeService] Day/Night cycle starting")
    self:RunTimeLoop()
end

function TimeService:RunTimeLoop()
    local cycleDuration = EnvConfig.TimeCycle.CycleDuration

    while true do
        local dt = 1
        task.wait(dt)

        timeState.cycleElapsed = timeState.cycleElapsed + dt
        if timeState.cycleElapsed >= cycleDuration then
            timeState.cycleElapsed = 0
            timeState.dayCount = timeState.dayCount + 1
        end

        -- Calculate time of day (0 = midnight, 0.5 = noon, 1 = midnight)
        timeState.timeOfDay = (timeState.cycleElapsed / cycleDuration) % 1

        local phase = GetPhaseName(timeState.timeOfDay)
        local wasDay = timeState.isDay
        timeState.isDay = IsDaytime(phase)

        -- Only broadcast on phase change
        if phase ~= timeState.phase then
            timeState.phase = phase
            local lighting = GetLightingForPhase(phase)

            local data = {
                phase = phase,
                isDay = timeState.isDay,
                timeOfDay = timeState.timeOfDay,
                lighting = lighting,
                dayCount = timeState.dayCount,
                cycleProgress = timeState.timeOfDay,
            }

            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                self.Client:Get("TimeStateChanged"):Fire(player, data)
            end

            Logger:Debug(string.format("[TimeService] Phase: %s (Day: %s, Progress: %.2f)",
                phase, tostring(timeState.isDay), timeState.timeOfDay))
        end
    end
end

-- ============================================================
-- Public Query API
-- ============================================================

function TimeService:IsDaytime()
    return timeState.isDay
end

function TimeService:GetTimeOfDay()
    return timeState.timeOfDay
end

function TimeService:GetPhase()
    return timeState.phase
end

function TimeService:GetSpawnModifier(rarity)
    local mods = timeState.isDay and EnvConfig.TimeCycle.DaySpawnModifiers or EnvConfig.TimeCycle.NightSpawnModifiers
    if rarity == "Common" then return mods.CommonMultiplier or 1
    elseif rarity == "Uncommon" then return mods.UncommonMultiplier or 1
    elseif rarity == "Rare" then return mods.RareMultiplier or 1
    elseif rarity == "Epic" then return mods.EpicMultiplier or 1
    elseif rarity == "Legendary" then return mods.LegendaryMultiplier or 1
    end
    return 1
end

function TimeService:GetDayOnlyCreatures()
    return EnvConfig.TimeCycle.DayOnlyCreatures
end

function TimeService:GetNightOnlyCreatures()
    return EnvConfig.TimeCycle.NightOnlyCreatures
end

function TimeService:GetActiveTimeCreatures()
    return timeState.isDay and EnvConfig.TimeCycle.DayOnlyCreatures or EnvConfig.TimeCycle.NightOnlyCreatures
end

-- Client query
function TimeService.Client:GetTimeData(player)
    local self = TimeService
    return {
        phase = timeState.phase,
        isDay = timeState.isDay,
        timeOfDay = timeState.timeOfDay,
        lighting = GetLightingForPhase(timeState.phase),
        dayCount = timeState.dayCount,
    }
end

return TimeService
