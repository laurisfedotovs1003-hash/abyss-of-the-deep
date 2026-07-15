# Abyss of the Deep

**A deep-sea exploration, survival, and creature-collection experience on Roblox.**

> *Descend through ocean layers. Discover bioluminescent life. Build underwater bases. Survive the anomalies of the deep.*

---

## 🎮 Overview

Abyss of the Deep is a Roblox game where players explore five increasingly dangerous ocean zones — from the sunlit shallows to the crushing Trenches. Each zone introduces new creatures, higher pressure, and unique environmental challenges. Players collect creatures, manage oxygen, upgrade diving gear, construct underwater bases, and survive unpredictable "Echo Event" anomalies.

**Genre:** Exploration / Survival / Collection / Base Building  
**Target Audience:** Roblox core demographic (ages 9–16)  
**Platform:** PC, Mobile, Console (Roblox)

---

## ✨ Features

### Core Gameplay
- **5 Depth Zones:** Sunlight (0–200m), Twilight (200–1,000m), Midnight (1,000–4,000m), Abyssal (4,000–6,000m), Trenches (6,000–11,000m)
- **30+ Collectible Creatures:** 5 rarity tiers — Common, Uncommon, Rare, Epic, Legendary — with Shiny variants
- **Oxygen Management:** Real-time oxygen drain that varies by depth zone; refill via tanks or surfacing
- **Pressure System:** Damage over time when exceeding gear depth limits
- **Diving Gear:** 5 upgrade tiers (Basic → Scuba Kit → Advanced Suit → Bathysphere → Abyssal Exosuit)

### Anomaly Events (The "Hook")
- **5 Echo Events:** Corrupted Depths, Enchanted Waters, Bioluminescent Bloom, Abyssal Surge, Ancient Migration
- Each event dynamically changes lighting, creature rarity weights, catch rates, XP/Credit multipliers, and spawn rates
- Visual and audio cues warn players before an anomaly triggers

### Base Building
- Modular underwater habitats with 5 module types: Habitat, Greenhouse, Lab, Defense Turret, Decoration
- 3 upgrade tiers per module
- Resource economy: Scrap Metal and Bioluminescent Crystals

### Quest & Progression System
- **8-Step Tutorial:** Guided onboarding that teaches diving, catching, selling, and upgrading
- **Daily Quests:** 3 per day with re-roll system — rewards Credits, XP, and consumables
- **Milestone Quests:** Depth, collection, gear, and base-building progression with permanent rewards
- **Event Quests:** Time-limited quests tied to active anomaly events
- **Achievements:** Long-term stat-based goals with titles and cosmetics

### Economy
- **Dual Currency:** Credits (earned through gameplay) + Research Points (premium currency from discoveries and milestones)
- **Resource Economy:** Scrap metal and Bioluminescent Crystals for base building
- **Shop:** 5 categories — Gear, Consumables, Bundles, Research Upgrades, Decorations
- **Daily Rewards:** 7-day streak system with escalating rewards
- **Depth Pass:** Seasonal battle pass with free and premium reward tracks

### Monetization (Planned)
- Game Passes: Oxygen Booster, Speed Diver, Expanded Collection, Abyssal Pass, VIP Status
- Developer Products: Currency packs, Starter Pack, Research Points
- Depth Pass: 399 Robux seasonal premium track

---

## 🛠️ Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Game Engine | Roblox Studio | Latest |
| Framework | Knit (sleitnick) | 1.4.7 |
| Sync Tool | Rojo | 7.x |
| Package Manager | Wally | Latest |
| Persistence | ProfileService (MadStudio) | 2.0.0 |
| Scripting Language | Luau | Roblox latest |

---

## 📁 Project Structure

