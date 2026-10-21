extends Node2D

const CombatRules = preload("res://scripts/combat_rules.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")

const RUN_DURATION := 300.0
const MAX_ENEMIES := 26
const MELEE_RANGE := 68.0
const RANGED_RANGE := 310.0
const MELEE_MARK_DURATION := 3.0
const COMBO_BONUS := 18.0
const RELIC_COST := 20

@onready var actors: Node2D = $World/Actors
@onready var controls: Control = $UI/TouchControls

var mode: String = "menu"
var player: Variant
var enemies: Array = []
var elapsed_seconds: float = 0.0
var spawn_timer: float = 0.8
var melee_cooldown_left: float = 0.0
var shot_cooldown_left: float = 0.0
var xp: int = 0
var xp_to_next_level: int = 3
var kills: int = 0
var crystals: int = 0
var run_reward: int = 0
var run_reward_claimed: bool = false
var counter_relic_unlocked: bool = false
var melee_damage: float = 22.0
var ranged_damage: float = 12.0
var combo_bonus: float = COMBO_BONUS
var counter_damage: float = 18.0
var projectile_range: float = RANGED_RANGE
var message: String = ""
var message_lifetime: float = 0.0
var ui_refresh_left: float = 0.0


func _ready() -> void:
	randomize()
	controls.process_mode = Node.PROCESS_MODE_ALWAYS
	controls.start_requested.connect(_start_run)
	controls.melee_pressed.connect(_on_melee_pressed)
	controls.shoot_pressed.connect(_on_shoot_pressed)
	controls.dodge_pressed.connect(_on_dodge_pressed)
	controls.pause_pressed.connect(_on_pause_pressed)
	controls.resume_requested.connect(_on_resume_pressed)
	controls.restart_requested.connect(_start_run)
	controls.upgrade_selected.connect(_on_upgrade_selected)
	controls.unlock_pressed.connect(_on_unlock_pressed)
	_load_progress()
	_sync_ui()
	queue_redraw()


func _process(delta: float) -> void:
	if message_lifetime > 0.0:
		message_lifetime = maxf(0.0, message_lifetime - delta)
		if message_lifetime <= 0.0:
			message = ""
	ui_refresh_left -= delta
	if ui_refresh_left <= 0.0:
		ui_refresh_left = 0.12
		_sync_ui()


func _physics_process(delta: float) -> void:
	if mode != "playing":
		return

	elapsed_seconds += delta
	if elapsed_seconds >= RUN_DURATION:
		elapsed_seconds = RUN_DURATION
		_finish_run(true)
		return

	if not is_instance_valid(player):
		_finish_run(false)
		return

	melee_cooldown_left = maxf(0.0, melee_cooldown_left - delta)
	shot_cooldown_left = maxf(0.0, shot_cooldown_left - delta)

	var requested_move: Vector2 = controls.move_vector
	var keyboard_move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keyboard_move.length_squared() > 0.02:
		requested_move = keyboard_move
	player.tick(delta, requested_move, _player_bounds())

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		var ramp := clampf(elapsed_seconds / RUN_DURATION, 0.0, 1.0)
		spawn_timer = 1.65 - ramp * 0.60

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var attack_resolved: bool = enemy.tick(delta, player.position)
		if attack_resolved and not player.is_dodging():
			var result: Dictionary = player.receive_damage(10.0)
			if bool(result.get("applied", false)):
				_set_message("Hit taken: -10 HP", 1.0)
				if bool(result.get("dead", false)):
					_finish_run(false)
					return
		if mode != "playing":
			break


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			_on_melee_pressed()
		KEY_F:
			_on_shoot_pressed()
		KEY_SHIFT:
			_on_dodge_pressed()
		KEY_ESCAPE:
			_on_pause_pressed()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.035, 0.055, 0.065), true)
	for x in range(20, int(viewport_size.x), 32):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), viewport_size.y), Color(0.11, 0.15, 0.16, 0.55), 1.0)
	for y in range(18, int(viewport_size.y), 32):
		draw_line(Vector2(0.0, float(y)), Vector2(viewport_size.x, float(y)), Color(0.11, 0.15, 0.16, 0.55), 1.0)
	draw_rect(Rect2(Vector2(18.0, 18.0), Vector2(viewport_size.x - 36.0, viewport_size.y - 36.0)), Color(0.34, 0.49, 0.48, 0.8), false, 2.0)


