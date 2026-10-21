extends SceneTree

const CombatRules = preload("res://scripts/combat_rules.gd")
const EnemyScript = preload("res://scripts/enemy.gd")


func _initialize() -> void:
	var near_enemy: Variant = CharacterBody2D.new()
	near_enemy.set_script(EnemyScript)
	near_enemy.position = Vector2(20.0, 0.0)
	root.add_child(near_enemy)

	var far_enemy: Variant = CharacterBody2D.new()
	far_enemy.set_script(EnemyScript)
	far_enemy.position = Vector2(80.0, 0.0)
	root.add_child(far_enemy)

	assert(CombatRules.nearest_target([far_enemy, near_enemy], Vector2.ZERO, 100.0) == near_enemy, "Must select the nearest valid enemy.")
	assert(CombatRules.nearest_target([near_enemy], Vector2.ZERO, 10.0) == null, "Must return no target when outside range.")
	near_enemy.alive = false
	assert(CombatRules.nearest_target([near_enemy, far_enemy], Vector2.ZERO, 100.0) == far_enemy, "Must skip dead enemies.")
	assert(is_equal_approx(CombatRules.combo_damage(12.0, 18.0, true), 30.0), "Marked target must take base plus combo damage.")
	assert(is_equal_approx(CombatRules.combo_damage(12.0, 18.0, false), 12.0), "Unmarked target must take base damage only.")
	assert(CombatRules.reward_for_run(5, false) == 2, "Loss reward should be half kills rounded down.")
	assert(CombatRules.reward_for_run(5, true) == 12, "Win reward should add ten crystals.")
	assert(CombatRules.reward_for_run(-4, false) == 0, "Negative kill count must not grant negative currency.")

	print("PASS: combat rules tests")
	quit()
