extends Node2D

const SCALE_MULTIPLIER = .01 # How sensitive are scale handles.
const SCALE_STEM_MULTIPLIER = 10.0 # How significant is the handle scaling.
const SCALE_HANDLE_INCREASE_DECREASE_BOUND = 7.5 # Handle scaling cannot go past this bound.
const ROTATION_COEFFICIENT = -.01 # How quickly to rotate node on mouse drag.
const DEFAULT_ARROW_STEM_LENGTH = 100.0 # How long are the stems for the direction arrows.
const MIN_DISTANCE_TO_ROTATION_CIRCLE_MIDDLE = 10.0 # To prevent ugly rotations. For speed and convenience.
const SELECTION_SIZE = Vector2(10.0, 10.0) # The relative size of the selection.
enum VD_Mouse_is_over_arrow {NONE, X_ARROW, Y_ARROW, MIDDLE}

onready var min_sqr_distance_to_rotation_circle_middle = MIN_DISTANCE_TO_ROTATION_CIRCLE_MIDDLE * MIN_DISTANCE_TO_ROTATION_CIRCLE_MIDDLE # To prevent ugly rotations.
onready var rotate_on_axis_is_enabled = false # For speed and convenience.
onready var mouse_is_over_arrow = VD_Mouse_is_over_arrow.NONE # Act only on one axis.
onready var x_arrow_stem_length = DEFAULT_ARROW_STEM_LENGTH # To be able to change stem length dynamically.
onready var y_arrow_stem_length = DEFAULT_ARROW_STEM_LENGTH # To be able to change stem length dynamically.
onready var move_rectangle_size = Vector2(10.0, 10.0) # To have an convenient handle.

var scale_arrow_stem_increase_amount_x = .0 # How much does the stem length must increase, when scaling is happening.
var scale_arrow_stem_increase_amount_y = .0 # How much does the stem length must increase, when scaling is happening.
var node = null # For speed and convenience.
var arrow_direction_vector_y = Vector2(.0, .0) # For speed and convenience.
var arrow_direction_vector_x = Vector2(.0, .0) # For speed and convenience.
var node_global_transform = Vector2(.0, .0) # For a wider scope.
var node_position = Vector2(.0, .0) # For a wider scope.
var debugger_camera_position = Vector2(.0, .0) # For a wider scope.
var camera_to_object_vector = Vector2(.0, .0) # For a wider scope.
var current_node_position = Vector2(.0, .0) # For a wider scope.
var zoomed_size = Vector2(.0, .0) # For a wider scope.
var center_of_the_node = Vector2(.0, .0) # For a wider scope.
var center_of_the_node_with_scale = Vector2(.0, .0) # For a wider scope.
var visual_debugger_camera = null # For speed and convenience.
var camera_zoom = null # For speed and convenience.
var rotation_transform_y = null # For speed and convenience.
var y_arrow_tip_position = Vector2(.0, .0) # For a wider scope.
var x_arrow_tip_position = Vector2(.0, .0) # For a wider scope.
var x_color = Color(.5, .1, .1, .5) # For speed and convenience.
var y_color = Color(.1, .1, .5, .5) # For speed and convenience.
var x_arrow_color = Color(.6, .1, .1, .9) # For speed and convenience.
var y_arrow_color = Color(.1, .1, .6, .9) # For speed and convenience.
var x_character_color = Color(.9, .4, .4, .99) # For speed and convenience.
var y_character_color = Color(.4, .4, .9, .99) # For speed and convenience.
var character_offset_x = 10.0 # For convenience.
var character_offset_y = 10.0 # For convenience.
var character_width = 15.0 # For convenience.
var character_height = 15.0 # For convenience.
var character_thickenss = 3.0 # For convenience.
var manage_this_node = false # Manage node only if it is possible.
var circle_size = .0 # For speed and convenience.
var scale_tip_rectangle_size = Vector2 (10.0, 10.0) # To set the size of the arrow tips for the scale arrows.
var old_mouse_position = Vector2(.0, .0) # To detect and measure mouse position changes.
var mouse_is_over_rotation_circle = false # For speed and convenience.
var absolute_mouse_position = Vector2(.0, .0) # For speed and convenience.
var sqr_distance_to_mouse = .0 # For speed and convenience.
var forbid_transformation_mouse_input = false # To forbid input if the click wasn't on interactable transformation element.
var scale_at_mouse_grab = Vector2(.0, .0) # To know, to which side to move the scale.
var node_scale_ratio = 1.0 # To preserve the correct ratio of the node scale.
var concurrent_scale_mask = Vector2(1.0, 1.0) # To always keep correct sign relationships for both axis.

