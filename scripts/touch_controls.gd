extends Control

signal movement_changed(direction: Vector2)
signal start_requested
signal melee_pressed
signal shoot_pressed
signal dodge_pressed
signal skill_pressed
signal ultimate_pressed
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
var action_flash: Dictionary = {
	"melee": 0.0,
	"shoot": 0.0,
	"dodge": 0.0,
	"skill": 0.0,
	"ultimate": 0.0
}

const JOYSTICK_RADIUS := 62.0
const DEAD_ZONE := 0.14


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	var needs_redraw := false
	for action in action_flash.keys():
		var remaining: float = maxf(0.0, float(action_flash[action]) - delta)
		if remaining != float(action_flash[action]):
			action_flash[action] = remaining
			needs_redraw = true
	if needs_redraw:
		queue_redraw()


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
			for action in ["melee", "shoot", "dodge", "skill", "ultimate"]:
				if _button_center(action).distance_to(point) <= _button_radius(action) + 7.0:
					action_flash[action] = 0.16
					queue_redraw()
					match action:
						"melee":
							melee_pressed.emit()
						"shoot":
							shoot_pressed.emit()
						"dodge":
							dodge_pressed.emit()
						"skill":
							skill_pressed.emit()
						"ultimate":
							ultimate_pressed.emit()
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
	return Vector2(98.0, size.y - 95.0)


func _button_center(which: String) -> Vector2:
	match which:
		"melee":
			return Vector2(size.x - 86.0, size.y - 82.0)
		"shoot":
			return Vector2(size.x - 169.0, size.y - 123.0)
		"dodge":
			return Vector2(size.x - 87.0, size.y - 166.0)
		"skill":
			return Vector2(size.x - 173.0, size.y - 204.0)
		"ultimate":
			return Vector2(size.x - 257.0, size.y - 166.0)
	return Vector2.ZERO


func _button_radius(which: String) -> float:
	match which:
		"melee":
			return 36.0
		"shoot":
			return 31.0
		"dodge":
			return 30.0
		"skill":
			return 31.0
		"ultimate":
			return 34.0
	return 30.0


func _pause_rect() -> Rect2:
	return Rect2(size.x - 59.0, 10.0, 48.0, 38.0)


func _start_rect() -> Rect2:
	return Rect2((size.x - 250.0) * 0.5, size.y * 0.55, 250.0, 56.0)


func _unlock_rect() -> Rect2:
	return Rect2((size.x - 320.0) * 0.5, size.y * 0.68, 320.0, 48.0)


func _resume_rect() -> Rect2:
	return Rect2((size.x - 220.0) * 0.5, size.y * 0.53, 220.0, 52.0)


func _restart_rect() -> Rect2:
	return Rect2((size.x - 220.0) * 0.5, size.y * 0.65, 220.0, 52.0)


func _upgrade_rect(index: int) -> Rect2:
	var card_width := 180.0
	var gap := 12.0
	var total_width := card_width * 3.0 + gap * 2.0
	var start_x := (size.x - total_width) * 0.5
	return Rect2(start_x + index * (card_width + gap), size.y * 0.45, card_width, 136.0)


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
		_draw_overlay(font, "TẠM DỪNG", "Chiến trường đã dừng. Nghỉ một chút rồi quay lại.")
		_draw_button_rect(font, _resume_rect(), "TIẾP TỤC")
		_draw_button_rect(font, _restart_rect(), "CHƠI LẠI")
	elif game_state == "upgrade":
		_draw_hud(font)
		_draw_upgrade_overlay(font)
	elif game_state == "won":
		_draw_result_overlay(font, true)
	elif game_state == "lost":
		_draw_result_overlay(font, false)


