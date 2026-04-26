class_name MainMenu
extends Node3D
## Handles the main menu background and the white transition into gameplay.

const GAMEPLAY_SCENE_PATH := "res://scenes/starter_3d.tscn"
const MENU_FADE_DURATION := 0.5

@onready var start_button: TextureButton = $Ui/Root/StartButton
@onready var fade_rect: ColorRect = $Ui/FadeRect

var _is_transitioning: bool = false


func _ready() -> void:
	if start_button != null and not start_button.pressed.is_connected(
			_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	if fade_rect != null:
		fade_rect.color = Color(1.0, 1.0, 1.0, 0.0)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_start_button_pressed() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	if start_button != null:
		start_button.disabled = true

	await _fade_to_white()
	_switch_to_gameplay_scene()


func _fade_to_white() -> void:
	if fade_rect == null:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color", Color.WHITE, MENU_FADE_DURATION)
	await tween.finished


func _switch_to_gameplay_scene() -> void:
	var change_error := get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)
	if change_error != OK:
		push_error("Failed to change to the starter 3D scene.")
