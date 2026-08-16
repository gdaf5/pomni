@tool
extends Node
class_name AnimationLibraryBuilder

# Helper class to programmatically build expressive, fluid 3D humanoid animations
# for Godot 4.x AnimationPlayer.

static func build_all_animations(anim_player: AnimationPlayer) -> void:
	var library: AnimationLibrary
	if anim_player.has_animation_library(""):
		library = anim_player.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		anim_player.add_animation_library("", library)
	
	library.add_animation("idle", create_idle_animation())
	library.add_animation("walk", create_walk_animation())
	library.add_animation("sprint", create_sprint_animation())
	library.add_animation("jump_start", create_jump_start_animation())
	library.add_animation("jump_loop", create_jump_loop_animation())
	library.add_animation("jump_land", create_jump_land_animation())
	library.add_animation("roll", create_roll_animation())
	library.add_animation("attack_light", create_attack_light_animation())
	library.add_animation("attack_light_2", create_attack_light_2_animation())
	library.add_animation("attack_light_3", create_attack_light_3_animation())
	library.add_animation("attack_light_4", create_attack_light_4_animation())
	library.add_animation("attack_heavy", create_attack_heavy_animation())
	library.add_animation("attack_heavy_finisher", create_attack_heavy_finisher_animation())
	library.add_animation("block", create_block_animation())
	library.add_animation("dance", create_dance_animation())
	library.add_animation("hit", create_hit_animation())
	library.add_animation("rifle_idle", create_rifle_idle_animation())
	library.add_animation("aim_idle", create_aim_idle_animation())
	library.add_animation("rifle_shoot", create_rifle_shoot_animation())
	library.add_animation("reload_rifle", create_reload_rifle_animation())

static func _add_track_keys(anim: Animation, track_path: String, times: Array[float], values: Array) -> void:
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, track_path)
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
	for i in range(times.size()):
		anim.track_insert_key(track_idx, times[i], values[i])

