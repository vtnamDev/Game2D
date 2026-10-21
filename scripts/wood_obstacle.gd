extends StaticBody2D
## A low-cost timber barricade with a matching physical collider.

var plank_length: float = 88.0
var plank_thickness: float = 22.0


func configure(length: float, thickness: float) -> void:
	plank_length = maxf(54.0, length)
	plank_thickness = maxf(16.0, thickness)
	collision_layer = 4
	collision_mask = 0
	add_to_group("arena_obstacle")

	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(plank_length, plank_thickness + 4.0)
	collider.shape = shape
	add_child(collider)
	queue_redraw()


func _draw() -> void:
	var half_length := plank_length * 0.5
	var half_thickness := plank_thickness * 0.5

	# Ground shadow keeps the log separate from the paving.
	draw_set_transform(Vector2(3.0, 9.0), 0.0, Vector2(1.0, 0.48))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half_length - 5.0, -half_thickness),
		Vector2(half_length - 1.0, -half_thickness - 2.0),
		Vector2(half_length + 7.0, 0.0),
		Vector2(half_length - 1.0, half_thickness + 5.0),
		Vector2(-half_length + 3.0, half_thickness + 4.0),
		Vector2(-half_length - 6.0, 0.0)
	]), Color(0.005, 0.009, 0.012, 0.78))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Dark stepped silhouette, two oak beams, and a chipped upper highlight.
	_draw_beam(-5.0, half_length, half_thickness * 0.42, Color(0.18, 0.095, 0.045), Color(0.47, 0.27, 0.12))
	_draw_beam(5.0, half_length, half_thickness * 0.40, Color(0.14, 0.071, 0.035), Color(0.38, 0.21, 0.09))

	# Rope and iron bindings add readable detail without expensive textures.
	for fraction in [-0.28, 0.28]:
		var ratio: float = float(fraction)
		var x: float = plank_length * ratio
		draw_rect(Rect2(x - 2.4, -half_thickness - 1.0, 4.8, plank_thickness + 2.0), Color(0.13, 0.16, 0.16), true)
		draw_rect(Rect2(x - 1.1, -half_thickness - 1.0, 2.2, plank_thickness + 2.0), Color(0.62, 0.45, 0.24), true)
		draw_circle(Vector2(x, -half_thickness + 2.0), 1.5, Color(0.93, 0.77, 0.45))
		draw_circle(Vector2(x, half_thickness - 2.0), 1.3, Color(0.06, 0.08, 0.08))

	# Grain, cracks, and a pale edge catch the ambient light.
	for fraction in [-0.39, -0.12, 0.16, 0.39]:
		var ratio: float = float(fraction)
		var x: float = plank_length * ratio
		draw_line(Vector2(x - 5.0, -half_thickness * 0.56), Vector2(x + 4.0, -half_thickness * 0.45), Color(0.78, 0.49, 0.24, 0.62), 1.0)
	draw_line(Vector2(-half_length + 8.0, -half_thickness + 1.5), Vector2(half_length - 8.0, -half_thickness + 1.5), Color(0.96, 0.71, 0.39, 0.62), 1.2)
	draw_line(Vector2(-half_length + 7.0, half_thickness - 1.0), Vector2(half_length - 7.0, half_thickness - 1.0), Color(0.07, 0.045, 0.026, 0.9), 1.2)


func _draw_beam(y_offset: float, half_length: float, half_height: float, shadow_color: Color, wood_color: Color) -> void:
	var outline := PackedVector2Array([
		Vector2(-half_length, y_offset - half_height + 3.0),
		Vector2(-half_length + 4.0, y_offset - half_height),
		Vector2(half_length - 4.0, y_offset - half_height),
		Vector2(half_length, y_offset - half_height + 3.0),
		Vector2(half_length - 2.0, y_offset + half_height - 2.0),
		Vector2(half_length - 6.0, y_offset + half_height),
		Vector2(-half_length + 4.0, y_offset + half_height),
		Vector2(-half_length, y_offset + half_height - 3.0)
	])
	draw_colored_polygon(outline, shadow_color)
	var inset := PackedVector2Array([
		Vector2(-half_length + 4.0, y_offset - half_height + 2.0),
		Vector2(half_length - 5.0, y_offset - half_height + 2.0),
		Vector2(half_length - 3.0, y_offset + half_height - 2.0),
		Vector2(-half_length + 4.0, y_offset + half_height - 2.0)
	])
	draw_colored_polygon(inset, wood_color)
