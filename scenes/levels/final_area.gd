
extends Area2D

@export_group("Final Scene")
@export_file("*.tscn") var final_scene_path: String = "res://final.tscn"

var transitioning: bool = false


func _ready() -> void:
	monitoring = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	print("[FinalArea] Zona final preparada.")
	print("[FinalArea] Escena final: ", final_scene_path)


func _on_body_entered(body: Node2D) -> void:
	if transitioning:
		return

	if not body is CharacterBody2D:
		return

	if not body.is_in_group("playable_characters"):
		return

	print("[FinalArea] Personaje detectado: ", body.name)

	transitioning = true
	call_deferred("_change_to_final")


func _change_to_final() -> void:
	print("[FinalArea] Cargando pantalla final...")

	var error: Error = get_tree().change_scene_to_file(final_scene_path)

	if error != OK:
		transitioning = false
		push_error(
			"[FinalArea] No se pudo cargar la escena: "
			+ final_scene_path
		)
		push_error("[FinalArea] Código de error: " + str(error))
	else:
		print("[FinalArea] Transición iniciada.")
