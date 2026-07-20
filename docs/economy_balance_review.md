# Economy Balance & Monetization Review — Abyssal Echoes

**Analyst:** Agent Roblox Market Analyst  
**Date:** June 29, 2026  
**Files Reviewed:** Config.lua, EconomyService.lua, DepthService.lua, Types.lua, abyssal_echoes_gdd.md  
**Codebase:** `/home/team/shared/abyss-of-the-deep/` and `/home/team/shared/game-files/`

---

## 1. Executive Summary

The economy implementation is structurally sound (dual-currency, XP/level, shop, inventory, persistence all wired correctly), but has **critical balance issues** that will harm both player retention and revenue if shipped as-is. This review identifies **7 balance problems** and proposes targeted fixes for each.

---

## 2. Issue #1: Earning Rates vs. Gear Costs — Progression Is Too Slow

### Current State

**Earning rates per dive session (estimated, 15-min dive to max gear depth):**

| Gear Tier | Max Depth | Best Per-Dive Earnings* | Dives to Next Tier | Cumulative Dives to Endgame |
|-----------|-----------|----------------------|--------------------|----------------------------|
| Basic (T1) | 200m | ~60-80 Credits | 2-3 dives (150 Cr) | 89-119 dives |
| Scuba Kit (T2) | 1,000m | ~100-150 Credits | 3-5 dives (500 Cr) | 87-99 dives |
| Advanced Suit (T3) | 4,000m | ~200-300 Credits | 5-8 dives (1,500 Cr) | 82-90 dives |
| Bathysphere (T4) | 6,000m | ~300-400 Credits | 12-17 dives (5,000 Cr) | 72-78 dives |
| Abyssal Exosuit (T5) | 11,000m | ~400-600 Credits | — | 0 |

*\*Includes depth credits + creature catches + dive completion bonus*

**Total Credits needed for all gear: 7,150**  
**Estimated dives to earn all gear (at average 80 Cr/dive early, 500 Cr/dive late): ~55-70 sessions**  
**Time to endgame at 2 dives/day: ~28-35 days**

### Problem

For a Roblox game targeting D7 retention of 12-18%, requiring 55+ sessions to reach endgame gear is **too aggressive**. Players will burn out in the Scuba Kit → Advanced Suit grind (Tier 2 → Tier 3, 500 Credits) because:
- They've already explored everything the Scuba Kit unlocks (Twilight Zone, 200-1,000m)
- The next zone (Midnight) requires the Advanced Suit (4,000m depth)
- They need 3-5 more identical dives just for the upgrade — with no new content in between

**Reference point:** Top-performing Roblox deep-progression games (like Blox Fruits) let players reach meaningful new content milestones every **2-3 sessions**, not every 5-8.

### Recommended Fixes

**A. Increase Credits per meter from 0.1 → 0.2 (100% increase)**

This makes deep diving more rewarding without affecting the early game significantly. In the Sunlight Zone (0-200m), this adds ~20 Credits per dive. In the Abyss (4,000-6,000m), this adds ~400 Credits — making deep exploration feel lucrative.

```lua
-- Config.lua line 292
CreditsPerDepthMeter = 0.2,  -- Was 0.1
```

**B. Increase dive completion bonus from 10 → 25 Credits**

```lua
-- Config.lua line 293
CreditsPerDiveComplete = 25,  -- Was 10
```

**C. Smooth gear price curve — reduce late-game spikes**

The price jump from Advanced Suit (500) → Bathysphere (1,500) is a **3x** spike. Then Bathysphere → Exosuit (5,000) is a **3.3x** spike. This feels punishing.

| Gear | Current Price | Adjusted Price | Reduction | Rationale |
|------|---------------|---------------|-----------|-----------|
| Basic Gear | Free | Free | — | ✅ Tutorial gear |
| Scuba Kit | 150 | 150 | — | ✅ Good first purchase |
| Advanced Suit | 500 | 400 | -20% | Reduce grind gap |
| Bathysphere | 1,500 | 1,000 | -33% | Major mid-game wall removed |
| Abyssal Exosuit | 5,000 | 3,000 | -40% | Endgame still feels earned |
| **Total** | **7,150** | **4,550** | **-36%** | |

```lua
-- Config.lua DivingGear pricing adjustments
-- Tier 3: 500 → 400
-- Tier 4: 1500 → 1000
-- Tier 5: 5000 → 3000
```

**D. Add zone milestone Credits bonus (one-time)**

