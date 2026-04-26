extends AudioStreamPlayer3D

const FADE_DURATION := 1.5
var _initialized := false
var _current_clip := ""


func _ready() -> void:
	play()


func _process(_delta: float) -> void:
	if not _initialized and playing:
		_initialized = true
		switch_clip("Main Menu")


func switch_clip(clip_name: String) -> void:
	# Don't interrupt if already on this clip
	if _current_clip == clip_name:
		return
	_current_clip = clip_name

	if not playing:
		play()
		while not playing:
			await get_tree().process_frame
		get_stream_playback().switch_to_clip_by_name(clip_name)
		return

	# Fade out, switch, fade back in
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "volume_db", -80.0, FADE_DURATION)
	await tween.finished

	volume_db = -80.0
	play()
	while not playing:
		await get_tree().process_frame

	get_stream_playback().switch_to_clip_by_name(clip_name)

	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "volume_db", 0.0, FADE_DURATION)
