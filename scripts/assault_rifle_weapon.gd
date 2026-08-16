extends WeaponBase
class_name AssaultRifleWeapon
signal ammo_changed(current: int, max_val: int)
signal weapon_fired

# --- WEAPON STATS ---
@export var damage_per_bullet: float = 18.0
# fire_rate inherited from WeaponBase
# range inherited from WeaponBase
@export var spread_hip: float = 3.5  # degrees
@export var spread_ads: float = 0.8  # degrees when aiming
@export var recoil_vertical: float = 1.2
@export var recoil_horizontal: float = 0.6
@export var max_ammo: int = 30
@export var reserve_ammo: int = 120
@export var reload_time: float = 2.2
@export var tactical_reload_time: float = 1.6
@export var aim_speed: float = 12.0
@export var bullet_penetration: int = 1

# --- STATE ---
var current_ammo: int = 30
var current_reserve: int = 120
var is_reloading: bool = false
var reload_timer: float = 0.0
var fire_timer: float = 0.0
var is_aiming: bool = false
var aim_progress: float = 0.0  # 0.0 to 1.0
var recoil_offset: Vector2 = Vector2.ZERO
var muzzle_flash_timer: float = 0.0

# References
var model: Node3D = null
var player: Node3D = null
var camera: Camera3D = null
var muzzle_point: Node3D = null

# VFX
var muzzle_flash_scene: PackedScene = preload("res://scenes/vfx/muzzle_flash.tscn")
var bullet_tracer_scene: PackedScene = preload("res://scenes/vfx/bullet_tracer.tscn")
var impact_spark_scene: PackedScene = preload("res://scenes/vfx/impact_spark.tscn")
var shell_casing_scene: PackedScene = preload("res://scenes/vfx/shell_casing.tscn")

func _on_equip() -> void:
	if weapon_owner:
		player = weapon_owner
		model = weapon_owner.get_node_or_null("PlayerModel")
		camera = weapon_owner.get_node_or_null("CamRoot/SpringArm3D/Camera3D")
		muzzle_point = model.get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Rifle/MuzzlePoint") if model else null
		
		current_ammo = max_ammo
		current_reserve = reserve_ammo
		is_reloading = false
		is_aiming = false
		aim_progress = 0.0
		ammo_changed.emit(current_ammo, max_ammo)

func _on_unequip() -> void:
	is_reloading = false
	is_aiming = false
	aim_progress = 0.0

func can_attack() -> bool:
	return not is_reloading and current_ammo > 0 and fire_timer <= 0.0

func attack() -> bool:
	if not can_attack():
		if current_ammo <= 0 and not is_reloading and current_reserve > 0:
			reload()
		return false
		
	fire_timer = fire_rate
	_fire_bullet()
	return true

func _fire_bullet() -> void:
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	
	# Muzzle flash
	if muzzle_flash_scene and muzzle_point:
		var flash = muzzle_flash_scene.instantiate()
		player.get_parent().add_child(flash)
		flash.global_transform = muzzle_point.global_transform
		flash.scale = Vector3(1.0, 1.0, 1.0)
	
	# Shell casing ejection
	if shell_casing_scene and model:
		var eject_point = model.get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Rifle/EjectPoint")
		if eject_point:
			var casing = shell_casing_scene.instantiate()
			player.get_parent().add_child(casing)
			casing.global_transform = eject_point.global_transform
	
	# Calculate spread
	var current_spread = lerp(spread_hip, spread_ads, aim_progress)
	var spread_rad = deg_to_rad(current_spread)
	var forward = -camera.global_transform.basis.z if camera else -player.global_transform.basis.z
	
	# Apply recoil
	recoil_offset.x += randf_range(-recoil_horizontal, recoil_horizontal)
	recoil_offset.y += recoil_vertical
	
	# Spread cone
	var dir = forward
	var rot_x = randf_range(-spread_rad, spread_rad)
	var rot_y = randf_range(-spread_rad, spread_rad)
	dir = dir.rotated(Vector3.UP, rot_y).rotated(Vector3.RIGHT, rot_x)
	
	# Raycast for bullet
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.6, 
		player.global_position + Vector3.UP * 1.6 + dir * attack_range)
	query.collision_mask = 3  # Hit enemies and walls
	query.exclude = [player.get_rid()] if player else []
	
	var result = space_state.intersect_ray(query)
	var hit_pos = player.global_position + Vector3.UP * 1.6 + dir * attack_range
	var hit_normal = -dir
	var hit_body: Node3D = null
	
	if result:
		hit_pos = result.position
		hit_normal = result.normal
		if result.collider:
			hit_body = result.collider
			
			# Apply damage
			if hit_body.has_method("take_damage"):
				hit_body.take_damage(damage_per_bullet, false, hit_pos)
			elif hit_body.has_method("apply_damage"):
				hit_body.apply_damage(damage_per_bullet, hit_pos)
				
			# Impact sparks
			if impact_spark_scene:
				var spark = impact_spark_scene.instantiate()
				player.get_parent().add_child(spark)
				spark.global_position = hit_pos
				if hit_normal.abs().dot(Vector3.UP) < 0.99: spark.look_at(spark.global_position + hit_normal, Vector3.UP)
	
	# Bullet tracer
	if bullet_tracer_scene and muzzle_point:
		var tracer = bullet_tracer_scene.instantiate()
		player.get_parent().add_child(tracer)
		tracer.setup(muzzle_point.global_position, hit_pos)
	
	weapon_fired.emit()

func aim_pressed() -> void:
	is_aiming = true

func aim_released() -> void:
	is_aiming = false

func reload() -> bool:
	if is_reloading or current_ammo >= max_ammo or current_reserve <= 0:
		return false
		
	is_reloading = true
	var is_tactical = current_ammo > 0
	reload_timer = tactical_reload_time if is_tactical else reload_time
	
	if model:
		model.play_anim("reload_rifle", 0.1)
	
	return true

func process(delta: float) -> void:
	# Fire timer
	if fire_timer > 0.0:
		fire_timer -= delta
	
	# Aim progress
	var target_aim = 1.0 if is_aiming else 0.0
	aim_progress = move_toward(aim_progress, target_aim, aim_speed * delta)
	
	# Recoil recovery
	recoil_offset = recoil_offset.move_toward(Vector2.ZERO, 15.0 * delta)
	
	# Camera recoil
	if camera and recoil_offset.length_squared() > 0.01:
		camera.rotation.x += deg_to_rad(recoil_offset.y * delta * 0.5)
		camera.rotation.y += deg_to_rad(recoil_offset.x * delta * 0.5)
	
	# Reload timer
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	
	# Muzzle flash timer
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta

func _finish_reload() -> void:
	var needed = max_ammo - current_ammo
	var available = min(needed, current_reserve)
	current_ammo += available
	current_reserve -= available
	is_reloading = false
	ammo_changed.emit(current_ammo, max_ammo)

func get_ammo_info() -> Dictionary:
	return {
		"current": current_ammo,
		"max": max_ammo,
		"reserve": current_reserve,
		"infinite": false,
		"reloading": is_reloading
	}

func get_animation_state() -> String:
	if is_reloading:
		return "reload"
	elif is_aiming:
		return "aim_idle"
	return "rifle_idle"

func get_spread() -> float:
	return lerp(spread_hip, spread_ads, aim_progress)

func get_recoil() -> Vector2:
	return recoil_offset
