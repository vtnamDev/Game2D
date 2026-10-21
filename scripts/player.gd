extends CharacterBody2D

var max_health: float = 100.0
var health: float = 100.0
var max_energy: float = 100.0
var energy: float = 100.0
var energy_regen: float = 5.0
var move_speed: float = 185.0
var invulnerability_left: float = 0.0
var dodge_left: float = 0.0
var dodge_cooldown_left: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var last_move_direction: Vector2 = Vector2.RIGHT
var facing_direction: Vector2 = Vector2.RIGHT
var perfect_counter_left: float = 0.0
var animation_clock: float = 0.0
var action_name: String = ""
var action_time: float = 0.0
var action_duration: float = 0.25
var hurt_flash_left: float = 0.0
var visual_sprite: Sprite2D


func _ready() -> void:
	visual_sprite = Sprite2D.new()
	visual_sprite.texture = load("res://assets/art/hero_swordmaster.svg") as Texture2D
	visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_sprite.scale = Vector2(0.86, 0.86)
	visual_sprite.show_behind_parent = true
	add_child(visual_sprite)


func tick(delta: float, requested_move: Vector2, bounds: Rect2) -> void:
	animation_clock += delta
	energy = minf(max_energy, energy + energy_regen * delta)
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	dodge_left = maxf(0.0, dodge_left - delta)
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	perfect_counter_left = maxf(0.0, perfect_counter_left - delta)
	action_time = maxf(0.0, action_time - delta)
	hurt_flash_left = maxf(0.0, hurt_flash_left - delta)

	var direction := requested_move.limit_length(1.0)
	if direction.length_squared() > 0.02 and dodge_left <= 0.0:
		last_move_direction = direction.normalized()
		facing_direction = last_move_direction

	velocity = direction * move_speed
	if dodge_left > 0.0:
		velocity = dodge_direction * 440.0
	move_and_slide()

	var bounded_position := position
	bounded_position.x = clampf(bounded_position.x, bounds.position.x, bounds.end.x)
	bounded_position.y = clampf(bounded_position.y, bounds.position.y, bounds.end.y)
	position = bounded_position
	if is_instance_valid(visual_sprite):
		visual_sprite.rotation = facing_direction.angle()
		if hurt_flash_left > 0.0:
			visual_sprite.modulate = Color(1.0, 0.56, 0.52, 1.0)
		elif dodge_left > 0.0:
			visual_sprite.modulate = Color(0.48, 0.98, 1.0, 1.0)
		else:
			visual_sprite.modulate = Color.WHITE
	queue_redraw()


func begin_dodge(direction: Vector2, is_perfect: bool) -> bool:
	if dodge_cooldown_left > 0.0:
		return false

	if direction.length_squared() < 0.02:
		direction = last_move_direction
	if direction.length_squared() < 0.02:
		direction = Vector2.RIGHT

	dodge_direction = direction.normalized()
	facing_direction = dodge_direction
	dodge_left = 0.22
	dodge_cooldown_left = 1.15
	invulnerability_left = maxf(invulnerability_left, 0.30)
	perfect_counter_left = 0.48 if is_perfect else 0.0
	play_action("dodge")
	return true


func play_action(next_action: String, target_position: Vector2 = Vector2.ZERO) -> void:
	action_name = next_action
	match next_action:
		"slash":
			action_duration = 0.26
		"ranged":
			action_duration = 0.22
		"burst":
			action_duration = 0.58
		"ultimate":
			action_duration = 0.88
		"dodge":
			action_duration = 0.22
		_:
			action_duration = 0.20
	action_time = action_duration
	if target_position != Vector2.ZERO and target_position.distance_squared_to(position) > 1.0:
		var direction := (target_position - position).normalized()
		if direction.length_squared() > 0.01:
			facing_direction = direction
	queue_redraw()


func spend_energy(amount: float) -> bool:
	if energy + 0.001 < amount:
		return false
	energy = maxf(0.0, energy - amount)
	queue_redraw()
	return true


func restore_energy(amount: float) -> void:
	energy = minf(max_energy, energy + maxf(0.0, amount))
	queue_redraw()


func is_dodging() -> bool:
	return dodge_left > 0.0


func receive_damage(amount: float) -> Dictionary:
	if invulnerability_left > 0.0:
		return {"applied": false, "dead": false}

	health = maxf(0.0, health - amount)
	invulnerability_left = 0.62
	hurt_flash_left = 0.18
	queue_redraw()
	return {"applied": true, "dead": health <= 0.0}


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	queue_redraw()


func _draw() -> void:
	var bob := sin(animation_clock * 10.0) * 1.1 if velocity.length_squared() > 20.0 else sin(animation_clock * 2.5) * 0.35

	# Contact shadow, ground-targeted spell rings, and weapon trails are kept separate from the sprite.
	draw_set_transform(Vector2(1.0, 8.0 + bob), 0.0, Vector2(1.42, 0.57))
	draw_circle(Vector2.ZERO, 14.0, Color(0.005, 0.012, 0.02, 0.68))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if action_time > 0.0 and action_name == "burst":
		var progress := 1.0 - action_time / action_duration
		var radius := lerpf(20.0, 148.0, progress)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(0.14, 0.94, 0.80, 0.90 * (1.0 - progress)), 4.0)
		draw_arc(Vector2.ZERO, radius * 0.78, 0.2, TAU - 0.2, 48, Color(0.80, 0.95, 0.70, 0.66 * (1.0 - progress)), 1.6)
	elif action_time > 0.0 and action_name == "ultimate":
		var progress := 1.0 - action_time / action_duration
		var radius := lerpf(34.0, 226.0, progress)
		draw_arc(Vector2.ZERO, radius, progress * 2.0, TAU + progress * 2.0, 64, Color(0.26, 0.90, 1.0, 0.95 * (1.0 - progress)), 6.0)
		draw_arc(Vector2.ZERO, radius * 0.82, 0.0, TAU, 48, Color(0.95, 0.68, 0.28, 0.68 * (1.0 - progress)), 2.0)

	if energy >= max_energy - 0.1:
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 36, Color(0.22, 0.86, 0.92, 0.55), 1.5)
	if perfect_counter_left > 0.0:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 36, Color(1.0, 0.79, 0.30, 0.95), 3.0)
	elif dodge_left > 0.0:
		draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 32, Color(0.32, 0.94, 1.0, 0.90), 2.5)

	draw_set_transform(Vector2.ZERO, facing_direction.angle(), Vector2.ONE)
	if action_time > 0.0 and action_name == "slash":
		var progress := 1.0 - action_time / action_duration
		draw_arc(Vector2(5.0, -1.0), 33.0, -1.05 + progress * 0.28, 1.05 + progress * 0.28, 28, Color(0.77, 0.99, 0.96, 0.94), 4.0)
		draw_arc(Vector2(5.0, -1.0), 27.0, -0.86 + progress * 0.28, 0.86 + progress * 0.28, 24, Color(0.33, 0.82, 0.92, 0.72), 2.0)
	elif action_time > 0.0 and action_name == "ranged":
		draw_line(Vector2(7.0, -4.0), Vector2(42.0, -4.0), Color(0.31, 0.94, 0.93, 0.82), 2.5)
		draw_circle(Vector2(41.0, -4.0), 3.0, Color(0.85, 1.0, 0.94, 0.94))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
