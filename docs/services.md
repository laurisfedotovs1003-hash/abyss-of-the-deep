# Service Documentation

## OxygenService
**Purpose:** Manages player oxygen levels and refill mechanics.

### Key Methods
| Method | Type | Description |
|--------|------|-------------|
| `PlayerAdded(player)` | Internal | Initialize oxygen data for new player |
| `PlayerRemoving(player)` | Internal | Clean up player data |
| `StartDive(player)` | Internal | Begin draining oxygen |
| `EndDive(player)` | Internal | Stop draining, refill at surface |
| `ProcessOxygenTick()` | Internal | 1-second loop draining oxygen per depth |
| `ForceSurface(player)` | Internal | Teleport player to surface when oxygen depleted |
| `AddOxygenBonus(player, amount)` | Internal | Increase max oxygen from gear/game passes |

### Client Signals
- `GetOxygenData` — Updates oxygen bar UI
- `RequestRefill` — Consume oxygen tank item
- `UseEmergencyTank` — Emergency oxygen boost

---

## DepthService
**Purpose:** Controls depth layers, diving gear progression, and pressure mechanics.

### Key Methods
| Method | Type | Description |
|--------|------|-------------|
| `UpdatePlayerDepth(player, newDepth)` | Internal | Update player's current depth |
| `GetMaxDepthForGear(gearTier)` | Internal | Calculate depth limit per gear tier |
| `UpgradeGear(player)` | Internal | Purchase and equip next gear tier |
| `ApplyPressureDamage(player, levels)` | Internal | Damage player for exceeding gear depth |
| `SurfacePlayer(player)` | Internal | Reset depth to 0 |

### Client Signals
- `GetDepthData` — Depth, layer, gear info for HUD
- `GetLayerInfo` — Zone transition details
- `UpgradeGearRequest` — Player buys new gear

### Depth Zones
| # | Zone | Depth Range | Gear Required |
|---|------|-------------|---------------|
| 1 | Sunlight | 0-200m | Basic Gear (T1) |
| 2 | Twilight | 200-1,000m | Scuba Kit (T2) |
| 3 | Midnight | 1,000-4,000m | Advanced Suit (T3) |
| 4 | Abyssal | 4,000-6,000m | Bathysphere (T4) |
| 5 | Trenches | 6,000-11,000m | Abyssal Exosuit (T5) |

---

## CreatureService
**Purpose:** Spawns creatures, manages encounter logic, and handles catch mechanics.

### Key Methods
| Method | Type | Description |
|--------|------|-------------|
| `RollEncounter(layerIndex)` | Internal | Weighted random creature selection |
| `SpawnCreatureForPlayer(player, layerIndex)` | Internal | Trigger creature encounter |
| `ProcessEncounters()` | Internal | 5-second loop for creature timing |
| `Client.RequestCatch(player)` | Client | Player attempts to catch creature |

### Rarity System
| Rarity | Weight | Catch Modifier | Color |
|--------|--------|----------------|-------|
| Common | 50 | 1.0x | Gray |
| Uncommon | 30 | 0.5x | Green |
| Rare | 15 | 0.25x | Blue |
| Epic | 4 | 0.1x | Purple |
| Legendary | 1 | 0.03x | Gold |

Shiny variants: ~1% chance, 3x sell value

---

## CollectionService
**Purpose:** Tracks player's collection of caught creatures.

### Key Methods
| Method | Type | Description |
|--------|------|-------------|
| `AddCreatureToCollection(player, data)` | Internal | Store caught creature |
| `HasCreature(player, creatureId)` | Internal | Check if creature already collected |

### Client Signals
- `CollectionUpdated` — Progress and count updates
- `GetCollection` — Full collection data
- `GetCollectionProgress` — Completion percentage

---

## BaseBuildingService
**Purpose:** Underwater habitat construction and management.

### Module Types
- **Habitat** — Living quarters (sleep to restore oxygen)
- **Greenhouse** — Grow resources
- **Lab** — Research and crafting
- **DefenseTurret** — Protect base from threats
- **Decoration** — Cosmetic items

### Limits
- Max 20 modules per base
- 3 upgrade tiers per module
- Players can only build at their base location

---

## EconomyService
**Purpose:** Currency management, XP/leveling, and purchases.

### Economics
- Starting currency: 50
- XP gained from: depth exploration (0.5/m), creature capture (25 each)
- Level formula: `100 * level * 1.5` XP needed
- Level-up bonus: `level * 10` currency

### Client Signals
- `EconomyUpdated` — Currency, XP, level changes
- `GetBalance` — Current balance data
- `PurchaseConsumable` — Buy items with in-game currency

---

## LeaderboardService
**Purpose:** Track and display top players.

### Leaderboards
- **Depth Records** — Max depth reached (OrderedDataStore)
- **Collection Completion** — Total unique creatures
- **Currency** — Total currency earned

Auto-refreshes every 120 seconds from DataStore.

---

## DataStoreManager
**Purpose:** Save/load player profiles with automatic persistence.

### Save Strategy
- Auto-save: Every 120 seconds
- On player leave: Immediate save
- Version migration: Automatic on version change

### Profile Schema
```lua
{
    Version = 2,
    Experience = 0, Level = 1, Currency = 50,
    CurrentGearTier = 1, OwnedGearTiers = {1},
    MaxDepthReached = 0,
    CreatureCollection = {},
    BaseModules = {}, BaseLocation = {0, 0, 0},
    TotalPlayTime = 0, TotalSessions = 1,
    FirstJoinTime = os.time(),
}
```