extends RigidBody3D


@export var item: ItemData
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var sprite_3d: Sprite3D = $Sprite3D

var _default_collision_layer: int
var _default_collision_mask: int
var _default_gravity_scale: float
var _default_can_sleep: bool


func _ready() -> void:
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	_default_gravity_scale = gravity_scale
	_default_can_sleep = can_sleep

	if item != null and item.sprite_texture != null:
		sprite_3d.texture = item.sprite_texture

	var material := sprite_3d.material_override as ShaderMaterial
	if material != null and item != null and item.sprite_texture != null:
		material = material.duplicate() as ShaderMaterial
		sprite_3d.material_override = material
		material.set_shader_parameter("billboard_texture", item.sprite_texture)


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


func set_sprite_offset(offset: Vector2) -> void:
	sprite_3d.offset = offset