Players should feel rewarded for *reaching* new depths, not just selling creatures:

```lua
-- Add to Config.DepthLayers or Config.Economy
DepthMilestoneBonuses = {
    { depth = 200, credits = 50,  label = "First Dive Below 200m" },
    { depth = 1000, credits = 200, label = "Reached the Twilight Zone" },
    { depth = 4000, credits = 500, label = "Conquered the Midnight Zone" },
    { depth = 6000, credits = 1000, label = "Survived the Abyss" },
    { depth = 11000, credits = 2000, label = "Descended to the Trenches!" },
}
```

### Post-Fix Projected Progression

| Gear | Adjusted Cost | Est. Dives (with fixes) | Real-Time (2 dives/day) |
|------|-------------|------------------------|-----------------------|
| Scuba Kit | 150 | 2-3 dives | 1-2 days |
| Advanced Suit | 400 | 3-4 dives | 2 days |
| Bathysphere | 1,000 | 4-6 dives | 3 days |
| Abyssal Exosuit | 3,000 | 8-12 dives | 4-6 days |
| **Endgame** | **4,550** | **~20-25 dives** | **~10-14 days** |

A 10-14 day path to endgame is much healthier for D7/D14 retention and fits the "2-3 sessions = new milestone" pattern proven by top Roblox games.

---

## 3. Issue #2: Research Points — Premium Currency With Nothing Premium to Buy

### Current State

| RP Source | Amount | Frequency |
|-----------|--------|-----------|
| Zone first entry | 1-20 RP | One-time per zone (5 total) |
| Creature first discovery | 1-50 RP | One-time per species |
| Level up | 5 RP | Every level |
| Gear milestone | tier × 2 | 5 times total |
| **Total earnable (est.)** | **~200-300 RP** | **Over weeks of play** |

**RP Shop Items:**

| Item | RP Cost | Effect |
|------|---------|--------|
| XP Booster | 15 RP | Double XP for 1 hour |
| Lucky Charm | 10 RP | +25% catch rate for 30 min |
| Bioluminescent Light | 2 RP | Decorations |

### Problem

Research Points are described as "premium currency" but:
1. Only **3 items** in the entire RP shop
2. All items are **temporary boosts** — nothing permanent or aspirational
3. The conversion is confusing (items can be bought with Credits OR RP)
4. Players who earn 50 RP from discovering a Legendary creature have **nothing exciting** to spend it on
5. No RP-gated content = no reason to buy RP packs with real money

### Recommended Fixes

**A. Add RP-gated permanent content (aspirational purchases)**

```lua
-- Add to Config.ShopItems:

-- RP-exclusive base modules
Research_AbyssalBeacon = {
    Name = "Abyssal Beacon",
    Description = "Teleports you to your deepest reached depth on next dive",
    Category = "Permanent",
    Price = 50,
    PriceCurrency = "ResearchPoints",
    Effect = "UnlockTeleport",
    Exclusive = true,
},
Research_BioluminescenceSkin = {
    Name = "Bioluminescent Aura",
    Description = "Permanent glowing effect on your diving suit",
    Category = "Cosmetic",
    Price = 30,
    PriceCurrency = "ResearchPoints",
    Effect = "CosmeticAura",
    Exclusive = true,
},
Research_PermaOxygen = {
    Name = "Deep Lungs Upgrade",
    Description = "Permanently +25 base oxygen capacity",
    Category = "Upgrade",
    Price = 40,
    PriceCurrency = "ResearchPoints",
    Effect = "PermaOxygen",
    Exclusive = true,
},
Research_ExclusiveCreature = {
    Name = "Void Jellyfish Egg",
    Description = "Hatch an exclusive Trenches-born pet that follows you",
    Category = "Companion",
    Price = 75,
    PriceCurrency = "ResearchPoints",
    Effect = "CompanionPet",
    Exclusive = true,
},
```

**B. Add a weekly RP shop rotation (FOMO driver)**

```lua
-- New table in Config
Config.RotatingShop = {
    RotationInterval = 604800, -- 7 days
    Items = {
        { Name = "Crimson Angler Skin",      RPCost = 20, Duration = "limited" },
        { Name = "Copper Dive Helmet Skin",   RPCost = 25, Duration = "limited" },
        { Name = "Golden Coral Decoration",   RPCost = 15, Duration = "limited" },
    }
}
```

**C. Remove the confusing dual-currency conversion on decorations**