func _process(delta):
	update()

func _input(event):
	if !VDGlobal.visual_debugger.mouse_is_over_visual_debugger_gui:
		absolute_mouse_position = VDGlobal.visual_debugger.scene_node_selector.absolute_mouse_position
		var absolute_mouse_position_with_scale = absolute_mouse_position / VDGlobal.visual_debugger.scale # For speed and convenience.
		sqr_distance_to_mouse = absolute_mouse_position_with_scale.distance_squared_to(center_of_the_node)
		if sqr_distance_to_mouse < circle_size * circle_size:
			mouse_is_over_rotation_circle = true
		else:
			mouse_is_over_rotation_circle = false

		if !mouse_left_click_is_active && Input.is_mouse_button_pressed(BUTTON_LEFT):
			mouse_left_click_is_active = true
			if node != null:
				scale_at_mouse_grab = node.get(transform_getsetters[2])
				node_scale_ratio = max(abs(node.get(transform_getsetters[2]).y), VDGlobal.APPROXIMATION_FLOAT) / max(abs(node.get(transform_getsetters[2]).x), VDGlobal.APPROXIMATION_FLOAT)
				concurrent_scale_mask = Vector2(1.0 if node.get(transform_getsetters[2]).x > .0 else -1.0, 1.0 if node.get(transform_getsetters[2]).y > .0 else -1.0)
			if !(mouse_is_over_arrow && VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.MOVE) &&\
			   !(mouse_is_over_rotation_circle && VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.ROTATE)\
			   && !(mouse_is_over_arrow && VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.SCALE):
				forbid_transformation_mouse_input = true
		elif mouse_left_click_is_active && !Input.is_mouse_button_pressed(BUTTON_LEFT):
			mouse_left_click_is_active = false
			forbid_transformation_mouse_input = false

		if mouse_left_click_is_active:
			if !forbid_transformation_mouse_input:
				VDGlobal.visual_debugger.forbid_selection_circle_management = true
				if VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.MOVE:
					move_on_axis()
				elif VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.ROTATE:
					rotate_on_axis()
				elif VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.SCALE:
					scale_on_axis()

				if mouse_is_over_rotation_circle:
					rotate_on_axis_is_enabled = true
		else:
			VDGlobal.visual_debugger.forbid_selection_circle_management = false
			mouse_is_over_arrow = VD_Mouse_is_over_arrow.NONE
			rotate_on_axis_is_enabled = false
			scale_arrow_stem_increase_amount_x = .0
			scale_arrow_stem_increase_amount_y = .0
			x_arrow_stem_length = DEFAULT_ARROW_STEM_LENGTH
			y_arrow_stem_length = DEFAULT_ARROW_STEM_LENGTH
		old_mouse_position = absolute_mouse_position

var mouse_left_click_is_active = false # To detect just pressed "event".

func move_on_axis():
	if mouse_is_over_arrow == VD_Mouse_is_over_arrow.X_ARROW:
		node.set(transform_getsetters[0], node.get(transform_getsetters[0]) + arrow_direction_vector_x * arrow_direction_vector_x.normalized().dot((absolute_mouse_position - old_mouse_position)))
	elif mouse_is_over_arrow == VD_Mouse_is_over_arrow.Y_ARROW:
		node.set(transform_getsetters[0], node.get(transform_getsetters[0]) + arrow_direction_vector_y * arrow_direction_vector_y.normalized().dot((absolute_mouse_position - old_mouse_position)))
	elif mouse_is_over_arrow == VD_Mouse_is_over_arrow.MIDDLE:
		node.set(transform_getsetters[0], node.get(transform_getsetters[0]) + (absolute_mouse_position - old_mouse_position) * camera_zoom)

