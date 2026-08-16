extends Node
class_name WeaponBase


@export var weapon_name: String = "Weapon"
@export var damage: float = 25.0
@export var fire_rate: float = 0.1
@export var attack_range: float = 50.0

var is_equipped: bool = false
var weapon_owner: Node3D = null

func _ready() -> void:
	pass

func equip(owner_node: Node3D) -> void:
	weapon_owner = owner_node
	is_equipped = true
	_on_equip()

func unequip() -> void:
	_on_unequip()
	is_equipped = false
	weapon_owner = null

func _on_equip() -> void:
	pass

func _on_unequip() -> void:
	pass

func can_attack() -> bool:
	return true

func attack() -> bool:
	return false

func aim_pressed() -> void:
	pass

func aim_released() -> void:
	pass

func reload() -> bool:
	return false

func get_ammo_info() -> Dictionary:
	return {"current": -1, "max": -1, "infinite": true}

func process(_delta: float) -> void:
	pass

func get_animation_state() -> String:
	return "idle"
