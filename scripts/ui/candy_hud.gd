
extends CanvasLayer

@export_group("References")
@export var character_manager: Node

@onready var slot_1: Label = $MarginContainer/HBoxContainer/PanelContainer/VBoxContainer/Label
@onready var slot_2: Label = $MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/Label
@onready var slot_3: Label = $MarginContainer/HBoxContainer/PanelContainer3/VBoxContainer/Label

@onready var bar_1: ProgressBar = $MarginContainer/HBoxContainer/PanelContainer/VBoxContainer/ProgressBar
@onready var bar_2: ProgressBar = $MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/ProgressBar
@onready var bar_3: ProgressBar = $MarginContainer/HBoxContainer/PanelContainer3/VBoxContainer/ProgressBar

var slot_labels: Array[Label] = []
var slot_bars: Array[ProgressBar] = []

const CANDY_COLORS: Dictionary = {
	"yellow": Color("#E9B72F"),
	"green": Color("#43B978"),
	"blue": Color("#438FE0")
}


func _ready() -> void:
	slot_labels = [
		slot_1,
		slot_2,
		slot_3
	]

	slot_bars = [
		bar_1,
		bar_2,
		bar_3
	]

	if not is_instance_valid(character_manager):
		push_error("[CandyHUD] CharacterManager no está asignado.")
		return

	for i in range(3):
		var label: Label = slot_labels[i]
		var bar: ProgressBar = slot_bars[i]

		if not is_instance_valid(label):
			push_error("[CandyHUD] Label del slot " + str(i + 1) + " no encontrado.")
			return

		if not is_instance_valid(bar):
			push_error("[CandyHUD] ProgressBar del slot " + str(i + 1) + " no encontrado.")
			return

		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 32)

		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = 100.0
		bar.show_percentage = false
		bar.visible = false
		bar.custom_minimum_size = Vector2(70, 8)

	if not CandyInventory.inventory_changed.is_connected(
		_on_inventory_changed
	):
		CandyInventory.inventory_changed.connect(
			_on_inventory_changed
		)

	_on_inventory_changed(CandyInventory.get_slots())

	print("[CandyHUD] HUD iniciado.")


func _process(_delta: float) -> void:
	_update_transformation_bars()


# --------------------------------------------------
# INVENTORY DISPLAY
# --------------------------------------------------

func _on_inventory_changed(slots: Array[String]) -> void:
	for i in range(slot_labels.size()):
		if i >= slots.size():
			continue

		var candy_color: String = slots[i]

		if candy_color == "":
			slot_labels[i].text = "○"
			slot_labels[i].modulate = Color("#777777")
		else:
			slot_labels[i].text = "●"
			slot_labels[i].modulate = CANDY_COLORS.get(
				candy_color,
				Color.WHITE
			)


# --------------------------------------------------
# TRANSFORMATION BARS
# --------------------------------------------------

func _update_transformation_bars() -> void:
	if not is_instance_valid(character_manager):
		return

	var active_slot: int = character_manager.get_active_candy_slot_index()
	var remaining: float = character_manager.get_remaining_transformation_time()
	var duration: float = character_manager.get_active_candy_duration()

	for i in range(slot_bars.size()):
		var bar: ProgressBar = slot_bars[i]

		if not is_instance_valid(bar):
			continue

		if i != active_slot or duration <= 0.0 or remaining <= 0.0:
			bar.visible = false
			bar.value = 100.0
			continue

		bar.visible = true
		bar.value = clampf(
			(remaining / duration) * 100.0,
			0.0,
			100.0
		)
