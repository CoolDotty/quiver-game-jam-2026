extends Node3D

@onready var audio_manager: AudioStreamPlayer3D = $"../Camera3D/AudioManager"

enum State {HAPPY, ANGRY}

# 2. Track the current state
var current_state = State.HAPPY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match current_state:
		State.HAPPY:
			pass  
			#if next_coconut.judgement == good
			#   change_state(State.HAPPY)   
		State.ANGRY:
			pass
			#if next_coconut.judgement == good
			#   change_state(State.HAPPY)
			
func change_state(new_state):
	current_state = new_state
	print("Changed state to: ", State.keys()[new_state])
