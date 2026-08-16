extends AdvancedEnemyBase
class_name VoidReaper

# --- Уникальные способности Пустотного Жнеца ---
@export_group("Void Abilities")
@export var void_dash_damage: float = 15.0
@export var void_dash_range: float = 8.0
@export var teleport_chance: float = 0.3 # 30% шанс телепортации при получении урона
@export var shadow_clone_duration: float = 5.0

# --- Состояния ---
var can_teleport: bool = true
var teleport_cooldown: float = 0.0
var has_clone: bool = false
var clone_node: Node3D = null

# --- Визуальные эффекты (заглушки для частиц) ---
@onready var void_particles: GPUParticles3D = $VoidParticles if has_node("VoidParticles") else null
@onready var trail_mesh: MeshInstance3D = $TrailMesh if has_node("TrailMesh") else null

func _ready():
	super._ready()
	# Настройка уникальных статов
	max_health = 150.0
	damage = 20.0
	speed = 6.5
	xp_value = 120
	health = max_health
	
	# Визуальный стиль "Пустоты"
	setup_void_appearance()

func setup_void_appearance():
	# Здесь будет настройка шейдеров и материалов для AAA-вида
	# Тёмная материя, фиолетовое свечение, искажение пространства
	if trail_mesh:
		trail_mesh.material_override = create_void_material()
	
	# Добавление эффекта шлейфа из тёмной энергии
	if void_particles:
		void_particles.emitting = true

func create_void_material() -> Material:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.0, 0.2) # Тёмно-фиолетовый
	material.emission_enabled = true
	material.emission = Color(0.5, 0.0, 1.0) # Яркое фиолетовое свечение
	material.emission_energy_multiplier = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func perform_attack():
	# Атака Пустотного Жнеца: комбо из телепортации и удара
	match randi() % 3:
		0:
			void_dash_attack()
		1:
			shadow_strike()
		2:
			basic_void_slash()

func void_dash_attack():
	# Быстрый рывок сквозь пространство к игроку
	if not target:
		return
	
	# Эффект телепортации
	spawn_void_effect(global_position)
	
	# Мгновенное перемещение за спину игрока
	var behind_player = target.global_position - (target.global_position - global_position).normalized() * 2.0
	global_position = behind_player
	
	# Эффект появления
	spawn_void_effect(global_position)
	
	# Нанесение урона
	deal_damage_to_target(void_dash_damage)
	
	# Визуальный эффект удара
	create_voidSlash_visuals()

func shadow_strike():
	# Создание тени-клона который атакует
	if has_clone:
		return
	
	has_clone = true
	clone_node = create_shadow_clone()
	get_tree().create_timer(shadow_clone_duration).timeout.connect(func(): remove_shadow_clone())
	
	# Клон наносит урон через небольшую задержку
	await get_tree().create_timer(0.5).timeout
	if clone_node and target:
		deal_damage_to_target(damage * 0.8)
	
	remove_shadow_clone()

func basic_void_slash():
	# Обычная атака ближнего боя с эффектом пустоты
	if target and global_position.distance_to(target.global_position) <= attack_range:
		deal_damage_to_target(damage)
		create_voidSlash_visuals()

func deal_damage_to_target(amount: float):
	if not target or not target.has_method("take_damage"):
		return
	target.take_damage(amount, true, global_position)

func create_shadow_clone() -> Node3D:
	# Создание временного клона
	var clone = MeshInstance3D.new()
	clone.mesh = SphereMesh.new()
	clone.material_override = create_void_material()
	clone.global_position = global_position + Vector3.RIGHT * 2.0
	get_parent().add_child(clone)
	
	# Анимация клона
	var tween = get_tree().create_tween()
	tween.tween_property(clone, "global_position", target.global_position if target else clone.global_position, 0.5)
	tween.tween_callback(func(): spawn_void_effect(clone.global_position))
	
	return clone

func remove_shadow_clone():
	if clone_node:
		clone_node.queue_free()
		clone_node = null
	has_clone = false

func take_damage(amount: float, is_heavy: bool = false, source_pos: Vector3 = Vector3.ZERO):
	# Уникальная механика: шанс телепортации при получении урона
	if can_teleport and randf() < teleport_chance and amount > 10.0:
		teleport_away()
		amount *= 0.5 # Снижение урона после успешной телепортации
	
	super.take_damage(amount, is_heavy, source_pos)

func teleport_away():
	# Телепортация в случайное место поблизости
	var random_offset = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	var new_pos = global_position + random_offset
	
	# Проверка чтобы не застрять в стене (упрощённо)
	spawn_void_effect(global_position)
	global_position = new_pos
	spawn_void_effect(global_position)
	
	# Кулдаун на телепортацию
	can_teleport = false
	teleport_cooldown = 3.0
	get_tree().create_timer(teleport_cooldown).timeout.connect(func(): can_teleport = true)

func spawn_void_effect(effect_pos: Vector3):
	# Создание визуального эффекта пустоты
	# В реальной игре здесь будет instantiation префаба частиц
	var effect = Area3D.new()
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	effect.add_child(collision)
	get_parent().add_child(effect)
	effect.global_position = effect_pos
	
	# Автоудаление
	get_tree().create_timer(0.5).timeout.connect(func(): effect.queue_free())

func create_voidSlash_visuals():
	# Эффект разреза пространства
	pass

func update_visuals():
	super.update_visuals()
	# Изменение интенсивности свечения в зависимости от здоровья
	if trail_mesh and trail_mesh.material_override is StandardMaterial3D:
		var mat = trail_mesh.material_override as StandardMaterial3D
		var health_percent = health / max_health
		mat.emission_energy_multiplier = 1.0 + health_percent * 2.0
