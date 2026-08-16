extends CharacterBody3D
class_name Player

signal health_changed(current: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal state_changed(state_name: String)
signal weapon_changed(weapon_name: String)
signal ammo_changed(current: int, max_val: int, reserve: int)

enum State {
	IDLE,
	WALK,
	SPRINT,
	JUMP,
	FALL,
	ROLL,
	SLIDE,
	ATTACK_LIGHT,
	ATTACK_LIGHT_2,
	ATTACK_LIGHT_3,
	ATTACK_LIGHT_4,
	ATTACK_HEAVY,
	ATTACK_HEAVY_FINISHER,
	BLOCK,
	RELOAD,
	DANCE,
	HIT_REACT,
	DEAD
}

enum WeaponType {
	SWORD,
	RIFLE
}

# --- STATS ---
@export_group("Stats")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 30.0
@export var sprint_stamina_cost: float = 15.0
@export var roll_stamina_cost: float = 20.0
@export var slide_stamina_cost: float = 15.0
@export var heavy_attack_stamina_cost: float = 25.0

# --- MOVEMENT ---
@export_group("Movement")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 8.5
@export var roll_speed: float = 11.0
@export var slide_speed: float = 22.0
@export var jump_velocity: float = 6.2
@export var rotation_speed: float = 12.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -70.0
@export var max_pitch: float = 50.0

# --- COMBAT ---
@export_group("Combat")
@export var magnet_range: float = 9.5
@export var magnet_angle_deg: float = 80.0

var health: float = 100.0
var stamina: float = 100.0
var current_state: State = State.IDLE
var state_timer: float = 0.0
var roll_direction: Vector3 = Vector3.FORWARD
var slide_direction: Vector3 = Vector3.FORWARD
var can_combo_next: bool = false
var is_invulnerable: bool = false
var current_target: Node3D = null
var _was_aiming: bool = false
var _wants_jump: bool = false
var _switching_weapon: bool = false
# var _airStrafeSpeed: float = 0.0

var current_weapon: WeaponType = WeaponType.SWORD
var sword_weapon: SwordWeapon = null
var rifle_weapon: AssaultRifleWeapon = null
var active_weapon: WeaponBase = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * 1.5
var is_aiming: bool = false

@onready var model: PlayerModel = $PlayerModel
@onready var cam_root: Node3D = $CamRoot
@onready var spring_arm: SpringArm3D = $CamRoot/SpringArm3D
@onready var camera: Camera3D = $CamRoot/SpringArm3D/Camera3D
@onready var player_collider: CollisionShape3D = $CollisionShape3D

var slash_vfx_scene: PackedScene = preload("res://scenes/vfx/slash_effect.tscn")
var hit_vfx_scene: PackedScene = preload("res://scenes/vfx/hit_particles.tscn")
var damage_num_scene: PackedScene = preload("res://scenes/vfx/damage_number.tscn")

# Блокирует управление (когда открыт инвентарь/меню)
var input_locked: bool = false

func _ready() -> void:
	health = max_health
	stamina = max_stamina
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	
	_setup_weapons()
	_setup_fallback_inputs()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if model:
		model.hit_registered.connect(_on_model_hit_registered)

func _setup_weapons() -> void:
	sword_weapon = SwordWeapon.new()
	sword_weapon.weapon_name = "Sword"
	sword_weapon.damage = 25.0
	sword_weapon.combo_damages = [25.0, 35.0, 45.0, 65.0]
	sword_weapon.heavy_damage = 75.0
	sword_weapon.heavy_finisher_damage = 110.0
	sword_weapon.stamina_cost_heavy = 25.0
	
	rifle_weapon = AssaultRifleWeapon.new()
	rifle_weapon.weapon_name = "Assault Rifle"
	rifle_weapon.damage_per_bullet = 18.0
	rifle_weapon.fire_rate = 0.08
	rifle_weapon.attack_range = 80.0
	rifle_weapon.max_ammo = 30
	rifle_weapon.reserve_ammo = 120
	rifle_weapon.reload_time = 2.2
	rifle_weapon.tactical_reload_time = 1.6
	rifle_weapon.spread_hip = 3.5
	rifle_weapon.spread_ads = 0.8
	rifle_weapon.recoil_vertical = 1.2
	rifle_weapon.recoil_horizontal = 0.6
	rifle_weapon.aim_speed = 12.0
	rifle_weapon.ammo_changed.connect(_on_ammo_changed)
	rifle_weapon.weapon_fired.connect(_on_weapon_fired)
	
	_switch_weapon(WeaponType.SWORD)

func _switch_weapon(new_weapon: WeaponType) -> void:
	if active_weapon:
		active_weapon.unequip()
	
	current_weapon = new_weapon
	
	match current_weapon:
		WeaponType.SWORD:
			active_weapon = sword_weapon
			if model:
				model.set_weapon_visible("sword")
		WeaponType.RIFLE:
			active_weapon = rifle_weapon
			if model:
				model.set_weapon_visible("rifle")
	
	if active_weapon:
		active_weapon.equip(self)
	
	weapon_changed.emit(active_weapon.weapon_name)
	var ammo_info = active_weapon.get_ammo_info()
	ammo_changed.emit(ammo_info.current, ammo_info.max, ammo_info.get("reserve", 0))
	
	# Reset aiming when switching
	is_aiming = false
	_was_aiming = false
	if active_weapon:
		active_weapon.aim_released()
	
	_switching_weapon = true
	# Re-trigger current state animation for new weapon
	change_state(current_state)
	_switching_weapon = false

func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		cam_root.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, min_pitch, max_pitch)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.3, 1.8, 6.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.3, 1.8, 6.0)

	# Weapon switching: 1 = Sword, 2 = Rifle
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 and current_weapon != WeaponType.SWORD:
			_switch_weapon(WeaponType.SWORD)
		elif event.keycode == KEY_2 and current_weapon != WeaponType.RIFLE:
			_switch_weapon(WeaponType.RIFLE)
		elif event.keycode == KEY_R and current_weapon == WeaponType.RIFLE:
			if rifle_weapon:
				rifle_weapon.reload()

	# Aim (Right Mouse Button) - only for rifle
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and current_weapon == WeaponType.RIFLE:
			if event.pressed:
				is_aiming = true
				if rifle_weapon:
					rifle_weapon.aim_pressed()
			else:
				is_aiming = false
				if rifle_weapon:
					rifle_weapon.aim_released()

