extends CharacterBody3D

@export var NORMAL_SPEED = 6.5
@export var SPRINT_SPEED = 6.5
@export var JUMP_VELOCITY = 5.5
@export var STAMINA = 10
@export var MOUSE_SENSITIVITY = 0.005
@onready var neck := $CameraRoot
@onready var cam := $CameraRoot/Camera3D
@onready var revolverAnim := $CameraRoot/Camera3D/plchld_revolver_better/AnimationPlayer
@onready var raycast := $CameraRoot/Camera3D/RayCast3D
@onready var raycastEnd := $CameraRoot/Camera3D/RayCastEnd

#CAM BOBBING FUNCTION WOOO
@export var BOB_FREQUENCY = 1.5
const BOB_AMPLITUDE = 0.08
var t_bob = 0.0

@onready var revolverBarrel := $CameraRoot/Camera3D/plchld_revolver_better/BarrelEnd

var proyectile #on ready for non hitscan weapons
var bulletTrail = load("res://Kleo Game Scenes/bullet_trail.tscn")
var instance

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event): # Window Activity and Camera Movement
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"): # ui_cancel = esc key
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			cam.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-65), deg_to_rad(70))

func _ready():
	pass
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBack")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_on_floor():
			velocity.x = lerp(velocity.x, direction.x * 6.5, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * 6.5, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * 30.5, delta * 3)
			velocity.z = lerp(velocity.z, direction.z * 30.5, delta * 3)
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 0.35)
			velocity.z = move_toward(velocity.z, 0, 0.35)
		
	#headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	cam.transform.origin = headbob(t_bob)
	
	#GUN
	if Input.is_action_pressed("primaryFire"):
		shoot_hitscan()

	move_and_slide()

func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	return pos

func shoot_hitscan():
	if !revolverAnim.is_playing():
		revolverAnim.play("recoil")
		instance = bulletTrail.instantiate()
		if raycast.is_colliding():
			instance.init(revolverBarrel.global_position, raycast.get_collision_point())
			#add a check for enemies
			#add a way to make bulletholes on surfaces
		else:
			instance.init(revolverBarrel.global_position, raycastEnd.global_position)
		get_parent().add_child(instance)
