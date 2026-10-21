extends Node2D

signal hit(target: Node2D, raw_damage: float)

var target: Node2D
var speed: float = 430.0
var damage: float = 12.0
var lifetime: float = 2.2
var travel_direction: Vector2 = Vector2.RIGHT
var trail_points: Array[Vector2] = []
var animation_clock: float = 0.0


func _process(delta: float) -> void:
	animation_clock += delta
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(target):
		queue_free()
		return
	if target.get("alive") == false:
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if distance <= 15.0:
		hit.emit(target, damage)
		queue_free()
		return
	if distance > 0.001:
		travel_direction = to_target / distance
		global_position += travel_direction * speed * delta
	trail_points.push_front(position)
	while trail_points.size() > 7:
		trail_points.pop_back()
	queue_redraw()


func _draw() -> void:
	for index in range(trail_points.size() - 1):
		var alpha := 0.54 * (1.0 - float(index) / maxf(1.0, float(trail_points.size())))
		draw_line(trail_points[index], trail_points[index + 1], Color(0.18, 0.88, 0.94, alpha), maxf(1.0, 4.0 - float(index) * 0.42))

	draw_circle(Vector2.ZERO, 7.0 + sin(animation_clock * 22.0) * 1.0, Color(0.12, 0.77, 0.89, 0.22))
	draw_set_transform(Vector2.ZERO, travel_direction.angle(), Vector2.ONE)
	draw_line(Vector2(-17.0, 0.0), Vector2(7.0, 0.0), Color(0.14, 0.58, 0.75, 0.78), 5.0)
	draw_line(Vector2(-12.0, 0.0), Vector2(9.0, 0.0), Color(0.47, 0.96, 1.0), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(13.0, 0.0), Vector2(4.0, -4.0), Vector2(6.0, 0.0), Vector2(4.0, 4.0)
	]), Color(0.94, 1.0, 0.88))
	draw_line(Vector2(-7.0, -3.0), Vector2(-1.0, 3.0), Color(0.91, 0.75, 0.36, 0.9), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
