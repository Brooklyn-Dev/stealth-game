extends Node2D

@export var next_scene: PackedScene

func _on_area_2d_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	var new_scene = next_scene.instantiate()
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	get_tree().current_scene = new_scene
	get_tree().root.add_child(new_scene)
