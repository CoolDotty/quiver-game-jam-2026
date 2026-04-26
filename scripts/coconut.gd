extends RigidBody3D

@export var data: Resource # This will hold the ItemData resource

var item_name: String:
	get:
		return data.item_name if data else "Unknown Item"

func set_item_data(new_data: Resource) -> void:
	data = new_data
	# You can update visuals here based on data (e.g., change color if it's a golden coconut)
	if data:
		print("Item data injected: ", data.item_name)

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.collision_layer & (1 << 3): 
		print("Item touched by arm!")
		Global.collect_item(item_name)
		queue_free()
