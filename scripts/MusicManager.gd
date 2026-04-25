extends Node

enum Intensity { LOW, MEDIUM, HIGH }

# Configuration for each intensity level
# BPM: Beats per minute
# phrase_beats: How many beats make a "phrase" (e.g., 16 beats for 4 bars of 4/4)
const INTENSITY_CONFIG = {
	Intensity.LOW: { "bpm": 100.0, "phrase_beats": 16 },
	Intensity.MEDIUM: { "bpm": 120.0, "phrase_beats": 16 },
	Intensity.HIGH: { "bpm": 140.0, "phrase_beats": 16 },
}

@export var low_track: AudioStream
@export var medium_track: AudioStream
@export var high_track: AudioStream

var current_intensity: Intensity = Intensity.LOW
var target_intensity: Intensity = Intensity.LOW
var player: AudioStreamPlayer

var last_phrase_index: int = -1

func _ready():
	# Initialize the player
	player = AudioStreamPlayer.new()
	add_child(player)
	player.bus = "Music" # Make sure you have a Music bus in Audio mixer
	
	# Start with low intensity
	_apply_intensity(Intensity.LOW)
	player.play()

func _process(_delta):
	if player == null or !player.playing:
		return

	# Calculate phrase boundary
	var config = INTENSITY_CONFIG[current_intensity]
	var beat_duration = 60.0 / config["bpm"]
	var phrase_duration = beat_duration * config["phrase_beats"]
	
	var playback_pos = player.get_playback_position()
	var current_phrase_index = floor(playback_pos / phrase_duration)
	
	# Check if we have entered a new phrase
	if current_phrase_index != last_phrase_index:
		last_phrase_index = current_phrase_index
		# If the game has requested a change, switch now!
		if target_intensity != current_intensity:
			_transition_to_target()

## Call this from your game timer or enemy logic
func set_intensity(new_intensity: Intensity):
	if new_intensity != target_intensity:
		print("MusicManager: Intensity change requested to ", Intensity.keys()[new_intensity])
		target_intensity = new_intensity

func _transition_to_target():
	var old_intensity = current_intensity
	var new_intensity = target_intensity
	
	# Calculate where we were in the song (which phrase)
	var old_config = INTENSITY_CONFIG[old_intensity]
	var old_phrase_duration = (60.0 / old_config["bpm"]) * old_config["phrase_beats"]
	var phrase_index = floor(player.get_playback_position() / old_phrase_duration)
	
	# Calculate the starting position in the new track to keep it synced
	var new_config = INTENSITY_CONFIG[new_intensity]
	var new_phrase_duration = (60.0 / new_config["bpm"]) * new_config["phrase_beats"]
	var start_position = phrase_index * new_phrase_duration
	
	print("MusicManager: Transitioning phrase %d from %s to %s" % [phrase_index, Intensity.keys()[old_intensity], Intensity.keys()[new_intensity]])
	
	_apply_intensity(new_intensity)
	
	# Play from the synchronized position
	player.play(start_position)
	current_intensity = new_intensity

func _apply_intensity(intensity: Intensity):
	match intensity:
		Intensity.LOW:
			player.stream = low_track
		Intensity.MEDIUM:
			player.stream = medium_track
		Intensity.HIGH:
			player.stream = high_track