func _start_run() -> void:
	get_tree().paused = false
	for child in actors.get_children():
		child.free()
	enemies.clear()
	player = null

	elapsed_seconds = 0.0
	spawn_timer = 0.8
	melee_cooldown_left = 0.0
	shot_cooldown_left = 0.0
	xp = 0
	xp_to_next_level = 3
	kills = 0
	run_reward = 0
	run_reward_claimed = false
	melee_damage = 22.0
	ranged_damage = 12.0
	combo_bonus = COMBO_BONUS
	counter_damage = 18.0
	projectile_range = RANGED_RANGE

	player = _new_actor_body(PlayerScript, 1, 2, 12.0)
	actors.add_child(player)
	player.position = get_viewport_rect().size * 0.5
	mode = "playing"
	message = "Mark with MELEE, then SHOOT to detonate."
	message_lifetime = 2.6
	_sync_ui()


func _new_actor_body(actor_script: Script, layer: int, mask: int, collision_radius: float) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.set_script(actor_script)
	body.collision_layer = layer
	body.collision_mask = mask
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = collision_radius
	collider.shape = circle
	body.add_child(collider)
	return body


func _player_bounds() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(Vector2(28.0, 43.0), Vector2(maxf(1.0, viewport_size.x - 56.0), maxf(1.0, viewport_size.y - 142.0)))


func _spawn_enemy() -> void:
	if enemies.size() >= MAX_ENEMIES or mode != "playing":
		return
	var bounds := _player_bounds()
	var spawn_position := Vector2.ZERO
	match randi_range(0, 3):
		0:
			spawn_position = Vector2(bounds.position.x, randf_range(bounds.position.y, bounds.end.y))
		1:
			spawn_position = Vector2(bounds.end.x, randf_range(bounds.position.y, bounds.end.y))
		2:
			spawn_position = Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.position.y)
		_:
			spawn_position = Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.end.y)

	var enemy: Variant = _new_actor_body(EnemyScript, 2, 3, 12.0)
	enemy.position = spawn_position
	var difficulty := clampf(elapsed_seconds / RUN_DURATION, 0.0, 1.0)
	enemy.move_speed = 32.0 + difficulty * 8.0
	actors.add_child(enemy)
	enemies.append(enemy)


func _on_melee_pressed() -> void:
	if mode != "playing" or melee_cooldown_left > 0.0 or not is_instance_valid(player):
		return
	melee_cooldown_left = 0.34
	var target: Variant = CombatRules.nearest_target(enemies, player.position, MELEE_RANGE)
	if target == null:
		_set_message("Melee missed - move closer.", 0.85)
		return

	target.mark(MELEE_MARK_DURATION + (1.0 if counter_relic_unlocked else 0.0))
	_set_message("EMBER MARK applied. Shoot that target.", 1.1)
	_damage_enemy(target, melee_damage)


func _on_shoot_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player):
		return
	var target: Variant = CombatRules.nearest_target(enemies, player.position, projectile_range)
	if target == null:
		_set_message("No valid target in range - no shot fired.", 1.1)
		return
	if shot_cooldown_left > 0.0:
		return

	var projectile: Variant = Node2D.new()
	projectile.set_script(ProjectileScript)
	projectile.target = target
	projectile.damage = ranged_damage
	var direction: Vector2 = player.position.direction_to(target.position)
	projectile.position = player.position + direction * 21.0
	projectile.hit.connect(_on_projectile_hit)
	actors.add_child(projectile)
	shot_cooldown_left = 0.20
	_set_message("Target acquired.", 0.55)


func _on_projectile_hit(target: Node2D, raw_damage: float) -> void:
	if not is_instance_valid(target) or target.get("alive") == false:
		return
	var marked: bool = float(target.get("marked_time")) > 0.0
	var damage := CombatRules.combo_damage(raw_damage, combo_bonus, marked)
	if marked:
		target.set("marked_time", 0.0)
		_set_message("EMBER COMBO! +%.0f bonus damage" % combo_bonus, 1.0)
	else:
		_set_message("Ranged hit: %.0f" % damage, 0.65)
	_damage_enemy(target, damage)


