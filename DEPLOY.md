# Deployment Guide — Abyss of the Deep

> Step-by-step guide for publishing Abyss of the Deep to Roblox.

---

## 📋 Pre-Deployment Checklist

Before publishing, verify:

- [ ] All systems initialized without errors in Studio playtest
- [ ] Tutorial flow completed end-to-end
- [ ] All 5 depth zones accessible with appropriate gear tiers
- [ ] Creature encounters work across all rarity tiers
- [ ] Economy balanced (starting Credits, gear prices, creature sell values)
- [ ] Daily rewards cycle complete (7 days tested)
- [ ] Shop purchases (gear + consumables) function correctly
- [ ] Quest system: daily/milestone/event/achievement all completable
- [ ] Anomaly events trigger and end correctly
- [ ] Base building works (module placement, upgrades, resource costs)
- [ ] Data persistence: progress saves across sessions
- [ ] Leaderboards display correct data
- [ ] No script errors in Output window
- [ ] No memory leaks after extended play session
- [ ] Mobile UI tested (touch controls, screen scaling)
- [ ] Console UI tested (controller support, text scaling)

---

## 🏗️ Step 1: Creator Dashboard Setup

1. Go to [create.roblox.com/dashboard](https://create.roblox.com/dashboard)
2. Click **"Create New Experience"** (or select existing if updating)
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | Abyss of the Deep |
| **Description** | Descend through ocean layers in this deep-sea exploration game! Discover 30+ unique creatures, manage oxygen, upgrade your diving gear, and survive mysterious anomalies. Build your underwater base and collect rare species in the depths. |
| **Genre** | Adventure |
| **Genre (sub)** | Exploration |
| **Devices** | ✔ Computer ✔ Mobile ✔ Tablet ✔ Console |
| **Allowed Gear** | None (experience gear disabled) |

4. **Save** the experience settings

---

## 📸 Step 2: Icons & Thumbnails

### Required Assets

| Asset | Size | Format | Description |
|-------|------|--------|-------------|
| **Icon** | 512×512 | PNG | Square game icon shown in search/results |
| **Thumbnail** | 1920×1080 | PNG | Main game thumbnail on the detail page |
| **Detailed Description** | 1920×1080 | PNG | At least 1 image for the description area |
| **Social Media** | 1200×630 | PNG | OG image for link sharing |

### Design Guidelines

- **Icon:** Deep blue background with a glowing bioluminescent creature silhouette. High contrast for small display sizes.
- **Thumbnail:** Show a diver descending through distinct ocean layers with a dramatic creature encounter. Include "Abyss of the Deep" title text.
- **Tone:** Mysterious, atmospheric, adventurous. Dark blues/purples with bioluminescent cyan/gold accents.
- **No UI elements** in thumbnails (Roblox policy)
- **No text** in icons (except the main thumbnail can have title)

> **Production note:** Team Technical Artist will create these assets. Replace `rbxassetid://0` placeholders in Config.lua with the published asset IDs.

---

## 🔗 Step 3: Place ID Linking

### Get Your Place ID

1. In Creator Dashboard, open your experience
2. The URL contains the Place ID: `https://create.roblox.com/dashboard/experiences/[PLACE_ID]`
3. Or check the Game Settings tab for "Place ID"

### Update default.project.json (if needed for Universe ID)

The `default.project.json` may need the Universe ID for analytics:

```json
{
  "name": "abyss-of-the-deep",
  "tree": { ... }
}
```

For development the project file works as-is. For production, you may want to add a `.place` file or configure via Creator Dashboard.

---

## 🎮 Step 4: Upload the Build

### Via Rojo Build

```bash
# Ensure packages are installed
wally install

# Build the production file
rojo build --output build/abyss-of-the-deep.rbxlx
```

### Upload to Roblox

**Option A: Via Creator Dashboard**

1. Go to your experience in Creator Dashboard
2. Click **"Upload Place"** or **"Edit Place"**
3. Select `build/abyss-of-the-deep.rbxlx`
4. Wait for upload to complete (typically 1-3 minutes)
5. Add version notes, e.g.: "Alpha v0.1 — All core systems implemented"

**Option B: Via Roblox Studio**

1. Open `build/abyss-of-the-deep.rbxlx` in Studio
2. Go to **File → Publish to Roblox (As...)** → select your experience
3. Wait for upload

### Version Management

- Use **"Shut Down Current Servers"** after uploading if players are on old versions
- Monitor the **"Experiences"** tab for active player counts after deployment
- Keep previous builds archived in case of rollback

---

## 💳 Step 5: Game Pass Configuration

### Create Game Passes in Creator Dashboard

1. Go to **Creator Dashboard → [Your Experience] → Store Items**
2. Create each game pass:

| Name | Price (Robux) | Description | Icon Size |
|------|--------------|-------------|-----------|
| Oxygen Booster | 79 | +100 base oxygen capacity — dive longer, explore deeper | 512×512 |
| Speed Diver | 99 | +20% swim speed — move through the depths faster | 512×512 |
| Expanded Collection | 149 | Double your creature collection slots | 512×512 |
| Abyssal Pass | 249 | Access exclusive content in the deepest trenches | 512×512 |
| VIP Status | 399 | +25% Credits, +15% XP, +5 max O₂, exclusive VIP title | 512×512 |

### Map Game Pass IDs to Config.lua

After creating each pass, Roblox assigns a numeric ID. Update `Config.lua`:

```lua
-- In Config.lua — after publishing, replace 0 with actual IDs
Config.GamePasses = {
    OxygenBooster = 1234567890,       -- Replace with actual ID
    SpeedDiver = 1234567891,
    ExpandedCollection = 1234567892,
    AbyssalPass = 1234567893,
    VIPStatus = 1234567894,
}
```

### Create Developer Products

| Product | Price (Robux) | Description |
|---------|--------------|-------------|
| 500 Credits | 49 | Small credit pack for new players |
| 2,000 Credits | 149 | Mid-tier credit pack — best value per Robux |
| 10,000 Credits | 499 | Whale tier — for dedicated collectors |
| 10 Research Points | 49 | Small RP pack for cosmetic purchases |
| 50 Research Points | 199 | Mid-tier RP pack |
| 250 Research Points | 799 | Premium RP pack — unlock everything |
| Starter Pack | 99 | Best value — Credits, Oxygen Tanks, Lures |

Update `Config.DeveloperProducts` similarly with the published IDs.

### Configure the Depth Pass (Seasonal)

| Product | Price (Robux) | Description |
|---------|--------------|-------------|
| Depth Pass Season 1 | 399 | Premium battle pass track — exclusive cosmetics, creatures, titles |

---

## 📊 Step 6: Analytics Setup

### Roblox Built-in Analytics

Available automatically once published via Creator Dashboard:
- **Engagement:** DAU, MAU, session length, session frequency
- **Retention:** D1, D7, D14, D30
- **Monetization:** Revenue, ARPU, ARPPU, conversion rate
- **Performance:** Script performance, memory usage, network traffic

### Custom Analytics (in Config.lua)

```lua
Config.Analytics = {
    Enabled = true,                    -- Already configured
    SessionTimeout = 300,              -- 5 min idle = new session
    EventPrefix = "Abyss_",            -- All events prefixed for identification
}
```

### Key Events to Monitor

| Event | When Fired | Tracking Purpose |
|-------|-----------|------------------|
| `Abyss_TutorialCompleted` | After step 8 | Tutorial conversion rate |
| `Abyss_DiveStarted` | Player enters water | Session depth metric |
| `Abyss_DiveCompleted` | Player surfaces | Dive completion rate |
| `Abyss_CreatureCaught` | Successful catch | Catch rate per rarity |
| `Abyss_FirstDiscovery` | New species found | Collection progress rate |
| `Abyss_GearPurchased` | Any gear upgrade | Economy velocity |
| `Abyss_AnomalyEncountered` | Anomaly triggers | Feature engagement |
| `Abyss_QuestCompleted` | Quest claimed | Quest system adoption |
| `Abyss_DailyRewardClaimed` | Daily reward claimed | Retention metric |
| `Abyss_ShopPurchase` | Any shop purchase | Conversion tracking |
| `Abyss_GamePassPurchased` | Game pass redeemed | Revenue source |
| `Abyss_DepthMilestoneReached` | Milestone depth | Progression pacing |

---

## 🚀 Step 7: Publishing Go-Live

### Final Checklist Before Public Launch

- [ ] All game passes and developer products created with correct prices
- [ ] Config.lua updated with actual product IDs
- [ ] Analytics events tested end-to-end
- [ ] Icon and thumbnails uploaded
- [ ] Description written and formatted (markdown preview checked)
- [ ] Social links added: Discord server, Twitter, DevForum post
- [ ] Privacy policy configured (required for data collection)
- [ ] Age guidelines: set to **"Appropriate for All Ages"** per content review
- [ ] Game link tested: `https://www.roblox.com/games/[PLACE_ID]/Abyss-of-the-Deep`

### Launch Sequence

1. **Soft launch:** Set to "Private" → invite testers → 24h bug bash
2. **Fix critical bugs** from soft launch feedback
3. **Public launch:** Set game visibility to "Public"
4. **Post-launch:** Monitor for 48 hours, address issues, track KPIs

### Marketing Channels

| Channel | Action |
|---------|--------|
| DevForum | Post in "My Game Feedback" section — include trailer, description, key features |
| Discord | Create server, invite alpha testers, pin Roadmap |
| Twitter/X | Share trailer, update on milestones, #RobloxDev |
| Roblox Ads | Consider Sponsored Experience ads after launch week |
| UGC Creators | Collaborate for avatar item cross-promotions |

---

## 🔄 Step 8: Post-Launch Updates

### Update Pipeline

```bash
# 1. Pull latest changes
git pull origin main

# 2. Install any new dependencies
wally install

# 3. Build
rojo build --output build/abyss-of-the-deep.rbxlx

# 4. Upload via Creator Dashboard
# 5. Add update notes: "Fixed [#issue] in [system]"
# 6. Shut down old servers (if breaking changes)
```

### Typical Update Cadence

| Update Type | Frequency | Scope |
|-------------|-----------|-------|
| Bug fixes | As needed | Small patches, no version bump |
| Balance tuning | Weekly | Config.lua changes only |
| New content (creatures, items) | Bi-weekly | Creature data, shop items |
| Feature releases | Monthly | New services, major systems |
| Seasonal (Depth Pass) | Every 4-6 weeks | Battle pass, events, limited items |

### Version Convention

Use tags in git for deployment versions:

```bash
git tag v0.1.0-alpha    # Alpha release
git tag v0.2.0-beta     # Beta with fixes
git tag v1.0.0          # Full launch
```

---

## ⚠️ Common Deployment Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Place ID not found" | Wrong Universe ID | Check URL in Creator Dashboard |
| Game passes not working | Missing or wrong product IDs | Verify IDs in Config.lua match Creator Dashboard |
| Old version still running | Servers not shut down | Use "Shut Down Current Servers" option |
| Profile data lost | Schema mismatch | Ensure ProfileTemplate.lua matches Types.lua |
| Analytics not tracking | Incorrect prefix | Check Config.Analytics.EventPrefix |
| Icon not showing | Wrong dimensions | Verify 512×512 PNG upload |
| Players can't join | Place set to Private | Change visibility to Public |