func _physics_process(delta: float) -> void:
	state_timer += delta
	_handle_stamina_regen(delta)
	
	# Update active weapon
	if active_weapon:
		active_weapon.process(delta)
	
	if input_locked:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	# Dynamic ADS Camera Zoom and Recoil for Rifle
	if current_weapon == WeaponType.RIFLE:
		if is_aiming:
			spring_arm.spring_length = lerp(spring_arm.spring_length, 2.0, 10.0 * delta)
			camera.fov = lerp(camera.fov, 52.0, 10.0 * delta)
			var cam_fwd = -cam_root.global_transform.basis.z
			cam_fwd.y = 0
			if cam_fwd.length_squared() > 0.01:
				var target_rot = atan2(-cam_fwd.x, -cam_fwd.z)
				model.rotation.y = lerp_angle(model.rotation.y, target_rot, 15.0 * delta)
		else:
			spring_arm.spring_length = lerp(spring_arm.spring_length, 3.8, 8.0 * delta)
			camera.fov = lerp(camera.fov, 72.0, 8.0 * delta)
	else:
		spring_arm.spring_length = lerp(spring_arm.spring_length, 3.8, 8.0 * delta)
		camera.fov = lerp(camera.fov, 72.0, 8.0 * delta)
	
	match current_state:
		State.IDLE, State.WALK, State.SPRINT:
			_process_locomotion(delta)
		State.JUMP, State.FALL:
			_process_air(delta)
		State.ROLL:
			_process_roll(delta)
		State.SLIDE:
			_process_slide(delta)
		State.ATTACK_LIGHT:
			_process_attack_light(delta, 1)
		State.ATTACK_LIGHT_2:
			_process_attack_light(delta, 2)
		State.ATTACK_LIGHT_3:
			_process_attack_light(delta, 3)
		State.ATTACK_LIGHT_4:
			_process_attack_light(delta, 4)
		State.ATTACK_HEAVY:
			_process_attack_heavy(delta, false)
		State.ATTACK_HEAVY_FINISHER:
			_process_attack_heavy(delta, true)
		State.BLOCK:
			_process_block(delta)
		State.RELOAD:
			_process_reload(delta)
		State.DANCE:
			_process_dance(delta)
		State.HIT_REACT:
			_process_hit_react(delta)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0, 5.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 5.0 * delta)
			if not is_on_floor():
				velocity.y -= gravity * delta
			move_and_slide()

