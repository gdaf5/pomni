extends Node

enum CharacterType { CUSTOM, SKELETON, GOJO }

var selected_character: CharacterType = CharacterType.CUSTOM

# Сохранённое состояние игрока между сценами
var saved_health: float = -1.0
var saved_max_health: float = 100.0
var saved_stamina: float = -1.0
var saved_max_stamina: float = 100.0
var saved_weapon: int = 0  # 0 = SWORD, 1 = RIFLE

# --- Инвентарь улучшенный ---
var inventory: Dictionary = {}

# --- Прогрессия игрока ---
var player_progression: PlayerProgression = null

signal inventory_changed
signal progression_ready(progression: PlayerProgression)

func add_item_advanced(item_id: String, amount: int = 1, item_data: Dictionary = {}) -> void:
	if amount <= 0 or item_id == "":
		return
	var def := ItemDefinition.get_item(item_id)
	if def == null:
		push_warning("add_item_advanced: неизвестный предмет: " + item_id)
		return

	if not def.stackable or not item_data.is_empty():
		for i in range(amount):
			if not inventory.has(item_id):
				inventory[item_id] = []
			inventory[item_id].append({"count": 1, "data": item_data.duplicate()})
	else:
		if not inventory.has(item_id):
			inventory[item_id] = [{"count": 0, "data": {}}]
		inventory[item_id][0]["count"] += amount

	inventory_changed.emit()

func remove_item_advanced(item_id: String, amount: int = 1) -> void:
	if amount <= 0 or not inventory.has(item_id):
		return

	var item_list = inventory[item_id]
	if typeof(item_list) == TYPE_ARRAY:
		var remaining := amount
		while remaining > 0 and not item_list.is_empty():
			var slot = item_list[-1]
			if slot["count"] <= remaining:
				remaining -= slot["count"]
				item_list.pop_back()
			else:
				slot["count"] -= remaining
				remaining = 0

		if item_list.is_empty():
			inventory.erase(item_id)
	else:
		remove_item_legacy(item_id, amount)
		return

	inventory_changed.emit()

func remove_item_legacy(item_id: String, amount: int = 1) -> void:
	if amount <= 0 or not inventory.has(item_id):
		return
	inventory[item_id] = int(inventory[item_id]) - amount
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	inventory_changed.emit()

func get_item_count(item_id: String) -> int:
	if not inventory.has(item_id):
		return 0

	var item_list = inventory[item_id]
	if typeof(item_list) == TYPE_ARRAY:
		var total := 0
		for slot in item_list:
			total += int(slot.get("count", 0))
		return total
	else:
		return int(inventory[item_id])

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

func get_inventory_entries() -> Array:
	var entries: Array = []
	for item_id in inventory:
		var def := ItemDefinition.get_item(item_id)
		if def:
			var count = get_item_count(item_id)
			var slots = inventory[item_id] if typeof(inventory[item_id]) == TYPE_ARRAY else [{"count": count, "data": {}}]
			entries.append({ "id": item_id, "count": count, "def": def, "slots": slots })
	entries.sort_custom(func(a, b):
		return str(a["id"]) < str(b["id"]))
	return entries

func get_item_slot(item_id: String, slot_index: int = 0) -> Dictionary:
	if not inventory.has(item_id):
		return {"count": 0, "data": {}}

	var item_list = inventory[item_id]
	if typeof(item_list) == TYPE_ARRAY and slot_index < item_list.size():
		return item_list[slot_index]
	return {"count": get_item_count(item_id), "data": {}}

func get_character_scene() -> String:
	match selected_character:
		CharacterType.CUSTOM:
			return "res://scenes/characters/player/player.tscn"
		CharacterType.SKELETON:
			return "res://scenes/characters/player/player_skeleton.tscn"
		CharacterType.GOJO:
			return "res://scenes/characters/player/player_gojo.tscn"
	return "res://scenes/characters/player/player.tscn"

func save_player_state(player) -> void:
	if not player:
		return
	saved_health = player.health
	saved_max_health = player.max_health
	saved_stamina = player.stamina
	saved_max_stamina = player.max_stamina
	saved_weapon = 1 if player.current_weapon == player.WeaponType.RIFLE else 0

func restore_player_state(player) -> void:
	if not player:
		return
	if saved_health > 0:
		player.health = saved_health
		player.health_changed.emit(player.health, player.max_health)
	if saved_stamina > 0:
		player.stamina = saved_stamina
		player.stamina_changed.emit(player.stamina, player.max_stamina)

func add_item(item_id: String, amount: int = 1) -> void:
	add_item_advanced(item_id, amount, {})

func remove_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0 or not inventory.has(item_id):
		return
	var item_list = inventory[item_id]
	if typeof(item_list) == TYPE_ARRAY:
		remove_item_advanced(item_id, amount)
	else:
		remove_item_legacy(item_id, amount)

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
		remove_item_advanced(item_id, 1)
		return true
	return false

func init_progression() -> PlayerProgression:
	if player_progression:
		return player_progression

	player_progression = PlayerProgression.new()
	add_child(player_progression)
	player_progression.stats_updated.connect(_on_progression_stats_updated)
	progression_ready.emit(player_progression)
	return player_progression

func _on_progression_stats_updated() -> void:
	pass

func add_xp(amount: int) -> void:
	if player_progression:
		player_progression.add_xp(amount)

func get_player_level() -> int:
	if player_progression:
		return player_progression.current_level
	return 1

func get_skill_points() -> int:
	if player_progression:
		return player_progression.skill_points
	return 0

func unlock_skill(skill_def: SkillDefinition, levels: int = 1) -> bool:
	if player_progression:
		return player_progression.unlock_skill(skill_def, levels)
	return false

func can_unlock_skill(skill_def: SkillDefinition, levels: int = 1) -> bool:
	if player_progression:
		return player_progression.can_unlock_skill(skill_def, levels)
	return false

func get_bonus_stat(stat_name: String) -> float:
	if player_progression:
		return player_progression.get_bonus_stat(stat_name)
	return 0.0