class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 14
const FLOP_COOLDOWN = 0.6

@onready var head: RigidBody3D = $Head
@onready var tail: RigidBody3D = $Tail
@onready var hinge_joint_3d: HingeJoint3D = $HingeJoint3D
@onready var rigid_body_3d_2: RigidBody3D = $RigidBody3D2

var _up_timer: float = 0.0
var _down_timer: float = 0.0


func _ready() -> void:
	set_process_unhandled_input(true)


func _physics_process(delta: float) -> void:
	# Handle individual cooldowns
	if _up_timer > 0:
		_up_timer -= delta
	if _down_timer > 0:
		_down_timer -= delta
	
	# Continuous smooth rotation (steering)
	var body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()
	var perpendicular_dir = body_axis.cross(Vector3.UP).normalized()
	
	if Input.is_action_pressed("roll_right"):
		head.apply_central_force(perpendicular_dir * TAIL_LIFT_FORCE * 2.50)
	if Input.is_action_pressed("roll_left"):
		head.apply_central_force(-perpendicular_dir * TAIL_LIFT_FORCE * 2.50)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("flop_down") and _down_timer <= 0:
		var body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()
		
		# Check if both head and tail are off the ground for bonus force
		var height_threshold = 0.5
		var propulsion_mult = 1.5
		if head.global_position.y > height_threshold and tail.global_position.y > height_threshold:
			propulsion_mult = 2.5 # Significant bonus for "Aerial Slam"
		
		# Slam tail down and slightly back to create a kick
		var slam_dir = (Vector3.DOWN * 0.7 + -body_axis * 0.3).normalized()
		tail.apply_central_impulse(slam_dir * TAIL_LIFT_FORCE)
		
		# Propel head forward
		head.apply_central_impulse(body_axis * TAIL_LIFT_FORCE * propulsion_mult)
		
		_down_timer = FLOP_COOLDOWN
		
	if Input.is_action_just_pressed("flop_up") and _up_timer <= 0:
		# Lift ends to create the curl
		var lift_force = TAIL_LIFT_FORCE * 0.6
		head.apply_central_impulse(Vector3.UP * lift_force)
		tail.apply_central_impulse(Vector3.UP * lift_force)
		
		_up_timer = FLOP_COOLDOWN
