# Game2D — v0.1 development plan and acceptance contract

**Status:** specification locked; first implementation branch created; runtime and device acceptance are still pending.

## 1. Confirmed decisions

- Engine: Godot 4.7.2 Stable.
- Script: GDScript only. No C#/.NET.
- Game: 2D top-down fantasy arena survival, pixel-art direction, placeholder art first.
- Target device: vivo V2120, Android 12. This is the only device included in v0.1 acceptance.
- Orientation: landscape.
- Controls: virtual joystick on the left; melee, ranged, and dodge buttons on the right.
- Ranged targeting: on each shot press, choose the nearest alive enemy within range. If none is valid, do not create a projectile.
- Signature mechanic A+B: melee marks an enemy; a ranged hit on a marked enemy triggers an elemental combo. Dodging during an enemy attack telegraph can interrupt it and trigger a counterattack.
- A run lasts 300 seconds. Survive through 300 seconds to win; health reaching zero first means loss.
- Level-up pauses the simulation and presents three upgrades; exactly one is applied.
- Runs award local crystals; a permanent unlock can be purchased using crystals.
- No mandatory Internet, login, server, ads, or in-app purchases in v0.1.
- Project first; APK only after the toolchain and project are verified.
- GitHub Actions/cloud build may be used. No desktop PC, root, or native plugin is assumed.

## 2. Assumptions for the first prototype

These are changeable implementation defaults, not separate user-approved design commitments:

- One playable character, one basic enemy type, one compact arena.
- One elemental mark and one combo reaction.
- A marked enemy takes normal projectile damage plus a fixed combo bonus.
- Enemy attacks use a visible wind-up ring so timing is learnable on a touchscreen.
- Temporary custom-drawn shapes are used instead of artwork until control feel and combat logic work.
- Initial numerical settings (attack range, mark duration, dodge window, enemy speed/health, spawn interval, combo damage) are tuning variables. They must be checked on device and may change.
- A small local save records crystals and the permanent Counter Relic unlock.

## 3. Implemented candidate behavior on the prototype branch

The code on prototype/m1-combat intends to include:

1. Menu and start/restart flow.
2. Landscape arena drawn with simple shapes.
3. CharacterBody2D player/enemies with circular collision shapes.
4. Touch joystick with dead zone and multi-pointer input, plus three action buttons.
5. Melee damage and an Ember Mark.
6. One target-seeking projectile per valid shoot action, using the nearest valid target.
7. No projectile and no shot cooldown when no valid target exists.
8. Projectile hit on a marked enemy consumes the mark and adds combo damage.
9. Enemy telegraph, dodge invulnerability, and counterattack on a dodge during a nearby telegraph.
10. XP, a level-up screen with three choices, and paused combat until selection.
11. 300-second win / zero-health loss and once-per-run crystal rewards.
12. Local save for crystals and a permanent Counter Relic unlock.
13. Isolated tests for nearest target, out-of-range target rejection, dead-target rejection, combo damage, and run reward calculations.
14. A GitHub Actions workflow intended to run Godot headlessly on the project and isolated tests.

This is a source/code claim, not a test result. Each item still requires runtime validation.

## 4. Acceptance gates

### Gate A — source integrity and project import
- project.godot and the main scene exist at the repository root/declared path.
- All script and scene references resolve.
- Godot 4.7.2 headless import and main-scene startup pass.
- Combat-rule tests pass.
- No engine output with a script parser error or missing resource.

### Gate B — controls and combat on vivo V2120
- Landscape layout remains usable on the actual screen.
- Joystick returns to neutral on release; simultaneous joystick and button input works.
- Melee only hits in range and applies a mark.
- The nearest living target in range is chosen; no valid target means no shot.
- Marked projectile hit consumes the mark and applies bonus damage exactly once.
- Dodge outside a telegraph is a normal dodge. Dodge during a nearby telegraph cancels the attack and applies one counter.
- Pause and upgrade selection genuinely pause the simulation.
- No controls overlap each other or the gameplay-critical UI.

### Gate C — complete run and persistent progression
- A run starts at 300 seconds and can end in either win or loss.
- The level-up screen offers three choices, applies one, then resumes the run.
- Rewards are issued at most once per run.
- The crystal count and Counter Relic unlock survive application restart.
- Restart resets run state but retains permanent progression.
- Offline play works.

### Gate D — stability and performance
- Run ten manual attempts with no crash or progression-blocking issue.
- Complete one ten-minute session without unexplained memory growth or severe thermal/stutter symptoms.
- FPS and frame-time behavior are measured both in a quiet arena and at maximum tested enemy load.
- Initial target: 60 FPS when lightly loaded; under stress, keep the game playable and aim for at least 30 FPS. These are targets to measure, not guarantees.
- Record device temperature, battery level, memory, enemy count, renderer, and resolution with the measurements.
- No arbitrary APK size or latency threshold is claimed until measured.

### Gate E — Android export
- Confirm export templates and Android export behavior for the installed Godot 4.7.2 editor.
- If cloud building is needed, confirm the job uses a compatible official engine/template and correct Android ABI configuration.
- Install and launch a real generated APK on vivo V2120.
- Verify ARMv7/armeabi-v7a compatibility from the actual artifact; do not infer it from the Android editor APK's ABI.
- Save the export log, APK metadata, commit SHA, install result, and smoke-test result.

## 5. Sequence and stop conditions

1. Review this branch and run the automated Godot checks.
2. Fix every parser/import/runtime issue before adding more features.
3. Import the branch into Godot Android and test controls and A+B in a short session.
4. Fix the combat feel and touch layout before balancing five-minute difficulty.
5. Run the complete-loop tests, save/reload tests, and ten attempts.
6. Measure performance; lower enemy cap/effects if necessary.
7. Only then validate the APK export pipeline.
8. Add original/AI/licensed artwork and audio after the gray-box experience passes.

Stop feature work if an error prevents starting or finishing a run. Do not mask a failed test by editing the checklist to "pass"; save the error and fix the underlying cause.

## 6. Known risks

- The user has confirmed Godot 4.7.2 opens and runs a project on the phone, but that does not prove the prototype imports, feels right, or exports an APK.
- Android editor and APK export are separate workflows. The export templates and ABI must be verified independently.
- The target device's measured FPS, available memory under load, thermals, input latency, and APK export capability are unknown.
- A telegraph-based perfect dodge may be too easy or too difficult; the window and distance must be tuned by playtesting.
- The first build uses a deliberately small enemy set. Multiple enemy archetypes, maps, deep skill trees, audio polish, and store release are not first-gate requirements.
