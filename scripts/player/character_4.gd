
extends "res://scripts/player/character_1.gd"

var phase_active: bool = false
var affected_bodies: Array[StaticBody2D] = []

@export_group("Blue Ability")
@export var max_phase_range: float = 0.0

var jumps_used: int = 0
var max_jumps: int = 2


func _ready() -> void:
	character_name = "Blue"
	strength = 0.4

	max_speed = 68.0
	acceleration = 1900.0
	deceleration = 2100.0

	gravity = 1150.0
	character_height = 24.0
	jump_height_multiplier = 0.4
	jump_release_multiplier = 0.1
	coyote_time = 0.10

	bounce_duration = 0.25
	bounce_strength = 0.25
	bounce_stretch = 0.15
	bounce_overshoot = 0.08

	surface_bounce = 0.18
	minimum_bounce_speed = 35.0

	idle_frequency = 2.8
	idle_breathing = 0.018

	super._ready()


func _physics_process(delta: float) -> void:
	if not is_controlled:
		_deactivate_phase()
		super._physics_process(delta)
		return

	if Input.is_action_just_pressed("ability"):
		phase_active = true

	if phase_active:
		_update_phase_collisions()
	else:
		_deactivate_phase()

	super._physics_process(delta)


# =========================================================
# FASE
# =========================================================

func _update_phase_collisions() -> void:
	var bodies := get_tree().get_nodes_in_group("blue_passable")

	for body in bodies:
		if not body is StaticBody2D:
			continue

		var static_body := body as StaticBody2D

		if not is_instance_valid(static_body):
			continue

		if max_phase_range > 0.0:
			if global_position.distance_to(static_body.global_position) > max_phase_range:
				continue

		if not affected_bodies.has(static_body):
			add_collision_exception_with(static_body)
			affected_bodies.append(static_body)


func _deactivate_phase() -> void:
	phase_active = false

	for body in affected_bodies:
		if is_instance_valid(body):
			remove_collision_exception_with(body)

	affected_bodies.clear()


# =========================================================
# DOBLE SALTO
# =========================================================

func _handle_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_used = 0
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y += gravity * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		var can_first_jump := is_on_floor() or coyote_timer > 0.0
		var can_second_jump := not is_on_floor() and jumps_used < max_jumps

		if can_first_jump or can_second_jump:
			var jump_height := character_height * jump_height_multiplier

			velocity.y = -sqrt(2.0 * gravity * jump_height)

			jumps_used += 1
			coyote_timer = 0.0

	if Input.is_action_just_released("jump"):
		if velocity.y < 0.0:
			velocity.y *= jump_release_multiplier


# =========================================================
# LIMPIEZA
# =========================================================

func _exit_tree() -> void:
	_deactivate_phase()
