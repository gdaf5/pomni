extends Resource
class_name MagicSkillDefinition

@export var id: String
@export var name: String
@export var description: String
@export var icon: Texture2D
@export var max_level: int = 1
@export var cost_points: int = 1 # Стоимость очков навыков
@export var is_ultimate: bool = false # Является ли ультимативной способностью

# Параметры заклинания
@export var mana_cost: int = 0
@export var cooldown: float = 0.0
@export var damage_base: int = 0
@export var damage_scale: float = 0.0 # Множитель от уровня магии/интеллекта
@export var effect_type: String = "fire" # fire, ice, lightning, heal, shield
@export var area_of_effect: float = 0.0
@export var duration: float = 0.0 # Для баффов/дебаффов

# Требования
@export var required_player_level: int = 1
@export var prerequisite_ids: Array[String] = []

# Бонусы пассивные (если это пассивный навык)
@export var passive_mana regen: float = 0.0
@export var passive_damage_bonus: float = 0.0
@export var passive_resistance: float = 0.0

func get_damage_at_level(level: int, player_intellect: int = 10) -> int:
    return damage_base + int(damage_scale * level * (player_intellect / 10.0))
