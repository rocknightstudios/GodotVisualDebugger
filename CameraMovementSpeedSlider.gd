extends HSlider

func _on_CameraMovementSpeedSlider_mouse_entered():
	editable = true

func _on_CameraMovementSpeedSlider_mouse_exited():
	editable = false
