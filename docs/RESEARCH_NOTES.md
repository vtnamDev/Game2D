# Research notes — techniques reviewed for Game2D

This document records the principles used, what was adopted, and what was intentionally not copied. Source code and art from these repositories are not treated as a free-for-all.

## 1. Official Godot 2D demo projects

Source: https://github.com/godotengine/godot-demo-projects  
Example: https://github.com/godotengine/godot-demo-projects/tree/master/2d/dodge_the_creeps  
Tutorial: https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html

Useful lessons:
- Start with a small, complete gameplay loop instead of creating many systems at once.
- Keep gameplay entities and the main scene explicit.
- Use the Compatibility renderer as a reasonable first option for a constrained mobile target, then measure on the real phone.
- The official repository is MIT-licensed, but its README notes that some individual art/audio/font assets have separate licenses. This project does not copy those assets or scripts.

Applied here: a compact arena, simple actor scenes/scripts, placeholders, and acceptance gates before art polish.

## 2. Godot movement and mobile input documentation

Sources:
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html
- https://docs.godotengine.org/en/latest/tutorials/physics/using_character_body_2d.html
- https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html

Useful lessons:
- Use CharacterBody2D movement in the physics update and move_and_slide for actor movement/collision response.
- Mobile touch has separate screen-touch and screen-drag events; don't assume mouse input alone is enough.
- Treat the touch area, world, and UI as distinct layers; ensure the interface is legible and input paths are explicit.

Applied here: CharacterBody2D actors with circle shapes, a fixed left joystick zone, dead zone, independent touch-pointer ID, and action buttons separated from movement input.

## 3. Open-source touch joystick example

Source: https://github.com/abdulroufsidhu/godot_touch_screen_joystick

The repository describes a Godot 4 GDScript touch joystick, touch/mouse handling, dead zone, configurable radius, and multi-touch support. Its metadata/README state the project uses the MIT license.

Used only as a design reference for the concepts above. Its plugin, code, scenes, and assets were not copied into this project; the prototype has its own minimal control implementation so it has no add-on dependency.

## 4. Godot mobile controls and CI project

Source: https://github.com/XFFF0/UrukDrive

The public project description demonstrates a Godot prototype with touch controls and a GitHub Actions build workflow. It is a 3D iOS project, so it is not a direct technical template for this Android 2D game. No code or assets are copied; its workflow merely reinforces the separation between source changes and an automated build artifact. No compatible license was confirmed here, so none of its implementation is reused.

## 5. Android export documentation

Sources:
- https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html
- https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html

Key constraints:
- A project running in the editor does not prove an Android package can be exported or installed.
- Android export architecture settings include armeabi-v7a and arm64-v8a; the final package must be checked rather than inferred.
- The Godot Android editor can export using its supported templates; Gradle builds have additional tooling requirements, including Godot Android Build Environment on the Android-editor path from Godot 4.6 onward.

Applied here: the initial workflow tests project import and the gameplay rules only. APK export is a later gate and is not represented as completed.

## 6. What remains to learn empirically

External tutorials cannot determine this phone's actual frame rate, heat, battery drain, touch latency, save behavior after process death, or export-template availability. Those require tests on the vivo V2120. The ten-minute performance test and repeated-run test are explicit tasks, not claims.
