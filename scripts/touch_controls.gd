extends Control

signal movement_changed(direction: Vector2)
signal start_requested
signal melee_pressed
signal shoot_pressed
signal dodge_pressed
signal pause_pressed
signal resume_requested
signal restart_requested
signal upgrade_selected(index: int)
signal unlock_pressed

var move_vector: Vector2 = Vector2.ZERO
var game_state: String = "menu"
var stats: Dictionary = {}
var message: String = ""
var joystick_touch_id: int = -1

const JOYSTICK_RADIUS := 62.0
const DEAD_ZONE := 0.14


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_game_state(next_state: String, next_stats: Dictionary, next_message: String) -> void:
	game_state = next_state
	stats = next_stats.duplicate()
	message = next_message
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.index, event.position)
		else:
			_handle_release(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_id:
			_update_joystick(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_press(-2, event.position)
		else:
			_handle_release(-2)
		accept_event()
	elif event is InputEventMouseMotion and joystick_touch_id == -2:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_joystick(event.position)
		accept_event()


func _handle_press(pointer_id: int, point: Vector2) -> void:
	match game_state:
		"menu":
			if _start_rect().has_point(point):
				start_requested.emit()
				return
			if _unlock_rect().has_point(point):
				unlock_pressed.emit()
				return
		"playing":
			if _pause_rect().has_point(point):
				pause_pressed.emit()
				return
			if _button_center("melee").distance_to(point) <= 43.0:
				melee_pressed.emit()
				return
			if _button_center("shoot").distance_to(point) <= 43.0:
				shoot_pressed.emit()
				return
			if _button_center("dodge").distance_to(point) <= 43.0:
				dodge_pressed.emit()
				return
			if joystick_touch_id == -1 and point.x <= size.x * 0.43 and point.y >= size.y * 0.42:
				joystick_touch_id = pointer_id
				_update_joystick(point)
				return
		"paused":
			if _resume_rect().has_point(point):
				resume_requested.emit()
				return
			if _restart_rect().has_point(point):
				restart_requested.emit()
				return
		"upgrade":
			for index in range(3):
				if _upgrade_rect(index).has_point(point):
					upgrade_selected.emit(index)
					return
		"won", "lost":
			if _restart_rect().has_point(point):
				restart_requested.emit()
				return


func _handle_release(pointer_id: int) -> void:
	if pointer_id == joystick_touch_id:
		joystick_touch_id = -1
		move_vector = Vector2.ZERO
		movement_changed.emit(move_vector)
		queue_redraw()


func _update_joystick(point: Vector2) -> void:
	var offset := point - _joystick_center()
	var strength := minf(1.0, offset.length() / JOYSTICK_RADIUS)
	if strength < DEAD_ZONE:
		move_vector = Vector2.ZERO
	else:
		move_vector = offset.normalized() * strength
	movement_changed.emit(move_vector)
	queue_redraw()


func _joystick_center() -> Vector2:
	return Vector2(92.0, size.y - 91.0)


func _button_center(which: String) -> Vector2:
	match which:
		"melee":
			return Vector2(size.x - 82.0, size.y - 87.0)
		"shoot":
			return Vector2(size.x - 177.0, size.y - 155.0)
		"dodge":
			return Vector2(size.x - 82.0, size.y - 178.0)
	return Vector2.ZERO


func _pause_rect() -> Rect2:
	return Rect2(size.x - 59.0, 8.0, 48.0, 36.0)


func _start_rect() -> Rect2:
	return Rect2((size.x - 230.0) * 0.5, size.y * 0.56, 230.0, 56.0)


func _unlock_rect() -> Rect2:
	return Rect2((size.x - 290.0) * 0.5, size.y * 0.70, 290.0, 48.0)


func _resume_rect() -> Rect2:
	return Rect2((size.x - 210.0) * 0.5, size.y * 0.53, 210.0, 52.0)


func _restart_rect() -> Rect2:
	return Rect2((size.x - 210.0) * 0.5, size.y * 0.65, 210.0, 52.0)


func _upgrade_rect(index: int) -> Rect2:
	var card_width := 172.0
	var gap := 13.0
	var total_width := card_width * 3.0 + gap * 2.0
	var start_x := (size.x - total_width) * 0.5
	return Rect2(start_x + index * (card_width + gap), size.y * 0.47, card_width, 126.0)


func _draw() -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return

	if game_state == "menu":
		_draw_menu(font)
	elif game_state == "playing":
		_draw_hud(font)
		_draw_controls(font)
	elif game_state == "paused":
		_draw_hud(font)
		_draw_overlay(font, "PAUSED", "The simulation is paused.")
		_draw_button_rect(font, _resume_rect(), "RESUME")
		_draw_button_rect(font, _restart_rect(), "NEW RUN")
	elif game_state == "upgrade":
		_draw_hud(font)
		_draw_upgrade_overlay(font)
	elif game_state == "won":
		_draw_result_overlay(font, true)
	elif game_state == "lost":
		_draw_result_overlay(font, false)


func _draw_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.04, 0.83), true)
	_draw_centered(font, "GAME2D", Vector2(size.x * 0.5, size.y * 0.22), 36, Color(0.85, 0.94, 1.0))
	_draw_centered(font, "EMBER & COUNTER  /  COMBAT PROTOTYPE", Vector2(size.x * 0.5, size.y * 0.32), 17, Color(1.0, 0.72, 0.27))
	_draw_centered(font, "Melee marks an enemy. Shoot the marked target to trigger an ember combo.", Vector2(size.x * 0.5, size.y * 0.42), 14, Color(0.82, 0.88, 0.93))
	_draw_centered(font, "Dodge during the enemy warning ring to counterattack.", Vector2(size.x * 0.5, size.y * 0.47), 14, Color(0.82, 0.88, 0.93))
	_draw_button_rect(font, _start_rect(), "START 5-MIN RUN")
	var relic_text := "COUNTER RELIC UNLOCKED" if bool(stats.get("unlocked_relic", false)) else "UNLOCK COUNTER RELIC - 20 CRYSTALS"
	_draw_button_rect(font, _unlock_rect(), relic_text)
	_draw_centered(font, "Saved crystals: %d" % int(stats.get("crystals", 0)), Vector2(size.x * 0.5, size.y * 0.84), 15, Color(0.9, 0.83, 0.63))
	if message != "":
		_draw_centered(font, message, Vector2(size.x * 0.5, size.y * 0.89), 14, Color(1.0, 0.78, 0.44))
	_draw_centered(font, "Keyboard: arrows move, Space melee, F shoot, Shift dodge, Esc pause.", Vector2(size.x * 0.5, size.y * 0.96), 12, Color(0.62, 0.69, 0.75))


