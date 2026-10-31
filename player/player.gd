class_name AdventurePlayer
extends CharacterBody2D
## The root position is the character's feet, not the centre of its artwork.

signal arrived
signal movement_failed

@export var walk_speed: float = 260.0
var walking := false
var destination := Vector2.ZERO
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var silhouette: Node2D = $Silhouette


func walk_to(point: Vector2) -> void:
	stop()
	destination = point
	agent.target_position = point
	walking = true


func stop() -> void:
	walking = false
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not walking:
		return
	if agent.is_navigation_finished():
		stop()
		if global_position.distance_to(destination) <= 12.0:
			arrived.emit()
		else:
			movement_failed.emit()
		return
	var step := agent.get_next_path_position() - global_position
	velocity = step.normalized() * minf(walk_speed, step.length() / delta)
	if absf(velocity.x) > 1.0:
		silhouette.scale.x = 1.0 if velocity.x >= 0.0 else -1.0
	move_and_slide()
	# Keep feet on the navigation surface even at tight path corners.
	global_position = NavigationServer2D.map_get_closest_point(agent.get_navigation_map(), global_position)
