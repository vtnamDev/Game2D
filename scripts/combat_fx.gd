extends Node2D
## Centralized low-cost combat feedback: pooled procedural audio and batched transient drawings.
## Effects share one CanvasItem and expire automatically instead of creating dozens of nodes.

const MAX_EFFECTS := 22
const AUDIO_VOICES := 6
const SAMPLE_RATE := 11025

var _effects: Array[Dictionary] = []
var _sounds: Dictionary = {}
var _audio_players: Array[AudioStreamPlayer] = []
var _audio_cursor: int = 0
var _redraw_left: float = 0.0
var _sound_cooldowns: Dictionary = {}


func _ready() -> void:
	z_index = 20
	_build_sound_bank()
	for voice_index in range(AUDIO_VOICES):
		var audio_player := AudioStreamPlayer.new()
		audio_player.volume_db = -8.0
		audio_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(audio_player)
		_audio_players.append(audio_player)


func _process(delta: float) -> void:
	for sound_kind in _sound_cooldowns.keys():
		var remaining: float = maxf(0.0, float(_sound_cooldowns[sound_kind]) - delta)
		if remaining <= 0.0:
			_sound_cooldowns.erase(sound_kind)
		else:
			_sound_cooldowns[sound_kind] = remaining
	var changed := false
	for index in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[index]
		var remaining: float = float(effect["time"]) - delta
		effect["time"] = remaining
		_effects[index] = effect
		changed = true
		if remaining <= 0.0:
			_effects.remove_at(index)

	if not changed:
		return
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = 1.0 / 30.0
		queue_redraw()


func play_sfx(kind: String) -> void:
	if not _sounds.has(kind) or _audio_players.is_empty():
		return
	if float(_sound_cooldowns.get(kind, 0.0)) > 0.0:
		return
	match kind:
		"death":
			_sound_cooldowns[kind] = 0.085
		"hit":
			_sound_cooldowns[kind] = 0.035
		"pickup":
			_sound_cooldowns[kind] = 0.045
	var audio_player: AudioStreamPlayer = _audio_players[_audio_cursor]
	_audio_cursor = (_audio_cursor + 1) % _audio_players.size()
	audio_player.stream = _sounds[kind] as AudioStreamWAV
	match kind:
		"hit", "hurt", "death":
			audio_player.volume_db = -10.0
		"slam", "ultimate", "lightning":
			audio_player.volume_db = -6.0
		_:
			audio_player.volume_db = -8.0
	audio_player.play()


func clear_effects() -> void:
	_effects.clear()
	queue_redraw()


func add_slash(world_position: Vector2, direction: Vector2, color: Color = Color(0.66, 0.96, 1.0)) -> void:
	_spawn("slash", world_position, direction, color, 48.0, 0.22)


func add_hit(world_position: Vector2, color: Color = Color(1.0, 0.78, 0.42)) -> void:
	_spawn("hit", world_position, Vector2.RIGHT, color, 20.0, 0.16)


func add_dash(world_position: Vector2, direction: Vector2) -> void:
	_spawn("dash", world_position, direction, Color(0.33, 0.90, 1.0), 54.0, 0.23)


func add_slam(world_position: Vector2, radius: float = 158.0, color: Color = Color(0.40, 1.0, 0.80)) -> void:
	_spawn("slam", world_position, Vector2.RIGHT, color, radius, 0.48)


func add_ice(world_position: Vector2, radius: float = 188.0) -> void:
	_spawn("ice", world_position, Vector2.RIGHT, Color(0.28, 0.81, 1.0), radius, 0.43)


func add_lightning(points: PackedVector2Array) -> void:
	if points.size() >= 2:
		_spawn("lightning", Vector2.ZERO, Vector2.RIGHT, Color(0.37, 0.83, 1.0), 10.0, 0.24, points)


