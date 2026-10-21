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
var action_target_position: Vector2 = Vector2.ZERO
var action_duration: float = 0.25
var visual_refresh_left: float = 0.0
var hurt_flash_left: float = 0.0
func _ready() -> void:
	# The hero is drawn by this node so it remains visible even if mobile SVG import fails.
	visible = true
	queue_redraw()


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
	visual_refresh_left -= delta
	if visual_refresh_left <= 0.0:
		visual_refresh_left = 0.04
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
	action_target_position = target_position
	match next_action:
		"slash":
			action_duration = 0.26
		"ranged":
			action_duration = 0.22
		"burst":
			action_duration = 0.58
		"ultimate":
			action_duration = 0.88
		"ice":
			action_duration = 0.58
		"lightning":
			action_duration = 0.28
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
	_draw_hero_body(bob)

	if action_time > 0.0 and action_name == "ice":
		var ice_progress := 1.0 - action_time / action_duration
		var ice_radius := lerpf(28.0, 188.0, ice_progress)
		draw_arc(Vector2.ZERO, ice_radius, ice_progress, TAU + ice_progress, 48, Color(0.18, 0.72, 1.0, 0.84 * (1.0 - ice_progress)), 4.0)
		draw_arc(Vector2.ZERO, ice_radius * 0.72, 0.0, TAU, 36, Color(0.72, 0.96, 1.0, 0.54 * (1.0 - ice_progress)), 1.8)
	elif action_time > 0.0 and action_name == "lightning":
		var target_offset := action_target_position - global_position
		if target_offset.length_squared() > 1.0:
			draw_line(Vector2.ZERO, target_offset, Color(0.22, 0.76, 1.0, 0.30), 6.0)
			draw_line(Vector2.ZERO, target_offset, Color(0.80, 0.98, 1.0, 0.90), 1.6)
	elif action_time > 0.0 and action_name == "burst":
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