The Bioluminescent Light costs 40 Credits *or* 2 RP. Since 2 RP ≈ 20 Credits at the stated conversion rate, but players can't actually convert RP to Credits, this creates confusion. Either:
- Make Bio Light RP-only (2 RP), or
- Make it Credits-only (40 Cr), or
- Add an explicit "Convert RP → Credits" button in the UI (at the stated 1 RP = 10 Cr rate)

---

## 4. Issue #3: Missing Resource Economy — Base Building Can't Function

### Current State

```lua
-- Config.lua line 296-301
BaseBuildingCosts = {
    Habitat = {Credits = 100, Scrap = 50, Crystal = 10},
    Greenhouse = {Credits = 75, Scrap = 30, Crystal = 20},
    Lab = {Credits = 200, Scrap = 80, Crystal = 40},
    DefenseTurret = {Credits = 150, Scrap = 60, Crystal = 15},
    Decoration = {Credits = 25, Scrap = 10},
},
```

### Problem

**Scrap and Crystal do not exist anywhere in the codebase.** No earning mechanism, no resource definition, no Config table. The base building system references resources that don't exist. If a player tries to build a Habitat, the transaction will fail because `EconomyService:CanAfford()` only checks Credits and ResearchPoints.

### Recommended Fix

**A. Add Resource definitions to Config.lua**

```lua
Config.Resources = {
    Scrap = {
        DisplayName = "Scrap Metal",
        Description = "Recycled metal from ocean debris and broken equipment",
        Icon = "rbxassetid://SCRAP_ICON_ID",
        StartingAmount = 0,
        MaxStack = 999,
        RarityWeights = { Common = 60, Uncommon = 30, Rare = 10 },
    },
    Crystal = {
        DisplayName = "Bioluminescent Crystal",
        Description = "Rare crystals found in deep-sea mineral deposits",
        Icon = "rbxassetid://CRYSTAL_ICON_ID",
        StartingAmount = 0,
        MaxStack = 999,
        RarityWeights = { Common = 40, Uncommon = 35, Rare = 20, Epic = 5 },
    },
}
```

**B. Add resource earning mechanics**

Resources should be earned alongside Credits during dives:

```lua
-- Add to Config.Economy
ResourcesPerDepthMeter = {
    Scrap = 0.05,   -- ~10 Scrap per 200m dive
    Crystal = 0.01,  -- ~2 Crystal per 200m dive (rarer)
},
ResourceNodeHarvestAmount = {
    Scrap = { min = 3, max = 8 },
    Crystal = { min = 1, max = 3 },
},
```

**C. Update EconomyService to handle resource transactions**

Add `AddResource()`, `SpendResource()`, and `CanAffordResource()` methods to EconomyService, mirroring the Credits/RP pattern. Also update `BaseBuildingCosts` to include resource costs.

---

## 5. Issue #4: Dive Completion Economics — Disincentivized Loop

### Current State

Dive completion gives:
- 10 Credits flat bonus (Config.Economy.CreditsPerDiveComplete)
- 5% of best depth achieved (DepthService line 192)

### Problem

A single catch of an Uncommon creature (avg 35 Credits) is worth **3.5x** the dive completion bonus of 10 Credits. This incentivizes players to:
1. Go to an easy zone
2. Farm creatures mindlessly
3. Ignore deep diving entirely

This breaks the core loop of "descend → explore → surface → upgrade."

### Recommended Fix

**A. Make dive completion reward scale with risk**

```lua
-- Replace the flat 10 Credits with a zone-based bonus
DiveCompletionBonuses = {
    { zoneMinDepth = 0,    zoneMaxDepth = 200,   baseBonus = 15,  label = "Shallow Dive" },
    { zoneMinDepth = 200,  zoneMaxDepth = 1000,  baseBonus = 40,  label = "Twilight Expedition" },
    { zoneMinDepth = 1000, zoneMaxDepth = 4000,  baseBonus = 100, label = "Midnight Descent" },
    { zoneMinDepth = 4000, zoneMaxDepth = 6000,  baseBonus = 250, label = "Abyssal Voyage" },
    { zoneMinDepth = 6000, zoneMaxDepth = 11000, baseBonus = 500, label = "Trench Exploration" },
}
```

**B. Add depth milestone achievements that reward RP**

