--[[
	Server Initialization — Abyss of the Deep
	Bootstraps Knit, validates Config, and initializes all server services.
]]

local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Logger"))
local ConfigValidator = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("ConfigValidator"))
local log = Logger.new("ServerInit")

-- Validate Config at startup (fail fast on misconfiguration)
log:Info("Running Config validation...")
ConfigValidator:ValidateAll()

-- Register all services
local services = script.Services:GetChildren()
local loadedCount = 0
local failedCount = 0

for _, serviceModule in ipairs(services) do
	if serviceModule:IsA("ModuleScript") then
		local success, err = pcall(function()
			require(serviceModule)
		end)
		if success then
			loadedCount += 1
		else
			failedCount += 1
			log:Error(string.format("Failed to load service %s", serviceModule.Name), tostring(err))
		end
	end
end

log:Info(string.format("Services loaded: %d success, %d failed", loadedCount, failedCount))

-- Initialize DataStore manager
local DataStoreManager = require(script.datastore.DataStoreManager)
local initSuccess, initErr = pcall(function()
	DataStoreManager:Initialize()
end)

if not initSuccess then
	log:Error("DataStoreManager initialization failed", tostring(initErr))
end

-- Start Knit
Knit.Start():andThen(function()
	log:Info("Knit server initialized successfully — Abyss of the Deep is running!")
	
	-- Fire ready event for any clients that connect late
	local readyEvent = Instance.new("BindableEvent")
	readyEvent.Name = "ServerReady"
	readyEvent.Parent = script
end):catch(function(err)
	log:Error("Knit server failed to start", tostring(err))
end)

return Knit