func change_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return
		
	if _is_attack_state(current_state) or current_state == State.RELOAD:
		if active_weapon and active_weapon is SwordWeapon:
			if model:
				model.stop_attack_hitbox()
	
	if current_state == State.ROLL:
		is_invulnerable = false
	if current_state == State.SLIDE:
		is_invulnerable = false
		_restore_collider()
		
	var _old_state = current_state
	# Prevent weapon-switch re-triggering jump
	if new_state == State.JUMP and _switching_weapon:
		new_state = State.IDLE
	current_state = new_state
	state_timer = 0.0
	state_changed.emit(State.keys()[new_state])
	
	if _is_attack_state(new_state):
		_apply_combat_magnetism()
	
	match current_state:
		State.IDLE:
			if model:
				if current_weapon == WeaponType.RIFLE:
					model.play_anim("aim_idle" if is_aiming else "rifle_idle", 0.2)
				else:
					model.play_anim("idle", 0.2)
		State.WALK:
			if model:
				if current_weapon == WeaponType.RIFLE and is_aiming:
					model.play_anim("aim_idle", 0.15)
				else:
					model.play_anim("walk", 0.15, 1.1)
		State.SPRINT:
			if current_weapon == WeaponType.RIFLE and is_aiming:
				is_aiming = false
				_was_aiming = false
				if rifle_weapon:
					rifle_weapon.aim_released()
			if model:
				model.play_anim("sprint", 0.15, 1.2)
		State.JUMP:
			velocity.y = jump_velocity
			if model:
				model.play_anim("jump_start", 0.08)
		State.FALL:
			if model:
				model.play_anim("jump_loop", 0.2)
		State.ROLL:
			is_invulnerable = true
			stamina = max(0, stamina - roll_stamina_cost)
			stamina_changed.emit(stamina, max_stamina)
			if model:
				model.play_anim("roll", 0.05, 1.15)
		State.SLIDE:
			is_invulnerable = true
			stamina = max(0, stamina - slide_stamina_cost)
			stamina_changed.emit(stamina, max_stamina)
			_squash_collider()
			if model:
				model.play_anim("slide", 0.05, 1.2)
		State.ATTACK_LIGHT:
			_execute_sword_attack(1)
		State.ATTACK_LIGHT_2:
			_execute_sword_attack(2)
		State.ATTACK_LIGHT_3:
			_execute_sword_attack(3)
		State.ATTACK_LIGHT_4:
			_execute_sword_attack(4)
		State.ATTACK_HEAVY:
			_execute_heavy_attack(false)
		State.ATTACK_HEAVY_FINISHER:
			_execute_heavy_attack(true)
		State.BLOCK:
			if model:
				model.play_anim("block", 0.12)
			if sword_weapon:
				sword_weapon.block()
		State.RELOAD:
			if model:
				model.play_anim("reload_rifle", 0.1)
		State.DANCE:
			if model:
				model.play_anim("dance", 0.2)
		State.HIT_REACT:
			if model:
				model.play_anim("hit", 0.05)

func _execute_sword_attack(step: int) -> void:
	if not sword_weapon:
		return
		
	can_combo_next = false
	var anim_name = ""
	var damage = 0.0
	var start_time = 0.08
	var end_time = 0.28
	var is_heavy = false
	
	match step:
		1:
			anim_name = "attack_light"
			damage = sword_weapon.combo_damages[0]
		2:
			anim_name = "attack_light_2"
			damage = sword_weapon.combo_damages[1]
		3:
			anim_name = "attack_light_3"
			damage = sword_weapon.combo_damages[2]
		4:
			anim_name = "attack_light_4"
			damage = sword_weapon.combo_damages[3]
			start_time = 0.18
			end_time = 0.42
			is_heavy = true
			
	if model:
		model.play_anim(anim_name, 0.06, 1.25)
	
	_spawn_slash_vfx(is_heavy)
	
	get_tree().create_timer(start_time).timeout.connect(func():
		if _is_attack_state(current_state) and model:
			model.start_attack_hitbox(damage, is_heavy)
	)
	get_tree().create_timer(end_time).timeout.connect(func():
		if _is_attack_state(current_state) and model:
			model.stop_attack_hitbox()
			can_combo_next = true
			combo_timer = 0.8
	)

