@tool
extends PlayerModel
class_name SkeletonPlayerModel

var fbx_model: Node3D = null
var skeleton: Skeleton3D = null
var fbx_anim_player: AnimationPlayer = null
var _loaded_anims: Dictionary = {}
var _hitbox_shape: BoxShape3D = null

var PALADIN_PATH = "res://рыцарь/Paladin J Nordstrom.fbx"

# Map logical animation names to FBX files and settings
# [path, is_looping, default_speed]
var ANIM_CONFIG = {
	"walk": ["res://assets/animations/Walking.fbx", true, 1.1],
	"sprint": ["res://assets/animations/Run.fbx", true, 1.2],
	"roll": ["res://assets/animations/Falling To Roll.fbx", false, 1.4],
	"dance": ["res://assets/animations/Hip Hop Dancing.fbx", true, 1.0],
	"attack_light": ["res://assets/animations/Side Kick.fbx", false, 1.8],
	"attack_light_2": ["res://assets/animations/Roundhouse Kick.fbx", false, 1.8],
	"attack_light_3": ["res://assets/animations/Side Kick.fbx", false, 2.2],
	"attack_light_4": ["res://assets/animations/Roundhouse Kick.fbx", false, 2.2],
	"attack_heavy": ["res://assets/animations/Roundhouse Kick.fbx", false, 1.3],
	"attack_heavy_finisher": ["res://assets/animations/Casting Spell.fbx", false, 1.6],
	"block": ["res://assets/animations/Dodging.fbx", true, 0.8],
	"hit": ["res://assets/animations/Dodging.fbx", false, 1.3],
	"slide": ["res://assets/animations/Running Slide.fbx", false, 1.2],
	"aim_idle": ["res://assets/animations/Pistol Strafe.fbx", true, 0.8],
	"rifle_idle": ["res://assets/animations/Pistol Strafe.fbx", true, 0.8],
}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_load_fbx_model()
	_setup_animation_player()
	_load_all_animations()
	_create_natural_idle()
	_create_jump_and_action_anims()
	_setup_hitbox()
	print("[Skeleton] Successfully configured all animations: ", fbx_anim_player.get_animation_library("").get_animation_list())

func _load_fbx_model() -> void:
	var scene = load(PALADIN_PATH) as PackedScene
	if not scene:
		push_error("Failed to load Paladin FBX")
		return
	fbx_model = scene.instantiate()
	add_child(fbx_model)
	fbx_model.rotation_degrees.y = 180.0
	skeleton = _find_node_by_type(fbx_model, "Skeleton3D") as Skeleton3D
	var existing_ap = _find_node_by_type(fbx_model, "AnimationPlayer") as AnimationPlayer
	if existing_ap:
		fbx_anim_player = existing_ap
	else:
		fbx_anim_player = AnimationPlayer.new()
		fbx_anim_player.name = "FBXAnimPlayer"
		fbx_model.add_child(fbx_anim_player)
	print("[Skeleton] FBX loaded. Skeleton: ", skeleton != null, " AnimPlayer: ", fbx_anim_player != null)

func _find_node_by_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_type(child, type_name)
		if result:
			return result
	return null

func _setup_animation_player() -> void:
	if not fbx_anim_player:
		return
	if not fbx_anim_player.has_animation_library(""):
		var new_lib = AnimationLibrary.new()
		fbx_anim_player.add_animation_library("", new_lib)

func _load_all_animations() -> void:
	if not fbx_anim_player:
		return
	var anim_lib = fbx_anim_player.get_animation_library("")
	for anim_key in ANIM_CONFIG:
		var cfg = ANIM_CONFIG[anim_key]
		var fbx_path: String = cfg[0]
		var is_loop: bool = cfg[1]
		var scene = load(fbx_path) as PackedScene
		if not scene:
			continue
		var instance = scene.instantiate()
		var source_ap = _find_node_by_type(instance, "AnimationPlayer") as AnimationPlayer
		if source_ap:
			for source_lib_name in source_ap.get_animation_library_list():
				var source_lib = source_ap.get_animation_library(source_lib_name)
				for anim_name in source_lib.get_animation_list():
					var src_anim = source_lib.get_animation(anim_name)
					var clean_anim = _strip_root_motion_and_clone(src_anim)
					clean_anim.loop_mode = Animation.LOOP_LINEAR if is_loop else Animation.LOOP_NONE
					anim_lib.add_animation(anim_key, clean_anim)
					_loaded_anims[anim_key] = anim_key
					break
		instance.free()

