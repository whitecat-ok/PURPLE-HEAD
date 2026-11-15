
extends Area2D

@export_group("References")
@export var character_manager: Node

@export_group("Camera")
@export var target_position: Vector2
@export var target_zoom: Vector2 = Vector2(2.0, 2.0)

@export_group("Transition")
@export_range(0.05, 5.0, 0.05)
var transition_duration: float = 0.8

@export var return_on_exit: bool = true

@export_group("Indicator 1")
@export var indicator_1: Sprite2D
@export var indicator_1_position: Vector2

@export_group("Indicator 2")
@export var indicator_2: Sprite2D
@export var indicator_2_position: Vector2

@export_group("Indicator 3")
@export var indicator_3: Sprite2D
@export var indicator_3_position: Vector2

@export_group("Indicator 4")
@export var indicator_4: Sprite2D
@export var indicator_4_position: Vector2

@export_group("Indicator 5")
@export var indicator_5: Sprite2D
@export var indicator_5_position: Vector2

@export_group("Indicator 6")
@export var indicator_6: Sprite2D
@export var indicator_6_position: Vector2

@export_group("Indicator 7")
@export var indicator_7: Sprite2D
@export var indicator_7_position: Vector2

@export_group("Indicator 8")
@export var indicator_8: Sprite2D
@export var indicator_8_position: Vector2

@export_group("Indicator 9")
@export var indicator_9: Sprite2D
@export var indicator_9_position: Vector2

@export_group("Indicator 10")
@export var indicator_10: Sprite2D
@export var indicator_10_position: Vector2

var active_character: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_update_indicators(false)

	if character_manager == null:
		push_error("CameraZone: CharacterManager no asignado.")
		set_deferred("monitoring", false)
		return

	if not character_manager.has_method("move_camera_to"):
		push_error("CameraZone: CharacterManager no tiene move_camera_to().")
		set_deferred("monitoring", false)
		return

	print("[CameraZone] Preparada: ", get_path())


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("playable_characters"):
		return

	if character_manager.call("is_player_locked"):
		return

	var selected = character_manager.call("get_selected_character")

	if selected != body:
		return

	active_character = body
	_update_indicators(true)

	print("[CameraZone] Entró: ", body.name)

	character_manager.call(
		"move_camera_to",
		target_position,
		target_zoom,
		transition_duration
	)


func _on_body_exited(body: Node2D) -> void:
	if body != active_character:
		return

	active_character = null
	_update_indicators(false)

	print("[CameraZone] Salió: ", body.name)

	if return_on_exit:
		character_manager.call(
			"return_camera_to_character",
			transition_duration
		)


func _update_indicators(is_inside: bool) -> void:
	var indicators: Array[Sprite2D] = [
		indicator_1,
		indicator_2,
		indicator_3,
		indicator_4,
		indicator_5,
		indicator_6,
		indicator_7,
		indicator_8,
		indicator_9,
		indicator_10
	]

	var positions: Array[Vector2] = [
		indicator_1_position,
		indicator_2_position,
		indicator_3_position,
		indicator_4_position,
		indicator_5_position,
		indicator_6_position,
		indicator_7_position,
		indicator_8_position,
		indicator_9_position,
		indicator_10_position
	]

	for i in range(indicators.size()):
		var indicator := indicators[i]

		if not is_instance_valid(indicator):
			continue

		if is_inside:
			indicator.global_position = positions[i]

		indicator.visible = is_inside
