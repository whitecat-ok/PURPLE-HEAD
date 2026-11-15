
extends Node2D

@export_file("*.tscn") var hospital_scene: String = "res://hospital.tscn"

var can_start: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if not can_start:
		return

	if event.is_action_pressed("jump"):
		can_start = false

		var error := get_tree().change_scene_to_file(hospital_scene)

		if error != OK:
			can_start = true
			push_error("No se pudo cargar hospital.tscn. Error: " + str(error))
