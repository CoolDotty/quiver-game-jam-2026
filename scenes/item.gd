extends RigidBody3D


@export var item : ItemData
@onready var sprite_3d: Sprite3D = $Sprite3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_3d.texture = item.sprite_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
