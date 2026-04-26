extends Node

@warning_ignore("unused_signal")
signal cooking_pot_item_inserted(pot: Node, item: RigidBody3D)
@warning_ignore("unused_signal")
signal cooking_pot_recipe_completed(pot: Node, items: Array)

func _ready() -> void:
	print("Global autoload ready.")