func _draw_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.022, 0.034, 0.88), true)
	_draw_centered(font, "KIẾM KHÍ TRUYỀN THUYẾT", Vector2(size.x * 0.5, size.y * 0.22), 34, Color(0.90, 0.97, 0.98))
	_draw_centered(font, "VÕ HIỆP • DARK FANTASY • ĐẤU TRƯỜNG SINH TỒN", Vector2(size.x * 0.5, size.y * 0.32), 15, Color(0.36, 0.91, 0.84))
	_draw_centered(font, "GẮN KIẾM ẤN RỒI PHÓNG KIẾM KHÍ ĐỂ KÍCH NỔ", Vector2(size.x * 0.5, size.y * 0.41), 14, Color(0.85, 0.90, 0.92))
	_draw_centered(font, "NÉ ĐÚNG BÁO ĐÒN ĐỂ PHẢN KÍCH • QUẢN LÝ NỘI LỰC", Vector2(size.x * 0.5, size.y * 0.46), 14, Color(0.85, 0.90, 0.92))
	_draw_button_rect(font, _start_rect(), "BƯỚC VÀO CHIẾN TRƯỜNG")
	var relic_text := "BẢO VẬT PHẢN KÍCH — ĐÃ MỞ" if bool(stats.get("unlocked_relic", false)) else "MỞ BẢO VẬT PHẢN KÍCH • 35 TINH THẠCH"
	_draw_button_rect(font, _unlock_rect(), relic_text)
	_draw_centered(font, "Tinh thạch tích lũy: %d" % int(stats.get("crystals", 0)), Vector2(size.x * 0.5, size.y * 0.83), 15, Color(0.95, 0.78, 0.41))
	_draw_centered(font, "Phím: mũi tên • Space: đánh • F: kiếm khí • Shift: lướt • E: phá trận • Q: tuyệt kỹ", Vector2(size.x * 0.5, size.y * 0.95), 11, Color(0.56, 0.69, 0.74))


