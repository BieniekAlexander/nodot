@tool
class_name FirstPersonIronSight extends Nodot3D

## Whether ironsight zoom is allowed
@export var enabled := true
## The speed to move the camera to the ironsight location
@export var zoom_speed := 10.0
## The ironsight field of view
@export var fov := 75
## Whether to enable a scope view after ironsight zoom is complete
@export var enable_scope := false
## The scope texture that will cover the screen
@export var scope_texture: Texture2D
## The scope field of view
@export var scope_fov := 45

@onready var parent: FirstPersonItem = get_parent()

var initial_position = null
var ironsight_target = null
var viewport_camera: Camera3D

func _get_configuration_warnings() -> PackedStringArray:
  var warnings: PackedStringArray = []
  if !(get_parent() is FirstPersonItem):
    warnings.append("Parent should be a FirstPersonItem")
  return warnings

func _ready():
  viewport_camera = parent.get_parent().viewport_camera
  
func _physics_process(delta):
  if ironsight_target == null:
    if initial_position:
      parent.position = lerp(parent.position, initial_position, zoom_speed * delta)
  else:
    parent.position = lerp(parent.position, ironsight_target, zoom_speed * delta)

## Initiates the ironsight zoom and shows scope when it approximately reaches its destination
func zoom():
  if initial_position == null: initial_position = parent.position
  ironsight_target = Vector3.ZERO - position
  if enable_scope and parent.position.is_equal_approx(ironsight_target):
    scope()

## Initiates ironsight zoom out
func zoomout():
  ironsight_target = null
  if enable_scope: unscope()

## Show the scope image and set the field of view
func scope():
  # TODO: show scope image
  viewport_camera.fov = scope_fov
  pass

## Hide the scope image and reset the field of view
func unscope():
  # TODO: hide scope image
  viewport_camera.fov = fov
  pass

## Restores all states to default
func deactivate():
  if initial_position:
    parent.position = initial_position
  zoomout()
