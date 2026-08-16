extends Area3D
class_name TreasureChest

@export var opened: bool = false
@export var loot_items: Array[Dictionary] = [
	{ "id": "potion", "count": 2 },
	{ "id": "coin", "count": 50 },
]

var _player_in_range: Node3D = null

@onready var lid: Node3D = $Lid
@onready var glow_light: OmniLight3D = $OpenLight

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_player_in_range = body

func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null

func _physics_process(delta: float) -> void:
	if opened:
		return
	if _player_in_range and _player_in_range is Player:
		_give_loot()
		_open()

func _give_loot() -> void:
	for loot in loot_items:
		var item_id: String = loot.get("id", "")
		var count: int = int(loot.get("count", 1))
		if item_id == "":
			continue
		GameManager.add_item(item_id, count)
		_toast("Получено: " + item_id + " x" + str(count))

func _toast(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(text)

func _open() -> void:
	opened = true
	if lid:
		var tween = create_tween()
		tween.tween_property(lid, "rotation:x", -1.2, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if glow_light:
		glow_light.visible = true
		var ltween = create_tween()
		ltween.tween_property(glow_light, "light_energy", 0.0, 1.2)