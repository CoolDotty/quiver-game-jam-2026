class_name Octobussy
extends Node3D
## Judges completed pot batches against a rotating recipe and updates the HUD.

const RECIPE_CATALOG := [
	{
		"cooked_name": "Coco cream",
		"burnt_name": "Unfortunately",
	},
	{
		"cooked_name": "Krabwich",
		"burnt_name": "Krap",
	},
	{
		"cooked_name": "SmokedSiren",
		"burnt_name": "Merstake",
	},
	{
		"cooked_name": "UrchinCake",
		"burnt_name": "Slurchin",
	},
]

const ROUND_DURATION := 120.0
const SCORE_EMOTE_OVERRIDE_DURATION := 3.0
const SUPER_ANGRY_DURATION := 10.0
const LOSS_MOVE_DURATION := 1.25
const LOSS_FADE_DURATION := 1.25
const LOSS_CAMERA_DISTANCE := 4.5
const LOSS_SCALE_MULTIPLIER := 20.0
const LOSS_SHAKE_MIN_AMPLITUDE := 0.015
const LOSS_SHAKE_MAX_AMPLITUDE := 0.18
const LOSS_SHAKE_MIN_SPEED := 7.0
const LOSS_SHAKE_MAX_SPEED := 16.0
const LOSS_RENDER_PRIORITY := 127
const GAME_OVER_SCENE_PATH := "res://scenes/game_over.tscn"

const NEUTRAL_TEXTURE := preload("res://assets/Art/Characters/octobussy_neutral.png")
const MIFFED_TEXTURE := preload("res://assets/Art/Characters/Octobussy.png")
const ANGRY_TEXTURE := preload("res://assets/Art/Characters/octobussy_angry.png")
const SAD_TEXTURE := preload("res://assets/Art/Characters/sad_octobussy.png")

@onready var portrait_sprite: Sprite3D = $Portrait
@onready var loss_fade_rect: ColorRect = $LossFade/Blackout
@onready var score_label: Label = $HUD/ScoreLabel
@onready var recipe_label: Label = $HUD/RecipeLabel
@onready var timer_label: Label = $HUD/TimerCenter/TimerLabel

var _rng := RandomNumberGenerator.new()
var _score: int = 0
var _recipe_size: int = 3
var _time_remaining: float = ROUND_DURATION
var _score_emote_override_remaining: float = 0.0
var _current_recipe: Array[RecipeSlot] = []
var _portrait_rest_position: Vector3 = Vector3.ZERO
var _shake_time: float = 0.0
var _is_game_over: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_recipe_size = _get_recipe_size_from_pot()

	if portrait_sprite != null:
		_portrait_rest_position = portrait_sprite.position
		var material := portrait_sprite.material_override as ShaderMaterial
		if material != null:
			portrait_sprite.material_override = material.duplicate()

	if loss_fade_rect != null:
		loss_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)

	if not Global.cooking_pot_recipe_completed.is_connected(_on_cooking_pot_recipe_completed):
		Global.cooking_pot_recipe_completed.connect(_on_cooking_pot_recipe_completed)

	_update_score_label()
	_update_timer_label()
	_update_portrait_emote()
	_generate_recipe(_recipe_size)


func _process(delta: float) -> void:
	if _is_game_over:
		return

	if _time_remaining > 0.0:
		_time_remaining = maxf(_time_remaining - delta, 0.0)

	if _score_emote_override_remaining > 0.0:
		_score_emote_override_remaining = maxf(
			_score_emote_override_remaining - delta,
			0.0
		)

	if Input.is_action_just_pressed("debug_decrease_time"):
		_time_remaining = maxf(_time_remaining - 10.0, 0.0)

	_update_loss_shake(delta)
	_update_timer_label()
	_update_portrait_emote()

	if _time_remaining <= 0.0:
		_start_game_over_sequence()


func _on_cooking_pot_recipe_completed(_pot: Node, items: Array) -> void:
	var delivered_item_names := _snapshot_item_names(items)
	var delta := _score_delivered_batch(delivered_item_names)

	_score += delta
	_update_score_label()
	_score_emote_override_remaining = SCORE_EMOTE_OVERRIDE_DURATION
	_update_portrait_emote()
	_generate_recipe(max(_current_recipe.size(), delivered_item_names.size()))


func _generate_recipe(recipe_size: int) -> void:
	if recipe_size <= 0:
		return

	_current_recipe.clear()

	for _index in range(recipe_size):
		var catalog_entry: Dictionary = RECIPE_CATALOG[
			_rng.randi_range(0, RECIPE_CATALOG.size() - 1)
		]
		_current_recipe.append(
			RecipeSlot.new(
				catalog_entry["cooked_name"],
				catalog_entry["burnt_name"]
			)
		)

	_update_recipe_label()


func _snapshot_item_names(items: Array) -> PackedStringArray:
	var item_names := PackedStringArray()

	for item in items:
		if item == null or not is_instance_valid(item):
			continue

		var dish_name := ""
		if item.has_method("get_item_name"):
			dish_name = String(item.call("get_item_name"))
		else:
			dish_name = String(item.name)

		if not dish_name.is_empty():
			item_names.append(dish_name)

	return item_names


func _score_delivered_batch(delivered_item_names: PackedStringArray) -> int:
	var score_delta := 0
	var matched_slots: Array = []
	matched_slots.resize(_current_recipe.size())

	for index in range(matched_slots.size()):
		matched_slots[index] = false

	for item_name in delivered_item_names:
		var slot_index := _find_matching_slot_index(item_name, matched_slots)
		if slot_index == -1:
			score_delta += _score_wrong_item(item_name)
			continue

		matched_slots[slot_index] = true
		var slot: RecipeSlot = _current_recipe[slot_index]
		score_delta += 2 if item_name == slot.cooked_name else 1

	return score_delta