# --- IDLE ANIMATION ---
static func create_idle_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 2.4
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 1.2, 2.4], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.98, 0), Vector3(0, 0.95, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(0, 0.1, 0), Vector3(-0.03, 0.08, 0), Vector3(0, 0.1, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest/Head:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(0, -0.08, 0), Vector3(0.04, -0.05, 0), Vector3(0, -0.08, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(0.2, 0.1, -0.3), Vector3(0.15, 0.12, -0.25), Vector3(0.2, 0.1, -0.3)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(-0.5, 0.2, 0), Vector3(-0.45, 0.2, 0), Vector3(-0.5, 0.2, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(-0.25, -0.2, 0.35), Vector3(-0.28, -0.22, 0.32), Vector3(-0.25, -0.2, 0.35)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(-0.7, -0.1, 0.2), Vector3(-0.75, -0.1, 0.2), Vector3(-0.7, -0.1, 0.2)])
	
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(0.05, 0, -0.05), Vector3(0.02, 0, -0.05), Vector3(0.05, 0, -0.05)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(-0.1, 0, 0), Vector3(-0.04, 0, 0), Vector3(-0.1, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(0.05, 0, 0.05), Vector3(0.02, 0, 0.05), Vector3(0.05, 0, 0.05)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 1.2, 2.4], 
		[Vector3(-0.1, 0, 0), Vector3(-0.04, 0, 0), Vector3(-0.1, 0, 0)])
		
	return anim

# --- WALK ANIMATION ---
static func create_walk_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(0, 0.95, 0), Vector3(0.03, 0.98, 0), Vector3(0, 0.95, 0), Vector3(-0.03, 0.98, 0), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(0, -0.1, 0), Vector3(0, 0, -0.03), Vector3(0, 0.1, 0), Vector3(0, 0, 0.03), Vector3(0, -0.1, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(0.05, 0.15, 0), Vector3(0.05, -0.15, 0), Vector3(0.05, 0.15, 0)])
	
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(-0.6, 0, 0), Vector3(0.1, 0, 0), Vector3(0.55, 0, 0), Vector3(0.1, 0, 0), Vector3(-0.6, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(0.1, 0, 0), Vector3(-0.8, 0, 0), Vector3(-0.1, 0, 0), Vector3(-0.2, 0, 0), Vector3(0.1, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin/LeftFoot:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(0.3, 0, 0), Vector3(-0.2, 0, 0), Vector3(-0.3, 0, 0), Vector3(0.1, 0, 0), Vector3(0.3, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(0.55, 0, 0), Vector3(0.1, 0, 0), Vector3(-0.6, 0, 0), Vector3(0.1, 0, 0), Vector3(0.55, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(-0.1, 0, 0), Vector3(-0.2, 0, 0), Vector3(0.1, 0, 0), Vector3(-0.8, 0, 0), Vector3(-0.1, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin/RightFoot:rotation", 
		[0.0, 0.25, 0.5, 0.75, 1.0], 
		[Vector3(-0.3, 0, 0), Vector3(0.1, 0, 0), Vector3(0.3, 0, 0), Vector3(-0.2, 0, 0), Vector3(-0.3, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(0.4, 0, -0.15), Vector3(-0.4, 0, -0.15), Vector3(0.4, 0, -0.15)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.6, 0, 0), Vector3(-0.2, 0, 0), Vector3(-0.6, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.35, -0.1, 0.2), Vector3(0.2, -0.1, 0.2), Vector3(-0.35, -0.1, 0.2)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.7, 0, 0.1), Vector3(-0.5, 0, 0.1), Vector3(-0.7, 0, 0.1)])
		
	return anim

# --- SPRINT ANIMATION ---
static func create_sprint_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.65
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.16, 0.32, 0.48, 0.65], 
		[Vector3(0, 0.88, 0.05), Vector3(0.04, 0.98, 0.05), Vector3(0, 0.88, 0.05), Vector3(-0.04, 0.98, 0.05), Vector3(0, 0.88, 0.05)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.16, 0.32, 0.48, 0.65], 
		[Vector3(0.25, -0.2, 0), Vector3(0.25, 0, -0.05), Vector3(0.25, 0.2, 0), Vector3(0.25, 0, 0.05), Vector3(0.25, -0.2, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.32, 0.65], 
		[Vector3(0.2, 0.25, 0), Vector3(0.2, -0.25, 0), Vector3(0.2, 0.25, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest/Head:rotation", 
		[0.0, 0.32, 0.65], 
		[Vector3(-0.35, 0, 0), Vector3(-0.35, 0, 0), Vector3(-0.35, 0, 0)])
	
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.16, 0.32, 0.48, 0.65], 
		[Vector3(-1.0, 0, 0), Vector3(0.2, 0, 0), Vector3(0.9, 0, 0), Vector3(0.1, 0, 0), Vector3(-1.0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.16, 0.32, 0.48, 0.65], 
		[Vector3(0.2, 0, 0), Vector3(-1.3, 0, 0), Vector3(-0.2, 0, 0), Vector3(-0.5, 0, 0), Vector3(0.2, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.16, 0.32, 0.48, 0.65], 
		[Vector3(0.9, 0, 0), Vector3(0.1, 0, 0), Vector3(-1.0, 0, 0), Vector3(0.2, 0, 0), Vector3(0.9, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.16, 0.32, 0.48, 0.65], 
		[Vector3(-0.2, 0, 0), Vector3(-0.5, 0, 0), Vector3(0.2, 0, 0), Vector3(-1.3, 0, 0), Vector3(-0.2, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.32, 0.65], 
		[Vector3(0.9, 0, -0.2), Vector3(-0.8, 0, -0.2), Vector3(0.9, 0, -0.2)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 0.32, 0.65], 
		[Vector3(-1.1, 0, 0), Vector3(-0.3, 0, 0), Vector3(-1.1, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.32, 0.65], 
		[Vector3(-0.6, -0.2, 0.3), Vector3(0.3, -0.1, 0.3), Vector3(-0.6, -0.2, 0.3)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.32, 0.65], 
		[Vector3(-0.8, 0, 0), Vector3(-0.6, 0, 0), Vector3(-0.8, 0, 0)])
		
	return anim

# --- JUMP START ANIMATION ---
static func create_jump_start_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.2
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.1, 0.2], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.75, 0), Vector3(0, 1.05, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.1, 0.2], 
		[Vector3(0, 0, 0), Vector3(0.3, 0, 0), Vector3(-0.15, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.1, 0.2], 
		[Vector3(0, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.3, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.1, 0.2], 
		[Vector3(0, 0, 0), Vector3(-0.9, 0, 0), Vector3(-0.2, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.1, 0.2], 
		[Vector3(0, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.3, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.1, 0.2], 
		[Vector3(0, 0, 0), Vector3(-0.9, 0, 0), Vector3(-0.2, 0, 0)])
		
	return anim

# --- JUMP LOOP ANIMATION ---
static func create_jump_loop_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.8
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.4, 0.8], 
		[Vector3(0, 1.0, 0), Vector3(0, 1.02, 0), Vector3(0, 1.0, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-0.1, 0, 0), Vector3(-0.05, 0, 0), Vector3(-0.1, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0.4, 0, -0.1), Vector3(0.35, 0, -0.1), Vector3(0.4, 0, -0.1)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-0.7, 0, 0), Vector3(-0.65, 0, 0), Vector3(-0.7, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-0.1, 0, 0.1), Vector3(-0.15, 0, 0.1), Vector3(-0.1, 0, 0.1)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-0.4, 0, 0), Vector3(-0.45, 0, 0), Vector3(-0.4, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0.5, 0, -0.5), Vector3(0.45, 0, -0.45), Vector3(0.5, 0, -0.5)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-0.4, 0, 0.5), Vector3(-0.35, 0, 0.45), Vector3(-0.4, 0, 0.5)])
		
	return anim

# --- JUMP LAND ANIMATION ---
static func create_jump_land_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.35
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.12, 0.35], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.65, 0), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.12, 0.35], 
		[Vector3(0, 0, 0), Vector3(0.4, 0, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.12, 0.35], 
		[Vector3(0, 0, 0), Vector3(0.7, 0, 0), Vector3(0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.12, 0.35], 
		[Vector3(0, 0, 0), Vector3(-1.1, 0, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.12, 0.35], 
		[Vector3(0, 0, 0), Vector3(0.7, 0, 0), Vector3(0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.12, 0.35], 
		[Vector3(0, 0, 0), Vector3(-1.1, 0, 0), Vector3(0, 0, 0)])
		
	return anim

# --- ROLL / DODGE ANIMATION ---
static func create_roll_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.65
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.15, 0.32, 0.5, 0.65], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.5, 0.2), Vector3(0, 0.35, 0), Vector3(0, 0.55, -0.1), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.15, 0.32, 0.5, 0.65], 
		[Vector3(0, 0, 0), Vector3(1.6, 0, 0), Vector3(3.14159, 0, 0), Vector3(4.71, 0, 0), Vector3(6.28318, 0, 0)])
	
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.15, 0.45, 0.65], 
		[Vector3(0, 0, 0), Vector3(1.3, 0, 0), Vector3(1.1, 0, 0), Vector3(0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.15, 0.45, 0.65], 
		[Vector3(0, 0, 0), Vector3(-1.8, 0, 0), Vector3(-1.5, 0, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.15, 0.45, 0.65], 
		[Vector3(0, 0, 0), Vector3(1.3, 0, 0), Vector3(1.1, 0, 0), Vector3(0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.15, 0.45, 0.65], 
		[Vector3(0, 0, 0), Vector3(-1.8, 0, 0), Vector3(-1.5, 0, 0), Vector3(0, 0, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.3, 0.65], 
		[Vector3(0, 0, 0), Vector3(1.2, 0.5, -0.3), Vector3(0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.3, 0.65], 
		[Vector3(0, 0, 0), Vector3(1.2, -0.5, 0.3), Vector3(0, 0, 0)])
		
	return anim

# --- LIGHT ATTACK 1 ---
static func create_attack_light_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.45
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.1, 0.2, 0.45], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.92, -0.08), Vector3(0, 0.94, 0.12), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.1, 0.22, 0.45], 
		[Vector3(0, 0, 0), Vector3(0, -0.45, 0), Vector3(0, 0.55, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.1, 0.22, 0.45], 
		[Vector3(0, 0, 0), Vector3(0.1, -0.65, -0.1), Vector3(-0.1, 0.85, 0.1), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.1, 0.2, 0.3, 0.45], 
		[
			Vector3(-0.25, -0.2, 0.35), 
			Vector3(0.6, -1.0, 0.9),
			Vector3(-0.5, 0.95, -0.4),
			Vector3(-0.7, 1.2, -0.3),
			Vector3(-0.25, -0.2, 0.35)
		])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.1, 0.2, 0.45], 
		[Vector3(-0.7, 0, 0.1), Vector3(-1.2, 0, 0.2), Vector3(-0.2, 0, 0), Vector3(-0.7, 0, 0.1)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.1, 0.22, 0.45], 
		[Vector3(0.2, 0.1, -0.3), Vector3(-0.3, 0.2, -0.4), Vector3(0.6, -0.4, -0.5), Vector3(0.2, 0.1, -0.3)])
		
	return anim

