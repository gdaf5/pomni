extends Control
class_name SkillTreeUI

signal closed

@export var skill_catalog_path: String = "res://resources/skills/skill_catalog.tres"

var progression: PlayerProgression = null
var skill_catalog: Array = []  # Массив SkillDefinition

var _skill_buttons: Dictionary = {}  # skill_id -> Button
var _selected_skill_id: String = ""

@onready var skill_container: GridContainer = $Margin/Contents/Body/GridWrap/SkillGrid
@onready var detail_panel: PanelContainer = $Margin/Contents/Body/DetailPanel
@onready var detail_name: Label = $Margin/Contents/Body/DetailPanel/VBox/Name
@onready var detail_desc: Label = $Margin/Contents/Body/DetailPanel/VBox/Desc
@onready var detail_level: Label = $Margin/Contents/Body/DetailPanel/VBox/Level
@onready var detail_cost: Label = $Margin/Contents/Body/DetailPanel/VBox/Cost
@onready var detail_prereq: Label = $Margin/Contents/Body/DetailPanel/VBox/Prereq
@onready var unlock_button: Button = $Margin/Contents/Body/DetailPanel/VBox/UnlockButton
@onready var skill_points_label: Label = $Margin/Contents/Header/SkillPointsPanel/SkillPoints
@onready var level_label: Label = $Margin/Contents/Header/LevelPanel/LevelInfo

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if GameManager.player_progression:
		_setup(GameManager.player_progression)
	else:
		GameManager.progression_ready.connect(_setup)
	
	_load_skill_catalog()

func _setup(prog: PlayerProgression) -> void:
	progression = prog
	progression.skill_points_changed.connect(_update_skill_points_display)
	progression.level_up.connect(_update_level_display)
	progression.skill_unlocked.connect(_on_skill_unlocked)
	progression.stats_updated.connect(_refresh)
	_update_skill_points_display(progression.skill_points)
	_update_level_display(progression.current_level)
	_refresh()

func _load_skill_catalog() -> void:
	# Загрузка каталога навыков из ресурса
	# Временная заглушка - создадим тестовые навыки
	_create_test_skills()
	if progression:
		_refresh()

func _create_test_skills() -> void:
	# Создаём тестовые навыки для демонстрации
	var warrior_strength = SkillDefinition.new()
	warrior_strength.id = "warrior_strength"
	warrior_strength.display_name = "Сила воина"
	warrior_strength.description = "Увеличивает урон от ближних атак."
	warrior_strength.icon = "⚔️"
	warrior_strength.max_level = 5
	warrior_strength.base_cost = 1
	warrior_strength.cost_per_level = 1
	warrior_strength.stat_bonuses = {"damage": 5.0}
	warrior_strength.unlocks_at_level = 1
	skill_catalog.append(warrior_strength)
	
	var endurance = SkillDefinition.new()
	endurance.id = "endurance"
	endurance.display_name = "Выносливость"
	endurance.description = "Увеличивает максимальное здоровье."
	endurance.icon = "❤️"
	endurance.max_level = 5
	endurance.base_cost = 1
	endurance.cost_per_level = 1
	endurance.stat_bonuses = {"max_health": 20.0}
	endurance.unlocks_at_level = 1
	endurance.prerequisite_skill = ""
	skill_catalog.append(endurance)
	
	var stamina_master = SkillDefinition.new()
	stamina_master.id = "stamina_master"
	stamina_master.display_name = "Мастер стамины"
	stamina_master.description = "Увеличивает максимальную стамину."
	stamina_master.icon = "💪"
	stamina_master.max_level = 5
	stamina_master.base_cost = 1
	stamina_master.cost_per_level = 1
	stamina_master.stat_bonuses = {"max_stamina": 15.0}
	stamina_master.unlocks_at_level = 2
	stamina_master.prerequisite_skill = "endurance"
	stamina_master.prerequisite_level = 2
	skill_catalog.append(stamina_master)
	
	var swift_runner = SkillDefinition.new()
	swift_runner.id = "swift_runner"
	swift_runner.display_name = "Быстрый бегун"
	swift_runner.description = "Увеличивает скорость бега."
	swift_runner.icon = "👟"
	swift_runner.max_level = 3
	swift_runner.base_cost = 2
	swift_runner.cost_per_level = 1
	swift_runner.stat_bonuses = {"sprint_speed": 0.5}
	swift_runner.unlocks_at_level = 3
	swift_runner.prerequisite_skill = "stamina_master"
	swift_runner.prerequisite_level = 1
	skill_catalog.append(swift_runner)
	
	var xp_boost = SkillDefinition.new()
	xp_boost.id = "xp_boost"
	xp_boost.display_name = "Опытный искатель"
	xp_boost.description = "Увеличивает получение опыта."
	xp_boost.icon = "✨"
	xp_boost.max_level = 3
	xp_boost.base_cost = 2
	xp_boost.cost_per_level = 2
	xp_boost.stat_bonuses = {"xp_gain": 0.1}
	xp_boost.unlocks_at_level = 5
	skill_catalog.append(xp_boost)
	
	var heavy_hitter = SkillDefinition.new()
	heavy_hitter.id = "heavy_hitter"
	heavy_hitter.display_name = "Тяжёлый удар"
	heavy_hitter.description = "Увеличивает урон тяжёлых атак."
	heavy_hitter.icon = "🔨"
	heavy_hitter.max_level = 3
	heavy_hitter.base_cost = 2
	heavy_hitter.cost_per_level = 2
	heavy_hitter.stat_bonuses = {"damage": 10.0}
	heavy_hitter.unlocks_at_level = 4
	heavy_hitter.prerequisite_skill = "warrior_strength"
	heavy_hitter.prerequisite_level = 3
	skill_catalog.append(heavy_hitter)

