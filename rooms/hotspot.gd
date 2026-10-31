@tool
class_name AdventureHotspot
extends Node2D
## Bounds and Approach can be edited independently of the visible artwork.

@export var hotspot_id: StringName
@export var display_name := "Object"
@export_multiline var examination := "Nothing unusual."
@export var hit_size := Vector2(100, 80):
	set(value):
		hit_size = value
		queue_redraw()
@export_enum("Object", "Left", "Right", "Up", "Down") var exit_direction: int = 0
@export_file("*.tscn") var destination_room: String
@export var destination_entrance: StringName
@export var pickup_item: StringName
@onready var approach: Marker2D = $Approach


func contains_point(point: Vector2) -> bool:
	return visible and Rect2(-hit_size / 2.0, hit_size).has_point(to_local(point))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-hit_size / 2.0, hit_size), Color(0.95, 0.78, 0.3, 0.8), false, 2.0)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not get_node_or_null("Approach") is Marker2D:
		warnings.append("Add a Marker2D child named Approach on walkable ground.")
	if hotspot_id.is_empty():
		warnings.append("Give this hotspot a unique Hotspot Id.")
	if exit_direction > 0 and (destination_room.is_empty() or destination_entrance.is_empty()):
		warnings.append("Exits need a destination scene and entrance marker name.")
	return warnings
