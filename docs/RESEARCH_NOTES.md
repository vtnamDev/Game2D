# Research notes — techniques reviewed for Game2D

This document records the principles used, what was adopted, and what was intentionally not copied. Source code and art from these repositories are not treated as a free-for-all.

## 1. Official Godot 2D demo projects

Sources:
- https://github.com/godotengine/godot-demo-projects
- https://github.com/godotengine/godot-demo-projects/tree/master/2d/dodge_the_creeps
- https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html

The official \`Dodge the Creeps\` example is a compact GDScript project using the Compatibility renderer. The official tutorial progresses through project setup, player, enemies, main scene and HUD. The overall lesson for this project is to get one complete loop working before expanding features.

License note: the demo-project repository's general license is MIT, but individual assets can have separate license terms; its sample README explicitly identifies distinct music, image and font terms. This prototype does not copy its assets or scripts.

Applied here: a small arena, explicit scripts/scenes, placeholder visuals and acceptance gates before art polish.

## 2. Godot movement and mobile input documentation

Sources:
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html
- https://docs.godotengine.org/en/latest/tutorials/physics/using_character_body_2d.html
- https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html

Useful lessons:
- Use \`CharacterBody2D\` movement in the physics update and \`move_and_slide()\` for character movement/collision response.
- Touchscreen handling includes separate screen-touch and screen-drag events; mouse-only input is not enough for a touch-first control path.
- Keep gameplay and HUD input paths explicit, especially when testing joystick and action buttons simultaneously.

Applied here: \`CharacterBody2D\` actors with circular shapes, a left joystick zone, dead zone, independent touch-pointer ID, and action buttons separated from movement input.

## 3. Open-source touch joystick example

Source: https://github.com/abdulroufsidhu/godot_touch_screen_joystick

The public README describes a Godot 4 GDScript joystick with touch/mouse handling, multi-touch support, configurable radius and dead zone, and a CanvasLayer placement suggestion. The repository declares an MIT license.

Used only as a design reference for joystick concepts. Its plugin, code, scenes and assets were not copied; this project has a small in-house control implementation and no add-on dependency.

## 4. Another Godot project with mobile controls and CI

Source: https://github.com/XFFF0/UrukDrive

The public project demonstrates a Godot prototype with touch controls and a GitHub Actions build workflow. It is a 3D iOS project, so it is not a direct technical template for this Android 2D game. No code or assets are copied; its workflow merely reinforces separating source changes from automated validation. No compatible license was confirmed here, so no implementation is reused.

## 5. Android export documentation

Sources:
- https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html
- https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html

Key constraints:
- A project running in the editor does not prove that an Android package can be exported or installed.
- Android export architecture settings include \`armeabi-v7a\` and \`arm64-v8a\`; inspect the final artifact rather than infer its ABI.
- Android export templates must match the Godot editor version. If a custom Gradle build is used, it has additional tooling requirements.

Applied here: the current workflow validates source import, combat rules, scene interactions, and headless startup only. APK export is a separate later gate and is not represented as completed.

## 6. What remains to learn empirically

External tutorials cannot determine this phone's actual frame rate, heat, battery drain, touch latency, save behavior after process death, or whether its installed editor/export templates can make the required APK. Those require testing on vivo V2120. The ten-minute performance test and repeated-run test are explicit tasks, not claims.