# --- LIGHT ATTACK 2 ---
static func create_attack_light_2_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.5
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.12, 0.25, 0.5], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.88, 0), Vector3(0, 1.02, 0.15), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.12, 0.25, 0.5], 
		[Vector3(0, 0.5, 0), Vector3(0, 0.75, 0), Vector3(0, -0.55, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.12, 0.25, 0.5], 
		[Vector3(0, 0.5, 0), Vector3(-0.2, 0.9, 0.25), Vector3(0.25, -0.7, -0.25), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.12, 0.25, 0.38, 0.5], 
		[
			Vector3(-0.4, 0.9, -0.3),
			Vector3(-0.9, 0.9, 0.3),
			Vector3(0.85, -0.85, 0.95),
			Vector3(0.95, -0.75, 0.75),
			Vector3(-0.25, -0.2, 0.35)
		])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.12, 0.25, 0.5], 
		[Vector3(-0.2, 0, 0), Vector3(-0.9, 0, 0), Vector3(-0.3, 0, 0), Vector3(-0.7, 0, 0.1)])
		
	return anim

# --- LIGHT ATTACK 3 ---
static func create_attack_light_3_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.55
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.15, 0.3, 0.55], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.92, 0.1), Vector3(0, 0.98, 0.25), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.18, 0.36, 0.55], 
		[Vector3(0, 0, 0), Vector3(0, 3.14159, 0), Vector3(0, 6.28318, 0), Vector3(0, 6.28318, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.18, 0.36, 0.55], 
		[Vector3(0, 0, 0), Vector3(0.2, 0.5, 0.1), Vector3(-0.1, -0.3, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.18, 0.36, 0.55], 
		[Vector3(-0.25, -0.2, 0.35), Vector3(0.2, 1.4, 1.2), Vector3(-0.3, 1.2, 0.8), Vector3(-0.25, -0.2, 0.35)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.18, 0.36, 0.55], 
		[Vector3(-0.7, 0, 0.1), Vector3(-0.2, 0, 0), Vector3(-0.3, 0, 0), Vector3(-0.7, 0, 0.1)])
		
	return anim

# --- LIGHT ATTACK 4 ---
static func create_attack_light_4_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.12, 0.22, 0.4, 0.6], 
		[
			Vector3(0, 0.95, 0), 
			Vector3(0, 0.78, -0.1),
			Vector3(0, 0.82, 0.45),
			Vector3(0, 0.88, 0.3),
			Vector3(0, 0.95, 0)
		])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.12, 0.22, 0.6], 
		[Vector3(0, 0, 0), Vector3(0.1, -0.2, 0), Vector3(0.2, 0.1, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.12, 0.22, 0.6], 
		[Vector3(0, 0, 0), Vector3(0.2, -0.3, 0), Vector3(0.35, 0.2, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.12, 0.22, 0.4, 0.6], 
		[
			Vector3(-0.25, -0.2, 0.35),
			Vector3(0.8, -0.6, 0.6),
			Vector3(1.57, 0.0, 0.0),
			Vector3(1.3, 0.0, 0.0),
			Vector3(-0.25, -0.2, 0.35)
		])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.12, 0.22, 0.6], 
		[Vector3(-0.7, 0, 0.1), Vector3(-1.4, 0, 0), Vector3(0.0, 0, 0), Vector3(-0.7, 0, 0.1)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.12, 0.22, 0.6], 
		[Vector3(0.2, 0.1, -0.3), Vector3(-0.5, 0, -0.3), Vector3(-1.4, 0, -0.3), Vector3(0.2, 0.1, -0.3)])
		
	return anim

