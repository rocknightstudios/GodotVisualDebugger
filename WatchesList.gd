extends ItemList

onready var watch_name = get_parent().get_node("WatchName") # For speed and convenience.
onready var outliner = get_parent().get_node("OutlinerContainer").get_node("Outliner") # For speed and convenience.
onready var watch_value = get_parent().get_node("WatchValue") # For speed and convenience.
onready var h_scroll_bar = get_parent().get_node("HScrollBar") # For speed and convenience. Is under parent to be visible outside this ItemList bounds.
onready var node_check_box = get_parent().get_node("WatchFieldWrapper").get_node("NodeCheckBox") # For speed and convenience.
onready var name_check_box = get_parent().get_node("WatchFieldWrapper").get_node("NameCheckBox") # For speed and convenience.
onready var value_check_box = get_parent().get_node("WatchFieldWrapper").get_node("ValueCheckBox") # For speed and convenience.
onready var type_check_box = get_parent().get_node("WatchFieldWrapper").get_node("TypeCheckBox") # For speed and convenience.
onready var raw_check_box = get_parent().get_node("WatchFieldWrapper").get_node("RawCheckBox") # For speed and convenience.
onready var unique_check_box = get_parent().get_node("WatchFieldWrapper").get_node("UniqueCheckBox") # For speed and convenience.

var current_watches_list = null # To keep a backup of all the list items including non unique ones.
var h_scroll_value = 0 # To know, what substring of item text to form.
var type_names = ["TYPE_NIL", "TYPE_BOOL", "TYPE_INT", "TYPE_REAL", "TYPE_STRING", "TYPE_VECTOR2", "TYPE_RECT2", "TYPE_VECTOR3", "TYPE_TRANSFORM2D", "TYPE_PLANE", "TYPE_QUAT", "TYPE_AABB", "TYPE_BASIS", "TYPE_TRANSFORM", "TYPE_COLOR", "TYPE_NODE_PATH", "TYPE_RID", "TYPE_OBJECT", "TYPE_DICTIONARY", "TYPE_ARRAY", "TYPE_RAW_ARRAY", "TYPE_INT_ARRAY", "TYPE_REAL_ARRAY", "TYPE_STRING_ARRAY", "TYPE_VECTOR2_ARRAY", "TYPE_VECTOR3_ARRAY", "TYPE_COLOR_ARRAY", "TYPE_MAX"]
var item_count = 0 # For speed and convenience.
var previous_h_scroll_value = 0 # To detect, when it is required to update all watch values.
var last_checkbox_checked_state = 0 # To determine, where to reset the state.

const MIN_CHARACTERS_LIST_ITEM = 42 # Don't let to show less than five character in the list item.
const ICON_WIDTH_COMPENSATION = 3 # Text must be able to scroll a bit further, because icons take a bit of space.

func remove_a_watch():
	remove_item(get_selected_items()[0])
	item_count -= 1;

func add_a_watch():
	if watch_name.text != "Type watch name":
		var currently_selected_node = outliner.get_selected() # For speed and convenience.
		if currently_selected_node == null:
			print("No node is selected, so no behaviour is performed.")
		else:
			add_item(watch_name.text, null, true)
			item_count = get_item_count()
			set_item_metadata(item_count - 1, [currently_selected_node.get_metadata(0), watch_name.text, 0])
			set_watch_value(item_count - 1)
			select(item_count - 1, true)
			if unique_check_box.pressed == true:
				if current_watches_list != null:
					current_watches_list.append([get_item_text(item_count - 1), get_item_metadata(item_count - 1)])