func _draw_hud(font: Font) -> void:
	draw_rect(Rect2(10.0, 9.0, 280.0, 77.0), Color(0.02, 0.035, 0.055, 0.78), true)
	var seconds := maxi(0, int(stats.get("time_left", 300)))
	var minutes := int(floor(float(seconds) / 60.0))
	var remainder := seconds % 60
	draw_string(font, Vector2(20.0, 32.0), "%02d:%02d" % [minutes, remainder], HORIZONTAL_ALIGNMENT_LEFT, 100.0, 23, Color(0.95, 0.96, 1.0))
	draw_string(font, Vector2(128.0, 31.0), "KOs %d" % int(stats.get("kills", 0)), HORIZONTAL_ALIGNMENT_LEFT, 110.0, 17, Color(0.94, 0.84, 0.59))
	var health_ratio := clampf(float(stats.get("health", 0.0)) / maxf(1.0, float(stats.get("max_health", 100.0))), 0.0, 1.0)
	draw_rect(Rect2(20.0, 43.0, 192.0, 10.0), Color(0.18, 0.20, 0.23), true)
	draw_rect(Rect2(20.0, 43.0, 192.0 * health_ratio, 10.0), Color(0.91, 0.27, 0.29), true)
	draw_string(font, Vector2(20.0, 72.0), "XP %d/%d   Crystals %d" % [int(stats.get("xp", 0)), int(stats.get("xp_required", 3)), int(stats.get("crystals", 0))], HORIZONTAL_ALIGNMENT_LEFT, 255.0, 14, Color(0.72, 0.86, 0.94))
	draw_rect(_pause_rect(), Color(0.07, 0.10, 0.14, 0.82), true)
	draw_string(font, Vector2(size.x - 54.0, 32.0), "II", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 20, Color.WHITE)