func _on_dodge_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player):
		return
	var perfect_target: Variant = _find_telegraphed_enemy()
	var direction: Vector2 = controls.move_vector
	if direction.length_squared() < 0.02:
		if perfect_target != null:
			direction = player.position - perfect_target.position
		else:
			direction = player.last_move_direction
	if not player.begin_dodge(direction, perfect_target != null):
		_set_message("Dodge is cooling down.", 0.65)
		return

	if perfect_target != null:
		perfect_target.cancel_telegraphed_attack()
		var damage: float = counter_damage + (8.0 if counter_relic_unlocked else 0.0)
		_set_message("PERFECT DODGE - COUNTER!", 1.1)
		_damage_enemy(perfect_target, damage)
	else:
		_set_message("Dodge!", 0.55)


func _find_telegraphed_enemy() -> Variant:
	if not is_instance_valid(player):
		return null
	var best: Variant = null
	var best_distance := 92.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive or enemy.windup_left <= 0.0:
			continue
		var distance: float = player.position.distance_to(enemy.position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


func _damage_enemy(enemy: Variant, amount: float) -> void:
	if not is_instance_valid(enemy) or not enemy.alive:
		return
	if enemy.take_damage(amount):
		_enemy_defeated(enemy)


func _enemy_defeated(enemy: Variant) -> void:
	if enemies.has(enemy):
		enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()
	kills += 1
	xp += 1
	_set_message("Enemy defeated. +1 XP", 0.75)
	if xp >= xp_to_next_level:
		xp -= xp_to_next_level
		xp_to_next_level += 1
		mode = "upgrade"
		get_tree().paused = true
		message = "Level up: choose one upgrade."
		message_lifetime = 0.0
		_sync_ui()


func _on_upgrade_selected(index: int) -> void:
	if mode != "upgrade":
		return
	match index:
		0:
			melee_damage += 5.0
			combo_bonus += 2.0
		1:
			ranged_damage += 4.0
			projectile_range += 30.0
		2:
			player.max_health += 15.0
			player.heal(15.0)

	get_tree().paused = false
	mode = "playing"
	_set_message("Upgrade applied.", 0.8)
	_sync_ui()


func _on_pause_pressed() -> void:
	if mode == "playing":
		mode = "paused"
		get_tree().paused = true
		_sync_ui()
	elif mode == "paused":
		_on_resume_pressed()


func _on_resume_pressed() -> void:
	if mode != "paused":
		return
	mode = "playing"
	get_tree().paused = false
	_sync_ui()


func _finish_run(won: bool) -> void:
	if run_reward_claimed:
		return
	get_tree().paused = false
	mode = "won" if won else "lost"
	run_reward = CombatRules.reward_for_run(kills, won)
	crystals += run_reward
	run_reward_claimed = true
	_save_progress()
	message = ""
	message_lifetime = 0.0
	_sync_ui()


func _on_unlock_pressed() -> void:
	if counter_relic_unlocked:
		_set_message("Counter Relic is already unlocked.", 1.1)
		_sync_ui()
		return
	if crystals < RELIC_COST:
		_set_message("Need 20 crystals to unlock the Counter Relic.", 1.2)
		_sync_ui()
		return
	crystals -= RELIC_COST
	counter_relic_unlocked = true
	_save_progress()
	_set_message("Counter Relic unlocked permanently.", 1.2)
	_sync_ui()


func _load_progress() -> void:
	var save := ConfigFile.new()
	var error := save.load("user://progress.cfg")
	if error == OK:
		crystals = maxi(0, int(save.get_value("progress", "crystals", 0)))
		counter_relic_unlocked = bool(save.get_value("progress", "counter_relic_unlocked", false))
	else:
		crystals = 0
		counter_relic_unlocked = false


func _save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("progress", "crystals", crystals)
	save.set_value("progress", "counter_relic_unlocked", counter_relic_unlocked)
	var error := save.save("user://progress.cfg")
	if error != OK:
		push_error("Could not save local progress. Error code: %d" % error)


func _set_message(text: String, duration: float) -> void:
	message = text
	message_lifetime = duration
	_sync_ui()


func _status() -> Dictionary:
	var time_left := maxi(0, int(ceil(RUN_DURATION - elapsed_seconds)))
	return {
		"health": player.health if is_instance_valid(player) else 100.0,
		"max_health": player.max_health if is_instance_valid(player) else 100.0,
		"time_left": time_left,
		"xp": xp,
		"xp_required": xp_to_next_level,
		"kills": kills,
		"crystals": crystals,
		"run_reward": run_reward,
		"unlocked_relic": counter_relic_unlocked
	}


func _sync_ui() -> void:
	if is_instance_valid(controls):
		controls.set_game_state(mode, _status(), message)
	queue_redraw()