func _draw_hud(font: Font) -> void:
	var hud_rect := Rect2(10.0, 9.0, 304.0, 96.0)
	draw_rect(hud_rect.grow(2.0), Color(0.10, 0.64, 0.65, 0.14), true)
	draw_rect(hud_rect, Color(0.012, 0.026, 0.041, 0.88), true)
	draw_rect(hud_rect, Color(0.34, 0.68, 0.65, 0.48), false, 1.0)

	var seconds := maxi(0, int(stats.get("time_left", 480)))
	var minutes := int(floor(float(seconds) / 60.0))
	var remainder := seconds % 60
	draw_string(font, Vector2(20.0, 32.0), "%02d:%02d" % [minutes, remainder], HORIZONTAL_ALIGNMENT_LEFT, 100.0, 22, Color(0.96, 0.98, 1.0))
	draw_string(font, Vector2(134.0, 31.0), "HẠ %d" % int(stats.get("kills", 0)), HORIZONTAL_ALIGNMENT_LEFT, 92.0, 15, Color(1.0, 0.79, 0.37))
	if bool(stats.get("boss_spawned", false)):
		draw_string(font, Vector2(222.0, 31.0), "TRÙM", HORIZONTAL_ALIGNMENT_LEFT, 62.0, 13, Color(1.0, 0.35, 0.26))

	var health_ratio := clampf(float(stats.get("health", 0.0)) / maxf(1.0, float(stats.get("max_health", 100.0))), 0.0, 1.0)
	draw_rect(Rect2(20.0, 43.0, 190.0, 9.0), Color(0.17, 0.20, 0.23), true)
	draw_rect(Rect2(20.0, 43.0, 190.0 * health_ratio, 9.0), Color(0.88, 0.20, 0.25), true)
	draw_rect(Rect2(20.0, 43.0, 190.0 * health_ratio, 2.0), Color(1.0, 0.58, 0.54, 0.88), true)

	var energy_ratio := clampf(float(stats.get("energy", 0.0)) / maxf(1.0, float(stats.get("max_energy", 100.0))), 0.0, 1.0)
	draw_rect(Rect2(20.0, 58.0, 190.0, 7.0), Color(0.10, 0.15, 0.20), true)
	draw_rect(Rect2(20.0, 58.0, 190.0 * energy_ratio, 7.0), Color(0.12, 0.68, 0.80), true)
	draw_rect(Rect2(20.0, 58.0, 190.0 * energy_ratio, 2.0), Color(0.60, 0.98, 1.0, 0.85), true)
	draw_string(font, Vector2(20.0, 82.0), "KN %d/%d" % [int(stats.get("xp", 0)), int(stats.get("xp_required", 8))], HORIZONTAL_ALIGNMENT_LEFT, 112.0, 13, Color(0.79, 0.89, 0.93))
	draw_string(font, Vector2(133.0, 82.0), "◇ %d" % int(stats.get("crystals", 0)), HORIZONTAL_ALIGNMENT_LEFT, 82.0, 13, Color(0.49, 0.95, 0.86))
	draw_string(font, Vector2(221.0, 82.0), "KHÍ %d%%" % int(round(energy_ratio * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, 80.0, 12, Color(0.53, 0.85, 0.94))

	draw_rect(_pause_rect(), Color(0.035, 0.075, 0.09, 0.92), true)
	draw_rect(_pause_rect(), Color(0.36, 0.75, 0.72, 0.75), false, 1.4)
	draw_line(Vector2(size.x - 44.0, 20.0), Vector2(size.x - 44.0, 37.0), Color(0.88, 0.96, 0.93), 3.0)
	draw_line(Vector2(size.x - 34.0, 20.0), Vector2(size.x - 34.0, 37.0), Color(0.88, 0.96, 0.93), 3.0)


func _draw_controls(font: Font) -> void:
	var center := _joystick_center()
	draw_circle(center, JOYSTICK_RADIUS + 6.0, Color(0.03, 0.08, 0.11, 0.15))
	draw_circle(center, JOYSTICK_RADIUS, Color(0.035, 0.09, 0.13, 0.64))
	draw_arc(center, JOYSTICK_RADIUS, 0.0, TAU, 48, Color(0.38, 0.69, 0.74, 0.72), 2.0)
	draw_arc(center, JOYSTICK_RADIUS - 7.0, 0.0, TAU, 48, Color(0.20, 0.42, 0.50, 0.50), 1.0)
	draw_line(center + Vector2(-JOYSTICK_RADIUS + 12.0, 0.0), center + Vector2(JOYSTICK_RADIUS - 12.0, 0.0), Color(0.33, 0.60, 0.64, 0.24), 1.0)
	draw_line(center + Vector2(0.0, -JOYSTICK_RADIUS + 12.0), center + Vector2(0.0, JOYSTICK_RADIUS - 12.0), Color(0.33, 0.60, 0.64, 0.24), 1.0)
	var knob := center + move_vector * 31.0
	draw_circle(knob + Vector2(1.0, 3.0), 24.0, Color(0.005, 0.02, 0.03, 0.46))
	draw_circle(knob, 22.0, Color(0.13, 0.35, 0.43, 0.98))
	draw_circle(knob, 17.0, Color(0.27, 0.67, 0.73, 0.95))
	draw_arc(knob, 20.0, PI, TAU, 24, Color(0.79, 0.97, 0.95, 0.85), 1.8)

	_draw_action_button(font, "melee", "ĐÁNH", Color(0.60, 0.18, 0.21), float(stats.get("melee_cd", 0.0)), 0.36, 0.0)
	_draw_action_button(font, "shoot", "KIẾM KHÍ", Color(0.15, 0.43, 0.57), float(stats.get("shoot_cd", 0.0)), 0.48, 9.0)
	_draw_action_button(font, "dodge", "LƯỚT", Color(0.12, 0.53, 0.59), float(stats.get("dodge_cd", 0.0)), 1.15, 0.0)
	_draw_action_button(font, "skill", "PHÁ TRẬN", Color(0.23, 0.43, 0.32), float(stats.get("skill_cd", 0.0)), 7.0, 32.0)
	_draw_action_button(font, "ultimate", "TUYỆT KỸ", Color(0.48, 0.31, 0.12), 0.0, 0.0, 100.0)

	if message != "":
		_draw_centered(font, message, Vector2(size.x * 0.5, size.y - 21.0), 13, Color(0.98, 0.87, 0.55))


func _draw_action_button(font: Font, action: String, title: String, base_color: Color, cooldown: float, max_cooldown: float, energy_cost: float) -> void:
	var center := _button_center(action)
	var radius := _button_radius(action)
	var energy_now := float(stats.get("energy", 100.0))
	var disabled := energy_now + 0.001 < energy_cost
	var fill := base_color.darkened(0.52) if disabled else base_color
	var flash := float(action_flash.get(action, 0.0))
	if flash > 0.0:
		fill = fill.lightened(0.38)
	draw_circle(center + Vector2(1.0, 4.0), radius + 3.0, Color(0.0, 0.0, 0.0, 0.48))
	draw_circle(center, radius + 3.0, Color(0.035, 0.08, 0.10, 0.94))
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.72, 0.91, 0.88, 0.92), 2.0)
	draw_arc(center, radius - 4.0, -PI * 0.82, PI * 0.82, 36, Color(0.96, 0.78, 0.42, 0.45), 1.0)

	match action:
		"melee":
			draw_line(center + Vector2(-10.0, -6.0), center + Vector2(9.0, -17.0), Color(0.99, 0.98, 0.84), 3.0)
			draw_line(center + Vector2(-4.0, -1.0), center + Vector2(1.0, -9.0), Color(0.96, 0.72, 0.34), 3.0)
			draw_line(center + Vector2(3.0, -9.0), center + Vector2(12.0, -1.0), Color(0.77, 0.94, 0.89), 1.5)
		"shoot":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -18.0), center + Vector2(6.0, -5.0),
				center + Vector2(1.0, -2.0), center + Vector2(0.0, -9.0),
				center + Vector2(-1.0, -2.0), center + Vector2(-6.0, -5.0)
			]), Color(0.79, 1.0, 0.97))
			draw_line(center + Vector2(-11.0, -2.0), center + Vector2(11.0, -2.0), Color(0.54, 0.95, 0.97, 0.85), 1.4)
		"dodge":
			draw_arc(center, 13.0, -2.6, 0.35, 28, Color(0.85, 1.0, 0.97), 2.7)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(13.0, -8.0), center + Vector2(18.0, 0.0), center + Vector2(9.0, -1.0)
			]), Color(0.97, 0.96, 0.78))
		"skill":
			draw_arc(center, 10.0, 0.0, TAU, 24, Color(0.78, 1.0, 0.83), 2.0)
			for ray in range(8):
				var angle := TAU * float(ray) / 8.0
				draw_line(center + Vector2(cos(angle), sin(angle)) * 12.0, center + Vector2(cos(angle), sin(angle)) * 18.0, Color(0.90, 1.0, 0.77), 2.0)
		"ultimate":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -19.0), center + Vector2(5.0, -7.0),
				center + Vector2(17.0, -8.0), center + Vector2(8.0, 1.0),
				center + Vector2(11.0, 13.0), center + Vector2(0.0, 7.0),
				center + Vector2(-11.0, 13.0), center + Vector2(-8.0, 1.0),
				center + Vector2(-17.0, -8.0), center + Vector2(-5.0, -7.0)
			]), Color(1.0, 0.88, 0.54))
			draw_arc(center, 21.0, PI * 0.1, PI * 1.75, 32, Color(0.97, 0.74, 0.32, 0.72), 1.4)

	var label_size := 10 if action == "skill" or action == "ultimate" or action == "shoot" else 12
	draw_string(font, Vector2(center.x - radius - 12.0, center.y + radius * 0.58), title, HORIZONTAL_ALIGNMENT_CENTER, (radius + 12.0) * 2.0, label_size, Color(0.97, 1.0, 0.97))

	if cooldown > 0.0 and max_cooldown > 0.0:
		var remaining := clampf(cooldown / max_cooldown, 0.0, 1.0)
		draw_arc(center, radius + 5.0, -PI * 0.5, -PI * 0.5 + TAU * remaining, 36, Color(0.12, 0.025, 0.035, 0.96), 4.5)
		if cooldown >= 0.28:
			draw_string(font, Vector2(center.x - 17.0, center.y + 4.0), "%.1f" % cooldown, HORIZONTAL_ALIGNMENT_CENTER, 34.0, 11, Color.WHITE)
	elif disabled:
		draw_arc(center, radius + 5.0, -PI * 0.5, PI * 1.5, 36, Color(0.02, 0.04, 0.05, 0.82), 3.0)


