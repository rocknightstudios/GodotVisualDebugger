extends Button

func _on_StepButton_button_down():
	do_a_step()

func do_a_step():
	get_tree().paused = false
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	get_tree().paused = true

var button_is_being_pressed = false # To manage single click.

func _process(delta):
	if Input.is_key_pressed(KEY_F9):
		if !button_is_being_pressed:
			button_is_being_pressed = true
			do_a_step()
	else:
		button_is_being_pressed = false