func scale_on_axis():
	if mouse_is_over_arrow == VD_Mouse_is_over_arrow.X_ARROW:
		var scale_amount = arrow_direction_vector_x.normalized().dot((absolute_mouse_position - old_mouse_position)) * SCALE_MULTIPLIER # For speed and convenience.
		if scale_at_mouse_grab.x > .0:
			node.set(transform_getsetters[2], node.get(transform_getsetters[2]) - Vector2(scale_amount, .0))
		else:
			node.set(transform_getsetters[2], node.get(transform_getsetters[2]) + Vector2(scale_amount, .0))
		scale_arrow_stem_increase_amount_x -= scale_amount
		x_arrow_stem_length = clamp(DEFAULT_ARROW_STEM_LENGTH + scale_arrow_stem_increase_amount_x * SCALE_STEM_MULTIPLIER, DEFAULT_ARROW_STEM_LENGTH\
									- SCALE_HANDLE_INCREASE_DECREASE_BOUND, DEFAULT_ARROW_STEM_LENGTH + SCALE_HANDLE_INCREASE_DECREASE_BOUND)
	elif mouse_is_over_arrow == VD_Mouse_is_over_arrow.Y_ARROW:
		var scale_amount = arrow_direction_vector_y.normalized().dot((absolute_mouse_position - old_mouse_position)) * SCALE_MULTIPLIER # For speed and convenience.
		if scale_at_mouse_grab.y > .0:
			node.set(transform_getsetters[2], node.get(transform_getsetters[2]) + Vector2(.0, scale_amount))
		else:
			node.set(transform_getsetters[2], node.get(transform_getsetters[2]) - Vector2(.0, scale_amount))
		scale_arrow_stem_increase_amount_y += scale_amount
		y_arrow_stem_length = clamp(DEFAULT_ARROW_STEM_LENGTH + scale_arrow_stem_increase_amount_y * SCALE_STEM_MULTIPLIER, \
									DEFAULT_ARROW_STEM_LENGTH - SCALE_HANDLE_INCREASE_DECREASE_BOUND, DEFAULT_ARROW_STEM_LENGTH + SCALE_HANDLE_INCREASE_DECREASE_BOUND)
	elif mouse_is_over_arrow == VD_Mouse_is_over_arrow.MIDDLE:
		var scale_amount = ((absolute_mouse_position.x - old_mouse_position.x) + (old_mouse_position.y - absolute_mouse_position.y)) * SCALE_MULTIPLIER # For speed and convenience.
		node.set(transform_getsetters[2], node.get(transform_getsetters[2]) + Vector2(scale_amount, .0))
		node.set(transform_getsetters[2], Vector2(.0, node.scale.x * node_scale_ratio * (1.0 if concurrent_scale_mask.y == concurrent_scale_mask.x else -1.0)))