func _draw_controls(font: Font) -> void:
	var center := _joystick_center()
	draw_circle(center, JOYSTICK_RADIUS, Color(0.10, 0.15, 0.20, 0.57))
	draw_arc(center, JOYSTICK_RADIUS, 0.0, TAU, 36, Color(0.72, 0.84, 0.91, 0.56), 2.0)
	draw_circle(center + move_vector * 33.0, 23.0, Color(0.55, 0.74, 0.86, 0.82))
	_draw_action_button(font, _button_center("melee"), 36.0, "MELEE", Color(0.61, 0.26, 0.21, 0.9))
	_draw_action_button(font, _button_center("shoot"), 33.0, "SHOOT", Color(0.71, 0.47, 0.15, 0.9))
	_draw_action_button(font, _button_center("dodge"), 33.0, "DODGE", Color(0.15, 0.48, 0.61, 0.9))
	if message != "":
		_draw_centered(font, message, Vector2(size.x * 0.5, size.y - 24.0), 15, Color(1.0, 0.86, 0.42))


func _draw_upgrade_overlay(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.035, 0.84), true)
	_draw_centered(font, "LEVEL UP - CHOOSE ONE", Vector2(size.x * 0.5, size.y * 0.25), 28, Color(1.0, 0.82, 0.36))
	_draw_centered(font, "Combat simulation is paused until you choose.", Vector2(size.x * 0.5, size.y * 0.34), 15, Color(0.84, 0.89, 0.94))
	var titles := ["EMBER EDGE", "ARC SHOT", "VITALITY"]
	var descriptions := ["Melee damage +5\nLonger mark duration", "Projectile damage +4\nRange +30", "Max health +15\nHeal 15 now"]
	for index in range(3):
		var rect := _upgrade_rect(index)
		draw_rect(rect, Color(0.10, 0.15, 0.20, 0.96), true)
		draw_rect(rect, Color(0.72, 0.82, 0.88, 0.85), false, 2.0)
		draw_string(font, Vector2(rect.position.x + 10.0, rect.position.y + 28.0), titles[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 16, Color(1.0, 0.76, 0.31))
		var lines: PackedStringArray = descriptions[index].split("\n")
		for line_index in range(lines.size()):
			draw_string(font, Vector2(rect.position.x + 10.0, rect.position.y + 60.0 + line_index * 22.0), lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 13, Color(0.87, 0.91, 0.94))


func _draw_result_overlay(font: Font, won: bool) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.035, 0.86), true)
	_draw_centered(font, "SURVIVED" if won else "RUN OVER", Vector2(size.x * 0.5, size.y * 0.31), 34, Color(0.64, 0.96, 0.68) if won else Color(1.0, 0.43, 0.38))
	_draw_centered(font, "KOs: %d    Run reward: %d crystals" % [int(stats.get("kills", 0)), int(stats.get("run_reward", 0))], Vector2(size.x * 0.5, size.y * 0.43), 18, Color(0.89, 0.91, 0.94))
	_draw_centered(font, "Total saved crystals: %d" % int(stats.get("crystals", 0)), Vector2(size.x * 0.5, size.y * 0.50), 15, Color(0.93, 0.82, 0.52))
	_draw_button_rect(font, _restart_rect(), "PLAY AGAIN")


func _draw_overlay(font: Font, title: String, subtitle: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.035, 0.76), true)
	_draw_centered(font, title, Vector2(size.x * 0.5, size.y * 0.37), 32, Color(0.94, 0.96, 1.0))
	_draw_centered(font, subtitle, Vector2(size.x * 0.5, size.y * 0.45), 15, Color(0.82, 0.88, 0.93))


func _draw_action_button(font: Font, center: Vector2, radius: float, title: String, fill: Color) -> void:
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 32, Color(0.92, 0.94, 0.96, 0.84), 2.0)
	draw_string(font, Vector2(center.x - 45.0, center.y + 5.0), title, HORIZONTAL_ALIGNMENT_CENTER, 90.0, 13, Color.WHITE)


func _draw_button_rect(font: Font, rect: Rect2, title: String) -> void:
	draw_rect(rect, Color(0.09, 0.17, 0.23, 0.97), true)
	draw_rect(rect, Color(0.72, 0.83, 0.89), false, 2.0)
	draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + rect.size.y * 0.58), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 15, Color(0.95, 0.96, 1.0))


func _draw_centered(font: Font, text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	draw_string(font, Vector2(size.x * 0.04, baseline.y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.92, font_size, color)
