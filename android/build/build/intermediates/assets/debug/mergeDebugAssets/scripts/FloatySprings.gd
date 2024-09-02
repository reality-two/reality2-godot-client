# ======================================================================================================================================================
# Floaty Springs
# --------------
#
# A way to create objects with children that encircle them, keeping on average a specified distance from each other and the centre object, in a springy,
# floaty way.
#
# Dr. Roy C.Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

class_name FloatySprings

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# The main class
# ------------------------------------------------------------------------------------------------------------------------------------------------------
class Planet:
	
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Public Attributes
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	## Closest Distance between Sentants
	var closestDistance = 30.0
	## Stiffness of Spring between Sentants
	var springStiffness = 0.1
	## Stiffness of Spring to centre object
	var centreSpringStiffness = 10.0
	## Distance to centre object
	var centreDistance = 10.0
	## Damping / friction
	var damping = 0.1
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	
	
	
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Private Attributes
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	var _velocity = Vector3(0,0,0)
	var _force = Vector3(0,0,0)
	var _friction = 0.5
	var _mass = 1.0
	
	var _core: Node3D
	# --------------------------------------------------------------------------------------------------------------------------------------------------



	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Constructor
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	func _init(parent, _name = "Test", _color = Color.CADET_BLUE):
		# Something to interact with
		var area = Area3D.new()
		area.set_ray_pickable(true)
		var collider = CollisionShape3D.new()
		collider.set_shape(SphereShape3D.new())
		collider.shape.set_radius(0.5)
		
		# Add to the parent
		area.add_child(collider)
		parent.add_child(area)

		# A little randomness to make sure the objects move around OK
		parent.position = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 0.1
		
		# Set for later
		_core = parent
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	
	

	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Call this every frame to update the positions of each object
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	func update(delta):
		_force = Vector3(0,0,0)
		
		# The children of my parent must be siblings...
		var siblings = _core.get_parent().get_children()
		
		# Iterate through, ignoring myself, and set a force to each other sibling
		for sibling in siblings:
			if (sibling != self) && (sibling is Node3D):
				var direction = _core.position - sibling.position
				var forceValue = direction.length() - closestDistance
				var normalizedDirection = direction.normalized()
				var thisForce = (normalizedDirection * -springStiffness * forceValue) - (_velocity * damping)
				_force += thisForce
		
		# Calculate a force to the centre (parent)
		var directionCentre = _core.position
		var forceValueCentre = directionCentre.length() - centreDistance
		var normalizedDirectionCentre = directionCentre.normalized()
		_force += (normalizedDirectionCentre * -centreSpringStiffness * forceValueCentre) - (_velocity * damping)

		# Adjust for friction
		var frictionForce = _velocity * -_friction
		
		# How much to move since the last frame
		_velocity = ((_force + frictionForce) / _mass) * delta
		
		# Set the new position
		_core.position = _core.position + _velocity
# ------------------------------------------------------------------------------------------------------------------------------------------------------
