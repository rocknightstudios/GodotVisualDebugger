extends Tree

onready var show_node_info_button = VDGlobal.visual_debugger.get_node("TabContainer/VisualSelect/SelectedNodeInfo/ShowNodeInfoButton") # For speed and convenience.
onready var indent_width = get_constant("item_margin") # For speed and convenience.
onready var one_character_width = get_font("font").size * FONT_ASPECT_RATIO # To calculate correctly the column 0 width.
onready var relative_indent_coefficient = indent_width / one_character_width # What is the factor between ONE_CHARACTER_WIDTH and indent_width.
onready var parent_node = get_parent() # For speed and convenience.
onready var selection_overlay = parent_node.get_node("SelectionOverlay") # To forbid selecting tree items if mouse is outside VD.

var tree_item = null # To remember which tree item to manage under which.
var deepest_branch_width = 0 # To determine how wide should be the h scroll bar.
var dont_find_the_widest_branch_while_building_the_tree = false # To avoid performing redundant (called by on_collapse signal) work and make management easier.
var current_deepest_item = null # To widen the scope and make management easier.
var icon_dictionary = {} # All the icons for the classes should be assigned here.
var absolute_widest_branch_width = 0 # Which is the widest branch regardless of indentation level and including node type. Width seperately for performance.
var absolute_widest_branch = null # Which is the widest branch regardless of indentation level and including node type.
var absolute_widest_type_text = "" # To correctly calculate the width of the whole branch.
var previous_tree_dictionary = {} # To keep the tree correctly expanded on refresh.

const SPACE_BETWEEN_COLUMNS = 5.0 # How many characters between columns.
const FONT_ASPECT_RATIO = .5 # How much wider is font than it is high.
const OUTLINER_BORDER_WIDTH = 30 # To not activate selection as soon as mouse is over the visual debugger background.