# --- HEAVY ATTACK ---
static func create_attack_heavy_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.85
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.2, 0.4, 0.5, 0.65, 0.85], 
		[
			Vector3(0, 0.95, 0), 
			Vector3(0, 0.8, -0.08), 
			Vector3(0, 1.18, 0.1), 
			Vector3(0, 0.65, 0.25), 
			Vector3(0, 0.75, 0.1),
			Vector3(0, 0.95, 0)
		])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.2, 0.4, 0.5, 0.85], 
		[Vector3(0, 0, 0), Vector3(0.2, -0.2, 0), Vector3(-0.3, 0, 0), Vector3(0.4, 0, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.2, 0.4, 0.5, 0.85], 
		[Vector3(0, 0, 0), Vector3(0.3, -0.3, 0), Vector3(-0.5, 0, 0), Vector3(0.6, 0, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.2, 0.4, 0.5, 0.85], 
		[
			Vector3(-0.25, -0.2, 0.35),
			Vector3(1.2, -0.3, 0.4),
			Vector3(1.8, 0.1, 0.2),
			Vector3(-1.1, 0, 0),
			Vector3(-0.25, -0.2, 0.35)
		])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.2, 0.4, 0.5, 0.85], 
		[Vector3(-0.7, 0, 0.1), Vector3(-1.2, 0, 0), Vector3(-0.4, 0, 0), Vector3(-0.1, 0, 0), Vector3(-0.7, 0, 0.1)])
		
	return anim

