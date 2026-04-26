class_name YouWinScreen
extends Control
## Fades the black screen away to reveal the win message.

const BLACKOUT_FADE_OUT_DURATION := 1.0

@onready var blackout_rect: ColorRect = $Blackout
@onready var sketch: Sprite2D = $GoodtimeSketch


func _ready() -> void:
	if blackout_rect == null:
		return

	blackout_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_fit_sketch_to_viewport()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(blackout_rect, "color", Color(0.0, 0.0, 0.0, 0.0), BLACKOUT_FADE_OUT_DURATION)


func _fit_sketch_to_viewport() -> void:
	if sketch == null or sketch.texture == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var texture_size := sketch.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	sketch.centered = true
	sketch.position = viewport_size * 0.5
	var scale_factor := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	sketch.scale = Vector2.ONE * scale_factor
