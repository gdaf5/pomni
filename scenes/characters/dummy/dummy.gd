extends CharacterBody3D
class_name TrainingDummy

@export var max_health: float = 200.0
@export var display_name: String = "🎯 МАНЕКЕН"
@export var attack_damage: float = 20.0
var health: float = 200.0

@onready var model_pivot: Node3D = $ModelPivot
@onready var hp_label: Label3D = $HPLabel
@onready var respawn_timer: Timer = $RespawnTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_area: Area3D = $AttackArea

var is_dead: bool = false
var wobble_angle: Vector3 = Vector3.ZERO
var wobble_velocity: Vector3 = Vector3.ZERO
var original_materials: Dictionary = {}

@export var respawns: bool = true
@export var loot_table: Array[Dictionary] = []
@export var loot_on_death: bool = false
@export var xp_value: int = 0

var hit_vfx_scene: PackedScene = preload("res://scenes/vfx/hit_particles.tscn")
var damage_num_scene: PackedScene = preload("res://scenes/vfx/damage_number.tscn")
var pickup_scene: PackedScene = preload("res://scenes/world/pickup.tscn")

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_update_hp_display()
	_cache_materials()
	
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start(4.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Damped harmonic spring physics for satisfying wobble when struck
	var spring_k = 120.0
	var damping = 12.0
	var spring_force = -wobble_angle * spring_k - wobble_velocity * damping
	wobble_velocity += spring_force * delta
	wobble_angle += wobble_velocity * delta
	
	model_pivot.rotation = wobble_angle

func take_damage(amount: float, is_heavy: bool, source_pos: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
		
	health = max(0, health - amount)
	_update_hp_display()
	
	# Impulse wobble away from attacker
	var hit_dir = (global_position - source_pos).normalized()
	var _tilt_axis = Vector3(-hit_dir.z, 0, hit_dir.x).normalized()
	var impulse_strength = 14.0 if is_heavy else 7.0
	wobble_velocity += Vector3(hit_dir.z, 0, -hit_dir.x) * impulse_strength
	
	# Hit flash
	_flash_red(is_heavy)
	
	# Spawn particles and damage number
	_spawn_hit_sparks(global_position + Vector3.UP * 1.2, is_heavy)
	_spawn_damage_number(amount, is_heavy)
	
	if health <= 0:
		_die()

func _flash_red(is_heavy: bool) -> void:
	var flash_color = Color(1.0, 0.2, 0.2, 1.0) if is_heavy else Color(1.0, 0.7, 0.7, 1.0)
	for mesh in _find_all_meshes(model_pivot):
		if mesh is MeshInstance3D and mesh.material_override:
			var mat = mesh.material_override as StandardMaterial3D
			if mat:
				mat.emission_enabled = true
				mat.emission = flash_color
				mat.emission_energy_multiplier = 4.0
				
	await get_tree().create_timer(0.12).timeout
	for mesh in _find_all_meshes(model_pivot):
		if mesh is MeshInstance3D and mesh.material_override:
			var mat = mesh.material_override as StandardMaterial3D
			if mat:
				mat.emission_enabled = false

func _die() -> void:
	is_dead = true
	hp_label.text = "💀 ПОВЕРЖЕН"
	hp_label.modulate = Color(1.0, 0.2, 0.2)
	
	# Knock flat
	var tween = create_tween().set_parallel(true)
	tween.tween_property(model_pivot, "rotation:x", -1.5, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(model_pivot, "position:y", 0.1, 0.4)
	
	if loot_on_death:
		_spawn_loot()
	
	if xp_value > 0:
		GameManager.add_xp(xp_value)
		_show_xp_gain(xp_value)
	
	if not respawns:
		return
	
	# Respawn after 2.5 seconds
	await get_tree().create_timer(2.5).timeout
	_respawn()

func _spawn_loot() -> void:
	for loot in loot_table:
		var item_id: String = loot.get("id", "")
		var count: int = int(loot.get("count", 1))
		if item_id == "" or count <= 0:
			continue
		var pickup := pickup_scene.instantiate() as Pickup
		get_parent().add_child(pickup)
		pickup.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0))
		pickup.setup(item_id, count)

func _show_xp_gain(amount: int) -> void:
	var label := Label3D.new()
	label.text = "+" + str(amount) + " XP"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 34
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 1)
	label.modulate = Color(0.4, 0.9, 1.0, 1.0)
	label.position = Vector3(0, 2.4, 0)
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", 3.6, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)

func _respawn() -> void:
	health = max_health
	is_dead = false
	wobble_angle = Vector3.ZERO
	wobble_velocity = Vector3.ZERO
	model_pivot.position = Vector3.ZERO
	model_pivot.rotation = Vector3.ZERO
	_update_hp_display()

func _update_hp_display() -> void:
	hp_label.text = "%s\n%d / %d HP" % [display_name, int(health), int(max_health)]
	var ratio = health / max_health
	if ratio > 0.5:
		hp_label.modulate = Color(0.2, 1.0, 0.4)
	elif ratio > 0.25:
		hp_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		hp_label.modulate = Color(1.0, 0.3, 0.2)

func _on_attack_timer_timeout() -> void:
	if is_dead:
		return
	# Periodic test strike against nearby player so player can practice Blocking (F) and Rolling (Q)
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body is Player:
				# Telegraph swing
				var tween = create_tween()
				tween.tween_property(model_pivot, "rotation:y", 0.8, 0.3)
				tween.tween_property(model_pivot, "rotation:y", -1.2, 0.15)
				tween.tween_callback(func():
					if not is_dead and body and is_instance_valid(body) and body.has_method("take_damage"):
						body.take_damage(20.0, false, global_position)
				)
				tween.tween_property(model_pivot, "rotation:y", 0.0, 0.4)

func _spawn_hit_sparks(pos: Vector3, is_heavy: bool) -> void:
	if not hit_vfx_scene:
		return
	var vfx = hit_vfx_scene.instantiate() as Node3D
	get_parent().add_child(vfx)
	vfx.global_position = pos
	if vfx.has_method("setup"):
		vfx.setup(is_heavy)

func _spawn_damage_number(amount: float, is_heavy: bool) -> void:
	if not damage_num_scene:
		return
	var dmg = damage_num_scene.instantiate() as Node3D
	get_parent().add_child(dmg)
	dmg.global_position = global_position + Vector3.UP * 2.2 + Vector3(randf_range(-0.3, 0.3), randf_range(0, 0.3), randf_range(-0.3, 0.3))
	if dmg.has_method("setup"):
		dmg.setup(amount, is_heavy)

func _cache_materials() -> void:
	for mesh in _find_all_meshes(model_pivot):
		if mesh is MeshInstance3D and mesh.get_surface_override_material(0):
			var mat = mesh.get_surface_override_material(0).duplicate()
			mesh.material_override = mat

func _find_all_meshes(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_meshes(child))
	return result
