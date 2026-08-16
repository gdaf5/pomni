extends Node
class_name PlayerProgression

signal level_up(new_level: int)
signal skill_points_changed(points: int)
signal skill_unlocked(skill_id: String, level: int)
signal stats_updated()

# --- Основные параметры ---
@export var base_xp_to_level: int = 100
@export var xp_growth_factor: float = 1.5
@export var max_level: int = 50

var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100
var skill_points: int = 0

# --- Навыки ---
# Хранит: skill_id -> уровень (0 = не изучен)
var skills: Dictionary = {}

# --- Статистика игрока (бонусы от навыков) ---
var bonus_stats: Dictionary = {
	"health": 0.0,
	"max_health": 0.0,
	"stamina": 0.0,
	"max_stamina": 0.0,
	"damage": 0.0,
	"defense": 0.0,
	"sprint_speed": 0.0,
	"walk_speed": 0.0,
	"xp_gain": 0.0  # множитель получения опыта
}

func _ready() -> void:
	_calculate_xp_for_next_level()

func get_total_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	var total := 0
	for l in range(2, level + 1):
		total += int(base_xp_to_level * pow(l, xp_growth_factor))
	return total

func _calculate_xp_for_next_level() -> void:
	xp_to_next_level = int(base_xp_to_level * pow(current_level, xp_growth_factor))

func add_xp(amount: int) -> void:
	var actual_amount = int(amount * (1.0 + bonus_stats.get("xp_gain", 0.0)))
	current_xp += actual_amount
	
	while current_xp >= xp_to_next_level and current_level < max_level:
		current_xp -= xp_to_next_level
		current_level += 1
		skill_points += 1  # даем 1 очко навыка за уровень
		_calculate_xp_for_next_level()
		level_up.emit(current_level)
	
	stats_updated.emit()

func set_level(level: int) -> void:
	current_level = clamp(level, 1, max_level)
	current_xp = 0
	_calculate_xp_for_next_level()
	level_up.emit(current_level)
	stats_updated.emit()

# --- Система навыков ---

func can_unlock_skill(skill_def: SkillDefinition, target_level: int = 1) -> bool:
	if target_level < 1 or target_level > skill_def.max_level:
		return false
	
	# Проверка уровня игрока
	if current_level < skill_def.unlocks_at_level:
		return false
	
	# Проверка пререквизитов
	if skill_def.prerequisite_skill != "":
		var prereq_level = skills.get(skill_def.prerequisite_skill, 0)
		if prereq_level < skill_def.prerequisite_level:
			return false
	
	# Проверка очков навыков
	var cost = skill_def.get_cost_for_level(target_level)
	if skill_points < cost:
		return false
	
	return true

func unlock_skill(skill_def: SkillDefinition, levels: int = 1) -> bool:
	if not can_unlock_skill(skill_def, levels):
		return false
	
	var cost = skill_def.get_cost_for_level(levels)
	skill_points -= cost
	
	var current_skill_level = skills.get(skill_def.id, 0)
	skills[skill_def.id] = current_skill_level + levels
	
	_apply_skill_bonuses(skill_def, levels)
	
	skill_unlocked.emit(skill_def.id, skills[skill_def.id])
	skill_points_changed.emit(skill_points)
	stats_updated.emit()
	
	return true

func _apply_skill_bonuses(skill_def: SkillDefinition, levels: int) -> void:
	for stat_name in skill_def.stat_bonuses:
		var bonus_per_level = float(skill_def.stat_bonuses[stat_name])
		if not bonus_stats.has(stat_name):
			bonus_stats[stat_name] = 0.0
		bonus_stats[stat_name] += bonus_per_level * levels

func get_skill_level(skill_id: String) -> int:
	return skills.get(skill_id, 0)

func is_skill_maxed(skill_def: SkillDefinition) -> bool:
	return skills.get(skill_def.id, 0) >= skill_def.max_level

func reset_all_skills() -> void:
	# Возвращаем все очки навыков (опционально можно брать комиссию)
	for skill_id in skills:
		var def = _get_skill_definition_by_id(skill_id)
		if def:
			var level = skills[skill_id]
			for l in range(1, level + 1):
				skill_points += def.get_cost_for_level(l)
	
	skills.clear()
	bonus_stats = {
		"health": 0.0,
		"max_health": 0.0,
		"stamina": 0.0,
		"max_stamina": 0.0,
		"damage": 0.0,
		"defense": 0.0,
		"sprint_speed": 0.0,
		"walk_speed": 0.0,
		"xp_gain": 0.0
	}
	
	skill_points_changed.emit(skill_points)
	stats_updated.emit()

func _get_skill_definition_by_id(skill_id: String) -> SkillDefinition:
	# Заглушка - в реальной игре нужно загружать из каталога
	# Здесь возвращаем null, т.к. каталог навыков будет отдельным ресурсом
	return null

func get_bonus_stat(stat_name: String) -> float:
	return bonus_stats.get(stat_name, 0.0)

func save_progress() -> Dictionary:
	return {
		"level": current_level,
		"xp": current_xp,
		"skill_points": skill_points,
		"skills": skills.duplicate(),
		"bonus_stats": bonus_stats.duplicate()
	}

func load_progress(data: Dictionary) -> void:
	current_level = data.get("level", 1)
	current_xp = data.get("xp", 0)
	skill_points = data.get("skill_points", 0)
	skills = data.get("skills", {}).duplicate()
	bonus_stats = data.get("bonus_stats", bonus_stats).duplicate()
	_calculate_xp_for_next_level()
	stats_updated.emit()
