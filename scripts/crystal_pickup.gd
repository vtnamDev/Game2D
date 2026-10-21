extends Node2D
## Small, uncommon crystal drops. Movement toward the player is handled by main.gd.

var amount: int = 1
var lifetime: float = 16.0
var age: float = 0.0


func _process(delta: float) -> void:
	age += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var bob := sin(age * 4.0) * 2.0
	var size_factor := 1.0 + minf(float(amount - 1) * 0.10, 0.35)
	var center := Vector2(0.0, bob)
	draw_circle(center + Vector2(0.0, 3.0), 11.0 * size_factor, Color(0.05, 0.14, 0.17, 0.24))
	draw_arc(center, 10.0 * size_factor, age * 0.8, age * 0.8 + TAU * 0.78, 24, Color(0.18, 0.86, 0.78, 0.6), 1.5)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -9.0 * size_factor),
		center + Vector2(6.0 * size_factor, -1.0),
		center + Vector2(2.0 * size_factor, 8.0 * size_factor),
		center + Vector2(-5.0 * size_factor, 4.0 * size_factor),
		center + Vector2(-6.0 * size_factor, -3.0)
	]), Color(0.10, 0.72, 0.65))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -7.0 * size_factor),
		center + Vector2(2.0 * size_factor, -1.0),
		center + Vector2(1.0 * size_factor, 4.0 * size_factor),
		center + Vector2(-3.0 * size_factor, 1.0)
	]), Color(0.67, 1.0, 0.91))
	draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 3.0), Color(0.85, 1.0, 0.95, 0.85), 1.0)