func _execute_heavy_attack(is_finisher: bool) -> void:
	if not sword_weapon:
		return
		
	if is_finisher:
		stamina = max(0, stamina - sword_weapon.stamina_cost_heavy)
		stamina_changed.emit(stamina, max_stamina)
		if model:
			model.play_anim("attack_heavy_finisher", 0.08, 1.1)
		get_tree().create_timer(0.42).timeout.connect(func():
			if current_state == State.ATTACK_HEAVY_FINISHER and model:
				model.start_attack_hitbox(sword_weapon.heavy_finisher_damage, true)
		)
		get_tree().create_timer(0.72).timeout.connect(func():
			if current_state == State.ATTACK_HEAVY_FINISHER and model:
				model.stop_attack_hitbox()
				can_combo_next = true
				combo_timer = 0.8
		)
	else:
		stamina = max(0, stamina - sword_weapon.stamina_cost_heavy)
		stamina_changed.emit(stamina, max_stamina)
		if model:
			model.play_anim("attack_heavy", 0.08, 1.0)
		get_tree().create_timer(0.38).timeout.connect(func():
			if current_state == State.ATTACK_HEAVY and model:
				model.start_attack_hitbox(sword_weapon.heavy_damage, true)
		)
		get_tree().create_timer(0.65).timeout.connect(func():
			if current_state == State.ATTACK_HEAVY and model:
				model.stop_attack_hitbox()
				can_combo_next = true
				combo_timer = 0.8
		)

var combo_timer: float = 0.0

func _process_locomotion(delta: float) -> void:
	if not is_on_floor():
		change_state(State.FALL)
		return
	
	# Detect aim transitions for rifle locomotion animations
	if current_weapon == WeaponType.RIFLE:
		if is_aiming != _was_aiming:
			_was_aiming = is_aiming
			if model:
				if is_aiming:
					model.play_anim("aim_idle", 0.15)
				else:
					var move_dir_check = _get_input_direction()
					if move_dir_check.length_squared() > 0.01:
						model.play_anim("walk", 0.15, 1.1)
					else:
						model.play_anim("rifle_idle", 0.2)
		
		# Weapon-specific inputs
		if Input.is_action_pressed("attack_light") and rifle_weapon and rifle_weapon.can_attack():
			rifle_weapon.attack()
		if Input.is_action_just_pressed("attack_heavy"):
			# Toggle aim already handled in _unhandled_input
			pass
		if Input.is_action_just_pressed("reload") or (rifle_weapon and rifle_weapon.get_ammo_info().current <= 0 and Input.is_action_pressed("attack_light")):
			if rifle_weapon and rifle_weapon.reload():
				change_state(State.RELOAD)
			return
	else:
		if Input.is_action_just_pressed("attack_heavy") and stamina >= sword_weapon.stamina_cost_heavy:
			change_state(State.ATTACK_HEAVY)
			return
		if Input.is_action_just_pressed("attack_light"):
			change_state(State.ATTACK_LIGHT)
			return
		if Input.is_action_pressed("block"):
			change_state(State.BLOCK)
			return
	
	if Input.is_action_just_pressed("roll") and stamina >= roll_stamina_cost:
		var input_dir = _get_input_direction()
		roll_direction = input_dir if input_dir.length_squared() > 0.01 else -cam_root.global_transform.basis.z
		roll_direction.y = 0
		roll_direction = roll_direction.normalized()
		change_state(State.ROLL)
		return
	if Input.is_action_just_pressed("slide") and stamina >= slide_stamina_cost:
		var input_dir = _get_input_direction()
		slide_direction = input_dir if input_dir.length_squared() > 0.01 else -cam_root.global_transform.basis.z
		slide_direction.y = 0
		slide_direction = slide_direction.normalized()
		change_state(State.SLIDE)
		return
	if Input.is_action_just_pressed("jump"):
		_wants_jump = true
		change_state(State.JUMP)
		return
	if Input.is_action_just_pressed("dance"):
		change_state(State.DANCE)
		return
		
	var move_dir = _get_input_direction()
	var is_moving = move_dir.length_squared() > 0.01
	var is_sprinting = Input.is_action_pressed("sprint") and is_moving and stamina > 2.0
	
	var target_speed = (sprint_speed if is_sprinting else walk_speed) if is_moving else 0.0
	
	if is_sprinting:
		stamina = max(0, stamina - sprint_stamina_cost * delta)
		stamina_changed.emit(stamina, max_stamina)
		if current_state != State.SPRINT:
			change_state(State.SPRINT)
	elif is_moving:
		if current_state != State.WALK:
			change_state(State.WALK)
	else:
		if current_state != State.IDLE:
			change_state(State.IDLE)
			
	var h_vel = Vector2(velocity.x, velocity.z)
	var target_h_vel = Vector2(move_dir.x, move_dir.z) * target_speed
	h_vel = h_vel.move_toward(target_h_vel, 25.0 * delta)
	velocity.x = h_vel.x
	velocity.z = h_vel.y
	velocity.y = 0.0
	
	if is_moving:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rot_y, rotation_speed * delta)
		
	move_and_slide()

