
extends Node

signal character_selected(character: CharacterBody2D)
signal character_transformed(previous: CharacterBody2D, current: CharacterBody2D)

@export_group("Initial Character")
@export var starting_character: CharacterBody2D

@export_group("Transformation Characters")
@export var yellow_character: CharacterBody2D
@export var green_character: CharacterBody2D

@onready var camera: Camera2D = $Camera2D

var selected_character: CharacterBody2D
var characters: Array[Node] = []

var camera_follow_enabled: bool = true
var player_locked: bool = false
var is_transforming: bool = false

var camera_tween: Tween
var default_camera_zoom: Vector2

var return_start_position: Vector2
var return_start_zoom: Vector2

# Posiciones originales de reserva.
var home_positions: Dictionary = {}

# Configuración física original.
var original_collision_layers: Dictionary = {}
var original_collision_masks: Dictionary = {}
var original_physics_states: Dictionary = {}

# Temporizador único de transformación.
var transformation_timer: Timer
var active_candy_color: String = ""
var active_candy_duration: float = 0.0
var active_candy_slot_index: int = -1


func _ready() -> void:
	characters = get_tree().get_nodes_in_group("playable_characters")

	camera.enabled = true
	camera.make_current()

	default_camera_zoom = camera.zoom

	# Creamos el temporizador.
	transformation_timer = Timer.new()
	transformation_timer.one_shot = true
	transformation_timer.timeout.connect(_on_transformation_timeout)
	add_child(transformation_timer)

	# Guardamos posiciones y propiedades originales.
	for node in characters:
		if not node is CharacterBody2D:
			continue

		var character := node as CharacterBody2D

		home_positions[character] = character.global_position
		original_collision_layers[character] = character.collision_layer
		original_collision_masks[character] = character.collision_mask
		original_physics_states[character] = character.is_physics_processing()

		character.set("is_controlled", false)

	# Validamos el personaje inicial.
	if starting_character == null:
		push_error("CharacterManager: No hay personaje inicial asignado.")
		return

	if not characters.has(starting_character):
		push_error("CharacterManager: El personaje inicial no está en playable_characters.")
		return

	if not _validate_transformation_characters():
		return

	# Desactivamos todos los personajes.
	for node in characters:
		if node is CharacterBody2D:
			_set_character_active(node as CharacterBody2D, false)

	# Activamos únicamente a Red.
	selected_character = starting_character

	_set_character_active(starting_character, true)
	starting_character.set("is_controlled", true)

	camera.global_position = starting_character.global_position

	# Escuchamos el consumo de dulces.
	if not CandyInventory.candy_consumed.is_connected(_on_candy_consumed):
		CandyInventory.candy_consumed.connect(_on_candy_consumed)

	print("[CharacterManager] Sistema de personajes iniciado.")
	print("[CharacterManager] Personaje inicial: ", starting_character.name)


func _validate_transformation_characters() -> bool:
	var required_characters: Array[CharacterBody2D] = [
		yellow_character,
		green_character
	]

	for character in required_characters:
		if character == null:
			push_error("CharacterManager: Falta asignar un personaje de transformación.")
			return false

		if not characters.has(character):
			push_error(
				"CharacterManager: ",
				character.name,
				" no pertenece al grupo playable_characters."
			)
			return false

		if character == starting_character:
			push_error("CharacterManager: Un personaje secundario no puede ser Red.")
			return false

	return true


func _process(_delta: float) -> void:
	if not camera_follow_enabled:
		return

	if selected_character and is_instance_valid(selected_character):
		camera.global_position = selected_character.global_position


# --------------------------------------------------
# CHARACTER ACTIVATION
# --------------------------------------------------

func _set_character_active(
	character: CharacterBody2D,
	active: bool
) -> void:

	if not is_instance_valid(character):
		return

	character.visible = active
	character.input_pickable = active

	if active:
		character.collision_layer = original_collision_layers[character]
		character.collision_mask = original_collision_masks[character]

		character.set_physics_process(
			original_physics_states[character]
		)

	else:
		character.collision_layer = 0
		character.collision_mask = 0

		character.set_physics_process(false)
		character.set("is_controlled", false)


