# Asset Pipeline Guide — Abyss of the Deep

> Guide for creating, uploading, and managing game assets (sounds, models, images, animations).

---

## 📊 Asset Overview

### Required Assets by Category

| Category | Count | Status | Format |
|----------|-------|--------|--------|
| Creature Models | 30+ | ⚪ Placeholder (IDs = 0) | `.rbxm` + MeshParts |
| Environment Geometry | ~15 | ⚪ Placeholder | `.rbxm` / Terrain |
| Base Module Models | 10+ | ⚪ Placeholder | `.rbxm` |
| Ambient Sounds | 6 | ⚪ Placeholder | `.mp3` / `.ogg` |
| SFX | 16+ | ⚪ Placeholder | `.mp3` / `.ogg` |
| Music Tracks | 4 | ⚪ Placeholder | `.mp3` / `.ogg` |
| UI Icons | 50+ | ⚪ Placeholder | `.png` 512×512 |
| UI Textures | ~10 | ⚪ Placeholder | `.png` 1024×1024 |
| Game Icon | 1 | ⚪ Placeholder | `.png` 512×512 |
| Thumbnails | 3+ | ⚪ Placeholder | `.png` 1920×1080 |
| Particle Textures | ~8 | ⚪ Placeholder | `.png` 256×256 |

---

## 🔊 Sound Pipeline

### File Format Requirements

| Format | Sample Rate | Bit Depth | Channels | Max Duration |
|--------|-------------|-----------|----------|-------------|
| `.mp3` | 44100 Hz | 320 kbps | Stereo | 7 min (ambient loops) |
| `.ogg` | 44100 Hz | VBR | Stereo | 30 sec (SFX) |

### Upload Process