func _process_air(delta: float) -> void:
	velocity.y -= gravity * delta
	
	# Air strafing: add velocity in camera-right direction when holding A/D
	var raw_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var cam_right = cam_root.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	# Strafe acceleration (Quake/HL style: only sideways matters)
	var air_accel = 50.0 * delta
	velocity.x += cam_right.x * raw_input.x * air_accel
	velocity.z += cam_right.z * raw_input.x * air_accel
	
	# Small forward influence
	var cam_forward = -cam_root.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	velocity.x += cam_forward.x * raw_input.y * air_accel * 0.15
	velocity.z += cam_forward.z * raw_input.y * air_accel * 0.15
	
	# Allow shooting while airborne
	if current_weapon == WeaponType.RIFLE:
		if Input.is_action_pressed("attack_light") and rifle_weapon and rifle_weapon.can_attack():
			rifle_weapon.attack()
		if Input.is_action_just_pressed("reload") or (rifle_weapon and rifle_weapon.get_ammo_info().get("current", 0) <= 0 and Input.is_action_pressed("attack_light")):
			if rifle_weapon and rifle_weapon.reload():
				change_state(State.RELOAD)
				return
	
	# Cap air speed at 2x sprint
	var h_speed = Vector2(velocity.x, velocity.z).length()
	if h_speed > sprint_speed * 2.0:
		var ratio = (sprint_speed * 2.0) / h_speed
		velocity.x *= ratio
		velocity.z *= ratio
	
	# Model faces movement direction in air
	var h_vel = Vector2(velocity.x, velocity.z)
	if h_vel.length_squared() > 0.5:
		var target_rot_y = atan2(-h_vel.x, -h_vel.y)
		model.rotation.y = lerp_angle(model.rotation.y, target_rot_y, 10.0 * delta)
	
	move_and_slide()
	
	if is_on_floor():
		if _wants_jump and Input.is_action_pressed("jump"):
			_wants_jump = false
			# Preserve horizontal velocity for bhop chain
			change_state(State.JUMP)
		else:
			_wants_jump = false
			if model:
				model.play_anim("jump_land", 0.05)
			change_state(State.IDLE)

func _process_roll(delta: float) -> void:
	var target_rot = atan2(-roll_direction.x, -roll_direction.z)
	model.rotation.y = target_rot
	
	var speed_ratio = 1.0 - (state_timer / 0.65)
	var current_roll_speed = roll_speed * max(0.2, speed_ratio)
	velocity.x = roll_direction.x * current_roll_speed
	velocity.z = roll_direction.z * current_roll_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		
	move_and_slide()
	if state_timer >= 0.65:
		change_state(State.IDLE)