func _draw_upgrade_overlay(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.018, 0.029, 0.90), true)
	_draw_centered(font, "LÊN CẤP — CHỌN MỘT", Vector2(size.x * 0.5, size.y * 0.25), 27, Color(0.96, 0.82, 0.46))
	_draw_centered(font, "Chiến đấu tạm dừng trong lúc chọn nâng cấp.", Vector2(size.x * 0.5, size.y * 0.34), 14, Color(0.79, 0.88, 0.91))
	var titles: Array[String] = ["KIẾM PHÁP", "KIẾM KHÍ", "NỘI LỰC"]
	var descriptions: Array[String] = [
		"Sát thương cận chiến +5\nCombo mạnh hơn",
		"Đạn mạnh hơn +4\nTầm đánh +35",
		"Sinh lực tối đa +20\nNội lực tối đa +10"
	]
	for index in range(3):
		var rect := _upgrade_rect(index)
		draw_rect(rect.grow(3.0), Color(0.06, 0.23, 0.24, 0.34), true)
		draw_rect(rect, Color(0.055, 0.10, 0.13, 0.98), true)
		draw_rect(rect, Color(0.34, 0.74, 0.68, 0.90), false, 1.8)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color(0.84, 0.62, 0.31), true)
		_draw_centered_in_rect(font, titles[index], Rect2(rect.position.x, rect.position.y + 17.0, rect.size.x, 30.0), 15, Color(1.0, 0.82, 0.47))
		var lines: PackedStringArray = descriptions[index].split("\n")
		for line_index in range(lines.size()):
			draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 65.0 + line_index * 23.0), lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 12, Color(0.82, 0.91, 0.91))


