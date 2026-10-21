extends Node2D

const CombatRules = preload("res://scripts/combat_rules.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PickupScript = preload("res://scripts/crystal_pickup.gd")
const WoodObstacleScript = preload("res://scripts/wood_obstacle.gd")
const CombatFxScript = preload("res://scripts/combat_fx.gd")

const WORLD_SIZE := Vector2(2400.0, 1600.0)
const RUN_DURATION := 480.0
const BOSS_SPAWN_TIME := 360.0
const MAX_ENEMIES := 12
const MELEE_RANGE := 67.0
const RANGED_RANGE := 310.0
const MELEE_MARK_DURATION := 3.0
const COMBO_BONUS := 24.0
const RELIC_COST := 35
const RANGED_ENERGY_COST := 9.0
const SKILL_ENERGY_COST := 32.0
const ULTIMATE_ENERGY_COST := 100.0
const ICE_ENERGY_COST := 28.0
const LIGHTNING_ENERGY_COST := 34.0

@onready var actors: Node2D = $World/Actors
@onready var controls: Control = $UI/TouchControls

var mode: String = "menu"
var player: Variant
var combat_fx: Variant
var enemies: Array = []
var pickups: Array = []
var elapsed_seconds: float = 0.0
var spawn_timer: float = 0.8
var melee_cooldown_left: float = 0.0
var shot_cooldown_left: float = 0.0
var skill_cooldown_left: float = 0.0
var ice_cooldown_left: float = 0.0
var lightning_cooldown_left: float = 0.0
var xp: int = 0
var xp_to_next_level: int = 8
var kills: int = 0
var crystals: int = 0
var run_reward: int = 0
var run_reward_claimed: bool = false
var counter_relic_unlocked: bool = false
var boss_spawned: bool = false
var melee_damage: float = 24.0
var ranged_damage: float = 13.0
var combo_bonus: float = COMBO_BONUS
var counter_damage: float = 25.0
var projectile_range: float = RANGED_RANGE
var message: String = ""
var message_lifetime: float = 0.0
var ui_refresh_left: float = 0.0


func _ready() -> void:
	randomize()
	_setup_wood_obstacles()
	combat_fx = Node2D.new()
	combat_fx.name = "CombatFX"
	combat_fx.set_script(CombatFxScript)
	$World.add_child(combat_fx)
	controls.process_mode = Node.PROCESS_MODE_ALWAYS
	controls.start_requested.connect(_start_run)
	controls.melee_pressed.connect(_on_melee_pressed)
	controls.shoot_pressed.connect(_on_shoot_pressed)
	controls.dodge_pressed.connect(_on_dodge_pressed)
	controls.skill_pressed.connect(_on_skill_pressed)
	controls.ultimate_pressed.connect(_on_ultimate_pressed)
	controls.ice_pressed.connect(_on_ice_pressed)
	controls.lightning_pressed.connect(_on_lightning_pressed)
	controls.pause_pressed.connect(_on_pause_pressed)
	controls.resume_requested.connect(_on_resume_pressed)
	controls.restart_requested.connect(_start_run)
	controls.upgrade_selected.connect(_on_upgrade_selected)
	controls.unlock_pressed.connect(_on_unlock_pressed)
	_load_progress()
	_sync_ui()


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
		_finish_run(_alive_boss() == null)
		return

	if not is_instance_valid(player):
		_finish_run(false)
		return

	melee_cooldown_left = maxf(0.0, melee_cooldown_left - delta)
	shot_cooldown_left = maxf(0.0, shot_cooldown_left - delta)
	skill_cooldown_left = maxf(0.0, skill_cooldown_left - delta)
	ice_cooldown_left = maxf(0.0, ice_cooldown_left - delta)
	lightning_cooldown_left = maxf(0.0, lightning_cooldown_left - delta)

	var requested_move: Vector2 = controls.move_vector
	var keyboard_move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keyboard_move.length_squared() > 0.02:
		requested_move = keyboard_move
	player.tick(delta, requested_move, _player_bounds())

	if not boss_spawned and elapsed_seconds >= BOSS_SPAWN_TIME:
		boss_spawned = true
		_spawn_enemy("boss")
		_set_message("TRÙM CUỐI XUẤT HIỆN — HẠ GỤC HẮN ĐỂ THẮNG!", 3.5)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		var ramp := clampf(elapsed_seconds / RUN_DURATION, 0.0, 1.0)
		spawn_timer = 2.35 - ramp * 0.55

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var attack_resolved: bool = enemy.tick(delta, player.position)
		if attack_resolved and not player.is_dodging():
			var result: Dictionary = player.receive_damage(enemy.attack_damage)
			if bool(result.get("applied", false)):
				if is_instance_valid(combat_fx):
					combat_fx.add_hit(player.position, Color(1.0, 0.20, 0.20))
					combat_fx.play_sfx("hurt")
				_set_message("BỊ TRÚNG ĐÒN  −%d SINH LỰC" % int(enemy.attack_damage), 0.85)
				if bool(result.get("dead", false)):
					_finish_run(false)
					return
		if mode != "playing":
			break

	_tick_pickups(delta)


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
		KEY_E:
			_on_skill_pressed()
		KEY_Q:
			_on_ultimate_pressed()
		KEY_R:
			_on_ice_pressed()
		KEY_T:
			_on_lightning_pressed()
		KEY_ESCAPE:
			_on_pause_pressed()


func _setup_wood_obstacles() -> void:
	actors.y_sort_enabled = true
	for child in actors.get_children():
		if child.is_in_group("arena_obstacle"):
			child.queue_free()

	var layouts: Array[Dictionary] = [
		# A loose ring around the starting clearing creates routes without boxing the hero in.
		{"point": Vector2(0.44, 0.40), "length": 108.0, "angle": -0.25},
		{"point": Vector2(0.67, 0.42), "length": 90.0, "angle": 1.45},
		{"point": Vector2(0.36, 0.61), "length": 86.0, "angle": 1.52},
		{"point": Vector2(0.70, 0.61), "length": 110.0, "angle": -0.20},
		{"point": Vector2(0.51, 0.67), "length": 92.0, "angle": 0.15},
		# Outer regions keep landmarks and cover distributed across the larger map.
		{"point": Vector2(0.18, 0.22), "length": 106.0, "angle": -0.16},
		{"point": Vector2(0.80, 0.22), "length": 90.0, "angle": 0.24},
		{"point": Vector2(0.17, 0.50), "length": 84.0, "angle": 1.52},
		{"point": Vector2(0.85, 0.50), "length": 74.0, "angle": 1.48},
		{"point": Vector2(0.22, 0.79), "length": 88.0, "angle": -0.40},
		{"point": Vector2(0.57, 0.83), "length": 96.0, "angle": 1.48},
		{"point": Vector2(0.86, 0.82), "length": 82.0, "angle": 1.48}
	]
	for layout in layouts:
		var obstacle: Variant = StaticBody2D.new()
		obstacle.set_script(WoodObstacleScript)
		var world_point: Vector2 = layout["point"]
		obstacle.position = WORLD_SIZE * world_point
		obstacle.rotation = float(layout["angle"])
		obstacle.configure(float(layout["length"]), 22.0)
		actors.add_child(obstacle)

func _start_run() -> void:
	get_tree().paused = false
	if is_instance_valid(combat_fx):
		combat_fx.clear_effects()
	for child in actors.get_children():
		if child.is_in_group("arena_obstacle"):
			continue
		child.free()
	enemies.clear()
	pickups.clear()
	player = null

	elapsed_seconds = 0.0
	spawn_timer = 0.8
	melee_cooldown_left = 0.0
	shot_cooldown_left = 0.0
	skill_cooldown_left = 0.0
	ice_cooldown_left = 0.0
	lightning_cooldown_left = 0.0
	xp = 0
	xp_to_next_level = 8
	kills = 0
	run_reward = 0
	run_reward_claimed = false
	boss_spawned = false
	melee_damage = 24.0
	ranged_damage = 13.0
	combo_bonus = COMBO_BONUS
	counter_damage = 25.0
	projectile_range = RANGED_RANGE

	player = _new_actor_body(PlayerScript, 1, 6, 12.0)
	actors.add_child(player)
	player.position = WORLD_SIZE * 0.5
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	camera.enabled = true
	player.add_child(camera)
	player.visible = true
	player.modulate = Color.WHITE
	player.self_modulate = Color.WHITE
	player.health = player.max_health
	player.energy = player.max_energy
	player.queue_redraw()
	mode = "playing"
	message = "ĐÁNH ĐẤU ĐỂ GẮN ẤN • KIẾM KHÍ KÍCH NỔ • NÉ ĐÚNG LÚC ĐỂ PHẢN KÍCH"
	message_lifetime = 3.2
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
	var half_view := get_viewport_rect().size * 0.5
	var margin := half_view + Vector2(24.0, 24.0)
	return Rect2(margin, WORLD_SIZE - margin * 2.0)


func _spawn_enemy(forced_kind: String = "") -> void:
	if (enemies.size() >= MAX_ENEMIES and forced_kind != "boss") or mode != "playing":
		return

	var kind := forced_kind if forced_kind != "" else _choose_enemy_kind()
	var view_size := get_viewport_rect().size
	var half_view := view_size * 0.5 + Vector2(42.0, 42.0)
	var center: Vector2 = player.position if is_instance_valid(player) else WORLD_SIZE * 0.5
	var spawn_position := Vector2.ZERO
	match randi_range(0, 3):
		0:
			spawn_position = Vector2(center.x - half_view.x, randf_range(center.y - half_view.y, center.y + half_view.y))
		1:
			spawn_position = Vector2(center.x + half_view.x, randf_range(center.y - half_view.y, center.y + half_view.y))
		2:
			spawn_position = Vector2(randf_range(center.x - half_view.x, center.x + half_view.x), center.y - half_view.y)
		_:
			spawn_position = Vector2(randf_range(center.x - half_view.x, center.x + half_view.x), center.y + half_view.y)
	spawn_position.x = clampf(spawn_position.x, 28.0, WORLD_SIZE.x - 28.0)
	spawn_position.y = clampf(spawn_position.y, 28.0, WORLD_SIZE.y - 28.0)

	var radius := 23.0 if kind == "boss" else (16.0 if kind == "guardian" or kind == "elite" else 12.0)
	var enemy: Variant = _new_actor_body(EnemyScript, 2, 5, radius)
	enemy.position = spawn_position
	enemy.configure_kind(kind, elapsed_seconds / RUN_DURATION)
	actors.add_child(enemy)
	enemies.append(enemy)


func _choose_enemy_kind() -> String:
	if elapsed_seconds >= 240.0 and randf() < 0.15:
		return "elite"
	if elapsed_seconds >= 150.0 and randf() < 0.24:
		return "guardian"
	if elapsed_seconds >= 75.0 and randf() < 0.25:
		return "stalker"
	return "shade"


func _on_melee_pressed() -> void:
	if mode != "playing" or melee_cooldown_left > 0.0 or not is_instance_valid(player):
		return
	melee_cooldown_left = 0.36
	var target: Variant = CombatRules.nearest_target(enemies, player.position, MELEE_RANGE)
	if target == null:
		player.play_action("slash", player.position + player.facing_direction * 40.0)
		if is_instance_valid(combat_fx):
			combat_fx.add_slash(player.position, player.facing_direction)
			combat_fx.play_sfx("swing")
		player.restore_energy(2.0)
		_set_message("CHÉM HỤT — ÁP SÁT KẺ ĐỊCH", 0.55)
		return

	player.play_action("slash", target.position)
	if is_instance_valid(combat_fx):
		combat_fx.add_slash(player.position, player.position.direction_to(target.position))
		combat_fx.play_sfx("swing")
		combat_fx.play_sfx("hit")
	player.restore_energy(5.0)
	target.mark(MELEE_MARK_DURATION + (1.2 if counter_relic_unlocked else 0.0))
	_set_message("KIẾM ẤN ĐÃ GẮN — DÙNG KIẾM KHÍ ĐỂ KÍCH NỔ", 0.8)
	_damage_enemy(target, melee_damage)


func _on_shoot_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player):
		return
	var target: Variant = CombatRules.nearest_target(enemies, player.position, projectile_range)
	if target == null:
		_set_message("KHÔNG CÓ MỤC TIÊU TRONG TẦM", 0.7)
		return
	if shot_cooldown_left > 0.0:
		return
	if not player.spend_energy(RANGED_ENERGY_COST):
		_set_message("THIẾU NỘI LỰC — DI CHUYỂN HOẶC ĐÁNH THƯỜNG ĐỂ HỒI", 1.0)
		return

	var projectile: Variant = Node2D.new()
	projectile.set_script(ProjectileScript)
	projectile.target = target
	projectile.damage = ranged_damage
	var direction: Vector2 = player.position.direction_to(target.position)
	projectile.position = player.position + direction * 21.0
	projectile.hit.connect(_on_projectile_hit)
	actors.add_child(projectile)
	if is_instance_valid(combat_fx):
		combat_fx.add_slash(player.position, direction, Color(0.32, 0.92, 1.0))
		combat_fx.play_sfx("shot")
	shot_cooldown_left = 0.48
	player.play_action("ranged", target.position)
	_set_message("KIẾM KHÍ PHÓNG RA", 0.45)


