--[[
	ConfigValidator.lua — Runtime schema validation for Config tables
	Runs at KnitStart to catch misconfiguration early with clear error messages.
	Validates required fields, types, ranges, and cross-references.
]]

local Logger = require(script.Parent.Logger)

local ConfigValidator = {}
local log = Logger.new("ConfigValidator")

-- ============================================================
-- Validation Helpers
-- ============================================================

local function isTable(v) return type(v) == "table" end
local function isNumber(v) return type(v) == "number" end
local function isString(v) return type(v) == "string" end
local function isBoolean(v) return type(v) == "boolean" end

local function expectField(tableName, fieldName, value, typeCheck, context)
	if value == nil then
		local msg = string.format("[Config] MISSING: %s.%s", tableName, fieldName)
		if context then msg = msg .. " (" .. tostring(context) .. ")" end
		log:Warn(msg)
		return false
	end
	if typeCheck and not typeCheck(value) then
		log:Warn(string.format("[Config] TYPE MISMATCH: %s.%s = %s (expected %s)", tableName, fieldName, typeof(value), typeCheck))
		return false
	end
	return true
end

local function expectNumber(tableName, fieldName, value, minVal, maxVal, context)
	if not expectField(tableName, fieldName, value, isNumber, context) then return false end
	if minVal ~= nil and value < minVal then
		log:Warn(string.format("[Config] RANGE: %s.%s = %s < minimum %s", tableName, fieldName, value, minVal))
		return false
	end
	if maxVal ~= nil and value > maxVal then
		log:Warn(string.format("[Config] RANGE: %s.%s = %s > maximum %s", tableName, fieldName, value, maxVal))
		return false
	end
	return true
end

-- ============================================================
-- Section Validators
-- ============================================================

function ConfigValidator:ValidateEconomy()
	local eco = Config.Economy
	if not eco then log:Error("Config.Economy missing"); return false end
	
	expectNumber("Economy", "StartingCurrency", eco.StartingCurrency, 0)
	expectNumber("Economy", "MaxCollectionSlots", eco.MaxCollectionSlots, 1)
	expectNumber("Economy", "XPPerDepthMeter", eco.XPPerDepthMeter, 0, 10)
	expectNumber("Economy", "XPPerCreatureCaptured", eco.XPPerCreatureCaptured, 1)
	expectNumber("Economy", "CreditsPerDepthMeter", eco.CreditsPerDepthMeter, 0, 10)
	expectNumber("Economy", "CreditsPerDiveComplete", eco.CreditsPerDiveComplete, 0)
	expectNumber("Economy", "ResearchPointsPerLevel", eco.ResearchPointsPerLevel, 0)
	
	if eco.BaseBuildingCosts then
		for moduleType, cost in pairs(eco.BaseBuildingCosts) do
			if type(cost) == "table" then
				expectNumber("BaseBuildingCosts", moduleType .. ".Credits", cost.Credits, 0, nil, moduleType)
				if cost.Scrap then expectNumber("BaseBuildingCosts", moduleType .. ".Scrap", cost.Scrap, 0, nil, moduleType) end
				if cost.Crystal then expectNumber("BaseBuildingCosts", moduleType .. ".Crystal", cost.Crystal, 0, nil, moduleType) end
			end
		end
	end
	
	log:Info("Config.Economy validated")
	return true
end

function ConfigValidator:ValidateDepthLayers()
	local layers = Config.DepthLayers
	if not layers then log:Error("Config.DepthLayers missing"); return false end
	if #layers < 3 then log:Warn("Config.DepthLayers has fewer than 3 zones — game may feel shallow") end
	
	for i, layer in ipairs(layers) do
		expectField("DepthLayers["..i.."]", "Name", layer.Name, isString)
		expectNumber("DepthLayers["..i.."]", "DepthMin", layer.DepthMin, 0)
		expectNumber("DepthLayers["..i.."]", "DepthMax", layer.DepthMax, layer.DepthMin or 0)
		expectNumber("DepthLayers["..i.."]", "OxygenDrainRate", layer.OxygenDrainRate, 0)
		expectNumber("DepthLayers["..i.."]", "PressureMultiplier", layer.PressureMultiplier, 1)
		
		-- Check layer ordering
		if i > 1 then
			local prev = layers[i-1]
			if prev and layer.DepthMin ~= prev.DepthMax then
				log:Warn(string.format("DepthLayers gap: Layer %d (%s) min depth %d != prev max %d", i, layer.Name, layer.DepthMin, prev.DepthMax))
			end
		end
	end
	
	log:Info(string.format("Config.DepthLayers validated (%d zones)", #layers))
	return true
end

function ConfigValidator:ValidateDivingGear()
	local gear = Config.DivingGear
	if not gear then log:Error("Config.DivingGear missing"); return false end
	
	-- Tier 1 should be free
	if gear[1] and gear[1].Price ~= 0 then
		log:Warn("DivingGear Tier 1 should be free (starter gear)")
	end
	
	for i, g in ipairs(gear) do
		expectField("DivingGear["..i.."]", "Name", g.Name, isString, g.Name)
		expectNumber("DivingGear["..i.."]", "Price", g.Price, 0, "tier "..i)
		expectNumber("DivingGear["..i.."]", "MaxDepth", g.MaxDepth, 1, "tier "..i)
		
		-- Check gear tier ordering (prices should increase)
		if i > 1 and gear[i-1] and g.Price <= gear[i-1].Price then
			log:Warn(string.format("Gear Tier %d (%s) price %d <= Tier %d price %d", i, g.Name, g.Price, i-1, gear[i-1].Name, gear[i-1].Price))
		end
	end
	
	log:Info(string.format("Config.DivingGear validated (%d tiers)", #gear))
	return true
end

function ConfigValidator:ValidateCreatureRarity()
	local rarity = Config.CreatureRarity
	if not rarity then log:Error("Config.CreatureRarity missing"); return false end
	
	local totalWeight = 0
	for name, r in pairs(rarity) do
		expectNumber("CreatureRarity", name .. ".Weight", r.Weight, 1)
		expectNumber("CreatureRarity", name .. ".XPMultiplier", r.XPMultiplier, 1)
		expectNumber("CreatureRarity", name .. ".SellPriceMin", r.SellPriceMin, 0)
		expectNumber("CreatureRarity", name .. ".SellPriceMax", r.SellPriceMax, r.SellPriceMin or 0)
		totalWeight += r.Weight
	end
	
	if totalWeight > 110 then
		log:Warn(string.format("CreatureRarity total weight %d > 100 — some rarities may never appear", totalWeight))
	end
	
	log:Info(string.format("Config.CreatureRarity validated (%d rarities)", #rarity))
	return true
end

function ConfigValidator:ValidateAll()
	log:Info("=== Config Validation Starting ===")
	
	local results = {
		Economy = self:ValidateEconomy(),
		DepthLayers = self:ValidateDepthLayers(),
		DivingGear = self:ValidateDivingGear(),
		CreatureRarity = self:ValidateCreatureRarity(),
	}
	
	-- Report results
	local passed = 0
	local failed = 0
	for name, ok in pairs(results) do
		if ok then passed += 1 else failed += 1 end
	end
	
	log:Info(string.format("Config validation complete: %d passed, %d failed", passed, failed))
	
	return failed == 0
end

return ConfigValidator