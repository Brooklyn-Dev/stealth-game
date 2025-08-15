extends CharacterBody2D

@export var speed := 32.0

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
