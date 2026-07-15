# Setup Guide — Abyss of the Deep

> Detailed setup instructions for new developers joining the project.

---

## 📋 Prerequisites

Before you begin, install the following tools:

### 1. Roblox Studio
- Download from [create.roblox.com](https://create.roblox.com/)
- Ensure you're signed in with a Roblox account that has editing permissions for the game
- Recommended: enable "Studio Beta" features for the latest editor capabilities

### 2. Rojo (v7.x)
Rojo bridges file-based development with Roblox Studio.

```bash
# Via Aftman (recommended — version pinning)
# Add to aftman.toml:
# [tools]
# rojo = "rojo-rbx/rojo@7.4.1"

# Or download manually:
# https://github.com/rojo-rbx/rojo/releases
```

**Verify installation:**
```bash
rojo --version
# Expected: rojo 7.x.x
```

### 3. Wally (Package Manager)
Wally manages Roblox package dependencies.

```bash
# Via Aftman (recommended):
# [tools]
# wally = "UpliftGames/wally@0.3.2"

# Or install script (Windows PowerShell):
# iwr -useb https://wally.run/install.ps1 | iex

# Or install script (macOS/Linux):
# curl -fsSL https://wally.run/install.sh | sh
```

**Verify installation:**
```bash
wally --version
# Expected: wally 0.3.x
```

### 4. Git
For version control.

```bash
# Verify:
git --version
```

### 5. Roblox Studio Rojo Plugin
- Open Roblox Studio
- Go to **Plugins → Rojo**
- Click **"Install"** if not already installed
- Restart Studio after installation

---

## 🔧 One-Time Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/laurisfedotovs1003-hash/abyss-of-the-deep
cd abyss-of-the-deep
```

### Step 2: Install Wally Dependencies

```bash
wally install
```

This creates a `Packages/` directory containing:
- **Knit** (`sleitnick/knit@1.4.7`) — Service/controller framework
- **ProfileService** (`madstudios/profile-service@2.0.0`) — Data persistence

> **Note:** `Packages/` is gitignored — each developer must run `wally install` after cloning.

### Step 3: Configure Rojo (if needed)

The `default.project.json` maps the source tree to Roblox instances:

```json
{
  "name": "abyss-of-the-deep",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Knit": { "$path": "src/server" }
    },
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "KnitShared": { "$path": "src/shared" },
      "KnitPackages": { "$path": "Packages" }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Knit": { "$path": "src/client" }
      }
    }
  }
}
```

No changes needed — this ships with the repo.

---

## 💻 Development Workflow

### Option A: Serve Mode (Recommended for Active Development)

This syncs changes to Studio in real-time as you edit files.

**Terminal 1 (keep running):**
```bash
rojo serve
```

**Roblox Studio:**
1. Open Studio
2. Go to **Plugins → Rojo → Connect to Project**
3. Wait for "Connected" status
4. Your project tree is now auto-populated

**Edit → See changes instantly:**
```bash
# Edit any .lua file in src/
# Rojo pushes the change to Studio in ~1-2 seconds
```

### Option B: Build Mode (For Publishing / CI)

```bash
# Build the project to a .rbxlx file
rojo build --output build/abyss-of-the-deep.rbxlx