func _process_slide(delta: float) -> void:
	var target_rot = atan2(-slide_direction.x, -slide_direction.z)
	model.rotation.y = target_rot
	
	# Резкий рывок в начале, плавное затухание к концу
	var slide_duration = 0.5
	var speed_ratio = 1.0 - (state_timer / slide_duration)
	var current_slide_speed = slide_speed * max(0.2, pow(speed_ratio, 1.5))
	velocity.x = slide_direction.x * current_slide_speed
	velocity.z = slide_direction.z * current_slide_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		
	move_and_slide()
	if state_timer >= slide_duration:
		change_state(State.IDLE)

# Сплющивает коллизию для слайда — позволяет проползать под низкими препятствиями
func _squash_collider() -> void:
	if not player_collider or not player_collider.shape:
		return
	var shape = player_collider.shape as CapsuleShape3D
	if not shape:
		return
	shape.height = 0.7
	player_collider.position.y = 0.45
	if cam_root:
		cam_root.position.y = 0.75

# Восстанавливает коллизию после слайда
func _restore_collider() -> void:
	if not player_collider or not player_collider.shape:
		return
	var shape = player_collider.shape as CapsuleShape3D
	if not shape:
		return
	shape.height = 1.85
	player_collider.position.y = 0.925
	if cam_root:
		cam_root.position.y = 1.45

func _process_attack_light(delta: float, step: int) -> void:
	_process_lunge_physics(delta, 12.0 if step == 4 else 8.5)
	
	if can_combo_next:
		if current_weapon == WeaponType.SWORD:
			if Input.is_action_just_pressed("attack_heavy") and stamina >= sword_weapon.stamina_cost_heavy and (step == 3 or step == 4):
				change_state(State.ATTACK_HEAVY_FINISHER)
				return
			if Input.is_action_just_pressed("attack_light"):
				match step:
					1: change_state(State.ATTACK_LIGHT_2)
					2: change_state(State.ATTACK_LIGHT_3)
					3: change_state(State.ATTACK_LIGHT_4)
					4: change_state(State.ATTACK_LIGHT)
				return
				
	if Input.is_action_just_pressed("roll") and stamina >= roll_stamina_cost:
		var input_dir = _get_input_direction()
		roll_direction = input_dir if input_dir.length_squared() > 0.01 else -model.global_transform.basis.z
		change_state(State.ROLL)
		return
	if Input.is_action_just_pressed("slide") and stamina >= slide_stamina_cost:
		var input_dir = _get_input_direction()
		slide_direction = input_dir if input_dir.length_squared() > 0.01 else -model.global_transform.basis.z
		change_state(State.SLIDE)
		return
		
	var max_dur = 0.45 if step == 1 else (0.5 if step == 2 else (0.55 if step == 3 else 0.6))
	if state_timer >= max_dur:
		change_state(State.IDLE)

func _process_attack_heavy(delta: float, is_finisher: bool) -> void:
	_process_lunge_physics(delta, 14.0 if is_finisher else 10.0)
	
	if Input.is_action_just_pressed("roll") and stamina >= roll_stamina_cost:
		var input_dir = _get_input_direction()
		roll_direction = input_dir if input_dir.length_squared() > 0.01 else -model.global_transform.basis.z
		change_state(State.ROLL)
		return
	if Input.is_action_just_pressed("slide") and stamina >= slide_stamina_cost:
		var input_dir = _get_input_direction()
		slide_direction = input_dir if input_dir.length_squared() > 0.01 else -model.global_transform.basis.z
		change_state(State.SLIDE)
		return
		
	var max_dur = 0.95 if is_finisher else 0.85
	if state_timer >= max_dur:
		change_state(State.IDLE)

func _process_lunge_physics(delta: float, lunge_speed: float) -> void:
	if state_timer >= 0.05 and state_timer <= 0.28:
		var forward = -model.global_transform.basis.z
		if current_target and is_instance_valid(current_target):
			var dist = global_position.distance_to(current_target.global_position)
			if dist <= 1.5:
				lunge_speed = 0.0
		velocity.x = forward.x * lunge_speed
		velocity.z = forward.z * lunge_speed
	else:
		velocity.x = move_toward(velocity.x, 0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 18.0 * delta)
		
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _apply_combat_magnetism() -> void:
	current_target = _find_best_combat_target()
	if current_target and is_instance_valid(current_target):
		var dir_to_enemy = (current_target.global_position - global_position)
		dir_to_enemy.y = 0
		if dir_to_enemy.length_squared() > 0.01:
			var target_rot = atan2(-dir_to_enemy.normalized().x, -dir_to_enemy.normalized().z)
			model.rotation.y = target_rot

