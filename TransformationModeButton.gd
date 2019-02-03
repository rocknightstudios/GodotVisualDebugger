extends MenuButton

func _ready():
	var parent_pos = get_parent().get_global_transform().origin # For speed and convenience.
	self.get_parent().get_global_transform().origin = parent_pos
	self.get_popup().connect("id_pressed", self, "manage_id")

func manage_id(ID):
	VDGlobal.visual_debugger.transformation_mode = ID
	self.text = "Transformation mode: " + self.get_popup().get_item_text(ID)

func _process(delta):
	if get_child(0).visible:
		get_child(0).rect_position = Vector2(rect_global_position.x, rect_global_position.y + rect_size.y)
