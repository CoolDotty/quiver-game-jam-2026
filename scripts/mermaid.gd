class_name Mermaid
extends Node3D

const TAIL_LIFT_FORCE = 12
const FLOP_COOLDOWN = 0.5
const EJECT_VELOCITY_SCALE = 0.7
const EJECT_FALLBACK_SPEED = 1.75
const EJECT_SPIN_SCALE = 1.15
const EJECT_LIFT = 1.2

enum Facing {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

@onready var audio_manager: AudioStreamPlayer3D = $"../Camera3D/AudioManager"

@onready var head: RigidBody3D = $Head
@onready var tail: RigidBody3D = $Tail
@onready var hinge_joint_3d: HingeJoint3D = $HingeJoint3D
@onready var rigid_body_3d_2: RigidBody3D = $RigidBody3D2
@onready var rigid_body_3d_3: RigidBody3D = $RigidBody3D3
@onready var rigid_body_3d_4: RigidBody3D = $RigidBody3D4
@onready var held_item_holder: Node3D = $HeldItemHolder
@onready var holding_right: Marker3D = get_node_or_null("Arm2/Holding/HandAnchor") as Marker3D
@onready var grab_range_head: Area3D = get_node_or_null("Head/GrabRange") as Area3D

var _up_timer: float = 0.0
var _down_timer: float = 0.0
var _held_item: RigidBody3D = null
var _pickups_in_range: Array[RigidBody3D] = []
var _last_holder_position: Vector3 = Vector3.ZERO
var _holder_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	set_process_unhandled_input(true)

	if grab_range_head == null:
		push_error("Mermaid head grab range is missing.")
		return
	if holding_right == null:
		push_error("Mermaid hand hold anchor is missing.")
		return

	grab_range_head.body_entered.connect(_on_grab_range_head_body_entered)
	grab_range_head.body_exited.connect(_on_grab_range_head_body_exited)
	Global.cooking_pot_item_inserted.connect(_on_cooking_pot_item_inserted)
	_last_holder_position = held_item_holder.global_position


func _physics_process(_delta: float) -> void:
	if _up_timer > 0:
		_up_timer -= _delta
	if _down_timer > 0:
		_down_timer -= _delta
	# Continuous smooth rotation (steering)
	var body_axis: Vector3 = get_body_axis()
	var perpendicular_dir: Vector3 = body_axis.cross(Vector3.UP).normalized()

	if Input.is_action_pressed("roll_right"):
		head.apply_central_force(perpendicular_dir * TAIL_LIFT_FORCE * 2.50)
	if Input.is_action_pressed("roll_left"):
		head.apply_central_force(-perpendicular_dir * TAIL_LIFT_FORCE * 2.50)

	if _held_item != null and is_instance_valid(_held_item):
		held_item_holder.global_transform = holding_right.global_transform
		var safe_delta: float = maxf(_delta, 0.0001)
		_holder_velocity = (held_item_holder.global_position - _last_holder_position) / safe_delta
		_last_holder_position = held_item_holder.global_position
	else:
		_holder_velocity = Vector3.ZERO
		_last_holder_position = held_item_holder.global_position



func _unhandled_input(_event: InputEvent) -> void:
	# var d = hinge_joint_3d.get_contact_local_normal(0)

	if Input.is_action_just_pressed("flop_down") and _down_timer <= 0:
		audio_manager.play_sound("Audio3D_MermaidTail")
		var real_body_axis = (head.global_position - rigid_body_3d_2.global_position).normalized()
		var real_body_axis: Vector3 = (head.global_position - rigid_body_3d_2.global_position).normalized()

		# Check if both head and tail are off the ground for bonus force
		var height_threshold: float = 0.5
		var propulsion_mult: float = 1.5
		if head.global_position.y > height_threshold and tail.global_position.y > height_threshold:
			propulsion_mult = 2.5 # Significant bonus for "Aerial Slam"

		# Slam tail down and slightly back to create a kick
		var slam_dir: Vector3 = (Vector3.DOWN * 0.7 + -real_body_axis * 0.3).normalized()
		tail.apply_central_impulse(slam_dir * TAIL_LIFT_FORCE)