func _on_skill_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player):
		return
	if skill_cooldown_left > 0.0:
		return
	if not player.spend_energy(SKILL_ENERGY_COST):
		_set_message("PHÁ TRẬN CẦN 32 NỘI LỰC", 0.8)
		return

	skill_cooldown_left = 7.0
	player.play_action("burst")
	if is_instance_valid(combat_fx):
		combat_fx.add_slam(player.position, 158.0)
		combat_fx.play_sfx("slam")
	var hit_count := 0
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if player.position.distance_to(enemy.position) > 158.0:
			continue
		var damage := 46.0
		if enemy.marked_time > 0.0:
			damage += combo_bonus * 0.65
			enemy.set("marked_time", 0.0)
		enemy.apply_knockback(enemy.position - player.position, 165.0)
		_damage_enemy(enemy, damage)
		hit_count += 1
	_set_message("PHÁ TRẬN — TRÚNG %d MỤC TIÊU" % hit_count, 1.0)


func _on_ice_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player) or ice_cooldown_left > 0.0:
		return
	var nearby_count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive and player.position.distance_to(enemy.position) <= 188.0:
			nearby_count += 1
	if nearby_count == 0:
		_set_message("BĂNG PHONG CẦN KẺ ĐỊCH TRONG PHẠM VI", 0.8)
		return
	if not player.spend_energy(ICE_ENERGY_COST):
		_set_message("BĂNG PHONG CẦN 28 NỘI LỰC", 0.8)
		return
	ice_cooldown_left = 9.5
	player.play_action("ice")
	if is_instance_valid(combat_fx):
		combat_fx.add_ice(player.position, 188.0)
		combat_fx.play_sfx("ice")
	var affected := 0
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if player.position.distance_to(enemy.position) > 188.0:
			continue
		enemy.apply_slow(2.6, 0.42)
		_damage_enemy(enemy, 16.0)
		affected += 1
	_set_message("BĂNG PHONG — LÀM CHẬM %d KẺ ĐỊCH" % affected, 1.0)


