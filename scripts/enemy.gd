extends CharacterBody2D

var enemy_kind: String = "shade"
var max_health: float = 34.0
var health: float = 34.0
var move_speed: float = 38.0
var attack_damage: float = 10.0
var attack_range: float = 37.0
var attack_windup: float = 0.42
var attack_cooldown_duration: float = 0.92
var xp_reward: int = 1
var visual_scale: float = 1.0
var marked_time: float = 0.0
var windup_left: float = 0.0
var attack_cooldown_left: float = 0.30
var alive: bool = true
var animation_clock: float = 0.0
var hurt_flash_left: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var slow_left: float = 0.0
var slow_factor: float = 1.0
var visual_refresh_left: float = 0.0
func _ready() -> void:
	# Procedural silhouettes avoid missing actors on Android when imported SVGs are unavailable.
	queue_redraw()


func _refresh_sprite() -> void:
	queue_redraw()


func configure_kind(next_kind: String, difficulty: float) -> void:
	enemy_kind = next_kind
	match enemy_kind:
		"stalker":
			max_health = 27.0
			move_speed = 64.0
			attack_damage = 8.0
			attack_range = 33.0
			attack_windup = 0.34
			attack_cooldown_duration = 0.76
			xp_reward = 2
			visual_scale = 0.88
		"guardian":
			max_health = 72.0
			move_speed = 27.0
			attack_damage = 15.0
			attack_range = 43.0
			attack_windup = 0.62
			attack_cooldown_duration = 1.18
			xp_reward = 3
			visual_scale = 1.24
		"elite":
			max_health = 106.0
			move_speed = 43.0
			attack_damage = 16.0
			attack_range = 48.0
			attack_windup = 0.52
			attack_cooldown_duration = 1.10
			xp_reward = 4
			visual_scale = 1.34
		"boss":
			max_health = 470.0
			move_speed = 26.0
			attack_damage = 24.0
			attack_range = 81.0
			attack_windup = 0.92
			attack_cooldown_duration = 1.48
			xp_reward = 15
			visual_scale = 2.0
		_:
			max_health = 34.0
			move_speed = 36.0
			attack_damage = 10.0
			attack_range = 38.0
			attack_windup = 0.46
			attack_cooldown_duration = 0.98
			xp_reward = 1
			visual_scale = 1.0

	var health_scale := 1.0 + clampf(difficulty, 0.0, 1.0) * 0.28
	max_health *= health_scale
	move_speed += clampf(difficulty, 0.0, 1.0) * 5.0
	health = max_health
	attack_cooldown_left = randf_range(0.25, 0.75)
	queue_redraw()


func tick(delta: float, player_position: Vector2) -> bool:
	animation_clock += delta
	hurt_flash_left = maxf(0.0, hurt_flash_left - delta)
	marked_time = maxf(0.0, marked_time - delta)
	slow_left = maxf(0.0, slow_left - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	visual_refresh_left -= delta
	if visual_refresh_left <= 0.0:
		visual_refresh_left = 0.06
		queue_redraw()
	if not alive:
		velocity = Vector2.ZERO
		return false

	var to_player := player_position - position
	var distance := to_player.length()

	if windup_left > 0.0:
		velocity = Vector2.ZERO
		if distance > attack_range + 34.0:
			windup_left = 0.0
		else:
			windup_left -= delta
			if windup_left <= 0.0:
				attack_cooldown_left = attack_cooldown_duration
				move_and_slide()
				return true
			move_and_slide()
			return false

	if knockback_velocity.length_squared() > 50.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 480.0 * delta)
	elif distance > attack_range and distance > 0.001:
		velocity = to_player / distance * move_speed * (slow_factor if slow_left > 0.0 else 1.0)
	else:
		velocity = Vector2.ZERO
		if attack_cooldown_left <= 0.0:
			windup_left = attack_windup

	move_and_slide()
	return false


func apply_slow(duration: float, factor: float) -> void:
	slow_left = maxf(slow_left, duration)
	slow_factor = clampf(factor, 0.25, 1.0)
	queue_redraw()


func mark(duration: float) -> void:
	marked_time = maxf(marked_time, duration)
	queue_redraw()


func cancel_telegraphed_attack() -> void:
	windup_left = 0.0
	attack_cooldown_left = maxf(attack_cooldown_left, attack_cooldown_duration * 0.85)
	velocity = Vector2.ZERO
	queue_redraw()


