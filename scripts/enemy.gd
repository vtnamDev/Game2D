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


func tick(delta: float, player_position: Vector2) -> bool:
	animation_clock += delta
	hurt_flash_left = maxf(0.0, hurt_flash_left - delta)
	marked_time = maxf(0.0, marked_time - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
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
			queue_redraw()
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
		velocity = to_player / distance * move_speed
	else:
		velocity = Vector2.ZERO
		if attack_cooldown_left <= 0.0:
			windup_left = attack_windup

	move_and_slide()
	queue_redraw()
	return false


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
	var bob := sin(animation_clock * (6.4 if enemy_kind == "stalker" else 3.6)) * (1.2 if enemy_kind != "boss" else 0.6)
	var is_boss := enemy_kind == "boss"
	var body_size := 15.0 * visual_scale
	var dark := Color(0.17, 0.055, 0.10)
	var mid := Color(0.58, 0.13, 0.18)
	var light := Color(0.91, 0.28, 0.25)
	var highlight := Color(1.0, 0.65, 0.35)

	match enemy_kind:
		"stalker":
			dark = Color(0.08, 0.055, 0.15)
			mid = Color(0.31, 0.19, 0.45)
			light = Color(0.68, 0.37, 0.78)
			highlight = Color(0.45, 0.95, 1.0)
		"guardian":
			dark = Color(0.12, 0.11, 0.08)
			mid = Color(0.40, 0.31, 0.19)
			light = Color(0.70, 0.53, 0.29)
			highlight = Color(1.0, 0.83, 0.50)
		"elite":
			dark = Color(0.10, 0.025, 0.08)
			mid = Color(0.47, 0.09, 0.27)
			light = Color(0.90, 0.20, 0.40)
			highlight = Color(1.0, 0.66, 0.36)
		"boss":
			dark = Color(0.035, 0.024, 0.06)
			mid = Color(0.23, 0.055, 0.12)
			light = Color(0.61, 0.09, 0.18)
			highlight = Color(1.0, 0.35, 0.20)
	if hurt_flash_left > 0.0:
		mid = Color(1.0, 0.83, 0.72)
		light = Color(1.0, 0.98, 0.85)

	# Ground shadow is an ellipse, not a flat outline.
	draw_set_transform(Vector2(1.0, 6.0 + bob), 0.0, Vector2(1.5 * visual_scale, 0.55 * visual_scale))
	draw_circle(Vector2.ZERO, body_size, Color(0.005, 0.01, 0.018, 0.62))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if enemy_kind == "elite" or is_boss:
		var aura_radius := 27.0 * visual_scale + sin(animation_clock * 3.0) * 2.0
		draw_arc(Vector2.ZERO, aura_radius, animation_clock * 0.3, animation_clock * 0.3 + TAU * 0.82, 40, Color(1.0, 0.17, 0.24, 0.45), 2.0)
		draw_arc(Vector2.ZERO, aura_radius * 0.78, -animation_clock * 0.4, TAU - animation_clock * 0.4, 36, Color(1.0, 0.62, 0.28, 0.24), 1.0)

	if windup_left > 0.0:
		var ratio := clampf(windup_left / maxf(attack_windup, 0.01), 0.0, 1.0)
		var warning_color := Color(1.0, 0.26, 0.20, 0.65 + 0.3 * (1.0 - ratio))
		draw_arc(Vector2.ZERO, attack_range + 10.0, 0.0, TAU, 48, warning_color, 3.0)
		draw_arc(Vector2.ZERO, attack_range + 4.0, -PI * 0.7, PI * 0.7, 36, Color(1.0, 0.77, 0.29, 0.55), 1.5)

	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2(visual_scale, visual_scale))
	if is_boss:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-23.0, -13.0), Vector2(-29.0, -28.0), Vector2(-12.0, -21.0),
			Vector2(-7.0, -34.0), Vector2(4.0, -25.0), Vector2(19.0, -30.0),
			Vector2(23.0, -12.0), Vector2(28.0, 8.0), Vector2(14.0, 23.0),
			Vector2(-14.0, 22.0), Vector2(-28.0, 6.0)
		]), dark)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-20.0, -12.0), Vector2(-18.0, -24.0), Vector2(-7.0, -18.0),
			Vector2(2.0, -28.0), Vector2(15.0, -19.0), Vector2(20.0, -9.0),
			Vector2(21.0, 8.0), Vector2(9.0, 19.0), Vector2(-12.0, 18.0),
			Vector2(-22.0, 4.0)
		]), mid)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12.0, -6.0), Vector2(-5.0, -12.0), Vector2(2.0, -6.0),
			Vector2(11.0, -9.0), Vector2(15.0, 3.0), Vector2(7.0, 12.0),
			Vector2(-7.0, 11.0), Vector2(-14.0, 2.0)
		]), light)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-19.0, -12.0), Vector2(-24.0, -26.0), Vector2(-12.0, -18.0),
			Vector2(-7.0, -23.0), Vector2(-9.0, -10.0)
		]), highlight)
		draw_colored_polygon(PackedVector2Array([
			Vector2(13.0, -12.0), Vector2(23.0, -25.0), Vector2(22.0, -9.0),
			Vector2(12.0, -5.0)
		]), highlight)
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-13.0, -7.0), Vector2(-17.0, -17.0), Vector2(-7.0, -12.0),
			Vector2(0.0, -20.0), Vector2(8.0, -12.0), Vector2(16.0, -17.0),
			Vector2(14.0, -5.0), Vector2(15.0, 8.0), Vector2(5.0, 14.0),
			Vector2(-7.0, 13.0), Vector2(-16.0, 5.0)
		]), dark)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-11.0, -7.0), Vector2(-11.0, -13.0), Vector2(-3.0, -10.0),
			Vector2(1.0, -15.0), Vector2(8.0, -10.0), Vector2(12.0, -12.0),
			Vector2(11.0, 4.0), Vector2(5.0, 11.0), Vector2(-6.0, 10.0),
			Vector2(-12.0, 3.0)
		]), mid)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8.0, -3.0), Vector2(-4.0, -8.0), Vector2(0.0, -6.0),
			Vector2(6.0, -8.0), Vector2(9.0, -1.0), Vector2(6.0, 5.0),
			Vector2(-5.0, 5.0)
		]), light)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12.0, -7.0), Vector2(-16.0, -18.0), Vector2(-5.0, -11.0)
		]), highlight)
		draw_colored_polygon(PackedVector2Array([
			Vector2(7.0, -11.0), Vector2(16.0, -18.0), Vector2(13.0, -6.0)
		]), highlight)

	var eye_color := Color(1.0, 0.87, 0.48) if enemy_kind != "stalker" else Color(0.40, 1.0, 1.0)
	draw_rect(Rect2(-7.0, -1.0, 4.0, 3.0), eye_color, true)
	draw_rect(Rect2(3.0, -1.0, 4.0, 3.0), eye_color, true)
	draw_line(Vector2(-5.0, 5.0), Vector2(5.0, 5.0), Color(0.12, 0.035, 0.055), 1.5)

	if marked_time > 0.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -29.0), Vector2(6.0, -23.0), Vector2(0.0, -17.0), Vector2(-6.0, -23.0)
		]), Color(1.0, 0.72, 0.22))
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 28, Color(1.0, 0.56, 0.16, 0.85), 1.8)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bar_width := 34.0 * visual_scale
	var bar_y := -31.0 * visual_scale
	if is_boss:
		bar_width = 72.0
		bar_y = -72.0
	draw_rect(Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width, 4.0 * visual_scale)), Color(0.035, 0.025, 0.04, 0.92), true)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width * clampf(health / maxf(1.0, max_health), 0.0, 1.0), 4.0 * visual_scale)), Color(0.96, 0.28, 0.25), true)
	if is_boss:
		draw_rect(Rect2(Vector2(-38.0, bar_y - 4.0), Vector2(76.0, 2.0)), Color(1.0, 0.61, 0.25, 0.8), true)
