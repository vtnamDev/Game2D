extends Node2D

signal hit(target: Node2D, raw_damage: float)

var target: Node2D
var speed: float = 390.0
var damage: float = 12.0
var lifetime: float = 2.0


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(target):
		queue_free()
		return
	if target.get("alive") == false:
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if distance <= 15.0:
		hit.emit(target, damage)
		queue_free()
		return
	if distance > 0.001:
		global_position += to_target / distance * speed * delta
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-7.0, 0.0), Vector2(5.0, 0.0), Color(1.0, 0.75, 0.2), 3.0)
	draw_circle(Vector2(5.0, 0.0), 3.0, Color(1.0, 0.94, 0.61))
