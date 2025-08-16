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

@export var hearing_range := 75.0
@export var investigate_time := 3.0
var investigating := false
var investigate_timer: float

var player: Node2D

func set_facing_degrees(value: float):
	facing_degrees = value
	facing_direction = Vector2.RIGHT.rotated(deg_to_rad(value))
	queue_redraw()

func _ready():
	original_facing = facing_direction

	player = get_node("../Player")
	if player:
		player.orb_thrown.connect(_on_orb_thrown)

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

func _draw():
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
		
		points.append(end_point)
	
	draw_colored_polygon(points, Color.RED * 0.5)

func _on_orb_thrown(world_pos: Vector2):
	if global_position.distance_to(world_pos) <= hearing_range:
		investigating = true
		investigate_timer = investigate_time
		target_facing = (world_pos - global_position).normalized()
