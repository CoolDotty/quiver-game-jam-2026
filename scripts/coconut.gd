extends RigidBody3D

@export var item_name: String = ""
@export var sprite_texture: Texture2D

@onready var sprite_3d: Sprite3D = get_node_or_null("Sprite3D") as Sprite3D


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

	if sprite_3d != null:
		sprite_3d.texture = sprite_texture


func get_item_name() -> String:
	return item_name if not item_name.is_empty() else "Unknown Item"


func set_item_name(value: String) -> void:
	item_name = value


func get_sprite_texture() -> Texture2D:
	return sprite_texture


func set_sprite_texture(value: Texture2D) -> void:
	sprite_texture = value
	if sprite_3d != null:
		sprite_3d.texture = sprite_texture


func _on_body_entered(body: Node) -> void:
	if body.collision_layer & (1 << 3):
		print("Item touched by arm!")
		Global.collect_item(get_item_name())
		queue_free()
