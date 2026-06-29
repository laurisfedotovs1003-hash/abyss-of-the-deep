--[[
	Client Initialization — Abyss of the Deep
	Bootstraps Knit on the client and registers all controllers.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))

-- Register all controllers
local controllers = script.Controllers:GetChildren()
for _, controllerModule in ipairs(controllers) do
	if controllerModule:IsA("ModuleScript") then
		local success, err = pcall(function()
			require(controllerModule)
		end)
		if not success then
			warn(string.format("[Abyss] Failed to load controller %s: %s", controllerModule.Name, err))
		end
	end
end

-- Wait for server to be ready
local serverReady = script.Parent:WaitForChild("ServerReady", 10)
if serverReady then
	serverReady.Event:Wait()
end

-- Start Knit
Knit.Start():andThen(function()
	print("[Abyss] Knit client initialized — Welcome to Abyss of the Deep!")
end):catch(function(err)
	warn(string.format("[Abyss] Knit client failed to start: %s", err))
end)

return Knit