func set_up_h_scroll_bar():
	var longest_item_string_length = 0 # To limit the h scroll bar max value.
	for i in range(0, item_count):
		var string_length = get_item_metadata(i)[2] # For speed and convenience.
		if string_length > longest_item_string_length:
			longest_item_string_length = string_length

	if longest_item_string_length > MIN_CHARACTERS_LIST_ITEM:
		h_scroll_bar.visible = true
		h_scroll_bar.max_value = longest_item_string_length - MIN_CHARACTERS_LIST_ITEM + ICON_WIDTH_COMPENSATION
		h_scroll_bar.page = h_scroll_bar.max_value * (MIN_CHARACTERS_LIST_ITEM / float(longest_item_string_length))
	else:
		h_scroll_bar.visible = false

func _ready():
	h_scroll_bar.visible = false

func set_watch_value(index):
	var item_metadata = get_item_metadata(index) # For speed and convenience.
	if item_metadata != null:
		var current_node = get_node(item_metadata[0]) # For speed and convenience.
		var current_node_path = current_node.get_path() # For speed and convenience.
		var checkbox_mask = 0 # Bitwise mask to simplify logic and speed up calculations.
		if node_check_box.pressed:
			checkbox_mask |= 1
		if name_check_box.pressed:
			checkbox_mask |= 2
		if value_check_box.pressed:
			checkbox_mask |= 4
		if type_check_box.pressed:
			checkbox_mask |= 8

		if checkbox_mask == 0:
			checkbox_mask = last_checkbox_checked_state
			if checkbox_mask == 1:
				node_check_box.pressed = true
			elif checkbox_mask == 2:
				name_check_box.pressed = true
			elif checkbox_mask == 4:
				value_check_box.pressed = true
			elif checkbox_mask == 8:
				type_check_box.pressed = true
		else:
			last_checkbox_checked_state = checkbox_mask

		var node_string = current_node_path.get_name(current_node_path.get_name_count() - 1) # For convenience.
		var name_string = item_metadata[1] # For convenience.
		var value_string = current_node.get(item_metadata[1]) # For convenience.
		var type_string = type_names[typeof(current_node.get(item_metadata[1]))] # For convenience.
		var raw_check_box_is_pressed = raw_check_box.pressed # For speed and convenience.

		var item_text = ""
		if checkbox_mask == 1:
			if raw_check_box_is_pressed:
				item_text = str(node_string)
			else:
				item_text = str("Node = ", node_string)
		elif checkbox_mask == 2:
			if raw_check_box_is_pressed:
				item_text = str(name_string)
			else:
				item_text = str("Watch = ", name_string)
		elif checkbox_mask == 3:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", name_string)
			else:
				item_text = str(node_string, "->", name_string)
		elif checkbox_mask == 4:
			if raw_check_box_is_pressed:
				item_text = str(value_string)
			else:
				item_text = str("Value = ", value_string)
		elif checkbox_mask == 5:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", value_string)
			else:
				item_text = str("Node = ", node_string, " | Value = ", value_string)
		elif checkbox_mask == 6:
			if raw_check_box_is_pressed:
				item_text = str(name_string, " ", value_string)
			else:
				item_text = str("Watch = ", name_string, " | Value = ", value_string)
		elif checkbox_mask == 7:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", name_string, " ", value_string)
			else:
				item_text = str(node_string, "->", name_string, " = ", value_string)
		elif checkbox_mask == 8:
			if raw_check_box_is_pressed:
				item_text = str(type_string)
			else:
				item_text = str("Type = ", type_string)
		elif checkbox_mask == 9:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", type_string)
			else:
				item_text = str("Node = ", node_string, " | Type ", type_string)
		elif checkbox_mask == 10:
			if raw_check_box_is_pressed:
				item_text = str(name_string, " ", type_string)
			else:
				item_text = str("Watch = ", name_string, " | Type ", type_string)
		elif checkbox_mask == 11:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", name_string, " ", type_string)
			else:
				item_text = str("Node = ", node_string, " | Watch = ", name_string, " | Type ", type_string)
		elif checkbox_mask == 12:
			if raw_check_box_is_pressed:
				item_text = str(value_string, " ", type_string)
			else:
				item_text = str("Value = ", value_string, " | Type ", type_string)
		elif checkbox_mask == 13:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", value_string, " ", type_string)
			else:
				item_text = str("Node = ", node_string, " | Value = ", value_string, " | Type ", type_string)
		elif checkbox_mask == 14:
			if raw_check_box_is_pressed:
				item_text = str(name_string, " ", value_string, " ", type_string)
			else:
				item_text = str("Watch = ", name_string, " | Value = ", value_string, " | Type ", type_string)
		elif checkbox_mask == 15:
			if raw_check_box_is_pressed:
				item_text = str(node_string, " ", name_string, " ", value_string, " ", type_string)
			else:
				item_text = str(node_string, "->", name_string, " = ", value_string, " : ", type_string)

		set_item_icon(index, outliner.icon_dictionary[current_node.get_class().to_lower()])

		var item_text_length = item_text.length() # For speed and convenience.
		set_item_metadata(index, [item_metadata[0], item_metadata[1], item_text_length])
		var actual_scroll_value = floor(h_scroll_value * (h_scroll_bar.max_value / (h_scroll_bar.max_value - h_scroll_bar.page))) # For speed and convenience.
		if actual_scroll_value < item_text_length:
			set_item_text(index, item_text.substr(actual_scroll_value, item_text_length - actual_scroll_value))
		else:
			set_item_text(index, "\n")

		set_up_h_scroll_bar()

