extends CheckButton

onready var jump_to_node_button = VDGlobal.visual_debugger.get_node("TabContainer/VisualSelect/SelectedNodeInfo/JumpToSelectedNodeButton") # For speed and convenience.

func _process(delta):
	if self.pressed:
		jump_to_node_button._on_JumpToSelectedNodeButton_pressed()