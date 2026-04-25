class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 18.0


@onready var head: RigidBody3D = $Head
@onready var tail: RigidBody3D = $Tail
@onready var hinge_joint_3d: HingeJoint3D = $HingeJoint3D
@onready var rigid_body_3d_2: RigidBody3D = $RigidBody3D2


func _ready() -> void:
	set_process_unhandled_input(true)


func _physics_process(_delta: float) -> void:
	# Continuous smooth rotation (steering)
	var body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()
	var perpendicular_dir = body_axis.cross(Vector3.UP).normalized()
	
	if Input.is_action_pressed("roll_right"):
		# Apply a continuous force to steer the head in a smooth arc
		head.apply_central_force(perpendicular_dir * TAIL_LIFT_FORCE * 2.50)
	if Input.is_action_pressed("roll_left"):
		head.apply_central_force(-perpendicular_dir * TAIL_LIFT_FORCE * 2.50)

func _unhandled_input(event: InputEvent) -> void:
	
	#var d = hinge_joint_3d.get_contact_local_normal(0)
	
	var direction: Vector3 = (head.global_position - rigid_body_3d_2.global_position).normalized()
	
	if Input.is_action_just_pressed("flop_down"):
		var body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()
		
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
		
