extends Area3D
class_name Portal

## Целевая сцена для телепортации (пусто = телепорт в позицию на этой же сцене)
@export var target_scene: String = ""
## Позиция появления (используется если target_scene пуст)
@export var target_position: Vector3 = Vector3.ZERO
## Куда повернуть игрока (в радианах) после появления
@export var target_yaw: float = 0.0
## Задержка перед телепортом (чтобы показать вспышку)
@export var delay: float = 0.3
## Название локации для HUD-подсказки (опционально)
@export var location_name: String = ""

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var ring: MeshInstance3D = $Ring

var _teleporting: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if anim_player:
		anim_player.play("spin")

func _on_body_entered(body: Node3D) -> void:
	if _teleporting:
		return
	if body is Player:
		_teleporting = true
		if location_name != "":
			print("[Portal] Телепорт в: ", location_name)
		var tween = create_tween()
		tween.tween_property(ring, "scale", Vector3(2.2, 1.4, 2.2), 0.25)
		tween.tween_callback(func():
			_do_teleport(body)
		)

func _do_teleport(player: Node) -> void:
	# Сохраняем состояние игрока перед переходом
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm and gm.has_method("save_player_state") and player:
		gm.save_player_state(player)
	
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	else:
		player.global_position = target_position
		player.rotation.y = target_yaw
		_teleporting = false
		var tween = create_tween()
		tween.tween_property(ring, "scale", Vector3.ONE, 0.3)