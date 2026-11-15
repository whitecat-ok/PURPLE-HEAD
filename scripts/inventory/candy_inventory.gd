
extends Node

signal inventory_changed(slots: Array[String])
signal candy_consumed(slot_index: int, candy_color: String, duration: float)

const MAX_SLOTS: int = 3
const VALID_CANDIES: Array[String] = ["yellow", "green", "blue"]
const DEFAULT_DURATION: float = 15.0

var slots: Array[String] = ["", "", ""]
var slot_durations: Array[float] = [0.0, 0.0, 0.0]


func _ready() -> void:
	print("[CandyInventory] Inventario iniciado.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("consume_slot_1") and not event.is_echo():
		get_viewport().set_input_as_handled()
		consume_slot(0)

	elif event.is_action_pressed("consume_slot_2") and not event.is_echo():
		get_viewport().set_input_as_handled()
		consume_slot(1)

	elif event.is_action_pressed("consume_slot_3") and not event.is_echo():
		get_viewport().set_input_as_handled()
		consume_slot(2)


# --------------------------------------------------
# ADD CANDY
# --------------------------------------------------

func add_candy(
	candy_color: String,
	duration: float = DEFAULT_DURATION
) -> bool:

	if not VALID_CANDIES.has(candy_color):
		push_warning("[CandyInventory] Color inválido: " + candy_color)
		return false

	if duration <= 0.0:
		push_warning("[CandyInventory] La duración debe ser mayor que cero.")
		return false

	for i in range(MAX_SLOTS):
		if slots[i] == "":
			slots[i] = candy_color
			slot_durations[i] = duration

			print(
				"[CandyInventory] Recogido: ",
				candy_color,
				" | Duración: ",
				duration,
				" segundos | Slot: ",
				i + 1
			)

			_emit_inventory_changed()
			return true

	print("[CandyInventory] Inventario lleno.")
	return false


# --------------------------------------------------
# CONSUME CANDY
# --------------------------------------------------

func consume_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false

	if slots[slot_index] == "":
		print("[CandyInventory] Slot ", slot_index + 1, " vacío.")
		return false

	var consumed_color: String = slots[slot_index]
	var consumed_duration: float = slot_durations[slot_index]

	slots[slot_index] = ""
	slot_durations[slot_index] = 0.0

	print(
		"[CandyInventory] Consumido: ",
		consumed_color,
		" | Duración: ",
		consumed_duration,
		" segundos"
	)

	candy_consumed.emit(
		slot_index,
		consumed_color,
		consumed_duration
	)

	_emit_inventory_changed()
	return true


# --------------------------------------------------
# GETTERS
# --------------------------------------------------

func get_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return ""

	return slots[slot_index]


func get_slot_duration(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return 0.0

	return slot_durations[slot_index]


func get_slots() -> Array[String]:
	return slots.duplicate()


func get_empty_slots() -> int:
	var empty_count: int = 0

	for candy in slots:
		if candy == "":
			empty_count += 1

	return empty_count


# --------------------------------------------------
# SIGNALS
# --------------------------------------------------

func _emit_inventory_changed() -> void:
	inventory_changed.emit(slots.duplicate())
