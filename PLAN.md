# Game2D — Pixel Survival (MVP Plan)

> Status: planning only. This document is the agreed starting plan, not a claim that the game has already been implemented or tested.
>
> Working assumption: “fixes 2D” means a **pixel-art 2D game**. To keep the first release achievable on Android ARMv7/32-bit, the proposed MVP is a top-down arena-survival game. The title and genre can still be changed before implementation.

## 1. Goal

Create a small but polished, original 2D mobile game with Godot, editable on Android, stored in this GitHub repository, and designed for a low-end 32-bit Android target. Keep the first version offline and avoid paid services, accounts, networking, native plugins, and complex build dependencies.

Target workflow:
1. ChatGPT prepares and reviews project files.
2. Commit the source to this repository.
3. Download the repository ZIP on the phone.
4. Extract it and import the folder containing `project.godot` into Godot Android.
5. Run the project in the editor and test it on the device.
6. Only after the game passes testing, attempt APK export and verify installation.

## 2. Proposed game concept

**Working title:** Pixel Survival: Last Stand  
**Genre:** Portrait, top-down, wave-based arena survival  
**Art direction:** Original pixel art with a limited palette, readable silhouettes, layered backgrounds, punchy hit effects, and clear UI. Do not copy Free Fire characters, logos, skins, music, or other protected assets.

### Core gameplay loop
- The player moves around a compact arena using a virtual touch joystick.
- The character automatically targets the nearest enemy and fires, reducing the number of simultaneous touch actions.
- Enemies spawn in waves and pursue the player.
- Defeated enemies drop experience. Leveling up pauses the action and offers one of three upgrades.
- Survive for a short run (initial target: 5 minutes), then show score, time survived, and a restart button.
- Store best score and basic settings locally.

### MVP scope
- Main menu with Play, Settings, and Exit.
- One arena and one playable character.
- Three enemy variants with distinct speed/health values.
- One basic weapon, three upgrade types, and a simple level-up selection panel.
- Player health, invulnerability blink after taking damage, score, timer, and game-over screen.
- Touch controls, pause/resume, restart, sound/music toggles, and local best-score save.
- Placeholder assets are acceptable while functionality is built; replace them with original pixel-art assets during polish.

### Explicitly out of scope for version 0.1
- Online multiplayer, accounts, cloud saves, chat, large open world, 3D models, gacha, in-app purchases, ads, leaderboards, and third-party native plugins.
- These add complexity and can jeopardize Android ARM32 compatibility. Reconsider monetization only after the core game is stable and fun.

## 3. Technical decisions

- **Engine:** Godot 4.x stable Android editor build; prefer a version that can be installed and opened on the target device.
- **Script:** GDScript only; no C#/.NET.
- **Renderer:** Compatibility / OpenGL ES 3, subject to confirming that the device GPU and driver support it.
- **Target architecture:** Keep the exported Android package compatible with ARMv7/armeabi-v7a. The architecture of the editor APK and the architecture of the exported game are separate checks.
- **Orientation:** Portrait.
- **Reference viewport:** Start at 360 × 640 logical pixels, with a stretch/expand strategy tested against tall phone screens. UI must use anchors and containers instead of hard-coded screen coordinates.
- **Art:** Pixel textures with nearest filtering, sprite sheets/atlases, limited animation frames, no giant uncompressed textures, and original/licensed assets only.
- **Storage:** Local save under `user://`; no personal data collection.
- **Dependencies:** Prefer built-in Godot nodes and GDScript. Do not require C#, Gradle-only Android plugins, GDExtensions, shell permissions, or root.

## 4. Performance budget (targets to validate, not guarantees)

- Aim for stable 60 FPS on the target phone; ensure the game remains playable if performance falls to 30 FPS.
- Start with no more than about 40 active enemies on screen; profile before increasing this.
- Reuse bullets, enemies, XP drops, and hit effects with object pooling when profiling shows node churn.
- Keep physics and AI updates simple; use squared-distance checks where appropriate and avoid expensive work in every frame.
- Use a small number of shared materials and sprite atlases; limit translucent particles and full-screen effects.
- Keep audio assets short and compressed. Set a practical initial download-size target below 50 MB, then measure the real build.
- Measure CPU/GPU load, memory, temperature, frame pacing, and battery drain during a 10-minute session. Reduce effects or entity counts if the phone heats or stutters.

## 5. Repository structure planned

