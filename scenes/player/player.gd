extends CharacterBody2D

@export var speed := 32.0
@export var orbSpeed := 80.0
@export var orbScene: PackedScene

signal orb_thrown(position: Vector2)

func throw_orb(target: Vector2) -> void:
	var tween = create_tween()
	var orb = orbScene.instantiate()
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position
	
	var distance = global_position.distance_to(target)
	var duration = distance / orbSpeed
	var arc_height = distance / 2
	var stretch_factor = distance / 100.0
	
	tween.tween_method(func(t): move_orb(orb, position, target, t, arc_height, stretch_factor), 0.0, 1.0, duration)
	tween.tween_callback(func(): orb_landed(target, orb))

func move_orb(orb: Node2D, start: Vector2, target: Vector2, t: float, arc_height: float, stretch_factor: float):
	var pos = start.lerp(target, t)
	var arc_factor = 4 * t * (1 - t) * stretch_factor
	pos.y -= arc_height * arc_factor
	orb.global_position = pos
	
func orb_landed(pos: Vector2, orb: Node2D):
	orb_thrown.emit(pos)
	orb.queue_free()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("throw"):
		throw_orb(get_global_mouse_position())

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
