extends Area2D

@export_group("References")
@export var character_manager: Node
@export var barrier: StaticBody2D

var blue_inside: CharacterBody2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("playable_characters"):
		return

	_update_blue_access()


func _on_body_exited(body: Node2D) -> void:
	if body == blue_inside:
		_remove_blue_access()


func _physics_process(_delta: float) -> void:
	_update_blue_access()


func _update_blue_access() -> void:
	if character_manager == null or barrier == null:
		return

	var selected := character_manager.call(
		"get_selected_character"
	) as CharacterBody2D

	var overlapping := get_overlapping_bodies()
	
	var can_pass: bool = (
	selected != null
	and selected.is_in_group("playable_characters")
	and selected.get("character_name") == "Blue"
	and overlapping.has(selected)
)

	if can_pass:
		if blue_inside != selected:
			_remove_blue_access()

			blue_inside = selected
			blue_inside.add_collision_exception_with(barrier)

	else:
		_remove_blue_access()


func _remove_blue_access() -> void:
	if is_instance_valid(blue_inside) and is_instance_valid(barrier):
		blue_inside.remove_collision_exception_with(barrier)

	blue_inside = null


func _exit_tree() -> void:
	_remove_blue_access()
