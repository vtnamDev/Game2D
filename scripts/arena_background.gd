
extends Node2D
## One cached terrain texture keeps the large map cheap to render on low-end Android.
## Props use an original, compact generated pixel-art atlas.

const WORLD_SIZE := Vector2(2400.0, 1600.0)
const PROP_ATLAS: Texture2D = preload("res://assets/art/arena_props_atlas.png")
const FLOOR_TILE: Texture2D = preload("res://assets/art/stone_floor_tile.svg")
const PROP_CELL := 64

var floor_texture: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Imported texture resources are more reliable across mobile Compatibility drivers than
	# uploading a large runtime ImageTexture during scene startup.
	floor_texture = FLOOR_TILE
	queue_redraw()


func _draw() -> void:
	# Always submit a visible ground layer before the decorative tile texture, so a texture issue
	# cannot leave the clear-color black field seen on the affected Android build.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.12, 0.16, 0.17, 1.0), true)
	if floor_texture != null:
		draw_texture_rect(floor_texture, Rect2(Vector2.ZERO, WORLD_SIZE), true, Color.WHITE)

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
