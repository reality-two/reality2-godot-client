# ======================================================================================================================================================
# Useful
# ------
#
# Some useful functions.
#
# Dr. Roy C.Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

class_name Useful

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# Create a gentle twisting, swaying motion.  When called, keep the angularVelocity as a variable, and call from the _process function, passing in delta.
# ------------------------------------------------------------------------------------------------------------------------------------------------------
static func gentle_twist(delta, angularVelocity: Vector3):
	# Create some gentle sway-y motion
	if (randf() > 0.7):
		var stepValue = delta / 1000
		var maxValue = stepValue * 20.0
		
		var xDirection = randf() > 0.5
		var yDirection = randf() > 0.5
		var zDirection = randf() > 0.5
		
		if (xDirection):
			angularVelocity.x += stepValue
		else:
			angularVelocity.x -= stepValue
		angularVelocity.x = clampf(angularVelocity.x, -maxValue, maxValue)
			
		if (yDirection):
			angularVelocity.y += stepValue
		else:
			angularVelocity.y -= stepValue	
		angularVelocity.y = clampf(angularVelocity.y, -maxValue, maxValue)
			
		if (zDirection):
			angularVelocity.z += stepValue
		else:
			angularVelocity.z -= stepValue
		angularVelocity.z = clampf(angularVelocity.z, -maxValue, maxValue)
	
	# return the new angular velocity
	return(angularVelocity)
# ------------------------------------------------------------------------------------------------------------------------------------------------------
