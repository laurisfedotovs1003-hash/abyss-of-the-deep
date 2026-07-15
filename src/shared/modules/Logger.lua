--[[
	Logger.lua — Structured debugging and error logging for Abyss of the Deep
	Provides a consistent logging interface across all services and controllers.
	Supports log levels: Debug, Info, Warn, Error.
]]

local Logger = {}
Logger.__index = Logger

-- ============================================================
-- Log Levels
-- ============================================================

local LogLevel = {
	Debug = 1,
	Info = 2,
	Warn = 3,
	Error = 4,
	Silent = 5,
}

local LevelNames = { "DEBUG", "INFO", "WARN", "ERROR" }

-- ============================================================
-- Logger Instance
-- ============================================================

function Logger.new(systemName)
	local self = setmetatable({}, Logger)
	self.SystemName = systemName
	self.MinLevel = LogLevel.Info -- Can be overridden per-environment
	return self
end

-- ============================================================
-- Log Methods
-- ============================================================

function Logger:Log(level, message, data)
	if level < self.MinLevel then return end
	
	local levelName = LevelNames[level] or "UNKNOWN"
	local dataStr = ""
	if data then
		if type(data) == "string" then
			dataStr = " | " .. data
		elseif type(data) == "table" then
			local ok, encoded = pcall(function()
				return table.concat(data, ", ")
			end)
			if ok then
				dataStr = " | " .. encoded
			end
		end
	end
	
	local logLine = string.format("[%s] [%s] %s%s", self.SystemName, levelName, tostring(message), dataStr)
	print(logLine)
	
	-- For errors, also warn so Roblox Studio's output shows it clearly
	if level >= LogLevel.Warn then
		warn(logLine)
	end
end

function Logger:Debug(message, data)
	self:Log(LogLevel.Debug, message, data)
end

function Logger:Info(message, data)
	self:Log(LogLevel.Info, message, data)
end

function Logger:Warn(message, data)
	self:Log(LogLevel.Warn, message, data)
end

function Logger:Error(message, data)
	self:Log(LogLevel.Error, message, data)
end

-- ============================================================
-- Utility: Safe pcall wrapper with logging
-- ============================================================

function Logger:SafeCall(method, ...)
	local args = { ... }
	local ok, result = pcall(method, unpack(args))
	if not ok then
		self:Error("pcall failed", tostring(result))
		return nil, result
	end
	return result
end

function Logger:SafeCallMethod(obj, methodName, ...)
	local method = obj[methodName]
	if not method then
		self:Error(string.format("Method %s not found on object", methodName))
		return nil, "Method not found"
	end
	return self:SafeCall(method, obj, ...)
end

-- ============================================================
-- Utility: Nil check with default
-- ============================================================

function Logger:Default(value, default)
	if value == nil then
		self:Debug("Using default for nil value", tostring(default))
		return default
	end
	return value
end

-- ============================================================
-- Export
-- ============================================================

Logger.LogLevel = LogLevel

return Logger