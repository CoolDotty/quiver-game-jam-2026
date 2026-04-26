class_name GameOverScreen
extends CanvasLayer
## Fades the black screen away to reveal the game-over sketch.

const FADE_IN_DURATION := 1.1

@onready var blackout: ColorRect = $Blackout
@onready var sketch: Sprite2D = $BadEndingSketch
@onready var message_label: Label = $Root/CenterContainer/MessageLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if blackout != null:
		blackout.color = Color(0.0, 0.0, 0.0, 1.0)

	if message_label != null:
		message_label.text = "you lose"

	_fit_sketch_to_viewport()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		blackout,
		"color",
		Color(0.0, 0.0, 0.0, 0.0),
		FADE_IN_DURATION
	)


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
