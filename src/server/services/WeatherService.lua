--[[
    WeatherService — Server-authoritative weather system
    Manages dynamic weather (Clear/Stormy/Bioluminescent/Blood Moon),
    broadcasts state changes to clients, provides modifier queries.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local EnvConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("EnvironmentConfig"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))

local WeatherService = Knit.CreateService {
    Name = "WeatherService",
    Client = {
        WeatherStateChanged = Knit.CreateSignal(),
        GetWeatherData = Knit.CreateSignal(),
    }
}

-- ============================================================
-- State
-- ============================================================

local weatherState = {
    currentType = "Clear",
    startedAt = 0,
    duration = 300,
    isTransitioning = false,
    lastChangeTime = 0,
}

-- ============================================================
-- Initialize
-- ============================================================

function WeatherService:KnitStart()
    Logger:Info("[WeatherService] Weather system starting")
    self:RunWeatherLoop()
end

function WeatherService:RunWeatherLoop()
    while true do
        -- Determine next check delay
        local sinceLast = os.time() - weatherState.lastChangeTime
        local minInterval = EnvConfig.Weather.ChangeIntervalMin
        local remaining = math.max(0, weatherState.startedAt + weatherState.duration - os.time())

        if remaining <= 0 then
            -- Current weather expired — pick new weather
            self:SelectNewWeather()
        end

        task.wait(10) -- Check every 10 seconds
    end
end

function WeatherService:SelectNewWeather()
    local types = EnvConfig.Weather.Types
    local weightedTable = {}

    for name, def in pairs(types) do
        table.insert(weightedTable, {
            value = name,
            weight = def.Weight,
        })
    end

    local chosen = Util.WeightedRandom(weightedTable)
    if not chosen then
        chosen = "Clear"
    end

    local def = types[chosen]
    local duration = math.random(def.DurationMin, def.DurationMax)
    local transitionTime = EnvConfig.Weather.TransitionDuration

    weatherState.currentType = chosen
    weatherState.startedAt = os.time()
    weatherState.duration = duration
    weatherState.lastChangeTime = os.time()
    weatherState.isTransitioning = true

    -- Broadcast weather start
    local data = {
        weatherType = chosen,
        lighting = def.Lighting,
        modifiers = def.Modifiers,
        description = def.Description,
        duration = duration,
        startedAt = os.time(),
        endsAt = os.time() + duration,
        transitionTime = transitionTime,
    }

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        self.Client:Get("WeatherStateChanged"):Fire(player, data)
    end

    Logger:Info(string.format("[WeatherService] Weather: %s (%ds)", chosen, duration))

    -- End transition after transitionTime
    task.delay(transitionTime, function()
        weatherState.isTransitioning = false
    end)
end

-- ============================================================
-- Public Query API
-- ============================================================

function WeatherService:GetCurrentWeather()
    return weatherState.currentType
end

function WeatherService:GetWeatherModifiers()
    local def = EnvConfig.Weather.Types[weatherState.currentType]
    return def and def.Modifiers or {}
end

function WeatherService:GetWeatherLighting()
    local def = EnvConfig.Weather.Types[weatherState.currentType]
    return def and def.Lighting or EnvConfig.Weather.Types.Clear.Lighting
end

function WeatherService:GetSpawnMultiplier()
    local mods = self:GetWeatherModifiers()
    return mods.CreatureSpawnMultiplier or 1.0
end

function WeatherService:GetRarityBonus(rarity)
    local mods = self:GetWeatherModifiers()
    if rarity == "Rare" then return (mods.RareBonus or 0) / 100
    elseif rarity == "Epic" then return (mods.EpicBonus or 0) / 100
    elseif rarity == "Legendary" then return (mods.LegendaryBonus or 0) / 100
    end
    return 0
end

function WeatherService:GetOxygenDrainMultiplier()
    local mods = self:GetWeatherModifiers()
    return mods.OxygenDrainMultiplier or 1.0
end

function WeatherService:IsTransitioning()
    return weatherState.isTransitioning
end

-- Client query
function WeatherService.Client:GetWeatherData(player)
    local self = WeatherService
    local def = EnvConfig.Weather.Types[weatherState.currentType]
    return {
        weatherType = weatherState.currentType,
        lighting = def.Lighting,
        modifiers = def.Modifiers,
        description = def.Description,
        duration = weatherState.duration,
        startedAt = weatherState.startedAt,
        endsAt = weatherState.startedAt + weatherState.duration,
        isTransitioning = weatherState.isTransitioning,
    }
end

return WeatherService
