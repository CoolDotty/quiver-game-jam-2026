class_name GameOverScreen
extends CanvasLayer
## Displays the game-over screen after the loss transition.

const FADE_IN_DURATION := 1.1

@onready var blackout: ColorRect = $Root/Blackout
@onready var message_label: Label = $Root/CenterContainer/MessageLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if blackout != null:
		blackout.color = Color(0.0, 0.0, 0.0, 1.0)

	if message_label != null:
		message_label.text = "you lose"

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