# Strips X and Z root motion displacement from mixamorig_Hips position track, making animations perfectly IN-PLACE
func _strip_root_motion_and_clone(src: Animation) -> Animation:
	var dst = src.duplicate(true) as Animation
	for t in range(dst.get_track_count()):
		var path_str = String(dst.track_get_path(t))
		if "Hips" in path_str and dst.track_get_type(t) == Animation.TYPE_POSITION_3D:
			var key_count = dst.track_get_key_count(t)
			for k in range(key_count):
				var val = dst.track_get_key_value(t, k)
				if val is Vector3:
					# Keep Y (vertical bounce/bob), zero out X and Z (prevents teleporting/sliding)
					dst.track_set_key_value(t, k, Vector3(0.0, val.y, 0.0))
	return dst

# Creates a natural breathing standing IDLE pose from Walking frame 0 (natural stance with arms down, not T-pose)
func _create_natural_idle() -> void:
	var anim_lib = fbx_anim_player.get_animation_library("")
	var walk_scene = load("res://assets/animations/Walking.fbx") as PackedScene
	if not walk_scene:
		return
	var inst = walk_scene.instantiate()
	var src_ap = _find_node_by_type(inst, "AnimationPlayer") as AnimationPlayer
	if not src_ap:
		inst.free()
		return
	var src_lib = src_ap.get_animation_library("")
	var src_anim: Animation = null
	for an in src_lib.get_animation_list():
		src_anim = src_lib.get_animation(an)
		break
	if not src_anim:
		inst.free()
		return
	
	# Build 2.0s looping idle by sampling the natural rest pose
	var idle = Animation.new()
	idle.length = 2.0
	idle.loop_mode = Animation.LOOP_LINEAR
	
	for t in range(src_anim.get_track_count()):
		var track_path = src_anim.track_get_path(t)
		var track_type = src_anim.track_get_type(t)
		var path_str = String(track_path)
		
		if track_type == Animation.TYPE_ROTATION_3D:
			var q0 = src_anim.rotation_track_interpolate(t, 0.0)
			var ntrack = idle.add_track(Animation.TYPE_ROTATION_3D)
			idle.track_set_path(ntrack, track_path)
			if "Spine" in path_str:
				# Subtle breathing rotation
				var e0 = q0.get_euler()
				var q1 = Quaternion.from_euler(Vector3(e0.x + 0.02, e0.y, e0.z))
				idle.rotation_track_insert_key(ntrack, 0.0, q0)
				idle.rotation_track_insert_key(ntrack, 1.0, q1)
				idle.rotation_track_insert_key(ntrack, 2.0, q0)
			else:
				idle.rotation_track_insert_key(ntrack, 0.0, q0)
				idle.rotation_track_insert_key(ntrack, 2.0, q0)
		elif track_type == Animation.TYPE_POSITION_3D:
			var p0 = src_anim.position_track_interpolate(t, 0.0)
			var ntrack = idle.add_track(Animation.TYPE_POSITION_3D)
			idle.track_set_path(ntrack, track_path)
			if "Hips" in path_str:
				idle.position_track_insert_key(ntrack, 0.0, Vector3(0.0, p0.y, 0.0))
				idle.position_track_insert_key(ntrack, 1.0, Vector3(0.0, p0.y - 0.015, 0.0))
				idle.position_track_insert_key(ntrack, 2.0, Vector3(0.0, p0.y, 0.0))
			else:
				idle.position_track_insert_key(ntrack, 0.0, p0)
				idle.position_track_insert_key(ntrack, 2.0, p0)
	
	anim_lib.add_animation("idle", idle)
	inst.free()

func _create_jump_and_action_anims() -> void:
	var anim_lib = fbx_anim_player.get_animation_library("")
	if not anim_lib.has_animation("jump_start") and anim_lib.has_animation("idle"):
		var idle_anim = anim_lib.get_animation("idle")
		var jump_start = _create_jump_phase(idle_anim, 0.3, false, 0.05)
		anim_lib.add_animation("jump_start", jump_start)
		var jump_loop = _create_jump_phase(idle_anim, 0.3, true, 0.05)
		anim_lib.add_animation("jump_loop", jump_loop)
		var jump_land = _create_jump_phase(idle_anim, 0.3, false, -0.05)
		anim_lib.add_animation("jump_land", jump_land)
	if not anim_lib.has_animation("reload_rifle") and anim_lib.has_animation("aim_idle"):
		var rel = anim_lib.get_animation("aim_idle").duplicate(true) as Animation
		rel.loop_mode = Animation.LOOP_NONE
		anim_lib.add_animation("reload_rifle", rel)

