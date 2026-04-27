class_name PauseMenu
extends CanvasLayer
## Handles the in-game pause overlay and restart flow.

signal pause_requested
signal resume_requested
signal restart_requested

@onready var root: Control = $Root
@onready var resume_button: TextureButton = $Root/CenterContainer/MenuColumn/ResumeButton
@onready var restart_button: Button = $Root/CenterContainer/MenuColumn/RestartButton

var _is_open: bool = false


func _ready() -> void:
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS

	if resume_button != null and not resume_button.pressed.is_connected(
			_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)

	if restart_button != null and not restart_button.pressed.is_connected(
			_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)

	close_menu()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return

	get_viewport().set_input_as_handled()

	if _is_open:
		resume_requested.emit()
	else:
		pause_requested.emit()


func open_menu() -> void:
	if _is_open:
		return

	_is_open = true

	if root != null:
		root.show()

	if resume_button != null:
		resume_button.grab_focus()


func close_menu() -> void:
	if not _is_open and root != null and not root.visible:
		return

	_is_open = false

	if root != null:
		root.hide()


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
