extends Control

@onready var custom_btn: Button = $HBox/CustomCard/VBox/CustomButton
@onready var skeleton_btn: Button = $HBox/SkeletonCard/VBox/SkeletonButton
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	custom_btn.pressed.connect(_on_custom_button_pressed)
	skeleton_btn.pressed.connect(_on_skeleton_button_pressed)
	back_btn.pressed.connect(_on_back_button_pressed)

func _on_custom_button_pressed() -> void:
	GameManager.selected_character = GameManager.CharacterType.CUSTOM
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _on_skeleton_button_pressed() -> void:
	GameManager.selected_character = GameManager.CharacterType.SKELETON
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
