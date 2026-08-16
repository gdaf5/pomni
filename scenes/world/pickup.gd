extends Area3D
class_name Pickup

@export var item_id: String = "coin"
@export var count: int = 1

@onready var mesh_pivot: Node3D = $MeshPivot
@onready var label: Label3D = $Label

var _spin_speed: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_label()

func _physics_process(delta: float) -> void:
	mesh_pivot.rotate_y(_spin_speed * delta)
	mesh_pivot.position.y = 0.6 + sin(Time.get_ticks_msec() * 0.004) * 0.15

func setup(p_item_id: String, p_count: int) -> void:
	item_id = p_item_id
	count = p_count
	_update_label()

func _update_label() -> void:
	var def := ItemDefinition.get_item(item_id)
	if def:
		label.text = def.icon + " " + def.display_name + " x" + str(count)
	else:
		label.text = item_id + " x" + str(count)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		GameManager.add_item(item_id, count)
		_pickup_toast()
		queue_free()

func _pickup_toast() -> void:
	var def := ItemDefinition.get_item(item_id)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		var name_text: String = def.display_name if def else item_id
		hud.show_toast("Подобрано: " + def.icon + " " + name_text + " x" + str(count))