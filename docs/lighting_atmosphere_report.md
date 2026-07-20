# Abyssal Echoes: Lighting & Atmosphere Technical Report

## Overview
This report details the lighting and post-processing configurations implemented for the "Underwater Atmosphere Prototype". The goal is to maximize the "Visual Wow Factor" by creating a high-contrast, immersive environment that transitions from vibrant tropical surfaces to the oppressive, bioluminescent-only darkness of the deep trenches.

## Global Settings
- **Lighting Technology:** `Future` (Enabled via `CameraController` initialization). This allows for high-quality specular highlights on wet surfaces and accurate bioluminescent light casting.
- **Global Shadows:** Enabled.
- **Bloom:**
  - Intensity: 1.0
  - Size: 24.0
  - Threshold: 0.8
  - *Purpose:* Enhances the glow of bioluminescent fish and plants without blowing out the highlights.

## Zone-Specific Configurations

### 1. Sunlight Zone (0m - 200m)
*Theme: Vibrant, Tropical, Safe*
- **Fog Color:** #3B82F6 (Electric Blue)
- **Fog Range:** Start 10, End 600
- **Ambient Light:** 0.8 (High)
- **Color Correction:**
  - Contrast: +0.1
  - Saturation: +0.2
  - Tint: Pure White
- **Visual Goal:** High visibility, "vacation" feel to contrast with later zones.

### 2. Twilight Zone (200m - 1000m)
*Theme: Cooling, Mysterious, Fading*
- **Fog Color:** #060A1A (Deep Ocean)
- **Fog Range:** Start 0, End 350
- **Ambient Light:** 0.2 (Low)
- **Color Correction:**
  - Brightness: -0.1
  - Contrast: +0.2
  - Saturation: -0.1
  - Tint: #C8DCFF (Light Blue-Ice)
- **Visual Goal:** Visibility begins to drop; colors start to wash out into blues.

### 3. Midnight Zone (1000m - 4000m)
*Theme: Oppressive, Bio-Dependent*
- **Fog Color:** #040610 (Near Black)
- **Fog Range:** Start 0, End 150
- **Ambient Light:** 0.05
- **Color Correction:**
  - Brightness: -0.2
  - Contrast: +0.4
  - Saturation: -0.3
  - Tint: #96B4FF (Muted Blue)
- **Visual Goal:** The player is forced to rely on their own lights and bioluminescence.

### 4. Abyssal Zone (4000m - 6000m)
*Theme: Crushing, Ancient, Dark*
- **Fog Color:** #020308
- **Fog Range:** Start 0, End 80
- **Ambient Light:** 0.01
- **Color Correction:**
  - Brightness: -0.3
  - Contrast: +0.6
  - Saturation: -0.5
  - Tint: #6482FF (Deep Blue)
- **Visual Goal:** Extreme darkness. The fog is very tight, creating a sense of claustrophobia.

### 5. The Trenches (6000m+)
*Theme: Void, The Unknown*
- **Fog Color:** #000000 (Pure Black)
- **Fog Range:** Start 0, End 40
- **Ambient Light:** 0 (None)
- **Color Correction:**
  - Brightness: -0.5
  - Contrast: +0.8
  - Saturation: -0.8
  - Tint: #5064FF (Void Blue)
- **Visual Goal:** Absolute void. Only neon/light sources are visible.

## Post-Processing Utility: VFXUtil
To support these settings, the `VFXUtil` module has been provided to the team. It ensures all bioluminescent assets (Creatures/Flora) use the correct neon materials and point lights that interact with the `Future` lighting engine.

- **Predefined Palette:** CyanGlow (#00E5FF), BioGreen (#39FF14), DeepPurple (#8B5CF6).
- **Behavior:** Includes "Pulse" and "Breathing" effects to make the deep sea feel "alive."