func add_death(world_position: Vector2, color: Color = Color(1.0, 0.34, 0.30)) -> void:
	_spawn("death", world_position, Vector2.RIGHT, color, 32.0, 0.30)


func add_pickup(world_position: Vector2) -> void:
	_spawn("pickup", world_position, Vector2.UP, Color(0.42, 1.0, 0.83), 18.0, 0.24)


func add_heal(world_position: Vector2) -> void:
	_spawn("heal", world_position, Vector2.UP, Color(0.42, 1.0, 0.67), 54.0, 0.64)


func _spawn(kind: String, world_position: Vector2, direction: Vector2, color: Color, size: float, duration: float, points: PackedVector2Array = PackedVector2Array()) -> void:
	if _effects.size() >= MAX_EFFECTS:
		_effects.remove_at(0)
	var safe_direction := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	_effects.append({
		"kind": kind,
		"position": world_position,
		"direction": safe_direction,
		"color": color,
		"size": size,
		"time": duration,
		"duration": duration,
		"points": points
	})
	_redraw_left = 0.0
	queue_redraw()


func _build_sound_bank() -> void:
	# Small generated PCM clips: no large downloaded audio pack and no allocation during combat.
	_sounds["swing"] = _make_sound(0.12, 720.0, 190.0, 0.30, 1.0)
	_sounds["shot"] = _make_sound(0.11, 1100.0, 380.0, 0.15, 2.0)
	_sounds["hit"] = _make_sound(0.095, 190.0, 58.0, 0.72, 3.0)
	_sounds["hurt"] = _make_sound(0.18, 155.0, 52.0, 0.70, 4.0)
	_sounds["dash"] = _make_sound(0.15, 420.0, 95.0, 0.24, 5.0)
	_sounds["slam"] = _make_sound(0.29, 125.0, 32.0, 0.65, 6.0)
	_sounds["ice"] = _make_sound(0.23, 980.0, 260.0, 0.12, 7.0)
	_sounds["lightning"] = _make_sound(0.24, 640.0, 70.0, 0.49, 8.0)
	_sounds["ultimate"] = _make_sound(0.34, 420.0, 45.0, 0.58, 9.0)
	_sounds["death"] = _make_sound(0.17, 300.0, 72.0, 0.40, 10.0)
	_sounds["pickup"] = _make_sound(0.10, 740.0, 1320.0, 0.04, 11.0)
	_sounds["heal"] = _make_sound(0.34, 430.0, 1050.0, 0.07, 12.0)


func _make_sound(duration: float, start_frequency: float, end_frequency: float, noise_mix: float, seed_value: float) -> AudioStreamWAV:
	var sample_count := maxi(1, int(SAMPLE_RATE * duration))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(start_frequency * 31.0 + end_frequency * 13.0 + seed_value * 7919.0)

	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		var time_seconds := float(index) / float(SAMPLE_RATE)
		var phase := TAU * (start_frequency * time_seconds + 0.5 * (end_frequency - start_frequency) * time_seconds * time_seconds / duration)
		var fundamental := sin(phase)
		var overtone := sin(phase * 2.03 + 0.5) * 0.20
		var noise := rng.randf_range(-1.0, 1.0)
		var envelope := minf(1.0, progress * 36.0) * pow(maxf(0.0, 1.0 - progress), 1.65)
		var mixed := (fundamental * (1.0 - noise_mix) + noise * noise_mix + overtone) * envelope * 0.72
		var sample_value := clampi(roundi(clampf(mixed, -1.0, 1.0) * 28000.0), -32768, 32767)
		pcm[index * 2] = sample_value & 255
		pcm[index * 2 + 1] = (sample_value >> 8) & 255

	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = SAMPLE_RATE
	wave.stereo = false
	wave.data = pcm
	return wave


