extends "res://scripts/player/character_1.gd"

func _ready() -> void:
	character_name = "Green"
	strength = 0.7

	max_speed = 36.0
	acceleration = 900.0
	deceleration = 1300.0

	gravity = 850.0
	character_height = 60.0
	jump_height_multiplier = 0.65
	jump_release_multiplier = 0.1
	coyote_time = 0.16

	bounce_duration = 0.40
	bounce_strength = 0.30
	bounce_stretch = 0.20
	bounce_overshoot = 0.10

	surface_bounce = 0.18
	minimum_bounce_speed = 35.0

	idle_frequency = 1.8
	idle_breathing = 0.020

	super._ready()

@export_group("Wall Jump")
@export var wall_jump_min_force: float = 160.0
@export var wall_jump_max_force: float = 250.0
@export var wall_jump_charge_time: float = 3.0
@export var wall_jump_horizontal_ratio: float = 0.85

var wall_grabbing: bool = false
var wall_normal: Vector2 = Vector2.ZERO
var wall_charge: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_controlled:
		wall_grabbing = false
		wall_normal = Vector2.ZERO
		wall_charge = 0.0
		super._physics_process(delta)
		return

	# Mientras está agarrado, permanece inmóvil en la pared.
	if wall_grabbing:
		velocity = Vector2.ZERO
		_handle_wall_charge(delta)
		return

	super._physics_process(delta)

	# Detectar contacto con una pared.
	if is_on_wall():
		wall_normal = get_wall_normal()

		if Input.is_action_just_pressed("ability"):
			wall_grabbing = true
			wall_charge = 0.0
			velocity = Vector2.ZERO


func _handle_wall_charge(delta: float) -> void:
	velocity = Vector2.ZERO

	if Input.is_action_pressed("ability"):
		wall_charge = minf(
			wall_charge + delta,
			wall_jump_charge_time
		)

	if Input.is_action_just_released("ability"):
		_execute_wall_jump()


func _execute_wall_jump() -> void:
	var charge_ratio := clampf(
		wall_charge / wall_jump_charge_time,
		0.0,
		1.0
	)

	var jump_force := lerpf(
		wall_jump_min_force,
		wall_jump_max_force,
		charge_ratio
	)

	velocity.x = wall_normal.x * jump_force * wall_jump_horizontal_ratio
	velocity.y = -jump_force

	wall_grabbing = false
	wall_charge = 0.0
	wall_normal = Vector2.ZERO

	coyote_timer = 0.0
	_play_impact_bounce()
