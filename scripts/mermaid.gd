class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 18.0
const BEND_THRESHOLD = 0.15

enum Facing {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

enum BendState {
	STRAIGHT,
	BENT,
}


@onready var head: RigidBody3D = $Head
@onready var tail: RigidBody3D = $Tail
@onready var hinge_joint_3d: HingeJoint3D = $HingeJoint3D
@onready var rigid_body_3d_2: RigidBody3D = $RigidBody3D2
@onready var rigid_body_3d_3: RigidBody3D = $RigidBody3D3
@onready var rigid_body_3d_4: RigidBody3D = $RigidBody3D4
@onready var mermaid_sprites: AnimatedSprite3D = $RigidBody3D3/MermaidSprites


func _ready() -> void:
	set_process_unhandled_input(true)


func _process(_delta: float) -> void:
	_update_animation()


func _physics_process(_delta: float) -> void:
	# Continuous smooth rotation (steering)
	var body_axis := get_body_axis()
	var perpendicular_dir = body_axis.cross(Vector3.UP).normalized()

	if Input.is_action_pressed("roll_right"):
		# Apply a continuous force to steer the head in a smooth arc
		head.apply_central_force(perpendicular_dir * TAIL_LIFT_FORCE * 2.50)
	if Input.is_action_pressed("roll_left"):
		head.apply_central_force(-perpendicular_dir * TAIL_LIFT_FORCE * 2.50)


func _unhandled_input(_event: InputEvent) -> void:
	# var d = hinge_joint_3d.get_contact_local_normal(0)

	var body_axis := get_body_axis()

	if Input.is_action_just_pressed("flop_down"):
		# To fix the "no movement on ground" issue:
		# Slam the tail DOWN and BACKWARDS (opposite of facing dir).
		# This creates a "kick" effect even if the tail is already touching the floor.
		var slam_dir = (Vector3.DOWN * 0.7 + -body_axis * 0.3).normalized()
		tail.apply_central_impulse(slam_dir * TAIL_LIFT_FORCE)

		# Propel the head forward relative to its current facing direction
		head.apply_central_impulse(body_axis * TAIL_LIFT_FORCE * 1.5)
	if Input.is_action_just_pressed("flop_up"):
		head.apply_central_impulse(Vector3.UP * TAIL_LIFT_FORCE * 0.5)
		tail.apply_central_impulse(Vector3.UP * TAIL_LIFT_FORCE * 0.5)


func get_body_axis() -> Vector3:
	var chain_points := get_chain_points()
	var axis := Vector3.ZERO

	for i in range(chain_points.size() - 1):
		axis += (chain_points[i + 1] - chain_points[i]).normalized()

	if axis == Vector3.ZERO:
		return Vector3.RIGHT

	return axis.normalized()


func get_chain_points() -> Array[Vector3]:
	return [
		head.global_position,
		rigid_body_3d_2.global_position,
		rigid_body_3d_3.global_position,
		rigid_body_3d_4.global_position,
		tail.global_position,
	]


func get_body_facing() -> Facing:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Facing.RIGHT

	var view_axis := camera.global_transform.basis.inverse() * get_body_axis()
	var screen_axis := Vector2(view_axis.x, -view_axis.y)

	if abs(screen_axis.x) > abs(screen_axis.y):
		return Facing.RIGHT if screen_axis.x > 0.0 else Facing.LEFT

	return Facing.DOWN if screen_axis.y > 0.0 else Facing.UP


func get_bend_state() -> BendState:
	var chain_points := get_chain_points()
	var body_axis := get_body_axis()
	var bend_score := 0.0

	for i in range(chain_points.size() - 1):
		var segment_axis := (chain_points[i + 1] - chain_points[i]).normalized()
		bend_score += 1.0 - abs(segment_axis.dot(body_axis))

	bend_score /= float(chain_points.size() - 1)

	return BendState.BENT if bend_score > BEND_THRESHOLD else BendState.STRAIGHT


func _update_animation() -> void:
	var animation_prefix := "fish_flat"

	if get_bend_state() == BendState.BENT:
		animation_prefix = "fish_flop"

	var animation_name := "%s_%s" % [
		animation_prefix,
		_facing_to_suffix(get_body_facing()),
	]

	if mermaid_sprites.animation != animation_name:
		mermaid_sprites.animation = animation_name


func _facing_to_suffix(facing: Facing) -> String:
	match facing:
		Facing.UP:
			return "down"
		Facing.DOWN:
			return "up"
		Facing.LEFT:
			return "right"
		Facing.RIGHT:
			return "left"

	return "right"