```text
Game2D/
├── project.godot
├── README.md
├── PLAN.md
├── scenes/
│   ├── main.tscn
│   ├── menu.tscn
│   ├── arena.tscn
│   ├── player.tscn
│   ├── enemy.tscn
│   ├── hud.tscn
│   ├── upgrade_picker.tscn
│   └── game_over.tscn
├── scripts/
│   ├── game_manager.gd
│   ├── player.gd
│   ├── enemy.gd
│   ├── spawner.gd
│   ├── weapon.gd
│   ├── upgrade_system.gd
│   ├── touch_joystick.gd
│   └── save_manager.gd
├── assets/
│   ├── sprites/
│   ├── ui/
│   └── audio/
└── docs/
    └── TEST_CHECKLIST.md
```

Do not create empty scene/resource references that make Godot report missing files. Build in small, importable increments.

## 6. Milestones

### M0 — Verify the toolchain
- Install the official Godot Android `arm32` editor build.
- Confirm it opens a blank project, can access Downloads/Documents, and can import a ZIP.
- Verify the device supports the required OpenGL ES version.
- Check available RAM and free storage before adding art.
- Confirm the installed Godot version; do not generate a project configuration blindly for an unknown major/minor version.

**Exit criterion:** a blank project can be created or imported and run.

### M1 — Playable gray-box
- Create `project.godot`, main scene, arena bounds, player movement, enemies, collision, health, and restart.
- Use simple colored shapes before adding art.
- Verify there are no missing scripts, invalid scene paths, parser errors, or crashes.

**Exit criterion:** the player can move, enemies chase and damage the player, and game over/restart work.

### M2 — Core game loop
- Add automatic weapon targeting, enemy waves, XP drops, level-up choices, timer, score, and local save.
- Add pause/resume and touch-friendly UI.
- Test edge cases: no enemies, simultaneous hits, level-up while near death, pause during upgrade, repeated restart.

**Exit criterion:** a complete 5-minute run can start, progress, end, and restart.

### M3 — Pixel-art and polish
- Add a consistent sprite palette, short animation cycles, layered arena, clean HUD, hit feedback, and restrained particles.
- Add sound effects and music with mute controls.
- Check text readability and all UI anchors in different aspect ratios.

**Exit criterion:** the game is visually cohesive without compromising readability or performance.

### M4 — Android performance and compatibility
- Import and run on the actual phone.
- Check frame pacing, memory, heat, audio, touch input, pause/resume after app backgrounding, and storage persistence.
- Remove any dependency that fails in the Android editor.
- Keep a minimal build if the device struggles; do not claim ARMv7 support until the exported APK is verified.

**Exit criterion:** no known blocking issue during repeated test runs; performance target is measured and recorded.

### M5 — Export and release preparation
- Install matching export templates if required and use the export path supported by the installed Android editor version.
- If APK export is unavailable or fails, record the exact error before choosing a cloud-build alternative; do not pretend a GitHub upload itself creates an APK.
- Verify the APK package ABI, install it, launch it, test fresh install/update behaviour, and record the result.
- Prepare app icon, screenshots, privacy disclosure, credits/licenses, version number, and a reproducible release checklist.

**Exit criterion:** a real APK installs and runs on the target phone. Store publishing and monetization are later phases.

## 7. Testing checklist

- [ ] Project imports from GitHub ZIP with `project.godot` at the project root.
- [ ] Main scene opens without missing resources or script errors.
- [ ] Touch movement works on the actual phone.
- [ ] Collision, health, enemy AI, XP, upgrade choices, pause, game over, and restart work.
- [ ] Settings and high score persist after app restart.
- [ ] A 10-minute run does not show unacceptable stutter, overheating, or memory growth.
- [ ] App can resume after being minimized.
- [ ] Exported APK is confirmed compatible with ARMv7/armeabi-v7a and installs on the phone.
- [ ] All art/audio has clear usage rights; repository contains no access tokens or private keys.

## 8. Risks and honest limits

- The Godot Android editor is less comfortable on a small touchscreen than desktop, so project files should remain small and easy to inspect.
- The editor's exact export capabilities depend on the installed Godot version and available templates/tools. Importing a project is not the same as successfully exporting an APK.
- A code review can catch many likely issues, but only running the project in Godot and installing the APK can verify the target-device result.
- Android ARM32 devices vary in GPU drivers, memory, and ABI support. Performance settings must be verified on the actual phone.

## 9. Immediate next actions

1. Confirm the intended meaning of “fixes 2D”; this plan assumes **pixel-art 2D**.
2. Check Godot version, OpenGL ES capability, available RAM, and storage on the phone.
3. Implement M1 first; do not add monetization, large art packs, or complex effects before the playable loop is stable.
