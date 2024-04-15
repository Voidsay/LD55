extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const SENSETIVITY = 0.003

const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0
var signum = 1.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var inair = false

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var audio = $AudioStreamPlayer3D
@onready var raycast = $Head/Camera3D/RayCast3D
@onready var hand = $Head/Camera3D/Hand

var mat
@export var adjustment = 1.0#TODO figure out right value
 
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var pFactor = 1
@export var iFactor = 1
@export var dFactor = 1
var integral = Vector3.ZERO
var lastDeviation = Vector3.ZERO

func _adjustForce(desired, current, timeFrame) -> Vector3:
	var present = desired - current
	integral += present * timeFrame
	var deriv = (present - lastDeviation) / timeFrame
	lastDeviation = present;
	return present * pFactor + integral * iFactor + deriv * dFactor

func  _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	if pos.x != 0.0 && sign(pos.x) != sign(signum):
		audio.play()
		signum *= -1.0
	return pos

func _check_for_collision(kinematicCollision):
	var colObj = kinematicCollision.get_collider()
	if colObj is RigidBody3D:
		var push_direction = (colObj.global_transform.origin - global_transform.origin).normalized()
		colObj.apply_impulse(push_direction * 1, Vector3.ZERO)#TODO consider player momentum

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mat = get_node("../CanvasLayer/ColorRect").material#TODO relative paths are bad

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSETIVITY)
		camera.rotate_x(-event.relative.y * SENSETIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))
		mat.set_shader_parameter("offset", Vector2(head.rotation_degrees.y, camera.rotation_degrees.x) *  adjustment)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		inair = true

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if is_on_floor() && inair:
		inair = false
		audio.play()
	
	if Input.is_action_pressed("Run"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, RUN_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
	for i in get_slide_collision_count():
		_check_for_collision(get_slide_collision(i))
	
	#Handholding
	if Input.is_action_pressed("Action1"):
		var obj = raycast.get_collider()
		if obj is RigidBody3D:
			var dragForce = _adjustForce(hand.global_position, obj.global_position, delta)
			obj.apply_central_impulse(dragForce)
