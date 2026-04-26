extends RigidBody3D

@export var item_name: String = ""
@export var sprite_texture: Texture2D

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var interact_area: Area3D = $InteractArea
@onready var item_display_area: Marker3D = $ItemDisplayArea


func _ready() -> void:
	sprite_3d.texture = sprite_texture
	set_process_unhandled_input(true)

	interact_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	print("Item Box has aquired: ", body)
	if not body.is_in_group("pickup"):
		return

	body.reparent(item_display_area)
	body.freeze = true
