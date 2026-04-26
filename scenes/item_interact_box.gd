extends RigidBody3D


@export var item_interact : ItemData
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var interact_area: Area3D = $InteractArea
@onready var item_display_area: Marker3D = $ItemDisplayArea


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_3d.texture = item_interact.sprite_texture
	set_process_unhandled_input(true)
	
	interact_area.body_entered.connect(
		func(body):
			print("Item Box has aquired: ", body)
			if not body.is_in_group("pickup"):
				return
			print("Item Box has aquired: ", body)
			body.reparent(item_display_area)
			body.freeze = true
	)
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
