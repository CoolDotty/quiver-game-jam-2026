class_name Starter3D
extends Node3D
## Owns the gameplay-to-win transition for the starter scene.

const YOU_WIN_SCENE_PATH := "res://scenes/you_win.tscn"
const STARTUP_FADE_DURATION := 0.5
const FADE_OUT_DURATION := 0.5

@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var _is_transitioning: bool = false


func _ready() -> void:
	if not Global.you_win_requested.is_connected(_on_you_win_requested):
		Global.you_win_requested.connect(_on_you_win_requested)

	if fade_rect != null:
		fade_rect.color = Color.WHITE
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		await _fade_from_white()


func _on_you_win_requested() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	await _fade_to_black()
	_switch_to_you_win_scene()


func _fade_from_white() -> void:
	if fade_rect == null:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		fade_rect,
		"color",
		Color(1.0, 1.0, 1.0, 0.0),
		STARTUP_FADE_DURATION
	)
	await tween.finished


func _fade_to_black() -> void:
	if fade_rect == null:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color", Color.BLACK, FADE_OUT_DURATION)
	await tween.finished


func _switch_to_you_win_scene() -> void:
	var change_error := get_tree().change_scene_to_file(YOU_WIN_SCENE_PATH)
	if change_error != OK:
		push_error("Failed to change to the You Win scene.")
