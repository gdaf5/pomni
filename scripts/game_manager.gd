extends Node

enum CharacterType { CUSTOM, SKELETON }

var selected_character: CharacterType = CharacterType.CUSTOM

# Сохранённое состояние игрока между сценами
var saved_health: float = -1.0
var saved_max_health: float = 100.0
var saved_stamina: float = -1.0
var saved_max_stamina: float = 100.0
var saved_weapon: int = 0  # 0 = SWORD, 1 = RIFLE

# --- Инвентарь ---
# Хранит: id предмета -> количество (только стековые/счётные предметы)
var inventory: Dictionary = {}
signal inventory_changed

func get_character_scene() -> String:
	match selected_character:
		CharacterType.CUSTOM:
			return "res://scenes/characters/player/player.tscn"
		CharacterType.SKELETON:
			return "res://scenes/characters/player/player_skeleton.tscn"
	return "res://scenes/characters/player/player.tscn"

# Сохраняет состояние игрока перед сменой сцены
func save_player_state(player) -> void:
	if not player:
		return
	saved_health = player.health
	saved_max_health = player.max_health
	saved_stamina = player.stamina
	saved_max_stamina = player.max_stamina
	saved_weapon = 1 if player.current_weapon == player.WeaponType.RIFLE else 0

# Восстанавливает состояние игрока после смены сцены
func restore_player_state(player) -> void:
	if not player:
		return
	if saved_health > 0:
		player.health = saved_health
		player.health_changed.emit(player.health, player.max_health)
	if saved_stamina > 0:
		player.stamina = saved_stamina
		player.stamina_changed.emit(player.stamina, player.max_stamina)

# --- Инвентарь ---

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0 or item_id == "":
		return
	var def := ItemDefinition.get_item(item_id)
	if def == null:
		push_warning("add_item: неизвестный предмет: " + item_id)
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0 or not inventory.has(item_id):
		return
	inventory[item_id] = int(inventory[item_id]) - amount
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	inventory_changed.emit()

func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

# Возвращает список записей инвентаря: [{id, count, def}]
func get_inventory_entries() -> Array:
	var entries: Array = []
	for item_id in inventory:
		var def := ItemDefinition.get_item(item_id)
		if def:
			entries.append({ "id": item_id, "count": int(inventory[item_id]), "def": def })
	entries.sort_custom(func(a, b):
		return str(a["id"]) < str(b["id"]))
	return entries

# Использует предмет через игрока. Возвращает true если использован.
func use_item(item_id: String, player) -> bool:
	if not player or not has_item(item_id):
		return false
	var def := ItemDefinition.get_item(item_id)
	if def == null:
		return false
	var used := false
	if def.heal_amount > 0.0 and player.has_method("heal"):
		player.heal(def.heal_amount)
		used = true
	if def.stamina_restore > 0.0 and player.has_method("restore_stamina"):
		player.restore_stamina(def.stamina_restore)
		used = true
	if def.type == ItemDefinition.ItemType.CONSUMABLE and used:
		remove_item(item_id, 1)
		return true
	return false