# Open the build file in Studio
# File → Open → navigate to build/abyss-of-the-deep.rbxlx
```

---

## 📁 Project Structure Explained

### `src/shared/` — Code for Both Client and Server

Files here end up in `ReplicatedStorage.KnitShared` so both sides can `require()` them.

| File | Purpose |
|------|---------|
| `Config.lua` | **The single source of truth** for game balance: creatures, gear, zones, economy, dailies, milestones, anomalies |
| `Types.lua` | Type definitions, network event names, enum-like constants |
| `Util.lua` | Pure helper functions (no Roblox dependencies) |
| `VFXUtil.lua` | Particle beam creation, tween helpers, light shaft builders |
| `AnimatedEnvironmentUtil.lua` | Kelp sway, vent bubbles, fish school movement |

> **Rule:** Never put Roblox service references in shared modules — they'll error on the client/server side that doesn't have them.

### `src/server/` — Server-Side Code

| Layer | Description |
|-------|-------------|
| `services/` | Knit services — each handles one game system |
| `datastore/` | Data persistence layer (ProfileService wrapper) |
| `init.lua` | Bootstrap: registers services, initializes DataStore, starts Knit |

#### Services Overview

| Service | Responsibility | Key State |
|---------|---------------|-----------|
| `OxygenService` | Oxygen drain, refill, tick loop | Per-player oxygen levels |
| `DepthService` | Depth tracking, gear limits, pressure damage | Per-player depth, gear tier |
| `CreatureService` | Creature spawning, encounter rolls, catch logic | Active encounters per player |
| `CollectionService` | Creature collection journal | Collection entries |
| `EconomyService` | Credits, RP, XP, leveling, shop, daily rewards | Per-player balances |
| `BaseBuildingService` | Module placement, upgrades, resource costs | Player base layouts |
| `AnomalyService` | Echo Event lifecycle, lighting, modifier tracking | Global anomaly state |
| `QuestService` | Daily/milestone/event/achievement quest lifecycle | Per-player quest state |
| `TutorialService` | 8-step onboarding tutorial | Per-player tutorial progress |
| `ToolService` | Fishing rod, harvest tool, tool validation | Tool state |
| `ZoneService` | World geometry generation, environment zones | Map state |
| `LeaderboardService` | Depth & collection leaderboards | Leaderboard snapshots |

### `src/client/` — Client-Side Code

| Layer | Description |
|-------|-------------|
| `controllers/` | Knit controllers — each handles one user-facing system |
| `ui/` | UI components, styles, screen implementations |
| `init.lua` | Bootstrap: registers controllers, waits for server, starts Knit |

#### Controllers Overview

| Controller | Responsibility |
|------------|---------------|
| `UIController` | HUD, depth gauge, oxygen bar, shop, inventory, quest panels |
| `DivingController` | Swimming, dive state, movement controls |
| `CameraController` | Underwater camera effects, fog, depth-based transitions |
| `AudioController` | Zone ambients (6 zones), SFX (16+), music (4 tracks with crossfades) |
| `FishingController` | Rod casting, line visuals, bite detection, reel-in mini-game |
| `VFXController` | Particle systems, bioluminescence, anomaly visual effects |

---

## 🆕 How to Add a New Service

### 1. Create the service file

```bash
touch src/server/services/MyNewService.lua
```

### 2. Use the Knit service template

```lua
--[[
    MyNewService — Description of what this service does
    Integrates with: [other services it depends on]
]]

local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Util"))

local MyNewService = Knit.CreateService {
    Name = "MyNewService",
    Client = {
        -- Signals that fire to client
        MyEvent = Knit.CreateSignal(),
        
        -- Queries (RemoteFunctions)
        GetData = Knit.CreateSignal(),
        
        -- Actions (RemoteFunctions)
        DoThing = Knit.CreateSignal(),
    }
}

-- Internal state
local playerData = {}

function MyNewService:KnitStart()
    print("[MyNewService] Initialized")
end

-- Called by DataStoreManager after loading a player's profile
function MyNewService:ReloadFromProfile(player)
    local DataStoreManager = require(game:GetService("ServerScriptService"):WaitForChild("Knit"):WaitForChild("datastore"):WaitForChild("DataStoreManager"))
    local profileSync = DataStoreManager:GetPlayerProfileSync(player)
    -- Initialize state from profile
end

function MyNewService:PlayerRemoving(player)
    playerData[player.UserId] = nil
end

-- Client handler (RemoteFunction)
function MyNewService.Client:GetData(player)
    -- Return data to client
end

function MyNewService.Client:DoThing(player, ...)
    -- Handle client action
end

return MyNewService
```

### 3. Add profile fields if needed

Edit `src/server/datastore/ProfileTemplate.lua` to add new persistent fields.

### 4. (No registration needed)

The server `init.lua` auto-discovers all modules in `Services/` and requires them. Your service will be picked up automatically.

---

## 🆕 How to Add a New Controller

```bash
touch src/client/controllers/MyNewController.lua
```

Use the Knit controller template:

```lua
local Knit = Knit or require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config"))

local MyNewController = Knit.CreateController {
    Name = "MyNewController",
}

