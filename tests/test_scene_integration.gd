extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	# The floor is an imported repeating tile so Android does not rely on a large runtime-generated texture.
	var background: Node = main.get_node("World/ArenaBackground")
	if not _check(background.floor_texture != null, "The imported arena floor tile must initialize."):
		return
	if not _check(background.floor_texture.get_size() == Vector2(96.0, 72.0), "The imported floor tile must have the expected 96x72 dimensions."):
		return
	var props_texture: Texture2D = load("res://assets/art/arena_props_atlas.png")
	if not _check(props_texture != null and props_texture.get_size() == Vector2(256.0, 64.0), "The generated environment prop atlas must import at 256x64."):
		return
	if not _check(is_instance_valid(main.combat_fx), "The shared combat feedback manager must exist."):
		return
	if not _check(main.combat_fx._sounds.size() >= 11, "Procedural audio bank must include the healing sound as well as combat sounds."):
		return
	for sound_name in ["swing", "hit", "dash", "slam", "ice", "lightning", "ultimate", "death", "pickup", "heal"]:
		var stream: AudioStreamWAV = main.combat_fx._sounds.get(sound_name)
		if not _check(stream != null and stream.data.size() > 100, "Audio effect %s must contain generated PCM data." % sound_name):
			return
	main.combat_fx.add_slash(Vector2(100.0, 100.0), Vector2.RIGHT)
	if not _check(main.combat_fx._effects.size() == 1, "Visual combat effects should be batched in the shared manager."):
		return
	main.combat_fx.clear_effects()
	if not _check(main.combat_fx._effects.is_empty(), "Starting a new run must clear leftover combat effects."):
		return

	main._start_run()
	main.spawn_timer = 1000.0
	await process_frame
	if not _check(main.mode == "playing", "A run should start in playing mode."):
		return
	if not _check(is_instance_valid(main.player), "A player should be created at run start."):
		return
	if not _check(main.player.is_visible_in_tree(), "The player node must be visible in the scene tree."):
		return
	if not _check(is_equal_approx(main.player.health, main.player.max_health), "Player health should start full."):
		return
	if not _check(is_equal_approx(main.player.energy, 100.0), "Player energy should start full."):
		return
	var start_stats: Dictionary = main._status()
	if not _check(float(start_stats.get("health", 0.0)) > 0.0, "The initial HUD must receive positive health."):
		return
	if not _check(is_equal_approx(float(start_stats.get("energy", 0.0)), 100.0), "The initial HUD must receive full energy."):
		return
	var obstacle_count := 0
	for actor in main.actors.get_children():
		if actor.is_in_group("arena_obstacle"):
			obstacle_count += 1
			if not _check(actor is StaticBody2D, "Every wood obstacle must have a physics body."):
				return
			if not _check(int(actor.collision_layer) == 4, "Wood obstacles must use the obstacle collision layer."):
				return
			if not _check(actor.get_child_count() > 0 and actor.get_child(0) is CollisionShape2D, "Wood obstacles must have an actual collision shape."):
				return
	if not _check(obstacle_count >= 12, "The expanded arena should contain at least twelve wooden barricades."):
		return
	var camera_count := 0
	for child in main.player.get_children():
		if child is Camera2D:
			camera_count += 1
	if not _check(camera_count == 1, "The player must own one follow camera for the larger world."):
		return
	var world_size: Vector2 = start_stats.get("world_size", Vector2.ZERO)
	if not _check(world_size.x >= 2200.0 and world_size.y >= 1400.0, "The map must be materially larger than the viewport."):
		return
	var bounds: Rect2 = main._player_bounds()
	if not _check(bounds.position == Vector2(18.0, 18.0), "The player must not be clamped one viewport-width away from the real map border."):
		return
	if not _check(bounds.size == world_size - Vector2(36.0, 36.0), "The movement bounds must reach almost to the actual world edge."):
		return
	var brute_test: CharacterBody2D = _make_enemy(main.player.position + Vector2(100.0, 0.0))
	brute_test.configure_kind("brute", 0.5)
	var hexer_test: CharacterBody2D = _make_enemy(main.player.position + Vector2(120.0, 0.0))
	hexer_test.configure_kind("hexer", 0.5)
	if not _check(brute_test.max_health > hexer_test.max_health, "The brute should be much tougher than the ranged hexer."):
		return
	if not _check(hexer_test.attack_range >= 120.0, "The hexer must have a distinct ranged engagement distance."):
		return
	if not _check(brute_test.attack_damage > hexer_test.attack_damage, "The brute must threaten the player with stronger attacks."):
		return
	brute_test.free()
	hexer_test.free()

	# Healing should be a deliberate, cooldown-bound decision, not an automatic free refill.
	main.player.energy = 100.0
	main.player.health = main.player.max_health
	main._on_heal_pressed()
	if not _check(main.heal_cooldown_left == 0.0, "Healing at full health must not start cooldown."):
		return
	if not _check(is_equal_approx(main.player.energy, 100.0), "Healing at full health must not waste energy."):
		return
	main.player.health = 50.0
	main._on_heal_pressed()
	if not _check(is_equal_approx(main.player.health, 82.0), "Healing should restore 32 health up to the maximum."):
		return
	if not _check(is_equal_approx(main.player.energy, 70.0), "Healing should consume 30 energy."):
		return
	if not _check(is_equal_approx(main.heal_cooldown_left, 18.0), "Healing should start an 18-second cooldown."):
		return
	if not _check(main.combat_fx._sounds.has("heal"), "Healing must have a dedicated sound effect."):
		return
	if not _check(main.combat_fx._effects.size() > 0 and String(main.combat_fx._effects.back()["kind"]) == "heal", "Healing must create a visible healing effect."):
		return
	main.player.health = main.player.max_health
	main.player.energy = 100.0
	main.heal_cooldown_left = 0.0


	# New spells should not spend energy or start cooldown when there is no valid target.
	main._on_ice_pressed()
	if not _check(is_equal_approx(main.player.energy, 100.0), "Ice should not consume energy without a nearby enemy."):
		return
	if not _check(main.ice_cooldown_left == 0.0, "Ice should not start cooldown without a nearby enemy."):
		return
	main._on_lightning_pressed()
	if not _check(is_equal_approx(main.player.energy, 100.0), "Lightning should not consume energy without a target."):
		return
	if not _check(main.lightning_cooldown_left == 0.0, "Lightning should not start cooldown without a target."):
		return

	# An unaffordable skill must not silently consume resources or start cooldown.
	main.player.energy = 10.0
	main._on_skill_pressed()
	if not _check(is_equal_approx(main.player.energy, 10.0), "An unaffordable skill must not consume energy."):
		return
	if not _check(main.skill_cooldown_left == 0.0, "An unaffordable skill must not enter cooldown."):
		return

	main.player.energy = 100.0
	main._on_skill_pressed()
	if not _check(is_equal_approx(main.player.energy, 68.0), "Phá Trận must consume 32 energy."):
		return
	if not _check(main.skill_cooldown_left > 0.0, "Phá Trận must enter cooldown after use."):
		return
	main.player.energy = 100.0

	# The ultimate can only fire at full energy and spends the full bar.
	main.player.energy = 99.0
	main._on_ultimate_pressed()
	if not _check(is_equal_approx(main.player.energy, 99.0), "An unavailable ultimate must preserve current energy."):
		return
	main.player.energy = 100.0
	main._on_ultimate_pressed()
	if not _check(is_equal_approx(main.player.energy, 0.0), "The ultimate must consume all 100 energy."):
		return
	if not _check(main.player.invulnerability_left > 0.0, "The ultimate should grant a brief defensive window."):
		return
	main.player.energy = 100.0

	# No target must mean no projectile and no shot cooldown.
	var initial_child_count: int = main.actors.get_child_count()
	main._on_shoot_pressed()
	if not _check(main.actors.get_child_count() == initial_child_count, "Shooting with no target must not create a projectile."):
		return
	if not _check(main.shot_cooldown_left == 0.0, "No-target input must not start shot cooldown."):
		return
	if not _check(main.message.contains("MỤC TIÊU"), "The player should receive Vietnamese no-target feedback."):
		return

	# Melee marks a valid nearby enemy; a ranged hit should consume the mark and resolve the combo.
	var marked_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(42.0, 0.0))
	main.actors.add_child(marked_enemy)
	main.enemies.append(marked_enemy)
	var original_health: float = marked_enemy.health
	main._on_melee_pressed()
	if not _check(marked_enemy.marked_time > 0.0, "Melee should apply the sword mark."):
		return
	if not _check(is_equal_approx(marked_enemy.health, original_health - main.melee_damage), "Melee should apply its base damage."):
		return
	main._on_shoot_pressed()
	await create_timer(0.35).timeout
	if not _check(main.kills == 1, "A projectile hitting a marked target should resolve the combo and defeat this test enemy."):
		return
	if not _check(not is_instance_valid(marked_enemy) or marked_enemy.marked_time <= 0.0, "A successful combo must consume the mark."):
		return

	# Dodge during a nearby enemy telegraph should interrupt one strike and cause one counterattack.
	var counter_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(54.0, 0.0))
	main.actors.add_child(counter_enemy)
	main.enemies.append(counter_enemy)
	counter_enemy.windup_left = 0.30
	var counter_health: float = counter_enemy.health
	main._on_dodge_pressed()
	if not _check(counter_enemy.windup_left == 0.0, "Perfect dodge should cancel the telegraphed strike."):
		return
	if not _check(is_equal_approx(counter_enemy.health, counter_health - main.counter_damage), "Perfect dodge should apply exactly one counter hit."):
		return
	if not _check(main.player.dodge_cooldown_left > 0.0, "Dodge should enter cooldown."):
		return
	if not _check(main.player.energy > 0.0, "A perfect dodge should restore energy."):
		return

	# Ice applies a temporary slow as well as damage.
	main.player.energy = 100.0
	var ice_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(74.0, 10.0))
	main.actors.add_child(ice_enemy)
	main.enemies.append(ice_enemy)
	main._on_ice_pressed()
	if not _check(ice_enemy.slow_left > 2.0, "Ice must apply a multi-second slow."):
		return
	if not _check(main.ice_cooldown_left > 0.0, "Ice must start cooldown after a successful cast."):
		return
	if not _check(main.player.energy < 100.0, "Ice must consume energy when it hits a target."):
		return
	main.enemies.erase(ice_enemy)
	ice_enemy.queue_free()
	main.player.energy = 100.0

	# Chain lightning should hit several distinct enemies and spend energy once.
	var chain_test_enemies: Array = []
	for chain_index in range(4):
		var chain_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(82.0 + chain_index * 31.0, float(chain_index % 2) * 22.0))
		main.actors.add_child(chain_enemy)
		main.enemies.append(chain_enemy)
		chain_test_enemies.append(chain_enemy)
	main._on_lightning_pressed()
	if not _check(main.lightning_cooldown_left > 0.0, "Lightning must start cooldown after finding targets."):
		return
	if not _check(main.message.contains("4 MỤC TIÊU"), "Lightning should chain to four separate targets."):
		return
	if not _check(main.player.energy < 100.0, "Lightning should consume energy once when cast."):
		return
	for chain_enemy in chain_test_enemies:
		if is_instance_valid(chain_enemy):
			main.enemies.erase(chain_enemy)
			chain_enemy.queue_free()

	# Make two enemy rewards cross the deliberately slower level-up threshold.
	main.xp = main.xp_to_next_level - 2
	var first_upgrade_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(80.0, 0.0))
	main.actors.add_child(first_upgrade_enemy)
	main.enemies.append(first_upgrade_enemy)
	main._enemy_defeated(first_upgrade_enemy)
	var second_upgrade_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(100.0, 0.0))
	main.actors.add_child(second_upgrade_enemy)
	main.enemies.append(second_upgrade_enemy)
	main._enemy_defeated(second_upgrade_enemy)
	if not _check(main.mode == "upgrade", "Reaching the XP threshold should open the upgrade state."):
		return
	if not _check(paused, "The tree should pause during upgrade selection."):
		return
	var old_melee_damage: float = main.melee_damage
	main._on_upgrade_selected(0)
	if not _check(main.mode == "playing" and not paused, "Picking an upgrade should resume the game."):
		return
	if not _check(is_equal_approx(main.melee_damage, old_melee_damage + 5.0), "Only the chosen upgrade effect should be applied."):
		return

	# Rewards must be paid at most once even if finish is called again.
	var crystals_before: int = main.crystals
	main._finish_run(true)
	if not _check(main.mode == "won" and main.run_reward_claimed, "A completed run should enter win state and claim its reward."):
		return
	var crystals_after_first_finish: int = main.crystals
	if not _check(crystals_after_first_finish == crystals_before + main.run_reward, "First finish should pay the stated reward."):
		return
	main._finish_run(false)
	if not _check(main.crystals == crystals_after_first_finish, "Repeated finish must not duplicate the reward."):
		return
	if not _check(main.mode == "won", "The first terminal result must remain authoritative."):
		return

	print("PASS: scene integration tests")
	paused = false
	main.queue_free()
	await process_frame
	quit(0)


func _check(condition: bool, description: String) -> bool:
	if condition:
		return true
	push_error("FAIL: " + description)
	paused = false
	quit(1)
	return false


func _make_enemy(at_position: Vector2) -> CharacterBody2D:
	var enemy := CharacterBody2D.new()
	enemy.set_script(ENEMY_SCRIPT)
	enemy.position = at_position
	enemy.collision_layer = 2
	enemy.collision_mask = 3
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	collider.shape = circle
	enemy.add_child(collider)
	return enemy
