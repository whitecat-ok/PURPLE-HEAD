
extends CanvasLayer

signal dialogue_finished
signal speaker_talking_changed(speaker: Node2D, talking: bool)

@export_group("Dialogue")
@export var dialogue_lines: Array[String] = [
	"Otra vez lo mismo...",
	"¿Cuántas veces vamos a tener que pasar por esto?"
]

@export var default_speaker: Node2D

@export_group("Speakers")
@export var dialogue_speakers: Array[Node2D] = []

@export_group("Appearance")
@export var character_delay: float = 0.035
@export var bubble_world_offset: Vector2 = Vector2(0, -65)
@export var bubble_screen_offset: Vector2 = Vector2(0, -10)

@onready var bubble: PanelContainer = $PanelContainer
@onready var dialogue_label: Label = $PanelContainer/MarginContainer/Label

var current_index: int = 0
var current_speaker: Node2D

var text_progress: float = 0.0
var visible_characters_count: int = 0

var dialogue_active: bool = false
var text_complete: bool = false

var camera: Camera2D


func _ready() -> void:
	bubble.visible = false
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dialogue_label.visible_characters = 0
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	camera = get_viewport().get_camera_2d()


func _process(delta: float) -> void:
	if not dialogue_active:
		return

	_update_bubble_position()

	if not text_complete:
		text_progress += delta

		var safe_delay: float = maxf(character_delay, 0.001)
		var target_characters: int = int(text_progress / safe_delay)

		if target_characters > visible_characters_count:
			visible_characters_count = target_characters
			dialogue_label.visible_characters = visible_characters_count

		if visible_characters_count >= dialogue_label.text.length():
			_complete_current_text()


# El diálogo tiene prioridad sobre otras interacciones.
func _input(event: InputEvent) -> void:
	if not dialogue_active:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_handle_advance()


func play_dialogue() -> void:
	if dialogue_active:
		push_warning("DialogueManager: Ya hay un diálogo activo.")
		return

	if dialogue_lines.is_empty():
		return

	current_index = 0
	dialogue_active = true

	bubble.visible = true

	_show_current_line()

	await dialogue_finished


func _show_current_line() -> void:
	if current_index >= dialogue_lines.size():
		_finish_dialogue()
		return

	dialogue_label.text = dialogue_lines[current_index]
	dialogue_label.visible_characters = 0

	visible_characters_count = 0
	text_progress = 0.0
	text_complete = false

	if current_index < dialogue_speakers.size():
		current_speaker = dialogue_speakers[current_index]
	else:
		current_speaker = default_speaker

	_set_speaker_talking(true)

	_update_bubble_position()
	bubble.reset_size()


func _handle_advance() -> void:
	if not text_complete:
		_complete_current_text()
		return

	_set_speaker_talking(false)

	current_index += 1

	if current_index >= dialogue_lines.size():
		_finish_dialogue()
	else:
		_show_current_line()


func _complete_current_text() -> void:
	if text_complete:
		return

	text_complete = true
	visible_characters_count = dialogue_label.text.length()
	dialogue_label.visible_characters = -1

	_set_speaker_talking(false)


func _finish_dialogue() -> void:
	_set_speaker_talking(false)

	dialogue_active = false
	bubble.visible = false
	current_speaker = null

	dialogue_finished.emit()


func _set_speaker_talking(talking: bool) -> void:
	if current_speaker == null:
		return

	if not is_instance_valid(current_speaker):
		return

	speaker_talking_changed.emit(current_speaker, talking)


func _update_bubble_position() -> void:
	if current_speaker == null:
		return

	if not is_instance_valid(current_speaker):
		return

	if camera == null:
		camera = get_viewport().get_camera_2d()

	if camera == null:
		return

	var world_position: Vector2 = (
		current_speaker.global_position + bubble_world_offset
	)

	var screen_position: Vector2 = (
		get_viewport().get_canvas_transform() * world_position
	)

	bubble.reset_size()

	var bubble_position: Vector2 = Vector2(
		bubble.size.x * 0.5,
		bubble.size.y
	)

	bubble.position = (
		screen_position
		- bubble_position
		+ bubble_screen_offset
	)


func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera


func set_default_speaker(speaker: Node2D) -> void:
	default_speaker = speaker
