# Game2D v0.1 acceptance checklist

**Device validation status:** pending. Headless CI passed for gameplay-code commit \`537c8e8\`; that result does not count as testing the phone. Do not mark a device test passed until the named action was performed and its evidence recorded.

Record for every session:
- Git commit SHA:
- Godot version:
- Device and Android version:
- Render method / viewport:
- Test ID:
- Expected result:
- Actual result:
- Pass / Fail / Blocked:
- Evidence or log:

## A. Project import and startup

- [ ] A-01: Import the project root in Godot 4.7.2; no missing resources.
- [ ] A-02: Main scene starts without parser errors.
- [ ] A-03: Menu renders in landscape and start control can be tapped.
- [ ] A-04: Pause and restart controls remain within the screen safe area.
- [ ] A-05: Keyboard smoke-test controls operate in desktop/headless-capable test mode.

## B. Touch input

- [ ] B-01: Joystick moves in four cardinal and diagonal directions.
- [ ] B-02: Releasing the joystick returns movement to zero.
- [ ] B-03: Joystick and one action button can be used simultaneously with two touch points.
- [ ] B-04: Taps on action buttons do not accidentally move the character.
- [ ] B-05: The joystick dead zone prevents visible drift.
- [ ] B-06: Buttons remain large enough and readable on vivo V2120.

## C. Combat and signature mechanic

- [ ] C-01: Melee outside range causes no damage/mark.
- [ ] C-02: Melee inside range damages a living target and applies Ember Mark.
- [ ] C-03: Shoot selects the nearest living target inside range.
- [ ] C-04: If there is no valid target, no projectile appears and no shot resource is consumed.
- [ ] C-05: Projectile hit on an unmarked target applies base ranged damage only.
- [ ] C-06: Projectile hit on a marked target applies base damage plus combo bonus once, then consumes the mark.
- [ ] C-07: Dead targets are ignored during target selection and projectile travel.
- [ ] C-08: Enemy telegraph is visually distinguishable before its strike.
- [ ] C-09: Normal dodge avoids eligible damage during its invulnerability window.
- [ ] C-10: Dodge during a nearby telegraph cancels that attack and produces exactly one counterattack.
- [ ] C-11: Dodge on cooldown is rejected without a second counterattack.
- [ ] C-12: Repeated melee/shoot/dodge taps do not create duplicate kills or rewards.

## D. XP, timer and progression

- [ ] D-01: Each enemy defeat grants one XP.
- [ ] D-02: Level-up shows three upgrade choices.
- [ ] D-03: Timer, enemy movement, projectiles and attacks pause while upgrade selection is open.
- [ ] D-04: Selecting an upgrade applies exactly one effect and resumes the run.
- [ ] D-05: Reaching 300 seconds results in win.
- [ ] D-06: Health reaching zero before 300 seconds results in loss.
- [ ] D-07: Win and loss screens cannot both be reached for the same run.
- [ ] D-08: Repeated input cannot issue the run reward twice.
- [ ] D-09: Counter Relic purchase checks funds, charges once and remains unlocked after restart.
- [ ] D-10: Restart resets run timer, health, XP, kills, temporary upgrades and enemies.

## E. Offline save and lifecycle

- [ ] E-01: A run can be played in airplane mode.
- [ ] E-02: Saved crystals persist after closing and relaunching the app.
- [ ] E-03: Counter Relic unlock persists after closing and relaunching the app.
- [ ] E-04: App background/resume does not freeze input or duplicate timer/rewards.
- [ ] E-05: Save-file write errors are visible in the log rather than silently claimed successful.

## F. Performance

- [ ] F-01: Record FPS in an empty arena.
- [ ] F-02: Record FPS at 10, 20 and maximum active enemies.
- [ ] F-03: Record frame-time spikes during melee combo and simultaneous telegraphs.
- [ ] F-04: Run a ten-minute session and record memory before, during and after.
- [ ] F-05: Record phone temperature and battery level before and after a comparable session.
- [ ] F-06: Repeat ten runs; record crashes, freezes, reward/save issues and worst stutter.

Provisional targets: aim at 60 FPS in light load and at least 30 FPS during stress. These are targets, not current measurements.

## G. Android export — separate from editor testing

- [ ] G-01: Install/verify export templates matching Godot 4.7.2.
- [ ] G-02: Export a debug APK through the supported path.
- [ ] G-03: Inspect package ABI; verify ARMv7/armeabi-v7a if it is the required build.
- [ ] G-04: Install and launch the actual APK on vivo V2120.
- [ ] G-05: Run B, C, D and E checks against the APK, not only the editor.
- [ ] G-06: Attach export log, artifact metadata, commit SHA, install result and smoke-test result.

## Automated checks

The GitHub Actions workflow uses the official Godot 4.7.2 Linux editor and performs:
1. Headless project import/parse, with log scanning for parser/runtime errors.
2. Combat-rule tests.
3. Scene integration tests for no-target shooting, melee mark + ranged combo, perfect-dodge counter, level-up pause/resume and one-time rewards.
4. Brief main-scene startup smoke test.

CI cannot test physical touch input, heat, battery, frame pacing on vivo V2120, persistence after a real phone process kill, nor prove that a real Android APK installs.
