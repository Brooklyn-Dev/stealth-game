extends CharacterBody2D

@onready var raycast = $RayCast2D

@export var vision_range := 75.0
@export var vision_angle := 60.0
@export var facing_direction := Vector2.RIGHT
@export var vision_rays := 32

var player: Node2D

func _ready():
	player = get_node("../Player")

func _physics_process(delta):
	if _can_see_player():
		print("Spotted!")
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
