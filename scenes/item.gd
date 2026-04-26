extends RigidBody3D

const SHADOW_MODULATE := Color(0, 0, 0, 0.55)
const SHADOW_SCALE_MULTIPLIER := 1.2


@export var item_name: String = ""
@export var sprite_texture: Texture2D
@export var cooks_into: PackedScene
@export var burns_into: PackedScene
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var shadow_sprite_3d: Sprite3D = get_node_or_null("Sprite3D_Shadow") as Sprite3D

var _default_collision_layer: int
var _default_collision_mask: int
var _default_gravity_scale: float
var _default_can_sleep: bool


func _ready() -> void:
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	_default_gravity_scale = gravity_scale
	_default_can_sleep = can_sleep

	var material := sprite_3d.material_override as ShaderMaterial
	if material != null:
		sprite_3d.material_override = material.duplicate()

	_apply_sprite_texture()
	_configure_shadow_sprite()


func set_held(is_held: bool) -> void:
	if is_held:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		gravity_scale = 0.0
		can_sleep = true
		sleeping = true
		collision_layer = 0
		collision_mask = 0
		collision_shape_3d.disabled = true
		return

	gravity_scale = _default_gravity_scale
	can_sleep = _default_can_sleep
	collision_layer = _default_collision_layer
	collision_mask = _default_collision_mask
	collision_shape_3d.disabled = false
	sleeping = false
	sprite_3d.position = Vector3.ZERO


func get_item_name() -> String:
	return item_name if not item_name.is_empty() else "Unknown Item"


func set_item_name(value: String) -> void:
	item_name = value


func get_sprite_texture() -> Texture2D:
	return sprite_texture


func set_sprite_texture(value: Texture2D) -> void:
	sprite_texture = value
	_apply_sprite_texture()


func get_cooks_into() -> PackedScene:
	return cooks_into


func set_cooks_into(value: PackedScene) -> void:
	cooks_into = value


func get_burns_into() -> PackedScene:
	return burns_into


func set_burns_into(value: PackedScene) -> void:
	burns_into = value


func set_sprite_offset(_offset: Vector2) -> void:
	sprite_3d.position = Vector3(_offset.x * 0.001, 0.0, 0.0)


func _apply_sprite_texture() -> void:
	if sprite_3d == null:
		return

	sprite_3d.texture = sprite_texture
	if shadow_sprite_3d != null:
		shadow_sprite_3d.texture = sprite_texture

	var material := sprite_3d.material_override as ShaderMaterial
	if material != null and sprite_texture != null:
		material.set_shader_parameter("billboard_texture", sprite_texture)


func _configure_shadow_sprite() -> void:
	if shadow_sprite_3d == null:
		return

	shadow_sprite_3d.modulate = SHADOW_MODULATE
	shadow_sprite_3d.scale = sprite_3d.scale * SHADOW_SCALE_MULTIPLIER
