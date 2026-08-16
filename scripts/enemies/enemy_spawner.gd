extends Node
class_name EnemySpawner

# --- Конфигурация спавнера ---
@export var enemy_scene: PackedScene
@export var spawn_points: Array[Node3D] = []
@export var max_enemies: int = 5
@export var spawn_interval: float = 10.0
@export var activation_range: float = 20.0

# --- Состояние ---
var current_enemies: Array = []
var is_active: bool = false
var spawn_timer: float = 0.0

# --- Ссылки ---
@onready var player: Node3D = null

func _ready():
	# Поиск игрока
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Инициализация точек спавна если не заданы
	if spawn_points.is_empty():
		create_default_spawn_points()

func _process(delta):
	if not is_active:
		check_activation()
	else:
		spawn_timer -= delta
		if spawn_timer <= 0:
			try_spawn_enemy()
			spawn_timer = spawn_interval

func check_activation():
	if player and global_position.distance_to(player.global_position) <= activation_range:
		activate()

func activate():
	is_active = true
	print("EnemySpawner activated!")

func try_spawn_enemy():
	if current_enemies.size() >= max_enemies:
		return
	
	if not enemy_scene:
		push_error("Enemy scene not assigned to spawner!")
		return
	
	# Выбор случайной точки спавна
	if spawn_points.is_empty():
		return
	
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	
	# Спавн врага
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point.global_position
	
	current_enemies.append(enemy)
	
	# Подписка на смерть врага
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy):
	current_enemies.erase(enemy)

func create_default_spawn_points():
	# Создание точек спавна вокруг спавнера
	for i in range(4):
		var point = Node3D.new()
		point.name = "SpawnPoint_%d" % i
		var angle = (PI * 2.0 / 4.0) * i
		point.position = Vector3(cos(angle) * 5.0, 0, sin(angle) * 5.0)
		add_child(point)
		spawn_points.append(point)

func deactivate():
	is_active = false
	spawn_timer = spawn_interval

func clear_all_enemies():
	for enemy in current_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemies.clear()
