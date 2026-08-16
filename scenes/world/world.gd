extends Node3D

@onready var hud: PlayerHUD = $HUD

## Позиция появления игрока (устанавливается из сцены)
@export var spawn_position: Vector3 = Vector3(0, 0.4, 3.5)
@export var spawn_yaw: float = 0.0

var player_scene: PackedScene
var player

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Инициализация прогрессии игрока (уровни/навыки)
	GameManager.init_progression()
	
	player_scene = load(GameManager.get_character_scene())
	if not player_scene:
		push_error("Failed to load player scene")
		return
	
	var instance = player_scene.instantiate()
	if not instance:
		push_error("Failed to instantiate player")
		return
	
	player = instance
	add_child(player)
	player.position = spawn_position
	player.rotation.y = spawn_yaw
	
	# Восстанавливаем здоровье/стамину если пришли через портал
	GameManager.restore_player_state(player)
	
	if hud and instance is Player:
		hud.connect_to_player(instance as Player)