# --- HEAVY COMBO FINISHER ---
static func create_attack_heavy_finisher_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.95
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.2, 0.45, 0.6, 0.75, 0.95], 
		[
			Vector3(0, 0.95, 0), 
			Vector3(0, 0.75, -0.1), 
			Vector3(0, 1.35, 0.2), 
			Vector3(0, 0.55, 0.35), 
			Vector3(0, 0.7, 0.2),
			Vector3(0, 0.95, 0)
		])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.2, 0.45, 0.6, 0.95], 
		[Vector3(0, 0, 0), Vector3(-0.2, 1.5, 0), Vector3(-0.4, 3.14159, 0), Vector3(0.5, 6.28318, 0), Vector3(0, 6.28318, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.2, 0.45, 0.6, 0.95], 
		[Vector3(0, 0, 0), Vector3(0.4, 0.5, 0), Vector3(-0.6, 0, 0), Vector3(0.7, 0, 0), Vector3(0, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.2, 0.45, 0.6, 0.95], 
		[
			Vector3(-0.25, -0.2, 0.35),
			Vector3(1.3, -0.4, 0.5),
			Vector3(2.0, 0.2, 0.2),
			Vector3(-1.3, 0, 0),
			Vector3(-0.25, -0.2, 0.35)
		])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.2, 0.45, 0.6, 0.95], 
		[Vector3(-0.7, 0, 0.1), Vector3(-1.3, 0, 0), Vector3(-0.3, 0, 0), Vector3(-0.1, 0, 0), Vector3(-0.7, 0, 0.1)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.2, 0.45, 0.6, 0.95], 
		[Vector3(0.2, 0.1, -0.3), Vector3(1.2, 0.3, -0.3), Vector3(1.9, -0.1, -0.2), Vector3(-1.0, 0, -0.2), Vector3(0.2, 0.1, -0.3)])
		
	return anim

# --- BLOCK ANIMATION ---
static func create_block_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.8
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.4, 0.8], 
		[Vector3(0, 0.88, 0), Vector3(0, 0.89, 0), Vector3(0, 0.88, 0)])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0, 0.25, 0), Vector3(0, 0.23, 0), Vector3(0, 0.25, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0.1, -0.3, 0), Vector3(0.08, -0.28, 0), Vector3(0.1, -0.3, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0.6, -0.7, 0.8), Vector3(0.58, -0.72, 0.78), Vector3(0.6, -0.7, 0.8)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-1.6, 0.4, -0.5), Vector3(-1.58, 0.4, -0.5), Vector3(-1.6, 0.4, -0.5)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0.7, 0.5, -0.6), Vector3(0.68, 0.52, -0.58), Vector3(0.7, 0.5, -0.6)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-1.4, -0.3, 0.4), Vector3(-1.38, -0.3, 0.4), Vector3(-1.4, -0.3, 0.4)])
		
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(0.3, 0, -0.2), Vector3(0.28, 0, -0.2), Vector3(0.3, 0, -0.2)])
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.4, 0.8], 
		[Vector3(-0.2, 0, 0.2), Vector3(-0.18, 0, 0.2), Vector3(-0.2, 0, 0.2)])
		
	return anim

