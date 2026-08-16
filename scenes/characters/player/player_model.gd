@tool
extends Node3D
class_name PlayerModel

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sword_hitbox: Area3D = get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Sword/Hitbox") as Area3D
@onready var weapon_mount: Node3D = get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount") as Node3D
@onready var sword_node: Node3D = get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Sword") as Node3D
@onready var rifle_node: Node3D = get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Rifle") as Node3D
@onready var blade_glow: MeshInstance3D = get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Sword/BladeGlow") as MeshInstance3D
@onready var visor_glow: MeshInstance3D = get_node_or_null("Rig/Hips/Chest/Head/VisorGlow") as MeshInstance3D
@onready var rifle_muzzle_glow: MeshInstance3D = get_node_or_null("Rig/Hips/Chest/RightShoulder/RightUpperArm/RightForearm/RightHand/WeaponMount/Rifle/MuzzlePoint/MuzzleDevice") as MeshInstance3D

signal hit_registered(body: Node3D, damage: float, is_heavy: bool)

var current_damage: float = 20.0
var is_heavy_attack: bool = false
var hit_entities: Array[Node3D] = []
var current_weapon_type: String = "sword"  # "sword" or "rifle"

func _ready() -> void:
	AnimationLibraryBuilder.build_all_animations(anim_player)
	
	if sword_hitbox:
		sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
		sword_hitbox.monitoring = false
	
	# Default to sword
	set_weapon_visible("sword")

func play_anim(anim_name: String, blend: float = 0.15, speed: float = 1.0) -> void:
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name, blend, speed)

func is_playing(anim_name: String) -> bool:
	return anim_player.is_playing() and anim_player.current_animation == anim_name

func get_current_animation() -> String:
	return anim_player.current_animation

func set_weapon_visible(weapon_type: String) -> void:
	current_weapon_type = weapon_type
	if sword_node:
		sword_node.visible = (weapon_type == "sword")
	if rifle_node:
		rifle_node.visible = (weapon_type == "rifle")

func get_current_weapon() -> String:
	return current_weapon_type

func start_attack_hitbox(damage: float, heavy: bool = false) -> void:
	current_damage = damage
	is_heavy_attack = heavy
	hit_entities.clear()
	if sword_hitbox and current_weapon_type == "sword":
		sword_hitbox.monitoring = true
	
	# Boost sword glow during attack
	if blade_glow and blade_glow.material_override:
		var mat = blade_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 7.0 if heavy else 4.5
	
	# Rifle muzzle glow during shooting
	if rifle_muzzle_glow and rifle_muzzle_glow.material_override and current_weapon_type == "rifle":
		var mat = rifle_muzzle_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 8.0

func stop_attack_hitbox() -> void:
	if sword_hitbox:
		sword_hitbox.monitoring = false
	hit_entities.clear()
	
	if blade_glow and blade_glow.material_override:
		var mat = blade_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.5
	
	if rifle_muzzle_glow and rifle_muzzle_glow.material_override:
		var mat = rifle_muzzle_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.5

func _on_sword_hitbox_body_entered(body: Node3D) -> void:
	if body == get_parent() or body == self:
		return
	if body in hit_entities:
		return
	
	hit_entities.append(body)
	hit_registered.emit(body, current_damage, is_heavy_attack)
	
	if body.has_method("take_damage"):
		body.take_damage(current_damage, is_heavy_attack, global_position)