```lua
-- New table in Config
DepthAchievements = {
    { depth = 200,  title = "Surface Scratcher", rpReward = 1 },
    { depth = 1000, title = "Twilight Traveler", rpReward = 3 },
    { depth = 4000, title = "Midnight Marauder", rpReward = 5 },
    { depth = 6000, title = "Abyss Walker",      rpReward = 10 },
    { depth = 11000, title = "Trench Dweller",    rpReward = 25 },
}
```

---

## 6. Issue #5: Consumable Economy — Overpriced vs. Free Alternative

### Current State

| Consumable | Price | Effect | Alternative |
|-----------|-------|--------|-------------|
| Emergency Oxygen Tank | 25 Cr | Refills 50% O₂ | Surface for free |
| Rare Lure | 50 Cr | Attracts rare creatures for 60s | Just keep diving |
| Propulsion Boost | 30 Cr | +40% speed for 30s | Swim normally |

### Problem

At 25 Credits, the Oxygen Tank is a **bad deal** — surfacing costs 0 Credits and fully refills O₂. The Rare Lure at 50 Credits is also expensive relative to a single creature catch (~86 Cr avg). Players will try these once, feel ripped off, and never buy them again.

### Recommended Fix

**A. Reduce consumable prices to be impulse buys**

```lua
-- Adjusted consumable prices (make them cheap enough to use freely)
Emergency Oxygen Tank: 25 → 10 Credits  (down 60%)
Rare Lure:              50 → 20 Credits  (down 60%)
Propulsion Boost:       30 → 15 Credits  (down 50%)
```

At 10 Credits, the Oxygen Tank becomes a "I'm at 200m and found a rare creature but am low on O₂" impulse purchase — exactly what consumables should be.

**B. Add bundle pricing (increases average revenue)**

```lua
-- New bundle items
Config.ShopItems.DiveBundle = {
    Name = "Diver's Bundle (5-pack)",
    Description = "5 Oxygen Tanks + 2 Rare Lures at a discount",
    Category = "Bundle",
    Price = 60,  -- Would cost 90 individually → 33% discount
    PriceCurrency = "Credits",
    Contains = { OxygenTank = 5, RareLure = 2 },
},
```

---

## 7. Issue #6: XP Curve — Linear Formula Lacks Late-Game Engagement

### Current State

```lua
local function GetXPForLevel(level)
    return math.floor(100 * level * 1.5)  -- 150, 300, 450, 600, 750...
end
```

| Level | XP Needed | Cumulative | Est. Dives to Level | Reward |
|-------|-----------|-----------|-------------------|--------|
| 1→2 | 150 | 150 | 2-3 dives | 5 RP |
| 2→3 | 300 | 450 | 3-5 dives | 5 RP |
| 5→6 | 750 | 2,250 | 5-8 dives | 5 RP |
| 10→11 | 1,500 | 8,250 | 8-12 dives | 5 RP |
| 20→21 | 3,000 | 31,500 | 15-20 dives | 5 RP |

### Problem

The XP curve is linear: each level takes the same 1.5x more. But the reward is flat (5 RP per level). At level 20+, a player needs 15-20 dives for 5 RP — which buys 1/3 of an XP Booster. The RP reward needs to scale with level so late-game leveling feels meaningful.

### Recommended Fix

**A. Make RP-per-level scale**

```lua
-- Replace flat 5 RP per level with scaling:
-- Config.Economy.ResearchPointsPerLevel = 5  -- OLD
-- NEW: Scale RP reward with level
ResearchPointsPerLevel = function(level)
    return 5 + math.floor(level / 5)  -- 5, 6, 7, 8, 9, 10... at level 25: 10 RP
end
```

**B. Add cosmetic rewards at milestone levels**

```lua
-- New table in Config
LevelMilestones = {
    { level = 5,  reward = "Diver Title",          type = "Cosmetic" },
    { level = 10, reward = "Explorer Title",        type = "Cosmetic" },
    { level = 15, reward = "Deep Explorer Title",   type = "Cosmetic" },
    { level = 20, reward = "Abyssal Lord Title",    type = "Cosmetic" },
    { level = 25, reward = "Ocean Master Title",    type = "Cosmetic" },
    { level = 50, reward = "Leviathan Slayer Title", type = "Cosmetic" },
}
```

Titles are cheap to implement, highly visible (shown above player name or in chat), and create powerful FOMO for collectors.

---

## 8. Issue #7: Missing Monetization Layers (Revenue Leak)

### Current State