func _on_lightning_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player) or lightning_cooldown_left > 0.0:
		return
	var first_target: Variant = CombatRules.nearest_target(enemies, player.position, 330.0)
	if first_target == null:
		_set_message("LÔI CHUỖI CẦN MỤC TIÊU TRONG TẦM", 0.8)
		return
	if not player.spend_energy(LIGHTNING_ENERGY_COST):
		_set_message("LÔI CHUỖI CẦN 34 NỘI LỰC", 0.8)
		return
	lightning_cooldown_left = 10.0
	var chain_points := PackedVector2Array([player.position])
	var hit_enemies: Array = []
	var current_position: Vector2 = player.position
	var total_damage := 0.0
	for chain_index in range(4):
		var nearest: Variant = null
		var nearest_distance := 330.0 if chain_index == 0 else 185.0
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.alive or hit_enemies.has(enemy):
				continue
			var distance: float = current_position.distance_to(enemy.position)
			if distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
		if nearest == null:
			break
		hit_enemies.append(nearest)
		chain_points.append(nearest.position)
		var damage := 38.0
		if nearest.marked_time > 0.0:
			damage += combo_bonus * 0.5
			nearest.marked_time = 0.0
		_damage_enemy(nearest, damage)
		total_damage += damage
		current_position = nearest.position
	if hit_enemies.is_empty():
		player.restore_energy(LIGHTNING_ENERGY_COST)
		lightning_cooldown_left = 0.0
		_set_message("LÔI CHUỖI KHÔNG TÌM THẤY MỤC TIÊU", 0.8)
		return
	if is_instance_valid(combat_fx):
		combat_fx.add_lightning(chain_points)
		combat_fx.play_sfx("lightning")
	player.play_action("lightning", chain_points[1])
	_set_message("LÔI CHUỖI — %d MỤC TIÊU • %.0f SÁT THƯƠNG" % [hit_enemies.size(), total_damage], 1.1)