func rotate_on_axis():
	if rotate_on_axis_is_enabled && sqr_distance_to_mouse > min_sqr_distance_to_rotation_circle_middle:
		var x_scale_coefficient = 1.0 if node.get(transform_getsetters[2]).x > .0 else -1.0 # To determine rotation direction.
		var y_scale_coefficient = 1.0 if node.get(transform_getsetters[2]).y > .0 else -1.0 # To determine rotation direction.
		var absolute_mouse_position_with_scale = absolute_mouse_position / VDGlobal.visual_debugger.scale # For speed and convenience.
		if absolute_mouse_position_with_scale.y > center_of_the_node_with_scale.y:
			if absolute_mouse_position_with_scale.x > old_mouse_position.x:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) + (absolute_mouse_position.x - old_mouse_position.x) * ROTATION_COEFFICIENT * x_scale_coefficient * y_scale_coefficient)
			else:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) - (old_mouse_position.x - absolute_mouse_position.x) * ROTATION_COEFFICIENT * x_scale_coefficient * y_scale_coefficient)
		else:
			if absolute_mouse_position_with_scale.x > old_mouse_position.x:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) - (absolute_mouse_position.x - old_mouse_position.x) * ROTATION_COEFFICIENT * x_scale_coefficient * y_scale_coefficient)
			else:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) + (old_mouse_position.x - absolute_mouse_position.x) * ROTATION_COEFFICIENT * x_scale_coefficient * y_scale_coefficient)

		if absolute_mouse_position_with_scale.x < center_of_the_node_with_scale.x:
			if absolute_mouse_position.y > old_mouse_position.y:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) + (absolute_mouse_position.y - old_mouse_position.y) * ROTATION_COEFFICIENT)
			else:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) - (old_mouse_position.y - absolute_mouse_position.y) * ROTATION_COEFFICIENT)
		else:
			if absolute_mouse_position_with_scale.y > old_mouse_position.y:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) - (absolute_mouse_position.y - old_mouse_position.y) * ROTATION_COEFFICIENT)
			else:
				node.set(transform_getsetters[1], node.get(transform_getsetters[1]) + (old_mouse_position.y - absolute_mouse_position.y) * ROTATION_COEFFICIENT)

func draw_arrow_head(arrow_direction_vector, center_of_the_node, tip_of_the_arrow, line_color, arrow_length, thickness):
	draw_line(tip_of_the_arrow, tip_of_the_arrow + Vector2(arrow_direction_vector.y, -arrow_direction_vector.x) * arrow_length, line_color, thickness, true)
	draw_line(tip_of_the_arrow, tip_of_the_arrow - Vector2(arrow_direction_vector.y, -arrow_direction_vector.x) * arrow_length, line_color, thickness, true)
	draw_line(tip_of_the_arrow + arrow_direction_vector * arrow_length, tip_of_the_arrow + \
			  Vector2(arrow_direction_vector.y, -arrow_direction_vector.x) * arrow_length, line_color, thickness, true)
	draw_line(tip_of_the_arrow + arrow_direction_vector * arrow_length, tip_of_the_arrow - \
			  Vector2(arrow_direction_vector.y, -arrow_direction_vector.x) * arrow_length, line_color, thickness, true)

func calculate_node_draw_center():
	visual_debugger_camera = VDGlobal.visual_debugger.debugger_camera
	camera_zoom = visual_debugger_camera.zoom
	if VDGlobal.visual_debugger.node_is_selected:
		node_global_transform = node.get_global_transform()
		node_position = node_global_transform.origin
		debugger_camera_position = visual_debugger_camera.get_global_transform().origin
		camera_to_object_vector = node_position - debugger_camera_position
		current_node_position = self.get_global_transform().origin
		var camera_zoom_coefficient = Vector2(1.0, 1.0) / camera_zoom # For speed and convenience.
		zoomed_size = SELECTION_SIZE * camera_zoom_coefficient
		center_of_the_node = (camera_to_object_vector * camera_zoom_coefficient - current_node_position) / VDGlobal.visual_debugger.scale
		center_of_the_node_with_scale = center_of_the_node - zoomed_size * .5
		rotation_transform_y = Transform2D(node_global_transform.get_rotation(), Vector2(.0, .0))
		if node.get(transform_getsetters[2]).x < .0 && node.get(transform_getsetters[2]).y < .0:
			var tmpMatrix = rotation_transform_y
			tmpMatrix.x = Vector2(-rotation_transform_y.x.x, -rotation_transform_y.x.y)
			tmpMatrix.y = Vector2(-rotation_transform_y.y.x, -rotation_transform_y.y.y)
			rotation_transform_y = tmpMatrix
		elif node.get(transform_getsetters[2]).x < .0:
			var tmpMatrix = rotation_transform_y
			tmpMatrix.x = Vector2(-rotation_transform_y.x.x, rotation_transform_y.x.y)
			tmpMatrix.y = Vector2(rotation_transform_y.y.x, -rotation_transform_y.y.y)
			rotation_transform_y = tmpMatrix
		elif node.get(transform_getsetters[2]).y < .0:
			var tmpMatrix = rotation_transform_y
			tmpMatrix.x = Vector2(rotation_transform_y.x.x, -rotation_transform_y.x.y)
			tmpMatrix.y = Vector2(-rotation_transform_y.y.x, rotation_transform_y.y.y)
			rotation_transform_y = tmpMatrix
		arrow_direction_vector_y = rotation_transform_y.xform(Vector2(0, 1))
		arrow_direction_vector_x = Vector2(arrow_direction_vector_y.y, -arrow_direction_vector_y.x)
		y_arrow_tip_position = center_of_the_node_with_scale + arrow_direction_vector_y * y_arrow_stem_length
		x_arrow_tip_position = center_of_the_node_with_scale - arrow_direction_vector_x * x_arrow_stem_length

