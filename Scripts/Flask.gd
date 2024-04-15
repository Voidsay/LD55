extends RigidBody3D

@onready var audio = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_body_entered(body:Node):
	print(body, " entered")
