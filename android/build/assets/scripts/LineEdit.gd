extends LineEdit

signal esc_key_pressed

func _unhandled_key_input(event):
	if (event.keycode== KEY_ESCAPE):
		emit_signal("esc_key_pressed")