func draw_tips_and_axis_characters():
	if node.get(transform_getsetters[2]).x < .0:
		draw_line(Vector2(x_arrow_tip_position.x + character_offset_x - character_width * 1.5, \
						  x_arrow_tip_position.y + character_offset_y + character_height * .5), \
				  Vector2(x_arrow_tip_position.x + character_offset_x - character_width * .5, \
						  x_arrow_tip_position.y + character_offset_y + character_height * .5), x_character_color, character_thickenss, true)
	draw_line(Vector2(x_arrow_tip_position.x + character_offset_x, x_arrow_tip_position.y + character_offset_y), \
			  Vector2(x_arrow_tip_position.x + character_offset_x + character_width, x_arrow_tip_position.y + character_offset_y + character_height),\
			  x_character_color, character_thickenss, true)
	draw_line(Vector2(x_arrow_tip_position.x + character_offset_x + character_width, x_arrow_tip_position.y + character_offset_y),\
			  Vector2(x_arrow_tip_position.x + character_offset_x, x_arrow_tip_position.y + character_offset_y + character_height), \
			  x_character_color, character_thickenss, true)

	if node.get(transform_getsetters[2]).y < .0:
		draw_line(Vector2(y_arrow_tip_position.x + character_offset_x - character_width * 1.5,\
						  y_arrow_tip_position.y + character_offset_y + character_height * .5), \
				  Vector2(y_arrow_tip_position.x + character_offset_x - character_width * .5, \
						  y_arrow_tip_position.y + character_offset_y + character_height * .5), y_character_color, character_thickenss, true)
	draw_line(Vector2(y_arrow_tip_position.x + character_offset_x, y_arrow_tip_position.y + character_offset_y), \
			  Vector2(y_arrow_tip_position.x + character_offset_x + character_width * .5, \
					  y_arrow_tip_position.y + character_offset_y + character_height * .5), y_character_color, character_thickenss, true)
	draw_line(Vector2(y_arrow_tip_position.x + character_offset_x + character_width, y_arrow_tip_position.y + character_offset_y), \
			  Vector2(y_arrow_tip_position.x + character_offset_x, y_arrow_tip_position.y + character_offset_y + character_height), \
			  y_character_color, character_thickenss, true)

	if VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.MOVE || \
	   VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.ROTATE:
		draw_arrow_head(arrow_direction_vector_x, center_of_the_node, x_arrow_tip_position, x_arrow_color, -7.5, 2.0)
		draw_arrow_head(arrow_direction_vector_y, center_of_the_node, y_arrow_tip_position, y_arrow_color, 7.5, 2.0)
		draw_arrow_head(arrow_direction_vector_x, center_of_the_node, x_arrow_tip_position, x_arrow_color, -5.0, 2.0)
		draw_arrow_head(arrow_direction_vector_y, center_of_the_node, y_arrow_tip_position, y_arrow_color, 5.0, 2.0)
		draw_arrow_head(arrow_direction_vector_x, center_of_the_node, x_arrow_tip_position, x_arrow_color, -2.5, 2.0)
		draw_arrow_head(arrow_direction_vector_y, center_of_the_node, y_arrow_tip_position, y_arrow_color, 2.5, 2.0)
	elif VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.SCALE:
		draw_rect(Rect2(x_arrow_tip_position - scale_tip_rectangle_size * .5, scale_tip_rectangle_size), x_arrow_color, true)
		draw_rect(Rect2(y_arrow_tip_position - scale_tip_rectangle_size * .5, scale_tip_rectangle_size), y_arrow_color, true)

