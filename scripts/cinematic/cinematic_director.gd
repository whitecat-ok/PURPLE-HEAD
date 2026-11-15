
extends Node

@export_group("References")
@export var character_manager: Node
@export var red: CharacterBody2D
@export var grandfather: Node2D
@export var dialogue_manager: CanvasLayer

@export_group("Cinematic")
@export var play_on_ready: bool = true
@export var matte_duration: float = 0.5

@export_group("Control Lock")
@export var unlock_controls_at_end: bool = true
@export var apply_control_delay: bool = true
@export_range(0.0, 30.0, 0.5) var control_lock_duration: float = 2.0

@export_group("Camera")
@export var camera_zoom: Vector2 = Vector2(1.5, 1.5)
@export var camera_offset: Vector2 = Vector2.ZERO
@export var camera_transition_duration: float = 0.8

@export_group("Red")
@export var lying_position: Vector2 = Vector2(0, 12)
@export var lying_rotation: float = 90.0
@export var standing_position: Vector2 = Vector2.ZERO

@export_group("Grandfather")
@export var grandfather_entry_offset: Vector2 = Vector2(180, 0)
@export var grandfather_final_offset: Vector2 = Vector2(65, 0)
@export var grandfather_wait_before_enter: float = 0.5
@export var grandfather_move_duration: float = 1.0

@export_group("Timing")
@export var wakeup_duration: float = 0.8

@onready var top_matte: ColorRect = $CanvasLayer/TopMate
@onready var bottom_matte: ColorRect = $CanvasLayer/ButtonMate

var camera: Camera2D
var red_sprite: Sprite2D

var matte_tween: Tween
var camera_tween: Tween

var cinematic_active: bool = false
var original_camera_zoom: Vector2


func _ready() -> void:
	top_matte.hide()
	bottom_matte.hide()

	top_matte.color = Color.BLACK
	bottom_matte.color = Color.BLACK

	top_matte.color.a = 0.0
	bottom_matte.color.a = 0.0

	if not _validate_references():
		return

	camera = character_manager.call("get_camera") as Camera2D

	if camera == null:
		push_error("CinematicDirector: No se encontró Camera2D.")
		return

	red_sprite = red.get_node_or_null("Sprite2D") as Sprite2D

	if red_sprite == null:
		push_error("CinematicDirector: No se encontró Sprite2D de Red.")
		return

	original_camera_zoom = camera.zoom

	dialogue_manager.call("set_camera", camera)
	dialogue_manager.call("set_default_speaker", grandfather)

	if grandfather.has_method("set_interaction_enabled"):
		grandfather.call("set_interaction_enabled", false)

	grandfather.hide()

	if play_on_ready:
		call_deferred("play_hospital_intro")


func _validate_references() -> bool:
	if character_manager == null:
		push_error("CinematicDirector: Falta CharacterManager.")
		return false

	if red == null:
		push_error("CinematicDirector: Falta Red.")
		return false

	if grandfather == null:
		push_error("CinematicDirector: Falta Grandfather.")
		return false

	if dialogue_manager == null:
		push_error("CinematicDirector: Falta DialogueManager.")
		return false

	return true


func show_mattes() -> void:
	await _animate_mattes(1.0)


func hide_mattes() -> void:
	await _animate_mattes(0.0)


func _animate_mattes(alpha: float) -> void:
	if matte_tween != null and matte_tween.is_running():
		matte_tween.kill()

	top_matte.show()
	bottom_matte.show()

	matte_tween = create_tween()
	matte_tween.set_parallel(true)
	matte_tween.set_ease(Tween.EASE_OUT)
	matte_tween.set_trans(Tween.TRANS_CUBIC)

	matte_tween.tween_property(
		top_matte,
		"color:a",
		alpha,
		matte_duration
	)

	matte_tween.tween_property(
		bottom_matte,
		"color:a",
		alpha,
		matte_duration
	)

	await matte_tween.finished

	if alpha <= 0.0:
		top_matte.hide()
		bottom_matte.hide()


func play_hospital_intro() -> void:
	if cinematic_active:
		return

	await begin_cinematic()

	red_sprite.position = lying_position
	red_sprite.rotation_degrees = lying_rotation

	await get_tree().create_timer(0.8).timeout

	await get_tree().create_timer(
		grandfather_wait_before_enter
	).timeout

	grandfather.global_position = (
		red.global_position + grandfather_entry_offset
	)

	grandfather.show()

	var grandfather_tween := create_tween()
	grandfather_tween.set_trans(Tween.TRANS_CUBIC)
	grandfather_tween.set_ease(Tween.EASE_OUT)

	grandfather_tween.tween_property(
		grandfather,
		"global_position",
		red.global_position + grandfather_final_offset,
		grandfather_move_duration
	)

	await grandfather_tween.finished

	var midpoint: Vector2 = (
		red.global_position + grandfather.global_position
	) / 2.0

	await move_camera(midpoint + camera_offset, camera_zoom)

	await dialogue_manager.call("play_dialogue")

	await play_red_wakeup()

	await finish_cinematic()


func begin_cinematic() -> void:
	cinematic_active = true

	character_manager.call("set_player_locked", true)
	character_manager.call("set_camera_follow", false)

	await show_mattes()

	await move_camera(
		red.global_position + camera_offset,
		camera_zoom
	)


func finish_cinematic() -> void:
	red_sprite.rotation_degrees = 0.0
	red_sprite.position = standing_position

	await move_camera(
		red.global_position + camera_offset,
		original_camera_zoom
	)

	character_manager.call("set_camera_follow", true)

	await hide_mattes()

	if unlock_controls_at_end:
		character_manager.call("set_player_locked", false)

	elif apply_control_delay:
		await get_tree().create_timer(control_lock_duration).timeout
		character_manager.call("set_player_locked", false)

	if grandfather.has_method("set_interaction_enabled"):
		grandfather.call("set_interaction_enabled", true)

	cinematic_active = false


func play_red_wakeup() -> void:
	var wake_tween := create_tween()
	wake_tween.set_trans(Tween.TRANS_BACK)
	wake_tween.set_ease(Tween.EASE_OUT)

	wake_tween.tween_property(
		red_sprite,
		"rotation_degrees",
		0.0,
		wakeup_duration
	)

	wake_tween.parallel().tween_property(
		red_sprite,
		"position",
		standing_position,
		wakeup_duration
	)

	await wake_tween.finished


func move_camera(
	destination: Vector2,
	destination_zoom: Vector2
) -> void:
	if camera_tween != null and camera_tween.is_running():
		camera_tween.kill()

	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_ease(Tween.EASE_IN_OUT)

	camera_tween.tween_property(
		camera,
		"global_position",
		destination,
		camera_transition_duration
	)

	camera_tween.tween_property(
		camera,
		"zoom",
		destination_zoom,
		camera_transition_duration
	)

	await camera_tween.finished
