# SkylineOS 2 - Direct Game Booting Guide (Eden / Switch on Pegasus)

## Problem Overview
When launching Switch games (such as *Mario Kart 8 Deluxe*) on Android handhelds like the Retroid Pocket 5, the emulator (Eden) opened to its main game library screen instead of directly executing the game ROM.

### Why This Happened
1. **Duplicate Intent Firing in upstream `theme.qml`**:
   The upstream Pegasus theme code contained a race condition where `launchGame(currentGame)` was executed inside `playGame()` and then a second time inside the state `Transition { to: "playgame" }` via `ScriptAction { script: launchGame(currentGame) }` (~400ms later).
   Receiving two `am start` intents in rapid succession caused Android / Eden to abort the direct `EmulationActivity` startup task and fall back to `MainActivity` (the emulator's ROM browser).

2. **Target Activity Specification**:
   Eden Emulator uses package name `dev.eden.eden_emulator`, but its emulation runner activity is:
   `dev.eden.eden_emulator/org.yuzu.yuzu_emu.activities.EmulationActivity`
   If an intent targets the root package without specifying `EmulationActivity`, Android defaults to `MainActivity`.

---

## What We Fixed in This Theme
1. **Single-Launch Debounce Lock**:
   Added `property bool isLaunching: false` with an automatic 3.5-second reset timer in `theme.qml`. Even if the 'A' button is pressed rapidly or animations trigger multiple transitions, Pegasus executes `game.launch()` strictly once.
2. **Removed Duplicate Trigger**:
   Updated `playGame()` and `playSoftware()` to transition smoothly before executing the launch action.
3. **Non-Pulsing UI Kit Borders**:
   Replaced pulsing animation with bold concentric HighlightBorder and clear gap so cover artwork remains unobstructed.
4. **Solid Enlarged Bottom Dock**:
   Enlarged button bar with solid borderless styling matching the Nintendo Switch 2 UI Kit.

---

## Pegasus Collection Configuration
Ensure your Switch collection in Pegasus has the following launch command:

```pegasus
collection: Nintendo Switch
shortname: switch
extensions: nsp, xci, nsz, xcz
launch: am start -n dev.eden.eden_emulator/org.yuzu.yuzu_emu.activities.EmulationActivity -a android.intent.action.VIEW -d "{file.uri}"
```

A ready-to-use `metadata.pegasus.txt` file is included in this zip archive. You can copy it directly into your Switch ROMs directory!

---

## Retroid Pocket 5 Setup Instructions
1. Download `skylineos2-pegasus-theme.zip`.
2. Extract the archive into your Pegasus themes directory:
   `/storage/emulated/0/pegasus-frontend/themes/skylineOS2/`
3. Launch Pegasus Frontend.
4. Go to **Settings > General > Theme** and select **skylineOS2**.
5. Launch any Nintendo Switch game: it will boot straight into gameplay with no emulator menus!


## Direct Game Launch Commands (Android Pegasus)

Ensure each system's `metadata.pegasus.txt` uses a direct file-launch intent so games open directly instead of stopping at the emulator library:

- **Nintendo Switch (Eden)**:
  `am start -n dev.eden.eden_emulator/org.yuzu.yuzu_emu.activities.EmulationActivity -a android.intent.action.VIEW -d "{file.uri}"`
- **PlayStation 2 (NetherSX2 / AetherSX2)**:
  `am start -n xyz.aethersx2.android/.MainActivity -a android.intent.action.MAIN -e bootPath "{file.path}"`
- **GameCube / Wii (Dolphin)**:
  `am start -n org.dolphinemu.dolphinemu/.ui.main.MainActivity -a android.intent.action.VIEW -e AutoStartFile "{file.path}"`
