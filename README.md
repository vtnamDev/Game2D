# Game2D — Ember & Counter

A small Godot 4.7.2, GDScript-only 2D arena-survival prototype for Android-first development.

## Current truth

- The confirmed target is **landscape mode** on a vivo V2120 running Android 12.
- The current implementation work is isolated on branch **prototype/m1-combat**.
- The branch contains a first combat vertical slice: touch controls, enemy telegraphing, melee marks, target-seeking ranged shots, dodge counters, level-up choices, a five-minute timer, local crystals, and a permanent counter relic.
- It uses custom-drawn placeholder shapes. No third-party art or audio is bundled.
- **It is not yet accepted as working on the target phone.** The code still needs the Godot 4.7.2 CI run, editor/runtime inspection, and manual phone testing.
- **No tested APK is provided or claimed.** Importing a project and exporting an Android APK are separate steps.

## Run in Godot

1. Open this repository or download its ZIP.
2. In Godot 4.7.2, import the folder containing project.godot.
3. Run the main scene.
4. Desktop controls for a quick smoke test: arrow keys move, Space melee, F shoot, Shift dodge, Esc pause.
5. On a touchscreen, use the left virtual joystick and the three action buttons on the right.

The current prototype uses the Compatibility renderer and a 960 × 540 landscape logical viewport. Final device scaling, frame pacing, heat, and battery use still need measurement on the vivo V2120.

## Test logic

With Godot 4.7.2 installed, run:

    godot --headless --path . --editor --quit
    godot --headless --path . --script res://tests/test_combat_rules.gd
    godot --headless --path . --quit-after 5

These checks cover project import/parser errors, isolated combat-rule assertions, and a brief main-scene startup. They do not replace touch testing or a complete five-minute game run on the phone.

## Development rules

- Do not copy assets or gameplay code without a compatible license.
- Keep GDScript and built-in Godot nodes; no .NET, root, native plugins, account, server, ads, or purchases are required.
- Keep placeholder art until gameplay is validated.
- Never mark a criterion as passed without an observed test result.
- Record Godot/Android version, commit, logs, frame-rate conditions, and test outcome.

See PLAN.md, docs/RESEARCH_NOTES.md, and docs/TEST_CHECKLIST.md for decisions, sources, risks, and acceptance steps.
