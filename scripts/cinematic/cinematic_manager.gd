
extends Node

@export_group("References")
@export var character_manager: Node
@export var red: CharacterBody2D

@export_group("Cinematic Camera")
@export var camera_zoom: Vector2 = Vector2(1.25, 1.25)
@export var camera_offset: Vector2 = Vector2(0, -20)

@export_group("Mattes")
@export var matte_height: float = 100.0
@export var matte_duration: float = 0.5

@export_group("Hospital Animation")
@export var lying_rotation: float = 90.0
@export var lying_position: Vector2 = Vector2(0, 0)
@export var standing_position: Vector2 = Vector2(0, 0)
@export var wake_duration: float = 1.0
@export var stand_duration: float = 1.2

@onready var top_matte: ColorRect = $CanvasLayer/TopMatte
@onready var bottom_matte: ColorRect = $CanvasLayer/BottomMatte

var camera: Camera2D
var cinematic_tween: Tween
var cinematic_active: bool = false


func _ready() -> void:
	top_matte.color = Color.BLACK
	bottom_matte.color = Color.BLACK

	top_matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_matte.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_mattes()

	camera = character_manager.get_camera()

	hide_mattes()


func _setup_mattes() -> void:
	top_matte.anchor_left = 0.0
	top_matte.anchor_right = 1.0
	top_matte.anchor_top = 0.0
	top_matte.anchor_bottom = 0.0

	top_matte.offset_left = 0.0
	top_matte.offset_right = 0.0
	top_matte.offset_top = 0.0
	top_matte.offset_bottom = 0.0

	bottom_matte.anchor_left = 0.0
	bottom_matte.anchor_right = 1.0
	bottom_matte.anchor_top = 1.0
	bottom_matte.anchor_bottom = 1.0

	bottom_matte.offset_left = 0.0
	bottom_matte.offset_right = 0.0
	bottom_matte.offset_top = 0.0
	bottom_matte.offset_bottom = 0.0


# MOSTRAR MATTE

func show_mattes() -> void:
	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		top_matte,
		"offset_bottom",
		matte_height,
		matte_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		bottom_matte,
		"offset_top",
		-matte_height,
		matte_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished


# OCULTAR MATTE

func hide_mattes() -> void:
	top_matte.offset_bottom = 0.0
	bottom_matte.offset_top = 0.0


func close_mattes() -> void:
	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		top_matte,
		"offset_bottom",
		0.0,
		matte_duration
	)

	tween.tween_property(
		bottom_matte,
		"offset_top",
		0.0,
		matte_duration
	)

	await tween.finished


# INICIAR CINEMÁTICA

func begin_cinematic() -> void:
	if cinematic_active:
		return

	cinematic_active = true

	character_manager.set_camera_follow(false)

	if red:
		red.set("is_controlled", false)
		red.set_physics_process(false)
		red.set_process(false)

	await show_mattes()


# TERMINAR CINEMÁTICA

func end_cinematic() -> void:
	if not cinematic_active:
		return

	await close_mattes()

	if red:
		red.set_physics_process(true)
		red.set_process(true)

	character_manager.set_camera_follow(true)

	cinematic_active = false


# MOVER CÁMARA

func move_camera(
	target_position: Vector2,
	duration: float = 1.0
) -> void:

	var tween := create_tween()

	tween.tween_property(
		camera,
		"global_position",
		target_position,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished


# ZOOM CINEMATOGRÁFICO

func change_zoom(
	target_zoom: Vector2,
	duration: float = 1.0
) -> void:

	var tween := create_tween()

	tween.tween_property(
		camera,
		"zoom",
		target_zoom,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished


# HOSPITAL: RED DESPIERTA Y SE LEVANTA

func play_hospital_wakeup() -> void:
	if not red:
		push_error("CinematicDirector: Red is not assigned.")
		return

	await begin_cinematic()

	camera.global_position = red.global_position + camera_offset
	camera.zoom = camera_zoom

	var sprite: Sprite2D = red.get_node("Sprite2D")

	# POSICIÓN INICIAL: ACOSTADO

	sprite.position = lying_position
	sprite.rotation_degrees = lying_rotation

	await get_tree().create_timer(0.8).timeout

	# DESPERTAR: PEQUEÑO MOVIMIENTO

	var wake_tween := create_tween()

	wake_tween.tween_property(
		sprite,
		"rotation_degrees",
		lying_rotation - 8.0,
		wake_duration * 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	wake_tween.tween_property(
		sprite,
		"rotation_degrees",
		lying_rotation,
		wake_duration * 0.5
	)

	await wake_tween.finished

	# INCORPORARSE

	var stand_tween := create_tween()

	stand_tween.set_parallel(true)

	stand_tween.tween_property(
		sprite,
		"rotation_degrees",
		0.0,
		stand_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	stand_tween.tween_property(
		sprite,
		"position",
		standing_position,
		stand_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await stand_tween.finished

	# RECUPERAR CONTROL

	await end_cinematic()

	sprite.rotation_degrees = 0.0
	sprite.position = standing_position

	print("Hospital cinematic finished.")
