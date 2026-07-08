--[[
    TutorialService — Knit service for player onboarding (first ~10 minutes).
    Manages an 8-step linear tutorial chain that introduces core mechanics.
    Self-destructs after completion. Only active for first-time players.
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))
local Players = game:GetService("Players")

local TutorialService = Knit.CreateService {
    Name = "TutorialService",
    Client = {
        -- ============================================================
        -- Signals
        -- ============================================================
        
        -- Fired when the player should advance to a new tutorial step
        TutorialStepStarted = Knit.CreateSignal(),
        -- Fired when the player completes a step
        TutorialStepCompleted = Knit.CreateSignal(),
        -- Fired when all 8 steps are done
        TutorialCompleted = Knit.CreateSignal(),
        
        -- ============================================================
        -- Queries
        -- ============================================================
        
        GetTutorialState = Knit.CreateSignal(),
        GetTutorialStep = Knit.CreateSignal(),
        
        -- ============================================================
        -- Actions
        -- ============================================================
        
        CompleteTutorialStep = Knit.CreateSignal(),
    }
}

-- ============================================================
-- Step Definitions
-- Each step has: step number, instruction, action type, reward, timeout
-- ============================================================

local TUTORIAL_STEPS = {
    {
        step = 1,
        title = "Welcome to the Deep",
        instruction = "Welcome, Explorer! The ocean depths are calling. Press [E] at the Diving Locker to begin.",
        actionType = "InteractDivingLocker",
        highlightTarget = "DivingLocker",
        rewardType = "Credits",
        rewardAmount = 10,
        timeout = 60,
        completionMessage = "Great! You found the locker.",
    },
    {
        step = 2,
        title = "Visit the Shop",
        instruction = "Head to the Shop to claim your basic gear. Press [B] or click the Shop button.",
        actionType = "OpenShop",
        highlightTarget = "ShopButton",
        rewardType = "Credits",
        rewardAmount = 15,
        timeout = 120,
        completionMessage = "Excellent! Basic Gear is yours — free!",
    },
    {
        step = 3,
        title = "Equip Your Gear",
        instruction = "Now equip your gear! Open your Inventory with [G] and click 'Equip' on Basic Gear.",
        actionType = "EquipGear",
        highlightTarget = "InventoryButton",
        rewardType = "Credits",
        rewardAmount = 10,
        timeout = 90,
        completionMessage = "Perfect! You're ready to dive.",
    },
    {
        step = 4,
        title = "First Dive",
        instruction = "Time to get wet! Walk to the dock and press [F] to dive into the Sunlight Zone.",
        actionType = "EnterWater",
        highlightTarget = "DockZone",
        rewardType = "Credits",
        rewardAmount = 25,
        timeout = 120,
        completionMessage = "Amazing view, isn't it?",
    },
    {
        step = 5,
        title = "Catch a Creature",
        instruction = "See that glowing fish? Click [Left Mouse] when the reticle lines up to catch it!",
        actionType = "CatchCreature",
        highlightTarget = "CreatureReticle",
        rewardType = "Credits",
        rewardAmount = 20,
        timeout = 180,
        completionMessage = "You caught a Clownfish! Nice work!",
        guaranteedCatch = true,  -- Server ensures tutorial creature is catchable
    },
    {
        step = 6,
        title = "Surface Safely",
        instruction = "Well caught! Now surface by pressing [F] or swimming up to the boat.",
        actionType = "Surface",
        highlightTarget = "SurfaceIndicator",
        rewardType = "Credits",
        rewardAmount = 20,
        timeout = 120,
        completionMessage = "Safe and sound!",
    },
    {
        step = 7,
        title = "Sell Your Catch",
        instruction = "Now sell that fish for Credits! Open your Collection with [C] and click 'Sell'.",
        actionType = "SellCreature",
        highlightTarget = "CollectionButton",
        rewardType = "Credits",
        rewardAmount = 30,  -- Bonus on top of normal sell price
        timeout = 120,
        completionMessage = "Your first Credits earned!",
    },
    {
        step = 8,
        title = "Upgrade & Continue",
        instruction = "You now have enough for the Scuba Kit! Open Shop [B] and buy it to explore deeper.",
        actionType = "PurchaseScubaKit",
        highlightTarget = "ShopScubaKit",
        rewardType = "Credits",
        rewardAmount = 50,
        timeout = 300,
        completionMessage = "🎉 Tutorial Complete! The depths await!",
        isFinalStep = true,
    },
}

