extends Node2D

var node_types_to_blacklist = [] # What type of nodes to detect.
export var selection_color = Color(0, .1, 0, .1) # What color to use for selection precision area.
export var reversed_node_path = [] # To have persistency through the recursion.

onready var selection_info = get_parent().get_node("TabContainer/VisualSelect/SelectionInfo") # For speed and convenience.
onready var ignore_nodes_types = selection_info.get_parent().get_node("IgnoreNodesTypes") # For speed and convenience.
onready var enable_visual_selection_button = VDGlobal.visual_debugger.get_node("TabContainer/VisualSelect/EnableVisualSelectionLabel/EnableVisualSelectionButton") # For speed and convenience.

var selection_radius = 50.0 # How precisely to detect the selectable node.
var relative_mouse_position = Vector2(0.0, 0.0) # To detect object relative to the debugger camera position.
var absolute_mouse_position = Vector2(0.0, 0.0) # For speed and convenience.
var full_paths = [] # To quickly access full path for each node.
var is_left_mouse_button_being_pressed = false # To detect just a single click.

const MAX_SELECTION_RADIUS_SIZE = 2000.0 # To avoid having magic numbers.
const MIN_SELECTION_RADIUS_SIZE = 5.0 # To avoid having magic numbers.
const SELECTION_RADIUS_CHANGE_COEFFICIENT = .1 # To avoid having magic numbers.

func _input(event):
	if enable_visual_selection_button.pressed:
		if !Input.is_key_pressed(KEY_CONTROL):
			manage_customization_params(event)
		manage_selection()

func manage_customization_params(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			selection_radius = min(selection_radius + selection_radius * SELECTION_RADIUS_CHANGE_COEFFICIENT, MAX_SELECTION_RADIUS_SIZE)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			selection_radius = max(selection_radius - selection_radius * SELECTION_RADIUS_CHANGE_COEFFICIENT, MIN_SELECTION_RADIUS_SIZE)

func _process(delta):
	absolute_mouse_position = get_viewport().get_mouse_position()
	relative_mouse_position = VDGlobal.visual_debugger.debugger_camera.position + absolute_mouse_position * VDGlobal.visual_debugger.debugger_camera.zoom
	update()

func manage_selection():
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if !is_left_mouse_button_being_pressed:
			is_left_mouse_button_being_pressed = true
			if !VDGlobal.visual_debugger.forbid_selection_circle_management && !VDGlobal.visual_debugger.mouse_is_over_visual_debugger_gui:
				node_types_to_blacklist.clear()
				for i in range(0, ignore_nodes_types.get_line_count()):
					node_types_to_blacklist.append(ignore_nodes_types.get_line(i))

				selection_info.text = ""
				full_paths = []
				if VDGlobal.visual_debugger.game_camera:
					get_all_nodes(VDGlobal.cached_root)
				selection_info.text = selection_info.text.substr(1, selection_info.text.length() - 1)
	else:
		is_left_mouse_button_being_pressed = false

func determine_whether_this_node_is_under_mouse(node):
	var manage_this_node = false # For convenience.
	var current_node_class = node.get_class() # For speed and convenience.
	if "rect_global_position" in node || "global_position" in node:
		manage_this_node = true
	if node_types_to_blacklist.has(current_node_class):
		manage_this_node = false

	if manage_this_node:
		if relative_mouse_position.distance_to(node.get_global_transform().origin) < selection_radius * VDGlobal.visual_debugger.scale.x * VDGlobal.visual_debugger.debugger_camera.zoom.x:
			var full_node_path = "" # To form the full node path.
			reversed_node_path = []
			selection_info.text += "\n" + node.name + ": " + current_node_class
			get_reversed_node_path(node)
			for i in range(reversed_node_path.size() - 1, -1, -1):
				full_node_path += "/" + reversed_node_path[i]
			full_paths.append(full_node_path)

func get_reversed_node_path(node):
	reversed_node_path.append(node.name)
	if node.get_parent():
		get_reversed_node_path(node.get_parent())

func get_all_nodes(node):
	for i in node.get_children():
		if i.get_child_count() > 0:
			determine_whether_this_node_is_under_mouse(i)
			get_all_nodes(i)
		else:
			determine_whether_this_node_is_under_mouse(i)

func _draw():
	if enable_visual_selection_button.pressed && !VDGlobal.visual_debugger.forbid_selection_circle_management:
		draw_circle(absolute_mouse_position / VDGlobal.visual_debugger.scale, selection_radius, selection_color);
	else:
		draw_circle(absolute_mouse_position, selection_radius, Color(0.0, 0.0, 0.0, 0.0));