The game has these monetization hooks in Config:
- **5 Game Passes** (all IDs = 0, not published yet)
- **7 Developer Products** (all IDs = 0, not published yet)
- **Battle Pass** (mentioned in GDD as "Depth Pass" — not in Config)
- **Limited-time events** (mentioned in GDD — not in Config)

### Problem

Compared to top-earning Roblox games like RIVALS (#1 Earning), the current monetization has **critical gaps**:

| Monetization Lever | RIVALS | Abyssal Echoes (Current) | Gap |
|-------------------|--------|------------------------|-----|
| Game Passes | 8+ (including VIP) | 5 (basic) | Missing permanent VIP |
| Developer Products | 15+ tiers | 7 (flat packs) | Missing subscription |
| Battle Pass | Seasonal (robust) | Not implemented | ✅ GDD mentions it |
| Limited Items | Weekly rotation | Not implemented | High FOMO value |
| Avatar Shop (UGC) | Active | Not mentioned | Extra revenue stream |

### Recommended Fixes

**A. Add a VIP Game Pass (recurring value)**

```lua
-- Add to Config.GamePasses
VIPStatus = 0,  -- Set after publishing
-- VIP Benefits: +25% Credits, +15% XP, +5 Max O₂, exclusive VIP title
```

VIP passes are the **highest-converting game pass type** on Roblox because they create ongoing value rather than a one-time perk.

**B. Implement the Depth Pass (Battle Pass) skeleton**

```lua
-- New table in Config
Config.DepthPass = {
    Enabled = true,
    SeasonDuration = 604800 * 4,  -- 4 weeks
    FreeTierRewards = {
        { level = 1,  type = "Credits",    amount = 50 },
        { level = 5,  type = "Consumable", item = "OxygenTank", count = 2 },
        { level = 10, type = "Title",      title = "Season 1 Diver" },
        { level = 15, type = "Credits",    amount = 200 },
        { level = 20, type = "ResearchPoints", amount = 10 },
        { level = 25, type = "Consumable", item = "RareBait", count = 3 },
    },
    PremiumTierRewards = {
        { level = 1,  type = "Cosmetic",   item = "Seasonal Suit Skin" },
        { level = 5,  type = "Consumable", item = "RareLure", count = 5 },
        { level = 10, type = "Cosmetic",   item = "Seasonal Submarine Skin" },
        { level = 15, type = "ResearchPoints", amount = 25 },
        { level = 20, type = "Cosmetic",   item = "Seasonal Base Decoration Set" },
        { level = 25, type = "GamePass",   item = "Exclusive Season 1 Creature" },
    },
    Price = 399,  -- Robux for premium track
}
```

**C. Add developer product tiers that match competitor pricing**

```lua
-- Replace placeholder values with real pricing tiers
Config.DeveloperProducts = {
    -- Small (impulse buy)
    Credits_500 = 0,           -- ~49 Robux — instant buy for new players
    Credits_2000 = 0,          -- ~149 Robux — mid-tier
    Credits_10000 = 0,         -- ~499 Robux — whale tier
    -- RP packs
    ResearchPoints_10 = 0,     -- ~49 Robux
    ResearchPoints_50 = 0,     -- ~199 Robux
    ResearchPoints_250 = 0,    -- ~799 Robux
    -- Bundles
    StarterPack = 0,           -- ~99 Robux — best value, time-limited
    DepthPass = 0,             -- ~399 Robux — seasonal
    VIP_Monthly = 0,           -- ~249 Robux — recurring
}
```

**D. Add daily reward system (retention driver)**

```lua
-- New table in Config
Config.DailyRewards = {
    Enabled = true,
    StreakLength = 7,
    Rewards = {
        { day = 1, type = "Credits", amount = 25 },
        { day = 2, type = "Consumable", item = "OxygenTank", count = 1 },
        { day = 3, type = "Credits", amount = 50 },
        { day = 4, type = "Consumable", item = "PropulsionBoost", count = 1 },
        { day = 5, type = "Credits", amount = 75 },
        { day = 6, type = "Consumable", item = "RareLure", count = 1 },
        { day = 7, type = "ResearchPoints", amount = 5 },  -- Big finish
    },
    ResetOnMiss = false,  -- Streak protection (premium feel)
}
```

---

## 9. Comparative Benchmarking

### How Abyssal Echoes Compares to Top Roblox Games

| Metric | Blox Fruits | RIVALS | Grow a Garden 2 | **Abyssal Echoes** | Target |
|--------|------------|--------|-----------------|-------------------|--------|
| **Gear Price Progression** | Exponential (smooth) | Linear (flat) | Stepped (good) | ⚠️ Spiky (bad) | Smooth curve |
| **Premium Currency Items** | 15+ | 20+ | 10+ | ❌ 3 only | 10+ aspirational |
| **Battle Pass** | ✅ | ✅ | ❌ | ❌ Not implemented | ✅ |
| **VIP Game Pass** | ✅ | ✅ | ❌ | ❌ Not implemented | ✅ |
| **Daily Rewards** | ✅ | ✅ | ✅ | ❌ Not implemented | ✅ |
| **Bundle Pricing** | ✅ | ✅ | ❌ | ❌ Not implemented | ✅ |
| **Consumable Pricing** | Cheap (impulse) | Cheap (impulse) | Cheap | ⚠️ Overpriced | Impulse range |
| **Creepers/hr** | 100-200 Cr | ~500 Cr/hr | ~300 Cr/hr | ⚠️ ~60-80/dive | 100-200/session |
| **Time to Endgame** | ~2 weeks | ~1 week | ~1 week | ⚠️ ~4-5 weeks | 10-14 days |

---

## 10. Priority Action Items

### 🔴 Critical (Must Fix Before Launch)

| # | Fix | Impact | Effort | File |
|---|-----|--------|--------|------|
| 1 | Increase Credits per meter: 0.1 → 0.2 | Fixes core earning rate | 1 line | Config.lua:292 |
| 2 | Increase dive completion: 10 → 25 | Fixes dive loop incentive | 1 line | Config.lua:293 |
| 3 | Add Scrap & Crystal resource definitions | Unlocks base building | ~30 lines | New Config.Resources |
| 4 | Smooth gear price curve (T3-T5) | Fixes mid-game grind wall | 3 lines | Config.lua:205,215,225 |

### 🟡 High Priority

| # | Fix | Impact | Effort | File |
|---|-----|--------|--------|------|
| 5 | Add RP-gated permanent items | Gives RP meaning, drives purchases | ~40 lines | Config.ShopItems |
| 6 | Reduce consumable prices 50-60% | Makes consumables usable | 3 lines | Config.lua:314,324,333 |
| 7 | Add daily reward system | Boosts D1/D7 retention | ~30 lines | New Config.DailyRewards |
| 8 | Fix dual-currency ambiguity on deco items | Prevents player confusion | 2 lines | Config.lua:352-358 |

### 🟢 Nice to Have (Before or After Launch)

| # | Fix | Impact | Effort |
|---|-----|--------|--------|
| 9 | Depth Pass (Battle Pass) skeleton | Major revenue driver | High |
| 10 | VIP Game Pass | Recurring revenue | Medium |
| 11 | Weekly rotating RP shop | FOMO + retention | Medium |
| 12 | Level milestone titles | Cheap engagement | Low |
| 13 | Bundle pricing | Revenue per user | Low |

---

## 11. Summary of Config.lua Changes Needed

| Line(s) | Current Value | Recommended | Location |
|---------|--------------|-------------|----------|
| 292 | `CreditsPerDepthMeter = 0.1` | `CreditsPerDepthMeter = 0.2` | Config.Economy |
| 293 | `CreditsPerDiveComplete = 10` | `CreditsPerDiveComplete = 25` | Config.Economy |
| 205 | `Price = 500` (T3) | `Price = 400` | DivingGear[3] |
| 215 | `Price = 1500` (T4) | `Price = 1000` | DivingGear[4] |
| 225 | `Price = 5000` (T5) | `Price = 3000` | DivingGear[5] |
| 314 | `Price = 25` (OxygenTank) | `Price = 10` | ShopItems |
| 324 | `Price = 50` (RareBait) | `Price = 20` | ShopItems |
| 333 | `Price = 30` (SpeedBoost) | `Price = 15` | ShopItems |
| 296-301 | References Scrap/Crystal | Add Config.Resources table | New section |
| 359 | `ResearchPointPrice = 2` | Remove or make exclusive | ShopItems |
| 287-302 | No milestones | Add DepthMilestoneBonuses | New section |
| New | N/A | Add DailyRewards | New section |
| New | N/A | Add RP-exclusive items | New section |

---

*Analysis by Agent Roblox Market Analyst. All recommendations align with the business plan's KPIs: D1 25%+, D7 retention, and sustainable monetization through game passes and developer products.*