-- ============================================================
-- Step Validators (server-side confirmation)
-- ============================================================

local function ValidateStep(player, profile, stepNum)
    if stepNum == 1 then
        -- Diving Locker interaction
        return profile.TutorialState and profile.TutorialState.StepCompleted and
            profile.TutorialState.StepCompleted[1] == true
    elseif stepNum == 2 then
        -- Opened Shop (Basic Gear purchase is handled by economy trigger)
        return profile.TutorialState and profile.TutorialState.StepCompleted and
            profile.TutorialState.StepCompleted[2] == true
    elseif stepNum == 3 then
        -- Equipped Basic Gear (owns Tier 1 gear)
        return profile.OwnedGearTiers and #profile.OwnedGearTiers >= 1
            and profile.CurrentGearTier and profile.CurrentGearTier >= 1
    elseif stepNum == 4 then
        -- Entered water (depth > 0)
        return (profile.MaxDepthReached or 0) >= 1
    elseif stepNum == 5 then
        -- Caught a creature
        return (profile.TotalCreaturesCollected or 0) >= 1
    elseif stepNum == 6 then
        -- Surfaced (tracked by tutorial state)
        return profile.TutorialState and profile.TutorialState.StepCompleted and
            profile.TutorialState.StepCompleted[6] == true
    elseif stepNum == 7 then
        -- Sold a creature
        return (profile.TotalCreaturesSold or 0) >= 1
    elseif stepNum == 8 then
        -- Purchased Scuba Kit (Tier 2)
        local hasTier2 = false
        if profile.OwnedGearTiers then
            for _, tier in ipairs(profile.OwnedGearTiers) do
                if tier == 2 then hasTier2 = true; break end
            end
        end
        return profile.CurrentGearTier and profile.CurrentGearTier >= 2 or hasTier2
    end
    return false
end

-- ============================================================
-- Internal State
-- ============================================================

local playerTutorialState = {}  -- { [UserId] = { currentStep = 1, stepTimer = nil } }
local stepValidators = {}       -- { [UserId] = { [stepNum] = function } }

-- ============================================================
-- Initialization
-- ============================================================

function TutorialService:KnitStart()
    print("[TutorialService] Initialized — Tutorial system ready")
end

