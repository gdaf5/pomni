extends CharacterBody3D
class_name AdvancedEnemyBase

# --- Конфигурация ---
@export_group("Stats")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var speed: float = 5.0
@export var xp_value: int = 50

@export_group("AI Settings")
@export var detection_range: float = 15.0
@export var attack_range: float = 2.5
@export var chase_speed_multiplier: float = 1.2
@export var stop_distance: float = 2.0

# --- Состояния ---
enum State { IDLE, CHASE, ATTACK, STUNNED, DIE }
var current_state: State = State.IDLE
var target: Node3D = null
var health: float
var is_dead: bool = false

# --- Таймеры и переменные ---
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var stun_duration: float = 0.0

# --- Ссылки на узлы (заполняются в дочерних классах) ---
@onready var animation_tree: AnimationTree = $AnimationTree if has_node("AnimationTree") else null
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D if has_node("NavigationAgent3D") else null
@onready var vision_ray: RayCast3D = $VisionRay if has_node("VisionRay") else null

# --- Сигналы ---
signal health_changed(new_health, max_health)
signal enemy_died(enemy)
signal hit_taken(amount)

func _ready():
	health = max_health
	update_visuals()
	# Подписка на глобальный менеджер, если нужно
	if GameManager.has_method("register_enemy"):
		GameManager.register_enemy(self)

func _physics_process(delta):
	if is_dead:
		return
	
	handle_state_machine(delta)
	move_and_slide()

func handle_state_machine(delta):
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.CHASE:
			process_chase(delta)
		State.ATTACK:
			process_attack(delta)
		State.STUNNED:
			process_stunned(delta)
		State.DIE:
			process_death(delta)

func process_idle(delta):
	state_timer -= delta
	if state_timer <= 0:
		find_target()
		if target:
			change_state(State.CHASE)
		else:
			# Случайное блуждание можно добавить здесь
			state_timer = randf_range(1.0, 3.0)

func process_chase(delta):
	if not target or is_target_lost():
		change_state(State.IDLE)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		change_state(State.ATTACK)
		return
	
	# Движение к цели
	if nav_agent:
		nav_agent.target_position = target.global_position
		var next_pos = nav_agent.get_next_path_position()
		velocity = (next_pos - global_position).normalized() * speed * chase_speed_multiplier
		look_at(target.global_position)
	else:
		# Фолбек если нет навигации
		velocity = (target.global_position - global_position).normalized() * speed * chase_speed_multiplier
		look_at(target.global_position)

func process_attack(delta):
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		perform_attack()
		attack_cooldown = get_attack_cooldown_time()
		
	# Если цель далеко, прервать атаку
	if target and global_position.distance_to(target.global_position) > attack_range * 1.5:
		change_state(State.CHASE)

func process_stunned(delta):
	stun_duration -= delta
	velocity = velocity.lerp(Vector3.ZERO, delta * 5.0) # Замедление
	if stun_duration <= 0:
		change_state(State.CHASE if target else State.IDLE)

func process_death(delta):
	velocity = velocity.lerp(Vector3.ZERO, delta * 10.0)
	# Здесь можно добавить физику ragdoll позже

# --- Боевая система ---
func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO, knockback_force: float = 0.0):
	if is_dead:
		return
	
	health -= amount
	hit_taken.emit(amount)
	update_visuals()
	
	# Отталкивание
	if knockback_force > 0:
		velocity += knockback_dir.normalized() * knockback_force
	
	if health <= 0:
		die()
	else:
		# Шанс оглушения при сильном ударе
		if knockback_force > 20.0:
			stun(0.5)
	
	health_changed.emit(health, max_health)

func die():
	is_dead = true
	current_state = State.DIE
	enemy_died.emit(self)
	# Выдача опыта игроку
	if GameManager.has_method("add_xp"):
		GameManager.add_xp(xp_value)
	
	# Запуск анимации смерти
	if animation_tree:
		animation_tree.set("parameters/conditions/death", true)
	
	# Удаление через время
	await get_tree().create_timer(3.0).timeout
	queue_free()

func stun(duration: float):
	stun_duration = duration
	change_state(State.STUNNED)
	if animation_tree:
		animation_tree.set("parameters/conditions/stun", true)

# --- Вспомогательные функции ---
func find_target():
	# Простой поиск игрока по тегу или группе
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func is_target_lost() -> bool:
	if not target:
		return true
	if global_position.distance_to(target.global_position) > detection_range * 1.5:
		return true
	# Проверка видимости (Raycast)
	if vision_ray and vision_ray.is_inside_tree():
		vision_ray.target_position = target.global_position - global_position
		if not vision_ray.is_colliding():
			return true
	return false

func change_state(new_state: State):
	if new_state == current_state:
		return
	current_state = new_state
	state_timer = randf_range(0.5, 1.5) # Сброс таймера
	attack_cooldown = 0.0
	
	# Обновление анимаций
	if animation_tree:
		match new_state:
			State.IDLE: animation_tree.set("parameters/conditions/idle", true)
			State.CHASE: animation_tree.set("parameters/conditions/run", true)
			State.ATTACK: animation_tree.set("parameters/conditions/attack", true)
			State.STUNNED: animation_tree.set("parameters/conditions/stun", true)

# --- Переопределяемые методы для конкретных врагов ---
func perform_attack():
	# Базовая атака (переопределяется)
	pass

func get_attack_cooldown_time() -> float:
	return 1.5

func update_visuals():
	# Базовое обновление (переопределяется для эффектов)
	pass