1. **Prepare audio files** in your DAW (Audacity, FL Studio, Ableton)
2. **Export** as `.mp3` (music/ambient) or `.ogg` (SFX) at 44100 Hz
3. **Upload to Roblox** via [create.roblox.com/library](https://create.roblox.com/library)
   - Category: Audio
   - Make sure to set "Allow Use in Experiences" to ON
4. **Copy the Asset ID** (the number in the URL: `https://www.roblox.com/library/[ASSET_ID]`)
5. **Update placeholders** in the code

### Sound Asset Map

Update `AudioController.lua` with actual asset IDs:

```lua
-- In AudioController.lua — replace rbxassetid://0 with actual IDs

SOUNDS = {
    Ambient = {
        Surface = { SoundId = "rbxassetid://1234567890", Volume = 0.3, Looped = true },
        SunlightZone = { SoundId = "rbxassetid://1234567891", Volume = 0.4, Looped = true },
        TwilightZone = { SoundId = "rbxassetid://1234567892", Volume = 0.35, Looped = true },
        MidnightZone = { SoundId = "rbxassetid://1234567893", Volume = 0.3, Looped = true },
        AbyssalZone = { SoundId = "rbxassetid://1234567894", Volume = 0.25, Looped = true },
        TrenchZone = { SoundId = "rbxassetid://1234567895", Volume = 0.2, Looped = true },
    },
    SFX = {
        DiveSplash = { SoundId = "rbxassetid://1234567900", Volume = 0.6 },
        SurfaceSplash = { SoundId = "rbxassetid://1234567901", Volume = 0.5 },
        BubbleLoop = { SoundId = "rbxassetid://1234567902", Volume = 0.3, Looped = true },
        CreatureCatch = { SoundId = "rbxassetid://1234567903", Volume = 0.7 },
        CreatureEscape = { SoundId = "rbxassetid://1234567904", Volume = 0.5 },
        OxygenWarning = { SoundId = "rbxassetid://1234567905", Volume = 0.8 },
        PressureWarning = { SoundId = "rbxassetid://1234567906", Volume = 0.7 },
        GearUpgrade = { SoundId = "rbxassetid://1234567907", Volume = 0.6 },
        Purchase = { SoundId = "rbxassetid://1234567908", Volume = 0.5 },
        LevelUp = { SoundId = "rbxassetid://1234567909", Volume = 0.7 },
        AnomalyWarning = { SoundId = "rbxassetid://1234567910", Volume = 0.6 },
        AnomalyStart = { SoundId = "rbxassetid://1234567911", Volume = 0.8 },
        AnomalyEnd = { SoundId = "rbxassetid://1234567912", Volume = 0.5 },
        QuestComplete = { SoundId = "rbxassetid://1234567913", Volume = 0.7 },
        DailyReward = { SoundId = "rbxassetid://1234567914", Volume = 0.6 },
        TutorialStep = { SoundId = "rbxassetid://1234567915", Volume = 0.5 },
    },
    Music = {
        Surface = { SoundId = "rbxassetid://1234567920", Volume = 0.2, Looped = true },
        Exploration = { SoundId = "rbxassetid://1234567921", Volume = 0.15, Looped = true },
        Danger = { SoundId = "rbxassetid://1234567922", Volume = 0.2, Looped = true },
        Anomaly = { SoundId = "rbxassetid://1234567923", Volume = 0.25, Looped = true },
    },
}
```

### Sound Design Notes

| Sound | Mood / Reference | Notes |
|-------|-----------------|-------|
| Surface Ambient | Gentle waves, distant seagulls, wind | Calm, inviting |
| Sunlight Zone | Bubbles, distant reef sounds, water movement | Bright, alive |
| Twilight Zone | Muffled, deeper bubbles, distant creaks | Mysterious, transitional |
| Midnight Zone | Low hum, sonar pings, pressure creaks | Eerie, isolated |
| Abyssal Zone | Deep rumbles, dripping, whale calls | Oppressive, awe-inspiring |
| Trench Zone | Subsonic, barely audible, heartbeat | Terrifying, sacred |
| Creature Catch | Satisfying "thwip" + splash | Rewarding, punchy |
| Anomaly Warning | Low horn + rising pitch | Urgent, ominous |
| Oxygen Warning | Rhythmic beep (like dive computer) | Stressful, actionable |

---

## 🎨 Model & Mesh Pipeline

### File Format Requirements

| Format | Use Case | Max Vertices | Max Parts |
|--------|----------|-------------|-----------|
| `.rbxm` (Roblox Model) | Full game objects | 10,000 per model | 20 per model |
| `.obj` | External 3D export | 50,000 | N/A |
| `.fbx` | Animated models | 50,000 | N/A |

### Creature Models

Each creature needs a 3D model. Design guidelines:

| Rarity | Quality Tier | Polygon Budget | UV Map | Animation |
|--------|-------------|----------------|--------|-----------|
| Common | Simple shapes | 200-500 tris | Basic | Idle bob, swim cycle |
| Uncommon | Medium detail | 500-1,000 tris | Color | Idle + swim + attack |
| Rare | Detailed | 1,000-2,000 tris | Detailed | 3+ animations |
| Epic | High detail | 2,000-5,000 tris | PBR texture | 4+ animations + special |
| Legendary | Premium | 5,000-10,000 tris | PBR + emissive | 5+ animations + VFX |

### Creature Model Naming Convention

```
Creature_<Name>_<Rarity>
Example: Creature_Clownfish_Common.rbxm
Example: Creature_AbyssalKraken_Legendary.rbxm
```

### Upload Process

1. **Create models** in Blender, Maya, or Roblox Studio
2. **Export as `.rbxm`** (or import `.obj`/`.fbx` into Studio first, then save as model)
3. **Upload to Roblox** via [create.roblox.com/library](https://create.roblox.com/library)
   - Category: Models
   - Enable "Allow Use in Experiences"
4. **Copy Asset ID** → update `Config.lua`:

```lua
-- In Config.lua — Creature definitions
Config.Creatures = {
    {
        Name = "Clownfish",
        Rarity = "Common",
        Zone = "Sunlight Zone",
        Description = "Small orange fish with iconic white stripes.",
        ModelAssetId = 1234567890,  -- ← Replace 0 with actual ID
    },
    -- ... for all 30+ creatures
}
```

### Environment Models

| Asset | Description | Poly Budget |
|-------|-------------|-------------|
| Coral_Reef | Sunlight zone coral formations | 500-2,000 tris |
| Kelp_Stalk | Twilight zone swaying kelp | 100-200 tris each |
| Hydrothermal_Vent | Midnight zone vents with particle emissions | 300-500 tris |
| Ancient_Ruins | Abyssal zone ruins | 2,000-5,000 tris |
| Trench_Rock | Trench zone rock formations | 500-1,000 tris |
| Research_Station | Player hub / surface building | 3,000-5,000 tris |

### Base Module Models

| Module | Size | Description |
|--------|------|-------------|
| Habitat | 4×4×3 studs | Living quarters, restores oxygen |
| Greenhouse | 3×4×3 studs | Grows resources over time |
| Lab | 4×5×3 studs | Research and crafting station |
| DefenseTurret | 2×2×3 studs | Repels hostile creatures during anomalies |
| Decoration | 1×1×1 stud | Various cosmetic items |

---

## 🖼️ UI Asset Pipeline

### Icon Requirements

| Icon Type | Size | Format | Notes |
|-----------|------|--------|-------|
| Creature icons | 128×128 | PNG | Transparent background, centered subject |
| Item icons | 128×128 | PNG | Transparent background, 45° angle view |
| UI buttons | 256×128 | PNG | Rounded rectangle, dark background |
| Shop category icons | 64×64 | PNG | Simple glyph style |
| Rarity borders | 256×256 | PNG | Frame overlay for creature cards |
| Zone backgrounds | 1920×1080 | PNG | Used in collection zone tabs |

### UI Style Guide

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Primary BG | Deep Navy | `#0A0E2A` | Main panels, backgrounds |
| Secondary BG | Dark Blue | `#141838` | Cards, sub-panels |
| Accent | Electric Blue | `#3B82F6` | Buttons, highlights, active states |
| Accent 2 | Cyan | `#06B6D4` | Secondary buttons, links |
| Success | Green | `#10B981` | Purchase confirm, quest complete |
| Warning | Amber | `#F59E0B` | Oxygen warnings, pressure alerts |
| Danger | Red | `#EF4444` | Critical oxygen, damage |
| Gold | Gold | `#F59E0B` | Legendary highlights, premium |
| Text Primary | White | `#FFFFFF` | Main text |
| Text Secondary | Light Gray | `#94A3B8` | Descriptions, subtitles |
| Rarity Common | Gray | `#B0B0B0` | Common border |
| Rarity Uncommon | Green | `#1EC850` | Uncommon border |
| Rarity Rare | Blue | `#1E90FF` | Rare border |
| Rarity Epic | Purple | `#B400FF` | Epic border |
| Rarity Legendary | Gold | `#FFB400` | Legendary border |

### Font

- **Primary:** Roblox default font (Gotham) or custom font uploaded as `rbxassetid`
- **Sizes:** H1=28, H2=24, H3=20, Body=16, Small=14, Micro=12
- **Scaling:** Use `UDim2` and `Scale` for responsive design across devices

---

## 🎆 Particle & VFX Pipeline

### Required Particle Textures

| Texture | Size | Use Case |
|---------|------|----------|
| `particle_circle.png` | 128×128 | Soft bubbles, ambient particles |
| `particle_glow.png` | 64×64 | Bioluminescent glows, stars |
| `particle_ring.png` | 256×256 | Anomaly rings, shockwaves |
| `particle_spark.png` | 32×32 | Crystal sparkles, light shafts |
| `particle_bubble.png` | 64×64 | Oxygen bubbles, vent emissions |
| `particle_smoke.png` | 128×128 | Deep-sea smoke, vent clouds |
| `particle_beam.png` | 256×32 | Light shafts, sonar pings |
| `particle_trail.png` | 128×32 | Creature trails, swim lines |

### Upload Process

1. Create textures in Photoshop/GIMP (PNG with transparency)
2. Upload to Roblox as Decals or MeshParts
3. Reference via `rbxassetid://` in VFXUtil.lua and VFXController.lua

### VFX System Reference

Effects are managed through `VFXUtil.lua` (shared helpers) and `VFXController.lua` (client-side runtime):

| Effect | System | Trigger |
|--------|--------|---------|
| Swaying kelp | AnimatedEnvironmentUtil | ZoneService spawn |
| Hydrothermal bubbles | AnimatedEnvironmentUtil | ZoneService spawn |
| Marine snow | VFXController | Continuous in deep zones |
| Light shafts | VFXUtil | Depth-based brightness |
| Fish schools | AnimatedEnvironmentUtil | ZoneService spawn |
| Bioluminescent glow | VFXController | Creature proximity |
| Anomaly ambient particles | VFXController | AnomalyService trigger |
| Oxygen bubbles | VFXController | Player diving state |
| Pressure crack effects | VFXController | DepthService warning |
| Catch sparkle | VFXUtil | On creature caught |

---

## 📦 Asset Management Best Practices

### Organization

```
Project Assets/
├── Audio/
│   ├── Ambient/
│   ├── SFX/
│   └── Music/
├── Models/
│   ├── Creatures/
│   ├── Environment/
│   ├── BaseModules/
│   └── Tools/
├── UI/
│   ├── Icons/
│   ├── Backgrounds/
│   └── Components/
├── VFX/
│   ├── Textures/
│   └── Particles/
└── Marketing/
    ├── Icon/
    ├── Thumbnails/
    └── Trailer/
```

### Versioning

- Keep source files (`.blend`, `.psd`, `.aup3`) in version control
- Exported Roblox files (`.rbxm`, `.mp3`, `.png`) in a separate `assets/` folder
- Use naming convention: `AssetName_Type_Version.ext`
- Document asset IDs in a spreadsheet linked to the project

### Asset ID Tracking

Create an `ASSET_IDS.md` or spreadsheet:

```markdown
# Asset ID Registry

## Sounds
| Asset | Roblox ID | Uploaded By | Date |
|-------|-----------|-------------|------|
| Surface Ambient | 1234567890 | [Name] | 2026-07-01 |
| Dive Splash | 1234567900 | [Name] | 2026-07-01 |

## Models
| Asset | Roblox ID | Uploaded By | Date |
|-------|-----------|-------------|------|
| Clownfish | 1234567890 | [Name] | 2026-07-01 |

## UI
| Asset | Roblox ID | Uploaded By | Date |
|-------|-----------|-------------|------|
| CreatureCard_Common | 1234567890 | [Name] | 2026-07-01 |
```

### Placeholder Strategy

For development, use temporary models/IDs:
- Creatures: Colored blocks with labels until proper models are ready
- Sounds: Free Royality Free audio from Pixabay/Freesound for prototyping
- UI: Solid-color rectangles with text labels
- VFX: Basic Roblox particles with default textures

---

## 🎯 Production Priority

| Priority | Assets | Responsible | Timeline |
|----------|--------|-------------|----------|
| 🔴 **Critical** | Game Icon, Thumbnail, 5 creature models for trailer | Technical Artist | Pre-launch |
| 🟡 **High** | All 30+ creature models, UI icons, ambient sounds | Technical Artist + Designer | Launch |
| 🟢 **Medium** | Environment details, VFX polish, music | Technical Artist | Post-launch |
| 🔵 **Low** | Shiny variants, premium cosmetics, seasonal assets | Technical Artist | Live ops |