func _draw_result_overlay(font: Font, won: bool) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.018, 0.029, 0.91), true)
	_draw_centered(font, "CHIẾN THẮNG" if won else "THẤT BẠI", Vector2(size.x * 0.5, size.y * 0.30), 34, Color(0.49, 1.0, 0.79) if won else Color(1.0, 0.42, 0.34))
	_draw_centered(font, "Đã hạ: %d    Thưởng: %d tinh thạch" % [int(stats.get("kills", 0)), int(stats.get("run_reward", 0))], Vector2(size.x * 0.5, size.y * 0.43), 17, Color(0.90, 0.94, 0.95))
	_draw_centered(font, "Tổng tinh thạch: %d" % int(stats.get("crystals", 0)), Vector2(size.x * 0.5, size.y * 0.50), 15, Color(0.95, 0.79, 0.42))
	_draw_button_rect(font, _restart_rect(), "CHƠI LẠI")


func _draw_overlay(font: Font, title: String, subtitle: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.03, 0.78), true)
	_draw_centered(font, title, Vector2(size.x * 0.5, size.y * 0.37), 30, Color(0.92, 0.98, 0.96))
	_draw_centered(font, subtitle, Vector2(size.x * 0.5, size.y * 0.45), 14, Color(0.76, 0.87, 0.89))


func _draw_button_rect(font: Font, rect: Rect2, title: String) -> void:
	draw_rect(rect.grow(3.0), Color(0.05, 0.58, 0.58, 0.20), true)
	draw_rect(rect, Color(0.045, 0.12, 0.16, 0.98), true)
	draw_rect(rect, Color(0.36, 0.78, 0.71, 0.96), false, 1.8)
	draw_rect(Rect2(rect.position.x + 5.0, rect.position.y + 5.0, rect.size.x - 10.0, 2.0), Color(0.88, 0.69, 0.37, 0.84), true)
	_draw_centered_in_rect(font, title, rect, 15, Color(0.95, 1.0, 0.98))


func _draw_centered(font: Font, text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	draw_string(font, Vector2(size.x * 0.04, baseline.y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.92, font_size, color)


func _draw_centered_in_rect(font: Font, text: String, rect: Rect2, font_size: int, color: Color) -> void:
	draw_string(font, Vector2(rect.position.x + 4.0, rect.position.y + rect.size.y * 0.64), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, color)
