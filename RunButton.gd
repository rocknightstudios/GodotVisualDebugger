extends Button

func _on_RunButton_button_down():
	get_tree().paused = false

func _process(delta):
	if Input.is_key_pressed(KEY_CONTROL) && Input.is_key_pressed(KEY_F9):
		get_tree().paused = false
