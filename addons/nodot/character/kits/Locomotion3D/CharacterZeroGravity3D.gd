@tool
## Assists with character zero-g controls and effects
class_name CharacterZeroGravity3D extends CharacterExtensionBase3D

## How much to slow the character while in zero g
@export var friction := 1.0
## How fast the player can move
@export var movement_speed := 5.0

@export_category("State Handlers")
## Set the swim state handler
@export var swim_state_handler: CharacterSwim3D
## Set the idle state handler
@export var idle_state_handler: StateHandler

@export_subgroup("Third Person Controls")
## Turn rate. If strafing is disabled, define how fast the character will turn.
@export var turn_rate: float = 0.1

@export_category("Input Actions")
## The input action name for strafing left
@export var left_action: String = "left"
## The input action name for strafing right
@export var right_action: String = "right"
## The input action name for moving forward
@export var up_action: String = "up"
## The input action name for moving backwards
@export var down_action: String = "down"
## The input action name for drifting upwards
@export var ascend_action: String = "jump"
## The input action name for drifting downwards
@export var descend_action: String = "submerge_descend"

var direction: Vector3 = Vector3.ZERO
var default_speed: float

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if !(get_parent() is NodotCharacter3D):
		warnings.append("Parent should be a NodotCharacter3D")
	return warnings

func setup():
	var action_names = [ascend_action, descend_action]
	var default_keys = [KEY_SPACE, KEY_CTRL]
	for i in action_names.size():
		var action_name = action_names[i]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			InputManager.add_action_event_key(action_name, default_keys[i])

func physics(delta: float) -> void:
	if !character.input_enabled:
		return
		
	var input_dir = Input.get_vector(left_action, right_action, up_action, down_action)
	var basis: Basis
	if third_person_camera:
		basis = third_person_camera.global_transform.basis
	else:
		basis = character.transform.basis
	direction = (basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var new_y_velocity = clamp(character.velocity.y, -16.0, 16.0)
	character.velocity.y = lerp(new_y_velocity, 0.0, 0.025 * friction)
	
	if Input.is_action_pressed(ascend_action):
		character.velocity.y = lerp(character.velocity.y, movement_speed, delta)
	if Input.is_action_pressed(descend_action):
		character.velocity.y = lerp(character.velocity.y, -movement_speed, delta)
	
	if direction == Vector3.ZERO:
		character.velocity.x = move_toward(character.velocity.x, 0, 0.1)
		character.velocity.z = move_toward(character.velocity.z, 0, 0.1)
	else:
		character.velocity.x = lerp(character.velocity.x, direction.x * movement_speed, 0.025)
		character.velocity.z = lerp(character.velocity.z, direction.z * movement_speed, 0.025)
		
		#if third_person_camera:
		#	var cached_rotation = third_person_camera_container.global_rotation
		#	face_target(character.position + direction, turn_rate)
		#	third_person_camera_container.global_rotation = cached_rotation
		
	character.move_and_slide()
