extends Node3D

func _process(_delta):
	if Input.is_action_just_pressed("Exit"):
		get_tree().quit()
