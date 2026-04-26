class_name SegmentShadowSprite
extends Sprite3D

const MAX_SHADOW_HEIGHT: float = 6.0
const MIN_SHADOW_SCALE: float = 0.35
const SHADOW_GROUND_OFFSET: float = 0.03
const SHADOW_BLUR_AMOUNT: float = 8.0
const BILLBOARD_SHADER: Shader = preload("res://resources/billboard.gdshader")

var _base_scale: Vector3
var _shadow_material: ShaderMaterial

func _ready() -> void:
	_ensure_shadow_material()
	_base_scale = scale
	_update_shadow_transform()


func _process(_delta: float) -> void:
	_update_shadow_transform()


func _update_shadow_transform() -> void:
	var parent_3d: Node3D = get_parent_node_3d()
	if parent_3d == null:
		return

	var shadow_position := parent_3d.global_position
	shadow_position.y = SHADOW_GROUND_OFFSET
	global_position = shadow_position

	var height: float = maxf(parent_3d.global_position.y, 0.0)
	var height_ratio: float = clampf(height / MAX_SHADOW_HEIGHT, 0.0, 1.0)
	var shadow_scale: float = lerpf(1.0, MIN_SHADOW_SCALE, height_ratio)
	scale = _base_scale * shadow_scale


func set_shadow_texture(value: Texture2D) -> void:
	texture = value
	_sync_shadow_material()


func _ensure_shadow_material() -> void:
	_shadow_material = material_override as ShaderMaterial
	if _shadow_material == null:
		_shadow_material = ShaderMaterial.new()
		_shadow_material.shader = BILLBOARD_SHADER
		material_override = _shadow_material

	_sync_shadow_material()


func _sync_shadow_material() -> void:
	if _shadow_material == null:
		return

	_shadow_material.set_shader_parameter("billboard_texture", texture)
	_shadow_material.set_shader_parameter(
		"blur_amount",
		SHADOW_BLUR_AMOUNT if texture != null else 0.0,
	)
