--[[
	DivingController — Handles player diving movement and interactions
	Manages swimming controls, oxygen usage triggers, and gear management.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local DivingController = Knit.CreateController {
	Name = "DivingController",
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- State
local isDiving = false
local currentDepth = 0
local swimSpeed = Config.Player.BaseSwimSpeed
local localPlayer = Players.LocalPlayer

function DivingController:KnitStart()
	print("[DivingController] Initialized")
	
	-- Listen for oxygen updates
	local OxygenService = Knit.GetService("OxygenService")
	if OxygenService then
		OxygenService.Client:Get("GetOxygenData"):Connect(function(data)
			if data.isCritical then
				self:TriggerCriticalOxygenWarning()
			end
		end)
	end
	
	-- Input handling
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Space then
			self:StartDive()
		end
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:ToggleSprint(true)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:ToggleSprint(false)
		end
		
		if input.KeyCode == Enum.KeyCode.Space then
			self:EndDive()
		end
	end)
	
	-- Movement update loop
	RunService:BindToRenderStep("AbyssDiving", Enum.RenderPriority.Character.Value, function(dt)
		self:UpdateMovement(dt)
	end)
end

function DivingController:StartDive()
	if isDiving then return end
	
	isDiving = true
	
	-- Notify server
	local OxygenService = Knit.GetService("OxygenService")
	if OxygenService then
		OxygenService:RequestDive()
	end
	
	-- Notify UI
	self:NotifyUI("DiveStarted")
end

function DivingController:EndDive()
	if not isDiving then return end
	
	isDiving = false
	
	-- Notify server
	local OxygenService = Knit.GetService("OxygenService")
	if OxygenService then
		OxygenService:Surface()
	end
	
	self:NotifyUI("DiveEnded")
end

function DivingController:UpdateMovement(dt)
	if not isDiving then return end
	
	-- Get movement direction
	local moveVector = Vector3.new(
		UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0,
		UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0,
		UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
	)
	
	if moveVector.Magnitude == 0 then return end
	
	-- Apply movement to character
	local character = localPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Move in camera-relative direction
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local moveDirection = cameraCFrame:VectorToObjectSpace(moveVector)
	moveDirection = Vector3.new(moveDirection.X, moveDirection.Y, moveDirection.Z).Unit
	
	-- Apply speed
	local speed = swimSpeed
	local gearTier = self:GetCurrentGearTier()
	if Config.DivingGear[gearTier] then
		speed = Config.Player.BaseSwimSpeed * Config.DivingGear[gearTier].SpeedModifier
	end
	
	humanoid:Move(moveDirection * speed, true)
	
	-- Update depth based on position
	self:UpdateDepth(rootPart.Position.Y)
end

function DivingController:UpdateDepth(yPosition)
	-- Convert Y position to depth (water surface at Y=0, depth increases downward)
	local depth = math.max(0, -yPosition)
	currentDepth = depth
	
	-- Report depth to server
	local DepthService = Knit.GetService("DepthService")
	if DepthService then
		DepthService:ReportDepth(depth)
	end
end

function DivingController:ToggleSprint(sprinting)
	if not isDiving then return end
	
	swimSpeed = sprinting and Config.Player.BaseSwimSpeed * Config.Player.SprintMultiplier or Config.Player.BaseSwimSpeed
end

function DivingController:TriggerCriticalOxygenWarning()
	-- Visual/audio warning would be triggered here
	-- UI controller would handle the display
	self:NotifyUI("CriticalOxygen")
end

function DivingController:GetCurrentGearTier()
	-- Would query DepthService or local cache
	return 1
end

function DivingController:NotifyUI(eventName, data)
	-- Communicates with UIController
	local UIController = Knit.GetController("UIController")
	if UIController then
		-- UIController:HandleDivingEvent(eventName, data)
	end
end

function DivingController:KnitStop()
	RunService:UnbindFromRenderStep("AbyssDiving")
end

return DivingController