func modify_watch_value():
	if item_count > 0 && watch_value.text.length() > 0 && watch_value.text != "Type value here":
		var type_index_of_the_new_value = typeof(get_node(get_item_metadata(get_selected_items()[0])[0]).get(get_item_metadata(get_selected_items()[0])[1])) # For speed and convenience.
		var value_array = null # To correctly parse string.
		var selected_item_index = get_selected_items()[0] # For speed and convenience.
		if type_index_of_the_new_value == TYPE_NIL:
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], null)
		elif type_index_of_the_new_value == TYPE_BOOL:
			if watch_value.text.to_upper() == "TRUE":
				get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], true)
			elif watch_value.text.to_upper() == "FALSE":
				get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], false)
		elif type_index_of_the_new_value == TYPE_INT:
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], int(watch_value.text))
		elif type_index_of_the_new_value == TYPE_REAL:
			# LOG AT BOTTOM print("Conversion is performed using float constructor!")
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], float(watch_value.text))
		elif type_index_of_the_new_value == TYPE_STRING:
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], watch_value.text)
		elif type_index_of_the_new_value == TYPE_VECTOR2:
			value_array = watch_value.text.replace("(", "").replace(")", "").split(",")
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], Vector2(value_array[0], value_array[1]))
		elif type_index_of_the_new_value == TYPE_RECT2:
			print("TYPE_RECT2 is not yet implemented")
		elif type_index_of_the_new_value == TYPE_VECTOR3:
			value_array = watch_value.text.replace("(", "").replace(")", "").split(",")
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], Vector3(value_array[0], value_array[1], value_array[2]))
		elif type_index_of_the_new_value == TYPE_TRANSFORM2D:
			print("TYPE_TRANSFORM2D is not yet implemented")
		elif type_index_of_the_new_value == TYPE_PLANE:
			print("TYPE_PLANE is not yet implemented")
		elif type_index_of_the_new_value == TYPE_QUAT:
			print("TYPE_QUAT is not yet implemented")
		elif type_index_of_the_new_value == TYPE_AABB:
			print("TYPE_AABB is not yet implemented")
		elif type_index_of_the_new_value == TYPE_BASIS:
			print("TYPE_BASIS is not yet implemented")
		elif type_index_of_the_new_value == TYPE_TRANSFORM:
			print("TYPE_TRANSFORM is not yet implemented")
		elif type_index_of_the_new_value == TYPE_COLOR:
			value_array = watch_value.text.replace("(", "").replace(")", "").split(",")
			get_node(get_item_metadata(selected_item_index)[0]).set(get_item_metadata(selected_item_index)[1], Color(value_array[0], value_array[1], value_array[2], value_array[3]))
		elif type_index_of_the_new_value == TYPE_NODE_PATH:
			print("TYPE_NODE_PATH is not yet implemented")
		elif type_index_of_the_new_value == TYPE_RID:
			print("TYPE_RID is not yet implemented")
		elif type_index_of_the_new_value == TYPE_OBJECT:
			print("TYPE_OBJECT is not yet implemented")
		elif type_index_of_the_new_value == TYPE_DICTIONARY:
			print("TYPE_DICTIONARY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_ARRAY:
			print("TYPE_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_RAW_ARRAY:
			print("TYPE_RAW_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_INT_ARRAY:
			print("TYPE_INT_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_REAL_ARRAY:
			print("TYPE_REAL_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_STRING_ARRAY:
			print("TYPE_STRING_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_VECTOR2_ARRAY:
			print("TYPE_VECTOR2_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_VECTOR3_ARRAY:
			print("TYPE_VECTOR3_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_COLOR_ARRAY:
			print("TYPE_COLOR_ARRAY is not yet implemented")
		elif type_index_of_the_new_value == TYPE_MAX:
			print("TYPE_MAX is not yet implemented")

		if get_item_metadata(selected_item_index)[1] == "name":
			if watch_value.text.length() > 0:
				var full_path = get_item_metadata(selected_item_index)[0] # For speed and convenience.
				var full_parent_path = "" # To append the new name.
				for i in range(0, full_path.get_name_count() - 1):
					full_parent_path += str("/", full_path.get_name(i))
				var new_path = get_node(str(full_parent_path, "/", watch_value.text)).get_path() # For speed and convenience.
				VDGlobal.visual_debugger.full_selected_path = str(new_path)
				for i in range(0, item_count):
					if get_item_metadata(i)[0] == full_path:
						set_item_metadata(i, [new_path, get_item_metadata(i)[1]])
						set_watch_value(i)

					outliner.get_selected().set_metadata(0, new_path)
					outliner.get_selected().set_text(0, watch_value.text)
			else:
				print("Name must contain at least one character!")
		else:
			set_watch_value(selected_item_index)
	else:
		print("A problem in setting watch value!")

func remove_duplicates():
	for i in range(0, item_count):
		for i2 in range(i, item_count):
			if i != i2 && get_item_metadata(i) == get_item_metadata(i2):
				remove_item(i2)
				item_count -= 1
				if i2 > item_count - 2:
					return

func update_watches():
	if item_count > 0:
		var selected_item_index = 0 # To know, where to reset
		if get_selected_items().size() > 0:
			selected_item_index = get_selected_items()[0]
		if unique_check_box.pressed != true:
			if current_watches_list == null || current_watches_list.size() < item_count:
				current_watches_list = [] # This approach may leak memory. clear() may be safer to use. Have to check and compare.
				for i in range(0, item_count):
					current_watches_list.append([get_item_text(i), get_item_metadata(i)])
			elif current_watches_list.size() > item_count:
				clear()
				for i in range(0, current_watches_list.size()):
					add_item(current_watches_list[i][0])
					set_item_metadata(i, current_watches_list[i][1])
				item_count = current_watches_list.size()
		else:
			if item_count > 1:
				remove_duplicates()

		for i in range(0, item_count):
			set_watch_value(i)

		if selected_item_index < item_count:
			select(selected_item_index)
		else:
			select(item_count - 1)

func _process(delta):
	if !get_tree().paused || previous_h_scroll_value != h_scroll_value:
		update_watches()

func _on_AddWatch_button_down():
	add_a_watch()

func _on_SetValue_button_down():
	modify_watch_value()

func _on_HScrollBar_value_changed(value):
	previous_h_scroll_value = h_scroll_value
	h_scroll_value = value

func _on_RemoveWatch_pressed():
	remove_a_watch()
