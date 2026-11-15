
extends Control

const MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"

@onready var intro_video: VideoStreamPlayer = $IntroVideo


func _ready() -> void:
	intro_video.finished.connect(_on_intro_finished)

	if intro_video.stream == null:
		push_warning("No se encontró el video de introducción.")
		_open_menu()
		return

	intro_video.play()


func _on_intro_finished() -> void:
	_open_menu()


func _open_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
