class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 12
const FLOP_COOLDOWN = 0.5

enum Facing {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}


@onready var head: RigidBody3D = $Head
@onready var tail: RigidBody3D = $Tail
@onready var hinge_joint_3d: HingeJoint3D = $HingeJoint3D
@onready var rigid_body_3d_2: RigidBody3D = $RigidBody3D2
@onready var rigid_body_3d_3: RigidBody3D = $RigidBody3D3
@onready var rigid_body_3d_4: RigidBody3D = $RigidBody3D4
@onready var grab_range_right: Area3D = $Arm2/GrabRange

@onready var holding_right: Marker3D = $Arm2/Holding/HandAnchor

var _up_timer: float = 0.0
var _down_timer: float = 0.0


func _ready() -> void:
	set_process_unhandled_input(true)

	grab_range_right.body_entered.connect(_on_grab_range_right_body_entered)


func _physics_process(_delta: float) -> void:
	if _up_timer > 0:
		_up_timer -= _delta
	if _down_timer > 0:
		_down_timer -= _delta
	# Continuous smooth rotation (steering)
	var body_axis := get_body_axis()
	var perpendicular_dir = body_axis.cross(Vector3.UP).normalized()

	if Input.is_action_pressed("roll_right"):
		head.apply_central_force(perpendicular_dir * TAIL_LIFT_FORCE * 2.50)
	if Input.is_action_pressed("roll_left"):
		head.apply_central_force(-perpendicular_dir * TAIL_LIFT_FORCE * 2.50)



func _unhandled_input(_event: InputEvent) -> void:
	# var d = hinge_joint_3d.get_contact_local_normal(0)

	if Input.is_action_just_pressed("flop_down") and _down_timer <= 0:
		var real_body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()

		# Check if both head and tail are off the ground for bonus force
		var height_threshold = 0.5
		var propulsion_mult = 1.5
		if head.global_position.y > height_threshold and tail.global_position.y > height_threshold:
			propulsion_mult = 2.5 # Significant bonus for "Aerial Slam"

		# Slam tail down and slightly back to create a kick
		var slam_dir = (Vector3.DOWN * 0.7 + -real_body_axis * 0.3).normalized()
		tail.apply_central_impulse(slam_dir * TAIL_LIFT_FORCE)

		# Propel head forward
		head.apply_central_impulse(real_body_axis * TAIL_LIFT_FORCE * propulsion_mult)

		_down_timer = FLOP_COOLDOWN

	if Input.is_action_just_pressed("flop_up") and _up_timer <= 0:
		# Lift ends to create the curl
		var lift_force = TAIL_LIFT_FORCE * 0.6
		head.apply_central_impulse(Vector3.UP * lift_force)
		tail.apply_central_impulse(Vector3.UP * lift_force)

		_up_timer = FLOP_COOLDOWN


func _on_grab_range_right_body_entered(body: Node) -> void:
	_try_pick_up(body, holding_right)


func _try_pick_up(body: Node, holding_marker: Marker3D) -> void:
	var pickup := body as RigidBody3D
	if pickup == null:
		return

	if not pickup.is_in_group("pickup"):
		return

	if pickup.sleeping and pickup.collision_layer == 0 and pickup.collision_mask == 0:
		return

	pickup.reparent(holding_marker, true)
	pickup.global_transform = holding_marker.global_transform

	if pickup.has_method("set_held"):
		pickup.call("set_held", true)


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
