extends Node2D
## Main mediates input, movement, room loading and puzzle actions.

const COURTYARD = preload("res://rooms/courtyard.tscn")

var current_room: AdventureRoom
var pending_hotspot: AdventureHotspot
var pending_item: StringName
var transitioning := true
@onready var player: AdventurePlayer = $Player
@onready var debug_overlay: Node2D = $DebugOverlay
@onready var interface: AdventureInterface = $Interface


func _ready() -> void:
	player.arrived.connect(_complete_pending_interaction)
	player.movement_failed.connect(_movement_failed)
	interface.selection_changed.connect(_selection_changed)
	interface.input_locked = true
	_install_room(COURTYARD, &"Start")
	await _wait_for_navigation()
	transitioning = false
	interface.input_locked = false
	interface.show_response("Find the key and use it to open the gatehouse.")


func _process(_delta: float) -> void:
	if not is_instance_valid(current_room):
		return
	var point := get_global_mouse_position()
	var hovered: AdventureHotspot = null
	if not transitioning and not interface.blocks_world(point):
		hovered = current_room.hotspot_at(point)
	interface.show_hover(hovered)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		debug_overlay.visible = not debug_overlay.visible
		debug_overlay.queue_redraw()
		interface.set_debug(debug_overlay.visible)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed:
		# Use this click's position; the polled mouse position can lag a native event.
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		handle_world_click(point, event.button_index)


func handle_world_click(point: Vector2, button: int) -> void:
	if transitioning or interface.blocks_world(point):
		return
	var hotspot := current_room.hotspot_at(point)
	if button == MOUSE_BUTTON_RIGHT:
		if not interface.selected_item.is_empty():
			interface.select_item(&"")
		elif hotspot:
			var description := hotspot.examination
			if hotspot.hotspot_id == &"gate" and GameState.gate_unlocked:
				description = "The gatehouse door is unlocked. The key worked."
			interface.show_response(description)
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	if hotspot:
		request_interaction(hotspot)
	elif current_room.contains_walk_point(point):
		pending_hotspot = null
		pending_item = &""
		player.walk_to(point)


func request_interaction(hotspot: AdventureHotspot) -> void:
	if transitioning or not is_instance_valid(hotspot) or not hotspot.visible:
		return
	player.stop()
	pending_hotspot = null
	var target := hotspot.approach.global_position
	if not current_room.contains_walk_point(target):
		interface.show_response("This object's Approach marker needs to be on walkable ground.")
		return
	pending_hotspot = hotspot
	pending_item = interface.selected_item
	if player.global_position.distance_to(target) <= 12.0:
		_complete_pending_interaction()
	else:
		player.walk_to(target)


func _complete_pending_interaction() -> void:
	if not is_instance_valid(pending_hotspot):
		return
	var hotspot := pending_hotspot
	var item := pending_item
	pending_hotspot = null
	pending_item = &""
	if transitioning or not hotspot.visible:
		return
	if not item.is_empty():
		if item == &"gate_key" and hotspot.hotspot_id == &"gate":
			GameState.unlock_gate()
			interface.select_item(&"")
			interface.show_response("The key turns. The gatehouse is unlocked — click the door to enter.")
		else:
			interface.show_response("The %s doesn't help with %s." % [GameState.item_label(item).to_lower(), hotspot.display_name.to_lower()])
		return
	if not hotspot.pickup_item.is_empty():
		if GameState.add_item(hotspot.pickup_item):
			interface.show_response("Picked up: %s. Move to the top edge to open your inventory." % GameState.item_label(hotspot.pickup_item))
	elif hotspot.hotspot_id == &"gate" and not GameState.gate_unlocked:
		interface.show_response("Locked. There must be a key nearby.")
	elif hotspot.hotspot_id == &"bell":
		var already_rung := GameState.bell_rung
		GameState.ring_bell()
		interface.show_response("Ding! You've already announced your arrival." if already_rung else "Ding! Demo complete. You found your way inside. Keep exploring!")
	elif hotspot.exit_direction > 0:
		change_room(hotspot.destination_room, hotspot.destination_entrance)
	else:
		interface.show_response(hotspot.examination)


func _selection_changed(_item: StringName) -> void:
	if is_instance_valid(pending_hotspot):
		player.stop()
	pending_hotspot = null
	pending_item = &""


func _movement_failed() -> void:
	pending_hotspot = null
	pending_item = &""
	interface.show_response("I can't get there. Try another spot.")


func change_room(path: String, entrance: StringName) -> void:
	if transitioning:
		return
	transitioning = true
	interface.input_locked = true
	player.stop()
	pending_hotspot = null
	pending_item = &""
	interface.show_hover(null)
	var packed := load(path) as PackedScene
	if packed == null:
		interface.show_response("This exit needs a valid room scene in its Inspector.")
		transitioning = false
		interface.input_locked = false
		return
	await create_tween().tween_property(interface.fade, "color:a", 1.0, 0.18).finished
	$RoomContainer.remove_child(current_room)
	current_room.queue_free()
	_install_room(packed, entrance)
	await _wait_for_navigation()
	await create_tween().tween_property(interface.fade, "color:a", 0.0, 0.18).finished
	transitioning = false
	interface.input_locked = false


func _install_room(packed: PackedScene, entrance: StringName) -> void:
	current_room = packed.instantiate()
	$RoomContainer.add_child(current_room)
	player.global_position = current_room.entrance_position(entrance)
	debug_overlay.room = current_room
	debug_overlay.queue_redraw()
	interface.set_room_title(current_room.room_title)


func _wait_for_navigation() -> void:
	# NavigationServer synchronizes at the end of physics frames, after signals.
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