func toggle() -> void:
	if not progression:
		GameManager.init_progression()
		progression = GameManager.player_progression
		if not progression:
			return
	visible = not visible
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	if not progression:
		return
	# Очистка старых кнопок
	for btn in _skill_buttons.values():
		if is_instance_valid(btn):
			btn.queue_free()
	_skill_buttons.clear()
	
	# Создание кнопок для каждого навыка
	for skill_def in skill_catalog:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 100)
		btn.focus_mode = Control.FOCUS_NONE
		
		var current_level = progression.get_skill_level(skill_def.id)
		var is_maxed = current_level >= skill_def.max_level
		var can_unlock = progression.can_unlock_skill(skill_def, 1)
		
		var text: String = skill_def.icon + "\n"
		text += skill_def.display_name + "\n"
		text += "Ур: " + str(current_level) + "/" + str(skill_def.max_level)
		
		btn.text = text
		btn.pressed.connect(_on_skill_selected.bind(skill_def))
		
		# Цвет кнопки в зависимости от состояния
		if is_maxed:
			btn.modulate = Color(0.3, 1.0, 0.3)  # Зелёный - макс. уровень
		elif can_unlock:
			btn.modulate = Color(1.0, 1.0, 0.3)  # Жёлтый - можно изучить
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)  # Серый - недоступно
		
		skill_container.add_child(btn)
		_skill_buttons[skill_def.id] = btn
	
	_update_skill_points_display(progression.skill_points)
	
	if _selected_skill_id != "":
		var selected_def = _get_skill_by_id(_selected_skill_id)
		if selected_def:
			_update_detail(selected_def)

func _on_skill_selected(skill_def: SkillDefinition) -> void:
	_selected_skill_id = skill_def.id
	_update_detail(skill_def)

func _update_detail(skill_def: SkillDefinition) -> void:
	var current_level = progression.get_skill_level(skill_def.id)
	var next_level = current_level + 1
	var is_maxed = current_level >= skill_def.max_level
	var can_unlock = progression.can_unlock_skill(skill_def, 1)
	
	detail_name.text = skill_def.icon + " " + skill_def.display_name
	detail_desc.text = skill_def.description
	detail_level.text = "Уровень: " + str(current_level) + " / " + str(skill_def.max_level)
	
	if is_maxed:
		detail_cost.text = "Максимальный уровень"
		unlock_button.text = "МАКС"
		unlock_button.disabled = true
	else:
		var cost = skill_def.get_cost_for_level(next_level)
		detail_cost.text = "Стоимость: " + str(cost) + " оч."
		unlock_button.text = "Изучить (" + str(cost) + ")"
		unlock_button.disabled = not can_unlock
	
	# Пререквизиты
	if skill_def.prerequisite_skill != "":
		var prereq_def = _get_skill_by_id(skill_def.prerequisite_skill)
		var prereq_name = prereq_def.display_name if prereq_def else skill_def.prerequisite_skill
		var prereq_level = progression.get_skill_level(skill_def.prerequisite_skill)
		detail_prereq.text = "Требуется: " + prereq_name + " (ур. " + str(skill_def.prerequisite_level) + ") [ваш: " + str(prereq_level) + "]"
		detail_prereq.visible = true
	else:
		detail_prereq.text = ""
		detail_prereq.visible = false
	
	unlock_button.pressed.disconnect(_on_unlock_pressed) if unlock_button.pressed.is_connected(_on_unlock_pressed) else null
	unlock_button.pressed.connect(_on_unlock_pressed.bind(skill_def))

func _on_unlock_pressed(skill_def: SkillDefinition) -> void:
	var current_level = progression.get_skill_level(skill_def.id)
	if progression.unlock_skill(skill_def, 1):
		_refresh()
		_update_detail(skill_def)

func _on_skill_unlocked(skill_id: String, level: int) -> void:
	_refresh()

func _update_skill_points_display(points: int) -> void:
	skill_points_label.text = "Очки навыков: " + str(points)

func _update_level_display(level: int) -> void:
	level_label.text = "Уровень: " + str(level)

func _get_skill_by_id(skill_id: String) -> SkillDefinition:
	for skill in skill_catalog:
		if skill.id == skill_id:
			return skill
	return null
