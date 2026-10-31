extends Node
## Session-only state. Reloading the game starts a fresh puzzle.

signal inventory_changed
signal progress_changed

var inventory: Array[StringName] = []
var gate_unlocked := false
var bell_rung := false


func add_item(item: StringName) -> bool:
	if item in inventory:
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true


func item_label(item: StringName) -> String:
	if item == &"gate_key":
		return "Gate key"
	return String(item).replace("_", " ").capitalize()


func unlock_gate() -> void:
	gate_unlocked = true
	progress_changed.emit()


func ring_bell() -> void:
	bell_rung = true
	progress_changed.emit()


func reset() -> void:
	inventory.clear()
	gate_unlocked = false
	bell_rung = false
	inventory_changed.emit()
	progress_changed.emit()
