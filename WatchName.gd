extends TextEdit

var focus_was_outside = true # To only select all the first time.

func _on_WatchName_gui_input(ev):
	if Input.is_mouse_button_pressed(BUTTON_LEFT) && focus_was_outside:
		focus_was_outside = false
		select_all()

func _on_WatchName_focus_exited():
	focus_was_outside = true
