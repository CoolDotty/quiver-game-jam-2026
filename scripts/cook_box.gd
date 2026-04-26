extends Node3D

enum State {
	EMPTY,
	COOKING
}

@export var cooking_time: float = 3.0
@export var modified_item_prefix: String = "Cooked "

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
	
	item.remove_from_group("pickup")
	item.set_deferred("freeze", true)
	item.call_deferred("reparent", self)
	call_deferred("_deferred_position_item", item)
	
	timer.start()

func _deferred_position_item(item: RigidBody3D) -> void:
	item.global_transform = item_spawn_point.global_transform

func _on_cooking_finished() -> void:
	print("CookBox: Item finished cooking! Spawning new item.")
	if current_item == null: return
	
	_modify_item()
	
	# We pass the current_item to a deferred function to handle spawning
	# to avoid "not in tree" errors when setting global_position
	call_deferred("_spawn_cooked_item", current_item)
	
	current_item.queue_free()
	current_item = null
	current_state = State.EMPTY

func _spawn_cooked_item(item_to_duplicate: RigidBody3D) -> void:
	var newItem = item_to_duplicate.duplicate()
	
	# Add to tree FIRST so global_position works
	get_tree().root.add_child(newItem)
	
	newItem.add_to_group("pickup")
	newItem.set_deferred("freeze", false)
	
	# Position: 5 units up and 4 units to the right (relative to box facing)
	var spawn_pos = global_position + Vector3.UP * 5.0 + (global_transform.basis.x * 4.0)
	newItem.global_position = spawn_pos
	
	print("CookBox: Spawned modified item at ", spawn_pos)

func _modify_item() -> void:
	if current_item == null: return
	if "data" in current_item and current_item.data:
		current_item.data.item_name = modified_item_prefix + current_item.data.item_name
		if current_item.has_node("Sprite3D"):
			current_item.get_node("Sprite3D").texture = current_item.data.sprite_texture
	print("CookBox: Item modified to: ", current_item.data.item_name if "data" in current_item and current_item.data else "Unknown")