func apply_knockback(direction: Vector2, force: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var resistance := 0.24 if enemy_kind == "boss" else 1.0
	knockback_velocity = direction.normalized() * force * resistance
	windup_left = 0.0
	queue_redraw()


func take_damage(amount: float) -> bool:
	if not alive:
		return true
	health = maxf(0.0, health - amount)
	hurt_flash_left = 0.14
	if health <= 0.0:
		alive = false
		velocity = Vector2.ZERO
	queue_redraw()
	return not alive


func _draw() -> void:
	var is_boss := enemy_kind == "boss"
	var bob := sin(animation_clock * 3.0) * 0.7
	draw_set_transform(Vector2(1.0, 6.0 + bob), 0.0, Vector2(1.4 * visual_scale, 0.52 * visual_scale))
	draw_circle(Vector2.ZERO, 14.0, Color(0.003, 0.008, 0.016, 0.68))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_enemy_body(bob)

	if slow_left > 0.0:
		draw_arc(Vector2.ZERO, 21.0 * visual_scale, 0.0, TAU, 28, Color(0.20, 0.78, 1.0, 0.75), 2.0)
		for shard in range(3):
			var ice_angle := TAU * float(shard) / 3.0 + animation_clock * 0.7
			var ice_center := Vector2(cos(ice_angle), sin(ice_angle)) * 23.0 * visual_scale
			draw_colored_polygon(PackedVector2Array([ice_center + Vector2(0.0, -3.0), ice_center + Vector2(2.5, 1.0), ice_center + Vector2(-2.5, 1.0)]), Color(0.64, 0.94, 1.0, 0.85))

	if enemy_kind == "elite" or is_boss:
		var aura_radius := 27.0 * visual_scale + sin(animation_clock * 3.0) * 2.0
		draw_arc(Vector2.ZERO, aura_radius, animation_clock * 0.3, animation_clock * 0.3 + TAU * 0.82, 40, Color(1.0, 0.17, 0.24, 0.45), 2.0)
		draw_arc(Vector2.ZERO, aura_radius * 0.78, -animation_clock * 0.4, TAU - animation_clock * 0.4, 36, Color(1.0, 0.62, 0.28, 0.24), 1.0)

	if windup_left > 0.0:
		var ratio := clampf(windup_left / maxf(attack_windup, 0.01), 0.0, 1.0)
		var warning_color := Color(1.0, 0.26, 0.20, 0.65 + 0.3 * (1.0 - ratio))
		draw_arc(Vector2.ZERO, attack_range + 10.0, 0.0, TAU, 48, warning_color, 3.0)
		draw_arc(Vector2.ZERO, attack_range + 4.0, -PI * 0.7, PI * 0.7, 36, Color(1.0, 0.77, 0.29, 0.55), 1.5)
		if is_boss:
			draw_arc(Vector2.ZERO, attack_range + 20.0, PI * 0.1, PI * 1.9, 48, Color(1.0, 0.19, 0.16, 0.35), 4.0)

	if marked_time > 0.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -28.0), Vector2(6.0, -22.0), Vector2(0.0, -16.0), Vector2(-6.0, -22.0)
		]), Color(1.0, 0.72, 0.22))
		draw_arc(Vector2.ZERO, 24.0 * visual_scale, 0.0, TAU, 28, Color(1.0, 0.56, 0.16, 0.75), 1.6)

	var bar_width := 34.0 * visual_scale
	var bar_y := -27.0 * visual_scale
	if is_boss:
		bar_width = 76.0
		bar_y = -57.0
	draw_rect(Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width, 5.0)), Color(0.015, 0.02, 0.035, 0.95), true)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width * clampf(health / maxf(1.0, max_health), 0.0, 1.0), 5.0)), Color(0.96, 0.26, 0.25), true)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width * clampf(health / maxf(1.0, max_health), 0.0, 1.0), 1.5)), Color(1.0, 0.66, 0.55, 0.9), true)
	if is_boss:
		draw_rect(Rect2(Vector2(-40.0, bar_y - 4.0), Vector2(80.0, 2.0)), Color(1.0, 0.61, 0.25, 0.8), true)