func _draw() -> void:
	for effect in _effects:
		var duration: float = float(effect["duration"])
		var progress := clampf(1.0 - float(effect["time"]) / maxf(duration, 0.001), 0.0, 1.0)
		var fade := 1.0 - progress
		var origin: Vector2 = effect["position"]
		var direction: Vector2 = effect["direction"]
		var color: Color = effect["color"]
		var radius: float = float(effect["size"])
		match String(effect["kind"]):
			"slash":
				_draw_slash(origin, direction, color, radius, progress, fade)
			"hit":
				_draw_hit(origin, color, radius, progress, fade)
			"dash":
				_draw_dash(origin, direction, color, radius, progress, fade)
			"slam":
				_draw_slam(origin, color, radius, progress, fade)
			"ice":
				_draw_ice(origin, color, radius, progress, fade)
			"lightning":
				_draw_lightning(effect["points"], color, fade)
			"death":
				_draw_death(origin, color, radius, progress, fade)
			"pickup":
				_draw_pickup(origin, color, radius, progress, fade)
			"heal":
				_draw_heal(origin, color, radius, progress, fade)


func _draw_slash(origin: Vector2, direction: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	draw_set_transform(origin, direction.angle(), Vector2.ONE)
	draw_arc(Vector2(12.0, 0.0), radius, -1.15 + progress * 0.48, 1.35 + progress * 0.48, 26, Color(color.r, color.g, color.b, 0.42 * fade), 14.0)
	draw_arc(Vector2(12.0, 0.0), radius, -1.15 + progress * 0.48, 1.35 + progress * 0.48, 26, Color(0.93, 1.0, 0.93, 0.94 * fade), 3.0)
	draw_line(Vector2(2.0, -9.0), Vector2(30.0, 2.0), Color(1.0, 0.76, 0.42, 0.84 * fade), 1.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hit(origin: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	draw_circle(origin, lerpf(3.0, 8.0, progress), Color(color.r, color.g, color.b, 0.26 * fade))
	for spark_index in range(7):
		var angle := TAU * float(spark_index) / 7.0 + 0.21
		var direction := Vector2(cos(angle), sin(angle))
		var inner := origin + direction * (radius * 0.18 + progress * 2.0)
		var outer := origin + direction * (radius * (0.35 + progress * 0.55))
		draw_line(inner, outer, Color(1.0, 0.94, 0.73, 0.86 * fade), 2.0 if spark_index % 2 == 0 else 1.0)


func _draw_dash(origin: Vector2, direction: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	var side := Vector2(-direction.y, direction.x)
	for trail_index in range(3):
		var back := float(trail_index + 1) * radius * 0.22
		var center := origin - direction * back
		var width := (7.0 - float(trail_index) * 1.5) * fade
		var points := PackedVector2Array([
			center + side * width,
			center + direction * 6.0,
			center - side * width,
			center - direction * 7.0
		])
		draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.34 * fade))


func _draw_slam(origin: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	var ring_radius := lerpf(10.0, radius, progress)
	draw_arc(origin, ring_radius, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.78 * fade), 4.5)
	draw_arc(origin, ring_radius * 0.76, 0.25, TAU - 0.25, 30, Color(1.0, 0.91, 0.68, 0.62 * fade), 1.8)
	for shard_index in range(9):
		var angle := TAU * float(shard_index) / 9.0 + 0.12
		var direction := Vector2(cos(angle), sin(angle))
		var center := origin + direction * ring_radius
		var side := Vector2(-direction.y, direction.x)
		var scale := 3.0 + 3.0 * fade
		draw_colored_polygon(PackedVector2Array([center + direction * scale, center + side * scale * 0.6, center - side * scale * 0.6]), Color(0.83, 0.91, 0.83, 0.68 * fade))


func _draw_ice(origin: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	var ring_radius := lerpf(20.0, radius, progress)
	draw_arc(origin, ring_radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.84 * fade), 4.0)
	draw_arc(origin, ring_radius * 0.83, progress, TAU - progress, 32, Color(0.77, 0.98, 1.0, 0.50 * fade), 1.5)
	for shard_index in range(8):
		var angle := TAU * float(shard_index) / 8.0
		var center := origin + Vector2(cos(angle), sin(angle)) * ring_radius
		var shard := Vector2(cos(angle), sin(angle)) * 7.0
		var side := Vector2(-sin(angle), cos(angle)) * 3.0
		draw_colored_polygon(PackedVector2Array([center + shard, center + side, center - shard * 0.5, center - side]), Color(0.67, 0.94, 1.0, 0.82 * fade))


func _draw_lightning(points: PackedVector2Array, color: Color, fade: float) -> void:
	if points.size() < 2:
		return
	for segment_index in range(points.size() - 1):
		var from_point: Vector2 = points[segment_index]
		var to_point: Vector2 = points[segment_index + 1]
		var delta_point := to_point - from_point
		var normal := Vector2(-delta_point.y, delta_point.x).normalized()
		var p1 := from_point + delta_point * 0.30 + normal * (9.0 if segment_index % 2 == 0 else -8.0)
		var p2 := from_point + delta_point * 0.67 + normal * (-7.0 if segment_index % 2 == 0 else 8.0)
		var bolt := PackedVector2Array([from_point, p1, p2, to_point])
		draw_polyline(bolt, Color(color.r, color.g, color.b, 0.52 * fade), 10.0, true)
		draw_polyline(bolt, Color(0.55, 0.91, 1.0, 0.94 * fade), 3.0, true)
		draw_polyline(bolt, Color(0.95, 1.0, 1.0, 0.91 * fade), 1.1, true)


func _draw_death(origin: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	for shard_index in range(8):
		var angle := TAU * float(shard_index) / 8.0
		var direction := Vector2(cos(angle), sin(angle))
		var side := Vector2(-direction.y, direction.x)
		var center := origin + direction * radius * progress
		var size := lerpf(4.0, 1.0, progress)
		draw_colored_polygon(PackedVector2Array([center + direction * size, center + side * size * 0.65, center - direction * size, center - side * size * 0.65]), Color(color.r, color.g, color.b, 0.84 * fade))


func _draw_heal(origin: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	var ring_radius := lerpf(12.0, radius, progress)
	draw_arc(origin, ring_radius, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.90 * fade), 3.2)
	draw_arc(origin, ring_radius * 0.68, -progress * 1.5, TAU - progress * 1.5, 30, Color(0.82, 1.0, 0.84, 0.82 * fade), 1.6)
	for spark_index in range(7):
		var angle := TAU * float(spark_index) / 7.0 + progress * 1.7
		var direction := Vector2(cos(angle), sin(angle))
		var inner := origin + direction * ring_radius * 0.32
		var outer := origin + direction * (ring_radius * 0.48 + progress * 14.0)
		draw_line(inner, outer, Color(0.62, 1.0, 0.78, 0.88 * fade), 2.0)
	# Rising plus symbol clearly distinguishes healing from an attack.
	var plus_center := origin + Vector2(0.0, -progress * 34.0)
	draw_rect(Rect2(plus_center + Vector2(-2.5, -9.0), Vector2(5.0, 18.0)), Color(0.88, 1.0, 0.90, 0.95 * fade), true)
	draw_rect(Rect2(plus_center + Vector2(-9.0, -2.5), Vector2(18.0, 5.0)), Color(0.88, 1.0, 0.90, 0.95 * fade), true)


func _draw_pickup(origin: Vector2, color: Color, radius: float, progress: float, fade: float) -> void:
	var ring_radius := lerpf(4.0, radius, progress)
	draw_arc(origin, ring_radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.65 * fade), 1.5)
	for shard_index in range(4):
		var angle := TAU * float(shard_index) / 4.0 + progress * 0.8
		var center := origin + Vector2(cos(angle), sin(angle)) * ring_radius
		draw_circle(center, 2.0 * fade, Color(0.84, 1.0, 0.82, 0.9 * fade))
