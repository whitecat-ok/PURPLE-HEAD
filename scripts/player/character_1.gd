
extends CharacterBody2D

# IDENTIDAD
@export_group("Character")
@export var character_name: String = "Red"
@export var strength: float = 1.0
@export var is_controlled: bool = false

# MOVIMIENTO
@export_group("Movement")
@export var max_speed: float = 50.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 1600.0

# SALTO
@export_group("Jump")
@export var gravity: float = 980.0
@export var character_height: float = 40.0
@export var jump_height_multiplier: float = 0.3
@export var jump_release_multiplier: float = 0.1
@export var coyote_time: float = 0.12

# BOUNCE VISUAL
@export_group("Bounce")
@export var bounce_duration: float = 0.35
@export var bounce_strength: float = 0.40
@export var bounce_stretch: float = 0.25
@export var bounce_overshoot: float = 0.12

# REBOTE FÍSICO
@export_group("Surface Bounce")
@export_range(0.0, 1.0) var surface_bounce: float = 0.18
@export var minimum_bounce_speed: float = 35.0

# IDLE
@export_group("Idle")
@export var idle_frequency: float = 2.0
@export var idle_breathing: float = 0.025

# EMPUJE ENTRE PERSONAJES
@export_group("Character Push")
@export var character_push_acceleration: float = 450.0

@onready var sprite: Sprite2D = $Sprite2D

var coyote_timer: float = 0.0
var sprite_base_scale: Vector2
var sprite_base_position: Vector2

var bounce_tween: Tween
var idle_time: float = 0.0


func _ready() -> void:
	sprite_base_scale = sprite.scale
	sprite_base_position = sprite.position

	input_pickable = true
	add_to_group("playable_characters")

	print(
		"[Character] ",
		character_name,
		" | Controlado: ",
		is_controlled
	)


func _physics_process(delta: float) -> void:
	_handle_horizontal_movement(delta)
	_handle_gravity(delta)

	if is_controlled:
		_handle_jump()

	var was_on_floor: bool = is_on_floor()
	var incoming_velocity: Vector2 = velocity

	move_and_slide()

	_apply_surface_bounce(incoming_velocity)
	_apply_push(incoming_velocity, delta)

	if not was_on_floor and is_on_floor():
		_play_landing_bounce()


func _process(delta: float) -> void:
	_update_idle_animation(delta)


# =========================================================
# MOVIMIENTO HORIZONTAL
# =========================================================

func _handle_horizontal_movement(delta: float) -> void:
	var direction: float = 0.0

	if is_controlled:
		direction = Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = move_toward(
			velocity.x,
			direction * max_speed,
			acceleration * delta
		)

		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			deceleration * delta
		)


# =========================================================
# GRAVEDAD
# =========================================================

func _handle_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(
			0.0,
			coyote_timer - delta
		)

		velocity.y += gravity * delta


# =========================================================
# SALTO
# =========================================================

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if coyote_timer > 0.0:
			var jump_height: float = (
				character_height * jump_height_multiplier
			)

			velocity.y = -sqrt(
				2.0 * gravity * jump_height
			)

			coyote_timer = 0.0

	if Input.is_action_just_released("jump"):
		if velocity.y < 0.0:
			velocity.y *= jump_release_multiplier


# =========================================================
# REBOTE CONTRA SUPERFICIES
# =========================================================

func _apply_surface_bounce(incoming_velocity: Vector2) -> void:
	var processed_bodies: Dictionary = {}

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		var collider := collision.get_collider()

		var impact_speed: float = -incoming_velocity.dot(normal)

		if impact_speed < minimum_bounce_speed:
			continue

		if collider != null:
			var collider_id: int = collider.get_instance_id()

			if processed_bodies.has(collider_id):
				continue

			processed_bodies[collider_id] = true

		var inward_speed: float = velocity.dot(normal)

		if inward_speed < 0.0:
			velocity -= normal * inward_speed

		velocity += normal * impact_speed * surface_bounce

		if collider is StaticBody2D:
			if collider.has_method("play_bounce"):
				collider.play_bounce(-normal)

		if absf(normal.x) > 0.5:
			_play_impact_bounce()


# =========================================================
# EMPUJE ENTRE PERSONAJES
# =========================================================

func _apply_push(
	incoming_velocity: Vector2,
	delta: float
) -> void:
	var processed_bodies: Dictionary = {}

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var target := collision.get_collider()

		if target == null or target == self:
			continue

		if not target is CharacterBody2D:
			continue

		if not target.is_in_group("playable_characters"):
			continue

		var target_id: int = target.get_instance_id()

		if processed_bodies.has(target_id):
			continue

		processed_bodies[target_id] = true

		var normal := collision.get_normal()
		var push_direction := -normal

		var approach_speed: float = -incoming_velocity.dot(normal)

		if approach_speed <= 1.0:
			continue

		var target_strength: float = target.get("strength")

		var momentum: float = clampf(
			approach_speed / maxf(max_speed, 1.0),
			0.0,
			1.0
		)

		var strength_ratio: float = clampf(
			strength / maxf(target_strength, 0.1),
			0.25,
			2.5
		)

		target.velocity += (
			push_direction
			* character_push_acceleration
			* strength_ratio
			* momentum
			* delta
		)


# =========================================================
# BOUNCE DE ATERRIZAJE
# =========================================================

func _play_landing_bounce() -> void:
	_play_bounce_animation(
		bounce_strength,
		bounce_stretch,
		bounce_overshoot,
		bounce_duration
	)


# =========================================================
# BOUNCE DE IMPACTO
# =========================================================

func _play_impact_bounce() -> void:
	_play_bounce_animation(
		bounce_strength * 0.65,
		bounce_stretch * 0.65,
		bounce_overshoot * 0.65,
		bounce_duration * 0.65
	)


# =========================================================
# ANIMACIÓN GENERAL DE REBOTE
# =========================================================

func _play_bounce_animation(
	compression: float,
	stretch: float,
	overshoot: float,
	duration: float
) -> void:
	if bounce_tween and bounce_tween.is_running():
		bounce_tween.kill()

	sprite.scale = sprite_base_scale

	bounce_tween = create_tween()

	bounce_tween.tween_property(
		sprite,
		"scale",
		Vector2(
			sprite_base_scale.x * (1.0 + compression),
			sprite_base_scale.y * (1.0 - compression)
		),
		duration * 0.20
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	bounce_tween.tween_property(
		sprite,
		"scale",
		Vector2(
			sprite_base_scale.x * (1.0 - stretch),
			sprite_base_scale.y * (1.0 + stretch)
		),
		duration * 0.30
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	bounce_tween.tween_property(
		sprite,
		"scale",
		sprite_base_scale * (1.0 + overshoot),
		duration * 0.20
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	bounce_tween.tween_property(
		sprite,
		"scale",
		sprite_base_scale,
		duration * 0.30
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# =========================================================
# IDLE
# =========================================================

func _update_idle_animation(delta: float) -> void:
	if bounce_tween and bounce_tween.is_running():
		return

	if is_controlled or not is_on_floor():
		sprite.scale = sprite_base_scale
		return

	idle_time += delta * idle_frequency

	var pulse: float = 1.0 + sin(idle_time) * idle_breathing

	sprite.scale = sprite_base_scale * pulse