func _on_ultimate_pressed() -> void:
	if mode != "playing" or not is_instance_valid(player):
		return
	if not player.spend_energy(ULTIMATE_ENERGY_COST):
		_set_message("TUYỆT KỸ CHƯA ĐẦY NỘI LỰC", 0.8)
		return

	player.play_action("ultimate")
	if is_instance_valid(combat_fx):
		combat_fx.add_slam(player.position, 228.0, Color(0.40, 0.77, 1.0))
		combat_fx.play_sfx("ultimate")
	player.invulnerability_left = maxf(player.invulnerability_left, 0.72)
	var hit_count := 0
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if player.position.distance_to(enemy.position) > 228.0:
			continue
		enemy.cancel_telegraphed_attack()
		enemy.apply_knockback(enemy.position - player.position, 270.0)
		var damage := 135.0 if enemy.enemy_kind == "boss" else 165.0
		_damage_enemy(enemy, damage)
		hit_count += 1
	_set_message("THIÊN KIẾM GIÁNG LÂM — %d MỤC TIÊU" % hit_count, 1.6)


func _on_projectile_hit(target: Node2D, raw_damage: float) -> void:
	if not is_instance_valid(target) or target.get("alive") == false:
		return
	var marked: bool = float(target.get("marked_time")) > 0.0
	var damage := CombatRules.combo_damage(raw_damage, combo_bonus, marked)
	if is_instance_valid(combat_fx):
		combat_fx.play_sfx("hit")
	if marked:
		target.set("marked_time", 0.0)
		_set_message("KIẾM ẤN BÙNG NỔ! +%.0f SÁT THƯƠNG" % combo_bonus, 0.85)
	else:
		_set_message("KIẾM KHÍ TRÚNG ĐÍCH: %.0f" % damage, 0.55)
	if is_instance_valid(player):
		player.restore_energy(2.0)
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
		_set_message("LƯỚT ĐANG HỒI CHIÊU", 0.6)
		return
	if is_instance_valid(combat_fx):
		combat_fx.add_dash(player.position, direction)
		combat_fx.play_sfx("dash")

	if perfect_target != null:
		perfect_target.cancel_telegraphed_attack()
		var damage: float = counter_damage + (10.0 if counter_relic_unlocked else 0.0)
		player.restore_energy(22.0)
		if is_instance_valid(combat_fx):
			combat_fx.add_slash(perfect_target.position, player.position.direction_to(perfect_target.position), Color(1.0, 0.78, 0.31))
			combat_fx.play_sfx("hit")
		_set_message("NÉ HOÀN HẢO — PHẢN KÍCH!", 1.0)
		_damage_enemy(perfect_target, damage)
	else:
		_set_message("LƯỚT TRÁNH ĐÒN", 0.5)