# --------------------------------------------------
# CANDY CONSUMPTION
# --------------------------------------------------

func _on_candy_consumed(
	slot_index: int,
	candy_color: String,
	duration: float
) -> void:

	print(
		"[CharacterManager] Dulce recibido: ",
		candy_color,
		" | Slot: ",
		slot_index + 1,
		" | Duración: ",
		duration,
		" segundos"
	)

	transform_to_candy(candy_color, duration, slot_index)


func transform_to_candy(
	candy_color: String,
	duration: float,
	slot_index: int
) -> void:

	if player_locked or is_transforming:
		print("[CharacterManager] Transformación bloqueada.")
		return

	if duration <= 0.0:
		push_warning("[CharacterManager] Duración inválida.")
		return

	var target_character: CharacterBody2D = null

	match candy_color:
		"yellow":
			target_character = yellow_character

		"green":
			target_character = green_character

		_:
			push_warning(
				"[CharacterManager] Dulce desconocido: ",
				candy_color
			)
			return

	if target_character == null:
		return

	if selected_character == null:
		return

	# Cancelamos cualquier temporizador anterior.
	transformation_timer.stop()

	active_candy_color = candy_color
	active_candy_duration = duration
	active_candy_slot_index = slot_index

	# Si ya tenemos ese personaje, renovamos el tiempo.
	if target_character == selected_character:
		print(
			"[CharacterManager] Dulce del mismo color. "
			+ "Temporizador reiniciado."
		)

		_start_transformation_timer(duration)
		return

	# Transformamos al nuevo personaje.
	_perform_transformation(target_character)

	# Iniciamos el temporizador.
	_start_transformation_timer(duration)


# --------------------------------------------------
# TRANSFORMATION
# --------------------------------------------------

func _perform_transformation(
	target_character: CharacterBody2D
) -> void:

	if is_transforming:
		return

	if target_character == null:
		return

	if selected_character == null:
		return

	if not home_positions.has(selected_character):
		push_error("[CharacterManager] No existe posición de reserva del personaje anterior.")
		return

	if not home_positions.has(target_character):
		push_error("[CharacterManager] No existe posición de reserva del personaje nuevo.")
		return

	is_transforming = true

	var previous_character := selected_character

	# Guardamos la posición actual.
	var transformation_position: Vector2 = previous_character.global_position

	print(
		"[CharacterManager] Transformando ",
		previous_character.name,
		" -> ",
		target_character.name
	)

	# Bloqueamos temporalmente el control.
	set_player_locked(true)

	# Devolvemos el personaje anterior a su reserva.
	previous_character.global_position = home_positions[previous_character]

	_set_character_active(previous_character, false)

	# Aparecemos el nuevo personaje en la posición anterior.
	target_character.global_position = transformation_position

	_set_character_active(target_character, true)

	# Actualizamos el personaje seleccionado.
	selected_character = target_character

	# Actualizamos la cámara.
	if camera_follow_enabled:
		_kill_camera_tween()
		camera.global_position = transformation_position

	# Desbloqueamos el nuevo personaje.
	set_player_locked(false)

	character_selected.emit(selected_character)

	character_transformed.emit(
		previous_character,
		selected_character
	)

	print(
		"[CharacterManager] Transformación completada: ",
		selected_character.name
	)

	is_transforming = false


# --------------------------------------------------
# TRANSFORMATION TIMER
# --------------------------------------------------

func _start_transformation_timer(duration: float) -> void:
	transformation_timer.stop()
	transformation_timer.start(duration)

	print(
		"[CharacterManager] Temporizador iniciado: ",
		duration,
		" segundos."
	)


