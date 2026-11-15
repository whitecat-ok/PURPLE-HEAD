
extends Area2D

const CANDY_COLOR: String = "green"

@export_group("References")
@export var character_manager: Node

@export_group("Candy")
@export_range(1.0, 300.0, 1.0, "or_greater")
var candy_duration: float = 15.0

@export_group("Interaction")
@export var interaction_enabled: bool = true

@onready var candy_sprite: Sprite2D = $Sprite_Green
@onready var candy_light: PointLight2D = $PointLight2D_Green
@onready var proximity: Area2D = $Proximity
@onready var indicator: Sprite2D = $Indicator

var player_nearby: bool = false


func _ready() -> void:
	indicator.visible = false
	candy_sprite.visible = true
	candy_light.visible = true

	proximity.body_entered.connect(_on_body_entered)
	proximity.body_exited.connect(_on_body_exited)

	if not is_instance_valid(character_manager):
		push_error("[CandyGreen] CharacterManager no asignado.")
		set_process(false)
		set_process_input(false)
		return

	print("[CandyGreen] Iniciada. Duración: ", candy_duration)


func _process(_delta: float) -> void:
	if not interaction_enabled:
		player_nearby = false
		indicator.visible = false
		return

	var selected: CharacterBody2D = (
		character_manager.call("get_selected_character")
		as CharacterBody2D
	)

	var overlapping := proximity.get_overlapping_bodies()

	player_nearby = (
		selected != null
		and overlapping.has(selected)
		and selected.is_in_group("playable_characters")
	)

	indicator.visible = player_nearby


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("playable_characters"):
		print("[CandyGreen] Personaje cerca: ", body.name)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("playable_characters"):
		print("[CandyGreen] Personaje salió: ", body.name)


func _input(event: InputEvent) -> void:
	if not interaction_enabled or not player_nearby:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			_collect_candy()


func _collect_candy() -> void:
	var collected: bool = CandyInventory.add_candy(
		CANDY_COLOR,
		candy_duration
	)

	if collected:
		print("[CandyGreen] Dulce recogido. Duración: ", candy_duration)
	else:
		print("[CandyGreen] No se pudo recoger el dulce.")


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled

	if not enabled:
		player_nearby = false
		indicator.visible = false
