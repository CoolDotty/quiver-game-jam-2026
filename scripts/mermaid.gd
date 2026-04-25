class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 18.0


@onready var head: RigidBody3D = $Head
@onready var tail: RigidBody3D = $Tail
@onready var hinge_joint_3d: HingeJoint3D = $HingeJoint3D
@onready var rigid_body_3d_2: RigidBody3D = $RigidBody3D2


func _ready() -> void:
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	
	#var d = hinge_joint_3d.get_contact_local_normal(0)
	
	var direction: Vector3 = (head.global_position - rigid_body_3d_2.global_position).normalized()
	
	if Input.is_action_just_pressed("flop_down"):
		tail.apply_impulse(Vector3(0.676, -1, 0) * TAIL_LIFT_FORCE)
		head.apply_impulse(Vector3.FORWARD * TAIL_LIFT_FORCE * 1)
	if Input.is_action_just_pressed("flop_up"):
		head.apply_impulse(Vector3(0, 1, 0) * TAIL_LIFT_FORCE)
		tail.apply_impulse(Vector3(0, 1, 0) * TAIL_LIFT_FORCE)
	if Input.is_action_just_pressed("roll_left"):
		head.apply_central_force(Vector3(0, 0, 1) * TAIL_LIFT_FORCE * 100)
	if Input.is_action_just_pressed("roll_right"):
		head.apply_central_force(Vector3(0, 0, -1) * TAIL_LIFT_FORCE * 100)
		