func load_textures(var dir_path):
	var dir = Directory.new()
	dir.open(dir_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if !dir.current_is_dir():
			icon_dictionary[file_name.replace("icon_", "").replace(".svg", "").replace("_", "")] = load(dir_path + "/" + file_name)
		file_name = dir.get_next()

func _ready():
	load_textures("res://VisualDebugger/icons/")
	VDGlobal.visual_debugger.outliner = self
	form_the_whole_outliner()

func add_a_tree_item(node, parent_item):
	tree_item = create_item(parent_item)
	var this_node_class = node.get_class() # For speed and convenience.
	tree_item.set_icon(0, icon_dictionary[this_node_class.to_lower()])
	tree_item.set_text(0, node.name)
	tree_item.set_text(1, this_node_class)
	var node_path = node.get_path() # For speed and convenience.
	tree_item.set_metadata(0, node_path)
	var previous_tree_dictionary_current_item = true # For speed and convenience.
	if previous_tree_dictionary.has(node_path):
		previous_tree_dictionary_current_item = previous_tree_dictionary[node_path]
	tree_item.collapsed = false if parent_item == null else previous_tree_dictionary_current_item

	if this_node_class == "Camera2D" && node != VDGlobal.visual_debugger.debugger_camera:
		VDGlobal.visual_debugger.game_camera = node

func get_all_outline_nodes(node, parent_item):
	add_a_tree_item(node, parent_item)
	parent_item = tree_item
	for i in node.get_children():
		if i.get_child_count() > 0:
			get_all_outline_nodes(i, parent_item)
		else:
			add_a_tree_item(i, parent_item)

func _on_form_the_outliner():
	form_the_whole_outliner()

	if VDGlobal.visual_debugger.debugger_camera != null:
		VDGlobal.visual_debugger.set_debugger_camera()
		VDGlobal.visual_debugger.is_game_camera = true

func fill_previous_tree_dictionary(dictionary_tree_item):
	previous_tree_dictionary[dictionary_tree_item.get_metadata(0)] = dictionary_tree_item.collapsed
	var child_item = dictionary_tree_item.get_children()
	while child_item != null:
		if child_item.get_children() != null:
			fill_previous_tree_dictionary(child_item)
		else:
			previous_tree_dictionary[child_item.get_metadata(0)] = child_item.collapsed
		child_item = child_item.get_next()

func form_the_whole_outliner():
	if get_root() != null:
		previous_tree_dictionary.clear()
		fill_previous_tree_dictionary(get_root())
	clear()
	dont_find_the_widest_branch_while_building_the_tree = true
	get_all_outline_nodes(VDGlobal.cached_root, null)
	dont_find_the_widest_branch_while_building_the_tree = false
	_on_Outliner_item_collapsed(null)

	selection_overlay.rect_size = rect_size

func _on_Outliner_cell_selected():
	var tmp_node_path_metadata = get_selected().get_metadata(0) # For speed and convenience.
	VDGlobal.visual_debugger.full_selected_path = str(tmp_node_path_metadata)
	VDGlobal.visual_debugger.node_is_selected = true
	show_node_info_button.set_info_text(tmp_node_path_metadata.get_name(tmp_node_path_metadata.get_name_count() - 1))

func find_widest_and_deepest_branches(current_branch_root_item):
	while true:
		if str(current_branch_root_item.get_metadata(0)).length() > deepest_branch_width:
			current_deepest_item = current_branch_root_item
			var path_name_count = current_branch_root_item.get_metadata(0).get_name_count() # For speed and convenience.
			deepest_branch_width = path_name_count * relative_indent_coefficient + current_branch_root_item.get_metadata(0).get_name(path_name_count - 1).length()
			if absolute_widest_type_text.length() < current_branch_root_item.get_text(1).length():
				absolute_widest_type_text = current_branch_root_item.get_text(1)
			if absolute_widest_branch_width == 0 || deepest_branch_width > absolute_widest_branch_width:
				absolute_widest_branch_width = deepest_branch_width
				absolute_widest_branch = current_deepest_item
			var current_widest_parent_item = current_branch_root_item.get_parent() # To find out whether the branch is collapsed.
			while true:
				if current_widest_parent_item == null:
					break
				if current_widest_parent_item.collapsed == true:
					path_name_count = current_widest_parent_item.get_metadata(0).get_name_count()
					deepest_branch_width = path_name_count * relative_indent_coefficient + current_widest_parent_item.get_metadata(0).get_name(path_name_count - 1).length()
					break
				current_widest_parent_item = current_widest_parent_item.get_parent()
		if current_branch_root_item.collapsed != true:
			find_widest_and_deepest_branches(current_branch_root_item.get_children())
		current_branch_root_item = current_branch_root_item.get_next()
		if current_branch_root_item == null:
			break

func _on_Outliner_item_collapsed(item):
	if !dont_find_the_widest_branch_while_building_the_tree:
		absolute_widest_branch_width = 0
		deepest_branch_width = 0
		absolute_widest_type_text = ""
		find_widest_and_deepest_branches(get_root())
		absolute_widest_branch_width = (absolute_widest_branch_width + SPACE_BETWEEN_COLUMNS) * one_character_width
		set_column_expand(1, true)
		set_column_expand(0, false)
		set_column_min_width(0, absolute_widest_branch_width)
		absolute_widest_branch_width += absolute_widest_type_text.length() * one_character_width

		selection_overlay.rect_size = rect_size

func find_if_mouse_is_over_outliner():
	var mouse_viewport_position = get_viewport().get_mouse_position() # For speed and convenience.
	var visual_debugger_background_width = VDGlobal.visual_debugger.visual_debugger_background.rect_size.x * VDGlobal.visual_debugger.scale.x # For speed and convenience.
	if mouse_viewport_position.x < visual_debugger_background_width - OUTLINER_BORDER_WIDTH * VDGlobal.visual_debugger.scale.x:
		return true
	else:
		return false

func _process(delta):
	if find_if_mouse_is_over_outliner():
		if parent_node.get_child_count() > 1:
			parent_node.remove_child(selection_overlay)
	elif parent_node.get_child_count() == 1:
		parent_node.add_child(selection_overlay)
