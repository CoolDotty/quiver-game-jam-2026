class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 8
const FLOP_COOLDOWN = 0.5
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
@onready var grab_range_left: Area3D = $Arm1/GrabRange
@onready var grab_range_right: Area3D = $Arm2/GrabRange

@onready var holding_left: Marker3D = $Arm1/Holding
@onready var holding_right: Marker3D = $Arm2/Holding

var _up_timer: float = 0.0
var _down_timer: float = 0.0


func _ready() -> void:
	set_process_unhandled_input(true)

	grab_range_left.body_entered.connect(_on_grab_range_left_body_entered)
	grab_range_right.body_entered.connect(_on_grab_range_right_body_entered)


func _process(_delta: float) -> void:
	_update_animation()


func _physics_process(_delta: float) -> void:
	if _up_timer > 0:
		_up_timer -= _delta
	if _down_timer > 0:
		_down_timer -= _delta
	# Continuous smooth rotation (steering)
	var body_axis := get_body_axis()
	var perpendicular_dir = body_axis.cross(Vector3.UP).normalized()

	if Input.is_action_pressed("roll_right"):
		head.apply_central_force(perpendicular_dir * TAIL_LIFT_FORCE * 2.55)
	if Input.is_action_pressed("roll_left"):
		head.apply_central_force(-perpendicular_dir * TAIL_LIFT_FORCE * 2.55)



func _unhandled_input(_event: InputEvent) -> void:
	# var d = hinge_joint_3d.get_contact_local_normal(0)

	var body_axis := get_body_axis()

	if Input.is_action_just_pressed("flop_down") and _down_timer <= 0:
		var real_body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()
		
		# Check if both head and tail are off the ground for bonus force
		var height_threshold = 0.5
		var propulsion_mult = 1.5
		if head.global_position.y > height_threshold and tail.global_position.y > height_threshold:
			propulsion_mult = 1.0 # Significant bonus for "Aerial Slam"
		
		# Slam tail down and slightly back to create a kick
		var slam_dir = (Vector3.DOWN * .7 + -real_body_axis * 0.3).normalized()
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


const arm_length = 750 * 2

func _on_grab_range_left_body_entered(body: Node) -> void:
	_try_pick_up(body, holding_left, Vector2(-arm_length, 0))


func _on_grab_range_right_body_entered(body: Node) -> void:
	_try_pick_up(body, holding_right, Vector2(arm_length, 0))


func _try_pick_up(body: Node, holding_marker: Marker3D, sprite_offset: Vector2) -> void:
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

	if pickup.has_method("set_sprite_offset"):
		pickup.call("set_sprite_offset", sprite_offset)


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


func _get_bend_offset() -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO

	var chain_points := get_chain_points()
	var projected_points: Array[Vector2] = []

	for point in chain_points:
		var camera_point := camera.to_local(point)
		projected_points.append(Vector2(camera_point.x, camera_point.y))

	var middle_point := (
		projected_points[1]
		+ projected_points[2]
		+ projected_points[3]
	) / 3.0
	var endpoints_midpoint := projected_points[0].lerp(projected_points[4], 0.5)

	return middle_point - endpoints_midpoint


func _update_animation() -> void:
	var bend_state := get_bend_state()
	var animation_prefix := "fish_flat"

	if bend_state == BendState.BENT:
		animation_prefix = "fish_flop"

	var flip_h := false
	var flip_v := false
	var facing := get_body_facing()

	if bend_state == BendState.BENT:
		var bend_offset := _get_bend_offset()

		if facing == Facing.LEFT or facing == Facing.RIGHT:
			flip_v = bend_offset.y < 0.0
		else:
			flip_h = bend_offset.x < 0.0

	var animation_name := "%s_%s" % [
		animation_prefix,
		_facing_to_suffix(facing),
	]

	if mermaid_sprites.animation != animation_name:
		mermaid_sprites.animation = animation_name

	mermaid_sprites.flip_h = flip_h
	mermaid_sprites.flip_v = flip_v


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
