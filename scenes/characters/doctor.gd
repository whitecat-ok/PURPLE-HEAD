
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
@onready var interaction_label: Label = $InteractionLabel

var player_nearby: bool = false
var interacting: bool = false
var current_character: CharacterBody2D = null


func _ready() -> void:
	indicator.visible = false
	interaction_label.visible = false
	animated_sprite.play("still")

	proximity.body_entered.connect(_on_proximity_body_entered)
	proximity.body_exited.connect(_on_proximity_body_exited)

	if character_manager == null:
		push_error("[Doctor] CharacterManager no asignado.")
		set_process(false)
		set_process_input(false)
		return

	if dialogue_manager == null:
		push_error("[Doctor] DialogueManager no asignado.")
		set_process(false)
		set_process_input(false)
		return

	if dialogue_manager.has_signal("speaker_talking_changed"):
		if not dialogue_manager.speaker_talking_changed.is_connected(
			_on_speaker_talking_changed
		):
			dialogue_manager.speaker_talking_changed.connect(
				_on_speaker_talking_changed
			)

	print("[Doctor] Sistema de interacción iniciado.")


func _process(_delta: float) -> void:
	
	interaction_label.visible = player_nearby and not interacting and interaction_enabled

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

	print("[Doctor] Personaje cerca: ", body.name)


func _on_proximity_body_exited(body: Node2D) -> void:
	if not body.is_in_group("playable_characters"):
		return

	print("[Doctor] Personaje salió: ", body.name)


# =========================================================
# INTERACTION - CLICK IZQUIERDO EN CUALQUIER LUGAR
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if not interaction_enabled:
		return

	if interacting or not player_nearby:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			_start_interaction()


func _start_interaction() -> void:
	if interacting or current_character == null:
		return

	if character_manager.call("is_player_locked"):
		return

	interacting = true
	indicator.visible = false

	character_manager.call("set_player_locked", true)

	print("[Doctor] Iniciando conversación.")

	await dialogue_manager.call("play_dialogue")

	if is_instance_valid(animated_sprite):
		animated_sprite.play("still")

	if is_instance_valid(character_manager):
		character_manager.call("set_player_locked", false)

	interacting = false

	print("[Doctor] Conversación terminada.")


# =========================================================
# ANIMACIONES
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


func set_talking(talking: bool) -> void:
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
		player_nearby = false
		current_character = null
