class_name MermaidMovementController
extends Node
## Handles mermaid impulse movement, cooldowns, and grounded state.

const DEFAULT_MAX_CONTACTS_REPORTED := 8

@export_range(0.0, 50.0, 0.1) var spin_impulse: float = 6.0
@export_range(0.0, 50.0, 0.1) var spin_torque: float = 2.75
@export_range(0.0, 50.0, 0.1) var upward_impulse: float = 4.33
@export_range(0.0, 50.0, 0.1) var forward_impulse: float = 11.0
@export_range(0.0, 5.0, 0.01) var spin_cooldown: float = 0.5
@export_range(0.0, 5.0, 0.01) var upward_cooldown: float = 0.5
@export_range(0.0, 5.0, 0.01) var forward_cooldown: float = 0.5
@export_range(0.0, 2.0, 0.01) var grounded_forward_multiplier: float = 0.55
@export_range(0.0, 4.0, 0.01) var air_forward_multiplier: float = 1.25
@export_range(0.0, 2.0, 0.01) var grounded_forward_lift: float = 0.2
@export_range(0.0, 2.0, 0.01) var air_forward_lift: float = 0.08
@export_range(0.0, 2.0, 0.01) var spin_vertical_nudge: float = 0.5
@export_range(0.0, 2.0, 0.01) var upward_tumble_nudge: float = 0.35
@export_range(0.0, 2.0, 0.01) var forward_torque_strength: float = 3.0
@export_range(0.0, 2.0, 0.01) var input_jitter: float = 0.12
@export_range(0.0, 10.0, 0.01) var vertical_force_multiplier: float = 2.0
@export_range(0.0, 10.0, 0.01) var gravity_multiplier: float = 2.0
@export_range(0.0, 100.0, 0.1) var velocity_cap: float = 18.0

var _chain_bodies: Array[RigidBody3D] = []
var _default_gravity_scales: Array[float] = []
var _spin_cooldown_remaining: float = 0.0
var _upward_cooldown_remaining: float = 0.0
var _forward_cooldown_remaining: float = 0.0
var _is_grounded: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_physics_process(true)


func configure(chain_bodies: Array[RigidBody3D]) -> void:
	_chain_bodies.clear()
	_default_gravity_scales.clear()

	for body in chain_bodies:
		if body == null or not is_instance_valid(body):
			continue

		_chain_bodies.append(body)
		_default_gravity_scales.append(body.gravity_scale)
		body.contact_monitor = true
		body.max_contacts_reported = maxi(
			body.max_contacts_reported,
			DEFAULT_MAX_CONTACTS_REPORTED
		)

	_apply_gravity_multiplier()
	_refresh_grounded_state()


func spin_left() -> void:
	_apply_spin(-1.0)


func spin_right() -> void:
	_apply_spin(1.0)


func burst_up() -> void:
	if _upward_cooldown_remaining > 0.0:
		return

	_upward_cooldown_remaining = upward_cooldown
	var forward_axis := get_body_axis()
	var side_axis := _get_side_axis(forward_axis)
	var center_index := _get_center_index()

	for index in range(_chain_bodies.size()):
		var body := _chain_bodies[index]
		if not _is_valid_body(body):
			continue

		var segment_weight := _get_segment_weight(index, center_index)
		var segment_sign := _get_segment_sign(index, center_index)
		var impulse := Vector3.UP * upward_impulse * vertical_force_multiplier * segment_weight
		impulse += (
			forward_axis
			* upward_impulse
			* vertical_force_multiplier
			* 0.07
			* segment_sign
		)
		impulse += (
			side_axis
			* upward_impulse
			* vertical_force_multiplier
			* input_jitter
			* _rng.randf_range(-1.0, 1.0)
		)

		body.apply_central_impulse(impulse)
		body.apply_torque_impulse(side_axis * upward_tumble_nudge * segment_sign)

	_clamp_chain_velocity()


func burst_forward() -> void:
	if _forward_cooldown_remaining > 0.0:
		return

	_forward_cooldown_remaining = forward_cooldown
	var forward_axis := get_body_axis()
	var side_axis := _get_side_axis(forward_axis)
	var center_index := _get_center_index()
	var horizontal_multiplier := (
		grounded_forward_multiplier if _is_grounded else air_forward_multiplier
	)
	var lift_amount := grounded_forward_lift if _is_grounded else air_forward_lift

	for index in range(_chain_bodies.size()):
		var body := _chain_bodies[index]
		if not _is_valid_body(body):
			continue

		var segment_weight := _get_segment_weight(index, center_index)
		var segment_sign := _get_segment_sign(index, center_index)
		var impulse := forward_axis * forward_impulse * horizontal_multiplier * segment_weight
		impulse += (
			Vector3.UP
			* forward_impulse
			* vertical_force_multiplier
			* lift_amount
			* segment_weight
		)
		impulse += side_axis * forward_impulse * input_jitter * segment_sign

		body.apply_central_impulse(impulse)
		body.apply_torque_impulse(side_axis * forward_torque_strength * segment_sign)

	_clamp_chain_velocity()


