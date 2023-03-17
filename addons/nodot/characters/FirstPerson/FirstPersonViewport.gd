class_name FirstPersonViewport extends SubViewportContainer

## Creates a viewport that can be used for first person items. For example hands and guns.
##
## The viewport camera only renders items on layer 2 so items are always rendered over the rest of the scene. This is useful when you don't want your gun to clip into a wall. 

@export_flags_3d_render var camera_cull_mask_layer = 2 ## Which cull mask layers to give the camera
@export var fov := 75 ## The viewport cameras field of view
@export var item_position := Vector3.ZERO ## (optional) The default item position
@export var viewport_camera: Camera3D ## (optional) The first person viewport camera

var character_camera: Camera3D
var viewport: SubViewport

signal item_change(item: FirstPersonItem)

var item_changing := false
var active_item_index := 0

func _get_configuration_warnings() -> PackedStringArray:
  var warnings: PackedStringArray = []
  if !(get_parent() is FirstPersonCharacter):
    warnings.append("Parent should be a FirstPersonCharacter")
  return warnings
  
func _enter_tree():
  var subviewport = SubViewport.new()
  subviewport.name = "SubViewport"
  subviewport.transparent_bg = true
  subviewport.handle_input_locally = false
  var camera3d = Camera3D.new()
  camera3d.name = "Camera3D"
  camera3d.cull_mask = camera_cull_mask_layer
  camera3d.fov = fov
  subviewport.add_child(camera3d)
  add_child(subviewport)
  viewport = subviewport
  viewport_camera = camera3d
  character_camera = get_parent().camera
  
func _ready():    
  # Move existing children to be a child of the camera
  for child in get_children():
    if child.get_class() != "SubViewport":
      var saved_transform = child.transform
      child.reparent(viewport_camera, true)
      if child is FirstPersonItem:
        if item_position == Vector3.ZERO:
          child.transform = saved_transform
        else:
          child.position = item_position
  
  if is_instance_valid(WindowManager):
    WindowManager.connect("window_resized", _on_window_resized)
    WindowManager.bump()
  
func _physics_process(_delta):
  viewport_camera.global_transform = character_camera.global_transform
  viewport_camera.rotation.z = 0.0

func _on_window_resized(new_size: Vector2):
  viewport.size = new_size

## Select the next item
func next_item():
  change_item(active_item_index + 1)

## Select the previous item
func previous_item():
  change_item(active_item_index - 1)
  
## Get the active item
func get_active_item():
  for item in viewport_camera.get_children():
    if item is FirstPersonItem and item.active:
      return item
      
## Get all FirstPersonItems
func get_all_items():
  var items: Array[FirstPersonItem] = []
  for item in viewport_camera.get_children():
    if item is FirstPersonItem:
      items.append(item)
  return items

## Change which item is active.
func change_item(new_index: int):
  if item_changing == false:
    item_changing = true
    var items = get_all_items()
    var item_count = items.size()
    if new_index >= item_count - 1:
      active_item_index = item_count - 1
    elif new_index <= 0:
      active_item_index = 0
    else:
      active_item_index = new_index
    
    var active_item = get_active_item()
    if active_item:
      await active_item.deactivate()
    
    await items[active_item_index].activate()
    item_changing = false
    emit_signal("item_change", items[active_item_index])

func action():
  var active_item = get_active_item()
  if active_item and active_item.has_method("action"): active_item.action()
  
func zoom():
  var active_item = get_active_item()
  if active_item and active_item.has_method("zoom"): active_item.zoom()

func zoomout():
  var active_item = get_active_item()
  if active_item and active_item.has_method("zoomout"): active_item.zoomout()

func reload():
  var active_item = get_active_item()
  if active_item and active_item.has_method("reload"): active_item.reload()
