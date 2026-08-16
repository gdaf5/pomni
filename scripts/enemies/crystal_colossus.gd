extends AdvancedEnemyBase
class_name CrystalColossus

# --- Уникальные способности Кристального Колосса ---
@export_group("Crystal Abilities")
@export var crystal_spike_damage: float = 25.0
@export var ground_slam_damage: float = 35.0
@export var crystal_shard_count: int = 8
@export var defense_mode_threshold: float = 0.5 # При здоровье ниже 50% включается режим защиты

# --- Состояния ---
var is_in_defense_mode: bool = false
var is_charging: bool = false
var charge_timer: float = 0.0
var crystal_shards_active: bool = false

# --- Визуальные эффекты ---
@onready var crystal_material: StandardMaterial3D = null
@onready var glow_mesh: MeshInstance3D = $GlowMesh if has_node("GlowMesh") else null
@onready var spike_particles: GPUParticles3D = $SpikeParticles if has_node("SpikeParticles") else null

func _ready():
	super._ready()
	# Настройка уникальных статов (медленный но мощный и бронированный)
	max_health = 300.0
	damage = 30.0
	speed = 3.0
	xp_value = 200
	health = max_health
	
	setup_crystal_appearance()

func setup_crystal_appearance():
	# Создание AAA-материала кристалла с преломлением и свечением
	crystal_material = create_crystal_material()
	
	if glow_mesh:
		glow_mesh.material_override = crystal_material
	
	# Настройка частиц для шипов
	if spike_particles:
		spike_particles.emitting = false

func create_crystal_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.8, 1.0) # Голубой кристалл
	material.metallic = 0.9
	material.roughness = 0.1
	material.emission_enabled = true
	material.emission = Color(0.0, 1.0, 1.0) # Циановое свечение
	material.emission_energy_multiplier = 1.5
	
	# Эффект преломления (симуляция)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.alpha = 0.9
	
	return material

func perform_attack():
	# Атаки Колосса: мощные но медленные
	if is_in_defense_mode:
		defensive_crystal_burst()
	else:
		match randi() % 3:
			0:
				ground_slam()
			1:
				crystal_spike_eruption()
			2:
				charge_attack()

func ground_slam():
	# Мощный удар по земле с AoE уроном
	if not target:
		return
	
	is_charging = true
	charge_timer = 1.5 # Долгая подготовка
	
	# Визуал подготовки
	start_charging_visuals()
	
	await get_tree().create_timer(charge_timer).timeout
	is_charging = false
	
	# Создание ударной волны
	create_ground_slam_effect()
	
	# Проверка попадания по площади
	var hit_range = 6.0
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.global_position.distance_to(global_position) <= hit_range:
			player.take_damage(ground_slam_damage, (player.global_position - global_position).normalized(), 30.0)

func crystal_spike_eruption():
	# Призыв кристаллических шипов вокруг себя
	create_crystal_spikes()
	
	# Задержка перед уроном
	await get_tree().create_timer(0.8).timeout
	
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.global_position.distance_to(global_position) <= 5.0:
			player.take_damage(crystal_spike_damage, Vector3.UP * 10.0, 20.0)
	
	remove_crystal_spikes()

func charge_attack():
	# Медленная но мощная атака рывком
	if not target:
		return
	
	is_charging = true
	charge_timer = 2.0 # Очень долгая подготовка
	
	# Визуал
	start_charging_visuals()
	
	await get_tree().create_timer(charge_timer).timeout
	is_charging = false
	
	# Рывок вперёд
	var direction = (target.global_position - global_position).normalized()
	var charge_distance = 10.0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", global_position + direction * charge_distance, 0.5)
	
	# Урон всем на пути
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var dist = player.global_position.distance_to(global_position)
		if dist <= 3.0:
			player.take_damage(damage * 1.5, direction, 40.0)

func defensive_crystal_burst():
	# В режиме защиты: взрыв кристаллических осколков
	if not crystal_shards_active:
		crystal_shards_active = true
		create_crystal_shield()
		
		await get_tree().create_timer(2.0).timeout
		
		# Взрыв
		explode_crystal_shards()
		crystal_shards_active = false

func create_crystal_spikes():
	# Визуальное создание шипов вокруг
	if spike_particles:
		spike_particles.emitting = true
		spike_particles.one_shot = true

func remove_crystal_spikes():
	if spike_particles:
		spike_particles.emitting = false

func create_ground_slam_effect():
	# Создание визуального эффекта удара по земле
	var effect_ring = MeshInstance3D.new()
	effect_ring.mesh = CylinderMesh.new()
	effect_ring.mesh.height = 0.2
	effect_ring.mesh.top_radius = 0.5
	effect_ring.mesh.bottom_radius = 0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 3.0
	effect_ring.material_override = mat
	
	get_parent().add_child(effect_ring)
	effect_ring.global_position = global_position
	effect_ring.rotation.x = PI / 2.0
	
	# Анимация расширения
	var tween = get_tree().create_tween()
	tween.tween_property(effect_ring.scale, "x", 10.0, 0.5)
	tween.tween_property(effect_ring.scale, "y", 10.0, 0.5)
	tween.tween_callback(func(): effect_ring.queue_free())

func create_crystal_shield():
	# Создание защитного барьера из кристаллов
	pass

func explode_crystal_shards():
	# Взрыв осколков во все стороны
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var dist = player.global_position.distance_to(global_position)
		if dist <= 8.0:
			player.take_damage(crystal_spike_damage * 0.8, (player.global_position - global_position).normalized(), 25.0)

func start_charging_visuals():
	# Усиление свечения во время зарядки
	if glow_mesh and glow_mesh.material_override is StandardMaterial3D:
		var mat = glow_mesh.material_override as StandardMaterial3D
		var tween = get_tree().create_tween()
		tween.tween_property(mat, "emission_energy_multiplier", 5.0, charge_timer)

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO, knockback_force: float = 0.0):
	# Проверка перехода в режим защиты
	if health > max_health * defense_mode_threshold and health - amount <= max_health * defense_mode_threshold:
		enter_defense_mode()
	
	# Снижение урона в режиме защиты
	if is_in_defense_mode:
		amount *= 0.6 # 40% снижение урона
	
	super.take_damage(amount, knockback_dir, knockback_force)

func enter_defense_mode():
	is_in_defense_mode = true
	# Изменение цвета на более агрессивный
	if glow_mesh and glow_mesh.material_override is StandardMaterial3D:
		var mat = glow_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(1.0, 0.0, 0.0) # Красный
		mat.emission = Color(1.0, 0.0, 0.0)
	
	# Визуальный эффект трансформации
	create_defense_mode_effect()

func create_defense_mode_effect():
	# Эффект перехода в режим защиты
	pass

func update_visuals():
	super.update_visuals()
	
	# Пульсация свечения в зависимости от здоровья
	if glow_mesh and glow_mesh.material_override is StandardMaterial3D:
		var mat = glow_mesh.material_override as StandardMaterial3D
		var pulse = sin(Time.get_ticks_msec() / 200.0) * 0.3 + 0.7
		mat.emission_energy_multiplier = pulse * (1.0 + health / max_health)
