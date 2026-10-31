class_name AdventureRoom
extends Node2D
## Rooms provide geometry and markers. Main handles input and room changes.

@export var room_title := "Room"
@onready var navigation: NavigationRegion2D = $NavigationRegion2D


func _ready() -> void:
	GameState.inventory_changed.connect(refresh_state)
	GameState.progress_changed.connect(refresh_state)
	refresh_state()


func refresh_state() -> void:
	for hotspot in hotspots():
		if not hotspot.pickup_item.is_empty():
			hotspot.visible = hotspot.pickup_item not in GameState.inventory
	var door := get_node_or_null("Scenery/Door") as Polygon2D
	if door:
		door.color = Color("47766e") if GameState.gate_unlocked else Color("80523a")
	var bell := get_node_or_null("Hotspots/Bell/Art") as Polygon2D
	if bell:
		bell.color = Color("75d7bd") if GameState.bell_rung else Color("e5b95f")


func hotspots() -> Array[AdventureHotspot]:
	var result: Array[AdventureHotspot] = []
	var container := get_node_or_null("Hotspots")
	if container:
		for child in container.get_children():
			if child is AdventureHotspot:
				result.append(child)
	return result


func hotspot_at(point: Vector2) -> AdventureHotspot:
	# Last sibling is drawn on top, so it also wins overlapping hit areas.
	var candidates := hotspots()
	candidates.reverse()
	for hotspot in candidates:
		if hotspot.contains_point(point):
			return hotspot
	return null


func contains_walk_point(point: Vector2) -> bool:
	var polygon := navigation.navigation_polygon
	var local_point := navigation.to_local(point)
	for index in polygon.get_polygon_count():
		var boundary := PackedVector2Array()
		for vertex in polygon.get_polygon(index):
			boundary.append(polygon.vertices[vertex])
		if Geometry2D.is_point_in_polygon(local_point, boundary):
			return true
	return false


func entrance_position(entrance: StringName) -> Vector2:
	var marker := get_node_or_null(NodePath("Entrances/" + String(entrance))) as Marker2D
	assert(marker != null, "Room is missing entrance: " + String(entrance))
	return marker.global_position