func _find_matching_slot_index(item_name: String, matched_slots: Array) -> int:
	for index in range(_current_recipe.size()):
		if matched_slots[index]:
			continue

		var slot: RecipeSlot = _current_recipe[index]
		if slot.matches_item_name(item_name):
			return index

	return -1


func _score_wrong_item(item_name: String) -> int:
	if _is_burnt_name(item_name):
		return -2

	return -1


func _is_burnt_name(item_name: String) -> bool:
	for entry in RECIPE_CATALOG:
		if item_name == String(entry["burnt_name"]):
			return true

	return false


func _get_recipe_size_from_pot() -> int:
	for pot_node in get_tree().get_nodes_in_group("cooking_pot"):
		var cooking_pot := pot_node as CookingPot
		if cooking_pot != null:
			return cooking_pot.recipe_size

	return _recipe_size


func _update_score_label() -> void:
	score_label.text = "Score: %d" % _score


func _update_timer_label() -> void:
	var total_seconds: int = int(_time_remaining)
	if total_seconds < 0:
		total_seconds = 0

	var minutes: int = 0
	var seconds: int = total_seconds

	while seconds >= 60:
		minutes += 1
		seconds -= 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _update_portrait_emote() -> void:
	if portrait_sprite == null:
		return

	if _score_emote_override_remaining > 0.0:
		_apply_portrait_texture(SAD_TEXTURE if _score < 0 else NEUTRAL_TEXTURE)
		return

	_apply_portrait_texture(_get_time_based_portrait_texture())


func _update_loss_shake(delta: float) -> void:
	if portrait_sprite == null:
		return

	if _time_remaining > SUPER_ANGRY_DURATION:
		portrait_sprite.position = _portrait_rest_position
		_shake_time = 0.0
		return

	var time_ratio := clampf(_time_remaining / SUPER_ANGRY_DURATION, 0.0, 1.0)
	var intensity := 1.0 - time_ratio
	var shake_speed := lerpf(
		LOSS_SHAKE_MIN_SPEED,
		LOSS_SHAKE_MAX_SPEED,
		intensity
	)
	var shake_amplitude := lerpf(
		LOSS_SHAKE_MIN_AMPLITUDE,
		LOSS_SHAKE_MAX_AMPLITUDE,
		intensity * intensity
	)

	_shake_time += delta * shake_speed
	portrait_sprite.position = _portrait_rest_position + Vector3(
		sin(_shake_time * 11.0) * shake_amplitude,
		cos(_shake_time * 13.0) * shake_amplitude * 0.8,
		sin(_shake_time * 7.0) * shake_amplitude * 0.25,
	)


func _start_game_over_sequence() -> void:
	if _is_game_over:
		return

	_is_game_over = true
	_time_remaining = 0.0
	_update_timer_label()

	if portrait_sprite != null:
		portrait_sprite.position = _portrait_rest_position
		portrait_sprite.render_priority = LOSS_RENDER_PRIORITY

	if loss_fade_rect != null:
		loss_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)

	var camera := get_viewport().get_camera_3d()
	var target_position := global_position
	if camera != null:
		var viewport_size := get_viewport().get_visible_rect().size
		var screen_center := viewport_size * 0.5
		target_position = camera.project_position(
			screen_center,
			LOSS_CAMERA_DISTANCE
		)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		self,
		"global_position",
		target_position,
		LOSS_MOVE_DURATION
	)
	tween.parallel().tween_property(
		self,
		"scale",
		Vector3.ONE * LOSS_SCALE_MULTIPLIER,
		LOSS_MOVE_DURATION
	)
	if loss_fade_rect != null:
		tween.parallel().tween_property(
			loss_fade_rect,
			"color",
			Color(0.0, 0.0, 0.0, 1.0),
			LOSS_FADE_DURATION
		)
	get_tree().paused = true
	tween.tween_callback(Callable(self, "_go_to_game_over_scene"))


func _go_to_game_over_scene() -> void:
	var error := get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)
	if error != OK:
		push_error("Failed to load game over scene: %s" % GAME_OVER_SCENE_PATH)


func _get_time_based_portrait_texture() -> Texture2D:
	if ROUND_DURATION <= 0.0:
		return NEUTRAL_TEXTURE

	var time_ratio := _time_remaining / ROUND_DURATION
	if time_ratio <= 0.1:
		return ANGRY_TEXTURE
	if time_ratio <= 0.5:
		return MIFFED_TEXTURE

	return NEUTRAL_TEXTURE


func _apply_portrait_texture(texture: Texture2D) -> void:
	if portrait_sprite == null:
		return

	portrait_sprite.texture = texture

	var material := portrait_sprite.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("billboard_texture", texture)


func _update_recipe_label() -> void:
	var lines := PackedStringArray()
	lines.append("Recipe:")

	for slot in _current_recipe:
		lines.append("- %s" % slot.cooked_name)

	recipe_label.text = "\n".join(lines)


class RecipeSlot:
	var cooked_name: String
	var burnt_name: String


	func _init(new_cooked_name: String, new_burnt_name: String) -> void:
		cooked_name = new_cooked_name
		burnt_name = new_burnt_name


	func matches_item_name(item_name: String) -> bool:
		return item_name == cooked_name or item_name == burnt_name