func draw_local_axis_handles():
	if VDGlobal.visual_debugger.full_selected_path != "":
		calculate_node_draw_center()
		if VDGlobal.visual_debugger.node_is_selected:
			var arrow_stem_selection_error = 20.0 # How close must the mouse cursor get to the arrow stem for it to be considered selected.
			var absolute_mouse_position_with_scale = absolute_mouse_position / VDGlobal.visual_debugger.scale # For speed and convenience.

			if mouse_is_over_arrow == VD_Mouse_is_over_arrow.NONE:
				if absolute_mouse_position_with_scale.distance_to(current_node_position + center_of_the_node_with_scale) < move_rectangle_size.x:
					mouse_is_over_arrow = VD_Mouse_is_over_arrow.MIDDLE
			if mouse_is_over_arrow == VD_Mouse_is_over_arrow.NONE:
				if absolute_mouse_position_with_scale.x - current_node_position.x > (center_of_the_node_with_scale.x\
																		  if center_of_the_node_with_scale.x < y_arrow_tip_position.x\
																		  else y_arrow_tip_position.x) - arrow_stem_selection_error:
					if absolute_mouse_position_with_scale.y - current_node_position.y > (center_of_the_node_with_scale.y\
																			  if center_of_the_node_with_scale.y < y_arrow_tip_position.y\
																			  else y_arrow_tip_position.y) - arrow_stem_selection_error:
						if absolute_mouse_position_with_scale.x - current_node_position.x < (center_of_the_node_with_scale.x\
																				  if center_of_the_node_with_scale.x > y_arrow_tip_position.x\
																				  else y_arrow_tip_position.x) + arrow_stem_selection_error:
							if absolute_mouse_position_with_scale.y - current_node_position.y < (center_of_the_node_with_scale.y\
																					  if center_of_the_node_with_scale.y > y_arrow_tip_position.y\
																					  else y_arrow_tip_position.y) + arrow_stem_selection_error:
								mouse_is_over_arrow = VD_Mouse_is_over_arrow.Y_ARROW
			if mouse_is_over_arrow == VD_Mouse_is_over_arrow.NONE:
				if absolute_mouse_position_with_scale.x - current_node_position.x > (center_of_the_node_with_scale.x\
																		  if center_of_the_node_with_scale.x < x_arrow_tip_position.x\
																		  else x_arrow_tip_position.x) - arrow_stem_selection_error:
					if absolute_mouse_position_with_scale.y - current_node_position.y > (center_of_the_node_with_scale.y\
																			  if center_of_the_node_with_scale.y < x_arrow_tip_position.y\
																			  else x_arrow_tip_position.y) - arrow_stem_selection_error:
						if absolute_mouse_position_with_scale.x - current_node_position.x < (center_of_the_node_with_scale.x\
																				  if center_of_the_node_with_scale.x > x_arrow_tip_position.x\
																				  else x_arrow_tip_position.x) + arrow_stem_selection_error:
							if absolute_mouse_position_with_scale.y - current_node_position.y < (center_of_the_node_with_scale.y\
																					  if center_of_the_node_with_scale.y > x_arrow_tip_position.y\
																					  else x_arrow_tip_position.y) + arrow_stem_selection_error:
								mouse_is_over_arrow = VD_Mouse_is_over_arrow.X_ARROW

			draw_line(center_of_the_node_with_scale, y_arrow_tip_position, Color (y_color.r, y_color.g, y_color.b,\
																				  (y_color.a if forbid_transformation_mouse_input else 1.0)\
																				  if mouse_is_over_arrow == VD_Mouse_is_over_arrow.Y_ARROW\
																				  else y_color.a), 5.0, true)
			draw_line(center_of_the_node_with_scale, x_arrow_tip_position, Color (x_color.r, x_color.g, x_color.b,\
																				  (x_color.a if forbid_transformation_mouse_input else 1.0)\
																				  if mouse_is_over_arrow == VD_Mouse_is_over_arrow.X_ARROW\
																				  else x_color.a), 5.0, true)

			draw_tips_and_axis_characters()

			if mouse_is_over_arrow != VD_Mouse_is_over_arrow.MIDDLE:
				draw_rect(Rect2(center_of_the_node_with_scale - move_rectangle_size * .5, move_rectangle_size), Color(.1, .9, .1, .7), true)
			else:
				draw_rect(Rect2(center_of_the_node_with_scale - move_rectangle_size * .5, move_rectangle_size), Color(.1, .9, .1, .9), true)
		else:
			VDGlobal.visual_debugger.warning_line.text = "Node not found! Check Godot Debugger!"