func _create_jump_phase(src_anim: Animation, duration: float, loop: bool, y_offset: float) -> Animation:
	var anim = Animation.new()
	anim.length = duration
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for t in range(src_anim.get_track_count()):
		var track_path = src_anim.track_get_path(t)
		var track_type = src_anim.track_get_type(t)
		if track_type == Animation.TYPE_ROTATION_3D:
			var q = src_anim.rotation_track_interpolate(t, 0.0)
			var ntrack = anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(ntrack, track_path)
			anim.rotation_track_insert_key(ntrack, 0.0, q)
			anim.rotation_track_insert_key(ntrack, duration, q)
		elif track_type == Animation.TYPE_POSITION_3D:
			var p = src_anim.position_track_interpolate(t, 0.0)
			var ntrack = anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(ntrack, track_path)
			if "Hips" in String(track_path):
				anim.position_track_insert_key(ntrack, 0.0, Vector3(0.0, p.y, 0.0))
				anim.position_track_insert_key(ntrack, duration, Vector3(0.0, p.y + y_offset, 0.0))
			else:
				anim.position_track_insert_key(ntrack, 0.0, p)
				anim.position_track_insert_key(ntrack, duration, p)
	return anim

func _copy_tracks(src: Animation, dst: Animation, from_time: float, to_time: float) -> void:
	for t in range(src.get_track_count()):
		var track_path = src.track_get_path(t)
		var track_type = src.track_get_type(t)
		if track_type == Animation.TYPE_ROTATION_3D:
			var ntrack = dst.add_track(Animation.TYPE_ROTATION_3D)
			dst.track_set_path(ntrack, track_path)
			var steps = 8
			for i in range(steps + 1):
				var time = from_time + (to_time - from_time) * float(i) / float(steps)
				var q = src.rotation_track_interpolate(t, time)
				dst.rotation_track_insert_key(ntrack, (to_time - from_time) * float(i) / float(steps), q)
		elif track_type == Animation.TYPE_POSITION_3D:
			var ntrack = dst.add_track(Animation.TYPE_POSITION_3D)
			dst.track_set_path(ntrack, track_path)
			var steps = 8
			for i in range(steps + 1):
				var time = from_time + (to_time - from_time) * float(i) / float(steps)
				var p = src.position_track_interpolate(t, time)
				var path_str = String(track_path)
				if "Hips" in path_str:
					dst.position_track_insert_key(ntrack, (to_time - from_time) * float(i) / float(steps), Vector3(0.0, p.y, 0.0))
				else:
					dst.position_track_insert_key(ntrack, (to_time - from_time) * float(i) / float(steps), p)

func play_anim(anim_name: String, blend: float = 0.15, speed: float = 1.0) -> void:
	if not fbx_anim_player:
		return
	var anim_lib = fbx_anim_player.get_animation_library("")
	if anim_lib.has_animation(anim_name):
		var custom_speed = speed
		if ANIM_CONFIG.has(anim_name):
			custom_speed *= ANIM_CONFIG[anim_name][2]
		fbx_anim_player.play(anim_name, blend, custom_speed)
		return
	if _loaded_anims.has(anim_name):
		var real_name = _loaded_anims[anim_name]
		if anim_lib.has_animation(real_name):
			fbx_anim_player.play(real_name, blend, speed)

func set_weapon_visible(_weapon_type: String) -> void:
	pass

func _setup_hitbox() -> void:
	sword_hitbox = Area3D.new()
	sword_hitbox.name = "SwordHitbox"
	sword_hitbox.collision_layer = 0
	sword_hitbox.collision_mask = 2
	sword_hitbox.monitoring = false
	sword_hitbox.monitorable = false
	_hitbox_shape = BoxShape3D.new()
	_hitbox_shape.size = Vector3(0.3, 0.3, 1.2)
	var col = CollisionShape3D.new()
	col.shape = _hitbox_shape
	sword_hitbox.add_child(col)
	sword_hitbox.position = Vector3(-0.4, 1.0, -0.8)
	add_child(sword_hitbox)
	sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)

func _on_sword_hitbox_body_entered(body: Node3D) -> void:
	if body == get_parent() or body == self:
		return
	if body in hit_entities:
		return
	hit_entities.append(body)
	hit_registered.emit(body, current_damage, is_heavy_attack)
	if body.has_method("take_damage"):
		body.take_damage(current_damage, is_heavy_attack, global_position)

func start_attack_hitbox(damage: float, heavy: bool = false) -> void:
	current_damage = damage
	is_heavy_attack = heavy
	hit_entities.clear()
	if sword_hitbox:
		sword_hitbox.monitoring = true

func stop_attack_hitbox() -> void:
	if sword_hitbox:
		sword_hitbox.monitoring = false
	hit_entities.clear()
