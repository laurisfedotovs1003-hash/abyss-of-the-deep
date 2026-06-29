--[[
	UIController — Manages all player-facing UI screens and HUD elements
	Central hub for UI state management, screen transitions, and monetization flow.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local UIController = Knit.CreateController {
	Name = "UIController",
}

-- State
local currentScreen = "HUD"
local screenStack = {} -- For navigation history
local screenCache = {} -- Cached ScreenGui instances

-- Screen definitions
local SCREENS = {
	HUD = "HUD",
	Shop = "Shop",
	Collection = "Collection",
	BaseEditor = "BaseEditor",
	Settings = "Settings",
	SplashScreen = "SplashScreen",
}

function UIController:KnitStart()
	print("[UIController] Initialized")
	
	-- Create main UI container
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create main UI holder
	local mainHolder = Instance.new("ScreenGui")
	mainHolder.Name = "AbyssUI"
	mainHolder.DisplayOrder = 1
	mainHolder.IgnoreGuiInset = true
	mainHolder.Parent = playerGui
	
	-- Listen for game events from services
	self:RegisterServiceListeners()
	
	-- Show initial HUD
	self:ShowScreen("HUD")
end

function UIController:RegisterServiceListeners()
	-- Oxygen updates
	local OxygenService = Knit.GetService("OxygenService")
	if OxygenService then
		OxygenService.Client:Get("GetOxygenData"):Connect(function(data)
			self:UpdateOxygenDisplay(data)
		end)
	end
	
	-- Depth updates
	local DepthService = Knit.GetService("DepthService")
	if DepthService then
		DepthService.Client:Get("GetDepthData"):Connect(function(data)
			self:UpdateDepthDisplay(data)
		end)
		
		DepthService.Client:Get("GetLayerInfo"):Connect(function(data)
			self:ShowZoneTransition(data)
		end)
	end
	
	-- Creature encounters
	local CreatureService = Knit.GetService("CreatureService")
	if CreatureService then
		CreatureService.Client:Get("CreatureSpawned"):Connect(function(data)
			self:ShowCreatureEncounter(data)
		end)
		
		CreatureService.Client:Get("CreatureCaught"):Connect(function(data)
			self:ShowCatchResult(data)
		end)
	end
	
	-- Economy updates
	local EconomyService = Knit.GetService("EconomyService")
	if EconomyService then
		EconomyService.Client:Get("EconomyUpdated"):Connect(function(data)
			self:UpdateEconomyDisplay(data)
		end)
	end
	
	-- Collection updates
	local CollectionService = Knit.GetService("CollectionService")
	if CollectionService then
		CollectionService.Client:Get("CollectionUpdated"):Connect(function(data)
			self:UpdateCollectionDisplay(data)
		end)
	end
end

-- ============================================================
-- Screen Management
-- ============================================================

function UIController:ShowScreen(screenName)
	if currentScreen == screenName then return end
	
	-- Hide current screen
	self:HideAllScreens()
	
	-- Show new screen
	if screenName == "HUD" then
		self:ShowHUD()
	elseif screenName == "Shop" then
		self:ShowShop()
	elseif screenName == "Collection" then
		self:ShowCollection()
	elseif screenName == "BaseEditor" then
		self:ShowBaseEditor()
	end
	
	currentScreen = screenName
end

function UIController:PushScreen(screenName)
	table.insert(screenStack, currentScreen)
	self:ShowScreen(screenName)
end

function UIController:PopScreen()
	if #screenStack == 0 then
		self:ShowScreen("HUD")
		return
	end
	
	local previousScreen = table.remove(screenStack)
	self:ShowScreen(previousScreen)
end

function UIController:HideAllScreens()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "AbyssUI" then
			gui.Enabled = false
		end
	end
end

-- ============================================================
-- HUD Components
-- ============================================================

function UIController:ShowHUD()
	-- The HUD would be built using Roblox GUI instances
	-- This is a stub — UI Designer handles exact layouts
	
	-- HUD elements to create:
	-- 1. Oxygen Bar (top-right)
	-- 2. Depth Indicator (top-left)
	-- 3. Zone Name Banner (center-top)
	-- 4. Currency Display (top-right, below oxygen)
	-- 5. Interaction Prompts (center)
	-- 6. Action Buttons (bottom)
end

function UIController:UpdateOxygenDisplay(data)
	-- Update oxygen bar fill, color, and text
	-- Critical state triggers pulsing red animation
end

function UIController:UpdateDepthDisplay(data)
	-- Update depth number, progress bar, gear tier indicator
end

function UIController:UpdateEconomyDisplay(data)
	-- Update currency counter, XP bar, level badge
end

function UIController:UpdateCollectionDisplay(data)
	-- Update collection completion percentage
end

-- ============================================================
-- Screen Implementations
-- ============================================================

function UIController:ShowShop()
	-- Shop screen with gear upgrades, consumables, cosmetics
	-- Monetization: Show Game Passes and Developer Products
end

function UIController:ShowCollection()
	-- Creature collection journal with grid layout
	-- Shows all collected creatures, rarity colors, stats
end

function UIController:ShowBaseEditor()
	-- Base building mode UI with placement grid
	-- Module selection panel, upgrade controls
end

-- ============================================================
-- Event-Driven UI Responses
-- ============================================================

function UIController:ShowZoneTransition(layerData)
	-- Animated zone name banner
	-- "--- Entering the Midnight Zone ---"
	-- Shows for 3 seconds
end

function UIController:ShowCreatureEncounter(data)
	-- Creature encounter popup
	-- Shows creature name, rarity, size
	-- "Press E to catch" prompt
end

function UIController:ShowCatchResult(data)
	-- Catch success/failure animation
	-- Shows creature card with stats
	-- XP earned and sell price
end

function UIController:ShowGameMessage(message)
	-- Generic message display
	-- Used for tutorials, warnings, tips
end

function UIController:KnitStop()
	-- Cleanup GUI instances
end

return UIController