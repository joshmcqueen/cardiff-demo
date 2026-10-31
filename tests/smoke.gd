extends Node
## Engine-level integration checks; no test plugin required.

var failures := 0
var checks := 0
var game: Node


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


func frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame
		await get_tree().process_frame


func settle() -> void:
	for index in 600:
		await frames(1)
		if not game.player.walking and not game.transitioning:
			return
	check(false, "Movement or transition timed out")


func interact(name: String) -> void:
	game.request_interaction(game.current_room.get_node("Hotspots/" + name))
	await settle()


func click_at(point: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	# Exercise GUI handling and Main._unhandled_input, not just gameplay methods.
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button
	event.pressed = true
	get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event, true)


func _ready() -> void:
	# Fail explicitly if Main cannot compile, rather than hanging after a script error.
	get_tree().create_timer(120.0).timeout.connect(func():
		push_error("Integration checks timed out")
		get_tree().quit(1)
	)
	var main_script := load("res://game/main.gd") as Script
	if main_script == null or not main_script.can_instantiate():
		push_error("Main script could not compile")
		get_tree().quit(1)
		return
	GameState.reset()
	game = load("res://game/main.tscn").instantiate()
	add_child(game)
	await frames(6)
	var player: AdventurePlayer = game.player
	var ui: AdventureInterface = game.interface
	# Keep pointer polling out of deterministic tests; GUI input remains active.
	ui.set_process(false)
	game.set_process(false)
	check(not game.transitioning, "Initial navigation is ready")
	check(game.current_room.contains_walk_point(Vector2(200, 500)), "Floor is walkable")
	check(not game.current_room.contains_walk_point(Vector2(625, 480)), "Crate is excluded")
	check(not game.current_room.contains_walk_point(Vector2(40, 500)), "Room bounds are excluded")
	var start := player.position
	click_at(Vector2(40, 500))
	await frames(3)
	check(player.position == start and not player.walking, "Outside clicks do nothing")

	player.position = Vector2(420, 480)
	click_at(Vector2(830, 480))
	check(player.walking and player.destination.distance_to(Vector2(830, 480)) < 0.01, "Mouse event reaches world input at the clicked position")
	var visited_detour := false
	var stayed_in_bounds := true
	for index in 500:
		await frames(1)
		var point := player.position
		stayed_in_bounds = stayed_in_bounds and not Rect2(511, 401, 228, 153).has_point(point)
		visited_detour = visited_detour or point.y < 401 or point.y > 554
		if not player.walking:
			break
	check(stayed_in_bounds, "Path never crosses crate")
	check(visited_detour and player.position.distance_to(Vector2(830, 480)) < 12, "Routes around crate and reaches target")

	game.request_interaction(game.current_room.get_node("Hotspots/Key"))
	check(game.pending_hotspot != null, "Interaction queues while walking")
	click_at(Vector2(950, 580))
	await settle()
	check(GameState.inventory.is_empty(), "New ground click cancels pending pickup")
	check(player.position.distance_to(Vector2(950, 580)) < 12, "New destination wins")
	click_at(Vector2(1135, 290), MOUSE_BUTTON_RIGHT)
	check(not player.walking and ui.response.text.contains("locked"), "Right-click examines without walking")
	await interact("Gate")
	check(game.current_room.name == "Courtyard" and not GameState.gate_unlocked, "Door starts locked")
	check(ui.response.text.begins_with("Locked"), "Locked door gives feedback")
	click_at(Vector2(350, 472))
	await settle()
	check(GameState.inventory == [&"gate_key"], "Key is collected")
	check(not game.current_room.get_node("Hotspots/Key").visible, "Collected key disappears")
	check(not GameState.add_item(&"gate_key") and GameState.inventory.size() == 1, "Duplicate pickup rejected")

	ui._set_drawer_open(true)
	await frames(20)
	check(is_zero_approx(ui.drawer.position.y) and is_equal_approx(ui.drawer.modulate.a, 1.0), "Drawer opens and fades in")
	check(not ui.previous.visible and not ui.next.visible, "No scroll arrows for one item")
	var click := InputEventMouseButton.new()
	click.position = Vector2(190, 70)
	click.global_position = click.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	get_viewport().push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	get_viewport().push_input(click, true)
	await frames(2)
	check(ui.selected_item == &"gate_key", "GUI slot click selects the key")
	check(not player.walking, "Inventory click does not move player")
	ui._set_drawer_open(false)
	await frames(20)
	check(not ui.drawer.visible and is_zero_approx(ui.drawer.modulate.a), "Drawer closes and fades out")
	await interact("Crate")
	check(ui.response.text.contains("doesn't help") and &"gate_key" in GameState.inventory, "Wrong use retains item and gives feedback")
	check(ui.selected_item == &"gate_key", "Wrong use retains selection")
	await interact("Gate")
	check(GameState.gate_unlocked and ui.selected_item.is_empty(), "Using key unlocks gate and clears selection")
	check(&"gate_key" in GameState.inventory, "Unlocking retains key")
	await interact("Gate")
	check(game.current_room.name == "Gatehouse", "Exit changes room after walking")
	check(player.position.distance_to(Vector2(275, 455)) < 1, "Arrives at named entrance")
	await interact("Bell")
	check(GameState.bell_rung and ui.response.text.contains("Demo complete"), "Bell completes puzzle")
	await interact("CourtyardExit")
	check(game.current_room.name == "Courtyard", "Can return to courtyard")
	check(GameState.gate_unlocked and GameState.bell_rung and GameState.inventory.size() == 1, "Puzzle state survives room changes")
	check(not game.current_room.get_node("Hotspots/Key").visible, "Key stays collected after return")
	await interact("Gate")
	check(game.current_room.name == "Gatehouse", "Unlocked door remains usable")
	await interact("Bell")
	check(ui.response.text.contains("already"), "Bell remembers completion")

	for index in 8:
		GameState.add_item(StringName("test_item_%d" % index))
	ui.scroll_offset = 0
	ui.refresh_inventory()
	check(ui.next.visible and not ui.previous.visible, "Overflow initially shows right arrow")
	ui.scroll(1)
	check(ui.previous.visible and ui.scroll_offset == 1, "Scrolls one item and shows left arrow")
	ui.scroll(100)
	check(not ui.next.visible and ui.scroll_offset == 3, "Scrolling stops at last page")
	ui.scroll(-100)
	check(not ui.previous.visible and ui.scroll_offset == 0, "Scrolling stops at first page")
	ui.select_item(&"gate_key")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	get_viewport().push_input(cancel, true)
	check(ui.selected_item.is_empty(), "Escape cancels item selection")
	ui.select_item(&"gate_key")
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	get_viewport().push_input(right_click, true)
	check(ui.selected_item.is_empty(), "Right-click cancels item selection")

	# An in-flight transition must reject further world input.
	game.change_room("res://rooms/courtyard.tscn", &"FromGatehouse")
	check(game.transitioning and ui.input_locked, "Transition locks gameplay immediately")
	game.handle_world_click(Vector2(500, 500), MOUSE_BUTTON_LEFT)
	check(not player.walking, "World clicks are ignored during transition")
	await settle()
	check(not game.transitioning and not ui.input_locked, "Transition unlocks after navigation sync")
	GameState.reset()
	game.queue_free()
	await frames(2)
	print("Cardiff integration: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
