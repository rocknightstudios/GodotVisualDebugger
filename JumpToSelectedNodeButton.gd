extends Button

func _on_JumpToSelectedNodeButton_pressed():
	if get_parent().get_node("ShowNodeInfoButton"):
		if VDGlobal.visual_debugger.full_selected_path != "":
			if get_node(VDGlobal.visual_debugger.full_selected_path) != null:
				var relative_position = get_node(VDGlobal.visual_debugger.full_selected_path).get_global_transform().origin # For speed and convenience.
				VDGlobal.visual_debugger.set_moving_to_node(true, relative_position)
			else:
				print("Oh, noh, nothing to follow, level probably got reloaded!")
		else:
			VDGlobal.visual_debugger.warning_line.text = "There is no node selected! Please select a node, to which to jump."
	else:
		VDGlobal.visual_debugger.warning_line.text = "The selected info node path is incorrect! Maybe node is removed from node tree."
