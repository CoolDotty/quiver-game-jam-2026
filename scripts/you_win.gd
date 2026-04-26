class_name YouWinScreen
extends Control
## Fades the black screen away to reveal the win message.

const BLACKOUT_FADE_OUT_DURATION := 1.0

@onready var blackout_rect: ColorRect = $Blackout


func _ready() -> void:
	if blackout_rect == null:
		return

	blackout_rect.color = Color(0.0, 0.0, 0.0, 1.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(blackout_rect, "color", Color(0.0, 0.0, 0.0, 0.0), BLACKOUT_FADE_OUT_DURATION)