function MyNewController:KnitStart()
    print("[MyNewController] Initialized")
end

return MyNewController
```

Like services, controllers are auto-discovered by the client `init.lua`.

---

## 🧪 Testing Guide

### In-Studio Testing

1. Start `rojo serve` and connect in Studio
2. Play the game (F5)
3. Check the Output window for initialization logs:
   - `[OxygenService] Initialized`
   - `[DepthService] Initialized`
   - `[CreatureService] Initialized`
   - etc.

### Testing Specific Systems

| System | How to Test |
|--------|-------------|
| Oxygen | Dive → watch oxygen drain → surface to refill → buy tank for emergency refill |
| Depth | Progress through zones → exceed gear limit → pressure damage activates |
| Creatures | Dive to any depth → wait for encounter → click to catch → check collection |
| Economy | Sell creatures → buy gear → check balance updates |
| Shop | Open shop → browse categories → purchase items |
| Anomaly | Wait for random trigger (minimum 1 active diver) → observe lighting/fog change |
| Base Building | Gather Scrap/Crystal → open base editor → place modules |
| Tutorial | Join with fresh account → follow 8 steps → check completion |
| Quests | Complete tutorial → open quest tab → accept dailies → complete conditions |
| Fishing | Equip rod → cast → wait for bite → reel in |
| Daily Rewards | Claim consecutive days → verify streak tracking |

### Debug Commands

Add to any service for testing:

```lua
-- In EconomyService, for example:
function EconomyService:DebugAddCredits(player, amount)
    self:AddCredits(player, amount)
    print(string.format("[DEBUG] Added %d Credits to %s", amount, player.Name))
end
```

---

## 🚨 Common Issues

### "Knit is not a valid member" error
- **Cause:** Wally dependencies not installed
- **Fix:** Run `wally install` from project root

### Rojo can't connect to Studio
- **Cause:** Rojo plugin not installed or firewall blocking
- **Fix:** Install the Rojo Studio plugin from Plugins → Rojo → Install
- **Check:** Ensure port 34872 is not blocked by firewall

### "Module not found" errors
- **Cause:** Incorrect path in `require()` call
- **Fix:** Services should use: `game:GetService("ReplicatedStorage"):WaitForChild("KnitShared"):WaitForChild("Modules"):WaitForChild("Config")`

### Changes not appearing in Studio
- **Cause:** Rojo serve disconnected
- **Fix:** Reconnect via Plugins → Rojo → Connect to Project
- **Check:** Terminal shows "Serving..." and Studio shows "Connected" status

### Profile fails to load
- **Cause:** DataStore not configured or invalid schema
- **Fix:** Check `DataStoreManager.lua` → `DATASTORE_NAME` constant
- **Fix:** Ensure `ProfileTemplate.lua` matches the expected schema

---

## 📦 Dependencies

Managed via `wally.toml`:

```toml
[package]
name = "nexus-blox-studios/abyss-of-the-deep"
description = "A deep-sea exploration and survival game on Roblox"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Knit = "sleitnick/knit@1.4.7"
ProfileService = "madstudios/profile-service@2.0.0"
```

---

## 🔄 Git Workflow

```bash
# Branch naming convention
feature/<system>-<description>    # e.g., feature/oxygen-refill
fix/<system>-<description>        # e.g., fix/creature-spawn-crash

# Before committing
rojo build --output build/abyss-of-the-deep.rbxlx  # Verify build

# Commit message format
type(scope): description

# Examples:
feat(oxygen): add emergency tank consumable
fix(depth): correct pressure damage calculation
docs(readme): update service list
refactor(economy): extract XP calculation to helper
```

---

## 📚 Reference

- [Knit Documentation](https://github.com/Sleitnick/Knit) — Service/controller patterns
- [Rojo Documentation](https://rojo.space/docs/) — Build and sync
- [Wally Documentation](https://wally.run/docs) — Package management
- [ProfileService Documentation](https://github.com/MadStudioRoblox/ProfileService) — Data persistence
- [Luau Documentation](https://luau-lang.org/) — Language reference
- [Roblox Creator Documentation](https://create.roblox.com/docs) — Engine reference