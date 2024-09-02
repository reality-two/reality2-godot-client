# ======================================================================================================================================================
# Shapes
# ------
#
# A class to add some useful shapes such as a line.
#
# Dr. Roy C.Davies
# roycdavies.github.io
# March 2024
# ======================================================================================================================================================

class_name Shapes

class Line:
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Attributes
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	var _mesh
	var _material
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	
	
	
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Create the line
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	func _init(parent, color = Color.CORNFLOWER_BLUE, start=Vector3(), end=Vector3()):
		_mesh = MeshInstance3D.new()
		var immediate_mesh := ImmediateMesh.new()
		_material = StandardMaterial3D.new()

		_mesh.mesh = immediate_mesh
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
		immediate_mesh.surface_add_vertex(start)
		immediate_mesh.surface_add_vertex(end)
		immediate_mesh.surface_end()

		_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		_material.albedo_color = color
		parent.add_child(_mesh)
	# --------------------------------------------------------------------------------------------------------------------------------------------------



	# --------------------------------------------------------------------------------------------------------------------------------------------------
	# Set the line's start and finish points
	# --------------------------------------------------------------------------------------------------------------------------------------------------
	func adjust_line(start, end):
		_mesh.mesh.clear_surfaces()

		_mesh.mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
		_mesh.mesh.surface_add_vertex(start)
		_mesh.mesh.surface_add_vertex(end)
		_mesh.mesh.surface_end()
	# --------------------------------------------------------------------------------------------------------------------------------------------------