		# Propel head forward
		head.apply_central_impulse(real_body_axis * TAIL_LIFT_FORCE * propulsion_mult)

		_down_timer = FLOP_COOLDOWN

	if Input.is_action_just_pressed("flop_up") and _up_timer <= 0:
		# Lift ends to create the curl
		var lift_force: float = TAIL_LIFT_FORCE * 0.6
		head.apply_central_impulse(Vector3.UP * lift_force)
		tail.apply_central_impulse(Vector3.UP * lift_force)

		_up_timer = FLOP_COOLDOWN

	if Input.is_action_just_pressed("interact"):
		_interact()


func _on_grab_range_head_body_entered(body: Node) -> void:
	var pickup: RigidBody3D = body as RigidBody3D
	if pickup == null:
		return

	if not pickup.is_in_group("pickup"):
		return

	if _pickups_in_range.has(pickup):
		return

	_pickups_in_range.append(pickup)


func _on_grab_range_head_body_exited(body: Node) -> void:
	var pickup: RigidBody3D = body as RigidBody3D
	if pickup == null:
		return

	_pickups_in_range.erase(pickup)


func _try_pick_up_from_range() -> void:
	if _held_item != null and is_instance_valid(_held_item):
		return

	for pickup in _pickups_in_range:
		if is_instance_valid(pickup):
			_try_pick_up(pickup)
			return


func _interact() -> void:
	if _held_item != null and is_instance_valid(_held_item):
		if _try_interact_with_pot():
			return
		_eject_held_item()
		return

	if _try_interact_with_pot():
		return

	_try_pick_up_from_range()


func _try_interact_with_pot() -> bool:
	var pots := get_tree().get_nodes_in_group("cooking_pot")
	for node in pots:
		var pot := node as CookingPot
		if pot == null:
			continue

		if pot.try_interact(_held_item, held_item_holder.global_position):
			return true

	return false


func _on_cooking_pot_item_inserted(_pot: Node, item: RigidBody3D) -> void:
	if item != _held_item:
		return

	_held_item = null
	_holder_velocity = Vector3.ZERO


func _try_pick_up(body: Node) -> void:
	var pickup: RigidBody3D = body as RigidBody3D
	if pickup == null:
		return

	if _held_item != null:
		if is_instance_valid(_held_item):
			return
		_held_item = null

	if not pickup.is_in_group("pickup"):
		return

	if pickup.has_method("is_held") and pickup.call("is_held"):
		return

	if pickup.has_method("is_in_pot") and pickup.call("is_in_pot"):
		return

	held_item_holder.global_transform = holding_right.global_transform
	pickup.reparent(held_item_holder, true)
	pickup.global_transform = held_item_holder.global_transform

	if pickup.has_method("set_held"):
		pickup.call("set_held", true)

	_held_item = pickup
	_last_holder_position = held_item_holder.global_position
	_holder_velocity = Vector3.ZERO
	_pickups_in_range.erase(pickup)
	if not pickup.tree_exited.is_connected(_on_held_item_tree_exited):
		pickup.tree_exited.connect(_on_held_item_tree_exited)


func _on_held_item_tree_exited() -> void:
	_held_item = null


func _eject_held_item() -> void:
	if _held_item == null:
		return

	if not is_instance_valid(_held_item):
		_held_item = null
		return

	var item: RigidBody3D = _held_item
	_held_item = null
	var launch_velocity: Vector3 = _holder_velocity * EJECT_VELOCITY_SCALE
	launch_velocity.y = maxf(launch_velocity.y, -0.35)

	var world_root: Node = get_tree().current_scene
	if world_root == null:
		world_root = get_tree().root

	item.reparent(world_root, true)
	item.global_transform = holding_right.global_transform

	if item.has_method("set_held"):
		item.call("set_held", false)

	if launch_velocity.length_squared() < 0.0001:
		launch_velocity = get_body_axis().cross(Vector3.UP).normalized() * EJECT_FALLBACK_SPEED
	launch_velocity.y = maxf(launch_velocity.y, EJECT_LIFT)

	item.angular_velocity = launch_velocity.cross(Vector3.UP) * EJECT_SPIN_SCALE

	item.linear_velocity = launch_velocity


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
