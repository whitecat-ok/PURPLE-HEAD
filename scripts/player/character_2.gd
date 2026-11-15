extends "res://scripts/player/character_1.gd"

var magnetic_active: bool = false
var attached_normal: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not is_controlled:
		magnetic_active = false
		attached_normal = Vector2.ZERO
		up_direction = Vector2.UP
		super._physics_process(delta)
		return

	if Input.is_action_just_pressed("ability"):
		magnetic_active = true

	if not magnetic_active:
		super._physics_process(delta)
		return

	_handle_magnetic_movement(delta)


func _handle_magnetic_movement(delta: float) -> void:
	var was_on_floor := is_on_floor()
	var incoming_velocity := velocity

	if attached_normal != Vector2.ZERO:
		up_direction = attached_normal
		var horizontal := Input.get_axis("move_left", "move_right")
		var vertical := 0.0

		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			vertical -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			vertical += 1.0

		var tangent := Vector2(-attached_normal.y, attached_normal.x)
		var direction := horizontal if absf(tangent.x) > 0.5 else vertical

		velocity = tangent * direction * max_speed
		velocity -= attached_normal * 65.0

		if direction != 0.0:
			sprite.flip_h = direction < 0.0
	else:
		up_direction = Vector2.UP
		_handle_horizontal_movement(delta)
		_handle_gravity(delta)

	move_and_slide()

	# Detectar paredes y techos para adherirse.
	var found_surface := false

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()

		if normal.x != 0.0 and absf(normal.x) > 0.5:
			attached_normal = normal
			found_surface = true
			break

		if normal.y > 0.5:
			attached_normal = normal
			found_surface = true
			break

	if not found_surface and attached_normal != Vector2.ZERO:
		# Mantener la adhesión mientras exista contacto con la superficie.
		var still_touching := false
		for i in get_slide_collision_count():
			var normal := get_slide_collision(i).get_normal()
			if normal.dot(attached_normal) > 0.7:
				still_touching = true
				break

		if not still_touching:
			attached_normal = Vector2.ZERO
			up_direction = Vector2.UP

	_apply_surface_bounce(incoming_velocity)
	_apply_push(incoming_velocity, delta)

	if not was_on_floor and is_on_floor():
		_play_landing_bounce()
