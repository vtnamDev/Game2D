extends Node2D
## Lightweight, short-lived chain-lightning visual in world coordinates.

var points: PackedVector2Array = PackedVector2Array()
var lifetime: float = 0.24
var _redraw_left: float = 0.0


func _process(delta: float) -> void:
	lifetime -= delta
	_redraw_left -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if _redraw_left <= 0.0:
		_redraw_left = 0.045
		queue_redraw()


func _draw() -> void:
	if points.size() < 2:
		return
	var alpha := clampf(lifetime / 0.24, 0.0, 1.0)
	for index in range(points.size() - 1):
		var from_point: Vector2 = points[index]
		var to_point: Vector2 = points[index + 1]
		var delta_point := to_point - from_point
		var normal := Vector2(-delta_point.y, delta_point.x).normalized()
		var direction := delta_point.normalized()
		var bend_a := from_point + delta_point * 0.32 + normal * (9.0 if index % 2 == 0 else -8.0)
		var bend_b := from_point + delta_point * 0.68 + normal * (-7.0 if index % 2 == 0 else 8.0)
		var bolt := PackedVector2Array([from_point, bend_a, bend_b, to_point])
		draw_polyline(bolt, Color(0.10, 0.66, 1.0, 0.36 * alpha), 8.0, true)
		draw_polyline(bolt, Color(0.34, 0.94, 1.0, 0.96 * alpha), 3.0, true)
		draw_polyline(bolt, Color(0.92, 1.0, 1.0, 0.92 * alpha), 1.1, true)