```
abyss-of-the-deep/
├── default.project.json      # Rojo project configuration (maps src/ to Roblox tree)
├── wally.toml                # Wally package manager dependencies
├── README.md                 # This file
├── SETUP.md                  # Developer setup guide
├── DEPLOY.md                 # Roblox publication guide
├── ASSETS.md                 # Asset pipeline guide
│
├── src/
│   ├── shared/               # Code shared between client & server (ReplicatedStorage)
│   │   ├── modules/
│   │   │   ├── Config.lua               # Game constants, layers, gear, creatures, economy
│   │   │   ├── Types.lua                # Type definitions, network events, schemas
│   │   │   ├── Util.lua                 # Pure utility functions (math, table, string)
│   │   │   ├── VFXUtil.lua              # Visual effect helpers (particles, beams, tweens)
│   │   │   └── AnimatedEnvironmentUtil.lua # Animated world elements (kelp, vents, fish schools)
│   │   └── init.lua                     # Shared module index
│   │
│   ├── server/               # Server-side code (ServerScriptService)
│   │   ├── services/
│   │   │   ├── AnomalyService.lua       # Echo Event management (lighting, modifiers, lifecycle)
│   │   │   ├── BaseBuildingService.lua  # Underwater base construction & upgrades
│   │   │   ├── CollectionService.lua    # Player creature collection journal
│   │   │   ├── CreatureService.lua      # Creature spawning, encounter logic, catch mechanics
│   │   │   ├── DepthService.lua         # Depth layers, pressure damage, gear progression
│   │   │   ├── EconomyService.lua       # Dual-currency economy, XP/leveling, shop, daily rewards
│   │   │   ├── LeaderboardService.lua   # Depth & collection leaderboards
│   │   │   ├── OxygenService.lua        # Oxygen drain, refill, critical state
│   │   │   ├── QuestService.lua         # Quest lifecycle (daily/milestone/event/achievement)
│   │   │   ├── ToolService.lua          # Fishing rod, harvest tool, tool validation
│   │   │   ├── TutorialService.lua      # 8-step onboarding tutorial
│   │   │   └── ZoneService.lua          # World geometry generation & environmental zones
│   │   ├── datastore/
│   │   │   ├── DataStoreManager.lua     # ProfileService wrapper (save/load/migrate)
│   │   │   └── ProfileTemplate.lua      # Player profile schema with defaults
│   │   └── init.lua                     # Server bootstrap with Knit.start()
│   │
│   └── client/               # Client-side code (StarterPlayerScripts)
│       ├── controllers/
│       │   ├── AudioController.lua      # Zone ambients, SFX, music crossfades
│       │   ├── CameraController.lua     # Underwater camera effects, depth-based fog
│       │   ├── DivingController.lua     # Swimming controls, movement, dive state
│       │   ├── FishingController.lua    # Rod casting, bite detection, reel-in mini-game
│       │   ├── UIController.lua         # HUD, shop, inventory, quest UI management
│       │   └── VFXController.lua        # Particles, bioluminescence, anomaly effects
│       ├── ui/
│       │   ├── UIStyles.lua             # Design tokens (colors, fonts, spacing)
│       │   ├── UIComponents.lua         # Reusable UI component factory
│       │   └── screens/
│       │       ├── ShopScreen.lua       # 5-category shop with gear, consumables, bundles
│       │       └── InventoryScreen.lua  # 4-tab inventory with collection, items, upgrades
│       └── init.lua                     # Client bootstrap with Knit.start()
│
├── build/                    # Rojo build output (compiled .rbxlx files)
├── docs/                     # Architecture & design documentation
└── .gitignore                # Git ignore rules
```

---

## 🏛️ Architecture

### Knit Framework

This project uses **Knit** (by sleitnick) for a clean service/controller architecture:

- **Services** (server-only) — Manage game state, handle logic, communicate with DataStores
- **Controllers** (client-only) — Handle user input, camera, UI updates, audio
- **Shared modules** — Code used by both client and server (config, types, utilities)

### Data Flow

```
Player Input → Controller → Knit RPC → Service → DataStore
                                 │
                          Shared Config
                                 │
Service → Knit Signal → Controller → UI Update
```

### Key Data Flows

**Diving Loop:**
1. Player presses F → `DivingController.StartDive()` → server `OxygenService:StartDive()`
2. Player moves → `DivingController` tracks depth → `DepthService:UpdatePlayerDepth()`
3. Server tick loop → `OxygenService:ProcessOxygenTick()` drains oxygen per depth layer
4. Critical oxygen → warning to client → HUD red pulse
5. Zero oxygen → `ForceSurface()` → player returns to surface

