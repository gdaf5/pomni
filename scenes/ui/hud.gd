extends CanvasLayer
class_name PlayerHUD

@onready var health_bar: ProgressBar = $Root/StatusContainer/HealthBar
@onready var health_label: Label = $Root/StatusContainer/HealthBar/Label
@onready var stamina_bar: ProgressBar = $Root/StatusContainer/StaminaBar
@onready var stamina_label: Label = $Root/StatusContainer/StaminaBar/Label
@onready var state_label: Label = $Root/StatusContainer/StateBadge/Label
@onready var ammo_container: HBoxContainer = $Root/StatusContainer/AmmoContainer
@onready var ammo_current: Label = $Root/StatusContainer/AmmoContainer/AmmoCurrent
@onready var ammo_reserve: Label = $Root/StatusContainer/AmmoContainer/AmmoReserve
@onready var weapon_icon: Label = $Root/StatusContainer/WeaponIcon
@onready var reload_indicator: Label = $Root/StatusContainer/AmmoContainer/ReloadIndicator
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var skill_tree_ui: SkillTreeUI = $SkillTreeUI
@onready var xp_container: VBoxContainer = $Root/XPContainer
@onready var level_label: Label = $Root/XPContainer/LevelLabel
@onready var xp_bar: ProgressBar = $Root/XPContainer/XPBar
@onready var xp_bar_label: Label = $Root/XPContainer/XPBar/Label

var current_hp_val: float = 100.0
var max_hp_val: float = 100.0
var current_stm_val: float = 100.0
var max_stm_val: float = 100.0

var _player: Player = null

@onready var toast_label: Label = $Root/Toast

func _ready() -> void:
	ammo_container.visible = false
	add_to_group("hud")
	inventory_ui.closed.connect(_on_panel_closed)
	skill_tree_ui.closed.connect(_on_panel_closed)
	GameManager.init_progression()
	GameManager.player_progression.stats_updated.connect(_update_xp_display)
	GameManager.player_progression.level_up.connect(_on_level_up)
	_update_xp_display()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle_panel(inventory_ui)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("skill_tree"):
		_toggle_panel(skill_tree_ui)
		get_viewport().set_input_as_handled()

func _toggle_panel(panel: Control) -> void:
	if not _player:
		return
	# Закрыть другое окно, чтобы не пересекались
	if panel == inventory_ui and skill_tree_ui.visible:
		skill_tree_ui.toggle()
	if panel == skill_tree_ui and inventory_ui.visible:
		inventory_ui.toggle(_player)
	var now_open = not panel.visible
	if panel == inventory_ui:
		inventory_ui.toggle(_player)
	elif panel == skill_tree_ui:
		skill_tree_ui.toggle()
	_player.input_locked = now_open

func _on_panel_closed() -> void:
	if _player:
		_player.input_locked = false

func show_toast(text: String, duration: float = 2.5) -> void:
	toast_label.text = text
	toast_label.visible = true
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(func(): toast_label.visible = false)

func _update_xp_display() -> void:
	var prog := GameManager.player_progression
	if not prog:
		return
	level_label.text = "УРОВЕНЬ %d" % prog.current_level
	xp_bar.max_value = max(1, prog.xp_to_next_level)
	xp_bar.value = prog.current_xp
	xp_bar_label.text = "%d / %d XP" % [prog.current_xp, prog.xp_to_next_level]

func _on_level_up(level: int) -> void:
	show_toast("НОВЫЙ УРОВЕНЬ %d! +1 очко навыка (клавиша K)" % level)
	_update_xp_display()

func connect_to_player(player: Player) -> void:
	_player = player
	player.health_changed.connect(set_health)
	player.stamina_changed.connect(set_stamina)
	player.state_changed.connect(set_state)
	player.weapon_changed.connect(set_weapon)
	player.ammo_changed.connect(set_ammo)

func set_health(current: float, max_val: float) -> void:
	current_hp_val = current
	max_hp_val = max_val
	health_bar.max_value = max_val
	
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	health_label.text = "%d / %d HP" % [int(current), int(max_val)]

func set_stamina(current: float, max_val: float) -> void:
	current_stm_val = current
	max_stm_val = max_val
	stamina_bar.max_value = max_val
	stamina_bar.value = current
	stamina_label.text = "%d / %d STAMINA" % [int(current), int(max_val)]

func set_weapon(weapon_name: String) -> void:
	if weapon_name == "Assault Rifle":
		weapon_icon.text = "🔫"
		ammo_container.visible = true
	elif weapon_name == "Sword":
		weapon_icon.text = "⚔"
		ammo_container.visible = false

func set_ammo(current: int, max_val: int, reserve: int) -> void:
	if max_val <= 0:
		ammo_container.visible = false
		return
		
	ammo_container.visible = true
	ammo_current.text = str(current)
	ammo_reserve.text = "/ %d" % reserve
	
	# Color coding
	if current <= max_val * 0.25:
		ammo_current.modulate = Color(1.0, 0.3, 0.3)
	else:
		ammo_current.modulate = Color(1.0, 1.0, 1.0)

func set_state(state_name: String) -> void:
	var display_name = state_name
	match state_name:
		"IDLE": display_name = "ГОТОВ"
		"WALK": display_name = "ХОДЬБА"
		"SPRINT": display_name = "СПРИНТ"
		"JUMP": display_name = "ПРЫЖОК"
		"FALL": display_name = "ПАДЕНИЕ"
		"ROLL": display_name = "КУВЫРОК (I-FRAMES)"
		"ATTACK_LIGHT": display_name = "АТАКА 1 (ЛКМ)"
		"ATTACK_LIGHT_2": display_name = "КОМБО 2 (ЛКМ)"
		"ATTACK_LIGHT_3": display_name = "КОМБО 3 (ЛКМ)"
		"ATTACK_LIGHT_4": display_name = "ФИНИШЕР (ЛКМ)"
		"ATTACK_HEAVY": display_name = "СИЛЬНЫЙ УДАР (ПКМ)"
		"ATTACK_HEAVY_FINISHER": display_name = "УЛЬТИМЕЙТ (ПКМ)"
		"BLOCK": display_name = "БЛОК (F)"
		"RELOAD": display_name = "ПЕРЕЗАРЯДКА (R)"
		"DANCE": display_name = "ТАНЕЦ (B) 🕺"
		"HIT_REACT": display_name = "ПОПАДАНИЕ"
		"DEAD": display_name = "ПАВШИЙ"
		
	state_label.text = "РЕЖИМ: " + display_name
