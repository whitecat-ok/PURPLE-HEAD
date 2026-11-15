
extends Node2D

@export_group("References")
@export var character_manager: Node
@export var dialogue_manager: CanvasLayer

@export_group("Interaction")
@export var interaction_enabled: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction: Area2D = $interaction
@onready var proximity: Area2D = $proximity
@onready var indicator: CanvasItem = $indicator

var player_nearby: bool = false
var interacting: bool = false
var current_character: CharacterBody2D


func _ready() -> void:
	indicator.visible = false

	animated_sprite.play("still")

	interaction.input_pickable = true

	interaction.input_event.connect(_on_interaction_input_event)

	proximity.body_entered.connect(_on_proximity_body_entered)
	proximity.body_exited.connect(_on_proximity_body_exited)

	if character_manager == null:
		push_error("Grandfather: Asigna CharacterManager.")
		return

	if dialogue_manager == null:
		push_error("Grandfather: Asigna DialogueManager.")
		return

	if dialogue_manager.has_signal("speaker_talking_changed"):
		dialogue_manager.speaker_talking_changed.connect(
			_on_speaker_talking_changed
		)

	print("[Grandfather] Sistema de interacción iniciado.")


func _process(_delta: float) -> void:
	if interacting or not interaction_enabled:
		indicator.visible = false
		return

	if character_manager == null:
		return

	var selected := character_manager.call(
		"get_selected_character"
	) as CharacterBody2D

	var overlapping := proximity.get_overlapping_bodies()

	player_nearby = (
		selected != null
		and overlapping.has(selected)
		and selected.is_in_group("playable_characters")
	)

	current_character = selected if player_nearby else null

	indicator.visible = player_nearby


# =========================================================
# PROXIMITY
# =========================================================

func _on_proximity_body_entered(body: Node2D) -> void:
	if not body.is_in_group("playable_characters"):
		return

	print("[Grandfather] Personaje entró en proximidad: ", body.name)


func _on_proximity_body_exited(body: Node2D) -> void:
	if not body.is_in_group("playable_characters"):
		return

	print("[Grandfather] Personaje salió de proximidad: ", body.name)


# =========================================================
# CLICK
# =========================================================

func _on_interaction_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if not interaction_enabled:
		return

	if interacting or not player_nearby:
		return

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			get_viewport().set_input_as_handled()
			_start_interaction()


func _start_interaction() -> void:
	if interacting:
		return

	if current_character == null:
		return

	if character_manager.call("is_player_locked"):
		return

	interacting = true
	indicator.visible = false

	character_manager.call("set_player_locked", true)

	print("[Grandfather] Iniciando conversación.")

	await dialogue_manager.call("play_dialogue")

	animated_sprite.play("still")

	character_manager.call("set_player_locked", false)

	interacting = false

	print("[Grandfather] Conversación terminada.")


# =========================================================
# ANIMACIONES DE DIÁLOGO
# =========================================================

func _on_speaker_talking_changed(
	speaker: Node2D,
	talking: bool
) -> void:
	if speaker != self:
		return

	if talking:
		animated_sprite.play("talking")
	else:
		animated_sprite.play("still")


# =========================================================
# CONTROL EXTERNO
# =========================================================

func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled

	if not enabled:
		indicator.visible = false


func set_talking(talking: bool) -> void:
	if talking:
		animated_sprite.play("talking")
	else:
		animated_sprite.play("still")
