extends Resource
class_name SkillDefinition

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = "⭐"
@export var max_level: int = 5
@export var base_cost: int = 1  # стоимость первого уровня
@export var cost_per_level: int = 1  # рост стоимости за уровень
@export var stat_bonuses: Dictionary = {}  # {"health": 10, "stamina": 5, ...}
@export var unlocks_at_level: int = 1  # минимальный уровень игрока для изучения
@export var prerequisite_skill: String = ""  # ID навыка, который нужно изучить сначала
@export var prerequisite_level: int = 0  # минимальный уровень пререквизита

func get_cost_for_level(level: int) -> int:
	if level < 1 or level > max_level:
		return -1
	return base_cost + (level - 1) * cost_per_level

func get_total_cost_for_max_level() -> int:
	var total := 0
	for l in range(1, max_level + 1):
		total += get_cost_for_level(l)
	return total