func _draw_hero_body(bob: float) -> void:
	var is_hurt := hurt_flash_left > 0.0
	var is_dodging := dodge_left > 0.0
	var cloak_color := Color(0.10, 0.29, 0.38)
	var armor_color := Color(0.22, 0.53, 0.61)
	if is_hurt:
		cloak_color = Color(0.62, 0.18, 0.20)
		armor_color = Color(0.96, 0.43, 0.39)
	elif is_dodging:
		cloak_color = Color(0.10, 0.62, 0.72)
		armor_color = Color(0.52, 0.98, 1.0)

	# Local art faces upward; rotate it toward the current movement/aim direction.
	draw_set_transform(Vector2(0.0, bob), facing_direction.angle() + PI * 0.5, Vector2.ONE)

	# Sword is layered behind the shoulder and body.
	draw_line(Vector2(8.0, -7.0), Vector2(22.0, -29.0), Color(0.018, 0.035, 0.052), 6.0)
	draw_line(Vector2(8.0, -7.0), Vector2(22.0, -29.0), Color(0.56, 0.84, 0.87), 3.2)
	draw_line(Vector2(12.0, -14.0), Vector2(24.0, -32.0), Color(0.95, 1.0, 0.91), 1.1)
	draw_line(Vector2(3.0, -10.0), Vector2(13.0, -3.0), Color(0.07, 0.10, 0.12), 4.0)
	draw_line(Vector2(3.0, -10.0), Vector2(11.0, -4.0), Color(0.88, 0.61, 0.28), 2.1)

	# Outer cloak silhouette and stepped hem make the actor readable against stone.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10.0, -10.0), Vector2(-8.0, -16.0), Vector2(-3.0, -18.0),
		Vector2(5.0, -17.0), Vector2(10.0, -12.0), Vector2(12.0, -5.0),
		Vector2(10.0, 4.0), Vector2(7.0, 12.0), Vector2(3.0, 16.0),
		Vector2(-7.0, 15.0), Vector2(-11.0, 9.0), Vector2(-14.0, 1.0),
		Vector2(-12.0, -6.0)
	]), Color(0.018, 0.040, 0.058))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -9.0), Vector2(-6.0, -14.0), Vector2(-2.0, -16.0),
		Vector2(4.0, -15.0), Vector2(8.0, -10.0), Vector2(10.0, -4.0),
		Vector2(8.0, 4.0), Vector2(5.0, 10.0), Vector2(2.0, 13.0),
		Vector2(-6.0, 12.0), Vector2(-9.0, 7.0), Vector2(-11.0, 1.0),
		Vector2(-9.0, -5.0)
	]), cloak_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -3.0), Vector2(-4.0, -8.0), Vector2(4.0, -8.0),
		Vector2(7.0, -3.0), Vector2(5.0, 5.0), Vector2(2.0, 8.0),
		Vector2(-4.0, 8.0), Vector2(-7.0, 4.0)
	]), armor_color)

	# Boots, shoulder plates, belt and a bright sash give the hero a clear silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(-8.0, 7.0), Vector2(-2.0, 8.0), Vector2(-3.0, 14.0), Vector2(-8.0, 15.0), Vector2(-10.0, 12.0)]), Color(0.025, 0.045, 0.059))
	draw_colored_polygon(PackedVector2Array([Vector2(2.0, 8.0), Vector2(8.0, 6.0), Vector2(10.0, 11.0), Vector2(7.0, 15.0), Vector2(2.0, 14.0)]), Color(0.025, 0.045, 0.059))
	draw_line(Vector2(-6.0, 2.0), Vector2(5.0, 0.0), Color(0.90, 0.63, 0.28), 2.3)
	draw_colored_polygon(PackedVector2Array([Vector2(-10.0, -8.0), Vector2(-7.0, -12.0), Vector2(-3.0, -10.0), Vector2(-4.0, -5.0), Vector2(-8.0, -4.0)]), Color(0.62, 0.46, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(4.0, -11.0), Vector2(8.0, -12.0), Vector2(11.0, -8.0), Vector2(8.0, -4.0), Vector2(4.0, -6.0)]), Color(0.68, 0.52, 0.29))
	draw_line(Vector2(-7.0, -7.0), Vector2(-2.0, 1.0), Color(0.72, 0.91, 0.87, 0.9), 1.3)
	draw_line(Vector2(2.0, -6.0), Vector2(5.0, 2.0), Color(0.06, 0.14, 0.19), 1.5)

	# Head, hair and face are drawn last so the character does not read as a colored blob.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -18.0), Vector2(-5.0, -22.0), Vector2(2.0, -23.0),
		Vector2(7.0, -19.0), Vector2(6.0, -12.0), Vector2(2.0, -9.0),
		Vector2(-4.0, -10.0), Vector2(-7.0, -14.0)
	]), Color(0.018, 0.030, 0.043))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0, -18.0), Vector2(-2.0, -20.0), Vector2(3.0, -19.0),
		Vector2(4.0, -14.0), Vector2(1.0, -11.0), Vector2(-3.0, -12.0),
		Vector2(-5.0, -15.0)
	]), Color(0.72, 0.48, 0.34))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6.0, -18.0), Vector2(-4.0, -22.0), Vector2(2.0, -23.0),
		Vector2(7.0, -20.0), Vector2(5.0, -17.0), Vector2(0.0, -18.0),
		Vector2(-3.0, -16.0), Vector2(-5.0, -14.0)
	]), Color(0.025, 0.044, 0.056))
	draw_line(Vector2(-3.0, -15.0), Vector2(-1.0, -14.0), Color(0.98, 0.83, 0.64), 1.2)
	draw_line(Vector2(1.0, -15.0), Vector2(3.0, -15.0), Color(0.98, 0.83, 0.64), 1.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-7.0, -20.0), Vector2(-11.0, -25.0), Vector2(-5.0, -22.0)]), Color(0.18, 0.55, 0.66))
	draw_colored_polygon(PackedVector2Array([Vector2(5.0, -21.0), Vector2(10.0, -24.0), Vector2(7.0, -18.0)]), Color(0.18, 0.55, 0.66))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
