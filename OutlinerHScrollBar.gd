extends HScrollBar

onready var outliner_container = get_parent().get_node("OutlinerContainer") # For speed and convenience.
onready var outliner = outliner_container.get_node("Outliner") # For speed and convenience.
onready var outliner_width = outliner.rect_size.x # For speed and convenience.
onready var branch_width_threshold = outliner.rect_size.x * .42 # If the path to the tree item is wider than this show the horizontal scroll bar.

const RIGHT_OFFSET_FOR_V_SCROLL_BAR = -12 # To avoid having magic numbers.

onready var the_vertical_scroll_bar = find_vertical_scroll_bar() # To hack around and reposition the vertical runtime scroll bar.

func find_vertical_scroll_bar():
	var outliner_children = outliner.get_children() # For speed and graceful return from the function.
	for i in range(0, outliner.get_child_count()):
		if outliner_children[i].get_class() == "VScrollBar":
			return outliner_children[i]

func _process(delta):
	the_vertical_scroll_bar.rect_position.x = outliner_container.rect_size.x + RIGHT_OFFSET_FOR_V_SCROLL_BAR + value
	if outliner.absolute_widest_branch_width > branch_width_threshold:
		visible = true
		max_value = outliner.absolute_widest_branch_width
		page = outliner.absolute_widest_branch_width - (outliner.absolute_widest_branch_width - branch_width_threshold)
		outliner.rect_position.x = -value
	else:
		visible = false
