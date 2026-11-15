
extends Control

@export_file("*.tscn") var hospital_scene: String = "res://hospital.tscn"

var can_start: bool = true


func _ready() -> void:
	print("[MainMenu] Menú iniciado.")


func _unhandled_input(event: InputEvent) -> void:
	if not can_start:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_SPACE:
			_start_game()


func _start_game() -> void:
	can_start = false

	print("[MainMenu] Cargando hospital...")

	var error := get_tree().change_scene_to_file(hospital_scene)

	if error != OK:
		can_start = true
		push_error("[MainMenu] Error cargando hospital: " + str(error))