func draw_circle_arc(center, radius, angle_from, angle_to, color, thickness, detail):
	var points_arc = PoolVector2Array()

	for i in range(detail + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / detail - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(detail):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color, thickness)

func draw_rotation_circle():
	calculate_node_draw_center()
	if VDGlobal.visual_debugger.node_is_selected:
		circle_size = center_of_the_node_with_scale.distance_to(y_arrow_tip_position)
		draw_circle_arc(center_of_the_node_with_scale, circle_size, .0, 360.0, Color(1.0, .0, .0, .5), 3.0, 32)
		draw_circle_arc(center_of_the_node_with_scale, circle_size - 3.0, .0, 360.0, Color(.0, 1.0, .0, .5), 3.0, 32)

		draw_line(center_of_the_node_with_scale, y_arrow_tip_position, y_color, 5.0, true)
		draw_line(center_of_the_node_with_scale, x_arrow_tip_position, x_color, 5.0, true)
		draw_tips_and_axis_characters()

		if (mouse_is_over_rotation_circle && !forbid_transformation_mouse_input) || rotate_on_axis_is_enabled:
			draw_circle(center_of_the_node_with_scale, circle_size - 6.0, Color(.0, .0, 1.0, .35))
		else:
			draw_circle(center_of_the_node_with_scale, circle_size - 6.0, Color(.0, .0, 1.0, .2))

		draw_circle(center_of_the_node_with_scale, MIN_DISTANCE_TO_ROTATION_CIRCLE_MIDDLE, Color(.0, .0, 1.0, .9))

var transform_getsetters = ["", "", ""] # To use the appropriate transformation setters and getters.

func check_for_transform_property(passed_properties):
	var is_property_found = false # To return gracefully from the function.
	for i in range(0, passed_properties.size()):
		if passed_properties[i] in node:
			is_property_found = true
			if i == 0:
				transform_getsetters[0] = "global_position"
				transform_getsetters[1] = "rotation"
				transform_getsetters[2] = "scale"
			elif i == 1:
				transform_getsetters[0] = "rect_position"
				transform_getsetters[1] = "rect_rotation"
				transform_getsetters[2] = "rect_scale"
			break
	return is_property_found

func _draw():
	node = get_node(VDGlobal.visual_debugger.full_selected_path)
	if node != null:
		if node.has_method("get_global_transform") && check_for_transform_property(["scale", "rect_scale"]):
			manage_this_node = true
		else:
			manage_this_node = false
			return
		if VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.MOVE:
			draw_local_axis_handles()
		elif VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.ROTATE:
			draw_rotation_circle()
		elif VDGlobal.visual_debugger.transformation_mode == VDGlobal.visual_debugger.VD_Transformation_modes.SCALE:
			draw_local_axis_handles()
