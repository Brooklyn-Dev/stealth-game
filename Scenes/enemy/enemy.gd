@tool
extends CharacterBody2D

@onready var raycast = $RayCast2D

@export_range(0, 360) var facing_degrees := 0.0 : set = set_facing_degrees
@export var facing_direction := Vector2.RIGHT
var original_facing: Vector2
var target_facing := Vector2.RIGHT

@export var vision_range := 75.0
@export var vision_angle := 60.0
@export var vision_rays := 32

@export var hearing_range := 40.0 : set = set_hearing_range
@export var investigate_time := 3.0
var investigating := false
var investigate_timer: float

var player: Node2D
var last_player_pos: Vector2

func set_facing_degrees(value: float):
	facing_degrees = value
	facing_direction = Vector2.RIGHT.rotated(deg_to_rad(value))
	queue_redraw()

func set_hearing_range(value: float):
	hearing_range = value
	queue_redraw()

func _ready():
	original_facing = facing_direction

	player = get_node("../Player")
	if player:
		player.orb_thrown.connect(_on_orb_thrown)
		last_player_pos = player.global_position

func _process(delta):
	if Engine.is_editor_hint():
		return
	
	if investigating:
		facing_direction = facing_direction.lerp(target_facing, 5.0 * delta)
		investigate_timer -= delta
		if investigate_timer <= 0:
			target_facing = original_facing
			investigating = false
	else:
		facing_direction = facing_direction.lerp(original_facing, 2.0 * delta)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	if _can_see_player():
		get_tree().reload_current_scene()
	
	_check_player_movement()
	
	queue_redraw()

func _can_see_player() -> bool:
	if not player:
		return false
		
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	if distance > vision_range:
		return false
		
	var angle_to_player = facing_direction.angle_to(to_player.normalized())
	if abs(rad_to_deg(angle_to_player)) > vision_angle / 2:
		return false
	
	raycast.target_position = to_local(player.global_position)
	raycast.force_raycast_update()
	
	return not raycast.is_colliding() or raycast.get_collider() == player

func _is_in_hearing_range(pos: Vector2) -> bool:
	var offset = pos - global_position
	var nx = offset.x / hearing_range
	var ny = offset.y / (hearing_range * 0.5)
	return nx * nx + ny * ny <= 1.0

func _check_player_movement() -> void:
	if not player:
		return
	
	var current_pos = player.global_position
	var moved_distance = last_player_pos.distance_to(current_pos)

	if moved_distance > 0.1 and _is_in_hearing_range(current_pos):
		_investigate_location(current_pos)
	
	last_player_pos = current_pos

func _draw():
	_draw_hearing_zone()	
	_draw_vision_cone()

func _draw_hearing_zone() -> void:
	var points = []
	for i in range(33):
		var angle = i * TAU / 32.0
		var point = Vector2(cos(angle) * hearing_range, sin(angle) * hearing_range * 0.5)
		points.append(point)
	
	draw_polyline(points, Color.YELLOW * 0.5, 2)

func _draw_vision_cone() -> void:
	var half_angle = deg_to_rad(vision_angle / 2)
	var points = [Vector2.ZERO]
	
	for i in range(vision_rays + 1):
		var angle = -half_angle + (2 * half_angle * i / vision_rays)
		var direction = facing_direction.rotated(angle)
		
		raycast.target_position = direction * vision_range
		raycast.force_raycast_update()
		
		var end_point = direction * vision_range
		if raycast.is_colliding():
			end_point = to_local(raycast.get_collision_point())
		
		end_point.y *= 0.5
		points.append(end_point)
	
	draw_colored_polygon(points, Color.RED * 0.5)

func _on_orb_thrown(world_pos: Vector2):
	if _is_in_hearing_range(world_pos):
		_investigate_location(world_pos)

func _investigate_location(world_pos: Vector2):
	investigating = true
	investigate_timer = investigate_time
	target_facing = (world_pos - global_position).normalized()
