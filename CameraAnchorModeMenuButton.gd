extends MenuButton

func _ready():
	self.get_popup().connect("id_pressed", self, "manage_id")
	if VDGlobal.visual_debugger.debugger_camera:
		self.text = str(VDGlobal.visual_debugger.debugger_camera.anchor_mode)

func manage_id(ID):
	VDGlobal.visual_debugger.debugger_camera.anchor_mode = ID
	self.text = self.get_popup().get_item_text(ID)

func _process(delta):
	if get_child(0).visible:
		get_child(0).rect_position = Vector2(rect_global_position.x, rect_global_position.y + rect_size.y)
