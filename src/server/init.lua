--[[
	Server Initialization — Abyss of the Deep
	Bootstraps Knit and initializes all server services.
]]

local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local DataStoreManager = require(script.DataStoreManager)

-- Register all services
local services = script.Services:GetChildren()
for _, serviceModule in ipairs(services) do
	if serviceModule:IsA("ModuleScript") then
		local success, err = pcall(function()
			require(serviceModule)
		end)
		if not success then
			warn(string.format("[Abyss] Failed to load service %s: %s", serviceModule.Name, err))
		end
	end
end

-- Initialize DataStore manager
DataStoreManager:Initialize()

-- Start Knit
Knit.Start():andThen(function()
	print("[Abyss] Knit server initialized successfully — Abyss of the Deep is running!")
	
	-- Fire ready event for any clients that connect late
	local readyEvent = Instance.new("BindableEvent")
	readyEvent.Name = "ServerReady"
	readyEvent.Parent = script
end):catch(function(err)
	warn(string.format("[Abyss] Knit server failed to start: %s", err))
end)

return Knit