# --- DANCE ANIMATION ---
static func create_dance_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], 
		[
			Vector3(0, 0.95, 0), Vector3(0.12, 0.88, 0), Vector3(0, 1.02, 0), Vector3(-0.12, 0.88, 0),
			Vector3(0, 0.95, 0), Vector3(0.1, 0.88, 0), Vector3(0, 1.02, 0), Vector3(-0.1, 0.88, 0), Vector3(0, 0.95, 0)
		])
	_add_track_keys(anim, "Rig/Hips:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(0, 0, -0.15), Vector3(0, 0.4, 0.15), Vector3(0, 0, -0.15), Vector3(0, -0.4, 0.15), Vector3(0, 0, -0.15)])
		
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(0.15, -0.3, 0.2), Vector3(-0.1, 0.3, -0.2), Vector3(0.15, -0.3, 0.2), Vector3(-0.1, 0.3, -0.2), Vector3(0.15, -0.3, 0.2)])
	_add_track_keys(anim, "Rig/Hips/Chest/Head:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-0.2, 0.2, -0.1), Vector3(0.2, -0.2, 0.1), Vector3(-0.2, 0.2, -0.1), Vector3(0.2, -0.2, 0.1), Vector3(-0.2, 0.2, -0.1)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(1.2, 0.3, -1.0), Vector3(-0.4, 0.2, -0.5), Vector3(1.2, 0.3, -1.0), Vector3(-0.4, 0.2, -0.5), Vector3(1.2, 0.3, -1.0)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-1.2, 0, 0), Vector3(-0.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(-0.2, 0, 0), Vector3(-1.2, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-0.4, -0.2, 0.5), Vector3(1.3, -0.3, 1.1), Vector3(-0.4, -0.2, 0.5), Vector3(1.3, -0.3, 1.1), Vector3(-0.4, -0.2, 0.5)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-0.3, 0, 0), Vector3(-1.4, 0, 0), Vector3(-0.3, 0, 0), Vector3(-1.4, 0, 0), Vector3(-0.3, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(0.5, 0, -0.3), Vector3(-0.2, 0, 0), Vector3(0.5, 0, -0.3), Vector3(-0.2, 0, 0), Vector3(0.5, 0, -0.3)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-0.8, 0, 0), Vector3(-0.1, 0, 0), Vector3(-0.8, 0, 0), Vector3(-0.1, 0, 0), Vector3(-0.8, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-0.2, 0, 0), Vector3(0.5, 0, 0.3), Vector3(-0.2, 0, 0), Vector3(0.5, 0, 0.3), Vector3(-0.2, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(-0.1, 0, 0), Vector3(-0.8, 0, 0), Vector3(-0.1, 0, 0), Vector3(-0.8, 0, 0), Vector3(-0.1, 0, 0)])
		
	return anim

# --- HIT REACTION ANIMATION ---
static func create_hit_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.3
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.08, 0.3], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.9, -0.15), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.08, 0.3], 
		[Vector3(0, 0, 0), Vector3(-0.4, 0.2, -0.1), Vector3(0, 0, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest/Head:rotation", 
		[0.0, 0.08, 0.3], 
		[Vector3(0, 0, 0), Vector3(0.4, -0.3, 0.1), Vector3(0, 0, 0)])
		
	return anim

# --- RIFLE IDLE ANIMATION ---
static func create_rifle_idle_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 1.0, 2.0], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.97, 0), Vector3(0, 0.95, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(0.02, 0.05, 0), Vector3(-0.02, -0.03, 0), Vector3(0.02, 0.05, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest/Head:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(0, -0.05, 0), Vector3(0.02, -0.02, 0), Vector3(0, -0.05, 0)])
	
	# Left Arm supporting rifle
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(0.45, 0.2, -0.35), Vector3(0.42, 0.22, -0.33), Vector3(0.45, 0.2, -0.35)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(-0.75, 0.1, 0), Vector3(-0.72, 0.1, 0), Vector3(-0.75, 0.1, 0)])
	
	# Right Arm on rifle grip
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(-0.25, -0.15, 0.35), Vector3(-0.27, -0.18, 0.33), Vector3(-0.25, -0.15, 0.35)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(-0.55, 0, 0.1), Vector3(-0.57, 0, 0.1), Vector3(-0.55, 0, 0.1)])
	
	_add_track_keys(anim, "Rig/Hips/LeftThigh:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(0.08, 0, -0.06), Vector3(0.04, 0, -0.06), Vector3(0.08, 0, -0.06)])
	_add_track_keys(anim, "Rig/Hips/LeftThigh/LeftShin:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(-0.12, 0, 0), Vector3(-0.06, 0, 0), Vector3(-0.12, 0, 0)])
		
	_add_track_keys(anim, "Rig/Hips/RightThigh:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(0.04, 0, 0.08), Vector3(0.02, 0, 0.08), Vector3(0.04, 0, 0.08)])
	_add_track_keys(anim, "Rig/Hips/RightThigh/RightShin:rotation", 
		[0.0, 1.0, 2.0], 
		[Vector3(-0.08, 0, 0), Vector3(-0.04, 0, 0), Vector3(-0.08, 0, 0)])
		
	return anim

# --- AIM IDLE (ADS) ANIMATION ---
static func create_aim_idle_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.5, 1.0], 
		[Vector3(0, 0.93, 0.02), Vector3(0, 0.94, 0.02), Vector3(0, 0.93, 0.02)])
	
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(0.1, -0.05, 0), Vector3(0.08, -0.05, 0), Vector3(0.1, -0.05, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest/Head:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.04, 0.03, 0), Vector3(-0.03, 0.03, 0), Vector3(-0.04, 0.03, 0)])
	
	# Raised arms aiming down sights
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(0.6, 0.25, -0.4), Vector3(0.58, 0.26, -0.38), Vector3(0.6, 0.25, -0.4)])
	_add_track_keys(anim, "Rig/Hips/Chest/LeftShoulder/LeftUpperArm/LeftForearm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.85, 0.1, 0), Vector3(-0.83, 0.1, 0), Vector3(-0.85, 0.1, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.15, -0.18, 0.45), Vector3(-0.17, -0.19, 0.43), Vector3(-0.15, -0.18, 0.45)])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.5, 1.0], 
		[Vector3(-0.65, 0, 0.1), Vector3(-0.67, 0, 0.1), Vector3(-0.65, 0, 0.1)])
		
	return anim

