
extends Node2D
## One cached terrain texture keeps the large map cheap to render on low-end Android.
## Props use an original, compact generated pixel-art atlas.

const WORLD_SIZE := Vector2(2400.0, 1600.0)
const FLOOR_SCALE := 0.5
const TILE_W := 32
const TILE_H := 24
const PROP_ATLAS: Texture2D = preload("res://assets/art/arena_props_atlas.png")
const PROP_CELL := 64

var floor_texture: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor_texture = _build_floor_texture()
	queue_redraw()


func _build_floor_texture() -> Texture2D:
	var image_width := int(WORLD_SIZE.x * FLOOR_SCALE)
	var image_height := int(WORLD_SIZE.y * FLOOR_SCALE)
	var image := Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.025, 0.036, 0.043, 1.0))
	var rng := RandomNumberGenerator.new()

	for row in range(ceili(float(image_height) / TILE_H)):
		var y := row * TILE_H
		var stagger := TILE_W / 2 if row % 2 == 0 else 0
		for column in range(ceili(float(image_width) / TILE_W) + 1):
			var x := column * TILE_W - stagger
			if x + TILE_W < 0 or x >= image_width:
				continue
			rng.seed = int(abs(column * 73856093 + row * 19349663 + 734129))
			var shade := rng.randf_range(-0.012, 0.014)
			var stone := Color(0.067 + shade, 0.088 + shade, 0.098 + shade, 1.0)
			var stone_shadow := Color(0.007, 0.012, 0.016, 1.0)
			var stone_highlight := Color(0.18, 0.22, 0.23, 0.32)
			var left := maxi(0, x + 2)
			var top := y + 2
			var right := mini(image_width, x + TILE_W - 2)
			var bottom := mini(image_height, y + TILE_H - 2)
			if right <= left or bottom <= top:
				continue
			image.fill_rect(Rect2i(left, top, right - left, bottom - top), stone)
			# Chipped corners and varied seams create paving without thousands of draw calls.
			image.set_pixel(left, top, stone_shadow)
			image.set_pixel(mini(right - 1, left + 1), top, stone_shadow)
			image.set_pixel(right - 1, top, stone_shadow)
			image.set_pixel(left, bottom - 1, stone_shadow)
			image.set_pixel(right - 1, bottom - 1, stone_shadow)
			image.fill_rect(Rect2i(left + 2, top + 1, maxi(1, right - left - 5), 1), stone_highlight)
			if rng.randf() < 0.10:
				var crack_x := clampi(left + rng.randi_range(5, maxi(5, right - left - 7)), left, right - 1)
				var crack_y := clampi(top + rng.randi_range(5, maxi(5, bottom - top - 5)), top, bottom - 1)
				image.set_pixel(crack_x, crack_y, stone_shadow)
				image.set_pixel(mini(right - 1, crack_x + 1), mini(bottom - 1, crack_y + 1), stone_shadow)
			if rng.randf() < 0.13:
				var moss_x := clampi(left + rng.randi_range(3, maxi(3, right - left - 4)), left, right - 1)
				var moss_y := clampi(top + rng.randi_range(3, maxi(3, bottom - top - 4)), top, bottom - 1)
				var moss_color := Color(0.095, 0.15, 0.09, 1.0)
				image.set_pixel(moss_x, moss_y, moss_color)
				image.set_pixel(mini(right - 1, moss_x + 1), moss_y, moss_color)

	return ImageTexture.create_from_image(image)


func _draw() -> void:
	if floor_texture == null:
		return
	# The complete floor is a single texture submission; camera movement no longer rebuilds tile geometry.
	draw_texture_rect(floor_texture, Rect2(Vector2.ZERO, WORLD_SIZE), false, Color.WHITE)

	# Opening chamber: large landmarks, braziers and rune platforms frame the player without blocking the combat lane.
	_draw_prop(Vector2(835.0, 580.0), 0, Vector2(118.0, 126.0))
	_draw_prop(Vector2(1570.0, 575.0), 0, Vector2(126.0, 132.0))
	_draw_prop(Vector2(830.0, 1020.0), 0, Vector2(122.0, 128.0))
	_draw_prop(Vector2(1570.0, 1028.0), 0, Vector2(130.0, 134.0))
	_draw_prop(Vector2(1000.0, 580.0), 2, Vector2(64.0, 64.0))
	_draw_prop(Vector2(1400.0, 580.0), 2, Vector2(64.0, 64.0))
	_draw_prop(Vector2(1000.0, 1018.0), 2, Vector2(64.0, 64.0))
	_draw_prop(Vector2(1400.0, 1018.0), 2, Vector2(64.0, 64.0))
	_draw_prop(Vector2(1200.0, 510.0), 3, Vector2(126.0, 74.0))
	_draw_prop(Vector2(1200.0, 1090.0), 3, Vector2(126.0, 74.0))

	# Additional region landmarks make exploration readable across the full map.
	_draw_prop(Vector2(170.0, 150.0), 0, Vector2(132.0, 144.0))
	_draw_prop(Vector2(2200.0, 170.0), 0, Vector2(140.0, 144.0))
	_draw_prop(Vector2(190.0, 1440.0), 0, Vector2(136.0, 138.0))
	_draw_prop(Vector2(2210.0, 1430.0), 0, Vector2(136.0, 138.0))
	_draw_prop(Vector2(430.0, 280.0), 2, Vector2(56.0, 56.0))
	_draw_prop(Vector2(1960.0, 340.0), 2, Vector2(56.0, 56.0))
	_draw_prop(Vector2(390.0, 1300.0), 2, Vector2(56.0, 56.0))
	_draw_prop(Vector2(1980.0, 1280.0), 2, Vector2(56.0, 56.0))
	_draw_prop(Vector2(560.0, 790.0), 3, Vector2(80.0, 48.0))
	_draw_prop(Vector2(1840.0, 810.0), 3, Vector2(80.0, 48.0))
	_draw_prop(Vector2(1200.0, 210.0), 1, Vector2(138.0, 54.0))
	_draw_prop(Vector2(1200.0, 1390.0), 1, Vector2(138.0, 54.0))

	# The perimeter is visible even when the camera moves far from the start.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.32, 0.50, 0.48, 0.54), false, 3.0)


func _draw_prop(center: Vector2, atlas_index: int, draw_size: Vector2) -> void:
	var target := Rect2(center - draw_size * 0.5, draw_size)
	var source := Rect2(float(atlas_index * PROP_CELL), 0.0, PROP_CELL, PROP_CELL)
	draw_texture_rect_region(PROP_ATLAS, target, source, Color.WHITE, false, true)
