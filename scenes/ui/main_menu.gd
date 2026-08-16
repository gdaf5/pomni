extends Control

@onready var start_btn: Button = $VBoxContainer/StartButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	start_btn.pressed.connect(_on_start_button_pressed)
	settings_btn.pressed.connect(_on_settings_button_pressed)
	quit_btn.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_settings_button_pressed() -> void:
	pass

func _on_quit_button_pressed() -> void:
	get_tree().quit()
