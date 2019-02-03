extends Panel

onready var visual_debugger = get_parent() # For speed and convenience.

func _process(delta):
	var mouse_viewport_position = get_viewport().get_mouse_position() # For speed and convenience.
	if mouse_viewport_position.x < get_rect().size.x * VDGlobal.visual_debugger.scale.x && mouse_viewport_position.y < get_rect().size.y * VDGlobal.visual_debugger.scale.y:
		if !visual_debugger.mouse_is_over_visual_debugger_gui:
			visual_debugger.mouse_is_over_visual_debugger_gui = true
			visual_debugger.remove_child(visual_debugger.scene_node_selector)
	else:
		if visual_debugger.mouse_is_over_visual_debugger_gui:
			visual_debugger.mouse_is_over_visual_debugger_gui = false
			visual_debugger.add_child(visual_debugger.scene_node_selector)
