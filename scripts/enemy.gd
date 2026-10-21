extends CharacterBody2D

var max_health: float = 34.0
var health: float = 34.0
var move_speed: float = 34.0
var marked_time: float = 0.0
var windup_left: float = 0.0
var attack_cooldown_left: float = 0.30
var alive: bool = true


func tick(delta: float, player_position: Vector2) -> bool:
	if not alive:
		velocity = Vector2.ZERO
		return false

	marked_time = maxf(0.0, marked_time - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	var to_player := player_position - position
	var distance := to_player.length()

	if windup_left > 0.0:
		velocity = Vector2.ZERO
		if distance > 82.0:
			windup_left = 0.0
		else:
			windup_left -= delta
			queue_redraw()
			if windup_left <= 0.0:
				attack_cooldown_left = 0.78
				move_and_slide()
				return true
			move_and_slide()
			return false

	if distance > 37.0 and distance > 0.001:
		velocity = to_player / distance * move_speed
	else:
		velocity = Vector2.ZERO
		if attack_cooldown_left <= 0.0:
			windup_left = 0.42

	move_and_slide()
	queue_redraw()
	return false


func mark(duration: float) -> void:
	marked_time = maxf(marked_time, duration)
	queue_redraw()


func cancel_telegraphed_attack() -> void:
	windup_left = 0.0
	attack_cooldown_left = maxf(attack_cooldown_left, 0.62)
	velocity = Vector2.ZERO
	queue_redraw()


func take_damage(amount: float) -> bool:
	if not alive:
		return true
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		alive = false
		velocity = Vector2.ZERO
	queue_redraw()
	return not alive


func _draw() -> void:
	# Distinctive placeholder silhouette and telegraph; replace with licensed/original art later.
	var body_color := Color(0.91, 0.29, 0.27)
	if not alive:
		body_color = Color(0.2, 0.2, 0.2)

	draw_rect(Rect2(-12.0, -10.0, 24.0, 21.0), body_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-10.0, -8.0), Vector2(-15.0, -17.0), Vector2(-3.0, -11.0)]), Color(0.58, 0.15, 0.19))
	draw_colored_polygon(PackedVector2Array([Vector2(10.0, -8.0), Vector2(15.0, -17.0), Vector2(3.0, -11.0)]), Color(0.58, 0.15, 0.19))
	draw_rect(Rect2(-5.0, -3.0, 3.0, 3.0), Color(1.0, 0.94, 0.71))
	draw_rect(Rect2(3.0, -3.0, 3.0, 3.0), Color(1.0, 0.94, 0.71))

	draw_rect(Rect2(-17.0, -24.0, 34.0, 4.0), Color(0.12, 0.10, 0.13))
	draw_rect(Rect2(-17.0, -24.0, 34.0 * (health / max_health), 4.0), Color(0.45, 0.92, 0.42))

	if marked_time > 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(0.0, -31.0), Vector2(6.0, -25.0), Vector2(0.0, -19.0), Vector2(-6.0, -25.0)]), Color(1.0, 0.58, 0.16))

	if windup_left > 0.0:
		draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 28, Color(1.0, 0.88, 0.28), 3.0)
