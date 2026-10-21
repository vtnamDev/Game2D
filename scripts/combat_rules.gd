extends RefCounted
class_name CombatRules

# Shared rules are kept pure where possible so CI can test them without rendering.
static func nearest_target(candidates: Array, origin: Vector2, max_range: float) -> Node2D:
	if max_range < 0.0:
		return null

	var range_squared := max_range * max_range
	var best_distance_squared := range_squared
	var best_target: Node2D = null

	for candidate in candidates:
		if not is_instance_valid(candidate) or not (candidate is Node2D):
			continue
		if candidate.get("alive") == false:
			continue

		var distance_squared: float = origin.distance_squared_to(candidate.position)
		if distance_squared > range_squared:
			continue
		if best_target == null or distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_target = candidate

	return best_target


static func combo_damage(base_damage: float, combo_bonus: float, target_is_marked: bool) -> float:
	if target_is_marked:
		return base_damage + combo_bonus
	return base_damage


static func reward_for_run(kills: int, won: bool) -> int:
	var reward: int = floori(float(maxi(0, kills)) / 2.0)
	if won:
		reward += 10
	return reward
