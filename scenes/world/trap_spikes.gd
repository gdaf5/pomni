extends Area3D
class_name SpikeTrap

@export var damage: float = 15.0
@export var knockback: float = 10.0
@export var cooldown: float = 1.5

var _last_hit_time: float = -100.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_try_hit_player(body)

func _physics_process(_delta: float) -> void:
	var overlapping = get_overlapping_bodies()
	for body in overlapping:
		if body is Player:
			_try_hit_player(body)

func _try_hit_player(player: Player) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_hit_time < cooldown:
		return
	_last_hit_time = now
	if player.has_method("take_damage"):
		player.take_damage(damage, true, global_position)