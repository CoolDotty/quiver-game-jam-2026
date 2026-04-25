extends Node

# This script is intended to be attached to a node in your main scene
# to demonstrate the MusicManager's transitions.

func _process(_delta):
	# Get total elapsed time since game start in seconds
	var game_time = Time.get_ticks_msec() / 1000.0
	
	# Logic to drive the music intensity:
	# 0-10s: LOW, 10-20s: MEDIUM, 20s+: HIGH
	# (Shortened intervals for easy testing)
	if game_time < 10:
		MusicManager.set_intensity(MusicManager.Intensity.LOW)
	elif game_time < 20:
		MusicManager.set_intensity(MusicManager.Intensity.MEDIUM)
	else:
		MusicManager.set_intensity(MusicManager.Intensity.HIGH)
