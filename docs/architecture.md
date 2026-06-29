# Abyss of the Deep — Architecture Overview

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Game Engine | Roblox Studio | Latest |
| Framework | Knit (sleitnick) | 1.4.7 |
| Sync Tool | Rojo | 7.x |
| Package Manager | Wally | Latest |
| Persistence | ProfileService | 2.0.0 |
| Scripting Language | Luau | Roblox latest |

## Project Structure

```
src/
├── shared/                # Code shared between client and server
│   ├── modules/
│   │   ├── Config.lua     # Game constants, layer definitions, gear tables
│   │   ├── Types.lua      # Type definitions, network events, schemas
│   │   └── Util.lua       # Pure utility functions
│   └── init.lua           # Shared module index
│
├── server/                # Server-side code (runs on Roblox servers)
│   ├── services/
│   │   ├── OxygenService.lua      # Oxygen management & refill
│   │   ├── DepthService.lua       # Depth layers, pressure, gear tiers
│   │   ├── CreatureService.lua    # Creature spawning & catching
│   │   ├── CollectionService.lua  # Player collection journal
│   │   ├── BaseBuildingService.lua # Underwater base construction
│   │   ├── EconomyService.lua     # Currency, XP, leveling
│   │   └── LeaderboardService.lua # Depth & collection leaderboards
│   ├── datastore/
│   │   ├── DataStoreManager.lua   # ProfileService wrapper
│   │   └── ProfileTemplate.lua    # Player profile schema
│   └── init.lua           # Server bootstrap with Knit.start()
│
└── client/                # Client-side code (runs on player's machine)
    ├── controllers/
    │   ├── CameraController.lua   # Underwater camera effects
    │   ├── DivingController.lua   # Swimming & movement
    │   └── UIController.lua       # HUD and screen management
    └── init.lua           # Client bootstrap with Knit.start()
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Roblox Server                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              ServerScriptService                  │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  │   │
│  │  │OxygenService│  │DepthService│  │CreatureSvc │  │   │
│  │  └────────────┘  └────────────┘  └────────────┘  │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  │   │
│  │  │CollectionSvc│  │EconomySvc │  │Leaderboard │  │   │
│  │  └────────────┘  └────────────┘  └────────────┘  │   │
│  │  ┌────────────┐  ┌──────────────────────────┐    │   │
│  │  │BaseBuilding│  │   DataStoreManager       │    │   │
│  │  └────────────┘  └──────────────────────────┘    │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                               │
│              ┌───────────┴───────────┐                   │
│              │   ReplicatedStorage   │                   │
│              │  ┌─────────────────┐  │                   │
│              │  │  Shared Modules  │  │                   │
│              │  │ Config, Types,  │  │                   │
│              │  │    Util.lua     │  │                   │
│              │  └─────────────────┘  │                   │
│              │  ┌─────────────────┐  │                   │
│              │  │   Knit Packages │  │                   │
│              │  └─────────────────┘  │                   │
│              └───────────────────────┘                   │
│                          │                               │
├──────────────────────────┼───────────────────────────────┤
│                   Client │                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │              StarterPlayerScripts                 │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  │   │
│  │  │CameraCtrl  │  │DivingCtrl  │  │UICtrl      │  │   │
│  │  └────────────┘  └────────────┘  └────────────┘  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │              PlayerGui (UI Screens)               │   │
│  │  HUD | Shop | Collection | Base Editor | Settings │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │           UserInput + Camera + Audio              │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Data Flow

### Diving Loop
1. Player presses SPACE → DivingController.StartDive() → OxygenService.StartDive() (server)
2. Player moves → DivingController tracks depth → DepthService.UpdatePlayerDepth()
3. Server tick loop → OxygenService drains oxygen based on depth layer
4. If oxygen critical → warning to client → UI shows red pulse
5. If oxygen zero → ForceSurface() → player returns to surface

### Creature Encounter Loop
1. CreatureService tick loop → checks if player is in a depth layer
2. Roll encounter → CreatureService.SpawnCreatureForPlayer()
3. Client receives CreatureSpawned event → UIController shows encounter
4. Player presses catch → CreatureService.Client.RequestCatch()
5. Server rolls catch chance → success/failure → CollectionService updated

## Network Strategy

- **Knit Signals** (RemoteEvents/RemoteFunctions under the hood) for service-client communication
- Oxygen, depth updates pushed from server every second
- Creature encounters pushed on spawn
- Economy and collection updates pushed on change
- Requests from client use Knit client method calls (RemoteFunctions)

## Data Persistence

- **ProfileService** pattern via DataStoreManager
- Auto-saves every 120 seconds
- Saves on player leave
- Versioned profiles with migration support
- Key player data: progression, gear, collection, base layout, stats

## Performance Considerations

- Creature encounter checks run on 5s interval, not every frame
- Camera effects use RenderStepped binding but lerp smoothly
- Oxygen drain processed in 1s tick on server, not per-frame
- UI updates only on event fire (not polling)
- Base building limited to 20 modules per player