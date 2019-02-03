extends Button

func _on_ZoomTo_pressed():
	VDGlobal.visual_debugger.debugger_camera.set_zoom_to()

var zoom_to_is_being_pressed = false # To execute the zoom only once.

func _process(delta):
	if Input.is_key_pressed(KEY_F10):
		if !zoom_to_is_being_pressed:
			_on_ZoomTo_pressed()
			zoom_to_is_being_pressed = true
	else:
		zoom_to_is_being_pressed = false
