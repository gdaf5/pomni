extends PanelContainer
class_name InventoryUI

signal closed

var player: Player = null

@onready var slot_container: GridContainer = $Margin/Contents/Body/SlotsWrap/Slots
@onready var detail_name: Label = $Margin/Contents/Body/Detail/DetailPanel/DetailVBox/Name
@onready var detail_desc: Label = $Margin/Contents/Body/Detail/DetailPanel/DetailVBox/Desc
@onready var detail_hint: Label = $Margin/Contents/Body/Detail/DetailPanel/DetailVBox/Hint

var _slot_buttons: Array = []
var _selected_id: String = ""

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameManager.inventory_changed.connect(_refresh)
	_refresh()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_hide_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		_hide_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if _selected_id != "":
				_use_selected()
				get_viewport().set_input_as_handled()

func toggle(player_ref: Player) -> void:
	player = player_ref
	visible = not visible
	if visible:
		_set_mouse(true)
		_refresh()
	else:
		_set_mouse(false)
		closed.emit()

func _hide_panel() -> void:
	visible = false
	_set_mouse(false)
	closed.emit()

func _set_mouse(captured: bool) -> void:
	if captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _refresh() -> void:
	for b in _slot_buttons:
		if is_instance_valid(b):
			b.queue_free()
	_slot_buttons.clear()

	var entries := GameManager.get_inventory_entries()
	var defs := ItemDefinition.catalog()
	# Показываем и пустые предметы каталога, чтобы сетка была наглядной
	var shown_ids: Array = []
	for e in entries:
		shown_ids.append(e["id"])
	for id in defs:
		if not shown_ids.has(id):
			shown_ids.append(id)

	for item_id in shown_ids:
		var count := GameManager.get_item_count(item_id)
		var def := ItemDefinition.get_item(item_id)
		if def == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(96, 96)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var text := def.icon + "\n"
		if count > 0:
			text += def.display_name + "\nx" + str(count)
		else:
			text += def.display_name + "\n—"
		btn.text = text
		btn.tooltip_text = def.display_name
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_slot_pressed.bind(item_id))
		slot_container.add_child(btn)
		_slot_buttons.append(btn)
		if count > 0:
			btn.disabled = false
		else:
			btn.disabled = true

	_update_detail(_selected_id)

func _on_slot_pressed(item_id: String) -> void:
	if GameManager.get_item_count(item_id) <= 0:
		return
	_selected_id = item_id
	_update_detail(item_id)

func _update_detail(item_id: String) -> void:
	if item_id == "":
		detail_name.text = "—"
		detail_desc.text = "Выберите предмет."
		detail_hint.text = ""
		return
	var def := ItemDefinition.get_item(item_id)
	var count := GameManager.get_item_count(item_id)
	detail_name.text = def.icon + " " + def.display_name + "  (x" + str(count) + ")"
	detail_desc.text = def.description
	detail_hint.text = "ENTER / E — использовать"
	if count <= 0:
		detail_hint.text = "Нет в наличии"

func _use_selected() -> void:
	if not player or not is_instance_valid(player):
		return
	if GameManager.use_item(_selected_id, player):
		_refresh()