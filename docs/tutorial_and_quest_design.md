# Tutorial & Quest System Design — Abyss of the Deep

**Author:** Agent Roblox Game Designer  
**Revision:** 1.0  
**Status:** Draft  
**Date:** July 2026  
**Target File:** `src/server/services/QuestService.lua`, `src/server/services/TutorialService.lua`, `src/shared/modules/Config.lua` (extensions)

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Tutorial System (First 10 Minutes)](#2-tutorial-system-first-10-minutes)
3. [Quest System Overview](#3-quest-system-overview)
4. [Quest Data Structures & Config](#4-quest-data-structures--config)
5. [Quest Categories](#5-quest-categories)
6. [Quest Service Implementation Plan](#6-quest-service-implementation-plan)
7. [Tutorial Service Implementation Plan](#7-tutorial-service-implementation-plan)
8. [UI/UX Integration Notes](#8-uiux-integration-notes)
9. [Monetization Hooks](#9-monetization-hooks)
10. [Quest Balance & Progression](#10-quest-balance--progression)

---

## 1. Design Philosophy

### Tutorial
- **Learn by doing.** Every mechanic is introduced through a guided action, not a wall of text.
- **Immediate reward.** Each tutorial step pays out Credits/XP so the player associates actions with progression.
- **No skip option on first playthrough.** New players must complete the tutorial chain. Returning players (checked via `profile.TotalSessions > 0`) can skip.
- **Non-blocking failure.** If a player runs out of oxygen during the tutorial dive, they surface at 0 cost and the tutorial resumes at the current step.

### Quests
- **3 pillars:** Daily (retention), Milestone (progression), Event (excitement/anomaly synergy).
- **Quest completion is a core loop extender** — players dive to complete quests, get rewarded, buy better gear, dive deeper.
- **Premium currency (Research Points) is the primary quest payout** for hard milestones. Credits are secondary.
- **Quest UI lives in the same HUD panel** (tab/toggle) alongside the collection journal.

---

## 2. Tutorial System (First 10 Minutes)

### 2.1 Flow Summary

The tutorial is a **linear chain of 8 steps** that introduces every core mechanic in sequence. Each step has a trigger condition, an instruction, and a reward. The player cannot proceed to the next step until the current one is completed.

```
Step 1: Welcome ──► Step 2: Visit Shop ──► Step 3: Equip Gear ──►
Step 4: First Dive ──► Step 5: Catch a Creature ──► Step 6: Surface ──►
Step 7: Sell & Earn ──► Step 8: Upgrade & Continue
```

### 2.2 Step Details

#### Step 1: Welcome to the Deep
| Field | Value |
|-------|-------|
| **Trigger** | Player joins for the first time (`TotalSessions == 0`) |
| **Instruction** | "Welcome, Explorer! The ocean depths are calling. Let's get you started." — fade-in text + ambient sound |
| **Action Required** | Press [E] to interact with the Diving Locker (spawn-point prop) |
| **Reward** | 10 Credits |
| **UI** | Full-screen overlay with animated prompt arrow pointing at the Diving Locker |
| **Timeout** | 60 seconds → highlight locker with pulsing glow |

#### Step 2: Visit the Shop
| Field | Value |
|-------|-------|
| **Trigger** | Step 1 completed |
| **Instruction** | "Head to the Shop to claim your basic gear." |
| **Action Required** | Open the Shop UI (press [B] or click Shop button) |
| **Reward** | 15 Credits |
| **UI** | Shop panel opens automatically with "Basic Gear" pre-highlighted; text: "This is yours — free!" |
| **Edge Case** | If player closes shop, re-prompt after 10 seconds |

#### Step 3: Equip Your Gear
| Field | Value |
|-------|-------|
| **Trigger** | Step 2 completed (Basic Gear purchased) |
| **Instruction** | "Great! Now equip your gear. Press [G] to open your inventory." |
| **Action Required** | Open inventory and click "Equip" on Basic Gear |
| **Reward** | 10 Credits |
| **UI** | Inventory panel highlights the Basic Gear slot; checkmark overlay on equip |

#### Step 4: First Dive
| Field | Value |
|-------|-------|
| **Trigger** | Step 3 completed |
| **Instruction** | "Time to get wet! Walk to the dock and press [F] to dive." |
| **Action Required** | Enter the water / trigger dive zone at the dock (Sunlight Zone, depth range 0-10m) |
| **Reward** | 25 Credits |
| **UI** | HUD fades in showing Oxygen bar, Depth gauge, and Credits counter. Arrow points down. |
| **Edge Cases** | If player surfaces before catching a creature, prompt "You need to go deeper — keep diving!" |

#### Step 5: Catch a Creature
| Field | Value |
|-------|-------|
| **Trigger** | Step 4 completed (player is underwater) |
| **Instruction** | "See that glowing fish? Click [Left Mouse] to cast your line and try to catch it!" |
| **Action Required** | Successfully catch a creature (minigame: click when the reticle lines up — 3 attempts guaranteed succeed on 3rd) |
| **Reward** | 20 Credits + the caught creature (guaranteed Clownfish, Common rarity) |
| **UI** | Crosshair reticle appears. Creature glows with a soft outline. On catch: "New Discovery!" popup with creature card. |
| **Edge Cases** | If player's collection is full (unlikely at 50 slots), show "Collection Full!" and auto-sell the creature |

#### Step 6: Surface Safely
| Field | Value |
|-------|-------|
| **Trigger** | Step 5 completed (creature caught) |
| **Instruction** | "Well caught! Now surface by pressing [F] or swimming up to the boat." |
| **Action Required** | Surface (leave water / trigger surface zone) |
| **Reward** | 20 Credits |
| **UI** | Oxygen bar pulses green as player ascends. "Surface!" text. Dive summary panel appears with depth + oxygen stats. |

#### Step 7: Sell Your Catch
| Field | Value |
|-------|-------|
| **Trigger** | Step 6 completed |
| **Instruction** | "Now sell that fish for Credits! Open your Collection with [C] and click 'Sell' on the Clownfish." |
| **Action Required** | Open collection → select creature → click Sell |
| **Reward** | Double the normal sell price for that creature (bonus tutorial payout: ~20-30 Cr extra) |
| **UI** | Collection panel opens. Creature card has pulsing "SELL" button. After sell: Credits-earned animation (+) |

#### Step 8: Upgrade & Continue
| Field | Value |
|-------|-------|
| **Trigger** | Step 7 completed |
| **Instruction** | "You now have enough Credits for the Scuba Kit! Open the Shop [B] and buy it to explore deeper waters." |
| **Action Required** | Purchase the Scuba Kit (Tier 2 gear, 150 Credits) — player now has ~90-100 Credits from tutorial rewards, needs 50-60 more; instruction prompts a few more catches if short |
| **Reward** | Bonus 50 Credits on purchase + Scuba Kit equipped |
| **UI** | "🎉 Tutorial Complete!" celebration screen with stats: creatures caught, Credits earned, depth reached |
| **Follow-up** | Quest tab unlocks. First Daily Quest auto-accepted. Player is now free. |

### 2.3 Tutorial Persistence

```lua
-- ProfileTemplate.lua additions (persistent fields)
TutorialState = {
    Completed = false,         -- Set to true after Step 8
    CurrentStep = 0,           -- 0 = not started, 1-8 = in progress, 9 = completed
    StepCompleted = {},        -- { 1 = true, 2 = true, ... }
    FirstJoinTime = 0,         -- os.time() of first join
}
```

**Skip Logic:** If `profile.TotalSessions > 0` OR `profile.MaxDepthReached > 200`, tutorial is auto-completed and skipped on load. Existing players retroactively marked as tutorial-complete.

---

## 3. Quest System Overview

### 3.1 Quest Types

| Type | Sub-Type | Reset | Max Active | Payout |
|------|----------|-------|------------|--------|
| **Daily** | Dive, Catch, Sell, Explore | Daily (server reset) | 3 at a time | Credits, Consumables |
| **Milestone** | Depth, Collection, Gear, Base | One-time (permanent) | Always active (auto-tracked) | RP, Titles, Cosmetic |
| **Event** | Anomaly-specific | Per anomaly occurrence | 1 at a time | Credits, RP, Exclusive |
| **Achievement** | Stats-based (total catches, dives, etc.) | One-time | Always active | RP, Titles, Badges |

### 3.2 Active Quest Limits
- **Daily quests:** Player gets 3 per day. Can abandon 1 per day to re-roll (with a 30-min cooldown).
- **Milestone quests:** Unlimited — auto-tracked in the background. Player sees the next 5 upcoming milestones.
- **Event quests:** 1 per active anomaly. Expires when anomaly ends.
- **Achievements:** All visible in a "Journal" tab. Auto-complete on meeting conditions.

### 3.3 Quest Lifecycle
```
Available ──► Accepted ──► In Progress ──► Completed ──► Claimed
                                                  │
                                                  ▼
                                             (Reward given)
```

- **Available:** Player can see the quest but hasn't accepted it. Daily quests are auto-offered. Milestones auto-track.
- **Accepted:** Quest is pinned to the active list. Counters begin.
- **Completed:** Conditions met — player must open the quest UI and click "Claim" to receive rewards.
- **Claimed:** Reward delivered. Quest is archived (for dailies: expires at next reset; for milestones: permanently complete).

---

## 4. Quest Data Structures & Config

### 4.1 Config Extension (Config.lua additions)

```lua
-- [[ Add to Config.lua ]]

-- ============================================================
-- Quest System Configuration
-- ============================================================

Config.QuestSystem = {
    Enabled = true,
    MaxDailyQuests = 3,
    DailyQuestPoolSize = 8,         -- Number of dailies to choose from
    DailyResetHour = 0,             -- UTC hour for daily reset
    ReRollCooldown = 1800,          -- 30 min cooldown between re-rolls
    MaxReRollsPerDay = 1,
    NotificationDuration = 5,       -- Seconds quest notification stays
}

-- ============================================================
-- Daily Quests (repeatable, resets daily)
-- ============================================================

Config.DailyQuests = {
    --- Dive-based dailies ---
    DeepDiver = {
        Name = "Deep Diver",
        Description = "Reach 100m depth in a single dive",
        Category = "Daily",
        Conditions = {
            { type = "MaxDepthReached", value = 100, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 50 },
            { type = "XP", amount = 100 },
        },
        Weight = 20,
        MinPlayerLevel = 1,
        MaxPlayerDepth = 200,      -- Only offered to players who haven't passed Twilight
    },
    TwilightExplorer = {
        Name = "Twilight Explorer",
        Description = "Reach the Twilight Zone (200m+)",
        Category = "Daily",
        Conditions = {
            { type = "MaxDepthReached", value = 200, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 100 },
            { type = "ResearchPoints", amount = 2 },
        },
        Weight = 15,
        MinPlayerLevel = 3,
        MinPlayerDepth = 200,
    },
    MidnightDescent = {
        Name = "Midnight Descent",
        Description = "Descend to 1000m or deeper",
        Category = "Daily",
        Conditions = {
            { type = "MaxDepthReached", value = 1000, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 200 },
            { type = "ResearchPoints", amount = 3 },
        },
        Weight = 10,
        MinPlayerLevel = 8,
        MinPlayerDepth = 1000,
    },
    AbyssalVoyage = {
        Name = "Abyssal Voyage",
        Description = "Reach 4000m depth",
        Category = "Daily",
        Conditions = {
            { type = "MaxDepthReached", value = 4000, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 350 },
            { type = "ResearchPoints", amount = 5 },
        },
        Weight = 5,
        MinPlayerLevel = 15,
        MinPlayerDepth = 4000,
    },

    --- Catch-based dailies ---
    CreatureCollector = {
        Name = "Creature Collector",
        Description = "Catch 5 creatures in one session",
        Category = "Daily",
        Conditions = {
            { type = "CreaturesCaughtInSession", value = 5, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 40 },
            { type = "XP", amount = 75 },
        },
        Weight = 25,
        MinPlayerLevel = 1,
    },
    RareHunter = {
        Name = "Rare Hunter",
        Description = "Catch 2 Rare or better creatures",
        Category = "Daily",
        Conditions = {
            { type = "CreaturesCaughtByRarity", rarity = "Rare", count = 2, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 100 },
            { type = "ResearchPoints", amount = 2 },
        },
        Weight = 15,
        MinPlayerLevel = 5,
        MinPlayerDepth = 200,
    },
    EpicSighting = {
        Name = "Epic Sighting",
        Description = "Catch 1 Epic or Legendary creature",
        Category = "Daily",
        Conditions = {
            { type = "CreaturesCaughtByRarity", rarity = "Epic", count = 1, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 200 },
            { type = "ResearchPoints", amount = 5 },
        },
        Weight = 8,
        MinPlayerLevel = 10,
        MinPlayerDepth = 1000,
    },

    --- Exploration dailies ---
    OxygenEconomist = {
        Name = "Oxygen Economist",
        Description = "Complete a dive using less than 50% of your oxygen",
        Category = "Daily",
        Conditions = {
            { type = "OxygenUsed", value = 50, comparison = "<=", scope = "single_dive" },
        },
        Rewards = {
            { type = "Credits", amount = 60 },
        },
        Weight = 18,
        MinPlayerLevel = 1,
    },
    DeepTreasure = {
        Name = "Deep Treasure",
        Description = "Collect 15 Scrap and 5 Crystal in one dive",
        Category = "Daily",
        Conditions = {
            { type = "ScrapCollected", value = 15, comparison = ">=", scope = "single_dive" },
            { type = "CrystalCollected", value = 5, comparison = ">=", scope = "single_dive" },
        },
        Rewards = {
            { type = "Credits", amount = 80 },
            { type = "Scrap", amount = 10 },
        },
        Weight = 12,
        MinPlayerLevel = 3,
        MinPlayerDepth = 200,
    },
}

-- ============================================================
-- Milestone Quests (one-time progression)
-- ============================================================

Config.MilestoneQuests = {
    --- Depth Milestones ---
    FirstSteps = {
        Name = "First Steps",
        Description = "Reach 50m depth for the first time",
        Category = "Milestone",
        Order = 1,
        Conditions = {
            { type = "MaxDepthReached", value = 50, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 50 },
            { type = "XP", amount = 100 },
        },
    },
    TwilightReached = {
        Name = "Into the Twilight",
        Description = "Reach 200m depth",
        Category = "Milestone",
        Order = 2,
        Conditions = {
            { type = "MaxDepthReached", value = 200, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 150 },
            { type = "ResearchPoints", amount = 2 },
        },
        Prerequisites = { "FirstSteps" },
    },
    MidnightReached = {
        Name = "Midnight Marauder",
        Description = "Reach 1000m depth",
        Category = "Milestone",
        Order = 3,
        Conditions = {
            { type = "MaxDepthReached", value = 1000, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 400 },
            { type = "ResearchPoints", amount = 5 },
            { type = "Title", title = "Midnight Marauder" },
        },
        Prerequisites = { "TwilightReached" },
    },
    AbyssWalker = {
        Name = "Abyss Walker",
        Description = "Reach 4000m depth",
        Category = "Milestone",
        Order = 4,
        Conditions = {
            { type = "MaxDepthReached", value = 4000, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 800 },
            { type = "ResearchPoints", amount = 10 },
            { type = "Title", title = "Abyss Walker" },
        },
        Prerequisites = { "MidnightReached" },
    },
    TrenchDweller = {
        Name = "Trench Dweller",
        Description = "Reach 6000m depth",
        Category = "Milestone",
        Order = 5,
        Conditions = {
            { type = "MaxDepthReached", value = 6000, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 1500 },
            { type = "ResearchPoints", amount = 25 },
            { type = "Title", title = "Trench Dweller" },
        },
        Prerequisites = { "AbyssWalker" },
    },
    TheDeepestDark = {
        Name = "The Deepest Dark",
        Description = "Reach the Trench floor (11000m)",
        Category = "Milestone",
        Order = 6,
        Conditions = {
            { type = "MaxDepthReached", value = 11000, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 3000 },
            { type = "ResearchPoints", amount = 50 },
            { type = "Title", title = "Trench Dweller" },
            { type = "Cosmetic", item = "Void Walker Suit Skin" },
        },
        Prerequisites = { "TrenchDweller" },
    },

    --- Collection Milestones ---
    BeginnerCollector = {
        Name = "Beginner Collector",
        Description = "Catch 10 different species",
        Category = "Milestone",
        Order = 10,
        Conditions = {
            { type = "UniqueSpeciesCaught", value = 10, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 100 },
            { type = "Consumable", item = "OxygenTank", count = 2 },
        },
    },
    SeasonedExplorer = {
        Name = "Seasoned Explorer",
        Description = "Catch 20 different species",
        Category = "Milestone",
        Order = 11,
        Conditions = {
            { type = "UniqueSpeciesCaught", value = 20, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 300 },
            { type = "ResearchPoints", amount = 5 },
        },
        Prerequisites = { "BeginnerCollector" },
    },
    MasterNaturalist = {
        Name = "Master Naturalist",
        Description = "Complete the entire bestiary (catch all 30 species)",
        Category = "Milestone",
        Order = 12,
        Conditions = {
            { type = "UniqueSpeciesCaught", value = 30, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 2000 },
            { type = "ResearchPoints", amount = 50 },
            { type = "Title", title = "Master Naturalist" },
            { type = "Cosmetic", item = "Bestiary Completion Aura" },
        },
        Prerequisites = { "SeasonedExplorer" },
    },

    --- Gear Milestones ---
    GearUpgraded = {
        Name = "Proper Equipment",
        Description = "Upgrade to Scuba Kit (Tier 2)",
        Category = "Milestone",
        Order = 20,
        Conditions = {
            { type = "GearTierReached", value = 2, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 50 },
        },
    },
    AdvancedDiver = {
        Name = "Advanced Diver",
        Description = "Upgrade to Advanced Dive Suit (Tier 3)",
        Category = "Milestone",
        Order = 21,
        Conditions = {
            { type = "GearTierReached", value = 3, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 200 },
            { type = "ResearchPoints", amount = 5 },
        },
        Prerequisites = { "GearUpgraded" },
    },
    BathysphereCaptain = {
        Name = "Bathysphere Captain",
        Description = "Upgrade to Bathysphere (Tier 4)",
        Category = "Milestone",
        Order = 22,
        Conditions = {
            { type = "GearTierReached", value = 4, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 500 },
            { type = "ResearchPoints", amount = 10 },
        },
        Prerequisites = { "AdvancedDiver" },
    },
    ExosuitPilot = {
        Name = "Exosuit Pilot",
        Description = "Upgrade to Abyssal Exosuit (Tier 5)",
        Category = "Milestone",
        Order = 23,
        Conditions = {
            { type = "GearTierReached", value = 5, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 1500 },
            { type = "ResearchPoints", amount = 25 },
            { type = "Title", title = "Exosuit Pilot" },
        },
        Prerequisites = { "BathysphereCaptain" },
    },

    --- Base Building Milestones ---
    HomeSweetHome = {
        Name = "Home Sweet Home",
        Description = "Place your first Base Module",
        Category = "Milestone",
        Order = 30,
        Conditions = {
            { type = "BaseModulesPlaced", value = 1, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 100 },
            { type = "Scrap", amount = 15 },
        },
    },
    BaseExpansion = {
        Name = "Base Expansion",
        Description = "Place 5 Base Modules total",
        Category = "Milestone",
        Order = 31,
        Conditions = {
            { type = "BaseModulesPlaced", value = 5, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 300 },
            { type = "Crystal", amount = 10 },
        },
        Prerequisites = { "HomeSweetHome" },
    },
    FullyOperational = {
        Name = "Fully Operational",
        Description = "Upgrade any Base Module to Tier 3",
        Category = "Milestone",
        Order = 32,
        Conditions = {
            { type = "BaseModuleMaxTier", value = 3, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 500 },
            { type = "ResearchPoints", amount = 10 },
        },
        Prerequisites = { "BaseExpansion" },
    },
}

-- ============================================================
-- Event Quests (tied to Anomaly events)
-- ============================================================

Config.EventQuests = {
    CorruptedDepths = {
        Name = "Corrupted Depths Survivor",
        Description = "Catch 3 creatures during a Corrupted Depths event",
        Category = "Event",
        AnomalyKey = "CorruptedDepths",
        Conditions = {
            { type = "CatchDuringAnomaly", anomaly = "CorruptedDepths", count = 3, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 150 },
            { type = "ResearchPoints", amount = 3 },
        },
    },
    EnchantedWaters = {
        Name = "Enchanted Waters Bounty",
        Description = "Catch 1 Rare+ creature during an Enchanted Waters event",
        Category = "Event",
        AnomalyKey = "EnchantedWaters",
        Conditions = {
            { type = "CatchRarityDuringAnomaly", anomaly = "EnchantedWaters", rarity = "Rare", count = 1, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 200 },
            { type = "ResearchPoints", amount = 5 },
        },
    },
    BioluminescentBloom = {
        Name = "Bioluminescent Collector",
        Description = "Catch 8 creatures during a Bioluminescent Bloom",
        Category = "Event",
        AnomalyKey = "BioluminescentBloom",
        Conditions = {
            { type = "CatchDuringAnomaly", anomaly = "BioluminescentBloom", count = 8, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 100 },
            { type = "Consumable", item = "RareLure", count = 2 },
        },
    },
    AbyssalSurge = {
        Name = "Abyssal Surge Rider",
        Description = "Descend to 500m deeper than your previous max during an Abyssal Surge",
        Category = "Event",
        AnomalyKey = "AbyssalSurge",
        Conditions = {
            { type = "DepthGainDuringAnomaly", anomaly = "AbyssalSurge", value = 500, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 300 },
            { type = "ResearchPoints", amount = 8 },
            { type = "XP", amount = 500 },
        },
    },
    AncientMigration = {
        Name = "Ancient Migration Witness",
        Description = "Catch or spot 1 Legendary creature during an Ancient Migration",
        Category = "Event",
        AnomalyKey = "AncientMigration",
        Conditions = {
            { type = "CatchRarityDuringAnomaly", anomaly = "AncientMigration", rarity = "Legendary", count = 1, comparison = ">=" },
        },
        Rewards = {
            { type = "Credits", amount = 1000 },
            { type = "ResearchPoints", amount = 25 },
            { type = "Title", title = "Ancient Witness" },
        },
    },
}

-- ============================================================
-- Achievement Quests (stat-based, permanent)
-- ============================================================

Config.Achievements = {
    FirstSale = {
        Name = "First Sale",
        Description = "Sell your first creature",
        Category = "Achievement",
        Conditions = {
            { type = "TotalCreaturesSold", value = 1, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 25 },
        },
    },
    Centurion = {
        Name = "Centurion",
        Description = "Catch 100 creatures total",
        Category = "Achievement",
        Conditions = {
            { type = "TotalCreaturesCollected", value = 100, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 300 },
            { type = "ResearchPoints", amount = 5 },
        },
    },
    ThousandDives = {
        Name = "Thousand Dives",
        Description = "Complete 100 dives total",
        Category = "Achievement",
        Conditions = {
            { type = "TotalDives", value = 100, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 500 },
            { type = "ResearchPoints", amount = 10 },
            { type = "Title", title = "Veteran Diver" },
        },
    },
    ShinyHunter = {
        Name = "Shiny Hunter",
        Description = "Catch 5 Shiny (alternate-color) creatures",
        Category = "Achievement",
        Conditions = {
            { type = "ShinyCreaturesCaught", value = 5, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 500 },
            { type = "ResearchPoints", amount = 10 },
            { type = "Title", title = "Shiny Hunter" },
        },
    },
    WhaleWatcher = {
        Name = "Whale Watcher",
        Description = "Catch 10 Legendary creatures total",
        Category = "Achievement",
        Conditions = {
            { type = "LegendaryCaught", value = 10, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 2000 },
            { type = "ResearchPoints", amount = 50 },
            { type = "Title", title = "Leviathan Bane" },
        },
    },
    FullBestiary = {
        Name = "Full Bestiary",
        Description = "Discover all 30+ species in the game",
        Category = "Achievement",
        Conditions = {
            { type = "UniqueSpeciesCaught", value = 30, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "ResearchPoints", amount = 100 },
            { type = "Cosmetic", item = "Bestiary Master Crown" },
            { type = "Title", title = "Living Encyclopedia" },
        },
    },
    BaseArchitect = {
        Name = "Base Architect",
        Description = "Place 10 Base Modules total",
        Category = "Achievement",
        Conditions = {
            { type = "BaseModulesPlaced", value = 10, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 500 },
            { type = "Title", title = "Base Architect" },
        },
    },
    Millionaire = {
        Name = "Millionaire",
        Description = "Earn a total of 10,000 Credits over your lifetime",
        Category = "Achievement",
        Conditions = {
            { type = "LifetimeCreditsEarned", value = 10000, comparison = ">=", scope = "lifetime" },
        },
        Rewards = {
            { type = "Credits", amount = 1000 },
            { type = "ResearchPoints", amount = 25 },
            { type = "Title", title = "Millionaire" },
        },
    },
}
```

### 4.2 Profile Template Extensions

```lua
-- [[ Add to ProfileTemplate.lua defaults ]]

-- Quest tracking
ActiveQuests = {},          -- { { questKey: string, questType: string, progress: {conditionIndex: currentValue}, acceptedAt: number }, ... }
CompletedQuests = {},       -- { [questKey] = { completedAt: number, claims: number } } — for dailies, claims tracks claim count
ClaimedQuests = {},         -- { [questKey] = true } — one-time quests that have been claimed

-- Daily quest state
DailyQuestState = {
    RefreshDay = 0,         -- Last daily-question-refresh day (format: YYYYMMDD)
    AcceptedDailyKeys = {},  -- { key1, key2, key3 } — up to 3 current daily quest keys
    ReRollsUsed = 0,         -- Count of re-rolls used today
    LastReRollTime = 0,      -- os.time() of last re-roll
    CompletedToday = {},     -- { key1 = true, key2 = true }
}

-- Tutorial state
TutorialState = {
    Completed = false,
    CurrentStep = 0,
    StepCompleted = {},
    FirstJoinTime = 0,
}

-- Session tracking (resets on each dive)
SessionQuestProgress = {
    MaxDepth = 0,
    OxygenUsed = 0,
    CreaturesCaught = {},       -- { creatureId -> count }
    RarityCounts = {},          -- { ["Rare"] = 2, ["Epic"] = 1, ... }
    ScrapCollected = 0,
    CrystalCollected = 0,
    StartDepth = 0,
}
```

---

## 5. Quest Categories (Detailed)

### 5.1 Daily Quests
- **Refresh:** All dailies reset at 00:00 UTC daily.
- **Selection:** Server picks `DailyQuestPoolSize` (8) quests from the pool, weighted by `Weight`. Player is offered 3 to accept.
- **Re-roll:** Player can re-roll 1 daily per day (30-min cooldown). The re-rolled quest is replaced with a random one from the remaining pool.
- **Completion:** Progress resets daily. If a quest is 90% done at reset, it fails — the player must start fresh.
- **Rewards:** Primarily Credits + XP. Higher-level dailies also pay Research Points.

### 5.2 Milestone Quests
- **Permanent:** Never expire. Once completed, cannot be done again.
- **Prerequisites:** Some milestones require prior milestones (e.g., "Twilight Reached" before "Midnight Reached").
- **Auto-track:** These quests don't need to be "accepted." The system evaluates them on every relevant event.
- **UI:** The Milestone tab shows the NEXT 5 upcoming milestones with a progress bar for each.
- **Notifications:** A toast appears when a milestone is completed: "🏆 Twilight Reached! Claim your reward!"

### 5.3 Event Quests
- **Tied to anomalies:** Only active when the named anomaly is running.
- **Auto-accept:** When an anomaly starts, any player currently diving has the event quest auto-accepted.
- **Expiration:** If the anomaly ends before the quest is completed, the quest is removed.
- **Exclusivity:** Event quests reward themed cosmetics/titles that cannot be obtained otherwise — strong FOMO driver.

### 5.4 Achievements
- **Background tracking:** Like milestones, achievements are always active.
- **Broad scope:** Cover lifetime stats (total dives, total creatures, shiny catches, etc.).
- **Prestige rewards:** Many achievements grant titles (visible above the player's name) or exclusive cosmetic effects.
- **Badge integration:** Some achievements correspond to Roblox platform badges (visible on player profiles).

---

## 6. Quest Service Implementation Plan

### 6.1 Knit Service Structure

```lua
-- QuestService.lua — Knit service for quest lifecycle management
-- Integrates with CreatureService, DepthService, EconomyService, AnomalyService, DataStoreManager

QuestService = Knit.CreateService {
    Name = "QuestService",
    Client = {
        -- Signals
        QuestProgressUpdated = Knit.CreateSignal(),   -- Fired when any quest progress changes
        QuestCompleted = Knit.CreateSignal(),           -- Fired when a quest becomes completable
        QuestClaimed = Knit.CreateSignal(),             -- Fired when rewards are claimed
        DailyQuestRefresh = Knit.CreateSignal(),        -- Fired when daily quests refresh
        EventQuestStarted = Knit.CreateSignal(),        -- Fired when an event quest is auto-accepted
        
        -- Queries
        GetActiveQuests = Knit.CreateSignal(),          -- Returns all active quests + progress
        GetCompletedQuests = Knit.CreateSignal(),       -- Returns completed but unclaimed quests
        GetAvailableQuests = Knit.CreateSignal(),       -- Returns quests available to accept
        GetQuestCatalog = Knit.CreateSignal(),          -- Returns all milestone + achievement definitions
        
        -- Actions
        AcceptDailyQuest = Knit.CreateSignal(),         -- Accept a daily quest from the offered pool
        ClaimQuestReward = Knit.CreateSignal(),         -- Claim rewards for a completed quest
        ReRollDailyQuest = Knit.CreateSignal(),         -- Re-roll one daily quest
    }
}
```

### 6.2 Core Methods

| Method | Description | When Called |
|--------|-------------|-------------|
| `KnitStart()` | Registers event hooks with CreatureService, DepthService, AnomalyService, EconomyService | On game start |
| `ReloadFromProfile(player)` | Loads quest state from profile data | On player join |
| `EvaluateCondition(player, condition, currentValue)` | Checks if a single condition is met | On each relevant event |
| `UpdateQuestProgress(player, eventType, eventData)` | Core — called by hooks to update all active quest progress | On catch, depth change, surface, anomaly start/end |
| `CompleteQuest(player, questKey)` | Marks quest as completable (not yet claimed) | When all conditions met |
| `ClaimReward(player, questKey)` | Delivers rewards, records claim | Player clicks "Claim" |
| `RefreshDailyQuests(player)` | Resets daily quest pool | On daily reset or player join |
| `SaveQuestState(player)` | Persists to profile | On claim, accept, re-roll |

### 6.3 Event Hooks (Registration in KnitStart)

```lua
-- Hook into CreatureService creature catch
CreatureService:OnCreatureCaught(player, creatureData) ->
    QuestService:UpdateQuestProgress(player, "CreatureCaught", creatureData)

-- Hook into DepthService depth update
DepthService:OnDepthUpdate(player, newDepth, maxDepth) ->
    QuestService:UpdateQuestProgress(player, "DepthUpdate", { newDepth = newDepth, maxDepth = maxDepth })

-- Hook into DepthService surface
DepthService:OnSurface(player, diveStats) ->
    QuestService:UpdateQuestProgress(player, "DiveComplete", diveStats)

-- Hook into EconomyService sell
EconomyService:OnCreatureSold(player, creatureData) ->
    QuestService:UpdateQuestProgress(player, "CreatureSold", creatureData)

-- Hook into EconomyService gear purchase
EconomyService:OnGearPurchased(player, gearTier) ->
    QuestService:UpdateQuestProgress(player, "GearPurchased", { tier = gearTier })

-- Hook into AnomalyService
AnomalyService:OnAnomalyStarted(anomalyKey) ->
    QuestService:AutoAcceptEventQuests(anomalyKey)

AnomalyService:OnAnomalyEnded(anomalyKey) ->
    QuestService:RemoveExpiredEventQuests(anomalyKey)

-- Hook into BaseBuildingService
BaseBuildingService:OnModulePlaced(player, moduleType) ->
    QuestService:UpdateQuestProgress(player, "ModulePlaced", { moduleType = moduleType })
```

### 6.4 Condition Evaluation Logic

Each quest condition has the format:
```lua
{ type = string, value = number/string, comparison = ">=" | "==" | ">", scope = "session" | "single_dive" | "lifetime" }
```

Scope defines WHERE the counter resets:
- `"lifetime"` → stored in profile, never resets (for milestones, achievements)
- `"single_dive"` → stored in `SessionQuestProgress`, resets each dive surface
- `"session"` → stored in memory, resets on player leave
- (no scope) → uses a server-managed counter from events

**Condition types to implement:**
| Type | Source | Scope |
|------|--------|-------|
| `MaxDepthReached` | DepthService depth update | single_dive or lifetime |
| `CreaturesCaughtInSession` | CreatureService catch event | session |
| `CreaturesCaughtByRarity` | CreatureService catch event | session |
| `OxygenUsed` | OxygenService tick aggregate | single_dive |
| `ScrapCollected` | EconomyService resource add | single_dive |
| `CrystalCollected` | EconomyService resource add | single_dive |
| `CatchDuringAnomaly` | CreatureService + AnomalyService cross-check | session |
| `CatchRarityDuringAnomaly` | CreatureService + AnomalyService cross-check | session |
| `DepthGainDuringAnomaly` | DepthService + AnomalyService | single_dive |
| `TotalCreaturesSold` | EconomyService sell event | lifetime |
| `UniqueSpeciesCaught` | CreatureService first-discovery event | lifetime |
| `GearTierReached` | EconomyService gear purchase | lifetime |
| `BaseModulesPlaced` | BaseBuildingService module placed | lifetime |
| `BaseModuleMaxTier` | BaseBuildingService module upgrade | lifetime |
| `TotalCreaturesCollected` | EconomyService stat | lifetime |
| `TotalDives` | DepthService surface event counter | lifetime |
| `ShinyCreaturesCaught` | CreatureService catch event (isShiny) | lifetime |
| `LegendaryCaught` | CreatureService catch event (rarity) | lifetime |
| `LifetimeCreditsEarned` | EconomyService stat | lifetime |

---

## 7. Tutorial Service Implementation Plan

### 7.1 Knit Service Structure

```lua
-- TutorialService.lua — Lightweight Knit service for tutorial step management
-- Only active for first-time players. Self-destructs after tutorial completion.

TutorialService = Knit.CreateService {
    Name = "TutorialService",
    Client = {
        -- Signals
        TutorialStepStarted = Knit.CreateSignal(),      -- Fired when a new step begins
        TutorialStepCompleted = Knit.CreateSignal(),     -- Fired when a step is finished
        TutorialCompleted = Knit.CreateSignal(),         -- Fired when all 8 steps done
        
        -- Queries
        GetTutorialState = Knit.CreateSignal(),          -- Returns current step + completed set
        GetTutorialStep = Knit.CreateSignal(),           -- Returns instruction for current step
        
        -- Actions
        CompleteTutorialStep = Knit.CreateSignal(),      -- Called by client UI when step action is done
        SkipTutorial = Knit.CreateSignal(),              -- Only for returning players
    }
}
```

### 7.2 Step Validation

Each step has a server-side validation function that checks whether the player has actually performed the required action:

```lua
-- Step validation map
local StepValidators = {
    [1] = function(player, profile)
        -- Step 1: Player pressed [E] at the Diving Locker
        return profile.TutorialState.StepCompleted[1] == true
    end,
    [2] = function(player, profile)
        -- Step 2: Player opened the Shop UI
        return profile.TutorialState.StepCompleted[2] == true
    end,
    [3] = function(player, profile)
        -- Step 3: Player equipped Basic Gear (gearTier >= 1 and owned)
        return profile.OwnedGearTiers and #profile.OwnedGearTiers >= 1
    end,
    [4] = function(player, profile)
        -- Step 4: Player is underwater (monitored by DepthService flag)
        return profile.MaxDepthReached >= 1
    end,
    [5] = function(player, profile)
        -- Step 5: Player has at least 1 creature in collection
        return profile.TotalCreaturesCollected >= 1
    end,
    [6] = function(player, profile)
        -- Step 6: Player has surfaced (surface event fired)
        return profile.TutorialState.StepCompleted[6] == true
    end,
    [7] = function(player, profile)
        -- Step 7: Player has sold a creature
        return profile.TotalCreaturesSold >= 1
    end,
    [8] = function(player, profile)
        -- Step 8: Player purchased Scuba Kit (Tier 2 owned)
        return profile.OwnedGearTiers and #profile.OwnedGearTiers >= 2
    end,
}
```

### 7.3 State Transition Flow

```
Player Joins (TotalSessions == 0)
  │
  ▼
TutorialService:KnitStart()
  │
  ▼
Check profile.TutorialState.Completed
  ├── true → SkipTutorial(), self-destruct service, return
  └── false → Load TutorialState.CurrentStep
                │
                ▼
        Validate current step
          ├── Already done? → Advance to next
          └── Not done? → Fire TutorialStepStarted(stepNum, instruction)
                            │
                            ▼
                    Wait for CompleteTutorialStep signal
                            │
                            ▼
                    Award step reward → Save profile → Fire TutorialStepCompleted
                            │
                            ▼
                    Advance to step N+1 (or TutorialCompleted if step 8)
```

---

## 8. UI/UX Integration Notes

### 8.1 Quest UI Panel (New Tab)

The quest panel lives as a tab alongside the Collection and Shop in the bottom toolbar:

| Tab | Section |
|-----|---------|
| **Daily** | Shows 3 active daily quests with progress bars + re-roll button |
| **Milestones** | Next 5 upcoming milestones with progress bars |
| **Achievements** | All achievements with completion status (locked/in progress/completed) |
| **Event** | Only visible during an active anomaly — shows the event quest |

**UI States per quest card:**
- **Available:** "Accept" button visible (dailies only)
- **Active:** Progress bar + current "X/Y" counter
- **Completed (unclaimed):** Green checkmark + pulsing "Claim" button
- **Claimed:** Greyed out, "Completed" badge (dailies show time until reset)

### 8.2 Tutorial UI Overlay

Each tutorial step pushes a contextual overlay:
- **Top-center:** Instruction text (large, readable) + step counter "3 / 8"
- **Animated arrow:** Points at the relevant UI element (Shop button, dive zone, creature)
- **Progress bar:** Thin bar at the bottom showing overall tutorial completion
- **Tooltip:** First time opening each panel gets an additional tooltip explaining the UI

### 8.3 Quest Notifications

- **Progress update:** Small toast "🐟 Creature Collector: 3/5" (fades after 5s)
- **Quest completed:** Medium toast "✅ Creature Collector completed! Claim your reward!" with animated icon
- **Milestone reached:** Large toast "🏆 New Milestone: Into the Twilight!" with sound effect
- **Daily refresh:** Banner notification on first server join after reset: "☀️ New Daily Quests Available!"

### 8.4 Quest & Tutorial HUD Elements

- **Quest indicator:** Small icon (scroll/book) on the HUD that pulses when quest progress is made or quests are completable. Shows a count of unclaimed quests.
- **Tutorial tracker:** Thin persistent bar at the top of the screen during tutorial, showing current step name and progress.
- **Anomaly quest banner:** During anomaly events, a special colored banner at the top of the HUD: "⚡ Ancient Migration Active! Catch a Legendary for bonus rewards!"

---

## 9. Monetization Hooks

### 9.1 Quest Booster Game Pass

| Name | Price (Robux) | Effect |
|------|--------------|--------|
| "Daily Boost" | 99 | +1 extra daily quest slot (4 total), +1 re-roll per day |
| "Quest Master" | 199 | +2 extra daily quest slots (5 total), unlimited re-rolls, +25% quest Credit rewards |

### 9.2 Skip Tutorial Game Pass

| Name | Price (Robux) | Effect |
|------|--------------|--------|
| "Experienced Diver" | 49 | Skip tutorial on alts, start with 200 bonus Credits (same as tutorial total) |

### 9.3 Developer Products

| Product | Price (Robux) | Effect |
|---------|--------------|--------|
| "Quest Rush" | 149 | Instantly complete all 3 current daily quests |
| "Milestone Booster" | 249 | Double Credit rewards from milestones for 24 hours |

### 9.4 Depth Pass Integration

The seasonal Depth Pass (already in Config.DepthPass) aligns with the quest system: Depth Pass XP is earned by completing daily quests. Free tier players earn 1x XP per quest; Premium tier earns 2x. This drives Depth Pass engagement through the quest system.

---

## 10. Quest Balance & Progression

### 10.1 Daily Quest Credit Economy

| Player Level | Avg Daily Quest Reward | Quests/Day | Daily Credits | % of Dive Earnings |
|-------------|----------------------|-----------|--------------|-------------------|
| 1-3 (Basic Gear) | 45 Cr | 3 | ~135 Cr | ~60% of 1 dive |
| 4-8 (Scuba Kit) | 80 Cr | 3 | ~240 Cr | ~40% of 1 dive |
| 9-15 (Adv. Suit) | 150 Cr | 3 | ~450 Cr | ~30% of 1 dive |
| 16-20 (Bathysphere) | 250 Cr | 3 | ~750 Cr | ~25% of 1 dive |
| 20+ (Exosuit) | 350 Cr | 3 | ~1,050 Cr | ~20% of 1 dive |

Daily quests should feel like a meaningful bonus (not the primary income source) — roughly 20-60% of a dive's earnings, depending on player level.

### 10.2 Milestone Quest Credit Economy

Milestone quests provide **one-time injections** that help players bridge gear gaps:

| Milestone Tier | Total Credits | Total RP | Helps Bridge |
|---------------|--------------|---------|-------------|
| Depth (early) | 200 Cr | 2 RP | Scuba Kit (150 Cr) |
| Depth (mid) | 1,200 Cr | 15 RP | Advanced Suit (400 Cr) → Bathysphere (1,000 Cr) |
| Depth (late) | 4,500 Cr | 75 RP | Exosuit (3,000 Cr) |
| Collection | 2,400 Cr | 55 RP | Endgame cosmetics |
| Gear | 2,250 Cr | 40 RP | Gear upgrade path |
| Base Building | 900 Cr | 10 RP | Base module costs |
| **Total** | **~11,450 Cr** | **~197 RP** | |

These one-time bonuses make the early-game grind feel surmountable while ensuring the endgame is still an achievement.

### 10.3 Time-to-Completion Targets

| Quest Type | Time to Complete | Player Level |
|-----------|-----------------|-------------|
| Easy daily (Catch 5 creatures) | ~3-5 min | 1+ |
| Medium daily (Reach 100m) | ~5-8 min | 3+ |
| Hard daily (Catch 2 Rare+) | ~10-15 min | 5+ |
| Expert daily (Reach 4000m) | ~15-25 min | 15+ |
| Early milestone (50m depth) | ~2 min | 1 |
| Mid milestone (1000m depth) | ~3-5 dives | 5-8 |
| Late milestone (6000m depth) | ~10-15 dives | 16-20 |
| Endgame milestone (11000m) | ~20-30 dives | 20+ |
| Event quest (easy) | ~3-5 min | 1+ |
| Event quest (hard — Legendary) | ~10-20 min (active anomaly) | 10+ |

### 10.4 Daily Quest Pool Weighting

The weight system ensures variety: a Level 3 player is not offered "Reach 4000m" but always has 3 completable dailies.

```lua
-- Selection algorithm (pseudocode):
function SelectDailyQuestsForPlayer(player, profile)
    local validPool = {}
    for _, questDef in ipairs(Config.DailyQuests) do
        if profile.Level >= (questDef.MinPlayerLevel or 1)
            and (profile.MaxDepth or 0) >= (questDef.MinPlayerDepth or 0)
            and (profile.MaxDepth or 0) <= (questDef.MaxPlayerDepth or math.huge) then
            table.insert(validPool, { key = key, def = questDef })
        end
    end
    
    -- Weighted random selection
    local selected = {}
    for i = 1, Config.QuestSystem.MaxDailyQuests do
        local pick = WeightedRandom(validPool)
        table.insert(selected, pick)
        -- Remove picked quest from pool so no duplicates
        RemoveFromTable(validPool, pick)
    end
    
    return selected
end
```

---

## Appendix A: Implementation Priority

### Phase 1 (MVP — Alpha)
1. **Tutorial steps 1-8** (Config extension + TutorialService + ProfileTemplate update)
2. **Milestone quests** (Depth + Gear milestones — highest retention impact)
3. **Achievement quests** (FirstSale, BeginnerCollector, Centurion — cheap to implement)
4. **QuestService core** (Condition evaluation + reward claiming + event hooks)

### Phase 2 (Beta)
5. **Daily quest system** (Pool selection + refresh + re-roll logic)
6. **Event quests** (AnomalyService integration)
7. **Quest notification UI** (Toasts, banners, progress bars)

### Phase 3 (Launch)
8. **Quest Booster game passes**
9. **Depth Pass quest integration**
10. **Full bestiary achievement + shiny hunting**

---

## Appendix B: Quest Service Test Scenarios

| Scenario | Steps | Expected Outcome |
|----------|-------|-----------------|
| New player completes tutorial | Follow steps 1-8 | Tutorial completed, Scuba Kit owned, quest tab unlocked |
| Player catches 5 creatures | Catch 5 creatures in single session | "Creature Collector" daily shows 5/5, "Claim" button appears |
| Player surfaces before completing daily | Complete 3/5 catches, surface | Progress is saved at 3/5 for the session |
| Daily quest resets mid-progress | Player has 4/5 catches at 00:00 UTC | Next login: daily is reset to 0/5, new pool offered |
| Player reaches 200m for first time | Dive to 201m | "Twilight Reached!" milestone auto-completes, reward available |
| Anomaly starts while diving | Anomaly active → player catches during it | Event quest progress increments |
| Player re-rolls daily quest | Click re-roll on a daily | Current quest removed, new one offered, re-roll cooldown starts |
| Player claims a milestone reward | Open quest tab, click "Claim" | Rewards delivered, quest marked claimed, title equipped if applicable |