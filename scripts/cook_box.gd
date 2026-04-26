extends Node3D

enum State {
	EMPTY,
	COOKING
}

@onready var timer: Timer = $Timer
@onready var interaction_area: Area3D = $InteractionArea
@onready var item_spawn_point: Marker3D = $ItemSpawnPoint

var current_item: RigidBody3D = null
var current_state: State = State.EMPTY

func _ready() -> void:
	timer.wait_time = cooking_time
	timer.one_shot = true
	timer.timeout.connect(_on_cooking_finished)
	
	interaction_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if current_state == State.EMPTY:
		if body.is_in_group("pickup"):
			_take_item(body)

func _take_item(item: RigidBody3D) -> void:
	print("CookBox: Taking item ", item.name)
	current_item = item
	current_state = State.COOKING
	timer.wait_time = _get_cook_time(item)

	item.remove_from_group("pickup")
	Global.cooking_item_consumed.emit(self, item)
	item.set_deferred("freeze", true)
	item.call_deferred("reparent", self)
	call_deferred("_deferred_position_item", item)
	
	timer.start()

func _deferred_position_item(item: RigidBody3D) -> void:
	item.global_transform = item_spawn_point.global_transform

func _on_cooking_finished() -> void:
	print("CookBox: Item finished cooking! Spawning new item.")
	if current_item == null: return
	
	var cooked_item: RigidBody3D = _create_cooked_item(current_item)
	if cooked_item == null:
		current_item.queue_free()
		current_item = null
		current_state = State.EMPTY
		return

	call_deferred("_spawn_cooked_item", cooked_item)
	
	current_item.queue_free()
	current_item = null
	current_state = State.EMPTY

func _create_cooked_item(item: RigidBody3D) -> RigidBody3D:
	var cooked_scene: PackedScene = null
	if item.has_method("get_cooks_into"):
		cooked_scene = item.call("get_cooks_into") as PackedScene

	if cooked_scene == null:
		return item.duplicate() as RigidBody3D

	return cooked_scene.instantiate() as RigidBody3D


func _get_cook_time(item: RigidBody3D) -> float:
	if item != null and item.has_method("get_cook_time"):
		return float(item.call("get_cook_time"))

	return 3.0


func _spawn_cooked_item(new_item: RigidBody3D) -> void:
	if new_item == null:
		return

	get_tree().root.add_child(new_item)

	new_item.add_to_group("pickup")
	new_item.set_deferred("freeze", false)

	var spawn_pos = global_position + Vector3.UP * 5.0 + (
		global_transform.basis.x * 4.0
	)
	new_item.global_position = spawn_pos

	print("CookBox: Spawned cooked item at ", spawn_pos)
