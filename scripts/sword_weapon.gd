extends WeaponBase
class_name SwordWeapon

@export var combo_damages: Array[float] = [25.0, 35.0, 45.0, 65.0]
@export var heavy_damage: float = 75.0
@export var heavy_finisher_damage: float = 110.0
@export var stamina_cost_light: float = 0.0
@export var stamina_cost_heavy: float = 25.0

var current_combo_step: int = 1
var can_combo: bool = false
var is_heavy_charging: bool = false
var heavy_charge_time: float = 0.0
var combo_timer: float = 0.0
var max_combo_window: float = 0.8

var model: Node3D = null
var player: Node3D = null

func _on_equip() -> void:
	if weapon_owner:
		player = weapon_owner
		model = weapon_owner.get_node_or_null("PlayerModel")
		current_combo_step = 1
		can_combo = false

func _on_unequip() -> void:
	current_combo_step = 1
	can_combo = false

func can_attack() -> bool:
	return true

func attack() -> bool:
	if not model:
		return false
		
	if is_heavy_charging:
		_execute_heavy()
		return true
		
	var anim_name = "attack_light"
	var atk_damage = combo_damages[0]
	
	match current_combo_step:
		1:
			anim_name = "attack_light"
			atk_damage = combo_damages[0]
		2:
			anim_name = "attack_light_2"
			atk_damage = combo_damages[1]
		3:
			anim_name = "attack_light_3"
			atk_damage = combo_damages[2]
		4:
			anim_name = "attack_light_4"
			atk_damage = combo_damages[3]
			
	model.play_anim(anim_name, 0.06, 1.25)
	can_combo = false
	combo_timer = 0.0
	
	var start_time = 0.08
	var end_time = 0.28
	if current_combo_step == 4:
		start_time = 0.18
		end_time = 0.42
		
	var current_step = current_combo_step
	get_tree().create_timer(start_time).timeout.connect(func():
		if is_equipped and model:
			model.start_attack_hitbox(atk_damage, current_step == 4)
	)
	get_tree().create_timer(end_time).timeout.connect(func():
		if is_equipped and model:
			model.stop_attack_hitbox()
			can_combo = true
			combo_timer = max_combo_window
	)
	
	current_combo_step += 1
	if current_combo_step > combo_damages.size():
		current_combo_step = 1
		
	return true

func start_heavy() -> void:
	is_heavy_charging = true
	heavy_charge_time = 0.0

func attack_heavy() -> bool:
	if not model:
		return false
		
	if is_heavy_charging:
		_execute_heavy()
	else:
		model.play_anim("attack_heavy_finisher", 0.08, 1.1)
		get_tree().create_timer(0.42).timeout.connect(func():
			if is_equipped and model:
				model.start_attack_hitbox(heavy_finisher_damage, true)
		)
		get_tree().create_timer(0.72).timeout.connect(func():
			if is_equipped and model:
				model.stop_attack_hitbox()
				can_combo = true
				combo_timer = max_combo_window
		)
	return true

func _execute_heavy() -> void:
	is_heavy_charging = false
	model.play_anim("attack_heavy", 0.08, 1.0)
	get_tree().create_timer(0.38).timeout.connect(func():
		if is_equipped and model:
			model.start_attack_hitbox(heavy_damage, true)
	)
	get_tree().create_timer(0.65).timeout.connect(func():
		if is_equipped and model:
			model.stop_attack_hitbox()
			can_combo = true
			combo_timer = max_combo_window
	)

func block() -> void:
	if model:
		model.play_anim("block", 0.12)

func process(delta: float) -> void:
	if can_combo:
		combo_timer -= delta
		if combo_timer <= 0.0:
			can_combo = false
			current_combo_step = 1
			
	if is_heavy_charging:
		heavy_charge_time += delta

func get_animation_state() -> String:
	if is_heavy_charging:
		return "heavy_charge"
	return "idle"

func get_combo_step() -> int:
	return current_combo_step

func can_combo_continue() -> bool:
	return can_combo