**Creature Encounter:**
1. `CreatureService` tick loop → checks if player is in a valid depth layer
2. Roll encounter → `CreatureService:SpawnCreatureForPlayer()` → rarity-weighted random
3. Client receives `CreatureSpawned` → `UIController` shows encounter UI
4. Player clicks catch → server rolls catch chance → success/failure
5. On success: creature added to collection, Credits + XP awarded

**Quest Progression:**
1. Player performs in-game action (catch creature, reach depth, etc.)
2. Service fires event → `QuestService:UpdateQuestProgress()` evaluates conditions
3. All conditions met → quest marked as completable → client notification
4. Player claims reward → `QuestService:ClaimReward()` → Credits/RP/items delivered

### Network Strategy

- **Knit Signals** (RemoteEvents/RemoteFunctions) for all service-client communication
- Oxygen and depth updates pushed from server every 1s tick
- Creature encounters pushed on spawn event
- Economy and collection updates pushed on change
- Client requests use Knit client method calls (RemoteFunctions under the hood)

### Data Persistence

- **ProfileService** via `DataStoreManager` wrapper
- Auto-saves every 120 seconds + on player leave
- Versioned profiles with migration support
- Stored data: progression, gear, collection, base layout, stats, quests, tutorial state

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/laurisfedotovs1003-hash/abyss-of-the-deep
cd abyss-of-the-deep

# 2. Install Wally dependencies
wally install

# 3. Build the project (creates .rbxlx file)
rojo build --output build/abyss-of-the-deep.rbxlx

# 4. Or serve for live sync with Roblox Studio
rojo serve

# 5. In Roblox Studio, connect via Rojo plugin and start editing
```

See [SETUP.md](./SETUP.md) for detailed setup instructions.

---

## 🧪 Testing

- Alpha map includes Zones 1–3 (Sunlight, Twilight, Midnight) for testing
- All services have print-based initialization logging
- Playtest in Studio using the Rojo serve workflow
- See [docs/architecture.md](./docs/architecture.md) for service architecture details

---

## 🗺️ Roadmap

| Phase | Status | Features |
|-------|--------|----------|
| Alpha | ✅ Complete | All core systems, 5 depth zones, 30+ creatures, anomaly events, base building, quests, tutorial, economy, UI, VFX |
| Beta | ⏳ Next | Closed alpha playtest, polish pass, bug fixes, marketing materials, trailer |
| Launch | ⏳ Planned | Roblox publication, game pass configuration, analytics, live ops |

---

## 👥 Team

**Nexus Blox Studios**

| Role | Focus Area |
|------|-----------|
| Game Designer | Core loops, progression, GDD, quest/tutorial design |
| Lead Developer | Architecture, Rojo/Knit, service framework, data persistence |
| Gameplay Scripter | Luau mechanics, NPC AI, tool systems, fishing/diving |
| Technical Artist | Lighting, VFX, particles, atmosphere, bioluminescence |
| UI/UX Designer | HUD, menus, shop, inventory, mobile-first design |
| Market Analyst | Monetization strategy, economy balance, competitor analysis |
| Trend Researcher | Platform trends, player sentiment, feature validation |

---

## 📄 License

Internal project — Nexus Blox Studios. All rights reserved.

---

## 📚 Related Documents

- [SETUP.md](./SETUP.md) — Developer setup and workflow guide
- [DEPLOY.md](./DEPLOY.md) — Roblox publication and game pass configuration
- [ASSETS.md](./ASSETS.md) — Asset creation and upload pipeline
- [docs/architecture.md](./docs/architecture.md) — Detailed architecture overview
- [docs/services.md](./docs/services.md) — Service-by-service documentation
- `tutorial_and_quest_design.md` — Quest and tutorial system design
- `abyssal_echoes_gdd.md` — Game Design Document
- `economy_balance_review.md` — Economy balance analysis and recommendations