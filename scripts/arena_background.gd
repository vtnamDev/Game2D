extends Node2D
## Camera-aware, low-cost stone arena. Only tiles near the camera are submitted for drawing.

const WORLD_SIZE := Vector2(2400.0, 1600.0)
const TILE_W := 64
const TILE_H := 48

var _last_camera_cell := Vector2i(-999, -999)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if not is_instance_valid(camera):
		return
	var camera_cell := Vector2i(floori(camera.global_position.x / TILE_W), floori(camera.global_position.y / TILE_H))
	if camera_cell != _last_camera_cell:
		_last_camera_cell = camera_cell
		queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var center: Vector2 = camera.global_position if is_instance_valid(camera) else WORLD_SIZE * 0.5
	var view_size := get_viewport_rect().size
	var left := maxi(0, floori((center.x - view_size.x * 0.5) / TILE_W) - 2)
	var right := mini(ceili(WORLD_SIZE.x / TILE_W), ceili((center.x + view_size.x * 0.5) / TILE_W) + 2)
	var top := maxi(0, floori((center.y - view_size.y * 0.5) / TILE_H) - 2)
	var bottom := mini(ceili(WORLD_SIZE.y / TILE_H), ceili((center.y + view_size.y * 0.5) / TILE_H) + 2)

	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.025, 0.036, 0.043), true)
	var rng := RandomNumberGenerator.new()
	for row in range(top, bottom):
		for column in range(left, right):
			rng.seed = int(abs(column * 73856093 + row * 19349663 + 734129))
			var x := float(column * TILE_W)
			var y := float(row * TILE_H)
			var shade := rng.randf_range(-0.012, 0.014)
			var chip := rng.randf_range(1.0, 5.0)
			var points := PackedVector2Array([
				Vector2(x + 4.0, y + 2.0),
				Vector2(x + TILE_W - 5.0, y + 1.0 + chip * 0.2),
				Vector2(x + TILE_W - 1.5, y + TILE_H * 0.38),
				Vector2(x + TILE_W - 5.0, y + TILE_H - 3.0),
				Vector2(x + 5.0 + chip, y + TILE_H - 1.5),
				Vector2(x + 1.5, y + TILE_H * 0.58)
			])
			draw_colored_polygon(points, Color(0.006, 0.010, 0.014, 0.42))
			draw_colored_polygon(points, Color(0.067 + shade, 0.088 + shade, 0.098 + shade))
			draw_line(Vector2(x + 8.0, y + 4.0), Vector2(x + TILE_W - 10.0, y + 3.0 + chip * 0.2), Color(0.20, 0.25, 0.26, 0.15), 1.0)

			if rng.randf() < 0.10:
				var crack := Vector2(x + rng.randf_range(10.0, TILE_W - 10.0), y + rng.randf_range(10.0, TILE_H - 10.0))
				draw_line(crack, crack + Vector2(rng.randf_range(4.0, 12.0), rng.randf_range(2.0, 7.0)), Color(0.015, 0.026, 0.030, 0.9), 1.2)
			if rng.randf() < 0.13:
				var moss := Vector2(x + rng.randf_range(8.0, TILE_W - 8.0), y + rng.randf_range(8.0, TILE_H - 8.0))
				draw_circle(moss, rng.randf_range(2.0, 4.0), Color(0.11, 0.18, 0.10, 0.42))

	# A few fixed landmarks give the expanded map readable regions without lighting shaders.
	_draw_ruin(Vector2(120.0, 115.0), 0.8)
	_draw_ruin(Vector2(WORLD_SIZE.x - 120.0, 130.0), 0.9)
	_draw_ruin(Vector2(145.0, WORLD_SIZE.y - 120.0), 0.85)
	_draw_ruin(Vector2(WORLD_SIZE.x - 145.0, WORLD_SIZE.y - 125.0), 1.0)

	# The perimeter is a real visual cue for the edge of the world.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.32, 0.50, 0.48, 0.50), false, 3.0)


func _draw_ruin(center: Vector2, scale_factor: float) -> void:
	var half := Vector2(20.0, 25.0) * scale_factor
	draw_set_transform(center + Vector2(3.0, 7.0), 0.0, Vector2(1.0, 0.48))
	draw_circle(Vector2.ZERO, 30.0 * scale_factor, Color(0.004, 0.008, 0.012, 0.72))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-half.x - 4.0, -half.y * 0.3),
		center + Vector2(-half.x * 0.6, -half.y),
		center + Vector2(half.x * 0.7, -half.y * 0.95),
		center + Vector2(half.x + 4.0, -half.y * 0.25),
		center + Vector2(half.x * 0.75, half.y * 0.4),
		center + Vector2(-half.x * 0.7, half.y * 0.4)
	]), Color(0.045, 0.066, 0.072))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-half.x * 0.7, -half.y * 0.35),
		center + Vector2(-half.x * 0.55, -half.y * 0.95),
		center + Vector2(half.x * 0.30, -half.y * 0.84),
		center + Vector2(half.x * 0.62, -half.y * 0.20),
		center + Vector2(half.x * 0.42, half.y * 0.34),
		center + Vector2(-half.x * 0.45, half.y * 0.34)
	]), Color(0.17, 0.22, 0.23))
	draw_line(center + Vector2(-half.x * 0.4, -half.y * 0.4), center + Vector2(-2.0, 3.0), Color(0.035, 0.052, 0.055), 2.0)
	draw_circle(center + Vector2(-half.x * 0.3, -half.y * 0.65), 2.5 * scale_factor, Color(0.16, 0.65, 0.50, 0.64))