func _find_best_combat_target() -> Node3D:
	var best_enemy: Node3D = null
	var best_score: float = -9999.0
	
	var ref_dir = _get_input_direction()
	if ref_dir.length_squared() < 0.01:
		ref_dir = -cam_root.global_transform.basis.z
	ref_dir.y = 0
	ref_dir = ref_dir.normalized()
	
	var candidates = get_tree().get_nodes_in_group("enemies")
	for node in candidates:
		if not node is Node3D or (node.has_method("is_dead") and node.is_dead):
			continue
		var enemy = node as Node3D
		var to_enemy = (enemy.global_position - global_position)
		to_enemy.y = 0
		var dist = to_enemy.length()
		
		if dist > magnet_range or dist < 0.1:
			continue
			
		var enemy_dir = to_enemy.normalized()
		var angle_deg = rad_to_deg(ref_dir.angle_to(enemy_dir))
		
		if angle_deg <= magnet_angle_deg:
			var score = (1.0 - (dist / magnet_range)) * 70.0 + (1.0 - (angle_deg / magnet_angle_deg)) * 30.0
			if score > best_score:
				best_score = score
				best_enemy = enemy
				
	return best_enemy

func _process_block(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	
	if not Input.is_action_pressed("block"):
		change_state(State.IDLE)
		return
		
	var cam_forward = -cam_root.global_transform.basis.z
	cam_forward.y = 0
	if cam_forward.length_squared() > 0.01:
		var target_rot = atan2(-cam_forward.x, -cam_forward.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rot, 8.0 * delta)

func _process_reload(delta: float) -> void:
	var move_dir = _get_input_direction()
	var h_vel = Vector2(velocity.x, velocity.z)
	var target_h_vel = Vector2(move_dir.x, move_dir.z) * walk_speed
	h_vel = h_vel.move_toward(target_h_vel, 25.0 * delta)
	velocity.x = h_vel.x
	velocity.z = h_vel.y
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if move_dir.length_squared() > 0.01:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rot_y, rotation_speed * delta)
	
	move_and_slide()
	
	if rifle_weapon and not rifle_weapon.is_reloading:
		change_state(State.IDLE)
		return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_wants_jump = true
		change_state(State.JUMP)
		return

func _process_dance(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	
	var is_moving = _get_input_direction().length_squared() > 0.01
	if is_moving or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("attack_heavy") or Input.is_action_just_pressed("roll") or Input.is_action_just_pressed("slide"):
		change_state(State.IDLE)

func _process_hit_react(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 15.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if state_timer >= 0.3:
		change_state(State.IDLE)

func _is_attack_state(st: State) -> bool:
	return st in [State.ATTACK_LIGHT, State.ATTACK_LIGHT_2, State.ATTACK_LIGHT_3, State.ATTACK_LIGHT_4, State.ATTACK_HEAVY, State.ATTACK_HEAVY_FINISHER]

func heal(amount: float) -> void:
	if current_state == State.DEAD:
		return
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)
	_spawn_damage_number(-amount, false)

func restore_stamina(amount: float) -> void:
	if current_state == State.DEAD:
		return
	stamina = min(max_stamina, stamina + amount)
	stamina_changed.emit(stamina, max_stamina)

func take_damage(amount: float, is_heavy: bool = false, source_pos: Vector3 = Vector3.ZERO) -> void:
	if is_invulnerable or current_state == State.DEAD:
		return
		
	if current_state == State.BLOCK and current_weapon == WeaponType.SWORD:
		var blocked_damage = amount * 0.15
		var stamina_drain = amount * 0.6
		stamina = max(0, stamina - stamina_drain)
		health = max(0, health - blocked_damage)
		stamina_changed.emit(stamina, max_stamina)
		health_changed.emit(health, max_health)
		
		_spawn_hit_sparks(global_position + Vector3.UP * 1.0, false, Color(1.0, 0.8, 0.1))
		_spawn_damage_number(blocked_damage, false)
		
		var push_dir = (global_position - source_pos).normalized()
		push_dir.y = 0
		velocity = push_dir * 3.0
		return
		
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	
	_spawn_hit_sparks(global_position + Vector3.UP * 1.0, is_heavy, Color(1.0, 0.2, 0.2))
	_spawn_damage_number(amount, is_heavy)
	
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HIT_REACT)
		if source_pos != Vector3.ZERO:
			var push_dir = (global_position - source_pos).normalized()
			push_dir.y = 0
			velocity = push_dir * (8.0 if is_heavy else 4.0)

