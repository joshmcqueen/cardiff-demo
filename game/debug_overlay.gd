extends Node2D
## Uses the actual baked polygons, so the overlay matches movement boundaries.

var room: AdventureRoom


func _draw() -> void:
	if not is_instance_valid(room):
		return
	var navigation := room.navigation
	var polygon := navigation.navigation_polygon
	for index in polygon.get_polygon_count():
		var points := PackedVector2Array()
		for vertex in polygon.get_polygon(index):
			points.append(to_local(navigation.to_global(polygon.vertices[vertex])))
		draw_colored_polygon(points, Color(0.15, 0.9, 0.7, 0.16))
		points.append(points[0])
		draw_polyline(points, Color(0.3, 1.0, 0.8, 0.65), 1.5)
	for marker in room.find_children("*", "Marker2D", true, false):
		var point := to_local(marker.global_position)
		draw_circle(point, 7.0, Color(1.0, 0.8, 0.25))
		draw_line(point - Vector2(12, 0), point + Vector2(12, 0), Color.WHITE)
		draw_line(point - Vector2(0, 12), point + Vector2(0, 12), Color.WHITE)
		draw_string(ThemeDB.fallback_font, point + Vector2(12, -10), marker.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
