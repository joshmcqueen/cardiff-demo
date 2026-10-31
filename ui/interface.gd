class_name AdventureInterface
extends CanvasLayer
## GUI receives clicks before Main's _unhandled_input, preventing click-through.

signal selection_changed(item: StringName)

const VISIBLE_SLOTS := 6
const DRAWER_HEIGHT := 124.0
const REVEAL_HEIGHT := 20.0

var selected_item: StringName
var scroll_offset := 0
var drawer_open := false
var input_locked := false
var drawer_tween: Tween
var message_tween: Tween
var debug_enabled := false
@onready var drawer: Panel = $Root/Drawer
@onready var slots: HBoxContainer = $Root/Drawer/Slots
@onready var previous: Button = $Root/Drawer/Previous
@onready var next: Button = $Root/Drawer/Next
@onready var response: Label = $Root/Response
@onready var cursor_label: Label = $Root/CursorLabel
@onready var pointer: Label = $Root/Pointer
@onready var hover_label: Label = $Root/HoverLabel
@onready var fade: ColorRect = $Root/Fade


func _ready() -> void:
	drawer.position.y = -DRAWER_HEIGHT
	drawer.modulate.a = 0.0
	drawer.visible = false
	for index in VISIBLE_SLOTS:
		var slot := slots.get_child(index) as Button
		slot.pressed.connect(_select_slot.bind(index))
	previous.pressed.connect(scroll.bind(-1))
	next.pressed.connect(scroll.bind(1))
	GameState.inventory_changed.connect(refresh_inventory)
	refresh_inventory()


func _process(_delta: float) -> void:
	var mouse := $Root.get_local_mouse_position() as Vector2
	var in_view := Rect2(Vector2.ZERO, Vector2(1280, 720)).has_point(mouse)
	var bottom := maxf(REVEAL_HEIGHT, drawer.position.y + DRAWER_HEIGHT)
	var should_open := not input_locked and in_view and (mouse.y <= REVEAL_HEIGHT or (drawer_open and mouse.y <= bottom + 8.0))
	if should_open != drawer_open:
		_set_drawer_open(should_open)
	cursor_label.position = Vector2(clampf(mouse.x + 22, 8, 1030), clampf(mouse.y + 25, 8, 680))
	pointer.position = mouse - Vector2(21, 27)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not selected_item.is_empty():
			select_item(&"")
			get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		select_item(&"")
		get_viewport().set_input_as_handled()


func blocks_world(point: Vector2) -> bool:
	return input_locked or point.y <= REVEAL_HEIGHT or (drawer.visible and point.y <= drawer.position.y + DRAWER_HEIGHT)


func _set_drawer_open(open: bool) -> void:
	drawer_open = open
	if drawer_tween:
		drawer_tween.kill()
	drawer.visible = true
	drawer_tween = create_tween().set_parallel(true)
	drawer_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	drawer_tween.tween_property(drawer, "position:y", 0.0 if open else -DRAWER_HEIGHT, 0.20)
	drawer_tween.tween_property(drawer, "modulate:a", 1.0 if open else 0.0, 0.20)
	if not open:
		drawer_tween.chain().tween_callback(func(): drawer.visible = false)


func scroll(amount: int) -> void:
	scroll_offset = clampi(scroll_offset + amount, 0, maxi(0, GameState.inventory.size() - VISIBLE_SLOTS))
	refresh_inventory()


func refresh_inventory() -> void:
	if not is_node_ready():
		return
	if not selected_item.is_empty() and selected_item not in GameState.inventory:
		select_item(&"")
	scroll_offset = clampi(scroll_offset, 0, maxi(0, GameState.inventory.size() - VISIBLE_SLOTS))
	previous.visible = scroll_offset > 0
	next.visible = scroll_offset + VISIBLE_SLOTS < GameState.inventory.size()
	$Root/Drawer/EmptyHint.visible = GameState.inventory.is_empty()
	for index in VISIBLE_SLOTS:
		var slot := slots.get_child(index) as Button
		var item_index := scroll_offset + index
		var occupied := item_index < GameState.inventory.size()
		slot.disabled = not occupied
		slot.text = GameState.item_label(GameState.inventory[item_index]) if occupied else "·"
		slot.button_pressed = occupied and GameState.inventory[item_index] == selected_item
		if occupied:
			slot.tooltip_text = "Select " + slot.text + "; then click an object."
		else:
			slot.tooltip_text = ""


func _select_slot(index: int) -> void:
	var item_index := scroll_offset + index
	if item_index < GameState.inventory.size():
		var item := GameState.inventory[item_index]
		select_item(&"" if item == selected_item else item)


func select_item(item: StringName) -> void:
	selected_item = item
	cursor_label.text = "Use " + GameState.item_label(item) if not item.is_empty() else ""
	selection_changed.emit(item)
	refresh_inventory()


func show_response(text: String) -> void:
	if message_tween:
		message_tween.kill()
	response.text = text
	response.modulate.a = 1.0
	message_tween = create_tween()
	message_tween.tween_interval(4.5)
	message_tween.tween_property(response, "modulate:a", 0.0, 0.4)


func show_hover(hotspot: AdventureHotspot) -> void:
	hover_label.text = hotspot.display_name if hotspot else ""
	if hotspot and not selected_item.is_empty():
		hover_label.text = "Use %s on %s" % [GameState.item_label(selected_item), hotspot.display_name]
	var is_exit := hotspot != null and hotspot.exit_direction > 0
	pointer.visible = is_exit and not input_locked
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if pointer.visible else Input.MOUSE_MODE_VISIBLE
	if is_exit:
		pointer.text = ["", "←", "→", "↑", "↓"][hotspot.exit_direction]
	elif hotspot:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func set_room_title(title: String) -> void:
	$Root/RoomName.text = title


func set_debug(enabled: bool) -> void:
	debug_enabled = enabled
	$Root/DebugHint.visible = enabled


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