func _draw_enemy_body(bob: float) -> void:
	var outline := Color(0.018, 0.009, 0.020)
	var body_color := Color(0.40, 0.10, 0.18)
	var light_color := Color(0.88, 0.27, 0.29)
	match enemy_kind:
		"stalker":
			body_color = Color(0.08, 0.30, 0.24)
			light_color = Color(0.36, 0.91, 0.62)
		"guardian":
			body_color = Color(0.19, 0.31, 0.39)
			light_color = Color(0.66, 0.82, 0.87)
		"elite":
			body_color = Color(0.30, 0.13, 0.39)
			light_color = Color(0.96, 0.39, 0.39)
		"boss":
			body_color = Color(0.15, 0.08, 0.16)
			light_color = Color(1.0, 0.30, 0.20)
	if hurt_flash_left > 0.0:
		body_color = Color(0.92, 0.76, 0.72)
		light_color = Color(1.0, 0.96, 0.76)
	elif slow_left > 0.0:
		body_color = Color(0.10, 0.34, 0.46)
		light_color = Color(0.58, 0.93, 1.0)
	elif windup_left > 0.0:
		light_color = Color(1.0, 0.88, 0.36)

	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE * visual_scale)

	if enemy_kind == "stalker":
		# Lean, many-legged silhouette for the fast hunter.
		for limb_index in range(4):
			var side := -1.0 if limb_index < 2 else 1.0
			var y_offset := -5.0 + float(limb_index % 2) * 9.0
			draw_line(Vector2(side * 5.0, y_offset), Vector2(side * (13.0 + float(limb_index % 2) * 2.0), y_offset + (4.0 if limb_index % 2 == 0 else -4.0)), outline, 3.0)
			draw_line(Vector2(side * 5.0, y_offset), Vector2(side * (13.0 + float(limb_index % 2) * 2.0), y_offset + (4.0 if limb_index % 2 == 0 else -4.0)), body_color, 1.4)

	# Chunky jagged outer contour creates readable sprite-like edges.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14.0, -5.0), Vector2(-12.0, -13.0), Vector2(-7.0, -12.0),
		Vector2(-4.0, -18.0), Vector2(0.0, -14.0), Vector2(5.0, -18.0),
		Vector2(8.0, -12.0), Vector2(12.0, -13.0), Vector2(15.0, -5.0),
		Vector2(12.0, 5.0), Vector2(7.0, 12.0), Vector2(0.0, 14.0),
		Vector2(-8.0, 11.0), Vector2(-13.0, 4.0)
	]), outline)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, -5.0), Vector2(-9.0, -11.0), Vector2(-5.0, -10.0),
		Vector2(-2.0, -14.0), Vector2(1.0, -11.0), Vector2(5.0, -14.0),
		Vector2(8.0, -10.0), Vector2(10.0, -11.0), Vector2(12.0, -4.0),
		Vector2(10.0, 4.0), Vector2(6.0, 9.0), Vector2(0.0, 11.0),
		Vector2(-7.0, 9.0), Vector2(-10.0, 3.0)
	]), body_color)

	# Variant-specific armor and anatomy.
	match enemy_kind:
		"guardian":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12.0, -8.0), Vector2(-5.0, -14.0), Vector2(7.0, -13.0),
				Vector2(13.0, -5.0), Vector2(10.0, 7.0), Vector2(0.0, 12.0),
				Vector2(-11.0, 6.0)
			]), Color(0.09, 0.16, 0.22))
			draw_line(Vector2(-9.0, -4.0), Vector2(9.0, -4.0), light_color, 2.4)
			draw_line(Vector2(-7.0, 3.0), Vector2(7.0, 3.0), Color(0.43, 0.65, 0.72), 2.0)
		"elite":
			draw_colored_polygon(PackedVector2Array([Vector2(-7.0, -10.0), Vector2(-4.0, -17.0), Vector2(0.0, -12.0), Vector2(5.0, -17.0), Vector2(8.0, -10.0)]), Color(0.77, 0.24, 0.43))
			draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 28, Color(0.83, 0.37, 1.0, 0.38), 2.0)
		"boss":
			draw_colored_polygon(PackedVector2Array([Vector2(-10.0, -9.0), Vector2(-18.0, -22.0), Vector2(-4.0, -17.0), Vector2(0.0, -12.0)]), Color(0.09, 0.04, 0.09))
			draw_colored_polygon(PackedVector2Array([Vector2(10.0, -9.0), Vector2(18.0, -22.0), Vector2(4.0, -17.0), Vector2(0.0, -12.0)]), Color(0.09, 0.04, 0.09))
			draw_colored_polygon(PackedVector2Array([Vector2(-8.0, -3.0), Vector2(0.0, -8.0), Vector2(8.0, -3.0), Vector2(6.0, 7.0), Vector2(0.0, 10.0), Vector2(-6.0, 7.0)]), Color(0.29, 0.11, 0.12))
		"stalker":
			draw_colored_polygon(PackedVector2Array([Vector2(-5.0, -7.0), Vector2(-2.0, -15.0), Vector2(4.0, -12.0), Vector2(7.0, -6.0), Vector2(3.0, 3.0), Vector2(-5.0, 3.0)]), Color(0.09, 0.43, 0.31))
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-7.0, -8.0), Vector2(-4.0, -12.0), Vector2(5.0, -12.0), Vector2(8.0, -7.0), Vector2(4.0, 2.0), Vector2(-4.0, 2.0)]), Color(0.25, 0.055, 0.11))

	# Bright eyes, forehead marks, and a core light provide a readable focal point.
	draw_rect(Rect2(-7.0, -5.0, 4.0, 2.5), light_color, true)
	draw_rect(Rect2(3.0, -5.0, 4.0, 2.5), light_color, true)
	draw_rect(Rect2(-4.0, 2.0, 8.0, 1.8), Color(1.0, 0.75, 0.42, 0.72), true)
	draw_line(Vector2(-7.0, 7.0), Vector2(0.0, 10.0), Color(0.94, 0.54, 0.28, 0.84), 1.4)
	draw_line(Vector2(0.0, 10.0), Vector2(7.0, 7.0), Color(0.94, 0.54, 0.28, 0.84), 1.4)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