func _find_telegraphed_enemy() -> Variant:
	if not is_instance_valid(player):
		return null
	var best: Variant = null
	var best_distance := 124.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive or enemy.windup_left <= 0.0:
			continue
		var distance: float = player.position.distance_to(enemy.position)
		if distance <= minf(best_distance, enemy.attack_range + 24.0):
			best = enemy
			best_distance = distance
	return best


func _damage_enemy(enemy: Variant, amount: float) -> void:
	if not is_instance_valid(enemy) or not enemy.alive:
		return
	if is_instance_valid(combat_fx):
		combat_fx.add_hit(enemy.position, Color(1.0, 0.76, 0.38) if enemy.marked_time > 0.0 else Color(1.0, 0.43, 0.35))
	if enemy.take_damage(amount):
		_enemy_defeated(enemy)


func _enemy_defeated(enemy: Variant) -> void:
	if not is_instance_valid(enemy):
		return
	var defeated_kind: String = enemy.enemy_kind
	var defeated_position: Vector2 = enemy.position
	if is_instance_valid(combat_fx):
		combat_fx.add_death(defeated_position, Color(1.0, 0.35, 0.32) if defeated_kind != "boss" else Color(0.85, 0.36, 1.0))
		combat_fx.play_sfx("death")
	var gained_xp: int = enemy.xp_reward
	if enemies.has(enemy):
		enemies.erase(enemy)
	enemy.queue_free()
	kills += 1
	xp += gained_xp
	if is_instance_valid(player):
		player.restore_energy(5.0)

	if defeated_kind == "boss":
		crystals += 10
		_save_progress()
		_set_message("TRÙM ĐÃ BỊ TIÊU DIỆT — CHIẾN THẮNG!", 2.0)
		_finish_run(true)
		return

	if defeated_kind == "elite":
		if randf() < 0.68:
			_spawn_crystal_pickup(defeated_position, randi_range(2, 3))
	elif randf() < 0.07:
		_spawn_crystal_pickup(defeated_position, 1)

	if xp >= xp_to_next_level:
		xp -= xp_to_next_level
		xp_to_next_level += 3
		mode = "upgrade"
		get_tree().paused = true
		message = "LÊN CẤP — CHỌN MỘT NÂNG CẤP"
		message_lifetime = 0.0
		_sync_ui()
	else:
		_set_message("HẠ GỤC KẺ ĐỊCH • +%d KINH NGHIỆM" % gained_xp, 0.7)


