class_name SegmentShadowSprite
extends Sprite3D


func _ready() -> void:
	global_position.y = 0.0


func _process(_delta: float) -> void:
	var shadow_position = get_parent().global_position
	shadow_position.y = 0.0
	global_position = shadow_position