# --- RIFLE SHOOT (RECOIL) ANIMATION ---
static func create_rifle_shoot_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.12
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.03, 0.08, 0.12], 
		[Vector3(0, 0.93, 0.02), Vector3(0, 0.91, -0.02), Vector3(0, 0.94, 0.01), Vector3(0, 0.93, 0.02)])
	
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.03, 0.08, 0.12], 
		[Vector3(0.1, -0.05, 0), Vector3(0.2, -0.03, 0), Vector3(0.14, -0.04, 0), Vector3(0.1, -0.05, 0)])
	
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.03, 0.08, 0.12], 
		[Vector3(-0.15, -0.18, 0.45), Vector3(-0.05, -0.22, 0.5), Vector3(-0.12, -0.19, 0.46), Vector3(-0.15, -0.18, 0.45)])
		
	return anim

# --- FULL RELOAD ANIMATION ---
static func create_reload_rifle_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_NONE
	
	_add_track_keys(anim, "Rig/Hips:position", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(0, 0.95, 0), Vector3(0, 0.92, 0.04), Vector3(0, 0.9, 0.02), Vector3(0, 0.93, 0), Vector3(0, 0.95, 0)])
	_add_track_keys(anim, "Rig/Hips/Chest:rotation", 
		[0.0, 0.5, 1.0, 1.5, 2.0], 
		[Vector3(0, 0, 0), Vector3(0.1, -0.1, 0), Vector3(0.15, -0.15, 0), Vector3(0.05, 0, 0), Vector3(0, 0, 0)])
	
	# Right hand mag grab and rack
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm:rotation", 
		[0.0, 0.3, 0.7, 1.2, 1.6, 2.0], 
		[
			Vector3(-0.25, -0.15, 0.35),
			Vector3(-0.1, 0.4, 0.7),
			Vector3(0.2, 0.7, 0.4),
			Vector3(-0.2, 0.3, 0.2),
			Vector3(-0.1, 0.4, 0.5),
			Vector3(-0.25, -0.15, 0.35)
		])
	_add_track_keys(anim, "Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm:rotation", 
		[0.0, 0.3, 0.7, 1.2, 1.6, 2.0], 
		[Vector3(-0.55, 0, 0.1), Vector3(-0.8, 0.2, 0.2), Vector3(-0.9, 0.3, 0.1), Vector3(-0.7, 0, 0.1), Vector3(-1.1, 0, 0), Vector3(-0.55, 0, 0.1)])
		
	return anim
