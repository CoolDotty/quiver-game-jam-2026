extends Node3D

@export var item_scene: PackedScene
@export var spawn_interval: float = 5.0

@onready var timer: Timer = $Timer
@onready var display_area: Area3D = $DisplayArea
@onready var spawn_point: Marker3D = $DisplayArea/SpawnPoint

func _ready() -> void:
	timer.wait_time = spawn_interval
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)

func _process(_delta: float) -> void:
	if not _is_area_occupied():
		if timer.is_stopped():
			timer.start()
	else:
		timer.stop()

func _on_timer_timeout() -> void:
	if not _is_area_occupied():
		spawn_item()

func _is_area_occupied() -> bool:
	for body in display_area.get_overlapping_bodies():
		if body is StaticBody3D:
			continue
		return true
	return false

func spawn_item() -> void:
	if not item_scene: return
	var item = item_scene.instantiate()

	add_child(item)
	item.global_transform = spawn_point.global_transform
	item.add_to_group("pickup")