func _spawn_crystal_pickup(at_position: Vector2, amount: int) -> void:
	var pickup: Variant = Node2D.new()
	pickup.set_script(PickupScript)
	pickup.position = at_position
	pickup.amount = amount
	actors.add_child(pickup)
	pickups.append(pickup)


func _tick_pickups(delta: float) -> void:
	if not is_instance_valid(player):
		return
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			pickups.erase(pickup)
			continue
		var to_player: Vector2 = player.position - pickup.position
		var distance := to_player.length()
		if distance < 112.0 and distance > 0.01:
			pickup.position += to_player / distance * minf(260.0 * delta, distance)
		if distance < 23.0:
			var picked_amount: int = int(pickup.amount)
			if is_instance_valid(combat_fx):
				combat_fx.add_pickup(pickup.position)
				combat_fx.play_sfx("pickup")
			crystals += picked_amount
			pickups.erase(pickup)
			pickup.queue_free()
			_save_progress()
			_set_message("NHẶT ĐƯỢC %d TINH THẠCH" % picked_amount, 0.8)


func _alive_boss() -> Variant:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive and enemy.enemy_kind == "boss":
			return enemy
	return null


func _on_upgrade_selected(index: int) -> void:
	if mode != "upgrade":
		return
	match index:
		0:
			melee_damage += 5.0
			combo_bonus += 5.0
		1:
			ranged_damage += 4.0
			projectile_range += 35.0
			player.energy_regen += 0.65
		2:
			player.max_health += 20.0
			player.heal(20.0)
			player.max_energy += 10.0
			player.restore_energy(10.0)

	get_tree().paused = false
	mode = "playing"
	_set_message("ĐÃ ÁP DỤNG NÂNG CẤP", 0.8)
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
		_set_message("BẢO VẬT PHẢN KÍCH ĐÃ ĐƯỢC MỞ KHÓA", 1.0)
		_sync_ui()
		return
	if crystals < RELIC_COST:
		_set_message("CẦN 35 TINH THẠCH ĐỂ MỞ BẢO VẬT", 1.0)
		_sync_ui()
		return
	crystals -= RELIC_COST
	counter_relic_unlocked = true
	_save_progress()
	_set_message("ĐÃ MỞ KHÓA BẢO VẬT PHẢN KÍCH", 1.0)
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
		push_error("Không thể lưu tiến trình. Mã lỗi: %d" % error)


func _set_message(text: String, duration: float) -> void:
	message = text
	message_lifetime = duration
	_sync_ui()


func _status() -> Dictionary:
	var time_left := maxi(0, int(ceil(RUN_DURATION - elapsed_seconds)))
	var enemy_positions: Array[Vector2] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive:
			enemy_positions.append(enemy.position)
	var obstacle_positions: Array[Vector2] = []
	for actor in actors.get_children():
		if actor.is_in_group("arena_obstacle"):
			obstacle_positions.append(actor.position)
	return {
		"health": player.health if is_instance_valid(player) else 100.0,
		"max_health": player.max_health if is_instance_valid(player) else 100.0,
		"energy": player.energy if is_instance_valid(player) else 100.0,
		"max_energy": player.max_energy if is_instance_valid(player) else 100.0,
		"energy_regen": player.energy_regen if is_instance_valid(player) else 5.0,
		"time_left": time_left,
		"xp": xp,
		"xp_required": xp_to_next_level,
		"kills": kills,
		"crystals": crystals,
		"run_reward": run_reward,
		"unlocked_relic": counter_relic_unlocked,
		"melee_cd": melee_cooldown_left,
		"shoot_cd": shot_cooldown_left,
		"skill_cd": skill_cooldown_left,
		"ice_cd": ice_cooldown_left,
		"lightning_cd": lightning_cooldown_left,
		"dodge_cd": player.dodge_cooldown_left if is_instance_valid(player) else 0.0,
		"boss_spawned": boss_spawned,
		"world_size": WORLD_SIZE,
		"player_world_position": player.position if is_instance_valid(player) else WORLD_SIZE * 0.5,
		"enemy_world_positions": enemy_positions,
		"obstacle_world_positions": obstacle_positions
	}


func _sync_ui() -> void:
	if is_instance_valid(controls):
		controls.set_game_state(mode, _status(), message)
