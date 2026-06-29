--[[
	Util.lua — Shared utility functions for Abyss of the Deep
	Pure functions — no state, no side effects.
]]

local Util = {}

-- ============================================================
-- Math & Random
-- ============================================================

function Util.Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function Util.Lerp(a, b, t)
	return a + (b - a) * t
end

function Util.WeightedRandom(weightTable)
	-- weightTable: { {value = any, weight = number}, ... }
	local totalWeight = 0
	for _, entry in ipairs(weightTable) do
		totalWeight += entry.weight
	end
	
	local roll = math.random() * totalWeight
	local cumulative = 0
	
	for _, entry in ipairs(weightTable) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end
	
	return weightTable[#weightTable].value
end

function Util.RandomRange(min, max)
	return min + math.random() * (max - min)
end

function Util.RandomInt(min, max)
	return math.floor(Util.RandomRange(min, max + 1))
end

-- ============================================================
-- Table Utilities
-- ============================================================

function Util.DeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = Util.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function Util.TableFind(tbl, predicate)
	for i, v in ipairs(tbl) do
		if predicate(v, i) then
			return v, i
		end
	end
	return nil, nil
end

function Util.TableSum(tbl, accessor)
	local sum = 0
	for _, v in ipairs(tbl) do
		if accessor then
			sum += accessor(v)
		else
			sum += v
		end
	end
	return sum
end

-- ============================================================
-- Depth Conversion
-- ============================================================

function Util.DepthToLayerIndex(depth)
	-- Returns which Config.DepthLayers index this depth belongs to
	local Config = require(script.Parent.Config)
	for i, layer in ipairs(Config.DepthLayers) do
		if depth >= layer.DepthMin and depth < layer.DepthMax then
			return i
		end
	end
	return #Config.DepthLayers
end

function Util.DepthToProgress(depth)
	-- Returns 0-1 progress through all depth layers
	local Config = require(script.Parent.Config)
	local maxDepth = Config.DepthLayers[#Config.DepthLayers].DepthMax
	return Util.Clamp(depth / maxDepth, 0, 1)
end

function Util.FormatDepth(depth)
	if depth >= 1000 then
		return string.format("%.1f km", depth / 1000)
	else
		return string.format("%.0f m", depth)
	end
end

-- ============================================================
-- Time Formatting
-- ============================================================

function Util.FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

function Util.FormatPlayTime(totalSeconds)
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

-- ============================================================
-- String Utilities
-- ============================================================

function Util.TitleCase(str)
	return str:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)
end

function Util.FormatCurrency(amount)
	local formatted = tostring(math.floor(amount))
	local k = 3
	while #formatted > k do
		formatted = formatted:sub(1, #formatted - k) .. "," .. formatted:sub(#formatted - k + 1)
	end
	return formatted
end

return Util