extends AudioStreamPlayer3D

# Cache all child randomizer players by name on ready
var _sounds: Dictionary = {}

func _ready() -> void:
	for child in get_children():	
		if child is AudioStreamPlayer3D:
			_sounds[child.name] = child

func play_sound(sound_name: String) -> void:
	print("A sound has been player: ")
	print(sound_name)
	if _sounds.has(sound_name):
		_sounds[sound_name].play()
		print("The sound actually played")
	else:
		push_warning("SoundManager: no child named '%s'" % sound_name)