func _on_transformation_timeout() -> void:
	print("[CharacterManager] ¡El dulce perdió su efecto!")

	# Si ya estamos en Red, no hace falta transformar.
	if selected_character == starting_character:
		_clear_active_candy()
		return

	# Si hay un bloqueo activo, esperamos.
	if player_locked or is_transforming:
		transformation_timer.start(0.25)
		return

	print("[CharacterManager] Regresando automáticamente a Red.")

	_clear_active_candy()
	_perform_transformation(starting_character)


func _clear_active_candy() -> void:
	active_candy_color = ""
	active_candy_duration = 0.0
	active_candy_slot_index = -1


func get_active_candy_color() -> String:
	return active_candy_color


func get_active_candy_slot_index() -> int:
	return active_candy_slot_index


func get_active_candy_duration() -> float:
	return active_candy_duration


func get_remaining_transformation_time() -> float:
	if transformation_timer == null:
		return 0.0

	if transformation_timer.is_stopped():
		return 0.0

	return transformation_timer.time_left


# --------------------------------------------------
# CHARACTER SELECTION
# --------------------------------------------------

func select_character(character: CharacterBody2D) -> void:
	if player_locked or is_transforming:
		return

	if not characters.has(character):
		return

	if not character.visible:
		return

	if selected_character == character:
		return

	if selected_character:
		selected_character.set("is_controlled", false)

	selected_character = character
	selected_character.set("is_controlled", true)

	character_selected.emit(selected_character)

	print("[CharacterManager] Character selected: ", character.name)


func get_selected_character() -> CharacterBody2D:
	return selected_character


# --------------------------------------------------
# PLAYER LOCK
# --------------------------------------------------

func set_player_locked(locked: bool) -> void:
	player_locked = locked

	if player_locked:
		for character in characters:
			if is_instance_valid(character):
				character.set("is_controlled", false)

		print("[CharacterManager] Player locked.")

	else:
		for character in characters:
			if is_instance_valid(character):
				character.set("is_controlled", false)

		if selected_character and is_instance_valid(selected_character):
			selected_character.set("is_controlled", true)

		print("[CharacterManager] Player unlocked.")


func is_player_locked() -> bool:
	return player_locked


# --------------------------------------------------
# CAMERA FOLLOW
# --------------------------------------------------

func set_camera_follow(enabled: bool) -> void:
	camera_follow_enabled = enabled


func get_camera() -> Camera2D:
	return camera


# --------------------------------------------------
# CAMERA ZONE TRANSITIONS
# --------------------------------------------------

func move_camera_to(
	destination: Vector2,
	destination_zoom: Vector2,
	duration: float
) -> void:

	if camera == null:
		return

	if player_locked:
		return

	camera_follow_enabled = false

	_kill_camera_tween()

	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.set_trans(Tween.TRANS_CUBIC)

	camera_tween.tween_property(
		camera,
		"global_position",
		destination,
		duration
	)

	camera_tween.tween_property(
		camera,
		"zoom",
		destination_zoom,
		duration
	)

	print("[CharacterManager] Moving camera to zone: ", destination)


func return_camera_to_character(duration: float) -> void:
	if camera == null:
		return

	if player_locked:
		return

	if selected_character == null:
		return

	camera_follow_enabled = false

	_kill_camera_tween()

	return_start_position = camera.global_position
	return_start_zoom = camera.zoom

	camera_tween = create_tween()
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.set_trans(Tween.TRANS_CUBIC)

	camera_tween.tween_method(
		_update_camera_return,
		0.0,
		1.0,
		duration
	)

	camera_tween.finished.connect(_on_camera_return_finished)

	print("[CharacterManager] Returning camera to character.")


func _update_camera_return(progress: float) -> void:
	if not is_instance_valid(selected_character):
		return

	camera.global_position = return_start_position.lerp(
		selected_character.global_position,
		progress
	)

	camera.zoom = return_start_zoom.lerp(
		default_camera_zoom,
		progress
	)


func _on_camera_return_finished() -> void:
	if player_locked:
		return

	camera_follow_enabled = true


func _kill_camera_tween() -> void:
	if camera_tween != null and camera_tween.is_running():
		camera_tween.kill()