function TutorialService:ReloadFromProfile(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profileSync = DataStoreManager:GetPlayerProfileSync(player)
    if not profileSync then return end
    
    -- Check if tutorial should be skipped (returning player)
    if (profileSync.TotalSessions or 0) > 0 or profileSync.TutorialState == nil then
        -- Auto-complete tutorial for returning players
        if not profileSync.TutorialState or not profileSync.TutorialState.Completed then
            DataStoreManager:UpdateProfile(player, function(profile)
                profile.TutorialState = {
                    Completed = true,
                    CurrentStep = 9,
                    StepCompleted = { [1] = true, [2] = true, [3] = true, [4] = true,
                                      [5] = true, [6] = true, [7] = true, [8] = true },
                    FirstJoinTime = profile.FirstJoinTime or os.time(),
                }
            end)
        end
        return
    end
    
    -- First-time player: load or initialize tutorial state
    local tutorialState = profileSync.TutorialState or {
        Completed = false,
        CurrentStep = 0,
        StepCompleted = {},
        FirstJoinTime = os.time(),
    }
    
    if not tutorialState.Completed then
        playerTutorialState[player.UserId] = {
            currentStep = tutorialState.CurrentStep or 0,
            stepTimer = nil,
        }
        
        -- If no step started, begin step 1
        if tutorialState.CurrentStep == 0 then
            self:AdvanceToStep(player, 1)
        else
            -- Resume from current step
            local stepToResume = tutorialState.CurrentStep
            -- Verify current step hasn't already been completed
            if tutorialState.StepCompleted and tutorialState.StepCompleted[stepToResume] then
                -- Find next incomplete step
                for s = stepToResume + 1, 8 do
                    if not tutorialState.StepCompleted[s] then
                        stepToResume = s
                        break
                    end
                end
                if stepToResume > 8 then
                    stepToResume = 8  -- Might be at final
                end
            end
            self:AdvanceToStep(player, stepToResume)
        end
    end
    
    print(string.format("[TutorialService] Loaded tutorial state for %s: Step %d/%d",
        player.Name, tutorialState.CurrentStep or 0, 8))
end

function TutorialService:PlayerRemoving(player)
    -- Cancel any pending timer
    local tState = playerTutorialState[player.UserId]
    if tState and tState.stepTimer then
        tState.stepTimer:Cancel()
        tState.stepTimer = nil
    end
    playerTutorialState[player.UserId] = nil
end

-- ============================================================
-- Step Management
-- ============================================================

function TutorialService:AdvanceToStep(player, stepNum)
    local tState = playerTutorialState[player.UserId]
    if not tState then
        tState = { currentStep = stepNum, stepTimer = nil }
        playerTutorialState[player.UserId] = tState
    end
    
    tState.currentStep = stepNum
    
    local stepDef = TUTORIAL_STEPS[stepNum]
    if not stepDef then
        -- Step 9 = completed
        self:CompleteTutorial(player)
        return
    end
    
    -- Update profile with current step
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    DataStoreManager:UpdateProfile(player, function(profile)
        if not profile.TutorialState then
            profile.TutorialState = {
                Completed = false,
                CurrentStep = 0,
                StepCompleted = {},
                FirstJoinTime = os.time(),
            }
        end
        profile.TutorialState.CurrentStep = stepNum
    end)
    
    -- Fire step started signal to client
    self.Client:Get("TutorialStepStarted"):Fire(player, {
        step = stepNum,
        totalSteps = 8,
        title = stepDef.title,
        instruction = stepDef.instruction,
        actionType = stepDef.actionType,
        highlightTarget = stepDef.highlightTarget,
        rewardType = stepDef.rewardType,
        rewardAmount = stepDef.rewardAmount,
        timeout = stepDef.timeout,
        completionMessage = stepDef.completionMessage,
    })
    
    -- Start timeout timer
    if tState.stepTimer then
        tState.stepTimer:Cancel()
    end
    
    -- Start a reminder loop (pings client every 30 seconds, sends timeout warning at 15s remaining)
    local startTime = os.time()
    tState.stepTimer = task.spawn(function()
        while task.wait(30) do
            local elapsed = os.time() - startTime
            local remaining = (stepDef.timeout or 60) - elapsed
            if remaining <= 0 then
                -- Timeout — send reminder/re-prompt
                self.Client:Get("TutorialStepStarted"):Fire(player, {
                    step = stepNum,
                    totalSteps = 8,
                    title = stepDef.title,
                    instruction = "Still here? " .. stepDef.instruction,
                    actionType = stepDef.actionType,
                    highlightTarget = stepDef.highlightTarget,
                    rewardType = stepDef.rewardType,
                    rewardAmount = stepDef.rewardAmount,
                    timeout = stepDef.timeout,
                    isReminder = true,
                    completionMessage = stepDef.completionMessage,
                })
                startTime = os.time()  -- Reset timeout
            elseif remaining <= 15 and (remaining % 5 == 0) then
                -- Subtle warning near timeout
                -- (optional: we can leave this as just the task wait loop)
            end
        end
    end)
end

function TutorialService:CompleteStepAction(player, stepNum)
    local tState = playerTutorialState[player.UserId]
    if not tState then return { success = false, reason = "No tutorial state" } end
    
    -- Verify it's the current step
    if tState.currentStep ~= stepNum then
        return { success = false, reason = "Step " .. stepNum .. " is not the current step" }
    end
    
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profile = DataStoreManager:GetPlayerProfileSync(player)
    
    -- Validate step was actually completed
    if not ValidateStep(player, profile, stepNum) then
        return { success = false, reason = "Step action not yet completed" }
    end
    
    -- Mark step as completed
    DataStoreManager:UpdateProfile(player, function(prof)
        if not prof.TutorialState then
            prof.TutorialState = {
                Completed = false,
                CurrentStep = 0,
                StepCompleted = {},
                FirstJoinTime = os.time(),
            }
        end
        if not prof.TutorialState.StepCompleted then
            prof.TutorialState.StepCompleted = {}
        end
        prof.TutorialState.StepCompleted[stepNum] = true
        prof.TutorialState.CurrentStep = stepNum + 1  -- Move to next step
    end)
    
    -- Award step reward
    local stepDef = TUTORIAL_STEPS[stepNum]
    if stepDef and stepDef.rewardType and stepDef.rewardAmount then
        local EconomyService = Knit.GetService("EconomyService")
        if stepDef.rewardType == "Credits" then
            EconomyService:AddCredits(player, stepDef.rewardAmount)
        end
    end
    
    -- Cancel step timer
    if tState.stepTimer then
        tState.stepTimer:Cancel()
        tState.stepTimer = nil
    end
    
    -- Fire step completed signal
    self.Client:Get("TutorialStepCompleted"):Fire(player, {
        step = stepNum,
        totalSteps = 8,
        completionMessage = stepDef and stepDef.completionMessage or "Step complete!",
        rewardType = stepDef and stepDef.rewardType,
        rewardAmount = stepDef and stepDef.rewardAmount,
    })
    
    -- Advance to next step or complete tutorial
    if stepDef and stepDef.isFinalStep then
        self:CompleteTutorial(player)
    else
        self:AdvanceToStep(player, stepNum + 1)
    end
    
    return { success = true, nextStep = stepNum + 1 }
end

function TutorialService:CompleteTutorial(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    
    -- Mark tutorial as completed
    DataStoreManager:UpdateProfile(player, function(profile)
        if not profile.TutorialState then
            profile.TutorialState = {}
        end
        profile.TutorialState.Completed = true
        profile.TutorialState.CurrentStep = 9
    end)
    
    -- Clean up state
    local tState = playerTutorialState[player.UserId]
    if tState and tState.stepTimer then
        tState.stepTimer:Cancel()
        tState.stepTimer = nil
    end
    playerTutorialState[player.UserId] = nil
    
    -- Fire completed signal
    self.Client:Get("TutorialCompleted"):Fire(player, {
        message = "🎉 Tutorial Complete! You're now ready to explore the depths on your own!",
    })
    
    print(string.format("[TutorialService] %s completed the tutorial!", player.Name))
end

-- ============================================================
-- Profile Migration (for existing players before tutorial existed)
-- ============================================================

function TutorialService:MigrateExistingPlayer(player)
    -- Called for players who already had progress before tutorial was added
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    DataStoreManager:UpdateProfile(player, function(profile)
        profile.TutorialState = {
            Completed = true,
            CurrentStep = 9,
            StepCompleted = { [1] = true, [2] = true, [3] = true, [4] = true,
                              [5] = true, [6] = true, [7] = true, [8] = true },
            FirstJoinTime = profile.FirstJoinTime or os.time(),
        }
    end)
end

-- ============================================================
-- Client Handlers
-- ============================================================

function TutorialService.Client:GetTutorialState(player)
    local self = TutorialService
    local tState = playerTutorialState[player.UserId]
    
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profile = DataStoreManager:GetPlayerProfileSync(player)
    
    if not profile then
        return { completed = true, currentStep = 0 }
    end
    
    local tutorialState = profile.TutorialState or { Completed = true }
    
    return {
        completed = tutorialState.Completed or false,
        currentStep = tState and tState.currentStep or tutorialState.CurrentStep or 0,
        totalSteps = 8,
        stepCompleted = tutorialState.StepCompleted or {},
    }
end

function TutorialService.Client:GetTutorialStep(player)
    -- Returns the instruction for the current tutorial step
    local self = TutorialService
    local tState = playerTutorialState[player.UserId]
    if not tState then
        return { active = false }
    end
    
    local stepDef = TUTORIAL_STEPS[tState.currentStep]
    if not stepDef then
        return { active = false }
    end
    
    return {
        active = true,
        step = stepDef.step,
        totalSteps = 8,
        title = stepDef.title,
        instruction = stepDef.instruction,
        actionType = stepDef.actionType,
        highlightTarget = stepDef.highlightTarget,
        rewardType = stepDef.rewardType,
        rewardAmount = stepDef.rewardAmount,
        completionMessage = stepDef.completionMessage,
    }
end

function TutorialService.Client:CompleteTutorialStep(player, stepNum)
    return TutorialService:CompleteStepAction(player, stepNum)
end

return TutorialService