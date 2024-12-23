# ======================================================================================================================================================
# R2 Node
# -------
#
# Represents a Reality2 node graphically.
#
# Dr. Roy C.Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

extends Node3D

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Public variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
@export var r2class: String
@export var details = {}
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Private variables
# ------------------------------------------------------------------------------------------------------------------------------------------------------
var sentant_scene = preload("res://scenes/R2Sentant.tscn")
var angularVelocity = Vector3(0,0,0)
var shape
var connecting_line
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Set up various aspects of the shape, and the initial floaty springs stuff
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _ready():
	shape = FloatySprings.Planet.new(self, "Reality2Node", Color.BLUE)
	shape.centreDistance = 10.0
	shape.closestDistance = 20.0
	connecting_line = Shapes.Line.new(self, Color.NAVY_BLUE)
	
	var title = Label3D.new()
	title.text = name
	title.set_outline_size(0)
	title.modulate = Color.BISQUE
	title.billboard = true
	title.pixel_size = 0.005
	title.position = Vector3(0.0, 0.0, 0.0)
	title.no_depth_test = true
	title.visibility_range_end = 15.0
	title.font_size = 30
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Called every frame. 'delta' is the elapsed time since the previous frame.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func _process(delta):
	# Update the shapes
	shape.update(delta)
	
	# Add a bit of gentel motion
	angularVelocity = Useful.gentle_twist(delta, angularVelocity)
	rotation = rotation + angularVelocity
	
	# Update the connecting line between this node and its parent
	connecting_line.adjust_line(Vector3(0,0,0), to_local(get_parent().global_position))
# ------------------------------------------------------------------------------------------------------------------------------------------------------


	
# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Given an array of Sentant details, create the sentant graphical representations connected to this Node.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func load_sentants(nodeName, url, sentants = []):
	# Remove any existing Sentants
	for child in get_children():
		if (!(child.name.begins_with("___") and child.name.ends_with("___"))):
			remove_child(child)

	# Add the 'new' ones from the list
	for sentant in sentants:
		if (sentant.has("name")):
			add_sentant(nodeName, url, sentant["name"], sentant)
# ------------------------------------------------------------------------------------------------------------------------------------------------------


	
# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Add a Sentant to this Node
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func add_sentant(nodeName, url, sentant_name, sentant_details = {}):
	var new_sentant = sentant_scene.instantiate()
	new_sentant.name = sentant_name
	print(details)
	sentant_details.nodeName = nodeName
	sentant_details.url = url 
	new_sentant.details = sentant_details
	new_sentant.r2class = "sentant"
	new_sentant.details = sentant_details
	add_child(new_sentant)
# ------------------------------------------------------------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Remove a Sentant from this node
# ------------------------------------------------------------------------------------------------------------------------------------------------------
func remove_sentant(sentant_name):
	for child in get_children():
		if (child.name == sentant_name):
			remove_child(child)
			child.queue_free()
# ------------------------------------------------------------------------------------------------------------------------------------------------------
