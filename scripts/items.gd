extends Node
class_name ItemDefinition

enum ItemType { CONSUMABLE, KEY, MATERIAL }

@export var id: String = ""
@export var display_name: String = ""
@export var type: ItemType = ItemType.CONSUMABLE
@export var icon: String = "📦"
@export var description: String = ""
@export var stackable: bool = true
@export var max_stack: int = 99
@export var value: int = 0  # базовая цена в монетах
@export var heal_amount: float = 0.0
@export var stamina_restore: float = 0.0

static func catalog() -> Dictionary:
	return {
		"potion": ItemDefinition.new("potion", "Зелье здоровья", ItemType.CONSUMABLE, "🧪", "Восстанавливает 50 HP.", true, 20, 15, 50.0, 0.0),
		"big_potion": ItemDefinition.new("big_potion", "Большое зелье", ItemType.CONSUMABLE, "⚗️", "Восстанавливает 100 HP.", true, 10, 40, 100.0, 0.0),
		"stamina_potion": ItemDefinition.new("stamina_potion", "Зелье стамины", ItemType.CONSUMABLE, "🍵", "Восстанавливает 100 стамины.", true, 15, 15, 0.0, 100.0),
		"coin": ItemDefinition.new("coin", "Монета", ItemType.MATERIAL, "🪙", "Валюта. В будущем можно тратить.", true, 999, 1, 0.0, 0.0),
		"gem": ItemDefinition.new("gem", "Самоцвет", ItemType.MATERIAL, "💎", "Ценный самоцвет.", true, 99, 50, 0.0, 0.0),
		"bone_key": ItemDefinition.new("bone_key", "Костяной ключ", ItemType.KEY, "🗝️", "Ключ от древней двери.", false, 1, 100, 0.0, 0.0),
	}

static func get_item(item_id: String) -> ItemDefinition:
	var c = catalog()
	if c.has(item_id):
		return c[item_id]
	return null

func _init(p_id: String = "", p_name: String = "", p_type: ItemType = ItemType.CONSUMABLE,
	p_icon: String = "📦", p_desc: String = "", p_stack: bool = true, p_max_stack: int = 99,
	p_value: int = 0, p_heal: float = 0.0, p_stamina: float = 0.0) -> void:
	id = p_id
	display_name = p_name
	type = p_type
	icon = p_icon
	description = p_desc
	stackable = p_stack
	max_stack = p_max_stack
	value = p_value
	heal_amount = p_heal
	stamina_restore = p_stamina