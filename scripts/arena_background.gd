extends Node2D
## Deterministic, low-cost procedural arena art. Custom geometry only; no external assets.

const TILE_W := 48
const TILE_H := 36


func _draw() -> void:
	var bounds := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	rng.seed = 734129

	draw_rect(Rect2(Vector2.ZERO, bounds), Color(0.035, 0.052, 0.065), true)

	for y in range(0, int(bounds.y) + TILE_H, TILE_H):
		for x in range(0, int(bounds.x) + TILE_W, TILE_W):
			var shade := rng.randf_range(-0.012, 0.014)
			var tile_color := Color(0.075 + shade, 0.105 + shade, 0.119 + shade)
			draw_rect(Rect2(Vector2(x + 1, y + 1), Vector2(TILE_W - 2, TILE_H - 2)), tile_color, true)
			draw_line(Vector2(x + 3, y + TILE_H - 2), Vector2(x + TILE_W - 3, y + TILE_H - 2), Color(0.13, 0.17, 0.18, 0.55), 1.0)
			draw_line(Vector2(x + TILE_W - 2, y + 3), Vector2(x + TILE_W - 2, y + TILE_H - 3), Color(0.025, 0.044, 0.052, 0.75), 1.0)

			if rng.randf() < 0.14:
				var crack_start := Vector2(x + rng.randf_range(7.0, TILE_W - 8.0), y + rng.randf_range(7.0, TILE_H - 8.0))
				draw_line(crack_start, crack_start + Vector2(rng.randf_range(3.0, 9.0), rng.randf_range(2.0, 7.0)), Color(0.025, 0.044, 0.052, 0.8), 1.0)
			if rng.randf() < 0.12:
				var moss_pos := Vector2(x + rng.randf_range(8.0, TILE_W - 8.0), y + rng.randf_range(8.0, TILE_H - 8.0))
				draw_circle(moss_pos, rng.randf_range(2.0, 5.0), Color(0.12, 0.20, 0.13, 0.48))
				draw_circle(moss_pos + Vector2(3.0, -1.0), 2.0, Color(0.18, 0.25, 0.15, 0.4))

	# Broken paving and low vegetation around the arena, with the central combat lane kept readable.
	for index in range(92):
		var point := Vector2(rng.randf_range(28.0, bounds.x - 28.0), rng.randf_range(35.0, bounds.y - 35.0))
		var central_clear := point.distance_to(bounds * 0.5) < minf(bounds.x, bounds.y) * 0.28
		if central_clear and rng.randf() < 0.82:
			continue
		if rng.randf() < 0.58:
			draw_colored_polygon(PackedVector2Array([
				point + Vector2(-4.0, 0.0),
				point + Vector2(-1.0, -3.0),
				point + Vector2(5.0, -1.0),
				point + Vector2(3.0, 3.0),
				point + Vector2(-2.0, 4.0)
			]), Color(0.15, 0.20, 0.14, 0.68))
		else:
			draw_line(point, point + Vector2(rng.randf_range(4.0, 11.0), rng.randf_range(-3.0, 4.0)), Color(0.20, 0.23, 0.22, 0.65), 2.0)

	_draw_ruin(Vector2(42.0, 47.0), 0.85)
	_draw_ruin(Vector2(bounds.x - 42.0, 47.0), 0.82)
	_draw_ruin(Vector2(42.0, bounds.y - 48.0), 0.78)
	_draw_ruin(Vector2(bounds.x - 42.0, bounds.y - 48.0), 0.9)

	# Rune stones sit against the edges and act as landmarks, not obstacles.
	_draw_rune(Vector2(bounds.x * 0.5, 27.0), 13.0)
	_draw_rune(Vector2(bounds.x * 0.5, bounds.y - 27.0), 11.0)
	_draw_rune(Vector2(25.0, bounds.y * 0.5), 10.0)
	_draw_rune(Vector2(bounds.x - 25.0, bounds.y * 0.5), 10.0)

	# Darkened perimeter creates a natural frame without covering combat silhouettes.
	draw_rect(Rect2(Vector2.ZERO, Vector2(bounds.x, 9.0)), Color(0.012, 0.02, 0.028, 0.58), true)
	draw_rect(Rect2(Vector2(0.0, bounds.y - 12.0), Vector2(bounds.x, 12.0)), Color(0.012, 0.02, 0.028, 0.58), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(8.0, bounds.y)), Color(0.012, 0.02, 0.028, 0.46), true)
	draw_rect(Rect2(Vector2(bounds.x - 8.0, 0.0), Vector2(8.0, bounds.y)), Color(0.012, 0.02, 0.028, 0.46), true)
	draw_rect(Rect2(Vector2(14.0, 14.0), bounds - Vector2(28.0, 28.0)), Color(0.35, 0.57, 0.54, 0.42), false, 2.0)


func _draw_ruin(center: Vector2, scale_factor: float) -> void:
	var shadow_size := Vector2(30.0, 15.0) * scale_factor
	draw_set_transform(center + Vector2(2.0, 7.0), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, shadow_size.x, Color(0.008, 0.014, 0.02, 0.75))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var stone := Color(0.16, 0.21, 0.23)
	var stone_light := Color(0.27, 0.32, 0.32)
	var stone_dark := Color(0.055, 0.082, 0.09)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-19.0, -5.0) * scale_factor,
		center + Vector2(-10.0, -15.0) * scale_factor,
		center + Vector2(13.0, -14.0) * scale_factor,
		center + Vector2(21.0, -3.0) * scale_factor,
		center + Vector2(15.0, 9.0) * scale_factor,
		center + Vector2(-13.0, 9.0) * scale_factor
	]), stone_dark)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-14.0, -8.0) * scale_factor,
		center + Vector2(-11.0, -25.0) * scale_factor,
		center + Vector2(7.0, -28.0) * scale_factor,
		center + Vector2(14.0, -8.0) * scale_factor,
		center + Vector2(11.0, 7.0) * scale_factor,
		center + Vector2(-11.0, 7.0) * scale_factor
	]), stone)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-11.0, -25.0) * scale_factor,
		center + Vector2(-3.0, -31.0) * scale_factor,
		center + Vector2(7.0, -28.0) * scale_factor,
		center + Vector2(12.0, -20.0) * scale_factor,
		center + Vector2(4.0, -23.0) * scale_factor
	]), stone_light)
	draw_line(center + Vector2(-8.0, -4.0) * scale_factor, center + Vector2(-2.0, 2.0) * scale_factor, Color(0.055, 0.08, 0.08), 2.0)
	draw_line(center + Vector2(3.0, -16.0) * scale_factor, center + Vector2(7.0, -9.0) * scale_factor, Color(0.07, 0.10, 0.10), 1.0)
	draw_circle(center + Vector2(-12.0, -23.0) * scale_factor, 2.0 * scale_factor, Color(0.20, 0.66, 0.55, 0.7))


func _draw_rune(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 4.0, Color(0.03, 0.08, 0.09, 0.35))
	draw_arc(center, radius, 0.0, TAU, 24, Color(0.24, 0.50, 0.44, 0.54), 1.5)
	draw_arc(center, radius * 0.62, 0.4, TAU - 0.4, 18, Color(0.34, 0.68, 0.57, 0.5), 1.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -radius * 0.42),
		center + Vector2(radius * 0.32, 0.0),
		center + Vector2(0.0, radius * 0.42),
		center + Vector2(-radius * 0.32, 0.0)
	]), Color(0.18, 0.41, 0.35, 0.55))
