extends CharacterBody2D

var max_health: float = 100.0
var health: float = 100.0
var move_speed: float = 185.0
var invulnerability_left: float = 0.0
var dodge_left: float = 0.0
var dodge_cooldown_left: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var last_move_direction: Vector2 = Vector2.RIGHT
var perfect_counter_left: float = 0.0


func tick(delta: float, requested_move: Vector2, bounds: Rect2) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	dodge_left = maxf(0.0, dodge_left - delta)
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	perfect_counter_left = maxf(0.0, perfect_counter_left - delta)

	var direction := requested_move.limit_length(1.0)
	if direction.length_squared() > 0.02 and dodge_left <= 0.0:
		last_move_direction = direction.normalized()

	velocity = direction * move_speed
	if dodge_left > 0.0:
		velocity = dodge_direction * 440.0
	move_and_slide()

	var bounded_position := position
	bounded_position.x = clampf(bounded_position.x, bounds.position.x, bounds.end.x)
	bounded_position.y = clampf(bounded_position.y, bounds.position.y, bounds.end.y)
	position = bounded_position
	queue_redraw()


func begin_dodge(direction: Vector2, is_perfect: bool) -> bool:
	if dodge_cooldown_left > 0.0:
		return false

	if direction.length_squared() < 0.02:
		direction = last_move_direction
	if direction.length_squared() < 0.02:
		direction = Vector2.RIGHT

	dodge_direction = direction.normalized()
	dodge_left = 0.24
	dodge_cooldown_left = 0.90
	invulnerability_left = maxf(invulnerability_left, 0.32)
	perfect_counter_left = 0.42 if is_perfect else 0.0
	return true


func is_dodging() -> bool:
	return dodge_left > 0.0


func receive_damage(amount: float) -> Dictionary:
	if invulnerability_left > 0.0:
		return {"applied": false, "dead": false}

	health = maxf(0.0, health - amount)
	invulnerability_left = 0.62
	queue_redraw()
	return {"applied": true, "dead": health <= 0.0}


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	queue_redraw()


func _draw() -> void:
	# Original placeholder geometry; final pixel-art assets are intentionally deferred.
	if perfect_counter_left > 0.0:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, Color(1.0, 0.78, 0.22, 0.95), 3.0)
	elif dodge_left > 0.0:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color(0.28, 0.9, 1.0, 0.8), 2.0)

	var body_color := Color(0.28, 0.76, 1.0)
	if invulnerability_left > 0.0 and int(invulnerability_left * 18.0) % 2 == 0:
		body_color = Color(0.78, 0.95, 1.0)

	draw_rect(Rect2(-9.0, -11.0, 18.0, 21.0), body_color)
	draw_rect(Rect2(-6.0, -16.0, 12.0, 7.0), Color(0.88, 0.94, 1.0))
	draw_rect(Rect2(-13.0, 7.0, 8.0, 6.0), Color(0.12, 0.33, 0.54))
	draw_rect(Rect2(5.0, 7.0, 8.0, 6.0), Color(0.12, 0.33, 0.54))
	draw_rect(Rect2(7.0, -3.0, 13.0, 4.0), Color(0.92, 0.88, 0.66))
