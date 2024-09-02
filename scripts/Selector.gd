# ======================================================================================================================================================
# Selector
# --------
#
# Selects an object by the mouse.
#
# Dr. Roy C.Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

extends Node3D

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Public variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
@export var orbitControls: Control
@export var UX: Node
@export var reality2_object: Node
# ------------------------------------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Private variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
var currentObject: Node3D
var lerper = 0.0
var xr_interface: XRInterface
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Set up some XR stuff.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _ready():
	UX.set_menu("Reality2")
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Update the viewing direction smoothly.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _process(delta):
	if (orbitControls):
		if (currentObject != null):
			lerper = min(1.0, lerper + 0.5 * delta)
			if (lerper == 1.0):
				orbitControls.target = currentObject.global_position
			else:
				orbitControls.target = orbitControls.target.lerp(currentObject.global_position, lerper)
			orbitControls.update()
		else:
			if (reality2_object):
				if (currentObject != reality2_object):
					currentObject = reality2_object
					lerper = 0
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# From the mouse position, find which object is under the mouse when clicked, and move the view to look at it.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _unhandled_input(event):
	if (event is InputEventMouseButton):
		#print(event)
		if event["button_index"] == 1 && event["pressed"]:
			handle_input(event)
	elif (event is InputEventScreenTouch):
		if event["index"] == 0 && event["pressed"]:
			handle_input(event)
		
func handle_input(_event):
	var space = get_world_3d().get_direct_space_state()
	var mousePosViewport = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var rayOrigin = camera.project_ray_origin(mousePosViewport)
	var rayEnd = rayOrigin+camera.project_ray_normal(mousePosViewport)*100
	var detectionParameters = PhysicsRayQueryParameters3D.new() 
	detectionParameters.collide_with_bodies = true
	detectionParameters.collide_with_areas = true
	detectionParameters.from = rayOrigin
	detectionParameters.to = rayEnd	
	
	var result = space.intersect_ray(detectionParameters)
	if result and result.collider:
		var object = result.collider.get_parent()
		print("Selected : " + object.name)
		if (object.name == "Center"):
			UX.set_menu("Reality2", {})
		#elif (object.name == "monitor"):
			#UX.set_menu("None", object.details)
		elif object.r2class == "node":
			UX.set_menu("Node", object.details)					
		elif object.r2class == "sentant":
			UX.set_menu("Sentant", object.details)		
			
		if ("r2class" in object): 
			print (object.r2class)
		currentObject = object
		lerper = 0.0
	else:
		UX.unselect()
		
	
# ------------------------------------------------------------------------------------------------------------------------------------------------------