func _on_model_hit_registered(target: Node3D, _damage: float, is_heavy: bool) -> void:
	_spawn_hit_sparks(target.global_position + Vector3.UP * 1.0, is_heavy)

func _on_ammo_changed(current: int, max_val: int) -> void:
	var reserve = 0
	if rifle_weapon:
		reserve = rifle_weapon.current_reserve
	ammo_changed.emit(current, max_val, reserve)

func _on_weapon_fired() -> void:
	# Camera shake or other effects
	pass

func _get_input_direction() -> Vector3:
	var raw_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if raw_input.length_squared() < 0.01:
		return Vector3.ZERO
		
	var forward = -cam_root.global_transform.basis.z
	var right = cam_root.global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	return (forward * -raw_input.y + right * raw_input.x).normalized()

func _handle_stamina_regen(delta: float) -> void:
	if current_state != State.SPRINT and current_state != State.ROLL and current_state != State.SLIDE and current_state != State.BLOCK:
		if stamina < max_stamina:
			stamina = min(max_stamina, stamina + stamina_regen * delta)
			stamina_changed.emit(stamina, max_stamina)

func _spawn_slash_vfx(is_heavy: bool) -> void:
	if not slash_vfx_scene:
		return
	var vfx = slash_vfx_scene.instantiate() as Node3D
	get_parent().add_child(vfx)
	vfx.global_position = global_position + Vector3.UP * 1.0 - model.global_transform.basis.z * 0.8
	vfx.global_rotation = model.global_rotation
	if vfx.has_method("setup"):
		vfx.setup(is_heavy)

func _spawn_hit_sparks(pos: Vector3, is_heavy: bool, hit_color: Color = Color(1.0, 0.8, 0.2)) -> void:
	if not hit_vfx_scene:
		return
	var vfx = hit_vfx_scene.instantiate() as Node3D
	get_parent().add_child(vfx)
	vfx.global_position = pos
	if vfx.has_method("setup"):
		vfx.setup(is_heavy, hit_color)

func _spawn_damage_number(amount: float, is_heavy: bool) -> void:
	if not damage_num_scene:
		return
	var dmg = damage_num_scene.instantiate() as Node3D
	get_parent().add_child(dmg)
	dmg.global_position = global_position + Vector3.UP * 1.8 + Vector3(randf_range(-0.3, 0.3), randf_range(0, 0.3), randf_range(-0.3, 0.3))
	if dmg.has_method("setup"):
		dmg.setup(amount, is_heavy)

func _setup_fallback_inputs() -> void:
	var actions = {
		"move_forward": [KEY_W],
		"move_backward": [KEY_S],
		"move_left": [KEY_A],
		"move_right": [KEY_D],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"roll": [KEY_Q, KEY_ALT],
		"slide": [KEY_C],
		"block": [KEY_F],
		"dance": [KEY_B],
		"reload": [KEY_R]
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for keycode in actions[action_name]:
				var ev = InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action_name, ev)
				
	if not InputMap.has_action("attack_light"):
		InputMap.add_action("attack_light")
		var ev_lmb = InputEventMouseButton.new()
		ev_lmb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack_light", ev_lmb)
		
	if not InputMap.has_action("attack_heavy"):
		InputMap.add_action("attack_heavy")
		var ev_rmb = InputEventMouseButton.new()
		ev_rmb.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("attack_heavy", ev_rmb)