func is_grounded() -> bool:
	return _is_grounded


func _physics_process(delta: float) -> void:
	if _spin_cooldown_remaining > 0.0:
		_spin_cooldown_remaining = maxf(_spin_cooldown_remaining - delta, 0.0)

	if _upward_cooldown_remaining > 0.0:
		_upward_cooldown_remaining = maxf(_upward_cooldown_remaining - delta, 0.0)

	if _forward_cooldown_remaining > 0.0:
		_forward_cooldown_remaining = maxf(_forward_cooldown_remaining - delta, 0.0)

	_refresh_grounded_state()
	_clamp_chain_velocity()


func get_body_axis() -> Vector3:
	if _chain_bodies.size() < 2:
		return Vector3.RIGHT

	var axis := Vector3.ZERO

	for index in range(_chain_bodies.size() - 1):
		var current_body := _chain_bodies[index]
		var next_body := _chain_bodies[index + 1]
		if current_body == null or next_body == null:
			continue

		if not is_instance_valid(current_body) or not is_instance_valid(next_body):
			continue

		axis += (current_body.global_position - next_body.global_position).normalized()

	if axis == Vector3.ZERO:
		return Vector3.RIGHT

	return axis.normalized()


func _apply_spin(direction: float) -> void:
	if _spin_cooldown_remaining > 0.0:
		return

	_spin_cooldown_remaining = spin_cooldown
	var forward_axis := get_body_axis()
	var side_axis := _get_side_axis(forward_axis)
	var center_index := _get_center_index()

	for index in range(_chain_bodies.size()):
		var body := _chain_bodies[index]
		if not _is_valid_body(body):
			continue

		var segment_weight := _get_segment_weight(index, center_index)
		var segment_sign := _get_segment_sign(index, center_index)
		var impulse_sign := direction * segment_sign
		var impulse := side_axis * spin_impulse * segment_weight * impulse_sign
		impulse += (
			Vector3.UP
			* spin_vertical_nudge
			* vertical_force_multiplier
			* segment_weight
			* _rng.randf_range(-1.0, 1.0)
		)

		body.apply_central_impulse(impulse)
		body.apply_torque_impulse(Vector3.UP * spin_torque * impulse_sign)

	_clamp_chain_velocity()


func _refresh_grounded_state() -> void:
	_is_grounded = false

	for body in _chain_bodies:
		if not _is_valid_body(body):
			continue

		for collider in body.get_colliding_bodies():
			if collider is StaticBody3D or collider is AnimatableBody3D:
				_is_grounded = true
				return


func _clamp_chain_velocity() -> void:
	if velocity_cap <= 0.0:
		return

	for body in _chain_bodies:
		if not _is_valid_body(body):
			continue

		if body.linear_velocity.length() > velocity_cap:
			body.linear_velocity = body.linear_velocity.normalized() * velocity_cap

		if body.angular_velocity.length() > velocity_cap:
			body.angular_velocity = body.angular_velocity.normalized() * velocity_cap


func _apply_gravity_multiplier() -> void:
	for index in range(_chain_bodies.size()):
		var body := _chain_bodies[index]
		if not _is_valid_body(body):
			continue

		var base_gravity_scale := _default_gravity_scales[index]
		body.gravity_scale = base_gravity_scale * gravity_multiplier


func _is_valid_body(body: RigidBody3D) -> bool:
	return body != null and is_instance_valid(body)


func _get_side_axis(forward_axis: Vector3) -> Vector3:
	var side_axis := forward_axis.cross(Vector3.UP)
	if side_axis.length_squared() < 0.0001:
		return Vector3.RIGHT

	return side_axis.normalized()


func _get_center_index() -> float:
	if _chain_bodies.is_empty():
		return 0.0

	return float(_chain_bodies.size() - 1) * 0.5


func _get_segment_sign(index: int, center_index: float) -> float:
	var segment_sign: float = sign(float(index) - center_index)
	if segment_sign != 0.0:
		return segment_sign

	return _rng.randf_range(-0.25, 0.25)


func _get_segment_weight(index: int, center_index: float) -> float:
	if center_index <= 0.0:
		return 1.0

	var distance_ratio := absf(float(index) - center_index) / center_index
	return 1.0 - distance_ratio * 0.25
