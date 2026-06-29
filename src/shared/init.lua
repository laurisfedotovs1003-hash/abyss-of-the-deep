--[[
	Shared Module Entry Point — Abyss of the Deep
	Exports shared modules that are available to both client and server via Knit.
]]

local Shared = {}

-- By convention, Knit shared modules are required individually by services
-- and controllers. This file serves as a central index.

Shared.Config = require(script.Modules.Config)
Shared.Types = require(script.Modules.Types)
Shared.Util = require(script.Modules.Util)

return Shared