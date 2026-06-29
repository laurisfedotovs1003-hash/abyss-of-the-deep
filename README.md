# Abyss of the Deep

**A deep-sea exploration and survival game on Roblox**

Descend through ocean layers (Sunlight → Twilight → Midnight → Abyss → Trenches), discovering bioluminescent creatures, building submarine bases, and encountering deep-sea anomalies. Mix of exploration, survival, base-building, and creature collection.

## Project Structure

```
abyss-of-the-deep/
├── default.project.json    # Rojo project configuration
├── wally.toml              # Wally package manager dependencies
├── src/
│   ├── shared/             # Code shared between client & server
│   │   ├── modules/        # Config, types, utilities
│   │   └── init.lua        # Shared module entry point
│   ├── client/             # Client-side code (StarterPlayerScripts)
│   │   ├── controllers/    # Knit controllers (camera, diving, UI)
│   │   ├── ui/             # Player-facing UI components
│   │   └── init.lua        # Client init with Knit.start()
│   ├── server/             # Server-side code (ServerScriptService)
│   │   ├── services/       # Knit services (core game systems)
│   │   ├── datastore/      # Data persistence layer
│   │   └── init.lua        # Server init with Knit.start()
│   └── assets/             # Asset reference notes
├── build/                  # Rojo build output (compiled .rbxlx)
└── docs/                   # Architecture & design documentation
```

## Prerequisites

- [Rojo](https://rojo.space/) v7.x — File-to-Roblox Studio sync
- [Wally](https://wally.run/) — Package manager for Roblox
- Roblox Studio

## Setup

### 1. Install dependencies

```bash
wally install
```

This creates the `Packages/` directory with Knit and other dependencies.

### 2. Build & sync with Rojo

```bash
# Build the project file
rojo build --output build/abyss-of-the-deep.rbxlx

# Or serve for live sync with Roblox Studio
rojo serve
```

### 3. In Roblox Studio

- Connect to the Rojo server via the Rojo plugin
- Insert the build into Studio, or sync directly
- The game will initialize via Knit's bootstrapper

## Architecture

### Knit Framework

This project uses **Knit** (by sleitnick) for service/controller architecture:

- **Services** (server-only) — Manage game state, handle logic, communicate with DataStores
- **Controllers** (client-only) — Handle user input, camera, UI updates
- **Shared modules** — Code used by both client and server (config, types, utilities)

### Core Systems

| System | Service | Description |
|--------|---------|-------------|
| Oxygen Management | OxygenService | Player oxygen levels, refill mechanics |
| Depth Layers | DepthService | 5 ocean zones with increasing pressure/dangers |
| Creatures | CreatureService | AI behavior, spawning, rarity tables |
| Collection | CollectionService | Player collection journal, scanning/ catching |
| Base Building | BaseBuildingService | Underwater habitat construction & upgrades |
| Persistence | DataStoreService | Player data save/load via ProfileService |
| Leaderboards | LeaderboardService | Depth records, collection completion |

## Development Workflow

1. Edit `.lua` files in the `src/` directory
2. Rojo syncs changes to Roblox Studio in real-time (when serving)
3. Test in Studio, then iterate
4. Commit changes to version control

## Team

**Nexus Blox Studios**

- Game Designer
- Lead Developer
- Gameplay Scripter
- Technical Artist
- UI/UX Designer
- Market Analyst
- Trend Researcher