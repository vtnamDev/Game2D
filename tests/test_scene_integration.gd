extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_run()
	main.spawn_timer = 1000.0
	await process_frame
	if not _check(main.mode == "playing", "A run should start in playing mode."):
		return
	if not _check(is_instance_valid(main.player), "A player should be created at run start."):
		return

	# No target must mean no projectile and no shot cooldown.
	var initial_child_count: int = main.actors.get_child_count()
	main._on_shoot_pressed()
	if not _check(main.actors.get_child_count() == initial_child_count, "Shooting with no target must not create a projectile."):
		return
	if not _check(main.shot_cooldown_left == 0.0, "No-target input must not start shot cooldown."):
		return
	if not _check(main.message.contains("No valid target"), "The player should receive no-target feedback."):
		return

	# Melee marks a valid nearby enemy; a ranged hit should consume the mark and resolve the combo.
	var marked_enemy: CharacterBody2D = _make_enemy(main.player.position + Vector2(42.0, 0.0))
	main.actors.add_child(marked_enemy)
	main.enemies.append(marked_enemy)
	var original_health: float = marked_enemy.health
	main._on_melee_pressed()
	if not _check(marked_enemy.marked_time > 0.0, "Melee should apply the Ember Mark."):
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

	# Trigger level-up and verify the choice pauses/resumes the game and applies one upgrade.
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
