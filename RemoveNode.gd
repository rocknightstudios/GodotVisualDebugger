extends Button

func _on_RemoveNode_pressed():
	VDGlobal.visual_debugger.node_is_selected = false
	get_node(VDGlobal.visual_debugger.full_selected_path).queue_free();
