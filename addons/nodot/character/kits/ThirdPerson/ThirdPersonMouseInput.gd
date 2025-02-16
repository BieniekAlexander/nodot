@tool
@icon("../../icons/mouse.svg")
## Takes mouse input for a third person character
class_name ThirdPersonMouseInput extends Nodot

## Is input enabled
@export var enabled := true
## Sensitivity of mouse movement
@export var mouse_sensitivity := 0.1
## Enable camera movement only while camera_rotate_action input action is pressed
@export var lock_camera_rotation := false
## Rotate the ThirdPersonCharacter with the camera
@export var lock_character_rotation := false
## Restrict vertical look angle
@export var vertical_clamp := Vector2(-1.36, 1.4)
## Custom mouse cursor
@export var custom_cursor := false

@export_category("Input Actions")
## Input action for enabling camera rotation
@export var camera_rotate_action: String = "camera_rotate"

@onready var character: ThirdPersonCharacter = get_parent()

var is_editor: bool = Engine.is_editor_hint()
var mouse_rotation: Vector2 = Vector2.ZERO
var cursor_show_state = Input.MOUSE_MODE_VISIBLE

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if !(get_parent() is ThirdPersonCharacter):
		warnings.append("Parent should be a ThirdPersonCharacter")
	return warnings

func _ready() -> void:
	if not character.is_multiplayer_authority(): return
	
	if enabled:
		enable()

	if custom_cursor:
		cursor_show_state = Input.MOUSE_MODE_HIDDEN

func _input(event: InputEvent) -> void:
	if not character.is_multiplayer_authority(): return
	
	if !enabled or !character.input_enabled: return
	if event is InputEventMouseMotion:
		mouse_rotation.y = event.relative.x * InputManager.mouse_sensitivity
		mouse_rotation.x = event.relative.y * InputManager.mouse_sensitivity
		character.camera.time_since_last_move = 0.0

func _physics_process(delta: float) -> void:
	
	if is_editor or character and character.is_multiplayer_authority() == false: return
	if !enabled or is_editor or !character.input_enabled or !character.third_person_camera_container: return
	if (!lock_camera_rotation or Input.is_action_pressed(camera_rotate_action)):
	
		var look_angle: Vector2 = Vector2(-mouse_rotation.x * delta, -mouse_rotation.y * delta)
		# character.look_angle = Vector2(look_angle.y, look_angle.x)
		# Handle look left and right
		if lock_character_rotation:
			character.rotate_object_local(Vector3(0, 1, 0), look_angle.y)
		else:
			character.third_person_camera_container.rotate_object_local(Vector3(0, 1, 0), look_angle.y)

		# Handle look up and down
		character.camera.rotate_object_local(Vector3(1, 0, 0), look_angle.x)

		character.camera.rotation.x = clamp(character.camera.rotation.x, vertical_clamp.x, vertical_clamp.y)
		mouse_rotation = Vector2.ZERO

## Disable input and release mouse
func disable() -> void:
	Input.set_mouse_mode(cursor_show_state)
	enabled = false

## Enable input and capture mouse
func enable() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	enabled = true
