extends CharacterBody3D

const NECK_SPIN_RESPONSE = 8.0
const NECK_SPIN_DAMPING = 6.0
const MAX_SPIN_SPEED = 12.0
const MIN_SCREEN_OFFSET_SQUARED = 0.0001

var _spin_velocity_z: float = 0.0
var _last_screen_offset := Vector2.ZERO
var _has_last_screen_offset: bool = false

@onready var mermaid_root: Node3D = get_parent_node_3d()
@onready var neck: RigidBody3D = $"../RigidBody3D2"


func _ready() -> void:
	set_physics_process(true)
	_sync_screen_offset()


func _physics_process(delta: float) -> void:
	global_position = neck.global_position
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_apply_z_only_rotation(delta)
		return

	var screen_offset := _get_screen_offset(camera)
	if screen_offset.length_squared() < MIN_SCREEN_OFFSET_SQUARED:
		_apply_z_only_rotation(delta)
		return

	if not _has_last_screen_offset:
		_last_screen_offset = screen_offset
		_has_last_screen_offset = true
		_apply_z_only_rotation(delta)
		return

	var spin_delta := _last_screen_offset.angle_to(screen_offset)
	_last_screen_offset = screen_offset

	_spin_velocity_z += spin_delta * NECK_SPIN_RESPONSE
	_spin_velocity_z = move_toward(
		_spin_velocity_z,
		0.0,
		NECK_SPIN_DAMPING * delta,
	)
	_spin_velocity_z = clampf(_spin_velocity_z, -MAX_SPIN_SPEED, MAX_SPIN_SPEED)

	rotation = Vector3(
		0.0,
		0.0,
		wrapf(rotation.z + _spin_velocity_z * delta, -PI, PI),
	)


func _sync_screen_offset() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var screen_offset := _get_screen_offset(camera)
	if screen_offset.length_squared() < MIN_SCREEN_OFFSET_SQUARED:
		return

	_last_screen_offset = screen_offset
	_has_last_screen_offset = true


func _get_screen_offset(camera: Camera3D) -> Vector2:
	var neck_screen_position := camera.unproject_position(neck.global_position)
	var root_screen_position := camera.unproject_position(mermaid_root.global_position)
	return neck_screen_position - root_screen_position


func _apply_z_only_rotation(delta: float) -> void:
	_spin_velocity_z = move_toward(
		_spin_velocity_z,
		0.0,
		NECK_SPIN_DAMPING * delta,
	)
	rotation = Vector3(
		0.0,
		0.0,
		wrapf(rotation.z + _spin_velocity_z * delta, -PI, PI),
	)
