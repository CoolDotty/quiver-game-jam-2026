class_name SegmentShadowSprite
extends Sprite3D

const MAX_SHADOW_HEIGHT: float = 6.0
const MIN_SHADOW_SCALE: float = 0.35

var _base_scale: Vector3

func _ready() -> void:
	_base_scale = scale
	_update_shadow_transform()


func _process(_delta: float) -> void:
	_update_shadow_transform()


func _update_shadow_transform() -> void:
	var parent_3d: Node3D = get_parent_node_3d()
	if parent_3d == null:
		return

	var shadow_position := parent_3d.global_position
	shadow_position.y = 0.0
	global_position = shadow_position

	var height: float = maxf(parent_3d.global_position.y, 0.0)
	var height_ratio: float = clampf(height / MAX_SHADOW_HEIGHT, 0.0, 1.0)
	var shadow_scale: float = lerpf(1.0, MIN_SHADOW_SCALE, height_ratio)
	scale = _base_scale * shadow_scale
