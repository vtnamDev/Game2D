# Game2D — Ember & Counter

A small Godot 4.7.2, GDScript-only 2D arena-survival prototype for Android-first development.

## Current truth

- Confirmed target: landscape mode on a vivo V2120 running Android 12.
- Implementation branch: `prototype/m1-combat`.
- The prototype contains touch controls, enemy telegraphing, melee marks, nearest-target ranged shots, dodge counters, level-up choices, a five-minute run, local crystals and a permanent Counter Relic unlock.
- It uses original custom-drawn placeholder shapes. No third-party art or audio is bundled.
- The latest observed successful headless CI run is [GitHub Actions run 14](https://github.com/vtnamDev/Game2D/actions/runs/39566039133) at code commit \`537c8e8\`. Check Actions again for the status of any later commit.
- Headless Linux checks do not certify Android touch feel, performance, thermals, save lifecycle, or APK installation on the target phone.
- **No tested APK is provided or claimed.** Importing the project, exporting an APK, installing it, and testing it on the phone are separate gates.

## Run in Godot

1. Open this repository or download its ZIP.
2. In Godot 4.7.2, import the folder containing \`project.godot\`.
3. Run the main scene.
4. Desktop quick-check controls: arrow keys move, Space melee, F shoot, Shift dodge, Esc pause.
5. On a touchscreen, use the left virtual joystick and the three action buttons on the right.

The prototype uses the Compatibility renderer and a 960 × 540 landscape logical viewport. Device scaling, frame pacing, heat, battery use and actual multi-touch behavior still need measurement on vivo V2120.

## Run automated checks

These commands require the Godot 4.7.2 command-line executable in a Linux-like shell. The \`timeout\` command bounds the duration of script tests.

\`\`\`sh
godot --headless --editor --path . --quit
timeout 30s godot --headless --path . --script res://tests/test_combat_rules.gd
timeout 30s godot --headless --path . --script res://tests/test_scene_integration.gd
godot --headless --path . --quit-after 5
\`\`\`

The rule tests cover nearest-target selection, range/dead-target rejection, combo damage, and reward calculations. The scene integration test starts the actual main scene and checks no-target shooting, melee mark plus ranged combo, perfect dodge/counter, upgrade pause/resume, and one-time run rewards. The main-scene smoke test catches startup/parser errors.

These checks do **not** replace touch testing or a full five-minute run on the phone.

## Development rules

- Do not copy assets or gameplay code without a compatible license.
- Keep GDScript and built-in Godot nodes; no .NET, root, native plugins, account, server, ads or purchases are required.
- Keep placeholder art until gameplay is validated.
- Never mark a criterion as passed without an observed test result.
- Record Godot/Android version, commit, logs, frame-rate conditions and test outcome.

See \`PLAN.md\`, \`docs/RESEARCH_NOTES.md\`, and \`docs/TEST_CHECKLIST.md\` for decisions, sources, risks and acceptance steps.
