extends MeshInstance3D

#var t
#
#func _ready():
	#t = create_tween().set_loops(0)
	#t.tween_property(self, "rotation_degrees:y", 360.0, 0.0).from(0.0)
#
#func _process(delta):
	#var parent_rotation = get_parent().rotation
	#t.tween_property(self, "rotation_degrees:x", 360.0, parent_rotation.x).from(0.0)
	#t.tween_property(self, "rotation_degrees:y", 360.0, parent_rotation.y).from(0.0)
	#t.tween_property(self, "rotation_degrees:z", 360.0, parent_rotation.z).from(0.0)
